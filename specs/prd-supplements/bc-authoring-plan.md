---
document_type: prd-supplement-bc-authoring-plan
level: L3
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/STATE.md
input-hash: "6fed331325c7bdfc4085b45c54e92aabc9255643d861ef286bdd1eed30c89055"
traces_to: prd.md
total_bcs: 86
total_batches: 13
p0_count: 48
p1_count: 30
p2_count: 8
subsystem_note: "All BCs carry subsystem: SS-TBD until architect assigns ARCH-INDEX SS-NN IDs in Phase 1b"
---

# BC Authoring Plan: ferrochain

> This plan enumerates every BC-S.SS.NNN to be authored, organized into
> batches of ≤8 BCs each for sequential sub-bursts. Each batch is one sub-burst.
> BC files go to `.factory/specs/behavioral-contracts/ss-NN/BC-S.SS.NNN.md`
> using the SS-NN ID from ARCH-INDEX Subsystem Registry (assigned Phase 1 Step D, 2026-07-14).

## Summary

| Metric | Value |
|--------|-------|
| Total BCs | 86 |
| P0 (must-have) | 48 |
| P1 (should-have) | 30 |
| P2 (nice-to-have) | 8 |
| Batches | 13 |
| BCs per batch (max) | 8 |
| Subsystems covered | 17 (SS.01–SS.17, mapping CAP-001–CAP-019) |

## Subsystem → CAP Mapping

| Subsection | CAP(s) | Crate | Priority |
|-----------|--------|-------|----------|
| SS.01 | CAP-001, CAP-002 | ferrochain-core | P0 |
| SS.02 | CAP-003 | ferrochain-graph | P0 |
| SS.03 | CAP-004 | ferrochain-graph | P0 |
| SS.04 | CAP-005 | ferrochain-checkpoint | P0 |
| SS.05 | CAP-006 | ferrochain-graph | P0 |
| SS.06 | CAP-007 | ferrochain-graph | P0 |
| SS.07 | CAP-008 | ferrochain-splitters | P0 |
| SS.08 | CAP-009, CAP-011 | ferrochain-\<provider\>, ferrochain-standard-tests | P1 |
| SS.09 | CAP-010 | ferrochain-mcp | P1 |
| SS.10 | CAP-012 | ferrochain-graph | P0 |
| SS.11 | CAP-013 | ferrochain-core/graph | P0 |
| SS.12 | CAP-014 | ferrochain-server | P1 |
| SS.13 | CAP-015 | ferrochain-graph/sandbox | P1 |
| SS.14 | CAP-016 | ferrochain-core | P0 |
| SS.15 | CAP-017 | ferrochain-memory (P2) | P2 |
| SS.16 | CAP-018 | ferrochain-core | P2 |
| SS.17 | CAP-019 | all (formal verification) | P2 |

## D17 Phase-1 BC Commitments Coverage

| D17 Commitment | BCs |
|----------------|-----|
| Q2: HITL contract | BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.05.004, BC-2.05.005, BC-2.05.006 |
| Q3: Per-task durability | BC-2.04.001, BC-2.04.002, BC-2.04.005 |
| Q4: Budget governance | BC-2.10.001, BC-2.10.002, BC-2.10.003, BC-2.10.004 |
| Q8: Content provenance/guardrail-on-ingress | BC-2.11.001–006 |
| Q9: R8 (splitters parity) | BC-2.07.001, BC-2.07.002 |
| Q9: R10 (NamedBarrierValue/EphemeralValue) | BC-2.02.003, BC-2.02.004 |
| Q9: R11 (MCP test voids) | BC-2.09.004, BC-2.09.005 |

> **Risk ID reconciliation:** `R11` used throughout this plan matches `R-006` in
> `domain-spec/risks.md` (both describe "MCP test voids: bare ToolException re-raise path
> untested upstream; `__aenter__` NotImplementedError contract untested"). STATE.md uses `R11`
> as a shorthand inherited from the D17 gate decisions; risks.md uses the canonical `R-006`
> identifier. They are the same risk. BCs continue to reference `R11` for consistency with
> STATE.md; the canonical ID for future artifacts is `R-006`.

## NE Requirement Coverage Summary

| NE | BC Anchors |
|----|-----------|
| NE-01 | BC-2.13.001 |
| NE-02 | BC-2.13.004, BC-2.13.005 |
| NE-03 | BC-2.14.006 |
| NE-04 | BC-2.14.004 |
| NE-05 | CI lint gate (ADR, no BC) |
| NE-06 | BC-2.11.002, BC-2.11.003, BC-2.11.004 |
| NE-07 | BC-2.14.003 |
| NE-08 | BC-2.12.006 |
| NE-09 | BC-2.16.001, BC-2.16.002, BC-2.16.003 |
| NE-10 | BC-2.14.005 |
| NE-11 | BC-2.04.007 |
| NE-12 | BC-2.04.006 |
| NE-13 | BC-2.06.003, BC-2.12.007 |
| NE-14 | BC-2.12.005 |
| NE-15 | BC-2.08.008 |
| NE-16 | BC-2.13.006 |
| NE-17 | BC-2.03.001, BC-2.03.003 |

## DI Invariant Enforcement Coverage

| DI | Enforcing BCs |
|----|--------------|
| DI-001 | BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.02.002 |
| DI-002 | BC-2.04.001, BC-2.04.002, BC-2.04.005 |
| DI-003 | BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.05.004 |
| DI-004 | BC-2.04.003, BC-2.04.004 |
| DI-005 | BC-2.04.006 |
| DI-006 | BC-2.13.001, BC-2.13.002, BC-2.13.003 |
| DI-007 | BC-2.13.004, BC-2.13.005 |
| DI-008 | BC-2.14.001, BC-2.14.003, BC-2.01.001, BC-2.01.002 |
| DI-009 | BC-2.14.004 |
| DI-010 | BC-2.14.005 |
| DI-011 | BC-2.06.001, BC-2.06.003, BC-2.12.007 |
| DI-012 | BC-2.11.001, BC-2.11.002, BC-2.11.003, BC-2.11.004, BC-2.11.005, BC-2.11.006 |
| DI-013 | BC-2.12.005 |
| DI-014 | BC-2.14.001, BC-2.14.006, BC-2.08.004, BC-2.08.007 |

**Coverage: 14/14 DIs enforced. Zero orphan invariants.**

---

## Batch Assignments

### Batch 1 — Core Primitives + Error Taxonomy Foundation (P0 first principles)
*8 BCs — SS.01 + SS.14 partial*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.01.001 | Typed ContentBlock sequence construction (no raw content where typed expected) | P0 | CAP-001 | DI-008 | Wave 0 |
| BC-2.01.002 | Message type-safety (AIMessage/HumanMessage/SystemMessage/ToolMessage) | P0 | CAP-001 | DI-008 | Wave 0 |
| BC-2.01.003 | Runnable trait invocation — invoke, stream, batch | P0 | CAP-002 | — | Wave 0 |
| BC-2.01.004 | Runnable pipe composition (A \| B = AB chain) | P0 | CAP-002 | — | Wave 0 |
| BC-2.14.001 | FerrochainError 2D component × category struct with RetryHint and machine code | P0 | CAP-016 | DI-008, DI-014 | Wave 0 |
| BC-2.14.002 | RFC-7807 compatible problem emission from FerrochainError | P0 | CAP-016 | — | Wave 0 |
| BC-2.14.003 | All library constructors return Result; no .unwrap()/.expect()/assert! in non-test (NE-07) | P0 | CAP-016 | DI-008 | Wave 0 |
| BC-2.14.004 | Every outbound HTTP ClientBuilder must set .timeout(30s); zero Client::new() outside tests (NE-04) | P0 | CAP-016 | DI-009 | Wave 0 |

### Batch 2 — Error Taxonomy Cont. + BSP Execution + Text Splitting (P0 correctness contracts)
*8 BCs — SS.14 cont. + SS.03 + SS.07*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.14.005 | API key newtype + Debug→"<redacted>"; no Serialize; no Deref<Target=str> (NE-10) | P0 | CAP-016 | DI-010 | Wave 0 |
| BC-2.14.006 | Validation failures propagate Err(FerrochainError); no silent None (NE-03) | P0 | CAP-016 | DI-014 | Wave 0 |
| BC-2.03.001 | BSP super-step execution determinism — Kani VP seed (NE-17) | P0 | CAP-004 | DI-001 | Wave 1 |
| BC-2.03.002 | Concurrent LastValue write rejection raises InvalidUpdateError | P0 | CAP-004 | DI-001 | Wave 1 |
| BC-2.03.003 | Deterministic reducer application order (task-identity sort) | P0 | CAP-004 | DI-001 | Wave 1 |
| BC-2.07.001 | Chunk boundaries are Unicode code-point counts (not bytes) | P0 | CAP-008 | — | Wave 0 |
| BC-2.07.002 | Non-ASCII boundary parity with Python reference implementation (emoji, CJK) — R8 Red Gate | P0 | CAP-008 | — | Wave 0 |
| BC-2.07.003 | Short document (length < chunk_size) — single chunk, no overlap, no panic | P0 | CAP-008 | — | Wave 0 |

### Batch 3 — Checkpointing Full Subsystem (P0 durability)
*7 BCs — SS.04 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.04.001 | Per-task put_writes completes before next super-step begins | P0 | CAP-005 | DI-002 | Wave 1 |
| BC-2.04.002 | Sync durability tier is default; async and exit-only are explicit opt-in | P0 | CAP-005 | DI-002 | Wave 1 |
| BC-2.04.003 | Monotonic logical-clock checkpoint IDs — wall-clock UUIDs are rejected | P0 | CAP-005 | DI-004 | Wave 1 |
| BC-2.04.004 | Fork lineage via parent_checkpoint_id pointers; no state copy on fork | P0 | CAP-005 | DI-004 | Wave 1 |
| BC-2.04.005 | Crash recovery: completed tasks not re-executed after process restart | P0 | CAP-005 | DI-002 | Wave 1 |
| BC-2.04.006 | Session triple-address uniqueness (thread_id, checkpoint_ns, checkpoint_id) — Kani VP seed (NE-12) | P0 | CAP-005 | DI-005 | Wave 1 |
| BC-2.04.007 | Encryption at rest covers both state AND event payloads; rotation errors propagate (NE-11) | P0 | CAP-005 | — | Wave 1 |

### Batch 4 — HITL Interrupt/Resume Full Subsystem (P0 D17-Q2 mandate)
*6 BCs — SS.05 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.05.001 | Interrupt suspension with durable state persistence | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.002 | Resume values delivered in strict FIFO order | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.003 | Interrupted node re-executes from start of its super-step on resume | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.004 | Command(resume=value) API contract for programmatic resume | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.005 | Resume on empty interrupt queue returns Err(NoActiveInterrupt) | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.006 | Risk-tiered interrupt classification (typed action-risk levels for Domain A SOC) | P0 | CAP-006 | DI-003, ASM-008 | Wave 1 |

### Batch 5 — StateGraph Definition Full Subsystem (P0)
*6 BCs — SS.02 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.02.001 | StateGraph node definition with typed channel assignment | P0 | CAP-003 | — | Wave 1 |
| BC-2.02.002 | LastValue / Append / BarrierValue channel semantics and reducer wiring | P0 | CAP-003 | DI-001 | Wave 1 |
| BC-2.02.003 | NamedBarrierValue missing-writer boundary behavior — Red Gate test (R10) | P0 | CAP-003 | — | Wave 1 |
| BC-2.02.004 | EphemeralValue cleared-after-super-step semantics — Red Gate test (R10) | P0 | CAP-003 | — | Wave 1 |
| BC-2.02.005 | Conditional edge routing function | P0 | CAP-003 | — | Wave 1 |
| BC-2.02.006 | Send API dynamic fan-out | P0 | CAP-003 | — | Wave 1 |

### Batch 6 — Streaming Events + Budget Governance (P0 D17-Q4 mandate)
*7 BCs — SS.06 + SS.10*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.06.001 | Typed per-phase event taxonomy (run/step/node/tool start-stream-end) | P0 | CAP-007 | DI-011 | Wave 1 |
| BC-2.06.002 | run_id + parent_ids correlation across all streaming events | P0 | CAP-007 | — | Wave 1 |
| BC-2.06.003 | Streaming and unary run produce identical final answer (NE-13) | P0 | CAP-007 | DI-011 | Wave 1 |
| BC-2.10.001 | BudgetPolicy allow/escalate/deny evaluation per run and per sub-agent | P0 | CAP-012 | — | Wave 1 |
| BC-2.10.002 | Append-only EvidenceJournal records every budget evaluation | P0 | CAP-012 | — | Wave 1 |
| BC-2.10.003 | Graceful halt when budget ceiling reached (on_ceiling = halt) | P0 | CAP-012 | — | Wave 1 |
| BC-2.10.004 | Budget escalation to HITL interrupt when on_ceiling = escalate | P0 | CAP-012, CAP-006 | DI-003 | Wave 1 |

### Batch 7 — Content Provenance + Guardrail-on-Ingress Full Subsystem (P0 D17-Q8 mandate)
*6 BCs — SS.11 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.11.001 | ProvenanceTag attached at every ingress boundary (tool-result, RAG, memory) | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.002 | GuardrailHook fires unconditionally at tool-result ingress | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.003 | GuardrailHook fires at RAG ingress | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.004 | GuardrailHook fires at memory ingress | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.005 | Rejected content does not enter model context under any code path | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.006 | No-hook default: content passes through with WARNING LOG (default-permit) | P0 | CAP-013 | DI-012 | Wave 1 |

### Batch 8 — Sandboxed Tool Execution Full Subsystem (P1)
*6 BCs — SS.13 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.13.001 | Enforcing sandbox backend (WASM or container) is default (NE-01) | P1 | CAP-015 | DI-006 | Wave 1 |
| BC-2.13.002 | Process backend requires explicit opt-in and emits loud runtime warning | P1 | CAP-015 | DI-006 | Wave 1 |
| BC-2.13.003 | Strict policy + non-enforcing backend returns Err(PolicyNotEnforceable) | P1 | CAP-015 | DI-006 | Wave 1 |
| BC-2.13.004 | All workspace file ops call canonicalize_beneath_root at access time — VP seed (NE-02) | P1 | CAP-015 | DI-007 | Wave 1 |
| BC-2.13.005 | Symlink that escapes workspace root returns Err(WorkspaceEscape) | P1 | CAP-015 | DI-007 | Wave 1 |
| BC-2.13.006 | macOS Seatbelt profile: deny-by-default with explicit allow rules (NE-16) | P1 | CAP-015 | DI-006 | Wave 1 |

### Batch 9 — Provider Conformance + Standard Tests (P1)
*9 BCs — SS.08 complete (Step-E addition: BC-2.08.009 authored from ADR-004 acceptance, architect feedback)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.08.001 | Chat model streaming completions conformance | P1 | CAP-009, CAP-011 | DI-011 | Wave 2 |
| BC-2.08.002 | Chat model tool-call round-trip conformance | P1 | CAP-009, CAP-011 | — | Wave 2 |
| BC-2.08.003 | Chat model structured output conformance | P1 | CAP-009, CAP-011 | — | Wave 2 |
| BC-2.08.004 | Chat model error-type fidelity conformance | P1 | CAP-009, CAP-011 | DI-014 | Wave 2 |
| BC-2.08.005 | Chat model token-usage accounting conformance | P1 | CAP-009, CAP-011 | — | Wave 2 |
| BC-2.08.006 | Standalone SDK crate split architecture (ferrochain-\<provider\>-sdk + adapter) | P1 | CAP-009 | DI-008 | Wave 2 |
| BC-2.08.007 | Provider streaming interrupted by transport error surfaces Err(Timeout), not truncated success | P1 | CAP-009 | DI-014 | Wave 2 |
| BC-2.08.008 | Eval score: arithmetic mean aggregation + JudgeResult::InfraError third outcome (NE-15) | P1 | CAP-011 | — | Wave 2 |
| BC-2.08.009 | Tool schema naming stability (snapshot test anchor) — **Step E** (ADR-004 snapshot obligation) | P1 | CAP-009 | — | Wave 2 |

### Batch 10 — MCP Adapter + Server Partial (P1)
*8 BCs — SS.09 + SS.12 partial*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.09.001 | MCP server tool discovery and registration at runtime | P1 | CAP-010 | — | Wave 2 |
| BC-2.09.002 | ToolInvocation routing to correct MCP server transport | P1 | CAP-010 | — | Wave 2 |
| BC-2.09.003 | Tool-result content treated as untrusted ingress (DI-012 applies) | P1 | CAP-010 | DI-012 | Wave 2 |
| BC-2.09.004 | MCP bare ToolException re-raise preserving type identity — R11 Red Gate | P1 | CAP-010 | DI-014 | Wave 2 |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections (Red Gate — R11) | P1 | CAP-010 | DI-014 | Wave 2 |
| BC-2.12.001 | Thread resource CRUD (create, read, list, delete durable conversation history) | P1 | CAP-014 | — | Wave 1 |
| BC-2.12.002 | Assistant resource CRUD (named agent config with graph reference) | P1 | CAP-014 | — | Wave 1 |
| BC-2.12.003 | Run creation and execution lifecycle (queued → in_progress → completed | failed | interrupted | cancelled) | P1 | CAP-014 | — | Wave 1 |

### Batch 11 — Server Cont. + Long-Horizon Memory (P1/P2)
*7 BCs — SS.12 cont. + SS.15*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.12.004 | CronSchedule creation and proactive run execution | P1 | CAP-014 | — | Wave 1 |
| BC-2.12.005 | SecurityConfig::default() denies CORS; debug route gated on explicit opt-in key (NE-14) | P1 | CAP-014 | DI-013 | Wave 1 |
| BC-2.12.006 | IdempotencyStore / RateLimitStore / RunStore trait seams with durable backends (NE-08) | P1 | CAP-014 | — | Wave 1 |
| BC-2.12.007 | Streaming endpoint and unary endpoint drive same graph engine, same final answer | P1 | CAP-014 | DI-011 | Wave 1 |
| BC-2.15.001 | KV and vector memory persistence across threads (not per-checkpoint) | P2 | CAP-017 | — | Post-v1 |
| BC-2.15.002 | User/app/session tier isolation — user-private does not bleed across scopes | P2 | CAP-017 | — | Post-v1 |
| BC-2.15.003 | GDPR erasure removes all traces from all memory tiers | P2 | CAP-017 | — | Post-v1 |

### Batch 12 — Tool Retry + Formal Verification (P2)
*5 BCs — SS.16 + SS.17*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.16.001 | Per-tool retry policy keyed by tool_name (not args hash) (NE-09) | P2 | CAP-018 | — | Post-v1 |
| BC-2.16.002 | Finite global_limit non-None default for all retry policies (NE-09) | P2 | CAP-018 | — | Post-v1 |
| BC-2.16.003 | Circuit breaker trips after repeated failure; prevents infinite retry (NE-09) | P2 | CAP-018 | — | Post-v1 |
| BC-2.17.001 | Kani harness scope: BSP determinism VP + session tenancy VP + workspace confinement VP | P2 | CAP-019 | DI-001, DI-005, DI-007 | Phase 6 |
| BC-2.17.002 | cargo-fuzz targets: serialization round-trip (checkpoint) and graph-execution paths | P2 | CAP-019 | — | Phase 6 |

---

## Proc-Macro BCs (UNBLOCKED — ADR-004 + ADR-008 accepted)

ADR-004 (D5 gate) and ADR-008 are both accepted. The following BCs have been authored
as Phase-1b additions (Batch 13). They are included in the 86-BC plan total.

### Batch 13 — Proc-Macro Developer Ergonomics (P1, Phase-1b, ADR-004/ADR-008)
*3 BCs — SS.08 extension (ferrochain-macros re-exported from ferrochain-core)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.08.010 | `#[tool]` Attribute Macro: async fn → Tool implementor via schemars::JsonSchema | P1 | CAP-002 | DI-008 | Wave 1 |
| BC-2.08.011 | `#[entrypoint]` Attribute Macro: START edge auto-wiring for StateGraph | P1 | CAP-003 | — | Wave 1 |
| BC-2.08.012 | `#[task]` Attribute Macro: task registration boilerplate generation | P1 | CAP-003 | — | Wave 1 |

---

## Authoring Guidelines for Sub-Burst Agents

1. **Subsystem ID:** Use `subsystem: SS-TBD` in frontmatter; architect assigns real IDs in Phase 1b.
2. **Capability Anchor Justification:** Each BC Traceability section must include:
   `| Capability Anchor Justification | CAP-NNN ("<exact title>") per capabilities.md §CAP-NNN |`
3. **DI citations:** Every BC that enforces a domain invariant must list it in the Traceability
   section under "L2 Domain Invariants".
4. **Test vectors:** Minimum 3 per BC (one happy-path, one edge-case, one error-case).
5. **Edge cases:** Minimum 1 per BC (EC-001); use domain-spec edge-cases.md for DEC-NNN anchors.
6. **VP seeds:** BCs that are Kani VP seeds (BC-2.03.001, BC-2.04.006, BC-2.13.004) must include
   a Verification Properties table with the VP description and method (Kani).
7. **Red Gate tests:** BCs for R8/R10/R11 (BC-2.07.002, BC-2.02.003-004, BC-2.09.004-005)
   must note "Red Gate test required — must compile and FAIL before implementation begins."
8. **Origin:** `origin: greenfield` for all 86 BCs (no brownfield extraction).
9. **Lifecycle:** `lifecycle_status: active`, `introduced: v1.0.0-greenfield`. **Status:** `status: active` — a BC is `active` once integrated into BC-INDEX; version bumps do NOT reset this field to `draft`.
10. **File path:** `.factory/specs/behavioral-contracts/ss-NN/BC-S.SS.NNN.md` (SS-NN from ARCH-INDEX Subsystem Registry)
