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

## State Checkpoint
```yaml
pass: A1
scope: test-inventory
status: complete
timestamp: 2026-07-13
notes: guardrail (0 integration) + eval (thin) flagged as coverage gaps
```
