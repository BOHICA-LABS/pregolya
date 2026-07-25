---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.003
version: "1.4"
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
timestamp: 2026-07-15T00:00:00Z
changelog:
  - "1.0 (initial): base BC authored."
  - "1.1 (ADV-P1D-PASS-28): OBS-P28-3 — minted E-PROV-007 (StructuredOutputRefused, POLICY) for the OpenAI structured-output refusal path; added code literal to 4 construction sites (PC5, Invariant, EC-001, TV-004). Every FerrochainError now carries a machine-readable code per BC-2.14.001 posture."
  - "1.2 (ADV-P1D-PASS-29): F-P29-01 — EC-002 codeless FerrochainError fixed: added code: \"E-PROV-005\" to the deserialization-failure construction. Per BC-2.14.001 every-error-has-a-code invariant."
  - "1.3 (2026-07-15, F-P78-SWEEP/D18-P78-A): Two message-prefix corrections. (1) E-PROV-007 EC-001: added 'StructuredOutputRefused:' prefix; renamed placeholder '<refusal text>' to '<refusal_message>' for consistency with updated taxonomy. Taxonomy E-PROV-007 detail corrected from 'model refused to generate structured output — refusal_message: <message>' to '<refusal_message>' (BC wins on content). (2) E-PROV-005 EC-002: added 'StructuredOutputParseError:' prefix. Taxonomy E-PROV-005 detail corrected from 'provider response did not match expected JSON schema: <path> — <reason>' to '<reason>' (BC wins; elaborate schema-path wrapper was not in BC message)."
  - "1.4 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-<provider> / ferrochain-standard-tests per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-009
  - domain-spec/capabilities-p1-p2.md#CAP-011
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/partners/behavioral-intent.md
  - .factory/semport/partners/test-inventory.md
input-hash: "f41bc8e"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.003: Chat Model Structured Output Conformance

## Description

Every ferrochain provider chat model must pass the `ferrochain-standard-tests` structured
output battery when `has_structured_output = true`. The `with_structured_output(schema)`
method returns a `Runnable` whose output is deserialized into the requested schema type;
the method must support at minimum one of the three methods supported by the underlying
provider (function_calling, json_mode, json_schema). Providers that expose `json_mode`
must also pass `test_json_mode` separately. Optional fields in the schema must be handled
correctly (not forced to present or silently dropped).

## Preconditions

1. A ferrochain provider chat model is constructed for a model that supports structured
   output (e.g., `gpt-4o` with native JSON schema, `claude-3-5-sonnet` via tool forcing,
   `ChatOllama` via the `format` request field).
2. The provider crate sets `has_structured_output: bool = true` in its capability profile;
   `supports_json_mode: bool` is set separately per model.
3. A JSON Schema or equivalent Rust type (derived via `schemars::JsonSchema` or provided
   as a `serde_json::Value`) is available to pass to `with_structured_output`.
4. A record/replay HTTP fixture layer is available for CI.

## Postconditions

1. `test_structured_output` and `test_structured_output_async` (gated by
   `has_structured_output`): calling `model.with_structured_output::<T>(schema)` and
   invoking with an appropriate prompt returns a `T` that deserializes successfully from
   the provider response; the output does not panic or return `Err` on the happy path.
2. `test_structured_output_optional_param` (gated): a schema with `Option<T>` fields
   is honored — the model may omit the optional field; the output deserializes to
   `None` for that field rather than failing.
3. `test_structured_few_shot_examples` (gated): few-shot examples embedded in the prompt
   do not confuse the structured output parser; the final structured response is from the
   model's completion, not from an example in the prompt.
4. `test_json_mode` (gated by `supports_json_mode`): invoking with `method = "json_mode"`
   produces a `serde_json::Value` that is valid JSON (no leading/trailing text, no markdown
   fences, no explanatory prose outside the JSON object).
5. Provider-specific method routing:
   - OpenAI: `json_schema` method sets `response_format: { type: "json_schema", strict: true }`;
     refusal returns `Err(FerrochainError { category: POLICY, code: "E-PROV-007" })`.
   - Anthropic: `function_calling` method forces a single tool binding; `thinking` mode
     must be disabled for structured output requests (incompatibility documented).
   - Ollama: `format` field set to the resolved JSON schema.

## Invariants

- `with_structured_output` never produces `Ok(output)` where `output` contains
  unparsed JSON string — the output type `T` is always fully deserialized.
- Optional fields (`Option<T>`) in the schema must not be forced present by the adapter;
  if the model omits them, the value is `None`.
- The refusal case (OpenAI Responses API with strict JSON schema) propagates as a typed
  `FerrochainError { category: POLICY, code: "E-PROV-007" }` (StructuredOutputRefused) — not a deserialization error.
- `json_mode` output is a valid JSON object: no markdown code fences (```` ```json ````),
  no preamble text, no trailing prose.

## Edge Cases

### EC-001: Refusal in OpenAI native structured output
**Scenario:** The model refuses to answer (safety filter) when `method = "json_schema"`.
**Expected behavior:** `Err(FerrochainError { category: POLICY, code: "E-PROV-007", message: "StructuredOutputRefused: <refusal_message>" })`.
The caller can distinguish this from a deserialization failure (E-PROV-005) by checking `code`.

### EC-002: Schema has required field the model omits
**Scenario:** The schema requires `{ "answer": string }` but the model returns `{}`.
**Expected behavior:** Deserialization fails cleanly with `Err(FerrochainError
{ category: VAL, code: "E-PROV-005", message: "StructuredOutputParseError: missing required field 'answer'" })`. No panic.

### EC-003: Ollama `format` with full JSON schema vs `"json"` string
**Scenario:** `with_structured_output` is called on `ChatOllama` with a complex nested
schema (not just `"json"`).
**Expected behavior:** The `format` field in the request is set to the full JSON schema
object (not the string `"json"`), and the response deserializes to the target type.

### EC-004: thinking enabled on Anthropic model with structured output
**Scenario:** `ChatAnthropic` is constructed with `thinking = { type: "enabled" }` and
`with_structured_output(schema)` is called.
**Expected behavior:** The adapter clones the model with thinking disabled for the
structured output call. The response does not contain a `thinking` content block.
No error is raised; the caller receives a structured output response.

### EC-005: few-shot examples in system prompt
**Scenario:** The system prompt contains two JSON examples followed by the user prompt.
**Expected behavior:** The structured output parser uses only the final model completion
as the structured output source; the examples in the system prompt do not trigger
premature parsing.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `model.with_structured_output::<Joke>` + "Tell me a joke" | `Joke { setup: <non-empty>, punchline: <non-empty> }` | Happy path |
| TV-002 | Same, `Optional<extra>` field not set by model | `Joke { setup: ..., extra: None }` | Optional field |
| TV-003 | OpenAI `json_mode`, prompt asking for `{"name": "Alice"}` | `serde_json::Value::Object({ "name": "Alice" })` — no markdown fences | json_mode |
| TV-004 | OpenAI refusal with `json_schema` method | `Err(FerrochainError { category: POLICY, code: "E-PROV-007" })` | Refusal case (StructuredOutputRefused) |
| TV-005 | Ollama with complex nested schema | Deserialized `T` matching schema | Ollama format |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208003-01 | Structured output round-trips through deserialization without panic | Integration test (standard-tests structured output battery) | Wave 2 |
| VP-BC208003-02 | json_mode output contains no markdown fences or prose | Unit test (regex assertion on raw response text) | Wave 2 |
| VP-BC208003-03 | Optional fields absent in model response deserialize to None, not Err | Unit test (schema with optional field + cassette fixture) | Wave 2 |

## Related BCs

- BC-2.08.002 — tool-call (function_calling method uses bind_tools internally)
- BC-2.08.004 — error fidelity (refusal and validation errors must be typed FerrochainError)
- BC-2.08.006 — SDK crate split (request format construction lives in SDK crate)

## Architecture Anchors

- `ferrochain-<provider>/src/structured_output.rs` — `with_structured_output` implementation (to be created)
- `ferrochain-standard-tests/src/chat_models/structured_output.rs` — structured output battery (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC208003-01, VP-BC208003-02, VP-BC208003-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009, CAP-011 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC specifies the structured output translation contract that every conforming provider must satisfy; CAP-011 ("Provider Conformance Suite (Standard Tests)") per capabilities-p1-p2.md §CAP-011 — this BC expresses the structured output subset of ferrochain-standard-tests |
| L2 Domain Invariants | — |
| NE References | — |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | I (integration, standard-tests structured output battery), U (unit — json_mode format, optional field) |
| Module | ferrochain-<provider> / ferrochain-standard-tests |
