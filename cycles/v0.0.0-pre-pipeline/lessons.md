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
