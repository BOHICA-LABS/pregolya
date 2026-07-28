---
document_type: behavioral-contract
level: L3
bc_id: BC-2.15.004
version: "1.3"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-15
capability: CAP-020
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.1 (F-P91-04, 2026-07-17): EC-004 adjudication — E-MEMORY-002 StorageFull is a write-capacity code (wrong semantic for a backend read I/O failure). No existing MEMORY code covers read I/O failure. Minted E-MEMORY-008 (MemoryStoreReadFailed, DURABILITY, broken, Maybe) as the correct code. EC-004 updated: removed E-MEMORY-002 and hedge 'or equivalent propagated storage error'; now cites E-MEMORY-008 MemoryStoreReadFailed. Added TV-008 to satisfy gate #33 raise-condition anchor for E-MEMORY-008. error-taxonomy.md v1.18 adds E-MEMORY-008 row (MEMORY namespace); census 85→86 (blanket 26→27: E-MEMORY-* 7→8)."
  - "1.2 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. EC-004 carried bare `Err(FerrochainError { category: DURABILITY, code: E-MEMORY-008 MemoryStoreReadFailed })` without message; E-MEMORY-008 taxonomy has <backend_error> placeholder (SQLite I/O error detail, available at raise site). Added inline message template to EC-004."
  - "1.3 (fix-burst-279/F-P175-B102/ADR-012-D1-Amendment/2026-07-28): PC3 updated with SCOPE NOTE — SkillStore implementations bind MemoryScope::App(app_id) at construction time per ADR-012 Decision 1 Amendment. Callers do not supply scope at call time; app_id comes from RunContext.app_id (system-derived, same source as ContextMutationConfig loading in BC-2.15.006). If the SkillStore was constructed without a valid app_id, all load_skill/list_skills/skill_exists calls return Err(E-MEMORY-004 NoScopeContext). EC-006 added for the empty-app_id construction case (unenumerated in prior versions; finding B102 noted this gap)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-020
  - architecture/decisions/ADR-012-self-improvement-primitives.md
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-012-self-improvement-primitives.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "870127a"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.15.004: SkillStore Registry — Load-on-Demand Skill Documents

## Description

`ferrochain-memory` provides a `SkillStore` trait that acts as a naming, tagging, and
load-on-demand routing overlay over `MemoryStore`. Skill documents (agentskills.io SKILL.md
pattern) are stored as ordinary KV entries in the underlying `MemoryStore`; `SkillStore`
adds semantic operations: load by name, list by tag, and existence check. Skills are
loaded on each `load_skill` call (on-demand, not cached in the registry). This BC specifies
the read path only; writes to skill entries are governed by BC-2.15.005 (guarded writes).

## Preconditions

1. A `SkillStore` implementation is configured and backed by an initialized `MemoryStore`.
2. Skill documents exist in the backing `MemoryStore` as KV entries in skill-designated
   namespaces, each associated with a `SkillDescriptor` (name, namespace, key, tags).
3. The caller has read access to the relevant `MemoryStore` namespace.
   SCOPE NOTE: `SkillStore` implementations bind `MemoryScope::App(app_id)` at
   construction time. Callers do not supply scope at call time. The `app_id` is
   supplied to the `SkillStore` constructor and comes from `RunContext.app_id`
   (system-derived, same as used by `ContextMutationConfig` loading in BC-2.15.006).
   If the `SkillStore` was constructed without a valid `app_id`, all `load_skill`,
   `list_skills`, and `skill_exists` calls return `Err(E-MEMORY-004 NoScopeContext)`
   (ADR-012 Decision 1 Amendment — scope encapsulated at service boundary; callers
   cannot influence which tenant partition is read).

## Postconditions

1. `load_skill(name: &str) -> Result<Option<String>, FerrochainError>` returns the skill
   document text (`Some(content)`) if a skill with the given name exists in the registry;
   returns `None` if no skill with that name is registered. Never returns an empty string
   to represent "not found."
2. `list_skills(tags: &[String]) -> Result<Vec<SkillDescriptor>, FerrochainError>` returns
   all registered `SkillDescriptor` entries whose tag list contains at least one of the
   requested tags. Passing an empty `tags` slice returns ALL registered descriptors.
3. `skill_exists(name: &str) -> Result<bool, FerrochainError>` returns `true` if a skill
   with the given name is registered, `false` otherwise. This call does NOT load the
   skill document; it is a cheap existence check only.
4. Each `load_skill` call issues a fresh read to `MemoryStore` — there is no in-process
   cache in `SkillStore`. If the underlying storage was updated (e.g., by BC-2.15.005's
   write path), subsequent `load_skill` calls return the updated content.
5. All three methods return `Err(FerrochainError)` on storage-layer failures (propagated
   from `MemoryStore`); they do NOT panic or return empty results to mask storage errors
   (DI-014).

## Invariants

- `SkillStore` is a **read-only routing layer**: it provides no `write_skill` or
  `delete_skill` method. All mutations to skill entries go through `MemoryStore` guarded
  by `MemoryWriteGuard` (BC-2.15.005).
- `SkillDescriptor` is a pure value type: `{ name: String, namespace: String, key: String,
  tags: Vec<String> }`. It carries no live references to storage and is `Send + Sync + Clone`.
- The mapping from skill name to `(namespace, key)` is maintained by the `SkillStore`
  implementation. Name collisions are not permitted: if two entries share a name, the
  implementation must surface an error at registration time, not silently pick one.
- `SkillStore` reads are NOT subject to injection scanning (that is a write-path concern).

## Edge Cases

### EC-001: load_skill with unknown name
**Scenario:** `load_skill("nonexistent_skill")` is called; no skill by that name exists.
**Expected behavior:** Returns `Ok(None)`. Does NOT return `Err`. Does NOT return
`Ok(Some(""))`.

### EC-002: list_skills with empty tag slice (return all)
**Scenario:** `list_skills(&[])` called when 5 skills are registered.
**Expected behavior:** Returns `Ok(vec![d1, d2, d3, d4, d5])` — all 5 descriptors. Order
is implementation-defined but stable across calls with no writes in between.

### EC-003: list_skills with tags matching subset
**Scenario:** 5 skills registered; 3 have tag `"filesystem"` and 2 have tag `"web"`.
`list_skills(&["filesystem"])` is called.
**Expected behavior:** Returns `Ok(vec![...])` with exactly the 3 descriptors tagged
`"filesystem"`. The 2 `"web"` skills are excluded.

### EC-004: MemoryStore storage error during load_skill
**Scenario:** The backing SQLite file returns an I/O error on read.
**Expected behavior:** Returns `Err(FerrochainError { category: DURABILITY, code: E-MEMORY-008 MemoryStoreReadFailed,
message: "MemoryStoreReadFailed: backend read failed: <backend_error>" })`
(where `<backend_error>` is the SQLite I/O error detail, available at the raise site). Does NOT panic.
Does NOT return `Ok(None)` to mask the error (DI-014).

### EC-005: skill_exists versus load_skill round-trip
**Scenario:** `skill_exists("python_helpers")` returns `true`; caller immediately calls
`load_skill("python_helpers")`.
**Expected behavior:** Returns `Ok(Some(content))`. The `skill_exists` check and
`load_skill` are separate storage reads; a concurrent delete between them could
produce `Ok(None)` — this is correct and not a contract violation (no TOCTOU
guarantee is required).

### EC-006: SkillStore constructed without a valid app_id — fail-loud at call time
**Scenario:** A `SkillStore` implementation was constructed with an empty `app_id`
(e.g., `SkillStore::new(store, "")` where the construction-time app_id was empty).
A caller then invokes `load_skill("py_helpers")`.
**Expected behavior:** Returns `Err(FerrochainError::new(
    Component::Memory, Category::Security, RetryHint::Never, "E-MEMORY-004",
    "NoScopeContext: SkillStore requires a valid app_id at construction; \
     app_id is empty — cannot derive tenant scope",
))`. All three methods (`load_skill`, `list_skills`, `skill_exists`) return the same
error when the bound `app_id` is empty. The operation fails closed — no data is
returned, no fallback scope used (ADR-012 Decision 1 Amendment — scope encapsulation
at service boundary; B102 CRIT correction).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Write skill "py_helpers" (content = "…doc…") to backing store; `load_skill("py_helpers")` | `Ok(Some("…doc…"))` | Happy-path load |
| TV-002 | `load_skill("missing")` when no such skill registered | `Ok(None)` | Not found is not an error |
| TV-003 | Register 3 skills with tags `["fs"]`, 2 with tags `["web"]`; `list_skills(&["fs"])` | `Ok(vec![d1, d2, d3])` — 3 descriptors | Tag filter |
| TV-004 | `list_skills(&[])` with 4 registered skills | `Ok(vec![...])` with 4 entries | Empty filter = all |
| TV-005 | `skill_exists("py_helpers")` after write | `Ok(true)` | Existence check |
| TV-006 | `skill_exists("nope")` with no such skill | `Ok(false)` | Existence check absent |
| TV-007 | Overwrite skill "py_helpers" via guarded write; `load_skill("py_helpers")` | Returns updated content | Load-on-demand; no stale cache |
| TV-008 | Backend `MemoryStore` returns an I/O error during `load_skill("py_helpers")` (e.g., SQLite file read failure) | `Err(E-MEMORY-008 MemoryStoreReadFailed)`; does not panic; does not return `Ok(None)` | EC-004 — read I/O failure propagates as structured error (DI-014) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-SKILL-01 | `load_skill` returns fresh content after write (no stale cache) | Integration test: write, overwrite, read; assert content is updated value | Wave 2 |
| VP-SKILL-02 | `list_skills` with tag filter returns correct subset | Unit test: register N skills with distinct tags; assert filter precision | Wave 2 |

## Related BCs

- BC-2.15.001 — depends on: KV persistence mechanics; skill documents are stored as KV entries in `MemoryStore`
- BC-2.15.002 — depends on: scope access control governs which namespaces the caller may read
- BC-2.15.005 — composes with: write path for skill entries; all mutations go through MemoryWriteGuard

## Architecture Anchors

- `ferrochain-memory/src/skills.rs` (`memory::skills`) — `SkillStore` trait + `SkillDescriptor` struct; routing overlay over `MemoryStore` (per ADR-012 Decision 1, Primitive A)
- `ferrochain-memory/src/store.rs` — `MemoryStore` backing trait; KV reads are delegated here
- ADR-012 §Decision 1 — Primitive A (SkillStore placement: ferrochain-memory as storage trait, not ferrochain-core)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-SKILL-01, VP-SKILL-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-020 |
| Capability Anchor Justification | CAP-020 ("Self-Improvement Primitives (Skill Registry, Guarded Memory Writes, Frozen-Snapshot Context Mutation)") per capabilities-p1-p2.md §CAP-020 — this BC specifies the skill registry read path (load-on-demand, list by tag, existence check) which is the "skill registry" primitive named in CAP-020(a) |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract — SkillStore::load_skill returns Result, not panics), DI-014 (Error Propagation — storage errors propagate as Err, never masked as None) |
| Decision Authority | D20 (self-improvement promoted to framework-scope); ADR-012 Decision 1 Primitive A |
| Domain D Forcing Function | domain-d-hermes-agent.md req 4 — "runtime-mutable procedural skills (SKILL.md load, route, write-back)"; `SkillStore` is the framework primitive enabling load-on-demand skill routing |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-memory (`memory::skills`) |
