---
document_type: analysis-state-checkpoint
corpus: adk-rust
version: v1.0.0
sha: a6c79b6f
pass: A7
status: complete
timestamp: 2026-07-13T21:30:00Z
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

- `adk-realtime` CAN pull `native-tls` via the OPTIONAL `livekit` feature (default builds use rustls; native-tls is feature-gated, not unconditional) — **conditional conflict** with ferrochain rustls-only rule if `livekit` feature is enabled; adk-realtime is otherwise rustls by default <!-- [comparative-cert-2] CORRECTION (C2 propagation): A6 C2 + A7 C2 both explicitly stated "the flat flag should carry the 'livekit-only, feature-gated, first-party-sole' qualifier"; correction was noted in A6/A7 but not applied; applied here; see P-93 and ANALYSIS-STATE C2/C4 -->
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

## Pass A7 — Convergence Deepening round 2 (COMPLETE)

Read the four A6-named residual threads at function-level depth + closed the one remaining A6-named
unread path. Full detail in patterns-observed.md "Pass A7 deepening" (P-88..P-97). Rust-blindness held.

### Per-item novelty verdicts

| # | Thread (A6-named residual) | Verdict | New patterns | Finding summary |
|---|----------------------------|---------|--------------|-----------------|
| 1 | adk-realtime `gemini/session.rs` internals (RequiresResumption teardown/rebuild in depth) | **MED** | P-88, P-89 | Depth-confirms P-80: `mutate_context` always returns `RequiresResumption`; `execute_resumption` does deterministic teardown (Close frame routed through the single writer channel, awaits writer `JoinHandle`, never holds lock across `.await`) then rebuild via `model.connect`. Resumption token threaded end-to-end (server `resumptionToken` → `config.extra["resumeToken"]` → setup `SessionResumptionConfig.handle`; documented client-`handle`/server-`resumptionToken` asymmetry). NEW: audio_buffer is NOT flushed before close — teardown/interrupt/clear silently drop trailing <40ms PCM (P-88). Translation lossy on 3 axes: silent base64-decode `unwrap_or_default`, multi-call truncation (`calls.first()`), empty synthesized ids (P-89). Refines, does not overturn, the P-80 model. |
| 2 | Avatar providers + keep-alive mechanics | **MED** | P-90, P-91 | `spawn_keep_alive` skips first tick, loops on interval, **fail-CLOSED** (stops on `is_active()==false` OR `keep_alive()` Err) — opposite of the fail-open event loop. The trait abstracts two opposite topologies: HeyGen = server-relay (LiveKit room + NativeAudioSource publish; `keep_alive` = POST /streaming.task), D-ID = client-direct (SDP/ICE returned to client; `send_audio` + `keep_alive` are no-ops) (P-90). Both providers: timeout-less `reqwest::Client::new()` + library-constructor `assert!` panic on non-HTTPS; good secret hygiene (SecretString/redacted/ExposeSecret) (P-91). New behavioral model for a previously code-path-only area. |
| 3 | livekit bridge — sole native-tls ingress; feature isolation | **LOW** | P-92, P-93 | Thin (~600 LOC/6 files), `livekit`-feature-gated, re-exports livekit types; typestate builder (`Missing`/`Present`) enforces identity-before-connect; audio push is fail-open; delegation proptest-covered, live FFI + `Room::connect` `#[ignore]`-gated (P-92). native-tls reconciliation: **exactly one first-party explicit native-tls opt-in workspace-wide** = `livekit` in root Cargo.toml; A5's other two "chains" (mistralrs/hf-hub, audio/hf-hub) are TRANSITIVE via hf-hub defaults, not first-party declarations. Clarifies (does not contradict) A5. Corroborates C2. (P-93). Mostly confirms isolation. |
| 4 | a2a-v1 retry/caching dynamic behavior (confirm-from-source; flag UNVERIFIABLE) | **MED** | P-94, P-95, P-96 | SOURCE-CONFIRMED + refined: retry is **JSON-RPC-unary-only** (`send_with_retry` invoked only by `jsonrpc_call`; the 8 REST + 2 streaming ops are single-shot); backoff `base·2^(n-1)`, no jitter/cap/Retry-After; **timeout-retry branch near-dormant** because no `.timeout()` is set (C1) → covers 429/5xx in practice (P-94). Card "caching" is conditional-**revalidation** only — the stored `cache.card` is write-only, never served back; 304→`Ok(None)` (P-95). Server emits real ETag (SipHash) + Last-Modified; matches_etag handles quoted/unquoted/wildcard; version negotiation `["0.3","1.0"]`, -32009/400. **Two divergent retry impls** (client 429/5xx/timeout vs server-push retries-all-failures + SSRF `validate_webhook_url`) (P-96). **UNVERIFIABLE-without-runtime (grep-confirmed: zero mock servers in adk-server):** backoff timing, 304 round-trip, -32009 round-trip shape-coupling, push SSRF+retry delivery — validation-phase, not closable statically. |
| 5 | Any thread left below deep — enumerate & close | **LOW** | P-97 | The only remaining A6-named unread path was `openai/webrtc.rs`. Closed: a full alternate transport (OpusCodec via audiopus + `OpenAIWebRTCSession` via str0m Sans-IO WebRTC; rustls-compatible, no native-tls), `openai-webrtc`-feature-gated + cmake-dependent, implementing the same `RealtimeSession` contract ⇒ governed identically by the runner FSM (P-80). No new governing mechanism. No residual A6-named thread left unread at depth. |

### Pattern count update

| Pass | Patterns Added | Running Total | STRONG | NEUTRAL | WEAK | INFO |
|------|---------------|---------------|--------|---------|------|------|
| A7 | 10 (P-88..P-97) | 97 | 0 | 5 | 4 | 1 |

(A7: P-88/P-89/P-90/P-96 NEUTRAL; P-91/P-93/P-94/P-95 WEAK; P-92 NEUTRAL; P-97 INFO. Running totals
across A1–A7: 97 patterns.)

### Contradictions vs prior passes (maintained list)

- **C1 (CORRECTION, from A6) — reqwest timeout-less site count.** UNCHANGED and REINFORCED: A7 found
  the same pattern in avatar providers (P-91) and both a2a-v1 clients (P-94), and observed a
  downstream consequence — the a2a-v1 client's `is_timeout()` retry branch is structurally near-dormant
  precisely because no `.timeout()` is set. Timeout-absence remains systemic (workspace-wide MAP).
- **C2 (REFINEMENT, from A6) — adk-realtime native-tls "HARD CONFLICT."** UNCHANGED and REINFORCED by
  P-93: the only first-party explicit `native-tls` opt-in workspace-wide is the `livekit` dep in root
  Cargo.toml; native-tls rides only the optional `livekit` feature; adk-realtime defaults to rustls.
  The flat A5 compliance flag should carry the "livekit-only, feature-gated, first-party-sole" qualifier.
- **C3 (SOURCE-INTERNAL, from A6) — adk-code Docker capability claim vs behavior.** UNCHANGED (not
  re-examined in A7; out of A7 thread scope).
- **C4 (CLARIFICATION, surfaced A7) — "three native-tls chains" (A5 dependency-disposition) vs "sole
  native-tls ingress" (A6/A7 realtime).** NOT a contradiction: A5's three-chain count includes
  TRANSITIVE exposure via hf-hub defaults (mistralrs, audio); A6/A7's "sole ingress" refers to (a) the
  sole native-tls ingress *within adk-realtime* and (b) the sole *first-party explicit* opt-in
  workspace-wide. Both statements are true at their respective scopes. Recorded to prevent a
  certification-cascade false-positive. (P-93)
- **C5 (SOURCE-INTERNAL, surfaced A7) — a2a-v1 dual retry policy divergence.** Within the same protocol
  family, the client retry (`A2aV1Client::send_with_retry`, retries 429/5xx/timeout, JSON-RPC-unary
  only) and the server push retry (`HttpPushNotificationSender::send_with_retry`, retries ANY
  non-success + any send error, all bindings, + SSRF guard) implement different policies. Internal
  inconsistency, not a cross-pass conflict — flag to certification as a source-fidelity note. (P-96)

### Open Items (post-A7 status)

| Item | Status |
|------|--------|
| adk-realtime gemini/session.rs internals | **RESOLVED (A7)** — P-88/P-89 |
| Avatar providers + keep-alive mechanics | **RESOLVED (A7)** — P-90/P-91 |
| livekit bridge delegation/isolation | **RESOLVED (A7)** — P-92/P-93 |
| a2a-v1 retry/caching dynamic behavior | **SOURCE-RESOLVED (A7)** — P-94/P-95/P-96; four dynamic behaviors flagged UNVERIFIABLE-without-runtime (carry to validation, NOT an analysis gap) |
| openai/webrtc.rs SDP transport | **RESOLVED (A7)** — P-97 |
| ADR: unify graph-checkpoint + session persistence | **OPEN — ferrochain Phase-1 design decision** (not an adk-rust novelty gap) |

## Overall Analysis-Convergence Verdict (post-A7)

**CONVERGED (analytically).** Every thread the A6 verdict named as "not yet read at function-level
depth" is now read and closed to an explicit verdict (threads 1–5 above). A7's novelty is
**MED-trending-LOW**: it produced genuine new behavioral detail (audio-loss-on-teardown, lossy Gemini
translation, two-topology avatar abstraction, retry-scope asymmetry, write-only card cache,
dual-retry+SSRF) but **every finding is a refinement WITHIN a subsystem A6 already surfaced — no new
subsystem, no new governing mechanism, and no overturned model.** This is the expected novelty-decay
signature (A1–A5 broad+deep → A6 HIGH on first-depth reads → A7 MED/LOW on re-reads).

Honesty check (per task discipline — do not force convergence): the only unknowns that remain are the
four a2a-v1 **UNVERIFIABLE-without-runtime** items (backoff timing, 304 round-trip, -32009 shape
coupling, push SSRF/retry delivery). These are NOT unread code — the logic is fully read and
internally consistent — they are *undynamicized* behaviors requiring a mock-server or live harness. No
further STATIC analysis pass can close them; they belong to the validation phase (Phase 4 / DTU or
holdout). Therefore they do not constitute an analysis gap and do not block a converged verdict.

**A potential A8 would find only NITPICKS** (byte-level edge cases, further doc-comment precision).
There is no named SUBSTANTIVE static thread remaining. The corpus is exhausted as an analytical corpus
(D16). Recommendation: **stop analysis passes; proceed to spec crystallization**, carrying the four
UNVERIFIABLE-without-runtime a2a-v1 items forward as validation-phase test obligations, and carrying
C1–C5 into the certification cascade as known-corrections/source-fidelity notes.
