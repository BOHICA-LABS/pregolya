---
document_type: adversarial-review
pass: 7
phase: 1d
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
finding_count: 3
sibling_checks: status/plan-sync PASS; run-state FAIL (3rd recurrence — pass-6 grep false-negative on backtick/slash forms)
trajectory: "14→5→7→13→3→3→3"
convergence_counter: "0/3"
produced_by: product-owner
timestamp: 2026-07-14T00:00:00Z
process_gap: complement-assertion mandate GENERALIZED to all controlled vocabularies (run-status, category, component) — Phase 2 lint story updated
---

# ADV-P1D-PASS-7 — Adversarial Review

**Verdict:** NOT CLEAN — 3 findings (1 HIGH, 1 MED, 1 LOW)

---

## Sibling Checks

| Check | Result |
|-------|--------|
| status/plan-sync | PASS |
| Complement tables (full distinct-value tables) | PASS |
| Disambiguating codes present | PASS |
| 5/5 spot rotation | GREEN |
| 14/14 DIs — no orphans | PASS |
| **run-state vocabulary** | **FAIL — 3rd recurrence** |

**Root-cause of recurrence:** Pass-6 complement evidence used `grep "→ running\|running →\|\"running\""`. This pattern missed backtick-quoted form `` `running` `` when not adjacent to `→` or in double-quotes (e.g., `status \`running\`, \`completed\`` in invariants), and missed slash-delimited form `completed/failed/running` in Related BCs and VP param lists. Complement assertion mandate is now GENERALIZED to all controlled vocabularies.

---

## Findings

### F-P7-01 [HIGH] — 6 surviving `running` run-status tokens (3rd recurrence)

**Locations (pre-fix):**
- `BC-2.05.004.md:73` — "run status transitions from `interrupted` → `running`" (postcondition 7)
- `BC-2.05.004.md:86` — "status `running`, `completed`, or `failed`" (invariants) — non-interrupted set incomplete
- `BC-2.05.005.md:49` — precondition 2c "`running` — the run is still executing"
- `BC-2.05.005.md:120` — VP-HITL-10 param list "completed/failed/**running**/slot-exhausted"
- `BC-2.05.005.md:127` — Related BCs misquote "run lifecycle states (completed/failed/**running**)"
- `BC-2.12.001.md:116` — EC-005 scenario "state: `running`"

**Canonical lifecycle:** `queued → in_progress → completed | failed | interrupted | cancelled`

**Fixes applied:**
- `BC-2.05.004.md:73`: `running` → `in_progress`
- `BC-2.05.004.md:86`: "status `running`, `completed`, or `failed`" → "status `queued`, `in_progress`, `completed`, `failed`, or `cancelled`" (full non-interrupted set)
- `BC-2.05.005.md:49`: `running` → `in_progress`
- `BC-2.05.005.md:120`: VP-HITL-10 param list → `completed/failed/in_progress/slot-exhausted`
- `BC-2.05.005.md:127`: misquote → "queued/in_progress/completed/failed/interrupted/cancelled … BC-2.12.003 defines `in_progress`"
- `BC-2.12.001.md:116`: `state: \`running\`` → `state: \`in_progress\``

**Post-fix complement evidence:**
```
grep -rn "→ running\|running →\|\"running\"\|status.*\`running\`|\`running\`.*status|run_status.*running" .factory/specs/
(no output)
```
Result: 0 hits.

**Whitelist-complement classification table (all remaining `running` hits):**

| File:Line | Hit | Classification |
|-----------|-----|----------------|
| `test-vectors.md:195` | "running ferrochain instance" | (b) justified — prose verb (server process operation) |
| `BC-2.12.006.md:99` | "long-running operation" | (b) justified — adjective for operation duration |
| `BC-2.12.002.md:40` | "ferrochain-server is running" | (b) justified — server process state, not RunStatus token |
| `BC-2.12.003.md:41` | "ferrochain-server is running" | (b) justified — server process state |
| `BC-2.12.004.md:47` | "scheduler subsystem is running" | (b) justified — server process state |
| `BC-2.12.001.md:40` | "ferrochain-server is running" | (b) justified — server process state |
| `BC-2.12.001.md:115` | "POST /state concurrent with running Run" | (b) justified — section heading adjective, not status token |
| `BC-2.13.006.md:43,48,92` | "running under that profile / silently running / Running under" | (b) justified — prose verb (sandbox execution context) |
| `BC-2.07.002.md:84` | "running the reference Python implementation" | (b) justified — prose verb |
| `BC-2.06.003.md:36` | "running the graph" | (b) justified — prose verb |
| `BC-2.17.001.md:68`, `BC-2.17.002.md:120` | "Running `cargo kani`", "before re-running" | (b) justified — prose verb (CI command) |
| `BC-2.04.007.md:49` | "The graph is running" | (b) justified — present-tense prose describing execution |
| `BC-2.04.005.md:90` | "node bodies running" | (b) justified — prose verb |
| `BC-2.05.001.md:34` | "inside a running node" | (b) justified — adjective for node execution state |
| `BC-2.05.005.md:35` | "is still running" | (b) justified — prose clause (not a RunStatus code literal) |
| `BC-2.05.005.md:60` | "from 'still running'" | (b) justified — prose comparison |
| `BC-2.05.005.md:99` | "still actively running (no interrupt yet)" | (b) justified — section heading prose |
| `BC-2.02.002.md:45` | "running in-memory" | (b) justified — prose (memory mode description) |
| `ADR-001.md:38,68,151` | "per running task", "long-running graphs ×2" | (b) justified — prose adjectives |
| `invariants.md:125` | "without running the actual graph" | (b) justified — prose verb |
| `BC-2.02.002.md:109` | `status \`done\`` — BarrierValue EC-003 natural halt | (a) fixed this burst → "halts naturally (run transitions to \`completed\`)" |
| `BC-2.02.005.md:57,80,99,113` | `status \`done\`` — END routing natural completion (4 instances) | (a) fixed this burst → `completed` / "halts naturally (run transitions to \`completed\`)" |
| `BC-2.10.003.md:51` | "already done; no new" | (b) justified — prose word, not a status token |
| `ADR-001.md:100` | "declaring the super-step done" | (b) justified — prose word |

Zero unclassified.

---

### F-P7-02 [MED] — verification-architecture.md:149 "No P1 VPs" contradicts own table

**Location:** `verification-architecture.md:149`

**Finding:** The section header says "No P1 VPs committed at Phase 1" but the Committed VP
Obligations table at line 59–60 shows VP-004 and VP-005 as P1 VPs. The actual situation
is: no P1 **Kani** VPs are committed; the 2 P1 VPs (VP-004/VP-005) are integration-tier,
assigned to Phase 3.

**Fix applied:**
> "No P1 Kani VPs committed at Phase 1 (the 2 committed P1 VPs — VP-004/VP-005 — are
> integration-tier, Phase 3). Additional Kani candidates for Phase 6 consideration:"

---

### F-P7-03 [LOW] — bc-authoring-plan.md:259 `create` initial state

**Location:** `bc-authoring-plan.md:259`

**Finding:** BC-2.12.003 plan entry used "create → in_progress → completed/failed" — both
the `create` initial state (non-canonical; canonical initial state is `queued`) and the
incomplete terminal set. BC-2.12.003's own H1 title correctly uses the full canonical
lifecycle.

**Fix applied:**
> "queued → in_progress → completed | failed | interrupted | cancelled"

---

## Observation (non-finding): BC-2.02.002:109 `status \`done\``

**Location:** `BC-2.02.002.md:109`

**Context:** EC-003 (BarrierValue missing-writer) described graph halting "with status `done`
(natural completion)". The token `done` is not in the canonical server RunStatus set
(`queued`, `in_progress`, `completed`, `failed`, `interrupted`, `cancelled`). The
graph-engine layer's natural completion maps to server RunStatus `completed`.

**Fix applied:** "the graph halts naturally (run transitions to `completed`) without ever
activating the downstream node." Matches sibling BC-2.02.003:90 "halts naturally" phrasing.

**BC-2.02.005 `done` instances (4, fixed same burst):** Lines 57, 80, 99, 113 used `done`
for `END` routing natural completion. All 4 map directly to server RunStatus `completed`
with no distinct graph-engine-internal signal distinction. Fixed to `completed` /
"halts naturally (run transitions to `completed`)". Classification table updated to (a).

---

## Trajectory

| Pass | Findings |
|------|----------|
| Pass 1 | 14 |
| Pass 2 | 5 |
| Pass 3 | 7 |
| Pass 4 | 13 |
| Pass 5 | 3 |
| Pass 6 | 3 |
| Pass 7 | 3 |

Convergence counter: 0/3 (need 3 consecutive clean passes at ≤0 findings to close Phase 1d).

**Trajectory note:** Three consecutive passes at 3 findings indicates a stable residual class
(vocabulary escapes missed by grep pattern) rather than divergence. Root cause codified
as process-gap above. With complement-assertion mandate generalized, Pass 8 should find
zero run-status escapes.
