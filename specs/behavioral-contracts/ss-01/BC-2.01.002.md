---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.002
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-01
capability: CAP-001
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-001
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/behavioral-intent.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "19a5567c0bc106d5cf83270335021aea43256ce374f0df4652894fc0deda7e67"
---

# BC-2.01.002: Message Type-Safety (AiMessage / HumanMessage / SystemMessage / ToolMessage)

## Description

ferrochain-core exposes a closed `Message` enum with exactly four primary variants:
`Ai(AiMessage)`, `Human(HumanMessage)`, `System(SystemMessage)`, `Tool(ToolMessage)`.
No caller may construct a message with an unrecognized role string. Each variant carries
typed metadata unique to its role (e.g., `AiMessage` carries `tool_calls`, `usage_metadata`;
`ToolMessage` carries `tool_call_id`). Construction of any variant returns `Ok(msg)` or a
typed `Err(FerrochainError)` — it never panics.

## Preconditions

1. The caller is constructing or deserializing a chat message in ferrochain-core.
2. The ferrochain-core crate defines the `Message` serde-tagged enum with the standard
   role variants and their typed payloads.
3. The construction call is in non-test code.

## Postconditions

1. `Message::Ai(AiMessage { content, tool_calls, invalid_tool_calls, usage_metadata, id, name, .. })`
   compiles and carries the exact fields supplied.
2. `Message::Human(HumanMessage { content, id, name, .. })` compiles and carries the supplied fields.
3. `Message::System(SystemMessage { content, id, name, .. })` compiles and carries the supplied fields.
4. `Message::Tool(ToolMessage { content, tool_call_id, id, name, .. })` requires `tool_call_id`
   and fails compilation without it — the field is NOT `Option<String>` but `String`.
5. Deserialization of `{"type":"ai","content":"hello"}` produces `Message::Ai(...)` with the
   correct variant; deserialization of `{"type":"unknown_role","content":"x"}` returns
   `Err(FerrochainError { category: VAL, code: E-CORE-002 })` — not a panic.
6. `Message` is `Serialize + DeserializeOwned`; round-trip serialization preserves all fields
   including `additional_kwargs` (captured via `#[serde(flatten)]` extras map).
7. Legacy role string `"function"` deserializes as the `Function(FunctionMessage)` legacy variant
   rather than erroring — backward compatibility with serialized data.

## Invariants

- **DI-008 (Library Constructor Result Contract):** All fallible construction paths return
  `Result<Message, FerrochainError>` — `unwrap` and `expect` are absent from non-test code.
- The `type` field is a discriminant literal per variant: `"ai"`, `"human"`, `"system"`, `"tool"`,
  `"function"` (legacy), `"chat"` (arbitrary-role), `"remove"` (history control).
- `ToolMessage.tool_call_id` is a required `String` field — it must be provided at construction;
  no default is supplied.
- `AiMessage.usage_metadata` is `Option<UsageMetadata>` — may be absent for non-model-generated
  messages (e.g. messages loaded from a checkpoint without token metadata).

## Edge Cases

### EC-001: ToolMessage constructed without tool_call_id
**Scenario:** A caller attempts to build `ToolMessage { content: ..., /* tool_call_id omitted */ }`.
**Expected behavior:** Compile-time error — `tool_call_id` is a required field with no default.
**Reference:** semport/core/behavioral-intent.md §2 (ToolMessage carries `tool_call_id`).

### EC-002: Deserialization of unknown message role
**Scenario:** A checkpoint stores a message with `{"type":"deprecated_agent","content":"x"}`.
**Expected behavior:** Deserialization returns `Err(FerrochainError { category: VAL, code: E-CORE-002,
message: "Message role 'deprecated_agent' is not a recognized message type" })`. The message is
not silently dropped or converted to a garbage variant.

### EC-003: AiMessage with both content string and tool_calls
**Scenario:** An AI response carries `"content": ""` (empty string) and `tool_calls: [ToolCall {...}]`.
**Expected behavior:** Both fields co-exist. The `content` field is `MessageContent::Text("")` and
`tool_calls` is a non-empty `Vec<ToolCall>`. Neither field overrides the other.
**Reference:** semport/core/behavioral-intent.md §2 (AIMessage.tool_calls alongside content).

### EC-004: Message serde round-trip with additional_kwargs
**Scenario:** A message carries provider-specific extra fields not in the typed schema
(e.g. `"refusal": "I can't do that"`).
**Expected behavior:** The extra fields are preserved in an `additional_kwargs: Map<String, Value>`
capture field via `#[serde(flatten)]`. Round-trip serialization includes these fields unchanged.

### EC-005: RemoveMessage as history control token
**Scenario:** A graph node injects a `Message::Remove(RemoveMessage { id: "msg-42" })` to delete
an entry from conversation history.
**Expected behavior:** The variant is accepted as a valid `Message`. Downstream history-management
code interprets it as a control signal, not as a content-bearing message.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `Message::Human(HumanMessage { content: MessageContent::Text("hi".into()), .. })` | Serializes as `{"type":"human","content":"hi"}` | Happy path — human message |
| TV-002 | `Message::Ai(AiMessage { content: ..., tool_calls: vec![tc], usage_metadata: Some(um), .. })` | All fields present in serialized form; `usage_metadata.input_tokens`, `.output_tokens`, `.total_tokens` numeric | AiMessage with tool call and usage |
| TV-003 | `Message::Tool(ToolMessage { content: MessageContent::Text("result".into()), tool_call_id: "call_abc".into(), .. })` | Serializes as `{"type":"tool","content":"result","tool_call_id":"call_abc"}` | ToolMessage with required id |
| TV-004 | Deserialize `{"type":"invalid_role","content":"x"}` | `Err(FerrochainError { category: VAL, code: E-CORE-002 })` | Unknown role → error |
| TV-005 | Deserialize `{"type":"function","content":"x","name":"fn_name"}` | `Message::Function(FunctionMessage { content: "x", name: "fn_name" })` | Legacy function role passes |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC201002-01 | Round-trip: all standard Message variants serialize and deserialize to identical value | Unit test (serde round-trip per variant) | Wave 0 |
| VP-BC201002-02 | Unknown role always returns Err(E-CORE-002), never panics | Unit test + property test (arbitrary role strings) | Wave 0 |

## Related BCs

- BC-2.01.001 — Typed ContentBlock construction (depends on: Message content is `Vec<ContentBlock>` after normalization)
- BC-2.01.003 — Runnable trait invocation (composes with: Messages are the primary input/output type of chat model Runnables)
- BC-2.14.001 — FerrochainError 2D struct (depends on: deserialization errors propagate as FerrochainError)
- BC-2.14.003 — Constructor Result contract (depends on: message construction must return Result, not panic)

## Architecture Anchors

- `ferrochain-core/src/messages/base.rs` — `Message` enum, `AiMessage`, `HumanMessage`, `SystemMessage`, `ToolMessage` (to be created)
- `ferrochain-core/src/messages/ai.rs` — `AiMessage` with `tool_calls`, `usage_metadata` fields (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC201002-01, VP-BC201002-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-001 |
| Capability Anchor Justification | CAP-001 ("Type-Safe Message and Content Primitive Construction") per capabilities-p0.md §CAP-001 — this BC directly implements the typed-message hierarchy (AiMessage/HumanMessage/SystemMessage/ToolMessage) which is the primary API-surface root primitive identified in CAP-001 |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract) |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), CT (compile-time type check), ST (serde round-trip) |
| Module | [architect to assign — ferrochain-core] |
