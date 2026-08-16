---
document_type: adr
level: L3
adr_id: "022"
slug: section-anchor-citation-convention
title: "§Named-Section Citation Convention: Restriction to Real Markdown Headings (fix-burst-287 / F-P176-A039 + F-P176-E001)"
status: accepted
producer: architect
timestamp: 2026-08-01T00:00:00Z
date: "2026-08-15"
version: "1.3"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17]
subsystems_affected: ["all"]
supersedes: null
superseded_by: null
changelog:
  - "1.3 (burst-288/F-P177-A01/2026-08-15): Reconcile §Decision 3 rule 5 vs §Decision 4 step 2 ambiguous-prefix conflict. Decision 4 step 2 was underdetermined: it treated any 'heading found' result as 'valid, no change' without distinguishing the one-match (unambiguous, valid) case from the multiple-match (ambiguous, invalid per Decision 3 rule 5) case. Fix: add step 2b and step 2c to Decision 4 to explicitly handle ambiguous-prefix citations — tighten the cited prefix to uniquely identify the intended heading using the known-replacements table or a description-qualified suffix. Add enumeration of 3 live corpus ambiguous-prefix instances requiring sweep and their prescribed resolutions."
  - "1.2 (fix-burst-287/measured-migration-count/2026-08-01): Correct fabricated migration count in Decision 4 and Consequences. '~170 citations across ~85 files' replaced with devops-measured figures: 42 normative-prose ADR-target §citations (217 raw occurrences minus 133 changelog/frontmatter exempt, minus 7 fenced-code, 16 inline-backtick, ~2 illustration, ~16 §Decision-N, 1 double-§ edge-case). 10 of the 42 are currently phantom. Sweep is a single-burst task, not a deferred campaign; gate can be promoted to BLOCKING sooner than v1.0/1.1 assumed. Note irony recorded: ADR-022's own migration precondition inherited the inflated count from CRIT E001 — fourth artifact this burst to carry a defect of the class it was created to fix. Add Decision 5: scope rule (ADR-target-only machine enforcement; Form A spirit binds all §-citations by convention; non-ADR targets adjudicated per-burst); chained double-§ forms prohibited."
  - "1.1 (fix-burst-287/2026-08-01): Correct self-consistency defects per DIRECTIVE 2. Fix Form A example to use exact ADR-010 heading text (Class 3, not Class-3). Tighten Decision 1 legal-form and Decision 3 validator spec to use prefix matching (heading must START WITH citation text; parenthetical suffixes allowed). Correct two migration-guidance citations (Class 1, Class 3 — no hyphens). Add DIRECTIVE 1 insight: reviewers, not only fix-burst agents, invent phantom anchors."
  - "1.0 (fix-burst-287/F-P176-A039+F-P176-E001/2026-08-01): Initial decision — close Mechanism 1 (§-anchor unverifiability). Restricts §Name citation convention to real markdown headings. Resolves structural conflict between TD-VSDD-091 (anti-volatile-pin) and machine-verifiable anchor resolution. Prerequisite to devops-engineer gate implementation."
---

# ADR-022: §Named-Section Citation Convention: Restriction to Real Markdown Headings

**Status:** Accepted — fix-burst-287 architect adjudication of F-P176-A039 (HIGH) and F-P176-E001 (CRIT) from P1D-176 Mechanism 1.

---

## Context

The `§Name` notation has been used in three structurally different ways across this spec corpus:

1. **Form A — Real heading:** `ADR-010 §Class 3 — Value-Observation Form` where `### Class 3 — Value-Observation Form (MUST include \`..` when eliding fields)` is an actual markdown heading in ADR-010. A validator can resolve this by scanning heading lines. The citation text is the start of the heading; the parenthetical suffix is permitted trailing content.

2. **Form B — Bold inline label:** `ADR-010 §impl PregolyaError` where `impl PregolyaError` is a Rust impl block identifier appearing in bold prose, not a markdown heading. No heading `## impl PregolyaError` exists in ADR-010. This form was introduced to cite a specific code block without creating a separate heading for it.

3. **Form C — Slugified pseudo-anchor:** `ADR-010 §non-exhaustive-gate/F-P173-619` where the notation combines a topic slug and a finding ID into a composite path-like anchor. No heading matching this string exists anywhere.

All three forms are syntactically identical in citation prose: a § symbol followed by text. No automated validator can distinguish Form A (resolvable) from Form B or C (phantom). Consequence: fabricated anchors (D-106 class) pass every blocking validator, and POL-19's assertion that §Named-Section citations are machine-enforced is false (F-P176-E001 CRIT).

A second structural problem: TD-VSDD-091 (anti-volatile-pin policy, L9b) requires converting `<doc> vN.N` citation forms into `§Named-Section` forms. Without restricting `§Name` to real headings, this policy instructs agents to replace version-pinned citations with whatever section anchor text seems topically correct — which may not correspond to any real heading. This makes the anti-volatile-pin policy a fabrication generator: it produces Form B or C citations that look valid but are phantom anchors.

---

## Decision 1 — §Name denotes a real markdown heading only

The `§Name` citation marker is **restricted to Form A only**. `§Name` MUST denote a section heading that exists as a real markdown heading in the target document.

**Legal form:** `<document-identifier> §Heading-Text` where the target document contains a heading line whose text **starts with** `Heading-Text` (case-sensitive). Formally: the heading line matches `^#{1,6} Heading-Text` where `Heading-Text` may be followed by end-of-line, a space, or an opening parenthesis (for parenthetical suffixes such as `(D-72 extension, v1.14)` or `(MUST use \`::new()\`)`). The citation text must be a unique prefix — it must match exactly one heading in the target document.

**Illegal — Form B (bold inline label):** Citations where the `§Name` text matches a **bold** label or a Rust code block identifier (`impl Block`, `struct Name`, `fn name`) that is NOT also a markdown heading. Example: `ADR-010 §impl PregolyaError`. The impl block identifier is not a heading. **Prohibited as of this ADR.** Replace with the real heading that governs the discussed content.

**Illegal — Form C (slugified pseudo-anchor):** Citations where `§Name` contains a `/` separator, combines a topic slug with a finding ID, or otherwise constructs a synthetic path-like anchor that has no corresponding heading. Example: `ADR-010 §non-exhaustive-gate/F-P173-619`. **Prohibited as of this ADR.** Replace with the real heading in the governing ADR, or with `ADR-NNN Decision N` if a numbered decision is the appropriate cite target.

**No new non-heading forms are to be invented.** If the content you want to cite has no heading, the correct action is: (a) create the heading in the target document, then cite it; or (b) cite only the document (bare `ADR-NNN`) without a section anchor if section precision is not needed.

---

## Decision 2 — TD-VSDD-091 conflict resolution: anti-volatile-pin requires real headings

TD-VSDD-091 (anti-volatile-pin policy, L9b) requires that `<doc> vN.N` version-pinned citation forms be replaced with non-volatile `§Named-Section` citations. This ADR resolves the structural conflict between that requirement and anchor verifiability.

**Governing rule:** When TD-VSDD-091 requires replacing `<doc> vN.N` with a `§Named-Section` citation, the replacement MUST satisfy Decision 1: the named section MUST be a real heading that exists in the target document at the time of replacement.

**If no real heading exists:** The replacing agent MUST first create the appropriate heading in the target document (making it a real markdown heading), THEN cite it. Anti-volatile-pin does not authorize citing non-existent headings.

**Rationale:** TD-VSDD-091's purpose is to remove version fragility (a `vN.N` citation breaks when the document version advances). Replacing a version pin with a phantom anchor introduces a different kind of fragility — a broken anchor that resolves to nothing. A phantom anchor is strictly worse than the version pin it replaced: at least a stale version pin is detectably stale; a phantom anchor appears valid to automated tooling.

**Operational consequence:** Before executing any L9b de-pin operation, the agent MUST verify the proposed `§Name` is a real heading in the target document. If it is not, creating the heading is part of the L9b de-pin task, not a separate follow-up.

---

## Decision 3 — Machine verification specification

A blocking validator enforcing this convention MUST implement the following existence check:

**Scan target:** Every `ADR-NNN §Section-Text` pattern found in the live body of any `.factory/specs/` markdown file (post-frontmatter), excluding:
- `## Changelog` body sections (standard exemption).
- Content inside fenced code blocks (`` ``` `` ... `` ``` ``).
- Content inside inline backtick spans (`` `...` ``).

Backtick-quoted content is example or code material, not a normative citation. ADR-022 itself contains Form B and Form C examples inside backticks (illustrating prohibited forms); these are intentional negative examples and must not trigger validator failures.

**Validation rule:** For each citation `ADR-NNN §Section-Text`:
1. Locate the target ADR file: `specs/architecture/decisions/ADR-NNN-*.md`.
2. Read the target ADR body (post-frontmatter).
3. Check that the target body contains a heading line starting with `#{1,6} Section-Text` (case-sensitive prefix match). The heading text may have additional trailing content (parenthetical suffix, em-dash elaboration) after `Section-Text`. Formally: `grep -q "^#{1,6} Section-Text" target.md` must exit 0, where the pattern is not anchored at the end. Additionally check that the match is unambiguous (only one heading matches the prefix).
4. **FAIL** if no heading starts with `Section-Text` (phantom anchor — D-106 class).
5. **FAIL** if multiple headings start with `Section-Text` (ambiguous citation — tighten the cited prefix).
6. **PASS** if exactly one heading starts with `Section-Text`.

**Scope note:** This validator covers `ADR-NNN §Name` citations specifically. Cross-document `§Name` citations (e.g., `module-decomposition.md §ss-22`) require a separate validator scoping rule (distinct from this ADR's scope; future work).

**Integration with existing validators:**
- `verify-adr-decision-refs.sh` gates `ADR-NNN §?Decisions? N` (numeric decision citations) — complementary scope, not overlapping.
- `verify-arch-anchor-resolution.sh` gates `architecture/<path>.md` path-level citations — file-level resolution only, not section-level.
- The new anchor-resolution gate covers the currently unvalidated `ADR-NNN §Named-Section` space.

**Validator output contract:** Same PASS/WARN/FAIL contract as existing blocking validators. Exit 1 if any FAIL; exit 0 otherwise.

---

## Decision 4 — Migration rule for existing corpus

**Measured corpus state (devops direct measurement):** 217 raw `ADR-NNN §` occurrences exist across the `.factory/specs/` corpus. Of these, 133 are in changelogs and YAML frontmatter (historical narrative — exempt); 7 are in fenced code blocks; 16 are in inline backtick spans; approximately 2 are in illustration regions; approximately 16 are `§Decision N` forms already covered by `verify-adr-decision-refs.sh`; 1 is a double-§ chained form (see Decision 5). **Net normative-prose ADR-target citations: 42, of which 10 are currently phantom anchors.**

This is a single-burst sweep, not a deferred multi-burst campaign. **This migration is NOT performed in this ADR's burst.** It is assigned to a subsequent dedicated sweep burst.

**Note (fourth-artifact irony):** This ADR's initial migration count of "~170 citations across ~85 files" was inherited from adversarial review finding E001 — the same pass this ADR exists to prevent. The adversary's measurement was not verified before being transcribed into the migration precondition. This is the fourth artifact in fix-burst-287 to carry a defect of the class it was created to fix.

**Migration rule for the sweep burst:**

For each `ADR-NNN §Name` citation in a live spec body:
1. Check whether a line `^#{1,6} Name` exists in `ADR-NNN-*.md` body.
2. **If yes — one match (unambiguous):** Citation is valid. No change.
2a. **If yes — multiple matches (ambiguous prefix, Decision 3 rule 5 FAIL):** The prefix matches more than one heading in the target ADR. This is NOT valid. The citation MUST be tightened: extend `Name` to a longer prefix that uniquely identifies the intended heading, or include the parenthetical suffix that distinguishes it (e.g., `§Component Axis Expansion (D21) — 12 → 16` instead of `§Component Axis Expansion`). Use the `grep -c "^#{1,6} Name" target.md` count to confirm uniqueness after tightening.
2b. **Known ambiguous-prefix instances requiring sweep resolution** (3 live instances identified by P1D-177):
   - Any bare `ADR-010 §#[non_exhaustive] gate update requirement` citation (without D21 or D23 qualifier) — matches both `### #[non_exhaustive] gate update requirement` (D21 context) and `#### #[non_exhaustive] gate update requirement (D23)`; tighten to whichever heading is intended, qualified by the D-decision suffix.
   - Any bare `ADR-010 §Component Axis Expansion` citation (without D21/D23 qualifier) — matches both `## Component Axis Expansion (D21) — 12 → 16` and `## Component Axis Expansion (D23) — 16 → 17`; tighten to the fully qualified heading.
   - The sweep burst MUST grep for all citations matching these patterns and resolve each by tightening to the unambiguous qualified form. If additional ambiguous-prefix instances are discovered during the sweep, apply step 2a to each.
3. **If no (phantom anchor):** Determine the intended target.
   - If the intent is a specific numbered decision, replace with `ADR-NNN Decision N`.
   - If the intent is a real section heading with a different name, replace `§Name` with `§Actual-Heading-Text`.
   - If the intent cannot be determined, replace with the bare `ADR-NNN` citation (no section anchor).
4. **Do not invent new headings in the target ADR** during the sweep — that would require an architect review. Replace phantom anchors with real citations using existing headings.

**Known high-frequency phantom anchors to resolve in the sweep:**
- `ADR-010 §impl PregolyaError` (Form B) → cite `ADR-010 §Error-Construction Notation Canon` or the specific class section (`ADR-010 §Class 1 — Construction Form` etc.) depending on context
- `ADR-010 §non-exhaustive-gate/F-P173-619` (Form C) → cite `ADR-023 §Decision 1` (the governing rule now exists in ADR-023, which addresses the `#[non_exhaustive]` governance gap)
- `ADR-021 §configurable-merge-protocol` (Form B, finding F-P176-B025) → cite `ADR-021 §Decision 2`

---

## Decision 5 — Gate scope and chained-§ prohibition

### Machine enforcement scope: ADR-target citations only

The Decision 3 validator enforces `ADR-NNN §Section-Text` citations specifically. It is **ADR-target-only** — it does not machine-check §citations to BC, VP, CAP, ADV-P, or other document types.

**Rationale for ADR-target-only enforcement:** Machine verification of `ADR-NNN §X` requires knowing the heading inventory of ADR files — a fixed, well-enumerated set under `architecture/decisions/`. Machine verification of `BC-S.SS.NNN §X` would require heading inventories of behavioral contracts (PO scope, dynamically evolving). Each document class would need its own gate with its own heading corpus. This is future work, not this ADR's scope.

**Convention versus enforcement:** The Form A spirit — cite only real headings — applies to ALL §-citations as an authoring norm, regardless of target document type. Authors MUST check that a cited heading exists in the target document before committing, regardless of document type. Violations in non-ADR targets are **not machine-detected by the anchor gate**; they are caught by adversarial review and corrected per-burst.

This means the corpus has two tiers:
- **ADR-target §citations:** Fully machine-enforced. Zero phantom anchors permitted after migration sweep.
- **Non-ADR §citations:** Convention-bound, not machine-enforced. 183 non-ADR §citations exist (BC: 79, ADV-P: 42, VP: 24, F-P: 14, CAP: 11, other: 13). Authors must apply Form A discipline; violations are adjudicated per-burst.

### Chained double-§ forms are prohibited

**Prohibited:** `ADR-NNN §X §Y` — a citation that chains two §anchors in sequence. Example: `api-surface.md` contains `ADR-014 §Decision 2 §Object-safety`. The second §Object-safety is a phantom in ADR-014 (the actual heading is in ADR-005).

**Reason:** A chained §-anchor citation creates an ambiguous target: does `§Y` refer to a heading in `ADR-NNN` or in some other file? The convention does not define semantics for chained anchors. The gate's regex cannot parse the second §anchor as an independent citation; it is an unflagged known gap in the gate (the gate sees the whole `§Decision 2 §Object-safety` as one anchor text, which fails the heading check).

**Replacement:** Each §citation must be a single anchor in a single document. To cite two related sections:
- Wrong: `ADR-014 §Decision 2 §Object-safety`
- Correct: `ADR-014 §Decision 2` and `ADR-005 §Adjacent Trait Object-Safety Adjudications` (in separate references)

The one known double-§ occurrence (`api-surface.md`) is in the sweep task for Decision 4.

---

## Alternatives Considered

**Alternative 1 — Allow Form B (bold-label citations) alongside Form A.**
Rejected. Machine verification of Form B requires semantic understanding of which inline bold labels carry citation significance — there is no structural marker distinguishing a bold label intended as a citation target from bold text used for emphasis. All three forms are syntactically identical at the `§` callsite; a validator cannot distinguish them without parsing the target document for bold labels (brittle, implementation-complex). Restricting to Form A (real headings) preserves full machine-verifiability with a simple `grep` implementation.

**Alternative 2 — Keep Form C (slugified pseudo-anchors) as a supported third form.**
Rejected. Form C citations (containing `/` separators or combining a slug with a finding ID) have no structural basis in the target document — there is no corresponding heading, only a constructed identifier. They exist solely as a workaround for TD-VSDD-091's L9b de-pin requirement applied without checking heading existence. The production-grade resolution is to require real headings, not to formalize the workaround as a convention.

**Alternative 3 — Restrict Form A citations to exact-match-only (no prefix matching).**
Rejected in favor of prefix matching. ADR headings commonly carry parenthetical suffixes that identify D-decision numbers, version annotations, or qualifying remarks (e.g., `### Class 1 — Construction Form (MUST use \`::new()\`)`). Requiring exact-match citations would force authors to include the entire parenthetical in every citation, increasing fragility — a change to the parenthetical suffix would break all citations. Prefix matching correctly anchors citations to the stable leading text of a heading while tolerating parenthetical additions. Rule 5 (uniqueness requirement) prevents prefix matching from creating ambiguous citations.

---

## Rationale

The three-meaning overload of `§Name` was introduced incrementally: Form A was the original intent; Form B emerged when authors wanted to cite a specific code block without adding a heading (convenient but unverifiable); Form C emerged from TD-VSDD-091 remediation (authors replaced `vN.N` pins with constructed anchor paths without checking heading existence).

Restricting to Form A is correct because:
1. **Machine verifiability by construction.** A heading is a stable, machine-readable artifact. Its existence can be checked by `grep`. A bold label or a fabricated slug cannot be verified without semantic understanding.
2. **Heading creation is cheap.** If content needs to be cited at section granularity, adding a heading is trivial and benefits all readers. The convenience of citing without a heading is outweighed by the fragility it introduces.
3. **No semantic information is lost.** Form B and C citations always correspond to some real content in the target ADR — they just cite it imprecisely. Converting to the real heading that covers that content is always possible.
4. **Phantom anchors are not exclusive to fix-burst agents.** In P1D-176 pass itself (adversarial review), finding D013 cited `entities-server.md §RunState` — a heading that does not exist in that file. The adversary reviewer fabricated the anchor in the act of writing the finding. This demonstrates that the problem affects any author — reviewers, spec-stewards, and auditors — not only automated agents executing fixes. The convention must be self-verifying at authoring time (via `grep` before committing the citation), not only at gate-run time. A restriction that requires active checking is stronger than one that relies on reviewer discipline alone.

---

## Consequences

- All `§Name` citations in live spec bodies must resolve to real headings. POL-19 (which asserts machine enforcement) remains accurate after the devops-engineer builds the blocking gate against Decision 3.
- The TD-VSDD-091 anti-volatile-pin policy must be read as requiring real headings, not arbitrary section text. Spec-steward must update POL-19 wording to state the restriction.
- The 42-normative-citation sweep (10 phantom defects) is a prerequisite for the gate to run at exit 0. The measured size makes this a single-burst task. Until the sweep completes, the gate may be run in advisory mode.
- The ADR-010 Class 3 prohibition is strengthened in this same burst (ITEM 3 of fix-burst-287) — see ADR-010 §Class 3 — Value-Observation Form for the canonical form and rationale.

---

## Source / Origin

- **F-P176-A039** (HIGH): §Name three-meaning taxonomy: gate pre-requisite convention restriction.
- **F-P176-E001** (CRIT): POL-19 asserts machine enforcement of §Named-Section anchors; no such enforcement exists.
- **F-P176-A007** (HIGH): POL-16 and POL-18 anchored to nonexistent ADR-010 sections (Form B phantom anchors).
- **L-155** (structural conflict record): TD-VSDD-091/L9b makes the anti-volatile-pin policy a fabrication generator when §Name is not restricted.
- **`verify-adr-decision-refs.sh`** (`CITE_RE` constant `r'\bADR-(\d{3})\s+§?Decisions?\s+(\d+)\b'`): confirms zero coverage for §Named-Section forms (requires a number, not a named section).
- **verify-arch-anchor-resolution.sh**: confirms file-level resolution only (no section-level check).
