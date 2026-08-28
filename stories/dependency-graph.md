---
document_type: dependency-graph
version: "1.3"
status: active
producer: story-writer
timestamp: 2026-08-27T00:00:00Z
phase: 2
traces_to: .factory/stories/STORY-INDEX.md
---

# Dependency Graph — pregolya Phase 2

> **Acyclicity validation:** Topological sort completed. Graph is a DAG.
> No story has a circular dependency.

## Inter-Story Dependency DAG

> Format: `STORY-ID: depends_on [IDs] -> blocks [downstream IDs]`
> Dependencies are implementation-order requirements (the depended-on story's
> artifacts must exist before the dependent story can be implemented).

### Wave 1 — pregolya-core (E-01)

```
S-1.01 (PregolyaError)
  depends_on: []
  blocks: S-1.02, S-1.03, S-1.08, S-1.09, S-1.14

S-1.02 (Error Policy)
  depends_on: [S-1.01]
  blocks: S-1.04, S-1.06, S-1.09, S-1.10, S-1.12, S-2.01, S-2.04, S-2.09

S-1.03 (Message Types)
  depends_on: [S-1.01]
  blocks: S-1.04

S-1.04 (Runnable Trait)
  depends_on: [S-1.03, S-1.02]
  blocks: S-1.05, S-1.06, S-1.07, S-1.10, S-1.12, S-1.13, S-1.14,
          S-1.17, S-1.18, S-1.19, S-1.21, S-1.26, S-2.01, S-2.02,
          S-2.03, S-2.04, S-2.06, S-2.10

S-1.05 (LCEL)
  depends_on: [S-1.04]
  blocks: S-6.01

S-1.06 (Retry/Circuit Breaker)
  depends_on: [S-1.04, S-1.02]
  blocks: S-1.22, S-2.07
```

### Wave 1 — pregolya-macros (E-02)

```
S-1.07 (#[tool], #[entrypoint], #[task] macros)
  depends_on: [S-1.04]
  blocks: S-1.21, S-2.07
```

### Wave 1 — Independent crates (E-03, E-04, E-05, E-06)

```
S-1.08 (Recursive Splitter)
  depends_on: [S-1.01]
  blocks: [none in v1 stories]

S-1.09 (Sandbox)
  depends_on: [S-1.01, S-1.02]
  blocks: S-1.21, S-1.22, S-6.01

S-1.10 (Checkpoint Core)
  depends_on: [S-1.04, S-1.02]
  blocks: S-1.11, S-1.16, S-1.18, S-1.20, S-1.25, S-1.26, S-6.01

S-1.11 (FTS Search)
  depends_on: [S-1.10]
  blocks: [none in v1 stories]

S-1.12 (Memory Persistence)
  depends_on: [S-1.04, S-1.02]
  blocks: S-1.13

S-1.13 (SkillStore/WriteGuard)
  depends_on: [S-1.12, S-1.04, S-1.14, S-1.17]
  blocks: S-1.16
```

### Wave 1 — pregolya-graph (E-07 through E-12)

```
S-1.14 (StateGraph Nodes + Channels)
  depends_on: [S-1.04, S-1.01]
  blocks: S-1.13, S-1.15, S-1.16, S-1.17, S-1.18, S-1.19, S-2.11

S-1.15 (Conditional Edges + Send)
  depends_on: [S-1.14]
  blocks: S-1.16, S-1.17

S-1.16 (BSP Engine)
  depends_on: [S-1.14, S-1.15, S-1.10, S-1.13, S-1.17, S-1.18]
  blocks: S-1.20, S-1.26, S-6.01

S-1.17 (Streaming Events)
  depends_on: [S-1.14, S-1.04, S-1.15]
  blocks: S-1.13, S-1.16, S-1.18, S-1.20, S-1.23, S-1.24

S-1.18 (Budget/EvidenceJournal)
  depends_on: [S-1.14, S-1.04, S-1.10, S-1.17]
  blocks: S-1.16, S-1.24, S-1.25

S-1.19 (GuardrailHook)
  depends_on: [S-1.14, S-1.04]
  blocks: S-2.02, S-2.10

S-1.20 (HITL Core)
  depends_on: [S-1.16, S-1.17, S-1.10]
  blocks: S-1.23

S-1.23 (PreToolCallHook)
  depends_on: [S-1.20, S-1.17]
  blocks: S-1.24, S-6.01

S-1.24 (Approval + Compaction Events)
  depends_on: [S-1.23, S-1.17, S-1.18]
  blocks: S-1.25

S-1.25 (Compaction Execution)
  depends_on: [S-1.10, S-1.18, S-1.24]
  blocks: S-6.01
```

### Wave 1 — pregolya-tools (E-13)

```
S-1.21 (File System Tools)
  depends_on: [S-1.09, S-1.04, S-1.07]
  blocks: S-1.22

S-1.22 (Bash + Grep Tools)
  depends_on: [S-1.09, S-1.21, S-1.06]
  blocks: S-2.10, S-6.01
```

### Wave 1 — pregolya-server (E-14)

```
S-1.26 (Thread/Assistant/Run CRUD)
  depends_on: [S-1.16, S-1.10, S-1.04]
  blocks: S-1.27

S-1.27 (CronSchedule + SecurityConfig)
  depends_on: [S-1.26]
  blocks: [none in v1 stories]
```

### Wave 2 — pregolya-core D21 additions (E-15, E-16)

```
S-2.01 (LC Serialization)
  depends_on: [S-1.04, S-1.02]
  blocks: S-6.01

S-2.02 (Retriever Trait)
  depends_on: [S-1.19, S-1.04]
  blocks: S-2.03
```

### Wave 2 — pregolya-vectorstores (E-17)

```
S-2.03 (VectorStore Trait + InMemoryVectorStore)
  depends_on: [S-2.02, S-1.04, S-2.09]
  blocks: S-6.01
```

### Wave 2 — pregolya-prompts (E-18)

```
S-2.04 (Prompt Templates Core)
  depends_on: [S-1.04, S-1.02]
  blocks: S-2.05

S-2.05 (Injection Safety Guard)
  depends_on: [S-2.04]
  blocks: S-6.01
```

### Wave 2 — Provider crates (E-19, E-20)

```
S-2.06 (Provider SDK Split Architecture)
  depends_on: [S-1.04]
  blocks: S-2.07, S-2.09

S-2.07 (Chat Model Core Conformance)
  depends_on: [S-2.06, S-1.07, S-1.06]
  blocks: S-2.08

S-2.08 (Advanced Provider Features)
  depends_on: [S-2.07]
  blocks: [none in v1 stories]

S-2.09 (Embeddings Trait + Providers)
  depends_on: [S-2.06, S-1.02]
  blocks: S-2.03, S-6.01
```

### Wave 2 — pregolya-mcp (E-21)

```
S-2.10 (MCP Client)
  depends_on: [S-1.19, S-1.04, S-1.22]
  blocks: S-2.11

S-2.11 (MCP Server)
  depends_on: [S-2.10, S-1.14]
  blocks: [none in v1 stories]
```

### Crate-Level Dependency Edges

> Runtime crate dependencies introduced by story decisions that add cross-crate build edges.
> Source-of-truth is the workspace `Cargo.toml` members list; this section tracks edge rationale.

| From Crate | To Crate | Rationale | ADR / BC Source |
|-----------|----------|-----------|----------------|
| `pregolya-mcp` | `pregolya-graph` | `GraphAgentTool` wraps `Arc<CompiledStateGraph>` (non-generic; `from_graph` is a non-generic constructor) — introduced by BC-2.09.008 and formalized in ADR-029 §Consequences. The `mcp::graph_tool` module depends on `CompiledStateGraph` and `GraphRunner` types from `pregolya-graph`. | ADR-029 §Consequences, BC-2.02.001 {PC-001}, BC-2.09.008 {PC-001} |

> **DAG-acyclicity confirmation:** Adding `pregolya-mcp → pregolya-graph` does not create a
> cycle. `pregolya-graph` has no dependency on `pregolya-mcp` (one-directional). At the story
> level, S-1.14 (Wave 1 batch 1d) is upstream of S-2.11 (Wave 2 batch 2d) — no cycle.
> Topological sort assertion continues to hold: Graph is a DAG.

### Wave 6 — Formal Verification (E-22)

```
S-6.01 (Kani + cargo-fuzz)
  depends_on: [S-1.16, S-1.10, S-1.09, S-2.01, S-2.03, S-1.23, S-1.25, S-1.05, S-2.09, S-2.05, S-1.22]
  blocks: [none — terminal node]
```

## Topological Sort (Wave Execution Order)

> Stories in the same batch have no inter-story dependencies and can be
> dispatched in parallel to separate implementer agents.

### Wave 1 — Topological Batches

| Batch | Stories | Rationale |
|-------|---------|-----------|
| 1a | S-1.01 | Root: no dependencies |
| 1b | S-1.02, S-1.03, S-1.08 | All depend only on S-1.01 |
| 1c | S-1.04, S-1.09 | S-1.04 dep S-1.02+S-1.03 (1b); S-1.09 dep S-1.01+S-1.02 (1a+1b) |
| 1d | S-1.05, S-1.06, S-1.07, S-1.10, S-1.12, S-1.14 | All deps satisfied by 1a–1c; none depend on each other |
| 1e | S-1.11, S-1.15, S-1.19, S-1.21 | All deps in 1a–1d; none depend on each other; S-1.13/S-1.17/S-1.18 removed — see 1f/1g |
| 1f | S-1.17, S-1.22 | S-1.17 dep S-1.15 (1e)+S-1.14+S-1.04 (1d); S-1.22 dep S-1.21 (1e)+S-1.06 (1d); no intra-batch edges |
| 1g | S-1.13, S-1.18 | S-1.13 dep S-1.17 (1f)+S-1.12+S-1.14 (1d); S-1.18 dep S-1.17 (1f)+S-1.14+S-1.10 (1d); concurrent — disjoint scheduler.rs regions per coordination note |
| 1h | S-1.16 | Dep S-1.13+S-1.18 (1g)+S-1.17 (1f)+S-1.15 (1e)+S-1.14+S-1.10 (1d) |
| 1i | S-1.20, S-1.26 | S-1.20 dep S-1.16 (1h)+S-1.17 (1f)+S-1.10 (1d); S-1.26 dep S-1.16 (1h)+S-1.10 (1d) |
| 1j | S-1.23, S-1.27 | S-1.23 dep S-1.20 (1i)+S-1.17 (1f); S-1.27 dep S-1.26 (1i) |
| 1k | S-1.24 | Dep S-1.23 (1j)+S-1.17 (1f)+S-1.18 (1g) |
| 1l | S-1.25 | Dep S-1.10 (1d)+S-1.18 (1g)+S-1.24 (1k) |

### Wave 2 — Topological Batches

| Batch | Stories | Rationale |
|-------|---------|-----------|
| 2a | S-2.01, S-2.04, S-2.06 | S-2.01 dep S-1.04+S-1.02; S-2.04 dep S-1.04+S-1.02; S-2.06 dep S-1.04 |
| 2b | S-2.02, S-2.05, S-2.07, S-2.09 | S-2.02 dep S-1.19+S-1.04; S-2.05 dep S-2.04; S-2.07 dep S-2.06+S-1.07+S-1.06; S-2.09 dep S-2.06+S-1.02 |
| 2c | S-2.03, S-2.08, S-2.10 | S-2.03 dep S-2.02+S-1.04+S-2.09; S-2.08 dep S-2.07; S-2.10 dep S-1.19+S-1.04+S-1.22 |
| 2d | S-2.11 | Dep S-2.10 (binding, 2c) + S-1.14 (Wave-1 dep; satisfied before Wave 2 begins) |

### Wave 6

| Batch | Stories | Rationale |
|-------|---------|-----------|
| 6a | S-6.01 | Terminal node; all Wave 1+2 merged |

---

## Traceability Matrices

### BC to Stories Matrix (abbreviated — full map in STORY-INDEX.md)

> Full coverage: 134 BCs, 39 stories, 0 gaps.

| Subsystem | BC Range | Stories | Coverage |
|-----------|----------|---------|---------|
| SS-01 Core Primitives | BC-2.01.001–008 | S-1.03, S-1.04, S-1.05 | Full |
| SS-02 StateGraph | BC-2.02.001–006 | S-1.14, S-1.15 | Full |
| SS-03 BSP Engine | BC-2.03.001–003 | S-1.16 | Full |
| SS-04 Checkpoint | BC-2.04.001–008 | S-1.10, S-1.11 | Full |
| SS-05 HITL | BC-2.05.001–008 | S-1.20, S-1.23 | Full |
| SS-06 Streaming | BC-2.06.001–006 | S-1.17, S-1.24 | Full |
| SS-07 Splitters | BC-2.07.001–003 | S-1.08 | Full |
| SS-08 Providers | BC-2.08.001–014 | S-1.07, S-2.06, S-2.07, S-2.08 | Full |
| SS-09 MCP | BC-2.09.001–008 | S-2.10, S-2.11 | Full |
| SS-10 Budget | BC-2.10.001–006 | S-1.18, S-1.25 | Full |
| SS-11 Guardrail | BC-2.11.001–006 | S-1.19 | Full |
| SS-12 Server | BC-2.12.001–007 | S-1.26, S-1.27 | Full |
| SS-13 Sandbox | BC-2.13.001–007 | S-1.09 | Full |
| SS-14 Error Taxonomy | BC-2.14.001–006 | S-1.01, S-1.02 | Full |
| SS-15 Memory | BC-2.15.001–006 | S-1.12, S-1.13 | Full |
| SS-16 Retry | BC-2.16.001–003 | S-1.06 | Full |
| SS-17 Formal Verification | BC-2.17.001–002 | S-6.01 | Full |
| SS-18 Prompts | BC-2.18.001–005 | S-2.04, S-2.05 | Full |
| SS-19 LC Serialization | BC-2.19.001–006 | S-2.01 | Full |
| SS-20 Retrieval | BC-2.20.001–003 | S-2.02 (BC-2.20.001–002), S-2.03 (BC-2.20.003) | Full |
| SS-21 VectorStore | BC-2.21.001–004 | S-2.03 | Full |
| SS-22 Embeddings | BC-2.22.001–003 | S-2.09 | Full |
| SS-23 Tools | BC-2.23.001–006 | S-1.21, S-1.22 | Full |

### VP to Stories Matrix

| VP | BC Anchor | Type | Phase | Priority | Anchor Story | Additional Stories |
|----|-----------|------|-------|---------|-------------|-------------------|
| VP-001 | BC-2.03.001 | Kani | 6 | P0 | S-1.16 | S-6.01 |
| VP-002 | BC-2.04.006 | Kani | 6 | P0 | S-1.10 | S-6.01 |
| VP-003 | BC-2.13.004 | Kani | 6 | P0 | S-1.09 | S-6.01 |
| VP-004 | BC-2.09.004 | integration | 3 | P1 | S-2.10 | — |
| VP-005 | BC-2.09.005 | integration | 3 | P1 | S-2.10 | — |
| VP-006 | BC-2.18.004 | Kani | 6 | P1 | S-2.05 | S-6.01 |
| VP-007 | BC-2.19.001 | proptest | 3 | P1 | S-2.01 | S-6.01 |
| VP-008 | BC-2.22.001 | proptest | 3 | P1 | S-2.09 | S-6.01 |
| VP-009 | BC-2.21.003 | Kani | 6 | P0 | S-2.03 | S-6.01 |
| VP-010 | BC-2.19.005 | Kani | 6 | P0 | S-2.01 | S-6.01 |
| VP-011 | BC-2.05.007 | Kani | 6 | P0 | S-1.23 | S-6.01 |
| VP-012 | BC-2.10.005 | Kani | 6 | P1 | S-1.25 | S-6.01 |
| VP-013 | BC-2.23.005 | Kani | 6 | P1 | S-1.22 | S-6.01 |
| VP-014 | BC-2.01.005 + BC-2.01.006 | proptest | 3 | P1 | S-1.05 | S-6.01 |
| VP-015 | BC-2.09.007 | unit | 3 | P1 | S-2.11 | — |
| VP-016 | BC-2.09.008 | proptest | 3 | P1 | S-2.11 | — |
| VP-006-B | BC-2.18.004 | proptest | 3 | P1 | S-2.05 | S-6.01 |

### NFR to Stories Matrix

> NFR catalog defined at `.factory/specs/prd-supplements/nfr-catalog.md`.
> The following NFR to story mappings use NFR identifiers from that catalog.
> Stories are not gated on NFR verification at Phase 2; NFR validation occurs in
> Phase 3 (per-story) and Phase 6 (formal hardening).

| NFR Category | Stories Implementing It | Validation Method |
|-------------|------------------------|-------------------|
| NFR: No unwrap in non-test code (production-grade default) | All Wave 1+2 stories | cargo clippy -D clippy::unwrap_used |
| NFR: reqwest rustls-tls mandatory | S-1.02, S-2.07, S-2.08, S-2.09 | cargo deny + CI |
| NFR: 30s HTTP timeout default | S-1.02, S-2.07, S-2.09 | Adversarial review per SAP |
| NFR: Redacted Debug for credentials | S-1.02, S-2.07, S-2.09 | Adversarial review |
| NFR: Non-exhaustive on public API types | All stories with new public types | compile-fail test gates |
| NFR: No println! in library crates | All crate stories | cargo clippy |
| NFR: 500 code-lines soft / 750 hard per file | All stories | cargo xtask check-file-size |
| NFR: Tokio multi-threaded async runtime | S-1.10, S-1.16, S-1.26, S-2.07, S-2.09, S-2.10 | runtime config in tests |
| NFR: Arc-DI wiring per constructor | S-1.14, S-1.18, S-1.19, S-1.20, S-2.02, S-2.03 | adversary fresh-context review |
| NFR: Structured tracing events + catalog row | All stories emitting events | SAP-1 adversary standing probe |

---

## BC Clause Coverage Matrix

> Abbreviated to Red Gate BCs and VP-anchored BCs. Full per-clause coverage
> is established at the story spec authoring stage (subsequent bursts).
> GAP-001 through GAP-003 represent intentionally-deferred P2 and Phase 6 items.

| BC | Key Clauses | Covering Story | AC Gap |
|----|-------------|---------------|--------|
| BC-2.02.003 | NamedBarrierValue missing-writer boundary (RG) | S-1.14 | Covered; RG test required |
| BC-2.02.004 | EphemeralValue cleared-after-super-step (RG) | S-1.14 | Covered; RG test required |
| BC-2.03.001 | BSP determinism (VP-001 Kani P0) | S-1.16 | Covered; Kani harness in S-6.01 |
| BC-2.04.006 | Session triple-address uniqueness (VP-002 Kani P0) | S-1.10 | Covered; Kani harness in S-6.01 |
| BC-2.07.002 | Non-ASCII boundary parity (RG) | S-1.08 | Covered; RG test required |
| BC-2.09.004 | MCP bare ToolException re-raise (RG, VP-004) | S-2.10 | Covered; integration test |
| BC-2.09.005 | MultiServerMcpClient no live connections (RG, VP-005) | S-2.10 | Covered; integration test |
| BC-2.13.004 | Workspace confinement (VP-003 Kani P0) | S-1.09 | Covered; Kani harness in S-6.01 |
| BC-2.18.004 | Injection guard fail-closed (RG, VP-006) | S-2.05 | Covered; Kani harness in S-6.01 |
| BC-2.18.005 | SlotTrustPolicy TrustAll construction error (RG) | S-2.05 | Covered; RG test required |
| BC-2.19.005 | Reviver allowlist fail-closed (RG, VP-010 Kani P0) | S-2.01 | Covered; Kani harness in S-6.01 |
| BC-2.20.002 | RAGRetrieval guardrail coverage (RG) | S-2.02 | Covered; RG test required |
| BC-2.21.003 | Zero-norm vector guard (RG, VP-009 Kani P0) | S-2.03 | Covered; Kani harness in S-6.01 |
| BC-2.22.002 | EmbeddingsOpenAI credential opacity + batch failure (RG) | S-2.09 | Covered; RG test required |
| BC-2.19.004 | Legacy namespace remap (P2) | S-2.01 | GAP-001 (P2 — lower priority but v1 in-scope) |

---

## Edge Case Coverage Matrix

> Edge cases are fully enumerated in per-story spec bodies (subsequent bursts).
> Key security-critical edge cases are listed here for early reference.

| Category | Edge Case | Description | Story | Status |
|----------|-----------|-------------|-------|--------|
| Sandbox | Symlink workspace escape | Resolved symlink points outside root | S-1.09 | Covered — BC-2.13.005 |
| Sandbox | macOS Seatbelt + ProcessBackend | Seatbelt profile denied operation | S-1.09 | Covered — BC-2.13.006 |
| Checkpoint | Concurrent put_writes collision | Two tasks write same key in same step | S-1.10 | Covered — BC-2.04.001 |
| BSP | Concurrent LastValue write | Two nodes write same channel in same step | S-1.16 | Covered — BC-2.03.002 |
| HITL | Resume on empty queue | No pending resume values | S-1.20 | Covered — BC-2.05.005 |
| Guardrail | No hook registered | Default pass-through with WARNING | S-1.19 | Covered — BC-2.11.006 |
| Serialization | Unknown type ID in reviver | Type not in OnceLock allowlist | S-2.01 | Covered — BC-2.19.005 |
| Serialization | Langchain monolith namespace | lc_type from python monolith | S-2.01 | Covered — BC-2.19.006 |
| VectorStore | Zero-norm embedding vector | Division by zero in cosine similarity | S-2.03 | Covered — BC-2.21.003 |
| Budget | Ceiling reached mid-run | Budget halt fires during BSP step | S-1.18 | Covered — BC-2.10.003 |
| Provider | Transport error on streaming | Network failure mid-stream | S-2.07 | Covered — BC-2.08.007 |
| MCP | ToolException from MCP server | Raw exception must propagate | S-2.10 | Covered — BC-2.09.004 |

---

## Gap Register

| Gap ID | Level | Source | Item | Justification | Resolution Target |
|--------|-------|--------|------|---------------|------------------|
| GAP-001 | L1 | BC-2.19.004 | P2 legacy namespace remap for OLD_CORE_NAMESPACES_MAPPING | Implemented in S-2.01 at P2 priority — lower urgency than P0/P1 BCs but v1 in-scope; resolution is implementation ordering, not deferral | S-2.01 Wave 2 |
| GAP-002 | L3 | VP-001 through VP-013 (Kani) | Kani harness execution | Harnesses authored in story specs but compiled and verified in S-6.01 (Phase 6); formal verification requires all Wave 1+2 crates compiled first | S-6.01 Wave 6 |
| GAP-003 | L3 | VP-004, VP-005 (integration) | MCP integration test against live server | Integration tests require MCP server running; exercised via in-process DTU-style mock server in S-2.10/2.11 unit tests; live-server tests tagged #[ignore] pending provisioned test environment per SID-1 | S-2.10, S-2.11 |

---

## Changelog

- **1.3 (GAP-01-nongeneric/round-10/2026-08-27):** Crate-Level Dependency Edges live row updated to round-10 non-generic design: `Arc<CompiledGraph<S>>` → `Arc<CompiledStateGraph>`; `from_graph<S>` generic constructor clause removed (`from_graph` is now a non-generic constructor per ADR-029 §Symbol Grounding / BC-2.02.001 {PC-001}); `CompiledGraph<S>` type reference → `CompiledStateGraph`; ADR source updated to ADR-029 §Consequences, BC-2.02.001 {PC-001}, BC-2.09.008 {PC-001}. Historical §Changelog rows preserved as records.
- **1.2 (F-P2A066-02/round-7/2026-08-26):** Crate-Level Dependency Edges: `GraphAgentTool<S>` → `GraphAgentTool` (struct is non-generic; `from_graph<S>` constructor and `Arc<CompiledGraph<S>>` remain generic per ADR-029 §Decision); clarification note added.
- **1.1 (F1/round-5/2026-08-26):** (a) BC count updated 133 → 134 to reflect BC-2.09.008 addition. (b) SS-09 BC range updated BC-2.09.001–007 → BC-2.09.001–008. (c) VP-to-Stories Matrix extended: VP-015 (BC-2.09.007 / unit / S-2.11), VP-016 (BC-2.09.008 / proptest / S-2.11), VP-006-B (BC-2.18.004 / Kani / S-2.05) added. (d) Crate-Level Dependency Edges section added: `pregolya-mcp → pregolya-graph` (ADR-029 / BC-2.09.008 PC-001; GraphAgentTool wraps Arc<CompiledGraph<S>>). S-1.14 added as upstream of S-2.11 (S-2.11 depends_on updated to [S-2.10, S-1.14]; S-1.14 blocks updated to include S-2.11). Topological sort batch 2d rationale updated; DAG-acyclicity confirmed (S-1.14 Wave-1 upstream of S-2.11 Wave-2 — no cycle).
