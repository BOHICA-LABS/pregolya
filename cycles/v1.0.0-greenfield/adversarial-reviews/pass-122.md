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
pass: 122
previous_review: pass-121.md
---

# Adversarial Review: ferrochain (Pass 122)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 121 produced three findings:
- F-P121-01: ContentBlock L2 depictions drifted — entities-graph.md + ubiquitous-language-core.md depict ~5-variant form vs BC-2.01.001 PC2 canonical 14; ToolCall fields wrong (JSON-RPC form); ToolResult classified as ContentBlock arm; NonStandard/DI-008 absent
- F-P121-02: L2 Message role enum closed 4-role {Human,AI,System,Tool} in both entities-graph + ubiquitous-language-core vs BC-2.01.002 PC7/EC-005 requiring Function/Chat/Remove
- OBS [process-gap]: per-token sweeps leave systemic L2-vs-BC type drift; mandated one-time comprehensive L2-vs-BC type audit (37-row) as class-closure deliverable

Fix burst 124 was dispatched (7 L2 shards + ADR-001 review; 37-row type audit as OBS class-closure deliverable). Verification follows.

### F-P121-01 / F-P121-02 Verification — CLOSED (7-Shard Scope)

**PASS-122 sibling-checks verification (checks a–e from PASS-122 SIBLING-CHECKS):**

| Check | Result |
|-------|--------|
| (a) ContentBlock 14-variant canon at entities-graph v1.2 + ubiquitous-language-core v1.2 — zero ToolUse/ImageUrl/Document/ContentBlock::ToolResult-as-arm live residue; ToolCall fields id/name/input_schema/description per BC-2.01.001; NonStandard/DI-008 present | PASS — entities-graph v1.2 carries 14-variant ContentBlock; ToolCall fields match BC-2.01.001 PC2; ToolResult re-classified as ToolMessage payload; DI-008/NonStandard present; ubiquitous-language-core v1.2 mirrors same |
| (b) Message 4-primary+3-extension variants (Function/Chat/Remove) at both entities-graph v1.2 + ubiquitous-language-core v1.2 | PASS — Message role set extended to 4-primary+Function/Chat/Remove in both shards; closed 4-role enum form absent |
| (c) CAP-007 12-variant StreamEvent in capabilities-p0 v1.4 — guardrail_decision present (Fail/Transform only, metadata payload per D18-P99-A) | PASS — CAP-007 now lists 12 StreamEvent variants; guardrail_decision variant present with Fail/Transform-only emission semantics; metadata fields correct per D18-P99-A |
| (d) Spot-verify 6 rows of the 37-row audit table (rows 1/7/12/19/26/37 representative sample) | PASS — Row 1 (entities-graph ContentBlock variant count): L2 now 14-variant, MATCH. Row 7 (ubiquitous-language-core ContentBlock): 14-variant glossary present, MATCH. Row 12 (bounded-contexts MCP seam ToolResult): ToolMessage seam correct, MATCH. Row 19 (entities-graph RunStatus enum): 4-terminal set present, MATCH. Row 26 (capabilities-p0 CheckpointSaver operations list): get_next_version exclusion correct per pass-116 adjudication, MATCH. Row 37 (invariants.md checkpoint invariants): stateless ZST get_next_version per burst 201, MATCH. Note: audit rows 2/8/22/34 contain errors — see F-P122-02/03 and OBS-P122-b in Part B. |
| (e) get_next_version L2-exclusion axis settled per pass-116 adjudication — pure computed helper, not persistence op; do NOT re-flag | PASS — get_next_version correctly excluded from persistence-op list in capabilities-p0 v1.4; no L2 edit needed; axis settled |

**ADR-001 review:** Reviewed clean — no structural gaps or contradictions with current spec corpus.

**F-P121-01 conclusion:** CLOSED for the 7-shard L2 fix scope — entities-graph v1.2 and ubiquitous-language-core v1.2 both correctly depict ContentBlock 14-variant form with correct ToolCall fields; ToolResult absent as ContentBlock arm; DI-008/NonStandard present. Part B identifies three residue sites at corpus locations outside the L2 audit scope (capabilities-p0 CAP-001, bounded-contexts Splitters seam, BC-2.11.002 image_url) — these constitute new finding F-P122-01.

**F-P121-02 conclusion:** CLOSED — Message role set extended to 4-primary+Function/Chat/Remove at both checked sites; closed 4-role enum form absent.

**OBS class-closure deliverable:** 37-row audit published in burst-206. Class considered converged for the L2 domain-spec scope. Part B (OBS-P122-a) identifies that the audit scope was structurally L2-only and missed the BC layer and capability enumerations, explaining why F-P122-01 residue persisted.

---

## Part B — New Findings

### F-P122-01 — HIGH: ContentBlock Drifted-Vocabulary Residue at 3 Corpus Sites Outside L2 Audit Scope

**Severity:** HIGH
**Scope:** `specs/domain-spec/capabilities-p0.md:42` (CAP-001); `specs/domain-spec/bounded-contexts.md:138` (Splitters seam); `specs/behavioral-contracts/ss-11/BC-2.11.002.md:105-106` (EC-002/EC-003)

#### Evidence

The burst-124 fix + 37-row type audit established ContentBlock 14-variant canon in the L2 domain-spec shards and declared "class CONVERGED." Pass 122 extends the search beyond the L2 domain-spec corpus to capability enumerations and the BC layer, finding vocabulary drift at three sites.

**Site 1 — capabilities-p0.md:42, CAP-001:**

CAP-001 enumerates ContentBlock variant handling at the graph API surface. At line 42, CAP-001 references ContentBlock with an incomplete variant list that does not match BC-2.01.001 PC2 canonical 14-variant form. The burst-124 audit covered only CAP-007 (rows 15/16), not CAP-001. CAP-001's ContentBlock reference was structurally outside the L2 audit scope and carried pre-fix vocabulary forward.

| Axis | Canon (BC-2.01.001 PC2) | Residue at CAP-001 | Violation |
|------|--------------------------|--------------------|-----------|
| ContentBlock variant enumeration | 14 variants + ToolMessage note | Incomplete variant list; ToolMessage distinction absent | VOCABULARY DRIFT |

**Site 2 — bounded-contexts.md:138, Splitters seam:**

The Splitters seam section at line 138 depicts the text-crossing type as `String` (singular) and references "Document variant" — both pre-fix vocabulary. BC-2.07.001/002/003 establishes that the Splitters seam uses `Vec<String>` (the splitter output is a sequence of chunks), not a single `String`. The "Document variant" reference is a ContentBlock phantom — `Document` was never in the canonical 14-variant form under that name. ContentBlock wrapping is caller responsibility, not Splitters output contract.

| Axis | Canon (BC-2.07.001/002/003) | Residue at bounded-contexts:138 | Violation |
|------|-----------------------------|----------------------------------|-----------|
| Splitters seam output type | Vec\<String\> | String (singular) | TYPE DRIFT |
| ContentBlock "Document variant" reference | No Document variant in canonical 14 | "Document variant" cited | PHANTOM VARIANT |

**Site 3 — BC-2.11.002:105-106, EC-002/EC-003:**

BC-2.11.002 EC-002 and EC-003 describe exception conditions using `image_url` vocabulary at lines 105-106. BC-2.01.001 PC2 establishes that the canonical ContentBlock variant name is `ContentBlock::Image` (not `image_url`). The `image_url` form is pre-canonical vocabulary that was retired when the 14-variant hardening settled the type names.

| Axis | Canon (BC-2.01.001 PC2) | Residue at BC-2.11.002:105-106 | Violation |
|------|--------------------------|--------------------------------|-----------|
| Image content variant name | ContentBlock::Image | image_url | NAME DRIFT |

**Impact on burst-124 convergence claim:** The burst-124 37-row audit declared "OBS process-gap class CONVERGED: comprehensive audit complete, all rows MATCH after fix burst 124." This claim is falsified — three corpus sites retained pre-fix ContentBlock vocabulary. The audit was L2-domain-spec-only and structurally excluded the BC layer (ss-01..ss-17) and the capability spec non-CAP-007 sections. See OBS-P122-a for the structural scope limitation.

---

### F-P122-02 — MED: Burst-206 Audit Table Rows 2/8 — Wrong ToolCall Canon and Phantom §ToolUse Cite

**Severity:** MED
**Scope:** `cycles/v1.0.0-greenfield/burst-log.md` — burst-206 audit table rows 2 and 8

#### Evidence

The burst-206 37-row audit table rows 2 and 8 (both labeled "§ContentBlock ToolCall fields") contain two errors:

**Error 1 — Wrong canon column value:**

| Row | Canon Column (actual) | Correct Canon |
|-----|----------------------|---------------|
| Row 2 | `id/name/input_schema/description` | `{id, name, args}` per BC-2.08.002 TV-001/TV-003 |
| Row 8 | `id/name/input_schema/description` | `{id, name, args}` per BC-2.08.002 TV-001/TV-003 |

The value `id/name/input_schema/description` is the Tool definition schema (the schema-specification fields of a tool registered with the LLM), not the ToolCall runtime schema. A ToolCall is the invocation record produced when the LLM decides to call a tool; its canonical fields per BC-2.08.002 TV-001/TV-003 are `{id, name, args}`. Rows 2 and 8 conflated Tool definition schema with ToolCall invocation schema.

**Error 2 — Phantom section anchor:**

The BC Authority column for rows 2 and 8 cites `BC-2.01.001 PC2 §ToolUse`. No section named `§ToolUse` exists in BC-2.01.001 PC2. BC-2.01.001 PC2 defines the ContentBlock tagged-union at the discriminated-union level; individual variant fields are not organized under named sections. The `§ToolUse` cite is phantom.

**Correct authority:** BC-2.08.002 TV-001 and TV-003 define ToolCall as `{id: String, name: String, args: Value}`.

**Impact:** The audit table rows 2 and 8 claimed to verify ToolCall field correctness but cited the wrong schema. The actual fix in entities-graph v1.2 and ubiquitous-language-core v1.2 correctly set ToolUse ContentBlock variant fields to `{id, name, input_schema, description}` per BC-2.01.001 PC2 — but the audit table attributed those fields to ToolCall rather than ContentBlock::ToolUse, creating vocabulary confusion. The burst-log corrigendum must correct rows 2 and 8.

---

### F-P122-03 — MED: Burst-206 Audit Table Row 34 — Phantom edge-cases.md §BudgetPolicy OnCeiling Section

**Severity:** MED
**Scope:** `cycles/v1.0.0-greenfield/burst-log.md` — burst-206 audit table row 34

#### Evidence

Burst-206 audit table row 34:

| Row | L2 Shard | Section / Type | Status |
|-----|----------|---------------|--------|
| 34 | edge-cases.md | §BudgetPolicy OnCeiling decision table | MATCH |

`edge-cases.md` contains no `§BudgetPolicy` section and no OnCeiling decision table. The OnCeiling decision table lives at `entities-server.md:98 §BudgetConfig`, established by D18-P91-A ("`on_ceiling` canon: BudgetConfig struct (GraphConfig.budget_config) owns on_ceiling/soft_limit/hard_limit; … OnCeiling + BudgetConfig now defined in interface-definitions §BudgetPolicy").

Row 34 audited a phantom section and produced a spurious `MATCH` verdict. The actual OnCeiling table at `entities-server.md:98 §BudgetConfig` was not audited by this row. The burst-log corrigendum must correct row 34 to point at the correct shard and section.

**MATCH verdict on corrected attribution:** The OnCeiling decision table at `entities-server.md:98 §BudgetConfig` (correct location) is correctly structured per D18-P91-A (Halt/Escalate/Summarize 3-way branch). The MATCH verdict is retained; only the shard/section citation is wrong.

---

### OBS-P122-a — Process-Gap: L2-Audit Scope Structurally Excluded BC Layer and Capability Enumerations

**Severity:** OBS [process-gap]
**Scope:** Phase 1d adversarial review methodology; burst-124 audit scope definition

#### Observation

The burst-124 37-row type audit was explicitly scoped to the L2 domain-spec shards (entities-*, ubiquitous-language-*, events, bounded-contexts, edge-cases, capabilities-p0). The BC layer (ss-01..ss-17) and capability spec sections outside CAP-007 were structurally absent from the audit design. F-P122-01 demonstrates that vocabulary drift can exist simultaneously:
- In L2 capability enumerations (capabilities-p0 CAP-001) that reference BC-defined types
- In BC files themselves (BC-2.11.002) where EC/TV descriptions use pre-canonical type vocabulary

The burst-124 "class CONVERGED" claim was therefore premature for the corpus as a whole — it was accurate for the L2 domain-spec layer but not for the full spec corpus. ContentBlock vocabulary can drift in any artifact that cites or references ContentBlock variants, not only in L2 entity definitions.

**Mandate for future class-closure deliverables:** A "class CONVERGED" designation for a vocabulary type requires a corpus-wide token grep (not L2-scoped) covering: L2 domain-spec shards, capabilities spec, BC layer (all ss-XX files), supplements (interface-definitions, error-taxonomy, test-vectors). The canonical token-set for ContentBlock includes: `ToolUse`, `ImageUrl`, `Document` (variant names), `ContentBlock::ToolResult` (as a ContentBlock arm), and `image_url` (legacy name). The fix-burst 125 corpus-wide census is the correct pattern.

---

### OBS-P122-b — Audit Table Row 22: Misdescribed L2 CheckpointSaver Operations

**Severity:** OBS
**Scope:** `cycles/v1.0.0-greenfield/burst-log.md` — burst-206 audit table row 22

#### Observation

Burst-206 audit table row 22:

| Row | Section / Type | L2 Pre-Fix Depiction | Canon |
|-----|---------------|----------------------|-------|
| 22 | §CheckpointSaver methods | put/get/list/put_writes/get_next_version | 5-method trait |

The L2 Pre-Fix Depiction column states `put/get/list/put_writes/get_next_version`. The actual L2 CheckpointSaver operations per entities-graph.md §CheckpointSaver are `{get_tuple, put_writes, put, list}` (4 ops; `get_next_version` excluded per pass-116 adjudication as a pure computed helper). The operation `get` does not appear under that name in the L2 shard; the correct read operation is `get_tuple`. The pre-fix description column was populated from memory rather than read from the L2 source, resulting in a fabricated operation name.

**Impact:** Row 22's MATCH verdict remains correct — the L2 CheckpointSaver operations are aligned with the BC-2.04.003 canonical form. The error is in the Pre-Fix Depiction column (incorrect operation name `get` vs actual `get_tuple`) and does not affect the status verdict. The burst-log corrigendum should note this inaccuracy.

---

## Carry-Forward Axes — No Findings

The following axes were swept in pass 122 and produced no findings. They are carried forward into pass-123 sibling-checks for fresh-context confirmation:

- **ADR-008/ADR-010/ADR-011 soundness:** Reviewed — no gaps or contradictions with current spec corpus.
- **ss-09 §Tool / §McpServer:** BC-2.09.* Tool and MCP server contract sections reviewed — no ContentBlock vocabulary drift; seam types correct.
- **ss-14 ↔ nfr-catalog:** BC-2.14.* performance / reliability contracts reviewed against nfr-catalog.md — no misalignment found.
- **ss-15 ↔ §MemoryStore:** BC-2.15.* memory store contracts reviewed against entities-server §MemoryStore — no type drift.
- **ss-06 ordering ↔ BC-2.12.007:** Run ordering invariant in ss-06 reviewed against BC-2.12.007 — consistent.

---

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 1 (F-P122-01: ContentBlock drifted-vocabulary residue at 3 sites outside L2 audit scope — capabilities-p0:42 CAP-001; bounded-contexts:138 Splitters seam String→Vec\<String\> + phantom Document variant; BC-2.11.002:105-106 image_url vs ContentBlock::Image; burst-124 class-CONVERGED claim falsified) |
| MED | 2 (F-P122-02: burst-206 audit rows 2/8 — wrong ToolCall canon {id,name,args} per BC-2.08.002, not {id,name,input_schema,description}; phantom §ToolUse cite. F-P122-03: burst-206 audit row 34 phantom — edge-cases.md has no OnCeiling section; actual table at entities-server:98 §BudgetConfig) |
| LOW | 0 |
| OBS | 2 (OBS-P122-a [process-gap]: burst-124 audit scope L2-only; BC layer + capability enumerations structurally missed; class-CONVERGED criteria requires corpus-wide token grep. OBS-P122-b: audit row 22 pre-fix depiction fabricated — "get" should be "get_tuple"; MATCH verdict retained) |
| **Total findings** | **5** |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — iterate
**Readiness:** requires revision

**CLEAN (strict):** no (1 HIGH + 2 MED + 2 OBS; strict-zero requires ZERO findings of any severity)
**CLEAN (PR-merge):** no (1 HIGH + 2 MED findings present)

**Convergence counter:** 0/3 (counter unchanged — pass 122 NOT CLEAN strict; fix burst 125 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** HIGH (new finding class: self-certifying class-closure deliverables asserting convergence against phantom canon — the burst-124 "class CONVERGED" designation was built on an L2-scoped audit that structurally excluded the BC layer and capability enumerations; the audit table itself contained phantom section cites and wrong canonical field names, which a fresh-context adversary is uniquely positioned to catch; this class of defect — convergence assertions with under-scoped evidence — has not appeared in prior Phase 1d passes)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 122 |
| **New findings** | 5 (F-P122-01 HIGH, F-P122-02 MED, F-P122-03 MED, OBS-P122-a [process-gap], OBS-P122-b) |
| **Cleared axes** | F-P121-01 CLOSED (7-shard L2 sites correct); F-P121-02 CLOSED (Message 4+3 role set correct at L2 sites); OBS class-closure deliverable published (L2 scope) |
| **Novelty score** | HIGH — first detection of self-certifying convergence claim with under-scoped evidence; audit table phantom cites (§ToolUse, edge-cases.md §BudgetPolicy) and field-name conflation (Tool schema vs ToolCall schema) are new defect classes; fresh-context adversary is the necessary check on prior-pass audit claims |
| **Median severity** | MED (1H + 2M dominant; OBS non-blocking) |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1→1→3→1→1→3→5 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (1H/2M/2OBS; counter 0/3 unchanged; fix burst 125 dispatched; NEXT: pass 123 on new HEAD after fix burst 125) |
