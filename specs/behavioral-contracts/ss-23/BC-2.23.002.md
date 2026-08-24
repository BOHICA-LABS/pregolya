---
document_type: behavioral-contract
level: L3
bc_id: BC-2.23.002
version: "2.2"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-23
capability: CAP-036
crate: pregolya-tools
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
di_anchors: [DI-014]
vp_seed: false
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 first-party tool library, SS-23 WriteFileTool."
  - "1.1 (burst-233/F-P133-03/2026-07-22): PC-5 / EC-003 / EC-004 / EC-006 / TV-004 — assign E-TOOLS-008 FileIoError to the OS-level I/O error paths (was 'TOOLS, I/O category' with no code). Structured fields: tool_type: 'WriteFileTool', path: <file_path>, io_kind: <ErrorKind debug name>. Gate #33 forward+reverse: E-TOOLS-008 now covers these raise sites; error-taxonomy.md v1.32 anchors BC-2.23.002 in E-TOOLS-008 row."
  - "1.2 (burst-247/F-P146-02/2026-07-24): H1 title — add E-TOOLS-008 to raised-code enumeration per SS-23 title policy (exhaustive RAISED codes only; Ok-path payload flags excluded). Before: trailing 'E-TOOLS-001'. After: 'E-TOOLS-001/008'. TD-VSDD-060: BC-INDEX row and bc-authoring-plan Batch 20 title cell updated same burst (state-manager handles BC-INDEX). input-hash updated 0bc5c5d→64d7571 (inputs unchanged; hash drift from prior burst)."
  - "1.3 (FIX-BURST-270/ADR-010-v1.9/2026-07-25): Apply PascalCase casing canon (ADR-010 v1.9 Direction B) at 2 sites: component: \"TOOLS\" string literal → component: Component::Tools (PC-2 + PC-5); Category::SECURITY → Category::Security (PC-2), Category::TOOL → Category::Tool (PC-5)."
  - "1.4 (F-P173-601/2026-07-27): PathGuard::check phantom-method sweep. Replace invented method name `PathGuard::check(path)` with canonical entry point `canonicalize_beneath_root` at 4 sites: PC-1 happy-path ('passes' → 'succeeds'), PC-2 raise condition ('returns false' → 'returns `Err`'), Invariants call-obligation bullet, VP-2.23.002-A property description. No error-layer-split issues found — E-TOOLS-001 correctly used as tool-layer code throughout."
  - "1.5 (fix-burst-280/F-P175-A25/2026-07-28): Convert 2 struct-literal construction examples to PregolyaError::new() form. PC2 E-TOOLS-001 PathConfinementViolation: ::new(Component::Tools, Category::Security, RetryHint::Never, ...). PC5 E-TOOLS-008 I/O error: ::new(Component::Tools, Category::Tool, RetryHint::Maybe, ...); phantom tool_type/path/io_kind fields removed (message-embedded placeholders). TD-VSDD-060 sibling sweep: EC-003/EC-004/EC-006/TV-004 JSON-like {tool_type, ...} notation classified (c) message-component descriptions; left as-is."
  - "1.6 (fix-burst-287/F-P176-C001/2026-08-01): PC-2 error-routing defect fixed. Prior text routed canonicalize_beneath_root returning Err 'for any reason' to E-TOOLS-001 (SECURITY/Never), conflating OS I/O failures with genuine scope-escape violations. Narrowed to: E-TOOLS-001 applies only when canonicalize_beneath_root returns Err because the resolved canonical path lies outside the guard scope (genuine escape). OS-level I/O failures (e.g., NotFound when parent directory does not exist) route to PC-5 as E-TOOLS-008 FileIoError. Discrimination note added to PC-2 body. EC-003 and TV-004 are already consistent with this rule; no additional edits needed. Same root defect as BC-2.23.001 PC-2."
  - "1.7 (fix-burst-287/ADR-010-C3/2026-08-01): ADR-010 Class 3 notation fix — 2 prose occurrences of PregolyaError::new(...) replaced with observation form. PC-2 E-TOOLS-001: inline → PregolyaError { code: 'E-TOOLS-001', .. }. PC-5 E-TOOLS-008: inline → { code: 'E-TOOLS-008', .. }. verify-error-notation-canon.sh PASS."
  - "1.8 (fix-burst-287/F-P176-C002/ADR-024/2026-08-01): ADR-024 create-path update — close CRIT unreachability defect. PC-1 extended: canonicalize_beneath_root Phase 2 two-phase fallback (ADR-024 Decision 1) enables new-file creation when target does not exist but parent is within scope. PC-2 discrimination rule extended with three genuine-escape conditions per ADR-024 Decision 3: (a) Phase 1 symlink escape on existing file; (b) Phase 2 parent resolves outside workspace; (c) path ends in '..' or is filesystem root (filename=None). traces_to and Architecture Anchors updated to include ADR-024. TOCTOU residual risk LOW per ADR-024 Decision 4; v2 mitigation (rustix openat O_NOFOLLOW) deferred."
  - "1.9 (burst-288/P1D-177-C-H02/2026-08-15): ADR-024 §Phase-2 Postconditions + §Confinement-Proof citation extension — update Architecture Anchors to cite §Phase-2 Postconditions PC-3 (dangling-symlink → PathNotFound → E-TOOLS-008) and PC-4 (Ok-path confinement proof). PC-5 extended: dangling-symlink case (canonicalize_beneath_root Phase 2 step (d) returns Err(SandboxError::PathNotFound)) added as an explicit E-TOOLS-008 route per ADR-024 Decision 3 / PC-3. §Architecture Authority in Traceability updated to reference ADR-024 PC-3 + PC-4."
  - "2.0 (burst-295/F-1-MED/P1D-186/2026-08-16): PC-3 stale brand residue corrected — atomic-write temp-file prefix '.ferroctmp_<random>' → '.pregolyatmp_<random>'. ferroctmp was the ferrochain-era internal token; canonical pregolya atomic-write temp prefix is 'pregolyatmp_'. D-134 ferro-residue sweep: sole live-body occurrence across behavioral-contracts + prd-supplements + domain-spec subtrees."
  - "2.1 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.21 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "2.2 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-036
  - architecture/decisions/ADR-020-first-party-tool-library.md
  - architecture/decisions/ADR-024-writefile-create-path-confinement.md
  - domain-spec/invariants.md#DI-014
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

# BC-2.23.002: WriteFileTool — PathGuard-Confined Atomic Write; High ActionRisk; No Auto-Retry; E-TOOLS-001/008

## Description

`WriteFileTool` in `pregolya-tools::tools::fs` implements the `Tool` trait with
`ActionRisk::High`. It creates or overwrites a file at a caller-supplied path with the
provided content. Before any I/O, the path argument is validated against the configured
`PathGuard` (pregolya-sandbox); paths outside the guard scope return
`Err(E-TOOLS-001 PathConfinementViolation)`. The write is performed atomically: the
implementation writes to a temporary file in the same directory and renames to the target
path, preventing partial-write corruption. `WriteFileTool` is non-idempotent and is NOT
enrolled for automatic retry (ADR-020 Decision 4); re-invocation of a failed write requires
explicit human re-approval via `PreToolCallHook` (ADR-018).

## Preconditions

1. {PRE-001} `WriteFileTool` is constructed with a `PathGuard` instance.
2. {PRE-002} The caller invokes the tool with JSON args `{ "path": "<path-string>", "content": "<content-string>" }`.
3. {PRE-003} `path` is a non-empty string; `content` may be empty (zero-byte file is valid).
4. {PRE-004} `ActionRisk::High` is the annotated risk tier; `RiskGatePolicy` will interrupt before
   execution unless a `PreToolCallHook` explicitly approves (BC-2.05.006, ADR-018).

## Postconditions

1. {PC-001} **Happy path:** `canonicalize_beneath_root(workspace_root, path)` succeeds — either via Phase 1
   (target file already exists; canonical form within scope) or via the Phase 2 two-phase fallback
   (ADR-024 Decision 1: target file does not yet exist but its parent directory exists and is within
   scope) — and the write proceeds. The target file contains exactly the bytes of `content`. For new
   files, Phase 2 resolves the canonical parent and appends the filename; the write then creates the
   file at that confined path. The tool returns `ToolOutput::Text("written: <path>")`.
   Parent directories are NOT created automatically; if the parent directory does not exist,
   `canonicalize_beneath_root` Phase 2 propagates a `NotFound` error for the parent →
   `E-TOOLS-008 FileIoError` (PC-5).
2. {PC-002} **Path confinement violation:** `canonicalize_beneath_root(workspace_root, path)` returns
   `Err(WorkspaceEscape)` for genuine escape conditions (ADR-024 Decision 3):
   - **(Phase 1)** Target file exists but its resolved canonical form lies outside the workspace root
     (symlink target escapes workspace).
   - **(Phase 2)** Target file does not exist; parent directory exists but its canonical form lies
     outside the workspace root.
   - **(Phase 2)** Path ends in `..` or is the filesystem root — `Path::file_name()` returns `None`;
     treated as a traversal attempt.
   The tool returns `Err(PregolyaError { code: "E-TOOLS-001", .. })`.
   No I/O is performed; no temporary file is created. **Discrimination rule (ADR-024 Decision 3):**
   `E-TOOLS-001` is raised exclusively for genuine scope-escape conditions. OS-level I/O failures
   (`NotFound` from a missing parent directory, `PermissionDenied`) are **not** confinement
   violations; they route to PC-5 as `E-TOOLS-008 FileIoError`.
3. {PC-003} **Atomic write semantics:** The implementation writes content to `<path>.pregolyatmp_<random>`
   in the same directory, then performs a rename to `<path>`. If the rename fails, the
   temporary file is removed and the error is propagated. The target file is never left in a
   partial-write state observable by concurrent readers.
4. {PC-004} **Overwrite existing file:** If `path` already exists, it is replaced atomically. No backup
   is created. The caller is responsible for any desired backup semantics.
5. {PC-005} **I/O error:** OS-level I/O failure (disk full, permission denied) propagates as
   `Err(PregolyaError { code: "E-TOOLS-008", .. })`.
   The temporary file is removed on error.
   **Dangling-symlink case (ADR-024 Decision 3 / PC-3):** if `canonicalize_beneath_root`
   Phase 2 step (d) detects that the final path component is a dangling symlink
   (`std::fs::symlink_metadata(joined)` returns `Ok(m)` with `is_symlink() = true`), it
   returns `Err(SandboxError::PathNotFound)`. This is NOT a confinement violation; it is an
   unresolvable-target condition. WriteFileTool propagates this as
   `Err(PregolyaError { code: "E-TOOLS-008", .. })` (same as other I/O failures).

## Invariants

- {INV-001} `canonicalize_beneath_root` is called for EVERY invocation before any filesystem open. No bypass exists.
- {INV-002} Write is always atomic via temp-file + rename. No direct-write code path exists.
- {INV-003} `WriteFileTool` has `retry_eligible: false` — the framework does not auto-retry write
  failures. A failed write followed by a retry requires explicit re-approval by the
  `PreToolCallHook`. This prevents double-write on transient errors.
- {INV-004} **DI-014 (No Silent Swallowing):** I/O errors and path violations propagate as
  `Err(PregolyaError)`. The tool never returns success for a write that did not complete.
- {INV-005} `ActionRisk::High` cannot be lowered below `Medium` by application configuration per
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
| VP-2.23.002-A (VP-003 reuse) | canonicalize_beneath_root called before any filesystem open | Kani proof reused from VP-003 |
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
- `architecture/decisions/ADR-024-writefile-create-path-confinement.md` — Decision 1 (two-phase `canonicalize_beneath_root` for non-existent paths, including step (d) dangling-symlink guard via `symlink_metadata`), Decision 2 (WriteFileTool calling convention unchanged), Decision 3 (error routing table — three genuine-escape conditions + dangling-symlink `Err(SandboxError::PathNotFound)` → E-TOOLS-008), Decision 4 (TOCTOU residual risk LOW), Decision 5 (atomic write compatible); §Phase-2 Postconditions PC-3 (dangling-symlink → `Err(SandboxError::PathNotFound)` — governing authority for PC-5 dangling-symlink routing); PC-4 (Ok-path confinement proof — `canonical_parent.join(filename) ⊆ canonical_base` holds under five soundness invariants; guarantees WriteFileTool write stays within workspace)
- `architecture/module-decomposition.md` — SS-23, `tools::fs` module in pregolya-tools
- `architecture/purity-boundary-map.md` — SS-23 Effectful Shell classification

## Story Anchor

S-1.21

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
| Architecture Authority | ADR-020 Decisions 2, 3, 4, and 5 (WriteFileTool contract, High ActionRisk, retry_eligible: false, E-TOOLS-001); ADR-024 Decisions 1–5 (two-phase `canonicalize_beneath_root`, calling convention, error routing, TOCTOU, atomic write) + §Phase-2 Postconditions PC-3 (dangling-symlink → E-TOOLS-008) and PC-4 (Ok-path confinement proof) |
| Binding Decisions | D23 (first-party tool library scope, SS-23 creation) |
| VP Registration | VP-003 reuse; VP-2.23.002-B/C (unit tests) |
| Module | pregolya-tools / tools::fs |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration |
