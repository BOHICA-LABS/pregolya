---
artifact: comparative/assessment-parts/part-2-dispositions-p51-p97
directive: D16
scope: "P-51 through P-97 (47 patterns)"
rust_blindness: ENFORCED — language carries zero evidentiary weight; patterns judged on
  production-grade merit only (test depth, failure-mode handling, security posture,
  operational maturity)
anti_sunk_cost: ENFORCED — prior semport investment earns LangChain semantics nothing
binding_constraints: [D4 single-workspace, D7 core→graph→partners, D11 HYBRID engine
  msgpack sync-default, D12 500/750-line gate, D13 ferrochain-server first-party]
created: 2026-07-13
status: complete
part: 2-of-4
patterns_range: P-51..P-97
---

# D16 Comparative Assessment — Part 2: Pattern Dispositions P-51 through P-97

<!-- SKELETON WRITTEN FIRST PER DIRECTIVE; sections filled sequentially -->

## Summary Counts

| Disposition | Count |
|-------------|-------|
| ADOPT | 7 |
| ADAPT | 7 |
| REJECT | 11 |
| NOT-APPLICABLE | 22 |
| **Total** | **47** |

Human-gate flags (high-stakes decisions): see end of document.

---

## 1. Skills / Capability-Coordination Cluster (P-51, P-56, P-87)

> adk source: `adk-skill` — coordinator, discovery, parser, select; `adk-core::ToolRegistry`

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-51 | Skill coordinator: phantom-tool prevention | **ADAPT** | Instruction↔tool binding atomically validated at selection time prevents hallucinated tool references. This is a strong correctness principle for any agent that receives a system prompt + tool list. Adapt: apply the validation logic in ferrochain agent config assembly (not the .skills/ discovery mechanism, which is adk-specific). | ADR: agent-config tool-binding validation; Domain A/B forcing function |
| P-56 | Content-addressed skill identity + layered discovery | **NOT-APPLICABLE** | `.skills/` discovery, SHA256 content identity, lexical overlap ranking are adk-specific runtime concerns with no analog in ferrochain's LangChain/LangGraph port scope. | — |
| P-87 | Coordinator strict-mode errors swallowed to `None` | **REJECT** | Must-not-inherit. Strict-mode validation failure is silently mapped to "no skill matched" — the caller cannot distinguish missing skill from unregistered tools. Violates CLAUDE.md no-silent-empty-return. Ferrochain agent config validation must surface a typed error identifying which tools are unregistered. | BC: agent-config validation returns typed `Err`, never silent `None` |

---

## 2. Plugin / Middleware / Callbacks Cluster (P-52, P-58)

> adk source: `adk-plugin` — `Plugin`, `PluginConfig`, `EnhancedPlugin`, `EnhancedPluginManager`

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-52 | Priority-ordered plugin pipeline (before/after + ShortCircuit + priority bands) | **ADOPT** | before/after hooks with Continue | ShortCircuit semantics, ascending priority (lower = earlier), documented bands (0–25 security, …100+ app), Err propagation that halts the chain — this maps cleanly to ferrochain callbacks and enforces security-first ordering by convention. The explicit Continue/ShortCircuit enum prevents the silent "swallowed by middleware" bug class. | BC for ferrochain callback chain; budget-gate hook placement (Domain B) |
| P-58 | Dual parallel plugin models (closure `Plugin` + trait `EnhancedPlugin`) | **REJECT** | Must-not-inherit. Two plugin/middleware models sharing the same hook surface invite drift, ambiguous "which do I use" ergonomics, and maintenance divergence. Ferrochain must pick ONE callback model from the start. The trait-based `EnhancedPlugin` (priority + typed return) is the stronger design if a choice must be made. | — |

---

## 3. Evaluation / Quality-Gates Cluster (P-53, P-64)

> adk source: `adk-eval` — `Evaluator`, `ToolTrajectoryScorer`, `ResponseScorer`, `LlmJudgeConfig`; `adk-eval::schema`

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-53 | Declarative eval harness (datasets + multi-criteria scoring) | **ADAPT** | The `.test.json`/`.evalset.json` declarative dataset schema, the tool-trajectory scorer (ordered/unordered, strict/partial args), and the deterministic text-similarity scorers (Levenshtein/ROUGE with Unicode tokenizer, all unit-tested) are liftable as ferrochain holdout-eval foundations. Adapt: fix the P-64 scoring defects (order-independent aggregation, distinct judge-error outcome, single agent run per case), and substitute ferrochain's error taxonomy throughout. | Phase 4 holdout: candidate BC for dataset schema and trajectory/similarity scorers |
| P-64 | Eval: order-dependent score merge + judge-infra-failure = quality-fail + agent re-runs | **REJECT** | Must-not-inherit. Three defects disqualify: (1) pairwise running `(s1+s2)/2` is not the mean — later turns dominate exponentially; (2) LLM-judge API outage inserts `score: 0.0 / Verdict::Fail` indistinguishable from genuine failure; (3) cost/trace-analyzer config triggers a second nondeterministic agent run per case. Ferrochain eval must use arithmetic mean, a dedicated judge-infrastructure-error outcome (not 0.0), and reuse the single-run event stream. | Phase 4 BC: evaluation correctness invariants |

---

## 4. Browser / Interpolation-Safety Cluster (P-54)

> adk source: `adk-browser::escape`

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-54 | Browser: defensive JS-string escaping for selector interpolation | **NOT-APPLICABLE** | Ferrochain has no browser-automation subsystem. The general principle — escape model/user-derived text before interpolating into an executable substrate (JS, SQL, shell) — is already a standard rule and does not require a new ferrochain design artifact. | — |

---

## 5. Guardrails / Content-Validation Cluster (P-55, P-59)

> adk source: `adk-guardrail` — `Guardrail`, `GuardrailExecutor`, `ContentFilter`, `PiiRedactor`

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-55 | Guardrail trait: Pass/Fail/Transform + severity ladder + parallel/sequential split | **ADAPT** | The three-way result (Pass | Fail{reason, severity} | Transform{new_content}), Severity = Low/Medium/High/Critical, and the parallel-for-independent / sequential-for-transforming execution split form a clean, composable content-validation seam. Adapt: adopt the shape; discard the trivial built-in policies (6-word blocklist is not a defense); place the guardrail executor on the tool-result ingress path (see P-59 reject) rather than only on user-input/final-output. | Domain A BC: guardrail trait shape; content-validation seam |
| P-59 | Guardrails run only on user input + final output; tool/RAG/memory content unguarded | **REJECT** | Must-not-inherit. The entire indirect-prompt-injection attack surface — tool results, retrieval output, memory content entering the model context — receives zero validation. For Domain A (SOC analyst with untrusted indicators) and Domain C (personal memory with user-sourced content) this is the critical gap. Ferrochain must tag content by provenance and run guardrail passes at tool-result ingress, not only at user-input / final-output boundaries. adk-rust is a counter-example here. | Domain A BC: must enforce guardrails at tool-result and RAG ingress |

---

## 6. Sandbox / Code-Execution Cluster (P-57, P-60, P-61, P-62, P-65, P-66, P-82, P-83)

> adk source: `adk-sandbox`, `adk-code`; four known negative-evidence patterns in this range: P-61, P-62, P-65 (per directive), plus P-66

Ferrochain has no sandbox or code-execution subsystem in Phase 1–3 scope. Patterns are NOT-APPLICABLE unless they encode a must-not-inherit principle that could contaminate adjacent work (e.g., file-tool path validation, constructor discipline).

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-57 | `SandboxPolicy::default()` = strict + truthful `BackendCapabilities` flags | **NOT-APPLICABLE** | No sandbox subsystem in scope. If ferrochain ever adds code-execution: strict-by-default + capability flags that match actual enforcement are the correct reference posture. | — |
| P-60 | macOS Seatbelt enforcer allow-by-default for file reads | **NOT-APPLICABLE** | No sandbox in scope. Must-not-inherit if sandbox added: `(allow default)` then selective deny is allow-all-reads regardless of policy; credential exfiltration surface. | — |
| P-61 | Default `ProcessBackend` provides no fs/net/memory isolation; `Language::Command` = raw `sh -c` | **NOT-APPLICABLE** | No sandbox in scope. Known negative-evidence. Must-not-inherit if code-exec added: default-no-isolation posture is the opposite of secure-by-default. | — |
| P-62 | `RustSandboxExecutor` (phase-1) host-local: policy strictness decoupled from enforcement | **NOT-APPLICABLE** | No sandbox in scope. Known negative-evidence. Policy that promises isolation the backend does not deliver is security theater; must-not-inherit. | — |
| P-65 | Workspace path safety is string-only (no symlink resolution) | **NOT-APPLICABLE** | No workspace/file sandbox in scope. Known negative-evidence. If file tools added: must canonicalize + verify real path is beneath root at access time, not string-depth-count only. | — |
| P-66 | `WasmBackend::new()` uses `.expect()` on engine init (panic in library constructor) | **REJECT** | Must-not-inherit regardless of sandbox scope. A library constructor must return `Result` and propagate engine-init failure through the error taxonomy. Panicking in `Default` violates CLAUDE.md no-unwrap/expect-in-non-test convention. | CLAUDE.md: all library constructors return `Result` |
| P-82 | Windows AppContainer enforcer is a hard-fail stub | **NOT-APPLICABLE** | Windows not in ferrochain initial target; no sandbox in scope. | — |
| P-83 | Docker backend ignores per-request `SandboxPolicy`; no resource/privilege hardening | **NOT-APPLICABLE** | No Docker sandbox in scope. If added: advertised enforcement must match actual enforcement; per-request policy must be honored or `BackendCapabilities` must honestly report `false`. | — |

---

## 7. Provider / Partner Cluster (P-67 through P-79)

> adk source: `adk-anthropic`, `adk-gemini`, `adk-model`, `adk-rust-macros`, `adk-payments`, `adk-rag`, `adk-realtime`; D7 partners wave; D5 schemars ADR; CLAUDE.md credential/timeout/rustls/structured-error rules

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-67 | Standalone-vendor-SDK + thin-trait-adapter provider layering | **ADOPT** | Wire contract lives exactly once in the SDK crate (zero framework deps, independently publishable); the adapter in the main crate is compile-time-coupled to SDK types so drift is a build error, not a runtime surprise. This is the correct architecture for ferrochain's partner wave: `ferrochain-anthropic` = wire SDK (reqwest + serde only) + `ferrochain-core` `Llm`-trait adapter. Satisfies D7, D12 file-size gate by construction, and D13 first-party server boundary. **HIGH-STAKES: needs Phase 1 ADR.** | ADR: partner crate architecture — SDK crate vs embedded adapter |
| P-68 | Text-tag tool-call parser for backends without native tool-calling | **ADOPT** | Directly needed for ferrochain-ollama: Ollama-served OSS models (Qwen/Llama/Mistral-Nemo/DeepSeek/Gemma4) frequently emit tool calls as text tags. The per-format parser + 22-unit test suite are liftable test-as-spec. ferrochain-ollama must include an equivalent parser wired before tool-result routing. | ferrochain-ollama BC: text-tag tool-call parsing |
| P-69 | DoS-hardened SSE decoder: buffer/event caps + idle-chunk timeout + TTFB metric | **ADOPT** | Streaming decoders are an unbounded-allocation and hang sink. The 1 MB buffer cap, 64 KB event cap, 30 s idle-chunk timeout (distinct from whole-request timeout), and TTFB metric are the correct production defaults for ALL ferrochain streaming provider decoders. Directly enforces CLAUDE.md mandatory-timeout convention at the stream level. | NFR BC: streaming reliability + TTFB observability |
| P-70 | `AccumulatingStream`: live token yield + assembled final-message, no double-buffer | **ADOPT** | Ferrochain streaming needs exactly this dual role: yield token deltas to the caller AND hand the runner the final assembled message for the event log / checkpoint, without buffering the stream twice. The `tokio::oneshot` for final-message delivery is a clean signal-on-drain pattern. Maps directly to semport/core §1 astream + message accumulation. | ferrochain-core streaming BC |
| P-71 | Shared retry combinator wired across 9/12 providers | **ADOPT** | A single classification+backoff policy at the center is centrally-tunable; per-provider ad-hoc retry loops diverge over time. The 3 justified exceptions (AWS SDK owns retry internally, WebSocket manual loop, ollama-rs owned) prove the rule rather than weakening it. ferrochain partner crates must route through the ferrochain-core retry combinator, not invent per-crate loops. | ferrochain-core BC: retry combinator |
| P-72 | `#[tool]` / `#[entrypoint]` / `#[task]` proc-macros (zero-boilerplate tool + graph wiring) | **ADAPT** | Zero-boilerplate tool wiring (doc-comment→description, schemars→JSON schema, snake_case→tool-name, capability attrs) is a strong DX win that keeps schema derivation honest. The `#[entrypoint]`/`#[task]` graph macros are a clean LangGraph `@entrypoint`/`@task` analog with checkpointing baked in. Adapt: ferrochain naming, integrate schemars per D5 ADR (schemars for owned Rust tool-arg types), validate that capability attr names match ferrochain's trait surface. **HIGH-STAKES: ferrochain macro design needs Phase 1 ADR (intersects D5).** | ADR: ferrochain-macros + D5 schemars placement |
| P-73 | Composable payment-policy guardrail: allow/escalate/deny + integer `Money` + append-only journal | **ADAPT** | adk-rust has NO token/cost budget gate (P-46 gap confirmed). But the payment guardrail's architecture — a composable-policy trait returning allow/escalate/deny with per-finding severity, backed by an append-only evidence journal — is exactly the SHAPE a Domain-B budget-governance primitive wants. Adapt: different domain (token/$ ceiling vs commerce-$); adopt the three-state decision, composable policy trait, and append-only journal as the ferrochain budget-governance skeleton. **HIGH-STAKES: only corpus reference for the budget-governance gap; human gate needed.** | Domain B BC: budget-governance allow/escalate/deny |
| P-74 | Feature-gated backend polymorphism (trait + many feature-gated impls) | **ADAPT** | One trait with multiple feature-gated backends (inmemory default, pgvector/qdrant/lancedb opt-in) is the right binary-size economics. Adapt: bound the test matrix per D12 — every feature combination that can be exercised in CI must be gated by a declared test-matrix entry; no untested backends ship (see P-84 reject). | ADR: ferrochain feature-matrix policy |
| P-75 | `schemars` for tool-arg schema; hand-rolled JSON Schema for provider wire schema | **ADOPT** | Concrete evidence for D5 ADR: adk-rust uses schemars where the schema derives from owned Rust types (the `#[tool]` macro path) and hand-rolls where it mirrors an externally-fixed wire contract (per-provider `schema_adapter.rs`). This is the correct decision boundary for ferrochain — `schemars::schema_for!` on ferrochain-owned tool-arg structs; manual schema construction when conforming to a provider's documented JSON Schema dialect. | D5 ADR: where to mandate schemars vs hand-roll |
| P-76 | Bare-`String` `#[derive(Debug)]` API keys workspace-wide | **REJECT** | Must-not-inherit. Every ferrochain provider config carries `#[derive(Debug)]` by default and the key is a `String` field — this prints the key verbatim in any span, error log, or `{:?}` fmt call. Several configs also `Serialize` the key to JSON. CLAUDE.md mandates: every secret/credential type is a redacted newtype with `impl Debug` → `"<redacted>"`. `OpenAiApiKey`, `AnthropicApiKey`, etc. must be newtypes. adk-rust is a workspace-wide counter-example, not a template. | CLAUDE.md: ApiKey redacted newtype (all partner crates) |
| P-77 | Inconsistent outbound-timeout discipline across provider stack | **REJECT** | Must-not-inherit. 8 `reqwest::Client::new()` sites with no `.timeout()` across the cluster (the anthropic main client is the lone exception). A hung provider endpoint blocks the calling task indefinitely. CLAUDE.md mandates a 30 s outbound timeout on every client. The `adk-anthropic` main client (`timeout(DEFAULT_TIMEOUT) + pool + keepalive`) is the positive reference; the rest are counter-examples. | CLAUDE.md: reqwest timeout enforcement |
| P-78 | `MistralRsError::Other(#[from] anyhow::Error)` — sole genuine `anyhow` public-signature leak | **REJECT** | Must-not-inherit. The `Other(anyhow::Error)` escape hatch on a public error enum erases component/category information at the boundary, inverting the structured-error investment. CLAUDE.md forbids `anyhow` in library public signatures. A ferrochain local-inference crate must give every failure mode a structured `thiserror` variant; no `Other(anyhow)` catch-all. | CLAUDE.md: no anyhow in public error types |
| P-79 | Multiple native-tls ingress chains via optional model/voice features | **ADAPT** | CLAUDE.md mandates rustls-only. adk-rust's three native-tls paths are: (1) livekit (first-party explicit, optional feature); (2) mistralrs→hf-hub (transitive, model download); (3) audio→hf-hub (transitive). Use as an ingress map for ferrochain audit: if ferrochain adds local inference (mistralrs-analog) or model download, ensure `hf-hub` is configured with its `rustls` feature; do not declare `native-tls` as a first-party feature. The livekit path is not relevant (ferrochain won't use LiveKit). | ADR: rustls-only enforcement + hf-hub feature audit if local inference added |

---

## 8. Realtime / Voice Cluster (P-80, P-81, P-88, P-89, P-90, P-91, P-92, P-93)

> adk source: `adk-realtime` — `RealtimeRunner`, `GeminiRealtimeSession`, `OpenAIWebRTCSession`, `AvatarProvider`, livekit bridge; not in ferrochain Phase 1–3 scope

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-80 | Realtime context-mutation FSM ("Phantom Reconnect") — 4-state FSM + bounded retry + fail-open event loop | **NOT-APPLICABLE** | Realtime voice is outside Phase 1–3 scope. If a ferrochain realtime subsystem is ever added targeting both OpenAI-WS and Gemini-Live, this FSM (teardown-safe gating, last-write-wins pending-mutation queue, 3-attempt reconnect budget, lock-discipline before `.await`) is the strongest single mechanism in the corpus. | — |
| P-81 | Barge-in / turn-taking delegated to server-side VAD | **NOT-APPLICABLE** | Realtime voice out of scope. | — |
| P-88 | Gemini teardown/rebuild: deterministic close + resumption token, but drops buffered audio | **NOT-APPLICABLE** | Realtime voice out of scope. | — |
| P-89 | Gemini event translation: lossy on base64 audio decode, multi-call truncation, unknown-frame collapse | **NOT-APPLICABLE** | Realtime voice out of scope. | — |
| P-90 | `AvatarProvider` trait: two fundamentally different topologies; keep-alive fail-closed | **NOT-APPLICABLE** | Avatar providers out of scope. | — |
| P-91 | Avatar HTTP clients timeout-less + `assert!` panic in library constructor | **REJECT** | Must-not-inherit regardless of realtime scope. Two distinct violations: (1) `reqwest::Client::new()` with no `.timeout()` — CLAUDE.md mandatory timeout rule; (2) `assert!(api_base_url.starts_with("https://"))` in a library constructor — CLAUDE.md no-unwrap/expect/assert-panic in non-test code; constructors return `Result` and report URL validation through the error taxonomy. The credential handling in the same crate (SecretString + redacted Debug) is the correct side of the pattern and DOES apply. | CLAUDE.md: constructor returns Result + mandatory timeout |
| P-92 | LiveKit bridge: thin feature-gated adapter with fail-open audio and typestate builder | **NOT-APPLICABLE** | LiveKit out of scope. | — |
| P-93 | native-tls ingress: livekit is the sole first-party explicit opt-in | **NOT-APPLICABLE** | Ferrochain won't use livekit. Confirms P-79 adapt: the native-tls exposure from hf-hub and realtime is transitive, not a declared workspace choice, making it addressable via feature selection rather than dependency surgery. | — |

---

## 9. A2A / Protocol Cluster (P-85, P-86, P-94, P-95, P-96)

> adk source: `adk-server/src/a2a/`; D13: ferrochain-server is first-party with NO wire-compatibility with LangGraph Platform; A2A is outside ferrochain's declared protocol scope

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-85 | `RemoteA2aAgent`: all transport failures surfaced as error events, never stream `Err` | **NOT-APPLICABLE** | A2A not in ferrochain scope. Design choice (error-in-content vs `Err` on stream) informs if ferrochain ever adds remote-agent calls — the error-in-content model is stream-survivable but collapses error channel into content channel. | — |
| P-86 | Dual A2A client generations (legacy + feature-gated v1) | **NOT-APPLICABLE** | A2A out of scope. Lesson for ferrochain-server: converge on a single client generation per protocol family from the start; dual-maintenance with duplicated SSE parsing is a sustained drift surface. | — |
| P-94 | a2a-v1 retry: unary-only; timeout-retry branch near-dormant (client has no outbound timeout) | **NOT-APPLICABLE** | A2A out of scope. Reinforces CLAUDE.md timeout rule: without a client-level `.timeout()`, the `is_timeout()` retry branch is structurally unreachable. | — |
| P-95 | a2a-v1 card caching is conditional-revalidation (ETag/If-None-Match), not a value cache | **NOT-APPLICABLE** | A2A out of scope. | — |
| P-96 | Two divergent retry policies in a2a-v1; server push adds SSRF defense before retry loop | **NOT-APPLICABLE** | A2A out of scope. SSRF gate on outbound push was already covered by P-35 ADOPT (Part 1). Policy divergence between client and server retry is an internal-consistency concern irrelevant to ferrochain's design. | — |

---

## 10. Retry-Reflect / Tool-Recovery Cluster (P-63)

> adk source: `adk-retry-reflect` — `RetryReflectPlugin`, `RetryTracker`, `GlobalRetryTracker`

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-63 | retry-reflect per-tool limit keyed by args-hash → bypassed by arg-changing agent | **REJECT** | Must-not-inherit termination hole. The counter key `"{tool_name}:{hash(args)}"` resets every time the model changes arguments (which the reflection prompt explicitly encourages), so `effective_limit = 3` is illusory. Ferrochain tool-retry must key the per-tool bound on `(tool_name)` or `(tool_name, call-site-id)` — NOT on argument content — and must enable a finite global bound by default (not `None`). The reflection-injection mechanism from P-50 (ADAPT in Part 1) is correct; only this key-design and the default-unlimited-global are wrong. | ferrochain tool-retry BC: termination guarantee |

---

## 11. RAG / VectorStore Cluster (P-84)

> adk source: `adk-rag` — `VectorStore` trait, `InMemoryVectorStore`, `qdrant`/`pgvector`/`lancedb`/`surrealdb` backends

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|----------------------|--------------|
| P-84 | `InMemoryVectorStore` ignores declared dimensions; 3/5 VectorStore backends have zero unit tests | **REJECT** | Must-not-inherit. The dimension-agnostic in-memory store (silently truncates via zip rather than erroring on mismatch) creates a correctness trap that only manifests in production against a real backend. ferrochain VectorStore implementations must validate embedding dimensions consistently across ALL backends — including InMemory — and surface a typed error on mismatch. The untested-backend coverage gap is also must-not-inherit per D14's strict quality standard. | ferrochain-rag BC: dimension invariant across all VectorStore backends |

---

## High-Stakes Patterns for Human Gate

The following four dispositions require Phase 1 architectural decisions that the human should review before BC authoring begins. They are not mechanical "must-not-inherit" cases — they are design forks with real trade-offs.

### H1 — P-73: Domain-B Budget-Governance Shape (ADAPT, HIGH stakes)

**What it is:** adk-payments' composable-policy guardrail (allow/escalate/deny three-state verdict, per-finding severity, composable policy trait, append-only evidence journal) is the only corpus reference resembling the Domain-B budget-governance primitive that adk-rust itself does NOT implement (P-46 gap confirmed).

**Why it matters:** The Domain-B "dark factory" holdout scenario requires a per-run / per-sub-agent token+cost ceiling with halt-or-degrade semantics. No LangChain/LangGraph prior art exists. The payment guardrail gives ferrochain a tested architectural shape (different domain, same governance topology) to work from rather than designing from scratch.

**Decision needed:** Adopt the allow/escalate/deny policy-trait + append-only journal shape for ferrochain budget-governance? If yes, this is a Phase 1 BC and a forcing-function for the `RunConfig` design.

---

### H2 — P-67: Provider Architecture — Standalone SDK Crate vs. Embedded Adapter (ADOPT, HIGH stakes)

**What it is:** adk-rust splits each vendor into an independent wire-SDK crate (zero framework deps) + a thin `Llm`-trait adapter in the main crate. Drift is a compile error, not a runtime surprise. The SDK is reusable by consumers who don't want the full framework.

**Why it matters:** The architectural choice for `ferrochain-anthropic`, `ferrochain-openai`, and `ferrochain-ollama` in the Phase 3 partners wave. Option A: follow adk's SDK+adapter split (creates `ferrochain-anthropic-sdk` + `ferrochain-anthropic`). Option B: single-crate embedded adapter (simpler workspace, less reuse surface). D4 (single workspace) is compatible with either.

**Decision needed:** Does ferrochain adopt the standalone-SDK split for partner crates? This shapes the workspace topology and the crate family beyond what D6 currently enumerates.

---

### H3 — P-72: Proc-Macro Design for Tool Wiring (ADAPT, HIGH stakes)

**What it is:** `#[tool]` attribute macro collapses the `Tool`-trait impl to one annotation; `#[entrypoint]`/`#[task]` are the LangGraph `@entrypoint`/`@task` analogs with auto-checkpointing baked in.

**Why it matters:** Ferrochain's DX story hinges partly on zero-boilerplate tool registration and a ergonomic functional-graph API. The macro path also determines where schemars is mandated (D5 ADR is unresolved). adk's approach (schemars for owned tool-arg types, hand-roll for provider wire contracts) resolves D5 for the tool surface specifically.

**Decision needed:** Does ferrochain ship proc-macros for tool and graph wiring in Phase 1/2? This is a Phase 1 ADR that intersects D5 and blocks graph BC authoring.

---

### H4 — P-59 + P-55 Combined: Content-Validation Architecture for Domains A and C (REJECT + ADAPT, HIGH stakes)

**What it is:** adk-rust's guardrails only cover user-input and final-output — the indirect prompt-injection surface (tool results, RAG content, memory content entering the model context) is entirely unguarded. The guardrail framework shape (P-55) is sound; the enforcement scope (P-59) is the gap.

**Why it matters:** Domain A (SOC analyst) and Domain C (OpenClaw personal assistant) both require validation of content by provenance, not just user origin. The architecture decision — where in the tool-call pipeline to insert provenance tagging and guardrail passes — shapes the core `InvocationContext` / tool-result routing design and should be resolved before Phase 1 BCs are authored.

**Decision needed:** Confirm that ferrochain's tool-result pipeline includes a provenance-tag seam and a guardrail-on-ingress hook (not only on user-input / final-output). This is a Phase 1 Domain-A forcing-function.

---

## Appendix: Disposition Cross-Reference by Original Pass

| Pass | Patterns in range | ADOPT | ADAPT | REJECT | N/A |
|------|------------------|-------|-------|--------|-----|
| A4 (P-47–P-66) | P-51..P-66 (16) | 1 (P-52) | 3 (P-51, P-53, P-55) | 5 (P-58, P-59, P-63, P-64, P-66) | 7 (P-54, P-56, P-57, P-60, P-61, P-62, P-65) |
| A5 (P-67–P-79) | P-67..P-79 (13) | 6 (P-67, P-68, P-69, P-70, P-71, P-75) | 4 (P-72, P-73, P-74, P-79) | 3 (P-76, P-77, P-78) | 0 |
| A6 (P-80–P-87) | P-80..P-87 (8) | 0 | 0 | 2 (P-84, P-87) | 6 (P-80, P-81, P-82, P-83, P-85, P-86) |
| A7 (P-88–P-97) | P-88..P-97 (10) | 0 | 0 | 1 (P-91) | 9 (P-88, P-89, P-90, P-92, P-93, P-94, P-95, P-96, P-97) |
| **Totals** | **47** | **7** | **7** | **11** | **22** |

*Sandbox patterns (P-57, P-60, P-61, P-62, P-65) are NOT-APPLICABLE to ferrochain's current scope but carry must-not-inherit notes if code-execution is ever added. P-63 (retry-reflect key design) is under its own cluster. P-84 (RAG dimension safety) is under its own cluster. The three known negative-evidence patterns cited in the directive (P-61, P-62, P-65) are all dispositioned NOT-APPLICABLE with explicit must-not-inherit notes; P-87 (error-swallowing) is REJECT.*
