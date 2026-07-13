---
artifact: comparative/adk-rust/test-inventory
pass: A1
constraint: D16 Rust-blindness — test rigor judged on production-grade merit only
created: 2026-07-13
status: observe-only
---

# adk-rust — Test Inventory (Pass A1)

Two test surfaces: in-crate `#[cfg(test)] mod tests` (unit, in-process) and top-level
`tests/` integration dirs. Unit-test counts below are grep matches on `#[test]`/`#[tokio::test]`
attribute lines (includes both surfaces within the crate tree). All 28 in-workspace crates
have a `tests/` directory except where noted.

## Core-crate test density

| Crate | Code LOC | Unit `#[test]` sites | Integration files | Integration LOC | Test:code signal |
|-------|---------:|---------------------:|------------------:|----------------:|-------------------|
| adk-core | 7,420 | 339 | 9 | 2,417 | Very high — near-exhaustive per type |
| adk-model | 27,913 | 505 | 18 | 4,780 | High — provider convert + retry + serde round-trips |
| adk-tool | 10,846 | 197 | 8 | 2,288 | High |
| adk-runner | 6,208 | 127 | 12 | 4,216 | High — integration-heavy (runtime behavior) |
| adk-agent | 9,398 | 86 | 18 | 5,644 | Integration-weighted (workflow agents) |
| adk-session | 8,089 | 50 | 13 | 1,949 | Medium — backend conformance style |

## Other crates — integration test presence (sampled)

| Crate | Integration files | Integration LOC | Note |
|-------|------------------:|----------------:|------|
| adk-graph | 14 | 3,185 | Strong — graph execution, checkpoint, HITL |
| adk-server | 13 | 4,906 | Strong — A2A protocol conformance |
| adk-payments | 12 | 3,669 | Strong for a capability crate |
| adk-sandbox | 7 | 1,091 | Backend execution tests |
| adk-memory | 6 | 1,188 | Project-scope isolation |
| adk-eval | 2 | 234 | **Thin** — an eval framework with minimal self-tests |
| adk-retry-reflect | 1 | 171 | Thin |
| adk-guardrail | 0 | 0 | **No integration tests** — unit-only (flagged) |

## Test-as-specification quality (the load-bearing question)

Judged on whether tests encode behavioral contracts a re-implementer could rely on:

- **STRONG — error taxonomy (adk-core::error).** ~35 tests. Not smoke tests: they assert the
  full category→retryability truth table (all 10 categories both directions), the full
  category→HTTP-status mapping (all 10), Problem-Details JSON shape incl. null-optional
  handling, source-chaining presence/absence, builder chaining, and a legacy-code invariant
  (`every legacy constructor's code ends with ".legacy"`). This is executable specification.
- **STRONG — retry combinator (adk-model::retry).** Tests verify retry-vs-no-retry
  classification, disabled-config single-attempt, server-hint delay override, 529 end-to-end,
  and a **timing-based exponential-backoff assertion** (gap2 ≥ ~2×gap1). The backoff test
  measures real elapsed time between attempts — behavioral, not structural.
- **STRONG — Event.is_final_response (adk-core::event).** 11 tests walk the complete decision
  truth table: no-content, text-only, function-call, function-response, partial,
  skip_summarization override, long-running-tool override, trailing-function-response, and
  text-after-function-response. A re-implementer could derive the predicate from the tests alone.
- **STRONG — state-key validation (adk-core::context).** Explicit adversarial cases:
  path traversal (`../etc/passwd`, `foo/bar`, `foo\bar`, `..`), null-byte injection, empty,
  over-length. Security invariant encoded as tests.
- **STRONG — RunConfig builder (adk-core::context).** Default-equivalence test + all-fields
  round-trip test pin every field's default and builder wiring.
- **MEDIUM — provider convert modules (adk-model).** Each provider has a `convert.rs`; the 505
  unit tests + serde round-trip tests (citations, provider_metadata, extensions, usage) give
  good coverage of wire mapping, though many depend on captured fixtures.
- **MEDIUM — trait-level tests.** `Agent`/`Tool` core tests use hand-rolled mock impls
  (`TestAgent`, `TestTool`, `MockSession`, `MockState`, `TestContext`) proving object-safety
  and default-method behavior. These are conformance harnesses reusable by new impls.
- **GAP — adk-guardrail** has zero integration tests despite being a safety subsystem; PII
  redaction and content filtering are exactly the kind of behavior that warrants adversarial
  integration coverage.
- **GAP — adk-eval** (2 files / 234 LOC) is thinly tested for a component whose job is to test
  other agents; trajectory-scoring correctness is under-verified.
- **Test-only `unwrap()`/`expect()`** is used liberally inside `#[cfg(test)]` blocks
  (acceptable under ferrochain's rule, which exempts test code). One production-relevant note:
  `Runner` uses `.lock().unwrap_or_else(|e| e.into_inner())` for mutex poisoning recovery
  rather than `.unwrap()` — a deliberate non-panicking choice in non-test code.

## Test infrastructure observations
- Heavy use of `#[tokio::test]` for async paths; `async_stream::stream!` and
  `futures::StreamExt` in stream tests.
- `adk-model::mock` provides a `MockLlm`-style double so agent/runner tests need no live API.
- `AtomicU32`/`Arc<Mutex<Vec<Instant>>>` used to assert call counts and timing in retry tests.
- Integration tests likely include `#[ignore]`'d live-API tests (EXT-gated) — not separately
  counted here; deep pass will classify ignored vs runnable.

---

# Pass A2 — cluster test density & test-as-spec quality (measured)

Counts from `grep -c` on `#[test]`/`#[tokio::test]` across `adk-graph` src+tests.

## adk-graph test file breakdown (14 integration files; 208 test fns crate-wide)
| Integration file | test fns | Kind |
|------------------|---------:|------|
| action_switch_property_tests.rs | 43 | property (routing totality) |
| workflow_schema_property_tests.rs | 23 | property (schema laws) |
| action_error_mode_property_tests.rs | 18 | property (error modes) |
| edge_tests.rs | 18 | example-based |
| graph_tests.rs | 18 | example-based |
| checkpoint_tests.rs | 16 | example-based (persist/load) |
| execution_tests.rs | 16 | example-based (super-step behavior) |
| node_tests.rs | 16 | example-based |
| state_tests.rs | 20 | example-based (reducers) |
| cache_property_tests.rs | 10 | property |
| deferred_property_tests.rs | 10 | property (fan-in) |
| delta_property_tests.rs | 6 | property (Diff round-trip) |
| timeout_property_tests.rs | 6 | property |
| time_travel_property_tests.rs | 3 | property |

8 of 14 files are `*_property_tests.rs` — property testing is the dominant style for the graph
runtime. Plus ~40 in-crate `delta.rs` unit tests (Diff round-trip across append/modify/remove/
unicode/multiline) and ~18 `typed_reducer.rs` unit tests (Replace/Append/Merge truth tables).

## Test-as-specification assessment (the load-bearing question) — cluster
- **STRONG — Diff round-trip (adk-graph::delta).** `apply(base, diff(base,new)) == new` verified
  over Vec/HashMap/String with adversarial cases (shorter-new, mid-modification, key removal,
  empty↔populated, unicode). A re-implementer can lift these as a conformance suite for a
  delta-checkpoint channel. Executable spec.
- **STRONG — reducer truth tables (state.rs / typed_reducer.rs).** Overwrite/Append/Sum/Custom and
  Replace/Append/Merge (incl. deep-merge nesting, array-replace, null handling) are pinned by
  example. Good.
- **STRONG — DeltaCheckpointer behavior.** full-at-interval, delta-between, reconstruction across
  snapshot boundary, load-by-id, key-removal — the storage-compression contract is well specified.
- **MEDIUM — execution/checkpoint tests.** `execution_tests.rs`/`checkpoint_tests.rs` cover
  sequential/conditional/cycle/recursion-limit and persist/load/list/delete. They spec what the
  engine DOES — but see the two gaps below.
- **GAP (the load-bearing one) — determinism is UNSPECIFIED because it is UNGUARANTEED.** No test
  asserts that reducer-apply order is independent of node completion order (it isn't — P-28). The
  Append/Sum reducers are only tested with a single writer or sequentially, never with two
  concurrent writers into the same channel in one super-step. So the suite does not — and cannot —
  encode the BSP deterministic-merge invariant ferrochain's D9 requires.
- **GAP — interrupt/resume replay contract UNTESTED because ABSENT (P-30).** There is no test for
  "node re-executes from start on resume; prior interrupt() returns stored value" because there is
  no resume-value mechanism. `checkpoint_tests`/`time_travel` cover restore-and-continue, not
  replay-with-injected-resume.
- **adk-session:** transactional create/append and sqlite rewind + rewind_steps are tested;
  `encrypted` round-trip + key-rotation tested. NOT asserted either way: that event content is
  left plaintext (P-32), or that same-timestamp rewind ordering is well-defined (P-31).
- **adk-memory:** project-scope isolation (global ∪ project) covered per the module's 6 integration
  files (A1). `MemoryServiceAdapter::search_in_project` override tested (mitigates A1 P-19).

## Verdict on the A1 claim
A1 flagged adk-graph's 14 files / 3,185 LOC as "Strong." CONFIRMED — genuinely strong, property-
test-dominant. Caveat for ferrochain: the strength is in *storage/routing law* coverage; the
Pregel invariants adk-graph OMITS (deterministic ordering, replay-with-resume) are, by definition,
not in the suite. High-fidelity tests of a lower-fidelity engine.

## State Checkpoint
```yaml
pass: A2
scope: test-inventory (state/persistence/orchestration cluster)
status: complete
timestamp: 2026-07-13
notes: adk-graph property-test-dominant (CONFIRMED strong); determinism + interrupt-replay
       are unspecified-because-unimplemented gaps
```
