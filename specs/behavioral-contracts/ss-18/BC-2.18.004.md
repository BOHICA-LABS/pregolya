---
document_type: behavioral-contract
level: L3
bc_id: BC-2.18.004
version: "1.5"
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
timestamp: 2026-07-22T00:00:00Z
di_anchors: [DI-008, DI-014]
red_gate: true
red_gate_source: "ADR-015 Decision 3 §Security Invariant 1 — injection_guard must block before implementation; VP-006 Kani candidate"
vp_seed: true
vp_id: VP-006
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-18 Prompt Templates; SECURITY-CRITICAL"
  - "1.1 (F-P224/F-P129-12/2026-07-21): Deterministic evaluation order specified for multi-variable TrustRequired slots. When one TrustRequired slot references multiple template variables (e.g., System('{a}: {b}')), iteration follows template source order (parse order of variable references in the template string), NOT HashMap iteration order — ensuring the <var_name> in E-TMPL-001 is deterministic. Added Invariant 5 (source-order discipline), EC-007 (intra-slot multi-untrusted-variable determinism), TV-005 (canonical test vector). Note: if ADR-015 code sketch implies HashMap iteration, that is a contradiction to route to architect."
  - "1.2 (burst-226/F-P131-05/2026-07-21): TrustLevel migration — replace all ProvenanceTag::Untrusted/::UserInput/::Trusted/::Internal refs with TrustLevel::* per ADR-015 v1.3 Decision 3 adjudication. Internal variant does not exist — removed. TemplateVar field renamed trust_level (from tag). MessageProvenance field renamed highest_trust_level (from tag). INV-4, INV-5, PC2, PC5, EC-001..007, TV-001..005 updated accordingly."
  - "1.3 (burst-238/sweep/2026-07-23): VP Registration (Traceability) and VP Anchors section updated: stale 'ARCH-INDEX candidate — architect assigns VP-INDEX entry after BC authoring completes' and 'pending VP-006 registration in VP-INDEX.md' replaced with 'assigned in VP-INDEX v1.2 as VP-006' (VP-INDEX v1.2 burst-223 seeded VP-006 Kani P1; VP-006.md exists). Completed-handoff residue removal."
  - "1.4 (F-P148-03/burst-249/2026-07-24): red_gate_source and Red Gate body callout updated: 'ADR-015 Security Invariant 1' → 'ADR-015 Decision 3 §Security Invariant 1' per ADR-015 v1.5 labeled anchor. input-hash updated to fa92953 (ADR-015 v1.5 adds labeled anchors)."
  - "1.5 (FIX-BURST-270/ADR-010-v1.9/2026-07-25): Apply PascalCase casing canon (ADR-010 v1.9 Direction B) at 4 sites: Component::TMPL → Component::Tmpl, Category::SECURITY → Category::Security. Sites: Description inline code block (×1 TMPL+SECURITY), PC-1 code block (×1 TMPL, ×1 SECURITY), Invariant 2 prose (×1 SECURITY)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-022
  - architecture/decisions/ADR-015-prompt-template-injection-safety.md
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
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

# BC-2.18.004: injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed at Render Time)

> **Red Gate test required** — ADR-015 Decision 3 §Security Invariant 1: the injection_guard test must
> COMPILE and FAIL before the `injection_guard` pure-core check is implemented. VP-006 Kani
> candidate: prove that a TrustRequired slot with an Untrusted variable NEVER produces a
> PromptValue.

## Description

The `injection_guard` module fires inside `ChatPromptTemplate::format_messages` **at render
time**, before any `PromptValue` is produced and before the guardrail boundary (DI-012). If
any variable being substituted into a `TrustRequired` slot carries `trust_level: Some(TrustLevel::Untrusted)` (i.e., `var.trust_level.is_some_and(|t| t.is_untrusted()) == true`), `format_messages` immediately returns
`Err(FerrochainError { component: Component::Tmpl, category: Category::Security, code: "E-TMPL-001", ... })`.
This is a **categorical hard block at the pure-core layer** — it is unconditional, not
configurable via `GuardrailHook`, and does not produce a partial `PromptValue`. SystemMessage
slots are always `TrustRequired` (enforced by BC-2.18.005); this BC specifies the render-time
enforcement of that invariant.

## Preconditions

1. A `ChatPromptTemplate` has been validly constructed (all policy checks passed per BC-2.18.005).
2. `format_messages` is called with a `HashMap<String, TemplateVar>` where at least one
   `TemplateVar` intended for a `TrustRequired` slot carries `trust_level: Some(TrustLevel::Untrusted)`
   (i.e., `var.trust_level.is_some_and(|t| t.is_untrusted())`).
3. The `TrustRequired` slot's variable name is present in the vars map (variable is not undefined).

## Postconditions

1. `format_messages` returns:
   ```
   Err(FerrochainError {
       component: Component::Tmpl,
       category: Category::Security,
       code: "E-TMPL-001",
       message: "InjectionAttempt: variable '{var_name}' carries untrusted provenance \
                 but slot '{slot_role}' requires TrustRequired policy",
   })
   ```
   where `{var_name}` is the name of the variable and `{slot_role}` is the `MessageRole`
   (e.g., `"system"`) of the refusing slot. Both placeholders are rendered dynamically.
2. No `PromptValue` is produced — the rendering is aborted at the first failing slot.
3. The error propagates via `?` to the caller; it is not caught or converted by any internal
   layer within `ferrochain-prompts`.
4. The check fires **before** the guardrail boundary (DI-012 / BC-2.11.001); the guardrail
   is a second, independent layer and does not substitute for this check.
5. Variables with `TrustLevel::UserInput` or `TrustLevel::Trusted` substituted into a
   `TrustRequired` slot do NOT trigger E-TMPL-001 (only `TrustLevel::Untrusted` triggers it).

## Invariants

1. The injection_guard check fires unconditionally for every `TrustRequired` slot on every
   call to `format_messages` — no bypass path exists (not even debug/test modes).
2. `category: Category::Security` distinguishes this error from validation errors; error
   taxonomy places E-TMPL-001 in the SECURITY severity tier.
3. The check is a **pure-core synchronous function** — no I/O, no async, no external
   dependencies. Kani VP-006 candidacy is grounded in this property.
4. `PromptValue` with a TrustRequired/Untrusted combination is a type-invariant: no instance
   of `PromptValue` where `MessageProvenance.highest_trust_level == Some(TrustLevel::Untrusted)` and
   `MessageProvenance.slot_trust_policy == TrustRequired` can be constructed.
5. **Source-order evaluation discipline:** when a single TrustRequired slot references
   multiple template variables (e.g., `System("{a}: {b}")`), the injection_guard iterates
   variables in **template source order** (the order variable references appear in the
   template string, as produced by the f-string template parser's left-to-right variable scan) — NOT in HashMap iteration order.
   This ensures the `<var_name>` in the E-TMPL-001 error message is deterministic and
   reproducible regardless of HashMap seed or insertion order.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Var has `trust_level: Some(TrustLevel::UserInput)` substituted into a SystemMessage slot | Succeeds — `UserInput` is NOT `Untrusted`; `MessageProvenance.highest_trust_level = Some(TrustLevel::UserInput)` in the output |
| EC-002 | Var has no TrustLevel (`trust_level: None`) substituted into a SystemMessage slot | Succeeds — `None` is not untrusted; `MessageProvenance.highest_trust_level = None` |
| EC-003 | HumanMessage slot (TrustAll policy) receives `trust_level: Some(TrustLevel::Untrusted)` | Succeeds — HumanMessage is TrustAll; injection_guard only fires for TrustRequired slots |
| EC-004 | Two SystemMessage vars — first is TrustLevel::Trusted, second is TrustLevel::Untrusted | Fails on the second var — iteration continues until the first Untrusted+TrustRequired collision |
| EC-005 | `trust_level: Some(TrustLevel::Untrusted)` var, but the slot has been explicitly set to TrustAll (possible only for non-System slots) | Succeeds — TrustAll policy accepts Untrusted; no E-TMPL-001 |
| EC-006 | Multiple TrustRequired slots, all with Untrusted vars | Fails on the FIRST TrustRequired+Untrusted hit; remaining slots are not evaluated |
| EC-007 | One TrustRequired slot `System("{a}: {b}")` — both `a` and `b` carry `trust_level: Some(TrustLevel::Untrusted)` | `Err(E-TMPL-001)` with `var_name = "a"` — first occurrence in template source order; `b` is not evaluated (fail-first); HashMap iteration order is NOT used |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 (Red Gate) | `template = [System("{sys_prompt}"), Human("{question}")]`, `vars = {"sys_prompt": TemplateVar { value: "DROP TABLE users;--", trust_level: Some(TrustLevel::Untrusted) }, "question": TemplateVar { value: "hi", trust_level: None }}` | `Err(FerrochainError { code: "E-TMPL-001", message: "InjectionAttempt: variable 'sys_prompt' carries untrusted provenance but slot 'system' requires TrustRequired policy" })` | error-case (injection attempt) |
| TV-002 | Same template, `vars = {"sys_prompt": TemplateVar { value: "Be helpful.", trust_level: Some(TrustLevel::UserInput) }, "question": TemplateVar { value: "hi", trust_level: None }}` | `Ok(PromptValue { ... })` — UserInput is not Untrusted | happy-path (UserInput trusted enough) |
| TV-003 | `template = [System("Constant."), Human("{q}")]`, `vars = {"q": TemplateVar { value: "...", trust_level: Some(TrustLevel::Untrusted) }}` | `Ok(PromptValue { ... })` — Untrusted only in HumanMessage slot (TrustAll) | happy-path (untrusted in TrustAll slot) |
| TV-004 | `template = [System("{s}"), Human("{h}")]`, both vars `trust_level: Some(TrustLevel::Untrusted)` | `Err(E-TMPL-001)` with `var_name = "s"` (first TrustRequired slot fails first) | error-case (fail-first semantics) |
| TV-005 | `template = [System("{a}: {b}")]`, `vars = {"a": TemplateVar { value: "inject", trust_level: Some(TrustLevel::Untrusted) }, "b": TemplateVar { value: "also inject", trust_level: Some(TrustLevel::Untrusted) }}` | `Err(FerrochainError { code: "E-TMPL-001", message: "InjectionAttempt: variable 'a' carries untrusted provenance but slot 'system' requires TrustRequired policy" })` — `a` appears first in template source order | error-case (intra-slot multi-var determinism) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.18.004-A (VP-006 candidate) | For all `ChatPromptTemplate` instances and all var maps, if any TrustRequired slot receives a variable with `is_untrusted() == true`, `format_messages` returns `Err(E-TMPL-001)` — no code path produces `Ok(PromptValue)` in this case | unit test (pure-core) + Kani VP-006 formal proof: prove the negation is unreachable |
| VP-2.18.004-B | The injection_guard check fires **before** any message is added to the partial render buffer — no partial `PromptValue` is observable | unit test — verify no PromptValue is produced on injection attempt |

## Related BCs

- BC-2.18.002 — composes with: injection_guard fires inside `format_messages`, which is the rendering path BC-2.18.002 specifies
- BC-2.18.005 — depends on: TrustAll on SystemMessage is prohibited at construction time (BC-2.18.005), ensuring all SystemMessage slots are TrustRequired and subject to this check
- BC-2.11.001 — referenced-for-context: DI-012 guardrail is a SEPARATE, post-render ingress mechanism; injection_guard fires pre-render and does NOT replace DI-012

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-18, `prompts::injection_guard` (Pure Core module)
- `architecture/decisions/ADR-015-prompt-template-injection-safety.md` — Decision 3 (injection check code sketch, E-TMPL-001 specification, relationship to DI-012)
- `architecture/purity-boundary-map.md` — `ferrochain-prompts / prompts::injection_guard` Pure Core classification; Kani VP-006 candidacy noted

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-18 security story]_

## VP Anchors

- VP-2.18.004-A (VP-006 assigned VP-INDEX v1.2; VP-006.md exists)
- VP-2.18.004-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-022 |
| Capability Anchor Justification | CAP-022 ("PromptTemplate and ChatPromptTemplate as Runnable (f-string Default, Jinja2 Optional)") per capabilities-p1-p2.md §CAP-022 — this BC specifies the injection_guard security invariant (ADR-015 Decision 3) that CAP-022 names as a security-critical property: "SystemMessage slots are hard-coded TrustRequired; untrusted-tagged variables substituted into a TrustRequired slot → E-TMPL-001 (SECURITY/InjectionAttempt) at render time via injection_guard pure-core blocker (ADR-015 Decision 3). This block is unconditional — not dependent on a configured GuardrailHook. VP-006 Kani candidate." |
| L2 Domain Invariants | DI-008 (injection_guard returns Result; no silent swallowing), DI-014 (E-TMPL-001 propagates as Err; no silent empty substitution or advisory warning) |
| Architecture Authority | ADR-015 Decision 3 (injection check, pure-core blocker, E-TMPL-001 category SECURITY) |
| Binding Decisions | D21 (ecosystem-parity scope expansion), R12 (prompt injection risk from D21 scope) |
| VP Registration | VP-006 (assigned in VP-INDEX v1.2 as VP-006 — Kani P1; ferrochain-prompts injection_guard_fail_closed) |
| Module | ferrochain-prompts / prompts::injection_guard |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (pure-core) + Kani (VP-006 candidate) |
