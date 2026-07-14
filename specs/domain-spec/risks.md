---
document_type: domain-spec-section
level: L2
section: risks
version: "1.0"
status: draft
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/STATE.md
input-hash: "f6a9de5f38547412b42b12dbd19c3733ab48c3741c91c3cacad08519057dee21"
traces_to: L2-INDEX.md
decisions: [D1, D2, D7, D17]
---

# Risk Register

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

R-NNN entries map from STATE.md Risk Register + product-brief. Each R-NNN has
`Status: open` and a `Category` tag. NFR and security candidates are flagged.

---

| ID | Risk | Likelihood | Impact | Status | Category | Traced To | Mitigation |
|----|------|-----------|--------|--------|----------|-----------|------------|
| R-001 | Competing `langgraph` crate (Onelevenvy) captures the LangGraph identity in Rust before ferrochain-graph ships. v0.2.x active; 599 downloads but updated 2026-07-01. | Medium | HIGH | open | business | CAP-004, CAP-005, success metric #2 | Lead with ferrochain-graph quality + durable checkpointing + HITL before competitor matches it (D7 P0 wave priority). Binary: ship ferrochain-graph GA with durable checkpointing before competitor announces equivalent. NFR candidate: no (velocity risk, not performance). |
| R-002 | crates.io namespace race: ferrochain-* names verified available but not yet reserved; `cargo login` + `publish-all.sh` not yet run | High | HIGH | open | business | All CAPs | Human must run `cargo login` + `.factory/namespace-reservation/publish-all.sh` immediately (R6 in STATE.md; PENDING HUMAN ACTION). Security focus: no — namespace squatting, not security vulnerability. |
| R-003 | LangChain Python v1 API semantic changes between semport pin (1.3.13) and ferrochain v1 release invalidate authored BCs | Medium | HIGH | open | reliability | CAP-001 to CAP-007, ASM-006 | Lock to SHA 42f8f79293 (D2). Monitor 1.3.x changelog. Delta-assess against new minor versions before Phase-2 story decomp. If breaking change detected, trigger re-scope gate. Holdout candidate: yes (ASM-006). NFR candidate: no. |
| R-004 | Splitters code-point vs byte-length parity on non-ASCII input — no upstream test coverage; wrong behavior is silent and hard to detect | High | High | open | correctness | CAP-008, DEC-001 | Phase-1 BC + Red Gate test authored from behavior (D17-Q9). Explicit test vectors for emoji and CJK input. Holdout scenario. NFR candidate: no (correctness risk). Security focus: no. |
| R-005 | NamedBarrierValue and EphemeralValue — no upstream unit tests for boundary behavior; product-owner must author BCs without reference tests | Medium | Medium | open | correctness | DEC-003, DEC-004 | Product-owner authors BCs from behavioral analysis (D17-Q9). Red Gate tests must compile and fail before any implementation. Reference: semport Corpus 1 source code as behavioral oracle. NFR candidate: no. |
| R-006 | MCP test voids: bare ToolException re-raise path untested upstream; `__aenter__` NotImplementedError contract untested | Medium | Medium | open | reliability | CAP-010, DEC-012 | Phase-1 BC backlog (D17-Q9). Explicit Red Gate tests for both paths. If MCP adapter behavior differs from langchain-mcp-adapters==0.3.0 on these paths, treat as a conformance defect. NFR candidate: no. |
| R-007 | langchain-community v1.0.0a1 API churn: alpha tag indicates instability; community integration wave targets demand-ranked surface, not the archived module manifest | Low | Medium | open | business | Post-v1 community scope (D1) | Community integrations are post-v1, third-party contributed, conformance-validated via ferrochain-standard-tests. Not a v1 blocker. Monitor for alpha-to-stable promotion. NFR candidate: no. |
| R-008 | D9 graph execution ADR requires ≥2 alternatives presented to human before lock; if architect presents only one option, the gate does not close and Phase-2 story decomp blocks | Medium | HIGH | open | reliability | CAP-003, CAP-004, all Wave 1 | D9 gate is explicit: architect must present ≥2 alternatives with production trade-offs. D11 steers apply (BSP, msgpack, 3-tier durability, sync default). Human approval required before architecture lock. NFR candidate: no. |

---

## Dual Risk ID Reconciliation (F-10)

Two risk ID schemes coexist across the spec package. The **domain-spec R-NNN scheme is
canonical within all spec artifacts** (domain-spec/, prd.md, PRD RTM Source column, BC
Traced-To columns). STATE.md R-N numeric aliases are retained for decision-log continuity
only; do not use them in new spec or BC authoring.

| Domain-Spec ID (canonical) | STATE.md Alias | Risk Description |
|---------------------------|----------------|-----------------|
| R-004 | R8 | Splitters code-point vs byte-length parity on non-ASCII input |
| R-005 | R10 | NamedBarrierValue / EphemeralValue — no upstream unit tests for boundary behavior |
| R-006 | R11 | MCP test voids: bare ToolException re-raise path + `__aenter__` NotImplementedError contract untested |

All other domain-spec risks (R-001–R-003, R-007–R-008) have no direct STATE.md alias; they
were introduced during Phase-1 domain modeling. BC frontmatter `red_gate_source` fields in
BC-INDEX Red Gate table cite STATE.md R-N form (R8/R10/R11) because the BCs were authored
before the domain-spec mapping was established. Use this table to cross-walk the two schemes.

---

## Risk-to-Capability Traceability

- R-001 affects CAP-004 and CAP-005 because the competitor's gap is precisely the BSP
  runtime + durable checkpointing that CAP-004/005 provide.
- R-002 affects all CAPs because without namespace reservation, ferrochain crates cannot
  publish; all capabilities are undeliverable.
- R-003 affects CAP-001 through CAP-007 because LangChain API surface is the semantic
  authority for those capabilities (ASM-001).
- R-004 affects CAP-008 because splitter code-point correctness is the defining invariant
  of that capability.
- R-008 affects CAP-003 and CAP-004 because without an approved graph ADR, no graph BC
  can be authored.
