---
document_type: adr
level: L3
adr_id: "015"
slug: prompt-template-injection-safety
title: "Prompt Template Rendering and Injection Safety: Slot Trust Model, ProvenanceTag Integration, and Template Engine Selection"
status: accepted
date: "2026-07-20"
producer: architect
timestamp: 2026-07-20T00:00:00Z
version: "1.11"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D21]
supersedes: null
superseded_by: null
subsystems_affected: [SS-18, SS-11]
changelog:
  - "1.11 (fix-burst-279/gap-corrections/2026-07-28): Three gap corrections to v1.10. (1) Gap 1 (BLOCKING): FewShotPromptTemplate adjudication body added to §Decision 3 Amendment — FewShotPromptTemplate Example Trust Check: pre-expansion trust check over Vec<(TemplateVar,TemplateVar)> examples; FewShotExamples arm in TemplateInput injection guard code sketch; security argument (fail-closed, fires before inner example_template.format()); example trust level convention table. (2) Gap 1 (continued): §Decision 3 Amendment — TemplateInput Enum Concretized added before B201 section; TemplateInput enum definition with Scalar/Messages/FewShotExamples arms; #[non_exhaustive]; format_messages signature declared as HashMap<String, TemplateInput>. (3) Gap 1 (continued): §Decision 3 Amendment — B201 Type-Level Enforcement Assessment added: type-level wrapper feasibility assessed (feasible but API friction disproportionate); prohibition-as-invariant retained for v1; v2 trigger condition documented. v1.10 was missing all three bodies."
  - "1.10 (fix-burst-279/F-P175-B201+F-P175-B202+F-P175-B208+B202-fewshot/2026-07-28): Decision 3 Amendment — four injection-safety gaps closed. (1) B201: PromptTemplate::format explicitly declared unguarded; system-position output from the single-message surface is prohibited; callers MUST use ChatPromptTemplate::format_messages for any system-role content; type-level enforcement assessed and deferred — see §B201 type-level question. (2) B202 MessageListVar: injection check extended to cover MessageListVar.trust_level for MessagesPlaceholder slots in TrustRequired position. (3) B202 FewShot: FewShotPromptTemplate example inputs promoted from Vec<(String,String)> to Vec<(TemplateVar,TemplateVar)>; pre-expansion trust check added for TrustRequired outer slots; inner PromptTemplate::format never called when outer guard fires. (4) B208: TrustLevel severity inversion fixed — add severity() -> u8 (Untrusted=2, UserInput=1, Trusted=0); #[non_exhaustive] added; #[derive(Ord)] explicitly prohibited. format_messages signature corrected to HashMap<String, TemplateInput>; TemplateInput enum concretized. Sweeps: ADR-015 prose at §Iteration determinism invariant and §Security Invariant 1 updated; interface-definitions.md format_messages signature and TemplateInput enum added; VP-006 formal invariant updated."
  - "1.9 (FIX-BURST-278/Wave-C-S5/2026-07-28): S5 canon — two FerrochainError struct literals in Rust fences converted to FerrochainError::new(component, category, RetryHint::Never, code, message) canonical constructor form per D-42/D-49. (1) Decision 2 from_messages guard: E-TMPL-002 struct literal → FerrochainError::new(Component::Tmpl, Category::Val, RetryHint::Never, ...). (2) Decision 3 injection check: E-TMPL-001 struct literal → FerrochainError::new(Component::Tmpl, Category::Security, RetryHint::Never, ...). RetryHint::Never confirmed for both codes (SECURITY/InjectionAttempt and VAL/SystemSlotPolicy are non-retriable by construction per error-taxonomy)."
  - "1.8 (FIX-BURST-272/F-P170-18/2026-07-25): Rewrite §PO Handoffs and §BA Handoffs in past-tense RESOLVED form following the burst-238 stale-handoff sweep pattern. All listed changes were applied in burst-226 and subsequent bursts; the future-tense obligation tables were live open instructions in an accepted ADR, a Production-Grade Default violation. Rotted line-number pointers (L1110, L1128-1129, L1155-1156) replaced with section/symbol anchors per TD-VSDD-091."
  - "1.7 (FIX-BURST-270/P1D-168-casing/2026-07-25): PascalCase canon sweep — Decision 2 code sketch: Component::TMPL → Component::Tmpl; Category::VAL → Category::Val; Decision 4 InjectionAttempt code sketch: Component::TMPL → Component::Tmpl; Category::SECURITY → Category::Security per ADR-010 v1.9 Direction B adjudication."
  - "1.6 (FIX-BURST-269/F-P167-01/2026-07-25): Replace all non-canonical Category::VALIDATION residue with Category::VAL at four sites: (1) Decision 2 E-TMPL-002 code sketch (live code body); (2) Decision 4 strict-undefined note '(VALIDATION)' narrative label; (3) Consequences E-TMPL-002 '(VALIDATION/SystemSlotPolicy)' narrative label; (4) Consequences E-TMPL-003 '(VALIDATION/UndefinedVariable)' narrative label. VALIDATION is not a canonical Category variant; canonical abbreviated form per ADR-010 is VAL."
  - "1.5 (burst-249/2026-07-24): F-P148-02 — add Security Invariant 2 labeled subsection to Decision 2 and Security Invariant 1 labeled subsection to Decision 3. Adjudication option (b): stable anchors added to ADR rather than remapping 7+ citation sites across 4 documents. Resolves unresolvable 'ADR-015 Security Invariant N' citations in BC-2.18.004, BC-2.18.005, BC-INDEX Red Gate table, VP-006 changelog, prd.md, test-vectors.md."
  - "1.4 (burst-227/2026-07-21): F-P132-03 (coordinator flag 2) — Add 'MessagesPlaceholder trust derivation' subsection to Decision 3. ADR-015 v1.3 defined `TemplateVar` for scalar substitution but gave no counterpart type or derivation rule for `Vec<Message>` placeholder variables. BC-2.18.003 PC2 cited 'ADR-015 v1.3 semantics' but the rule was unanchored. Fix: introduce `MessageListVar { messages: Vec<Message>, trust_level: Option<TrustLevel> }` and state the uniform derivation rule: each expanded message's `MessageProvenance.highest_trust_level` = `MessageListVar.trust_level`; `None` → `None` (treated as Trusted). API shape (TemplateInput enum) deferred to story implementation."
  - "1.3 (burst-226/2026-07-21): F-P131-05 (CRITICAL) — ProvenanceTag shape adjudication. `ProvenanceTag` (SS-11 ingress-boundary struct) and template-composition trust level are TWO DISTINCT CONCERNS. Introduce `TrustLevel` enum (Untrusted|UserInput|Trusted) in `ferrochain-prompts: prompts::template` as the SS-18-local trust classifier. `TemplateVar.trust_level: Option<TrustLevel>` replaces the former implicit `Option<ProvenanceTag>` coupling. `MessageProvenance.highest_trust_level: Option<TrustLevel>` replaces `tag: Option<ProvenanceTag>`. Injection check updated: `var.trust_level.is_some_and(|t| t.is_untrusted())`. `ProvenanceTag` remains the SS-11 canonical 3-field struct (boundary_type/ingress_id/sequence_position) — no trust dimension added. BC-2.09.003 `ProvenanceTag::McpToolResult { server_name, tool_name }` is an outdated pre-PASS-58 variant; PO handoff: update PC1 to canonical struct form (`boundary_type: BoundaryType::ToolResult`). F-P131-04 (MED) — strict-undefined is a UNIVERSAL template-engine contract. Both f-string (default) and jinja2 (optional) engines raise E-TMPL-003 for undefined variables. E-TMPL-003 is engine-neutral. Decision 4 updated to state universal obligation."
  - "1.2 (burst-224/2026-07-21): F-P129-12 — specify template-source-order iteration for slot.variable_names() per BC-2.18.004 Invariant 5 + EC-007 + TV-005; determinism note added to Decision 3 injection-check prose and code sketch. HashSet/HashMap iteration prohibited for this loop."
  - "1.1 (crates.io/2026-07-20): Drop abandoned `mustache` crate (last release 2018-02, ~8yr stale — production-grade violation). Template engines: f-string (default) + jinja2/minijinja only. Pin: `minijinja = \"2\"` (2.21.0, default-features=false, optional). Add minijinja autoescape + sandboxed/restricted-mode + strict-undefined safety notes."
  - "1.0 (D21/2026-07-20): Initial ADR — ferrochain-prompts new crate, slot trust model (SystemMessage slots TrustRequired immutable), ProvenanceTag pass-through via PromptValue, f-string always-on + mustache/jinja2 optional features, injection_guard module as pure-core blocker before guardrail boundary."
---

# ADR-015: Prompt Template Rendering and Injection Safety

**Status:** Accepted — D21 ecosystem-parity scope expansion (SECURITY-CRITICAL)

## Context

D21 promotes prompt templates (PromptTemplate, ChatPromptTemplate, MessagesPlaceholder,
FewShot*) to full v1 scope. Templates substitute user-supplied variables into message
slots before sending to an LLM. This creates a novel security surface not present in
any existing ferrochain subsystem: **untrusted content substituted into a SystemMessage
template slot is a prompt injection vector**.

The existing security model (DI-012 / BC-2.11.001) fires guardrail hooks at ingress
boundaries (tool-result, RAG retrieval, memory reads). Template rendering is a
*composition step after ingress* — the variable values may already carry ProvenanceTags
from those ingress points, but no existing mechanism blocks them from landing in a
system-position message. This ADR defines that mechanism.

Four questions must be resolved:

1. **Crate placement:** new `ferrochain-prompts` or fold into ferrochain-core?
2. **Trust model:** how does ProvenanceTag interact with template slot rendering?
3. **Injection prevention:** what blocks untrusted content from reaching SystemMessage slots?
4. **Template engine selection:** which engines are supported, and which are safe to depend on?

## Decision 1 — Crate Placement: `ferrochain-prompts` (new crate)

Prompt templates are not placed in ferrochain-core because:
- Jinja2 rendering pulls in the `minijinja` crate (2.21.0). This is an optional capability
  that should not bloat every ferrochain-core user.
- The f-string engine is small (written in-house, ~100 LOC), but grouping both engines
  in a dedicated crate is cleaner than a feature-gated blob in ferrochain-core.
- Template logic is higher-level than the core type primitives; it depends on `core::message`,
  `core::runnable`, and `core::credentials` but adds nothing to the core trait contract.

`ferrochain-prompts` depends on ferrochain-core. It exports:
- `PromptTemplate` — single-message template (f-string default; jinja2 via optional feature)
- `ChatPromptTemplate` — multi-message template; produces `Vec<Message>`
- `MessagesPlaceholder` — inserts a `Vec<Message>` variable into a chat template
- `FewShotPromptTemplate` — few-shot example builder
- `PromptValue` — the rendered output type carrying per-message provenance

## Decision 2 — Template Slot Trust Model

Every `ChatPromptTemplate` message slot has a `SlotTrustPolicy`:

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SlotTrustPolicy {
    /// This slot accepts any input, including untrusted content.
    /// Appropriate for HumanMessage slots receiving user-supplied text.
    TrustAll,
    /// This slot requires trusted input only. Untrusted content triggers
    /// Err(FerrochainError { code: "E-TMPL-001", ... }).
    /// SystemMessage slots are ALWAYS TrustRequired — not configurable.
    TrustRequired,
}
```

**SystemMessage slot policy is hard-coded to `TrustRequired`** and cannot be overridden
by the caller. This is a compile-time architectural invariant enforced at template
construction time:

```rust
impl ChatPromptTemplate {
    pub fn from_messages(
        messages: Vec<(MessageRole, &str, SlotTrustPolicy)>,
    ) -> Result<Self, FerrochainError> {
        for (role, _, policy) in &messages {
            if *role == MessageRole::System && *policy != SlotTrustPolicy::TrustRequired {
                return Err(FerrochainError::new(
                    Component::Tmpl,
                    Category::Val,
                    RetryHint::Never,
                    "E-TMPL-002",
                    "SystemMessage slots must use TrustRequired policy; \
                              TrustAll is disallowed for system-position message slots",
                ));
            }
        }
        // ...
    }
}
```

`HumanMessage` and `AIMessage` slots default to `TrustAll` (appropriate: these positions
are intended to carry user-supplied or model-generated content). Callers may explicitly set
them to `TrustRequired` for additional hardening in pipelines that have tighter trust budgets.

### Security Invariant 2 — SystemMessage Slot Always TrustRequired at Construction Time (BC-2.18.005 Red Gate)

**The `TrustAll` policy on a SystemMessage slot is rejected at template construction time,
before any rendering occurs.** Calling `ChatPromptTemplate::from_messages` with a
`(MessageRole::System, _, SlotTrustPolicy::TrustAll)` tuple immediately returns
`Err(FerrochainError { code: "E-TMPL-002" })`. There is no bypass: no caller-supplied
override, no feature flag, no runtime configuration disables this check. Any
`ChatPromptTemplate` that successfully constructs has all SystemMessage slots in the
`TrustRequired` posture — rendering never executes without this guarantee.

This is the Red Gate anchor for **BC-2.18.005**: the `E-TMPL-002` rejection test must
compile and fail before `ChatPromptTemplate::from_messages` is implemented.

## Decision 3 — TrustLevel Classification and Injection Prevention

**F-P131-05 adjudication (burst-226):** `ProvenanceTag` (SS-11 ingress-boundary struct) and
template-composition trust serve two distinct axes and MUST NOT be conflated.

`ProvenanceTag` tracks WHICH ingress event produced content and WHERE within that event
(fields: `boundary_type`, `ingress_id`, `sequence_position`). These fields are meaningful
only at tool-result / RAG / memory ingress boundaries. Template variables are a composition
step — there is no ingress event and no sequence position. Forcing full ingress audit fields
onto a template variable would be semantically incorrect.

`TrustLevel` is introduced in `ferrochain-prompts: prompts::template` as the SS-18-local
trust classifier, **distinct from and independent of** `ProvenanceTag`.

### TrustLevel — template-variable trust classifier

```rust
// ferrochain-prompts: prompts::template
/// Trust classification for a template variable's value.
/// Distinct from `core::guardrail::ProvenanceTag` (SS-11 ingress-boundary audit struct).
/// Used ONLY within the SS-18 template composition layer.
///
/// SEVERITY ORDERING: Untrusted (highest) > UserInput > Trusted (lowest).
/// Use `severity()` for aggregate comparisons — NEVER `#[derive(Ord)]`.
/// Declaration order (Untrusted < UserInput < Trusted in derived Ord) is the INVERSE
/// of security severity. Deriving Ord and calling `.max()` would silently return
/// `Trusted` as the aggregate of any set containing `Untrusted` — a fail-open error.
#[non_exhaustive]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(kani, derive(kani::Arbitrary))]
pub enum TrustLevel {
    /// Content derived from an external/adversarial source (e.g., a RAG retrieval
    /// result or an MCP tool output). Substituting `Untrusted` content into a
    /// `TrustRequired` slot raises E-TMPL-001 (injection_guard fail-closed).
    Untrusted,
    /// Content from a user (trusted as a human operator but potentially naive or
    /// exploitable). Acceptable in `TrustRequired` slots when user trust is granted.
    UserInput,
    /// Developer-controlled content. Always acceptable in any slot.
    Trusted,
}

impl TrustLevel {
    /// Returns `true` only for `Untrusted` — the sole trigger for E-TMPL-001.
    pub fn is_untrusted(&self) -> bool {
        matches!(self, Self::Untrusted)
    }

    /// Numeric severity for aggregate computation.
    /// Untrusted = 2 (highest risk), UserInput = 1, Trusted = 0 (lowest risk).
    ///
    /// **INVARIANT:** When combining TrustLevels across multiple variables, use
    /// `.max_by_key(|t| t.severity())` — NEVER `Iterator::max()` or `Ord::max()`.
    /// Derived `Ord` on this enum is the INVERSE of severity order (Untrusted < Trusted
    /// in declaration order); calling `max()` on a mixed set returns `Trusted`,
    /// which is a silent fail-open injection bypass.
    ///
    /// BC anchor: BC-2.18.002 INV-2 (severity ordering used for highest_trust_level aggregation)
    pub fn severity(&self) -> u8 {
        match self {
            Self::Untrusted => 2,
            Self::UserInput => 1,
            Self::Trusted   => 0,
        }
    }
}
```

`TemplateVar` carries `Option<TrustLevel>`:

```rust
pub struct TemplateVar {
    pub value: String,
    /// Trust classification for this variable's value.
    /// `None` is treated as `Trusted` (developer-supplied literal; no external origin).
    pub trust_level: Option<TrustLevel>,
}
```

**Relationship to `ProvenanceTag`:** When a developer derives a template variable from a
RAG result (which arrived at the ingress boundary with a `ProvenanceTag { boundary_type:
BoundaryType::RAGRetrieval, ingress_id: ..., sequence_position: ... }`), they translate the
ingress provenance into a `TrustLevel` for the composition step:
`trust_level: Some(TrustLevel::Untrusted)`. The ingress `ProvenanceTag` record is already
captured in the guardrail audit log at ingress time and need not be threaded through template
composition.

### PromptValue carries TrustLevel

The rendered output type carries per-message trust inherited from substituted variables:

```rust
#[non_exhaustive]
pub struct PromptValue {
    pub messages: Vec<(Message, MessageProvenance)>,
}

#[non_exhaustive]
pub struct MessageProvenance {
    /// Highest-severity TrustLevel from any variable substituted into this message.
    /// `None` if no variables were substituted (template literal only) or all
    /// substituted variables carried `None` trust_level (developer-supplied values).
    pub highest_trust_level: Option<TrustLevel>,
    pub slot_trust_policy: SlotTrustPolicy,
}
```

When multiple variables are substituted into the same message, `highest_trust_level` is
the maximum-severity `TrustLevel` across all variables
(`Untrusted > UserInput > Trusted`). Only `Untrusted` triggers E-TMPL-001.

### Injection check (pure-core blocker)

The injection check fires **at render time** (inside `format_messages`), before the rendered
`PromptValue` reaches the graph or any guardrail:

```rust
impl ChatPromptTemplate {
    pub fn format_messages(
        &self,
        vars: HashMap<String, TemplateInput>,
    ) -> Result<PromptValue, FerrochainError> {
        for slot in &self.slots {
            if slot.policy == SlotTrustPolicy::TrustRequired {
                // slot.variable_names() returns names in TEMPLATE SOURCE ORDER
                // (left-to-right, first-occurrence position in the template string).
                // This guarantees deterministic error reporting: when multiple variables
                // carry untrusted provenance, E-TMPL-001 always names the FIRST one in
                // template source order. Slot variable storage MUST use Vec<String> or
                // another insertion-order structure — HashSet/HashMap iteration is
                // PROHIBITED here. (BC-2.18.004 Invariant 5 / EC-007 / TV-005)
                for var_name in slot.variable_names() {
                    match vars.get(var_name) {
                        Some(TemplateInput::Scalar(var)) => {
                            // Scalar TemplateVar — check trust_level directly.
                            if var.trust_level.is_some_and(|t| t.is_untrusted()) {
                                return Err(FerrochainError::new(
                                    Component::Tmpl,
                                    Category::Security,
                                    RetryHint::Never,
                                    "E-TMPL-001",
                                    format!(
                                        "InjectionAttempt: variable '{}' carries untrusted \
                                         provenance but slot '{}' requires TrustRequired policy",
                                        var_name, slot.message_role
                                    ),
                                ));
                            }
                        }
                        Some(TemplateInput::Messages(msg_var)) => {
                            // MessageListVar — check the declared trust_level for the
                            // entire expansion. This is the fix for F-P175-B202: prior
                            // code iterated only scalar variable_names() and never
                            // inspected MessageListVar.trust_level, leaving MessagesPlaceholder
                            // slots silently unguarded in TrustRequired position.
                            if msg_var.trust_level.is_some_and(|t| t.is_untrusted()) {
                                return Err(FerrochainError::new(
                                    Component::Tmpl,
                                    Category::Security,
                                    RetryHint::Never,
                                    "E-TMPL-001",
                                    format!(
                                        "InjectionAttempt: message list variable '{}' carries \
                                         untrusted provenance but slot '{}' requires TrustRequired \
                                         policy",
                                        var_name, slot.message_role
                                    ),
                                ));
                            }
                        }
                        None => {} // strict-undefined raises E-TMPL-003 at render time
                    }
                }
            }
        }
        // ... render ...
    }
}
```

**Iteration determinism invariant (BC-2.18.004 Invariant 5 / EC-007 / TV-005):**
`slot.variable_names()` MUST return variable names in **template source order** —
left-to-right, first-occurrence order as the variable placeholders appear in the
template string. Consequences:
- When multiple variables in a `TrustRequired` slot carry untrusted provenance, the
  `E-TMPL-001` error always names the **first** such variable in template source order.
  This is deterministic and testable (TV-005).
- Implementers MUST store slot variable names in a `Vec<String>` (or `IndexMap`), NOT a
  `HashSet<String>` or unordered structure. HashMap iteration order is undefined and
  produces non-deterministic errors under EC-007 (multiple-untrusted-vars scenario).
- The `vars: HashMap<String, TemplateInput>` parameter is used only for **O(1) lookup**
  (`vars.get(var_name)`); its iteration order is irrelevant to the check correctness.

This is a **hard block at the pure-core layer**, not a guardrail advisory. The error is
`E-TMPL-001` (SECURITY category) and propagates via `?` to the caller. The guardrail
boundary (DI-012) is a second layer for content entering the model context — it is not
a replacement for this render-time check.

### Security Invariant 1 — injection_guard Fail-Closed at Render Time (VP-006 Kani Candidate, BC-2.18.004 Red Gate)

**`TrustLevel::Untrusted` in a `TrustRequired` slot ALWAYS causes `format_messages` to return
`Err(E-TMPL-001)`.** No code path through the injection check produces `Ok(PromptValue)` when
this condition holds. The check is unconditional — no bypass path, no advisory mode, no
`GuardrailHook`-dependent override. No partial `PromptValue` is observable when the error
fires: rendering aborts at the first failing slot variable.

This is the Red Gate anchor for **BC-2.18.004**: the injection_guard test must compile and
fail before `ChatPromptTemplate::format_messages` is implemented. Kani VP-006 proves this
invariant formally: the `Ok` arm of `format_messages` is unreachable for any symbolic
`(ChatPromptTemplate, HashMap<String, TemplateInput>)` pair where any `TrustRequired` slot
receives a variable with `is_untrusted() == true`.

### Decision 3 Amendment — TemplateInput Enum Concretized (F-P175-B202 prerequisite)

The prior code sketch used `HashMap<String, TemplateVar>` as the `format_messages` parameter
type. This obscured the MessageListVar arm and prevented the injection guard from inspecting
it. The concrete unifying enum is established here (previously deferred to story implementation):

```rust
// ferrochain-prompts: prompts::template
/// Unified input type for `ChatPromptTemplate::format_messages`.
/// Replaces the former `HashMap<String, TemplateVar>` parameter type.
#[non_exhaustive]
pub enum TemplateInput {
    /// A scalar string substitution with optional trust classification.
    Scalar(TemplateVar),
    /// A message-list expansion for MessagesPlaceholder slots.
    Messages(MessageListVar),
    /// A few-shot example pair for FewShotPromptTemplate slots.
    /// Both components carry trust classification.
    /// Authority: ADR-015 Decision 3 Amendment — FewShotPromptTemplate trust check.
    FewShotExamples(Vec<(TemplateVar, TemplateVar)>),
}
```

**`format_messages` signature (corrected):**

```rust
pub fn format_messages(
    &self,
    vars: HashMap<String, TemplateInput>,
) -> Result<PromptValue, FerrochainError>
```

This is a **breaking change** from the prior sketch form `HashMap<String, TemplateVar>`.
All spec citations of `HashMap<String, TemplateVar>` as the `format_messages` parameter type
must be updated (see TD-VSDD-060 sweep in burst-279 sweep manifest for enumeration by owner).

### Decision 3 Amendment — FewShotPromptTemplate Example Trust Check (F-P175-B202)

**Finding:** `FewShotPromptTemplate` example rendering is a second unguarded path in B202.
BC-2.18.003 PC5 renders examples via `example_template: PromptTemplate` — the explicitly
unguarded surface per B201. BC-2.18.003 PC2 supplies examples as bare `Vec<(String, String)>`
with no trust level. An attacker supplying retrieved/user-supplied content as example
pairs routes it through the unguarded `PromptTemplate::format` into the expanded messages
with no injection check at any layer.

**Adjudication — pre-expansion trust check, example inputs typed as TemplateVar:**

`FewShotPromptTemplate` example inputs are promoted from bare `(String, String)` pairs to
`(TemplateVar, TemplateVar)` pairs. This makes the trust level of example content explicit
and checkable.

**Corrected FewShot injection guard logic:**

```rust
// In ChatPromptTemplate::format_messages injection guard loop:
// (FewShotExamples arm in TemplateInput)
Some(TemplateInput::FewShotExamples(examples)) => {
    if slot.policy == SlotTrustPolicy::TrustRequired {
        for (input_var, output_var) in examples {
            if input_var.trust_level.is_some_and(|t| t.is_untrusted()) {
                return Err(FerrochainError::new(
                    Component::Tmpl, Category::Security, RetryHint::Never,
                    "E-TMPL-001",
                    format!("InjectionAttempt: few-shot example input carries untrusted \
                             provenance in TrustRequired position (slot '{}')",
                             slot.message_role),
                ));
            }
            if output_var.trust_level.is_some_and(|t| t.is_untrusted()) {
                return Err(FerrochainError::new(
                    Component::Tmpl, Category::Security, RetryHint::Never,
                    "E-TMPL-001",
                    format!("InjectionAttempt: few-shot example output carries untrusted \
                             provenance in TrustRequired position (slot '{}')",
                             slot.message_role),
                ));
            }
        }
    }
}
```

**Security argument (fail-closed):** The pre-expansion check fires BEFORE the inner
`example_template.format()` call. If any example variable carries `TrustLevel::Untrusted`
in a TrustRequired outer slot, E-TMPL-001 fires and the inner `PromptTemplate::format` is
never invoked. The unguarded `PromptTemplate::format` surface (B201) is never reached for
content that fails the outer trust check.

**Example trust level convention:**
- Developer-authored examples (hard-coded in source code): `trust_level: None` (treated as Trusted)
- Examples loaded from a trusted dataset: `trust_level: Some(TrustLevel::Trusted)` or `None`
- Examples retrieved from a vector store or external source: `trust_level: Some(TrustLevel::Untrusted)`
- Examples from user input: `trust_level: Some(TrustLevel::UserInput)`

**BC-side update (PO-routed):** BC-2.18.003 PC2 must change from `Vec<(example_input:
String, example_output: String)>` to `Vec<(example_input: TemplateVar, example_output:
TemplateVar)>`. See routing spec burst-279 item 5.

### Decision 3 Amendment — B201 Type-Level Enforcement Assessment

**Question from orchestrator:** Is a type-level distinction feasible — e.g. `format`
returning a wrapper type that system-position APIs will not accept, so the invariant holds
by construction rather than convention?

**Assessment:**

The mechanism is feasible. The chain would be:
1. `PromptTemplate::format` returns `PlainString` (newtype over `String`) instead of `String`
2. `SystemMessage::new` changes from `fn new(text: String)` to `fn new(text: SystemTrustedContent)` where `SystemTrustedContent` is a separate type
3. `PlainString` cannot coerce into `SystemTrustedContent` — the type system prevents placement in system position

**Why deferred for v1:**

The API friction is disproportionate to the risk profile:
- Changing `SystemMessage::new(String)` to `SystemMessage::new(SystemTrustedContent)` breaks every caller that passes a string literal for system messages (the dominant use case for developer-authored prompts)
- Every developer-authored system message string would need explicit type conversion: `SystemTrustedContent::developer_literal("You are a helpful assistant.")` — adds ceremony to the common case to protect against the rare misuse case
- The actual risk pattern requires a developer to: (a) use `TemplateVar { value: retrieved_content, trust_level: Some(TrustLevel::Untrusted) }` with `PromptTemplate::format`, AND (b) manually place the `String` output into a system message — two independent developer errors at two separate call sites
- Post-v1 audits can detect violations mechanically via lint rules (grep for `SystemMessage::new(template.format(...)`)

**Decision:** Keep the prohibition-as-invariant for v1. If post-v1 audits detect violations of the prohibition in downstream crate code, introduce the type-level wrapper as a v2 hardening with a deprecation path for the `String`-accepting API. This reasoning is recorded here as the architectural rationale — it is NOT a defer-and-forget; it is a deliberate v1 decision with a concrete v2 trigger condition.

### Decision 3 Amendment — PromptTemplate::format Explicitly Unguarded (F-P175-B201)

`PromptTemplate::format` (the single-message surface) is **explicitly unguarded**. The
injection check defined above fires only inside `ChatPromptTemplate::format_messages`.
`PromptTemplate::format` returns a bare `String` with no `MessageProvenance` metadata —
there is no slot trust policy check, no `TrustLevel` inspection, and no `E-TMPL-001`
path within that method.

**Prohibition:** The output of `PromptTemplate::format` MUST NOT be placed directly into
a system-role position (SystemMessage) of any LLM call or ChatPromptTemplate without an
explicit re-check through `ChatPromptTemplate::format_messages` or an equivalent guard.

This prohibition is an architectural invariant, not a runtime check. It binds callers,
not implementors: `PromptTemplate` itself cannot enforce what position its output is used in.
The contract is declared here to ensure the BC layer reflects this gap correctly.

**BC correction (PO-routed):** Any BC that claims "injection_guard fires during the render
path that `PromptTemplate::format` exercises" is incorrect. The injection guard fires ONLY
in `ChatPromptTemplate::format_messages`. PO must remove or correct any such claim. See
routing spec burst-279.

### Decision 3 Amendment — MessageListVar Guard in TrustRequired Slots (F-P175-B202)

The injection check code sketch in earlier versions of this ADR iterated only
`slot.variable_names()` and inspected only `TemplateVar` (scalar) entries. `MessageListVar`
(the input type for `MessagesPlaceholder` slots) was never inspected — a `MessagesPlaceholder`
slot carrying `trust_level: Some(TrustLevel::Untrusted)` in a `TrustRequired` position
would have silently passed the guard.

The corrected injection check (updated in the code sketch above) handles both input arms:

| Input type | Guard action |
|------------|-------------|
| `TemplateInput::Scalar(TemplateVar)` | Check `var.trust_level.is_some_and(|t| t.is_untrusted())` |
| `TemplateInput::Messages(MessageListVar)` | Check `msg_var.trust_level.is_some_and(|t| t.is_untrusted())` |

The `MessageListVar` path was unguarded in prior code; this amendment closes the gap.
The `format_messages` signature now takes `HashMap<String, TemplateInput>` (the enum
unifying both input types); the `vars: HashMap<String, TemplateVar>` form in prior
versions was a sketch placeholder that obscured this gap.

### Decision 3 Amendment — TrustLevel Severity Inversion (F-P175-B208)

The `TrustLevel` enum has a latent severity-inversion hazard: Rust derives `Ord` in
declaration order, making `Untrusted < UserInput < Trusted`. Any implementor who adds
`#[derive(Ord)]` and calls `Iterator::max()` or `Ord::max()` on a set of `TrustLevel`
values will silently receive `Trusted` as the aggregate even if `Untrusted` is present —
a fail-open injection bypass.

**Three-part fix (applied in this amendment):**

1. `#[non_exhaustive]` added to `TrustLevel` — prevents exhaustive match arms in
   downstream code; callers must handle `_ =>` arm, making future variants safe to add
   without breaking existing match guards.

2. `severity() -> u8` method added (Untrusted=2, UserInput=1, Trusted=0) — provides the
   only safe path for aggregate severity computation.

3. Explicit prohibition: `#[derive(Ord)]` and `#[derive(PartialOrd)]` MUST NOT be added
   to `TrustLevel`. Every aggregate trust computation MUST use
   `.max_by_key(|t| t.severity())`, not `Iterator::max()` or `Ord::max()`.

**Canonical aggregate pattern:**

```rust
// CORRECT — uses severity() for ordering
let highest = vars.values()
    .filter_map(|v| match v {
        TemplateInput::Scalar(tv) => tv.trust_level,
        TemplateInput::Messages(mv) => mv.trust_level,
    })
    .max_by_key(|t| t.severity());

// WRONG — Ord declaration order is inverse of severity
// let highest = trust_levels.iter().copied().max();  // DO NOT USE
```

**VP-006 impact:** The Kani proof harness for VP-006 exercises
`TrustLevel::Untrusted` in a `TrustRequired` slot via `kani::Arbitrary`. The
`#[non_exhaustive]` + `#[cfg_attr(kani, derive(kani::Arbitrary))]` combination is
required for the harness to enumerate all variants. The `kani::Arbitrary` derive is
load-bearing — see VP-006.

### Relationship to existing DI-012 / BC-2.11.001 guardrail model

DI-012 fires at ingress boundaries (tool-result / RAG / memory). Template rendering is
a **post-ingress composition step**. The two mechanisms are complementary:

| Step | Mechanism | Fires when |
|------|-----------|------------|
| RAG result enters agent | DI-012 guardrail (BoundaryType::RAGRetrieval) | Content crosses ingress boundary |
| RAG result substituted into SystemMessage slot | E-TMPL-001 (pure-core blocker) | Variable with untrusted provenance + TrustRequired slot |
| Rendered PromptValue enters LLM call | DI-012 guardrail optionally re-applied | Caller may invoke guardrail on the PromptValue before sending |

**BoundaryType is NOT extended.** The template injection blocker is a pre-guardrail pure-core
error — it does not require a new BoundaryType variant.

`core::write_guard` (ADR-012) covers write-path safety; `prompts::injection_guard` covers
template-composition safety. Both are pure-core blockers with no async I/O.

### MessagesPlaceholder trust derivation (anchors BC-2.18.003 PC2)

`MessagesPlaceholder` expands a `Vec<Message>` call-site variable into individual messages.
Unlike scalar `TemplateVar` (which carries a `String` value), a placeholder variable wraps a
message list together with its declared trust classification:

```rust
pub struct MessageListVar {
    pub messages: Vec<Message>,
    /// Trust classification applied uniformly to all messages in this expansion.
    /// `None` is treated as `Trusted` (developer-supplied history; no external origin).
    pub trust_level: Option<TrustLevel>,
}
```

**Derivation rule:** Each expanded message's `MessageProvenance.highest_trust_level` is set
to the parent `MessageListVar.trust_level` — uniform across every message in the expansion.
When `trust_level` is `None`, every expanded message's `highest_trust_level` is `None`
(treated as Trusted by `injection_guard`). This anchors BC-2.18.003 PC2: "each expanded
message's `MessageProvenance.highest_trust_level` is derived from the `Vec<Message>`
variable's declared `trust_level: Option<TrustLevel>`."

`MessageListVar` is the call-site input type for `MessagesPlaceholder` slots; scalar slots
continue to use `TemplateVar`. Both are present in the call-time input map — the concrete
API shape (e.g., `enum TemplateInput { Scalar(TemplateVar), Messages(MessageListVar) }`) is
resolved during story implementation and does not constrain the decision here.

## Decision 4 — Template Engine Selection

Three template engines are supported via Cargo features in `ferrochain-prompts`:

| Engine | Cargo feature | Dependency | Status |
|--------|--------------|-----------|--------|
| f-string | always-on (no feature flag) | none (in-house implementation) | DEFAULT |
| jinja2 | `feature = "jinja2"` | `minijinja = "2"` (2.21.0, `default-features = false`) | optional |

**mustache crate dropped:** the `mustache` crate on crates.io has not had a release since
2018-02 (~8yr stale; predates Rust 2018 edition). Using it in v1 violates the
production-grade default. The mustache-syntax use case is fully covered by the jinja2 engine
— minijinja is a superset of mustache variable substitution. No `ramhorns` fallback needed.

**minijinja injection safety mechanisms (backing the trust model):** `minijinja` 2.21.0
provides three mechanisms directly relevant to the slot trust model:
- **Autoescape**: available and configurable per-template; ferrochain-prompts leaves it
  off by default for LLM prompts (not HTML) but exposes it for callers that render into
  web contexts.
- **Sandboxed mode**: restricts attribute access, method calls, and filter invocations
  to an explicit allowlist; ferrochain-prompts enables sandboxed mode for all jinja2
  template rendering, preventing template authors from calling arbitrary methods on
  substituted values.
- **Strict-undefined mode**: raises `E-TMPL-003` (VAL) on any undefined variable
  reference rather than silently substituting an empty string — prevents accidental
  information hiding during template development. This behavior is UNIVERSAL across both
  template engines (see "Universal strict-undefined contract" below).

These mechanisms are complementary to the `SlotTrustPolicy` injection check (Decision 3),
which fires at the variable-substitution level before engine rendering.

**Universal strict-undefined contract (F-P131-04 adjudication, burst-226):**
Undefined-variable detection is a **universal, engine-neutral obligation** — it applies to
BOTH template engines. A missing variable is an error regardless of which engine is active.

- **f-string engine (default, always-on):** Raises `E-TMPL-003` when a `{variable}` placeholder
  references a name absent from the `vars: HashMap<String, TemplateVar>`. This is the behavior
  mandated by BC-2.18.001 INV3 ("f-string DEFAULT engine raises E-TMPL-003 always-on").
- **jinja2 engine (optional, `feature = "jinja2"`):** Configures minijinja with
  `strict_undefined = true`, producing the same `E-TMPL-003` error for undefined references.

`E-TMPL-003` (VAL/UndefinedVariable) is **engine-neutral** — the error code, message prefix,
and semantics are identical regardless of which engine is active. Callers cannot assume
undefined variables are silently empty-substituted in either engine. This obligation binds
even when only the f-string feature is compiled in (the default build). The error-taxonomy
entry for E-TMPL-003 MUST describe it as engine-neutral (PO handoff).

The f-string engine is written in-house (~100 LOC) following Python's `str.format` semantics:
- `{variable}` is a substitution point
- `{{` and `}}` are escapes for literal braces
- Nested attribute access `{x.y}` is NOT supported in v1 (security simplification: no
  arbitrary object traversal in templates; if needed, callers pre-compute the value)

The jinja2 engine renders **the template string only** — the template itself is authored
by the developer and is trusted. Only VARIABLE VALUES are potentially untrusted.
The injection check (Decision 3) fires regardless of which template engine is used.

## Rationale

**Why a hard error rather than a guardrail advisory?** A guardrail advisory can be overridden
by a permissive `GuardrailHook` implementation. The injection vector — untrusted content in
a SystemMessage position — is a categorical security error, not a policy question. It must
be a hard error at the pure-core layer where it is provably prevented regardless of the
caller's guardrail configuration. This follows the production-grade default principle:
security-critical invariants are enforced by construction, not by convention.

**Why TrustRequired for SystemMessage slots only (not all slots)?** HumanMessage slots are
designed to carry user-supplied content — blocking `TrustLevel::UserInput` there would
prevent all user-input-driven prompt construction. The injection risk is specifically in the
System position, where an adversarially crafted string can override instructions, bypass
safety constraints, or hijack agent behavior. AIMessage slots are treated as TrustAll by
default because they are typically used for few-shot examples (developer-controlled).

**Why the f-string engine in-house?** No suitable crate precisely implements Python's
`str.format` semantics including the `{x}` / `{{` / `}}` escape rules without pulling
in Python-compat or shell-expansion concerns. 100 LOC in-house is lower risk than a
mismatched crate. Snapshot tests validate parity with the Python reference.

## Alternatives Considered

### Alt A: Prompt templates in ferrochain-core

Arguments for: no extra crate; templates are primitives.
Rejected: the minijinja crate would become a transitive dep of all ferrochain-core users
even when they don't use templates. Core stays lean; optional capabilities belong in
dedicated crates.

### Alt B: Inject the trust check into the existing GuardrailHook (DI-012 extension)

Arguments for: single mechanism for all content safety.
Rejected: GuardrailHooks are effectful (they can call external services) and are optional
per BC-2.11.001. Making prompt injection prevention depend on a user-configured optional
hook means the invariant is not enforced when no hook is configured. The pure-core check
is simpler, faster, and unconditional.

### Alt C: Extend BoundaryType with a TemplateRender variant

Arguments for: uniform provenance model across all content boundaries.
Rejected: Template rendering is not an ingress boundary — it is a composition step over
already-tagged content. Adding a BoundaryType variant would incorrectly imply that template
rendering is a place where content enters the system from an external source. The injection
check is a different concern (output-position validation, not input-tagging).

### Alt D: Allow TrustAll on SystemMessage slots with a deprecation warning

Rejected outright. "Warn but allow" is a deferred-security anti-pattern. If the invariant
matters (and prompt injection to system position matters), it must be enforced.

## Source / Origin

- **D21 (burst 216)**: ecosystem-parity scope expansion for prompt templates.
- **semport/core/rust-translation-strategy.md §4**: Prompt difficulty 🟡 moderate; f-string
  fidelity requirement; 3 template formats; `.partial()` builder; snapshot fixtures.
- **DI-008 (untrusted-content invariant)**: untrusted content must not enter model context
  without guardrail checks — the template injection blocker satisfies this for the
  system-slot vector.
- **DI-012 / BC-2.11.001**: existing guardrail model at ingress boundaries; this ADR adds
  a complementary pure-core check at template composition time.
- **ADR-012 Decision 1**: `MemoryWriteGuard::validate()` pure synchronous precedent — the
  `prompts::injection_guard` pure-core check follows the same pattern (synchronous, no I/O,
  returns error or allows).
- **R12** (prompt injection risk from D21 scope): the security surface introduced by
  template variable substitution is the primary risk this ADR addresses.

## Consequences

- `ferrochain-prompts` is the 19th published crate (D21 addition; `ferrochain-vectorstores`
  is the 20th).
- `prompts::injection_guard` is a Pure Core module — no async, no I/O, Kani-candidacy
  noted (VP-006: prove that `TrustLevel::Untrusted` in a `TrustRequired` slot always
  produces `Err(E-TMPL-001)` — harness uses `kani::Arbitrary` on `TrustLevel`).
- `PromptValue` carries `MessageProvenance` — callers that previously assumed raw `Vec<Message>`
  from a template must unwrap or use the helper `.into_messages()` method.
- `E-TMPL-001` (SECURITY/InjectionAttempt) and `E-TMPL-002` (VAL/SystemSlotPolicy)
  are new error codes; they belong in the error taxonomy (ferrochain-core `core::error`).
- ferrochain-prompts depends on ferrochain-core. No new deps on ferrochain-graph or
  ferrochain-memory — prompt templates are lower in the dependency graph than execution.
- The jinja2 engine has an external dep (`minijinja = "2"`, 2.21.0, `default-features = false`)
  and is opt-in via `feature = "jinja2"`. Default dependency tree: ferrochain-prompts →
  ferrochain-core only (no minijinja unless the `jinja2` feature is enabled).
- `E-TMPL-003` (VAL/UndefinedVariable) is engine-neutral — raised by BOTH the
  f-string (default) and jinja2 (optional) engines. The error-taxonomy description MUST NOT
  attribute it to minijinja only (PO handoff; see below).
- `TrustLevel` enum (`Untrusted | UserInput | Trusted`) is a new type in
  `ferrochain-prompts: prompts::template`. It is distinct from `core::guardrail::ProvenanceTag`
  (SS-11). SS-18 BC files and interface-definitions that reference `ProvenanceTag::Untrusted`,
  `::UserInput`, `::Trusted`, or `::Internal` for template trust purposes must be updated to
  use `TrustLevel::*` variants (PO handoff; variant `Internal` does not exist — remove it).
- `TemplateVar.trust_level: Option<TrustLevel>` replaces any earlier `provenance_tag:
  Option<ProvenanceTag>` field reference in SS-18 artifacts.
- `MessageProvenance.highest_trust_level: Option<TrustLevel>` replaces the former `tag:
  Option<ProvenanceTag>` field reference in SS-18 artifacts.

## PO Handoffs (burst-226 adjudications) — RESOLVED

### F-P131-05: ProvenanceTag shape adjudication — RESOLVED (burst-226)

All `ProvenanceTag`-for-trust replacements in the SS-18 BC layer and interface-definitions were applied in burst-226:

- **BC-2.18.004:** All `ProvenanceTag::Untrusted/::UserInput/::Trusted/::Internal` references replaced with `TrustLevel::Untrusted/::UserInput/::Trusted`; phantom `Internal` variant removed; PC5, EC-001–EC-007, TV-001–TV-005 updated.
- **BC-2.18.002 INV-2:** `ProvenanceTag` severity ordering replaced with `TrustLevel` severity ordering.
- **BC-2.09.003 PC1:** Outdated `ProvenanceTag::McpToolResult { server_name, tool_name }` (pre-PASS-58) replaced with canonical SS-11 struct form `ProvenanceTag { boundary_type: BoundaryType::ToolResult, ingress_id, sequence_position }`.
- **interface-definitions §Prompt Templates:** `TemplateVar.trust_level: Option<TrustLevel>` and `MessageProvenance.highest_trust_level: Option<TrustLevel>` are the canonical shapes. The `None → Trusted` rule for absent `trust_level` is documented. Crossed BC-assignment references in the §Prompt Templates section corrected: `ChatPromptTemplate` multi-message formatting traces to BC-2.18.002; strict-undefined / `E-TMPL-003` behavior traces to BC-2.18.001.
- **error-taxonomy §E-TMPL-001:** Raise-condition updated: `TrustLevel::Untrusted` is the trigger (not `ProvenanceTag::Untrusted`).

### F-P131-04: Universal strict-undefined contract — RESOLVED (burst-226)

- **error-taxonomy §E-TMPL-003:** Description is engine-neutral: "raised by both the f-string (default) and jinja2 engines when a template variable is referenced but absent from the input variable map." BC anchor: BC-2.18.001 (not BC-2.18.002).
- **interface-definitions §Prompt Templates:** Crossed BC-assignment for strict-undefined behavior corrected (see F-P131-05 above).

## BA Handoffs (burst-226 adjudications) — RESOLVED

### F-P131-04: Universal strict-undefined contract — RESOLVED (burst-226)

- **capabilities-p1-p2.md §CAP-022:** Updated to state that strict-undefined is a universal engine obligation (both f-string and jinja2 engines raise E-TMPL-003 on undefined variables).
