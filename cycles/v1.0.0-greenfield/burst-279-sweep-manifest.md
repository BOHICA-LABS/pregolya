---
document_type: sweep-manifest
burst: "279"
wave: A
producer: architect
timestamp: 2026-07-28T00:00:00Z
findings_closed: [F-P175-B101, F-P175-B102, F-P175-B201, F-P175-B202, F-P175-B208]
frozen_head: caaa09b
---

# Burst-279 Sweep-Boundary Manifest

Wave A — Architect Security Adjudications. Frozen reference HEAD: `caaa09b`.

---

## Changed Files

Wave A (initial) + Gap corrections (Wave A continued):

| File | Version | Finding(s) / Changes |
|------|---------|---------------------|
| `.factory/specs/architecture/decisions/ADR-012-self-improvement-primitives.md` | 1.8 → 1.10 | F-P175-B101, F-P175-B102 (v1.9); Gap 3 empty-app_id fail-loud (v1.10) |
| `.factory/specs/architecture/decisions/ADR-015-prompt-template-injection-safety.md` | 1.9 → 1.10+ | F-P175-B201, F-P175-B202, F-P175-B208 (v1.10); Gap 1 FewShot adjudication, TemplateInput concretized, B201 type-level answer (same burst) |
| `.factory/specs/prd-supplements/interface-definitions.md` | 2.65 → 2.67 | F-P175-B101, F-P175-B102, F-P175-B208 (v2.66); Gap 2 TemplateInput enum + format_messages sig (v2.67) |
| `.factory/specs/verification-properties/VP-006.md` | 1.6 → 1.7 | Gap 2 TD-VSDD-060 — formal invariant + Kani harness updated for TemplateInput |
| `.factory/specs/architecture/ARCH-INDEX.md` | 1.20 → 1.22 | Changelog propagation (v1.21 initial wave; v1.22 gap corrections) |
| `.factory/cycles/v1.0.0-greenfield/wave-b-po-routing-spec-279.md` | created (updated) | F-P175-B101..B202; + Gap corrections: Routing Items 5, 6, 7; Routing Item 1 empty-app_id fix |
| `.factory/cycles/v1.0.0-greenfield/burst-279-sweep-manifest.md` | created (this document) | (sweep boundary record) |

---

## Identifier Sweep

Every identifier touched in this burst, with corpus match classification and change summary.

### `MemoryScope::App(app_id)` — Scope Tenancy Boundary

| Identifier | Corpus matches (before burst) | Classification | Change |
|-----------|------------------------------|----------------|--------|
| `MemoryScope::App(spec.namespace)` | ADR-012 Decision 1 §Primitive B description, BC-2.15.006 PC1 | CRITICAL BUG — caller-supplied content namespace as tenant identity | ADR-012: amended to `MemoryScope::App(run_context.app_id)` with composite key; BC-2.15.006 PC1 routed to PO |
| `spec.namespace` (as `app_id` arg) | BC-2.15.006 PC1 | CRITICAL BUG — content namespace ≠ app identity | Reclassified as key-namespace prefix; routing spec provides replacement text |
| `run_context.app_id` | Not present (new field) | NEW — system-derived tenant identity | Added to RunContext struct in ADR-012 Amendment and interface-definitions.md |
| `format!("{}/{}", spec.namespace, spec.key)` | Not present (new) | NEW — composite storage key | Added as corrected ContextMutationConfig loading key in ADR-012 Amendment |

### `SkillStore` — Scope Encapsulation

| Identifier | Corpus matches (before burst) | Classification | Change |
|-----------|------------------------------|----------------|--------|
| `SkillStore::load_skill` | ADR-012 Decision 1 §Primitive A, interface-definitions.md §SkillStore, BC-2.15.004 | CRIT GAP — no scope; resolves to Session by default | ADR-012 Amendment: scope bound at construction. Trait method signature UNCHANGED. |
| `SkillStore::list_skills` | Same corpus | CRIT GAP — same | Same: scope bound at construction |
| `SkillStore::skill_exists` | Same corpus | CRIT GAP — same | Same: scope bound at construction |
| `SkillStore::new(store, app_id)` | Not present (new constructor signature) | NEW — construction-time scope binding | Added in ADR-012 Amendment; BC-2.15.004 PC3 update routed to PO |
| `E-MEMORY-004 NoScopeContext` | Not present (new error code) | NEW — fail-closed sentinel | Defined in ADR-012 Amendment and routing spec; PO must mint in error taxonomy |

### `TrustLevel` — Severity Inversion Fix

| Identifier | Corpus matches (before burst) | Classification | Change |
|-----------|------------------------------|----------------|--------|
| `TrustLevel` enum derives | ADR-015 Decision 3, interface-definitions.md §Prompt Templates | HIGH BUG — missing `Copy`, `#[non_exhaustive]`, `#[cfg_attr(kani, derive(kani::Arbitrary))]` | Added all three in both ADR-015 and interface-definitions.md |
| `TrustLevel::severity()` | Not present | NEW — safe aggregate comparison method | Added in ADR-015 Amendment and interface-definitions.md; Untrusted=2, UserInput=1, Trusted=0 |
| `#[derive(Ord)]` on `TrustLevel` | Not present (no Ord derive existed) | HIGH LATENT — declaration order inverts severity | Explicit prohibition added in ADR-015 and interface-definitions.md doc comment |
| `Iterator::max()` on TrustLevel | Not present | HIGH LATENT — would fail-open | Prohibition added in severity() doc comment |
| `BC-2.18.002 INV-2` severity-ordering text | BC-2.18.002 INV-2 | NEEDS UPDATE — does not reference severity() method | Routed to PO with replacement text |

### `PromptTemplate::format` — Unguarded Surface

| Identifier | Corpus matches (before burst) | Classification | Change |
|-----------|------------------------------|----------------|--------|
| `PromptTemplate::format` | ADR-015, interface-definitions.md §Prompt Templates, BC-2.18.001, BC-2.18.004 §Related BCs | CRIT GAP — §Related BCs falsely claims injection_guard fires on this path | ADR-015 Amendment: explicit unguarded declaration added; BC side routed to PO |
| `BC-2.18.004 §Related BCs` (false injection_guard claim) | BC-2.18.004 | CRIT — incorrect cross-reference | Routed to PO; routing spec item 3 provides replacement text |

### `MessageListVar` / `TemplateInput::Messages` — Injection Guard Gap

| Identifier | Corpus matches (before burst) | Classification | Change |
|-----------|------------------------------|----------------|--------|
| `MessageListVar.trust_level` | ADR-015 §MessagesPlaceholder trust derivation | CRIT GAP — defined but never checked by injection_guard | ADR-015 Amendment: injection check extended to cover `TemplateInput::Messages` arm |
| `TemplateInput` enum | ADR-015 (API shape deferred to story) | NEW CONCRETE REFERENCE — unifying enum for both input types | ADR-015 code sketch updated to use `TemplateInput::Scalar(TemplateVar)` and `TemplateInput::Messages(MessageListVar)` |
| `vars: HashMap<String, TemplateVar>` (format_messages param) | ADR-015 Decision 3 code sketch | WAS INCORRECT — hid MessageListVar from the check | Updated to `vars: HashMap<String, TemplateInput>` |
| `BC-2.18.004 PC5` | BC-2.18.004 | NEEDS UPDATE — covers only scalar TemplateVar | Routed to PO; routing spec item 4 provides replacement text |

### `TemplateInput` — Enum Concretized (Gap 2 / TD-VSDD-060 Sweep)

| Identifier | Sites | Owner | Change |
|-----------|-------|-------|--------|
| `TemplateInput` enum definition | ADR-015 (new), interface-definitions.md (new) | Architect | Added in this burst — three arms: Scalar, Messages, FewShotExamples |
| `format_messages` param `HashMap<String, TemplateVar>` | BC-2.18.002 PC1/PC2, BC-2.18.004 PC2 | PO | Routing Items 6 and 7 provide replacement text |
| `format_messages` param `HashMap<String, TemplateVar>` | interface-definitions.md §format_messages | Architect | FIXED in this burst (v2.67) |
| `format_messages` param `HashMap<String, TemplateVar>` | VP-006.md formal invariant | Architect | FIXED in this burst (v1.7) |
| `VP-006` Kani harness `SlotVar.trust_level: Option<TrustLevel>` | VP-006.md | Architect | FIXED — SlotVar.input now TemplateInput; harness covers Scalar + Messages + FewShotExamples |
| `format_messages` name-only references | nfr-catalog.md, entities-graph.md, failure-modes.md, BC-2.08.006.md | PO/BA | NO CHANGE REQUIRED — function-name references only; no type signatures |
| `PromptTemplate::format` with `HashMap<String, TemplateVar>` | BC-2.18.001 PC2, PC1 | PO | NO CHANGE REQUIRED — `PromptTemplate::format` is scalar-only; `HashMap<String, TemplateVar>` is CORRECT for this surface |

### `FewShotPromptTemplate` — Example Trust Check (Gap 1 / F-P175-B202)

| Identifier | Sites | Owner | Change |
|-----------|-------|-------|--------|
| `FewShotPromptTemplate` example pair type `Vec<(String, String)>` | BC-2.18.003 PC2 | PO | Routing Item 5 replacement: `Vec<(TemplateVar, TemplateVar)>` |
| `FewShotPromptTemplate` pre-expansion guard | BC-2.18.003 PC5 | PO | Routing Item 5 addition: pre-guard note before `example_template.format()` |
| `TemplateInput::FewShotExamples` arm | ADR-015 (new), interface-definitions.md (new), VP-006.md (new) | Architect | Added in this burst |

### Gap 3 — `empty app_id` Fail-Loud (B101 Path)

| Identifier | Sites | Owner | Change |
|-----------|-------|-------|--------|
| B101 empty-app_id behavior | ADR-012 §Decision 1 §Security argument | Architect | FIXED burst-279 — Ok(None) → Err(E-MEMORY-004 NoScopeContext) |
| B101 empty-app_id RunContext doc | ADR-012 §Decision 1 RunContext.app_id doc | Architect | FIXED burst-279 |
| B101 empty-app_id in routing spec | wave-b-po-routing-spec-279.md Routing Item 1 | Architect | FIXED — routing spec PC1 replacement text corrected to Err |
| B101 empty-app_id in BC-2.15.006 | BC-2.15.006 (EC-NEW) | PO | Routing Item 1 EC replacement text updated to Err (not Ok(None)) |

---

## Non-Changed Files (In-Scope Sweep Results)

The following files were scanned for mentions of the changed identifiers. No changes
required beyond the PO-routed items listed in the routing spec.

| File | Scan result |
|------|-------------|
| `.factory/specs/behavioral-contracts/ss-15/BC-2.15.004.md` | PO authority; replacement text in routing spec item 2 |
| `.factory/specs/behavioral-contracts/ss-15/BC-2.15.006.md` | PO authority; replacement text in routing spec item 1 (updated to Err) |
| `.factory/specs/behavioral-contracts/ss-18/BC-2.18.001.md` | PO authority; prohibition note in routing spec item 3. NOTE: `HashMap<String, TemplateVar>` at lines 63/69 is CORRECT (PromptTemplate::format scalar surface) — no type change needed |
| `.factory/specs/behavioral-contracts/ss-18/BC-2.18.002.md` | PO authority; INV-2 update (item 4); PC1/PC2 signature update (item 6) |
| `.factory/specs/behavioral-contracts/ss-18/BC-2.18.003.md` | PO authority; PC2 FewShot type change (item 5); PC5 pre-guard note (item 5) |
| `.factory/specs/behavioral-contracts/ss-18/BC-2.18.004.md` | PO authority; PC5 + §Related BCs updates (items 3, 4); PC2 type update (item 7) |
| `.factory/specs/prd-supplements/error-taxonomy.md` | PO authority; E-MEMORY-004 mint in routing spec |
| `.factory/specs/prd-supplements/nfr-catalog.md` | Scanned: function-name references only (NFR-014 performance bound); no type signatures; NO CHANGE REQUIRED |
| `.factory/specs/domain-spec/entities-graph.md` | Scanned: no `format_messages` type signature occurrences; NO CHANGE REQUIRED |
| `.factory/specs/domain-spec/failure-modes.md` | Scanned: no `format_messages` type signature occurrences; NO CHANGE REQUIRED |
| `.factory/specs/behavioral-contracts/ss-08/BC-2.08.006.md` | Scanned: mentions `format_messages_for_provider` (different function); no `HashMap<String, TemplateVar>` type signatures; NO CHANGE REQUIRED |

---

## TD-VSDD-060 Sweep Summary

`grep -rn 'HashMap<String, TemplateVar>' .factory/specs/` — remaining occurrences after this burst:

- **Architect-owned files:** All occurrences are in historical-reference context (changelog entries, prior-form descriptions explaining the change). Zero live-specification occurrences remain in architect-owned files.
- **PO-owned BCs:** BC-2.18.002 (2 occurrences), BC-2.18.004 (1 occurrence) — routing spec items 6/7 provide exact replacement text.
- **PromptTemplate::format (CORRECT):** BC-2.18.001 (2 occurrences) — these correctly describe `PromptTemplate::format`, not `format_messages`. NO CHANGE.

---

## Scope Boundary

**In-scope (architect authority — done this burst):**
- ADR-012 Decision 1 Amendment (B101 scope bridge, B102 SkillStore, Gap 3 fail-loud correction)
- ADR-015 Decision 3 Amendment (B201 unguarded, B202 MessageListVar + FewShot, B208 TrustLevel, Gap 1 FewShot body, TemplateInput concretized, B201 type-level question answered)
- interface-definitions.md (TrustLevel, RunContext.app_id, SkillStore scope, TemplateInput enum, format_messages signature)
- VP-006.md (formal invariant + Kani harness for TemplateInput)
- ARCH-INDEX.md changelog propagation

**Out-of-scope (PO authority — routed via Routing Items 1–7):**
- BC body edits (BC-2.15.004, BC-2.15.006, BC-2.18.001, BC-2.18.002, BC-2.18.003, BC-2.18.004)
- E-MEMORY-004 error taxonomy mint
- error-taxonomy.md (PO authority)

**Out-of-scope (no change required):**
- nfr-catalog.md (function-name references only)
- entities-graph.md, failure-modes.md, BC-2.08.006.md (no type signature occurrences)
- domain-spec/ files (BA authority; no changes triggered by this burst)
- STATE.md (state-manager authority)
