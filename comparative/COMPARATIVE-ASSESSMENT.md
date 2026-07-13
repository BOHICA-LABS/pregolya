---
artifact: comparative/COMPARATIVE-ASSESSMENT
pass: D16-COMPARE-4 (FINAL SYNTHESIS)
directive: D16 — human mandate 2026-07-13
scope: all 97 patterns (Corpus 1 LangChain/LangGraph + Corpus 5 adk-rust v1.0.0)
rust_blindness: ENFORCED — language carries zero evidentiary weight
anti_sunk_cost: ENFORCED — prior semport investment earns LangChain semantics nothing
binding_constraints: [D4, D7, D8, D9, D11, D12, D13, D14, D16]
sources:
  - comparative/assessment-parts/part-1-dispositions-p01-p50.md  # 50 patterns
  - comparative/assessment-parts/part-2-dispositions-p51-p97.md  # 47 patterns
  - comparative/assessment-parts/part-3-conflicts-negative-evidence.md  # 10 conflicts, 17 NE
  - STATE.md  # D1–D16 Decisions Log + Risk Register
certification_basis: >
  Corpus 1 (LangChain/LangGraph): extraction gate 3/3 strict-zero (7-area exhaustive sweep).
  Corpus 5 (adk-rust v1.0.0 SHA a6c79b6f): 3-CLEAN gate C21–C23, 0 hallucinations over 23
  cumulative passes. Both corpora dispositioned under Rust-blindness — language carries zero
  evidentiary weight in every verdict.
produced_by: architect
created: 2026-07-13
status: complete
---

# D16 Comparative Assessment — Final Synthesis

This document assembles the findings of the four-part D16 comparative best-patterns assessment
into a human-readable synthesis that drives the HUMAN DIRECTION GATE before Phase 1 spec
crystallization begins. Sections 2–4 are assembled from the three certified part-files; the
outcome scoring and gate questions in Sections 5–7 are original synthesis work performed here.

---

## Section 1: Method Note

### Rust-Blindness Operationalization

D16 mandates that the language of implementation carries zero evidentiary weight. In practice
this means: every pattern was evaluated on the following merit dimensions only.

**Merit evidence accepted:**
- **Test depth** — truth-table unit tests, property-based tests, timing-verified timing tests,
  round-trip invariant tests. The presence, quality, and breadth of automated evidence for a
  claimed property.
- **Failure-mode handling** — does the pattern surface errors structurally, propagate failures
  rather than swallowing them, and preserve caller observability across all paths (including
  rare ones)?
- **Security posture** — does the pattern enforce secure defaults by construction (deny-by-default,
  secret protection, no-timeout surfaces), or does it require caller discipline to be safe?
- **Operational maturity** — does the pattern handle production concerns (clock correctness,
  determinism, crash recovery, idempotency, connection limits, backpressure) rather than deferring
  them to the caller?

**Merit evidence rejected:**
- Language idiom preference ("this is more Rust-idiomatic")
- Reuse of existing semport work ("we already ported this")
- Ergonomic preference not backed by a correctness or operational argument

Patterns were dispositioned ADOPT / ADAPT / REJECT / NOT-APPLICABLE on these criteria. A pattern
written in Rust that scored HIGH on all four dimensions beats a pattern from the Python corpus
that scores LOW — and vice versa. The dispositions in Parts 1 and 2 are per-pattern merit
verdicts; the strategic outcome recommendation in Section 5 is where the aggregate is scored.

### Provenance

Sections 2–4 are assembled from three certified part-files:

| Part file | Scope | Status |
|-----------|-------|--------|
| `assessment-parts/part-1-dispositions-p01-p50.md` | Patterns P-01–P-50 | complete |
| `assessment-parts/part-2-dispositions-p51-p97.md` | Patterns P-51–P-97 | complete |
| `assessment-parts/part-3-conflicts-negative-evidence.md` | 10 conflicts + 17 NE items | complete |

Do not re-read the raw analysis corpora (patterns-observed.md, behavioral-intent.md) to verify
findings — that work has been certified. Corrections require a new certification pass under D14.

### Certification Basis

Corpus 1 (LangChain/LangGraph at langchain==1.3.13 / langgraph==1.2.9): extraction gate closed
at 3 consecutive strict-zero passes (7-area exhaustive sweep). Corpus 5 (adk-rust v1.0.0,
SHA a6c79b6f): 3-CLEAN gate closed at passes C21–C22–C23, with zero hallucinations accumulated
across all 23 certification passes (C1–C23). Both assessments used the same exhaustive-sweep-
then-3-CLEAN protocol established by D14.

---

## Section 2: Pattern Dispositions — Rollup

### Aggregate Counts

| Disposition | Part 1 (P-01–P-50) | Part 2 (P-51–P-97) | **Total** |
|-------------|--------------------|--------------------|-----------|
| **ADOPT** | 20 | 7 | **27** |
| **ADAPT** | 9 | 7 | **16** |
| **REJECT** | 16 | 11 | **27** |
| **NOT-APPLICABLE** | 5 | 22 | **27** |
| **TOTAL** | **50** | **47** | **97** |

For per-pattern verdict tables with full rationale and Phase-1 hooks, see the certified part
files. This section contains the per-subsystem summary and the combined high-stakes flags only.

### Per-Subsystem Summary

| Subsystem | ADOPT | ADAPT | REJECT | NA | Notes |
|-----------|-------|-------|--------|----|-------|
| Agents / Core | 8 | 2 | 4 | 0 | P-01/P-04 error taxonomy, P-09 typestate builder are strongest adopts; P-15 monolith is critical reject |
| Tools | 2 | 1 | 0 | 0 | P-10 schema normalization; P-50 reflection-inject (adapted) |
| Model Providers | 1 | 0 | 0 | 0 | P-03 retry combinator; layered delay precedence |
| Graph / Executor | 2 | 2 | 4 | 1 | CRITICAL: P-28/P-29/P-30/P-31 all REJECT — no determinism, no per-task durability, no HITL resume |
| Checkpointing / State | 2 | 2 | 2 | 0 | P-20 transactional writes (ADOPT); encryption gap (REJECT) |
| Memory | 0 | 1 | 1 | 0 | P-26 scope model (ADAPT); P-19 silent defaults (REJECT) |
| Server | 4 | 1 | 6 | 0 | Security-positive: P-35/P-36/P-38 strong adopts; CORS/timeout/idempotency all REJECT |
| Telemetry | 1 | 0 | 0 | 0 | P-39 usage normalization substrate |
| Sandbox | 3 | 0 | 0 | 5 | P-47/P-48/P-49 strong adopts; OOS patterns NA |
| Workspace Hygiene | 1 | 1 | 1 | 2 | Feature-gating (ADAPT); cache-key proxy (REJECT) |
| Skills / Coord | 0 | 1 | 1 | 1 | P-51 (ADAPT); P-87 silent swallow (REJECT) |
| Plugins / Callbacks | 0 | 1 | 1 | 0 | P-52 priority pipeline (ADOPT); dual-model (REJECT) |
| Evaluation | 0 | 1 | 1 | 0 | P-53 declarative harness (ADAPT); P-64 scoring defects (REJECT) |
| Guardrails | 0 | 1 | 1 | 0 | P-55 trait shape (ADAPT); P-59 incomplete scope (REJECT) |
| Providers / Partners | 5 | 3 | 3 | 0 | P-67 SDK layering, P-68/P-69/P-70/P-71/P-75 strong adopts |
| Realtime / Voice | 0 | 0 | 1 | 7 | P-91 REJECT (constructor panic + timeout absent); rest OOS |
| A2A / Protocol | 0 | 0 | 0 | 5 | All OOS per D13 |
| Tool-Retry | 0 | 0 | 1 | 0 | P-63 termination hole REJECT |
| RAG / VectorStore | 0 | 0 | 1 | 0 | P-84 dimension safety REJECT |

### Combined High-Stakes Flags (9)

These patterns require a human decision before Phase-1 BC/ADR lock because they determine which
architectural directions are irrevocably open or closed.

| Flag | Pattern | Stakes Summary |
|------|---------|----------------|
| HS-1 | P-28 | Nondeterministic reducer order — must be day-1 graph design invariant; cannot be retrofitted |
| HS-2 | P-29 | Step-boundary-only durability — D11 mandates per-task writes; confirm Phase-1 scope |
| HS-3 | P-30 | Notification-only HITL — resume-value scratchpad must be built from scratch; confirm Phase-1 BC |
| HS-4 | P-46/P-73 | Budget governance confirmed novel (P-46 gap + P-73 payment-guardrail shape as closest analog); confirm Domain-B Phase-1 scope |
| HS-5 | P-24 | Proptest BSP invariants are VP seeds — confirm as VP obligations before architecture phase locks |
| HS-6 | P-67 | Partner architecture: standalone SDK crate vs embedded adapter — shapes workspace beyond D6 |
| HS-7 | P-72 | Proc-macro design for tool/graph wiring — Phase-1 ADR intersects D5 (schemars); blocks graph BC authoring |
| HS-8 | P-55+P-59 | Content-validation scope: tool-result + RAG ingress ungarded in adk-rust — Domain A/C forcing function; confirm Phase-1 BC |
| HS-9 | P-73 | Budget-governance shape (allow/escalate/deny, composable policy, append-only journal) — only corpus reference for Domain B primitive |

---

## Section 3: Cross-Corpus Design Conflicts — Rollup

Ten sites where the two corpora materially disagree on design. For full evidence citations and
detailed analysis, see `assessment-parts/part-3-conflicts-negative-evidence.md` Section A.

| Conflict | Area | Corpus 1 (LangGraph) wins? | Recommendation |
|----------|------|---------------------------|----------------|
| **CONFLICT-1** | Graph execution model | YES (binding: D9/D11) | Implement BSP version-triggered scheduling + content-addressed task IDs + deterministic write order; adk-rust edge-following completion-order model is counter-example |
| **CONFLICT-2** | Checkpoint durability | YES (binding: D11.3) | Three-tier durability (sync/async/exit) with per-task `put_writes`; sync default; monotonic checkpoint IDs; adk-rust step-boundary-only is counter-example |
| **CONFLICT-3** | Interrupt/resume (HITL) | YES (binding: D8 Domains A+B) | Full LangGraph HITL contract: per-task scratchpad, FIFO resume-value delivery, node-re-executes-from-start; adk-rust notification-only is counter-example — build from scratch |
| **CONFLICT-4** | Checkpoint clock/ordering | YES | Monotonic logical clock (not wall-clock) for checkpoint IDs; parent-pointer fork lineage (not copy); adk-rust UUID v4 + wall-clock is counter-example |
| **CONFLICT-5** | Streaming event taxonomy | YES (wire format ferrochain-native) | Typed per-phase event taxonomy (start/stream/end per operation, run_id correlation, parent_ids); ferrochain-native wire format (not langchain compat); adk-rust flat Event envelope is internal persistence unit only |
| **CONFLICT-6** | Error taxonomy | adk-rust wins decisively | Adopt adk-rust 2D component×category struct for `FerrochainError`; Python exception hierarchy does not translate to Rust; rename components to ferrochain crate names |
| **CONFLICT-7** | Memory service | Both contribute | User/app/session partitioning + GDPR erasure (from adk-rust); global-overlay default INVERTED (user-private must not bleed); explicit opt-in for global tier |
| **CONFLICT-8** | Agent composition | YES (binding: D7/D11.1) | Agents expressed as StateGraph instances; high-level API (`create_react_agent` analog) for ergonomics; adk-rust composite-tree informs ergonomics only |
| **CONFLICT-9** | Delta checkpoint granularity | YES | Per-channel delta granularity (LangGraph) over whole-state map (adk-rust); adopt adk-rust's composable DeltaCheckpointer wrapper pattern, adapt granularity |
| **CONFLICT-10** | Server surface | Hybrid | adk-rust defensive middleware stack (P-35/P-36/P-37/P-38) adopted; LangGraph Platform endpoint catalog is semantic reference for thread/run resources; streaming and unary runs equivalent from day 1 |

---

## Section 4: Negative Evidence Catalog — Rollup

Seventeen adk-rust patterns that ferrochain must actively NOT inherit. Each carries a ferrochain
requirement that becomes a BC candidate, holdout hook, or ADR. For full analysis see
`assessment-parts/part-3-conflicts-negative-evidence.md` Section B.

| NE | Source | Must-Not-Inherit Description | Ferrochain Requirement |
|----|--------|------------------------------|------------------------|
| NE-01 | P-61/P-49/P-62 | Default sandbox = no isolation; capability honesty does not force enforcement | Enforcing backend (WASM/container) must be default; process backend is loud opt-in; `Sandbox::execute` on strict policy against non-enforcing backend returns `Err(PolicyNotEnforceable)` |
| NE-02 | P-65 | String-only workspace path safety; no symlink resolution | All workspace file ops must `canonicalize_beneath_root(base, path)` at access time; VP: no file op can observe outside declared workspace root |
| NE-03 | P-87 | Skill coordinator strict-mode swallows validation errors → caller sees `None` | Validation failures must propagate `Err(SkillError::ValidationFailed { skill, missing_tools })`; no silent `None` |
| NE-04 | P-42/P-77/P-91/P-94 | Outbound reqwest clients built without `.timeout()` — 8+ sites; hung external endpoints block indefinitely | Every `reqwest::ClientBuilder` MUST call `.timeout(Duration::from_secs(30))`; CI gate: zero `Client::new()` outside test files |
| NE-05 | P-17 | Cache-key proxy on agent description (not resolved instruction + tools hash) | Cache keys must be content hash of (resolved instruction bytes + sorted tool declarations); VP candidate |
| NE-06 | P-59 | Guardrails cover user-input + model-output only; tool/RAG/memory ingress unguarded | Content-validation hook must fire on tool-result ingress; Domain A holdout must assert indirect prompt injection rejected |
| NE-07 | P-66 | `.expect()` panic in library constructor (WASM engine init) | All library constructors return `Result`; `Default` must not delegate to fallible ctor; CI: deny-expect-in-lib lint |
| NE-08 | P-43 | Hard-wired in-memory idempotency map, rate-limit buckets, run state; no durability seam; no eviction | `IdempotencyStore`/`RateLimitStore`/`RunStore` traits required; durable backends first-class in v1; LRU+TTL default for in-memory |
| NE-09 | P-63 | Per-tool retry bound keyed by args-hash; global bound defaults to None; termination illusory | Retry bound keyed on `(tool_name)` not args; finite `global_limit` non-None default; circuit-breaker on by default |
| NE-10 | P-76/P-44 | Workspace-wide bare-`String` `#[derive(Debug)]` API keys; credentials serialize to JSON | Every API key type: newtype + `impl Debug → "<redacted>"`; no `#[derive(Serialize)]`; no `Deref<Target=str>` |
| NE-11 | P-32 | Encryption covers session STATE only; event payloads stored plaintext; rotation errors `let _ =` | Encryption must cover both state AND event payloads; rotation errors must propagate; both are VP candidates |
| NE-12 | P-34 | Identity triple collapses to bare `session_id` at append boundary; cross-tenant guard is runtime-only | Triple-addressed ops are the only code path; triple flows from trait method to SQL WHERE; Kani VP for tenancy partition |
| NE-13 | P-41 | Streaming run endpoint emits task-state stubs; never invokes engine; streaming ≠ unary | Streaming and unary endpoints behaviorally equivalent from day 1; holdout must assert identical final answer |
| NE-14 | P-45 | `SecurityConfig::default()` → CORS wildcard + unauthenticated debug route | `default()` must be secure (CORS denied, debug route gated); Phase-3 security gate: assert 403 on debug routes |
| NE-15 | P-64 | Multi-turn score merge is order-dependent; judge infra failure = quality fail | Arithmetic mean for score aggregation; `JudgeResult::InfraError` as third outcome; single agent run per eval case |
| NE-16 | P-60 | macOS Seatbelt profile is allow-by-default for file reads (`(allow default)` base rule) | macOS sandbox must be deny-by-default (`(deny default)` base); explicit `(allow file-read* (subpath ...))` per path |
| NE-17 | P-28 | Nondeterministic reducer application order (`buffer_unordered` completion-order folding) | Writes applied in deterministic sorted order keyed on task identity; Kani/proptest VP: identical output regardless of arrival order |

---

## Section 5: Outcome Options Matrix

The four outcomes assessed, scored against four criteria.

**Scoring scale:** HIGH / MEDIUM / LOW (with HIGH = most favorable for that criterion)

---

### Outcome (a) — Pure LangChain-semantics port; adk-rust as prior-art reference only

Design ferrochain entirely from the LangChain/LangGraph semport extraction. Treat adk-rust
only as a reference for design decisions that have no LangChain analog.

| Criterion | Score | Reasoning |
|-----------|-------|-----------|
| Fidelity to LangChain ecosystem semantics | HIGH | 100% alignment; no reconciliation needed |
| Production-grade merit | MEDIUM | Forfeits 27 ADOPT + 16 ADAPT patterns from adk-rust that have superior test depth or solve gaps LangChain does not address (error taxonomy CONFLICT-6, HTTP hygiene P-35–P-38, typestate builder P-09, sandbox P-47–P-49). Will likely reinvent inferior versions of these. |
| Delivery risk | MEDIUM-HIGH | More design-from-scratch surface; NE-04 timeout discipline, NE-10 credential newtypes, NE-07 constructor safety all require independent discovery |
| Phase-1 spec complexity | MEDIUM | Familiar domain; no cross-corpus reconciliation; but 10 conflict ADRs must be resolved regardless |

---

### Outcome (b) — Hybrid: LangChain API surface + selected adk-rust internal patterns (RECOMMENDED)

Preserve the LangChain/LangGraph API surface (market premise per D7 white-space analysis) as
the external contract. Adopt the 27 ADOPT + 16 ADAPT adk-rust patterns as internal implementation
guidance where they are stronger than LangChain's analogs. The 27 REJECT patterns become
counter-example BCs and VPs. The 10 conflicts are resolved per Section 3 recommendations.

| Criterion | Score | Reasoning |
|-----------|-------|-----------|
| Fidelity to LangChain ecosystem semantics | HIGH | API surface preserved; internal implementation is not user-visible. CONFLICT-6 error taxonomy is ferrochain-native anyway (not exposed via LangChain API). |
| Production-grade merit | HIGH | Best of both corpora: LangGraph's BSP/HITL/durability model for the graph engine (D7/D9/D11 mandated) + adk-rust's error taxonomy, HTTP hygiene, typestate, sandbox, retry combinator, usage normalization. 17 NE requirements become BCs and VPs. |
| Delivery risk | MEDIUM | More design decisions to resolve at Phase 1 (10 conflict ADRs, 16 ADAPT pattern adaptations); however these decisions must be made under any outcome — the conflicts are inherent to the product scope |
| Phase-1 spec complexity | MEDIUM-HIGH | Hybrid requires explicit border-drawing between API surface and internal patterns; 9 high-stakes flags become gate questions; but this is exactly the Phase-1 architect + product-owner work the pipeline is designed for |

---

### Outcome (c) — adk-rust wholesale adoption per subsystem

Build ferrochain by wholesale-adopting adk-rust's design choices subsystem by subsystem,
adapting only what is necessary for Rust-ecosystem publication.

| Criterion | Score | Reasoning |
|-----------|-------|-----------|
| Fidelity to LangChain ecosystem semantics | LOW | adk-rust's graph engine is fundamentally incompatible with LangGraph semantics: CONFLICT-1 (BSP vs edge-walker, nondeterministic writes), CONFLICT-2 (no per-task durability), CONFLICT-3 (no resume-value HITL), CONFLICT-4 (wall-clock ordering). These are the exact capabilities D7 identifies as the market white-space. Wholesale adoption would ship a product that cannot satisfy the LangGraph semantics that distinguish ferrochain. |
| Production-grade merit | MEDIUM | Strong in error taxonomy, HTTP hygiene, provider layer, sandbox. Weak in graph engine, checkpoint durability, HITL — which are ferrochain's P0 differentiators. The adk-rust graph engine would need to be replaced in a follow-on cycle, creating technical debt before v1. |
| Delivery risk | HIGH | Adopting an incompatible graph engine requires rework before holdout evaluation (Phase 4) can pass — the holdout domains (A/B/C) all require LangGraph HITL or durable multi-step execution semantics. |
| Phase-1 spec complexity | LOW | Less up-front spec work; but spec complexity is deferred to a rework cycle |

---

### Outcome (d) — Re-baseline on adk-rust; no LangChain semantics port

Abandon the semport framing and re-baseline ferrochain as an independent Rust agent framework
that builds on adk-rust's design. LangChain/LangGraph becomes inspiration only.

| Criterion | Score | Reasoning |
|-----------|-------|-----------|
| Fidelity to LangChain ecosystem semantics | LOW | This is a full pivot away from D7's market premise. |
| Production-grade merit | MEDIUM | adk-rust is a production-grade framework; however it explicitly does not solve the LangGraph BSP + durable HITL niche. The resulting product would compete directly with adk-rust on its own ground, rather than occupying the identified white-space. |
| Delivery risk | LOW-MEDIUM | Lower implementation risk (no semport reconciliation); but strategic risk is HIGH — the market white-space D7 identified (LangGraph runtime with durable checkpointing + formal verification) would remain unoccupied; R4 langgraph crate competitor would dominate |
| Phase-1 spec complexity | LOW | No semport work; but D1–D16 decisions require significant re-evaluation |

---

### Decision Rationale

**CRITICAL FINDING (from Part 3):** adk-rust's graph engine (CONFLICTS 1–4) lacks all three
guarantees that D9/D11 require: BSP determinism, per-task durability, and resume-value HITL.
These are not gaps that can be patched onto adk-rust wholesale — they require designing the
graph engine from scratch using LangGraph's execution model as the reference. This CRITICAL
finding eliminates Outcomes (c) and (d) as strategic choices: both rely on adk-rust's graph
engine being usable as-is, which it is not for ferrochain's declared product scope.

The choice between (a) and (b) is a quality question. Outcome (b) is unambiguously stronger:
it captures 43 proven production patterns from adk-rust without compromising the LangChain API
surface that is ferrochain's market premise. The additional Phase-1 complexity of Outcome (b)
is the work of resolving 10 conflict ADRs and specifying 16 adaptations — work that produces
better specs, not less of them.

**RECOMMENDED OUTCOME: (b) — Hybrid**

**RUNNER-UP: (a) — Pure LangChain port**
Viable if Phase-1 spec complexity must be minimized. Leaves production quality on the table
but avoids cross-corpus reconciliation work. Acceptable only if the 9 high-stakes flags (HS-1
through HS-9) are explicitly deferred with documented risk decisions — which is itself a
Phase-1 gate.

---

## Section 6: Phase 1 Carry-Forward List

### BC Candidates (mandatory — must appear in Phase-1 product-owner spec)

| Category | Item | Source |
|----------|------|--------|
| Error taxonomy | `FerrochainError` 2D component×category struct, RetryHint, machine code, RFC-7807 emission | CONFLICT-6 (ADOPT adk P-01/P-04) |
| Graph executor — BSP determinism | Writes applied in deterministic task-identity-sorted order; `InvalidUpdateError` on concurrent LastValue writes | CONFLICT-1; NE-17; VP candidate |
| Graph executor — HITL | Per-task scratchpad, FIFO resume-value delivery, node-re-executes-from-start, `Command(resume=value)` | CONFLICT-3; HS-3 |
| Checkpoint durability | Three-tier (sync/async/exit), sync default, per-task `put_writes`, monotonic logical-clock IDs, parent-pointer fork | CONFLICT-2; CONFLICT-4; HS-2 |
| Session tenancy | Triple-addressed ops only; no bare-session_id fallback; tenancy VP with Kani harness | NE-12 |
| Encryption at rest | Both state AND event payloads encrypted; rotation errors propagate | NE-11 |
| Streaming equivalence | Streaming and unary endpoints drive same engine; same final answer; holdout assertion | NE-13; CONFLICT-10 |
| Content validation scope | Guardrail hook at tool-result ingress + RAG ingress; provenance tagging | NE-06; HS-8; Domain A |
| Budget governance | allow/escalate/deny policy trait + composable + append-only journal shape | HS-4/HS-9; Domain B |
| Sandbox enforcement precondition | Policy-backend enforcement binding; `Err(PolicyNotEnforceable)` on mismatch | NE-01; Domain C |
| Security posture defaults | `SecurityConfig::default()` = CORS denied; debug routes require explicit opt-in | NE-14 |
| Credential newtypes | Every API key type: `impl Debug → "<redacted>"`; no Serialize; no bare Deref | NE-10; CLAUDE.md |
| Constructor `Result` contract | All library constructors return `Result`; no `.expect()` / `.unwrap()` / `assert!` in non-test | NE-07; CLAUDE.md |
| Outbound timeout gate | Every `reqwest::ClientBuilder` must call `.timeout(30s)`; CI lint enforced | NE-04; CLAUDE.md |
| Tool-retry termination | Retry bound keyed on `(tool_name)` not args-hash; finite global_limit default; circuit-breaker on | NE-09 |
| Eval correctness | Arithmetic mean aggregation; `JudgeResult::InfraError` third outcome; single agent run per case | NE-15 |
| Splitters (R8) | Explicit BC + holdout for code-point vs byte-length split boundaries on non-ASCII text | R8 (Risk Register) |
| NamedBarrierValue / EphemeralValue (R10) | Product-owner authors BCs + Red Gate tests from behavior (no upstream tests) | R10 (Risk Register) |
| MCP test voids (R11) | bare-ToolException re-raise path + `__aenter__` NotImplementedError must become explicit Red Gate tests | R11 (Risk Register) |

### Holdout Scenario Candidates

| Domain | Scenario | Source |
|--------|----------|--------|
| Domain A (SOC analyst) | Indirect prompt injection via tool result does not bypass content validation | NE-06; HS-8 |
| Domain A | Streaming event taxonomy exposes per-step reasoning audit trail | CONFLICT-5 |
| Domain B (dark factory) | Multi-day durable run survives process restart; per-task `put_writes` credits completed nodes | CONFLICT-2; NE-08 |
| Domain B | Budget-governance gate halts / degrades run when token+cost ceiling reached | HS-4; HS-9 |
| Domain B | Streaming endpoint and unary endpoint produce identical final answer | NE-13 |
| Domain C (OpenClaw) | User-private memory does not bleed across scopes; GDPR erasure removes all traces | CONFLICT-7 |
| Domain C | Workspace symlink escape attempt returns `Err(WorkspaceEscape)` | NE-02 |
| Cross-domain | HITL resume-value injection: human decision propagates into interrupted node's execution | CONFLICT-3; HS-3 |

### ADR Topics (Phase-1 architecture phase)

| ADR Topic | Flags / Conflicts | Priority |
|-----------|------------------|----------|
| Graph execution model: BSP channel-version-triggered implementation | HS-1, HS-2, CONFLICT-1, CONFLICT-2, D9 gate | P0 — human gate required (D9) |
| Checkpoint IDs and logical clock | CONFLICT-4 | P0 |
| HITL interrupt/resume contract | HS-3, CONFLICT-3 | P0 |
| Error taxonomy: `FerrochainError` 2D struct | CONFLICT-6 | P0 |
| Streaming event taxonomy | CONFLICT-5 | P1 |
| Partner crate architecture: standalone SDK crate vs embedded adapter | HS-6, P-67 | P1 |
| Proc-macro design for tool/graph wiring + schemars placement | HS-7, P-72, D5 | P1 |
| Budget governance primitive shape | HS-4, HS-9, P-46, P-73 | P1 — Domain B forcing function |
| Content-validation scope and provenance tagging | HS-8, P-55, P-59 | P1 — Domain A/C forcing function |
| Memory service global-overlay default | CONFLICT-7 | P1 — Domain C |
| Delta checkpoint granularity (per-channel vs whole-state) | CONFLICT-9 | P2 |
| Agent composition model (graph-as-agent vs composite-tree ergonomics) | CONFLICT-8 | P2 |

### a2a-v1 Runtime Test Obligations (Phase-4 carry-forward from certification)

Per STATE.md certification carry-forward — four a2a-v1 runtime-test obligations from the
certification passes that must route to Phase-4 holdout evaluation:

1. `message_stream` must invoke the engine and produce real model output (not task-state stubs).
2. Input_REQUIRED context-resume state machine (INPUT_REQUIRED → Working → Completed) must be
   tested end-to-end, including idempotent resume after process restart.
3. A2A client retry with outbound timeout: the timeout-retry branch must be reachable (requires
   `.timeout()` on the client, which NE-04 mandates).
4. Rate-limit bucket behavior across distinct caller IDs under LRU eviction (NE-08 seam).

Note: ferrochain-server is first-party per D13 and not A2A-protocol-compatible; these obligations
translate to equivalent ferrochain-server holdout assertions, not A2A wire compliance.

### 17 Negative-Evidence Requirements (Phase-1 BC / ADR / policy anchoring)

All 17 NE items from Section 4 must be anchored to a BC, ADR, or CLAUDE.md policy entry during
Phase 1. No NE item may enter the Phase-2 story decomposition without an explicit anchor. The
table in Section 4 identifies the requirement for each item; the Phase-1 product-owner and
architect must confirm the anchor type (BC / ADR / CI lint / CLAUDE.md policy) before Phase-1
gate closes.

### 9 High-Stakes Pattern Flags (Phase-1 gate items)

All 9 HS flags from Section 2 must be resolved at the Human Direction Gate (Section 7) or
during Phase-1 spec crystallization before any BC can be authored in the affected area.

---

## Section 7: Questions for the Human Direction Gate

These are the decisions only the human can make. Each question states the options and includes
the architect's recommendation.

---

**Q1 — OUTCOME CHOICE (blocking)**

Which outcome does the project adopt?

Options:
- **(b) Hybrid** — LangChain API surface + 27 ADOPT + 16 ADAPT adk-rust internal patterns.
  10 conflict ADRs + 16 adaptation specs required in Phase 1. [RECOMMENDED]
- **(a) Pure port** — LangChain semantics only; adk-rust as prior-art reference. 9 high-stakes
  flags require documented risk deferrals.
- **(c) adk-rust wholesale** — Not recommended; graph engine incompatible with D9/D11.
- **(d) Re-baseline** — Not recommended; abandons D7 white-space positioning.

Recommendation: **(b) Hybrid.**

---

**Q2 — HITL SCOPE (D9/D11 gate, blocking Phase-1)**

Is the full LangGraph HITL contract (per-task scratchpad, FIFO resume-value delivery,
node-re-executes-from-start replay, `Command(resume=value)` API) a Phase-1 BC, or is it
deferred to a later cycle?

Options:
- **Phase-1 BC** — graph state-machine and executor design must accommodate the scratchpad
  from day 1; cannot be retrofitted. Domains A and B holdout scenarios require it.
- **Deferred** — requires a documented risk decision acknowledging that Domains A and B holdout
  scenarios will fail until HITL ships.

Recommendation: **Phase-1 BC.** This is the most expensive retrofit in the adk-rust corpus
(CONFLICT-3 analysis). The D9 design conversation gate is the right venue.

---

**Q3 — PER-TASK DURABILITY SCOPE (D11.3, blocking Phase-1)**

Is the per-task `put_writes` tier (sync durability default) a Phase-1 BC, or explicitly
deferred with a documented risk?

Options:
- **Phase-1 BC** — design the checkpoint store with per-task intermediate writes from the start.
- **Deferred** — step-boundary-only durability for v1; per-task writes in a follow-on cycle.
  Risk: Domain B dark-factory holdout (multi-day runs surviving crashes) will fail.

Recommendation: **Phase-1 BC.** D11.3 already mandates this. Confirming it at the gate
commits the checkpoint-store ADR to include `put_writes`.

---

**Q4 — BUDGET GOVERNANCE SCOPE (Domain B, Phase-1)**

Is the budget-governance primitive (allow/escalate/deny policy trait + composable + append-only
evidence journal) a Phase-1 BC, or deferred?

Options:
- **Phase-1 BC** — shapes `RunConfig` design; Domain B holdout (dark factory cost ceiling)
  requires it.
- **Deferred** — requires a documented risk decision; Domain B holdout scenario scope
  must be adjusted to exclude budget-ceiling assertion until shipped.

Recommendation: **Phase-1 BC** if the dark factory holdout is to be evaluated at Phase 4.
If Domain B is deferred, document it explicitly so Phase-2 story decomposition does not
allocate BC capacity for it.

---

**Q5 — PARTNER ARCHITECTURE (HS-6, shapes workspace beyond D6)**

Does ferrochain adopt the standalone-SDK-crate split for partner crates (adk-rust P-67 pattern:
independent wire-SDK + thin trait adapter)?

Options:
- **Yes — standalone SDK split** — `ferrochain-anthropic-sdk` + `ferrochain-anthropic` adapter;
  similarly for OpenAI and Ollama. Wire contract drift is a build error. SDK is independently
  publishable. Adds crates to workspace beyond D6's enumeration.
- **No — single-crate embedded** — simpler workspace per D4; less reuse surface; partner crates
  are not independently publishable without pulling framework deps.

Recommendation: **Standalone SDK split.** The compile-time drift guarantee is a meaningful
correctness property for a partner adapter. Workspace complexity is bounded (D4 remains intact).

---

**Q6 — PROC-MACRO SCOPE (HS-7, blocking graph BC authoring)**

Does ferrochain ship `#[tool]` / `#[entrypoint]` / `#[task]` proc-macros in Phase 1/2?

Options:
- **Phase 1/2** — zero-boilerplate tool registration and graph wiring; D5 schemars placement
  resolved via ADR before BC authoring. [RECOMMENDED]
- **Phase 2 only** — macros deferred after core graph BCs are authored without them.
- **Deferred** — document risk that tool DX story depends on unresolved schemars/macro decision.

Recommendation: **Phase 1/2 with D5 ADR first.** The macro design resolves D5 (schemars
placement) which blocks graph BC authoring anyway.

---

**Q7 — BSP DETERMINISM VP OBLIGATIONS (HS-5, blocks Phase-6 formal hardening scope)**

Are the following BSP invariants committed as VP obligations for Phase-6 formal hardening,
before the architecture phase locks them out?

- VP: Concurrent node outputs produce identical reduced state regardless of arrival order (NE-17)
- VP: Round-trip delta checkpoint `apply(s1, diff(s1,s2)) == s2` per channel (CONFLICT-9)
- VP: Session triple-address uniquely partitions session rows (NE-12)
- VP: Encryption wrapper covers both state and event payloads (NE-11)
- VP: No file operation observes content outside declared workspace root (NE-02)
- VP: Cache key differs for two agents with identical descriptions but different resolved instructions (NE-05)

Options:
- **Yes — commit as VP obligations now.** Locks them into Phase-6 harness planning from Phase 1.
- **Defer to Phase-1 architect.** Architect makes final VP/not-VP call during architecture phase.

Recommendation: **Commit the first three (NE-17, delta round-trip, NE-12) as mandatory VP
obligations now.** They correspond to the highest-stakes correctness invariants and are load-bearing
for the graph engine design. The remaining three can be confirmed by the Phase-1 architect.

---

**Q8 — CONTENT VALIDATION SCOPE (HS-8, Domain A/C forcing function)**

Does ferrochain's Phase-1 spec include a provenance-tag seam and guardrail-on-ingress hook for
tool-result, RAG, and memory content entering the model context (not only user-input + model-output)?

Options:
- **Yes — Phase-1 BC.** Domain A SOC analyst holdout requires it; this is a Phase-1 forcing function.
- **Deferred.** Risk: Domain A holdout scenario (indirect prompt injection) fails without it.

Recommendation: **Phase-1 BC.** The ingress-guardrail seam affects the `InvocationContext` and
tool-result routing design, which cannot be added cleanly after the core agent loop is specified.

---

**Q9 — SPLITTERS / MEME TEST VOIDS ROUTING (R8, R10, R11)**

R8 (splitters code-point parity), R10 (NamedBarrierValue/EphemeralValue test voids), and R11
(MCP test voids) are all High/Medium risks in the Risk Register. Do these enter the Phase-1
product-owner BC backlog as explicit Red Gate test obligations, or are they deferred to Phase-3?

Options:
- **Phase-1 BC backlog.** Product-owner authors BCs + Red Gate tests from behavior.
  Risk of getting behavior wrong is borne at spec time, not implementation time.
- **Phase-3 implementation notes.** Implementers discover correct behavior at TDD time.

Recommendation: **Phase-1 BC backlog.** These are correctness gaps in the upstream reference
corpus (not bugs to fix later) — they must be decided at spec time to avoid encoding the wrong
behavior into the first implementation.
