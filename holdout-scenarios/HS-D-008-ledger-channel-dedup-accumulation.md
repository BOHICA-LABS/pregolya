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
id: HS-D-008
title: "Dedup-Idempotent Evidence Accumulation with First-Appearance Ordering"
category: integration-boundaries
must_pass: true
priority: must-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.02.007
  - BC-2.02.008
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
  - "1.0 (Round-50 B2/2026-08-31): New Domain D scenario — forces LedgerChannel dedup-idempotent evidence accumulation and first-appearance ordering as observable behavior. Covers BC-2.02.007 and BC-2.02.008. Must-pass; addresses F-P2A211-08 gap: Domain D had no scenario exercising the SS-02/ledger_channel surface."
---

# Holdout Scenario HS-D-008: Dedup-Idempotent Evidence Accumulation with First-Appearance Ordering

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.
> The information asymmetry between builder and evaluator is the core quality mechanism.

---

## Scenario

A multi-step research orchestrator graph accumulates evidence items across several steps
using a shared accumulation channel. The channel enforces two observable properties:

1. **Dedup-idempotent accumulation**: an evidence item whose identifier has already been
   recorded in the channel is silently discarded — it is not appended again. The channel
   value never shrinks as a result of duplicate submissions.

2. **First-appearance ordering**: items in the accumulated list are ordered by the step at
   which their identifier was first encountered. Re-submitting a previously seen item does
   not alter the position of any existing item in the list.

The scenario directly forces both properties by submitting a known mix of novel and duplicate
items across multiple graph steps, then verifying the final accumulated value.

**Given:**
- A graph with at least four sequential steps.
- Each step emits one or more evidence items to a shared evidence accumulation channel.
- Evidence items are structured records, each with a unique stable identifier.

**Check 1 — Novel items accumulated; duplicates silently discarded**

**When** Step 1 emits items with identifiers [A, B, C] (all novel) and Step 2 emits
items with identifiers [B, D] (B is a duplicate of the item already in the channel; D is
novel):

**Then:**
1. The accumulated channel value contains exactly 4 items: the items with identifiers
   A, B, C, and D.
2. No duplicate appears — the item with identifier B appears exactly once.
3. The item with identifier D is present (novel item from Step 2 was appended).

**Check 2 — Channel never shrinks; re-submitting seen items is a no-op**

**When** Step 3 emits items with identifiers [A, B] (both already present in the channel)
and no novel items:

**Then:**
1. The accumulated channel value still contains exactly 4 items: A, B, C, D.
2. No item was removed.
3. No duplicate was created — A and B still appear exactly once each.
4. The submission of duplicates in Step 3 produced no error and no state change in the
   channel value.

**Check 3 — First-appearance order preserved; duplicates do not affect position**

**When** Step 4 emits item with identifier E (novel) and then the final accumulated channel
value is read:

**Then:**
1. The accumulated channel value contains exactly 5 items: A, B, C, D, E.
2. Items appear in first-appearance order: A (first seen in Step 1) is at position 0; B
   (first seen in Step 1) is at position 1; C (first seen in Step 1) is at position 2; D
   (first seen in Step 2) is at position 3; E (first seen in Step 4) is at position 4.
3. The duplicate B submission in Step 2 and the duplicate A, B submissions in Step 3 did
   not alter the position of any item. The ordering is solely determined by first
   submission step.

**Check 4 — Accumulated channel value is reproducible across identical input sequences**

**When** the same graph is run twice with identical step inputs:

**Then:**
1. Both runs produce the same accumulated channel value: same items, same order.
2. The accumulation result is deterministic — no random permutation occurs.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.02.007 | Dedup-idempotent append: novel entry_id appended; duplicate entry_id is silent no-op; channel never shrinks | Check 1 (novel items added, B duplicate discarded), Check 2 (A + B re-submission is no-op; channel still 4 items) |
| BC-2.02.008 | First-appearance ordering: Vec<T> ordered by chronological first submission of each entry_id; duplicate submissions do not alter position | Check 3 (A, B, C, D, E in first-appearance order; Step-2/3 duplicates did not move B or A); Check 4 (deterministic across identical runs) |

---

## Verification Approach

1. Build a 4-step sequential graph. The graph state includes an evidence accumulation channel
   configured with dedup-idempotent append semantics.
2. Configure Step 1 to emit three evidence items with identifiers "alpha", "beta", "gamma".
   Configure Step 2 to emit two evidence items with identifiers "beta" (duplicate) and
   "delta" (novel). Configure Step 3 to emit two evidence items with identifiers "alpha"
   (duplicate) and "beta" (duplicate). Configure Step 4 to emit one evidence item with
   identifier "epsilon" (novel).
3. Run the graph. After all four steps complete, read the accumulated channel value.
4. Assert the channel value contains exactly 5 items (alpha, beta, gamma, delta, epsilon).
   Assert no identifier appears more than once.
5. Assert the items are in first-appearance order: alpha at index 0, beta at index 1, gamma
   at index 2, delta at index 3, epsilon at index 4. Assert no item from Step 2 or Step 3's
   duplicate submissions changed the position of an already-present item.
6. Run the same graph a second time with identical inputs. Assert the accumulated channel
   value from the second run is identical in contents and order to the first run (Check 4).
7. Run with `cargo test` or equivalent; the test must exit 0.

---

## Evaluation Rubric

| Dimension | Weight | Must-Pass? | Passing Signal |
|-----------|--------|------------|----------------|
| Check 1: novel items accumulated; duplicates discarded; correct count | 0.30 | yes | Channel contains exactly 4 items after Steps 1+2; B appears once; D present |
| Check 2: channel never shrinks; duplicate re-submission is no-op | 0.25 | yes | Channel still 4 items after Step 3; no errors; no new duplicates |
| Check 3: first-appearance order preserved; duplicates do not shift positions | 0.30 | yes | 5 items in order [alpha, beta, gamma, delta, epsilon] after Step 4 |
| Check 4: deterministic accumulation across two identical runs | 0.15 | yes | Both runs produce identical channel values in identical order |

**Must-pass threshold (all four dimensions):** weighted average ≥ 0.70.

---

## Edge Conditions

### EC-001: All items in a step are duplicates
**Expected behavior:** A step that emits only items whose identifiers are already present in
the channel produces no change to the channel value. The channel value after the step is
identical to the channel value before the step. No error is raised.

### EC-002: First step emits zero items
**Expected behavior:** If the first step emits no evidence items, the channel starts empty.
Subsequent steps accumulate normally from that empty baseline.

### EC-003: Very large number of items accumulating across many steps
**Expected behavior:** The dedup-idempotent accumulation and first-appearance ordering
guarantee hold regardless of the total accumulated count. For N ≥ 1000 items, the channel
value remains correct and accessible without truncation or ordering violation.

### EC-004: Two novel items with the same identifier submitted in a single step
**Expected behavior:** Within a single step, if two items share the same identifier, the
channel appends the first occurrence and discards the second. The final channel contains
exactly one copy of that identifier. The specific tie-breaking within a step's submissions
is deterministic (based on deterministic task-identity-sorted write order).

### EC-005: Run resumed from checkpoint; accumulated channel preserved across resume
**Expected behavior:** When a run is resumed from a durable checkpoint after a process
restart, the evidence accumulation channel value is restored to the state at the last
committed checkpoint boundary. Items accumulated before the restart are not lost and are
not duplicated by the resume.

---

## Failure Guidance

"HOLDOUT LOW: HS-D-008 (satisfaction: X.XX) — the evidence accumulation channel did
not correctly enforce dedup-idempotent semantics and/or first-appearance ordering. Likely
failure modes:

- Duplicate-append fail: a duplicate evidence item (same identifier as an already-present
  item) was appended to the channel instead of being silently discarded. The accumulated
  list contains the same identifier more than once.
- Channel-shrink fail: re-submitting duplicate items caused the channel value to shrink or
  lose previously accumulated items. The accumulated list had fewer items after a step that
  submitted only duplicates.
- Order violation: items are not in first-appearance order. An item that was first submitted
  in an earlier step appears at a higher index than an item first submitted in a later step.
  Or, a duplicate submission in a later step moved an already-present item to a new position.
- Novel-item loss: a novel item (never-before-seen identifier) submitted in a later step was
  not appended to the accumulated list. The channel value after the step was unchanged despite
  the novel submission.
- Non-determinism: two runs of the same graph with identical inputs produced accumulated
  channel values with different items or different ordering. The first-appearance position of
  a given identifier differed between runs."

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

Not applicable — this scenario's category is `integration-boundaries` (see the frontmatter `category:` field). No real-world corpus is required for this `integration-boundaries` test.
