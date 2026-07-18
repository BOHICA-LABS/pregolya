---
document_type: behavioral-contract
level: L3
bc_id: BC-2.13.005
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "619429b"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-13
capability: CAP-015
lifecycle_status: active
introduced: v1.0.0-greenfield
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

# BC-2.13.005: Symlink That Escapes Workspace Root Returns Err(WorkspaceEscape)

## Description

A symlink that lives inside the workspace directory but whose target resolves to a path
outside the workspace root must return `Err(E-SBXD-001: WorkspaceEscape)` when accessed
through any workspace file operation. This is the specific attack vector that adk-rust P-65's
string-only `validate_relative_path` fails to detect — the path `/workspace/escape_link`
passes string-depth validation because it contains no `..` segments, yet following the symlink
reveals `/etc/passwd`. ferrochain's `canonicalize_beneath_root` (BC-2.13.004) catches this by
calling `std::fs::canonicalize()` which follows symlinks at the OS level before the prefix check.
This BC directly covers domain edge case DEC-011.

## Preconditions

1. A workspace root `/workspace` exists with a canonical path
2. A symlink exists at a path inside the workspace (e.g., `/workspace/escape_link`) whose
   target is outside the workspace root (e.g., `/etc/passwd`, `~/.ssh/id_rsa`,
   `~/.aws/credentials`)
3. A tool or internal API requests a file operation on the symlink path via the `WorkspaceFs`
   facade

## Postconditions

1. `canonicalize_beneath_root(workspace_root, "/workspace/escape_link")` calls
   `std::fs::canonicalize("/workspace/escape_link")`
2. `canonicalize` returns the resolved target (e.g., `/etc/passwd`)
3. The resolved path does NOT have `/workspace` as a prefix
4. `canonicalize_beneath_root` returns
   `Err(E-SBXD-001: WorkspaceEscape { requested: "/workspace/escape_link", resolved: "/etc/passwd", root: "/workspace" })`
5. The file is NOT read, written, or otherwise accessed — zero bytes of the target file are
   observed

## Invariants

1. Symlink resolution happens via OS-level `canonicalize` — no string analysis of the symlink
   path itself determines the outcome
2. `WorkspaceEscape` carries three fields: `requested` (the path the caller provided),
   `resolved` (the canonical target path after symlink resolution), and `root` (the workspace
   root) — enabling precise audit logging
3. There is no "follow symlinks outside root" opt-in for workspace file operations —
   escape detection is unconditional
4. Symlinks whose targets remain within the workspace root are allowed (access proceeds with
   the canonical resolved path)
5. adk-rust reference sparsity: P-65 is the explicit counter-example; no positive upstream
   reference — greenfield behavior derived from NE-02 and DI-007

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Symlink at `/workspace/internal_link` points to `/workspace/subdir/file.txt` (within root) | `canonicalize` resolves to `/workspace/subdir/file.txt`; beneath root; `Ok(resolved_path)` — internal symlinks are permitted |
| EC-002 | Chained symlinks: `/workspace/link_a → /workspace/link_b → /etc/passwd` | `canonicalize` follows the full chain; resolves to `/etc/passwd`; `Err(E-SBXD-001: WorkspaceEscape)` |
| EC-003 | Dangling symlink: target path does not exist | `std::fs::canonicalize` returns `IoError::NotFound`; propagated as `Err(SandboxError::PathNotFound)` — not a workspace escape error |
| EC-004 | Relative symlink: `/workspace/rel_link → ../etc/passwd` | `canonicalize` resolves relative to the symlink's parent directory (`/workspace`), yielding `/etc/passwd`; `Err(E-SBXD-001: WorkspaceEscape)` |
| EC-005 | Symlink to a directory outside root: `/workspace/etc_dir → /etc` | `canonicalize` resolves to `/etc`; not beneath root; `Err(E-SBXD-001: WorkspaceEscape)` — directory symlinks are subject to the same check |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `canonicalize_beneath_root("/workspace", "/workspace/escape_link")` where `escape_link → /etc/passwd` | `Err(E-SBXD-001: WorkspaceEscape { requested: "/workspace/escape_link", resolved: "/etc/passwd", root: "/workspace" })` | DEC-011 (domain edge case) |
| `canonicalize_beneath_root("/workspace", "/workspace/internal_link")` where `internal_link → /workspace/subdir/file` | `Ok(PathBuf::from("/workspace/subdir/file"))` | happy-path (internal symlink) |
| `canonicalize_beneath_root("/workspace", "/workspace/link_a")` where chain resolves to `/etc/passwd` | `Err(E-SBXD-001: WorkspaceEscape { resolved: "/etc/passwd" })` | edge-case (chained symlinks) |
| `canonicalize_beneath_root("/workspace", "/workspace/dangling_link")` where target missing | `Err(SandboxError::PathNotFound)` | edge-case (dangling symlink — not an escape error) |
| `canonicalize_beneath_root("/workspace", "/workspace/rel_escape")` where `rel_escape → ../etc/passwd` | `Err(E-SBXD-001: WorkspaceEscape { resolved: "/etc/passwd" })` | edge-case (relative symlink escape) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|--------------|
| VP-2.13.005-A | A symlink inside the workspace that resolves outside the root returns `Err(E-SBXD-001: WorkspaceEscape)` and does not cause a file read or write | integration test — create escape symlink in test workspace; assert Err and zero file accesses |
| VP-2.13.005-B | A symlink inside the workspace that resolves to another path inside the root returns `Ok(resolved_path)` and the file operation proceeds | unit test — internal symlink happy-path |
| VP-2.13.005-C | `WorkspaceEscape` error carries `requested`, `resolved`, and `root` fields | unit test — error struct field inspection |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-015 |
| Capability Anchor Justification | CAP-015 ("Sandboxed Tool Execution (Enforcing Backend Default)") per capabilities-p1-p2.md §CAP-015 |
| L2 Domain Invariants | DI-007 (Workspace Path Confinement) |
| Source Analysis | P-65 NOT-APPLICABLE (must-not-inherit: `validate_relative_path` string-only — permits symlink escapes); NE-02 (ferrochain requirement: canonical real-path check); DEC-011 (domain edge case: Workspace Symlink Escape); assessment-parts/part-3 §NE-02 |
| Reference Evidence | adk-rust P-65: `validate_relative_path` never calls `canonicalize`, never resolves symlinks — ferrochain INVERTS this. DEC-011 in edge-cases.md documents this exact scenario. No positive upstream reference — greenfield. |
| Binding Decisions | NE-02, DI-007 |
| Forcing Functions | DEC-011 ("Workspace Symlink Escape" domain edge case); product-brief.md §NE catalog NE-02 |
| Architecture Module | ferrochain-sandbox / WorkspaceFs facade (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.13.004 — depends on: symlink escape detection is a consequence of the access-time canonicalization mandated by BC-2.13.004; this BC specifies the specific escape scenario
- BC-2.17.001 — VP seed: the Kani harness for workspace confinement (Phase 6) covers this symlink scenario as one of its proof obligations

## Architecture Anchors

- `architecture/ferrochain-sandbox.md` — `canonicalize_beneath_root` implementation and `E-SBXD-001: WorkspaceEscape` error type (filled by architect)

## Story Anchor

S-N.MM — Symlink escape detection in WorkspaceFs (filled by story-writer)

## VP Anchors

- VP-2.13.005-A — Escape symlink → Err + zero file accesses (integration test)
- VP-2.13.005-B — Internal symlink → Ok (unit test)
- VP-2.13.005-C — WorkspaceEscape error fields (unit test)
