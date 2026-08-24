# RUN: llvm-mc -triple=riscv64 -mattr=+xrevivevec -show-encoding < %s \
# RUN:     | FileCheck %s
# RUN: llvm-mc -triple=riscv64 -mattr=+xrevivevec -filetype=obj < %s \
# RUN:     | llvm-objdump -d -M no-aliases --no-print-imm-hex --mattr=+xrevivevec - \
# RUN:     | FileCheck %s --check-prefix=OBJ
# RUN: not llvm-mc -triple=riscv64 < %s 2>&1 \
# RUN:     | FileCheck %s --check-prefix=NO-EXT

# Every instruction at all four widths. The width is a field of the instruction, so these are
# distinct encodings within one opcode space rather than separate instruction sets. Assembling
# and then disassembling the object checks that the encoder and the decoder agree.

# CHECK: revive.add128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x00]
# OBJ: revive.add128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.add128 v8, v10, v12
# CHECK: revive.sub128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x02]
# OBJ: revive.sub128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sub128 v8, v10, v12
# CHECK: revive.mul128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x04]
# OBJ: revive.mul128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.mul128 v8, v10, v12
# CHECK: revive.and128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x06]
# OBJ: revive.and128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.and128 v8, v10, v12
# CHECK: revive.or128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x08]
# OBJ: revive.or128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.or128 v8, v10, v12
# CHECK: revive.xor128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x0a]
# OBJ: revive.xor128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.xor128 v8, v10, v12
# CHECK: revive.divu128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x0c]
# OBJ: revive.divu128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.divu128 v8, v10, v12
# CHECK: revive.div128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x0e]
# OBJ: revive.div128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.div128 v8, v10, v12
# CHECK: revive.remu128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x10]
# OBJ: revive.remu128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.remu128 v8, v10, v12
# CHECK: revive.rem128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x12]
# OBJ: revive.rem128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.rem128 v8, v10, v12
# CHECK: revive.exp128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x14]
# OBJ: revive.exp128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.exp128 v8, v10, v12
# CHECK: revive.signextend128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x16]
# OBJ: revive.signextend128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.signextend128 v8, v10, v12
# CHECK: revive.minu128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x18]
# OBJ: revive.minu128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.minu128 v8, v10, v12
# CHECK: revive.min128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x1a]
# OBJ: revive.min128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.min128 v8, v10, v12
# CHECK: revive.maxu128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x1c]
# OBJ: revive.maxu128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.maxu128 v8, v10, v12
# CHECK: revive.max128	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x1e]
# OBJ: revive.max128	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.max128 v8, v10, v12
# CHECK: revive.sll128	v8, v10, a0 # encoding: [0x5b,0x04,0xa5,0x20]
# OBJ: revive.sll128	v8, v10, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sll128 v8, v10, a0
# CHECK: revive.srl128	v8, v10, a0 # encoding: [0x5b,0x04,0xa5,0x22]
# OBJ: revive.srl128	v8, v10, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.srl128 v8, v10, a0
# CHECK: revive.sra128	v8, v10, a0 # encoding: [0x5b,0x04,0xa5,0x24]
# OBJ: revive.sra128	v8, v10, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sra128 v8, v10, a0
# CHECK: revive.seq128	a0, v10, v12 # encoding: [0x5b,0x05,0xc5,0x26]
# OBJ: revive.seq128	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.seq128 a0, v10, v12
# CHECK: revive.sne128	a0, v10, v12 # encoding: [0x5b,0x05,0xc5,0x28]
# OBJ: revive.sne128	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sne128 a0, v10, v12
# CHECK: revive.sltu128	a0, v10, v12 # encoding: [0x5b,0x05,0xc5,0x2a]
# OBJ: revive.sltu128	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sltu128 a0, v10, v12
# CHECK: revive.slt128	a0, v10, v12 # encoding: [0x5b,0x05,0xc5,0x2c]
# OBJ: revive.slt128	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.slt128 a0, v10, v12
# CHECK: revive.trunc128	a0, v10 # encoding: [0x5b,0x05,0x05,0x2e]
# OBJ: revive.trunc128	a0, v10
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.trunc128 a0, v10
# CHECK: revive.zext128	v8, a0 # encoding: [0x5b,0x04,0x05,0x30]
# OBJ: revive.zext128	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.zext128 v8, a0
# CHECK: revive.sext128	v8, a0 # encoding: [0x5b,0x04,0x05,0x32]
# OBJ: revive.sext128	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sext128 v8, a0
# CHECK: revive.bswap128	v8, v10 # encoding: [0x5b,0x04,0x05,0x34]
# OBJ: revive.bswap128	v8, v10
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.bswap128 v8, v10
# CHECK: revive.mv128	v8, v10 # encoding: [0x5b,0x04,0x05,0x36]
# OBJ: revive.mv128	v8, v10
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.mv128 v8, v10
# CHECK: revive.ld128	v8, 16(a0) # encoding: [0x5b,0x24,0x05,0x01]
# OBJ: revive.ld128	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.ld128 v8, 16(a0)
# CHECK: revive.st128	v8, 16(a0) # encoding: [0x5b,0x68,0x85,0x00]
# OBJ: revive.st128	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.st128 v8, 16(a0)
# CHECK: revive.add256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x40]
# OBJ: revive.add256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.add256 v8, v10, v12
# CHECK: revive.sub256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x42]
# OBJ: revive.sub256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sub256 v8, v10, v12
# CHECK: revive.mul256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x44]
# OBJ: revive.mul256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.mul256 v8, v10, v12
# CHECK: revive.and256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x46]
# OBJ: revive.and256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.and256 v8, v10, v12
# CHECK: revive.or256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x48]
# OBJ: revive.or256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.or256 v8, v10, v12
# CHECK: revive.xor256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x4a]
# OBJ: revive.xor256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.xor256 v8, v10, v12
# CHECK: revive.divu256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x4c]
# OBJ: revive.divu256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.divu256 v8, v10, v12
# CHECK: revive.div256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x4e]
# OBJ: revive.div256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.div256 v8, v10, v12
# CHECK: revive.remu256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x50]
# OBJ: revive.remu256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.remu256 v8, v10, v12
# CHECK: revive.rem256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x52]
# OBJ: revive.rem256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.rem256 v8, v10, v12
# CHECK: revive.exp256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x54]
# OBJ: revive.exp256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.exp256 v8, v10, v12
# CHECK: revive.signextend256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x56]
# OBJ: revive.signextend256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.signextend256 v8, v10, v12
# CHECK: revive.minu256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x58]
# OBJ: revive.minu256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.minu256 v8, v10, v12
# CHECK: revive.min256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x5a]
# OBJ: revive.min256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.min256 v8, v10, v12
# CHECK: revive.maxu256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x5c]
# OBJ: revive.maxu256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.maxu256 v8, v10, v12
# CHECK: revive.max256	v8, v10, v12 # encoding: [0x5b,0x04,0xc5,0x5e]
# OBJ: revive.max256	v8, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.max256 v8, v10, v12
# CHECK: revive.sll256	v8, v10, a0 # encoding: [0x5b,0x04,0xa5,0x60]
# OBJ: revive.sll256	v8, v10, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sll256 v8, v10, a0
# CHECK: revive.srl256	v8, v10, a0 # encoding: [0x5b,0x04,0xa5,0x62]
# OBJ: revive.srl256	v8, v10, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.srl256 v8, v10, a0
# CHECK: revive.sra256	v8, v10, a0 # encoding: [0x5b,0x04,0xa5,0x64]
# OBJ: revive.sra256	v8, v10, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sra256 v8, v10, a0
# CHECK: revive.seq256	a0, v10, v12 # encoding: [0x5b,0x05,0xc5,0x66]
# OBJ: revive.seq256	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.seq256 a0, v10, v12
# CHECK: revive.sne256	a0, v10, v12 # encoding: [0x5b,0x05,0xc5,0x68]
# OBJ: revive.sne256	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sne256 a0, v10, v12
# CHECK: revive.sltu256	a0, v10, v12 # encoding: [0x5b,0x05,0xc5,0x6a]
# OBJ: revive.sltu256	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sltu256 a0, v10, v12
# CHECK: revive.slt256	a0, v10, v12 # encoding: [0x5b,0x05,0xc5,0x6c]
# OBJ: revive.slt256	a0, v10, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.slt256 a0, v10, v12
# CHECK: revive.trunc256	a0, v10 # encoding: [0x5b,0x05,0x05,0x6e]
# OBJ: revive.trunc256	a0, v10
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.trunc256 a0, v10
# CHECK: revive.zext256	v8, a0 # encoding: [0x5b,0x04,0x05,0x70]
# OBJ: revive.zext256	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.zext256 v8, a0
# CHECK: revive.sext256	v8, a0 # encoding: [0x5b,0x04,0x05,0x72]
# OBJ: revive.sext256	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sext256 v8, a0
# CHECK: revive.bswap256	v8, v10 # encoding: [0x5b,0x04,0x05,0x74]
# OBJ: revive.bswap256	v8, v10
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.bswap256 v8, v10
# CHECK: revive.mv256	v8, v10 # encoding: [0x5b,0x04,0x05,0x76]
# OBJ: revive.mv256	v8, v10
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.mv256 v8, v10
# CHECK: revive.ld256	v8, 16(a0) # encoding: [0x5b,0x34,0x05,0x01]
# OBJ: revive.ld256	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.ld256 v8, 16(a0)
# CHECK: revive.st256	v8, 16(a0) # encoding: [0x5b,0x68,0x85,0x40]
# OBJ: revive.st256	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.st256 v8, 16(a0)
# CHECK: revive.add512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x81]
# OBJ: revive.add512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.add512 v8, v12, v16
# CHECK: revive.sub512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x83]
# OBJ: revive.sub512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sub512 v8, v12, v16
# CHECK: revive.mul512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x85]
# OBJ: revive.mul512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.mul512 v8, v12, v16
# CHECK: revive.and512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x87]
# OBJ: revive.and512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.and512 v8, v12, v16
# CHECK: revive.or512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x89]
# OBJ: revive.or512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.or512 v8, v12, v16
# CHECK: revive.xor512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x8b]
# OBJ: revive.xor512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.xor512 v8, v12, v16
# CHECK: revive.divu512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x8d]
# OBJ: revive.divu512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.divu512 v8, v12, v16
# CHECK: revive.div512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x8f]
# OBJ: revive.div512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.div512 v8, v12, v16
# CHECK: revive.remu512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x91]
# OBJ: revive.remu512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.remu512 v8, v12, v16
# CHECK: revive.rem512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x93]
# OBJ: revive.rem512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.rem512 v8, v12, v16
# CHECK: revive.exp512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x95]
# OBJ: revive.exp512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.exp512 v8, v12, v16
# CHECK: revive.signextend512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x97]
# OBJ: revive.signextend512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.signextend512 v8, v12, v16
# CHECK: revive.minu512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x99]
# OBJ: revive.minu512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.minu512 v8, v12, v16
# CHECK: revive.min512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x9b]
# OBJ: revive.min512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.min512 v8, v12, v16
# CHECK: revive.maxu512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x9d]
# OBJ: revive.maxu512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.maxu512 v8, v12, v16
# CHECK: revive.max512	v8, v12, v16 # encoding: [0x5b,0x04,0x06,0x9f]
# OBJ: revive.max512	v8, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.max512 v8, v12, v16
# CHECK: revive.sll512	v8, v12, a0 # encoding: [0x5b,0x04,0xa6,0xa0]
# OBJ: revive.sll512	v8, v12, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sll512 v8, v12, a0
# CHECK: revive.srl512	v8, v12, a0 # encoding: [0x5b,0x04,0xa6,0xa2]
# OBJ: revive.srl512	v8, v12, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.srl512 v8, v12, a0
# CHECK: revive.sra512	v8, v12, a0 # encoding: [0x5b,0x04,0xa6,0xa4]
# OBJ: revive.sra512	v8, v12, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sra512 v8, v12, a0
# CHECK: revive.seq512	a0, v12, v16 # encoding: [0x5b,0x05,0x06,0xa7]
# OBJ: revive.seq512	a0, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.seq512 a0, v12, v16
# CHECK: revive.sne512	a0, v12, v16 # encoding: [0x5b,0x05,0x06,0xa9]
# OBJ: revive.sne512	a0, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sne512 a0, v12, v16
# CHECK: revive.sltu512	a0, v12, v16 # encoding: [0x5b,0x05,0x06,0xab]
# OBJ: revive.sltu512	a0, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sltu512 a0, v12, v16
# CHECK: revive.slt512	a0, v12, v16 # encoding: [0x5b,0x05,0x06,0xad]
# OBJ: revive.slt512	a0, v12, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.slt512 a0, v12, v16
# CHECK: revive.trunc512	a0, v12 # encoding: [0x5b,0x05,0x06,0xae]
# OBJ: revive.trunc512	a0, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.trunc512 a0, v12
# CHECK: revive.zext512	v8, a0 # encoding: [0x5b,0x04,0x05,0xb0]
# OBJ: revive.zext512	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.zext512 v8, a0
# CHECK: revive.sext512	v8, a0 # encoding: [0x5b,0x04,0x05,0xb2]
# OBJ: revive.sext512	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sext512 v8, a0
# CHECK: revive.bswap512	v8, v12 # encoding: [0x5b,0x04,0x06,0xb4]
# OBJ: revive.bswap512	v8, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.bswap512 v8, v12
# CHECK: revive.mv512	v8, v12 # encoding: [0x5b,0x04,0x06,0xb6]
# OBJ: revive.mv512	v8, v12
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.mv512 v8, v12
# CHECK: revive.ld512	v8, 16(a0) # encoding: [0x5b,0x44,0x05,0x01]
# OBJ: revive.ld512	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.ld512 v8, 16(a0)
# CHECK: revive.st512	v8, 16(a0) # encoding: [0x5b,0x68,0x85,0x80]
# OBJ: revive.st512	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.st512 v8, 16(a0)
# CHECK: revive.add1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xc0]
# OBJ: revive.add1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.add1024 v8, v16, v0
# CHECK: revive.sub1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xc2]
# OBJ: revive.sub1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sub1024 v8, v16, v0
# CHECK: revive.mul1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xc4]
# OBJ: revive.mul1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.mul1024 v8, v16, v0
# CHECK: revive.and1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xc6]
# OBJ: revive.and1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.and1024 v8, v16, v0
# CHECK: revive.or1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xc8]
# OBJ: revive.or1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.or1024 v8, v16, v0
# CHECK: revive.xor1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xca]
# OBJ: revive.xor1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.xor1024 v8, v16, v0
# CHECK: revive.divu1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xcc]
# OBJ: revive.divu1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.divu1024 v8, v16, v0
# CHECK: revive.div1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xce]
# OBJ: revive.div1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.div1024 v8, v16, v0
# CHECK: revive.remu1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xd0]
# OBJ: revive.remu1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.remu1024 v8, v16, v0
# CHECK: revive.rem1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xd2]
# OBJ: revive.rem1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.rem1024 v8, v16, v0
# CHECK: revive.exp1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xd4]
# OBJ: revive.exp1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.exp1024 v8, v16, v0
# CHECK: revive.signextend1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xd6]
# OBJ: revive.signextend1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.signextend1024 v8, v16, v0
# CHECK: revive.minu1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xd8]
# OBJ: revive.minu1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.minu1024 v8, v16, v0
# CHECK: revive.min1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xda]
# OBJ: revive.min1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.min1024 v8, v16, v0
# CHECK: revive.maxu1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xdc]
# OBJ: revive.maxu1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.maxu1024 v8, v16, v0
# CHECK: revive.max1024	v8, v16, v0 # encoding: [0x5b,0x04,0x08,0xde]
# OBJ: revive.max1024	v8, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.max1024 v8, v16, v0
# CHECK: revive.sll1024	v8, v16, a0 # encoding: [0x5b,0x04,0xa8,0xe0]
# OBJ: revive.sll1024	v8, v16, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sll1024 v8, v16, a0
# CHECK: revive.srl1024	v8, v16, a0 # encoding: [0x5b,0x04,0xa8,0xe2]
# OBJ: revive.srl1024	v8, v16, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.srl1024 v8, v16, a0
# CHECK: revive.sra1024	v8, v16, a0 # encoding: [0x5b,0x04,0xa8,0xe4]
# OBJ: revive.sra1024	v8, v16, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sra1024 v8, v16, a0
# CHECK: revive.seq1024	a0, v16, v0 # encoding: [0x5b,0x05,0x08,0xe6]
# OBJ: revive.seq1024	a0, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.seq1024 a0, v16, v0
# CHECK: revive.sne1024	a0, v16, v0 # encoding: [0x5b,0x05,0x08,0xe8]
# OBJ: revive.sne1024	a0, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sne1024 a0, v16, v0
# CHECK: revive.sltu1024	a0, v16, v0 # encoding: [0x5b,0x05,0x08,0xea]
# OBJ: revive.sltu1024	a0, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sltu1024 a0, v16, v0
# CHECK: revive.slt1024	a0, v16, v0 # encoding: [0x5b,0x05,0x08,0xec]
# OBJ: revive.slt1024	a0, v16, v0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.slt1024 a0, v16, v0
# CHECK: revive.trunc1024	a0, v16 # encoding: [0x5b,0x05,0x08,0xee]
# OBJ: revive.trunc1024	a0, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.trunc1024 a0, v16
# CHECK: revive.zext1024	v8, a0 # encoding: [0x5b,0x04,0x05,0xf0]
# OBJ: revive.zext1024	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.zext1024 v8, a0
# CHECK: revive.sext1024	v8, a0 # encoding: [0x5b,0x04,0x05,0xf2]
# OBJ: revive.sext1024	v8, a0
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.sext1024 v8, a0
# CHECK: revive.bswap1024	v8, v16 # encoding: [0x5b,0x04,0x08,0xf4]
# OBJ: revive.bswap1024	v8, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.bswap1024 v8, v16
# CHECK: revive.mv1024	v8, v16 # encoding: [0x5b,0x04,0x08,0xf6]
# OBJ: revive.mv1024	v8, v16
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.mv1024 v8, v16
# CHECK: revive.ld1024	v8, 16(a0) # encoding: [0x5b,0x54,0x05,0x01]
# OBJ: revive.ld1024	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.ld1024 v8, 16(a0)
# CHECK: revive.st1024	v8, 16(a0) # encoding: [0x5b,0x68,0x85,0xc0]
# OBJ: revive.st1024	v8, 16(a0)
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.st1024 v8, 16(a0)
# CHECK: revive.addmod	v8, v10, v12, v14 # encoding: [0x5b,0x14,0xc5,0x70]
# OBJ: revive.addmod	v8, v10, v12, v14
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.addmod v8, v10, v12, v14
# CHECK: revive.mulmod	v8, v10, v12, v14 # encoding: [0x5b,0x14,0xc5,0x72]
# OBJ: revive.mulmod	v8, v10, v12, v14
# NO-EXT: :[[@LINE+1]]:{{[0-9]+}}: error: instruction requires the following: 'XReviveVec'
revive.mulmod v8, v10, v12, v14
