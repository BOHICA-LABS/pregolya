---
document_type: behavioral-contract
level: L3
bc_id: BC-2.18.003
version: "1.9"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-18
capability: CAP-023
crate: pregolya-prompts
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-24T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-18 Prompt Templates"
  - "1.1 (burst-227/F-P132-03/2026-07-21): PC2 MessagesPlaceholder trust derivation: replace broken 'ProvenanceTag (if any); each expanded message inherits the same tag' with explicit ADR-015-conformant trust derivation — each expanded message's MessageProvenance.highest_trust_level is derived from the Vec<Message> variable's declared trust_level: Option<TrustLevel>; None if unset."
  - "1.2 (F-P149-02/burst-250/2026-07-24): PC2 version pin de-pinned: 'per ADR-015 v1.3 semantics' → 'per ADR-015 Decision 3 §MessagesPlaceholder trust derivation' (TD-VSDD-091 stable-anchor enforcement, F-P149-02). input-hash updated to d2cc4f4 (drift from burst-227 ADR-015 content changes)."
  - "1.3 (fix-burst-279/F-P175-B202/ADR-015-D3-Amendment/2026-07-28): FewShotPromptTemplate example type change and pre-guard note. PC2: FewShot examples promoted from Vec<(String, String)> to Vec<(TemplateVar, TemplateVar)> — each component carries optional trust_level so the outer injection_guard in format_messages can check trust levels before calling example_template.format() (prior Vec<(String, String)> had no trust classification; this closes the FewShot injection path per ADR-015 Decision 3 Amendment). PC5: added pre-guard note — before rendering each pair, format_messages injection_guard checks trust level of both example_input and example_output TemplateVar components against SlotTrustPolicy; if either carries TrustLevel::Untrusted in a TrustRequired slot, format_messages returns Err(E-TMPL-001) before any example_template.format() call (fail-closed per ADR-015 Decision 3 Amendment, B202 CRIT)."
  - "1.4 (BURST-315/F-A3/2026-08-17): Promote status from `draft` to `active` — incomplete POL-14 promotion; `lifecycle_status: active` was already correct; `status: draft` was residual from pre-merge state."
  - "1.5 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-2.04 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.6 (P2A-040-F-01-F-02/2026-08-22): TWO changes closing F-01/F-02 (HIGH) from adversary pass P2A-040. (1) PC-1: replace stale 'call-time vars map supplies a Vec<Message>' with 'call-time vars map supplies a TemplateInput::Messages(MessageListVar)' — the bare Vec<Message> phrasing predated the TemplateInput enum concretization (ADR-015 Decision 3 Amendment, burst-279) and caused S-2.04 AC-015 to claim MessageListVar is a bare newtype over Vec<Message>, which is wrong and makes the Messages-arm Red Gate (S-2.05 AC-016) structurally unimplementable. (2) INV-4 (new): canonical MessageListVar struct shape defined with both messages: Vec<Message> and trust_level: Option<TrustLevel> fields — NOT a bare newtype; trust_level is the load-bearing field that enables injection_guard (BC-2.18.004 Pre-2/PC-5) to check msg_var.trust_level.is_some_and(|t| t.is_untrusted()) against TrustRequired slots. BC census UNCHANGED: 133 (51 P0 / 79 P1 / 3 P2). input-hash drift corrected (09c85f7). Story-writer must amend STORY-S-2.04 AC-015 to reference BC-2.18.003 INV-4 (not INV-1) and correct the MessageListVar shape claim."
  - "1.7 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.8 (P2A-044-F-06/2026-08-24): P2A-044 F-06: compressed-ordinal citations normalized to stable tags."
  - "1.9 (B-SS15-18-hardening/2026-08-26): Phase-2 bc-completeness-scan (D-270, burst B). {PC-009} added: FewShotPromptTemplate output provenance — when the trust check in PC-005 passes, the generated HumanMessage and AiMessage carry MessageProvenance.highest_trust_level derived from the respective TemplateVar's trust_level; None treated as Trusted by downstream injection_guard (BC-2.18.004)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-023
  - architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "09c85f7"
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

1. {PRE-001} For `MessagesPlaceholder`: a `ChatPromptTemplate` contains a placeholder slot declared with
   a variable name; the call-time `vars` map supplies a `TemplateInput::Messages(MessageListVar)`
   binding for that variable name (see INV-004 for the canonical `MessageListVar` struct shape).
   `MessageListVar` carries both the message list and its trust classification — it is NOT a
   bare newtype over `Vec<Message>`.
2. {PRE-002} For `FewShotPromptTemplate`: a `Vec` of `(example_input: TemplateVar, example_output: TemplateVar)`
   pairs is provided at construction; a `PromptTemplate` is provided to format each example pair.
   Each `TemplateVar` carries an optional `trust_level: Option<TrustLevel>`.
   This allows the outer `injection_guard` in `ChatPromptTemplate::format_messages` to
   check example component trust levels before calling the inner `example_template.format()`.
   (Prior form `Vec<(String, String)>` had no trust classification — this type change
   closes the FewShot injection path per ADR-015 Decision 3 Amendment.)
3. {PRE-003} Both types are constructed via fallible constructors returning `Result<Self, PregolyaError>`
   per DI-008.

## Postconditions

### MessagesPlaceholder

1. {PC-001} When `format_messages` is called, the `Vec<Message>` variable is expanded in-place at
   the placeholder position — each message in the Vec becomes a separate entry in
   `PromptValue.messages`.
2. {PC-002} The expanded messages carry `MessageProvenance` derived from the `Vec<Message>` variable's
   declared `trust_level: Option<TrustLevel>` (per ADR-015 Decision 3 §MessagesPlaceholder trust derivation): a
   `Vec<Message>` conversation-history variable is externally-supplied content; each expanded
   message's `MessageProvenance.highest_trust_level` is set to the variable's declared
   `trust_level` value. If the variable has no declared `trust_level` (i.e., `trust_level:
   None`), every expanded message's `highest_trust_level` is `None` (treated as Trusted by
   injection_guard).
3. {PC-003} If the `Vec<Message>` variable is absent from the call-time vars map, the behavior follows
   the slot's `required: bool` setting: if required (default), returns `Err(E-TMPL-003)`; if
   optional, expands to zero messages.
4. {PC-004} A `MessagesPlaceholder` with an empty `Vec<Message>` variable expands to zero messages (no
   error); the final `PromptValue.messages` simply has no entries at that position.

### FewShotPromptTemplate

5. {PC-005} Before rendering each pair via `example_template: PromptTemplate`, the outer
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
6. {PC-006} The full `PromptValue.messages` ordering is: prefix messages → few-shot Human/AI pairs →
   suffix messages (e.g., the final user turn).
7. {PC-007} If the example list is empty, the template renders with no few-shot pairs (zero messages
   at the few-shot position) — not an error.
8. {PC-008} Example rendering errors (e.g., missing variable in the example template) propagate as
   `Err(PregolyaError)` — they do not silently skip the failing example.
9. {PC-009} **FewShot output provenance:** When the trust check in {PC-005} passes (no Untrusted
   component triggers E-TMPL-001), the messages produced from each rendered pair carry
   `MessageProvenance` as follows:
   - The `HumanMessage(rendered_input)` carries
     `MessageProvenance.highest_trust_level = example_input.trust_level`.
   - The `AiMessage(rendered_output)` carries
     `MessageProvenance.highest_trust_level = example_output.trust_level`.
   If either `TemplateVar` has `trust_level: None`, the corresponding message's
   `highest_trust_level` is `None` — treated as Trusted by the downstream
   `injection_guard` (BC-2.18.004 {PRE-002} / {PC-005}). This mirrors the provenance
   derivation for `MessagesPlaceholder` variables in {PC-002}.
   (Stable anchor: {PC-009}. ADR-015 Decision 3 §MessagesPlaceholder trust derivation,
   extended to FewShot pair messages.)

## Invariants

1. {INV-001} `MessagesPlaceholder` expansion is positional — the expanded messages appear exactly at the
   declared placeholder position within the final `PromptValue.messages` sequence.
2. {INV-002} `FewShotPromptTemplate` example order matches the input Vec order; examples are not
   reordered.
3. {INV-003} Both types are pure-core (no I/O, no async) — `format_messages` is synchronous.
4. {INV-004} `MessageListVar` is the concrete input type for `MessagesPlaceholder` slots — the
   `Messages` arm of `TemplateInput`. Its canonical struct shape is:

   ```rust
   pub struct MessageListVar {
       pub messages: Vec<Message>,
       /// Trust classification applied uniformly to all messages in this expansion.
       /// `None` is treated as `Trusted` (developer-supplied history; no external origin).
       pub trust_level: Option<TrustLevel>,
   }
   ```

   `MessageListVar` is **NOT a bare newtype over `Vec<Message>`**. The
   `trust_level: Option<TrustLevel>` field is load-bearing: it is the mechanism by which
   the `injection_guard` (BC-2.18.004 PRE-002/PC-005) can check
   `msg_var.trust_level.is_some_and(|t| t.is_untrusted())` against `TrustRequired` slots.
   Without this field, the Messages-arm Red Gate (S-2.05 AC-016) is structurally
   unimplementable. `trust_level: None` is treated as `Trusted` by the guard — it does not
   trigger `E-TMPL-001`. (ADR-015 §MessagesPlaceholder trust derivation;
   F-P175-B202 MessageListVar guard in TrustRequired Slots.)

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
- `architecture/decisions/ADR-015-prompt-template-injection-safety.md` — Decision 1 (FewShot and MessagesPlaceholder listed as pregolya-prompts exports)
- `architecture/purity-boundary-map.md` — Pure Core classification

## Story Anchor

S-2.04

## VP Anchors

- VP-2.18.003-A, VP-2.18.003-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-023 |
| Capability Anchor Justification | CAP-023 ("MessagesPlaceholder and FewShotPromptTemplate — Message-List and Few-Shot Composition") per capabilities-p1-p2.md §CAP-023 — this BC specifies MessagesPlaceholder in-place expansion and FewShotPromptTemplate few-shot sequence composition, which CAP-023 identifies as the message-list and few-shot composition surface operating at message-list granularity distinct from scalar rendering |
| L2 Domain Invariants | DI-008 (construction returns Result; no unwrap in non-test code) |
| Architecture Authority | ADR-015 Decision 1 (pregolya-prompts exports: MessagesPlaceholder, FewShotPromptTemplate, PromptValue) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | pregolya-prompts / prompts::messages_placeholder, prompts::few_shot |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (pure-core, no I/O) |
