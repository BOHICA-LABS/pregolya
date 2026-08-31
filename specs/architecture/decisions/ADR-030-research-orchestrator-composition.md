---
document_type: adr
level: L3
adr_id: "030"
slug: research-orchestrator-composition
title: "Praxist-Pattern Research Orchestrator: Use-Case Composition Architecture and Additive Library Primitives"
status: accepted
date: "2026-08-31"
producer: architect
timestamp: 2026-08-31T00:00:00Z
version: "1.1"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
superseded_by: null
subsystems_affected: ["SS-02", "SS-04"]
changelog:
  - "1.1 (ADR-030 Stage-4-ruling/2026-08-31): §Consequences BC reservation table patched per architect subsystem ruling. BC-2.02.008 row updated to reflect actual PO authoring (LedgerChannel first-appearance ordering); BC-2.02.009 row added for PromoteRetireChannel Lifecycle Semantics (displaced from BC-2.02.008 by PO Stage 2a deviation). BC-2.04.011 row unchanged — retains Trajectory Compaction Isolation (SS-04) original intent. SS-02 BC range text updated 001–008 → 001–009. Total new BCs 5→6."
  - "1.0 (ADR-030/2026-08-31): Initial — use-case composition architecture and two additive library primitives (checkpoint::trajectory, ledger channel types in graph::channels). Spawned by human-directed Stage 1 scoping of the praxist-pattern research orchestrator use case."
---

# ADR-030: Praxist-Pattern Research Orchestrator — Composition Architecture and Additive Primitives

**Status:** Accepted — human-directed Stage 1 scoping (2026-08-31)

## Context

The pregolya library is being extended with a new use case: an autonomous
research/experiment-iteration orchestrator inspired by the behavioral pattern of the
Praxist framework (sapientinc/praxist, Fair Source licensed). This ADR establishes:

1. How the full use case is expressed on **existing** pregolya primitives — confirming
   no new product crate is required.
2. Two **additive library primitives** whose designs are settled here and whose BCs
   will be authored by the product-owner in Stage 2: (a) a durable audit-grade
   trajectory record and (b) ledger-style state channels with custom reducers.

**Clean-room posture:** This ADR expresses behavioral inspiration only. No code, prose,
or documentation text from the Praxist codebase or website has been copied, paraphrased,
or reproduced here. Praxist is cited solely as the pattern reference; all design is
expressed natively in pregolya's own types, modules, and conventions.

## Decision 1 — Use-Case Composition on Existing Primitives

The research orchestrator pattern is fully expressible on the current pregolya API surface:

| Pattern element | Mapped pregolya primitive |
|----------------|--------------------------|
| **Generation loop** — repeat research rounds until convergence | `CompiledStateGraph` with a loop-back conditional edge; generation boundary = a checkpoint-committing node invoking `CheckpointSaver::put_writes` |
| **Panel topology** — PI fan-out → cross-review → Chair reducer | Sub-`StateGraph` (nested invocation via `CompiledStateGraph::invoke`); PI nodes fan out via `RunnableParallel`; cross-review and Chair nodes are standard agent nodes; state visibility controlled by channel scoping |
| **Peer / PI / Chair agents** | Agent nodes wrapping `BaseChatModel` via `Runnable<Vec<Message>, AiMessage>`; provider crates `pregolya-openai` / `pregolya-anthropic` / `pregolya-ollama` |
| **DIG gate** (read-only design review before code generation) | Pre-generation node sub-graph composed from read-only tools (ActionRisk::ReadOnly); `InvocationContext` + `GuardrailHook` enforce the read-only invariant; validated-contract result written to a state channel before the generation node is reached |
| **QD allocator** (quality-diversity candidate allocation) | Deterministic pure-function `Runnable` node over candidate descriptor values — no LLM call; deterministic given the same input state |
| **Tools** | `ToolDefinition` + MCP client/server (`mcp::client`, `mcp::server`) + permission gating via `PreToolCallHook` (ADR-018) |
| **Streaming** | `StreamEvent` per ADR-006; budget and guards via `InvocationContext` (ADR-009 / ADR-018) |
| **Evidence accumulation** | Ledger-style state channels (Decision 3 below) as the `StateGraph` channel type for evidence collections |
| **Resume from checkpoint** | Standard `CheckpointSaver` durable-resume path (ADR-003 / SS-04) |

**No new product crate is required.** The composition layer is user-space code built on the
existing pregolya API; it ships as example / documentation, not as a new `pregolya-*` library
crate.

## Decision 2 — Durable Audit-Grade Trajectory Primitive

### Motivation

`StreamEvent` is transient (emitted over a channel, consumed in real time, not persisted). A
research orchestrator requires *durable*, *replayable* event records for reproducibility
audits and experiment replay. This need is structurally different from — and must be isolated
from — the conversation context window that `CheckpointSaver` manages for compaction purposes.

### Design

Following the ADR-009 Option 3 pattern (definitions in pregolya-core; execution in the domain
crate):

**`core::trajectory`** (definitions-only, pregolya-core, SS-04 type definitions):

```rust
/// A single durable record in a run's audit trajectory.
#[non_exhaustive]
pub struct TrajectoryRecord {
    pub run_id: Uuid,
    pub step_idx: u64,              // logical-clock position (from checkpoint::clock)
    pub event_kind: String,         // e.g., "generation_complete", "peer_result"
    pub payload: serde_json::Value, // structured payload; no credential material
}

/// Durable write path for audit-grade trajectory records (SS-04 type definitions).
#[async_trait]
pub trait TrajectoryWriter: Send + Sync {
    async fn put_record(&self, record: TrajectoryRecord) -> Result<(), PregolyaError>;
}

/// Replay path for audit-grade trajectory records.
#[async_trait]
pub trait TrajectoryReader: Send + Sync {
    async fn replay(&self, run_id: Uuid) -> Result<Vec<TrajectoryRecord>, PregolyaError>;
}
```

**`checkpoint::trajectory`** (execution, pregolya-checkpoint, SS-04):
Concrete `impl TrajectoryWriter + TrajectoryReader` backed by the existing
`CheckpointSaver` storage tier (or a co-located storage slice). Trajectory records are
**isolated from compaction**: `ADR-019` compaction targets the conversation context window;
`TrajectoryRecord`s persist regardless of compaction events.

### Module placement

- `core::trajectory` — definitions-only; no criticality-counted row (ADR-009 precedent);
  canonical file `pregolya-core/src/trajectory.rs`; SS-04 type definitions.
- `checkpoint::trajectory` — MEDIUM execution module; canonical file
  `pregolya-checkpoint/src/trajectory.rs`; SS-04; no Kani VP (storage-backed Effectful Shell).

## Decision 3 — Ledger-Style State Channels with Custom Reducers

### Motivation

Evidence collected across research generations needs append-only accumulation with
dedup-idempotency (the same finding from multiple peers must not create duplicates) and a
promote/retire lifecycle (candidates advance through the QD allocation cycle). These reducer
semantics are not covered by the existing `graph::channels` family
(LastValue / Append / BarrierValue / NamedBarrierValue / EphemeralValue).

### Design

Two new channel types are added **within the existing `graph::channels` module** in
pregolya-graph — no new module row is needed.

```rust
/// Marker trait for ledger entries with a stable identity.
/// T must implement LedgerEntry to be stored in LedgerChannel or PromoteRetireChannel.
pub trait LedgerEntry: Clone + Send + Sync + 'static {
    fn entry_id(&self) -> &str;
}

/// Dedup-idempotent append-only channel.
/// Reducing with a T whose entry_id() is novel appends it.
/// Reducing with a T whose entry_id() is already present is a no-op.
/// Channel value: Vec<T> (accumulated; never shrinks).
pub struct LedgerChannel<T: LedgerEntry> { ... }

/// Enum of operations for the promote/retire lifecycle.
#[non_exhaustive]
pub enum PromoteRetireOp<T: LedgerEntry> {
    Promote(T),
    Retire(String), // entry_id of the item to retire
}

/// Active-set channel with idempotent promote/retire operations.
/// Promote adds to active set (idempotent if already present).
/// Retire removes from active set (idempotent if already absent).
/// Channel value: Vec<T> (active set).
pub struct PromoteRetireChannel<T: LedgerEntry> { ... }
```

### VP

`LedgerChannel` dedup-idempotency is a formally provable pure-function reducer property.
**VP-017** (proptest P1, Phase 3) is seeded now:

- Property: for any sequence of `put_record` calls against `LedgerChannel`, the final
  accumulated `Vec<T>` contains exactly the entries with distinct `entry_id` values, in
  first-appearance order.
- Tool: proptest — exercise arbitrary sequences of novel and repeated entries; assert
  idempotency invariant holds for every prefix.
- Module: `graph::channels` | Crate: `pregolya-graph` | BC Anchor: BC-2.02.007

## Decision 4 — Clean-Room Posture

Praxist (sapientinc/praxist, Fair Source FSL-1.1-ALv2) is referenced **by behavioral
pattern only**:

- Pattern vocabulary ("generation loop", "panel", "DIG gate", "QD allocator") describes
  architectural concepts mapped above to pregolya primitives.
- No Praxist source code, documentation text, or configuration has been reproduced.
- The pregolya implementation derives entirely from the pregolya type system, existing BCs,
  and the ADR-009 / ADR-018 / ADR-019 design patterns already committed in this project.
- If a future holdout scenario cites Praxist, it does so only by behavioral description;
  the evaluator may not reference Praxist internals.

## Rationale

### Why no new product crate

The composition layer is application-level orchestration: `CompiledStateGraph` graphs wired
together with channel types and node functions. This is exactly what user code builds with
pregolya. Adding a new library crate for a use-case composition pattern would encode a
specific research-orchestrator opinion into the library surface, creating maintenance
obligations and API versioning risk. Expressing it as example/documentation keeps the library
surface tight.

### Why checkpoint::trajectory separate from StreamEvent

`StreamEvent` is a transient emission type — consumed by SSE clients and dropped. The
trajectory record is a durable, replayable audit artifact. Co-locating the two would require
the streaming layer to take on persistence responsibilities it is not designed for (ADR-006
explicitly scoped streaming to real-time event emission). The ADR-009 definitions-in-core /
execution-in-domain split is the established pregolya pattern for exactly this kind of
durable-but-separable concern.

### Why ledger channels in graph::channels (not a new module)

`graph::channels` is the canonical home for all `StateGraph` channel reducer types. The new
types are channel reducers; they belong in the same module family. Adding a new module for
two related channel types would over-split a cohesive unit. The module row description is
extended to document the new types.

### Why VP-017 proptest (not Kani)

`LedgerChannel::reduce` is a collection transformation over arbitrary-length entry sequences.
Kani's bounded model-checking is well-suited to fixed-structure invariants (arithmetic,
enum-dispatch); proptest with arbitrary entry sequences covers the dedup-idempotency property
more naturally and with lower verification effort. This matches the existing proptest pattern
for collection invariants (VP-007 `core::serializable` round-trip, VP-014 `RunnableParallel`
key-completeness).

## Alternatives Considered

### Alt A: New `pregolya-research` crate

Rejected. Encodes a specific orchestration opinion; creates a new dependency and publication
target; the composition is user-space code that belongs in documentation/examples, not a
library crate.

### Alt B: Trajectory records stored in CheckpointSaver alongside graph state

Rejected. Mixing trajectory records with graph state in the same storage entry makes it
impossible to keep trajectory records isolated from ADR-019 compaction. The trajectory slice
must be addressable independently of the conversation context window.

### Alt C: LedgerChannel implemented as a user-defined type outside pregolya-graph

Rejected. User code cannot implement the `Channel` trait for a type outside `graph::channels`
without a public extension seam that does not yet exist. Adding these types to the canonical
channel family is the correct production-grade path. They are general-purpose reducers that
any StateGraph application can use.

## Source / Origin

- Behavioral inspiration: Praxist framework (sapientinc/praxist, Fair Source FSL-1.1-ALv2).
  Clean-room derivation only; no reproduction of Praxist source or documentation text.
- ADR-009 (Budget Governance Engine Placement) — definitions-in-core / execution-in-domain
  split pattern applied for `core::trajectory` / `checkpoint::trajectory`.
- ADR-006 (Streaming Event Taxonomy) — rationale for trajectory not extending StreamEvent.
- ADR-019 (Rolling Context Compaction) — compaction isolation requirement for trajectory.
- ADR-018 (Per-Tool-Call Approval Hook) — HITL enforcement for DIG gate composition.
- Human-directed Stage 1 scoping, 2026-08-31.

## Consequences

### Positive

- The use case exercises the full pregolya stack depth (checkpointing, HITL, streaming,
  budget governance, MCP, memory, serialization) — a strong integration test target.
- Additive primitives (`checkpoint::trajectory`, ledger channels) have general applicability
  beyond the research orchestrator pattern.
- No new crate = no new crates.io namespace reservation, no new workspace member, no wave
  reprioritization.

### New BCs for Product Owner (Stage 2)

| BC ID | Subsystem | Title (draft) | One-line intent |
|-------|-----------|---------------|-----------------|
| BC-2.04.009 | SS-04 | `TrajectoryWriter::put_record` Durability | A written record is recoverable after process restart |
| BC-2.04.010 | SS-04 | `TrajectoryReader::replay` Logical-Clock Ordering | Replay returns records in ascending step_idx order; complete; deterministic |
| BC-2.04.011 | SS-04 | Trajectory Compaction Isolation | Trajectory records are not pruned by ADR-019 compaction |
| BC-2.02.007 | SS-02 | `LedgerChannel` Dedup-Idempotent Append | VP-017 target; seen entry_id on second write is a no-op |
| BC-2.02.008 | SS-02 | `LedgerChannel` First-Appearance Ordering | Entry order in Vec<T> reflects first-appearance across all super-steps [PO Stage 2a actual authoring] |
| BC-2.02.009 | SS-02 | `PromoteRetireChannel` Lifecycle Semantics | Promote/Retire are each idempotent; active set is the channel value [displaced from BC-2.02.008; see v1.1 changelog] |

SS-04 BC range extends from 001–008 to **001–011**.
SS-02 BC range extends from 001–006 to **001–009** (BC-2.02.009 added; BC-2.02.008 consumed by LedgerChannel first-appearance ordering per PO Stage 2a authoring).
Total new BCs: 6 (two SS-04 trajectory BCs + three SS-02 ledger-channel BCs + one SS-04 trajectory compaction BC).

### New VP

| VP | Module | Tool | Priority | BC Anchor | Phase |
|----|--------|------|----------|-----------|-------|
| VP-017 | `graph::channels` | proptest | P1 | BC-2.02.007 | 3 |

### Architecture Invariants Unchanged

- 21 published crates — no additions.
- `deployment_topology: single-service` — unchanged.
- `graph::channels` module row in module-decomposition.md — extended in-module description; no
  new module row (ledger types are in the same module as the existing channel family).
- ADR-009 definitions-in-core pattern applied for `core::trajectory`; same exemptions apply.
- `checkpoint::trajectory` is an Effectful Shell module (storage I/O); purity-boundary-map
  updated accordingly.
