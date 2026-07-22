---
document_type: behavioral-contract
level: L3
bc_id: BC-2.19.001
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
timestamp: 2026-07-21T00:00:00Z
di_anchors: [DI-008]
vp_seed: true
vp_id: VP-007
changelog:
  - "1.1 (burst-222/2026-07-21): VP-007 proptest seed assigned. BC-2.19.001 is the round-trip contract (serialize→Serialized::Constructor→Reviver::revive→semantically-equivalent value) that VP-007 will verify via property-based testing. Assignment rationale: H1 title contains 'Round-Trip' explicitly and postcondition 3 specifies the semantic equivalence invariant that proptest exercises. Architect to author VP-007 body in Phase 6."
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-19 LC Serialization"
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-024
  - architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "380e5ee"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.19.001: LcSerializable Round-Trip — Serialize to Serialized::Constructor, Deserialize to Semantically Equivalent Value

## Description

Any type implementing `LcSerializable` can be serialized to a `Serialized::Constructor` JSON
envelope (`{ type: "constructor", lc: 1, id: Vec<String>, kwargs: Map<String, Value> }`) and
deserialized back via `Reviver` to produce a value semantically equivalent to the original.
The round-trip invariant — `deserialize(serialize(x)) ≡ x` — holds for all 141 core-registered
types. Credential fields listed in `lc_secrets()` are excluded from `kwargs` at serialization
time and stripped before constructor dispatch at deserialization time (DI-010, specified in
BC-2.19.002). `LcSerializable::is_lc_serializable()` returns `false` for opt-out types; no
serialization is attempted and `Serialized::NotImplemented` is produced instead.

## Preconditions

1. The type `T` implements `LcSerializable` with `is_lc_serializable() → true`.
2. `T::lc_id()` returns a non-empty `&'static [&'static str]` namespace path (e.g.,
   `["langchain_core", "prompts", "prompt", "PromptTemplate"]`).
3. `T` is registered in the inventory via `inventory::submit! { LcEntry { lc_id: T::lc_id(), constructor: ... } }`.
4. The `Reviver`'s internal registry (built at startup from `inventory::iter::<LcEntry>()`)
   contains an entry whose `lc_id` matches `T::lc_id()`.

## Postconditions

1. `T::serialize(&self) → Serialized` returns
   `Serialized::Constructor { lc: 1, id: T::lc_id().to_vec(), kwargs }` where `kwargs` is a
   `serde_json::Map` containing all serde-serializable fields EXCEPT those listed in
   `lc_secrets()`.
2. `Reviver::revive(serialized: Serialized) → Result<Box<dyn Any + Send + Sync>, FerrochainError>`
   returns `Ok(boxed_value)` when the `id` is registered and kwargs are valid.
3. The deserialized value `v` satisfies `v ≡ original` under the type's semantic equivalence
   relation (field-by-field equality for types that derive PartialEq; documented equivalence
   for types with custom equality).
4. `is_lc_serializable() → false` types produce `Serialized::NotImplemented { lc: 1,
   id: T::lc_id().to_vec(), repr: None }` from `serialize()` and return `Err(E-SRLZ-001)`
   from `Reviver::revive()` (opt-out type not in registry).

## Invariants

1. Round-trip produces a semantically equivalent value — not necessarily the identical memory
   representation (e.g., `PromptTemplate` with equal fields is semantically equivalent).
2. `lc: 1` is a protocol version marker; ferrochain v1 always produces and accepts `lc: 1`.
3. The `id` field preserves the namespace path exactly as returned by `T::lc_id()` — no
   normalization or case folding.
4. Round-trip is deterministic: calling serialize→deserialize twice on the same value produces
   the same result (no random state, no timestamp injection into kwargs).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Type with `is_lc_serializable() → false` | `serialize()` returns `Serialized::NotImplemented`; `revive()` returns `Err(E-SRLZ-001)` |
| EC-002 | Type has `lc_secrets()` returning non-empty list | Serialization succeeds; secret fields absent from kwargs; deserialization reconstructs via DI constructor (BC-2.19.002) |
| EC-003 | Type has `lc_attributes()` returning additional metadata | `kwargs` includes both serde fields and lc_attributes entries; round-trip preserves the additional attributes |
| EC-004 | Round-trip with a type that has optional fields set to `None` | `kwargs` omits `None`-valued optional fields (standard serde behavior); deserialization reconstructs with `None` defaults |
| EC-005 | Type registered under multiple legacy aliases (alias multiplicity) | Any alias id deserializes to the same value; the canonical serialize() output uses the canonical `lc_id()` |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `PromptTemplate { template: "Hello {name}", partial_vars: {} }` → `serialize()` | `Serialized::Constructor { lc: 1, id: ["langchain_core", "prompts", "prompt", "PromptTemplate"], kwargs: {"template": "Hello {name}", "input_variables": ["name"]} }` | happy-path |
| TV-002 | TV-001 `Serialized` → `Reviver::revive()` | `Ok(PromptTemplate { template: "Hello {name}", input_variables: ["name"] })` — semantically equivalent to original | happy-path (round-trip) |
| TV-003 | Type with `is_lc_serializable() → false` → `serialize()` | `Serialized::NotImplemented { lc: 1, id: [...], repr: None }` | edge-case (opt-out type) |
| TV-004 | `SystemMessage { content: "Be helpful." }` → serialize → revive | Round-trip produces `SystemMessage { content: "Be helpful." }` | happy-path (message round-trip) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.19.001-A | For all registered types T, `revive(serialize(x)) ≡ x` (semantic equivalence) | unit test — one per registered core type; snapshot test |
| VP-2.19.001-B | `serialize()` output `id` field always equals `T::lc_id().to_vec()` — no truncation or mutation | unit test — identity assertion |

## Related BCs

- BC-2.19.002 — composes with: lc_secrets() stripping is part of the serialize path this BC specifies; see BC-2.19.002 for the stripping contract
- BC-2.19.003 — depends on: round-trip requires a registered type; BC-2.19.003 specifies registry registration
- BC-2.19.005 — depends on: Reviver allowlist containment (BC-2.19.005) is the gate that permits BC-2.19.001's `revive()` postcondition to hold

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-19, `core::serializable` module
- `architecture/decisions/ADR-016-lc-json-deserialization-safety.md` — Decision 2 (`LcSerializable` trait definition, `Serialized` enum, `LcEntry` struct)
- `architecture/purity-boundary-map.md` — `ferrochain-core / core::serializable` Pure Core classification

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-19 story]_

## VP Anchors

- VP-2.19.001-A, VP-2.19.001-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-024 |
| Capability Anchor Justification | CAP-024 ("LcSerializable Round-Trip (Serialize → Serialized → Deserialize → Equivalent Value)") per capabilities-p1-p2.md §CAP-024 — this BC specifies the serialize→Serialized::Constructor→deserialize→equivalent-value behavioral contract including the opt-out type handling that CAP-024 identifies as the core lc-JSON round-trip obligation |
| L2 Domain Invariants | DI-008 (LcSerializable and Reviver constructors return Result; no .unwrap() in non-test code) |
| Architecture Authority | ADR-016 Decisions 1 and 2 (crate placement core::serializable, LcSerializable trait, Serialized enum, LcEntry struct) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-core / core::serializable |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit + snapshot (pure-core) |
