---
document_type: behavioral-contract
level: L3
bc_id: BC-2.17.002
version: "1.3"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P2
subsystem: SS-17
capability: CAP-019
wave: Phase-6
phase: 1a
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.1 (F-P80-01, 2026-07-15): EC-002 error code corrected E-GRAPH-007→E-GRAPH-008. E-GRAPH-007 is UnknownChannelKey (runtime unregistered-write-key error); the correct code for a zero-node degenerate topology is E-GRAPH-008 UnreachableGraph (no path from START). Message aligned to taxonomy form: UnreachableGraph: <reason>. 'or similar' hedge removed from code assertion — exact E-GRAPH-008 is now required; message-detail flexibility preserved per fuzz-oracle semantics (oracle tests code discriminant, not message text)."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to fuzz/ per module-decomposition.md v1.10."
  - "1.3 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. EC-002 had `Err(FerrochainError { code: E-GRAPH-008 })` with message only in prose (not in the struct); E-GRAPH-008 has <reason> placeholder. Inlined the example message from the prose into the struct as the authoritative concrete form; fuzz oracle semantics note retained (oracle tests code discriminant, not message text)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-019
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "41095ca"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.17.002: cargo-fuzz Targets — Serialization Round-Trip (Checkpoint) and Graph-Execution Paths

## Description

The ferrochain Phase-6 formal hardening must include two cargo-fuzz targets covering the
highest-complexity code paths: checkpoint state serialization (msgpack round-trip) and
graph-execution path variation (node topology and concurrent writer patterns). Fuzzing
is complementary to Kani — Kani proves invariants over a bounded state space; fuzzing
explores crash surfaces across arbitrary inputs for extended durations. Both are required
for v1 convergence per CAP-019.

> **Phase anchor (OQR-3):** This BC specifies the cargo-fuzz target scope. The fuzz
> corpus and harness files are Phase-6 delivery artifacts. Phase-1 passes when this BC
> exists and is approved. Phase-6 passes when both fuzz targets compile and run for the
> minimum required corpus expansion without crashes.

## Preconditions

1. Phase-3 implementation of ferrochain-checkpoint and ferrochain-graph is complete.
2. `cargo-fuzz` is available in the CI toolchain (the devops-engineer provisions this in
   Phase-0 toolchain setup).
3. The msgpack serialization layer for `GraphState` and checkpoint structures is
   implemented and passing Phase-3 tests.

## Postconditions

1. **Fuzz Target 1 — Checkpoint Serialization Round-Trip:**
   - Target name: `fuzz_checkpoint_serde`
   - Input: arbitrary byte sequence from the fuzzer
   - Contract: deserializing an arbitrary byte sequence into a `GraphState` MUST NOT panic;
     it must return `Ok(state)` or `Err(DeserializationError)`. Any panic is a crash
     finding.
   - Round-trip sub-contract: for any `GraphState` that can be serialized to msgpack,
     deserializing the serialized bytes must produce an equal state:
     `deser(ser(s)) == s` for all reachable `s`.
   - Target file: `fuzz/fuzz_targets/fuzz_checkpoint_serde.rs`

2. **Fuzz Target 2 — Graph-Execution Paths:**
   - Target name: `fuzz_graph_execution`
   - Input: arbitrary fuzzer-generated `GraphDefinition` (node count, edge topology, channel
     assignments, concurrent write patterns)
   - Contract: executing an arbitrary `GraphDefinition` MUST NOT panic or produce undefined
     behavior; it must either complete or return `Err(FerrochainError)`. Any panic, memory
     safety violation, or silent data corruption is a crash finding.
   - The fuzzer must reach all three BSP super-step paths: normal completion, interrupt
     injection, and empty-super-step no-op.
   - Target file: `fuzz/fuzz_targets/fuzz_graph_execution.rs`

3. Both targets compile without errors: `cargo +nightly fuzz build` succeeds.

4. Both targets run for a minimum of 10,000 corpus inputs without new crash findings before
   the Phase-6 gate is passed. (The corpus is seeded from Phase-3 test data.)

5. Any crash finding (panic, OOM abort, ASAN/MSAN report) from either target is a blocking
   convergence failure — it must be triaged and fixed before v1.

6. The fuzz corpus is committed to the repository under `fuzz/corpus/` and included in CI
   for regression prevention (subsequent runs replay the saved corpus before new exploration).

## Invariants

- **No-panic contract:** Fuzzing targets enforce the DI-008 principle (Library Constructor
  Result Contract) at the input boundary — arbitrary bytes must never cause a panic in
  library code.
- **Corpus persistence:** The fuzz corpus is a versioned artifact. Removing or resetting it
  requires an ADR entry explaining why corpus diversity was discarded.
- **Toolchain pin:** cargo-fuzz requires nightly Rust. The exact nightly version used for
  fuzzing is pinned in `rust-toolchain.toml` to prevent silent regression from toolchain
  changes.

## Edge Cases

### EC-001: Malformed msgpack Bytes in Serialization Fuzzer
**Scenario:** The fuzzer generates bytes that are invalid msgpack.
**Expected behavior:** Deserialization returns `Err(DeserializationError)` — no panic.
The error propagates to the caller. The fuzz target counts this as a non-crash handled error.

### EC-002: Graph with Zero Nodes
**Scenario:** The graph execution fuzzer generates a `GraphDefinition` with no nodes.
**Expected behavior:** Execution returns `Err(FerrochainError { code: E-GRAPH-008,
message: "UnreachableGraph: empty graph — no entry edge from START" })`.
No panic. The graph executor must handle degenerate topologies gracefully.
The fuzz oracle asserts exact code E-GRAPH-008; message-detail text may vary by implementation
(the message above is the canonical example; implementations may substitute a semantically equivalent `<reason>`).

### EC-003: Circular Edge in Graph Topology
**Scenario:** The fuzzer generates a graph with a cycle (`A → B → A`).
**Expected behavior:** The executor must detect the cycle and return
`Err(FerrochainError)` rather than looping forever or panicking. Cycle detection must be
bounded (not a live-lock).

### EC-004: Fuzz Target Finds Crash in Phase-6
**Scenario:** During Phase-6 fuzzing, `fuzz_checkpoint_serde` produces a panic.
**Expected behavior:** The crash input is saved to `fuzz/artifacts/`. The Phase-6
gate is BLOCKED. The implementer receives the minimized crash input, reproduces it with
`cargo +nightly fuzz run --artifact <input>`, identifies the panic site, and fixes it.
A regression test is added to the Phase-3 suite for the fixed input before re-running
the fuzzer.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `cargo +nightly fuzz build` | Compilation succeeds for both targets | Toolchain health check |
| TV-002 | Fuzz target `fuzz_checkpoint_serde` with valid serialized `GraphState` | Round-trip: `deser(ser(s)) == s` | Happy-path serde invariant |
| TV-003 | Fuzz target `fuzz_checkpoint_serde` with 0x00 bytes | `Err(DeserializationError)` — no panic | Malformed input safety |
| TV-004 | Fuzz target `fuzz_graph_execution` with 0-node graph | `Err(FerrochainError)` — no panic | Degenerate topology |
| TV-005 | Fuzz target `fuzz_graph_execution` with cyclic graph | `Err(FerrochainError)` — no panic, no live-lock | Cycle detection |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC217002-01 | Both fuzz targets compile with `cargo +nightly fuzz build` | CI compile check | Phase 6 |
| VP-BC217002-02 | 10,000 corpus inputs replay without new crash findings | cargo-fuzz run | Phase 6 |
| VP-BC217002-03 | Serialization round-trip property holds across corpus | Property test (libFuzzer corpus replay) | Phase 6 |

## Related BCs

- BC-2.17.001 — Kani harness scope (composes with: Kani proves bounded invariants; cargo-fuzz explores crash surfaces; both required for Phase-6 gate)
- BC-2.04.001 — Checkpoint write durability (depends on: fuzz_checkpoint_serde exercises the checkpoint serialization path that BC-2.04.001 defines)
- BC-2.03.001 — BSP super-step determinism (depends on: fuzz_graph_execution exercises the BSP execution path that BC-2.03.001 defines)

## Architecture Anchors

- `fuzz/fuzz_targets/fuzz_checkpoint_serde.rs` — Target 1 harness (to be created in Phase 6)
- `fuzz/fuzz_targets/fuzz_graph_execution.rs` — Target 2 harness (to be created in Phase 6)
- `fuzz/corpus/` — Seeded corpus from Phase-3 test data (to be created in Phase 6)
- `rust-toolchain.toml` — Nightly pin for cargo-fuzz (to be created/updated in Phase 6)

## Story Anchor

_[to be filled after story decomposition — Phase-6 story]_

## VP Anchors

- VP-BC217002-01, VP-BC217002-02, VP-BC217002-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-019 |
| Capability Anchor Justification | CAP-019 ("Formal Verification Pipeline (Kani + cargo-fuzz)") per capabilities-p1-p2.md §CAP-019 — this BC specifies the cargo-fuzz target scope that CAP-019 names explicitly: "cargo-fuzz on the core serialization and graph-execution paths" |
| L2 Domain Invariants | — |
| NE References | — |
| FM References | FM-002 (Checkpoint Write Loss on Crash — fuzz_checkpoint_serde targets this failure surface) |
| Phase anchor | OQR-3 — behavioral invariants are Phase-1 BCs; cargo-fuzz harness files are Phase-6 artifacts |
| Priority | P2 |
| Wave | Phase-6 |
| Test Types | F (fuzz) |
| Module | fuzz/ |
