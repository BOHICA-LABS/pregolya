---
document_type: adversarial-review-pass
phase: 1d
pass: 27
verdict: NOT CLEAN
findings_count: 6
high_count: 3
med_count: 2
low_count: 1
observations_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "...→2→7→5→6"
timestamp: 2026-07-14T00:00:00Z
new_class: "BC↔error-taxonomy category-authority conflict + self-invalidating positive-coverage census after upstream wildcard narrowing"
---

# Adversarial Review Pass 27 — Phase 1d

**Verdict: NOT CLEAN** — 6 findings (3 HIGH, 2 MED, 1 LOW) + 2 observations. Counter reset: 0/3 consecutive clean.

---

## F-P27-01 [HIGH] — E-GRAPH-002 Three-Way Status Contradiction (422 / POLICY→403 / absent from 422 enumeration)

**Finding class:** BC↔error-taxonomy category-authority conflict + self-invalidating positive-coverage census after upstream wildcard narrowing (new class this pass).

**Scope:** Three files:
- `behavioral-contracts/ss-05/BC-2.05.005.md` EC-001 (~line 81) and TV-003 (~line 109): cited retired wildcard "E-GRAPH-* → 422"
- `prd-supplements/bc-authoring-plan.md` line 427: census row marked PASS but cited the retired wildcard as evidence — false PASS
- `prd-supplements/error-taxonomy.md` line 79: E-GRAPH-002 category POLICY (categorical → 403)

**Finding:**
OBS-1 in pass-26 narrowed the 422 row from `E-GRAPH-*` to an enumerated list of 8 VAL-category codes. E-GRAPH-002 (NoActiveInterrupt) was intentionally excluded from that enumeration because it is POLICY category — making the two cited evidence patterns ("E-GRAPH-* → 422") stale: the wildcard no longer exists in the table. The bc-authoring-plan.md census row therefore cited retired evidence for its PASS verdict. Additionally, BC-2.14.002 PC3's Known-overrides registry had no entry for E-GRAPH-002, leaving it without a documented rationale for the 422 assignment.

**Decision (spec canon):** KEEP 422. Pass-23 deliberately set E-GRAPH-002 → 422 (prior 409 entry retired). The resume endpoint semantics make 422 correct: "you are authorized and the run exists, but no interrupt slot is active" is a semantic state validation failure (422 Unprocessable Entity), not a policy rejection (403). POLICY → 403 is the categorical default; this is a per-endpoint override.

**Fix (completed this pass):**

1. `BC-2.14.002.md` PC3 Known-overrides (version 1.2 → 1.3):
   - Added 9th override entry: `E-GRAPH-002 (NoActiveInterrupt)` → **422** despite `Category::Policy` → 403.
   - Rationale documented: "the resume endpoint receives a well-formed request for a run with no active interrupt slot — this is a semantic state validation failure (422), not a policy rejection (403). 422 conveys 'the run exists and you are authorized, but there is nothing to resume.'"
   - Canon citation: pass-23; prior 409 entry retired.
2. `BC-2.14.002.md` Invariant:
   - Added E-GRAPH-002 POLICY→422 to the divergence example list.
   - Updated source citation to include F-P27-01.
3. `interface-definitions.md` 422 row (version 1.7 → 1.8):
   - Added E-GRAPH-002 (NoActiveInterrupt — POLICY→422 per-endpoint override) to the 422 row enumeration.
   - Updated 422 row description from "VAL-category on body content" to "Semantic validation failure (VAL-category on body content) and per-endpoint POLICY→422 overrides (request valid but current state makes processing impossible)".
4. `BC-2.05.005.md` EC-001 and TV-003 (version 1.0 → 1.1):
   - Replaced retired wildcard "E-GRAPH-* → 422 per interface-definitions.md" with concrete "E-GRAPH-002 POLICY→422 per-endpoint override; BC-2.14.002 PC3 9th override; interface-definitions.md §HTTP Status Codes 422 row".
5. `bc-authoring-plan.md` census row line 427:
   - Updated from "PASS (fixed P23: E-GRAPH-* → 422 per interface-definitions.md; prior 409 entry retired)" to "PASS (F-P27-01: E-GRAPH-002 now enumerated in 422 row explicitly as POLICY→422 per-endpoint override; BC-2.14.002 PC3 9th override; wildcard citation in EC-001 and TV-003 replaced with concrete override citation; prior wildcard 'E-GRAPH-* → 422' retired by P26 OBS-1 narrowing)".

---

## F-P27-02 [HIGH] — E-CHKPT-004 Taxonomy SECURITY vs BC INTERNAL (×6 BC constructions)

**Finding class:** BC↔error-taxonomy category-authority conflict (new subtype of existing class).

**Scope:** Two files:
- `prd-supplements/error-taxonomy.md` line 102: E-CHKPT-004 category SECURITY
- `behavioral-contracts/ss-04/BC-2.04.007.md` lines ~40-41, ~60-61, ~63, ~80-81, ~91: BC constructs `FerrochainError { category: INTERNAL }` throughout; key rotation failure is framed as an internal invariant failure per NE-11

**Finding:**
BC-2.04.007 is the anchor for E-CHKPT-004. It consistently constructs this error with `category: INTERNAL` in the description, PC4, PC5, EC-001, EC-002, and test vectors. error-taxonomy.md assigned SECURITY, which would categorically map to HTTP 403. The BC-is-authoritative policy requires the taxonomy to follow the BC.

**Fix (completed this pass):**

1. `error-taxonomy.md` E-CHKPT-004 (version 1.1 → 1.2):
   - Category: SECURITY → INTERNAL.
   - Added inline correction note: "BC-2.04.007 constructs this error with `category: INTERNAL` throughout (PC4, PC5, EC-001, EC-002); key rotation failure is an internal invariant violation (programming/config error), not a security policy rejection. BC is authoritative."
2. `BC-2.04.007.md` (version 1.1 → 1.2):
   - Added E-CHKPT-004 error code name (EncryptionKeyRotationFailed / E-CHKPT-004) throughout BC body (description, PC4, PC5, EC-001, EC-002, test vector 3).
   - Reverse-anchor fix: BC previously never named the code it was specifying (adversary-noted weakness).

---

## F-P27-03 [HIGH] — "all E-CHKPT-* codes go to the 500 row" Over-Broad

**Finding class:** HTTP-status enumeration over-broad (extends P26 OBS-1 narrowing discipline).

**Scope:** `prd-supplements/interface-definitions.md` line 213: 422 row parenthetical "all E-CHKPT-* codes go to the 500 row".

**Finding:**
E-CHKPT-* includes five active codes:
- E-CHKPT-001 (DURABILITY) → 500 ✓
- E-CHKPT-002 (INTERNAL) → 500 ✓
- E-CHKPT-003 (DURABILITY) → 500 ✓
- E-CHKPT-004 (was SECURITY → 403; now INTERNAL per F-P27-02 → 500) — absent from 500 row, absent from 422 row enumeration
- E-CHKPT-005 (TENANCY → categorical 409) — not in 500 row; categorical 409 but library-level, never direct HTTP
- E-CHKPT-006 (INTERNAL) → 500 ✓

The blanket "all E-CHKPT-*" text concealed that E-CHKPT-004 was absent from the 500 row and E-CHKPT-005 had no documented status treatment at all.

**E-CHKPT-005 decision:** Library-level/embedded. BC-2.04.006 (citing BC) contains no HTTP endpoint references. TENANCY → categorical 409 applies only if directly surfaced via HTTP; in v1 this error surfaces as a run failure embedded in Run.error. Treatment mirrors E-PROV categorical-fallback codes: omission note added.

**Fix (completed this pass):**

1. `interface-definitions.md` 422 row:
   - Replaced "all E-CHKPT-* codes go to the 500 row" with "DURABILITY/INTERNAL E-CHKPT codes (E-CHKPT-001, -002, -003, -004, -006) go to the 500 row; E-CHKPT-005 (TENANCY) is library-level embedded — see omission note below."
2. `interface-definitions.md` 500 row:
   - Added E-CHKPT-004 (EncryptionKeyRotationFailed, INTERNAL).
3. `interface-definitions.md` omission notes block:
   - Added E-CHKPT-005 (TENANCY) library-level omission note explaining categorical TENANCY→409 mapping and v1 embedded treatment.

---

## F-P27-04 [MED] — Uncovered Wire-Visible E-GRAPH Codes

**Finding class:** HTTP-status coverage gap (wire-visible code absent from status table).

**Scope:** `prd-supplements/interface-definitions.md` §HTTP Status Codes.

**Findings:**
- E-GRAPH-013 (SECURITY, InsufficientApproverRole): wire-visible — directly returned from `POST /threads/{thread_id}/runs/{run_id}/resume` when caller lacks required role (BC-2.05.006 PC3, PC4, EC-001). SECURITY → categorical 403. Absent from 403 row.
- E-GRAPH-001 (CONCURRENCY, InvalidUpdateError): graph execution error; surfaces as run failure embedded in Run.error. Absent from status table with no omission note.
- E-GRAPH-014 (POLICY, InterruptApprovalTimeout): run transitions to `failed` on timeout; embedded in Run.error. Absent from status table with no omission note.
- E-GRAPH-016 (POLICY, InterruptWithoutCheckpointer): interrupt() without checkpointer; surfaces as run failure. Absent from status table with no omission note.

**Fix (completed this pass):**

1. `interface-definitions.md` 403 row:
   - Added E-GRAPH-013 (InsufficientApproverRole — SECURITY; direct HTTP 403 on resume endpoint when caller role is insufficient for the interrupt's risk tier; BC-2.05.006 PC3-PC4, EC-001).
2. `interface-definitions.md` new omission note block:
   - Added "Graph execution errors embedded in Run.error" note covering E-GRAPH-001 (CONCURRENCY, InvalidUpdateError), E-GRAPH-014 (POLICY, InterruptApprovalTimeout), and E-GRAPH-016 (POLICY, InterruptWithoutCheckpointer).

---

## F-P27-05 [MED] — BC-2.12.005 PC4 Stale "(or the configured debug route path)"

**Finding class:** Debug-route dual-authority residue (extends F-P26-04 canon — residue miss).

**Scope:** `behavioral-contracts/ss-12/BC-2.12.005.md` PC4 (~line 67).

**Finding:**
F-P26-04 eliminated `debug_route_path` as a configurable option from the BC invariant and the config schema. However, PC4 still contained "(or the configured debug route path)" in the postcondition text — a residue of the pre-P26-04 configurable-path design. The debug route path is fixed at `/_debug` per the invariant; the parenthetical was internally contradictory to that same BC.

**Fix (completed this pass):**

1. `BC-2.12.005.md` PC4 (version 1.1 → 1.2):
   - Removed "(or the configured debug route path)" from the postcondition text.
   - Added inline note: "(F-P27-05: removed '(or the configured debug route path)' — the path is fixed at `/_debug`; `debug_route_path` is NOT a config option per the invariant below.)"

---

## F-P27-06 [LOW] — risk_tier.rs Module Path in BC-2.05.006 Architecture Anchor

**Finding class:** Retired-identifier residue in Architecture Anchor (extends F-P26-03 canon — source file path scope).

**Scope:** `behavioral-contracts/ss-05/BC-2.05.006.md` line 181.

**Finding:**
The Architecture Anchor referenced `ferrochain-graph/src/hitl/risk_tier.rs`. F-P25-06 established the canon: `action_risk` is the authoritative field name (renamed from `risk_tier`). While pass-26 acknowledged `risk_tier.rs` as a Rust source file path (implementer scope), the retired-identifier gate #19 cleanup mandate applies to all spec files including Architecture Anchors. Using the retired name as the module path in the spec perpetuates the `risk_tier` identifier in implementer guidance.

**Decision:** Rename module path to `action_risk.rs` for canon consistency. Grep confirmed no other spec file cited `risk_tier.rs` as a live reference — this was the sole occurrence. Change is low-risk.

**Fix (completed this pass):**

1. `BC-2.05.006.md` Architecture Anchors (version 1.0 → 1.1):
   - `ferrochain-graph/src/hitl/risk_tier.rs` → `ferrochain-graph/src/hitl/action_risk.rs`.
   - Added correction note: "F-P27-06: renamed from `risk_tier.rs` for consistency with the `action_risk` wire-field canon; `risk_tier.rs` is a retired source path."
2. `bc-authoring-plan.md` gate #19 retired-identifier list:
   - Added `risk_tier.rs` (source file path) → `action_risk.rs`.
   - Updated census command comment to clarify filtering of the retired-identifier registry rows.

---

## Observations

### OBS-P27-1 (no action) — Python-Context Citation Acceptable

The adversary noted a Python-context citation in one BC's source analysis section. This BC was produced from a Python-authored behavioral-intent document; the citation is to the semport source analysis, not to the Rust implementation contract. The citation is contextual annotation for the human reader, not a production-code reference. No action required — acceptable annotation.

### OBS-P27-2 [process-gap] — Census Not Re-Run After Upstream Table Edit

**Finding:** When P26 OBS-1 narrowed the 422 row from `E-GRAPH-*` wildcard to an enumerated list, the §17-C census in bc-authoring-plan.md was not re-run. The census row for E-GRAPH-002 continued to cite "E-GRAPH-* → 422 per interface-definitions.md" as its PASS evidence — but that pattern no longer existed in the table. A census row is only as strong as the grep command that produced its PASS verdict; if the table changes, the census must be re-verified.

**Fix applied:** Added standing gate #21 (CENSUS RE-RUN TRIGGER) to bc-authoring-plan.md: any burst that edits the interface-definitions.md §HTTP Status Codes table MUST re-run the full §17-C census in the SAME burst and update every affected census row.

**Deferred process improvement (CI/hook recommendation, machine-enforcement):** The adversary recommends a CI/hook implementation: a grep script that re-runs the §17-C census after any commit touching interface-definitions.md §HTTP Status Codes and fails if any census row cites a wildcard pattern that no longer exists in the table row. This would make census freshness machine-enforceable rather than relying on burst discipline. Logged for v1.1 planning at cycle close.

---

## NEW CLASS: BC↔Error-Taxonomy Category-Authority Conflict + Self-Invalidating Positive-Coverage Census After Upstream Wildcard Narrowing

**BC↔Error-Taxonomy Category-Authority Conflict definition:** When an error code's BC anchor uses a different `category:` than the error-taxonomy.md entry, the BC is authoritative. The taxonomy must be corrected to match. A conflicting taxonomy category produces a wrong categorical HTTP status mapping for anyone implementing the error dispatch layer.

**Self-Invalidating Positive-Coverage Census definition:** When a census row cites a wildcard pattern (e.g., "E-GRAPH-* → 422") as its PASS evidence, and the upstream table is subsequently narrowed from wildcard to an enumeration that excludes the cited code, the census row silently becomes a false PASS — the evidence no longer exists in the table but the verdict remains. This class is now caught by gate #21.

**Drain status:**
- E-GRAPH-002 POLICY→422 per-endpoint override: documented in BC-2.14.002 PC3 (9th entry), enumerated in 422 row, BC-2.05.005 wildcard citations replaced. Fixed.
- E-CHKPT-004 SECURITY→INTERNAL: taxonomy corrected, BC error-code names added, 500 row updated. Fixed.
- "all E-CHKPT-*" over-broad: replaced with specific enumeration, E-CHKPT-005 embedded omission note added. Fixed.
- E-GRAPH-013 wire-visible: added to 403 row. Fixed.
- E-GRAPH-001/014/016 embedded: omission notes added. Fixed.
- BC-2.12.005 PC4 stale parenthetical: removed. Fixed.
- risk_tier.rs module path: renamed to action_risk.rs. Fixed.

**Standing gate added:** bc-authoring-plan.md guideline #21 (Census Re-Run Trigger).

---

## Fix Records (Post-Application)

| Finding | File | Change | Status |
|---------|------|--------|--------|
| F-P27-01 | BC-2.14.002.md | Added 9th PC3 override (E-GRAPH-002 POLICY→422); invariant divergence-example updated; v1.2→1.3 | APPLIED |
| F-P27-01 | interface-definitions.md | E-GRAPH-002 added to 422 row; 422 row description updated; v1.7→1.8 | APPLIED |
| F-P27-01 | BC-2.05.005.md | EC-001 and TV-003 wildcard citations replaced with concrete E-GRAPH-002 POLICY→422 citations; v1.0→1.1 | APPLIED |
| F-P27-01 | bc-authoring-plan.md | Census row 427 updated from wildcard PASS to enumerated-row PASS | APPLIED |
| F-P27-02 | error-taxonomy.md | E-CHKPT-004 category SECURITY→INTERNAL; correction note added; v1.1→1.2 | APPLIED |
| F-P27-02 | BC-2.04.007.md | E-CHKPT-004 EncryptionKeyRotationFailed code name added to description, PC4, PC5, EC-001, EC-002, TV-3; v1.1→1.2 | APPLIED |
| F-P27-03 | interface-definitions.md | 422 row "all E-CHKPT-*" replaced with specific enumeration; E-CHKPT-005 omission note added | APPLIED |
| F-P27-03 | interface-definitions.md | 500 row: E-CHKPT-004 (EncryptionKeyRotationFailed, INTERNAL) added | APPLIED |
| F-P27-04 | interface-definitions.md | 403 row: E-GRAPH-013 (InsufficientApproverRole, SECURITY) added; omission notes for E-GRAPH-001/014/016 added | APPLIED |
| F-P27-05 | BC-2.12.005.md | PC4 "(or the configured debug route path)" removed; correction note added; v1.1→1.2 | APPLIED |
| F-P27-06 | BC-2.05.006.md | Architecture Anchor risk_tier.rs → action_risk.rs; v1.0→1.1 | APPLIED |
| F-P27-06 | bc-authoring-plan.md | Gate #19 retired-identifier list: risk_tier.rs → action_risk.rs added | APPLIED |
| OBS-P27-1 | — | No action (Python-context citation acceptable) | ACCEPTED |
| OBS-P27-2 | bc-authoring-plan.md | Gate #21 (Census Re-Run Trigger) added; CI/hook deferred-improvement recorded | APPLIED |

---

## Post-Fix Verification Census

| Check | Command | Result |
|-------|---------|--------|
| E-GRAPH-* wildcard live citations | `grep -rn "E-GRAPH-\*" .factory/specs/ \| grep -v "~~\|changelog\|narrowed from E-GRAPH-\*"` | PASS — no live wildcard citations; only changelog and census-rule mentions |
| E-GRAPH-002 in 422 row | `grep -n "E-GRAPH-002" interface-definitions.md` | PASS — present in 422 row as POLICY→422 per-endpoint override |
| E-GRAPH-002 in BC-2.14.002 PC3 | `grep -n "E-GRAPH-002" BC-2.14.002.md` | PASS — present in PC3 9th override entry and invariant |
| E-CHKPT-004 category in taxonomy | `grep -n "E-CHKPT-004" error-taxonomy.md` | PASS — INTERNAL (corrected from SECURITY) |
| "all E-CHKPT" drained | `grep -rn "all E-CHKPT" .factory/specs/ \| grep -v "~~\|changelog"` | PASS — only changelog entry; live table text replaced with specific enumeration |
| E-GRAPH-013 in 403 row | `grep -n "E-GRAPH-013" interface-definitions.md` | PASS — present in 403 row |
| "configured debug route path" drained | `grep -rn "configured debug route path" .factory/specs/` | PASS — only in changelog and correction note text; no live requirement |
| risk_tier.rs drained | `grep -rn "risk_tier\.rs" .factory/specs/ \| grep -v "changelog\|retired-id"` | PASS — only in bc-authoring-plan retired-identifier registry row (allowable) |
| E-CHKPT-004 in 500 row | `grep -n "E-CHKPT-004" interface-definitions.md` | PASS — present in 500 row and changelog |
| BC-2.14.002 PC3 override count | Count `→ **NNN**` patterns | PASS — 10 patterns (9 named entries: E-SERVER-002/003/006/008/009(×2)/010/011/016 + E-GRAPH-002; E-SERVER-009 dual sub-entries counted as one entry = 9 total named error-code overrides) |
| 422 vs 500 disjoint (actual codes) | Visual inspection of actual 422 code list vs 500 code list | PASS — E-GRAPH-002/003/004/007/008/009/010/012/015, E-SERVER-009/011 map to 422; E-GRAPH-006/011, E-CHKPT-001/002/003/004/006, E-SERVER-014 map to 500; no code in both lists. Codes mentioned in 422 row description to say they go elsewhere (E-GRAPH-006/011, E-CHKPT-001/002/003/004/006) are not 422 mappings — they are exclusion annotations. |

---

## Sibling Reverse-Anchor Check

No BC additions or retirements this pass. BC count unchanged at P0 48 + P1 30 + P2 8 = 86 total.

---

## HTTP Status Code Census — PASS (Post-Fix, Incremental Updates)

| HTTP Code | E-code + Variant | Category | Notes | Verdict |
|-----------|-----------------|----------|-------|---------|
| 403 | E-SERVER-004 DebugRouteUnauthorized | POLICY | Direct HTTP 403 | PASS (unchanged) |
| 403 | E-SERVER-005 CorsRejected | POLICY | Direct HTTP 403 | PASS (unchanged) |
| 403 | E-GRAPH-013 InsufficientApproverRole | SECURITY | Direct HTTP 403 on resume endpoint; SECURITY→403 categorical (no override needed) | PASS (added F-P27-04) |
| 422 | E-GRAPH-002 NoActiveInterrupt | POLICY | Per-endpoint override POLICY→422; resume endpoint; BC-2.14.002 PC3 9th override | PASS (added F-P27-01) |
| 422 | E-GRAPH-003/004/007/008/009/010/012/015 | VAL | Per-endpoint override VAL→422; unchanged from P26 | PASS (unchanged) |
| 422 | E-SERVER-009/011 | VAL | Per-endpoint override; unchanged from P26 | PASS (unchanged) |
| 500 | E-CHKPT-004 EncryptionKeyRotationFailed | INTERNAL | Categorical INTERNAL→500; category corrected SECURITY→INTERNAL (F-P27-02) | PASS (added F-P27-02/03) |
| Embedded | E-GRAPH-001 InvalidUpdateError | CONCURRENCY | Graph execution error; embedded in Run.error (CONCURRENCY→409 categorical applies if directly surfaced) | PASS (omission note added F-P27-04) |
| Embedded | E-GRAPH-014 InterruptApprovalTimeout | POLICY | Graph execution error; run→failed embedded in Run.error | PASS (omission note added F-P27-04) |
| Embedded | E-GRAPH-016 InterruptWithoutCheckpointer | POLICY | Graph execution error; run→failed embedded in Run.error | PASS (omission note added F-P27-04) |
| Embedded | E-CHKPT-005 SessionAddressCollision | TENANCY | Library-level checkpoint error; TENANCY→409 categorical; embedded in Run.error in v1 | PASS (omission note added F-P27-03) |

*All P26 census rows remain valid (no status changes to previously-PASS rows). Rows added this pass are above.*

---

## New Standing Gates (added to bc-authoring-plan.md)

**Gate #21 — Census Re-Run Trigger:** [process-gap] Any burst that edits the interface-definitions.md §HTTP Status Codes table (row add, remove, narrowing, or widening) MUST re-run the full §17-C census in the SAME burst and update every affected census row. Rationale: P26 OBS-1 narrowing of the 422 wildcard left the E-GRAPH-002 census row citing retired evidence as PASS (self-invalidating census). Source: ADV-P1D-PASS-27 §OBS-P27-2 [process-gap].

**Deferred CI/hook recommendation:** Orchestrator to log for v1.1 planning — machine-enforced census grep that verifies each census row's evidence pattern exists in the current interface-definitions.md §HTTP Status Codes table row.

---

## Rotated Census Results

| Census | Command | Result |
|--------|---------|--------|
| Lifecycle-arrow census (#12) | `grep -rn "in_progress →\|→ interrupted\|⇄" .factory/specs/` | PASS — no new arrows introduced |
| DI-verbatim census (P11) | BC body DI description strings | PASS — no new DI citations added |
| Cross-BC state-machine consistency (P11) | terminal set = {completed, failed, cancelled} | PASS — no state machine changes |
| Shared-type census (#15/P18/P19/P20) | `grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage\|\bCheckpointer\b" .factory/specs/` | PASS — no new violations |
| E-code↔variant-name census (#16/P20) | E-CHKPT-004 EncryptionKeyRotationFailed, E-GRAPH-013 InsufficientApproverRole (new BC text); E-GRAPH-002 NoActiveInterrupt (existing) | PASS — all variant names match taxonomy |
| HTTP endpoint census (#17/P23) | No endpoint additions this pass | PASS — no new endpoints |
| Wire-object field-set coherence (#18/P24/P25) | No field changes to Run/Thread/Assistant/etc. | PASS — no wire-object changes |
| Retired-identifier residue grep (#19/P26) | `grep -rn "to_problem_detail\|risk_tier\|X-Debug-Key" .factory/specs/ \| grep -v "~~\|changelog\|Census command\|retired.*list\|Retired Identifier\|action_risk.rs"` | PASS — changelog/correction-notes only; risk_tier.rs renamed to action_risk.rs (F-P27-06) |
| AUTH/POLICY category re-sweep (#20/P26) | E-CHKPT-004 SECURITY→INTERNAL; E-GRAPH-013 SECURITY→403 (no override needed); full POLICY census | PASS — E-GRAPH-002 POLICY→422 override documented; E-GRAPH-014/016 POLICY→403 categorical (embedded, omission notes added); no orphaned AUTH/POLICY codes |
| Census re-run after table edit (#21 — NEW gate) | 422 row changed (E-GRAPH-002 added); §17-C census re-run this burst | PASS — census row 427 updated in this burst; gate #21 now enforces this going forward |
