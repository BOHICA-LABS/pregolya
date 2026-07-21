---
document_type: behavioral-contract
level: L3
bc_id: BC-2.16.001
version: "1.3"
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
  - "1.1 (ADV-P1D-PASS-34): F-P34-02 EC-003 + TV-004 — replace E-RETRY-003 with E-RETRY-004 (InvalidRetryLimit). E-RETRY-003 is CircuitBreakerOpen (BC-2.16.003, POLICY/Later); zero-limit construction rejection is a misconfiguration → VAL, RetryHint Never. New code E-RETRY-004 minted in error-taxonomy.md 1.5."
  - "1.2 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-core per module-decomposition.md v1.10."
  - "1.3 (F-P111-01, 2026-07-18): Gate #33 Form 3 wrapper-form sweep. PC5 had `Err(FerrochainError { component: RETRY, category: POLICY, code: E-RETRY-001, retry_hint: Never })` — bare wrapper missing message field for E-RETRY-001 which has `<tool_name>` and `<attempt_limit>` placeholders. Added `message:` template inline; `<tool_name>` from `ToolRetryPolicy.tool_name`; `<attempt_limit>` from `ToolRetryPolicy.attempt_limit` — both deterministically available at raise site."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-018
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
input-hash: "a20fa83"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.16.001: Per-Tool Retry Policy Keyed by tool_name (Not Args Hash)

## Description

The ferrochain retry combinator (adopted from adk-rust P-71) must key per-tool retry
counters on `(tool_name)` alone — never on `(tool_name, hash(args))`. The args-hash
keying pattern in adk-rust P-63 is explicitly REJECTed because it resets the counter
every time the model changes arguments (which the reflection prompt encourages), making
any configured per-tool limit illusory. Two consecutive calls to the same tool with
different arguments must share the same retry counter.

## Preconditions

1. The caller is constructing a `ToolRetryPolicy` for a named tool `T`.
2. The ferrochain-core crate provides a single shared retry combinator (P-71 ADOPT); no
   per-crate retry loop exists outside this combinator.
3. The tool name is a non-empty ASCII-printable string (e.g., `"web_search"`).

## Postconditions

1. The retry counter key for tool `T` is `tool_name: &str` only; no args-derived component
   appears in the key type or the counter lookup.
2. Two successive invocations of tool `T` with distinct argument values (`args_a` and
   `args_b`) both increment the **same** per-tool counter — not two independent counters.
3. Invocations of two distinct tools `T1` and `T2` maintain fully independent retry
   counters even when `T1.name == T2.name` is false; the counter namespace is flat and
   keyed by name string.
4. The ferrochain-core API exposes no constructor that accepts an args-hash as a retry key;
   such a constructor does not exist in the public surface — the REJECT is structural, not
   just policy.
5. When the per-tool retry limit for `T` is reached, the combinator returns
   `Err(FerrochainError { component: RETRY, category: POLICY, code: E-RETRY-001,
   retry_hint: Never,
   message: "RetryExhausted: per-tool retry limit for tool '<tool_name>' exhausted after <attempt_limit> attempts" })`
   (where `<tool_name>` from `ToolRetryPolicy.tool_name`; `<attempt_limit>` from `ToolRetryPolicy.attempt_limit`)
   without invoking `T` again.
6. The `ToolRetryPolicy` struct carries the tool name string and the per-tool `attempt_limit`
   as named fields; both must be present to construct a policy.

## Invariants

- **No args-hash retry key (P-63 REJECT, NE-09):** The counter key type MUST NOT contain
  any derivative of the tool's argument values. A type-checked enforcement (distinct key type
  that cannot be constructed with args) is preferred over a runtime check.
- The shared retry combinator (P-71 ADOPT) is the **only** retry implementation in
  ferrochain. Partner provider crates route through it; they do not implement their own loops.
- Counter state is per-invocation scope (one graph run) — it does not persist across
  checkpoint boundaries or runs.

## Edge Cases

### EC-001: Argument-Changing Reflection Loop
**Scenario:** The model's reflection prompt causes it to call tool `T` three consecutive
times, each with different arguments (e.g., progressively refined search queries). All
three calls fail.
**Expected behavior:** All three failures increment the same counter keyed on `"T"`. When
`attempt_limit` (e.g., 3) is reached, the combinator stops after the third call and
returns `E-RETRY-001`. The model does NOT receive a fourth attempt by supplying yet another
arg variation.
**Reference:** FM-012, NE-09, COMPARATIVE-ASSESSMENT §P-63 REJECT rationale.

### EC-002: Two Tools Same-Name Collision
**Scenario:** Two independently-registered tools happen to share the same `tool_name`
string. Both are called in the same run.
**Expected behavior:** Counter is shared by name; both calls deplete the same counter.
This is by design — tool_name is the authoritative identity. If this is undesirable, the
caller must register them under distinct names. No silent disambiguation occurs.

### EC-003: Zero-Limit Policy Construction
**Scenario:** A caller attempts to construct `ToolRetryPolicy { attempt_limit: 0 }`.
**Expected behavior:** Construction returns `Err(E-RETRY-004: InvalidRetryLimit)`
(category: VAL, RetryHint: Never — F-P34-02, ADV-P1D-PASS-34). Zero attempts means
the tool is never called; this is a misconfiguration, not a valid policy.

### EC-004: Tool Succeeds on Second Attempt
**Scenario:** Tool `T` fails on attempt 1, then succeeds on attempt 2.
**Expected behavior:** Counter resets (or is irrelevant) after success. The successful
`ToolOutput` is returned. No error is emitted. The per-tool counter is scoped to
consecutive-failure runs and does not carry over to subsequent invocations in the same run
after a success.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Tool `T` fails 3x with args `{q:"a"}`, `{q:"b"}`, `{q:"c"}`; `attempt_limit=3` | Returns `E-RETRY-001` after third call; no fourth invocation | Core NE-09 termination guarantee |
| TV-002 | Tool `T1` fails 2x; tool `T2` fails 2x; each `attempt_limit=3` | Both proceed independently; neither is blocked | Independent counters by name |
| TV-003 | Tool `T` fails 2x, then succeeds | Returns `Ok(ToolOutput)` on third attempt | Happy path — eventual success |
| TV-004 | Construct `ToolRetryPolicy { attempt_limit: 0 }` | `Err(E-RETRY-004)` | Zero-limit reject (F-P34-02) |
| TV-005 | Tool `T` fails; args change on each call (P-63 pattern) | Counter increments each call regardless of args | Args-hash isolation |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC216001-01 | Two calls to same tool with different args share one counter | Unit test (counter state inspection) | Post-v1 |
| VP-BC216001-02 | Per-tool limit is reached in exactly `attempt_limit` calls regardless of arg variation | Property test (arbitrary args, fixed limit) | Post-v1 |

## Related BCs

- BC-2.16.002 — Finite global_limit (composes with: global cap guards against misconfigured per-tool limits)
- BC-2.16.003 — Circuit breaker (composes with: circuit breaker is an additional termination layer on top of per-tool counter)
- BC-2.09.004 — MCP ToolException handling (depends on: retry combinator receives MCP tool errors and decides retry eligibility)

## Architecture Anchors

- `ferrochain-core/src/retry/combinator.rs` — shared retry combinator (to be created; P-71 ADOPT)
- `ferrochain-core/src/retry/policy.rs` — `ToolRetryPolicy` struct definition (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC216001-01, VP-BC216001-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-018 |
| Capability Anchor Justification | CAP-018 ("Tool Retry with Circuit Breaker") per capabilities-p1-p2.md §CAP-018 — this BC encodes the first clause of NE-09: "Retry bound keyed on (tool_name) not args", which CAP-018 names explicitly as the grounding constraint |
| L2 Domain Invariants | — |
| NE References | NE-09 (P-63 REJECT), P-71 (ADOPT — shared retry combinator) |
| FM References | FM-012 (Tool-Retry Loops Forever) |
| Priority | P2 |
| Wave | Wave 2 |
| Test Types | U (unit), P (property) |
| Module | ferrochain-core |
