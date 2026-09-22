// AC-007 compile-fail fixture — external match on ProblemDetail WITHOUT `..`
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST NOT compile because `ProblemDetail` is marked
// `#[non_exhaustive]` and matching without `..` is forbidden outside the
// defining crate (rustc E0638).
//
// Traces to: BC-2.14.001 {PC-008}, S-1.01 AC-007, adv F1 (POL-42).
// Updated in pass-9b: retry_hint and component are now direct top-level fields
// (ProblemExtensions removed per BC-2.14.002 v1.16 {PC-001} option ii).

fn check(pd: pregolya_core::ProblemDetail) -> String {
    // From outside pregolya_core, this pattern is illegal:
    //   `..` required with struct marked as non-exhaustive (E0638)
    let pregolya_core::ProblemDetail { type_uri, title, detail, retry_hint, component } = pd;
    let _ = (title, detail, retry_hint, component);
    type_uri
}

fn main() {}
