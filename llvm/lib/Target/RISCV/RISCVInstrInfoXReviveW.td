//===-- RISCVInstrInfoXReviveW.td - revive wide ints, W file -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Prototype variant of XReviveVec: i256 lives in a dedicated 16-entry register
// file (W0-W15) instead of reused RVV groups, and the width is fixed at 256 bits
// so there is no vtype / vsetivli. The custom-2 encodings are identical to the
// vector variant -- only the register class differs -- so the PolkaVM linker
// decodes them the same way (it defaults an unresolved width to 256 bits under
// this variant, since no SetVtype is emitted). The instructions are
// isCodeGenOnly to avoid asm/disasm encoding clashes with the VR-based ones.
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXReviveW], isCodeGenOnly = 1 in {

// funct3 selects the operand shape, funct7 the operation (same as the vector
// variant); operands are single W registers -- the 256-bit value is the register.
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
class WReviveALU<bits<7> op, string s>
    : RVInstR<op, 0b000, OPC_CUSTOM_2, (outs WR:$rd), (ins WR:$rs1, WR:$rs2),
              s, "$rd, $rs1, $rs2">;
class WReviveShift<bits<7> op, string s>
    : RVInstR<op, 0b010, OPC_CUSTOM_2, (outs WR:$rd), (ins WR:$rs1, GPR:$rs2),
              s, "$rd, $rs1, $rs2">;
class WReviveCmp<bits<7> op, string s>
    : RVInstR<op, 0b001, OPC_CUSTOM_2, (outs GPR:$rd), (ins WR:$rs1, WR:$rs2),
              s, "$rd, $rs1, $rs2">;
class WReviveCvtToGPR<bits<7> op, string s>
    : RVInstR<op, 0b110, OPC_CUSTOM_2, (outs GPR:$rd), (ins WR:$rs1),
              s, "$rd, $rs1"> { let rs2 = 0; }
class WReviveCvtToWide<bits<7> op, string s>
    : RVInstR<op, 0b111, OPC_CUSTOM_2, (outs WR:$rd), (ins GPR:$rs1),
              s, "$rd, $rs1"> { let rs2 = 0; }
class WReviveUnary<bits<7> op, string s>
    : RVInstR<op, 0b110, OPC_CUSTOM_2, (outs WR:$rd), (ins WR:$rs1),
              s, "$rd, $rs1"> { let rs2 = 0; }
class WReviveR4<bits<2> f2, string s>
    : RVInstR4<f2, 0b011, OPC_CUSTOM_2, (outs WR:$rd),
               (ins WR:$rs1, WR:$rs2, WR:$rs3), s, "$rd, $rs1, $rs2, $rs3">;

def REVIVEW_ADD     : WReviveALU<0b0000000, "revive.wadd">;
def REVIVEW_SUB     : WReviveALU<0b0000001, "revive.wsub">;
def REVIVEW_MUL     : WReviveALU<0b0000010, "revive.wmul">;
def REVIVEW_AND     : WReviveALU<0b0000011, "revive.wand">;
def REVIVEW_OR      : WReviveALU<0b0000100, "revive.wor">;
def REVIVEW_XOR     : WReviveALU<0b0000101, "revive.wxor">;
def REVIVEW_UDIV    : WReviveALU<0b0000110, "revive.wdivu">;
def REVIVEW_SDIV    : WReviveALU<0b0000111, "revive.wdiv">;
def REVIVEW_UREM    : WReviveALU<0b0001000, "revive.wremu">;
def REVIVEW_SREM    : WReviveALU<0b0001001, "revive.wrem">;
def REVIVEW_EXP     : WReviveALU<0b0001010, "revive.wexp">;
def REVIVEW_SIGNEXT : WReviveALU<0b0001011, "revive.wsignextend">;
def REVIVEW_MINU    : WReviveALU<0b0001100, "revive.wminu">;
def REVIVEW_MIN     : WReviveALU<0b0001101, "revive.wmin">;
def REVIVEW_MAXU    : WReviveALU<0b0001110, "revive.wmaxu">;
def REVIVEW_MAX     : WReviveALU<0b0001111, "revive.wmax">;

def REVIVEW_SLL : WReviveShift<0b0000000, "revive.wsll">;
def REVIVEW_SRL : WReviveShift<0b0000001, "revive.wsrl">;
def REVIVEW_SRA : WReviveShift<0b0000010, "revive.wsra">;

def REVIVEW_SEQ  : WReviveCmp<0b0000000, "revive.wseq">;
def REVIVEW_SNE  : WReviveCmp<0b0000001, "revive.wsne">;
def REVIVEW_SLTU : WReviveCmp<0b0000010, "revive.wsltu">;
def REVIVEW_SLT  : WReviveCmp<0b0000011, "revive.wslt">;

def REVIVEW_TRUNC : WReviveCvtToGPR<0b0000001, "revive.wtrunc">;
def REVIVEW_ZEXT  : WReviveCvtToWide<0b0000000, "revive.wzext">;
def REVIVEW_SEXT  : WReviveCvtToWide<0b0000001, "revive.wsext">;
def REVIVEW_BSWAP : WReviveUnary<0b0000010, "revive.wbswap">;

def REVIVEW_ADDMOD : WReviveR4<0b00, "revive.waddmod">;
def REVIVEW_MULMOD : WReviveR4<0b01, "revive.wmulmod">;

// A whole-register move of one 256-bit W value. i256 spans two 128-bit slots, so
// the move count in funct7 must be 0b01 (wmv2r / lmul 1 = 256 bits); 0b00 (wmv1r)
// would copy only the low 128 bits and drop the high half. Used by copyPhysReg.
def REVIVEW_MV : RVInstR<{0b01, 0b00000}, 0b110, OPC_CUSTOM_2,
                         (outs WR:$rd), (ins WR:$rs1), "revive.wmv2r", "$rd, $rs1"> {
  let rs2 = 0;
}
} // hasSideEffects = 0, mayLoad = 0, mayStore = 0

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def REVIVEW_LD : RVInstI<0b100, OPC_CUSTOM_2, (outs WR:$rd),
                         (ins GPRMem:$rs1, simm12_lo:$imm12),
                         "revive.wld", "$rd, ${imm12}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def REVIVEW_ST : RVInstS<0b101, OPC_CUSTOM_2, (outs),
                         (ins WR:$rs2, GPRMem:$rs1, simm12_lo:$imm12),
                         "revive.wst", "$rs2, ${imm12}(${rs1})">;
} // Predicates = [HasVendorXReviveW], isCodeGenOnly = 1

//===----------------------------------------------------------------------===//
// Selection patterns (i256 only; no vtype operands)
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXReviveW] in {
defvar vt = i256;

// One instruction per wide binop, div/rem included. div/rem require
// setMaxDivRemBitWidthSupported to be raised to >= 256 (see RISCVISelLowering), or
// the ExpandLargeDivRem IR pass rewrites i256 div/rem into a software limb loop
// before these patterns ever run.
foreach p = [["add", "ADD"], ["sub", "SUB"], ["mul", "MUL"], ["and", "AND"],
             ["or", "OR"], ["xor", "XOR"], ["udiv", "UDIV"], ["sdiv", "SDIV"],
             ["urem", "UREM"], ["srem", "SREM"], ["umin", "MINU"],
             ["smin", "MIN"], ["umax", "MAXU"], ["smax", "MAX"]] in
  def : Pat<(vt (!cast<SDPatternOperator>(p[0]) (vt WR:$a), (vt WR:$b))),
            (!cast<Instruction>("REVIVEW_"#p[1]) WR:$a, WR:$b)>;

def : Pat<(vt (bswap (vt WR:$a))), (REVIVEW_BSWAP WR:$a)>;

// Narrow work: widened operands with a truncated result is XLen arithmetic.
foreach p = [["add", "ADD"], ["sub", "SUB"], ["and", "AND"], ["or", "OR"],
             ["xor", "XOR"]] in {
  def : Pat<(XLenVT (trunc (vt (!cast<SDPatternOperator>(p[0])
                                  (vt (zext (XLenVT GPR:$a))),
                                  (vt (zext (XLenVT GPR:$b))))))),
            (!cast<Instruction>(p[1]) GPR:$a, GPR:$b)>;
  def : Pat<(XLenVT (trunc (vt (!cast<SDPatternOperator>(p[0])
                                  (vt (riscv_wide_zext (XLenVT GPR:$a))),
                                  (vt (riscv_wide_zext (XLenVT GPR:$b))))))),
            (!cast<Instruction>(p[1]) GPR:$a, GPR:$b)>;
  def : Pat<(XLenVT (trunc (vt (!cast<SDPatternOperator>(p[0])
                                  (vt (anyext (XLenVT GPR:$a))),
                                  (vt (anyext (XLenVT GPR:$b))))))),
            (!cast<Instruction>(p[1]) GPR:$a, GPR:$b)>;
}

def : Pat<(XLenVT (setcc (vt (zext (XLenVT GPR:$a))), (vt (zext (XLenVT GPR:$b))), SETULT)),
          (SLTU GPR:$a, GPR:$b)>;
def : Pat<(XLenVT (setcc (vt (zext (XLenVT GPR:$a))), (vt (zext (XLenVT GPR:$b))), SETUGT)),
          (SLTU GPR:$b, GPR:$a)>;

def : Pat<(vt (riscv_wide_zext (XLenVT GPR:$a))), (REVIVEW_ZEXT GPR:$a)>;
def : Pat<(vt (riscv_wide_sext (XLenVT GPR:$a))), (REVIVEW_SEXT GPR:$a)>;

// Shifts: amount from a GPR, or a wide amount truncated first.
foreach p = [["shl", "SLL"], ["srl", "SRL"], ["sra", "SRA"]] in {
  def : Pat<(vt (!cast<SDPatternOperator>(p[0]) (vt WR:$a), (XLenVT GPR:$b))),
            (!cast<Instruction>("REVIVEW_"#p[1]) WR:$a, GPR:$b)>;
  def : Pat<(vt (!cast<SDPatternOperator>(p[0]) (vt WR:$a), (vt WR:$b))),
            (!cast<Instruction>("REVIVEW_"#p[1]) WR:$a, (REVIVEW_TRUNC WR:$b))>;
}

foreach p = [["SETEQ", "SEQ"], ["SETNE", "SNE"], ["SETULT", "SLTU"],
             ["SETLT", "SLT"]] in
  def : Pat<(XLenVT (setcc (vt WR:$a), (vt WR:$b), !cast<CondCode>(p[0]))),
            (!cast<Instruction>("REVIVEW_"#p[1]) WR:$a, WR:$b)>;
foreach p = [["SETUGT", "SLTU"], ["SETGT", "SLT"]] in
  def : Pat<(XLenVT (setcc (vt WR:$a), (vt WR:$b), !cast<CondCode>(p[0]))),
            (!cast<Instruction>("REVIVEW_"#p[1]) WR:$b, WR:$a)>;

def : Pat<(i64 (trunc (vt WR:$a))), (REVIVEW_TRUNC WR:$a)>;
def : Pat<(vt (zext (XLenVT GPR:$a))), (REVIVEW_ZEXT GPR:$a)>;
def : Pat<(vt (sext (XLenVT GPR:$a))), (REVIVEW_SEXT GPR:$a)>;
def : Pat<(vt (anyext (XLenVT GPR:$a))), (REVIVEW_ZEXT GPR:$a)>;

def : Pat<(vt (load (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
          (REVIVEW_LD GPR:$rs1, simm12_lo:$imm12)>;
def : Pat<(store (vt WR:$rs2), (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12)),
          (REVIVEW_ST WR:$rs2, GPR:$rs1, simm12_lo:$imm12)>;

// Narrowing multiply to scalar needs the multiply extension.
let Predicates = [HasVendorXReviveW, HasStdExtZmmul] in
foreach ext = [zext, riscv_wide_zext, anyext] in
  def : Pat<(XLenVT (trunc (vt (mul (vt (ext (XLenVT GPR:$a))),
                                    (vt (ext (XLenVT GPR:$b))))))),
            (MUL GPR:$a, GPR:$b)>;

// Extending loads: scalar load then widen.
foreach p = [["extloadi8", "LBU"], ["extloadi16", "LHU"], ["extloadi32", "LWU"],
             ["extloadi64", "LD"]] in
  def : Pat<(vt (!cast<SDPatternOperator>(p[0])
                    (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
            (REVIVEW_ZEXT (!cast<Instruction>(p[1]) GPR:$rs1, simm12_lo:$imm12))>;
foreach p = [["sextloadi8", "LB"], ["sextloadi16", "LH"], ["sextloadi32", "LW"]] in
  def : Pat<(vt (!cast<SDPatternOperator>(p[0])
                    (AddrRegImm (XLenVT GPR:$rs1), simm12_lo:$imm12))),
            (REVIVEW_SEXT (!cast<Instruction>(p[1]) GPR:$rs1, simm12_lo:$imm12))>;

def : Pat<(vt (sext_inreg (vt WR:$rs1), i32)),
          (REVIVEW_SEXT (ADDIW (REVIVEW_TRUNC WR:$rs1), 0))>;
def : Pat<(vt (sext_inreg (vt WR:$rs1), i16)),
          (REVIVEW_SEXT (SRAI (SLLI (REVIVEW_TRUNC WR:$rs1), 48), 48))>;
def : Pat<(vt (sext_inreg (vt WR:$rs1), i8)),
          (REVIVEW_SEXT (SRAI (SLLI (REVIVEW_TRUNC WR:$rs1), 56), 56))>;

// EVM modular intrinsics (256-bit by definition).
def : Pat<(int_riscv_revive_addmod (vt WR:$a), (vt WR:$b), (vt WR:$c)),
          (REVIVEW_ADDMOD WR:$a, WR:$b, WR:$c)>;
def : Pat<(int_riscv_revive_mulmod (vt WR:$a), (vt WR:$b), (vt WR:$c)),
          (REVIVEW_MULMOD WR:$a, WR:$b, WR:$c)>;
def : Pat<(int_riscv_revive_exp (vt WR:$a), (vt WR:$b)),
          (REVIVEW_EXP WR:$a, WR:$b)>;
def : Pat<(int_riscv_revive_signextend (vt WR:$a), (vt WR:$b)),
          (REVIVEW_SIGNEXT WR:$a, WR:$b)>;

// Select: same conditional-branch triangle as the vector variant.
defm Select_WR : SelectCC_GPR_rrirr<WR, i256>;
} // Predicates = [HasVendorXReviveW]
