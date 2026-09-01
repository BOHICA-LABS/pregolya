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
version: "1.4"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
superseded_by: null
subsystems_affected: ["SS-02", "SS-04"]
changelog:
  - "1.4 (round-52/F-P2A217-02/2026-08-31): Decision 1 panel-topology row: removed holdout-disclosing phrase '(used in HS-D-002) is a standard node function that reads the full state and returns a projected subset' — disclosed the solution of sealed HS-D-002 by name; replaced with general library statement: 'author-metadata projection is user-space node logic'. No architectural content changed; the general statement is accurate and non-disclosing."
  - "1.3 (round-51/F-P2A212-01+F-P2A212-02+F-P2A212-03+F-P2A215-02+F-P2A215-03/2026-08-31): Decision 2: TrajectoryRecord::new() constructor added to code block (F-P2A212-01 — #[non_exhaustive] cross-crate construction fix; SqliteTrajectoryStore/pregolya-checkpoint callers unblocked); TrajectoryRetentionPolicy::new() note added (same fix). Decision 3: LedgerEntry code block bound corrected to Serialize+DeserializeOwned supertrait (F-P2A212-02 — code block was Clone+Send+Sync only, contradicting §Serialization Bound); §Serialization Bound Product-owner directive rewritten to T: LedgerEntry supertrait-only form (F-P2A212-03 — old text prescribed use-site T: LedgerEntry + Serialize + DeserializeOwned, contradicting F-P2A208-11); Default impls added for LedgerChannel<T>/PromoteRetireChannel<T> (F-P2A212-01 channel-marker defensive correctness; registration seam is type-level). §Decision 3 §VP: 'put_record' corrected to 'reduce'; BC Anchor extended to BC-2.02.007 + BC-2.02.008 (F-P2A215-02). §Consequences New-BCs table: BC-2.04.010 title corrected to canonical H1 'TrajectoryReader::replay Ascending step_idx Order' (F-P2A215-03)."
  - "1.2 (round-50/F-P2A209-01+F-P2A209-04+F-P2A211-06+F-P2A211-07+F-P2A211-09+F-P2A210-02+F-P2A208-09/2026-08-31): Decision 2: at-rest confidentiality decision added (Option A — route through EncryptedSerializer when configured; F-P2A209-01/CWE-311); SQLite topology pinned (same database file, dedicated trajectory_records table, WAL, bounded-batch compaction; F-P2A209-04); uuid serde feature noted (F-P2A208-09). Decision 3: LedgerEntry serde bound decision added (Serialize+DeserializeOwned on LedgerEntry trait; F-P2A211-07). Decision 1: panel-visibility wording corrected — no per-node channel-scoping primitive; realizable pattern is explicit transform node (F-P2A211-09). §Consequences New-VP table: VP-018 proptest P1 + VP-019 integration P1 rows added (F-P2A211-06/F-P2A210-03). §Renumber-provenance: canonical BC-2.02.009 creation narrative added (new creation, not renumber; F-P2A210-02)."
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
| **Panel topology** — PI fan-out → cross-review → Chair reducer | Sub-`StateGraph` (nested invocation via `CompiledStateGraph::invoke`); PI nodes fan out via `RunnableParallel`; cross-review and Chair nodes are standard agent nodes; author-metadata stripping is implemented as an explicit transform node that projects the state map — no per-node channel-visibility-scoping primitive exists in the pregolya API; author-metadata projection is user-space node logic |
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
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TrajectoryRecord {
    pub run_id: Uuid,
    pub step_idx: u64,              // logical-clock position (from checkpoint::clock)
    pub event_kind: String,         // e.g., "generation_complete", "peer_result"
    pub payload: serde_json::Value, // structured payload; no credential material
}

impl TrajectoryRecord {
    /// Construct a trajectory record for cross-crate use.
    /// Required because `#[non_exhaustive]` prevents struct-literal construction
    /// outside `pregolya-core` (e.g., `SqliteTrajectoryStore` in `pregolya-checkpoint`).
    pub fn new(
        run_id: Uuid,
        step_idx: u64,
        event_kind: impl Into<String>,
        payload: serde_json::Value,
    ) -> Self {
        TrajectoryRecord { run_id, step_idx, event_kind: event_kind.into(), payload }
    }
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

**`TrajectoryRetentionPolicy`** (also `core::trajectory`, `pregolya-core`) requires a constructor
for the same reason: `#[non_exhaustive]` blocks struct-literal construction outside `pregolya-core`.
`TrajectoryCompactor` callers (in `pregolya-checkpoint`) pass a `TrajectoryRetentionPolicy` and
must be able to construct it. See interface-definitions §Trajectory Primitive for the full struct
definition; the canonical constructor is:
`pub fn new(retention_frontier: u64, promoted: Vec<u64>) -> Self`

**`checkpoint::trajectory`** (execution, pregolya-checkpoint, SS-04):
Concrete `impl TrajectoryWriter + TrajectoryReader` backed by the existing
`CheckpointSaver` storage tier (or a co-located storage slice). Trajectory records are
**isolated from compaction**: `ADR-019` compaction targets the conversation context window;
`TrajectoryRecord`s persist regardless of compaction events.

### At-Rest Confidentiality Decision (F-P2A209-01)

**Decision:** Option A — route trajectory writes through the same `EncryptedSerializer` as
`CheckpointSaver` when configured.

The `checkpoint::trajectory` concrete implementation receives an
`Option<Arc<dyn Serializer + Send + Sync>>` at construction via Arc-DI (CLAUDE.md §Arc-DI wiring
per constructor). When an `EncryptedSerializer` is provided, `put_record` serializes the
`TrajectoryRecord::payload` through the same serializer instance before persisting to SQLite.
When no serializer is provided, trajectory records are stored plaintext (opt-in model — no
fail-closed guard for the no-serializer case). This is consistent with the established
`EncryptedSerializer` posture in `BC-2.04.007 {INV-003}` and the fail-closed `E-CHKPT-010`
precedent. **Product-owner:** add `BC-2.04.009 {INV-002}` — "When `EncryptedSerializer` is
configured, `put_record` encrypts the record payload before storage."

### SQLite Topology Decision (F-P2A209-04)

**Decision:** Trajectory records reside in a **dedicated `trajectory_records` table** within the
**same SQLite database file** as `CheckpointSaver` (the "co-located storage slice" interpretation
of the §Design text above).

Isolation model:
- **Record-level table isolation:** no FK joins between `checkpoint_*` tables and `trajectory_records`.
- **WAL mode:** both `CheckpointSaver` and `TrajectoryWriter` share WAL mode on the database file;
  concurrent reads served from WAL snapshots without blocking writes.
- **Bounded compaction batch:** `TrajectoryCompactor::compact` uses `BEGIN IMMEDIATE` with a
  maximum batch size of 1 000 records per transaction to prevent blocking `CheckpointSaver::put_writes`
  indefinitely (writer-timeout guard).

`BC-2.04.011 {INV-005}` existing wording ("has no access to and does not affect the
conversation-context checkpoint tables") correctly describes table-level isolation and requires
no amendment. **Product-owner:** add to `BC-2.04.011 {INV-005}` a parenthetical: "bounded
compaction batch (default 1 000 records per `BEGIN IMMEDIATE` transaction) prevents
writer-timeout blocking of concurrent `CheckpointSaver::put_writes` calls."

### Dependency Note: uuid serde Feature (F-P2A208-09)

`TrajectoryRecord` derives `Serialize + DeserializeOwned` over `run_id: uuid::Uuid`. The `uuid`
crate's serde support is gated behind the `"serde"` feature flag. **S-2.12 implementation note:**
workspace `Cargo.toml` MUST declare `uuid = { version = "...", features = ["v4", "serde"] }`.
Omitting `"serde"` causes a compile error at the `TrajectoryRecord` derive site.

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
///
/// `Serialize + DeserializeOwned` bounds are required for checkpoint-resume: the `Vec<T>`
/// channel accumulator is serialized by `CheckpointSaver::put_writes` on checkpoint and
/// deserialized on resume. `entry_id()` must return the same value before and after a serde
/// round-trip (stable identity invariant — ADR-030 §Decision 3 §Serialization Bound).
pub trait LedgerEntry: Clone + Serialize + DeserializeOwned + Send + Sync + 'static {
    fn entry_id(&self) -> &str;
}

/// Dedup-idempotent append-only channel — stateless reducer marker.
/// Channel registration is type-level (via `StateGraph` schema annotation); the BSP engine
/// constructs instances internally. `Default` impl provided for cross-crate use (tests, etc.).
/// Reducer: `fn reduce(acc: Vec<T>, update: T) -> Vec<T>` (pure function; no `Result`).
#[non_exhaustive]
pub struct LedgerChannel<T: LedgerEntry> { _inner: PhantomData<T> }

impl<T: LedgerEntry> Default for LedgerChannel<T> {
    fn default() -> Self { LedgerChannel { _inner: PhantomData } }
}

/// Enum of operations for the promote/retire lifecycle.
#[non_exhaustive]
pub enum PromoteRetireOp<T: LedgerEntry> {
    Promote(T),
    Retire(String), // entry_id of the item to retire
}

/// Active-set channel — stateless reducer marker.
/// `Default` impl provided for cross-crate use (tests, etc.).
/// Reducer: `fn reduce(acc: Vec<T>, op: PromoteRetireOp<T>) -> Vec<T>` (pure; no `Result`).
#[non_exhaustive]
pub struct PromoteRetireChannel<T: LedgerEntry> { _inner: PhantomData<T> }

impl<T: LedgerEntry> Default for PromoteRetireChannel<T> {
    fn default() -> Self { PromoteRetireChannel { _inner: PhantomData } }
}
```

### Serialization Bound for Checkpoint Resume (F-P2A211-07)

**Decision:** Impose `Serialize + DeserializeOwned` bounds on the `LedgerEntry` trait directly.

`StateGraph` serializes channel accumulators (`Vec<T>`) via `CheckpointSaver::put_writes` on
checkpoint and deserializes them on resume. `LedgerChannel<T>` and `PromoteRetireChannel<T>`
accumulators are `Vec<T>`, requiring `T: Serialize + DeserializeOwned` for round-trip correctness.
Placing the bounds on `LedgerEntry` is the correct seam — any type implementing `LedgerEntry` is
automatically checkpoint-resume-compatible without a separate registration step.

Canonical bound: `pub trait LedgerEntry: Clone + Serialize + DeserializeOwned + Send + Sync + 'static`

`entry_id()` must produce the same value before and after a serde round-trip (stable identity).

**Product-owner:** update `BC-2.02.007 AC-001` and `S-1.28 AC-001` to carry:
"The `T` type bound for `LedgerChannel<T>` is `T: LedgerEntry` (supertrait-only — `Serialize +
DeserializeOwned` are already imposed by the `LedgerEntry` supertrait; use-site repetition of
those bounds is forbidden per F-P2A208-11); `entry_id()` is stable across serde round-trips."

### VP

`LedgerChannel` dedup-idempotency is a formally provable pure-function reducer property.
**VP-017** (proptest P1, Phase 3) is seeded now:

- Property: for any sequence of `reduce` calls on `LedgerChannel`, the final
  accumulated `Vec<T>` contains exactly the entries with distinct `entry_id` values, in
  first-appearance order.
- Tool: proptest — exercise arbitrary sequences of novel and repeated entries; assert
  idempotency invariant holds for every prefix.
- Module: `graph::channels` | Crate: `pregolya-graph` | BC Anchor: BC-2.02.007 + BC-2.02.008

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
| BC-2.04.010 | SS-04 | `TrajectoryReader::replay` Ascending step_idx Order | Replay returns records in ascending step_idx order; complete; deterministic |
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
| VP-017 | `graph::channels` | proptest | P1 | BC-2.02.007 + BC-2.02.008 | 3 |
| VP-018 | `checkpoint::trajectory` | proptest | P1 | BC-2.04.011 {INV-001} | 3 |
| VP-019 | `checkpoint::trajectory` | integration | P1 | BC-2.04.011 {INV-003} | 6 |

**VP-017** dual anchor: BC-2.02.007 (dedup-idempotent append) + BC-2.02.008 (first-appearance
ordering) — harness exercises both properties; VP-014 two-BC precedent.

**VP-018** (proptest P1): pure-core record-selection and ordering invariants (no-loss/no-mutation
of retained records; ascending step_idx preservation). Harness extracts the selection logic from
the async SQLite layer.

**VP-019** (integration P1, Phase 6): crash-isolation invariant — SIGKILL mid-compaction,
restart, `replay(run_id)` returns pre-compaction result. Promotes informal `VP-COMPACT-02`
label in `BC-2.04.011 §Verification Properties` to a real VP. **Product-owner:** rename
`VP-COMPACT-01` → `VP-018` and `VP-COMPACT-02` → `VP-019` in `BC-2.04.011 §Verification
Properties` table.

### BC-2.02.009 Renumber-Provenance Canonical Narrative (F-P2A210-02)

**One authoritative event sequence (resolve contradiction in BC-2.02.009 changelog):**

1. ADR-030 Stage 1 (v1.0) reserved BC-2.02.007 (LedgerChannel dedup) and BC-2.02.008 in SS-02.
   Original Stage 1 intent for BC-2.02.008 was PromoteRetireChannel lifecycle.
2. PO Stage 2a: authored BC-2.02.008 as "LedgerChannel First-Appearance Ordering" (deviation from
   Stage 1 plan); simultaneously authored PromoteRetireChannel content at BC-2.04.011 (SS-04 —
   wrong subsystem and wrong BC range).
3. ARCH-INDEX ruling: BC-2.04.011 content reset to Trajectory Compaction Isolation (SS-04,
   its original reservation purpose); PromoteRetireChannel content relocated to new BC-2.02.009.
4. **BC-2.02.009 was CREATED as a new BC in the SS-02 range.** It was NOT renumbered from
   BC-2.04.011. BC-2.04.011 is an active, independent BC (Trajectory Compaction Isolation) that
   was never renamed or superseded.
5. The PromoteRetireChannel content that BC-2.02.009 contains was physically relocated FROM the
   PO's erroneous use of BC-2.04.011, but BC-2.04.011 is NOT the `prior_id` of BC-2.02.009.

**BC-2.02.009 canonical prior-ID:** none (new creation). Prior-subsystem: N/A.

**BC-2.02.009 changelog correction:** "Renumbered from BC-2.04.011 to BC-2.02.009" is
inaccurate. The canonical description: "BC-2.02.009 created as new SS-02 BC; PromoteRetireChannel
content relocated from erroneous PO draft at BC-2.04.011 (which was always reserved for
Trajectory Compaction Isolation in SS-04; BC-2.04.011 continues as a separate active BC).
Prior-ID: N/A (new creation)."

### Architecture Invariants Unchanged

- 21 published crates — no additions.
- `deployment_topology: single-service` — unchanged.
- `graph::channels` module row in module-decomposition.md — extended in-module description; no
  new module row (ledger types are in the same module as the existing channel family).
- ADR-009 definitions-in-core pattern applied for `core::trajectory`; same exemptions apply.
- `checkpoint::trajectory` is an Effectful Shell module (storage I/O); purity-boundary-map
  updated accordingly.
