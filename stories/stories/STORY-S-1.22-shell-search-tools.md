---
document_type: story
level: ops
story_id: S-1.22
epic_id: E-13
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-23/BC-2.23.005.md
  - .factory/specs/behavioral-contracts/ss-23/BC-2.23.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "975cb13"
traces_to:
  - behavioral-contracts/BC-2.23.005
  - behavioral-contracts/BC-2.23.006
points: 8
depends_on: [S-1.09, S-1.21, S-1.06]
blocks: [S-6.01]
behavioral_contracts: [BC-2.23.005, BC-2.23.006]
verification_properties: [VP-013]
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-tools
subsystems: [SS-23]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: N/A — BCs authored (BC-2.23.005, BC-2.23.006)
---

# STORY-S-1.22: Shell and Search Tools (BashTool, GrepTool)

## Narrative

As a graph node author, I want `BashTool` and `GrepTool` implementations so that agents can execute sandboxed shell commands and perform workspace-confined regex searches, with a non-lowerable Medium risk floor on BashTool ensuring no low-risk configuration of a shell executor can bypass the pre-tool-call approval hook.

## Token Budget Estimate

| Context Component | Estimated Tokens |
|-------------------|-----------------|
| This story spec | ~4,500 |
| BC files (2 BCs: BC-2.23.005–006) | ~7,000 |
| Architecture module-decomposition.md | ~3,000 |
| Target source files (pregolya-tools/src/shell/, search/) | ~8,000 |
| Test files | ~10,000 |
| S-1.06 (tool retry / circuit breaker) interface | ~2,500 |
| S-1.09 (PathGuard) confinement API | ~2,000 |
| **Total estimate** | **~37,000** |

Comfortable within context window. No split required.

## Behavioral Contracts

| BC ID | Title | Red Gate? |
|-------|-------|-----------|
| BC-2.23.005 | BashTool — sandboxed shell with non-lowerable Medium risk floor | No |
| BC-2.23.006 | GrepTool — hermetic in-process regex search with confinement | No |

## Acceptance Criteria

### AC-001: BashTool — default ActionRisk is High
`BashTool::action_risk()` returns `ActionRisk::High` by default. This is the baseline tier applied when no `ToolConfig::override_risk` is specified.
(traces to BC-2.23.005 postcondition 1)

### AC-002: BashTool — risk floor is Medium; cannot be lowered below Medium
`ToolConfig::override_risk(ActionRisk::ReadOnly)` returns `Err` at call time. `ToolConfig::override_risk(ActionRisk::Medium)` returns `Ok`. The builder-consuming validator ensures the registry never receives a `BashTool` configured below `ActionRisk::Medium`. This property is the seed for VP-013 (Kani P1).
(traces to BC-2.23.005 postcondition 2)

### AC-003: BashTool — 256 KiB output cap (exactly 262,144 bytes)
Combined stdout + stderr output is capped at 262,144 bytes. If the process emits more, the output is truncated and `BashOutput::truncated` is set to `true`. The error code `E-TOOLS-005` is a non-raised payload flag (set on `BashOutput`), not returned as `Err`.
(traces to BC-2.23.005 postcondition 3)

### AC-004: BashTool — 30-second timeout via tokio::time::timeout
`tokio::time::timeout(Duration::from_secs(30), sandbox.execute(cmd))` wraps every command execution. On timeout, returns `Err(PregolyaError { code: "E-TOOLS-004", .. })`.
(traces to BC-2.23.005 postcondition 4)

### AC-005: BashTool — non-zero exit code is NOT Err
`BashOutput { stdout, stderr, exit_code: 1, truncated: false }` is returned as `Ok(BashOutput { .. })`, not as `Err`. Non-zero exit code is part of the normal output payload. Only timeout and confinement violations produce `Err`.
(traces to BC-2.23.005 postcondition 5)

### AC-006: BashTool — risk tier violation error E-TOOLS-007
If the runtime risk tier passed at invoke time is lower than `ActionRisk::Medium` (should not occur after call-time validation, but as a defense-in-depth check), returns `Err(PregolyaError { code: "E-TOOLS-007", .. })`.
(traces to BC-2.23.005 postcondition 6)

### AC-007: GrepTool — in-process regex search using `regex` crate (linear-time DFA)
`GrepTool::invoke` performs regex matching entirely in-process using `regex = "1"` (linear-time DFA). No subprocess is spawned. Behavior is hermetic (no filesystem side effects other than reads).
(traces to BC-2.23.006 postcondition 1)

### AC-008: GrepTool — PathGuard confinement on directory traversal
`canonicalize_beneath_root` is applied to the search root before any traversal. An attempt to search outside the workspace returns `Err(PregolyaError { code: "E-TOOLS-001", .. })`.
(traces to BC-2.23.006 postcondition 2)

### AC-009: GrepTool — max_results cap of 100; capped flag
When the number of matches reaches 100, `GrepTool` stops collecting matches and sets `GrepResult::capped = true`. `E-TOOLS-006` is NOT raised as `Err`; it is a non-raised payload flag reflected in `GrepResult::capped`.
(traces to BC-2.23.006 postcondition 3)

### AC-010: GrepTool — traversal I/O error fails entire search
If a filesystem I/O error occurs during directory traversal (e.g., permission denied on a subdirectory), `GrepTool` returns `Err(PregolyaError { code: "E-TOOLS-008", .. })`. Partial results are NOT returned. The entire search fails.
(traces to BC-2.23.006 postcondition 4)

### AC-011: GrepTool — invalid regex returns E-TOOLS-009
Providing a regex pattern that fails to compile returns `Err(PregolyaError { code: "E-TOOLS-009", .. })` before any filesystem traversal.
(traces to BC-2.23.006 postcondition 5)

### AC-012: GrepTool — GrepResult payload: matches with file, line, text
`GrepResult::matches` is `Vec<GrepMatch>` where each `GrepMatch` has `file: PathBuf`, `line: u64`, and `text: String`. ActionRisk is `ActionRisk::ReadOnly`.
(traces to BC-2.23.006 invariant 1)

### AC-013: VP-013 seed — ToolConfig::override_risk call-time validation (Kani anchor)
This story is the VP-013 anchor. The Kani harness for VP-013 must verify: for all `ActionRisk` variants `r`, `BashTool::validate_risk(r)` returns `Ok` iff `r >= ActionRisk::Medium`, else `Err`. The test vector `test_AC_013_bash_risk_floor_kani_seed` exercises both the rejection of `ReadOnly` and the acceptance of `Medium`.
(traces to BC-2.23.005 invariant 1)

## Architecture Mapping

| Component | Module | Crate | Pure/Effectful |
|-----------|--------|-------|---------------|
| `BashTool` | `pregolya_tools::shell::bash` | pregolya-tools | Effectful (subprocess sandbox) |
| `BashOutput` | `pregolya_tools::shell::bash` | pregolya-tools | Pure (data type) |
| `GrepTool` | `pregolya_tools::search::grep` | pregolya-tools | Effectful (filesystem traversal) |
| `GrepResult`, `GrepMatch` | `pregolya_tools::search::grep` | pregolya-tools | Pure (data types) |
| `ToolConfig::override_risk` | `pregolya_tools::config` | pregolya-tools | Pure (builder-consuming validator) |
| `canonicalize_beneath_root` | `pregolya_tools::sandbox` | pregolya-tools | Pure |

**Subsystem anchor:** SS-23 owns this story's scope because SS-23 is the Tool Implementations subsystem per ARCH-INDEX Subsystem Registry. `BashTool` and `GrepTool` are concrete tool implementations in SS-23. The risk floor policy is enforced within SS-23 at `ToolConfig` construction time.

**Dependency anchors:**
- Depends on S-1.09: `canonicalize_beneath_root` used by `GrepTool` for workspace confinement.
- Depends on S-1.21: `pregolya-tools` crate workspace entry and shared types (`ActionRisk`, `DynTool`) established in S-1.21.
- Depends on S-1.06: `retry_eligible` and circuit-breaker policy integration. BashTool command timeout behavior is tested with retry policy's `record` method.

## Purity Classification

| Function / Type | Pure or Effectful | Reason |
|----------------|-------------------|--------|
| `ToolConfig::override_risk` | Pure | Builder validator; no I/O |
| `BashTool::action_risk` | Pure | Returns constant variant |
| `BashTool::invoke` | Effectful | Spawns process, waits, captures output |
| `GrepTool::invoke` | Effectful | Traverses filesystem, reads files |
| `GrepResult` construction | Pure | Data aggregation only |

## Edge Cases

| ID | Source | Description | Expected Behavior |
|----|--------|-------------|-------------------|
| EC-001 | BC-2.23.005 EC-1 | `override_risk(ReadOnly)` on BashTool | `Err` at call time; registry never receives config |
| EC-002 | BC-2.23.005 EC-2 | `override_risk(Medium)` on BashTool | `Ok`; Medium floor is exactly the floor, not below it |
| EC-003 | BC-2.23.005 EC-3 | Process exceeds 262,144 bytes combined output | Truncated; `BashOutput::truncated = true`; `Ok` returned |
| EC-004 | BC-2.23.005 EC-4 | Process exceeds 30s | `Err(E-TOOLS-004)` |
| EC-005 | BC-2.23.005 EC-5 | Process exits non-zero | `Ok(BashOutput { exit_code: N, .. })` — never `Err` |
| EC-006 | BC-2.23.006 EC-1 | Invalid regex pattern | `Err(E-TOOLS-009)` before traversal |
| EC-007 | BC-2.23.006 EC-2 | 101st match | Stop at 100; `capped = true`; `Ok` |
| EC-008 | BC-2.23.006 EC-3 | Permission denied on subdirectory during traversal | `Err(E-TOOLS-008)` — fail whole search |
| EC-009 | BC-2.23.006 EC-4 | Search root escapes workspace | `Err(E-TOOLS-001)` |
| EC-010 | BC-2.23.006 EC-5 | Zero matches found | `Ok(GrepResult { matches: [], capped: false })` |

## Tasks

- [ ] Create `crates/pregolya-tools/src/shell/mod.rs` (re-exports)
- [ ] Create `crates/pregolya-tools/src/shell/bash.rs` — `BashTool`, `BashOutput`, `BashConfig`
- [ ] Create `crates/pregolya-tools/src/search/mod.rs` (re-exports)
- [ ] Create `crates/pregolya-tools/src/search/grep.rs` — `GrepTool`, `GrepResult`, `GrepMatch`
- [ ] Create `crates/pregolya-tools/src/config.rs` — `ToolConfig::override_risk` builder-consuming validator
- [ ] Write failing tests for AC-001..AC-013 before any implementation
- [ ] Write `test_AC_013_bash_risk_floor_kani_seed` — exercises VP-013 property
- [ ] Implement `ToolConfig::override_risk` — return `Err` for `ActionRisk` below Medium
- [ ] Implement `BashTool::invoke` — tokio::time::timeout(30s), 262,144-byte cap, non-zero exit Ok
- [ ] Implement `GrepTool::invoke` — `regex = "1"` in-process, fail-whole-search on I/O error, cap at 100
- [ ] Add `regex = { version = "1", default-features = false, features = ["std"] }` to `pregolya-tools/Cargo.toml`
- [ ] Verify `GrepTool::action_risk()` returns `ActionRisk::ReadOnly`
- [ ] Create `crates/pregolya-tools/src/proofs/risk_floor.rs` — `#[cfg(kani)]` `risk_floor_rejects_below_medium` stub (body `todo!()` for Phase 6 formal hardening; VP-013)
- [ ] Run `just iter pregolya-tools` — all tests green

## Previous Story Intelligence

**From S-1.21 (Filesystem Tools):**
- `ToolConfig` was introduced in S-1.21's config module. S-1.22 extends `ToolConfig` with `override_risk` validator.
- The `.pregolyatmp_<random>` temp write pattern is NOT used in this story — BashTool and GrepTool don't write files.
- Error code discrimination established in S-1.21: `E-TOOLS-001` = scope escape; `E-TOOLS-008` = OS I/O error. Same discrimination applies here.

**From S-1.09 (Sandbox Backend & PathGuard):**
- `canonicalize_beneath_root` is the canonical API for GrepTool confinement.
- Same two-phase fallback (Phase-2 returns `Ok(path)` even when path doesn't exist) applies — but for GrepTool the search root must exist, so `NotFound` is `E-TOOLS-008`.

**From S-1.06 (Tool Retry / Circuit Breaker):**
- `retry_eligible` on BashTool: bash commands are not retry-eligible by default (destructive side effects). Override requires explicit configuration.

## Architecture Compliance Rules

1. **Non-lowerable risk floor is a call-time invariant.** `ToolConfig::override_risk` must call the validator immediately, before storing the override. The registry must never receive a `BashTool` with `ActionRisk::ReadOnly`.
2. **No subprocess in GrepTool.** GrepTool is hermetic — uses `regex = "1"` in-process. No `Command::new("grep")` or `Command::new("rg")` anywhere in `grep.rs`.
3. **Fail-whole-search on I/O error.** GrepTool must NOT return partial results on traversal error. The entire `invoke` returns `Err(E-TOOLS-008)`.
4. **Truncation payload, not error.** BashTool 262,144-byte cap sets `BashOutput::truncated = true` and returns `Ok`. It does NOT return `Err(E-TOOLS-005)`.
5. **No `unwrap()` / `expect()` in production code.**
6. **`mod.rs` re-export only.** `shell/mod.rs` and `search/mod.rs` contain only `pub use` declarations.
7. **`#[non_exhaustive]`** on `BashOutput`, `GrepResult`, `GrepMatch` (public API surface types).
8. **Forbidden dependency:** `pregolya-tools` must NOT depend on `pregolya-graph` or `pregolya-server`.

## Library & Framework Requirements

| Library | Version | Feature Flags | License | Usage |
|---------|---------|--------------|---------|-------|
| `regex` | `1` | `default-features = false, features = ["std"]` | MIT/Apache-2.0 | Linear-time DFA regex in GrepTool |
| `tokio` | (workspace pin) | `time`, `process` features | MIT | Timeout + subprocess spawn in BashTool |
| `tracing` | (workspace pin) | default | MIT | Structured logging |
| `pregolya-core` | (workspace) | — | — | `PregolyaError`, `ActionRisk` |

**Do NOT add:** `grep`, `ripgrep`, or any subprocess-based grep dependency. GrepTool is in-process only.

## File Structure Requirements

```
crates/pregolya-tools/
  Cargo.toml                         # add: regex = "1" default-features = false features = ["std"]
  src/
    lib.rs                           # add pub use shell::*; pub use search::*; pub use config::*;
    shell/
      mod.rs                         # re-export only
      bash.rs                        # BashTool, BashOutput, BashConfig
    search/
      mod.rs                         # re-export only
      grep.rs                        # GrepTool, GrepResult, GrepMatch
    config.rs                        # ToolConfig, override_risk validator
  tests/
    bash_tool_tests.rs               # unit + integration: timeout, truncation, risk floor
    grep_tool_tests.rs               # unit + integration: confinement, cap, partial-fail
```

**Files to create (new):** all shell/ and search/ modules; config.rs; `src/proofs/risk_floor.rs` (VP-013 Kani harness stub — `risk_floor_rejects_below_medium`; body `todo!()` for Phase 6).
**Files to modify (existing):** `pregolya-tools/Cargo.toml` (add regex dep), `src/lib.rs` (add pub use).
