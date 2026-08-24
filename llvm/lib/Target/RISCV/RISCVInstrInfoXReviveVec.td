//===-- RISCVInstrInfoXReviveVec.td - revive wide integer ops -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// 256-bit integers as a machine type, so the code generator never expands them
// into limb chains. EVM words are a quarter of all IR revive emits, and RISC-V
// has no carry flag, so the generic expansion pays an `sltu` per carry: 56 bytes
// for one `add i256`, 86 for `icmp ult`.
//
// Values live in the vector registers, a pair to a value at LMUL=2, so the
// extension is an addition to the vector extensions rather than a replacement
// for them: copies are `vmv2r.v` and a wide value can be built by ordinary
// vector code. The semantics of the instructions below are scalar, though:
// nothing here reads `vtype` or `vl`, and the width is fixed by the opcode
// rather than by a `vsetvli`. Two widths are encoded here, 256 bits in a
// register pair and 128 bits in a single register, and every instruction
// carries its own: a `funct7` bit in the register forms, the low bit of the
// offset field in the memory forms.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Operands
//===----------------------------------------------------------------------===//

// The offset a wide memory instruction takes: a 12-bit signed immediate whose
// least significant bit is zero.
//
// Constants only, where a scalar load or store also accepts the low part of a
// symbol. The PolkaVM linker decodes these instructions whole and rejects a
// relocation against one, so a symbol has to be added to the address register
// instead. Even only, because the low bit of the field selects between the wide
// types; it stays where it is encoded rather than being shifted out, so that the
// narrower types find it in the same place.
def simm12_lsb0 : RISCVOp,
                  ImmLeaf<XLenVT, [{return isShiftedInt<11, 1>(Imm);}]> {
  let ParserMatchClass = SImmAsmOperand<12, "Lsb0">;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeSImmLsb0Operand<12>";
  let OperandType = "OPERAND_SIMM12_LSB0";
}

// The same offset, for a width whose flag takes the low bit of the field rather
// than leaving the offset's own zero there. The offset occupies the eleven bits
// above the flag, which is where the wider type keeps it too, so what reaches
// the decoder is the offset already in place, and even by construction rather
// than by a check.
def simm12_lsb0_widthflag
    : RISCVOp, ImmLeaf<XLenVT, [{return isShiftedInt<11, 1>(Imm);}]> {
  let ParserMatchClass = SImmAsmOperand<12, "Lsb0">;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeSImmOperand<12>";
  let OperandType = "OPERAND_SIMM12_LSB0";
}

//===----------------------------------------------------------------------===//
// DAG nodes
//===----------------------------------------------------------------------===//

// Widening an XLen value. Target nodes rather than ZERO_EXTEND/SIGN_EXTEND so
// constant materialisation survives: an extend of a constant folds back into a
// wide constant, which would send it to the pool.
def SDT_ReviveWiden : SDTypeProfile<1, 1, [SDTCisInt<0>, SDTCisInt<1>]>;

def riscv_wide_zext : RVSDNode<"WIDE_ZEXT", SDT_ReviveWiden>;
def riscv_wide_sext : RVSDNode<"WIDE_SEXT", SDT_ReviveWiden>;

// Counting bits. The generic expansions of CTPOP, CTLZ and CTTZ give up at this
// width and ask for a libcall that does not exist, so each gets an instruction.
// The result of counting 256 bits fits in an XLen register.
def SDT_ReviveCount : SDTypeProfile<1, 1, [SDTCisInt<0>, SDTCisInt<1>]>;

def riscv_wide_cpop : RVSDNode<"WIDE_CPOP", SDT_ReviveCount>;
def riscv_wide_clz : RVSDNode<"WIDE_CLZ", SDT_ReviveCount>;
def riscv_wide_ctz : RVSDNode<"WIDE_CTZ", SDT_ReviveCount>;

//===----------------------------------------------------------------------===//
// Encodings
//===----------------------------------------------------------------------===//

// custom-2 opcode space, leaving custom-3 for XReviveCarry. funct3 selects the
// operand shape, funct7 the operation within it: the top funct7 bit is the
// width, so one operation keeps one funct6 at every width it exists at.
class RVReviveALU<bit width, bits<6> funct6, DAGOperand valty, string opcodestr>
    : RVInstR<{width, funct6}, 0b000, OPC_CUSTOM_2, (outs valty:$rd),
              (ins valty:$rs1, valty:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Comparisons narrow to a GPR: the result feeds branches and selects.
class RVReviveCmp<bit width, bits<6> funct6, DAGOperand valty, string opcodestr>
    : RVInstR<{width, funct6}, 0b001, OPC_CUSTOM_2, (outs GPR:$rd),
              (ins valty:$rs1, valty:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Shift amounts come from a GPR: only the low bits can matter.
class RVReviveShift<bit width, bits<6> funct6, DAGOperand valty,
                    string opcodestr>
    : RVInstR<{width, funct6}, 0b010, OPC_CUSTOM_2, (outs valty:$rd),
              (ins valty:$rs1, GPR:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Conversions between a wide value and an XLen one.
class RVReviveCvtToGPR<bit width, bits<6> funct6, DAGOperand valty,
                       string opcodestr>
    : RVInstR<{width, funct6}, 0b110, OPC_CUSTOM_2, (outs GPR:$rd),
              (ins valty:$rs1), opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

class RVReviveCvtToWide<bit width, bits<6> funct6, DAGOperand valty,
                        string opcodestr>
    : RVInstR<{width, funct6}, 0b111, OPC_CUSTOM_2, (outs valty:$rd),
              (ins GPR:$rs1), opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

// A wide unary, which is also the shape a register copy takes.
class RVReviveMove<bit width, bits<6> funct6, DAGOperand valty,
                   string opcodestr>
    : RVInstR<{width, funct6}, 0b110, OPC_CUSTOM_2, (outs valty:$rd),
              (ins valty:$rs1), opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

// The modular operations take three wide inputs, so they need R4.
class RVReviveR4<bits<2> funct2, string opcodestr>
    : RVInstR4<funct2, 0b011, OPC_CUSTOM_2, (outs VRM2:$rd),
               (ins VRM2:$rs1, VRM2:$rs2, VRM2:$rs3), opcodestr,
               "$rd, $rs1, $rs2, $rs3">;

// The memory forms have no funct7 to put the width in, so the low bit of the
// offset field holds it: the offset is even, so the widest type leaves its own
// zero there and a narrower one a fixed one. The offset itself stays in the
// same eleven bits at either width, and the flag being a fixed bit is what
// makes the widths separate encodings rather than one the decoder must guess.
class RVReviveLoad<bit width, DAGOperand valty, DAGOperand memimm,
                   string opcodestr>
    : RVInstI<0b100, OPC_CUSTOM_2, (outs valty:$rd),
              (ins GPRMem:$rs1, memimm:$imm12), opcodestr,
              "$rd, ${imm12}(${rs1})"> {
  let Inst{31-21} = imm12{11-1};
  let Inst{20} = !if(width, 0b1, imm12{0});
}

class RVReviveStore<bit width, DAGOperand valty, DAGOperand memimm,
                    string opcodestr>
    : RVInstS<0b101, OPC_CUSTOM_2, (outs),
              (ins valty:$rs2, GPRMem:$rs1, memimm:$imm12), opcodestr,
              "$rs2, ${imm12}(${rs1})"> {
  let Inst{11-8} = imm12{4-1};
  let Inst{7} = !if(width, 0b1, imm12{0});
}

//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

// One expansion per wide type: `width` is the bit that selects it, of funct7 in
// the register forms and of the offset field in the memory forms, `valty` the
// registers that hold it, `suffix` and `asmsuffix` the tails of the record
// names and of the mnemonics, `memimm` the offset the memory forms take.
multiclass RVReviveOps<bit width, DAGOperand valty, string suffix,
                       string asmsuffix, DAGOperand memimm> {
let Predicates = [HasVendorXReviveVec] in {
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
// Arithmetic and logic
def ADD#suffix  : RVReviveALU<width, 0b000000, valty, "revive.wadd"#asmsuffix>;
def SUB#suffix  : RVReviveALU<width, 0b000001, valty, "revive.wsub"#asmsuffix>;
def MUL#suffix  : RVReviveALU<width, 0b000010, valty, "revive.wmul"#asmsuffix>;
def AND#suffix  : RVReviveALU<width, 0b000011, valty, "revive.wand"#asmsuffix>;
def OR#suffix   : RVReviveALU<width, 0b000100, valty, "revive.wor"#asmsuffix>;
def XOR#suffix  : RVReviveALU<width, 0b000101, valty, "revive.wxor"#asmsuffix>;
def UDIV#suffix : RVReviveALU<width, 0b000110, valty, "revive.wdivu"#asmsuffix>;
def SDIV#suffix : RVReviveALU<width, 0b000111, valty, "revive.wdiv"#asmsuffix>;
def UREM#suffix : RVReviveALU<width, 0b001000, valty, "revive.wremu"#asmsuffix>;
def SREM#suffix : RVReviveALU<width, 0b001001, valty, "revive.wrem"#asmsuffix>;

def SLL#suffix : RVReviveShift<width, 0b000000, valty, "revive.wsll"#asmsuffix>;
def SRL#suffix : RVReviveShift<width, 0b000001, valty, "revive.wsrl"#asmsuffix>;
def SRA#suffix : RVReviveShift<width, 0b000010, valty, "revive.wsra"#asmsuffix>;

// Comparisons. `icmp ult` is 6% of all IR revive emits and the most expensive
// frequent operation: the generic expansion walks limbs from the top, branching
// at each.
def SEQ#suffix  : RVReviveCmp<width, 0b000000, valty, "revive.wseq"#asmsuffix>;
def SNE#suffix  : RVReviveCmp<width, 0b000001, valty, "revive.wsne"#asmsuffix>;
def SLTU#suffix : RVReviveCmp<width, 0b000010, valty, "revive.wsltu"#asmsuffix>;
def SLT#suffix  : RVReviveCmp<width, 0b000011, valty, "revive.wslt"#asmsuffix>;

// Moves and conversions
def MV#suffix    : RVReviveMove<width, 0b000000, valty,
                                "revive.wmv"#asmsuffix>;
def BSWAP#suffix : RVReviveMove<width, 0b000010, valty,
                                "revive.wbswap"#asmsuffix>;
def TRUNC#suffix : RVReviveCvtToGPR<width, 0b000001, valty,
                                    "revive.wtrunc"#asmsuffix>;
def CPOP#suffix  : RVReviveCvtToGPR<width, 0b000011, valty,
                                    "revive.wcpop"#asmsuffix>;
def CLZ#suffix   : RVReviveCvtToGPR<width, 0b000100, valty,
                                    "revive.wclz"#asmsuffix>;
def CTZ#suffix   : RVReviveCvtToGPR<width, 0b000101, valty,
                                    "revive.wctz"#asmsuffix>;
def ZEXT#suffix  : RVReviveCvtToWide<width, 0b000000, valty,
                                     "revive.wzext"#asmsuffix>;
def SEXT#suffix  : RVReviveCvtToWide<width, 0b000001, valty,
                                     "revive.wsext"#asmsuffix>;
} // hasSideEffects = 0, mayLoad = 0, mayStore = 0

// Memory
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def LD#suffix : RVReviveLoad<width, valty, memimm, "revive.wld"#asmsuffix>;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def ST#suffix : RVReviveStore<width, valty, memimm, "revive.wst"#asmsuffix>;
} // Predicates = [HasVendorXReviveVec]
}

defm REVIVE_W_ : RVReviveOps<0, VRM2, "", "", simm12_lsb0>;
defm REVIVE_W_ : RVReviveOps<1, VR, "_128", ".i128", simm12_lsb0_widthflag>;

//===----------------------------------------------------------------------===//
// Routines that revive currently open-codes in stdlib.ll
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
let Predicates = [HasVendorXReviveVec] in {
// EVM operations with no RISC-V equivalent, each replacing a stdlib.ll routine
// (__mulmod 4,534 bytes, __addmod 3,756).
def REVIVE_W_ADDMOD : RVReviveR4<0b00, "revive.waddmod">;
def REVIVE_W_MULMOD : RVReviveR4<0b01, "revive.wmulmod">;

def REVIVE_W_EXP    : RVReviveALU<0, 0b001010, VRM2, "revive.wexp">;

// The value to extend comes first and the byte index second, matching the shifts
// rather than the EVM opcode, whose operands are the other way round.
def REVIVE_W_SIGNEXT: RVReviveALU<0, 0b001011, VRM2, "revive.wsignextend">;
} // Predicates = [HasVendorXReviveVec]
} // hasSideEffects = 0, mayLoad = 0, mayStore = 0

//===----------------------------------------------------------------------===//
// Selection patterns
//===----------------------------------------------------------------------===//

// The addressing mode of the wide memory instructions: only an even constant
// offset folds into the instruction, so a symbol or an odd offset is left in the
// address for a scalar instruction to add.
def AddrRegImmWide : ComplexPattern<iPTR, 2, "SelectAddrRegImmWide">;

// The patterns for one wide type, naming the instructions RVReviveOps defined
// for it.
multiclass RVRevivePats<ValueType vt, DAGOperand valty, string suffix,
                        DAGOperand memimm> {
defvar W_ADD   = !cast<Instruction>("REVIVE_W_ADD"#suffix);
defvar W_SUB   = !cast<Instruction>("REVIVE_W_SUB"#suffix);
defvar W_MUL   = !cast<Instruction>("REVIVE_W_MUL"#suffix);
defvar W_AND   = !cast<Instruction>("REVIVE_W_AND"#suffix);
defvar W_OR    = !cast<Instruction>("REVIVE_W_OR"#suffix);
defvar W_XOR   = !cast<Instruction>("REVIVE_W_XOR"#suffix);
defvar W_UDIV  = !cast<Instruction>("REVIVE_W_UDIV"#suffix);
defvar W_SDIV  = !cast<Instruction>("REVIVE_W_SDIV"#suffix);
defvar W_UREM  = !cast<Instruction>("REVIVE_W_UREM"#suffix);
defvar W_SREM  = !cast<Instruction>("REVIVE_W_SREM"#suffix);
defvar W_SLL   = !cast<Instruction>("REVIVE_W_SLL"#suffix);
defvar W_SRL   = !cast<Instruction>("REVIVE_W_SRL"#suffix);
defvar W_SRA   = !cast<Instruction>("REVIVE_W_SRA"#suffix);
defvar W_SEQ   = !cast<Instruction>("REVIVE_W_SEQ"#suffix);
defvar W_SNE   = !cast<Instruction>("REVIVE_W_SNE"#suffix);
defvar W_SLTU  = !cast<Instruction>("REVIVE_W_SLTU"#suffix);
defvar W_SLT   = !cast<Instruction>("REVIVE_W_SLT"#suffix);
defvar W_BSWAP = !cast<Instruction>("REVIVE_W_BSWAP"#suffix);
defvar W_TRUNC = !cast<Instruction>("REVIVE_W_TRUNC"#suffix);
defvar W_CPOP  = !cast<Instruction>("REVIVE_W_CPOP"#suffix);
defvar W_CLZ   = !cast<Instruction>("REVIVE_W_CLZ"#suffix);
defvar W_CTZ   = !cast<Instruction>("REVIVE_W_CTZ"#suffix);
defvar W_ZEXT  = !cast<Instruction>("REVIVE_W_ZEXT"#suffix);
defvar W_SEXT  = !cast<Instruction>("REVIVE_W_SEXT"#suffix);
defvar W_LD    = !cast<Instruction>("REVIVE_W_LD"#suffix);
defvar W_ST    = !cast<Instruction>("REVIVE_W_ST"#suffix);

def : Pat<(vt (add (vt valty:$rs1), (vt valty:$rs2))), (W_ADD  (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(vt (sub (vt valty:$rs1), (vt valty:$rs2))), (W_SUB  (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(vt (mul (vt valty:$rs1), (vt valty:$rs2))), (W_MUL  (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(vt (and (vt valty:$rs1), (vt valty:$rs2))), (W_AND  (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(vt (or  (vt valty:$rs1), (vt valty:$rs2))), (W_OR   (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(vt (xor (vt valty:$rs1), (vt valty:$rs2))), (W_XOR  (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(vt (udiv (vt valty:$rs1), (vt valty:$rs2))), (W_UDIV (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(vt (sdiv (vt valty:$rs1), (vt valty:$rs2))), (W_SDIV (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(vt (urem (vt valty:$rs1), (vt valty:$rs2))), (W_UREM (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(vt (srem (vt valty:$rs1), (vt valty:$rs2))), (W_SREM (vt valty:$rs1), (vt valty:$rs2))>;

// The IR types both shift operands wide; the DAG often narrows the amount
// first, so both forms are matched.
def : Pat<(vt (shl (vt valty:$rs1), (XLenVT GPR:$rs2))),
          (W_SLL (vt valty:$rs1), GPR:$rs2)>;
def : Pat<(vt (srl (vt valty:$rs1), (XLenVT GPR:$rs2))),
          (W_SRL (vt valty:$rs1), GPR:$rs2)>;
def : Pat<(vt (sra (vt valty:$rs1), (XLenVT GPR:$rs2))),
          (W_SRA (vt valty:$rs1), GPR:$rs2)>;
def : Pat<(vt (shl (vt valty:$rs1), (vt valty:$rs2))),
          (W_SLL (vt valty:$rs1), (W_TRUNC (vt valty:$rs2)))>;
def : Pat<(vt (srl (vt valty:$rs1), (vt valty:$rs2))),
          (W_SRL (vt valty:$rs1), (W_TRUNC (vt valty:$rs2)))>;
def : Pat<(vt (sra (vt valty:$rs1), (vt valty:$rs2))),
          (W_SRA (vt valty:$rs1), (W_TRUNC (vt valty:$rs2)))>;

def : Pat<(XLenVT (setcc (vt valty:$rs1), (vt valty:$rs2), SETEQ)),
          (W_SEQ (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(XLenVT (setcc (vt valty:$rs1), (vt valty:$rs2), SETNE)),
          (W_SNE (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(XLenVT (setcc (vt valty:$rs1), (vt valty:$rs2), SETULT)),
          (W_SLTU (vt valty:$rs1), (vt valty:$rs2))>;
def : Pat<(XLenVT (setcc (vt valty:$rs1), (vt valty:$rs2), SETLT)),
          (W_SLT (vt valty:$rs1), (vt valty:$rs2))>;
// The reversed forms are the same instruction with operands swapped, so `ugt`
// and `sgt` need no encodings of their own.
def : Pat<(XLenVT (setcc (vt valty:$rs1), (vt valty:$rs2), SETUGT)),
          (W_SLTU (vt valty:$rs2), (vt valty:$rs1))>;
def : Pat<(XLenVT (setcc (vt valty:$rs1), (vt valty:$rs2), SETGT)),
          (W_SLT (vt valty:$rs2), (vt valty:$rs1))>;

def : Pat<(vt (bswap (vt valty:$rs1))), (W_BSWAP (vt valty:$rs1))>;

// sign_extend_inreg is formed after legalization, so the Custom lowering does not
// always see it. Narrow to a GPR, sign-extend there, and widen back.
def : Pat<(vt (sext_inreg (vt valty:$rs1), i32)),
          (W_SEXT (ADDIW (W_TRUNC (vt valty:$rs1)), 0))>;
def : Pat<(vt (sext_inreg (vt valty:$rs1), i16)),
          (W_SEXT (SRAI (SLLI (W_TRUNC (vt valty:$rs1)), 48), 48))>;
def : Pat<(vt (sext_inreg (vt valty:$rs1), i8)),
          (W_SEXT (SRAI (SLLI (W_TRUNC (vt valty:$rs1)), 56), 56))>;

def : Pat<(XLenVT (riscv_wide_cpop (vt valty:$rs1))), (W_CPOP (vt valty:$rs1))>;
def : Pat<(XLenVT (riscv_wide_clz (vt valty:$rs1))), (W_CLZ (vt valty:$rs1))>;
def : Pat<(XLenVT (riscv_wide_ctz (vt valty:$rs1))), (W_CTZ (vt valty:$rs1))>;

def : Pat<(vt (riscv_wide_zext (XLenVT GPR:$rs1))), (W_ZEXT GPR:$rs1)>;
def : Pat<(vt (riscv_wide_sext (XLenVT GPR:$rs1))), (W_SEXT GPR:$rs1)>;

def : Pat<(i64 (trunc (vt valty:$rs1))), (W_TRUNC (vt valty:$rs1))>;
def : Pat<(vt (zext GPR:$rs1)), (W_ZEXT GPR:$rs1)>;
def : Pat<(vt (sext GPR:$rs1)), (W_SEXT GPR:$rs1)>;
def : Pat<(vt (anyext GPR:$rs1)), (W_ZEXT GPR:$rs1)>;

// Extending loads have no wide instruction: load narrow into a GPR and widen.
// EXTLOAD cannot be marked Expand, so it is matched here as a zero extend.
def : Pat<(vt (extloadi8 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (W_ZEXT (LBU GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(vt (extloadi16 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (W_ZEXT (LHU GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(vt (extloadi32 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (W_ZEXT (LWU GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(vt (extloadi64 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (W_ZEXT (LD GPR:$rs1, simm12_lo:$imm12))>;

// Sign-extending loads are matched rather than expanded: the expansion forms a
// sign_extend_inreg that is created after legalization and reaches ISel unlowered.
def : Pat<(vt (sextloadi8 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (W_SEXT (LB GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(vt (sextloadi16 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (W_SEXT (LH GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(vt (sextloadi32 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (W_SEXT (LW GPR:$rs1, simm12_lo:$imm12))>;

def : Pat<(vt (load (AddrRegImmWide (XLenVT GPR:$rs1), memimm:$imm12))),
          (W_LD GPR:$rs1, memimm:$imm12)>;
def : Pat<(store (vt valty:$rs2), (AddrRegImmWide (XLenVT GPR:$rs1), memimm:$imm12)),
          (W_ST (vt valty:$rs2), GPR:$rs1, memimm:$imm12)>;
}

let Predicates = [HasVendorXReviveVec] in {
defm : RVRevivePats<i256, VRM2, "", simm12_lsb0>;

// The stdlib replacements. These are reached through intrinsics rather than
// ordinary IR because they have no LLVM opcode.
def : Pat<(int_riscv_revive_addmod (i256 VRM2:$rs1), (i256 VRM2:$rs2), (i256 VRM2:$rs3)),
          (REVIVE_W_ADDMOD (i256 VRM2:$rs1), (i256 VRM2:$rs2), (i256 VRM2:$rs3))>;
def : Pat<(int_riscv_revive_mulmod (i256 VRM2:$rs1), (i256 VRM2:$rs2), (i256 VRM2:$rs3)),
          (REVIVE_W_MULMOD (i256 VRM2:$rs1), (i256 VRM2:$rs2), (i256 VRM2:$rs3))>;
def : Pat<(int_riscv_revive_exp (i256 VRM2:$rs1), (i256 VRM2:$rs2)),
          (REVIVE_W_EXP (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(int_riscv_revive_signextend (i256 VRM2:$rs1), (i256 VRM2:$rs2)),
          (REVIVE_W_SIGNEXT (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
} // Predicates = [HasVendorXReviveVec]

//===----------------------------------------------------------------------===//
// Select
//===----------------------------------------------------------------------===//

// The same conditional-branch triangle as the scalar select; there is no wide
// conditional move to fold into.
let Predicates = [HasVendorXReviveVec] in
defm Select_VRM2 : SelectCC_GPR_rrirr<VRM2, i256>;
