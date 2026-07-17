---
document_type: behavioral-contract
level: L3
bc_id: BC-2.16.003
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P2
subsystem: SS-16
capability: CAP-018
wave: 2
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-core per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-018
  - domain-spec/failure-modes.md#FM-012
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/failure-modes.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "a51ccb9"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.16.003: Circuit Breaker Trips After Repeated Failure; Prevents Infinite Retry

## Description

The ferrochain tool-retry combinator must include a per-tool circuit breaker that trips to
OPEN after a configurable number of consecutive failures for a given tool, immediately
returning an error without invoking the tool. The circuit breaker is ON by default — it
cannot be silently omitted or defaulted to disabled. Combined with BC-2.16.001 (tool_name
keying) and BC-2.16.002 (finite global_limit), the circuit breaker provides a third
independent termination layer that prevents a permanently failing tool from consuming all
retries in the global limit pool.

## Preconditions

1. A `ToolRetryPolicy` includes an associated `CircuitBreaker` configuration (or a default
   one is injected by the combinator).
2. The tool `T` has been invoked at least once within the current run.
3. The circuit breaker for `T` is in CLOSED state (initial state) or HALF-OPEN state.

## Postconditions

1. After `failure_threshold` consecutive failures for tool `T`, the circuit breaker for
   `T` transitions from CLOSED to OPEN state.
2. In OPEN state, any further call to tool `T` returns
   `Err(FerrochainError { component: RETRY, category: POLICY, code: E-RETRY-003,
   retry_hint: Later(reset_timeout), message: "CircuitBreakerOpen: tool '<tool_name>'
   circuit tripped after <failure_threshold> consecutive failures" })` without
   invoking the tool's underlying implementation.
3. The circuit breaker resets to CLOSED (or HALF-OPEN) after `reset_timeout` elapses.
   In HALF-OPEN, one probe call is allowed; if it succeeds, circuit transitions to CLOSED;
   if it fails, circuit returns to OPEN with `reset_timeout` restarted.
4. `CircuitBreaker::default()` is ON with `failure_threshold: 5` and
   `reset_timeout: Duration::from_secs(30)`. Both values are overridable.
5. There is no constructor `CircuitBreaker::disabled()` or `CircuitBreaker::off()`. To
   exclude circuit breaking for a specific tool, the caller must use
   `CircuitBreaker::always_closed()`, which emits a `tracing::warn!` at construction time.
6. Circuit state is per-tool-name and scoped to the current run; it does not persist across
   checkpoint boundaries or cross-run restores.
7. A successful tool invocation resets the consecutive-failure counter for that tool
   (but does not immediately close an OPEN circuit — the reset_timeout must still elapse
   before HALF-OPEN probe is permitted).

## Invariants

- **Circuit breaker on by default (NE-09):** `ToolRetryPolicy::default()` includes a live
  `CircuitBreaker` with finite `failure_threshold`. No opt-out at construction time.
- **Fail-closed semantics:** A circuit in OPEN state returns `E-RETRY-003` immediately —
  it does not silently drop the call or return `Ok(default_value)`.
- **Independent of global_limit (BC-2.16.002):** Circuit breaker fires on consecutive failures
  even if global_limit is not yet exhausted. Both limits are independent and either can halt
  a run.

## Edge Cases

### EC-001: Circuit Trips on Threshold Exact Boundary
**Scenario:** `failure_threshold = 3`. Tool `T` fails 3 consecutive times.
**Expected behavior:** After the 3rd failure, the circuit transitions to OPEN. The 3rd
call still returns the tool's error (not E-RETRY-003). The 4th call returns E-RETRY-003
immediately without invoking the tool.

### EC-002: Success Resets Consecutive-Failure Counter
**Scenario:** Tool `T` fails 2 times (threshold = 3), then succeeds once, then fails 2
more times.
**Expected behavior:** The success on attempt 3 resets the counter to 0. After 2 more
failures (total = 2, not 4), the counter is at 2 and the circuit is still CLOSED.

### EC-003: Half-Open Probe Fails
**Scenario:** Circuit is OPEN for tool `T`. `reset_timeout` elapses. Probe call is made
and fails.
**Expected behavior:** Circuit returns to OPEN with `reset_timeout` restarted from the
failed probe time. A `tracing::debug!` event is emitted: `"circuit probe for tool '<T>'
failed; returning to OPEN"`.

### EC-004: Half-Open Probe Succeeds
**Scenario:** Circuit is OPEN for tool `T`. `reset_timeout` elapses. Probe call succeeds.
**Expected behavior:** Circuit transitions to CLOSED. Subsequent calls invoke the tool
normally with a freshly reset failure counter.

### EC-005: always_closed() Warning
**Scenario:** A caller constructs `CircuitBreaker::always_closed()` to disable the breaker
for a stub tool in testing.
**Expected behavior:** The policy is constructed. A `tracing::warn!` is emitted:
`"CircuitBreaker::always_closed() — circuit protection disabled for tool '<tool_name>'; only use in tests"`.
The tool is always invoked regardless of failure count.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Tool `T` fails `failure_threshold` times consecutively | Circuit transitions to OPEN; next call returns `E-RETRY-003` | Core circuit-trip behavior |
| TV-002 | `CircuitBreaker::default()` | `failure_threshold = 5`, `reset_timeout = 30s`, state = CLOSED | ON by default |
| TV-003 | Tool `T` in OPEN; `reset_timeout` elapses; probe succeeds | Circuit → CLOSED; subsequent calls invoke tool | Half-open recovery |
| TV-004 | Tool `T` in OPEN; probe fails | Circuit stays OPEN; `reset_timeout` restarts | Failure-in-half-open |
| TV-005 | Tool fails twice, succeeds, fails twice; `threshold = 3` | Circuit remains CLOSED throughout | Success resets counter |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC216003-01 | Circuit transitions CLOSED→OPEN after exactly `failure_threshold` consecutive failures | Unit test (state machine) | Post-v1 |
| VP-BC216003-02 | Call to tool in OPEN state returns E-RETRY-003 without invoking implementation | Unit test (mock tool; call count assertion) | Post-v1 |
| VP-BC216003-03 | Half-open → CLOSED on probe success; OPEN on probe failure | Integration test (time-controlled clock) | Post-v1 |

## Related BCs

- BC-2.16.001 — Per-tool retry key (composes with: circuit breaker uses the same tool_name key)
- BC-2.16.002 — Finite global_limit (composes with: both are independent termination layers; circuit breaker does not consume global_limit budget when returning E-RETRY-003 from OPEN state)
- BC-2.09.004 — MCP ToolException (depends on: ToolException is a failing invocation that counts toward failure_threshold)

## Architecture Anchors

- `ferrochain-core/src/retry/circuit_breaker.rs` — `CircuitBreaker` state machine (to be created)
- `ferrochain-core/src/retry/policy.rs` — `ToolRetryPolicy` embeds `CircuitBreaker` (to be created)
- `ferrochain-core/src/retry/combinator.rs` — invokes circuit check before tool call (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC216003-01, VP-BC216003-02, VP-BC216003-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-018 |
| Capability Anchor Justification | CAP-018 ("Tool Retry with Circuit Breaker") per capabilities-p1-p2.md §CAP-018 — this BC encodes the third NE-09 clause: "circuit-breaker on by default", providing the fail-fast termination layer that CAP-018 specifies for permanently-failing tools |
| L2 Domain Invariants | — |
| NE References | NE-09 (P-63 REJECT — termination illusory without circuit breaker) |
| FM References | FM-012 (Tool-Retry Loops Forever — this BC is its primary detection and prevention mechanism) |
| Priority | P2 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-core |
