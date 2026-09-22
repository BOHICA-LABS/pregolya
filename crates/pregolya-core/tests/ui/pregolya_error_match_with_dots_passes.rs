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
    // `code` is a private field; `message` is public. We extract `message`
    // and access `code` via the `code()` accessor to confirm both work externally.
    let _ = err.code(); // BC-2.14.001: code is private field; pub fn code() accessor works externally
    let pregolya_core::PregolyaError { message, .. } = err;
    message
}

fn main() {}
