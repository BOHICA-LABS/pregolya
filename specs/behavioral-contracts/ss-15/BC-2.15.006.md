---
document_type: behavioral-contract
level: L3
bc_id: BC-2.15.006
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-15
capability: CAP-020
changelog:
  - "1.1 (OBS-P77-C, 2026-07-15): ADR-012 DI-001 renamed to ADR-012 INV-1 per architect adjudication D18-P77-A (ADR-012 v1.2 local-invariant rename). Updated in Invariants (cache-coherence invariant label) and Architecture Anchors (§Decision 3 reference)."
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-020
  - architecture/decisions/ADR-012-self-improvement-primitives.md
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-012-self-improvement-primitives.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "ed6eef5"
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

1. `RunnableConfig.context_mutations` is `Some(ContextMutationConfig { sources: Vec<ContextSourceSpec> })`
   where each `ContextSourceSpec` has a non-empty `namespace` and `key`.
2. The referenced `MemoryStore` is initialized and accessible from `graph::scheduler`.
3. The run is being initiated via `invoke` or `stream` (not resumed from an existing
   interrupted checkpoint — resumption uses the context as of the original run start).

## Postconditions

1. Before the first super-step executes, `graph::scheduler` loads each `ContextSourceSpec`
   from `MemoryStore` in declaration order: `MemoryStore::get(spec.namespace, spec.key)`.
2. The loaded content is prepended to the initial system instruction that is passed to the
   first super-step's model context. Sources that return `None` (key absent) are silently
   skipped — their absence is not an error.
3. The assembled context (including all successfully loaded sources) is held as an immutable
   snapshot for the duration of the run. **No super-step** in the current run sees a
   different assembled context, even if a memory write occurs mid-run via BC-2.15.005.
4. Memory writes performed during the run take effect in `MemoryStore` immediately (for
   callers reading the store directly). They become part of the context snapshot for the
   **next** run that calls `graph::scheduler` with the same `ContextMutationConfig`.
5. When `context_mutations` is `None`, no additional content is prepended; behavior is
   identical to the existing run-without-context-mutations path.
6. The loaded context content is included in any ADR-011 cache-key hash computation over the
   assembled system instruction. (See Invariants — ADR-011 obligation.)

## Invariants

- **Cache-coherence invariant (ADR-012 INV-1):** Within a single run, the context assembled
  from `ContextMutationConfig` sources is immutable. A memory write performed during the run
  does not affect the context seen by subsequent super-steps in that run. Violation of this
  invariant is a programming error (INTERNAL).
- **ADR-011 cache-key obligation:** If the provider uses a content-hash cache key over the
  assembled system instruction (e.g., Anthropic `cache_control`, OpenAI system message
  caching), the hash input MUST include the bytes of all loaded context-mutation content.
  The cache key must not be computed before context-mutation injection (ADR-012 §Consequences
  / Cache-Key Obligation).
- **Source declaration order is load order:** Sources are loaded in the order they appear in
  `ContextMutationConfig.sources`. If two sources produce conflicting content, the later
  source's content is appended after the earlier source's content (no merge/dedup logic).
- `ContextMutationConfig` and `ContextSourceSpec` are pure value types defined in
  `ferrochain-core/src/context_mutation.rs` — no async, no I/O in these types themselves.
  The loading behavior is in `graph::scheduler`.

## Edge Cases

### EC-001: Source key not present in MemoryStore
**Scenario:** `ContextSourceSpec { namespace: "agent", key: "MEMORY.md" }` but no such key
has been written yet.
**Expected behavior:** `MemoryStore::get` returns `None`. The source is skipped (omitted from
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
load returns `Err(FerrochainError { ... })` due to a storage I/O failure.
**Expected behavior:** The error propagates from `graph::scheduler` to the caller; the run
does NOT start. `Err(FerrochainError { category: DURABILITY, ... })` (the propagated storage
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

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `ContextMutationConfig { sources: [{ ns: "agent", key: "SOUL.md" }] }`; "SOUL.md" = "You are a helpful agent."; run invoked | First super-step sees "You are a helpful agent." prepended to system instruction | Happy-path: source loaded |
| TV-002 | Same config; "SOUL.md" key absent in MemoryStore | Run proceeds with no prepend; no error | Absent source silently skipped |
| TV-003 | "MEMORY.md" = "Fact A"; run starts; super-step 1 writes "Fact A; Fact B" to MEMORY.md; super-step 2 executes | Super-step 2 context still has "Fact A" (frozen at run start) | Frozen snapshot: mid-run write invisible |
| TV-004 | Run 1 writes "Fact B" to MEMORY.md; Run 2 starts with same config | Run 2 context prepend includes "Fact B" | Next-run visibility |
| TV-005 | `context_mutations = None` | No prepend; run executes as before | Opt-out path |
| TV-006 | Storage I/O error during pre-run load | `Err(FerrochainError { category: DURABILITY })` from `invoke`; run does not start | Storage failure halts run before first super-step |

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

- `ferrochain-core/src/context_mutation.rs` (`core::context_mutation`) — `ContextSourceSpec` struct `{ namespace: String, key: String }`; `ContextMutationConfig` struct `{ sources: Vec<ContextSourceSpec> }`; `RunnableConfig.context_mutations: Option<ContextMutationConfig>` (per ADR-012 Decision 1, Primitive B)
- `ferrochain-graph/src/pregel/scheduler.rs` (`graph::scheduler`) — pre-first-super-step load: iterates `ContextMutationConfig.sources`, calls `MemoryStore::get` per source, prepends loaded content to initial context; no new module row (added behavior of existing scheduler module per ADR-012 Decision 4)
- ADR-012 §Decision 3 — frozen-snapshot semantics adopted; live mutation rejected; ADR-012 INV-1 (cache-coherence invariant)
- ADR-011 — cache-key obligation: loaded context bytes must be included in system-instruction hash input

## Story Anchor

_[to be filled after story decomposition]_

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
| Module | ferrochain-core (`core::context_mutation` — types) / ferrochain-graph (`graph::scheduler` — loading behavior) |
