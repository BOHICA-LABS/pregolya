// BC-2.14.003 {PC-006}/{EC-007} live-violation fixture (pass-8 F-01):
// A `mut other => unreachable!(...)` catch-all arm must be FLAGGED.
//
// `mut other` is an irrefutable binding — the `mut` keyword changes the binding
// mode (mutable binding) but does NOT restrict which values the pattern matches.
// An irrefutable mutable-binding is semantically a catch-all: it matches any value
// not covered by earlier arms. Adding a new type-domain member makes this arm
// reachable, causing a production panic.
//
// The §EC-007 exhaustive-match exemption grants Exemption 1 ONLY to named variant
// patterns (e.g. `Phase::Done`). A `mut other =>` binding-mode arm is not a named
// variant pattern regardless of the `mut` keyword.
//
// Red-gate provenance: authored when is_catch_all_pat checked `p.mutability.is_none()` for
// Pat::Ident; a `mut` binding had `mutability` as Some(...), causing the check to return
// false and Exemption 1 to be incorrectly applied. The shipped syn/AST scanner treats
// `mut other` as an irrefutable binding (catch-all) and FLAGS this fixture.
pub fn process_mut(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        mut other => unreachable!("F-01 pass-8: mut binding catch-all: {}", other),
    }
}
