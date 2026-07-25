---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
traces_to: STATE.md
phase: 1d
pass: 18
verdict: NOT CLEAN
timestamp: 2026-07-14T00:00:00Z
producer: product-owner
scope: "Shared-type identifier census (gate #19 inception); BC CheckpointSaver/RunnableConfig fix pass; sibling censuses PASS"
inputs:
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.001.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.002.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.003.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.004.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.004.md
  - .factory/specs/behavioral-contracts/ss-12/BC-2.12.007.md
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.002.md
  - .factory/specs/behavioral-contracts/ss-15/BC-2.15.003.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.002.md
  - .factory/specs/behavioral-contracts/ss-02/BC-2.02.001.md
  - .factory/specs/behavioral-contracts/BC-INDEX.md
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/specs/prd-supplements/bc-authoring-plan.md
  - .factory/specs/domain-spec/ubiquitous-language-server.md
input-hash: "79b0c56"
findings:
  - id: F-P18-01
    severity: HIGH
    status: FIXED
    class: shared-type identifier — layer-correlated split (new class, gate #19 seeded)
  - id: F-P18-02
    severity: MEDIUM
    status: OPEN
    scope: interface-definitions.md (architect scope — not fixed in this pass)
  - id: F-P18-03
    severity: MEDIUM
    status: OPEN
    scope: ubiquitous-language nonexistent ContentBlock::ToolUse/ToolResult variants (BA/architect scope)
  - id: F-P18-04
    severity: MEDIUM
    status: FIXED
    class: AIMessage casing drift in BC H1 titles and test vectors (found by gate #19 census, within product-owner scope)
trajectory: "...→1→1→1→4"
clean_pass_counter: 0/3
canon_decision: "CheckpointSaver (not CheckpointStore) + RunnableConfig (not RunConfig) — implementer-facing norm, LangChain/LangGraph upstream name fidelity per D17"
previous_review: ADV-P1D-PASS-17.md
---

# ADV-P1D-PASS-18: Adversarial Review

## Finding ID Convention

Finding IDs for this pass use the format `F-P18-NN` (project convention; cycle prefix omitted per established ferrochain shorthand).

## Verdict: NOT CLEAN — 4 Findings (2 FIXED in product-owner scope; 2 OPEN in architect/BA scope)

Novel probe axis this pass: **shared-type identifier census** — first full sweep of all ferrochain
shared type identifiers across all BC code snippets and prd-supplements. This axis (gate #19)
had never been run as a whole before. Prior passes addressed individual renaming issues in
isolation; this pass establishes the standing gate with a comprehensive type list.

Sibling axes (NE anchor matrix reconfirmation, CAP/VP census, executable-string census): **PASS** —
no new findings on these axes this pass.

---

## Part B — New Findings (or all findings for pass 1)

## F-P18-01 (HIGH) — Shared-Type Name Split: CheckpointStore/CheckpointSaver + RunConfig/RunnableConfig

### Finding

**Class: shared Rust type identifiers across L2/L3 (NEW CLASS, gate #19 seeded)**

Two canonical type names had split spellings across L2 domain spec and L3 behavioral contracts,
creating the risk of Phase-3 integration breakage (implementers encounter two names, pick one,
other codepath fails to compile or link).

**CheckpointStore vs CheckpointSaver:**
- `ubiquitous-language-core.md` defines `CheckpointStore` as the canonical ferrochain name
- `ubiquitous-language-server.md` reconciliation table maps `BaseCheckpointSaver` → `CheckpointStore`
- `interface-definitions.md` (architect-produced) uses `CheckpointSaver` consistently
- BCs (BC-2.12.001, BC-2.12.003) used `CheckpointStore`

**RunConfig vs RunnableConfig:**
- `ubiquitous-language-server.md` reconciliation table shows `RunnableConfig` → `RunConfig` with "May rename in ADR"
- `interface-definitions.md` uses `RunnableConfig` consistently (upstream LangChain name)
- BCs (ss-10, ss-12, ss-15) and error-taxonomy.md used `RunConfig`

### Canon Decision (orchestrator-recorded)

`CheckpointSaver` and `RunnableConfig` are the canonical ferrochain names. Rationale: these are
the implementer-facing API surface names per D17 LangChain/LangGraph fidelity requirement, and
interface-definitions.md (the Rust trait specification) is the source of truth for API surface
identifiers.

### Fix Applied

| File | Change | Occurrences |
|------|--------|-------------|
| `ss-12/BC-2.12.001.md` | `CheckpointStore` → `CheckpointSaver` | 1 |
| `ss-12/BC-2.12.003.md` | `CheckpointStore` → `CheckpointSaver`, `RunConfig` → `RunnableConfig` | 2 |
| `ss-10/BC-2.10.001.md` | `RunConfig` → `RunnableConfig` | 5 |
| `ss-10/BC-2.10.002.md` | `RunConfig` → `RunnableConfig` | 2 |
| `ss-10/BC-2.10.003.md` | `RunConfig` → `RunnableConfig` | 3 |
| `ss-10/BC-2.10.004.md` | `RunConfig` → `RunnableConfig` | 2 |
| `ss-12/BC-2.12.002.md` | `RunConfig` → `RunnableConfig` | 1 |
| `ss-12/BC-2.12.004.md` | `RunConfig` → `RunnableConfig` | 4 |
| `ss-12/BC-2.12.007.md` | `RunConfig` → `RunnableConfig` | 1 |
| `ss-15/BC-2.15.002.md` | `RunConfig` → `RunnableConfig` | 2 |
| `ss-15/BC-2.15.003.md` | `RunConfig` → `RunnableConfig` | 2 |
| `prd-supplements/error-taxonomy.md` | `RunConfig` → `RunnableConfig` | 1 |

**Note:** `ubiquitous-language-core.md` still defines `CheckpointStore` and `ubiquitous-language-server.md`
reconciliation table still shows `RunConfig` as the ferrochain term — those are BA/architect scope
and require a separate fix pass to update the domain-spec layer.

**Residual check post-fix:**
```
CheckpointStore in BCs:     0 occurrences ✓
RunConfig in BCs:           0 occurrences ✓
RunConfig in prd-supplements (excl interface-definitions): 0 occurrences ✓
```

---

## F-P18-02 (MEDIUM) — interface-definitions.md: AIMessage Casing

**Scope: architect-owned file — NOT fixed in this pass.**

`interface-definitions.md` contains `AIMessage` (uppercase I) where `AiMessage` (Rust-idiomatic
camelCase) is the canonical ferrochain type name per BC-2.01.002 body text. Architect must apply
`AIMessage` → `AiMessage` in interface-definitions.md.

**Status:** OPEN — assigned to architect scope.

---

## F-P18-03 (MEDIUM) — Ubiquitous Language: Nonexistent ContentBlock::ToolUse / ContentBlock::ToolResult Variants

**Scope: BA/architect — NOT fixed in this pass.**

The ubiquitous-language-server.md reconciliation table lists `ContentBlock::ToolUse` and
`ContentBlock::ToolResult` as canonical ferrochain names, but the census finds 0 occurrences
of these variant spellings in any BC code snippet or prd-supplement. The BCs use `ToolMessage`
(the outer message wrapper) rather than `ContentBlock::ToolUse/ToolResult` (block-level variants).

Either: (a) these ContentBlock variants need to be added to the type system and BCs updated, or
(b) the reconciliation table entry is aspirational and should be marked as a future addition.

**Status:** OPEN — requires BA/architect decision on whether ContentBlock::ToolUse/ToolResult
are implemented variants or planned variants.

---

## F-P18-04 (MEDIUM) — AIMessage Casing Drift in BC Titles and Test Vectors

**Found by: gate #19 census (new finding, within product-owner scope).**

`AIMessage` (LangChain Python casing) appeared in ferrochain-native Rust type contexts in BCs:

| Site | Old | Fixed to |
|------|-----|---------|
| `BC-2.01.002.md` H1 title | `AIMessage` | `AiMessage` |
| `BC-2.01.002.md` CAP justification row | `AIMessage/HumanMessage...` | `AiMessage/HumanMessage...` |
| `BC-INDEX.md` title column | `AIMessage` | `AiMessage` |
| `BC-2.02.001.md` TV-001 test vector (`Append<AIMessage>`, `AIMessage("hello")`) | `AIMessage` | `AiMessage` |
| `prd-supplements/bc-authoring-plan.md` batch entry | `AIMessage` | `AiMessage` |

**Exempt:** `BC-2.01.002.md` line 91 reference `"semport/core/behavioral-intent.md §2 (AIMessage.tool_calls...)"` — this cites the Python semport source where `AIMessage` IS the correct Python class name. Python cross-references are exempt from the census per gate #19 rule.

**Status:** FIXED (within product-owner scope). F-P18-02 (interface-definitions.md) remains open for architect.

---

## Gate #19 Shared-Type Identifier Census (Full Table)

Census scope: all `.factory/specs/behavioral-contracts/**/*.md` + `.factory/specs/prd-supplements/**/*.md`
excluding `interface-definitions.md` (architect scope).

| Type | Canonical? | Files Found (post-fix) | Verdict |
|------|-----------|----------------------|---------|
| `Message` | YES | 22 | OK |
| `ContentBlock` | YES | 18 | OK |
| `AiMessage` | YES | 7 | OK (post-fix) |
| `AiMessageChunk` | YES | 2 | OK |
| `FerrochainError` | YES | 47 | OK |
| `Component` | YES | 4 | OK |
| `Category` | YES | 26 | OK |
| `RetryHint` | YES | 6 | OK |
| `CheckpointSaver` | YES | 15 | OK (post-fix) |
| `RunnableConfig` | YES | 15 | OK (post-fix) |
| `CheckpointTuple` | YES | 0 | UNUSED (not yet in BCs) |
| `RunStatus` | YES | 1 | OK |
| `MemoryStore` | YES | 3 | OK |
| `BudgetPolicy` | YES | 7 | OK |
| `GuardrailHook` | YES | 11 | OK |
| `ProvenanceTag` | YES | 10 | OK |
| `HumanMessage` | YES (inner struct) | 3 | OK |
| `SystemMessage` | YES (inner struct) | 3 | OK |
| `ToolMessage` | YES (inner struct) | 10 | OK |
| `ContentBlock::ToolUse` | ABSENT | 0 | UNUSED — F-P18-03 |
| `ContentBlock::ToolResult` | ABSENT | 0 | UNUSED — F-P18-03 |
| `CheckpointStore` | RETIRED | 0 | RETIRED-SPELLING CLEAN ✓ |
| `RunConfig` | RETIRED | 0 | RETIRED-SPELLING CLEAN ✓ |
| `BaseCheckpointSaver` | RETIRED | 0 | RETIRED-SPELLING CLEAN ✓ |
| `AIMessage` (Rust contexts) | RETIRED | 0 | RETIRED-SPELLING CLEAN ✓ (post-fix; 1 exempt semport ref) |

All retired spellings: 0 occurrences post-fix. Census CLEAN on the 4 targets in F-P18-01.

---

## Sibling Axes (Reconfirmed PASS)

- **NE anchor matrix (P16 standing gate):** Reconfirmed — no drift from P17 state.
- **CAP/VP census (P15 standing gate):** Reconfirmed — no new orphan capabilities.
- **Executable-string census (P17 standing gate):** Reconfirmed — no new harness name drift.
- **Anchor-matrix census (P16 standing gate):** Reconfirmed — all 86 BCs × 6 axes stable.

---

## Gate #19 Registration

Gate #19 (Shared-Type Identifier Census) registered in `prd-supplements/bc-authoring-plan.md`
as guideline item 15 (standing gate). The gate command, exempt-pattern rule (Python semport
cross-references), and canonical type list are documented in the guideline.

---

## Trajectory

```
...→P14(1)→P15(0-CLEAN)→P16(1)→P17(1)→P18(4 findings, 2 FIXED in PO scope, 2 OPEN architect/BA)
```

Clean pass counter: **0/3** — pass is not clean (2 open findings remain in architect/BA scope).
Next: architect must fix F-P18-02 (interface-definitions AIMessage casing) and BA/architect
must resolve F-P18-03 (ContentBlock::ToolUse/ToolResult variant existence decision).

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 3 |
| LOW | 0 |

**Overall Assessment:** pass-with-findings
**Convergence:** FINDINGS_REMAIN — 2 findings open in architect/BA scope; counter stays 0/3
**Readiness:** requires fix pass for F-P18-02 (architect) and F-P18-03 resolution (BA/architect)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 18 |
| **New findings** | 4 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 1.0 (4/4) |
| **Median severity** | 3.0 (MED — 1H+3M, median position = MED) |
| **Trajectory** | →1→1→1→4 |
| **Verdict** | FINDINGS_REMAIN |
