// AC-007 compile-pass fixture — external match on ProblemDetail WITH `..`
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST compile successfully because the pattern uses `..`
// as required by `#[non_exhaustive]`.
//
// This companion fixture proves the boundary precisely: it is the missing `..`
// that causes the compile error, not some other aspect of the match.
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv F1 (POL-42).

fn check(pd: pregolya_core::ProblemDetail) -> String {
    // Correct external pattern: `..` is required and present.
    let pregolya_core::ProblemDetail { type_uri, .. } = pd;
    type_uri
}

fn main() {}
