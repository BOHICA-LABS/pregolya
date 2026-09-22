// AC-007 compile-fail fixture — external exhaustive match on Category WITHOUT `_` arm
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST NOT compile because `Category` is marked
// `#[non_exhaustive]` and any external match must include a wildcard `_ => {}`
// arm to handle potential future variants.
//
// Even though every currently-defined variant is listed below, the compiler
// requires `_ => {}` for non-exhaustive enums matched from outside the crate.
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv F1 (POL-42).

fn check(c: pregolya_core::Category) -> u16 {
    // From outside pregolya_core, exhaustive match without `_` is illegal:
    //   non-exhaustive patterns: `_` not covered (E0004)
    match c {
        pregolya_core::Category::Val => 400,
        pregolya_core::Category::Auth => 401,
        pregolya_core::Category::Policy => 403,
        pregolya_core::Category::Security => 403,
        pregolya_core::Category::Rate => 429,
        pregolya_core::Category::Concurrency => 409,
        pregolya_core::Category::Tenancy => 409,
        pregolya_core::Category::Tool => 422,
        pregolya_core::Category::Transport => 502,
        pregolya_core::Category::Timeout => 504,
        pregolya_core::Category::Durability => 500,
        pregolya_core::Category::Internal => 500,
        pregolya_core::Category::Exec => 500,
        pregolya_core::Category::Sys => 500,
        // No `_ => {}` arm — this omission is the point of the test.
    }
}

fn main() {}
