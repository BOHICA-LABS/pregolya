---
document_type: behavioral-contract
level: L3
bc_id: BC-2.16.002
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P2
subsystem: SS-16
capability: CAP-018
wave: Post-v1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-018
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
input-hash: "b8d6b656a36659b344bb8d6b676d6c2862676124b4eb61e645298dca3360aa89"
---

# BC-2.16.002: Finite global_limit Non-None Default for All Retry Policies

## Description

Every `RetryPolicy` constructed in ferrochain — whether per-tool or global — must carry a
finite, non-zero `global_limit`. The adk-rust P-63 pattern of defaulting `global_limit` to
`None` (unlimited) is REJECTed per NE-09 because an unlimited global limit provides no
termination guarantee regardless of per-tool limits. The default constructor must produce a
`global_limit: Some(NonZeroU32)` value; the only way to construct an unlimited policy is via
an explicit `RetryPolicy::unlimited()` method that emits a diagnostic warning.

## Preconditions

1. A `RetryPolicy` or `ToolRetryPolicy` is being constructed (via `Default`, builder, or
   explicit constructor).
2. The ferrochain-core retry combinator crate is in scope.

## Postconditions

1. `RetryPolicy::default()` produces a policy with `global_limit: Some(NonZeroU32::new(10).unwrap())`
   (or another specific finite value set by the architect; exact default must be documented
   in the struct's rustdoc and must be `>= 3`).
2. The `global_limit` field type is `Option<NonZeroU32>` — not `Option<u32>`. The `NonZeroU32`
   wrapper prevents silent construction of a zero-limit policy via the `Some(0)` path.
3. `RetryPolicy::new(global_limit: NonZeroU32)` accepts only non-zero values by construction;
   the type system enforces this without runtime checks.
4. `RetryPolicy::unlimited()` is the only constructor that produces `global_limit: None`.
   It emits a `tracing::warn!` at construction time with the message:
   `"RetryPolicy::unlimited() constructed — no global retry bound; only use in tests or controlled environments"`.
5. When the global limit across all tool calls in a single run is exhausted,
   the combinator returns `Err(FerrochainError { component: RETRY, category: POLICY,
   code: E-RETRY-002, retry_hint: Never })` and halts further tool invocations for
   the current run.
6. The global limit applies cumulatively across all tool types in a run; it is not
   reset per-tool. A run with three tools each having `attempt_limit=5` and
   `global_limit=Some(8)` stops after 8 total failures across all tools.

## Invariants

- **Finite-by-default (NE-09):** The zero-argument constructor MUST produce a finite limit.
  Any future refactoring that changes `default()` to produce `None` must fail a CI contract
  test.
- **NonZeroU32 gate:** The type-level constraint (NonZeroU32) replaces a runtime check.
  No `assert!` or `if limit == 0 { panic!(...) }` is needed or permitted in library code
  (per DI-008).
- Global limit is scoped to a single graph run. It does not accumulate across
  checkpoint restores or resumed runs.

## Edge Cases

### EC-001: global_limit Reached Before per-tool Limit
**Scenario:** A run has three tools. Tool `A` fails 4 times, tool `B` fails 4 times.
`global_limit = Some(8)`. Tool `B`'s per-tool limit is 10.
**Expected behavior:** After 8 total failures (4+4), the global limit is reached and
`E-RETRY-002` is returned. Tool `B` stops even though its per-tool limit (10) is not hit.
Global limit wins.

### EC-002: Default Policy in Production Code
**Scenario:** A caller does `RetryPolicy::default()` without reading the docs.
**Expected behavior:** The policy has `global_limit = Some(10)` (or the documented default).
The caller is protected from infinite retry without any extra configuration.

### EC-003: RetryPolicy::unlimited() Warning
**Scenario:** Test code calls `RetryPolicy::unlimited()`.
**Expected behavior:** The policy is constructed successfully with `global_limit: None`. A
`tracing::warn!` is emitted. Tests that capture tracing output should expect the warning
message to appear.

### EC-004: Builder Override to Lower Limit
**Scenario:** A caller does `RetryPolicy::default().with_global_limit(NonZeroU32::new(3).unwrap())`.
**Expected behavior:** The resulting policy has `global_limit = Some(3)`. The default is
overridden cleanly. No warning is emitted (3 is a finite value).

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `RetryPolicy::default()` | `global_limit == Some(NonZeroU32 >= 3)` | Finite-by-default |
| TV-002 | `RetryPolicy::unlimited()` | `global_limit == None`; tracing warn emitted | Unlimited requires explicit opt-in |
| TV-003 | Run with 3 tools; 8 total failures; `global_limit = 8` | `Err(E-RETRY-002)` after 8th failure; run halted | Global cap fires |
| TV-004 | `RetryPolicy::new(global_limit: NonZeroU32)` with value 1 | Policy with `global_limit = Some(1)` | Minimum valid limit |
| TV-005 | `RetryPolicy::default().with_global_limit(3_NonZeroU32)` | `global_limit = Some(3)` | Builder override |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC216002-01 | `RetryPolicy::default().global_limit` is `Some(_)` and not `None` | Unit test (compile + runtime assertion) | Post-v1 |
| VP-BC216002-02 | A run exceeding global_limit halts regardless of per-tool state | Integration test (multi-tool run) | Post-v1 |

## Related BCs

- BC-2.16.001 — Per-tool retry key (composes with: global_limit is the outer bound; per-tool limit is the inner bound)
- BC-2.16.003 — Circuit breaker (composes with: circuit breaker fires independently of global_limit; both can halt a run)

## Architecture Anchors

- `ferrochain-core/src/retry/policy.rs` — `RetryPolicy` struct with `global_limit: Option<NonZeroU32>` field (to be created)
- `ferrochain-core/src/retry/combinator.rs` — global limit counter logic (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC216002-01, VP-BC216002-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-018 |
| Capability Anchor Justification | CAP-018 ("Tool Retry with Circuit Breaker") per capabilities-p1-p2.md §CAP-018 — this BC encodes the second NE-09 clause: "finite global_limit non-None default", directly addressing the P-63 termination hole where `global_limit: None` made per-tool limits illusory |
| L2 Domain Invariants | — |
| NE References | NE-09 (P-63 REJECT — None global limit), P-71 (ADOPT — shared combinator carries the global counter) |
| FM References | FM-012 (Tool-Retry Loops Forever) |
| Priority | P2 |
| Wave | Post-v1 |
| Test Types | U (unit), I (integration) |
| Module | [architect to assign — ferrochain-core] |
| Note | Error codes E-RETRY-002 requires addition to error-taxonomy.md Component: RETRY |
