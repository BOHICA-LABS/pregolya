// POL-31 live-violation fixture (BC-2.14.003 EC-007, AC-017):
// A `_ => unreachable!()` wildcard arm must be FLAGGED by check-no-panic.
//
// Wildcard arms are potentially reachable when the matched type gains new variants
// (e.g. an integer type's future-expanded domain) or when a non-exhaustive enum
// adds a variant. Wildcard unreachable! is NOT a valid exhaustiveness witness —
// it is a latent panic path under enum evolution.
pub fn categorize(n: u32) -> &'static str {
    match n {
        0 => "zero",
        1 => "one",
        _ => unreachable!("unexpected value: {}", n),
    }
}
