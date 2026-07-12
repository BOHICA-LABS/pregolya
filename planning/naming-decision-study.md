# Naming Decision Study — Rust Port of the LangChain Ecosystem

**Date:** 2026-07-12
**Author:** Research agent (Corverax / VSDD factory)
**Decision owner:** Human maintainer (approval required)
**Status:** Ready for decision

---

## 0. TL;DR

- **Option 1 (keep `langchain-rs`, publish `langchain-*-rs` crates)** fails on two of the most identity-defining names: `langchain-rs` itself is **already taken** (crates.io treats `langchain-rs` and the existing `langchain_rs` v0.0.2 as the *same* name), and `langgraph-checkpoint-rs` is **already taken** at v0.2.5 by an active competitor (`Onelevenvy`) who *also* owns the `langgraph` crate. So the flagship crate name and one partner crate are unavailable on day one.
- The `-rs` space is also **crowded and confusing**: it collides with the mature incumbent `langchain-rust` (Abraxas-365, v4.6.0), with `langchain-ai-rust` (v5.0.1, ownership opaque, **not** confirmed affiliated with LangChain Inc.), and with `Onelevenvy/langgraph` (a "full suite" Rust LangGraph port). We would be the 3rd–4th "langchain in Rust" project.
- **Option 2 (distinct brand)** is legally cleaner, gives us a **complete namespace**, and is future-proof if LangChain Inc. ships an official Rust SDK. The discoverability cost is real but **bounded to `"langchain rust"`-style queries** and is demonstrably mitigable — `rig`, `swiftide`, and `kalosm` all succeed as distinct brands.
- **Recommendation: Option 2, distinct brand — `ferrochain`** (crate `ferrochain`, `ferrochain-core`, and GitHub org `github.com/ferrochain` are all verified available), positioned in all metadata as *"a Rust implementation of the LangChain v1 architecture."* Score: **Option 2 = 23/25 vs Option 1 = 14/25.**

> Availability was verified live against the crates.io API (`https://crates.io/api/v1/crates/<name>`; HTTP 404 = available) and GitHub org pages on 2026-07-12. Every claim is cited.

---

## 1. Option 1 — Keep `langchain-rs`, publish `-rs`-suffixed crates

### 1.1 crates.io availability table (verified 2026-07-12)

| # | Proposed crate | crates.io status | Notes |
|---|----------------|------------------|-------|
| 1 | `langchain-core-rs` | ✅ **AVAILABLE** (404) | |
| 2 | `langgraph-rs` | ✅ **AVAILABLE** (404) | |
| 3 | `langgraph-checkpoint-rs` | ❌ **TAKEN** — v0.2.5 | Owned by `Onelevenvy`; *"Core checkpointing traits and interfaces for LangGraph applications in Rust."* Same owner as the `langgraph` crate. |
| 4 | `langchain-rs` | ❌ **TAKEN** — collides with `langchain_rs` v0.0.2 | crates.io **normalizes `-` and `_` to the same name**, so `langchain-rs` == `langchain_rs`. Existing crate: *"Rust version of Langchain."* The flagship name is blocked. |
| 5 | `langchain-openai-rs` | ✅ **AVAILABLE** (404) | |
| 6 | `langchain-anthropic-rs` | ✅ **AVAILABLE** (404) | |
| 7 | `langchain-ollama-rs` | ✅ **AVAILABLE** (404) | |
| 8 | `langchain-community-rs` | ✅ **AVAILABLE** (404) | |
| 9 | `langchain-text-splitters-rs` | ✅ **AVAILABLE** (404) | |
| 10 | `langgraph-prebuilt-rs` | ✅ **AVAILABLE** (404) | |

**Result: 8/10 available, but the 2 blocked names are the worst two to lose** — the flagship umbrella crate (`langchain-rs`) and a core LangGraph partner crate (`langgraph-checkpoint-rs`).

> The `-`/`_` equivalence is documented crates.io behavior: names differing only in hyphens vs underscores (and case) are treated as the same crate and cannot both be published. This is why `langchain-rs` cannot be claimed while `langchain_rs` exists. ([crates.io usage policy / naming](https://crates.io/policies))

### 1.2 The existing competing crates

**`langgraph` (v0.2.5) — a serious parallel effort we would compete with.**
- Owner: **`Onelevenvy`** (single owner). ([crates.io API — langgraph](https://crates.io/api/v1/crates/langgraph), [owners](https://crates.io/api/v1/crates/langgraph/owners))
- Repo: **https://github.com/Onelevenvy/langgraph-rust**
- Description: *"A Rust implementation of LangGraph for building stateful, multi-actor applications with LLMs (Full suite)."*
- License: **MIT**. Created **2026-06-06**, updated **2026-07-01**, ~**599 downloads**.
- Assessment: **A genuine, actively-developed, "full suite" parallel port** — not a squat. Early (v0.2.x, pre-1.0, low downloads) but current. The same owner holds `langgraph-checkpoint-rs`, so they are building an integrated LangGraph namespace in Rust. This is the project we would most directly **compete with for the LangGraph identity in Rust**. ([Onelevenvy/langgraph-rust](https://github.com/Onelevenvy/langgraph-rust))

**`langgraph-checkpoint` (v0.1.0, 2026-06-06) — a separate community port.**
- Owner: **`CYXCAT`** (per lib.rs). ([lib.rs — langgraph-checkpoint](https://lib.rs/crates/langgraph-checkpoint))
- Description: *"Checkpoint saver trait and in-memory implementation for durable graph execution."* Part of a Chinese-language community "Rust 版 LangGraph 社区移植" (community port). Carries an **explicit disclaimer that it is independent from official LangChain / LangGraph** and that the v0.1.x API is an early preview.
- Assessment: **A separate, early-stage community effort** (different owner than `Onelevenvy`). Note there are now **two** checkpoint crates in this space (`langgraph-checkpoint` by CYXCAT and `langgraph-checkpoint-rs` by Onelevenvy) — the namespace is already fragmenting.

**`langchain-rust` (v4.6.0) — the mature incumbent.**
- Owner: **`Abraxas-365`**. Repo: **https://github.com/Abraxas-365/langchain-rust**. License: **MIT**.
- Description: *"LangChain for Rust, the easiest way to write LLM-based programs in Rust."* Full feature set (LLMs, embeddings, vector stores, chains, agents, tools, semantic routing; SQLite/Postgres/SurrealDB/Qdrant integrations). At v4.6.0 it is **the most mature and most discoverable Rust LangChain port**. ([crates.io — langchain-rust](https://crates.io/crates/langchain-rust), [repo](https://github.com/Abraxas-365/langchain-rust)) This is the project that already owns the `"langchain rust"` search intent.

**`langchain-ai-rust` (v5.0.1) — ownership opaque; NOT confirmed affiliated with LangChain Inc.**
- crates.io description: *"Build LLM applications in Rust with type safety: chains, agents, RAG, LangGraph, embeddings, vector stores, and 20+ …"*
- **Affiliation: could NOT be confirmed.** No visible statement that it is a first-party LangChain Inc. product, no linked corporate repo, no "official Rust SDK" language in the sources examined. The name mirrors LangChain's **GitHub org name (`langchain-ai`)**, which makes it *look* official without evidence that it is. There is **no evidence it is a fork of `langchain-rust`** — no cross-references between the two projects. Treat it as an **independent community project of unknown provenance** until LangChain Inc. documentation says otherwise. This is itself a cautionary data point: a third party has already annexed the `langchain-ai` identity in Rust.

> Inconclusive flag: `langchain-ai-rust` ownership/affiliation is **unresolved**. The high version number (5.0.1) and broad feature claims suggest a serious effort, but governance is opaque.

### 1.3 LangChain Inc. trademark / brand posture

- **Registered mark:** LangChain Inc. filed a **USPTO word-mark application for "LANGCHAIN"** (serial **98033029**, filed **2023-06-08**, for *"Downloadable software for creating, developing…"*). The last visible status was an early **"New Application"** stage; **completion of registration could not be confirmed** from public snapshots. Treat "LangChain" as at least an **applied-for + common-law mark**. ([Justia — LANGCHAIN 98033029](https://trademarks.justia.com/980/33/langchain-98033029.html), [USPTO Trademark Center](https://trademarkcenter.uspto.gov/))
- **LangGraph / LangSmith:** **No** visible USPTO registrations found; likely rely on common-law rights. (Inconclusive — not proof of absence.)
- **No public community brand/trademark-usage policy.** LangChain's only visible governing document is its [Terms of Service](https://www.langchain.com/terms-of-service), which addresses customer marks, not third-party ports. There are **no published brand guidelines** for community projects.
- **Treatment of community ports (precedent):**
  - **`langchain4j` (Java)** — independent community project under its own `langchain4j` GitHub org; **not** officially blessed/donated/endorsed; uses the `4j` suffix convention. **No enforcement.** ([langchain4j](https://github.com/langchain4j/langchain4j))
  - **`langchaingo` (Go)** — `github.com/tmc/langchaingo` (~9,200★), maintainer `tmc`; often *called* "official" by third-party articles but structurally a **community port under an individual's namespace**, moving toward community governance; **not** LangChain-org-owned. **No enforcement.** ([tmc/langchaingo](https://github.com/tmc/langchaingo))
  - **`langchain-rust` (Rust)** — independent (Abraxas-365). **No enforcement.**
  - **`LangChain.js`** — the **only** first-party port; published under the `langchain` npm name and the LangChain-controlled `@langchain` npm org. ([npm langchain](https://www.npmjs.com/package/langchain))
- **Enforcement history:** **No documented trademark enforcement actions** against any community "langchain-*" port were found. The de-facto norm is **nominative fair use** (a suffix like `4j`/`go`/`-rs`/`.js` signals "a port for X," not the official product), tolerated but **not formally licensed**. LangChain Inc. keeps tight control of its *official* namespaces (`langchain` on npm, `@langchain` org) while leaving community ports alone.

> Net trademark read for Option 1: **Low-probability but non-zero risk today**, rising if the port becomes prominent *or* if LangChain Inc. ships an official Rust SDK. We would be relying on continued tolerance of an applied-for mark, with no license and no policy to point to.

### 1.4 crates.io policy on squatting / name transfer

- **First-come, first-served.** crates.io does **not** reserve names for trademark holders; the first publisher owns the name. ([crates.io policies](https://crates.io/policies))
- Disputes and unmaintained-name reclamation are handled **case-by-case via a GitHub issue** to the crates.io team, informed by community RFC discussion — there is **no automatic trademark-transfer mechanism**. ([Pre-RFC: giving crates to new maintainers](https://users.rust-lang.org/t/pre-rfc-we-need-a-process-for-giving-crates-to-new-maintainers/8033), [Name squatting on crates.io](https://users.rust-lang.org/t/name-squatting-on-the-crates-io/42415))
- **Implication:** We **cannot force** `langchain_rs` (v0.0.2) or `langgraph-checkpoint-rs` (Onelevenvy, active) to be transferred to us. The v0.0.2 stub *might* be reclaimable via an issue given near-zero usage, but that is discretionary, slow, and not guaranteed; the Onelevenvy crate is **actively maintained and non-reclaimable**.

---

## 2. Option 2 — New distinct brand

Positioned as *"a Rust implementation of the LangChain v1 architecture (chains, graphs, agents)."*

### 2.1 Candidate evaluation (verified 2026-07-12)

| Candidate | crate `<name>` | crate `<name>-core` | GitHub org `github.com/<name>` | Collision risk | Verdict |
|-----------|----------------|---------------------|-------------------------------|----------------|---------|
| **ferrochain** | ✅ AVAILABLE | ✅ AVAILABLE | ✅ AVAILABLE | **None found** ("ferro" = iron, plays on Rust; no software collision) | ⭐ **BEST — fully clean** |
| **cogflow** | ✅ AVAILABLE | ✅ AVAILABLE | ✅ AVAILABLE | Possible minor: "CogFlow" MLOps/Kubeflow-adjacent tooling exists in the ML space | Strong alternate |
| **graphweave** | ✅ AVAILABLE | ✅ AVAILABLE | ⚠️ org handle **registered but empty** (no repos/members) | Handle taken on GitHub (unused); good semantic fit (graphs) | Viable, GitHub caveat |
| agentflow | ✅ AVAILABLE | ❌ TAKEN (`agentflow-core` v0.1.2) | ❌ TAKEN (org "pascal") | Namespace incomplete | Reject |
| rustchain | ❌ TAKEN (v0.1.0, workflow transpiler) | — | — | Blockchain-search confusion + taken | Reject |
| linkforge | ❌ TAKEN (v0.1.0 *"Reserved for the official LinkForge Rust port"*) | — | — | Taken | Reject |
| chainforge | — | — | — | **Direct LLM-domain collision** — [ChainForge](https://www.chainforge.ai/) is an established LLM prompt-engineering GUI | Reject (confusion) |
| weaver | — | — | — | Heavy collision (OpenTelemetry Weaver, others) | Reject |
| synapse | — | — | — | Heavy collision (Matrix Synapse, Azure Synapse) | Reject |
| relay | — | — | — | Heavy collision (Facebook Relay GraphQL) | Reject |
| lattice / cascade | — | — | — | Common names, multiple collisions | Reject |

> Candidates marked "—" for sub-columns were eliminated at the first collision check and not fully namespace-verified, since a known major-project collision already disqualifies them.

**Winner: `ferrochain`.** It is the only candidate with a **verified-clean full namespace** (base crate + `-core` + GitHub org) *and* strong Rust semantics (ferrous = iron/rust) *and* no discoverable software collision (a web search for "ferrochain … LLM Rust" surfaced **no** project by that name). Recommended companion crates all inherit the clean prefix: `ferrochain-core`, `ferrochain-openai`, `ferrochain-anthropic`, `ferrochain-ollama`, `ferrochain-community`, plus a graph layer (e.g. `ferrograph` or `ferrochain-graph`) and checkpoint crate. (Verify the exact partner-crate names before publishing.)

Alternates in priority order: **`cogflow`** (note the ML "CogFlow" prior art) then **`graphweave`** (note the empty-but-registered GitHub org handle).

### 2.2 Discoverability cost — and why it is manageable

**How Rust developers actually find LLM frameworks:**
1. **crates.io keyword/category browsing** — `llm`, `nlp`, `ai`, `agent`, `rag` keyword pages. ([crates.io keyword: llm](https://crates.io/keywords/llm))
2. **GitHub topic search** — `llm`, `generative-ai`, `agent`, `rust`, `llmops`, `rag`.
3. **Curated lists** — [`jondot/awesome-rust-llm`](https://github.com/jondot/awesome-rust-llm), [`rust-unofficial/awesome-rust`](https://github.com/rust-unofficial/awesome-rust).
4. **Functional web queries** — *"Rust LLM framework," "Rust AI agent," "Rust RAG pipeline"* (not brand-first).
5. **Social** — r/rust launch threads, blogs, newsletters.

**Distinct brands succeed despite not carrying "langchain":**
- **`rig` (`rig-core`, [0xPlaygrounds/rig](https://github.com/0xPlaygrounds/rig), site [rig.rs](https://rig.rs))** — *"Build modular and scalable LLM Applications in Rust; one unified API across 20+ providers."* Heavy GitHub topics + companion crates + examples repo.
- **`swiftide` ([bosun-ai/swiftide](https://github.com/bosun-ai/swiftide), site [swiftide.rs](https://swiftide.rs))** — *"Fast & streaming LLM applications in Rust"* (RAG-focused).
- **`kalosm` ([Floneum](https://floneum.com/), docs on docs.rs)** — *"a simple, local-first interface for pre-trained language, audio, and image models,"* built on Candle; the `kalosm-sample` crate shows tens of thousands of downloads under the `nlp` keyword.

**Conclusion:** The **only** discoverability the distinct brand forfeits is the narrow set of brand-literal queries (*"langchain rust"*), which the incumbent `langchain-rust` already dominates anyway. For the far larger pool of **functional** queries and **keyword/list** discovery, a distinct brand competes on equal footing — provided we (a) put a descriptive tagline everywhere (*"a Rust implementation of the LangChain v1 architecture — chains, graphs, agents"*), (b) tag `llm`/`agent`/`rag`/`nlp`/`ai` keywords on crates.io, (c) set GitHub topics, (d) get listed on `awesome-rust-llm`, and (e) ship an examples repo + docs site. This is a **solved problem** in the Rust LLM ecosystem.

---

## 3. Scored comparison

Scoring: **1 = worst, 5 = best** on each criterion (higher is better).

| Criterion | Option 1 — `langchain-*-rs` | Option 2 — distinct brand (`ferrochain`) |
|-----------|:---------------------------:|:----------------------------------------:|
| **Legal / trademark risk** (5 = lowest risk) | **3** — relies on tolerated nominative use of an applied-for mark; no license, no policy; risk rises with prominence | **5** — no use of the LANGCHAIN mark; "implements the LangChain v1 architecture" is descriptive/nominative and safe |
| **Namespace completeness** (5 = can get every name) | **2** — flagship `langchain-rs` **and** `langgraph-checkpoint-rs` blocked; cannot be forced via crates.io | **5** — `ferrochain` + `-core` + GitHub org all verified free; whole namespace ours |
| **Discoverability / adoption** (5 = best) | **5** — direct capture of "langchain rust" intent | **3** — loses brand-literal queries only; recoverable via keywords/lists/tagline (proven by rig/swiftide/kalosm) |
| **Identity / differentiation** (5 = strongest) | **2** — 3rd–4th "langchain in Rust"; collides with `langchain-rust`, `langchain-ai-rust`, and `Onelevenvy/langgraph` | **5** — own brand, zero collision with the incumbents |
| **Long-term flexibility** (5 = most future-proof) | **2** — tied to LangChain Inc.'s roadmap; an official Rust SDK (likely `langchain`/`@langchain`) would subordinate/obsolete us | **5** — independent; if an official SDK ships we coexist and differentiate rather than being displaced |
| **TOTAL (/25)** | **14** | **23** |

### What happens if LangChain Inc. ships an official Rust SDK?
- **Option 1:** They would almost certainly publish under their controlled identity (`langchain` npm-style ownership; likely a `langchain`/`@langchain`-aligned crate name and a first-party repo). Our `langchain-*-rs` crates would look like the *unofficial also-ran* next to the blessed SDK, and any latent trademark tolerance could tighten. **High strategic downside.**
- **Option 2:** A distinct brand is unaffected. We compete/coexist like `rig`/`swiftide` do, and can even advertise *"LangChain-v1-architecture-compatible"* interop. **Low strategic downside.**

---

## 4. Recommendation

**Adopt Option 2 — a distinct brand — using `ferrochain`** (verified-clean crate, `-core`, and GitHub org), positioned everywhere as *"a Rust implementation of the LangChain v1 architecture (chains, graphs, agents)."*

Rationale: Option 1's two blocked names are precisely the flagship (`langchain-rs`) and a core partner (`langgraph-checkpoint-rs`, held by an active competitor), so Option 1 **cannot deliver a coherent namespace** even before weighing trademark and differentiation. Option 2 wins decisively (23 vs 14), trading only a **bounded, mitigable** discoverability cost for a clean namespace, low legal risk, strong identity, and future-proofing against an official SDK.

**Discoverability mitigations (ship these regardless):**
1. Tagline in every crate description, README, and site: *"A Rust implementation of the LangChain v1 architecture — chains, graphs, agents."*
2. crates.io keywords: `llm`, `agent`, `rag`, `nlp`, `ai`; GitHub topics to match.
3. Submit to `jondot/awesome-rust-llm` and `rust-unofficial/awesome-rust` at launch.
4. Ship an examples repo + a docs site (`ferrochain.rs` if available) mirroring rig/swiftide's playbook.
5. Add a docs page *"Coming from LangChain / LangGraph?"* to capture comparison queries **without** using the mark in the crate name.
6. Do **not** claim `langchain-*-rs` pointer crates for SEO — that reintroduces the trademark risk we are avoiding.

---

## 5. Decision table (for approval)

| Decision | Recommended choice | Alternatives if rejected |
|----------|--------------------|--------------------------|
| **Naming strategy** | ☐ Option 2 — distinct brand | ☐ Option 1 — `langchain-*-rs` (accept: blocked flagship + competitor-owned partner crate) |
| **Brand name** | ☐ `ferrochain` | ☐ `cogflow` (ML "CogFlow" prior art) · ☐ `graphweave` (GitHub org handle registered-but-empty) |
| **Umbrella crate** | ☐ `ferrochain` | — |
| **Core crate** | ☐ `ferrochain-core` | — |
| **Graph layer** | ☐ `ferrograph` *(verify availability before publishing)* | ☐ `ferrochain-graph` |
| **Partner crates** | ☐ `ferrochain-openai` / `-anthropic` / `-ollama` / `-community` *(verify each)* | — |
| **GitHub org** | ☐ `github.com/ferrochain` | — |
| **Positioning line** | ☐ "A Rust implementation of the LangChain v1 architecture" | — |
| **Repo name** | ☐ Rename `langchain-rs` → `ferrochain` | ☐ Keep repo, publish under `ferrochain` |

> Action items on approval: (1) claim `ferrochain` + `ferrochain-core` on crates.io and the `ferrochain` GitHub org immediately (first-come-first-served); (2) verify the remaining `ferrochain-*` partner-crate and `ferrograph` names before finalizing; (3) reconfirm no new collisions the day of registration.

---

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| **Perplexity `perplexity_research` (PRIMARY)** | 3 | Deep multi-source synthesis: (a) competing crates `langgraph`/`langgraph-checkpoint`/`langchain-rust`/`langchain-ai-rust`; (b) LangChain Inc. trademark posture, community-port precedent, crates.io squatting policy; (c) distinct-brand discoverability (rig/swiftide/kalosm) + candidate-name collision analysis |
| Perplexity `perplexity_reason` | 0 | — |
| Perplexity `perplexity_search` | 0 | — |
| Perplexity `perplexity_ask` | 0 | — |
| Context7 | 0 | — |
| Tavily (all variants) | 0 | — |
| WebFetch | 24 | Live crates.io API availability checks (10 Option-1 names, 4 alt base names, 4 alt `-core` names) + `langgraph` crate metadata/owners + 4 GitHub org checks |
| WebSearch | 2 | Verify "ferrochain" has no software collision; confirm `langchaingo` (Go) affiliation status |
| Training data | 1 area | General crates.io `-`/`_` normalization behavior and ecosystem context (corroborated against crates.io policy pages) — flagged inline |

**Total MCP tool calls:** 3 (all `perplexity_research`, `reasoning_effort: high`) + 26 direct web verifications (WebFetch/WebSearch).
**Training data reliance:** **low** — every availability claim was verified live against the crates.io API / GitHub on 2026-07-12; ownership, trademark, and discoverability claims are sourced to Perplexity-cited URLs and direct fetches.

### Inconclusive / caveats
- **`langchain-ai-rust` affiliation:** unresolved — no evidence it is a LangChain Inc. product, and no evidence it is a fork of `langchain-rust`. Treat as independent, unknown provenance.
- **USPTO "LANGCHAIN" registration status:** application confirmed (serial 98033029, filed 2023-06-08); completion of registration not confirmed from public snapshots.
- **`LANGGRAPH` / `LANGSMITH` marks:** no registrations found (absence of evidence, not evidence of absence).
- **`graphweave` GitHub org** is a registered-but-empty handle; **`ferrograph`** and the `ferrochain-*` partner names were **not** individually verified and must be checked before publishing.
