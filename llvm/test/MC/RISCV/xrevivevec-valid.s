# RUN: llvm-mc -triple=riscv64 -mattr=+xrevivevec -show-encoding < %s \
# RUN:     | FileCheck %s
# RUN: llvm-mc -triple=riscv64 -mattr=+xrevivevec -filetype=obj < %s \
# RUN:     | llvm-objdump -d -M no-aliases --no-print-imm-hex --mattr=+xrevivevec - \
# RUN:     | FileCheck %s --check-prefix=OBJ
# RUN: not llvm-mc -triple=riscv64 < %s 2>&1 \
# RUN:     | FileCheck %s --check-prefix=NO-EXT

# Every instruction, once: the width comes from vtype, so one encoding covers all
# three. Assembling and then disassembling checks encoder and decoder agree.

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
# CHECK: revive.wzext	v8, a0 # encoding: [0x5b,0x74,0x05,0x00]
# OBJ: revive.wzext	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wzext v8, a0
# CHECK: revive.wsext	v8, a0 # encoding: [0x5b,0x74,0x05,0x02]
# OBJ: revive.wsext	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wsext v8, a0
# CHECK: revive.wbswap	v8, v10 # encoding: [0x5b,0x64,0x05,0x04]
# OBJ: revive.wbswap	v8, v10
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wbswap v8, v10
# CHECK: revive.waddmod	v8, v10, v12, v14 # encoding: [0x5b,0x34,0xc5,0x70]
# OBJ: revive.waddmod	v8, v10, v12, v14
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.waddmod v8, v10, v12, v14
# CHECK: revive.wmulmod	v8, v10, v12, v14 # encoding: [0x5b,0x34,0xc5,0x72]
# OBJ: revive.wmulmod	v8, v10, v12, v14
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wmulmod v8, v10, v12, v14
# CHECK: revive.wld	v8, 16(a0) # encoding: [0x5b,0x44,0x05,0x01]
# OBJ: revive.wld	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wld v8, 16(a0)
# CHECK: revive.wst	v8, 16(a0) # encoding: [0x5b,0x58,0x85,0x00]
# OBJ: revive.wst	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.wst v8, 16(a0)
