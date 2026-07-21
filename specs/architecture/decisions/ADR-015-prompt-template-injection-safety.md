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
version: "1.2"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D21]
supersedes: null
superseded_by: null
subsystems_affected: [SS-18, SS-11]
changelog:
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
                return Err(FerrochainError {
                    component: Component::TMPL,
                    category: Category::VALIDATION,
                    code: "E-TMPL-002",
                    message: "SystemMessage slots must use TrustRequired policy; \
                              TrustAll is disallowed for system-position message slots",
                });
            }
        }
        // ...
    }
}
```

`HumanMessage` and `AIMessage` slots default to `TrustAll` (appropriate: these positions
are intended to carry user-supplied or model-generated content). Callers may explicitly set
them to `TrustRequired` for additional hardening in pipelines that have tighter trust budgets.

## Decision 3 — ProvenanceTag Pass-Through and Injection Prevention

### PromptValue carries provenance

The rendered output type carries per-message provenance inherited from substituted variables:

```rust
#[non_exhaustive]
pub struct PromptValue {
    pub messages: Vec<(Message, MessageProvenance)>,
}

#[non_exhaustive]
pub struct MessageProvenance {
    /// Highest-severity ProvenanceTag from any variable substituted into this message.
    /// None if no variables were substituted (template literal only).
    pub tag: Option<ProvenanceTag>,
    pub slot_trust_policy: SlotTrustPolicy,
}
```

`ProvenanceTag` is imported from ferrochain-core (BC-2.11.001 / SS-11). When a variable
carrying a `ProvenanceTag` is substituted into a message slot:
- The slot's `MessageProvenance.tag` is set to the variable's ProvenanceTag.
- If multiple variables are substituted into the same message, the tag is the highest-
  severity tag across all variables (tag severity ordering: `Untrusted > UserInput > Trusted`).

### Injection check (pure-core blocker)

The injection check fires **at render time** (inside `format_messages`), before the rendered
`PromptValue` reaches the graph or any guardrail:

```rust
impl ChatPromptTemplate {
    pub fn format_messages(
        &self,
        vars: HashMap<String, TemplateVar>,
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
                    if let Some(var) = vars.get(var_name) {
                        if var.provenance_tag.is_some_and(|t| t.is_untrusted()) {
                            return Err(FerrochainError {
                                component: Component::TMPL,
                                category: Category::SECURITY,
                                code: "E-TMPL-001",
                                message: format!(
                                    "InjectionAttempt: variable '{}' carries untrusted provenance \
                                     but slot '{}' requires TrustRequired policy",
                                    var_name, slot.message_role
                                ),
                            });
                        }
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
- The `vars: HashMap<String, TemplateVar>` parameter is used only for **O(1) lookup**
  (`vars.get(var_name)`); its iteration order is irrelevant to the check correctness.

This is a **hard block at the pure-core layer**, not a guardrail advisory. The error is
`E-TMPL-001` (SECURITY category) and propagates via `?` to the caller. The guardrail
boundary (DI-012) is a second layer for content entering the model context — it is not
a replacement for this render-time check.

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
- **Strict-undefined mode**: raises `E-TMPL-003` (VALIDATION) on any undefined variable
  reference rather than silently substituting an empty string — prevents accidental
  information hiding during template development.

These mechanisms are complementary to the `SlotTrustPolicy` injection check (Decision 3),
which fires at the variable-substitution level before engine rendering.

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
designed to carry user-supplied content — blocking `ProvenanceTag::UserInput` there would
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
  noted (VP-006 candidate: prove that untrusted content never renders into SystemMessage).
- `PromptValue` carries `MessageProvenance` — callers that previously assumed raw `Vec<Message>`
  from a template must unwrap or use the helper `.into_messages()` method.
- `E-TMPL-001` (SECURITY/InjectionAttempt) and `E-TMPL-002` (VALIDATION/SystemSlotPolicy)
  are new error codes; they belong in the error taxonomy (ferrochain-core `core::error`).
- ferrochain-prompts depends on ferrochain-core. No new deps on ferrochain-graph or
  ferrochain-memory — prompt templates are lower in the dependency graph than execution.
- The jinja2 engine has an external dep (`minijinja = "2"`, 2.21.0, `default-features = false`)
  and is opt-in via `feature = "jinja2"`. Default dependency tree: ferrochain-prompts →
  ferrochain-core only (no minijinja unless the `jinja2` feature is enabled).
- `E-TMPL-003` (VALIDATION/UndefinedVariable) is added for minijinja strict-undefined mode
  violations; it belongs in the error taxonomy alongside `E-TMPL-001` and `E-TMPL-002`.
