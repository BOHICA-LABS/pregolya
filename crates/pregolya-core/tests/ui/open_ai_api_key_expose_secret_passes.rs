// BC-2.14.005 compile-pass fixture — external use of OpenAiApiKey via public API
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST compile successfully.
//
// NOTE: For `OpenAiApiKey` (a tuple struct with a private field), ALL forms of
// pattern destructuring from external code are blocked by E0532 — including the
// `(..)` wildcard. Private field visibility prevents pattern matching entirely,
// not just named field access. This is stronger than `#[non_exhaustive]` alone.
//
// What DOES work from an external crate:
//   - Accepting a value by ownership or reference
//   - Calling public methods: `expose_secret()` is the gated access path
//
// This fixture demonstrates the correct external-crate interaction: `expose_secret()`
// is the only intentional path to the inner key value (BC-2.14.005 {PC-005}).
// It is discriminating: the fixture would fail to compile if `expose_secret()` were
// removed or made private, confirming the public API surface is intact.
//
// The companion `_blocked.rs` shows what is NOT allowed (binding the private field,
// E0532 — "cannot match against a tuple struct which contains private fields").
//
// Traces to: BC-2.14.005 {PC-003}, {PC-005}, S-1.02 non-exhaustive gate (F-P47-MED-002 fix).

fn check(key: pregolya_core::OpenAiApiKey) {
    // expose_secret() is the only external access path — no pattern destructuring allowed.
    let _ = key.expose_secret();
}

fn main() {}
