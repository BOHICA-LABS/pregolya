---
document_type: behavioral-contract
level: L3
bc_id: BC-2.13.004
version: "1.6"
status: active
producer: product-owner
timestamp: 2026-08-16T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
  - .factory/specs/architecture/decisions/ADR-024-writefile-create-path-confinement.md
input-hash: "df3ab85"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-13
capability: CAP-015
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-8): F-P8-01 title census — H1 updated to add '— Kani VP Seed' suffix (vp_seed designation codified in heading per title-authority convention)."
  - "1.2 (F-P110-02, 2026-07-18): Fix TV-002 E-SBXD-001 WorkspaceEscape struct — 2-field form `{ resolved, root }` missing `requested`. Canonical 3-field form `{ requested, resolved, root }` per BC-2.13.005 Invariant-2 (cross-anchor consistency under gate #33 v2.37). TV-002 fix: add `requested: \"/workspace/../etc/passwd\"`. TD-VSDD-060 file-wide sweep: only one E-SBXD-001 struct site in this file (line 108 in Canonical Test Vectors). The prior in-file sweep missed this because the secondary anchor BC-2.13.004 was not scoped by the TD-VSDD-060 sweep anchored 'in-file' rather than 'across ALL anchor BCs' — the systemic root cause corrected in bc-authoring-plan gate #33 v2.37."
  - "1.3 (FIX-BURST-257/F-P156-01, 2026-07-24): anchor-class sweep — nonexistent architecture file citations replaced with adjudicated real targets (F-P114-01 pattern)."
  - "1.4 (burst-288/P1D-177-C-H03/2026-08-15): ADR-024 §Phase-2 Postconditions traceability propagation — §Traceability §Binding Decisions: ADR-024 Decision 1 (two-phase protocol) + §Phase-2 Postconditions PC-4 (Ok-path confinement proof) added; PC-4 is the formal proof that directly implements what EC-004's parent-canonicalize protocol specifies. Postcondition 5 (write/create new file): traces-to note citing ADR-024 Decision 1 Phase 2 + PC-4 added. Architecture Anchors: ADR-024 §Decision 1/§Confinement-Proof/§PC-4 added. inputs: ADR-024 added."
  - "1.5 (burst-290/P1D-180-phantom-sweep, 2026-08-16): Fix two live-body phantom ADR §-citations. PC-5 trailing reference and Architecture Anchors: `§Confinement-Proof` (hyphen form) → `ADR-024 §Confinement Proof — Phase 2` (real heading is `## Confinement Proof — Phase 2` in ADR-024; hyphen was dropped to space + em-dash)."
  - "1.6 (burst-291/D-134/2026-08-16): §-anchor phantom sweep — Forcing Functions: §NE catalog NE-02 is a phantom anchor (no '## NE catalog' heading in product-brief.md; NE items are table rows within '### Security Defaults — PRD Carry-Forward'). Corrected to §Security Defaults — PRD Carry-Forward (NE-02)."
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
vp_seed: true
vp_id: VP-003
kani_target: workspace-confinement
---

# BC-2.13.004: All Workspace File Ops Call canonicalize_beneath_root at Access Time (NE-02) — Kani VP Seed

## Description

Every workspace file operation (read, write, create, delete, list) must invoke
`canonicalize_beneath_root(base: &Path, requested: &Path) -> Result<PathBuf, SandboxError>`
at access time before performing any OS-level file call. The function calls
`std::fs::canonicalize()` on the fully-joined path to resolve all symlinks and `..`
components, then verifies the canonical path starts with the canonical workspace root.
The adk-rust counter-example (P-65) uses string depth-counting of `..` segments
(`validate_relative_path`) without touching the filesystem — a symlink inside the workspace
pointing outside passes cleanly. pregolya's access-time canonicalization closes this gap.
This BC is a VP seed: the workspace-confinement Kani harness (Phase 6, BC-2.17.001) will
formally prove that no file operation can observe content outside the declared workspace root.

## Preconditions

1. A `WorkspaceRoot` has been established with a canonical base path (resolved at construction
   time via `std::fs::canonicalize()`)
2. A tool or internal API is requesting a file operation against a `requested_path` (which may
   be relative, absolute, contain `..`, or contain symlinks)
3. The file operation is dispatched through the `WorkspaceFs` facade — no direct `std::fs`
   calls are permitted outside this facade

## Postconditions

1. `canonicalize_beneath_root(base, requested)` is called before any OS file operation
2. The function calls `std::fs::canonicalize()` (or `tokio::fs::canonicalize()` in async
   context) to resolve all symlinks and `..` components
3. If the canonical resolved path has the canonical workspace root as a prefix,
   the resolved `PathBuf` is returned and the file operation proceeds
4. If the canonical resolved path does NOT have the workspace root as a prefix,
   `Err(E-SBXD-001: WorkspaceEscape)` is returned and no file operation occurs
5. For write/create to a new file (path does not yet exist), the parent directory path is
   canonicalized and verified to be beneath the root; the new filename is then appended
   (ADR-024 Decision 1 Phase 2 two-phase protocol; confinement proof for the `Ok(path)` return
   per ADR-024 §Phase-2 Postconditions PC-4: `canonical_parent.join(filename) ⊆ canonical_base`
   holds unconditionally under the five soundness invariants in ADR-024 §Confinement Proof — Phase 2)
6. String depth-counting of `..` segments is NOT used as sole or partial validation

## Invariants

1. `canonicalize_beneath_root` is called at access time — not at path construction time or
   as a pre-validation step that is later bypassed
2. All workspace file operations route through a single `WorkspaceFs` facade; no code path
   calls `std::fs::read`, `std::fs::write`, `std::fs::File::open`, or equivalents directly
   on a path inside the sandbox without going through this facade
3. The prefix check uses the CANONICAL workspace root (resolved once at `WorkspaceRoot`
   construction) — not a string comparison of the original input path
4. adk-rust reference sparsity: upstream `validate_relative_path` (P-65) is the
   counter-example; no positive upstream reference for filesystem-level canonicalization
   in the sandbox path — greenfield design derived from NE-02 and DI-007

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Relative path with benign `../` that does NOT escape root: `workspace/foo/../bar` | Canonical path is `/workspace/bar`; beneath root; `Ok("/workspace/bar")` — operation proceeds |
| EC-002 | Relative path with `../` that escapes root: `workspace/../etc/passwd` | Canonical path is `/etc/passwd`; not beneath root; `Err(E-SBXD-001: WorkspaceEscape)` |
| EC-003 | Absolute path outside root: `/etc/passwd` | Canonical path `/etc/passwd`; not beneath root; `Err(E-SBXD-001: WorkspaceEscape)` |
| EC-004 | Write to a new file that does not yet exist | Parent directory is canonicalized; parent must be beneath root; if parent OK, append filename and proceed; if parent escapes, `Err(WorkspaceEscape)` |
| EC-005 | Path refers to a directory, not a file (e.g., list operation) | `canonicalize_beneath_root` applied to directory path; same prefix check; returns `Ok(canonical_dir)` or `Err(WorkspaceEscape)` |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `canonicalize_beneath_root("/workspace", "/workspace/subdir/file.txt")` (file exists) | `Ok(PathBuf::from("/workspace/subdir/file.txt"))` | happy-path |
| `canonicalize_beneath_root("/workspace", "/workspace/foo/../bar")` (bar exists) | `Ok(PathBuf::from("/workspace/bar"))` | edge-case (benign traversal) |
| `canonicalize_beneath_root("/workspace", "/workspace/../etc/passwd")` | `Err(E-SBXD-001: WorkspaceEscape { requested: "/workspace/../etc/passwd", resolved: "/etc/passwd", root: "/workspace" })` | error (string escape) |
| `canonicalize_beneath_root("/workspace", "/etc/passwd")` | `Err(E-SBXD-001: WorkspaceEscape)` | error (absolute path outside root) |
| Attempt to call `std::fs::read("/workspace/file.txt")` directly without `WorkspaceFs` facade | Compile-error or lint violation — `WorkspaceFs` facade is the only permitted path | structural |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|--------------|
| VP-2.13.004-A | For all reachable workspace file operations, `canonicalize_beneath_root` is called before the OS-level file call | integration test — instrument WorkspaceFs facade; assert canonicalize called on every code path |
| VP-2.13.004-B | No workspace file operation uses string depth-counting of `..` segments as its path safety mechanism | structural test — grep for `validate_relative_path`-style patterns; zero occurrences |
| VP-2.13.004-C (VP seed) | No file operation can observe content outside the declared workspace root regardless of symlink structure | Kani harness — Phase 6 (BC-2.17.001); this VP is the formal-verification seed for the workspace-confinement invariant |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-015 |
| Capability Anchor Justification | CAP-015 ("Sandboxed Tool Execution (Enforcing Backend Default)") per capabilities-p1-p2.md §CAP-015 |
| L2 Domain Invariants | DI-007 (Workspace Path Confinement) |
| Source Analysis | P-65 NOT-APPLICABLE (must-not-inherit: string-only path safety without symlink resolution); NE-02 (pregolya requirement: canonicalize_beneath_root at access time); assessment-parts/part-2 §6 Sandbox Cluster; assessment-parts/part-3 §NE-02 |
| Reference Evidence | adk-rust `validate_relative_path` (P-65) counts `..` segments without filesystem contact — pregolya INVERTS this. No upstream LangChain equivalent for canonicalize-based path confinement. greenfield design. |
| Binding Decisions | NE-02, DI-007; ADR-024 Decision 1 (two-phase `canonicalize_beneath_root` protocol for non-existent paths — Phase 2 directly implements the parent-canonicalize protocol specified in EC-004); ADR-024 §Phase-2 Postconditions PC-4 (confinement proof for `Ok(path)` returns from Phase 2: `canonical_parent.join(filename) ⊆ canonical_base` under five soundness invariants) |
| Forcing Functions | product-brief.md §Security Defaults — PRD Carry-Forward (NE-02) ("All workspace file operations must call canonicalize_beneath_root(base, path) at access time"); DEC-011 (Domain edge case: Workspace Symlink Escape) |
| Architecture Module | pregolya-sandbox / WorkspaceFs facade (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.13.005 — depends on: symlink escape detection (BC-2.13.005) requires this canonicalization to be in place
- BC-2.17.001 — VP seed: this BC's workspace-confinement invariant is the target of the Phase-6 Kani harness

## Architecture Anchors

- `architecture/module-decomposition.md §pregolya-sandbox` — `sandbox::path_guard` row: `canonicalize_beneath_root(base, path)`; `Err E-SBXD-001` on workspace escape; `WorkspaceFs` facade routes all workspace file ops (CRITICAL, SS-13)
- `architecture/purity-boundary-map.md §Pure Core` — `sandbox::path_guard` row: VP-003 Kani P0 target; pure path arithmetic after OS resolution
- `architecture/verification-architecture.md` — VP-003 workspace-confinement Kani harness (`workspace_confinement_harness`)
- `architecture/decisions/ADR-024-writefile-create-path-confinement.md` — §Decision 1 (two-phase protocol implementing EC-004's parent-canonicalize semantics); ADR-024 §Confinement Proof — Phase 2 (attack-surface catalog AS-01..AS-09 + soundness argument for Phase 2 `Ok` returns); §Phase-2 Postconditions PC-4 (formal confinement guarantee for `Ok(canonical_parent.join(filename))` — the theoretical basis for the VP-003 Kani harness Phase 2 extension)

## Story Anchor

S-N.MM — WorkspaceFs facade with canonicalize_beneath_root (filled by story-writer)

## VP Anchors

- VP-2.13.004-A — canonicalize called on every workspace file op (integration test)
- VP-2.13.004-B — no string-depth-counting pattern (structural test)
- VP-2.13.004-C — Kani workspace-confinement proof (Phase 6 / BC-2.17.001)
