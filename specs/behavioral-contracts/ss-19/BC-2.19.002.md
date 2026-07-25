---
document_type: behavioral-contract
level: L3
bc_id: BC-2.19.002
version: "1.1"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-19
capability: CAP-024
crate: ferrochain-core
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-20T00:00:00Z
di_anchors: [DI-008, DI-010]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-19 LC Serialization"
  - "1.1 (burst-227/F-P132-08/2026-07-21): Clarify serde field-name convention: lc_secrets() returns serde-serialized names (not Rust field names). Invariant 3 extended. TV-001 note updated: 'api_key field absent' → 'openai_api_key (serde-serialized name) absent from kwargs'."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-024
  - architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-010
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "0daa69f"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.19.002: lc_secrets() Credential Fields Stripped from kwargs Before Serialization and Constructor Dispatch

## Description

`LcSerializable::lc_secrets()` returns the field names of all credential and API key fields on
a type. Before the `kwargs` map is written into `Serialized::Constructor`, the serialization
path removes every field whose name appears in `lc_secrets()`. Symmetrically, `Reviver` strips
those same field names from `kwargs` before dispatching to the registered constructor — ensuring
that credential fields never transit the serialized envelope in either direction. Types without
secrets return an empty `lc_secrets()` slice and are unaffected. The stripping is unconditional;
no configuration knob overrides it (DI-010).

## Preconditions

1. The type `T` implements `LcSerializable` with `lc_secrets()` returning one or more field
   name strings (e.g., `&["openai_api_key", "anthropic_api_key"]`).
2. `T`'s `serialize()` method constructs `kwargs` from serde serialization of `&self`.
3. `Reviver::revive()` receives a `Serialized::Constructor` whose `kwargs` map may or may not
   contain the secret field names.

## Postconditions

1. `T::serialize(&self) → Serialized::Constructor { kwargs, ... }` — for every field name `s`
   in `T::lc_secrets()`, `kwargs.get(s)` returns `None`. The field is absent from the
   serialized output regardless of its value in `&self`.
2. `Reviver::revive(serialized)` — before dispatching to the registered constructor function,
   strips every field name listed in `T::lc_secrets()` from `kwargs`. The constructor receives
   a `kwargs` map containing no secret field names.
3. Types with `lc_secrets()` returning an empty slice are serialized and deserialized with no
   change — the stripping loop is a no-op.
4. The constructors for credential-bearing types accept `kwargs` without the credential fields
   and reconstruct those fields from environment variables or explicit injection, NOT from the
   serialized envelope. (The constructor convention is specified in ADR-016 Decision 3.)
5. `lc_secrets()` returns only field names; it never returns field values. No credential value
   is observable from the `LcSerializable` interface.

## Invariants

1. The stripping is **unconditional** — it applies even when the serialized form originates
   from a trusted internal source. There is no `unsafe_with_secrets()` escape hatch (DI-010).
2. The stripping is **idempotent** — stripping a `kwargs` map that already lacks the secret
   keys produces the same result.
3. `lc_secrets()` is a `&'static [&'static str]` — compile-time constant, no runtime mutation.
   The strings are **serde-serialized field names** (i.e., the name as it appears in the `kwargs`
   JSON map after any `#[serde(rename = ...)]` attribute), not the Rust source field names.
   Example: a Rust field `api_key` with `#[serde(rename = "openai_api_key")]` produces
   `lc_secrets() = &["openai_api_key"]`. The `kwargs` map always uses serde-serialized names;
   `lc_secrets()` stripping operates on those names.
4. After serialization, a `Debug` print of `Serialized::Constructor` never reveals a credential
   value because the field is absent from `kwargs` (DI-010 — credential opacity extends to the
   serialized form).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Type has `lc_secrets()` returning `[]` (no secrets) | Serialization includes all serde fields; stripping is a no-op; round-trip is unchanged |
| EC-002 | Attacker-crafted `Serialized::Constructor` includes a secret field name in kwargs | Reviver strips it before constructor dispatch; constructor does NOT receive the injected credential |
| EC-003 | Type has overlapping field names — a non-secret field happens to share a prefix with a secret field | Only exact string matches from `lc_secrets()` are stripped; prefix matches are not stripped |
| EC-004 | Type has multiple credential fields (e.g., both `api_key` and `api_secret`) | Both are stripped; `lc_secrets()` lists all of them |
| EC-005 | Deserialization with kwargs containing only non-secret fields | Constructor receives the complete non-secret kwargs; no error |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `OpenAiChatModel { api_key: ApiKey("sk-abc..."), model: "gpt-4o" }` → `serialize()` | `Serialized::Constructor { kwargs: {"model": "gpt-4o"} }` — `openai_api_key` (serde-serialized name of the `api_key` Rust field, via `#[serde(rename = "openai_api_key")]`) is absent from kwargs | happy-path (secret stripped) |
| TV-002 | `Serialized::Constructor { kwargs: {"model": "gpt-4o", "openai_api_key": "sk-injected"} }` → `Reviver::revive()` | Constructor dispatched with `kwargs = {"model": "gpt-4o"}` — injected key stripped | happy-path (reviver stripping) |
| TV-003 | Type with no `lc_secrets()` → serialize | All fields present in kwargs | happy-path (no-op stripping) |
| TV-004 | Type with 3 credential fields → serialize | All 3 absent from kwargs output | happy-path (multiple secrets) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.19.002-A | For every `T` where `lc_secrets()` is non-empty: for all instances `x` of `T`, the `kwargs` of `x.serialize()` contains no key from `lc_secrets()` | unit test — iterate over all registered types with non-empty lc_secrets; assert field absence |
| VP-2.19.002-B | Reviver strips injected secret fields before constructor dispatch for all registered credential-bearing types | unit test — inject a field in the kwargs of a crafted Serialized; assert constructor fn is not called with it |

## Related BCs

- BC-2.19.001 — composes with: the overall round-trip contract; credential stripping is a sub-behavior of the serialization path
- BC-2.19.003 — depends on: the Reviver registry dispatches constructors that must accept credential-stripped kwargs

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-19, `core::serializable` module
- `architecture/decisions/ADR-016-lc-json-deserialization-safety.md` — Decision 3 (credential stripping obligation, lc_secrets() contract, constructor convention for credential fields)
- `architecture/purity-boundary-map.md` — `ferrochain-core / core::serializable` Pure Core

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-19 story]_

## VP Anchors

- VP-2.19.002-A, VP-2.19.002-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-024 |
| Capability Anchor Justification | CAP-024 ("LcSerializable Round-Trip (Serialize → Serialized → Deserialize → Equivalent Value)") per capabilities-p1-p2.md §CAP-024 — credential stripping is a mandatory property of the round-trip: the Serialized envelope must never carry credential values, which CAP-024's safety property list identifies as a core constraint on the serialization surface |
| L2 Domain Invariants | DI-008 (serialize/revive return Result; no unwrap), DI-010 (credential opacity — credential values never transit AI context or serialized form; lc_secrets() stripping is the mechanism) |
| Architecture Authority | ADR-016 Decision 3 (lc_secrets() stripping obligation, constructor convention for credential injection) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-core / core::serializable |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (pure-core, no I/O) |
