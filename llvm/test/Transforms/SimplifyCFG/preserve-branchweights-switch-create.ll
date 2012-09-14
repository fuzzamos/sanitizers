; RUN: opt -simplifycfg -S -o - < %s | FileCheck %s

declare void @func2(i32)
declare void @func4(i32)
declare void @func6(i32)
declare void @func8(i32)

;; test1 - create a switch with case 2 and case 4 from two branches: N == 2
;; and N == 4.
define void @test1(i32 %N) nounwind uwtable {
entry:
  %cmp = icmp eq i32 %N, 2
  br i1 %cmp, label %if.then, label %if.else, !prof !0
; CHECK: test1
; CHECK: switch i32 %N
; CHECK: ], !prof !0

if.then:
  call void @func2(i32 %N) nounwind
  br label %if.end9

if.else:
  %cmp2 = icmp eq i32 %N, 4
  br i1 %cmp2, label %if.then7, label %if.else8, !prof !1

if.then7:
  call void @func4(i32 %N) nounwind
  br label %if.end

if.else8:
  call void @func8(i32 %N) nounwind
  br label %if.end

if.end:
  br label %if.end9

if.end9:
  ret void
}

;; test2 - Merge two switches where PredDefault == BB.
define void @test2(i32 %M, i32 %N) nounwind uwtable {
entry:
  %cmp = icmp sgt i32 %M, 2
  br i1 %cmp, label %sw1, label %sw2

sw1:
  switch i32 %N, label %sw2 [
    i32 2, label %sw.bb
    i32 3, label %sw.bb1
  ], !prof !2
; CHECK: test2
; CHECK: switch i32 %N, label %sw.epilog
; CHECK: i32 2, label %sw.bb
; CHECK: i32 3, label %sw.bb1
; CHECK: i32 4, label %sw.bb5
; CHECK: ], !prof !1

sw.bb:
  call void @func2(i32 %N) nounwind
  br label %sw.epilog

sw.bb1:
  call void @func4(i32 %N) nounwind
  br label %sw.epilog

sw2:
;; Here "case 2" is invalidated if control is transferred through default case
;; of the first switch.
  switch i32 %N, label %sw.epilog [
    i32 2, label %sw.bb4
    i32 4, label %sw.bb5
  ], !prof !3

sw.bb4:
  call void @func6(i32 %N) nounwind
  br label %sw.epilog

sw.bb5:
  call void @func8(i32 %N) nounwind
  br label %sw.epilog

sw.epilog:
  ret void
}

!0 = metadata !{metadata !"branch_weights", i32 64, i32 4}
!1 = metadata !{metadata !"branch_weights", i32 4, i32 64}
; CHECK: !0 = metadata !{metadata !"branch_weights", i32 256, i32 4352, i32 16}
!2 = metadata !{metadata !"branch_weights", i32 4, i32 4, i32 8}
!3 = metadata !{metadata !"branch_weights", i32 8, i32 8, i32 4}
; CHECK: !1 = metadata !{metadata !"branch_weights", i32 32, i32 48, i32 96, i32 16}
