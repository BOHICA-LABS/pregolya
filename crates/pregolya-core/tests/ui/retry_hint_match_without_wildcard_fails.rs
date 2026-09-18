// AC-007 compile-fail fixture — external exhaustive match on RetryHint WITHOUT `_` arm
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST NOT compile because `RetryHint` is marked
// `#[non_exhaustive]` and any external match must include a wildcard `_ => {}`
// arm to handle potential future variants.
//
// Even though every currently-defined variant is listed below, the compiler
// requires `_ => {}` for non-exhaustive enums matched from outside the crate.
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv F1 (POL-42).

fn check(h: pregolya_core::RetryHint) -> &'static str {
    // From outside pregolya_core, exhaustive match without `_` is illegal:
    //   non-exhaustive patterns: `_` not covered (E0004)
    match h {
        pregolya_core::RetryHint::Never => "never",
        pregolya_core::RetryHint::Maybe => "maybe",
        pregolya_core::RetryHint::Later(_) => "later",
        // No `_ => {}` arm — this omission is the point of the test.
    }
}

fn main() {}
