---
document_type: story
level: ops
story_id: S-2.04
epic_id: E-18
version: "1.5"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-18/BC-2.18.001.md
  - .factory/specs/behavioral-contracts/ss-18/BC-2.18.002.md
  - .factory/specs/behavioral-contracts/ss-18/BC-2.18.003.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "c23ad27"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-1.04, S-1.02]
blocks: [S-2.05]
behavioral_contracts: [BC-2.18.001, BC-2.18.002, BC-2.18.003]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: pregolya-prompts
subsystems: [SS-18]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-2.04: PromptTemplate Core — f-String Engine, ChatPromptTemplate, and TemplateInput

## Narrative

- **As a** pregolya chain author composing LLM inputs
- **I want to** construct `PromptTemplate` and `ChatPromptTemplate` from template strings and message tuples, format them with variable bindings via the `TemplateInput` enum, and receive structured `PromptValue` outputs usable by downstream Runnables
- **So that** I have a type-safe, f-string prompt construction system that catches malformed templates at construction time and undefined variables at render time, with a `TemplateInput` sum type that accommodates scalar values, message lists, and few-shot examples in a single interface

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.18.001 | PromptTemplate — f-String Engine; from_template Fallible Constructor; format() Renders or Returns E-TMPL-003 / E-TMPL-004 | P1 |
| BC-2.18.002 | ChatPromptTemplate Multi-Message Rendering, PromptValue Enum (String/Messages Variants, Send+Sync), and Runnable<HashMap<String,TemplateInput>,PromptValue> | P1 |
| BC-2.18.003 | MessagesPlaceholder Vec<Message> In-Place Expansion and FewShotPromptTemplate Few-Shot Composition | P1 |

## Acceptance Criteria

### AC-001 (traces to BC-2.18.001 PRE-001)
`PromptTemplate::from_template(template: &str) -> Result<Self, PregolyaError>` succeeds for
well-formed f-string templates (e.g., `"Hello, {name}!"`). The returned template stores
the variable list extracted from `{...}` placeholders.
Verified by `test_BC_2_18_001_from_template_wellformed_ok()`.

### AC-002 (traces to BC-2.18.001 INV-001)
`PromptTemplate::from_template` with a malformed template (unmatched `{` or `}`, nested braces
`{{}}` is NOT malformed — it is an escaped literal brace) returns
`Err(PregolyaError::new(Component::Tmpl, Category::Val, RetryHint::Never, "E-TMPL-004", ...))`.
The error fires at construction time, not render time.
Verified by `test_BC_2_18_001_malformed_template_returns_e_tmpl_004()`.

### AC-003 (traces to BC-2.18.001 PC-001)
`PromptTemplate::format(&self, values: &HashMap<String, TemplateVar>) -> Result<String, PregolyaError>`
substitutes all `{var}` placeholders with the corresponding value from `values`.
`{{` and `}}` escape to literal `{` and `}` respectively (Python f-string escape convention; also
governed by BC-2.18.001 PC-005 for the brace-escape sub-behavior).
Verified by `test_BC_2_18_001_format_substitutes_vars_and_escapes()`.

### AC-004 (traces to BC-2.18.001 PC-004)
`PromptTemplate::format` with a missing variable returns
`Err(PregolyaError::new(Component::Tmpl, Category::Val, RetryHint::Never, "E-TMPL-003",
"UndefinedVariable: variable '<var_name>' is not defined in the template context"))`.
The error message contains the variable name (dynamic interpolation for E-TMPL-003).
Verified by `test_BC_2_18_001_missing_var_returns_e_tmpl_003()`.

### AC-005 (traces to BC-2.18.001 PC-007)
`PromptTemplate` implements `Runnable<Input=HashMap<String, TemplateVar>, Output=PromptValue>`.
`invoke(input, config)` calls `format` and wraps the result in `PromptValue::String`.
An empty variable map formats a template with no placeholders successfully.
Verified by `test_BC_2_18_001_prompt_template_is_runnable()`.

### AC-006 (traces to BC-2.18.001 INV-006)
`PromptTemplate` is a pure-core type — no I/O in `format` or `invoke`. No async calls,
no network calls, no file I/O. `PromptTemplate: Send + Sync`.
Verified by compile-time bound assertion `test_BC_2_18_001_prompt_template_send_sync()`.

### AC-007 (traces to BC-2.18.002 PRE-001)
`ChatPromptTemplate::from_messages(messages: Vec<(MessageRole, &str, SlotTrustPolicy)>) -> Result<Self, PregolyaError>`
parses each template string, associates it with the role and policy, and returns
`Ok(ChatPromptTemplate)` when all templates are well-formed and policies are valid.
Verified by `test_BC_2_18_002_from_messages_ok()`.

### AC-008 (traces to BC-2.18.002 PC-002)
`ChatPromptTemplate::format_messages(&self, values: HashMap<String, TemplateInput>) -> Result<PromptValue, PregolyaError>`
renders all message templates, resolves `TemplateInput::Scalar` for simple substitutions,
`TemplateInput::Messages` for inserting a pre-formed message list at a placeholder, and
`TemplateInput::FewShotExamples` for few-shot example interpolation.
Returns `PromptValue::Messages(Vec<(Message, MessageProvenance)>)`.
Verified by `test_BC_2_18_002_format_messages_all_input_types()`.

### AC-009 (traces to BC-2.18.002 PC-007)
`ChatPromptTemplate` implements `Runnable<Input=HashMap<String, TemplateInput>, Output=PromptValue>`.
`invoke(input, config)` delegates to `format_messages`.
Verified by `test_BC_2_18_002_chat_prompt_template_is_runnable()`.

### AC-010 (traces to BC-2.18.002 INV-005)
`PromptValue` is a `#[non_exhaustive]` enum with variants `PromptValue::String(String)` and
`PromptValue::Messages(Vec<(Message, MessageProvenance)>)`.
`PromptValue: Send + Sync`.
Verified by `test_BC_2_18_002_prompt_value_variants_and_send_sync()`.

### AC-011 (traces to BC-2.18.002 PRE-001)
`ChatPromptTemplate::from_messages` validates that ALL template strings are well-formed
before returning. A mix of one valid and one invalid template string returns `Err(E-TMPL-004)`.
Construction is atomic — no partial state.
Verified by `test_BC_2_18_002_from_messages_atomic_construction()`.

### AC-012 (traces to BC-2.18.002 INV-006 — TemplateInput enum: 3 arms, #[non_exhaustive])
`TemplateInput` is an enum with exactly three variants:
- `TemplateInput::Scalar(TemplateVar)` — a single scalar value for a `{var}` slot
- `TemplateInput::Messages(MessageListVar)` — a pre-formed list for a `{messages}` slot
- `TemplateInput::FewShotExamples(Vec<(TemplateVar, TemplateVar)>)` — question/answer pairs
`TemplateInput` is `#[non_exhaustive]`.
Verified by `test_BC_2_18_002_template_input_variants()`.

### AC-013 (traces to BC-2.18.002 PRE-002 — HashMap<String,TemplateInput> parameter type)
`ChatPromptTemplate::format_messages(&self, vars: HashMap<String, TemplateInput>) -> Result<PromptValue, PregolyaError>`
accepts `TemplateInput` arms per slot: `TemplateInput::Scalar` for scalar text slots,
`TemplateInput::Messages` for in-place message-list expansion, and
`TemplateInput::FewShotExamples` for few-shot composition. This replaces the prior
`HashMap<String, TemplateVar>` parameter (breaking type change per ADR-015 §Decision 3
Amendment, burst-279). A `ChatPromptTemplate` constructed with a `MessagesPlaceholder`
slot renders successfully when the binding supplies `TemplateInput::Messages(MessageListVar)`.
Verified by `test_BC_2_18_002_format_messages_accepts_template_input_arms()`.

### AC-014 (traces to BC-2.18.002 INV-007 — SlotTrustPolicy enum shape: variants TrustRequired/TrustAll, derives Copy+PartialEq+Debug; BC-2.18.002 PC-004 for provenance recording)
`SlotTrustPolicy` is an enum with variants `TrustRequired` and `TrustAll`.
`SlotTrustPolicy` is used in `ChatPromptTemplate::from_messages` to annotate each
message slot's trust requirement. `SlotTrustPolicy: Copy + PartialEq + Debug`.
`MessageProvenance.slot_trust_policy` records the slot's declared policy (traces to BC-2.18.002 PC-004).
Verified by `test_BC_2_18_002_slot_trust_policy_shape()`.

### AC-015 (traces to BC-2.18.003 INV-004 — canonical MessageListVar struct shape)
`TemplateVar` is a newtype over `String`. `MessageListVar` is a struct (NOT a bare newtype):

```rust
pub struct MessageListVar {
    pub messages: Vec<Message>,
    /// Trust classification applied uniformly to all messages in this expansion.
    /// `None` is treated as `Trusted` (developer-supplied history; no external origin).
    pub trust_level: Option<TrustLevel>,
}
```

The `trust_level` field is load-bearing: `injection_guard` uses it to check
`msg_var.trust_level.is_some_and(|t| t.is_untrusted())` against `TrustRequired` slots.
Without this field the Messages-arm Red Gate (S-2.05 AC-016) is structurally unimplementable.
`MessageListVar` is `#[non_exhaustive]`.
Verified by `test_BC_2_18_003_templatevar_and_messagelistvar_shapes()`.

### AC-016 (traces to BC-2.18.002 INV-001 — source-order slot evaluation)
`format_messages` iterates message slots in SOURCE ORDER — the order in which slots were
declared in `from_messages`. HashMap input order is irrelevant; slot evaluation order is
deterministic and declaration-order-based.
Verified by `test_BC_2_18_002_format_messages_source_order()`.

### AC-017 (traces to BC-2.18.003 PC-001 — VP-2.18.003-A)
`MessagesPlaceholder` expansion length equals the input `Vec<Message>` length: when a
`TemplateInput::Messages(MessageListVar)` binding supplies N messages, exactly N entries
appear at the placeholder position in `PromptValue.messages`.
Verified by `test_BC_2_18_003_messages_placeholder_expansion_length()`.

### AC-018 (traces to BC-2.18.003 PC-006 — VP-2.18.003-B)
`FewShotPromptTemplate` full message count equals prefix count + (2 × example count) + suffix
count. Each `(input, output)` example pair produces exactly one `HumanMessage` and one
`AiMessage`. Ordering is: prefix messages → few-shot Human/AI pairs → suffix messages
(BC-2.18.003 PC-006).
Verified by `test_BC_2_18_003_few_shot_message_count()`.

### AC-019 (traces to BC-2.18.003 INV-001 — MessagesPlaceholder positional expansion)
`MessagesPlaceholder` expanded messages appear at exactly the declared placeholder position
within the final `PromptValue.messages` sequence. Messages before the placeholder position are
unaffected; messages after the placeholder position follow the expanded messages.
Verified by `test_BC_2_18_003_messages_placeholder_positional_expansion()`.

### AC-020 (traces to BC-2.18.003 PC-003 — EC-005)
When a `MessagesPlaceholder` required variable is absent from the call-time vars map,
`format_messages` returns
`Err(PregolyaError::new(Component::Tmpl, Category::Val, RetryHint::Never, "E-TMPL-003", ...))`.
No silent zero-expansion occurs when `required = true` (default).
Verified by `test_BC_2_18_003_messages_placeholder_required_var_absent_err()`.

### AC-021 (traces to BC-2.18.003 PC-004 — EC-001)
A `MessagesPlaceholder` with an empty `Vec<Message>` (zero elements) expands to zero messages
without error. The final `PromptValue.messages` has no entries at that placeholder position.
Verified by `test_BC_2_18_003_messages_placeholder_empty_vec_ok()`.

### AC-022 (traces to BC-2.18.003 PC-008 — EC-004)
When a `FewShotPromptTemplate` example template renders with a missing variable, the error
propagates as `Err(PregolyaError)`. The failing example is NOT silently skipped;
`format_messages` returns the first render error encountered.
Verified by `test_BC_2_18_003_few_shot_example_render_error_propagates()`.

### AC-023 (traces to BC-2.18.003 PC-009)
`FewShotPromptTemplate` output provenance: each `HumanMessage` produced from a few-shot
example pair carries `MessageProvenance.trust_level = example_input.trust_level`, and
each `AiMessage` produced carries `MessageProvenance.trust_level = example_output.trust_level`.
When `example_input.trust_level` or `example_output.trust_level` is `None`, that message
is treated as `Trusted` by downstream consumers (absent classification; developer-supplied
content). This ensures that the trust provenance of few-shot examples flows through to the
assembled `PromptValue.Messages` — critical for injection-guard compatibility in S-2.05.
Verified by `test_BC_2_18_003_fewshot_output_provenance_trust_level()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `PromptTemplate` | `pregolya-prompts/src/prompt_template.rs` | pure-core |
| `ChatPromptTemplate` | `pregolya-prompts/src/chat_template.rs` | pure-core |
| `TemplateInput`, `TemplateVar`, `MessageListVar` | `pregolya-prompts/src/template_input.rs` | pure-core |
| `PromptValue` | `pregolya-prompts/src/prompt_value.rs` | pure-core |
| `SlotTrustPolicy` | `pregolya-prompts/src/policy.rs` | pure-core |
| Module root | `pregolya-prompts/src/lib.rs` | re-export-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| All `pregolya-prompts/src/*.rs` | pure-core | Template formatting is a pure string transformation. No I/O. |
| `Runnable::invoke` implementation | pure-core | Delegates only to `format` / `format_messages`, which are pure. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Template with no placeholders (`"Hello world"`) | `from_template` succeeds; `format({})` succeeds; returns `"Hello world"` |
| EC-002 | Template with only escaped braces (`"{{literal}}"`) | `from_template` succeeds; `format({})` returns `"{literal}"` |
| EC-003 | Same placeholder used twice (`"{name} is {name}"`) | Both occurrences substituted with the same value |
| EC-004 | Extra keys in the values map (more than the template uses) | Allowed — extra keys are ignored, no error |
| EC-005 | Empty `from_messages` vec | `Ok(ChatPromptTemplate)` with no slots — `format_messages({})` returns empty message list |
| EC-006 | `FewShotExamples` with zero example pairs | Renders zero examples — no error |
| EC-007 | `format_messages` with extra keys beyond declared slots | Allowed — extra keys are ignored |
| EC-008 | `PromptTemplate::format` where template has N vars and exactly N-1 are provided | `Err(E-TMPL-003)` for the first missing variable in template scan order |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~5,800 |
| BC files (3 BCs) | ~9,000 |
| `module-decomposition.md` (SS-18 section) | ~400 |
| ADR-015 prompt template injection safety | ~2,500 |
| Module files (~80 lines each × 5 files) | ~3,500 |
| Test files (~130 lines) | ~1,900 |
| Tool outputs | ~500 |
| **Total** | **~23,600** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~12%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-023 (test-writer)
2. [ ] Verify Red Gate (this story has no Red Gate BCs — proceed to implementation after test stubs)
3. [ ] Create `pregolya-prompts/Cargo.toml` — new crate; depends on pregolya-core, serde, serde_json
4. [ ] Create `pregolya-prompts/src/template_input.rs` — `TemplateInput` enum (`#[non_exhaustive]`), `TemplateVar` newtype, `MessageListVar` struct (`messages: Vec<Message>`, `trust_level: Option<TrustLevel>`; `#[non_exhaustive]`), `SlotTrustPolicy` enum
5. [ ] Create `pregolya-prompts/src/prompt_value.rs` — `PromptValue` enum (`#[non_exhaustive]`: String, Messages variants)
6. [ ] Create `pregolya-prompts/src/policy.rs` — `SlotTrustPolicy` (if not already in template_input.rs)
7. [ ] Create `pregolya-prompts/src/prompt_template.rs` — `PromptTemplate` (f-string parser, `from_template`, `format`, `Runnable` impl)
8. [ ] Create `pregolya-prompts/src/chat_template.rs` — `ChatPromptTemplate` (`from_messages`, `format_messages`, `Runnable` impl); source-order slot evaluation
9. [ ] Create `pregolya-prompts/src/lib.rs` — re-export-only crate root
10. [ ] Register `E-TMPL-003` and `E-TMPL-004` in error taxonomy (`Component::Tmpl, Category::Val, RetryHint::Never`)
11. [ ] Add `pregolya-prompts` to workspace `Cargo.toml` members list
12. [ ] Run `cargo nextest run -p pregolya-prompts` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-1.04 established `Runnable<Input, Output>` in `pregolya-core`. `PromptTemplate` and
`ChatPromptTemplate` implement `Runnable` here using the `async-trait` pattern from S-1.04.
The `RunnableConfig` type is from S-1.04 and must be accepted in `invoke`.

S-1.02 established error handling primitives, `PregolyaError`, and `Component`/`Category`/`RetryHint`
enums. This story adds new error codes `E-TMPL-003` and `E-TMPL-004` — register them in the
error taxonomy before implementation (taxonomy path: `.factory/specs/prd-supplements/error-taxonomy.md`
or the BC-level taxonomy appendix).

S-2.05 depends on this story for `ChatPromptTemplate::from_messages` being in place. The
`SlotTrustPolicy` enum introduced in AC-014 is used by S-2.05's injection guard. Define
`SlotTrustPolicy` in this story so S-2.05 can reference it without circular dependencies.
`TrustLevel` (the runtime trust tag on variable values) is SEPARATE from `SlotTrustPolicy`
(the construction-time slot policy) — do not conflate them. `TrustLevel` is defined in S-2.05.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `PromptTemplate` and `ChatPromptTemplate` are pure-core (no I/O) | BC-2.18.001 INV-006; ADR-015 purity map | `pregolya-prompts` must NOT have tokio as a direct dep (only needed if Runnable impls use async; use async-trait bridge) |
| `PromptValue` is `#[non_exhaustive]` | BC-2.18.002 INV-005 | Compile-fail test for external exhaustive match |
| `TemplateInput` is `#[non_exhaustive]` | BC-2.18.002 INV-006 | Compile-fail test |
| Source-order slot evaluation in `format_messages` | BC-2.18.002 INV-001 | Unit test AC-016 |
| `lib.rs` in `pregolya-prompts` is re-export-only — no logic | CLAUDE.md Code Conventions (mod.rs/lib.rs rule) | Code review |
| E-TMPL-003 message format: dynamic (contains var name) | BC-2.18.001 PC-004 | String contains check in test |
| E-TMPL-004 is construction-time | BC-2.18.001 INV-001 | Error arises from `from_template`, not `format` |

**Forbidden dependencies:** `pregolya-prompts` must NOT depend on `pregolya-vectorstores` or `pregolya-graph`. It may depend on `pregolya-core` for `Runnable`, `PregolyaError`, and `Message`.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `async-trait` | workspace pin | `#[async_trait]` for `Runnable` impl on PromptTemplate / ChatPromptTemplate |
| `serde` | workspace pin | Serialize/Deserialize on TemplateVar, PromptValue |
| `serde_json` | workspace pin | MessageListVar JSON round-trip; TemplateInput value serialization |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-prompts/Cargo.toml` | CREATE | New crate definition |
| `pregolya-prompts/src/lib.rs` | CREATE | Re-export-only crate root |
| `pregolya-prompts/src/template_input.rs` | CREATE | `TemplateInput`, `TemplateVar`, `MessageListVar`, `SlotTrustPolicy` |
| `pregolya-prompts/src/prompt_value.rs` | CREATE | `PromptValue` enum |
| `pregolya-prompts/src/prompt_template.rs` | CREATE | `PromptTemplate` + f-string parser |
| `pregolya-prompts/src/chat_template.rs` | CREATE | `ChatPromptTemplate` + `format_messages` |
| `Cargo.toml` (workspace root) | MODIFY | Add `pregolya-prompts` to `members` |

## Changelog

- "1.0 (2026-08-19): initial story authored"
- "1.1 (M3/ADR-027/2026-08-24): AC traces re-cited to stable clause anchors; 4 compliance-table semantic re-anchors applied (see escalation notes)"
- "1.2 (P2A-043/2026-08-24): P2A-043 F-02/F-03: SS-18 anchors resolved per PO; escalation notes cleared"
- "1.3 (P2A-046/2026-08-24): F-1 remove SS-18 BC 5 (SlotTrustPolicy fail-closed enforcement; reference-not-coverage in this story; full coverage anchored to S-2.05); F-2 inputs+Token-Budget corrected to 3 BCs; AC-014 re-anchored from removed BC PC-001 → BC-2.18.002 INV-007 (SlotTrustPolicy enum shape)."
- "1.4 (P2A-047/2026-08-24): F-047-01: verification_properties frontmatter cleared to [] — VP-2.18.003-A and VP-2.18.003-B are BC-local (BC-2.18.003) and are not registered in VP-INDEX; they remain documented in AC-017 and AC-018 body traces per STORY-INDEX §Conventions."
- "1.5 (SW-4/BC-completeness/2026-08-26): BC-2.18.003 propagation — AC-023 added for PC-009 FewShot output provenance (HumanMessage.trust_level = example_input.trust_level; AiMessage.trust_level = example_output.trust_level; None treated as Trusted downstream); input-hash updated c23ad27."

