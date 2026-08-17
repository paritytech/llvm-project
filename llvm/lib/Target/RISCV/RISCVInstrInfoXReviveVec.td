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
// Values live in VRM2 -- i256 is added to its type list, so at VLEN=128 a wide
// value is an LMUL=2 register pair. The semantics are scalar: nothing here reads
// `vtype` or `vl`, and the width is fixed by the opcode, not by a `vsetvli`.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// DAG nodes
//===----------------------------------------------------------------------===//

// Widening an XLen value. Target nodes rather than ZERO_EXTEND/SIGN_EXTEND so
// constant materialisation survives: an extend of a constant folds back into a
// wide constant, which would send it to the pool.
def SDT_ReviveWiden : SDTypeProfile<1, 1, [SDTCisInt<0>, SDTCisInt<1>]>;

def riscv_wide_zext : RVSDNode<"WIDE_ZEXT", SDT_ReviveWiden>;
def riscv_wide_sext : RVSDNode<"WIDE_SEXT", SDT_ReviveWiden>;

//===----------------------------------------------------------------------===//
// Encodings
//===----------------------------------------------------------------------===//

// Each width gets its own custom opcode, because the I- and S-type memory forms
// have no spare field to hold one. funct3 selects the operand shape and funct7
// the operation within it.
//
//   i256 (LMUL=2) -> custom-2    i512 (LMUL=4) -> custom-3    i1024 -> custom-1
class RVReviveALU<RISCVOpcode opc, bits<7> op, string opcodestr, RegisterClass rc>
    : RVInstR<op, 0b000, opc, (outs rc:$rd),
              (ins rc:$rs1, rc:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Comparisons narrow to a GPR: the result feeds branches and selects.
class RVReviveCmp<RISCVOpcode opc, bits<7> op, string opcodestr, RegisterClass rc>
    : RVInstR<op, 0b001, opc, (outs GPR:$rd),
              (ins rc:$rs1, rc:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Shift amounts come from a GPR: only the low bits can matter.
class RVReviveShift<RISCVOpcode opc, bits<7> op, string opcodestr, RegisterClass rc>
    : RVInstR<op, 0b010, opc, (outs rc:$rd),
              (ins rc:$rs1, GPR:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Conversions between a wide value and an XLen one.
class RVReviveCvtToGPR<RISCVOpcode opc, bits<7> op, string opcodestr, RegisterClass rc>
    : RVInstR<op, 0b110, opc, (outs GPR:$rd), (ins rc:$rs1),
              opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

class RVReviveCvtToWide<RISCVOpcode opc, bits<7> op, string opcodestr, RegisterClass rc>
    : RVInstR<op, 0b111, opc, (outs rc:$rd), (ins GPR:$rs1),
              opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

// A wide unary. Copies do not need one: the RVV classes already have VMVnR_V.
class RVReviveMove<RISCVOpcode opc, bits<7> op, string opcodestr, RegisterClass rc>
    : RVInstR<op, 0b110, opc, (outs rc:$rd), (ins rc:$rs1),
              opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

// The modular operations take three wide inputs, so they need R4.
class RVReviveR4<RISCVOpcode opc, bits<2> funct2, string opcodestr, RegisterClass rc>
    : RVInstR4<funct2, 0b011, opc, (outs rc:$rd),
               (ins rc:$rs1, rc:$rs2, rc:$rs3), opcodestr,
               "$rd, $rs1, $rs2, $rs3">;

// One set of instructions per width. `W` names the suffix used in the mnemonic
// and the record name, so REVIVE_W_ADD is the 256-bit add and REVIVE_D_ADD the
// 512-bit one.
multiclass RVReviveOps<RISCVOpcode opc, string W, string suffix, RegisterClass rc> {
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
  def W#_ADD  : RVReviveALU<opc, 0b0000000, "revive."#suffix#"add",  rc>;
  def W#_SUB  : RVReviveALU<opc, 0b0000001, "revive."#suffix#"sub",  rc>;
  def W#_MUL  : RVReviveALU<opc, 0b0000010, "revive."#suffix#"mul",  rc>;
  def W#_AND  : RVReviveALU<opc, 0b0000011, "revive."#suffix#"and",  rc>;
  def W#_OR   : RVReviveALU<opc, 0b0000100, "revive."#suffix#"or",   rc>;
  def W#_XOR  : RVReviveALU<opc, 0b0000101, "revive."#suffix#"xor",  rc>;
  def W#_UDIV : RVReviveALU<opc, 0b0000110, "revive."#suffix#"divu", rc>;
  def W#_SDIV : RVReviveALU<opc, 0b0000111, "revive."#suffix#"div",  rc>;
  def W#_UREM : RVReviveALU<opc, 0b0001000, "revive."#suffix#"remu", rc>;
  def W#_SREM : RVReviveALU<opc, 0b0001001, "revive."#suffix#"rem",  rc>;
  def W#_EXP     : RVReviveALU<opc, 0b0001010, "revive."#suffix#"exp", rc>;
  def W#_SIGNEXT : RVReviveALU<opc, 0b0001011, "revive."#suffix#"signextend", rc>;
  def W#_MINU : RVReviveALU<opc, 0b0001100, "revive."#suffix#"minu", rc>;
  def W#_MIN  : RVReviveALU<opc, 0b0001101, "revive."#suffix#"min",  rc>;
  def W#_MAXU : RVReviveALU<opc, 0b0001110, "revive."#suffix#"maxu", rc>;
  def W#_MAX  : RVReviveALU<opc, 0b0001111, "revive."#suffix#"max",  rc>;

  def W#_SLL : RVReviveShift<opc, 0b0000000, "revive."#suffix#"sll", rc>;
  def W#_SRL : RVReviveShift<opc, 0b0000001, "revive."#suffix#"srl", rc>;
  def W#_SRA : RVReviveShift<opc, 0b0000010, "revive."#suffix#"sra", rc>;

  def W#_SEQ  : RVReviveCmp<opc, 0b0000000, "revive."#suffix#"seq",  rc>;
  def W#_SNE  : RVReviveCmp<opc, 0b0000001, "revive."#suffix#"sne",  rc>;
  def W#_SLTU : RVReviveCmp<opc, 0b0000010, "revive."#suffix#"sltu", rc>;
  def W#_SLT  : RVReviveCmp<opc, 0b0000011, "revive."#suffix#"slt",  rc>;

  def W#_TRUNC : RVReviveCvtToGPR<opc, 0b0000001, "revive."#suffix#"trunc", rc>;
  def W#_ZEXT  : RVReviveCvtToWide<opc, 0b0000000, "revive."#suffix#"zext", rc>;
  def W#_SEXT  : RVReviveCvtToWide<opc, 0b0000001, "revive."#suffix#"sext", rc>;
  def W#_BSWAP : RVReviveMove<opc, 0b0000010, "revive."#suffix#"bswap", rc>;

  def W#_ADDMOD : RVReviveR4<opc, 0b00, "revive."#suffix#"addmod", rc>;
  def W#_MULMOD : RVReviveR4<opc, 0b01, "revive."#suffix#"mulmod", rc>;
}

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
  def W#_LD : RVInstI<0b100, opc, (outs rc:$rd),
                      (ins GPRMem:$rs1, simm12_lo:$imm12),
                      "revive."#suffix#"ld", "$rd, ${imm12}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
  def W#_ST : RVInstS<0b101, opc, (outs),
                      (ins rc:$rs2, GPRMem:$rs1, simm12_lo:$imm12),
                      "revive."#suffix#"st", "$rs2, ${imm12}(${rs1})">;
}

let Predicates = [HasVendorXReviveVec] in {
defm REVIVE : RVReviveOps<OPC_CUSTOM_2, "_W", "w", VRM2>;   // i256,  LMUL=2
defm REVIVE : RVReviveOps<OPC_CUSTOM_3, "_D", "d", VRM4>;   // i512,  LMUL=4
defm REVIVE : RVReviveOps<OPC_CUSTOM_1, "_Q", "q", VRM8>;   // i1024, LMUL=8
}

//===----------------------------------------------------------------------===//
// Selection patterns
//===----------------------------------------------------------------------===//

multiclass RVRevivePats<string W, ValueType vt, RegisterClass rc> {
  def : Pat<(vt (add  (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_ADD")  (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (sub  (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_SUB")  (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (mul  (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_MUL")  (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (and  (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_AND")  (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (or   (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_OR")   (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (xor  (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_XOR")  (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (udiv (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_UDIV") (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (sdiv (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_SDIV") (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (urem (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_UREM") (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (srem (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_SREM") (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (umin (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_MINU") (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (smin (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_MIN")  (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (umax (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_MAXU") (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (smax (vt rc:$a), (vt rc:$b))), (!cast<Instruction>("REVIVE"#W#"_MAX")  (vt rc:$a), (vt rc:$b))>;
  def : Pat<(vt (bswap (vt rc:$a))), (!cast<Instruction>("REVIVE"#W#"_BSWAP") (vt rc:$a))>;
  def : Pat<(vt (riscv_wide_zext (XLenVT GPR:$a))), (!cast<Instruction>("REVIVE"#W#"_ZEXT") GPR:$a)>;
  def : Pat<(vt (riscv_wide_sext (XLenVT GPR:$a))), (!cast<Instruction>("REVIVE"#W#"_SEXT") GPR:$a)>;

  // The IR types both shift operands alike; the DAG often narrows the amount
  // first, so both forms are matched.
  def : Pat<(vt (shl (vt rc:$a), (XLenVT GPR:$b))), (!cast<Instruction>("REVIVE"#W#"_SLL") (vt rc:$a), GPR:$b)>;
  def : Pat<(vt (srl (vt rc:$a), (XLenVT GPR:$b))), (!cast<Instruction>("REVIVE"#W#"_SRL") (vt rc:$a), GPR:$b)>;
  def : Pat<(vt (sra (vt rc:$a), (XLenVT GPR:$b))), (!cast<Instruction>("REVIVE"#W#"_SRA") (vt rc:$a), GPR:$b)>;
  def : Pat<(vt (shl (vt rc:$a), (vt rc:$b))),
            (!cast<Instruction>("REVIVE"#W#"_SLL") (vt rc:$a), (!cast<Instruction>("REVIVE"#W#"_TRUNC") (vt rc:$b)))>;
  def : Pat<(vt (srl (vt rc:$a), (vt rc:$b))),
            (!cast<Instruction>("REVIVE"#W#"_SRL") (vt rc:$a), (!cast<Instruction>("REVIVE"#W#"_TRUNC") (vt rc:$b)))>;
  def : Pat<(vt (sra (vt rc:$a), (vt rc:$b))),
            (!cast<Instruction>("REVIVE"#W#"_SRA") (vt rc:$a), (!cast<Instruction>("REVIVE"#W#"_TRUNC") (vt rc:$b)))>;

  def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), SETEQ)),  (!cast<Instruction>("REVIVE"#W#"_SEQ")  (vt rc:$a), (vt rc:$b))>;
  def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), SETNE)),  (!cast<Instruction>("REVIVE"#W#"_SNE")  (vt rc:$a), (vt rc:$b))>;
  def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), SETULT)), (!cast<Instruction>("REVIVE"#W#"_SLTU") (vt rc:$a), (vt rc:$b))>;
  def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), SETLT)),  (!cast<Instruction>("REVIVE"#W#"_SLT")  (vt rc:$a), (vt rc:$b))>;
  // The reversed forms are the same instruction with operands swapped.
  def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), SETUGT)), (!cast<Instruction>("REVIVE"#W#"_SLTU") (vt rc:$b), (vt rc:$a))>;
  def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), SETGT)),  (!cast<Instruction>("REVIVE"#W#"_SLT")  (vt rc:$b), (vt rc:$a))>;

  def : Pat<(i64 (trunc (vt rc:$a))), (!cast<Instruction>("REVIVE"#W#"_TRUNC") (vt rc:$a))>;
  def : Pat<(vt (zext (XLenVT GPR:$a))), (!cast<Instruction>("REVIVE"#W#"_ZEXT") GPR:$a)>;
  def : Pat<(vt (sext (XLenVT GPR:$a))), (!cast<Instruction>("REVIVE"#W#"_SEXT") GPR:$a)>;
  def : Pat<(vt (anyext (XLenVT GPR:$a))), (!cast<Instruction>("REVIVE"#W#"_ZEXT") GPR:$a)>;

  def : Pat<(vt (load (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
            (!cast<Instruction>("REVIVE"#W#"_LD") GPR:$rs1, simm12_lo:$imm12)>;
  def : Pat<(store (vt rc:$rs2), (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12)),
            (!cast<Instruction>("REVIVE"#W#"_ST") (vt rc:$rs2), GPR:$rs1, simm12_lo:$imm12)>;
}

let Predicates = [HasVendorXReviveVec] in {
defm : RVRevivePats<"_W", i256,  VRM2>;
defm : RVRevivePats<"_D", i512,  VRM4>;
defm : RVRevivePats<"_Q", i1024, VRM8>;

// Only i256 has these: the widening nodes exist for constant materialisation,
// the extending loads and sign_extend_inreg for narrow memory, and the modular
// intrinsics are EVM operations that are 256-bit by definition.
def : Pat<(int_riscv_revive_addmod (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c)),
          (REVIVE_W_ADDMOD (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c))>;
def : Pat<(int_riscv_revive_mulmod (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c)),
          (REVIVE_W_MULMOD (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c))>;
def : Pat<(int_riscv_revive_exp (i256 VRM2:$a), (i256 VRM2:$b)),
          (REVIVE_W_EXP (i256 VRM2:$a), (i256 VRM2:$b))>;
def : Pat<(int_riscv_revive_signextend (i256 VRM2:$a), (i256 VRM2:$b)),
          (REVIVE_W_SIGNEXT (i256 VRM2:$a), (i256 VRM2:$b))>;

def : Pat<(i256 (extloadi8 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_ZEXT (LBU GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (extloadi16 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_ZEXT (LHU GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (extloadi32 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_ZEXT (LWU GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (extloadi64 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_ZEXT (LD GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (sextloadi8 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_SEXT (LB GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (sextloadi16 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_SEXT (LH GPR:$rs1, simm12_lo:$imm12))>;
def : Pat<(i256 (sextloadi32 (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVE_W_SEXT (LW GPR:$rs1, simm12_lo:$imm12))>;

def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i32)),
          (REVIVE_W_SEXT (ADDIW (REVIVE_W_TRUNC (i256 VRM2:$rs1)), 0))>;
def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i16)),
          (REVIVE_W_SEXT (SRAI (SLLI (REVIVE_W_TRUNC (i256 VRM2:$rs1)), 48), 48))>;
def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i8)),
          (REVIVE_W_SEXT (SRAI (SLLI (REVIVE_W_TRUNC (i256 VRM2:$rs1)), 56), 56))>;

// Widening between the wide widths: build a zero of the wider type and insert
// the narrower value as its low sub-register.
def : Pat<(i512 (zext (i256 VRM2:$rs1))),
          (INSERT_SUBREG (i512 (REVIVE_D_ZEXT (XLenVT X0))), (i256 VRM2:$rs1), sub_vrm2_0)>;
def : Pat<(i1024 (zext (i256 VRM2:$rs1))),
          (INSERT_SUBREG (i1024 (REVIVE_Q_ZEXT (XLenVT X0))), (i256 VRM2:$rs1), sub_vrm2_0)>;
def : Pat<(i1024 (zext (i512 VRM4:$rs1))),
          (INSERT_SUBREG (i1024 (REVIVE_Q_ZEXT (XLenVT X0))), (i512 VRM4:$rs1), sub_vrm4_0)>;

// Truncating between the wide widths: the low part of the wider register is the
// narrower value, so this is a sub-register copy.
def : Pat<(i256 (trunc (i512 VRM4:$rs1))),
          (i256 (EXTRACT_SUBREG (i512 VRM4:$rs1), sub_vrm2_0))>;
def : Pat<(i512 (trunc (i1024 VRM8:$rs1))),
          (i512 (EXTRACT_SUBREG (i1024 VRM8:$rs1), sub_vrm4_0))>;
def : Pat<(i256 (trunc (i1024 VRM8:$rs1))),
          (i256 (EXTRACT_SUBREG (i1024 VRM8:$rs1), sub_vrm2_0))>;
} // Predicates = [HasVendorXReviveVec]

//===----------------------------------------------------------------------===//
// Select
//===----------------------------------------------------------------------===//

// The same conditional-branch triangle as the scalar select; there is no wide
// conditional move to fold into.
let Predicates = [HasVendorXReviveVec] in
defm Select_VRM2 : SelectCC_GPR_rrirr<VRM2, i256>;
