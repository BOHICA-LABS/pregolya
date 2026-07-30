---
artifact: planning/holdout-domains/domain-b-dark-factory
version: 1.0.0
created: 2026-07-13
domain: "Domain B — Dark factory / autonomous software development orchestrator"
source_decision: D8 (STATE.md, human directive 2026-07-13)
purpose:
  - "Phase 1 design forcing function: PRD/architecture must demonstrate this workload is supportable on pregolya."
  - "Phase 2 holdout domain: product-owner authors hidden acceptance scenarios; only the domain (this brief) is public."
assessor: research-agent (perplexity sonar-deep-research high-effort + WebFetch + Tavily + local file inventory)
primary_references:
  - "LOCAL (read-only prior art / evidence, NOT a template per D9): /Users/jmagady/Dev/vsdd-factory"
  - "WEB: https://factory.strongdm.ai/"
confidence: high (operating model + landscape); medium (internal architectures of closed agents — vendors do not publish them)
input-hash: "[pending state-manager]"
---

# Domain B — Dark Factory / Autonomous Software Development Orchestrator

> **Scope note.** This is a *domain brief*, not a spec. It characterizes the problem
> space so (1) Phase 1 can treat "power a dark factory" as a forcing function on the
> pregolya-graph + pregolya-server design, and (2) Phase 2 product-owner can author
> *hidden* holdout scenarios. It intentionally describes **general evaluation shapes**,
> not concrete holdout scenarios. Per D9, the local vsdd-factory workspace is designated
> PRIOR ART / EVIDENCE — "most productionally best, not just prior art" — and is
> explicitly **NOT a template** to be cloned.

---

## 10-Line Domain Summary

1. A **dark factory** is a non-interactive software-production pipeline where specs and scenarios are the input, working+tested software is the output, and humans act only at intent/gate boundaries — not on the code itself (StrongDM's stated rules: "Code must not be written by humans. Code must not be reviewed by humans.").
2. It is categorically different from a *coding assistant*: an assistant augments a human in an interactive loop; a dark factory is an autonomous input→output system where the source code is treated as an intermediate/disposable artifact and correctness is inferred from behavior.
3. The defining properties are: autonomous phase progression, spec-as-source-of-truth, test-first (or scenario-first) gates, adversarial/validation loops iterated to convergence, human-only-at-gates, and full traceability from intent to artifact.
4. Two human-designated references anchor the domain: the **vsdd-factory** methodology (an 8-phase VSDD pipeline with 33 specialist agents, Red Gate TDD, wave gates, 3-CLEAN adversarial convergence, 7-dimensional convergence) and **StrongDM's Software Factory** (scenario-driven, Digital-Twin-validated, "satisfaction"-scored, zero human code review).
5. The 2026 landscape spans a spectrum: assistive→agentic→dark-factory. Devin, OpenAI Codex cloud, Claude Code fleets, GitHub Copilot coding agent + Agentic Workflows + Agent HQ, and Google Jules occupy the agentic middle (issue→PR with a human merge gate); StrongDM sits at the dark-factory extreme.
6. **Spec-driven development (SDD)** is the connective tissue: AWS Kiro (requirements→design→tasks→property-tests) and GitHub Spec Kit (`/speckit.constitution → specify → plan → tasks → implement`) make specs executable artifacts that drive multi-agent implementation.
7. Across all systems the same technical primitives recur: durable sandboxed task execution, multi-agent parallelization, session/context persistence, human-in-the-loop approval gates, hooks for validation/security, spec→plan→task decomposition, and traceable logs/diffs.
8. This domain is the **most demanding forcing function** for pregolya-graph + pregolya-server: it requires multi-day durable runs surviving process restarts, hierarchical sub-agent spawning with isolated contexts, parallel fan-out over stories/waves, conditional gate routing, HITL interrupts mid-run, and token/cost budget metering.
9. Most of these primitives map cleanly onto pregolya's planned LangGraph-derived surface (StateGraph/Pregel engine, Send-API fan-out, `interrupt()` HITL, conditional edges, checkpointer, store, subgraphs, server threads/assistants/crons); a smaller set is **NEW** (agent-registry/routing, worktree-style filesystem isolation, per-run/per-agent budget metering, probabilistic "satisfaction" gating, adversarial-convergence as a first-class loop primitive).
10. Verdict: Domain B is *supportable* on the planned pregolya surface **and** productively stresses it — it is the domain most likely to surface gaps in durability, sub-agent isolation, and budget governance that Domains A (SOC) and C (personal assistant) do not force as hard.

---

## 1. Operating-Model Distillation — What Defines a "Dark Factory" vs a Coding Assistant

The term "dark factory" (borrowed from lights-out manufacturing) was applied to software by Dan Shapiro and popularized via StrongDM's public writeup and Simon Willison's coverage.[W1][W4] A dark factory is defined operationally as:

> "a development environment where no human even looks at the code the coding agents are producing" — the process is "an input-output system. The input is natural language … specifications … scenarios … user requirements written out in markdown. The process is effectively a black box. Inside … agents write code, run test harnesses, fail, analyze the failure, retry, converge on a solution. The output is just the working software."[W4]

### 1.1 The dividing line

| Dimension | Coding Assistant | Dark Factory |
|---|---|---|
| Human role | In the loop, per-edit | At the boundary — intent, constraints, scenarios, final gate |
| Loop shape | Interactive (human ↔ model, synchronous) | Non-interactive (spec → autonomous convergence → artifact) |
| Source code | The deliverable a human reads/reviews | An **intermediate/disposable artifact**; "the source code … is the binary … a waste product of the creation process"[W4] |
| Correctness signal | Human review + green test suite (boolean) | Behavior-inferred; **probabilistic "satisfaction"** over trajectories[W1][W6] |
| Progression | Human drives next step | **Autonomous phase progression** with programmatic gates |
| Scale lever | Human attention | Token spend (StrongDM benchmark: **~$1,000/day per engineer**)[W6][W10] |

### 1.2 The six load-bearing properties (synthesis of both references)

1. **Autonomous phase progression** — the pipeline advances through phases without a human "continue?" between each (vsdd: Phase 0→7 driven by an orchestrator; StrongDM: agents loop write→test→analyze→retry→converge).
2. **Spec-as-source-of-truth** — specs/scenarios are the durable artifact; code aligns to spec, never the reverse (vsdd Standing Rule: "code-vs-spec conflicts → the SPEC wins"; SDD movement: executable specifications).
3. **Test-first / scenario-first gates** — nothing implemented until a failing test/scenario demands it (vsdd Red Gate: "NO IMPLEMENTATION WITHOUT RED GATE VERIFICATION FIRST"; StrongDM: end-to-end scenarios stored *outside* the codebase, like an ML holdout set).
4. **Adversarial / validation loops to convergence** — surviving artifacts are attacked by a fresh, cognitively-diverse reviewer until findings decay (vsdd: 3-CLEAN, novelty-decay, different-model adversary; StrongDM: satisfaction measured across many trajectories).
5. **Human-only-at-gates** — humans approve intent, phase transitions, and shippable output; not intermediate code (vsdd: phase human-approval steps; StrongDM: humans review the *product*, not the code).
6. **Full traceability** — every artifact answers "why does this exist?" back to a requirement (vsdd L1→L2→L3→AC→test→impl→VP chain).

---

## 2. Primary Reference 1 (LOCAL) — vsdd-factory Orchestration Patterns

Source: `/Users/jmagady/Dev/vsdd-factory` (read-only). Findings below are an inventory of
**orchestration patterns**, not code. Citations are local file paths.

### 2.1 Phase pipeline
An 8-phase greenfield pipeline (`README.md`; `docs/guide/pipeline-paths.md`):
Phase 0 Brownfield Ingest → 1 Spec Crystallization → 2 Story Decomposition → 3 TDD Implementation → 4 Holdout Evaluation → 5 Adversarial Refinement → 6 Formal Hardening → 7 Convergence & Release. A parallel **feature pipeline** (F1–F7) handles post-v1 deltas, plus maintenance/discovery/multi-repo paths (`docs/guide/pipeline-paths.md`, 14 routing paths). Phases are encoded as **`.lobster` workflow files** (YAML-as-data) that the orchestrator reads to spawn agents in dependency order (`README.md` "Workflows | 16"; `docs/guide/agents-reference.md` "Orchestrator Workflows").

### 2.2 Agent specialization + dispatch model
33 specialist agents + an orchestrator (`docs/guide/agents-reference.md`). The **orchestrator does not write files** — it dispatches specialists via an Agent tool with a `subagent_type`, coordinates gates, and validates (pregolya `CLAUDE.md` "Pipeline Authority"; vsdd `agents-reference.md`). Key dispatch patterns:
- **Fresh context per specialist** — each of the 9 per-story steps is a *separate* subagent to prevent context exhaustion and topic drift ("Single-context delivery is a correctness bug", `docs/guide/phase-3-tdd-delivery.md`).
- **Context discipline** — each specialist receives only files relevant to its task (per-specialist file table, `phase-3-tdd-delivery.md`).
- **Information asymmetry** — the adversary runs with `context: fork` and *cannot see prior review passes*; the holdout-evaluator cannot see source/specs/notes (`agents-reference.md`).
- **Cognitive diversity** — adversary/reviewers deliberately use a *different model family* (`agents-reference.md` "Model Assignment").
- **Model-tier selection** — dispatcher uses the least-powerful model that can do each task; escalates a tier on BLOCKED (`phase-3-tdd-delivery.md` "Model Selection").
- **Structured status protocol** — DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED gate the next dispatch decision (`agents-reference.md`).

### 2.3 Quality gates (layered)
- **Red Gate** (per story): tests must compile and fail with *assertion* errors (not build errors) before any implementation (`phase-3-tdd-delivery.md`, "The Iron Law").
- **Wave gate** (per wave, 6 sequential checks, all must pass, restart-from-gate-1 on any fix): test suite on `develop`, DTU validation, adversarial review, demo evidence, holdout evaluation (mean ≥ 0.85, each critical ≥ 0.60, no rounding), state update (`phase-3-tdd-delivery.md`, "Wave Gate").
- **Phase gates** with explicit criteria counts (Phase 1 = 17 criteria, Phase 2 = 8, etc.; `pipeline-paths.md`).
- **7-dimensional convergence gate** (Phase 7): spec, tests, implementation, verification, visual, performance, documentation — each with quantitative pass criteria; "not a subjective judgment" (`docs/guide/phase-7-convergence-release.md`).

### 2.4 Adversarial convergence (definition)
Convergence is *measured*, not declared. Signals: **novelty decay** (latest adversary novelty < 0.15), median finding severity strictly decreasing for ≥3 passes, and **3-CLEAN** (three consecutive zero-finding passes; any finding resets the streak; the streak only counts against an unchanged HEAD — a new commit resets it) (pregolya `CLAUDE.md` BC-5.39.001; vsdd `README.md`, `phase-7-convergence-release.md`). "The pipeline terminates when further adversarial review produces only hallucinated findings" (`README.md`).

### 2.5 State management + session resume
- Live pipeline state in a single **`STATE.md`** (phase, step, decisions log D1..Dn, risk register, session-resume checkpoint) with an enforced **size budget** (~160 lines) — historical detail is offloaded to per-cycle files (`.factory/STATE.md`; `factory-project-state-template.md`).
- **`.factory/cycles/<cycle>/`** holds burst logs, convergence trajectories, session checkpoints, lessons.
- **factory-artifacts orphan branch** mounted at `.factory/` via a worktree; a single agent (state-manager) owns all `.factory/` commits and runs LAST in every burst to avoid version-race regressions (`agents-reference.md` "Why this separation matters"; pregolya `CLAUDE.md` Git Workflow).
- **Single-commit-per-burst** discipline (TD-VSDD-053), enforced by a hook chain.

### 2.6 Worktree isolation
Per-story git **worktrees** in `.worktrees/<story-id>/` on `feature/<story-id>` branches from `develop`; created by devops-engineer at step 1, cleaned at step 8 (`phase-3-tdd-delivery.md`; pregolya `CLAUDE.md` "Worktree pattern"). Enables parallel story work with filesystem isolation. Claude Code's own docs recommend the same pattern for agent fleets (see §4.3).

### 2.7 Human approval gates
Explicit `human-approval` steps at Phase 1, Phase 2, wave transitions, and pre-release; convergence criteria are *advisory* — the human can override NOT_CONVERGED→ship (recorded risk acceptance) or CONVERGED→continue (`phase-7-convergence-release.md` "Human Override"; `pipeline-paths.md`).

### 2.8 Failure escalation
- Agent BLOCKED → re-dispatch at next model tier or split the task; never retry same model+context (`agents-reference.md`).
- Systematic-debugging skill escalates after 3 failed fix attempts (→ "architectural problem, not a simple bug") (`phase-3-tdd-delivery.md`).
- Gate failure → stop, report blocker, restart gate sequence from gate 1 after fix.
- **Progressive autonomy**: once an Autonomy Score (composite of holdout satisfaction, false-positive rate, override rate, convergence speed, regression rate) exceeds 0.85 for 20 consecutive runs, qualifying phases may auto-advance without human approval (`phase-7-convergence-release.md`).

---

## 3. Primary Reference 2 (WEB) — StrongDM Software Factory

Source: https://factory.strongdm.ai/ (fetched 2026-07-13) + corroborating writeups.[W1–W10]

### 3.1 What it is / claims
"A **Software Factory**: non-interactive development where specs + scenarios drive agents that write code, run harnesses, and converge without human review."[WF][W1] Three rules stated as absolute mandates: (implied) "the model should be doing this", **"Code must not be written by humans"**, **"Code must not be reviewed by humans"**.[W4][W6] Source code is treated as an intermediate artifact; humans review the *product*, not the code.[W4][W10] Built by a **three-person team in ~three months**.[W6]

### 3.2 Operating model / pipeline
1. **Scenario definition** — end-to-end "user stories," repurposed from Cem Kaner's scenario testing (2003), stored *outside* the codebase, "similar to a holdout set in model training," intuitively understood and flexibly validated by an LLM.[W1][W6]
2. **Agent code generation** — non-interactive agents write and test code; the core agent is **Attractor**, "a non-interactive coding agent structured as a graph of phases" that "runs end-to-end when the work is fully specified" (open-sourced, Apache-2.0, published as a natural-language spec, ~1,200 GitHub stars by June 2026).[W1][W6][W9]
3. **Validation via Digital Twin Universe** — behavioral clones of third-party services (Okta, Jira, Slack, Google Docs/Drive/Sheets) replicating APIs, edge cases, and observable behaviors, enabling "thousands of risk-free test runs per hour" with no rate limits or API costs.[W1][W4][W6]
4. **Satisfaction measurement** — replaces boolean "test suite is green" with a probabilistic metric: "of all the observed trajectories through all the scenarios, what fraction of them likely satisfy the user?"[W1][W6] Scenario holdouts guard against reward hacking.[W6]

### 3.3 Supporting components (from /products)
- **Attractor** — non-interactive coding agent = graph of phases (directly analogous to pregolya-graph + vsdd phases).[W9]
- **CXDB** — self-hosted context store for agents: "turn DAG, blob deduplication, dynamic types, and visual debugging" (analogous to a checkpoint/state store).[W9]
- **StrongDM ID** — identity for humans, workloads, and AI agents; every agent has a unique verifiable identity linked to a human sponsor "so organizations always know who authorized every action" (agent identity/provenance = a governance primitive).[W2][W9]

### 3.4 Governance / autonomy stance
Most radical publicly-documented point on the spectrum: human code review eliminated *entirely*, contrasted explicitly with Stripe (which requires review).[W6] The thesis: "if validation infrastructure is strong enough, human code review becomes unnecessary."[W6] Note: **Delinea completed acquisition of StrongDM on 2026-03-05** — long-term independence of the factory is under new ownership.[W6]

---

## 4. Landscape — 2026 Autonomous Software Engineering Space

Verified via perplexity sonar-deep-research (high effort).[R1] Caveat carried from the
source: vendors publish *capabilities*, not internal architectures — concurrency models,
schedulers, resource governance, and failure modes are largely **not** publicly documented;
claims below are interface-level and flagged where inference would be speculative.

| System | Position on spectrum | Autonomy / execution model | Human gate | Notable primitive |
|---|---|---|---|---|
| **Devin (Cognition)** | High-autonomy agentic | "First autonomous software engineer"; plans/writes/tests/ships; long-term context window + reasoning chain; sets up repos/envs, builds, runs, debugs, deploys; runs in parallel at enterprise scale (Cognizant partnership, Windsurf, Flowsource).[R1-9][R1-10][R1-4] | Enterprise-configured (PR/governance at platform layer); not explicitly documented | Long-horizon multi-step planning; session persistence (mechanism undocumented) |
| **OpenAI Codex cloud (2025–26)** | Agentic (issue→PR) | Coding agent that reads/edits/runs code in **isolated cloud environments**; parallel tasks in dedicated sandboxes that continue in background; entry from web/GitHub/Linear/Slack.[R1-11] | Human review of diff/PR before merge | Isolated per-task sandbox + parallel task execution |
| **Claude Code (fleets/teams)** | Agentic → factory-capable | **Multi-agent sessions**: coordinator in a primary thread spawns sub-agent threads at runtime, each with isolated context + own model/prompt/tools/MCP/skills, sharing sandbox/filesystem/credentials; **persistent threads** (follow-ups retain state); parallelization / specialization / escalation patterns; headless mode for CI; **git worktrees** for parallel agents per branch; **hooks** as enforced quality gates; **MCP** for external tools.[R1-6][R1-12] | Configurable (hooks can gate); CI review on PRs | Orchestrator-worker sub-agent spawning + hooks + worktree parallelism |
| **GitHub Copilot coding agent** | Agentic (issue→PR) | Autonomous in an **ephemeral GitHub Actions env**; assigned via issue/Chat; researches repo, plans, edits on a branch, runs tests/linters; **hooks** run custom shell commands at key points.[R1-13] | PR boundary — never auto-merges to protected branches | Ephemeral sandbox + hooks + issue→PR gate |
| **GitHub Agentic Workflows / Agent HQ** | Orchestration plane | Repo automations authored in **markdown + YAML frontmatter** (engine = Copilot/Claude/Codex/Gemini), compiled to hardened `.lock.yml` Actions; triage issues, investigate CI, sync docs, improve coverage; billing/permission-gated (`copilot-requests: write`). **Agent HQ** = "any agent, any way you work" — orchestrate Anthropic/OpenAI/Google/Cognition/xAI agents on one platform.[R1-14][R1-7] | Per-workflow permissions + PR gate | Markdown-as-executable-workflow (echoes vsdd `.lobster`); heterogeneous agent orchestration |
| **Google Jules** | Agentic (async, VM-based) | Clones repo/branch into a **cloud VM**, plans with Gemini, edits, runs commands, opens a PR; **tiered parallelism** (base 15 tasks/day, 3 concurrent → Ultra 300/day, 60 concurrent).[R1-15] | PR review/approve/merge | Per-task cloud VM isolation + concurrency quotas |
| **AWS Kiro** | Spec-driven agentic | Prompts → **requirements → architectural design → sequenced tasks**, then implement with **parallel agents**; checks requirements for contradictions/gaps via automated reasoning before coding; **property-based tests** for invariants; ACP + MCP + `AGENTS.md`/`Skills.md`; IDE + CLI (headless).[R1-16] (Note: kiro.dev does not brand itself AWS in current docs — "AWS Kiro" framing is the common shorthand; treat AWS affiliation as unverified from primary source.)[R1-16] | Human on spec + PR | Spec → plan → tasks decomposition + property-based validation |
| **GitHub Spec Kit** | Spec-driven method/toolkit | Commands `/speckit.constitution → specify → plan → tasks → taskstoissues → implement`; specs are **executable artifacts** ("flips the script" — spec is king, code is generated); invoked via an agent (e.g., Claude Code).[R1-17] | Human authors constitution/spec; reviews output | Constitution + spec→plan→tasks→implement pipeline |
| **StrongDM Software Factory** | **Dark factory** (extreme) | See §3. Non-interactive; scenarios + Digital Twins; satisfaction scoring; no human code review.[W1–W10] | Human only on intent/scenarios + final product | Digital Twin Universe + probabilistic satisfaction gating + agent identity |

### 4.1 Recurring primitives across the landscape
The deep-research synthesis names the common set verbatim:[R1] "durable task execution in sandboxes, multi-agent parallelization, session persistence and long-term context, human-in-the-loop approval gates at issue-to-PR boundaries, hooks for custom validation and security, spec-driven decomposition into plans and tasks, and traceable logs and diffs." Spec-driven development (Kiro, Spec Kit) is the connective tissue converting intent → executable specs → multi-agent implementation.

---

## 5. Framework Demands → pregolya Primitives Mapping

Domain B is the Phase-1 forcing function that most stresses **pregolya-graph** (LangGraph-derived StateGraph/Pregel runtime, per D7/D11) and **pregolya-server** (first-party durable-run server, per D13). The capability list is enumerated in STATE.md D8. Mapping each factory demand to pregolya's planned surface:

| Factory demand (from refs + landscape) | pregolya primitive (planned) | Coverage | Source of primitive |
|---|---|---|---|
| Multi-day pipeline that survives process restarts | Durable checkpointer + `interrupt`/resume; sync-default durability (crash-safe); msgpack wire format | **PLANNED** | D11.2/D11.3; market-intel §4.1 |
| Specialist agents with isolated contexts | Subgraphs + sub-agent invocation; per-node isolated state | **PLANNED (partial)** — graph subgraphs exist; a first-class *agent-spawning* API is NEW | market-intel diff #4; landscape §4 (Claude Code threads) |
| Quality gates → conditional routing | Conditional edges / branch routing in StateGraph | **PLANNED** | LangGraph parity (D7) |
| Human approval at gates (HITL) mid-run | `interrupt()` + resume from checkpoint | **PLANNED** | D8 checklist; D11.3 |
| Parallel waves / fan-out over stories | **Send API** (map-style fan-out) | **PLANNED** | LangGraph parity |
| State / artifacts persisted across sessions | Checkpointer (SQLite/in-memory min, Postgres stretch) + Store (cross-session memory) | **PLANNED** | market-intel §4.1; D8 |
| Structured outputs (verdicts, findings, satisfaction) | Typed `ContentBlock`/structured-output; tool-schema types | **PLANNED** | market-intel §4 diff |
| External tool integration (SIEM/Slack/GitHub/DTU) | **pregolya-mcp** (MCP adapter port) | **PLANNED** | D1; D8 |
| 24/7 persistent resumable sessions | pregolya-server threads/assistants | **PLANNED** | D13 |
| Scheduled / proactive agency (nightly maintenance sweeps, cron) | pregolya-server crons | **PLANNED** | D13 |
| Streaming progress/logs | Server streaming | **PLANNED** | D13 |
| **Agent registry + routing table** (vsdd: 33 agents → subagent_type; Agent HQ: heterogeneous engines) | — | **NEW** | vsdd `CLAUDE.md` Agent Routing Table; landscape §4 (Agent HQ) |
| **Worktree-style filesystem isolation** per parallel unit | — (git worktrees are an app-layer concern, but the runtime must support per-branch isolated execution contexts) | **NEW** | vsdd §2.6; Claude Code / Jules VM isolation |
| **Token / cost budget metering** per run + per agent (StrongDM $1k/day; Jules quotas) | — (checkpointer stores usage but no budget-governance primitive planned) | **NEW** | multi-repo state template "Cost Summary"; W6/W10; R1-15 |
| **Adversarial-convergence loop** as a reusable pattern (3-CLEAN, novelty decay) | expressible as a cyclic subgraph, but not a library primitive | **NEW (compositional)** | vsdd §2.4 |
| **Probabilistic "satisfaction" gating** (LLM-judged, trajectory-based) | expressible as a node, but no eval/scoring primitive | **NEW (compositional)** | StrongDM W1/W6 |
| **Agent identity / provenance** ("who authorized every action") | — | **NEW** (governance surface; may map to server auth + structured event catalog) | StrongDM ID W2/W9 |
| Full traceability (intent→artifact) | Structured event catalog + tracing (pregolya `CLAUDE.md`); checkpoint history | **PLANNED (as observability)** | pregolya `CLAUDE.md`; vsdd §2.5 |

### 5.1 Net assessment for Phase 1
- **Covered by planned surface:** durable graph runs + checkpoint/resume, fan-out (Send), conditional routing, HITL interrupts, subgraphs, store/memory, MCP tools, server threads/assistants/crons/streaming, structured outputs, tracing/traceability. Domain B is *supportable*.
- **NEW capabilities Domain B forces onto the design conversation (D9 gate input):** (1) an **agent-registry/routing** abstraction; (2) **execution-context isolation** semantics (worktree/VM analog) at the runtime boundary; (3) **budget/cost metering + quota governance** per run and per sub-agent; (4) first-class support for **long-cyclic convergence loops** with per-iteration checkpoint atomicity; (5) optionally, **agent identity/provenance** as a governance primitive. These should be explicitly addressed (adopt / defer-with-anchor / out-of-scope) in the pregolya-graph and pregolya-server ADRs so the architecture *demonstrably* supports the dark-factory workload rather than assuming it.

---

## 6. Evaluation Shapes (General — NOT Holdout Scenarios)

For Phase 2 product-owner. These are *shapes* of what a hidden holdout could exercise; the
actual scenarios, fixtures, and thresholds must be authored privately and sealed.

1. **Multi-story TDD pipeline with an injected failing gate.** Orchestrate a small graph of "stories" through stub → failing-test → implement → gate, where one gate is rigged to fail; verify the run routes to a fix path (conditional edge), does not advance the wave, and records the failure — exercising conditional routing + gate semantics + structured findings.
2. **Resume after simulated crash mid-wave.** Start a fan-out over N parallel work-units, kill the process partway, restart from the checkpoint, and verify no unit is lost, none is double-executed, and completed units are not re-run — exercising checkpoint atomicity + durable fan-out + restart survival.
3. **Escalation on repeated gate failure.** Drive the same gate to fail K times; verify the run escalates (model-tier bump / task split / human-interrupt) rather than looping forever — exercising bounded retry + HITL interrupt + escalation policy.
4. **Adversarial-convergence loop to a fixed point.** Run a review→fix cycle where injected findings decay over passes; verify the loop recognizes a 3-CLEAN-style convergence condition and terminates (and that a new "commit" resets the streak) — exercising cyclic subgraph + convergence-condition state.
5. **Human-approval interrupt at a phase boundary.** Pause at a gate awaiting external approval, persist, and resume on the approval signal arriving in a *later process* — exercising `interrupt()` + durable wait + external-event resume (server thread).
6. **Budget-bounded run.** Give a run a token/cost ceiling; verify it meters spend across sub-agents and halts-or-degrades gracefully at the ceiling rather than overrunning — exercising the NEW budget-metering capability (expected to reveal a gap).
7. **Parallel sub-agent fan-out with isolated contexts + result synthesis.** Spawn K specialist sub-agents with disjoint context, run concurrently, and synthesize their structured outputs at a join node — exercising sub-agent spawning + context isolation + fan-in.

---

## 7. Phase-1-Ready Capability Checklist

The pregolya PRD/architecture must **demonstrate** (not merely assert) support for each.
Maps to STATE.md D8. Legend: [P] planned-surface covers it; [N] NEW / gap to resolve in ADR.

- [ ] **[P] Durable graph runs surviving process restart** — checkpoint after each super-step; resume produces identical continuation. (ADR: checkpoint atomicity, single-writer.)
- [ ] **[P] Checkpoint + external store** — SQLite + in-memory minimum; Postgres stretch; msgpack wire format; one-way Python-checkpoint import. (D11.2)
- [ ] **[P] Sub-agent invocation with isolated contexts** — subgraph / nested-run with disjoint state; fan-in synthesis. → also see [N] agent-spawning API.
- [ ] **[P] Parallel fan-out (Send API)** — map over a dynamic collection; partial-failure surfaced via error taxonomy (not silent empty return, per pregolya `CLAUDE.md`).
- [ ] **[P] Conditional routing / quality-gate branching** — conditional edges keyed on structured node output.
- [ ] **[P] HITL interrupt + resume** — `interrupt()` persists and resumes on external signal, including across process boundaries.
- [ ] **[P] Structured outputs** — typed verdicts/findings/scores as first-class content, not stringly-typed JSON.
- [ ] **[P] MCP tool integration** — pregolya-mcp adapter (D1) for external services (GitHub, CI, chat, digital twins).
- [ ] **[P] Persistent resumable sessions / threads** — pregolya-server threads + assistants (D13).
- [ ] **[P] Scheduled / proactive agency** — server crons for nightly/maintenance-style runs (D13).
- [ ] **[P] Streaming + traceability** — token/step streaming; structured event catalog gives intent→artifact audit trail.
- [ ] **[N] Agent registry + routing** — a dispatch abstraction mapping work-kind → specialist agent config (model/prompt/tools). Resolve in pregolya-graph or a factory-layer ADR.
- [ ] **[N] Execution-context isolation (worktree/VM analog)** — runtime semantics for per-unit isolated filesystem/workspace. Resolve scope: runtime primitive vs application concern.
- [ ] **[N] Budget / cost metering + quotas** — per-run and per-sub-agent token/cost accounting with a ceiling that halts/degrades gracefully. Resolve in pregolya-server + graph ADR.
- [ ] **[N] Convergence-loop support** — bounded cyclic execution with per-iteration checkpointing and a first-class convergence/termination condition (3-CLEAN / novelty-decay shape).
- [ ] **[N] Agent identity / provenance (optional/governance)** — verifiable actor identity per action; may fold into server auth + event catalog. Decide in scope.

**D9 gate note:** items marked [N] are exactly the material for the mandated ≥2-alternatives
architecture conversation before the pregolya-graph execution-model ADR is locked.

---

## 8. Distinctions to Preserve for Holdout Authoring (Anti-Leakage)

- Domain B forces **durability, sub-agent isolation, convergence loops, and budget governance** hardest. (Domain A/SOC forces tool-calling + HITL-before-containment + high-volume triage; Domain C/personal-assistant forces persistent-session + multi-channel ingress + local-first.) Keep holdouts domain-distinct so each exercises its unique primitive.
- Per D9, do **not** encode vsdd-factory's specific phase names or the 33-agent roster as required outputs — that is prior art, not a conformance target. Test the *capability* (e.g., "orchestrate N specialists through a gated pipeline that resumes after crash"), not the vsdd shape.
- Per D13, pregolya-server is first-party with real BCs/holdouts; there is **no** wire-compatibility or conformance obligation to LangGraph Platform or any external factory.

---

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| **Perplexity perplexity_research (PRIMARY)** | 1 (high effort, strip_thinking) | Deep multi-source landscape of 2026 autonomous SWE + factory-style multi-agent SDLC orchestration (Devin, Codex, Claude Code, Copilot/Agentic Workflows/Agent HQ, Jules, Kiro, Spec Kit, StrongDM) + recurring primitives. Result 95.9k chars; ~67% read directly + targeted grep verification of remainder. |
| Perplexity perplexity_search | 1 | Ranked URLs + snippets for StrongDM Software Factory talks/writeups (Simon Willison, StrongDM blog, YouTube briefing, Ry Walker research, LinkedIn). |
| WebFetch | 1 | factory.strongdm.ai home — verbatim characterization of the Software Factory operating model, rules, pipeline, metrics. |
| Local file reads (Read/Glob) | 8 | vsdd-factory README, pipeline-paths, agents-reference, phase-3-tdd-delivery, phase-7-convergence, factory-project-state-template; pregolya CLAUDE.md, STATE.md, market-intel. Orchestration-pattern inventory + pregolya planned-surface + D8 context. |
| Grep | 2 | Locate/verify synthesis sections in the large research result file. |

**Total MCP tool calls:** 3 (1 perplexity_research, 1 perplexity_search, 1 WebFetch is not MCP — MCP total = 2 Perplexity). Tavily not needed — Perplexity + WebFetch + local corpus were sufficient and cross-corroborating (10 independent StrongDM sources agreed).
**Training data reliance:** low — landscape claims are URL-cited via sonar-deep-research; StrongDM claims corroborated across 10 sources + primary site; vsdd/pregolya claims are direct local file reads. Internal architectures of closed agents (Devin/Codex/Jules concurrency + resource models) are flagged as vendor-undocumented, not asserted.

## Sources

**Local (prior art / evidence, read-only):**
- `/Users/jmagady/Dev/vsdd-factory/README.md`, `docs/guide/pipeline-paths.md`, `docs/guide/agents-reference.md`, `docs/guide/phase-3-tdd-delivery.md`, `docs/guide/phase-7-convergence-release.md`, `plugins/vsdd-factory/templates/factory-project-state-template.md`
- `/Users/jmagady/Dev/pregolya/CLAUDE.md`, `.factory/STATE.md` (D7/D8/D9/D11/D13), `.factory/planning/market-intel.md`

**Web (StrongDM):**
- [WF] https://factory.strongdm.ai/ and /products (fetched 2026-07-13)
- [W1] https://simonwillison.net/2026/Feb/7/software-factory/
- [W2] https://www.strongdm.com/blog/the-strongdm-software-factory-building-software-with-ai
- [W4] https://www.youtube.com/watch?v=dOuzQVvMVPw ("Software Factories And The Agentic Moment")
- [W6] https://rywalker.com/research/strongdm-factory
- [W9] https://factory.strongdm.ai/products (CXDB, StrongDM ID, Attractor)
- [W10] https://www.linkedin.com/posts/neerajsingh0101_the-shape-of-the-thing-... ; [W3] eugenehlyzov LinkedIn; [W5] jaytaylor.com/notes/node/1771018596000.html; [W7] alldevblogs mirror; [W8] dev.to/uenyioha agentic-software-factory

**Web (landscape, via perplexity sonar-deep-research [R1], URL-cited within):**
- Devin/Cognition (cognition.ai; Amplifi Labs; Cognizant partnership PR); OpenAI Codex cloud docs; Anthropic Claude multi-agent sessions docs + Claude Code practitioner guidance; GitHub Copilot cloud agent docs; GitHub Agentic Workflows + Agent HQ (Universe 2025); Google Jules (jules.google); Kiro (kiro.dev); GitHub Spec Kit repo; Factory.ai; MindStudio "dark factory" definition.
