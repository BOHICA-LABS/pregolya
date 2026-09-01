---
document_type: holdout-scenario
level: ops
version: "2.2"
status: active
producer: product-owner
timestamp: 2026-08-31T00:00:00Z
phase: 2
domain: D
domain_name: Autonomous Research Orchestrator
id: HS-D-007
title: "Durable Audit-Grade Trajectory Replay"
category: edge-case-combinations
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.04.009
  - BC-2.04.010
  - BC-2.04.011
inputs:
  - .factory/specs/prd.md
input-hash: "d8d03ee"
traces_to: .factory/specs/prd.md
lifecycle_status: active
introduced: v1.0.0-phase-2-newuc
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
coverage_areas:
  - trajectory
  - checkpoint_resume
  - streaming
changelog:
  - "1.0 (initial/2026-08-31): Domain D HS-D-007 authored for autonomous research orchestrator use case. Exercised checkpoint super-step replay against pre-existing checkpoint BCs only."
  - "2.0 (Round-50 B2 fix/2026-08-31): Re-scoped to genuinely exercise the dedicated trajectory recording primitive as observable black-box behavior. Prior v1.0 scenario was satisfiable with the trajectory primitive entirely absent (it reconstructed from ordinary super-step checkpoints). New scenario requires: (a) all written trajectory records returned by replay, (b) strict ascending step-index ordering, (c) protected records survive a compaction and ordering is preserved. BC linkage updated to BC-2.04.009/010/011 (trajectory subsystem). Checkpoint super-step content removed — that coverage is retained by HS-D-001/HS-D-002. coverage_areas updated: trajectory replaces graph_execution; checkpoint_resume and streaming retained."
  - "2.1 (Round-52 Stage-C fix/2026-08-31): Promoted from should-pass to must-pass (F-P2A219-03). Durable trajectory persistence is the only Domain-D holdout exercising the SS-04 trajectory primitive, a core P1 contract. Asymmetric classification with sibling ledger holdouts HS-D-008/009 (must-pass) was unjustified. must_pass set true; priority updated to must-pass; Evaluation Rubric threshold relabeled accordingly."
  - "2.2 (round-53/HS-label-fix/2026-08-31): Information Asymmetry Confirmation §Evaluation Rubric label corrected from 'should-pass threshold' to 'must-pass threshold' — stale label surviving after Round-52 promotion to must-pass (v2.1/F-P2A219-03); frontmatter was already correct (must_pass: true, priority: must-pass)."
---

# Holdout Scenario HS-D-007: Durable Audit-Grade Trajectory Replay

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A research orchestrator run uses a dedicated trajectory recording interface — distinct from
the graph's super-step checkpoint mechanism — to log one structured audit record per step.
Each record carries a step position (a monotonically advancing logical counter) and a
structured payload. After the run completes, a replay operation retrieves all logged records
for that run in a single call.

The scenario verifies four observable properties of the trajectory recording surface:

**Given:**
- A research orchestrator run that writes N ≥ 4 trajectory records at distinct step
  positions, using the dedicated trajectory recording interface.
- Each record has a unique step position and a non-empty structured payload.
- A durable storage backend backs the trajectory recording interface so that written
  records survive process termination.

**Check 1 — All written records returned; strict ascending step-position order**

**When** the replay operation is called for the completed run in the same process:

**Then:**
1. Exactly N records are returned — one per written step.
2. The records are ordered in strictly ascending step-position order: each record's step
   position is numerically greater than the step position of the record before it in the
   returned list. No two records share the same step position.
3. The structured payload of each returned record is identical to what was written at that
   step position.

**Check 2 — Records survive process restart**

**When** the process that executed the run is terminated and a fresh process calls the
replay operation for the same run:

**Then:**
1. All N records are returned — the same set as in Check 1.
2. The records are in the same strictly ascending step-position order.
3. No record is missing or corrupted relative to the original written set.

**Check 3 — Protected records survive compaction; ordering preserved**

**When** some of the N records are designated as retained (protected from removal) and a
compaction operation is requested — instructed to remove eligible non-protected records —
and then the replay operation is called:

**Then:**
1. Every protected record is present in the replay result.
2. The protected records are returned in strictly ascending step-position order.
3. The payload of each protected record is identical to what was written.
4. No protected record was silently modified, truncated, or re-ordered by the compaction.

**Check 4 — Deterministic ordering across two replay calls**

**When** the replay operation is called twice in succession for the same completed run
(no writes between calls):

**Then:**
1. Both calls return the same set of records.
2. Both calls return records in the same strictly ascending step-position order.
3. The payloads returned in both calls are identical for each step position.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.04.009 | Durability: put_record persists across process restart; record appears in subsequent replay | Check 1 (write → replay round-trip in same process); Check 2 (survives process termination) |
| BC-2.04.010 | Replay returns all records for run_id in strictly ascending step_idx order | Check 1 (ascending order); Check 4 (deterministic across two calls) |
| BC-2.04.011 | Compaction isolation: protected/retained records survive compaction intact; ordering preserved | Check 3 (protected records present and ordered after compaction) |

---

## Verification Approach

1. Construct a run fixture that writes exactly 4 trajectory records at step positions 1, 2,
   3, and 4 via the trajectory recording interface. Use a DTU mock for any provider calls;
   the DTU mock may be online for this phase.
2. After the run completes, call the replay operation for the run. Assert exactly 4 records
   are returned. Assert step positions are [1, 2, 3, 4] in that order (no gaps, no
   duplicates). Assert each record's payload matches the written payload.
3. Simulate process termination (drop the runtime handle). In a fresh process, load the
   trajectory backend and call replay for the same run. Assert the same 4 records are
   returned in ascending step-position order (Check 2).
4. Designate step-position records 2 and 4 as protected/retained. Invoke the compaction
   operation instructed to remove records not designated as retained. Call replay. Assert
   records at step positions 2 and 4 are present. Assert no records at step positions 1 or
   3 are present. Assert the two retained records are in ascending step-position order
   (position 2 before position 4) and their payloads are unchanged (Check 3).
5. Call replay twice in succession for the same run. Assert both calls return identical
   records in identical order (Check 4).
6. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| Check 1: all records returned; ascending step-position order in same process | 0.25 | Exactly N records; step positions [1, 2, ..., N] in ascending order; payloads match |
| Check 2: records survive process restart | 0.25 | Same N records and order returned in fresh process |
| Check 3: protected records survive compaction; ordering preserved | 0.30 | Only protected records present after compaction; ascending order; payloads unchanged |
| Check 4: deterministic ordering across two replay calls | 0.20 | Both calls return identical record sets in identical order |

**Must-pass threshold:** weighted average ≥ 0.60.

---

## Edge Conditions

### EC-001: Write records in non-sequential order; verify replay ordering
**Expected behavior:** If trajectory records are written at step positions in non-ascending
submission order (e.g., position 3 written before position 2), the replay operation still
returns all records in ascending step-position order. The ordering guarantee is based on
step position, not insertion order.

### EC-002: Write record with duplicate step position
**Expected behavior:** The recording interface surfaces a structured error when a record is
submitted with a step position that already has a durably committed record for the same run.
The previously committed record at that step position is not silently overwritten.

### EC-003: Replay a run with zero records (empty trajectory)
**Expected behavior:** The replay operation returns an empty list without error. The call does
not fail or time out when the run has no trajectory records.

### EC-004: Compaction where all records are protected
**Expected behavior:** The compaction operation completes without removing any records. A
subsequent replay returns all records unchanged and in ascending step-position order.

### EC-005: Compaction mid-write (process restart between write and compaction)
**Expected behavior:** A process that terminates after writing but before compaction leaves
the pre-compaction trajectory intact. A fresh process that calls replay sees all records
written before the restart. A fresh compaction operation starts from the correct state.

---

## Failure Guidance

"HOLDOUT LOW: HS-D-007 (satisfaction: X.XX) — the dedicated trajectory recording
surface did not satisfy one or more of its durability and ordering guarantees. Likely
failure modes:

- Record completeness fail: the replay operation returned fewer than the N written records.
  The trajectory recording interface did not durably persist all writes, or the replay
  operation did not retrieve all committed records.
- Ordering violation: records were not returned in strictly ascending step-position order.
  Two records shared the same step position, or a record with a higher step position appeared
  before one with a lower step position in the returned list.
- Process-restart loss: records written before a process termination were not present in the
  replay result retrieved by a fresh process. The storage backend did not provide durable
  persistence across process boundaries.
- Compaction retention failure: a protected (retained) record was absent from the replay
  result after a compaction operation. The compaction operation removed a record that should
  have been preserved.
- Compaction ordering corruption: protected records were present after compaction but their
  step-position ordering or payload content was altered. The compaction operation modified
  records it was not authorized to remove.
- Non-determinism: two sequential replay calls on the same completed trajectory returned
  different records or different step-position ordering."

---

## Information Asymmetry Confirmation

**Evaluator-facing sections confirmed FREE of internal traceability identifiers (BC IDs, VP IDs, error code identifiers, and internal module-path identifiers):**
- §Scenario (Check 1 through Check 4)
- §Verification Approach
- §Evaluation Rubric (table rows and must-pass threshold)
- §Failure Guidance
- §Edge Conditions

**Exempted non-evaluator metadata sections (legitimately retain traceability IDs):**
- §Behavioral Contract Linkage (BC-ID traceability table — orchestrator metadata only)

---

## Category: real-world-corpus

Not applicable — this scenario's category is `edge-case-combinations` (see the frontmatter `category:` field). No real-world corpus is required for this `edge-case-combinations` test.
