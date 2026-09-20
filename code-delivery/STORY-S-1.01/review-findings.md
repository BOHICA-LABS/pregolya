# Review Findings — S-1.01 (PR-Level Cascade)

Story: S-1.01 — PregolyaError struct
Cascade protocol: BC-5.39.001 3-CLEAN (PR-level)
Feature branch: feature/S-1.01

## Convergence Trajectory

| Pass | Head SHA | Findings | CLEAN(strict) | CLEAN(PR-merge) | Streak | Notes |
|------|----------|----------|---------------|-----------------|--------|-------|
| 1 | — | CRIT/HIGH/MED present | no | no | 0/3 | |
| 2 | — | CRIT/HIGH/MED present | no | no | 0/3 | |
| 3 | — | CRIT/HIGH/MED present | no | no | 0/3 | |
| 4 | — | CRIT/HIGH/MED present | no | no | 0/3 | |
| 5 | — | CRIT/HIGH/MED present | no | no | 0/3 | |
| 6 | — | 0 | yes | yes | 1/3 | First CLEAN(strict) pass |
| 7 | 0aed506 | 1 LOW | no | yes | 1/3 | RECORDS-ONLY (TD-RECORDS-MICRO-BURST-001); F-P7-001 closed by commit 66fd4c8 |
| 8 | 66fd4c8 | 1 MED + 1 LOW + 2 OBS | no | no | 0/3 | F-01 (MED) E-TEST fixture codes violate EC-007; F-02 (LOW) missing AC-005 external assert_impl_all. Fix: commit 7e46930. |
| push | 7e46930 | — | — | — | — | F-01+F-02 fix burst; CI green (19/19); streak reset to 0/3 per frozen-HEAD rule; pass 9 dispatched |
| 9 | 7e46930 | 0 | yes | yes | 1/3 | First CLEAN(strict) on HEAD 7e46930; pass 10 dispatched |

## Finding Detail — Pass 9

No findings. Pass 9 is CLEAN(strict) and CLEAN(PR-merge) on frozen HEAD `7e46930`.
Streak advances to 1/3. Pass 10 dispatched against same frozen HEAD.

## Finding Detail — Pass 8

**F-01** (MED): E-TEST fixture error codes violate EC-007.

Test fixtures used error codes that did not conform to the EC-007 emit-time binding
constraint established in BC-2.14.002. The fix in commit `7e46930` corrects the
fixture codes to use valid EC-007-bound values.

**F-02** (LOW): Missing AC-005 external `assert_impl_all!` assertion.

The external compile-fail gate for `assert_impl_all!` required by AC-005 was absent.
Commit `7e46930` adds the assertion to the external test harness.

Closure: CLOSED — both findings fixed in commit `7e46930`. CI green (19/19 tests pass).
Per frozen-HEAD rule (BC-5.39.001), push of fix burst resets streak to 0/3.
Pass 9 dispatched against new frozen HEAD `7e46930`.

## Finding Detail — Pass 7

**F-P7-001** (LOW): `to_problem()` `# Panics` rustdoc missing EC-007 emit-time binding panic path.

BC-2.14.002 §EC-002 enumerates two panic paths for `to_problem()`:
- EC-002: Custom-name panic (documented before pass 7)
- EC-007: emit-time binding panic, fires for any component variant when `component` is
  reassigned post-construction (missing before pass 7)

Fix: implementer added second paragraph to `to_problem()` `# Panics` section in commit
`66fd4c8` on branch `feature/S-1.01`. 58 tests pass. Docs compile without warnings.

Closure: CLOSED — fix committed, records micro-burst complete per TD-RECORDS-MICRO-BURST-001.

## Status

CLEAN(strict) streak: 1/3 — first CLEAN(strict) pass on frozen HEAD `7e46930` (pass 9).
BC-5.39.001 frozen-HEAD rule: streak advances only on consecutive CLEAN(strict) passes
against unchanged HEAD. Passes 10 and 11 required for convergence.

Deferred D-001: BC `wave: 0` frontmatter inconsistency (13 BCs corpus-wide, no
implementation impact, deferred to phase-5 spec-steward).

Next: adversary pass 10 on frozen HEAD `7e46930`.
