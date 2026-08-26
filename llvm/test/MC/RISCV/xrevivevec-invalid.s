# RUN: not llvm-mc -triple riscv64 -mattr=+xrevivevec < %s 2>&1 \
# RUN:     | FileCheck %s
# RUN: not llvm-mc -triple riscv64 < %s 2>&1 \
# RUN:     | FileCheck -check-prefix=CHECK-NO-EXT %s

# The offset of a wide memory instruction is an ordinary simm12, so the only
# offset left to reject is one outside it. Both widths take the offset the same
# way, so both reject the same offsets in the same words.

## Out of range
revive.wld v8, 2048(a0) # CHECK: :[[@LINE]]:16: error: operand must be a symbol with %lo/%pcrel_lo/%tprel_lo specifier or an integer in the range [-2048, 2047]
revive.wst v8, -2049(a0) # CHECK: :[[@LINE]]:16: error: operand must be a symbol with %lo/%pcrel_lo/%tprel_lo specifier or an integer in the range [-2048, 2047]
revive.wld.i128 v8, 2048(a0) # CHECK: :[[@LINE]]:21: error: operand must be a symbol with %lo/%pcrel_lo/%tprel_lo specifier or an integer in the range [-2048, 2047]
revive.wst.i128 v8, -2049(a0) # CHECK: :[[@LINE]]:21: error: operand must be a symbol with %lo/%pcrel_lo/%tprel_lo specifier or an integer in the range [-2048, 2047]

## Third operand. The conversions pin rs2 to zero: sharing funct3 000 with the
## arithmetic does not give them its second source.
revive.wmv v8, v10, v12 # CHECK: :[[@LINE]]:21: error: invalid operand for instruction
revive.wzext v8, a0, a1 # CHECK: :[[@LINE]]:22: error: invalid operand for instruction

## Without the extension. Every mnemonic here needs it, at either width.
revive.wadd.i128 v8, v8, v10 # CHECK-NO-EXT: :[[@LINE]]:1: error: instruction requires the following: 'XReviveVec' (revive 256-bit wide integer instructions)
