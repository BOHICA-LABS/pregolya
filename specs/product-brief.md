---
document_type: product-brief
level: L1
version: "1.2"
status: approved
producer: product-owner
timestamp: 2026-07-17T00:00:00Z
phase: 1a
inputs:
  - .factory/planning/market-intel.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
  - .factory/planning/naming-decision-study.md
  - .factory/semport/reference-manifest.md
input-hash: "9d9847b"
traces_to: ""
decisions: [D1, D2, D3, D4, D5, D6, D7, D8, D9, D11, D12, D13, D17]
changelog:
  - "v1.2 (2026-07-17): Provenance-integrity fix — removed .factory/STATE.md from inputs: list. STATE.md is a live pipeline-state file with no spec-content signal for this brief. All genuine derivation sources (market-intel, COMPARATIVE-ASSESSMENT, holdout domain files, naming study, semport reference manifest) are already listed. Input-hash recomputed."
  - "v1.1: SR-01 compress core sections; SR-02 relocate security defaults to Overflow; SR-03 mark locked tech; SR-04 reformulate time-to-market criterion"
---

# Product Brief: ferrochain

## What Is This?

ferrochain is a Rust implementation of the LangChain v1 architecture — a production-grade,
async-native agent orchestration framework that gives Rust developers the same conceptual
model as LangChain/LangGraph (chains, StateGraph, HITL, durable checkpointing, provider
conformance) without the Python runtime. It occupies the confirmed white space in the Rust
LLM ecosystem: no existing crate ships a StateGraph execution engine with durable per-task
checkpointing, human-in-the-loop interrupts, a provider standard-tests conformance suite,
and a formally-verified core — the four-part combination that market intelligence confirms
no competitor has (market-intel.md §4, ASM-003/ASM-004). The product is a Cargo workspace
of independently-publishable crates, not a monolith; every layer composes with standard
Rust async idioms and never requires the Python runtime.

## Who Is It For?

Primary users are Rust developers building production AI agent systems who know
LangChain/LangGraph semantics and need them in a language where Python is not an option
or is a performance liability. Three holdout-domain archetypes anchor the design (D8):

| Persona | Pain Point | Current Workaround | Source |
|---------|-----------|-------------------|--------|
| Security/platform engineers building SOC-analyst agents | Durable multi-step pipelines with HITL risk-tiered authorization gates, MCP tool integration, forensic audit trails, and prompt-injection isolation at tool-result boundaries | Patch together langchain-rust + rig + swiftide manually; accept partial coverage | domain-a-soc-analyst.md §5, §10 |
| Autonomous software development teams building dark-factory pipelines | Multi-day graph runs surviving process restarts, parallel sub-agent fan-out, per-run budget/cost metering, convergence-loop support | Python LangGraph (GIL bottleneck) or custom Rust with no durable checkpoint | domain-b-dark-factory.md §5 |
| Personal AI assistant / gateway builders (OpenClaw-like) | Persistent sessions, pluggable multi-channel ingress, local-first single-binary deployment, long-horizon cross-session memory, default-on execution isolation | OpenClaw (TypeScript, 2–3 GB Docker image, host-first unsafe defaults) | domain-c-openclaw.md §5 |
| Rust developers generally building LLM applications | Must cobble together langchain-rust + rig + swiftide + rust-langgraph; none provides LangGraph runtime or formal verification | Manual multi-crate integration; no standard provider conformance contract | market-intel.md §1, §3 |

**Secondary users:** provider / tool vendors who want their integrations conformance-tested via
ferrochain-standard-tests; Rust infrastructure teams (edge/WASM/embedded) where Python is
architecturally excluded.

## Scope

### In Scope

Wave 0 — Core primitives (P0, unlocks everything)
- `ferrochain-core`: typed message/content primitives (Runnable, Message, ContentBlock), tool
  schema traits, FerrochainError 2D component×category error taxonomy (CONFLICT-6/D17),
  secure-by-default construction posture (NE catalog: NE-01/NE-02/NE-04/NE-07/NE-10/NE-14/D17;
  PRD-level detail in Overflow §Security-PRD-Carry-Forward)
- `ferrochain-splitters`: text splitter capability with explicit BC for code-point vs
  byte-length boundary parity on non-ASCII input (R8/D17-Q9)

Wave 1 — Graph runtime + server (P0 lead differentiator, D7)
- `ferrochain-graph`: LangGraph StateGraph engine — BSP scheduling with deterministic reducer
  order (CONFLICT-1/NE-17), Send API fan-out, conditional edges, full HITL interrupt/resume
  contract (CONFLICT-3/D17-Q2)
- `ferrochain-checkpoint`: three-tier durable checkpointing (sync default, crash-safe), per-task
  put_writes (CONFLICT-2/D17-Q3), monotonic logical-clock checkpoint IDs (CONFLICT-4),
  msgpack wire format [locked: D11.2], SQLite + in-memory backends [locked: D11.3],
  Postgres stretch target
- `ferrochain-server`: first-party durable-run HTTP server (D13); threads, assistants, cron
  scheduler, streaming and unary run equivalence (NE-13/D17); no LangGraph Platform wire-compat
- `ferrochain-sandbox`: sandboxed tool execution (SS-13/ARCH-INDEX); WASM/container enforcing
  backend default, workspace path confinement, process backend as loud opt-in (NE-01/NE-02/D17)

Wave 2 — Partners + conformance + MCP (P1, D7 roadmap)
- `ferrochain-openai`, `ferrochain-anthropic`, `ferrochain-ollama`: first-party provider
  crates (D3 early-integration priority); standalone SDK crate split architecture (HS-6/D17-Q5)
- `ferrochain-mcp`: port of langchain-mcp-adapters==0.3.0 (D1 amendment); MCP client adapter
  for security, productivity, and custom server integration (server list in Overflow §MCP-Surface)
- `ferrochain-memory`: long-horizon cross-session memory (SS-15/ARCH-INDEX); vector search,
  scoped memory isolation, GDPR erasure (D17-Q4 memory holdout; domain-c cross-session requirement)
- `ferrochain-standard-tests`: port of LangChain's langchain-tests conformance suite; all
  Wave 2 provider crates must pass before v1 release

Post-v1 community ecosystem
- Demand-ranked community integration crates: conformance-validated via ferrochain-standard-tests,
  published independently (not in-tree), third-party contributed (D1 amendment)

Cross-cutting (all waves)
- Formal verification pipeline: Kani proofs + cargo-fuzz [both locked: D17-Q7] for
  ferrochain-core + ferrochain-graph invariants (BSP determinism VP (NE-17),
  session triple-address VP (DI-005/NE-12), workspace path confinement VP (DI-007/NE-02)
  — top-3 obligations per D17-Q7)
- Phase-1 BC backlog (D17-Q2/Q3/Q4/Q8/Q9): HITL contract, per-task durability, budget
  governance, content provenance/guardrail-on-ingress, R8/R10/R11 upstream test-void BCs —
  all authored from behavior, not deferred to Phase 3 (detail in Overflow §D17-BC-Backlog)

### Out of Scope

- Full 1,051-module langchain-community port: archived by LangChain Inc. 2026-06-19;
  community integrations are third-party contributed, not in-tree (D1)
- Wire-compatibility with LangGraph Platform or any external managed graph runtime (D13)
- A2A/AWP/ACP protocol implementations: out-of-scope per D13; COMPARATIVE-ASSESSMENT
  Section 3 (all A2A patterns NOT-APPLICABLE)
- LangGraph kafka scheduler: removed from LangGraph v1.x; not a port target (reference-manifest.md)
- Voice/audio/canvas/device-node bridges: library product; no UX phase (explicit architect decision needed)
- Managed hosting / LangGraph Platform-equivalent SaaS: possible future monetization path,
  not v1 scope (market-intel.md §2)
- OCSF-style telemetry normalization at core layer: integration-layer concern for SOC domain
  consumers; explicit in/out decision required in architecture phase (domain-a §5)
- SEC disclosure / SOC 2 compliance semantics as in-product features: low-confidence,
  flagged for explicit architect decision (domain-a §4)
- Python runtime or PyO3 interop: one-way Python-checkpoint import tool is in scope;
  a general Py bridge is not
- langchain-community v1.0.0a1 API tracking: alpha churn risk; community wave targets
  demand-ranked integration surface, not the archived module manifest

## Success Criteria

| Outcome | Metric | Target | Source |
|---------|--------|--------|--------|
| Community adoption | crates.io monthly downloads for ferrochain-core | ≥ 4,000/month within 12 months of public release (parity with langchain-rust baseline) | market-intel.md §2 (SOM), ASM-005 |
| Competitive time-to-market | ferrochain-graph durable-checkpointing GA release date vs. R4 watchlist competitor announcements | Binary: ferrochain-graph durable-checkpointing GA ships before any competing Rust framework announces equivalent GA; measured at release date against R4 watchlist. **Human may substitute a calendar target at Phase-1 approval gate.** | market-intel.md §1 (R4 watchlist), D7 rationale |
| Provider conformance | ferrochain-standard-tests pass rate for ferrochain-openai, -anthropic, -ollama | 100% conformance (streaming, tool-calling, structured output, error propagation, token accounting) before v1 release | market-intel.md §4 differentiator #2 |
| Holdout evaluation fidelity | VSDD wave-gate: mean holdout score and per-critical-scenario floor | Mean ≥ 0.85; each critical holdout ≥ 0.60; no rounding; all three domains pass Phase 4 gate | VSDD wave-gate protocol; domain-a §6, domain-b §6, domain-c §7 |
| Formal verification coverage | VP coverage: BSP determinism (NE-17), session triple-address partition (DI-005/NE-12), workspace path confinement (DI-007/NE-02) | All 3 committed VP obligations (D17-Q7) pass Kani harness before v1 convergence | D17-Q7; COMPARATIVE-ASSESSMENT §6 |

## Constraints & Integration Points

**Language and runtime**
- Rust only for all production crates; Python reference corpus (langchain 1.3.13, langgraph
  1.2.9, langchain-mcp-adapters 0.3.0, adk-rust v1.0.0) is analysis-only (reference-manifest.md v1.4.0)
- Minimum supported Rust edition/version: set in Phase-1 architecture ADR

**Workspace topology**
- Single Cargo workspace per D4; crates publish individually
- ferrochain brand namespace (18 publishable crates — authoritative source: ARCH-INDEX §Canonical Crate Roster):
  ferrochain (facade), ferrochain-core, ferrochain-graph, ferrochain-checkpoint,
  ferrochain-openai, ferrochain-anthropic, ferrochain-ollama, ferrochain-mcp, ferrochain-community,
  ferrochain-splitters, ferrochain-standard-tests, ferrochain-server, ferrochain-sandbox,
  ferrochain-memory, ferrochain-macros,
  ferrochain-openai-sdk, ferrochain-anthropic-sdk, ferrochain-ollama-sdk
  (D6 base 9 + D1 mcp/standard-tests + D13 server + P2-05 sandbox/memory + ADR-008 macros + D17-Q5 3×-sdk;
  updated ADV-P1D-PASS-3 F-P3-04)
- Partner crate architecture: standalone SDK crate split (HS-6/D17-Q5); ferrochain-openai-sdk,
  ferrochain-anthropic-sdk, ferrochain-ollama-sdk do NOT depend on ferrochain-core (per ADR-007)

**API surface and semantic fidelity**
- External API surface: LangChain v1 semantic fidelity per D17 HYBRID outcome; internal
  implementation uses 43 ADOPT/ADAPT patterns from adk-rust v1.0.0 (COMPARATIVE-ASSESSMENT §5)
- All 17 NE requirements are first-class BCs, ADRs, or CI policies; must be anchored before
  Phase-2 story decomposition (COMPARATIVE-ASSESSMENT §4)

**File size and modularity standard (D12)**
- Production code: 500 lines soft / 750 hard (CI fail on `cargo xtask check-file-size`)
- Test code: 1,000 lines soft / 1,500 hard
- Exceptions via `xtask/file-size-allowlist.toml`

**Phase-1 gates (D9, D5)**
- D9: architect must present ≥2 alternatives for graph execution-model ADR before lock;
  D11 steers apply (D11.1 HYBRID engine, D11.2 msgpack, D11.3 three-tier durability, sync default)
- D5: schemars/proc-macro ADR required before proc-macro BCs can be authored (D17-Q6)

**Integration points (Wave 1)**
- ferrochain-mcp targets langchain-mcp-adapters==0.3.0 (D2); verified active MCP server
  surface spans security, productivity, and custom integration (Overflow §MCP-Surface)
- Early provider integrations (D3): OpenAI, Anthropic, Ollama; full partner set in Wave 2

**Branding and discoverability**
- Do not use LANGCHAIN or LANGGRAPH marks in any crate name (naming-decision-study.md §3)
- Positioning tagline: "A Rust implementation of the LangChain v1 architecture"
- crates.io keywords: llm, agent, rag, nlp, ai; GitHub topics to match; submit to
  jondot/awesome-rust-llm and rust-unofficial/awesome-rust at launch

**Security posture**
- Secure-by-default construction: the 17 NE catalog requirements (COMPARATIVE-ASSESSMENT §4,
  D17) are first-class BCs, ADRs, or CI policies; PRD-level specification in Overflow §Security-PRD-Carry-Forward.

## Open Questions

None outstanding at brief level. Phase-1 architect gate items (not brief-level open questions):
D9 graph execution-model ADR (≥2 alternatives, human gate), D5 schemars/proc-macro ADR
(D17-Q6), OCSF normalization scope decision (domain-a §5), SEC/SOC 2 semantics scope
decision (domain-a §4).

---

## Overflow Context

*This section is NOT loaded into agent context by default. Phase-1 agents pull from it
on-demand via the Extended ToC pattern. Subsections tagged `PRD carry-forward` must be
anchored to BCs, ADRs, or CI policies during Phase-1 spec crystallization.*

### Market Intelligence Summary
Source: .factory/planning/market-intel.md (recommendation: CAUTION → GO-with-conditions;
market-intel gate PASSED per STATE.md)

- AI agents market: $10.9B (2026) → $182.9B (2033) at 49.6% CAGR (Grand View Research)
- Confirmed white space (ASM-003, ASM-004): zero Rust crates have LangGraph runtime +
  checkpointing + conformance suite + formal verification
- Pain validated: GitHub issue #15057 in langchain-ai/langchain explicitly requests a Rust
  LangChain implementation; Rust agents 25-44% faster and 4x less memory than Python equivalents
  (dev.to benchmark)
- GO conditions accepted: D1 scope amendment, D7 ferrograph as P0 differentiator, D6 brand
- Competitor traction baselines: rig ~6k stars (no checkpointing), langchain-rust ~4k
  downloads/month (chain-era model only), langgraph-rust (Onelevenvy) v0.2.x / 599 downloads

### Risk Register Summary
Source: STATE.md Risk Register (binding)

| Risk ID | Summary | Severity | Mitigation |
|---------|---------|---------|------------|
| R4 | Competing langgraph crate (Onelevenvy) velocity — may capture LangGraph identity in Rust | Medium | Lead with ferrochain-graph quality + checkpointing before rig/Onelevenvy match it |
| R6 | Namespace reservation race — cargo login + publish-all.sh not yet run (PENDING HUMAN ACTION) | High | Human must run `cargo login` + .factory/namespace-reservation/publish-all.sh immediately. Reservation must cover all 18 publishable crates (see ARCH-INDEX §Canonical Crate Roster) including ferrochain-sandbox (Wave 1), ferrochain-memory (Wave 2), ferrochain-macros (Wave 1), and ferrochain-openai-sdk / ferrochain-anthropic-sdk / ferrochain-ollama-sdk (Wave 2) — updated ADV-P1D-PASS-3 F-P3-04. |
| R7 | langchain-protocol version volatility (v0.0.17 no stable) | Low | Port rationale is version-volatility; not a conformance target |
| R8 | Splitters code-point vs byte-length parity on non-ASCII — no upstream test coverage | High | Phase-1 BC + Red Gate test authored from behavior (D17-Q9) |
| R10 | NamedBarrierValue/EphemeralValue have no upstream unit tests | Medium | Phase-1 BC backlog — product-owner authors BCs + Red Gate tests (D17-Q9) |
| R11 | MCP test voids: bare-ToolException re-raise + __aenter__ NotImplementedError untested upstream | Medium | Phase-1 BC backlog — explicit Red Gate tests (D17-Q9) |

### Reference Corpus Pins
Source: .factory/semport/reference-manifest.md v1.4.0

| Corpus | Tag | SHA |
|--------|-----|-----|
| langchain | langchain==1.3.13 | 42f8f79293cfb7589e5bc1d74a8ae4dfd0bf15e3 |
| langgraph | 1.2.9 | 95af6a00718588e7b7ce17310e8006d267896a77 |
| langchain-community | libs/community/v0.4.2 | 7c10a5fa327f6aaaf7c932822a9e5d144891406e |
| langchain-mcp-adapters | langchain-mcp-adapters==0.3.0 | a61c783a7949719a8c3fbe4aeba961f45f3b7849 |
| adk-rust (comparative) | v1.0.0 | a6c79b6f97a338de58d2c0fbf33cac00eaae0f13 |

### D17 HYBRID Outcome — Phase-1 BC Scope Commitments
Source: STATE.md D17, COMPARATIVE-ASSESSMENT.md §6

Five Phase-1 BC categories committed at the Human Direction Gate (all Q2–Q9 accepted verbatim):

1. **HITL contract** (D17-Q2, CONFLICT-3): per-task scratchpad, FIFO resume-value delivery,
   node-re-executes-from-start, Command(resume=value) API — cannot be retrofitted post-graph-design
2. **Per-task durability** (D17-Q3, CONFLICT-2): sync-default put_writes per task in checkpoint
   store; Domain B multi-day holdout depends on this
3. **Budget governance** (D17-Q4, HS-4/HS-9): allow/escalate/deny policy trait, composable,
   append-only evidence journal — Domain B dark-factory holdout requires it
4. **Content provenance / guardrail-on-ingress** (D17-Q8, NE-06/HS-8): provenance-tag seam +
   guardrail hook at tool-result, RAG, and memory ingress — Domain A SOC analyst holdout
5. **R8/R10/R11 BC backlog** (D17-Q9): splitters code-point parity (R8) +
   NamedBarrierValue/EphemeralValue behavioral contracts (R10) + MCP bare-ToolException/
   `__aenter__` contracts (R11) — all authored from behavior, not deferred to Phase 3

This is also the `### D17-BC-Backlog` section referenced from core §Scope.

### Competitive Differentiator Traceability
Source: market-intel.md §4, COMPARATIVE-ASSESSMENT.md §5 (seeded from L2 → PRD Section 6)

| Differentiator | Source | BC anchor (Phase 1) |
|---------------|--------|---------------------|
| LangGraph runtime + durable checkpointing in Rust — no competitor has this | market-intel §4 #1, CONFLICT-1/2/3/4 | Graph BSP determinism + HITL + per-task durability BCs (D17-Q2/Q3) |
| Standard-tests conformance suite — no competitor has this | market-intel §4 #2 | ferrochain-standard-tests conformance BC |
| Formally-verified core (Kani + cargo-fuzz) — no competitor has this | market-intel §4 #3, D17-Q7 | BSP determinism VP (NE-17), session triple-address VP (DI-005), workspace path confinement VP (DI-007) |
| Idiomatic async-first trait design with typed ContentBlock | market-intel §4 #4, CONFLICT-6 | FerrochainError 2D struct BC, typed ContentBlock BC |
| Provider conformance + migration story from LangChain Python v1 | market-intel §4 #5 | ferrochain-standard-tests + "Coming from LangChain?" docs |

### Security Defaults — PRD Carry-Forward
*Tag: PRD carry-forward. Source: NE catalog (COMPARATIVE-ASSESSMENT §4), D17, CLAUDE.md D10.*
*Every item must be anchored to a BC, ADR, or CI policy before Phase-2 story decomposition.*

| NE | Requirement | Anchor type |
|----|-------------|------------|
| NE-14 | SecurityConfig::default() must be deny-CORS and debug route must be explicitly gated | BC |
| NE-10 | Every API key type: newtype wrapper + `impl Debug → "<redacted>"`; no `#[derive(Serialize)]`; no `Deref<Target=str>` | BC + CI lint |
| NE-07 | All library constructors return `Result`; no `.expect()`/`.unwrap()`/`assert!` in non-test code; Default must not delegate to fallible ctor | BC + CI lint |
| NE-04 | Every outbound HTTP client builder must set a mandatory connection timeout (recommended 30s); zero `Client::new()` outside test files | CI lint gate |
| NE-01 | Enforcing sandbox backend (WASM/container) must be the default; process backend is loud opt-in; `Sandbox::execute` on strict policy against non-enforcing backend returns `Err(PolicyNotEnforceable)` | BC |
| NE-02 | All workspace file operations must call `canonicalize_beneath_root(base, path)` at access time; no file op may observe content outside declared workspace root | BC + VP |

### MCP Server Surface — Integration Reference
*Tag: reference. Source: domain-a-soc-analyst.md §3 (independently cross-verified [V]). D1.*
*This is the §MCP-Surface section referenced from core Constraints.*

| Tool | Status | Governance |
|------|--------|-----------|
| Splunk MCP Server (Splunkbase app 7931) | GA (v1.2.1, Jun 2026) | Official (Splunk LLC) |
| Microsoft Sentinel MCP | GA (Nov 2025) | Official (Microsoft) |
| Okta MCP Server | Active | Official (Okta) |
| ServiceNow MCP Console | Active | Official (ServiceNow) |
| CrowdStrike falcon-mcp | Preview (Aug 2025) | Community — NOT official CrowdStrike product (MIT) |
| VirusTotal mcp-virustotal | Active | Community |
| MISP MCP Server | Active | Community |
| AlienVault OTX otx-mcp | Active | Community |

These validate ferrochain-mcp's prioritization per D1 amendment. Could NOT verify dedicated
MCP servers for Elastic Security, Google Chronicle, SentinelOne, PagerDuty, or Recorded
Future as of mid-2026.
