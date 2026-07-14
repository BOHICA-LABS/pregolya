---
document_type: adversarial-review-pass
phase: 1d
pass: 34
verdict: NOT CLEAN
findings_count: 3
high_count: 1
med_count: 2
low_count: 0
observations_count: 3
consecutive_clean: 0
required_clean: 3
trajectory: "...→4→2→3"
timestamp: 2026-07-14T00:00:00Z
new_class: "live code collision (RETRY namespace — E-RETRY-003 used for two contradictory meanings); tooling blind spot (gate #16 regex misses colon-delimited pairings); partial-fix propagation gap (F-P31-01 not fully applied to PC8)"
---

# Adversarial Review Pass 34 — Phase 1d

**Verdict: NOT CLEAN** — 3 findings (1 HIGH, 2 MED, 0 LOW) + 3 observations. Counter reset: 0/3 consecutive clean.

---

## F-P34-02 [HIGH] — Error-Code Collision: E-RETRY-003 Has Two Contradictory Meanings

**Finding class:** Live error-code collision — same code assigned contradictory variant names in BC vs taxonomy (same class as GRAPH/SERVER collisions previously reconciled; RETRY namespace was never swept).

**Scope:**
- `.factory/specs/prd-supplements/error-taxonomy.md` line 189 (authoritative): E-RETRY-003 = `CircuitBreakerOpen`, POLICY, `Later(<reset_timeout>)`.
- `.factory/specs/behavioral-contracts/ss-16/BC-2.16.003.md` lines 52, 74, 85, 117: uses E-RETRY-003 = `CircuitBreakerOpen` consistently.
- `.factory/specs/behavioral-contracts/ss-16/BC-2.16.001.md` EC-003 (line ~94): uses E-RETRY-003 = `InvalidRetryLimit` ("Construction returns `Err(E-RETRY-003: InvalidRetryLimit)`...").
- `.factory/specs/behavioral-contracts/ss-16/BC-2.16.001.md` TV-004 (line ~111): asserts `Err(E-RETRY-003)` for zero-limit reject.

**Finding:** The RETRY namespace defines only E-RETRY-001 (RetryExhausted), E-RETRY-002 (GlobalLimitExhausted), E-RETRY-003 (CircuitBreakerOpen). No code exists for `InvalidRetryLimit`, so BC-2.16.001 grabbed the highest existing code E-RETRY-003. A caller catching E-RETRY-003 for circuit-breaker backoff (`Later`) would misinterpret a permanent construction misconfiguration (should be VAL/Never) as a transient condition. This is the same collision class as the GRAPH/SERVER collisions reconciled in prior bursts; the RETRY namespace was never swept by gate #16 because the colon-delimited form `E-RETRY-003: InvalidRetryLimit` was invisible to the gate regex (see F-P34-03).

**Severity justification (HIGH):** The collision crosses semantic categories — POLICY/Later vs VAL/Never. A client that catches E-RETRY-003 to schedule a retry will busy-loop indefinitely on what is actually a fatal misconfiguration.

**Fix applied:**
1. `error-taxonomy.md` (v1.4 → v1.5): Minted E-RETRY-004 = `InvalidRetryLimit`, category VAL, severity broken, BC anchor BC-2.16.001, RetryHint Never (matches VAL default — not a divergence). Changelog updated.
2. `BC-2.16.001.md` (v1.0 → v1.1): EC-003 (`E-RETRY-003: InvalidRetryLimit` → `E-RETRY-004: InvalidRetryLimit`; category VAL, RetryHint Never noted); TV-004 (`Err(E-RETRY-003)` → `Err(E-RETRY-004)`). Version + changelog added.
3. Verified BC-2.16.003 remains the sole owner of E-RETRY-003 (CircuitBreakerOpen) — no changes needed there.
4. Gate #22 divergence registry: E-RETRY-003 CircuitBreakerOpen `Later` remains a legitimate divergence; unchanged. E-RETRY-004 Never matches VAL default — NOT added as a divergence.

---

## F-P34-01 [MED] — GET /threads List PC8/PC9 Missing Clamp Semantics and Declared Ordering

**Finding class:** Pagination coherence gap — partial-fix propagation from F-P31-01 (gate #24 class, first introduced ADV-P1D-PASS-31).

**Scope:** `.factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md` PC8 (line ~65) and PC9 (line ~66).

**Finding:** PC8 states "Accepts query params `metadata` (filter), `limit` (default 10, max 100), `offset`." — no out-of-range CLAMP rule, no declared ordering. PC9 states the response shape without ordering. Sibling PC17 (same BC) received the full F-P31-01 fix (values > 100 clamped to 100; offset default 0; ordered newest-first) in ADV-P1D-PASS-31. PC8 did not. Yet interface-definitions.md §Canonical Pagination Convention (line 162) explicitly cites "BC-2.12.001 PC8 (threads list)" as the clamp+`created_at`-DESC anchor for GET /threads — a partial-fix propagation gap from pass-31.

**Severity justification (MED):** Implementers reading BC-2.12.001 as spec authority for GET /threads would find no clamp guarantee and no ordering declaration in PC8, potentially implementing unbounded queries or wrong ordering. The interface-definitions.md row cites PC8 as anchor but PC8 did not carry the full convention.

**Fix applied:**
1. `BC-2.12.001.md` (v1.1 → v1.2): PC8 updated — added "values > 100 silently clamped to 100" and "offset (default 0)". PC9 updated — added `created_at` DESC ordering note with F-P31-01 citation. Version + changelog updated.
2. `interface-definitions.md` side is already correct and cites PC8 as anchor — no interface-side edit needed.

---

## F-P34-03 [MED, process-gap] — Gate #16 Census Regex Misses Colon-Delimited Pairings

**Finding class:** Tooling blind spot — structural gap in standing gate that allowed F-P34-02 to survive 33 passes.

**Scope:** `.factory/specs/prd-supplements/bc-authoring-plan.md` gate #16 (~line 451).

**Finding:** Gate #16 regex `grep -hrn "E-[A-Z]*-[0-9]\{3\} [A-Z][A-Za-z]*"` requires a space immediately after the code. BC bodies also use the form `E-RETRY-003: InvalidRetryLimit` (colon+space), which the regex never matches. This is why F-P34-02 survived 33 passes — `BC-2.16.001.md` EC-003 uses the colon form and was invisible to every gate #16 census. Additionally, the gate lacked explicit cross-check instructions for collision detection (verifying variant name against taxonomy's authoritative code→variant binding).

**Fix applied:**
1. `bc-authoring-plan.md` gate #16 (~line 451): Widened census to two grep commands — one for space-delimited form, one for colon-delimited form. Added collision-detection note requiring each extracted pairing to be cross-checked against error-taxonomy.md's authoritative binding (not just variant-name drift, but also code collision detection).

---

## Gate #16 Widened Census (Post-Fix Verification)

Census scope: all BC files under `.factory/specs/behavioral-contracts/`, both pairing forms.

**Space-delimited pairings extracted (representative sample — all verified PASS):**
- E-BUDGET-001 BudgetCeilingReached ✓
- E-BUDGET-002 JournalWriteFailed ✓
- E-CHKPT-001 CheckpointWriteFailed ✓
- E-GRAPH-001 InvalidUpdateError ✓
- E-GRAPH-003 UnknownRoutingTarget ✓
- E-GRAPH-013 InsufficientApproverRole ✓
- E-GRAPH-016 InterruptWithoutCheckpointer ✓
- E-MEMORY-003 ScopeAccessDenied ✓
- E-RETRY-004 InvalidRetryLimit ✓ (new — post-fix)
- E-SERVER-003 ThreadNotFound ✓
- E-SERVER-016 IdempotencyLockTimeout ✓
- (false positives from table rows with category names filtered out — POLICY, VAL, TIMEOUT, TOOL, DURABILITY are not variant names in the taxonomy)

**Colon-delimited pairings extracted:**
- E-GRAPH-006: BspDeterminismViolation ✓ (matches taxonomy)
- E-RETRY-003: InvalidRetryLimit ✗ **WAS COLLISION** — FIXED (now E-RETRY-004)
- E-SBXD-001: WorkspaceEscape ✓ (matches taxonomy)
- E-SBXD-002: PolicyNotEnforceable ✓ (matches taxonomy)
- E-SBXD-003: SandboxInitFailed ✓ (matches taxonomy)

**Post-fix colon-delimited result:** 0 collisions. All 5 colon-delimited pairings resolve correctly post-fix.

**Census verdict: PASS (post-fix).** 1 collision found (E-RETRY-003/InvalidRetryLimit) and resolved by minting E-RETRY-004.

---

## Gate #22 RetryHint Coherence (Post-Fix)

| Error Code | Category | Default RetryHint | Per-Code RetryHint | Status |
|-----------|----------|-------------------|--------------------|--------|
| E-RETRY-001 | POLICY | Never | Never | PASS — matches default |
| E-RETRY-002 | POLICY | Never | Never | PASS — matches default |
| E-RETRY-003 | POLICY | Never | `Later(<reset_timeout>)` | PASS — intentional divergence, BC-2.16.003 rationale |
| E-RETRY-004 | VAL | Never | Never | PASS — matches default; NOT a divergence |

New code E-RETRY-004: VAL/Never. VAL default = Never. No divergence → NOT added to known-intentional-divergences table. Gate #22 PASS.

---

## Gate #24 Six-Surface Pagination Census (Post-Fix)

| Surface | Interface Row | Anchor BC PC | Clamp | Ordering | Status |
|---------|-------------|-------------|-------|----------|--------|
| GET /threads list | line 170: default 10 max 100, `created_at` DESC | BC-2.12.001 PC8 | YES (post-fix) | YES (post-fix, PC9) | PASS |
| GET /threads/{id}/history | line 174: max 100, clamped | BC-2.12.001 PC17 | YES | newest-first | PASS |
| GET /assistants list | line ~181: default 10 max 100, `created_at` DESC | BC-2.12.002 PC21-PC23 | YES | YES | PASS |
| GET /assistants/{id}/versions | canonical + version ASC exemption | BC-2.12.002 PC20 | YES | version ASC | PASS |
| GET /threads/{id}/runs | default 10 max 100, `created_at` DESC | BC-2.12.003 PC18 | YES | YES | PASS |
| GET /runs?schedule_id | default 10 max 100, `created_at` DESC | BC-2.12.004 PC7 | YES | YES | PASS |

**Gate #24 verdict: ALL 6 SURFACES PASS (post-fix).** Surface 1 (GET /threads PC8) was the failing surface; fixed by F-P34-01.

---

## Observations

### OBS-P34-1 [location-note] — Endpoint-Count Invariant Location

The endpoint-count invariant (26 = Threads 7 + Assistants 7 + Runs 7 + Cron 4 + aggregate 1) lives in `bc-authoring-plan.md` lines 407-411 (added OBS-P33-2), not in `interface-definitions.md` §17-B as STATE.md resume text may claim. Substance correct and enforced; location note only — STATE.md resume pointer should be corrected.

### OBS-P34-2 [no-defect] — BC-2.12.002 PC Label Transposition

BC-2.12.002 actual ordering is PC21=pagination, PC22=response shape, PC23=`created_at` DESC. A dispatch prose had the labels transposed. No spec defect.

### OBS-P34-3 [known-partial] — Holdout Domain A "Forensic-Grade Tamper-Evident Audit Trail"

The holdout Domain A describes "forensic-grade tamper-evident audit trail" which has no dedicated BC (BC-2.10.002 EvidenceJournal is budget-scoped only). The brief self-flags this as NEW/PARTIAL as a forcing function, not a Phase-1 acceptance criterion. No spec-internal defect.

---

## Novelty Assessment

**Classification: HIGH.**

**New classes introduced:**
1. **Live code collision in RETRY namespace** — same class as prior GRAPH/SERVER collisions but in a previously-unswept namespace. Root cause: RETRY namespace was not included in any prior collision sweep because its codes were authored together (same burst) and no cross-component collision audit existed at authoring time.
2. **Tooling blind spot (gate #16 colon form)** — the census regex has been running 34 passes without ever matching colon-delimited pairings. Any BC that used the `E-XXX-NNN: VariantName` form was systematically invisible to gate #16.
3. **Partial-fix propagation gap (F-P31-01/PC8)** — the pass-31 fix applied the clamp/ordering canon to PC17 (history endpoint) but the same BC's PC8 (list endpoint) was not updated, even though interface-definitions.md §Canonical Pagination Convention explicitly cites PC8 as the anchor.

**Recovery signal:** The two substantive defects (F-P34-02/03) share a common root cause — the gate that should have caught F-P34-02 was blind to the form BC-2.16.001 used. Fixing the gate (F-P34-03) and running the widened census immediately finds zero additional collisions, confirming the spec is clean beyond the one newly-resolved collision.

---

## Sibling Reverse-Anchor Checks

No BCs added or retired this burst. 1 new E-code minted (E-RETRY-004). BC count unchanged: P0 48 + P1 30 + P2 8 = 86 total.

**(a) BC and artifact version bumps consistent with changelog entries:**
- `BC-2.16.001.md`: 1.0 → 1.1 ✓ (F-P34-02: E-RETRY-003 → E-RETRY-004 in EC-003, TV-004; category VAL/Never noted)
- `BC-2.12.001.md`: 1.1 → 1.2 ✓ (F-P34-01: PC8 clamp + offset default; PC9 created_at DESC)
- `prd-supplements/error-taxonomy.md`: 1.4 → 1.5 ✓ (F-P34-02: E-RETRY-004 minted)
- `prd-supplements/bc-authoring-plan.md`: gate #16 widened (no version field)

**(b) E-RETRY-003 still exclusively owned by BC-2.16.003 (CircuitBreakerOpen):**
Census: `grep -rn "E-RETRY-003" .factory/specs/behavioral-contracts/` — BC-2.16.003.md only (post-fix). PASS.

**(c) Gate #24 BC-2.12.001 PC8 anchor cites F-P31-01:**
`grep -n "limit\|offset" BC-2.12.001.md | grep -v "17"` → PC8: clamp + offset default 0 present. PC9: created_at DESC + F-P31-01 cited. PASS.

---

## Fix Records (Post-Application)

| Finding | File | Change | Status |
|---------|------|--------|--------|
| F-P34-02 | `.factory/specs/prd-supplements/error-taxonomy.md` | E-RETRY-004 (InvalidRetryLimit, VAL, broken, BC-2.16.001, Never) minted; v1.4→1.5; changelog entry | APPLIED |
| F-P34-02 | `.factory/specs/behavioral-contracts/ss-16/BC-2.16.001.md` | EC-003 E-RETRY-003 → E-RETRY-004 (category VAL, RetryHint Never noted); TV-004 E-RETRY-003 → E-RETRY-004; v1.0→1.1; changelog added | APPLIED |
| F-P34-01 | `.factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md` | PC8: clamp semantics + offset default 0 added; PC9: created_at DESC + F-P31-01 citation added; v1.1→1.2; changelog entry | APPLIED |
| F-P34-03 | `.factory/specs/prd-supplements/bc-authoring-plan.md` | Gate #16: census widened to two grep forms (space + colon); collision-detection cross-check note added | APPLIED |
