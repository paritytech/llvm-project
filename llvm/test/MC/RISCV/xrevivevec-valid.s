# RUN: llvm-mc %s -triple=riscv64 -mattr=+xrevivevec -show-encoding \
# RUN:     | FileCheck %s

# The wide instructions are compiler-generated and the decoder covers them all
# in xrevivevec-disasm.txt; what needs an assembler test at 256 bits is the
# offset the memory forms take, which is even and which is encoded in place
# rather than shifted down. 2046 encoding as 0x7fe rather than 0x3ff is what
# shows the difference, and it leaves the low bit of the field free to select
# the width.
#
# The 128-bit family is covered whole: the decoder test says what a word means
# but not that the assembler emits that word, and a single bit of every encoding
# is all that separates the two widths.

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

# The 128-bit width, whose instructions differ from the 256-bit ones by one
# funct7 bit in the register forms and by the low bit of the offset field in the
# memory forms.
# CHECK: revive.wadd.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x80]
revive.wadd.i128 v8, v8, v10
# CHECK: revive.wsub.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x82]
revive.wsub.i128 v8, v8, v10
# CHECK: revive.wmul.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x84]
revive.wmul.i128 v8, v8, v10
# CHECK: revive.wand.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x86]
revive.wand.i128 v8, v8, v10
# CHECK: revive.wor.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x88]
revive.wor.i128 v8, v8, v10
# CHECK: revive.wxor.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x8a]
revive.wxor.i128 v8, v8, v10
# CHECK: revive.wdivu.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x8c]
revive.wdivu.i128 v8, v8, v10
# CHECK: revive.wdiv.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x8e]
revive.wdiv.i128 v8, v8, v10
# CHECK: revive.wremu.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x90]
revive.wremu.i128 v8, v8, v10
# CHECK: revive.wrem.i128	v8, v8, v10
# CHECK: encoding: [0x5b,0x04,0xa4,0x92]
revive.wrem.i128 v8, v8, v10

# One register to a value rather than a pair, so the odd registers are operands
# here too.
# CHECK: revive.wadd.i128	v9, v11, v13
# CHECK: encoding: [0xdb,0x84,0xd5,0x80]
revive.wadd.i128 v9, v11, v13
# CHECK: revive.wxor.i128	v31, v31, v1
# CHECK: encoding: [0xdb,0x8f,0x1f,0x8a]
revive.wxor.i128 v31, v31, v1

# The shift amount comes from a GPR.
# CHECK: revive.wsll.i128	v8, v8, a0
# CHECK: encoding: [0x5b,0x24,0xa4,0x80]
revive.wsll.i128 v8, v8, a0
# CHECK: revive.wsrl.i128	v8, v8, a0
# CHECK: encoding: [0x5b,0x24,0xa4,0x82]
revive.wsrl.i128 v8, v8, a0
# CHECK: revive.wsra.i128	v8, v8, a0
# CHECK: encoding: [0x5b,0x24,0xa4,0x84]
revive.wsra.i128 v8, v8, a0

# CHECK: revive.wseq.i128	a0, v8, v10
# CHECK: encoding: [0x5b,0x15,0xa4,0x80]
revive.wseq.i128 a0, v8, v10
# CHECK: revive.wsne.i128	a0, v8, v10
# CHECK: encoding: [0x5b,0x15,0xa4,0x82]
revive.wsne.i128 a0, v8, v10
# CHECK: revive.wsltu.i128	a0, v8, v10
# CHECK: encoding: [0x5b,0x15,0xa4,0x84]
revive.wsltu.i128 a0, v8, v10
# CHECK: revive.wslt.i128	a0, v8, v10
# CHECK: encoding: [0x5b,0x15,0xa4,0x86]
revive.wslt.i128 a0, v8, v10

# CHECK: revive.wmv.i128	v8, v10
# CHECK: encoding: [0x5b,0x04,0x05,0x98]
revive.wmv.i128 v8, v10
# CHECK: revive.wbswap.i128	v8, v10
# CHECK: encoding: [0x5b,0x04,0x05,0x9c]
revive.wbswap.i128 v8, v10
# CHECK: revive.wtrunc.i128	a0, v10
# CHECK: encoding: [0x5b,0x05,0x05,0x9a]
revive.wtrunc.i128 a0, v10
# CHECK: revive.wcpop.i128	a0, v10
# CHECK: encoding: [0x5b,0x05,0x05,0x9e]
revive.wcpop.i128 a0, v10
# CHECK: revive.wclz.i128	a0, v10
# CHECK: encoding: [0x5b,0x05,0x05,0xa0]
revive.wclz.i128 a0, v10
# CHECK: revive.wctz.i128	a0, v10
# CHECK: encoding: [0x5b,0x05,0x05,0xa2]
revive.wctz.i128 a0, v10
# CHECK: revive.wzext.i128	v8, a0
# CHECK: encoding: [0x5b,0x04,0x05,0xa4]
revive.wzext.i128 v8, a0
# CHECK: revive.wsext.i128	v8, a0
# CHECK: encoding: [0x5b,0x04,0x05,0xa6]
revive.wsext.i128 v8, a0

# The offsets are the same plain even integers, and they occupy the same eleven
# bits of the field, with the width flag below them: 16 encodes as 0x011.
# CHECK: revive.wld.i128	v8, 0(a0)
# CHECK: encoding: [0x5b,0x44,0x15,0x00]
revive.wld.i128 v8, 0(a0)
# CHECK: revive.wld.i128	v8, 16(a0)
# CHECK: encoding: [0x5b,0x44,0x15,0x01]
revive.wld.i128 v8, 16(a0)
# CHECK: revive.wld.i128	v10, -2048(a1)
# CHECK: encoding: [0x5b,0xc5,0x15,0x80]
revive.wld.i128 v10, -2048(a1)
# CHECK: revive.wld.i128	v12, 2046(sp)
# CHECK: encoding: [0x5b,0x46,0xf1,0x7f]
revive.wld.i128 v12, 2046(sp)

# CHECK: revive.wst.i128	v8, 0(a0)
# CHECK: encoding: [0xdb,0x50,0x85,0x00]
revive.wst.i128 v8, 0(a0)
# CHECK: revive.wst.i128	v8, 16(a0)
# CHECK: encoding: [0xdb,0x58,0x85,0x00]
revive.wst.i128 v8, 16(a0)
# CHECK: revive.wst.i128	v10, -2048(a1)
# CHECK: encoding: [0xdb,0xd0,0xa5,0x80]
revive.wst.i128 v10, -2048(a1)
# CHECK: revive.wst.i128	v12, 2046(sp)
# CHECK: encoding: [0xdb,0x5f,0xc1,0x7e]
revive.wst.i128 v12, 2046(sp)
