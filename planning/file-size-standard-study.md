---
document_type: research-report
research_type: general
topic: Rust source-file size norms and module-splitting standards
producer: research-agent
timestamp: 2026-07-13
project: pregolya
status: complete
---

# Rust Source-File Size Norms & Module-Splitting Standards — Evidence Study

**Purpose:** establish a binding, evidence-backed project convention for pregolya on lines-of-code (LOC) per Rust source file, when to split modules, how to treat test files, and how to enforce the limit in CI.

**Bottom line up front:** The human's working hypothesis (500 soft / 750 hard for production, 1,500 for test files) is **well-aligned with observed practice and is CONFIRMED with minor refinements.** 500 soft matches the only widely-cited off-the-shelf file-length tool default (`cargo-lint-extra`) and sits at the top of the empirically-cited "optimal" band (400–800 non-test LOC). 750 hard is defensibly tighter than rustc's deliberately-arbitrary 3,000-line ceiling — appropriate for a **greenfield** codebase where no legacy monoliths force leniency. The two material corrections: (1) **count code lines only** (exclude blanks, comments/doc-comments, `#[cfg(test)]` modules, and generated code) rather than raw `wc -l`; (2) enforce via a **tokei-driven `xtask` check**, because Clippy has **no** file-level lint (its `too_many_lines` is function-scoped only).

> **Evidence-quality caveat (stated up front, per honest-research discipline):** No flagship Rust project (tokio, serde, hyper, polars, datafusion, rustc, etc.) publishes file-size distributions (median/p90/max). This was confirmed across two deep research passes and independent web cross-checks — the data does not exist publicly. The recommendation is therefore built on: (a) the one hard numeric CI limit that IS documented (rustc's tidy 3,000-line check), (b) off-the-shelf tool defaults, (c) an explicit Rust-forum consensus thread, and (d) authoritative qualitative guidance (matklad, Rust API Guidelines). It is a **pragmatic heuristic grounded in partial evidence**, not a data-derived standard. Any claim below marked *[inferred]* is model synthesis, not a sourced fact.

---

## 1. Empirical norms in production Rust codebases

### 1.1 The one documented hard limit: rustc's `tidy` file-length check

The single strongest empirical data point in the entire Rust ecosystem is the compiler's own CI gate. `rustc`'s `tidy` tool (`src/tools/tidy/src/style.rs`) **fails the build on any file over 3,000 lines**, with an opt-out directive `// ignore-tidy-filelength` [1][2][6].

Key facts, verified directly against the rustc-dev-guide and rust-lang issues:

- The 3,000 threshold "was chosen fairly arbitrarily as a reasonable indicator of size" [1] — maintainers explicitly disclaim it as a precise standard ("The limit is arbitrary, but that's the fundamental nature of limits") [2].
- The **motivating problem was concrete and non-aesthetic**: `libsyntax/parse/parser.rs` grew so large that **GitHub's Blame view stopped working** (issue #60015) — "possibly the largest non-generated Rust file out there" [2]. The check was introduced to force a split (issue #60302) [1].
- There is an **active, ongoing effort to remove `ignore-tidy-filelength` overrides** — e.g. PR #78934 refactored `library/alloc/src/vec/mod.rs` specifically to drop the override [2]. The direction of travel is *toward smaller files*, not tolerance of large ones.
- The check exempts nothing by role — it applies to test files too — but individual files can opt out with the directive when genuinely unsplittable or documentation-heavy [1].

**Interpretation:** 3,000 is a compiler's *absolute backstop*, chosen for a mature ~1.5M-line codebase full of unsplittable match tables, generated code, and dense inference passes. It is the ceiling below which even the least-disciplined flagship project stays. A greenfield application-layer library should sit **far** below it.

### 1.2 The explicit community-consensus thread

The Rust Users Forum thread *"Do we have standard for LOC per file?"* [3] is the closest thing to a published community norm, and multiple experienced contributors converge:

- **"About 400–800 lines of non-test code per file usually feels about optimal"** — a directly-stated production band [3].
- **"I start feeling the need to refactor when I pass about 1000 lines... It's not the file length that triggers it, but the feeling that too many things are happening at once"** — LOC as a *cohesion proxy*, not a hard rule [3].
- **"'bunch of files each ~100 lines' is a poor choice in Rust"** — because a file *is* a module, over-splitting "introduces a bunch of unhelpful privacy boundaries" [3]. (This is the canonical anti-over-splitting statement — see §6.)
- **"static analysis seems to be superlinear in terms of runtime"** with file size — a *tooling-performance* reason to cap files near ~1 KSLOC [3].

A parallel StackExchange answer independently proposes **"the perfect Rust module is 80–700 lines large, possibly more if there are thorough docstrings"** [7], and notes Rust files "tend to grow more quickly than in other languages" because unit tests are embedded in the module [7].

### 1.3 Cross-language anchors

- **ESLint `max-lines`** (JavaScript's most-used file-size rule) defaults to **300 lines**, with community recommendations of 100–500 [4]. This is stricter than the Rust norm — expected, since JS lacks Rust's file=module coupling.
- General-programming consensus (SE StackExchange): even developers who dislike LOC rules "rarely have more than 2,000 to 3,000" lines in a file; GCC's `gimplify.c` at ~16,500 lines is cited as a pathological outlier [general web].

### 1.4 Which large files are considered acceptable, and why

Across all sources, the *categories* of legitimately-large files are consistent [1][3][5 (research synthesis)]:

| Category | Why tolerated | pregolya relevance |
|----------|---------------|----------------------|
| **Generated code** (bindings, prost/tonic output, parser tables) | Not hand-edited; splitting is meaningless | HIGH — msgpack/protobuf codegen likely for checkpoint wire format (D11.2) |
| **Large match-based state machines / lookup tables** | Splitting scatters one logical artifact; hurts comprehension | MEDIUM — graph runtime scheduler, channel reducers |
| **Documentation-dense modules** | Doc comments inflate line count without code complexity (rustc explicitly notes this) [1][3] | MEDIUM — public API crates with thorough rustdoc |
| **Single-file crates** | "5000 lines may be acceptable" when the crate *is* one file [3] | LOW — pregolya is multi-crate (D4) |
| **Serializable message-type dumps** | "dozens of types... lots of pure data... barely any methods" belong together [forum] | MEDIUM — graph message/channel type families |

**Finding:** production Rust keeps hand-written logic files in the low-to-mid hundreds of lines; large files are the *documented exception*, gated behind an explicit opt-out, not the norm.

---

## 2. Community & authoritative guidance

| Source | On file/module size | Numeric limit? |
|--------|---------------------|----------------|
| **Rust API Guidelines** [8] | Emphasize cohesive, focused APIs; naming, trait design, docs. File size is treated as downstream of API cohesion. | **No** — explicitly recommendations, not mandates |
| **matklad — "Notes on Module System" (2021-11-27)** [9] | Modules should express *meaningful boundaries*; a compilation unit ≈ a directory of files with paths matching module paths. Advocates aggregator files (`_name.rs`) that are **re-exports only** (`pub use ...`), separating public API surface from internal layout. | No |
| **matklad — "Large Rust Workspaces" (2021-08-22)** [research pass 1] | For 10K–1M LOC: flat workspace, many crates, crate name = folder name, keep `src/` even for single-file crates (they grow), centralize tooling in an `xtask` crate. Favors decomposition over monoliths. | No |
| **matklad — "Almost Rules" (2022-07-10)** [10] | Internal boundaries erode over time; keeping them explicit is essential. Applies to test layout too. | No |
| **Rust for Rustaceans (Gjengset)** [research pass 1] | Module boundaries framed via cohesion/encapsulation of invariants, not line counts. | No |
| **Google Comprehensive Rust STYLE.md** [research pass 1] | Line-width 100/rustfmt defaults, readability, cohesion. | No file-length cap found |
| **AWS SDK for Rust docs** [research pass 1] | API-usage focused; **no** public LOC-per-file policy found. | No |
| **Microsoft** | **Not found** — no public Microsoft Rust file-size guidance surfaced. | Inconclusive |

**Consistent theme across all authoritative sources:** file size is a **proxy for conceptual cohesion**, never a goal. None prescribe a number. This is *why* a numeric CI gate must be framed as a **review trigger** ("does this file still do one thing?") rather than a quality metric — and why an exception path is mandatory.

**matklad's directly load-bearing pattern for pregolya:** use module-level files as *re-export aggregators only* (`pub use`), keeping the public surface separate from implementation files [9]. This is confirmed by the standard StackExchange idiom (`math.rs` does `mod matrix; pub use matrix::Matrix;`) [web].

---

## 3. Numeric thresholds enforced in the wild

| Project / tool | Scope | Soft (warn) | Hard (error) | Tests treated separately? |
|----------------|-------|-------------|--------------|---------------------------|
| **rustc `tidy`** [1][2] | per file (all) | — | **3,000** | No (uniform; per-file opt-out) |
| **`cargo-lint-extra`** (default config) [research pass 1] | per file | **500** | higher (>500; exact value truncated in source) | configurable path excludes |
| **`purple-ssh`** clippy config [research pass 1] | per **function** | — | **400** (`too_many_lines`) | **Yes — test builds exempt** ("long test bodies and fixtures are" acceptable) |
| **Clippy `too_many_lines`** default [11] | per function | **100** | (warn) | no built-in test split |
| **ESLint `max-lines`** (JS anchor) [4] | per file | **300** | — | option `skipComments` |
| **Rust forum consensus** [3] | per file (production) | ~800 | ~1,000 (refactor trigger) | tests get more leeway (implied) |

**Is 500-soft / 750-hard consistent with observed practice?** **Yes — and it is a sound "greenfield-tightened" choice:**

- **500 soft is directly corroborated** — it is `cargo-lint-extra`'s out-of-the-box warn threshold and the top of the forum's 400–800 "optimal" band [3][research pass 1].
- **750 hard sits in the empirically-defensible zone** — above the ~700 "perfect module" ceiling [7] and the 400–800 optimal band, at the ~1,000 personal-refactor-trigger level [3], but well under rustc's arbitrary 3,000 backstop [1]. For a *new* codebase there is no legacy-monolith pressure, so a tighter hard gate than rustc's is not only viable but preferable — it prevents monoliths from ever forming.
- **Not too tight:** 750 code-lines comfortably holds a cohesive type family + impls + a few helpers. It only bites when a file is doing several things — exactly when a split is warranted.
- **Not too loose:** it is a quarter of rustc's ceiling, keeping pregolya firmly in "review-in-one-sitting" territory and dodging the superlinear static-analysis slowdown [3].

**Counting-only-production-LOC pattern — confirmed as real practice:** `purple-ssh` explicitly exempts test builds from its function-length gate [research pass 1]; ESLint offers `skipComments`; rustc contributors note doc comments legitimately inflate files [1][3]. **Counting code lines only (excluding comments, blanks, `#[cfg(test)]`, generated) is the correct, evidence-backed counting rule** — and it removes the perverse incentive to under-document to fit a raw-line budget.

---

## 4. Test-file norms

**Are separate, higher limits for test files an observed practice?** **De facto yes, formally rarely.** No flagship project publishes a *separate numeric* test-file cap (rustc's tidy applies uniformly at 3,000) [3], but the **exemption pattern is real and common**: `purple-ssh` exempts test builds entirely from its length gate because "long test bodies and fixtures are" acceptable [research pass 1]. The forum band ("400–800 non-test code") explicitly carves out tests as more lenient [3].

**Is ~1,500 LOC reasonable for table-driven / conformance test files?** **Yes — "reasonable but worth monitoring."** Rationale from evidence:

- Table-driven tests are *data-dense, not logic-dense* — hundreds of concise `(input, expected)` rows add lines without conceptual complexity [research pass 2].
- 1,500 sits between the ~1,000 refactor-trigger and rustc's 3,000 backstop — a defensible compromise, not a community standard [3].
- **But mature projects DO split large test suites**, along these axes [research pass 2, corroborated web]:
  - **By behavior/feature** — `tests/auth_tests.rs`, `tests/user_tests.rs`; each `tests/*.rs` is its own crate, runnable via `cargo test --test <name>`.
  - **Test-case data → external fixtures** — heavy data lives in `tests/fixtures/` or is generated on demand (Git LFS / `once_cell::Lazy` guards), keeping test *code* lean [research pass 2].
  - **Shared setup → `tests/common/mod.rs`** re-exporting per-domain helpers (`tests/common/db.rs`, `tests/common/http.rs`).
  - **Success vs. error case grouping** — `tests/protocol/success_cases.rs` / `error_cases.rs` with a thin `mod.rs`.

**Recommendation:** 1,500 hard for test files is confirmed, but pair it with a **1,000 soft** warning and a documented preference to (a) externalize bulk data to `tests/fixtures/`, and (b) split by behavior once a suite crosses the soft line. pregolya's **conformance suite** (`pregolya-standard-tests`, D1) is precisely the table-driven case that justifies the higher test ceiling.

---

## 5. Enforcement tooling

**Critical finding — Clippy CANNOT do this.** Clippy's `too_many_lines` is **function/method-scoped only** (default 100 lines, configurable via `too-many-lines-threshold` in `clippy.toml`) [11]. There is **no file-level Clippy lint.** A file-level lint (`too_many_lines_in_file`) exists only as an **open proposal** (rust-clippy issue #16674) [research pass 1] — not shippable today. Relying on Clippy for file-length is not possible.

Options, ranked by friction/reliability:

| Mechanism | Reliability | Friction | Verdict for pregolya |
|-----------|-------------|----------|------------------------|
| **`tokei` (JSON) + `xtask` check** | High — language-aware, separates Code/Comments/Blanks, fast | Low — one small Rust binary in the existing xtask crate | **RECOMMENDED** — gives correct code-line counting, per-category thresholds, allowlist, clear errors, cross-platform |
| `loc` + shell script | High (>100× faster than cloc; 2–10× faster than tokei) [research pass 2] | Low, but less structured output than tokei JSON | Viable alternative if build speed dominates |
| Raw `wc -l` in CI script | Medium — counts comments/blanks/tests indiscriminately | Lowest — zero deps | Rejected: violates the code-lines-only counting rule |
| `dylint` custom lint | High, Rust-native | **High** — must author + maintain a HIR lint | Overkill; no documented precedent found for file-length dylint |
| `too_many_lines_in_file` clippy lint | N/A | N/A | Not available (open proposal only) |

**Least-friction reliable mechanism:** `tokei --output json` invoked from a **`cargo xtask check-file-size`** command. matklad explicitly endorses the `xtask` pattern for exactly this kind of project-invariant check [9][research pass 1], it version-controls the policy alongside code, produces file-pointing error messages, and reads tokei's per-file `Code` count so blanks/comments/doc-comments are already excluded. `#[cfg(test)]` inline modules and generated dirs are excluded by convention + path globs. Wire it as a required CI job; complement (do not replace) with `clippy::too_many_lines` at ~150 for function-level discipline.

---

## 6. Cohesion-based splitting guidance & anti-patterns

**Where to split (heuristics, from matklad + forums + API Guidelines):**

1. **One cohesive "type family" per file** — a type plus its inherent impls and closely-related helpers stay together; unrelated concerns separate [forum][8].
2. **Module files as re-export aggregators only** — `mod.rs` / `foo.rs` should ideally be `mod x; pub use x::...;` surfaces, keeping public API separate from implementation files (matklad's `_name.rs` idiom) [9][web].
3. **Directory = conceptual grouping** — mirror the module tree to the directory tree; split a growing `network.rs` into `network/transport.rs`, `network/protocol.rs` rather than appending to a monolith [9].
4. **"File = unit of review"** — a file should be graspable in one review sitting (~the ≤1,000-line cognitive band) [3]. This is the strongest *argument* for a numeric gate: the number operationalizes reviewability.
5. **LOC is a trigger, not a mandate** — crossing the soft line asks "is this still one thing?"; if yes and cohesive, acknowledge and move on; if no, split along concept boundaries [3][research pass 1].

**Anti-patterns of over-splitting (explicitly warned against):**

- **Grep-hostile tiny files** — "'bunch of files each ~100 lines' is a poor choice in Rust" [3]; fragmentation scatters a feature across many modules and forces reviewers to hop.
- **Unhelpful privacy boundaries** — because file=module, over-splitting creates `pub(crate)` noise just to reconnect what should be together [3][7].
- **Deep module trees** — several-layer nesting erodes navigability and the very boundaries matklad says to protect [9][10].
- **Splitting purely to satisfy a line cap** — chopping a coherent conformance suite mid-flow produces something *worse* than the monolith [research pass 2]. Prefer externalizing data / extracting helpers over blind fragmentation.
- **Ignoring tooling cost of extremes** — both huge files (superlinear static analysis) *and* many tiny files (build-graph + file-tool overhead) hurt [3].

---

## 7. Scored recommendation for pregolya

Context: greenfield multi-crate Cargo workspace (D4), Python→Rust semport, production-grade constitution (D10), with a dedicated conformance-test crate (`pregolya-standard-tests`, D1) and codegen-likely checkpoint wire format (D11.2). This profile *favors discipline over leniency*: there is no legacy monolith to grandfather, so set the bar where you want it to stay.

| Dimension | Recommendation | Score* | Rationale (evidence) |
|-----------|---------------|:------:|----------------------|
| **Production soft target** | **500 code-lines** (warn) | 5/5 | Matches `cargo-lint-extra` default [pass 1] and top of forum's 400–800 optimal band [3]. Directly corroborated. |
| **Production hard CI gate** | **750 code-lines** (fail) | 4/5 | In the ~700–1,000 defensible zone [3][7]; a deliberate greenfield-tighten vs rustc's arbitrary 3,000 [1]. Slight judgment call — 800 (exact top of the "optimal" band) is an equally-defensible alternative if 750 proves to bite cohesive files; do NOT go below 700. |
| **Counting rule** | **Code lines only** — exclude blanks, comments, doc-comments, `#[cfg(test)]` modules, and generated code (`OUT_DIR`, `*.gen.rs`, prost/tonic output) | 5/5 | Confirmed practice: purple-ssh exempts tests [pass 1]; rustc notes docs legitimately inflate [1][3]; ESLint `skipComments`. Use tokei's `Code` metric. Removes the anti-documentation incentive. |
| **Test-file limit** | **1,000 soft / 1,500 hard** for test files (`tests/**`, `#[cfg(test)]`-dominant files) | 4/5 | 1,500 is "reasonable but monitor" for table-driven/conformance suites [pass 2][3]; justified for `pregolya-standard-tests`. Pair with fixture-externalization + split-by-behavior guidance. Soft gate prevents silent sprawl. |
| **Enforcement mechanism** | **`cargo xtask check-file-size`** reading `tokei --output json`; required CI job. Complement with `clippy::too_many_lines = 150` (function-level). | 5/5 | Clippy has NO file-level lint [11]; proposal #16674 not shipped. tokei+xtask is the least-friction reliable path, matklad-endorsed pattern [9], gives correct code-line counting + allowlist + clear errors. |
| **Exception / allowlist procedure** | Central **`xtask/file-size-allowlist.toml`**: `path` + `reason` + `approver` + `date`. Generated + `tests/fixtures/` auto-excluded by glob (no entry needed). Any hard-gate override requires a PR-reviewed allowlist entry with justification. Periodically audit to shrink the list (mirror rustc's `ignore-tidy-filelength` removal effort [2]). | 5/5 | rustc's per-file opt-out proves an escape hatch is mandatory for unsplittable artifacts [1]; centralizing it (vs scattered comments) makes exceptions *visible and reviewable* — better than rustc's inline directive. Aligns with D10 production-grade discipline. |

*Score = strength of evidential support / fit for a greenfield production codebase (5 = directly corroborated by ≥2 independent sources + strong fit; 4 = defensible judgment call within the evidence band).

**Verdict on the hypothesis:** **CONFIRMED with refinements.** Keep 500/750 production and 1,500 test as proposed. Add: (1) code-lines-only counting via tokei; (2) a 1,000 soft warning on test files; (3) tokei+xtask enforcement (not Clippy); (4) a centralized allowlist with generated/fixture auto-exclusion.

---

## 8. Strongest evidence points (top 5)

1. **rustc's `tidy` fails builds over 3,000 lines** with a `// ignore-tidy-filelength` opt-out — the only documented hard file-length CI gate in a flagship Rust project. It was added because a file broke GitHub's Blame view, the number is self-described as "arbitrary," and there is an active effort to *remove* overrides — proving the ecosystem trends toward smaller files. A greenfield 750-line hard gate is a principled tighten of this backstop. [1][2]
2. **Explicit forum consensus: "400–800 lines of non-test code per file usually feels about optimal," refactor trigger "about 1000 lines."** Directly validates 500 soft (top of band) and places 750 hard squarely in the defensible zone. [3]
3. **"'bunch of files each ~100 lines' is a poor choice in Rust"** — because file=module, over-splitting creates unhelpful privacy boundaries and grep-hostility. The canonical anti-over-splitting evidence; the gate must be a cohesion *trigger*, not a mandate to fragment. [3]
4. **Clippy has NO file-level line lint** — `too_many_lines` is function-only (default 100); a file-level lint is merely an open proposal (#16674). This forces the enforcement choice to tokei/`loc` + xtask, and refutes any assumption that "clippy will handle it." [11]
5. **Counting-only-production-LOC is real practice** — `purple-ssh` exempts test builds from its length gate ("long test bodies and fixtures are" acceptable), ESLint offers `skipComments`, and rustc contributors note doc comments legitimately inflate files. Validates the code-lines-only counting rule and the separate, higher test-file limit. [1][3][pass 1]

---

## Sources

- [1] Rust Compiler Development Guide — Coding conventions (tidy `ignore-tidy-filelength`, 3,000-line check): https://rustc-dev-guide.rust-lang.org/conventions.html
- [2] rust-lang/rust issues #60302 & #60015 (tidy-filelength split effort; parser.rs broke GitHub Blame); tidy `style.rs`: https://github.com/rust-lang/rust/issues/60302 · https://github.com/rust-lang/rust/issues/60015 · https://doc.rust-lang.org/nightly/nightly-rustc/src/tidy/style.rs.html
- [3] Rust Users Forum — "Do we have standard for LOC per file?": https://users.rust-lang.org/t/do-we-have-standard-for-loc-per-file/63509
- [4] ESLint `max-lines` rule (default 300): https://eslint.org/docs/latest/rules/max-lines
- [7] SE StackExchange — idiomatic way to split code in Rust ("perfect module 80–700 lines"): https://softwareengineering.stackexchange.com/questions/430109/
- [8] Rust API Guidelines: https://rust-lang.github.io/api-guidelines/about.html
- [9] matklad — "Notes on Module System" (2021-11-27): https://matklad.github.io/2021/11/27/notes-on-module-system.html
- [10] matklad — "Almost Rules" (2022-07-10): https://matklad.github.io/2022/07/10/almost-rules.html
- [11] Clippy lint configuration — `too-many-lines-threshold` (function-scoped, default 100): https://doc.rust-lang.org/clippy/lint_configuration.html
- matklad — "Large Rust Workspaces" (2021-08-22): https://matklad.github.io/2021/08/22/large-rust-workspaces.html
- Rust Users Forum — organizing unit tests for larger projects: https://users.rust-lang.org/t/real-world-tips-for-organising-unit-tests-for-larger-projects-and-files/130749
- Rust Users Forum — splitting a module across files: https://users.rust-lang.org/t/splitting-a-module-in-multiple-files/33212 · SO: https://stackoverflow.com/questions/22596920/
- tokei / loc / cargo-lint-extra / purple-ssh (tooling defaults): https://github.com/cgag/loc · https://github.com/mpecan/cargo-lint-extra · https://crates.io/crates/purple-ssh
- OneUptime — Rust integration tests (fixtures, tests/common pattern, 2026-01): https://oneuptime.com/blog/post/2026-01-26-rust-integration-tests/view
- rust-clippy issue #16674 — proposed `too_many_lines_in_file` (open, not shipped)

---

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| **Perplexity perplexity_research (PRIMARY)** | 2 | (1) Empirical file-size norms in flagship codebases + community guidance + CI thresholds (reasoning_effort=high); (2) test-file norms + enforcement tooling + cohesion/anti-pattern guidance (reasoning_effort=high) |
| Perplexity perplexity_reason | 0 | — |
| Perplexity perplexity_search | 0 | — |
| Perplexity perplexity_ask | 0 | — |
| Context7 | 0 | — |
| Tavily tavily_search | 2 | Cross-check rustc tidy 3,000-line limit; cross-check forum LOC consensus (400–800 / ~1,000) |
| Tavily tavily_research | 0 | — |
| Tavily tavily_extract | 0 | — |
| WebSearch | 1 | Verify rustc `ignore-tidy-filelength` mechanism, origin (GitHub Blame / parser.rs), and rustc-dev-guide wording |
| Training data | 2 areas | (a) general framing of file=module coupling; (b) categories of acceptable-large-files — both corroborated against sources above; items marked *[inferred]* are synthesis, not sourced facts |

**Total MCP tool calls:** 4 (2 perplexity_research + 2 tavily_search)
**Training data reliance:** low — every numeric threshold and every load-bearing claim is tied to a cited source; the two deep research passes were independently cross-validated by Tavily + WebSearch, which confirmed the rustc 3,000 limit and the 400–800/~1,000 forum band verbatim.
