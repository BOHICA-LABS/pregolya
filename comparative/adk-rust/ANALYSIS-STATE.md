---
document_type: analysis-state-checkpoint
corpus: adk-rust
version: v1.0.0
sha: a6c79b6f
pass: A5
status: complete
timestamp: 2026-07-13T12:00:00Z
---

# adk-rust Comparative Analysis State

## Pass A1 — Broad Sweep + Deep Core (COMPLETE)

### Summary

- **Scope:** All 39 crates (~233k in-workspace code LOC by tokei workspace-src; ~242k original estimate); deep analysis on 6 core crates <!-- [comparative-sweep] tokei workspace member src dirs → 233,425 Rust code lines; original ~242k is at the high end; delta ~9k -->
- **Patterns catalogued:** 19 total (10 STRONG / 4 NEUTRAL / 5 WEAK)
- **Layering:** Clean 5-tier hub-and-spoke; adk-core is ZERO-intra-workspace-dependency trait hub + unified AdkError

### STRONG Patterns (10)

1. Two-dimensional component×category error taxonomy with total tested retryability/HTTP mappings
2. Retry-as-combinator with layered delay precedence
3. `is_final_response` 9-case truth-table predicate <!-- [comparative-sweep] corrected from 11: grep shows 9 fn test_is_final_response_* in event.rs -->
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
| Verify `anyhow`-in-public-signatures extent | A2 or A3 | RESOLVED (A5) — FINAL verdict: NOT a systemic leak. One variant only (`adk-mistralrs::MistralRsError::Other(#[from] anyhow::Error)`, P-78) + one dead dep (adk-model declares, never uses); core + all other library crates clean; binaries permitted |
| Clarify `adk-model` vs standalone provider crate relationship and drift surface | A2 | RESOLVED (A5) — P-16: NOT duplication. Standalone SDK (`adk-anthropic`/`adk-gemini`, zero-adk-dep) + thin `Llm`-trait adapter in `adk-model` that WRAPS it (`fn inner()`, compile-time type coupling). SDK canonical for wire, adapter for trait. Drift risk LOW (was A1-assumed HIGH). See patterns P-67 |
| Locate all `reqwest` timeout construction sites | A3 | RESOLVED — P-42: 7 sites across server/auth/awp/acp/managed/enterprise, ALL without `.timeout()`; confirmed counter-example |
| Classify ignored-vs-runnable integration tests | A2/A3 sweep | PARTIAL — A4 cluster: ~617 test markers (attribute-only; corrected from ~961 — see SWEEP-test-deps.md); adk-sandbox (5 proptest) + adk-code (7 proptest/10 integ) high-rigor; browser tools likely driver-gated. Full ignored-test census carry to A5 <!-- [comparative-sweep] proptest file counts corrected; original used double-counting methodology --> |
| `anyhow`/`reqwest` in safety-cluster | A4 | RESOLVED — anyhow = 1 doc-example (browser), no leak; reqwest absent in cluster (browser uses thirtyfour) |
| Guardrail untrusted-content ingress (Domain A) | A4 | RESOLVED (as GAP) — P-59: guardrails see only initial input + final output, never tool/RAG/memory content |
| Sandbox default posture (Domain C) | A4 | RESOLVED (as GAP) — default ProcessBackend no isolation (P-61); macOS reads unrestricted (P-60); adk-code Rust exec unenforced (P-62) |
| ADR question: unify graph-checkpoint + session persistence on one store | NEW (raised A2) | OPEN — ferrochain design decision at Phase 1 |

## Deep Pass Status

| Pass | Cluster | Crates | Status |
|------|---------|--------|--------|
| A1 | Broad sweep + 6 deep core crates | all 39 crates; deep: adk-core, adk-agent, adk-runner, adk-model, adk-graph (surface), adk-session (surface) | COMPLETE — 19P (10S/4N/5W) |
| A2 | State / persistence / orchestration | adk-graph, adk-session, adk-memory, adk-artifact | COMPLETE — 15P P-20..P-34 (5S/3N/7W) |
| A3 | Server / platform / protocol | adk-server, adk-runner, adk-awp, adk-acp, adk-auth, adk-telemetry, adk-cli | COMPLETE — 12P P-35..P-46 (4S/2N/6W) |
| A4 | Safety / quality cluster | adk-guardrail, adk-sandbox, adk-eval, adk-retry-reflect, adk-skill, adk-plugin, adk-code, adk-browser | COMPLETE — 20P P-47..P-66 (8S/4N/8W) |
| A5 | Provider / capability cluster | adk-model providers, adk-anthropic, adk-gemini, adk-mistralrs, adk-realtime, adk-rag, adk-audio, adk-payments, adk-action, adk-bench, adk-rust-macros + P-16 resolution + final anyhow verdict | COMPLETE — 13P P-67..P-79 (7S/2N/4W); P-16 RESOLVED (SDK+adapter, not duplication); anyhow FINAL (1 variant); 3 native-tls chains |

## Pattern Count Summary

| Pass | Patterns Added | Running Total | STRONG | NEUTRAL | WEAK |
|------|---------------|---------------|--------|---------|------|
| A1 | 19 (P-01..P-19) | 19 | 10 | 4 | 5 |
| A2 | 15 (P-20..P-34) | 34 | 5 | 3 | 7 |
| A3 | 12 (P-35..P-46) | 46 | 4 | 2 | 6 |
| A4 | 20 (P-47..P-66) | 66 | 8 | 4 | 8 |
| A5 | 13 (P-67..P-79) | 79 | 7 | 2 | 4 |
