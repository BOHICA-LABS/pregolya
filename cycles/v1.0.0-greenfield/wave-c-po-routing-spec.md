---
document_type: cycle-document
level: ops
artifact_subtype: po-routing-spec
version: "1.0"
status: active
producer: architect
timestamp: 2026-07-28T00:00:00Z
cycle: v1.0.0-greenfield
traces_to: STATE.md
burst: 277
changelog:
  - "1.0 (FIX-BURST-277-WAVE-B/2026-07-28): Initial Wave C product-owner routing obligations from fix-burst 277 architect adjudications. Three BC groups: (A) BC-2.20.003 body corrections for VectorStoreRetriever lifetime removal per ADR-014 Decision 2; (B) BC-2.09.001 DynTool migration per ADR-005 §Adjacent Adjudications; (C) BC-2.09.002 DynTool migration."
---

# Wave C Product-Owner Routing Spec — Fix-Burst 277

Precise copy-pasteable replacement text for BC body corrections outside architect scope
(BC body / AC / Description / Postconditions / Invariants / Edge Cases).
Route each group to the product-owner for amendment.

Authority: ADR-014 Decision 2 (VectorStoreRetriever lifetime), ADR-005 §Adjacent Trait
Object-Safety Adjudications (DynTool migration).

---

## Group A: BC-2.20.003 — VectorStoreRetriever Body Corrections

**Reason:** ADR-014 Decision 2 changed `VectorStoreRetriever<'a>` (with `store: &'a dyn VectorStore`) to `VectorStoreRetriever` (with `store: Arc<dyn VectorStore>`, no lifetime). `as_retriever` became fallible: `fn as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>`. The BC-2.20.003 body still describes the old lifetime-bound design.

**BC:** BC-2.20.003 (current version: 1.3)
**Version after PO amendment:** 1.4

### A1 — Description

Replace:

```
`VectorStoreRetriever<'a>` is a concrete `Retriever` implementation in
`ferrochain-vectorstores: vectorstores::retriever` that wraps a `&'a dyn VectorStore` and
dispatches `get_relevant_documents` to the appropriate VectorStore search method based on
`SearchType`. It is constructed via `VectorStore::as_retriever(&self) → VectorStoreRetriever<'_>`,
a concrete (non-opaque) return type that preserves `VectorStore`'s dyn-compatibility (E0038-safe
per ADR-014). The retriever is configured with `k` (final result count), `fetch_k` (MMR
candidate pool size), and `lambda_mult` (MMR diversity weight).
```

With:

```
`VectorStoreRetriever` is a concrete `Retriever` implementation in
`ferrochain-vectorstores: vectorstores::retriever` that owns an `Arc<dyn VectorStore>` and
dispatches `get_relevant_documents` to the appropriate VectorStore search method based on
`SearchType`. It is constructed via `VectorStore::as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>`,
a concrete (non-opaque) fallible constructor that validates configuration before constructing
and returns `Err(E-VS-003)` on invalid config (ADR-014 Decision 2). The retriever is configured
with `k` (final result count), `fetch_k` (MMR candidate pool size), and `lambda_mult` (MMR
diversity weight). `VectorStoreRetriever` has no lifetime parameter; the `Arc<dyn VectorStore>`
internal field allows `VectorStoreRetriever` to satisfy `Retriever + 'static`, enabling
`Arc<dyn Retriever>` coercion.
```

### A2 — Preconditions (PC2, PC3, PC4)

Replace:

```
2. `VectorStore::as_retriever(&self)` is called on the store, returning a `VectorStoreRetriever<'_>`.
3. The caller configures `search_type`, `k`, `fetch_k`, and `lambda_mult` (defaults apply
   if not explicitly set: `SearchType::Similarity`, `k=4`, `fetch_k=20`, `lambda_mult=0.5`).
4. The `VectorStoreRetriever<'_>` is coerced to `Arc<dyn Retriever>` by wrapping in `Arc::new`.
```

With:

```
2. `VectorStore::as_retriever(self: &Arc<Self>)` is called on an `Arc<dyn VectorStore>`,
   returning `Ok(VectorStoreRetriever)` on valid config or `Err(E-VS-003)` on invalid config
   (ADR-014 Decision 2).
3. The caller configures `search_type`, `k`, `fetch_k`, and `lambda_mult` (defaults apply
   if not explicitly set: `SearchType::Similarity`, `k=4`, `fetch_k=20`, `lambda_mult=0.5`).
4. The `VectorStoreRetriever` (no lifetime parameter) is coerced to `Arc<dyn Retriever>` by
   wrapping in `Arc::new`; this coercion succeeds because `VectorStoreRetriever: Retriever + 'static`.
```

### A3 — Postconditions (PC5)

Replace:

```
5. `VectorStore::as_retriever(&self) → VectorStoreRetriever<'_>` is a concrete (non-opaque) return.
   This is NOT `async fn`, NOT `impl Retriever` — it returns the concrete named type, preserving
   `VectorStore`'s dyn-compatibility (E0038-safe).
```

With:

```
5. `VectorStore::as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>`
   is a concrete (non-opaque) fallible return — NOT `async fn`, NOT `impl Retriever`. Returns the
   concrete named type `VectorStoreRetriever` (no lifetime parameter). `VectorStore` trait remains
   object-safe; `as_retriever` takes `self: &Arc<Self>` to provide access to the `Arc` needed for
   internal `Arc<dyn VectorStore>` storage (ADR-014 Decision 2). Returns `Err(E-VS-003)` on invalid
   config.
```

### A4 — Invariants (Invariant 5)

Replace:

```
5. `VectorStoreRetriever<'_>` borrows the store with lifetime `'a`; it CANNOT outlive the store it
   wraps (lifetime-safe — the borrow checker enforces this statically).
```

With:

```
5. `VectorStoreRetriever` owns its store via `Arc<dyn VectorStore>`; it is `'static` (no lifetime
   parameter). The `Arc` reference count keeps the store alive for the retriever's lifetime — no
   borrow-checker lifetime constraint applies (ADR-014 Decision 2). `Arc<dyn Retriever>` coercion
   succeeds without a lifetime-bound error.
```

### A5 — Edge Cases (EC-006)

Replace:

```
| EC-006 | `as_retriever()` called on a store via `Arc<dyn VectorStore>` | Returns `VectorStoreRetriever<'_>` with lifetime tied to the deref of the Arc; caller holds the Arc for the retriever's lifetime |
```

With:

```
| EC-006 | `as_retriever(self: &Arc<Self>)` called on an `Arc<dyn VectorStore>` with valid config | Returns `Ok(VectorStoreRetriever)` (no lifetime parameter); retriever owns a clone of the `Arc<dyn VectorStore>`; caller may drop the original `Arc` after construction |
```

**Changelog entry for 1.4 (PO to author):**

```
"1.4 (Wave-C/ADR-014-Decision-2-body/2026-07-28): BC body aligned with ADR-014 Decision 2 VectorStoreRetriever lifetime removal. (1) Description: VectorStoreRetriever<'a>/&'a dyn VectorStore removed; as_retriever fallible fn as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>; Err(E-VS-003) on invalid config. (2) PC2: as_retriever(&self) -> as_retriever(self: &Arc<Self>); infallible -> fallible. (3) PC3: VectorStoreRetriever<'_> -> VectorStoreRetriever. (4) PC4: coercion succeeds because Retriever + 'static. (5) PC5: updated to fallible signature; E0038-safe framing removed (issue was lifetime, not object safety). (6) Invariant 5: lifetime-borrow language -> Arc ownership language; 'static coercion documented. (7) EC-006: Ok(VectorStoreRetriever) return; Arc clone semantics."
```

---

## Group B: BC-2.09.001 — DynTool Migration

**Reason:** ADR-005 §Adjacent Trait Object-Safety Adjudications mandates migration of all `Arc<dyn ferrochain_core::Tool>` sites to `Arc<dyn DynTool>`. `dyn Tool` is non-object-safe because `Tool: Runnable<ToolInput, ToolOutput>` inherits `Runnable::stream()` with `impl Stream` return (E0038). `DynTool` is the object-safe seam (definition in interface-definitions.md §DynTool and api-surface.md §Public Rust Traits).

**BC:** BC-2.09.001 (check current version before amending)
**Version after PO amendment:** next minor

### B1 — Description (one replacement)

Replace:

```
`Arc<dyn ferrochain_core::Tool>` whose `args_schema` carries the raw JSON-Schema
`Value` from `tool.inputSchema` verbatim — no schema synthesis.
```

With:

```
`Arc<dyn DynTool>` whose `args_schema` carries the raw JSON-Schema `Value` from
`tool.inputSchema` verbatim — no schema synthesis. (`DynTool` is the object-safe dispatch
seam for tool collections; direct `dyn Tool` is non-object-safe per ADR-005 §Adjacent
Trait Object-Safety Adjudications.)
```

### B2 — Postconditions PC2 (one replacement)

Replace:

```
2. Each `rmcp::model::Tool` from the server is converted into
   `Arc<dyn ferrochain_core::Tool>` via `convert_mcp_tool`.
```

With:

```
2. Each `rmcp::model::Tool` from the server is converted into
   `Arc<dyn DynTool>` via `convert_mcp_tool`. (`DynTool` is the object-safe dispatch
   seam per ADR-005 §Adjacent Trait Object-Safety Adjudications; `convert_mcp_tool`
   returns `Arc<dyn DynTool>`.)
```

**Changelog entry (PO to author):**

```
"<next-version> (Wave-C/ADR-005-DynTool/2026-07-28): BC-2.09.001 Description + PC2: migrate Arc<dyn ferrochain_core::Tool> -> Arc<dyn DynTool> per ADR-005 §Adjacent Trait Object-Safety Adjudications (dyn Tool is non-object-safe; DynTool is the object-safe seam; blanket impl auto-implements DynTool for T: Tool + Send + Sync + 'static; definition in interface-definitions.md §DynTool)."
```

---

## Group C: BC-2.09.002 — DynTool Migration

**Reason:** Same as Group B. BC-2.09.002 PC1 cites `Arc<dyn ferrochain_core::Tool>` as the input type produced by `convert_mcp_tool`.

**BC:** BC-2.09.002 (check current version before amending)
**Version after PO amendment:** next minor

### C1 — Preconditions PC1 (one replacement)

Replace:

```
1. A `Arc<dyn ferrochain_core::Tool>` was produced by `convert_mcp_tool`
   (see BC-2.09.001), carrying a `SessionSource` referencing the target MCP server.
```

With:

```
1. A `Arc<dyn DynTool>` was produced by `convert_mcp_tool` (see BC-2.09.001),
   carrying a `SessionSource` referencing the target MCP server. (`DynTool` is the
   object-safe dispatch seam per ADR-005 §Adjacent Trait Object-Safety Adjudications;
   direct `dyn ferrochain_core::Tool` is non-object-safe and may not be used as a
   trait object.)
```

**Changelog entry (PO to author):**

```
"<next-version> (Wave-C/ADR-005-DynTool/2026-07-28): BC-2.09.002 PC1: migrate Arc<dyn ferrochain_core::Tool> -> Arc<dyn DynTool> per ADR-005 §Adjacent Trait Object-Safety Adjudications. Authority: ADR-005 §Adjacent Adjudications, interface-definitions.md §DynTool."
```

---

## Summary

| Group | BC | Section | Change | Authority |
|-------|----|---------|--------|-----------|
| A1 | BC-2.20.003 | Description | `VectorStoreRetriever<'a>`/`&'a dyn VectorStore` → `VectorStoreRetriever`/`Arc<dyn VectorStore>`; `as_retriever` fallible | ADR-014 Decision 2 |
| A2 | BC-2.20.003 | Preconditions PC2/PC3/PC4 | `as_retriever` fallible receiver; remove lifetime annotations; `'static` coercion | ADR-014 Decision 2 |
| A3 | BC-2.20.003 | Postconditions PC5 | Fallible signature; remove E0038-safe framing | ADR-014 Decision 2 |
| A4 | BC-2.20.003 | Invariants 5 | Lifetime-borrow language → Arc ownership; `'static` documented | ADR-014 Decision 2 |
| A5 | BC-2.20.003 | EC-006 | `Ok(VectorStoreRetriever)` return; Arc clone semantics | ADR-014 Decision 2 |
| B1 | BC-2.09.001 | Description | `Arc<dyn ferrochain_core::Tool>` → `Arc<dyn DynTool>` | ADR-005 §Adjacent Adjudications |
| B2 | BC-2.09.001 | Postconditions PC2 | `Arc<dyn ferrochain_core::Tool>` → `Arc<dyn DynTool>` | ADR-005 §Adjacent Adjudications |
| C1 | BC-2.09.002 | Preconditions PC1 | `Arc<dyn ferrochain_core::Tool>` → `Arc<dyn DynTool>` | ADR-005 §Adjacent Adjudications |
