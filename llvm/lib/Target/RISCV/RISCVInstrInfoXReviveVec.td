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
// A wide value is a vector register group, and its width is `LMUL * VLEN` read
// from `vtype`: one `revive.wadd` covers 256, 512 and 1024 bits, whichever
// `vsetivli` is in force. No width in the encoding, so the extension fits in
// custom-2. Neither `vl` nor SEW is read; a group is one integer, not a vector.
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

// All in custom-2: funct3 selects the operand shape, funct7 the operation. No
// width is encoded, so custom-1 and custom-3 stay free.
//
// Operands are single vector registers because that is all an encoding names; the
// group each width occupies is expressed by the pseudos below, which is what the
// register allocator sees.
class RVReviveALU<bits<7> op, string opcodestr>
    : RVInstR<op, 0b000, OPC_CUSTOM_2, (outs VR:$rd),
              (ins VR:$rs1, VR:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Comparisons narrow to a GPR: the result feeds branches and selects.
class RVReviveCmp<bits<7> op, string opcodestr>
    : RVInstR<op, 0b001, OPC_CUSTOM_2, (outs GPR:$rd),
              (ins VR:$rs1, VR:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Shift amounts come from a GPR: only the low bits can matter.
class RVReviveShift<bits<7> op, string opcodestr>
    : RVInstR<op, 0b010, OPC_CUSTOM_2, (outs VR:$rd),
              (ins VR:$rs1, GPR:$rs2), opcodestr, "$rd, $rs1, $rs2">;

// Conversions between a wide value and an XLen one.
class RVReviveCvtToGPR<bits<7> op, string opcodestr>
    : RVInstR<op, 0b110, OPC_CUSTOM_2, (outs GPR:$rd), (ins VR:$rs1),
              opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

class RVReviveCvtToWide<bits<7> op, string opcodestr>
    : RVInstR<op, 0b111, OPC_CUSTOM_2, (outs VR:$rd), (ins GPR:$rs1),
              opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

// A wide unary. Copies do not need one: the RVV classes already have VMVnR_V.
class RVReviveMove<bits<7> op, string opcodestr>
    : RVInstR<op, 0b110, OPC_CUSTOM_2, (outs VR:$rd), (ins VR:$rs1),
              opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

// The modular operations take three wide inputs, so they need R4.
class RVReviveR4<bits<2> funct2, string opcodestr>
    : RVInstR4<funct2, 0b011, OPC_CUSTOM_2, (outs VR:$rd),
               (ins VR:$rs1, VR:$rs2, VR:$rs3), opcodestr,
               "$rd, $rs1, $rs2, $rs3">;

let Predicates = [HasVendorXReviveVec] in {
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
def REVIVE_W_ADD     : RVReviveALU<0b0000000, "revive.wadd">;
def REVIVE_W_SUB     : RVReviveALU<0b0000001, "revive.wsub">;
def REVIVE_W_MUL     : RVReviveALU<0b0000010, "revive.wmul">;
def REVIVE_W_AND     : RVReviveALU<0b0000011, "revive.wand">;
def REVIVE_W_OR      : RVReviveALU<0b0000100, "revive.wor">;
def REVIVE_W_XOR     : RVReviveALU<0b0000101, "revive.wxor">;
def REVIVE_W_UDIV    : RVReviveALU<0b0000110, "revive.wdivu">;
def REVIVE_W_SDIV    : RVReviveALU<0b0000111, "revive.wdiv">;
def REVIVE_W_UREM    : RVReviveALU<0b0001000, "revive.wremu">;
def REVIVE_W_SREM    : RVReviveALU<0b0001001, "revive.wrem">;
def REVIVE_W_EXP     : RVReviveALU<0b0001010, "revive.wexp">;
def REVIVE_W_SIGNEXT : RVReviveALU<0b0001011, "revive.wsignextend">;
def REVIVE_W_MINU    : RVReviveALU<0b0001100, "revive.wminu">;
def REVIVE_W_MIN     : RVReviveALU<0b0001101, "revive.wmin">;
def REVIVE_W_MAXU    : RVReviveALU<0b0001110, "revive.wmaxu">;
def REVIVE_W_MAX     : RVReviveALU<0b0001111, "revive.wmax">;

def REVIVE_W_SLL : RVReviveShift<0b0000000, "revive.wsll">;
def REVIVE_W_SRL : RVReviveShift<0b0000001, "revive.wsrl">;
def REVIVE_W_SRA : RVReviveShift<0b0000010, "revive.wsra">;

// `icmp ult` is 6% of all IR revive emits and the most expensive frequent
// operation: the generic expansion walks limbs from the top, branching at each.
def REVIVE_W_SEQ  : RVReviveCmp<0b0000000, "revive.wseq">;
def REVIVE_W_SNE  : RVReviveCmp<0b0000001, "revive.wsne">;
def REVIVE_W_SLTU : RVReviveCmp<0b0000010, "revive.wsltu">;
def REVIVE_W_SLT  : RVReviveCmp<0b0000011, "revive.wslt">;

def REVIVE_W_TRUNC : RVReviveCvtToGPR<0b0000001, "revive.wtrunc">;
def REVIVE_W_ZEXT  : RVReviveCvtToWide<0b0000000, "revive.wzext">;
def REVIVE_W_SEXT  : RVReviveCvtToWide<0b0000001, "revive.wsext">;
def REVIVE_W_BSWAP : RVReviveMove<0b0000010, "revive.wbswap">;

// EVM operations with no RISC-V equivalent, each replacing a stdlib.ll routine
// (__mulmod 4,534 bytes, __addmod 3,756).
def REVIVE_W_ADDMOD : RVReviveR4<0b00, "revive.waddmod">;
def REVIVE_W_MULMOD : RVReviveR4<0b01, "revive.wmulmod">;
} // hasSideEffects = 0, mayLoad = 0, mayStore = 0

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def REVIVE_W_LD : RVInstI<0b100, OPC_CUSTOM_2, (outs VR:$rd),
                          (ins GPRMem:$rs1, simm12_lo:$imm12),
                          "revive.wld", "$rd, ${imm12}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def REVIVE_W_ST : RVInstS<0b101, OPC_CUSTOM_2, (outs),
                          (ins VR:$rs2, GPRMem:$rs1, simm12_lo:$imm12),
                          "revive.wst", "$rs2, ${imm12}(${rs1})">;
} // Predicates = [HasVendorXReviveVec]

//===----------------------------------------------------------------------===//
// Pseudos, one per width
//===----------------------------------------------------------------------===//

// These carry the width the encodings do not: each names its register class and
// LMUL, so RISCVInsertVSETVLI emits the `vsetivli` for it and elides the rest.
// RISCVVPseudosTable maps them back to the one encoding by the width suffix.
//
// SEW is 64 because a vtype must name one. At VLEN=128 that puts VLMAX at 4, 8
// and 16 -- under 32, so the configuration stays in its immediate form.
defvar ReviveLog2SEW = 6;
defvar ReviveLMULs = [V_M2, V_M4, V_M8];

// `BaseInstr` is named, not derived: PseudoToVInst strips `_SE`, which would map
// REVIVE_W_SEQ to REVIVE_WQ and REVIVE_W_SEXT to REVIVE_WXT.
class ReviveWidePseudo<dag outs, dag ins, LMULInfo m, Instruction base>
    : RISCVVPseudo<outs, ins> {
  let BaseInstr = base;
  let VLMul = m.value;
  let HasVLOp = 1;
  let HasSEWOp = 1;
  let hasSideEffects = 0;
  let mayLoad = 0;
  let mayStore = 0;
}

multiclass ReviveWideALUPseudo<Instruction base> {
  foreach m = ReviveLMULs in
    def "_"#m.MX : ReviveWidePseudo<(outs m.vrclass:$rd),
                                    (ins m.vrclass:$rs1, m.vrclass:$rs2,
                                         AVL:$vl, sew:$sew), m, base>;
}

multiclass ReviveWideShiftPseudo<Instruction base> {
  foreach m = ReviveLMULs in
    def "_"#m.MX : ReviveWidePseudo<(outs m.vrclass:$rd),
                                    (ins m.vrclass:$rs1, GPR:$rs2,
                                         AVL:$vl, sew:$sew), m, base>;
}

multiclass ReviveWideCmpPseudo<Instruction base> {
  foreach m = ReviveLMULs in
    def "_"#m.MX : ReviveWidePseudo<(outs GPR:$rd),
                                    (ins m.vrclass:$rs1, m.vrclass:$rs2,
                                         AVL:$vl, sew:$sew), m, base>;
}

multiclass ReviveWideToGPRPseudo<Instruction base> {
  foreach m = ReviveLMULs in
    def "_"#m.MX : ReviveWidePseudo<(outs GPR:$rd),
                                    (ins m.vrclass:$rs1, AVL:$vl, sew:$sew), m, base>;
}

multiclass ReviveWideFromGPRPseudo<Instruction base> {
  foreach m = ReviveLMULs in
    def "_"#m.MX : ReviveWidePseudo<(outs m.vrclass:$rd),
                                    (ins GPR:$rs1, AVL:$vl, sew:$sew), m, base>;
}

multiclass ReviveWideUnaryPseudo<Instruction base> {
  foreach m = ReviveLMULs in
    def "_"#m.MX : ReviveWidePseudo<(outs m.vrclass:$rd),
                                    (ins m.vrclass:$rs1, AVL:$vl, sew:$sew), m, base>;
}

multiclass ReviveWideR4Pseudo<Instruction base> {
  foreach m = ReviveLMULs in
    def "_"#m.MX : ReviveWidePseudo<(outs m.vrclass:$rd),
                                    (ins m.vrclass:$rs1, m.vrclass:$rs2,
                                         m.vrclass:$rs3, AVL:$vl, sew:$sew), m, base>;
}

multiclass ReviveWideLoadPseudo<Instruction base> {
  foreach m = ReviveLMULs in
    def "_"#m.MX : ReviveWidePseudo<(outs m.vrclass:$rd),
                                    (ins GPRMem:$rs1, simm12_lo:$imm12,
                                         AVL:$vl, sew:$sew), m, base> {
      let mayLoad = 1;
    }
}

multiclass ReviveWideStorePseudo<Instruction base> {
  foreach m = ReviveLMULs in
    def "_"#m.MX : ReviveWidePseudo<(outs),
                                    (ins m.vrclass:$rs2, GPRMem:$rs1,
                                         simm12_lo:$imm12, AVL:$vl, sew:$sew), m, base> {
      let mayStore = 1;
    }
}

let Predicates = [HasVendorXReviveVec] in {
foreach op = ["ADD", "SUB", "MUL", "AND", "OR", "XOR", "UDIV", "SDIV", "UREM",
              "SREM", "EXP", "SIGNEXT", "MINU", "MIN", "MAXU", "MAX"] in
  defm "PseudoREVIVE_W_"#op : ReviveWideALUPseudo<!cast<Instruction>("REVIVE_W_"#op)>;

foreach op = ["SLL", "SRL", "SRA"] in
  defm "PseudoREVIVE_W_"#op : ReviveWideShiftPseudo<!cast<Instruction>("REVIVE_W_"#op)>;

foreach op = ["SEQ", "SNE", "SLTU", "SLT"] in
  defm "PseudoREVIVE_W_"#op : ReviveWideCmpPseudo<!cast<Instruction>("REVIVE_W_"#op)>;

defm PseudoREVIVE_W_TRUNC : ReviveWideToGPRPseudo<REVIVE_W_TRUNC>;
defm PseudoREVIVE_W_ZEXT  : ReviveWideFromGPRPseudo<REVIVE_W_ZEXT>;
defm PseudoREVIVE_W_SEXT  : ReviveWideFromGPRPseudo<REVIVE_W_SEXT>;
defm PseudoREVIVE_W_BSWAP : ReviveWideUnaryPseudo<REVIVE_W_BSWAP>;

foreach op = ["ADDMOD", "MULMOD"] in
  defm "PseudoREVIVE_W_"#op : ReviveWideR4Pseudo<!cast<Instruction>("REVIVE_W_"#op)>;

defm PseudoREVIVE_W_LD : ReviveWideLoadPseudo<REVIVE_W_LD>;
defm PseudoREVIVE_W_ST : ReviveWideStorePseudo<REVIVE_W_ST>;
} // Predicates = [HasVendorXReviveVec]

//===----------------------------------------------------------------------===//
// Selection patterns
//===----------------------------------------------------------------------===//

multiclass RVRevivePats<LMULInfo m, ValueType vt> {
  defvar rc = m.vrclass;
  // Each reads vtype for its width, so each carries the AVL and SEW naming its LMUL.
  defvar P = "PseudoREVIVE_W_";
  defvar S = "_"#m.MX;

  foreach p = [["add", "ADD"], ["sub", "SUB"], ["mul", "MUL"], ["and", "AND"],
               ["or", "OR"], ["xor", "XOR"], ["udiv", "UDIV"], ["sdiv", "SDIV"],
               ["urem", "UREM"], ["srem", "SREM"], ["umin", "MINU"],
               ["smin", "MIN"], ["umax", "MAXU"], ["smax", "MAX"]] in
    def : Pat<(vt (!cast<SDPatternOperator>(p[0]) (vt rc:$a), (vt rc:$b))),
              (!cast<Instruction>(P#p[1]#S) (vt rc:$a), (vt rc:$b),
                                            (VLMax), ReviveLog2SEW)>;

  def : Pat<(vt (bswap (vt rc:$a))),
            (!cast<Instruction>(P#"BSWAP"#S) (vt rc:$a), (VLMax), ReviveLog2SEW)>;

  // Widened operands and a truncated result mean the wide instruction is doing
  // XLen work. Low bits depend only on low bits here, so the scalar one is
  // equivalent -- and it needs no vtype at all.
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

  def : Pat<(vt (riscv_wide_zext (XLenVT GPR:$a))),
            (!cast<Instruction>(P#"ZEXT"#S) GPR:$a, (VLMax), ReviveLog2SEW)>;
  def : Pat<(vt (riscv_wide_sext (XLenVT GPR:$a))),
            (!cast<Instruction>(P#"SEXT"#S) GPR:$a, (VLMax), ReviveLog2SEW)>;

  // The IR types both shift operands alike; the DAG often narrows the amount
  // first, so both forms are matched.
  foreach p = [["shl", "SLL"], ["srl", "SRL"], ["sra", "SRA"]] in {
    def : Pat<(vt (!cast<SDPatternOperator>(p[0]) (vt rc:$a), (XLenVT GPR:$b))),
              (!cast<Instruction>(P#p[1]#S) (vt rc:$a), GPR:$b,
                                            (VLMax), ReviveLog2SEW)>;
    def : Pat<(vt (!cast<SDPatternOperator>(p[0]) (vt rc:$a), (vt rc:$b))),
              (!cast<Instruction>(P#p[1]#S)
                  (vt rc:$a),
                  (!cast<Instruction>(P#"TRUNC"#S) (vt rc:$b), (VLMax), ReviveLog2SEW),
                  (VLMax), ReviveLog2SEW)>;
  }

  foreach p = [["SETEQ", "SEQ"], ["SETNE", "SNE"], ["SETULT", "SLTU"],
               ["SETLT", "SLT"]] in
    def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), !cast<CondCode>(p[0]))),
              (!cast<Instruction>(P#p[1]#S) (vt rc:$a), (vt rc:$b),
                                            (VLMax), ReviveLog2SEW)>;

  // The reversed forms are the same instruction with operands swapped.
  foreach p = [["SETUGT", "SLTU"], ["SETGT", "SLT"]] in
    def : Pat<(XLenVT (setcc (vt rc:$a), (vt rc:$b), !cast<CondCode>(p[0]))),
              (!cast<Instruction>(P#p[1]#S) (vt rc:$b), (vt rc:$a),
                                            (VLMax), ReviveLog2SEW)>;

  def : Pat<(i64 (trunc (vt rc:$a))),
            (!cast<Instruction>(P#"TRUNC"#S) (vt rc:$a), (VLMax), ReviveLog2SEW)>;
  def : Pat<(vt (zext (XLenVT GPR:$a))),
            (!cast<Instruction>(P#"ZEXT"#S) GPR:$a, (VLMax), ReviveLog2SEW)>;
  def : Pat<(vt (sext (XLenVT GPR:$a))),
            (!cast<Instruction>(P#"SEXT"#S) GPR:$a, (VLMax), ReviveLog2SEW)>;
  def : Pat<(vt (anyext (XLenVT GPR:$a))),
            (!cast<Instruction>(P#"ZEXT"#S) GPR:$a, (VLMax), ReviveLog2SEW)>;

  def : Pat<(vt (load (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
            (!cast<Instruction>(P#"LD"#S) GPR:$rs1, simm12_lo:$imm12,
                                          (VLMax), ReviveLog2SEW)>;
  def : Pat<(store (vt rc:$rs2), (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12)),
            (!cast<Instruction>(P#"ST"#S) (vt rc:$rs2), GPR:$rs1, simm12_lo:$imm12,
                                          (VLMax), ReviveLog2SEW)>;
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
defm : RVRevivePats<V_M2, i256>;
defm : RVRevivePats<V_M4, i512>;
defm : RVRevivePats<V_M8, i1024>;

// Only i256 has these: the widening nodes exist for constant materialisation,
// the extending loads and sign_extend_inreg for narrow memory, and the modular
// intrinsics are EVM operations that are 256-bit by definition.
def : Pat<(int_riscv_revive_addmod (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c)),
          (PseudoREVIVE_W_ADDMOD_M2 (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c),
                                    (VLMax), ReviveLog2SEW)>;
def : Pat<(int_riscv_revive_mulmod (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c)),
          (PseudoREVIVE_W_MULMOD_M2 (i256 VRM2:$a), (i256 VRM2:$b), (i256 VRM2:$c),
                                    (VLMax), ReviveLog2SEW)>;
def : Pat<(int_riscv_revive_exp (i256 VRM2:$a), (i256 VRM2:$b)),
          (PseudoREVIVE_W_EXP_M2 (i256 VRM2:$a), (i256 VRM2:$b),
                                 (VLMax), ReviveLog2SEW)>;
def : Pat<(int_riscv_revive_signextend (i256 VRM2:$a), (i256 VRM2:$b)),
          (PseudoREVIVE_W_SIGNEXT_M2 (i256 VRM2:$a), (i256 VRM2:$b),
                                     (VLMax), ReviveLog2SEW)>;

foreach p = [["extloadi8", "LBU", "ZEXT"], ["extloadi16", "LHU", "ZEXT"],
             ["extloadi32", "LWU", "ZEXT"], ["extloadi64", "LD", "ZEXT"],
             ["sextloadi8", "LB", "SEXT"], ["sextloadi16", "LH", "SEXT"],
             ["sextloadi32", "LW", "SEXT"]] in
  def : Pat<(i256 (!cast<SDPatternOperator>(p[0])
                      (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
            (!cast<Instruction>("PseudoREVIVE_W_"#p[2]#"_M2")
                (!cast<Instruction>(p[1]) GPR:$rs1, simm12_lo:$imm12),
                (VLMax), ReviveLog2SEW)>;

def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i32)),
          (PseudoREVIVE_W_SEXT_M2
              (ADDIW (PseudoREVIVE_W_TRUNC_M2 (i256 VRM2:$rs1), (VLMax), ReviveLog2SEW), 0),
              (VLMax), ReviveLog2SEW)>;
def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i16)),
          (PseudoREVIVE_W_SEXT_M2
              (SRAI (SLLI (PseudoREVIVE_W_TRUNC_M2 (i256 VRM2:$rs1), (VLMax), ReviveLog2SEW), 48), 48),
              (VLMax), ReviveLog2SEW)>;
def : Pat<(i256 (sext_inreg (i256 VRM2:$rs1), i8)),
          (PseudoREVIVE_W_SEXT_M2
              (SRAI (SLLI (PseudoREVIVE_W_TRUNC_M2 (i256 VRM2:$rs1), (VLMax), ReviveLog2SEW), 56), 56),
              (VLMax), ReviveLog2SEW)>;

// Widening between the wide widths: build a zero of the wider type and insert
// the narrower value as its low sub-register.
def : Pat<(i512 (zext (i256 VRM2:$rs1))),
          (INSERT_SUBREG (i512 (PseudoREVIVE_W_ZEXT_M4 (XLenVT X0), (VLMax), ReviveLog2SEW)),
                         (i256 VRM2:$rs1), sub_vrm2_0)>;
def : Pat<(i1024 (zext (i256 VRM2:$rs1))),
          (INSERT_SUBREG (i1024 (PseudoREVIVE_W_ZEXT_M8 (XLenVT X0), (VLMax), ReviveLog2SEW)),
                         (i256 VRM2:$rs1), sub_vrm2_0)>;
def : Pat<(i1024 (zext (i512 VRM4:$rs1))),
          (INSERT_SUBREG (i1024 (PseudoREVIVE_W_ZEXT_M8 (XLenVT X0), (VLMax), ReviveLog2SEW)),
                         (i512 VRM4:$rs1), sub_vrm4_0)>;

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
