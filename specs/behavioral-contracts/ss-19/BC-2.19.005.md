---
document_type: behavioral-contract
level: L3
bc_id: BC-2.19.005
version: "1.1"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-19
capability: CAP-025
crate: ferrochain-core
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
di_anchors: [DI-008, DI-014]
red_gate: true
red_gate_source: "ADR-016 Security Invariant — Reviver must reject unknown type ids at all times; allowlist test must COMPILE and FAIL before Reviver::revive() is implemented; VP-010 Kani candidate"
vp_seed: true
vp_id: VP-010
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-19 LC Serialization; SECURITY-CRITICAL"
  - "1.1 (F-P224/F-P129-01+F-P129-04/2026-07-21): (1) F-P129-01: PC1 and Invariant 3 corrected — Category::SECURITY → Category::VAL per ADR-010 §SRLZ adjudication (error-taxonomy.md line 279 already recorded E-SRLZ-001 as VAL; this BC was out of sync). Invariant 3 rationale rewritten: deserialization containment is input validation against the registry, not an attack-vector boundary event. (2) F-P129-04: VP-2.19.005-A restated to scope non-monolith unregistered ids only and add joint coverage note with BC-2.19.006/VP-010."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-025
  - architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "cbd45f7"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.19.005: Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed, VP-010 Kani Candidate)

> **Red Gate test required** — ADR-016 Security Invariant: the allowlist-containment test
> must COMPILE and FAIL before `Reviver::revive()` is implemented. VP-010 Kani candidate:
> prove that for ALL possible `Serialized` inputs, if the `id` is not in the registry,
> the result is ALWAYS `Err(E-SRLZ-001)` — no code path produces `Ok(...)` for an
> unregistered id.

## Description

`Reviver::revive()` performs an allowlist check as the FIRST step of deserialization —
before any constructor dispatch, kwargs parsing, or type coercion. If the `id` field of
the `Serialized::Constructor` does not appear in the registry (after legacy-namespace remap
per BC-2.19.004), `revive()` immediately returns
`Err(FerrochainError { code: "E-SRLZ-001" })`. There is no fallback, no partial construction,
and no type coercion that can bypass this check. This is the primary defense against
deserialization of arbitrary user-controlled type ids. The property is Kani-verifiable
because `Reviver::revive()` is pure-core (no I/O, no async) and the registry is a
`OnceLock<HashMap>` with a fixed set of entries at initialization time.

## Preconditions

1. `Reviver` has been initialized (BC-2.19.003); the registry is populated and the
   `OnceLock` is set.
2. `revive()` receives a `Serialized` value — either `Serialized::Constructor`,
   `Serialized::Secret`, or `Serialized::NotImplemented`.
3. The `id` field of the input is NOT present in the registry (after legacy remap lookup).

## Postconditions

1. `Reviver::revive(serialized)` returns:
   ```
   Err(FerrochainError {
       component: Component::SRLZ,
       category: Category::VAL,
       code: "E-SRLZ-001",
       message: "unknown-serializable: type id not in registry",
   })
   ```
2. No constructor is called; no `kwargs` map is parsed; no heap allocation occurs on the
   failure path beyond the error struct itself.
3. The error propagates via `?` to the caller; it is not swallowed or converted within
   `core::serializable` (DI-014).
4. `Serialized::Secret` and `Serialized::NotImplemented` variants also return `Err(E-SRLZ-001)`
   when their `id` is unregistered (they carry no `kwargs` but still require a registry check).
5. Any `Serialized::Constructor` whose `id` matches a registered entry proceeds to constructor
   dispatch (covered by BC-2.19.001, BC-2.19.004).

## Invariants

1. The allowlist check is the **first operation** in `revive()` — it cannot be reordered
   below any other check or transformation.
2. The check uses the same `HashMap` that was populated at startup (BC-2.19.003) —
   no secondary list, no `allow_all` flag, no runtime override.
3. `category: Category::VAL` — the allowlist check validates the `id` field of the
   deserialized input against the registry. An unregistered type id is a validation
   failure: the input does not conform to the allowed inventory. The `SECURITY` category
   is reserved for errors guarding concrete attack-vector boundaries per ADR-010 taxonomy
   membership rules (E-SBXD-001 workspace escape, E-GRAPH-013 approver-role gate,
   E-MEMORY-007 write injection, E-TMPL-001 prompt injection). Deserialization containment
   enforced by registry lookup is input validation, not a boundary-crossing attack-vector
   event. This adjudication is recorded in error-taxonomy.md v1.28 (E-SRLZ-001 row: VAL).
4. The `E-SRLZ-001` message text is fixed (`"unknown-serializable: type id not in registry"`);
   it does NOT include the received id in the message to avoid leaking attacker-controlled
   data into structured logs (gate #33 STRUCT-PLACEHOLDER PARITY: the message format has
   no `<placeholder>` because the id must not be interpolated).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `id` is an empty Vec (attacker sends `id: []`) | `Err(E-SRLZ-001)` — empty Vec is not in registry |
| EC-002 | `id` is a single-element Vec with a plausible-sounding name not in registry | `Err(E-SRLZ-001)` — no fuzzy matching, no prefix matching |
| EC-003 | `id` matches a legacy alias in `OLD_CORE_NAMESPACES_MAPPING` whose canonical is registered | Remap succeeds; canonical lookup succeeds; `Ok(value)` — NOT an E-SRLZ-001 case (remap resolved it) |
| EC-004 | `id` matches a legacy alias in `OLD_CORE_NAMESPACES_MAPPING` whose canonical is NOT registered | `Err(E-SRLZ-001)` — remap found the alias but canonical lookup failed |
| EC-005 | `Serialized::NotImplemented` with unknown id | `Err(E-SRLZ-001)` — same allowlist check applies |
| EC-006 | Very long `id` Vec (attacker sends 1000-element id path) | `Err(E-SRLZ-001)` — HashMap lookup on Vec<String>; returns Not-Found; no DoS vector from list traversal |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 (Red Gate) | `Reviver::revive(Serialized::Constructor { id: ["attacker_custom", "Exploit"], kwargs: {"cmd": "rm -rf /"} })` | `Err(FerrochainError { code: "E-SRLZ-001", message: "unknown-serializable: type id not in registry" })` | error-case (unknown id) |
| TV-002 (Red Gate) | `Reviver::revive(Serialized::Constructor { id: [], kwargs: {} })` | `Err(E-SRLZ-001)` — empty id | error-case (empty id) |
| TV-003 | `Reviver::revive(Serialized::Constructor { id: ["langchain_core", "prompts", "prompt", "PromptTemplate"], kwargs: {"template": "Hi"} })` | `Ok(PromptTemplate { ... })` — registered type | happy-path (registered type passes) |
| TV-004 | `Reviver::revive(Serialized::NotImplemented { id: ["unknown", "Type"] })` | `Err(E-SRLZ-001)` — NotImplemented variant also gated | error-case (NotImplemented with unknown id) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.19.005-A (VP-010 candidate) | `allowlist_check` returns `Err(E-SRLZ-001)` for all **non-monolith** unregistered ids (ids not in `LANGCHAIN_MONOLITH_TYPES`). For monolith ids see BC-2.19.006 (`Err(E-SRLZ-002)`). VP-010 Kani proof covers the non-monolith domain exclusively; joint coverage with BC-2.19.006 unit tests establishes the full invariant: `revive()` never returns `Ok` for any unregistered id. | unit test (exhaustive known-bad non-monolith id space) + Kani VP-010 formal proof: enumerate all reachable code paths in `revive()` for non-monolith ids, prove `Ok` is unreachable; BC-2.19.006 unit tests cover the monolith-id domain |
| VP-2.19.005-B | The allowlist check is the FIRST operation in `revive()` — no kwargs parsing or type dispatch occurs before it | code structural test: verify `revive()` calls registry lookup before any serde call |

## Related BCs

- BC-2.19.001 — depends on: allowlist containment is the guard that makes BC-2.19.001's `Ok(revived)` postcondition safe — only registered types can return Ok
- BC-2.19.003 — depends on: the registry must exist and be non-empty for the allowlist check to work
- BC-2.19.004 — composes with: legacy remap happens before the allowlist check; both must be in order for the security model to hold
- BC-2.19.006 — composes with: langchain-monolith types are a subset of unknown ids that warrant E-SRLZ-002 specifically; the general fallthrough for all other unknown ids is E-SRLZ-001

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-19, `core::serializable::reviver` (pure-core revive fn)
- `architecture/decisions/ADR-016-lc-json-deserialization-safety.md` — Decision 6 (allowlist-first revive, E-SRLZ-001, no id interpolation in error message, Kani VP-010 candidacy)
- `architecture/purity-boundary-map.md` — `ferrochain-core / core::serializable` Pure Core; Kani VP-010 candidacy noted

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-19 security story]_

## VP Anchors

- VP-2.19.005-A (pending VP-010 registration in VP-INDEX.md)
- VP-2.19.005-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-025 |
| Capability Anchor Justification | CAP-025 ("Reviver and Type Registry (Inventory-Based; Allowlist Containment; Legacy-Namespace Remap)") per capabilities-p1-p2.md §CAP-025 — this BC specifies the Allowlist Containment property that CAP-025 names as the second of its three defining subsystem capabilities; the allowlist-first revive is the primary deserialization security invariant for SS-19 |
| L2 Domain Invariants | DI-008 (revive returns Result; no panic or unsafe unwrap), DI-014 (E-SRLZ-001 propagates as Err; no silent fallthrough, no default-constructed value returned) |
| Architecture Authority | ADR-016 Decision 6 (allowlist-first check, E-SRLZ-001 category SECURITY, no id in error message, VP-010 Kani candidacy) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| VP Registration | VP-010 (ARCH-INDEX candidate — architect assigns VP-INDEX entry after BC authoring completes) |
| Module | ferrochain-core / core::serializable::reviver |
| Priority | P0 |
| Wave | 2 |
| Test Types | unit (pure-core) + Kani (VP-010 candidate) |
