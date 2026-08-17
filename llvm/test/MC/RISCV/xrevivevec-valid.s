# RUN: llvm-mc -triple=riscv64 -mattr=+xrevivevec -show-encoding < %s \
# RUN:     | FileCheck %s
# RUN: llvm-mc -triple=riscv64 -mattr=+xrevivevec -filetype=obj < %s \
# RUN:     | llvm-objdump -d -M no-aliases --no-print-imm-hex --mattr=+xrevivevec - \
# RUN:     | FileCheck %s --check-prefix=OBJ
# RUN: not llvm-mc -triple=riscv64 < %s 2>&1 \
# RUN:     | FileCheck %s --check-prefix=NO-EXT

# Every instruction at all three widths. Each width has its own custom opcode
# space -- w in custom-2, d in custom-3, q in custom-1 -- because the I- and
# S-type memory forms have no spare field for one. Assembling and then
# disassembling the object checks that the encoder and decoder agree.

# CHECK: revive.wadd	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x00]
# OBJ: revive.wadd	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wadd v8, v10, v12
# CHECK: revive.wsub	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x02]
# OBJ: revive.wsub	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wsub v8, v10, v12
# CHECK: revive.wmul	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x04]
# OBJ: revive.wmul	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wmul v8, v10, v12
# CHECK: revive.wand	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x06]
# OBJ: revive.wand	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wand v8, v10, v12
# CHECK: revive.wor	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x08]
# OBJ: revive.wor	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wor v8, v10, v12
# CHECK: revive.wxor	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x0a]
# OBJ: revive.wxor	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wxor v8, v10, v12
# CHECK: revive.wdivu	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x0c]
# OBJ: revive.wdivu	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wdivu v8, v10, v12
# CHECK: revive.wdiv	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x0e]
# OBJ: revive.wdiv	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wdiv v8, v10, v12
# CHECK: revive.wremu	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x10]
# OBJ: revive.wremu	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wremu v8, v10, v12
# CHECK: revive.wrem	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x12]
# OBJ: revive.wrem	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wrem v8, v10, v12
# CHECK: revive.wexp	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x14]
# OBJ: revive.wexp	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wexp v8, v10, v12
# CHECK: revive.wsignextend	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x16]
# OBJ: revive.wsignextend	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wsignextend v8, v10, v12
# CHECK: revive.wminu	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x18]
# OBJ: revive.wminu	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wminu v8, v10, v12
# CHECK: revive.wmin	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x1a]
# OBJ: revive.wmin	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wmin v8, v10, v12
# CHECK: revive.wmaxu	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x1c]
# OBJ: revive.wmaxu	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wmaxu v8, v10, v12
# CHECK: revive.wmax	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x1e]
# OBJ: revive.wmax	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wmax v8, v10, v12
# CHECK: revive.wsll	v8, v10, a0 # encoding: [0x5b,0x24,0xa5,0x00]
# OBJ: revive.wsll	v8, v10, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wsll v8, v10, a0
# CHECK: revive.wsrl	v8, v10, a0 # encoding: [0x5b,0x24,0xa5,0x02]
# OBJ: revive.wsrl	v8, v10, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wsrl v8, v10, a0
# CHECK: revive.wsra	v8, v10, a0 # encoding: [0x5b,0x24,0xa5,0x04]
# OBJ: revive.wsra	v8, v10, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wsra v8, v10, a0
# CHECK: revive.wseq	a0, v10, v12 # encoding: [0x5b,0x15,0xc5,0x00]
# OBJ: revive.wseq	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wseq a0, v10, v12
# CHECK: revive.wsne	a0, v10, v12 # encoding: [0x5b,0x15,0xc5,0x02]
# OBJ: revive.wsne	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wsne a0, v10, v12
# CHECK: revive.wsltu	a0, v10, v12 # encoding: [0x5b,0x15,0xc5,0x04]
# OBJ: revive.wsltu	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wsltu a0, v10, v12
# CHECK: revive.wslt	a0, v10, v12 # encoding: [0x5b,0x15,0xc5,0x06]
# OBJ: revive.wslt	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wslt a0, v10, v12
# CHECK: revive.wtrunc	a0, v10 # encoding: [0x5b,0x65,0x05,0x02]
# OBJ: revive.wtrunc	a0, v10
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wtrunc a0, v10
# CHECK: revive.wzext	v8, a1 # encoding: [0x5b,0xf4,0x05,0x00]
# OBJ: revive.wzext	v8, a1
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wzext v8, a1
# CHECK: revive.wsext	v8, a1 # encoding: [0x5b,0xf4,0x05,0x02]
# OBJ: revive.wsext	v8, a1
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wsext v8, a1
# CHECK: revive.wbswap	v8, v10 # encoding: [0x5b,0x64,0x05,0x04]
# OBJ: revive.wbswap	v8, v10
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wbswap v8, v10
# CHECK: revive.waddmod	v8, v10, v12, v8 # encoding: [0x5b,0x34,0xc5,0x40]
# OBJ: revive.waddmod	v8, v10, v12, v8
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.waddmod v8, v10, v12, v8
# CHECK: revive.wmulmod	v8, v10, v12, v8 # encoding: [0x5b,0x34,0xc5,0x42]
# OBJ: revive.wmulmod	v8, v10, v12, v8
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wmulmod v8, v10, v12, v8
# CHECK: revive.wld	v8, 8(a0) # encoding: [0x5b,0x44,0x85,0x00]
# OBJ: revive.wld	v8, 8(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wld v8, 8(a0)
# CHECK: revive.wst	v8, -8(a0) # encoding: [0x5b,0x5c,0x85,0xfe]
# OBJ: revive.wst	v8, -8(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wst v8, -8(a0)
# CHECK: revive.dadd	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x01]
# OBJ: revive.dadd	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dadd v8, v12, v16
# CHECK: revive.dsub	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x03]
# OBJ: revive.dsub	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dsub v8, v12, v16
# CHECK: revive.dmul	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x05]
# OBJ: revive.dmul	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dmul v8, v12, v16
# CHECK: revive.dand	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x07]
# OBJ: revive.dand	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dand v8, v12, v16
# CHECK: revive.dor	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x09]
# OBJ: revive.dor	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dor v8, v12, v16
# CHECK: revive.dxor	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x0b]
# OBJ: revive.dxor	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dxor v8, v12, v16
# CHECK: revive.ddivu	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x0d]
# OBJ: revive.ddivu	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.ddivu v8, v12, v16
# CHECK: revive.ddiv	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x0f]
# OBJ: revive.ddiv	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.ddiv v8, v12, v16
# CHECK: revive.dremu	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x11]
# OBJ: revive.dremu	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dremu v8, v12, v16
# CHECK: revive.drem	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x13]
# OBJ: revive.drem	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.drem v8, v12, v16
# CHECK: revive.dexp	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x15]
# OBJ: revive.dexp	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dexp v8, v12, v16
# CHECK: revive.dsignextend	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x17]
# OBJ: revive.dsignextend	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dsignextend v8, v12, v16
# CHECK: revive.dminu	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x19]
# OBJ: revive.dminu	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dminu v8, v12, v16
# CHECK: revive.dmin	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x1b]
# OBJ: revive.dmin	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dmin v8, v12, v16
# CHECK: revive.dmaxu	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x1d]
# OBJ: revive.dmaxu	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dmaxu v8, v12, v16
# CHECK: revive.dmax	v8, v12, v16 # encoding: [0x7b,0x04,0x06,0x1f]
# OBJ: revive.dmax	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dmax v8, v12, v16
# CHECK: revive.dsll	v8, v12, a0 # encoding: [0x7b,0x24,0xa6,0x00]
# OBJ: revive.dsll	v8, v12, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dsll v8, v12, a0
# CHECK: revive.dsrl	v8, v12, a0 # encoding: [0x7b,0x24,0xa6,0x02]
# OBJ: revive.dsrl	v8, v12, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dsrl v8, v12, a0
# CHECK: revive.dsra	v8, v12, a0 # encoding: [0x7b,0x24,0xa6,0x04]
# OBJ: revive.dsra	v8, v12, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dsra v8, v12, a0
# CHECK: revive.dseq	a0, v12, v16 # encoding: [0x7b,0x15,0x06,0x01]
# OBJ: revive.dseq	a0, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dseq a0, v12, v16
# CHECK: revive.dsne	a0, v12, v16 # encoding: [0x7b,0x15,0x06,0x03]
# OBJ: revive.dsne	a0, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dsne a0, v12, v16
# CHECK: revive.dsltu	a0, v12, v16 # encoding: [0x7b,0x15,0x06,0x05]
# OBJ: revive.dsltu	a0, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dsltu a0, v12, v16
# CHECK: revive.dslt	a0, v12, v16 # encoding: [0x7b,0x15,0x06,0x07]
# OBJ: revive.dslt	a0, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dslt a0, v12, v16
# CHECK: revive.dtrunc	a0, v12 # encoding: [0x7b,0x65,0x06,0x02]
# OBJ: revive.dtrunc	a0, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dtrunc a0, v12
# CHECK: revive.dzext	v8, a1 # encoding: [0x7b,0xf4,0x05,0x00]
# OBJ: revive.dzext	v8, a1
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dzext v8, a1
# CHECK: revive.dsext	v8, a1 # encoding: [0x7b,0xf4,0x05,0x02]
# OBJ: revive.dsext	v8, a1
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dsext v8, a1
# CHECK: revive.dbswap	v8, v12 # encoding: [0x7b,0x64,0x06,0x04]
# OBJ: revive.dbswap	v8, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dbswap v8, v12
# CHECK: revive.daddmod	v8, v12, v16, v8 # encoding: [0x7b,0x34,0x06,0x41]
# OBJ: revive.daddmod	v8, v12, v16, v8
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.daddmod v8, v12, v16, v8
# CHECK: revive.dmulmod	v8, v12, v16, v8 # encoding: [0x7b,0x34,0x06,0x43]
# OBJ: revive.dmulmod	v8, v12, v16, v8
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dmulmod v8, v12, v16, v8
# CHECK: revive.dld	v8, 8(a0) # encoding: [0x7b,0x44,0x85,0x00]
# OBJ: revive.dld	v8, 8(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dld v8, 8(a0)
# CHECK: revive.dst	v8, -8(a0) # encoding: [0x7b,0x5c,0x85,0xfe]
# OBJ: revive.dst	v8, -8(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.dst v8, -8(a0)
# CHECK: revive.qadd	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x01]
# OBJ: revive.qadd	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qadd v8, v16, v24
# CHECK: revive.qsub	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x03]
# OBJ: revive.qsub	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qsub v8, v16, v24
# CHECK: revive.qmul	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x05]
# OBJ: revive.qmul	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qmul v8, v16, v24
# CHECK: revive.qand	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x07]
# OBJ: revive.qand	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qand v8, v16, v24
# CHECK: revive.qor	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x09]
# OBJ: revive.qor	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qor v8, v16, v24
# CHECK: revive.qxor	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x0b]
# OBJ: revive.qxor	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qxor v8, v16, v24
# CHECK: revive.qdivu	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x0d]
# OBJ: revive.qdivu	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qdivu v8, v16, v24
# CHECK: revive.qdiv	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x0f]
# OBJ: revive.qdiv	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qdiv v8, v16, v24
# CHECK: revive.qremu	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x11]
# OBJ: revive.qremu	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qremu v8, v16, v24
# CHECK: revive.qrem	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x13]
# OBJ: revive.qrem	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qrem v8, v16, v24
# CHECK: revive.qexp	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x15]
# OBJ: revive.qexp	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qexp v8, v16, v24
# CHECK: revive.qsignextend	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x17]
# OBJ: revive.qsignextend	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qsignextend v8, v16, v24
# CHECK: revive.qminu	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x19]
# OBJ: revive.qminu	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qminu v8, v16, v24
# CHECK: revive.qmin	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x1b]
# OBJ: revive.qmin	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qmin v8, v16, v24
# CHECK: revive.qmaxu	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x1d]
# OBJ: revive.qmaxu	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qmaxu v8, v16, v24
# CHECK: revive.qmax	v8, v16, v24 # encoding: [0x2b,0x04,0x88,0x1f]
# OBJ: revive.qmax	v8, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qmax v8, v16, v24
# CHECK: revive.qsll	v8, v16, a0 # encoding: [0x2b,0x24,0xa8,0x00]
# OBJ: revive.qsll	v8, v16, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qsll v8, v16, a0
# CHECK: revive.qsrl	v8, v16, a0 # encoding: [0x2b,0x24,0xa8,0x02]
# OBJ: revive.qsrl	v8, v16, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qsrl v8, v16, a0
# CHECK: revive.qsra	v8, v16, a0 # encoding: [0x2b,0x24,0xa8,0x04]
# OBJ: revive.qsra	v8, v16, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qsra v8, v16, a0
# CHECK: revive.qseq	a0, v16, v24 # encoding: [0x2b,0x15,0x88,0x01]
# OBJ: revive.qseq	a0, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qseq a0, v16, v24
# CHECK: revive.qsne	a0, v16, v24 # encoding: [0x2b,0x15,0x88,0x03]
# OBJ: revive.qsne	a0, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qsne a0, v16, v24
# CHECK: revive.qsltu	a0, v16, v24 # encoding: [0x2b,0x15,0x88,0x05]
# OBJ: revive.qsltu	a0, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qsltu a0, v16, v24
# CHECK: revive.qslt	a0, v16, v24 # encoding: [0x2b,0x15,0x88,0x07]
# OBJ: revive.qslt	a0, v16, v24
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qslt a0, v16, v24
# CHECK: revive.qtrunc	a0, v16 # encoding: [0x2b,0x65,0x08,0x02]
# OBJ: revive.qtrunc	a0, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qtrunc a0, v16
# CHECK: revive.qzext	v8, a1 # encoding: [0x2b,0xf4,0x05,0x00]
# OBJ: revive.qzext	v8, a1
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qzext v8, a1
# CHECK: revive.qsext	v8, a1 # encoding: [0x2b,0xf4,0x05,0x02]
# OBJ: revive.qsext	v8, a1
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qsext v8, a1
# CHECK: revive.qbswap	v8, v16 # encoding: [0x2b,0x64,0x08,0x04]
# OBJ: revive.qbswap	v8, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qbswap v8, v16
# CHECK: revive.qaddmod	v8, v16, v24, v8 # encoding: [0x2b,0x34,0x88,0x41]
# OBJ: revive.qaddmod	v8, v16, v24, v8
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qaddmod v8, v16, v24, v8
# CHECK: revive.qmulmod	v8, v16, v24, v8 # encoding: [0x2b,0x34,0x88,0x43]
# OBJ: revive.qmulmod	v8, v16, v24, v8
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qmulmod v8, v16, v24, v8
# CHECK: revive.qld	v8, 8(a0) # encoding: [0x2b,0x44,0x85,0x00]
# OBJ: revive.qld	v8, 8(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qld v8, 8(a0)
# CHECK: revive.qst	v8, -8(a0) # encoding: [0x2b,0x5c,0x85,0xfe]
# OBJ: revive.qst	v8, -8(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.qst v8, -8(a0)
