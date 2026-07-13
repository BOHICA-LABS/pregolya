---
document_type: lessons
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-13T04:00:00Z
cycle: v0.0.0-pre-pipeline
inputs: [STATE.md]
input-hash: "[live-state]"
traces_to: STATE.md
---

# Lessons Learned — v0.0.0-pre-pipeline

<!-- Lessons are appended as they are captured. Do NOT put lessons in STATE.md. -->

---

## Lesson: PROCESS-GAP — Validator Counting Methodology (2026-07-13)

**Source:** Extraction-validation pass 2 (burst 10)
**Category:** process-gap
**Severity:** HIGH (pass-1 corrections were labeled "verified" but were factually wrong)

### What happened

Extraction-validation pass 1 used regex/string-matching to count dict keys in Python source. The regex matched multi-line tuple value strings as dict keys, producing inflated counts. Pass-1 "corrections" were:
- Chat providers: corrected to 30→33 (actual: 27)
- Embeddings providers: corrected to 11→14 (actual: 10)

These corrections were labeled as validated findings but introduced new inaccuracies. Pass-1 also failed cross-document propagation: module-inventory was corrected but behavioral-intent document was left stale with the old (pre-correction) counts.

Pass 2 independently discovered all of this, reversed the wrong corrections, and fixed all occurrences with [validation-corrected pass-2] markers.

### Why it matters

A 3-CLEAN cascade requires that corrections themselves be correct. If a validator produces wrong corrections labeled as verified, the streak resets and the prior pass's "improvements" become technical debt in the corpus. This happened twice in two passes.

### Codification applied

Going forward for pass 3 and subsequent passes:
1. **AST-based counting mandatory** for any dict/list/set size claim — no regex string-matching on source structure.
2. **Cross-document propagation sweep mandatory** — before finalizing any count correction, grep all related documents for the old count and update all occurrences atomically.
3. **Correction self-audit** — each correction must include the exact file+line evidence that supports the new value; no "obvious from context" reasoning.

### Follow-up

A story for hardening the validate-extraction agent prompt upstream (enforce AST-counting methodology, mandate cross-doc propagation checks in the agent's operating instructions) should be noted in the Drift/Deferral table with target = session-review.

---

## Lesson: PROCESS-GAP — Cross-Document Propagation Failures Recurring Across Passes (2026-07-13)

**Source:** Extraction-validation pass 3 (burst 11)
**Category:** process-gap
**Severity:** MEDIUM (no new source-level inaccuracies introduced, but propagation residue persisted through three passes)

### What happened

Cross-document propagation failures recurred across all three extraction-validation passes. Each time a correction was applied to one document, sibling documents in the same area were left carrying the pre-correction values. This pattern manifested in pass 3 as all 7 findings being propagation residue rather than new source-level inaccuracies:

- langchain/dependency-disposition.md (and its mermaid diagram and strategy table) still showed pre-correction provider counts (30/11) after two passes had already corrected the source value to 27 chat / 10 embeddings.
- Middleware count inconsistencies (13 vs 15) existed simultaneously across §2 table and strategy table in the same file.
- Test-file count discrepancies (18 vs 17; 11 vs 12) existed across sibling documents.

The root cause: each validator pass focused on new strata rather than first auditing whether prior-pass corrections fully propagated to all related documents.

### Why it matters

TD-VSDD-060 (sibling-site sweep) was understood to apply to code corrections, but was not consistently applied to documentation corrections. A correction that partially propagates is worse than no correction: it creates false confidence that the corpus is consistent while leaving silent inconsistencies that surface in later passes as new findings, artificially extending the streak cascade.

### Codification applied

For pass 4 and subsequent passes, the mandatory first stratum is a whole-area propagation audit:

1. **Propagation audit as first stratum:** Before examining new behavioral strata, grep all prior-pass correction values corpus-wide and confirm they are present in ALL related documents. Any file still containing an old value is a propagation gap — sweep and fix before proceeding to new strata.
2. **TD-VSDD-060 applies to documentation corrections:** The sibling-site sweep obligation is not limited to code changes. Documentation corrections must be propagated atomically across all files in the affected area.
3. **Grep anchored context:** When sweeping, use anchored context regexes (e.g., "27 chat", "10 embeddings") rather than bare numbers to avoid false positives.

### Follow-up

Fold the document-sibling-sweep into the validate-extraction agent prompt upstream — same session-review target as the counting-methodology gap (first process-gap lesson). Both gaps compound: AST-counting produces correct values, but those values must then propagate fully across all related documents in a single pass.

---

## Lesson: PROCESS-GAP — Behavioral-Locus Precision Guardrail (2026-07-13)

**Source:** Extraction-validation pass 5 (burst 13)
**Category:** process-gap
**Severity:** LOW (single LOW finding; but pattern is subtle and load-bearing for Rust API surface)

### What happened

Extraction-validation pass 5 found a behavioral-locus error: `tick()` was documented as raising `GraphRecursionError` when the recursion limit is exceeded. The actual behavior is: `tick()` sets `status = out_of_steps` and returns `False`. The outer `invoke` loop detects the `out_of_steps` status and converts it to an error/exception.

This distinction is load-bearing for the Rust API design. If `tick()` were specified as raising an exception, a Rust implementer would correctly model it as `-> Result<bool, GraphRecursionError>`. With the correct behavior, the Rust API should be `-> bool` with error propagation handled by the outer loop only.

The corpus accurately documented WHAT happened (recursion limit error) but attributed the locus of the behavior to the wrong function layer.

### Why it matters

Behavioral-locus errors are harder to catch than factual errors because they are locally plausible — the overall behavior is correct, only the WHERE is wrong. In a multi-layer system like pregel (tick → invoke → run), attributing error-raising to the inner tick() vs the outer invoke() produces different API contracts that are both internally consistent but only one is correct.

### Codification applied

For pass 6 and subsequent passes, a behavioral-locus precision guardrail is active:

1. **Locus identification mandatory:** When documenting behavior that spans multiple layers (inner function → outer loop → caller), explicitly identify which layer owns the observable behavior — return value, error raise, status mutation.
2. **API-surface implication check:** For any claim about error-raising behavior in graph internals, check whether the Rust API implication matches (does this become a `Result<T, E>` or a `bool` + outer error conversion?).
3. **Multi-layer verification:** When a function both mutates state AND has a caller-visible result, verify both independently — the state mutation locus and the error-propagation locus may differ.

### Follow-up

Fold the behavioral-locus precision guardrail into the validate-extraction agent prompt upstream — add as a mandatory verification step for any claim about error-raising behavior in multi-layer graph internals. Session-review target: same batch as counting-methodology and propagation gaps.

---

## Lesson: PROCESS-GAP — Semantic-Precision Guardrail for Summary Words in Behavioral Docs (2026-07-13)

**Source:** Extraction-validation pass 6 (burst 14)
**Category:** process-gap
**Severity:** LOW (single LOW finding; but pattern is load-bearing for Rust implementation invariants)

### What happened

Extraction-validation pass 6 found that `core/behavioral-intent.md` described `merge_dicts` identity-key semantics as "last-wins". The actual behavior is: keep-left-when-equal (left value wins when both channels carry identical keys) / concatenate-when-different (values appended when keys differ).

"Last-wins" is a plausible shorthand that captures the general concept of merging overriding prior state — it reads naturally in the context of a dict merge operation. But it encodes the wrong invariant. A Rust implementer building `merge_dicts` from the "last-wins" description would implement an overwrite rule for all key collisions, when the actual behavior distinguishes equal-value collisions (keep-left) from different-value collisions (concatenate).

This is the same failure class as the pass-5 behavioral-locus finding: locally plausible, globally wrong. The summary word "last-wins" is not a lie in isolation; it becomes a specification error when its specificity is insufficient to disambiguate behavior.

### Why it matters

Summary words (last-wins, always, never, all, any, overwrite) carry semantic load in behavioral specifications. When they diverge from the actual branch logic — even subtly — they propagate into Rust implementations as silent semantic divergence. Unlike factual errors (wrong count, wrong type name), semantic-precision errors do not fail tests unless there is a test vector that exercises the disambiguating case. A Rust `merge_dicts` that overwrites on equal values passes all tests derived from summary descriptions but fails on equal-value merge inputs.

### Codification applied

For pass 7 and subsequent passes, a semantic-precision guardrail is active:

1. **Summary-word verification mandatory:** When a behavioral description uses summary words (last-wins, first-wins, always, never, overwrite, append, merge), verify the word against actual branch logic in the reference source — not against intuition about what the operation "should" do.
2. **Disambiguation test:** For any summary that describes collision resolution or ordering behavior, ask: "Is there a case where this summary produces a different outcome than the actual code?" If yes, the summary requires a more specific description.
3. **Rust-implication check:** For any behavioral claim about merge, update, or collision resolution, verify the Rust API implication — what invariant does the implementer derive from this description?

### Follow-up

Add semantic-precision guardrail to the validate-extraction agent prompt upstream — co-batch with behavioral-locus precision guardrail and propagation sweeps for session-review. All three share the common pattern: locally plausible, load-bearing for Rust API surface, resistant to casual review.

---

## Lesson: PROCESS-GAP — Notes-Without-Edits: Correction Notes Do Not Fix Sibling Table Cells (2026-07-13)

**Source:** Extraction-validation pass 6 (burst 14)
**Category:** process-gap
**Severity:** LOW (single LOW finding; pattern extends the cross-document propagation discipline to intra-document cases)

### What happened

Extraction-validation pass 6 found that `core/module-inventory.md` main table still showed `block_translators: 7 files`. A correction NOTE had been added in a separate section of the same document (a deepening section or analysis note) identifying the correct count as 8. The NOTE was written as if the correction had been applied; the main table cell was never updated.

The pass-7-deepening correction NOTE existed. The physical edit to the table never happened.

### Why it matters

This is a specific and recurring failure shape: an agent adds a correction note documenting what should be fixed, then does not apply the physical edit to the table or structured field that actually needs updating. The note creates false confidence that the correction is done. The corpus now contains a note that says the count is 8 and a table that says the count is 7. A reader who reaches the table first sees 7; only a reader who also finds the note sees the discrepancy. The canonical structured data (the table) is wrong; the discursive text (the note) is right. Downstream agents and implementers read tables, not correction notes.

This failure shape is distinct from cross-document propagation (TD-VSDD-060), which concerns corrections applied to one file but not propagated to sibling files. Notes-without-edits concerns corrections noted but not applied within the same file, and specifically the pattern of notes in discursive sections while structured data (tables, code blocks) goes uncorrected.

### Codification applied

For pass 7 and subsequent passes, a notes-without-edits sweep is mandatory:

1. **Deepening-note sweep as first stratum:** Before examining new behavioral strata, grep all documents for correction notes, "TODO:", "FIXME:", "NOTE:", "CORRECTION:", "should be", and similar markers that indicate a correction was recognized but may not have been applied to the surrounding structured data.
2. **Intra-document table audit:** When a correction note refers to a count, type, or field value, confirm that all table cells and structured data fields in the same document reflect the corrected value, not just the prose.
3. **Notes are not corrections:** A note that says "the correct value is X" is not a correction — it is evidence that a correction is needed. The correction is only complete when the structured data reflects X.

### Follow-up

Add deepening-note sweep as a mandatory first-stratum in the validate-extraction agent prompt. This sweep directly catches the pass-6 failure shape and the broader class of "correction recognized, physical edit skipped" failures. Co-batch with counting-methodology, propagation, behavioral-locus, and semantic-precision guardrails in session-review upstream agent prompt hardening.

---

## Lesson: PROCESS-GAP — Package-Attribution Guardrail (2026-07-13)

**Source:** Extraction-validation pass 7 (burst 15)
**Category:** process-gap
**Severity:** MEDIUM (single MEDIUM finding; inflated port scope — LoggingCallbackHandler wrongly attributed to langchain-core)

### What happened

Extraction-validation pass 7 found that `LoggingCallbackHandler` was attributed to `langchain-core` in the corpus. The class exists only in `langchain_classic` (the legacy `langchain` package, `langchain/callbacks/manager.py`). It does not exist in `langchain-core` at the pinned tag (langchain-core v0.3.x). As a result, the ferrochain-core port scope had been inflated to include a class that is not part of core at all.

The correct core callback/tracer roster is: `LangChainTracer`, `ConsoleCallbackHandler`, `FunctionCallbackHandler`, `RootListenersTracer`, `EvaluatorCallbackHandler`, `RunCollectorCallbackHandler`. `LoggingCallbackHandler` belongs in a ferrochain-classic compatibility layer, not in ferrochain-core.

The companion LOW finding: `BaseCallbackHandler` was documented with 4 ignore flags (`ignore_llm`, `ignore_chain`, `ignore_agent`, `ignore_retriever`). The actual count is 7 — `ignore_retry`, `ignore_chat_model`, and `ignore_custom_event` were missing. A Rust `CallbackHandler` trait derived from the 4-flag description would have lacked 3 opt-outs, producing behavioral divergence on retry and custom-event callbacks.

### Why it matters

Misattribution of a class to the wrong package has two consequences: (1) wrong port scope (implementers build what was never in the package), and (2) wrong exclusion scope (things that were in the package get missed because the investigator finds the class somewhere and stops looking). The failure is especially pernicious in the langchain ecosystem because `langchain-core`, `langchain` (classic), `langchain-community`, and other packages share naming conventions and sometimes re-export each other's symbols. A class that "seems core-like" is not necessarily in langchain-core.

The propagation audit this pass found ZERO stale values for the first time across all passes — extinguishing the corpus-wide residue failure class. Package-attribution is now the new leading failure class.

### Codification applied

For pass 8 and subsequent passes, a package-attribution guardrail is active (6th guardrail):

1. **Package-attribution check mandatory:** Any class, function, or type attributed to a specific package MUST be verified to exist in that package at the pinned tag — not just "in the ecosystem." Presence in any langchain-* package is not evidence of presence in langchain-core.
2. **Re-export disambiguation:** When a class is re-exported across packages (e.g., langchain imports from langchain-core), attribute it to the defining package (where `class Foo:` is defined), not the importing package.
3. **Scope inflation check:** For every callback/tracer/handler attributed to ferrochain-core scope, confirm the defining module is `langchain_core`, not `langchain` (classic), `langchain_community`, or another package.
4. **Exhaustive flag/method inventory:** For abstract base classes (like `BaseCallbackHandler`), enumerate ALL abstract/optional fields and flags from the actual class definition — do not derive the count from usage examples or doc summaries which typically show the common subset.

### Follow-up

Add the package-attribution guardrail to the validate-extraction agent prompt upstream as the 6th guardrail — co-batch with all prior guardrails in session-review prompt hardening. The full 6-guardrail set is now: (1) AST-based counting, (2) cross-document propagation sweep, (3) behavioral-locus precision, (4) semantic-precision summary-word verification, (5) deepening-note sweep, (6) package-attribution verification.

---

## PROCESS-GAP: Scope-Label Matching — 7th Guardrail

**Category:** Validator counting methodology
**Discovered:** Certification pass 1 (burst 18, 2026-07-13)
**Severity when violated:** MEDIUM

### What happened

Certification pass 1 found 2 MEDIUM corrections — both were the exhaustive sweep's own over-corrections. The exhaustive sweep's M-05 and M-06 re-counted `libs/sdk-py/langgraph_sdk` and `libs/cli/langgraph_cli` rows using the broader `libs/sdk-py` and `libs/cli` directory trees (63 files / 20,787 LOC and 46 files / 9,997 LOC respectively). The correct counts, measured from the labeled package directories, are 45 / 18,728 and 19 / 8,383. Every other row in module-inventory.md counts the package sub-directory; these two rows were recounted from the wrong scope.

The exhaustive sweep intended to correct loose estimates (`~50/18,728` and `~25/8,383`) and the corrected totals were directionally correct for their broader scope, but inconsistent with the scope the row labels denote.

### Why it matters

A table row that says `libs/sdk-py/langgraph_sdk` implicitly defines scope as "the langgraph_sdk Python package." Counting files from the parent `libs/sdk-py/` directory includes setup.py, examples/, scripts/, and test fixtures — content that does not belong in the "package code" scope claimed by the label. This scope mismatch produces counts that are systematically inflated and inconsistent with companion rows, misleading implementers about actual package size.

Conversely, a corrector who reads only the broader-tree number and trusts it without cross-checking the scope of the label will propagate an inaccurate figure with high confidence.

### Codification — 7th Guardrail: SCOPE-LABEL MATCHING

For every numeric row (LOC, file count, etc.) in a module inventory table:

1. **Resolve the label's scope FIRST:** Before re-counting, determine exactly what filesystem path the row label denotes. A label like `libs/sdk-py/langgraph_sdk` means the package directory, not the libs/ parent.
2. **Count from the labeled scope, not the nearest convenient path:** If the label says `langgraph_sdk`, run `find .reference/langgraph/libs/sdk-py/langgraph_sdk -name "*.py"` — not `find .reference/langgraph/libs/sdk-py -name "*.py"`.
3. **Cross-check scope consistency:** After re-counting, verify the corrected value is consistent with what companion rows in the same table count (all package dirs, or all libs/ trees — must match across rows).
4. **Document the scope in the correction comment:** Every `[validation-*]` comment must state both the measured path and the count, e.g.: `find .../langgraph_sdk -name "*.py" | wc -l = 45, xargs wc -l = 18,728`.
5. **Certifier scope check:** In certification passes, when reverifying a row previously corrected, check whether the corrector used the right scope — not just whether the arithmetic is correct for the scope they used.

### The full 7-guardrail set

1. AST-based counting (never grep/eyeballing for code constructs)
2. Cross-document propagation sweep (find all locations that must reflect the same fact)
3. Behavioral-locus precision (describe behavior at the execution locus, not a secondary description)
4. Semantic-precision summary-word verification (verify superlatives, totals, and summary claims against base data)
5. Deepening-note sweep (verify items marked for deeper investigation were actually investigated)
6. Package-attribution verification (any class attributed to a package must exist in that package at the pinned tag)
7. Scope-label matching (every numeric row must be counted from exactly the scope its label denotes)

---

## Lesson: PROCESS-GAP — Dependency-Constraint Completeness — Guardrail 7b (2026-07-13)

**Source:** 3-CLEAN certification pass 3 (burst 20)
**Category:** process-gap
**Severity:** LOW (single LOW finding; but pattern is load-bearing for provider-crate risk posture)

### What happened

Certification pass 3 found that `partners/dependency-disposition.md` §2 anthropic row quoted the constraint as `anthropic>=0.96`. The actual pyproject.toml specifies `anthropic>=0.96.0,<1.0.0`. The upper bound `<1.0.0` was omitted.

The upper bound is not a formatting detail — it is a contract signal. A `<1.0.0` cap explicitly communicates that the upstream package is expected to ship a breaking-change v1.0 that is not yet compatible, and that the integrator has chosen to pin below it rather than track HEAD. Omitting this bound in a disposition row misrepresents the stability posture: a reader of the disposition table sees an open-ended ">=0.96" requirement where the actual source establishes a bounded window.

### Why it matters

Dependency rows in disposition documents feed directly into Cargo.toml planning and version-selection decisions. A disposition that omits an upper bound gives implementers false latitude — they may choose a version within the unconstrained range that violates the upstream maintainer's stated compatibility contract. For provider crates (openai, anthropic, ollama) where breaking changes are frequent in pre-1.0 packages, this constraint completeness is risk-relevant.

### Codification applied — Guardrail 7b: DEPENDENCY-CONSTRAINT COMPLETENESS

For certification passes and exhaustive sweeps, a dependency-constraint completeness guardrail is now active:

1. **Full verbatim constraint required:** Every dependency row must quote the full constraint expression from the source pyproject.toml / requirements file, including both lower AND upper bounds, exclusion markers (`!=`), and environment markers. Omission of any bound is a finding.
2. **Bounds are contract:** An upper bound (`<1.0.0`, `<=2.3`, `!=1.5`) is not optional metadata — it is the upstream project's statement about compatibility. Verify it is present in the disposition row.
3. **Pass 4 opening sweep:** Certification pass 4 begins with an exhaustive verbatim sweep of every dependency row corpus-wide (all 7 semport areas). This bounded check permanently closes the dependency-constraint completeness class.

### The full 8-guardrail set (after 7b)

1. AST-based counting (never grep/eyeballing for code constructs)
2. Cross-document propagation sweep (find all locations that must reflect the same fact)
3. Behavioral-locus precision (describe behavior at the execution locus, not a secondary description)
4. Semantic-precision summary-word verification (verify superlatives, totals, and summary claims against base data)
5. Deepening-note sweep (verify items marked for deeper investigation were actually investigated)
6. Package-attribution verification (any class attributed to a package must exist in that package at the pinned tag)
7. Scope-label matching (every numeric row must be counted from exactly the scope its label denotes)
7b. Dependency-constraint completeness (dependency rows must quote full constraint expressions verbatim; bounds are contract)

### Follow-up

Pass 4 opens with an exhaustive verbatim sweep of every dependency row across all 7 semport areas. This bounded check closes the entire dependency-constraint class permanently. After pass 4, fold guardrail 7b into the validate-extraction agent prompt upstream alongside the full 7-guardrail set.
