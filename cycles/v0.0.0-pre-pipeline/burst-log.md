---
document_type: burst-log
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-12T23:14:56Z
cycle: v0.0.0-pre-pipeline
inputs: [STATE.md]
input-hash: "[live-state]"
traces_to: STATE.md
---

# Burst Log — v0.0.0-pre-pipeline

## Burst: pre-pipeline burst 1 — toolchain preflight, reference corpus, arch research (2026-07-12)

**Parent-commit:** 6dca920f9895e11d849ed4f57d67ccc56f608b1b

**Adversary verdict:** n/a — pre-pipeline burst; no spec or implementation artifacts subject to adversarial review yet.

**Files touched (Dim-1): 3 unique files**

- .factory/preflight-report.md
- .factory/semport/reference-manifest.md
- .factory/semport/langchain-research.md

**Codifications:** D1-D6 human decisions locked. Pipeline advanced from INITIALIZED to IN_PROGRESS. .mcp.json gitignored (plaintext API keys resolved). Risks R1-R5 registered.

**Dim-2 Attestation:** n/a — pre-pipeline burst; no Rust code delivered; no behavioral-contract shell gates to run. Reference corpus cloned at pinned SHAs (verified via git -C .reference/langchain rev-parse HEAD).

**Dim-5 Attestation:** n/a — pre-pipeline burst; no WASM hook artifacts produced or modified in this burst.

**Dim-6 Attestation:** n/a — pre-pipeline burst; Cargo workspace not yet initialized; cargo fmt / clippy gates not applicable.

**Dim-7 Attestation:** n/a — pre-pipeline burst; no test suite yet; cargo nextest / bats gates not applicable.

**Closes:** pre-pipeline steps: toolchain-preflight (WARN), reference-corpus-clone (DONE), external-research-langchain-v1-arch (DONE).

---

## Burst: pre-pipeline burst 3 — market-intelligence gate close + repo-init + D1 amendment + semport dispatch (2026-07-12)

**Gate closed:** market-intelligence — PASSED (GO with conditions, human-approved). Evidence: .factory/planning/market-intel.md. White space verified (no Rust crate combines graph-runtime-with-checkpointing + conformance suite + formal verification). Demand validated (upstream issue #15057). Competitor velocity HIGH (rig v0.40). Four conditions accepted by human.

**Decisions recorded:**

| ID | Action | Decision |
|----|--------|----------|
| D1 | AMENDED | langchain-community full 1,051-module port REMOVED. New strategy: integration trait contracts in ferrochain-core + ferrochain-standard-tests conformance suite + NEW ferrochain-mcp crate (port of langchain-mcp-adapters) + curated demand-ranked community crates post-v1 + long tail out-of-tree conformance-validated |
| D2 | UPDATED | Reference corpus final: langchain==1.3.13, langgraph==1.2.9, langchain-community==v0.4.2 (archived; curated-subset only), langchain-mcp-adapters==0.3.0 (SHA a61c783a). Manifest: .factory/semport/reference-manifest.md v1.3.0 |
| D7 | NEW | Wave priority: core → graph → partners. LangGraph runtime + durable checkpointing is P0 lead differentiator |

**Blocking issues resolved:**

| ID | Resolution |
|----|------------|
| B2 | repo-initialization complete. GitHub=BOHICA-LABS/ferrochain (renamed, redirect live); local=/Users/jmagady/Dev/ferrochain (worktree repaired, verified); placeholder crates prepped with publish-all.sh |

**Risks updated:**

| ID | Update |
|----|--------|
| R1 | scheduler-kafka confirmed removed from langgraph 1.2.9; with D1 amendment treat as out-of-scope (severity LOW) |
| R6 | STILL OPEN — crates.io names verified available, publish-all.sh prepped, but human has not yet run it (cargo login required; time-sensitive) |

**Phase transition:** pre-1 steps continuing — semport-analyze pass 1 dispatched (codebase-analyzer on langchain-core / libs/core).

**Files touched:** STATE.md (major update), cycles/v0.0.0-pre-pipeline/blocking-issues-resolved.md (created), cycles/v0.0.0-pre-pipeline/burst-log.md (this entry).

---

### Burst 1 Detail

| Agent | Task | Outcome |
|-------|------|---------|
| dx-engineer | Toolchain preflight — validate rustc 1.95.0, 7 verification tools, gh auth, direnv, .mcp.json | WARN: direnv unenabled (B1 open); .mcp.json had plaintext API keys → resolved via .gitignore |
| devops-engineer | Reference corpus shallow-clone — pin langchain, langgraph, langchain-community at latest stable v1 tags | DONE: 3 repos pinned; note: langgraph initially mis-pinned at 0.3.34 due to tag-sort bug (R5), corrected to 1.2.9 |
| research-agent | External research — LangChain v1 architecture, ecosystem structure, langgraph internals | DONE: .factory/semport/langchain-research.md |

### Human Decisions Recorded

| ID | Decision |
|----|----------|
| D1 | Full ecosystem port scope (langchain-core + langchain v1 + text-splitters + 15 partner packages + FULL langgraph incl. Platform SDK/CLI + FULL langchain-community ~1,051 modules roadmap-phased) |
| D2 | Reference version pins: langchain==1.3.13 / langgraph==1.2.9 / langchain-community==v0.4.2 |
| D3 | Early integrations: OpenAI, Anthropic, Ollama first; then full partner set |
| D4 | Single Cargo workspace; crates publish individually |
| D5 | Dependency disposition mandate: per-package disposition file; pydantic→serde/schemars ADR required before BCs |
| D6 | Naming under research; `langchain` and `langgraph` crate names TAKEN on crates.io |

### Risks Flagged

| ID | Risk |
|----|------|
| R1 | langgraph `scheduler-kafka` removed 0.3.x→1.2.9 — confirm new home before porting |
| R2 | langchain-community API churn (0.4.x stable vs 1.0.0a1 tagged) |
| R3 | LangGraph Platform SDK/CLI → DTU_REQUIRED likely TRUE at P1-06 (proprietary SaaS backend) |
| R4 | Competing active `langgraph` crate on crates.io (updated 2026-07-01) |
| R5 | Three incompatible tag conventions across reference repos — tag-sort bug already triggered |

---

## Burst: pre-pipeline burst 4 — D9/D10 recorded; semport pass 1 close; ANALYSIS-STATE.md persisted; passes 2-3 dispatched (2026-07-12)

**Decisions recorded:**

| ID | Action | Decision |
|----|--------|----------|
| D9 | NEW | ferrochain-graph design consultation gate. Before ANY ferrochain-graph execution-model ADR is finalized, architect MUST present ≥2 alternatives with production trade-offs (scheduling model, checkpoint atomicity, backpressure, cancellation, multi-tenant fairness) to human for design conversation. /Users/jmagady/Dev/vsdd-factory designated PRIOR ART / EVIDENCE, NOT a template. Gate applies at Phase 1c architecture. |
| D10 | NEW | Production-grade constitution adopted. /Users/jmagady/Dev/ferrochain/CLAUDE.md (553 lines) authored by technical-writer from full harvest of /Users/jmagady/Dev/prism/CLAUDE.md. Binds all agents. Includes: Canonical Principle, six rules + self-audit checklist, TD-VSDD-053/059/060/091, BC-5.39.001 3-CLEAN, SID-1, SAP-1 (adapted), day-1 Rust conventions (rustls-tls mandatory, credential newtypes, no-unwrap, non_exhaustive discipline, tokio async-first), git non-negotiables. NOTE: CLAUDE.md sits on main (no initial commit yet) — committed at workspace-init (devops, Phase 1). |

**Semport pass 1 close — langchain-core:**

| Metric | Value |
|--------|-------|
| Source LOC | 60,101 |
| Source files | 180 |
| Tests | ~1,766 (~59,935 test LOC, ~1:1 ratio) |
| Deliverables | 5 (module-inventory, behavioral-intent, test-inventory, dependency-disposition, rust-translation-strategy) |
| ADR candidates | 5 (logged in rust-translation-strategy.md) |
| Top risk | Runnables/LCEL (RED — research-grade) |
| New dep discovered | langchain-protocol v0.0.17 (immature → R7) |

**Risks updated:**

| ID | Update |
|----|--------|
| R7 | NEW — langchain-protocol v0.0.17 discovered as upstream dep; immature; port-as-provisional strategy |

**Files touched:**

- STATE.md (D9, D10, R7 added; current_step updated; checkpoint updated; phase steps updated)
- .factory/semport/core/ANALYSIS-STATE.md (created — analyzer checkpoint, 8 deepening items, hook-blocked direct write resolved by state-manager)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)

**Phase step archival:** "Naming decision study" and "market-intelligence-assessment" rows rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 1 and burst 3 entries above.

**Next steps:** semport passes 2-3 in progress (langgraph runtime+checkpoint+prebuilt → .factory/semport/graph/, langchain_v1 → .factory/semport/langchain/). Remaining queue after passes 2-3: partners deep pass (openai/anthropic/ollama), standard-tests, text-splitters, mcp-adapters, langgraph-platform SDK/CLI deep, core deepening pass.

---

## Burst: pre-pipeline burst 5 — passes 2-3 DONE; D11 design steers recorded; passes 4-5 dispatched (2026-07-13)

**Semport pass 2 close — langgraph runtime+checkpoint+prebuilt:**

| Metric | Value |
|--------|-------|
| Deep-scope LOC | ~46,150 (core 27,846; checkpoint 5,892; postgres 4,891; sqlite 3,849; prebuilt 3,676) |
| Inventory-only | sdk-py 18,728; cli 8,383 |
| Test LOC | ~62,000–63,000 (larger than source) + upstream checkpoint-conformance framework |
| Deliverables | 5 (module-inventory, behavioral-intent, test-inventory, dependency-disposition, rust-translation-strategy) |
| Key risks | LANGGRAPH_STRICT_MSGPACK RCE-guard (byte-faithful security-sensitive checkpoint serialization); dual storage shapes (sqlite blob vs postgres normalized blobs) behind one trait; replay-on-resume as semantic (content-addressed xxh3_128 task IDs + uuid6 checkpoint IDs must reproduce exactly); DeltaChannel beta prune constraints |
| vsdd-factory prior art | Transferable idioms: tiered execution, spawn_blocking isolation, drain timers, fault trapping. Durable/replay core is greenfield (vsdd-factory is stateless-per-run). |

**Semport pass 3 close — langchain_v1:**

| Metric | Value |
|--------|-------|
| Source LOC | 14,512 |
| Test LOC | 31,653 (2.2x source) |
| Weight concentration | ~87% in agents/ |
| Deliverables | 5 (module-inventory, behavioral-intent, test-inventory, dependency-disposition, rust-translation-strategy) |
| Key output | Exact langgraph API surface consumed by create_agent = minimum ferrochain-graph public API (frozen list in behavioral-intent.md §5.1–5.4); private stream internals (§5.5, subagent transformer) recommended as v1 non-goal — SCOPE DECISION queued for Phase 1 human gate |
| Middleware | 10 hooks, onion composition test-locked |
| Dependency disposition | Required: ferrochain-core + ferrochain-graph + serde/schemars; langsmith.traceable → ELIMINATE (tracing seam); 19 provider extras → partner crates |

**Decisions recorded:**

| ID | Action | Decision |
|----|--------|----------|
| D11 | NEW (design steers from D9 early conversation 2026-07-12; formal ADR ratification at Phase 1c) | D11.1 HYBRID execution model: orchestrator-loop engine per run (compile-time write-isolation, single-writer checkpoint atomicity) + actor-style outer scheduler (multi-tenant fairness/quotas); serves embedded-library AND hosted-SaaS. D11.2 RUST-NATIVE checkpoint wire format (msgpack, security-allowlist RCE-guard retained) + one-way Python-checkpoint import tool; NOT byte-compatible with Python ormsgpack ext-table format. D11.3 Durability: port all three tiers (sync/async/exit); ferrochain DEFAULTS to sync (crash-safe) — deliberate documented deviation from upstream defaults per production-grade constitution. |

**Queued scope decisions for Phase 1 human gate:**

| Item | Recommendation | Source |
|------|---------------|--------|
| (a) Subagent stream transformer v1 non-goal | Recommend defer private stream internals (§5.5) to post-v1 | Pass 3 recommendation |
| (b) Final crate-name ADR | Ratify ferrochain crate family names (D6 RESOLVED; formal ADR at architecture phase) | D6 |
| (c) License decision | MIT-derivative with attribution | human queue |

**Phase step archival:** rows "repo-initialization (parts 1+2)", "semport-analyze pass 1 — langchain-core", and "ANALYSIS-STATE.md persisted" rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 3 and burst 4 entries above.

**Files touched:**

- STATE.md (current_step, timestamp, Last Updated, Current Step; Current Phase Steps table replaced; D11 added to Decisions Log; Session Resume Checkpoint updated; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)

**Next steps:** passes 4-5 in progress (partners+standard-tests → .factory/semport/partners/, text-splitters+mcp-adapters → .factory/semport/splitters/+mcp/). Remaining queue after passes 4-5: langgraph-platform SDK/CLI deep pass, core deepening pass, then semport convergence → Phase 1.

---

## Burst: pre-pipeline burst 6 — passes 4-5 DONE; D12 locked; R8 added; passes 6-7 dispatched (2026-07-13)

**Semport pass 4 close — partners+standard-tests:**

| Metric | Value |
|--------|-------|
| Partner src LOC | ~52,193 total |
| openai | 13,597 src / 16,658 test |
| anthropic | 5,664 src / 8,941 test |
| ollama | 2,959 src / 2,607 test |
| standard-tests | 9,820 LOC / 12 conformance base classes |
| Deliverables | 5 (module-inventory, behavioral-intent, test-inventory, dependency-disposition, rust-translation-strategy) at .factory/semport/partners/ |
| Key findings | deepseek+xai are BaseChatOpenAI subclasses; groq/fireworks/openrouter ride OpenAI wire → one openai-wire module serves ~6 crates. MAP-vs-HTTP verdict = DIRECT-HTTP for all 3 deep providers + shared ferrochain-partner-http infra crate. genai REJECTED as substrate. async-openai REJECTED (rustls-tls feature conflict + DTO mismatch). Conformance suite maps to capability-flag trait + declarative macro with no-opt-out guard (xfail requires reason or compile error). |
| Conflict routed | Pass 4 DIRECT-HTTP verdict supersedes pass-1 core strategy §3 note — routed to Phase 1 ADR |

**Semport pass 5 close — text-splitters+mcp-adapters:**

| Metric | Value |
|--------|-------|
| Splitters LOC | 3,671 (PORT-class) |
| MCP LOC | 1,914 |
| Deliverables | 10 total (5 splitters at .factory/semport/splitters/, 5 MCP at .factory/semport/mcp/) |
| Splitters key findings | CRITICAL parity risk: code-point vs byte-length metric (see R8). json.dumps separator fidelity flagged. BeautifulSoup-vs-html5ever DOM parity flagged. tiktoken→tiktoken-rs MAP verdict HIGH confidence. nltk/spacy sentence splitters: DEFER. |
| MCP key findings | rmcp 2.2.0 is the OFFICIAL Rust MCP SDK (15.5M downloads, all transports) → ADOPT verdict. 3 pre-Phase-1 verification items: elicitation callbacks, structuredContent/isError field, list_tools pagination. Session model: fresh-per-tool-call, NO pooling in v1. |

**Decisions recorded:**

| ID | Action | Decision |
|----|--------|----------|
| D12 | NEW (human-approved, research-validated) | File size & module splitting standard. Production: 500 LOC soft / 750 hard (CI fail). Tests: 1,000 soft / 1,500 hard. Counted via tokei Code metric (blanks/comments/doc-comments/#[cfg(test)]/generated excluded). CI enforcement: cargo xtask check-file-size (created at workspace init) + clippy::too_many_lines=150. Exceptions: xtask/file-size-allowlist.toml (path+reason+approver+date, PR-reviewed). Cohesion clause: split by concern, mod.rs re-export-only, over-splitting is anti-pattern. Evidence: .factory/planning/file-size-standard-study.md (hypothesis CONFIRMED with refinements). Codified in CLAUDE.md Code Conventions + Forbidden Patterns. |

**Risks added:**

| ID | Risk |
|----|------|
| R8 | NEW — Splitters code-point/byte-length parity CRITICAL. Upstream len() = code-point count, not byte count. No non-ASCII test vector in upstream suite → risk undetected in ferrochain-splitters. Must become explicit BC + holdout scenario. Route to product-owner at Phase 1. |

**Phase step archival:** rows "semport-analyze pass 2 — langgraph runtime+checkpoint+prebuilt", "semport-analyze pass 3 — langchain_v1", and "D11 design steers recorded" rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 5 entry above.

**Files touched:**

- STATE.md (current_step, timestamp, Last Updated, Current Step; Current Phase Steps replaced; D12 added to Decisions Log; R8 added to Risk Register; Session Resume Checkpoint updated; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (created — burst 5 checkpoint archived)

**Next steps:** passes 6-7 in progress (platform SDK/CLI → .factory/semport/platform/, core convergence deepening → .factory/semport/core/). After completion: extraction-validation gate (validate-extraction agent) → semport convergence → Phase 1.

---

## Burst: pre-pipeline burst 7 — passes 6-7 DONE; R9 added; pass 8 dispatched (2026-07-13)

**Semport pass 6 close — platform SDK/CLI:**

| Metric | Value |
|--------|-------|
| SDK LOC | 18,728 |
| CLI LOC | 8,383 |
| Deliverables | 5 at .factory/semport/platform/ |
| SDK key findings | Async tree + sync mirror → collapses to async-only in ferrochain port. auth/runtime/encryption modules are server-authoring frameworks → DROP from client crate; retained as reference for a future server product. |
| CLI key findings | Only `validate` + langgraph.json schema (~2,500 LOC) is portable → becomes ferrochain.toml + config validation. build/up/dev/deploy are Docker/Python/SaaS-bound → DROP/RE-SCOPE. |
| DTU spec produced | Endpoint catalog COMPLETE: 50+ REST endpoints, 40+ DTOs, 19 enums = DTU clone spec for P1-06. DTU approach: stateful fake seeded from local engine. Conformance defined as "matches SDK-1.2.9 contract" NOT live SaaS. |
| Queued Phase 1 gate decisions | CLI re-scope + platform-client depth (RemoteGraph parity: full PregelProtocol vs reduced subset). |

**Semport pass 7 close — core convergence deepening:**

| Metric | Value |
|--------|-------|
| Deliverables updated | All 5 core deliverables + ANALYSIS-STATE.md |
| Items worked | 8 |
| Novelty | 1 HIGH, 4 MED, 3 LOW |
| Contradictions logged | C-1..C-6 with pass-1 — routed to extraction-validation gate |
| Headline contradiction | C-1: langchain-protocol is the full Agent Streaming Protocol; core consumes only the MessagesData subset → ADR-6 scope split (core subset unified with ContentBlock enum, eliminating _compat_bridge; full protocol deferred to graph/server layer) |
| New ADRs queued | ADR-6 protocol scope split; ADR-7 block-translator plugin registry; ADR-8 astream_events cancellation/cleanup ordering |
| Convergence verdict | NOT fully converged — narrow pass 8 dispatched |

**Risks added:**

| ID | Risk |
|----|------|
| R9 | NEW — Platform API churn HIGH: no public versioned spec, documented drift across SDK versions, license-gated endpoints. DTU clone must track against SDK-1.2.9 contract explicitly; churn will require re-conformance before each release. |

**Pass 8 dispatch — narrow (IN_PROGRESS):**

- Scope: RunnableSequence transform/stream line-verify + SERIALIZABLE_MAPPING partner-entry enumeration
- Parallel: research-agent fetching langchain-protocol 0.0.17 CDDL for ADR-6 verification → output: .factory/semport/core/langchain-protocol-0.0.17-verification.md

**Phase step archival:** "semport-analyze pass 4 — partners+standard-tests" row rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 6 entry above.

**Files touched:**

- STATE.md (current_step, timestamp, Last Updated, Current Step; Current Phase Steps replaced; R9 added to Risk Register; Session Resume Checkpoint updated; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 6 checkpoint archived)

**Next steps:** pass 8 + langchain-protocol-0.0.17 verification in progress. After completion: extraction-validation gate (validate-extraction over all passes with C-1..C-6 as known-corrections) → semport convergence → Phase 1.

---

## Burst: pre-pipeline burst 8 — pass 8 CONVERGED; D13 ferrochain-server first-party; R3/R9 downgraded; extraction-validation gate dispatched (2026-07-13)

**Semport pass 8 close — narrow: RunnableSequence + ADR-3 + langchain-protocol-0.0.17:**

| Metric | Value |
|--------|-------|
| Convergence verdict | CONVERGED — all semport passes complete |
| ADR-5 resolved | transform is the streaming primitive (two-default trait design, 7 locking tests cited). NEW constraint: tee/stream-duplication is a base primitive — must unify with ADR-8 start-before-end mechanism |
| ADR-3 enumerated | 176 unique keys: 141 core-internal, 12 langchain-monolith (→ structured "unsupported" error), 23 partner keys / 12 packages; alias multiplicity preserved |
| Namespace allowlist ruling | DERIVED from registered set (registry = source of truth) — eliminates upstream's hand-maintained-list drift class (3 dead entries found upstream) |
| C-7 added | LOW count correction — added to contradiction ledger with C-1..C-6 |
| langchain-protocol 0.0.17 | VERIFIED at .factory/semport/core/langchain-protocol-0.0.17-verification.md — CHANGED but strictly additive; content blocks byte-identical to 0.0.15-documented subset; only UsageInfo gained two optional token-detail structs. Agent-protocol repo is MIT. Caveat: extraction-verified not byte-diffed; CI diff step needed at port time. |

**Decisions recorded:**

| ID | Action | Decision |
|----|--------|----------|
| D13 | NEW (human directive, confirmed via structured question) | ferrochain-server is a first-party target. (1) Building ferrochain-server in-workspace (durable runs, threads/assistants/crons/store, streaming); spec'd in Phase 1 alongside client; implemented after core → graph → first partners. (2) NO wire-compatibility with LangGraph Platform; SDK-1.2.9 endpoint catalog = design input, not conformance target. (3) DTU scope collapses: ferrochain-server gets real BCs/holdouts; DTU = genuine third parties (OpenAI, Anthropic, provider APIs, Ollama keyless CI). Pass-6 "stateful fake of LangChain's platform" RETIRED. (4) Pass-6 DROPped auth/runtime/encryption + CLI dev/deploy RE-CLASSIFIED as ferrochain-server design references. (5) D11.1 actor-style outer scheduler is ferrochain-server's core. |

**Risks updated:**

| ID | Update |
|----|--------|
| R3 | REVISED per D13 — ferrochain-server is first-party (full BCs/holdouts; no DTU clone needed). DTU scope = genuine third parties only. Pass-6 "stateful fake" requirement RETIRED. Severity: High → Low. |
| R9 | DOWNGRADED per D13 — LangGraph Platform SaaS is design reference only, not conformance target. Risk = design-input staleness (check SDK-1.2.9 catalog at spec revision cycles). Severity: High → Low. DTU conformance obligation RETIRED. |

**Phase step archival:** "semport-analyze pass 5 — text-splitters+mcp-adapters" row rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 6 entry above.

**Extraction-validation gate dispatched:**

- Agent: validate-extraction
- Scope: all 8 semport passes, C-1..C-7 as known-corrections
- Output: .factory/semport/VALIDATION-REPORT.md
- Gate: on PASS → semport phase CLOSED → Phase 1 spec crystallization opens

**Phase 1 gate agenda (human decisions required before spec work begins):**

| Item | Description |
|------|-------------|
| (a) D13 server API shape | Define ferrochain-server API surface for Phase 1 spec |
| (b) CLI re-scope | Narrow CLI to ferrochain.toml validate + schema only; defer dev/deploy |
| (c) Subagent-transformer non-goal | Confirm private stream internals deferred to post-v1 (pass 3 recommendation) |
| (d) RemoteGraph parity depth | Full PregelProtocol vs reduced subset |
| (e) License/attribution | MIT-derivative with attribution |
| (f) Crate-name ADR | Ratify ferrochain crate family names (D6 resolved; formal ADR at architecture phase) |
| (g) Slimmed DTU assessment | Enumerate final third-party clone list (OpenAI/Anthropic/providers/Ollama) at P1-06 |

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated, Current Step; Current Phase Steps replaced — pass 5 archived, pass 8 updated to DONE, extraction-validation gate added; D13 added to Decisions Log; R3 updated; R9 downgraded; Session Resume Checkpoint replaced; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 7 checkpoint archived)

**Next steps:** extraction-validation gate in progress. On PASS → semport phase CLOSED → Phase 1 spec crystallization opens (architect + product-owner, with consolidated ADR queue ADR-1..ADR-8+, D8 forcing functions, D13 server contract, R8 missing-contract flag, and the Phase-1 human gate agenda above).

---

## Burst: pre-pipeline burst 9 — D14 locked; extraction-validation pass 1 COMPLETE (PASS WITH CORRECTIONS); pass 2 dispatched (2026-07-13)

**Decision recorded:**

| ID | Action | Decision |
|----|--------|----------|
| D14 | NEW (human directive via structured question) | Extraction-validation gate runs FULL 3-CLEAN protocol (BC-5.39.001 strict criterion: zero findings of ANY severity; corrections reset streak to 0/3; each pass fresh-context). Applies to the semport corpus extraction-validation gate — not just spec/implementation cascades. Rationale: human chose maximum assurance on the analysis corpus that drives all Phase 1 spec work. Current streak: 0/3. |

**Extraction-validation pass 1 close:**

| Metric | Value |
|--------|-------|
| Result | PASS WITH CORRECTIONS |
| Corrections applied | 11 (3 MEDIUM, 8 LOW) |
| Hallucinations found | ZERO corpus-wide |
| Streak after pass 1 | 0/3 (corrections reset streak) |
| Per-area verdict | core PASS clean; splitters PASS clean; mcp PASS clean; graph/langchain/partners/platform PASS-WITH-CORRECTIONS |

**Top corrections from pass 1 (all applied in-place with [validation-corrected] markers):**

| Severity | Correction |
|----------|-----------|
| MEDIUM | sqlite-vec runtime dependency fully missing from graph disposition — 3 Rust options added for Phase 1 (sqlx+sqlite-vec extension, sqlite-vss crate, tantivy HNSW alternative) |
| MEDIUM | checkpoint serde/types.py pregel sentinel constants (TASKS/INTERRUPT/RESUME/ERROR/SCHEDULED) omitted from core inventory |
| MEDIUM | ChatModelIntegrationTests count inflated ~62→~48; affects conformance suite sizing in Phase 1 |
| LOW | _BUILTIN_PROVIDERS undercount: chat 30→33 (adds watsonx/ibm/litellm/upstage/nvidia); embeddings 11→14; Phase 1 partner-coverage question broadened |
| LOW | RedisCache tier in langgraph-checkpoint unmentioned; Phase 1 decision: expose Redis cache tier? |
| LOW (×6) | Various count/name corrections across graph, langchain, partners, platform passes |

**Full report:** .factory/semport/VALIDATION-REPORT.md

**Extraction-validation pass 2 dispatched:**

- Agent: validate-extraction (fresh context, no pass-1 history)
- Sampling: rotated strata (different files sampled than pass 1)
- Scope: independently re-verifies pass-1 corrections + full corpus sweep
- Streak needed: 2 more CLEAN(strict) passes (including this one) after streak reset

**Phase step archival:** "D12 file-size standard locked" row rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 6 entry above.

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated/Current Step; Current Phase Steps — D12 row archived, extraction-validation gate split into pass-1-COMPLETE + pass-2-IN_PROGRESS; D14 added to Decisions Log; Session Resume Checkpoint replaced; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 8 checkpoint archived)

**Next steps:** extraction-validation pass 2 in progress. Requires 2 more CLEAN(strict) passes (streak 0/3). On streak reaching 3/3 → semport phase CLOSED → Phase 1 spec crystallization opens.

---

## Burst: pre-pipeline burst 10 — extraction-validation pass 2 close, pass 3 dispatch (2026-07-13)

**Pass 2 verdict:** CLEAN(strict)=NO, CLEAN(PR-merge)=NO. 5 corrections (4 HIGH, 1 LOW). Streak RESET to 0/3.

**Key finding — pass-1 corrections were WRONG:** Pass-1's regex-based counting matched multi-line tuple value strings as dict keys, producing incorrect corrected counts. Actuals verified by pass-2: 27 chat / 10 embeddings (pass-1 had incorrectly "corrected" to 30→33 chat / 11→14 embeddings). Pass-1 also failed cross-document propagation — corrected module-inventory but left behavioral-intent stale. Pass 2 fixed all occurrences with [validation-corrected pass-2] markers.

**Positive signal — semantic layer sound:** 128 behavioral items re-verified across all 7 areas, ALL accurate. Verified: deepseek/xai BaseChatOpenAI inheritance (line-verified), pregel WRITES_IDX_MAP sentinels, interrupt xxh3 ID derivation, 7 stream modes, SDK timeout defaults, all dependency tables re-verified. Churn confined to mechanical counts only.

**Process-gap codified (lessons.md per S-7.02):** Validator counting methodology — regex/string-matching on dict-like structures produces wrong verified-labeled corrections. Codification applied: pass-3+ prompts now mandate AST-based counting + cross-document propagation sweeps. Hardening story for validate-extraction agent prompt noted for session-review (Drift/Deferral table).

**Pass 3 dispatched:** Fresh context, AST-counting guardrail, cross-doc propagation checks, rotated strata including crates.io claims verification. Streak 0/3.

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated/Current Step; Current Phase Steps — pass-6 row archived, pass-2 updated to DONE, pass-3 DISPATCHED row added; Session Resume Checkpoint replaced; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 9 checkpoint archived)
- cycles/v0.0.0-pre-pipeline/lessons.md (created; PROCESS-GAP lesson added)

**Next steps:** extraction-validation pass 3 in progress. Requires 3 CLEAN(strict) passes (streak still 0/3 after pass-2 reset). On streak reaching 3/3 → semport phase CLOSED → Phase 1 spec crystallization opens.

---

## Burst: pre-pipeline burst 11 — extraction-validation pass 3 close, pass 4 dispatch (2026-07-13)

**Pass 3 verdict:** CLEAN(strict)=NO. 7 corrections (2 MEDIUM, 5 LOW). Streak remains 0/3 (no improvement; cascade continues).

**Root cause — all 7 corrections are cross-document propagation residue:**

All 7 findings were propagation failures from prior-pass corrections, not new source-level inaccuracies:

| Finding | Category | Severity |
|---------|----------|----------|
| langchain/dependency-disposition.md still carried pre-correction provider counts (30/11) after two passes | propagation residue | MEDIUM |
| mermaid diagram in same file still showed old provider counts | propagation residue | MEDIUM |
| middleware count (§2 table) showed 13→15 inconsistency | propagation residue | LOW |
| middleware count in strategy table same discrepancy | propagation residue | LOW |
| test-file count 18→17 in one document | propagation residue | LOW |
| test-file count 11→12 in a sibling document | propagation residue | LOW |
| one additional cross-area count residue | propagation residue | LOW |

Now consistent across all 5 langchain-area docs: 27 chat / 10 embeddings.

**Positive signal — full behavioral verification clean:** 65/65 fresh behavioral claims verified; 14 platform endpoints spot-confirmed; all 8 langgraph channel types confirmed; all 17 claimed Rust crates confirmed on crates.io. Finding-class decay: source gaps (pass 1) → validator errors (pass 2) → propagation residue only (pass 3).

**Second process-gap codified (lessons.md per S-7.02):** Cross-document propagation failures recurred across all three passes. TD-VSDD-060 (sibling-site sweep) applies to documentation corrections, not just code. Codified as mandatory first-stratum whole-area propagation audit in pass-4+ prompts. Follow-up: fold document-sibling-sweep into the validate-extraction agent prompt upstream (same session-review target as counting-methodology gap).

**Pass 4 dispatched:** Fresh context; propagation audit as first stratum; fresh behavioral strata outside prior verified-lists; test-citation integrity checks. Streak 0/3.

**Phase step archival:** "semport-analyze pass 7 — core convergence deepening" row rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 7 entry above.

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated/Current Step; Current Phase Steps — pass-7 archived, pass-3 updated to DONE, pass-4 IN_PROGRESS row added; Session Resume Checkpoint replaced; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 10 checkpoint archived)
- cycles/v0.0.0-pre-pipeline/lessons.md (second PROCESS-GAP lesson added — propagation failures / TD-VSDD-060)

---

## Burst: pre-pipeline burst 12 — extraction-validation pass 4 COMPLETE, R10 registered, pass 5 dispatched (2026-07-13)

**Summary:** Pass 4 returned CLEAN(strict)=NO — 9 corrections (5 MEDIUM, 4 LOW). Streak remains 0/3. Cascade correction trend: 11→5→7→9 — NOT count-decaying because each pass rotates into unexplored strata; pass 4's finds were genuinely new substance (graph-area had only 1 analysis pass vs core's 3 prior passes).

**Headline finding (most consequential of whole cascade):** Checkpoint serialization ext-hook dispatch enumeration was INCOMPLETE across all 5 graph-area documents. The dispatch table documented only the happy-path types and omitted: Pydantic v2 (the PRIMARY path for user graph state), Pydantic v1/SecretStr, Enum, dataclasses, NamedTuples, and numpy arrays. Additionally, langgraph named types (Command/Interrupt/TimeoutPolicy) were incorrectly described as a special dispatch path — they are @dataclasses and hit the GENERIC dispatch path. A Rust implementer building from the uncorrected docs would have shipped a serializer unable to handle real graph state. All 5 graph-area documents corrected.

**Other pass 4 corrections:**
- Test-citation integrity failure: test_channels.py was cited as the source for NamedBarrierValue and EphemeralValue semantics, but test_channels.py does not test these types (barrier tested in test_state.py, 3 assert lines; NamedBarrierValue has NO dedicated test). Citations corrected.
- Propagation residue: stale ANALYSIS-STATE footer (referenced now-superseded analysis state) and ~62→~48 tokio-test estimate in partners strategy document.

**R10 registered:** Upstream coverage gap — NamedBarrierValue has NO dedicated unit test anywhere in the langgraph reference corpus. EphemeralValue only 3 assert lines in test_state.py. Like R8 (splitters code-point/byte parity): a contract upstream never wrote. Product-owner must author BCs + tests from behavior, not from ported tests. Severity: Medium. Route at Phase 1.

**Pass 5 dispatched:** Fresh context; graph-area weighting (pregel loop, checkpoint SQL schemas, prebuilt agents, interrupts); light-coverage partners inventory; test-citation integrity checks across all documents. Streak 0/3. Phase 1 opens only after 3 consecutive CLEAN(strict) passes.

**Phase step archival:** "semport-analyze pass 8 — narrow: RunnableSequence + ADR-3 + langchain-protocol-0.0.17" row rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 8 entry above.

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated/Current Step; Current Phase Steps — pass-8 archived, pass-4 updated to DONE, pass-5 IN_PROGRESS row added; R10 added to Risk Register; Session Resume Checkpoint replaced; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 11 checkpoint archived)

---

## Burst: pre-pipeline burst 13 — extraction-validation pass 5 COMPLETE, pass 6 dispatched (2026-07-13)

**Summary:** Pass 5 returned CLEAN(strict)=NO, CLEAN(PR-merge)=YES — the first pass in the cascade with zero CRIT/HIGH/MED findings. 2 corrections (2 LOW). Streak remains 0/3 (CLEAN(strict) requires zero findings of ANY severity). Cascade correction trajectory: 11→5→7→9→2. Severity collapsed to LOW-only; strata approaching exhaustion.

**Pass 5 findings:**

1. **Behavioral-locus correction (LOW — load-bearing for Rust API):** `tick()` does NOT raise `GraphRecursionError`. It sets `status = out_of_steps` and returns `False`. The outer `invoke` loop converts `status` to an error. This distinction is load-bearing for the Rust API surface: `tick()` should be `-> bool`, not `-> Result<bool, GraphRecursionError>`. Corrected in graph-area documents.

2. **Stale test-count values (LOW — documentation artifact):** Two occurrences of "60+ tests" in `partners/module-inventory.md` ASCII tree were stale. Actual count is 48 (per `ChatModelIntegrationTests`). Corrected to 48.

**Verified-accurate (no corrections needed):**
- PostgreSQL and SQLite checkpoint schemas: exact match to reference source
- All 15 partner LOC counts: all exact
- Pregel halt ordering: confirmed correct
- Interrupt machinery: xxh3 IDs, `interrupt_counter` resume matching, `Command` field enumeration all confirmed
- Zero hallucinations corpus-wide

**Pass-5 lesson codified:** Behavioral-locus precision guardrail — validators must verify not just WHAT a function does but WHERE the behavior lives (tick() vs invoke loop). Added to lessons.md and injected as guardrail into pass-6 prompt.

**Pass 6 dispatched:** Fresh context. Strata rotated to least-sampled areas: core messages/parsers/prompts claims, `create_agent` graph-construction vs `factory.py`, splitters boundary semantics, MCP behaviors. Behavioral-locus precision guardrail active. Streak 0/3.

**Phase step archival:** "D14 locked + extraction-validation pass 1 COMPLETE" row rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 9 entry above.

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated/Current Step; Current Phase Steps — pass-1 archived, pass-5 updated to DONE, pass-6 IN_PROGRESS row added; Session Resume Checkpoint replaced; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 12 checkpoint archived)
- cycles/v0.0.0-pre-pipeline/lessons.md (behavioral-locus precision guardrail lesson added)

**Next steps:** extraction-validation pass 4 in progress. Requires 3 CLEAN(strict) passes (streak still 0/3). On streak reaching 3/3 → semport phase CLOSED → Phase 1 spec crystallization opens.

---

## Burst: pre-pipeline burst 14 — extraction-validation pass 6 COMPLETE, two lessons codified, pass 7 dispatched (2026-07-13)

**Summary:** Pass 6 returned CLEAN(strict)=NO, CLEAN(PR-merge)=YES — second consecutive pass with zero CRIT/HIGH/MED findings. 2 corrections (2 LOW). Streak remains 0/3. Cascade correction trajectory: 11→5→7→9→2→2. LOW-only two consecutive passes; approaching asymptote. Orchestrator note: if LOW-only pattern persists through passes 8-9, present trajectory data to human for D14 bar review (human decision, not orchestrator's).

**Pass 6 findings:**

1. **Semantic-precision correction (LOW — load-bearing for Rust merge_dicts):** `core/behavioral-intent.md` described `merge_dicts` identity-key semantics as "last-wins". The actual behavior is: keep-left-when-equal (left value wins when both channels carry identical keys) / concatenate-when-different (values appended when keys differ). "Last-wins" is a plausible but incorrect summary that would have induced a wrong overwrite rule in a Rust implementer's `merge_dicts` function. Corrected in behavioral-intent.md.

2. **Notes-without-edits correction (LOW — documentation integrity):** `core/module-inventory.md` main table still showed `block_translators: 7 files`. A deepening-correction NOTE had been added in a separate section of the same document identifying the correct count as 8, but the main table cell was never updated to reflect it. The NOTE recorded the correction; the physical edit never happened. Table cell updated to 8.

**Verified-accurate (no corrections needed):**
- Tracer/callback registration machinery confirmed against reference source
- 7 stream mode semantic descriptions verified
- CLI claim set (graph compile output, studio endpoint, deploy verbs) all confirmed
- Middleware composition order confirmed: input_schema, configurable_fields, output_schema, fallback chain
- MCP session model, rmcp transport matrix all confirmed

**Two new lessons codified (lessons.md):**
1. Semantic-precision guardrail: summary words in behavioral docs ("last-wins", "always", "never") must be verified against actual branch logic; locally plausible summaries can encode the wrong invariant (same failure shape as pass-5 behavioral-locus; different manifestation).
2. Notes-without-edits: a correction NOTE added in one section does not fix sibling table cells in the same or other documents — every correction requires the physical edit at every affected location, not just a note recording the intent.

**Pass 7 dispatched:** Fresh context. Corpus-wide propagation audit including deepening-note sweep (catches the same failure shape as pass-6 finding #2 at scale). Strata rotated to: tracers/callbacks, graph streaming modes, CLI claims, middleware composition order. Streak 0/3.

**Phase step archival:** "extraction-validation pass 2" row rotated out of STATE.md Current Phase Steps (5-row limit); covered in burst 10 entry above.

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated/Current Step; Current Phase Steps — pass-2 archived, pass-6 updated to DONE, pass-7 IN_PROGRESS row added; Session Resume Checkpoint replaced; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 13 checkpoint archived)
- cycles/v0.0.0-pre-pipeline/lessons.md (two new lessons added: semantic-precision guardrail, notes-without-edits)

**Next steps:** extraction-validation pass 7 in progress. Requires 3 CLEAN(strict) passes (streak still 0/3). On streak reaching 3/3 → semport phase CLOSED → Phase 1 spec crystallization opens.

---

## Burst: pre-pipeline burst 15 — extraction-validation pass 7 COMPLETE, pass 8 dispatched (2026-07-13)

**Adversary verdict:** n/a — pre-pipeline burst; extraction-validation cascade in progress; no spec or implementation artifacts subject to adversarial review yet.

**Pass 7 results:** CLEAN(strict)=NO, CLEAN(PR-merge)=YES. 2 corrections (1 MEDIUM, 1 LOW). Both in the final never-sampled stratum (core callbacks/tracers §10).

**MEDIUM finding:** LoggingCallbackHandler misattributed to langchain-core. It exists only in langchain_classic (legacy `langchain` package). Correct ferrochain-core tracer roster: LangChainTracer, ConsoleCallbackHandler, FunctionCallbackHandler, RootListenersTracer, EvaluatorCallbackHandler, RunCollectorCallbackHandler. LoggingCallbackHandler is a legacy/classic class, not a core class. Port scope corrected — ferrochain-core scope was inflated.

**LOW finding:** BaseCallbackHandler has 7 ignore flags, not 4. Missing: ignore_retry, ignore_chat_model, ignore_custom_event. A Rust CallbackHandler trait derived from the 4-flag description would have lacked 3 opt-outs, producing behavioral divergence on retry and custom-event callbacks.

**MILESTONES this pass:**
- Propagation audit found ZERO stale values corpus-wide for the first time — failure class extinguished.
- ALL areas and strata have been sampled at least once — no unexplored territory remains.
- Verified this pass: all 7 graph streaming modes exact, CLI command inventory exact, middleware composition-order chains confirmed, tokio task_local claims factually correct.

**6th guardrail codified:** Package-attribution — any class attributed to a package must exist in that package at the pinned tag. Added to lessons.md.

**Cascade totals:** 49 corrections over 7 passes. Trajectory: 11→5→7→9→2→2→2.

**Pass 8 dispatched:** Fresh context. Fresh-eyes stratified random re-verification with ALL 6 guardrails active simultaneously + corpus-wide semantic-precision word sweep. First pass with a genuine shot at CLEAN(strict). Streak 0/3.

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated/Current Step; Current Phase Steps — pass-3 row archived, pass-7 updated to DONE, pass-8 IN_PROGRESS row added; Session Resume Checkpoint replaced)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 14 checkpoint archived)
- cycles/v0.0.0-pre-pipeline/lessons.md (6th lesson added: package-attribution guardrail)

**Next steps:** extraction-validation pass 8 in progress. Requires 3 CLEAN(strict) passes (streak still 0/3). On streak reaching 3/3 → semport phase CLOSED → Phase 1 spec crystallization opens.

---

## Burst: pre-pipeline burst 16 — pass 8 COMPLETE (CLEAN(strict)=NO; 7 corrections); D14.1 exhaustive-sweep-then-3-CLEAN (human-approved); 7 parallel area validators dispatched (2026-07-13)

**Pass 8 results:** CLEAN(strict)=NO. 7 corrections (5 MEDIUM, 2 LOW). Streak 0/3 — streak has never started across 8 passes. Cascade: 11→5→7→9→2→2→2→7. Total corrections: 56.

**Headline finding — PHANTOM BEHAVIOR:** All four partner-area docs claimed a `base_url` gate on OpenAI Responses-API routing that does NOT exist in source code. Routing is determined solely by feature-flag + model-name check; the only `base_url` gate is stream_usage auto-enabling (a different, unrelated feature). A Rust implementer working from the uncorrected docs would have built a non-existent conditional gate, producing incorrect fallback behavior on every Responses-API call. Corrected in all four partner-area docs.

**Additional MEDIUM findings:**

| Severity | Finding |
|----------|---------|
| MEDIUM | AnyValue channel semantics documented as OPPOSITE of actual — docs stated "never empty once written"; actual behavior is cleared each unwritten step (ephemeral, not persistent). Load-bearing for Rust channel implementation. |
| MEDIUM | langchain agents/ LOC metric corrected (cascaded count correction across 3 partner-area docs) |
| MEDIUM | (remaining 2 MEDIUM in partner-area docs — partner-routing and channel semantics scope) |
| LOW | 2 LOW corrections across area docs (minor count/name precision) |

**D14.1 amendment (human-approved 2026-07-13):** Sampling provably does not converge — constant error-strike rate across 8 passes. New protocol: exhaustive-sweep-then-3-CLEAN. 7 parallel area validators (core, graph, langchain, partners, splitters, mcp, platform), each confined to its own area directory, exhaustively verify every discrete claim against pinned source (not sampling), fix in-place with [validation-exhaustive] markers, write `<area>/EXHAUSTIVE-SWEEP.md` with claims-checked counts and coverage statements. THEN the 3-CLEAN certification passes run. D14 strict-zero bar UNCHANGED.

**Exhaustive sweep dispatched:** 7 parallel validators (core, graph, langchain, partners, splitters, mcp, platform).

**Level-2 escalation recorded:** Constant error-strike rate across 8 sampling passes escalated to human per Level-2 protocol. Human approved D14.1 amendment.

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated/Current Step; Current Phase Steps — pass-4 row archived, pass-8 updated to DONE, exhaustive sweep IN_PROGRESS row added; D14 amended to D14.1; Session Resume Checkpoint replaced)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 15 checkpoint archived)

**Next steps:** Exhaustive sweep in progress (7 parallel area validators). Each writes `<area>/EXHAUSTIVE-SWEEP.md` with full claims-checked counts. After all 7 complete → 3-CLEAN certification passes begin (streak 0/3). Streak must reach 3/3 for semport phase to close and Phase 1 to open.

---

## Burst: pre-pipeline burst 17 — D14.1 exhaustive sweep COMPLETE (all 7 areas, FULL coverage); R11 registered; 3-CLEAN certification pass 1 dispatched (2026-07-13)

**Exhaustive sweep results — ALL 7 AREAS COMPLETE:**

| Area | Claims Verified | Corrections | Severity Breakdown |
|------|----------------|-------------|-------------------|
| core | ~273 | 5 | 5 LOW |
| graph | ~140 | 11 | 2 CRITICAL, others MEDIUM/LOW |
| langchain | ~170 | 6 | 1 CRITICAL, others MEDIUM/LOW |
| partners | ~147 | 11 | 2 HIGH (phantoms), others MEDIUM/LOW |
| splitters | ~178 | 4 | 1 HIGH, others LOW |
| mcp | ~164 | 5 | LOW (+ 2 new upstream test voids) |
| platform | ~144 | 3 | 3 LOW (all 61 endpoints verified exact — D13 server design input certified) |
| **TOTAL** | **~1,216** | **~45** | **3 CRITICAL, ~9 HIGH, ~11 MEDIUM, rest LOW** |

**ZERO hallucinated symbols** corpus-wide. 2 phantom artifacts caught and removed (see below).

**CRITICAL corrections (load-bearing for Rust port):**

1. **graph — recursion_limit default is 10,007 NOT 25.** Upstream source: `langgraph/_internal/_config.py:32`, `LANGGRAPH_DEFAULT_RECURSION_LIMIT` env-tunable. The value 25 is langchain-core's recursion limit (a different package). A Rust ferrochain-graph implementation guarding at 25 would halt production graphs after 25 steps. Corrected in graph/behavioral-intent.md + graph/rust-translation-strategy.md.

2. **langchain — node hook return type is `dict[str,Any]|None` NOT `dict|Command|None`.** `jump_to` travels as a dict key (not a Command object at the hook return layer). Only `wrap_tool_call` returns Command. This redefines the Rust `HookResult` type as a state-update map (a middleware trait — load-bearing surface). Corrected in langchain/behavioral-intent.md + langchain/rust-translation-strategy.md.

3. *(Third CRITICAL: within graph area — classified in graph/EXHAUSTIVE-SWEEP.md.)*

**HIGH corrections:**

| Area | Finding |
|------|---------|
| splitters | JSX separator cascade ORDER was reversed — append after JS separators, not prepend. Produces wrong split boundaries for JSX source files. Corrected in splitters/behavioral-intent.md + splitters/rust-translation-strategy.md. |
| partners | PHANTOM artifact #1 — 4 partner-area docs claimed a `GET /api/version` DTU endpoint that does NOT exist in the codebase. Phantom removed from partners/module-inventory.md + sibling docs. |
| partners | PHANTOM artifact #2 — `test_image_urls` conformance test claimed in partners/test-inventory.md does NOT exist in the reference corpus. Removed. |

**Additional corrections:** graph pregel path misattributions + unlisted `_executor.py` (Submit protocol — relevant to D11 hybrid execution design); langchain extras count 19→18, messages symbols 34→31; core `_compat_bridge` surface 3→5 functions (async entry points were missing); langchain-community extras updates.

**§5 consumed-API contract verified:** 34/34 frozen ferrochain-graph API symbols individually verified — ZERO hallucinations in the consumed API contract input for Phase 1.

**D13 server design certified:** All 61 platform endpoints verified exact against SDK-1.2.9. Server design input is certified clean.

**R11 registered:** MCP upstream test voids — two contracts that upstream does not test and ferrochain must explicitly Red Gate:
1. `mcp` bare-ToolException re-raise path: untested upstream.
2. `mcp` `__aenter__` NotImplementedError contract: untested upstream.
Both must be explicit ferrochain Red Gate tests (join R8 splitters code-point/byte parity, R10 NamedBarrierValue/EphemeralValue as untested-upstream-contract class).

**3-CLEAN certification pass 1 dispatched:**

- Agent: validate-extraction (fresh context)
- Scope: all 6 guardrails active; re-verifies a sample of exhaustive corrections themselves + high-consequence fixes + cross-area consistency
- Streak: 0/3 (starts fresh post-exhaustive sweep)
- Gate: 3 consecutive CLEAN(strict) passes required before Phase 1 opens

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated, Current Step; Current Phase Steps — pass-5 row archived, exhaustive sweep row updated to DONE, certification pass-1 IN_PROGRESS row added; R11 added to Risk Register; Session Resume Checkpoint replaced; Historical Content updated)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 16 checkpoint archived)
- semport/core/EXHAUSTIVE-SWEEP.md (new — 273 claims, 5 corrections)
- semport/graph/EXHAUSTIVE-SWEEP.md (new — 140 claims, 11 corrections, 2 CRITICAL)
- semport/langchain/EXHAUSTIVE-SWEEP.md (new — 170 claims, 6 corrections, 1 CRITICAL)
- semport/partners/EXHAUSTIVE-SWEEP.md (new — 147 claims, 11 corrections, 2 HIGH phantoms removed)
- semport/splitters/EXHAUSTIVE-SWEEP.md (new — 178 claims, 4 corrections, 1 HIGH)
- semport/mcp/EXHAUSTIVE-SWEEP.md (new — 164 claims, 5 corrections)
- semport/platform/EXHAUSTIVE-SWEEP.md (new — 144 claims, 3 corrections, 61 endpoints certified)
- semport/*/behavioral-intent.md, module-inventory.md, rust-translation-strategy.md, test-inventory.md, dependency-disposition.md (24 files — [validation-exhaustive] corrections applied in-place)

**Next steps:** 3-CLEAN certification pass 1 in progress. Requires 3 consecutive CLEAN(strict) passes (streak 0/3). On streak reaching 3/3 → semport phase CLOSED → Phase 1 spec crystallization opens.

---

## Burst 18 — 3-CLEAN Certification Pass 1 COMPLETE (2026-07-13)

**Result:** CLEAN(strict)=NO, CLEAN(PR-merge)=YES. 2 corrections (2 MEDIUM), streak 0/3.

**Corrections:**

- **MEDIUM M-05 REVERTED (sdk-py scope):** `libs/sdk-py/langgraph_sdk` row corrected from exhaustive sweep's 63 files / 20,787 LOC back to 45 / 18,728. The exhaustive correction M-05 measured the broader `libs/sdk-py` tree (setup.py, examples, scripts) instead of the labeled `langgraph_sdk` package directory. All other rows in module-inventory.md count the package sub-directory; this row must match that scope. `find .reference/langgraph/libs/sdk-py/langgraph_sdk -name "*.py" | wc -l = 45; xargs wc -l = 18,728` confirms correct values.

- **MEDIUM M-06 REVERTED (cli scope):** `libs/cli/langgraph_cli` row corrected from 46 files / 9,997 LOC back to 19 / 8,383. Same failure class: M-06 measured `libs/cli` (broader tree) vs the labeled `langgraph_cli` package directory. `find .reference/langgraph/libs/cli/langgraph_cli -name "*.py" | wc -l = 19; xargs wc -l = 8,383` confirms.

**STRONG convergence signal:**

- All 4 high-consequence exhaustive fixes RE-CONFIRMED against source: recursion_limit 10,007 (✓ `_config.py:32`), HookResult dict[str,Any]\|None (✓ `types.py:419`), JSX cascade append-after (✓ `jsx.py:103-108`), phantom /api/version removal (✓ `chat_models.py:926`).
- 16 additional exhaustive corrections re-derived all-correct (LOC counts, file counts, test citation line numbers).
- 12 test citations accurate.
- Propagation audit: ZERO stale values corpus-wide.
- 34-symbol API contract cross-area consistent.
- Error surface reduced to a single class: scope-label precision on counts.

**Guardrail #7 codified:** SCOPE-LABEL MATCHING — every numeric row must be counted from exactly the scope its label denotes (package directory vs libs tree, including vs excluding tests); correctors must resolve the label's scope BEFORE re-counting.

**Certification pass 2 dispatched:**

- Agent: validate-extraction (fresh context)
- Scope: all 7 guardrails active; rotated sampling avoiding pass-1's verified list; re-verifies pass-1's own two fixes; platform↔graph number agreement check
- Streak: 0/3

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated, Current Step; pass-1 row updated to DONE; pass-2 IN_PROGRESS row added; Session Resume Checkpoint replaced; Historical Content updated with burst 18, lesson, burst-17 checkpoint entry)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/lessons.md (Guardrail #7 SCOPE-LABEL MATCHING appended)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 17 checkpoint archived)
- semport/VALIDATION-REPORT.md (Certification Pass 1 section appended — Phase 1 behavioral verification tables, extended re-verification, test citation integrity, cross-area consistency, finding summary)
- semport/graph/module-inventory.md (sdk-py 63/20,787→45/18,728, cli 46/9,997→19/8,383; validation_note updated with [validation-certification-1] reverts)
- logs/dispatcher-internal-2026-07-12.jsonl (dispatcher log updated)

**Next steps:** 3-CLEAN certification pass 2 in progress. Requires 3 consecutive CLEAN(strict) passes (streak 0/3). On streak reaching 3/3 → semport phase CLOSED → Phase 1 spec crystallization opens.

---

## Burst 19 — 2026-07-13 — 3-CLEAN certification pass 2 COMPLETE; pass 3 dispatched

**Agent:** validate-extraction (certification pass 2)

**Summary:** Certification pass 2 returned CLEAN(strict)=YES — ZERO corrections. This is the first CLEAN(strict) pass of the entire gate after 8 sampled passes + 7-area exhaustive sweep + certification pass 1. Streak advances from 0/3 to 1/3. 58 checks performed: 21 behavioral claims drawn from all 7 areas (rotated from prior verified lists) ALL CONFIRMED against pinned source; 21 numeric rows checked under guardrail 7 scope-label resolution — ALL delta=0; certification-pass-1 own fixes re-verified exact; cross-area consistency checks (platform↔graph figures, core↔langchain §5 symbols) intact. Certification pass 3 dispatched immediately (fresh context, all 7 guardrails, sampling weighted toward ADR-driving assertions and error-path claims, rotated away from both prior certification passes' verified lists). Advances to 2/3 on zero corrections; any finding resets streak to 0/3.

**Files touched:**

- STATE.md (timestamp, current_step, Last Updated, Current Step; pass-2 row updated to DONE; pass-3 IN_PROGRESS row added; pass-7 row archived; Session Resume Checkpoint replaced; Historical Content updated with burst 19, burst-18 checkpoint entry)
- cycles/v0.0.0-pre-pipeline/burst-log.md (this entry)
- cycles/v0.0.0-pre-pipeline/session-checkpoints.md (burst 18 checkpoint archived)

**Next steps:** 3-CLEAN certification pass 3 in progress (streak 1/3). Requires 2 more consecutive CLEAN(strict) passes. On streak reaching 3/3 → semport phase CLOSED → Phase 1 spec crystallization opens.

---

## Burst 20 — 3-CLEAN certification pass 3 COMPLETE; pass 4 dispatched (2026-07-13)

**Agent:** state-manager (state update) / validate-extraction (certification pass 3)

**Result:** CLEAN(strict)=NO — 1 correction (1 LOW). Streak RESET 1/3→0/3.

**Finding:**
- `semport/partners/dependency-disposition.md` §2 anthropic row: constraint was `anthropic>=0.96` — the `<1.0.0` upper bound from the actual pyproject.toml (`anthropic>=0.96.0,<1.0.0`) was absent. The upper bound is material: it signals upstream breaking-change expectation and is relevant to provider-crate risk posture. Corrected in-place with `[validation-certification-3]` marker.

**Stratum coverage:** Fresh error-path-weighted rotation away from both cert pass 1+2 verified lists. Sampled: retry policies (backon exponential config), exception taxonomies (GraphInterrupt, NodeInterrupt, InvalidUpdateError), platform 8-code HTTP error tree (400/401/402/403/404/409/422/500 + ≥500 dispatch), cross-library exception-tree independence. All confirmed correct.

**VALIDATION-REPORT.md:** Updated with certification pass 3 per-area verdicts and CLEAN status block.

**Files modified:** `semport/partners/dependency-disposition.md`, `semport/VALIDATION-REPORT.md`

**Lesson codified:** 7b — DEPENDENCY-CONSTRAINT COMPLETENESS (see lessons.md).

**Next:** Certification pass 4 dispatched. All 7 guardrails + 7b active. New stratum: config defaults, env-var names, serialization field names. Streak 0/3.

---

## Burst 21 — 3-CLEAN Certification Pass 4 COMPLETE + Pass 5 Dispatch

**Date:** 2026-07-13
**Agent:** state-manager (burst-close)

**Summary:** 3-CLEAN certification pass 4 COMPLETE — CLEAN(strict)=NO. 6 corrections (6 LOW). Streak 0/3.

**Pass 4 corrections (6 LOW — all partners area + platform):**
1. `openai>=2.45.0,<3.0.0` — `<3.0.0` upper bound absent from partners/dependency-disposition.md; added `[validation-certification-4]` marker. Source: `langchain_openai/pyproject.toml`.
2. `tiktoken>=0.7.0,<1.0.0` — `<1.0.0` upper bound absent; same file/marker. Source: `langchain_openai/pyproject.toml`.
3. `pydantic>=2.7.4,<3.0.0` (anthropic row) — `<3.0.0` upper bound absent; same file/marker. Source: `langchain_anthropic/pyproject.toml`.
4. `ollama>=0.6.1,<1.0.0` — `<1.0.0` upper bound absent; same file/marker. Source: `langchain_ollama/pyproject.toml`.
5. `ANTHROPIC_API_URL` is the PRIMARY env var for base_url override; `ANTHROPIC_BASE_URL` is the fallback — precedence was undocumented. Added to partners/behavioral-intent.md `[validation-certification-4]` marker. Source: `langchain_anthropic/chat_models.py:950` `from_env(["ANTHROPIC_API_URL","ANTHROPIC_BASE_URL"])`.
6. CLI test LOC 7,208→7,102 — stale count; corrected in platform/test-inventory.md with `[validation-certification-4]` marker.

**DEPENDENCY-CONSTRAINT class closed:** All dependency rows across entire corpus now verbatim-verified (both lower and upper bounds). Root cause: partner pyprojects uniformly cap vendor SDKs at next major; prior passes in the analysis phase dropped the caps. Class permanently closed — guardrail 7b covers all future rows.

**Behavioral items confirmed:** 17/18 behavioral items sampled confirmed correct. Exhaustive env-var sweep (closes env-var class) deferred to pass 5 by protocol rotation.

**Files modified:** `semport/partners/dependency-disposition.md`, `semport/partners/behavioral-intent.md`, `semport/platform/test-inventory.md`, `semport/VALIDATION-REPORT.md`

**Next:** Certification pass 5 DISPATCHED. Opens with exhaustive corpus-wide env-var sweep (closes env-var class), then rotates to streaming chunk shapes, serialization field names, constructor defaults. Streak 0/3.

---

## Burst: pre-pipeline burst 22 — 3-CLEAN certification pass 5 complete, pass 6 dispatch (2026-07-13)

**Date:** 2026-07-13
**Agent:** state-manager (burst-close)

**Summary:** 3-CLEAN certification pass 5 COMPLETE — CLEAN(strict)=NO. 3 unique inaccuracies / 4 corrections (2 MEDIUM, 1 LOW). ENV-VAR CLASS CLOSED. DEPRECATED-VS-ACTIVE class opened. Streak 0/3.

**Pass 5 corrections:**

**ENV-VAR CLASS CLOSED (LOW — 1 correction):**
1. `LANGGRAPH_DELTA_MAX_SUPERSTEPS_SINCE_SNAPSHOT` (default 5000) absent from graph/behavioral-intent.md env-var inventory. Added at §2.1 snapshot-boundary description with `[validation-certification-5]` marker. Source: `pregel/_internal/_config.py:34`. Env-var class status: 18/18 env-vars verified exact, class permanently closed. Three partner inventory omissions (XAI_API_BASE, GROQ_API_BASE, GROQ_PROXY) noted for pass-6 housekeeping opener.

**DEPRECATED-VS-ACTIVE class (MEDIUM — 1 correction, 1 file):**
2. `Checkpoint LATEST_VERSION=4` — graph/behavioral-intent.md §2.2 cited `LATEST_VERSION=2` (v=2 current). The active pregel runtime at `pregel/_checkpoint.py:23` defines `LATEST_VERSION = 4`; all new checkpoints created by `pregel/_loop.py` use `empty_checkpoint()` from this file. The value `LATEST_VERSION=2` at `checkpoint/base/__init__.py:811` is in that file's DEPRECATED section ("deprecated utilities used by past versions of LangGraph") and does not govern new checkpoint creation. Exhaustive sweep had verified the deprecated file, not the active code path. Corrected to `v=4 current, LATEST_VERSION=4` with `[validation-certification-5]` marker. Directly relevant to D11.2 (Rust-native checkpoint format + Python import tool) — import tool must import v4 format, not v2.

**DEFAULT-FLAG GATING class (MEDIUM — 2 corrections, 2 files):**
3. `validate_model` gated by `validate_model_on_init: bool = False` (default off) — partners/behavioral-intent.md §Ollama implied always-on startup HTTP call ("On configuration, `validate_model` calls `client.list()`"). Actual: validation only runs when `validate_model_on_init=True`. Corrected with `[validation-certification-5]` marker. Source: `chat_models.py:548`, `chat_models.py:966-967`.
4. partners/module-inventory.md §Ollama description — "Model presence validation" note also implied always-on. Updated to "Model presence validation (opt-in)" with gating clause and `[validation-certification-5]` marker.

**Pass-5 confirming items:** Streaming chunk shapes, serialization field names, most constructor defaults confirmed. Default-flag gating and lifecycle/cleanup claims deferred to pass-6 rotation.

**Files modified:** `semport/graph/behavioral-intent.md`, `semport/partners/behavioral-intent.md`, `semport/partners/module-inventory.md`, `semport/VALIDATION-REPORT.md`

**9th lesson codified:** DEPRECATED-VS-ACTIVE — versioned/dual-implementation claims must be verified against the ACTIVE code path at the pinned tag, not the first matching definition found (appended to cycles/v0.0.0-pre-pipeline/lessons.md).

---

## Burst: pre-pipeline burst 23 — 3-CLEAN certification pass 6 complete, pass 7 dispatched (2026-07-13)

**Pass 6 verdict:** CLEAN(strict)=NO. 1 correction (1 LOW, port-correctness-critical). Streak 0/3.

**Housekeeping (3 env-vars added):**
- `XAI_API_BASE`, `GROQ_API_BASE`, `GROQ_PROXY` — partner env-var inventory additions noted in pass-5 close; applied in pass-6 opener to semport/partners/module-inventory.md (or equivalent partner-area env-var section) with `[validation-certification-6]` markers.

**VERSION CLASS CLOSED:**
- 7/7 version claims verified against active code paths. Zero deprecated-vs-active issues remaining. Class closed.

**ENUMERATION INCOMPLETENESS class — 1 correction (1 LOW, port-correctness-critical):**
1. `_reapply_writes_to_succeeded_nodes` signal skip set — graph/behavioral-intent.md documented the function as skipping two signals. The actual implementation skips FOUR signals: ERROR, ERROR_SOURCE_NODE, INTERRUPT, RESUME. The INTERRUPT omission is port-correctness-critical: a Rust implementer building the reapply logic from the two-signal description would not skip INTERRUPT-bearing nodes, causing writes to be re-applied to nodes that were interrupted mid-execution and corrupting resume semantics. Corrected in graph/behavioral-intent.md and graph/rust-translation-strategy.md with `[validation-certification-6]` markers.

**Dominant residual error class identified:** ENUMERATION INCOMPLETENESS. Recurring pattern across the full cascade: ignore-flags (4→7 across correction passes), bridge functions (3→5), skip-markers (2→4), serialization dispatch paths (Pydantic v2 path was the primary instance; now the signal skip set). The common mechanism: the validator confirmed that the documented members ARE present in the source, but did not verify that the documented count is EXHAUSTIVE against the authoritative source structure.

**Files modified:** `semport/graph/behavioral-intent.md`, `semport/graph/rust-translation-strategy.md`

**10th lesson codified:** ENUMERATION COMPLETENESS — enumerated sets (skip lists, flag sets, dispatch tables, signal handlers) must be verified exhaustively against the authoritative source structure, not just by confirming that documented members exist. Under-counting is a finding even when all documented members are correct (appended to cycles/v0.0.0-pre-pipeline/lessons.md).

**Pass 7 dispatched:** Exhaustive enumeration-completeness sweep over behavioral-intent + rust-translation-strategy files across all 7 areas (core, graph, langchain, partners, splitters, mcp, platform) — bounded sweep that closes the dominant error class — then rotated sampling of inventory/disposition file types. Streak 0/3.

**Files touched (state):**
- `semport/graph/behavioral-intent.md` (signal skip set corrected)
- `semport/graph/rust-translation-strategy.md` (same correction propagated)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)
- `cycles/v0.0.0-pre-pipeline/lessons.md` (10th lesson appended)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 22 checkpoint archived)
- `STATE.md` (pass 6 DONE, pass 7 IN_PROGRESS, session checkpoint updated, pass 2 row rotated out of Current Phase Steps)

**Next:** Certification pass 6 DISPATCHED. Opens with housekeeping: add XAI_API_BASE, GROQ_API_BASE, GROQ_PROXY to partner env-var inventory. Then bounded version-number sweep (closes deprecated-vs-active class). Then rotation to default-flag gating and lifecycle/cleanup claims. Streak 0/3.

---

## Burst: pre-pipeline burst 24 — 3-CLEAN certification pass 7 complete, pass 8 dispatched (2026-07-13)

**Pass 7 verdict:** CLEAN(strict)=NO. 1 correction (1 LOW). Streak 0/3.

**ENUMERATION CLASS CLOSED:**
- 42 enumeration claims exhaustively verified across all 14 spec-driving files (behavioral-intent.md + rust-translation-strategy.md for all 7 areas: core, graph, langchain, partners, splitters, mcp, platform).
- 6 of 7 areas fully clean this pass.
- 1 correction in graph area (see below). All other 6 areas: zero findings.
- ENUMERATION INCOMPLETENESS error class permanently closed.

**1 correction (1 LOW, channel Concrete-types enumeration):**
1. `NamedBarrierValueAfterFinish` absent from channel Concrete-types enumeration in `graph/rust-translation-strategy.md §6.1`. Asymmetric omission: `LastValueAfterFinish` sibling was already present. Source: `named_barrier_value.py:84` — a real concrete channel type that withholds the barrier value until `finish()` is called. Added with `[validation-certification-7]` marker. Corrected in `semport/graph/rust-translation-strategy.md`.

**ALL BOUNDED ERROR CLASSES NOW CLOSED:**
- Propagation residue: CLOSED
- Counting methodology: CLOSED
- Dependency-verbatim: CLOSED
- Env-vars: CLOSED
- Deprecated-vs-active versions: CLOSED
- Enumeration completeness: CLOSED (this pass)

Per-pass yield has collapsed to 1 finding. Remaining residue is unstructured (no remaining pattern-bounded error class).

**Files modified:** `semport/graph/rust-translation-strategy.md`, `semport/VALIDATION-REPORT.md`

**Pass 8 dispatched:** Pure fresh-eyes rotation, all 10 guardrails active, instructed to select never-verified claims and to report coverage-saturation explicitly if none remain findable.

**Files touched (state):**
- `semport/graph/rust-translation-strategy.md` (NamedBarrierValueAfterFinish added to §6.1)
- `semport/VALIDATION-REPORT.md` (pass 7 result recorded)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 23 checkpoint archived)
- `STATE.md` (pass 7 DONE, pass 8 IN_PROGRESS, session checkpoint updated)

---

## Burst 25 — 3-CLEAN Certification Pass 8 COMPLETE + Pass 9 Dispatched (2026-07-13)

**Pass 8 result:** CLEAN(strict)=NO. 1 correction (1 MEDIUM).

**Correction — Subgraph Checkpointer Semantics (MEDIUM, port-critical):**

`checkpointer=True` in a compiled subgraph does NOT mean "own persistence." It is a subgraph-only flag meaning: borrow the parent's checkpointer from `CONFIG_KEY_CHECKPOINTER` in the runtime config, but recast it under this subgraph's own namespace via `recast_checkpoint_ns`. The subgraph writes checkpoints under `parent_ns|subgraph_name:task_id` — it does NOT create an independent persistence layer.

- `True` on a root graph raises `RuntimeError` (`main.py:2583-2584`): "Root graphs must have a checkpointer or None, not True."
- `None` = "may inherit parent's checkpointer" (compile() docstring `state.py:1183-1189`)
- `False` = "will not use or inherit any checkpointer"
- `BaseCheckpointSaver` instance = own persistence (the only form that is truly independent)

All four variants now documented in `semport/graph/behavioral-intent.md §6.4` with `[validation-certification-8]` correction markers. The corrected description: "True (use parent's checkpointer with own namespace — subgraph-only; raises RuntimeError for root graphs)".

**Design implication:** ferrochain-graph's subgraph API must model this distinction clearly. `checkpointer=True` is a Rust-side configuration flag meaning "borrow from parent runtime context," not "create a new saver." This is a direct design input for D9/D11.

**Coverage-saturation report (per-area):**

| Area | Saturation | Genuinely-unverified residual |
|------|------------|-------------------------------|
| core | High | `BaseLLM.generate` partial-failure semantics (what happens when some outputs succeed, some fail); streaming LLM event emission order |
| graph | High | None named |
| langchain | High | None named |
| partners | High | None named |
| splitters | Near-full | None named |
| mcp | High | None named |
| platform | Near-full | None named |

Validator conclusion: "The last high-consequence unverified contract in subgraph compilation has now been corrected. Remaining residual territory is structurally peripheral."

**Streak:** 0/3 (correction resets). Pass 8 cascade: 11→5→7→9→2→2→2→7→1→1. Finding severity trending MEDIUM from LOW — this class of correction (semantics, not omissions) is harder to catch via enumeration guardrails.

**Pass 9 dispatched:** Opens by verifying ALL explicitly-named residual territory from the pass-8 saturation report (core `BaseLLM.generate` partial-failure semantics, streaming LLM event emission). Then rotation across all 7 areas.

**Files touched:**
- `semport/graph/behavioral-intent.md` (checkpointer=True semantics corrected §6.4)
- `semport/VALIDATION-REPORT.md` (pass 8 result appended)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 24 checkpoint archived)
- `STATE.md` (pass 8 DONE, pass 9 IN_PROGRESS, session checkpoint updated)

---

## Burst 26 — 2026-07-13

### Summary

3-CLEAN certification pass 9 COMPLETE — CLEAN(strict)=NO. 4 corrections (2 MEDIUM, 2 LOW). Streak 0/3. Gate-strategy decision pending human.

### Corrections

**MEDIUM-1 — `BaseLLM.generate` batch-fail semantics (`semport/core/behavioral-intent.md`)**
Corpus claimed: "`generate` collects per-prompt exceptions when `run_manager` present."
Actual (`_generate_helper`, llms.py:816-850): calls `_generate(all prompts)` atomically; on exception fires `on_llm_error` for EACH run_manager in a loop (all receive SAME exception) then re-raises. No per-prompt exception collection; no partial success. `batch(return_exceptions=True)` replicates same exception for all inputs. `LLM._generate` iterates prompts in a plain for-loop with no per-iteration exception catch — any `_call` exception propagates immediately. Corrected with `[validation-certification-9]` marker.

**MEDIUM-2 — langchain-protocol v3 streaming test count (`semport/core/test-inventory.md`, `semport/core/dependency-disposition.md`)**
Corpus claimed: "the v3 stream has only 2 tests (`test_runnable_events_v3.py`) — immature, treat as provisional."
Actual: 107 dedicated tests across 4 files — `test_chat_model_v3_stream.py` (41 tests / 1,482 LOC), `test_chat_model_stream.py` (42 tests / 904 LOC), `test_chat_model_streamer.py` (24 tests / 484 LOC), `test_runnable_events_v3.py` (2 tests / 23 LOC). Original pass-1 inventory omitted 3 test files. R7 downgraded from Medium to Low. Port-as-provisional stance can relax to normal port at Phase 1 discretion. Gating v3 behind a feature remains a valid architecture decision — rationale is now version-volatility, not immaturity.

**LOW-1 — `HTMLHeaderTextSplitter` active_headers key type (`semport/splitters/behavioral-intent.md`)**
Corpus claimed: active-header dict "keyed by DOM depth."
Actual (`html.py:277-280, 342`): keyed by user-defined header NAME (e.g., "Header 1"); value = tuple `(header_text, level, dom_depth)`; DOM depth is field-3 of the value tuple and drives scope eviction (evict headers whose recorded `dom_depth > current`). Corrected with `[validation-certification-9]` marker.

**LOW-2 — Propagation fix for v3 test count (`semport/core/dependency-disposition.md:84`)**
Stale "the v3 stream has only 2 tests" string in dependency-disposition.md corrected; rationale updated to version-volatility.

### Coverage saturation

All pass-8 explicitly-named residual territory verified:
- `BaseLLM.generate` partial-failure — corrected (MEDIUM)
- `_get_supported_usage_metadata_keys` — no corpus claim (function absent from corpus)
- `_run_agent` streaming path — no corpus claim (was a saturation suggestion, not a claimed fact)
- `AgentMiddleware.before_agent` signature — CONFIRMED (factory.py / middleware/types.py exact match)

Cumulative: 24 total validation runs (8 sampled + 7-area exhaustive sweep + 9 certification passes); ~75 total corrections; best streak 1/3 (once, pass 2); all bounded error classes closed.

### Gate-strategy escalation

Pass 9 is the 9th certification pass with no streak reaching 3. Human consulted on gate-closure strategy (orchestrator escalation, Level 2). Possible paths: (a) continue certification until 3 consecutive CLEAN passes; (b) declare semport sufficient at current precision depth and advance to Phase 1 with a formal cap on pass count; (c) other human-directed approach.

### Files modified

- `semport/core/behavioral-intent.md` (BaseLLM.generate batch-fail semantics corrected)
- `semport/core/test-inventory.md` (v3 streaming 107 tests corrected)
- `semport/core/dependency-disposition.md` (v3 test count + R7 rationale corrected)
- `semport/splitters/behavioral-intent.md` (HTMLHeaderTextSplitter active_headers key corrected)
- `semport/VALIDATION-REPORT.md` (pass 9 result appended)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 25 checkpoint archived)
- `STATE.md` (pass 9 DONE, R7 downgraded, session checkpoint updated)

## Burst: pre-pipeline burst 27 — D14 reaffirmed (Level-2 escalation) + certification pass 10 dispatched (2026-07-13)

**Event type:** Human decision at orchestrator Level-2 escalation.

**Context:** After certification pass 9 returned CLEAN(strict)=NO (4 corrections, 2 MEDIUM 2 LOW), the orchestrator escalated gate-closure strategy to the human. 24 total validation runs completed (~75 total corrections; best streak 1-of-3). Human was presented with three options:

1. Severity-scoped 3-CLEAN: gate closes on 3 consecutive zero-MED+ passes (LOW findings tolerated)
2. Absolute strict-zero (D14 as-is): gate closes only on 3 consecutive zero-finding passes of any severity
3. Close-now with Phase-1 re-verify rule: declare semport sufficient, open Phase 1 with a formal re-verification obligation

**Human decision:** ABSOLUTE STRICT-ZERO — D14 stands unamended. D14 was neither amended nor replaced; the original strict-zero bar is reaffirmed.

**D14 status:** REAFFIRMED UNAMENDED. `CLEAN(strict)` = zero findings of ANY severity. Streak reset on any correction regardless of severity. 3 consecutive CLEAN(strict) passes required before Phase 1 opens.

**Certification pass 10 DISPATCHED:** Fresh context; all 10 guardrails active. Opener task: propagation verification of all corrections made during passes 8 and 9, including verification that EXHAUSTIVE-SWEEP.md files are internally consistent with corrected content. Then standard rotation through remaining areas.

**Streak:** 0/3 (current).

### Files modified

- `STATE.md` (D14 reaffirmed in Decisions Log, current_step updated, session checkpoint updated, burst 27 recorded in Historical Content)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 26 checkpoint archived)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)

## Burst: pre-pipeline burst 28 — 3-CLEAN certification pass 10 COMPLETE + pass 11 dispatched (2026-07-13)

**Event type:** Certification pass 10 COMPLETE; pass 11 DISPATCHED per D15.

### Pass 10 result

**CLEAN(strict)=NO.** 3 corrections, all LOW severity. ALL findings are propagation residue of prior cert-8/9 corrections — ZERO new source-level inaccuracies, zero hallucinations, 100% rotation samples confirmed.

**Correction 1 (LOW): `core/dependency-disposition.md:196` R7 risk label**
Prior wording: "MED (new/churning, v3 immature)". Cert-9 established that langchain-protocol v3 streaming has 107 dedicated tests (NOT immature from test-coverage perspective). The valid risk is schema volatility at version 0.0.x, not test immaturity. Label corrected to "MED (new/churning, v3 schema 0.0.x)". This is propagation bookkeeping — the substance of R7 was already corrected in cert-9 (test count 2→107, severity downgraded to Low); only the risk-column wording in dependency-disposition.md lagged.

**Correction 2 (LOW): `graph/module-inventory.md` `interrupt.py` LOC 110→105 (notes-without-edits recurrence)**
`EXHAUSTIVE-SWEEP.md` for the graph area previously noted "interrupt.py: VERIFIED (105 actual)" but the correction was never propagated to the module-inventory table row (which still read `~110`). This is the notes-without-edits failure pattern (guardrail #2) applied to EXHAUSTIVE-SWEEP notes rather than in-document correction notes. The recurrence confirms that EXHAUSTIVE-SWEEP "VERIFIED (N actual)" notes are themselves a vector for the notes-without-edits defect class — a finding that directly motivates the pass-11 opener task.

**Correction 3 (LOW): `graph/test-inventory.md` YAML metadata `core_test_loc ~62000→63249`**
YAML frontmatter carried `~62000` while the validation narrative in the same file already recorded the exact figure 63,249 (via `find .../langgraph/tests -name "*.py" | xargs wc -l`). The narrative "~62–63k LOC" was already accurate (brackets 63,249). The YAML metadata was the trailing stale value.

### Signal

Corpus source-claims have stopped yielding genuine new inaccuracies. All three pass-10 findings are bookkeeping residue from prior passes. This matches the convergence pattern predicted by the D15 dispatch rationale: corrections will eventually reach zero when all propagation paths are exhausted.

### Pass 11 dispatch (per D15)

Dispatched autonomously per D15 (no human check-in required). Opener: (1) bounded YAML/metadata numeric sweep across all 7 area EXHAUSTIVE-SWEEP.md files and their corresponding inventory tables — specifically checking for numeric values that appear in "VERIFIED (N actual)" notes but were not propagated to the adjacent table cell; (2) then full rotation through all areas. This opener directly closes the notes-without-edits recurrence class at its root.

**Streak:** 0/3 (cert pass 10 was a correction; streak resets per D14 strict-zero bar).

### Files modified

- `semport/core/dependency-disposition.md` (R7 risk label cert-10 propagation correction)
- `semport/graph/module-inventory.md` (interrupt.py LOC 110→105 notes-without-edits propagation fix)
- `semport/graph/test-inventory.md` (core_test_loc YAML metadata 62000→63249)
- `STATE.md` (pass 10 DONE, pass 11 dispatched, session checkpoint updated, burst 28 recorded)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 27 checkpoint archived)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)

---

## Burst 29 — 3-CLEAN Certification Pass 11 Complete

**Date:** 2026-07-13
**Agent:** validate-extraction
**Type:** certification-pass

### Result

3-CLEAN certification pass 11 COMPLETE: **CLEAN(strict)=NO**. 10 corrections (10 LOW).

### Root Cause: YAML/Metadata Numeric Stale-Approximation Class

The bounded YAML/metadata numeric sweep flushed the entire stale-approximation class in one pass. All corrections were approximate values ("~N", "N+") in YAML frontmatter or metadata tables that had not been updated to reflect the exact figures already computed during the exhaustive sweep. No behavioral claims were incorrect — this was exclusively a metadata-accuracy pass.

### Corrections

| # | File | Old Value | New Value | Notes |
|---|------|-----------|-----------|-------|
| 1-3 | `semport/core/test-inventory.md` (×3 locations) | 59,935 | 59,322 | test_loc YAML frontmatter + table |
| 4 | `semport/platform/module-inventory.md` | 50+ endpoints | 61 endpoints | platform endpoint count exact |
| 5 | `semport/platform/module-inventory.md` | 40+ DTOs | 44 DTOs | platform DTO count exact |
| 6 | `semport/core/module-inventory.md` (stream/) | ~2,000 | 2,210 | stream/ LOC exact |
| 7 | `semport/core/module-inventory.md` (channels/) | ~1.2k | 1,143 | channels/ LOC exact |
| 8 | `semport/graph/module-inventory.md` (graph/) | ~2.8k | 2,960 | graph/ LOC exact |
| 9-10 | `semport/platform/behavioral-intent.md`, `semport/platform/rust-translation-strategy.md` | stale approx | exact figures | metadata sync |

### Behavioral Layer (38/38 confirmed)

38 behavioral claims verified across all 7 areas — ZERO new errors, zero hallucinations. All behavioral contracts previously corrected in passes 1-10 remain stable.

### Class Closure

**YAML/METADATA CLASS CLOSED**: All approximations now exact corpus-wide. This was the final bounded error class. All bounded classes are now both closed AND swept:

| Class | Status |
|-------|--------|
| Propagation residue | CLOSED |
| Counting methodology | CLOSED |
| Dependency-constraint verbatim | CLOSED |
| Env-var completeness | CLOSED |
| Deprecated-vs-active | CLOSED |
| Enumeration completeness | CLOSED |
| YAML/metadata approximations | CLOSED (this pass) |

### Signal

Stale-approximation class was the last category of systematic error. With all bounded classes closed and swept, remaining passes are pure rotation over a corpus where every class of known error is extinguished.

### Pass 12 dispatch (per D15)

Dispatched autonomously per D15 (no human check-in required). Opener: (1) verify pass-11 propagation — re-spot-check the 8 corrected values independently; (2) then pure rotation through behavioral claims not covered in recent passes.

**Streak:** 0/3 (cert pass 11 was a correction; streak resets per D14 strict-zero bar).

### Files modified

- `semport/VALIDATION-REPORT.md` (pass-11 results appended)
- `semport/core/ANALYSIS-STATE.md` (YAML/metadata class closed, pass-11 status)
- `semport/core/module-inventory.md` (stream/ 2,210; channels/ 1,143 — exact values)
- `semport/core/test-inventory.md` (test_loc 59,322 ×3 locations)
- `semport/graph/module-inventory.md` (graph/ 2,960 — exact value)
- `semport/platform/behavioral-intent.md` (metadata sync)
- `semport/platform/module-inventory.md` (61 endpoints, 44 DTOs — exact counts)
- `semport/platform/rust-translation-strategy.md` (metadata sync)
- `STATE.md` (pass 11 DONE, pass 12 dispatched, session checkpoint updated, burst 29 recorded)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 28 checkpoint archived)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)

---

## Burst 30 — 2026-07-13

**Trigger:** 3-CLEAN certification pass 12 COMPLETE per D15 autonomous continuation.

### Summary

3-CLEAN certification pass 12 COMPLETE: CLEAN(strict)=NO. 2 corrections (2 LOW), both corrector-introduced residue rather than new source inaccuracies.

**Opening stratum (cert-11 propagation verification):**
Swept all 35 semport docs for stale forms `~59935`, `50+`, `40+`, `~2,000`, `~1.2k`, `~2.8k`. Found 1 residual:
- `platform/module-inventory.md:212` — prose sentence "The **50+** endpoints above are the complete client-visible surface at 1.2.9." The cert-11 YAML field `rest_endpoints:` was corrected to 61 but this companion prose sentence was not updated. Corrected to "61 endpoints".
- All 5 cert-11 numeric spot-recomputes independently confirmed: core test LOC 59,322 (delta 0), stream/ 2,210 (delta 0), channels/ 1,143 (delta 0), graph/ 2,960 (delta 0), platform wire_dtos 44 (delta 0).

**Behavioral rotation (28 claims, 7 areas):** All 28 confirmed. ZERO new inaccuracies, ZERO hallucinations.
- Graph citation: `graph/behavioral-intent.md:112` cited `pregel/_internal/_config.py:34` for `DELTA_MAX_SUPERSTEPS_SINCE_SNAPSHOT`. No such file exists. Constant is at `langgraph/_internal/_config.py:33`. This citation was introduced by cert-5 and survived 7 passes unverified. Corrected with `[validation-certification-12]`.

**Metric verification (27 claims):** All 27 delta-zero. One tilde-prose noted but not corrected: `~120 tests` in splitters/behavioral-intent.md (actual 123, +2.4%, within acceptable approximation per BC-5.39.001).

### New Failure Modes Logged

Two new failure mode patterns identified for cert-13 rotation checklist:
1. **Prose-not-updated-with-YAML:** YAML field corrected; companion prose sentence in the same document not swept. Now in cert-13 openers.
2. **Citation-path-introduced-by-correction-never-verified:** cert-5 added `DELTA_MAX_SUPERSTEPS_SINCE_SNAPSHOT` claim with a `pregel/_internal/_config.py` path prefix that was never independently verified. Path survived 7 passes. Now in cert-13 correction-marker citation audit.

### 11th Lesson

Corrections are claims too: every path/value a correction introduces must be verified like any original claim, and every corrected numeric needs a prose-sibling sweep. Appended to lessons.md.

### Files Modified This Burst

- `semport/platform/module-inventory.md:212` (prose "50+" → "61"; `[validation-certification-12]` marker)
- `semport/graph/behavioral-intent.md:112` (citation path `pregel/_internal/_config.py:34` → `_internal/_config.py:33`; `[validation-certification-12]` marker)
- `semport/VALIDATION-REPORT.md` (Certification Pass 12 section appended)
- `STATE.md` (pass 12 DONE, pass 13 dispatched, session checkpoint updated, burst 30 recorded)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 29 checkpoint archived)
- `cycles/v0.0.0-pre-pipeline/lessons.md` (11th lesson appended)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)

---

## Burst 31 — D16 Recorded + D8 Amended (Domain C) + Pass 13 Dispatched (2026-07-13)

### What Happened

Following cert pass 12 completion (burst 30), two new decisions were recorded and pass 13 was dispatched per D15 autonomous continuation.

**D16 recorded:** adk-rust comparative corpus deferred until 3-CLEAN gate closes. Human directed post-closure ingestion of github.com/zavora-ai/adk-rust as Corpus 5 with identical rigor. RUST-BLINDNESS RULE: language carries zero evidentiary weight — patterns win on production-grade merit only. All outcomes on table (adopt patterns / adopt none / pivot wholesale / hybrid). Pre-staging permitted immediately: devops-engineer pins clone to `.reference/adk-rust` + manifest row + license capture. Analysis PARKED.

**D8 amended:** Domain C added — OpenClaw-like personal AI assistant. Forces uniquely: 24/7 resumable sessions, multi-channel ingress/webhooks, proactive cron agency, long-horizon cross-session personal memory, local-first single-binary deployment, skill/plugin/MCP ecosystem. Host-first single-operator threat model to be inverted toward default-on isolation in any ferrochain clone.

**Cert pass 13 dispatched:** D15 autonomous continuation, no check-in. Opener: correction-marker citation audit (all `[validation-*]` lines corpus-wide), prose-sibling sweep of all pass-10–12 corrected numerics, tilde-prose normalization (~120→123 etc.); then rotation. Streak 0/3.

### Files Modified This Burst

- `STATE.md` (D16 recorded, D8 amended, pass 13 dispatched, session checkpoint updated, burst 31 recorded)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)

---

## Burst 32 — Holdout Domain Research COMPLETE + adk-rust Corpus 5 Pinned (2026-07-13)

### What Happened

Human-directed follow-through on D8 ("fully understand all holdout scenarios"): all three domain briefs authored and verified at `.factory/planning/holdout-domains/`. adk-rust corpus pre-staging completed per D16.

**Domain A — Virtual SOC Analyst** (`.factory/planning/holdout-domains/domain-a-soc-analyst.md`):
Tiered SOC workflows documented. 2026 AI-SOC landscape verified. MCP-in-security confirmed real: official Splunk/Sentinel/Okta/ServiceNow MCP servers exist. NEW Phase-1 forcing surfaces identified: forensic-grade immutable audit/provenance, risk-tiered authorization gates (typed action-risk + approver roles), evidence-cited structured verdicts, untrusted-tool-content isolation. Phase-1 decision flags requiring stance before BCs: OCSF normalization approach; compliance-disclosure scope.

**Domain B — Dark Factory** (`.factory/planning/holdout-domains/domain-b-dark-factory.md`):
Distilled from vsdd-factory docs + factory.strongdm.ai + 2026 autonomous-SDLC landscape. NEW surfaces: agent-registry/routing abstraction layer; token/cost budget metering + quota governance (flagged for D9 design conversation). Killer eval shape: kill mid-fan-out, restart, verify no work lost and no double-run.

**Domain C — OpenClaw** (`.factory/planning/holdout-domains/domain-c-openclaw.md`):
Verified from primary sources: Steinberger's local-first gateway, Clawdbot→Moltbot→OpenClaw lineage, 29 channels, SKILL.md/ClawHub, two-tier memory, cron/webhooks, host-first single-operator threat model. NEW surfaces: channel ingress adapters, personal-memory model, skill registry beyond MCP, exec sandboxing, local-first single-binary packaging.

**Cross-domain validation:** D7/D11/D13 spine (durable runs, HITL, fan-out, structured output, cron/threads) confirmed covered under all three domains. Consolidated NEW-surface matrix recorded in each brief's Phase-1 checklist section.

**adk-rust corpus pinned (Corpus 5):** v1.0.0, SHA a6c79b6f, Apache-2.0, 39 crates / ~265k Rust LOC. Reference-manifest.md bumped to v1.4.0. Notable overlaps for future comparative assessment: adk-sandbox/adk-guardrail ↔ domain A/C isolation demands; adk-eval ↔ domain B; adk-realtime ↔ domain C. Analysis PARKED per D16 until 3-CLEAN gate closes.

**Current step UNCHANGED:** Certification pass 13 in progress, streak 0/3 (D15 loop).

### Files Created This Burst

- `.factory/planning/holdout-domains/domain-a-soc-analyst.md`
- `.factory/planning/holdout-domains/domain-b-dark-factory.md`
- `.factory/planning/holdout-domains/domain-c-openclaw.md`
- `.factory/semport/reference-manifest.md` bumped to v1.4.0 (adk-rust Corpus 5 row added)
- `.reference/adk-rust/` (corpus clone, gitignored)

### Files Modified This Burst

- `STATE.md` (burst 32 recorded, session checkpoint updated, Historical Content consolidated)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 31 checkpoint archived)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)

---

## Burst 33 — Cert Pass 13 COMPLETE + Pass 14 Dispatched (2026-07-14)

### What Happened

Certification pass 13 completed per D15 autonomous continuation (no check-in). Pass 14 dispatched immediately.

**Opening strata (cert-13 openers) — BOTH CLEAN:**
- Correction-marker citation audit: all `[validation-*]` lines corpus-wide verified. Zero phantom citations. CLEAN.
- Prose-sibling sweep of all pass-10–12 corrected numerics: all prose siblings confirmed updated or confirmed already-matching. CLEAN.

**Tilde-normalization: 4 corrections (4 LOW):**

Three corrections are tilde-normalization propagation misses from earlier pass fixes. One is a new micro-class.

1. `core/behavioral-intent.md` — `~60` methods tilde not updated when numeric was corrected to `~68`. `[validation-certification-13]`.
2. `core/module-inventory.md` — same `~60→~68` methods propagation miss in a second location. `[validation-certification-13]`.
3. `core/module-inventory.md` — `~8.2k` prebuilt-test LOC tilde not updated when numeric was corrected to `8,944`. `[validation-certification-13]`.
4. **NEW micro-class — line-range endpoint drift:** `partners/behavioral-intent.md` cited `L3953–4012`; both endpoints verified against source; actual range is `L3953–4033` (end-point drifted). `[validation-certification-13]`. This is the first instance of a new failure class: line-range citations where the start-point is correct but the end-point has drifted due to upstream edits since the claim was authored.

**Housekeeping (not a correction, normalization only):**
- `splitters/behavioral-intent.md` `~120` tests tilde normalized to `~123` (actual 123, within tilde convention). `[validation-certification-13]`.

**Behavioral rotation (27/28 confirmed; 1 skip):**
Rotation sample confirmed 27/28 behavioral claims. One claim in the rotation set fell inside an already-corrected line-range region and was validated as part of finding (4) above — counted once.

**Corrected files (semport):**
- `semport/core/behavioral-intent.md` (`~60→~68` methods; `[validation-certification-13]`)
- `semport/core/module-inventory.md` (`~60→~68` methods + `~8.2k→8,944` prebuilt-test LOC; `[validation-certification-13]`)
- `semport/graph/test-inventory.md` (tilde normalization consistent with pass-13 sweep; `[validation-certification-13]`)
- `semport/partners/behavioral-intent.md` (line-range `L3953–4012 → L3953–4033`; `[validation-certification-13]`)
- `semport/splitters/behavioral-intent.md` (`~120→~123` tests normalization; `[validation-certification-13]`)
- `semport/VALIDATION-REPORT.md` (Certification Pass 13 section appended)

**Pass 14 dispatched per D15 (no check-in):**
Opener: bounded line-range endpoint sweep — all `L\d+–\d+` citations corpus-wide, both start- and end-points verified against pinned source. Then pass-13 propagation check (verify tilde corrections from pass-13 fully propagated across all files). Then tilde-residual zero-check (scan for any remaining unapproximated raw numerics that should carry tilde). Then rotation. Streak 0/3.

**New micro-class logged:**
Line-range endpoint drift: a citation of `LX–Y` where X (start) is correct but Y (end) has drifted. Pass-14 opener targets this class exhaustively corpus-wide. Will register as 12th lesson if end-of-pass lesson capture happens this burst; deferred to burst-close if pass-14 is still in-flight.

### Streak Status

Streak 0/3. Pass 13: NO. Cumulative: 14 cert passes dispatched, 0 consecutive CLEAN. Total validation runs: 29 (8 sampled + 7-area exhaustive + 14 cert passes dispatched). Total corrections: ~94. Best streak: 1/3 (once, lost at pass 5).

### Files Modified This Burst

- `semport/VALIDATION-REPORT.md` (Pass 13 section appended)
- `semport/core/behavioral-intent.md` (`~60→~68` methods; pass-13 tilde-normalization)
- `semport/core/module-inventory.md` (`~60→~68` methods + `~8.2k→8,944` prebuilt-test LOC; pass-13 tilde-normalization)
- `semport/graph/test-inventory.md` (pass-13 tilde normalization sweep)
- `semport/partners/behavioral-intent.md` (line-range `L3953–4012 → L3953–4033`; pass-13 new micro-class)
- `semport/splitters/behavioral-intent.md` (`~120→~123` tests normalization; pass-13 housekeeping)
- `logs/dispatcher-internal-2026-07-13.jsonl` (pass-13 completion + pass-14 dispatch logged)
- `STATE.md` (pass 13 DONE, pass 14 dispatched, session checkpoint updated, burst 33 recorded)
- `cycles/v0.0.0-pre-pipeline/session-checkpoints.md` (burst 32 checkpoint archived)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)

---

## Burst 34 — 2026-07-14

**Trigger:** BURST_CLOSE from orchestrator: cert pass 14 COMPLETE + VALIDATION-REPORT.md rotation operational fix.

**Work completed:**

### Cert Pass 14 Results
- **CLEAN(strict): NO** — 2 corrections, both LOW severity
- **Correction 1:** `partners/behavioral-intent.md:105` L1629–1660 → L1629–1661 (Stratum 1 line-range endpoint sweep: `message_chunk = AIMessageChunk(content=[content_block])` at line 1661 was the final statement of the thinking_delta/signature_delta elif handler but was outside the cited range)
- **Correction 2:** `splitters/test-inventory.md:16` ~120 → 123 (Stratum 2 pass-13 propagation sweep: cert-13 corrected behavioral-intent.md:151 but did not update the sibling test-inventory.md row)
- **Rotation:** 28/28 confirmed across 7 areas (4 claims per area)
- **Line-range sweep:** ~30 of 144 citations verified strategically; class PARTIALLY swept; pass 15 completes exhaustively
- **Streak:** 0/3 (not advanced)
- **Cumulative:** 30 total validation runs; ~96 total corrections; best streak 1/3

### OPERATIONAL FIX — VALIDATION-REPORT.md Rotation
- **Trigger:** VALIDATION-REPORT.md exceeded 4,192 lines, causing PostToolUse hook timeouts on appends (hit at passes 12 and 14)
- **Action:** Extracted lines 1–3478 (passes 1–8 + cert passes 1–10) to `cycles/v0.0.0-pre-pipeline/validation-report-archive.md` (3,478 lines, verbatim)
- **New VALIDATION-REPORT.md:** 746 lines — rotation header + cert passes 11–14 + all future passes
- **Archive:** `cycles/v0.0.0-pre-pipeline/validation-report-archive.md` (3,478 lines)

### Pass 15 Dispatched
- Per D15 (autonomous continuation, no check-ins)
- Opener: exhaustive sweep of remaining ~114 line-range citations (all 144 total) + pass-14 propagation check (stale L1629–1660 or ~120 siblings) + rotation

**Files touched in this burst:**
- `semport/partners/behavioral-intent.md` (cert-14 correction: L1629–1660 → L1629–1661)
- `semport/splitters/test-inventory.md` (cert-14 correction: ~120 → 123)
- `semport/VALIDATION-REPORT.md` (rotation: reduced 4,192 → 746 lines; cert-14 section added)
- `cycles/v0.0.0-pre-pipeline/validation-report-archive.md` (NEW — 3,478 lines: passes 1–10 verbatim)
- `STATE.md` (pass 14 DONE, pass 15 dispatched, session checkpoint updated, burst 34 recorded)
- `cycles/v0.0.0-pre-pipeline/burst-log.md` (this entry)
