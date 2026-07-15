---
document_type: adversarial-review
pass: 58
verdict: NOT_CLEAN
novelty: HIGH
finding_count: 3
high_count: 1
medium_count: 2
low_count: 0
timestamp: 2026-07-15T00:00:00Z
scope: prd-supplements, behavioral-contracts, domain-spec
---

# Adversarial Review — Pass 58

**Verdict:** NOT CLEAN — 3 findings (1 HIGH, 2 MED). Novelty HIGH (all in pass-56/57-edited surface — partial-fix regression against pass-57's own de-undefined-type rationale).

---

## F-P58-02 (HIGH): IngressContent Type Undefined — Three-Way Naming Drift

**Location:** `interface-definitions.md` §GuardrailHook (lines ~153, ~170, ~173); `BC-2.11.002` PC1; `entities-server.md` line 97; `error-taxonomy.md` E-CORE-007 message format.

**Finding:** `IngressContent` is referenced 3× in the v2.12 GuardrailHook block — as the `content` parameter type, as the `Transform.new_content` type, and in the doc-comment asserting "any IngressContent variant" — but is **DEFINED NOWHERE** in the spec corpus.

Three-way naming drift:
- `interface-definitions.md` §GuardrailHook: `content: IngressContent`
- `BC-2.11.002` PC1: "every `ToolMessage ContentBlock`" — uses the concrete inner type name, not the enum variant
- `entities-server.md` line 97: `action_fn: Fn(Content, ProvenanceTag)` — uses bare `Content`
- `error-taxonomy.md` E-CORE-007 message: `'<content_type>'` placeholder — implies discriminable type but names no enum

The fix introduced by pass-57 (F-P57-01) added `IngressContent` to the trait signature as a correction from `Result<IngressContent, GuardrailError>` but did not define the type — creating a type name with zero definition sites in the corpus.

**Fix required:** Define `IngressContent` inline in `interface-definitions.md` §GuardrailHook as an enum with variants derived from the BC-authoritative boundary types (BC-2.11.002/003/004 PC1). Reconcile the E-CORE-007 `<content_type>` placeholder to the IngressContent variant name. Add minimal cross-reference notes to BC-2.11.002/003/004.

---

## F-P58-01 (MED): GuardrailSeverity Type Undefined

**Location:** `interface-definitions.md` §GuardrailHook line ~167 (`severity: GuardrailSeverity`).

**Finding:** `GuardrailSeverity` is referenced as the `Fail.severity` type — sole corpus hit. The 4-value ladder (Critical > High > Medium > Low, Critical → run-failed) exists only in prose in BC bodies (BC-2.11.002 INV-3, BC-2.11.005 PC4/PC5) and in the GuardrailResult doc-comment. The type itself has no definition site.

Applies the same undefined-type standard that pass-57 used to remove `GuardrailError`: a type referenced in a trait signature must have a definition site in the corpus.

**Fix required:** Define `GuardrailSeverity` enum inline in `interface-definitions.md` §GuardrailHook with the 4 values and the Critical-run-failed rule cited to BC-2.11.002 INV-3 and BC-2.11.005 PC4/PC5.

---

## F-P58-03 (MED): entities-server.md §ss-11 Entities Contradict BC-Authoritative Shapes

**Location:** `entities-server.md` lines ~90–99 (§ProvenanceTag and §GuardrailHook).

**Finding:** The ss-11 entity shapes in `entities-server.md` contradict the BC-authoritative shapes in three ways:

**ProvenanceTag** (entity vs BC-2.11.001):
- Entity: `source_type: IngressSource (Tool | RAG | Memory | User | Model)`, `tool_name`, `invocation_id`, `timestamp`
- BC-authoritative (BC-2.11.001 PC1–PC3): `boundary_type: BoundaryType (ToolResult | RAGRetrieval | MemoryIngress)`, `ingress_id`, `sequence_position`
- The `User` and `Model` variants in `IngressSource` directly contradict BC-2.11.001 EC-004 which specifies that model scratch-pad (and by extension User messages not at an ingress boundary) receive NO ProvenanceTag.

**GuardrailHook** (entity vs interface-definitions.md v2.12):
- Entity: `action_fn: Fn(Content, ProvenanceTag) → GuardrailAction` with `GuardrailAction` variants `Accept, Reject(reason: String), Redact(sanitized: Content)`
- BC-authoritative (from BC-2.11.002 PC1–PC4 + interface-definitions.md v2.12): `evaluate(content: IngressContent, provenance_tag: ProvenanceTag) → GuardrailResult` with variants `Pass`, `Fail{reason, severity: GuardrailSeverity}`, `Transform{new_content: IngressContent}`
- `GuardrailAction` / `Accept` / `Reject` / `Redact` are completely retired by pass-57 F-P57-01 in interface-definitions.md but the entities-server.md entity was not updated.

**Fix required:** Rewrite `entities-server.md` §ProvenanceTag and §GuardrailHook to the BC-authoritative shapes. Retire `IngressSource`, `GuardrailAction`, `Accept`, `Reject`, `Redact` from all spec files. Also fix `ubiquitous-language-server.md` which still uses the retired Accept/Reject/Redact terminology.

---

## OBS-P58-1 [process-gap]: No Corpus Census for Types in Public Rust Trait Signatures

**Observation:** There is no standing gate that resolves every type named in the §Public Rust Trait Signatures block (params, returns, enum fields) to a definition site in the corpus. F-P58-01 and F-P58-02 are both instances of the same gap: a type name in a trait signature that has no corpus definition. Pass-57 created the pattern by removing `GuardrailError` (correct) but did not fill the obligation with `IngressContent`/`GuardrailSeverity` definitions (omission).

**Proposed gate #31:** After any edit to §Public Rust Trait Signatures, run a type-resolution census: extract every concrete type identifier (non-generic-parameter, non-external) and verify it has a definition site (inline in the section, entities shard, or a BC). Add to bc-authoring-plan.md.

---

## Sibling Checks

1. **GuardrailHook block semantics coherent** — evaluate method name, GuardrailResult variants, Critical run-failed rule, panic path and E-CORE-007 reference: **FAIL** on F-P58-01 (GuardrailSeverity undefined) and F-P58-02 (IngressContent undefined). Semantics are internally consistent but both types are undefined.
2. **Zero live on_ingress / GuardrailError references** in non-changelog spec files: **PASS** (confirmed via grep — only changelog entries reference these retired names).
3. **Trait-signature type census**: **FAIL** — GuardrailHook block only (root of findings F-P58-01 and F-P58-02).

## Censuses

Gates #13, #21, #23, #26, #27, #30: **PASS**. Gate #29 (supplement-vs-BC seam): **PASS** — GuardrailHook block additions are definitional, not behavioral claims. Gate #28 (version-changelog integrity): not triggered by this pass. Gate #19 (retired-identifier): **FAIL** on entities-server.md (IngressSource/GuardrailAction live). Proposed gate #31 (trait-signature type-resolution): **FAIL** (motivating instance for gate creation).

## Probes

- **(a) GuardrailSeverity semantics coherent, type undefined:** CONFIRMED — BC-2.11.002 INV-3 and BC-2.11.005 PC4/PC5 fully specify the 4-value ladder; the type is semantically unambiguous but has no definition site.
- **(b) IngressContent undefined:** CONFIRMED — 3 live references in interface-definitions.md, zero definition sites in corpus.
- **(c) domain-entity ↔ BC ss-11 coherence:** FAIL — ProvenanceTag field set and GuardrailHook callable shape both contradict BC-authoritative shapes.
