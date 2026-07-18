---
document_type: architecture-section
level: L3
section: verification-coverage-matrix
version: "1.5"
status: active
producer: architect
timestamp: 2026-07-17T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/module-criticality.md
input-hash: "b90ba74"
traces_to: ARCH-INDEX.md
changelog:
  - "1.5 (provenance-fix-169/2026-07-17): cascade input-hash recompute (VP-INDEX.md v1.1 content change — column reorder for hook compatibility)."
  - "1.4 (provenance-fix-169/2026-07-17): cascade input-hash recompute (module-decomposition.md v1.8 content change); add [Section Content] template compliance fix."
  - "1.3 (gate #25 backfill + D20/CAP-021): F-backfill add write-guard enforcement HIGH row missing since ADR-012 D20 burst (matrix header was 33, module-criticality was 34 — drift corrected); add mcp-server MEDIUM row (CAP-021); header 33→35 (CRITICAL 9 / HIGH 13 / MEDIUM 11 / LOW 2); Coverage-by-Tier HIGH 12→13, MEDIUM 10→11."
  - "1.2 (ADV-P1D-PASS-45): F-P45-01 correct retry crate from ferrochain-graph to ferrochain-core per module-criticality.md line 64 (SS-16); relocate row from ferrochain-graph cluster into ferrochain-core cluster. Full 33-row crate-ownership diff against module-criticality.md — no other mismatches found."
  - "1.1 (ADV-P1D-PASS-37): F-P37-02 correct Coverage by Criticality Tier summary to CRITICAL 9 / HIGH 12 / MEDIUM 10 / LOW 2 = 33 (was stale 6/7/5/2=20); complete Per-Module Coverage Status table to all 33 architecture modules (was 27); added rows for ferrochain-macros (HIGH), sandbox-wasm (MEDIUM), ferrochain-standard-tests (MEDIUM), memory-store (MEDIUM), xtask (LOW), ferrochain-community (LOW)."
  - "1.0 (initial): base verification coverage matrix authored."
---

# Verification Coverage Matrix: ferrochain

## [Section Content]

> **VP-INDEX.md is the authoritative VP catalog.** This matrix derives from it.
> Arithmetic invariant: VP total (5) = Kani (3) + integration (2). Status is updated per gate.

## VP-to-Module Mapping

| VP | Title | Module | Crate | Tool | BC Anchor | Phase | Status |
|----|-------|--------|-------|------|-----------|-------|--------|
| VP-001 | BSP Super-Step Determinism | bsp-engine (reducer stage) | ferrochain-graph | Kani | BC-2.03.001 | 6 | draft |
| VP-002 | Session Triple-Address Uniqueness | session-index | ferrochain-checkpoint | Kani | BC-2.04.006 | 6 | draft |
| VP-003 | Workspace Path Confinement | path-guard | ferrochain-sandbox | Kani | BC-2.13.004 | 6 | draft |
| VP-004 | MCP ToolException Type-Identity Preservation | mcp-adapter | ferrochain-mcp | integration | BC-2.09.004 | 3 | draft |
| VP-005 | MultiServerMcpClient Holds No Live Connections | mcp-client | ferrochain-mcp | integration | BC-2.09.005 | 3 | draft |

**Totals: 5 VPs | Kani: 3 | proptest: 0 | fuzz: 0 | integration: 2**

## Per-Module Coverage Status

> This table covers all 35 architecture modules from `.factory/specs/module-criticality.md`.
> Tier groupings follow the authoritative inventory (CRITICAL 9 / HIGH 13 / MEDIUM 11 / LOW 2).

| Module | Crate | Kani | proptest | fuzz | Integration | Notes |
|--------|-------|------|---------|------|-------------|-------|
| bsp-engine | ferrochain-graph | VP-001 | yes (BC-2.03.003) | yes (BC-2.17.002) | yes | Core VP target |
| channels | ferrochain-graph | — | yes (BC-2.02.002) | — | yes | Reducer invariants via proptest |
| hitl | ferrochain-graph | — | — | — | yes | FIFO + suspend/resume |
| scheduler | ferrochain-graph | — | — | — | yes | Pending ADR-001 |
| budget | ferrochain-graph | — | yes | — | yes | EvidenceJournal ordering |
| provenance | ferrochain-graph | — | — | — | yes | Hook dispatch |
| event_emitter | ferrochain-graph | — | — | — | yes | Streaming/unary equivalence |
| session-index | ferrochain-checkpoint | VP-002 | yes | — | yes | Core VP target |
| clock | ferrochain-checkpoint | — | yes | — | yes | Monotonic property |
| lineage | ferrochain-checkpoint | — | — | — | yes | Fork pointer |
| encryption | ferrochain-checkpoint | — | — | — | yes | Payload coverage |
| sqlite | ferrochain-checkpoint | — | — | yes (BC-2.17.002) | yes | Round-trip fuzz |
| path-guard | ferrochain-sandbox | VP-003 | — | — | yes | Core VP target |
| sandbox-policy | ferrochain-sandbox | — | — | — | yes | Err(PolicyNotEnforceable) |
| message | ferrochain-core | — | yes | — | yes | ContentBlock invariants |
| error | ferrochain-core | — | — | — | yes | RFC-7807 emission |
| credentials | ferrochain-core | — | — | — | yes | Redacted Debug |
| runnable | ferrochain-core | — | yes | — | yes | Pipe associativity |
| retry | ferrochain-core | — | yes | — | yes | Policy termination |
| server handlers | ferrochain-server | — | — | — | yes | CRUD lifecycle |
| server security | ferrochain-server | — | — | — | yes | SecurityConfig defaults |
| recursive splitter | ferrochain-splitters | — | yes | — | yes | Code-point boundaries |
| openai | ferrochain-openai | — | — | — | yes | Conformance suite |
| anthropic | ferrochain-anthropic | — | — | — | yes | Conformance suite |
| ollama | ferrochain-ollama | — | — | — | yes | Conformance suite |
| mcp client | ferrochain-mcp | — | — | — | yes | Red Gate BCs |
| mcp adapter | ferrochain-mcp | — | — | — | yes | ToolException fidelity |
| mcp server | ferrochain-mcp | — | — | — | yes | Server-side tool exposure + inbound dispatch (CAP-021) |
| ferrochain-macros | ferrochain-macros | — | — | — | yes | `#[tool]`/`#[entrypoint]`/`#[task]` expansion correctness |
| sandbox-wasm | ferrochain-sandbox | — | — | — | yes | WASM execution backend |
| ferrochain-standard-tests | ferrochain-standard-tests | — | — | — | yes | Shared conformance harness; exercised via provider integrations |
| memory-store | ferrochain-memory | — | yes | — | yes | KV + vector ops; GDPR erasure protocol |
| write-guard enforcement | ferrochain-memory | — | — | — | yes | `WriteGuardDecision` enforcement; injection scanning dispatch (D20/ADR-012) |
| xtask | xtask | — | — | — | — | CI lint gates only; advisory ≥70% |
| ferrochain-community | ferrochain-community | — | — | — | — | Post-v1 placeholder; not in-tree at v1 |

## Coverage by Criticality Tier

| Tier | Modules | Kani VPs | proptest | fuzz | Kill Rate Target |
|------|---------|---------|---------|------|-----------------|
| CRITICAL | 9 | 3 (VP-001, VP-002, VP-003) | all | subset | ≥ 95% |
| HIGH | 13 | 0 | most | subset | ≥ 90% |
| MEDIUM | 11 | 0 | some | — | ≥ 80% |
| LOW | 2 | 0 | — | — | ≥ 70% |

## Mutation Kill Rate Gates (cargo-mutants)

Kill rate gates are Phase-5 adversarial gates. Phase-3 per-story gates apply to CRITICAL modules only.

| Tier | Gate | Phase |
|------|------|-------|
| CRITICAL | ≥ 95% | Phase 3 (per story) + Phase 5 |
| HIGH | ≥ 90% | Phase 5 |
| MEDIUM | ≥ 80% | Phase 5 |
| LOW | ≥ 70% | Phase 5 advisory |
