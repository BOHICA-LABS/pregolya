---
document_type: behavioral-contract
level: L3
bc_id: BC-2.18.002
version: "1.0"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-18
capability: CAP-022
crate: ferrochain-prompts
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-20T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-18 Prompt Templates"
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-022
  - architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "9eec8c9"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.18.002: ChatPromptTemplate Multi-Message Rendering with PromptValue and Per-Message MessageProvenance

## Description

`ChatPromptTemplate` renders a sequence of typed message slots into a `PromptValue`, which
carries `Vec<(Message, MessageProvenance)>`. Each slot is rendered independently; the resulting
`Message` is paired with a `MessageProvenance` recording the highest-severity `ProvenanceTag`
from all variables substituted into that slot, plus the slot's `SlotTrustPolicy`. Callers may
extract a plain `Vec<Message>` via `.into_messages()` when provenance data is not needed
downstream. All slot policies are validated at construction time; SystemMessage slots are
hard-coded to `TrustRequired` and cannot be changed (BC-2.18.005).

## Preconditions

1. A `ChatPromptTemplate` has been constructed via `ChatPromptTemplate::from_messages(messages)`
   returning `Result<Self, FerrochainError>` per DI-008 — construction validates all slot policies.
2. For rendering, a `HashMap<String, TemplateVar>` is provided where every `TemplateVar`
   optionally carries a `ProvenanceTag`.
3. All variables referenced in the template are present in the var map (else see BC-2.18.001
   EC-004 for E-TMPL-003), OR the caller has bound them via partial binding.

## Postconditions

1. `ChatPromptTemplate::format_messages(&self, vars: HashMap<String, TemplateVar>)
   → Result<PromptValue, FerrochainError>` returns `Ok(prompt_value)` on success.
2. `PromptValue.messages` is a `Vec<(Message, MessageProvenance)>` with one entry per slot,
   in the order slots were declared at construction.
3. For each slot: `MessageProvenance.tag` is `Some(tag)` where `tag` is the highest-severity
   `ProvenanceTag` across all variables substituted into that slot; `None` if no variable carried
   a tag (template-literal slots).
4. `MessageProvenance.slot_trust_policy` reflects the slot's policy as declared at construction.
5. `PromptValue.into_messages()` extracts `Vec<Message>` by discarding provenance metadata;
   the original `PromptValue` is consumed.
6. A `ChatPromptTemplate` with zero message slots constructs and renders successfully, returning
   a `PromptValue` with an empty `messages` Vec.

## Invariants

1. Slot order in the rendered `PromptValue` matches the order slots were declared at
   construction — no reordering occurs.
2. Tag severity ordering for provenance aggregation: `Untrusted > UserInput > Trusted`.
   When multiple variables with different tags are substituted into one slot, the
   highest-severity tag wins.
3. A slot that is a template literal (no variable substitutions) always has
   `MessageProvenance.tag = None`.
4. `ChatPromptTemplate` construction is pure (no I/O, no async); it returns `Result`.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | HumanMessage slot gets a var with ProvenanceTag::Untrusted | Renders successfully (TrustAll policy); `MessageProvenance.tag = Some(Untrusted)` |
| EC-002 | Slot has two variables — one `Trusted`, one `UserInput` | `MessageProvenance.tag = Some(UserInput)` (higher severity wins) |
| EC-003 | Template literal SystemMessage (no variable substitutions) | Renders normally; `MessageProvenance.tag = None`; `slot_trust_policy = TrustRequired` |
| EC-004 | ChatPromptTemplate with a single HumanMessage slot | Valid construction; renders a single-element `PromptValue.messages` |
| EC-005 | `into_messages()` called twice | Second call is a compile-time error (moves `PromptValue`); not a runtime concern |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `template = [System("You are helpful."), Human("{question}")]`, `vars = {"question": TemplateVar { value: "What is Rust?", tag: None }}` | `Ok(PromptValue { messages: [(SystemMessage("You are helpful."), Provenance { tag: None, policy: TrustRequired }), (HumanMessage("What is Rust?"), Provenance { tag: None, policy: TrustAll })] })` | happy-path |
| TV-002 | Same template, `vars = {"question": TemplateVar { value: "...", tag: Some(UserInput) }}` | HumanMessage slot: `Provenance { tag: Some(UserInput), policy: TrustAll }` | happy-path (provenance threading) |
| TV-003 | `template.format_messages({})` with all variables pre-bound as partials | `Ok(PromptValue { messages: [...] })` | happy-path (partial binding only) |
| TV-004 | `into_messages()` on TV-001 result | `Vec<Message>` with `[SystemMessage("You are helpful."), HumanMessage("What is Rust?")]` | happy-path (extraction) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.18.002-A | For each slot, `MessageProvenance.tag` is exactly the maximum-severity tag from all substituted variables | unit test — enumerate severity combinations |
| VP-2.18.002-B | Slot ordering in `PromptValue.messages` matches declaration order | unit test — verify index correspondence |

## Related BCs

- BC-2.18.001 — depends on: PromptTemplate rendering semantics (f-string engine) are the basis for each slot's string rendering
- BC-2.18.003 — composes with: MessagesPlaceholder and FewShot compose within a ChatPromptTemplate
- BC-2.18.004 — depends on: injection_guard check fires inside `format_messages` before returning PromptValue
- BC-2.18.005 — depends on: construction-time TrustAll prohibition guards the SystemMessage slot policy

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-18 module, `prompts::chat_template` + `prompts::prompt_value`
- `architecture/decisions/ADR-015-prompt-template-injection-safety.md` — Decision 3 (PromptValue, MessageProvenance, ProvenanceTag pass-through)
- `architecture/purity-boundary-map.md` — `ferrochain-prompts / prompts::chat_template` Pure Core

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-18 story]_

## VP Anchors

- VP-2.18.002-A, VP-2.18.002-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-022 |
| Capability Anchor Justification | CAP-022 ("PromptTemplate and ChatPromptTemplate as Runnable (f-string Default, Jinja2 Optional)") per capabilities-p1-p2.md §CAP-022 — this BC specifies the ChatPromptTemplate multi-message rendering contract and the PromptValue output type carrying per-message MessageProvenance, which CAP-022 identifies as the multi-message rendering surface of ferrochain-prompts |
| L2 Domain Invariants | DI-008 (ChatPromptTemplate construction returns Result; no unwrap/expect in non-test code) |
| Architecture Authority | ADR-015 Decision 3 (PromptValue structure, MessageProvenance, ProvenanceTag pass-through and severity ordering) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-prompts / prompts::chat_template, prompts::prompt_value |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (pure-core, no I/O) |
