---
document_type: adr
level: L3
adr_id: "003"
slug: durability-tiers
title: "Checkpoint Durability Tiers: Sync Default, Async and Exit-Only Opt-In"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D11]
supersedes: []
---

# ADR-003: Checkpoint Durability Tiers

**Status:** Accepted

## Context

LangGraph Python supports three checkpoint durability modes: synchronous (writes before
next super-step), asynchronous (background writes), and exit-only (write only on clean exit).
D11.3 adopted all three tiers, with ferrochain defaulting to sync.

## Decision: Three-Tier Model, Sync Default

**Tiers:**

| Tier | Default | Guarantee | BC Anchor |
|------|---------|-----------|-----------|
| `Sync` | YES | `put_writes` completes before next super-step begins | BC-2.04.001, BC-2.04.002 |
| `Async` | no | Background write; super-step may start before write confirms | BC-2.04.002 |
| `ExitOnly` | no | Writes only on clean graph exit (no crash safety) | BC-2.04.002 |

**Rationale for sync default:**
- Domain B (dark factory multi-day runs) depends on crash recovery (BC-2.04.005).
- NE-11/adk-rust step-boundary-only checkpoint is a documented failure mode: completed tasks are re-executed after crash. Sync default eliminates this class of bugs by construction.
- Performance overhead of sync writes is acceptable: SQLite WAL mode provides < 1ms typical write latency; graph nodes are async and the overhead is masked by node execution time.
- Teams that explicitly need throughput over durability can opt into `Async`.

**API surface:**

```rust
pub enum DurabilityTier { Sync, Async, ExitOnly }
pub struct CheckpointSaverConfig { pub tier: DurabilityTier }
impl Default for CheckpointSaverConfig {
    fn default() -> Self { Self { tier: DurabilityTier::Sync } }
}
```

**Crash recovery contract (BC-2.04.005):** After process restart, the graph resumes
from the last committed super-step. Tasks that had their `put_writes` committed are
not re-executed. Tasks whose `put_writes` had not yet committed are re-executed from
the start of the interrupted super-step.

## Consequences

- `CheckpointSaver::put_writes` is `async` — caller awaits before advancing super-step (Sync tier).
- Async tier: `put_writes` spawns a background Tokio task; returns immediately; graph continues. No durability guarantee.
- ExitOnly: writes are buffered in memory; flushed on `GraphState::finish()`.
- The SQL schema uses a `durability_tier` column to record which tier was active when a checkpoint was written (for post-crash analysis).
