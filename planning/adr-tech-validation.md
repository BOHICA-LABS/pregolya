---
artifact: planning/adr-tech-validation
version: 1.2.0
created: 2026-07-13T00:00:00Z
updated: 2026-07-22T00:00:00Z
input_level: L3
recommendation: MOSTLY-VALID (1 competitive BLOCKER-flag, 2 STALE version corrections; D21 ADRs validated 2026-07-20; D23 ADR-020 deps validated 2026-07-21)
confidence: high
assessor: research-agent (perplexity sonar-deep-research + crates.io registry verification)
assessed_at: 2026-07-22
inputs:
  - .factory/specs/architecture/decisions/ADR-002-checkpoint-format.md
  - .factory/specs/architecture/decisions/ADR-004-serde-schemars-schema-generation.md
  - .factory/specs/architecture/decisions/ADR-003-durability-tiers.md
  - .factory/specs/architecture/decisions/ADR-008-proc-macro-attributes.md
  - .factory/specs/architecture/decisions/ADR-014-vectorstore-retriever-abstraction.md
  - .factory/specs/architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - .factory/specs/architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - .factory/specs/architecture/decisions/ADR-017-embeddings-trait-provider-integration.md
  - .factory/specs/architecture/decisions/ADR-020-first-party-tool-library.md
input-hash: "a534b58"
changelog:
  - "1.2.0 (crates.io/2026-07-21): Add §7 D23 ADR-020 dependency validation — `similar` 3.1.1 GREEN (pin `\"3\"`, owner mitsuhiko not dtolnay, Apache-2.0 single, MSRV 1.85, TextDiff::ratio() confirmed); `regex` 1.13.1 GREEN (pin `\"1\"`, MIT OR Apache-2.0, MSRV 1.65, linear-time guarantee, net-new workspace dep); fuzzy-matcher REJECTED (stale 2020); strsim deferred."
  - "1.1.0 (crates.io/2026-07-20): Add §6 D21 ADR technology validation — inventory 0.3.24 GREEN, minijinja 2.21.0 GREEN, mustache REJECTED (abandoned 2018-02), embeddings no-crate GREEN, vector-math no-crate GREEN."
  - "1.0.0 (2026-07-13): Initial validation covering ADR-002/003/004/008 — schemars, rmp-serde, verification toolchain, provider APIs, competitive watch."
---

# ADR Technology Validation — ferrochain Phase-1

**Validation date:** 2026-07-13. All version numbers verified against the live crates.io API
on this date (not from model training data). Provider-API and competitive findings verified
against Perplexity `sonar-deep-research` (web-grounded) plus direct registry/doc fetches.

## TERSE Verdict (one line per question)

1. **schemars (ADR-004):** VALID — schemars **1.2.1** (crates.io, 2026-02-01) is current; 1.x is the maintained series (no 2.x). Targets JSON Schema **2020-12**. Derive/serde integration mature. Minor caveat below on public-API schema stability. adk-rust's schemars-1.0 assumption still holds (1.x current).
2. **msgpack / rmp-serde (ADR-002):** VALID — `rmp-serde` **1.3.1** (2025-12-23), actively maintained, self-describing (correct rationale). Add one alternatives-paragraph: **postcard 1.1.3** and **bincode 2.0.1/3.0.0** now both exist and are worth a one-line mention (both still non-self-describing — ADR's core reasoning unchanged). Minor STALE nuance: ADR speaks of bincode pre-2.0; bincode 2.x stabilized Mar 2025.
3. **Verification toolchain (SS-17):** VALID with one important caveat — Kani **0.67.0** (2026-01-16), cargo-fuzz **0.13.2** (2026-06-09), cargo-mutants **27.1.0** (2026-06-02) all current & maintained. **CAVEAT/BLOCKER for harness authoring: Kani still has no native async/`.await` support** — tokio proof harnesses must drive futures via a manual executor/`block_on`, not verify real async scheduling. SS-17 should state this explicitly.
4. **Provider APIs (DTU):** VALID — OpenAI official OpenAPI spec still published (`github.com/openai/openai-openapi`); Anthropic version header still **`2023-06-01`** (no official OpenAPI spec, community spec only); Ollama API docs now at `docs.ollama.com/api` (unversioned, stable). **One breaking-change flag:** OpenAI is deprecating older surfaces (Realtime API beta removed; Assistants API sunset; migration to Responses API) — Anthropic & Ollama: no breaking changes in last 6 mo.
5. **Competitive watch (R4 / SC-2):** **BLOCKER-FLAG** — the `langgraph` crate on crates.io (**0.2.5**, 2026-07-01) now ships `PostgresSaver`/`SqliteSaver` durable checkpointing with pause/resume + time-travel. NOT yet 1.0/GA (~50% docs, pre-1.0), but it directly targets ferrochain's differentiator. `rig-core` **0.40.0** (2026-07-11) has serializable `AgentRun` (persist-intent) but no GA durable checkpointer; swiftide/kalosm: none.
6. **D21 ADRs (ADR-014 through ADR-017, crates.io/2026-07-20):** VALID — `inventory = "0.3"` (0.3.24) GREEN; `minijinja = "2"` (2.21.0) GREEN; `mustache` crate REJECTED (abandoned, last release 2018-02); embeddings approach (no separate crate — OpenAI+Ollama HTTP direct) GREEN; vector-math approach (no crate — `Vec<f32>` cosine) GREEN.
7. **D23 ADR-020 deps (crates.io/2026-07-21):** VALID with attribution fix — `similar = "3"` (3.1.1) GREEN, owner corrected to mitsuhiko (NOT dtolnay), Apache-2.0 single-licensed (cargo-deny allowlist required), MSRV 1.85; `regex = "1"` (1.13.1) GREEN, MIT OR Apache-2.0, MSRV 1.65, linear-time guarantee; fuzzy-matcher REJECTED (stale 2020, wrong shape); both deps net-new workspace entries (workspace uninitialized).

---

## 1. schemars (ADR-004, D5) — VALID

| Fact | Finding (verified 2026-07-13) | Source |
|------|-------------------------------|--------|
| Current version | **1.2.1**, published 2026-02-01 | crates.io API |
| Major series | 1.x is current & maintained; **no 2.x exists** | crates.io / docs.rs |
| JSON Schema draft | **Draft 2020-12** by default (`SchemaSettings` default "currently conform[s] to JSON Schema 2020-12"; draft-07 / 2019-09 presets also available) | docs.rs schemars `SchemaSettings` |
| serde integration | Mature — design goal is to mirror serde ser/de behavior; `#[derive(JsonSchema)]` + `schema_for!` are the stable, widely-used entry points | docs.rs / GitHub |
| adk-rust schemars 1.0 | 1.x remains the current/recommended series, so the assumption is still valid. Exact adk-rust pin could not be confirmed from snippets (low-confidence on that sub-fact only). | Perplexity (flagged unverified) |

**Public-API caveat (not a blocker, worth an ADR consequence note):** the 0.8→1.0 transition
changed the generated-schema type model (the old monolithic `RootSchema` gave way to the 1.x
`Schema` model). ADR-004 line 55 specifies `schema: schemars::schema::RootSchema` on
`ToolDefinition` — **verify this path against schemars 1.2 before locking the public type**, as the
`schema::RootSchema` module path is a 0.8-era shape. In 1.x the idiomatic type is
`schemars::Schema` (a transparent JSON wrapper). Additionally, schema *naming* stability
(enum ref-variant names, `$ref` naming) is an area still under active discussion upstream —
relevant because tool-arg schemas are part of ferrochain's **public** API surface and schema
churn between schemars versions could be observable to API consumers. Recommendation: pin schemars
with a caret on 1.x and add a conformance snapshot test on generated tool schemas.

**ADR-004 action:** Update the `RootSchema` reference to the schemars 1.x `Schema` type; add a
consequence bullet on schema-naming stability + a snapshot test. Core decision (adopt schemars) is VALID.

## 2. msgpack / rmp-serde (ADR-002, D11.2) — VALID (add alternatives paragraph)

| Crate | Current version | Status | Self-describing? |
|-------|-----------------|--------|------------------|
| **rmp-serde** | **1.3.1** (2025-12-23) | Actively maintained, stable | Yes (msgpack is tagged/self-describing) — ADR rationale correct |
| postcard | 1.1.3 (2025-07-24) | Stable, maintained, `no_std` focus | **No** — stable documented wire format but requires external versioning |
| bincode | 2.0.1 (2025-03-10) stable; 3.0.0 (2025-12-16) latest | 2.x rewrite stabilized (own encode/decode traits, serde optional) | **No** — non-self-describing |

**Suggested one-paragraph alternatives note for ADR-002:** *"Two Rust-native binary formats
matured since this decision: `postcard` 1.1.x (compact, `no_std`, stable wire format) and
`bincode` 2.x (2.0 rewrite stabilized Mar 2025 with standalone encode/decode traits). Both remain
**non-self-describing**, so neither changes the msgpack rationale: schema evolution (adding fields
to `GraphState`) would require an explicit version-tag layer with either, whereas msgpack's tagged
format tolerates additive changes with less ceremony. rmp-serde 1.3.1 remains the recommended
choice; postcard/bincode are noted for completeness."*

**Minor STALE nuance:** ADR-002 line 39 discusses bincode without acknowledging the 2.0 rewrite.
The core claim (bincode not self-describing, needs explicit version handling) is **still accurate**
for 2.x/3.0, so this is cosmetic. No decision change.

> Note: a Perplexity source characterized bincode 3.0.0 as an unmaintained/"stub" release with
> maintained forks (`bincode2`, `bincode-next`). This could **not** be independently confirmed and
> conflicts with crates.io showing 3.0.0 as the current release (2025-12-16). Treated as unverified;
> does not affect the ADR since bincode is a rejected alternative regardless.

## 3. Verification toolchain (SS-17) — VALID (with async caveat)

| Tool | Current version | Status | Notes |
|------|-----------------|--------|-------|
| **Kani** (kani-verifier) | **0.67.0** (2026-01-16) | Active (AWS model-checking) | Pins a specific nightly rustc internally; run via `cargo kani`. Bit-precise model checker. |
| **cargo-fuzz** | **0.13.2** (2026-06-09) | Active | libFuzzer-based; works with async by wrapping in a sync entry point that blocks on a runtime. |
| **cargo-mutants** | **27.1.0** (2026-06-02) | Active | Mutation testing; runtime-agnostic, works with tokio tests as-is. |

**Important caveat for proof-harness authoring (async/tokio):** As of mid-2026, **Kani still does
not natively model async/`.await` scheduling.** Proof harnesses over async code must drive futures
manually (poll/`block_on` via a minimal executor) — Kani verifies the state-machine logic of the
future, not real tokio scheduling/concurrency interleavings. This is the single most consequential
finding for SS-17: **proof harnesses for ferrochain's async graph-execution / checkpoint paths must
be authored against synchronous cores or manually-driven futures.** cargo-fuzz and cargo-mutants,
by contrast, handle async/tokio via standard `block_on` wrapping patterns.

**SS-17 action:** Add an explicit note that Kani harnesses target sync cores / manually-polled
futures; design checkpoint & clock logic (ADR-002, ADR-005) with sync, harness-friendly cores so
they are Kani-verifiable independent of the tokio runtime. Exact Kani→rustc nightly pin should be
read from the installed `kani`'s `rust-toolchain` at CI-setup time (Perplexity could not pin the
exact nightly; low-confidence on that sub-fact — verify at toolchain install).

## 4. Provider API surfaces (DTU assessment) — VALID (1 breaking-change flag)

| Provider | Spec / version | Status (2026-07-13) |
|----------|----------------|---------------------|
| **OpenAI** | Official OpenAPI spec at `github.com/openai/openai-openapi` (also Stainless-hosted YAML) | Published & current. **Breaking changes in flight:** migration to **Responses API**; **Realtime API beta removed**; Assistants API sunset; some DALL·E/GPT snapshot removals. DTU should track Chat Completions vs Responses surface. |
| **Anthropic Messages** | Required header **`anthropic-version: 2023-06-01`** (still the current documented version) | Stable. **No official OpenAPI spec** — only a community/unofficial spec. No breaking changes in last 6 mo. |
| **Ollama** | Docs moved to **`docs.ollama.com/api`** (was `docs/api.md` in `github.com/ollama/ollama`) | Explicitly **unversioned**, described as stable/backwards-compatible; deprecations rare & release-noted. No breaking changes in last 6 mo. |

**Breaking-change flag:** Only **OpenAI** has shipped breaking deprecations in the window
(Jan–Jul 2026) — principally the push to the Responses API and removal of the Realtime API beta.
ferrochain's OpenAI provider should target Chat Completions (stable) and note Responses API as a
forward-looking surface. Anthropic & Ollama: stable, no action. Absence of official OpenAPI specs
for Anthropic/Ollama means the DTU cannot fully machine-verify those surfaces — hand-maintained
client types remain necessary (unchanged from prior assessment).

## 5. Competitive watch (R4 / success-criterion #2) — BLOCKER-FLAG

| Framework | Version (crates.io, 2026-07-13) | Durable graph checkpointing? |
|-----------|-------------------------------|------------------------------|
| **`langgraph` crate** | **0.2.5** (2026-07-01) | **YES, claimed.** Ships `InMemorySaver`, **`PostgresSaver`** (sqlx + migrations), **`SqliteSaver`**; advertises "pause/resume, human-in-the-loop, time-travel debugging." Pre-1.0, ~50% doc coverage, 16 examples. Self-describes as "Full suite." |
| `rig-core` | 0.40.0 (2026-07-11) | Partial/intent only — serializable `AgentRun` state machine targeting persist-and-resume, but **no unified GA durable checkpointer**. |
| swiftide | (not version-pinned here) | No documented durable graph/agent-loop checkpointing. |
| kalosm | (not version-pinned here) | No durable agent-state checkpoint facility (uses Floneum for workflow graphs). |

**Assessment:** No Rust framework has an unambiguously **GA (1.0, fully-documented, widely-adopted)**
durable checkpointer equivalent to Python LangGraph — ferrochain's differentiation thesis (SC-2)
**still holds at the GA/maturity bar.** HOWEVER, the `langgraph` crate at 0.2.5 is a direct,
fast-moving competitor now claiming exactly ferrochain's headline feature (SQLite+Postgres durable
checkpointing with time-travel). This is a **material change since prior market-intel** and should
be escalated: (a) the "no Rust competitor" framing in R4 is now too strong — reframe to "no *GA/
mature* competitor"; (b) monitor the `langgraph` crate's release cadence (0.1.0→0.2.5 shows active
development); (c) ferrochain's edge must be articulated as maturity/verification/durability-tier
rigor (ADR-003, SS-17 proofs), not merely "first to have checkpointing in Rust."

## 6. D21 ADR Technology Validation (ADR-014 through ADR-017) — VALID

**Verification date:** 2026-07-20 (crates.io registry API, live).

| Crate / approach | Decision | Finding | Verdict |
|------------------|----------|---------|---------|
| `inventory = "0.3"` | ADR-016 registry mechanism | Current: 0.3.24 (dtolnay, Q1-2026 active, MSRV 1.62, edition-agnostic, WASM-safe). Linker-section constructor model is sound. | GREEN — pin as `"0.3"` |
| `minijinja = "2"` | ADR-015 jinja2 template engine | Current: 2.21.0. Autoescape, sandboxed mode, strict-undefined all present in 2.x API. Active maintenance (2024-present). MIT licensed. | GREEN — pin as `"2"` (default-features=false) |
| `mustache` crate | ADR-015 mustache engine | Last release: 2018-02-21 (0.9.0). No commit activity since 2018. Predates Rust 2018 edition. Cannot be a v1 dependency. | REJECTED — abandoned |
| Embeddings: no separate crate | ADR-017 | No embedding-specific Rust crate needed. OpenAI `/v1/embeddings` and Ollama `/api/embed` are direct HTTP calls via `reqwest`. `Vec<f32>` output is sufficient. | GREEN — HTTP direct, no new dep |
| Vector math: `Vec<f32>` only | ADR-014 | `ndarray` explicitly rejected (heavy transitive dep for ferrochain-core). `Vec<f32>` cosine + zero-norm guard is correct and dep-free for the in-memory backend. | GREEN — no ndarray |
| `ramhorns = "1"` | ADR-015 mustache fallback | Evaluated as fallback only. Current: 1.0.0 (experimental, sparse maintenance). Not needed — minijinja covers the mustache-syntax use case as a superset. | NOT NEEDED — not used |

### Notes

- **inventory pin maintenance:** `inventory` and similar constructor-section crates (`linkme`) track
  Rust compiler internals. Keep the pin at `"0.3"` (caret) and re-verify when upgrading the pinned
  Rust toolchain channel in `rust-toolchain.toml`.
- **minijinja sandboxed mode:** ADR-015 Decision 4 specifies that ferrochain-prompts enables sandboxed
  mode for all jinja2 rendering. This is backed by minijinja 2.x's `Environment::set_sandboxed(true)`
  API (verified present in 2.21.0 docs).
- **Ollama endpoint split:** `/api/embed` (newer, `input` field) vs `/api/embeddings` (legacy, `prompt`
  field) confirmed against `docs.ollama.com/api` (2026-07-20). ADR-017 `EmbeddingsOllama` defaults
  to `/api/embed` with `use_legacy_endpoint` toggle — aligns with current Ollama documentation.
- **OpenAI model currency:** `text-embedding-3-small` and `text-embedding-3-large` confirmed as
  current recommended models; `text-embedding-ada-002` confirmed legacy/superseded. OpenAI `/v1/embeddings`
  endpoint stable (no breaking changes in 2026 window for embeddings).

## 7. D23 ADR-020 Dependency Validation (ADR-020 Decision 7) — VALID with attribution fix

**Verification date:** 2026-07-21 (crates.io registry API, live).

| Crate / approach | Decision | Finding | Verdict |
|------------------|----------|---------|---------|
| `similar = "3"` | ADR-020 Decision 7 (EditFileTool fuzzy fallback) | Current: 3.1.1 (mitsuhiko, 2025). ATTRIBUTION FIX: owner is mitsuhiko (Armin Ronacher, also author of `minijinja`/`insta`), NOT dtolnay as ADR v1.0 stated. Apache-2.0 SINGLE-licensed (not dual). MSRV 1.85. `TextDiff::ratio()` confirmed as the correct difflib-parity mechanism for multi-line edit-block fuzzy matching. | GREEN — pin as `"3"` (caret on 3.x) |
| `regex = "1"` | ADR-020 Decision 7 (GrepTool in-process matching) | Current: 1.13.1. MIT OR Apache-2.0 dual-licensed. MSRV 1.65. Linear-time finite-automata engine — no catastrophic backtracking on adversarial inputs. NOT currently a workspace dep (workspace uninitialized as of 2026-07-22). | GREEN — pin as `"1"` (caret on 1.x) |
| `fuzzy-matcher` crate | ADR-020 Decision 7 alternative | Last release 2020; no maintenance activity; wrong shape for edit-block fuzzy matching. | REJECTED — stale, wrong API shape |
| `strsim` crate | ADR-020 possible identifier-level typo tolerance | Current stable (maintained). Only appropriate for identifier-level typo tolerance (e.g., flag name suggestions), not for edit-block multi-line fuzzy replacement. | NOT ADOPTED — deferred; only if identifier-level fuzzy tolerance needed in future cycle |

### Notes

- **`similar` cargo-deny obligation:** Apache-2.0 single-licensed. `cargo-deny` `[licenses.allow]` list must include `"Apache-2.0"` explicitly at workspace initialization. `inventory` (0.3.24, ADR-016) is also Apache-2.0 only (confirmed in §6) — this obligation already existed. One `[licenses.allow]` entry covers both.
- **MSRV floor impact:** `similar = "3"` (MSRV 1.85) is now the highest MSRV across all workspace deps validated to date. The pinned stable channel in `rust-toolchain.toml` must be ≥ 1.85. This supersedes the `inventory` 1.62 and `regex` 1.65 floors. Devops-engineer must verify at workspace init.
- **Both deps are net-new:** Neither `similar` nor `regex` exist in the workspace today (root `Cargo.toml` not yet initialized). Both will be added as `[workspace.dependencies]` entries during devops-engineer workspace init. `ferrochain-tools` `Cargo.toml` will reference both via `similar.workspace = true` and `regex.workspace = true`.
- **`similar` default-features:** `similar` 3.x exposes `inline`, `unicode`, and `bytes` features. For `EditFileTool`, only text-diff is needed; pin with `default-features = true` (includes `unicode` support, needed for multi-byte edits) or `features = ["text"]` if size-sensitive. Research-agent recommendation: keep defaults unless binary size audit demands trimming.

---

## Sources

- crates.io registry API (live, 2026-07-13): schemars, rmp-serde, kani-verifier, cargo-fuzz,
  cargo-mutants, langgraph, rig-core, bincode, postcard — version + release-date fields.
- crates.io registry API (live, 2026-07-20): inventory (0.3.24), minijinja (2.21.0),
  mustache (0.9.0/2018-02-21, abandoned), ramhorns — D21 ADR pin verification.
- crates.io registry API (live, 2026-07-21): similar (3.1.1, mitsuhiko, Apache-2.0 single,
  MSRV 1.85), regex (1.13.1, rust-lang, MIT OR Apache-2.0, MSRV 1.65), fuzzy-matcher
  (stale 2020), strsim (not adopted) — D23 ADR-020 Decision 7 pin verification.
- docs.rs: schemars 1.2.1 `SchemaSettings` (JSON Schema 2020-12 default); langgraph 0.2.5 crate docs
  (checkpointer backends).
- Perplexity `sonar-deep-research` (web-grounded, 2026-07-13): schemars ecosystem & API-stability
  discussion; Rust binary-serialization survey; Rust verification toolchain + Kani async status;
  OpenAI/Anthropic/Ollama spec & breaking-change survey; Rust agent-framework checkpointing survey.
- `github.com/openai/openai-openapi` (official OpenAI spec); Anthropic API versioning docs
  (`anthropic-version: 2023-06-01`); `docs.ollama.com/api`.

**Confidence notes / inconclusive flags:**
- Exact adk-rust schemars pin: unverified (Perplexity snippet gap). Series-currency (1.x) is verified.
- Exact Kani→rustc nightly pin: unverified — read from installed toolchain at CI setup.
- bincode 3.0.0 "deprecation stub / maintained-fork" claim: **unverified, conflicts with crates.io**;
  excluded from conclusions.
- swiftide/kalosm exact versions not pinned (checkpointing-absence finding is qualitative).

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| **Perplexity perplexity_research (PRIMARY)** | 5 | schemars state; Rust binary-serialization alternatives; Rust verification toolchain + Kani async; provider API specs & breaking changes; Rust agent-framework checkpointing survey (all reasoning_effort medium/high) |
| Perplexity perplexity_reason | 0 | — |
| Perplexity perplexity_search | 0 | — |
| Perplexity perplexity_ask | 0 | — |
| Context7 | 0 | — (registry + docs.rs fetches sufficed for version/API verification) |
| Tavily tavily_extract | 1 | crates.io API batch fetch (partial; superseded by WebFetch) |
| WebFetch | 9 | Direct crates.io API version verification (schemars, rmp-serde, kani-verifier, cargo-mutants, cargo-fuzz, bincode, postcard, langgraph, rig-core) + docs.rs langgraph checkpointing confirmation |
| WebSearch | 0 | — |
| Training data | 0 areas | Explicitly avoided for version numbers per mandate; all versions registry-verified 2026-07-13 |

**Total MCP tool calls:** 6 (5 perplexity_research + 1 tavily_extract), plus 9 WebFetch registry verifications.
**Training data reliance:** low — every version number and release date was verified against the live
crates.io API on 2026-07-13; qualitative findings cross-checked against web-grounded Perplexity deep research.
