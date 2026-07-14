---
document_type: adversarial-review-pass
phase: 1d
pass: 22
verdict: NOT CLEAN
findings_count: 1
high_count: 1
consecutive_clean: 0
required_clean: 3
trajectory: "...→3→1→1"
timestamp: 2026-07-14T00:00:00Z
---

# Adversarial Review Pass 22 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (1 HIGH). Counter reset: 0/3 consecutive clean.

---

## F-P22-01 [HIGH] — Pass-21 CAP Relocation Left 16 BC Files with Dangling capabilities-p1-p2.md Anchors (S-7.01 Reverse-Anchor Regression)

**Finding class (NEW):** S-7.01 partial-fix regression — reverse-anchor dimension.

**Scope:** ss-10 (BC-2.10.001–004 ×4), ss-11 (BC-2.11.001–006 ×6), ss-14 (BC-2.14.001–006 ×6) — 16 files total, 2 sites each.

**Finding:** Pass-21 correctly relocated CAP-012, CAP-013, and CAP-016 from `capabilities-p1-p2.md` into `capabilities-p0.md`, but the reverse anchors in the 16 constituent BC files were not updated. Both anchor sites per file retained the stale source attribution:

| Site | Pattern (stale) |
|------|----------------|
| Frontmatter `inputs:` entry | `.factory/specs/domain-spec/capabilities-p1-p2.md` |
| Capability Anchor Justification cell | `per capabilities-p1-p2.md §CAP-012` / `§CAP-013` / `§CAP-016` |

Because the Capability Anchor Justification cell is the S-7.01 compliance surface (adversary policy 5 — Semantic Anchoring Audit), citing a stale source file fails the verbatim-citation obligation: the authoritative location for CAP-012/013/016 is now `capabilities-p0.md`, not `capabilities-p1-p2.md`.

**Impact:** Any agent following S-7.01 policy and reading the justification cell to locate the capability definition would open `capabilities-p1-p2.md`, which no longer contains CAP-012/013/016, and conclude the anchor is broken. Drift between the source-of-truth file and the 16 BC justification cells is HIGH severity per the adversary-policy preamble.

**Fix plan:**
1. In all 16 BC files (ss-10/BC-2.10.001–004, ss-11/BC-2.11.001–006, ss-14/BC-2.14.001–006): replace `capabilities-p1-p2.md` → `capabilities-p0.md` in BOTH the frontmatter `inputs:` entry (preserving any `#CAP-0NN` fragment) AND the Capability Anchor Justification cell.
2. Re-grep: zero BC references to `capabilities-p1-p2.md` for CAP-012/013/016.
3. Straggler sweep: grep prd.md, architecture/, prd-supplements/ for `capabilities-p1-p2.md` near CAP-012/013/016 mentions; fix any found.
4. Confirm that BCs for CAPs still residing in capabilities-p1-p2.md (ss-08/09/12/13/15/16/17) are NOT touched.
5. Input-hash refresh for the 16 files is state-manager's responsibility at commit (inputs arrays changed).

---

## Tier Census — PASS (19/19 MATCH)

Tier dimension fully converged post Pass-21 fix. P0-count arithmetic verified unchanged: **48 P0 / 30 P1 / 8 P2** BCs. All 19 CAPs map to consistent tier across L2-INDEX, PRD §2 section headers, and BC RTM frontmatter.

| CAP | L2 tier | PRD §2 tier | BC RTM tier | Match |
|-----|---------|-------------|-------------|-------|
| CAP-001 through CAP-019 (19 CAPs) | — | — | — | PASS (all 19 consistent) |

---

## DI/NE Censuses — CLEAN

| Census | Gate | Result |
|--------|------|--------|
| Domain Invariant (DI-NNN) coverage | Every DI-NNN cited in at least one BC Traceability L2 Invariants field | PASS — 0 orphan invariants |
| Negative Examples (NE-NNN) | All NE citations in BC bodies resolve to a named NE in comparative assessment | PASS — 0 dangling NE refs |

---

## Novel Probes (2) — MIXED

| Probe | Target | Result |
|-------|--------|--------|
| CAP relocation reverse-anchor sweep | 16 BC files in ss-10/11/14 — inputs: + justification cells cite capabilities-p0.md post-Pass-21 fix | F-P22-01 (see above) — FAIL |
| Untouched-subsystem stability | ss-08/09/12/13/15/16/17 BC files still cite capabilities-p1-p2.md for their respective CAPs | PASS — 104 reference lines confirmed intact |
