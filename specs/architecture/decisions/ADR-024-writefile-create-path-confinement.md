---
document_type: adr
level: L3
adr_id: "024"
slug: writefile-create-path-confinement
title: "WriteFileTool Create-Path Confinement Protocol: Parent-Canonicalize Extension, TOCTOU Analysis, and Error Routing (fix-burst-287 / F-P176-C002)"
status: accepted
producer: architect
timestamp: 2026-08-01T00:00:00Z
version: "1.0"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D23]
changelog:
  - "1.0 (fix-burst-287/F-P176-C002/2026-08-01): Initial decision — close CRIT unreachability defect in WriteFileTool create-path. Product-owner confirmed no exists-check pre-guard in SS-23; architect adjudication of parent-canonicalize protocol, TOCTOU window, and error routing. Prerequisite to product-owner BC-2.23.002 update."
---

# ADR-024: WriteFileTool Create-Path Confinement Protocol

**Status:** Accepted — fix-burst-287 architect adjudication of F-P176-C002 (CRIT) from P1D-176.

---

## Context

`canonicalize_beneath_root(base, requested)` is the path-confinement security function for all
workspace file operations. Its current implementation (per BC-2.13.004) calls
`std::fs::canonicalize(base.join(requested))`, which returns `Err(NotFound)` for paths that do
not yet exist. Consequence: WriteFileTool's primary use case — creating a new file — is
structurally unreachable. When WriteFileTool calls `canonicalize_beneath_root` on a new file's
path, the function returns `NotFound`, which under BC-2.23.002 PC-2's discrimination rule routes
to `E-TOOLS-008 FileIoError`. Every new-file creation attempt exits before reaching the write
operation.

BC-2.13.004 EC-004 already specifies the CORRECT protocol for new-file creation: "parent
directory is canonicalized; parent must be beneath root; if parent OK, append filename and
proceed." This protocol is documented as a postcondition of `canonicalize_beneath_root` but is
absent from the function's implementation path as described in BC-2.13.004 §Description. The
protocol is also absent from BC-2.23.002's documented entry points: PC-1 through PC-6 all
assume `canonicalize_beneath_root` succeeds for the full path.

Product-owner confirmed (fix-burst-287 coordinator message): no BC in SS-23 defines an
`exists: false` pre-check or an alternate entry point for create-path before
`canonicalize_beneath_root`. The unreachability is structural, not a wording gap.

---

## Decision 1 — Extend `canonicalize_beneath_root` to handle non-existent target paths

`canonicalize_beneath_root(base: &Path, requested: &Path)` MUST be extended to handle the case
where the target path does not yet exist. The extension implements a two-phase protocol:

**Phase 1 (existing behavior — happy path):**
1. Compute `joined = base.join(requested)`.
2. Call `std::fs::canonicalize(joined)` → `canonical`.
3. Check: `canonical.starts_with(canonical_base)`. If yes, return `Ok(canonical)`.
4. If no: return `Err(E-SBXD-001: WorkspaceEscape)`.

**Phase 2 (new — non-existent target fallback, triggered ONLY on `ErrorKind::NotFound`):**
5. If step 2 returns `Err(e)` where `e.kind() == io::ErrorKind::NotFound`:
   a. Extract `parent = joined.parent()`.
   b. Extract `filename = joined.file_name()`.
   c. If `filename` is `None` (path ends in `..` or is the root): return `Err(E-SBXD-001: WorkspaceEscape)` — path traversal attempt; do not proceed.
   d. Call `std::fs::canonicalize(parent)` → `canonical_parent`.
   e. If `canonical_parent` call returns `Err`: propagate as-is (parent directory does not exist or is inaccessible).
   f. Check: `canonical_parent.starts_with(canonical_base)`. If no: return `Err(E-SBXD-001: WorkspaceEscape)`.
   g. Return `Ok(canonical_parent.join(filename))`.
6. If step 2 returns `Err(e)` where `e.kind() != NotFound` (e.g., `PermissionDenied`): propagate as-is. Do NOT attempt parent-canonicalize.

**Why phase 2 is confined:**
- `canonical_parent` is the output of `std::fs::canonicalize` — it contains no symlink components and no `..` components.
- `filename` is the last path component as returned by `Path::file_name()`. This function returns `None` for paths ending in `..`; it never returns a string containing a path separator. A bare filename component cannot escape a confirmed canonical parent.
- Therefore `canonical_parent.join(filename)` is always beneath `canonical_parent`, which is itself beneath `canonical_base`. The confinement guarantee is preserved.

**Purity boundary:** The extended `canonicalize_beneath_root` remains in `pregolya-sandbox`,
which is the Pure Core security module. The extension adds no new external I/O beyond the
existing filesystem contact. The Kani harness (VP-003, BC-2.17.001) must be updated in Phase 6
to cover the two-phase path.

---

## Decision 2 — Create intent: WriteFileTool calling convention unchanged

WriteFileTool continues to call `canonicalize_beneath_root(workspace_root, path)` with the full
target path. After Decision 1's extension:

- If the path already exists: Phase 1 resolves it. Existing behavior unchanged.
- If the path does not exist but the parent exists and is within scope: Phase 2 resolves the
  parent → returns `Ok(canonical_parent.join(filename))` → WriteFileTool proceeds.
- If the path does not exist and the parent is outside the workspace root: Phase 2's step (f)
  catches the escape → `E-SBXD-001 WorkspaceEscape` → WriteFileTool translates to `E-TOOLS-001`.
- If the path does not exist and the parent does not exist: Phase 2 step (e) propagates the
  `NotFound` from the parent → WriteFileTool routes to `E-TOOLS-008 FileIoError`.

WriteFileTool does NOT need a separate "create mode" parameter or a pre-existence check. The
discrimination is internal to `canonicalize_beneath_root`.

**ReadFileTool and EditFileTool:** These tools do not create files. For them, `NotFound`
indicates that the target file does not exist and the operation cannot proceed. After Decision 1:
- Phase 2 runs (the parent may exist and be within scope).
- `Ok(canonical_parent.join(filename))` is returned.
- ReadFileTool / EditFileTool then attempt to open the file → receive `NotFound` from the OS
  at open time → propagate as `E-TOOLS-008 FileIoError`.

This behavior is correct: the path is validly confined but the file doesn't exist. E-TOOLS-008
is the right error. No change to ReadFileTool or EditFileTool calling conventions is required.

---

## Decision 3 — Error routing for the create path

The following error routing table replaces BC-2.23.002's implicit handling after Decision 1 is
implemented. Product-owner applies this to BC-2.23.002 PC-1 through PC-5.

| Scenario | `canonicalize_beneath_root` returns | WriteFileTool raises |
|----------|-------------------------------------|----------------------|
| Path exists, within scope | `Ok(canonical_path)` | Proceeds to write |
| Path exists, escapes workspace (symlink) | `Err(WorkspaceEscape)` | `E-TOOLS-001 PathConfinementViolation` |
| Path does not exist; parent exists, within scope | `Ok(canonical_parent.join(filename))` | Proceeds to create |
| Path does not exist; parent exists, escapes workspace | `Err(WorkspaceEscape)` | `E-TOOLS-001 PathConfinementViolation` |
| Path does not exist; parent does not exist | `Err(NotFound from parent)` | `E-TOOLS-008 FileIoError` (io_kind: "NotFound") |
| Path ends in `..` or is root | `Err(WorkspaceEscape)` | `E-TOOLS-001 PathConfinementViolation` |
| PermissionDenied or other I/O error | `Err(PermissionDenied)` | `E-TOOLS-008 FileIoError` |

**Key invariant:** `E-TOOLS-001` is raised exclusively for genuine scope-escape conditions
(resolved canonical path is outside the workspace root). `NotFound` (path does not exist) is
never a confinement violation; it routes to E-TOOLS-008. This is consistent with the C001
discrimination rule already in BC-2.23.001 and BC-2.23.002.

---

## Decision 4 — TOCTOU residual risk and v2 mitigation path

**Window definition:** The TOCTOU window exists between:
- T1: `std::fs::canonicalize(parent)` in Phase 2 — resolves parent's canonical path.
- T2: The OS `open(canonical_parent.join(filename), O_CREAT)` call in the atomic write.

Between T1 and T2, an attacker could: (a) remove the real directory at `canonical_parent`, (b)
create a symlink at `canonical_parent` pointing to a directory outside the workspace. A write to
`canonical_parent/filename` would then follow the symlink and create a file outside the workspace.

**Severity assessment: LOW for standard deployment.** The attack requires all of:
1. Write access to `canonical_parent`'s parent directory (to delete the real dir and create symlink).
2. The workspace is shared with a concurrent process capable of this operation.
3. Millisecond-level timing precision between T1 and T2.

Standard pregolya deployment: the workspace directory is owned by the LLM agent process; no
external untrusted process has write access to workspace parent directories during tool
execution. The TOCTOU window is operationally unreachable in standard deployments.

**Symlinked parents:** If `parent` itself is a symlink at T1, `std::fs::canonicalize(parent)`
follows the symlink and returns the physical canonical path of the symlink target. The
confinement check at step (f) evaluates the CANONICAL parent (target of the symlink), not the
symlink itself. A symlinked parent is therefore handled correctly:
- Symlink target within workspace → Phase 2 returns `Ok`; write goes to the real directory.
- Symlink target outside workspace → WorkspaceEscape; write is rejected.

**v1 (this ADR):** Document the TOCTOU window as a known residual risk with LOW severity for
standard deployment. No additional mitigation beyond what `canonicalize_beneath_root` provides
in Phase 1 (resolving `..` and symlinks at the full path level).

**v2 mitigation (deferred):** Replace `std::fs::write` with `openat(parent_fd, filename, O_CREAT
| O_NOFOLLOW)` via `rustix`, where `parent_fd` is a file descriptor held open from T1 through
T2. A held file descriptor binds to the actual directory inode (not the path), making symlink
injection physically impossible regardless of filesystem state between T1 and T2. Trigger
condition for v2: threat model evidence that workspace directories are shared with untrusted
processes, or a dedicated security audit finding that classifies the TOCTOU window as HIGH.

---

## Decision 5 — Atomic write interaction with confinement

The atomic write protocol in BC-2.23.002 (write to `<path>.ferroctmp_<random>`, rename to
`<path>`) is compatible with Decision 1. After Phase 2 resolves `canonical_path`:

- Temp file: `canonical_parent.join(format!(".ferroctmp_{}", random_suffix))` — within the
  canonicalized parent, beneath workspace root.
- Write temp file at `canonical_parent.join(".ferroctmp_<N>")` → same confinement guarantee.
- Rename to `canonical_path = canonical_parent.join(filename)` — same directory, same scope.
- If rename fails: remove temp file. No file outside workspace root is ever created.

No additional confinement check is required after the atomic write. The canonical path is
resolved once (Decision 1) and used for all subsequent I/O operations in the same tool
invocation.

---

## Rationale

The parent-canonicalize approach is preferred over alternatives for three reasons:

1. **Centralization.** All security logic stays in `canonicalize_beneath_root` (Pure Core,
   `pregolya-sandbox`). Every tool benefits automatically. The alternative — each tool
   independently detecting NotFound and calling a separate `create_confinement_check` — spreads
   security logic across multiple tools and increases the surface for divergence.

2. **BC-2.13.004 alignment.** EC-004 already specifies the parent-canonicalize protocol as
   the expected behavior for the non-existent-path case. Decision 1 is an implementation of
   what EC-004 describes. The alternative — a separate `canonicalize_beneath_root_for_create`
   entry point — would fragment the security surface without specification benefit.

3. **Formal-verification tractability.** A single function with a well-defined two-phase
   protocol is provable by Kani (VP-003 extension). A per-tool create-mode check would require
   separate proof harnesses for each tool.

---

## Consequences

- Product-owner MUST update BC-2.23.002 to describe the create-path behavior: PC-1 happy path
  now includes new-file creation (parent exists, within scope). The "parent directories NOT
  created automatically" note in PC-1 remains correct — if the PARENT doesn't exist, E-TOOLS-008
  is returned.
- Product-owner MAY update BC-2.13.004 §Description to clarify that `canonicalize_beneath_root`
  implements the two-phase protocol internally for non-existent paths, consistent with EC-004.
- The Phase 3 implementer extends `sandbox::path_guard::canonicalize_beneath_root` with Phase 2
  logic per Decision 1.
- VP-003 Kani harness must be extended in Phase 6 to cover the two-phase protocol. The harness
  should include: (a) new-file path with valid parent, (b) new-file path with parent escaping
  workspace, (c) path ending in `..` (filename = None case).
- The v2 TOCTOU mitigation (`rustix` + `openat` + `O_NOFOLLOW`) is deferred; trigger condition
  is documented in Decision 4.

---

## Source / Origin

- **F-P176-C002** (CRIT): WriteFileTool create-path structurally unreachable — `canonicalize_beneath_root` cannot return `Ok` for a not-yet-existing path.
- **BC-2.13.004 EC-004**: "Write to a new file that does not yet exist — Parent directory is canonicalized; parent must be beneath root; if parent OK, append filename and proceed." Authority for the parent-canonicalize protocol.
- **BC-2.23.002 §PC-2**: C001 discrimination rule (E-TOOLS-001 for genuine escapes, E-TOOLS-008 for OS I/O failures). This ADR extends that rule to the create-path case.
- **DI-007**: Workspace Path Confinement — the invariant that `canonicalize_beneath_root` upholds.
- **VP-003** (BC-2.17.001): Kani harness — Phase 6 formal proof of workspace confinement; must be extended to cover the two-phase protocol.
