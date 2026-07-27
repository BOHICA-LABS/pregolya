---
document_type: architecture-section
level: L3
section: dependency-graph
version: "1.6"
status: active
producer: architect
timestamp: 2026-07-26T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd-supplements/module-criticality.md
  - .factory/specs/prd.md
  - .factory/specs/module-criticality.md
input-hash: "pending-FIX-BURST-275"
traces_to: ARCH-INDEX.md
decisions: [D4, D6, D7, D21, D23]
changelog:
  - "1.6 (FIX-BURST-275/F-P172b-07+08+16+17/2026-07-26): F-P172b-07 — add missing Edge Table row `ferrochain-graph → ferrochain-checkpoint` (runtime; graph::budget builds ConversationSnapshot via CheckpointSaver::search_history per BC-2.04.008 compaction engine; this edge exists in the Crate DAG nesting but was absent from Edge Table). F-P172b-07 sibling sweep (TD-VSDD-060) — 3-way DAG↔Edge-Table↔Build-Order diff complete: no other missing edges found; all DAG visual nesting edges verified against Edge Table; Build Order Wave 1 position ordering validates (ferrochain-graph at position 8 after ferrochain-checkpoint at position 5 is correct given this new runtime edge). F-P172b-16 — add `ferrochain` facade crate (#1 per ARCH-INDEX Canonical Crate Roster) everywhere it was absent: Crate DAG (terminal re-export node after all impl crates), Edge Table (one row listing all 14 impl crate dependencies), Build Order position 20. F-P172b-17 — fix Crate DAG ferrochain-checkpoint annotation: remove 'uses core: CheckpointSaver' (CheckpointSaver is DEFINED in ferrochain-checkpoint::checkpoint::saver, not imported from core); correct to 'uses core: FerrochainError'. TD-VSDD-060 sibling sweep: Edge Table ferrochain-checkpoint row rationale also corrected (CheckpointSaver removed, FerrochainError only). F-P172b-08 — update Cross-Cutting Dependencies Kani row from 3 crates to 7 crates (add ferrochain-vectorstores, ferrochain-core, ferrochain-prompts, ferrochain-tools per VP catalog expansion in D21/D23); update proptest row to add ferrochain-splitters, ferrochain-core, ferrochain-memory (proptest P1 obligations VP-007/VP-008 + memory write-guard invariants require proptest in those crates). OBS-P172b-A — add `specs/module-criticality.md` to inputs."
  - "1.5 (FIX-BURST-273/F-P171a-06/2026-07-25): Add two missing Edge Table rows: (1) ferrochain-tools → ferrochain-macros (build; #[tool] proc-macro used directly in ferrochain-tools implementations per ADR-020 Decision 1 / ADR-008); (2) ferrochain-core → ferrochain-macros (build; re-exports proc-macro items from ferrochain-macros per ADR-008 Decision 2). The Crate DAG annotation and Topological Build Order already documented both edges; the Edge Table was inconsistent. Amend §Invariant: 'ferrochain-core MUST NOT depend on any other ferrochain crate' to add the proc-macro exception (build-time only, no runtime circular dependency)."
  - "1.4 (FIX-BURST-272/F-P170-06/2026-07-25): ActionRisk dependency adjudication propagation. Crate DAG: update ferrochain-tools annotation — ActionRisk is now sourced from ferrochain-core (core::action_risk), not ferrochain-graph; annotation rewritten to reflect this. Edge Table: update ferrochain-tools→ferrochain-core rationale to include ActionRisk."
  - "1.3 (FIX-BURST-267/F-P165-04/2026-07-25): Remove spurious DI-012 anchor from §[Section Content] intro sentence — DI-012 is 'Guardrail Coverage at Ingress Boundaries' (unrelated to graph acyclicity). Correct cite to P-06 alone (system-overview §Architecture Principles). DI-NNN sweep: only remaining DI cite is DI-009 at reqwest row in Cross-Cutting Dependencies table, which correctly anchors the outbound HTTP timeout invariant."
  - "1.2 (FIX-BURST-265/F-P163-03/2026-07-25): Propagate D21+D23 21-crate roster. Crate DAG: add ferrochain-prompts (D21/ADR-015), ferrochain-vectorstores (D21/ADR-014), ferrochain-tools (D23/ADR-020) after ferrochain-memory. Edge Table: 4 new rows (prompts→core, vectorstores→core, tools→core, tools→sandbox). Topological Build Order: Wave 1 gains ferrochain-memory (D23 Wave 2→1, position 6) + ferrochain-tools (position 7), now 9 items; Wave 2 loses ferrochain-memory, gains ferrochain-prompts (position 13) + ferrochain-vectorstores (position 14), now 10 items. Add D21/D23 to decisions list."
  - "1.1 (provenance-fix-169/2026-07-17): hash-currency refresh — prd.md updated to v1.2 in same burst; add [Section Content] template compliance fix. No spec content changes."
  - "1.0 (initial): crate dependency DAG authored."
---

# Dependency Graph: ferrochain

> All edges are uni-directional. No cycles are permitted (P-06).
> External crates (tokio, axum, reqwest, serde, etc.) omitted for clarity.

## [Section Content]

This file documents ferrochain's crate dependency DAG, external integration surfaces, and the acyclicity constraint (P-06). External crates (tokio, axum, reqwest, serde, etc.) are omitted for clarity; only workspace-internal dependency edges are shown.

## Crate DAG

```
ferrochain-core
  ├── ferrochain-macros         (proc-macro crate; re-exported from core)
  │
  ├── ferrochain-graph          (uses core: Runnable, Message, FerrochainError)
  │   ├── ferrochain-checkpoint (uses core: FerrochainError; defines CheckpointSaver internally)
  │   │   └── ferrochain-server (uses graph + checkpoint: runs + threads + cron)
  │   └── [ferrochain-graph → ferrochain-checkpoint: graph::budget uses CheckpointSaver::search_history (BC-2.04.008)]
  │
  ├── ferrochain-splitters      (uses core: FerrochainError only; isolated)
  │
  ├── ferrochain-sandbox        (uses core: FerrochainError; ferrochain-graph uses sandbox)
  │   [ferrochain-graph → ferrochain-sandbox for tool dispatch]
  │
  ├── ferrochain-memory         (uses core: FerrochainError; MemoryStore trait)
  │
  ├── ferrochain-prompts        (uses core: Message, Runnable, FerrochainError; D21/ADR-015)
  │
  ├── ferrochain-vectorstores   (uses core: Document, Retriever, Embeddings, FerrochainError; D21/ADR-014)
  │
  ├── ferrochain-tools          (uses core + sandbox: Tool, ActionRisk, PathGuard, SandboxPolicy; D23/ADR-020)
  │   [depends on ferrochain-core + ferrochain-sandbox + ferrochain-macros; ActionRisk sourced from core::action_risk (relocated per F-P170-06); no ferrochain-graph compile-time dep]
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

ferrochain (facade)             (re-exports public API from all impl crates; terminal node)
  [depends on: ferrochain-core, ferrochain-graph, ferrochain-checkpoint, ferrochain-server,
   ferrochain-splitters, ferrochain-sandbox, ferrochain-memory, ferrochain-prompts,
   ferrochain-vectorstores, ferrochain-tools, ferrochain-openai, ferrochain-anthropic,
   ferrochain-ollama, ferrochain-mcp]
```

## Edge Table

| From | To | Kind | Rationale |
|------|----|------|-----------|
| ferrochain-graph | ferrochain-core | runtime | Runnable, Message, ContentBlock, FerrochainError |
| ferrochain-graph | ferrochain-sandbox | runtime | Tool execution dispatch (via trait object) |
| ferrochain-graph | ferrochain-checkpoint | runtime | graph::budget uses CheckpointSaver::search_history to build ConversationSnapshot for compaction engine (BC-2.04.008 / ADR-019) |
| ferrochain-checkpoint | ferrochain-core | runtime | FerrochainError |
| ferrochain-server | ferrochain-graph | runtime | Runs invoke the graph engine |
| ferrochain-server | ferrochain-checkpoint | runtime | Threads/runs read/write checkpoints |
| ferrochain-memory | ferrochain-core | runtime | FerrochainError; MemoryStore trait definition |
| ferrochain-prompts | ferrochain-core | runtime | Message, Runnable, FerrochainError; template composition (ADR-015 Decision 1) |
| ferrochain-vectorstores | ferrochain-core | runtime | Document, Retriever, Embeddings, FerrochainError (ADR-014 Decision 1) |
| ferrochain-tools | ferrochain-core | runtime | Tool, ToolOutput, FerrochainError, ActionRisk (core::action_risk, relocated from graph::hitl per F-P170-06) (ADR-020 Decision 1) |
| ferrochain-tools | ferrochain-sandbox | runtime | PathGuard, SandboxPolicy, sandbox execution (ADR-020 Decision 1) |
| ferrochain-tools | ferrochain-macros | build | `#[tool]` proc-macro attribute used directly in ferrochain-tools tool implementations; direct Cargo dependency required for proc-macro attribute resolution (ADR-020 Decision 1 / ADR-008 Decision 2) |
| ferrochain-core | ferrochain-macros | build | Re-exports `#[tool]` and related proc-macro items from ferrochain-macros for user-facing API; compile-time only — proc-macro crates do not create runtime circular dependencies (ADR-008 Decision 2) |
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
| `ferrochain` (facade) | ferrochain-core | runtime | Public API re-export: re-exports core trait surface, message types, error types |
| `ferrochain` (facade) | ferrochain-graph | runtime | Public API re-export: StateGraph, CompiledGraph, graph execution |
| `ferrochain` (facade) | ferrochain-checkpoint | runtime | Public API re-export: CheckpointSaver, backend types |
| `ferrochain` (facade) | ferrochain-server | runtime | Public API re-export: Axum server builder, RunConfig |
| `ferrochain` (facade) | ferrochain-splitters | runtime | Public API re-export: RecursiveSplitter, PariTySplitter |
| `ferrochain` (facade) | ferrochain-sandbox | runtime | Public API re-export: SandboxBackend, SandboxPolicy |
| `ferrochain` (facade) | ferrochain-memory | runtime | Public API re-export: MemoryStore, SkillStore |
| `ferrochain` (facade) | ferrochain-prompts | runtime | Public API re-export: PromptTemplate, ChatPromptTemplate, injection_guard |
| `ferrochain` (facade) | ferrochain-vectorstores | runtime | Public API re-export: VectorStore, VectorStoreRetriever |
| `ferrochain` (facade) | ferrochain-tools | runtime | Public API re-export: ReadFileTool, WriteFileTool, BashTool, GrepTool |
| `ferrochain` (facade) | ferrochain-openai | runtime | Public API re-export: ChatOpenAI, EmbeddingsOpenAI |
| `ferrochain` (facade) | ferrochain-anthropic | runtime | Public API re-export: ChatAnthropic |
| `ferrochain` (facade) | ferrochain-ollama | runtime | Public API re-export: ChatOllama, EmbeddingsOllama |
| `ferrochain` (facade) | ferrochain-mcp | runtime | Public API re-export: MultiServerMcpClient, MCP tool adapters |

## Cross-Cutting Dependencies (Shared by All Crates)

| Crate | Role |
|-------|------|
| `tokio` | Async runtime (all crates) |
| `serde` + `serde_json` | Serialization (all crates) |
| `rmp-serde` / `msgpack` | Checkpoint wire format (ferrochain-checkpoint; ADR-002) |
| `reqwest` | HTTP client (provider crates + ferrochain-mcp; DI-009 timeout mandatory) |
| `axum` | HTTP server (ferrochain-server only) |
| `tracing` | Structured logging (all crates) |
| `kani` | Formal verification harnesses (ferrochain-graph [VP-001/VP-011], ferrochain-checkpoint [VP-002], ferrochain-sandbox [VP-003], ferrochain-vectorstores [VP-009], ferrochain-core [VP-010/VP-012], ferrochain-prompts [VP-006], ferrochain-tools [VP-013]; dev-dep in all 7) |
| `proptest` | Property tests (ferrochain-graph [reducers/clock], ferrochain-checkpoint [clock/backends], ferrochain-splitters [boundary invariants], ferrochain-core [VP-007 LcSerializable round-trip, VP-008 dimensionality contract], ferrochain-memory [write-guard invariants]; dev-dep) |

## Topological Build Order (Wave 1 → Wave 2)

```
Wave 1:
  1. ferrochain-macros           (proc-macro crate; no internal deps)
  2. ferrochain-core             (foundation; depends on macros for re-export)
  3. ferrochain-splitters        (parallel; depends only on core)
  4. ferrochain-sandbox          (parallel; depends only on core)
  5. ferrochain-checkpoint       (depends on core)
  6. ferrochain-memory           (parallel; depends only on core; promoted Wave 2→1 per D23 item 3)
  7. ferrochain-tools            (depends on core + sandbox; D23/ADR-020)
  8. ferrochain-graph            (depends on core + sandbox)
  9. ferrochain-server           (depends on graph + checkpoint)

Wave 2:
  10. ferrochain-openai-sdk      (standalone; no ferrochain-core dep) [D17-Q5]
  11. ferrochain-anthropic-sdk   (standalone) [D17-Q5]
  12. ferrochain-ollama-sdk      (standalone) [D17-Q5]
  13. ferrochain-prompts         (depends on core; D21/ADR-015)
  14. ferrochain-vectorstores    (depends on core; D21/ADR-014)
  15. ferrochain-openai          (depends on core + openai-sdk)
  16. ferrochain-anthropic       (depends on core + anthropic-sdk)
  17. ferrochain-ollama          (depends on core + ollama-sdk)
  18. ferrochain-standard-tests  (depends on core + all adapter crates)
  19. ferrochain-mcp             (depends on core + optional providers)
  20. ferrochain (facade)        (re-exports all impl crates; terminal node; depends on all above)
```

**Note:** ferrochain-graph depends on ferrochain-sandbox for tool dispatch. However,
sandbox is in the same Wave 1 build. The dependency is via a trait object
(`dyn SandboxBackend`), enabling ferrochain-sandbox to compile independently before
ferrochain-graph binds it. ferrochain-tools also depends on ferrochain-sandbox
(ADR-020 Decision 1) and builds after sandbox (position 7 after position 4).

## Invariant: No Circular Dependencies

The crate DAG is strictly acyclic. Enforced by Cargo's compiler. Any proposal to add an
edge that would create a cycle requires an ADR and architectural review. Key cycles to
prevent:

- ferrochain-core MUST NOT depend on any other ferrochain crate. Exception: `ferrochain-macros` is a `proc-macro = true` crate; its compilation model is compile-time only (it produces no runtime code in dependents) and does not create circular runtime dependencies. Build order: ferrochain-macros(1) → ferrochain-core(2) (ADR-008 Decision 2).
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
