; RUN: llc -mtriple=riscv64 -mattr=+e,+m,+xrevivevec -target-abi lp64e \
; RUN:   -riscv-revive-i128 -verify-machineinstrs < %s | FileCheck %s

; The callee-saved half of the vector file is named by the register pairs, so a
; half is preserved across a call because it sits beneath a pair in the list and
; not because it is in the list itself. A function that clobbers one half has to
; save the whole pair it belongs to: the caller is entitled to keep an i128 in
; that half, and the pair is the only unit the prologue can save it as.

declare void @sink()

define i128 @half_live_across_call(i128 %a) {
; CHECK-LABEL: half_live_across_call:
; CHECK:         revive.wst v24, 0(sp) # 32-byte Folded Spill
; CHECK:         revive.wmv.i128 v24, v8
; CHECK:         call sink
; CHECK:         revive.wmv.i128 v8, v24
; CHECK:         revive.wld v24, 0(sp) # 32-byte Folded Reload
  call void @sink()
  ret i128 %a
}

define i256 @pair_live_across_call(i256 %a) {
; CHECK-LABEL: pair_live_across_call:
; CHECK:         revive.wst v24, 0(sp) # 32-byte Folded Spill
; CHECK:         revive.wmv v24, v8
; CHECK:         call sink
; CHECK:         revive.wmv v8, v24
; CHECK:         revive.wld v24, 0(sp) # 32-byte Folded Reload
  call void @sink()
  ret i256 %a
}
