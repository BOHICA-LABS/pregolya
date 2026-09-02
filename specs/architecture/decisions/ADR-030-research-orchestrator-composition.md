---
document_type: adr
level: L3
adr_id: "030"
slug: research-orchestrator-composition
title: "Praxist-Pattern Research Orchestrator: Use-Case Composition Architecture and Additive Library Primitives"
status: accepted
date: "2026-09-01"
producer: architect
timestamp: 2026-08-31T00:00:00Z
version: "2.1"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: []
supersedes: []
superseded_by: null
subsystems_affected: ["SS-02", "SS-04"]
changelog:
  - "2.1 (round-63/F-P2A235-01+F-P2A235-03+F-P2A235-04+F-P2A235-06+F-P2A235-08/2026-09-01): STAGE A fix-burst. F-P2A235-01 [HIGH] §SQLite Topology Decision: retired contradictory bounded-batch bullet — replaced with per-run single-transaction DELETE description (no batch-size limit; single BEGIN IMMEDIATE/COMMIT scoped to target run_id); replaced stale product-owner add-bounded-batch-parenthetical directive with supersession note pointing to §Compaction Atomicity Decision. F-P2A235-04 [HIGH] NFR-015 priority decided authoritatively as P0: BC-2.04.009 claims parity with put_writes durability; NFR-002 (put_writes NFR) is P0; parity requires identical priority; product-owner directed to update nfr-catalog.md Priority from P1 to P0. F-P2A235-06 [MED] E-TRAJ-006 message/placeholder updated to STATIC 0-placeholder canonical form per error-taxonomy.md (the taxonomy is the source of truth for error codes); EC-006 directive message aligned. F-P2A235-08 [MED] VP-020 BC Anchor: {INV-002} gloss corrected from 'Retire idempotency, task-identity ordering' to 'reducer determinism, task-identity ordering' ({INV-002} is REDUCER DETERMINISM; {PC-004} is Retire idempotency)."
  - "2.0 (round-62/F-P2A234-01+F-P2A234-02+F-P2A234-03+F-P2A234-04+F-P2A234-05+OBS-1+OBS-2+OBS-3/2026-09-01): STAGE A fix-burst. F-P2A234-01 [HIGH/CWE-459] §Compaction Atomicity Decision: staging-table single-atomic-swap model REPLACED with per-run single-transaction DELETE. The prior staging-table swap silently destroyed all other run_ids' records — trajectory_records is keyed (run_id, step_idx) and holds ALL runs; the build phase copied only the target run's retained records to staging, then the whole-table rename permanently destroyed every other run_id's records. Redesigned mechanism: BEGIN IMMEDIATE; DELETE FROM trajectory_records WHERE run_id = :run_id AND step_idx < :retention_frontier AND step_idx NOT IN (:promoted_step_idxs); COMMIT — inherently per-run-scoped (only target run records touched), single-transaction reader-visible-atomic, 2-point crash matrix (before COMMIT = pre-compaction intact; after COMMIT = post-compaction). F-P2A234-02 [HIGH/CWE-362] concurrent put_record safety resolved: BEGIN IMMEDIATE write-lock serializes any concurrent put_record that arrives while compaction is in progress; no build-to-swap clobber window exists under per-run DELETE; BC-2.04.011 §Related BCs false safety claim corrected (product-owner directive provided in §Compaction Atomicity Decision). F-P2A234-03 [MED/CWE-390+354] E-TRAJ-006 TrajectoryIntegrityCheckFailed: mint directive added to §Content-Hash Oracle Decision — covers AES-GCM auth-tag mismatch during conflict-detection decrypt; product-owner + state-manager directives. F-P2A234-04 [MED] NFR-015 trajectory durability: mint directive added to §SQLite Topology Decision — mirrors NFR-002 crash-cycle target anchored to BC-2.04.009 DI-002; product-owner directive. F-P2A234-05 [MED] VP-020 PromoteRetireChannel idempotency proptest P1: minted in §VP of Decision 3 — BC-2.02.009 {INV-001}+{INV-002}, DI-001, harness promote_retire_channel_idempotency, Phase 3; VP-INDEX, verification-architecture, verification-coverage-matrix updated same burst. OBS-1: nonce-uniqueness cross-reference directive added to §Content-Hash Oracle Decision. OBS-2: deletion-tamper-evidence explicitly declared out of scope for v1 in new §Deletion Tamper-Evidence Decision subsection. OBS-3: promoted Vec<u64> element semantics directive added to §Consequences."
  - "1.9 (round-58/F-P2A229-01/2026-09-01): F-P2A229-01 [MED] §Decision 3 PromoteRetireOp<T>: add #[derive(Clone, Debug)]. Clone is required by the Channel::Update: Clone bound; LedgerEntry: Clone (supertrait bundles Clone), so derive(Clone) emits impl<T: Clone> Clone for PromoteRetireOp<T> which resolves for every T: LedgerEntry with no bound beyond the supertrait — does NOT trigger rustc #26925 spurious-bound problem (contrast: Default is NOT in the LedgerEntry bundle, which is why the marker structs use manual bound-free Default impls). Debug is conventionally added for a data-bearing update enum (diagnostic value); the derived impl is conditional on T: Debug (LedgerEntry does not bundle Debug); no declared bound requires unconditional Debug, so the conditional impl is acceptable. Rationale documented as doc-comment on PromoteRetireOp to prevent future incorrect removal. Derive-shape paragraph extended to confirm LedgerChannel<T> Update = T needs no separate Clone annotation (T: LedgerEntry implies T: Clone — already satisfies Channel::Update: Clone). LedgerChannel<T> code block is unaffected."
  - "1.8 (round-57/F-P2A227-01/2026-09-01): F-P2A227-01 [HIGH] §Decision 3 code block: the derive(Default)-ONLY mandate introduced by F-P2A220-01/F-P2A224-03 is NON-REALIZABLE and is hereby REVERSED. rustc's derive(Default) for a generic struct emits an impl that bounds every type parameter by Default (rustc issue #26925 — perfect-derive not implemented). Because LedgerEntry does not include Default, derive(Default) on LedgerChannel<T: LedgerEntry> emits impl<T: LedgerEntry + Default> Default for LedgerChannel<T> — a spurious T: Default bound that violates AC-018/BC-2.02.007 {INV-004}. The same defect applies to PromoteRetireChannel<T: LedgerEntry>. The previously-correct manual bound-free impl (present in v1.3, removed in v1.6) is restored for both structs: impl<T: LedgerEntry> Default for LedgerChannel<T> { fn default() -> Self { Self { _inner: PhantomData } } } and analogously for PromoteRetireChannel. The derive(Default) annotation is dropped from both struct definitions. No other derive attributes are added or removed. This decision supersedes the derive-only mandate in F-P2A220-01 and F-P2A224-03, which are recorded as non-realizable. The no-Clone/Serialize/Deserialize-on-marker-struct rule and #[non_exhaustive] annotations remain intact."
  - "1.7 (round-55/F-P2A225-01+F-P2A225-02/2026-09-01): F-P2A225-01 [HIGH] §VP DI adjudication extended to PromoteRetireChannel::reduce — DI-014 is inapplicable to both LedgerChannel::reduce and PromoteRetireChannel::reduce; both are pure infallible reducers returning Vec<T> (no Result, no error path); DI-001 (BSP reducer determinism) is the sole authoritative anchor for both; per-artifact propagation targets table added for product-owner. F-P2A225-02 [HIGH] Three chained double-§ citations eliminated per POL-19/ADR-022: (1) For-story-writer S-1.28 note chain §BSP Reduce-Dispatch Seam + §Channel Trait Definition Home → single §Channel Trait Definition Home and ChannelKind Coexistence. (2) LedgerEntry code-block doc-comment chain §Decision 3 + §Serialization Bound → single §Serialization Bound for Checkpoint Resume. (3) VP-019 Consequences note chain §Compaction Atomicity Decision + §BC-2.04.011 downstream notes → §BC-2.04.011 Downstream Notes (pseudo-heading promoted to real #### heading to enable single valid §-citation)."
  - "1.6 (round-54/F-P2A224-01+F-P2A224-03+F-P2A224-04/2026-09-01): F-P2A224-01 [HIGH] Channel trait ownership and ChannelKind coexistence resolved. Authoritative decision: the Channel trait is defined in graph::channels by S-1.14 (channels/channel.rs) per this ADR's direction; S-1.14 must additionally implement Channel for all five built-in types (LastValue<T>, BinaryOperatorAggregate<T,Op>, BarrierValue<T>, NamedBarrierValue<T>, EphemeralValue<T>). ChannelKind enum (types.rs) is a naming/discriminant for StateGraph schema configuration; Channel trait is the sole BSP dispatch mechanism — no hybrid dispatch path exists. §BSP Reduce-Dispatch Seam: Channel trait definition home and ChannelKind coexistence note added; S-1.14 story-writer instruction added. §Alternatives Alt C: repaired 'does not yet exist' — the Channel extension seam is defined by S-1.14 per this ADR; Alt C rejected on general-purpose-applicability grounds. 'For story-writer (S-1.28)' note updated: Channel trait is pre-existing when S-1.28 begins; corrected Rule 15 provenance text provided. F-P2A224-03 [HIGH] §Decision 3: LedgerChannel<T> and PromoteRetireChannel<T> struct definitions updated to canonical derive-set (F-P2A220-01 canon; S-1.28 Rule 13) — replaced manual impl Default blocks with #[derive(Default)] annotation form. F-P2A224-04 [LOW] §Consequences New-BCs table: BC-2.02.009 title corrected from 'PromoteRetireChannel Lifecycle Semantics' to canonical H1 'PromoteRetireChannel Promote/Retire Lifecycle' (BC-2.02.009 §H1 sync)."
  - "1.5 (round-53/F-P2A221-01+F-P2A221-02+F-P2A220-03+F-P2A223-01+F-P2A220-05/2026-08-31): Decision 2: §Content-Hash Oracle Decision added (F-P2A221-02/CWE-916/CWE-311) — conflict detection MUST use decrypt-then-compare exclusively; no auxiliary hash or HMAC may be stored on disk; key-provenance is the 256-bit AES-GCM key already held by EncryptedSerializer — no second secret required. §Compaction Atomicity Decision added (F-P2A221-01) — staging-table single-atomic-swap model: build phase copies retained records to trajectory_records_staging in bounded batches (no reader-visible lock held on trajectory_records); swap phase renames staging to trajectory_records in a single BEGIN IMMEDIATE/COMMIT (fast catalog op); crash mid-build leaves trajectory_records intact; crash mid-swap is WAL-atomic; reconciles BC-2.04.011 whole-operation atomicity with bounded-batch SQLite Topology; VP-019 crash-point matrix extended to four points. Decision 3: §BSP Reduce-Dispatch Seam added (F-P2A220-03) — Channel trait contract (Accumulator/Update assoc types, pure infallible reduce fn, Default required); LedgerChannel<T> and PromoteRetireChannel<T> Channel impls specified; derive-shape: T: LedgerEntry only (supertrait bundles all required bounds); BSP registration is type-level. §VP: di_anchor for VP-017 adjudicated DI-001 (BSP reducer determinism; DI-014 inapplicable — pure fn returns Vec<T> not Result); seeded-now directive text replaced with minted-active status. Consequences §VP: VP-COMPACT-01→VP-018/VP-COMPACT-02→VP-019 rename directive marked discharged (completed by product-owner in BC-2.04.011 §Verification Properties (round-50/D-328)). Records-tier cleanup (F-P2A220-05/F-P2A223-02)."
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

### Content-Hash Oracle Decision — Conflict Detection Integrity (F-P2A221-02)

`BC-2.04.009 {INV-001}` previously permitted "decrypt-then-compare OR compare a deterministic
content-hash of the pre-encryption plaintext stored alongside the ciphertext." The second
option is an oracle vulnerability: any hash (unkeyed or keyed) stored persistently alongside
ciphertext enables an adversary with read access to the database file to confirm known
plaintext against the stored value (CWE-916 preimage oracle; CWE-311 insufficient at-rest
encryption protection).

**Decision: decrypt-then-compare exclusively.**

Conflict detection for `(run_id, step_idx)` duplicate `put_record` writes MUST decrypt the
stored ciphertext and compare plaintext payloads in memory. No auxiliary hash, digest, HMAC,
or any other derivation of the plaintext may be stored on disk.

**Key provenance:** The decryption key is the 256-bit AES-GCM key already held in memory by
`EncryptedSerializer` (passed at `EncryptedSerializer::new(key: &[u8; 32])` construction).
No additional secret key is required for conflict detection. The comparison operates entirely
in memory; no derivative of the plaintext is persisted to the database file.

**Rationale for rejecting keyed MAC:**
A HMAC keyed with the AES-GCM encryption key is architecturally unsound (key reuse across
distinct cryptographic functions). A HMAC keyed with a separate key requires provisioning,
storing, and rotating a second independent secret — operational complexity that provides zero
benefit over decrypt-then-compare, since the decryption key is already present in memory.

**Rationale for rejecting unkeyed hash:**
A plaintext-deterministic hash (SHA-256, BLAKE3, etc.) stored in the clear is a preimage
oracle: an attacker who can read the database and guess a candidate plaintext verifies it
against the stored hash without needing the encryption key. Unkeyed hashes MUST NOT be
stored alongside at-rest ciphertext.

**Product-owner directive (F-P2A221-02):** `BC-2.04.009 {INV-001}` MUST be amended to remove
the "(or compare a deterministic content-hash of the pre-encryption plaintext stored alongside
the ciphertext)" clause. The required wording: "when `EncryptedSerializer` is configured,
conflict detection MUST decrypt-then-compare — the implementation decrypts the stored record
ciphertext and compares plaintext payloads in memory. No auxiliary hash or digest may be
stored on disk for this purpose."

**E-TRAJ-006 mint directive (F-P2A234-03/CWE-390+354):** The decrypt-then-compare path is
FALLIBLE. When `EncryptedSerializer::deserialize` returns `Err` on the conflict-detection
read (AES-GCM auth-tag mismatch — stored record is corrupted or tampered), no current error
code covers this condition. E-TRAJ-002 (VAL/ConflictingDuplicate) is wrong — this is not a
caller-supplied duplicate, it is a storage-layer integrity failure. E-TRAJ-001 (DURABILITY/
TrajectoryWriteFailed) is wrong — this is a read failure on the conflict-detection path.

**State-manager + product-owner directive:** Mint E-TRAJ-006 in error-taxonomy.md
Component: TRAJ:
- Code: `E-TRAJ-006`
- Name: `TrajectoryIntegrityCheckFailed`
- Category: DURABILITY
- Severity: broken
- RetryHint: Never (diverges from DURABILITY default Maybe — AES-GCM auth-tag mismatch
  is permanent corruption; retrying will reproduce the same failure)
- Message: `TrajectoryIntegrityCheckFailed: stored trajectory record failed AES-GCM integrity check during conflict-detection read — tamper, corruption, or wrong key`
- Placeholders: none (static message — 0 placeholders; error-taxonomy.md is the source of truth for the canonical form)
- Raise site: `TrajectoryWriter::put_record` conflict-detection path — when
  `EncryptedSerializer` is configured and `EncryptedSerializer::deserialize` of the stored
  record returns `Err` (auth-tag mismatch); the stored record is not modifiable; the error
  is returned to the caller immediately
- BC anchor: BC-2.04.009 {INV-001}
- Census delta: TRAJ namespace 4→5 live codes; individual 30→31; total 142→143
  (50 HTTP + 31 individual + 62 blanket = 143)

**Product-owner directive (EC for BC-2.04.009):** Add EC-006 to BC-2.04.009:
"Scenario: `put_record` is called for `(run_id=R, step_idx=7)` where an encrypted record
already exists at that position. `EncryptedSerializer::deserialize` of the stored ciphertext
returns `Err` (AES-GCM auth-tag mismatch — stored data may be corrupted or tampered).
Expected behavior: `put_record` returns `Err(PregolyaError { code: E-TRAJ-006, message:
'TrajectoryIntegrityCheckFailed: stored trajectory record failed AES-GCM integrity check
during conflict-detection read — tamper, corruption, or wrong key', category: DURABILITY,
.. })`. No modification is made to the stored record. DI-014 (error propagation — no silent
swallowing) requires surfacing this failure as `Err` rather than silently swallowing it."

**Nonce-uniqueness cross-reference (OBS-1):**
`BC-2.04.009 {INV-001}` relies on per-record AES-GCM nonce uniqueness for the
decrypt-then-compare to work correctly. The nonce uniqueness guarantee is a contract of
`EncryptedSerializer`, not of `TrajectoryWriter`.

**Product-owner directive (OBS-1):** Add a cross-reference sentence to BC-2.04.009 {INV-002}:
"Per-record nonce uniqueness is guaranteed by `EncryptedSerializer`'s contract (see
BC-2.04.007 for the nonce-source mechanism; for AES-GCM with a 96-bit nonce, the birthday
probability of nonce collision becomes material only at approximately 2^48 encrypt operations
per key — far exceeding any practical single-run trajectory size; the random-nonce approach is
sound within the research orchestrator use case)."

**Product-owner directive (OBS-1):** Verify that BC-2.04.007 explicitly states the nonce
source mechanism for `EncryptedSerializer` (counter vs. random CSPRNG). If not, add the
specification: "nonces are generated per-encrypt-call from the operating-system CSPRNG
via the `aes-gcm` crate (96-bit, randomly generated)."

### SQLite Topology Decision (F-P2A209-04)

**Decision:** Trajectory records reside in a **dedicated `trajectory_records` table** within the
**same SQLite database file** as `CheckpointSaver` (the "co-located storage slice" interpretation
of the §Design text above).

Isolation model:
- **Record-level table isolation:** no FK joins between `checkpoint_*` tables and `trajectory_records`.
- **WAL mode:** both `CheckpointSaver` and `TrajectoryWriter` share WAL mode on the database file;
  concurrent reads served from WAL snapshots without blocking writes.
- **Per-run single-transaction DELETE:** `TrajectoryCompactor::compact` executes one
  `BEGIN IMMEDIATE` / `COMMIT` transaction scoped to the target `run_id`. Lock duration is
  proportional to the eligible-record set for that run (typically O(hundreds) for a research
  session), not to the total table size. No batch-size limit applies — the DELETE is a
  single transaction whose scope is structurally bounded by the target run's eligible records.
  See §Compaction Atomicity Decision for the full mechanism and crash semantics.

`BC-2.04.011 {INV-005}` existing wording ("has no access to and does not affect the
conversation-context checkpoint tables") correctly describes table-level isolation and requires
no amendment. The bounded-batch parenthetical described the prior staging-table build phase
and has been superseded by §Compaction Atomicity Decision; product-owner must remove it
per that section's directive.

### Compaction Atomicity Decision — Per-Run Single-Transaction DELETE (F-P2A221-01, revised F-P2A234-01)

**Defect in prior staging-table model (F-P2A234-01/CWE-459):**
The staging-table single-atomic-swap model had a catastrophic multi-run data-loss path.
`compact(run_id, policy)` is per-run-scoped: all postconditions reference only records for
the given `run_id`. However, the `trajectory_records` table is keyed by `(run_id, step_idx)`
and holds ALL runs' records simultaneously (BC-2.04.010 EC-003 shows `run_id_A` and
`run_id_B` coexisting). The prior build phase copied only the target run's retained records
to `trajectory_records_staging` — records belonging to all other runs were NEVER copied.
The whole-table rename swap then permanently destroyed every other run's trajectory. This is
a silent catastrophic data-loss path on any deployment where more than one research run has
ever written trajectory records.

**Decision: per-run single-transaction DELETE.**

Compaction is now a **single-phase operation** scoped to the target `run_id`:

```sql
BEGIN IMMEDIATE;
DELETE FROM trajectory_records
  WHERE run_id = :run_id
    AND step_idx < :retention_frontier
    AND step_idx NOT IN (:promoted_step_idxs);
COMMIT;
```

**Mechanism properties:**

- **Per-run scope-safety:** only records with `run_id = :run_id` are touched. Records
  belonging to every other `run_id` are never read, modified, or deleted — structural
  enforcement, not documentation convention.
- **Reader-visible atomicity:** the single `BEGIN IMMEDIATE / COMMIT` transaction provides
  atomicity for `BC-2.04.011 {PC-004}`. `TrajectoryReader::replay(run_id)` observes
  either the complete pre-compaction state (transaction not yet committed) or the complete
  post-compaction state (transaction committed). No intermediate partial state is observable.
- **Bounded lock duration:** the DELETE transaction acquires the write lock proportionally
  to the number of eligible records for the target `run_id`, not to the total table size.
  For the research orchestrator use case, eligible records per compaction event are bounded
  by the session length since the last frontier advance — typically O(hundreds) — well
  within a single transaction's safe scope.
- **No stale-artifact cleanup:** no staging table is created; there is no stale
  `trajectory_records_staging` table to detect or drop on recovery.

**Crash semantics (2-point matrix):**

- **Before COMMIT** (process killed during DELETE execution, before the COMMIT WAL record
  is written): SQLite WAL atomicity applies — uncommitted WAL frames are discarded on the
  next database open; `trajectory_records` is fully intact at the pre-compaction state.
  `replay(run_id)` returns the pre-compaction record set.
- **After COMMIT** (process killed after the COMMIT WAL record is durably flushed):
  `trajectory_records` reflects the post-compaction state — all eligible records for
  `run_id` are absent; all retained records and all other runs' records are present.
  `replay(run_id)` returns the post-compaction retained set.

**Concurrent `put_record` safety (F-P2A234-02/CWE-362):**

Under the prior staging-table model, a `put_record` call that committed AFTER the build
phase read the table but BEFORE the swap was silently destroyed by the whole-table rename.
Under the per-run DELETE model this window does not exist:

SQLite `BEGIN IMMEDIATE` acquires a reserved lock that prevents any other writer from
starting until this transaction commits. A concurrent `put_record` call that arrives while
the compaction transaction is in progress will attempt its own `BEGIN IMMEDIATE` and will
block until the compaction `COMMIT` releases the write lock. The `put_record` then executes
against the post-compaction table state. No durably committed `put_record` result can
be silently lost by a concurrent `compact` call.

**Product-owner directive (F-P2A234-02):** Replace the false safety claim in
BC-2.04.011 §Related BCs: the sentence "compaction never conflicts with in-flight
`put_record` calls due to the atomic transaction boundary" is false under the prior
staging-table model and must be replaced with the true guarantee:
"compaction serializes against concurrent `put_record` calls via SQLite's `BEGIN IMMEDIATE`
write-lock protocol; a `put_record` call that arrives while a compaction transaction is in
progress blocks until the compaction `COMMIT` releases the write lock, then writes to the
post-compaction table state; no durably committed `put_record` record can be silently lost
by a concurrent `compact` call."

**Reconciliation with `BC-2.04.011 {PC-004}` / `{INV-003}`:**
Reader-visible atomicity is provided by the single `BEGIN IMMEDIATE / COMMIT` wrapping the
DELETE. The pre/post observability mapping: before COMMIT → pre-compaction state; after
COMMIT → post-compaction state. This directly satisfies BC-2.04.011 {PC-004}.

**Reconciliation with §SQLite Topology bounded-batch wording:**
The "bounded compaction batches (default 1 000 records per `BEGIN IMMEDIATE` transaction)"
language in §SQLite Topology Decision described the prior staging-table build phase, which
no longer exists. **Product-owner directive:** remove the "bounded compaction batch"
parenthetical from BC-2.04.011 {INV-005} — it described build-phase behavior that does
not exist under the per-run DELETE model. The write-lock-duration concern no longer applies:
the DELETE transaction's lock duration is proportional to the target-run eligible set, not
the full table.

**NFR-015 directive (F-P2A234-04):**
**Product-owner:** add NFR-015 to nfr-catalog.md:
- Category: Reliability
- Requirement: Trajectory records durably committed via `put_record` must survive process
  crash and appear in `replay` after restart — same durability guarantee as NFR-002
  for `put_writes`.
- Success Criterion: 0 trajectory records lost in 100 crash-restart cycles (SIGKILL after
  `put_record` returns `Ok(())`; `replay(run_id)` after restart returns all such records).
- Validation: `cargo test --test trajectory_crash_recovery -- --nocapture`
- Priority: P0 (DI-002 per-task durability; BC-2.04.009 explicitly claims same guarantee
  as `put_writes`).
- BC Anchor: BC-2.04.009 (DI-002).

**Authoritative priority decision (F-P2A235-04):** NFR-015 priority is **P0**
(convergence-gating). Rationale: BC-2.04.009 explicitly claims "the same durability guarantee
as `put_writes`"; NFR-002 (the `put_writes` durability NFR, the declared parity target) is P0.
Parity requires NFR-015 to carry the same priority. Any nfr-catalog.md value of P1 for
NFR-015 is a divergence from this decision; P0 is authoritative.

**Product-owner directive (F-P2A235-04):** Update NFR-015 in nfr-catalog.md: set
`Priority: P0` in the registry row, the NFR-to-Module map row, and the changelog. Canonical
rationale for the changelog entry: "BC-2.04.009 declares parity with `put_writes` durability
(NFR-002 is P0); parity requires identical priority. Promoted P1 → P0 per ADR-030
§NFR-015 directive (F-P2A235-04, round-63)."

#### BC-2.04.011 Downstream Notes (updated — F-P2A234-01)

- `{INV-003}`: "the SQLite `BEGIN IMMEDIATE` / `COMMIT` transaction" refers to the
  per-run DELETE transaction — the sole atomicity boundary. The **2-point crash matrix**
  supersedes the prior 4-point matrix: (1) before COMMIT → pre-compaction state intact;
  (2) after COMMIT → post-compaction state. The staging-table crash points (mid-build,
  mid-swap) no longer exist.
- `{INV-005}`: "bounded compaction batches" is removed. The single-transaction DELETE
  is the compaction implementation; no build-phase bounded-batch concept exists.
  **Product-owner:** amend {INV-005} to remove the bounded-batch parenthetical. The
  table-isolation statement (no FK joins to checkpoint tables) and WAL non-blocking-reads
  statement remain valid.
- **Formal-verifier directive for `VP-019`:** The crash-point matrix MUST be updated from
  four crash points to **TWO crash points**: (1) before-commit — SIGKILL during DELETE
  execution (expected: pre-compaction record set); (2) after-commit — SIGKILL after WAL
  COMMIT record flushed (expected: post-compaction retained set). The mid-build and
  mid-swap crash points do not exist under the per-run DELETE model. Update the VP-019 body
  Property Statement section, Formal Statement section, and TV-002 matrix accordingly.

#### Deletion Tamper-Evidence Decision (OBS-2)

`compact(run_id, policy)` is a legitimate deletion channel: the caller can permanently
remove trajectory records. The question is whether v1 must provide tamper-evidence against
compaction — a mechanism to prove that deletions were authorized and records were not
modified by other means (append-only storage, hash-chain linking, compaction audit log).

**Decision: deletion tamper-evidence is EXPLICITLY OUT OF SCOPE for v1.**

Rationale:
1. The trajectory primitive is designed for REPLAY and REPRODUCIBILITY of research runs
   by the system owner — not as a tamper-evident log against the system owner. The use
   case is researcher-grade reproducibility, not compliance-grade immutable audit.
2. Append-only enforcement and hash chains require a storage backend that enforces
   append-only semantics (WORM media, blockchain-style hash chains, or an external audit
   service) — these are v2 / compliance-tier features beyond the scope of the research
   orchestrator primitive.
3. The compaction API is access-controlled at the system level; the v1 threat model
   treats the system owner as trusted.
4. If future compliance requirements (SOC2, GDPR evidence retention) demand tamper-evidence,
   a dedicated v2 feature would extend `checkpoint::trajectory` with hash-chain record
   linking or an external compaction audit log. That feature is deferred by explicit design
   choice, not by oversight.

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
/// round-trip (stable identity invariant — ADR-030 §Serialization Bound for Checkpoint Resume).
pub trait LedgerEntry: Clone + Serialize + DeserializeOwned + Send + Sync + 'static {
    fn entry_id(&self) -> &str;
}

/// Dedup-idempotent append-only channel — stateless reducer marker.
/// Channel registration is type-level (via `StateGraph` schema annotation); the BSP engine
/// constructs instances internally. `Default` is a manual bound-free impl so that
/// `LedgerChannel<T>` satisfies `Channel: Default` for all `T: LedgerEntry` without
/// requiring `T: Default` (derive(Default) would spuriously add that bound per rustc #26925).
/// Reducer: `fn reduce(acc: Vec<T>, update: T) -> Vec<T>` (pure function; no `Result`).
#[non_exhaustive]
pub struct LedgerChannel<T: LedgerEntry> { _inner: PhantomData<T> }

impl<T: LedgerEntry> Default for LedgerChannel<T> {
    fn default() -> Self { Self { _inner: PhantomData } }
}

/// Enum of operations for the promote/retire lifecycle.
///
/// `derive(Clone)` is safe here: `LedgerEntry: Clone` (the supertrait bundles `Clone`),
/// so the derived `impl<T: Clone> Clone for PromoteRetireOp<T>` resolves for every
/// `T: LedgerEntry` with no bound beyond the supertrait. This satisfies the
/// `Channel::Update: Clone` bound without introducing a spurious extra bound — it does
/// NOT trigger the rustc #26925 problem that forced the marker structs to use manual
/// bound-free `Default` impls. Contrast: `Default` is NOT in the `LedgerEntry` bundle,
/// so `derive(Default)` on a generic struct would emit a spurious `T: Default` bound;
/// `Clone` IS in the bundle, so `derive(Clone)` is the correct form here. `Debug` is
/// added conventionally for a data-bearing update enum (diagnostic value); because
/// `LedgerEntry` does not bundle `Debug`, the derived impl is conditional on `T: Debug`
/// — acceptable since no declared bound requires unconditional `Debug` on `Update` types.
#[non_exhaustive]
#[derive(Clone, Debug)]
pub enum PromoteRetireOp<T: LedgerEntry> {
    Promote(T),
    Retire(String), // entry_id of the item to retire
}

/// Active-set channel — stateless reducer marker.
/// `Default` is a manual bound-free impl so that `PromoteRetireChannel<T>` satisfies
/// `Channel: Default` for all `T: LedgerEntry` without requiring `T: Default`.
/// Reducer: `fn reduce(acc: Vec<T>, op: PromoteRetireOp<T>) -> Vec<T>` (pure; no `Result`).
#[non_exhaustive]
pub struct PromoteRetireChannel<T: LedgerEntry> { _inner: PhantomData<T> }

impl<T: LedgerEntry> Default for PromoteRetireChannel<T> {
    fn default() -> Self { Self { _inner: PhantomData } }
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

### BSP Reduce-Dispatch Seam for LedgerChannel (F-P2A220-03)

`LedgerChannel<T>` and `PromoteRetireChannel<T>` participate in the BSP reduce phase through
the `Channel` trait in `graph::channels` (pregolya-graph). This section defines the trait
contract and specifies how the BSP engine dispatches to the ledger-channel reducers, enabling
story S-1.28 to wire the types into the `StateGraph` schema.

#### Channel Trait Definition Home and ChannelKind Coexistence (F-P2A224-01)

**Authoritative trait definition home: S-1.14 — `channels/channel.rs`.**

The `Channel` trait is defined by S-1.14 in `pregolya-graph/src/channels/channel.rs` as
part of the `graph::channels` module. S-1.14 is the story that owns the channel family;
the `Channel` trait is the BSP extension seam that unifies all channel types under a single
dispatch interface. S-1.28 consumes the pre-existing `Channel` trait and implements it for
`LedgerChannel<T>` and `PromoteRetireChannel<T>` — S-1.28 does NOT define the trait.

**S-1.14 required additions (per this ADR):**

1. Define `pub trait Channel: Default + Send + Sync + 'static` in `channels/channel.rs`
   with the exact signature shown in the code block below.
2. Implement `Channel` for each of the five built-in types:
   - `LastValue<T>` — `Accumulator = Option<T>` (or `T` per S-1.14 spec), `Update = T`
   - `BinaryOperatorAggregate<T, Op>` — `Accumulator = T`, `Update = T`
   - `BarrierValue<T>` — `Accumulator` and `Update` per S-1.14 barrier semantics
   - `NamedBarrierValue<T>` — per S-1.14 named-barrier semantics
   - `EphemeralValue<T>` — per S-1.14 ephemeral semantics
   The exact `Accumulator`/`Update` types for the built-in impls are owned by S-1.14's
   spec; the trait shape is authoritative from this ADR.

**ChannelKind enum and Channel trait coexistence — no hybrid dispatch:**

`ChannelKind` (in `types.rs`) is a **naming discriminant** for StateGraph schema
configuration — it identifies WHICH channel type is active for a given field at the
schema-declaration level. It is not a dispatch mechanism. The BSP execution engine
dispatches to channel reducers exclusively through the `Channel` trait:
`<C as Channel>::reduce(acc, update)`. There is ONE dispatch path: the `Channel` trait.
The `ChannelKind` enum does not duplicate or shadow this path; the two constructs serve
distinct roles (schema configuration vs. execution dispatch) and coexist without conflict.

**`Channel` trait (`graph::channels`, pregolya-graph — defined by S-1.14):**

```rust
/// Extension point for custom BSP channel reducers in a `StateGraph`.
///
/// The BSP engine dispatches to `<C as Channel>::reduce` during the reduce phase for each
/// update posted to a field annotated with channel type `C`. `Default` is required so the
/// BSP engine can construct the zero-value accumulator for a newly-created channel field.
pub trait Channel: Default + Send + Sync + 'static {
    /// The accumulated channel state type, stored per-super-step per `StateGraph` field.
    /// Must satisfy serde bounds for checkpoint-resume serialization.
    type Accumulator: Clone + Serialize + DeserializeOwned + Send + Sync + 'static;
    /// The type of a single update posted to this channel by a graph node.
    /// Updates are ephemeral (not checkpointed); no serde bound required.
    type Update: Clone + Send + Sync + 'static;
    /// Pure, deterministic, infallible reducer: `(current_acc, update) -> new_acc`.
    /// No `Result` — channel reducers must be infallible by contract.
    fn reduce(acc: Self::Accumulator, update: Self::Update) -> Self::Accumulator;
}
```

**`LedgerChannel<T>` `Channel` implementation:**

```rust
impl<T: LedgerEntry> Channel for LedgerChannel<T> {
    type Accumulator = Vec<T>;
    type Update = T;
    /// Dedup-idempotent append: if `update.entry_id()` is already present in `acc`,
    /// returns `acc` unchanged. Otherwise appends `update` in first-appearance position.
    fn reduce(acc: Vec<T>, update: T) -> Vec<T> {
        if acc.iter().any(|e| e.entry_id() == update.entry_id()) {
            acc
        } else {
            let mut v = acc;
            v.push(update);
            v
        }
    }
}
```

**`PromoteRetireChannel<T>` `Channel` implementation:**

```rust
impl<T: LedgerEntry> Channel for PromoteRetireChannel<T> {
    type Accumulator = Vec<T>;
    type Update = PromoteRetireOp<T>;
    /// Promote: dedup-idempotent append to active set.
    /// Retire: remove entry whose `entry_id()` matches the given ID (no-op if absent).
    fn reduce(acc: Vec<T>, op: PromoteRetireOp<T>) -> Vec<T> {
        match op {
            PromoteRetireOp::Promote(entry) => {
                if acc.iter().any(|e| e.entry_id() == entry.entry_id()) {
                    acc
                } else {
                    let mut v = acc;
                    v.push(entry);
                    v
                }
            }
            PromoteRetireOp::Retire(id) => {
                acc.into_iter().filter(|e| e.entry_id() != id.as_str()).collect()
            }
        }
    }
}
```

**BSP registration mechanism (type-level, compile-time):**

`StateGraph` schema declaration annotates each channel field with a `Channel` implementor
type. The BSP engine stores channel accumulators keyed by field name; during the reduce phase
it calls `<C as Channel>::reduce(acc, update)` for the `C` registered for that field.
Registration is compile-time: the user declares `LedgerChannel<EvidenceItem>` as the channel
type for an evidence field; the compiler resolves `<LedgerChannel<EvidenceItem> as Channel>::reduce`
statically. No runtime lookup or reflection is required.

**Derive-shape / `T: LedgerEntry` requirement:**

A concrete type `T` is valid as a `LedgerChannel<T>` element if and only if `T: LedgerEntry`.
`LedgerEntry` is defined as:
`pub trait LedgerEntry: Clone + Serialize + DeserializeOwned + Send + Sync + 'static`
All bounds required by `Channel::Accumulator` (`Clone + Serialize + DeserializeOwned + Send + Sync + 'static`)
and `Channel::Update` (`Clone + Send + Sync + 'static`) are already imposed by the
`LedgerEntry` supertrait. For `LedgerChannel<T>`, `Update = T` and `T: LedgerEntry`
implies `T: Clone` — no additional `#[derive(Clone)]` annotation on `T` is required;
the `Channel::Update: Clone` bound is already satisfied by the supertrait alone.
No additional bounds are required at the call site — `T: LedgerEntry` is the complete
derive-shape requirement for both `LedgerChannel<T>` and `PromoteRetireChannel<T>`.

**For story-writer (S-1.28):** S-1.28 must implement the `Channel` trait for `LedgerChannel<T>`
and `PromoteRetireChannel<T>` as shown above. The `Channel` trait is pre-existing when S-1.28
begins — it is authored by S-1.14 per this ADR's direction (ADR-030 §Channel Trait Definition Home and ChannelKind Coexistence). S-1.28 only implements the trait;
it does not define it. Confirm the `StateGraph` schema annotation mechanism dispatches to
`<LedgerChannel<T> as Channel>::reduce` during the BSP reduce phase, and verify
`PromoteRetireChannel<T>` is wired symmetrically with `Update = PromoteRetireOp<T>`.

**Corrected S-1.28 Rule 15 provenance (replace current Rule 15 text):**
"The `Channel` trait is defined in `graph::channels` by S-1.14 (`channels/channel.rs` per
ADR-030 §Channel Trait Definition Home); S-1.28 consumes the
pre-existing trait and does NOT define it. The `Channel` impl for `LedgerChannel<T>` and
`PromoteRetireChannel<T>` goes in the respective channel module files (`channels/ledger.rs`
and `channels/promote_retire.rs`)."

**For product-owner (BC-2.02.007 amendment):** Add to BC-2.02.007: "`LedgerChannel<T>`
implements `graph::channels::Channel` with `Accumulator = Vec<T>` and `Update = T`; the BSP
engine dispatches to `LedgerChannel::<T>::reduce` during the reduce phase. No additional
bounds beyond `T: LedgerEntry` are required at call sites."

### VP

`LedgerChannel` dedup-idempotency is a formally provable pure-function reducer property.
**VP-017** (proptest P1, Phase 3) is established (minted/active — VP-INDEX VP-017, v1.2):

- Property: for any sequence of `reduce` calls on `LedgerChannel`, the final
  accumulated `Vec<T>` contains exactly the entries with distinct `entry_id` values, in
  first-appearance order.
- Tool: proptest — exercise arbitrary sequences of novel and repeated entries; assert
  idempotency invariant holds for every prefix.
- Module: `graph::channels` | Crate: `pregolya-graph` | BC Anchor: BC-2.02.007 + BC-2.02.008

**DI anchor adjudication for VP-017 (F-P2A223-01):** Authoritative anchor: **`DI-001`**
(BSP reducer determinism). VP-017 proves `LedgerChannel::reduce` is deterministic, idempotent,
and preserves first-appearance ordering across arbitrary entry sequences — all properties that
fall under the BSP reducer determinism domain invariant. `DI-014` (error propagation, no
silent swallowing) does not apply: `reduce` is a pure function returning `Vec<T>`, not
`Result`; there is no error path to swallow or propagate. State-manager and all downstream
VP-INDEX / BC-INDEX / ARCH-INDEX parentheticals that reference VP-017 MUST carry
`di_anchor: DI-001`.

**DI anchor adjudication — extended to PromoteRetireChannel::reduce (F-P2A225-01):** The
inapplicability ruling above extends categorically to `PromoteRetireChannel::reduce`.
`PromoteRetireChannel::reduce` is a pure, infallible function returning `Vec<T>`, not `Result`.
The Promote operation is dedup-idempotent (no-op when `entry_id` already present); the Retire
operation is a no-op when the `entry_id` is absent. Neither case is an error path: the
function signature structurally precludes returning `Err` or `None`. `DI-014` (error
propagation, no silent swallowing) does not apply — there is no error path to swallow or
propagate. Authoritative anchor: **`DI-001`** (BSP reducer determinism). Round-53 adjudicated
only `LedgerChannel::reduce` (F-P2A223-01); this entry corrects the omission for
`PromoteRetireChannel::reduce`.

**VP-020 mint (F-P2A234-05):**

`PromoteRetireChannel::reduce` is structurally identical to `LedgerChannel::reduce` in the
properties that make proptest the correct verification tool: pure, infallible, returns
`Vec<T>`, and the idempotency invariants require arbitrary operation-sequence coverage that
fixed-point unit tests (TST-PROM-01/02) cannot provide. BC-2.02.009 {INV-001}/{INV-002} are
formally provable pure-function reducer properties with the same DI-001 anchor as VP-017.

**VP-020** (proptest P1, Phase 3):

- BC Anchor: BC-2.02.009 {INV-001} (Promote idempotency, no-duplicate) + {INV-002} (reducer
  determinism, task-identity ordering)
- Module: `graph::channels` | Crate: `pregolya-graph` | DI anchor: DI-001
- harness_fn: `promote_retire_channel_idempotency`
- File: `vp-020-promote-retire-channel-idempotency.md`
- Properties for formal-verifier harness:
  1. Promote idempotency: a second `Promote(e)` where `e.entry_id()` already exists in
     the accumulator leaves the set unchanged (no-op; count does not grow).
  2. Retire idempotency: `Retire(id)` where `id` is not in the accumulator is a no-op
     (set unchanged; no panic; no spurious error).
  3. No phantom duplicates: after any `Promote(e)`, `entry_id == e.entry_id()` appears
     exactly once in the accumulator.
  4. Retire removes exactly one entry with the matching `entry_id` when present; all
     other entries are preserved in their original order.
  Tool: proptest — generate arbitrary `Vec<PromoteRetireOp<TestEntry>>` sequences;
  verify all four invariants hold for every prefix of every generated sequence.

**Formal-verifier directive (F-P2A234-05):** Author VP-020 body file at
`.factory/specs/verification-properties/vp-020-promote-retire-channel-idempotency.md`
with the properties above. DI anchor: DI-001. DI-014 is inapplicable (pure function;
same adjudication rationale as VP-017 and PromoteRetireChannel DI ruling above).

**Product-owner directive (F-P2A234-05):** Add to BC-2.02.009 §VP Anchors: VP-020
(proptest, {INV-001} + {INV-002} idempotency, no-duplicate, and identity preservation).
Add to BC-2.02.009 §Verification Properties table:
`VP-020 | PromoteRetireChannel promote idempotency, retire idempotency, no-duplicate, identity preservation across arbitrary operation sequences | proptest | Phase 3`

**Downstream propagation required (F-P2A225-01) — product-owner action:** DI-014 is NOT
orphaned (remains cited by 237+ other BCs; POL-2 not triggered).

| Artifact | Location | Action |
|----------|----------|--------|
| BC-2.02.007 | §Traceability L2 Domain Invariants | Remove DI-014 entry; retain DI-001 |
| BC-2.02.009 | §Traceability L2 Domain Invariants | Replace DI-014 entry with DI-001 |
| prd.md §2 | BC-2.02.007 row Invariants column | Remove DI-014 |
| prd.md §2 | BC-2.02.009 row Invariants column | DI-014 → DI-001 |
| prd.md §7 RTM | BC-2.02.007 row | Remove DI-014 |
| prd.md §7 RTM | BC-2.02.009 row | DI-014 → DI-001 |
| prd.md §12 | BC-2.02.007 row | Remove DI-014 |
| prd.md §12 | BC-2.02.009 row | DI-014 → DI-001 |

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

Rejected. The `Channel` trait is a public extension seam defined in `graph::channels` by
S-1.14 per this ADR (ADR-030 §Channel Trait Definition Home),
so user code CAN implement `Channel` for external types. However, `LedgerChannel` and
`PromoteRetireChannel` are general-purpose reducers applicable beyond the research orchestrator
use case — any `StateGraph` application accumulating keyed entries or managing promote/retire
lifecycles benefits from them. Adding these types to the canonical channel family in
`pregolya-graph` is the correct production-grade path: they ship as a maintained, tested, and
versioned part of the library rather than as per-application boilerplate.

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
| BC-2.02.009 | SS-02 | `PromoteRetireChannel` Promote/Retire Lifecycle | Promote/Retire are each idempotent; active set is the channel value [displaced from BC-2.02.008; see changelog ADR-030 §1.1] |

SS-04 BC range extends from 001–008 to **001–011**.
SS-02 BC range extends from 001–006 to **001–009** (BC-2.02.009 added; BC-2.02.008 consumed by LedgerChannel first-appearance ordering per PO Stage 2a authoring).
Total new BCs: 6 (two SS-04 trajectory BCs + three SS-02 ledger-channel BCs + one SS-04 trajectory compaction BC).

### New VP

| VP | Module | Tool | Priority | BC Anchor | Phase |
|----|--------|------|----------|-----------|-------|
| VP-017 | `graph::channels` | proptest | P1 | BC-2.02.007 + BC-2.02.008 | 3 |
| VP-018 | `checkpoint::trajectory` | proptest | P1 | BC-2.04.011 {INV-001} | 3 |
| VP-019 | `checkpoint::trajectory` | integration | P1 | BC-2.04.011 {INV-003} | 6 |
| VP-020 | `graph::channels` | proptest | P1 | BC-2.02.009 {INV-001}+{INV-002} | 3 |

**VP-017** dual anchor: BC-2.02.007 (dedup-idempotent append) + BC-2.02.008 (first-appearance
ordering) — harness exercises both properties; VP-014 two-BC precedent.

**VP-018** (proptest P1): pure-core record-selection and ordering invariants (no-loss/no-mutation
of retained records; ascending step_idx preservation). Harness extracts the selection logic from
the async SQLite layer.

**VP-019** (integration P1, Phase 6): crash-isolation invariant — SIGKILL mid-compaction,
restart, `replay(run_id)` returns pre-compaction or post-compaction state (never partial).
Promoted informal `VP-COMPACT-02` label in `BC-2.04.011 §Verification Properties` to a
real VP. **Directive discharged:** `VP-COMPACT-01` → `VP-018` and `VP-COMPACT-02` → `VP-019`
rename was completed by product-owner in BC-2.04.011 §Verification Properties (round-50/D-328). **Formal-verifier directive (F-P2A234-01):** under the per-run DELETE model
(§Compaction Atomicity Decision revised), VP-019 crash-point matrix MUST be updated from
four points to **two points** — see §BC-2.04.011 Downstream Notes.

**VP-020** (proptest P1, Phase 3): PromoteRetireChannel promote/retire idempotency and
ordering. See §Decision 3 §VP section above for full directive. Census: VP total 20→21,
P1 14→15, proptest 7→8. Arithmetic: 21 = P0(6) + P1(15) = Kani(9) + proptest(8) +
integration(3) + unit(1).

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

### OBS-3: Promoted Element Semantics Directive

**Product-owner directive (OBS-3):** Add a sentence to BC-2.04.011 {PRE-002} explicitly
stating: "`promoted: Vec<u64>` contains the `step_idx` values of specific records to be
retained regardless of their position relative to `retention_frontier`; a record whose
`step_idx` appears in `promoted` is retained even if `step_idx < retention_frontier`. This
allows milestone records (e.g., convergence evidence, landmark generation results) to survive
compaction regardless of age."

**Also:** Update interface-definitions.md §TrajectoryRetentionPolicy `promoted` field
description to add: "step_idx values in this list are unconditionally retained — even if
`step_idx < retention_frontier`."

### Architecture Invariants Unchanged

- 21 published crates — no additions.
- `deployment_topology: single-service` — unchanged.
- `graph::channels` module row in module-decomposition.md — extended in-module description; no
  new module row (ledger types are in the same module as the existing channel family).
- ADR-009 definitions-in-core pattern applied for `core::trajectory`; same exemptions apply.
- `checkpoint::trajectory` is an Effectful Shell module (storage I/O); purity-boundary-map
  updated accordingly.
