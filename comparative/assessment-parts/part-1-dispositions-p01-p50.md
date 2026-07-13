---
artifact: comparative/assessment-parts/part-1-dispositions-p01-p50
pass: D16-COMPARE-1
scope: patterns P-01 through P-50 (passes A1 + A2 + A3 + first four of A4)
constraint: >
  D16 Rust-blindness. Language carries zero evidentiary weight.
  ADOPT/ADAPT/REJECT/NOT-APPLICABLE decided on production-grade merit only.
  Anti-sunk-cost: prior semport investment earns LangChain semantics nothing.
  These are per-pattern merit verdicts; overall strategic outcome goes to human direction gate.
binding_context: D4 single workspace | D7 core→graph→partners | D11 HYBRID engine /
  msgpack checkpoints / 3 durability tiers sync-default | D12 500/750 file-size gate |
  D13 ferrochain-server first-party | CLAUDE.md (no anyhow in libs, mandatory 30s timeout,
  newtype credentials, no unwrap/expect in non-test, structured errors, no silent empty returns)
created: 2026-07-13
status: complete
---

# D16 Comparative Assessment — Part 1: Dispositions P-01 through P-50

Patterns dispositioned: **50** (P-01 … P-50).
Subsystem tables follow; each table carries columns:
**Pattern | Title (short) | Disposition | Merit-based rationale | Phase-1 hook**

Disposition codes:
- **ADOPT** — take the mechanism as-is; wire into ferrochain design
- **ADAPT** — take the design intent; modify implementation (rationale states what changes)
- **REJECT** — counter-example; ferrochain must do the opposite or avoid the pattern
- **NOT-APPLICABLE** — outside ferrochain scope or decision deferred with documented rationale

---

## 1. Agents / Core (adk-core, adk-runner agent abstractions)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-01 | Structured error envelope (component × category) | **ADOPT** | Two-axis error (14 components × 10 categories) with derived retry-hint and HTTP mapping, exhaustively tested in truth tables — data-driven rather than ad-hoc per call site; directly maps to ferrochain error-taxonomy requirement | BC for error-taxonomy; ADR D5-errors |
| P-02 | Supertrait context ladder (ReadonlyCtx → CallbackCtx → InvocationCtx) | **ADAPT** | Progressive capability disclosure at the type level is strong; ferrochain's RunConfig threading follows LangGraph semantics (configurable, not invocation-centric) so the exact trait hierarchy must differ — adopt the least-privilege shape, adapt the capability tiers to LangGraph's `config`/`store`/`writer` model | ADR for RunConfig/callback context |
| P-04 | Retry hint co-located with error | **ADOPT** | Single source of truth for retryability travels with the error value; eliminates error-string re-parsing at every call site; legacy fallback is explicitly scoped | error-taxonomy BC (reinforces P-01) |
| P-05 | `is_final_response()` turn-completion predicate | **ADOPT** | Centralizing turn-boundary detection with a 9-case test truth table prevents streaming/tool-loop bugs; the single-predicate pattern is directly portable | agent-loop BC (stream terminal-event contract) |
| P-06 | Typed-identity newtypes (AppName/UserId/SessionId triple) | **ADOPT** | Parse-don't-validate; the triple prevents cross-tenant session collisions a bare string key invites; `*_for_identity` methods eliminate ambiguous bare-id lookups | session namespace invariant BC |
| P-07 | Cooperative cancellation + Drop-guaranteed cleanup | **ADOPT** | Combining per-session + global cancellation tokens with a `Drop`-guard for cleanup is exception-safe across the streaming state machine; correctly scopes targeted interrupt vs global shutdown | cancellation/shutdown NFR |
| P-08 | Non-fatal degradation surfaced, not swallowed | **ADOPT** | Explicit policy of warn-and-proceed for optimization failures (cache) vs propagate for correctness failures (session append) is directly aligned with CLAUDE.md "No silent empty returns where partial-failure should propagate" | general logging/error-discipline BC |
| P-09 | Typestate builder (phantom NoAppName/NoAgent/NoSessionService) | **ADOPT** | Unrepresentable invalid construction state; makes missing-session-service a compile error not a runtime `unwrap`; correct for ferrochain runner and graph builder | Arc-DI wiring BC |
| P-11 | Event embeds LlmResponse via `#[serde(flatten)]` | **REJECT** | Coupling Event schema to LlmResponse via flatten invites field-collision surprises and forces schema migration in lockstep; justification is adk-go parity, not an architectural virtue — ferrochain should use explicit nested composition | — (counter-example) |
| P-12 | Capability defaults returning `false`/`None` | **ADAPT** | Default-false is acceptable for performance hints (`is_long_running`, `is_builtin`); dangerous for correctness-bearing isolation capabilities (`shared_state`, memory project scope) — adopt default-false only for non-correctness hints; require explicit implementations for isolation/coordination primitives | capability-gating BC |
| P-15 | Monolithic LlmAgent (2,712 lines) + 800-line runner | **REJECT** | Both violate D12 hard gate (750 lines); the 800-line single-function turn-state-machine makes each concern (cache lifecycle, transfer loop, compaction) un-unit-testable in isolation — counter-example requiring decomposition into TurnExecutor / TransferResolver / CacheLifecycle seams | D12 CI gate (cargo xtask check-file-size) |

---

## 2. Tools (adk-core SchemaAdapter, tool execution surface)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-10 | Provider-aware schema normalization (SchemaAdapter) | **ADOPT** | Keeps tool discovery provider-agnostic; localizes each provider's schema quirks behind a trait discovered through the model, not branched at call sites; tool-name UTF-8 truncation for 64-byte limits is a correct default | tool-schema BC; MCP adapter |
| P-13 | `serde_json::Value` as universal tool arg/result | **ADOPT** | Maximal provider-neutrality at the LLM tool boundary is reasonable; schema enforcement via SchemaAdapter/guardrail at request time; D5 pydantic→serde/schemars ADR handles compile-time schema side | D5 ADR (serde/schemars) |
| P-50 | Retry-&-reflect reflection injection (not blind retry) | **ADAPT** | Replacing tool-error with a structured reflection prompt is smarter than blind re-execution; saturating backoff with real-error passthrough on exhaustion is correct — two fixes required: (1) key per-tool counter on `tool_name` alone, not `tool_name:args_hash` (arg-changing agent bypasses the limit); (2) default `global_limit` to a finite value (not None) | tool-retry BC |

---

## 3. Model Providers (adk-model retry)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-03 | Retry as generic combinator with layered delay precedence | **ADOPT** | Policy (config) / classification (predicate) / mechanism (combinator) cleanly separated; delay precedence `AdkError.retry.retry_after()` → server `retry-after` header → exponential backoff respects server timing over local guessing; timing-verified test (gap measurements) is the correct validation form | rate-limiter BC |

---

## 4. Graph / Executor (adk-graph PregelExecutor)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-23 | Write isolation within super-step (clone → run → collect → apply) | **ADOPT** | BSP write-isolation invariant: nodes never observe each other's writes mid-step; the clone→concurrent-run→collect→apply shape is the correct implementation of D11's Pregel isolation requirement | D9 gate; graph-executor BC (BSP isolation) |
| P-24 | Property-based test suite over graph runtime (proptest-driven) | **ADOPT** | 8 of 14 integration files are property tests over BSP invariants (round-trip, routing totality, fan-in completeness, timeout laws); these encode the conformance contract ferrochain can lift directly as VP-NNN formal harness seeds | VP-NNN candidates (BSP round-trip / routing totality) |
| P-25 | Delta granularity: whole-state map, not per-channel | **ADAPT** | Composable wrapper shape (`DeltaCheckpointer<C>`) and round-trip invariant (`apply(s1, diff(s1,s2)) == s2`) are excellent; granularity must be per-channel to match LangGraph semport §1.4 `DeltaChannel` semantics — adopt the layered wrapper, adapt the `Diff` implementation to channel-level scope | checkpoint-delta ADR |
| P-27 | Graph checkpointing and session persistence as two unrelated subsystems | **NOT-APPLICABLE** | The separation itself is a design choice, not a pattern with a production-grade verdict; ferrochain architecture must explicitly decide whether graph thread checkpoints and conversation sessions share one backing store — defer to D9 gate / architecture ADR | D9 gate; architecture ADR |
| P-28 | Nondeterministic reducer application order (`buffer_unordered`) | **REJECT** | Completion-order reduce of non-commutative reducers makes replay non-reproducible; directly contradicts D9/D11 determinism invariant — counter-example; ferrochain executor must sort `all_updates` by deterministic node-identity/path before reducer application, and add concurrent-write detection for last-value channels | graph-executor BC (determinism); **HIGH-STAKES for human gate** |
| P-29 | Step-boundary-only durability, no per-task writes, no durability modes | **REJECT** | Crash mid-step re-runs all in-flight nodes (at-least-once, no per-task credit); zero `put_writes` equivalent; zero durability-mode knob — directly contradicts D11's requirement for all 3 durability tiers defaulting to sync; counter-example that would require a full redesign | durability-tiers ADR; **HIGH-STAKES for human gate** |
| P-30 | Notification-only interrupt / no resume-value injection | **REJECT** | `Dynamic { message, data }` interrupt cannot carry a human decision back into the interrupted node; no resume-value scratchpad, no per-task interrupt counter, no "node re-executes from start; prior interrupt() returns stored value" replay contract — the load-bearing LangGraph HITL semantic (semport §3.1–3.5) must be built from scratch | HITL/interrupt BC; **HIGH-STAKES for human gate** |
| P-31 | Wall-clock ordering for checkpoint "latest" and rewind | **REJECT** | `ORDER BY created_at DESC` + `Uuid::new_v4` checkpoint IDs: two checkpoints in the same clock tick have ambiguous order; clock adjustment can reorder history; rewind tie-break by id is arbitrary — counter-example; ferrochain must use a monotonic per-thread sequence (not wall-clock) for checkpoint IDs | checkpoint-ordering BC |

---

## 5. Checkpointing / State (adk-session, adk-graph checkpoint)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-20 | Transactional multi-table session writes (session + state + events atomic) | **ADOPT** | RAII-rollback `pool.begin()…commit()` across session/state/event tables; temp-prefixed keys stripped before persistence — this is the D11 checkpoint-atomicity guarantee: an appended event and its induced state delta commit or roll back together | durability BC |
| P-21 | AEAD envelope encryption wrapper with key rotation | **ADAPT** | AES-256-GCM with random 96-bit nonce, lazy re-encrypt with current key on previous-key hit, wrap-any-backend composition — correct crypto primitives and rotation design; two ferrochain requirements diverge: (1) event payloads must also be encrypted (P-32 gap); (2) rotation re-encrypt errors must propagate, not be silently swallowed (`let _ =` pattern) | encryption-at-rest NFR BC |
| P-22 | DeltaCheckpointer composable wrapper | **ADAPT** | Composable `DeltaCheckpointer<C: Checkpointer>` drop-in with snapshot cadence + bounded replay is strong layering; round-trip invariant tested via proptest — adapt granularity to per-channel scope per P-25 reasoning; otherwise adopt | checkpoint-delta ADR |
| P-32 | Encryption covers only session STATE, not event content | **REJECT** | Events contain the actual conversation (LlmResponse, actions) stored plaintext; plus rotation re-encrypt is `let _ =` swallowed — partial encryption guarantee misleads consumers; violates CLAUDE.md no-silent-swallow; counter-example: ferrochain must encrypt full session payload and propagate rotation failures | encryption-at-rest BC |
| P-33 | Gratuitous `unsafe impl Send/Sync` on PhantomData reducers | **REJECT** | `PhantomData<fn() -> T>` or derivation from bounded `T: Send+Sync` yields identical guarantees with zero unsafe; reaching for unsafe to paper over a variance/marker choice violates CLAUDE.md "no gratuitous unsafe without soundness note"; counter-example | — (counter-example) |
| P-34 | `append_event_for_identity` default collapses triple to bare session_id | **REJECT** | Default silently discards `app_name + user_id` and falls back to a globally-non-unique `session_id` key, then leans on a runtime ambiguity check — undercuts P-06's type-safety investment; counter-example: ferrochain must make triple-addressed append the only code path (no defaulted collapse) | session namespace invariant BC |

---

## 6. Memory (adk-memory, adk-session capability defaults)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-19 | Correctness-bearing capability defaults that silently return `None`/global-fallback | **REJECT** | `shared_state()` silently returns `None`; `search_in_project` defaults to global search when project scope is unimplemented — cross-project memory bleed or missed coordination is behaviorally indistinguishable from correct behavior; isolation-bearing capabilities must be required, not defaulted; counter-example | memory-isolation BC |
| P-26 | Memory visibility: global ∪ project overlay (additive project scope) | **ADAPT** | Clean cross-project isolation (project A cannot read project B) with firm user partitioning is correct; global entries deliberately bleed into every project view, suitable for shared org knowledge — ferrochain must decide for Domain C personal memory whether the global tier is disabled (user-private-only) or preserved; adopt the additive model for multi-project scenarios, gate it behind a config knob for personal-assistant contexts | Domain C personal-memory ADR |

---

## 7. Server (adk-server, adk-auth, adk-managed)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-35 | SSRF-hardened outbound webhook delivery | **ADOPT** | Validating user-supplied webhook URLs against private IPv4 ranges / loopback before every delivery is mandatory for any ferrochain-server push surface; delivery failure surfaced via structured error, not swallowed | security-review BC; webhook holdout |
| P-36 | Defense-in-depth default middleware stack (request-id + tracing + timeout + CORS + security headers) | **ADOPT** | Secure defaults by construction (request-id into tracing span, 30s inbound timeout, body-size limit, explicit CORS allowlist, nosniff/frame-deny/XSS headers); ferrochain adopts the stack design and overrides the P-45 CORS-open default with a deny-unless-configured posture | server-middleware BC |
| P-37 | Exhaustive A2A input validation with explicit per-field size bounds | **ADAPT** | Size-bound validation (non-empty, ≤256-char IDs, ≤64 KB metadata) individually tested per bound is the correct validation discipline for any RPC surface; context-resume state machine (INPUT_REQUIRED → Working → Completed) is a strong holdout target — ferrochain-server uses its own protocol (not A2A); adapt the validation rigor pattern, not the A2A protocol specifics | request-validation BC; holdout for size-bound rejection + context-resume idempotency |
| P-38 | Auth as injected trait boundary (RequestContextExtractor) | **ADOPT** | Separates identity extraction from policy (RBAC/scope); `Option<RequestContext>` in request extensions lets unauthenticated routes coexist; scope flows to tool execution via `ToolContext::user_scopes()` — the shape is directly portable to ferrochain-server's auth model | auth-seam ADR |
| P-41 | A2A `message_stream` is a state-transition stub (not real streaming) | **REJECT** | Streaming path emits `Task→Working→Completed` status events with no engine output ("placeholder — Runner integration later"); two transports for the same operation with divergent behavior is a behavioral lie; counter-example: ferrochain streaming and unary must be behaviorally equivalent and both drive the real engine | streaming holdout (assert real output) |
| P-42 | Outbound `reqwest::Client` built without `.timeout()` (8 sites, 0 timeout calls) | **REJECT** | Hung webhook receiver / JWKS endpoint / remote agent blocks delivery indefinitely; directly contradicts CLAUDE.md mandatory 30s outbound timeout convention; counter-example covering push sender, OIDC discovery, JWKS fetch, A2A client | — (counter-example; CLAUDE.md enforcement) |
| P-43 | Non-durable, unbounded in-memory idempotency + rate-limit + run state | **REJECT** | Idempotency map and token-bucket `buckets` are hard-wired `RwLock<HashMap>` with no persistence seam and no eviction — idempotency breaks across process restarts; unbounded maps leak memory under distinct caller IDs; incompatible with Domain B durable multi-day runs; counter-example requiring persistence seam from v1 | idempotency/rate-limit store ADR |
| P-44 | Secrets flow as bare `String` (no redacted newtype) | **REJECT** | `String` secret has default `Debug`/`Display` and can appear in spans/error messages verbatim; directly contradicts CLAUDE.md "Newtype + redacted Debug for credentials"; counter-example | — (counter-example; CLAUDE.md enforcement) |
| P-45 | Permissive-by-default CORS (`AllowOrigin::any()`) + unauthenticated debug route | **REJECT** | `SecurityConfig::default()` with empty `allowed_origins` produces CORS-open server; `/debug/trace` route exposed when auth is unconfigured; secure-by-default inverted; counter-example: ferrochain-server must deny CORS unless configured and never expose trace/debug without explicit opt-in | server-security BC |
| P-46 | No budget/cost-ceiling enforcement anywhere (token accounting only) | **NOT-APPLICABLE** | adk-rust stops at `UsageReport` accounting + request-rate limiting; no token→cost conversion, no per-run ceiling, no halt-or-degrade gate — confirms Domain B budget-governance is novel with no reference-corpus prior art; ferrochain must design from scratch layered on a `UsageReport`-style substrate | Domain B budget-governance BC; **HIGH-STAKES for human gate (novel scope)** |

---

## 8. Telemetry (adk-managed usage, adk-telemetry semconv)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-39 | Cross-provider usage normalization (`UsageReport` / `SessionUsageTracker`) | **ADOPT** | Normalizing Gemini/OpenAI/Anthropic token fields into one struct (input/output/total + thinking/cache-read/cache-write; clamp negatives; auto-compute total) with matching OTel `gen_ai.usage.*` semconv constants is the accounting substrate Domain B budget-governance sits on top of | usage-metering BC |

---

## 9. Sandbox (adk-sandbox — P-47..P-50 are the first A4 patterns in scope)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-47 | WASM backend: genuine in-process isolation (deny-by-default, epoch timeout, memory bounds) | **ADOPT** | No filesystem preopens, no network, memory bounded via `StoreLimitsBuilder`, wall-clock timeout via epoch interruption — honest all-five-true capability descriptor; strongest isolation primitive in the corpus; ferrochain code-exec should treat WASM (or container) as the default enforcing backend, not process | Domain C sandboxing BC |
| P-48 | Linux bubblewrap enforcer: deny-by-default namespace isolation | **ADOPT** | `--die-with-parent + --unshare-pid/net/session`, expose only allowlisted paths via `--ro-bind`/`--bind`, `probe()` verifies binary + unprivileged namespaces — correct shape for Linux kernel-enforced isolation without root | Domain C sandboxing BC |
| P-49 | Truthful backend-capability descriptor (honesty over false-security claims) | **ADOPT** | `BackendCapabilities` / `EnforcedLimits` report actual enforcement; process backend logs "memory limit not enforced" rather than pretending — adopt as a pattern AND strengthen: ferrochain sandbox trait must also include a hard precondition that refuses to run untrusted code on a backend whose enforcement flags are false for the requested isolation level | sandbox-policy BC |

---

## 10. Deps / Workspace Hygiene (cross-crate structural patterns)

| Pattern | Title | Disposition | Merit-based rationale | Phase-1 hook |
|---------|-------|-------------|-----------------------|--------------|
| P-14 | Feature-flag-gated optional subsystems in composition root | **ADAPT** | Feature-gating for binary-size opt-in is correct; heavy `#[cfg]` interleaving inside a single long function body (Runner::run) is not — adopt feature-gating for optional subsystem inclusion; require that gated code lives in separately-extracted modules that satisfy D12, not inlined in an 800-line function | workspace structure ADR |
| P-16 | "Duplicated" provider surfaces (in-tree modules vs standalone crates) | **NOT-APPLICABLE** | A5/P-67 resolution demonstrates this is a layered SDK + adapter stack, not parallel reimplementations; the A1 WEAK concern was unfounded; disposition is deferred to P-67 (ADOPT) in Part 2 | — (see P-67 ADOPT in Part 2) |
| P-17 | Cache-key proxy on agent description (not resolved instruction + tools hash) | **REJECT** | Two agents with identical descriptions but different resolved instructions can collide; changed instruction under stable description can serve stale cache; empty tools map means tool definitions are not part of cache identity; counter-example: ferrochain prompt-caching must key on a content hash of (resolved instruction + tool declarations) | — (counter-example) |
| P-18 | `anyhow` available workspace-wide alongside `AdkError` | **NOT-APPLICABLE** | Certification confirmed `anyhow::Error` is confined to binaries and tests (zero public library signature exposure); the risk was library leakage, not the dep itself; ferrochain independently forbids anyhow in library public APIs via CLAUDE.md, so the confinement rule is adopted by policy, not by pattern | — (CLAUDE.md enforcement) |

---

## Summary

| Disposition | Count | Patterns |
|-------------|-------|---------|
| **ADOPT** | 20 | P-01 P-03 P-04 P-05 P-06 P-07 P-08 P-09 P-10 P-13 P-20 P-23 P-24 P-35 P-36 P-38 P-39 P-47 P-48 P-49 |
| **ADAPT** | 9 | P-02 P-12 P-14 P-21 P-22 P-25 P-26 P-37 P-50 |
| **REJECT** | 16 | P-11 P-15 P-17 P-19 P-28 P-29 P-30 P-31 P-32 P-33 P-34 P-41 P-42 P-43 P-44 P-45 |
| **NOT-APPLICABLE** | 5 | P-16 P-18 P-27 P-40 P-46 |
| **TOTAL** | 50 | |

---

## High-Stakes Patterns Flagged for Human Gate

The following patterns require a human decision before the Phase-1 ADR / BC lock, because they determine which architectural directions are irrevocably open or closed:

| Pattern | Why Human Gate Required |
|---------|------------------------|
| **P-28** (nondeterministic reducer order) | Deterministic merge order must be a day-1 design invariant in ferrochain-graph; retrofitting it post-implementation is prohibitively expensive. Confirm deterministic-node-identity-sort approach before the D9 ADR. |
| **P-29** (step-boundary-only durability) | D11 mandates all 3 durability tiers. This pattern shows what NOT to build; human should confirm the per-task `put_writes` tier is in Phase-1 scope (not deferred to a later cycle). |
| **P-30** (notification-only interrupt/resume) | LangGraph §3 HITL resume-value/replay contract must be built entirely from scratch. Human should confirm this is a Phase-1 BC (not a Phase-3 bolt-on), because it affects graph state-machine design at the core. |
| **P-46** (budget governance confirmed novel) | No reference-corpus prior art; Domain B requires a new primitive. Human should affirm whether budget-governance is Phase-1 scope (BC in first cycle) or explicitly deferred with a documented risk decision. |
| **P-24** (proptest test suite as VP seeds) | The adk-graph property tests encode BSP invariants (round-trip, routing totality, fan-in completeness) that map 1:1 to ferrochain VP-NNN candidates. Human should confirm these invariants are committed as VP obligations for Phase-6 formal hardening before the architecture phase locks them in. |
