---
document_type: behavioral-contract
level: L3
bc_id: BC-2.18.005
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
timestamp: 2026-07-20T00:00:00Z
di_anchors: [DI-008, DI-014]
red_gate: true
red_gate_source: "ADR-015 Decision 2 §Security Invariant 2 — SlotTrustPolicy::TrustAll on SystemMessage must be rejected at construction time"
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-18 Prompt Templates; SECURITY-CRITICAL"
  - "1.1 (F-P148-03/burst-249/2026-07-24): red_gate_source and Red Gate body callout updated: 'ADR-015 Security Invariant 2' → 'ADR-015 Decision 2 §Security Invariant 2' per ADR-015 v1.5 labeled anchor. input-hash updated to fa92953 (ADR-015 v1.5 adds labeled anchors)."
  - "1.2 (FIX-BURST-269/F-P167-01/2026-07-25): Fix Category::VALIDATION → Category::VAL at two sites: PC-1 code block (E-TMPL-002 Err struct) and INV-3 prose. VALIDATION is not in the canonical 12-member Category enum; E-TMPL-002 is VAL per error-taxonomy.md §E-TMPL-002. D23 sibling-sweep."
  - "1.3 (FIX-BURST-270/ADR-010-v1.9/2026-07-25): Apply PascalCase casing canon (ADR-010 v1.9 Direction B) at 3 sites: Component::TMPL → Component::Tmpl (PC-1 code block), Category::VAL → Category::Val (PC-1 code block + Invariant 3 prose)."
  - "1.4 (FIX-BURST-278-WAVE-C/D-42-S5-gate/2026-07-28): S5 gate closure — PC-1 postcondition fence: FerrochainError struct literal (missing retry_hint, source fields) → FerrochainError::new(Component::Tmpl, Category::Val, RetryHint::Never, \"E-TMPL-002\", msg) constructor form per D-42 canonical ctor. RetryHint::Never: VAL category default per error-taxonomy.md §E-TMPL-002. Verifiable: grep 'FerrochainError {' specs/behavioral-contracts/ss-18/BC-2.18.005.md returns zero fence-scoped literal occurrences after this edit."
  - "1.5 (wave-b-b7-notation-sweep/2026-07-29): ADR-010 §Class 3 notation sweep — 2 CLASS3_MISSING_DOTDOT violations corrected. (1) Description ¶1 E-TMPL-002 inline cite: add `, ..` field-elision marker. (2) TV-001 expected-output cell: add `, ..` field-elision marker. No security semantics, Red Gate invariants, or VP anchors altered."
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

# BC-2.18.005: SlotTrustPolicy::TrustAll on SystemMessage Slot Raises E-TMPL-002 at Construction Time (Fail-Closed)

> **Red Gate test required** — ADR-015 Decision 2 §Security Invariant 2: the construction-time policy
> rejection test must COMPILE and FAIL before the `from_messages` guard is implemented.

## Description

`ChatPromptTemplate::from_messages` validates slot policies at construction time. Any
attempt to declare a `SystemMessage` slot with `SlotTrustPolicy::TrustAll` is rejected with
`Err(FerrochainError { code: "E-TMPL-002", .. })` — the template is never created. This is a
**compile-time architectural invariant enforced at construction** (ADR-015 Decision 2): there
is no method, configuration flag, or runtime override that permits `TrustAll` on a
SystemMessage slot. The rationale is that "warn-but-allow" is a deferred-security anti-pattern
for an invariant that matters categorically. The enforcement is construction-time, not render-time,
so the error is detected as early as possible regardless of whether the template is ever rendered.

## Preconditions

1. A caller invokes `ChatPromptTemplate::from_messages(messages)` where `messages` contains
   at least one tuple `(MessageRole::System, template_str, SlotTrustPolicy::TrustAll)`.
2. No other preconditions — the check fires unconditionally on construction, before any
   rendering or variable binding.

## Postconditions

1. `ChatPromptTemplate::from_messages` returns:
   ```
   Err(FerrochainError::new(
       Component::Tmpl,
       Category::Val,
       RetryHint::Never,
       "E-TMPL-002",
       "SystemMessage slots must use TrustRequired policy; \
        TrustAll is disallowed for system-position message slots",
   ))
   ```
2. No `ChatPromptTemplate` is created — the construction fails atomically.
3. There is no partial construction state; no slots from the input list are registered before
   the error is returned.
4. Non-SystemMessage slots with `TrustAll` (HumanMessage, AiMessage) do NOT trigger E-TMPL-002.
5. Non-SystemMessage slots with `TrustRequired` (caller hardening) are accepted without error.

## Invariants

1. The `SlotTrustPolicy` of a `SystemMessage` slot is always `TrustRequired` — there is no
   runtime mutation path that changes it after construction.
2. The construction-time check iterates over all declared message tuples before creating the
   template; the first System+TrustAll tuple triggers the error.
3. `category: Category::Val` (not SECURITY) — this is a programming error caught at
   construction time, not a runtime injection attempt. The SECURITY-tier error is E-TMPL-001
   (render-time injection attempt). The taxonomy distinction is intentional.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | All SystemMessage slots declared as `TrustRequired` (correct usage) | Construction succeeds; `Ok(ChatPromptTemplate)` returned |
| EC-002 | No SystemMessage slots — only HumanMessage and AiMessage with TrustAll | Construction succeeds; E-TMPL-002 never fires |
| EC-003 | Multiple SystemMessage slots — first is TrustRequired, second is TrustAll | `Err(E-TMPL-002)` on the second slot; construction fails atomically |
| EC-004 | HumanMessage slot with `TrustRequired` (explicit hardening) | Accepted without error — non-System slots may use either policy |
| EC-005 | AiMessage slot with `TrustAll` (few-shot example slot, default usage) | Accepted without error — AiMessage defaults to TrustAll |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 (Red Gate) | `ChatPromptTemplate::from_messages(vec![(MessageRole::System, "You are {role}.", SlotTrustPolicy::TrustAll)])` | `Err(FerrochainError { code: "E-TMPL-002", message: "SystemMessage slots must use TrustRequired policy; TrustAll is disallowed for system-position message slots", .. })` | error-case (policy violation) |
| TV-002 | `ChatPromptTemplate::from_messages(vec![(MessageRole::System, "You are helpful.", SlotTrustPolicy::TrustRequired), (MessageRole::Human, "{question}", SlotTrustPolicy::TrustAll)])` | `Ok(ChatPromptTemplate { ... })` | happy-path (correct policies) |
| TV-003 | `ChatPromptTemplate::from_messages(vec![(MessageRole::Human, "{q}", SlotTrustPolicy::TrustAll)])` | `Ok(ChatPromptTemplate { ... })` — only Human slot, no System slot | happy-path (no System slot) |
| TV-004 | Template with two System slots: first TrustRequired, second TrustAll | `Err(E-TMPL-002)` — second slot triggers the error | error-case (second System slot fails) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.18.005-A | For all `from_messages` inputs, if any `(MessageRole::System, _, SlotTrustPolicy::TrustAll)` tuple is present, the result is always `Err(E-TMPL-002)` | unit test — exhaustive construction-time policy check |
| VP-2.18.005-B | No `ChatPromptTemplate` instance exists where a SystemMessage slot has `SlotTrustPolicy::TrustAll` — this is a type-level invariant | type-level argument + unit test |

## Related BCs

- BC-2.18.002 — depends on: ChatPromptTemplate rendering (BC-2.18.002) can only produce a PromptValue with TrustRequired SystemMessage slots because this BC ensures no TrustAll SystemMessage slots can exist
- BC-2.18.004 — composes with: construction-time guard (this BC) and render-time guard (BC-2.18.004) are two layers of the same security model; this BC is the first layer

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-18, `prompts::chat_template` (from_messages validation)
- `architecture/decisions/ADR-015-prompt-template-injection-safety.md` — Decision 2 (SlotTrustPolicy enum, SystemMessage hard-coded TrustRequired, from_messages validation code sketch, E-TMPL-002 specification)
- `architecture/purity-boundary-map.md` — `ferrochain-prompts / prompts::chat_template` Pure Core

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-18 security story]_

## VP Anchors

- VP-2.18.005-A, VP-2.18.005-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-022 |
| Capability Anchor Justification | CAP-022 ("PromptTemplate and ChatPromptTemplate as Runnable (f-string Default, Jinja2 Optional)") per capabilities-p1-p2.md §CAP-022 — this BC specifies the construction-time policy enforcement invariant that CAP-022 names explicitly: "SystemMessage slots are hard-coded TrustRequired; untrusted-tagged variables substituted into a TrustRequired slot → E-TMPL-001 (SECURITY/InjectionAttempt)." The construction-time guard (E-TMPL-002) is the pre-condition that makes the render-time guard (E-TMPL-001) structurally necessary and sufficient |
| L2 Domain Invariants | DI-008 (construction returns Result; no panic path), DI-014 (E-TMPL-002 propagates as Err; no warn-and-allow degradation) |
| Architecture Authority | ADR-015 Decision 2 (SlotTrustPolicy, SystemMessage hard-coded TrustRequired, from_messages rejection logic) |
| Binding Decisions | D21 (ecosystem-parity scope expansion), R12 (prompt injection risk from D21 scope) |
| Module | ferrochain-prompts / prompts::chat_template |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit (construction-time, pure-core) |
