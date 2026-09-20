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
| 12 | b1d70d9 | 1 MED + 2 LOW | no | no | 0/3 | MED-001 BC-INDEX DI-010 missing from BC-2.14.001 row; LOW-001 demo §Section AC-005 attribution + println gap; LOW-002 api-surface §Error Type mixed receiver types — Category sub-header needed. Full cascade (MED-001 present). |
| push | f339f9d | — | — | — | — | MED-001 closed by state-manager (c628d4e, BC-INDEX §BC-2.14.001 DI-010 column); LOW-001 closed by implementer (f339f9d); LOW-002 closed by architect (379a81d); streak reset to 0/3 per frozen-HEAD rule; pass-13 dispatched on new frozen HEAD |
| 13 | f339f9d | 2 MED + 2 LOW | no | no | 0/3 | MED-001 EC-006 strip_prefix guard zero test coverage; MED-002 BC panic enumeration "two" vs three shipped paths + story §EC-007 asymmetry; LOW-001 fn F8-04 → footnote F8-04; LOW-002 Category::default_retry_hint no AC-016 no demo. Full cascade (MED findings present). |
| push | 639d12a | — | — | — | — | MED-001 + LOW-002 closed by implementer (639d12a; 59 tests pass); MED-002 closed by product-owner (85eb142, BC-2.14.001 §Panics + BC-2.14.002 §Panics); LOW-001 + LOW-002 AC-016 closed by story-writer (8601821, story §EC-007); streak reset to 0/3 per frozen-HEAD rule; pass-14 dispatched on new frozen HEAD |
| 14 | 639d12a | HIGH-001 + MED-001 | no | no | 0/3 | HIGH-001 AC-016 phantom Category variants (correct 3-variant Later partition: Rate/Timeout/Transport); MED-001 demo header "15 acceptance criteria" stale after AC-016 addition. Full cascade (HIGH + MED present). |
| push | 2b9371d | — | — | — | — | HIGH-001 closed by story-writer (a3ae216, story §AC-016 §Later-partition corrected to 3 variants; story v2.4); MED-001 closed by demo-recorder (demo header 15→16 acceptance criteria); streak reset to 0/3 per frozen-HEAD rule; pass-15 dispatched on new frozen HEAD |
| 15 | 2b9371d | 1 LOW | no | yes | 0/3 | RECORDS-ONLY (TD-RECORDS-MICRO-BURST-001); LOW-001 AC-016 demo block missing Category::Transport; exhaustive-enumeration convention not followed; streak NOT advanced (CLEAN(strict)=no, records-only) |
| push | bdefb70 | — | — | — | — | LOW-001 closed by demo-recorder (full 14-variant exhaustive enumeration matching AC-003/AC-011 convention); records-lint.sh PASS=5 WARN=0 FAIL=0; streak reset to 0/3 per frozen-HEAD rule; pass-16 dispatched on new frozen HEAD |

## Finding Detail — Pass 15

**LOW-001**: AC-016 demo block missing Category::Transport; exhaustive-enumeration convention not followed.

The AC-016 demo block enumerated Category variants but omitted Category::Transport, leaving
the demo coverage incomplete relative to the full 14-variant enum. The exhaustive-enumeration
convention established by AC-003 and AC-011 demo blocks requires all variants to be
explicitly covered. Omitting Category::Transport created a traceability gap between the
demo evidence and the AC-016 acceptance criterion. Fix: demo-recorder commit `bdefb70` on
`feature/S-1.01` promotes the AC-016 demo block to a full 14-variant exhaustive enumeration
matching the AC-003/AC-011 convention. records-lint.sh PASS=5 WARN=0 FAIL=0.

Closure: LOW-001 CLOSED (demo-recorder `bdefb70`).
Ceremony: records-only micro-burst per TD-RECORDS-MICRO-BURST-001 (1 LOW finding, zero CRIT/HIGH/MED).
Per TD-RECORDS-MICRO-BURST-001, the 3-CLEAN streak is NOT reset at pass-evaluation time by a
records-only micro-burst pass.
Per frozen-HEAD rule (BC-5.39.001), push of demo-recorder fix resets streak to 0/3.
New frozen HEAD: `bdefb70`. Pass-16 dispatched.

## Finding Detail — Pass 14

**HIGH-001**: AC-016 phantom Category variants — correct 3-variant Later partition is Rate/Timeout/Transport.

The story §AC-016 §Later-partition section enumerated Category variants that did not match
the implementation. The correct 3-variant Later partition shipped in production is
Rate/Timeout/Transport. The variants listed in the spec prior to this pass were phantom
entries inconsistent with the actual enum definition, creating a traceability gap between
the acceptance criterion and the live API surface. Fix: story-writer commit `a3ae216` on
`factory-artifacts` corrects §AC-016 §Later-partition to enumerate exactly the three
correct variants (Rate/Timeout/Transport) and bumps the story to v2.4.

**MED-001**: Demo header "15 acceptance criteria" stale after AC-016 addition.

The demo script header cited "15 acceptance criteria." The addition of AC-016 brought the
total to 16, making the header count stale. Fix: demo-recorder commit on `feature/S-1.01`
updates the demo header from "15 acceptance criteria" to "16 acceptance criteria." This
commit is the new frozen HEAD `2b9371d`.

Closure: HIGH-001 CLOSED (story-writer `a3ae216`). MED-001 CLOSED (demo-recorder `2b9371d`).
Ceremony: full cascade per BC-5.39.001 (HIGH + MED findings present).
Per frozen-HEAD rule (BC-5.39.001), push of demo-recorder fix resets streak to 0/3.
New frozen HEAD: `2b9371d`. Pass-15 dispatched.

## Finding Detail — Pass 13

**MED-001**: EC-006 strip_prefix guard — zero test coverage.

The EC-006 code path (strip_prefix guard logic) had no test coverage at all. The guard
was implemented but never exercised in the test suite, meaning any regression in the
strip_prefix boundary would be invisible. Fix: implementer commit `639d12a` on
`feature/S-1.01` adds a dedicated test for the EC-006 strip_prefix guard (59 tests
pass post-fix).

**MED-002**: BC panic enumeration lists "two" panic paths; three are now shipped +
story §Edge Cases EC-007 asymmetry.

BC-2.14.001 and BC-2.14.002 `# Panics` sections enumerated exactly "two" panic paths.
Post pass-12 implementation, three distinct panic paths are exercised by the production
code. The BC prose saying "two" was factually incorrect and created a traceability gap.
Additionally, the story §Edge Cases section EC-007 entry was asymmetric relative to the
BC — the BC covered the guard condition but the story omitted the third path entirely.
Fix: product-owner commit `85eb142` on `factory-artifacts` updates BC-2.14.001 §Panics and
BC-2.14.002 §Panics with corrected panic enumeration (three paths, explicitly listed).
Story-writer commit `8601821` on `factory-artifacts` updates the story spec §EC-007,
aligning §Edge Cases with the corrected BC inventory.

**LOW-001**: "fn F8-04" should be "footnote F8-04".

A spec prose reference used the abbreviation "fn F8-04" where the correct form is
"footnote F8-04". The `fn` prefix is a Rust keyword and the collision creates ambiguity
when readers scan prose for symbol references. Fix: story-writer commit `8601821`
corrects all "fn F8-04" occurrences to "footnote F8-04" in the story spec (story v2.3).

**LOW-002**: Category::default_retry_hint — no AC-016 traceability, no demo coverage.

The `Category::default_retry_hint` symbol was added to the API surface in a prior
fix-burst but lacked an AC-016 acceptance criterion traceability anchor in the story
spec, and the demo script had no coverage of the symbol. Both gaps were required by
the story's traceability contract. Fix: implementer commit `639d12a` on `feature/S-1.01`
adds demo coverage for `default_retry_hint`. Story-writer commit `8601821` on
`factory-artifacts` adds the AC-016 acceptance criterion to the story spec (story v2.3).

Closure: MED-001 CLOSED (implementer `639d12a`). MED-002 CLOSED (product-owner `85eb142`
+ story-writer `8601821`). LOW-001 CLOSED (story-writer `8601821`). LOW-002 CLOSED
(implementer `639d12a` demo + story-writer `8601821` AC-016).
Ceremony: full cascade per BC-5.39.001 (MED findings present).
Per frozen-HEAD rule (BC-5.39.001), push of implementer fix resets streak to 0/3.
New frozen HEAD: `639d12a`. Pass-14 dispatched.

## Finding Detail — Pass 12

**MED-001**: BC-INDEX DI-010 missing from BC-2.14.001 row.

The BC-INDEX row for BC-2.14.001 did not include DI-010 in the dependency-injection
dependency column. DI-010 is a load-bearing dependency for the component-binding
invariant and its absence caused incomplete traceability for consumers reading the
BC-INDEX dependency graph. Fix: state-manager commit `c628d4e` on `factory-artifacts`
updates BC-INDEX §BC-2.14.001 dependency column to include DI-010.

**LOW-001**: Demo §Section AC-005 attribution + println gap.

The demo script's §Section AC-005 attribution comment was missing the story-spec
traceability anchor and a `println!` in the demo body was not suppressed behind a
feature flag, creating a library-crate println violation. Fix: implementer commit
`f339f9d` on `feature/S-1.01` adds the traceability anchor to the demo comment and
replaces the bare `println!` with a `tracing::info!` emission.

**LOW-002**: api-surface.md §Error Type mixed receiver types — Category sub-header needed.

The §Error Type section of `api-surface.md` listed methods with mixed receiver types
(`&self`, `&mut self`, associated functions) without a Category sub-header to
distinguish them. This made the section ambiguous for consumers scanning the API
surface. Fix: architect commit `379a81d` on `factory-artifacts` adds a Category
sub-header row separating instance methods from associated functions in §Error Type
of api-surface.md.

Closure: MED-001 CLOSED (state-manager `c628d4e`). LOW-001 CLOSED (implementer `f339f9d`).
LOW-002 CLOSED (architect `379a81d`).
Ceremony: full cascade per TD-RECORDS-MICRO-BURST-001 (MED-001 present).
Per frozen-HEAD rule (BC-5.39.001), push of LOW-001 fix resets streak to 0/3.
New frozen HEAD: `f339f9d`. Pass-13 dispatched.

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

CLEAN(strict) streak: 0/3 — reset by push of fix burst (new frozen HEAD `bdefb70`).
BC-5.39.001 frozen-HEAD rule: streak advances only on consecutive CLEAN(strict) passes
against unchanged HEAD. Fix burst from pass-15 (records-only micro-burst) landed as
demo-recorder commit `bdefb70` on `feature/S-1.01`; streak resets to 0/3 on push per
frozen-HEAD rule. Per TD-RECORDS-MICRO-BURST-001, the records-only micro-burst ceremony
does NOT reset the streak at pass-evaluation time — only the push of the new HEAD resets
it via the frozen-HEAD rule.

Current frozen HEAD: `bdefb70`
Current streak: 0/3 on new frozen HEAD.

Deferred D-001: BC `wave: 0` frontmatter inconsistency (13 BCs corpus-wide, no
implementation impact, deferred to phase-5 spec-steward).

Deferred OBS-003: out of scope for S-1.01; deferred to wave gate per orchestrator direction.

Next: pass-16 dispatched on frozen HEAD `bdefb70`.
