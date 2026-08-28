---
document_type: behavioral-contract
level: L3
bc_id: BC-2.13.005
version: "1.6"
status: active
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
  - .factory/specs/architecture/decisions/ADR-024-writefile-create-path-confinement.md
input-hash: "ecd4d2b"
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
changelog:
  - "1.1 (CENSUS-P109, 2026-07-18): Fix TV-002 and TV-003 E-SBXD-001 WorkspaceEscape struct — both rows used `{ resolved: \"/etc/passwd\" }` (single field) missing `requested` and `root`. Canonical 3-field form `{ requested, resolved, root }` per PC4/Invariant-2/VP-2.13.005-C. TV-002 fix: add `requested: \"/workspace/link_a\"`; TV-003 fix: add `requested: \"/workspace/rel_escape\"`. Both rows also missing `root: \"/workspace\"`. TD-VSDD-060 sweep: no other E-SBXD-001 struct sites in file."
  - "1.2 (FIX-BURST-257/F-P156-01, 2026-07-24): anchor-class sweep — nonexistent architecture file citations replaced with adjudicated real targets (F-P114-01 pattern)."
  - "1.3 (burst-288/P1D-177-C01/2026-08-15): ADR-024 §Phase-2 Postconditions traceability propagation — §Traceability §Binding Decisions: ADR-024 §Phase-2 Postconditions PC-3 added as governing authority for EC-003 dangling-symlink PathNotFound decision (per ADR-024 §Consumers obligation). EC-003 Expected Behavior updated: per ADR-024 §Decision 1 Phase 2 step (d), `symlink_metadata(joined)` detects the dangling symlink directly (is_symlink()=true → Err(SandboxError::PathNotFound)); prior text cited canonicalize's IoError::NotFound which was the pre-§Decision-1-Phase-2 description. Error verdict unchanged: Err(SandboxError::PathNotFound), not WorkspaceEscape. Architecture Anchors: ADR-024 §Decision 1 step (d) + §PC-3 added. inputs: ADR-024 added."
  - "1.4 (burst-291/D-134/2026-08-16): §-anchor phantom sweep — Forcing Functions: §NE catalog NE-02 is a phantom anchor (no '## NE catalog' heading in product-brief.md; NE items are table rows within '### Security Defaults — PRD Carry-Forward'). Corrected to §Security Defaults — PRD Carry-Forward (NE-02)."
  - "1.5 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.6 (F-P2A123-01/2026-08-28): §Story Anchor backfilled to S-1.09; §Architecture Module confirmed as pregolya-sandbox / WorkspaceFs facade — from STORY-INDEX forward map (SS-13 coverage map) and self §Architecture Anchors (module-decomposition.md §pregolya-sandbox, sandbox::path_guard row). No behavioral change."
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
reveals `/etc/passwd`. pregolya's `canonicalize_beneath_root` (BC-2.13.004) catches this by
calling `std::fs::canonicalize()` which follows symlinks at the OS level before the prefix check.
This BC directly covers domain edge case DEC-011.

## Preconditions

1. {PRE-001} A workspace root `/workspace` exists with a canonical path
2. {PRE-002} A symlink exists at a path inside the workspace (e.g., `/workspace/escape_link`) whose
   target is outside the workspace root (e.g., `/etc/passwd`, `~/.ssh/id_rsa`,
   `~/.aws/credentials`)
3. {PRE-003} A tool or internal API requests a file operation on the symlink path via the `WorkspaceFs`
   facade

## Postconditions

1. {PC-001} `canonicalize_beneath_root(workspace_root, "/workspace/escape_link")` calls
   `std::fs::canonicalize("/workspace/escape_link")`
2. {PC-002} `canonicalize` returns the resolved target (e.g., `/etc/passwd`)
3. {PC-003} The resolved path does NOT have `/workspace` as a prefix
4. {PC-004} `canonicalize_beneath_root` returns
   `Err(E-SBXD-001: WorkspaceEscape { requested: "/workspace/escape_link", resolved: "/etc/passwd", root: "/workspace" })`
5. {PC-005} The file is NOT read, written, or otherwise accessed — zero bytes of the target file are
   observed

## Invariants

1. {INV-001} Symlink resolution happens via OS-level `canonicalize` — no string analysis of the symlink
   path itself determines the outcome
2. {INV-002} `WorkspaceEscape` carries three fields: `requested` (the path the caller provided),
   `resolved` (the canonical target path after symlink resolution), and `root` (the workspace
   root) — enabling precise audit logging
3. {INV-003} There is no "follow symlinks outside root" opt-in for workspace file operations —
   escape detection is unconditional
4. {INV-004} Symlinks whose targets remain within the workspace root are allowed (access proceeds with
   the canonical resolved path)
5. {INV-005} adk-rust reference sparsity: P-65 is the explicit counter-example; no positive upstream
   reference — greenfield behavior derived from NE-02 and DI-007

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Symlink at `/workspace/internal_link` points to `/workspace/subdir/file.txt` (within root) | `canonicalize` resolves to `/workspace/subdir/file.txt`; beneath root; `Ok(resolved_path)` — internal symlinks are permitted |
| EC-002 | Chained symlinks: `/workspace/link_a → /workspace/link_b → /etc/passwd` | `canonicalize` follows the full chain; resolves to `/etc/passwd`; `Err(E-SBXD-001: WorkspaceEscape)` |
| EC-003 | Dangling symlink: symlink entry exists but target path does not exist | ADR-024 §Decision 1 Phase 2 step (d): `std::fs::symlink_metadata(joined)` returns `Ok(m)` where `m.file_type().is_symlink() = true` — the symlink entry is present but its target is absent. Returns `Err(SandboxError::PathNotFound)` per ADR-024 §Phase-2 Postconditions PC-3. Not a workspace escape error — the symlink entry itself is inside the workspace; confinement of the target cannot be verified, so the operation is rejected with PathNotFound. |
| EC-004 | Relative symlink: `/workspace/rel_link → ../etc/passwd` | `canonicalize` resolves relative to the symlink's parent directory (`/workspace`), yielding `/etc/passwd`; `Err(E-SBXD-001: WorkspaceEscape)` |
| EC-005 | Symlink to a directory outside root: `/workspace/etc_dir → /etc` | `canonicalize` resolves to `/etc`; not beneath root; `Err(E-SBXD-001: WorkspaceEscape)` — directory symlinks are subject to the same check |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `canonicalize_beneath_root("/workspace", "/workspace/escape_link")` where `escape_link → /etc/passwd` | `Err(E-SBXD-001: WorkspaceEscape { requested: "/workspace/escape_link", resolved: "/etc/passwd", root: "/workspace" })` | DEC-011 (domain edge case) |
| `canonicalize_beneath_root("/workspace", "/workspace/internal_link")` where `internal_link → /workspace/subdir/file` | `Ok(PathBuf::from("/workspace/subdir/file"))` | happy-path (internal symlink) |
| `canonicalize_beneath_root("/workspace", "/workspace/link_a")` where chain resolves to `/etc/passwd` | `Err(E-SBXD-001: WorkspaceEscape { requested: "/workspace/link_a", resolved: "/etc/passwd", root: "/workspace" })` | edge-case (chained symlinks) |
| `canonicalize_beneath_root("/workspace", "/workspace/dangling_link")` where target missing | `Err(SandboxError::PathNotFound)` | edge-case (dangling symlink — not an escape error) |
| `canonicalize_beneath_root("/workspace", "/workspace/rel_escape")` where `rel_escape → ../etc/passwd` | `Err(E-SBXD-001: WorkspaceEscape { requested: "/workspace/rel_escape", resolved: "/etc/passwd", root: "/workspace" })` | edge-case (relative symlink escape) |

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
| Source Analysis | P-65 NOT-APPLICABLE (must-not-inherit: `validate_relative_path` string-only — permits symlink escapes); NE-02 (pregolya requirement: canonical real-path check); DEC-011 (domain edge case: Workspace Symlink Escape); assessment-parts/part-3 §NE-02 |
| Reference Evidence | adk-rust P-65: `validate_relative_path` never calls `canonicalize`, never resolves symlinks — pregolya INVERTS this. DEC-011 in edge-cases.md documents this exact scenario. No positive upstream reference — greenfield. |
| Binding Decisions | NE-02, DI-007; ADR-024 §Phase-2 Postconditions PC-3 (dangling-symlink final component → `Err(SandboxError::PathNotFound)` — governing authority for EC-003 error-routing decision; per ADR-024 §Consumers obligation, this BC must cite ADR-024 as the implementing authority for step (d) of the two-phase `canonicalize_beneath_root` protocol) |
| Forcing Functions | DEC-011 ("Workspace Symlink Escape" domain edge case); product-brief.md §Security Defaults — PRD Carry-Forward (NE-02) |
| Architecture Module | pregolya-sandbox / WorkspaceFs facade |
| Stories | S-1.09 |

## Related BCs

- BC-2.13.004 — depends on: symlink escape detection is a consequence of the access-time canonicalization mandated by BC-2.13.004; this BC specifies the specific escape scenario
- BC-2.17.001 — VP seed: the Kani harness for workspace confinement (Phase 6) covers this symlink scenario as one of its proof obligations

## Architecture Anchors

- `architecture/module-decomposition.md §pregolya-sandbox` — `sandbox::path_guard` row: `std::fs::canonicalize()` follows symlinks before prefix check; `Err E-SBXD-001`; symlink-escape detection as consequence of access-time canonicalization (CRITICAL, SS-13)
- `architecture/decisions/ADR-024-writefile-create-path-confinement.md` — §Decision 1 Phase 2 step (d): `symlink_metadata(joined)` detects dangling-symlink final component (`is_symlink()=true` → `Err(SandboxError::PathNotFound)`); §Phase-2 Postconditions PC-3: governing authority for EC-003 error code and rationale (confinement unverifiable for dangling-symlink target)

## Story Anchor

S-1.09 — Symlink escape detection in WorkspaceFs

## VP Anchors

- VP-2.13.005-A — Escape symlink → Err + zero file accesses (integration test)
- VP-2.13.005-B — Internal symlink → Ok (unit test)
- VP-2.13.005-C — WorkspaceEscape error fields (unit test)
