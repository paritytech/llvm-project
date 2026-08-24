# RUN: llvm-mc %s -triple=riscv64 -mattr=+xrevivevec -show-encoding \
# RUN:     | FileCheck %s

# The wide instructions are compiler-generated and the decoder covers them all
# in xrevivevec-disasm.txt; what needs an assembler test is the offset the memory
# forms take, which is even and which is encoded in place rather than shifted
# down. 2046 encoding as 0x7fe rather than 0x3ff is what shows the difference,
# and it leaves the low bit of the field free to select the width later.

# CHECK: revive.wld	v8, 0(a0)
# CHECK: encoding: [0x5b,0x44,0x05,0x00]
revive.wld v8, 0(a0)
# CHECK: revive.wld	v8, 16(a0)
# CHECK: encoding: [0x5b,0x44,0x05,0x01]
revive.wld v8, 16(a0)
# CHECK: revive.wld	v10, -2048(a1)
# CHECK: encoding: [0x5b,0xc5,0x05,0x80]
revive.wld v10, -2048(a1)
# CHECK: revive.wld	v12, 2046(sp)
# CHECK: encoding: [0x5b,0x46,0xe1,0x7f]
revive.wld v12, 2046(sp)

# CHECK: revive.wst	v8, 0(a0)
# CHECK: encoding: [0x5b,0x50,0x85,0x00]
revive.wst v8, 0(a0)
# CHECK: revive.wst	v8, 16(a0)
# CHECK: encoding: [0x5b,0x58,0x85,0x00]
revive.wst v8, 16(a0)
# CHECK: revive.wst	v10, -2048(a1)
# CHECK: encoding: [0x5b,0xd0,0xa5,0x80]
revive.wst v10, -2048(a1)
# CHECK: revive.wst	v12, 2046(sp)
# CHECK: encoding: [0x5b,0x5f,0xc1,0x7e]
revive.wst v12, 2046(sp)
