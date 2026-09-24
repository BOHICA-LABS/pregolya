// Violation fixture: todo!() in non-test library code.
// Used by test_bc_2_14_003_todo_stub_is_flagged to verify the check-no-panic
// scanner detects todo!() (F-P9-M02 fix, BC-2.14.003).

pub fn todo_stub_function() -> String {
    todo!("implement this")
}
