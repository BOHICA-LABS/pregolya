---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T10:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 106
previous_review: pass-105.md
---

# Adversarial Review: ferrochain (Pass 106)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 105 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P105-01 | MED (PO) | RESOLVED | error-taxonomy.md v1.19 SECURITY description rewritten to "Workspace/sandbox escape; approver-role authorization failure; agent-memory write injection prevention." Verified: (1) all 3 SECURITY members spanned — E-SBXD-001 WorkspaceEscape, E-GRAPH-013 InsufficientApproverRole, E-MEMORY-007 MemoryWriteGuardDenied; (2) zero live residue of "sandbox policy enforcement" phrase; (3) v1.19 changelog conventions PASS (descending, timestamp-current at 2026-07-18). |
| OBS-P105-A | OBS (PO+orchestrator) | RESOLVED | SECURITY vs POLICY authorization-failure categorization rule documented as blockquote note after Error Categories table. Adversary verified: (a) E-GRAPH-013 SECURITY justified — HITL approval gate; bypass enables harmful high-risk action approval per BC-2.05.006; (b) E-MEMORY-003 POLICY justified — cross-scope memory isolation constraint per BC-2.15.002; (c) E-MEMORY-006 POLICY justified — admin-only GDPR erasure capability constraint per BC-2.15.003. Decision heuristic coherent: "attack vector → SECURITY; privileged operation for legitimate caller → POLICY." Rule text present and unambiguous. |
| OBS-P105-B | OBS [process-gap] (PO+orchestrator) | PARTIALLY RESOLVED → F-P106-01 | MANDATORY PRE-EMISSION CHECK block inserted at gate #28 with per-step Form A + Form B checks (bc-authoring-plan v2.33). Verified: (a) block is present and non-optional ("Before emitting ANY..."); (b) Form A check and Form B check both explicit; (c) "finding is INVALID" gate labeled per form. Known Form-B-only files list verified for the 6 entries present: BC-2.07.002, BC-2.08.011, BC-2.08.012 (BCs); bc-authoring-plan.md, test-vectors.md, verification-architecture.md (supplements). PARTIAL: `BC-INDEX.md` is absent from the list (see F-P106-01). |

**Sibling-checks (burst-189 owed list):**

| Check | Result |
|-------|--------|
| (a) SECURITY description spans 3 members (E-SBXD-001, E-GRAPH-013, E-MEMORY-007) | PASS — description confirmed: "Workspace/sandbox escape; approver-role authorization failure; agent-memory write injection prevention" — all three members present |
| (b) Zero live "sandbox policy enforcement" residue | PASS — phrase absent from error-taxonomy.md v1.19 under SECURITY row; OBS-P105-A blockquote does not reintroduce it |
| (c) SECURITY/POLICY rule blockquote coherent with anchor BCs BC-2.05.006/BC-2.15.002/BC-2.15.003 | PASS — blockquote cites all three anchor BCs; heuristic description matches each code's categorization rationale |
| (d) Gate #28 MANDATORY PRE-EMISSION CHECK present in bc-authoring-plan v2.33 | PASS (with F-P106-01 scope note) — block present; 6 of 7 Form-B-only files listed; BC-INDEX.md omitted → F-P106-01 |
| (e) Four broadened descriptions (TIMEOUT/TRANSPORT/DURABILITY/CONCURRENCY) span full membership | PASS — verified all four descriptions against member sets; TIMEOUT adds E-SERVER-016; TRANSPORT adds E-PROV-008/E-MCP-005; DURABILITY adds E-MEMORY-002/005/008/E-SERVER-014/E-BUDGET-002; CONCURRENCY adds E-SERVER-007/012/015; no contradiction introduced |
| (f) error-taxonomy.md v1.19 changelog row descending order and timestamp-current | PASS — v1.19 at top; descending to v1.1; timestamp 2026-07-18 = newest entry date |

**Additional verification axes (independent probes, this pass):**

| Axis | Check | Result |
|------|-------|--------|
| 12/12 category descriptions | All 12 Error Categories table descriptions verified to span full category membership without contradiction | PASS — VAL/AUTH/RATE/TIMEOUT/TRANSPORT/INTERNAL/DURABILITY/POLICY/TOOL/CONCURRENCY/SECURITY/TENANCY — each description accurately characterizes member set; no omission gaps found across the 12 rows |
| Test-vectors census 504+9=513 | Per-SS sums: SS-01 (5+2=7) + SS-02 (4+1=5) + SS-03 (3) + SS-04 (7+1=8) + SS-05 (6+1=7) + SS-06 (3) + SS-07 (3) + SS-08 (9+2=11) + SS-09 (5) + SS-10 (4) + SS-11 (6) + SS-12 (7+2=9) + SS-13 (6) + SS-14 (6) + SS-15 (6+1=7) + SS-16 (3) + SS-17 (2+1=3); sum = 504+9 appended = 513 total test vectors | PASS — per-SS sums verified; 504 base + 9 D20-appended = 513 total; no drift |
| StreamEvent 12-variant coherence | All 12 StreamEvent variants (RunStart/RunEnd/NodeStart/NodeEnd/ToolStart/ToolEnd/StepStart/StepEnd/RunStreamChunk/NodeStreamChunk/ToolStreamChunk/GuardrailDecision) verified against SS-06 + D18-P99-A + SS-11 surface | PASS — GuardrailDecision as 12th variant confirmed (D18-P99-A); unary/streaming observability equivalence preserved per DI-011 |
| Gate #33 E-CHKPT-002 spot | E-CHKPT-002 `MonotonicClockRegression: checkpoint_id must be monotonic: random UUID rejected` → BC-2.04.003 EC-003 anchor verified for semantic agreement (UUID rejection vs monotonic regression) | PASS — F-P78-SWEEP correction verified; message matches BC-2.04.003 semantic; no regression |
| Burst-189 hash refreshes | 3 BC hashes refreshed (BC-2.14.001, BC-2.14.002, BC-2.07.001) per D18-P89-A; requires shell access to verify | UNVERIFIABLE (adversary read-only profile) — mechanical, sanctioned; consistent with D18-P89-A standing sweep protocol |

## Part B — New Findings

### MED

#### F-P106-01: Gate #28 Form-B-Only Known-File List Omits BC-INDEX.md

- **Severity:** MED [process-gap]
- **Owner:** PO + orchestrator
- **Category:** process-gap (gate #28 MANDATORY PRE-EMISSION CHECK known-file completeness)
- **Location:** `.factory/specs/prd-supplements/bc-authoring-plan.md` §Gate #28, MANDATORY PRE-EMISSION CHECK — Known Form-B-only files list
- **Description:** The MANDATORY PRE-EMISSION CHECK block added in v2.33 (OBS-P105-B fix) lists a known set of Form-B-only files: BCs (BC-2.07.002, BC-2.08.011, BC-2.08.012) and Supplements (bc-authoring-plan.md, test-vectors.md, verification-architecture.md). The list omits `BC-INDEX.md`. BC-INDEX.md carries its changelog exclusively as a `## Changelog` body table (Form B only — located at approximately line 162 of BC-INDEX.md); it has no frontmatter `changelog:` YAML key. BC-INDEX.md is not an ADR and is not a prd-supplement, so it fell through the catch-all that reads "Any ADR or supplement that uses a `## Changelog` body section." A future adversary pass running only Form A against BC-INDEX.md would produce a false-positive "missing changelog" finding — exactly the failure mode the MANDATORY PRE-EMISSION CHECK was designed to prevent.
- **Evidence:** BC-INDEX.md — no `changelog:` frontmatter key; body `## Changelog` table present; file is not an ADR (no `adr:` frontmatter), not a prd-supplement. v2.33 catch-all covers "Any ADR or supplement" only — `BC-INDEX.md` belongs to the behavioral-contracts/ tree and is a living index file, neither ADR nor supplement.
- **Gate:** Gate #28 MANDATORY PRE-EMISSION CHECK own completeness; gate #28 Form-B union-coverage rule.
- **Fix:** (1) Add `BC-INDEX.md` to the explicit list under a new "Indexes:" bullet within the Known Form-B-only files block. (2) Broaden the catch-all from "Any ADR or supplement that uses a `## Changelog` body section" to "Any index, ADR, or supplement that uses a `## Changelog` body section rather than a frontmatter `changelog:` YAML list" — covering BC-INDEX.md and any future living-index files. (3) Perform a difference-set verification: enumerate all files matching `grep -rl "^## Changelog" .factory/specs/` vs `grep -rl "^changelog:" .factory/specs/` — files in the first set but not the second are Form-B-only; all must appear in the explicit list or under the catch-all. bc-authoring-plan.md version bump: v2.33 → v2.34.

### OBS

#### OBS-P106-A: E-MEMORY-006 Message Format Has Unfillable Placeholder and Hardcoded Class Name

- **Severity:** OBS
- **Owner:** PO
- **Category:** error-taxonomy-message-format (taxonomy message ↔ BC struct-field 1:1 parity; gate #33 SEMANTIC-AGREEMENT)
- **Location:** `.factory/specs/prd-supplements/error-taxonomy.md` §Component: MEMORY, E-MEMORY-006 row, Message Format column
- **Description:** The E-MEMORY-006 InsufficientPrivilege Message Format in error-taxonomy.md v1.19 reads: `` `InsufficientPrivilege: operation '<operation>' requires AdminContext; caller has <caller_privilege>` ``. Two defects: (1) `AdminContext` is hardcoded — this is the name of a specific implementing type, not a struct field. BC-2.15.003 EC-005 struct is `{ operation, required }` where `required` is a general description of the required privilege level; the taxonomy message hardcodes a specific class name instead of the parameterizable `<required>` placeholder. (2) `<caller_privilege>` has no corresponding struct field in BC-2.15.003 EC-005 struct `{ operation, required }` — the struct has no `caller_privilege` field, so this placeholder can never be filled from the struct. The message as written would require implementers to invent a field not in the contract.
- **Evidence:** BC-2.15.003 EC-005 struct: `{ operation, required }`. Taxonomy message: `requires AdminContext; caller has <caller_privilege>`. "AdminContext" does not appear in EC-005 struct definition; `<caller_privilege>` field does not exist in EC-005 struct. Gate #33 BC-wins-on-divergence rule applies: BC-2.15.003 is authoritative.
- **Fix:** Correct E-MEMORY-006 Message Format to: `` `InsufficientPrivilege: operation '<operation>' requires <required>` `` — mapping 1:1 to BC-2.15.003 EC-005 struct fields `{ operation, required }`. Run sibling sweep of all struct-bearing MEMORY codes to verify no analogous struct-field mismatch. error-taxonomy.md version bump: v1.19 → v1.20.

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 1 |
| LOW | 0 |
| **Total findings** | **1** |
| OBS / process-gap | 1 |

**CLEAN (strict):** no (1 MED + 1 OBS)
**CLEAN (PR-merge):** no (1 MED present)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** MEDIUM (new axes: gate #28 known-file list completeness for index-type files distinct from the ADR/supplement catch-all; gate #33 message-format struct-field parity for POLICY codes with parameterized privilege descriptions — distinct from prior description-spanning and message-prefix finding classes)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 106 |
| **New findings** | 1 MED (F-P106-01) + 1 OBS (OBS-P106-A) |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | MEDIUM (F-P106-01: gate #28 known-file list completeness for index-type files is a distinct axis from the earlier Form-B/ADR/supplement coverage gaps; OBS-P106-A: E-MEMORY-006 message-format struct-field parity under gate #33 — distinct from the message-prefix class of D18-P78-A and the description-spanning class of F-P105-01) |
| **Median severity** | MED |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1 |
| **CLEAN (strict)** | no (1 MED + 1 OBS) |
| **CLEAN (PR-merge)** | no (1 MED present) |
| **Verdict** | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
