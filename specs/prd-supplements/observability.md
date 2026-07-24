---
document_type: prd-supplement-observability
level: L3
version: "1.1"
status: active
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
phase: 1d
changelog:
  - "1.0 (F-P130-06/2026-07-21): Initial Canonical Structured Event Catalog created. Census: grep `event_type =` across all of .factory/specs/behavioral-contracts/ and .factory/specs/architecture/. Total: 2 distinct event_type values found. SAP-1 standing probe policy stated. New emission sites require a same-commit catalog row per SAP-1 (CLAUDE.md §Standing Adversary Probes)."
  - "1.1 (burst-226/F-P131-02+F-P131-03/2026-07-21): (1) Retire ferrochain.mcp.guardrail.unregistered — replaced by canonical guardrail.unregistered_passthrough (item-4 adjudication; BC-2.09.003 v1.2 + BC-2.11.006 v1.2 unified). (2) Add 5 new catalog entries: guardrail.unregistered_passthrough (canonical no-hook passthrough), sandbox.process_no_isolation_execute (BC-2.13.002), server.rate_limit_store_in_memory (BC-2.12.006), memory.gdpr_unattributed_session_entries (BC-2.15.003), server.security_config_cors_wildcard (BC-2.12.005). (3) Census methodology upgraded: prose-emission sweep supplements token-grep; 6 active event_type values (1 retired). (4) Inputs expanded to include all emitting BC files."
inputs:
  - .factory/specs/behavioral-contracts/ss-22/BC-2.22.002.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.003.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.006.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.002.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.006.md
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.003.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.005.md
input-hash: "0699840"
---

# Canonical Structured Event Catalog

## SAP-1 Policy — New Emission Sites Require Same-Commit Catalog Row

Per CLAUDE.md §Standing Adversary Probes (SAP-1):

> For EVERY adversarial pass on stories or PRs touching `crates/**/*.rs`:
> 1. Grep `event_type =` across the entire `crates/` workspace: `rg 'event_type\s*=' crates/ --type rust`
> 2. For each `event_type` value found, verify a corresponding row exists in this catalog with full field schema, audit role, and recurrence policy.
> 3. Tracing emission WITHOUT a catalog row = **P1 finding**.
> 4. Same-commit catalog row required for emissions added in the branch.
> 5. Removal of an emission does NOT require a new catalog row.

**Every implementer adding a `tracing::*!(event_type = "...")` call to any `crates/` file MUST add a corresponding row to this catalog in the same commit.**

---

## Census Methodology

**v1.0 (initial):** The catalog was seeded by grepping `event_type` across all BC files and architecture docs:

```bash
grep -r "event_type" .factory/specs/behavioral-contracts/ .factory/specs/architecture/
```

**v1.1 (burst-226 upgrade):** Prose-emission sweep added. Some BC-mandated emissions are described in prose (e.g., "a WARN log is emitted with...") but do not use the `event_type` token — the token-grep misses these. The prose-emission sweep also searches for `WARN`/`WARNING`/`log.*emitted` patterns in BC postconditions and edge cases, then identifies mandated structured emissions and assigns canonical `event_type` values.

**Current active event_type count: 6** (1 retired entry below)

---

## Catalog

| event_type | Status | Log Level | Emitting Crate / Module | Emitting BC | Trigger Condition | Field Schema | Audit Role | Recurrence Policy |
|------------|--------|-----------|------------------------|-------------|-------------------|--------------|------------|-------------------|
| `embeddings.legacy_model_warning` | active | `WARN` | `ferrochain-openai` / `openai::embeddings` | BC-2.22.002 PC3, EC-002 | `EmbeddingsOpenAI` constructed with model name `"text-embedding-ada-002"` (superseded legacy model) | `event_type: &str`, `model: &str` (= `"text-embedding-ada-002"`) | Warn operator/user that a legacy embedding model was selected; the ada-002 model is still supported by OpenAI but superseded by the 3-series (`text-embedding-3-small`, `text-embedding-3-large`). Enables proactive migration planning. | Once per `EmbeddingsOpenAI` construction — NOT once per API call. Multiple calls on the same instance do not re-emit. |
| ~~`ferrochain.mcp.guardrail.unregistered`~~ | **RETIRED** (replaced by `guardrail.unregistered_passthrough`, burst-226) | ~~`WARN`~~ | ~~`ferrochain-core` / guardrail dispatch layer~~ | ~~BC-2.09.003 PC4 (pre-v1.2)~~ | Retired | — | — | — |
| `guardrail.unregistered_passthrough` | active | `WARN` | `ferrochain-core` / guardrail dispatch layer; `ferrochain-mcp` / `tools.rs` | BC-2.11.006 PC2, BC-2.09.003 PC4 | An ingress boundary crossing (ToolResult, RAGRetrieval, or MemoryIngress) occurs with no `GuardrailHook` registered in the `InvocationContext` (OQR-5 default-permit path) | Required fields: `event_type: &str`, `boundary_type: &str` ("ToolResult"\|"RAGRetrieval"\|"MemoryIngress"), `ingress_id: Uuid`, `item_count: usize`, `timestamp: DateTime<Utc>`. Conditional (ToolResult from MCP only): `server_name: &str`, `tool_name: &str` | Security observability: signals that content entered model context without guardrail evaluation. Supports automated alerting on unguarded ingress paths. ONE log line per boundary crossing event. Replaces `ferrochain.mcp.guardrail.unregistered` with a unified schema covering all three ingress boundary types. | Per boundary crossing event. High-frequency if application consistently lacks a GuardrailHook — this is intentional (repetition motivates hook registration). |
| `sandbox.process_no_isolation_execute` | active | `WARN` | `ferrochain-sandbox` / `process_backend.rs` | BC-2.13.002 PC1, VP-2.13.002-A | `ProcessBackend::execute()` is called — every invocation emits this WARN (the process backend provides no isolation) | `event_type: &str` | Security observability: warns operator that code is running without filesystem isolation, network isolation, or memory bounds. Every execute() call emits this — the repetition is intentional to surface the risk in production logs. | Per `ProcessBackend::execute()` call — NOT once at startup. Every invocation emits. |
| `server.rate_limit_store_in_memory` | active | `WARN` | `ferrochain-server` / server init | BC-2.12.006 EC-005, Invariants | Server startup when no distributed `RateLimitStore` is configured (in-memory backend selected) | `event_type: &str`, `backend: &str` (= `"in_memory"`) | Operator signal: in-memory rate limiting is not coordinated across multiple server instances. Motivates configuration of a distributed backend (Redis/Postgres) for production multi-instance deployments. | Once per server startup. |
| `memory.gdpr_unattributed_session_entries` | active | `WARN` | `ferrochain-memory` / `gdpr.rs` | BC-2.15.003 EC-004 | GDPR erasure for a user finds session entries that predate `session_id → user_id` tracking (no attribution available) | `event_type: &str`, `user_id: &str`, `unattributed_session_count: usize` | Compliance observability: operator signal that some session entries could not be attributed to the erased user. Entries are NOT deleted (per documented limitation). Enables operator audit of data gaps. | Per GDPR erasure request where `unattributed_session_count > 0`. |
| `server.security_config_cors_wildcard` | active | `WARN` | `ferrochain-server` / server init | BC-2.12.005 EC-003, Invariants | Server startup with `SecurityConfig { allowed_origins: [AllowOrigin::Any] }` (CORS wildcard) | `event_type: &str` | Security observability: CORS wildcard is acceptable for local development but is a misconfiguration in production. Fires on every startup to ensure the warning is visible across restarts and CI runs. | Once per server startup when CORS wildcard is configured. |

---

## Catalog Table: Field Schema Details

### `embeddings.legacy_model_warning`

```rust
tracing::warn!(
    event_type = "embeddings.legacy_model_warning",
    model = %model_name,  // = "text-embedding-ada-002"
    "legacy embedding model selected; consider upgrading to text-embedding-3-small or text-embedding-3-large"
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"embeddings.legacy_model_warning"` |
| `model` | `&str` (Display) | The legacy model name; currently always `"text-embedding-ada-002"` |

### `guardrail.unregistered_passthrough`

```rust
tracing::warn!(
    event_type = "guardrail.unregistered_passthrough",
    boundary_type = %boundary_type,
    ingress_id = %ingress_id,
    item_count = item_count,
    timestamp = %timestamp,
    // Conditional: only when boundary_type == "ToolResult" from MCP:
    // server_name = %server_name,
    // tool_name = %tool_name,
    "content passed through ingress boundary without guardrail evaluation"
);
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `event_type` | `&'static str` | Always | Always `"guardrail.unregistered_passthrough"` |
| `boundary_type` | `&str` (Display) | Always | One of `"ToolResult"`, `"RAGRetrieval"`, `"MemoryIngress"` |
| `ingress_id` | `Uuid` (Display) | Always | Matches `ProvenanceTag.ingress_id` for the crossing event |
| `item_count` | `usize` | Always | Number of content items in this crossing event |
| `timestamp` | `DateTime<Utc>` (Display) | Always | Crossing event timestamp |
| `server_name` | `&str` (Display) | Conditional | MCP server name — present only for `ToolResult` boundary from MCP |
| `tool_name` | `&str` (Display) | Conditional | MCP tool name — present only for `ToolResult` boundary from MCP |

### `sandbox.process_no_isolation_execute`

```rust
tracing::warn!(
    event_type = "sandbox.process_no_isolation_execute",
    "ProcessBackend: no filesystem isolation, no network isolation, no memory bounds — untrusted code runs with OS-level privileges of the ferrochain process"
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"sandbox.process_no_isolation_execute"` |

### `server.rate_limit_store_in_memory`

```rust
tracing::warn!(
    event_type = "server.rate_limit_store_in_memory",
    backend = "in_memory",
    "RateLimitStore: in-memory backend — rate limits are not coordinated across instances"
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"server.rate_limit_store_in_memory"` |
| `backend` | `&'static str` | Always `"in_memory"` |

### `memory.gdpr_unattributed_session_entries`

```rust
tracing::warn!(
    event_type = "memory.gdpr_unattributed_session_entries",
    user_id = %user_id,
    unattributed_session_count = unattributed_session_count,
    "GDPR erasure: {} session entries could not be attributed to user_id={} due to missing session-user mapping; these entries are NOT deleted",
    unattributed_session_count, user_id
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"memory.gdpr_unattributed_session_entries"` |
| `user_id` | `&str` (Display) | The user_id for which GDPR erasure was requested |
| `unattributed_session_count` | `usize` | Number of session entries that could not be attributed and were NOT deleted |

### `server.security_config_cors_wildcard`

```rust
tracing::warn!(
    event_type = "server.security_config_cors_wildcard",
    "SecurityConfig: CORS wildcard configured — do not use in production"
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"server.security_config_cors_wildcard"` |

---

## Adding a New Emission Site

When adding a new `tracing::*!(event_type = "...")` call in any `crates/` file:

1. Choose a `event_type` string following the `<subsystem>.<event>` naming convention (e.g., `guardrail.unregistered_passthrough`, `sandbox.process_no_isolation_execute`). Legacy entries may use the `ferrochain.` prefix but new entries should use the bare subsystem name.
2. Add a row to this catalog table in the SAME commit, with:
   - All field names and types
   - The emitting BC anchor (cite the BC ID and the precondition/postcondition that mandates the emission)
   - The audit role (why does an operator need this event?)
   - The recurrence policy (once per construction? per call? per invocation?)
3. A PR with a new `event_type` emission but no corresponding catalog row will be blocked by SAP-1 as a P1 finding in adversarial review.
