---
document_type: story
level: ops
story_id: S-1.03
epic_id: E-01
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-18T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.002.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "431744e"
traces_to: .factory/stories/STORY-INDEX.md
points: 5
depends_on: [S-1.01]
blocks: [S-1.04]
behavioral_contracts: [BC-2.01.001, BC-2.01.002]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-core
subsystems: [SS-01]
estimated_days: 1
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-1.03: Message and ContentBlock Type System

## Narrative

- **As a** pregolya library user and provider implementer
- **I want to** have a complete, serde-serializable `Message` enum and `ContentBlock` enum that cover all LangChain-parity message roles and content types
- **So that** I can pass structured messages through chains, preserve unknown block types without data loss, and receive structured `PregolyaError` when an unknown role appears

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.01.001 | Typed ContentBlock Sequence Construction (No Raw Content Where Typed Expected) | AC-001..AC-006 |
| BC-2.01.002 | Message Type-Safety (AiMessage / HumanMessage / SystemMessage / ToolMessage) | AC-007..AC-012 |

## Acceptance Criteria

### AC-001 (traces to BC-2.01.001 postcondition 1)
`ContentBlock` is an enum with at least the following variants: `Text(String)`, `Reasoning(String)`, `ToolCall { id: String, name: String, arguments: String }`, `ToolCallChunk { id: String, index: u32, delta: String }`, `InvalidToolCall { id: String, error: String }`, `Image { media_type: String, data: String }`, `Video { url: String }`, `Audio { data: String, format: String }`, `PlainText(String)`, `File { name: String, mime_type: String, data: String }`, `ServerToolCall { id: String, name: String, input: serde_json::Value }`, `ServerToolCallChunk { id: String, index: u32, delta: serde_json::Value }`, `ServerToolResult { tool_use_id: String, content: serde_json::Value }`, `NonStandard { value: serde_json::Value }`. Verified by `test_BC_2_01_001_content_block_variants()` which constructs each variant.

### AC-002 (traces to BC-2.01.001 postcondition 2)
`serde_json::from_str::<ContentBlock>(r#"{"type":"text","text":"hello"}"#)` succeeds and returns `ContentBlock::Text("hello".to_string())`. Serde deserialization uses the `type` tag field. Verified by `test_BC_2_01_001_content_block_serde()`.

### AC-003 (traces to BC-2.01.001 postcondition 3)
`serde_json::from_str::<ContentBlock>(r#"{"type":"unknown_future_type","foo":"bar"}"#)` returns `ContentBlock::NonStandard { value: serde_json::Value }` (NOT an error). The unknown block is preserved verbatim as a `Value`. Verified by `test_BC_2_01_001_unknown_block_nonstandard()`.

### AC-004 (traces to BC-2.01.001 postcondition 4)
`MessageContent` is an enum with variants: `Text(String)` (for simple string content) and `Blocks(Vec<ContentBlock>)` (for structured multi-block content). Both variants serialize/deserialize correctly. Verified by `test_BC_2_01_001_message_content()`.

### AC-005 (traces to BC-2.01.001 postcondition 5)
`ContentBlock` has `#[non_exhaustive]` applied. An external-crate match without a wildcard arm fails to compile. `ContentBlock` implements `Debug`, `Clone`. Verified by compile-fail test.

### AC-006 (traces to BC-2.01.001 edge case EC-006 — E-CORE-001)
When strict content block validation mode is active and a block has an unrecognized type tag with no fallback, the error is `Err(PregolyaError { code: "E-CORE-001", message: "StrictContentBlockValidation: block at position <n> has unrecognized type tag '<type>'; not in KNOWN_BLOCK_TYPES — use lenient deserialization for NonStandard passthrough", .. })`. In the default (non-strict) mode, `NonStandard` is returned instead. Verified by `test_BC_2_01_001_strict_mode_error()`.

### AC-007 (traces to BC-2.01.002 postcondition 1)
`Message` is an enum with at minimum: `Ai(AiMessage)`, `Human(HumanMessage)`, `System(SystemMessage)`, `Tool(ToolMessage)`. Each inner type has a `content: MessageContent` field. `Tool(ToolMessage)` has `tool_call_id: String` (not `Option<String>`). Verified by `test_BC_2_01_002_message_variants()`.

### AC-008 (traces to BC-2.01.002 postcondition 2)
Legacy message types exist for Python port compatibility: `Function(FunctionMessage)`, `Remove(RemoveMessage)`, `Chat(ChatMessage)`. They serialize and deserialize correctly. Verified by `test_BC_2_01_002_legacy_variants()`.

### AC-009 (traces to BC-2.01.002 postcondition 3)
`serde_json::from_str::<Message>(r#"{"type":"human","content":"hello"}"#)` succeeds and returns `Message::Human(HumanMessage { content: MessageContent::Text("hello".to_string()), .. })`. Verified by `test_BC_2_01_002_human_message_serde()`.

### AC-010 (traces to BC-2.01.002 postcondition 4)
An unrecognized message role `{"type":"robot","content":"beep"}` returns `Err(PregolyaError { code: "E-CORE-002", message: "Message role 'robot' is not a recognized message type", .. })`. Verified by `test_BC_2_01_002_unknown_role_error()`.

### AC-011 (traces to BC-2.01.002 postcondition 5)
`ToolMessage { tool_call_id: "".to_string(), content: MessageContent::Text("result".to_string()) }` fails with `Err(PregolyaError { code: "E-CORE-005", category: VAL, message: "Validation failed for 'tool_call_id': must not be empty", .. })`. Verified by `test_BC_2_01_002_tool_message_requires_call_id()`.

### AC-012 (traces to BC-2.01.002 invariant)
`Message` has `#[non_exhaustive]`. `AiMessage`, `HumanMessage`, `SystemMessage`, `ToolMessage` all have `#[non_exhaustive]`. Verified by compile-fail tests (external match).

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `ContentBlock`, `MessageContent` | `pregolya-core/src/message/content.rs` | pure-core |
| `Message`, `AiMessage`, `HumanMessage`, `SystemMessage`, `ToolMessage` | `pregolya-core/src/message/types.rs` | pure-core |
| Legacy types | `pregolya-core/src/message/legacy.rs` | pure-core |
| Module root | `pregolya-core/src/message/mod.rs` | re-export-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/message/content.rs` | pure-core | Data types only; serde deserialization is pure computation over bytes. No I/O, no async. |
| `pregolya-core/src/message/types.rs` | pure-core | Enum and struct definitions; construction is fallible (`Result`); no I/O. |
| `pregolya-core/src/message/legacy.rs` | pure-core | Same as types.rs. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | ContentBlock with `type: null` | NonStandard or E-CORE-001 (strict mode) |
| EC-002 | `ToolMessage` with empty `tool_call_id` | Err(E-CORE-005 VAL "Validation failed for 'tool_call_id': must not be empty") |
| EC-003 | `HumanMessage` with `Blocks([])` | Allowed — empty block list is valid (no content restriction at type level) |
| EC-004 | Message type field missing from JSON | Serde returns deserialization error mapped to E-CORE-002 |
| EC-005 | `NonStandard` block round-trips through JSON unchanged | `serde_json::to_value(serde_json::from_str::<ContentBlock>(json)?) == original_value` |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,200 |
| BC-2.01.001.md (~200 lines) | ~3,000 |
| BC-2.01.002.md (~180 lines) | ~2,700 |
| `module-decomposition.md` (SS-01 section) | ~500 |
| `message/content.rs` + `types.rs` + `legacy.rs` (~100 lines each) | ~4,500 |
| Test files (~100 lines) | ~1,500 |
| Tool outputs | ~500 |
| **Total** | **~15,900** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~8%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-012 (test-writer)
2. [ ] Verify Red Gate
3. [ ] Create `pregolya-core/src/message/mod.rs` — re-exports only
4. [ ] Create `pregolya-core/src/message/content.rs` — `ContentBlock`, `MessageContent` enums with serde
5. [ ] Create `pregolya-core/src/message/types.rs` — `Message`, `AiMessage`, `HumanMessage`, `SystemMessage`, `ToolMessage`
6. [ ] Create `pregolya-core/src/message/legacy.rs` — `FunctionMessage`, `RemoveMessage`, `ChatMessage`
7. [ ] Add `pub mod message;` to `pregolya-core/src/lib.rs`
8. [ ] Implement `NonStandard` fallback deserialization using serde `#[serde(untagged)]` or custom deserializer
9. [ ] Implement `E-CORE-001` strict mode validation path
10. [ ] Implement `E-CORE-002` for unrecognized role during `Message` deserialization
11. [ ] Add `#[non_exhaustive]` and compile-fail tests for all public API types
12. [ ] Run `cargo nextest run -p pregolya-core` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-1.01 established `PregolyaError` with `Category::VAL`, `code: "E-CORE-001"`, `code: "E-CORE-002"`. S-1.03 uses `E-CORE-001` and `E-CORE-002` directly. Ensure these codes are in the error taxonomy before implementing.

S-1.01 also established: `source: Option<Arc<dyn Error + Send + Sync>>` field. Serde deserialization errors should be wrapped using this pattern when constructing E-CORE-002.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `message/mod.rs` is re-export-only | CLAUDE.md Code Conventions | Code review; `mod.rs` must contain only `pub use` statements |
| `#[non_exhaustive]` on all public message types | CLAUDE.md Code Conventions | Compile-fail tests |
| No tokio dependency in message module | Architecture boundary | `cargo tree -p pregolya-core` |
| `tool_call_id: String` (not `Option<String>`) | BC-2.01.002 postcondition 1 | Compile-time struct field access; unit test |

**Forbidden dependencies for `pregolya-core/src/message/`:** `tokio`, `reqwest`, `axum`. Only `std`, `serde`, `serde_json`.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `serde` | workspace pin | `#[derive(Serialize, Deserialize)]` on all message types |
| `serde_json` | workspace pin | `Value` for NonStandard blocks and ServerTool content |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/message/mod.rs` | CREATE | Re-export-only module root |
| `pregolya-core/src/message/content.rs` | CREATE | `ContentBlock`, `MessageContent` |
| `pregolya-core/src/message/types.rs` | CREATE | `Message`, `AiMessage`, `HumanMessage`, `SystemMessage`, `ToolMessage` |
| `pregolya-core/src/message/legacy.rs` | CREATE | `FunctionMessage`, `RemoveMessage`, `ChatMessage` |
| `pregolya-core/src/lib.rs` | MODIFY | Add `pub mod message;` |
