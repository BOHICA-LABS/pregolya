// BC-2.14.003 {PC-005}/{PC-006} live-violation fixture (pass-4 F-01):
// assert!{...} with brace delimiter must be FLAGGED by check-no-panic.
//
// BC-2.14.003 prohibits assert!, assert_eq!, assert_ne!, and panic! in
// non-test library code regardless of the macro invocation delimiter.
// The scanner must flag brace-delimited ( assert!{...} ) and bracket-delimited
// ( assert![...] ) forms with the same rule as the parenthesis form assert!(...).
pub fn check_nonnegative(x: i32) {
    assert!{x >= 0, "x must be non-negative"};
}
