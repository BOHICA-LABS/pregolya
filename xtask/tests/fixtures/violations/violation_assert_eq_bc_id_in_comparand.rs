// Violation fixture: assert_eq! / assert_ne! with BC-ID in comparand, not message.
// EC-007 requires the BC-ID to appear in the assert MESSAGE argument.
// These are violations: the BC-ID "BC-2.14.003" is the right-hand comparand, not a message.
// check-no-panic must flag these even though a # Panics doc + BC-ID text are present.

/// # Panics
///
/// Panics if the code does not have the BC-2.14.003 prefix.
pub fn validate_code_prefix(code: &str) {
    assert_eq!(code, "BC-2.14.003");       // VIOLATION: BC-ID in comparand
    assert_ne!(code, "BC-2.14.003");       // VIOLATION: BC-ID in comparand
}
