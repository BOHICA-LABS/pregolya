// BC-2.14.003 {PC-005}/{EC-007} live-violation fixture (MED-2 fix):
// assert! with # Panics doc where the BC-ID is in the CONDITION (not the message)
// must be FLAGGED.
//
// EC-007 requires the BC-ID to appear in the assert MESSAGE string argument, not
// in the condition expression. Checking that the condition string starts with a
// BC-ID does not satisfy the assertion documentation requirement.
//
// # Panics
//
// Panics if code does not start with a valid BC prefix.
pub fn validate_code(code: &str) {
    assert!(
        code.starts_with("BC-2.14.003"),
        "no bc id in message: code format check failed"
    );
}
