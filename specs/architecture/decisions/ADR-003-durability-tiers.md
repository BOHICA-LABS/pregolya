---
document_type: adr
level: L3
adr_id: "003"
slug: durability-tiers
title: "Checkpoint Durability Tiers: Sync Default, Async and Exit-Only Opt-In"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
date: "2026-07-14"
subsystems_affected: ["SS-04"]
supersedes: []
superseded_by: null
version: "1.1"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D11]
changelog:
  - "1.1 (burst-288/F-P177-LOW-date/2026-08-15): Add missing frontmatter fields (date, subsystems_affected, superseded_by); add Rationale, Alternatives Considered, Source / Origin sections per ADR template (LOW finding: date boundary conditions)."
  - "1.0 (D11/2026-07-14): Initial ADR — three-tier checkpoint durability model (Sync default, Async opt-in, ExitOnly opt-in) per D11.3."
---

# ADR-003: Checkpoint Durability Tiers

**Status:** Accepted

## Context

LangGraph Python supports three checkpoint durability modes: synchronous (writes before
next super-step), asynchronous (background writes), and exit-only (write only on clean exit).
D11.3 adopted all three tiers, with pregolya defaulting to sync.

## Decision

Adopt a three-tier durability model for `pregolya-checkpoint`, with Sync as the default:

| Tier | Default | Guarantee | BC Anchor |
|------|---------|-----------|-----------|
| `Sync` | YES | `put_writes` completes before next super-step begins | BC-2.04.001, BC-2.04.002 |
| `Async` | no | Background write; super-step may start before write confirms | BC-2.04.002 |
| `ExitOnly` | no | Writes only on clean graph exit (no crash safety) | BC-2.04.002 |

## Rationale

- Domain B (dark factory multi-day runs) depends on crash recovery (BC-2.04.005).
- CONFLICT-2 (P-29)/adk-rust step-boundary-only checkpoint is a documented failure mode: completed tasks are re-executed after crash. Sync default eliminates this class of bugs by construction.
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

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| Sync-only (no tier choice) | Insufficient for high-throughput use cases where callers explicitly trade durability for throughput; D11.3 explicitly specified opt-in tiers. |
| Async-default | Domain B and crash recovery requirements (BC-2.04.005) require sync durability as the safe default. Async-default would require every caller to explicitly opt into sync, which is error-prone. |
| ExitOnly-as-default | Unacceptable for multi-day runs — a crash would lose all intermediate progress. |

## Source / Origin

- **Decision mandate:** D11.3 — three-tier checkpoint durability model (Sync default, Async and ExitOnly opt-in).
- **BC traceability:** BC-2.04.001, BC-2.04.002 (tier guarantees), BC-2.04.005 (crash recovery contract).
- **Authoring context:** D11 design session (2026-07-14); pregolya Phase 1a.
