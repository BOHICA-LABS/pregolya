---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.013
version: "1.3"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-009
changelog:
  - "1.1 (OBS-P77-B, 2026-07-15): Architecture Anchor corrected — 'built-in enum variants' → 'built-in trait implementations'. ToolCallDialect is an object-safe pluggable trait (per BC body Description and interface-definitions v2.23); NativeOpenAiJson, NativeAnthropic, HermesChatMlXml are concrete struct implementations of that trait, not enum variants."
  - "1.2 (F-P108-03, 2026-07-18): EC-002 expanded from 2-field catch-all `{ dialect, reason }` to 4-field explicit struct `{ dialect, element, offset, parse_error }`. Adjudication: the taxonomy Message Format for E-PROV-009 has 4 distinct placeholders (`<dialect>`, `<element>`, `<n>`, `<parse_error>`); the `<n>` offset is MID-message (not trailing), making a catch-all `reason` structurally unable to render independent `<element>` and `<n>` values. Expanded variant: `{ dialect: \"HermesChatMlXml\", element: \"<tool_call>\", offset: 2, parse_error: \"key must be a string\" }`. Sibling sweep (all E-PROV-009 sites in this BC): PC8 uses PregolyaError message-template form (correctly shows 4 values in message string); PC9, EC-005, TV-006 use bare form (no struct fields; not subject to parity check). No taxonomy change needed — E-PROV-009 message format already shows 4 placeholders."
  - "1.3 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-2.08 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-009
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "a403241"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.013: Pluggable Tool-Call Dialect Seam (ToolCallDialect; Hermes ChatML XML)

## Description

pregolya providers translate tool definitions to model-specific wire formats and parse
tool-call responses back to `ContentBlock::ToolCall` via a pluggable `ToolCallDialect` trait
defined in `core::runnable`. Three built-in dialects are provided: `NativeOpenAiJson`
(OpenAI `tool_calls` JSON format), `NativeAnthropic` (Anthropic `tool_use` content blocks),
and `HermesChatMlXml` (Hermes XML dialect: `<tools>[…]</tools>` in system prompt;
`<tool_call>{json}</tool_call>` tags in assistant response). The dialect is selected
per-model at provider construction time via `ChatConfig.tool_call_dialect: ToolCallDialect`.
This BC specifies the full round-trip contract for all three dialects and the error behavior
when dialect parsing fails.

> **Error code minted here (E-PROV-009).** `E-PROV-009 ToolCallDialectParseError` is
> introduced by this BC. Category: VAL. Severity: broken. RetryHint: Never.
> Taxonomy row registration: sub-burst 2.

## Preconditions

1. A `ChatConfig` is constructed with `tool_call_dialect: ToolCallDialect` set to one of
   `NativeOpenAiJson`, `NativeAnthropic`, or `HermesChatMlXml` (or a custom implementor).
2. The chat model is invoked with at least one bound tool; the provider sends the tool
   definitions to the model using the configured dialect's serialization format.
3. A model response is received and must be parsed back to `AiMessage` content.

## Postconditions

**NativeOpenAiJson dialect:**
1. Tool definitions are serialized as the `tools` field of the OpenAI chat-completions
   request body: `[{ "type": "function", "function": { "name": "…", "description": "…",
   "parameters": {…} } }]`.
2. Model responses containing `tool_calls` JSON objects are parsed to
   `Vec<ContentBlock::ToolCall { id, name, args }>`.

**NativeAnthropic dialect:**
3. Tool definitions are serialized as the `tools` field of the Anthropic messages request
   body: `[{ "name": "…", "description": "…", "input_schema": {…} }]`.
4. Model responses containing `tool_use` content blocks are parsed to
   `Vec<ContentBlock::ToolCall { id, name, args }>`.

**HermesChatMlXml dialect:**
5. Tool definitions are emitted into the **system prompt** as an XML block:
   `<tools>[{"name": "…", "description": "…", "parameters": {…}}]</tools>`. The existing
   system instruction (if any) is prepended before the `<tools>` block.
6. The model's assistant response is scanned for `<tool_call>{json}</tool_call>` tags. For
   each such tag, the JSON payload is extracted, parsed, and emitted as
   `ContentBlock::ToolCall { name: parsed.name, args: parsed.arguments }`.
7. Text content outside `<tool_call>` tags in the same response is preserved as
   `ContentBlock::Text` in the `AiMessage` content list (partial-text + tool-call
   co-occurrence is valid).
8. `<tool_call>` tag content that is not valid JSON returns
   `Err(PregolyaError { component: PROV, category: VAL, code: "E-PROV-009",
   message: "ToolCallDialectParseError: HermesChatMlXml <tool_call> payload is not valid JSON
   at response offset <n>: <parse_error>", retry_hint: Never })`.

**All dialects:**
9. A `ToolCallDialect` implementation that returns an error from serialization or
   deserialization surfaces `Err(E-PROV-009 ToolCallDialectParseError)`. The error message
   identifies the dialect and the failure point.
10. The `ToolCallDialect` trait is object-safe and implementable by operators for custom
    model dialects not covered by the three built-in variants.

## Invariants

- **Dialect is a per-model-construction setting.** It is not swapped mid-invocation and
  not derived from the model's response format at runtime. One `ChatConfig` → one dialect.
- **Round-trip fidelity:** for all three built-in dialects, a tool definition serialized
  by the dialect and then deserialized from the model's response must yield a `ToolCall`
  with name equal to the original tool name (case-sensitive, Unicode-safe) and args equal
  to the model's argument JSON (DI-014: no silent data loss).
- **HermesChatMlXml tool definitions in system prompt:** the `<tools>` block is appended to
  the system prompt (never replaces it). If no system instruction is set, the `<tools>`
  block becomes the entire system content.
- **No implicit dialect fallback:** if the configured dialect fails to parse the response,
  the error is E-PROV-009. pregolya does NOT auto-detect an alternative dialect
  from the response format.

## Edge Cases

### EC-001: HermesChatMlXml — response contains both text and a tool call
**Scenario:** Model emits: `"I'll check the weather for you. <tool_call>{"name": "get_weather",
"arguments": {"location": "Paris"}}</tool_call>"`
**Expected behavior:** `AiMessage.content = [ContentBlock::Text("I'll check the weather for
you. "), ContentBlock::ToolCall { name: "get_weather", args: { "location": "Paris" } }]`.
Text outside tags preserved; tool call parsed.

### EC-002: HermesChatMlXml — malformed JSON in tool_call tag
**Scenario:** Model emits `<tool_call>{name: get_weather}</tool_call>` (not valid JSON).
**Expected behavior:** `Err(E-PROV-009 ToolCallDialectParseError { dialect: "HermesChatMlXml",
element: "<tool_call>", offset: 2, parse_error: "key must be a string" })`.

### EC-003: HermesChatMlXml — multiple tool calls in one response
**Scenario:** Model emits two `<tool_call>` tags in one assistant message.
**Expected behavior:** Both are parsed to separate `ContentBlock::ToolCall` entries in
`AiMessage.content`. Order preserved (left-to-right tag order).

### EC-004: NativeOpenAiJson — model response contains no tool_calls field
**Scenario:** Model produces a plain text response when tools were bound.
**Expected behavior:** `AiMessage.content = [ContentBlock::Text("…")]` — no `ToolCall`
blocks. This is a valid model decision not to call a tool; not an error.

### EC-005: Custom dialect implementor raises parse error
**Scenario:** A custom `ToolCallDialect` returns `Err` from its deserialization method.
**Expected behavior:** `Err(E-PROV-009 ToolCallDialectParseError)` propagated to the caller
with the implementor's error message embedded. (DI-014: error not swallowed.)

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `NativeOpenAiJson` dialect; bind tool `get_weather`; model returns `{"tool_calls":[{"id":"call_1","type":"function","function":{"name":"get_weather","arguments":"{\"location\":\"Paris\"}"}}]}` | `AiMessage` containing `ToolCall { id: "call_1", name: "get_weather", args: {"location": "Paris"} }` | OpenAI native round-trip |
| TV-002 | `NativeAnthropic` dialect; bind tool `search`; Anthropic response contains `tool_use` block | `AiMessage` containing `ToolCall { name: "search", args: {…} }` | Anthropic native round-trip |
| TV-003 | `HermesChatMlXml` dialect; bind tool `get_weather`; request inspected | System prompt contains `<tools>[{"name":"get_weather",…}]</tools>` | Hermes: tools in system prompt |
| TV-004 | `HermesChatMlXml`; model response `<tool_call>{"name":"get_weather","arguments":{"location":"Paris"}}</tool_call>` | `ToolCall { name: "get_weather", args: {"location": "Paris"} }` | Hermes XML parse |
| TV-005 | `HermesChatMlXml`; response with text + tool_call tag | `[Text("…"), ToolCall{…}]` in content | Mixed text + tool call |
| TV-006 | `HermesChatMlXml`; malformed JSON in `<tool_call>` tag | `Err(E-PROV-009 ToolCallDialectParseError)` | Malformed payload |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-DIALECT-01 | HermesChatMlXml full round-trip: tool definition in system prompt; `<tool_call>` response parsed to ToolCall | Integration test with Hermes-dialect mock provider | Wave 2 |
| VP-DIALECT-02 | All three dialects produce identical `ToolCall` structs for the same logical tool invocation | Parametric unit test across 3 dialect fixtures | Wave 2 |

## Related BCs

- BC-2.08.002 — composes with: tool-call round-trip conformance; this BC adds the dialect seam layer that BC-2.08.002's conformance tests must exercise per dialect
- BC-2.08.001 — composes with: streaming tool-call chunks must also respect the configured dialect
- BC-2.08.004 — depends on: provider error fidelity applies when E-PROV-009 is raised

## Architecture Anchors

- `pregolya-core/src/runnable.rs` (or `pregolya-core/src/tool_dialect.rs`) — `ToolCallDialect` trait definition; `NativeOpenAiJson`, `NativeAnthropic`, `HermesChatMlXml` built-in trait implementations; `ChatConfig.tool_call_dialect: ToolCallDialect` field
- `pregolya-<provider>/src/tool_translation.rs` — per-dialect `serialize_tools(tools: &[Tool]) -> ProviderRequest` and `parse_response(raw: ResponseBody) -> Result<AiMessage, PregolyaError>` implementations
- `pregolya-openai/src/chat_model.rs`, `pregolya-anthropic/src/chat_model.rs` — dialect selection at construction time

## Story Anchor

S-2.08

## VP Anchors

- VP-DIALECT-01, VP-DIALECT-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC specifies the pluggable tool-call serialization/deserialization seam that conforming providers must implement; the Hermes ChatML XML dialect is a third dialect alongside native OpenAI JSON and native Anthropic tool_use, all covered under the "pass pregolya-standard-tests for tool calling" requirement of CAP-009 |
| L2 Domain Invariants | DI-008 (constructors return Result; E-PROV-009 is Err not panic), DI-014 (Error Propagation — dialect parse errors propagate as Err; no silent data loss) |
| Error Code Minted | E-PROV-009 ToolCallDialectParseError — VAL, broken, Never. PROV namespace had 8 live codes (E-PROV-001 through E-PROV-008); E-PROV-009 is next. Taxonomy row: sub-burst 2. |
| Domain D Forcing Function | domain-d-hermes-agent.md req 1 — "[PARTIAL CAP-009/BC-2.08.002] … no parser seam for non-native dialects (Hermes `<tool_call>{json}</tool_call>` XML)"; this BC fills that gap |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit), I (integration) |
| Module | pregolya-core (ToolCallDialect trait) / pregolya-<provider> (dialect dispatch) |
