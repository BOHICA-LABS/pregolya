---
document_type: analysis-state-checkpoint
corpus: adk-rust
version: v1.0.0
sha: a6c79b6f
pass: A1
status: complete
timestamp: 2026-07-13T00:00:00Z
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

| Item | Target Pass |
|------|-------------|
| Verify `anyhow`-in-public-signatures extent | A2 or A3 |
| Clarify `adk-model` vs standalone provider crate relationship and drift surface | A2 |
| Locate all `reqwest` timeout construction sites | A3 |
| Classify ignored-vs-runnable integration tests | A2/A3 sweep |

## Queued Deep Passes

| Pass | Cluster | Crates | Status |
|------|---------|--------|--------|
| A2 | State / persistence / orchestration | adk-graph, adk-session, adk-memory, adk-artifact | DISPATCHED — in progress |
| A3 | Server / platform / protocol | adk-server, adk-runner, adk-awp, adk-acp, adk-auth, adk-telemetry, adk-cli | DISPATCHED — in progress |
| A4 | Quality / safety | adk-guardrail, adk-sandbox, adk-eval | queued |
| A5 | Integration / providers | adk-realtime, adk-providers, adk-protocols, adk-payments | queued |
| A6 | Retry / reflection deep dive | adk-core retry combinator, cross-crate retry usage | queued |
