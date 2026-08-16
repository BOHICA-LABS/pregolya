---
document_type: adr
level: L3
adr_id: "024"
slug: writefile-create-path-confinement
title: "WriteFileTool Create-Path Confinement Protocol: Parent-Canonicalize Extension, TOCTOU Analysis, and Error Routing (fix-burst-287 / F-P176-C002)"
status: accepted
date: 2026-08-15
producer: architect
timestamp: 2026-08-01T00:00:00Z
version: "1.1"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D23]
subsystems_affected: [SS-13, SS-23]
supersedes: null
superseded_by: null
changelog:
  - "1.1 (burst-288/P1D-177-C01+C02+C-H01/2026-08-15): Confinement-proof redesign (C-02): redesigned §Decision 1 Phase 2 to add dangling-symlink guard (step d), relabeled Phase 2 steps as a-h; added §Confinement-Proof with full attack-surface catalog AS-01..AS-09 and soundness argument replacing unsound bare-filename claim. Dangling-symlink authoritative decision (C-01): Phase 2 step (d) returns Err(SandboxError::PathNotFound) for dangling-target symlinks, resolving contradiction with BC-2.13.005 §EC-003; §Phase-2 Postconditions PC-3 is the authoritative cross-reference anchor. Phase-2 postconditions (C-H01): authored PC-1 through PC-5 as formal postconditions in new §Phase-2 Postconditions section. Added §Consumers enumerating all six BCs that must cite this ADR: BC-2.13.004, BC-2.13.005, BC-2.23.001, BC-2.23.003, BC-2.23.004, BC-2.23.006 (propagation owner: product-owner per C-H02); PC-5 applicability confirmed for BC-2.23.004 (ListDirTool) and BC-2.23.006 (GrepTool) in burst-288 follow-up."
  - "1.0 (fix-burst-287/F-P176-C002/2026-08-01): Initial decision — close CRIT unreachability defect in WriteFileTool create-path. Product-owner confirmed no exists-check pre-guard in SS-23; architect adjudication of parent-canonicalize protocol, TOCTOU window, and error routing. Prerequisite to product-owner BC-2.23.002 update."
---

# ADR-024: WriteFileTool Create-Path Confinement Protocol

**Status:** Accepted — fix-burst-287 architect adjudication of F-P176-C002 (CRIT) from P1D-176.
Amended in burst-288 (P1D-177 C-01 / C-02 / C-H01): dangling-symlink soundness fix, confinement
proof redesign, Phase-2 postconditions PC-1..PC-5.

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
   c. If `filename` is `None` (path ends in `..` or is the root): return
      `Err(E-SBXD-001: WorkspaceEscape)` — path traversal attempt; do not proceed.
   d. Call `std::fs::symlink_metadata(joined)`. If `Ok(m)` where `m.file_type().is_symlink()`
      is `true`: `joined` is a dangling symlink (the symlink entry exists but its target is
      absent). Return `Err(SandboxError::PathNotFound)`. Do NOT proceed to parent-canonicalize.
      Rationale: writing to a dangling symlink follows the symlink to a target whose location
      cannot be verified against the workspace root; confinement cannot be established. See
      §Phase-2 Postconditions PC-3 and BC-2.13.005 §EC-003 for the authoritative behavior.
   e. Call `std::fs::canonicalize(parent)` → `canonical_parent`.
   f. If step (e) returns `Err`: propagate as-is (parent directory does not exist or is
      inaccessible).
   g. Check: `canonical_parent.starts_with(canonical_base)`. If no: return
      `Err(E-SBXD-001: WorkspaceEscape)`.
   h. Return `Ok(canonical_parent.join(filename))`.
6. If step 2 returns `Err(e)` where `e.kind() != NotFound` (e.g., `PermissionDenied`):
   propagate as-is. Do NOT attempt parent-canonicalize.

**Purity boundary:** The extended `canonicalize_beneath_root` remains in `pregolya-sandbox`,
which is the Pure Core security module. The extension adds no new external I/O beyond the
existing filesystem contact. The Kani harness (VP-003, BC-2.17.001) must be extended in Phase 6
to cover the two-phase path including step (d)'s dangling-symlink guard.

---

## Confinement Proof — Phase 2

This section proves that Phase 2 is sound: for every `requested` input, Phase 2 either returns
`Err` or returns `Ok(path)` where `path` is strictly beneath `canonical_base`. The proof covers
the full attack surface (per L-170: a closed-but-incomplete probe set is itself a false-clean
generator). Every attack shape identified in P1D-177 Orchestrator Adjudication is addressed.

### Attack Surface Catalog

| ID | Shape | Covering step | Outcome |
|----|-------|---------------|---------|
| AS-01 | Path traversal — `requested` contains `../` that escapes root (e.g., `../../etc/passwd`) | Step (e): `canonicalize(parent)` resolves to an out-of-root path; step (g): WorkspaceEscape | Rejected: E-SBXD-001 |
| AS-02 | Absolute path outside root — `requested = "/etc/passwd"` (Unix); `base.join("/etc/passwd")` = `/etc/passwd` (absolute join replaces base) | Phase 1 catches this: if `/etc/passwd` exists, `canonicalize` succeeds, prefix check fails → WorkspaceEscape from Phase 1. If it does not exist, Phase 2 step (e) canonicalizes parent `/etc` → not beneath root → WorkspaceEscape from step (g) | Rejected: Phase 1 (exists) or step (g) (not exists) |
| AS-03 | Trailing `..` — `requested` ends in `..` so `file_name()` returns `None` | Step (c): `filename` is None → WorkspaceEscape | Rejected: E-SBXD-001 |
| AS-04 | Symlinked parent directory — the parent component of `requested` is a symlink to a directory outside the workspace root | Step (e): `std::fs::canonicalize(parent)` follows the full symlink chain of the parent; step (g): canonical parent outside root → WorkspaceEscape | Rejected: E-SBXD-001 |
| AS-05 | Separator in filename component — attacker embeds a path separator in what appears to be a filename | `Path::file_name()` on Rust/Unix returns `None` for paths ending with a separator, and returns only the final path component (which by OS segment parsing contains no separator character). A multi-component `requested` is handled by Phase 1 or by the parent extraction path in Phase 2; the separator never appears in `filename` | Not exploitable |
| AS-06 | Dangling-target symlink — `joined` is a symlink entry at the filesystem level whose target path does not exist (directly or via a chain) | Step (d): `std::fs::symlink_metadata(joined)` does NOT follow symlinks; it returns `Ok(m)` for the symlink entry itself. `m.file_type().is_symlink()` is `true` → Err(SandboxError::PathNotFound). Phase 2 does NOT proceed to parent-canonicalize | Rejected: PathNotFound |
| AS-07 | Symlink-to-symlink chain with absent final target — `A → B → nonexistent` | Step (d): `symlink_metadata(joined)` on the first link `A` detects `is_symlink() = true` → PathNotFound. The chain is never followed by Phase 2 | Rejected: PathNotFound |
| AS-08 | TOCTOU — attacker replaces `canonical_parent` with an out-of-root symlink between step (e) and the OS `open(O_CREAT)` call in WriteFileTool | Decision 4 addresses this residual risk. Standard deployment: workspace directories are owned by the LLM agent process; no untrusted concurrent process has write access to workspace parent directories. Severity: LOW | Residual risk — see Decision 4 |
| AS-09 | Non-canonical join result — `canonical_parent.join(filename)` where `filename` is a dangling symlink entry | Eliminated by AS-06: step (d) returns PathNotFound before reaching step (h) whenever `joined` (= `canonical_parent.join(filename)` after extraction) is a symlink | Not reachable after step (d) |

### Soundness Argument for Step (h) Return

When execution reaches step (h), the following invariants hold simultaneously:

1. **`canonical_parent` is beneath `canonical_base`:** established by step (g)'s
   `starts_with` check on the output of `std::fs::canonicalize(parent)`.

2. **`canonical_parent` contains no symlink or `..` components:** it is the verbatim output
   of `std::fs::canonicalize`, which resolves all symlinks and `..` before returning.

3. **`filename` contains no path separator:** guaranteed by `Path::file_name()` semantics
   on Rust/Unix (AS-05 analysis above).

4. **`filename` is not `..`:** step (c) returns WorkspaceEscape for any `joined` whose
   `file_name()` is `None`, which includes all paths ending in `..` (AS-03).

5. **The entry at `joined` is not a dangling symlink:** step (d) returns PathNotFound for
   any `joined` where `symlink_metadata` reports `is_symlink() = true`. At step (h), the
   entry at `joined` either does not exist as any filesystem entry (new-file case), or
   exists as a non-symlink entry (AS-06, AS-07).

**Conclusion:** `canonical_parent.join(filename)` is a path within a directory that is
provably beneath `canonical_base`, where the filename component is not a symlink, not `..`,
and contains no separator. The join is confined to `canonical_base` or its subtree.
This proof is the formal basis for the Phase-6 Kani harness (VP-003) covering Phase 2 of
`canonicalize_beneath_root`.

---

## Phase-2 Postconditions

These postconditions are guaranteed by the Phase 2 protocol defined in Decision 1 for every
caller of `canonicalize_beneath_root`. They govern implementation correctness and are the
formal specification targets for the VP-003 Kani harness.

**PC-1** — If Phase 2 returns `Err(E-SBXD-001: WorkspaceEscape)`, then either:
(a) `file_name()` on `joined` returned `None` — the path ends in `..` or refers to the
filesystem root (step c), or (b) `canonical_parent` as returned by `canonicalize(parent)`
does not have `canonical_base` as a prefix — the parent directory escapes the workspace
(step g). No filesystem write or read beyond the canonicalization calls in steps (d) and (e)
has occurred.

**PC-2** — If Phase 2 returns `Err(e)` due to `canonicalize(parent)` failure (step f), then
the parent directory does not exist or is inaccessible at the time of the call. The error `e`
is the raw `io::Error` from the OS call, propagated without wrapping. No filesystem write has
occurred. Callers receiving this error must route to `E-TOOLS-008 FileIoError`
(`io_kind: "NotFound"` when the parent is missing).

**PC-3** — If Phase 2 returns `Err(SandboxError::PathNotFound)`, then step (d)'s
`std::fs::symlink_metadata(joined)` returned `Ok(m)` where `m.file_type().is_symlink()` is
`true`: the final component of `joined` is a dangling symlink (the symlink entry exists at
the filesystem level; its target does not). Writing to `joined` would follow the symlink to
a target location that cannot be verified against the workspace root at call time; confinement
cannot be established, so the operation is rejected.

> **Authoritative behavior decision for C-01 (P1D-177):** A dangling-target symlink at the
> final path component MUST cause Phase 2 to return `Err(SandboxError::PathNotFound)`. This
> is the authoritative decision resolving the contradiction between ADR-024 §Phase-2-Fallback
> (v1.0, which returned `Ok` on `ErrorKind::NotFound`) and BC-2.13.005 §EC-003 (which requires
> `Err(SandboxError::PathNotFound)` for a dangling symlink). The resolution: `ErrorKind::NotFound`
> from Phase 1 is the *activation condition* for Phase 2, not the error code to surface to
> callers. Step (d)'s dangling-symlink guard intercepts the dangling-symlink sub-case before
> reaching parent-canonicalize and emits `PathNotFound` directly. The non-symlink new-file case
> continues through step (e) as before.
>
> **BC alignment obligation:** BC-2.13.005 §EC-003 must be updated by the product-owner to cite
> this ADR as the governing authority for the dangling-symlink error code decision and to confirm
> its `Err(SandboxError::PathNotFound)` verdict is consistent with PC-3 above.

**PC-4** — If Phase 2 returns `Ok(path)`, then `path = canonical_parent.join(filename)` where
all five soundness invariants in §Confinement-Proof hold simultaneously:
(a) `canonical_parent` is beneath `canonical_base` (step g);
(b) `canonical_parent` is a fully-canonicalized path with no symlink or `..` components;
(c) `filename` contains no path separator;
(d) `filename` is not `..`;
(e) the entry at `joined` is not a dangling symlink (step d eliminates this case).

Under these five invariants, `canonical_parent.join(filename) ⊆ canonical_base` holds
unconditionally, satisfying DI-007 (Workspace Path Confinement) and the property asserted
by VP-003 (BC-2.17.001 §no-path-escapes-sandbox-root).

**PC-5** — The `Ok(path)` returned by Phase 2 is NOT a fully-canonical path: the final
`filename` component was not passed through `canonicalize` and may not yet exist as a
filesystem entry. Callers MUST treat this path as a *creation target* only. Specifically:

- **WriteFileTool:** correct — uses `path` as the atomic-write destination; the temp file
  and final rename land within `canonical_parent` (see Decision 5).
- **ReadFileTool / EditFileTool:** these tools receive `Ok(path)` from Phase 2 when the
  requested file does not yet exist; the subsequent OS open call will return `NotFound`,
  which must be propagated as `E-TOOLS-008 FileIoError`. This behavior is correct and
  expected — the path is confined but the file does not exist.

Callers MUST NOT assume that receiving `Ok(path)` from `canonicalize_beneath_root` implies
the file at `path` already exists on disk.

---

## Decision 2 — Create intent: WriteFileTool calling convention unchanged

WriteFileTool continues to call `canonicalize_beneath_root(workspace_root, path)` with the full
target path. After Decision 1's extension:

- If the path already exists: Phase 1 resolves it. Existing behavior unchanged.
- If the path does not exist but the parent exists and is within scope: Phase 2 resolves the
  parent → returns `Ok(canonical_parent.join(filename))` → WriteFileTool proceeds.
- If the path does not exist and the parent is outside the workspace root: Phase 2's step (g)
  catches the escape → `E-SBXD-001 WorkspaceEscape` → WriteFileTool translates to `E-TOOLS-001`.
- If the path does not exist and the parent does not exist: Phase 2 step (f) propagates the
  `NotFound` from the parent → WriteFileTool routes to `E-TOOLS-008 FileIoError`.
- If the final path component is a dangling symlink: Phase 2 step (d) returns
  `Err(SandboxError::PathNotFound)` → WriteFileTool routes to `E-TOOLS-008 FileIoError`.

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
| Final component is a dangling symlink | `Err(SandboxError::PathNotFound)` | `E-TOOLS-008 FileIoError` |
| PermissionDenied or other I/O error | `Err(PermissionDenied)` | `E-TOOLS-008 FileIoError` |

**Key invariant:** `E-TOOLS-001` is raised exclusively for genuine scope-escape conditions
(resolved canonical path is outside the workspace root). `NotFound` (path does not exist) is
never a confinement violation; it routes to E-TOOLS-008. A dangling symlink is similarly not
a confinement violation — it is an unresolvable-target condition — and routes to E-TOOLS-008.
This is consistent with the C001 discrimination rule already in BC-2.23.001 and BC-2.23.002.

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
confinement check at step (g) evaluates the CANONICAL parent (target of the symlink), not the
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

## Consumers — BCs That Must Cite This ADR

The following behavioral contracts govern code that calls or depends on the two-phase
`canonicalize_beneath_root` protocol defined in this ADR. Each MUST carry a traceability
reference to ADR-024 so that changes to this ADR trigger review of the consuming contracts.

| BC | Role | Required Citation Status |
|----|------|--------------------------|
| BC-2.13.004 | Implements `canonicalize_beneath_root`; §EC-004 is the source authority for Phase 2 semantics | MISSING — must add ADR-024 to §Traceability §Binding Decisions |
| BC-2.13.005 | §EC-003 (dangling symlink → PathNotFound) is the cross-reference anchor for PC-3 | MISSING — must add ADR-024 to §Traceability §Binding Decisions; EC-003 must confirm alignment with PC-3 |
| BC-2.23.002 | WriteFileTool — primary consumer of Phase 2 create-path semantics | Present |
| BC-2.23.003 | EditFileTool — Phase 2 runs when path does not exist; PC-5 explains the Ok-then-NotFound-at-open sequence | MISSING — must reference ADR-024 §Phase-2 Postconditions PC-5 |
| BC-2.23.001 | ReadFileTool — same Phase 2 Ok-then-NotFound pattern as EditFileTool | MISSING — must reference ADR-024 §Phase-2 Postconditions PC-5 |
| BC-2.23.004 | ListDirTool — calls `canonicalize_beneath_root` for the directory path; if path does not exist, Phase 2 returns `Ok(path)`, then `fs::read_dir` returns `NotFound` → E-TOOLS-008 (EC-005). Identical Ok-then-NotFound-at-OS-call pattern as ReadFileTool/EditFileTool | MISSING — must reference ADR-024 §Phase-2 Postconditions PC-5 |
| BC-2.23.006 | GrepTool — calls `canonicalize_beneath_root` for the root `path` argument; if root path does not exist, Phase 2 returns `Ok(path)`, then `fs::open`/`read_dir` returns `NotFound` → E-TOOLS-008 via PC-6 fail-the-whole-search. PC-5 applies to the root path argument; recursive sub-paths are discovered by walking (they exist when canonicalize is called) so Phase 2 does not arise for those | MISSING — must reference ADR-024 §Phase-2 Postconditions PC-5 |
| Provider WriteFileTool BCs (pregolya-openai, pregolya-ollama) | Any WriteFileTool variant using `canonicalize_beneath_root` inherits Phase 2 confinement semantics | MISSING — must cite ADR-024 when authored |

**Propagation owner:** product-owner is responsible for propagating ADR-024 citations to
BC-2.13.004, BC-2.13.005, BC-2.23.001, BC-2.23.003, and any provider WriteFileTool BCs
(per P1D-177 finding C-H02, §Slice C).

---

## Rationale

The parent-canonicalize approach is preferred over alternatives for three reasons:

1. **Centralization.** All security logic stays in `canonicalize_beneath_root` (Pure Core,
   `pregolya-sandbox`). Every tool benefits automatically. The alternative — each tool
   independently detecting NotFound and calling a separate `create_confinement_check` — spreads
   security logic across multiple tools and increases the surface for divergence.

2. **BC-2.13.004 alignment.** §EC-004 already specifies the parent-canonicalize protocol as
   the expected behavior for the non-existent-path case. Decision 1 is an implementation of
   what §EC-004 describes. The alternative — a separate `canonicalize_beneath_root_for_create`
   entry point — would fragment the security surface without specification benefit.

3. **Formal-verification tractability.** A single function with a well-defined two-phase
   protocol is provable by Kani (VP-003 extension). A per-tool create-mode check would require
   separate proof harnesses for each tool.

---

## Alternatives Considered

### Alternative A — Per-tool create-mode parameter

Each tool that creates files could accept a `create: bool` parameter and call a separate
`canonicalize_beneath_root_for_create(base, requested)` entry point. WriteFileTool would
pass `create=true`; ReadFileTool and EditFileTool would pass `create=false`.

**Rejected because:** This spreads security logic across multiple tool implementations and
requires each tool author to correctly select the mode. A missed `create=false` in a
future tool would inherit the confinement gap. Centralization in `canonicalize_beneath_root`
means a single correct implementation protects all current and future tools automatically.
Also contradicts BC-2.13.004 §EC-004, which specifies the parent-canonicalize behavior as
an internal protocol of `canonicalize_beneath_root` rather than a caller-configurable mode.

### Alternative B — Caller-side existence pre-check

WriteFileTool could call `metadata(path)` before `canonicalize_beneath_root` to distinguish
existing-path calls from new-file calls, and branch to a simpler confinement check for
new files.

**Rejected because:** Introduces a TOCTOU window between the `metadata` call and the
`canonicalize_beneath_root` call that is more severe than the window in Decision 4
(the v2 deferred mitigation). Also duplicates logic across callers and does not reduce
implementation complexity relative to the two-phase internal protocol.

### Alternative C — Require parent directory to exist before calling WriteFileTool

Require the LLM agent to create the parent directory first (via a separate tool call) before
calling WriteFileTool on a new file. `canonicalize_beneath_root` would require the full path
to be canonicalizeable (Phase 1 only).

**Rejected because:** This produces exactly the F-P176-C002 CRIT condition — WriteFileTool's
primary use case is creating new files, and requiring a separate tool invocation to create the
parent makes the common case a multi-step error-prone workflow. Also does not eliminate the
dangling-symlink risk (the parent exists, but the file may be a dangling symlink when the
agent re-calls WriteFileTool).

---

## Consequences

- Product-owner MUST update BC-2.23.002 to describe the create-path behavior: PC-1 happy path
  now includes new-file creation (parent exists, within scope). The "parent directories NOT
  created automatically" note in PC-1 remains correct — if the PARENT doesn't exist, E-TOOLS-008
  is returned.
- Product-owner MUST align BC-2.13.005 §EC-003 with this ADR's PC-3 decision: dangling symlinks
  yield `Err(SandboxError::PathNotFound)`, and this ADR is the governing authority for that
  behavior.
- Product-owner MAY update BC-2.13.004 §Description to clarify that `canonicalize_beneath_root`
  implements the two-phase protocol internally for non-existent paths, consistent with §EC-004.
- Product-owner MUST propagate ADR-024 citations to BC-2.13.004, BC-2.13.005, BC-2.23.001,
  BC-2.23.003, and any provider WriteFileTool BCs per §Consumers above.
- The Phase 3 implementer extends `sandbox::path_guard::canonicalize_beneath_root` with Phase 2
  logic per Decision 1, including the dangling-symlink guard in step (d).
- VP-003 Kani harness must be extended in Phase 6 to cover the two-phase protocol including
  step (d). The harness must include:
  (a) new-file path with valid parent;
  (b) new-file path with parent escaping workspace;
  (c) path ending in `..` (filename = None case);
  (d) path whose final component is a dangling symlink (`symlink_metadata` returns `is_symlink
      = true`);
  (e) path whose final component is a symlink chain with absent final target.
- The v2 TOCTOU mitigation (`rustix` + `openat` + `O_NOFOLLOW`) is deferred; trigger condition
  is documented in Decision 4.

---

## Source / Origin

- **F-P176-C002** (CRIT): WriteFileTool create-path structurally unreachable — `canonicalize_beneath_root` cannot return `Ok` for a not-yet-existing path.
- **BC-2.13.004 §EC-004**: "Write to a new file that does not yet exist — Parent directory is canonicalized; parent must be beneath root; if parent OK, append filename and proceed." Authority for the parent-canonicalize protocol.
- **BC-2.23.002 §PC-2**: C001 discrimination rule (E-TOOLS-001 for genuine escapes, E-TOOLS-008 for OS I/O failures). This ADR extends that rule to the create-path case.
- **BC-2.13.005 §EC-003**: Dangling symlink → `Err(SandboxError::PathNotFound)`. Authority for Phase 2 step (d)'s error code. PC-3 of this ADR formalizes the implementation that makes EC-003 reachable.
- **DI-007**: Workspace Path Confinement — the invariant that `canonicalize_beneath_root` upholds.
- **VP-003** (BC-2.17.001): Kani harness — Phase 6 formal proof of workspace confinement; must be extended to cover the two-phase protocol including the dangling-symlink guard.
- **P1D-177 §Orchestrator Adjudication** (L-170): A verified-clean claim backed by an enumerated-but-incomplete probe set is itself a false-clean generator. This is the lesson that drives the complete attack-surface catalog in §Confinement-Proof.
