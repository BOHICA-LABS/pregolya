---
document_type: adr
level: L3
adr_id: "020"
slug: first-party-tool-library
title: "First-Party Tool Library: ferrochain-tools Crate, tools::fs / tools::shell / tools::search Modules, SS-23 Subsystem"
status: accepted
date: "2026-07-22"
producer: architect
timestamp: 2026-07-22T00:00:00Z
version: "1.0"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D23]
supersedes: null
superseded_by: null
subsystems_affected: [SS-23]
changelog:
  - "1.0 (D23/2026-07-22): Initial ADR — introduces ferrochain-tools as crate #21. Closes the DEGRADED gap for first-party file/bash/search tools in domain-e-agentic-coding-assistant.md §3 items 1-5."
---

# ADR-020: First-Party Tool Library

**Status:** Accepted — D23 authority (2026-07-22)

## Context

Domain E (agentic coding CLI, §3 items 1-5, §6 table) classifies file I/O, bash, and
search as DEGRADED:

> "MCP exposes these capabilities but ferrochain ships no first-party implementations.
> An agentic coding assistant needs file read/write/edit, directory listing, bash
> execution, and grep as first-class ferrochain tools — not framework-external wrappers."

The current state: `ferrochain-sandbox` (SS-13, crate #12) provides a policy enforcement
substrate — path-confinement guards, WASM sandbox backend, process isolation primitives.
BC-2.13.001–BC-2.13.005 establish the sandbox enforcement layer. What does NOT exist is
a set of first-party `Tool`-implementing types that wrap these operations and are ready
to be registered in a `ToolRegistry` for graph execution.

The `Tool` trait is defined in `ferrochain-core` (ADR-009). `ActionRisk` is in
`ferrochain-graph::hitl` (BC-2.05.006). The sandbox path-guard is in
`ferrochain-sandbox`. A tool library crate sits above all three in the dependency graph:
it instantiates tools with a sandbox policy and registers them for graph use.

## Decision 1 — New Crate `ferrochain-tools` (Crate #21) under New Subsystem SS-23

`ferrochain-tools` is introduced as crate #21 in the workspace canonical roster.
It forms a new subsystem SS-23 "First-Party Tool Library."

**Placement rationale:** `ferrochain-sandbox` is an enforcement substrate, not a
user-facing tool API. Placing first-party tools in `ferrochain-sandbox` would conflate
"execution policy enforcement" with "tool API surface" — two concerns with different
consumers, different abstraction levels, and likely different release cadences. A new
crate makes the dependency direction explicit: `ferrochain-tools` depends on
`ferrochain-sandbox`; the sandbox has no awareness of `ferrochain-tools`.

**Dependency graph for `ferrochain-tools`:**

```
ferrochain-core        (Tool trait, ToolOutput, FerrochainError)
ferrochain-graph       (ActionRisk, PreToolCallHook — integration only)
ferrochain-sandbox     (PathGuard, SandboxPolicy, sandbox execution)
ferrochain-macros      (#[tool] attribute macro, risk tier annotation)
```

`ferrochain-tools` does NOT depend on `ferrochain-graph` at compile time; ActionRisk is
used only through the `#[tool(action_risk = ...)]` macro annotation path, which binds at
registration time via the macro expansion, not at crate import. This avoids a circular
dependency.

## Decision 2 — Three Modules: `tools::fs`, `tools::shell`, `tools::search`

All three modules in `ferrochain-tools` are **Effectful Shell** (see Decision 6).

### `tools::fs` — File System Operations

Implements `Tool` for:

| Type | Operation | ActionRisk default |
|------|-----------|-------------------|
| `ReadFileTool` | Read file at path, return contents | `ReadOnly` |
| `WriteFileTool` | Write (create/overwrite) file at path | `High` |
| `EditFileTool` | Apply a string-replace edit to an existing file | `High` |
| `ListDirTool` | List directory entries at path | `ReadOnly` |

Path arguments are validated against `PathGuard` (ferrochain-sandbox) before any I/O.
Out-of-guard paths return `Err(FerrochainError::sandbox(E-SANDBOX-xxx))`.

`EditFileTool` receives:
```json
{ "path": "...", "old_string": "...", "new_string": "...", "replace_all": false }
```
It performs an exact-string replacement. The `similar` crate (dependency research flag —
see Decision 7) is used ONLY if the host opts in to fuzzy-match fallback via
`EditConfig::fuzzy_threshold: Option<f32>`. Default is exact match only.

`ReadFileTool` respects a configurable `max_bytes: u64` limit (default: 1 MiB) to prevent
accidental large-file ingestion into context. Exceeding the limit returns a structured
error with the file size and the configured limit.

### `tools::shell` — Bash Execution

| Type | Operation | ActionRisk default |
|------|-----------|-------------------|
| `BashTool` | Execute a shell command; capture stdout/stderr/exit code | `High` |

`BashTool` runs via `ferrochain-sandbox` WASM or process isolation backend (per
BC-2.13.001–003). It never runs commands outside the sandbox policy.

Output capture:
```rust
pub struct BashOutput {
    pub stdout: String,
    pub stderr: String,
    pub exit_code: i32,
    pub truncated: bool,   // true if output exceeded max_output_bytes
}
```

`max_output_bytes: u64` limit (default: 256 KiB). Exceeding the limit returns the first
256 KiB with `truncated: true` — it does NOT fail, consistent with Claude Code's existing
truncation behavior.

Timeout: `max_duration: Duration` (default: 30 seconds per NFR catalog — same as reqwest
client policy). Timeout returns `Err(FerrochainError::sandbox(E-SANDBOX-timeout))`.

### `tools::search` — Grep / Text Search

| Type | Operation | ActionRisk default |
|------|-----------|-------------------|
| `GrepTool` | Regex search across file(s) or directory; return matches with line numbers | `ReadOnly` |

`GrepTool` accepts:
```json
{ "pattern": "...", "path": "...", "recursive": true, "case_insensitive": false, "max_results": 100 }
```

The `regex` crate handles pattern matching (dependency research flag — see Decision 7;
`regex` is an established workspace dep, confirm it is already in `Cargo.toml` or add).
Results are capped at `max_results` (default 100) to prevent runaway output.

`GrepTool` does NOT shell out to system `grep` or `ripgrep`; it uses the `regex` crate
in-process to keep the tool hermetic and testable without system tool availability checks.
For production-grade performance on large trees, a ripgrep-backed implementation may be
added in a future crate extension (not v1 scope).

## Decision 3 — Risk Tier Defaults and HITL Integration

`ferrochain-tools` tools register with `ActionRisk` defaults as shown in Decision 2.
These defaults interact with `PreToolCallHook` (ADR-018) and `RiskGatePolicy` (BC-2.05.006):

| Tool | Default risk | `RiskGatePolicy` trigger | Typical prompt |
|------|-------------|--------------------------|----------------|
| `ReadFileTool` | ReadOnly | No interrupt | Auto-approve |
| `ListDirTool` | ReadOnly | No interrupt | Auto-approve |
| `GrepTool` | ReadOnly | No interrupt | Auto-approve |
| `BashTool` | High | Interrupt by default | Approval required |
| `WriteFileTool` | High | Interrupt by default | Approval required |
| `EditFileTool` | High | Interrupt by default | Approval required |

Applications may lower risk tiers for specific tool instances via
`ToolConfig::override_risk(ActionRisk)`. Risk tier can only be lowered by explicit
application-layer configuration; the framework never lowers a tool's risk tier without
explicit instruction.

`BashTool` risk tier CANNOT be lowered below `Medium` — attempting to set `ReadOnly` or
`Low` on `BashTool` returns a configuration error at startup. This is a framework safety
invariant, not an application convention.

## Decision 4 — Retry Classification

All three modules participate in `core::retry` (CAP-018, promoted to Wave 1 per D23 item 4):

| Tool | Retry-eligible? | Rationale |
|------|----------------|-----------|
| `ReadFileTool` | No (idempotent by default) | Read-only; no transient failure expected. Re-read = re-read, no state change. |
| `ListDirTool` | No | Same as ReadFileTool. |
| `GrepTool` | No | In-process; no I/O transience. |
| `WriteFileTool` | No — requires approval-first | Writes are non-idempotent. Retry without re-approval risks double write. |
| `EditFileTool` | Conditional — only if `old_string` not found (file changed race) | The race window is narrow; retry is safe because `old_string` mismatch is a structural no-op. |
| `BashTool` | Configurable per tool_name | Commands must be explicitly enrolled in retry policy by the application. Default is NO retry. |

`BashTool` retry enrollment follows the existing BC-2.16.001 keying-by-tool-name pattern.
The framework does not auto-retry `BashTool` invocations because shell commands are
not generally idempotent.

Retry-approval ordering (ADR-018 Decision 6): circuit_breaker → pre_tool_dispatch
(approval hook) → tool.invoke → retry_policy.record. Each retry of `BashTool` goes
through the approval hook independently; the hook may deny on a retry even if it approved
the first attempt.

## Decision 5 — Error Namespace `E-TOOLS-*`

A new error component namespace `E-TOOLS-*` is established for errors originating in
`ferrochain-tools`. Initial codes (populated at Phase 1 in `error-taxonomy.md` by PO):

| Code | Name | Description |
|------|------|-------------|
| E-TOOLS-001 | PathConfinementViolation | Path argument rejected by PathGuard |
| E-TOOLS-002 | FileReadExceedsLimit | File size exceeds ReadFileTool max_bytes |
| E-TOOLS-003 | EditOldStringNotFound | exact-match old_string not found in target file |
| E-TOOLS-004 | BashTimeout | BashTool execution exceeded max_duration |
| E-TOOLS-005 | BashOutputTruncated | BashTool output exceeded max_output_bytes (non-fatal) |
| E-TOOLS-006 | SearchResultsCapped | GrepTool result count hit max_results ceiling |
| E-TOOLS-007 | BashRiskTierViolation | Attempted to lower BashTool risk below Medium |

**PO obligation (error-taxonomy.md):** add the `E-TOOLS-*` section with these 7 codes
to `.factory/specs/prd-supplements/error-taxonomy.md`.

## Decision 6 — Purity Boundary Classification

All three modules in `ferrochain-tools` are **Effectful Shell**:

| Module | Classification | Rationale |
|--------|---------------|-----------|
| `tools::fs` | Effectful Shell | All I/O via OS filesystem |
| `tools::shell` | Effectful Shell | Process execution, stdout/stderr capture |
| `tools::search` | Effectful Shell | Filesystem traversal + regex application |

The `graph::hitl (pre-tool dispatch)` function (ADR-018) is a **Boundary Module**:
pure routing of `PreToolDecision` but calling effectful `PreToolCallHook::pre_invoke`.

No new Pure Core modules are introduced by this ADR. The `core::budget` extensions
(ADR-019 types) are definitions-only (pure data structures and traits); they reside in
the existing Pure Core classification for `core::budget`.

## Decision 7 — External Dependency Research Flags

The following dependencies require the research-agent to confirm exact crate names,
current stable versions, and license compatibility before `Cargo.toml` is written:

| Purpose | Likely crate | Verify |
|---------|-------------|--------|
| Edit fuzzy-match fallback in `EditFileTool` | `similar` (dtolnay) | Current stable version, MIT license confirm |
| Regex engine for `GrepTool` | `regex` (rust-lang) | Already in workspace? If not, confirm current stable |
| File metadata in `ListDirTool` | stdlib only (`std::fs`) | No external dep needed |
| Path guard integration | `ferrochain-sandbox` internal | No new external dep |

**Research flags (BA → research-agent):** Confirm `similar` stable version and license.
Confirm `regex` is already a workspace dependency (check `Cargo.toml` `[workspace.dependencies]`).

## Rationale

Keeping `ferrochain-tools` as a separate crate (not folded into `ferrochain-sandbox`) is
correct because:
1. Consumers of `ferrochain-sandbox` are framework-internal enforcement logic; consumers
   of `ferrochain-tools` are end-user graph applications.
2. Release cadence differs: sandbox policy primitives are stable; tool APIs evolve with
   Claude Code/Codex conventions.
3. The dependency direction is clear and one-way: tools → sandbox, not sandbox → tools.

Implementing `GrepTool` with the in-process `regex` crate (not shelling out to system
`grep` or `ripgrep`) is correct for v1 because:
1. Hermetic: no system tool availability assumptions.
2. Testable: no subprocess in unit tests.
3. Sufficient: coding assistant search patterns are bounded. Performance on large trees
   can be addressed with a ripgrep-backed optional implementation in a future cycle.

Defaulting `BashTool` to `ActionRisk::High` with a non-lowerable floor of `Medium`
enforces the framework safety posture for arbitrary command execution without requiring
application authors to reason about risk tiers for every use case.

## Alternatives Considered

- **Option A — Ship tools inside `ferrochain-sandbox`:** Rejected (see Decision 1 rationale).
  Conflates enforcement substrate with user-facing API surface.

- **Option B — MCP-only, no first-party tools:** Status quo DEGRADED classification.
  Rejected: forces every coding-assistant application to wrap MCP or write its own tool
  implementations without path-guard integration, HITL ActionRisk defaults, or retry
  classification. Framework-level consistency is lost.

- **Option C — Tools as macros / codegen inside `ferrochain-macros`:** Rejected:
  `ferrochain-macros` provides procedural macros, not runtime Tool implementations.
  A generated `ReadFileTool` would still require a runtime library home.

- **Option D — Shell-out to `ripgrep` for `GrepTool`:** Considered and deferred to a
  future `ferrochain-tools-rg` crate. For v1, in-process `regex` is hermetic and
  sufficient. Ripgrep adds significant performance for large repos and is a natural
  extension point when real-world benchmarks demand it.

- **Option E — Fold tools into `ferrochain-community`:** `ferrochain-community`
  is intended for third-party contributed tool integrations (HTTP clients, databases,
  external APIs). First-party filesystem/shell tools belong in a maintained first-party
  crate with a stable API guarantee — not in the community catch-all crate.

## Source / Origin

- **D23 authority:** D23 decisions log entry (STATE.md) — item 5 "first-party
  file/bash/search tool contracts."
- **Domain E forcing function:** domain-e-agentic-coding-assistant.md §3 items 1-5 and
  §6 table rows for `read_file`, `write_file`, `edit_file`, `list_dir`, `bash`, `grep` —
  all DEGRADED, closure path "first-party ferrochain-tools crate implementing the Tool
  trait with sandbox path-guard integration."
- **BC-2.13.001–003:** ferrochain-sandbox enforcement contracts — the policy substrate
  reused by `tools::fs` and `tools::shell`.
- **BC-2.05.006:** ActionRisk enum and RiskGatePolicy — referenced for risk tier defaults
  in Decision 3.
- **ADR-018:** PreToolCallHook — approval-hook integration referenced in Decision 3 and 4.
- **BC-2.16.001:** per-tool retry keying — retry classification in Decision 4.
- **VP-003:** path-confinement proof (existing Kani P0) — reused by tools::fs without
  modification (PathGuard is the same type).

## Consequences

### Positive

- Agentic coding CLI applications can use `ReadFileTool`, `WriteFileTool`, `EditFileTool`,
  `ListDirTool`, `BashTool`, `GrepTool` out of the box without writing wrapper code.
- All tools automatically integrate with PathGuard (ferrochain-sandbox), ActionRisk
  (ferrochain-graph::hitl), PreToolCallHook (ADR-018), and retry policy (BC-2.16.001).
- VP-003 (path-confinement Kani proof) is reused by `tools::fs` without modification;
  path-confinement correctness proof coverage extends to first-party tools.
- `BashTool` risk floor invariant (`Medium` minimum) can be expressed as a Kani P0
  candidate (VP-013): `BashTool::set_risk(ReadOnly)` and `set_risk(Low)` return error,
  never succeed.

### Negative / Trade-offs

- Crate #21 increases workspace build time slightly. Mitigated: `ferrochain-tools` is
  an optional dependency for applications that don't need it (tool registration is
  explicit; not auto-loaded by graph runtime).
- `EditFileTool` exact-match semantics may frustrate users expecting fuzzy replacement.
  Addressed: opt-in `EditConfig::fuzzy_threshold` with `similar` crate for production
  applications that need it.
- `GrepTool` in-process `regex` will be slower than ripgrep on large repos. Accepted for
  v1; documented as a known performance bound, not a production-blocking issue for the
  typical coding-assistant search radius.
- A new `E-TOOLS-*` error namespace requires a PO supplement amendment to
  `error-taxonomy.md` before Phase 2 story decomposition.

### Status as of 2026-07-22

Architecture decision accepted. No implementation yet (Phase 1). Crate #21 placeholder
(`Cargo.toml` stub) should be created by devops-engineer at workspace prep; Wave 1
delivery. PO BC delivery for SS-23 tool behavioral contracts is a prerequisite for
Phase 2 story decomposition.
