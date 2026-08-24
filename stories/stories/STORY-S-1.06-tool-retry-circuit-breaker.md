---
document_type: story
level: ops
story_id: S-1.06
epic_id: E-01
version: "1.2"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.1 (M3/ADR-027/2026-08-24): AC traces re-cited to stable clause anchors."
  - "1.2 (M4/ADR-027/2026-08-24): ADR-027 M4: normalize edge-case citations to stable EC-NNN tag."
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-16/BC-2.16.001.md
  - .factory/specs/behavioral-contracts/ss-16/BC-2.16.002.md
  - .factory/specs/behavioral-contracts/ss-16/BC-2.16.003.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "4e55d07"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.04, S-1.02]
blocks: [S-1.22, S-2.07]
behavioral_contracts: [BC-2.16.001, BC-2.16.002, BC-2.16.003]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-core
subsystems: [SS-16]
estimated_days: 1
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.06: Tool Retry Policy and Circuit Breaker

## Narrative

- **As a** pregolya library user orchestrating tool-calling agents
- **I want to** have a `ToolRetryPolicy` keyed by tool name, a `RetryPolicy` with a global budget, and a `CircuitBreaker` that trips after consecutive failures
- **So that** transient tool failures are automatically retried up to a configured limit, global retry budgets are enforced across all tools in a run, and circuit breakers prevent cascading failures by fast-failing tools that have proven consistently unreliable

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.16.001 | Per-Tool Retry Policy Keyed by tool_name (Not Args Hash) | AC-001..AC-004, AC-013 |
| BC-2.16.002 | Finite global_limit Non-None Default for All Retry Policies | AC-005..AC-007 |
| BC-2.16.003 | Circuit Breaker Trips After Repeated Failure; Prevents Infinite Retry | AC-008..AC-012, AC-014 |

## Acceptance Criteria

### AC-001 (traces to BC-2.16.001 PC-001 and PC-002)
`ToolRetryPolicy` stores per-tool limits keyed by `tool_name: &str` (NOT by args hash). Two tool invocations with identical `tool_name` but different arguments share the same retry counter. Verified by `test_BC_2_16_001_keyed_by_tool_name_only()`.

### AC-002 (traces to BC-2.16.001 PC-005)
When per-tool retry limit is exhausted, the returned error is `Err(PregolyaError { category: POLICY, code: "E-RETRY-001", message: "RetryExhausted: per-tool retry limit for tool '<tool_name>' exhausted after <attempt_limit> attempts", .. })`. Verified by `test_BC_2_16_001_per_tool_limit_exhausted()`.

### AC-003 (traces to BC-2.16.001 EC-003)
Constructing a `ToolRetryPolicy` with `attempt_limit: 0` returns `Err(PregolyaError { category: VAL, code: "E-RETRY-004", message: "InvalidRetryLimit: attempt_limit must be > 0; got 0", .. })`. Verified by `test_BC_2_16_001_zero_limit_construction_error()`.

### AC-004 (traces to BC-2.16.001 INV-004)
The retry dispatch ordering for a tool invocation is: `circuit_breaker.check(tool_name)` → `pre_tool_dispatch` hook → `tool.invoke(args)` → `retry_policy.record(result)`. Circuit breaker check happens BEFORE the tool is invoked; recording happens AFTER. A unit test using mock objects verifies the ordering. Verified by `test_BC_2_16_001_retry_approval_ordering()`.

### AC-005 (traces to BC-2.16.002 PC-001 and PC-002)
`RetryPolicy::default()` constructs with `global_limit: Some(NonZeroU32::new(10).unwrap())`. The `global_limit` field type is `Option<NonZeroU32>` — not `Option<u32>`. `NonZeroU32` prevents silent zero construction. Verified by `test_BC_2_16_002_default_global_limit()`.

### AC-006 (traces to BC-2.16.002 PC-004)
`RetryPolicy::unlimited()` constructs with `global_limit: None` and emits a tracing warn event with `event_type = "retry.unlimited_policy_constructed"`. Verified by `test_BC_2_16_002_unlimited_policy_logs_warn()`.

### AC-007 (traces to BC-2.16.002 PC-005 and PC-006)
When the cumulative retry count across ALL tool invocations in a run exceeds `global_limit`, the error is `Err(PregolyaError { code: "E-RETRY-002", message: "GlobalLimitExhausted: global retry budget of <global_limit> exhausted across all tools in this run", .. })`. The global limit is cumulative — it counts all tool retries, not just one tool's retries. Verified by `test_BC_2_16_002_global_limit_cumulative()`.

### AC-008 (traces to BC-2.16.003 PC-004)
`CircuitBreaker::default()` constructs with `failure_threshold: 5`, `reset_timeout: Duration::from_secs(30)`, and state `CLOSED`. Verified by `test_BC_2_16_003_default_values()`.

### AC-009 (traces to BC-2.16.003 PC-001 and PC-002)
After 5 consecutive failures recorded via `circuit_breaker.record_failure(tool_name)`, `circuit_breaker.check(tool_name)` returns `Err(PregolyaError { code: "E-RETRY-003", message: "CircuitBreakerOpen: tool '<tool_name>' circuit tripped after 5 consecutive failures", .. })` — without invoking the tool. Verified by `test_BC_2_16_003_closed_to_open_after_threshold()`.

### AC-010 (traces to BC-2.16.003 PC-003)
After `reset_timeout` (30s default) has elapsed in OPEN state, the circuit transitions to HALF-OPEN. The next `check` call returns `Ok(())` (probe is allowed). If the probe succeeds (via `record_success`), the circuit returns to CLOSED. If the probe fails, the circuit returns to OPEN and resets the timer. Verified by `test_BC_2_16_003_half_open_probe_success()` and `test_BC_2_16_003_half_open_probe_failure()`.

### AC-011 (traces to BC-2.16.003 PC-005)
`CircuitBreaker::always_closed()` constructs a circuit breaker that never trips and emits a tracing warn with `event_type = "retry.circuit_breaker_disabled"`. Verified by `test_BC_2_16_003_always_closed_logs_warn()`.

### AC-012 (traces to BC-2.16.003 EC-003 — probe failure tracing)
When a HALF-OPEN probe fails, a debug trace event is emitted with `event_type = "retry.circuit_probe_failed"`. Verified by `test_BC_2_16_003_probe_failure_tracing()`.

### AC-013 (traces to BC-2.16.001 PC-003)
Per the NE-09 counter-example documented in BC-2.16.001: per-tool counters are independent. Tool "A" consuming 3 of its 5 retries does NOT affect Tool "B"'s per-tool counter. Only the global `RetryPolicy` counter is shared. Verified by `test_BC_2_16_001_per_tool_counters_independent()`.

### AC-014 (traces to BC-2.16.003 PC-007)
A successful invocation resets the consecutive failure counter for that tool to zero in the `CircuitBreaker`. One success after 4 failures brings the counter back to 0 (not OPEN). Verified by `test_BC_2_16_003_success_resets_consecutive_counter()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `ToolRetryPolicy` | `pregolya-core/src/retry/tool_retry.rs` | effectful (maintains per-tool counters; shared state) |
| `RetryPolicy` | `pregolya-core/src/retry/global_policy.rs` | effectful (global cumulative counter) |
| `CircuitBreaker` | `pregolya-core/src/retry/circuit_breaker.rs` | effectful (state machine; timer; shared state) |
| Module root | `pregolya-core/src/retry/mod.rs` | re-export-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/retry/tool_retry.rs` | effectful | Maintains mutable per-tool counters across invocations; state shared across calls. Uses `Mutex` or `Arc<AtomicU32>`. |
| `pregolya-core/src/retry/circuit_breaker.rs` | effectful | Three-state machine (`CLOSED`/`OPEN`/`HALF-OPEN`) with timer. Uses `Instant` for reset_timeout; tokio-independent (std::time). |
| `pregolya-core/src/retry/global_policy.rs` | effectful | Cumulative global counter shared across tool dispatches. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Circuit HALF-OPEN: second concurrent probe attempt | Only one probe in-flight at a time; second caller is blocked (returns OPEN error or awaits) |
| EC-002 | Per-tool limit = 1 (exactly one attempt allowed, no retries) | First failure immediately returns E-RETRY-001; no retries |
| EC-003 | Global limit = 1 shared across two tools | First retry on either tool exhausts the budget; second tool retry returns E-RETRY-002 |
| EC-004 | reset_timeout = Duration::ZERO | Circuit immediately moves to HALF-OPEN after tripping; probe on next check |
| EC-005 | `always_closed` circuit with 1000 consecutive failures | Never trips; always returns Ok; warning logged once at construction |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,200 |
| BC-2.16.001.md (~200 lines) | ~3,000 |
| BC-2.16.002.md (~180 lines) | ~2,700 |
| BC-2.16.003.md (~210 lines) | ~3,200 |
| `module-decomposition.md` (SS-16 section) | ~500 |
| `retry/` files (~90 lines each × 3 files) | ~3,900 |
| Test files (~130 lines) | ~1,950 |
| Tool outputs | ~500 |
| **Total** | **~18,950** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~9%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-014 (test-writer)
2. [ ] Verify Red Gate
3. [ ] Create `pregolya-core/src/retry/mod.rs` — re-exports only
4. [ ] Create `pregolya-core/src/retry/tool_retry.rs` — `ToolRetryPolicy` keyed by `tool_name` with `NonZeroU32` limit
5. [ ] Create `pregolya-core/src/retry/global_policy.rs` — `RetryPolicy` with `global_limit: Option<NonZeroU32>` and cumulative counter
6. [ ] Create `pregolya-core/src/retry/circuit_breaker.rs` — three-state machine with `failure_threshold`, `reset_timeout`, and probe semantics
7. [ ] Implement `CircuitBreaker::always_closed()` with `tracing::warn!(event_type = "retry.circuit_breaker_disabled")`
8. [ ] Implement `RetryPolicy::unlimited()` with `tracing::warn!(event_type = "retry.unlimited_policy_constructed")`
9. [ ] Implement HALF-OPEN probe logic: probe failure → `tracing::debug!(event_type = "retry.circuit_probe_failed")`
10. [ ] Implement E-RETRY-001, E-RETRY-002, E-RETRY-003, E-RETRY-004 error constructions
11. [ ] Add `pub mod retry;` to `pregolya-core/src/lib.rs`
12. [ ] Register new tracing event types in Canonical Structured Event Catalog (`.factory/specs/prd-supplements/observability.md`)
13. [ ] Run `cargo nextest run -p pregolya-core` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-1.04 established the `Runnable` trait and `DynRunnable`. S-1.06's retry machinery operates at a level ABOVE `Runnable::invoke` — the retry loop calls `Runnable::invoke` repeatedly. The `ToolRetryPolicy` and `CircuitBreaker` are clients of the `Runnable` abstraction, not implementors.

S-1.02 established that `reqwest::Client` always has a 30s timeout mapped to E-PROV-002. S-1.06 retry logic must NOT wrap timeout errors in retry — `RetryHint::Never` on timeout (unless the RetryHint is explicitly `Maybe` or `Later`). The retry policy respects the `RetryHint` on the `PregolyaError` returned by the tool.

The three new tracing events `retry.circuit_breaker_disabled`, `retry.unlimited_policy_constructed`, `retry.circuit_probe_failed` require Canonical Structured Event Catalog entries per SAP-1 (standing adversary probe). Register them in the same commit as the code that emits them.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `retry/mod.rs` is re-export-only | CLAUDE.md Code Conventions | Code review |
| `global_limit: Option<NonZeroU32>` (not `Option<u32>`) | BC-2.16.002 PC-002 | Type signature; static assertion |
| Retry ordering: circuit_breaker.check → pre_tool → invoke → record | BC-2.16.001 INV-004 | Mock ordering test |
| All three tracing events registered in catalog before PR merges | SAP-1 standing probe | Adversary grep check |
| `reset_timeout` uses `std::time::Duration`/`std::time::Instant` (not tokio::time) | Architecture decision | `cargo tree` for retry module must not show tokio under circuit_breaker.rs |

**Forbidden dependencies for `pregolya-core/src/retry/circuit_breaker.rs`:** `tokio` (use `std::time::Instant` for timer). The circuit breaker is a pure state machine; time measurement uses std.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `std::num::NonZeroU32` | stdlib | Type-safe non-zero limit for `RetryPolicy` |
| `std::time::{Duration, Instant}` | stdlib | Reset timeout tracking in `CircuitBreaker` |
| `tracing` | workspace pin | `warn!` and `debug!` for policy construction and probe events |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/retry/mod.rs` | CREATE | Re-export-only module root |
| `pregolya-core/src/retry/tool_retry.rs` | CREATE | `ToolRetryPolicy` |
| `pregolya-core/src/retry/global_policy.rs` | CREATE | `RetryPolicy` with global budget |
| `pregolya-core/src/retry/circuit_breaker.rs` | CREATE | `CircuitBreaker` state machine |
| `pregolya-core/src/lib.rs` | MODIFY | Add `pub mod retry;` |
| `.factory/specs/prd-supplements/observability.md` | MODIFY | Add catalog rows for `retry.circuit_breaker_disabled`, `retry.unlimited_policy_constructed`, `retry.circuit_probe_failed` |
