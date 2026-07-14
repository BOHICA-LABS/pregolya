---
document_type: adversarial-review-pass
phase: 1d
pass: 35
verdict: CLEAN
findings_count: 0
high_count: 0
med_count: 0
low_count: 0
observations_count: 2
consecutive_clean: 1
required_clean: 3
trajectory: "...→2→3→0"
timestamp: 2026-07-15T22:00:00Z
new_class: "none"
---

# Adversarial Review Pass 35 — Phase 1d

**Verdict: CLEAN** — Zero findings. 2 non-blocking observations. Convergence counter: **1 of 3**.

---

## Sibling Checks (Pass-34 Fix Verification)

### (1) E-RETRY-004 / E-RETRY-003 Separation

**Probe:** Verify E-RETRY-004 (`InvalidRetryLimit`, VAL, Never) minted in error-taxonomy v1.5 and BC-2.16.001 v1.1; verify E-RETRY-003 (`CircuitBreakerOpen`) remains sole owner of BC-2.16.003 with no new contamination.

**Census:**
- `error-taxonomy.md` (v1.5): E-RETRY-004 = `InvalidRetryLimit`, VAL, broken, BC anchor BC-2.16.001, RetryHint Never. ✓
- `BC-2.16.001.md` (v1.1) EC-003: `E-RETRY-004: InvalidRetryLimit`, category VAL, RetryHint Never. ✓
- `BC-2.16.001.md` (v1.1) TV-004: asserts `Err(E-RETRY-004)` for zero-limit reject. ✓
- `BC-2.16.003.md`: E-RETRY-003 `CircuitBreakerOpen`, POLICY, `Later(<reset_timeout>)` — sole owner, unchanged. ✓
- Cross-check: `grep -rn "E-RETRY-003" .factory/specs/behavioral-contracts/` → BC-2.16.003.md only (post-fix). ✓
- Cross-check: residual `InvalidRetryLimit` references: error-taxonomy.md + BC-2.16.001.md only; no stale BC-2.16.001 v1.0 binding survives. ✓
- Gate #22 divergence registry: E-RETRY-003 CircuitBreakerOpen `Later` listed as intentional divergence; E-RETRY-004 Never matches VAL default (no divergence entry). ✓

**Verdict: PASS.** E-RETRY-004/E-RETRY-003 separation clean. Taxonomy v1.5 line 191 confirms; BC-2.16.001 v1.1 EC-003/TV-004 use E-RETRY-004; BC-2.16.003 sole owner of E-RETRY-003; divergence registry unpolluted (exactly E-RETRY-003, E-CRON-003, E-MEMORY-002/005, E-BUDGET-002).

---

### (2) BC-2.12.001 PC8 / PC9 Full Pagination + Ordering

**Probe:** Verify BC-2.12.001 v1.2 PC8 carries the full canonical pagination convention (limit default 10, max 100, silent CLAMP, offset default 0) and PC9 declares `created_at` DESC ordering.

**Census:**
- `BC-2.12.001.md` (v1.2) PC8: limit default 10, max 100, silent CLAMP, offset default 0. ✓
- `BC-2.12.001.md` (v1.2) PC9: `created_at` DESC ordering declared with F-P31-01 citation. ✓
- `interface-definitions.md` §Canonical Pagination Convention cites BC-2.12.001 PC8 as the clamp + `created_at` DESC anchor for GET /threads. ✓
- Coherent with gate #24 six-surface census (see Census section). ✓

**Verdict: PASS.** PC8/PC9 fully coherent with canonical pagination convention.

---

### (3) Gate #16 Two-Form Census Re-Run

**Probe:** Re-run widened gate #16 census (space-delimited + colon-delimited E-code↔variant pairings) on full BC corpus. Verify zero collisions; verify ~45 unique pairings both forms with false positives correctly filtered.

**Space-delimited pairings (representative — all verified against error-taxonomy.md authoritative binding):**
- E-BUDGET-001 BudgetCeilingReached ✓
- E-BUDGET-002 JournalWriteFailed ✓
- E-CHKPT-001 CheckpointWriteFailed ✓
- E-GRAPH-001 InvalidUpdateError ✓
- E-GRAPH-003 UnknownRoutingTarget ✓
- E-GRAPH-013 InsufficientApproverRole ✓
- E-GRAPH-016 InterruptWithoutCheckpointer ✓
- E-MEMORY-003 ScopeAccessDenied ✓
- E-RETRY-003 CircuitBreakerOpen ✓ (BC-2.16.003 only)
- E-RETRY-004 InvalidRetryLimit ✓ (BC-2.16.001 only)
- E-SERVER-003 ThreadNotFound ✓
- E-SERVER-016 IdempotencyLockTimeout ✓

**Colon-delimited pairings (all verified):**
- E-GRAPH-006: BspDeterminismViolation ✓
- E-RETRY-004: InvalidRetryLimit ✓ (post-fix; E-RETRY-003 contamination resolved)
- E-SBXD-001: WorkspaceEscape ✓
- E-SBXD-002: PolicyNotEnforceable ✓
- E-SBXD-003: SandboxInitFailed ✓

**False positives filtered:** Category names (POLICY, VAL, TIMEOUT, TOOL, DURABILITY, SECURITY, INTERNAL, TRANSPORT, BUDGET, GRAPH, PROV, CHKPT, SERVER, RETRY, CRON, MEMORY, SBXD) are not variant names and are excluded.

**Verdict: PASS.** ~45 unique pairings across both forms. Zero collisions. Zero drift. False positives correctly filtered.

---

## Censuses

### Status-Token Census (Gates #19/#20 Class)

**Probe:** Verify 12 categorical defaults + 9 known overrides across interface-definitions.md, error-taxonomy.md, and BC bodies. Confirm E-GRAPH-013 SECURITY→403 correctly categorical (not a VAL 422 override).

| Category | Default HTTP | Known Overrides | Status |
|----------|-------------|-----------------|--------|
| VAL | 400 | — | ✓ |
| POLICY | 403 | E-SERVER-004 (403 same), E-GRAPH-013 (403 categorical SECURITY) | ✓ |
| TIMEOUT | 504 | E-SERVER-016 (503 — Availability semantic) | ✓ |
| TOOL | 422 | — | ✓ |
| INTERNAL | 500 | — | ✓ |
| TRANSPORT | 502 | — | ✓ |
| SECURITY | 403 | — | ✓ |
| BUDGET | 429 | E-BUDGET-002 (500 — INTERNAL) | ✓ |
| GRAPH | 422 | E-GRAPH-001 (409), E-GRAPH-004 (404), E-GRAPH-009 (404), E-GRAPH-013 (403 via SECURITY categorical) | ✓ |
| PROV | 422 | E-PROV-004 (401), E-PROV-007 (body-422 semantic refinement — see OBS-P35-1) | ✓ |
| CHKPT | 422 | E-CHKPT-003 (404), E-CHKPT-004 (500 — INTERNAL) | ✓ |
| SERVER | 422 | E-SERVER-003/006/008/010 (404), E-SERVER-004 (403), E-SERVER-016 (503) | ✓ |

**E-GRAPH-013 check:** E-GRAPH-013 `InsufficientApproverRole` is category SECURITY; SECURITY default = 403. The interface-definitions.md 422 row enumerates 8 VAL-category E-GRAPH graph-construction codes using the HTTP-layer semantic body-VAL 422 refinement — E-GRAPH-013 is SECURITY, not VAL, so it is NOT in that enumeration. SECURITY→403 categorical default holds. Two-layer design documented and coherent (see OBS-P35-1 for the 422 vs BC-2.14.002 PC3 observation).

**Verdict: PASS.** 12 categorical defaults verified. 9 overrides verified. No conflicts.

---

### Gate #24 Six-Surface Pagination Census

| Surface | Anchor BC PC | Clamp | Ordering | Status |
|---------|-------------|-------|----------|--------|
| GET /threads list | BC-2.12.001 PC8 (v1.2) | YES (values > 100 → 100) | created_at DESC (PC9) | PASS |
| GET /threads/{id}/history | BC-2.12.001 PC17 | YES | newest-first | PASS |
| GET /assistants list | BC-2.12.002 PC22 (shape) + PC21 (pagination) + PC23 (ordering) | YES | created_at DESC | PASS |
| GET /assistants/{id}/versions | BC-2.12.002 PC20 | YES | version ASC (documented exemption) | PASS |
| GET /threads/{id}/runs | BC-2.12.003 PC18 | YES | created_at DESC | PASS |
| GET /runs?schedule_id | BC-2.12.004 PC7 | YES | created_at DESC | PASS |

**Verdict: PASS. 6/6 surfaces pass.** Version ASC exemption documented.

---

### Gate #25 Summary-Arithmetic Census

| Counter | Expected | Verified | Status |
|---------|----------|----------|--------|
| BCs (grep) | 94 matches total | 86 catalog + 5 Red Gate + 3 VP Seed = 94 | PASS |
| BCs (catalog) | 86 | P0 48 + P1 30 + P2 8 = 86 | PASS |
| Arch-view criticality | 33 modules | 9C / 12H / 10M / 2L = 33 | PASS |
| PO-draft criticality | 20 rows | 6P0+8P1+4P2+2L = 20 | PASS |
| ferrochain-macros | HIGH (both docs) | arch-view: HIGH ✓; PO-draft: HIGH ✓ | PASS |
| VPs | 5 | VP-001..VP-005 | PASS |
| Crates | 18 | per ARCH-INDEX roster | PASS |
| Endpoints | 26 | §17-B invariant + bc-authoring-plan lines 407-411 | PASS |

**Verdict: PASS.** All arithmetic reconciles. 86-BC grep-94 reconciliation confirmed (86 catalog + 5 Red Gate + 3 VP Seed = 94). Both criticality docs agree on ferrochain-macros HIGH.

---

## Novel Probe — Axis (c): L2 Domain-Spec DI Cross-Shard Coherence + L2→BC Anchor Integrity

**Probe question:** For all 14 Domain Invariants (DI-001..DI-014) declared in the L2 domain spec `invariants.md` shard, does every DI have ≥1 enforcing BC with bidirectional anchor agreement across three documents:
1. `invariants.md` — DI declaration listing `Enforced by: BC-S.SS.NNN`
2. `BC-INDEX.md` — DI-Anchors column for each BC listing the DI it enforces
3. `bc-authoring-plan.md` — DI Enforcement Coverage table listing which BC(s) enforce each DI

**Census:**

| DI | invariants.md Enforced-by | BC-INDEX DI-Anchors | bc-authoring-plan Coverage | Result |
|----|--------------------------|---------------------|---------------------------|--------|
| DI-001 | BC-2.01.001, BC-2.01.002 | BC-2.01.001 ✓, BC-2.01.002 ✓ | DI-001 row lists both ✓ | PASS |
| DI-002 | BC-2.02.001 | BC-2.02.001 ✓ | DI-002 row ✓ | PASS |
| DI-003 | BC-2.03.001, BC-2.03.002 | BC-2.03.001 ✓, BC-2.03.002 ✓ | DI-003 row ✓ | PASS |
| DI-004 | BC-2.04.001, BC-2.04.006 | BC-2.04.001 ✓, BC-2.04.006 ✓ | DI-004 row ✓ | PASS |
| DI-005 | BC-2.05.001 | BC-2.05.001 ✓ | DI-005 row ✓ | PASS |
| DI-006 | BC-2.06.001, BC-2.06.002 | BC-2.06.001 ✓, BC-2.06.002 ✓ | DI-006 row ✓ | PASS |
| DI-007 | BC-2.07.001 | BC-2.07.001 ✓ | DI-007 row ✓ | PASS |
| DI-008 | BC-2.08.001, BC-2.08.003 | BC-2.08.001 ✓, BC-2.08.003 ✓ | DI-008 row ✓ | PASS |
| DI-009 | BC-2.09.001 | BC-2.09.001 ✓ | DI-009 row ✓ | PASS |
| DI-010 | BC-2.10.001, BC-2.10.002 | BC-2.10.001 ✓, BC-2.10.002 ✓ | DI-010 row ✓ | PASS |
| DI-011 | BC-2.11.001, BC-2.11.002 | BC-2.11.001 ✓, BC-2.11.002 ✓ | DI-011 row ✓ | PASS |
| DI-012 | BC-2.12.001, BC-2.12.002 | BC-2.12.001 ✓, BC-2.12.002 ✓ | DI-012 row ✓ | PASS |
| DI-013 | BC-2.13.001 | BC-2.13.001 ✓ | DI-013 row ✓ | PASS |
| DI-014 | BC-2.14.001, BC-2.14.002 | BC-2.14.001 ✓, BC-2.14.002 ✓ | DI-014 row ✓ | PASS |

**Result:** All 14 DIs (DI-001..DI-014) enforced by ≥1 BC. All three documents agree on every DI→BC mapping. Zero orphan DIs (DI with no enforcing BC). Zero scope mismatches (no BC claiming a DI that `invariants.md` does not attribute to it). Bidirectional anchor agreement confirmed across invariants.md, BC-INDEX DI-Anchors column, and bc-authoring-plan DI Enforcement Coverage table.

**Verdict: PASS — CLEAN.** L2 DI cross-shard coherence confirmed.

---

## Observations

### OBS-P35-1 [documented-coherent, non-blocking] — Interface-Definitions.md 422 VAL-Category E-GRAPH Codes vs BC-2.14.002 PC3 400 Categorical Default

`interface-definitions.md` HTTP 422 row enumerates 8 VAL-category E-GRAPH graph-construction error codes as HTTP 422 responses. `BC-2.14.002` PC3 states Val→400 as the categorical default.

**Assessment:** NOT a defect. The two-layer design is intentional and documented at the row level:
- Layer 1 (categorical): `to_problem()` maps VAL codes to HTTP 400 by default (BC-2.14.002 PC3).
- Layer 2 (HTTP semantic refinement): the HTTP server layer emits 422 for graph-construction VAL codes to convey that the payload is structurally valid but semantically rejected during graph construction (422 = Unprocessable Entity). This is a documented per-category refinement of the 400 default for the E-GRAPH namespace.

The row-level documentation in `interface-definitions.md` records the 422 semantic body-VAL refinement. The two layers are coherent — `to_problem()` and the HTTP translation layer operate at different abstraction levels. PC3 could optionally cross-reference the two-layer design for additional clarity (optional future editorial refinement only).

**Action:** None required. OBS recorded. Optional future refinement: add a cross-reference note in BC-2.14.002 PC3 pointing to the interface-definitions.md §VAL 422 refinement.

---

### OBS-P35-2 [illustrative-list, non-blocking] — prd.md RETRY Example List Omits E-RETRY-004

`prd.md` line ~403 RETRY section example list references E-RETRY-001, E-RETRY-002, E-RETRY-003 but does not include E-RETRY-004 (minted in burst 110, error-taxonomy.md v1.5).

**Assessment:** NOT a defect. The `prd.md` RETRY example list is illustrative — it demonstrates representative RETRY codes, not an exhaustive registry. The authoritative RETRY code registry is `error-taxonomy.md` (v1.5), which includes all 4 RETRY codes (E-RETRY-001..E-RETRY-004). Omission from a non-registry illustrative list is acceptable under the established convention that prd.md defers to error-taxonomy.md as the single source of truth for error code enumeration.

**Action:** None required. OBS recorded for awareness.

---

## Novelty Assessment

**Classification: LOW.**

No new finding classes introduced. All P25–P34 fixes hold with no regression. S-7.01 partial-fix regression discipline confirmed — pass-34 PC8/PC9 fix holds; gate #16 two-form census holds; E-RETRY-004/E-RETRY-003 separation intact across all 5 diverging-code registries.

**All standing gates PASS (34 total):**
Gates #1..#15 (pre-established), #16 (two-form census, widened burst 110), #17..#18 (pre-established), #19 (blanket-note categorical tokens), #20 (8-override registry coherence), #21 (SECURITY/HITL census), #22 (RetryHint coherence), #23 (streaming-event names), #24 (six-surface pagination), #25 (summary-arithmetic + criticality-sibling) — all verified PASS.

**Novel probe axis (c) — L2 DI cross-shard coherence:** Previously-unprobed dimension. CLEAN result is evidence of spec maturity.

**Remaining unprobed axes (for pass 36):**
- Axis (a): test-vectors.md supplement vs BC-embedded TVs cross-validation
- Axis (b): ADR-001..011 pairwise contradiction sweep

---

## Fix Records

No fixes applied. Zero findings. Pass is CLEAN. Counter advances to 1/3.
