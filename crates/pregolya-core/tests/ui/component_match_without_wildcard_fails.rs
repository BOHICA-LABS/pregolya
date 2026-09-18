// AC-007 compile-fail fixture — external exhaustive match on Component WITHOUT `_` arm
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST NOT compile because `Component` is marked
// `#[non_exhaustive]` and any external match must include a wildcard `_ => {}`
// arm to handle potential future variants.
//
// Even though every currently-defined variant is listed below, the compiler
// requires `_ => {}` for non-exhaustive enums matched from outside the crate.
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv F1 (POL-42).

fn check(c: pregolya_core::Component) -> u8 {
    // From outside pregolya_core, exhaustive match without `_` is illegal:
    //   non-exhaustive patterns: `_` not covered (E0004)
    match c {
        pregolya_core::Component::Core => 0,
        pregolya_core::Component::Graph => 1,
        pregolya_core::Component::Chkpt => 2,
        pregolya_core::Component::Server => 3,
        pregolya_core::Component::Prov => 4,
        pregolya_core::Component::Mcp => 5,
        pregolya_core::Component::Split => 6,
        pregolya_core::Component::Sbxd => 7,
        pregolya_core::Component::Retry => 8,
        pregolya_core::Component::Cron => 9,
        pregolya_core::Component::Memory => 10,
        pregolya_core::Component::Budget => 11,
        pregolya_core::Component::Tmpl => 12,
        pregolya_core::Component::Srlz => 13,
        pregolya_core::Component::Vs => 14,
        pregolya_core::Component::Embed => 15,
        pregolya_core::Component::Tools => 16,
        pregolya_core::Component::Custom(_) => 17,
        // No `_ => {}` arm — this omission is the point of the test.
    }
}

fn main() {}
