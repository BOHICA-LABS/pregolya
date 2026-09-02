---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.005
version: "1.5"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-14
capability: CAP-016
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-core per module-decomposition.md v1.10."
  - "1.2 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.02 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.3 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.4 (round-47/F-P2A197-03/2026-08-30): F-P2A197-03 [LOW/records] Debug form inconsistency adjudicated — canonical Debug form is exactly '<redacted>' per CLAUDE.md §Newtype + redacted Debug (f.write_str('<redacted>') emits exactly '<redacted>'); {PC-002} 'exactly' wording retained as authoritative source of truth. TV-001 expected output corrected from 'FooApiKey(<redacted>)' (or '<redacted>') to '<redacted>' (exact match). EC-003 expected behavior corrected from 'FooApiKey(<redacted>)' to '<redacted>' (exact match). Both aligned to {PC-002}/{INV-002}. {INV-002} log-scrubber substring guarantee unaffected."
  - "1.5 (round-67 reconciliation/2026-09-02): Story Anchor expanded to multi-anchor. S-1.02 remains primary anchor (creates credential newtypes in pregolya-core/src/credentials.rs). S-2.06 added as co-anchor: SDK crates cannot depend on pregolya-core per BC-2.08.006 PC-001, so SDK crates define independent credential newtypes (OpenAiApiKey etc. in pregolya-{openai,anthropic,ollama}-sdk) governed by the same workspace-wide policy. S-2.06 AC-006 traces to {PC-002} — the trace is behaviorally exact. No behavioral change; Story Anchor field corrected from exclusive to multi-anchor. STORY-INDEX BC-to-Story anchor map row and sprint-state.yaml S-2.06 bcs array delegated to state-manager."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
  - domain-spec/invariants.md#DI-010
  - NE-10
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "646db6f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.005: API Key Newtype with Redacted Debug; No Serialize; No Deref<Target=str>

## Description

Every API key or secret credential type in pregolya must be a newtype struct (not a bare
`String` or `&str`). The `Debug` implementation must emit the literal `"<redacted>"` and
never expose the key value. The type must not `#[derive(Serialize)]` and must not
`impl Deref<Target = str>`. CI lint enforces this. This contract addresses NE-10
(adk-rust's bare-String API keys with `#[derive(Debug)]` that leak secrets to logs).

## Preconditions

1. {PRE-001} A pregolya crate defines a type intended to carry an API key or secret credential value.
2. {PRE-002} The type is declared in non-test code (`!#[cfg(test)]` scope).
3. {PRE-003} The implementing engineer is writing or modifying the key type definition.

## Postconditions

1. {PC-001} The key type is a newtype struct: `pub struct FooApiKey(String)` (or `Arc<str>` variant) — not a type alias.
2. {PC-002} `impl fmt::Debug for FooApiKey` emits exactly `"<redacted>"` — no substring of the actual key value appears in any format specifier.
3. {PC-003} The type does NOT `#[derive(Serialize)]` (serde serialization is explicitly absent or gated behind an internal-use-only feature).
4. {PC-004} The type does NOT `impl Deref<Target = str>` or `impl Deref<Target = String>`.
5. {PC-005} The type provides an `.as_str()` or `.expose_secret()` method (or similar) for the narrow use-case of passing the value to an HTTP client; calling sites are explicit opt-in.
6. {PC-006} CI lint gate (`cargo xtask deny-bare-api-key` or equivalent custom lint) causes the build to fail if any public struct carrying "key", "token", "secret", or "credential" in its name derives `Debug` without a manual impl, derives `Serialize`, or impls `Deref<Target=str>`.

## Invariants

- {INV-001} **DI-010 (Credential Opacity):** Credentials never appear in log output, error messages, serialized artifacts, or formatted strings under any execution path.
- {INV-002} The redacted string literal must be exactly `"<redacted>"` (matching the pregolya-standard log-scrubber pattern so automated log scanning tools can detect accidental exposures).
- {INV-003} Inner value is only accessible via an explicit `expose_secret()` / `inner()` call — never via trait auto-deref.

## Edge Cases

### EC-001: Accidentally serialized key via serde
**Scenario:** A type containing `FooApiKey` is serialized with `serde_json::to_string`. The `FooApiKey` field does not derive `Serialize`.
**Expected behavior:** Compilation error — the parent struct's `#[derive(Serialize)]` fails if `FooApiKey` does not implement `Serialize`. The key cannot be silently serialized.
**Reference:** NE-10; DI-010.

### EC-002: Debug format in error context
**Scenario:** `anyhow::Error` or `PregolyaError` wraps a value containing a `FooApiKey` and is formatted via `{:?}`.
**Expected behavior:** The formatted output contains `"<redacted>"` for the key field, never the actual key bytes.

### EC-003: Log macro with API key struct
**Scenario:** `tracing::debug!("{:?}", api_key)` is called with a key instance.
**Expected behavior:** The log record contains the string `"<redacted>"` (exact, per {PC-002} canonical `f.write_str("<redacted>")` impl), never the key value. The tuple-wrapper form `FooApiKey(<redacted>)` does NOT appear because the manual `Debug` impl writes the literal string `"<redacted>"` directly.

### EC-004: Clone does not expose inner value
**Scenario:** A `FooApiKey` is `Clone`'d for use across threads.
**Expected behavior:** `Clone` is permitted and does not involve `Debug` or `Display` output. The cloned value retains opacity.

### EC-005: Comparison in tests uses expose_secret
**Scenario:** A unit test asserts that a parsed config contains the correct API key.
**Expected behavior:** Test calls `api_key.expose_secret() == "expected-value"` explicitly. The assertion does not rely on `Debug` or `PartialEq` with the raw string.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `format!("{:?}", FooApiKey::new("sk-real-secret"))` | `"<redacted>"` | Happy path — debug output is opaque; exact string per {PC-002}/{INV-002} canonical form |
| TV-002 | `serde_json::to_string(&FooApiKey::new("sk-real-secret"))` | Compilation error (`Serialize` not impl'd) | Key type must not be serializable |
| TV-003 | Attempt `let s: &str = &api_key` via `Deref` | Compilation error (`Deref` not impl'd) | No silent deref to str |
| TV-004 | `api_key.expose_secret()` returns `"sk-real-secret"` | `"sk-real-secret"` — explicit access works | Explicit opt-in path |
| TV-005 | CI lint runs on crate containing `pub struct OpenAiApiKey(String)` with `#[derive(Debug)]` | Lint error: `"OpenAiApiKey" carries credential name; manual Debug impl required` | Lint gate enforcement |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI010-01 | `Debug` output of any `*ApiKey` / `*Token` / `*Secret` type contains `<redacted>` literal | Property test (proptest over random key strings) | Phase 1 |
| VP-DI010-02 | No `Serialize` impl on credential newtypes (compile-time) | CI lint / `cargo check` | Wave 0 CI |
| VP-DI010-03 | No `Deref<Target=str>` on credential newtypes (compile-time) | CI lint | Wave 0 CI |

## Related BCs

- BC-2.14.001 — PregolyaError 2D struct (composes with: error type that wraps credentials must also redact)
- BC-2.14.003 — Constructor Result contract (depends on: key construction returns `Result<FooApiKey, PregolyaError>`, not panic)
- BC-2.14.006 — Validation failure propagation (depends on: empty/malformed key string → `Err`, not `None`)

## Architecture Anchors

- `pregolya-core/src/credentials.rs` (to be created)
- CI: `cargo xtask deny-bare-api-key` lint target

## Story Anchor

S-1.02 (primary — credential newtypes in `pregolya-core/src/credentials.rs`), S-2.06 (co-anchor — credential newtypes in SDK crates; SDK crates cannot depend on `pregolya-core` per BC-2.08.006 PC-001, so they define independent newtypes subject to this policy)

## VP Anchors

- VP-DI010-01, VP-DI010-02, VP-DI010-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (PregolyaError 2D Struct)") per capabilities-p0.md §CAP-016 — credential opacity is a direct sub-requirement of the error taxonomy surface; specifically the NE-10 counter-example (adk-rust bare-String API keys) is explicitly listed under CAP-016's grounding |
| L2 Domain Invariants | DI-010 (Credential Opacity) |
| NE References | NE-10 |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), CI lint |
| Module | pregolya-core |
