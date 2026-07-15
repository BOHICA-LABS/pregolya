---
document_type: adversarial-review
pass: 57
verdict: NOT_CLEAN
novelty: MEDIUM
finding_count: 1
high_count: 1
medium_count: 0
low_count: 0
timestamp: 2026-07-15T00:00:00Z
scope: prd-supplements, behavioral-contracts
---

# Adversarial Review — Pass 57

**Verdict:** NOT CLEAN — 1 finding (HIGH). Novelty MEDIUM.

---

## F-P57-01 (HIGH): GuardrailHook Trait Signature Trilateral Contradiction

**Location:** `.factory/specs/prd-supplements/interface-definitions.md` §Public Rust Trait
Signatures, lines 132–144.

**Finding:** `interface-definitions.md` §Public Rust Trait Signatures declares:

```rust
async fn on_ingress(&self, content: IngressContent, provenance: ProvenanceTag)
    -> Result<IngressContent, GuardrailError>;
```

with doc-comment "Returns Ok(content) to pass, Ok(replacement) to redact, Err to reject."

ALL SIX ss-11 BC bodies (BC-2.11.001 through BC-2.11.006) uniformly specify:

```
GuardrailHook::evaluate(content_block, provenance_tag) → GuardrailResult::{Pass, Fail{reason,severity}, Transform{new_content}}
```

with panic path `Err(FerrochainError { category: INTERNAL, code: E-CORE-007 })` (fail-closed
semantics confirmed in BC-2.11.002 EC-001, BC-2.11.003 EC-004, BC-2.11.004 EC-004). The
pass-56 E-CORE-007 taxonomy entry also hard-codes `GuardrailHook::evaluate` as the method name.

Three distinct contradictions:

| Axis | interface-definitions.md | BC authority (6-way uniform) |
|------|--------------------------|------------------------------|
| Method name | `on_ingress` | `evaluate` |
| Return type | `Result<IngressContent, GuardrailError>` | `GuardrailResult` enum (Pass / Fail / Transform) |
| Error type | `GuardrailError` (from return type) | `FerrochainError { INTERNAL, E-CORE-007 }` (from panic path — not from return type) |

`on_ingress` appears ONLY at `interface-definitions.md:136` — it is absent from every BC body.
`GuardrailError` as a type is not defined anywhere in the spec corpus.

**Authority resolution (D18-P47-A authority-deference):** The BCs (6-way uniform consensus)
and the error taxonomy (E-CORE-007 message cites `GuardrailHook::evaluate`) outweigh
`interface-definitions.md`. Fix target: `interface-definitions.md`.

**Not covered by the "guardrail split" non-defect:** The pass-56 guardrail split observation
concerned BC decomposition across boundary types — a structural matter. This finding is about
the trait method shape itself (name, return type, error type) — a different and incompatible
public API surface.

---

## Sibling Checks — ALL PASS

**Sibling 1 — New taxonomy row coherence (4 new codes from pass-56):**
E-PROV-008 (TRANSPORT), E-CHKPT-007 (INTERNAL), E-CORE-007 (INTERNAL) plus E-CORE-006
(INTERNAL) from pass-56 completion: all four pass category-severity-exit-code internal
consistency. None creates a new category; all fit within established namespaces. No divergence
registry conflicts. **PASS.**

**Sibling 2 — Disposition census (79 = 45 + 11 + 23):**
Independent recount: 45 HTTP table rows (verified by counting E-* codes in the HTTP status
table), 11 individual omission notes (E-CORE-006, E-CORE-007, E-CHKPT-005, E-SERVER-013,
E-GRAPH-016, E-GRAPH-001, E-GRAPH-014, E-PROV-007, E-RETRY-004, E-CORE-006 recursion note,
E-GRAPH-017 embedded), 23 blanket library-layer codes (E-MCP-*, E-SBXD-*, E-RETRY-* base,
E-BUDGET-*, E-MEMORY-*, E-SPLIT-*). Total 79. Zero uncovered. Gate #28 **PASS.**

**Sibling 3 — Gate #30 TBD census (zero genuine hits):**
Full scan of behavioral-contracts/ss-11/*.md and prd-supplements/error-taxonomy.md for
TBD-* or codeless `category: INTERNAL` constructions — zero remaining. All pass-56
mints resolved. Gate #30 **PASS.**

**Sibling 4 — Wired sites hold:**
All six BC-2.11 bodies use `evaluate` consistently; error taxonomy E-CORE-007 cites
`GuardrailHook::evaluate`; BC changelogs correctly reference pass-4 `GuardrailError` → INTERNAL
correction. No wired reference inconsistency. **PASS.**

**Sibling 5 — Gate #28 changelog audit (14 unique BCs):**
OBS-P57-1 (briefing imprecision): the pass-56 burst changelogged 14 unique BCs (BC-2.11.002,
BC-2.11.003, BC-2.11.004 — E-CORE-007 mint; BC-2.08.002 — E-CORE-005 mint; BC-2.01.003 — 
E-CORE-006 mint; BC-2.04.007 — E-CHKPT-007 mint; BC-2.08.004 — E-PROV-008 mint; BC-2.04.001
through BC-2.04.006 — scope confirmation; BC-2.12.003 — run-config merge precedence note;
BC-2.08.005 — token accounting update), for a total of 14 BC files touched. The gate #28
briefing said "12 unique BCs" — this is an imprecision. All 14 are changelogged with
version-and-burst citations. Gate #28 **PASS (14/14 changelogged).**

---

## Free Probes

**(a) New-row constructibility (Sibling Census #16):**
All 4 pass-56 new error codes have fully derivable placeholder values (message format uses
`<boundary>` and `<content_type>` for E-CORE-007; `<path>` for E-CHKPT-007;
`<status_code>`/`<body_preview>` for E-PROV-008; `<depth>` for E-CORE-006). Note:
E-PROV-008 `TRANSPORT-for-opaque-400` is documented-intentional (non-HTTP-5xx can still be
opaque transport errors from the SDK perspective). No near-collisions with existing codes.
Census **PASS.**

**(b) E-CORE-005 fallback audit (Census #22):**
All 6 usage sites of E-CORE-005 (ValidationFailed) fit the generic field-validation template:
construction-time guard on `bind_tools`, structured-output schema validation, recursion-limit
integer bounds, and config field type checks. No usage site requires a more specific code.
**PASS.**

**(c) NEW LENS — Trait-signature ↔ BC coherence:**
- `Runnable<Input, Output>`: `invoke`/`stream`/`batch`/`pipe` match BC-2.01.003 PC1-PC4
  (invoke returns `Result<Output, FerrochainError>`; stream returns `Result<impl Stream<...>,
  FerrochainError>`; batch returns `Result<Vec<...>, FerrochainError>`). **PASS.**
- `CheckpointSaver`: `put_writes`/`get_tuple`/`list` match BC-2.04.001-BC-2.04.003
  (put returns `Result<(), FerrochainError>`, get returns `Result<Option<CheckpointTuple>,
  FerrochainError>`, list returns stream). **PASS.**
- `BudgetPolicy`: `evaluate` returns `BudgetDecision { Allow / Escalate / Deny }` —
  matches BC-2.10.001 PC1-PC3. **PASS.**
- `BaseChatModel`: `stream_chat` (BC-2.08.001 streaming conformance), `bind_tools` returning
  `impl BaseChatModel` (BC-2.08.002 PC1), `with_structured_output` (BC-2.08.003 PC1).
  `model_name()` is an introspective getter not specifically constrained by a BC but consistent
  with the provider capability profile required by BC-2.08.001 PC2. **PLAUSIBLE MATCH.**
- `GuardrailHook`: **F-P57-01 — see above.**

MemoryStore, Sandbox (SandboxBackend), Tool/MCP, and Retry traits are **not declared** in
§Public Rust Trait Signatures — they appear only in error taxonomy and config schema sections.
No trait signature contradiction possible at this layer; architectural trait shapes are
architect-owned.

---

## Novelty Assessment

**MEDIUM.** The method name divergence (`on_ingress` vs `evaluate`) has been latent since the
initial BC authoring burst (burst 72). It was not previously surfaced because earlier adversary
passes focused on error categories, taxonomy completeness, and pagination. The E-CORE-007 mint
in pass-56 made the contradiction load-bearing: the taxonomy entry now explicitly cites
`GuardrailHook::evaluate` as the canonical method name, creating a three-way cross-document
conflict that was previously only a two-way (BC vs interface-definitions) mismatch.
