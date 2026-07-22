---
document_type: behavioral-contract
level: L3
bc_id: BC-2.23.001
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
  - "1.2 (burst-233/F-P133-03/2026-07-22): PC-4 / EC-005 / TV-004 — assign E-TOOLS-008 FileIoError to the OS-level I/O error path (was 'TOOLS, I/O category' with no code). Structured fields: tool_type: 'ReadFileTool', path: <file_path>, io_kind: <ErrorKind debug name>. Gate #33 forward+reverse: E-TOOLS-008 now covers this raise site; error-taxonomy.md v1.32 anchors BC-2.23.001 in E-TOOLS-008 row."
  - "1.1 (Burst-232/2026-07-22): Fix Category::VALIDATION → Category::VAL in PC-3 (E-TOOLS-002 FileReadExceedsLimit). VALIDATION is not in the canonical 12-member Category enum; E-TOOLS-002 is VAL per error-taxonomy v1.31. D23 straggler sweep."
  - "1.0 (D23/2026-07-22): Initial BC — D23 first-party tool library, SS-23 ReadFileTool."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-036
  - architecture/decisions/ADR-020-first-party-tool-library.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-020-first-party-tool-library.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "6e07319"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.23.001: ReadFileTool — PathGuard-Confined File Read; max_bytes 1 MiB Limit; E-TOOLS-001 / E-TOOLS-002

## Description

`ReadFileTool` in `ferrochain-tools::tools::fs` implements the `Tool` trait with
`ActionRisk::ReadOnly`. It reads a file at a caller-supplied path and returns its contents as
a UTF-8 string (or raw bytes for binary files). Before any I/O, the path argument is validated
against the configured `PathGuard` (ferrochain-sandbox); paths outside the guard scope return
`Err(E-TOOLS-001 PathConfinementViolation)`. A configurable `max_bytes: u64` limit (default
1,048,576 — 1 MiB) prevents accidental large-file ingestion into model context; exceeding it
returns `Err(E-TOOLS-002 FileReadExceedsLimit)` with both the file size and the configured
limit.

## Preconditions

1. `ReadFileTool` is constructed with a `PathGuard` instance and an optional `max_bytes`
   configuration (`ReadFileConfig::max_bytes: u64`, default 1,048,576).
2. The caller invokes the tool with JSON args `{ "path": "<path-string>" }` where `path` is a
   non-empty string.
3. The `PathGuard` encodes at least one allowed root scope (ferrochain-sandbox
   `BC-2.13.004` workspace-confinement invariant applies).

## Postconditions

1. **Happy path:** `path` resolves to an existing readable file within `PathGuard` scope and
   the file size is ≤ `max_bytes`. The tool returns `ToolOutput::Text(contents)` where
   `contents` is the full UTF-8 file contents. If the file contains non-UTF-8 bytes, the
   implementation returns them lossily decoded (replacement character U+FFFD) rather than
   erroring — consumers that need strict UTF-8 validation must do so on the returned text.
2. **Path confinement violation:** `PathGuard::check(path)` returns false for any reason
   (path is outside scope, is a symlink escaping scope, is an absolute path not under the
   guard root). The tool returns
   `Err(FerrochainError { component: "TOOLS", category: Category::SECURITY,
   code: "E-TOOLS-001", message: "PathConfinementViolation: path '<path>' is outside the
   configured PathGuard scope" })`.
   No I/O is performed; no side effect occurs.
3. **File size exceeds limit:** `PathGuard` passes but the file's metadata size exceeds
   `max_bytes`. The tool returns
   `Err(FerrochainError { component: "TOOLS", category: Category::VAL,
   code: "E-TOOLS-002", message: "FileReadExceedsLimit: file '<path>' is <actual_bytes> bytes,
   exceeds configured limit of <max_bytes> bytes" })`.
   The file is NOT read into memory before this check; the implementation uses
   `std::fs::metadata()` to obtain the size before opening the file.
4. **File not found or permission denied:** The tool propagates the OS I/O error as
   `Err(FerrochainError { component: "TOOLS", category: Category::TOOL, code: "E-TOOLS-008",
   message: "ReadFileTool I/O error on '<path>': <io_kind>", tool_type: "ReadFileTool",
   path: <file_path>, io_kind: <std::io::ErrorKind debug name> })`.
   This is not a path-confinement violation; it is a runtime filesystem error.
5. VP-003 (workspace confinement Kani proof) coverage extends to `ReadFileTool` without
   modification: `PathGuard` is the same type already proven; no new Kani proof is required.

## Invariants

- `PathGuard::check` is called for EVERY invocation before any filesystem open. There is no
  bypass, no trust-caller shortcut.
- `max_bytes` is checked against file metadata size BEFORE reading file contents into memory.
  The implementation must not read up to `max_bytes` and then truncate; it must reject first.
- `ReadFileTool` does not retain any file handle or content reference between tool calls.
  Each invocation is stateless.
- **DI-014 (No Silent Swallowing):** validation failures (path confinement, size limit, I/O
  error) propagate as `Err(FerrochainError)`. The tool never returns an empty `ToolOutput` or
  `None` to represent a failure.
- `ActionRisk::ReadOnly` is the annotated risk tier; this tier cannot be raised by application
  configuration (only lowered, but ReadOnly is already the floor). `RiskGatePolicy` auto-approve
  semantics for ReadOnly (BC-2.05.006) apply.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Path is outside PathGuard scope (e.g., `"/etc/passwd"` when guard root is `"/workspace"`) | `Err(E-TOOLS-001 PathConfinementViolation)` — no I/O performed |
| EC-002 | Path is a symlink that resolves to a target outside PathGuard scope | `Err(E-TOOLS-001 PathConfinementViolation)` — symlink target must also pass `PathGuard::check` |
| EC-003 | File exists, is within scope, but size is 1,048,577 bytes (1 byte over 1 MiB default) | `Err(E-TOOLS-002 FileReadExceedsLimit)` — file not read; error message includes actual size and limit |
| EC-004 | File exists, within scope, size ≤ max_bytes, but contains binary (non-UTF-8) bytes | `ToolOutput::Text(contents)` with U+FFFD replacement for non-UTF-8 bytes — not an error; caller annotated |
| EC-005 | File does not exist | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "ReadFileTool", path: "<path>", io_kind: "NotFound" }` |
| EC-006 | `ReadFileConfig::max_bytes` is set to 0 (caller misconfiguration) | `Err(E-TOOLS-002 FileReadExceedsLimit)` for any non-empty file; zero-byte files return `ToolOutput::Text("")` |
| EC-007 | Concurrent invocations of `ReadFileTool` for the same path | Both complete independently; no locking; last-write-wins on the filesystem is an accepted OS behavior |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `{ "path": "/workspace/README.md" }` — file exists, 512 bytes, within PathGuard | `ToolOutput::Text("<file contents>")` | happy-path |
| TV-002 | `{ "path": "/etc/passwd" }` — outside PathGuard scope `("/workspace")` | `Err(E-TOOLS-001)` — `PathConfinementViolation: path '/etc/passwd' is outside the configured PathGuard scope` | security (confinement) |
| TV-003 | `{ "path": "/workspace/large.bin" }` — file is 2 MiB, max_bytes = 1,048,576 | `Err(E-TOOLS-002)` — `FileReadExceedsLimit: file '/workspace/large.bin' is 2097152 bytes, exceeds configured limit of 1048576 bytes` | size-limit |
| TV-004 | `{ "path": "/workspace/missing.txt" }` — file does not exist | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "ReadFileTool", path: "/workspace/missing.txt", io_kind: "NotFound" }` | error-case (not-found) |
| TV-005 | `{ "path": "/workspace/binary.bin" }` — binary file, 100 bytes, within scope | `ToolOutput::Text(<lossily-decoded string>)` — no error | edge-case (binary) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.23.001-A (VP-003 reuse) | PathGuard::check is called before any filesystem open for every ReadFileTool invocation | Kani proof reused from VP-003 (PathGuard type is unchanged) |
| VP-2.23.001-B | max_bytes check uses metadata size, not post-read truncation | Unit test: mock filesystem with file size = max_bytes + 1; assert Err before read |
| VP-2.23.001-C | DI-014 compliance: Err propagates for all failure conditions; no empty ToolOutput fallback | Unit tests for each failure path (EC-001 through EC-005) |

## Related BCs

- BC-2.23.002 — sibling: WriteFileTool (same PathGuard substrate; different risk tier)
- BC-2.23.003 — sibling: EditFileTool (same PathGuard substrate; different risk tier)
- BC-2.23.004 — sibling: ListDirTool (same PathGuard substrate; ReadOnly)
- BC-2.13.004 — depends on: workspace confinement PathGuard invariant (VP-003 Kani proof)
- BC-2.05.006 — related to: ActionRisk::ReadOnly auto-approve semantics in RiskGatePolicy

## Architecture Anchors

- `architecture/decisions/ADR-020-first-party-tool-library.md` — Decision 2 (tools::fs module), Decision 3 (ActionRisk defaults), Decision 5 (E-TOOLS-001/002 error namespace)
- `architecture/module-decomposition.md` — SS-23, `tools::fs` module in ferrochain-tools
- `architecture/purity-boundary-map.md` — SS-23 Effectful Shell classification

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-23 story]_

## VP Anchors

- VP-2.23.001-A (VP-003 reuse — no new VP-INDEX entry needed)
- VP-2.23.001-B
- VP-2.23.001-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-036 |
| Capability Anchor Justification | CAP-036 ("First-Party Filesystem Tools (tools::fs — ReadFileTool, WriteFileTool, EditFileTool, ListDirTool)") per capabilities-p1-p2.md §CAP-036 — this BC specifies the ReadFileTool behavioral contract including PathGuard-confinement, max_bytes size limit, E-TOOLS-001/002 error codes, and ReadOnly risk tier that CAP-036 names as part of the tools::fs surface |
| L2 Domain Invariants | DI-014 (Error Propagation — validation failures propagate as Err; no silent empty fallback) |
| Architecture Authority | ADR-020 Decisions 2, 3, and 5 (tools::fs module, ActionRisk defaults, E-TOOLS-001/002 namespace) |
| Binding Decisions | D23 (first-party tool library scope, SS-23 creation) |
| VP Registration | VP-003 reuse (no new VP-INDEX entry); VP-2.23.001-B/C (unit tests) |
| Module | ferrochain-tools / tools::fs |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration |
