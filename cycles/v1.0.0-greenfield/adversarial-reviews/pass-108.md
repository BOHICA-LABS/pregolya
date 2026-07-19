---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T13:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 108
previous_review: pass-107.md
---

# Adversarial Review: ferrochain (Pass 108)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 107 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P107-01 | MED (PO) | RESOLVED (a,b,c,d,f PASS; census claim (e) FAILED — see F-P108-04 + F-P108-01/02/03) | Four ss-02 BC struct fixes verified PASS: (a) BC-2.02.005 v1.2 {source_node, message} ↔ `<source_node>/<message>` — 1:1; (b) BC-2.02.001 v1.2 {node_id, key} ↔ `<node_id>/<key>` — 1:1; (c) BC-2.02.002 v1.2 {channel, task_ids, step} ↔ `<channel>/<task_ids>/<n>` — step↔<n> semantic alias per bc-authoring-plan registry; (d) BC-2.02.003 v1.2 {channel, writer, step} ↔ `<channel>/<writer>/<n>` — step↔<n> semantic alias. (f) error-taxonomy v1.21 corrigendum row present at top of changelog; v1.20 row NOT rewritten; v1.21 changelog text correctly states "5 FAIL (E-MEMORY-006 fixed v1.20; E-GRAPH-011, E-GRAPH-007, E-GRAPH-001, E-GRAPH-004 fixed this burst), 17 PASS." HOWEVER: check (e) — the "17 PASS" completeness claim of v1.21 is FALSE. Independent adversary census rerun found three additional struct-field parity defects in the "17 PASS" set: E-PROV-010 (BC-2.08.014 EC-004 combined two taxonomy placeholders into one field), E-CHKPT-004 (BC-2.04.007 PC4 used different field name from PC5/EC-002/TV), E-PROV-009 (BC-2.08.013 EC-002 used catch-all that embeds mid-message offset placeholder). See F-P108-01, F-P108-02, F-P108-03. The pattern is the second consecutive burst where a sweep-completeness claim was false (v1.20 "21 PASS" was wrong; v1.21 "17 PASS" is now wrong). Root cause identified as methodological: the census verified struct-field existence but NOT constructibility — see F-P108-04. |

**Sibling-checks (burst-191 owed list):**

| Check | Result |
|-------|--------|
| (a) E-GRAPH-011 BC-2.02.005 v1.2: struct {source_node, message} 1:1 with taxonomy `<source_node>/<message>` | PASS — verified; prior `{ source: 'source_node' }` removed; changelog ascending v1.1→v1.2 |
| (b) E-GRAPH-007 BC-2.02.001 v1.2: struct {node_id, key} 1:1 with taxonomy `<node_id>/<key>` | PASS — verified; prior `{ key }` (missing node_id) corrected; changelog ascending |
| (c) E-GRAPH-001 BC-2.02.002 v1.2: struct {channel, task_ids, step} ↔ `<channel>/<task_ids>/<n>` with step↔<n> alias | PASS — step↔<n> is a documented semantic alias in bc-authoring-plan gate #33; ascending changelog |
| (d) E-GRAPH-004 BC-2.02.003 v1.2: struct {channel, writer, step} ↔ `<channel>/<writer>/<n>` with step↔<n> alias | PASS — step↔<n> alias; ascending changelog |
| (e) v1.21 census completeness "17 PASS" claim | FAILED — adversary independent census found E-PROV-010, E-CHKPT-004, E-PROV-009 as additional FAIL codes (see F-P108-01, F-P108-02, F-P108-03); v1.21 "17 PASS" = FALSE; actual: 14 PASS, 3 more FAIL |
| (f) v1.21 corrigendum row at changelog top; v1.20 row preserved (not rewritten) | PASS — corrigendum structure correct; historical record preserved |

## Part B — New Findings

### HIGH

#### F-P108-04: Struct-Placeholder Parity Census Methodology Emitted False Completeness Claims in Two Consecutive Bursts [process-gap]

- **Severity:** HIGH [process-gap]
- **Owner:** PO + orchestrator
- **Category:** process-gap (census-methodology soundness; gate #33 extension required)
- **Location:** bc-authoring-plan.md gate #33 procedure; error-taxonomy.md v1.20 and v1.21 changelog sweep entries
- **Description:** The v1.20 burst-110 sweep ("22 codes checked, 1 fixed, 21 PASS") and the v1.21 corrigendum ("22 codes checked, 5 FAIL, 17 PASS") both produced false completeness claims. The adversary's independent census at pass-108 finds three additional FAIL codes among the "17 PASS" set. This is the **second consecutive sweep that over-claimed PASS**, indicating the sweep methodology is systematically inadequate, not just a one-time miss. Root cause (structural): the v1.20 and v1.21 sweeps verified (1) that a struct-shorthand site EXISTS and (2) that the variant name MATCHES the taxonomy entry — but did NOT verify (A) intra-BC field-name consistency across sites for the same variant, and (B) that the struct field set is a SUPERSET of all distinct taxonomy placeholders with no multi-placeholder field combining two independently-positioned values. Without check (A), PC4 using `{ source: <reason> }` while PC5/EC-002/TV use `{ message: "EncryptionKeyRotationFailed: ..." }` passes undetected. Without check (B), a single `last_error: "E-PROV-008/provider-b"` combining `<last_error_code>/<last_provider>` passes undetected. The consecutive failures (v1.20, v1.21) confirm this is a methodological gap, not a one-time oversight.
- **Evidence:** v1.20 entry: "22 codes checked, 1 fixed (E-MEMORY-006), 21 PASS" — FALSE (E-GRAPH-011 was in the PASS set but contained the same defect class). v1.21 corrigendum: "22 codes checked, 5 FAIL, 17 PASS" — FALSE (E-PROV-010, E-CHKPT-004, E-PROV-009 in the PASS set fail constructibility checks). Pattern: sweep used "does struct-shorthand exist near the code?" as proxy for "is the struct correct?" — these are not equivalent.
- **Fix (completed in burst 112):** bc-authoring-plan gate #33 extended with STRUCT-PLACEHOLDER PARITY CENSUS sub-check (Steps A–C) per D18-P108-04. Step A enumerates all struct-shorthand sites via two grep commands. Step B performs three per-code checks: (1) intra-BC/corpus field-name consistency, (2) placeholder coverage (struct field set SUPERSET of all distinct taxonomy placeholders; no multi-placeholder combined field; trailing catch-all rule with documented accepted instances), (3) no-hardcode check. Step C produces a mandatory per-code TABLE — prose completeness claims alone are INVALID. bc-authoring-plan version v2.34→v2.35. total_standing_gates unchanged at 34 (sub-check extension of gate #33, not a new gate). Motivating instances (E-PROV-010, E-CHKPT-004, E-PROV-009) and catch-all rule documented inline with known semantic aliases.

### MED

#### F-P108-01: E-PROV-010 BC-2.08.014 EC-004/TV-005 Use Single `last_error` Field Combining Two Taxonomy Placeholders

- **Severity:** MED
- **Owner:** PO
- **Category:** error-taxonomy-message-format (taxonomy message ↔ BC struct-field parity; gate #33 STRUCT-PLACEHOLDER PARITY CENSUS check 2)
- **Location:** `.factory/specs/behavioral-contracts/ss-08/BC-2.08.014.md` §EC-004, §TV-005; `.factory/specs/prd-supplements/error-taxonomy.md` §PROV namespace E-PROV-010
- **Description:** The taxonomy Message Format for E-PROV-010 ProviderChainExhausted specifies: `"ProviderChainExhausted: all <N> providers in fallback chain failed; last error: <last_error_code>/<last_provider>"` — three distinct dynamic placeholders: `<N>`, `<last_error_code>`, `<last_provider>`. BC-2.08.014 EC-004 and TV-005 (before this fix) used struct `{ providers_attempted: 3, last_error: "E-PROV-008/provider-b" }` — a two-field struct where `last_error` combines both `<last_error_code>` and `<last_provider>` into a single slash-separated value. The message cannot be constructed from independent fields (e.g., log filtering by `last_provider` field is impossible; structured monitoring cannot extract `last_error_code` separately). BC-wins rule applies; the taxonomy already correctly specifies the split as two placeholders. PC5 in the same BC already used the correct form `<last_error_code>/<last_provider>` as separate placeholders in the message template — the defect was only in EC-004 and TV-005. Root cause: the v1.20 and v1.21 sweeps accepted the struct as a PASS because it had multiple fields and a variant name — neither sweep verified that EACH taxonomy placeholder mapped to an INDEPENDENT struct field.
- **Evidence:** Taxonomy Message Format: `"ProviderChainExhausted: all <N> providers in fallback chain failed; last error: <last_error_code>/<last_provider>"` — 3 placeholders. BC-2.08.014 EC-004 pre-fix: `Err(E-PROV-010 ProviderChainExhausted { providers_attempted: 3, last_error: "E-PROV-008/provider-b" })` — 2 fields; `last_error` combines placeholders 2 and 3. PC5 (same BC, correct form): `"ProviderChainExhausted: all <N> providers in fallback chain failed; last error: <last_error_code>/<last_provider>"` — consistent with taxonomy, not struct-shorthand form, not subject to parity check.
- **Fix (completed in burst 112):** BC-2.08.014 v1.1→v1.2: EC-004 expanded to `{ providers_attempted: 3, last_error_code: "E-PROV-008", last_provider: "provider-b" }` (3 independent fields matching 3 taxonomy placeholders 1:1). TV-005 correspondingly updated to full 3-field struct. Sibling sweep: PC5 uses message-template form (correctly shows `<last_error_code>/<last_provider>` as separate placeholders; not struct-shorthand, not subject to parity check). Description (prose) and TV-006 (bare form) use bare `Err(E-PROV-010 ProviderChainExhausted)` — no struct fields; not subject to check. All E-PROV-010 sites: PASS after fix. No taxonomy row change needed — taxonomy already correctly specified the split.

#### F-P108-02: E-CHKPT-004 BC-2.04.007 PC4 Uses `source` Field While PC5/EC-002/TV Use `message` Field — Intra-BC Field-Name Inconsistency

- **Severity:** MED
- **Owner:** PO
- **Category:** error-taxonomy-message-format (intra-BC field-name consistency; gate #33 STRUCT-PLACEHOLDER PARITY CENSUS check 1)
- **Location:** `.factory/specs/behavioral-contracts/ss-04/BC-2.04.007.md` §PC4, §PC5, §EC-002, §TV (key-v2 rotation row)
- **Description:** BC-2.04.007 PC4 (before this fix) used `Err(E-CHKPT-004 EncryptionKeyRotationFailed { source: <reason> })` while PC5, EC-002, and the key-v2 TV row all use `{ message: "EncryptionKeyRotationFailed: <reason>" }`. Two defects: (1) Field name inconsistency — `source` (PC4) vs `message` (PC5/EC-002/TV); the single-field struct cannot be reliably used as a pattern for all raise sites. (2) The v1.4 sweep (burst-110) fixed four message-prefix sites in this BC but missed PC4's field name, because PC4 was updated to add the "EncryptionKeyRotationFailed:" prefix but retained the pre-v1.4 `source` field name rather than renaming it to `message`. Root cause: v1.4 was a prefix-addition sweep — it transformed `{ source: <reason> }` into a prefixed-content form but did not audit intra-BC field-name parity. The v1.20 and v1.21 sweeps accepted BC-2.04.007 as PASS because a struct existed — check 1 (intra-BC consistency across ALL sites) was not run.
- **Evidence:** BC-2.04.007 PC4 pre-fix: `Err(E-CHKPT-004 EncryptionKeyRotationFailed { source: <reason> })`. PC5: `Err(E-CHKPT-004 EncryptionKeyRotationFailed { message: "EncryptionKeyRotationFailed: <reason>" })`. EC-002: `Err(E-CHKPT-004 EncryptionKeyRotationFailed { message: "EncryptionKeyRotationFailed: key not found: <key_id>" })`. TV key-v2 row: `Err(E-CHKPT-004 EncryptionKeyRotationFailed { message: "EncryptionKeyRotationFailed: key not found: key-v2" })`. Three sites use `message`; one site (PC4) uses `source` — intra-BC inconsistency.
- **Fix (completed in burst 112):** BC-2.04.007 v1.4→v1.5: PC4 now reads `{ message: "EncryptionKeyRotationFailed: <reason>" }` consistent with PC5, EC-002, and the TV row. Changelog entry cites F-P108-02 and documents the root cause (v1.4 added prefix but did not rename field). No taxonomy change — taxonomy already correctly specifies `EncryptionKeyRotationFailed: <reason>` as single-placeholder trailing form matching `{ message }`.

### LOW

#### F-P108-03: E-PROV-009 BC-2.08.013 EC-002 Catch-All `reason` Embeds Mid-Message `<n>` Offset Placeholder — Pending-Intent Adjudication Required [pending-intent]

- **Severity:** LOW [pending-intent]
- **Owner:** PO
- **Category:** error-taxonomy-message-format (placeholder coverage; gate #33 STRUCT-PLACEHOLDER PARITY CENSUS check 2; catch-all rule adjudication)
- **Location:** `.factory/specs/behavioral-contracts/ss-08/BC-2.08.013.md` §EC-002
- **Description:** The taxonomy Message Format for E-PROV-009 ToolCallDialectParseError specifies four distinct placeholders: `<dialect>`, `<element>`, `<n>`, `<parse_error>`. The message form is `"ToolCallDialectParseError: <dialect> <element> payload is not valid JSON at response offset <n>: <parse_error>"` — where `<n>` is the response offset, positioned mid-message between `<element>` and `<parse_error>`. BC-2.08.013 EC-002 (before this fix) used struct `{ dialect: "HermesChatMlXml", reason: "JSON parse error at offset N: key must be a string" }` — a two-field struct where `reason` embeds both `<n>` and `<parse_error>` inline. This finding is LOW [pending-intent] because: (1) the `reason` catch-all pattern is not inherently wrong; (2) the question is whether the catch-all rule permits this case; and (3) the adjudication depends on bc-authoring-plan gate #33 catch-all rule which was not fully codified at v1.21 time. Adjudication decision (per product-owner in burst 112): catch-all `reason` is NOT acceptable here because `<n>` is a MID-message placeholder (not trailing), meaning the full 4-placeholder message `"at response offset <n>: <parse_error>"` cannot be rendered with independent N and parse_error values from a single `reason` field. The catch-all rule allows trailing-position catch-all only when all preceding placeholders have dedicated fields; E-PROV-009 has `<n>` preceding `<parse_error>` — the `reason` field embeds both.
- **Evidence:** Taxonomy: four placeholders (`<dialect>`, `<element>`, `<n>`, `<parse_error>`); `<n>` is between `<element>` and `<parse_error>` in the message. BC-2.08.013 EC-002 pre-fix: `Err(E-PROV-009 ToolCallDialectParseError { dialect: "HermesChatMlXml", reason: "JSON parse error at offset N: key must be a string" })` — two fields; `reason` embeds mid-message offset. BC-authoring-plan accepted trailing catch-all examples: E-CHKPT-003 `{ thread_id, checkpoint_id, reason }`, E-MCP-005 `{ transport, reason }`, E-SBXD-003 `{ reason }` — all have `reason` at TRAILING position. E-PROV-009 `<n>` is not trailing.
- **Fix (completed in burst 112):** BC-2.08.013 v1.1→v1.2: EC-002 expanded from `{ dialect, reason }` to `{ dialect: "HermesChatMlXml", element: "<tool_call>", offset: 2, parse_error: "key must be a string" }` — 4-field struct matching all 4 taxonomy placeholders (with `offset` used for `<n>` — offset is the more meaningful name for a response position; this is not a semantic alias per the bc-authoring-plan list but is semantically equivalent: offset = position = <n> in this context; documented in changelog). Sibling sweep: PC8 uses message-template form (correctly shows 4 values inline; not struct-shorthand; not subject to parity check). PC9, EC-005, TV-006 use bare `Err(E-PROV-009 ToolCallDialectParseError)` — no struct fields; not subject to check. No taxonomy change needed.

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 1 |
| MED | 2 |
| LOW | 1 |
| **Total findings** | **4** |
| OBS / process-gap | 0 (F-P108-04 is HIGH, not OBS) |

**CLEAN (strict):** no (1H + 2M + 1L)
**CLEAN (PR-merge):** no (1H + 2M present)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** MEDIUM (meta-insight: the census methodology itself was unsound — existence-checking is insufficient for constructibility; two consecutive false PASS claims indicate systematic gap; codification into gate #33 Step A–C procedure addresses root cause)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 108 |
| **New findings** | 1H + 2M + 1L (F-P108-04 HIGH, F-P108-01 MED, F-P108-02 MED, F-P108-03 LOW) |
| **Duplicate/variant findings** | F-P108-01/02/03 are the same DEFECT CLASS as OBS-P106-A/F-P107-01; novel angle is the METHODOLOGICAL root cause (F-P108-04) |
| **Novelty score** | MEDIUM (individual defects are class-recurrence; F-P108-04 is the novel meta-finding — census methodology insufficient; two consecutive false claims establish systematic gap vs one-time miss) |
| **Median severity** | MED |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4 |
| **CLEAN (strict)** | no (1H + 2M + 1L) |
| **CLEAN (PR-merge)** | no (1H + 2M present) |
| **Verdict** | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
