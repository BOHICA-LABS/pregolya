---
document_type: analysis-state-checkpoint
corpus: adk-rust
version: v1.0.0
sha: a6c79b6f
pass: A6
status: complete
timestamp: 2026-07-13T18:00:00Z
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
| A6 | 8 (P-80..P-87) | 87 | 1 | 3 | 4 |

## Pass A6 — Convergence Deepening (COMPLETE)

Worked the residual open/deferred items to explicit novelty verdicts, highest spec-impact first.
Full detail in patterns-observed.md "Pass A6 deepening" (P-80..P-87).

### Per-item novelty verdicts

| # | Item | Verdict | New patterns | Finding summary |
|---|------|---------|--------------|-----------------|
| 1 | adk-realtime bidi audio FSM (VAD/barge-in/turn-taking) | **HIGH** | P-80, P-81 | 4-state runner FSM + provider-agnostic "Phantom Reconnect" (native-mutate vs teardown/rebuild), last-write-wins single-slot queue, 3-attempt retry budget, fail-open event loop (P-80). Barge-in is server-VAD-delegated; client loop never auto-`interrupt()`s on SpeechStarted; `interrupt()` is manual; Gemini drops manual `ResponseCancel` (P-81). Domain C reference. |
| 2 | Sandbox: Windows AppContainer + adk-code Docker isolation | **HIGH** | P-82, P-83 | Windows enforcer is a documented hard-fail stub — `configure_command` returns `EnforcerFailed`; no working Windows sandbox path (unsandboxed-or-error); Linux bwrap + macOS seatbelt are real (P-82). adk-code `DockerExecutor.execute()` IGNORES per-request `SandboxPolicy` (net/fs/env) despite `capabilities()` advertising enforcement — uses static `DockerConfig`; no `--user`/`--read-only`/`--memory`/`--cpus`/`--pids-limit`/`--cap-drop`; DoS bounded only by timeout (P-83). Domain A/C. |
| 3 | Ignored-vs-runnable integration-test census (attr-only) | **MED** | — | 4,803 test attrs / 150 proptest / **126 `#[ignore]` (≈2.6%)** / 19 live-API-gated files. Ignores dominated by external deps (keys, HF weights, npx/Vertex), not broken tests; most carry reason strings. Reconciles with A4 (~617) + A5 (~1,849) cluster subsets. Closes the PARTIAL census item. |
| 4 | adk-rag vector-store contracts + thin-test claim | **MED** | P-84 | Thin-test VERIFIED: qdrant/pgvector/lancedb have ZERO tests (4/6 backends untested); only chunking/inmemory/surrealdb tested. NEW: `InMemoryVectorStore` discards declared `dimensions` and never dim-checks; `cosine_similarity` truncate-zips → silent garbage scores on mismatch, diverging from DB backends that enforce dims engine-side. |
| 5 | Skill ContextCoordinator negative path | **MED** | P-87 | Phantom-tool prevention is real + well-tested (instruction built only from resolved `active_tools`). Strict mode: validation error swallowed (`Err => continue`), caller can't distinguish no-match from tools-missing. Permissive: missing tools silently omitted (comment concedes embedder must monitor). Both modes HIGH-confidence tested. |
| 6 | a2a client (RemoteA2aAgent / A2aClient) behavioral read | **HIGH** | P-85, P-86 | UPGRADES A3 signature-depth. All transport/RPC failures surfaced as error EVENTS (`turn_complete`, `error_message`), never stream `Err` — remote failure looks like a completed turn (P-85). Dual client generations: legacy `A2aClient` (no retry/version) + feature-gated `A2aV1Client` (11 ops, JSON-RPC+REST, exp-backoff retry on 429/5xx/timeout, version negotiation -32009, ETag card caching); SSE parser triplicated; transport paths untested (P-86). |
| 7 | Residual open items (ADR unify graph-checkpoint+session) | **LOW** | — | The "unify graph-checkpoint + session persistence on one store" item is a **ferrochain Phase-1 design decision**, not an adk-rust analysis gap — remains OPEN as a ferrochain-side decision (see below). No other ANALYSIS-STATE item left open. |

### Open Items (post-A6 status)

| Item | Status |
|------|--------|
| Verify `anyhow`-in-public-signatures extent | RESOLVED (A5) |
| adk-model vs standalone provider crate relationship | RESOLVED (A5, P-16/P-67) |
| Locate all `reqwest` timeout construction sites | **CORRECTED (A6)** — see Contradiction C1: workspace-wide ~79 client-construction sites in production `src`, only ~10 carry `.timeout()` (~69 timeout-less). A3 P-42's "7 sites" was cluster-scoped (server/auth/awp/acp/managed/enterprise) and under-counted; timeout-absence is systemic (providers, rag, payments, a2a clients all affected). |
| Classify ignored-vs-runnable integration tests | **RESOLVED (A6)** — census above (126 `#[ignore]`, ≈2.6%). |
| Sandbox default posture (Domain C) | RESOLVED (A4 P-60/61/62) + EXTENDED (A6 P-82 Windows, P-83 Docker). |
| ADR: unify graph-checkpoint + session persistence | **OPEN — ferrochain Phase-1 design decision** (not an adk-rust novelty gap; carry to architecture phase). |

### Contradictions vs prior passes (for the certification cascade — known-corrections)

- **C1 (CORRECTION) — reqwest timeout-less site count.** A3 P-42: "7 sites … ALL without `.timeout()`,
  confined to server/auth/awp/acp/managed/enterprise." A6 workspace-wide: ~79 `reqwest::Client::new()`/
  `builder()` sites in production `src`, only ~10 with `.timeout()` → ~69 timeout-less, spanning
  providers (anthropic/gemini/model), rag, payments, and BOTH a2a clients. P-42's count is a subset,
  not the total. Timeout-absence is a **systemic** counter-example to ferrochain's mandatory-30s rule,
  not a 7-site cluster. (Spec impact: NFR/error-taxonomy should assume workspace-wide timeout MAP, not a
  localized fix.)
- **C2 (REFINEMENT) — adk-realtime native-tls "HARD CONFLICT".** The ANALYSIS-STATE A5 compliance flag
  states adk-realtime "pulls `native-tls` via `livekit` — HARD CONFLICT" as a flat statement.
  patterns-observed P-79 already refines this ("contained to optional features"). Correction: adk-realtime
  DEFAULTS to rustls (declares `rustls` w/ aws-lc-rs; `google-cloud-auth` `default-rustls-provider`;
  OpenAI/Gemini transports over tokio-tungstenite+rustls). native-tls rides ONLY the OPTIONAL `livekit`
  feature. The conflict is feature-gated, not unconditional — the flat flag should carry the "livekit-only"
  qualifier.
- **C3 (SOURCE-INTERNAL contradiction, surfaced A6) — adk-code Docker capability claim vs behavior.**
  `DockerExecutor::capabilities()` advertises `enforce_filesystem_policy/enforce_network_policy/
  enforce_environment_policy = true`, but `execute()` ignores the per-request `SandboxPolicy` for those
  three axes (honors only timeout + output caps); isolation comes from the construction-time `DockerConfig`.
  This is a contradiction *within the source* (self-declared capability vs actual per-request behavior),
  not between analysis passes — flag to certification as a source-fidelity note. The CLI
  `ContainerCommandExecutor` does NOT have this gap (it maps the per-request policy).

Note on candidate contradiction (RESOLVED, not a contradiction): the A6 workspace test-attribute total
(4,803) vs A4 "~617" / A5 "~1,849" is a SCOPE difference (workspace vs safety cluster vs provider cluster),
not a conflict — the cluster figures are subsets of the workspace total.

## Overall Analysis-Convergence Verdict

**NOT YET CONVERGED (near-converged).** A6 resolved all named residual items but produced two **HIGH**-novelty
areas (realtime FSM P-80/P-81; a2a client behavior P-85/P-86) and one systemic correction (C1), so the
"all items LOW" bar for CONVERGED is not met. The model materially changed for realtime, sandbox-Windows,
and a2a. Remaining substantive threads NOT yet read at function-level depth (candidates for an optional A7,
if pursued):

- adk-realtime `gemini/session.rs` internals (writer-task teardown ordering, `sessionResumptionUpdate`
  wire handling, audio flush buffer) and the `openai/webrtc.rs` SDP/offer path — only the OpenAI WS + runner
  FSM were read at depth.
- adk-realtime avatar providers (`avatar/heygen`, `avatar/did`) + `spawn_keep_alive` lifecycle — flagged in
  P-80 code path but not behaviorally analyzed.
- adk-realtime `livekit/*` bridge (the sole native-tls ingress) — delegation behavior unread at depth.
- a2a v1 retry/caching/transport behavior is source-verified but UNTESTED (mock-server gap) — no dynamic
  confirmation of backoff/304 semantics.

Recommendation: the corpus is analytically sufficient for spec crystallization on all Domain A/B/C surfaces
covered; an A7 targeting the four realtime-internal threads above would be SUBSTANTIVE but is optional and
lower-priority than proceeding, given P-80 already captures the governing realtime mechanism.
