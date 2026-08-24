---
document_type: behavioral-contract
level: L3
bc_id: BC-2.18.002
version: "2.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-18
capability: CAP-022
crate: pregolya-prompts
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-18 Prompt Templates"
  - "1.1 (burst-226/F-P131-05/2026-07-21): TrustLevel migration — INV-2 'ProvenanceTag severity ordering' → 'TrustLevel severity ordering'. PC3: MessageProvenance.tag → MessageProvenance.highest_trust_level; ProvenanceTag → TrustLevel in provenance aggregation context. EC-001, EC-002 updated: ProvenanceTag → TrustLevel; tag field → highest_trust_level. TV-001, TV-002: Provenance.tag → Provenance.highest_trust_level; ProvenanceTag variants → TrustLevel variants."
  - "1.2 (burst-227/F-P132-03/2026-07-21): Complete TrustLevel migration residue from v1.1 partial propagation. precondition 2: 'ProvenanceTag' → 'trust_level: Option<TrustLevel>'. EC-003: 'MessageProvenance.tag = None' → 'highest_trust_level = None'. TV-001: 'tag: None' → 'trust_level: None'. VP-2.18.002-A: 'MessageProvenance.tag' → 'MessageProvenance.highest_trust_level' and 'tag' → 'TrustLevel'."
  - "1.3 (fix-burst-279/F-P175-B202+B208+B221/ADR-015-D3-Amendment/2026-07-28): FOUR changes. (1) PC1 signature: format_messages parameter updated from HashMap<String, TemplateVar> to HashMap<String, TemplateInput> (TemplateInput enum concretized: Scalar/Messages/FewShotExamples arms; ADR-015 Decision 3 Amendment). (2) precondition 2: updated to HashMap<String, TemplateInput> with per-arm trust classification (B202 CRIT; breaking type change). (3) INV-2: updated to reference TrustLevel::severity() method for aggregate computation; Ord::max() and derived Ord on TrustLevel explicitly prohibited — declaration order is inverse of security severity (B208 HIGH fail-open fix; ADR-015 Decision 3 Amendment). (4) PC3 + INV-3: None case broadened from 'template-literal slots' to 'no variables substituted OR all substituted variables carried trust_level: None' — TV-001 showed non-literal slot yielding None when trust_level: None (B221 semantic correction; ADR-015 correct disjunction)."
  - "1.4 (burst-300/stale-ProvenanceTag-residue/2026-08-16): Two STALE ProvenanceTag→TrustLevel residues closed. (1) §Architecture Anchors ADR-015 bullet: 'Decision 3 (PromptValue, MessageProvenance, ProvenanceTag pass-through)' → 'Decision 3 (PromptValue, MessageProvenance, TrustLevel classification)' — ADR-015 Decision 3 heading was renamed TrustLevel Classification and Injection Prevention in v1.3 (burst-226); ProvenanceTag is the SS-11 ingress-boundary struct, not the SS-18 trust classifier. (2) §Traceability Architecture Authority row: 'ProvenanceTag pass-through and severity ordering' → 'TrustLevel classification and severity ordering' — same concept rename; severity ordering is TrustLevel::severity() domain per ADR-015 Decision 3 Amendment F-P175-B208."
  - "1.5 (BURST-315/F-A3/2026-08-17): Promote status from `draft` to `active` — incomplete POL-14 promotion; `lifecycle_status: active` was already correct; `status: draft` was residual from pre-merge state."
  - "1.6 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-2.04 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.7 (P2A-037-gaps/2026-08-22): Five changes closing P2A-037 class-audit spec gaps for STORY-S-2.04 AC-009/AC-010. (1) PC-7 (new): ChatPromptTemplate implements Runnable<Input=HashMap<String,TemplateInput>, Output=PromptValue>; invoke delegates to format_messages(); errors propagate unchanged. (2) INV-5 (new): PromptValue is a #[non_exhaustive] enum with variants String(String) and Messages(Vec<(Message, MessageProvenance)>); PromptValue: Send+Sync; non_exhaustive requires wildcard arm in external match. PC-5 into_messages() updated to cover both variants. (3) postcondition 2 rephrased: 'PromptValue.messages' struct-field notation replaced with 'PromptValue::Messages variant contains' (PC-2 was inconsistent with INV-5 enum declaration). (4) PC-5 updated to describe String-variant single-HumanMessage path. (5) TV-005 (new): Runnable invoke happy-path; TV count 4→5. H1 updated per bc_h1_is_title_source_of_truth; BC-INDEX updated."
  - "1.8 (P2A-039-F-039-04/2026-08-22): Remove stale ADR-015 amendment-pending parenthetical from INV-5 — ADR-015 §PromptValue now defines the enum shape and is aligned; no behavioral change."
  - "1.9 (P2A-040-F-02/2026-08-22): precondition-2 cross-reference added to BC-2.18.003 INV-4 for the MessageListVar struct shape — the Messages arm of TemplateInput carries trust_level: Option<TrustLevel> (NOT a bare newtype); BC-2.18.003 INV-4 is the authoritative clause for the struct shape. No behavioral change to ChatPromptTemplate rendering or PromptValue semantics; this is a traceability anchor addition that makes the Messages-arm Red Gate (S-2.05 AC-016) traceable to a canonical BC clause."
  - "2.0 (P2A-041-F-3/2026-08-23): disambiguated precondition-2 vs postcondition-2 changelog notation; no clause content change."
  - "2.1 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-022
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

# BC-2.18.002: ChatPromptTemplate Multi-Message Rendering, PromptValue Enum (String/Messages Variants, Send+Sync), and Runnable<HashMap<String,TemplateInput>,PromptValue>

## Description

`ChatPromptTemplate` renders a sequence of typed message slots into a `PromptValue`, which
carries `Vec<(Message, MessageProvenance)>`. Each slot is rendered independently; the resulting
`Message` is paired with a `MessageProvenance` recording the highest-severity `TrustLevel`
from all variables substituted into that slot, plus the slot's `SlotTrustPolicy`. Callers may
extract a plain `Vec<Message>` via `.into_messages()` when provenance data is not needed
downstream. All slot policies are validated at construction time; SystemMessage slots are
hard-coded to `TrustRequired` and cannot be changed (BC-2.18.005).

## Preconditions

1. {PRE-001} A `ChatPromptTemplate` has been constructed via `ChatPromptTemplate::from_messages(messages)`
   returning `Result<Self, PregolyaError>` per DI-008 — construction validates all slot policies.
2. {PRE-002} For rendering, a `HashMap<String, TemplateInput>` is provided. Each `TemplateInput`
   is one of:
   - `TemplateInput::Scalar(TemplateVar)` — scalar string binding for human/AI/system slots
   - `TemplateInput::Messages(MessageListVar)` — message-list expansion for MessagesPlaceholder
     (canonical `MessageListVar` struct shape: BC-2.18.003 INV-4 — carries both
     `messages: Vec<Message>` and `trust_level: Option<TrustLevel>`; NOT a bare newtype)
   - `TemplateInput::FewShotExamples(Vec<(TemplateVar, TemplateVar)>)` — for FewShot slots
   For each `TemplateInput` that binds to a `TrustRequired` slot, the trust level of the
   input's components is checked before rendering (injection_guard, BC-2.18.004).
   (Breaking change from prior `HashMap<String, TemplateVar>` per ADR-015 §Decision 3
   Amendment — TemplateInput Enum Concretized, burst-279.)
3. {PRE-003} All variables referenced in the template are present in the var map (else see BC-2.18.001
   EC-004 for E-TMPL-003), OR the caller has bound them via partial binding.

## Postconditions

1. {PC-001} `ChatPromptTemplate::format_messages(&self, vars: HashMap<String, TemplateInput>)
   → Result<PromptValue, PregolyaError>` returns `Ok(prompt_value)` on success.
2. {PC-002} The `PromptValue::Messages` variant contains a `Vec<(Message, MessageProvenance)>` with
   one entry per slot, in the order slots were declared at construction.
3. {PC-003} For each slot: `MessageProvenance.highest_trust_level` is `Some(trust_level)` where `trust_level` is the highest-severity
   `TrustLevel` across all variables substituted into that slot; `None` if no variables were
   substituted (template-literal slots) OR if all substituted variables carried
   `trust_level: None` (ADR-015 §Decision 3 correct disjunction — a non-literal slot with all
   `None` trust levels yields `highest_trust_level: None`, matching the template-literal case;
   see TV-001 for canonical example: `trust_level: None` variable → `highest_trust_level: None`).
4. {PC-004} `MessageProvenance.slot_trust_policy` reflects the slot's policy as declared at construction.
5. {PC-005} `PromptValue::into_messages()` returns `Vec<Message>` consuming self. For the
   `PromptValue::Messages` variant, provenance metadata is discarded and the message sequence
   returned; for the `PromptValue::String` variant, a single `HumanMessage` wrapping the
   string is returned. (See INV-5 for the canonical PromptValue enum shape.)
6. {PC-006} A `ChatPromptTemplate` with zero message slots constructs and renders successfully, returning
   a `PromptValue::Messages` variant with an empty inner Vec.
7. {PC-007} `ChatPromptTemplate` implements `Runnable<Input = HashMap<String, TemplateInput>, Output = PromptValue>`.
   `invoke(&self, input: HashMap<String, TemplateInput>, config: Option<RunnableConfig>)`
   delegates to `self.format_messages(input)` and returns the result directly
   (`Result<PromptValue, PregolyaError>`); all errors from `format_messages` propagate unchanged.
   The `batch` default delegates to sequential `invoke` calls. (CAP-022 Runnable requirement;
   purity-boundary-map.md — prompts::chat_template (Pure Core).)

## Invariants

1. {INV-001} Slot order in the rendered `PromptValue` matches the order slots were declared at
   construction — no reordering occurs.
2. {INV-002} TrustLevel severity ordering: `Untrusted` (severity=2) > `UserInput` (severity=1) >
   `Trusted` (severity=0). The highest-severity TrustLevel wins. Aggregate computation MUST
   use `TrustLevel::severity()` comparisons (`.max_by_key(|t| t.severity())`); `Ord::max()`
   or derived `Ord` on `TrustLevel` MUST NOT be used — declaration order is the INVERSE of
   security severity (ADR-015 Decision 3 Amendment, F-P175-B208). A derived `Ord` on
   `TrustLevel { Untrusted, UserInput, Trusted }` makes `Untrusted < Trusted`, so `.max()`
   returns `Trusted` for a set containing `Untrusted` — silent fail-open on the injection guard.
3. {INV-003} A slot has `MessageProvenance.highest_trust_level = None` when either: (a) no variables
   are substituted (template-literal slot), or (b) all substituted variables carry
   `trust_level: None`. These two cases are semantically equivalent for provenance purposes —
   in both, no trust classification was propagated into the slot (ADR-015 §Decision 3).
4. {INV-004} `ChatPromptTemplate` construction is pure (no I/O, no async); it returns `Result`.
5. {INV-005} `PromptValue` is a `#[non_exhaustive]` enum with exactly two stable variants:
   `PromptValue::String(String)` — produced by `PromptTemplate::invoke` (BC-2.18.001 PC-7),
   wrapping the formatted string output of `PromptTemplate::format`; and
   `PromptValue::Messages(Vec<(Message, MessageProvenance)>)` — produced by
   `ChatPromptTemplate::format_messages`, carrying per-slot `MessageProvenance` (PC-3).
   `PromptValue: Send + Sync` — all variant payload types are `Send + Sync`.
   The `#[non_exhaustive]` annotation requires external `match` arms to include a `_ => {}`
   wildcard arm to remain forward-compatible. `into_messages()` (PC-5) converts both variants
   to `Vec<Message>`. (ADR-015 §PromptValue is aligned with this enum shape.)

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | HumanMessage slot gets a var with TrustLevel::Untrusted | Renders successfully (TrustAll policy); `MessageProvenance.highest_trust_level = Some(TrustLevel::Untrusted)` |
| EC-002 | Slot has two variables — one `TrustLevel::Trusted`, one `TrustLevel::UserInput` | `MessageProvenance.highest_trust_level = Some(TrustLevel::UserInput)` (higher severity wins) |
| EC-003 | Template literal SystemMessage (no variable substitutions) | Renders normally; `MessageProvenance.highest_trust_level = None`; `slot_trust_policy = TrustRequired` |
| EC-004 | ChatPromptTemplate with a single HumanMessage slot | Valid construction; renders a single-element `PromptValue.messages` |
| EC-005 | `into_messages()` called twice | Second call is a compile-time error (moves `PromptValue`); not a runtime concern |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `template = [System("You are helpful."), Human("{question}")]`, `vars = {"question": TemplateVar { value: "What is Rust?", trust_level: None }}` | `Ok(PromptValue { messages: [(SystemMessage("You are helpful."), Provenance { highest_trust_level: None, policy: TrustRequired }), (HumanMessage("What is Rust?"), Provenance { highest_trust_level: None, policy: TrustAll })] })` | happy-path |
| TV-002 | Same template, `vars = {"question": TemplateVar { value: "...", trust_level: Some(TrustLevel::UserInput) }}` | HumanMessage slot: `Provenance { highest_trust_level: Some(TrustLevel::UserInput), policy: TrustAll }` | happy-path (provenance threading) |
| TV-003 | `template.format_messages({})` with all variables pre-bound as partials | `Ok(PromptValue { messages: [...] })` | happy-path (partial binding only) |
| TV-004 | `into_messages()` on TV-001 result | `Vec<Message>` with `[SystemMessage("You are helpful."), HumanMessage("What is Rust?")]` | happy-path (extraction) |
| TV-005 | Same template and vars as TV-001 invoked via `Runnable::invoke(vars, None)` rather than `format_messages` directly | `Ok(PromptValue::Messages([...]))` — result is structurally identical to TV-001; invoke delegates to format_messages without modification | happy-path (Runnable delegation; PC-7) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.18.002-A | For each slot, `MessageProvenance.highest_trust_level` is exactly the maximum-severity `TrustLevel` from all substituted variables | unit test — enumerate severity combinations |
| VP-2.18.002-B | Slot ordering in `PromptValue.messages` matches declaration order | unit test — verify index correspondence |

## Related BCs

- BC-2.18.001 — depends on: PromptTemplate rendering semantics (f-string engine) are the basis for each slot's string rendering
- BC-2.18.003 — composes with: MessagesPlaceholder and FewShot compose within a ChatPromptTemplate
- BC-2.18.004 — depends on: injection_guard check fires inside `format_messages` before returning PromptValue
- BC-2.18.005 — depends on: construction-time TrustAll prohibition guards the SystemMessage slot policy

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-18 module, `prompts::chat_template` + `prompts::prompt_value`
- `architecture/decisions/ADR-015-prompt-template-injection-safety.md` — Decision 3 (PromptValue, MessageProvenance, TrustLevel classification)
- `architecture/purity-boundary-map.md` — `pregolya-prompts / prompts::chat_template` Pure Core

## Story Anchor

S-2.04

## VP Anchors

- VP-2.18.002-A, VP-2.18.002-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-022 |
| Capability Anchor Justification | CAP-022 ("PromptTemplate and ChatPromptTemplate as Runnable (f-string Default, Jinja2 Optional)") per capabilities-p1-p2.md §CAP-022 — this BC specifies the ChatPromptTemplate multi-message rendering contract and the PromptValue output type carrying per-message MessageProvenance, which CAP-022 identifies as the multi-message rendering surface of pregolya-prompts |
| L2 Domain Invariants | DI-008 (ChatPromptTemplate construction returns Result; no unwrap/expect in non-test code) |
| Architecture Authority | ADR-015 Decision 3 (PromptValue structure, MessageProvenance, TrustLevel classification and severity ordering) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | pregolya-prompts / prompts::chat_template, prompts::prompt_value |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (pure-core, no I/O) |
