---
document_type: behavioral-contract
level: L3
bc_id: BC-2.12.002
version: "1.8"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-12
capability: CAP-014
wave: 1
phase: 1a
red_gate: false
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-32): F-P32-03 add PC20 — GET /assistants/{id}/versions pagination (limit default 10 max 100 clamped / offset 0 / ordering exemption: version ASC) matching interface-definitions.md §Assistants /versions row."
  - "1.2 (ADV-P1D-PASS-33): F-P33-01 add PC21-PC23 — GET /assistants list-collection postcondition block (response shape { assistants: [Assistant], total_count: u64 }, limit default 10 max 100 clamped / offset 0 / created_at DESC); interface-definitions.md §Canonical Pagination Convention BC anchors updated. F-P33-02 add cross-reference to run-config merge precedence canon in Description."
  - "1.3 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-server per module-decomposition.md v1.10."
  - "1.4 (fix-burst-283/F-P175-C113/2026-07-30): §Description corrected — replace fabricated 'model, tools, system prompt overrides, checkpointer config' clause with accurate RunnableConfig field inventory per ADR-021 Decision 2 (configurable map added; LangGraph parity). Add EC-006 and TV-008 for configurable-key collision merge precedence (run-level key wins per BC-2.12.003 §Run-Config Merge Precedence Invariant and interface-definitions.md §RunnableConfig configurable field doc)."
  - "1.5 (burst-291/D-134/2026-08-16): Three phantom §-anchor citations corrected. (1) §Description 'BC-2.12.003 §Run-Config Merge Precedence Invariant' → 'BC-2.12.003 §Invariants' (§Run-Config Merge Precedence Invariant matches no heading; it is a bold bullet inside §Invariants). (2) EC-006 same correction plus 'interface-definitions.md §RunnableConfig configurable field doc' → 'interface-definitions.md §RunnableConfig — Struct Definition' (§RunnableConfig configurable field doc matches no heading; RunnableConfig struct is defined under '#### RunnableConfig — Struct Definition (F-P92-02)'). Sentence restructured with comma separator so BC_CITE_RE stops at §Invariants, not at '.md'. TD-VSDD-060 sweep: both §Run-Config Merge Precedence Invariant occurrences in live body text corrected."
  - "1.6 (BURST-312/F-P203-01/2026-08-17): Capability Anchor Justification quote-fidelity fix — 'Assistant (named agent config with graph reference)' corrected to verbatim CAP-014 text 'Assistant (named agent config)'; the phrase 'with graph reference' does not appear in capabilities-p1-p2.md §CAP-014. F-P203-01."
  - "1.7 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.26 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.8 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/semport/platform/behavioral-intent.md
input-hash: "37b5b45"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.12.002: Assistant Resource CRUD (Named Agent Config with Graph Reference)

## Description

An Assistant is a named, versioned configuration record that binds a `graph_id` to
a `RunnableConfig` carrying execution parameters (`recursion_limit`, `thread_id`, `budget_config`) plus a `configurable` map for graph-specific overrides (e.g., model selection, tool-set, system-prompt), and optional context. Graphs read their per-run parameters from `config.configurable` at execution time using graph-defined key names. It serves as a reusable "agent persona": callers create a Run
by referencing an Assistant, and the Run inherits the Assistant's config; run-supplied
`config`, `metadata`, and `context` are deep-merged over the Assistant's stored values
with run-level keys winning at the leaf level (merge precedence canon — see BC-2.12.003
§Invariants, F-P33-02). Versions
are immutable snapshots; `set_latest` updates the "current" pointer without mutating
any existing version. No wire-compatibility with LangGraph Platform (D13).

## Preconditions

1. {PRE-001} `pregolya-server` is running with a configured `RunStore` backend.
2. {PRE-002} The caller holds a valid authentication credential (or the server is in unauthenticated dev mode).

## Postconditions

### Create Assistant (`POST /assistants`)

1. {PC-001} Accepts body `{ graph_id: String, config?: RunnableConfig, context?: Value, metadata?: Map<String,Value>, assistant_id?: Uuid, if_exists?: "raise"|"do_nothing", name?: String, description?: String }`.
2. {PC-002} `assistant_id` is caller-supplied or server-generated (UUID v4 if absent).
3. {PC-003} The server stores an immutable Version 1 snapshot of `(graph_id, config, context, metadata)`.
4. {PC-004} Returns HTTP 201 with the `Assistant { assistant_id, graph_id, config, context, metadata, name, description, version: 1, created_at }`.
5. {PC-005} If `assistant_id` already exists and `if_exists = "raise"` (default): HTTP 409.
6. {PC-006} If `assistant_id` already exists and `if_exists = "do_nothing"`: returns existing Assistant (HTTP 200).

### Read Assistant (`GET /assistants/{assistant_id}`)

7. {PC-007} Returns the currently active version of the Assistant.
8. {PC-008} Returns HTTP 404 with `{ code: "E-SERVER-009", message: "AssistantNotFound: assistant '<id>' does not exist" }` if not found.

### Update Assistant (`PATCH /assistants/{assistant_id}`)

9. {PC-009} Accepts a sparse body; only provided fields are updated.
10. {PC-010} Creates a new immutable version snapshot (version N+1) with the merged fields.
11. {PC-011} The previous version remains accessible via `GET /assistants/{assistant_id}/versions`.
12. {PC-012} Returns HTTP 200 with the updated (new-version) Assistant record.

### Delete Assistant (`DELETE /assistants/{assistant_id}`)

13. {PC-013} Accepts optional query param `delete_threads: bool` (default `false`).
14. {PC-014} If `delete_threads = true`: all Threads associated with this Assistant's Runs are also deleted (cascade).
15. {PC-015} If `delete_threads = false`: Threads are preserved; the Assistant record is removed.
16. {PC-016} Returns HTTP 204 on success; HTTP 404 if not found.

### Version Operations

17. {PC-017} `GET /assistants/{assistant_id}/versions` — returns list of all immutable version snapshots
    ordered by version number ascending.
18. {PC-018} `POST /assistants/{assistant_id}/set_latest { version: N }` — updates the "latest" pointer
    to version N. Returns HTTP 200 with the Assistant record at version N.
19. {PC-019} Setting `version = N` where N does not exist returns HTTP 404.
20. {PC-020} `GET /assistants/{assistant_id}/versions` supports canonical pagination: `limit` (default 10,
    max 100; values > 100 silently clamped to 100), `offset` (default 0). **Ordering exemption:**
    results are ordered `version` **ascending** (lowest version first) — version ASC is
    intentional for historical replay and differs from the canonical `created_at` DESC default
    declared in the §Canonical Pagination Convention. BC-2.12.001 PC8 clamp canon applies;
    out-of-range canon: clamp (F-P31-01). Exemption documented in interface-definitions.md
    §Assistants /versions row (F-P32-03).

### List Assistants (`GET /assistants`)

21. {PC-021} Accepts query params `limit` (default 10, max 100; values > 100 silently clamped to 100),
    `offset` (default 0).
22. {PC-022} Returns `{ assistants: [Assistant], total_count: u64 }` for all stored Assistants.
23. {PC-023} Results ordered `created_at` **descending** (canonical; F-P31-01). Out-of-range clamp
    canon per BC-2.12.001 PC8 (F-P31-01, ADV-P1D-PASS-31). Interface anchor:
    interface-definitions.md §Assistants `GET /assistants` row (F-P33-01).

## Invariants

- {INV-001} Each `PATCH` creates a NEW version; existing versions are immutable and never overwritten.
- {INV-002} The "latest" pointer is mutable; it always resolves to a valid version number.
- {INV-003} `GET /assistants/{id}` always resolves via the latest pointer, never returns a stale version.
- {INV-004} `graph_id` is a required field and cannot be updated to empty on `PATCH` (validation error).

## Edge Cases

### EC-001: PATCH with empty body
**Scenario:** `PATCH /assistants/a1` with `{}`.
**Expected behavior:** HTTP 200 with the same Assistant record (no-op PATCH). A new
version is NOT created — sparse updates only create a version when at least one field
changes.

### EC-002: set_latest to non-existent version
**Scenario:** `POST /assistants/a1/set_latest { version: 99 }` when only versions 1–3 exist.
**Expected behavior:** HTTP 404 `{ code: "E-SERVER-010", message: "AssistantVersionNotFound: assistant 'a1' has no version 99" }`.

### EC-003: delete with delete_threads=true
**Scenario:** Assistant "a1" has 3 associated threads (via its runs). `DELETE /assistants/a1?delete_threads=true`.
**Expected behavior:** HTTP 204. All 3 threads and their checkpoint state deleted. The
thread deletion is subject to BC-2.12.001 cascade semantics.

### EC-004: Read assistant at specific version
**Scenario:** Assistant has 3 versions; caller wants version 2 specifically.
**Expected behavior:** `GET /assistants/a1/versions` lists all 3; caller reads version 2's
snapshot from the list. There is no `GET /assistants/a1?version=2` single-resource endpoint —
callers must use the versions list.

### EC-005: Graph_id references a graph not registered in the server
**Scenario:** `POST /assistants { graph_id: "phantom-graph", ... }`.
**Expected behavior:** HTTP 422 `{ code: "E-SERVER-011", message: "GraphNotFound: graph 'phantom-graph' is not registered with this server instance" }`. The assistant is NOT created.

### EC-006: Configurable-key collision between assistant-stored and run-supplied config
**Scenario:** Assistant "a1" is stored with `config.configurable = { "model": "gpt-4o", "temperature": 0.7 }`. A `POST /threads/t1/runs { assistant_id: "a1", config: { configurable: { "model": "claude-opus-4-5" } } }` arrives with a run-level `configurable` that carries only `"model"`.
**Expected behavior:** The effective `configurable` used by the executor is `{ "model": "claude-opus-4-5", "temperature": 0.7 }`. Run-level key `"model"` wins over the assistant-stored value; key `"temperature"` is absent from the run-level map so the assistant-stored value is retained. Merge is at the top-level key of the `configurable` map (not a recursive deep-merge of values). Authority: BC-2.12.003 §Invariants, interface-definitions.md §RunnableConfig — Struct Definition.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `POST /assistants { graph_id: "agent", name: "SOC agent" }` | HTTP 201, `version: 1`, server-generated `assistant_id` | Happy-path create |
| TV-002 | `GET /assistants/<id>` after creation | HTTP 200, Assistant at version 1 | Happy-path read |
| TV-003 | `PATCH /assistants/<id> { metadata: {"env":"prod"} }` | HTTP 200, version 2 with merged metadata; version 1 still in versions list | Version snapshot created |
| TV-004 | `GET /assistants/nonexistent` | HTTP 404 E-SERVER-009 | Not found |
| TV-005 | `DELETE /assistants/<id>` | HTTP 204; `GET` returns 404 | Delete + verification |
| TV-006 | `GET /assistants/<id>/versions` after 2 patches | `[version1, version2, version3]` | Version history |
| TV-007 | `POST /assistants/<id>/set_latest { version: 1 }` | HTTP 200, assistant resolves to version 1 config | Rollback via set_latest |
| TV-008 | Assistant stored with `config.configurable = {"model":"gpt-4o","temperature":0.7}`; run created with `config: { configurable: {"model":"claude-opus-4-5"} }` | Executor receives effective `configurable = {"model":"claude-opus-4-5","temperature":0.7}` | configurable key collision — run key wins, absent keys retained from assistant |

## Verification Properties

_No Kani VP seed required. Integration tests against in-process pregolya-server are sufficient._

## Related BCs

- BC-2.12.001 — sibling: Threads are the durable state containers; Assistants are the reusable config records
- BC-2.12.003 — depends on: Runs reference an Assistant's config at creation time

## Architecture Anchors

- `pregolya-server/src/api/assistants.rs` — Assistant CRUD handlers
- `pregolya-server/src/store/run_store.rs` — `AssistantRecord` and `AssistantVersion` persistence

## Story Anchor

S-1.26

## VP Anchors

S-1.26

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-014 |
| Capability Anchor Justification | CAP-014 ("Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)") per capabilities-p1-p2.md §CAP-014 — this BC implements the Assistant resource CRUD, which is explicitly listed as the second of the four managed resources: "Assistant (named agent config)" |
| L2 Domain Invariants | — |
| DEC Reference | — |
| Risk Source | — |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | I (integration), E2E (end-to-end) |
| Module | pregolya-server |
