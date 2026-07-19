---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T14:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 109
previous_review: pass-108.md
---

# Adversarial Review: ferrochain (Pass 109)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 108 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P108-01 | MED (PO) | RESOLVED | BC-2.08.014 v1.2 EC-004 and TV-005 both carry `{ providers_attempted: 3, last_error_code: "E-PROV-008", last_provider: "provider-b" }` — three independent fields, one per taxonomy placeholder `<N>`, `<last_error_code>`, `<last_provider>`; no combined field. PC5 uses message-template form (correct, not subject to struct check). All other E-PROV-010 sites: bare `Err(E-PROV-010 ProviderChainExhausted)` — no struct, not subject. Changelog ascending v1.1→v1.2. PASS. |
| F-P108-02 | MED (PO) | RESOLVED | BC-2.04.007 v1.5 PC4 now reads `{ message: "EncryptionKeyRotationFailed: <reason>" }` — field name `message` matches PC5, EC-002, and TV key-v2 row (all four sites uniform). v1.4 source→message correction documented in changelog. Changelog ascending v1.4→v1.5. PASS. |
| F-P108-03 | LOW (PO) | RESOLVED | BC-2.08.013 v1.2 EC-002 expanded to `{ dialect: "HermesChatMlXml", element: "<tool_call>", offset: 2, parse_error: "key must be a string" }` — four independent fields matching all four taxonomy placeholders; `offset` ↔ `<n>` semantic equivalence documented in changelog (byte offset in dialect parse error; not in alias list; noted explicitly). Catch-all disqualification confirmed: `<n>` was mid-message (between `<element>` and `<parse_error>`), making the catch-all rule inapplicable. Changelog ascending v1.1→v1.2. PASS. |
| F-P108-04 | HIGH [process-gap] (PO+orchestrator) | RESOLVED (a,b,c,d PASS; (e) census claim FAILED — see F-P109-01) | (a) Gate #33 STRUCT-PLACEHOLDER PARITY CENSUS procedure present in bc-authoring-plan v2.35: Steps A, B, C all present and executable. (b) Step B check requirements: (1) intra-BC field-name consistency across sites, (2) struct field SUPERSET of all distinct taxonomy placeholders with no multi-placeholder combined field, (3) no hardcoded values. (c) Step C per-code TABLE format binding — prose-only claims INVALID. (d) Motivating instances (E-PROV-010, E-CHKPT-004, E-PROV-009) and catch-all rule documented inline. HOWEVER: check (e) — the "0 remaining" claim of v1.22's 28 PASS set is FALSE. Independent census re-run under strengthened v2.36 rules finds three additional struct-field parity defects among the codes assessed as PASS under v1.22. See F-P109-01 and F-P109-02. This is the **third consecutive burst** where a sweep-completeness claim has proven false (v1.20 "21 PASS", v1.21 "17 PASS", v1.22 "28 PASS"). |

**Sibling-checks (burst-193 owed list):**

| Check | Result |
|-------|--------|
| (a) gate #33 STRUCT-PLACEHOLDER PARITY CENSUS Steps A/B/C present in bc-authoring-plan v2.35 | PASS — all three steps present; Step-C mandatory per-code TABLE format binding stated |
| (b) BC-2.08.014 v1.2 EC-004/TV-005: struct {providers_attempted, last_error_code, last_provider} 1:1 with taxonomy 3 placeholders | PASS — three independent fields matching three placeholders; ascending changelog |
| (c) BC-2.04.007 v1.5 PC4: {message: "EncryptionKeyRotationFailed: <reason>"} consistent with PC5/EC-002/TV | PASS — uniform field name across all four sites; changelog ascending v1.4→v1.5 |
| (d) BC-2.08.013 v1.2 EC-002: {dialect, element, offset, parse_error} — four independent fields | PASS — four fields; offset↔<n> noted in changelog; catch-all disqualified |
| (e) v1.22 census completeness "28 PASS" and "0 remaining" claim | FAILED — adversary independent census re-run under gate #33 v2.35 procedure (before v2.36 strengthening) finds three additional struct-field parity defects: E-GRAPH-002 NoActiveInterrupt (9 of 10 BC-2.05.005 sites missing thread_id; PC1 was already correct but EC-001/002/003/004, TV-001/002/003/004/005 all carried only `{ run_status }` without `thread_id`); E-MCP-002 McpTransportError (BC-2.09.001 TV-004 used `{ server: "math", ... }` as SOLE struct site — `...` abbreviation fails PASS-ABBREV rule because no non-TV full-struct site exists in the same BC for this code); E-SBXD-001 WorkspaceEscape (BC-2.13.005 TV-002 and TV-003 each used `{ resolved: "/etc/passwd" }` with only the `resolved` field — missing `requested` and `root`; taxonomy has `<resolved>` and `<root>` as distinct placeholders; PC4 and TV-001 use the canonical 3-field form `{ requested, resolved, root }` — TV-002/003 failed both intra-BC consistency (vs PC4/TV-001) and placeholder coverage). See F-P109-01 and F-P109-02. |

## Part B — New Findings

### HIGH

#### F-P109-01: E-GRAPH-002 NoActiveInterrupt Falsely Marked PASS by v1.22 Census — 9 of 10 BC-2.05.005 Sites Missing thread_id [process-gap]

- **Severity:** HIGH [process-gap]
- **Owner:** PO + orchestrator
- **Category:** process-gap (census-completeness; gate #33 STRUCT-PLACEHOLDER PARITY CENSUS third consecutive false claim; plus two latent defects of the same class — E-MCP-002, E-SBXD-001 — found and fixed in the same burst)
- **Location:** `.factory/specs/behavioral-contracts/ss-05/BC-2.05.005.md` §PC1 (9 sites: EC-001/002/003/004, TV-001/002/003/004/005); `.factory/specs/prd-supplements/error-taxonomy.md` §E-GRAPH-002; `.factory/specs/prd-supplements/bc-authoring-plan.md` gate #33
- **Description:** The taxonomy Message Format for E-GRAPH-002 NoActiveInterrupt specifies two dynamic placeholders: `<run_id>` (the run/thread identifier) and `<run_status>` (the current run state). BC-2.05.005 PC1 correctly carries `{ thread_id, run_status }` — with `thread_id` as the registered alias for `<run_id>` in the interrupt context (a run is identified by its thread_id). However, all 9 other sites in the same BC — EC-001, EC-002, EC-003, EC-004, TV-001, TV-002, TV-003, TV-004, TV-005 — carried only `{ run_status: "..." }` (a single-field struct) with no `thread_id` field. Two defects at each site: (1) intra-BC field-name inconsistency (PC1 carries `{ thread_id, run_status }`, EC/TV carry only `{ run_status }`), and (2) placeholder coverage failure (taxonomy placeholder `<run_id>` has no corresponding field in 9 of 10 sites). The v1.22 census assessed E-GRAPH-002 as "PASS-NOTE" (step↔`<n>` semantic alias noted for other codes) — but the census actually assessed E-GRAPH-002's field coverage as PASS based on PC1 alone without checking all 9 EC/TV sites for intra-BC field-name consistency. This is the same class of error as E-CHKPT-004 in pass-108 (PC4 using `source` while PC5/EC-002/TV used `message` — a single-site inconsistency) but more widespread: 9 of 10 sites are missing the field. Additionally, two further latent defects of the same class were found and fixed in the same burst (E-MCP-002 PASS-ABBREV violation, E-SBXD-001 placeholder coverage failure) — published in the full per-site census table in burst-194 burst-log.
- **Evidence:** v1.22 Step-C table row: `E-GRAPH-002 | BarrierWaitTimeout | BC-2.02.006 EC-001 | {barrier_id, step, timeout_ms} | ... | step↔<n> | PASS-NOTE` — BUT this is the WRONG BC site for E-GRAPH-002. E-GRAPH-002 is NoActiveInterrupt anchored to BC-2.05.005, not BarrierWaitTimeout at BC-2.02.006. The v1.22 census confused the code with E-GRAPH-002 under BC-2.02.006 (BarrierWaitTimeout), not BC-2.05.005 (NoActiveInterrupt). The taxonomy row: `| E-GRAPH-002 | POLICY | broken | BC-2.05.005 | NoActiveInterrupt: no interrupt is pending for run '<run_id>' |`. BC-2.05.005 EC-001 pre-fix: `Err(E-GRAPH-002 NoActiveInterrupt { run_status: "completed" })` — one field, `<run_id>` unrepresented. PC1 (pre-fix, already correct): `Err(E-GRAPH-002 NoActiveInterrupt { thread_id, run_status })` — two fields. The census passed E-GRAPH-002 because it FOUND a struct-bearing site (PC1) but did not verify all sites for field-name consistency. This is precisely the gap that bc-authoring-plan v2.35 Step B check 1 was supposed to catch — but v2.36 additional cross-site verification revealed the census missed it on the very pass that codified the procedure.
- **Fix (completed in burst 113):** BC-2.05.005 v1.2→v1.3: all 9 defective sites (EC-001, EC-002, EC-003, EC-004, TV-001, TV-002, TV-003, TV-004, TV-005) expanded to full 2-field struct `{ thread_id, run_status: "<value>" }`. TD-VSDD-060 file-wide sweep: all 10 E-GRAPH-002 occurrences assessed — PC1 was already correct; 9 expanded; zero remaining. Alias `thread_id ↔ <run_id>` registered in bc-authoring-plan v2.36 gate #33 alias registry (interrupt context: a run is identified by its thread_id). Additionally, two latent defects found and fixed in same census pass: E-MCP-002 BC-2.09.001 v1.3 TV-004 `...` abbreviation expanded to full struct; E-SBXD-001 BC-2.13.005 v1.1 TV-002/003 expanded from single-field `{ resolved }` to 3-field `{ requested, resolved, root }`. Error-taxonomy v1.22→v1.23 corrigendum #3.

### MED

#### F-P109-02: Gate #33 Check-2 Registry Under-Specified — Four Semantic Aliases and E-MEMORY-007 Context-Sourced Exception Class Unregistered [process-gap]

- **Severity:** MED [process-gap]
- **Owner:** PO + orchestrator
- **Category:** process-gap (gate #33 registry completeness; bc-authoring-plan v2.35 → v2.36 extension required)
- **Location:** `.factory/specs/prd-supplements/bc-authoring-plan.md` gate #33 check-2 alias registry and exception class definitions
- **Description:** Gate #33 bc-authoring-plan v2.35 check-2 requires that struct fields map to taxonomy placeholders via registered semantic aliases. However, v2.35's alias registry and exception handling are under-specified in two ways: (1) **Unregistered aliases:** `offset ↔ <n>` (used in E-PROV-009 fix, burst-193), `providers_attempted ↔ <N>` (used in E-PROV-010 fix, burst-193), and `backend_error ↔ <reason>` (used for E-MEMORY-005 ErasurePartialFailure) were not explicitly registered in the v2.35 alias table. Additionally, `message ↔ <reason>` for E-CHKPT-004 is a CODE-SPECIFIC alias (the full constructed message string is the reason) and must be registered with a "do-not-generalize" note to prevent misapplication to codes where `message` maps to `<message>` (a different semantic). (2) **Unregistered exception class:** E-MEMORY-007 MemoryWriteGuardDenied has a context-sourced placeholder pattern: taxonomy placeholders `<ns>` and `<key>` are sourced from `MemoryWriteRequest.namespace` and `MemoryWriteRequest.key` at the raise site — the BC names the context object explicitly and the values are deterministically available at raise time. Under a strict "every placeholder must have a corresponding struct field" rule, E-MEMORY-007 would FAIL check 2 because the struct `{ ns, key, reason }` does not duplicate the context values. The context-sourced exception class must be formally defined and E-MEMORY-007 must be registered in it to avoid false-fail verdicts on future passes. Additionally, the PASS-ABBREV rule for TV-row `...` abbreviations was insufficiently explicit: v2.35 noted the rule but did not state that a TV row with `...` FAILS check 2 when it is the SOLE struct-bearing site for that code in the BC (the abbreviated TV row is the sole source of field names, making the abbreviation a genuine coverage gap).
- **Evidence:** bc-authoring-plan v2.35 alias registry listed only: `step ↔ <n>`, `node ↔ <node_id>`, `thread_id ↔ <run_id>`. Not listed: `offset ↔ <n>` (E-PROV-009 burst-193 fix used this alias — it was noted in BC-2.08.013 changelog but not registered in the gate #33 alias table), `providers_attempted ↔ <N>` (E-PROV-010 burst-193 fix used this alias — not registered), `backend_error ↔ <reason>` (E-MEMORY-005 {user_id, backend_error} maps `backend_error` to `<reason>` — not registered), `message ↔ <reason>` CODE-SPECIFIC for E-CHKPT-004 (the field name `message` carries the full constructed reason string, a CODE-SPECIFIC form that must not be generalized). Gate #33 v2.35 PASS-ABBREV rule: stated `...` is only valid abbreviation when a non-TV PC/EC full-struct site exists in the same BC; but the COROLLARY — that `...` is a FAIL when TV-row is the SOLE struct site — was not stated explicitly, making the rule ambiguous in the B-109 context. BC-2.09.001 TV-004's `{ server: "math", ... }` was the SOLE E-MCP-002 struct site in the file; the v2.35 rule did not clearly prohibit this form, creating an opening for the "PASS-ABBREV" misapplication.
- **Fix (completed in burst 113):** bc-authoring-plan v2.35→v2.36: (1) alias registry extended with four entries: `offset ↔ <n>` (E-PROV-009 — byte offset in dialect parse error), `providers_attempted ↔ <N>` (E-PROV-010 — abbreviation; tried-count), `backend_error ↔ <reason>` (E-MEMORY-005 — storage backend failure detail), `message ↔ <reason>` CODE-SPECIFIC for E-CHKPT-004 (full constructed message string; do-not-generalize note); (2) context-sourced placeholder exception class defined with 3-part acceptance criterion: (a) BC body must name the context object providing the placeholder values; (b) placeholder values must be deterministically available at the raise site via the named context object; (c) the code must be explicitly registered in the exception list. E-MEMORY-007 registered as the first context-sourced exception (MemoryWriteRequest.namespace → `<ns>`, MemoryWriteRequest.key → `<key>`); (3) PASS-ABBREV rule made explicit with both the positive rule and negative corollary: TV-row `...` abbreviation PASSES check 2 ONLY IF a non-TV (PC or EC) full-struct site in the same BC explicitly names all fields; when the abbreviated TV row is the SOLE struct-bearing site for a code in the BC, the `...` form is a FAIL — all fields must be listed explicitly. Motivating instance: BC-2.09.001 TV-004 `{ server: "math", ... }` was the sole E-MCP-002 struct site — expanded to `{ server: "math", transport_error: "connection refused" }` in BC-2.09.001 v1.3. `total_standing_gates` unchanged at 34 (registry extension + rule clarification within gate #33; no new gate). E-MEMORY-007 context-sourced exception registered simultaneously with the exception class definition.

## Partial-Coverage Note

Due to context budget consumed by the E-GRAPH-002 census re-execution (all 10 BC-2.05.005 sites evaluated manually, v2.36 alias registry verified, 30-code census table re-run), the following coverage axes were NOT fully exercised in pass 109 and are carried forward as mandatory pass-110 scope:

- **holdout↔BC/CAP coverage:** full cross-check of holdout-scenario boundary conditions against BC/CAP set not exercised this pass
- **purity-map (58 functions) ↔ module-decomposition (35 modules):** interface parity not spot-checked this pass
- **GTV (9 vectors) ↔ BC-2.07.002:** graph traversal vector traceability not exercised this pass
- **ss-16/ss-17 axis soundness:** SS-16 (retry/circuit-breaker) and SS-17 (verification/hardening) BC structural soundness not checked this pass

These axes are not newly identified; they are carry-forward from the partial-coverage note in pass-108.

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 1 |
| MED | 1 |
| LOW | 0 |
| **Total findings** | **2** |
| OBS / process-gap | Both findings are process-gap class (F-P109-01 HIGH [process-gap], F-P109-02 MED [process-gap]) |

**CLEAN (strict):** no (1H + 1M)
**CLEAN (PR-merge):** no (1H + 1M present)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** MEDIUM-HIGH (F-P109-01 is the third consecutive false census completeness claim — pattern now confirmed systemic; meta-insight: census was checking struct-bearing site EXISTENCE at the code level rather than INTRA-BC FIELD-NAME CONSISTENCY at EACH site; F-P109-02 confirms gate #33 registry was incompletely specified as of v2.35; both findings confirm the census procedure needs hardening beyond what Steps A–C as originally written provide)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 109 |
| **New findings** | 1H + 1M (F-P109-01 HIGH [process-gap], F-P109-02 MED [process-gap]) |
| **Duplicate/variant findings** | Same defect CLASS as F-P108-01/02/03/04; novel angle is confirmation that the census procedure itself (even with Steps A–C) can produce false completeness claims when the examiner checks struct existence at the code level without checking field-name consistency at EVERY INDIVIDUAL SITE in the BC |
| **Novelty score** | MEDIUM-HIGH (third consecutive false census claim — pattern now confirmed systemic, not random; plus the v2.35 census incorrectly identified E-GRAPH-002 under the WRONG BC site, suggesting the procedure's Step A needs explicit BC-site-level verification guidance; F-P109-02 alias registry gap and context-sourced exception class are straightforward but consequential for future pass reliability) |
| **Median severity** | HIGH (two findings: 1H + 1M) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2 |
| **CLEAN (strict)** | no (1H + 1M) |
| **CLEAN (PR-merge)** | no (1H + 1M present) |
| **Verdict** | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
