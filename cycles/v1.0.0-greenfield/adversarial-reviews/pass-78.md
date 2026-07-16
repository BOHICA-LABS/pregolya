---
document_type: adversarial-review
pass: 78
phase: 1d
verdict: NOT_CLEAN
finding_count: 4
finding_severity: [MED, MED, LOW-MED, MED]
novelty: MEDIUM
novelty_class: gate33-first-run-message-and-anchor-drift
sibling_checks: "6/6 PASS (where intersected)"
timestamp: 2026-07-15T00:00:00Z
---

# Adversarial Review — Pass 78 (Phase 1d)

**Verdict:** NOT CLEAN — 4 findings (MED, MED, LOW-MED, MED). All FIXED same burst.

---

## Findings

### F-P78-01 (MED) — E-MEMORY-007 taxonomy message format vs BC-2.15.005 PC2

**File:** `specs/prd-supplements/error-taxonomy.md`

E-MEMORY-007 "Memory Write Blocked: Injection Detected" taxonomy Message Format carried an extra `<operation>` placeholder and had wrong word order / separator compared to the authoritative anchor BC-2.15.005 PC2 (security code, prompt-injection guard). BC wins on any divergence per gate #33 semantic-agreement rule (D18-P77-B). Taxonomy Message Format reconciled to verbatim BC-2.15.005 PC2 text.

**Resolution:** taxonomy v1.16 Message Format corrected to match BC-2.15.005 PC2 verbatim. BC unchanged.

---

### F-P78-02 (MED) — E-PROV-010 omission note cited no-error path (BC-2.08.014 PC4/EC-002)

**File:** `specs/prd-supplements/interface-definitions.md`

interface-definitions E-PROV-010 omission note cited BC-2.08.014 "PC4/EC-002". Both are no-error paths: PC4 = ordered-chain success, EC-002 = SUCCESS. The code is raised by PC5 (provider tool error) and EC-004 (TOOL_ERROR) — the actual raising path. This is a success-path citation, which gate #33 step 11 (added this burst, OBS-P78-E/D18-P78-B) identifies as a violation.

**Resolution:** interface-definitions v2.25 omission-note citation corrected: BC-2.08.014 PC5/EC-004.

---

### F-P78-03 (LOW-MED) — E-PROV-009 omission note cited success-parse path (BC-2.08.013 PC4)

**File:** `specs/prd-supplements/interface-definitions.md`

E-PROV-009 omission note cited BC-2.08.013 PC4 (success-parse). The code is raised by PC8 (stream parse failure), PC9 (empty stream), and EC-002 (STREAM_PARSE_ERROR). Same success-path citation class as F-P78-02.

**Resolution:** interface-definitions v2.25 citation corrected: BC-2.08.013 PC8/PC9/EC-002.

---

### F-P78-04 (MED, adjudicated D18-P78-A) — BC-2.04.008 PC6 message lacked `FtsLimitZero:` prefix

**File:** `specs/behavioral-contracts/ss-04/BC-2.04.008.md`

BC-2.04.008 PC6 error message did not carry the `FtsLimitZero:` prefix. Universal `<ErrorName>: <detail>` message-prefix convention (D18-P78-A) requires the BC message body to include the prefix — this is the canonical direction of correction (BC-side, not taxonomy-side) whenever a BC message lacks the standardized prefix. Gate #33 semantic sweep confirmed this instance; 11 additional BCs were corrected in the same sweep for the same class (prefix additions).

**Resolution:** BC-2.04.008 v1.3 PC6 message updated with `FtsLimitZero:` prefix per D18-P78-A.

---

## Process Gap

### OBS-P78-E — Gate #33 lacked omission-note anchor-citation check (CLOSED D18-P78-B)

Gate #33 had no step verifying that interface-definitions omission-note BC-anchor citations resolve to a PC/EC that actually raises the code. F-P78-02 and F-P78-03 were copy-paste success-path citations that survived all prior passes. Gate #33 step 11 added (bc-authoring-plan v2.18): every interface-definitions omission-note BC-anchor citation must resolve to a raising PC/EC; success-path citation is a violation. Gate count stays 33 (step added to existing gate #33).

---

## Full Gate #33 Semantic Sweep — First Complete Run (85/85 codes, PO-executed same burst)

**Scope:** all 85 live error codes (census 85 = 43 CORE+SERVER+MCP+SBXD + 16 CHKPT + 26 PROV+BUDGET+MEMORY).

**Results:**
- **68 MATCH** — taxonomy Message Format + raise-condition annotation agree with anchor BC message text + EC/TV predicates verbatim.
- **11 BC-side prefix additions** (D18-P78-A: `<ErrorName>: <detail>` convention): E-CORE-006, E-CHKPT-002, E-CHKPT-004, E-CHKPT-007, E-SERVER-007, E-PROV-002 [also added missing `code:` field], E-PROV-004, E-PROV-005, E-PROV-007, E-PROV-008, E-BUDGET-001. Taxonomy content reconciled BC-wins where applicable.
- **2 taxonomy-only message structure fixes** — E-PROV-009 and E-PROV-010 (message reworded to match BC + omission-note citations corrected per F-P78-02/03).
- **2 citation-only fixes** — F-P78-02 (E-PROV-010 → PC5/EC-004) + F-P78-03 (E-PROV-009 → PC8/PC9/EC-002).
- **Zero codes unswept.**

**8 BC files bumped (prefix additions):**
- BC-2.01.003 v1.3 (E-CORE-006)
- BC-2.04.003 v1.2 (E-BUDGET-001)
- BC-2.04.007 v1.4 (E-PROV-002/004/005/007/008)
- BC-2.08.003 v1.3 (E-CHKPT-002/004/007)
- BC-2.08.004 v1.3 (E-SERVER-007)
- BC-2.08.007 v1.2 (E-PROV-009/010 message structure — taxonomy-side only; BC unchanged except citation row)
- BC-2.10.003 v1.4 (E-CHKPT-007 additional instance)
- BC-2.12.001 v1.3 (E-PROV-005 additional instance)

**Supplement versions:** error-taxonomy → v1.16 (13 Message Format corrections total); interface-definitions → v2.25 (citation fixes + E-CORE-006 dual-layer table prefix + `<depth>` field note); bc-authoring-plan → v2.18 (gate #33 step 11).

---

## Adversary Clean Verifications

- **Census 85 = 43 + 16 + 26** confirmed per namespace enumeration.
- **RetryHint divergence set = 6 verbatim** (unchanged; gate #22 stable).
- **E-SBXD-006 wildcard model** verbatim match confirmed (F-P77-01 propagated; taxonomy v1.14→v1.16 preserves fix).
- **E-MCP-005 + E-CHKPT-009 messages** verbatim match to respective anchor BCs.
- **BC-2.09.006** McpServerTransport/start/Handle + ADR-013 cite confirmed.
- **Sibling-checks 1–6 PASS** (where documents were read):
  1. taxonomy v1.16 E-SBXD-006 wildcard model matches BC-2.13.007 PC5/EC/TV verbatim.
  2. ADR-013 v1.1 McpServerTransport/start/McpServerHandle/Sse{bind_addr} + authority note present.
  3. ADR-012 v1.2 INV-1 — zero "ADR-012 DI-001" residue (changelog rows exempt).
  4. BC-2.08.013 v1.1 "trait implementations" language intact.
  5. BC-2.15.006 v1.1 + capabilities-p1-p2 v1.2 INV-1 propagated.
  6. bc-authoring-plan v2.18 gate #33 steps 7–11 present; 33 gates unchanged.

---

## Novelty Assessment

**MEDIUM.** Gate #33 semantic-agreement axis (D18-P77-B) is new but the findings are structural drift detected on first sweep — expected initial-run residue. OBS-P78-E (omission-note citation class) is a new sub-class discovery. Prefix-canon D18-P78-A codifies a previously implicit convention.

**Trajectory:** →4 (P1D-78). **Convergence counter:** 0/3 (reset by pass 78 findings).
