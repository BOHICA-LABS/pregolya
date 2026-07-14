---
document_type: domain-spec-section
level: L2
section: differentiators
version: "1.0"
status: draft
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "96a97c892cfd894c1e3b2d9df10121c70d1b282157e5d6d8dcb5a139c887f694"
traces_to: L2-INDEX.md
decisions: [D7, D17]
---

# Competitive Differentiators

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

Source: product-brief.md §Overflow Competitive Differentiator Traceability and
market-intel.md §4. Each differentiator maps to the domain capabilities that implement it.

---

## Differentiator Map

| # | Differentiator | Market Source | Domain Capabilities | Domain Invariants | Phase-1 BC Anchor |
|---|---------------|--------------|---------------------|-------------------|-------------------|
| D-01 | LangGraph runtime + durable checkpointing in Rust — no competitor has this | market-intel §4 #1; CONFLICT-1/2/3/4 | CAP-003, CAP-004, CAP-005, CAP-006 | DI-001, DI-002, DI-003, DI-004 | Graph BSP determinism + HITL + per-task durability BCs (D17-Q2/Q3) |
| D-02 | Standard-tests conformance suite — no competitor has this | market-intel §4 #2 | CAP-011 | (none; process-level differentiator) | ferrochain-standard-tests conformance BC |
| D-03 | Formally-verified core (Kani + cargo-fuzz) — no competitor has this | market-intel §4 #3; D17-Q7 | CAP-019 | DI-001 (BSP VP), DI-005 (tenancy VP), DI-007 (workspace VP) | BSP determinism VP (VP-001), session triple-address VP (VP-002), workspace path confinement VP (VP-003/DI-007/NE-02) (D17-Q7) |
| D-04 | Idiomatic async-first trait design with typed ContentBlock and 2D error taxonomy | market-intel §4 #4; CONFLICT-6 | CAP-001, CAP-002, CAP-016 | DI-008 (constructor Result), DI-014 (no silent errors) | FerrochainError 2D struct BC; typed ContentBlock BC |
| D-05 | Provider conformance + LangChain Python v1 migration story | market-intel §4 #5 | CAP-009, CAP-010, CAP-011 | (process-level; no runtime invariant) | ferrochain-standard-tests + "Coming from LangChain?" docs |

---

## Competitive Landscape Coverage Gap

The four-part combination that no competitor has (ASM-003, validated):

| Capability | Closest Rust Competitor | Gap |
|------------|------------------------|-----|
| StateGraph runtime | langgraph-rust (Onelevenvy) v0.2.x | No durable checkpoint; no HITL resume; 599 downloads |
| Durable checkpointing | None | Confirmed white space (market-intel §4) |
| Provider conformance suite | None | Confirmed white space |
| Formally-verified core | None | Confirmed white space |
| Combined (all four) | None | This four-part combination = ferrochain's unique market position |

## Differentiator Delivery Risk

D-01 is most at risk from R-001 (langgraph crate velocity). D-03 is time-insensitive (formal
verification is a quality play, not a first-mover play). D-02 is entirely in-house and
independent of competitors.

The critical path for differentiator delivery is:
```
CAP-004 (BSP) → CAP-005 (durability) → CAP-006 (HITL) → D-01 delivered
CAP-011 (std-tests) → D-02 delivered
CAP-019 (Kani/fuzz) → D-03 delivered
```
