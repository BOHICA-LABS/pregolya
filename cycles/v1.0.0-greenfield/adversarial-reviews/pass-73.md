---
document_type: adversarial-review
pass: 73
verdict: NOT CLEAN
finding_count: 2
finding_severity: [HIGH, MED]
novelty: MEDIUM-HIGH
novelty_class: d20-propagation-gap-single-carrier
novelty_notes: "Whole-catalog omission invisible to index-level counts — D20 burst propagated to 8 carriers but skipped test-vectors.md (single un-propagated carrier). Security-critical BCs absent from test catalog consumed by test-writer and holdout-evaluator: BC-2.15.005 (prompt-injection scanning) and BC-2.13.007 (env-secret stripping). Novelty MEDIUM-HIGH because the defect class is new (catalog-layer omission; invisible to BC-INDEX count checks)."
sibling_checks: "8/9 PASS (#8 FAIL → F-P73-02)"
arithmetic_axes_converged: false
domain_d_probe: ALL 12 forcing functions resolve
timestamp: 2026-07-15T00:00:00Z
phase: 1d
---

# Adversarial Review Pass 73

**Verdict:** NOT CLEAN — 2 findings (1 HIGH, 1 MED) + 4 OBS.

**Novelty:** MEDIUM-HIGH — D20 single-carrier propagation gap (catalog-invisible to index-level count checks).

---

## Findings

### F-P73-01 (HIGH)

**Location:** prd-supplements/test-vectors.md (v1.3) — BC Test Vector Inventory

**Description:** test-vectors.md v1.3 claims "86 authored BCs / ~475 vectors" with frontmatter annotation "aggregated from 86 BC files." This is the catalog consumed by test-writer and holdout-evaluator agents. All 9 D20-added BCs are absent from this catalog:

- BC-2.04.008 (SQLite FTS5 checkpoint search, P1)
- BC-2.08.013 (ToolCallDialect seam, P1)
- BC-2.08.014 (ProviderFallbackPolicy, P1)
- BC-2.09.006 (MCP server tool advertisement, P1)
- BC-2.09.007 (MCP server session management, P1)
- BC-2.13.007 (SandboxConfig env_allowlist stripping, P1)
- BC-2.15.004 (SkillStore load/list/exists, P1)
- BC-2.15.005 (MemoryWriteGuard guarded writes + injection scanning, P1)
- BC-2.15.006 (frozen-snapshot context mutation, P1)

All 9 are Priority-1 contracts. BC-2.15.005 governs prompt-injection scanning (EC-001/EC-002 role-injection prefixes + invisible-Unicode) and BC-2.13.007 governs env-secret stripping at sandbox boundary — both security-critical. BC-2.09.006/007 and the Domain-D §5 checklist BCs are also absent. The vectors exist in the individual BC files but are not surfaced in the catalog.

Root cause: The D20 burst propagated to 8 carriers (BC-INDEX, bc-authoring-plan, prd, prd-supplements/module-criticality, interface-definitions, error-taxonomy, L2-INDEX, ARCH-INDEX) but skipped test-vectors.md. The v1.3 changelog entry was only the F-P64-02 date fix — no D20 row additions.

Additionally, BC-2.10.003 row (v1.2 OnCeiling::Summarize + BudgetInfo) was listed with 5 TVs; the v1.2 burst added TV-006 (summarize path) and TV-007 (remaining-budget exposure), giving 7 TVs. This under-count went unnoticed under the D20 umbrella.

**Severity:** HIGH — test-writer and holdout-evaluator operate from this catalog; 9 entire BCs including security-critical prompt-injection and env-secret-stripping contracts are invisible to the test pipeline.

**Fix (PO):** Insert 9 rows at correct subsystem positions in test-vectors.md with live TV counts derived from each BC file: BC-2.04.008 (6 TVs), BC-2.08.013 (6 TVs), BC-2.08.014 (7 TVs), BC-2.09.006 (6 TVs), BC-2.09.007 (6 TVs), BC-2.13.007 (6 TVs), BC-2.15.004 (7 TVs), BC-2.15.005 (7 TVs), BC-2.15.006 (6 TVs). Correct BC-2.10.003 row: 5 → 7 TVs. Re-derive total: 95 BCs / ~534 vectors. Update frontmatter annotation to 95. Bump test-vectors.md → v1.4.

**FIXED (PO):** Completed in same burst. test-vectors.md → v1.4. 9 rows inserted at correct subsystem positions with live TV counts (BC-2.04.008: 6, BC-2.08.013: 6, BC-2.08.014: 7, BC-2.09.006: 6, BC-2.09.007: 6, BC-2.13.007: 6, BC-2.15.004: 7, BC-2.15.005: 7, BC-2.15.006: 6). BC-2.10.003 row corrected 5 → 7 TVs (v1.2 TV-006/007 now counted). Total re-derived: 95 BCs / ~534 vectors. Frontmatter annotation → 95.

---

### F-P73-02 (MED)

**Location:** prd.md + specs/behavioral-contracts/BC-INDEX.md — stale current-state "86" BC-count assertions (sibling-check #8 FAIL)

**Description:** Three current-state claims assert the old pre-D20 BC count of 86:

1. **prd.md §5b:** "all 86 BC files" — unframed reference to the pre-D20 baseline
2. **prd.md OQR-4:** "(total: 86 BCs)" — unframed; reads as current total
3. **BC-INDEX.md note #1:** "All 86 BCs now have subsystem: SS-NN" — unframed; reads as current assertion

All three are current-state assertions that should reflect the D20-expanded count of 95. They survived the D20 burst's propagation sweep (which targeted BC rows, not prose count claims) and the pass-72 86-count OBS sweep (which targeted bc-authoring-plan and module-criticality, not prd §5b or BC-INDEX notes).

Historical changelog entries containing "86" (Batch 13 authoring records, bc-authoring-plan v2.x series) are immutable audit trail and are exempt — only current-state claims require updating.

**Severity:** MED — stale current-state count assertions; can mislead test pipeline count-validation tooling and implementers reading the spec.

**Fix (PO):** prd.md §5b: "all 86 BC files" → "all 95 BC files". prd.md OQR-4: "(total: 86 BCs)" → "(total at Batch 13: 86 BCs; later grown to 95 via D20 domain expansion)". BC-INDEX note #1: "All 86 BCs" → "All 95 BCs" + add changelog section. Bump prd.md → v1.1, BC-INDEX.md → v1.3. Sweep historical "86" entries: verify all remaining instances are changelog/historical context, not current-state claims.

**FIXED (PO):** prd.md → v1.1 (§5b → 95; OQR-4 → Batch-13 framed). BC-INDEX → v1.3 (note #1 → 95; changelog section added). Post-fix grep: zero current-state "86" residue. Historical changelog entries verified legitimate; all remaining "86" instances are immutable audit trail.

---

## Observations (Non-Defects — All Fixed Same Burst)

### OBS-P73-A (stale prose — prd §2.10 summary)

**Location:** prd.md §2.10 BC-2.10.003 summary

**Description:** Summary text still read "(on_ceiling = halt)" — missing "| summarize" and "; Remaining-Budget Exposure" from the H1-authoritative title. Required 3-way sync: BC-INDEX title (fixed in F-P73-02 context), bc-authoring-plan Batch 6 entry (fixed in prior bursts), prd §2.10 summary.

**Disposition:** OBS — fixed in same burst. prd §2.10 → "(halt | summarize) + budget_info" in sync with H1 title.

---

### OBS-P73-B (process-gap — gate #32 carrier #5 module count stale)

**Location:** bc-authoring-plan gate #32 "ADR-propagation census" carrier #5 — module-criticality PO registry description

**Description:** Gate #32 carrier #5 description referenced "20-module subset" (pre-D20 PO registry count). The PO registry was updated to 22 modules in burst 150 (v1.3, 6/9/5/2). Gate #32 carrier #5 should reference the current count.

**Disposition:** OBS — fixed in same burst. bc-authoring-plan → v2.14 (carrier #5 "20-module subset" → "22-module subset").

---

### OBS-P73-C (missing trait enumeration — prd §3)

**Location:** prd.md §3 core trait enumeration

**Description:** prd §3 listed pre-D20 traits without the 4 D20 additions: SkillStore, MemoryWriteGuard, ToolCallDialect, ProviderFallbackPolicy. These are framework-scope primitives (D20) and should appear in the §3 trait enumeration for completeness.

**Disposition:** OBS — fixed in same burst. prd §3 updated to include all 4 D20 traits.

---

### OBS-P73-D (illustrative paraphrase — no action)

**Location:** prd.md §2 illustrative narrative

**Description:** One illustrative use-case paraphrase used pre-D20 framing; this is non-normative prose. No BC or contract affected.

**Disposition:** NOT a defect. Advisory only — no action required.

---

## Clean Verifications

### Mandatory A — ARCH-INDEX / L2-INDEX title and count sync (deferred from pass 72)

ARCH-INDEX v1.3 BC ranges sum to 95 (all subsystem ranges verified against BC-INDEX row count by subsystem). L2-INDEX v1.2 capability registry consistent: 21 CAPs (11 P0 / 7 P1 / 3 P2), 14 DIs, 13 DECs, 9 ASMs, 8 R-categories, 14 FMs. CAP tier breakdown 11/7/3 matches ARCH-INDEX and prd frontmatter. PASS.

### Mandatory B — Full prd.md read (deferred from pass 72)

Full prd.md read completed. Findings above (F-P73-02 + OBS-P73-A/C). No additional defects detected beyond those reported. PASS (after PO fix).

### Mandatory C — Independent census recount (deferred from pass 72)

Independent HTTP-table vs omission-error vs blanket-library split recount:

85 total = 43 HTTP-table + 16 omission-type + 26 blanket library-layer

By component: CORE 7 / GRAPH 16 / CHKPT 9 / SERVER 14 / PROV 10 / MCP 5 / SPLIT 2 / SBXD 6 / RETRY 4 / CRON 3 / MEMORY 7 / BUDGET 2 = 85 ✓

Corrigendum partition EXACT — matches the census established in D20 PO burst. PASS.

---

## Domain-D Probe

All 12 domain-D forcing functions from `domain-d-hermes-agent.md` (v1.1) resolve correctly:

| Forcing Function | Resolution | Status |
|-----------------|------------|--------|
| req 1 — tool dialect adaptation (ChatML / Hermes XML tool format) | BC-2.08.013 (ToolCallDialect seam, Hermes-XML + E-PROV-009) | ✓ |
| req 2 — budget-aware execution with stop-and-summarize | BC-2.10.003 v1.2 (OnCeiling::Summarize, RunContext.budget_info) | ✓ |
| req 3 — agent identity / persona prompt configuration | app-layer — ferrochain provides context-mutation primitives; persona config = application responsibility | ✓ |
| req 4 — workflow graph topology and state management | app-layer — ferrochain provides graph execution; topology = application responsibility | ✓ |
| req 5 — multi-agent coordination protocol | v2-deferred — code-to-tool RPC gateway explicitly deferred (D20) | ✓ |
| req 6 — env-secret sanitization before subprocess launch | BC-2.13.007 (SandboxConfig env_allowlist, E-SBXD-006) | ✓ |
| req 7 — runtime-loadable procedural skills (skill doc injection on demand) | BC-2.15.004 (SkillStore load_skill / list_skills / skill_exists) | ✓ |
| req 8 — full-text search over conversation and checkpoint history | BC-2.04.008 (SQLite FTS5, E-CHKPT-008 VAL / E-CHKPT-009 INTERNAL split) | ✓ |
| req 9 — dynamic capability negotiation / feature flags | v2-deferred — capability negotiation deferred per D20 scope decision | ✓ |
| req 10 — multi-vendor provider fallback chain (429/5xx/Auth failover) | BC-2.08.014 (ProviderFallbackPolicy, E-PROV-010) | ✓ |
| req 11 — MCP server tool advertisement to external agents | BC-2.09.006 (tool advertisement) + BC-2.09.007 (session mgmt) | ✓ |
| req 12 — HITL risk-tiered interrupt classification | app-layer — BC-2.05.006 provides typed action-risk levels; HITL UI = application responsibility | ✓ |

No orphaned citations. All deferral notes verified. v2-deferred items (req 5, req 9) are scope-bounded by D20 decisions and do not represent coverage gaps.

---

## Sibling Checks

| # | Check | Result |
|---|-------|--------|
| 1 | interface-definitions v2.22: SkillStore name-keyed + tag-filtered; Replace old_value Option\<Value\> | PASS |
| 2 | ADR-012 v1.1: Decision-4 = headline = Consequences coherent; scope 34 + ADR-013 → final 35 | PASS |
| 3 | ADR-013: sole mcp::server authority; ARCH-INDEX v1.3; 13 ADRs total | PASS |
| 4 | BC-2.10.003 v1.3: VP anchors 04/05/06 present; 3-way title sync (BC-INDEX v1.2→v1.3, plan v2.13→v2.14) | PASS |
| 5 | error-taxonomy v1.13: E-MEMORY-007 rationale = prompt-injection per BC-2.15.005 | PASS |
| 6 | PO criticality registry v1.3: 22 = 6/9/5/2; write_guard HIGH; mcp::server MEDIUM; memory::skills excluded | PASS |
| 7 | BC-2.09.006 v1.1: Architecture Anchors cites ADR-013 (not ADR-012) | PASS |
| 8 | Stale current-state 86s: prd §5b / prd OQR-4 / BC-INDEX note #1 | FAIL → F-P73-02 |
| 9 | Gate #32: 5 carriers including both criticality registry views | PASS |

---

## Baseline Verified

| Metric | Value |
|--------|-------|
| Total live BCs | 95 (48 P0 / 39 P1 / 8 P2) |
| Total CAPs | 21 (11 P0 / 7 P1 / 3 P2) |
| Total test vectors (post-fix) | ~534 across 95 BCs |
| Universe | 35 modules (9 CRITICAL / 13 HIGH / 11 MEDIUM / 2 LOW) |
| Census | 85 codes = 43 HTTP-table + 16 omission + 26 blanket library-layer |
| ADRs | 13 (ADR-013 mcp::server placement) |
| RetryHint divergences | 6 |
| Gate #31 trait-census | 24/28 resolved (4 pending implementation phase) |

---

## Novelty Assessment

**MEDIUM-HIGH** — The defect class is a whole-catalog omission invisible to index-level BC count checks. BC-INDEX correctly listed 95 BCs; ARCH-INDEX ranges summed correctly; plan Batch counts were correct. Only the test-vectors catalog was skipped. Standard count-based sweep tooling would not detect this gap because the BC count appeared correct at every checked carrier. The propagation mechanism (D20 burst touching 8 of 9 required carriers) is a new pattern.

**Trajectory:** →2 (P1D-73). Convergence counter 0/3.
