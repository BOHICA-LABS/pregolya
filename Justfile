# pregolya task runner — see CLAUDE.md §Build & Test for full recipe reference.
#
# Requires: just, cargo-nextest
# Optional: cargo-llvm-cov, cargo kani, cargo-fuzz, cargo-mutants, cargo-udeps

_default:
    @just --list

# TDD inner loop — single crate, fast iteration (~10-30s warm)
iter crate filter="":
    cargo nextest run -p {{crate}} {{ if filter != "" { "--filter-expr 'test(" + filter + ")'" } else { "" } }}

# Pre-push gate — full strict workspace check
check:
    cargo fmt --all --check
    cargo clippy --workspace --all-targets -- -D warnings
    cargo nextest run --workspace
    cargo test --workspace --doc
    cargo xtask check-file-size

# Clippy + layout only (no tests; for refactor sweeps)
check-fast:
    cargo clippy --workspace --all-targets -- -D warnings
    cargo xtask check-file-size

# CI-equivalent local run
check-ci:
    cargo fmt --all --check
    cargo clippy --workspace --all-targets -- -D warnings
    cargo nextest run --workspace
    cargo test --workspace --doc
    cargo xtask check-file-size
    cargo deny check
    cargo audit
    cargo semver-checks

# clippy with -D warnings
clippy:
    cargo clippy --workspace --all-targets -- -D warnings

# cargo fmt --all
fmt:
    cargo fmt --all

# coverage via cargo-llvm-cov
cov:
    cargo llvm-cov --workspace

# Kani formal verification proofs
kani-local:
    cargo kani --workspace

# cargo-fuzz target
fuzz-local crate target:
    cargo fuzz run -p {{crate}} {{target}} -- -max_total_time=300

# mutation testing
mutants:
    cargo mutants --workspace

# unused-dep detection (requires nightly)
udeps:
    cargo +nightly udeps --workspace
