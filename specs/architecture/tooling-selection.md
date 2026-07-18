---
document_type: architecture-section
level: L3
section: tooling-selection
version: "1.1"
status: active
producer: architect
timestamp: 2026-07-17T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "f385250"
traces_to: ARCH-INDEX.md
decisions: [D17]
changelog:
  - "1.1 (provenance-fix-169/2026-07-17): hash-currency refresh — prd.md updated to v1.2 in same burst; add [Section Content] template compliance fix. No spec content changes."
  - "1.0 (initial): tooling selection authored."
---

# Tooling Selection: ferrochain

> Per D17-Q7 and CAP-019. All version pins are Point-in-Time estimates; implementer
> must verify against crates.io before Phase 3 begins. Pins are not checked into Cargo.toml
> until workspace init.

## [Section Content]

This file documents ferrochain's formal verification and testing tooling selection: Kani model checker (VP-001/002/003), cargo-fuzz, cargo-mutants, and proptest. All selections are driven by D17-Q7 (NFR-003 formal-proof obligations) and CAP-019.

## Formal Verification: Kani

**Target:** VP-001 (BSP determinism), VP-002 (session tenancy), VP-003 (workspace confinement)

| Property | Value |
|----------|-------|
| Crate | `kani` (Kani Rust Verifier) |
| Version target | 0.67.0 (verified 2026-07, latest stable) |
| Cargo integration | `[dev-dependencies]` in ferrochain-graph, ferrochain-checkpoint, ferrochain-sandbox |
| Invocation | `cargo kani --harness <harness_name>` |
| CI gate | Phase 6 only; Kani is NOT a per-PR gate (too slow); run in dedicated Phase 6 job |
| Bounded loops | All harnesses must assert `kani::assume(n <= 4)` or equivalent bound |
| OS syscall policy | Harnesses must not call `std::fs::*`; pure path models used for VP-003 |

**Constraint — no async support:** Kani 0.67.0 has NO native async/.await support.
Harnesses must target the synchronous pure core of each module. The async orchestration
layer (ADR-001 Alt-B Tokio runtime) is not Kani-verifiable; the sync reducer cores it
calls ARE. This drives the sync-core mandate: `graph::bsp_engine::reduce_super_step`,
`checkpoint::session_index::derive_key`, and `checkpoint::clock::next_id` MUST be
extractable as sync functions. See verification-architecture.md § Kani Async Constraint.

**Constraint — purity:** Any harness that reaches I/O code will produce a verification
failure. The purity-boundary-map.md classifications are the prerequisite for Kani scope.

## Property-Based Testing: proptest

**Target:** Channel reducers (SS-02/SS-03), checkpoint logical clock (SS-04), splitter
boundaries (SS-07), budget evaluation (SS-10)

| Property | Value |
|----------|-------|
| Crate | `proptest` |
| Version target | ≥ 1.4.0 |
| Cargo integration | `[dev-dependencies]` in ferrochain-graph, ferrochain-checkpoint, ferrochain-splitters |
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
| Invocation | `cargo xtask deny-client-new` / `cargo xtask deny-expect-in-lib` (wrappers) |
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
| Property tests | proptest | Every PR (CRITICAL/HIGH modules) |
| Integration tests | `cargo test --test *` | Every PR |
| Soak tests | custom harness | Phase 3 per-story (durability) |
| Mutation testing | cargo-mutants | Phase 3 per-story (CRITICAL); Phase 5 full sweep |
| Security linting | Semgrep (via xtask) | Every PR |
| Fuzzing | cargo-fuzz | Phase 6 |
| Formal verification | Kani | Phase 6 |
