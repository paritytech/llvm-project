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
// rather than by a `vsetvli`.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// DAG nodes
//===----------------------------------------------------------------------===//

// Widening an XLen value. Target nodes rather than ZERO_EXTEND/SIGN_EXTEND so
// constant materialisation survives: an extend of a constant folds back into a
// wide constant, which would send it to the pool.
def SDT_ReviveWiden : SDTypeProfile<1, 1, [SDTCisVT<0, i256>, SDTCisInt<1>]>;

def riscv_wide_zext : RVSDNode<"WIDE_ZEXT", SDT_ReviveWiden>;
def riscv_wide_sext : RVSDNode<"WIDE_SEXT", SDT_ReviveWiden>;

// Counting bits. The generic expansions of CTPOP, CTLZ and CTTZ give up at this
// width and ask for a libcall that does not exist, so each gets an instruction.
// The result of counting 256 bits fits in an XLen register.
def SDT_ReviveCount : SDTypeProfile<1, 1, [SDTCisInt<0>, SDTCisVT<1, i256>]>;

def riscv_wide_cpop : RVSDNode<"WIDE_CPOP", SDT_ReviveCount>;
def riscv_wide_clz : RVSDNode<"WIDE_CLZ", SDT_ReviveCount>;
def riscv_wide_ctz : RVSDNode<"WIDE_CTZ", SDT_ReviveCount>;

//===----------------------------------------------------------------------===//
// Encodings
//===----------------------------------------------------------------------===//

// custom-2 opcode space, leaving custom-3 for XReviveCarry. funct3 selects the
// operand shape, funct7 the operation within it.
class RVReviveALU<bits<7> funct7, string opcodestr>
    : RVInstR<funct7, 0b000, OPC_CUSTOM_2, (outs VRM2:$rd),
              (ins VRM2:$rs1, VRM2:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Comparisons narrow to a GPR: the result feeds branches and selects.
class RVReviveCmp<bits<7> funct7, string opcodestr>
    : RVInstR<funct7, 0b001, OPC_CUSTOM_2, (outs GPR:$rd),
              (ins VRM2:$rs1, VRM2:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Shift amounts come from a GPR: only the low bits can matter.
class RVReviveShift<bits<7> funct7, string opcodestr>
    : RVInstR<funct7, 0b010, OPC_CUSTOM_2, (outs VRM2:$rd),
              (ins VRM2:$rs1, GPR:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Conversions between a wide value and an XLen one.
class RVReviveCvtToGPR<bits<7> funct7, string opcodestr>
    : RVInstR<funct7, 0b110, OPC_CUSTOM_2, (outs GPR:$rd), (ins VRM2:$rs1),
              opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

class RVReviveCvtToWide<bits<7> funct7, string opcodestr>
    : RVInstR<funct7, 0b111, OPC_CUSTOM_2, (outs VRM2:$rd), (ins GPR:$rs1),
              opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

// A wide unary, which is also the shape a register copy takes.
class RVReviveMove<bits<7> funct7, string opcodestr>
    : RVInstR<funct7, 0b110, OPC_CUSTOM_2, (outs VRM2:$rd), (ins VRM2:$rs1),
              opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

// The modular operations take three wide inputs, so they need R4.
class RVReviveR4<bits<2> funct2, string opcodestr>
    : RVInstR4<funct2, 0b011, OPC_CUSTOM_2, (outs VRM2:$rd),
               (ins VRM2:$rs1, VRM2:$rs2, VRM2:$rs3), opcodestr,
               "$rd, $rs1, $rs2, $rs3">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
//===----------------------------------------------------------------------===//
// Arithmetic and logic
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXReviveVec] in {
def REVIVE_W_ADD  : RVReviveALU<0b0000000, "revive.wadd">;
def REVIVE_W_SUB  : RVReviveALU<0b0000001, "revive.wsub">;
def REVIVE_W_MUL  : RVReviveALU<0b0000010, "revive.wmul">;
def REVIVE_W_AND  : RVReviveALU<0b0000011, "revive.wand">;
def REVIVE_W_OR   : RVReviveALU<0b0000100, "revive.wor">;
def REVIVE_W_XOR  : RVReviveALU<0b0000101, "revive.wxor">;
def REVIVE_W_UDIV : RVReviveALU<0b0000110, "revive.wdivu">;
def REVIVE_W_SDIV : RVReviveALU<0b0000111, "revive.wdiv">;
def REVIVE_W_UREM : RVReviveALU<0b0001000, "revive.wremu">;
def REVIVE_W_SREM : RVReviveALU<0b0001001, "revive.wrem">;

def REVIVE_W_SLL  : RVReviveShift<0b0000000, "revive.wsll">;
def REVIVE_W_SRL  : RVReviveShift<0b0000001, "revive.wsrl">;
def REVIVE_W_SRA  : RVReviveShift<0b0000010, "revive.wsra">;

//===----------------------------------------------------------------------===//
// Comparisons
//===----------------------------------------------------------------------===//

// `icmp ult` is 6% of all IR revive emits and the most expensive frequent
// operation: the generic expansion walks limbs from the top, branching at each.
def REVIVE_W_SEQ  : RVReviveCmp<0b0000000, "revive.wseq">;
def REVIVE_W_SNE  : RVReviveCmp<0b0000001, "revive.wsne">;
def REVIVE_W_SLTU : RVReviveCmp<0b0000010, "revive.wsltu">;
def REVIVE_W_SLT  : RVReviveCmp<0b0000011, "revive.wslt">;

//===----------------------------------------------------------------------===//
// Moves and conversions
//===----------------------------------------------------------------------===//

def REVIVE_W_BSWAP : RVReviveMove<0b0000010, "revive.wbswap">;
def REVIVE_W_TRUNC : RVReviveCvtToGPR<0b0000001, "revive.wtrunc">;
def REVIVE_W_CPOP  : RVReviveCvtToGPR<0b0000011, "revive.wcpop">;
def REVIVE_W_CLZ   : RVReviveCvtToGPR<0b0000100, "revive.wclz">;
def REVIVE_W_CTZ   : RVReviveCvtToGPR<0b0000101, "revive.wctz">;
def REVIVE_W_ZEXT  : RVReviveCvtToWide<0b0000000, "revive.wzext">;
def REVIVE_W_SEXT  : RVReviveCvtToWide<0b0000001, "revive.wsext">;

//===----------------------------------------------------------------------===//
// Routines that revive currently open-codes in stdlib.ll
//===----------------------------------------------------------------------===//

// EVM operations with no RISC-V equivalent, each replacing a stdlib.ll routine
// (__mulmod 4,534 bytes, __addmod 3,756).
def REVIVE_W_ADDMOD : RVReviveR4<0b00, "revive.waddmod">;
def REVIVE_W_MULMOD : RVReviveR4<0b01, "revive.wmulmod">;

def REVIVE_W_EXP    : RVReviveALU<0b0001010, "revive.wexp">;

// The value to extend comes first and the byte index second, matching the shifts
// rather than the EVM opcode, whose operands are the other way round.
def REVIVE_W_SIGNEXT: RVReviveALU<0b0001011, "revive.wsignextend">;
} // Predicates = [HasVendorXReviveVec]
} // hasSideEffects = 0, mayLoad = 0, mayStore = 0

//===----------------------------------------------------------------------===//
// Memory
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXReviveVec] in {
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def REVIVE_W_LD : RVInstI<0b100, OPC_CUSTOM_2, (outs VRM2:$rd),
                          (ins GPRMem:$rs1, simm12_lo:$imm12), "revive.wld",
                          "$rd, ${imm12}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def REVIVE_W_ST : RVInstS<0b101, OPC_CUSTOM_2, (outs),
                          (ins VRM2:$rs2, GPRMem:$rs1, simm12_lo:$imm12),
                          "revive.wst", "$rs2, ${imm12}(${rs1})">;
} // Predicates = [HasVendorXReviveVec]

//===----------------------------------------------------------------------===//
// Selection patterns
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXReviveVec] in {
def : Pat<(i256 (add (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_ADD  (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(i256 (sub (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_SUB  (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(i256 (mul (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_MUL  (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(i256 (and (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_AND  (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(i256 (or  (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_OR   (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(i256 (xor (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_XOR  (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(i256 (udiv (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_UDIV (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(i256 (sdiv (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_SDIV (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(i256 (urem (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_UREM (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(i256 (srem (i256 VRM2:$rs1), (i256 VRM2:$rs2))), (REVIVE_W_SREM (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;

// The IR types both shift operands i256; the DAG often narrows the amount
// first, so both forms are matched.
def : Pat<(i256 (shl (i256 VRM2:$rs1), (XLenVT GPR:$rs2))),
          (REVIVE_W_SLL (i256 VRM2:$rs1), GPR:$rs2)>;
def : Pat<(i256 (srl (i256 VRM2:$rs1), (XLenVT GPR:$rs2))),
          (REVIVE_W_SRL (i256 VRM2:$rs1), GPR:$rs2)>;
def : Pat<(i256 (sra (i256 VRM2:$rs1), (XLenVT GPR:$rs2))),
          (REVIVE_W_SRA (i256 VRM2:$rs1), GPR:$rs2)>;
def : Pat<(i256 (shl (i256 VRM2:$rs1), (i256 VRM2:$rs2))),
          (REVIVE_W_SLL (i256 VRM2:$rs1), (REVIVE_W_TRUNC (i256 VRM2:$rs2)))>;
def : Pat<(i256 (srl (i256 VRM2:$rs1), (i256 VRM2:$rs2))),
          (REVIVE_W_SRL (i256 VRM2:$rs1), (REVIVE_W_TRUNC (i256 VRM2:$rs2)))>;
def : Pat<(i256 (sra (i256 VRM2:$rs1), (i256 VRM2:$rs2))),
          (REVIVE_W_SRA (i256 VRM2:$rs1), (REVIVE_W_TRUNC (i256 VRM2:$rs2)))>;

def : Pat<(XLenVT (setcc (i256 VRM2:$rs1), (i256 VRM2:$rs2), SETEQ)),
          (REVIVE_W_SEQ (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(XLenVT (setcc (i256 VRM2:$rs1), (i256 VRM2:$rs2), SETNE)),
          (REVIVE_W_SNE (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(XLenVT (setcc (i256 VRM2:$rs1), (i256 VRM2:$rs2), SETULT)),
          (REVIVE_W_SLTU (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
def : Pat<(XLenVT (setcc (i256 VRM2:$rs1), (i256 VRM2:$rs2), SETLT)),
          (REVIVE_W_SLT (i256 VRM2:$rs1), (i256 VRM2:$rs2))>;
// The reversed forms are the same instruction with operands swapped, so `ugt`
// and `sgt` need no encodings of their own.
def : Pat<(XLenVT (setcc (i256 VRM2:$rs1), (i256 VRM2:$rs2), SETUGT)),
          (REVIVE_W_SLTU (i256 VRM2:$rs2), (i256 VRM2:$rs1))>;
def : Pat<(XLenVT (setcc (i256 VRM2:$rs1), (i256 VRM2:$rs2), SETGT)),
          (REVIVE_W_SLT (i256 VRM2:$rs2), (i256 VRM2:$rs1))>;

def : Pat<(i256 (bswap (i256 VRM2:$rs1))), (REVIVE_W_BSWAP (i256 VRM2:$rs1))>;

// sign_extend_inreg is formed after legalization, so the Custom lowering does not
// always see it. Narrow to a GPR, sign-extend there, and widen back.
def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i32)),
          (REVIVE_W_SEXT (ADDIW (REVIVE_W_TRUNC (i256 VRM2:$rs1)), 0))>;
def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i16)),
          (REVIVE_W_SEXT (SRAI (SLLI (REVIVE_W_TRUNC (i256 VRM2:$rs1)), 48), 48))>;
def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i8)),
          (REVIVE_W_SEXT (SRAI (SLLI (REVIVE_W_TRUNC (i256 VRM2:$rs1)), 56), 56))>;

def : Pat<(XLenVT (riscv_wide_cpop (i256 VRM2:$rs1))), (REVIVE_W_CPOP (i256 VRM2:$rs1))>;
def : Pat<(XLenVT (riscv_wide_clz (i256 VRM2:$rs1))), (REVIVE_W_CLZ (i256 VRM2:$rs1))>;
def : Pat<(XLenVT (riscv_wide_ctz (i256 VRM2:$rs1))), (REVIVE_W_CTZ (i256 VRM2:$rs1))>;

def : Pat<(riscv_wide_zext (XLenVT GPR:$rs1)), (REVIVE_W_ZEXT GPR:$rs1)>;
def : Pat<(riscv_wide_sext (XLenVT GPR:$rs1)), (REVIVE_W_SEXT GPR:$rs1)>;

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
def : Pat<(i64 (trunc (i256 VRM2:$rs1))), (REVIVE_W_TRUNC (i256 VRM2:$rs1))>;
def : Pat<(i256 (zext GPR:$rs1)), (REVIVE_W_ZEXT GPR:$rs1)>;
def : Pat<(i256 (sext GPR:$rs1)), (REVIVE_W_SEXT GPR:$rs1)>;
def : Pat<(i256 (anyext GPR:$rs1)), (REVIVE_W_ZEXT GPR:$rs1)>;

// Extending loads have no wide instruction: load narrow into a GPR and widen.
// EXTLOAD cannot be marked Expand, so it is matched here as a zero extend.
def : Pat<(i256 (extloadi8 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_ZEXT (LBU GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (extloadi16 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_ZEXT (LHU GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (extloadi32 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_ZEXT (LWU GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (extloadi64 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_ZEXT (LD GPR:$rs1, simm12_lo:$imm12))>;

// Sign-extending loads are matched rather than expanded: the expansion forms a
// sign_extend_inreg that is created after legalization and reaches ISel unlowered.
def : Pat<(i256 (sextloadi8 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_SEXT (LB GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (sextloadi16 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_SEXT (LH GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (sextloadi32 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_SEXT (LW GPR:$rs1, simm12_lo:$imm12))>;

def : Pat<(i256 (load (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_LD GPR:$rs1, simm12_lo:$imm12)>;
def : Pat<(store (i256 VRM2:$rs2), (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12)),
          (REVIVE_W_ST (i256 VRM2:$rs2), GPR:$rs1, simm12_lo:$imm12)>;
} // Predicates = [HasVendorXReviveVec]

//===----------------------------------------------------------------------===//
// Select
//===----------------------------------------------------------------------===//

// The same conditional-branch triangle as the scalar select; there is no wide
// conditional move to fold into.
let Predicates = [HasVendorXReviveVec] in
defm Select_VRM2 : SelectCC_GPR_rrirr<VRM2, i256>;
