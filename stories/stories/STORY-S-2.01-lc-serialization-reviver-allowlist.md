---
document_type: story
level: ops
story_id: S-2.01
epic_id: E-15
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-19T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-19/BC-2.19.001.md
  - .factory/specs/behavioral-contracts/ss-19/BC-2.19.002.md
  - .factory/specs/behavioral-contracts/ss-19/BC-2.19.003.md
  - .factory/specs/behavioral-contracts/ss-19/BC-2.19.004.md
  - .factory/specs/behavioral-contracts/ss-19/BC-2.19.005.md
  - .factory/specs/behavioral-contracts/ss-19/BC-2.19.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "3a6439a"
traces_to: .factory/stories/STORY-INDEX.md
points: 13
depends_on: [S-1.04, S-1.02]
blocks: [S-6.01]
behavioral_contracts: [BC-2.19.001, BC-2.19.002, BC-2.19.003, BC-2.19.004, BC-2.19.005, BC-2.19.006]
verification_properties: [VP-007, VP-010]
priority: P0
cycle: v1.0.0-greenfield
wave: 2
target_module: pregolya-core
subsystems: [SS-19]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-2.01: LC Serialization Round-Trip, Inventory Registry and Reviver Allowlist Security

## Narrative

- **As a** pregolya library user who needs to persist and reload LLM pipeline components
- **I want to** serialize any `LcSerializable` type to a `Serialized::Constructor` envelope and revive it back to a semantically equivalent value
- **So that** graph checkpoints, prompt templates, and retrieval components can be durably stored and rehydrated while credential fields are never serialized and unknown type ids are always rejected

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.19.001 | LcSerializable Round-Trip — Serialize to Serialized::Constructor, Deserialize to Semantically Equivalent Value | P1 |
| BC-2.19.002 | lc_secrets() Credential Fields Stripped from kwargs Before Serialization and Constructor Dispatch | P1 |
| BC-2.19.003 | Inventory-Based Type Registry — Link-Time Registration, Feature-Gated Partner Entries, OnceLock Allowlist | P1 |
| BC-2.19.004 | Legacy Namespace Remap — OLD_CORE_NAMESPACES_MAPPING Aliases Resolve to Canonical Constructors | P2 |
| BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed, VP-010 Kani Candidate) | P0 |
| BC-2.19.006 | Langchain-Monolith Type Ids Return E-SRLZ-002 (Structured Error, Not Silent None or E-SRLZ-001) | P1 |

## Acceptance Criteria

### AC-001 (traces to BC-2.19.001 postcondition 1)
`LcSerializable::serialize(&self) -> Serialized` returns
`Serialized::Constructor { lc: 1, id: T::lc_id().to_vec(), kwargs }` where `kwargs` is a
`serde_json::Map` containing all serde-serializable fields EXCEPT those listed in
`lc_secrets()`. Verified by `test_BC_2_19_001_serialize_produces_constructor_envelope()`.

### AC-002 (traces to BC-2.19.001 postcondition 2)
`Reviver::revive(serialized: Serialized) -> Result<Box<dyn Any + Send + Sync>, PregolyaError>`
returns `Ok(boxed_value)` when the `id` is registered and kwargs are valid.
Verified by `test_BC_2_19_001_reviver_revive_registered_type_ok()`.

### AC-003 (traces to BC-2.19.001 postcondition 3)
The deserialized value `v` satisfies `v ≡ original` under field-by-field equality for types
that derive `PartialEq`. A `PromptTemplate { template: "Hello {name}", input_variables: ["name"] }`
round-trips to an equivalent value. Verified by `test_BC_2_19_001_round_trip_semantic_equivalence()`.

### AC-004 (traces to BC-2.19.001 postcondition 4)
`is_lc_serializable() -> false` types produce `Serialized::NotImplemented { lc: 1, id: T::lc_id().to_vec(), repr: None }`
from `serialize()` and return `Err(E-SRLZ-001)` from `Reviver::revive()`.
Verified by `test_BC_2_19_001_opt_out_type_not_implemented()`.

### AC-005 (traces to BC-2.19.001 invariant 4)
Round-trip is deterministic: calling serialize → revive twice on the same value produces
the same result. Verified by `test_BC_2_19_001_round_trip_deterministic()`.

### AC-006 (traces to BC-2.19.002 postcondition 1)
For every field name `s` in `T::lc_secrets()`, `kwargs.get(s)` returns `None` in the
`Serialized::Constructor` output of `T::serialize(&self)`. `OpenAiChatModel { api_key, model }` →
`kwargs` has `"model"` but NOT `"openai_api_key"`. Verified by `test_BC_2_19_002_secret_stripped_on_serialize()`.

### AC-007 (traces to BC-2.19.002 postcondition 2)
`Reviver::revive(serialized)` strips every field name listed in `T::lc_secrets()` from `kwargs`
before dispatching to the registered constructor. An attacker-crafted `Serialized::Constructor`
with an injected `"openai_api_key"` field is stripped before constructor dispatch.
Verified by `test_BC_2_19_002_secret_stripped_on_revive()`.

### AC-008 (traces to BC-2.19.002 invariant 1)
The stripping is unconditional — it fires even when the serialized form originates from a
trusted internal source. There is no `unsafe_with_secrets()` or equivalent escape hatch.
Verified by `test_BC_2_19_002_stripping_unconditional()` by constructing a serialized value
without injected secrets and asserting the same result.

### AC-009 (traces to BC-2.19.003 postcondition 2)
`Reviver::new()` returns a `Reviver` instance backed by a `HashMap` containing exactly the
entries produced by `inventory::iter::<LcEntry>()`. No entries are added at runtime.
Verified by `test_BC_2_19_003_reviver_new_infallible_and_backed_by_inventory()`.

### AC-010 (traces to BC-2.19.003 postcondition 5)
`Reviver::registry_size() -> usize` returns the count of registered entries. In a binary
with only core features, `reviver.registry_size() == LANGCHAIN_CORE_REGISTRY.len()`.
Verified by `test_BC_2_19_003_registry_size_equals_core_registry_constant()`.

### AC-011 (traces to BC-2.19.003 postcondition 3)
The `OnceLock` ensures the registry is initialized at most once per process. Calling
`Reviver::new()` three times in sequence returns the same `registry_size()` each time.
Verified by `test_BC_2_19_003_reviver_new_idempotent_onceLock()`.

### AC-012 (traces to BC-2.19.003 invariant 1)
The registry is append-only at link time. No runtime API adds or removes entries from
the `OnceLock<HashMap>` after initialization. Verified by `test_BC_2_19_003_registry_append_only_no_runtime_mutation()`.

### AC-013 (traces to BC-2.19.004 postcondition 1)
`Reviver::revive(serialized)` transparently remaps a legacy id to the canonical id before
registry lookup. `Serialized::Constructor { id: ["langchain", "prompts", "prompt", "PromptTemplate"], kwargs }` → `Ok(PromptTemplate { ... })` without caller pre-processing.
Verified by `test_BC_2_19_004_legacy_alias_remapped_transparently()`.

### AC-014 (traces to BC-2.19.004 postcondition 3)
A legacy id NOT in `OLD_CORE_NAMESPACES_MAPPING` is treated as unknown and returns
`Err(E-SRLZ-001)`. Verified by `test_BC_2_19_004_unknown_legacy_id_returns_e_srlz_001()`.

### AC-015 (traces to BC-2.19.004 invariant 3 — startup validation)
Remap chains are not supported. A startup validation unit test asserts that no key in
`OLD_CORE_NAMESPACES_MAPPING` maps to a value that is also a key in the table.
Verified by `test_BC_2_19_004_no_remap_chains_in_mapping()`.

### AC-016 (traces to BC-2.19.005 postcondition 1 — Red Gate)
**RED GATE**: This test must COMPILE and FAIL before `Reviver::revive()` is implemented.
`Reviver::revive(Serialized::Constructor { id: ["attacker_custom", "Exploit"], kwargs: {"cmd": "rm -rf /"} })` returns
`Err(PregolyaError { code: "E-SRLZ-001", message: "unknown-serializable: type id not in registry", .. })`.
Verified by `test_BC_2_19_005_unknown_id_returns_e_srlz_001_rg()`.

### AC-017 (traces to BC-2.19.005 postcondition 2)
No constructor is called; no `kwargs` map is parsed; no heap allocation occurs on the
failure path beyond the error struct itself. The allowlist check fires BEFORE any dispatch.
Verified by `test_BC_2_19_005_allowlist_first_no_constructor_dispatch()` using a mock constructor that panics if called.

### AC-018 (traces to BC-2.19.005 postcondition 4 — Red Gate)
**RED GATE**: `Serialized::NotImplemented` and `Serialized::Secret` variants with an
unregistered id also return `Err(E-SRLZ-001)`. Verified by
`test_BC_2_19_005_not_implemented_variant_also_gated_rg()`.

### AC-019 (traces to BC-2.19.005 invariant 1)
The allowlist check is the FIRST operation in `revive()` — it cannot be reordered below
any other check or transformation. Verified by structural code review assertion in
`test_BC_2_19_005_allowlist_check_first_operation()` using a code-inspection test that
verifies registry lookup precedes serde calls.

### AC-020 (traces to BC-2.19.005 invariant 4)
The `E-SRLZ-001` message text is fixed (`"unknown-serializable: type id not in registry"`) —
it does NOT include the received id. Verified by `test_BC_2_19_005_error_message_no_id_interpolation()`.

### AC-021 (traces to BC-2.19.006 postcondition 1)
`Reviver::revive(Serialized::Constructor { id: ["langchain", "chains", "llm", "LLMChain"], kwargs: {} })` returns
`Err(PregolyaError { code: "E-SRLZ-002", message: "unsupported-serializable: langchain-monolith type not ported to pregolya", .. })`.
Verified by `test_BC_2_19_006_monolith_type_returns_e_srlz_002()`.

### AC-022 (traces to BC-2.19.006 postcondition 4 — check ordering)
The check ordering within `revive()` is: registry lookup → legacy remap → monolith check →
E-SRLZ-001 fallthrough. A type registered in both registry and `LANGCHAIN_MONOLITH_TYPES`
(programming error) returns `Ok(...)` (registry wins). Verified by
`test_BC_2_19_006_check_ordering_registry_before_monolith()`.

### AC-023 (traces to BC-2.19.006 invariant 4)
`LANGCHAIN_MONOLITH_TYPES` and the registry are disjoint at startup. A startup validation
unit test asserts no entry in `LANGCHAIN_MONOLITH_TYPES` appears in the registry.
Verified by `test_BC_2_19_006_monolith_and_registry_disjoint()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `LcSerializable` trait, `Serialized` enum, `LcEntry` struct | `pregolya-core/src/serializable/traits.rs` | pure-core |
| `LcEntry` registry + OnceLock init + `registry_size` | `pregolya-core/src/serializable/registry.rs` | pure-core (link-time init) |
| `Reviver` struct + `revive()` + allowlist check + monolith check | `pregolya-core/src/serializable/reviver.rs` | pure-core |
| `OLD_CORE_NAMESPACES_MAPPING` static table | `pregolya-core/src/serializable/legacy_remap.rs` | pure-core |
| `LANGCHAIN_MONOLITH_TYPES` static set | `pregolya-core/src/serializable/monolith.rs` | pure-core |
| Module root (re-export-only) | `pregolya-core/src/serializable/mod.rs` | re-export-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/serializable/traits.rs` | pure-core | Trait + type definitions only; no I/O. |
| `pregolya-core/src/serializable/registry.rs` | pure-core | `OnceLock` init is link-time determinism; no I/O. |
| `pregolya-core/src/serializable/reviver.rs` | pure-core | HashMap lookup and serde deserialization; no I/O, no async. VP-010 Kani candidacy grounded here. |
| `pregolya-core/src/serializable/legacy_remap.rs` | pure-core | Compile-time static table. |
| `pregolya-core/src/serializable/monolith.rs` | pure-core | Compile-time static set. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Opt-out type (`is_lc_serializable() = false`) revived | `Err(E-SRLZ-001)` — not in registry |
| EC-002 | Empty id Vec (`id: []`) sent to revive() | `Err(E-SRLZ-001)` — no fuzzy matching |
| EC-003 | lc_secrets() returns `[]` (no secrets) | Stripping is a no-op; round-trip unaffected |
| EC-004 | Multiple credential fields listed in lc_secrets() | All stripped independently; no partial stripping |
| EC-005 | Legacy id NOT in OLD_CORE_NAMESPACES_MAPPING | Returns E-SRLZ-001 — unknown type |
| EC-006 | Remap chain (A→B→C) in OLD_CORE_NAMESPACES_MAPPING | Caught by startup validation test; no panic at runtime |
| EC-007 | Monolith type also registered in the registry | Registry wins (step a before step c); Ok returned |
| EC-008 | Very long id Vec (attacker sends 1000-element path) | HashMap lookup returns not-found; E-SRLZ-001; no DoS |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~5,500 |
| BC files (6 BCs) | ~18,000 |
| `module-decomposition.md` (SS-19 section) | ~600 |
| `ADR-016-lc-json-deserialization-safety.md` | ~2,000 |
| `serializable/` module files (~80 lines each × 5 files) | ~3,500 |
| Test file (~200 lines) | ~3,000 |
| Tool outputs | ~600 |
| **Total** | **~33,200** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~17%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-023 (test-writer); verify Red Gate (AC-016, AC-018 must FAIL before implementation)
2. [ ] Verify Red Gate density ≥ 0.5
3. [ ] Create `pregolya-core/src/serializable/traits.rs` — `LcSerializable` trait, `Serialized` enum, `LcEntry` struct
4. [ ] Create `pregolya-core/src/serializable/registry.rs` — `inventory::submit!` macro, `OnceLock<HashMap>`, `LANGCHAIN_CORE_REGISTRY` constant, `registry_size()`
5. [ ] Create `pregolya-core/src/serializable/legacy_remap.rs` — `OLD_CORE_NAMESPACES_MAPPING` static map
6. [ ] Create `pregolya-core/src/serializable/monolith.rs` — `LANGCHAIN_MONOLITH_TYPES` static set
7. [ ] Create `pregolya-core/src/serializable/reviver.rs` — `Reviver::new()` (infallible), `Reviver::revive()` (allowlist first, legacy remap, monolith check, constructor dispatch), credential stripping
8. [ ] Create `pregolya-core/src/serializable/mod.rs` — re-exports only
9. [ ] Add `pub mod serializable;` to `pregolya-core/src/lib.rs`
10. [ ] Register `inventory` crate in `pregolya-core/Cargo.toml`
11. [ ] Add startup validation test for remap-chain absence (AC-015) and monolith-registry disjoint (AC-023)
12. [ ] Create `crates/pregolya-core/src/proofs/reviver_allowlist.rs` — `#[cfg(kani)]` `allowlist_rejects_unregistered_id` stub (body `todo!()` for Phase 6 formal hardening; VP-010)
13. [ ] Run `cargo nextest run -p pregolya-core` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-1.04 established `Runnable` trait and `DynRunnable` using `serde_json::Value` as the wire format. The `kwargs` in `Serialized::Constructor` is also a `serde_json::Map<String, Value>` — the same serde-json dependency is already present in pregolya-core from S-1.04.

S-1.02 established error machinery: `PregolyaError::new(Component::Srlz, Category::Val, RetryHint::Never, "E-SRLZ-001", msg)` and `E-SRLZ-002` must be present in the error taxonomy (`prd-supplements/error-taxonomy.md §Component: SRLZ`).

The `inventory` crate (dtolnay) is a new dependency for this story. Add to `pregolya-core/Cargo.toml`. Note: `inventory::submit!` macros are collected at link time via weak symbols; the pattern is `inventory::collect!(LcEntry)` in `registry.rs` plus `inventory::submit! { LcEntry { ... } }` at each registration site.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `serializable/mod.rs` is re-export-only | CLAUDE.md Code Conventions | Code review |
| `Reviver::new()` is infallible (no `Result` return) | BC-2.19.003 postcondition 2; DI-008 corrected | Type signature inspection |
| `Reviver::revive()` is the ONLY fallible operation in the serialization path | BC-2.19.001 postcondition 2; DI-008 | Type signatures; no `?` in `serialize()` |
| Allowlist check is the FIRST operation in `revive()` | BC-2.19.005 invariant 1 | Code review; structural test AC-019 |
| `lc_secrets()` returns serde-serialized field names (not Rust field names) | BC-2.19.002 invariant 3 | Test with `#[serde(rename = ...)]` type |
| E-SRLZ-001 message does NOT interpolate the received id | BC-2.19.005 invariant 4 (gate #33 STRUCT-PLACEHOLDER PARITY) | Test AC-020 |
| E-SRLZ-002 message does NOT interpolate the type id | BC-2.19.006 invariant 3 | Unit test |
| No `ndarray`, no BLAS, no I/O in `core::serializable` | Architecture purity boundary | Dependency audit |
| Component::Srlz (PascalCase) not Component::SRLZ | ADR-010 PascalCase canon | Code review |

**Forbidden dependencies for `pregolya-core/src/serializable/`:** No tokio import. No reqwest. No file I/O. The entire subsystem is pure-core.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `inventory` | workspace pin (dtolnay) | Link-time type registration via `submit!` / `iter` |
| `serde_json` | workspace pin | `serde_json::Map<String, Value>` as kwargs type |
| `serde` | workspace pin | Derive macros for `LcSerializable` impls |
| `std::sync::OnceLock` | std (Rust stable) | Single-init registry backing store |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/serializable/mod.rs` | CREATE | Re-export-only module root |
| `pregolya-core/src/serializable/traits.rs` | CREATE | `LcSerializable` trait, `Serialized` enum, `LcEntry` struct |
| `pregolya-core/src/serializable/registry.rs` | CREATE | OnceLock registry init, `LANGCHAIN_CORE_REGISTRY` constant, `registry_size()` |
| `pregolya-core/src/serializable/legacy_remap.rs` | CREATE | `OLD_CORE_NAMESPACES_MAPPING` static map |
| `pregolya-core/src/serializable/monolith.rs` | CREATE | `LANGCHAIN_MONOLITH_TYPES` static set |
| `pregolya-core/src/serializable/reviver.rs` | CREATE | `Reviver` struct, `new()`, `revive()`, allowlist check, credential stripping |
| `pregolya-core/src/proofs/reviver_allowlist.rs` | CREATE | VP-010 Kani harness stub — `allowlist_rejects_unregistered_id` (body `todo!()` for Phase 6) |
| `pregolya-core/src/lib.rs` | MODIFY | Add `pub mod serializable;` |
| `pregolya-core/Cargo.toml` | MODIFY | Add `inventory` dependency |
| `pregolya-core/tests/serializable_integration.rs` | CREATE | Feature-flag integration tests (BC-2.19.003 TV-002 pattern) |
