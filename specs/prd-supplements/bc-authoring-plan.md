---
document_type: prd-supplement-bc-authoring-plan
level: L3
version: "1.5"
status: active
producer: product-owner
total_standing_gates: 27
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
> batches of ≤8 BCs each at initial planning (Batch 9 carries a documented 9th BC — BC-2.08.009, Step-E addition per ADR-004 acceptance) for sequential sub-bursts. Each batch is one sub-burst.
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
| BCs per batch (max) | 9 (Batch 9 only — Step-E exception; planning cap remains 8) |
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
| DI-001 | BC-2.02.002, BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.17.001 |
| DI-002 | BC-2.04.001, BC-2.04.002, BC-2.04.005 |
| DI-003 | BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.05.004, BC-2.05.005, BC-2.05.006, BC-2.10.004 |
| DI-004 | BC-2.04.003, BC-2.04.004 |
| DI-005 | BC-2.04.006, BC-2.17.001 |
| DI-006 | BC-2.13.001, BC-2.13.002, BC-2.13.003, BC-2.13.006 |
| DI-007 | BC-2.13.004, BC-2.13.005, BC-2.17.001 |
| DI-008 | BC-2.01.001, BC-2.01.002, BC-2.08.006, BC-2.08.010, BC-2.14.001, BC-2.14.003 |
| DI-009 | BC-2.08.007, BC-2.14.004 |
| DI-010 | BC-2.14.005 |
| DI-011 | BC-2.06.001, BC-2.06.003, BC-2.08.001, BC-2.12.007 |
| DI-012 | BC-2.09.003, BC-2.11.001, BC-2.11.002, BC-2.11.003, BC-2.11.004, BC-2.11.005, BC-2.11.006 |
| DI-013 | BC-2.12.005 |
| DI-014 | BC-2.08.004, BC-2.08.007, BC-2.09.004, BC-2.09.005, BC-2.14.001, BC-2.14.006 |

**Coverage: 14/14 DIs enforced. Zero orphan invariants.**

---

## Batch Assignments

### Batch 1 — Core Primitives + Error Taxonomy Foundation (P0 first principles)
*8 BCs — SS.01 + SS.14 partial*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.01.001 | Typed ContentBlock sequence construction (no raw content where typed expected) | P0 | CAP-001 | DI-008 | Wave 0 |
| BC-2.01.002 | Message type-safety (AiMessage/HumanMessage/SystemMessage/ToolMessage) | P0 | CAP-001 | DI-008 | Wave 0 |
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
| BC-2.05.006 | Risk-tiered interrupt classification (typed action-risk levels for Domain A SOC) | P0 | CAP-006 | DI-003 | Wave 1 |

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
| BC-2.10.004 | Budget escalation to HITL interrupt when on_ceiling = escalate | P0 | CAP-012 | DI-003 | Wave 1 |

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
| BC-2.08.001 | Chat model streaming completions conformance | P1 | CAP-009 | DI-011 | Wave 2 |
| BC-2.08.002 | Chat model tool-call round-trip conformance | P1 | CAP-009 | — | Wave 2 |
| BC-2.08.003 | Chat model structured output conformance | P1 | CAP-009 | — | Wave 2 |
| BC-2.08.004 | Chat model error-type fidelity conformance | P1 | CAP-009 | DI-014 | Wave 2 |
| BC-2.08.005 | Chat model token-usage accounting conformance | P1 | CAP-009 | — | Wave 2 |
| BC-2.08.006 | Standalone SDK crate split architecture (ferrochain-\<provider\>-sdk + adapter) | P1 | CAP-009 | DI-008 | Wave 2 |
| BC-2.08.007 | Provider streaming interrupted by transport error surfaces Err(Timeout) or Err(Transport), not truncated success | P1 | CAP-009 | DI-009, DI-014 | Wave 2 |
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
| BC-2.12.003 | Run Creation and Execution Lifecycle (queued → in_progress → completed/failed/cancelled; interrupted is pausable/resumable) | P1 | CAP-014 | — | Wave 1 |

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
11. **Governance: integrated-into-index ⇒ `status: active` (all spec artifacts).**
    - A spec artifact is integrated once its authoritative index accepts it: BC files → BC-INDEX, domain-spec shards → L2-INDEX, architecture sections → ARCH-INDEX, prd.md and prd-supplements → prd.md supplements list, ADRs → ARCH-INDEX ADR log (stay `accepted`), product-brief → product review (stays `approved`).
    - VP files are the **only** exception: they may remain `status: draft` while Kani/integration harnesses are pre-implementation, provided VP-INDEX.md is `status: active` and lists the VP.
    - This rule is generalized from F-P6-03 (ADV-P1D-PASS-6 fix). Source of truth: ADV-P1D-PASS-8.md §F-P8-04.
12. **Lifecycle-arrow census gate (added P12):** Any BC or supplement that contains a Run
    state-machine lifecycle arrow MUST use one of the two canonical forms:
    - *Title/prose* form: `queued → in_progress → completed/failed/cancelled; interrupted is pausable/resumable`
    - *Diagram/arrow* form: `queued → in_progress → completed | failed | cancelled; in_progress ⇄ interrupted (resume via POST .../resume)`
    Terminal set = {completed, failed, cancelled} only. `interrupted` MUST NOT appear as a
    terminal state in any lifecycle arrow. The single authority for the state machine is
    BC-2.12.003 PC7-PC9. Run `grep -rn "in_progress →\|in_progress→\|→ interrupted\|⇄" .factory/specs/`
    and verify every hit: (a) shows `interrupted` as pausable/resumable, and (b) lists only
    `completed | failed | cancelled` as terminal. Source of truth: ADV-P1D-PASS-12.md §F-P12-01.
13. **Anchor-matrix census gate (added P16 — standing gate, subsumes all prior per-axis checks; widened P40 — five-way):**
    After any BC authoring burst, run the full anchor-matrix census across all 86 BCs × 6 axes
    {CAP, DI, NE, R (R-NNN/R8-10-11 aliases), ADR, registered-VP}. For each axis, perform a
    **five-way consistency check**: BC body Traceability tables ↔ BC-INDEX columns (NE Anchors,
    DI Anchors, Cap, VP, RG) ↔ PRD §2 tables + §7 RTM Source column + §9 NE Disposition Table ↔
    authoritative registry (capabilities shards / invariants.md / PRD §9 / risks.md /
    ARCH-INDEX ADR registry / VP-INDEX) ↔ **bc-authoring-plan batch-table anchor columns
    (CAP, DI)**. Body wins unless provably wrong; fix index/RTM/batch-table to match body.
    The ne_anchor and ne_coverage frontmatter fields are OPTIONAL-LEGACY — BC body
    Traceability (NE anchor row) + BC-INDEX NE Anchors column are the canonical carriers; do
    NOT add ne_anchor/ne_coverage frontmatter to new BCs.
    **Widening rationale (OBS-P40-1, ADV-P1D-PASS-40):** The bc-authoring-plan batch-table
    CAP/DI columns were absent from the carrier set through Pass 39. This allowed the batch-table
    DI cell for BC-2.08.007 to show `DI-014` while all other four carriers showed `DI-009, DI-014`
    (motivating instance: F-P40-01). The batch-table is consumed by sub-burst authoring agents and
    must match BC-INDEX on every anchor-affecting burst to prevent forward propagation of drift.
    Source of truth: ADV-P1D-PASS-16.md §F-P16-01 + anchor-matrix reconciliation;
    ADV-P1D-PASS-40 §OBS-P40-1 (widening).
14. **Harness-fn registry + executable-string census gate (added P17 — standing gate):**
    VP-INDEX.md `harness_fn` column is the authoritative registry for Phase-6 `cargo kani --harness`
    invocation identifiers. Any change to a VP harness function name MUST update VP-INDEX.md
    `harness_fn` first, then propagate to: VP-NNN.md harness skeleton fn name, nfr-catalog.md
    any `cargo kani --harness` command string, BC body Kani VP Seed notes, and
    verification-architecture.md harness sketches. After any such change, run the full
    executable-string census: `grep -rn "cargo kani --harness" .factory/specs/` and verify
    every cited harness name matches a `harness_fn` value in VP-INDEX.md (or is a placeholder
    `<harness_name>`). Source of truth: ADV-P1D-PASS-17.md §F-P17-01 + executable-string census.
15. **Shared-type identifier census gate (added P18 — standing gate):**
    After any BC authoring or fix burst, run the shared-type identifier census across all BC code
    snippets and prd-supplements (excluding interface-definitions.md, which is architect scope).
    For every ferrochain type in the ubiquitous-language reconciliation table plus the core
    shared types (Message, ContentBlock, AiMessage, AiMessageChunk, FerrochainError, Component,
    Category, RetryHint, CheckpointSaver, RunnableConfig, CheckpointTuple, RunStatus, MemoryStore,
    BudgetPolicy, GuardrailHook, ProvenanceTag): assert single spelling per type across all BC
    code snippets and prd-supplements. Canonical spellings are the ferrochain names per
    ubiquitous-language-server.md reconciliation table (D17 fidelity: CheckpointSaver not
    CheckpointStore; RunnableConfig not RunConfig; AiMessage not AIMessage). Retired spellings
    (CheckpointStore, RunConfig, BaseCheckpointSaver, AIMessage in Rust contexts) must have 0
    occurrences. Census command (updated P20):
    `grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage\|\bCheckpointer\b" .factory/specs/`
    Added retired spelling: bare `\bCheckpointer\b` (canonical name is `CheckpointSaver`).
    Note: compound identifiers where `Checkpointer` has no left `\b` (e.g.,
    `InterruptWithoutCheckpointer`) are self-excluded by the regex — no explicit exemption needed.
    Exemptions (do NOT count as violations): (a) Python semport cross-references (cite semport
    source file); (b) census-rule text itself in bc-authoring-plan.md; (c) reconciliation table
    LEFT column in ubiquitous-language-server.md (intentionally documents LangChain Python names).
    Source of truth: ADV-P1D-PASS-19.md §F-P19-02 (scope widened from BC+prd-supplements to full
    .factory/specs/); ADV-P1D-PASS-18.md §F-P18-01 + shared-type identifier census.
    `\bCheckpointer\b` widened: ADV-P1D-PASS-20.md §F-P20-03.

17. **HTTP endpoint census gate (added P23 — standing gate):**
    After any BC authoring or fix burst that adds, moves, or renames an HTTP endpoint path,
    run the full endpoint census. Two sub-checks:

    **A. URL-scheme consistency (RUNS = thread-nested; SCHEDULES = flat):**
    Canon: ALL run CRUD paths are `/threads/{thread_id}/runs/...`. The ONLY flat run path
    is the cross-thread aggregate `GET /runs?schedule_id={cron_id}` (BC-2.12.004). All
    schedule CRUD paths are `/schedules/{cron_id}` (flat). Source of truth: F-P23-01;
    interface-definitions.md §Runs and §Cron Schedules; api-surface.md §ferrochain-server HTTP Endpoints.

    Census command:
    `grep -rn "POST /runs\b\|GET /runs/\|DELETE /runs/\|PATCH /runs/" .factory/specs/ | grep -v "schedule_id" | grep -v "threads/"` — output must be EMPTY (zero hits).
    Any non-empty output means a flat run path escaped the fix.

    **B. Path × citing-docs × scheme-verdict table:** After any endpoint change, verify
    the following canonical table still holds (all rows PASS):

    | Path (canonical) | Citing Docs | Scheme Verdict |
    |-----------------|-------------|---------------|
    | `POST /threads/{thread_id}/runs` | interface-definitions.md, api-surface.md, prd.md §3, BC-2.12.003 | PASS (thread-nested) |
    | `GET /threads/{thread_id}/runs` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
    | `GET /threads/{thread_id}/runs/{run_id}` | interface-definitions.md, api-surface.md, BC-2.12.003, BC-2.12.007, BC-2.05.006 | PASS |
    | `GET /threads/{thread_id}/runs/{run_id}/stream` | interface-definitions.md, api-surface.md, BC-2.12.007 | PASS |
    | `POST /threads/{thread_id}/runs/{run_id}/resume` | interface-definitions.md, api-surface.md, BC-2.05.004, BC-2.05.005, BC-2.05.006, edge-cases.md | PASS |
    | `POST /threads/{thread_id}/runs/{run_id}/cancel` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
    | `DELETE /threads/{thread_id}/runs/{run_id}` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
    | `POST /schedules` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS (flat) |
    | `GET /schedules/{cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
    | `PATCH /schedules/{cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
    | `DELETE /schedules/{cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
    | `GET /runs?schedule_id={cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS (flat; cross-thread aggregate only) |

    **Endpoint-count invariant (OBS-P33-2, ADV-P1D-PASS-33 [process-gap]):** Total
    ferrochain-server HTTP endpoints = **26** (Threads 7 + Assistants 7 + Runs 7 +
    Cron 4 + aggregate 1). Recount confirmed from interface-definitions.md §Threads /
    §Assistants / §Runs / §Cron Schedules tables. Any burst that adds or removes an
    endpoint MUST update this count in the same burst.

    **C. HTTP status-code↔E-code census (schema discipline):** For each BC that states
    an HTTP status code for a specific E-xxx-NNN error, assert the code maps correctly
    to the interface-definitions.md §HTTP Status Codes table.

    **Positive-coverage assertion (added P25 — [process-gap] fix):** Every PASS row in
    this census table MUST be grep-verifiable in interface-definitions.md §HTTP Status Codes.
    A census row marked PASS against a status code or E-code not present in the interface
    table is a false PASS — the census is inert. Census command:
    `grep -n "^| 201\|^| 202\|^| 204\|^| 400\|^| 401\|^| 403\|^| 404\|^| 409\|^| 422\|^| 429\|^| 500\|^| 502\|^| 503\|^| 504" .factory/specs/prd-supplements/interface-definitions.md`
    Every status code appearing in the census table below must appear as a row in that grep output.
    Source: ADV-P1D-PASS-25 F-P25-07 [process-gap].

    | HTTP Code | E-code + Variant | Citing BCs (sample) | Verdict |
    |-----------|-----------------|---------------------|---------|
    | 400 | E-CRON-002 InvalidCronExpression | BC-2.12.004 EC-002 | PASS (added 400 row in iface-def P25) |
    | 404 | E-SERVER-002 RunNotFound | BC-2.12.003 EC-001, TV-003, TV-004 | PASS |
    | 404 | E-SERVER-003 ThreadNotFound | BC-2.12.003 PC2, EC-001 | PASS |
    | 404 | E-SERVER-006 ScheduleNotFound | BC-2.12.004 EC-005 | PASS |
    | 409 | E-SERVER-012 ConcurrentRun | BC-2.12.003 EC-002 | PASS |
    | 409 | E-SERVER-015 RunAlreadyExecuting | BC-2.12.007 TV-006 | PASS |
    | 422 | E-GRAPH-002 NoActiveInterrupt | BC-2.05.005 TV-003 | PASS (F-P27-01: E-GRAPH-002 now enumerated in 422 row explicitly as POLICY→422 per-endpoint override; BC-2.14.002 PC3 9th override; wildcard citation in EC-001 and TV-003 replaced with concrete override citation; prior wildcard "E-GRAPH-* → 422" retired by P26 OBS-1 narrowing) |
    | 422 | E-SERVER-009 (AssistantNotFound in run body) | BC-2.12.003 PC3 | PASS (context-dependent: 422 in run creation body; 404 at direct assistant lookup) |
    | 422 | E-SERVER-011 (GraphNotFound in assistant body) | BC-2.12.002 EC-005 | PASS |
    | 429 | E-PROV-001 | interface-definitions.md | PASS |
    | 500 | E-SERVER-014 RunStoreFailed | BC-2.12.006 EC-004 | PASS |
    | 204 | DELETE success (no body) | BC-2.12.004 PC5, EC-005 | PASS (204 row added to iface-def P25) |
    | 201 | POST /schedules | BC-2.12.004 TV-001 | PASS (201 row added to iface-def P25) |
    | 202 | POST /threads/{id}/runs | BC-2.12.003 PC5 | PASS |
    | 503 | E-SERVER-016 IdempotencyLockTimeout | BC-2.12.006 EC-002 | PASS (503 row added to iface-def P25; per-endpoint override over Timeout→504) |

    Source of truth: ADV-P1D-PASS-23.md §F-P23-01; ADV-P1D-PASS-25 §F-P25-07; interface-definitions.md §HTTP Status Codes.

16. **E-code↔variant-name consistency census gate (added P20 — standing gate; widened P34 — F-P34-03):**
    After any BC authoring or fix burst that introduces, renames, or retires an error code,
    run the variant-name consistency census. For every `E-<COMP>-NNN <VariantName>` or
    `E-<COMP>-NNN: <VariantName>` pairing found in any BC body, assert that `<VariantName>`
    is the canonical variant name for `E-<COMP>-NNN` in error-taxonomy.md. A code referenced
    with the wrong variant name is a high-severity drift that misleads implementers.

    **Census commands (BOTH forms required — F-P34-03):**

    Form 1 (space-delimited: `E-XXX-NNN VariantName`):
    `grep -hrn "E-[A-Z]*-[0-9]\{3\} [A-Z][A-Za-z]*" .factory/specs/behavioral-contracts/ | grep -v "~~" | grep -oE "E-[A-Z]+-[0-9]{3} [A-Z][A-Za-z]+" | sort -u`

    Form 2 (colon-delimited: `E-XXX-NNN: VariantName`):
    `grep -hrn "E-[A-Z]*-[0-9]\{3\}: [A-Z][A-Za-z]*" .factory/specs/behavioral-contracts/ | grep -v "~~" | grep -oE "E-[A-Z]+-[0-9]{3}: [A-Z][A-Za-z]+" | sort -u`

    **Cross-check requirement (collision detection):** For each extracted pairing (either form),
    look up the code in error-taxonomy.md and verify (a) the variant name matches the taxonomy
    row exactly, AND (b) the code is not already assigned a DIFFERENT variant name elsewhere in
    the taxonomy (collision detection, not just name drift). A code appearing in a BC with a
    variant name that differs from the taxonomy's canonical variant is a HIGH-severity finding.
    Category names (POLICY, VAL, TIMEOUT, DURABILITY, TOOL, etc.) appearing after a code in a
    markdown table row are false positives — filter these out by confirming the word is not a
    known category code from the Error Category Codes table.

    Codes used without a variant name (e.g., bare `E-CHKPT-001`) are permitted — only named
    pairings are checked. Retired codes (~~strikethrough~~ in taxonomy) must not appear in
    non-~~strikethrough~~ BC text.

    Source of truth: ADV-P1D-PASS-20.md §F-P20-03. Widening rationale: ADV-P1D-PASS-34
    §F-P34-03 — the original space-only regex missed `E-RETRY-003: InvalidRetryLimit` in
    BC-2.16.001.md for 33 passes, allowing a live collision to persist undetected.

18. **Wire-object field-set coherence census gate (added P24 — standing gate):**
    After any BC authoring or fix burst that introduces, modifies, or removes a field on a
    wire-visible object (Run, Thread, Assistant, CronSchedule, Resume request, or any new
    server resource), run the three-way field-set census: `interface-definitions.md` JSON schema
    ↔ `entities-server.md` entity fields ↔ every BC postcondition / test vector that returns or
    consumes the object. All three must agree; the BCs are authoritative.

    **Canonical field-set table (as of F-P24-01):**

    | Object | Field | schema (iface-def) | entity (entities-server) | BC PC/TV | Verdict |
    |--------|-------|-------------------|--------------------------|----------|---------|
    | Run | run_id | required | YES | PC5, PC13 | PASS |
    | Run | thread_id | required | YES | PC5, PC13 | PASS |
    | Run | assistant_id | required | YES | PC5, PC13 | PASS |
    | Run | status | required | YES (RunStatus) | PC5, PC13 | PASS |
    | Run | created_at | required | YES | PC5, PC13 | PASS |
    | Run | updated_at | required (added F-P24-01) | YES | PC13 | PASS |
    | Run | completed_at | nullable (added F-P24-01) | YES (Option<Timestamp>) | PC13 | PASS |
    | Run | output | conditional (status=completed) | YES (Option<Value>) | PC15 | PASS |
    | Run | error | conditional (status=failed) | implicit via FerrochainError | PC16 | PASS |
    | Run | interrupt | conditional (status=interrupted) | Interrupt entity (separate) | PC9 | PASS (flattened) |
    | Thread | thread_id | no JSON schema | YES | PC5 | NOTE: no explicit JSON schema; entity + BC suffice |
    | Thread | metadata | — | YES | PC1 | PASS |
    | Thread | created_at | — | YES | PC5 | PASS |
    | Thread | updated_at | — | YES | PC5 | PASS |
    | Thread | status | — | YES (ThreadStatus; added F-P24-01) | PC5 | PASS |
    | Assistant | assistant_id | no JSON schema | YES | PC4 | PASS |
    | Assistant | graph_id | — | YES | PC4 | PASS |
    | Assistant | config | — | YES | PC4 | PASS |
    | Assistant | context | — | YES (Option<Value>; added F-P24-01) | PC4 | PASS |
    | Assistant | metadata | — | YES | PC4 | PASS |
    | Assistant | name | — | YES (Option<String>; added F-P24-01) | PC4 | PASS |
    | Assistant | description | — | YES (Option<String>; added F-P24-01) | PC4 | PASS |
    | Assistant | version | — | YES (u32; added F-P24-01) | PC4 | PASS |
    | Assistant | created_at | — | YES (added F-P24-01) | PC4 | PASS |
    | CronSchedule | cron_id | path param `{cron_id}` | YES | PC1, PC3 | PASS |
    | CronSchedule | assistant_id | — | YES | PC1 | PASS |
    | CronSchedule | schedule | — | YES (CronExpression) | PC1 | PASS |
    | CronSchedule | config | — | YES | PC4 (input) | PASS |
    | CronSchedule | enabled | GET response | YES | PC4 | PASS |
    | CronSchedule | last_fired_at | GET response | YES (Option<Timestamp>; added F-P24-01) | PC3 | PASS |
    | ResumeRequest | resume_value | required | N/A (request body) | BC-2.05.004 | PASS |
    | ResumeRequest | approver_id | optional | N/A | BC-2.05.004 | PASS |

    **Census trigger:** any change to a BC postcondition or test vector that adds, renames, or
    removes a field on a wire-visible object MUST propagate to (a) the `interface-definitions.md`
    JSON schema for that object (if one exists), (b) the `entities-server.md` entity field list,
    and (c) all other BCs that return or consume that same object. Three-way consistency is
    required before the fix burst closes.

    **Sub-field coherence extension (added P25 — F-P25-06):** The three-way census applies to
    EMBEDDED sub-objects (e.g., Run.interrupt, Run.error) with the same discipline as top-level
    objects. For each embedded object with a `properties` block in the interface-definitions.md
    JSON schema, every named sub-field must be coherent across (a) the schema `properties`, (b)
    the entity or BC type that defines the sub-object shape, and (c) all BCs that emit or consume
    the parent object in the interrupted/error state. Known embedded sub-objects subject to this rule:
    Run.interrupt (fields: interrupt_id, node_name, super_step, value, action_risk, action, context,
    scratchpad — authority: BC-2.05.001, BC-2.05.006, entities-server.md §Interrupt);
    Run.error (fields: type, title, detail, extensions — authority: BC-2.14.002, RFC-7807).
    Sub-field drift between the schema and the authoritative BC is a wire-breaking defect.
    Source: ADV-P1D-PASS-25 §F-P25-06.

    **Quick check command (Run object schema):**
    `grep -n "updated_at\|completed_at" .factory/specs/prd-supplements/interface-definitions.md .factory/specs/domain-spec/entities-server.md .factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md`
    Both `updated_at` and `completed_at` must appear in all three files.

    Source of truth: ADV-P1D-PASS-24.md §WIRE-OBJECT class.

19. **Retired-identifier residue grep (added P26 — standing gate):**
    Whenever a rename canon is set (method name, field name, type identifier, route path),
    the fix burst MUST grep the ENTIRE `.factory/specs/` tree — including
    `architecture/decisions/` ADRs AND all BC test vectors — for the retired identifier
    and drain every hit before the burst closes. A changelog or census-rule mention is
    not a hit; only live (non-~~strikethrough~~, non-changelog, non-census-rule) occurrences
    are violations.

    **Current retired-identifier list** (add to this list whenever a new rename is canonized):
    | Retired Identifier | Canonical Replacement | Canon Set In |
    |--------------------|----------------------|-------------|
    | `to_problem_detail` | `to_problem` | F-P25-04 (api-surface.md); F-P26-02 (ADR-010) |
    | `risk_tier` | `action_risk` | F-P25-06 (Run.interrupt sub-field); F-P26-03 (BC-2.05.001 TV-005) |
    | `node_id` (in interrupt context) | `node_name` | F-P25-06 (Run.interrupt sub-field) |
    | `{schedule_id}` (flat run path param) | thread-nested `runs/` paths | F-P23-01 |
    | `CheckpointStore` | `CheckpointSaver` | P18 shared-type census |
    | `RunConfig` | `RunnableConfig` | P18 shared-type census |
    | `BaseCheckpointSaver` | `CheckpointSaver` | P18 shared-type census |
    | `AIMessage` (Rust context) | `AiMessage` | P18 shared-type census |
    | bare `\bCheckpointer\b` | `CheckpointSaver` | P20 shared-type census |
    | `X-Debug-Key` header | `Authorization: Bearer <key>` | F-P26-04 |
    | `/debug/*` path | `/_debug` | F-P26-04 |
    | `risk_tier.rs` (source file path) | `action_risk.rs` | F-P27-06 (BC-2.05.006 Architecture Anchor) |
    | `node_delta` (SSE event token / description) | `node_stream` | F-P29-03 (BC-2.12.007, interface-definitions.md); BC-2.06.001 is the streaming taxonomy authority |
    | `RunStarted`, `NodeStarted`, `ToolStarted`, `StepStarted`, `RunEnded`, `NodeEnded`, `ToolEnded`, `StepEnded` (Rust enum variant names in L3 architecture artifacts) | `RunStart`, `NodeStart`, `ToolStart`, `StepStart`, `RunEnd`, `NodeEnd`, `ToolEnd`, `StepEnd` (imperative) | F-P29-04 (ADR-006, module-decomposition.md); BC-2.06.001 is the authority; **NOTE: events.md (L2 domain spec) uses past-tense PascalCase (RunStarted, InterruptRaised, etc.) as DDD domain event names — this is correct and NOT retired; the census below excludes domain-spec/** |
    | `run_started`, `node_started` (snake_case SSE wire tokens) | `run_start`, `node_start` (imperative) | F-P29-04 (ADR-006); wire tokens follow variant names |

    Census command: `grep -rn "to_problem_detail\|risk_tier\|X-Debug-Key\|node_delta" .factory/specs/ | grep -v "bc-authoring-plan\|~~\|changelog\|Census command\|retired.*list\|Retired Identifier\|action_risk.rs"` — output must be ZERO live occurrences (bc-authoring-plan.md excluded as registry document).
    Census command (past-tense StreamEvent variants — L3 architecture and BC artifacts only): `grep -rn "RunStarted\|NodeStarted\|ToolStarted\|StepStarted\|run_started\|node_started" .factory/specs/ | grep -v "bc-authoring-plan\|domain-spec/\|~~\|changelog\|Census command\|retired.*list\|Retired Identifier"` — output must be ZERO live occurrences.
    Source: ADV-P1D-PASS-26 §F-P26-02, §F-P26-03, §F-P26-04; ADV-P1D-PASS-27 §F-P27-06; ADV-P1D-PASS-29 §F-P29-03, §F-P29-04.

20. **AUTH/POLICY category re-sweep (added P26 — standing gate):**
    Any edit to a 401/403/409 table row in interface-definitions.md §HTTP Status Codes,
    OR any change to an E-code's `category` field in error-taxonomy.md, MUST trigger a
    full category→status census for ALL error codes in the affected categories across ALL
    namespaces (E-CORE, E-GRAPH, E-CHKPT, E-SERVER, E-PROV, E-MCP, E-SPLIT, E-SBXD,
    E-RETRY, E-CRON, E-MEMORY, E-BUDGET — not just the namespace being edited).

    The census must verify:
    1. Every AUTH-category code: maps to 401 (categorical) or has a documented per-endpoint override in BC-2.14.002 PC3.
    2. Every POLICY-category code: maps to 403 (categorical) or has a documented per-endpoint override.
    3. Every CONCURRENCY-category code: maps to 409 (categorical) or has a documented per-endpoint override.
    4. No code appears in two conflicting rows of the HTTP status table without an explicit disambiguation note.

    Source: ADV-P1D-PASS-26 §F-P26-05 (E-PROV-004 orphan discovery triggered this gate).

21. **HTTP status-code table edit → census re-run trigger (added P27 — standing gate):** [process-gap]
    Any burst that edits the interface-definitions.md §HTTP Status Codes table (row add,
    row remove, row narrowing, or row widening) MUST re-run the full §17-C census
    (guideline #17 above) IN THE SAME BURST and update every affected census row before
    the burst closes.

    **Trigger conditions:**
    - Adding a new E-code to any row → add a census row for that code
    - Removing an E-code from a row → retire the census row (mark RETIRED with reason)
    - Narrowing a wildcard to an enumerated list → update every census row that cited the wildcard
    - Widening an enumerated list → add census rows for newly included codes
    - Changing a row's description without changing codes → no census update needed (description-only)

    **Rationale:** ADV-P1D-PASS-27 §OBS-P27-2 found that the P26 OBS-1 narrowing of the 422
    wildcard (E-GRAPH-* → enumerated list) left the §17-C census row for E-GRAPH-002 citing
    the retired wildcard as its PASS evidence — making the census row a false PASS. The census
    must be re-run whenever the table it verifies against changes.

    **Deferred process improvement (machine-enforcement recommendation, OBS-P27-2):** The
    orchestrator should consider a CI/hook implementation: a grep script that re-runs the
    §17-C census after any commit touching interface-definitions.md §HTTP Status Codes and
    fails if any census row cites a wildcard pattern that no longer exists in the table row.
    This would make the census machine-enforceable rather than relying on burst discipline.
    Log at cycle close for v1.1 planning.

    Source: ADV-P1D-PASS-27 §OBS-P27-2 [process-gap].

22. **RetryHint coherence gate — RETRYHINT COHERENCE (added P28 — standing gate):**
    Any burst that creates or edits a per-code catalog row in error-taxonomy.md OR edits
    the Error Category Codes table (adding/removing a category or changing a Default RetryHint)
    MUST verify RetryHint coherence before the burst closes:

    1. **Per-code row check:** For every new or edited E-code row that has an explicit
       `RetryHint` column value, confirm whether that value matches or diverges from the
       category's "Default RetryHint" in the category table.
    2. **Divergence requires BC-anchored rationale:** If the per-code RetryHint diverges
       from the category default, the per-code row (or an inline correction note) MUST
       include a rationale citing the specific BC (e.g., "BC-2.16.003 circuit-breaker
       cool-down semantics override POLICY Never default"). A bare divergence with no
       rationale is a gate failure.
    3. **Category-table edit propagation:** If the Default RetryHint for a category is
       changed, re-audit ALL per-code rows in that category to confirm that:
       (a) any previously-compliant rows are still compliant under the new default, and
       (b) any new divergences are documented with rationale.
    4. **No silent convergence:** Do NOT silently change a per-code RetryHint to match
       the default without confirming the semantics. The per-code value may be intentionally
       different (e.g., a DURABILITY code that is non-recoverable by retry should keep
       `Never` even if the category default is `Maybe`).

    **Known intentional divergences (as of ADV-P1D-PASS-28):**

    | Error Code | Category | Default RetryHint | Per-Code RetryHint | Rationale |
    |-----------|----------|-------------------|--------------------|-----------|
    | E-RETRY-003 | POLICY | Never | `Later(<reset_timeout>)` | BC-2.16.003: circuit breaker has a defined reset horizon; the cool-down period makes Later semantics correct (retrying after reset_timeout will likely succeed) |
    | E-CRON-003 | POLICY | Never | `Later` | BC-2.12.004: schedule queue transiently full; next firing cycle will likely have capacity |
    | E-MEMORY-002 | DURABILITY | Maybe | `Never` | BC-2.15.001: storage-full is non-recoverable by retry without operator intervention (capacity must be freed or expanded) |
    | E-MEMORY-005 | DURABILITY | Maybe | `Never` | BC-2.15.003: GDPR erasure partial failure rolled back; retry without fixing the underlying cause will produce the same partial failure |
    | E-BUDGET-002 | DURABILITY | Maybe | `Never` | BC-2.10.002: budget journal write failure is non-recoverable by retry if the storage backend has failed; journaling must be restored by operator |

    **Rationale:** ADV-P1D-PASS-28 §F-P28-01 found that 5 codes have per-code RetryHints
    diverging from their category defaults with no precedence rule documenting which value
    is authoritative. The fix (F-P28-01) relabeled the column to "Default RetryHint" and
    added a precedence rule; this gate ensures future divergences are explicitly justified.
    Source: ADV-P1D-PASS-28 §F-P28-01 [process-gap].

    **ADV-P1D-PASS-29 update (F-P29-02):** E-CRON-003 (ScheduleQueueFull) was present in
    the known-intentional-divergences table above but was NOT cited in the blockquote at
    error-taxonomy.md §RetryHint precedence rule. Fixed: blockquote now explicitly cites all
    5 divergent codes. The blockquote divergence list and this table must remain in sync.

23. **Streaming-event-name coherence gate — STREAMING-EVENT-NAME COHERENCE (added P29 — standing gate):**
    [process-gap] Any burst that creates or edits streaming event names in ANY of the following
    artifacts: `domain-spec/events.md`, `domain-spec/capabilities-p0.md`, `BC-2.06.001.md` (the
    StreamEvent enum authority), `architecture/decisions/ADR-006-streaming-event-taxonomy.md`,
    `prd-supplements/interface-definitions.md`, `BC-2.12.007.md`, `architecture/module-decomposition.md`
    MUST perform a three-way coherence check before the burst closes:

    1. **L2 source (events.md, capabilities-p0.md):** Note the domain event names and any
       stream-event labels. Domain event section headers (RunStarted, InterruptRaised, etc.)
       use DDD past-tense PascalCase — this is intentional and NOT a violation.
    2. **BC-2.06.001 StreamEvent enum (authoritative):** Variant names must be imperative
       (RunStart, NodeStream, ToolEnd, etc.); wire tokens must be snake_case imperative
       (run_start, node_stream, tool_end, etc.).
    3. **Downstream consumers** (ADR-006, interface-definitions.md, BC-2.12.007,
       module-decomposition.md): Must use the exact variant names and wire tokens from
       BC-2.06.001. Any description field listing event tokens must use node_stream not
       node_delta; RunStart not RunStarted.
    4. **D13 wire posture:** ADR-006 and any wire-format description must state
       ferrochain-native wire format. LangChain Python `.astream_events()` v2 compat
       claims are a gate failure (they contradict D13).
    5. **Census commands:**
       - `grep -rn "node_delta" .factory/specs/ | grep -v "bc-authoring-plan\|~~\|changelog\|retired.*list\|Census"` → zero live hits
       - `grep -rn "RunStarted\|NodeStarted\|run_started" .factory/specs/ | grep -v "bc-authoring-plan\|domain-spec/\|~~\|changelog\|retired.*list\|Census"` → zero live hits
       - `grep -n "NodeStream\|ToolStream" .factory/specs/architecture/decisions/ADR-006-streaming-event-taxonomy.md` → present
       - `grep -rn "astream_events" .factory/specs/architecture/ | grep -v "native\|D13\|NOT\|no.*compat"` → zero live compat claims

    **Anti-fix note (OBS-P30-2, ADV-P1D-PASS-30 — DURABLE):** `domain-spec/events.md` legitimately omits `run_stream`, `step_start`, `step_end`, and similar wire-taxonomy labels. `events.md` documents domain processing-stages by DDD convention, not the exhaustive wire-event taxonomy; gate #23 step 1 explicitly permits representative subsets in L2. Future passes MUST NOT "fix" `events.md` into duplicating BC-2.06.001's `StreamEvent` authority — BC-2.06.001 is the single wire-taxonomy source of truth. Any attempt to add `run_stream`, `step_start`, or `step_end` labels to `events.md` on the grounds that they are "missing from L2" is incorrect; the omission is intentional.

    Source: ADV-P1D-PASS-29 §F-P29-03, §F-P29-04, §F-P29-05, §OBS-P29-2 [process-gap]; ADV-P1D-PASS-30 §OBS-P30-2.

24. **Pagination coherence census gate — PAGINATION COHERENCE (added P31 — standing gate):**

    Any burst that adds or edits a list/aggregate GET endpoint in `interface-definitions.md`
    MUST perform this census before closing:

    1. **Canonical convention check:** The endpoint row cites F-P31-01 or carries an explicit
       documented exemption with rationale. The canonical convention is: `limit` (default 10,
       max 100; values > 100 silently clamped to 100), `offset` (default 0), results ordered
       `created_at` descending (or endpoint-specific ordering explicitly declared).

    2. **Anchor BC match:** The anchor BC named in the endpoint row's "BC Anchor" column must
       have a matching postcondition that declares the same limit/offset/ordering semantics as
       the interface row. Drift between the interface row and the anchor BC is a gate failure.

    3. **Out-of-range uniformity:** All list endpoints must use the same out-of-range canon:
       **clamp** (not reject). If any BC uses reject-with-E-CORE instead of clamp, that BC
       and this gate note must be updated together. The current canon is clamp (decided
       ADV-P1D-PASS-31 §F-P31-01 — no prior BC stated reject, so clamp was adopted).

    4. **Census commands:**
       - `grep -n "limit" .factory/specs/prd-supplements/interface-definitions.md | grep "GET"` →
         all list endpoint rows carry pagination or explicit exemption.
       - `grep -n "limit\|offset" .factory/specs/behavioral-contracts/ss-12/BC-2.12.004.md` →
         PC7 present with default 10 / max 100 / offset / created_at DESC.
       - `grep -n "limit\|offset" .factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md` →
         PC18 includes limit/offset/clamped/created_at DESC.
       - `grep -n "limit\|offset" .factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md` →
         PC8 includes default 10 / max 100 / values > 100 clamped / offset default 0
         (F-P34-01, ADV-P1D-PASS-34); PC17 includes default 10 / max 100 / clamped / offset.
       - `grep -n "limit\|offset" .factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md` →
         PC21 includes limit (default 10 / max 100 / clamped); PC22 returns
         { assistants: [Assistant], total_count: u64 }; PC23 declares created_at DESC
         (list-assistants anchor, F-P33-01); PC20 present with /versions pagination
         (limit 10/100/clamped/offset 0/version ASC exemption, F-P32-03).

    **Exemption pattern:** If an endpoint legitimately cannot support pagination (e.g., it
    returns a single resource, not a list), document the exemption in the row's description
    with rationale. Endpoints that *do* return arrays but omit pagination are a gate failure.

    Source: ADV-P1D-PASS-31 §F-P31-01 (pagination/query-param coherence — new class).

25. **Summary-arithmetic + criticality-sibling coherence census gate — SUMMARY-ARITHMETIC
    + CRITICALITY-SIBLING COHERENCE (added P32 — standing gate [process-gap]):**

    Any burst that edits a table containing a summary/count section OR edits any
    module-criticality document MUST perform this two-part census before closing:

    **Part A — Summary arithmetic:**
    Any edit to a table that has an associated Summary or Classification Summary section
    (containing module counts, row counts, percentages, or self-summing totals) MUST:
    1. Recount the table rows in the SAME burst — do not trust existing Summary cells.
    2. Reconcile EVERY summary cell (each tier count AND the total) against the row recount.
    3. Update ALL mismatched cells in the same burst. Deferring reconciliation is a gate
       failure.

    Trigger: any row add, row remove, row re-tier, count edit, or percentage edit in a
    table that has a downstream Summary section.

    **Part B — Criticality-sibling coherence (widened P37 — OBS-P37-1 [process-gap]):**
    Any burst that adds, removes, or re-tiers a module in ANY criticality-bearing document MUST
    propagate the change to ALL FOUR sibling documents in the same burst:
    1. `.factory/specs/module-criticality.md` (arch registry — authoritative source of truth post-1b)
    2. `.factory/specs/prd-supplements/module-criticality.md` (PO registry)
    3. `.factory/specs/architecture/module-decomposition.md` (derived — per-module Criticality column
       AND structurally-privileged module-tier headings, e.g., `## <module-name> — <TIER>`)
    4. `.factory/specs/architecture/verification-coverage-matrix.md` (derived — per-tier summary row
       AND per-module table Criticality column)

    Never update any one of these four without verifying all four in the same burst.

    After editing:
    - Apply **Part A** (table/summary reconciliation) to every document you touch.
    - Apply **Gate #26** (Structurally-Privileged-Line Canon Check) to catch stale tier claims
      in H1/H2/H3 headings (e.g., `## ferrochain-macros — MEDIUM` heading in
      module-decomposition.md — the heading is structurally privileged and must match the registry).
    - Run the **Tier agreement census** below across all four documents.

    **Census commands:**
    - Registry rows: count rows per tier in Module Inventory table (arch) → must equal arch
      Summary cells. Count rows per tier in Module Classification table (PO) → must equal PO
      Classification Summary cells; cell self-sum must equal stated Total.
    - Derived-doc module check: for each module in the Criticality column of
      module-decomposition.md and verification-coverage-matrix.md per-module table, verify the
      tier matches module-criticality.md (arch registry). Any mismatch is a HIGH-severity finding.
    - Tier-summary row check: recount rows per tier in verification-coverage-matrix.md per-module
      table → must equal the §Coverage by Criticality Tier summary row (CRITICAL/HIGH/MEDIUM/LOW
      counts and total). Example correct value: 9/12/10/2=33.
    - Structurally-privileged heading check: grep `^##` in module-decomposition.md for
      tier-bearing headings; verify each named module's tier matches module-criticality.md.
      Command: `grep -n "^## " module-decomposition.md | grep -E "CRITICAL|HIGH|MEDIUM|LOW"`

    **Motivating instance (OBS-P37-1):** F-P37-01 and F-P37-02 survived passes 31–36 because
    the original Part B named only the two registry docs — leaving module-decomposition.md and
    verification-coverage-matrix.md unchecked. Specific drift: graph::channels showed CRITICAL in
    module-decomposition.md vs HIGH in module-criticality.md; verification-coverage-matrix.md
    §Coverage by Criticality Tier showed 6/7/5/2=20 while the authoritative count is 9/12/10/2=33
    and the doc's own per-module table enumerated 9 CRITICAL / 11 HIGH rows.

    Source: ADV-P1D-PASS-32 §OBS-P32-3 [process-gap] (original gate — two-registry sibling set);
    ADV-P1D-PASS-37 §OBS-P37-1 [process-gap] (widening — all four criticality-bearing docs added).

26. **Structurally-Privileged-Line Canon Check — STRUCTURALLY-PRIVILEGED-LINE CANON CHECK
    (added P36 — standing gate [process-gap]):**

    Whenever a fix retires or amends a canon claim, the fixer MUST grep structurally-privileged
    lines — markdown H1/H2/H3 headings (especially `## Decision:` in ADRs), Summary cells/blocks,
    and index/registry rows — across the affected document AND its citing documents for the retired
    claim, not just body prose. A fix that updates body paragraphs but leaves the same stale claim
    in a structurally-privileged heading creates first-class misleading artifacts: headings appear
    in file diffs, navigation, and summaries first and are typically the only content reviewers
    absorb when skimming.

    **Trigger:** Every canon-retirement or canon-amendment fix burst.

    **Scope — what counts as a structurally-privileged line:**
    1. H1/H2/H3 headings in the affected document (especially `## Decision:` and `## Summary:` in ADRs)
    2. Summary / Abstract / Synopsis paragraph blocks (first prose paragraph after the title)
    3. Index rows and registry rows that reference the affected artifact:
       BC-INDEX Title column, ARCH-INDEX ADR log Decision-summary column,
       BC-authoring-plan batch-table Title column, VP-INDEX Description column

    **Census commands (run after every canon-retirement fix):**

    Check H1/H2/H3 headings in the affected document for the retired claim:
    ```
    grep -n "^#" <affected-file> | grep "<retired-claim-keywords>"
    ```

    Check ALL spec documents for structurally-privileged lines containing the retired claim:
    ```
    grep -rn "^#.*<retired-claim-keywords>" .factory/specs/
    grep -rn "^| .*<retired-claim-keywords>" .factory/specs/   # index/registry rows
    ```

    **Motivating instances (two occurrences before this gate was added):**
    - **F-P27-02 (ADV-P1D-PASS-27):** A fix updated body prose but left a stale canon claim in a
      structurally-privileged summary or heading line. First observed instance.
    - **F-P36-01 (ADV-P1D-PASS-36):** `ADR-006-streaming-event-taxonomy.md` `## Decision:` heading
      retained "JSON-serialized to LangGraph format over HTTP" after F-P29-05 corrected the body
      to ferrochain-native wire format (D13). The heading was not re-read by any prior fix pass
      across 7 subsequent adversarial reviews.

    **Anti-pattern to prevent:** Fix the body paragraphs, close the burst, leave the heading unchanged.
    The heading is the privileged summary of the decision — it propagates through git diffs, PR
    descriptions, and table-of-contents navigation. Stale headings outlive stale prose.

    Source: ADV-P1D-PASS-27 §OBS-P27-2 (motivating predecessor); ADV-P1D-PASS-36 §OBS-P36-2 [process-gap].

27. **Architecture-anchor crate-resolution census gate — ARCH-ANCHOR CRATE-RESOLUTION CENSUS
    (added P42 — standing gate [process-gap]):**

    Every `ferrochain-<crate>/src/...` path (and `xtask/` path) appearing in any BC's
    `## Architecture Anchors` section must satisfy two conditions:

    1. **Roster membership:** The crate name must exist in the ADR-007 18-crate roster (+xtask).
       Crate names not in the roster are invalid regardless of whether the file exists.
    2. **Ownership correctness:** The module cited must be owned by the named crate per
       `module-decomposition.md` responsibilities and ADR-007 crate responsibility descriptions.
       A path that uses a VALID crate name but assigns a module owned by a DIFFERENT crate is a
       wrong-crate assignment and is a HIGH-severity error.

    **ADR-007 18-crate roster (authoritative):** ferrochain, ferrochain-core, ferrochain-graph,
    ferrochain-checkpoint, ferrochain-openai, ferrochain-anthropic, ferrochain-ollama,
    ferrochain-community, ferrochain-splitters, ferrochain-mcp, ferrochain-standard-tests,
    ferrochain-server, ferrochain-sandbox, ferrochain-memory, ferrochain-macros,
    ferrochain-openai-sdk, ferrochain-anthropic-sdk, ferrochain-ollama-sdk. Plus: xtask.

    **Key ownership rules (from module-decomposition.md):**
    - StateGraph builder (`add_node`, `add_edge`, `compile`, `graph::definition`) → **ferrochain-graph**
    - BSP engine, HITL, channels, scheduler, budget, provenance → **ferrochain-graph**
    - Runnable trait, Message types, error taxonomy, credentials, events, config, retry → **ferrochain-core**
    - Proc-macro implementations (`#[tool]`, `#[entrypoint]`, `#[task]`) → **ferrochain-macros**
    - Re-exported macro trait hooks (e.g., `Tool` re-export) → **ferrochain-core** (defensible re-export)
    - CheckpointSaver, session index, logical clock, lineage, encryption → **ferrochain-checkpoint**

    **Census command:**
    ```
    grep -rh "## Architecture Anchors" --include="*.md" -A 10 .factory/specs/behavioral-contracts/ \
      | grep "ferrochain-" | grep -oE "ferrochain-[a-z-]+" | sort -u
    ```
    Verify each extracted crate name against the 18-crate roster. Then for any path containing
    `/src/`, verify module ownership against module-decomposition.md.

    **Quick wrong-crate check (run after any BC anchor edit):**
    ```
    grep -rn "ferrochain-core/src/graph\|ferrochain-core/src/channels\|ferrochain-core/src/pregel\
    \|ferrochain-core/src/hitl\|ferrochain-core/src/bsp\|ferrochain-core/src/budget\
    \|ferrochain-core/src/provenance\|ferrochain-core/src/scheduler" \
    .factory/specs/behavioral-contracts/
    ```
    Output must be EMPTY (zero hits). These are graph-owned modules incorrectly placed in core.

    **Trigger:** Every burst that adds or edits BC Architecture Anchors + every adversary rotation.
    Running the full census on every adversary rotation prevents wrong-crate anchors from surviving
    multiple passes.

    **Exemptions:** Paths marked `(to be created)` or `[architect to assign]` with a plausible
    crate ownership (i.e., the module name is consistent with the crate's scope) are accepted.
    Paths marked `(to be created)` with wrong-crate assignment are NOT exempt — the wrong-crate
    error is independent of whether the file exists.

    **Motivating instance:** F-P42-01 (ADV-P1D-PASS-42) — BC-2.08.011 line 112 and BC-2.08.012
    line 119 cited `ferrochain-core/src/graph/builder.rs` for the StateGraph builder (`add_edge`,
    `add_node`). The StateGraph builder is owned by `ferrochain-graph` per ADR-007, module-decomp
    `graph::definition`, and BC-2.02.001 Architecture Anchors. This wrong-crate anchor survived
    41 passes because gate #13 (anchor-matrix census) covers Traceability column cells, not the
    free-text `## Architecture Anchors` bullet section. Gate #27 closes this blind spot.

    Source: ADV-P1D-PASS-42 §F-P42-01 [process-gap].

---

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.5 | 2026-07-14 | Gate #27 "architecture-anchor crate-resolution census" added; `total_standing_gates` 26→27. Full gate-#27 census run across all 86 BCs × 187 Architecture Anchor crate paths: 16 distinct crate names found (all valid per ADR-007 roster); exactly 2 wrong-crate anchors found and fixed (BC-2.08.011 line 112 and BC-2.08.012 line 119: `ferrochain-core/src/graph/builder.rs` → `ferrochain-graph/src/graph/state.rs`). Zero remaining wrong-crate anchors after fixes. (F-P42-01 [process-gap], ADV-P1D-PASS-42) | F-P42-01 |
| 1.4 | 2026-07-14 | (1) F-P40-01: Batch 9 BC-2.08.007 DI cell corrected `DI-014` → `DI-009, DI-014` (body + BC-INDEX + DI-coverage table all show DI-009; batch-table was the sole outlier). (2) Full batch-table anchor sweep (86 rows vs BC-INDEX): 8 corrections — BC-2.08.001–005 CAP `CAP-009, CAP-011` → `CAP-009` (body capability: CAP-009; CAP-011 spurious); BC-2.10.004 CAP `CAP-012, CAP-006` → `CAP-012` (body primary capability: CAP-012); BC-2.05.006 DI `DI-003, ASM-008` → `DI-003` (ASM-008 is an assumption reference, not a domain invariant). Zero remaining anchor drifts vs BC-INDEX after fixes. (3) Gate #13 widened from four-way to five-way consistency check: bc-authoring-plan batch-table CAP/DI columns added as fifth verified carrier; motivating instance F-P40-01 cited (OBS-P40-1, ADV-P1D-PASS-40) | F-P40-01, OBS-P40-1 |
| 1.3 | 2026-07-14 | Reconciled batch-size constraint with Batch 9 Step-E exception: amended line-27 prose to document BC-2.08.009 exception per ADR-004 acceptance; updated Summary metric "BCs per batch (max)" from `8` to `9 (Batch 9 only — Step-E exception; planning cap remains 8)`; three statements (prose, metric, Batch 9 header) now mutually coherent (F-P39-02, ADV-P1D-PASS-39) | F-P39-02 |
| 1.2 | 2026-07-14 | Gate #25 Part B widened from 2-registry to 4-document sibling set: added module-decomposition.md (derived Criticality column + tier headings) and verification-coverage-matrix.md (derived tier summary + per-module table) as required census targets; extended census commands accordingly (OBS-P37-1 [process-gap], ADV-P1D-PASS-37) | OBS-P37-1 |
| 1.1 | 2026-07-16 | Added standing gate #26 "Structurally-Privileged-Line Canon Check"; added `total_standing_gates: 26` to frontmatter (F-P36-03/OBS-P36-2 codification, ADV-P1D-PASS-36) | OBS-P36-2 |
| 1.0 | 2026-07-13 | Initial authoring | Greenfield Phase 1a |
