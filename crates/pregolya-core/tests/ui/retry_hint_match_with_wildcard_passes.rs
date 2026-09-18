// AC-007 compile-pass fixture — external match on RetryHint WITH `_` wildcard arm
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST compile successfully because the pattern includes
// a wildcard `_ => {}` arm as required by `#[non_exhaustive]`.
//
// This companion fixture proves the boundary precisely: it is the missing
// wildcard arm that causes the compile error, not the match itself.
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv F1 (POL-42).

fn check(h: pregolya_core::RetryHint) -> &'static str {
    // Correct external pattern: wildcard arm handles current and future variants.
    match h {
        pregolya_core::RetryHint::Never => "never",
        pregolya_core::RetryHint::Maybe => "maybe",
        _ => "other",
    }
}

fn main() {}
