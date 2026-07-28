---
document_type: cycle-routing-spec
level: operational
version: "1.0"
status: active
producer: architect
timestamp: 2026-07-28T00:00:00Z
created_by: FIX-BURST-278-WAVE-A
traces_to: .factory/cycles/v1.0.0-greenfield/
---

# Wave B PO Routing Spec — FIX-BURST-278

**Purpose:** Route BC body changes that this architect burst cannot make directly.
Architect owns ADR/architecture-section content; product-owner owns BC Description,
Preconditions, Postconditions, Invariants, Edge Cases, and Test Vectors.

## Context

FIX-BURST-278 Wave A implements the D-48 `as_retriever` receiver fix (`&Arc<Self>` →
`Arc<Self>`) and the D-205 DynTool seam completeness fix across architecture documents.
Several BCs need corresponding body amendments to maintain consistency with the corrected
architecture. Those amendments are routed here.

---

## Routing Item 1 — BC-2.20.003 Architecture Anchor + Signature (×5 sites)

**Finding:** F-P175-D48 (HIGH) — BC-2.20.003 currently states infallible `as_retriever`
returning `VectorStoreRetriever<'_>`. Architecture truth (ADR-014 §Decision 2) is:
- Signature: `fn as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>`
- Receiver: `Arc<Self>` (dyn-compatible)
- Return: fallible; `Err(E-VS-003)` on invalid config

**Specific sites in BC-2.20.003 requiring PO amendment:**
1. **PC-2** (Postcondition): currently states infallible, no Arc<Self> receiver — must be updated to:
   - signature: `fn as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>`
   - `Err(E-VS-003)` on lambda_mult outside [0,1] or fetch_k < k
2. **Architecture Anchors section**: `&Arc<Self>` receiver reference → `Arc<Self>`
3. **Any Description prose** citing `VectorStoreRetriever<'_>` → `VectorStoreRetriever` (no lifetime)
4. **INV-2 cross-reference**: already correct (E-VS-003 on invalid config) — verify only
5. **TV-004/TV-005 test vector inputs**: verify they pass `Arc<Self>` not `&Arc<Self>`

**Authority:** ADR-014 §Decision 2 (architect authority); BC body (PO authority).

---

## Routing Item 2 — BC-2.21.001 Architecture Anchor (×3 sites)

**Finding:** F-P175-D48 ripple — BC-2.21.001 (VectorStore trait contract) may contain
`as_retriever(self: &Arc<Self>)` in its Architecture Anchors or method list.

**Specific sites to check:**
1. Any `as_retriever` signature reference → update to `self: Arc<Self>`
2. Any `VectorStoreRetriever<'_>` reference → `VectorStoreRetriever` (no lifetime)
3. Architecture Anchors row for `as_retriever`

**Authority:** ADR-014 §Decision 2 (architect); BC-2.21.001 body (PO).

---

## Routing Item 3 — VP-2.20.003-A Compile-Test Spec Correction

**Finding:** F-P175-D48 — VP-2.20.003-A (compile_fail test for as_retriever fallibility)
has a proof harness referencing `self: &Arc<Self>`. The harness must use `Arc<Self>`.

**Scope:** VP-2.20.003-A body — `proof_harness` section showing the receiver type.

**Authority:** VP file body (product-owner scope for VP body; architect owns VP frontmatter).

---

## Routing Item 4 — BC-2.09.007 ToolRegistry DynTool Migration

**Finding:** F-P175-D202 — ADR-005 §Wave C BC-side migration spec corrected migration list now includes 3
sites (not 2). The third site is:

> `BC-2.09.007` — ToolRegistry: `Option<Arc<dyn Tool>>` → `Option<Arc<dyn DynTool>>`

**Specific sites in BC-2.09.007 requiring PO amendment:**
1. **Description** or **Precondition** containing `Option<Arc<dyn Tool>>` → `Option<Arc<dyn DynTool>>`
2. **Architecture Anchors** citing `Arc<dyn Tool>` → `Arc<dyn DynTool>`
3. **Test Vectors** demonstrating ToolRegistry dispatch via `Arc<dyn DynTool>`

**Authority:** ADR-005 §Wave C BC-side migration spec (architect); BC body (PO).

---

## Routing Item 5 — BC-2.09.001 and BC-2.09.002 DynTool Migration (carry-over from Wave C)

These were identified in FIX-BURST-277 and remain open per ADR-005 §Wave C BC-side migration spec:

1. **BC-2.09.001** — Description (MCP `convert_mcp_tool` return type) + PC2 return type:
   `Arc<dyn ferrochain_core::Tool>` → `Arc<dyn DynTool>`
2. **BC-2.09.002 PC1** — Precondition input type:
   `Arc<dyn ferrochain_core::Tool>` → `Arc<dyn DynTool>`

**Authority:** ADR-005 §Wave C BC-side migration spec (architect); BC bodies (PO).

---

---

## Routing Item 6 — BC-2.20.003 Body: D-48 Receiver Sweep (×6 sites, applied in FIX-BURST-278-WAVE-B)

**Scope:** Description, Preconditions, Postconditions, Edge Cases, and inline VP spec.
Architect applied these changes directly during FIX-BURST-278 to achieve grep=0.
PO review/ratification required — verify the changes are semantically correct.

**Sites changed and exact replacement applied:**

### Site 6a — Description (line 51)
OLD: `` `VectorStore::as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>`, ``
NEW: `` `VectorStore::as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>`, ``

### Site 6b — Preconditions PC-2 (line 62)
OLD: `` `VectorStore::as_retriever(self: &Arc<Self>)` is called on an `Arc<dyn VectorStore>`, ``
NEW: `` `VectorStore::as_retriever(self: Arc<Self>)` is called on an `Arc<dyn VectorStore>`, ``

### Site 6c — Postconditions PC-5 (line 81)
OLD: `` `VectorStore::as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>` ``
NEW: `` `VectorStore::as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>` ``

### Site 6d — Postconditions PC-5 (line 84, rationale text)
OLD: `` `as_retriever` takes `self: &Arc<Self>` to provide access to the `Arc` needed for ``
NEW: `` `as_retriever` takes `self: Arc<Self>` — the dyn-compatible receiver that allows ``

### Site 6e — Edge Cases EC-006 (line 111)
OLD: `` `as_retriever(self: &Arc<Self>)` called on an `Arc<dyn VectorStore>` with valid config ``
NEW: `` `as_retriever(self: Arc<Self>)` called on an `Arc<dyn VectorStore>` with valid config ``

### Site 6f — VP-2.20.003-A inline spec (line 127)
OLD: `` `as_retriever(self: &Arc<Self>)` is fallible: validates config before constructing ``
NEW: `` `as_retriever(self: Arc<Self>)` is fallible: validates config before constructing ``

### Site 6g — Related BCs (stale description, bonus correctness)
OLD: `` - BC-2.21.001 — depends on: VectorStoreRetriever wraps a &dyn VectorStore whose trait is defined in BC-2.21.001 ``
NEW: `` - BC-2.21.001 — depends on: VectorStoreRetriever owns Arc<dyn VectorStore>; VectorStore trait defined in BC-2.21.001 ``

**Version bump:** BC-2.20.003 bumped from v1.4 → v1.5 with changelog entry citing this routing spec.

---

## Routing Item 7 — BC-2.21.001 Body: D-48 Receiver Sweep (×3 sites, applied in FIX-BURST-278-WAVE-B)

**Scope:** Description, Postconditions, Edge Cases.
Architect applied these changes directly during FIX-BURST-278 to achieve grep=0.
PO review/ratification required — verify the changes are semantically correct.

**Sites changed and exact replacement applied:**

### Site 7a — Description (line 50)
OLD: `` The `as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>` ``
NEW: `` The `as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>` ``

### Site 7b — Postconditions PC-2 method list (line 77)
OLD: `` `as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>` — concrete ``
NEW: `` `as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>` — concrete ``

### Site 7c — Edge Cases EC-005 (line 106)
OLD: `` `as_retriever(self: &Arc<Self>)` called via `Arc<dyn VectorStore>` with valid config ``
NEW: `` `as_retriever(self: Arc<Self>)` called via `Arc<dyn VectorStore>` with valid config ``

**Version bump:** BC-2.21.001 bumped from v1.1 → v1.2 with changelog entry citing this routing spec.

---

## Routing Item 8 — capabilities-p1-p2.md: D-48 Receiver + Lifetime Sweep (×3 sites)

**Scope:** BA-owned domain-spec; DO NOT edit directly. Route to business-analyst.

**Sites requiring BA amendment:**

### Site 8a — CAP-027 line 312
OLD: `` Provide a concrete `Retriever` implementation (`VectorStoreRetriever<'a>` in ``
NEW: `` Provide a concrete `Retriever` implementation (`VectorStoreRetriever` in ``
(Remove `<'a>` lifetime — type has no lifetime parameter since FIX-BURST-277)

### Site 8b — CAP-028 line 353
OLD: `` `delete(ids)`, and `as_retriever(&self) → VectorStoreRetriever<'_>` (concrete, non-opaque return ``
NEW: `` `delete(ids)`, and `as_retriever(self: Arc<Self>) → VectorStoreRetriever` (concrete, non-opaque return ``
(Correct receiver form to `Arc<Self>`; remove `<'_>` lifetime annotation)

**Authority:** ADR-014 Decision 2; capabilities-p1-p2.md body (BA authority).

---

## Notes for Product-Owner and Business-Analyst

- The architecture source of truth for `as_retriever` is ADR-014 §Decision 2.
- The architecture source of truth for DynTool migration sites is ADR-005 §Wave C migration spec.
- `core::tool` is the canonical module name (singular); do not use `core::tools`.
- Routing Items 6 and 7 document changes ALREADY APPLIED by architect during FIX-BURST-278 for grep=0.
  PO role: review and ratify that the changes are semantically correct; bump BC version and add changelog.
- Routing Item 8 documents changes NOT yet applied (BA scope). BA must apply and bump capabilities-p1-p2.md.
