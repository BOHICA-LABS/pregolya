---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.002
version: "1.4"
status: active
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/L2-INDEX.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "767bd41"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-04
capability: CAP-005
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-4): category canon sweep — EC-003 and test vector error category corrected from `ConfigError` to `VAL` (13-category sweep, F-P4-xx)."
  - "1.2 (ADV-P1D-PASS-56-COMPLETION): Gate #30 second-pass census — EC-003 had `Err(FerrochainError { category: VAL, message: ... })` and the durability-string-turbo TV row had `Err(FerrochainError { category: VAL })` with no code. Added code: E-CORE-005 (ValidationFailed) — unknown durability tier string is a VAL construction-time failure at run start."
  - "1.3 (F-P112-02, 2026-07-18): E-CORE-005 message canonicalization. EC-003 message reworded from 'unknown durability tier: \"<value>\"' to 'Validation failed for 'durability': unknown tier \"<value>\"' to conform to canonical E-CORE-005 taxonomy format (Validation failed for '<field>': <reason>). TV bare form unchanged — PASS-ABBREV via EC-003."
  - "1.4 (2026-07-19, F-P114-01 anchor-class sweep, burst 117): Architecture Anchors updated from nonexistent 'architecture/ferrochain-checkpoint.md' to 'architecture/decisions/ADR-003-durability-tiers.md' — DurabilityTier enum, CheckpointSaverConfig::default(), Sync-default rationale. No BC body content changed."
modified: []
extracted_from: null
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
priority: P0
wave: 1
d17_commitment: Q3
---

# BC-2.04.002: Sync Durability Tier Is Default; Async and Exit Are Explicit Opt-In

## Description

The default durability tier for any compiled graph invocation is `DurabilityTier::Sync`:
per-task `put_writes` are awaited to storage confirmation before each super-step boundary.
The `Async` and `Exit` tiers are explicit opt-in values that must be passed in `RunnableConfig`
at the call site. This guarantees that crash-safe semantics hold by default without any
developer ceremony — the unsafe faster modes require a deliberate choice.

## Preconditions

1. A `CompiledStateGraph` is invoked with a `RunnableConfig`
2. The `RunnableConfig` either omits the `durability` field or explicitly specifies one of
   `DurabilityTier::Sync`, `DurabilityTier::Async`, or `DurabilityTier::Exit`

## Postconditions

1. If `durability` is absent from `RunnableConfig`, the effective tier is `DurabilityTier::Sync`
2. With `Sync`: every `put_writes` call is fully awaited before the next super-step begins;
   a crash after K task completions loses no writes for those K tasks
3. With `Async`: `put_writes` is submitted as a background future; the loop proceeds; futures
   are joined before the run exits; a crash before join may lose the last in-flight write
4. With `Exit`: `put_writes` is not called mid-run; only a final `put` on graph exit; a
   mid-run crash loses all task-level writes from the current run

## Invariants

1. `DurabilityTier::Sync` is the default variant; it requires no explicit configuration
2. The default cannot be overridden by an environment variable alone — it requires explicit
   code at the call site
3. No internal ferrochain code path changes the effective durability tier without passing
   it through the `RunnableConfig` channel
4. The `DurabilityTier` type is not `Default`-derivable to some other variant; the only
   place a default is injected is at `RunnableConfig` resolution

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Caller passes `DurabilityTier::Async` explicitly | Accepted; `put_writes` submitted as futures; loop does not block on each task's write; futures joined on run exit |
| EC-002 | Caller passes `DurabilityTier::Exit` explicitly | Accepted; zero `put_writes` mid-run; single `put` on graph exit; fastest, no crash recovery within a run |
| EC-003 | `durability` field present in config but set to an unrecognized string | `Err(FerrochainError { category: VAL, code: E-CORE-005, message: "Validation failed for 'durability': unknown tier \"<value>\"" })` at run start |
| EC-004 | Subgraph nested inside a root graph; no explicit durability on subgraph | Subgraph inherits parent's effective durability tier via `RunnableConfig` propagation |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `graph.invoke(input, RunnableConfig::default())` | Effective tier = `Sync`; each task's `put_writes` awaited to storage before next super-step; verified by timing storage queries | happy-path |
| `graph.invoke(input, config.with_durability(DurabilityTier::Async))` | Effective tier = `Async`; background futures dispatched; throughput higher than Sync; all futures confirmed on run exit | edge-case |
| `graph.invoke(input, config.with_durability(DurabilityTier::Exit))` | Effective tier = `Exit`; no `put_writes` during run; storage shows zero pending-writes records mid-run; one `put` record on exit | edge-case |
| `graph.invoke(input, config.with_durability_str("turbo"))` | `Err(FerrochainError { category: VAL, code: E-CORE-005 })` at run start; no execution | error |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.04.002-A | For all invocations without explicit durability, effective tier equals Sync | proptest |
| VP-2.04.002-B | Effective tier never differs from the value in RunnableConfig (no hidden override) | code review / lint gate |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-005 |
| Capability Anchor Justification | CAP-005 ("Durable Three-Tier Checkpointing (Sync Default; Per-Task put_writes)") per capabilities-p0.md §CAP-005 |
| L2 Domain Invariants | DI-002 (Per-Task Durability (Sync Default)) |
| Source Analysis | semport/graph/behavioral-intent.md §5.1 (three durability modes); CONFLICT-2 recommendation (sync as crash-safe default) |
| Binding Decisions | D11.3 (all three durability tiers; ferrochain defaults to sync), D17-Q3 (Phase-1 BC commitment) |
| Architecture Module | ferrochain-checkpoint (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.04.001 — composes with: per-task put_writes is what Sync durability uses
- BC-2.04.005 — composes with: crash recovery depends on Sync being the default

## Architecture Anchors

- `architecture/decisions/ADR-003-durability-tiers.md` — `DurabilityTier` enum, `CheckpointSaverConfig::default()`, Sync-default rationale

## Story Anchor

S-N.MM — Durability tier default and opt-in (filled by story-writer)

## VP Anchors

- VP-2.04.002-A — default Sync invariant (proptest)
