---
document_type: behavioral-contract
level: L3
bc_id: BC-2.23.003
version: "1.11"
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
timestamp: 2026-08-24T00:00:00Z
di_anchors: [DI-014]
vp_seed: false
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 first-party tool library, SS-23 EditFileTool."
  - "1.1 (Burst-232/2026-07-22): Fix Category::VALIDATION → Category::VAL in PC-2 (E-TOOLS-003 EditOldStringNotFound). VALIDATION is not in the canonical 12-member Category enum; E-TOOLS-003 is VAL per error-taxonomy v1.31. D23 straggler sweep."
  - "1.2 (burst-233/F-P133-03/2026-07-22): PC-5 — assign E-TOOLS-008 FileIoError to the OS-level I/O error path for file-not-found (was 'TOOLS, I/O category' with no code). Structured fields: tool_type: 'EditFileTool', path: <file_path>, io_kind: <ErrorKind debug name>. Gate #33 forward+reverse clean."
  - "1.3 (burst-247/F-P146-02/2026-07-24): H1 title — append exhaustive raised-code enumeration 'E-TOOLS-001/003/008' per SS-23 title policy. Inline contextual reference 'E-TOOLS-003 on No-Match' is retained (describes trigger condition); trailing exhaustive enumeration is now also present for machine extractability. TD-VSDD-060: BC-INDEX row and bc-authoring-plan Batch 20 title cell updated same burst (state-manager handles BC-INDEX). input-hash updated 0bc5c5d→64d7571 (inputs unchanged; hash drift from prior burst)."
  - "1.4 (FIX-BURST-270/ADR-010-v1.9/2026-07-25): Apply PascalCase casing canon (ADR-010 v1.9 Direction B) at 2 sites: component: \"TOOLS\" string literal → component: Component::Tools (PC-2 + PC-5); Category::VAL → Category::Val (PC-2), Category::TOOL → Category::Tool (PC-5)."
  - "1.5 (F-P173-601/2026-07-27): PathGuard::check phantom-method sweep. Replace invented method name PathGuard::check with canonical canonicalize_beneath_root at 1 site: VP-2.23.003-A property description. No error-layer-split issues — E-TOOLS-001 correctly used throughout."
  - "1.6 (fix-burst-280/F-P175-A25/2026-07-28): Convert 2 struct-literal construction examples to PregolyaError::new() form. PC2 E-TOOLS-003 EditOldStringNotFound: ::new(Component::Tools, Category::Val, RetryHint::Never, ...). PC5 E-TOOLS-008 file-not-found: ::new(Component::Tools, Category::Tool, RetryHint::Maybe, ...); phantom tool_type/path/io_kind fields removed (message-embedded placeholders). TD-VSDD-060 sibling sweep: no other struct-literal construction examples found in this BC."
  - "1.7 (fix-burst-287/ADR-010-C3/2026-08-01): ADR-010 Class 3 notation fix — 2 prose occurrences of PregolyaError::new(...) replaced with observation form. PC-2 E-TOOLS-003: inline → PregolyaError { code: 'E-TOOLS-003', .. }. PC-5 E-TOOLS-008: inline → { code: 'E-TOOLS-008', .. }. verify-error-notation-canon.sh PASS."
  - "1.8 (burst-288/P1D-177-C-H02/2026-08-15): ADR-024 §Phase-2 Postconditions traceability propagation — EditFileTool Ok-then-NotFound-at-open behavior. PC-5 extended: when canonicalize_beneath_root returns Ok(path) via Phase 2 (ADR-024 §Phase-2 Postconditions PC-5), path may not yet exist on disk; EditFileTool precondition 3 requires an existing file, so the subsequent OS open returns NotFound, propagated as E-TOOLS-008. This behavior is expected — Phase 2 running does not imply the file exists. traces_to + inputs + Architecture Anchors + §Architecture Authority updated to reference ADR-024 §Phase-2 Postconditions PC-5."
  - "1.9 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.21 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.10 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.11 (ADR-027 F-04/2026-08-24): ADR-027 F-04: old-form ordinal cross-refs converted to stable tags — self-reference 'precondition 3' in PC-005 prose converted to {PRE-003}."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-036
  - architecture/decisions/ADR-020-first-party-tool-library.md
  - architecture/decisions/ADR-024-writefile-create-path-confinement.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-020-first-party-tool-library.md
  - .factory/specs/architecture/decisions/ADR-024-writefile-create-path-confinement.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "81ff585"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.23.003: EditFileTool — Exact-Match String Replace; E-TOOLS-003 on No-Match; Opt-In Fuzzy Fallback (EditConfig::fuzzy_threshold); Conditional Retry Safe; E-TOOLS-001/003/008

## Description

`EditFileTool` in `pregolya-tools::tools::fs` implements the `Tool` trait with
`ActionRisk::High`. It applies a string-replace edit to an existing file: it finds the first
occurrence of `old_string` in the file and replaces it with `new_string`. The default mode is
exact-match; if `old_string` is not found verbatim, the tool returns
`Err(E-TOOLS-003 EditOldStringNotFound)` — the file is left unchanged. An optional
`EditConfig::fuzzy_threshold: Option<f32>` enables fuzzy-match fallback using the `similar`
crate (`TextDiff::ratio` threshold, default `None` / exact-only). `replace_all: bool`
controls whether all occurrences are replaced (default false — first occurrence only).

## Preconditions

1. {PRE-001} `EditFileTool` is constructed with a `PathGuard` instance and an optional `EditConfig`
   (`EditConfig::fuzzy_threshold: Option<f32>` where `f32 ∈ (0.0, 1.0]`; default `None`).
2. {PRE-002} The caller invokes the tool with JSON args:
   `{ "path": "<path>", "old_string": "<old>", "new_string": "<new>", "replace_all": false }`.
   `path` and `old_string` are non-empty strings; `new_string` may be empty (deletion).
3. {PRE-003} The path resolves to an existing file within `PathGuard` scope.

## Postconditions

1. {PC-001} **Happy path (exact match found):** The first (or all, if `replace_all: true`) occurrence
   of `old_string` in the file is replaced with `new_string`. The write is performed atomically
   (same temp-file + rename pattern as BC-2.23.002). The tool returns
   `ToolOutput::Text("edited: <path> (1 replacement)")` or
   `ToolOutput::Text("edited: <path> (<n> replacements)")` when `replace_all: true`.
2. {PC-002} **Exact-match not found (default mode, `fuzzy_threshold: None`):** `old_string` is not
   present in the file verbatim. The tool returns
   `Err(PregolyaError { code: "E-TOOLS-003", .. })`.
   The file is NOT modified.
3. {PC-003} **Fuzzy fallback (opt-in, `fuzzy_threshold: Some(t)`):** If exact match fails, the tool
   uses `similar::TextDiff` to compute the `ratio()` between `old_string` and each contiguous
   region of the file of similar length. If the best match has `ratio() >= t`, the match is
   accepted and the replacement proceeds as in PC-1. If no region meets the threshold,
   `Err(E-TOOLS-003)` is returned as in PC-2. Fuzzy match is a fallback; exact match is
   always tried first.
4. {PC-004} **Path confinement violation:** Returns `Err(E-TOOLS-001 PathConfinementViolation)`.
   No I/O performed.
5. {PC-005} **File not found:** Returns `Err(PregolyaError { code: "E-TOOLS-008", .. })`.
   **ADR-024 PC-5 note:** `canonicalize_beneath_root` Phase 2 may return `Ok(path)` for a
   path whose parent is within scope even when the target file does not yet exist. `EditFileTool`
   {PRE-003} requires the path to resolve to an *existing* file; Phase 2 running does not
   mean the file exists (ADR-024 §Phase-2 Postconditions PC-5: `Ok(path)` from Phase 2 is a
   creation-target path, not a file-existence guarantee). The subsequent OS `open()` call returns
   `NotFound`, which is propagated as `E-TOOLS-008` here. This is expected — `EditFileTool` does
   not create files.
6. {PC-006} **Conditional retry safe:** `old_string` not found (E-TOOLS-003) is structurally a no-op
   (the file was not modified). Re-retrying after E-TOOLS-003 is safe without re-approval
   because no state was changed. This is the only retry-safe failure mode; write failures
   (OS I/O errors) are NOT retry-safe and require re-approval per BC-2.23.002 semantics.

## Invariants

- {INV-001} Exact match is always attempted before fuzzy fallback. Fuzzy fallback is NEVER applied
  if `fuzzy_threshold` is `None`.
- {INV-002} `fuzzy_threshold` must be in `(0.0, 1.0]`; a value of 0.0 is rejected at construction
  with a configuration error (a threshold of 0.0 would match anything).
- {INV-003} Atomicity: when a match is found and replacement proceeds, the write follows the
  temp-file + rename protocol from BC-2.23.002. No partial writes are observable.
- {INV-004} **DI-014 (No Silent Swallowing):** E-TOOLS-003 is returned — the file not changing is never
  silently treated as success. Callers can detect and handle the not-found case.
- {INV-005} `replace_all: false` (default): only the FIRST occurrence is replaced. Subsequent identical
  occurrences are untouched.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `old_string` not present in file; `fuzzy_threshold: None` | `Err(E-TOOLS-003 EditOldStringNotFound: old_string not found in '<path>')` — no write |
| EC-002 | `old_string` not present exactly, but present with different whitespace; `fuzzy_threshold: Some(0.85)` and TextDiff::ratio >= 0.85 | Fuzzy match accepted; replacement proceeds; `ToolOutput::Text("edited: <path> (1 replacement)")` |
| EC-003 | `new_string` is empty string (deletion) | First occurrence of `old_string` deleted; file otherwise unchanged; `ToolOutput::Text("edited: <path> (1 replacement)")` |
| EC-004 | `old_string` appears 3 times, `replace_all: false` | Only first occurrence replaced; 2 remaining unchanged |
| EC-005 | `old_string` appears 3 times, `replace_all: true` | All 3 replaced; `ToolOutput::Text("edited: <path> (3 replacements)")` |
| EC-006 | Path outside PathGuard | `Err(E-TOOLS-001 PathConfinementViolation)` — no I/O |
| EC-007 | `fuzzy_threshold: Some(0.0)` (zero threshold at construction) | Configuration error at `EditFileTool::new()` — `fuzzy_threshold` must be in `(0.0, 1.0]` |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `{ "path": "/workspace/src.rs", "old_string": "fn foo()", "new_string": "fn bar()" }` — exact match present | `ToolOutput::Text("edited: /workspace/src.rs (1 replacement)")` | happy-path (exact match) |
| TV-002 | `{ "path": "/workspace/src.rs", "old_string": "fn missing()", "new_string": "fn bar()" }` — `old_string` absent; no fuzzy | `Err(E-TOOLS-003)` — `EditOldStringNotFound: old_string not found in '/workspace/src.rs'` | error-case (no match) |
| TV-003 | Same as TV-002 but `fuzzy_threshold: Some(0.9)` — "fn missing()" ≈ "fn missing ()"; ratio ≥ 0.9 | `ToolOutput::Text("edited: /workspace/src.rs (1 replacement)")` | fuzzy fallback |
| TV-004 | `{ "path": "/etc/hosts", ... }` — outside PathGuard | `Err(E-TOOLS-001 PathConfinementViolation)` | security (confinement) |
| TV-005 | `{ ..., "new_string": "", "replace_all": false }` — deletion of first occurrence | File shorter by `old_string.len()` bytes; `ToolOutput::Text("edited: <path> (1 replacement)")` | edge-case (deletion) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.23.003-A (VP-003 reuse) | canonicalize_beneath_root called before any filesystem open | Kani proof reused from VP-003 |
| VP-2.23.003-B | E-TOOLS-003 returned when exact match absent and no fuzzy threshold set | Unit test: file without old_string; assert Err(E-TOOLS-003) |
| VP-2.23.003-C | Conditional retry safety: E-TOOLS-003 path leaves file unchanged | Unit test: call EditFileTool twice with same args on a file without old_string; file bytes identical after both calls |

## Related BCs

- BC-2.23.001 — sibling: ReadFileTool (ReadOnly; same PathGuard substrate)
- BC-2.23.002 — sibling: WriteFileTool (same atomic write protocol; different call shape)
- BC-2.13.004 — depends on: VP-003 PathGuard workspace-confinement Kani proof
- BC-2.16.001 — related to: EditFileTool retry classification (conditional retry safe for E-TOOLS-003; not safe for I/O errors)
- BC-2.05.007 — related to: ActionRisk::High → PreToolCallHook approval gate at dispatch

## Architecture Anchors

- `architecture/decisions/ADR-020-first-party-tool-library.md` — Decision 2 (EditFileTool contract, `EditConfig::fuzzy_threshold`, `similar = "3"` opt-in), Decision 3 (High ActionRisk), Decision 4 (conditional retry classification), Decision 5 (E-TOOLS-001/003), Decision 7 (`similar` crate pin `"3"` Apache-2.0 MSRV 1.85)
- `architecture/decisions/ADR-024-writefile-create-path-confinement.md` — §Phase-2 Postconditions PC-5 (EditFileTool receives `Ok(path)` from Phase 2 when the requested file does not yet exist; the subsequent OS `open()` call returns `NotFound`, which must be propagated as `E-TOOLS-008 FileIoError` — `Ok` from `canonicalize_beneath_root` does NOT mean the file exists; EditFileTool does not create files); §Decision 2 (EditFileTool calling convention unchanged — no create-mode parameter)
- `architecture/module-decomposition.md` — SS-23, `tools::fs` module in pregolya-tools

## Story Anchor

S-1.21

## VP Anchors

- VP-2.23.003-A (VP-003 reuse)
- VP-2.23.003-B
- VP-2.23.003-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-036 |
| Capability Anchor Justification | CAP-036 ("First-Party Filesystem Tools (tools::fs — ReadFileTool, WriteFileTool, EditFileTool, ListDirTool)") per capabilities-p1-p2.md §CAP-036 — this BC specifies EditFileTool's exact-match semantics, E-TOOLS-003 error, opt-in fuzzy fallback via EditConfig::fuzzy_threshold, and conditional retry safety that CAP-036 names as part of the tools::fs surface |
| L2 Domain Invariants | DI-014 (Error Propagation — E-TOOLS-003 propagates as Err; no silent success on no-match) |
| Architecture Authority | ADR-020 Decisions 2, 3, 4, 5, and 7 (EditFileTool contract, fuzzy threshold, similar dep pin, retry classification, E-TOOLS-001/003); ADR-024 §Phase-2 Postconditions PC-5 (EditFileTool receives `Ok(path)` from Phase 2 when file does not exist; subsequent `open()` returns `NotFound` → E-TOOLS-008 — EditFileTool does not create files) and §Decision 2 (calling convention unchanged) |
| Binding Decisions | D23 (first-party tool library scope, SS-23 creation) |
| VP Registration | VP-003 reuse; VP-2.23.003-B/C (unit tests) |
| Module | pregolya-tools / tools::fs |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration |
