---
document_type: adr
level: L3
adr_id: "012"
slug: self-improvement-primitives
title: "Self-Improvement Primitives: Skill Registry, Runtime Context Mutation, Guarded Memory Writes (D20)"
status: accepted
date: 2026-07-15
producer: architect
timestamp: 2026-07-15T00:00:00Z
version: "1.10"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D20]
supersedes: null
superseded_by: null
subsystems_affected: [SS-15]
changelog:
  - "1.10 (fix-burst-279/gap-3-B101-empty-app_id/2026-07-28): Correct B101 empty-app_id failure mode: `run_context.app_id` empty MUST return `Err(E-MEMORY-004 NoScopeContext)` — NOT `Ok(None)`. v1.9 incorrectly stated the empty-app_id case silently returns `Ok(None)`. Changed §Decision 1 Amendment F-P175-B101 §Security argument and RunContext `app_id` doc-comment. Fail-loud policy is now symmetric with B102 (SkillStore construction fail-loud). NO-SILENT-EMPTY enforced on both B101 and B102 paths."
  - "1.9 (fix-burst-279/F-P175-B101+F-P175-B102/2026-07-28): Decision 1 Amendment — ContextMutationConfig scope bridge and SkillStore scope encapsulation. B101: `spec.namespace` is a key-namespace prefix, NOT the tenant `app_id`; loading uses `MemoryScope::App(run_context.app_id)` with composite key `{namespace}/{key}` (system-derived tenant identity, not caller-supplied). B102: SkillStore binds `MemoryScope::App(app_id)` at construction time; trait methods remain scopeless; E-MEMORY-004 NoScopeContext raised when no app_id derivable. RunContext gains `app_id: String` field (system-derived, set before first super-step, not overridable via RunnableConfig). E-MEMORY-004 NoScopeContext minted by PO — see routing spec burst-279."
  - "1.8 (fix-burst-276/F-P173-505/2026-07-27): Records hygiene — remove bare commit SHA from v1.6 changelog entry; burst-238 alone is the stable citable anchor (TD-VSDD-091). No semantic change."
  - "1.7 (FIX-BURST-276/F-P173-706/2026-07-27): Forward-amend all three 18-crate roster references to 21-crate: (1) Alternatives Considered Decision 1 table rationale; (2) Decision 4 crate roster count; (3) Rationale closing parenthetical. Add forward-amendment blockquote after Decision 4 crate roster statement. The \"no new crate\" decision holds unchanged under the 21-crate roster; ADR-012 adds no new crate. Roster expanded from 18 to 21 by D21 (+pregolya-prompts, +pregolya-vectorstores) and D23 (+pregolya-tools) — see ARCH-INDEX.md §Canonical Crate Roster."
  - "1.6 (FIX-BURST-274/timestamp-convention/2026-07-26): Restore frozen original-acceptance timestamp per ADR decision-date convention (Gate #28 Rule 5): `timestamp: 2026-07-23T00:00:00Z` → `2026-07-15T00:00:00Z`. Date field already correct at 2026-07-15 (original ADR-012 acceptance date, D20). Timestamp was incorrectly bumped to 2026-07-23 in burst-238."
  - "1.5 (FIX-BURST-268/OBS-P166-A/2026-07-25): De-pin live-body version pin per TD-VSDD-091: Decision 1 body 'bc-authoring-plan.md v2.10' → 'bc-authoring-plan.md §Gate #27 §Key ownership rules' (stable section anchor; guardrail placement canon resides in Gate #27 Key ownership rules table)."
  - "1.4 (burst-238/2026-07-23): Stale-handoff sweep — consolidate Error Codes section: remove stale 'PO must mint E-MEM-NNN' obligation and advisory correction blockquote; rewrite as single past-tense statement (E-MEMORY-007 MemoryWriteGuardDenied already minted per F-P72-02 OBS)."
  - "1.3 (F-P95-01/D18-P84-A/2026-07-17): Reconcile two stale 'budget policy evaluation between super-steps' analogies with BC canon. (1) Primitive B description: 'analogously to how graph::budget evaluates BudgetPolicy between super-steps' → 'analogously to how graph::budget_engine populates RunContext.budget_info at each super-step boundary before task dispatch (BC-2.10.003 PC9) — both are phase-boundary operations, not per-call evaluations'. (2) Decision 3 rationale bullet: 'analogous to budget policy evaluation between super-steps' → 'analogous to graph::budget_engine populating RunContext.budget_info at super-step boundaries before task dispatch — BC-2.10.003 PC9'. Template structure: add date, subsystems_affected, superseded_by, supersedes frontmatter fields; add Rationale, Alternatives Considered, Source / Origin sections."
  - "1.2 (OBS-P77-C/D18-P77-A/2026-07-15): Rename ADR-012 DI-001 → ADR-012 INV-1 (Decision 3 body). DI-NNN is the reserved domain-invariant namespace (DI-001..DI-014); local ADR invariants must use non-DI identifiers. Adjudication D18-P77-A recorded. PO to propagate rename to BC-2.15.006 (lines ~69, ~150) and capabilities-p1-p2.md (~line 111)."
  - "1.1 (F-P72-02/ADR-013/2026-07-15): Reconcile Decision 4 to actual downstream state: headline clarified as ADR-012 scope (33→34); gate #25 updated to note final universe = 35 post-ADR-013 (mcp::server MEDIUM); memory::skills cell corrected from \"No new row\" to \"No new criticality row\" distinguishing structural decomposition row from criticality-counted row; Consequences item 2 clarified \"structural module rows\" to distinguish from criticality rows; Error Codes advisory annotated with actually-minted E-MEMORY-007 (namespace MEMORY, number 007)."
  - "1.0 (D20/2026-07-15): Initial decision: placement of three self-improvement primitives; injection-scanning seam (new MemoryWriteGuard, no BoundaryType amendment); frozen-snapshot semantics; universe 33→34 (+memory::write_guard HIGH row)."
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

**Chosen:** Definitions in pregolya-core / routing + enforcement in pregolya-memory.
Follows the ADR-009 Option 3 split (BudgetPolicy trait in core, BudgetEngine in graph)
and the guardrail placement canon (GuardrailHook trait in pregolya-core, invocation
pipeline in pregolya-graph per bc-authoring-plan.md §Gate #27 §Key ownership rules).

### Primitive A — Skill Registry

**pregolya-memory** gains a new module `memory::skills`
(`pregolya-memory/src/skills.rs`):

```rust
pub struct SkillDescriptor {
    pub name:      String,
    pub namespace: String,  // storage namespace in MemoryStore
    pub key:       String,  // storage key in MemoryStore
    pub tags:      Vec<String>,
}

pub trait SkillStore: Send + Sync {
    async fn load_skill(&self, name: &str) -> Result<Option<String>, PregolyaError>;
    async fn list_skills(&self, tags: &[String]) -> Result<Vec<SkillDescriptor>, PregolyaError>;
    async fn skill_exists(&self, name: &str) -> Result<bool, PregolyaError>;
}
```

`SkillStore` is a routing/lookup overlay over `MemoryStore`. The skill _content_ is stored as
ordinary KV entries in `MemoryStore`; `SkillStore` adds naming, tagging, and load-on-demand
semantics. Write path for skill documents is governed by the guarded write primitives
(Primitive C). `SkillStore` reads are read-only and not subject to the write guard.

Rationale for pregolya-memory (not pregolya-core): `SkillStore` is a storage trait
(async, I/O-bound) — the same category as `MemoryStore` and `CheckpointSaver`. Storage
traits live with their backing layer. Placing a storage trait in pregolya-core would
contradict the pattern established by MemoryStore (pregolya-memory) and CheckpointSaver
(pregolya-checkpoint).

### Primitive B — Runtime Context Mutation

**pregolya-core** gains a new definitions module `core::context_mutation`
(`pregolya-core/src/context_mutation.rs`):

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

`RunnableConfig` (pregolya-core::config) gains:
```rust
pub context_mutations: Option<ContextMutationConfig>,
```

Execution loading is performed by `graph::scheduler` at run start (before the first
super-step begins), analogously to how `graph::budget_engine` populates
`RunContext.budget_info` at each super-step boundary before task dispatch
(BC-2.10.003 PC9) — both are phase-boundary operations, not per-call evaluations.
The loaded content is prepended to the initial context passed to the first
super-step. No new module row is added for the loading behavior — it is a new behavior of
the existing `graph::scheduler` module (same treatment as the HITL interrupt-queue check
added to the orchestrator in ADR-001 rev-1 without a new module row).

### Primitive C — Guarded Memory-Write Contracts

**Two-layer split** following ADR-009 Option 3 precedent:

**pregolya-core** gains a new definitions module `core::write_guard`
(`pregolya-core/src/write_guard.rs`):

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

**pregolya-memory** gains a new enforcement module `memory::write_guard`
(`pregolya-memory/src/write_guard.rs`):

This is the **execution module**: receives every attempted write to a guarded memory
namespace, calls `MemoryWriteGuard::validate()`, and either commits the write, blocks it
with an error, or commits the sanitized payload from `Transform`. Injection scanning
implementations (`MemoryWriteGuard` implementors) are provided by the operator or by
pregolya-memory's built-in scanner.

### Placement Summary

| Primitive | Pure types/trait | Enforcement/routing |
|-----------|-----------------|---------------------|
| Skill registry | — (storage trait → memory directly) | `memory::skills` (pregolya-memory) |
| Context mutation | `core::context_mutation` (pregolya-core) | `graph::scheduler` (existing module, new behavior) |
| Write guard | `core::write_guard` (pregolya-core) | `memory::write_guard` (pregolya-memory, NEW execution module) |

### Alternatives Considered (Decision 1)

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| New crate for self-improvement primitives | REJECT | 21-crate roster is current (ARCH-INDEX canonical roster, ADR-007; expanded from 18 to 21 by D21+D23 — see forward-amendment note in Decision 4). No cross-cutting concern warrants a new crate. |
| All primitive types in pregolya-core (incl. SkillStore) | REJECT | SkillStore is a storage trait (async, I/O-bound, backed by MemoryStore). Storage traits live with their backing layer (MemoryStore → pregolya-memory, CheckpointSaver → pregolya-checkpoint). |
| All primitive traits/types in pregolya-memory | REJECT | MemoryWriteGuard is a pure validation trait. Following guardrail placement canon (GuardrailHook → pregolya-core), pure validation contracts belong in pregolya-core so non-memory consumers can wire guards without a pregolya-memory dep. |
| Definitions in pregolya-core / routing + enforcement in pregolya-memory | **ADOPT** | Consistent with ADR-009 Option 3 and GuardrailHook placement canon. |

### Decision 1 Amendment — ContextMutationConfig Scope Bridge and SkillStore Scope Encapsulation (fix-burst-279)

#### F-P175-B101 — ContextMutationConfig: `spec.namespace` is NOT the tenant identity

**Finding:** The original v1.0 decision text for Primitive B specified that `graph::scheduler`
calls `MemoryStore::memory_get(MemoryScope::App(spec.namespace), &spec.key)`. This places a
caller-supplied content namespace (e.g., "agent", "SOUL.md") into the `app_id` tenancy
partition key, enabling any caller with `ContextMutationConfig` to read from any
application's memory namespace by crafting `spec.namespace`.

**Adjudication — fail-closed redesign:**

`ContextSourceSpec.namespace` is a **key-namespace prefix** — a content classifier scoped
WITHIN a single application's memory space. It is NOT an application identity. The
tenant scope MUST be derived from the system, not from caller-supplied data.

**Corrected loading contract:**

```
MemoryStore::memory_get(
    MemoryScope::App(run_context.app_id),   // system-derived tenant identity
    &format!("{}/{}", spec.namespace, spec.key),  // composite key: namespace prefix + key
)
```

`run_context.app_id` is set by the execution engine before the first super-step. It
cannot be overridden by `RunnableConfig::context_mutations` — the caller controls WHICH
keys to load (via `ContextSourceSpec`), but NOT which application's partition is read from.

**Security argument (fail-closed):** If `run_context.app_id` is empty, the load returns
`Err(E-MEMORY-004 NoScopeContext)` — the call site does NOT silently collapse to
`Ok(None)`. This is a deliberate fail-loud policy: an empty `app_id` means the execution
engine failed to establish a tenant identity before the super-step, which is an engine
error that must be surfaced, not silently ignored by returning no context. If `app_id` is
non-empty but does not match any partition in the MemoryStore, the read returns `Ok(None)`
(no content found in that partition — normal miss, not an error). There is no fallback to
a global or default scope.

**RunContext gains `app_id: String`:**

```rust
pub struct RunContext {
    pub thread_id: Option<Uuid>,
    pub run_id: Uuid,
    pub sub_agent_id: Option<SubAgentId>,
    pub budget_info: Option<BudgetInfo>,
    /// System-derived application identity for memory tenancy.
    /// Set by the execution engine before the first super-step; NOT settable via
    /// `RunnableConfig`. Used as the `app_id` parameter for `MemoryScope::App(app_id)`
    /// in all ContextMutationConfig reads.
    /// Empty string means no application scope — all MemoryScope::App reads return
    /// `Err(E-MEMORY-004 NoScopeContext)`. Do NOT silently return Ok(None).
    pub app_id: String,
}
```

`app_id` is derived from the application's registered identity in the execution
environment (e.g., the API client ID, deployment namespace, or operator-configured
application key). The execution engine sets it; it is opaque to graph nodes and tool calls.

#### F-P175-B102 — SkillStore: scope must be encapsulated at construction, not absent

**Finding:** The original `SkillStore` trait definition has no scope parameter on any
method (`load_skill`, `list_skills`, `skill_exists`). Under BC-2.15.002 EC-001, the
default scope for unscoped MemoryStore reads is Session. A cross-session read of a skill
with no scope context therefore resolves into a session-local partition, returning
`Ok(None)` for all non-current-session skills.

**Adjudication — construction-time scope binding:**

`SkillStore` implementations bind `MemoryScope::App(app_id)` **at construction time**.
The trait methods remain scopeless (callers do not supply scope). The `app_id` is
threaded through the construction path — not exposed in the method surface.

**Corrected SkillStore scope contract:**

```
SkillStore::new(store: Arc<dyn MemoryStore>, app_id: String) -> Result<Self, PregolyaError>
```

If `app_id` is empty or the implementation cannot derive an application scope, it returns
`Err(E-MEMORY-004 NoScopeContext)`. Once constructed with a valid `app_id`, all
`load_skill` / `list_skills` / `skill_exists` calls resolve within
`MemoryScope::App(app_id)`.

**Trait surface is unchanged** — no new scope parameter is added to trait methods. This
preserves the existing trait contract: method callers do not need to know about tenancy.

**E-MEMORY-004 NoScopeContext** (MEMORY namespace, number 004, category SECURITY,
retry_hint Never): minted by PO in the error taxonomy. Used when a SkillStore or
ContextMutationConfig load cannot derive a valid application scope at construction time
or load time respectively. See routing spec burst-279 for the PO mint obligation.

---

## Decision 2 — Injection-Scanning Guard Seam

**Chosen:** New `MemoryWriteGuard` trait in pregolya-core — separate seam from GuardrailHook
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
| New `MemoryWriteGuard` trait in pregolya-core, enforcement in pregolya-memory | **ADOPT** | Clean write-path analog. Pure synchronous validation (no async). Operators inject custom scanners. No BoundaryType amendment. |

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
  for context refreshes (analogous to `graph::budget_engine` populating
  `RunContext.budget_info` at super-step boundaries before task dispatch — BC-2.10.003 PC9).
- Live mutation would require re-assembling the system prompt at arbitrary super-steps,
  invalidating provider caches and making the run non-reproducible from a caching standpoint.

**Cache coherence invariant (ADR-012 INV-1):** Within a single run (invoke/ainvoke
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

**Chosen:** Universe 33 → **34** (ADR-012 scope). One new execution module row added. All other
D20 artifacts are definitions-only. **Final downstream universe: 35** — subsequent ADR-013
adds `mcp::server` MEDIUM (+1 execution row); see ADR-013-mcp-server-module-placement.md.

**Classification per primitive:**

| Artifact | Type | Row decision | Rationale |
|----------|------|-------------|-----------|
| `core::context_mutation` | Pure types (definitions-only) | **No new row** | ContextSourceSpec + ContextMutationConfig are pure structs. Precedent: `core::budget` (BudgetPolicy/TokenUsage/RunContext) is definitions-only with no row (ADR-009 Option 3, D18-P61-C). |
| `core::write_guard` | Pure types + pure trait (definitions-only) | **No new row** | MemoryWriteGuard/MemoryWriteRequest/WriteGuardDecision are pure types/trait. Same precedent as `core::budget`. |
| `memory::skills` | SkillStore trait + routing (storage trait) | **No new criticality row** (structural module-decomposition row added; see Consequences) | Thin routing overlay over MemoryStore reads. Subsumed into `memory::store` note (analogous to `core::budget` definitions note in pregolya-core). No independent execution logic beyond storage delegation. |
| `memory::write_guard` | Execution enforcement (effectful dispatch) | **NEW HIGH row** | Calls `MemoryWriteGuard::validate()` on every write, applies injection scanning, conditionally aborts or sanitizes writes. Security-sensitive write-path enforcement — analogous to `graph::provenance` (HIGH tier, guardrail dispatch) and `sandbox::policy` (MEDIUM tier, sandbox policy enforcement). Security significance of write-path injection prevention warrants HIGH tier. |
| Context loading in `graph::scheduler` | New behavior of existing module | **No new row** | Added behavior to existing `graph::scheduler` module (run-start hook). No new module created. |

**Gate #25 declaration (ADR-012 scope):** Module universe after ADR-012 = **34**
(9 CRITICAL + 13 HIGH + 10 MEDIUM + 2 LOW). **Post-ADR-013 final universe: 35**
(9 CRITICAL + 13 HIGH + 11 MEDIUM + 2 LOW) — `mcp::server` MEDIUM (+1 execution row)
attributed to ADR-013-mcp-server-module-placement.md.

**Crate roster:** 21 published crates — **unchanged by ADR-012**. All D20 primitives
reside in existing crates (pregolya-core, pregolya-memory). No new crate.

> **Forward Amendment (FIX-BURST-276, 2026-07-27):** The roster at ADR-012 acceptance
> time was 18 published crates. The roster has since expanded to **21 published crates**
> by D21 (+pregolya-prompts, +pregolya-vectorstores) and D23 (+pregolya-tools). The
> "no new crate" decision holds under the current 21-crate roster — ADR-012 adds no new
> crate regardless of the roster count. **See ARCH-INDEX.md §Canonical Crate Roster as
> the authoritative source of truth.**

### Alternatives Considered (Decision 4)

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| All D20 modules add criticality rows (+4 rows, universe 37) | REJECT | Pure-type definitions (core::context_mutation, core::write_guard, memory::skills) have no execution logic; inflates count against ADR-009 precedent. |
| No new rows (universe stays 33, all via notes) | REJECT | memory::write_guard IS a new security-significant execution module with injection scanning enforcement; analogous to graph::provenance (HIGH) which has its own row. |
| One new HIGH row for memory::write_guard; definitions-only notes for the rest | **ADOPT** | Universe 33→34; consistent with ADR-009 definitions-note/execution-row precedent. |

---

## Rationale

D20 promotes self-improvement primitives to framework scope. The ADR-009 Option 3 split pattern (pure-trait definitions in pregolya-core, effectful engine in the domain crate) is applied consistently: context-mutation types and write-guard types are pure-core, while enforcement and routing live in pregolya-memory. The frozen-snapshot semantics for ContextMutationConfig preserve provider prompt-prefix caching (ADR-011 cache-key contract) and are consistent with Hermes MEMORY.md stable-tier semantics. The new `MemoryWriteGuard` seam is architecturally separate from `GuardrailHook`/`BoundaryType` to avoid conflating ingress-path safety with write-path safety. Module-criticality growth is minimal: only `memory::write_guard` earns a new HIGH row; definition-only modules follow the `core::budget` precedent.

## Alternatives Considered

See `### Alternatives Considered (Decision N)` subsections in each Decision section above for full per-decision alternative analysis. At the top level: the key rejected paths were (a) placing everything in a new crate (rejected — 21-crate roster; no cross-cutting concern warrants addition), (b) live context mutation (rejected — cache-invalidation), and (c) extending BoundaryType for write-path guards (rejected — conflates ingress and write paths).

## Consequences

### Module-Decomposition Changes

1. pregolya-core gains a **self-improvement definitions note** (no new table rows):
   - `core::context_mutation` (`pregolya-core/src/context_mutation.rs`): ContextSourceSpec, ContextMutationConfig
   - `core::write_guard` (`pregolya-core/src/write_guard.rs`): MemoryWriteRequest, MemoryWriteGuard trait, WriteGuardDecision
2. pregolya-memory gains two new **structural** module rows in module-decomposition.md
   (`memory::skills` does NOT earn a criticality-counted row per Decision 4 table above;
   only `memory::write_guard` earns a criticality row):
   - `memory::skills` (structural decomposition row, MEDIUM tier classification, SS-15): SkillStore trait + SkillDescriptor, skill load-on-demand routing
   - `memory::write_guard` (HIGH, SS-15, **criticality-counted**): guarded write enforcement engine, injection scanning dispatch

### PO Anchors (Exact Paths for CAP/BC Authoring)

| Primitive | Crate | Module path | Trait/types | SS |
|-----------|-------|-------------|------------|-----|
| Skill registry | pregolya-memory | `pregolya-memory/src/skills.rs` (`memory::skills`) | `SkillStore`, `SkillDescriptor` | SS-15 |
| Context mutation | pregolya-core | `pregolya-core/src/context_mutation.rs` (`core::context_mutation`) | `ContextSourceSpec`, `ContextMutationConfig`; `RunnableConfig.context_mutations: Option<ContextMutationConfig>` | SS-01 (config seam) + SS-15 (memory source) |
| Write guard (types/trait) | pregolya-core | `pregolya-core/src/write_guard.rs` (`core::write_guard`) | `MemoryWriteGuard`, `MemoryWriteRequest`, `WriteGuardDecision` | SS-15 |
| Write guard (enforcement) | pregolya-memory | `pregolya-memory/src/write_guard.rs` (`memory::write_guard`) | guarded write engine | SS-15 |

### Error Codes

`E-MEMORY-007 MemoryWriteGuardDenied` is the authoritative error code for `MemoryWriteGuard::Deny` (category: SECURITY, retry_hint: Never; minted by PO per bc-authoring-plan.md error-taxonomy ownership, F-P72-02 OBS). Namespace prefix `MEMORY`, number `007`.

### RunContext Field Addition (fix-burst-279)

`RunContext` gains a new `app_id: String` field per the Decision 1 Amendment above
(F-P175-B101). This field is set by the execution engine (`graph::scheduler`) before the
first super-step and is not accessible to `RunnableConfig` callers. Its presence in
`RunContext` is required for correct `MemoryScope::App(app_id)` resolution during
`ContextMutationConfig` loading and `SkillStore` construction.

**Downstream propagation obligation:** All code that constructs `RunContext` must supply
`app_id`. The field has no default — an empty `String` is the explicit "no-scope" sentinel.
PO must update BC-2.15.006 to reflect the corrected loading contract (namespace as
key-prefix, not as `app_id`). See routing spec burst-279.

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

## Source / Origin

- **D20 human authority** — promotes self-improvement and self-learning loop to framework-scope primitives per D19 holdout-domain brief (domain-d-hermes-agent.md req 3 + req 4).
- **ADR-009 Option 3** — trait-in-core / engine-in-domain split pattern applied to all three primitives.
- **BC-2.15.001–006** — behavioral contracts for SS-15 Long-Horizon Memory; write-guard enforcement and skill-registry loading are contractual obligations specified there.
- **BC-2.10.003 PC9** — `RunContext.budget_info` population at super-step boundaries (analogy for frozen-snapshot load-at-run-start model).
- **ADR-011** — cache-key contract that frozen-snapshot semantics must respect.
