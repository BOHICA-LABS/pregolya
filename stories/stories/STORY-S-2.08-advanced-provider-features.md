---
document_type: story
level: ops
story_id: S-2.08
epic_id: E-19
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-19T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.008.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.009.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.013.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.014.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "68f3954"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-2.07]
blocks: []
behavioral_contracts: [BC-2.08.008, BC-2.08.009, BC-2.08.013, BC-2.08.014]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: [pregolya-openai, pregolya-anthropic, pregolya-ollama, pregolya-standard-tests]
subsystems: [SS-08]
estimated_days: 3
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
# BC status: all 4 BCs active; no BC-TBD placeholders; status = draft per Spec-First Gate S-7.01
---

# S-2.08: Advanced Provider Features — Eval Scoring, Schema Stability, Tool Dialects, Failover Chain

## Narrative

- **As a** pregolya platform engineer building evaluation harnesses, schema-versioned tool contracts, multi-dialect provider integrations, and resilient multi-provider chains
- **I want to** have production-grade implementations of eval score aggregation, schema snapshot stability guards, pluggable tool-call dialect serialization, and provider failover chain semantics
- **So that** evaluation scores are arithmetically correct and infra-error-aware, schema changes are detected before they break consumers, tool-call format is pluggable across different provider conventions, and a failing primary provider transparently delegates to fallbacks with structured exhaustion errors

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.08.008 | Eval Score Aggregation — Arithmetic Mean + InfraError | P1 |
| BC-2.08.009 | Tool Schema Naming Stability | P1 |
| BC-2.08.013 | Pluggable Tool-Call Dialect Seam | P1 |
| BC-2.08.014 | Provider Failover Chain | P1 |

## Acceptance Criteria

### AC-001 (traces to BC-2.08.008 postcondition 1)
`EvalHarness::score()` computes the arithmetic mean as `sum(Pass) / count(Pass + Fail)`.
A run with 3 Pass + 1 Fail + 2 InfraError returns `Ok(3.0 / 4.0)` = `Ok(0.75)`.
Verified by `test_BC_2_08_008_eval_score_arithmetic_mean()`.

### AC-002 (traces to BC-2.08.008 postcondition 2)
`InfraError` outcomes are excluded from both the numerator and denominator. Two InfraError
cases in a 4-case run where 2 pass: `score = 2.0 / 2.0 = 1.0`, not `2.0 / 4.0`.
Verified by `test_BC_2_08_008_infra_error_excluded_from_numerator_and_denominator()`.

### AC-003 (traces to BC-2.08.008 postcondition 5)
When ALL cases are `InfraError`, `score()` returns
`Err(EvalError::AllCasesInfraError)` — not `Ok(0.0)` or `Ok(f64::NAN)`.
Verified by `test_BC_2_08_008_all_cases_infra_error_returns_err()`.

### AC-004 (traces to BC-2.08.008 postcondition 4)
For each `InfraError` outcome, the harness emits:
`tracing::warn!(event_type = "eval.judge_infra_error", reason = %reason)`.
The `event_type` value is exactly `"eval.judge_infra_error"` (registered in the Canonical
Structured Event Catalog per SAP-1). Verified by
`test_BC_2_08_008_infra_error_emits_tracing_event()` (tracing subscriber capture).

### AC-005 (traces to BC-2.08.009 postcondition 1)
`test_BC_2_08_009_tool_schema_snapshot_<ToolName>()` calls `schemars::schema_for!(T)` on
each public tool input type and captures the result with `insta::assert_snapshot!`. The
first run creates the snapshot; subsequent runs assert equality. Verified by
`cargo nextest run -p pregolya-standard-tests` producing matching snapshots for all tool types.

### AC-006 (traces to BC-2.08.009 postcondition 2)
Snapshots are stored in canonicalized JSON (alphabetically sorted object keys at every
nesting level). A snapshot of `{ "z": 1, "a": 2 }` is stored as `{ "a": 2, "z": 1 }`.
Verified by `test_BC_2_08_009_snapshot_is_canonicalized_json()`.

### AC-007 (traces to BC-2.08.009 postcondition 3)
Reordering fields in a tool input struct (no semantic change) does NOT cause a snapshot
failure. The canonical JSON sort makes field order irrelevant. Verified by
`test_BC_2_08_009_field_reorder_is_not_breaking()`.

### AC-008 (traces to BC-2.08.009 postcondition 4)
Renaming a field in a tool input struct causes the snapshot to differ, and the snapshot
assertion fails. This is the intended detection mechanism for breaking schema changes.
Verified by `test_BC_2_08_009_field_rename_fails_snapshot()` (uses a type with a renamed
field against a committed snapshot that expects the original name).

### AC-009 (traces to BC-2.08.013 postcondition 1)
`ToolCallDialect::NativeOpenAiJson` serializes tool definitions as the OpenAI `tools` array
format: `[{"type":"function","function":{"name":...,"description":...,"parameters":...}}]`.
Verified by `test_BC_2_08_013_native_openai_json_serialization()`.

### AC-010 (traces to BC-2.08.013 postcondition 2)
`ToolCallDialect::NativeAnthropic` serializes tool definitions as the Anthropic `tools` array
format: `[{"name":...,"description":...,"input_schema":{...}}]`.
Verified by `test_BC_2_08_013_native_anthropic_serialization()`.

### AC-011 (traces to BC-2.08.013 postcondition 3)
`ToolCallDialect::HermesChatMlXml` injects `<tools>[{...}]</tools>` into the system prompt
as a serialized JSON array wrapped in XML tags. Verified by
`test_BC_2_08_013_hermes_chatml_xml_injects_system_prompt()`.

### AC-012 (traces to BC-2.08.013 postcondition 4)
`ToolCallDialect::HermesChatMlXml` parses assistant responses containing
`<tool_call>{json}</tool_call>` tags and extracts the tool call name and arguments.
Verified by `test_BC_2_08_013_hermes_chatml_xml_parses_tool_call_response()`.

### AC-013 (traces to BC-2.08.013 postcondition 5)
A malformed `<tool_call>` response (invalid JSON inside the XML tag, or no closing tag)
returns `Err(PregolyaError { code: "E-PROV-009", .. })`. Verified by
`test_BC_2_08_013_malformed_hermes_xml_returns_e_prov_009()`.

### AC-014 (traces to BC-2.08.014 postcondition 1)
A 429 HTTP response from the primary provider triggers failover to the next provider in
the `ProviderFallbackPolicy` chain. The secondary provider's response is returned.
Verified by `test_BC_2_08_014_429_triggers_failover()`.

### AC-015 (traces to BC-2.08.014 postcondition 2)
A 5xx HTTP response from the primary provider triggers failover to the next provider.
Verified by `test_BC_2_08_014_5xx_triggers_failover()`.

### AC-016 (traces to BC-2.08.014 postcondition 3)
An authentication failure (E-PROV-004) from the primary provider triggers the
`credential_refresh` callback if configured, then retries the same provider once. If
that also fails, failover proceeds to the next provider. Verified by
`test_BC_2_08_014_auth_failure_triggers_credential_refresh_then_failover()`.

### AC-017 (traces to BC-2.08.014 postcondition 4)
When all providers in the chain are exhausted, the chain returns
`Err(PregolyaError { code: "E-PROV-010", .. })`. Verified by
`test_BC_2_08_014_chain_exhausted_returns_e_prov_010()`.

### AC-018 (traces to BC-2.08.014 postcondition 5)
Constructing a `ProviderFallbackPolicy` with an empty `chain` returns
`Err(PregolyaError { code: "E-PROV-011", .. })` at construction time — not at invocation time.
Verified by `test_BC_2_08_014_empty_chain_returns_e_prov_011_at_construction()`.

### AC-019 (traces to BC-2.08.014 invariant 1)
A `TIMEOUT` error (E-PROV-002) from the primary provider does NOT trigger failover. The
timeout propagates directly to the caller as `Err(E-PROV-002)`. Failover is only triggered
by 429, 5xx, or auth failures. Verified by
`test_BC_2_08_014_timeout_does_not_trigger_failover()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `EvalHarness` | `pregolya-standard-tests/src/eval.rs` | effectful (invokes model per case) |
| `eval_score()` aggregator | `pregolya-standard-tests/src/eval.rs` | pure-core (arithmetic on outcomes) |
| `ToolCallDialect` trait + impls | `pregolya-core/src/tool_dialect.rs` | pure-core (serialization logic) |
| `ProviderFallbackPolicy` | `pregolya-core/src/failover.rs` | effectful (dispatches to providers) |
| Schema snapshot tests | `pregolya-standard-tests/src/schema_snapshots.rs` | pure-core (serde + insta) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `eval_score()` aggregator | pure-core | Pure arithmetic on a `Vec<EvalOutcome>`; no I/O |
| `ToolCallDialect` serializers | pure-core | Pure string/JSON transformations; no network I/O |
| `ProviderFallbackPolicy::invoke` | effectful | Dispatches HTTP calls to provider adapters |
| Schema snapshot test bodies | pure-core | Pure `schemars::schema_for!` call + insta assertion |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Single case, InfraError | `Err(EvalError::AllCasesInfraError)` — all cases are InfraError |
| EC-002 | Chain with one provider; that provider returns 429 | `Err(E-PROV-010)` — chain exhausted after one entry |
| EC-003 | `credential_refresh` callback panics | Panic propagates; not caught by failover — callers must not panic in callbacks |
| EC-004 | HermesChatMlXml with `<tools>` already in system prompt | Behavior: append second `<tools>` block — this is a misuse; the AC only covers the normal path of one bind_tools call |
| EC-005 | Schema snapshot drift detected in CI | `cargo nextest` fails with insta snapshot mismatch — engineer must run `cargo insta review` to accept or reject |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,800 |
| BC files (4 BCs) | ~8,000 |
| `module-decomposition.md` SS-08 section | ~600 |
| Source files (eval.rs, tool_dialect.rs, failover.rs, schema_snapshots.rs) | ~2,500 |
| Test files (~120 lines) | ~1,800 |
| Tool outputs | ~500 |
| **Total** | **~17,200** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~9%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-019 (test-writer step)
2. [ ] No Red Gate BCs — proceed to implementation after test stubs
3. [ ] Create `pregolya-standard-tests/src/eval.rs` — `EvalHarness`, `EvalOutcome`, `eval_score()`
4. [ ] Implement score aggregation: exclude InfraError, arithmetic mean, AllInfraError → Err
5. [ ] Add `tracing::warn!(event_type = "eval.judge_infra_error", ...)` per InfraError case
6. [ ] Register `eval.judge_infra_error` event in Canonical Structured Event Catalog (SAP-1)
7. [ ] Create `pregolya-core/src/tool_dialect.rs` — `ToolCallDialect` enum, object-safe trait
8. [ ] Implement `NativeOpenAiJson`, `NativeAnthropic`, `HermesChatMlXml` serializers
9. [ ] Implement `HermesChatMlXml` parser — XML tag extraction + JSON parse; E-PROV-009 on malform
10. [ ] Create `pregolya-core/src/failover.rs` — `ProviderFallbackPolicy`, failover dispatch
11. [ ] Implement failover triggers: 429/5xx/auth → next; timeout → propagate; exhausted → E-PROV-010
12. [ ] Implement empty-chain guard at `ProviderFallbackPolicy::new` → Err(E-PROV-011)
13. [ ] Create `pregolya-standard-tests/src/schema_snapshots.rs` — snapshot test helpers
14. [ ] Write schema snapshot tests for all public tool input types; generate initial snapshots
15. [ ] Run `cargo nextest run -p pregolya-standard-tests -p pregolya-core` — all 19 ACs green

## Previous Story Intelligence (MANDATORY)

S-2.07 established `BaseChatModel` implementations for all three providers. This story adds
cross-cutting features that compose with those implementations: `ToolCallDialect` modifies
how tool definitions are serialized before being sent to the provider; `ProviderFallbackPolicy`
wraps provider instances; the eval harness invokes `BaseChatModel::invoke` per test case.

S-1.06 established the `Tool` trait and `DynTool` object-safe seam. `ToolCallDialect` operates
on tool definitions derived from `DynTool::input_schema()` — use the same schema representation.

The `ToolCallDialect` trait must be object-safe (ADR-005 §Adjacent Trait Object-Safety Adjudications).
The enum approach (`ToolCallDialect::NativeOpenAiJson` etc.) is preferred over a trait object
for dialect selection, but the serialization logic must be callable via `&dyn` if needed.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `eval_score()` excludes InfraError from denominator | BC-2.08.008 postcondition 2 | Unit test AC-002 |
| AllCasesInfraError → `Err`, never `Ok(0.0)` | BC-2.08.008 postcondition 3 | Unit test AC-003 |
| Schema snapshots use canonicalized JSON (alphabetically sorted keys) | BC-2.08.009 postcondition 2 | Snapshot helper enforces sorting |
| `tracing::warn!` with `event_type = "eval.judge_infra_error"` registered in catalog | SAP-1 | Catalog row required before PR merge |
| TIMEOUT (E-PROV-002) does NOT trigger failover | BC-2.08.014 invariant 1 | Unit test AC-019 |
| Empty chain detected at construction, not invocation | BC-2.08.014 postcondition 5 | Unit test AC-018 |
| `ToolCallDialect` is object-safe | ADR-005 §Adjacent Trait Object-Safety Adjudications | Compile-fail test |

**Forbidden dependencies:** `pregolya-standard-tests` must NOT depend on `pregolya-graph`,
`pregolya-mcp`, `pregolya-vectorstores`, or `pregolya-server`. It depends only on
`pregolya-core` and provider adapter crates. If this crate gains a dependency on the forbidden
list, the build MUST fail via `cargo deny`.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `schemars` | workspace pin | `schemars::schema_for!(T)` for schema snapshot generation |
| `insta` | workspace pin | Snapshot testing for schema stability |
| `serde_json` | workspace pin | Canonicalized JSON serialization for snapshot normalization |
| `tracing` | workspace pin | `tracing::warn!` for InfraError events (SAP-1) |
| `async-trait` | workspace pin | `ProviderFallbackPolicy` implements async dispatch |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-standard-tests/src/eval.rs` | CREATE | `EvalHarness`, `EvalOutcome`, `eval_score()` aggregator |
| `pregolya-standard-tests/src/schema_snapshots.rs` | CREATE | Schema snapshot test helpers + snapshot files |
| `pregolya-core/src/tool_dialect.rs` | CREATE | `ToolCallDialect` enum + serializer/parser impls |
| `pregolya-core/src/failover.rs` | CREATE | `ProviderFallbackPolicy`, `CredentialRefreshCallback` |
| `pregolya-standard-tests/src/snapshots/` | CREATE | Insta snapshot directory for tool schema snapshots |
