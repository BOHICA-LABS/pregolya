---
document_type: behavioral-contract
level: L3
bc_id: BC-2.19.006
version: "1.3"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-19
capability: CAP-025
crate: ferrochain-core
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
di_anchors: [DI-008, DI-014]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-19 LC Serialization"
  - "1.1 (F-P224/F-P129-02/2026-07-21): PC1 and PC5 corrected — Category::COMPATIBILITY → Category::VAL per ADR-010 adjudication (E-SRLZ-002 = VAL in error-taxonomy.md v1.27; COMPATIBILITY is a non-canonical variant absent from the 12-member category enum). PC5 rationale rewritten: monolith type id is a validation failure (type known but unsupported), not a compatibility domain concept per taxonomy membership rules."
  - "1.2 (FIX-BURST-268/F-P166-01/2026-07-25): (1) TD-VSDD-091 de-pin — PC5 cited 'error-taxonomy.md v1.27 E-SRLZ-002 row' as live normative authority; version pin violates TD-VSDD-091 (narrative body must not cite vN.N numbers that decay on subsequent taxonomy diffs). Adjudication: live normative citation, not historical record. De-pinned to stable section anchor: 'error-taxonomy.md §E-SRLZ-002 (row: VAL)'. (2) COMPATIBILITY residue purge — Architecture Anchors and Traceability Architecture Authority both read 'E-SRLZ-002 category COMPATIBILITY' despite PC5 being corrected to VAL at v1.1; both are live authority claims contradicting the BC's own postconditions. Corrected both to 'category VAL' to match PC5 and ADR-010 adjudication."
  - "1.3 (FIX-BURST-269/F-P167-02/2026-07-25): Fix dangling 'ADR-016 Decision 7' anchor at two sites (Architecture Anchors and Traceability Architecture Authority). ADR-016 has only Decisions 1–5; Decision 7 is nonexistent. Corrected to 'ADR-016 Decision 3 Property 4' — LANGCHAIN_MONOLITH_TYPES set, E-SRLZ-002 category VAL, and the deliberate-unregistered pattern are all specified in Decision 3 Property 4. Same anchor class as BC-2.19.005 F-P148-01 fix ('Decision 6' → 'Decision 3 §Security Invariant')."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-025
  - architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "47a5803"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.19.006: Langchain-Monolith Type Ids Return E-SRLZ-002 (Structured Error, Not Silent None or E-SRLZ-001)

## Description

Serialized JSON artifacts produced by `langchain` (the Python monolith package, as opposed
to `langchain_core`) contain `id` paths starting with `["langchain", ...]` that refer to
types that were never ported to `langchain_core` — and therefore never ported to ferrochain.
These are distinct from unknown arbitrary ids: they are known-langchain-monolith types whose
absence from ferrochain is intentional. `Reviver` maintains a static
`LANGCHAIN_MONOLITH_TYPES` set; when `revive()` encounters an id in this set, it returns
`Err(E-SRLZ-002)` instead of `Err(E-SRLZ-001)`, allowing callers to distinguish "I've never
heard of this type" from "I know this type but it's from the langchain monolith and not
available in ferrochain." The error is propagated as `Err`; it is never a silent `None` (DI-014).

## Preconditions

1. `Reviver` has been initialized (BC-2.19.003).
2. The `id` field of the `Serialized::Constructor` matches an entry in `LANGCHAIN_MONOLITH_TYPES`
   (after legacy remap; BC-2.19.004).
3. The `id` does NOT match any registered ferrochain type (precondition for E-SRLZ-002
   vs. a successful revive).

## Postconditions

1. `Reviver::revive(serialized)` returns:
   ```
   Err(FerrochainError {
       component: Component::SRLZ,
       category: Category::VAL,
       code: "E-SRLZ-002",
       message: "unsupported-serializable: langchain-monolith type not ported to ferrochain",
   })
   ```
2. No constructor is called; no kwargs is parsed.
3. The error propagates via `?` to the caller (DI-014 — no silent None).
4. The check for `LANGCHAIN_MONOLITH_TYPES` occurs AFTER the general allowlist check
   (BC-2.19.005): the full ordering is:
   a. Registry lookup (BC-2.19.005) — if found, dispatch;
   b. Legacy remap then retry (BC-2.19.004) — if found, dispatch;
   c. `LANGCHAIN_MONOLITH_TYPES` check (this BC) — if found, return E-SRLZ-002;
   d. Default fallthrough: return E-SRLZ-001.
5. `category: Category::VAL` — a monolith type id in a serialized envelope is a validation
   failure: the type path is recognized as a known langchain-monolith namespace but is not
   supported in ferrochain. ADR-010 adjudicates E-SRLZ-002 as VAL (recorded in
   error-taxonomy.md §E-SRLZ-002 (row: VAL)). `COMPATIBILITY` is not a canonical member of
   the 12-member category enum; it was never a valid assignment.

## Invariants

1. `LANGCHAIN_MONOLITH_TYPES` is a compile-time `static` set — no runtime mutation.
2. The diagnostic error code (`E-SRLZ-002`) is always returned for monolith types —
   regardless of kwargs content. The type-not-ported error supersedes any kwargs validation.
3. The message text is fixed (`"unsupported-serializable: langchain-monolith type not ported to
   ferrochain"`) — it does NOT interpolate the type id (consistent with gate #33
   STRUCT-PLACEHOLDER PARITY and DI-010 discipline).
4. If a monolith type is later ported to ferrochain (future work), it is added to the registry
   and removed from `LANGCHAIN_MONOLITH_TYPES` simultaneously — the two sets must be disjoint.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Type is in both `LANGCHAIN_MONOLITH_TYPES` and the registry (programming error — sets must be disjoint) | Registry lookup succeeds first (step a); E-SRLZ-002 is never reached; this is detected by a startup validation check |
| EC-002 | Type is NOT in `LANGCHAIN_MONOLITH_TYPES` and NOT in the registry | Fallthrough to E-SRLZ-001 (BC-2.19.005's default case) |
| EC-003 | Type IS in `LANGCHAIN_MONOLITH_TYPES` but the caller constructed a well-formed `Serialized` | `Err(E-SRLZ-002)` regardless of kwargs validity — type-not-ported error supersedes kwargs |
| EC-004 | Legacy alias in `OLD_CORE_NAMESPACES_MAPPING` remaps to a monolith-type canonical | After remap, the canonical is checked against the registry; if not found, then checked against `LANGCHAIN_MONOLITH_TYPES`; returns E-SRLZ-002 |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `Reviver::revive(Serialized::Constructor { id: ["langchain", "chains", "llm", "LLMChain"], kwargs: {} })` | `Err(FerrochainError { code: "E-SRLZ-002", message: "unsupported-serializable: langchain-monolith type not ported to ferrochain" })` | error-case (monolith type) |
| TV-002 | `Reviver::revive(Serialized::Constructor { id: ["langchain", "agents", "mrkl", "ZeroShotAgent"], kwargs: {} })` | `Err(E-SRLZ-002)` — another monolith type | error-case (monolith type) |
| TV-003 | `Reviver::revive(Serialized::Constructor { id: ["completely_unknown", "Type"], kwargs: {} })` | `Err(E-SRLZ-001)` — not in monolith set, not in registry | error-case (generic unknown) |
| TV-004 | `Reviver::revive(Serialized::Constructor { id: ["langchain_core", "prompts", "prompt", "PromptTemplate"], kwargs: {"template": "Hi"} })` | `Ok(PromptTemplate { ... })` — langchain_core type (registered; not monolith) | happy-path |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.19.006-A | For all ids in `LANGCHAIN_MONOLITH_TYPES`, `revive()` returns exactly `Err(E-SRLZ-002)` | unit test — iterate over LANGCHAIN_MONOLITH_TYPES set; assert E-SRLZ-002 for each |
| VP-2.19.006-B | `LANGCHAIN_MONOLITH_TYPES` and the registry are disjoint at startup | startup validation unit test |

## Related BCs

- BC-2.19.005 — composes with: E-SRLZ-002 is a specialization of the general allowlist containment behavior; both are Err paths; E-SRLZ-002 is checked after the general registry miss
- BC-2.19.003 — depends on: the registry must be initialized to distinguish registered types from monolith types

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-19, `core::serializable::reviver`
- `architecture/decisions/ADR-016-lc-json-deserialization-safety.md` — Decision 3 Property 4 (LANGCHAIN_MONOLITH_TYPES set, E-SRLZ-002 category VAL, disjoint-set invariant, check-ordering)

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-19 story]_

## VP Anchors

- VP-2.19.006-A, VP-2.19.006-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-025 |
| Capability Anchor Justification | CAP-025 ("Reviver and Type Registry (Inventory-Based; Allowlist Containment; Legacy-Namespace Remap)") per capabilities-p1-p2.md §CAP-025 — this BC specifies the structured E-SRLZ-002 diagnostic for langchain-monolith types, which CAP-025 identifies as a required distinction between "unknown" and "known-but-not-ported" deserialization failures |
| L2 Domain Invariants | DI-008 (revive returns Result; no panic or silent unwrap), DI-014 (E-SRLZ-002 propagates as Err; no silent None or default object construction for a monolith type) |
| Architecture Authority | ADR-016 Decision 3 Property 4 (LANGCHAIN_MONOLITH_TYPES set, E-SRLZ-002, category VAL, disjoint-set invariant, check ordering within revive) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-core / core::serializable::reviver |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (pure-core, no I/O) |
