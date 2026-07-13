---
document_type: analysis-state-checkpoint
corpus: adk-rust
version: v1.0.0
sha: a6c79b6f
pass: A3
status: complete
timestamp: 2026-07-13T08:00:00Z
---

# adk-rust Comparative Analysis State

## Pass A1 — Broad Sweep + Deep Core (COMPLETE)

### Summary

- **Scope:** All 39 crates (~242k in-workspace code LOC); deep analysis on 6 core crates
- **Patterns catalogued:** 19 total (10 STRONG / 4 NEUTRAL / 5 WEAK)
- **Layering:** Clean 5-tier hub-and-spoke; adk-core is ZERO-intra-workspace-dependency trait hub + unified AdkError

### STRONG Patterns (10)

1. Two-dimensional component×category error taxonomy with total tested retryability/HTTP mappings
2. Retry-as-combinator with layered delay precedence
3. `is_final_response` 11-case truth-table predicate
4. Supertrait least-privilege context ladder
5. Drop-guaranteed cancellation cleanup
6. (Remaining 5 catalogued in patterns-observed.md)

### NEUTRAL Patterns (4)

See patterns-observed.md for full catalogue.

### WEAK Patterns (5)

1. 2,712-line `llm_agent.rs` + ~800-line stream closure — FAILS ferrochain D12 750-line hard gate
2. Duplicated Anthropic/Gemini provider surfaces: in-tree module AND standalone crates (drift risk)
3. Cache-key-by-agent-description proxy (brittle; description mutation = silent cache invalidation)
4. `anyhow` alongside `AdkError` leak risk — unverified in deep passes; OPEN ITEM
5. Correctness-bearing capability defaults (silent cross-project memory bleed risk)

### Compliance Flags

- `adk-realtime` pulls `native-tls` via `livekit` — HARD CONFLICT with ferrochain rustls-only rule (CLAUDE.md)
- `reqwest` uses `rustls-tls-native-roots` (different root store from ferrochain default) — deliberate MAP consideration

## Open Items (queued for deep passes)

| Item | Target Pass | Status |
|------|-------------|--------|
| Verify `anyhow`-in-public-signatures extent | A2 or A3 | PARTIAL — A3 confirmed clean in library code, confined to CLI binaries; FINAL verdict deferred to A5 |
| Clarify `adk-model` vs standalone provider crate relationship and drift surface | A2 | OPEN — P-16 (duplication observation) recorded; resolution deferred to A5 |
| Locate all `reqwest` timeout construction sites | A3 | RESOLVED — P-42: 7 sites across server/auth/awp/acp/managed/enterprise, ALL without `.timeout()`; confirmed counter-example |
| Classify ignored-vs-runnable integration tests | A2/A3 sweep | OPEN — carry to A4/A5 |
| ADR question: unify graph-checkpoint + session persistence on one store | NEW (raised A2) | OPEN — ferrochain design decision at Phase 1 |

## Deep Pass Status

| Pass | Cluster | Crates | Status |
|------|---------|--------|--------|
| A1 | Broad sweep + 6 deep core crates | all 39 crates; deep: adk-core, adk-agent, adk-runner, adk-model, adk-graph (surface), adk-session (surface) | COMPLETE — 19P (10S/4N/5W) |
| A2 | State / persistence / orchestration | adk-graph, adk-session, adk-memory, adk-artifact | COMPLETE — 15P P-20..P-34 (5S/3N/7W) |
| A3 | Server / platform / protocol | adk-server, adk-runner, adk-awp, adk-acp, adk-auth, adk-telemetry, adk-cli | COMPLETE — 12P P-35..P-46 (4S/2N/6W) |
| A4 | Safety / quality cluster | adk-guardrail, adk-sandbox, adk-eval, adk-retry-reflect, adk-skill, adk-plugin, adk-code, adk-browser | DISPATCHED — in progress |
| A5 | Provider / capability cluster | adk-realtime, adk-providers, adk-protocols, adk-payments + P-16 duplication resolution + final anyhow verdict | DISPATCHED — in progress |

## Pattern Count Summary

| Pass | Patterns Added | Running Total | STRONG | NEUTRAL | WEAK |
|------|---------------|---------------|--------|---------|------|
| A1 | 19 (P-01..P-19) | 19 | 10 | 4 | 5 |
| A2 | 15 (P-20..P-34) | 34 | 5 | 3 | 7 |
| A3 | 12 (P-35..P-46) | 46 | 4 | 2 | 6 |
