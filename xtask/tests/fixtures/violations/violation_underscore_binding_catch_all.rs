// BC-2.14.003 {PC-006}/{EC-004}/{EC-007} live-violation fixture (HIGH-1 fix):
// An underscore-prefixed irrefutable binding catch-all arm with unreachable!()
// must be FLAGGED.
//
// §EC-004 says `_other => unreachable!()` is NOT exempt — the leading `_` does
// not make this a wildcard `_` arm, but it IS still an irrefutable binding that
// matches every value not covered by earlier arms. Adding a new enum variant
// makes this arm reachable, causing a production panic.
//
// is_catch_all_pat must return true for `_other` (first char == '_').
pub fn process_status(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        _other => unreachable!("should not reach: {}", _other),
    }
}
