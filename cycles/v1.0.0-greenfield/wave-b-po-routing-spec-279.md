---
document_type: po-routing-spec
burst: "279"
wave: B
status: open
producer: architect
timestamp: 2026-07-28T00:00:00Z
findings_addressed: [F-P175-B101, F-P175-B102, F-P175-B201, F-P175-B202]
routes_to: product-owner
---

# Wave B — PO Routing Spec (burst-279)

Architect security adjudications for four CRIT findings from adversarial pass P1D-175.
For each item: the architect has made the architectural decision; the product-owner must
apply the corresponding BC corrections. Exact replacement text is provided.

---

## Routing Item 1 — BC-2.15.006: ContextMutationConfig Scope Bridge (F-P175-B101)

**Architectural decision (ADR-012 Decision 1 Amendment):**
`ContextSourceSpec.namespace` is a key-namespace prefix within the tenant partition, NOT
the `app_id`. Loading uses `MemoryScope::App(run_context.app_id)` with composite key
`format!("{}/{}", spec.namespace, spec.key)`. `RunContext.app_id` is the system-derived
tenant identity.

**BC-2.15.006 PC1 — Replace:**

Current text (approximate):
```
PC1: `graph::scheduler` calls
  `MemoryStore::memory_get(MemoryScope::App(spec.namespace), &spec.key)`
  for each `ContextSourceSpec` in `ContextMutationConfig.sources`.
```

Replacement text (copy-pasteable):
```
PC1: `graph::scheduler` calls
  `MemoryStore::memory_get(
      MemoryScope::App(run_context.app_id),
      &format!("{}/{}", spec.namespace, spec.key),
  )`
  for each `ContextSourceSpec` in `ContextMutationConfig.sources`.
  `run_context.app_id` is the system-derived application tenant identity (set by the
  execution engine before the first super-step; NOT supplied by the caller via
  `RunnableConfig`). `spec.namespace` is a key-namespace prefix scoped WITHIN the
  tenant partition — it is NOT an application identity.
  If `run_context.app_id` is empty, all reads return `Err(E-MEMORY-004 NoScopeContext)`
  — fail-loud; no content is silently skipped (ADR-012 Decision 1 Amendment,
  Gap 3 correction: empty app_id must fail loud, not silently return Ok(None)).
```

**New EC to add (after existing ECs):**
```
EC-NEW: If `run_context.app_id` is empty at the start of a super-step, `graph::scheduler`
  returns `Err(E-MEMORY-004 NoScopeContext)` for each `ContextMutationConfig` load.
  The run does NOT proceed silently with no memory context — it surfaces the missing
  scope as an error. The execution engine is responsible for ensuring `run_context.app_id`
  is set before the first super-step.
  (Fail-loud: symmetric with `SkillStore` construction, per ADR-012 Decision 1 Amendment
  §Gap 3 correction — NO-SILENT-EMPTY enforced on both B101 and B102 paths.)
```

---

## Routing Item 2 — BC-2.15.004: SkillStore Scope Encapsulation (F-P175-B102)

**Architectural decision (ADR-012 Decision 1 Amendment):**
`SkillStore` implementations bind `MemoryScope::App(app_id)` at construction time.
Trait methods remain scopeless. If no `app_id` can be derived at construction → raise
`E-MEMORY-004 NoScopeContext`.

**BC-2.15.004 Precondition to add/update:**

Current PC3 text (approximate):
```
PC3: The caller has read access to the relevant MemoryStore namespace (scope checks
  per BC-2.15.002 apply at the storage layer).
```

Replacement text for the precondition note (the precondition itself does not change
the CALLER's obligations, but a note must clarify the scope derivation):
```
PC3: The caller has read access to the relevant MemoryStore namespace.
  SCOPE NOTE: `SkillStore` implementations bind `MemoryScope::App(app_id)` at
  construction time. Callers do not supply scope at call time. The `app_id` is
  supplied to the `SkillStore` constructor and comes from `RunContext.app_id`
  (system-derived, same as used by `ContextMutationConfig` loading).
  If the `SkillStore` was constructed without a valid `app_id`, all `load_skill`,
  `list_skills`, and `skill_exists` calls return `Err(E-MEMORY-004 NoScopeContext)`.
```

**Error code to mint (E-MEMORY-004 NoScopeContext):**
```
Code:       E-MEMORY-004
Name:       NoScopeContext
Namespace:  MEMORY
Number:     004
Category:   SECURITY
RetryHint:  Never
Raise when: A SkillStore or ContextMutationConfig load operation cannot derive a valid
            MemoryScope::App(app_id) because app_id is empty or unavailable.
            The operation fails closed — no data is returned, no fallback scope used.
BC anchor:  BC-2.15.004 PC3 (SkillStore scope), BC-2.15.006 PC1 (ContextMutationConfig scope)
```

**Mint E-MEMORY-004 in the error taxonomy.**

---

## Routing Item 3 — BC-2.18.001 / BC-2.18.004: PromptTemplate::format Unguarded (F-P175-B201)

**Architectural decision (ADR-015 Decision 3 Amendment):**
`PromptTemplate::format` (the single-message surface) is explicitly unguarded — the
injection check fires ONLY in `ChatPromptTemplate::format_messages`. Any BC that claims
"injection_guard fires during the render path that `PromptTemplate::format` exercises"
is incorrect and must be corrected.

**BC-2.18.004 §Related BCs — Remove or correct the following claim:**

If BC-2.18.004 §Related BCs contains text such as:
```
BC-2.18.004 — depends on: injection_guard fires during the render path that
BC-2.18.001 exercises.
```

This must be removed or replaced with:
```
Note: `PromptTemplate::format` (BC-2.18.001 surface) is NOT guarded by injection_guard.
The injection guard (E-TMPL-001) fires ONLY in `ChatPromptTemplate::format_messages`
(this contract). Output of `PromptTemplate::format` MUST NOT be placed in a system-role
position without an explicit re-check through `ChatPromptTemplate::format_messages`.
```

**BC-2.18.001 — Add the prohibition note:**

Add to BC-2.18.001 §Constraints or §Invariants:
```
INV-NEW: The output of `PromptTemplate::format` is a bare `String` with no
`MessageProvenance` and no injection guard. Callers MUST NOT use this output
directly as system-role content in any LLM call or `ChatPromptTemplate` without
routing it through `ChatPromptTemplate::format_messages` for a TrustLevel check.
(ADR-015 Decision 3 Amendment — PromptTemplate::format explicitly unguarded)
```

---

## Routing Item 4 — BC-2.18.002 / BC-2.18.004: MessageListVar Guard (F-P175-B202)

**Architectural decision (ADR-015 Decision 3 Amendment):**
The injection check must also inspect `MessageListVar.trust_level` for MessagesPlaceholder
slots in TrustRequired position. The corrected check covers both `TemplateInput::Scalar`
(TemplateVar) and `TemplateInput::Messages` (MessageListVar).

**BC-2.18.004 PC5 — Update to cover MessageListVar:**

Current PC5 text (approximate):
```
PC5: injection_guard checks TrustLevel::Untrusted in slot variables against
  TrustRequired slots → raises E-TMPL-001.
```

Replacement text:
```
PC5: `injection_guard` checks BOTH scalar `TemplateVar.trust_level` AND
  `MessageListVar.trust_level` against `TrustRequired` slots:
  - If `TemplateInput::Scalar(var)` and `var.trust_level == Some(TrustLevel::Untrusted)` →
    raises `E-TMPL-001` (InjectionAttempt, SECURITY, never-retry).
  - If `TemplateInput::Messages(msg_var)` and
    `msg_var.trust_level == Some(TrustLevel::Untrusted)` →
    raises `E-TMPL-001` (same error code and category).
  Both input types are guarded equally. There is no path through `format_messages` that
  delivers an `Ok(PromptValue)` when either a scalar or message-list variable carries
  `TrustLevel::Untrusted` in a `TrustRequired` slot. (VP-006 Kani proof covers this
  invariant exhaustively for both input arms.)
```

**BC-2.18.002 INV-2 — Update severity ordering to reference `severity()` method:**

Current INV-2 text (approximate):
```
INV-2: TrustLevel severity ordering: Untrusted > UserInput > Trusted. The highest-severity
  TrustLevel wins.
```

Replacement text:
```
INV-2: TrustLevel severity ordering: Untrusted (severity=2) > UserInput (severity=1) >
  Trusted (severity=0). The highest-severity TrustLevel wins. Aggregate computation MUST
  use `TrustLevel::severity()` comparisons (`.max_by_key(|t| t.severity())`); `Ord::max()`
  or derived `Ord` on `TrustLevel` MUST NOT be used — declaration order is the INVERSE of
  security severity (ADR-015 Decision 3 Amendment, F-P175-B208).
```

---

## Routing Item 5 — BC-2.18.003 PC2: FewShot Example Type Change (F-P175-B202)

**Architectural decision (ADR-015 Decision 3 Amendment — FewShotPromptTemplate):**
`FewShotPromptTemplate` example inputs are promoted from bare `(String, String)` pairs
to `(TemplateVar, TemplateVar)` pairs so each example component carries a trust level.

**BC-2.18.003 Precondition 2 — Replace:**

Current PC2 text (approximate):
```
PC2: A `Vec` of `(example_input: String, example_output: String)` pairs is provided
  at construction; a `PromptTemplate` is provided to format each example.
```

Replacement text:
```
PC2: A `Vec` of `(example_input: TemplateVar, example_output: TemplateVar)` pairs is
  provided at construction; a `PromptTemplate` is provided to format each example pair.
  Each `TemplateVar` carries an optional `trust_level: Option<TrustLevel>`.
  This allows the outer `injection_guard` in `ChatPromptTemplate::format_messages` to
  check example component trust levels before calling the inner `example_template.format()`.
  (Prior form `Vec<(String, String)>` had no trust classification — this type change
  closes the FewShot injection path per ADR-015 Decision 3 Amendment.)
```

**BC-2.18.003 FewShotPromptTemplate Postcondition 5 — Update:**

Current PC5 text (approximate):
```
PC5: Each (input, output) pair is rendered via the provided example_template: PromptTemplate
  and produces a (HumanMessage(rendered_input), AiMessage(rendered_output)) pair.
```

Add pre-guard note:
```
PC5: Before rendering each pair via `example_template: PromptTemplate`, the outer
  `ChatPromptTemplate::format_messages` injection_guard checks the trust level of BOTH
  the `example_input` and `example_output` `TemplateVar` components against the slot's
  `SlotTrustPolicy`. If either component carries `TrustLevel::Untrusted` in a
  `TrustRequired` slot, `format_messages` returns `Err(E-TMPL-001)` before any
  `example_template.format()` call is made. (Fail-closed, per ADR-015 Decision 3
  Amendment — FewShotPromptTemplate Example Trust Check, F-P175-B202.)
```

---

## Routing Item 6 — BC-2.18.002 PC2/PC1: format_messages Signature Change (TD-VSDD-060)

**Architectural decision (ADR-015 Decision 3 Amendment — TemplateInput Enum Concretized):**
`ChatPromptTemplate::format_messages` parameter type changes from `HashMap<String, TemplateVar>`
to `HashMap<String, TemplateInput>`. This is a breaking API change.

**BC-2.18.002 Precondition 2 — Replace:**

Current PC2 text (approximate):
```
PC2: For rendering, a `HashMap<String, TemplateVar>` is provided where every `TemplateVar`
  that binds to a TrustRequired slot carries a `trust_level`.
```

Replacement text:
```
PC2: For rendering, a `HashMap<String, TemplateInput>` is provided. Each `TemplateInput`
  is one of:
  - `TemplateInput::Scalar(TemplateVar)` — scalar string binding for human/AI/system slots
  - `TemplateInput::Messages(MessageListVar)` — message-list expansion for MessagesPlaceholder
  - `TemplateInput::FewShotExamples(Vec<(TemplateVar, TemplateVar)>)` — for FewShot slots
  For each `TemplateInput` that binds to a `TrustRequired` slot, the trust level of the
  input's components is checked before rendering (injection_guard, BC-2.18.004).
  (Breaking change from prior `HashMap<String, TemplateVar>` per ADR-015 §Decision 3
  Amendment — TemplateInput Enum Concretized, burst-279.)
```

**BC-2.18.002 Postcondition 1 — Update signature:**

Current PC1 signature (approximate):
```
PC1: `ChatPromptTemplate::format_messages(&self, vars: HashMap<String, TemplateVar>)
  → Result<PromptValue, FerrochainError>`
```

Replacement:
```
PC1: `ChatPromptTemplate::format_messages(&self, vars: HashMap<String, TemplateInput>)
  → Result<PromptValue, FerrochainError>`
```

---

## Routing Item 7 — BC-2.18.004 PC2: format_messages Parameter Type (TD-VSDD-060)

**BC-2.18.004 Precondition 2 — Replace:**

Current PC2 text (approximate):
```
PC2: `format_messages` is called with a `HashMap<String, TemplateVar>` where at least one
  variable binding has `trust_level: Some(TrustLevel::Untrusted)`.
```

Replacement text:
```
PC2: `format_messages` is called with a `HashMap<String, TemplateInput>` where at least
  one input binding — in a `TrustRequired` slot — has a `TrustLevel::Untrusted` component.
  The input may be any arm of `TemplateInput`:
  - `TemplateInput::Scalar(v)` with `v.trust_level == Some(TrustLevel::Untrusted)`
  - `TemplateInput::Messages(m)` with `m.trust_level == Some(TrustLevel::Untrusted)`
  - `TemplateInput::FewShotExamples(pairs)` where any `(iv, ov)` has
    `iv.trust_level == Some(TrustLevel::Untrusted)` or
    `ov.trust_level == Some(TrustLevel::Untrusted)`
  (Breaking type change from `HashMap<String, TemplateVar>` per ADR-015 §Decision 3
  Amendment — TemplateInput Enum Concretized, burst-279.)
```

---

## TD-VSDD-060 Sweep: Non-PO / Non-BA Sites

The following files mention `format_messages` but do NOT carry the type signature
`HashMap<String, TemplateVar>` as a live spec claim — no changes required:

- `nfr-catalog.md` — function-name references only (NFR-014 performance bound); no type signature
- `entities-graph.md` — no occurrences found
- `failure-modes.md` — no occurrences found
- `BC-2.18.001.md` — `HashMap<String, TemplateVar>` at lines 63/69 is CORRECT: these describe
  `PromptTemplate::format` (the single-message scalar-only surface), NOT `format_messages`.
  `PromptTemplate::format` retains `HashMap<String, TemplateVar>` because it is scalar-only.

---

## E-MEMORY-004 Mint Summary

| Field | Value |
|-------|-------|
| Code | E-MEMORY-004 |
| Name | NoScopeContext |
| Namespace | MEMORY |
| Number | 004 |
| Category | SECURITY |
| RetryHint | Never |
| Raise conditions | Empty `app_id` at `SkillStore` construction; empty `app_id` in `RunContext` at `ContextMutationConfig` load time |
| BC anchors | BC-2.15.004 PC3, BC-2.15.006 PC1 |

Mint this in the error taxonomy alongside existing MEMORY-namespace codes.

---

## Scope Boundary

The architect has adjudicated and fixed the following in this burst:
- ADR-012 Decision 1 Amendment (scope bridge + SkillStore encapsulation; empty app_id → Err fail-loud)
- ADR-015 Decision 3 Amendment (PromptTemplate::format prohibition + MessageListVar guard + TrustLevel severity fix + TemplateInput enum concretized + FewShot adjudication + B201 type-level design question answered)
- interface-definitions.md — TrustLevel enum, RunContext.app_id, SkillStore scope note, TemplateInput enum, format_messages signature
- VP-006.md — formal invariant and Kani harness updated for TemplateInput

The product-owner is responsible for:
- BC-2.15.004 PC3 update (SkillStore scope note)
- BC-2.15.006 PC1 replacement text (scope bridge; empty app_id → Err, not Ok(None)) — see Routing Item 1
- BC-2.18.001 INV-NEW (PromptTemplate::format prohibition) — see Routing Item 3
- BC-2.18.004 §Related BCs correction (remove false injection_guard claim for format path) — see Routing Item 3
- BC-2.18.004 PC5 update (MessageListVar + FewShot guard coverage) — see Routing Item 4
- BC-2.18.002 INV-2 update (severity() reference) — see Routing Item 4
- BC-2.18.003 PC2 update (FewShot examples: Vec<(TemplateVar, TemplateVar)>) — see Routing Item 5
- BC-2.18.003 PC5 update (pre-guard note before example_template.format()) — see Routing Item 5
- BC-2.18.002 PC2 update (HashMap<String, TemplateInput> type) — see Routing Item 6
- BC-2.18.002 PC1 signature update (HashMap<String, TemplateInput>) — see Routing Item 6
- BC-2.18.004 PC2 update (HashMap<String, TemplateInput> type) — see Routing Item 7
- E-MEMORY-004 NoScopeContext mint in error taxonomy
