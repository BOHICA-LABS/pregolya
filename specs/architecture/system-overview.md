---
document_type: architecture-section
level: L3
section: system-overview
version: "1.4"
status: active
producer: architect
timestamp: 2026-07-25T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "3f5c44e"
traces_to: ARCH-INDEX.md
decisions: [D4, D6, D7, D9, D11, D13, D17, D21, D23]
changelog:
  - "1.4 (FIX-BURST-276/F-P173-802/2026-07-27): F-P173-802 — fix P-06 principle. (1) Remove forbidden edge: original `pregolya-core ← pregolya-graph ← pregolya-checkpoint ← pregolya-server` asserted `pregolya-graph ← pregolya-checkpoint` which, under the `←`=depended-upon-by convention, means checkpoint depends on graph — explicitly forbidden by dependency-graph.md §Invariant. (2) Correct topology: swap checkpoint and graph in the chain so `pregolya-checkpoint ← pregolya-graph` now reads as graph depends on checkpoint (correct; graph::budget uses CheckpointSaver::search_history per BC-2.04.008 / ADR-019, added in dependency-graph.md §CheckpointSaver-graph-dependency). (3) Add explicit `←` arrow convention note inline so no future reader must guess direction. (4) Note pregolya-server's direct checkpoint dependency. Corrected chain: `pregolya-core ← pregolya-checkpoint ← pregolya-graph ← pregolya-server` (pregolya-server also depends directly on pregolya-checkpoint). Verified against dependency-graph.md §Invariant and Edge Table."
  - "1.3 (FIX-BURST-265/F-P163-02/2026-07-25): Propagate D21+D23 21-crate roster. [Section Content] heading 18-crate→21-crate. Crate Topology heading 18→21. Code block: add pregolya-tools (Wave 1, D23/ADR-020) after pregolya-memory; add pregolya-prompts (Wave 2, D21/ADR-015) and pregolya-vectorstores (Wave 2, D21/ADR-014) after pregolya-mcp. Wave Alignment table: Wave 1 gains pregolya-memory (D23 Wave 2→1 promotion) + pregolya-tools; Wave 2 loses pregolya-memory, gains pregolya-prompts + pregolya-vectorstores."
  - "1.2 (burst-241/2026-07-23): F-P141-02 — expand NFR-003 Key Constraints gate from 3 P0 Kani VPs (VP-001/002/003, D17-Q7 only) to 6 P0 Kani VPs (VP-001/002/003/009/010/011, D17-Q7 + D21 + D23); add note on 3 P1 Kani VPs (VP-006/012/013). VP-009 (zero-norm cosine guard, SAFETY), VP-010 (reviver allowlist containment, SECURITY), VP-011 (PreToolCallHook fail-closed, SECURITY/SAFETY) confirmed P0 under production-grade default — fail-closed security/safety proofs are must-pass-before-v1. Add D21/D23 to decisions list."
  - "1.1 (provenance-fix-169/2026-07-17): remove .factory/STATE.md from inputs (not a genuine spec-content input; D-NNN decisions are baked-in stable facts); add domain-spec/invariants.md (genuine: DI-001, DI-008, DI-010 cited in Principles table)."
  - "1.0 (initial): system overview authored."
---

# System Overview: pregolya

## [Section Content]

This section documents pregolya's system-level architecture: its vision and deployment
topology, architecture principles, 21-crate topology, wave delivery plan, design-forcing
holdout domains, and key implementation constraints.

## Vision

pregolya is a Rust implementation of the LangChain v1 architecture: a Cargo workspace
of independently-publishable crates delivering the LangGraph StateGraph execution model
(BSP scheduling, durable per-task checkpointing, HITL interrupt/resume), provider
conformance testing, and a formally-verified core — without the Python runtime.

**External API:** LangChain Python v1 semantics (D17 HYBRID).
**Internal patterns:** 43 ADOPT/ADAPT from adk-rust v1.0.0 (COMPARATIVE-ASSESSMENT.md).
**Anti-patterns:** 17 NE must-not-inherit patterns enforced by BCs, CI lint gates, or ADRs.

## Deployment Topology

**`single-service`** — one Cargo workspace (D4), single repo, crates publish independently
to crates.io. No multi-service boundary; pregolya-server is first-party (D13) and
built in-workspace. No wire-compatibility with LangGraph Platform.

## Architecture Principles

| # | Principle | Consequence |
|---|-----------|-------------|
| P-01 | Purity-first | Pure-core functions are formal verification targets; effectful shell is integration-tested |
| P-02 | Production defaults | Sync checkpoint tier default; enforcing sandbox default; secure server config default |
| P-03 | No panics in library code | All public constructors return `Result`; no `.unwrap()`/`.expect()` outside tests (DI-008) |
| P-04 | Credential opacity | API key newtypes with redacted Debug; no Serialize; no Deref<Target=str> (DI-010) |
| P-05 | Deterministic execution | BSP super-step produces identical output for identical input regardless of task order (DI-001) |
| P-06 | Dependency direction is acyclic | `pregolya-core ← pregolya-checkpoint ← pregolya-graph ← pregolya-server` (`←` = "is depended upon by"; pregolya-server also depends directly on pregolya-checkpoint); no cycles. Verified against dependency-graph.md §Invariant. |
| P-07 | File size gate | ≤500 lines soft / ≤750 hard per production file; CI-enforced via `cargo xtask check-file-size` (D12) |

## Crate Topology (21 published crates; see ARCH-INDEX.md §Canonical Crate Roster)

```
pregolya                — Re-export facade (optional convenience re-export)
pregolya-core           — Runnable/Message/ContentBlock, PregolyaError, credential newtypes
pregolya-macros         — Proc-macros: #[tool], #[entrypoint], #[task]; re-exported from core
pregolya-graph          — StateGraph BSP engine, HITL, budget governance, provenance/guardrail
pregolya-checkpoint     — per-task put_writes, SQLite/memory backends, monotonic clock
pregolya-server         — Axum HTTP: threads/assistants/runs/schedules, SecurityConfig
pregolya-splitters      — Unicode code-point text splitting (isolated; no graph dep)
pregolya-sandbox        — WASM/container tool execution, workspace path confinement
pregolya-memory         — Long-horizon memory: MemoryStore trait, SQLite/in-memory backends
pregolya-tools          — First-party tools: tools::fs, tools::shell, tools::search [D23/ADR-020]
pregolya-openai-sdk     — OpenAI standalone wire client (no pregolya-core dep) [D17-Q5]
pregolya-openai         — OpenAI adapter: impl BaseChatModel (depends on core + openai-sdk)
pregolya-anthropic-sdk  — Anthropic standalone wire client [D17-Q5]
pregolya-anthropic      — Anthropic adapter: impl BaseChatModel
pregolya-ollama-sdk     — Ollama standalone wire client [D17-Q5]
pregolya-ollama         — Ollama adapter: impl BaseChatModel (local-first, no API key newtype)
pregolya-standard-tests — Conformance test suite (each adapter crate as dev-dep)
pregolya-mcp            — MCP tool adapter (langchain-mcp-adapters semantic port)
pregolya-prompts        — Prompt templates: f-string + jinja2 rendering, injection guard [D21/ADR-015]
pregolya-vectorstores   — VectorStore trait, in-memory backend, MMR, VectorStoreRetriever [D21/ADR-014]
pregolya-community      — [post-v1; third-party contributed; not in-tree at v1]
xtask                     — Cargo workspace tooling: file-size gate, timeout lint, namespace check
```

## Wave Alignment (D7: core → graph → partners)

| Wave | Crates | Phase |
|------|--------|-------|
| Wave 0 | (no new crates) — cross-cutting foundational types and CI-lint gates in pregolya-core that all Wave 1 crates depend on: PregolyaError struct (BC-2.14.001–003), HTTP timeout lint (BC-2.14.004), credential opacity newtype (BC-2.14.005), validation propagation (BC-2.14.006); also Core Primitives (BC-2.01.001–004) and Text Splitting API shape (BC-2.07.001–003) which are authored before the Wave 1 CI run | Phase 2 (spec/CI setup) |
| Wave 1 | pregolya-core, pregolya-macros, pregolya-graph, pregolya-checkpoint, pregolya-server, pregolya-splitters, pregolya-sandbox, pregolya-memory (D23 Wave 2→1), pregolya-tools (D23/ADR-020) | Phase 3 |
| Wave 2 | pregolya-openai-sdk, pregolya-openai, pregolya-anthropic-sdk, pregolya-anthropic, pregolya-ollama-sdk, pregolya-ollama, pregolya-standard-tests, pregolya-mcp, pregolya-prompts (D21/ADR-015), pregolya-vectorstores (D21/ADR-014) | Phase 3 (after Wave 1) |
| Post-v1 | pregolya-community, additional providers | Post Phase 7 |

## Design-Forcing Holdout Domains (D8)

- **Domain A (SOC analyst):** risk-tiered HITL (SS-05), content provenance/guardrail (SS-11), forensic audit
- **Domain B (dark factory):** multi-day durable runs (SS-04), budget governance (SS-10), crash recovery (SS-04)
- **Domain C (OpenClaw):** persistent sessions (SS-04, SS-05), local-first single binary, pregolya-server (SS-12)

## Key Constraints

- **D9 gate:** pregolya-graph execution model ADR (ADR-001) requires ≥2 alternatives presented to human before lock.
- **D5 gate:** serde/schemars ADR (ADR-004) must precede any proc-macro BCs (#[tool], #[entrypoint]).
- **NFR-003:** All 6 P0 Kani VPs (VP-001, VP-002, VP-003, VP-009, VP-010, VP-011) must pass before v1 release (Phase 6 convergence gate). Three P1 Kani VPs (VP-006, VP-012, VP-013) are Phase 6 goals but not gate-blocking. See verification-architecture.md for full VP catalog.
- **NFR-004:** File size gate ≤750 lines hard; CI blocks on violation.
