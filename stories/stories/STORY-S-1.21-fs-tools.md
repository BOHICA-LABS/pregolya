---
document_type: story
level: ops
story_id: S-1.21
epic_id: E-13
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-23/BC-2.23.001.md
  - .factory/specs/behavioral-contracts/ss-23/BC-2.23.002.md
  - .factory/specs/behavioral-contracts/ss-23/BC-2.23.003.md
  - .factory/specs/behavioral-contracts/ss-23/BC-2.23.004.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "11a6d3e"
traces_to:
  - behavioral-contracts/BC-2.23.001
  - behavioral-contracts/BC-2.23.002
  - behavioral-contracts/BC-2.23.003
  - behavioral-contracts/BC-2.23.004
points: 8
depends_on: [S-1.09, S-1.04, S-1.07]
blocks: [S-1.22]
behavioral_contracts: [BC-2.23.001, BC-2.23.002, BC-2.23.003, BC-2.23.004]
verification_properties: [VP-003]
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-tools
subsystems: [SS-23]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: N/A — BCs authored (BC-2.23.001, BC-2.23.002, BC-2.23.003, BC-2.23.004)
---

# STORY-S-1.21: Filesystem Tools (ReadFile, WriteFile, EditFile, ListDir)

## Narrative

As a graph node author, I want four filesystem tool implementations — `ReadFileTool`, `WriteFileTool`, `EditFileTool`, and `ListDirTool` — so that agents can read, write, edit, and list files within the sandboxed workspace without escaping the PathGuard confinement boundary.

## Token Budget Estimate

| Context Component | Estimated Tokens |
|-------------------|-----------------|
| This story spec | ~5,000 |
| BC files (4 BCs: BC-2.23.001–004) | ~10,000 |
| Architecture module-decomposition.md | ~3,000 |
| Target source files (pregolya-tools/src/) | ~8,000 |
| Test files | ~10,000 |
| S-1.09 (sandbox/PathGuard) interface | ~3,000 |
| **Total estimate** | **~39,000** |

Comfortable within context window. No split required.

## Behavioral Contracts

| BC ID | Title | Red Gate? |
|-------|-------|-----------|
| BC-2.23.001 | ReadFileTool — PathGuard-confined byte read, 1 MiB cap | No |
| BC-2.23.002 | WriteFileTool — PathGuard-confined atomic write | No |
| BC-2.23.003 | EditFileTool — exact-match / fuzzy replace with atomic write | No |
| BC-2.23.004 | ListDirTool — depth-1 directory listing with DirEntry | No |

## Acceptance Criteria

### AC-001: ReadFileTool — PathGuard confinement enforced on every call
`canonicalize_beneath_root` is called for every `ReadFileTool::invoke` call without exception. A path that resolves outside the workspace root (symlink escape or `..` traversal) returns `Err(PregolyaError { code: "E-TOOLS-001", .. })`.
(traces to BC-2.23.001 postcondition 1)

### AC-002: ReadFileTool — max_bytes cap is 1,048,576 (1 MiB default)
Reading a file larger than 1,048,576 bytes returns at most 1,048,576 bytes. The default `ReadConfig::max_bytes` is `1_048_576u64`.
(traces to BC-2.23.001 postcondition 2)

### AC-003: ReadFileTool — OS I/O errors use E-TOOLS-008, not E-TOOLS-001
A genuine file-not-found or permission-denied OS error returns `Err(PregolyaError { code: "E-TOOLS-008", .. })`. `E-TOOLS-001` is reserved for genuine scope-escape; OS I/O errors are never mapped to it.
(traces to BC-2.23.001 postcondition 3)

### AC-004: ReadFileTool — ADR-024 Phase-2 two-phase fallback for non-existent paths
`canonicalize_beneath_root` is called; `Ok(path)` from Phase-2 does NOT guarantee file exists. A subsequent `open` returning `NotFound` maps to `E-TOOLS-008`, not `E-TOOLS-001`.
(traces to BC-2.23.001 invariant 1)

### AC-005: WriteFileTool — atomic write via `.pregolyatmp_<random>` + rename
`WriteFileTool::invoke` writes content to a temp file named `.pregolyatmp_<random>` in the parent directory, then calls `fs::rename` to atomically replace the target. No partial write is visible to concurrent readers.
(traces to BC-2.23.002 postcondition 1)

### AC-006: WriteFileTool — retry_eligible: false
`WriteFileTool` implements `DynTool::retry_eligible` returning `false`. A failed write (e.g., parent directory missing) is not automatically retried by the circuit-breaker retry policy.
(traces to BC-2.23.002 postcondition 2)

### AC-007: WriteFileTool — three genuine E-TOOLS-001 conditions
`E-TOOLS-001` is raised precisely for: (a) symlink resolution escapes workspace root, (b) parent directory is outside workspace root, (c) path ends `..` or is filesystem root. All other I/O errors use `E-TOOLS-008`.
(traces to BC-2.23.002 postcondition 3)

### AC-008: WriteFileTool — ActionRisk::High
`WriteFileTool::action_risk()` returns `ActionRisk::High`. The tool registry records this tier for pre-tool-call hook dispatch.
(traces to BC-2.23.002 invariant 1)

### AC-009: EditFileTool — exact-match replacement by default
`EditFileTool::invoke` with `EditConfig::fuzzy_threshold: None` finds the first exact occurrence of `old_str` in the file and replaces it. If `old_str` appears zero times, returns `Err(PregolyaError { code: "E-TOOLS-003", .. })`.
(traces to BC-2.23.003 postcondition 1)

### AC-010: EditFileTool — opt-in fuzzy threshold via EditConfig
`EditFileTool::invoke` with `EditConfig::fuzzy_threshold: Some(t)` where `t ∈ (0.0, 1.0]` enables the `similar` (v3) crate for fuzzy matching. `fuzzy_threshold = 0.0` is rejected at `EditConfig` construction with `Err`. The `similar` crate carries Apache-2.0 license; MSRV 1.85.
(traces to BC-2.23.003 postcondition 2)

### AC-011: EditFileTool — atomic write on success
After a successful replacement, the updated content is written atomically via the same `.pregolyatmp_<random>` + rename pattern as `WriteFileTool`. ActionRisk is `ActionRisk::High`.
(traces to BC-2.23.003 postcondition 3)

### AC-012: ListDirTool — depth-1 listing with DirEntry
`ListDirTool::invoke` returns `Vec<DirEntry>` where each entry has `name: String`, `kind: EntryKind` (File/Dir/Symlink), and `size_bytes: Option<u64>` (populated for files, `None` for directories and symlinks).
(traces to BC-2.23.004 postcondition 1)

### AC-013: ListDirTool — entries sorted lexicographically by name
The returned `Vec<DirEntry>` is sorted ascending by `name`. An empty directory returns `Ok(vec![])`, not `Err`.
(traces to BC-2.23.004 postcondition 2)

### AC-014: ListDirTool — ActionRisk::ReadOnly
`ListDirTool::action_risk()` returns `ActionRisk::ReadOnly`. PathGuard confinement enforced; I/O traversal error returns `E-TOOLS-008`.
(traces to BC-2.23.004 postcondition 3)

## Architecture Mapping

| Component | Module | Crate | Pure/Effectful |
|-----------|--------|-------|---------------|
| `ReadFileTool` | `pregolya_tools::fs::read` | pregolya-tools | Effectful (filesystem I/O) |
| `WriteFileTool` | `pregolya_tools::fs::write` | pregolya-tools | Effectful (filesystem I/O) |
| `EditFileTool` | `pregolya_tools::fs::edit` | pregolya-tools | Effectful (filesystem I/O) |
| `ListDirTool` | `pregolya_tools::fs::list` | pregolya-tools | Effectful (filesystem I/O) |
| `PathGuard` / `canonicalize_beneath_root` | `pregolya_tools::sandbox` (from S-1.09) | pregolya-tools | Pure (canonicalization logic) |
| `DirEntry`, `EntryKind` | `pregolya_tools::fs::types` | pregolya-tools | Pure (data types) |
| `EditConfig` | `pregolya_tools::fs::edit` | pregolya-tools | Pure (config) |

**Subsystem anchor:** SS-23 owns this story's scope because SS-23 is the Tool Implementations subsystem per ARCH-INDEX Subsystem Registry. SS-23 contains all concrete tool structs that implement the `DynTool` object-safe trait; PathGuard is provided by SS-22 (sandbox backend, built in S-1.09) and consumed here.

**Dependency anchors:**
- Depends on S-1.09: `PathGuard` and `canonicalize_beneath_root` are built in S-1.09 (sandbox backend). S-1.21 cannot compile without the confinement API.
- Depends on S-1.04: `DynTool` trait (object-safe) and `ActionRisk` enum are defined in S-1.04. All four tools implement `DynTool`.
- Depends on S-1.07: `#[tool(...)]` proc-macro attribute (built in S-1.07) annotates tool registration and `action_risk` metadata.

## Purity Classification

| Function / Trait impl | Pure or Effectful | Reason |
|----------------------|-------------------|--------|
| `canonicalize_beneath_root` | Pure | Deterministic path arithmetic; no side effects |
| `EditConfig::new(fuzzy_threshold)` | Pure | Validates threshold bounds; returns Err on 0.0 |
| `ReadFileTool::invoke` | Effectful | Opens and reads filesystem |
| `WriteFileTool::invoke` | Effectful | Creates temp file, writes, renames |
| `EditFileTool::invoke` | Effectful | Reads, replaces, writes atomically |
| `ListDirTool::invoke` | Effectful | Reads directory entries from OS |

## Edge Cases

| ID | Source | Description | Expected Behavior |
|----|--------|-------------|-------------------|
| EC-001 | BC-2.23.001 EC-1 | Symlink target escapes workspace | `E-TOOLS-001` from `canonicalize_beneath_root` |
| EC-002 | BC-2.23.001 EC-2 | File larger than 1 MiB | Truncated read; at most 1,048,576 bytes returned |
| EC-003 | BC-2.23.001 EC-3 | ADR-024 Phase-2: non-existent target path canonicalized OK, then open fails | `E-TOOLS-008` on `open` failure |
| EC-004 | BC-2.23.002 EC-1 | Write parent directory missing | `E-TOOLS-008` (not `E-TOOLS-001`) |
| EC-005 | BC-2.23.002 EC-2 | rename() fails (cross-device) | `E-TOOLS-008`; partial temp file cleaned up |
| EC-006 | BC-2.23.003 EC-1 | `old_str` not found, no fuzzy | `E-TOOLS-003`; retry is caller-safe |
| EC-007 | BC-2.23.003 EC-2 | `fuzzy_threshold = 0.0` | `Err` at `EditConfig` construction |
| EC-008 | BC-2.23.004 EC-1 | Empty directory | `Ok(vec![])` |
| EC-009 | BC-2.23.004 EC-2 | Permission denied reading dir | `E-TOOLS-008` |
| EC-010 | BC-2.23.001 EC-4 | Path is `..` or filesystem root | `E-TOOLS-001` |

## Tasks

- [ ] Add `pregolya-tools` crate to workspace `Cargo.toml` members if not present
- [ ] Create `crates/pregolya-tools/src/lib.rs` (re-exports only; no logic)
- [ ] Create `crates/pregolya-tools/src/fs/mod.rs` (re-exports only)
- [ ] Create `crates/pregolya-tools/src/fs/types.rs` — `DirEntry`, `EntryKind`
- [ ] Create `crates/pregolya-tools/src/fs/read.rs` — `ReadFileTool`, `ReadConfig`
- [ ] Create `crates/pregolya-tools/src/fs/write.rs` — `WriteFileTool`, `WriteConfig`
- [ ] Create `crates/pregolya-tools/src/fs/edit.rs` — `EditFileTool`, `EditConfig`
- [ ] Create `crates/pregolya-tools/src/fs/list.rs` — `ListDirTool`
- [ ] Write failing tests for each AC before implementation (TDD strict)
- [ ] Implement `ReadFileTool` — PathGuard check, max_bytes, E-TOOLS-001/008 discrimination
- [ ] Implement `WriteFileTool` — atomic `.pregolyatmp_<random>` + rename
- [ ] Implement `EditFileTool` — exact match first, `similar` v3 opt-in fuzzy
- [ ] Implement `ListDirTool` — depth-1 with lexicographic sort
- [ ] Add `similar = { version = "3", default-features = false }` to `Cargo.toml`
- [ ] Verify `EditConfig::fuzzy_threshold: Some(0.0)` returns `Err` at construction
- [ ] Verify `retry_eligible()` returns `false` on `WriteFileTool`
- [ ] Run `just iter pregolya-tools` — all tests green

## Previous Story Intelligence

**From S-1.09 (Sandbox Backend & PathGuard):**
- `canonicalize_beneath_root(root: &Path, target: &Path) -> Result<PathBuf, PregolyaError>` is the canonical API. Do NOT call any `PathGuard::check` alias — `canonicalize_beneath_root` is the function name.
- ADR-024 Phase-2 two-phase fallback: for non-existent target files, the function returns `Ok(path)` (path is confined but not guaranteed to exist). The subsequent `fs::open` may return `NotFound` — map that to `E-TOOLS-008`, not `E-TOOLS-001`.
- The three genuine E-TOOLS-001 conditions (symlink escape, parent outside root, path ends `..` or is root) are all caught by `canonicalize_beneath_root` before any I/O occurs.

**From S-1.04 (Runnable Trait & Pipe):**
- `DynTool` is object-safe; it is the `Arc<dyn DynTool>` dispatch target used in the tool registry.
- `ActionRisk` enum variants: `ReadOnly`, `Medium`, `High`. All four tools in this story use `ReadOnly` (Read, List) or `High` (Write, Edit).

**From S-1.07 (Proc-Macro Attributes):**
- `#[tool(name = "...", action_risk = "High")]` macro annotates tools for registry auto-discovery. Use the canonical attribute form from S-1.07.

**N/A for prior batch lessons** — this is the first tool-implementation story.

## Architecture Compliance Rules

Extracted from `architecture/module-decomposition.md` and ADRs:

1. **`mod.rs` is re-export only.** `pregolya_tools::fs::mod.rs` must contain only `pub use` declarations — no `impl`, no `fn`, no `struct` definitions. Logic belongs in `read.rs`, `write.rs`, `edit.rs`, `list.rs`.
2. **No `unwrap()` / `expect()` in production code.** All `Result` / `Option` paths use `?` propagation with structured `PregolyaError` variants.
3. **No `println!` / `eprintln!` in library crates.** Use `tracing::debug!` / `tracing::warn!` with structured fields and `event_type`.
4. **reqwest not applicable to this crate** — no HTTP client in filesystem tools.
5. **`#[non_exhaustive]`** on `DirEntry`, `EntryKind`, `ReadConfig`, `WriteConfig`, `EditConfig` (public API surface types).
6. **File size gate:** production files under 750 code-lines (tokei `Code` metric). `read.rs`, `write.rs`, `edit.rs`, `list.rs` must each stay under soft target of 500.
7. **Forbidden dependency:** `pregolya-tools` must NOT depend on `pregolya-graph` or `pregolya-server`. Tool implementations are lower-layer.
8. **Atomic write temp prefix:** exactly `.pregolyatmp_<random>` — no other prefix is acceptable.

## Library & Framework Requirements

| Library | Version | Feature Flags | License | Usage |
|---------|---------|--------------|---------|-------|
| `similar` | `3` | `default-features = false` | Apache-2.0 | Fuzzy text matching in EditFileTool |
| `tokio` | (workspace pin) | `fs` feature required | MIT | Async filesystem I/O |
| `tracing` | (workspace pin) | default | MIT | Structured logging |
| `pregolya-core` / error types | (workspace) | — | — | `PregolyaError`, `ActionRisk` |
| `tempfile` or `rand` | (workspace if present) | — | MIT/Apache | Random suffix for `.pregolyatmp_<random>` temp name |

**Version note:** Do NOT invent version pins. Use workspace `[dependencies]` pin for `tokio`, `tracing`. `similar = "3"` is the only new pin introduced here (MSRV 1.85, Apache-2.0).

## File Structure Requirements

```
crates/pregolya-tools/
  Cargo.toml                         # [dependencies]: similar = "3" default-features = false
  src/
    lib.rs                           # re-export: pub use fs::*; pub use sandbox::*;
    fs/
      mod.rs                         # re-export only: pub use read::*; pub use write::*; ...
      types.rs                       # DirEntry, EntryKind (#[non_exhaustive])
      read.rs                        # ReadFileTool, ReadConfig
      write.rs                       # WriteFileTool, WriteConfig
      edit.rs                        # EditFileTool, EditConfig
      list.rs                        # ListDirTool
    sandbox.rs                       # re-exports canonicalize_beneath_root from S-1.09
  tests/
    fs_tools_integration.rs          # integration tests: confinement, atomic write, fuzzy edit
```

**Files to create (new):** all of the above.
**Files to modify (existing):** workspace root `Cargo.toml` (add `pregolya-tools` to `members`).
