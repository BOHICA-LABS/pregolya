---
document_type: adversarial-review
pass: 77
verdict: NOT CLEAN
finding_count: 1
finding_severity: [HIGH]
novelty: HIGH
novelty_class: taxonomy-vs-anchor-BC-semantic-divergence
novelty_notes: "New failure class: taxonomy row described REGEX validation model while anchor BC mandated EXACT-NAME model. Invisible to name/presence-only gates (#20, #33). Survived two prior gate passes. Gate #33 extended with SEMANTIC-AGREEMENT sub-check (steps 7–10) to close this axis."
sibling_checks: "N/A (no fix burst preceded pass 77)"
timestamp: 2026-07-15T00:00:00Z
phase: 1d
---

# Adversarial Review Pass 77

**Verdict: NOT CLEAN — 1 HIGH finding (F-P77-01). Counter RESET 1/3 → 0/3.**

---

## Findings

### F-P77-01 (HIGH) [process-gap] — E-SBXD-006 Taxonomy Regex-vs-Wildcard Semantic Divergence

**FIXED (PO): taxonomy v1.14 E-SBXD-006 row rewritten to wildcard/exact-name model.**

E-SBXD-006 taxonomy row described a REGEX validation model ("not a valid regex pattern" / "fails regex compilation" / "fix the pattern") while anchor BC-2.13.007 mandates an EXACT-NAME model: `env_allowlist` entries are exact names, case-sensitive; E-SBXD-006 fires when an entry contains `*` or `?` wildcard characters; regex is unsupported in v1.

**Operational contradiction:** The string "OPENAI_*" compiles as a syntactically valid regex (it would NOT fire under the taxonomy's regex model), but TV-005 mandates it MUST fire (wildcard character present). An implementer following the taxonomy row ships a regex-based allowlist validator that silently accepts "OPENAI_*" on the DI-010 credential boundary — violating BC-2.13.007's exact-name enforcement intent.

**Survived gates:** Gate #20 (HTTP status membership census — name/presence-only) and gate #33 (taxonomy anchor reverse-verification — presence-only: verified code exists at anchor BC, but did not verify that the raise-condition description and message text AGREE with anchor BC EC/TV predicates). This is a new failure class.

**Fix applied (PO, same burst):** error-taxonomy.md v1.14 — E-SBXD-006 row rewritten: message matches BC-2.13.007 PC5 verbatim, raise-condition language changed from "fails regex compilation" to "contains wildcard character (`*` or `?`)", regex language removed entirely, VAL label + RetryHint Never kept.

**Process-gap closed (D18-P77-B):** Gate #33 extended with SEMANTIC-AGREEMENT sub-check steps 7–10: Message Format template in taxonomy row + raise-condition annotation must agree with anchor BC message text + EC/TV predicates; BC wins on any divergence. Total standing gates unchanged at 33. bc-authoring-plan → v2.17.

---

### OBS-P77-A (MED, FIXED) — ADR-013 Interface Sketch Fourfold Divergence from BC-2.09.006

ADR-013 interface sketch contained four divergences from BC-2.09.006:
1. `McpTransport` (ADR sketch) vs `McpServerTransport` (BC-2.09.006 anchor)
2. `serve(transport, registry)` (ADR sketch) vs `start(config)` (BC-2.09.006)
3. Return type `()` (ADR sketch) vs `McpServerHandle` (BC-2.09.006)
4. `Sse { port, path }` (ADR sketch) vs `Sse { bind_addr: SocketAddr }` (BC-2.09.006)

**FIXED (architect):** ADR-013 v1.1 — interface sketch reconciled to BC shapes; behavioral-authority note added ("BC-2.09.006 and the interface-definitions.md canonical shapes govern; ADR sketches are illustrative only and BC/interface-definitions win on divergence"). Zero `McpTransport` residue in architecture/ (`McpTransportError` elsewhere = distinct error type, exempt from this fix).

---

### OBS-P77-B (MED, FIXED) — BC-2.08.013 Architecture Anchor Dialect Contradiction

BC-2.08.013 Architecture Anchor section described the 3 message dialects as "built-in enum variants" — contradicting its own pluggable object-safe TRAIT model (which BC-2.08.013 defines elsewhere: `MessageFormat` is a trait with 3 built-in implementations, not an enum).

**FIXED (PO):** BC-2.08.013 v1.1 — "built-in enum variants" → "built-in trait implementations".

---

### OBS-P77-C (MED, FIXED) — ADR-012 Local Invariant Squatted DI-NNN Domain Namespace

ADR-012 named a local architectural invariant "ADR-012 DI-001" — squatting the `DI-NNN` namespace. DI-001 is already globally reserved for BSP Reducer Determinism (the domain-invariant namespace is managed by the PO registry).

**ADJUDICATED (D18-P77-A):** Renamed → "ADR-012 INV-1". ADR-012 v1.2 updated by architect.

**Propagated (PO):** BC-2.15.006 v1.1 (2 occurrences of "ADR-012 DI-001" → "ADR-012 INV-1"); capabilities-p1-p2 v1.2 (1 occurrence). Zero live "ADR-012 DI-001" residue confirmed (changelog audit-trail entries exempt).

---

### OBS-P77-D (LOW, DECLINED) — BC-2.15.004 EC-004 Read I/O Error → E-MEMORY-002 StorageFull

BC-2.15.004 EC-004 maps read I/O errors to E-MEMORY-002 (StorageFull) with an "or equivalent propagated storage error" hedge (verbatim confirmed in BC text). No generic MEMORY read-failure code exists in the taxonomy. Minting a new code for this edge case declined during convergence — the hedge covers the gap without ambiguity, and minting adds risk of taxonomy churn.

**Standing note for Phase 2+:** if Phase 2 story decomposition reveals a need for a distinct read-I/O error code in the memory subsystem, route to PO at that time.

---

## Clean Verifications (Adversary Ledger)

| Check | Result |
|-------|--------|
| Census 85 = 43 HTTP + 16 omission + 26 blanket re-derived (by namespace: CORE 7 / GRAPH 16 / CHKPT 9 / SERVER 14 / PROV 10 / MCP 5 / SPLIT 2 / SBXD 6 / RETRY 4 / CRON 3 / MEMORY 7 / BUDGET 2) | PASS |
| Universe 35 = 9/13/11/2 (arch view) | PASS |
| PO registry 22 = 6/9/5/2 | PASS |
| 6 RetryHint divergences BC-anchored | PASS |
| 21 CAPs = 11/7/3 | PASS |
| VP 5 = 3 Kani P0 + 2 integration P1 — propagated across all 3 carrying docs | PASS |
| DI 14/14 — zero orphans | PASS |
| Gate #13 (BC numbering uniqueness) | PASS |
| Gate #20 (HTTP status membership census — name/presence-only axis) | PASS |
| Gate #22 (6 RetryHint divergences BC-anchored) | PASS |
| Gate #25 (CAP count 21 = 11/7/3) | PASS |
| Gate #31 (gate enforcement command syntax) | PASS |
| Gate #32 (ADR propagation scope) | PASS |
| Gate #33 (taxonomy anchor reverse-verification — presence axis; semantic-agreement axis = new gap identified → closed by D18-P77-B steps 7–10) | PARTIAL → EXTENDED |

---

## Summary

**Finding trajectory:** →1 (P1D-77, RESET). Counter 0/3.

**Novelty:** HIGH — new class: semantic divergence between taxonomy raise-condition description and anchor BC EC/TV predicates. Invisible to name/presence-only gate passes. Gate #33 semantic-agreement sub-check (D18-P77-B, steps 7–10) closes this axis. This class has no prior manifestation in passes 1–76.
