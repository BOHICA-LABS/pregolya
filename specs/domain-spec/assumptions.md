---
document_type: domain-spec-section
level: L2
section: assumptions
version: "1.1"
status: active
producer: business-analyst
timestamp: 2026-07-17T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/planning/market-intel.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
input-hash: "a346f3d"
traces_to: L2-INDEX.md
decisions: [D1, D2, D7, D17]
changelog:
  - "v1.1 (2026-07-17): Provenance-integrity fix — STATE.md removed from inputs (D-NNN decisions baked at authoring time); broken path comment removed from market-intel.md entry (awk path-parser strips whitespace; parenthetical comment made the path unresolvable); COMPARATIVE-ASSESSMENT.md added (ASM-001 D17 HYBRID, ASM-009 HS-4/HS-9 grounding); domain-a-soc-analyst.md added (ASM-008 risk-tiered HITL source); input-hash recomputed."
---

# Assumptions

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

All ASM entries have `Status: unvalidated` unless validation is documented.
Holdout candidates (Confidence=Low or Impact-if-Wrong=HIGH) are flagged.

---

| ID | Assumption | Confidence | Impact if Wrong | Status | Validation Method |
|----|------------|-----------|-----------------|--------|-------------------|
| ASM-001 | LangChain v1 Python semantics are the authoritative API-surface for ferrochain's external contract | High | HIGH — entire positioning strategy | Validated — D17 HYBRID decision adopted verbatim | D17 human direction gate; COMPARATIVE-ASSESSMENT.md recommendation accepted |
| ASM-002 | Rust developers building production AI systems know LangChain/LangGraph semantics and need them without Python | High | HIGH — TAM assumption; wrong TAM means adoption fails | Validated — GitHub issue #15057 explicitly requests Rust LangChain; crate download baselines confirmed | market-intel.md §1/§3; product-brief §Market Intelligence Summary |
| ASM-003 | No existing Rust crate ships LangGraph runtime + durable checkpointing + conformance suite + formal verification as a combination | High | HIGH — kills white-space positioning | Validated — market-intel gate PASSED; zero crates with this four-part combination confirmed | market-intel.md §4; ASM-003/ASM-004 notation in product-brief |
| ASM-004 | Rust LLM agents are 25–44% faster and 4× less memory than Python equivalents | Medium | Medium — affects "why Rust" messaging but not feasibility | Partially validated — cited dev.to benchmark; methodology not independently audited | product-brief §Market Intelligence Summary; treat as indicative |
| ASM-005 | ferrochain-core can reach ≥4,000 downloads/month within 12 months of public release | Low | Medium — affects success metric; parity baseline correct but new crate ramp uncertain | Unvalidated | Measure at 3-month, 6-month, 12-month post-launch; compare to langchain-rust baseline (4k/month confirmed in market-intel) — **Holdout candidate: yes** |
| ASM-006 | LangChain Python v1 API surface will not introduce breaking semantic changes before ferrochain v1 ships | Medium | HIGH — breaking changes in reference corpus invalidate BC authoring | Unvalidated | Monitor langchain==1.3.x changelog; lock semport to SHA 42f8f79; pin langgraph to SHA 95af6a0 (D2); delta-assess before Phase-2 story decomp — **Holdout candidate: yes** |
| ASM-007 | msgpack is sufficient for checkpoint wire format without Python wire compatibility | High | Low — format can be changed pre-v1 if wrong; one-way import tool handles migration | Validated — D11.2 human decision; Python-checkpoint import tool in scope | D11.2; one-way import tool in scope (product-brief §Constraints) |
| ASM-008 | A single boolean interrupt is insufficient for the SOC analyst domain; risk-tiered authorization gates require typed action-risk levels routing to different approver roles | High | HIGH — Domain A holdout fails if HITL is single-boolean; architecture unfit for enterprise security | Validated — domain-a-soc-analyst.md §5 explicitly identifies risk-tiered autonomy as NEW; vendor pattern (Palo Alto XSIAM, SentinelOne) confirms tiered model | domain-a-soc-analyst.md §4, §5; D8 Phase-1 forcing function |
| ASM-009 | Budget governance (allow/escalate/deny policy with cost metering) is novel in the Rust LLM framework ecosystem | High | Medium — if a competitor ships this first, we lose differentiation on Domain B; core graph runtime remains differentiating | Validated — HS-4/P-46: no adk-rust analog; market-intel §4 does not list a Rust budget-governance crate | COMPARATIVE-ASSESSMENT.md HS-4, HS-9; product-brief Overflow §D17-BC-Backlog |

---

## Assumption Dependency Map

- ASM-001 → all BC authoring (LangChain is the semantic authority)
- ASM-002 + ASM-003 → market positioning; success metric CAP-009 (standard-tests)
- ASM-006 → BC version stability; triggers delta-assess if semport corpus updates
- ASM-008 → HITL design (CAP-006 must be richer than one boolean)
- ASM-009 → CAP-012 scope and priority
