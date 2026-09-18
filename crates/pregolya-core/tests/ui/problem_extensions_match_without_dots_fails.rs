// AC-007 compile-fail fixture — external match on ProblemExtensions WITHOUT `..`
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST NOT compile because `ProblemExtensions` is marked
// `#[non_exhaustive]` and matching without `..` is forbidden outside the
// defining crate (rustc E0638).
//
// `ProblemExtensions` lives at `pregolya_core::error::ProblemExtensions`
// (not re-exported at the crate root).
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv F1 (POL-42).

fn check(pe: pregolya_core::error::ProblemExtensions) -> String {
    // From outside pregolya_core, this pattern is illegal:
    //   `..` required with struct marked as non-exhaustive (E0638)
    let pregolya_core::error::ProblemExtensions { retry_hint, component } = pe;
    let _ = component;
    retry_hint
}

fn main() {}
