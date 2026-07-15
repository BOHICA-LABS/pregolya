---
document_type: adversarial-review
pass: 52
verdict: CLEAN
severity: N/A
confidence: HIGH
novelty: LOW
phase: 1d
timestamp: 2026-07-17T12:00:00Z
findings_count: 0
observations_count: 2
producer: adversary
burst: burst-128
---

# Adversarial Review — Pass 52

## Verdict: CLEAN — ZERO findings. Novelty LOW. Adversary: "The spec package is converged... recommend counting toward the minimum-3-clean-pass requirement."

---

## Findings

None.

---

## Observations (non-defect)

### OBS-P52-1: #[entrypoint] macro name overlaps LangGraph functional-API @entrypoint

**Location:** ferrochain-macros spec, domain-spec, ADR references (proc-macro surface).

**Observation:** The `#[entrypoint]` proc-macro name overlaps with LangGraph's functional-API `@entrypoint` decorator. The ferrochain semantics are distinct: `#[entrypoint]` auto-wires the START edge (CAP-003) — a structural graph-wiring primitive. LangGraph's `@entrypoint` is a higher-level functional-API abstraction with different lifecycle semantics. The specs are unambiguous within ferrochain's own frame.

**Adjudication:** Non-defect. Naming overlap is a migration-friction note for users moving from LangGraph Python, not a spec contradiction. The semantic distinction (START-edge auto-wiring per CAP-003) is clear and unique. No spec change required; a migration guide note is appropriate at documentation phase.

---

### OBS-P52-2: retry_policy/cache_policy/defer add_node options + functional API excluded by positive-enumeration scope bounding

**Location:** bc-authoring-plan scope-bounding conventions; Wave-1 scope exclusions.

**Observation:** The `retry_policy`, `cache_policy`, and `defer` options to `add_node`, plus the functional API entrypoint pattern, are excluded from Wave-1 scope via positive-enumeration (listing what IS included) rather than explicit per-feature exclusion notes. This is the spec's consistent scope-bounding pattern.

**Adjudication:** Non-defect. Positive-enumeration exclusion is the established and documented convention in the spec (consistent with the scope-bounding pattern used throughout). Per-feature exclusion notes would duplicate information and create maintenance burden. No spec change required.

---

## Mandatory Negative-Space Round 3 — All 10 Mechanisms Resolved

All 10 upstream mechanisms reviewed for coverage status:

| Mechanism | Status | Authority |
|-----------|--------|-----------|
| Command `goto` | SPECIFIED | BC-2.05.004 PC4/EC/TVs — goto target-node semantics fully contracted |
| Command `update` | SPECIFIED | BC-2.05.004 PC3 state-update; graph=PARENT override PC5; E-GRAPH-015 invalid-update |
| `entrypoint.final` | EXCLUDED | Functional API DEFER P2 per dependency-disposition:77 — Wave-1 scope does not include functional API |
| Pending-sends (checkpoint flush) | SPECIFIED | BC-2.02.006 PC1/PC2/PC7 pending-sends semantics + BC-2.04.005 EC-004 checkpoint-write-with-pending |
| EphemeralValue | SPECIFIED | BC-2.02.004 Red Gate (EphemeralValue does NOT cross super-step boundary); DEC-004; R10 risk documented |
| NamedBarrierValue | SPECIFIED | BC-2.02.003 Red Gate (NamedBarrierValue aggregation semantics); DEC-003; E-GRAPH-004/E-GRAPH-010; R10 risk documented |
| stream_mode variants | EXCLUDED-BY-REPLACEMENT | 11-variant StreamEvent taxonomy (ADR-006/D13) replaces Python stream_mode dispatch entirely — ferrochain-native wire format |
| Subgraph streaming | SPECIFIED | BC-2.06.001 EC-004/TV-005 parent_ids propagation in subgraph stream events |
| Per-node RetryPolicy | EXCLUDED-scope | tool-retry SPECIFIED in SS-16; per-add_node RetryPolicy = Wave-2 positive-enumeration exclusion |
| CachePolicy | EXCLUDED | DEFER P2 (disposition:81); ADR-011 is cache-KEY only — full per-node CachePolicy is post-Wave-1 |
| Deferred nodes | EXCLUDED | Reducer-channel fan-in makes deferred-aggregator pattern unnecessary (BC-2.02.006 PC6 covers the aggregation use case); no spec gap |

**Round 3 verdict: ALL RESOLVED.** No unported mechanisms, no gaps.

---

## Censuses

| Census | Result | Details |
|--------|--------|---------|
| #21 (E-code override registry) | PASS | 12 base codes + overrides intact; count consistent across all 4 documents |
| #22 (RetryHint count) | PASS | Exactly 5 per-code RetryHint assignments; no phantom 6th |
| #23 (RunEnd completion-only, 3-doc coherence) | PASS | BC-2.06.001 PC2+EC-005, BC-2.12.007 TV-005/EC-003/EC-001, interface-definitions v2.8 — RunEnd = completion-only; non-completion terminals use error SSE / __interrupt__ envelope respectively |
| #26 (structurally-privileged lines) | PASS | 18 crates; 86/48/30/8 BC distribution; 17/17 NEs (ubiquitous-language-server); 5 VPs — all four counts consistent across all structurally-privileged locations |

---

## Additional Probes

### (a) H1↔INDEX Title Sync (6 sampled)

Six BC document H1 titles spot-checked against BC-INDEX.md entries: all consistent.

**Result: PASS.**

### (b) Subsystem Sync

Subsystem assignments in BC-INDEX cross-checked against ss-NN directory structure and ARCH-INDEX subsystem table for sampled entries: consistent.

**Result: PASS.**

### (c) Semantic Anchoring

Sampled anchor paths in behavioral contracts (ss-04, ss-11, ss-16) cross-checked against ADR-007 crate roster and module-decomposition ownership: all paths resolve correctly.

**Result: PASS.**

### (d) Partial-Fix Regression Discipline

E-GRAPH-017 full propagation chain verified (taxonomy v1.6, BC-2.03.001 v1.2, BC-2.01.003 v1.1, BC-2.08.002 v1.1, interface-definitions v2.8 dual-layer row): all consistent. RunEnd completion-only canon fully propagated (3-doc coherence, census #23 PASS). No partial-fix residue detected.

**Result: PASS.**

---

## Convergence Assessment

- Convergence counter advances: **2 of 3** (strict-zero D14).
- Trajectory: ...→1→1→0 (P1D-35 CLEAN) →3→2→1→2→1→0 (P1D-41 CLEAN) →1→1→0 (P1D-44 CLEAN) →2→1→2→1→1→1→0 (P1D-51 CLEAN) →**0 (P1D-52 CLEAN)**.
- Adversary assessment: "The spec package is converged... recommend counting toward the minimum-3-clean-pass requirement."
- Next action: Pass 53 — THE POTENTIAL CONVERGENCE PASS. Rotate remaining census set (#13 five-way anchor matrix, #24 pagination, #25 A+B+C, #27 crate-resolution, #28 two-form version-changelog, #29 supplement-vs-BC seams); arithmetic-executability spot; adversary free choice (maximum creativity encouraged). CLEAN → 3/3 → Phase 1d CONVERGED → /vsdd-factory:check-input-drift → Phase 1 human approval gate. ANY finding resets to 0/3.
