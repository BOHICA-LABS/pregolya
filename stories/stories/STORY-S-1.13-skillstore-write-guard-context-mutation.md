---
document_type: story
level: ops
story_id: S-1.13
epic_id: E-06
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.004.md
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.005.md
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "76f1726"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.12, S-1.04, S-1.14]
blocks: []
behavioral_contracts: [BC-2.15.004, BC-2.15.005, BC-2.15.006]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-memory
subsystems: [SS-15, SS-03]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.13: SkillStore Registry, Guarded Memory Writes, and Frozen-Snapshot Context Mutation

## Narrative

- **As a** pregolya library user building skill-routing agents
- **I want to** have a read-only SkillStore overlaying MemoryStore for skill routing, a synchronous write-guard that validates and sanitizes all memory writes before persistence, and a frozen-snapshot mechanism for loading context mutation configs at graph start
- **So that** skills are discoverable via app-scoped memory without write access, memory writes cannot inject prompt content or invisible Unicode, and context mutation is deterministic and cache-coherent across a graph run

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.15.004 | SkillStore — Read-Only Routing Overlay, App Scope Bound at Construction | AC-001..AC-005 |
| BC-2.15.005 | MemoryWriteGuard — Synchronous validate(), Fail-Closed, Injection Scanner | AC-006..AC-012 |
| BC-2.15.006 | Frozen-Snapshot Context Mutation — Loaded Once Pre-First-Super-Step | AC-013..AC-017 |

## Acceptance Criteria

### AC-001 (traces to BC-2.15.004 postcondition 1 — SkillStore trait)
`SkillStore` trait provides three methods: `load_skill(skill_id) -> Result<Option<Skill>, PregolyaError>`, `list_skills(tags: &[&str]) -> Result<Vec<Skill>, PregolyaError>`, `skill_exists(skill_id) -> Result<bool, PregolyaError>`. `load_skill` returns `Ok(None)` for not-found (not an error). `list_skills` with empty tags returns all skills in scope. Verified by `test_BC_2_15_004_skill_store_trait_methods()`.

### AC-002 (traces to BC-2.15.004 postcondition 2 — App scope bound at construction)
`SkillStore::new(store: Arc<dyn MemoryStore>, app_id: &str)` binds `MemoryScope::App(app_id)` permanently at construction. All subsequent `load_skill`, `list_skills`, `skill_exists` calls use this scope — the caller cannot override the scope. The `app_id` is derived from `RunContext.app_id` (system-derived), not passed directly by user code. Verified by `test_BC_2_15_004_app_scope_bound_at_construction()`.

### AC-003 (traces to BC-2.15.004 postcondition 3 — read-only overlay)
`SkillStore` has no write methods. There is no `memory_set`, `memory_delete`, or any mutation method. `SkillStore` is strictly read-only. Verified by `test_BC_2_15_004_skill_store_no_write_methods()` (compile check: calling `store.memory_set(...)` on a `SkillStore` value fails to compile).

### AC-004 (traces to BC-2.15.004 postcondition 4 — empty app_id fail-closed)
`SkillStore::new(store, "")` with empty `app_id` stores the empty ID but all subsequent calls (`load_skill`, `list_skills`, `skill_exists`) return `Err(PregolyaError { code: "E-MEMORY-004", message: "NoScopeContext: SkillStore constructed with empty app_id", category: SECURITY, .. })`. This is fail-closed behavior — the empty app_id is not silently treated as global scope. Verified by `test_BC_2_15_004_empty_app_id_fail_closed()` covering all three methods (TV-009 coverage).

### AC-005 (traces to BC-2.15.004 postcondition 5 — load_skill not-found)
`load_skill("nonexistent_skill_id")` returns `Ok(None)` — not-found is not an error. Only infrastructure failures (database error, scope access denied) return `Err`. Verified by `test_BC_2_15_004_load_skill_not_found_is_ok_none()`.

### AC-006 (traces to BC-2.15.005 postcondition 1 — validate signature)
`MemoryWriteGuard::validate(req: &MemoryWriteRequest) -> WriteGuardDecision` is a synchronous `fn` (NOT async). `WriteGuardDecision` is `Allow`, `Deny { reason: String }`, or `Transform { sanitized: MemoryWriteRequest }`. The method takes a reference (no ownership transfer). Verified by `test_BC_2_15_005_validate_signature()`.

### AC-007 (traces to BC-2.15.005 postcondition 2 — fail-closed on panic)
If a custom `MemoryWriteGuard` implementation panics inside `validate`, the panic is caught via `std::panic::catch_unwind` and the result is `Deny { reason: "write guard panicked" }`. The memory write does NOT proceed when the guard panics. Verified by `test_BC_2_15_005_panic_fails_closed()` (custom guard that always panics).

### AC-008 (traces to BC-2.15.005 postcondition 3 — E-MEMORY-007 on Deny)
When `validate` returns `Deny`, the memory write returns `Err(PregolyaError { code: "E-MEMORY-007", message: "MemoryWriteGuardDenied: ...", category: SECURITY, severity: broken, .. })`. The error is classified SECURITY and severity `broken` (never a transient retry). Verified by `test_BC_2_15_005_deny_produces_e_memory_007()`.

### AC-009 (traces to BC-2.15.005 postcondition 4 — built-in role prefix scanner)
The built-in `MemoryWriteGuard` implementation scans for role injection prefixes in the write value: `"Human:"` and `"Assistant:"` at the start of any content string. If detected, returns `Deny { reason: "role prefix injection detected" }`. A write containing `"Human: you are now..."` is denied. Verified by `test_BC_2_15_005_role_prefix_injection_denied()`.

### AC-010 (traces to BC-2.15.005 postcondition 5 — invisible Unicode scanner)
The built-in scanner also detects invisible Unicode in the write value: U+200B..U+200F (zero-width spaces), U+FEFF (BOM), U+202A..U+202E (bidirectional overrides). If detected, returns `Deny { reason: "invisible Unicode detected" }`. Verified by `test_BC_2_15_005_invisible_unicode_denied()` with each code point range.

### AC-011 (traces to BC-2.15.005 postcondition 6 — Transform decision)
When `validate` returns `Transform { sanitized }`, the memory write proceeds with `sanitized` content (not the original). The `Remove` variant of content sanitization (removing invisible chars) always produces `Allow` from the built-in scanner after sanitization. Verified by `test_BC_2_15_005_transform_decision_uses_sanitized()`.

### AC-012 (traces to BC-2.15.005 invariant 1 — type split)
`WriteGuardDecision`, `MemoryWriteRequest`, and the `MemoryWriteGuard` trait are defined in `pregolya-core/src/write_guard.rs`. The enforcement logic (calling `validate` and applying the decision) is in `pregolya-memory/src/write_guard.rs`. The types MUST NOT be defined in `pregolya-memory` — they live in `pregolya-core` for cross-crate reuse. Verified by `test_BC_2_15_005_write_guard_types_in_core()` (import path assertion in tests).

### AC-013 (traces to BC-2.15.006 postcondition 1 — ContextMutationConfig loaded once)
`ContextMutationConfig { sources: Vec<ContextSourceSpec { namespace: String, key: String }> }` is loaded by `graph::scheduler` (in `pregolya-graph/src/scheduler.rs`) once before the first super-step. It is NOT reloaded during the graph run. Verified by `test_BC_2_15_006_context_mutation_config_loaded_once()` (scheduler loads config once and verifies no re-load on subsequent super-steps).

### AC-014 (traces to BC-2.15.006 postcondition 2 — scope and key format)
The memory scope used for context mutation lookup is `MemoryScope::App(run_context.app_id)`. The lookup key is formatted as `format!("{}/{}", spec.namespace, spec.key)`. The namespace itself is NOT used as the scope — `MemoryScope::App(spec.namespace)` is WRONG. Verified by `test_BC_2_15_006_scope_is_app_id_not_namespace()`.

### AC-015 (traces to BC-2.15.006 postcondition 3 — empty app_id fail-loud)
If `run_context.app_id` is empty at context mutation loading time, the scheduler returns `Err(PregolyaError { code: "E-MEMORY-004", message: "NoScopeContext: context mutation requires a non-empty app_id in RunContext", .. })`. The graph run does NOT proceed with an empty app_id. Verified by `test_BC_2_15_006_empty_app_id_fails_load()`.

### AC-016 (traces to BC-2.15.006 postcondition 4 — frozen for run duration, visible next run)
After loading at run start, `ContextMutationConfig` is immutable for the duration of the run. Any changes to the underlying memory store during the run are NOT reflected (ADR-012 INV-1 cache-coherence invariant). Changes are visible in the NEXT run (next call to `scheduler.start()`). Verified by `test_BC_2_15_006_config_frozen_during_run()`.

### AC-017 (traces to BC-2.15.006 invariant 2 — ADR-011 cache-key obligation)
The cache key for the loaded context content includes the loaded content itself (not just the spec). This is the ADR-011 cache-key obligation — the cache key must reflect the content so that content changes invalidate the cache. Verified by `test_BC_2_15_006_cache_key_includes_content()`.

## Architecture Mapping

| Unit / Type | Module Path | Crate | Pure / Effectful |
|-------------|-------------|-------|-----------------|
| `WriteGuardDecision`, `MemoryWriteRequest`, `MemoryWriteGuard` trait | `pregolya_core::write_guard` | pregolya-core | Pure (trait and enum definitions; no I/O) |
| `ContextMutationConfig`, `ContextSourceSpec` | `pregolya_core::context_mutation` | pregolya-core | Pure (data type definitions; no I/O) |
| `SkillStoreImpl` (`load_skill`, `list_skills`, `skill_exists`; App scope bound at construction) | `pregolya_memory::skill_store` | pregolya-memory | Effectful Shell (reads from underlying `Arc<dyn MemoryStore>` via SQLite-backed production store) |
| `MemoryWriteGuard` enforcement logic (`catch_unwind`, decision application, `E-MEMORY-007`) | `pregolya_memory::write_guard` | pregolya-memory | Pure (synchronous `validate` call; `catch_unwind` is deterministic; no I/O in enforcement path itself) |
| Built-in injection scanner (role prefix and invisible Unicode detection) | `pregolya_memory::write_guard` | pregolya-memory | Pure (deterministic string scan; no I/O) |
| `ContextMutationConfig` loader (pre-first-super-step; `Arc<ContextMutationConfig>` frozen snapshot) | `pregolya_graph::scheduler` | pregolya-graph | Effectful Shell (reads from `MemoryStore` once; produces immutable `Arc` snapshot for the run) |

**Subsystem anchor:** SS-15 owns this story's primary scope because SS-15 is the Long-Horizon Memory subsystem (`pregolya-memory` and the `pregolya-core` type primitives) per ARCH-INDEX Subsystem Registry. SS-03 (BSP Execution Engine) is co-anchored because SS-03 owns the BSP super-step scheduler component in `pregolya-graph` per ARCH-INDEX Subsystem Registry; the `pregolya_graph::scheduler` context mutation config loader runs at the pre-first-super-step boundary that the BSP execution engine controls. Note: crate membership in `pregolya-graph` alone does not establish the SS-03 anchor (multiple subsystems — SS-02, SS-03, SS-05, SS-06, SS-10, SS-11 — all share `pregolya-graph`); the semantic basis is that the pre-first-super-step boundary is a BSP execution engine lifecycle hook owned by SS-03, not a graph-definition, HITL, or budget-governance boundary. Pure-core / effectful-shell boundary: all type definitions in `pregolya-core` are pure core; the enforcement logic in `pregolya-memory::write_guard` is pure (synchronous scan); `SkillStoreImpl` and the scheduler's config loader are effectful shells.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `WriteGuardDecision`, `MemoryWriteRequest`, `MemoryWriteGuard` trait (`pregolya-core`) | Pure | Type and trait definitions; no I/O |
| `ContextMutationConfig`, `ContextSourceSpec` (`pregolya-core`) | Pure | Data type definitions; no I/O |
| `MemoryWriteGuard::validate` (enforcement call with `catch_unwind`) | Pure | Synchronous fn; deterministic `catch_unwind` boundary; no I/O in the enforcement path; panicking guard is caught and converted to `Deny` |
| Built-in role-prefix and invisible-Unicode scanner | Pure | Deterministic string scan (`str::starts_with`, Unicode code-point range checks); no I/O |
| `SkillStoreImpl::load_skill` / `list_skills` / `skill_exists` | Effectful Shell | Reads from underlying `Arc<dyn MemoryStore>` (SQLite-backed in production); performs database reads |
| `pregolya_graph::scheduler` context mutation config loading | Effectful Shell | Reads `ContextMutationConfig` from `MemoryStore` once pre-first-super-step; stores as `Arc<ContextMutationConfig>` frozen snapshot |

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| Story spec (this file) | ~5,500 |
| BC files (3 BCs: BC-2.15.004/005/006) | ~8,000 |
| Architecture module-decomposition.md (SS-15 + SS-04 graph sections) | ~1,500 |
| pregolya-memory existing code (S-1.12 context) | ~2,500 |
| pregolya-core write_guard.rs (new file) | ~1,500 |
| pregolya-graph scheduler.rs (new/modified) | ~2,000 |
| Test files | ~4,000 |
| **Total** | **~25,000** |

Within the 20-30% agent context window threshold. Note this story touches three crates (`pregolya-core`, `pregolya-memory`, `pregolya-graph`).

## Tasks

- [ ] Create `pregolya-core/src/write_guard.rs` — `WriteGuardDecision`, `MemoryWriteRequest`, `MemoryWriteGuard` trait (types only, no enforcement)
- [ ] Create `pregolya-core/src/context_mutation.rs` — `ContextMutationConfig`, `ContextSourceSpec` types
- [ ] Create `pregolya-memory/src/skill_store.rs` — `SkillStoreImpl` implementing `SkillStore` trait; App scope bound at construction; empty app_id fail-closed
- [ ] Create `pregolya-memory/src/write_guard.rs` — enforcement: call `validate`, catch panics, apply `WriteGuardDecision`, return E-MEMORY-007 on Deny
- [ ] Add built-in injection scanner to `pregolya-memory/src/write_guard.rs` — role prefix detection, invisible Unicode detection
- [ ] Create/modify `pregolya-graph/src/scheduler.rs` — load `ContextMutationConfig` once pre-first-super-step; scope as `MemoryScope::App(run_context.app_id)`; key format `"{namespace}/{key}"`; empty app_id fail-loud
- [ ] Export `SkillStore` trait and types from `pregolya-memory/src/lib.rs`
- [ ] Export `WriteGuardDecision`, `MemoryWriteRequest`, `MemoryWriteGuard` from `pregolya-core/src/lib.rs`
- [ ] Export `ContextMutationConfig`, `ContextSourceSpec` from `pregolya-core/src/lib.rs`
- [ ] Write unit tests for all 17 ACs
- [ ] Run `just iter pregolya-memory` + `just iter pregolya-core` + `just iter pregolya-graph` — all tests green

## Previous Story Intelligence

- S-1.12 (Memory KV/Vector/GDPR) established `MemoryStore` trait, `MemoryScope`, `SqliteMemoryStore`, and the ephemeral test backend. `SkillStore` is built as an overlay on top of the existing `MemoryStore` trait. Load S-1.12 context before implementing S-1.13.
- S-1.04 (Runnable Trait and Pipe) established `pregolya-core` crate structure. Adding `write_guard.rs` and `context_mutation.rs` to `pregolya-core` follows the same module pattern.
- S-1.14 (StateGraph Node + Channel Reducers) established the `pregolya-graph` crate, including its `Cargo.toml`, `src/lib.rs`, and module scaffold. `pregolya-graph/src/scheduler.rs` cannot be created until the `pregolya-graph` crate exists. Implementer must load S-1.14 context first to confirm the crate layout and `lib.rs` re-export conventions before adding `scheduler.rs`.
- The graph scheduler (in `pregolya-graph`) has not been covered in prior Wave 1 stories. This is the first story touching `pregolya-graph/src/scheduler.rs`. The implementer should verify that a scheduler skeleton exists before implementing the context mutation loading.

## Architecture Compliance Rules

Derived from `architecture/module-decomposition.md §pregolya-memory` and `§pregolya-core`:

1. `WriteGuardDecision`, `MemoryWriteRequest`, `MemoryWriteGuard` trait MUST be in `pregolya-core/src/write_guard.rs`. The enforcement (calling `validate`, catching panics) is in `pregolya-memory/src/write_guard.rs`. No type definitions in `pregolya-memory` — only enforcement logic.
2. `ContextMutationConfig` and `ContextSourceSpec` MUST be in `pregolya-core/src/context_mutation.rs`. The loading logic is in `pregolya-graph/src/scheduler.rs`. Same split pattern as write-guard.
3. `MemoryScope::App(run_context.app_id)` — the scope is the `app_id`, NOT the `namespace`. This is the most likely correctness trap in this story.
4. Key format is `format!("{}/{}", spec.namespace, spec.key)` — the slash-separated concatenation is part of the BC contract and must not be changed without an ADR.
5. `ContextMutationConfig` is frozen after load: it must be stored in an immutable snapshot (e.g., `Arc<ContextMutationConfig>`) passed to all super-steps.
6. The `SkillStore` has no write methods. If a write method is accidentally added, the contract is broken. This must be verified by a compile-fail test or a code review check.
7. `WriteGuardDecision`, `MemoryWriteRequest`, `SkillStore`, `ContextMutationConfig`, `ContextSourceSpec` must all carry `#[non_exhaustive]` on public enums and structs.
8. `std::panic::catch_unwind` is ONLY acceptable for the write guard enforcement — it exists specifically to prevent panicking guard implementations from propagating panics to callers. Do not use `catch_unwind` elsewhere.
9. No `unwrap()` / `expect()` in non-test code. No `println!`.

## Library & Framework Requirements

| Library | Version | Usage |
|---------|---------|-------|
| `pregolya-core` | workspace path | `WriteGuardDecision`, `MemoryWriteRequest`, `ContextMutationConfig` (types defined here) |
| `pregolya-memory` | workspace path | `MemoryStore`, `MemoryScope` (enforcement defined here) |
| `pregolya-graph` | workspace path | `scheduler.rs` context mutation loading |
| `tokio` | 1.x | Async scheduler methods |
| `tracing` | 0.1.x | Structured logging |

**Forbidden Dependencies:** `pregolya-core/src/write_guard.rs` and `pregolya-core/src/context_mutation.rs` MUST NOT import from `pregolya-memory` or `pregolya-graph` — they are `pregolya-core` primitives. The dependency direction is: `pregolya-graph` → `pregolya-memory` → `pregolya-core`.

## File Structure Requirements

Files to CREATE:
- `/pregolya-core/src/write_guard.rs` — `WriteGuardDecision`, `MemoryWriteRequest`, `MemoryWriteGuard` trait
- `/pregolya-core/src/context_mutation.rs` — `ContextMutationConfig`, `ContextSourceSpec`
- `/pregolya-memory/src/skill_store.rs` — `SkillStoreImpl`
- `/pregolya-memory/src/write_guard.rs` — enforcement + built-in scanner
- `/pregolya-memory/tests/skill_store_tests.rs`
- `/pregolya-memory/tests/write_guard_tests.rs`

Files to MODIFY:
- `/pregolya-core/src/lib.rs` — re-export from `write_guard` and `context_mutation`
- `/pregolya-memory/src/lib.rs` — re-export from `skill_store` and `write_guard`
- `/pregolya-graph/src/scheduler.rs` — add context mutation config loading (create file if first scheduler story)

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `SkillStore::new(store, "")` then all three methods called | All three methods return `Err(E-MEMORY-004)` — TV-009 coverage |
| EC-002 | Custom `MemoryWriteGuard` returns `Transform` with sanitized content | Memory write proceeds with sanitized content (not original) |
| EC-003 | Custom guard panics | `catch_unwind` catches panic; returns `Deny { reason: "write guard panicked" }` |
| EC-004 | Context mutation config: `sources: vec![]` (empty sources list) | Load succeeds with empty config; no memory reads performed |
| EC-005 | Context mutation memory key contains slashes in namespace or key fields | Key is `format!("{}/{}", namespace, key)` — no escaping; downstream code must handle potential ambiguity |
| EC-006 | `SkillStore::list_skills([])` (empty tags) | Returns all skills in App scope — empty tags means no tag filter |
| EC-007 | Write with `"\u{200B}zero-width space"` in value | Built-in scanner detects U+200B; returns Deny |
| EC-008 | Write with `"Human: injected prompt"` in value | Built-in scanner detects role prefix; returns Deny |
