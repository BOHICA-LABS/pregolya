// BC-2.14.005 compile-fail fixture — external pattern on OpenAiApiKey WITHOUT `..`
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST NOT compile: `OpenAiApiKey` is `#[non_exhaustive]`
// and its inner field is `pub(crate)`. Attempting to bind the field from
// external code fails because the field is private (E0603); the
// `#[non_exhaustive]` attribute additionally requires `..` in any pattern
// that touches the struct from outside the defining crate (E0638).
//
// Traces to: BC-2.14.005 {PC-003}, S-1.02 stub non-exhaustive gate.

fn check(key: pregolya_core::OpenAiApiKey) {
    // Attempt to destructure the tuple field — private + non-exhaustive prevents this.
    let pregolya_core::OpenAiApiKey(_inner) = key;
    let _ = _inner;
}

fn main() {}
