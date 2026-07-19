---
document_type: architecture-section
level: L3
section: dependency-graph
version: "1.1"
status: active
producer: architect
timestamp: 2026-07-17T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/specs/prd.md
input-hash: "4ef284a"
traces_to: ARCH-INDEX.md
decisions: [D4, D6, D7]
changelog:
  - "1.1 (provenance-fix-169/2026-07-17): hash-currency refresh — prd.md updated to v1.2 in same burst; add [Section Content] template compliance fix. No spec content changes."
  - "1.0 (initial): crate dependency DAG authored."
---

# Dependency Graph: ferrochain

> All edges are uni-directional. No cycles are permitted (P-06).
> External crates (tokio, axum, reqwest, serde, etc.) omitted for clarity.

## [Section Content]

This file documents ferrochain's crate dependency DAG, external integration surfaces, and the acyclicity constraint (DI-012 / P-06). External crates (tokio, axum, reqwest, serde, etc.) are omitted for clarity; only workspace-internal dependency edges are shown.

## Crate DAG

```
ferrochain-core
  ├── ferrochain-macros         (proc-macro crate; re-exported from core)
  │
  ├── ferrochain-graph          (uses core: Runnable, Message, FerrochainError)
  │   └── ferrochain-checkpoint (uses core: CheckpointSaver, FerrochainError)
  │       └── ferrochain-server (uses graph + checkpoint: runs + threads + cron)
  │
  ├── ferrochain-splitters      (uses core: FerrochainError only; isolated)
  │
  ├── ferrochain-sandbox        (uses core: FerrochainError; ferrochain-graph uses sandbox)
  │   [ferrochain-graph → ferrochain-sandbox for tool dispatch]
  │
  ├── ferrochain-memory         (uses core: FerrochainError; MemoryStore trait)
  │
  ├── ferrochain-openai-sdk     (NO ferrochain-core dep; reqwest + serde only) [D17-Q5]
  │   └── ferrochain-openai     (uses core: BaseChatModel + openai-sdk)
  ├── ferrochain-anthropic-sdk  (NO ferrochain-core dep) [D17-Q5]
  │   └── ferrochain-anthropic  (uses core: BaseChatModel + anthropic-sdk)
  ├── ferrochain-ollama-sdk     (NO ferrochain-core dep) [D17-Q5]
  │   └── ferrochain-ollama     (uses core: BaseChatModel + ollama-sdk)
  │
  ├── ferrochain-standard-tests (dev-deps on each adapter crate + core)
  │
  └── ferrochain-mcp            (uses core: Tool, Runnable; optional dep on providers)
```

## Edge Table

| From | To | Kind | Rationale |
|------|----|------|-----------|
| ferrochain-graph | ferrochain-core | runtime | Runnable, Message, ContentBlock, FerrochainError |
| ferrochain-graph | ferrochain-sandbox | runtime | Tool execution dispatch (via trait object) |
| ferrochain-checkpoint | ferrochain-core | runtime | CheckpointSaver, FerrochainError |
| ferrochain-server | ferrochain-graph | runtime | Runs invoke the graph engine |
| ferrochain-server | ferrochain-checkpoint | runtime | Threads/runs read/write checkpoints |
| ferrochain-memory | ferrochain-core | runtime | FerrochainError; MemoryStore trait definition |
| ferrochain-openai-sdk | (none) | — | Standalone: reqwest + serde only; no ferrochain-core [D17-Q5] |
| ferrochain-openai | ferrochain-core | runtime | BaseChatModel + FerrochainError |
| ferrochain-openai | ferrochain-openai-sdk | runtime | Wire client for SDK adapter pattern |
| ferrochain-anthropic-sdk | (none) | — | Standalone; no ferrochain-core dep |
| ferrochain-anthropic | ferrochain-core | runtime | BaseChatModel + FerrochainError |
| ferrochain-anthropic | ferrochain-anthropic-sdk | runtime | Wire client |
| ferrochain-ollama-sdk | (none) | — | Standalone; no ferrochain-core dep |
| ferrochain-ollama | ferrochain-core | runtime | BaseChatModel + FerrochainError |
| ferrochain-ollama | ferrochain-ollama-sdk | runtime | Wire client |
| ferrochain-standard-tests | ferrochain-openai | dev | Conformance test harness |
| ferrochain-standard-tests | ferrochain-anthropic | dev | Conformance test harness |
| ferrochain-standard-tests | ferrochain-ollama | dev | Conformance test harness |
| ferrochain-standard-tests | ferrochain-core | dev | Test trait surface |
| ferrochain-mcp | ferrochain-core | runtime | Tool, Runnable, FerrochainError |
| ferrochain-splitters | ferrochain-core | runtime | FerrochainError for Result |
| ferrochain-macros | (none) | — | Proc-macro crate; no ferrochain-core dep at compile time |

## Cross-Cutting Dependencies (Shared by All Crates)

| Crate | Role |
|-------|------|
| `tokio` | Async runtime (all crates) |
| `serde` + `serde_json` | Serialization (all crates) |
| `rmp-serde` / `msgpack` | Checkpoint wire format (ferrochain-checkpoint; ADR-002) |
| `reqwest` | HTTP client (provider crates + ferrochain-mcp; DI-009 timeout mandatory) |
| `axum` | HTTP server (ferrochain-server only) |
| `tracing` | Structured logging (all crates) |
| `kani` | Formal verification harnesses (ferrochain-graph, ferrochain-checkpoint, ferrochain-sandbox; dev-dep) |
| `proptest` | Property tests (ferrochain-graph, ferrochain-checkpoint; dev-dep) |

## Topological Build Order (Wave 1 → Wave 2)

```
Wave 1:
  1. ferrochain-macros           (proc-macro crate; no internal deps)
  2. ferrochain-core             (foundation; depends on macros for re-export)
  3. ferrochain-splitters        (parallel; depends only on core)
  4. ferrochain-sandbox          (parallel; depends only on core)
  5. ferrochain-checkpoint       (depends on core)
  6. ferrochain-graph            (depends on core + sandbox)
  7. ferrochain-server           (depends on graph + checkpoint)

Wave 2:
  8.  ferrochain-openai-sdk      (standalone; no ferrochain-core dep) [D17-Q5]
  9.  ferrochain-anthropic-sdk   (standalone) [D17-Q5]
  10. ferrochain-ollama-sdk      (standalone) [D17-Q5]
  11. ferrochain-openai          (depends on core + openai-sdk)
  12. ferrochain-anthropic       (depends on core + anthropic-sdk)
  13. ferrochain-ollama          (depends on core + ollama-sdk)
  14. ferrochain-memory          (depends on core; MemoryStore trait)
  15. ferrochain-standard-tests  (depends on core + all adapter crates)
  16. ferrochain-mcp             (depends on core + optional providers)
```

**Note:** ferrochain-graph depends on ferrochain-sandbox for tool dispatch. However,
sandbox is in the same Wave 1 build. The dependency is via a trait object
(`dyn SandboxBackend`), enabling ferrochain-sandbox to compile independently before
ferrochain-graph binds it.

## Invariant: No Circular Dependencies

The crate DAG is strictly acyclic. Enforced by Cargo's compiler. Any proposal to add an
edge that would create a cycle requires an ADR and architectural review. Key cycles to
prevent:

- ferrochain-core MUST NOT depend on any other ferrochain crate
- ferrochain-checkpoint MUST NOT depend on ferrochain-graph (graph depends on checkpoint, not vice versa)
- Provider crates MUST NOT depend on each other

## Feature Flag Interaction

Cargo features create conditional dependencies:
- `checkpoint-sqlite` (default): `ferrochain-checkpoint` + `rusqlite`
- `checkpoint-postgres`: + `tokio-postgres`
- `checkpoint-memory`: no additional dep
- `sandbox-wasm` (default): `ferrochain-sandbox` + `wasmtime`
- `sandbox-container`: + Docker API client
- `server`: `ferrochain-server` included in workspace binary builds

See ADR-007 for full feature interaction rules.
