---
document_type: behavioral-contract
level: L3
bc_id: BC-2.13.002
version: "1.6"
status: active
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "4cc0b0a"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-13
capability: CAP-015
di_anchors: [DI-006, DI-015]
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.1 (burst-226/F-P131-03/2026-07-21): Assign canonical event_type 'sandbox.process_no_isolation_execute' to the mandated WARN-level log emission per observability census (SAP-1). PC1 and VP-2.13.002-A updated to specify the structured event_type field."
  - "1.2 (burst-235/F-P135-05/2026-07-22): Add DI-015 (Subprocess Execution Timeout) to di_anchors and Traceability — ProcessBackend co-enforces DI-015 at the sandbox layer via .kill_on_drop(true); add PC-6 (kill-on-drop subprocess guarantee) and INV-6 (.kill_on_drop(true) mandate). Architect adjudication F-P135-05."
  - "1.3 (FIX-BURST-257/F-P156-01, 2026-07-24): anchor-class sweep — nonexistent architecture file citations replaced with adjudicated real targets (F-P114-01 pattern)."
  - "1.4 (burst-291/D-134/2026-08-16): §-anchor phantom sweep — Forcing Functions: §NE catalog NE-01 is a phantom anchor (no '## NE catalog' heading in product-brief.md; NE items are table rows within '### Security Defaults — PRD Carry-Forward'). Corrected to §Security Defaults — PRD Carry-Forward (NE-01)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.6 (P2A-BC-scan-B/2026-08-26): Process backend execute failure paths added. PC-007 added: OS subprocess spawn failure → E-SBXD-007 ProcessSpawnFailed (TOOL/broken/Maybe; 2 placeholders: command, os_error). PC-008 added: process non-zero exit → E-SBXD-008 ProcessNonZeroExit (TOOL/broken; exit_code, stderr). EC-005/EC-006 added for spawn-failure and non-zero-exit test scenarios. Note: error-taxonomy minted E-SBXD-007 with anchor 'BC-2.13.002 PC-003' and E-SBXD-008 with anchor 'BC-2.13.002 PC-004'; PC-003/PC-004 are occupied by existing postconditions; authoritative stable tags are PC-007/PC-008 per ADR-027 append-only numbering."
modified: []
extracted_from: null
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
priority: P1
wave: 1
---

# BC-2.13.002: Process Backend Requires Explicit Opt-In and Emits Loud Runtime Warning

## Description

The `ProcessBackend` — which provides only `env_clear()` and a wall-clock timeout, with no
filesystem, network, or memory isolation — must be accessible only via an explicitly named
unsafe constructor. Every `execute()` call on the process backend emits a WARN-level log
message that names the missing isolation dimensions. There is no quiet path, no default
constructor, and no suppression API. This is a direct inversion of adk-rust P-61 (process
backend is the Cargo default) and P-62 (policy strictness is silently decoupled from actual
enforcement).

## Preconditions

1. {PRE-001} The caller explicitly invokes `Sandbox::unsafe_process_no_isolation()` to obtain a
   `ProcessBackend` handle
2. {PRE-002} The caller then invokes `execute(tool, args, policy)` on that handle

## Postconditions

1. {PC-001} Before code execution begins, a log message is emitted at `WARN` level with the text:
   `"ProcessBackend: no filesystem isolation, no network isolation, no memory bounds —
   untrusted code runs with OS-level privileges of the pregolya process"`
   The log entry MUST include `event_type = "sandbox.process_no_isolation_execute"` as a structured field alongside the message.
2. {PC-002} The warning is emitted once per `execute()` invocation, not only at construction time
3. {PC-003} The process backend executes the tool function and returns its result
4. {PC-004} `ProcessBackend::capabilities()` returns
   `BackendCapabilities { filesystem_isolated: false, network_isolated: false, memory_bounded: false }`
5. {PC-005} The warning cannot be suppressed by any public API call on `ProcessBackend` or
   `SandboxExecutor`
6. {PC-006} Every `tokio::process::Child` spawned by `ProcessBackend::execute()` is configured with
   `.kill_on_drop(true)`. If the `execute()` Future is dropped mid-execution (e.g., by an
   upstream `tokio::time::timeout` at the BashTool layer), the OS subprocess is killed by
   Tokio's drop machinery. No subprocess spawned by `ProcessBackend` may outlive the
   `execute()` Future.
7. {PC-007} If `tokio::process::Command::spawn()` returns an OS error (e.g., executable not found,
   resource exhaustion, permission denied), `execute()` returns
   `Err(E-SBXD-007: ProcessSpawnFailed { command: <command_string>, os_error: <os_error_message> })`.
   The WARN log from {PC-001} is NOT emitted for a spawn failure — the warning fires before code
   execution begins ({INV-002}), but spawn failure prevents execution from beginning at all; the
   error itself is the observable signal. RetryHint: Maybe (spawn failure may be transient resource
   exhaustion; a subsequent attempt after system resources free may succeed).
8. {PC-008} If the spawned process exits with a non-zero exit code, `execute()` returns
   `Err(E-SBXD-008: ProcessNonZeroExit { command: <command_string>, exit_code: <code>, stderr: <captured_stderr> })`.
   The tool function's return value is discarded; the non-zero exit is treated as a tool execution
   failure. Callers MUST NOT treat non-zero exit as success. `stderr` is captured for diagnostic
   purposes; it MUST NOT be included in model context without sanitization (DI-009 credential
   safety). RetryHint: Never (same command on same input will produce the same non-zero exit).

## Invariants

1. {INV-001} The process backend constructor name contains the tokens "unsafe" and "no_isolation"
   verbatim — the security posture is visible at the call site
2. {INV-002} The WARN log is emitted before tool code begins executing — a log tail can observe the
   warning before any damage from unsandboxed execution
3. {INV-003} No method named `suppress_warning`, `quiet`, `allow_unsafe`, or similar exists on
   `ProcessBackend`
4. {INV-004} `BackendCapabilities::enforcing()` returns `false` for `ProcessBackend`; any code that
   gates on `BackendCapabilities::enforcing()` will see the false value
5. {INV-005} adk-rust reference sparsity: upstream provides no loud-warning mechanism for unsafe
   backends (P-49 ADOPT adds honest capabilities but no warning); this is greenfield behavior
   derived from NE-01
6. {INV-006} `ProcessBackend` MUST set `.kill_on_drop(true)` on every `tokio::process::Child` it
   spawns; this is the DI-015 co-enforcement mechanism at the sandbox layer — it guarantees
   subprocess termination on async cancellation without requiring an explicit kill call from
   the BashTool layer.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `unsafe_process_no_isolation()` is called in a test (`#[cfg(test)]`) context | Warning is still emitted at WARN level; no test-only override suppresses it |
| EC-002 | `ProcessBackend` is constructed but `execute()` is never called | No warning emitted — warning fires at execute-time, not at construct-time |
| EC-003 | `execute()` is called 5 times in a loop | Warning emitted 5 times (once per execute call); no deduplication |
| EC-004 | Calling code attempts to intercept the warning by setting a custom log subscriber | Warning is emitted into the standard `tracing` subscriber; custom subscriber receives it; pregolya does not suppress it |
| EC-005 | {EC-005} `unsafe_process_no_isolation()` + `execute()` with a command that does not exist on the PATH (e.g., `"nonexistent_binary_xyz"`) | `Err(E-SBXD-007: ProcessSpawnFailed { command: "nonexistent_binary_xyz", os_error: "No such file or directory (os error 2)" })`; no WARN log from PC-001 (spawn did not begin execution); {PC-007} |
| EC-006 | {EC-006} `unsafe_process_no_isolation()` + `execute()` with a valid command that exits with code 1 (e.g., shell script returning `exit 1`) | `Err(E-SBXD-008: ProcessNonZeroExit { command: "...", exit_code: 1, stderr: "..." })`; tool result is not `Ok`; {PC-008} |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `Sandbox::unsafe_process_no_isolation().execute(no_op_tool, args)` | WARN log emitted containing "no filesystem isolation" and "no network isolation"; `Ok(result)` returned | happy-path (explicit opt-in) |
| `SandboxBackend::default().execute(tool, args)` (WASM backend) | No ProcessBackend WARN log emitted; `Ok(result)` | contrast (no spurious warning on enforcing backend) |
| Scan `pregolya_sandbox` public API for any method returning `ProcessBackend` without "unsafe" or "no_isolation" in its name | Zero methods found | structural test |
| `unsafe_process_no_isolation()` called; `execute()` called twice | Two WARN log lines — one per execute call | edge-case (per-execute frequency) |
| `unsafe_process_no_isolation()` + `execute()` started; executing `Future` is dropped mid-execution (e.g., by `tokio::time::timeout` at the BashTool layer timing out) | OS subprocess killed via `.kill_on_drop(true)` Tokio drop machinery; no orphan subprocess survives the dropped `Future` | kill-on-drop (DI-015 co-enforcement) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|--------------|
| VP-2.13.002-A | Every `execute()` call on `ProcessBackend` emits at least one WARN-level log entry with `event_type = "sandbox.process_no_isolation_execute"` containing the words "no filesystem isolation" | unit test — tracing subscriber capture |
| VP-2.13.002-B | No public API of `pregolya-sandbox` returns a `ProcessBackend` without "unsafe" and "no_isolation" in the function name | structural test — API surface scan |
| VP-2.13.002-C | `ProcessBackend::capabilities().enforcing()` is `false` | unit test |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-015 |
| Capability Anchor Justification | CAP-015 ("Sandboxed Tool Execution (Enforcing Backend Default)") per capabilities-p1-p2.md §CAP-015 |
| L2 Domain Invariants | DI-006 (Enforcing Sandbox Backend is Default), DI-015 (Subprocess Execution Timeout — ProcessBackend co-enforces via `.kill_on_drop(true)` at sandbox layer; primary enforcer is BC-2.23.005 / BashTool) |
| Source Analysis | P-61 NOT-APPLICABLE (must-not-inherit: process backend as Cargo default); P-62 NOT-APPLICABLE (must-not-inherit: silent policy-strictness decoupling); P-49 ADOPT (truthful BackendCapabilities — honest false values drive loud warning); NE-01 (pregolya requirement: loud opt-in); assessment-parts/part-3 §NE-01 |
| Reference Evidence | No upstream LangChain or adk-rust equivalent for loud-warning on process backend — greenfield behavior. adk-rust P-49 ADOPT provides the honest-capabilities shape but no warning mechanism; pregolya adds the warning layer on top. |
| Binding Decisions | NE-01, DI-006 |
| Forcing Functions | Domain C OpenClaw §4 (host-first execution default is §4 design lesson contra pregolya; pregolya inverts); product-brief.md §Security Defaults — PRD Carry-Forward (NE-01) |
| Architecture Module | pregolya-sandbox (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.13.001 — composes with: this BC specifies the warning behavior on the non-default path that BC-2.13.001 creates
- BC-2.13.003 — composes with: strict policy + process backend triggers Err(PolicyNotEnforceable) before this warning fires (PolicyNotEnforceable takes precedence)

## Architecture Anchors

- `architecture/module-decomposition.md §pregolya-sandbox` — `sandbox::process` row: explicit non-default; `unsafe_process_no_isolation()` only access path; WARN log on every `execute()`; `BackendCapabilities { filesystem_isolated: false, network_isolated: false, memory_bounded: false }`; DI-015 co-enforcer via `.kill_on_drop(true)` (MEDIUM, SS-13)
- `architecture/purity-boundary-map.md §Effectful Shell` — `sandbox::process` row: OS subprocess spawning via `tokio::process::Command` with `.kill_on_drop(true)` (integration test)

## Story Anchor

S-N.MM — Process backend opt-in warning (filled by story-writer)

## VP Anchors

- VP-2.13.002-A — WARN log on every execute() call (unit test)
- VP-2.13.002-B — API surface constructor naming (structural test)
- VP-2.13.002-C — BackendCapabilities::enforcing() false (unit test)
