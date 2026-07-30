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
attribute lines (includes both surfaces within the crate tree). All 27 in-workspace crates
have a `tests/` directory except where noted. <!-- [comparative-sweep] corrected from 28:
grep-verified — 12 workspace members lack a tests/ dir: adk-cli, adk-browser, adk-telemetry,
adk-guardrail, adk-plugin, adk-skill, adk-rust, adk-deploy, awp-types, adk-acp, cargo-adk,
adk-bench -->

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
- **STRONG — Event.is_final_response (adk-core::event).** 9 tests walk the complete decision
  truth table: no-content, text-only, function-call, function-response, partial,
  skip_summarization override, long-running-tool override, trailing-function-response, and
  text-after-function-response. A re-implementer could derive the predicate from the tests alone.
  <!-- [comparative-sweep] corrected from 11: grep -cE 'fn test_is_final_response'
  adk-core/src/event.rs → 9 functions; the two listed cases each resolve to one named
  function, not separate tests -->
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
  (acceptable under pregolya's rule, which exempts test code). One production-relevant note:
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

<!-- [comparative-sweep] METHODOLOGY NOTE: original counts used a combined pattern
`#[test]|#[tokio::test]|fn test_` that double-counts synchronous tests (one `#[test]`
attribute line + one `fn test_name()` declaration line = 2 matches per sync test).
Corrected column uses attribute-only count `grep -cE '^\s*#\[(test|tokio::test)\]'`
which equals actual test-function count. Crate-wide: original 208 (internally
inconsistent — integration subtable summed to 223) → corrected 262 (149 src + 113
tests/). -->

## adk-graph test file breakdown (14 integration files; 262 test fns crate-wide) <!-- [comparative-sweep] corrected from 208 -->
| Integration file | test fns (corrected) | test fns (original) | Kind |
|------------------|---------:|---:|------|
| action_switch_property_tests.rs | 22 | ~~43~~ | property (routing totality) |
| workflow_schema_property_tests.rs | 12 | ~~23~~ | property (schema laws) |
| action_error_mode_property_tests.rs | 9 | ~~18~~ | property (error modes) |
| edge_tests.rs | 9 | ~~18~~ | example-based |
| graph_tests.rs | 9 | ~~18~~ | example-based |
| checkpoint_tests.rs | 8 | ~~16~~ | example-based (persist/load) |
| execution_tests.rs | 8 | ~~16~~ | example-based (super-step behavior) |
| node_tests.rs | 8 | ~~16~~ | example-based |
| state_tests.rs | 10 | ~~20~~ | example-based (reducers) |
| cache_property_tests.rs | 5 | ~~10~~ | property |
| deferred_property_tests.rs | 5 | ~~10~~ | property (fan-in) |
| delta_property_tests.rs | 3 | ~~6~~ | property (Diff round-trip) |
| timeout_property_tests.rs | 3 | ~~6~~ | property |
| time_travel_property_tests.rs | 2 | ~~3~~ | property |

8 of 14 files are `*_property_tests.rs` — property testing is the dominant style for the graph
runtime. Plus 39 in-crate `delta.rs` unit tests (Diff round-trip across append/modify/remove/
unicode/multiline) and 15 `typed_reducer.rs` unit tests (Replace/Append/Merge truth tables).
<!-- [comparative-sweep] corrected: delta.rs attribute-only count 39 (not ~40),
typed_reducer.rs attribute-only count 15 (not ~18) -->

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
  encode the BSP deterministic-merge invariant pregolya's D9 requires.
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
test-dominant. Caveat for pregolya: the strength is in *storage/routing law* coverage; the
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

---

# Pass A4 — SAFETY / QUALITY cluster test inventory

D16 Rust-blindness: test rigor judged on production-grade merit only. Cross-refs P-47..P-66.

<!-- [comparative-sweep] METHODOLOGY NOTE: original "test markers" column used combined
`#[test]|#[tokio::test]|fn test_` pattern which double-counts synchronous tests; sync tests
generate 2 line-matches per function (attribute + fn declaration). Async tests (`#[tokio::test]
async fn`) count once. Corrected column uses attribute-only grep. proptest file counts were
each overcounted by 1; the extra count came from incorrectly including a file that uses
`proptest` only in import syntax, not as a test invocation. -->

## Test volume by crate (test markers = `#[test]`/`#[tokio::test]`; attribute-only; src+tests) <!-- [comparative-sweep] -->
| Crate | Integ files | Unit-test files (src) | Test markers (corrected) | Test markers (original) | proptest files (corrected) | proptest (orig) |
|-------|-------------|----------------------|------:|------:|------:|------:|
| adk-eval | 2 | 17 | 124 | ~~243~~ | 2 | ~~3~~ |
| adk-sandbox | 7 | 11 | 154 | ~~242~~ | 5 | ~~6~~ |
| adk-code | 10 | 9 | 175 | ~~193~~ | 7 | ~~8~~ |
| adk-plugin | 0 | 4 | 43 | ~~86~~ | 0 | 0 |
| adk-browser | 0 | 5 | 32 | ~~64~~ | 0 | 0 |
| adk-guardrail | 0 | 4 | 27 | ~~55~~ | 0 | 0 |
| adk-skill | 0 | 6 | 46 | 46 | 0 | 0 |
| adk-retry-reflect | 1 | 0 | 16 | ~~32~~ | 0 | ~~1~~ |

## What the tests actually assert (test-as-spec value)
- **adk-sandbox (STRONG coverage of the primitives):** Linux `generate_args` truth tables (deny-all
  → unshare-net + new-session; ro-bind/bind placement); macOS profile generation (deny network/
  write/fork, domain allowlist, balanced-parens); WASM timeout (infinite loop → `Timeout`), memory
  limit (`memory.grow` → `MemoryExceeded`), non-zero exit, stdin/stdout, invalid module; path_safety
  traversal cases (absolute/`..`-escape/drive-letter rejected, in-bounds `..` allowed). 5 proptest
  files <!-- [comparative-cert-1] corrected from 6 per SWEEP-test-deps attribute-only recount -->. This is the highest-rigor sub-suite in the cluster.
- **adk-code:** 7 proptest files <!-- [comparative-cert-1] corrected from 8 per SWEEP-test-deps --> + 10 integ files — property + integration heavy for the exec
  substrate (rust harness contract, workspace ops, diagnostics).
- **adk-eval:** 124 markers, 2 proptest <!-- [comparative-cert-1] corrected from "243 markers, 3 proptest"; original used double-counting methodology (combined fn-grep); attribute-only recount per SWEEP-test-deps: 124 markers, 2 proptest files --> — scorers well unit-tested (tool-trajectory exact/partial/
  unordered, Levenshtein/Jaccard/ROUGE-L, ToolUse strict-vs-partial matching). BUT: the two
  scoring-rigor bugs (P-64) are NOT covered — no test asserts the multi-turn merge is order-
  independent (it isn't), and no test distinguishes judge-infra-failure from quality-fail (both
  yield score 0.0). Judge parsing (`SAFE: YES`/`SCORE:`) has no adversarial malformed-response test.
- **adk-guardrail (27 markers, unit-only) <!-- [comparative-cert-1] corrected from "55 markers" per SWEEP-test-deps attribute-only recount -->:** content filter (harmful blocks, hackathon/`exploit a
  bug` pass, strict-vs-default, on-topic, max-length, blocked-keywords), PII (email/phone/ssn/CC,
  multiple, none, transform), schema (valid/missing-required/wrong-type/markdown-fence/no-json),
  executor (empty/pass/low-severity-passes/high-fails/critical-early-exit). GAP: NO test that tool/
  RAG/memory content is guardrailed (because it isn't — P-59); NO prompt-injection test; NO test of
  the input-vs-output hook coverage in the agent loop (the enforcement is in adk-agent, untested here).
- **adk-retry-reflect (16 markers, 0 proptest) <!-- [comparative-cert-1] corrected from "32 markers, 1 proptest" per SWEEP-test-deps attribute-only recount; proptest use = 0 (grep found none) -->:** detection (error shapes), backoff (None/Fixed/
  Exponential + ceiling, saturating), filter (allow/deny), template rendering. GAP: NO test that the
  args-hash keying defeats the per-tool limit under arg-changing retries (P-63) — the termination
  hole is untested-because-unnoticed.
- **adk-skill (46 markers):** parser (valid/full-spec/missing-fields/AGENTS.md/SOUL.md/strict-
  .skills), discovery (both dirs, dedup, non-dir skip), select (relevance, tag include/exclude, +
  extensive CJK/Cyrillic/Japanese/Korean/accented-Latin tokenization tests), injector (top-skill
  prepend). Coordinator `allowed-tools`↔ToolRegistry validation (P-51) — the phantom-tool guard —
  is the load-bearing one; verify it has a negative test (skill requests unavailable tool → handled
  per ValidationMode) during any pregolya port.
- **adk-plugin (43 markers) <!-- [comparative-cert-1] corrected from "86 markers" per SWEEP-test-deps attribute-only recount -->:** hook result semantics, priority ordering, both managers.
- **adk-browser (32 markers, unit-only) <!-- [comparative-cert-1] corrected from "64 markers" per SWEEP-test-deps attribute-only recount -->:** `escape_js_string` has a strong adversarial suite
  (injection attempt, `</script>`, quotes/backtick/null/newlines) (P-54). Tool actions are
  WebDriver-backed → likely `#[ignore]`/mock at the driver boundary (no integ files present).

## Verdict on cluster test rigor
Mixed. The **sandbox/code primitives are genuinely well-tested** (property + truth-table + integ),
and the **eval scorers and browser escaping** have solid unit coverage. But the tests are strongest
exactly where the design is strongest (isolation primitives, deterministic scorers) and SILENT
exactly where the design is weakest: no test covers the untrusted-content-ingress gap (P-59), the
macOS read-confinement gap (P-60), the retry-reflect termination hole (P-63), the eval score-merge/
judge-failure bugs (P-64), or symlink-escape in path_safety (P-65). High-rigor tests of the parts
that were built correctly; no tests probing the parts that were not — a re-implementer lifting this
suite would inherit the blind spots. (Consistent with A2's "high-fidelity tests of a lower-fidelity
engine.")

## State Checkpoint
```yaml
pass: A4
scope: test-inventory (safety/quality cluster)
status: complete
cluster_test_markers: ~617 (8 crates) # [comparative-sweep] corrected from ~961; original used double-counting methodology (see table note above)
strongest_suites: [adk-sandbox (5 proptest + truth-tables), adk-code (7 proptest + 10 integ), adk-eval scorers] # [comparative-cert-13] CORRECTION: "6 proptest" → 5 (adk-sandbox) and "8 proptest" → 7 (adk-code); these were pre-correction double-count values; cert-1 corrected the body text at lines 204-206 but this State Checkpoint YAML was not updated; verified proptest file counts: adk-sandbox=5, adk-code=7 per SWEEP-test-deps attribute-only recount
untested_gaps: [untrusted-content-ingress (P-59), macos-read-confinement (P-60),
                retry-reflect-termination-hole (P-63), eval-score-merge+judge-failure (P-64),
                path-safety-symlink-escape (P-65)]
timestamp: 2026-07-13
```

---

# Pass A5 — PROVIDER / CAPABILITY cluster test inventory

D16 Rust-blindness — observe only. Test-as-spec read of the provider/capability cluster.

## Test-marker counts (approx; `#[test]` + `#[tokio::test]` + `proptest!`)
| Crate | ~markers | integ files | proptest files | Note |
|-------|---------:|------------:|---------------:|------|
| adk-model | ~513 | 18 | 7 | Heaviest. `openai_schema_property_tests` + interactions_runtime integ (`#[ignore]`, needs key). tool_call_parser 22 unit. |
| adk-anthropic | ~445 | 7 | 0 | SDK deeply unit-tested (convert, sse, accumulating, types round-trips); example-based, no proptest. |
| adk-mistralrs | ~282 | 17 | 14 | Surprisingly proptest-heavy (14 files) for a local-inference wrapper — convert/config/adapter laws. | <!-- [comparative-cert-20] ~264→~282: sweep correction reverted; the original comparative-sweep excluded proptest! for this crate only, inconsistent with all other per-crate figures which include proptest! per section header methodology (#[test] + #[tokio::test] + proptest!). Independent recount: 245 #[test] + 19 #[tokio::test] + 18 proptest! = 282. -->
| adk-gemini | ~215 | 7 | 5 | proptest on convert + schema_adapter. |
| adk-bench | ~115 | 0 | 0 | In-src unit tests only (metrics/scoring). |
| adk-audio | ~105 | 13 | 11 | proptest-dominant (codec/frame/resample laws). |
| adk-realtime | ~100 | 12 | 6 | proptest on audio codec + protocol framing. |
| adk-payments | ~65 | 12 | 0 | Example-based; policy decisions (allow/escalate/deny) + money arithmetic + protocol mappers. trybuild compile tests. | <!-- [comparative-sweep] integ files corrected from 9→12; find tests/ count = 12, consistent with A1 pass table which correctly recorded 12 -->
| adk-action | ~39 | 2 | 2 | interpolation proptest. |
| adk-rag | ~13 | 2 | 1 | THIN — chunking + one property test; backends largely untested without live services. |
| adk-rust-macros | ~12 | 1 | 0 | macro-expansion tests (dev-dep schemars/adk-core). |

## Test-as-spec highlights (reusable conformance)
- **tool_call_parser (P-68):** 22 unit tests, one per text-tag format (Qwen json/function-tag, Llama,
  Mistral Nemo, DeepSeek, Gemma) + text-before + multiple-calls + no-match + streaming emit-immediately.
  A direct behavioral conformance suite for a pregolya-ollama text-tool-call parser.
- **retry (P-71):** gemini has explicit retryable/non-retryable/disabled-config tests around
  `execute_with_retry`; the combinator's timing test lives in `adk-model::retry` (P-03).
- **anthropic SDK:** convert round-trips (thinking blocks, usage, cache), SSE decoding, accumulating
  stream assembly — the wire behavior is well-pinned (445 markers), which is why the adapter can rely
  on it (P-16/P-67).
- **payments:** amount-threshold escalate/deny boundaries + integer-money arithmetic + ACP/AP2 mapper
  round-trips; `trybuild` compile-fail tests guard the public API. The allow/escalate/deny decisions
  are unit-tested (the P-73 governance shape is test-backed).
- **mistralrs / audio:** proptest-dominant on conversion/codec laws.

## Untested / weakly-tested gaps
- **adk-rag** (~13 markers, 1 proptest) — the vector-store backends (qdrant/lancedb/pgvector/surrealdb)
  are effectively untested without live services; only in-memory + chunking are covered. THIN suite for
  a RAG crate.
- **`#[ignore]` key-gated integration** — `adk-model` interactions_runtime tests require a live key
  (per SID-1, pregolya must add key-free unit tests at the boundary instead).
- **Timeout behavior (P-77)** — no test asserts that provider clients set/enforce an outbound timeout
  (because most don't).
- **Credential redaction (P-76)** — no test asserts a key is NOT leaked in Debug (because none is
  redacted). Pregolya would add a redaction assertion test per key type.

## State Checkpoint
```yaml
pass: A5
scope: test-inventory (provider/capability cluster)
status: complete
cluster_test_markers: ~1849 (11 crates) # [comparative-sweep] corrected from ~1500; attr-only recount sum = 1849; original ~1500 is also inconsistent with the per-crate table which sums to ~1904
strongest_suites: [adk-anthropic (SDK wire round-trips), adk-model tool_call_parser (22 format tests),
                   adk-mistralrs+adk-audio (proptest-dominant), adk-payments (policy+money+trybuild)]
untested_gaps: [adk-rag-backends (thin), provider-timeout (P-77), credential-redaction (P-76),
                key-gated-integration (SID-1)]
timestamp: 2026-07-13
```
