---
document_type: behavioral-contract
level: L3
bc_id: BC-2.02.004
version: "1.2"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-02
capability: CAP-003
wave: 1
phase: 1a
red_gate: true
red_gate_source: R10
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-graph per module-decomposition.md v1.10."
  - "1.2 (F-P140-01, 2026-07-23): Fix burst 240 Wave 2 — sweep stale pregel/*.rs Architecture Anchor file-path references to canonical flat graph:: layout per ADR-001 / module-decomposition v1.21."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-003
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/semport/graph/behavioral-intent.md
input-hash: "291e48b"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.02.004: EphemeralValue Cleared-After-Super-Step Semantics (Red Gate — R10)

> **Red Gate test required.** A test for this contract must compile and FAIL (i.e.,
> the read-in-next-step returns a non-absent value) before the `EphemeralValue`
> implementation begins. This is a D17-Q9 Phase-1 mandatory Red Gate per R10: the
> upstream LangGraph reference has no focused unit test confirming that an `EphemeralValue`
> is absent in the step following its write (DEC-004). The test must be authored first
> and checked into the repository in a failing state.

## Description

`EphemeralValue` is a channel type with a one-step lifetime: a value written in super-step
N is available only to nodes scheduled to read it in super-step N. In super-step N+1, that
same channel reads as absent (`None` or `Option::None`); the value is not persisted to the
checkpoint and is not carried forward across step boundaries. This cleared-after-step
semantic distinguishes `EphemeralValue` from `LastValue` (which persists the last write
indefinitely) and is a critical correctness property for transient pass-through signals
such as `Send.arg` routing payloads and single-step coordination values. The value is also
explicitly excluded from checkpoint serialization (`UntrackedValue` semantics apply to
`EphemeralValue` for persistence purposes).

## Preconditions

1. A `StateGraph` is compiled with a channel of type `EphemeralValue<T>`.
2. In super-step N, at least one node writes a value `v` to the ephemeral channel.
3. A node scheduled to run in super-step N+1 reads the same channel.

## Postconditions

1. In super-step N, the ephemeral channel holds `Some(v)` and is available to nodes
   triggered in that step; those nodes observe the value `v`.
2. After super-step N completes (after `apply_writes` and `after_tick`), the ephemeral
   channel is cleared; its value becomes absent (`None`) for super-step N+1.
3. In super-step N+1, any node reading the channel observes `None` / the absence of a
   value; it does NOT observe `v` from the previous step.
4. The ephemeral value is NOT serialized to the checkpoint at the super-step boundary;
   inspecting the checkpoint metadata for super-step N shows the ephemeral channel absent
   or as a sentinel indicating cleared state.
5. After a process restart (restore from checkpoint for step N), the ephemeral channel
   is absent; the channel does not retain the value from the pre-restart step.

## Invariants

- `EphemeralValue` is a one-step channel: its lifetime is exactly the duration of the
  super-step in which it is written.
- The cleared state is the default: at the start of each super-step, `EphemeralValue`
  channels begin absent unless written in that step.
- A write to an `EphemeralValue` in step N does not trigger nodes in step N+1 (the
  channel's channel_version does not propagate across the step boundary as a new write).

## Edge Cases

### EC-001: EphemeralValue read in same step as write — value is present
**Scenario:** Node A writes `v` to an `EphemeralValue` channel in step N. Node B, also
scheduled in step N, reads the same channel.
**Expected behavior:** Node B observes `Some(v)` within step N. This is the intended
in-step usage. This confirms the value IS available within the originating step.

### EC-002: EphemeralValue read in step N+1 — value is absent (Red Gate vector)
**Scenario:** Node A writes `v` to `EphemeralValue` in step N. In step N+1, node B is
triggered (via a separate channel) and reads the ephemeral channel.
**Expected behavior:** Node B observes `None` (absent). Value `v` is not present.
**This is the Red Gate vector** — must fail before implementation.

### EC-003: EphemeralValue not written in a step — channel is absent
**Scenario:** A step completes without any node writing to the `EphemeralValue` channel.
A node in that step reads the channel.
**Expected behavior:** The channel is absent (`None`); no value is observed. No error.

### EC-004: Checkpoint inspection after EphemeralValue write
**Scenario:** After step N writes an ephemeral value, the checkpoint is inspected.
**Expected behavior:** The checkpoint's `channel_values` for the ephemeral channel is
absent or shows a cleared-sentinel; the value `v` is not serialized into the checkpoint.
Restoring from this checkpoint in a fresh process yields the ephemeral channel absent.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Node A writes `42` to `EphemeralValue<i64>` in step N; node B reads same channel in step N | Node B observes `Some(42)` | In-step availability — happy path |
| TV-002 | Node A writes `42` in step N; step N+1 has node C reading same channel | Node C observes `None` | **Red Gate vector** — must fail before implementation |
| TV-003 | Step N: no writes to ephemeral channel; node reads it | `None` observed | Absent-by-default |
| TV-004 | Checkpoint snapshot after step N where `42` was written to ephemeral channel | Checkpoint `channel_values` does not contain `42` for that channel | Not persisted to checkpoint |
| TV-005 | Restore from step-N checkpoint in new process; read ephemeral channel | `None` | No persistence across process restart |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-EPHEM-01 | EphemeralValue is absent in step N+1 regardless of step-N write | Red Gate test (compile+fail), then integration test | Phase 1 |
| VP-EPHEM-02 | EphemeralValue is not serialized into checkpoint | Integration test (inspect checkpoint channel_values) | Phase 1 |

## Related BCs

- BC-2.02.002 — sibling: LastValue (persists indefinitely) is the complementary channel type
- BC-2.02.003 — sibling: NamedBarrierValue also has step-scoped availability semantics (R10 Red Gate)
- BC-2.04.001 — related: checkpoint serialization contract (put_writes) does not include EphemeralValue
- BC-2.02.006 — related: Send.arg may be channeled through an EphemeralValue-like mechanism for task routing

## Architecture Anchors

- `pregolya-graph/src/channels/ephemeral.rs` — `EphemeralValue<T>` channel type
- `pregolya-graph/src/bsp_engine.rs` (`graph::bsp_engine`) — `finish()` call on all channels at step end (triggers ephemeral clear)
- `pregolya-checkpoint/src/base.rs` — `UntrackedValue` / exclusion from checkpoint serialization

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-EPHEM-01, VP-EPHEM-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-003 |
| Capability Anchor Justification | CAP-003 ("StateGraph Definition (Nodes, Edges, Channels, Reducers)") per capabilities-p0.md §CAP-003 — `EphemeralValue` is explicitly listed by name in CAP-003's channel type inventory; this BC specifies its cleared-after-step semantics, which is the defining behavioral property of the type |
| L2 Domain Invariants | — |
| D17 Commitment | D17-Q9 — R10 Red Gate test required (EphemeralValue cleared-after-step has no upstream focused unit test) |
| DEC Reference | DEC-004 (EphemeralValue Read After Super-Step) |
| Risk Source | R10 (upstream LangGraph has no unit test for EphemeralValue cross-step absence) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), Red Gate |
| Module | pregolya-graph |
