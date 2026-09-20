// AC-007 compile-pass fixture — external match on ProblemExtensions WITH `..`
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST compile successfully because the pattern uses `..`
// as required by `#[non_exhaustive]`.
//
// This companion fixture proves the boundary precisely: it is the missing `..`
// that causes the compile error, not some other aspect of the match.
//
// `ProblemExtensions` is re-exported at `pregolya_core::ProblemExtensions`
// (also accessible at the module path `pregolya_core::error::ProblemExtensions`).
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv F1 (POL-42).

fn check(pe: pregolya_core::ProblemExtensions) -> String {
    // Correct external pattern: `..` is required and present.
    let pregolya_core::ProblemExtensions { retry_hint, .. } = pe;
    retry_hint
}

fn main() {}
