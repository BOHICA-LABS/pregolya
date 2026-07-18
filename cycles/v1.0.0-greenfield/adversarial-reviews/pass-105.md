---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T09:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 105
previous_review: pass-104.md
---

# Adversarial Review: ferrochain (Pass 105)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification (Pass 104 findings)

| ID | Previous Severity | Status | Notes |
|----|-------------------|--------|-------|
| F-P104-01 | MED (architect) | RESOLVED | ARCH-INDEX.md v1.1 changelog row reconstructed from burst-187 git archaeology (commit 8aebfcd); v1.0 row also reconstructed (commit ef41eda); both annotated with NOTE markers citing source commit SHAs per F-P88-03 precedent. api-surface.md v1.0 row similarly reconstructed from ef41eda. Changelog is now complete: v1.4/v1.3/v1.2/v1.1/v1.0 descending. Missing-level sweep across all architecture files and ADR-009/012/013 confirmed no other gaps. |

**Sibling-checks (burst-187/188 owed list):**

| Check | Result |
|-------|--------|
| (a) ARCH-INDEX.md changelog completeness — 5 rows present (v1.4/v1.3/v1.2/v1.1/v1.0), descending order | PASS — v1.1 and v1.0 rows present; descending order confirmed; NOTE markers citing 8aebfcd (v1.1) and ef41eda (v1.0) present |
| (a-fidelity) ARCH-INDEX v1.1+v1.0 NOTE source commits git-verified — requires `git show <SHA>` access | UNVERIFIABLE (adversary read-only profile) — CLOSED BY ORCHESTRATOR via git: burst-188 spot diffs 5/5 hash-field-only (zero content changes); burst-187 file set matches sanctioned scope; commits 8aebfcd/ef41eda confirmed as reconstruction sources |
| (b) api-surface.md changelog completeness — 5 rows present (v1.4/v1.3/v1.2/v1.1/v1.0), descending order | PASS — v1.0 row present; NOTE cites ef41eda; descending order confirmed |
| (c) Missing-level sweep: all architecture files + ADR-009/012/013 | PASS — corpus-complete; no other architecture file has a version-level gap |
| (d) Gate #28 completeness-axis corpus spot-check (pass-105 adversary owns) | PASS — spot-checked architecture section files and selected high-churn BC files; all changelogs complete at current version; no version-level gaps found |
| (e) Corpus hash-currency TOTAL MATCH — requires bash shell access | UNVERIFIABLE (adversary read-only profile) — CLOSED BY ORCHESTRATOR via git: burst-188 was bookkeeping-only; spot-diff verification of 5 updated files confirmed hash-field-only changes; TOTAL MATCH 128/128 confirmed per burst-188 burst-log entry |

**Summary of Part A positive verification:**
- ARCH-INDEX.md changelog completeness (5 rows, descending): PASS
- api-surface.md changelog completeness (5 rows, descending): PASS
- Source commit fidelity for reconstructed rows (8aebfcd/ef41eda): CLOSED BY ORCHESTRATOR
- Missing-level sweep corpus-complete: PASS
- Gate #28 completeness-axis spot-check: PASS
- Hash-currency TOTAL MATCH: CLOSED BY ORCHESTRATOR

## Part B — New Findings

### MED

#### F-P105-01: SECURITY Category Description Contradicts Member Taxonomy and Omits Two of Three Members

- **Severity:** MED
- **Owner:** PO
- **Category:** error-taxonomy-category-definition (category description ↔ row-categorization semantic coherence; new axis)
- **Location:** `.factory/specs/prd-supplements/error-taxonomy.md` §Error Categories, SECURITY row, Description column
- **Description:** The SECURITY category description in error-taxonomy.md v1.18 reads "Workspace escape, sandbox policy enforcement." This description has two defects: (1) **Semantic contradiction**: the phrase "sandbox policy enforcement" is the exact domain of `E-SBXD-002 PolicyNotEnforceable`, which is classified as POLICY — not SECURITY. Listing "sandbox policy enforcement" in the SECURITY description directly contradicts the categorization of the code whose name is literally *PolicyNot**Enforceable***. (2) **Membership omission**: the SECURITY category has three members — `E-SBXD-001 WorkspaceEscape`, `E-GRAPH-013 InsufficientApproverRole`, and `E-MEMORY-007 MemoryWriteGuardDenied`. The description names only workspace/sandbox escape; it does not mention approver-role authorization failure (E-GRAPH-013) or agent-memory write injection prevention (E-MEMORY-007). A category description whose scope is narrower than its member set is incomplete and misleads implementers about which errors are SECURITY-classified.
- **Evidence:** error-taxonomy.md v1.18, §Error Categories, SECURITY row: `"Workspace escape, sandbox policy enforcement"`. E-SBXD-002 (PolicyNotEnforceable) is POLICY category — "sandbox policy enforcement" is its domain, not SECURITY. E-GRAPH-013 (SECURITY) description: "approver-role authorization failure (HITL risk-tier gate)". E-MEMORY-007 (SECURITY) description: "agent-controlled write injection prevention." Both SECURITY-classified members unmentioned in the category description.
- **Gate:** Gate #33 SEMANTIC-AGREEMENT sub-check (category description must agree with member semantics); category-description membership coverage implicit in gate #33's purpose.
- **Fix:** Rewrite the SECURITY description to span all three members: `"Workspace/sandbox escape; approver-role authorization failure; agent-memory write injection prevention"` — covering E-SBXD-001 (path escape per BC-2.13.005), E-GRAPH-013 (HITL approval gate per BC-2.05.006), and E-MEMORY-007 (write injection prevention per BC-2.15.005). Remove the "sandbox policy enforcement" phrase entirely. Perform sibling sweep of all other category descriptions to verify none have analogous omission gaps.

### OBS

#### OBS-P105-A: SECURITY vs POLICY Authorization-Failure Categorization — Adjudicated

- **Severity:** OBS (adjudicated; no open defect)
- **Owner:** PO + orchestrator
- **Category:** error-taxonomy-category-definition (categorization rule documentation)
- **Location:** `.factory/specs/prd-supplements/error-taxonomy.md` §Error Categories
- **Description:** During investigation of F-P105-01, the adversary observed that `E-GRAPH-013 InsufficientApproverRole` is categorized SECURITY, while `E-MEMORY-003 CrossScopeIsolationViolation` and `E-MEMORY-006 UnauthorizedErasure` are categorized POLICY — yet all three involve authorization/privilege failures. Without a documented rule, a future implementer adding a new authorization-failure code might mis-categorize it. The SECURITY/POLICY split is intentional and has a clear semantic basis, but that basis was not written down anywhere in the taxonomy.
- **Evidence:** E-GRAPH-013 (SECURITY): HITL approval gate — bypassing it could authorize execution of a harmful high-risk action (attack vector). E-MEMORY-003 (POLICY): cross-scope memory isolation — policy constraint on legitimate callers accessing out-of-scope data. E-MEMORY-006 (POLICY): admin-only erasure — capability/data-access constraint on otherwise-legitimate operations. The attack-vector / legitimate-caller distinction is real and defensible, but undocumented.
- **Adjudication:** SECURITY guards boundaries whose bypass enables an attack vector (unauthorized action that causes harm beyond data exposure alone: BC-2.05.006 HITL gate, BC-2.13.005 sandbox escape, BC-2.15.005 write injection). POLICY enforces privilege/data-access constraints for otherwise-legitimate callers who lack the required capability or scope (BC-2.15.002 cross-scope isolation, BC-2.15.003 admin-only erasure). Rule documented as a blockquote note after the Error Categories table in error-taxonomy.md v1.19. No categorization changes required.

#### OBS-P105-B: Gate #28 Form-B False-Positive Trap Reproduced (Process-Gap)

- **Severity:** OBS [process-gap]
- **Owner:** PO + orchestrator
- **Category:** process-gap (adversary gate #28 pre-emission check)
- **Location:** `.factory/specs/prd-supplements/bc-authoring-plan.md` §Gate #28 completeness sub-check
- **Description:** During this pass, the adversary initially flagged `verification-architecture.md` as missing a changelog (Form-A check: frontmatter `changelog:` key absent). The adversary self-corrected upon recognizing that `verification-architecture.md` is a Form-B file (body `## Changelog` table), and that its Form-B changelog IS present and complete. This is a recurrence of F-P49-01 — the adversary ran only the Form-A check first, nearly filing a false positive before catching the Form-B case. The existing "CRITICAL" warning and "Union coverage rule" text in gate #28 was not sufficient to prevent the near-miss; the gate lacked an explicit MANDATORY pre-emission checkpoint that blocks filing until both forms are verified.
- **Evidence:** `verification-architecture.md` has no frontmatter `changelog:` field (FAIL Form-A) but has a body `## Changelog` table (PASS Form-B). Gate #28 §version-changelog integrity had a "Union coverage rule" but no structured pre-emission step requiring the adversary to explicitly check Form-B before filing a "missing changelog" finding.
- **Precedent:** F-P49-01 (same false positive class, same file class, pass 49); OBS-P65-1 (Form-B set first enumerated explicitly).
- **Fix:** Insert a standalone `MANDATORY PRE-EMISSION CHECK` block at the gate #28 changelog-presence sub-check, with two explicit per-step checks: (1) Form-A: check frontmatter `changelog:` key — if absent, do NOT file yet; proceed to Form-B check; (2) Form-B: check for body `## Changelog` section — if present, finding is INVALID (file is compliant via Form-B); (3) only if BOTH are absent file the finding. Enumerate the known Form-B-only files (BCs: BC-2.07.002, BC-2.08.011, BC-2.08.012; supplements: bc-authoring-plan.md, test-vectors.md, verification-architecture.md) inline as a known-list gate. bc-authoring-plan v2.32 → v2.33.

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 0 |
| MED | 1 |
| LOW | 0 |
| **Total findings** | **1** |
| OBS / process-gap | 2 (OBS-P105-A adjudicated inline; OBS-P105-B self-corrected before filing) |

**CLEAN (strict):** no (1 MED + 2 OBS)
**CLEAN (PR-merge):** no (1 MED present)

**Convergence counter:** 0/3 (NOT CLEAN strict; counter stays at 0)
**Novelty:** MEDIUM (new axis: error-taxonomy category-description ↔ row-categorization semantic coherence; distinct from prior description-level findings; directly uncovered by F-P105-01 SECURITY membership audit)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 105 |
| **New findings** | 1 MED (F-P105-01) + 2 OBS (OBS-P105-A adjudicated; OBS-P105-B self-corrected) |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | MEDIUM (new axis: category-description ↔ membership semantic coherence; distinct from the changelog-ordering/completeness classes of passes 101-104; OBS-P105-B is a recurrence of F-P49-01 class but adversary self-corrected before filing) |
| **Median severity** | MED |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1 |
| **CLEAN (strict)** | no (1 MED + 2 OBS) |
| **CLEAN (PR-merge)** | no (1 MED present) |
| **Verdict** | FINDINGS_REMAIN; NOT CLEAN strict; NOT CLEAN PR-merge |
