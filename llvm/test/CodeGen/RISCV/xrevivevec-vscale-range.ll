; RUN: not llc -mtriple=riscv64 < %s 2>&1 | FileCheck %s

; The bounds can arrive as an attribute too. vscale_range(4,4) is VLEN=256.

; CHECK: XReviveVec requires VLEN=128, but the vector length minimum is 256

define i256 @add256(i256 %a, i256 %b) #0 {
  %r = add i256 %a, %b
  ret i256 %r
}

attributes #0 = { "target-features"="+m,+xrevivevec" vscale_range(4,4) }
