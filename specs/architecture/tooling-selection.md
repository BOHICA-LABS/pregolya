---
document_type: architecture-section
level: L3
section: tooling-selection
version: "1.0"
status: draft
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "d0dce6c9953e730c"
traces_to: ARCH-INDEX.md
decisions: [D17]
---

# Tooling Selection: ferrochain

> Per D17-Q7 and CAP-019. All version pins are Point-in-Time estimates; implementer
> must verify against crates.io before Phase 3 begins. Pins are not checked into Cargo.toml
> until workspace init.

## Formal Verification: Kani

**Target:** VP-001 (BSP determinism), VP-002 (session tenancy), VP-003 (workspace confinement)

| Property | Value |
|----------|-------|
| Crate | `kani` (Kani Rust Verifier) |
| Version target | ≥ 0.50.0 (latest stable at Phase 6) |
| Cargo integration | `[dev-dependencies]` in ferrochain-graph, ferrochain-checkpoint, ferrochain-sandbox |
| Invocation | `cargo kani --harness <harness_name>` |
| CI gate | Phase 6 only; Kani is NOT a per-PR gate (too slow); run in dedicated Phase 6 job |
| Bounded loops | All harnesses must assert `kani::assume(n <= 4)` or equivalent bound |
| OS syscall policy | Harnesses must not call `std::fs::*`; pure path models used for VP-003 |

**Constraint:** Kani operates on pure functions. Any harness that reaches I/O code will
produce a verification failure. The purity-boundary-map.md classifications are the
prerequisite for Kani scope.

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
| Version target | ≥ 0.12.0 |
| Fuzz targets | `fuzz/fuzz_targets/checkpoint_roundtrip.rs`, `fuzz/fuzz_targets/graph_engine_boundary.rs` |
| Invocation | `cargo fuzz run <target> -- -max_total_time=300` |
| CI gate | Phase 6; fuzz corpus committed in `fuzz/corpus/` |
| Corpus seeding | Use known-good checkpoint artifacts as corpus seeds |

## Mutation Testing: cargo-mutants

**Target:** All CRITICAL and HIGH modules (kill rate ≥ 95% / ≥ 90%)

| Property | Value |
|----------|-------|
| Crate | `cargo-mutants` |
| Version target | ≥ 0.16.0 |
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
