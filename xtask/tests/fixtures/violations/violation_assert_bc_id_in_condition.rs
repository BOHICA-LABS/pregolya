// BC-2.14.003 {PC-005}/{EC-007} live-violation fixture (MED-2 fix):
// assert! with # Panics doc where the BC-ID is in the CONDITION (not the message)
// must be FLAGGED.
//
// EC-007 requires the BC-ID to appear in the assert MESSAGE string argument, not
// in the condition expression. Checking that the condition string starts with a
// BC-ID does not satisfy the assertion documentation requirement.
/// # Panics
///
/// This function may panic if the code is not a valid BC identifier.
pub fn validate_bc_code(code: &str) {
    assert!(code.starts_with("BC-2.14.003"), "no bc id in message — code must start with BC prefix");
}
