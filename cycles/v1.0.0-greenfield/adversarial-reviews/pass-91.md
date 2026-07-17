---
document_type: adversarial-review-pass
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-17T11:30:00Z
cycle: v1.0.0-greenfield
pass: 91
burst: 173
phase: 1d
clean_strict: false
clean_pr_merge: false
finding_count: 4
finding_severity: "1 HIGH + 1 MED + 2 OBS"
novelty: MEDIUM
counter_before: 0
counter_after: 0
traces_to: STATE.md
---

# Adversarial Review — Pass 91 (Burst 173)

**Date:** 2026-07-17
**Pass:** P1D-91
**Verdict:** NOT CLEAN
**Finding count:** 4 (1 HIGH + 1 MED + 2 OBS)
**CLEAN (strict):** no
**CLEAN (PR-merge):** no
**Novelty:** MEDIUM — first genuine CONTENT-layer finding cluster in many passes (budget subsystem semantic mis-anchor unreachable by index-level gates)
**Convergence counter:** 0/3 (reset)

## Probes Verified Clean

- VP-001..005 provability vs anchor BCs
- ADR-005/009/012 ↔ BC alignment
- Holdout CAP-020/021 traceability
- Gate #33 11-code sample
- Gate #34 format census

## Findings

### F-P91-01 (HIGH) — on_ceiling mis-attributed to BudgetPolicy TRAIT

**Owner:** PO + BA
**Component:** SS-10 (Budget) BC trio + CAP-012

BC-2.10.001, BC-2.10.003, BC-2.10.004, and CAP-012 all attributed `on_ceiling` to the BudgetPolicy TRAIT. A pure Rust trait carries no data field — `on_ceiling` is a configuration value, not a trait method. The canonical owner is BudgetConfig STRUCT (api-surface per ADR-009), which lives in GraphConfig.budget_config. The engine branches on BudgetConfig::on_ceiling after receiving a Deny decision from the policy. This class of mis-anchor (trait vs struct data ownership) is unreachable by index-level gates that only verify name presence.

**Fix applied:**
- BC-2.10.001 v1.2: PC1 + TV-001/2/3 → BudgetConfig::on_ceiling; engine constructs policy from config
- BC-2.10.003 v1.5: Description/PC1/PC4/PC5/Arch-Anchor → BudgetConfig::on_ceiling in GraphConfig.budget_config
- BC-2.10.004 v1.2: Description/PC1/TV-001/EC-001 → OnCeiling::Escalate (canonical variant)
- BC-2.06.003 v1.1: corpus-sweep residual EC-005 → BudgetConfig; changelog section created
- capabilities-p0 v1.2: CAP-012 → "budget configuration's on_ceiling (BudgetConfig::on_ceiling)"
- BC-2.10.002: swept clean, no changes needed
- Post-fix corpus grep: zero residual mis-attribution across all 95 BCs + 6 supplements

**Decision:** D18-P91-A

---

### F-P91-02 (MED) — OnCeiling + BudgetConfig undefined in interface-definitions

**Owner:** architect
**Component:** interface-definitions (SS-10 public surface)

OnCeiling and BudgetConfig are publicly exported SS-10 surface types but were absent from interface-definitions, leaving the public API contract incomplete. Consumers of the budget subsystem API had no authoritative type definition to reference.

**Fix applied:**
- interface-definitions v2.29 adds:
  - `OnCeiling { Halt, Escalate, Summarize { summarize_prompt: String } }` with EC-005 fallback semantics in doc comments
  - `BudgetConfig { soft_limit: Option<u64>, hard_limit: Option<u64>, on_ceiling: OnCeiling }` (fields from BC-2.10.001 TVs)
  - Engine-branches-on-config prose explaining Deny → on_ceiling dispatch
- Siblings: module-decomposition v1.9 + purity-boundary-map v1.4 (core::budget row type inventories +OnCeiling/BudgetConfig)

**Decision:** D18-P91-A

---

### F-P91-03 (OBS) — TOML default_on_ceiling comment omitted Summarize

**Owner:** architect
**Component:** interface-definitions (TOML configuration example)

The TOML `default_on_ceiling` comment example did not mention the Summarize variant.

**Adjudication:** Bare-string TOML default intentionally excludes Summarize (struct variant with payload; not expressible as bare string). Table form `[budget.on_ceiling] mode = "Summarize" / summarize_prompt = "..."` is documented inline. Prose is correct; no structural change needed.

**Decision:** D18-P91-A

---

### F-P91-04 (OBS) — BC-2.15.004 EC-004 mapped MemoryStore READ failure to E-MEMORY-002 StorageFull

**Owner:** PO
**Component:** BC-2.15.004 (MemoryStore) + error-taxonomy

BC-2.15.004 EC-004 mapped MemoryStore READ I/O failure to E-MEMORY-002 StorageFull (write-capacity semantics; wrong for a read error). Hedge phrase "or analogous I/O error code" was insufficient — left the error mapping ambiguous; MEMORY namespace had no read-failure code.

**Fix applied:**
- E-MEMORY-008 MemoryStoreReadFailed MINTED: DURABILITY / broken / RetryHint Maybe (namespace default, no divergence); anchor BC-2.15.004 EC-004 + new TV-008 raise-condition
- Gate #31 near-name PASS — no name collision
- BC-2.15.004 v1.1: hedge removed; EC-004 maps to E-MEMORY-008
- error-taxonomy v1.17 → v1.18: E-MEMORY-008 row added
- interface-definitions v2.29 → v2.30: census row for E-MEMORY-008 (DURABILITY blanket-covered; explicit row for traceability)
- **ERROR-CODE CENSUS: 85 → 86 = 43 + 16 + 27** (blanket E-MEMORY-* 7 → 8)

**Decision:** D18-P91-B

---

## Summary

| Finding | Severity | Owner | Status |
|---------|----------|-------|--------|
| F-P91-01 | HIGH | PO + BA | FIXED — BC-2.10.001/003/004 v1.2/1.5/1.2 + BC-2.06.003 v1.1 + capabilities-p0 v1.2 |
| F-P91-02 | MED | architect | FIXED — interface-definitions v2.29; module-decomposition v1.9; purity-boundary-map v1.4 |
| F-P91-03 | OBS | architect | ADJUDICATED — no change (bare-string TOML intentionally excludes Summarize) |
| F-P91-04 | OBS | PO | FIXED — E-MEMORY-008 minted; BC-2.15.004 v1.1; error-taxonomy v1.18; interface-definitions v2.30 |

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | P1D-91 |
| **Novelty score** | MEDIUM |
| **Trajectory** | →4 (P1D-91); cumulative tail →4→4→1→4 |
| **Verdict** | FINDINGS_REMAIN |

First genuine CONTENT-layer finding cluster in many passes. Budget subsystem (SS-10) carried a semantic mis-anchor (trait vs struct data ownership) invisible to all index-level gates — neither name-presence census nor format-consistency gate can detect which Rust construct owns a field. F-P91-01 and F-P91-02 are a pair: the BC mis-anchor and the missing interface definition are two faces of the same gap. F-P91-04 mints E-MEMORY-008 to close a read/write semantic confusion in the error taxonomy that survived since the MEMORY namespace was introduced.

## Convergence Assessment

**CLEAN (strict):** no (4 findings)
**CLEAN (PR-merge):** no
**Streak:** 0/3 (reset)
**Trajectory:** →4 (P1D-91); tail →4→4→1→4
**Next action:** dispatch adversary pass 92; PASS-92 sibling-checks: SS-10 trio + BC-2.06.003 + BC-2.15.004 (on_ceiling/BudgetConfig coherence + E-MEMORY-008 anchor); interface-definitions v2.30 (OnCeiling/BudgetConfig defs + E-MEMORY-008 census); error-taxonomy v1.18 (E-MEMORY-008 row); census 86=43+16+27 recount; module-decomposition v1.9 + purity-boundary-map v1.4 type inventories; capabilities-p0 v1.2 CAP-012.
