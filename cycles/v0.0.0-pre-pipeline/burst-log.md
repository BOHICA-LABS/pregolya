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
