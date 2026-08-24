---
document_type: behavioral-contract
level: L3
bc_id: BC-2.23.005
version: "1.12"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-23
capability: CAP-037
crate: pregolya-tools
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
di_anchors: [DI-014, DI-015]
vp_seed: true
vp_id: VP-013
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 first-party tool library, SS-23 BashTool. VP-013 Kani seed candidate."
  - "1.1 (Burst-232/2026-07-22): Fix Category::CONFIGURATION → Category::VAL in PC-4 (E-TOOLS-007 BashRiskTierViolation). CONFIGURATION is not in the canonical 12-member Category enum; E-TOOLS-007 is VAL per error-taxonomy v1.31. Gate #33 reverse-verify E-TOOLS-007 ↔ BC-2.23.005: taxonomy VAL ↔ BC PC-4 VAL — PASS."
  - "1.2 (F-P134-06/2026-07-22): Re-anchor DI-009 (HTTP connection timeout) → DI-015 (Subprocess Execution Timeout) per architect adjudication of finding F-P134-06. di_anchors [DI-009,DI-014]→[DI-014,DI-015]; traces_to DI-009→DI-015; Description, PC-3, Invariants DI-009 analog bullet, and Traceability L2 Invariants row updated. Gate #28 F-P134-06 close. input-hash refreshed to 835edd0 (invariants.md updated by BA to mint DI-015; final stable hash after BA writes settled)."
  - "1.3 (burst-235/F-P135-05/2026-07-22): Fix four occurrences of wrong implementation phrasing 'tokio::time::timeout over/wrapping tokio::process::Command' (Description, PC-3, Invariants DI-015 bullet, Traceability) — implied BashTool calls tokio::process::Command directly, contradicting the sandbox-mandatory Invariant. Correct: tokio::time::timeout wraps the sandbox backend execute() call; tokio::process::Command is managed by sandbox::process internally. Architect adjudication F-P135-05."
  - "1.4 (burst-238/F-P138-03/2026-07-23): VP Anchors and Traceability VP Registration updated: stale 'ARCH-INDEX D23 candidate — architect to assign VP-INDEX entry' prose replaced with 'assigned in VP-INDEX as VP-013' (VP-INDEX v1.5 burst-232 seeded VP-013 Kani P1; pregolya-tools risk_floor_rejects_below_medium). Both sites updated (VP Anchors section + Traceability VP Registration row). Gate #28 close F-P138-03."
  - "1.5 (burst-247/F-P146-02+OBS-naming/2026-07-24): (1) H1 title — remove payload flag E-TOOLS-005 from title error-code enumeration per SS-23 title policy (Ok-path payload flags excluded from raised-code enumeration). Before: 'E-TOOLS-004/005/007'. After: 'E-TOOLS-004/007'. E-TOOLS-005 is retained in the body as a payload annotation (BashOutput.truncated) — it is not removed from the contract, only from the raised-code title list. (2) PC-2 body — align truncation flag name from informal 'BashOutputTruncated'-style to canonical field-path notation 'BashOutput.truncated' per OBS naming-anchor (error-taxonomy v1.37 adds explicit canonical-field-path marker for E-TOOLS-005). TD-VSDD-060: BC-INDEX row and bc-authoring-plan Batch 20 title cell updated same burst (state-manager handles BC-INDEX). input-hash updated 0bc5c5d→64d7571 (inputs unchanged; hash drift from prior burst)."
  - "1.6 (FIX-BURST-270/ADR-010-v1.9/2026-07-25): Apply PascalCase casing canon (ADR-010 v1.9 Direction B) at 2 sites: component: \"TOOLS\" string literal → component: Component::Tools (PC-3 + PC-4); Category::TIMEOUT → Category::Timeout (PC-3), Category::VAL → Category::Val (PC-4)."
  - "1.7 (F-P170-16/burst-272/2026-07-25): Adjudication — canonical method name is ToolConfig::override_risk (ADR-020 Decision 3 introduction form; majority usage in PC3/ECs/TVs; VP-013 capabilities-p1-p2.md). Fix three set_risk sites: (1) §Invariants 'Risk floor' paragraph — two occurrences BashTool::set_risk(ReadOnly) and BashTool::set_risk(Low) → ToolConfig::override_risk(ActionRisk::ReadOnly) and ToolConfig::override_risk(ActionRisk::Low). (2) §Verification Properties VP-013 row — same fix. set_risk appeared only in prose/invariant/anchor sentences; ToolConfig::override_risk is the architectural name per ADR-020 Decision 3."
  - "1.8 (F-P171a-02b/burst-273/2026-07-25): Lifecycle adjudication — ToolConfig::override_risk is a builder-consuming validator (signature: override_risk(self, risk: ActionRisk) -> Result<ToolConfig, PregolyaError>); it returns Err immediately at call time; the registry never receives an invalid ToolConfig. Deliberate spec amendment per CLAUDE.md precedence rule 1 (BC supersedes for contract semantics). (1) PC-4 header: 'Risk floor violation at startup' → 'Risk floor violation at ToolConfig::override_risk call time'. (2) PC-4 body: 'At ToolRegistry::register time' → 'At ToolConfig::override_risk call time'. (3) EC-004 Description: 'at registry time' → 'at ToolConfig::override_risk call time'. TD-VSDD-060 sibling sweep: VP-013.md §BC Traceability EC-004/EC-005 and §Proof Harness cite 'registry time' and 'registration logic' — routed to architect for VP-013 body update (architect scope)."
  - "1.9 (fix-burst-280/F-P175-A25/2026-07-28): Convert 2 struct-literal construction examples to PregolyaError::new() form. PC3 E-TOOLS-004 BashTimeout: ::new(Component::Tools, Category::Timeout, RetryHint::Never, ...). PC4 E-TOOLS-007 BashRiskTierViolation: ::new(Component::Tools, Category::Val, RetryHint::Never, ...). TD-VSDD-060 sibling sweep: no other struct-literal construction examples found in this BC."
  - "1.10 (fix-burst-287/TD-VSDD-091+ADR-010-C3/2026-08-01): (1) VP-INDEX version pin removed: §VP Anchors and §Traceability VP Registration 'VP-INDEX v1.5 as' → 'VP-INDEX as' (no §-anchor introduced). (2) ADR-010 Class 3 fix: PC-3 E-TOOLS-004 and PC-4 E-TOOLS-007 prose PregolyaError::new(...) → PregolyaError { code: 'E-TOOLS-004', .. } and { code: 'E-TOOLS-007', .. } (observation form). 2 violations corrected. verify-no-version-pins.sh PASS; verify-error-notation-canon.sh PASS."
  - "1.11 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.22 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.12 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-037
  - architecture/decisions/ADR-020-first-party-tool-library.md
  - domain-spec/invariants.md#DI-014
  - domain-spec/invariants.md#DI-015
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-020-first-party-tool-library.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "5dcadf6"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.23.005: BashTool — Sandboxed Shell Execution; Non-Lowerable Medium Risk Floor; BashOutput; 256 KiB Output Cap; 30 s Timeout; E-TOOLS-004/007 (VP-013 Kani Seed)

## Description

`BashTool` in `pregolya-tools::tools::shell` implements the `Tool` trait with default
`ActionRisk::High`. It executes a shell command via the pregolya-sandbox WASM/container
backend (BC-2.13.001–003); direct OS process execution outside the sandbox policy is
prohibited. Output is captured in a `BashOutput { stdout: String, stderr: String,
exit_code: i32, truncated: bool }` struct. A `max_output_bytes` limit (default 256 KiB)
caps captured output: when exceeded, the first 256 KiB is returned with `truncated: true`
(E-TOOLS-005, informational — non-fatal). A `max_duration` timeout (default 30 seconds, enforcing DI-015 (Subprocess Execution Timeout)
via `tokio::time::timeout` wrapping the sandbox backend `execute()` call — distinct from DI-009 which governs
HTTP connection timeouts) terminates the command and returns `Err(E-TOOLS-004 BashTimeout)`. The risk tier CANNOT be lowered below `ActionRisk::Medium` —
attempting to set `ReadOnly` or `Low` via `ToolConfig::override_risk` returns a configuration
error at startup (E-TOOLS-007; VP-013 Kani P1 seed).

## Preconditions

1. {PRE-001} `BashTool` is constructed with a sandbox policy reference (pregolya-sandbox, BC-2.13.001)
   and optional `BashConfig { max_output_bytes: u64 (default 262,144), max_duration: Duration (default 30s) }`.
2. {PRE-002} The caller invokes the tool with JSON args `{ "command": "<shell-command-string>" }`.
3. {PRE-003} `ActionRisk::High` is the default annotated risk tier; application may lower to `Medium`
   via `ToolConfig::override_risk(ActionRisk::Medium)`. Setting `ReadOnly` or `Low` is
   rejected at startup with `Err(E-TOOLS-007 BashRiskTierViolation)`.
4. {PRE-004} Retry enrollment: `BashTool` is NOT enrolled for automatic retry by default. Explicit
   enrollment via `RetryPolicy` keyed on `tool_name: "bash"` (BC-2.16.001) is required;
   each retry independently flows through `PreToolCallHook` (ADR-018 Decision 6).

## Postconditions

1. {PC-001} **Happy path:** The command executes within `max_duration` and its combined stdout +
   stderr output fits within `max_output_bytes`. The tool returns `ToolOutput::Json(BashOutput)`
   where:
   ```json
   { "stdout": "<stdout>", "stderr": "<stderr>", "exit_code": 0, "truncated": false }
   ```
   Non-zero exit codes are NOT errors at the tool layer — the tool returns `Ok(BashOutput)`
   with the non-zero `exit_code`. The caller decides whether a non-zero exit code is a failure.
2. {PC-002} **Output truncation (non-fatal):** Combined output (stdout + stderr) exceeds `max_output_bytes`.
   The tool returns `ToolOutput::Json(BashOutput)` with `truncated: true` and the first
   `max_output_bytes` bytes of output (priority: stdout first, then stderr). E-TOOLS-005
   (`BashOutput.truncated`) is an informational annotation in the output object, not an `Err`.
   The command is allowed to complete (truncation is output-cap, not process-kill).
3. {PC-003} **Timeout (DI-015):** The command runs for longer than `max_duration`. `tokio::time::timeout`
   wrapping the sandbox backend `execute()` call fires; the sandbox kills the subprocess
   (ProcessBackend via `.kill_on_drop(true)` async drop; WASM/container backends via runtime-level
   process termination). The tool returns
   `Err(PregolyaError { code: "E-TOOLS-004", .. })`. This raise-condition
   directly enacts DI-015 (Subprocess Execution Timeout): exceed `max_duration` → terminate
   process → structured `E-TOOLS-004` error.
4. {PC-004} **Risk floor violation at `ToolConfig::override_risk` call time:** `ToolConfig::override_risk(ActionRisk::ReadOnly)` or
   `override_risk(ActionRisk::Low)` called on a `BashTool` instance. At `ToolConfig::override_risk`
   call time the builder-consuming validator returns
   `Err(PregolyaError { code: "E-TOOLS-007", .. })`.
   The registry never receives an invalid ToolConfig; the graph does not start.
5. {PC-005} **Sandbox policy violation:** The command attempts an operation disallowed by the sandbox
   policy (pregolya-sandbox BC-2.13.002). The sandbox returns an error before the command
   executes; this propagates as `Err(PregolyaError)` from the sandbox namespace.

## Invariants

- {INV-001} **Risk floor (VP-013 Kani seed):** `ToolConfig::override_risk(ActionRisk::ReadOnly)` and
  `ToolConfig::override_risk(ActionRisk::Low)` on a `BashTool` instance ALWAYS return `Err(E-TOOLS-007)`. No code path allows these
  tiers on BashTool. This is a framework safety invariant provable by Kani: the risk floor
  check is a pure enum comparison (`risk < ActionRisk::Medium` → error) with no side effects.
- {INV-002} All sandbox execution is via pregolya-sandbox (BC-2.13.001–003). There is no fallback
  direct OS execution path.
- {INV-003} `max_output_bytes` truncation is applied BEFORE returning to the caller; the sandbox
  buffer is bounded and does not grow unboundedly.
- {INV-004} **DI-015 (Subprocess Execution Timeout):** `max_duration` (default 30 seconds) is the
  governing subprocess wall-clock timeout, enforced via `tokio::time::timeout` wrapping the
  sandbox backend `execute()` call; `tokio::process::Command` is managed by `sandbox::process`
  (ProcessBackend) internally — BashTool does NOT call `tokio::process::Command` directly
  (doing so would violate the Invariant above: "All sandbox execution is via pregolya-sandbox").
  When a command exceeds `max_duration` the sandbox terminates
  the process and the tool returns `Err(E-TOOLS-004 BashTimeout)`. Production graphs that
  need a different default must set `BashConfig::max_duration` explicitly; zero-duration is
  rejected (configuration error). DI-009 (HTTP connection timeout) does NOT govern subprocess
  execution — DI-015 is the exclusive authority for this BC.
- {INV-005} **DI-014 (No Silent Swallowing):** Timeout and sandbox errors propagate as `Err`. A
  non-zero exit code is NOT swallowed — it is surfaced in `BashOutput.exit_code`. The
  tool does not transform a non-zero exit code into an empty or `None` result.
- {INV-006} Retry: each retry attempt flows through `PreToolCallHook` independently (ADR-018 Decision 6
  and ADR-020 Decision 4). The hook may deny on a retry even if it approved the first attempt.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Command produces 300 KiB of output (exceeds 256 KiB default) | `ToolOutput::Json({ ..., "truncated": true })` — first 262,144 bytes returned; command allowed to complete |
| EC-002 | Command runs for 31 seconds (exceeds 30s default) | `Err(E-TOOLS-004 BashTimeout: command exceeded max_duration of 30s)` — process killed |
| EC-003 | Command exits with non-zero exit code (e.g., `exit 1`) | `ToolOutput::Json({ "exit_code": 1, "truncated": false })` — Ok, not Err; caller handles |
| EC-004 | `ToolConfig::override_risk(ActionRisk::ReadOnly)` on BashTool at `ToolConfig::override_risk` call time | `Err(E-TOOLS-007 BashRiskTierViolation: attempted: 'ReadOnly')` — registry never sees the invalid config; graph does not start |
| EC-005 | `ToolConfig::override_risk(ActionRisk::Medium)` on BashTool | Accepted — Medium is the floor; graph starts normally |
| EC-006 | Command output is exactly 262,144 bytes | `ToolOutput::Json({ ..., "truncated": false })` — at limit, not over; no truncation |
| EC-007 | Sandbox policy blocks the command before execution | `Err(PregolyaError)` — sandbox namespace error, NOT E-TOOLS-004 or E-TOOLS-005 |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `{ "command": "echo hello" }` — succeeds, output < 256 KiB | `ToolOutput::Json({ "stdout": "hello\n", "stderr": "", "exit_code": 0, "truncated": false })` | happy-path |
| TV-002 | `{ "command": "exit 1" }` — non-zero exit | `ToolOutput::Json({ "stdout": "", "stderr": "", "exit_code": 1, "truncated": false })` | non-zero exit (not Err) |
| TV-003 | `{ "command": "dd if=/dev/zero bs=1k count=400" }` — 400 KiB output | `ToolOutput::Json({ ..., "truncated": true })` — first 262,144 bytes | output truncation |
| TV-004 | `{ "command": "sleep 60" }` — exceeds 30s timeout | `Err(E-TOOLS-004)` — `BashTimeout: command exceeded max_duration of 30s` | timeout |
| TV-005 | `override_risk(ActionRisk::Low)` at registry | `Err(E-TOOLS-007)` — `BashRiskTierViolation: BashTool risk tier cannot be lowered below Medium; attempted: 'Low'` | risk floor violation |
| TV-006 | `override_risk(ActionRisk::Medium)` at registry | Accepted — graph starts normally | risk floor (boundary) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-013 (Kani P1 candidate) | `ToolConfig::override_risk(ActionRisk::ReadOnly)` and `ToolConfig::override_risk(ActionRisk::Low)` on BashTool ALWAYS return Err; never succeed | Kani exhaustive proof: enum comparison `risk < Medium` → Err branch; no code path to Ok |
| VP-2.23.005-B | Timeout fires at max_duration; no indefinite hang | Integration test: command `sleep 120`, assert Err(E-TOOLS-004) within 32s |
| VP-2.23.005-C | Output truncation: first 262,144 bytes returned, truncated=true for oversized output | Unit test with mock sandbox returning 300 KiB; assert truncated=true and len==262144 |

## Related BCs

- BC-2.23.001 — sibling: ReadFileTool (ReadOnly; no risk floor complexity)
- BC-2.13.001 — depends on: sandbox backend execution contract
- BC-2.13.002 — depends on: sandbox policy enforcement (EC-007)
- BC-2.16.001 — related to: BashTool retry enrollment keyed by tool_name
- BC-2.05.007 — related to: ActionRisk::High → PreToolCallHook approval gate; retry-through-hook ordering (ADR-018 Decision 6)
- BC-2.05.006 — related to: ActionRisk::Medium minimum risk floor interacts with RiskGatePolicy

## Architecture Anchors

- `architecture/decisions/ADR-020-first-party-tool-library.md` — Decision 2 (BashTool, BashOutput struct, max_output_bytes 256 KiB, 30s timeout), Decision 3 (non-lowerable Medium floor), Decision 4 (retry enrollment per BC-2.16.001), Decision 5 (E-TOOLS-004/005/007)
- `architecture/decisions/ADR-018-per-tool-call-approval-hook.md` — Decision 6 (retry-through-hook ordering: circuit_breaker → pre_tool_dispatch → invoke → retry_policy.record)
- `architecture/module-decomposition.md` — SS-23, `tools::shell` module in pregolya-tools

## Story Anchor

S-1.22

## VP Anchors

- VP-013 (assigned in VP-INDEX as VP-013 — Kani P1; pregolya-tools risk_floor_rejects_below_medium)
- VP-2.23.005-B
- VP-2.23.005-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-037 |
| Capability Anchor Justification | CAP-037 ("First-Party Shell Execution Tool (tools::shell — BashTool)") per capabilities-p1-p2.md §CAP-037 — this BC specifies BashTool's non-lowerable Medium risk floor, BashOutput struct, 256 KiB output cap, 30s timeout, E-TOOLS-004/005/007 error codes, sandbox-mandatory execution, and retry enrollment semantics that CAP-037 names as the distinct framework safety invariant warranting its own CAP band |
| L2 Domain Invariants | DI-014 (Error Propagation — timeout and sandbox errors propagate as Err; non-zero exit code surfaced in BashOutput, never swallowed), DI-015 (Subprocess Execution Timeout — max_duration wall-clock timeout enforced by BashTool via tokio::time::timeout wrapping sandbox execute() call; exceed → terminate subprocess via sandbox → Err(E-TOOLS-004 BashTimeout)) |
| Architecture Authority | ADR-020 Decisions 2, 3, 4, and 5; ADR-018 Decision 6 (retry-through-hook ordering) |
| Binding Decisions | D23 (first-party tool library scope, SS-23 creation) |
| VP Registration | VP-013 (assigned in VP-INDEX as VP-013 — Kani P1; pregolya-tools risk_floor_rejects_below_medium) |
| Module | pregolya-tools / tools::shell |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration + Kani (VP-013) |
