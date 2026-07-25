---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
traces_to: STATE.md
phase: 1d
pass: 17
verdict: NOT CLEAN
timestamp: 2026-07-14T00:00:00Z
producer: architect
scope: "Kani harness identifier registry + full executable-string layer sweep; NE-axis rebuild PASS; CAP/VP PASS; 3 prior censuses PASS"
inputs:
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/verification-properties/VP-001.md
  - .factory/specs/verification-properties/VP-002.md
  - .factory/specs/verification-properties/VP-003.md
  - .factory/specs/prd-supplements/nfr-catalog.md
  - .factory/specs/behavioral-contracts/ss-03/BC-2.03.001.md
  - .factory/specs/behavioral-contracts/ss-17/BC-2.17.001.md
  - .factory/specs/architecture/verification-architecture.md
  - .factory/specs/architecture/verification-coverage-matrix.md
  - .factory/specs/prd-supplements/bc-authoring-plan.md
input-hash: "ad62d46"
findings:
  - id: F-P17-01
    severity: MEDIUM
    status: FIXED
trajectory: "...→1→1→1"
clean_pass_counter: 0/3
previous_review: ADV-P1D-PASS-16.md
---

# ADV-P1D-PASS-17: Adversarial Review

## Finding ID Convention

Finding IDs for this pass use the format `F-P17-NN` (project convention; cycle prefix omitted per established ferrochain shorthand).

## Verdict: NOT CLEAN — 1 MEDIUM Finding (FIXED)

Novel probe axis this pass: **executable-string layer** — full grep sweep of all embedded
`cargo kani`, `cargo xtask`, `cargo bench`, `cargo fuzz`, `cargo mutants`, `cargo check -p`,
`semgrep`, and bare `xtask` command strings across all of `.factory/specs/`, census table
built, identifier consistency across all citations checked. This surface had never been
censused as a whole before. Prior passes addressed individual harness-name issues in isolation.

Sibling axes (NE full rebuild, CAP/VP census, 3 prior census reconfirmations): **PASS** —
no new findings on these axes this pass.

---

## Part B — New Findings (or all findings for pass 1)

## F-P17-01 (MEDIUM) — Kani Harness Identifier: 5 Naming Variants, Nonexistent Names in Gate Commands

### Finding

**Class: verification-command chain** — NEW CLASS, not previously covered by any standing gate.

BC-2.17.001 is the source of truth for canonical Kani harness function names (TV names in
TV-001/TV-002/TV-003). The canonical names are:

| VP | Canonical harness_fn |
|----|---------------------|
| VP-001 | `bsp_determinism_harness` |
| VP-002 | `session_tenancy_harness` |
| VP-003 | `workspace_confinement_harness` |

**Failing sites (pre-fix):**

| Document | Line | Nonexistent name cited | Canonical name |
|----------|------|----------------------|----------------|
| nfr-catalog.md (NFR-003) | 32 | `bsp_determinism_vp` | `bsp_determinism_harness` |
| nfr-catalog.md (NFR-011) | 40 | `bsp_determinism_vp` | `bsp_determinism_harness` |
| BC-2.03.001.md | 122 | `verify_bsp_determinism` | `bsp_determinism_harness` |
| VP-001.md | 54 | `bsp_super_step_determinism` | `bsp_determinism_harness` |
| verification-architecture.md | 43 | `bsp_determinism` | `bsp_determinism_harness` |
| verification-architecture.md | 79 | `bsp_determinism` | `bsp_determinism_harness` |
| verification-architecture.md | 103 | `session_tenancy_partition` | `session_tenancy_harness` |
| verification-architecture.md | 133 | `workspace_confinement` | `workspace_confinement_harness` |
| VP-002.md | 50 | `session_triple_uniqueness` | `session_tenancy_harness` |
| VP-003.md | 53 | `workspace_confinement` | `workspace_confinement_harness` |

**Additionally:** VP-INDEX.md had no `harness_fn` column, leaving harness names with no
single authoritative registry entry.

**Severity rationale:** MEDIUM (not HIGH) because: (1) harness files are Phase-6 artifacts,
not yet created; (2) the canonical names exist in BC-2.17.001 and no incorrect names were
in BC-2.17.001 itself; (3) the NFR gate commands (`cargo kani --harness bsp_determinism_vp`)
would fail at Phase-6 invocation time, not during Phase-1 spec review. Risk is late-stage
confusion rather than current inconsistency in behavioral contracts.

### Fix

1. Added `harness_fn` column to VP-INDEX.md VP Catalog table.
2. Reconciled all 10 failing sites to canonical names from BC-2.17.001.
3. Recorded VP-INDEX `harness_fn` column + executable-string census as standing gate #18
   in bc-authoring-plan.md.

---

## Executable-String Census (Full Sweep)

Scope: all `cargo kani`, `cargo xtask`, `cargo bench`, `cargo fuzz`, `cargo mutants`,
`cargo check -p`, `semgrep`, bare `xtask` strings in `.factory/specs/`.

| Command String | Documents Citing It | Consistent? |
|----------------|---------------------|-------------|
| `cargo kani --harness bsp_determinism_harness` | BC-2.17.001 TV-001 | CANONICAL |
| `cargo kani --harness session_tenancy_harness` | BC-2.17.001 TV-002 | CANONICAL |
| `cargo kani --harness workspace_confinement_harness` | BC-2.17.001 TV-003 | CANONICAL |
| `cargo kani --harness bsp_determinism_vp` | nfr-catalog.md NFR-003, NFR-011 | INCONSISTENT → FIXED |
| `cargo kani --harness <harness_name>` | BC-2.17.001 §Postconditions, tooling-selection.md | CONSISTENT (placeholder) |
| `cargo kani` (bare) | BC-2.17.001, VP-001.md, VP-002.md, tooling-selection.md | CONSISTENT |
| `cargo bench --bench runnable_overhead` | nfr-catalog.md NFR-001 | CONSISTENT (single citation) |
| `cargo bench --bench graph_throughput` | nfr-catalog.md NFR-007 | CONSISTENT (single citation) |
| `cargo xtask check-file-size` | nfr-catalog.md NFR-004, product-brief.md | CONSISTENT |
| `cargo xtask check-client-timeout` | nfr-catalog.md NFR-009, BC-2.08.007 | CONSISTENT |
| `cargo xtask deny-client-new` | prd.md NE-04, module-criticality.md, tooling-selection.md | CONSISTENT |
| `cargo xtask lint-no-timeout` | BC-2.14.004 | CONSISTENT (single citation; distinct from deny-client-new) |
| `cargo xtask lint-no-panic` | BC-2.14.003 | CONSISTENT (single citation) |
| `cargo xtask deny-bare-api-key` | BC-2.14.005 | CONSISTENT (single citation) |
| `cargo xtask deny-anyhow-in-lib` | ADR-010 | CONSISTENT (single citation) |
| `cargo xtask deny-description-cache-key` | ADR-011 | CONSISTENT (single citation) |
| `cargo xtask audit-constructors` | BC-2.14.003 | CONSISTENT (single citation) |
| `cargo xtask deny-expect-in-lib` | module-criticality.md, tooling-selection.md | CONSISTENT |
| `cargo check -p ferrochain-<provider>-sdk` | BC-2.08.006, module-decomposition.md, ADR-007 | CONSISTENT |
| `cargo fuzz run <target>` | tooling-selection.md | CONSISTENT (placeholder) |
| `cargo mutants --workspace` | tooling-selection.md | CONSISTENT (single citation) |
| `semgrep` (via xtask wrappers) | tooling-selection.md | CONSISTENT |

**Summary:** 1 inconsistency found and fixed (`bsp_determinism_vp` × 2 citations in nfr-catalog.md).
All other command strings are consistent across their citation sites.

---

## Observations (Non-Blocking)

**OBS-1 — harness_fn registry gap (NEW):**
The `harness_fn` column now added to VP-INDEX.md closes the gap identified: without it,
no single artifact listed the Phase-6 cargo-kani invocation identifiers. The column is
maintained in VP-INDEX as the standing registry; bc-authoring-plan gate #18 enforces
consistency on future edits.

**OBS-2 — NFR-006 scope stretch (non-blocking, pre-existing):**
NFR-006 validation method `cargo test -p ferrochain-standard-tests -- --include-ignored`
does not have a corresponding xtask wrapper. This is intentional per NFR-006 design
(raw `cargo test -p` invocation, not xtask-wrapped). Noted for completeness; no fix
required at Phase 1.

---

## Sibling Axis Results (PASS)

- **NE-axis full rebuild:** All 17 NEs verified across BC body, BC-INDEX NE Anchors,
  PRD §7 RTM, PRD §9 NE Disposition Table. No new issues beyond P16 fix already applied. PASS.
- **CAP/VP census:** All 5 VPs trace to valid CAP anchors. VP-INDEX counts consistent with
  verification-architecture.md and verification-coverage-matrix.md. PASS.
- **P12 lifecycle-arrow census reconfirmation:** No new `interrupted` terminal-state violations. PASS.
- **P13 anchor-matrix census reconfirmation:** No new drift on 86 BC × 6 axes. PASS.
- **P16 NE-anchor four-way census reconfirmation:** No new mismatches on NE-anchor axis. PASS.

---

## Strongest-Surviving Attack

**Full embedded-command sweep:** Confirm that every `cargo kani --harness <name>` invocation
in all spec documents uses a name that exists in VP-INDEX.md `harness_fn` column. With the
`harness_fn` column now established and the 10 failing sites fixed, this sweep produces zero
inconsistencies. The standing gate (bc-authoring-plan #18) closes the surface permanently.

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 1 |
| LOW | 0 |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — F-P17-01 fixed in this pass; counter 0/3
**Readiness:** requires confirmation pass (pass 18) to verify fixes held

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 17 |
| **New findings** | 1 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (1/1) |
| **Median severity** | 3.0 (MED) |
| **Trajectory** | →1→1→1 |
| **Verdict** | FINDINGS_REMAIN |
