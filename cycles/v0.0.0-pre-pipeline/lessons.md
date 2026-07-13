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
