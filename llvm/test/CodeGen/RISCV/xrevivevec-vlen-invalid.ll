; Only VLEN=128 is defined, where an LMUL=2 group is exactly 256 bits. Any other
; width would silently change what the register classes hold.

; Unset on the command line: pinned to 128, no diagnostic.
; RUN: llc -mtriple=riscv64 -mattr=+m,+xrevivevec < %s | FileCheck %s

; Zero means "derive from Zvl", which with this extension is 128. Also fine.
; RUN: llc -mtriple=riscv64 -mattr=+m,+xrevivevec -riscv-v-vector-bits-min=0 \
; RUN:   < %s | FileCheck %s

; Explicitly the supported width.
; RUN: llc -mtriple=riscv64 -mattr=+m,+xrevivevec -riscv-v-vector-bits-min=128 \
; RUN:   -riscv-v-vector-bits-max=128 < %s | FileCheck %s

; RUN: not llc -mtriple=riscv64 -mattr=+m,+xrevivevec \
; RUN:   -riscv-v-vector-bits-min=256 < %s 2>&1 | FileCheck %s --check-prefix=MIN

; RUN: not llc -mtriple=riscv64 -mattr=+m,+xrevivevec \
; RUN:   -riscv-v-vector-bits-max=512 < %s 2>&1 | FileCheck %s --check-prefix=MAX

; MIN: XReviveVec requires VLEN=128, but the vector length minimum is 256
; MAX: XReviveVec requires VLEN=128, but the vector length maximum is 512

; CHECK-LABEL: add256:
; CHECK: revive.add256
define i256 @add256(i256 %a, i256 %b) {
  %r = add i256 %a, %b
  ret i256 %r
}
