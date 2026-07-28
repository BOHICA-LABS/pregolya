---
document_type: behavioral-contract
level: L3
bc_id: BC-2.18.003
version: "1.3"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-18
capability: CAP-023
crate: ferrochain-prompts
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-07-20T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-18 Prompt Templates"
  - "1.1 (burst-227/F-P132-03/2026-07-21): PC2 MessagesPlaceholder trust derivation: replace broken 'ProvenanceTag (if any); each expanded message inherits the same tag' with explicit ADR-015-conformant trust derivation — each expanded message's MessageProvenance.highest_trust_level is derived from the Vec<Message> variable's declared trust_level: Option<TrustLevel>; None if unset."
  - "1.2 (F-P149-02/burst-250/2026-07-24): PC2 version pin de-pinned: 'per ADR-015 v1.3 semantics' → 'per ADR-015 Decision 3 §MessagesPlaceholder trust derivation' (TD-VSDD-091 stable-anchor enforcement, F-P149-02). input-hash updated to d2cc4f4 (drift from burst-227 ADR-015 content changes)."
  - "1.3 (fix-burst-279/F-P175-B202/ADR-015-D3-Amendment/2026-07-28): FewShotPromptTemplate example type change and pre-guard note. PC2: FewShot examples promoted from Vec<(String, String)> to Vec<(TemplateVar, TemplateVar)> — each component carries optional trust_level so the outer injection_guard in format_messages can check trust levels before calling example_template.format() (prior Vec<(String, String)> had no trust classification; this closes the FewShot injection path per ADR-015 Decision 3 Amendment). PC5: added pre-guard note — before rendering each pair, format_messages injection_guard checks trust level of both example_input and example_output TemplateVar components against SlotTrustPolicy; if either carries TrustLevel::Untrusted in a TrustRequired slot, format_messages returns Err(E-TMPL-001) before any example_template.format() call (fail-closed per ADR-015 Decision 3 Amendment, B202 CRIT)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-023
  - architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "352f3dd"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.18.003: MessagesPlaceholder Vec<Message> In-Place Expansion and FewShotPromptTemplate Few-Shot Composition

## Description

`MessagesPlaceholder` expands a named `Vec<Message>` variable in-place within a
`ChatPromptTemplate`, enabling dynamic injection of conversation history windows, streamed
tool-result sequences, or any pre-built message list. `FewShotPromptTemplate` composes a
sequence of few-shot `(input, output)` example pairs into a `ChatPromptTemplate` by formatting
each pair as a Human/AI message pair and inserting the entire sequence at a designated position.
Both produce a `PromptValue` carrying per-message `MessageProvenance` (via BC-2.18.002), making
their outputs composable with the injection_guard (BC-2.18.004) and guardrail pipelines.

## Preconditions

1. For `MessagesPlaceholder`: a `ChatPromptTemplate` contains a placeholder slot declared with
   a variable name; the call-time `vars` map supplies a `Vec<Message>` for that variable name.
2. For `FewShotPromptTemplate`: a `Vec` of `(example_input: TemplateVar, example_output: TemplateVar)`
   pairs is provided at construction; a `PromptTemplate` is provided to format each example pair.
   Each `TemplateVar` carries an optional `trust_level: Option<TrustLevel>`.
   This allows the outer `injection_guard` in `ChatPromptTemplate::format_messages` to
   check example component trust levels before calling the inner `example_template.format()`.
   (Prior form `Vec<(String, String)>` had no trust classification — this type change
   closes the FewShot injection path per ADR-015 Decision 3 Amendment.)
3. Both types are constructed via fallible constructors returning `Result<Self, FerrochainError>`
   per DI-008.

## Postconditions

### MessagesPlaceholder

1. When `format_messages` is called, the `Vec<Message>` variable is expanded in-place at
   the placeholder position — each message in the Vec becomes a separate entry in
   `PromptValue.messages`.
2. The expanded messages carry `MessageProvenance` derived from the `Vec<Message>` variable's
   declared `trust_level: Option<TrustLevel>` (per ADR-015 Decision 3 §MessagesPlaceholder trust derivation): a
   `Vec<Message>` conversation-history variable is externally-supplied content; each expanded
   message's `MessageProvenance.highest_trust_level` is set to the variable's declared
   `trust_level` value. If the variable has no declared `trust_level` (i.e., `trust_level:
   None`), every expanded message's `highest_trust_level` is `None` (treated as Trusted by
   injection_guard).
3. If the `Vec<Message>` variable is absent from the call-time vars map, the behavior follows
   the slot's `required: bool` setting: if required (default), returns `Err(E-TMPL-003)`; if
   optional, expands to zero messages.
4. A `MessagesPlaceholder` with an empty `Vec<Message>` variable expands to zero messages (no
   error); the final `PromptValue.messages` simply has no entries at that position.

### FewShotPromptTemplate

5. Before rendering each pair via `example_template: PromptTemplate`, the outer
   `ChatPromptTemplate::format_messages` injection_guard checks the trust level of BOTH
   the `example_input` and `example_output` `TemplateVar` components against the slot's
   `SlotTrustPolicy`. If either component carries `TrustLevel::Untrusted` in a
   `TrustRequired` slot, `format_messages` returns `Err(E-TMPL-001)` before any
   `example_template.format()` call is made. (Fail-closed, per ADR-015 Decision 3
   Amendment — FewShotPromptTemplate Example Trust Check, F-P175-B202.)
   When the trust check passes, each `(input, output)` pair is rendered via
   `example_template: PromptTemplate` and produces a
   `(HumanMessage(rendered_input), AiMessage(rendered_output))` pair inserted
   at the few-shot position.
6. The full `PromptValue.messages` ordering is: prefix messages → few-shot Human/AI pairs →
   suffix messages (e.g., the final user turn).
7. If the example list is empty, the template renders with no few-shot pairs (zero messages
   at the few-shot position) — not an error.
8. Example rendering errors (e.g., missing variable in the example template) propagate as
   `Err(FerrochainError)` — they do not silently skip the failing example.

## Invariants

1. `MessagesPlaceholder` expansion is positional — the expanded messages appear exactly at the
   declared placeholder position within the final `PromptValue.messages` sequence.
2. `FewShotPromptTemplate` example order matches the input Vec order; examples are not
   reordered.
3. Both types are pure-core (no I/O, no async) — `format_messages` is synchronous.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `MessagesPlaceholder` receives `Vec<Message>` with 0 elements | Expands to zero messages; no error; total `PromptValue.messages` has no entries at placeholder position |
| EC-002 | `MessagesPlaceholder` receives `Vec<Message>` with 50 elements | Expands to 50 entries; no size limit in v1; caller is responsible for context-window budget |
| EC-003 | `FewShotPromptTemplate` with 0 example pairs | Renders as prefix + suffix only; no few-shot section; `Ok(PromptValue)` |
| EC-004 | `FewShotPromptTemplate` example template has a variable missing from example data | `Err(E-TMPL-003)` from inner `PromptTemplate::format`; propagates up; does not skip the bad example |
| EC-005 | `MessagesPlaceholder` required variable absent from vars map | `Err(E-TMPL-003 UndefinedVariable)` — no silent zero-expansion when `required = true` |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `MessagesPlaceholder` at position 1 in a 3-slot template, `vars = {"history": [HumanMessage("hi"), AiMessage("hello")]}` | `PromptValue.messages` has: slot-0-msg, HumanMessage("hi"), AiMessage("hello"), slot-2-msg — 4 entries total | happy-path |
| TV-002 | `FewShotPromptTemplate` with examples `[("2+2?", "4"), ("3+3?", "6")]`, prefix `System("You do math.")`, suffix `Human("{question}")`, `vars = {"question": "5+5?"}` | `PromptValue.messages`: System("You do math."), Human("2+2?"), Ai("4"), Human("3+3?"), Ai("6"), Human("5+5?") | happy-path |
| TV-003 | `MessagesPlaceholder` with `Vec<Message>` of length 0 (`required = false`) | `PromptValue.messages` has no entries at placeholder position | edge-case (empty expansion) |
| TV-004 | `FewShotPromptTemplate` with empty example list | `PromptValue.messages`: prefix + suffix only | edge-case (zero examples) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.18.003-A | `MessagesPlaceholder` expansion length equals the input `Vec<Message>` length | unit test — vary Vec length, assert PromptValue.messages count |
| VP-2.18.003-B | `FewShotPromptTemplate` message count = prefix + (2 × example_count) + suffix | unit test — arithmetic assertion |

## Related BCs

- BC-2.18.001 — depends on: f-string rendering is used for individual example pairs in FewShotPromptTemplate
- BC-2.18.002 — composes with: produces PromptValue with MessageProvenance, same as ChatPromptTemplate
- BC-2.18.004 — depends on: injection_guard fires if Vec<Message> items carry untrusted provenance and land in TrustRequired slots

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-18, `prompts::messages_placeholder`, `prompts::few_shot`
- `architecture/decisions/ADR-015-prompt-template-injection-safety.md` — Decision 1 (FewShot and MessagesPlaceholder listed as ferrochain-prompts exports)
- `architecture/purity-boundary-map.md` — Pure Core classification

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-18 story]_

## VP Anchors

- VP-2.18.003-A, VP-2.18.003-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-023 |
| Capability Anchor Justification | CAP-023 ("MessagesPlaceholder and FewShotPromptTemplate — Message-List and Few-Shot Composition") per capabilities-p1-p2.md §CAP-023 — this BC specifies MessagesPlaceholder in-place expansion and FewShotPromptTemplate few-shot sequence composition, which CAP-023 identifies as the message-list and few-shot composition surface operating at message-list granularity distinct from scalar rendering |
| L2 Domain Invariants | DI-008 (construction returns Result; no unwrap in non-test code) |
| Architecture Authority | ADR-015 Decision 1 (ferrochain-prompts exports: MessagesPlaceholder, FewShotPromptTemplate, PromptValue) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | ferrochain-prompts / prompts::messages_placeholder, prompts::few_shot |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (pure-core, no I/O) |
