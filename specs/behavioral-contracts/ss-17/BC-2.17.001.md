---
document_type: behavioral-contract
level: L3
bc_id: BC-2.17.001
version: "1.1"
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
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to kani_proofs/ per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-019
  - domain-spec/invariants.md#DI-001
  - domain-spec/invariants.md#DI-005
  - domain-spec/invariants.md#DI-007
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "b845cb6"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.17.001: Kani Harness Scope — BSP Determinism VP + Session Tenancy VP + Workspace Confinement VP

## Description

This BC specifies the behavioral contract for Phase-6 Kani harness delivery: exactly three
VP obligations (from D17-Q7) must be proven before v1 convergence. The behavioral invariants
being proved are specified in Phase-1 BCs (BC-2.03.001, BC-2.04.006, BC-2.13.004); this BC
specifies WHAT the Kani harness must cover and what "proof passes" means. The harness itself
is a Phase-6 artifact (OQR-3); this Phase-1 BC is the scope specification for that work.

> **Phase anchor (OQR-3):** Behavioral invariants DI-001, DI-005, DI-007 are specified in
> Phase-1 BCs (BC-2.03.001, BC-2.04.006, BC-2.13.004). This BC specifies the Kani harness
> scope. The harness files (`kani_proofs/` or equivalent) are Phase-6 delivery artifacts.
> Phase-1 passes when this BC exists and is approved. Phase-6 passes when the harness runs
> clean with `cargo kani`.

## Preconditions

1. Phase-1 BCs BC-2.03.001, BC-2.04.006, and BC-2.13.004 are in ACTIVE lifecycle status.
2. The architect has confirmed the three VP obligations as D17-Q7 scope before Phase-2
   story decomposition.
3. Phase 6 (formal hardening) has begun — the implementation that Phase-6 will verify is
   complete and all Phase-3 unit/integration tests pass.

## Postconditions

1. The Kani harness includes exactly three VP targets corresponding to D17-Q7:
   - **VP-1 (DI-001 — BSP Reducer Determinism):** Harness proves that given identical
     `Vec<PregelTask>` inputs, the BSP reducer produces identical `GraphState` output
     regardless of task arrival order (concurrent simulation). Corresponds to BC-2.03.001
     Verification Properties.
   - **VP-2 (DI-005 — Session Triple-Address Uniqueness):** Harness proves that no state
     operation with distinct `(thread_id, checkpoint_ns, checkpoint_id)` triples produces
     the same storage address, and no code path addresses state by bare `thread_id` alone.
     Corresponds to BC-2.04.006 Verification Properties.
   - **VP-3 (DI-007 — Workspace Path Confinement):** Harness proves that every workspace
     file operation using `canonicalize_beneath_root(base, path)` either stays within
     `base` or returns `Err(WorkspaceEscape)` — no path escapes. Corresponds to BC-2.13.004
     Verification Properties.
2. Running `cargo kani --harness <vp1_harness>` on the Phase-3-complete implementation
   terminates with `VERIFICATION SUCCESSFUL` for each of the three VPs.
3. Any Kani failure (VERIFICATION FAILED, timeout, or harness compile error) is a blocking
   convergence-gate failure (NFR-003).
4. The harness scope does NOT include additional VPs beyond these three without a D17-Q7
   amendment approved by the architect.
5. Kani proof success does NOT substitute for Phase-3 unit/integration tests — both are
   required for v1 convergence.

## Invariants

- **D17-Q7 lock:** The three VP targets (VP-1, VP-2, VP-3 as named above) are locked by
  D17-Q7 and cannot be reduced or renamed without a formal ADR amendment.
- **Phase separation (OQR-3):** Phase-1 owns the behavioral invariant specification
  (BC-2.03.001, BC-2.04.006, BC-2.13.004, BC-2.17.001). Phase-6 owns harness execution.
  The harness files are NOT produced in Phase 1.
- **Proof completeness:** Each harness must exercise the full state space reachable from
  the precondition; partial proofs (bounded unwind without justification) require explicit
  annotation and architect sign-off.

## Edge Cases

### EC-001: Kani Harness Timeout
**Scenario:** VP-1 (BSP determinism) takes > 60 minutes on the CI runner due to large
state space.
**Expected behavior:** The harness must be bounded with `#[kani::unwind(N)]` annotation
(N determined by architect). If bounding is applied, a comment in the harness file must
justify the bound and confirm completeness for the bounded case. A timeout without an
unwind annotation is a convergence failure, not a known limitation.

### EC-002: Only Two of Three VPs Pass
**Scenario:** VP-1 and VP-2 pass; VP-3 (workspace confinement) fails VERIFICATION FAILED.
**Expected behavior:** v1 convergence is BLOCKED. The failing VP maps to a specific
implementation bug in `canonicalize_beneath_root`. The failure message from Kani must
identify the failing path. The implementer receives the counterexample and fixes the
implementation.

### EC-003: New VP Proposed After D17-Q7
**Scenario:** During Phase 6, the architect proposes adding a fourth VP for a new
correctness property.
**Expected behavior:** This BC's scope (exactly three VPs) must not be modified silently.
An ADR amendment is required. Until the amendment is approved, Phase-6 delivery requires
only the original three VPs. A fourth VP, if added, becomes a separate BC (BC-2.17.003
or higher).

### EC-004: Implementation Refactored After Kani Passes
**Scenario:** A post-Phase-6 refactor changes the BSP reducer. VP-1 is no longer proven
for the new code.
**Expected behavior:** CI must re-run the Kani harness on the refactored code. If the
harness fails, the refactor is not mergeable. The harness is a living gate, not a one-time
proof.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `cargo kani --harness bsp_determinism_harness` on Phase-3-complete implementation | `VERIFICATION SUCCESSFUL` | VP-1 happy path |
| TV-002 | `cargo kani --harness session_tenancy_harness` on Phase-3-complete implementation | `VERIFICATION SUCCESSFUL` | VP-2 happy path |
| TV-003 | `cargo kani --harness workspace_confinement_harness` on Phase-3-complete implementation | `VERIFICATION SUCCESSFUL` | VP-3 happy path |
| TV-004 | Implementation with intentional reducer non-determinism injected | `VERIFICATION FAILED` with counterexample | VP-1 detects violation |
| TV-005 | Implementation with bare thread_id state access injected | `VERIFICATION FAILED` with counterexample | VP-2 detects violation |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC217001-01 | Kani harness file exists and compiles for each of the three D17-Q7 targets | CI compile check | Phase 6 |
| VP-BC217001-02 | All three VP targets pass `cargo kani` with VERIFICATION SUCCESSFUL | Kani formal proof | Phase 6 |

## Related BCs

- BC-2.03.001 — BSP super-step execution determinism (is the behavioral source for VP-1; this BC is the proof-scope spec for VP-1)
- BC-2.04.006 — Session triple-address uniqueness (is the behavioral source for VP-2; this BC is the proof-scope spec for VP-2)
- BC-2.13.004 — Workspace canonicalize_beneath_root (is the behavioral source for VP-3; this BC is the proof-scope spec for VP-3)
- BC-2.17.002 — cargo-fuzz targets (composes with: both are Phase-6 formal hardening deliverables; Kani and fuzz are complementary)

## Architecture Anchors

- `kani_proofs/bsp_determinism.rs` — VP-1 harness (to be created in Phase 6)
- `kani_proofs/session_tenancy.rs` — VP-2 harness (to be created in Phase 6)
- `kani_proofs/workspace_confinement.rs` — VP-3 harness (to be created in Phase 6)
- `NFR-003` in `prd-supplements/nfr-catalog.md` — "All 3 committed VP obligations pass Kani before v1"

## Story Anchor

_[to be filled after story decomposition — Phase-6 story]_

## VP Anchors

- VP-BC217001-01, VP-BC217001-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-019 |
| Capability Anchor Justification | CAP-019 ("Formal Verification Pipeline (Kani + cargo-fuzz)") per capabilities-p1-p2.md §CAP-019 — this BC specifies the exact Kani harness scope that CAP-019 identifies as the D17-Q7-locked VP obligations for BSP determinism, session tenancy, and workspace confinement |
| L2 Domain Invariants | DI-001 (BSP Reducer Determinism — VP-1 target), DI-005 (Session Triple-Address Uniqueness — VP-2 target), DI-007 (Workspace Path Confinement — VP-3 target) |
| NE References | NE-17 (BSP nondeterminism counter-example → VP-1), NE-12 (identity-triple collapse → VP-2), NE-02 (workspace escape → VP-3) |
| FM References | FM-001 (Non-Deterministic Reducer Order — VP-1 targets this), FM-005 (Cross-Tenant State Read — VP-2 targets this) |
| Phase anchor | OQR-3 — behavioral invariants are Phase-1 BCs; Kani proof deliverables are Phase-6 artifacts |
| Priority | P2 |
| Wave | Phase-6 |
| Test Types | K (Kani formal proof) |
| Module | kani_proofs/ |
