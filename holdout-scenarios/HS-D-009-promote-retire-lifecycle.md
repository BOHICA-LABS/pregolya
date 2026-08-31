---
document_type: holdout-scenario
level: ops
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-08-31T00:00:00Z
phase: 2
domain: D
domain_name: Autonomous Research Orchestrator
id: HS-D-009
title: "Active-Set Promote/Retire Lifecycle with Idempotency"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.02.009
inputs:
  - .factory/specs/prd.md
input-hash: "d8d03ee"
traces_to: .factory/specs/prd.md
lifecycle_status: active
introduced: v1.0.0-phase-2-r50b2
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
coverage_areas:
  - graph_execution
  - ledger_channel
  - composition
changelog:
  - "1.0 (Round-50 B2/2026-08-31): New Domain D scenario — forces PromoteRetireChannel promote/retire lifecycle, idempotency, and no-duplicate invariant as observable behavior. Covers BC-2.02.009. Must-pass; addresses F-P2A211-08 gap: Domain D had no scenario exercising the SS-02/promote-retire surface."
---

# Holdout Scenario HS-D-009: Active-Set Promote/Retire Lifecycle with Idempotency

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A research orchestrator graph manages a pool of candidate entries using an active-set
channel that supports two operations: **promoting** an entry adds it to the active set
(or is a safe no-op if it is already active); **retiring** an entry removes it from the
active set by its identifier (or is a safe no-op if it is already absent). Both operations
are idempotent. The active set never contains duplicate entries.

The scenario directly exercises the promote/retire lifecycle through a multi-step graph
that promotes candidates, retires superseded candidates, and re-promotes already-active
entries, verifying the observable state of the active set at each boundary.

**Given:**
- A graph with at least five sequential steps.
- Each step emits one or more promote or retire operations to a shared active-set channel.
- Entries in the active set are structured records with unique stable identifiers.

**Check 1 — Promote adds entry to the active set**

**When** Step 1 promotes entries with identifiers [A, B, C]:

**Then:**
1. The active set contains exactly [A, B, C] (3 entries).
2. No entry appears more than once.

**Check 2 — Retire removes an entry; retire of absent entry is a no-op**

**When** Step 2 retires entry B (present) and retires entry X (never added — absent):

**Then:**
1. The active set contains exactly [A, C] (2 entries). Entry B has been removed.
2. The retire of entry X produced no error and no change to the active set.
   The active set still contains exactly [A, C].

**Check 3 — Promote is idempotent; re-promoting an already-active entry adds no duplicate**

**When** Step 3 promotes entries [A, D] (A is already active; D is novel):

**Then:**
1. The active set contains exactly [A, C, D] (3 entries).
2. Entry A appears exactly once — the re-promote of the already-active A did not add a
   second copy.
3. Entry D was successfully added as a novel entry.

**Check 4 — Mixed promote/retire sequence; no duplicate; correct final active set**

**When** Step 4 promotes [E, F] (both novel) and retires [A, C] (both present):

**Then:**
1. The active set contains exactly [D, E, F] (3 entries).
2. No duplicate entry exists — each identifier appears exactly once.
3. Entries A and C have been removed.

**Check 5 — Retire of already-retired entry is a no-op; active set unchanged**

**When** Step 5 retires [A, C] (both already absent from the active set):

**Then:**
1. The active set is unchanged — still [D, E, F].
2. No error is raised.
3. No entry was removed from or added to the active set.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.02.009 | Promote adds novel entry (PC-001); Promote is idempotent for existing entry (PC-002); Retire removes present entry (PC-003); Retire is idempotent for absent entry (PC-004); no errors for idempotent ops (PC-005); no duplicate entry_id in active set at any time (INV-001) | Check 1 (PC-001: A,B,C promoted), Check 2 (PC-003: B retired; PC-004: X retire no-op), Check 3 (PC-002: A re-promote no-op + PC-001: D added), Check 4 (PC-001: E,F added; PC-003: A,C removed), Check 5 (PC-004: already-absent retire is no-op) |

---

## Verification Approach

1. Build a 5-step sequential graph. The graph state includes an active-set channel
   configured with promote/retire semantics.
2. Configure Step 1 to emit promote operations for identifiers "alpha", "beta", "gamma".
3. Configure Step 2 to emit a retire for "beta" (present) and a retire for "xray"
   (never promoted — absent).
4. Configure Step 3 to emit promote operations for "alpha" (duplicate — already active)
   and "delta" (novel).
5. Configure Step 4 to emit promote operations for "echo" and "foxtrot" (both novel),
   and retire operations for "alpha" and "gamma" (both present).
6. Configure Step 5 to emit retire operations for "alpha" and "gamma" (both already
   absent from the active set).
7. After each step, assert the active set state matches the expected set. Specifically:
   - After Step 1: active set = {"alpha", "beta", "gamma"} (3 entries, no duplicates).
   - After Step 2: active set = {"alpha", "gamma"} ("beta" removed; "xray" retire
     was no-op; active set is 2 entries).
   - After Step 3: active set = {"alpha", "gamma", "delta"} (re-promote of "alpha"
     added no duplicate; "delta" added; 3 entries).
   - After Step 4: active set = {"delta", "echo", "foxtrot"} ("echo" and "foxtrot"
     added; "alpha" and "gamma" removed; 3 entries).
   - After Step 5: active set = {"delta", "echo", "foxtrot"} (already-absent retires
     were no-ops; active set unchanged).
8. At every step boundary, assert no identifier appears more than once in the active set.
9. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Must-Pass? | Passing Signal |
|-----------|--------|------------|----------------|
| Check 1: promote adds novel entries; no duplicates | 0.20 | yes | Active set = {A, B, C} after Step 1; each identifier once |
| Check 2: retire removes present entry; retire of absent entry is no-op | 0.20 | yes | Active set = {A, C} after Step 2; no error for X retire |
| Check 3: promote is idempotent; re-promote adds no duplicate | 0.20 | yes | Active set = {A, C, D} after Step 3; A appears once |
| Check 4: mixed promote/retire; correct final active set; no duplicate | 0.25 | yes | Active set = {D, E, F} after Step 4; A and C absent |
| Check 5: retire of already-absent entry is no-op; no error | 0.15 | yes | Active set unchanged at {D, E, F} after Step 5; no error |

**Must-pass threshold (all five dimensions):** weighted average ≥ 0.70.

---

## Edge Conditions

### EC-001: Promote and retire the same identifier in a single step
**Expected behavior:** If a step emits both a promote and a retire for the same identifier,
the operations are processed in deterministic order (based on task-identity-sorted write
order). The final state of the identifier in the active set is determined by which
operation was processed last. No error is raised.

### EC-002: Empty active set at start; retire is no-op
**Expected behavior:** Retiring an entry from an empty active set produces no error and
leaves the active set empty.

### EC-003: Promote an entry, retire it, and promote it again
**Expected behavior:** The second promote re-adds the entry to the active set as if it
were novel. The active set contains exactly one copy of the entry after the second promote.

### EC-004: Active set with many entries; no duplicate invariant holds
**Expected behavior:** For N ≥ 100 active entries, the no-duplicate invariant holds
regardless of the number of promote and retire operations applied. No identifier appears
more than once at any step boundary.

### EC-005: Run resumed from checkpoint; active set state preserved
**Expected behavior:** When a run is resumed from a durable checkpoint after a process
restart, the active-set channel value is restored to the state at the last committed
checkpoint boundary. Entries that were active before the restart are still active; entries
that were retired before the restart remain absent.

---

## Failure Guidance

"HOLDOUT LOW: HS-D-009 (satisfaction: X.XX) — the active-set promote/retire channel
did not correctly enforce its lifecycle semantics or idempotency guarantees. Likely
failure modes:

- Promote duplicate fail: promoting an already-active entry added a second copy. The
  active set contained the same identifier more than once after the re-promote.
- Retire no-op fail: retiring an entry that was not in the active set raised an error
  instead of being a silent no-op. Or it unexpectedly modified the active set.
- Retire correctness fail: retiring an entry that was present in the active set did not
  remove it, or removed the wrong entry, or corrupted the remaining active set.
- Mixed-operation ordering fail: in a step with both promote and retire operations,
  the final active set did not reflect the correct deterministic ordering of those
  operations, resulting in an entry that should have been present being absent, or
  vice versa.
- Post-retire re-promote fail: re-promoting an entry that had been previously retired
  failed to add it back to the active set, or added a duplicate.
- Duplicate invariant violation: the active set contained two entries with the same
  identifier at any point during the run, regardless of which operation caused it."

---

## Information Asymmetry Confirmation

**Evaluator-facing sections confirmed FREE of internal traceability identifiers (BC IDs, VP IDs, error code identifiers, and internal module-path identifiers):**
- §Scenario (Check 1 through Check 5)
- §Verification Approach
- §Evaluation Rubric (table rows and must-pass threshold)
- §Failure Guidance
- §Edge Conditions

**Exempted non-evaluator metadata sections (legitimately retain traceability IDs):**
- §Behavioral Contract Linkage (BC-ID traceability table — orchestrator metadata only)

---

## Category: real-world-corpus

Not applicable — this scenario's category is `integration-boundaries` (see the frontmatter `category:` field). No real-world corpus is required for this `integration-boundaries` test.
