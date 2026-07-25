---
document_type: prd-supplement-observability
level: L3
version: "1.4"
status: active
producer: product-owner
timestamp: 2026-07-25T00:00:00Z
phase: 1d
changelog:
  - "1.4 (FIX-BURST-263/F-P162-02/2026-07-25): TD-VSDD-060 full emitting-crate sweep — 11 active + 1 retired rows audited against each anchor BC's Architecture Anchors + module-decomposition. Two mis-anchors found and fixed: (1) F-P162-02 (MED): guardrail.unregistered_passthrough Emitting Crate/Module corrected from 'ferrochain-core / guardrail dispatch layer' to 'ferrochain-graph / graph::provenance' — BC-2.11.006 Architecture Anchors explicitly name graph::provenance (ferrochain-graph, SS-11) as the WARN dispatch site and mark core::guardrail as definitions-only ('None hook-slot handled by graph::provenance WARN logic'); module-decomposition line §ferrochain-graph confirms 'graph::provenance | ProvenanceTag attachment at ingress boundaries, GuardrailHook dispatch | HIGH | SS-11'; core::guardrail note confirms 'dispatch modules (graph::provenance, mcp::ingress) import from ferrochain-core'. ferrochain-mcp / tools.rs (conditional MCP branch per BC-2.09.003 PC4) unchanged. Field Schema Details block: no crate/module named — no change. (2) sandbox.process_no_isolation_execute Emitting Crate/Module corrected from 'ferrochain-sandbox / process_backend.rs' to 'ferrochain-sandbox / sandbox::process' — 'process_backend.rs' appears in no authority source; BC-2.13.002 Architecture Anchor cites 'sandbox::process row' in module-decomposition; module-decomposition row label is 'sandbox::process' (no file-path override given). All other 9 active rows verified CLEAN. Retired row (ferrochain.mcp.guardrail.unregistered) carries stale emitting-crate text in strikethrough — not corrected (historical tombstone; no production surface)."
  - "1.3 (burst-259/F-P158-01+F-P158-02/2026-07-24): (1) F-P158-01: retry.circuit_breaker_disabled — drop tool_name from field schema. CircuitBreaker::always_closed() is a zero-argument constructor; tool association happens at ToolRetryPolicy bind time, after construction. Schema now matches sibling retry.unlimited_policy_constructed (event_type: &str only). Catalog table Audit Role updated to 'at construction time' (tool-agnostic). Field Schema Details: code snippet and table updated. Option (b) adjudicated over (a)/(c): construction-time WARN is the correct catch point; bind-time would require architectural plumbing through a constructor that accepts no arguments. (2) F-P158-02: server.cron_schedule_queue_full Trigger Condition aligned from 'exceeds' (>) to 'meets or exceeds' (>=) — consistent with Recurrence column which already stated '>= max_queue_depth'."
  - "1.2 (burst-258/F-P157-01/2026-07-24): Full prose-emission sweep across all 129 BCs. (1) Add 5 new catalog entries from 4 BCs: retry.unlimited_policy_constructed (BC-2.16.002), retry.circuit_breaker_disabled (BC-2.16.003), retry.circuit_probe_failed (BC-2.16.003), server.cron_schedule_queue_full (BC-2.12.004), eval.judge_infra_error (BC-2.08.008). (2) All 4 BCs updated with canonical event_type literals in emission prose (BC versions bumped per Form-A). (3) 6 sweep entries adjudicated as NOT-A-STRUCTURED-EMISSION with explicit exemption notes in scope section. (4) Active count 6 → 11."
  - "1.1 (burst-226/F-P131-02+F-P131-03/2026-07-21): (1) Retire ferrochain.mcp.guardrail.unregistered — replaced by canonical guardrail.unregistered_passthrough (item-4 adjudication; BC-2.09.003 v1.2 + BC-2.11.006 v1.2 unified). (2) Add 5 new catalog entries: guardrail.unregistered_passthrough (canonical no-hook passthrough), sandbox.process_no_isolation_execute (BC-2.13.002), server.rate_limit_store_in_memory (BC-2.12.006), memory.gdpr_unattributed_session_entries (BC-2.15.003), server.security_config_cors_wildcard (BC-2.12.005). (3) Census methodology upgraded: prose-emission sweep supplements token-grep; 6 active event_type values (1 retired). (4) Inputs expanded to include all emitting BC files."
  - "1.0 (F-P130-06/2026-07-21): Initial Canonical Structured Event Catalog created. Census: grep `event_type =` across all of .factory/specs/behavioral-contracts/ and .factory/specs/architecture/. Total: 2 distinct event_type values found. SAP-1 standing probe policy stated. New emission sites require a same-commit catalog row per SAP-1 (CLAUDE.md §Standing Adversary Probes)."
inputs:
  - .factory/specs/behavioral-contracts/ss-22/BC-2.22.002.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.003.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.006.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.002.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.006.md
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.003.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.005.md
  - .factory/specs/behavioral-contracts/ss-16/BC-2.16.002.md
  - .factory/specs/behavioral-contracts/ss-16/BC-2.16.003.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.004.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.008.md
input-hash: "7ce6fb8"
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

**v1.2 (burst-258 full sweep):** Full prose-emission sweep re-run across all 129 BCs. 5 new emission sites found across 4 BCs; all 4 BCs updated with canonical `event_type` literals. 6 sweep matches were adjudicated as non-catalog entries — see Scope/Exemptions section below for rationale.

**Current active event_type count: 11** (1 retired entry below; 5 added in v1.2)

---

## Catalog

| event_type | Status | Log Level | Emitting Crate / Module | Emitting BC | Trigger Condition | Field Schema | Audit Role | Recurrence Policy |
|------------|--------|-----------|------------------------|-------------|-------------------|--------------|------------|-------------------|
| `embeddings.legacy_model_warning` | active | `WARN` | `ferrochain-openai` / `openai::embeddings` | BC-2.22.002 PC3, EC-002 | `EmbeddingsOpenAI` constructed with model name `"text-embedding-ada-002"` (superseded legacy model) | `event_type: &str`, `model: &str` (= `"text-embedding-ada-002"`) | Warn operator/user that a legacy embedding model was selected; the ada-002 model is still supported by OpenAI but superseded by the 3-series (`text-embedding-3-small`, `text-embedding-3-large`). Enables proactive migration planning. | Once per `EmbeddingsOpenAI` construction — NOT once per API call. Multiple calls on the same instance do not re-emit. |
| ~~`ferrochain.mcp.guardrail.unregistered`~~ | **RETIRED** (replaced by `guardrail.unregistered_passthrough`, burst-226) | ~~`WARN`~~ | ~~`ferrochain-core` / guardrail dispatch layer~~ | ~~BC-2.09.003 PC4 (pre-v1.2)~~ | Retired | — | — | — |
| `guardrail.unregistered_passthrough` | active | `WARN` | `ferrochain-graph` / `graph::provenance`; `ferrochain-mcp` / `tools.rs` (conditional MCP branch per BC-2.09.003 PC4) | BC-2.11.006 PC2, BC-2.09.003 PC4 | An ingress boundary crossing (ToolResult, RAGRetrieval, or MemoryIngress) occurs with no `GuardrailHook` registered in the `InvocationContext` (OQR-5 default-permit path) | Required fields: `event_type: &str`, `boundary_type: &str` ("ToolResult"\|"RAGRetrieval"\|"MemoryIngress"), `ingress_id: Uuid`, `item_count: usize`, `timestamp: DateTime<Utc>`. Conditional (ToolResult from MCP only): `server_name: &str`, `tool_name: &str` | Security observability: signals that content entered model context without guardrail evaluation. Supports automated alerting on unguarded ingress paths. ONE log line per boundary crossing event. Replaces `ferrochain.mcp.guardrail.unregistered` with a unified schema covering all three ingress boundary types. | Per boundary crossing event. High-frequency if application consistently lacks a GuardrailHook — this is intentional (repetition motivates hook registration). |
| `sandbox.process_no_isolation_execute` | active | `WARN` | `ferrochain-sandbox` / `sandbox::process` | BC-2.13.002 PC1, VP-2.13.002-A | `ProcessBackend::execute()` is called — every invocation emits this WARN (the process backend provides no isolation) | `event_type: &str` | Security observability: warns operator that code is running without filesystem isolation, network isolation, or memory bounds. Every execute() call emits this — the repetition is intentional to surface the risk in production logs. | Per `ProcessBackend::execute()` call — NOT once at startup. Every invocation emits. |
| `server.rate_limit_store_in_memory` | active | `WARN` | `ferrochain-server` / server init | BC-2.12.006 EC-005, Invariants | Server startup when no distributed `RateLimitStore` is configured (in-memory backend selected) | `event_type: &str`, `backend: &str` (= `"in_memory"`) | Operator signal: in-memory rate limiting is not coordinated across multiple server instances. Motivates configuration of a distributed backend (Redis/Postgres) for production multi-instance deployments. | Once per server startup. |
| `memory.gdpr_unattributed_session_entries` | active | `WARN` | `ferrochain-memory` / `gdpr.rs` | BC-2.15.003 EC-004 | GDPR erasure for a user finds session entries that predate `session_id → user_id` tracking (no attribution available) | `event_type: &str`, `user_id: &str`, `unattributed_session_count: usize` | Compliance observability: operator signal that some session entries could not be attributed to the erased user. Entries are NOT deleted (per documented limitation). Enables operator audit of data gaps. | Per GDPR erasure request where `unattributed_session_count > 0`. |
| `server.security_config_cors_wildcard` | active | `WARN` | `ferrochain-server` / server init | BC-2.12.005 EC-003, Invariants | Server startup with `SecurityConfig { allowed_origins: [AllowOrigin::Any] }` (CORS wildcard) | `event_type: &str` | Security observability: CORS wildcard is acceptable for local development but is a misconfiguration in production. Fires on every startup to ensure the warning is visible across restarts and CI runs. | Once per server startup when CORS wildcard is configured. |
| `retry.unlimited_policy_constructed` | active | `WARN` | `ferrochain-core` / `retry::policy` | BC-2.16.002 PC4, EC-003 | `RetryPolicy::unlimited()` constructed | `event_type: &str` | Warn developer/operator that a `RetryPolicy` with no global retry bound (`global_limit: None`) was constructed. `None` global limit provides no termination guarantee regardless of per-tool limits (NE-09). Motivates review: is the unlimited policy intentional or accidental? | Once per `RetryPolicy::unlimited()` construction — NOT once per run that uses the policy. |
| `retry.circuit_breaker_disabled` | active | `WARN` | `ferrochain-core` / `retry::circuit_breaker` | BC-2.16.003 PC5, EC-005 | `CircuitBreaker::always_closed()` constructed | `event_type: &str` | Warn developer/operator that circuit protection was explicitly disabled at construction time. The circuit breaker provides a third independent termination layer preventing infinite retry (NE-09); `always_closed()` bypasses it. Motivates review: is disabling the circuit breaker intentional or a test-only construct leaked to production? | Once per `CircuitBreaker::always_closed()` construction. |
| `retry.circuit_probe_failed` | active | `DEBUG` | `ferrochain-core` / `retry::circuit_breaker` | BC-2.16.003 EC-003 | HALF-OPEN probe call for a tool fails; circuit returns to OPEN | `event_type: &str`, `tool_name: &str` | Diagnostic signal: the circuit breaker attempted to recover from OPEN state via a probe call, but the probe failed. Circuit re-enters OPEN with `reset_timeout` restarted. Supports tracing circuit state machine transitions during incident investigation and integration testing. | Per failed HALF-OPEN probe attempt — distinct from CLOSED→OPEN transitions (no event_type emitted on initial trip). |
| `server.cron_schedule_queue_full` | active | `WARN` | `ferrochain-server` / `scheduler` | BC-2.12.004 EC-004 | Schedule fires when run queue depth meets or exceeds `max_queue_depth` | `event_type: &str`, `cron_id: Uuid`, `queue_depth: usize` | Operator signal that a scheduled run firing was skipped due to run queue saturation. Enables back-pressure monitoring and alerting on schedule overload. Repeated firing indicates the schedule interval is too short relative to run completion time; operator should increase interval or max_queue_depth. | Per schedule firing skip when `queue_depth >= max_queue_depth`. |
| `eval.judge_infra_error` | active | `WARN` | `ferrochain-standard-tests` / `eval::judge` | BC-2.08.008 PC3 | `JudgeResult::InfraError` returned for an eval case (judge LLM unavailable, timeout, or unparseable response) | `event_type: &str`, `reason: &str` | Signals judge infrastructure failure for a specific eval case, distinguishing it from a quality failure. Prevents false quality alarms when the judge LLM is degraded. `InfraError` cases are excluded from aggregate eval score per BC-2.08.008 PC3. | Per eval case where `JudgeResult::InfraError` is returned. |

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

### `retry.unlimited_policy_constructed`

```rust
tracing::warn!(
    event_type = "retry.unlimited_policy_constructed",
    "RetryPolicy::unlimited() constructed — no global retry bound; only use in tests or controlled environments"
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"retry.unlimited_policy_constructed"` |

### `retry.circuit_breaker_disabled`

```rust
tracing::warn!(
    event_type = "retry.circuit_breaker_disabled",
    "CircuitBreaker::always_closed() constructed — circuit protection disabled; only use in tests or controlled environments"
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"retry.circuit_breaker_disabled"` |

### `retry.circuit_probe_failed`

```rust
tracing::debug!(
    event_type = "retry.circuit_probe_failed",
    tool_name = %tool_name,
    "circuit probe for tool '{}' failed; returning to OPEN", tool_name
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"retry.circuit_probe_failed"` |
| `tool_name` | `&str` (Display) | The tool name whose HALF-OPEN probe call failed |

### `server.cron_schedule_queue_full`

```rust
tracing::warn!(
    event_type = "server.cron_schedule_queue_full",
    cron_id = %cron_id,
    queue_depth = queue_depth,
    "CronSchedule {}: firing skipped — run queue full at depth {}", cron_id, queue_depth
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"server.cron_schedule_queue_full"` |
| `cron_id` | `Uuid` (Display) | The cron schedule ID whose firing was skipped |
| `queue_depth` | `usize` | Current run queue depth at the time of the firing skip (= or > `max_queue_depth`) |

### `eval.judge_infra_error`

```rust
tracing::warn!(
    event_type = "eval.judge_infra_error",
    reason = %reason,
    "eval judge infrastructure error: {}", reason
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"eval.judge_infra_error"` |
| `reason` | `&str` (Display) | The `reason` field from `JudgeResult::InfraError { reason }` — describes the specific infrastructure failure (e.g., "judge LLM returned non-parseable response: ...", "timeout after 30s") |

---

## Scope and Non-Emission Exemptions

The catalog covers `tracing::*!(event_type = "...")` structured emissions that are mandated by BC postconditions or edge cases. The v1.2 full-sweep found the following BC references that the grep matched but are NOT catalog entries:

| BC | Matched Phrase | Classification | Rationale |
|----|----------------|----------------|-----------|
| BC-2.06.003 TV-005 | "streaming emits error event" | NOT-A-STRUCTURED-EMISSION | TV test scenario prose describing how a budget-halt error appears in a test vector; not a `tracing::*!` call mandate |
| BC-2.10.001 TV-005 | "structured error from the sub-agent run" | NOT-A-STRUCTURED-EMISSION | `structured error` refers to `FerrochainError` return type, not a tracing emission |
| BC-2.11.001 §Related BCs | "WARNING LOG emission per boundary crossing" | NOT-A-NEW-EMISSION | Cross-reference to BC-2.11.006's already-cataloged `guardrail.unregistered_passthrough` emission; no independent emission |
| BC-2.13.006 EC-003 | "standard process-backend WARN log (BC-2.13.002) is emitted" | NOT-A-NEW-EMISSION | Cross-reference to BC-2.13.002's already-cataloged `sandbox.process_no_isolation_execute` emission; no independent emission |
| BC-2.14.005 EC-003 | `tracing::debug!("{:?}", api_key)` | NOT-A-STRUCTURED-EMISSION | This is a **test scenario** showing what a caller does when logging a key type; the BC describes the behavior of the `Debug` impl (`"<redacted>"`). The caller's debug call is not a mandated BC emission — it is the input to the test. |
| BC-2.15.004 TV-008 | "structured error (DI-014)" | NOT-A-STRUCTURED-EMISSION | `structured error` refers to `FerrochainError` propagation, not a tracing emission |

These adjudications are stable: a fresh-context adversarial pass seeing these entries in the table should treat them as resolved, not as gaps.

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
