// AC-007 compile-fail fixture — external match on PregolyaError WITHOUT `..`
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST NOT compile because `PregolyaError` is marked
// `#[non_exhaustive]` and matching without `..` is forbidden outside the
// defining crate (rustc E0638).
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv pass-1 F2.

fn check(err: pregolya_core::PregolyaError) -> String {
    // From outside pregolya_core, this pattern is illegal:
    //   `..` required with struct marked as non-exhaustive (E0638)
    let pregolya_core::PregolyaError { message } = err;
    message
}

fn main() {}
