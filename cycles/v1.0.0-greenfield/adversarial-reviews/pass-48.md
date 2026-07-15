---
document_type: adversarial-review
pass: 48
verdict: NOT_CLEAN
severity: MED
novelty: MEDIUM
phase: 1d
timestamp: 2026-07-15T00:00:00Z
findings_count: 1
observations_count: 1
---

# Adversarial Review — Pass 48

## Verdict: NOT CLEAN — 1 finding (MED). Novelty MEDIUM.

---

## Findings

### F-P48-01 (MED): E-RETRY-* namespace annotation category-set incomplete in blanket omission note

**Location:** `interface-definitions.md` §Library/execution-layer codes — blanket omission note (~line 261).

**Finding:** The blanket omission note annotates `E-RETRY-* (BC-2.16.x, POLICY)` — listing only the POLICY category. However, E-RETRY-004 (InvalidRetryLimit, VAL, minted ADV-P1D-PASS-34 in taxonomy v1.5) means the E-RETRY namespace spans two categories: POLICY (E-RETRY-001/002/003) and VAL (E-RETRY-004). Every sibling namespace annotation in the same sentence is category-exhaustive (E-MCP-*: TOOL/TRANSPORT/VAL; E-SBXD-*: SECURITY/POLICY/INTERNAL; E-BUDGET-*: POLICY/DURABILITY; E-MEMORY-*: VAL/POLICY/DURABILITY; E-SPLIT-*: VAL); E-RETRY is the lone incomplete annotation. Root cause: partial-fix propagation — E-RETRY-004 was minted in pass 34 but the P29/P30-authored blanket note was not updated to reflect the VAL addition. Not a functional mapping change (VAL→400 categorical fallback already present in the fallback list).

**Fix:** Change `E-RETRY-* (BC-2.16.x, POLICY)` → `E-RETRY-* (BC-2.16.x, POLICY/VAL)`.

---

## Observations

### OBS-P48-1 (ADJUDICATED — intentional v1 limitation): Run.interrupt schema interrupt_id vs. REST Resume Request Schema

**Location:** `interface-definitions.md` §Resume Request Schema (~lines 330-339).

**Observation:** The Run.interrupt schema surfaces `interrupt_id` described as "used in Command(resume={interrupt_id: value}) targeted delivery" (BC-2.05.004 EC-002/TV-004), but the REST Resume Request Schema carries only `resume_value` + `approver_id`. REST clients cannot target a specific concurrent interrupt by interrupt_id.

**Adjudication (orchestrator, D17-Q2 committed HITL contract):** This is an intentional v1 limitation. D17-Q2 commits the FIFO-resume HITL contract: REST resume = FIFO delivery to the single active interrupt slot. Targeted delivery by interrupt_id is library-API only (Command API: `graph.invoke` / `graph.stream`). BC-2.05.004 EC-002/TV-004 describe the library Command path exclusively — no REST targeted-delivery claim is made. The limitation must be documented in the Resume Request Schema section.

**Fix:** Add one documentation line to the Resume Request Schema section noting the FIFO-only semantics and library-API restriction for targeted delivery.

---

## Sibling Checks

- interface-definitions v2.6 sandbox rows (F-P47-01/02/OBS-P47-1): PASS — all three fixes verbatim-match BCs; zero fallback text.
- Gate #29 census: FAIL on E-RETRY annotation seam (F-P48-01); all other sampled seams clean.

---

## Censuses

| Census | Result | Notes |
|--------|--------|-------|
| #16 (full namespace extraction) | PASS | CORE 1 / GRAPH 15 / CHKPT 6 / SERVER 15 / PROV 7 / MCP 4 / SPLIT 2 / SBXD 5 / RETRY 4 / CRON 3 / MEMORY 6 / BUDGET 2; zero collisions |
| #22 (exit codes) | PASS | Exactly 5 |
| #23 (stream event variants) | PASS | 11 variants — 9 Run/Node/Tool ×3 + 2 Step; RunEnd completion-only holds everywhere |
| #24 | PASS | 6/6 |
| #25 (arithmetic + tier-sibling) | PARTIAL | Arithmetic confirmed 86=48/30/8, 13 batches, 17 subsystems; tier-sibling + per-row crate diff NOT exhaustively run — pass 49 must run fully |

---

## Novel Probes

| Probe | Result |
|-------|--------|
| memory×tenancy | PASS — BC-2.15.002 analogous-principle scoping; DI-005 enforcers correctly exclude memory |
| sandbox×tool error flow | PASS — embedded-in-Run.error routing confirmed |
| HITL×server REST | PASS on state machine (+ OBS-P48-1 documented) |
| provenance×streaming | PASS — unconditional ingress tagging orthogonal to StreamEvent |

---

## Novelty Assessment

**MEDIUM** — category-completeness annotation drift seeded by post-dated taxonomy edit (E-RETRY-004 minted P34, blanket note authored P29/P30); rest of sweep LOW.
