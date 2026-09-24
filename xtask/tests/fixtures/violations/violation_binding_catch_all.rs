// BC-2.14.003 {PC-006}/{EC-007} live-violation fixture (pass-4 F-02):
// An irrefutable binding catch-all arm with unreachable!() must be FLAGGED.
//
// §EC-007 grants the exhaustive-match exemption ONLY when every arm is a named
// variant pattern (no `_`, no irrefutable binding). An irrefutable binding `other =>`
// is semantically a catch-all: it matches any value not covered by earlier arms.
// Adding a new enum variant or extending the matched type domain makes this arm
// reachable, causing a production panic.
//
// The exemption for `Phase::Done => unreachable!(...)` is valid because
// `Phase::Done` is an explicit named variant, not a catch-all. `other =>` is not.
pub fn process_value(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        other => unreachable!("F-02: irrefutable binding catch-all: {}", other),
    }
}
