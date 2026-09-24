// BC-2.14.003 {PC-005}/{EC-007} live-violation fixture (MED-2 fix):
// assert! with # Panics doc but an INVALID BC-ID format in the message
// must be FLAGGED.
//
// "BC-9" does not satisfy the required pattern BC-\d+\.\d{2}\.\d{3}
// (missing the .XX.XXX suffix). The gate must require the full canonical
// BC-ID shape, not merely that "BC-" appears followed by any digit.
/// # Panics
///
/// This function may panic if x is not positive.
pub fn validate_positive(x: i32) {
    assert!(x > 0, "BC-9 short id not valid — value must be positive");
}
