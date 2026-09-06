# PR Review — Cycle 10 (FINAL) — PR #1

| Field | Value |
|-------|-------|
| PR | #1 `chore/phase3-workspace-init` → `develop` |
| Reviewed SHA | `a2fda7983498995e96be4a60343166f642d9c4a1` |
| Cycle | 10 of 10 (final automated review) |
| Reviewer | pr-reviewer (fresh-eyes, information-asymmetry wall enforced) |
| Review verdict | **APPROVE** — 0 blocking, 1 suggestion, 4 nits |
| GitHub review state | `COMMENTED` (review `PRR_kwDOTWfxF88AAAABL8eK3w`) |
| GitHub review URL | https://github.com/BOHICA-LABS/pregolya/pull/1 |
| CI | 17/17 required checks pass |

## Posting-mechanism deviation (must be read before acting on this review)

The contract requires posting via `gh pr review --approve` or `gh pr review --request-changes`.
`gh pr review 1 --approve` was **attempted and DENIED by the permission system** on
self-approval grounds: the authenticated GitHub account (`drbothen`) is the PR author, and
approving a PR authored by the same automated pipeline defeats the two-party review
requirement. No user authorization for self-approval exists.

The review was therefore posted with `gh pr review 1 --comment --body-file` — still a formal
review object (not `gh pr comment`), but with state `COMMENTED` rather than `APPROVED`.

**Consequence:** if branch protection on `develop` requires an approving review, a **human must
click approve**. This review records the verdict; it cannot record the approval. This is a
permission boundary, not a review finding — do not treat the `COMMENTED` state as a
withheld verdict.

---

## Cycle 10 Review (FINAL) — PR #1 `chore/phase3-workspace-init` → `develop`

**Reviewed SHA:** `a2fda7983498995e96be4a60343166f642d9c4a1`
**Verdict: APPROVE** — no blocking findings. 1 suggestion, 4 nits.

I reviewed all 62 changed files, re-verified the two fix-7 changes by **differential probing**
(reverting each fix in an isolated tree and re-running the suite), and confirmed all 17
required checks green.

---

### Verification performed (not a rubber stamp)

| Check | Method | Result |
|---|---|---|
| `mod tests;` file-module resolution | `cargo test -p xtask` in isolated tree at HEAD | 27/27 pass — `src/tests.rs` resolves from `main.rs` (crate root), `use super::*;` reaches all private items (`scan_for_panics_in_source`, `scan_for_timeout_violations_in_source`, `is_test_file`) |
| B-7 correctness (char vs byte index) | Reverted to `line.as_bytes().get(i + 1) == Some(&b'/')`, added a probe with ≥3 extra bytes before the `//` **and** a `{` inside the comment | Probe **FAILS** pre-fix, **PASSES** post-fix — the bug was real and the fix resolves it |
| B-8 correctness (semicolon latch) | Reverted to the `is_file_module_decl` (`contains("mod ") && ends_with(';')`) check, probed `#[cfg(test)] use …;` + multi-line production fn | Probe **FAILS** pre-fix, **PASSES** post-fix — bug real, fix correct |
| `#[cfg(test)] type Foo = Bar;` (B-8 generality) | Reasoned + traced: line ends with `;` → `pending_cfg_test` never latches. Same for `use`, `const`, `static`, `mod`, `pub use`, `extern crate` | Correct |
| Unicode coverage of B-7 | `chars: Vec<char>` is indexed by `chars.get(i + 1)`; both the scan cursor and the lookahead are now in the same (char) index space, so the fix is category-independent — 2-byte (é), 3-byte (—, box-drawing ─), and 4-byte (astral/emoji) code points all behave identically | Correct for all Unicode |
| File-size gate | `tokei --output json` on the branch tree | `xtask/src/main.rs` = **446** code-lines, `xtask/src/tests.rs` = **305**. Both under the 500 prod soft / 1000 test soft targets. No allowlist entry needed (consistent with the N-4 removal) |
| fmt / clippy | `cargo fmt --all -- --check`, `cargo clippy --workspace --all-targets` in isolated tree | Clean |
| `reqwest` TLS rule | `git grep reqwest -- '*/Cargo.toml'` | Root declares `default-features = false, features = ["rustls-tls", …]`; all 7 consuming crates use `{ workspace = true }` — no `native-tls`/`default-tls` path anywhere. `deny.toml` additionally bans `native-tls`, `openssl`, `openssl-sys`, `openssl-probe` |
| CI | `gh pr checks 1` | 17/17 pass (fmt, clippy, test, build, file-size-gate, deny, audit, lint-extra, GitGuardian) |
| Diff coherence | All 62 files are workspace-init scaffolding + the xtask gate tool. No unrelated changes. | Clean |
| Commit quality | Conventional format, scoped, per-finding rationale in bodies, no AI attribution | Clean |

---

### Findings

#### [SUGGESTION] S-10.1 — The two new B-7/B-8 "regression tests" are not load-bearing

**File:** `xtask/src/tests.rs` — `test_no_panic_non_ascii_line_does_not_corrupt_depth`, `test_no_panic_cfg_test_use_statement_does_not_latch`

Both fixes in fix-7 are **correct** — I verified that independently. But neither of the two new tests would catch a revert of its own fix. I restored the pre-fix bodies of `scan_for_panics_in_source` in an isolated tree and re-ran the suite:

```
test tests::test_no_panic_cfg_test_use_statement_does_not_latch ... ok
test tests::test_no_panic_non_ascii_line_does_not_corrupt_depth ... ok
test result: ok. 27 passed; 0 failed
```

27/27 green **against the buggy code**. Why each is inert:

- **B-7 test** — the fixture is `"/// Contains résumé — Unicode doc comment\n#[cfg(test)]\n…"`. The `//` sits at column 0, where char index and byte index are still equal, so the old `line.as_bytes().get(i + 1)` lookahead breaks on exactly the same character. The non-ASCII appears *after* the `//`, where it can no longer affect anything. Additionally, a *closing* `}` inside a comment causes the test block to exit **early** (a false-positive direction), which still yields a non-empty `findings` — so even a correctly-positioned fixture needs an *opening* `{`. And the byte shift must be ≥3: with a shift of 1 or 2 the second `/`'s lookahead still lands on the first `/`, so the comment is detected one char late but still detected.

  Load-bearing form (verified FAIL pre-fix / PASS post-fix):
  ```rust
  let src = "#[cfg(test)]\nmod tests {\n    let s = \"a\u{2014}\u{2014}b\"; // {\n}\npub fn prod() {\n    let x: Option<i32> = Some(1);\n    x.unwrap()\n}\n";
  let findings = scan_for_panics_in_source(src, "src/lib.rs");
  assert!(!findings.is_empty());
  ```
  (two em-dashes = 4 extra bytes; `{` inside the comment inflates `brace_depth` so the test block never closes)

- **B-8 test** — the fixture puts the whole production fn on one line: `pub fn prod() { let x: Option<i32> = Some(1); x.unwrap() }`. The `in_test_block` check runs *after* the per-line char walk, and the `{` and `}` both process within that one line, so `in_test_block` is already back to `false` by the time the `.unwrap()` check runs. The finding is reported either way. Splitting the production fn across lines makes it real:
  ```rust
  let src = "#[cfg(test)] use std::collections::HashMap;\npub fn prod() {\n    let x: Option<i32> = Some(1);\n    x.unwrap()\n}\n";
  let findings = scan_for_panics_in_source(src, "src/lib.rs");
  assert!(!findings.is_empty());
  ```
  (verified FAIL pre-fix / PASS post-fix)

**Why it matters:** `xtask` *is* the CI enforcement surface. A gate whose own regression guards don't guard means a future refactor can silently reintroduce B-7 or B-8 with CI fully green. This is a TD-VSDD-059-class gap: the fix is load-bearing, the test evidence is not.

**Why it is not merge-blocking:** shipped behavior is correct and independently verified; 17/17 CI green; no production crate code is affected (the gate scans `crates/`, and all `crates/*/src/lib.rs` are ≤16 code-lines of scaffolding). The remedy is a two-fixture edit with no production change.

**Suggested fix:** replace the two fixtures above (≈4 lines). Please close this before the first story that adds real `crates/` code, since that is when a silent gate regression starts costing something.

#### [NIT] N-10.1 — Commit message line count is inaccurate

The fix-7 body says *"main.rs drops from ~750 to ~560 code lines."* `tokei --output json` measures **446**. Under-reporting, so the gate conclusion holds, but the number in the record is wrong. Since it is a commit message it can't be corrected in place — noting it so the story record cites 446/305.

#### [NIT] N-10.2 — Dead conjuncts in the B-7 guard

`scan_for_panics_in_source`, the `//` break condition:

```rust
if ch == '/' && !in_string_literal && !in_char_literal && chars.get(i + 1) == Some(&'/')
```

Both `!in_string_literal` and `!in_char_literal` are provably `true` here — the two `if in_string_literal { … continue; }` / `if in_char_literal { … continue; }` blocks earlier in the loop body already returned control for either state. Dropping them makes the invariant (`we are outside all literals`) legible instead of re-asserted. Cosmetic; no behavior change.

#### [NIT] N-10.3 — `check-file-size` runs twice in CI

`.github/workflows/ci.yml` runs `cargo xtask check-file-size` in both the `file-size-gate` job and as the first line of the `lint-extra` job's gate list. ~1 min of duplicated wall time per run, and two independent required checks that can only ever fail together. Consider dropping it from `lint-extra` (keeping the dedicated job as the named required check) — or keep the duplication deliberately and note why.

#### [NIT] N-10.4 — `just setup` doesn't install everything the recipes need

`setup` installs `tokei`, `cargo-deny`, `cargo-audit`, `cargo-nextest`. But `just check-ci` and the `pre-tag` lefthook both invoke `cargo semver-checks`, and `just cov` invokes `cargo llvm-cov` — neither is provisioned. A fresh clone hits a cryptic "no such subcommand" at tag time rather than at setup time. Either add `cargo install cargo-semver-checks --locked` + `cargo install cargo-llvm-cov --locked` to `setup`, or add a `command -v` guard with a pointer to `just setup` (the pattern `lefthook.yml` already uses correctly for `tokei` in `pre-push`).

---

### Observation (no action requested)

`pregolya-community` and `pregolya-macros` are workspace members but are not re-exported by the `pregolya` umbrella crate, while the other 13 are. If that is deliberate (opt-in community surface; macros re-exported later through `pregolya-core`), a one-line comment in `crates/pregolya/src/lib.rs` would stop a future reviewer from re-raising it.

---

### Checklist

| # | Item | Status |
|---|---|---|
| 1 | Diff coherence | PASS — all 62 files are workspace scaffolding + the xtask gate tool |
| 2 | Description accuracy | PASS with N-10.1 (line-count figure off) |
| 3 | Test coverage | PASS with S-10.1 — 27 tests cover every scanner branch; 2 of them don't gate their own fix |
| 4 | Demo evidence | N/A — infrastructure PR with no user-facing AC; CI job transcripts are the evidence |
| 5 | Commit quality | PASS — conventional, scoped, per-finding rationale, no AI attribution |
| 6 | Diff size | ~5,345 diff lines, but 20 of 21 crates are ≤16-line scaffolds; real review surface is `xtask` (751 code-lines) + 8 config files |
| 7 | Missing changes | PASS — `Cargo.toml` members, `.cargo/config.toml` xtask alias, `clippy.toml`, `deny.toml`, `rust-toolchain.toml`, `Justfile`, `lefthook.yml`, CI, allowlist all present and mutually consistent |
| 8 | Dependency status | PASS — no upstream PRs; this is the first workspace commit |

Cycle 1–9 fixes (B-1 … B-8, M-1 … M-8, F-1 … F-3, S-1/S-3/S-4/S-6, N-4) are all present at this SHA and none regressed.

**Approved for squash-merge into `develop`** (subject to the human approval click noted above).

---

## Finding table (machine-readable)

| ID | Severity | Category | Finding | Suggestion |
|----|----------|----------|---------|------------|
| S-10.1 | suggestion | coverage | The two new B-7/B-8 regression tests in `xtask/src/tests.rs` pass against the pre-fix (buggy) code — verified by differential revert. Neither gates its own fix. | Replace both fixtures with the load-bearing forms given above (≈4 lines). Close before the first story that adds real `crates/` code. |
| N-10.1 | nit | description | fix-7 commit message claims main.rs is "~560 code lines"; tokei measures 446. | Cite 446/305 in the story record; commit message is immutable. |
| N-10.2 | nit | coherence | `!in_string_literal && !in_char_literal` in the `//` break guard are provably true (earlier `continue` blocks). | Drop the two dead conjuncts. |
| N-10.3 | nit | coherence | `cargo xtask check-file-size` runs in both the `file-size-gate` and `lint-extra` CI jobs. | Drop from `lint-extra`, or document the duplication. |
| N-10.4 | nit | missing | `just setup` omits `cargo-semver-checks` (needed by `pre-tag` lefthook + `just check-ci`) and `cargo-llvm-cov` (needed by `just cov`). | Add both to `setup`, or add `command -v` guards pointing at `just setup`. |
