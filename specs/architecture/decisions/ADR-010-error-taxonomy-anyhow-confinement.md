---
document_type: adr
level: L3
adr_id: "010"
slug: error-taxonomy-anyhow-confinement
title: "Error Taxonomy and anyhow Confinement (P-78 / NE-03 / DI-014)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17]
---

# ADR-010: Error Taxonomy and anyhow Confinement

**Status:** Accepted

## Context

adk-rust uses `anyhow::Error` at the library boundary in several places, losing structured
error information for callers (P-78 pattern to avoid). DI-014 mandates structured error
propagation with no silent None returns. BC-2.14.001–006 specify the FerrochainError model.

This ADR specifies: when is `anyhow` permitted, where is it banned, and how are crate
boundaries enforced.

## Decision: FerrochainError at all library boundaries; anyhow permitted only in binaries

**Rule:** `anyhow::Error` MUST NOT appear in any `pub` function signature in any library
crate. All public functions return `Result<T, FerrochainError>`.

**FerrochainError structure (BC-2.14.001):**

```rust
#[derive(Debug, Clone)]
pub struct FerrochainError {
    pub component: Component,     // authoritative list lives in error-taxonomy.md §Components; enum reproduced here for the FerrochainError type definition: CORE | GRAPH | CHKPT | SERVER | PROV | MCP | SPLIT | SBXD | RETRY | CRON | MEMORY | BUDGET
    pub category: Category,       // canonical Category Codes: VAL | AUTH | RATE | TIMEOUT | TRANSPORT | INTERNAL | DURABILITY | POLICY | TOOL | CONCURRENCY | SECURITY | TENANCY
    pub retry_hint: RetryHint,    // canonical: Never | Maybe | Later(Duration)
    pub code: &'static str,       // "E-GRAPH-001", "E-CHKPT-002", etc.
    pub message: String,          // Human-readable; MUST NOT contain credentials
    pub source: Option<Box<dyn std::error::Error + Send + Sync>>,
}
```

**anyhow confinement rules:**
1. Library crates (`ferrochain-*`): `anyhow` is NOT a dependency. ZERO uses.
2. `xtask` (binary): `anyhow` is permitted (CLI tooling; errors are human-facing).
3. Integration test binaries: `anyhow` is permitted for test harness convenience.
4. Example binaries: `anyhow` is permitted.

**CI enforcement:** `cargo xtask deny-anyhow-in-lib` (custom Semgrep rule) scans
`src/` in all library crates for `anyhow` imports. Fails CI on any finding.

**Internal error conversion:** Library crates use `thiserror` for internal error types
that convert to `FerrochainError` at the crate boundary. `thiserror` is permitted in
library crates; `anyhow` is not.

**Scope note:** NE-16 in the PRD refers to macOS Seatbelt (BC-2.13.006); it does NOT
govern anyhow confinement. This ADR's authority derives from P-78 (adk-rust
`MistralRsError::Other(#[from] anyhow::Error)` must-not-inherit pattern — the sole
genuine anyhow public-signature leak per CERTIFICATION-REPORT W-04), DI-014 (no silent
error swallowing), and the BC-2.14.003 CI lint gate.

## Consequences

- All library crates add `thiserror` as a dependency.
- Internal module errors use `thiserror`-derived enums.
- The `From<SomeInternalError> for FerrochainError` impl provides the conversion boundary.
- `anyhow` appears ONLY in `xtask/Cargo.toml` and integration test harness crates.
- RFC-7807 emission (BC-2.14.002): `FerrochainError::to_problem()` serializes to
  `application/problem+json` for ferrochain-server error responses.
  **Correction (F-P26-02, ADV-P1D-PASS-26, propagating F-P25-04 canon):** `to_problem_detail()`
  was the retired method name; `to_problem()` is authoritative per BC-2.14.002 PC1 and
  api-surface.md §Error Type.
- `FerrochainError::source()` returns the original cause (for logging); MUST NOT be
  exposed in HTTP responses (credential leak risk per DI-010).
