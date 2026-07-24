---
document_type: behavioral-contract
level: L3
bc_id: BC-2.19.004
version: "1.0"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P2
subsystem: SS-19
capability: CAP-025
crate: ferrochain-core
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-20T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-19 LC Serialization"
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-025
  - architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "0b51533"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.19.004: Legacy Namespace Remap — OLD_CORE_NAMESPACES_MAPPING Aliases Resolve to Canonical Constructors

## Description

Serialized JSON artifacts produced by earlier versions of langchain-core (Python) used
namespace paths such as `["langchain", "prompts", "prompt", "PromptTemplate"]` (pre-split
namespace) in place of the current canonical `["langchain_core", "prompts", "prompt",
"PromptTemplate"]`. Ferrochain's `Reviver` maintains a static `OLD_CORE_NAMESPACES_MAPPING`
table that maps each legacy id to its canonical equivalent. When `revive()` receives an
`id` that matches a legacy alias, the alias is transparently remapped to the canonical id
before the registry lookup proceeds. The result is that legacy-namespace deserialization
succeeds without requiring the caller to pre-process the id.

## Preconditions

1. `Reviver` has been initialized (BC-2.19.003) and the canonical type is registered.
2. The `Serialized::Constructor` received by `revive()` has an `id` field that matches a key
   in `OLD_CORE_NAMESPACES_MAPPING` (e.g., `["langchain", "prompts", "prompt", "PromptTemplate"]`).
3. The canonical type for the alias is present in the registry.

## Postconditions

1. `Reviver::revive(serialized)` transparently remaps the legacy `id` to the canonical id
   before registry lookup. The caller does NOT need to call any remap function explicitly.
2. The deserialized value is identical to what would have been produced by a canonical-id
   `Serialized::Constructor` with the same `kwargs`.
3. If the canonical type is registered but the legacy alias is NOT in `OLD_CORE_NAMESPACES_MAPPING`,
   the legacy id is treated as unknown and returns `Err(E-SRLZ-001)`. The remap table is the
   authoritative list of supported aliases.
4. `OLD_CORE_NAMESPACES_MAPPING` is a compile-time `static` — no entries are added at runtime.
5. After remapping, the returned deserialized value carries the type's canonical `lc_id()`, not
   the legacy alias id.

## Invariants

1. The remap is **transparent to the caller** — the caller does not observe the remapping;
   it only observes the deserialized value.
2. The remap table is a compile-time constant — it cannot be extended without a code change
   and rebuild. This is intentional: runtime-mutable remap tables would create a
   dynamic-injection vector.
3. Remap chains are not supported — if a legacy alias maps to another alias (which would then
   need further remapping), this is a programming error caught at startup via a remap-chain
   validation check.
4. Every entry in `OLD_CORE_NAMESPACES_MAPPING` must map to an id that resolves in the registry;
   if the canonical id is not registered, revive still returns `Err(E-SRLZ-001)`.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | id is already canonical (no remap needed) | Remap lookup is a no-op; canonical lookup proceeds directly |
| EC-002 | Legacy id is in the remap table but the canonical type is not registered | `Err(E-SRLZ-001)` — remap found, canonical lookup failed; error message includes the canonical id |
| EC-003 | Legacy id is NOT in the remap table and NOT in the registry | `Err(E-SRLZ-001)` — treated as unknown type (same as BC-2.19.005's gate) |
| EC-004 | Two distinct legacy aliases map to the same canonical id | Both deserialize to the same type; both succeed if the canonical type is registered |
| EC-005 | `OLD_CORE_NAMESPACES_MAPPING` contains a remap-chain (A → B → C) | Startup validation panics with `RemapChainDetected` — caught in CI; not a production runtime path |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `Serialized::Constructor { id: ["langchain", "prompts", "prompt", "PromptTemplate"], kwargs: {"template": "Hello {name}"} }` → `revive()` | `Ok(PromptTemplate { template: "Hello {name}" })` — legacy id remapped to canonical | happy-path (legacy alias) |
| TV-002 | `Serialized::Constructor { id: ["langchain_core", "prompts", "prompt", "PromptTemplate"], kwargs: {"template": "Hi {x}"} }` → `revive()` | `Ok(PromptTemplate { template: "Hi {x}" })` — canonical id, no remap | happy-path (canonical, no remap) |
| TV-003 | `Serialized::Constructor { id: ["langchain", "nonexistent", "Type"], kwargs: {} }` → `revive()` | `Err(FerrochainError { code: "E-SRLZ-001" })` — not in remap table and not in registry | error-case (unknown legacy id) |
| TV-004 | `Serialized::Constructor { id: ["langchain", "schema", "messages", "SystemMessage"], kwargs: {"content": "Be helpful."} }` → `revive()` | `Ok(SystemMessage { content: "Be helpful." })` — legacy SystemMessage namespace remapped | happy-path (message type legacy alias) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.19.004-A | For every entry `(legacy_id, canonical_id)` in `OLD_CORE_NAMESPACES_MAPPING`, `revive(Constructor { id: legacy_id, kwargs })` produces the same result as `revive(Constructor { id: canonical_id, kwargs })` | unit test — pair-wise comparison for all remap entries |
| VP-2.19.004-B | The remap table has no remap chains — all canonical ids resolve directly in the registry | startup validation test (runs in CI) |

## Related BCs

- BC-2.19.001 — composes with: round-trip uses canonical ids; legacy remap ensures import of legacy-serialized data succeeds
- BC-2.19.003 — depends on: the Reviver registry must be initialized before the remap lookup can proceed
- BC-2.19.005 — composes with: after remap, the allowlist containment check applies to the canonical id (not the legacy id)

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-19, `core::serializable::legacy_remap` sub-module
- `architecture/decisions/ADR-016-lc-json-deserialization-safety.md` — Decision 5 (OLD_CORE_NAMESPACES_MAPPING, remap-before-lookup, remap-chain validation)

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-19 story]_

## VP Anchors

- VP-2.19.004-A, VP-2.19.004-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-025 |
| Capability Anchor Justification | CAP-025 ("Reviver and Type Registry (Inventory-Based; Allowlist Containment; Legacy-Namespace Remap)") per capabilities-p1-p2.md §CAP-025 — this BC specifies the Legacy-Namespace Remap behavior that CAP-025 names explicitly as one of the three defining capabilities of the Reviver subsystem |
| L2 Domain Invariants | DI-008 (revive returns Result; no panic on remap lookup) |
| Architecture Authority | ADR-016 Decision 5 (OLD_CORE_NAMESPACES_MAPPING, compile-time-constant remap, remap-chain validation, remap-then-registry-lookup ordering) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-core / core::serializable::legacy_remap |
| Priority | P2 |
| Wave | 2 |
| Test Types | unit (pure-core, compile-time constants) |
