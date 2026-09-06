# PR Review — cycle-12 (fix-9 targeted)

**Reviewed SHA:** `d1d566f4a5f495a3f36ffb54de72fb5f34eec9e8`
**PR:** #1 `chore/phase3-workspace-init` → `develop`
**Scope:** targeted re-review of the two cycle-11 MUST-FIX items (MED-1 POL-40 lex-failure, B-7 non-load-bearing fixture) plus new-issue scan on `git diff 8b0a7c1..d1d566f -- xtask/`.

## Verdict

**REQUEST_CHANGES** — 1 MED finding. MED-1 is genuinely closed and verified end-to-end. **B-7 is NOT closed**: the replacement fixture still passes against the pre-fix implementation it is supposed to guard.

## Gate results (all verified by execution)

| Gate | Command | Result |
|---|---|---|
| Tests | `cargo nextest run -p xtask --no-fail-fast` | **29 run, 29 passed, 0 skipped** |
| Clippy | `cargo clippy -p xtask --all-targets` | clean, zero warnings |
| Fmt | `cargo fmt --all --check` | exit 0 |
| Real gate | `cargo run -p xtask -- check-no-panic` | `PASSED` (exit 0) |
| Real gate | `cargo run -p xtask -- check-client-timeout` | `PASSED` (exit 0) |

## MED-1 (POL-40 lex-failure silent return) — VERIFIED CLOSED

Both `scan_for_panics_in_source` and `scan_for_timeout_violations_in_source` now return a finding on `src.parse()` failure. Verified at three levels:

1. **Unit level** — both new tests pass and produce the exact message:
   `src/foo.rs:0: FAILED TO LEX FILE: cannot parse string into token stream`
2. **End-to-end level** — I dropped a deliberately unlexable file into `crates/pregolya-core/src/` and ran both real CLI gates. Both correctly failed:
   ```
   ERROR: panic-potential in library code: crates/pregolya-core/src/zz_lexprobe.rs:0: FAILED TO LEX FILE: ...
   ERROR: reqwest::Client::new() without timeout: crates/pregolya-core/src/zz_lexprobe.rs:0: FAILED TO LEX FILE: ...
   ```
   Confirms the finding reaches `all_findings` and drives `exit(1)`. The silent false-negative path is gone. (Probe file removed; tree clean at review time.)
3. **Suppression boundary** — a lex failure on a test-file path (`src/tests.rs`) still returns empty, because `is_test_file` short-circuits before `parse()`. This is consistent with the existing whole-file test exclusion policy and is correct, not a regression.

## MED-2 (NEW) — B-7 regression fixture is still not load-bearing

| Field | Value |
|---|---|
| Severity | **MED** |
| Category | coverage (paper-fix / TD-VSDD-059) |
| Location | `xtask/src/tests.rs`, `test_no_panic_non_ascii_line_does_not_corrupt_depth` |

### Finding

The fixture was changed to `h_résumé()` with a `{` inside the comment, with the stated intent that a pre-fix byte-indexed `//` detector would miss the comment boundary and suppress the production `.unwrap()`. **It does not.** I reconstructed the pre-fix scanner (the `a2fda79` string-based `scan_for_panics_in_source` with the B-7 fix reverted to `line.as_bytes().get(i + 1) == Some(&b'/')`) and ran it against the exact new fixture:

```
PRE-FIX | cycle-12 B-7 fixture (h_résumé, drift=2)  | n=1 | FOUND      <-- test would PASS against the bug
PRE-FIX | cycle-11 old fixture (h(), drift after //) | n=1 | FOUND      <-- previously-rejected fixture
PRE-FIX | drift=3 variant (h_réésumé)                | n=0 | SUPPRESSED <-- genuinely load-bearing
PRE-FIX | drift=4 variant                            | n=0 | SUPPRESSED
```

So `test_no_panic_non_ascii_line_does_not_corrupt_depth` passes both with and against the bug it guards. It discriminates nothing.

### Root cause

`h_résumé` contains exactly **two** multi-byte chars (`é`, `é`) before the `//`, so the byte-index/char-index drift is exactly **2** — which happens to equal the width of `//`.

Walking the pre-fix lookahead over line 3 (`    fn h_résumé() {} // { brace_in_comment`): the two `/` chars sit at char indices 21 and 22, and at byte offsets 23 and 24. The pre-fix check is `bytes[i + 1] == b'/'`:

- at `i = 21` (first `/`): `bytes[22]` is `' '` → no break (as predicted), but `/` falls through to the `_ => {}` no-op arm, consuming nothing structural;
- at `i = 22` (second `/`): `bytes[23]` is `'/'` → **break fires**.

The break lands one char late but still *before* the `{ brace_in_comment` text, so brace depth is never corrupted and the `.unwrap()` is never suppressed. Drift of 1 self-cancels for the same reason. Only **drift ≥ 3** moves the byte window entirely past both slashes so that no char index satisfies both `chars[i] == '/'` and `bytes[i+1] == b'/'`, making the break never fire.

The doc comment added in this commit also asserts an incorrect mechanism — "makes the pre-fix scanner inflate brace depth by 1" — which the probe disproves for this fixture.

### Suggestion

One-character fixture change: add a third multi-byte char before the `//` so drift reaches 3.

```rust
let src = "#[cfg(test)]\nmod tests {\n    fn h_réésumé() {} // { brace_in_comment\n}\npub fn prod() { let x: Option<i32> = Some(1); x.unwrap() }\n";
```

I verified both directions of this replacement:
- **pre-fix scanner → `n=0`** (comment boundary missed, `{` inflates depth, production `.unwrap()` suppressed) — the test would fail, as a regression test must;
- **current `proc_macro2` scanner → `n=1`, `["src/lib.rs:5: .unwrap()"]`** — the test passes.

Please also correct the doc comment to describe the actual mechanism (byte-window drift must exceed the two-char `//` width before the boundary check can be missed) and state why drift 1 and 2 self-cancel — that is the non-obvious property this test exists to pin.

## NITs (non-blocking)

| # | Location | Note |
|---|---|---|
| N-1 | both scanners | `:0:` is a sentinel line number; every other finding uses a real 1-based line. Consider `:1:` or omitting the line segment for whole-file failures so downstream `path:line` parsers don't see a line 0. |
| N-2 | both scanners | The lex-failure format string is duplicated verbatim. A shared helper (e.g. `fn lex_failure(path: &str, e: impl Display) -> Vec<String>`) keeps the two gates from drifting. |
| N-3 | `check_no_panic` / `check_client_timeout` footers | On a lex failure the remediation footer prints "Use ? propagation with structured error variants instead." / "Use Client::builder().timeout(...)" — misleading advice for a corrupt file. Pre-existing generic footer, but now reachable via a new code path. |

## Checklist coverage

1. **Diff coherence** — pass. `8b0a7c1..d1d566f` touches only `xtask/src/main.rs` (4 lines) and `xtask/src/tests.rs` (fixture + 2 new tests). No unrelated changes.
2. **Description accuracy** — the MED-1 portion is accurate. The B-7 portion overstates the fix (see MED-2).
3. **Test coverage** — MED-1 covered by two new discriminating tests. B-7 covered by a **non**-discriminating test.
4. **Demo evidence** — n/a for this workspace-scaffold chore PR; the CLI gates are self-evidencing and I ran both.
5. **Commit quality** — pass. Conventional format, scoped `fix(xtask)`, clear subject.
6. **Diff size** — pass. Fix-9 delta is ~55 lines.
7. **Missing changes** — MED-2 is the outstanding item.
8. **Dependency status** — no upstream PR dependencies.

## What I verified rather than assumed

Under TD-VSDD-059 (paper-fix detection), I did not accept either claimed closure on inspection. I reconstructed the pre-fix implementation and executed it against the fixtures to test whether each regression test actually discriminates the fix from the bug. MED-1 survived that test; B-7 did not. A regression test that passes against the defect it guards is precisely the paper-fix pattern TD-VSDD-059 exists to catch, which is why this is MED and not a NIT despite being confined to test code — production behaviour of the `proc_macro2` scanner is correct.

**REQUEST_CHANGES** — resolve MED-2, then this is ready.
