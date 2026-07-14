---
document_type: behavioral-contract
level: L3
bc_id: BC-2.01.001
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

# BC-2.01.001: Typed ContentBlock Sequence Construction (No Raw Content Where Typed Expected)

## Description

ferrochain-core must represent every message content value as a closed-variant typed `ContentBlock`
enum rather than an untyped `String` or `Map<String, Value>`. When a caller constructs a typed
message, the content sequence must be `Vec<ContentBlock>` and the compiler must prevent raw-string
content from satisfying a typed-content parameter. This contract encodes the LangChain v1
"content-block-native" design (semport/core/behavioral-intent.md §2) and enforces DI-008 at construction time.

## Preconditions

1. The caller is constructing a message with one or more content blocks.
2. The ferrochain-core crate defines the `ContentBlock` enum with all standard variants
   (Text, Reasoning, ToolCall, ToolCallChunk, InvalidToolCall, Image, Video, Audio,
   PlainText, File, ServerToolCall, ServerToolCallChunk, ServerToolResult, NonStandard).
3. The construction call is in non-test code.

## Postconditions

1. Every message-content parameter in ferrochain-core's public API that represents typed
   content accepts `Vec<ContentBlock>` (not `Vec<serde_json::Value>` or `Vec<String>`).
2. A `ContentBlock::Text(TextContentBlock { text, annotations })` construction compiles and
   carries the exact text passed.
3. A raw `String` value is NOT accepted where a `Vec<ContentBlock>` is required — the Rust
   type system prevents implicit coercion.
4. The `MessageContent` enum `{ Text(String), Blocks(Vec<ContentBlock>) }` allows either
   form, but callers requesting typed access receive `Vec<ContentBlock>` after normalization.
5. An unknown provider-specific block maps to `ContentBlock::NonStandard { value: serde_json::Value }`
   rather than causing a deserialization error.
6. Construction succeeds and returns `Ok(message)` when all content block types are valid;
   construction returns `Err(FerrochainError { category: VAL, code: E-CORE-001 })` when an
   unrecognized block type is encountered and the API contract requires strict validation.

## Invariants

- **DI-008 (Library Constructor Result Contract):** All content block construction functions
  that can fail return `Result<T, FerrochainError>` — never panic.
- The `KNOWN_BLOCK_TYPES` set governs standard-vs-provider dispatch; a variant not in the set
  maps to `NonStandard` rather than being rejected.
- `ContentBlock` is a closed serde-tagged enum; serde deserialization from `{"type": "text", ...}`
  produces `ContentBlock::Text(...)`, not a `Map`.
- `MessageContent::Text(s)` and `MessageContent::Blocks(v)` are semantically equivalent views
  of the same information — transitioning from text to blocks via a normalization call must
  not lose content.

## Edge Cases

### EC-001: Unknown block type in provider response
**Scenario:** A provider returns a block with `"type": "provider_specific_block"` that is not
in the standard set.
**Expected behavior:** The block deserializes as `ContentBlock::NonStandard { value: {...} }`.
The message is valid; no error is returned. The caller may inspect the value field.
**Reference:** semport/core/behavioral-intent.md §2 (`KNOWN_BLOCK_TYPES` set).

### EC-002: Empty content sequence
**Scenario:** A caller constructs a message with `content: vec![]` (zero blocks).
**Expected behavior:** Construction succeeds. The message carries an empty content sequence.
Downstream operations that require at least one block (e.g. model invocation) may return
a separate validation error, but the construction itself does not fail.

### EC-003: Raw string content in blocks-typed parameter
**Scenario:** A caller attempts to pass a `String` directly to a parameter typed `Vec<ContentBlock>`.
**Expected behavior:** Compilation failure — no implicit coercion from `String` to `ContentBlock`.
The caller must wrap in `ContentBlock::Text(TextContentBlock { text: s, annotations: vec![] })`.

### EC-004: Mixed block types in single message
**Scenario:** A message contains `[ContentBlock::Text(...), ContentBlock::Image(...), ContentBlock::ToolCall(...)]`.
**Expected behavior:** All blocks are accepted in sequence; the resulting `Vec<ContentBlock>` preserves
insertion order. Each block is independently accessible by variant match.

### EC-005: Serde round-trip with extras field
**Scenario:** A `TextContentBlock` with an `extras` field containing provider metadata is
serialized and deserialized.
**Expected behavior:** The `extras: Map<String, Value>` (or `#[serde(flatten)]` equivalent) round-trips
faithfully; no extras data is silently dropped.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `ContentBlock::Text(TextContentBlock { text: "hello".into(), annotations: vec![] })` | Serializes as `{"type":"text","text":"hello"}` | Happy path — basic text block |
| TV-002 | `ContentBlock::Image(ImageContentBlock { url: "https://example.com/img.png".into(), ... })` | Serializes as `{"type":"image","url":"https://example.com/img.png",...}` | Multimodal block |
| TV-003 | Deserialize `{"type":"unknown_provider","data":{}}` into `ContentBlock` | `ContentBlock::NonStandard { value: {"type":"unknown_provider","data":{}} }` | Unknown type → NonStandard |
| TV-004 | `MessageContent::Text("hello".into())` → normalize to blocks | `vec![ContentBlock::Text(TextContentBlock { text: "hello", annotations: vec![] })]` | Text→Blocks normalization |
| TV-005 | Pass raw `String` to `fn accepts_blocks(v: Vec<ContentBlock>)` | Compile error | Type-system enforcement |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC201001-01 | Round-trip: `ContentBlock::Text` serializes and deserializes to identical value | Unit test (serde round-trip) | Wave 0 |
| VP-BC201001-02 | Unknown block type always maps to NonStandard, never panics | Property test (arbitrary JSON objects with unknown type fields) | Wave 0 |

## Related BCs

- BC-2.01.002 — Message type-safety (depends on: typed content blocks are the content payload of typed messages)
- BC-2.01.003 — Runnable trait invocation (composes with: messages are the primary Input/Output types of chat model Runnables)
- BC-2.14.001 — FerrochainError 2D struct (depends on: construction errors propagate via FerrochainError)
- BC-2.14.003 — Constructor Result contract (depends on: content block construction must return Result, not panic)

## Architecture Anchors

- `ferrochain-core/src/messages/content.rs` — `ContentBlock` enum definition (to be created)
- `ferrochain-core/src/messages/base.rs` — `MessageContent` enum and normalization (to be created)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC201001-01, VP-BC201001-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-001 |
| Capability Anchor Justification | CAP-001 ("Type-Safe Message and Content Primitive Construction") per capabilities-p0.md §CAP-001 — this BC enforces the "no raw untyped content where typed variant is expected" guarantee that CAP-001 mandates as its central invariant |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract) |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), CT (compile-time type check), ST (serde round-trip) |
| Module | [architect to assign — ferrochain-core] |
