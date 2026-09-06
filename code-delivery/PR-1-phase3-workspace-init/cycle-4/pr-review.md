# PR Review — Cycle 4 (verification pass)

**Verdict: REQUEST_CHANGES**
**HEAD reviewed:** `270fd2591f491922200e3b0596029ac1cfc7805a`
**Reviewer:** pr-reviewer (fresh-eyes, diff-only)
**Scope reviewed:** all 59 changed files in `gh pr diff 1` (4,610 diff lines)
**Posting mechanism:** `gh pr review 1 --request-changes` was rejected by the GitHub API
("Can not request changes on your own pull request" — the authenticated user is the PR author).
Posted instead as a formal review object via `gh pr review 1 --comment --body-file`, which
creates a review record rather than a plain issue comment. The verdict below is a formal
REQUEST_CHANGES and must be treated as merge-blocking.

---

## Summary

The nine claimed B-fixes are present in the diff and CI is fully green (fmt, clippy, test,
build, file-size-gate, deny, audit, lint-extra, GitGuardian). B1 (wasmtime removal), B3
(license allow-list), B8 (`--no-tests=warn`), B9 (schemars 1.x) verify clean.

However, this review **cannot approve**. I found **1 blocking** and **8 MED** findings, most
of them *introduced or left incomplete by the cycle-3 fixes themselves*. Three of them I
verified by executing the actual code from this diff against probe inputs — they are not
theoretical.

The core problem: **CI being green is not evidence the gates work.** The workspace has zero
tests and zero function bodies, so every gate in this PR is currently being exercised against
an empty input set. I ran the gates against representative Wave-1-shaped inputs instead.

| # | Severity | Category | Finding |
|---|----------|----------|---------|
| B-1 | **blocking** | coherence | Workspace clippy lints + CI `-D warnings` make *all* test code fail CI |
| M-1 | med | coherence | `check-no-panic` silently suppresses production `.unwrap()` (gate bypass) |
| M-2 | med | coherence | `check-no-panic` false-positives on `src/tests.rs` external test modules |
| M-3 | med | missing | `check-client-timeout` sibling site not swept (TD-VSDD-060) |
| M-4 | med | coherence | `deny.toml` dropped `yanked` on a false premise — regresses SEC-003 |
| M-5 | med | coherence | `deny.toml` `unmaintained = "workspace"` is *weaker* than cargo-deny's default |
| M-6 | med | missing | `check-file-size` implements none of its documented exclusions |
| M-7 | med | coherence | B6 made `tokei` a hard pre-commit requirement that is documented nowhere |
| M-8 | med | coherence | `.claude/settings.json` commits an auto-run hook to a gitignored path |

---

## BLOCKING

### B-1 `[BLOCKING]` `[coherence]` — workspace clippy lints make every unit test fail CI

**File:** `clippy.toml` (in combination with `Cargo.toml` `[workspace.lints.clippy]` and
`.github/workflows/ci.yml` clippy job)

`Cargo.toml` (`[workspace.lints.clippy]`) sets `unwrap_used`, `expect_used`, `print_stdout`,
`print_stderr` to `"warn"`. All 21 library crates inherit via `[lints] workspace = true`. CI
then runs:

```
cargo clippy --workspace --all-targets -- -D warnings
```

`--all-targets` includes test targets, and `-D warnings` promotes every one of those warns to
a hard error **inside `#[cfg(test)]` blocks too**. `clippy.toml` contains only
`too-many-lines-threshold = 150` — the `allow-*-in-tests` keys are absent.

**Why this matters:** the very next commit on this repo is a Wave-1 TDD story, and the first
`assert_eq!(x.unwrap(), y)` a test-writer writes will red the `CI / clippy` job. It also
directly contradicts two project rules: CLAUDE.md scopes the unwrap ban to
"code paths **outside** `#[cfg(test)]` blocks", and SID-1 *mandates* unit tests in
`#[cfg(test)] mod tests` blocks as the substitute for `#[ignore]`'d integration tests. B7 went
to the trouble of teaching the xtask panic gate to exclude `#[cfg(test)]`; the clippy lint that
runs alongside it never got the same exclusion.

**Verified empirically.** Minimal workspace replicating this exact lint config + `clippy.toml`,
on the pinned 1.98.0 toolchain:

```
error: used `unwrap()` on an `Option` value
  --> crates/foo/src/lib.rs:12:20   (inside #[cfg(test)] mod tests)
   = note: `-D clippy::unwrap-used` implied by `-D warnings`
error: used `expect()` on a `Result` value    ...
error: use of `println!`                      ...
error: could not compile `foo` (lib test) due to 5 previous errors
```

**Suggestion** — add to `clippy.toml`:

```toml
too-many-lines-threshold = 150
allow-unwrap-in-tests = true
allow-expect-in-tests = true
allow-panic-in-tests = true
allow-print-in-tests = true
```

I re-ran the same probe with those four keys added and the `unwrap_used` / `expect_used` /
`print_stdout` errors disappear while production-path enforcement is retained. This is the
correct fix — do **not** fix it by weakening the workspace lints or by dropping `-D warnings`.

---

## MED findings

### M-1 `[MED]` `[coherence]` — `check-no-panic` silently suppresses production `.unwrap()`

**File:** `xtask/src/main.rs`, fn `find_panic_outside_tests`

`find_panic_outside_tests` arms `pending_cfg_test = true` on any line containing
`#[cfg(test)]`, then latches `in_test_block` onto **the next `{` seen anywhere in the file**.
The common idiom

```rust
#[cfg(test)]
mod tests;      // <- declaration, no brace on this line
```

leaves the flag armed, so the next brace it finds is the body brace of the following
**production** function. Everything from there to that function's closing brace is treated as
test code and skipped.

**Verified by executing the actual scanner from this diff** against a probe file:

```
--- crates/pregolya-core/src/lib.rs: 0 finding(s)     <-- contains a real production v.unwrap()
--- crates/pregolya-core/src/inner.rs: 1 finding(s)
```

The production `.unwrap()` on the line after `#[cfg(test)] mod tests;` passes the gate. This is
the same *class* of defect B6 was raised to eliminate — a gate that returns success without
having checked anything.

**Suggestion:** only arm the test block when the `#[cfg(test)]` item actually opens a block.
Track whether a `;` is reached before the next `{` and disarm if so:

```rust
if line.contains("#[cfg(test)]") { pending_cfg_test = true; }
// ...then, while walking chars:
';' if pending_cfg_test => pending_cfg_test = false,  // `#[cfg(test)] mod tests;` — no block
```

Longer term, a `syn`-based visitor over the parsed AST removes this whole family of bugs —
`syn` is already a workspace dependency in `pregolya-macros`.

### M-2 `[MED]` `[coherence]` — `check-no-panic` false-positives on external test modules

**File:** `xtask/src/main.rs`, fn `find_panic_outside_tests`

The test-file exclusion is `path.contains("/tests/") || path.ends_with("_test.rs")`. That misses
`src/tests.rs` and `src/<module>/tests.rs` — the canonical target of `#[cfg(test)] mod tests;`.
Verified in the same probe run above: `crates/pregolya-core/src/tests.rs` is flagged for a
`.unwrap()` in a `#[test]` fn.

This is not hypothetical for this repo specifically: CLAUDE.md's file-size rule (test files get
their own 1000/1500 thresholds, production files 500/750) actively pushes test code out of
inline modules and into separate files. The gate will fire on exactly the layout the size rule
encourages.

**Suggestion:** add `|| path.ends_with("/tests.rs")` to the exclusion, and fix M-1 so the
`#[cfg(test)] mod tests;` declaration site is handled correctly too.

### M-3 `[MED]` `[missing]` — `check-client-timeout` sibling site not swept

**File:** `xtask/src/main.rs`, fn `check_client_timeout`

B7 replaced the naive substring heuristic with a brace-tracking scanner in `check_no_panic`, but
`check_client_timeout` — sitting immediately above it in the same file, with the same job — still
filters with:

```rust
.filter(|l| !l.contains("test") && !l.contains("#[cfg(test)]"))
```

`l` is a whole `grep -r` output line, so the **file path** is part of the match. Any path
containing the substring `test` suppresses the finding. Verified:

```
FLAGGED:    crates/pregolya-core/src/clean.rs:...reqwest::Client::new()...
SUPPRESSED: crates/pregolya-core/src/latest.rs:...reqwest::Client::new()...
SUPPRESSED: crates/pregolya-standard-tests/src/lib.rs:...reqwest::Client::new()...
```

The entire `crates/pregolya-standard-tests/` crate is invisible to this gate, as is any file
whose name happens to contain `test` (`latest.rs`, `contest.rs`, `attestation.rs`). Given the
30s-timeout rule is a stated NFR and `pregolya-standard-tests` is the crate that will drive live
provider conformance runs, that is the worst possible blind spot.

TD-VSDD-060 requires sweeping sibling sites when a pattern is corrected. Please apply the
brace-tracking scanner (or the `syn` visitor) to `check_client_timeout` as well.

Secondary: the grep pattern is bare `Client::new()`, which will also false-positive on every
non-reqwest client (`OpenAiClient::new()`, `pregolya::Client::new()`). Anchor it to
`reqwest::Client::new()` / a `use reqwest::Client` import check.

### M-4 `[MED]` `[coherence]` — `deny.toml` dropped `yanked`, regressing SEC-003

**File:** `deny.toml`, `[advisories]`

The B2 commit message states it removed "deprecated v1 keys (vulnerability,
unmaintained=\"warn\", yanked, notice)". `vulnerability` and `notice` are indeed deprecated —
but **`yanked` is a valid v2 key**, not a v1 leftover. From cargo-deny 0.20.2
`src/advisories/cfg.rs`:

```rust
pub struct Config {
    pub yanked: Spanned<LintLevel>,      // valid
    pub unmaintained: Spanned<Scope>,
    pub unsound: Spanned<Scope>,
    ...
}
impl Default for Config {
    yanked: Spanned::new(LintLevel::Warn),   // <-- default is WARN, not deny
```

The PR description records SEC-003 as closed by setting `yanked = "deny"`. Removing the key
reverts enforcement to `warn`, so a yanked dependency no longer fails `CI / deny`. A previously
closed security finding is now open again, and the commit message documents an incorrect reason
for it.

**Suggestion:** restore `yanked = "deny"` in `[advisories]` — it is schema-valid in 0.20.2.

### M-5 `[MED]` `[coherence]` — `unmaintained = "workspace"` is weaker than the default

**File:** `deny.toml`, `[advisories]`

From the same source, `unmaintained` defaults to `Scope::All` and `unsound` defaults to
`Scope::Workspace`. This PR sets `unmaintained = "workspace"` — the narrowest of the four valid
scopes — and omits `unsound` entirely.

Net effect: **RUSTSEC unmaintained advisories on transitive dependencies are no longer reported
at all.** The config is now strictly less strict than writing no `[advisories]` section. That is
the opposite of what a fix labelled "correct the schema" should produce, and it removes coverage
for precisely the advisory class that motivated B1.

The `CI / audit` job is not a backstop here: `cargo audit` treats unmaintained/unsound as
*informational* and exits 0 on them unless run with `--deny unmaintained` / `--deny warnings`,
which this workflow does not do.

**Suggestion:**

```toml
[advisories]
yanked = "deny"
unmaintained = "all"
unsound = "all"
ignore = []   # add RUSTSEC-IDs here with an inline rationale + owner if a real block appears
```

If `"all"` surfaces transitive advisories today, the production-grade response is an `ignore`
entry with documented rationale per advisory — not a global scope downgrade that hides the whole
category.

### M-6 `[MED]` `[missing]` — `check-file-size` implements none of its documented exclusions

**Files:** `xtask/src/main.rs` fn `check_file_size`; `xtask/file-size-allowlist.toml`; `CLAUDE.md`

`xtask/file-size-allowlist.toml` header asserts:

> Generated code (OUT_DIR/, *.gen.rs) and tests/fixtures/ are auto-excluded by glob.

`check_file_size()` implements no glob exclusion whatsoever — the only skip path is
`allowlist.is_allowed(name)`. CLAUDE.md makes the same claim. A generated `*.gen.rs` or a large
`tests/fixtures/` file will hard-fail the gate and force a manual allowlist entry, contradicting
"no allowlist entry needed".

This is the documented anti-pattern from CLAUDE.md's own table: *"Doc comment claiming 'this
requires capability X' with no capability check → either implement the gate or remove the docs."*

Two related gaps in the same function:

- CLAUDE.md defines the measurement as tokei `Code` with "`#[cfg(test)] mod` blocks … excluded
  from the count". tokei does not do this, and the code carries a `NOTE:` comment explaining
  that it deliberately counts them instead. Per CLAUDE.md source-of-truth precedence rule 7
  (code-vs-spec → **spec wins**), a code comment is not a valid resolution; either the
  measurement is implemented as specified, or CLAUDE.md is amended by its owner. CLAUDE.md is
  modified in this very PR (heartbeat section) and was not amended here.
- `tokei` is invoked against `crates/` only, so `xtask/` is exempt from the file-size gate it
  implements. `xtask/src/main.rs` is 386 code-lines today — under the 500 soft target, but it
  will grow with every new gate and is currently unmeasured.

**Suggestion:** implement the three documented glob exclusions, add `xtask/` to the scanned
paths, and either implement the `#[cfg(test)]`-exclusion measurement or route a CLAUDE.md
amendment through its owner.

### M-7 `[MED]` `[coherence]` — B6 makes `tokei` a hard commit blocker that is documented nowhere

**Files:** `lefthook.yml` (`pre-commit.layout`); `Justfile` (header); `xtask/src/main.rs`

B6 correctly changed `check-file-size` to `exit(1)` when tokei is missing, closing a silent
gate bypass. But the same binary is wired into `lefthook.yml`:

```yaml
pre-commit:
  commands:
    layout:
      run: cargo xtask check-file-size
```

So after B6, **any contributor without `tokei` on PATH cannot commit at all** — and skipping
hooks is a TD-FACTORY-HOOK-BYPASS-001 P0 violation, so there is no legitimate escape. The
Justfile header lists `just` + `cargo-nextest` as required and five tools as optional; `tokei`
appears in neither list. CI installs it explicitly, so CI stays green and the breakage lands
only on humans and on any agent working in a fresh worktree.

**Suggestion:** add `tokei` to the Justfile `Requires:` line and add a bootstrap recipe, e.g.

```
# Install required dev tooling
setup:
    cargo install cargo-nextest tokei --locked
```

Keep the `exit 1` — the gate behaviour is right; only its prerequisite is undeclared.

### M-8 `[MED]` `[coherence]` — committed auto-run SessionStart hook pointing at a gitignored path

**File:** `.claude/settings.json`

Added with:

```json
"SessionStart": [{ "hooks": [{ "type": "command",
  "command": "bash \"$CLAUDE_PROJECT_DIR/.factory/hooks/ensure-heartbeat.sh\"" }] }]
```

Two problems. (1) `.factory/` is a gitignored worktree mount, so for every clone that does not
have that worktree — any contributor, any fresh CI checkout, any new agent worktree — this hook
fires and fails on every session start. (2) `settings.json` is the *shared, committed* settings
file, so an auto-executing shell command is now checked into a repo intended for public
release; anyone opening the repo runs a script whose contents are not reviewable in this
diff (they live on the `factory-artifacts` branch). The PR's own security section flags this as
OBS-001 and mitigates it with "branch protection", which does not address the missing-file case
at all.

This is also the least coherent part of the diff: a heartbeat-cron automation hook and its
CLAUDE.md documentation are not part of "initialize Phase-3 Cargo workspace scaffold". The PR
body does disclose them, so description accuracy is fine — but they belong in their own change.

**Suggestion:** move the hook to `.claude/settings.local.json` (gitignored, operator-local), or
if it must be shared, guard it:
`[ -f "$CLAUDE_PROJECT_DIR/.factory/hooks/ensure-heartbeat.sh" ] && bash ... || true`.

---

## Suggestions (non-blocking)

1. `[SUGGESTION]` **`repository` URL is wrong in all 21 crates.** `[workspace.package]` sets
   `repository = "https://github.com/jmagady/pregolya"`; the actual remote is
   `https://github.com/BOHICA-LABS/pregolya`. Every crate inherits it via
   `repository.workspace = true`. Low impact today only because every crate is `publish = false`
   — but that also means the error survives until first publish, when it becomes immutable
   crates.io metadata. One-line fix.
2. `[SUGGESTION]` **MED4 only half-applied.** `--all-features` was added to the `nextest` lines
   in `check` / `check-ci`, but not to the `clippy` lines. Feature-gated code (e.g.
   `sandbox-container`) is therefore compiled by tests but never linted. Add `--all-features` to
   the clippy invocations in `check`, `check-ci`, `check-fast`, `clippy`, and `lefthook.yml`.
3. `[SUGGESTION]` **`tokei` unpinned while its peers are pinned.** MED1 pinned
   `cargo-deny@0.20.2` and `cargo-audit@0.22.2`; the adjacent `cargo install tokei --locked`
   in the same workflow is floating. A tokei JSON-schema change silently breaks the file-size
   gate. Pin it.
4. `[SUGGESTION]` **No `rust-version` in `[workspace.package]`.** `rust-toolchain.toml` pins
   `1.98.0` for local/CI builds, but the published MSRV signal is absent, so nothing enforces
   the "single-workspace MSRV" rule for consumers or catches accidental use of newer std APIs.
   Add `rust-version = "1.98"`.
5. `[SUGGESTION]` **`pregolya-macros` bypasses `[workspace.dependencies]`.** It declares
   `proc-macro2 = "1"`, `quote = "1"`, `syn = { version = "2", features = ["full"] }` inline
   while all 20 sibling crates use `{ workspace = true }`. Version drift risk; move them to
   `[workspace.dependencies]`.
6. `[SUGGESTION]` **`deny-anyhow-in-lib` scans test code too.** `grep -rn "use anyhow" crates/`
   covers `tests/` and `#[cfg(test)]` blocks. The rule is stated as a *library* ban
   (ADR-010 / NE-03); using anyhow in a test harness is legitimate and will be blocked.
7. `[SUGGESTION]` **`deny-description-cache-key` will false-positive on prose.** It flags any
   line matching `cache_key|CacheKey` that also contains `description|Description` — including
   doc comments and the error-taxonomy docs that will inevitably describe this very rule.
8. `[NIT]` **No `LICENSE-MIT` / `LICENSE-APACHE` files** despite `license = "MIT OR Apache-2.0"`.
9. `[NIT]` **Inverted rationale in `AllowList::is_allowed`.** The comment says `contains()`
   "would match substrings … causing false negatives" — over-matching an allowlist causes false
   *negatives in the gate* by over-allowing, i.e. false positives in the match. The code is
   right; the comment's reasoning is backwards.
10. `[NIT]` **`pregolya-standard-tests` dependency direction.** Provider crates were moved to
    `[dev-dependencies]` (B9), which is fine for Cargo, but the crate is described as the
    "shared conformance test suite … for all provider crates" — the intended direction is
    providers depending on the harness. Expect rework at Wave 1.

---

## Checklist results

| # | Item | Result |
|---|------|--------|
| 1 | Diff coherence | **Partial** — `.claude/settings.json` + CLAUDE.md heartbeat docs unrelated to a Cargo scaffold (M-8) |
| 2 | Description accuracy | **Pass** with one exception — the B2 commit message misstates `yanked` as a deprecated v1 key (M-4). The PR body's CI table is stale (cites `f5694882`, shows deny/audit FAIL); both are green on this HEAD |
| 3 | Test coverage | **N/A, accepted** — scaffold has no behavioral code. Caveat: this means every gate is validated against an empty input set, which is how B-1/M-1/M-3 survived cycle 3 |
| 4 | Demo evidence | **N/A, accepted** — no ACs; no `docs/demo-evidence/` expected for a workspace scaffold |
| 5 | Commit quality | **Pass** — conventional format, B/MED IDs mapped per finding, no AI attribution |
| 6 | Diff size | 4,610 lines / 59 files — over the 500-line flag, but appropriate and unavoidable for a 22-crate workspace init; 21 of the manifests are near-identical |
| 7 | Missing changes | See M-4, M-5 (SEC-003 regression), M-6 (documented-but-unimplemented exclusions) |
| 8 | Dependency status | **Pass** — no upstream PRs; all 42 Wave stories are downstream of this one |

## What I verified positively

- **B1** — `crates/pregolya-sandbox/Cargo.toml` has no `wasmtime` entry; `sandbox-wasm` removed
  from `[features]`, with an inline comment recording why. `CI / audit` green confirms the 17
  RUSTSEC advisories are gone.
- **B3** — `Unicode-3.0` and `CDLA-Permissive-2.0` present in `[licenses] allow`, unused
  `Unicode-DFS-2016` removed; `xtask/Cargo.toml` now carries `license = "MIT OR Apache-2.0"`.
  `CI / deny` green.
- **B2 (partial)** — `[advisories]` is schema-valid for cargo-deny 0.20.2 and `CI / deny` passes;
  the deprecated `vulnerability` / `notice` keys are correctly gone. The *enforcement level*
  chosen is the defect (M-4, M-5), not the schema.
- **B4** — `[workspace.lints]` present at root; all 21 library crates carry
  `[lints] workspace = true`; `xtask` correctly uses an explicit profile that omits
  `print_stdout` / `print_stderr` for its CLI output while keeping `unsafe_code = "forbid"`.
  Lint wiring itself is exactly right — B-1 is about the missing test-scope escape hatch, not
  the wiring.
- **B5** — `too_many_lines = "warn"` in `[workspace.lints.clippy]`, paired with
  `too-many-lines-threshold = 150` in `clippy.toml`.
- **B6** — `check_file_size` returns `exit(1)` with an actionable install hint when tokei is
  absent. Correct as written; M-7 is about the undeclared prerequisite, not the exit code.
- **B8** — `--no-tests=warn` present on the `iter` recipe, matching `check` and `check-ci`.
- **B9** — `schemars = "1"` in `[workspace.dependencies]`; `pregolya-core` and `pregolya-mcp`
  both use `schemars = { workspace = true }`. No `0.8` reference anywhere in the diff.
- **MED1** — `cargo-deny@0.20.2` and `cargo-audit@0.22.2` pinned with `--locked`.
- **MED2** — `http2` present in the reqwest feature list, alongside `default-features = false`
  and `rustls-tls`. All 6 reqwest consumers use `{ workspace = true }`, so the native-tls path
  is unreachable; `deny.toml` bans `native-tls`, `openssl`, `openssl-sys`, `openssl-probe` as
  a second layer. This is done well.
- **MED3** — `toolchain: "1.98.0"` on all 8 CI jobs; no `stable` remains.
- **Security posture** — `.env.example` is key-names-only; all GitHub Action refs are 40-char
  SHA-pinned with version comments; workflow-level `permissions: contents: read`;
  `RUST_BACKTRACE=1` correctly narrowed from workflow env to the `test` job; every job has
  `timeout-minutes`; `#![forbid(unsafe_code)]` in the lib.rs stubs on top of the workspace lint.
- **CI on this HEAD** — 8/8 jobs + GitGuardian green.

---

## Path to approval

B-1 is a one-file, four-line change to `clippy.toml`. M-4 and M-5 are a five-line change to
`deny.toml`. M-1/M-2/M-3 are a focused rework of the two xtask scanners (or one `syn`-based
visitor replacing both). M-6/M-7/M-8 are small and mechanical.

One request for the fix burst: **the xtask gates need tests.** All three gate defects above
were found by running the gate functions against probe inputs — something a handful of unit
tests over `find_panic_outside_tests` (production unwrap after `#[cfg(test)] mod tests;`,
unwrap inside `#[cfg(test)] mod tests {}`, unwrap in `src/tests.rs`) would have caught in
cycle 3 and will catch in cycle 5. A lint gate with no tests is a gate nobody has verified.

Per the frozen-HEAD streak rule, pushing the fix burst resets the streak — cycle 5 must
re-gate on the newly-pushed HEAD.
