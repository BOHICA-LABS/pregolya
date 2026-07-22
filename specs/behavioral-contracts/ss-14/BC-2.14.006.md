---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.006
version: "1.2"
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
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-56): OBS-P56-2 codeless-error census (gate #30 first run) — EC-001, EC-004, TV-001, TV-004, TV-005 each had a specific 'Validation failed for...' message matching E-CORE-005 but no code field. Added code: E-CORE-005 to all five sites."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-core per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
  - domain-spec/invariants.md#DI-014
  - NE-03
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/behavioral-intent.md
input-hash: "aecb919"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.006: Validation Failures Propagate Err(FerrochainError); No Silent None

## Description

Every public ferrochain API that validates input must propagate validation failures as
`Err(FerrochainError { category: VAL, ... })`. No public function may return `None`,
an empty `Vec`, or a zero-value default to represent a validation failure — silent
swallowing is prohibited. This contract addresses NE-03 (adk-rust strict-mode skill
coordinator returns `None` on validation failure rather than propagating the error).

## Preconditions

1. A caller invokes a public ferrochain function with input that fails a validation check
   (type constraint, range check, format check, required-field-missing, etc.).
2. The function is in non-test, non-binary code (library surface).
3. The validation failure is deterministic — the same input will always fail.

## Postconditions

1. The function returns `Err(FerrochainError { component: <C>, category: VAL, retry_hint: Never, code: E-<C>-NNN, message: "<field>: <reason>" })`.
2. The caller can inspect `.component`, `.category`, `.code`, and `.message` to identify the exact validation constraint that failed.
3. The return type on the happy path is `Ok(T)` — the `None` / `Option<T>` pattern for validation-failure signaling is absent from the public API surface.
4. The error message uses the format `"Validation failed for '<field>': <reason>"` (E-CORE-005 or the component-appropriate code).
5. No intermediate callsite between the validation site and the public API boundary discards or converts the error to `None` / empty.

## Invariants

- **DI-014 (Error Propagation (No Silent Swallowing)):** Validation errors propagate as `Err`; no code path returns `None` or empty to indicate failure.
- Downstream consumers of a `Result<T, FerrochainError>` must not silently `.ok()` a validation error in library code — only application/binary code may choose to ignore errors after explicit handling.
- The `VAL` category always implies `retry_hint: Never` (the input must change; retrying the same input will not succeed).

## Edge Cases

### EC-001: Required field is missing in builder
**Scenario:** A builder pattern is used to construct a ferrochain type; a required field is not set; `.build()` is called.
**Expected behavior:** `.build()` returns `Err(FerrochainError { category: VAL, code: E-CORE-005, message: "Validation failed for 'field_name': field is required" })`. Returns `Ok(T)` only when all required fields are present.
**Reference:** DI-014; NE-03.

### EC-002: Config struct parsed from TOML with invalid enum value
**Scenario:** A config file contains an unrecognized string for an enum field (e.g., `durability = "turbo"` where `turbo` is not a valid `DurabilityTier`).
**Expected behavior:** Parsing returns `Err(FerrochainError { category: VAL, ... })` with a message identifying the field and the received value.

### EC-003: Nested validation — inner field fails, outer returns None (prohibited)
**Scenario:** A compound validator checks multiple fields; one inner check fails.
**Expected behavior:** The compound validator returns `Err` with the specific inner field that failed — it must NOT return `Ok(None)` or `Ok(Default::default())` as a sentinel.

### EC-004: Empty string for a required non-empty field
**Scenario:** An API key field is set to `""` (empty string).
**Expected behavior:** Constructor or setter returns `Err(FerrochainError { category: VAL, code: E-CORE-005, message: "Validation failed for 'api_key': value must not be empty" })`.

### EC-005: Validation inside a `From` impl
**Scenario:** A `TryFrom` impl (the correct pattern) vs a `From` impl (which cannot fail).
**Expected behavior:** Fallible conversions always use `TryFrom<T>`, returning `Result<Self, FerrochainError>`. `From<T>` is only used for infallible conversions. Using `From` to represent a conversion that can fail is a violation of this contract.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `GraphBuilder::new().build()` with no nodes set | `Err(FerrochainError { category: VAL, code: E-CORE-005, message: "Validation failed for 'nodes': at least one node is required" })` | Missing required field |
| TV-002 | `ChunkSize::new(0)` (chunk_size = 0) | `Err(FerrochainError { code: E-SPLIT-001, message: "ZeroChunkSize: chunk_size must be > 0 code points; got 0" })` | Zero-value constraint |
| TV-003 | `ChunkSize::new(100)` | `Ok(ChunkSize(100))` | Happy path — valid input |
| TV-004 | `DurabilityTier::from_str("turbo")` | `Err(FerrochainError { category: VAL, code: E-CORE-005, message: "Validation failed for 'durability_tier': 'turbo' is not a recognized tier" })` | Enum parse failure |
| TV-005 | `ApiKey::new("")` | `Err(FerrochainError { category: VAL, code: E-CORE-005, message: "Validation failed for 'api_key': value must not be empty" })` | Empty-string constraint |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DI014-01 | All public `Result`-returning fns with `VAL` errors return `Err`, never `Ok(None)` | Property test + code review | Phase 1 |
| VP-DI014-02 | No public function signature returns `Option<T>` for validation-failure signaling | Static analysis (clippy custom lint or grep) | Wave 0 CI |

## Related BCs

- BC-2.14.001 — FerrochainError 2D struct (composes with: defines the error type this BC returns)
- BC-2.14.003 — Constructor Result contract (depends on: all constructors return `Result`; this BC specifies category=VAL behavior)
- BC-2.14.005 — API key newtype (depends on: empty key string → `Err(VAL)`, not `None`)

## Architecture Anchors

- `ferrochain-core/src/errors.rs` — `FerrochainError` definition
- CI: clippy lint `option_for_validation_failure` (custom)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-DI014-01, VP-DI014-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (FerrochainError 2D Struct)") per capabilities-p0.md §CAP-016 — validation failure propagation is a first-class requirement of the error taxonomy contract; NE-03 (adk-rust silent None on validation) is named under CAP-016's grounding |
| L2 Domain Invariants | DI-014 (Error Propagation (No Silent Swallowing)) |
| NE References | NE-03 |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), CI lint |
| Module | ferrochain-core |
