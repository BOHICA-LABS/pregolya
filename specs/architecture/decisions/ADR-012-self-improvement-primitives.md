---
document_type: adr
level: L3
adr_id: "012"
slug: self-improvement-primitives
title: "Self-Improvement Primitives: Skill Registry, Runtime Context Mutation, Guarded Memory Writes (D20)"
status: accepted
producer: architect
timestamp: 2026-07-15T00:00:00Z
version: "1.0"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D20]
---

# ADR-012: Self-Improvement Primitives

**Status:** Accepted — D20 human authority

## Context

D19 holdout-domain brief (domain-d-hermes-agent.md) classified layered system-prompt
composition (req 3) and runtime-mutable procedural skills (req 4) as `[NEW
application-layer]`. D20 human decision overrides that disposition: the self-improvement
and self-learning loop is promoted to **framework-scope primitives**. Three primitives
are in scope:

(a) **Skill registry** — load skill documents into agent context on demand (agentskills.io
    SKILL.md pattern); agent can also write/update skill files at runtime.
(b) **Runtime context mutation** — agent-written artifacts update the system-prompt context
    seen by subsequent runs; must preserve prompt-prefix caching.
(c) **Guarded memory-write tool contracts** — add/replace/remove semantics with injection
    scanning; prevents prompt-injection via agent-controlled memory writes.

This ADR decides four questions:
1. Which crate and module owns each primitive?
2. Where does the injection-scanning guard live (new seam vs BoundaryType extension)?
3. What are the context-mutation semantics (frozen-snapshot vs live)?
4. Does this change the module-criticality universe (gate #25)?

---

## Decision 1 — Placement

**Chosen:** Definitions in ferrochain-core / routing + enforcement in ferrochain-memory.
Follows the ADR-009 Option 3 split (BudgetPolicy trait in core, BudgetEngine in graph)
and the guardrail placement canon (GuardrailHook trait in ferrochain-core, invocation
pipeline in ferrochain-graph per bc-authoring-plan.md v2.10).

### Primitive A — Skill Registry

**ferrochain-memory** gains a new module `memory::skills`
(`ferrochain-memory/src/skills.rs`):

```rust
pub struct SkillDescriptor {
    pub name:      String,
    pub namespace: String,  // storage namespace in MemoryStore
    pub key:       String,  // storage key in MemoryStore
    pub tags:      Vec<String>,
}

pub trait SkillStore: Send + Sync {
    async fn load_skill(&self, name: &str) -> Result<Option<String>, FerrochainError>;
    async fn list_skills(&self, tags: &[String]) -> Result<Vec<SkillDescriptor>, FerrochainError>;
    async fn skill_exists(&self, name: &str) -> Result<bool, FerrochainError>;
}
```

`SkillStore` is a routing/lookup overlay over `MemoryStore`. The skill _content_ is stored as
ordinary KV entries in `MemoryStore`; `SkillStore` adds naming, tagging, and load-on-demand
semantics. Write path for skill documents is governed by the guarded write primitives
(Primitive C). `SkillStore` reads are read-only and not subject to the write guard.

Rationale for ferrochain-memory (not ferrochain-core): `SkillStore` is a storage trait
(async, I/O-bound) — the same category as `MemoryStore` and `CheckpointSaver`. Storage
traits live with their backing layer. Placing a storage trait in ferrochain-core would
contradict the pattern established by MemoryStore (ferrochain-memory) and CheckpointSaver
(ferrochain-checkpoint).

### Primitive B — Runtime Context Mutation

**ferrochain-core** gains a new definitions module `core::context_mutation`
(`ferrochain-core/src/context_mutation.rs`):

```rust
/// Specifies one memory item to inject into the system-prompt context at run start.
pub struct ContextSourceSpec {
    pub namespace: String,
    pub key:       String,
}

/// Declares which memory items are loaded into the context at the start of a run.
/// Attached to `RunnableConfig`. Loaded by `graph::scheduler` before the first super-step.
pub struct ContextMutationConfig {
    pub sources: Vec<ContextSourceSpec>,
}
```

`RunnableConfig` (ferrochain-core::config) gains:
```rust
pub context_mutations: Option<ContextMutationConfig>,
```

Execution loading is performed by `graph::scheduler` at run start (before the first
super-step begins), analogously to how `graph::budget` evaluates `BudgetPolicy` between
super-steps. The loaded content is prepended to the initial context passed to the first
super-step. No new module row is added for the loading behavior — it is a new behavior of
the existing `graph::scheduler` module (same treatment as the HITL interrupt-queue check
added to the orchestrator in ADR-001 rev-1 without a new module row).

### Primitive C — Guarded Memory-Write Contracts

**Two-layer split** following ADR-009 Option 3 precedent:

**ferrochain-core** gains a new definitions module `core::write_guard`
(`ferrochain-core/src/write_guard.rs`):

```rust
pub enum MemoryWriteRequest {
    Add     { namespace: String, key: String, value: Value },
    Replace { namespace: String, key: String, old_value: Option<Value>, new_value: Value },
    Remove  { namespace: String, key: String },
}

pub enum WriteGuardDecision {
    Allow,
    Deny      { reason: String },
    Transform { sanitized: Value },
}

/// Pure synchronous validation contract. No async, no I/O.
pub trait MemoryWriteGuard: Send + Sync {
    fn validate(&self, req: &MemoryWriteRequest) -> WriteGuardDecision;
}
```

**ferrochain-memory** gains a new enforcement module `memory::write_guard`
(`ferrochain-memory/src/write_guard.rs`):

This is the **execution module**: receives every attempted write to a guarded memory
namespace, calls `MemoryWriteGuard::validate()`, and either commits the write, blocks it
with an error, or commits the sanitized payload from `Transform`. Injection scanning
implementations (`MemoryWriteGuard` implementors) are provided by the operator or by
ferrochain-memory's built-in scanner. The built-in scanner checks for prompt-injection
patterns (role-injection prefixes, instruction-override markers).

### Placement Summary

| Primitive | Pure types/trait | Enforcement/routing |
|-----------|-----------------|---------------------|
| Skill registry | — (storage trait → memory directly) | `memory::skills` (ferrochain-memory) |
| Context mutation | `core::context_mutation` (ferrochain-core) | `graph::scheduler` (existing module, new behavior) |
| Write guard | `core::write_guard` (ferrochain-core) | `memory::write_guard` (ferrochain-memory, NEW execution module) |

### Alternatives Considered (Decision 1)

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| New crate for self-improvement primitives | REJECT | 18-crate roster is frozen (ARCH-INDEX canonical roster, ADR-007). No cross-cutting concern warrants a new crate. |
| All primitive types in ferrochain-core (incl. SkillStore) | REJECT | SkillStore is a storage trait (async, I/O-bound, backed by MemoryStore). Storage traits live with their backing layer (MemoryStore → ferrochain-memory, CheckpointSaver → ferrochain-checkpoint). |
| All primitive traits/types in ferrochain-memory | REJECT | MemoryWriteGuard is a pure validation trait. Following guardrail placement canon (GuardrailHook → ferrochain-core), pure validation contracts belong in ferrochain-core so non-memory consumers can wire guards without a ferrochain-memory dep. |
| Definitions in ferrochain-core / routing + enforcement in ferrochain-memory | **ADOPT** | Consistent with ADR-009 Option 3 and GuardrailHook placement canon. |

---

## Decision 2 — Injection-Scanning Guard Seam

**Chosen:** New `MemoryWriteGuard` trait in ferrochain-core — separate seam from GuardrailHook
and BoundaryType. BoundaryType stays exactly 3 variants (ToolResult | RAGRetrieval |
MemoryIngress). **No canon amendment to PASS-58 is required.**

**Rationale:**

BoundaryType governs **INGRESS** (external content entering the model context, **read path**).
Memory writes are on the **write path** (agent → store). These are architecturally orthogonal:

| Seam | Direction | Input shape | Decision shape |
|------|-----------|------------|----------------|
| `GuardrailHook` / BoundaryType | External content → model context | `IngressContent` (ToolResult/RagChunk/MemoryItem) | Pass/Fail/Transform |
| `MemoryWriteGuard` | Agent → memory store | `MemoryWriteRequest` (Add/Replace/Remove) | Allow/Deny/Transform |

Extending BoundaryType to include a MemoryWrite variant would:
1. Require a canon amendment (PASS-58 states exactly 3 variants, verified in entities-server.md §ProvenanceTag and BC-2.11.001 EC-004).
2. Conflate ingress safety (protecting model context from malicious external content) with write safety (preventing agent from injecting malicious content into its own memory).
3. Force the GuardrailHook interface to accept `MemoryWriteRequest` inputs via type erasure — incompatible with the existing `IngressContent` parameter shape.

**BoundaryType amendment status:** None required. BoundaryType = `ToolResult | RAGRetrieval | MemoryIngress` is unchanged.

### Alternatives Considered (Decision 2)

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| Extend BoundaryType with `MemoryWrite` variant (4 variants) | REJECT | Requires explicit PASS-58 canon amendment; conflates ingress-path and write-path safety; BoundaryType is scoped to `ProvenanceTag` fields that tag ingress events, not write operations. |
| Reuse GuardrailHook at a new MemoryWrite boundary (BoundaryType extension) | REJECT | Shares REJECT above; additionally, GuardrailHook::evaluate takes IngressContent — incompatible with write-operation semantics (Add/Replace/Remove). Forcing MemoryWriteRequest into IngressContent would require type erasure or a new variant (triggering BoundaryType + IngressContent amendments simultaneously). |
| Write-path validation inline in `MemoryStore::put` (no injection point) | REJECT | Embeds security policy in the storage layer; untestable and non-extensible; operators cannot register custom injection scanners without forking MemoryStore. |
| New `MemoryWriteGuard` trait in ferrochain-core, enforcement in ferrochain-memory | **ADOPT** | Clean write-path analog. Pure synchronous validation (no async). Operators inject custom scanners. No BoundaryType amendment. |

---

## Decision 3 — Context Mutation Semantics

**Chosen:** Frozen-snapshot.

Writes to guarded memory namespaces (SKILL.md, MEMORY.md content) take effect in
**MemoryStore immediately** during the current run. However, `ContextMutationConfig`
sources are **loaded once at run start** (before the first super-step) and do not
change during the run. Context updates from the current run are visible to the **next**
run when a fresh `ContextMutationConfig` load occurs.

**Rationale:**
- Preserves prompt-prefix caching: the system-prompt prefix is assembled once at run
  start and remains stable throughout the run. Provider-side prefix caching (Anthropic
  cache_control, OpenAI system message caching) is not invalidated mid-run.
- Parity with Hermes MEMORY.md / SOUL.md stable-tier semantics: frozen tiers prevent
  cache churn during a run.
- Consistent with BSP super-step model: between-run updates are the natural boundary
  for context refreshes (analogous to budget policy evaluation between super-steps).
- Live mutation would require re-assembling the system prompt at arbitrary super-steps,
  invalidating provider caches and making the run non-reproducible from a caching standpoint.

**Cache coherence invariant (ADR-012 DI-001):** Within a single run (invoke/ainvoke
call), the context assembled from `ContextMutationConfig` sources is immutable. Any
memory write performed during the run does not affect the context of that run.

### Alternatives Considered (Decision 3)

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| Live mutation (mid-run context update on every memory write) | REJECT | Invalidates prompt-prefix cache on every write during a run; incompatible with provider caching contracts (NE-05 content-hash cache-key contract, ADR-011); no Hermes reference for live stable-tier mutation. |
| Frozen-snapshot with explicit flush command (operator-triggered reload mid-run) | PARTIAL-REJECT | Adds API complexity for marginal v1 benefit; the flush pattern can be added post-v1 as a new ContextMutationConfig option without breaking the frozen-snapshot default. |
| Frozen-snapshot (context loaded at run start; writes visible on next run) | **ADOPT** | Cache-coherent; Hermes-compatible; BSP-natural. |

---

## Decision 4 — Module-Criticality Universe (Gate #25)

**Chosen:** Universe 33 → **34**. One new execution module row added. All other
D20 artifacts are definitions-only.

**Classification per primitive:**

| Artifact | Type | Row decision | Rationale |
|----------|------|-------------|-----------|
| `core::context_mutation` | Pure types (definitions-only) | **No new row** | ContextSourceSpec + ContextMutationConfig are pure structs. Precedent: `core::budget` (BudgetPolicy/TokenUsage/RunContext) is definitions-only with no row (ADR-009 Option 3, D18-P61-C). |
| `core::write_guard` | Pure types + pure trait (definitions-only) | **No new row** | MemoryWriteGuard/MemoryWriteRequest/WriteGuardDecision are pure types/trait. Same precedent as `core::budget`. |
| `memory::skills` | SkillStore trait + routing (storage trait) | **No new row** | Thin routing overlay over MemoryStore reads. Subsumed into `memory::store` note (analogous to `core::budget` definitions note in ferrochain-core). No independent execution logic beyond storage delegation. |
| `memory::write_guard` | Execution enforcement (effectful dispatch) | **NEW HIGH row** | Calls `MemoryWriteGuard::validate()` on every write, applies injection scanning, conditionally aborts or sanitizes writes. Security-sensitive write-path enforcement — analogous to `graph::provenance` (HIGH tier, guardrail dispatch) and `sandbox::policy` (MEDIUM tier, sandbox policy enforcement). Security significance of write-path injection prevention warrants HIGH tier. |
| Context loading in `graph::scheduler` | New behavior of existing module | **No new row** | Added behavior to existing `graph::scheduler` module (run-start hook). No new module created. |

**Gate #25 declaration:** Module universe after D20 = **34**
(9 CRITICAL + 13 HIGH + 10 MEDIUM + 2 LOW).

**Crate roster:** 18 published crates — **unchanged confirmed**. All D20 primitives
reside in existing crates (ferrochain-core, ferrochain-memory). No new crate.

### Alternatives Considered (Decision 4)

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| All D20 modules add criticality rows (+4 rows, universe 37) | REJECT | Pure-type definitions (core::context_mutation, core::write_guard, memory::skills) have no execution logic; inflates count against ADR-009 precedent. |
| No new rows (universe stays 33, all via notes) | REJECT | memory::write_guard IS a new security-significant execution module with injection scanning enforcement; analogous to graph::provenance (HIGH) which has its own row. |
| One new HIGH row for memory::write_guard; definitions-only notes for the rest | **ADOPT** | Universe 33→34; consistent with ADR-009 definitions-note/execution-row precedent. |

---

## Consequences

### Module-Decomposition Changes

1. ferrochain-core gains a **self-improvement definitions note** (no new table rows):
   - `core::context_mutation` (`ferrochain-core/src/context_mutation.rs`): ContextSourceSpec, ContextMutationConfig
   - `core::write_guard` (`ferrochain-core/src/write_guard.rs`): MemoryWriteRequest, MemoryWriteGuard trait, WriteGuardDecision
2. ferrochain-memory gains two new module rows:
   - `memory::skills` (MEDIUM, SS-15): SkillStore trait + SkillDescriptor, skill load-on-demand routing
   - `memory::write_guard` (HIGH, SS-15): guarded write enforcement engine, injection scanning dispatch

### PO Anchors (Exact Paths for CAP/BC Authoring)

| Primitive | Crate | Module path | Trait/types | SS |
|-----------|-------|-------------|------------|-----|
| Skill registry | ferrochain-memory | `ferrochain-memory/src/skills.rs` (`memory::skills`) | `SkillStore`, `SkillDescriptor` | SS-15 |
| Context mutation | ferrochain-core | `ferrochain-core/src/context_mutation.rs` (`core::context_mutation`) | `ContextSourceSpec`, `ContextMutationConfig`; `RunnableConfig.context_mutations: Option<ContextMutationConfig>` | SS-01 (config seam) + SS-15 (memory source) |
| Write guard (types/trait) | ferrochain-core | `ferrochain-core/src/write_guard.rs` (`core::write_guard`) | `MemoryWriteGuard`, `MemoryWriteRequest`, `WriteGuardDecision` | SS-15 |
| Write guard (enforcement) | ferrochain-memory | `ferrochain-memory/src/write_guard.rs` (`memory::write_guard`) | guarded write engine | SS-15 |

### Error Codes

Guarded write failures require a new error code in the MEMORY namespace. PO must mint
`E-MEM-NNN` (category: SECURITY, retry_hint: Never) for `MemoryWriteGuard::Deny`.
Naming suggestion: `E-MEM-004 MemoryWriteGuardDenied` — PO has final authority per
bc-authoring-plan.md error-taxonomy ownership.

### Cache-Key Obligation (ADR-011)

`ContextMutationConfig` source content is loaded from `MemoryStore` and may be included
in the assembled system instruction. Per ADR-011, any cache-key computation over the
assembled system prompt MUST include the loaded context-mutation content in the hash
input (it is part of the resolved instruction bytes). Implementors must not cache on a
key computed before context-mutation injection.

### BoundaryType (PASS-58) — No Change

`BoundaryType` = `ToolResult | RAGRetrieval | MemoryIngress` — **3 variants, unchanged**.
No amendment to PASS-58 canon. The write-path guard (`MemoryWriteGuard`) is a separate
seam that does not interact with `ProvenanceTag`, `GuardrailHook`, or `BoundaryType`.

---

## Changelog

| Version | Date | Author | References | Summary |
|---------|------|--------|------------|---------|
| 1.0 | 2026-07-15 | architect | D20 | Initial decision: placement of three self-improvement primitives; injection-scanning seam (new MemoryWriteGuard, no BoundaryType amendment); frozen-snapshot semantics; universe 33→34 (+memory::write_guard HIGH row). |
