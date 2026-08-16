---
document_type: adr
level: L3
adr_id: "025"
slug: type-signature-canon
title: "Type Signature Canon: Object Safety and Arc Ownership Patterns (D-43, D-45, D-48)"
status: accepted
producer: architect
timestamp: 2026-08-01T00:00:00Z
date: "2026-08-01"
subsystems_affected: ["all"]
supersedes: []
superseded_by: null
version: "1.2"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D43, D45, D48]
changelog:
  - "1.2 (burst-288/F-P177-LOW-date/2026-08-15): Add missing frontmatter fields (date, subsystems_affected, superseded_by); add Alternatives Considered section per ADR template (LOW finding: date boundary conditions)."
  - "1.1 (fix-burst-287/illustration-markers/2026-08-01): Add discriminator:illustration-start/end markers around all prohibited-form examples, problem descriptions, and validator prose in each decision section. The ADR documents the prohibition by naming the prohibited forms; the markers exempt these illustrative regions from verify-signature-canon.sh scan so the scanner enforces normative signatures only. Content unchanged; no new decisions."
  - "1.0 (fix-burst-287/canon-inversion/2026-08-01): Initial decision — promote D-43 (DynTool), D-45 (VectorStoreRetriever no lifetime), and D-48 (as_retriever receiver + &Arc<Self> prohibition) from shell-script rule comments to ratified ADR headings. Grounds verify-signature-canon.sh rules S2, S3, S4 in citable architectural authority. `§Type Signature Canon` policy citations (POL-18 D-43/D-45/D-48 entries) can now be repointed from `adopted: [UNGOVERNED]` to these headings. Source: fix-burst-287 coordinator message identifying governance inversion — 'the validator has become the source of canon rather than an enforcer of it.'"
---

# ADR-025: Type Signature Canon — Object Safety and Arc Ownership Patterns

**Status:** Accepted — fix-burst-287 governance correction. Grounds D-43/D-45/D-48 canonical
forms in a citable ADR, enabling `verify-signature-canon.sh` to enforce this ADR rather than
define it.

---

## Context

Three adjudicated decisions govern Rust type-signature forms in the pregolya codebase:

<!-- discriminator:illustration-start -->
- **D-43** (FIX-BURST-277): `Arc<dyn Tool>` is E0038 non-object-safe; canonical form is
  `Arc<dyn DynTool>`.
- **D-45** (FIX-BURST-277): `VectorStoreRetriever` must have no lifetime parameter; it owns
  `Arc<dyn VectorStore>` and must be `'static`.
- **D-48** (FIX-BURST-277): `as_retriever` method receiver must be `self: Arc<Self>`; related
  `&Arc<Self>` receiver pattern is a standing project-wide hazard.
<!-- discriminator:illustration-end -->

These three decisions were adjudicated at the time of FIX-BURST-277 but were recorded ONLY as
inline rule comments in `hooks/verify-signature-canon.sh` (rules S2, S3, S4). No ADR heading
existed. The hook cited "D-43", "D-45", "D-48" in its CANON TABLE but had no document to
enforce — the script defined the canon it was supposed to certify.

This is the same family of defect as the Mechanism 3 class in P1D-176: a gate that satisfies
itself by internal identity rather than by checking an external ground truth. A rule that lives
only in the script that checks it: (a) is unreviewable outside the script context, (b) cannot
be cited by a BC or a story, (c) changes silently when someone edits the regex, and (d) is
circular by construction.

This ADR provides the canonical-form definitions as real markdown headings, grounded in what
`verify-signature-canon.sh` rules S2, S3, S4 actually assert (read verbatim from the CANON
TABLE in the hook). Where the hook's comment and any existing prose disagree, this ADR
adjudicates and states which won.

---

## Decision

Ratify three canonical type-signature forms as ADR headings, grounding `verify-signature-canon.sh` rules S2, S3, S4 in this ADR:

1. **D-43 — DynTool dispatch:** `Arc<dyn DynTool + Send + Sync>` is the canonical form; `Arc<dyn Tool>` is E0038 (not object-safe) and prohibited.
<!-- discriminator:illustration-start -->
2. **D-45 — VectorStoreRetriever:** The canonical trait has no lifetime parameter; `VectorStoreRetriever<'_>` in any signature is prohibited.
3. **D-48 — `as_retriever` receiver and `&Arc<Self>` standing prohibition:** `fn as_retriever(self: Arc<Self>) -> Arc<dyn VectorStoreRetriever + Send + Sync>` is canonical; `&self` and `&Arc<Self>` receivers are prohibited for `as_retriever` and for any future `Arc<Self>` dispatch method.
<!-- discriminator:illustration-end -->

---

## DynTool: Canonical Object-Safe Tool Dispatch Form (D-43)

**Rule origin:** verify-signature-canon.sh S4, citing D-43.

<!-- discriminator:illustration-start -->
**Problem:** `Tool` inherits two non-dyn-compatible members from `Runnable`:
- `stream()` — returns `impl Stream` (opaque return type, non-dyn-compatible)
- `pipe()` — has `where Self: Sized` bound (explicitly excludes `dyn T`)

These characteristics make `dyn Tool` non-object-safe (E0038 fires on `Arc<dyn Tool>`).
The project encountered E0038 from `Arc<dyn Tool>` in FIX-BURST-277; a second E0038 from
`Arc<dyn VectorStore>` driven by `&Arc<Self>` receivers was found simultaneously (D-48).
<!-- discriminator:illustration-end -->

**Canonical form:**

```
Arc<dyn DynTool>
```

`DynTool` is the object-safe façade for tool dispatch. It exposes `invoke_dyn` and the four
tool-metadata accessors that ARE dyn-compatible. Blanket implementation:
`T: Tool + Send + Sync + 'static` auto-implements `DynTool`. Callers holding `Arc<dyn DynTool>`
can dispatch uniformly without knowing the concrete type; `Arc<dyn Tool>` (non-object-safe, E0038) cannot.

<!-- discriminator:illustration-start -->
**Prohibited forms:**

| Form | Why prohibited |
|------|---------------|
| `Arc<dyn Tool>` | E0038 — `dyn Tool` is non-object-safe |
| `dyn pregolya_core::Tool` | E0038 — fully-qualified form of the same violation |

**Validator (S4):** `verify-signature-canon.sh` FAILS on any line containing `Arc<dyn Tool>` or
`dyn pregolya_core::Tool` that does NOT also contain one of the hazard words: `non-object-safe`,
`E0038`, `not dyn compatible`, `dyn-incompatible`, `NOT object-safe`, `non_exhaustive`. Lines
naming the hazard are descriptive (documenting the prohibited form); lines without hazard words
are normative (endorsing it).
<!-- discriminator:illustration-end -->

**Module:** `pregolya-core` — `core::tool`.

---

## VectorStoreRetriever: No Lifetime Parameter (D-45)

**Rule origin:** verify-signature-canon.sh S2, citing D-48/D-45.

<!-- discriminator:illustration-start -->
**Problem:** An early `VectorStoreRetriever<'a>` design held `&'a dyn VectorStore` (a borrowed
reference). This means:
1. `Arc<dyn Retriever>` coercion fails — `VectorStoreRetriever<'_>` is not `'static`,
   so `Arc<dyn Retriever + 'static>` cannot be formed.
2. The retriever cannot survive `tokio::spawn`, which requires `'static` bounds on futures.
<!-- discriminator:illustration-end -->

**Canonical form:**

```
VectorStoreRetriever
```

`VectorStoreRetriever` (no angle bracket) owns `store: Arc<dyn VectorStore>` and is `'static`.
`Arc<dyn Retriever>` coercion succeeds. The retriever can be sent across thread boundaries and
stored in `tokio::spawn` futures.

<!-- discriminator:illustration-start -->
**Prohibited forms:**

| Form | Why prohibited |
|------|---------------|
| `VectorStoreRetriever<'a>` | Lifetime parameter makes type non-`'static` |
| `VectorStoreRetriever<T>` | Any angle-bracket suffix breaks the ownership invariant |

**Validator (S2):** `verify-signature-canon.sh` FAILS on any line containing
`VectorStoreRetriever<` (any character after the `<`). The match is changelog-exempt: YAML
frontmatter and body `## Changelog` sections are not scanned (historical record exemption per
D-46 design principle in the hook header).
<!-- discriminator:illustration-end -->

**Module:** `pregolya-vectorstores` — `vectorstores::retriever`.

---

## as_retriever Receiver: Arc<Self> Ownership (D-48)

**Rule origin:** verify-signature-canon.sh S1, citing D-48.

<!-- discriminator:illustration-start -->
**Problem:** The `VectorStore` trait includes `fn as_retriever(...)`. Two incorrect receiver
forms were found in the corpus:

- **S1a: `fn as_retriever(self: &Arc<Self>)`** — `&Arc<Self>` is a non-dyn-compatible receiver
  (see `&Arc<Self> Receiver` section below). Makes `VectorStore` non-object-safe (E0038 fires
  at any `Arc<dyn VectorStore>` use site).

- **S1b: `fn as_retriever(&self)`** — `&self` drops the `Arc`. The returned `VectorStoreRetriever`
  needs to own `Arc<dyn VectorStore>` (per D-45) so it can be `'static`. A `&self` receiver
  cannot provide an owned `Arc`; cloning `&self` would require `Self: Clone`, which is not
  required by the `VectorStore` bound.
<!-- discriminator:illustration-end -->

**Canonical form:**

```
fn as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, PregolyaError>
```

`self: Arc<Self>` is an owned Arc receiver. It IS dyn-compatible (arbitrary self types
with `Deref` are dyn-compatible when no other non-dyn-compatible bound applies). It provides
the `Arc<Self>` from which `Arc<dyn VectorStore>` can be constructed for the retriever. The
return type is fallible (`Err(E-VS-003)` on invalid configuration per ADR-014 Decision 2).

<!-- discriminator:illustration-start -->
**Prohibited forms:**

| Form | Why prohibited |
|------|---------------|
| `fn as_retriever(self: &Arc<Self>)` | E0038 — `&Arc<Self>` receiver, non-dyn-compatible |
| `fn as_retriever(&self)` | Drops Arc; retriever cannot own `Arc<dyn VectorStore>` |

**Validator (S1):** `verify-signature-canon.sh` FAILS on S1a (`as_retriever(self: &Arc<Self>)`)
and S1b (`as_retriever(&self)`) outside frontmatter and changelog regions.
<!-- discriminator:illustration-end -->

**Module:** `pregolya-vectorstores` — `vectorstores::vector_store` (VectorStore trait).

---

<!-- discriminator:illustration-start -->
## &Arc<Self> Receiver: Standing Prohibition (D-48 General)

**Rule origin:** verify-signature-canon.sh S3, citing D-48 general.

**Problem:** `&Arc<Self>` as a method receiver compiles on a concrete `impl` but makes any
trait containing that method non-dyn-compatible under E0038. The project was hit by this
twice within the same pass: `Tool` (D-43, `as_retriever` precursor pattern) and `VectorStore`
(D-48). Two E0038 incidents from the same receiver pattern constitute a standing hazard that
warrants a corpus-wide prohibition rather than per-instance adjudication.

**Canonical replacement:** `Arc<Self>` (owned Arc receiver, dyn-compatible).

**Prohibition:** `&Arc<Self>` MUST NOT appear as a method receiver in any `.factory/specs/`
file outside the S3 allowlist.

**Allowlist:** `hooks/signature-canon-allowlist.txt`. Entries require:
- Format: `<path-relative-to-.factory/specs> :: <symbol>`
- Preceding line: `# Reason: <justification>`
- Keyed on (file, symbol) — line-number-independent per TD-VSDD-091.

Allowlist entries are for genuine exceptions (e.g., documenting a prohibited form as a known
hazard for educational purposes). They are NOT for working around the prohibition in normative
signatures.

**Validator (S3):** `verify-signature-canon.sh` FAILS on any line containing `&Arc<Self>`
outside allowlisted files, frontmatter, and changelog regions.
<!-- discriminator:illustration-end -->

**Module:** Project-wide — `core::tool`, `vectorstores::vector_store`, and any future trait
whose methods could take an Arc-owned self.

---

## Rationale

<!-- discriminator:illustration-start -->
All four prohibitions resolve to the same root: Rust's dyn-compatibility rules exclude receiver
types that do not deref to `Self` in ways compatible with vtable dispatch. `Arc<Self>` IS
compatible (arbitrary self types); `&Arc<Self>` IS NOT (double-indirection through non-`Self`
deref chain). The blanket prohibition on `&Arc<Self>` (S3) is stronger than strictly required
by the individual decisions but is justified by the cost of re-encountering E0038 in a new
trait.
<!-- discriminator:illustration-end -->

A dedicated ADR (rather than adding to ADR-010 error taxonomy) is appropriate because:
1. These decisions govern type-level API surface, not error construction or propagation.
2. ADR-010 is the source of truth for `PregolyaError` forms; mixing ownership patterns into
   the error-taxonomy ADR would obscure both topics.
3. `§Type Signature Canon` appeared in policy citations repeatedly because reviewers correctly
   expected this section to exist in a standalone ADR.

---

## Consequences

- `verify-signature-canon.sh` rules S1, S2, S3, S4 now enforce this ADR rather than define it.
  Edits to the hook's regex patterns must be reviewed against the canonical forms here; divergence
  between the hook and this ADR is a hook defect, not a new canonical form.

- **POL-18** entries for D-43 (DynTool), D-45 (VectorStoreRetriever), and D-48 (as_retriever receiver and standing prohibition) can be repointed from `adopted: [UNGOVERNED]` to headings in this ADR.
  Spec-steward routes this repointing; report the exact heading texts:
  <!-- discriminator:illustration-start -->
  - D-43: `§DynTool: Canonical Object-Safe Tool Dispatch Form (D-43)` in `ADR-025`
  - D-45: `§VectorStoreRetriever: No Lifetime Parameter (D-45)` in `ADR-025`
  - D-48 (S1): `§as_retriever Receiver: Arc<Self> Ownership (D-48)` in `ADR-025`
  - D-48 (S3): `§&Arc<Self> Receiver: Standing Prohibition (D-48 General)` in `ADR-025`
  <!-- discriminator:illustration-end -->

<!-- discriminator:illustration-start -->
- Any future trait that introduces `Arc<Self>` dispatch must be reviewed against
  `§&Arc<Self> Receiver: Standing Prohibition` and `§DynTool` before landing.
<!-- discriminator:illustration-end -->

- `BC-2.09.007` §Architecture Anchors and any other BC that describes `Arc<dyn DynTool>` can
  cite `ADR-025 §DynTool` as the governing authority rather than `ADR-005 §Adjacent Trait
  Object-Safety Adjudications`. Both are valid; ADR-025 is the canonical source of truth for
  the DynTool form.

---

## Source / Origin

- **verify-signature-canon.sh** CANON TABLE rules S1, S2, S3, S4 — verbatim source for all
  prohibited-form and canonical-form definitions in this ADR.
- **D-43** (FIX-BURST-277): DynTool adjudication — `Arc<dyn Tool>` is E0038.
- **D-45** (FIX-BURST-277): `VectorStoreRetriever` no lifetime — `Arc<dyn Retriever>` coercion
  requires `'static`.
<!-- discriminator:illustration-start -->
- **D-48** (FIX-BURST-277): `as_retriever` canonical receiver and `&Arc<Self>` standing
  prohibition.
<!-- discriminator:illustration-end -->
- **ADR-005 §Adjacent Trait Object-Safety Adjudications**: Migration routing for Wave C BC
  amendments (BC-2.09.001, BC-2.09.002, BC-2.09.007). ADR-005 carries the migration history;
  ADR-025 carries the forward-going canonical form.
- **ADR-014 Decision 2**: `as_retriever` fallibility — `Err(E-VS-003)` on invalid config.
- **fix-burst-287 coordinator message**: governance-inversion finding — validator was source of
  canon rather than enforcer of it.

## Alternatives Considered

<!-- discriminator:illustration-start -->
| Alternative | Reason Rejected |
|-------------|-----------------|
| Continue encoding canonical forms as shell-script CANON TABLE comments only | Creates a governance inversion: the hook becomes the source of canon rather than an enforcer. Architectural decisions require citable ADR headings that BCs and spec citations can reference. REJECT. |
| D-43: `Box<dyn Tool + Send + Sync>` instead of `Arc<dyn DynTool + Send + Sync>` | `Box` precludes shared ownership across async tasks; `Arc` is required for multi-owner dispatch in Tokio multi-threaded runtime (ADR-001 Alt-B). `DynTool` is needed because `Tool` is not object-safe (generic `run` return type). REJECT. |
| D-45: Keep lifetime parameter on `VectorStoreRetriever<'a>` | Lifetime parameters prevent `dyn VectorStoreRetriever` trait objects from being stored in `Arc` (requires `+ 'static`). Static dispatch coercion requires `'static` lifetime on the trait. REJECT. |
| D-48: `&self` receiver for `as_retriever` | `&self` cannot yield an `Arc<dyn VectorStoreRetriever>` without a `Weak` back-reference or external `Arc` injection — both are non-trivial and error-prone. `self: Arc<Self>` provides the owned `Arc` directly. REJECT. |
<!-- discriminator:illustration-end -->
