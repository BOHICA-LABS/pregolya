---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 120
previous_review: pass-119.md
---

# Adversarial Review: ferrochain (Pass 120)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 119 produced one finding (plus two OBS folded):
- F-P119-01: BC-2.05.005 v1.4 Preconditions §2 guard body missing `summary_halt` clause — within-BC PC↔VP contradiction with VP-HITL-10
- OBS-1: `queued` and `cancelled` absent from Preconditions §2 guard (delegation gap vs BC-2.05.004)
- OBS-2: VP-HITL-10 "five states" count imprecise once OBS-1 resolved

Fix burst 122 was dispatched (BC-2.05.005 v1.4→v1.5; BC-2.05.004 v1.3→v1.4; test-vectors v1.8→v1.9). Verification follows.

### F-P119-01 + OBS-1 + OBS-2 Verification — ALL CLOSED

**PASS-120 sibling-checks verification (checks a–f from PASS-120 SIBLING-CHECKS):**

| Check | Result |
|-------|--------|
| (a) BC-2.05.005 v1.5 Preconditions §2 seven-case guard (clauses a-g): completed (a), failed (b), in_progress (c), interrupted/slots-consumed (d), summary_halt (e), queued (f), cancelled (g) — complete predicate over all non-interrupted run_status values | PASS — BC-2.05.005 v1.5 Preconditions §2 enumerates all 7 cases; clauses (e) summary_halt, (f) queued, (g) cancelled added by fix burst 122; guard is a complete predicate over all non-interrupted run_status values per OBS-1 production-grade totality adjudication |
| (b) BC-2.05.004 v1.4 delegation coherent: Invariants non-interrupted guard (lines 99-101) enumerates all six statuses and delegates to BC-2.05.005; both BCs bidirectionally coherent | PASS — BC-2.05.004 v1.4 Invariants §4 delegates queued, in_progress, completed, failed, cancelled, summary_halt → BC-2.05.005; BC-2.05.005 v1.5 Preconditions §2 covers all six non-interrupted statuses; delegation coherent in both directions |
| (c) VP-HITL-10 rewritten 7-case: "six non-interrupted run_status values (completed, failed, in_progress, summary_halt, queued, cancelled) plus the interrupted-slots-consumed scenario (PC2(d)/TV-002) — 7 total parameterized test cases" | PASS — VP-HITL-10 in BC-2.05.005 v1.5 reads verbatim: "six non-interrupted run_status values (completed, failed, in_progress, summary_halt, queued, cancelled) plus the interrupted-slots-consumed scenario (PC2(d)/TV-002) — 7 total parameterized test cases"; OBS-2 resolved |
| (d) test-vectors v1.9: BC-2.05.005 TV Count 8, SS-05 subtotal 5+5+5+6+8+6=35, canonical total 507, all vectors 516 — independently re-summed | PASS — BC-2.05.005 TV Count 8 (TV-001 through TV-008); SS-05 subtotal 35 (5+5+5+6+8+6=35 independently verified); canonical total 507; all-vector total 507+9=516 (9 non-canonical supplemental vectors); arithmetic VERIFIED |
| (e) STATE.md baseline reads "test-vectors 516=507+9" | PASS — STATE.md Session Resume Checkpoint and Convergence Status both cite "test-vectors 516=507+9" (507 canonical + 9 supplemental) |
| (f) No live doc cites 504 or 513 as TV totals | PASS — corpus-wide grep: no live document cites 504 or 513 as canonical or all-vector totals; all prior 504/513 references are in archived changelog rows (exempt) |

**F-P119-01 conclusion:** CLOSED — BC-2.05.005 v1.5 Preconditions §2 normative guard body enumerates all 7 cases matching VP-HITL-10 parameterized test case count; PC↔VP contradiction eliminated.
**OBS-1 conclusion:** CLOSED — production-grade totality adjudication applied; queued (f) and cancelled (g) added to Preconditions §2 guard; delegation from BC-2.05.004 bidirectionally coherent.
**OBS-2 conclusion:** CLOSED — VP-HITL-10 rewritten to 7-case derivable count (6 non-interrupted run_status + 1 slots-consumed); "five" replaced by derivable count with explicit enumeration.

**Cleared axes for this pass:**

| Axis | Files Probed | Result |
|------|-------------|--------|
| ss-13 env-allowlist (server configuration allowlist gate) | BC-2.13.*, interface-definitions §server-config env filtering | CLEAN — no findings; allowlist gate consistent across BC bodies and interface supplement |
| ss-07 GTV Red Gate (Graph Termination Variant budget ceiling gate) | BC-2.07.* (splitter/GTV), verification-architecture §GTV Red Gate, test-vectors SS-07 | CLEAN — no findings; GTV Red Gate vectors and architecture anchors consistent |
| schedule lifecycle | BC-2.12.004 v1.3 cron-run lifecycle, BC-2.12.003 v1.4 RunStatus lifecycle | CLEAN — no findings; cron PC2b lifecycle arrow includes all four terminal statuses; sibling coherence with F-P118-01/02 corrections confirmed |

**Summary_halt cascade closure verification:** BC-2.05.005 Preconditions §2 (7-case guard), BC-2.05.004 Invariants (6-status delegation), VP-HITL-10 (7-case derivable), test-vectors v1.9 TV Count 8 for BC-2.05.005, SS-05 subtotal 35, totals 507/516 — FULLY CLOSED. No residual summary_halt cascade gaps detected.

---

## Part B — New Findings

### F-P120-01 — HIGH: Command Modeled as 2-Variant Enum in Domain Spec vs BC-2.05.004 Authoritative Struct Form

**Severity:** HIGH
**Scope:** `specs/domain-spec/entities-server.md` line 78; `specs/domain-spec/ubiquitous-language-core.md` line 142

#### Evidence

**BC-2.05.004 authoritative model (normative):**

BC-2.05.004 Invariants and body define `Command` as a struct with **four optional fields**:

| Field | Type | Description |
|-------|------|-------------|
| `resume` | `Option<ResumeValue>` | Resume from interrupt |
| `update` | `Option<UpdateValue>` | State mutation |
| `goto` | `Option<GotoValue>` | Control flow |
| `graph` | `Option<SubgraphValue>` | Subgraph dispatch |

Under BC-2.05.004, any combination of these fields may be populated simultaneously — this is the **combinability invariant** (`Command.PARENT`). Compound commands (e.g., resume + update simultaneously) are explicitly modeled via co-presence of multiple `Some(_)` fields. The `Command.PARENT` super-node confirms that a single `Command` may exercise multiple capabilities at once; the struct form is the normative shape for this invariant.

**Domain spec depictions (non-normative, contradictory):**

`entities-server.md` line 78 and `ubiquitous-language-core.md` line 142 both depict `Command` as a 2-variant enum:

```
enum Command {
    Resume(ResumeValue),
    Update(UpdateValue),
}
```

Only 2 variants shown; `GotoValue` and `SubgraphValue` absent. The enum form structurally forbids co-presence of multiple variants — a fundamental mismatch with the combinability invariant.

**Unrepresentability impact:**

The enum form makes compound commands structurally unrepresentable:

| Compound Scenario | BC-2.05.004 (struct) | entities-server enum | Status |
|-------------------|----------------------|---------------------|--------|
| EC-001: Resume + simultaneous state update | `Command { resume: Some(_), update: Some(_) }` | Single-variant only | **UNREPRESENTABLE** |
| TV-002: Resume command into `in_progress` (compound) | struct — co-presence | Single-variant only | **UNREPRESENTABLE** |
| TV-003: compound resume+goto control-flow | struct — co-presence | Single-variant only | **UNREPRESENTABLE** |

The `Command.PARENT` super-node — which explicitly allows multi-field co-presence — has no representation in the 2-variant enum.

**Root cause:** `entities-server.md` and `ubiquitous-language-core.md` were authored with a simplified enum depiction prior to BC-2.05.004's combinability invariant and `Command.PARENT` being hardened (passes 117-118). The domain spec sections were not updated in the same burst as the BC strengthening.

**Impact:** HIGH — `entities-server.md` is the normative entity reference for Phase 3 implementers; `ubiquitous-language-core.md` is the ubiquitous language glossary. Both feeding Phase 3 with an enum form that makes compound commands structurally unrepresentable would produce a Phase 3 type definition that compiles but fails EC-001/TV-002/TV-003. Source-of-truth precedence (CLAUDE.md §Source-of-Truth Precedence Rule 1) mandates BC wins on contract semantics; domain spec depictions must be corrected to mirror the BC struct form.

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 1 (F-P120-01: Command modeled as 2-variant enum in entities-server.md:78 + ubiquitous-language-core.md:142 vs BC-2.05.004 authoritative struct {resume,update,goto,graph}+Command.PARENT; compound commands EC-001/TV-002/TV-003 unrepresentable) |
| MED | 0 |
| LOW | 0 |
| OBS | 0 |
| **Total findings** | **1** |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — iterate
**Readiness:** requires revision

**CLEAN (strict):** no (1 HIGH finding)
**CLEAN (PR-merge):** no (1 HIGH finding)

**Convergence counter:** 0/3 (counter unchanged — pass 120 NOT CLEAN strict; fix burst 123 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** MEDIUM-HIGH (F-P120-01 is a BC-strengthening-without-domain-spec-propagation class — combinability invariant introduced via passes 117-118 was not propagated to the two L2 domain spec entity/glossary sections; novel class for this cascade; impacted compound-command test vectors EC-001/TV-002/TV-003 are directly unrepresentable in enum form)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 120 |
| **New findings** | 1 (F-P120-01 HIGH) |
| **Cleared axes** | F-P119-01/OBS-1/OBS-2 ALL CLOSED; summary_halt cascade FULLY CLOSED (7-case guard, TV arithmetic 8/35/507/516 independently re-summed PASS); ss-13 env-allowlist CLEAN; ss-07 GTV Red Gate CLEAN; schedule lifecycle CLEAN |
| **Novelty score** | MEDIUM-HIGH — new BC-strengthening-without-domain-spec-propagation class; enum vs struct Command contradiction makes compound commands EC-001/TV-002/TV-003 structurally unrepresentable; first occurrence of combinability-invariant propagation gap in Phase 1d cascade |
| **Median severity** | HIGH |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1→3→1→1 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (1 HIGH; counter 0/3 unchanged; fix burst 123 dispatched; NEXT: pass 121 on new HEAD after fix burst 123) |
