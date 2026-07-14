---
document_type: adversarial-review
pass: 6
phase: 1d
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
finding_count: 3
sibling_checks: ALL PASS
trajectory: "14→5→7→13→3→3"
convergence_counter: "0/3"
produced_by: product-owner
timestamp: 2026-07-14T00:00:00Z
---

# ADV-P1D-PASS-6 — Adversarial Review

**Verdict:** NOT CLEAN — 3 findings (1 HIGH, 2 MED)

---

## Sibling Checks — ALL PASS

| Check | Result |
|-------|--------|
| Complement tables (full distinct-value tables) | PASS |
| Disambiguating codes present | PASS |
| 5/5 spot rotation | GREEN |
| 14/14 DIs — no orphans | PASS |

---

## Findings

### F-P6-01 [HIGH] — `running` vocabulary regression-escape

**Locations:**
- `bc-authoring-plan.md:259` — BC-2.12.003 title used non-canonical `create → running → completed/failed`
- `BC-2.05.004.md:134` — VP-HITL-07 used `interrupted → running → completed/interrupted`

**Canonical lifecycle:** `queued → in_progress → completed | failed | interrupted | cancelled`

**Fix applied:**
- `bc-authoring-plan.md:259`: `running` → `in_progress` in BC-2.12.003 title
- `BC-2.05.004.md:134`: VP-HITL-07 `running` → `in_progress`
- `BC-2.05.005.md:100,102,112`: Three additional `"running"` escapes in error-payload literals and test vectors also corrected during complement-evidence sweep

**Complement evidence (post-fix):**
```
grep -rn "→ running\|running →\|\"running\"" .factory/specs/
(no output)
```
Result: 0 hits — clean.

---

### F-P6-02 [MED] — Plan staleness: title drift + count + Red-Gate over-listing

**Sub-issues:**

**F-P6-02a** — `bc-authoring-plan.md:256` title drift for BC-2.09.005:
- Was: `MCP __aenter__ NotImplementedError contract — R11 Red Gate`
- BC-INDEX H1 authoritative title: `MultiServerMcpClient Holds No Live Connections (Red Gate — R11)`
- Fix: updated plan line 256 to match BC-INDEX verbatim.

**F-P6-02b** — `bc-authoring-plan.md:316` count stale:
- Was: `origin: greenfield for all 83 BCs`
- Correct total (per BC-INDEX header): 86 BCs
- Fix: `83` → `86`.

**F-P6-02c** — `bc-authoring-plan.md:314` Red-Gate list over-includes BC-2.07.001:
- Was: `BCs for R8/R10/R11 (BC-2.07.001-002, BC-2.02.003-004, BC-2.09.004-005)`
- BC-INDEX Red Gate table has exactly 5 BCs: BC-2.02.003, BC-2.02.004, BC-2.07.002, BC-2.09.004, BC-2.09.005; BC-2.07.001 is NOT a Red Gate BC
- Fix: `BC-2.07.001-002` → `BC-2.07.002`.

---

### F-P6-03 [MED+process-gap] — `status:` field ungoverned; 19 BCs in `draft` state

**Finding:** 19 BC files across ss-04 (×7), ss-11 (×6), ss-13 (×6) carried `status: draft` despite being fully authored and integrated into BC-INDEX. No authoring guideline defined when `draft` transitions to `active`.

**Decision:** A BC is `active` once integrated into BC-INDEX. Version bumps do NOT reset status. Adversarial passes handle revision review — `draft` is not a review-cycle state.

**Fix applied:**
- All 19 `status: draft` files in ss-04/ss-11/ss-13 normalized to `status: active`.
- Authoring guideline #9 in `bc-authoring-plan.md` extended: `status: active` — a BC is active once integrated into BC-INDEX; version bumps do NOT reset this field to `draft`.

**Complement evidence (post-fix):**
```
grep -rhoE "^status: [a-z]+" .factory/specs/behavioral-contracts/ss-*/ | sort | uniq -c
    86 status: active
```
Result: single value `active` ×86 — clean.

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

Convergence counter: 0/3 (need 3 consecutive clean passes at ≤0 findings to close Phase 1d).
