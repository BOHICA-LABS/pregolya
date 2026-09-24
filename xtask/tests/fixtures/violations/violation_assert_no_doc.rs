// POL-31 live-violation fixture (BC-2.14.003 EC-007, AC-017):
// A bare assert! on a function WITHOUT a `# Panics` doc section
// and WITHOUT a BC-ID in the assert message must be FLAGGED by check-no-panic.
//
// The function below has no /// # Panics section and the assert message
// contains no BC-NNN identifier — both conditions required for the EC-006
// programmer-error-guard exemption are absent.
pub fn validate_positive(x: i32) {
    assert!(x > 0, "x must be positive");
}
