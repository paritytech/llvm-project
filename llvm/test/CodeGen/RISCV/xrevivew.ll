; RUN: llc -mtriple=riscv64 -mattr=+m,+xrevivew -verify-machineinstrs < %s \
; RUN:   | FileCheck %s

; The XReviveW prototype holds i256 in the dedicated W0-W15 register file. Unlike
; the vector variant it emits NO vsetivli: the width is fixed at 256 bits. Every
; wide op is one instruction on w-registers, and i256 arguments/results use the W
; calling convention (w0, w1, ...).

; No vtype configuration is ever emitted for this variant.
; CHECK-NOT: vsetivli

; CHECK-LABEL: add_i256:
; CHECK:       revive.wadd w0, w0, w1
; CHECK-NEXT:  ret
define i256 @add_i256(i256 %a, i256 %b) {
  %r = add i256 %a, %b
  ret i256 %r
}

; CHECK-LABEL: sub_i256:
; CHECK:       revive.wsub w0, w0, w1
define i256 @sub_i256(i256 %a, i256 %b) {
  %r = sub i256 %a, %b
  ret i256 %r
}

; CHECK-LABEL: mul_i256:
; CHECK:       revive.wmul w0, w0, w1
define i256 @mul_i256(i256 %a, i256 %b) {
  %r = mul i256 %a, %b
  ret i256 %r
}

; CHECK-LABEL: and_i256:
; CHECK:       revive.wand w0, w0, w1
define i256 @and_i256(i256 %a, i256 %b) {
  %r = and i256 %a, %b
  ret i256 %r
}

; CHECK-LABEL: or_i256:
; CHECK:       revive.wor w0, w0, w1
define i256 @or_i256(i256 %a, i256 %b) {
  %r = or i256 %a, %b
  ret i256 %r
}

; CHECK-LABEL: xor_i256:
; CHECK:       revive.wxor w0, w0, w1
define i256 @xor_i256(i256 %a, i256 %b) {
  %r = xor i256 %a, %b
  ret i256 %r
}

; div/rem select to the wide instruction: setMaxDivRemBitWidthSupported keeps the
; ExpandLargeDivRem IR pass from rewriting i256 division into a software limb loop.
; CHECK-LABEL: udiv_i256:
; CHECK:       revive.wdivu w0, w0, w1
define i256 @udiv_i256(i256 %a, i256 %b) {
  %r = udiv i256 %a, %b
  ret i256 %r
}

; CHECK-LABEL: sdiv_i256:
; CHECK:       revive.wdiv w0, w0, w1
define i256 @sdiv_i256(i256 %a, i256 %b) {
  %r = sdiv i256 %a, %b
  ret i256 %r
}

; CHECK-LABEL: urem_i256:
; CHECK:       revive.wremu w0, w0, w1
define i256 @urem_i256(i256 %a, i256 %b) {
  %r = urem i256 %a, %b
  ret i256 %r
}

; A wide comparison narrows to a GPR.
; CHECK-LABEL: ult_i256:
; CHECK:       revive.wsltu a0, w0, w1
define i64 @ult_i256(i256 %a, i256 %b) {
  %c = icmp ult i256 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

; CHECK-LABEL: eq_i256:
; CHECK:       revive.wseq a0, w0, w1
define i64 @eq_i256(i256 %a, i256 %b) {
  %c = icmp eq i256 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

; Shift amount comes from a GPR.
; CHECK-LABEL: shl_i256:
; CHECK:       revive.wsll w0, w0, a0
define i256 @shl_i256(i256 %a, i64 %n) {
  %e = zext i64 %n to i256
  %r = shl i256 %a, %e
  ret i256 %r
}

; Load and store are one instruction each, no vtype.
; CHECK-LABEL: load_i256:
; CHECK:       revive.wld w0, 0(a0)
define i256 @load_i256(ptr %p) {
  %v = load i256, ptr %p
  ret i256 %v
}

; CHECK-LABEL: store_i256:
; CHECK:       revive.wst w0, 0(a0)
define void @store_i256(i256 %v, ptr %p) {
  store i256 %v, ptr %p
  ret void
}

; Conversions between a wide value and an XLen one.
; CHECK-LABEL: zext_i256:
; CHECK:       revive.wzext w0, a0
define i256 @zext_i256(i64 %a) {
  %r = zext i64 %a to i256
  ret i256 %r
}

; CHECK-LABEL: trunc_i256:
; CHECK:       revive.wtrunc a0, w0
define i64 @trunc_i256(i256 %a) {
  %r = trunc i256 %a to i64
  ret i64 %r
}

; A register-to-register move (from the loop-carried value) uses the wide move.
; It must be wmv2r (256-bit); wmv1r would drop the high 128 bits of the i256.
; CHECK-LABEL: move_i256:
; CHECK:       revive.wmv2r
define i256 @move_i256(i256 %a, i64 %n) {
entry:
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i256 [ %a, %entry ], [ %acc2, %loop ]
  %acc2 = add i256 %acc, %a
  %i2 = add i64 %i, 1
  %d = icmp eq i64 %i2, %n
  br i1 %d, label %out, label %loop
out:
  ret i256 %acc2
}

; A select expands to a conditional-branch triangle, no wide conditional move.
; CHECK-LABEL: select_i256:
; CHECK-DAG:   revive.wadd
; CHECK-DAG:   revive.wsub
define i256 @select_i256(i256 %a, i256 %b, i64 %c) {
  %x = add i256 %a, %b
  %y = sub i256 %a, %b
  %cond = icmp eq i64 %c, 0
  %r = select i1 %cond, i256 %x, i256 %y
  ret i256 %r
}

; A wide value live across a call is spilled and reloaded with the wide access.
; CHECK-LABEL: spill_i256:
; CHECK:       revive.wst {{w[0-9]+}}, {{[0-9]+}}(sp)
; CHECK:       call sink
; CHECK:       revive.wld {{w[0-9]+}}, {{[0-9]+}}(sp)
declare void @sink()
define i256 @spill_i256(i256 %a, i256 %b) {
  %s = add i256 %a, %b
  call void @sink()
  %r = add i256 %s, %b
  ret i256 %r
}
