# PR Review — PR #1 `chore/phase3-workspace-init` → `develop`

> **SUPERSEDED — cycle 4 record, retained for history.**
> This pass reviewed HEAD `270fd2591f491922200e3b0596029ac1cfc7805a` and returned
> REQUEST_CHANGES. All 5 blocking findings were closed by the fix-2 burst.
> **Current review state: APPROVE at `a2fda7983498995e96be4a60343166f642d9c4a1`** —
> see `cycle-10/pr-review.md` for the authoritative verdict (cycle 10 of 10, FINAL:
> 0 blocking, 1 suggestion S-10.1, 4 nits). B-5 and B-6 were closed by fix-5;
> B-7 and B-8 were closed by fix-7 and independently re-verified by differential revert.
> Do not read the verdict below as the current merge gate.

**Reviewed HEAD:** `270fd2591f491922200e3b0596029ac1cfc7805a`
**Verdict:** REQUEST_CHANGES — 5 blocking (MED) findings *(superseded — see cycle-5)*
**Reviewer:** pr-reviewer (fresh-eyes, diff-only) — independent pass, findings derived by *executing* the gates this PR introduces
**Posting mechanism:** `gh pr review 1 --request-changes` was rejected by the GitHub API
("Can not request changes on your own pull request" — the authenticated token is the PR author).
Posted instead as a formal review object via `gh pr review 1 --comment --body-file`, which creates a
review record rather than a plain issue comment. The verdict below is a formal REQUEST_CHANGES and
must be treated as merge-blocking.
**CI at review time:** all 17 checks green (fmt, clippy, test, build, file-size-gate, deny, audit, lint-extra ×2 runs + GitGuardian)
**Diff:** 58 files, ~4,610 diff lines (large, but justified — 22 crate scaffolds + generated `Cargo.lock`)

This is a genuinely strong scaffold. The prior cycle's blocking fixes (B1–B9) all landed and I verified each
independently. What follows are findings I derived by *executing* the gates this PR introduces, rather than
reading them — and four of the five gates certify clean state they have not actually measured.

---

## Verdict rationale

I did not want to block this PR. CI is green, the dependency hygiene is excellent, and the anti-vacuous-pass
philosophy in `ci.yml`'s header comment is exactly right. But I built the workspace locally at this HEAD and
ran adversarial probes against each xtask gate, and three of the four lint gates returned `PASSED` while
staring directly at the violations they exist to catch. A fourth (`check-file-size`) fails open on a
dependency that CI installs unpinned. And the clippy configuration will hard-fail the first TDD test that
uses `.unwrap()` — which is to say, the first TDD test.

Each finding below includes the exact probe I ran and its measured output.

---

## Findings

| ID | Severity | Category | Summary |
|----|----------|----------|---------|
| F1 | **blocking** (MED) | coverage | Workspace clippy lints make `.unwrap()`/`.expect()`/`println!` in tests a hard CI failure |
| F2 | **blocking** (MED) | missing | `check-client-timeout` does not enforce the timeout convention — 3 confirmed false negatives, no backstop |
| F3 | **blocking** (MED) | missing | `check-no-panic` has 2 confirmed false negatives (trailing comment; latched `#[cfg(test)]`) |
| F4 | **blocking** (MED) | missing | `check-file-size` fails **open** on tokei JSON drift; CI installs tokei unpinned |
| F5 | **blocking** (MED) | coherence | File-size measurement contradicts CLAUDE.md, and the allowlist header contradicts the implementation |
| F6 | suggestion | coherence | `lefthook.yml` `pre-tag` stage never fires — git has no `pre-tag` hook |
| F7 | suggestion | coherence | Justfile + lefthook clippy omit `--all-features`; CI includes it |
| F8 | suggestion | missing | `deny-anyhow-in-lib` only greps `use anyhow` |
| F9 | nit | — | Duplicate CI work, unmeasured `xtask/`, inconsistent dep refs, missing crate header |

---

### F1 — [BLOCKING] Workspace clippy lints will fail every TDD test that uses `.unwrap()`

**Where:** `Cargo.toml` (`[workspace.lints.clippy]`) + `clippy.toml` + `.github/workflows/ci.yml` (clippy job)

`[workspace.lints.clippy]` sets `unwrap_used`, `expect_used`, `print_stdout`, and `print_stderr` to `"warn"`.
All 21 library crates inherit these via `[lints] workspace = true`. CI then runs:

```
cargo clippy --workspace --all-targets --all-features -- -D warnings
```

`-D warnings` promotes every one of those warns to a hard error, and `--all-targets` includes test targets.
`clippy.toml` contains only `too-many-lines-threshold = 150` — it does **not** set the companion
`allow-*-in-tests` options, which default to `false`.

Measured at this HEAD (toolchain 1.98.0, the pinned channel):

```
$ cargo clippy -p pregolya-core --all-targets -- -D warnings
error: used `unwrap()` on an `Option` value
 --> crates/pregolya-core/tests/probe_unwrap.rs:4:16
  = note: `-D clippy::unwrap-used` implied by `-D warnings`
error: used `expect()` on a `Result` value
  = note: `-D clippy::expect-used` implied by `-D warnings`
error: could not compile `pregolya-core` (test "probe_unwrap") due to 4 previous errors
error: could not compile `pregolya-core` (lib test) due to 2 previous errors
```

The inline `#[cfg(test)] mod` case fails identically, and a separate probe confirmed a bare `println!` in an
integration test also errors (`-D clippy::print_stdout`).

**Why it matters:** this contradicts CLAUDE.md, which scopes the ban precisely — "`unwrap()` and `expect()`
… are forbidden in all code paths **outside `#[cfg(test)]` blocks**" and "`println!` … forbidden in every
crate **except** binary crates' CLI formatting helpers". As configured, the workspace is stricter than its own
standard, in the one place the standard explicitly carves out. Every TDD story in Wave 1 will write tests
with `.unwrap()`; each will red-gate on CI clippy rather than on its own assertion. That converts a
correctness gate into an obstacle and invites the worst possible remedy — scattering `#[allow]` attributes
through test code, which then erodes the lint everywhere.

This looks like a sibling-site sweep gap from the B4 fix (TD-VSDD-060): the workspace lints were added
without the companion `clippy.toml` test allowances.

**Suggested fix** — append to `clippy.toml`:

```toml
too-many-lines-threshold = 150
allow-unwrap-in-tests = true
allow-expect-in-tests = true
allow-print-in-tests = true
allow-panic-in-tests = true
allow-dbg-in-tests = true
```

I verified this fix: after adding `allow-unwrap-in-tests` / `allow-expect-in-tests`, both `unwrap_used` and
`expect_used` errors disappear from the probe while the production-path enforcement remains intact. This is
the idiomatic mechanism — it keeps the lints at full strength in production code and is a single
configuration surface rather than N scattered attributes.

---

### F2 — [BLOCKING] `check-client-timeout` does not enforce the timeout convention

**Where:** `xtask/src/main.rs`, `check_client_timeout()`

The gate greps `crates/` for the literal string `Client::new()` and then filters:

```rust
.filter(|l| !l.contains("test") && !l.contains("#[cfg(test)]"))
```

I built the xtask binary at this HEAD and ran it against three production `reqwest::Client` constructions,
none of which sets a timeout:

```rust
// crates/pregolya-core/src/probe_d.rs
pub fn c1() -> Client { Client::builder().build().unwrap_or_default() }   // builder path, no .timeout()
pub fn c2() -> Client { let latest = Client::new(); latest }             // line contains "latest"
// crates/pregolya-standard-tests/src/probe_e.rs
pub fn c3() -> reqwest::Client { reqwest::Client::new() }                // path contains "test"
```

```
$ cargo xtask check-client-timeout
check-client-timeout PASSED.
exit=0
```

Three distinct false negatives, each independently sufficient to defeat the gate:

1. **`Client::builder().build()` is unmodelled.** The gate only knows the `Client::new()` form. The builder
   path — the *idiomatic* way to construct a client, and the one every provider crate will use — passes
   unconditionally whether or not `.timeout()` is called. The gate's own error message tells you to use
   `Client::builder().timeout(...).build()`, so the one construction it recommends is the one it cannot check.
2. **`!l.contains("test")` matches on the whole grep line**, path and code together. Any line containing the
   substring "test" is exempt: `latest`, `tester`, `attestation`, `// fastest path`.
3. **Path-based exemption is unbounded.** Because the filter sees the grep-prefixed path, every file under
   `crates/pregolya-standard-tests/src/` is exempt — that is a first-class library crate in
   `workspace.members`, not a test directory.

Separately, `!l.contains("#[cfg(test)]")` is dead code: `grep` is line-oriented, so the attribute can never
appear on the same line as the constructor it guards.

**Why it matters:** unlike F3, there is **no clippy backstop here**. No lint checks reqwest timeouts. This
gate is the sole enforcement for a CLAUDE.md rule that the project classifies as severe — "New clients
without an explicit timeout are a P1 finding in adversarial review." A clientless timeout hangs the Tokio
executor indefinitely on a stalled provider, which is precisely the failure this project cannot afford in
graph node execution.

**Suggested fix:** scan per-file rather than per-line, and check the property rather than the spelling —
locate each `reqwest::Client` construction site (`Client::new()`, `Client::builder()`, `ClientBuilder::new()`)
and require a `.timeout(` in the same expression chain. Reuse the `find_panic_outside_tests` file-walk
already in this module so test-block exclusion is structural (see F3 for its own fixes) rather than a
substring guess. At minimum, replace the `contains("test")` filter with a path-anchored check
(`path.contains("/tests/") || path.ends_with("_test.rs")`) so a variable named `latest` cannot disable the gate.

---

### F3 — [BLOCKING] `check-no-panic` has two confirmed false negatives

**Where:** `xtask/src/main.rs`, `find_panic_outside_tests()`

The B7 brace-depth scanner is a real improvement over a naive grep, and it works on the common case. But two
easily-hit inputs defeat it. Both probes are production code with a bare `.unwrap()`:

```rust
// crates/pregolya-core/src/probe_b.rs
pub fn f(x: Option<u32>) -> u32 {
    x.unwrap() // documented invariant
}
// crates/pregolya-core/src/probe_c.rs
#[cfg(test)]
use std::sync::Arc;

pub fn g(x: Option<u32>) -> u32 {
    x.unwrap()
}
```

```
$ cargo xtask check-no-panic
check-no-panic PASSED.
exit=0
```

1. **Trailing comments disable the check.** The final guard is
   `if (has_unwrap || has_expect) && !line.contains("//")`. The intent was presumably to skip commented-out
   code, but `contains` is not anchored, so *any* line with a trailing comment is exempt. `x.unwrap() // safe`
   is both the most natural way to write an unwrap and a complete bypass. (The earlier
   `trimmed.starts_with("//")` check already handles genuinely commented-out lines correctly — this second
   guard is redundant and harmful.)
2. **`pending_cfg_test` latches across items.** It is set on any line containing `#[cfg(test)]` and cleared
   only at the next `{` *anywhere in the file*. When `#[cfg(test)]` decorates a brace-less item — a `use`,
   a `const`, a `type` alias — the flag survives to the next production function body, which is then marked
   as the test block. Since `in_test_block` only clears at the matching depth, **the remainder of the file is
   exempt**. `#[cfg(test)] use ...;` is an extremely common pattern for test-only imports.

There is also a latent third issue: braces inside string and char literals are counted
(`let s = "{";`, `'}'`, `format!("{{")`), which desyncs `brace_depth` and can cause a test block to end
early or never end.

**Why it matters:** this one *is* backstopped — the F1 clippy lints do catch both probes in production code —
so the practical exposure is lower. But per TD-VSDD-059, a gate that reports `PASSED` over unmeasured
violations is a paper-fix regardless of whether another mechanism happens to cover it, and this gate will be
cited as evidence in future reviews. If the intent is defense-in-depth, it needs to actually hold.

**Suggested fix:** drop the `&& !line.contains("//")` guard entirely (the `starts_with("//")` check above
already covers commented-out code); strip trailing `//…` before pattern matching instead. Clear
`pending_cfg_test` at the end of any line that does not open a brace, or only latch it when the same or next
line contains `mod ` / `fn `. Skip brace counting inside string and char literals. Hoist the
`path.contains("/tests/")` check out of the per-line loop to the top of the function.

---

### F4 — [BLOCKING] `check-file-size` fails **open** on tokei JSON drift, and CI installs tokei unpinned

**Where:** `xtask/src/main.rs` `check_file_size()`; `.github/workflows/ci.yml` (`file-size-gate`, `lint-extra`)

The parse is guarded by:

```rust
if let Some(rust) = json.get("Rust")
    && let Some(reports) = rust.get("reports").and_then(|r| r.as_array())
```

If either node is absent the entire loop is skipped and the function falls through to
`println!("check-file-size PASSED …")` with exit 0. I confirmed this with a stub `tokei` on `PATH` emitting
a plausible alternative schema (language map nested under a `languages` key) reporting a 99,999-line file:

```
$ PATH=/tmp/faketokei:$PATH ./target/debug/xtask check-file-size
check-file-size PASSED (0 warnings).
exit=0
```

Compounding it, CI installs the tool **without a version pin**:

```yaml
- name: Install tokei
  run: cargo install tokei --locked
```

while the two neighbouring tools in the same workflow *are* pinned (`cargo-deny@0.20.2`,
`cargo-audit@0.22.2`). So a future tokei release that reshapes its JSON silently converts a **required**
status check into a vacuous pass, with nothing in the logs to indicate it.

Secondary fail-open in the same function: `.and_then(|c| c.as_u64()).unwrap_or(0)` scores any report with a
missing or non-integer `stats.code` as zero lines.

**Why it matters:** this is the exact defect class `ci.yml`'s own header comment is written to prevent —
"A pass on a required status check while measuring nothing would certify unmeasured state (Mechanism-3
defect)." That reasoning was applied rigorously to the missing-`Cargo.toml` case (`exit 1`, non-certifying)
but not to the missing-`Rust`-key case one layer down.

For the record, the gate is correct when tokei behaves. I ran both controls:

```
$ ./target/debug/xtask check-file-size          # 800-line file planted in pregolya-core
ERROR: HARD GATE FAIL: crates/pregolya-core/src/big.rs has 800 code lines (limit: 750)
exit=1                                          # positive control OK

$ env -i PATH=/usr/bin:/bin ./target/debug/xtask check-file-size
ERROR: tokei not found on PATH. …
exit=1                                          # B6 fix confirmed working
```

**Suggested fix:** pin the tool (`cargo install tokei@<version> --locked`) in both jobs, and make the parse
fail closed — if `crates/**/*.rs` files exist but the `Rust`/`reports` node is absent or empty, `exit 1` with
a message naming the schema mismatch. Replace `unwrap_or(0)` on `stats.code` with an explicit error, so an
unreadable report is a gate failure rather than a zero-line pass.

---

### F5 — [BLOCKING] File-size measurement contradicts CLAUDE.md; allowlist header contradicts the implementation

**Where:** `xtask/src/main.rs` `check_file_size()` vs `xtask/file-size-allowlist.toml` vs CLAUDE.md

CLAUDE.md states two properties of the measurement:

> measured by `tokei --output json` `Code` metric — blanks, comments, doc-comments, **`#[cfg(test)] mod` blocks**, and generated code **excluded from the count**

> Generated code (`OUT_DIR/`, `*.gen.rs`, prost/tonic output) and `tests/fixtures/` are **auto-excluded by glob — no allowlist entry needed**

`xtask/file-size-allowlist.toml`'s header restates both, nearly verbatim:

```
# Generated code (OUT_DIR/, *.gen.rs) and tests/fixtures/ are auto-excluded by glob.
# Thresholds (tokei Code metric — blanks, comments, cfg(test) blocks excluded):
```

The implementation does neither, and says so:

```rust
// NOTE: tokei counts ALL code-lines in a file (including #[cfg(test)] blocks
// that are inline in production files).  … Inline test modules contribute to
// the production file's code count — this is intentional
```

There is likewise no glob exclusion anywhere in `check_file_size` — the only skip path is
`allowlist.is_allowed(name)`, an explicit-entry match.

**Why it matters:** two concrete consequences, plus a governance one.

- Rust convention places unit tests inline in `#[cfg(test)] mod tests`, and CLAUDE.md's own TDD guidance
  actively pushes work there ("prefer unit tests … reserve subprocess integration tests"). Counting them
  against the production budget means a cohesive 400-line module with 400 lines of inline tests trips the
  750-line hard gate — pressuring exactly the fragmentation CLAUDE.md's cohesion clause warns against
  ("Over-splitting into many ~100-line files is an anti-pattern in Rust").
- The first in-tree `*.gen.rs` or prost/tonic output under `crates/` will hard-fail CI and demand an
  allowlist entry that CLAUDE.md and the allowlist header both promise is unnecessary.
- Per Source-of-Truth Precedence rule 7, code-vs-spec conflicts resolve in favour of the spec; code is
  brought into alignment, and only the human may authorize amending the spec to match the code. The
  implementation comment declares the deviation "intentional" but no such authorization is visible in this PR.

**Suggested fix:** align the gate to CLAUDE.md — pass tokei per-file with inline `#[cfg(test)]` regions
excluded from the code count (or subtract them in a pre-pass), and add the documented glob exclusions for
`*.gen.rs`, prost/tonic output, and `crates/*/tests/fixtures/**` ahead of the allowlist check. If the
implementer's reasoning is right on the merits — and it is a defensible position — that is a CLAUDE.md
amendment to request from the human, not a code-side reinterpretation. Either way the allowlist header and
the implementation comment must stop saying opposite things in the same commit.

---

### F6 — [SUGGESTION] `lefthook.yml` `pre-tag` stage never fires automatically

**Where:** `lefthook.yml`

Git has no `pre-tag` hook. The client-side hook set is `pre-commit`, `prepare-commit-msg`, `commit-msg`,
`post-commit`, `pre-rebase`, `post-checkout`, `post-merge`, `pre-push`, `pre-auto-gc`, `post-rewrite`,
`reference-transaction`, and a few others — `pre-tag` is not among them. `git tag` therefore fires nothing,
and the `semver-checks` + `audit` + `deny` gate is reachable only via an explicit `lefthook run pre-tag`.

Not blocking: no releases exist yet, `version = "0.1.0"`, and CLAUDE.md itself documents "`pre-tag`:
semver-checks + audit + deny" — so this PR faithfully implements what the project asked for, and the flawed
premise sits upstream in CLAUDE.md rather than in this diff.

**Suggested fix:** keep the stage (it is a useful named recipe) but add a comment stating it is
manual-invocation-only, and move the real enforcement into a tag-triggered release workflow
(`on: push: tags: ['v*']`) so a release cannot skip semver-checks. Worth flagging to the architect as a
CLAUDE.md correction.

---

### F7 — [SUGGESTION] Local clippy diverges from CI on `--all-features`

**Where:** `Justfile` (`check`, `check-fast`, `clippy`), `lefthook.yml` (`pre-commit`)

Every local path runs `cargo clippy --workspace --all-targets -- -D warnings`. CI runs the same command
**plus `--all-features`**. `pregolya-sandbox` already declares `sandbox-container`/`sandbox-wasm`, and
`pregolya-checkpoint`'s doc header plans `checkpoint-sqlite`/`checkpoint-memory`/`checkpoint-postgres`, so
feature-gated code is coming. Contributors will get a clean `just check` and a red CI.

**Suggested fix:** add `--all-features` to the three Justfile recipes and the lefthook `pre-commit` clippy
command so the local gate is CI-equivalent — which is what `check-ci` claims to be.

---

### F8 — [SUGGESTION] `deny-anyhow-in-lib` only greps `use anyhow`

**Where:** `xtask/src/main.rs`, `deny_anyhow_in_lib()`

The gate greps for the literal `use anyhow`. It misses fully-qualified usage (`fn f() -> anyhow::Result<()>`),
the `anyhow::anyhow!` / `anyhow::bail!` macro forms, and an `anyhow` entry appearing in any crate's
`[dependencies]`. Conversely it has no crate-scope or target-scope awareness, so it would flag a legitimate
dev-dependency usage in a test harness despite the gate being named `…-in-lib`.

**Suggested fix:** also grep for `anyhow::` and scan each `crates/*/Cargo.toml` `[dependencies]` section
(the dependency check is the reliable one — you cannot use the crate without declaring it). Scope the source
scan to `src/` and exclude `#[cfg(test)]` regions if dev-time anyhow is intended to be permitted.

---

### F9 — [NIT] Assorted

- **Duplicate CI work.** `file-size-gate` and `lint-extra` each install tokei and each run
  `cargo xtask check-file-size` — roughly a minute of redundant CI per run. Drop it from one job, or fold
  `file-size-gate` into `lint-extra` and keep a single required check name.
- **`xtask/` is itself unmeasured.** `check_file_size` passes only `crates/` to tokei, so
  `xtask/src/main.rs` (387 lines and growing with each gate) never faces the gate it implements.
- **Inconsistent dependency references.** `pregolya-openai-sdk`, `pregolya-anthropic-sdk`, and
  `pregolya-ollama-sdk` declare `thiserror = "2"` literally while every sibling uses
  `thiserror = { workspace = true }`. Same value today; drifts on the first workspace bump.
- **`pregolya-macros/src/lib.rs`** omits the `#![forbid(unsafe_code)]` / `#![warn(missing_docs)]` header that
  the other 21 crates carry. Harmless (workspace lints cover `unsafe_code`) but inconsistent — and
  `missing_docs` is genuinely not enforced there.

---

## Checklist results

| # | Item | Result |
|---|------|--------|
| 1 | Diff coherence | **PASS.** All 58 files serve workspace init. `CLAUDE.md` and `.claude/settings.json` appear in `gh pr diff` but are byte-identical to current `develop` (`git diff develop...HEAD` empty for both) — those commits landed on `develop` independently, so the effective diff has no scope creep. |
| 2 | Description accuracy | **PASS.** Body matches the diff, including the ADR block and the honest "not a behavioral story — no BC traceability" framing. Crate count (22) matches `workspace.members`. |
| 3 | Test coverage | **N/A with caveat.** Zero behavioral code, so no tests are expected. But see F1 — the harness as configured will reject the first tests written against it. |
| 4 | Demo evidence | **N/A, correctly declared.** No behavioral ACs to demonstrate; the description states this rather than shipping placeholder evidence. |
| 5 | Commit quality | **PASS.** 5 commits, all conventional format with clear scoped subjects. No AI attribution. No story ID — correct for an infra PR. |
| 6 | Diff size | **PASS with note.** ~4,610 lines exceeds the 500-line flag threshold, but 22 near-identical crate scaffolds plus a generated `Cargo.lock` (262 packages) is irreducible for a workspace init. Reviewed in full. |
| 7 | Missing changes | **See F5.** The file-size gate does not implement the `#[cfg(test)]` exclusion or the generated-code glob exclusions that CLAUDE.md specifies. |
| 8 | Dependency status | **PASS.** No upstream story dependencies; `MERGEABLE` against `develop`. |

---

## Verified clean (independently confirmed at this HEAD)

I want to be explicit about what I checked and found correct, so this is not read as a blanket rejection:

- **reqwest / TLS.** Single workspace dep with `default-features = false, features = ["rustls-tls", "http2", "json", "stream"]`. All six consuming crates (`openai`, `openai-sdk`, `anthropic`, `anthropic-sdk`, `ollama`, `ollama-sdk`, `mcp`) use `{ workspace = true }` — zero local overrides that could reintroduce `native-tls`. `Cargo.lock` contains `rustls` and `ring` and **zero** entries for `native-tls`, `openssl`, `openssl-sys`, or `openssl-probe`.
- **deny.toml (B1).** Valid v2 schema — `unmaintained = "workspace"`, deprecated v1 keys (`vulnerability`, `yanked`, `notice`) removed. Bans all four of `native-tls`/`openssl`/`openssl-sys`/`openssl-probe`. License allow-list includes the previously-missing `Unicode-3.0` and `CDLA-Permissive-2.0`. `[sources] allow-registry` restricted to crates.io. `CI / deny` green on both runs.
- **wasmtime removal (B2).** Absent from `Cargo.lock`. `pregolya-sandbox` reserves the `sandbox-wasm` feature with an explicit comment warning against speculative reintroduction and citing the 17 advisories — good institutional memory. `CI / audit` green.
- **schemars (B5).** `Cargo.lock` resolves `schemars 1.2.2`; workspace declares `schemars = "1"`; both `pregolya-mcp` and `pregolya-core` use `{ workspace = true }`. No 0.8 anywhere.
- **xtask license (B3).** `license = "MIT OR Apache-2.0"` plus `publish = false`.
- **Workspace lints (B4).** `unsafe_code = "forbid"` present; all 21 library crates inherit via `[lints] workspace = true`. `xtask` opts out deliberately with a narrower explicit set and a documented rationale for omitting `print_stdout`/`print_stderr` — correct call for a CLI tool, and better than inheriting-then-allowing.
- **CI hardening (B9).** All 8 jobs carry `timeout-minutes` (10–30, sized to the work). All three actions SHA-pinned with version comments and a maintenance note in the header. `permissions: contents: read` at workspace level. `concurrency` with `cancel-in-progress`. No job-level `hashFiles` — all guards moved to step level. `branches-ignore: factory-artifacts`. `set -euo pipefail` on every `run` block. The non-certifying `exit 1` skip steps are the right instinct.
- **`just iter --no-tests=warn` (B8).** Present, and the `filter` interpolation matches the `just iter <crate> [test_filter]` signature documented in CLAUDE.md.
- **B6.** Measured: `check-file-size` exits 1 when tokei is absent from `PATH`.
- **File-size gate positive control.** Measured: an 800-line planted file produces `HARD GATE FAIL` and exit 1.
- **Credential hygiene.** `.env.example` contains four key names and zero values. `.gitignore` covers `.env`, `.envrc`, `*.env.*` with a correct `!.env.example` re-inclusion. GitGuardian green.
- **All 22 crates compile clean** under `clippy --all-targets -D warnings` with `#![warn(missing_docs)]` active — verified locally on the pinned 1.98.0 toolchain.

---

## Path to approval

F1 and F5 are configuration and alignment changes. F2, F3, and F4 are scoped fixes to `xtask/src/main.rs`
plus one CI pin. None requires architectural rework, and none touches the dependency hygiene that is the
strongest part of this PR.

The one item I would route rather than fix in-branch is F5's underlying question — whether inline
`#[cfg(test)]` blocks count toward the production budget. The implementer's position is defensible; it just
needs to be the human's call, with CLAUDE.md and the allowlist header updated to agree with whatever is
decided. Everything else is in-scope work.

I will re-review promptly on the next push. Please re-run the probes in F2/F3/F4 as regression tests once
fixed — each gate should now report a failure on its corresponding probe input, which is the cheapest way to
prove these are load-bearing rather than paper-fixed.

**Verdict: REQUEST_CHANGES** (5 blocking / MED, 3 suggestions, 1 nit)
