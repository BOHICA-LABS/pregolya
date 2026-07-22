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
version: "1.6"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D23]
supersedes: null
superseded_by: null
subsystems_affected: [SS-23]
changelog:
  - "1.6 (burst-234/2026-07-22): F-P134-02 label format normalization — Decision 5 anchor list: normalize BC-2.23.006 label to prescribed canonical form `(GrepTool — tools::search traversal I/O error)`. Prior v1.5 intermediate form `(GrepTool traversal I/O error paths — tools::search)` was substantively correct but did not match prescribed format. TD-VSDD-060 sweep: sole occurrence in body text at Decision 5 adjudication paragraph; ADR-010 TOOLS table unaffected (no per-BC labels in that table)."
  - "1.5 (burst-234/2026-07-22): F-P134-02 — Decision 5 anchor list (E-TOOLS-008 adjudication paragraph, line ~224): fix BC-2.23.006 label from `(WriteFileTool missing parent dir)` to `(GrepTool traversal I/O error paths — tools::search)`. BC-2.23.006 is GrepTool / tools::search; the missing-parent-dir scenario belongs to BC-2.23.002 EC-003. ADR-010 TOOLS table label for BC-2.23.006 verified correct (no change required)."
  - "1.4 (burst-234/2026-07-22): PO minted E-TOOLS-009 InvalidRegexPattern (VAL/Never; fields pattern: String + compile_error: String; anchor BC-2.23.006 PC-4/EC-002/TV-003). Add E-TOOLS-009 row to Decision 5 table. Update PO obligation to 9 codes (TD-VSDD-060 sweep: '8 codes' → '9 codes'). TOOLS namespace is now 9 codes (001..009)."
  - "1.3 (burst-233/2026-07-22): F-P133-07 sibling sweep (TD-VSDD-060) — remove stale 'VP-013 Kani P0 candidate' label in §Positive Properties / Rationale (VP-013 seeded burst-232, Kani P1; also correct Kani P0 → Kani P1)."
  - "1.2 (burst-233/2026-07-22): F-P133-01 — fix fabricated E-SANDBOX namespace in Decision 2: tools::fs out-of-guard return corrected from `FerrochainError::sandbox(E-SANDBOX-xxx)` to `Err(E-TOOLS-001 PathConfinementViolation)`; tools::shell timeout return corrected from `FerrochainError::sandbox(E-SANDBOX-timeout)` to `Err(E-TOOLS-004 BashTimeout)`. F-P133-03 adjudication — add E-TOOLS-008 FileIoError to Decision 5 table; category TOOL (OS-level file execution failure; confirmed via ADR-010 12-category axis); RetryHint Maybe; PO obligation extended to 8 codes (anchor BCs 2.23.001–004 and 2.23.006)."
  - "1.1 (dep-validation/2026-07-22): Decision 7 updated with validated pin results (research-agent crates.io/2026-07-21): `similar` 3.1.1 → pin `\"3\"`, owner corrected to mitsuhiko (Armin Ronacher, NOT dtolnay), Apache-2.0 single-licensed (cargo-deny allowlist note added), MSRV 1.85 (consequence flagged); `regex` 1.13.1 → pin `\"1\"`, MIT OR Apache-2.0, MSRV 1.65, both net-new [workspace.dependencies] (workspace uninitialized); linear-time matching guarantee rationale added; in-body research-flag language resolved."
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
Out-of-guard paths return `Err(E-TOOLS-001 PathConfinementViolation)`.

`EditFileTool` receives:
```json
{ "path": "...", "old_string": "...", "new_string": "...", "replace_all": false }
```
It performs an exact-string replacement. The `similar` crate (`similar = "3"`, mitsuhiko,
Apache-2.0 — see Decision 7) is used ONLY if the host opts in to fuzzy-match fallback via
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
client policy). Timeout returns `Err(E-TOOLS-004 BashTimeout)`.

### `tools::search` — Grep / Text Search

| Type | Operation | ActionRisk default |
|------|-----------|-------------------|
| `GrepTool` | Regex search across file(s) or directory; return matches with line numbers | `ReadOnly` |

`GrepTool` accepts:
```json
{ "pattern": "...", "path": "...", "recursive": true, "case_insensitive": false, "max_results": 100 }
```

The `regex` crate (`regex = "1"`, linear-time matching — see Decision 7) handles pattern
matching. Results are capped at `max_results` (default 100) to prevent runaway output.

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
| E-TOOLS-008 | FileIoError | OS-level I/O error during file tool execution (wraps `std::io::ErrorKind`); structured fields: `path: String`, `io_kind: String` (ErrorKind debug name, e.g. "NotFound", "PermissionDenied", "StorageFull", "NotADirectory") |
| E-TOOLS-009 | InvalidRegexPattern | `GrepTool` pattern string failed to compile as a valid regex; structured fields: `pattern: String`, `compile_error: String` (the `regex` crate compile error message); anchor BC-2.23.006 PC-4/EC-002/TV-003 |

**E-TOOLS-008 category adjudication (F-P133-03, burst-233):** BC-2.23.001–004 and
BC-2.23.006 reference OS-level filesystem errors with non-canonical "I/O" and "VALIDATION"
category labels; neither appears in the 12-category canonical axis (ADR-010). Adjudicated
category: **TOOL** ("tool execution failures" per ADR-010 §Category axis — OS errors
discovered during file tool execution are not VAL [path is syntactically valid input], not
SECURITY [path passed PathGuard; E-TOOLS-001 covers the confinement violation case], not
TIMEOUT, not INTERNAL; TOOL is the exact fit). RetryHint: `Maybe` — some OS errors are
transient (e.g., `StorageFull` may resolve); caller must inspect `io_kind` to determine
retry feasibility. Message form: `"<tool_type> I/O error on '<path>': <io_kind>"` — subject
to gate #33 constraint in `error-taxonomy.md` (PO to verify at error-taxonomy authoring).
Anchor BCs: BC-2.23.001 (ReadFileTool), BC-2.23.002 (WriteFileTool), BC-2.23.003
(EditFileTool), BC-2.23.004 (ListDirTool), BC-2.23.006 (GrepTool — tools::search traversal I/O error).

**PO obligation (error-taxonomy.md):** add the `E-TOOLS-*` section with these 9 codes
to `.factory/specs/prd-supplements/error-taxonomy.md`. For E-TOOLS-008 specifically:
category TOOL, RetryHint Maybe, message form subject to gate #33 check; amend PC
error-path rows in BC-2.23.001–004 and BC-2.23.006 to cite `E-TOOLS-008 FileIoError`
replacing the current "I/O category" and "VALIDATION" labels.

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

## Decision 7 — External Dependencies: Validated Pins

Research-agent validation completed 2026-07-21 (crates.io registry, live). All open questions resolved.

| Purpose | Crate | Pin | License | MSRV | Notes |
|---------|-------|-----|---------|------|-------|
| Edit fuzzy-match fallback (`EditFileTool`) | `similar` (mitsuhiko) | `"3"` (3.1.1) | Apache-2.0 (single) | 1.85 | See notes below |
| Regex engine (`GrepTool`) | `regex` (rust-lang) | `"1"` (1.13.1) | MIT OR Apache-2.0 | 1.65 | Net-new workspace dep; linear-time |
| File metadata in `ListDirTool` | stdlib only (`std::fs`) | — | — | — | No external dep needed |
| Path guard integration | `ferrochain-sandbox` internal | — | — | — | No new external dep |

**`similar` attribution correction:** crate owner is mitsuhiko (Armin Ronacher — also
author of `minijinja` and `insta`), NOT dtolnay. Pin as `similar = "3"` (caret — tracks
3.x patch releases; latest 3.1.1 as of 2026-07-21).

**`similar` license note:** Apache-2.0 single-licensed (NOT dual MIT/Apache-2.0).
Acceptable for ferrochain's license posture. `cargo-deny` license policy config MUST
include an explicit `"Apache-2.0"` entry in `[licenses.allow]` at workspace
initialization — this is a devops-engineer obligation, not a blocker, but must not be
omitted (omission causes `cargo-deny` to reject the license silently).

**`similar` API rationale:** `TextDiff::ratio()` is the correct mechanism for multi-line
edit-block fuzzy matching, providing difflib-parity behavior. This is the
industry-standard approach for text editor edit-distance fuzzy fallback.

**`regex` net-new dependency:** `regex` is NOT currently a workspace dependency — the
root `Cargo.toml` workspace has not yet been initialized (as of 2026-07-22). Both
`similar` and `regex` will be net-new `[workspace.dependencies]` entries when
devops-engineer initializes the workspace.

**`regex` linear-time guarantee:** The `regex` crate uses a finite-automata engine with
linear-time matching — no catastrophic backtracking on adversarial inputs. This is an
important safety property for `GrepTool`, which accepts arbitrary user-supplied patterns.

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
- `BashTool` risk floor invariant (`Medium` minimum) is formally captured as VP-013
  (Kani P1, seeded burst-232): `BashTool::set_risk(ReadOnly)` and `set_risk(Low)` return error,
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
- `similar` (dep pin `"3"`) has MSRV 1.85. This sets the effective MSRV floor for
  `ferrochain-tools`. The pinned stable channel in `rust-toolchain.toml` (set by
  devops-engineer at workspace init) MUST be ≥ 1.85. Above the 1.65 MSRV of `regex`
  and the 1.62 MSRV of `inventory` (ADR-016) — toolchain channel selection must satisfy
  the highest MSRV across the workspace, which is 1.85 as of D23.
- `similar` is Apache-2.0 single-licensed. `cargo-deny` configuration must allow
  `"Apache-2.0"` explicitly in `[licenses.allow]`. Devops-engineer owns this at
  workspace init; failure to add it causes silent `cargo-deny` license rejection at CI.

### Status as of 2026-07-22

Architecture decision accepted. No implementation yet (Phase 1). Crate #21 placeholder
(`Cargo.toml` stub) should be created by devops-engineer at workspace prep; Wave 1
delivery. PO BC delivery for SS-23 tool behavioral contracts is a prerequisite for
Phase 2 story decomposition.
