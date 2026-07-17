---
document_type: architecture-section
level: L3
section: system-overview
version: "1.1"
status: active
producer: architect
timestamp: 2026-07-17T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "86eb7e8"
traces_to: ARCH-INDEX.md
decisions: [D4, D6, D7, D9, D11, D13, D17]
changelog:
  - "1.0 (initial): system overview authored."
  - "1.1 (provenance-fix-169/2026-07-17): remove .factory/STATE.md from inputs (not a genuine spec-content input; D-NNN decisions are baked-in stable facts); add domain-spec/invariants.md (genuine: DI-001, DI-008, DI-010 cited in Principles table)."
---

# System Overview: ferrochain

## [Section Content]

This section documents ferrochain's system-level architecture: its vision and deployment
topology, architecture principles, 18-crate topology, wave delivery plan, design-forcing
holdout domains, and key implementation constraints.

## Vision

ferrochain is a Rust implementation of the LangChain v1 architecture: a Cargo workspace
of independently-publishable crates delivering the LangGraph StateGraph execution model
(BSP scheduling, durable per-task checkpointing, HITL interrupt/resume), provider
conformance testing, and a formally-verified core — without the Python runtime.

**External API:** LangChain Python v1 semantics (D17 HYBRID).
**Internal patterns:** 43 ADOPT/ADAPT from adk-rust v1.0.0 (COMPARATIVE-ASSESSMENT.md).
**Anti-patterns:** 17 NE must-not-inherit patterns enforced by BCs, CI lint gates, or ADRs.

## Deployment Topology

**`single-service`** — one Cargo workspace (D4), single repo, crates publish independently
to crates.io. No multi-service boundary; ferrochain-server is first-party (D13) and
built in-workspace. No wire-compatibility with LangGraph Platform.

## Architecture Principles

| # | Principle | Consequence |
|---|-----------|-------------|
| P-01 | Purity-first | Pure-core functions are formal verification targets; effectful shell is integration-tested |
| P-02 | Production defaults | Sync checkpoint tier default; enforcing sandbox default; secure server config default |
| P-03 | No panics in library code | All public constructors return `Result`; no `.unwrap()`/`.expect()` outside tests (DI-008) |
| P-04 | Credential opacity | API key newtypes with redacted Debug; no Serialize; no Deref<Target=str> (DI-010) |
| P-05 | Deterministic execution | BSP super-step produces identical output for identical input regardless of task order (DI-001) |
| P-06 | Dependency direction is acyclic | ferrochain-core ← ferrochain-graph ← ferrochain-checkpoint ← ferrochain-server; no cycles |
| P-07 | File size gate | ≤500 lines soft / ≤750 hard per production file; CI-enforced via `cargo xtask check-file-size` (D12) |

## Crate Topology (18 published crates; see ARCH-INDEX.md §Canonical Crate Roster)

```
ferrochain                — Re-export facade (optional convenience re-export)
ferrochain-core           — Runnable/Message/ContentBlock, FerrochainError, credential newtypes
ferrochain-macros         — Proc-macros: #[tool], #[entrypoint], #[task]; re-exported from core
ferrochain-graph          — StateGraph BSP engine, HITL, budget governance, provenance/guardrail
ferrochain-checkpoint     — per-task put_writes, SQLite/memory backends, monotonic clock
ferrochain-server         — Axum HTTP: threads/assistants/runs/schedules, SecurityConfig
ferrochain-splitters      — Unicode code-point text splitting (isolated; no graph dep)
ferrochain-sandbox        — WASM/container tool execution, workspace path confinement
ferrochain-memory         — Long-horizon memory: MemoryStore trait, SQLite/in-memory backends
ferrochain-openai-sdk     — OpenAI standalone wire client (no ferrochain-core dep) [D17-Q5]
ferrochain-openai         — OpenAI adapter: impl BaseChatModel (depends on core + openai-sdk)
ferrochain-anthropic-sdk  — Anthropic standalone wire client [D17-Q5]
ferrochain-anthropic      — Anthropic adapter: impl BaseChatModel
ferrochain-ollama-sdk     — Ollama standalone wire client [D17-Q5]
ferrochain-ollama         — Ollama adapter: impl BaseChatModel (local-first, no API key newtype)
ferrochain-standard-tests — Conformance test suite (each adapter crate as dev-dep)
ferrochain-mcp            — MCP tool adapter (langchain-mcp-adapters semantic port)
ferrochain-community      — [post-v1; third-party contributed; not in-tree at v1]
xtask                     — Cargo workspace tooling: file-size gate, timeout lint, namespace check
```

## Wave Alignment (D7: core → graph → partners)

| Wave | Crates | Phase |
|------|--------|-------|
| Wave 0 | (no new crates) — cross-cutting foundational types and CI-lint gates in ferrochain-core that all Wave 1 crates depend on: FerrochainError struct (BC-2.14.001–003), HTTP timeout lint (BC-2.14.004), credential opacity newtype (BC-2.14.005), validation propagation (BC-2.14.006); also Core Primitives (BC-2.01.001–004) and Text Splitting API shape (BC-2.07.001–003) which are authored before the Wave 1 CI run | Phase 2 (spec/CI setup) |
| Wave 1 | ferrochain-core, ferrochain-macros, ferrochain-graph, ferrochain-checkpoint, ferrochain-server, ferrochain-splitters, ferrochain-sandbox | Phase 3 |
| Wave 2 | ferrochain-openai-sdk, ferrochain-openai, ferrochain-anthropic-sdk, ferrochain-anthropic, ferrochain-ollama-sdk, ferrochain-ollama, ferrochain-standard-tests, ferrochain-mcp, ferrochain-memory | Phase 3 (after Wave 1) |
| Post-v1 | ferrochain-community, additional providers | Post Phase 7 |

## Design-Forcing Holdout Domains (D8)

- **Domain A (SOC analyst):** risk-tiered HITL (SS-05), content provenance/guardrail (SS-11), forensic audit
- **Domain B (dark factory):** multi-day durable runs (SS-04), budget governance (SS-10), crash recovery (SS-04)
- **Domain C (OpenClaw):** persistent sessions (SS-04, SS-05), local-first single binary, ferrochain-server (SS-12)

## Key Constraints

- **D9 gate:** ferrochain-graph execution model ADR (ADR-001) requires ≥2 alternatives presented to human before lock.
- **D5 gate:** serde/schemars ADR (ADR-004) must precede any proc-macro BCs (#[tool], #[entrypoint]).
- **NFR-003:** All 3 Kani VPs (VP-001, VP-002, VP-003) must pass before v1 release.
- **NFR-004:** File size gate ≤750 lines hard; CI blocks on violation.
