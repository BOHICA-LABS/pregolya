// BC-2.14.003 §EC-007 pass-5 F-01 live-violation fixture:
// A guarded irrefutable-binding catch-all `name if <guard> => unreachable!(...)` must be FLAGGED.
//
// §EC-007 grants the exhaustive-match exemption ONLY when every arm is a named variant pattern
// (no `_`, no irrefutable binding, no guarded catch-all). An irrefutable binding `other`
// is semantically a catch-all regardless of whether a guard is appended — the guard only
// further restricts when the arm fires; it does not make the binding a named variant.
//
// Adding a new variant or extending the matched type domain can satisfy the guard, making
// the `unreachable!()` reachable in production.
pub fn process_with_guard(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        other if other > 100 => unreachable!("pass-5 F-01: guarded irrefutable binding: {}", other),
    }
}
