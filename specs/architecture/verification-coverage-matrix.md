---
document_type: architecture-section
level: L3
section: verification-coverage-matrix
version: "1.8"
status: active
producer: architect
timestamp: 2026-07-21T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/verification-properties/VP-INDEX.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/module-criticality.md
input-hash: "78e6dd5"
traces_to: ARCH-INDEX.md
changelog:
  - "1.8 (burst-224/2026-07-21): Fix Coverage by Criticality Tier MEDIUM count: 11 → 12 (vectorstores-mmr reclassified CRITICAL → MEDIUM when VP-009 moved to vectorstores-similarity; F-P129-11 reclassification, not an addition). Fix tier membership description in header note. Refresh input-hash cascade: 8bc637f → 78d9c11 (module-decomposition.md v1.12) → c766473 final (module-criticality.md v1.4 D21+burst-224 backfill in same burst)."
  - "1.7 (burst-224/2026-07-21): F-P129-11 — VP-009 module renamed vectorstores-mmr → vectorstores-similarity in VP-to-Module table; Per-Module Coverage Status split into vectorstores-similarity (VP-009 Kani P0) + vectorstores-mmr (no Kani VP, caller of similarity). Totals unchanged (10 VPs, Kani 6). Propagates VP-INDEX v1.3 + module-decomposition v1.12."
  - "1.6 (burst-223/2026-07-21): D21 VP layer — add VP-006..010 to VP-to-Module table; add SS-18..22 module rows to Per-Module Coverage Status; update Totals 5→10 VPs, Kani 3→6, proptest 0→2; update Coverage by Criticality Tier to reflect new D21 modules."
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
> Arithmetic invariant: VP total (10) = P0 (5) + P1 (5) = Kani (6) + proptest (2) + integration (2). Status is updated per gate.

## VP-to-Module Mapping

| VP | Title | Module | Crate | Tool | BC Anchor | Phase | Status |
|----|-------|--------|-------|------|-----------|-------|--------|
| VP-001 | BSP Super-Step Determinism | bsp-engine (reducer stage) | ferrochain-graph | Kani | BC-2.03.001 | 6 | draft |
| VP-002 | Session Triple-Address Uniqueness | session-index | ferrochain-checkpoint | Kani | BC-2.04.006 | 6 | draft |
| VP-003 | Workspace Path Confinement | path-guard | ferrochain-sandbox | Kani | BC-2.13.004 | 6 | draft |
| VP-004 | MCP ToolException Type-Identity Preservation | mcp-adapter | ferrochain-mcp | integration | BC-2.09.004 | 3 | draft |
| VP-005 | MultiServerMcpClient Holds No Live Connections | mcp-client | ferrochain-mcp | integration | BC-2.09.005 | 3 | draft |
| VP-006 | injection_guard Fail-Closed | injection_guard | ferrochain-prompts | Kani | BC-2.18.004 | 6 | draft |
| VP-007 | LcSerializable Round-Trip | serializable | ferrochain-core | proptest | BC-2.19.001 | 3 | draft |
| VP-008 | Embeddings Dimensionality Contract | embeddings | ferrochain-core | proptest | BC-2.22.001 | 3 | draft |
| VP-009 | Zero-Norm Cosine Guard | vectorstores-similarity | ferrochain-vectorstores | Kani | BC-2.21.003 | 6 | draft |
| VP-010 | Reviver Allowlist Containment | serializable-reviver | ferrochain-core | Kani | BC-2.19.005 | 6 | draft |

**Totals: 10 VPs | Kani: 6 | proptest: 2 | fuzz: 0 | integration: 2**

## Per-Module Coverage Status

> This table covers all 41 architecture modules (35 pre-D21 + 5 added by D21 VP layer + 1 from F-P129-11 split).
> Tier groupings: CRITICAL 11 / HIGH 16 / MEDIUM 12 / LOW 2 (D21 established CRITICAL 11 / HIGH 16 / MEDIUM 11, with vectorstores-mmr classified CRITICAL as the VP-009 host; F-P129-11 burst-224 adds vectorstores-similarity as the new CRITICAL VP-009 host and reclassifies vectorstores-mmr CRITICAL → MEDIUM — net CRITICAL unchanged at 11, MEDIUM +1 = 12).

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
| injection_guard | ferrochain-prompts | VP-006 | — | — | yes | D21/SS-18; prompt injection safety; Kani P1 (BC-2.18.004) |
| serializable | ferrochain-core | — | VP-007 | — | yes | D21/SS-19; LcSerializable round-trip; proptest P1 (BC-2.19.001) |
| serializable-reviver | ferrochain-core | VP-010 | — | — | yes | D21/SS-19; allowlist containment; Kani P0 red_gate (BC-2.19.005) |
| vectorstores-similarity | ferrochain-vectorstores | VP-009 | — | — | yes | D21/SS-21; shared cosine_similarity primitive; zero-norm guard; Kani P0 red_gate (BC-2.21.003) |
| vectorstores-mmr | ferrochain-vectorstores | — | — | — | yes | D21/SS-21; MMR selection algorithm; calls vectorstores::similarity::cosine_similarity |
| embeddings | ferrochain-core | — | VP-008 | — | yes | D21/SS-22; dimensionality contract; proptest P1 (BC-2.22.001) |

## Coverage by Criticality Tier

| Tier | Modules | Kani VPs | proptest | fuzz | Kill Rate Target |
|------|---------|---------|---------|------|-----------------|
| CRITICAL | 11 | 5 (VP-001, VP-002, VP-003, VP-009, VP-010) | all | subset | ≥ 95% |
| HIGH | 16 | 1 (VP-006) | most + VP-007, VP-008 | subset | ≥ 90% |
| MEDIUM | 12 | 0 | some | — | ≥ 80% |
| LOW | 2 | 0 | — | — | ≥ 70% |

## Mutation Kill Rate Gates (cargo-mutants)

Kill rate gates are Phase-5 adversarial gates. Phase-3 per-story gates apply to CRITICAL modules only.

| Tier | Gate | Phase |
|------|------|-------|
| CRITICAL | ≥ 95% | Phase 3 (per story) + Phase 5 |
| HIGH | ≥ 90% | Phase 5 |
| MEDIUM | ≥ 80% | Phase 5 |
| LOW | ≥ 70% | Phase 5 advisory |
