---
document_type: architecture-section
level: L3
section: tooling-selection
version: "1.5"
status: active
producer: architect
timestamp: 2026-07-26T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "pending-FIX-BURST-275"
traces_to: ARCH-INDEX.md
decisions: [D17, D21, D23]
changelog:
  - "1.5 (D-35-rename-sweep/2026-07-28): D-35 canonical xtask naming sweep — §Security Linting Invocation row: `cargo xtask deny-client-new` → `cargo xtask check-client-timeout`; `cargo xtask deny-expect-in-lib` → `cargo xtask check-no-panic`. Canonical `check-<subject>` form per D-35."
  - "1.4 (FIX-BURST-276/F-P173-803/2026-07-27): F-P173-803 — fix proptest gate in §Test Strategy Summary. Actual proptest coverage is 3 of 12 CRITICAL tiers (graph::bsp_engine, checkpoint::session_index, checkpoint::clock) and 7 of 28 HIGH tiers (core::runnable, core::message, core::serializable/VP-007, core::embeddings/VP-008, graph::definition, graph::channels, graph::budget). Replace 'Every PR (CRITICAL/HIGH modules)' with actual coverage count and stated obligation. See verification-coverage-matrix.md §Coverage by Criticality Tier for current counts. Derivation: counted from per-module table proptest column in verification-coverage-matrix.md — rows with yes or VP-NNN in proptest column, grouped by tier per module-criticality.md tier assignments."
  - "1.3 (FIX-BURST-275/F-P172b-08+09/2026-07-26): F-P172b-09 — replace phantom symbol `checkpoint::session_index::derive_key` with correct `checkpoint::session_index::storage_address` in §Kani async constraint paragraph. Rationale: `storage_address` is the sync Kani harness target per verification-architecture.md VP-002 harness (`session_tenancy_harness`); `derive_key` is not a real symbol in the checkpoint module surface (phantom); VP-002 anchors to `checkpoint::session_index`, not `checkpoint::clock`. F-P172b-08 — add `ferrochain-core` and `ferrochain-memory` to proptest Cargo integration row (proptest P1 obligations VP-007 LcSerializable round-trip [ferrochain-core SS-19] and VP-008 dimensionality contract [ferrochain-core SS-22] and memory write-guard invariants [ferrochain-memory SS-15] require proptest in those crates); add SS-19 (LC Serialization VP-007) and SS-22 (Embeddings VP-008) to proptest §Target."
  - "1.2 (burst-241/2026-07-23): F-P141-02 — expand Kani §Target from D17-Q7 3-VP set to full 9-VP catalog (6 P0 + 3 P1); expand Cargo integration row to all 7 Kani-hosting crates; update [Section Content] intro sentence. VP-009/010/011 confirmed P0 (fail-closed security/safety proofs). Add D21/D23 to decisions."
  - "1.1 (provenance-fix-169/2026-07-17): hash-currency refresh — prd.md updated to v1.2 in same burst; add [Section Content] template compliance fix. No spec content changes."
  - "1.0 (initial): tooling selection authored."
---

# Tooling Selection: ferrochain

> Per D17-Q7 and CAP-019. All version pins are Point-in-Time estimates; implementer
> must verify against crates.io before Phase 3 begins. Pins are not checked into Cargo.toml
> until workspace init.

## [Section Content]

This file documents ferrochain's formal verification and testing tooling selection: Kani model checker (9 VPs: 6 P0 + 3 P1), cargo-fuzz, cargo-mutants, and proptest. All selections are driven by D17-Q7 + D21 + D23 (NFR-003 formal-proof obligations) and CAP-019.

## Formal Verification: Kani

**P0 targets (v1 convergence gate — all must pass before Phase 7):**
VP-001 (BSP determinism / ferrochain-graph), VP-002 (session tenancy / ferrochain-checkpoint),
VP-003 (workspace confinement / ferrochain-sandbox), VP-009 (zero-norm cosine guard /
ferrochain-vectorstores), VP-010 (reviver allowlist containment / ferrochain-core),
VP-011 (PreToolCallHook fail-closed / ferrochain-graph)

**P1 targets (Phase 6 goals):**
VP-006 (injection_guard fail-closed / ferrochain-prompts), VP-012 (OnWatermark arithmetic /
ferrochain-core), VP-013 (BashTool risk floor / ferrochain-tools)

| Property | Value |
|----------|-------|
| Crate | `kani` (Kani Rust Verifier) |
| Version target | 0.67.0 (verified 2026-07, latest stable) |
| Cargo integration | `[dev-dependencies]` in ferrochain-graph, ferrochain-checkpoint, ferrochain-sandbox, ferrochain-vectorstores, ferrochain-core, ferrochain-prompts, ferrochain-tools |
| Invocation | `cargo kani --harness <harness_name>` |
| CI gate | Phase 6 only; Kani is NOT a per-PR gate (too slow); run in dedicated Phase 6 job |
| Bounded loops | All harnesses must assert `kani::assume(n <= 4)` or equivalent bound |
| OS syscall policy | Harnesses must not call `std::fs::*`; pure path models used for VP-003 |

**Constraint — no async support:** Kani 0.67.0 has NO native async/.await support.
Harnesses must target the synchronous pure core of each module. The async orchestration
layer (ADR-001 Alt-B Tokio runtime) is not Kani-verifiable; the sync reducer cores it
calls ARE. This drives the sync-core mandate: `graph::bsp_engine::reduce_super_step`,
`checkpoint::session_index::storage_address`, and `checkpoint::clock::get_next_version` MUST be
extractable as sync functions. See verification-architecture.md § Kani Async Constraint.

**Constraint — purity:** Any harness that reaches I/O code will produce a verification
failure. The purity-boundary-map.md classifications are the prerequisite for Kani scope.

## Property-Based Testing: proptest

**Target:** Channel reducers (SS-02/SS-03), checkpoint logical clock (SS-04), splitter
boundaries (SS-07), budget evaluation (SS-10), LC Serialization round-trip (SS-19 / VP-007),
Embeddings dimensionality contract (SS-22 / VP-008)

| Property | Value |
|----------|-------|
| Crate | `proptest` |
| Version target | ≥ 1.4.0 |
| Cargo integration | `[dev-dependencies]` in ferrochain-graph, ferrochain-checkpoint, ferrochain-splitters, ferrochain-core, ferrochain-memory |
| Invocation | Standard `cargo test` |
| Regression corpus | Proptest stores failures in `proptest-regressions/` (committed) |

Use `proptest!` macro for invariant-style tests (e.g., `reduce(permute(v)) == reduce(v)`).

## Fuzzing: cargo-fuzz

**Target:** BC-2.17.002 — checkpoint msgpack round-trip, graph-engine boundary inputs

| Property | Value |
|----------|-------|
| Crate | `cargo-fuzz` (libFuzzer) |
| Version target | 0.13.2 (verified 2026-07) |
| Fuzz targets | `fuzz/fuzz_targets/checkpoint_roundtrip.rs`, `fuzz/fuzz_targets/graph_engine_boundary.rs` |
| Invocation | `cargo fuzz run <target> -- -max_total_time=300` |
| CI gate | Phase 6; fuzz corpus committed in `fuzz/corpus/` |
| Corpus seeding | Use known-good checkpoint artifacts as corpus seeds |

## Mutation Testing: cargo-mutants

**Target:** All CRITICAL and HIGH modules (kill rate ≥ 95% / ≥ 90%)

| Property | Value |
|----------|-------|
| Crate | `cargo-mutants` |
| Version target | 27.1.0 (verified 2026-07) |
| Invocation | `cargo mutants --workspace` |
| CI gate | Phase 5 adversarial; also Phase 3 per-story gate for CRITICAL modules |
| Kill rate thresholds | CRITICAL ≥ 95%; HIGH ≥ 90%; MEDIUM ≥ 80%; LOW ≥ 70% |
| Exclusions | `xtask/`, `ferrochain-community/` (not production runtime) |

## Security Linting: Semgrep

**Target:** NE-04 (timeout lint), NE-07 (expect lint), NE-10 (credential leak)

| Property | Value |
|----------|-------|
| Tool | `semgrep` (CLI) |
| Invocation | `cargo xtask check-client-timeout` / `cargo xtask check-no-panic` (wrappers) |
| Rule set | Custom rules in `xtask/semgrep-rules/` |
| CI gate | Every PR; fail on any finding |

Key rules:
- `client-new-without-timeout`: detect `Client::new()` outside `#[cfg(test)]`
- `expect-in-lib`: detect `.expect()` / `.unwrap()` in `src/` (not `tests/`)
- `bare-string-api-key`: detect `pub struct *Key(String)` without `#[cfg_attr(debug, ...)]`

## Test Strategy Summary

| Verification Level | Tools | When |
|-------------------|-------|------|
| Unit tests | `cargo test` | Every PR |
| Property tests | proptest | Every PR (modules with proptest targets: 3 of 12 CRITICAL + 7 of 28 HIGH = 10 modules; see verification-coverage-matrix.md §Coverage by Criticality Tier; **coverage obligation:** expand proptest to all CRITICAL/HIGH modules by Phase 5) |
| Integration tests | `cargo test --test *` | Every PR |
| Soak tests | custom harness | Phase 3 per-story (durability) |
| Mutation testing | cargo-mutants | Phase 3 per-story (CRITICAL); Phase 5 full sweep |
| Security linting | Semgrep (via xtask) | Every PR |
| Fuzzing | cargo-fuzz | Phase 6 |
| Formal verification | Kani | Phase 6 |
