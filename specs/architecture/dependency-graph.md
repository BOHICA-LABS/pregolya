---
document_type: architecture-section
level: L3
section: dependency-graph
version: "1.0"
status: draft
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/specs/prd.md
input-hash: "6eb975297dd3c4dc"
traces_to: ARCH-INDEX.md
decisions: [D4, D6, D7]
---

# Dependency Graph: ferrochain

> All edges are uni-directional. No cycles are permitted (P-06).
> External crates (tokio, axum, reqwest, serde, etc.) omitted for clarity.

## Crate DAG

```
ferrochain-core
  ├── ferrochain-graph          (uses core: Runnable, Message, FerrochainError)
  │   └── ferrochain-checkpoint (uses core: CheckpointSaver, FerrochainError)
  │       └── ferrochain-server (uses graph + checkpoint: runs + threads + cron)
  │
  ├── ferrochain-splitters      (uses core: FerrochainError only; isolated)
  │
  ├── ferrochain-sandbox        (uses core: FerrochainError; ferrochain-graph uses sandbox)
  │   [ferrochain-graph → ferrochain-sandbox for tool dispatch]
  │
  ├── ferrochain-openai         (uses core: BaseChatModel, Runnable, FerrochainError)
  ├── ferrochain-anthropic      (uses core: same surface as openai)
  ├── ferrochain-ollama         (uses core: same surface as openai)
  │
  ├── ferrochain-standard-tests (dev-deps on each provider crate + core)
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
| ferrochain-openai | ferrochain-core | runtime | BaseChatModel + FerrochainError |
| ferrochain-anthropic | ferrochain-core | runtime | Same as openai |
| ferrochain-ollama | ferrochain-core | runtime | Same as openai |
| ferrochain-standard-tests | ferrochain-openai | dev | Conformance test harness |
| ferrochain-standard-tests | ferrochain-anthropic | dev | Conformance test harness |
| ferrochain-standard-tests | ferrochain-ollama | dev | Conformance test harness |
| ferrochain-standard-tests | ferrochain-core | dev | Test trait surface |
| ferrochain-mcp | ferrochain-core | runtime | Tool, Runnable, FerrochainError |
| ferrochain-splitters | ferrochain-core | runtime | FerrochainError for Result |

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
  1. ferrochain-core             (foundation; no internal deps)
  2. ferrochain-splitters        (parallel; depends only on core)
  3. ferrochain-sandbox          (parallel; depends only on core)
  4. ferrochain-checkpoint       (depends on core)
  5. ferrochain-graph            (depends on core + sandbox)
  6. ferrochain-server           (depends on graph + checkpoint)

Wave 2:
  7. ferrochain-openai           (depends only on core)
  8. ferrochain-anthropic        (depends only on core)
  9. ferrochain-ollama           (depends only on core)
  10. ferrochain-standard-tests  (depends on core + all providers)
  11. ferrochain-mcp             (depends on core + optional providers)
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
