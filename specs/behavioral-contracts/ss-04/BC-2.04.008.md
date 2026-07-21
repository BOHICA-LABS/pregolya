---
document_type: behavioral-contract
level: L3
bc_id: BC-2.04.008
version: "1.4"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0: Initial greenfield spec (D20 sub-burst 1)."
  - "1.1 (D20 sub-burst 2): E-CHKPT-008/E-CHKPT-009 split — EC-006 updated to use E-CHKPT-009 (INTERNAL/Fts5Unavailable) instead of E-CHKPT-008; ambiguity note removed; resolution note added; Traceability Error Code Minted row updated; error code minted blockquote updated to document both codes."
  - "1.2 (2026-07-15, F-P74-01): Description fix — CheckpointStore::fts_search → CheckpointSaver::fts_search; retired identifier per gate #19 shared-type canon (P18 census). No other retired spellings found in full-file scan (RunConfig, BaseCheckpointSaver, AIMessage-Rust-context, Checkpointer)."
  - "1.3 (2026-07-15, F-P78-04/D18-P78-A): PC6 message string corrected — added 'FtsLimitZero: ' prefix per universal <Name>: <detail> convention (D18-P78-A adjudication). Updated 'got 0' to 'got <limit>' for parametric template consistency with taxonomy row E-CHKPT-008. No change to EC-004 or TV-004 (those use variant name only, no message string)."
  - "1.4 (2026-07-15, F-P82-01): PC3 corrected — `query: &str` was incorrectly listed as a field of `FtsSearchConfig`. Fixed: `query` is the standalone first parameter of `fts_search` (not a config field); `FtsSearchConfig` fields are `thread_id: Option<&str>` and `limit: usize` only. Signature (Description block), PC1, EC-002, TV-001 all agree with this fix; only PC3 carried the contradiction. No other content changed."
origin: greenfield
priority: P1
subsystem: SS-04
capability: CAP-005
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-005
inputs:
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "1ea13ca"
modified: []
extracted_from: null
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.04.008: FTS Conversation Search Over Checkpoint History (Single-Process; SQLite FTS5)

## Description

`ferrochain-checkpoint` exposes `CheckpointSaver::fts_search(query: &str, config:
FtsSearchConfig) -> Result<Vec<FtsSearchResult>, FerrochainError>` — a full-text search
interface over conversation history stored in the checkpoint SQLite database. The FTS5
index covers checkpoint bodies: conversation messages (human, AI, tool), tool call arguments,
and tool results. This is a **single-process v1** implementation: multi-process WAL-safe
concurrent write semantics are deferred to v2 (the SQLite WAL writer handles single-process
concurrent reads). The search capability is also registered as a callable `Tool`
(`search_history`) so agents can query their own conversation history mid-run.

## Preconditions

1. The `CheckpointSaver` backend is SQLite with FTS5 enabled (SQLite must have the FTS5
   extension compiled in — this is the default for all major distributions).
2. At least one checkpoint has been written to the store (FTS index populated from
   checkpoint writes).
3. `query: &str` is the standalone first parameter to `fts_search` — it is NOT a field of
   `FtsSearchConfig`. It may include FTS5 phrase syntax (e.g., `"\"Paris weather\""`).
   `FtsSearchConfig` has exactly two fields: `thread_id: Option<&str>` (scope to a single
   thread or `None` for all threads) and `limit: usize` (maximum number of results,
   must be > 0).

## Postconditions

1. `fts_search(query, config)` returns `Ok(Vec<FtsSearchResult>)` where each
   `FtsSearchResult` contains: `checkpoint_id: CheckpointId`, `thread_id: String`,
   `checkpoint_ns: String`, `message_role: MessageRole`, `content_snippet: String`
   (a BM25-ranked excerpt of the matching content), and `rank: f64` (BM25 relevance score,
   lower is more relevant in SQLite FTS5 convention).
2. Results are ordered by `rank` ascending (most relevant first).
3. If `config.thread_id = Some(tid)`, only checkpoints for that thread are searched.
   If `None`, all threads in the store are searched.
4. If no matches are found, `Ok(vec![])` is returned — not an error.
5. The `search_history` `Tool` wraps `fts_search` and is registerable in any ferrochain
   graph via `graph.add_tool(search_history_tool())`. Calling it from a graph node
   invokes `fts_search` on the run's configured `CheckpointSaver` and returns the
   results as a `ToolMessage`.
6. `FtsSearchConfig.limit` of 0 returns
   `Err(FerrochainError { component: CHKPT, category: VAL, code: "E-CHKPT-008",
   message: "FtsLimitZero: FtsSearchConfig.limit must be > 0; got <limit>", retry_hint: Never })`.

> **Error codes minted here (E-CHKPT-008, E-CHKPT-009).**
> - `E-CHKPT-008 FtsLimitZero` — VAL, broken, Never. Covers: (1) `limit = 0` input (PC6/EC-004); (2) malformed FTS5 query syntax (EC-002). Both are VAL caller-input rejections.
> - `E-CHKPT-009 Fts5Unavailable` — INTERNAL, broken, Never. Covers: FTS5 extension not compiled into SQLite build (EC-006). INTERNAL — deployment/environment error, not a caller input error.
> Taxonomy rows registered: sub-burst 2.

## Invariants

- **Read-only search:** `fts_search` is a pure read; it does not write to the checkpoint
  store and does not create or update checkpoints. It does not affect the FTS5 index.
- **FTS5 index consistency:** the FTS5 index is updated atomically when a new checkpoint
  is written (same transaction as the checkpoint write). A checkpoint visible via
  `get_tuple` is also searchable via `fts_search`. No separate indexing job is required.
- **Single-process v1:** the `fts_search` implementation assumes a single SQLite writer
  process. Multi-process WAL write-safety (concurrent checkpoint writers) is deferred and
  explicitly out of scope for this BC. Read-only queries from multiple async tasks within
  the same process are safe (SQLite WAL mode supports concurrent readers).
- `limit` must be a positive integer > 0. Arithmetic check: for any `limit: usize` where
  `limit > 0`, the result `Vec` length is in the range `[0, limit]` inclusive.

## Edge Cases

### EC-001: No checkpoints in the store
**Scenario:** `fts_search("hello world", config)` called on an empty checkpoint database.
**Expected behavior:** `Ok(vec![])`. Not an error. FTS5 returns empty results on an empty table.

### EC-002: FTS5 phrase query with special characters
**Scenario:** `fts_search("\"Paris weather\"", config)` (FTS5 phrase search).
**Expected behavior:** Returns results where "Paris" and "weather" appear adjacent. FTS5
phrase syntax is passed directly to SQLite. Malformed FTS5 syntax (e.g., unclosed quote)
returns `Err(FerrochainError { component: CHKPT, category: VAL, code: E-CHKPT-008, ... })`
propagating the SQLite FTS5 parse error.

### EC-003: Thread-scoped search
**Scenario:** `config.thread_id = Some("thread-abc")`; 3 checkpoints for "thread-abc",
2 for "thread-xyz". Query matches 1 from "thread-abc" and 1 from "thread-xyz".
**Expected behavior:** Returns 1 result (from "thread-abc" only); "thread-xyz" result excluded.

### EC-004: `limit = 0` at construction
**Scenario:** `FtsSearchConfig { limit: 0, … }`.
**Expected behavior:** `Err(E-CHKPT-008 FtsLimitZero)`. (DI-008: construction-time
validation returns Err, not panic.)

### EC-005: search_history tool called from a graph node mid-run
**Scenario:** A graph node calls the `search_history` tool with query `"API error"` to
find prior occurrences in the conversation history.
**Expected behavior:** `fts_search` is called on the run's `CheckpointSaver`; results
returned as a `ToolMessage` content block. The tool invocation is counted against the run's
budget (BC-2.10.001) and checkpoint-logged (BC-2.04.001).

### EC-006: SQLite FTS5 extension not available
**Scenario:** SQLite is compiled without the FTS5 extension.
**Expected behavior:** `CheckpointSaver::new(…)` with FTS enabled returns
`Err(FerrochainError { component: CHKPT, category: INTERNAL, code: "E-CHKPT-009",
message: "Fts5Unavailable: FTS5 extension not available in this SQLite build — recompile SQLite with FTS5 support or use a pre-built distribution that includes it" })` at construction time.
(DI-008: fail at construction, not at first search call.)

> **Resolution (D20 sub-burst 2):** The ambiguity between `limit = 0` (VAL) and FTS5-unavailable (INTERNAL) is resolved by splitting into two codes: `E-CHKPT-008` (VAL) for caller-input errors (limit=0, malformed FTS5 query syntax) and `E-CHKPT-009` (INTERNAL) for deployment/environment errors (FTS5 not compiled in). Different categories → different codes per taxonomy governance. EC-006 uses `E-CHKPT-009` exclusively.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Write 3 checkpoints with "Paris weather" in content; `fts_search("Paris")` | `Ok(vec![result1, result2, result3])` with BM25 ranks | Happy-path FTS |
| TV-002 | `fts_search("Paris")` on empty store | `Ok(vec![])` | Empty store |
| TV-003 | `fts_search("Paris", config { thread_id: Some("t1") })` — "Paris" in both t1 and t2 | Only t1 result returned | Thread-scoped search |
| TV-004 | `FtsSearchConfig { limit: 0, … }` | `Err(E-CHKPT-008 FtsLimitZero)` | Limit-zero guard |
| TV-005 | Write 10 checkpoints with "error"; `fts_search("error", config { limit: 3 })` | `Ok(vec![…])` with `len() <= 3` | Limit enforcement |
| TV-006 | Graph node calls `search_history` tool mid-run | `ToolMessage` with FTS results returned | Tool integration |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-FTS-01 | FTS5 index is consistent with checkpoint write: a checkpoint visible via `get_tuple` is searchable within the same transaction boundary | Integration test: write checkpoint; fts_search; assert match | Wave 2 |
| VP-FTS-02 | Thread-scoped search excludes results from other threads | Integration test: write to 2 threads; search scoped to one; assert count | Wave 2 |

## Related BCs

- BC-2.04.001 — depends on: `put_writes` is the write path; FTS5 index update is co-transactional with checkpoint writes
- BC-2.04.003 — composes with: monotonic checkpoint IDs are the primary key in FTS index entries
- BC-2.15.001 — related to: both provide search over stored content; FTS here covers conversation/tool-call history; BC-2.15.001 covers long-horizon KV+vector memory; they are stored in separate backends

## Architecture Anchors

- `ferrochain-checkpoint/src/fts.rs` — `FtsSearchConfig`, `FtsSearchResult`, `fts_search` implementation; FTS5 virtual table `fts_checkpoint_bodies` co-created with the main checkpoints table; `search_history_tool()` constructor
- `ferrochain-checkpoint/src/sqlite.rs` — FTS5 index update in the same SQLite transaction as `put` / `put_writes`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-FTS-01, VP-FTS-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-005 |
| Capability Anchor Justification | CAP-005 ("Durable Three-Tier Checkpointing (Sync Default; Per-Task put_writes)") per capabilities-p0.md §CAP-005 — this BC extends the SQLite checkpoint backend (specified in CAP-005 as "SQLite (default)") with an FTS5 full-text search index over checkpoint bodies, enabling conversation history to be queried as a callable tool; FTS is an additive query layer over the same checkpoint store |
| L2 Domain Invariants | DI-002 (Per-Task Durability — FTS5 index updated in same transaction as checkpoint write; FTS results consistent with what's checkpointed), DI-008 (Library Constructor Result Contract — FtsSearchConfig with limit=0 returns Err at construction time, not panic), DI-014 (Error Propagation — storage errors propagate as Err; empty result is Ok(vec[]) not an error) |
| Error Codes Minted | E-CHKPT-008 FtsLimitZero (VAL, broken, Never) — caller-input rejections: limit=0 and malformed FTS5 query syntax. E-CHKPT-009 Fts5Unavailable (INTERNAL, broken, Never) — FTS5 extension not compiled into SQLite build. CHKPT namespace had 7 live codes (E-CHKPT-001 through E-CHKPT-007); E-CHKPT-008 and E-CHKPT-009 are next. Split adjudicated in D20 sub-burst 2: different categories (VAL vs INTERNAL) require separate codes per taxonomy governance. |
| Domain D Forcing Function | domain-d-hermes-agent.md req 8 — "[PARTIAL CAP-005/SS-04 + CAP-017/SS-15] … FTS over the full checkpoint/conversation history (tool calls + reasoning traces) exposed as a first-class callable agent tool is absent" |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration) |
| Module | ferrochain-checkpoint |
