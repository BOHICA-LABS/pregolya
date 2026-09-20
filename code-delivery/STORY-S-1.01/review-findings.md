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
| 10 | 7e46930 | 3 MED + 2 LOW + 3 OBS | no | no | 0/3 | MED-001 EC-007 scope gap; MED-002 phantom §Components; MED-003 missing API in api-surface.md; LOW-001 ProblemDetail Deserialize untested; LOW-002 grammar |
| push | 42f6f86 | — | — | — | — | MED-001/002/003 + LOW-001/002 fix burst; OBS-001 adjudicated; streak reset to 0/3 per frozen-HEAD rule; pass-11 dispatched on new frozen HEAD (post-push) |
| 11 | 42f6f86 | 2 MED + 2 LOW + 3 OBS | no | no | 0/3 | Full cascade (MED present); MED-001 ADR-010 §Components anchor unswept; MED-002 api-surface static method doc error; LOW-001 default_retry_hint no story-spec trace; LOW-002 to_problem() unsanctioned panic path; OBS-001 Component enum doc anchor; OBS-002 demo version pins; OBS-003 deferred to wave gate |
| push | b1d70d9 | — | — | — | — | MED-001+MED-002 closed by architect (6dc5724); LOW-001 closed by story-writer (d86744f); LOW-002+OBS-001+OBS-002 closed by implementer (b1d70d9); OBS-003 deferred to wave gate; streak reset to 0/3 per frozen-HEAD rule; pass-12 dispatched on new frozen HEAD |

## Finding Detail — Pass 11

**MED-001**: ADR-010 §Components anchor unswept.

ADR-010 contains a §Components section anchor reference that was not swept when the
component-binding invariant was updated in the pass-10 fix burst. The anchor survived
in prose that cited it without a corresponding target section. Fix: architect burst on `factory-artifacts` (`6dc5724`) sweeps the stale
§Components anchor reference from ADR-010.

**MED-002**: api-surface.md static method doc error.

`api-surface.md` described `default_retry_hint` as a static method when it is a free
function. The method/function distinction is load-bearing for consumers reading the
API surface catalog. Fix: architect burst on `factory-artifacts` (`6dc5724`) corrects the description to
"free function" and aligns the calling convention notes.

**LOW-001**: `default_retry_hint` entry in api-surface.md has no story-spec trace.

The symbol was added to `api-surface.md` in the pass-10 fix burst without a traceability
citation back to the story spec (S-1.01 or a BC). Fix: story-writer commit `d86744f`
adds the traceability anchor (S-1.01 §AC-003) to the api-surface.md entry.

**LOW-002**: `to_problem()` unsanctioned panic path.

`to_problem()` contained a `panic!` invocation that was not enumerated in the BC-2.14.002
`# Panics` section and not covered by the EC taxonomy. The path was reachable under
an undocumented precondition violation. Fix: implementer commit `b1d70d9` on
`feature/S-1.01` replaces the panic with a structured error return and adds the
corresponding BC-2.14.002 `# Panics` entry covering the precondition.

**OBS-001**: Component enum doc anchor.

The `Component` enum rustdoc contained a `[see §Components]` anchor reference that
points nowhere (no `§Components` section exists in the doc). Fix: implementer commit
`b1d70d9` removes the phantom anchor reference and replaces it with inline prose.

**OBS-002**: Demo version pins.

Demo script referenced unpinned crate version numbers that have since been superseded.
Fix: implementer commit `b1d70d9` updates the demo version pins to match the
current `Cargo.lock`.

**OBS-003**: Deferred to wave gate.

OBS-003 is out of scope for S-1.01 and requires cross-story context unavailable in this
cascade. Adjudicated: deferred to wave gate per orchestrator direction.

Closure: MED-001+MED-002 CLOSED (architect `6dc5724`). LOW-001 CLOSED (story-writer `d86744f`).
LOW-002+OBS-001+OBS-002 CLOSED (implementer `b1d70d9`). OBS-003 DEFERRED to wave gate.
Ceremony: full cascade per TD-RECORDS-MICRO-BURST-001 (MED findings present).
Per frozen-HEAD rule (BC-5.39.001), push of fix burst resets streak to 0/3.
New frozen HEAD: `b1d70d9`. Pass-12 dispatched.

## Finding Detail — Pass 10

**MED-001**: EC-007 scope clause missing from BC-2.14.001.

BC-2.14.001 lacked an explicit EC-007 scope clause tying the component-binding invariant
to the `new()`/`to_problem()` boundary. Finding anchors to BC-2.14.001 §EC-007.

Fix pt1: BC-2.14.001 §EC-007 — scope clause added with S-1.02 deferral anchor.
Fix pt2: `new()` and `to_problem()` rustdoc scope notes added in commit `42f6f86` on
`feature/S-1.01`.

**MED-002**: Phantom §Components anchor reference in api-surface.md.

`api-surface.md` contained a §Components section anchor reference that did not exist,
producing a phantom link in the Error Catalog. Commit `f914400` on `factory-artifacts`
fixes the anchor.

**MED-003**: Missing API symbols in api-surface.md.

`api-surface.md` omitted `http_status`, `ProblemDetail`, `PROBLEM_JSON_CONTENT_TYPE`, and
`default_retry_hint` from the public API surface listing. All four symbols added.

**LOW-001**: ProblemDetail round-trip deserialization untested.

`ProblemDetail` lacked a round-trip deserialization assertion. Commit `42f6f86` adds the
assertion to the test suite.

**LOW-002**: Grammar defects in BC-2.14.002.

Minor grammar issues in BC-2.14.002 prose. BC-2.14.002 §Prose grammar fixes applied.

**OBS-001**: Citation form.

Both citation forms are correct in context; adjudicated — no change required.

Closure: MED-001/002/003 + LOW-001/002 CLOSED. OBS-001 adjudicated (no change).
Per frozen-HEAD rule (BC-5.39.001), push of fix burst resets streak to 0/3.
Pass-11 to be dispatched on new frozen HEAD (post-push of feature/S-1.01).

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

CLEAN(strict) streak: 0/3 — reset by push of fix burst (new frozen HEAD `b1d70d9`).
BC-5.39.001 frozen-HEAD rule: streak advances only on consecutive CLEAN(strict) passes
against unchanged HEAD. Fix burst from pass-11 landed as implementer commit `b1d70d9`
on `feature/S-1.01`; streak resets to 0/3 on push per frozen-HEAD rule.

Current frozen HEAD: `b1d70d9`
Current streak: 0/3 on new frozen HEAD.

Deferred D-001: BC `wave: 0` frontmatter inconsistency (13 BCs corpus-wide, no
implementation impact, deferred to phase-5 spec-steward).

Deferred OBS-003: out of scope for S-1.01; deferred to wave gate per orchestrator direction.

Next: pass-12 dispatched on frozen HEAD `b1d70d9`.
