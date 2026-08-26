---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.002
version: "1.6"
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
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-core per module-decomposition.md v1.10."
  - "1.2 (FIX-BURST-B5-WAVE-B/2026-07-29): Error-construction notation sweep (ADR-010 §Class 3). Three sites corrected: PC5 single-line span (E-CORE-002, bare wrapper missing `, ..`); EC-002 multiline span continuation line (E-CORE-002, `, ..` added before closing `})`); TV-004 table-cell span (E-CORE-002, `, ..` added). All spans have category/code but lack component and retry_hint."
  - "1.3 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.03 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.4 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.5 (M3b/ADR-027-escalation-2/2026-08-24): Added {INV-005} — Message hierarchy #[non_exhaustive] clause; authoring missing production-grade invariant per CLAUDE.md workspace-wide mandate (S-1.03 AC-012 escalation)."
  - "1.6 (P2-bc-completeness-burst-B/SS-01..03/2026-08-26): Gap BC-2.01.002 MED — INV-002 listed 'chat' discriminant with no specification of ChatMessage variant fields or behavior. Decision: keep 'chat' in accepted set (LangChain ChatMessage is a legitimate API surface for arbitrary-role messages). Added {PC-008} specifying ChatMessage fields (role: String required, content: MessageContent) and round-trip behavior; added {EC-006} showing ChatMessage with an arbitrary role value. Added INV-002 annotation clarifying the 'chat' discriminant requires a non-empty role field."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-001
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/semport/core/behavioral-intent.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "e21c7f4"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.01.002: Message Type-Safety (AiMessage / HumanMessage / SystemMessage / ToolMessage)

## Description

pregolya-core exposes a closed `Message` enum with exactly four primary variants:
`Ai(AiMessage)`, `Human(HumanMessage)`, `System(SystemMessage)`, `Tool(ToolMessage)`.
No caller may construct a message with an unrecognized role string. Each variant carries
typed metadata unique to its role (e.g., `AiMessage` carries `tool_calls`, `usage_metadata`;
`ToolMessage` carries `tool_call_id`). Construction of any variant returns `Ok(msg)` or a
typed `Err(PregolyaError)` — it never panics.

## Preconditions

1. {PRE-001} The caller is constructing or deserializing a chat message in pregolya-core.
2. {PRE-002} The pregolya-core crate defines the `Message` serde-tagged enum with the standard
   role variants and their typed payloads.
3. {PRE-003} The construction call is in non-test code.

## Postconditions

1. {PC-001} `Message::Ai(AiMessage { content, tool_calls, invalid_tool_calls, usage_metadata, id, name, .. })`
   compiles and carries the exact fields supplied.
2. {PC-002} `Message::Human(HumanMessage { content, id, name, .. })` compiles and carries the supplied fields.
3. {PC-003} `Message::System(SystemMessage { content, id, name, .. })` compiles and carries the supplied fields.
4. {PC-004} `Message::Tool(ToolMessage { content, tool_call_id, id, name, .. })` requires `tool_call_id`
   and fails compilation without it — the field is NOT `Option<String>` but `String`.
5. {PC-005} Deserialization of `{"type":"ai","content":"hello"}` produces `Message::Ai(...)` with the
   correct variant; deserialization of `{"type":"unknown_role","content":"x"}` returns
   `Err(PregolyaError { category: VAL, code: E-CORE-002, .. })` — not a panic.
6. {PC-006} `Message` is `Serialize + DeserializeOwned`; round-trip serialization preserves all fields
   including `additional_kwargs` (captured via `#[serde(flatten)]` extras map).
7. {PC-007} Legacy role string `"function"` deserializes as the `Function(FunctionMessage)` legacy variant
   rather than erroring — backward compatibility with serialized data.
8. {PC-008} The `"chat"` discriminant deserializes as `Message::Chat(ChatMessage { role, content, .. })`
   where `role` is the arbitrary role string carried in the JSON `"role"` field (required, non-empty)
   and `content` is the message body. Construction via
   `Message::Chat(ChatMessage { role: "custom_role".into(), content: MessageContent::Text("...".into()), .. })`
   compiles and carries the supplied role string. Round-trip serialization preserves the `role` field
   verbatim. `ChatMessage` is distinct from the four primary variants — it does NOT restrict the role
   to `"ai"`, `"human"`, `"system"`, or `"tool"`; it accepts any non-empty string. Deserialization
   of `{"type":"chat"}` without a `"role"` field returns `Err(PregolyaError { category: VAL,
   code: E-CORE-002, .. })` because the `role` field is required.

## Invariants

- {INV-001} **DI-008 (Library Constructor Result Contract):** All fallible construction paths return
  `Result<Message, PregolyaError>` — `unwrap` and `expect` are absent from non-test code.
- {INV-002} The `type` field is a discriminant literal per variant: `"ai"`, `"human"`, `"system"`, `"tool"`,
  `"function"` (legacy), `"chat"` (arbitrary-role — carries a required non-empty `"role"` field as the
  actual role string; see PC-008), `"remove"` (history control).
- {INV-003} `ToolMessage.tool_call_id` is a required `String` field — it must be provided at construction;
  no default is supplied.
- {INV-004} `AiMessage.usage_metadata` is `Option<UsageMetadata>` — may be absent for non-model-generated
  messages (e.g. messages loaded from a checkpoint without token metadata).
- {INV-005} `Message`, `AiMessage`, `HumanMessage`, `SystemMessage`, and `ToolMessage` are each annotated
  `#[non_exhaustive]`; external code matching on `Message` variants must include a wildcard arm
  (`_ => {}`). The attribute applies to all public structs and enums in the message hierarchy per
  the workspace-wide `#[non_exhaustive]` mandate (CLAUDE.md §Code Conventions).

## Edge Cases

### EC-001: ToolMessage constructed without tool_call_id
**Scenario:** A caller attempts to build `ToolMessage { content: ..., /* tool_call_id omitted */ }`.
**Expected behavior:** Compile-time error — `tool_call_id` is a required field with no default.
**Reference:** semport/core/behavioral-intent.md §2 (ToolMessage carries `tool_call_id`).

### EC-002: Deserialization of unknown message role
**Scenario:** A checkpoint stores a message with `{"type":"deprecated_agent","content":"x"}`.
**Expected behavior:** Deserialization returns `Err(PregolyaError { category: VAL, code: E-CORE-002,
message: "Message role 'deprecated_agent' is not a recognized message type", .. })`. The message is
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

### EC-006: ChatMessage with arbitrary role
**Scenario:** A caller constructs a message with role `"assistant_v2"` (not one of the standard
four variants) by deserializing `{"type":"chat","role":"assistant_v2","content":"hello"}`.
**Expected behavior:** Deserialization produces
`Message::Chat(ChatMessage { role: "assistant_v2", content: MessageContent::Text("hello"), .. })`.
Round-trip serialization preserves `"type":"chat"` and `"role":"assistant_v2"`. The message is
a valid `Message` and can be stored in a checkpoint or passed downstream.
Attempting to deserialize `{"type":"chat","content":"hello"}` (missing `role` field) returns
`Err(PregolyaError { category: VAL, code: E-CORE-002, .. })`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `Message::Human(HumanMessage { content: MessageContent::Text("hi".into()), .. })` | Serializes as `{"type":"human","content":"hi"}` | Happy path — human message |
| TV-002 | `Message::Ai(AiMessage { content: ..., tool_calls: vec![tc], usage_metadata: Some(um), .. })` | All fields present in serialized form; `usage_metadata.input_tokens`, `.output_tokens`, `.total_tokens` numeric | AiMessage with tool call and usage |
| TV-003 | `Message::Tool(ToolMessage { content: MessageContent::Text("result".into()), tool_call_id: "call_abc".into(), .. })` | Serializes as `{"type":"tool","content":"result","tool_call_id":"call_abc"}` | ToolMessage with required id |
| TV-004 | Deserialize `{"type":"invalid_role","content":"x"}` | `Err(PregolyaError { category: VAL, code: E-CORE-002, .. })` | Unknown role → error |
| TV-005 | Deserialize `{"type":"function","content":"x","name":"fn_name"}` | `Message::Function(FunctionMessage { content: "x", name: "fn_name" })` | Legacy function role passes |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC201002-01 | Round-trip: all standard Message variants serialize and deserialize to identical value | Unit test (serde round-trip per variant) | Wave 0 |
| VP-BC201002-02 | Unknown role always returns Err(E-CORE-002), never panics | Unit test + property test (arbitrary role strings) | Wave 0 |

## Related BCs

- BC-2.01.001 — Typed ContentBlock construction (depends on: Message content is `Vec<ContentBlock>` after normalization)
- BC-2.01.003 — Runnable trait invocation (composes with: Messages are the primary input/output type of chat model Runnables)
- BC-2.14.001 — PregolyaError 2D struct (depends on: deserialization errors propagate as PregolyaError)
- BC-2.14.003 — Constructor Result contract (depends on: message construction must return Result, not panic)

## Architecture Anchors

- `pregolya-core/src/messages/base.rs` — `Message` enum, `AiMessage`, `HumanMessage`, `SystemMessage`, `ToolMessage` (to be created)
- `pregolya-core/src/messages/ai.rs` — `AiMessage` with `tool_calls`, `usage_metadata` fields (to be created)

## Story Anchor

S-1.03

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
| Module | pregolya-core |
