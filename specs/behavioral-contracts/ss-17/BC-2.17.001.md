---
document_type: behavioral-contract
level: L3
bc_id: BC-2.17.001
version: "1.2"
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
  - "1.2 (burst-241/Wave-2/F-P141-02/2026-07-23): VP-gate expansion — architect-confirmed 6 P0 + 3 P1 Kani obligations. Title updated. Description 'exactly three' → 'six P0 (D17-Q7+D21+D23) + three P1'. OQR-3 note: invariants +DI-014; enforcing BCs +BC-2.21.003/2.19.005/2.05.007; 'harnesses'/'are Phase-6 artifacts'. Preconditions: +BC-2.21.003/2.19.005/2.05.007; 'nine VP obligations (6 P0 + 3 P1)'. Postconditions: +VP-009/010/011 (P0) + VP-006/012/013 (P1); P0 failures block Phase-7; P1 failures block Phase-6 only; 'nine'. Invariants: lock expanded to D17-Q7+D21+D23; six P0 + three P1. EC-002 title/content: 'Fewer than Six P0 VPs Pass'. EC-003: nine (6 P0 + 3 P1). TV-006..009 added. Verification Properties updated. Related BCs +3. Architecture Anchors +3. Traceability DI +DI-014. traces_to +DI-014 +3 BCs."
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to kani_proofs/ per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-019
  - domain-spec/invariants.md#DI-001
  - domain-spec/invariants.md#DI-005
  - domain-spec/invariants.md#DI-007
  - domain-spec/invariants.md#DI-014
  - behavioral-contracts/ss-21/BC-2.21.003.md
  - behavioral-contracts/ss-19/BC-2.19.005.md
  - behavioral-contracts/ss-05/BC-2.05.007.md
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "d4754dd"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.17.001: Six P0 Kani VP Obligations + Three P1 Kani VP Obligations

## Description

This BC specifies the behavioral contract for Phase-6 Kani harness delivery: six P0
(D17-Q7+D21+D23) + three P1 VP obligations must be proven before v1 convergence. The
behavioral invariants being proved are specified in Phase-1 BCs (BC-2.03.001, BC-2.04.006,
BC-2.13.004, BC-2.21.003, BC-2.19.005, BC-2.05.007); this BC specifies WHAT the Kani
harnesses must cover and what "proof passes" means. The harnesses themselves are Phase-6
artifacts (OQR-3); this Phase-1 BC is the scope specification for that work.

> **Phase anchor (OQR-3):** Behavioral invariants DI-001, DI-005, DI-007, DI-014 are specified in
> Phase-1 BCs (BC-2.03.001, BC-2.04.006, BC-2.13.004, BC-2.21.003, BC-2.19.005, BC-2.05.007). This BC specifies the Kani harness
> scope. The harness files (`kani_proofs/` or equivalent) are Phase-6 delivery artifacts.
> Phase-1 passes when this BC exists and is approved. Phase-6 passes when the harnesses run
> clean with `cargo kani`.

## Preconditions

1. Phase-1 BCs BC-2.03.001, BC-2.04.006, BC-2.13.004, BC-2.21.003, BC-2.19.005, and BC-2.05.007 are in ACTIVE lifecycle status.
2. The architect has confirmed the nine VP obligations (6 P0 + 3 P1) as D17-Q7+D21+D23 scope before Phase-2
   story decomposition.
3. Phase 6 (formal hardening) has begun — the implementation that Phase-6 will verify is
   complete and all Phase-3 unit/integration tests pass.

## Postconditions

1. The Kani harnesses include nine VP targets: six P0 (D17-Q7+D21+D23) and three P1:
   - **VP-1 (DI-001 — BSP Reducer Determinism) [P0]:** Harness proves that given identical
     `Vec<PregelTask>` inputs, the BSP reducer produces identical `GraphState` output
     regardless of task arrival order (concurrent simulation). Corresponds to BC-2.03.001
     Verification Properties.
   - **VP-2 (DI-005 — Session Triple-Address Uniqueness) [P0]:** Harness proves that no state
     operation with distinct `(thread_id, checkpoint_ns, checkpoint_id)` triples produces
     the same storage address, and no code path addresses state by bare `thread_id` alone.
     Corresponds to BC-2.04.006 Verification Properties.
   - **VP-3 (DI-007 — Workspace Path Confinement) [P0]:** Harness proves that every workspace
     file operation using `canonicalize_beneath_root(base, path)` either stays within
     `base` or returns `Err(WorkspaceEscape)` — no path escapes. Corresponds to BC-2.13.004
     Verification Properties.
   - **VP-009 (DI-014 — Zero-Norm Cosine Guard) [P0]:** Harness proves that the zero-norm
     vector guard in `InMemoryVectorStore` returns `E-VS-001` before any cosine division
     occurs — no NaN can propagate into similarity ranking. Corresponds to BC-2.21.003
     Verification Properties.
   - **VP-010 (DI-014 — Reviver Allowlist Containment) [P0]:** Harness proves that an
     unregistered type id raises `E-SRLZ-001` (Fail-Closed) and never dispatches a
     constructor. Corresponds to BC-2.19.005 Verification Properties.
   - **VP-011 (DI-014 — PreToolCallHook Fail-Closed) [P0]:** Harness proves that a
     `PreToolCallHook` returning `Deny` prevents tool invocation — no tool is called when
     the hook denies. Corresponds to BC-2.05.007 Verification Properties.
   - **VP-006 (DI-008, DI-014 — Injection Guard Fail-Closed) [P1]:** Harness proves that
     `injection_guard` raises `E-TMPL-001` for untrusted content in a `SystemMessage` slot
     at render time. Corresponds to BC-2.18.004 Verification Properties.
   - **VP-012 (DI-014 — OnWatermark Arithmetic) [P1]:** Harness proves the `OnWatermark`
     trigger fires iff `tokens_remaining / ceiling < (1.0 - fraction)` with no overflow.
     Corresponds to BC-2.10.005 Verification Properties.
   - **VP-013 (DI-014, DI-015 — BashTool Risk Floor) [P1]:** Harness proves the
     non-lowerable `Medium` risk floor on `BashTool` — `ReadOnly` and `Low` `ActionRisk`
     always return `Err(E-TOOLS-007)`. Corresponds to BC-2.23.005 Verification Properties.
2. Running `cargo kani --harness <vp_harness>` on the Phase-3-complete implementation
   terminates with `VERIFICATION SUCCESSFUL` for each of the nine VPs (P0 failures block
   Phase-7 convergence; P1 failures block Phase-6 completion only).
3. Any P0 VP failure (VP-001/002/003/009/010/011: VERIFICATION FAILED, timeout, or harness
   compile error) is a blocking Phase-7 convergence-gate failure (NFR-003). Any P1 VP
   failure (VP-006/012/013) blocks Phase-6 completion only and does not gate Phase-7.
4. The harness scope does NOT include additional VPs beyond these nine without a
   D17-Q7/D21/D23 amendment approved by the architect.
5. Kani proof success does NOT substitute for Phase-3 unit/integration tests — both are
   required for v1 convergence.

## Invariants

- **D17-Q7+D21+D23 lock:** The six P0 VP targets (VP-001/002/003 locked by D17-Q7;
  VP-009/010/011 locked by D21+D23) and three P1 VP targets (VP-006/012/013 locked by
  D21+D23) cannot be reduced or renamed without a formal ADR amendment.
- **Phase separation (OQR-3):** Phase-1 owns the behavioral invariant specification
  (BC-2.03.001, BC-2.04.006, BC-2.13.004, BC-2.21.003, BC-2.19.005, BC-2.05.007,
  BC-2.17.001). Phase-6 owns harness execution. The harness files are NOT produced in Phase 1.
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

### EC-002: Fewer than Six P0 VPs Pass
**Scenario:** One or more of the six P0 VPs (VP-001/002/003/009/010/011) fail VERIFICATION
FAILED.
**Expected behavior:** Phase-7 convergence is BLOCKED. Each failing VP maps to a specific
implementation bug in the corresponding behavioral contract. The failure message from Kani
must identify the failing path. The implementer receives the counterexample and fixes the
implementation. P1 VP failures (VP-006/012/013) block Phase-6 completion only.

### EC-003: New VP Proposed After D17-Q7/D21/D23
**Scenario:** During Phase 6, the architect proposes adding a VP beyond the current nine
(6 P0 + 3 P1).
**Expected behavior:** This BC's scope (nine VPs: 6 P0 + 3 P1) must not be modified
silently. An architect-approved ADR amendment is required. Additional VPs may be added to
this BC or assigned to a new BC at the architect's discretion. Until an amendment is
approved, Phase-6 delivery requires only the nine defined VPs.

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
| TV-006 | `cargo kani --harness zero_norm_guard_fail_closed` on Phase-3-complete implementation | `VERIFICATION SUCCESSFUL` | VP-009 happy path |
| TV-007 | `cargo kani --harness allowlist_rejects_unregistered_id` on Phase-3-complete implementation | `VERIFICATION SUCCESSFUL` | VP-010 happy path |
| TV-008 | `cargo kani --harness deny_excludes_tool_invocation` on Phase-3-complete implementation | `VERIFICATION SUCCESSFUL` | VP-011 happy path |
| TV-009 | Implementation with intentional zero-norm vector not rejected before cosine division | `VERIFICATION FAILED` with counterexample | VP-009 detects violation |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC217001-01 | Kani harness file exists and compiles for each of the nine VP targets (6 P0 + 3 P1) | CI compile check | Phase 6 |
| VP-BC217001-02 | All six P0 VP targets pass `cargo kani` with VERIFICATION SUCCESSFUL (Phase-7 gate) | Kani formal proof | Phase 6 |
| VP-BC217001-03 | All three P1 VP targets pass `cargo kani` with VERIFICATION SUCCESSFUL (Phase-6 completion gate) | Kani formal proof | Phase 6 |

## Related BCs

- BC-2.03.001 — BSP super-step execution determinism (is the behavioral source for VP-1/VP-001; this BC is the proof-scope spec for VP-001)
- BC-2.04.006 — Session triple-address uniqueness (is the behavioral source for VP-2/VP-002; this BC is the proof-scope spec for VP-002)
- BC-2.13.004 — Workspace canonicalize_beneath_root (is the behavioral source for VP-3/VP-003; this BC is the proof-scope spec for VP-003)
- BC-2.21.003 — Zero-norm vector guard (is the behavioral source for VP-009 P0; this BC is the proof-scope spec for VP-009)
- BC-2.19.005 — Reviver allowlist containment (is the behavioral source for VP-010 P0; this BC is the proof-scope spec for VP-010)
- BC-2.05.007 — PreToolCallHook fail-closed Deny (is the behavioral source for VP-011 P0; this BC is the proof-scope spec for VP-011)
- BC-2.17.002 — cargo-fuzz targets (composes with: both are Phase-6 formal hardening deliverables; Kani and fuzz are complementary)

## Architecture Anchors

- `kani_proofs/bsp_determinism.rs` — VP-001 harness (to be created in Phase 6)
- `kani_proofs/session_tenancy.rs` — VP-002 harness (to be created in Phase 6)
- `kani_proofs/workspace_confinement.rs` — VP-003 harness (to be created in Phase 6)
- `kani_proofs/zero_norm_guard.rs` — VP-009 harness (to be created in Phase 6)
- `kani_proofs/reviver_allowlist.rs` — VP-010 harness (to be created in Phase 6)
- `kani_proofs/pre_tool_hook_closed.rs` — VP-011 harness (to be created in Phase 6)
- `NFR-003` in `prd-supplements/nfr-catalog.md` — "All 6 P0 Kani VP obligations pass before v1 convergence"

## Story Anchor

_[to be filled after story decomposition — Phase-6 story]_

## VP Anchors

- VP-BC217001-01, VP-BC217001-02, VP-BC217001-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-019 |
| Capability Anchor Justification | CAP-019 ("Formal Verification Pipeline (Kani + cargo-fuzz)") per capabilities-p1-p2.md §CAP-019 — this BC specifies the exact Kani harness scope that CAP-019 identifies as the D17-Q7-locked VP obligations for BSP determinism, session tenancy, and workspace confinement |
| L2 Domain Invariants | DI-001 (BSP Reducer Determinism — VP-001 target), DI-005 (Session Triple-Address Uniqueness — VP-002 target), DI-007 (Workspace Path Confinement — VP-003 target), DI-014 (Data Integrity — VP-009/010/011 targets) |
| NE References | NE-17 (BSP nondeterminism counter-example → VP-1), NE-12 (identity-triple collapse → VP-2), NE-02 (workspace escape → VP-3) |
| FM References | FM-001 (Non-Deterministic Reducer Order — VP-1 targets this), FM-005 (Cross-Tenant State Read — VP-2 targets this) |
| Phase anchor | OQR-3 — behavioral invariants are Phase-1 BCs; Kani proof deliverables are Phase-6 artifacts |
| Priority | P2 |
| Wave | Phase-6 |
| Test Types | K (Kani formal proof) |
| Module | kani_proofs/ |
