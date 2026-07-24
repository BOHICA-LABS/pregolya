---
document_type: behavioral-contract
level: L3
bc_id: BC-2.23.006
version: "1.5"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-23
capability: CAP-038
crate: ferrochain-tools
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-22T00:00:00Z
di_anchors: [DI-014]
vp_seed: false
red_gate: false
changelog:
  - "1.4 (burst-247/F-P146-02+OBS-naming/2026-07-24): (1) H1 title — replace payload flag E-TOOLS-006 with the correct raised codes E-TOOLS-008 and E-TOOLS-009 per SS-23 title policy (exhaustive RAISED codes only; Ok-path payload flags excluded). Before: 'E-TOOLS-001/006'. After: 'E-TOOLS-001/008/009'. E-TOOLS-006 is retained in the body as a payload annotation (GrepResult.capped). (2) Description and PC-2 body — align capped-flag name from informal 'SearchResultsCapped'-style to canonical field-path notation 'GrepResult.capped' per OBS naming-anchor (error-taxonomy v1.37 adds explicit canonical-field-path marker for E-TOOLS-006). (3) Traceability Capability Anchor Justification — update error-code citation from 'E-TOOLS-001/006' to 'E-TOOLS-001/008/009 (E-TOOLS-006 is a non-raised payload flag)'. TD-VSDD-060: BC-INDEX row and bc-authoring-plan Batch 20 title cell updated same burst (state-manager handles BC-INDEX). input-hash updated 0bc5c5d→64d7571 (inputs unchanged; hash drift from prior burst)."
  - "1.5 (F-P149-02/burst-250/2026-07-24): Architecture Anchors version pin de-pinned: 'ADR-020 TOOLS table in ADR-020 v1.7' → 'ADR-020 Decision 5 §E-TOOLS-* table' (TD-VSDD-091 stable-anchor enforcement, F-P149-02). input-hash updated 64d7571→0b1f1b3 (drift from prior burst)."
  - "1.3 (burst-238/F-P138-01/2026-07-23): Architecture Anchors Decision 5 annotation updated: stale 'architect to append E-TOOLS-008/009 to ADR-020 TOOLS table' replaced with 'appended to ADR-020 TOOLS table in ADR-020 v1.7 (burst-238 sweep: satisfied)'. Completed-handoff residue removal. Gate #28 close F-P138-01."
  - "1.2 (burst-234/F-P134-01/2026-07-22): PC-6 / EC-008 / TV-006 — add E-TOOLS-008 FileIoError (Category::TOOL/Maybe) for OS-level I/O errors during traversal. Traversal-error semantics DECIDED: fail-the-whole-search (not skip-with-warning). Rationale: (1) consistent with sibling tools BC-2.23.001–004 which all fail on E-TOOLS-008; (2) DI-014 no-silent-swallow — returning partial results without signalling the search was cut short is indistinguishable from complete results; (3) guard-verify-before-open invariant establishes that mid-traversal path failures are surfaced; (4) silently-incomplete search results are more hazardous than explicit Err. Structured fields per taxonomy: tool_type='GrepTool' (static), path=<offending path>, io_kind=<std::io::ErrorKind debug name>. Invariants DI-014 bullet updated to include OS-error path. Architecture Anchors Decision 5 updated to note E-TOOLS-008 burst-234. Traceability L2 Domain Invariants updated with E-TOOLS-008 gate #33 reverse anchor. Gate #33 E-TOOLS-008 both-direction PASS: taxonomy v1.32 anchors this BC ('BC-2.23.006 OS-error paths') AND this BC now cites E-TOOLS-008 in PC-6/EC-008/TV-006. TV census: 5→6; test-vectors.md total 669→670."
  - "1.1 (burst-233/F-P133-03/2026-07-22): PC-4 / EC-002 / TV-003 — assign E-TOOLS-009 InvalidRegexPattern (Category::VAL/Never) to the invalid-regex path (was 'VALIDATION category' with no code). 'VALIDATION' is not in the canonical 12-member Category enum; adjudicated: no existing TOOLS code covers regex compile failure; E-CORE-005 wrong component; E-TOOLS-009 minted. Structured fields: pattern: <pattern string>, compile_error: <regex crate error>. Gate #33 forward+reverse: E-TOOLS-009 now covers this raise site; error-taxonomy.md v1.32 anchors BC-2.23.006 in E-TOOLS-009 row. ARCHITECT FLAG: ADR-010 v1.4 and ADR-020 v1.3 TOOLS tables need E-TOOLS-009 appended."
  - "1.0 (D23/2026-07-22): Initial BC — D23 first-party tool library, SS-23 GrepTool."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-038
  - architecture/decisions/ADR-020-first-party-tool-library.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-020-first-party-tool-library.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "01606ea"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.23.006: GrepTool — In-Process Regex Search; Linear-Time `regex` Crate; max_results 100 Cap; Hermetic; PathGuard Scope; E-TOOLS-001/008/009

## Description

`GrepTool` in `ferrochain-tools::tools::search` implements the `Tool` trait with
`ActionRisk::ReadOnly`. It performs regex pattern matching across a file or directory tree
using the `regex` crate (pin `"1"`, linear-time finite-automata engine — no catastrophic
backtracking on adversarial inputs). `GrepTool` does NOT shell out to system `grep` or
`ripgrep`; it is hermetic and unit-testable without system tool availability. Results are
capped at `max_results` (default 100); when the ceiling is reached the tool returns the
first 100 matches with `capped: true` in the output and emits `E-TOOLS-006`
(`GrepResult.capped` payload flag) as an informational annotation (non-fatal). The directory path
argument is validated against `PathGuard` (E-TOOLS-001 on violation).

## Preconditions

1. `GrepTool` is constructed with a `PathGuard` instance and optional `GrepConfig {
   max_results: usize (default 100) }`.
2. The caller invokes the tool with JSON args:
   `{ "pattern": "<regex>", "path": "<path>", "recursive": true, "case_insensitive": false,
   "max_results": 100 }`.
3. `pattern` is a valid regex string compilable by the `regex` crate. An invalid pattern
   is rejected at invocation time with `Err(E-TOOLS-009 InvalidRegexPattern)` (Category::VAL).
4. `path` resolves to an existing file or directory within `PathGuard` scope.

## Postconditions

1. **Happy path (results ≤ max_results):** All matches are returned. The tool returns
   `ToolOutput::Json` with a `GrepResult` object:
   ```json
   {
     "matches": [
       { "file": "/workspace/src/main.rs", "line": 42, "text": "fn main() {" }
     ],
     "capped": false
   }
   ```
   If `path` is a file, only that file is searched. If `path` is a directory and
   `recursive: true`, all files under the directory (within PathGuard scope) are searched.
   If `recursive: false`, only files directly in the directory are searched.
2. **Results capped (non-fatal):** The match count reaches `max_results` before the full
   file tree is searched. The tool returns `ToolOutput::Json({ "matches": [<first 100>], "capped": true })`.
   This is NOT an `Err` — partial results are returned with the `capped` flag. The
   informational code E-TOOLS-006 (`GrepResult.capped` payload flag) appears in the structured output
   annotations, not as a thrown error. Callers can detect the cap via `capped: true`.
3. **Path confinement violation:** Returns
   `Err(FerrochainError { component: "TOOLS", category: Category::SECURITY,
   code: "E-TOOLS-001", message: "PathConfinementViolation: path '<path>' is outside the
   configured PathGuard scope" })`.
4. **Invalid regex:** Returns
   `Err(FerrochainError { component: "TOOLS", category: Category::VAL, code: "E-TOOLS-009",
   message: "InvalidRegexPattern: pattern '<pattern>' failed to compile: <compile_error>",
   pattern: <pattern string from args>, compile_error: <error from regex crate> })`.
5. **No matches found:** Returns `ToolOutput::Json({ "matches": [], "capped": false })` —
   not an error.
6. **OS-level I/O error during traversal (fail-the-whole-search):** If an OS-level I/O
   error occurs on any visited path during recursive directory traversal — e.g.,
   `PermissionDenied` when opening a subdirectory, `NotFound` for a file deleted between
   directory listing and open, `NotADirectory` for a path whose type changed mid-traversal,
   or any other `std::io::Error` from the filesystem — the search is aborted immediately.
   The tool returns:
   `Err(FerrochainError { component: "TOOLS", category: Category::TOOL,
   code: "E-TOOLS-008", message: "GrepTool I/O error on '<path>': <io_kind>",
   tool_type: "GrepTool", path: <offending_path_string>,
   io_kind: <std::io::ErrorKind debug name e.g. "PermissionDenied"> })`.
   Partial results accumulated before the error are NOT returned; the caller receives only
   the `Err` so that the incomplete search is never silently treated as a complete result
   (DI-014). This also applies to I/O errors on the root `path` argument after it passes
   `PathGuard::check` — the guard pass and the subsequent `fs::open` are distinct steps;
   an I/O error at open time is E-TOOLS-008, not E-TOOLS-001.

## Invariants

- `GrepTool` uses the `regex` crate exclusively. It does NOT shell out to grep, ripgrep,
  or any system tool. No subprocess is spawned. This is a hermetic, in-process operation.
- **Linear-time guarantee:** The `regex` crate uses a finite-automata engine. No regex
  pattern can cause catastrophic backtracking. This is a correctness property for accepting
  untrusted user-supplied patterns.
- `PathGuard::check` is called for the root `path` argument. For recursive traversal,
  each visited path is also verified against the guard before the file is opened.
- **DI-014 (No Silent Swallowing):** Path violations, invalid patterns, and OS-level I/O
  errors during traversal all propagate as `Err`. Zero matches return `Ok` with an empty
  array — not silently swallowed as an error. Partial traversal results accumulated before
  an I/O error are discarded; the caller receives only the `Err` so that an incomplete
  search is never silently accepted as a complete result (PC-6).
- `ActionRisk::ReadOnly` — no write to the filesystem occurs. `RiskGatePolicy` auto-approve
  semantics apply (BC-2.05.006).
- Result ordering: matches are returned in file-path-then-line-number order (lexicographic
  by file path within a directory; line order within a file).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Path is outside PathGuard scope | `Err(E-TOOLS-001 PathConfinementViolation)` — no I/O |
| EC-002 | Pattern is invalid regex (e.g., `"[unclosed"`) | `Err(E-TOOLS-009 InvalidRegexPattern)` — `{ pattern: "[unclosed", compile_error: "<regex crate error message>" }` — Category::VAL |
| EC-003 | Pattern matches 150 files with `max_results = 100` | `ToolOutput::Json({ ..., "capped": true })` — first 100 matches; non-fatal |
| EC-004 | Pattern matches no files | `ToolOutput::Json({ "matches": [], "capped": false })` — empty results, not an error |
| EC-005 | `path` is a file (not a directory), `recursive: true` | Only that file is searched; `recursive` is ignored when path is a file |
| EC-006 | Adversarial pattern like `"(a+)+"` (exponential in NFA) | `regex` crate rejects or compiles to linear-time DFA; no catastrophic backtracking; search completes in bounded time |
| EC-007 | `case_insensitive: true`, pattern `"Hello"` | Matches `"hello"`, `"HELLO"`, `"Hello"` etc. |
| EC-008 | `PermissionDenied` on a subdirectory mid-traversal (PathGuard passed root; OS denies subdir open) | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "GrepTool", path: "/workspace/secret", io_kind: "PermissionDenied" }` — search aborted; partial results discarded (DI-014) |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `{ "pattern": "fn main", "path": "/workspace/src", "recursive": true }` — 3 matches in 2 files | `ToolOutput::Json({ "matches": [3 entries], "capped": false })` | happy-path |
| TV-002 | `{ "pattern": "TODO", "path": "/workspace", "max_results": 2, "recursive": true }` — 5 matches exist | `ToolOutput::Json({ "matches": [2 entries], "capped": true })` | cap enforcement |
| TV-003 | `{ "pattern": "[bad regex", "path": "/workspace" }` — invalid pattern | `Err(E-TOOLS-009 InvalidRegexPattern)` — `{ pattern: "[bad regex", compile_error: "<regex crate error>" }` — VAL | invalid pattern |
| TV-004 | `{ "pattern": "NOTFOUND", "path": "/workspace" }` | `ToolOutput::Json({ "matches": [], "capped": false })` | no matches |
| TV-005 | `{ "pattern": "foo", "path": "/etc" }` — outside PathGuard | `Err(E-TOOLS-001 PathConfinementViolation)` | security (confinement) |
| TV-006 | `{ "pattern": "fn ", "path": "/workspace", "recursive": true }` — PathGuard passes; subdir `/workspace/secret` returns `PermissionDenied` on open | `Err(E-TOOLS-008 FileIoError)` — `{ tool_type: "GrepTool", path: "/workspace/secret", io_kind: "PermissionDenied" }` — search aborted; no partial matches returned | traversal I/O error |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.23.006-A (VP-003 partial reuse) | PathGuard::check called for every accessed path (root + each recursive subpath) | Unit test: mock PathGuard that records calls; assert called for each file path visited |
| VP-2.23.006-B | max_results capping: first 100 matches returned with capped=true when > 100 exist | Unit test: directory with 150 matching files; assert matches.len() == 100 and capped == true |
| VP-2.23.006-C | Hermetic: no subprocess spawned during GrepTool invocation | Integration test: run with a system-command tracer; assert zero subprocess spawns |

## Related BCs

- BC-2.23.001 — sibling: ReadFileTool (same ReadOnly risk; same PathGuard substrate; different operation)
- BC-2.23.004 — sibling: ListDirTool (ReadOnly; PathGuard; directory navigation)
- BC-2.13.004 — depends on: PathGuard workspace-confinement contract (VP-003)
- BC-2.05.006 — related to: ActionRisk::ReadOnly auto-approve semantics in RiskGatePolicy

## Architecture Anchors

- `architecture/decisions/ADR-020-first-party-tool-library.md` — Decision 2 (GrepTool, in-process regex, no subprocess, max_results 100), Decision 3 (ReadOnly ActionRisk), Decision 5 (E-TOOLS-001/006; E-TOOLS-008 OS-error paths minted burst-234; E-TOOLS-009 minted burst-233 — appended to ADR-020 Decision 5 §E-TOOLS-* table (burst-238 sweep: satisfied)), Decision 7 (`regex = "1"` pin, linear-time guarantee, MSRV 1.65)
- `architecture/module-decomposition.md` — SS-23, `tools::search` module in ferrochain-tools
- `architecture/purity-boundary-map.md` — SS-23 Effectful Shell (filesystem traversal)

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-23 story]_

## VP Anchors

- VP-2.23.006-A
- VP-2.23.006-B
- VP-2.23.006-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-038 |
| Capability Anchor Justification | CAP-038 ("First-Party Search Tool (tools::search — GrepTool)") per capabilities-p1-p2.md §CAP-038 — this BC specifies GrepTool's in-process regex semantics, linear-time `regex` crate guarantee, max_results 100 capping, hermetic no-subprocess invariant, PathGuard scope validation, and E-TOOLS-001/008/009 raised error codes (E-TOOLS-006 is a non-raised payload flag: GrepResult.capped) that CAP-038 names as the distinct search surface warranting its own CAP band |
| L2 Domain Invariants | DI-014 (Error Propagation — path violations, invalid patterns, and OS-level I/O errors during traversal all propagate as Err; zero matches returns Ok([]) not Err; capping is non-fatal; E-TOOLS-008 is the carrier for traversal I/O errors — gate #33 reverse anchor: this BC now cites E-TOOLS-008 in PC-6/EC-008/TV-006 matching taxonomy v1.32 forward anchor) |
| Architecture Authority | ADR-020 Decisions 2, 3, 5, and 7 (GrepTool contract, regex dep pin, ReadOnly ActionRisk, E-TOOLS-001/006) |
| Binding Decisions | D23 (first-party tool library scope, SS-23 creation) |
| VP Registration | VP-2.23.006-A/B/C (unit/integration tests) |
| Module | ferrochain-tools / tools::search |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration |
