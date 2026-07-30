---
artifact: semport/reference-manifest
version: 1.4.0
created: 2026-07-12
updated: 2026-07-13
purpose: >
  Pinned reference corpus for the pregolya semport analysis.
  All repos are shallow-cloned at their latest stable release tags
  so the codebase-analyzer has a stable, reproducible source of truth.
---

# Semport Reference Corpus Manifest

## Repository Index

| Repo                     | URL                                                       | Pinned Tag                           | Commit SHA                               | Clone Date |
|--------------------------|-----------------------------------------------------------|--------------------------------------|------------------------------------------|------------|
| langchain                | https://github.com/langchain-ai/langchain                 | langchain==1.3.13                    | 42f8f79293cfb7589e5bc1d74a8ae4dfd0bf15e3 | 2026-07-12 |
| langgraph                | https://github.com/langchain-ai/langgraph                 | 1.2.9                                | 95af6a00718588e7b7ce17310e8006d267896a77 | 2026-07-12 |
| langchain-community      | https://github.com/langchain-ai/langchain-community       | libs/community/v0.4.2                | 7c10a5fa327f6aaaf7c932822a9e5d144891406e | 2026-07-12 |
| langchain-mcp-adapters   | https://github.com/langchain-ai/langchain-mcp-adapters    | langchain-mcp-adapters==0.3.0        | a61c783a7949719a8c3fbe4aeba961f45f3b7849 | 2026-07-12 |
| adk-rust                 | https://github.com/zavora-ai/adk-rust                     | v1.0.0                               | a6c79b6f97a338de58d2c0fbf33cac00eaae0f13 | 2026-07-13 |

Local clone paths (relative to repo root, excluded from git via `.gitignore`):

- `.reference/langchain/`
- `.reference/langgraph/`
- `.reference/langchain-community/`
- `.reference/langchain-mcp-adapters/`
- `.reference/adk-rust/`

All clones are shallow (`--depth 1`).

---

## langchain — Package Layout

Tag: `langchain==1.3.13`
SHA: `42f8f79293cfb7589e5bc1d74a8ae4dfd0bf15e3`
Top-level repo dirs: `libs/`, `README.md`, `CITATION.cff`, `CLAUDE.md`, `AGENTS.md`

```
libs/
├── core/                    # langchain_core — base interfaces (Runnable, BaseMessage, etc.)
│   └── langchain_core/
├── langchain_v1/            # ** THE v1 package ** — pip install langchain==1.x ships from here
│   └── langchain/           #    Python module is named `langchain`, not `langchain_v1`
├── langchain/               # Renamed legacy: now called langchain_classic (breaking rename)
│   └── langchain_classic/   #    pip install langchain-classic
├── partners/                # First-party partner integrations (each is its own pip package)
│   ├── anthropic/
│   ├── chroma/
│   ├── deepseek/
│   ├── exa/
│   ├── fireworks/
│   ├── groq/
│   ├── huggingface/
│   ├── mistralai/
│   ├── nomic/
│   ├── ollama/
│   ├── openai/
│   ├── openrouter/
│   ├── perplexity/
│   ├── qdrant/
│   └── xai/
├── standard-tests/          # langchain_tests — shared test suites for partner compliance
│   └── langchain_tests/
├── text-splitters/          # langchain_text_splitters — standalone text splitting utilities
│   └── langchain_text_splitters/
└── model-profiles/          # langchain_model_profiles — model capability metadata
    └── langchain_model_profiles/
```

---

## langgraph — Package Layout

Tag: `1.2.9`
SHA: `95af6a00718588e7b7ce17310e8006d267896a77`
Top-level repo dirs: `libs/`, `docs/`, `examples/`, `README.md`, `CONTRIBUTING.md`, `security.md`

```
libs/
├── langgraph/               # Core graph engine (StateGraph, nodes, edges, streaming)
│   ├── langgraph/
│   └── bench/
├── checkpoint/              # Abstract checkpoint interface (BaseCheckpointSaver)
│   └── langgraph/
├── checkpoint-conformance/  # NEW in v1.x — conformance test suite for checkpoint backends
│   └── langgraph/
├── checkpoint-postgres/     # PostgreSQL checkpoint backend
│   └── langgraph/
├── checkpoint-sqlite/       # SQLite checkpoint backend
│   └── langgraph/
├── prebuilt/                # Pre-built agents: create_react_agent, ToolNode, etc.
│   └── langgraph/
├── cli/                     # LangGraph deployment CLI (langgraph-cli)
│   ├── langgraph_cli/
│   ├── examples/
│   ├── js-examples/
│   ├── js-monorepo-example/ # NEW in v1.x
│   ├── python-monorepo-example/ # NEW in v1.x
│   └── uv-examples/         # NEW in v1.x
├── sdk-py/                  # Python client SDK for LangGraph Platform API
│   └── langgraph_sdk/
└── sdk-js/                  # JavaScript/TypeScript client SDK
```

Note: `libs/scheduler-kafka` present at 0.3.34 is absent at 1.2.9 — likely moved
to a separate repo or removed from the monorepo.

---

## langchain-community — Package Layout

Tag: `libs/community/v0.4.2`
SHA: `7c10a5fa327f6aaaf7c932822a9e5d144891406e`
Top-level repo dirs: `libs/`, `README.md`, `CLAUDE.md`, `AGENTS.md`

Single package: `libs/community/langchain_community/`

### Integration Module Counts

| Category               | Module Count |
|------------------------|--------------|
| document_loaders       | 171          |
| llms                   | 102          |
| vectorstores           | 89           |
| tools                  | 87           |
| embeddings             | 77           |
| chat_models            | 49           |
| retrievers             | 43           |
| **Total source files** | **~1,051**   |

Full category listing of `langchain_community/`:

```
├── adapters/
├── agent_toolkits/
├── agents/
├── callbacks/
├── chains/
├── chat_loaders/
├── chat_message_histories/
├── chat_models/              # 49 providers
├── cross_encoders/
├── docstore/
├── document_compressors/
├── document_loaders/         # 171 loaders (largest category)
├── document_transformers/
├── embeddings/               # 77 providers
├── example_selectors/
├── graph_vectorstores/
├── graphs/
├── indexes/
├── llms/                     # 102 providers
├── memory/
├── output_parsers/
├── query_constructors/
├── retrievers/               # 43 retrievers
├── storage/
├── tools/                    # 87 tools
├── utilities/
├── utils/
└── vectorstores/             # 89 stores
```

---

## langchain ↔ langgraph Dependency Boundary

LangGraph depends on `langchain-core` (`libs/core`) as its only langchain
dependency — it does NOT import from `libs/langchain_v1` or `libs/langchain`.
LangChain Community also depends only on `langchain-core`, not on the main
`langchain` package. Clean layering target for the Rust port:

```
langchain-core-rs        ← port of libs/core          (Runnable, BaseMessage, etc.)
       ↑                 ↑
langgraph-rs             langchain-community-rs         ← ~1,051 integration modules
       ↑
langchain-rs             ← port of libs/langchain_v1   (chains, agents, retrievers)
       ↑
langchain-partners-rs    ← 15 first-party partner crates (openai, anthropic, etc.)
```

---

## Corrections Log

### Correction 1 — LangGraph re-pin: 0.3.34 → 1.2.9

- **Original pin:** `0.3.34` (SHA `6263c2f71088d7d5fcaed8585948bd5868488996`)
- **Corrected pin:** `1.2.9` (SHA `95af6a00718588e7b7ce17310e8006d267896a77`)
- **Root cause:** The initial tag-resolution pipeline used `sort -t. -k2 -V` on
  a filtered stream that had already dropped tags whose names begin with `1.`
  without a `v` prefix. LangGraph's v1 series uses bare semver (e.g., `1.2.9`),
  not `v1.2.9`. The `-k2` field split on `.` incorrectly decomposed `1.2.9` and
  the version sort placed these tags after the `v0.x.y` entries in a short
  `tail -20` window, making `0.3.34` appear to be the highest. A direct probe
  via `git ls-remote refs/tags/1.2.9` confirmed the tag and SHA against the
  coordinator-provided value.
- **Structural impact:** v1.2.9 adds `libs/checkpoint-conformance/` (new conformance
  test suite for backend implementors) and additional CLI example directories
  (`js-monorepo-example`, `python-monorepo-example`, `uv-examples`). The
  `libs/scheduler-kafka` package present in 0.3.34 is absent in v1.2.9.

### Correction 2 — langchain-community added to corpus

Scope expansion, not an error. `langchain-community` was separated out of the
main langchain monorepo and is now the canonical home at
`https://github.com/langchain-ai/langchain-community`. It is not present in
`libs/` of the langchain repo at `langchain==1.3.13`.

Tag-naming anomaly: community tags use a path-style prefix — `libs/community/vX.Y.Z`.
The next tag beyond `v0.4.2` is `libs/community/v1.0.0a1` (alpha), correctly
excluded. Latest stable confirmed as `libs/community/v0.4.2`.

---

## Anomalies and Notable Findings

1. **libs/langchain renamed to langchain_classic in v1.** The new `langchain` pip
   package (v1) lives in `libs/langchain_v1/`. Port should target `libs/langchain_v1/`.

2. **Three distinct tag-naming conventions across three repos:**
   - langchain: `package==semver` (e.g., `langchain==1.3.13`)
   - langgraph: bare semver, no `v` prefix (e.g., `1.2.9`)
   - langchain-community: path-style with `v` (e.g., `libs/community/v0.4.2`)
   Tag resolution scripts must handle all three forms without assuming `v`-prefix.

3. **LangGraph is v1.x stable.** The 0.x series is legacy. Target the v1.x API surface.

4. **No libs/community in langchain monorepo.** Community integrations live
   exclusively in the separate `langchain-community` repo.

5. **langchain-community approaching v1.0 but not yet there.** Alpha tag
   `libs/community/v1.0.0a1` signals an upcoming major version bump. Expect API
   churn in community interfaces before the semport is complete.

6. **scheduler-kafka removed from langgraph v1.x.** Absent in 1.2.9, was present
   at 0.3.34. Confirm new canonical home before targeting for Rust port.

7. **Partners directory is limited to 15 in-tree.** Many third-party integrations
   live in separate repos under `langchain-ai/` org (e.g., `langchain-aws`,
   `langchain-google-*`). Community repo covers the long tail (~1,051 modules).

---

## adk-rust — Package Layout

Tag: `v1.0.0`
SHA: `a6c79b6f97a338de58d2c0fbf33cac00eaae0f13` (lightweight tag, direct commit ref)
Published: 2026-06-07
License: Apache License Version 2.0, Copyright 2026 Zavora Technologies Ltd
Workspace: Cargo workspace, resolver = "2", edition = "2024", rust-version = "1.94.0"

**Corpus 5 — comparative analysis corpus per D16; analysis parked until extraction
gate convergence; Rust-blindness rule applies.**

### Scale

| Metric                         | Count     |
|--------------------------------|-----------|
| Total files (all types)        | 2,092     |
| Rust source files (.rs)        | 1,386     |
| Rust lines (code)              | 265,316   |
| Rust lines (comments)          | 11,338    |
| Rust lines (blank)             | 41,723    |
| Rust lines (total incl. docs)  | 370,217   |
| Example crates in examples/    | 81        |

### Workspace Members (39 crates)

```
# Core agent framework
adk-core             # Base types, traits, and interfaces
adk-rust-macros      # Procedural macros
adk-rust             # Re-export facade crate

# Agent lifecycle
adk-agent            # Agent definition and execution
adk-model            # Model provider abstraction
adk-tool             # Tool definition and dispatch
adk-runner           # Agent runner (single-agent, multi-agent)
adk-session          # Session and conversation state
adk-artifact         # Artifact storage and retrieval
adk-memory           # Memory backends

# Infrastructure
adk-server           # HTTP server layer
adk-cli              # CLI binary
adk-telemetry        # OpenTelemetry tracing/metrics
adk-guardrail        # Safety and content policy
adk-auth             # Authentication helpers
adk-plugin           # Plugin system
adk-skill            # Skill registry and dispatch

# Specialized capabilities
adk-realtime         # Real-time voice agents (LiveKit)
adk-graph            # Graph-based multi-agent orchestration
adk-browser          # Browser automation integration
adk-eval             # Agent evaluation framework
adk-code             # Code execution capabilities
adk-sandbox          # Sandboxed execution environment
adk-rag              # Retrieval-augmented generation
adk-audio            # Audio processing utilities
adk-deploy           # Deployment helpers
adk-payments         # Payment agent capabilities
adk-action           # Action nodes
adk-retry-reflect    # Retry-with-reflection loop pattern

# Model provider integrations (first-party)
adk-gemini           # Google Gemini integration
adk-anthropic        # Anthropic Claude integration
adk-mistralrs        # Local LLM inference via mistralrs

# Protocols
awp-types            # Agent Wire Protocol (AWP) type definitions
adk-awp              # AWP transport implementation
adk-acp              # Agent Communication Protocol (ACP) integration

# Tooling
cargo-adk            # Cargo subcommand (cargo adk)
adk-managed          # Managed agent runtime
adk-enterprise       # Enterprise client SDK
adk-bench            # Benchmarking framework
```

### Top-Level Repository Layout

```
adk-<crate>/         # One directory per workspace member (39 crates)
awp-types/
cargo-adk/
examples/            # 81 standalone example crates (each excluded from workspace)
docs/
assets/
scripts/
Cargo.toml           # Workspace root
Cargo.lock
Makefile
publish.sh
setup.sh
devenv.nix           # Nix dev environment
devenv.lock
devenv.yaml
rust-toolchain.toml
rustfmt.toml
CHANGELOG.md
CONTRIBUTING.md
README.md
ROADMAP.md
SECURITY.md
STABILITY.md
AGENTS.md
LICENSE
```

Excluded from workspace (not present in shallow clone):
- `reference/adk-go` — Go reference implementation (separate repo concern)
- `reference/mcp-rust-sdk` — MCP Rust SDK reference
- `reference/gemini-rust` — Gemini Rust SDK reference
- `adk-studio` — extracted to https://github.com/zavora-ai/adk-studio

### Non-Rust Components

Predominantly Rust. Minor non-Rust content:
- `.wav` files: 53 (audio test samples, in adk-audio or adk-realtime)
- `.mp4` files: 3 (demo media)
- `.png`/`.jpg`/`.webp`/`.svg`: ~27 image assets (docs/README)
- `.sh` files: 12 (setup.sh, publish.sh, build scripts)
- `.py` files: 3 (minor utility scripts)
- `.js` files: 5 (minor scripts)
- Nix files: devenv.nix (dev environment config)

### Anomalies

1. **edition = "2024", rust-version = "1.94.0".** Requires very recent Rust
   toolchain. Not yet widely deployed as of July 2026. Note during analysis.

2. **AWP protocol crates (awp-types, adk-awp).** "Agent Wire Protocol" — bespoke
   inter-agent communication protocol not present in LangChain/LangGraph.
   Relationship to A2A/MCP/ACP unclear until analysis gate opens.

3. **ACP integration (adk-acp).** "Agent Communication Protocol" — distinct from
   AWP. May be interop with external ACP standard.

4. **adk-payments crate.** Payment capabilities built into the agent framework.
   No Python LangChain analog. Scope anomaly to flag for D16 analysis.

5. **adk-retry-reflect.** Name suggests a retry-with-self-reflection loop pattern.
   No direct LangChain equivalent (closest: LangGraph's re-try edges). May be a
   pregolya-relevant pattern.

6. **81 example crates.** Large example surface area; excluded from workspace to
   avoid build-time cost. Rich pattern source if analysis gate opens.

7. **Active and well-maintained.** 23 tags, v1.0.0 published 2026-06-07, active
   changelog. Not archived.
