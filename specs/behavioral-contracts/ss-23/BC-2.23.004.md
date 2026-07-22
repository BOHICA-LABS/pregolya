---
document_type: behavioral-contract
level: L3
bc_id: BC-2.23.004
version: "1.1"
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
  - "1.1 (burst-233/F-P133-03/2026-07-22): PC-3 / PC-5 / EC-002 / EC-005 / TV-004 — assign E-TOOLS-008 FileIoError to the OS-level I/O error paths (was 'TOOLS, I/O category' with no code). Structured fields: tool_type: 'ListDirTool', path: <dir_path>, io_kind: <ErrorKind debug name> ('NotADirectory' for PC-3/EC-002; 'NotFound' for PC-5/EC-005). Gate #33 forward+reverse clean."
  - "1.0 (D23/2026-07-22): Initial BC — D23 first-party tool library, SS-23 ListDirTool."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-036
  - architecture/decisions/ADR-020-first-party-tool-library.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-020-first-party-tool-library.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "9ed2507"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.23.004: ListDirTool — PathGuard-Confined Directory Listing; ReadOnly; E-TOOLS-001; DirEntry Struct

## Description

`ListDirTool` in `ferrochain-tools::tools::fs` implements the `Tool` trait with
`ActionRisk::ReadOnly`. It returns the entries of a directory at a caller-supplied path
as a JSON array of `DirEntry` objects, each containing `name`, `kind` (File, Dir, or
Symlink), and `size_bytes` (for files; `null` for directories and symlinks). Before any
I/O, the path is validated against the configured `PathGuard`. The listing is
non-recursive (depth 1); callers that need recursive enumeration make multiple calls.
No output-size limit is specified for `ListDirTool` — directories are assumed to be
bounded in the workspace; if an exceptionally large listing is a concern, callers should
filter at the application layer.

## Preconditions

1. `ListDirTool` is constructed with a `PathGuard` instance.
2. The caller invokes the tool with JSON args `{ "path": "<path-string>" }`.
3. `path` is a non-empty string resolving to a directory within `PathGuard` scope.

## Postconditions

1. **Happy path:** `PathGuard::check(path)` passes and `path` is a readable directory.
   The tool returns `ToolOutput::Json(entries)` where `entries` is a JSON array of
   `DirEntry` objects:
   ```json
   [
     { "name": "README.md", "kind": "File", "size_bytes": 1234 },
     { "name": "src",       "kind": "Dir",  "size_bytes": null },
     { "name": "link",      "kind": "Symlink", "size_bytes": null }
   ]
   ```
   Entries are sorted lexicographically by `name`. Hidden files (names starting with `.`)
   are included unless excluded by `PathGuard` policy.
2. **Path confinement violation:** Returns
   `Err(FerrochainError { component: "TOOLS", category: Category::SECURITY,
   code: "E-TOOLS-001", message: "PathConfinementViolation: path '<path>' is outside the
   configured PathGuard scope" })`.
3. **Path is a file, not a directory:** Returns
   `Err(FerrochainError { component: "TOOLS", category: Category::TOOL, code: "E-TOOLS-008",
   message: "ListDirTool I/O error on '<path>': NotADirectory",
   tool_type: "ListDirTool", path: <dir_path>, io_kind: "NotADirectory" })`.
4. **Empty directory:** Returns `ToolOutput::Json([])` — zero entries, not an error.
5. **Permission denied or not found:** Returns
   `Err(FerrochainError { component: "TOOLS", category: Category::TOOL, code: "E-TOOLS-008",
   message: "ListDirTool I/O error on '<path>': <io_kind>",
   tool_type: "ListDirTool", path: <dir_path>, io_kind: <std::io::ErrorKind debug name> })`.

## Invariants

- `PathGuard::check` is called for EVERY invocation before any filesystem open.
- Listing is non-recursive (depth 1). The tool returns only the direct children of `path`;
  it does not descend into subdirectories.
- `DirEntry::size_bytes` is the file's metadata size (same as `std::fs::metadata().len()`).
  It is NOT read into memory; only stat is called.
- `ActionRisk::ReadOnly` — `RiskGatePolicy` auto-approve semantics apply (BC-2.05.006).
- **DI-014 (No Silent Swallowing):** Path violations, permission errors, and not-a-directory
  errors propagate as `Err(FerrochainError)`. Empty directories return `Ok([])` — not an error.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Path is outside PathGuard scope | `Err(E-TOOLS-001 PathConfinementViolation)` — no I/O |
| EC-002 | Path resolves to a file (not a directory) | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "ListDirTool", path: "<path>", io_kind: "NotADirectory" }` |
| EC-003 | Directory is empty | `ToolOutput::Json([])` — empty array, not an error |
| EC-004 | Directory contains a symlink | Entry with `kind: "Symlink"` included; size_bytes is `null`; the symlink target is NOT resolved for PathGuard (symlink target check is the caller's responsibility) |
| EC-005 | Directory not found | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "ListDirTool", path: "<path>", io_kind: "NotFound" }` |
| EC-006 | Directory has 10,000 entries | `ToolOutput::Json(<10,000 entries>)` — no truncation at this layer; callers should handle large listings at application layer |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `{ "path": "/workspace" }` — workspace contains 3 files + 1 subdir, within PathGuard | `ToolOutput::Json([{...}, {...}, {...}, {...}])` — 4 entries sorted by name | happy-path |
| TV-002 | `{ "path": "/etc" }` — outside PathGuard scope | `Err(E-TOOLS-001)` — `PathConfinementViolation: path '/etc' is outside the configured PathGuard scope` | security (confinement) |
| TV-003 | `{ "path": "/workspace/empty_dir" }` — exists, empty | `ToolOutput::Json([])` | edge-case (empty dir) |
| TV-004 | `{ "path": "/workspace/src/main.rs" }` — path is a file | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "ListDirTool", path: "/workspace/src/main.rs", io_kind: "NotADirectory" }` | error-case |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.23.004-A (VP-003 reuse) | PathGuard::check called before any filesystem open | Kani proof reused from VP-003 |
| VP-2.23.004-B | Empty directory returns Ok([]), not Err | Unit test: create empty dir, assert ToolOutput::Json([]) |
| VP-2.23.004-C | Entries sorted lexicographically by name | Unit test: dir with unsorted entries; assert sorted output |

## Related BCs

- BC-2.23.001 — sibling: ReadFileTool (same ReadOnly risk; same PathGuard substrate)
- BC-2.13.004 — depends on: VP-003 PathGuard workspace-confinement Kani proof
- BC-2.05.006 — related to: ActionRisk::ReadOnly auto-approve semantics in RiskGatePolicy

## Architecture Anchors

- `architecture/decisions/ADR-020-first-party-tool-library.md` — Decision 2 (ListDirTool, stdlib only, no external dep), Decision 3 (ReadOnly ActionRisk), Decision 5 (E-TOOLS-001)
- `architecture/module-decomposition.md` — SS-23, `tools::fs` module in ferrochain-tools

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-23 story]_

## VP Anchors

- VP-2.23.004-A (VP-003 reuse)
- VP-2.23.004-B
- VP-2.23.004-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-036 |
| Capability Anchor Justification | CAP-036 ("First-Party Filesystem Tools (tools::fs — ReadFileTool, WriteFileTool, EditFileTool, ListDirTool)") per capabilities-p1-p2.md §CAP-036 — this BC specifies ListDirTool's PathGuard-confinement, DirEntry struct shape, ReadOnly risk tier, non-recursive depth-1 semantics, and E-TOOLS-001 error code that CAP-036 names as part of the tools::fs surface |
| L2 Domain Invariants | DI-014 (Error Propagation — path violations and I/O errors propagate as Err; empty dir returns Ok([]) not Err) |
| Architecture Authority | ADR-020 Decisions 2, 3, and 5 (ListDirTool contract, stdlib-only, ReadOnly ActionRisk, E-TOOLS-001) |
| Binding Decisions | D23 (first-party tool library scope, SS-23 creation) |
| VP Registration | VP-003 reuse; VP-2.23.004-B/C (unit tests) |
| Module | ferrochain-tools / tools::fs |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration |
