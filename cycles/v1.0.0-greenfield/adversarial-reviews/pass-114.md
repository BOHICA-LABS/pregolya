---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T23:50:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 114
previous_review: pass-113.md
---

# Adversarial Review: ferrochain (Pass 114)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 113 was CLEAN strict (zero findings); there are no prior-pass findings to verify.
Frozen-corpus spot-checks confirm the corpus state matches the pass-113 committed baseline:

| Check | Result |
|-------|--------|
| F-P112-01 resolution (BC-2.11.002 v1.8, BC-2.11.003/004 v1.7; bare `content_type` variants) | CONFIRMED intact — no qualified-path forms (`IngressContent::ToolResult` etc.) present in any BC body; bc-authoring-plan v2.39 gate #33 entry unchanged |
| F-P112-02 resolution (E-CORE-005 canonical format at 5 BC sites; error-taxonomy v1.26 adjudication row) | CONFIRMED intact — all 5 sites carry `Validation failed for '<field>': <reason>` format |
| ADR-005 content at pass-114 time (pre-fix burst 117) | STALE STATE FOUND — see F-P114-01 below |
| All other pass-113 CLEAN axes (TV-count 513, VP-INDEX, NFR/VP cross-consistency, BC-INDEX arithmetic, module-criticality, IngressBoundary vs BoundaryType) | CONFIRMED — no drift detected |
| Corpus frozen since burst 198 (no spec edits since pass-113 commit) | CONFIRMED — working tree shows no modifications outside ADR-005 class |

**Frozen-corpus rule compliance:** Confirmed. No body-content spec edits between pass-113 and pass-114 dispatch (consistent with the BC-5.39.001 frozen-corpus rule during streak).

## Part B — New Findings

### F-P114-01 — CRIT: ADR-005 rev-1 AtomicU64 MonotonicClock Violates Cross-Restart Monotonicity, PK Uniqueness, and Crash-Recovery BCs

**Severity:** CRIT
**Scope:** `specs/architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` (rev-1),
`specs/behavioral-contracts/ss-04/BC-2.04.003.md`, `BC-2.04.005.md`, `BC-2.04.006.md`,
`specs/verification-properties/VP-002.md`, Architecture Anchors of BC-2.04.001–007

#### Evidence Chain (6 steps)

**Step 1 — API signature mismatch (BC-2.04.003 PC1)**

ADR-005 v1.0 defined the checkpoint ID generation API as:
```rust
impl MonotonicClock {
    pub fn next_id(&self) -> CheckpointId { ... }
}
```
with an `AtomicU64` field on the `MonotonicClock` struct as the counter.

BC-2.04.003 PC1 mandates:
> A `CheckpointSaver` implementation provides a `get_next_version(current, channel)` method

The BC-2.04.003 canonical test vectors and postconditions presuppose this exact signature. The ADR-005 rev-1 signature `next_id(&self)` takes no `current` parameter and returns `CheckpointId` (not `Result<CheckpointId, FerrochainError>`). These are structurally incompatible: a caller of `next_id` cannot supply the persisted `CheckpointId` from the loaded `CheckpointTuple`, nor propagate an overflow error.

**Step 2 — Cross-restart monotonicity violated (BC-2.04.003 Inv1)**

ADR-005 v1.0 included the explicit claim:
> "Cross-instance ordering: not required; each process restart starts a new saver instance."

BC-2.04.003 Inv1 states:
> For checkpoints C1 and C2 on the same `(thread_id, checkpoint_ns)`: if C1 was created before C2, then `C1.checkpoint_id < C2.checkpoint_id` under the natural ordering of the ID type.

There is no restart exception in Inv1. A fresh `MonotonicClock` instance backed by an `AtomicU64` starting at 0 will emit `CheckpointId(1)` as its first value after any restart, regardless of how many checkpoints were written before the restart for the same `(thread_id, checkpoint_ns)` pair. If the persisted maximum for that pair was, say, `CheckpointId(47)`, then post-restart the next ID emitted is `CheckpointId(1)` — a strict regression, violating Inv1.

**Step 3 — Crash recovery protocol violated (BC-2.04.005)**

BC-2.04.005 specifies crash recovery semantics: completed tasks are not re-executed after a process restart, and recovery resumes the same `thread_id`. The saver must write new checkpoint state for in-progress tasks to storage as part of the recovery.

Under the ADR-005 rev-1 design, a restarted saver begins its `AtomicU64` counter at 0. For any `(thread_id, checkpoint_ns)` pair that had checkpoints before the crash, the saver will attempt to write new checkpoints with IDs starting at 1 — IDs that already exist in storage. The result is either a primary-key collision (rejected write, recovery stalls) or a silent overwrite of prior state (data corruption). Neither outcome satisfies BC-2.04.005.

**Step 4 — Composite PK uniqueness violated after restart (BC-2.04.006 Inv1)**

BC-2.04.006 Inv1 establishes:
> The triple `(thread_id, checkpoint_ns, checkpoint_id)` is the composite primary key in every backend schema; no backend may use bare `checkpoint_id` as a sole primary key.

This invariant must hold across ALL storage — including across restarts. After one restart, an `AtomicU64`-backed saver generates `CheckpointId(1)` for the same `(thread_id, checkpoint_ns)` pair that already has a `CheckpointId(1)` from before the crash. The composite PK `(thread_id, checkpoint_ns, 1)` collides with the pre-crash record. This is a direct violation of Inv1 and makes this BC a Kani VP seed with the wrong behavioral guarantee underneath it.

**Step 5 — VP-002 "per saver instance" framing incorrect**

VP-002 v1.0 described the uniqueness property with the phrase "unique per saver instance" in its traceability section. This phrase mirrors the ADR-005 rev-1 scoping ("each process restart starts a new saver instance") and is therefore incorrect: under BC-2.04.006 Inv1, the PK must be unique across the entire durable store — not scoped to one saver instance's runtime. A Kani proof written against the "per saver instance" framing would not exercise the cross-restart PK collision case, leaving the most critical invariant unverified.

**Step 6 — Nonexistent architecture anchor; zero corpus text on persisted-max seeding**

All 7 ss-04 BCs (BC-2.04.001 through BC-2.04.007) cite `architecture/ferrochain-checkpoint.md` in their Architecture Anchors sections. This file does not exist anywhere in the corpus — not in `specs/architecture/`, not in `specs/architecture/decisions/`, not anywhere under `.factory/`. The ARCH-INDEX.md has no entry for `ferrochain-checkpoint.md`. The anchor citations are fabricated paths from BC authoring time.

Compounding this: there is zero corpus text describing a persisted-max seeding mechanism. ADR-005 rev-1 had no seeding at all (the AtomicU64 starts at 0). No BC, supplement, or ADR anywhere in the corpus describes how a `CheckpointSaver` should obtain the persisted maximum `checkpoint_id` for a `(thread_id, checkpoint_ns)` pair before calling any ID-generation function. The complete seeding design is absent from the spec corpus, making implementation of the correct behavior impossible without further architect guidance.

#### Failure Modes

| Failure mode | Trigger | Impact |
|---|---|---|
| PK collision on restart | Process restarts after writing ≥1 checkpoint; saver generates `CheckpointId(1)` again | Backend write rejection (SQLite UNIQUE constraint) or silent overwrite; data corruption |
| Ordering regression on restart | `CheckpointId` post-restart ≤ last pre-restart ID for same pair | `ORDER BY checkpoint_id DESC` returns wrong ordering; `get_latest` returns stale state |
| Incorrect Kani target | VP-002 proof exercises "per saver instance" scope | Cross-restart PK collision invariant not formally verified; Phase 6 proof provides false assurance |
| Dead anchor citation | Implementation consults `architecture/ferrochain-checkpoint.md` | Implementer finds 404; either invents a design or stalls Phase 3 delivery |

#### Required Fix

1. **ADR-005 rev-2:** Replace `MonotonicClock` struct + `AtomicU64` + `next_id(&self)` with a stateless ZST and `get_next_version(current: Option<CheckpointId>, _channel: &ChannelName) -> Result<CheckpointId, FerrochainError>`. Define seeding scope as per `(thread_id, checkpoint_ns)` pair via the persisted `CheckpointTuple` returned by `get_tuple()`. Retract the "Cross-instance ordering: not required" claim. Document E-CHKPT-003 failure path if `get_tuple()` fails.
2. **VP-002 v1.1:** Broaden traceability note from "per saver instance" to "unique across the durable store (monotonicity preserved across restarts via persisted-max seeding)."
3. **BC-2.04.001–007 Architecture Anchors:** Replace all 7 nonexistent `architecture/ferrochain-checkpoint.md` citations with adjudicated real targets per architect guidance.
4. **tooling-selection.md:** Update any `next_id` → `get_next_version` reference.

## Cleared Axes (Frozen-Corpus Spot-Checks)

| Axis | Result |
|------|--------|
| Semport risks R8/R10/R11 → BC coverage (carried from prior passes) | CLEAN — BC-2.07.002 (R8 splitter parity), BC-2.02.003/004 (R10), BC-2.09.004/005 (R11) all intact |
| api-surface ↔ interface-definitions ↔ error-taxonomy internal consistency (sample 10 BCs) | CLEAN — 10 sampled BCs consistent with interface-definitions + error-taxonomy |
| ADR-002 soundness (carried from prior passes) | CLEAN — no change to ADR-002 corpus |

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 1 (F-P114-01: ADR-005 rev-1 AtomicU64 violates cross-restart monotonicity, PK uniqueness, crash recovery; nonexistent anchor class) |
| HIGH | 0 |
| MED | 0 |
| LOW | 0 |
| OBS | 0 |
| **Total findings** | **1** |

**CLEAN (strict):** no (1 CRIT finding)
**CLEAN (PR-merge):** no (1 CRIT finding)

**Convergence counter:** RESET to 0/3 (BC-5.39.001 — pass 114 NOT CLEAN strict; fix burst 117 pushes new HEAD; streak from pass 113 invalidated)
**Novelty:** HIGH (CRIT finding identifies a fundamental design divergence between ADR-005 rev-1 AtomicU64 counter and BC-2.04.003/005/006 cross-restart invariants; persisted-max seeding concept absent from corpus entirely; anchor-class sweep finds all 7 ss-04 BCs cite a nonexistent file)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 114 |
| **New findings** | 1 |
| **Cleared axes** | R8/R10/R11 BC coverage; api-surface ↔ interface-definitions ↔ error-taxonomy (sample); ADR-002 soundness |
| **Novelty score** | HIGH |
| **Median severity** | CRIT |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (CRIT; streak RESET 1/3→0/3; fix burst 117 dispatched; NEXT: pass 115 on new HEAD) |
