---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.002
version: "1.8"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-009
wave: 2
phase: 1a
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-49): F-P49-02 — wired 'configurable step limit' invariant to explicit contract: config.recursion_limit (default 25, RunnableConfig) + BC-2.03.001 PC5 + E-GRAPH-017 GraphRecursionLimitExceeded. VP-BC208002-01 description updated to cite E-GRAPH-017 and BC-2.03.001 PC5."
  - "1.2 (ADV-P1D-PASS-56-COMPLETION): Gate #30 drain — EC-005 had `Err(PregolyaError { category: VAL, message: ... })` and TV-005 had `Err(PregolyaError { category: VAL })` with no code. Added code: E-CORE-005 (ValidationFailed) to EC-005 description and TV-005 — VAL construction-time validation for `bind_tools` called on a model with `has_tool_calling = false`."
  - "1.3 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-<provider> / pregolya-standard-tests per module-decomposition.md v1.10."
  - "1.4 (F-P112-02, 2026-07-18): E-CORE-005 message canonicalization. EC-005 message reworded from 'model <name> does not support tool calling' to 'Validation failed for 'model': model '<name>' does not support tool calling' to conform to canonical E-CORE-005 taxonomy format (Validation failed for '<field>': <reason>). TV-005 bare form unchanged — PASS-ABBREV via EC-005."
  - "1.5 (F-P160-01 TD-VSDD-060 sweep, 2026-07-25): Fix burst 261 — VP-BC208002-01 description had 'without exceeding config.recursion_limit (default 25) super-steps' which implies ≤25 steps execute before halt; corrected to 'within recursion_limit + 1 super-steps per invocation segment' (stop = step_at_invoke_start + recursion_limit + 1; default limit=25 → up to 26 steps execute before halt). Normative authority is BC-2.03.001 PC5; this VP description now agrees."
  - "1.6 (FIX-BURST-281-WAVE-B-SS08-B1/D-72/2026-07-29): Error-construction notation sweep (ADR-010 §Error-Construction Notation Canon). §EC-005 and §Canonical Test Vectors TV-005: PregolyaError value-observations missing required `..` rest pattern (partial fields: category, code, message at EC-005; category, code at TV-005); added `, ..` before closing `}` at both sites. All occurrences reconciled: 2 corrected (Class 3), 2 exempt (changelog, 1 line)."
  - "1.7 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-2.07 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.8 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-009
  - domain-spec/capabilities-p1-p2.md#CAP-011
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/partners/behavioral-intent.md
  - .factory/semport/partners/test-inventory.md
input-hash: "86e470d"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.002: Chat Model Tool-Call Round-Trip Conformance

## Description

Every pregolya provider chat model must pass the `pregolya-standard-tests` tool-calling
battery: binding tools, invoking them, receiving `ToolCall` content blocks in the response,
and completing the round-trip by supplying `ToolMessage` results back to the model.
The mandatory ungated test `test_agent_loop` verifies that a tool-calling agent loop
terminates correctly with the correct final answer, without requiring a `has_tool_calling`
capability flag. Gated tool-call tests require the `has_tool_calling` capability flag.

## Preconditions

1. {PRE-001} A pregolya provider chat model is constructed with valid credentials and a model
   that supports function/tool calling (e.g., `gpt-4o`, `claude-3-5-sonnet`, or a
   local Ollama model with tool support).
2. {PRE-002} At least one `Tool` definition with a JSON Schema input spec is available to bind.
3. {PRE-003} `pregolya-standard-tests` is registered as a dev-dependency and the provider
   implements the standard conformance trait.
4. {PRE-004} The provider crate sets `has_tool_calling: bool = true` in its capability profile
   for models that support tool calling; `has_tool_choice: bool` is set per model.
5. {PRE-005} A record/replay HTTP fixture layer is available for CI.

## Postconditions

1. {PC-001} `test_agent_loop` (ungated): a tool-calling agent loop completes. The model calls
   the supplied tool at least once; the tool result is fed back; the model produces a
   final non-tool-call response. The loop terminates (does not run forever).
2. {PC-002} `test_tool_calling` and `test_tool_calling_async` (gated by `has_tool_calling`):
   calling `.bind_tools([tool])` and invoking with a prompt that requires tool use
   returns an `AiMessage` containing exactly one `ContentBlock::ToolCall` with the
   correct tool name and non-null argument values.
3. {PC-003} `test_tool_calling_with_no_arguments` (gated): a tool with zero required parameters
   is called correctly; argument field is present and is an empty JSON object `{}` — not
   `None` or an absent field.
4. {PC-004} `test_tool_choice` (gated by `has_tool_choice`): passing `tool_choice = "required"` or
   `tool_choice = ToolName` forces the model to call the specified tool; the response
   contains the forced `ToolCall`.
5. {PC-005} `test_tool_message_histories_string_content` and `test_tool_message_histories_list_content`
   (gated): feeding back a `ToolMessage` with string content and with list-of-block content
   both produce a non-error follow-up response; content type normalisation does not lose data.
6. {PC-006} `test_tool_message_error_status` (gated): a `ToolMessage` with
   `status = ToolMessageStatus::Error` is accepted and the model produces a graceful
   error-aware follow-up response.
7. {PC-007} `test_unicode_tool_call_integration` (gated): tool calls containing non-ASCII Unicode
   characters in argument values are transmitted and received without corruption.
8. {PC-008} `test_bind_runnables_as_tools` (gated): a `Runnable` wrapped as a tool via
   `bind_tools([runnable_as_tool])` is correctly bound and invocable.

## Invariants

- {INV-001} **Tool call argument parsing is tolerant:** arguments arriving as a stringified JSON
  object (e.g., Ollama-style `"{ \"key\": 1 }"`) must be parsed to a structured
  `serde_json::Value` before presentation to the caller — raw string pass-through is
  a conformance violation.
- {INV-002} **Argument presence:** a zero-argument tool call always includes an argument field
  set to `{}`, never `None`, never an absent JSON key.
- {INV-003} **Tool name fidelity:** the tool name in the `ToolCall` content block matches the
  bound tool name exactly (case-sensitive, Unicode-safe).
- {INV-004} **No truncated loops:** an agent loop consuming tool results must not silently drop
  the `ToolMessage` or loop forever — it terminates when `config.recursion_limit` (default 25,
  from `RunnableConfig`) super-steps are exhausted in the current invocation segment, halting
  with `Err(E-GRAPH-017 GraphRecursionLimitExceeded)` per BC-2.03.001 PC5. The step limit is
  the graph-engine super-step ceiling; a tool-calling loop that never routes to END will exhaust
  it and fail with E-GRAPH-017 rather than running forever.

## Edge Cases

### EC-001: Parallel tool calls (multiple ToolCall blocks in one response)
**Scenario:** The model emits two `ContentBlock::ToolCall` entries in a single response.
**Expected behavior:** Both tool calls are present in the `AiMessage.content` slice with
distinct `id` values. The caller processes each and feeds back two `ToolMessage` entries
in the next turn.

### EC-002: Tool argument is deeply nested JSON
**Scenario:** The tool schema accepts `{ "query": { "filters": [{"field": "date"}] } }`.
**Expected behavior:** The full nested structure is preserved from the model response
through parsing and into the tool execution call without data loss.

### EC-003: Tool call with Unicode argument value
**Scenario:** A model calls a tool with argument `{ "text": "日本語テスト" }`.
**Expected behavior:** The argument value arrives at the tool runtime as the exact
Unicode string — no escaping artifacts, no replacement characters.

### EC-004: ToolMessage with error status triggers graceful follow-up
**Scenario:** A `ToolMessage { status: Error, content: "network_timeout" }` is fed back.
**Expected behavior:** The model acknowledges the error and either retries (if the graph
policy allows) or produces a graceful failure response — it does not crash or raise an
unhandled deserialization error.

### EC-005: bind_tools on model that does not support tool calling
**Scenario:** `.bind_tools([tool])` is called on a model with `has_tool_calling = false`.
**Expected behavior:** `bind_tools` returns `Err(PregolyaError { category: VAL, code: E-CORE-005,
message: "Validation failed for 'model': model '<name>' does not support tool calling", .. })` — it does not silently return
a model that ignores the tools at inference time.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | invoke with `bind_tools([get_weather])` + "What is the weather in Paris?" | `AiMessage` containing `ContentBlock::ToolCall { name: "get_weather", args: {"location": "Paris"} }` | Basic tool call |
| TV-002 | agent loop: tool returns "22°C"; model follow-up | Final `AiMessage` text mentions "22" or "Paris"; loop terminates | test_agent_loop |
| TV-003 | Zero-argument tool called with `tool_choice = ToolName` | `ToolCall { args: {} }` (empty object, not None) | No-argument tool |
| TV-004 | `ToolMessage { status: Error, content: "timeout" }` fed back | Non-error `AiMessage` acknowledging failure | Error status ToolMessage |
| TV-005 | `bind_tools([tool])` on model with `has_tool_calling = false` | `Err(PregolyaError { category: VAL, code: E-CORE-005, .. })` | EC-005 guard |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208002-01 | agent_loop terminates within `recursion_limit + 1` super-steps per invocation segment (`stop = step_at_invoke_start + recursion_limit + 1`; default limit=25 → up to 26 steps execute before halt); if the loop does not route to END within the ceiling, the run fails with `Err(E-GRAPH-017 GraphRecursionLimitExceeded)` per BC-2.03.001 PC5 | Integration test (standard-tests battery) | Wave 2 |
| VP-BC208002-02 | Tool argument zero-argument case produces `{}` not None | Unit test (argument normalisation) | Wave 2 |
| VP-BC208002-03 | Unicode arguments survive round-trip without corruption | Integration test (unicode_tool_call) | Wave 2 |

## Related BCs

- BC-2.08.001 — streaming tool-call chunks follow v3 protocol (composes with)
- BC-2.08.003 — structured output (alternative to tool-call path for typed responses)
- BC-2.08.004 — error fidelity (depends on: bind_tools error propagation)
- BC-2.08.006 — SDK crate split (depends on: tool-call serialisation in SDK crate)

## Architecture Anchors

- `pregolya-<provider>/src/chat_model.rs` — `bind_tools()` implementation (to be created)
- `pregolya-<provider>/src/tool_translation.rs` — tool call serialise/deserialise (to be created)
- `pregolya-standard-tests/src/chat_models/tool_calling.rs` — tool-calling battery (to be created)

## Story Anchor

S-2.07

## VP Anchors

- VP-BC208002-01, VP-BC208002-02, VP-BC208002-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009, CAP-011 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC specifies the tool-calling translation fidelity requirement every conforming provider must satisfy; CAP-011 ("Provider Conformance Suite (Standard Tests)") per capabilities-p1-p2.md §CAP-011 — this BC expresses the tool-calling subset of pregolya-standard-tests including the mandatory `test_agent_loop` |
| L2 Domain Invariants | — |
| NE References | — |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration, standard-tests tool-calling battery), U (unit — argument normalisation) |
| Module | pregolya-<provider> / pregolya-standard-tests |
