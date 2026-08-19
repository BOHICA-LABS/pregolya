---
document_type: story
level: ops
story_id: S-1.09
epic_id: E-01
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.001.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.002.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.003.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.004.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.005.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.006.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.007.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "479ddd1"
traces_to: .factory/stories/STORY-INDEX.md
points: 13
depends_on: [S-1.01, S-1.02]
blocks: []
behavioral_contracts: [BC-2.13.001, BC-2.13.002, BC-2.13.003, BC-2.13.004, BC-2.13.005, BC-2.13.006, BC-2.13.007]
verification_properties: [VP-003]
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-sandbox
subsystems: [SS-13]
estimated_days: 5
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.09: Sandbox Backend Selection, Path Guard, and Policy Enforcement

## Narrative

- **As a** pregolya library user executing untrusted tool code
- **I want to** have a sandbox system that defaults to enforcing isolation (WASM or Container backend), enforces workspace path confinement, applies deny-by-default macOS Seatbelt profiles, and sanitizes environment variables
- **So that** tool execution is isolated by default, path traversal attacks are blocked at the type level, and the system is secure without requiring explicit opt-in from users

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.13.001 | Enforcing Sandbox Backend (WASM or Container) Is Default (NE-01) | AC-001..AC-003 |
| BC-2.13.002 | ProcessBackend Emits WARN Log Before Every Execute (NE-02) | AC-004..AC-005 |
| BC-2.13.003 | Strict Policy + Non-Enforcing Backend = Err(E-SBXD-002) | AC-006..AC-007 |
| BC-2.13.004 | canonicalize_beneath_root at Access Time — VP-003 Kani Seed | AC-008..AC-012 |
| BC-2.13.005 | Symlink That Escapes Workspace Root Returns Err(WorkspaceEscape) | AC-013..AC-014 |
| BC-2.13.006 | macOS Seatbelt Profile: Deny-by-Default with Explicit Allow Rules (NE-16) | AC-015..AC-018 |
| BC-2.13.007 | Environment Variable Sanitization — Strip All, Allowlist Explicit | AC-019..AC-021 |

## VP-003 ANCHOR (Kani P0)

This story builds the `sandbox::path_guard` module containing `canonicalize_beneath_root` and its pure companion `canonicalize_beneath_root_pure`. The `canonicalize_beneath_root_pure` function is the test vehicle for the VP-003 Kani harness (Phase 6 formal hardening). The pure function MUST be extracted as a public function in `pregolya-sandbox/src/path_guard.rs` so that the formal-verifier can access it in the `#[cfg(kani)]` proof harness at the path specified in VP-003.

**Subsystem anchor justification:** SS-13 owns this story's scope because SS-13 is the Sandbox subsystem (pregolya-sandbox crate) per ARCH-INDEX Subsystem Registry — it defines the enforcing backend, path guard, and policy enforcement components.

**Dependency anchor justification:** S-1.09 depends on S-1.01 because `PregolyaError` (established in S-1.01) is the error type returned by `canonicalize_beneath_root` and all sandbox constructors. S-1.09 depends on S-1.02 because the `ErrorPolicy` enforcement infrastructure (S-1.02) establishes the error propagation pattern used in Err(E-SBXD-NNN) returns.

## Acceptance Criteria

### AC-001 (traces to BC-2.13.001 postcondition 1 — enforcing default)
`Sandbox::new(config)` constructs using the enforcing backend (WASM or Container) when the `sandbox-wasm` feature is enabled (default Cargo feature). The `BackendCapabilities` returned by `Sandbox::capabilities()` satisfies `filesystem_isolated && network_isolated && memory_bounded`. Verified by `test_BC_2_13_001_enforcing_default_capabilities()`.

### AC-002 (traces to BC-2.13.001 postcondition 2 — unsafe_process escape hatch)
`ProcessBackend` (non-isolating) is only constructable via `Sandbox::unsafe_process_no_isolation()`. There is no public `Sandbox::new_process()` or any other constructor path that creates a `ProcessBackend` without the `unsafe_` naming. Verified by `test_BC_2_13_001_process_backend_requires_unsafe_constructor()`.

### AC-003 (traces to BC-2.13.001 postcondition 3 — no enforcing backend compile error)
When no enforcing backend feature is enabled (all of `sandbox-wasm`, `sandbox-container` disabled), `Sandbox::new(config)` returns `Err(PregolyaError { code: "E-SBXD-003", message: "SandboxInitFailed: no enforcing backend compiled — enable the 'sandbox-wasm' or 'sandbox-container' feature", .. })`. Verified by `test_BC_2_13_001_no_enforcing_backend_error()` (feature-gated test).

### AC-004 (traces to BC-2.13.002 postcondition 1 — WARN log per execute)
Every call to `ProcessBackend::execute(command)` emits a tracing WARN event with `event_type = "sandbox.process_no_isolation_execute"` BEFORE the subprocess is spawned. The log is emitted once per call, not per construction. Verified by `test_BC_2_13_002_warn_log_per_execute()` using a tracing subscriber capture.

### AC-005 (traces to BC-2.13.002 postcondition 3 — kill_on_drop)
All `tokio::process::Child` handles spawned by `ProcessBackend::execute` are configured with `.kill_on_drop(true)`. If the `ProcessBackend` is dropped before execution completes, the child process is killed. Verified by `test_BC_2_13_002_kill_on_drop_set()` (inspects command builder configuration).

### AC-006 (traces to BC-2.13.003 postcondition 1 — policy not enforceable)
When `SandboxPolicy { strict: true }` is passed to a `ProcessBackend` (which has `filesystem_isolated: false`), `execute()` returns `Err(PregolyaError { code: "E-SBXD-002", message: "PolicyNotEnforceable: ...", .. })` containing `policy_requirements` and `backend_capabilities` fields. The tool is NOT called. Verified by `test_BC_2_13_003_strict_policy_non_enforcing_backend_error()`.

### AC-007 (traces to BC-2.13.003 postcondition 2 — no silent fallback)
`E-SBXD-002` has severity classification `broken` in the error taxonomy. There is no code path where a strict policy+non-enforcing backend combination silently falls back to executing without enforcement. Verified by `test_BC_2_13_003_no_silent_fallback()`.

### AC-008 (traces to BC-2.13.004 postcondition 1 — VP-003 seed function exists)
`pregolya-sandbox/src/path_guard.rs` exports `pub fn canonicalize_beneath_root(base: &Path, requested: &Path) -> Result<PathBuf, PregolyaError>` (OS-calling version) and `pub fn canonicalize_beneath_root_pure(base: &Path, path: &Path) -> Result<PathBuf, PregolyaError>` (pure model version for Kani). Both functions exist and are accessible to external crates. Verified by `test_BC_2_13_004_path_guard_functions_exist()`.

### AC-009 (traces to BC-2.13.004 postcondition 2 — WorkspaceFs mandatory)
All workspace file operations in `pregolya-sandbox` route through the `WorkspaceFs` facade — no direct `std::fs` calls appear in non-`path_guard.rs` code. The `WorkspaceFs` facade calls `canonicalize_beneath_root` at access time, not at path construction time. Verified by `test_BC_2_13_004_workspace_fs_facade_routes_through_guard()` and a code review grep check (no `std::fs::` in workspace operation paths).

### AC-010 (traces to BC-2.13.004 postcondition 3 — path within root returns Ok)
`canonicalize_beneath_root(base, valid_sub_path)` returns `Ok(canonical_path)` where `canonical_path.starts_with(base)` is true. Verified by `test_BC_2_13_004_valid_path_returns_ok()`.

### AC-011 (traces to BC-2.13.004 postcondition 4 — escape returns Err E-SBXD-001)
`canonicalize_beneath_root(base, escape_path)` where `escape_path` resolves to a path outside `base` returns `Err(PregolyaError { code: "E-SBXD-001", .. })`. The error observation includes `requested`, `resolved`, and `root` fields (ADR-010 Class 3 `..` rest-pattern for elided fields). Verified by `test_BC_2_13_004_path_escape_returns_err()`.

### AC-012 (traces to BC-2.13.004 edge case EC-001 — ADR-024 two-phase protocol)
For paths that do not yet exist on the filesystem, `canonicalize_beneath_root` applies the ADR-024 two-phase protocol: (1) canonicalize the parent directory (which must exist), (2) append the filename component. This avoids `std::fs::canonicalize` failure on non-existent paths while still enforcing workspace confinement. Verified by `test_BC_2_13_004_nonexistent_path_two_phase_protocol()`.

### AC-013 (traces to BC-2.13.005 postcondition 1 — external symlink escape)
A symlink inside the workspace that resolves (via OS canonicalization) to a path outside the workspace root returns `Err(PregolyaError { code: "E-SBXD-001", .. })` with `WorkspaceEscape { requested, resolved, root }`. Chained symlinks are followed by OS canonicalize before the prefix check. Verified by `test_BC_2_13_005_external_symlink_escape_error()` (creates a real symlink via `std::os::unix::fs::symlink` in a tempdir).

### AC-014 (traces to BC-2.13.005 edge case EC-002 — dangling symlink)
A dangling symlink (target does not exist) returns `Err(SandboxError::PathNotFound)` — NOT `Err(E-SBXD-001 WorkspaceEscape)`. Internal symlinks (target is within workspace) return `Ok(canonical_path)`. Verified by `test_BC_2_13_005_dangling_symlink_path_not_found()`.

### AC-015 (traces to BC-2.13.006 postcondition 1 — deny default present)
On macOS, `SandboxBackend::new_macos_seatbelt(workspace_root, policy)` generates a Seatbelt profile string that contains `(deny default)` as the base policy rule. Verified by `test_BC_2_13_006_deny_default_present()` (macOS-only, `#[cfg(target_os = "macos")]`).

### AC-016 (traces to BC-2.13.006 postcondition 2 — no allow default)
The generated Seatbelt profile string does NOT contain the literal substring `(allow default)` anywhere. Verified by `test_BC_2_13_006_no_allow_default()` (macOS-only).

### AC-017 (traces to BC-2.13.006 postcondition 6 — PlatformNoEnforcement)
When the allow-list required for a tool is impractical to enumerate, `new_macos_seatbelt()` returns `Err(SandboxError::PlatformNoEnforcement { .. })` (`E-SBXD-004`); execution requires `SandboxPolicy::allow_no_sandbox()` explicit opt-in. On non-macOS platforms, `E-SBXD-004` is returned without attempting Seatbelt profile generation. Verified by `test_BC_2_13_006_platform_no_enforcement_error()`.

### AC-018 (traces to BC-2.13.006 edge case EC-002 — Seatbelt unavailable)
When the macOS kernel does not support the required Seatbelt operations, `new_macos_seatbelt()` returns `Err(SandboxError::BackendUnavailable { .. })` (`E-SBXD-005`) — it does NOT silently run unsandboxed. Verified by `test_BC_2_13_006_backend_unavailable_error()` (mocked kernel version check).

### AC-019 (traces to BC-2.13.007 postcondition 1 — strip all by default)
`SandboxConfig` with an empty `env_allowlist: vec![]` causes all environment variables to be stripped from the child process environment. The child process inherits zero env vars from the parent. Verified by `test_BC_2_13_007_strip_all_env_default()`.

### AC-020 (traces to BC-2.13.007 postcondition 2 — allowlist forwarded)
`SandboxConfig { env_allowlist: vec!["PATH".to_string(), "HOME".to_string()], .. }` causes only `PATH` and `HOME` to be forwarded to the child process. All other env vars are stripped. Verified by `test_BC_2_13_007_allowlisted_vars_forwarded()`.

### AC-021 (traces to BC-2.13.007 postcondition 3 — no wildcards, DEBUG log)
`env_allowlist` does not support wildcards. An entry containing `*` returns `Err(PregolyaError { code: "E-SBXD-006", message: "InvalidEnvAllowlistPattern: wildcard patterns are not supported in env_allowlist", .. })`. Before each execution, a DEBUG trace event is emitted with `event_type = "sandbox.env_sanitized"` containing the count of stripped and forwarded variables. Verified by `test_BC_2_13_007_wildcard_rejected()` and `test_BC_2_13_007_sanitization_debug_log()`.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| Story spec (this file) | ~6,500 |
| BC files (7 BCs: BC-2.13.001..007) | ~10,000 |
| VP-003 file | ~2,000 |
| Architecture module-decomposition.md (SS-13 section) | ~1,200 |
| pregolya-sandbox crate skeleton | ~3,500 |
| ADR-024 (two-phase path protocol) | ~1,000 |
| Test files (unit + integration + feature-gated) | ~5,000 |
| **Total** | **~29,200** |

Near but within the 20-30% context window threshold. Implementer should load only the BC sections relevant to the current failing test, not all 7 BCs simultaneously.

## Tasks

- [ ] Create `pregolya-sandbox/Cargo.toml` with `sandbox-wasm` as default feature
- [ ] Create `pregolya-sandbox/src/lib.rs` — public API: `Sandbox`, `SandboxConfig`, `SandboxPolicy`, `BackendCapabilities`
- [ ] Create `pregolya-sandbox/src/path_guard.rs` — `canonicalize_beneath_root` (OS-calling) and `canonicalize_beneath_root_pure` (Kani-provable pure model); `WorkspaceFs` facade
- [ ] Create `pregolya-sandbox/src/backend/mod.rs` — `SandboxBackend` trait, enforcing/process variants
- [ ] Create `pregolya-sandbox/src/backend/process.rs` — `ProcessBackend` with WARN log per execute, `.kill_on_drop(true)`
- [ ] Create `pregolya-sandbox/src/backend/wasm.rs` — WASM enforcing backend stub (todo!() bodies for Phase 3)
- [ ] Create `pregolya-sandbox/src/seatbelt.rs` — macOS Seatbelt profile generator (deny-by-default)
- [ ] Create `pregolya-sandbox/src/env_sanitizer.rs` — env allowlist enforcement, wildcard rejection, DEBUG log
- [ ] Write unit tests for all 21 ACs
- [ ] Write integration test for real symlink escape (AC-013, AC-014) using tempdir
- [ ] Add `#[cfg(kani)]` proof harness skeleton in `path_guard.rs` per VP-003 (bodies `todo!()` for Phase 6)
- [ ] Add `pregolya-sandbox` to workspace `Cargo.toml` members
- [ ] Run `just iter pregolya-sandbox` — all tests green

## Previous Story Intelligence

- S-1.01 established `PregolyaError` with `code`, `category`, `message` fields and the `..` rest-pattern notation for error observations (ADR-010 Class 3). All Err returns in this story follow the same pattern.
- S-1.02 established the `ErrorPolicy` enforcement infrastructure. The `broken` severity classification for E-SBXD-002 integrates with the error propagation chain from S-1.02.
- N/A for previous sandbox stories — this is the first story in the sandbox epic.

## Architecture Compliance Rules

Derived from `architecture/module-decomposition.md §pregolya-sandbox` and ADR-024:

1. `canonicalize_beneath_root_pure` MUST be a pure function (no OS calls, no `std::fs::canonicalize`). The pure model resolves `..` components symbolically. This is required for Kani provability (VP-003).
2. `canonicalize_beneath_root` (OS-calling) delegates to `canonicalize_beneath_root_pure` after resolving via `std::fs::canonicalize`. The two-layer design enables Kani verification of the pure layer and integration testing of the OS layer.
3. No direct `std::fs` calls in workspace file operation code paths other than `canonicalize_beneath_root`. All workspace file ops MUST go through `WorkspaceFs`.
4. `ProcessBackend::execute` MUST set `.kill_on_drop(true)` on every `tokio::process::Command` spawned. This is a DI-015 compliance requirement.
5. The `sandbox-wasm` feature MUST be declared as a default feature in `Cargo.toml`. Build configurations without any enforcing feature return E-SBXD-003.
6. No `unwrap()` / `expect()` in non-test code. Path guard errors are fatal security violations — surface them as `Err(PregolyaError)`, not panics.
7. macOS Seatbelt code MUST be `#[cfg(target_os = "macos")]` gated to prevent compilation failures on Linux.
8. All public types (`SandboxConfig`, `SandboxPolicy`, `BackendCapabilities`, `SandboxError` variants) MUST carry `#[non_exhaustive]`.
9. `event_type` values used in this story that must be registered in the Canonical Structured Event Catalog: `"sandbox.process_no_isolation_execute"` (WARN, per-execute), `"sandbox.env_sanitized"` (DEBUG, per-execute).

## Library & Framework Requirements

Derived from `architecture/dependency-graph.md` external dependency table:

| Library | Version | Usage |
|---------|---------|-------|
| `tokio` | 1.x | Async subprocess execution in ProcessBackend; `process::Command` |
| `tracing` | 0.1.x | WARN/DEBUG structured events (event_type catalog) |
| `tempfile` | 3.x | Integration tests for real symlink creation (dev-dependency) |
| `pregolya-core` | workspace path | `PregolyaError` |

**Forbidden Dependencies:** `pregolya-sandbox` MUST NOT depend on `pregolya-graph`, `pregolya-checkpoint`, or `pregolya-memory`. The sandbox is a primitive that those subsystems may use, not the other way around.

## File Structure Requirements

Files to CREATE:
- `/pregolya-sandbox/Cargo.toml`
- `/pregolya-sandbox/src/lib.rs`
- `/pregolya-sandbox/src/path_guard.rs` — VP-003 Kani proof vehicle
- `/pregolya-sandbox/src/backend/mod.rs`
- `/pregolya-sandbox/src/backend/process.rs`
- `/pregolya-sandbox/src/backend/wasm.rs`
- `/pregolya-sandbox/src/seatbelt.rs`
- `/pregolya-sandbox/src/env_sanitizer.rs`
- `/pregolya-sandbox/tests/path_guard_tests.rs`
- `/pregolya-sandbox/tests/backend_tests.rs`
- `/pregolya-sandbox/tests/seatbelt_tests.rs` (macOS-only)
- `/pregolya-sandbox/tests/env_sanitizer_tests.rs`
- `/pregolya-sandbox/tests/integration_symlink_tests.rs`

Files to MODIFY:
- `/Cargo.toml` — add `"pregolya-sandbox"` to `[workspace] members`

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Path is `"../"` relative to workspace root | Resolves outside root via pure model; returns E-SBXD-001 WorkspaceEscape |
| EC-002 | Chained symlinks: A→B, B→C, C→outside | OS canonicalize follows all links; resolved path fails prefix check; E-SBXD-001 |
| EC-003 | Internal symlink: workspace/link→workspace/real_dir | OS canonicalize resolves to within root; returns Ok(canonical_path) |
| EC-004 | `env_allowlist` contains a var that doesn't exist in parent env | Silently forwarded as absent (child process sees it absent); no error |
| EC-005 | Seatbelt profile with `allow_network: true` | `(allow network*)` added; `(deny default)` base preserved; no `(allow default)` |
