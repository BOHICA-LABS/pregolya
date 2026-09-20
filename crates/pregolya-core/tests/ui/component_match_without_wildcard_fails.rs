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
        pregolya_core::Component::Traj => 3,
        pregolya_core::Component::Server => 4,
        pregolya_core::Component::Prov => 5,
        pregolya_core::Component::Mcp => 6,
        pregolya_core::Component::Split => 7,
        pregolya_core::Component::Sbxd => 8,
        pregolya_core::Component::Retry => 9,
        pregolya_core::Component::Cron => 10,
        pregolya_core::Component::Memory => 11,
        pregolya_core::Component::Budget => 12,
        pregolya_core::Component::Tmpl => 13,
        pregolya_core::Component::Srlz => 14,
        pregolya_core::Component::Vs => 15,
        pregolya_core::Component::Embed => 16,
        pregolya_core::Component::Tools => 17,
        pregolya_core::Component::Custom(_) => 18,
        // No `_ => {}` arm — this omission is the point of the test.
    }
}

fn main() {}
