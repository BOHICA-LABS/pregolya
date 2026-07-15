---
document_type: adversarial-review
pass: 72
verdict: NOT CLEAN
finding_count: 8
finding_severity: [HIGH, HIGH, MED, MED, MED, MED, MED, MED]
novelty: HIGH
novelty_class: fresh-content-integration-defects
novelty_notes: "Fresh-content integration defects — D20 burst introduced interface/BC/taxonomy misalignments not caught by prior passes. All D20-era fresh content. Novelty HIGH because the defect class is new (interface signatures diverging from their governing BC on first authoring)."
sibling_checks: PARTIAL-FAIL
arithmetic_axes_converged: false
domain_d_probe: ALL 12 forcing functions resolve
timestamp: 2026-07-15T00:00:00Z
phase: 1d
---

# Adversarial Review Pass 72

**Verdict:** NOT CLEAN — 8 findings (2 HIGH, 6 MED)

**Novelty:** HIGH — fresh-content integration defects (D20 burst mismatch class)

---

## Findings

### F-P72-01 (HIGH)

**Location:** interface-definitions.md §SkillStore (v2.21 lines ~340–376)

**Description:** The `SkillStore` trait signatures in interface-definitions.md use a `(namespace, key)` parameter pattern for `load_skill` and `skill_exists`, and a `namespace: Option<&str>` filter for `list_skills`. This directly contradicts:

- **BC-2.15.004 PC1:** `load_skill(name: &str) -> Result<Option<String>, FerrochainError>` (name-keyed)
- **BC-2.15.004 PC2:** `list_skills(tags: &[String]) -> Result<Vec<SkillDescriptor>, FerrochainError>` (tag-filtered)
- **BC-2.15.004 PC3:** `skill_exists(name: &str) -> Result<bool, FerrochainError>` (name-keyed)
- **ADR-012 Decision 1 Primitive A:** identical name-keyed + tag-filtered signatures

The BC invariant states: "The mapping from skill name to `(namespace, key)` is maintained by the `SkillStore` implementation. Name collisions are not permitted." The `(namespace, key)` is impl-internal, not API surface. The interface-definitions.md exposed impl internals as method parameters, contradicting the authoritative design.

Gate #31 RESOLVED row for SkillStore cited the corrected shapes — but the actual code block in the document retained the wrong shapes. The gate row passed on a false positive.

**Severity:** HIGH — implementers building against this interface will produce code that cannot satisfy the BCs' postconditions. API surface is wrong.

**Fix:** Correct `SkillStore` method signatures in interface-definitions.md §SkillStore to the name-keyed + tag-filtered forms per BC-2.15.004 + ADR-012 Decision 1 Primitive A. Gate #31 RESOLVED note requires no change (it already stated correct shapes; the code block was not audited against the note).

---

### F-P72-02 (HIGH)

**Location:** ADR-012 (architecture/decisions/ADR-012-self-improvement-primitives.md) — Decision 4 universe claim + Decision 4 Consequences skills-row contradiction

**Description:** Two sub-findings:

**Sub-A (universe 34-stale):** ADR-012 Decision 4 declares "Module universe after D20 = **34** (9 CRITICAL + 13 HIGH + 10 MEDIUM + 2 LOW)." However, `mcp::server` (MEDIUM, CAP-021 ferrochain-mcp) had no governing ADR at BC-2.09.006 authoring time — BC-2.09.006 Architecture Anchors cited ADR-012 §Consequences as the placement authority, but ADR-012 contains no MCP content. ADR-013 is being minted by the architect to govern `mcp::server`; once accepted, the universe is 35, not 34. ADR-012's universe claim is stale/premature.

**Sub-B (Decision 4 Consequences skills-row contradiction):** ADR-012 §Consequences states ferrochain-memory gains **two new module rows**: `memory::skills` (MEDIUM) and `memory::write_guard` (HIGH). But Decision 4 §Placement Summary / §Classification says `memory::skills` receives **No new row** ("No independent execution logic beyond storage delegation"). The §Consequences text and the §Classification text contradict each other.

**Severity:** HIGH — universe count is wrong and the skills-row is contradicted within the same ADR.

**Fix (architect scope — do NOT fix in this burst):** Architect must amend ADR-012 Decision 4 universe claim (34→35 once ADR-013 accepted) and resolve the skills-row contradiction (delete the `memory::skills` row from §Consequences ferrochain-memory gains list, keeping only `memory::write_guard`). PO fix: BC-2.09.006 Architecture Anchors must cite ADR-013 instead of ADR-012 (OBS fix below).

---

### F-P72-03 (MED)

**Location:** prd-supplements/module-criticality.md (v1.2) — Module Classification table

**Description:** The PO module-criticality registry (v1.2, Classification Summary 20 = 6/8/4/2) has no D20 rows. All D20-era additions from ADR-012 Decision 4 are absent:

- `memory::write_guard` (HIGH, ferrochain-memory) — ADR-012 Decision 4 explicitly mints a NEW HIGH row for this execution module
- `mcp::server` (MEDIUM, ferrochain-mcp) — pending ADR-013; MEDIUM tier established by BC-2.09.006 architecture anchors

Gate #25 Part B/C requires the PO registry to stay in tier-agreement with the arch registry (module-criticality.md). The arch registry carries 35 modules (universe per F-P72-02 corrected); the PO registry claims 20. The D20 rows are missing from the PO registry.

**Severity:** MED — tier agreement violation for security-sensitive enforcement module.

**Fix:** Add `memory::write_guard` (HIGH) and `mcp::server` (MEDIUM) rows to PO registry; update Classification Summary arithmetic. `memory::skills` is adjudicated NO NEW ROW per ADR-012 Decision 4 §Placement Summary ("No independent execution logic beyond storage delegation").

---

### F-P72-04 (MED)

**Location:** BC-2.09.006 Architecture Anchors (v1.0, line ~145)

**Description:** Architecture Anchors cites "per ADR-012 §Consequences — 'PO Anchors' recommendation: mcp::server module in ferrochain-mcp" as the placement authority for the MCP server module. ADR-012 contains no MCP content at all; it governs SkillStore, context mutation, and write guard only (ferrochain-core / ferrochain-memory). CAP-021 / BC-2.09.006 (MCP server tool advertisement) had no governing ADR at authoring time. ADR-013 is being minted by the architect to fill this gap.

**Severity:** MED — false ADR attribution; misleads implementers about the architectural decision governing `mcp::server`.

**Fix:** BC-2.09.006 Architecture Anchors: replace "per ADR-012 §Consequences" with "per ADR-013 §Consequences" (once minted).

---

### F-P72-05 (MED)

**Location:** BC-2.10.003 (v1.2) — VP Anchors section

**Description:** The VP Anchors section lists only `VP-BUDGET-04`. The Verification Properties table (v1.2) contains three VPs: VP-BUDGET-04, VP-BUDGET-05 (Summarize path), and VP-BUDGET-06 (remaining-budget exposure). Both VP-BUDGET-05 and VP-BUDGET-06 were added in the v1.2 burst (D20 sub-burst 1) but were not added to the VP Anchors section. Per authoring guidelines, the VP Anchors section must enumerate all VP IDs that verify this contract.

**Severity:** MED — VP coverage gap; VP-INDEX and verification tools that scan VP Anchors will miss VP-BUDGET-05/06 as verifiers of BC-2.10.003.

**Fix:** Add VP-BUDGET-05 and VP-BUDGET-06 to BC-2.10.003 VP Anchors section.

---

### F-P72-06 (MED)

**Location:** interface-definitions.md §MemoryWriteRequest — `Replace` variant (v2.21 line ~396)

**Description:** The `MemoryWriteRequest::Replace` variant in interface-definitions.md uses `old_value: Value`. ADR-012 Decision 1 / Primitive C defines the type as `old_value: Option<Value>`, where `None` = unconditional replace and `Some(v)` = match-based replace (replace only if current value equals `v`). The interface-definitions.md used `Value` (non-optional), removing the unconditional replace semantics.

BC-2.15.005 PC2 lists the `Replace` shape without specifying whether `old_value` is `Value` or `Option<Value>`. The ADR-012 definition is the authoritative architectural decision; the BC does not contradict it.

**Severity:** MED — type mismatch causes semantic loss (unconditional replace is impossible with non-optional old_value).

**Fix:** Change `Replace { ..., old_value: Value, ... }` to `Replace { ..., old_value: Option<Value>, ... }` in interface-definitions.md §MemoryWriteRequest; add doc-comment explaining None = unconditional replace per ADR-012 Decision 1/Primitive C + BC-2.15.005 PC2.

---

### F-P72-07 (MED)

**Location:** error-taxonomy.md §MEMORY component — E-MEMORY-007 rationale (v1.12)

**Description:** E-MEMORY-007 (MemoryWriteGuardDenied) rationale states: "SECURITY — the guard enforces workspace security policy (sandbox escape prevention, untrusted-tool output isolation)." This is boilerplate copied from sandbox-related SECURITY codes (E-SBXD-001, E-SBXD-002 region). The actual security concern for E-MEMORY-007 is **prompt-injection in agent-controlled memory and skill writes** — role-injection prefixes (`"Human:"`, `"Assistant:"`, `"Ignore previous instructions"`) and invisible-Unicode characters (U+200B–U+200F, U+FEFF, U+202A–U+202E) that could corrupt agent memory with executable instructions. Per BC-2.15.005 EC-001–EC-002 and ADR-012 Decision 2.

"Sandbox escape prevention" and "untrusted-tool output isolation" are not the relevant threat for memory write guarding.

**Severity:** MED — incorrect rationale misleads implementers about what E-MEMORY-007 protects against; they may configure scanners targeting sandbox escape instead of prompt injection.

**Fix:** Correct E-MEMORY-007 rationale to cite prompt-injection and invisible-Unicode as the specific threat per BC-2.15.005 + ADR-012 Decision 2.

---

### F-P72-08 (MED)

**Location:** BC-INDEX (v1.1 line 112) + bc-authoring-plan Batch 6 table (v2.12 line 217)

**Description:** BC-2.10.003 H1 (v1.2, authoritative): "Graceful Halt When Budget Ceiling Reached (on_ceiling = halt | summarize); Remaining-Budget Exposure"

- **BC-INDEX title:** "Graceful Halt When Budget Ceiling Reached (on_ceiling = halt) _(v1.2: adds OnCeiling::Summarize + RunContext.budget\_info / BudgetInfo)_"
  — base title missing "`| summarize`" and "; Remaining-Budget Exposure"
- **Batch 6 table title:** "Graceful halt when budget ceiling reached (on_ceiling = halt)"
  — base title missing "`| summarize`"

Per H1 title authority (bc_h1_is_title_source_of_truth): H1 is authoritative; all downstream references must use H1 title verbatim as the base.

**Severity:** MED — title drift; INDEX enrichment appended to a stale base title rather than the current H1 base.

**Fix:** BC-INDEX: update base title to "(on_ceiling = halt \| summarize); Remaining-Budget Exposure" preserving INDEX enrichment suffix. Batch-6 table: update to "(on_ceiling = halt | summarize)".

---

## Observations (Non-Defects)

### OBS-P72-1 (stale prose — not a defect)

**Location:** bc-authoring-plan.md guideline #8 (v2.12 line 358) and Batch-13 header (line 302–305)

**Description:** Both locations reference "86 BCs" — stale since the D20 burst raised the total to 95. Also guideline #13 line ~375 references "all 86 BCs × 6 axes". These are consistency prose issues but not logic defects.

**Disposition:** OBS — fixed in same burst as F-P72-08 fixes.

---

### OBS-P72-2 (process-gap — gate #32 carrier list incomplete)

**Location:** bc-authoring-plan.md gate #32 "ADR-propagation census" (v2.12 lines ~1472–1485)

**Description:** Gate #32 "Three required carriers" does not include the module-criticality documents. When an ADR makes a crate-placement or new-module-row decision (as ADR-012 Decision 4 does), both `module-criticality.md` (arch registry) and `prd-supplements/module-criticality.md` (PO registry) must be updated to reflect the new tier assignments. The current three carriers (module-decomposition.md, BC Architecture Anchors, interface-definitions.md) do not cover this requirement, allowing the D20 module rows to remain absent from the PO registry (F-P72-03).

**Disposition:** Process-gap — fixed in same burst.

---

### OBS-P72-3 (advisory — not a defect)

**Location:** error-taxonomy.md §MEMORY component — E-MEMORY-004 row

**Description:** E-MEMORY-004 (`NoScopeContext`, VAL) message format says "memory scope resolution requires an active RunnableConfig session context; none is available." The message references `RunnableConfig` — a core framework type rather than a user-visible scope entity. For a memory scope error, implementers may find it clearer to name the missing scope context entity explicitly (e.g., "SessionContext" or "active execution context"). Advisory only — the current message is technically accurate.

**Disposition:** NOT a defect. Advisory for future message polish pass only.

---

### OBS-P72-4 (cosmetic changelog order — not a defect)

**Location:** error-taxonomy.md frontmatter changelog (v1.12)

**Description:** The changelog entries are in non-monotonic version order (v1.12 appears before v1.11 in the frontmatter list). This is cosmetic and does not affect semantics, but diverges from the descending-version ordering convention used in other supplements.

**Disposition:** NOT a defect. Cosmetic only — do not fix in this burst.

---

## Domain-D Probe

All 12 domain-D forcing functions from `domain-d-hermes-agent.md` resolve correctly:

| Forcing Function | Resolution | Status |
|-----------------|------------|--------|
| req 1 — persistent long-horizon memory (KV + vector) | BC-2.15.001–003 (CAP-017) | ✓ |
| req 2 — stop-and-summarize + budget-exposed-to-model | BC-2.10.003 v1.2 (OnCeiling::Summarize, RunContext.budget_info) | ✓ |
| req 3 — layered system-prompt composition (MEMORY.md/SOUL.md) | BC-2.15.006 (frozen-snapshot context mutation) | ✓ |
| req 4 — runtime-mutable procedural skills (SKILL.md load, route, write-back) | BC-2.15.004 (load) + BC-2.15.005 (write-back guard) | ✓ |
| req 5 — injection scanning on memory/skill writes | BC-2.15.005 (MemoryWriteGuard; E-MEMORY-007) | ✓ |
| req 6 — tool dialect seam (Hermes ChatML XML) | BC-2.08.013 (ToolCallDialect) | ✓ |
| req 7 — provider failover chain (fallback on 429/5xx/Auth) | BC-2.08.014 (ProviderFallbackPolicy) | ✓ |
| req 8 — FTS conversation search over checkpoint history | BC-2.04.008 (SQLite FTS5) | ✓ |
| req 9 — env-var sanitization at sandbox boundary | BC-2.13.007 (SandboxConfig env_allowlist) | ✓ |
| req 10 — multi-vendor provider conformance | BC-2.08.001–009 (provider conformance suite) | ✓ |
| req 11 — MCP server role (expose tools as MCP endpoint) | BC-2.09.006–007 (mcp::server) | ✓ |
| req 12 — HITL risk-tiered interrupt classification | BC-2.05.006 (typed action-risk levels) | ✓ |

No orphaned citations. All deferral notes verified.

---

## Lens Results

| Lens | Result | Notes |
|------|--------|-------|
| #16 (DI enforcement coverage) | PASS | 14/14 DIs covered |
| #30 (codeless-error census) | PASS | All constructions coded |
| #33 (taxonomy anchor reverse-verification) | FAIL (F-P72-07) | E-MEMORY-007 rationale incorrect domain |
| #13 (anchor-matrix five-way census) | PASS | |
| #22 (RetryHint divergence census) | PASS | 6 divergences + rationales |
| #26 (structurally-privileged-line canon check) | PASS | |
| Arithmetic / Classification Summary | PASS (PO registry) | FAIL only on missing D20 rows (F-P72-03) |
| Seams census (guardrail/write-guard/boundary) | PASS | |
| #31 (trait-signature type-resolution) | FAIL (F-P72-01 / F-P72-06) | SkillStore signatures wrong; Replace type wrong |
| #25 (criticality-sibling coherence) | FAIL (F-P72-03) | PO registry missing D20 rows |
| #32 (ADR-propagation census) | PARTIAL-FAIL (F-P72-04 / OBS-P72-2) | BC-2.09.006 cites ADR-012 for MCP; gate carrier list incomplete |
| Citation-audit (ADR attribution) | FAIL (F-P72-04) | ADR-012 cited for CAP-021 has no MCP content |

---

## Baseline Verified

| Metric | Value |
|--------|-------|
| Total live BCs | 95 (48 P0 / 39 P1 / 8 P2) |
| Total CAPs | 21 |
| Batches | 14 (Wave 2) + 15 (Wave 1) = completed through Batch 15 |
| BC-INDEX census by-component | 85 (per error-taxonomy.md v1.12 disposition census) |
| Blanket library-layer coverage entries | 26 |

---

## Not Reached (Pass 73 Must)

- ARCH-INDEX / L2-INDEX title sync (full sweep deferred)
- Full prd.md read (partial coverage only)
- 43/16 HTTP-split recount (interface-definitions.md split verified by census note; independent recount deferred to pass 73)

---

## Sibling Checks

| Check | Result |
|-------|--------|
| BC-INDEX count: 95 rows | PASS |
| Gate #22: RetryHint divergences 6/6 | PASS |
| Gate #28: version-changelog integrity | PASS |
| Gate #19: retired-identifier presence (0 hits) | PASS |
| Disposition census cross-check: 43+16+26=85 | PASS |
| Gate #25 Part A: PO registry arithmetic self-sum (6+8+4+2=20) | PASS (pre-D20 rows) |
| Gate #25 Part B: PO vs arch tier agreement (D20 rows) | FAIL → F-P72-03 |
| Gate #31: trait-signature type-resolution | FAIL → F-P72-01, F-P72-06 |
| Gate #32: ADR-propagation census | PARTIAL-FAIL → F-P72-04 |

---

## Proposed Decisions Log Entries

**D18-P72-A — SkillStore API is name-keyed:**
`SkillStore::load_skill` and `skill_exists` take a single `name: &str` parameter. `list_skills` takes `tags: &[String]`. The `(namespace, key)` internal addressing is implementation-private (BC-2.15.004 Invariant). Authority: BC-2.15.004 PC1–PC3 + ADR-012 Decision 1 Primitive A. Gate #31 SkillStore row is RESOLVED with corrected shapes (interface-definitions.md v2.22).

**D18-P72-B — `MemoryWriteRequest::Replace.old_value` is `Option<Value>`:**
`None` = unconditional replace (replace regardless of current value). `Some(v)` = match-based replace (only if current value equals `v`). Authority: ADR-012 Decision 1 / Primitive C. BC-2.15.005 does not contradict this — it specifies validation semantics without constraining the type. No ADR-012 amendment required; interface-definitions.md v2.22 adopts `Option<Value>` with doc-comment explaining None-semantics.

**D18-P72-C — `memory::skills` does NOT receive a module-criticality row in either registry:**
ADR-012 Decision 4 §Placement Summary: "No new row. Thin routing overlay over MemoryStore reads. Subsumed into `memory::store` note. No independent execution logic beyond storage delegation." Only `memory::write_guard` (HIGH) and `mcp::server` (MEDIUM, per ADR-013) receive new rows. PO registry updated to 22 modules (6/9/5/2) in v1.3.
