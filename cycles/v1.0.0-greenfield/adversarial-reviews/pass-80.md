---
document_type: adversarial-review
phase: 1d
pass: 80
verdict: NOT CLEAN
finding_count: 1
finding_severity: [MED]
novelty: MEDIUM
novelty_class: error-code-mis-anchor-hedge-shielded
sibling_checks: "3/3 PASS"
timestamp: 2026-07-15T00:00:00Z
---

# Adversarial Review — Pass 80 (Phase 1d)

**Verdict:** NOT CLEAN — 1 finding (MED), FIXED same burst.

---

## F-P80-01 (MED, FIXED) — BC-2.17.002 EC-002 Wrong Error Code (E-GRAPH-007 → E-GRAPH-008)

**Location:** `.factory/specs/behavioral-contracts/ss-17/BC-2.17.002.md` — EC-002, TV-004

**Finding:** BC-2.17.002 is the least-visited ss-17 fuzz BC. Its EC-002 (Graph with Zero
Nodes) cited error code `E-GRAPH-007` (UnknownChannelKey — runtime unregistered-write-key
error). The correct code for a zero-node / empty-graph degenerate topology is `E-GRAPH-008`
(UnreachableGraph), which is mandated by BC-2.02.001 EC-002/TV-003 for the "no entry edge
from START" failure class. The message `"empty graph definition"` in the prior version
matched no taxonomy form; the taxonomy form is `UnreachableGraph: <reason>`.

The `"or similar"` hedge on the error code assertion shielded this mis-anchor from every
prior sweep: no pass needed to confirm the exact code, only that the code was "similar" to
E-GRAPH-007. This is a standing instance of the hedge-shielded class.

**Fix applied (BC-2.17.002 v1.1):**
- EC-002 error code corrected: `E-GRAPH-007` → `E-GRAPH-008`.
- Message aligned to taxonomy form: `UnreachableGraph: empty graph — no entry edge from START`.
- `"or similar"` hedge removed from code assertion — exact `E-GRAPH-008` is now required.
- Message-detail flexibility preserved per fuzz-oracle semantics: the fuzz oracle asserts the
  EXACT error code discriminant; message-detail text may vary by implementation. This is the
  correct fuzz-oracle posture (code is the semantic contract; message is human-readable detail).

**Full ss-17 error-code citation audit (same burst):**
- BC-2.17.002: all other ECs/TVs clean — code-free or correct-domain assertions; only EC-002
  required correction. No other ss-17 EC mis-anchors found.
- BC-2.17.001: zero E-NNN error code citations (Kani harness outputs only — compile-error and
  proof-failure returns, not FerrochainError codes). No bump warranted.

**BC-2.17.002 version bumped to v1.1.**

---

## Sibling-Checks (3/3 PASS)

1. **BC-2.10.003 v1.4 currency** — frontmatter version "1.4" confirmed; pass-79 fix intact.
2. **BC-2.04.003 v1.3 corrigendum** — v1.3 corrigendum entry present; live content untouched;
   pass-79 fix intact.
3. **9-file version-currency scan** — pass-78/pass-79 defect class (frontmatter-currency
   mismatch) does not recur in the 9-file scan. All scanned files: frontmatter version =
   changelog head version. PASS.

---

## Clean Verifications

**Baselines confirmed:**
- 95 BCs = 48 P0 / 39 P1 / 8 P2 (reconciled).
- DI 14/14 orphan-free.
- VP arithmetic + bodies match.
- Census 85 = 43+16+26.
- 6 RetryHint divergences (BC-anchored, standing).

**Gate rotation — passes 80:** Gates #12, #13, #14, #15, #17, #18 rotated — all CLEAN except
F-P80-01 (caught by deep ss-16/ss-17 read, not a named gate; the deep-read probe was the
detection vector).

**Free probes:**
- PRD RTM ≥10-row audit: CLEAN.
- Holdout domains A/C freshness check: CLEAN (domain briefs intact, no stale cross-references).
- NFR-catalog ↔ VP-INDEX/BC-2.17.001 harness names match: CLEAN.
- ss-16/ss-17 deep read: F-P80-01 found here (least-visited BC in ss-17 fuzz set).

**OBS (non-resetting):** CONCURRENCY error category description in the error taxonomy reads
graph-channel-narrower than server-layer usage (E-SERVER-007/012/015 also carry CONCURRENCY).
Technically valid — the description covers the core class; the server-layer codes are a
broader application. Description-scope note only; no BC or taxonomy body change warranted.
Carries forward as a standing OBS.

---

## Novelty Assessment

**Novelty:** MEDIUM. **Class:** error-code-mis-anchor-hedge-shielded. This is a recognized
class (hedge-shielded wrong code) applied to the least-visited BC in the fuzz subsystem.
The "or similar" hedge pattern is the vector; prior passes that swept ss-17 name-presence only
would not have caught a wrong-but-similar code under a hedge.

**Trajectory:** →1 (P1D-80). **Convergence counter:** 0/3 (reset by this finding).
