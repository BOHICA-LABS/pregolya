// BC-2.14.003 {PC-006}/{EC-007} live-violation fixture (pass-8 F-01):
// A `ref other => unreachable!(...)` catch-all arm must be FLAGGED.
//
// `ref other` is an irrefutable binding — the `ref` keyword changes the binding
// mode (bound by reference) but does NOT restrict which values the pattern matches.
// An irrefutable reference-mode binding is semantically a catch-all: it matches
// any value not covered by earlier arms. Adding a new type-domain member makes
// this arm reachable, causing a production panic.
//
// The §EC-007 exhaustive-match exemption grants Exemption 1 ONLY to named variant
// patterns (e.g. `Phase::Done`). A `ref other =>` binding-mode arm is not a named
// variant pattern regardless of the `ref` keyword.
//
// Current false-negative: is_catch_all_pat checks `p.by_ref.is_none()` for
// Pat::Ident. When `ref` is present, `by_ref` is Some(...) → check returns false →
// arm_stack push(false) → Exemption 1 incorrectly applied.
pub fn process_ref(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        ref other => unreachable!("F-01 pass-8: ref binding catch-all: {}", other),
    }
}
