; ModuleID = 'sampleMod'
source_filename = "sampleMod"

define i32 @simple() {
entry:
  ret i32 0
}

define i32 @add(i32 %0, i32 %1) {
entry:
  %2 = add i32 %0, %1
  ret i32 %2
}

define float @addIntFloat(i32 %0, float %1) {
entry:
  %2 = sitofp i32 %0 to float
  %3 = fadd float %2, %1
  ret float %3
}

define i32 @conditional(i1 %0) {
entry:
  %1 = alloca i32, align 4
  %2 = select i1 %0, i32 3, i32 5
  store i32 %2, ptr %1, align 4
  %3 = load i32, ptr %1, align 4
  %4 = add i32 %3, 11
  ret i32 %4
}

define i32 @oneTwoPhi(i1 %0) {
entry:
  br i1 %0, label %true, label %false

true:                                             ; preds = %entry
  br label %merge

false:                                            ; preds = %entry
  br label %merge

merge:                                            ; preds = %false, %true
  %1 = phi i32 [ 3, %true ], [ 5, %false ]
  %2 = add i32 %1, 11
  ret i32 %2
}

define i32 @selection(i1 %0) {
entry:
  %1 = select i1 %0, i32 3, i32 5
  %2 = add i32 %1, 11
  ret i32 %2
}
