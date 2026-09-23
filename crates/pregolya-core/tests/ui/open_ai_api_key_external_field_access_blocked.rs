// BC-2.14.005 compile-fail fixture — external field access on OpenAiApiKey (E0532)
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST NOT compile: attempting to bind the private inner
// field of `OpenAiApiKey` from an external crate produces E0532:
// "cannot match against a tuple struct which contains private fields".
//
// The field `(String)` inside `OpenAiApiKey` is private — external code cannot
// name or access it in a pattern. The `#[non_exhaustive]` attribute additionally
// prevents exhaustive matching from outside the defining crate.
//
// Traces to: BC-2.14.005 {PC-003}, S-1.02 non-exhaustive gate (F-P47-MED-002 fix).

fn check(key: pregolya_core::OpenAiApiKey) {
    // Attempt to destructure the tuple field — private field blocks this with E0532.
    let pregolya_core::OpenAiApiKey(_inner) = key;
    let _ = _inner;
}

fn main() {}
