---
document_type: demo-evidence-report
product: "pregolya-core (S-1.01: PregolyaError 2D Struct and RFC-7807 Emission)"
pipeline_run: "2026-09-18"
demo_type: "library"
recording_tool: "vhs"
status: complete
story_id: S-1.01
---

# Demo Evidence Report — S-1.01

## Product
`pregolya-core` — `PregolyaError` 2D Component × Category struct with RFC-7807 emission.

## Story
S-1.01: PregolyaError 2D Struct and RFC-7807 Emission (Wave 1, Priority P0)

## Demo Type
Library / test-harness. No binary or web UI. Evidence is captured by running
`cargo run -p pregolya-core --example error_taxonomy_demo -- <section>` for each
acceptance-criterion group and recording the output with VHS.

---

## Per-AC Demo Recordings

| AC | BC Trace | Description | Recording | Format | Status |
|----|----------|-------------|-----------|--------|--------|
| AC-001 | BC-2.14.001 PC-001 | `PregolyaError::new()` constructs all 5 named fields; Display = `[code] message` | [AC-001-007-008 GIF](AC-001-007-008-construction-display-source-chain.gif) | gif+webm | recorded |
| AC-002 | BC-2.14.001 PC-002 | Component axis — 18 named variants + Custom = 19 total | [AC-002-003-004 GIF](AC-002-003-004-enum-axes-retry-hint.gif) | gif+webm | recorded |
| AC-003 | BC-2.14.001 PC-003 | Category axis — 14 variants incl. Sys (14th, INTERNAL-tier HTTP 500) | [AC-002-003-004 GIF](AC-002-003-004-enum-axes-retry-hint.gif) | gif+webm | recorded |
| AC-004 | BC-2.14.001 PC-004 | RetryHint — Never/Maybe/Later(Duration); Duration::ZERO valid sentinel | [AC-002-003-004 GIF](AC-002-003-004-enum-axes-retry-hint.gif) | gif+webm | recorded |
| AC-005 | BC-2.14.001 PC-006 | `Error + Send + Sync` compile-time assertion + `Error::source` runtime clause — `source present: true` / `source preserved after clone: true` captured in Group-1 recording | [AC-001-007-008 GIF](AC-001-007-008-construction-display-source-chain.gif) | gif+webm | recorded |
| AC-006 | BC-2.14.001 PC-007 | `Default` NOT implemented — `assert_not_impl_any!` compile-time + external API surface confirmation; runtime header `=== AC-006: PregolyaError: not Default ===` emitted in all three recordings | [AC-001-007-008 GIF](AC-001-007-008-construction-display-source-chain.gif) | gif+webm | recorded |
| AC-007 | BC-2.14.001 PC-008 | `#[non_exhaustive]` — external callers use `PregolyaError::new` | [AC-001-007-008 GIF](AC-001-007-008-construction-display-source-chain.gif) | gif+webm | recorded |
| AC-008 | BC-2.14.001 EC-001 | `source: Option<Arc<dyn Error+Send+Sync>>` — clone preserves source via Arc refcount | [AC-001-007-008 GIF](AC-001-007-008-construction-display-source-chain.gif) | gif+webm | recorded |
| AC-009 | BC-2.14.002 PC-001 | `to_problem()` → type_uri, title, detail, retry_hint, component | [AC-009-015 GIF](AC-009-015-rfc7807-http-status-content-type.gif) | gif+webm | recorded |
| AC-010 | BC-2.14.002 PC-002 | `serde_json::to_string` produces valid RFC-7807 JSON, no null required fields | [AC-009-015 GIF](AC-009-015-rfc7807-http-status-content-type.gif) | gif+webm | recorded |
| AC-011 | BC-2.14.002 PC-003 | `http_status()` — all 14 Category variants mapped; no variant returns 200 | [AC-009-015 GIF](AC-009-015-rfc7807-http-status-content-type.gif) | gif+webm | recorded |
| AC-012 | BC-2.14.002 PC-004 | `PROBLEM_JSON_CONTENT_TYPE = "application/problem+json"` | [AC-009-015 GIF](AC-009-015-rfc7807-http-status-content-type.gif) | gif+webm | recorded |
| AC-013 | BC-2.14.002 PC-005 | `to_problem()` synchronous — no Tokio runtime required | [AC-009-015 GIF](AC-009-015-rfc7807-http-status-content-type.gif) | gif+webm | recorded |
| AC-014 | BC-2.14.002 INV-001+003 | `type_uri` = `urn:pregolya:error:<code>`; retry_hint canonical `"never"`/`"maybe"`/`"later:<secs>"` | [AC-009-015 GIF](AC-009-015-rfc7807-http-status-content-type.gif) | gif+webm | recorded |
| AC-015 | BC-2.14.001 INV-003 | `error.code` preserved unchanged in `to_problem().type_uri` | [AC-009-015 GIF](AC-009-015-rfc7807-http-status-content-type.gif) | gif+webm | recorded |

**Note on AC-005 and AC-006:** Both ACs have compile-time assertion components AND runtime output captured in the recordings.

AC-005 has two clauses: (a) `static_assertions::assert_impl_all!(PregolyaError: Error + Send + Sync)` at module level in `pregolya-core/src/error.rs` (compile-time gate) and (b) the `Error::source` runtime clause — demonstrated in the `construction` section via `std::error::Error::source(&outer).is_some()` on an error built with `.with_source(Arc::clone(&inner_arc))`. The Group-1 recording captures the runtime clause via `source present: true` and `source preserved after clone: true` output lines under the `=== AC-005: Error + Send + Sync / Error::source runtime clause ===` header.

AC-006 (`Default` not implemented): enforced at compile time by `static_assertions::assert_not_impl_any!(pregolya_core::PregolyaError: Default)` in the example itself — an external compilation unit, proving the guarantee on the public API surface. Additionally, all three recordings show the runtime confirmation lines `=== AC-006: PregolyaError: not Default ===` and `  assert_not_impl_any!(PregolyaError: Default) — verified externally`, printed by `main()` before any section-specific code runs.

---

## Recording Group → AC Mapping

### Group 1: `AC-001-007-008-construction-display-source-chain` (tape + gif + webm)

Runs: `cargo run -p pregolya-core --example error_taxonomy_demo -- construction`

| Output Line Pattern | AC Evidenced |
|---------------------|-------------|
| `=== AC-006: PregolyaError: not Default ===` | AC-006 runtime confirmation header (runs before any section) |
| `  assert_not_impl_any!(PregolyaError: Default) — verified externally` | AC-006 external API surface confirmation |
| `Display:  [E-CORE-001] Invalid ContentBlock type 'x'` | AC-001 Display format `[code] message` |
| `.code:`, `.message:`, `.category:`, `.component:`, `.retry:`, `.source:` fields printed | AC-001 five named fields + source accessible |
| `Sys (14th Category): [E-SBXD-010] CanonicalizationFailed: cannot resolve path '/tmp/link': EACCES: Permission denied` | AC-003 Sys variant; AC-007 external constructor |
| `=== AC-005: Error + Send + Sync / Error::source runtime clause ===` | AC-005 runtime clause section header |
| `Outer:  [E-GRAPH-001] concurrent writes to LastValue channel` | AC-008 outer error wraps inner |
| `source present: true` | AC-005 `Error::source` populated; AC-008 source field populated |
| `source message: [E-CHKPT-001] checkpoint write failed` | AC-008 source chain accessible via Display |
| `source preserved after clone: true` | AC-005 `Error::source` preserved via Arc refcount after clone; AC-008 Arc::clone semantics |

### Group 2: `AC-002-003-004-enum-axes-retry-hint` (tape + gif + webm)

Runs: `cargo run -p pregolya-core --example error_taxonomy_demo -- enums`

| Output Line Pattern | AC Evidenced |
|---------------------|-------------|
| `Named (18): Core Graph Chkpt Traj Server Prov Mcp Split Sbxd Retry Cron Memory Budget Tmpl Srlz Vs Embed Tools` | AC-002 18 named variants exhaustively listed |
| `Custom:    Custom("newcrate")` | AC-002 Custom(String) variant |
| `Total variants: 19` | AC-002 total count |
| `All 14: Val Auth Rate Timeout Transport Internal Durability Policy Tool Concurrency Security Tenancy Exec Sys` | AC-003 14 variants |
| `Sys is the 14th (INTERNAL-tier, HTTP 500, default RetryHint::Maybe)` | AC-003 Sys variant spec |
| `Never: Never`, `Maybe: Maybe`, `Later(30s): Later(30s)` | AC-004 three variants |
| `Later(0s):  Later(0ns)  (Duration::ZERO sentinel ...)` | AC-004 Duration::ZERO is valid |
| `Inner duration accessible: 30s` | AC-004 inner Duration field accessible |

### Group 3: `AC-009-015-rfc7807-http-status-content-type` (tape + gif + webm)

Runs: `cargo run -p pregolya-core --example error_taxonomy_demo -- rfc7807`

| Output Line Pattern | AC Evidenced |
|---------------------|-------------|
| `"type": "urn:pregolya:error:E-CORE-001"` | AC-009 type_uri format; AC-014 stable URN |
| `"title": "Validation"` | AC-009 humanized category title |
| `"detail": "Invalid ContentBlock type 'x'"` | AC-009 detail = message |
| `"retry_hint": "never"` | AC-009 retry_hint; AC-014 canonical "never" form |
| `"component": "core"` | AC-009 component lowercase |
| `"retry_hint": "later:30"` (Rate/Later(30s)) | AC-014 canonical "later:<secs>" form (not "30s" or debug) |
| `"title": "System"` (Sys/Maybe) | AC-003 Sys title = "System"; AC-009 |
| `"retry_hint": "maybe"` (Sys/Maybe) | AC-014 canonical "maybe" form |
| `Val -> HTTP 400  [OK]` through `Sys -> HTTP 500  [OK]` (14 rows) | AC-011 all 14 categories mapped |
| `No category returns 200: true` | AC-011 no-200 invariant |
| `PROBLEM_JSON_CONTENT_TYPE = "application/problem+json"` | AC-012 constant value |
| `is RFC-7807 value (not application/json): true` | AC-012 not application/json |
| `to_problem() called without async runtime: OK` | AC-013 synchronous |
| `original code:  E-CORE-001` / `type_uri:       urn:pregolya:error:E-CORE-001` | AC-015 code immutable |
| `code preserved: true` | AC-015 code unchanged through to_problem |

**AC-009 wire shape note (BC-2.14.002 v1.16):** The serialized JSON contains no `extensions` key — `retry_hint` and `component` are emitted as direct top-level RFC-7807 §3.2 members (verified by `test_BC_2_14_002_rfc7807_json` which asserts `obj.get('extensions').is_none()`).

---

## Example Source

`crates/pregolya-core/examples/error_taxonomy_demo.rs`

Accepts an optional positional argument: `construction`, `enums`, or `rfc7807`.
Without argument, runs all three sections in sequence.

---

## Toolchain

| Tool | Version | Status |
|------|---------|--------|
| VHS | 0.11.0 | installed |
| cargo | 1.98.0 | installed |
| ffmpeg | system | installed (used by VHS) |
| Playwright | — | not applicable (library product) |

**Note on `Wait+Line`:** VHS 0.11.0 `Wait+Line` is non-functional on this platform
(macOS Darwin 25.5.0); `Sleep`-based timing is used instead. The `Sleep` durations
(8–10s) are calibrated to `cargo run` overhead (~1s) plus output display time plus
a final-frame hold. All recordings were verified to contain the expected output.

---

## PR Embedding Snippet

```markdown
### Demo Evidence — S-1.01: PregolyaError

| AC Group | GIF |
|----------|-----|
| Construction, Display, Arc Source Chain (AC-001/007/008) | ![AC-001-007-008](docs/demo-evidence/S-1.01/AC-001-007-008-construction-display-source-chain.gif) |
| Enum Axes & RetryHint (AC-002/003/004) | ![AC-002-003-004](docs/demo-evidence/S-1.01/AC-002-003-004-enum-axes-retry-hint.gif) |
| RFC-7807, http_status, Content-Type, Sync, Immutable (AC-009..015) | ![AC-009-015](docs/demo-evidence/S-1.01/AC-009-015-rfc7807-http-status-content-type.gif) |
```
