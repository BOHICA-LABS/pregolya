---
document_type: wave-schedule
level: ops
version: "1.0"
status: active
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs: [STORY-INDEX.md, dependency-graph.md]
input-hash: "cb744c4"
traces_to: STORY-INDEX.md
---

# Wave Schedule: pregolya

## Summary

| Metric | Value |
|--------|-------|
| Total stories | 39 |
| Total waves | 3 (Wave 1, Wave 2, Wave 6) |
| Max parallelism (groups per wave) | 7 groups in Wave 1 / sub-batch 1e |
| Estimated agent spawns | 39 implementer agents total |

## Wave Plan

> **Priority axis (D7):** pregolya-core → pregolya-graph → partners → remaining.
> Stories in the same group have no inter-story dependencies and can be dispatched
> to separate implementer agents concurrently. Sub-batches reflect topological ordering
> within each wave.

### Wave 1 (no cross-wave dependencies)

#### Sub-batch 1a — pregolya-core root

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.01 | 5 | S | 1 story/agent |

#### Sub-batch 1b — pregolya-core tier 1 + pregolya-splitters (depends on S-1.01)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.02 | 5 | S | 1 story/agent |
| B | S-1.03 | 5 | S | 1 story/agent |
| C | S-1.08 | 8 | M | 1 story/agent |

#### Sub-batch 1c — pregolya-core Runnable + pregolya-sandbox (depends on 1b)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.04 | 5 | S | 1 story/agent |
| B | S-1.09 | 13 | XL | 1 story/agent |

#### Sub-batch 1d — Dependent crates tier 1 (depends on 1c)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.05 | 8 | M | 1 story/agent |
| B | S-1.06 | 5 | S | 1 story/agent |
| C | S-1.07 | 5 | S | 1 story/agent |
| D | S-1.10 | 13 | XL | 1 story/agent |
| E | S-1.12 | 8 | M | 1 story/agent |
| F | S-1.14 | 8 | M | 1 story/agent |

#### Sub-batch 1e — Dependent crates tier 2 + graph tier 1 (depends on 1d) — max parallelism

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.11 | 3 | XS | 1 story/agent |
| B | S-1.13 | 8 | M | 1 story/agent |
| C | S-1.15 | 5 | S | 1 story/agent |
| D | S-1.17 | 5 | S | 1 story/agent |
| E | S-1.18 | 8 | M | 1 story/agent |
| F | S-1.19 | 13 | XL | 1 story/agent |
| G | S-1.21 | 8 | M | 1 story/agent |

#### Sub-batch 1f — BSP engine + Bash tool (depends on 1e)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.16 | 13 | XL | 1 story/agent |
| B | S-1.22 | 8 | M | 1 story/agent |

#### Sub-batch 1g — HITL core + server CRUD (depends on 1f)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.20 | 13 | XL | 1 story/agent |
| B | S-1.26 | 8 | M | 1 story/agent |

#### Sub-batch 1h — PreToolCallHook + server security config (depends on 1g)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.23 | 5 | S | 1 story/agent |
| B | S-1.27 | 8 | M | 1 story/agent |

#### Sub-batch 1i — Approval + compaction events (depends on S-1.23, S-1.17, S-1.18)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.24 | 5 | S | 1 story/agent |

#### Sub-batch 1j — Compaction execution (depends on S-1.10, S-1.18, S-1.24)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-1.25 | 5 | S | 1 story/agent |

---

### Wave 2 (depends on Wave 1 merge)

#### Sub-batch 2a — Wave 2 roots (parallel)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-2.01 | 13 | XL | 1 story/agent |
| B | S-2.04 | 8 | M | 1 story/agent |
| C | S-2.06 | 3 | XS | 1 story/agent |

#### Sub-batch 2b — Wave 2 second tier (parallel)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-2.02 | 8 | M | 1 story/agent |
| B | S-2.05 | 8 | M | 1 story/agent |
| C | S-2.07 | 13 | XL | 1 story/agent |
| D | S-2.09 | 8 | M | 1 story/agent |

#### Sub-batch 2c — Wave 2 third tier (parallel)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-2.03 | 8 | M | 1 story/agent |
| B | S-2.08 | 8 | M | 1 story/agent |
| C | S-2.10 | 8 | M | 1 story/agent |

#### Sub-batch 2d — MCP server (depends on S-2.10)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-2.11 | 5 | S | 1 story/agent |

---

### Wave 6 (depends on Wave 1 + Wave 2 merge)

| Group | Stories | Points | Complexity | Agent Scope |
|-------|---------|--------|-----------|-------------|
| A | S-6.01 | 8 | M | 1 story/agent |

---

## Pipeline Overlap Plan

| Parallel Activity | When |
|------------------|------|
| Wave 1 stubs (pregolya-core) | Start at Phase 3 kickoff |
| Wave 1 stubs (pregolya-checkpoint, pregolya-sandbox, pregolya-splitters, pregolya-macros, pregolya-memory) | Start when pregolya-core types compile (after S-1.04 merges) |
| Wave 1 stubs (pregolya-graph) | Start when pregolya-core + pregolya-checkpoint types compile (after S-1.10 merges) |
| Wave 1 stubs (pregolya-tools, pregolya-server) | Start when pregolya-sandbox + pregolya-graph types compile |
| Wave 2 stubs (all Wave 2 crates) | Start when Wave 1 stories S-1.01 through S-1.22 are merged and crate types stable |
| Wave 2 implementation | Start after Wave 1 Red Gate fully verified and develop HEAD stable |
| Wave 6 Kani harnesses | Harness skeletons authored in S-6.01 spec; execution starts after all Wave 1+2 crates merged |
| VP proptest targets (VP-007, VP-008, VP-014) | Authored in their anchor stories (S-2.01, S-2.09, S-1.05); run at Phase 3 alongside TDD |
| VP integration tests (VP-004, VP-005) | Authored in S-2.10; run at Phase 3 with in-process mock server (SID-1 compliant) |

## Critical Path

> The critical path is the longest chain of sequentially-dependent **implementation stories**
> (Wave 1 + Wave 2). S-6.01 (Phase-6 formal-verification terminal aggregator) is excluded from
> this measurement: it depends on nearly all implementation stories by design and would trivially
> dominate any chain, making critical-path analysis uninformative for implementation scheduling.
> Total: **S-1.01 → S-1.03 → S-1.04 → S-1.14 → S-1.15 → S-1.16 → S-1.20 → S-1.23 → S-1.24 → S-1.25**
> = 10 stories, 69 points.

| Sequence Position | Story | Points | Depends On |
|------------------|-------|--------|-----------|
| 1 | S-1.01 | 5 | — |
| 2 | S-1.03 | 5 | S-1.01 |
| 3 | S-1.04 | 5 | S-1.03, S-1.02 |
| 4 | S-1.14 | 8 | S-1.04 |
| 5 | S-1.15 | 5 | S-1.14 |
| 6 | S-1.16 | 13 | S-1.14, S-1.15, S-1.10, S-1.13 |
| 7 | S-1.20 | 13 | S-1.16, S-1.17, S-1.10 |
| 8 | S-1.23 | 5 | S-1.20, S-1.17 |
| 9 | S-1.24 | 5 | S-1.23, S-1.17, S-1.18 |
| 10 | S-1.25 | 5 | S-1.10, S-1.18, S-1.24 |

**Critical path total: 69 points across 10 sequential stories.**
Note: S-1.10 (checkpoint) and S-1.17/S-1.18 (streaming events / budget) are in parallel with the
critical path backbone (nodes 4–7) but both feed into the critical path at S-1.16 and S-1.20.
Their implementation should be co-scheduled with the S-1.14 batch to avoid becoming the
actual critical path constraint.

## Crate Implementation Order

> Respects D7 priority: pregolya-core → pregolya-graph → partners → remaining.

| Tier | Crate | Wave | Notes |
|------|-------|------|-------|
| 1 | pregolya-core | 1 | Foundation; no deps |
| 2 | pregolya-splitters | 1 | Parallel with tier 2 |
| 2 | pregolya-sandbox | 1 | Parallel with tier 2 |
| 2 | pregolya-checkpoint | 1 | Parallel with tier 2 |
| 2 | pregolya-memory | 1 | Parallel with tier 2 |
| 2 | pregolya-macros | 1 | Parallel with tier 2 |
| 3 | pregolya-graph | 1 | D7 priority 2 |
| 4 | pregolya-tools | 1 | Dep sandbox + macros |
| 5 | pregolya-server | 1 | Dep graph + checkpoint |
| 6 | pregolya-vectorstores | 2 | Wave 2; no internal pregolya-* deps |
| 6 | pregolya-prompts | 2 | Wave 2; no internal pregolya-* deps |
| 6 | pregolya-openai-sdk | 2 | D17-Q5 wire client; no pregolya-core dep (builds before adapter) |
| 6 | pregolya-anthropic-sdk | 2 | D17-Q5 wire client; no pregolya-core dep (builds before adapter) |
| 6 | pregolya-ollama-sdk | 2 | D17-Q5 wire client; no pregolya-core dep (builds before adapter) |
| 7 | pregolya-openai | 2 | D7 partners priority; dep openai-sdk (tier 6) |
| 7 | pregolya-anthropic | 2 | D7 partners priority; dep anthropic-sdk (tier 6) |
| 7 | pregolya-ollama | 2 | D7 partners priority; dep ollama-sdk (tier 6) |
| 7 | pregolya-standard-tests | 2 | Shared test infra for providers |
| 8 | pregolya-mcp | 2 | Dep tools + graph |
| 9 | xtask (formal) | 6 | Terminal — all crates compiled |
| — | pregolya (facade) | v1 (incremental) | Re-export-only umbrella; Cargo.toml stub scaffolded at workspace init (namespace reservation); `pub use` re-exports assembled incrementally as member-crate stories land; no dedicated story (ADR-007 §Consequences) |
| — | pregolya-community | post-v1 | Zero v1 scope per ADR-007 + ARCH-INDEX roster; no v1 stories target this crate |
