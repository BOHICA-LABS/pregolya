---
document_type: story
level: ops
story_id: S-6.01
epic_id: E-22
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-19T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-17/BC-2.17.001.md
  - .factory/specs/behavioral-contracts/ss-17/BC-2.17.002.md
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/verification-architecture.md
input-hash: "8bcf23e"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.16, S-1.10, S-1.09, S-2.01, S-2.03, S-1.23, S-1.25, S-1.05, S-2.09]
blocks: []
behavioral_contracts: [BC-2.17.001, BC-2.17.002]
verification_properties: [VP-001, VP-002, VP-003, VP-006, VP-007, VP-008, VP-009, VP-010, VP-011, VP-012, VP-013, VP-014]
priority: P2
cycle: v1.0.0-greenfield
wave: 6
target_module: xtask
subsystems: [SS-17]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-6.01: Formal Verification Pipeline — Kani Proof Execution, cargo-fuzz Smoke Gate, and Phase-7 Convergence Gate

## Narrative

- **As a** pregolya core contributor completing Phase 6 (formal hardening)
- **I want** all nine Kani verification properties proven (`bsp_determinism_harness`, `session_tenancy_harness`, `workspace_confinement_harness`, `zero_norm_guard_fail_closed`, `allowlist_rejects_unregistered_id`, `deny_excludes_tool_invocation` [P0] + `injection_guard_fail_closed`, `watermark_arithmetic_harness`, `risk_floor_rejects_below_medium` [P1]), two cargo-fuzz targets (`fuzz_checkpoint_serde`, `fuzz_graph_execution`) compiled and corpus-validated, and the proptest suites (VP-007, VP-008, VP-014) confirmed passing against the Phase-3-complete workspace
- **So that** v1 convergence has a formally-verified foundation where security-critical invariants (workspace path confinement, PreToolCallHook fail-closed dispatch, reviver allowlist containment, zero-norm cosine guard) are proven by machine-checked proof, and the highest-complexity code paths (checkpoint serialization, graph execution) have been stress-tested against arbitrary input without panic or data corruption

> **GAP-002 resolution vehicle:** This story resolves GAP-002 in the dependency graph. The nine Kani harnesses are authored per-story in Waves 1 and 2 (as `todo!()` stub functions in `crates/*/src/proofs/` modules). S-6.01 is the aggregate execution contract: it defines WHAT must happen (harnesses compiled, proofs pass, fuzz targets green) once all Wave-1+2 crates are built. This is NOT a deferral — the harness stubs exist from Phase 3; S-6.01 drives the Phase-6 harness completion and proof run.

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.17.001 | Six P0 Kani VP Obligations + Three P1 Kani VP Obligations — D17-Q7+D21+D23 lock | P2 |
| BC-2.17.002 | cargo-fuzz Targets — Serialization Round-Trip (Checkpoint) and Graph-Execution Paths | P2 |

## Acceptance Criteria

### AC-001 (traces to BC-2.17.001 postcondition 1 — six P0 Kani harness functions exist)
Each of the six P0 Kani harness functions exists in its target crate `src/proofs/` module and
the harness file compiles (stub or full implementation):

| Harness function | Crate | Module |
|-----------------|-------|--------|
| `bsp_determinism_harness` | pregolya-graph | `graph::bsp_engine` |
| `session_tenancy_harness` | pregolya-checkpoint | `checkpoint::session_index` |
| `workspace_confinement_harness` | pregolya-sandbox | `sandbox::path_guard` |
| `zero_norm_guard_fail_closed` | pregolya-vectorstores | `vectorstores::similarity` |
| `allowlist_rejects_unregistered_id` | pregolya-core | `core::serializable` |
| `deny_excludes_tool_invocation` | pregolya-graph | `graph::hitl` |

`cargo kani` compile check passes for each harness crate on Linux and macOS CI runners.
Verified by `test_BC_2_17_001_six_p0_harness_files_compile()` (xtask compile-gate).

### AC-002 (traces to BC-2.17.001 postcondition 1 — three P1 Kani harness functions exist)
Each of the three P1 Kani harness functions exists in its target crate `src/proofs/` module
and compiles:

| Harness function | Crate | Module |
|-----------------|-------|--------|
| `injection_guard_fail_closed` | pregolya-prompts | `prompts::injection_guard` |
| `watermark_arithmetic_harness` | pregolya-core | `core::budget` |
| `risk_floor_rejects_below_medium` | pregolya-tools | `tools::shell` |

`cargo kani` compile check passes for each harness crate on Linux and macOS CI runners.
Verified by `test_BC_2_17_001_three_p1_harness_files_compile()` (xtask compile-gate).

### AC-003 (traces to BC-2.17.001 postcondition 2 — P0 VP proofs pass — Phase-7 gate)
**RED GATE**: The six P0 harness stubs (`todo!()` bodies) must compile and produce
VERIFICATION FAILED (or abort) before the harness bodies are implemented. After
implementation, `cargo kani --harness <fn>` terminates with `VERIFICATION SUCCESSFUL`
for each of the six P0 VPs:

| VP | Harness | Property proven |
|----|---------|----------------|
| VP-001 | `bsp_determinism_harness` | Identical `PregelTask` inputs → identical `GraphState` output regardless of task-arrival order |
| VP-002 | `session_tenancy_harness` | Distinct `(thread_id, checkpoint_ns, checkpoint_id)` triples → distinct storage addresses; no bare `thread_id` addressing |
| VP-003 | `workspace_confinement_harness` | `canonicalize_beneath_root(base, path)` stays within `base` or returns `Err(WorkspaceEscape)` — no escape path |
| VP-009 | `zero_norm_guard_fail_closed` | Zero-norm vector guard returns `E-VS-001` before any cosine division — no NaN propagation |
| VP-010 | `allowlist_rejects_unregistered_id` | Unregistered type id raises `E-SRLZ-001` and never dispatches a constructor |
| VP-011 | `deny_excludes_tool_invocation` | `Deny { .. }` routes to `DispatchOutcome::Reject`; `Approve` to `Proceed`; invalid-`Edit` falls back to `Reject`; hook errors shielded to `Deny { .. }` before routing; `#[non_exhaustive]` wildcard arm returns `Reject` |

Any of these six VPs resulting in VERIFICATION FAILED is a blocking Phase-7 convergence-gate
failure per BC-2.17.001 postcondition 3 and NFR-003.
Verified by `just kani-local` on Linux/macOS; CI job `kani-p0-gate` enforces all six pass.

### AC-004 (traces to BC-2.17.001 postcondition 2 — P1 VP proofs pass — Phase-6 gate)
**RED GATE**: The three P1 harness stubs must compile and produce VERIFICATION FAILED (or abort)
before implementation. After implementation, `cargo kani --harness <fn>` terminates with
VERIFICATION SUCCESSFUL for each of the three P1 VPs:

| VP | Harness | Property proven |
|----|---------|----------------|
| VP-006 | `injection_guard_fail_closed` | `injection_guard` raises `E-TMPL-001` for untrusted content in a `SystemMessage` slot at render time; fail-closed on unknown `TrustLevel` variant |
| VP-012 | `watermark_arithmetic_harness` | `OnWatermark` fires iff `tokens_remaining / ceiling <= (1.0 - fraction)` (f64 arithmetic, domain `0 <= tokens_remaining <= ceiling`); non-strict `<=` is load-bearing (fraction=1.0, tokens_remaining=0 boundary must fire); no overflow |
| VP-013 | `risk_floor_rejects_below_medium` | `ReadOnly` and `Low` `ActionRisk` on `BashTool` always return `Err(E-TOOLS-007)` — non-lowerable `Medium` risk floor |

P1 VP failures block Phase-6 completion only; they do NOT gate Phase-7.
Verified by `just kani-local` on Linux/macOS; CI job `kani-p1-gate` enforces all three pass.

### AC-005 (traces to BC-2.17.001 postcondition 3 — gate classification)
The CI pipeline classifies VP failures by tier:
- P0 VP failure (VP-001/002/003/009/010/011): `kani-p0-gate` fails → Phase-7 convergence BLOCKED
- P1 VP failure (VP-006/012/013): `kani-p1-gate` fails → Phase-6 completion BLOCKED (Phase-7 gate is VP-independent of P1)

The xtask `verify` command documents the gate tier in its output for each harness run.
Verified by `test_BC_2_17_001_gate_tier_classification()` (xtask output assertion).

### AC-006 (traces to BC-2.17.001 postcondition 5 — Kani does not substitute for Phase-3 tests)
The Phase-6 formal-verification gate requires BOTH: (a) all nine Kani VPs passing AND
(b) `cargo nextest run --workspace` passing (all Phase-3 unit and integration tests).
The CI `phase-6-gate` job declares explicit `needs:` dependencies on both
`kani-p0-gate`, `kani-p1-gate`, and `test-workspace-pass`. Neither Kani success alone
nor nextest success alone satisfies the gate.
Verified by `test_BC_2_17_001_combined_gate_requires_both_kani_and_nextest()` (CI workflow test).

### AC-007 (traces to BC-2.17.001 postcondition 4 + invariant 1 — D17-Q7+D21+D23 lock)
The Kani proof suite covers exactly nine VP targets (six P0 + three P1). The xtask
`verify --count-harnesses` subcommand enumerates registered harnesses and returns a
non-zero exit code if the count diverges from nine. No harness is added or removed
without an architect-approved ADR amendment (D17-Q7+D21+D23 lock). The harness
inventory in `xtask/src/verify.rs` is the single source of truth for the count.
Verified by `test_BC_2_17_001_harness_count_equals_nine()` (xtask count assertion).

### AC-008 (traces to BC-2.17.001 invariant 3 — proof completeness / unwind annotations)
Each bounded harness that uses `#[kani::unwind(N)]` includes a source comment immediately
above the annotation that (a) states the bound value `N`, (b) justifies why the bound is
sufficient for completeness over the relevant state space, and (c) records the architect
sign-off finding reference. A harness timeout without an unwind annotation (CI wall-clock
> 60 minutes per harness slot) is treated as a convergence failure, not a known limitation.
Verified by `test_BC_2_17_001_bounded_harnesses_have_justification_comments()` (source
scan in xtask verify).

### AC-009 (traces to BC-2.17.001 precondition 3 — Wave-1+2 prerequisite gate)
S-6.01 is dispatched only after all Wave-1 and Wave-2 story PRs are merged to `develop`
and `cargo nextest run --workspace` passes on `develop` HEAD. CI job `wave-gate-6`
declares `needs: [wave-2-complete]` and checks `develop` branch test-pass status before
the Phase-6 formal-verification jobs begin. Attempting to run `just kani-local` without
the crates compiled returns a meaningful error (not a silent crash).
Verified by `test_BC_2_17_001_wave_gate_blocks_kani_before_wave2_complete()` (xtask gate check).

### AC-010 (traces to BC-2.17.002 postcondition 1 — fuzz_checkpoint_serde target)
`fuzz/fuzz_targets/fuzz_checkpoint_serde.rs` exists. The fuzz target enforces:
- Arbitrary byte sequence input to `GraphState` deserialization returns `Ok(state)` or
  `Err(DeserializationError)` — no panic on any input.
- Round-trip sub-contract: for any `GraphState` that serializes to msgpack, deserializing
  the serialized bytes produces an equal state (`deser(ser(s)) == s` for all reachable `s`).

The fuzz oracle asserts discriminant-level correctness (not message text) on error paths.
Verified by `test_BC_2_17_002_fuzz_checkpoint_serde_target_exists_and_compiles()` (xtask check).

### AC-011 (traces to BC-2.17.002 postcondition 2 — fuzz_graph_execution target)
`fuzz/fuzz_targets/fuzz_graph_execution.rs` exists. The fuzz target enforces:
- Arbitrary fuzzer-generated `GraphDefinition` execution either completes or returns
  `Err(PregolyaError)` — no panic, no undefined behavior, no silent data corruption.
- The fuzzer reaches all three BSP super-step paths (normal completion, interrupt injection,
  empty-super-step no-op) within the seed corpus.
- A zero-node `GraphDefinition` returns `Err(PregolyaError { code: E-GRAPH-008,
  message: "UnreachableGraph: <reason>", .. })` — code discriminant is exact; message
  detail may vary per BC-2.17.002 EC-002 fuzz-oracle semantics.

Verified by `test_BC_2_17_002_fuzz_graph_execution_target_exists_and_compiles()` (xtask check).

### AC-012 (traces to BC-2.17.002 postcondition 3 — nightly fuzz build)
**RED GATE**: `cargo +nightly fuzz build` failing due to missing harness bodies is the Red
Gate state. After implementation, `cargo +nightly fuzz build` succeeds for both targets using
the nightly toolchain pinned in `rust-toolchain.toml`. Any compile error in either target is
a blocking Phase-6 failure.
Verified by `test_BC_2_17_002_nightly_fuzz_build_succeeds()` (CI compile gate `fuzz-build`).

### AC-013 (traces to BC-2.17.002 postcondition 4 — minimum corpus coverage)
Both fuzz targets run for a minimum of 10,000 corpus inputs seeded from Phase-3 test data
in `fuzz/corpus/` without new crash findings. The CI `fuzz-smoke` job enforces this minimum
corpus replay using `cargo +nightly fuzz run <target> -- -runs=10000`. The smoke run uses the
committed seed corpus (not extended fuzzing) to keep CI wall-clock bounded.
Verified by `test_BC_2_17_002_corpus_replay_10k_without_crash()` (CI fuzz-smoke gate).

### AC-014 (traces to BC-2.17.002 postcondition 5 — crash = blocking failure)
Any crash finding (panic, OOM abort, ASAN/MSAN report) from either fuzz target is a blocking
Phase-6 convergence failure. The crash input is saved to `fuzz/artifacts/<target>/` automatically
by libFuzzer. The Phase-6 gate remains BLOCKED until: (a) the crash is reproduced and fixed,
(b) a regression test is added to the Phase-3 `cargo nextest` suite for the minimized crash
input, and (c) the fuzz target reruns clean for 10,000 corpus inputs without the crash.
Verified by `test_BC_2_17_002_crash_finding_blocks_gate()` (CI gate dependency assertion).

### AC-015 (traces to BC-2.17.002 postcondition 6 — corpus committed)
The fuzz seed corpus is committed under `fuzz/corpus/fuzz_checkpoint_serde/` and
`fuzz/corpus/fuzz_graph_execution/` respectively. The CI `fuzz-smoke` job replays the
committed corpus on every PR that modifies files under `crates/pregolya-checkpoint/` or
`crates/pregolya-graph/`. The corpus directory is included in the repository (not gitignored).
Verified by `test_BC_2_17_002_corpus_directories_present_and_tracked()` (xtask check).

### AC-016 (traces to BC-2.17.002 invariant 2 — corpus persistence / ADR gate)
Removing or resetting the fuzz corpus requires an ADR entry explaining why corpus
diversity was discarded (BC-2.17.002 invariant 2). The CI `fuzz-smoke` job enforces corpus
presence via a pre-run check: if `fuzz/corpus/` is empty or absent, the job fails with
a human-readable error before invoking `cargo +nightly fuzz run`. No CI job silently
seeds an empty corpus without committing it.
Verified by `test_BC_2_17_002_corpus_presence_gate_fails_on_empty()` (xtask check).

### AC-017 (traces to BC-2.17.002 invariant 3 — nightly toolchain pin)
The nightly Rust toolchain used for cargo-fuzz is pinned in `rust-toolchain.toml`.
The `cargo +nightly fuzz build` and `cargo +nightly fuzz run` invocations in CI
and in `Justfile` recipes explicitly use `+nightly` to select the pinned toolchain.
Any change to the nightly pin in `rust-toolchain.toml` requires justification in the
commit message referencing the reason for the pin change (toolchain regression,
security fix, or feature requirement). Silently bumping the nightly pin without a
rationale comment is an adversarial review finding.
Verified by `test_BC_2_17_002_nightly_pin_change_requires_rationale()` (source scan in xtask verify).

### AC-018 (traces to BC-2.17.001 postcondition 2 — Kani Linux/macOS only, Windows concrete tests)
Kani proofs run on Linux and macOS CI runners only. The `kani-p0-gate` and `kani-p1-gate`
CI jobs declare `runs-on: [ubuntu-latest, macos-latest]` (not Windows). Windows CI runs
`cargo nextest run --workspace` (concrete unit and integration tests) as the Windows
correctness gate; Kani proof validity is platform-agnostic because the underlying Rust code
is identical on all platforms. The Justfile `kani-local` recipe includes a platform check
and prints a clear message on Windows (e.g., "Kani proofs require Linux or macOS; run concrete
unit tests with `just iter <crate>` on Windows").
Verified by `test_BC_2_17_001_kani_ci_jobs_platform_linux_macos_only()` (CI workflow lint in xtask).

### AC-019 (traces to BC-2.17.001 postcondition 2 — proptest VPs confirmed via aggregate nextest run)
VP-007 (`LcSerializable` round-trip proptest in `core::serializable`), VP-008 (embeddings
dimensionality proptest in `core::embeddings`), and VP-014 (`RunnableParallel` key-completeness
proptest in `core::runnable::parallel`) are Phase-3 proptest suites authored in their anchor
stories (S-2.01, S-2.09, S-1.05 respectively). S-6.01 confirms all three proptest suites
continue to pass against the Phase-3-complete codebase via the aggregate
`cargo nextest run --workspace` sweep run as part of the Phase-6 gate (see AC-006). The xtask
verify output reports proptest pass/fail per VP anchor. Regressions in these proptests after
Wave-2 integration constitute Phase-6 findings requiring root-cause investigation before
Phase-7 convergence.
Verified by `test_BC_2_17_001_proptest_vp_suite_passes_post_wave2()` (nextest workspace gate AC-006).

## Architecture Mapping

| Component | Module | Crate | Pure/Effectful |
|-----------|--------|-------|----------------|
| `bsp_determinism_harness` | `graph::bsp_engine` (proofs submodule) | pregolya-graph | pure-core (Kani proof function) |
| `session_tenancy_harness` | `checkpoint::session_index` (proofs submodule) | pregolya-checkpoint | pure-core (Kani proof function) |
| `workspace_confinement_harness` | `sandbox::path_guard` (proofs submodule) | pregolya-sandbox | pure-core (Kani proof function) |
| `zero_norm_guard_fail_closed` | `vectorstores::similarity` (proofs submodule) | pregolya-vectorstores | pure-core (Kani proof function) |
| `allowlist_rejects_unregistered_id` | `core::serializable` (proofs submodule) | pregolya-core | pure-core (Kani proof function) |
| `deny_excludes_tool_invocation` | `graph::hitl` (proofs submodule) | pregolya-graph | pure-core (Kani proof function) |
| `injection_guard_fail_closed` | `prompts::injection_guard` (proofs submodule) | pregolya-prompts | pure-core (Kani proof function) |
| `watermark_arithmetic_harness` | `core::budget` (proofs submodule) | pregolya-core | pure-core (Kani proof function) |
| `risk_floor_rejects_below_medium` | `tools::shell` (proofs submodule) | pregolya-tools | pure-core (Kani proof function) |
| `fuzz_checkpoint_serde` | `fuzz/fuzz_targets/` | fuzz (workspace member) | effectful (arbitrary I/O via libFuzzer) |
| `fuzz_graph_execution` | `fuzz/fuzz_targets/` | fuzz (workspace member) | effectful (arbitrary I/O via libFuzzer) |
| `xtask verify` subcommand | `xtask/src/verify.rs` | xtask | effectful (spawns cargo processes) |
| Justfile recipes (`kani-local`, `fuzz-local`) | `Justfile` | — | effectful (shell commands) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| All `src/proofs/*.rs` harness functions | pure-core | Kani harness bodies are pure functions over symbolic inputs; no I/O, no Tokio, no file access. |
| `fuzz/fuzz_targets/*.rs` | effectful | libFuzzer targets receive arbitrary byte slices from the fuzzer engine (OS I/O); they call production deserialization and graph-execution functions whose async paths are exercised synchronously via `tokio::runtime::Runtime::block_on`. |
| `xtask/src/verify.rs` | effectful | Spawns `cargo kani` and `cargo +nightly fuzz` child processes; reads stdout/stderr for gate assertions. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | VP-001 `bsp_determinism_harness` exceeds 60-minute CI wall-clock due to large state space | Harness must be bounded with `#[kani::unwind(N)]` annotation with justification comment; timeout without annotation = convergence failure (BC-2.17.001 EC-001) |
| EC-002 | One or more P0 VPs return VERIFICATION FAILED | Phase-7 convergence BLOCKED; Kani counterexample identifies the failing path; implementer receives counterexample and fixes the implementation; P1 failures block Phase-6 completion only (BC-2.17.001 EC-002) |
| EC-003 | Architect proposes adding a tenth VP after D17-Q7+D21+D23 lock | This BC's scope (nine VPs) must not be modified silently; architect-approved ADR amendment required; xtask harness count check will fail until amendment is approved and the harness inventory updated (BC-2.17.001 EC-003) |
| EC-004 | Post-Phase-6 refactor breaks VP-001 (BSP reducer change) | CI reruns `kani-p0-gate` on the refactored code; VERIFICATION FAILED blocks the PR; harness is a living gate, not a one-time proof (BC-2.17.001 EC-004) |
| EC-005 | Fuzzer generates malformed msgpack bytes for `fuzz_checkpoint_serde` | Deserialization returns `Err(DeserializationError)` — no panic; fuzz target counts as non-crash handled error (BC-2.17.002 EC-001) |
| EC-006 | Fuzzer generates cyclic graph topology for `fuzz_graph_execution` | Executor detects cycle and returns `Err(PregolyaError)` — no panic, no live-lock; cycle detection is bounded (BC-2.17.002 EC-003) |
| EC-007 | `cargo +nightly fuzz build` fails on CI due to nightly toolchain change | Toolchain pin in `rust-toolchain.toml` is bumped to a compatible nightly with rationale; the fuzz-build job is always run after the pin change to confirm compilation still passes (BC-2.17.002 invariant 3) |
| EC-008 | Platform is Windows; `just kani-local` is invoked | Recipe prints clear platform-constraint message and exits non-zero without attempting Kani execution; Windows CI runs concrete nextest suite instead (BC-2.17.001 postcondition 2 + CLAUDE.md Kani platform note) |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~5,800 |
| BC-2.17.001 (full file) | ~4,200 |
| BC-2.17.002 (full file) | ~3,000 |
| VP-INDEX.md (catalog rows) | ~1,800 |
| VP-001 through VP-011 Kani harness specs (9 files × ~700 tokens each) | ~6,300 |
| VP-007, VP-008, VP-014 proptest specs (3 files × ~600 tokens each) | ~1,800 |
| `module-decomposition.md` (SS-17 + affected crate sections) | ~1,500 |
| `verification-architecture.md` (provable properties catalog) | ~2,000 |
| Existing harness stub files (9 files × ~40 lines each) | ~3,000 |
| `fuzz/fuzz_targets/` stubs (2 files × ~60 lines each) | ~1,000 |
| `xtask/src/verify.rs` (new; ~200 lines) | ~1,500 |
| Justfile additions (recipes) | ~300 |
| Tool outputs (cargo kani stdout) | ~800 |
| **Total** | **~33,000** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~16.5%** |

## Tasks (MANDATORY)

1. [ ] (test-writer) Write failing Red Gate stubs for AC-003 and AC-004: confirm all nine Kani harness `todo!()` bodies compile but produce VERIFICATION FAILED or panic-abort under `cargo kani --harness <fn>`. Verify Red Gate density ≥ 0.5 across harness files.
2. [ ] (test-writer) Write failing Red Gate stub for AC-012: confirm `cargo +nightly fuzz build` fails before fuzz target bodies are implemented.
3. [ ] (formal-verifier) Complete `bsp_determinism_harness` body in `crates/pregolya-graph/src/proofs/bsp_determinism.rs` (VP-001): symbolic inputs over `Vec<PregelTask>`; assert identical output regardless of task-arrival order.
4. [ ] (formal-verifier) Complete `session_tenancy_harness` body in `crates/pregolya-checkpoint/src/proofs/session_tenancy.rs` (VP-002): symbolic `(thread_id, checkpoint_ns, checkpoint_id)` triples; assert distinct addresses and no bare `thread_id` addressing.
5. [ ] (formal-verifier) Complete `workspace_confinement_harness` body in `crates/pregolya-sandbox/src/proofs/workspace_confinement.rs` (VP-003): symbolic `base` and `path`; assert `canonicalize_beneath_root` stays within `base` or returns `Err(WorkspaceEscape)`.
6. [ ] (formal-verifier) Complete `zero_norm_guard_fail_closed` body in `crates/pregolya-vectorstores/src/proofs/zero_norm_guard.rs` (VP-009): symbolic `f32` embedding vector; assert zero-norm guard fires before cosine division.
7. [ ] (formal-verifier) Complete `allowlist_rejects_unregistered_id` body in `crates/pregolya-core/src/proofs/reviver_allowlist.rs` (VP-010): symbolic type-id string; assert unregistered id raises `E-SRLZ-001` and never dispatches a constructor.
8. [ ] (formal-verifier) Complete `deny_excludes_tool_invocation` body in `crates/pregolya-graph/src/proofs/pre_tool_hook.rs` (VP-011): symbolic `PreToolDecision` variants (Approve/Deny/Edit) and hook-error path; assert fail-closed routing per BC-2.17.001 postcondition 1 VP-011 specification.
9. [ ] (formal-verifier) Complete `injection_guard_fail_closed` body in `crates/pregolya-prompts/src/proofs/injection_guard.rs` (VP-006): symbolic `TrustLevel` and slot; assert fail-closed → `Err(E-TMPL-001)`.
10. [ ] (formal-verifier) Complete `watermark_arithmetic_harness` body in `crates/pregolya-core/src/proofs/watermark.rs` (VP-012): symbolic `tokens_remaining`, `ceiling`, `fraction`; assert `OnWatermark` fires iff `tokens_remaining / ceiling <= (1.0 - fraction)` (f64; non-strict `<=`).
11. [ ] (formal-verifier) Complete `risk_floor_rejects_below_medium` body in `crates/pregolya-tools/src/proofs/risk_floor.rs` (VP-013): symbolic `ActionRisk`; assert `ReadOnly` and `Low` always return `Err(E-TOOLS-007)`.
12. [ ] (formal-verifier) Add `#[kani::unwind(N)]` annotation with justification comment to any harness exceeding CI wall-clock limit; record architect sign-off finding reference in the comment (AC-008).
13. [ ] (implementer) Implement `fuzz/fuzz_targets/fuzz_checkpoint_serde.rs`: no-panic deserialization of arbitrary bytes; round-trip sub-contract `deser(ser(s)) == s` (AC-010).
14. [ ] (implementer) Implement `fuzz/fuzz_targets/fuzz_graph_execution.rs`: no-panic execution of arbitrary `GraphDefinition`; assert all three BSP super-step paths reachable from seed corpus (AC-011).
15. [ ] (devops-engineer) Wire `xtask/src/verify.rs` `--count-harnesses` subcommand: enumerate nine harness registrations; exit non-zero if count ≠ 9 (AC-007).
16. [ ] (devops-engineer) Add CI jobs `kani-p0-gate`, `kani-p1-gate`, `fuzz-build`, `fuzz-smoke`, `wave-gate-6` per AC-005, AC-006, AC-009, AC-012, AC-013.
17. [ ] (devops-engineer) Seed `fuzz/corpus/fuzz_checkpoint_serde/` and `fuzz/corpus/fuzz_graph_execution/` from Phase-3 test data; commit corpus (AC-015).
18. [ ] (devops-engineer) Add `kani-local`, `fuzz-local` Justfile recipes with platform check for Windows (AC-018).
19. [ ] Run `just kani-local` on Linux/macOS — confirm all nine harnesses pass VERIFICATION SUCCESSFUL.
20. [ ] Run `cargo +nightly fuzz run fuzz_checkpoint_serde -- -runs=10000` — confirm no crashes.
21. [ ] Run `cargo +nightly fuzz run fuzz_graph_execution -- -runs=10000` — confirm no crashes.
22. [ ] Run `cargo nextest run --workspace` — confirm proptest VP-007, VP-008, VP-014 suites pass (AC-019).
23. [ ] Run `cargo xtask verify --count-harnesses` — confirm count = 9 (AC-007).

## Previous Story Intelligence (MANDATORY)

S-6.01 is the terminal node in the dependency graph (Wave 6, batch 6a). All Wave-1 and Wave-2
stories must be merged before S-6.01 is dispatched.

**Key predecessor context for formal verifier:**

- **S-1.16 (BSP Engine)** established `reduce_super_step` in `graph::bsp_engine` — VP-001
  harness targets this function. The harness was stubbed as `todo!()` in S-1.16's Phase-3
  delivery. S-6.01 fills the stub.

- **S-1.10 (Checkpoint Core)** established the `(thread_id, checkpoint_ns, checkpoint_id)`
  triple-address uniqueness invariant in `checkpoint::session_index` — VP-002 harness targets
  the address-derivation function. The harness was stubbed in S-1.10.

- **S-1.09 (Sandbox)** established `canonicalize_beneath_root` in `sandbox::path_guard` — VP-003
  harness targets this function. The harness was stubbed in S-1.09.

- **S-2.03 (VectorStore)** established `cosine_similarity` zero-norm guard in
  `vectorstores::similarity` — VP-009 harness was stubbed in S-2.03.

- **S-2.01 (LC Serialization)** established the `OnceLock` allowlist reviver in
  `core::serializable` — VP-010 harness was stubbed in S-2.01. The proptest VP-007 suite
  (round-trip) was authored in S-2.01 and must still pass.

- **S-1.23 (PreToolCallHook)** established `route_pre_tool_decision` and
  `shield_hook_result` in `graph::hitl` — VP-011 harness was stubbed in S-1.23. Critical
  constraint from S-1.23: `PendingHumanApproval` is peeled off upstream in `pre_tool_dispatch`
  before `route_pre_tool_decision` is called; the Kani harness covers only the three routable
  variants (Approve/Deny/Edit) + hook-error path per BC-2.17.001 postcondition 1 VP-011
  specification.

- **S-1.25 (Compaction)** established `OnWatermark` arithmetic in `core::budget` — VP-012
  harness was stubbed in S-1.25. The non-strict `<=` boundary (fraction=1.0,
  tokens_remaining=0) is load-bearing — do NOT tighten to strict `<`.

- **S-1.05 (LCEL)** established `RunnableParallel` key-completeness in `core::runnable` —
  VP-014 proptest was authored in S-1.05 and must still pass post-integration.

- **S-2.09 (Embeddings)** established the dimensionality invariant proptest VP-008 in
  `core::embeddings` — must still pass post-integration.

**GAP-002 context:** GAP-002 in the dependency graph documented that Kani harness EXECUTION
requires all Wave-1+2 crates compiled. The harness stubs authored per-story in Waves 1 and 2
are `todo!()` bodies (Phase-3 TDD discipline: stubs compile, proofs fail). S-6.01 is the
story where those stubs are COMPLETED to produce VERIFICATION SUCCESSFUL. This is the
resolution vehicle for GAP-002 — not a deferral but an execution-ordering necessity.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| Kani harnesses run on Linux and macOS only — not Windows | CLAUDE.md §Formal Verification; BC-2.17.001 postcondition 2 | CI job matrix `platform: [ubuntu-latest, macos-latest]`; Justfile platform check (AC-018) |
| Harness count must equal exactly nine | BC-2.17.001 postcondition 4 + invariant 1 (D17-Q7+D21+D23 lock) | `cargo xtask verify --count-harnesses` gate (AC-007) |
| P0 VP failure blocks Phase-7; P1 failure blocks Phase-6 only | BC-2.17.001 postcondition 3 | CI job dependency chain: `kani-p0-gate` → Phase-7 gate; `kani-p1-gate` → Phase-6 gate (AC-005) |
| `PendingHumanApproval` excluded from VP-011 harness | BC-2.17.001 postcondition 1 (VP-011 bullet) | Harness body; code comment stating `PendingHumanApproval` coverage lives in the S-1.23 HITL interrupt/resume integration tests, not the Kani harness |
| Non-strict `<=` in VP-012 `OnWatermark` arithmetic | BC-2.17.001 postcondition 1 (VP-012 bullet) | Harness assertion uses `<=`; adversarial review checks for off-by-one |
| No-panic contract on all fuzz targets | BC-2.17.002 invariant 1; DI-008 | libFuzzer ASAN/MSAN instrumentation; `cargo +nightly fuzz run` exit-code assertion |
| Fuzz corpus committed and non-empty | BC-2.17.002 invariant 2 + postcondition 6 | CI corpus-presence pre-run check (AC-016) |
| Nightly toolchain pin in `rust-toolchain.toml` — explicit for fuzz commands | BC-2.17.002 invariant 3 | `+nightly` flag on all fuzz invocations; pin-change rationale requirement (AC-017) |
| Kani proofs are a living gate — re-run on every post-Phase-6 PR touching verified modules | BC-2.17.001 EC-004 | CI path-trigger on `crates/{pregolya-graph,pregolya-checkpoint,pregolya-sandbox,pregolya-core,pregolya-vectorstores,pregolya-prompts,pregolya-tools}/` → `kani-p0-gate` |
| Kani success does NOT substitute for Phase-3 nextest | BC-2.17.001 postcondition 5 | CI `phase-6-gate` requires both `kani-p0-gate` and `test-workspace-pass` (AC-006) |

**Forbidden dependencies:** `crates/*/src/proofs/*.rs` harness modules must NOT depend on
`tokio`, network clients, file I/O, or any effectful crate. Kani proofs operate on symbolic
values; any effectful import will cause `cargo kani` to abort with an unsupported-operation
error. If a harness needs to call an async function, use `#[tokio::test]` in a separate unit
test — do NOT run Tokio runtimes inside Kani harnesses.

## Library & Framework Requirements (MANDATORY)

| Tool | Workspace pin | Purpose |
|------|--------------|---------|
| `kani` (via `cargo kani`) | workspace pin per `rust-toolchain.toml` | Bounded model checking for the nine VP harnesses |
| `cargo-fuzz` (via `cargo +nightly fuzz`) | pinned nightly per `rust-toolchain.toml` | LibFuzzer-based coverage-guided fuzzing for `fuzz_checkpoint_serde` and `fuzz_graph_execution` |
| `cargo-mutants` | workspace pin | Mutation kill-rate gate at wave 6 convergence; applied to harness-covered modules |
| `semgrep` | workspace pin | Security scan on CI as part of Phase-6 formal hardening gate |
| `cargo nextest` | workspace pin | Aggregate workspace test sweep confirming proptest VPs (VP-007, VP-008, VP-014) pass post-integration |

> Version pins are the workspace-level pins in `Cargo.toml` and `rust-toolchain.toml`.
> Do NOT embed specific version numbers in this story — use the workspace pin as the
> authoritative reference per TD-VSDD-091.

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `crates/pregolya-graph/src/proofs/bsp_determinism.rs` | COMPLETE (stub exists from S-1.16) | VP-001 Kani harness — `bsp_determinism_harness` |
| `crates/pregolya-graph/src/proofs/pre_tool_hook.rs` | COMPLETE (stub exists from S-1.23) | VP-011 Kani harness — `deny_excludes_tool_invocation` |
| `crates/pregolya-checkpoint/src/proofs/session_tenancy.rs` | COMPLETE (stub exists from S-1.10) | VP-002 Kani harness — `session_tenancy_harness` |
| `crates/pregolya-sandbox/src/proofs/workspace_confinement.rs` | COMPLETE (stub exists from S-1.09) | VP-003 Kani harness — `workspace_confinement_harness` |
| `crates/pregolya-vectorstores/src/proofs/zero_norm_guard.rs` | COMPLETE (stub exists from S-2.03) | VP-009 Kani harness — `zero_norm_guard_fail_closed` |
| `crates/pregolya-core/src/proofs/reviver_allowlist.rs` | COMPLETE (stub exists from S-2.01) | VP-010 Kani harness — `allowlist_rejects_unregistered_id` |
| `crates/pregolya-core/src/proofs/watermark.rs` | COMPLETE (stub exists from S-1.25) | VP-012 Kani harness — `watermark_arithmetic_harness` |
| `crates/pregolya-prompts/src/proofs/injection_guard.rs` | COMPLETE (stub exists from S-2.05) | VP-006 Kani harness — `injection_guard_fail_closed` |
| `crates/pregolya-tools/src/proofs/risk_floor.rs` | COMPLETE (stub exists from S-1.22) | VP-013 Kani harness — `risk_floor_rejects_below_medium` |
| `fuzz/fuzz_targets/fuzz_checkpoint_serde.rs` | CREATE | cargo-fuzz target 1 (BC-2.17.002 postcondition 1) |
| `fuzz/fuzz_targets/fuzz_graph_execution.rs` | CREATE | cargo-fuzz target 2 (BC-2.17.002 postcondition 2) |
| `fuzz/Cargo.toml` | CREATE | Fuzz workspace member manifest; declares `[dependencies.pregolya-graph]` and `[dependencies.pregolya-checkpoint]` |
| `fuzz/corpus/fuzz_checkpoint_serde/` | CREATE (seed from Phase-3 test data) | Seed corpus for serialization fuzzer |
| `fuzz/corpus/fuzz_graph_execution/` | CREATE (seed from Phase-3 test data) | Seed corpus for graph-execution fuzzer |
| `xtask/src/verify.rs` | CREATE | `cargo xtask verify` subcommand — harness-count gate, platform check, gate-tier classification |
| `xtask/src/main.rs` | MODIFY | Register `verify` subcommand |
| `Justfile` | MODIFY | Add `kani-local`, `fuzz-local <crate> <target>`, `mutants`, `semgrep` recipes (per CLAUDE.md recipe list) |
| `.github/workflows/phase-6-formal.yml` | CREATE | CI jobs: `kani-p0-gate`, `kani-p1-gate`, `fuzz-build`, `fuzz-smoke`, `wave-gate-6`, `phase-6-gate` |

## Demo Plan

**Demo artifact:** Terminal recording via `just record-demo S-6.01` (VHS cassette).

**AC-003/AC-004 demo (Kani proof pass):**
```
$ just kani-local
[kani] bsp_determinism_harness      VERIFICATION SUCCESSFUL (VP-001 P0)
[kani] session_tenancy_harness      VERIFICATION SUCCESSFUL (VP-002 P0)
[kani] workspace_confinement_harness VERIFICATION SUCCESSFUL (VP-003 P0)
[kani] zero_norm_guard_fail_closed  VERIFICATION SUCCESSFUL (VP-009 P0)
[kani] allowlist_rejects_unregistered_id VERIFICATION SUCCESSFUL (VP-010 P0)
[kani] deny_excludes_tool_invocation VERIFICATION SUCCESSFUL (VP-011 P0)
[kani] injection_guard_fail_closed  VERIFICATION SUCCESSFUL (VP-006 P1)
[kani] watermark_arithmetic_harness VERIFICATION SUCCESSFUL (VP-012 P1)
[kani] risk_floor_rejects_below_medium VERIFICATION SUCCESSFUL (VP-013 P1)
[kani] All 9/9 harnesses: PASS  (6 P0 Phase-7 gates + 3 P1 Phase-6 gates)
```

**AC-012/AC-013 demo (fuzz build + smoke):**
```
$ cargo +nightly fuzz build
   Compiling fuzz_checkpoint_serde ...  Finished
   Compiling fuzz_graph_execution ...   Finished
$ cargo +nightly fuzz run fuzz_checkpoint_serde -- -runs=10000
   10000 runs completed. No crashes found.
$ cargo +nightly fuzz run fuzz_graph_execution -- -runs=10000
   10000 runs completed. No crashes found.
```

**AC-007 demo (harness count gate):**
```
$ cargo xtask verify --count-harnesses
   Harness inventory: 9/9 registered. Gate: PASS.
```

Each demo output is captured per-AC as a VHS cassette and attached to the Phase-6 PR body.
