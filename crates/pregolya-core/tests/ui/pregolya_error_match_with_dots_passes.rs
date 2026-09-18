// AC-007 compile-pass fixture — external match on PregolyaError WITH `..`
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST compile successfully because the pattern uses `..`
// as required by `#[non_exhaustive]`.
//
// This companion fixture proves the boundary precisely: it is the missing `..`
// that causes the compile error, not some other aspect of the match.
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv pass-1 F2.

fn check(err: pregolya_core::PregolyaError) -> String {
    // Correct external pattern: `..` is required and present.
    let pregolya_core::PregolyaError { code, .. } = err;
    code
}

fn main() {}
