---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T16:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 110
previous_review: pass-109.md
---

# Adversarial Review: ferrochain (Pass 110)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 109 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P109-01 | HIGH [process-gap] | RESOLVED | BC-2.05.005 v1.3 independently verified: all 10 E-GRAPH-002 struct sites assessed. PC1 carries `{ thread_id, run_status }` (pre-existing correct). EC-001/002/003/004, TV-001/002/003/004/005 — all 9 formerly-defective sites now carry `{ thread_id, run_status: "<value>" }`. Intra-BC field-name consistency confirmed: every site identical. Placeholder coverage: `thread_id` covers `<run_id>` (alias registered in gate #33 v2.36); `run_status` is an extra audit-utility field (valid superset). Changelog ascending v1.2→v1.3. PASS. |
| F-P109-02 | MED [process-gap] | RESOLVED | bc-authoring-plan v2.36 independently assessed for verdicts: (1) alias registry — 8 entries verified: step↔`<n>`, node↔`<node_id>`, thread_id↔`<run_id>`, offset↔`<n>` (E-PROV-009), providers_attempted↔`<N>` (E-PROV-010), backend_error↔`<reason>` (E-MEMORY-005), message↔`<reason>` CODE-SPECIFIC E-CHKPT-004 (do-not-generalize noted). All registered. ≥8 independent verdicts derivable from expanded registry. (2) context-sourced exception class: 3-part criterion present; E-MEMORY-007 registered as first instance (MemoryWriteRequest.namespace/key sourced). (3) PASS-ABBREV corollary: explicitly stated — TV-row `...` FAILS when sole struct site for that code in the BC; motivating instance BC-2.09.001 TV-004 documented. PASS. |

**Sibling-checks (burst-194 owed list):**

| Check | Result |
|-------|--------|
| (a) BC-2.05.005 v1.3 all 10 E-GRAPH-002 sites carry `{ thread_id, run_status }` — PC1 + EC-001/002/003/004 + TV-001/002/003/004/005 | PASS — 10/10 sites verified; alias thread_id↔`<run_id>` confirmed in gate #33 v2.36 alias registry; ascending changelog v1.2→v1.3 |
| (b) BC-2.09.001 v1.3 TV-004 McpTransportError `{ server, transport_error }` — no `...` abbreviation | PASS — TV-004 expanded to `{ server: "math", transport_error: "connection refused" }`; no `...`; PASS-ABBREV corollary in bc-authoring-plan v2.36 |
| (c) BC-2.13.005 v1.1 TV-002 and TV-003 both carry 3-field `{ requested, resolved, root }` | PASS — TV-002 `{ requested: "/workspace/link_a", resolved: "/etc/passwd", root: "/workspace" }`; TV-003 `{ requested: "/workspace/rel_escape", resolved: "/etc/passwd", root: "/workspace" }`; intra-BC consistency with PC4/TV-001 confirmed |
| (d) error-taxonomy v1.23 corrigendum #3 at top of changelog; v1.22 row preserved | PASS — changelog structure confirmed; v1.22 row intact; v1.23 row at top of changelog list |
| (e) gate #33 v2.36 census tally 30 codes / 3 FAIL-all-fixed / 27 PASS — re-run Steps A/B/C independently | FAILED (see F-P110-01 and Enumeration Dispute below) |

**Enumeration Dispute:**

Independent re-run of gate #33 census using a third safety grep (targeting multi-line struct forms and variant-name–anchored search) finds **≥33** struct-bearing codes in scope, not 30. The v2.36 census used two grep forms (primary `Err(E-` + `{`; secondary `E-[A-Z]*-[0-9]{3} [A-Z][A-Za-z]* {`) which are blind to multi-line struct forms where the opening `{` appears on a continuation line. Five disputed codes identified; four confirmed as genuine new struct-bearing codes (E-GRAPH-009 DuplicateNodeName BC-2.02.001, E-GRAPH-014 InterruptApprovalTimeout BC-2.05.006, E-CRON-002 InvalidCronExpression BC-2.12.004, E-SERVER-006 ScheduleNotFound BC-2.12.004); one was a false positive in the adversary's sweep. Net result: 30 prior + 4 newly-scoped = 34. Full reconciliation in fix burst 114 / burst-195 census table.

Additionally, the v2.36 census entry for E-GRAPH-002 contained a WRONG PLACEHOLDER COUNT in the corrigendum #3 rationale (stated two placeholders; actual is one). See F-P110-01.

## Part B — New Findings

### HIGH

#### F-P110-02: E-SBXD-001 WorkspaceEscape Secondary Anchor BC-2.13.004 TV-002 Still 2-Field — TD-VSDD-060 Sweep Scoped "In-File" Not "Across All Anchor BCs" [process-gap]

- **Severity:** HIGH [process-gap]
- **Owner:** PO + orchestrator
- **Category:** process-gap (census-completeness; gate #33 Step B check-1 cross-anchor scope; 5th consecutive false census completeness claim at different levels of the same gate)
- **Location:** `.factory/specs/behavioral-contracts/ss-13/BC-2.13.004.md` TV-002; `.factory/specs/prd-supplements/bc-authoring-plan.md` gate #33 Step B check-1
- **Description:** The burst-194 fix for E-SBXD-001 WorkspaceEscape (burst-194 fix burst 113) corrected BC-2.13.005 TV-002 and TV-003 from single-field `{ resolved }` to canonical 3-field form `{ requested, resolved, root }` per BC-2.13.005 Invariant-2. The TD-VSDD-060 file-wide sweep was performed IN-FILE (within BC-2.13.005 only). However, the error-taxonomy E-SBXD-001 BC-Anchor cell lists **two** anchor BCs: BC-2.13.005 (primary) AND BC-2.13.004 (secondary). BC-2.13.004 serves as a VP seed for the same `canonicalize_beneath_root` code path (VP-003) and its TV-002 (`canonicalize_beneath_root("/workspace", "/workspace/../etc/passwd")`) also uses the E-SBXD-001 struct. BC-2.13.004 TV-002 at the time of pass-110 review: `Err(E-SBXD-001: WorkspaceEscape { resolved: "/etc/passwd", root: "/workspace" })` — a **2-field** form missing `requested`. This diverges from BC-2.13.005's canonical 3-field form and from BC-2.13.005 Invariant-2 ("All workspace file operations use a single `WorkspaceEscape` error type with `{ requested, resolved, root }`"). The gate #33 Step B check-1 text in v2.36 reads "all sites for the same variant across the same BC must use identical field names" — the phrase "the same BC" (intra-BC scope) was too narrow; it should be "across ALL BCs the taxonomy BC-Anchor cell designates for this code" (cross-anchor scope). Root cause is systemic: the 5th consecutive false census claim at varying levels of the same gate.
- **Evidence:** BC-2.13.004 TV-002 (pre-fix): `canonicalize_beneath_root("/workspace", "/workspace/../etc/passwd") → Err(E-SBXD-001: WorkspaceEscape { resolved: "/etc/passwd", root: "/workspace" })` — 2 fields, `requested` absent. BC-2.13.005 TV-002 (post-fix): `{ requested: "/workspace/link_a", resolved: "/etc/passwd", root: "/workspace" }` — 3 fields. bc-authoring-plan v2.36 Step B check-1 scope: "all sites for the same variant across **the same BC**" — the underlined phrase limits the sweep to a single BC file, missing secondary anchor BCs. Error-taxonomy E-SBXD-001 BC-Anchor cell: `BC-2.13.005 (also BC-2.13.004/VP-003 — shared canonicalize_beneath_root code path)` — both BCs are anchor sites.
- **Fix (completed in burst 114):** BC-2.13.004 v1.1→v1.2: TV-002 expanded to `{ requested: "/workspace/../etc/passwd", resolved: "/etc/passwd", root: "/workspace" }` (3-field canonical form; `requested` added). TD-VSDD-060 file-wide sweep of BC-2.13.004: one E-SBXD-001 struct site (TV-002); zero remaining. bc-authoring-plan v2.36→v2.37: Step B check-1 cross-anchor scope clarification — "intra-corpus" redefined as EVERY struct site in every BC the taxonomy BC-Anchor cell lists for the code (primary AND secondary anchors); text now reads "The PRIMARY anchor's most authoritative construct determines the canonical field name and field count; update ALL diverging sites in ALL anchor BCs." Additionally: full re-census under v2.37 cross-anchor scope found 34 struct-bearing codes total (prior: 30); 4 newly-scoped: E-GRAPH-009 DuplicateNodeName (PASS), E-GRAPH-014 InterruptApprovalTimeout (FAIL — fixed in BC-2.05.006 v1.4), E-CRON-002 InvalidCronExpression (PASS), E-SERVER-006 ScheduleNotFound (PASS). total_standing_gates unchanged at 34.

### MED

#### F-P110-01: Corrigendum #3 (error-taxonomy v1.23) Falsely Claims E-GRAPH-002 Has Two Placeholders — Actual Count Is One [process-gap]

- **Severity:** MED [process-gap]
- **Owner:** PO + orchestrator
- **Category:** process-gap (corrigendum rationale error; taxonomy Message Format mis-stated in changelog prose; BC fix was correct but the stated rationale for WHY the fix was needed is wrong)
- **Location:** `.factory/specs/prd-supplements/error-taxonomy.md` changelog entry v1.23 (corrigendum #3); the **taxonomy row** for E-GRAPH-002 is correct and requires no change
- **Description:** The v1.23 changelog entry (corrigendum #3) contains this rationale: "E-GRAPH-002 NoActiveInterrupt — taxonomy has two placeholders (`<run_id>` and `<run_status>`)". This is FALSE. The E-GRAPH-002 Message Format row in error-taxonomy.md reads: `NoActiveInterrupt: no interrupt is pending for run '<run_id>'` — this message has **ONE** dynamic placeholder: `<run_id>`. The corrigendum described `run_status` as if it were a taxonomy placeholder, but it is not. The BC-2.05.005 struct `{ thread_id, run_status }` is a valid superset: `thread_id` satisfies the ONE required placeholder `<run_id>` via the registered alias; `run_status` is an EXTRA field added for audit/diagnostic utility (valid per Step B check-2: the struct may be a strict superset of the taxonomy placeholder set). The actual fix in BC-2.05.005 v1.3 (adding `thread_id` to all 9 defective sites) was CORRECT — those sites were genuinely missing the `<run_id>`-covering field. The corrigendum described the fix correctly as "9 of 10 sites missing thread_id were correctly identified and fixed." However, the rationale for WHY was wrong: the correct rationale is "struct `{ run_status }` covered zero of the ONE required placeholder `<run_id>`; the v1.23 fix correctly added `thread_id` to cover it." The stated rationale ("two placeholders") overestimates the taxonomy requirement, creating ambiguity about whether `run_status` is mandatory for compliance (it is not — it is a diagnostic extra). Impact: if a future census used the v1.23 prose as a check, it might incorrectly require `run_status` to be present in every site, creating false-negative verdicts for compliant sites that omit the extra field.
- **Evidence:** error-taxonomy.md E-GRAPH-002 row: `| E-GRAPH-002 | POLICY | broken | BC-2.05.005 | \`NoActiveInterrupt: no interrupt is pending for run '<run_id>'\`` — single placeholder `<run_id>`. error-taxonomy v1.23 changelog entry states: "E-GRAPH-002 NoActiveInterrupt — taxonomy has two placeholders (`<run_id>` and `<run_status>`)." These are contradictory. The taxonomy row is the source of truth (D18-P77-B: BC wins on divergence; in this case, taxonomy row is primary). The v1.23 changelog prose is the wrong side.
- **Fix (completed in burst 114):** error-taxonomy v1.23→v1.24 corrigendum #4: (1) corrects the placeholder-count error — E-GRAPH-002 has ONE placeholder `<run_id>`; `run_status` is an extra diagnostic field in the struct (valid superset, not a taxonomy placeholder); v1.23 row is NOT rewritten (immutable audit trail); the correction is a standalone corrigendum #4 entry; (2) records the cross-anchor census scope expansion (BC-2.13.004 F-P110-02 fix) and 34-code enumeration reconciliation. No taxonomy Message Format row changes — the E-GRAPH-002 row was already correct.

## Partial-Coverage Note

The following coverage axes were NOT fully exercised in pass 110 (same carry-forward from pass 109):

- **holdout↔BC/CAP coverage:** full cross-check of holdout-scenario boundary conditions against BC/CAP set not exercised
- **purity-map (58 functions) ↔ module-decomposition (35 modules):** interface parity not spot-checked
- **ss-16/ss-17 remainder:** BC-2.16.002/003 (retry/circuit-breaker detail) and BC-2.17.002 (fuzz target wiring) structural soundness not checked

**Clean axes (exercised this pass):**

- **GTV(9)↔BC-2.07.002:** Graph Traversal Vector traceability checked; byte-identical match between 9 GTV entries and BC-2.07.002 §Canonical Test Vectors confirmed; Red Gate integrity intact
- **ss-16/ss-17 partial:** BC-2.16.001 (InvalidRetryLimit E-RETRY-004 anchor) and BC-2.17.001 (workspace-confinement Kani harness VP citation) both structurally sound; versioning ascending

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 1 |
| MED | 1 |
| LOW | 0 |
| OBS / process-gap | Both findings are process-gap class (F-P110-02 HIGH [process-gap], F-P110-01 MED [process-gap]) |
| **Total findings** | **2** |

**CLEAN (strict):** no (1H + 1M)
**CLEAN (PR-merge):** no (1H + 1M present)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** MEDIUM-HIGH (F-P110-02 is the 5th consecutive census false-claim, now at a different level — cross-anchor TD-VSDD-060 scope rather than intra-BC field coverage; each recurrence has been at a refined/deepened level of the same gate #33 check hierarchy, suggesting the procedure's cross-document scope has been systematically under-specified; F-P110-01 reveals that the corrigendum process itself can introduce wrong rationale even when the fix is correct — the BCs and taxonomy row were correct, only the changelog prose was wrong; adversary enumeration dispute confirmed: 34 codes, not 30)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 110 |
| **New findings** | 1H + 1M (F-P110-02 HIGH [process-gap], F-P110-01 MED [process-gap]) |
| **Duplicate/variant findings** | Same defect CLASS as prior census-completeness findings (F-P108-04, F-P109-01, F-P109-02); novel angle is cross-anchor scope (primary+secondary anchor BCs must BOTH be swept); F-P110-01 is a new sub-class (corrigendum-rationale error vs fix-content error) |
| **Novelty score** | MEDIUM-HIGH (F-P110-02 represents a genuinely new scope dimension — TD-VSDD-060 cross-BC sweep was previously considered "file-wide" but the correct scope is "all anchor BCs for the code as listed in taxonomy"; this dimension was unaddressed by v2.36. F-P110-01 is lower novelty — changelog prose inconsistency — but the impact is that census procedure guidance becomes misleading for future passes) |
| **Median severity** | HIGH (two findings: 1H + 1M) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2 |
| **CLEAN (strict)** | no (1H + 1M) |
| **CLEAN (PR-merge)** | no (1H + 1M present) |
| **Verdict** | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
