//===-- RISCVInstrInfoXReviveVec.td - revive wide integer ops -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Wide integers as machine types, so the code generator never expands them into
// limb chains. EVM words are a quarter of all IR revive emits, and RISC-V has no
// carry flag, so the generic expansion pays an `sltu` per carry: 56 bytes for one
// `add i256`, 86 for `icmp ult`.
//
// Values live in the vector registers, a group to a value, and the width is a
// field of the instruction rather than of `vtype`. Everything is in custom-2:
//
//   funct3 = 000        arithmetic, compares, shifts, conversions and moves,
//                       with funct7 = {width, operation}
//   funct3 = 001        the modular operations, which are 256-bit by definition
//   funct3 = 010..101   a load at 128, 256, 512 and 1024 bits
//   funct3 = 110        a store, with the width in the top of the immediate
//
// Encoding the width rather than reading `vtype` costs nothing here -- funct7 had
// the room -- and it is what lets a consumer of the object see each instruction's
// width without following the control flow to find the configuration in force.
// Loads keep a full 12-bit immediate so a constant pool entry is still reachable
// through `%lo`; a store never needs one, so it gives up two bits for the width.
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
// Widths
//===----------------------------------------------------------------------===//

// One record per width: how it is encoded, the register group it occupies, and
// the funct3 its load uses. 128 bits has no legal type and so no patterns, but it
// still needs encodings -- a single vector register can be spilled or copied.
class ReviveWidth<bits<2> enc, string suffix, RegisterClass regclass, bits<3> ldfunct3> {
  bits<2> Enc = enc;
  string Suffix = suffix;
  RegisterClass RC = regclass;
  bits<3> LoadFunct3 = ldfunct3;
}

def ReviveW128  : ReviveWidth<0b00, "128",  VR,   0b010>;
def ReviveW256  : ReviveWidth<0b01, "256",  VRM2, 0b011>;
def ReviveW512  : ReviveWidth<0b10, "512",  VRM4, 0b100>;
def ReviveW1024 : ReviveWidth<0b11, "1024", VRM8, 0b101>;

// A store's offset uses the existing `simm10`: two bits shorter than the usual
// twelve, because the width takes the top of the field.

//===----------------------------------------------------------------------===//
// Encodings
//===----------------------------------------------------------------------===//

class RVReviveALU<bits<2> wenc, bits<5> op, string mnemonic, string suffix, RegisterClass rc>
    : RVInstR<{wenc, op}, 0b000, OPC_CUSTOM_2, (outs rc:$rd), (ins rc:$rs1, rc:$rs2),
              "revive."#mnemonic#suffix, "$rd, $rs1, $rs2">;

// Comparisons narrow to a GPR: the result feeds branches and selects.
class RVReviveCmp<bits<2> wenc, bits<5> op, string mnemonic, string suffix, RegisterClass rc>
    : RVInstR<{wenc, op}, 0b000, OPC_CUSTOM_2, (outs GPR:$rd), (ins rc:$rs1, rc:$rs2),
              "revive."#mnemonic#suffix, "$rd, $rs1, $rs2">;

// Shift amounts come from a GPR: only the low bits can matter.
class RVReviveShift<bits<2> wenc, bits<5> op, string mnemonic, string suffix, RegisterClass rc>
    : RVInstR<{wenc, op}, 0b000, OPC_CUSTOM_2, (outs rc:$rd), (ins rc:$rs1, GPR:$rs2),
              "revive."#mnemonic#suffix, "$rd, $rs1, $rs2">;

class RVReviveCvtToGPR<bits<2> wenc, bits<5> op, string mnemonic, string suffix, RegisterClass rc>
    : RVInstR<{wenc, op}, 0b000, OPC_CUSTOM_2, (outs GPR:$rd), (ins rc:$rs1),
              "revive."#mnemonic#suffix, "$rd, $rs1"> {
  let rs2 = 0;
}

class RVReviveCvtToWide<bits<2> wenc, bits<5> op, string mnemonic, string suffix, RegisterClass rc>
    : RVInstR<{wenc, op}, 0b000, OPC_CUSTOM_2, (outs rc:$rd), (ins GPR:$rs1),
              "revive."#mnemonic#suffix, "$rd, $rs1"> {
  let rs2 = 0;
}

class RVReviveUnary<bits<2> wenc, bits<5> op, string mnemonic, string suffix, RegisterClass rc>
    : RVInstR<{wenc, op}, 0b000, OPC_CUSTOM_2, (outs rc:$rd), (ins rc:$rs1),
              "revive."#mnemonic#suffix, "$rd, $rs1"> {
  let rs2 = 0;
}

// The modular operations take three wide inputs, so they need R4. They are EVM
// operations on 256-bit words, so they carry no width.
class RVReviveR4<bits<2> funct2, string opcodestr>
    : RVInstR4<funct2, 0b001, OPC_CUSTOM_2, (outs VRM2:$rd),
               (ins VRM2:$rs1, VRM2:$rs2, VRM2:$rs3), opcodestr,
               "$rd, $rs1, $rs2, $rs3">;

class RVReviveLoad<bits<3> funct3, string suffix, RegisterClass rc>
    : RVInstI<funct3, OPC_CUSTOM_2, (outs rc:$rd),
              (ins GPRMem:$rs1, simm12_lo:$imm12), "revive.ld"#suffix,
              "$rd, ${imm12}(${rs1})">;

// Written out rather than built on RVInstS, because the width takes the two bits
// above the offset.
class RVReviveStore<bits<2> wenc, string suffix, RegisterClass rc>
    : RVInst<(outs), (ins rc:$rs2, GPRMem:$rs1, simm10:$imm10),
             "revive.st"#suffix, "$rs2, ${imm10}(${rs1})", [], InstFormatS> {
  bits<10> imm10;
  bits<5> rs2;
  bits<5> rs1;

  let Inst{31-30} = wenc;
  let Inst{29-25} = imm10{9-5};
  let Inst{24-20} = rs2;
  let Inst{19-15} = rs1;
  let Inst{14-12} = 0b110;
  let Inst{11-7} = imm10{4-0};
  let Inst{6-0} = OPC_CUSTOM_2.Value;
}

//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

multiclass ReviveOps<ReviveWidth w> {
  let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
  def _ADD : RVReviveALU<w.Enc, 0, "add", w.Suffix, w.RC>;
  def _SUB : RVReviveALU<w.Enc, 1, "sub", w.Suffix, w.RC>;
  def _MUL : RVReviveALU<w.Enc, 2, "mul", w.Suffix, w.RC>;
  def _AND : RVReviveALU<w.Enc, 3, "and", w.Suffix, w.RC>;
  def _OR : RVReviveALU<w.Enc, 4, "or", w.Suffix, w.RC>;
  def _XOR : RVReviveALU<w.Enc, 5, "xor", w.Suffix, w.RC>;
  def _DIVU : RVReviveALU<w.Enc, 6, "divu", w.Suffix, w.RC>;
  def _DIV : RVReviveALU<w.Enc, 7, "div", w.Suffix, w.RC>;
  def _REMU : RVReviveALU<w.Enc, 8, "remu", w.Suffix, w.RC>;
  def _REM : RVReviveALU<w.Enc, 9, "rem", w.Suffix, w.RC>;
  def _EXP : RVReviveALU<w.Enc, 10, "exp", w.Suffix, w.RC>;
  def _SIGNEXTEND : RVReviveALU<w.Enc, 11, "signextend", w.Suffix, w.RC>;
  def _MINU : RVReviveALU<w.Enc, 12, "minu", w.Suffix, w.RC>;
  def _MIN : RVReviveALU<w.Enc, 13, "min", w.Suffix, w.RC>;
  def _MAXU : RVReviveALU<w.Enc, 14, "maxu", w.Suffix, w.RC>;
  def _MAX : RVReviveALU<w.Enc, 15, "max", w.Suffix, w.RC>;

  def _SLL : RVReviveShift<w.Enc, 16, "sll", w.Suffix, w.RC>;
  def _SRL : RVReviveShift<w.Enc, 17, "srl", w.Suffix, w.RC>;
  def _SRA : RVReviveShift<w.Enc, 18, "sra", w.Suffix, w.RC>;

  def _SEQ : RVReviveCmp<w.Enc, 19, "seq", w.Suffix, w.RC>;
  def _SNE : RVReviveCmp<w.Enc, 20, "sne", w.Suffix, w.RC>;
  def _SLTU : RVReviveCmp<w.Enc, 21, "sltu", w.Suffix, w.RC>;
  def _SLT : RVReviveCmp<w.Enc, 22, "slt", w.Suffix, w.RC>;

  def _TRUNC : RVReviveCvtToGPR<w.Enc, 23, "trunc", w.Suffix, w.RC>;
  def _ZEXT  : RVReviveCvtToWide<w.Enc, 24, "zext", w.Suffix, w.RC>;
  def _SEXT  : RVReviveCvtToWide<w.Enc, 25, "sext", w.Suffix, w.RC>;
  def _BSWAP : RVReviveUnary<w.Enc, 26, "bswap", w.Suffix, w.RC>;
  def _MV    : RVReviveUnary<w.Enc, 27, "mv", w.Suffix, w.RC>;
  }

  let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
  def _LD : RVReviveLoad<w.LoadFunct3, w.Suffix, w.RC>;

  let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
  def _ST : RVReviveStore<w.Enc, w.Suffix, w.RC>;
}

let Predicates = [HasVendorXReviveVec] in {
defm REVIVE_128  : ReviveOps<ReviveW128>;
defm REVIVE_256  : ReviveOps<ReviveW256>;
defm REVIVE_512  : ReviveOps<ReviveW512>;
defm REVIVE_1024 : ReviveOps<ReviveW1024>;

// EVM operations with no RISC-V equivalent, each replacing a stdlib.ll routine
// (__mulmod 4,534 bytes, __addmod 3,756).
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
def REVIVE_ADDMOD : RVReviveR4<0b00, "revive.addmod">;
def REVIVE_MULMOD : RVReviveR4<0b01, "revive.mulmod">;
}
} // Predicates = [HasVendorXReviveVec]

//===----------------------------------------------------------------------===//
// Selection patterns
//===----------------------------------------------------------------------===//

multiclass RVRevivePats<ReviveWidth w, ValueType vt> {
  defvar rc = w.RC;
  defvar P = "REVIVE_"#w.Suffix#"_";

  foreach p = [["add", "ADD"], ["sub", "SUB"], ["mul", "MUL"], ["and", "AND"],
               ["or", "OR"], ["xor", "XOR"], ["udiv", "DIVU"], ["sdiv", "DIV"],
               ["urem", "REMU"], ["srem", "REM"], ["umin", "MINU"],
               ["smin", "MIN"], ["umax", "MAXU"], ["smax", "MAX"]] in
    def : Pat<(vt (!cast<SDPatternOperator>(p[0]) (vt rc:$a), (vt rc:$b))),
              (!cast<Instruction>(P#p[1]) (vt rc:$a), (vt rc:$b))>;

  def : Pat<(vt (bswap (vt rc:$a))), (!cast<Instruction>(P#"BSWAP") (vt rc:$a))>;

  // Widened operands and a truncated result mean the wide instruction is doing
  // XLen work. Low bits depend only on low bits here, so the scalar one is
  // equivalent.
  foreach p = [["add", "ADD"], ["sub", "SUB"],
               ["and", "AND"], ["or", "OR"], ["xor", "XOR"]] in {
    def : Pat<(XLenVT (trunc (vt (!cast<SDPatternOperator>(p[0])
                                    (vt (zext (XLenVT GPR:$a))),
                                    (vt (zext (XLenVT GPR:$b))))))),
              (!cast<Instruction>(p[1]) GPR:$a, GPR:$b)>;
    def : Pat<(XLenVT (trunc (vt (!cast<SDPatternOperator>(p[0])
                                    (vt (riscv_wide_zext (XLenVT GPR:$a))),
                                    (vt (riscv_wide_zext (XLenVT GPR:$b))))))),
              (!cast<Instruction>(p[1]) GPR:$a, GPR:$b)>;
    // The combiner weakens the extends to anyext when only low bits are
    // demanded, so that form needs matching too.
    def : Pat<(XLenVT (trunc (vt (!cast<SDPatternOperator>(p[0])
                                    (vt (anyext (XLenVT GPR:$a))),
                                    (vt (anyext (XLenVT GPR:$b))))))),
              (!cast<Instruction>(p[1]) GPR:$a, GPR:$b)>;
  }

  // Zero extension preserves unsigned order, so the compare narrows too.
  def : Pat<(XLenVT (setcc (vt (zext (XLenVT GPR:$a))), (vt (zext (XLenVT GPR:$b))), SETULT)),
            (SLTU GPR:$a, GPR:$b)>;
  def : Pat<(XLenVT (setcc (vt (zext (XLenVT GPR:$a))), (vt (zext (XLenVT GPR:$b))), SETUGT)),
            (SLTU GPR:$b, GPR:$a)>;

  def : Pat<(vt (riscv_wide_zext (XLenVT GPR:$a))), (!cast<Instruction>(P#"ZEXT") GPR:$a)>;
  def : Pat<(vt (riscv_wide_sext (XLenVT GPR:$a))), (!cast<Instruction>(P#"SEXT") GPR:$a)>;

  // The IR types both shift operands alike; the DAG often narrows the amount
  // first, so both forms are matched.
  foreach p = [["shl", "SLL"], ["srl", "SRL"], ["sra", "SRA"]] in {
    def : Pat<(vt (!cast<SDPatternOperator>(p[0]) (vt rc:$a), (XLenVT GPR:$b))),
              (!cast<Instruction>(P#p[1]) (vt rc:$a), GPR:$b)>;
    def : Pat<(vt (!cast<SDPatternOperator>(p[0]) (vt rc:$a), (vt rc:$b))),
              (!cast<Instruction>(P#p[1]) (vt rc:$a),
                                          (!cast<Instruction>(P#"TRUNC") (vt rc:$b)))>;
  }

  foreach p = [["SETEQ", "SEQ"], ["SETNE", "SNE"], ["SETULT", "SLTU"],
               ["SETLT", "SLT"]] in
    def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), !cast<CondCode>(p[0]))),
              (!cast<Instruction>(P#p[1]) (vt rc:$a), (vt rc:$b))>;

  // The reversed forms are the same instruction with operands swapped.
  foreach p = [["SETUGT", "SLTU"], ["SETGT", "SLT"]] in
    def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), !cast<CondCode>(p[0]))),
              (!cast<Instruction>(P#p[1]) (vt rc:$b), (vt rc:$a))>;

  def : Pat<(i64 (trunc (vt rc:$a))), (!cast<Instruction>(P#"TRUNC") (vt rc:$a))>;
  def : Pat<(vt (zext (XLenVT GPR:$a))), (!cast<Instruction>(P#"ZEXT") GPR:$a)>;
  def : Pat<(vt (sext (XLenVT GPR:$a))), (!cast<Instruction>(P#"SEXT") GPR:$a)>;
  def : Pat<(vt (anyext (XLenVT GPR:$a))), (!cast<Instruction>(P#"ZEXT") GPR:$a)>;

  def : Pat<(vt (load (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
            (!cast<Instruction>(P#"LD") GPR:$rs1, simm12_lo:$imm12)>;
  def : Pat<(store (vt rc:$rs2), (AddrRegImm (XLenVT GPR:$rs1), simm10:$imm10)),
            (!cast<Instruction>(P#"ST") (vt rc:$rs2), GPR:$rs1, simm10:$imm10)>;
}

// Narrowing multiply, kept apart because scalar MUL needs the multiply
// extension; without it the wide instruction stays.
multiclass RVReviveMulPats<ValueType vt> {
  foreach ext = [zext, riscv_wide_zext, anyext] in
    def : Pat<(XLenVT (trunc (vt (mul (vt (ext (XLenVT GPR:$a))),
                                      (vt (ext (XLenVT GPR:$b))))))),
              (MUL GPR:$a, GPR:$b)>;
}

let Predicates = [HasVendorXReviveVec, HasStdExtZmmul] in {
defm : RVReviveMulPats<i256>;
defm : RVReviveMulPats<i512>;
defm : RVReviveMulPats<i1024>;
}

let Predicates = [HasVendorXReviveVec] in {
defm : RVRevivePats<ReviveW256,  i256>;
defm : RVRevivePats<ReviveW512,  i512>;
defm : RVRevivePats<ReviveW1024, i1024>;

// Only i256 has these: the widening nodes exist for constant materialisation,
// the extending loads and sign_extend_inreg for narrow memory, and the modular
// intrinsics are EVM operations that are 256-bit by definition.
def : Pat<(int_riscv_revive_addmod (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c)),
          (REVIVE_ADDMOD (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c))>;
def : Pat<(int_riscv_revive_mulmod (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c)),
          (REVIVE_MULMOD (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c))>;
def : Pat<(int_riscv_revive_exp (i256 VRM2:$a), (i256 VRM2:$b)),
          (REVIVE_256_EXP (i256 VRM2:$a), (i256 VRM2:$b))>;
def : Pat<(int_riscv_revive_signextend (i256 VRM2:$a), (i256 VRM2:$b)),
          (REVIVE_256_SIGNEXTEND (i256 VRM2:$a), (i256 VRM2:$b))>;

foreach p = [["extloadi8", "LBU", "ZEXT"], ["extloadi16", "LHU", "ZEXT"],
             ["extloadi32", "LWU", "ZEXT"], ["extloadi64", "LD", "ZEXT"],
             ["sextloadi8", "LB", "SEXT"], ["sextloadi16", "LH", "SEXT"],
             ["sextloadi32", "LW", "SEXT"]] in
  def : Pat<(i256 (!cast<SDPatternOperator>(p[0])
                      (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
            (!cast<Instruction>("REVIVE_256_"#p[2])
                (!cast<Instruction>(p[1]) GPR:$rs1, simm12_lo:$imm12))>;

def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i32)),
          (REVIVE_256_SEXT (ADDIW (REVIVE_256_TRUNC (i256 VRM2:$rs1)), 0))>;
def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i16)),
          (REVIVE_256_SEXT (SRAI (SLLI (REVIVE_256_TRUNC (i256 VRM2:$rs1)), 48), 48))>;
def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i8)),
          (REVIVE_256_SEXT (SRAI (SLLI (REVIVE_256_TRUNC (i256 VRM2:$rs1)), 56), 56))>;

// Widening between the wide widths: build a zero of the wider type and insert
// the narrower value as its low sub-register.
def : Pat<(i512 (zext (i256 VRM2:$rs1))),
          (INSERT_SUBREG (i512 (REVIVE_512_ZEXT (XLenVT X0))), (i256 VRM2:$rs1), sub_vrm2_0)>;
def : Pat<(i1024 (zext (i256 VRM2:$rs1))),
          (INSERT_SUBREG (i1024 (REVIVE_1024_ZEXT (XLenVT X0))), (i256 VRM2:$rs1), sub_vrm2_0)>;
def : Pat<(i1024 (zext (i512 VRM4:$rs1))),
          (INSERT_SUBREG (i1024 (REVIVE_1024_ZEXT (XLenVT X0))), (i512 VRM4:$rs1), sub_vrm4_0)>;

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
let Predicates = [HasVendorXReviveVec] in {
defm Select_VRM2 : SelectCC_GPR_rrirr<VRM2, i256>;
defm Select_VRM4 : SelectCC_GPR_rrirr<VRM4, i512>;
defm Select_VRM8 : SelectCC_GPR_rrirr<VRM8, i1024>;
}
