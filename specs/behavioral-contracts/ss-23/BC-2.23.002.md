---
document_type: behavioral-contract
level: L3
bc_id: BC-2.23.002
version: "1.2"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-23
capability: CAP-036
crate: ferrochain-tools
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-22T00:00:00Z
di_anchors: [DI-014]
vp_seed: false
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 first-party tool library, SS-23 WriteFileTool."
  - "1.1 (burst-233/F-P133-03/2026-07-22): PC-5 / EC-003 / EC-004 / EC-006 / TV-004 — assign E-TOOLS-008 FileIoError to the OS-level I/O error paths (was 'TOOLS, I/O category' with no code). Structured fields: tool_type: 'WriteFileTool', path: <file_path>, io_kind: <ErrorKind debug name>. Gate #33 forward+reverse: E-TOOLS-008 now covers these raise sites; error-taxonomy.md v1.32 anchors BC-2.23.002 in E-TOOLS-008 row."
  - "1.2 (burst-247/F-P146-02/2026-07-24): H1 title — add E-TOOLS-008 to raised-code enumeration per SS-23 title policy (exhaustive RAISED codes only; Ok-path payload flags excluded). Before: trailing 'E-TOOLS-001'. After: 'E-TOOLS-001/008'. TD-VSDD-060: BC-INDEX row and bc-authoring-plan Batch 20 title cell updated same burst (state-manager handles BC-INDEX). input-hash updated 0bc5c5d→64d7571 (inputs unchanged; hash drift from prior burst)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-036
  - architecture/decisions/ADR-020-first-party-tool-library.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-020-first-party-tool-library.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "e18c596"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.23.002: WriteFileTool — PathGuard-Confined Atomic Write; High ActionRisk; No Auto-Retry; E-TOOLS-001/008

## Description

`WriteFileTool` in `ferrochain-tools::tools::fs` implements the `Tool` trait with
`ActionRisk::High`. It creates or overwrites a file at a caller-supplied path with the
provided content. Before any I/O, the path argument is validated against the configured
`PathGuard` (ferrochain-sandbox); paths outside the guard scope return
`Err(E-TOOLS-001 PathConfinementViolation)`. The write is performed atomically: the
implementation writes to a temporary file in the same directory and renames to the target
path, preventing partial-write corruption. `WriteFileTool` is non-idempotent and is NOT
enrolled for automatic retry (ADR-020 Decision 4); re-invocation of a failed write requires
explicit human re-approval via `PreToolCallHook` (ADR-018).

## Preconditions

1. `WriteFileTool` is constructed with a `PathGuard` instance.
2. The caller invokes the tool with JSON args `{ "path": "<path-string>", "content": "<content-string>" }`.
3. `path` is a non-empty string; `content` may be empty (zero-byte file is valid).
4. `ActionRisk::High` is the annotated risk tier; `RiskGatePolicy` will interrupt before
   execution unless a `PreToolCallHook` explicitly approves (BC-2.05.006, ADR-018).

## Postconditions

1. **Happy path:** `PathGuard::check(path)` passes and the write succeeds. The target file
   contains exactly the bytes of `content`. The tool returns `ToolOutput::Text("written: <path>")`.
   Parent directories that do not exist are NOT created automatically; callers must ensure the
   parent directory exists. If the parent directory does not exist, the tool returns an I/O error.
2. **Path confinement violation:** `PathGuard::check(path)` returns false for any reason.
   The tool returns
   `Err(FerrochainError { component: "TOOLS", category: Category::SECURITY,
   code: "E-TOOLS-001", message: "PathConfinementViolation: path '<path>' is outside the
   configured PathGuard scope" })`.
   No I/O is performed; no temporary file is created.
3. **Atomic write semantics:** The implementation writes content to `<path>.ferroctmp_<random>`
   in the same directory, then performs a rename to `<path>`. If the rename fails, the
   temporary file is removed and the error is propagated. The target file is never left in a
   partial-write state observable by concurrent readers.
4. **Overwrite existing file:** If `path` already exists, it is replaced atomically. No backup
   is created. The caller is responsible for any desired backup semantics.
5. **I/O error:** OS-level I/O failure (disk full, permission denied) propagates as
   `Err(FerrochainError { component: "TOOLS", category: Category::TOOL, code: "E-TOOLS-008",
   message: "WriteFileTool I/O error on '<path>': <io_kind>", tool_type: "WriteFileTool",
   path: <file_path>, io_kind: <std::io::ErrorKind debug name> })`.
   The temporary file is removed on error.

## Invariants

- `PathGuard::check` is called for EVERY invocation before any filesystem open. No bypass exists.
- Write is always atomic via temp-file + rename. No direct-write code path exists.
- `WriteFileTool` has `retry_eligible: false` — the framework does not auto-retry write
  failures. A failed write followed by a retry requires explicit re-approval by the
  `PreToolCallHook`. This prevents double-write on transient errors.
- **DI-014 (No Silent Swallowing):** I/O errors and path violations propagate as
  `Err(FerrochainError)`. The tool never returns success for a write that did not complete.
- `ActionRisk::High` cannot be lowered below `Medium` by application configuration per
  ADR-020 Decision 3 (tools that touch the filesystem with write semantics remain High or
  Medium at minimum).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Path is outside PathGuard scope | `Err(E-TOOLS-001 PathConfinementViolation)` — no I/O |
| EC-002 | Target file exists; caller writes different content | File atomically replaced; old content is gone; `ToolOutput::Text("written: <path>")` |
| EC-003 | Parent directory does not exist | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "WriteFileTool", path: "<path>", io_kind: "NotFound" }` |
| EC-004 | Disk full during write | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "WriteFileTool", path: "<path>", io_kind: "StorageFull" }`; temp file removed; target file unchanged |
| EC-005 | `content` is empty string | `ToolOutput::Text("written: <path>")` — zero-byte file created atomically |
| EC-006 | Path is a directory (not a file) | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "WriteFileTool", path: "<path>", io_kind: "IsADirectory" }`; rename to a directory fails at OS level |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `{ "path": "/workspace/out.txt", "content": "hello" }` — path within PathGuard, parent exists | `ToolOutput::Text("written: /workspace/out.txt")` | happy-path |
| TV-002 | `{ "path": "/etc/shadow", "content": "evil" }` — outside PathGuard | `Err(E-TOOLS-001)` — `PathConfinementViolation: path '/etc/shadow' is outside the configured PathGuard scope` | security (confinement) |
| TV-003 | `{ "path": "/workspace/existing.txt", "content": "new" }` — overwrites existing | `ToolOutput::Text("written: /workspace/existing.txt")`; file contains `"new"` | overwrite semantics |
| TV-004 | `{ "path": "/workspace/nodir/out.txt", "content": "x" }` — parent `/workspace/nodir/` missing | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "WriteFileTool", path: "/workspace/nodir/out.txt", io_kind: "NotFound" }` | error-case (missing parent) |
| TV-005 | `{ "path": "/workspace/empty.txt", "content": "" }` | `ToolOutput::Text("written: /workspace/empty.txt")`; zero-byte file | edge-case (empty content) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.23.002-A (VP-003 reuse) | PathGuard::check called before any filesystem open | Kani proof reused from VP-003 |
| VP-2.23.002-B | Atomic write: target file never partially written (temp-rename invariant) | Unit test: inject failure after temp-write, before rename; assert target unchanged |
| VP-2.23.002-C | DI-014: I/O errors propagate as Err; no silent success on failed write | Unit tests for EC-003, EC-004 |

## Related BCs

- BC-2.23.001 — sibling: ReadFileTool (same PathGuard substrate; ReadOnly risk)
- BC-2.23.003 — sibling: EditFileTool (same High risk; different write semantics)
- BC-2.13.004 — depends on: VP-003 PathGuard workspace-confinement Kani proof
- BC-2.16.001 — related to: WriteFileTool retry_eligible: false (non-idempotent; no auto-retry)
- BC-2.05.007 — related to: ActionRisk::High → PreToolCallHook approval gate at dispatch

## Architecture Anchors

- `architecture/decisions/ADR-020-first-party-tool-library.md` — Decision 2 (tools::fs WriteFileTool), Decision 3 (High ActionRisk), Decision 4 (retry_eligible: false), Decision 5 (E-TOOLS-001)
- `architecture/module-decomposition.md` — SS-23, `tools::fs` module in ferrochain-tools
- `architecture/purity-boundary-map.md` — SS-23 Effectful Shell classification

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-23 story]_

## VP Anchors

- VP-2.23.002-A (VP-003 reuse)
- VP-2.23.002-B
- VP-2.23.002-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-036 |
| Capability Anchor Justification | CAP-036 ("First-Party Filesystem Tools (tools::fs — ReadFileTool, WriteFileTool, EditFileTool, ListDirTool)") per capabilities-p1-p2.md §CAP-036 — this BC specifies WriteFileTool's PathGuard-confinement, atomic write semantics, High ActionRisk, no-auto-retry policy, and E-TOOLS-001 error code that CAP-036 names as part of the tools::fs surface |
| L2 Domain Invariants | DI-014 (Error Propagation — I/O failures and path violations propagate as Err; no silent success) |
| Architecture Authority | ADR-020 Decisions 2, 3, 4, and 5 (WriteFileTool contract, High ActionRisk, retry_eligible: false, E-TOOLS-001) |
| Binding Decisions | D23 (first-party tool library scope, SS-23 creation) |
| VP Registration | VP-003 reuse; VP-2.23.002-B/C (unit tests) |
| Module | ferrochain-tools / tools::fs |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration |
