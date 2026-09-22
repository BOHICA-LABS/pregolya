// BC-2.14.005 compile-pass fixture — external use of OpenAiApiKey WITHOUT field access
//
// This file is compiled by trybuild as an independent binary (simulating an
// external crate). It MUST compile successfully: the key is used opaquely,
// without attempting to bind its private inner field.
//
// From an external crate, `OpenAiApiKey` can be:
//   - received as a function parameter
//   - passed to another function expecting the same type
//   - moved or dropped
//
// The companion `_fails.rs` shows what is NOT allowed (binding the private field).
//
// Traces to: BC-2.14.005 {PC-003}, S-1.02 non-exhaustive gate.

fn consume(_key: pregolya_core::OpenAiApiKey) {
    // Opaque use — no field access, no pattern binding. This is always valid
    // regardless of field visibility or #[non_exhaustive].
}

fn main() {}
