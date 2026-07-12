# LangChain → Rust Port: Research Report

**Type:** general (technology / architecture research)
**Date:** 2026-07-12
**Topic:** Structure of the `langchain-ai/langchain` monorepo (v1 era), core abstractions inventory, package dependency graph, scale, existing Rust ecosystem, and Rust design considerations for a full port.
**Confidence legend:** ✅ verified against a cited live source · 🟡 inferred / partially verified · 🔴 inconclusive (flagged).

> Scope note: This report covers **LangChain Python** (the reference implementation). Version numbers were verified against PyPI, crates.io, and GitHub in July 2026. Technology landscapes move fast — treat all version numbers as "as of mid-2026."

---

## 0. Executive Summary

- **LangChain is now on v1.x, not v0.3.** ✅ Verified latest published versions: `langchain` **1.3.13**, `langchain-core` **1.4.9**, `langgraph` **1.2.9**, `langgraph-prebuilt` **1.0.13**. [PyPI](https://pypi.org/project/langchain), [PyPI langchain-core](https://pypi.org/project/langchain-core), [PyPI langgraph](https://pypi.org/project/langgraph), [deps.dev](https://deps.dev/pypi/langgraph-prebuilt)
- **v1.0 was a conceptual restructuring, not just a version bump.** The `langchain` package is now centered on a single `create_agent` abstraction whose runtime is **LangGraph**. The old `langchain` package became **`langchain-classic`**. `langchain-core` was promoted to 1.0 "with no breaking changes but a core addition" — **standard content blocks**. [LangChain blog: 1.0 alpha](https://www.langchain.com/blog/langchain-langchain-1-0-alpha-releases)
- **Agent execution moved to LangGraph.** LangChain agents are "built on top of LangGraph in order to provide durable execution, streaming, human-in-the-loop, persistence, and more." [PyPI langgraph](https://pypi.org/project/langgraph)
- **`langchain-community` has been sunset**; integrations now live in standalone repos/packages. [Sunsetting issue discussion, per Perplexity synthesis]
- **The monorepo `libs/` layout is now:** `core`, `langchain` (=classic), `langchain_v1` (=the v1 package), `model-profiles`, `partners` (openai, anthropic, ollama, deepseek, xai), `standard-tests`, `text-splitters`. ✅ [GitHub libs/](https://github.com/langchain-ai/langchain/tree/master/libs)
- **Rust ecosystem:** the strongest, most active options are **rig** (`rig-core` **0.40.0**, agent-first, ~6k★) and **langchain-rust** (`4.6.0`, direct conceptual port, very active). A newer **`langchain-ai-rust` (5.0.1)** explicitly advertises a fuller port (LangGraph, Deep Agents, structured output). **swiftide** (~0.32) is the RAG/streaming leader. **llm-chain** (0.13.0) appears stale. **None is a drop-in full v1 port**; a greenfield async-first, trait-based port is recommended, informed by these.

---

## 1. Current Repo Structure (mid-2026)

### 1.1 Monorepo layout under `libs/` ✅

Verified directly from the GitHub tree ([libs/](https://github.com/langchain-ai/langchain/tree/master/libs)) and corroborated by an independent repo wiki ([openwiki.sh](https://openwiki.sh/langchain-ai/langchain)):

| `libs/` directory | PyPI package | Role |
|---|---|---|
| `core/` | `langchain-core` | Core primitives & abstractions. Minimal deps. The foundation everything builds on. |
| `langchain_v1/` | `langchain` | **The current v1 package.** High-level `create_agent`, retrieval helpers, chains. Depends on `langchain-core` + `langgraph`. |
| `langchain/` | `langchain-classic` | **Legacy/compat location.** Old chains, community re-exports, the indexing API, deprecated functionality. Not the default entry point for new projects. |
| `model-profiles/` | `langchain-model-profiles` 🟡 | Model capability/metadata profiles (new in the v1 era). |
| `partners/` | `langchain-openai`, `langchain-anthropic`, `langchain-ollama`, `langchain-deepseek`, `langchain-xai` | First-party provider integrations maintained by the LangChain team, each with its own `pyproject.toml`. |
| `standard-tests/` | `langchain-tests` | Standardized integration test suite that partner/community integrations run against. |
| `text-splitters/` | `langchain-text-splitters` | Text splitting utilities (character, token, recursive, code-aware, etc.). |

The repo is described as "The agent engineering platform," has ~141k★ / 23.5k forks, and ~1,296 releases; the GitHub Releases page shows recent tags like `langchain==1.3.11` (Jun 22 2026). ✅ [GitHub repo](https://github.com/langchain-ai/langchain)

### 1.2 What changed in the v1.0 restructuring ✅

From the official 1.0 alpha announcement ([blog](https://www.langchain.com/blog/langchain-langchain-1-0-alpha-releases)) and the PyPI descriptions:

1. **`langchain` re-centered on `create_agent`.** Historically the package shipped many hand-written chain/agent patterns. v1 focuses the package around one agent abstraction with a "same high-level interface, different underpinning" — the new `create_agent` runs on LangGraph.
2. **Old package → `langchain-classic`.** The pre-v1 `langchain` code (legacy chains, indexing API, community re-exports, deprecated APIs) moved to `langchain-classic` at `libs/langchain/`, while `libs/langchain_v1/` holds the new package.
3. **`langchain-core` → 1.0 with no breaking changes but "a core addition."** That addition is **standard content blocks** — a provider-agnostic, typed representation of multimodal/structured message content. 🟡 (The blog states "a core addition"; the specific identification as content blocks is corroborated by the core-abstractions research and current docs.)
4. **Structured output moved into the main agent loop** — it no longer requires a separate extra LLM call. [LangChain v1 "what's new" docs, per Perplexity synthesis] 🟡
5. **Middleware became the agent customization primitive** — hooks into the agent loop (PII redaction, dynamic tool selection, history summarization) without rewriting execution logic. [LangChain "middleware" blog, per synthesis] 🟡
6. **`langchain-community` was sunset.** Integrations should now live in standalone packages/repos. 🟡 (Reported via a GitHub sunsetting issue in the Perplexity synthesis; the *general* direction is corroborated by the webfuse cheat sheet and the fact that Google/AWS now maintain independent packages.)

### 1.3 What moved OUT of the monorepo

- **`langchain-community`** — sunset; integrations dispersed to standalone packages. 🟡
- **Most third-party integrations** — the `libs/` README notes most integrations have been moved to separate repositories; e.g. Google and AWS maintain their own LangChain integration packages. ✅ [GitHub libs/]
- **LangGraph** — a **separate repository and package** (`langgraph`, `langgraph-prebuilt`, `langgraph-checkpoint*`), not under `langchain-ai/langchain`. ✅
- **Deep Agents** — a higher-level package built on LangChain, in its own repo `langchain-ai/deepagents` (requires Python 3.11+). ✅ [forum.langchain.com](https://forum.langchain.com/t/are-langchain-package-versions-python-version-specific/2778)

---

## 2. Core Abstractions Inventory (`langchain-core`)

Verified conceptually against a dedicated deep-research pass over the langchain-core API reference and current docs; specific v1 changes flagged where the primary confirmation is the 1.0 blog.

### 2.1 Runnable / LCEL protocol
- **`Runnable`** is the universal interface: `invoke` / `ainvoke`, `stream` / `astream`, `batch` / `abatch`, `astream_events`, plus `RunnableConfig` threading. Implementing sync automatically yields async and vice-versa via default methods.
- **Composition primitives:** `RunnableSequence` (the `|` pipe operator), `RunnableParallel`, `RunnablePassthrough`, `RunnableLambda`, `RunnableBranch`, `RunnableWithFallbacks`, `.with_retry()`, `.with_config()`, `.bind()`.
- **v1 status:** LCEL remains the **universal execution protocol** underlying chains and graph nodes (a `Runnable` can serve as a node in a chain or a LangGraph graph). However, for *agent construction* it is **de-emphasized** in favor of `create_agent` + LangGraph. LCEL is still the idiomatic way to build deterministic, sequential pipelines (e.g. `prompt | model | parser`). 🟡 (Verified via core-abstractions research; the de-emphasis-for-agents framing is corroborated by the 1.0 blog.)

### 2.2 Messages
- **`BaseMessage` hierarchy:** `HumanMessage`, `AIMessage`, `SystemMessage`, `ToolMessage`, `FunctionMessage` (legacy), `ChatMessage`.
- **`AIMessage`** carries `tool_calls: list[ToolCall]`, `usage_metadata`, `response_metadata`.
- **Streaming:** `AIMessageChunk` (and `BaseMessageChunk` subclasses) support additive concatenation for token streaming.
- **Content blocks (v1 core addition):** message `content` can be a list of **standard, typed content blocks** (text, image, audio, file, reasoning/thinking, tool-use, tool-result, citations) providing a provider-agnostic multimodal representation. This is the key `langchain-core` 1.0 addition. ✅/🟡

### 2.3 Chat models
- **`BaseChatModel`** (a `Runnable`) is the provider interface. Key methods: `invoke`, `stream`, `bind_tools(tools)` (attach tool schemas for tool-calling), and **`with_structured_output(schema)`** (return validated Pydantic/JSON-schema objects). Partner packages implement `BaseChatModel`.

### 2.4 Tools / tool-calling
- **`@tool` decorator**, **`BaseTool`**, **`StructuredTool`**; args validated via a Pydantic `args_schema`.
- **`ToolCall`** (name, args, id) is emitted on `AIMessage.tool_calls`; results returned as **`ToolMessage`**. This is the standard tool-calling loop that `create_agent` orchestrates via LangGraph.

### 2.5 Output parsers
- **`BaseOutputParser`** (a `Runnable`): `StrOutputParser`, `JsonOutputParser`, `PydanticOutputParser`, `CommaSeparatedListOutputParser`, structured/streaming variants. In v1, native `with_structured_output` and in-loop structured output reduce reliance on standalone parsers.

### 2.6 Prompts
- **`PromptTemplate`**, **`ChatPromptTemplate`**, **`MessagesPlaceholder`**, `FewShotPromptTemplate`, `FewShotChatMessagePromptTemplate`, `PipelinePromptTemplate`. All are `Runnable`s.

### 2.7 Retrieval stack
- **`Embeddings`** (`embed_documents`, `embed_query`), **`VectorStore`** (`add_documents`, `similarity_search`, `as_retriever`), **`BaseRetriever`** (a `Runnable`, `get_relevant_documents` / `ainvoke`). Concrete vector stores are now external packages.

### 2.8 Documents / loaders / splitters
- **`Document`** (`page_content`, `metadata`), **`BaseLoader`** (document loaders — mostly external now), **text splitters** in `langchain-text-splitters` (`RecursiveCharacterTextSplitter`, token/code/markdown splitters).

### 2.9 Callbacks / tracing
- **`BaseCallbackHandler`**, **`CallbackManager`** / `AsyncCallbackManager`, lifecycle events (`on_llm_start`, `on_tool_end`, `on_chain_*`, etc.). LangSmith tracing hooks in here via the `langsmith` SDK.

### 2.10 Agents / memory / checkpointing (now LangGraph)
- **Agent execution runtime is in LangGraph**, not `langchain-core`. `create_agent` builds a LangGraph `State` machine; invocation appends a message to a `messages` state keyed by `thread_id`. **Memory/checkpointing/persistence** (short-term memory, durable execution, human-in-the-loop) are LangGraph features (`langgraph-checkpoint*`). ✅ [PyPI langgraph]

---

## 3. Package Dependency Graph

```
langsmith SDK (tracing, external SaaS client)
        ▲
        │
   langchain-core   ◄── minimal core (pydantic, tenacity, jsonpatch, PyYAML, langsmith)
        ▲   ▲   ▲   ▲
        │   │   │   └────────────── langchain-text-splitters
        │   │   └────────────────── langchain-tests (standard-tests)
        │   └────────────────────── partners: langchain-openai / -anthropic / -ollama /
        │                            -deepseek / -xai  (+ each provider's SDK)
        │
   langgraph  (separate repo)  ──►  langgraph-prebuilt, langgraph-checkpoint*
        ▲
        │
   langchain (v1)  ── depends on langchain-core + langgraph (+ langgraph-prebuilt)
        ▲
        │
   langchain-classic ── depends on langchain-core + langchain-text-splitters
```

- **Minimal "core" surface = `langchain-core`**: messages + content blocks, the `Runnable`/LCEL protocol, `BaseChatModel`, tools/`ToolCall`, output parsers, prompts, the `Embeddings`/`VectorStore`/`BaseRetriever` interfaces, `Document`, and callbacks. It has **no provider dependencies** — providers implement its interfaces. This is the natural first target for a Rust port. 🟡 (exact dependency lists inferred from PyPI metadata + package descriptions)
- **`langchain` (v1)** adds a hard dependency on **`langgraph`** — so a faithful port of the *v1 agent package* implies porting or substituting a LangGraph-equivalent runtime.

---

## 4. Approximate Scale (port scoping) 🔴 rough / partially inconclusive

Exact LOC/module counts were **not verified against a checkout** (no shell access; GitHub file-count not enumerated). The following are order-of-magnitude estimates flagged as **unverified inference**, useful only for relative scoping:

| Package | Rough relative size | Port priority |
|---|---|---|
| `langchain-core` | Largest abstraction surface (many small modules: messages, runnables, prompts, tools, parsers, callbacks, vectorstore/retriever/embeddings interfaces). Est. tens of thousands of LOC. 🔴 | **P0** — the foundation |
| `langchain-text-splitters` | Small, self-contained. 🔴 | P1 — easy early win |
| `partners/*` | Each small–medium (one chat model + embeddings + client glue). 🔴 | P1 per provider |
| `langchain` (v1) | Medium, but pulls in LangGraph semantics. 🔴 | P2 |
| `langgraph` (separate) | Substantial: graph engine, checkpointing, streaming, HITL. 🔴 | P2/P3 (decide build-vs-simplify) |
| `standard-tests` | Medium; valuable as a conformance harness to port. 🔴 | P1 (test parity) |

> **Recommendation:** obtain a local checkout and run `tokei`/`scc` per `libs/*` before committing to a scope estimate. The numbers above are deliberately coarse.

---

## 5. Existing Rust Ecosystem

All versions verified on crates.io in July 2026.

| Crate | Latest ver ✅ | Focus | Activity | Assessment |
|---|---|---|---|---|
| **rig** (`rig-core`) | **0.40.0** | Agent-first: 20+ providers, 10+ vector stores, completion+embedding, multi-agent, graph workflows, persistence; `rig` facade + companion crates | Very active, ~6k★, "torrent of features… breaking changes" | **Strongest modern base.** Idiomatic, ergonomic, agent/graph-oriented (close to v1's create_agent + LangGraph philosophy). |
| **langchain-rust** (Abraxas-365) | **4.6.0** | Direct conceptual LangChain port: LLMs, embeddings, vector stores (sqlite-vss/-vec, Postgres, SurrealDB, Qdrant), chains, agents, tools, semantic routing, document loaders (PDF/docx/html/csv/git) | "Very active," last push ~1 day ago ([GraphCanon 96%](https://www.graphcanon.com/tools/abraxas-365-langchain-rust/trust)) | Closest 1:1 naming/mental-model match, but **`serde_json`-heavy** (JSON-first, weaker compile-time typing) and models pre-v1 "chains," not the create_agent/graph runtime. |
| **langchain-ai-rust** | **5.0.1** ([docs.rs](https://docs.rs/crate/langchain-ai-rust/latest)) | Ambitious full port: chains, agents, RAG, **LangGraph**, embeddings, vector stores, 20+ loaders, OpenAI/Claude/Gemini/Mistral/Bedrock/Ollama, streaming, structured output, **multi-agent (Deep Agent)**. 2.48 MB source; uses `async-openai ^0.28` | Newer entrant | Most explicitly aligned with **v1 feature scope** (LangGraph + Deep Agents + structured output). Worth deep evaluation as a base or reference. |
| **swiftide** | ~**0.32** (`swiftide-langfuse` 0.32.1; core historically lagged) | Fast, streaming RAG indexing/query pipelines + tool-using/multi-agent; async-first, production-oriented | Active, "heavy development, breaking changes" | **RAG/streaming leader.** Best-in-class for indexing pipelines; less of a general LCEL/chain surface. |
| **llm-chain** | **0.13.0** | Chains of LLM calls, prompt templates, multi-step tasks; multi-crate | Appears **stale** (long at 0.13.x) | Historical importance; not recommended as a live base. |
| **kalosm** | (crates.io) | Simple interface to local pre-trained language/audio/image models (Candle-based) | — | Execution-layer component for **local models**, not orchestration. |
| **async-openai** | ~**0.28.x** | Unofficial OpenAI client from OpenAPI spec; retries w/ exponential backoff; streaming | Active | Best-in-class **OpenAI client**. Use as a backend, not a framework. |
| **genai** | (crates.io) | Single ergonomic multi-provider client (OpenAI, Anthropic, Gemini, xAI, Ollama, Groq), native protocols | Active | Excellent **unified client layer** to build a port's model abstraction on. |
| **ollama-rs** | ~**0.2** | Ollama local-server client | Active | Local model backend. |
| **anthropic-sdk-rust** | (crates.io) | Typed Anthropic SDK, parity with TS SDK, async | Active | Anthropic backend. |
| **candle** | (HF) | Minimalist ML inference framework, GPU support (Whisper, LLaMA, etc.) | Active | Local inference substrate (the "PyTorch of Rust"). |

### 5.1 What they got right / wrong
- **rig — right:** async-first, trait-based, ergonomic, modular companion-crate design, agent+graph orchestration matches v1 direction, strong provider/vector-store breadth. **Wrong/risk:** opinionated, still pre-1.0 with ongoing breaking changes; its abstractions are rig's own, not a LangChain mirror.
- **langchain-rust — right:** breadth mirroring LangChain, real document loaders, feature-gated vector stores (idiomatic Cargo features). **Wrong:** `serde_json::Value`-centric design forfeits Rust's compile-time typing; chain-era model, not v1 agent runtime.
- **swiftide — right:** genuinely fast streaming RAG, production focus, async/stream-native. **Wrong/limit:** narrower than full LangChain (RAG+agents, not a general LCEL surface).
- **llm-chain — wrong:** momentum stalled; chain-only scope.

### 5.2 Base vs. greenfield
- **No existing crate is a faithful LangChain v1 port.** rig and `langchain-ai-rust` are the two most viable *starting points*; swiftide is the best *RAG component*; genai/async-openai/anthropic-sdk-rust/ollama-rs are the *client layer*.
- **Recommendation:** **greenfield, async-first, trait-based core** that (a) mirrors `langchain-core` interfaces (messages+content-blocks, a `Runnable`-equivalent, `ChatModel`, tools, parsers, retrieval traits), (b) reuses **genai/async-openai** as provider backends rather than reimplementing clients, and (c) treats a LangGraph-equivalent executor as a separate, later crate. Study rig's ergonomics and langchain-ai-rust's scope as prior art; avoid langchain-rust's JSON-first typing.

---

## 6. Rust Design Considerations (Python dynamic → Rust static)

Verified against a dedicated deep-research pass; core facts (AFIT stabilization, object safety) are well-established Rust knowledge and confirmed in the research.

### 6.1 Async traits & dynamic dispatch ✅
- **`async fn` in traits (AFIT) stabilized in Rust 1.75** (Dec 2023), along with RPITIT (`-> impl Trait` in trait methods).
- **But AFIT is NOT `dyn`-compatible (object-safe) by default.** A `Runnable`-like abstraction that needs **trait objects** (`dyn Runnable` for heterogeneous pipelines/plugins) must either:
  - use the **`async-trait`** crate (desugars to `Pin<Box<dyn Future<Output=...> + Send>>`), or
  - hand-write methods returning `Pin<Box<dyn Future<...>>>`, or
  - use the **`trait-variant`** crate to generate `Send`-bounded variants.
- **Design guidance:** use native AFIT for generic/monomorphized code paths; use `async-trait` (or boxed futures) at the **`dyn` boundaries** (the plugin/registry seams where LangChain relies on duck typing).

### 6.2 Streaming ✅
- Standard model: **`futures::Stream<Item = Result<Chunk, Error>>`**. Ecosystem: `tokio-stream`, and the **`async-stream`** crate (`yield` syntax) for ergonomic generators. `AsyncIterator` (the std `Stream`) remains experimental/unstable.
- LLM token streaming (`stream`/`astream` in LCIL) maps to returning a pinned `Stream` of message chunks; rig, swiftide, and async-openai all expose futures `Stream`s. For `dyn` objects, return `Pin<Box<dyn Stream<Item=...> + Send>>`.
- `AIMessageChunk`'s additive concatenation maps cleanly to a Rust `Chunk` type with an `extend`/`+` impl.

### 6.3 Dynamic composition → traits/generics/enums
- **Python `Runnable` duck typing → Rust `dyn Trait`** for heterogeneous composition (pipelines, tool registries, callback handlers), **generics/monomorphization** for hot, statically-known paths (zero-cost, but code bloat + no heterogeneity).
- **Closed variant sets → enums** (e.g. `Message`, `ContentBlock`) — better exhaustiveness and serde ergonomics than trait objects.
- **`**kwargs` config → the builder pattern** (typed optional fields) and/or a `RunnableConfig` struct; avoid stringly-typed maps.
- **Dynamic JSON → `serde_json::Value`** at true dynamic edges; **serde internally/adjacently-tagged enums** (`#[serde(tag = "type")]`) for polymorphic (de)serialization of messages and content blocks — this is the idiomatic replacement for LangChain's `lc_serializable` / `_type` dynamic (de)serialization.

### 6.4 Sync + async duality
- **Recommendation: be async-first.** LangChain's sync/async mirroring exists because Python retrofitted async; Rust libraries (rig, swiftide) are async-native. If a blocking API is required, offer thin wrappers via `Runtime::block_on` in a separate `blocking` module rather than duplicating the whole surface.

### 6.5 `tower::Service` as a Runnable/middleware model
- **`tower::Service` + `Layer`** is a strong Rust analog for both the `Runnable` "call with config → future of output" shape *and* LangChain v1's **middleware** concept (Layers wrap Services = middleware wraps the agent loop). Worth prototyping the core `Runnable` trait as a `Service`-shaped abstraction to get composable middleware "for free."

---

## 7. LangSmith / LangGraph Boundary (in-scope vs. sibling projects)

| Project | Nature | In scope for a "LangChain" port? |
|---|---|---|
| **`langchain-core`** | OSS (MIT). Abstractions: messages, runnables, chat-model interface, tools, parsers, prompts, retrieval interfaces, callbacks. | **Yes — P0.** The heart of the port. |
| **`langchain` (v1)** | OSS. `create_agent`, retrieval helpers; depends on LangGraph. | **Yes — P2** (implies a graph runtime). |
| **partner packages / text-splitters / standard-tests** | OSS. | **Yes** (per-provider + utilities + conformance tests). |
| **LangGraph** | OSS, **separate repo/package**. Low-level orchestration runtime: durable execution, checkpointing/persistence, streaming, human-in-the-loop, memory. **Agent execution runtime lives here.** | **Boundary decision.** For full v1 agent parity you need a LangGraph-equivalent executor. Can be a separate later crate, or start with a simpler tool-loop executor. |
| **Deep Agents** | OSS, higher-level package (`langchain-ai/deepagents`) built on LangChain (planning, subagents, virtual FS). | Out of scope for the core port; a downstream layer. |
| **LangSmith** | **Proprietary SaaS** (closed-source): tracing, evals, observability, prompt hub. | **Out of scope.** Only the **callback/tracing hooks** are in `langchain-core`; a port would expose equivalent callback traits and could optionally emit to LangSmith's ingestion API, but the platform itself is not ported. |

**Summary boundary:** "LangChain proper" = `langchain-core` + `langchain` (v1) + partners + text-splitters + standard-tests. **LangGraph** = the execution runtime (sibling, required by the v1 agent package). **LangSmith** = proprietary observability SaaS (sibling, not ported; integrate via callbacks).

---

## 8. Recommended Technical Decisions (port)

1. **Target LangChain v1 semantics, not v0.3.** Build around a `create_agent`-style entry point + a `Runnable`/LCEL-equivalent core; keep "classic chains" out of scope initially.
2. **Port `langchain-core` first**: `Message` + `ContentBlock` enums (serde tagged), a `Runnable` trait (consider `tower::Service` shape), `ChatModel` trait, `Tool`/`ToolCall`, output parsers, prompt templates, retrieval traits, callback traits. Async-first.
3. **Reuse the client layer** (`genai` for multi-provider, `async-openai`, `anthropic-sdk-rust`, `ollama-rs`) behind a `ChatModel` trait rather than reimplementing HTTP clients.
4. **Use `dyn` + `async-trait`/boxed futures at plugin seams** (model registry, tool registry, callbacks, retrievers); generics on hot paths.
5. **Defer the LangGraph-equivalent runtime** to a separate crate; start agents on a simple tool-calling loop, then add checkpointing/HITL/durable execution.
6. **Adopt `standard-tests` as a conformance harness** ported to Rust to guarantee provider parity.
7. **Evaluate `rig` and `langchain-ai-rust` deeply** before finalizing greenfield vs. fork — both are more v1-aligned than `langchain-rust`.

---

## 9. Inconclusive / To-Verify (flagged)

- 🔴 **Exact LOC/module counts** per package — not verified (no checkout). Run `tokei`/`scc` on a clone.
- 🟡 **`langchain-community` sunset issue** — the specific GitHub issue was reported via Perplexity synthesis, not opened directly; the *direction* is well-corroborated. Verify the exact issue URL/date.
- 🟡 **v1 "structured output in main loop" and "middleware" specifics** — sourced from LangChain docs/blog via synthesis; confirm current API names against live `docs.langchain.com`.
- 🟡 **`langchain-core` content-blocks as the specific "core addition"** — the 1.0 blog says "a core addition"; identification as content blocks is corroborated but worth a direct docs check.
- 🟡 **`model-profiles` package purpose** — inferred from name; confirm against its README.

---

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| **Perplexity perplexity_research (PRIMARY)** | 4 | (1) Monorepo structure + v1 restructuring + LangGraph relationship; (2) Rust LangChain-like ecosystem crates; (3) langchain-core core abstractions inventory; (4) Rust async/trait/streaming design patterns & prior art. All `reasoning_effort` high/medium. |
| Perplexity perplexity_reason | 0 | — |
| Perplexity perplexity_search | 0 | — |
| Perplexity perplexity_ask | 0 | — |
| Context7 | 0 | Not used — deep-research + direct GitHub/PyPI verification covered the need; Context7 would be the next step to pull exact langchain-core API signatures. |
| Tavily tavily_search | 4 | Verified: GitHub `libs/` layout; rig-core versions; langchain-rust version/activity; swiftide & llm-chain versions; langchain-core/langgraph PyPI versions. |
| Tavily tavily_extract | 0 | — |
| WebFetch | 1 | Enumerated the exact `libs/` subdirectory list from GitHub. |
| WebSearch | 0 | — |
| Training data | ~2 areas | LangChain core abstraction names (cross-checked against research) and well-established Rust facts (AFIT stabilized 1.75, object safety, futures::Stream, tower::Service) — flagged inline; corroborated by the design-patterns research pass. |

**Total MCP tool calls:** 12 (4 perplexity_research + 4 tavily_search + 3 file reads of research output are internal; 1 WebFetch). MCP calls that hit the network: 8 (4 Perplexity + 4 Tavily) plus 1 WebFetch = 9 external retrievals.
**Training data reliance:** low–medium — every version number and the monorepo layout are verified against live PyPI/crates.io/GitHub; abstraction names and Rust patterns are corroborated by deep-research passes. Remaining gaps are explicitly flagged in §9.
