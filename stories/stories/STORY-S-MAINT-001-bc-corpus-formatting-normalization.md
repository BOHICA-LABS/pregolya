---
document_type: story
level: ops
story_id: S-MAINT-001
epic_id: EPIC-MAINT
version: "1.2"
status: draft
# POL-29 gate waived for maintenance stories per D-259+ (product-owner 2026-08-24). behavioral_contracts: [] is intentional and correct. Story may be promoted to ready once state-manager records the canonical-format decision rows in STATE.md (AC-001 gate). Canonical BC formats decided: ## Invariants = bullet list (- {INV-NNN} ...); ## Edge Cases = ### EC-NNN subsection headers.
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/BC-INDEX.md
input-hash: "9d09df5"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: []
blocks: []
behavioral_contracts: []
verification_properties: []
priority: P2
cycle: v1.0.0-greenfield
wave: out-of-wave
target_module: .factory/specs/behavioral-contracts
subsystems: []
estimated_days: 1
assumption_validations: []
risk_mitigations: []
tdd_mode: facade
# tdd_mode: facade — no Rust code is produced; this story edits spec Markdown files only.
# Quality gate: `verify-ac-pc-trace.sh` exits 0 after all edits (replaces Red Gate density check).
---

# S-MAINT-001: BC Corpus Section Formatting Normalization

> **OUT-OF-WAVE** — This story does not modify any product story, wave schedule, or
> behavioral contract semantics. It is tracked separately from the 39-story converged
> product census and must not alter wave assignments, story points totals, or BC coverage
> maps. Dispatch only after explicit human direction and after the canonical format
> decision (see AC-001) is recorded in STATE.md.

## Narrative

- **As a** spec tooling author and future maintainer
- **I want to** normalize BC corpus section formatting to a single canonical style per section type
- **So that** automated validators, grep patterns, and human reviewers can rely on
  consistent structure across all 134 BCs without format-conditional logic or
  ambiguous dual-format parsing

## Background (P2A-032 Finding)

During Phase 2 Adversarial pass P2A-032, a corpus-wide formatting split was identified:

- **`## Invariants` section:** 94 of 134 BCs use bullet lists; 40 use numbered lists.
  Affected BC families: BC-2.04.*, BC-2.11.*, BC-2.13.*, BC-2.18.*, BC-2.19.*,
  BC-2.20.*, BC-2.21.*, BC-2.22.*.
- **`## Edge Cases` section:** 81 of 134 BCs use `### EC-NNN` subsection headers;
  53 use Markdown table rows.

The `verify-ac-pc-trace.sh` validator was updated to be format-agnostic, so this split
does NOT block validation or convergence. The normalization is a readability and
tooling-durability improvement recorded per human direction 2026-08-22.

## Behavioral Contracts

_None — this is a tooling/consistency maintenance story with no product behavioral
contract. The story's own acceptance criteria constitute the full governance gate._

## Acceptance Criteria

### AC-001: Canonical format decision recorded
Before any file edits begin, the architect or PO records the canonical format
choice for each section type in STATE.md as a D-NNN decision row:
- `## Invariants`: bullet list (`- `) OR numbered list (`1.`) — one chosen
- `## Edge Cases`: `### EC-NNN` subsection headers OR Markdown table rows — one chosen

This AC gates all subsequent ACs. No file edits proceed without the D-NNN row.

### AC-002: All 134 `## Invariants` sections use the chosen canonical format
After normalization, `grep -rn` across `.factory/specs/behavioral-contracts/`
finds zero BC files with the non-canonical invariant list format. The 40 previously
numbered-list BCs (BC-2.04.*, BC-2.11.*, BC-2.13.*, BC-2.18.*, BC-2.19.*,
BC-2.20.*, BC-2.21.*, BC-2.22.*) are converted to match the canonical form.
Conversion is purely syntactic — no invariant text, numbering of clauses, or
semantic content is altered.

### AC-003: All 134 `## Edge Cases` sections use the chosen canonical format
After normalization, `grep -rn` across `.factory/specs/behavioral-contracts/`
finds zero BC files with the non-canonical edge-case format. The 53 previously
table-row BCs are converted to match the canonical form. EC IDs, descriptions,
and expected behaviors are preserved verbatim — only the structural wrapper changes.

### AC-004: `verify-ac-pc-trace.sh` exits 0 with zero drift after normalization
Running `.factory/hooks/verify-ac-pc-trace.sh` (or equivalent validator) against
the full BC corpus after normalization produces exit code 0, zero findings, and
a total-BC count of 134. No AC-to-BC trace is broken by the formatting change.

### AC-005: BC-INDEX.md content and row count unchanged
`BC-INDEX.md` `Total BCs: 134` count is unchanged. No BC ID, title, priority,
subsystem, or story-coverage field is modified. The only permitted changes to any
BC file are whitespace and list-marker characters in the `## Invariants` and
`## Edge Cases` sections.

### AC-006: No `file:NNN` line-number citations introduced (TD-VSDD-091)
A post-normalization grep confirms zero additions of `file.rs:NNN` or
`path/file:NNN` patterns in any modified BC file. All BC references remain
symbol-name and behavioral-anchor based only.

## Non-Goals

The following are explicitly out of scope and must NOT be performed:

- Rewording, reordering, adding, or removing any invariant clause or edge case
- Changing any BC ID, title, priority, or subsystem assignment
- Modifying any story file, STORY-INDEX.md, or wave schedule
- Altering any AC-to-BC trace in any story
- Adding new BCs or deprecating existing BCs
- Changing error codes, type names, or behavioral semantics of any kind

## Architecture Mapping

| Component | Location | Pure/Effectful |
|-----------|----------|---------------|
| BC corpus files | `.factory/specs/behavioral-contracts/` | Pure (Markdown only) |
| Validator script | `.factory/hooks/verify-ac-pc-trace.sh` | Effectful (shell, read-only after normalization) |

_No Rust source files are modified by this story._

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| BC corpus Markdown files | pure-data | No code, no I/O, no async. Deterministic text transformation of Markdown list syntax only. |
| `verify-ac-pc-trace.sh` | effectful (read-only) | Shell script; reads files but produces no persistent side effects. Invoked only for gate verification, not modified by this story. |

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A BC file has mixed formats within a single section (some bullets, some numbered) | Normalize the entire section to canonical format in one pass; do not partially normalize |
| EC-002 | A BC file's `## Edge Cases` section is empty or absent | Leave the section as-is; empty sections are valid and need no conversion |
| EC-003 | Conversion would alter an EC ID (e.g., `1.` was functioning as `EC-NNN` equivalent) | Preserve the EC-NNN identifiers exactly; only change the structural wrapper, never the identifiers |
| EC-004 | Two BC families have conflicting sub-formatting conventions within the chosen canonical form | Flag to architect; do not normalize silently — the canonical form must be unambiguous before proceeding |

## Token Budget Estimate

| Item | Estimated Tokens |
|------|-----------------|
| This story spec | ~2,000 |
| BC corpus (134 files, ~300 tokens avg) | ~40,200 |
| Validator script review | ~500 |
| BC-INDEX.md | ~3,000 |
| **Total** | **~45,500** |

Token budget is within a single agent context window. The 40 numbered-invariant BCs
and 53 table-edge-case BCs can be processed in a single implementer pass using
targeted `grep` + batch `Edit` calls. No burst splitting required.

## Tasks

- [ ] Await D-NNN decision row in STATE.md authorizing this story and recording canonical format choice
- [ ] Run `grep -rn "^1\. " .factory/specs/behavioral-contracts/` to enumerate affected invariant BCs
- [ ] Run `grep -rn "^| EC-" .factory/specs/behavioral-contracts/` to enumerate affected edge-case BCs
- [ ] For each affected BC, apply format conversion using Edit tool (no shell bypass per TD-FACTORY-HOOK-BYPASS-001)
- [ ] Run `verify-ac-pc-trace.sh` and confirm exit 0 with count=134
- [ ] Confirm BC-INDEX.md total and all rows unchanged
- [ ] State-manager single-commit per TD-VSDD-053

## Previous Story Intelligence

N/A — first story in EPIC-MAINT. No predecessor intelligence to carry forward.

## Architecture Compliance Rules

- Edit only `.factory/specs/behavioral-contracts/` Markdown files
- Use Edit/Write tools only — never Python/sed/echo bypass (TD-FACTORY-HOOK-BYPASS-001 P0)
- Single commit for all BC edits (TD-VSDD-053)
- No line-number citations in modified text (TD-VSDD-091)

## Library & Framework Requirements (MANDATORY)

No Rust dependencies. Tooling: `grep`/`rg` for discovery, `verify-ac-pc-trace.sh`
for gate. No version pins required.

## File Structure Requirements

**Files to modify:** `.factory/specs/behavioral-contracts/ss-*/BC-2.{04,11,13,18,19,20,21,22}.*.md`
(40 invariant files) and the 53 table-edge-case BC files identified by grep.

**Files NOT to modify:** `BC-INDEX.md`, any story file, `STORY-INDEX.md`,
`dependency-graph.md`, `epics.md`, `STATE.md`.

## Changelog

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.2 | 2026-08-27 | story-writer | Round-20/F-P2A092-04: BC census updated 133 → 134 (GAP-01/D-275 added BC-2.09.008; 51 P0/80 P1/3 P2). All live "133 BCs" references updated to 134. Background empirical numerators recomputed: BC-2.09.008 uses bullet-list invariants (canonical format) and ### EC-NNN subsection headers (canonical format) → invariant numerator 93 → 94; edge-case numerator 80 → 81. Denominators in AC-002, AC-003, AC-004, AC-005, Token Budget, and Tasks updated accordingly. |
| 1.1 | 2026-08-24 | story-writer | P2A-044 F-10: POL-29 placeholder resolved — canonical-format decision recorded, S-7.01 gate waived for maintenance class |
| 1.0 | 2026-08-22 | story-writer | Initial story creation |
