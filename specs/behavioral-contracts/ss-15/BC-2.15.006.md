---
document_type: behavioral-contract
level: L3
bc_id: BC-2.15.006
version: "1.9"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-15
capability: CAP-020
changelog:
  - "1.1 (OBS-P77-C, 2026-07-15): ADR-012 DI-001 renamed to ADR-012 INV-1 per architect adjudication D18-P77-A (ADR-012 v1.2 local-invariant rename). Updated in Invariants (cache-coherence invariant label) and Architecture Anchors (§Decision 3 reference)."
  - "1.2 (OBS-P123-b cross-fix, fix burst 126, 2026-07-19): PC1 and Architecture Anchors corrected to use the canonical MemoryStore trait API per interface-definitions.md v2.39 §MemoryStore. (A) Method name: MemoryStore::get → MemoryStore::memory_get (BC-2.15.001 PC3 is the authoritative method name). (B) Scope parameter: spec.namespace is now explicitly typed as MemoryScope::App(spec.namespace) — context mutation sources are operator-managed, app-level content (BC-2.15.002 PC3); this matches test vector TV-001 namespace 'agent' which is an app-level concept. (C) Architecture Anchors scheduler call updated to reflect correct method signature. No behavioral change — the resolution of which MemoryScope tier applies to ContextSourceSpec.namespace was implicit in the prior text; this entry makes it explicit."
  - "1.3 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
  - "1.4 (fix-burst-279/F-P175-B101/ADR-012-D1-Amendment/2026-07-28): PC1 scope bridge corrected per architect ADR-012 Decision 1 Amendment (B101 CRIT). ContextSourceSpec.namespace is a key-namespace PREFIX within the tenant partition, NOT the app_id. Corrected call uses MemoryScope::App(run_context.app_id) with composite key format!(\"{}/{}\", spec.namespace, spec.key). run_context.app_id is the system-derived tenant identity (set by execution engine before first super-step; NOT overridable via RunnableConfig caller input). Empty app_id fails loud: all reads return Err(E-MEMORY-004 NoScopeContext) — no silent empty return. EC-006 added for empty app_id at run start. Architecture Anchors scheduler call updated to reflect corrected signature."
  - "1.5 (notation-sweep-B6/2026-07-29): B6 error-construction notation sweep — 3 corrections. (1) EC-003 Scenario: `PregolyaError { ... }` → `PregolyaError { .. }` (CLASS3_ASCII_ELLIPSIS_VIOLATION). (2) EC-003 Expected: `PregolyaError { category: DURABILITY, ... }` → `PregolyaError { category: DURABILITY, .. }` (CLASS3_ASCII_ELLIPSIS_VIOLATION). (3) TV-006: `PregolyaError { category: DURABILITY }` → `PregolyaError { category: DURABILITY, .. }` (Class 3 VIOLATION — no elision marker). All three per ADR-010 §Error-Construction Notation Canon."
  - "1.6 (fix-burst-283/TV-gap-EC-006/2026-07-30): TV-007 added for EC-006 (empty app_id at run start → E-MEMORY-004 NoScopeContext fail-loud). EC-006 was introduced in v1.4 but had no corresponding test vector; a decision with no vector is unenforceable per project discipline. TV-007 exercises the `run_context.app_id` empty path and verifies `Err(E-MEMORY-004)` with `category: SECURITY` — fail-closed per ADR-012 Decision 1 Amendment §Gap 3 correction."
  - "1.7 (fix-burst-287/ADR-010-C3/2026-08-01): ADR-010 Class 3 notation fix — EC-006 Expected behavior multi-line PregolyaError::new(Component::Memory, Category::Security, RetryHint::Never, \"E-MEMORY-004\", ...) collapsed to Err(PregolyaError { code: \"E-MEMORY-004\", .. }). Bare constructor form forbidden in prose context per ADR-010 Class 3 rules."
  - "1.8 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.13 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.9 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-020
  - architecture/decisions/ADR-012-self-improvement-primitives.md
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-012-self-improvement-primitives.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "bda5443"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.15.006: Frozen-Snapshot Context Mutation — Memory-Sourced System-Prompt Content

## Description

`RunnableConfig.context_mutations: Option<ContextMutationConfig>` declares which memory
entries (identified by `namespace` + `key` pairs) are loaded and prepended to the
system-prompt context at run start. `graph::scheduler` loads these sources **once**, before
the first super-step begins. Within the run, memory writes (governed by BC-2.15.005) take
effect in `MemoryStore` immediately but do NOT update the assembled context — the context
snapshot is frozen for the duration of the run. Updates become visible on the **next** run
when `graph::scheduler` performs a fresh `ContextMutationConfig` load. This preserves
prompt-prefix cache hits (ADR-011 cache-key obligation applies) and implements the
frozen-tier semantics of Hermes SOUL.md / MEMORY.md.

## Preconditions

1. {PRE-001} `RunnableConfig.context_mutations` is `Some(ContextMutationConfig { sources: Vec<ContextSourceSpec> })`
   where each `ContextSourceSpec` has a non-empty `namespace` and `key`.
2. {PRE-002} The referenced `MemoryStore` is initialized and accessible from `graph::scheduler`.
3. {PRE-003} The run is being initiated via `invoke` or `stream` (not resumed from an existing
   interrupted checkpoint — resumption uses the context as of the original run start).

## Postconditions

1. {PC-001} Before the first super-step executes, `graph::scheduler` loads each `ContextSourceSpec`
   from `MemoryStore` in declaration order:
   ```
   MemoryStore::memory_get(
       MemoryScope::App(run_context.app_id),
       &format!("{}/{}", spec.namespace, spec.key),
   )
   ```
   `run_context.app_id` is the system-derived application tenant identity (set by the
   execution engine before the first super-step; NOT supplied by the caller via
   `RunnableConfig`). `spec.namespace` is a key-namespace prefix scoped WITHIN the
   tenant partition — it is NOT an application identity.
   If `run_context.app_id` is empty, all reads return `Err(E-MEMORY-004 NoScopeContext)`
   — fail-loud; no content is silently skipped (ADR-012 Decision 1 Amendment,
   §Gap 3 correction: empty app_id must fail loud, not silently return Ok(None)).
2. {PC-002} The loaded content is prepended to the initial system instruction that is passed to the
   first super-step's model context. Sources that return `None` (key absent) are silently
   skipped — their absence is not an error. This silently-skipped path applies only when
   `run_context.app_id` is non-empty and the specific key does not exist in the store.
3. {PC-003} The assembled context (including all successfully loaded sources) is held as an immutable
   snapshot for the duration of the run. **No super-step** in the current run sees a
   different assembled context, even if a memory write occurs mid-run via BC-2.15.005.
4. {PC-004} Memory writes performed during the run take effect in `MemoryStore` immediately (for
   callers reading the store directly). They become part of the context snapshot for the
   **next** run that calls `graph::scheduler` with the same `ContextMutationConfig`.
5. {PC-005} When `context_mutations` is `None`, no additional content is prepended; behavior is
   identical to the existing run-without-context-mutations path.
6. {PC-006} The loaded context content is included in any ADR-011 cache-key hash computation over the
   assembled system instruction. (See Invariants — ADR-011 obligation.)

## Invariants

- {INV-001} **Cache-coherence invariant (ADR-012 INV-1):** Within a single run, the context assembled
  from `ContextMutationConfig` sources is immutable. A memory write performed during the run
  does not affect the context seen by subsequent super-steps in that run. Violation of this
  invariant is a programming error (INTERNAL).
- {INV-002} **ADR-011 cache-key obligation:** If the provider uses a content-hash cache key over the
  assembled system instruction (e.g., Anthropic `cache_control`, OpenAI system message
  caching), the hash input MUST include the bytes of all loaded context-mutation content.
  The cache key must not be computed before context-mutation injection (ADR-012 §Consequences
  / Cache-Key Obligation).
- {INV-003} **Source declaration order is load order:** Sources are loaded in the order they appear in
  `ContextMutationConfig.sources`. If two sources produce conflicting content, the later
  source's content is appended after the earlier source's content (no merge/dedup logic).
- {INV-004} `ContextMutationConfig` and `ContextSourceSpec` are pure value types defined in
  `pregolya-core/src/context_mutation.rs` — no async, no I/O in these types themselves.
  The loading behavior is in `graph::scheduler`.

## Edge Cases

### EC-001: Source key not present in MemoryStore
**Scenario:** `ContextSourceSpec { namespace: "agent", key: "MEMORY.md" }` but no such key
has been written yet.
**Expected behavior:** `MemoryStore::memory_get` returns `None`. The source is skipped (omitted from
the context prepend). No error is raised. The run proceeds with the remaining sources (if any)
or with no prepended content.

### EC-002: Memory write occurs mid-run; same-run context unchanged
**Scenario:** Super-step 1 writes to `("agent", "MEMORY.md")` via a guarded write (BC-2.15.005).
Super-step 2 processes the next model call.
**Expected behavior:** Super-step 2's model context still sees the content loaded at run start
(before the write). The updated `("agent", "MEMORY.md")` content becomes visible only on the
next run's `ContextMutationConfig` load.

### EC-003: MemoryStore load failure at run start
**Scenario:** During the `graph::scheduler` pre-first-super-step load, a `ContextSourceSpec`
load returns `Err(PregolyaError { .. })` due to a storage I/O failure.
**Expected behavior:** The error propagates from `graph::scheduler` to the caller; the run
does NOT start. `Err(PregolyaError { category: DURABILITY, .. })` (the propagated storage
error) is returned. No partial run or partial context injection occurs. (DI-008.)

### EC-004: context_mutations = None (opt-out path)
**Scenario:** `RunnableConfig.context_mutations` is `None`.
**Expected behavior:** `graph::scheduler` skips the ContextMutationConfig loading step
entirely. The system instruction is assembled without any memory-sourced prepend. Behavior
is identical to the pre-CAP-020 run path.

### EC-005: Two consecutive runs; memory updated between runs
**Scenario:** Run 1 starts with `("agent", "MEMORY.md")` = "Fact A". During run 1, a
guarded write updates `("agent", "MEMORY.md")` to "Fact A; Fact B". Run 2 starts with the
same `ContextMutationConfig`.
**Expected behavior:** Run 1 context sees "Fact A" only (frozen at run start). Run 2 loads
"Fact A; Fact B" (the value written during run 1) and that content is prepended to run 2's
context.

### EC-006: Empty app_id at run start — fail-loud (ADR-012 Decision 1 Amendment)
**Scenario:** `graph::scheduler` attempts to load `ContextMutationConfig` sources but
`run_context.app_id` is empty at the start of the super-step.
**Expected behavior:** `graph::scheduler` returns `Err(PregolyaError { code: "E-MEMORY-004", .. })` for the ContextMutationConfig load. The run does NOT proceed silently with no memory
context — it surfaces the missing scope as an error. The execution engine is responsible
for ensuring `run_context.app_id` is set before the first super-step. Fail-loud: symmetric
with `SkillStore` construction (BC-2.15.004 PC3), per ADR-012 Decision 1 Amendment §Gap 3
correction — NO-SILENT-EMPTY enforced on both B101 and B102 paths.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `ContextMutationConfig { sources: [{ ns: "agent", key: "SOUL.md" }] }`; "SOUL.md" = "You are a helpful agent."; run invoked | First super-step sees "You are a helpful agent." prepended to system instruction | Happy-path: source loaded |
| TV-002 | Same config; "SOUL.md" key absent in MemoryStore | Run proceeds with no prepend; no error | Absent source silently skipped |
| TV-003 | "MEMORY.md" = "Fact A"; run starts; super-step 1 writes "Fact A; Fact B" to MEMORY.md; super-step 2 executes | Super-step 2 context still has "Fact A" (frozen at run start) | Frozen snapshot: mid-run write invisible |
| TV-004 | Run 1 writes "Fact B" to MEMORY.md; Run 2 starts with same config | Run 2 context prepend includes "Fact B" | Next-run visibility |
| TV-005 | `context_mutations = None` | No prepend; run executes as before | Opt-out path |
| TV-006 | Storage I/O error during pre-run load | `Err(PregolyaError { category: DURABILITY, .. })` from `invoke`; run does not start | Storage failure halts run before first super-step |
| TV-007 | `ContextMutationConfig { sources: [{ ns: "agent", key: "SOUL.md" }] }`; `run_context.app_id` is `""` (empty string) when the execution engine triggers the pre-first-super-step load | `Err(PregolyaError { category: SECURITY, code: "E-MEMORY-004", message: "NoScopeContext: application tenant identity (app_id) is empty; ContextMutationConfig load requires a valid app_id", .. })` from `invoke`; run does NOT start; does NOT silently return `Ok(None)` or proceed with empty context | EC-006 — empty `app_id` fail-loud; ADR-012 Decision 1 Amendment §Gap 3 correction |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-CTX-01 | Mid-run write does not change the context seen by subsequent super-steps in the same run | Integration test: capture model context at step 1 and step 2; assert identical | Wave 2 |
| VP-CTX-02 | Cache key computed over assembled instruction includes loaded context content | Unit test: assemble instruction with source, compute cache key; verify content bytes are in key input | Wave 2 |

## Related BCs

- BC-2.15.004 — composes with: SkillStore reads are one mechanism to load skill documents; ContextMutationConfig sources can reference skill namespaces in MemoryStore
- BC-2.15.005 — composes with: guarded writes govern mutation of the memory keys that serve as ContextMutationConfig sources
- BC-2.15.001 — depends on: MemoryStore provides the KV read operation used by `graph::scheduler` during source loading

## Architecture Anchors

- `pregolya-core/src/context_mutation.rs` (`core::context_mutation`) — `ContextSourceSpec` struct `{ namespace: String, key: String }`; `ContextMutationConfig` struct `{ sources: Vec<ContextSourceSpec> }`; `RunnableConfig.context_mutations: Option<ContextMutationConfig>` (per ADR-012 Decision 1, Primitive B)
- `pregolya-graph/src/scheduler.rs` (`graph::scheduler`) — pre-first-super-step load: iterates `ContextMutationConfig.sources`, calls `MemoryStore::memory_get(MemoryScope::App(run_context.app_id), &format!("{}/{}", spec.namespace, spec.key))` per source; empty `run_context.app_id` returns `Err(E-MEMORY-004)` fail-loud; prepends loaded content to initial context; no new module row (added behavior of existing scheduler module per ADR-012 Decision 1 Amendment + Decision 4)
- ADR-012 §Decision 3 — frozen-snapshot semantics adopted; live mutation rejected; ADR-012 INV-1 (cache-coherence invariant)
- ADR-011 — cache-key obligation: loaded context bytes must be included in system-instruction hash input

## Story Anchor

S-1.13

## VP Anchors

- VP-CTX-01, VP-CTX-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-020 |
| Capability Anchor Justification | CAP-020 ("Self-Improvement Primitives (Skill Registry, Guarded Memory Writes, Frozen-Snapshot Context Mutation)") per capabilities-p1-p2.md §CAP-020 — this BC specifies the "frozen-snapshot context mutation" primitive named in CAP-020(c): ContextMutationConfig on RunnableConfig, sources loaded once at run start by graph::scheduler, writes visible next run |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract — ContextMutationConfig is a pure value type; loading errors propagate as Err), DI-002 (Per-Task Durability — context is loaded before first super-step, consistent with BSP model), DI-014 (Error Propagation — load failures surface as Err; never silently empty) |
| Decision Authority | D20; ADR-012 Decision 3 (frozen-snapshot semantics adopted over live mutation); ADR-011 (cache-key obligation) |
| Domain D Forcing Function | domain-d-hermes-agent.md req 3 — "frozen-snapshot semantics for the stable tiers preserve prompt-cache hits while allowing ephemeral per-turn additions"; this BC implements the framework-level frozen-snapshot primitive |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration) |
| Module | pregolya-core (`core::context_mutation` — types) / pregolya-graph (`graph::scheduler` — loading behavior) |
