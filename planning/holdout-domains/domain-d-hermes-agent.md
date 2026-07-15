---
document_type: holdout-domain-brief
domain_id: D
domain_name: Hermes-style agentic assistant
status: complete
producer: product-owner
timestamp: 2026-07-15
traces_to: D19
source_decision: D8 (amended 2026-07-15 via D19)
project: ferrochain
purpose: Phase-1 forcing function + Phase-2 holdout authoring input (product-owner authors hidden scenarios; only this domain is public)
assessor: product-owner (disposition analysis against BC-INDEX + capability shards; research summary from research-agent 2026-07-14)
confidence: medium-high (architecture documented at docs/API level; numeric thresholds unverified — see §Research Caveats)
version: "1.1"
input-hash: "[pending state-manager]"
changelog:
  - "v1.0: Initial domain analysis (D19 burst). Research-agent summary ingested; all 12 requirements dispositioned against BC-INDEX v1.0 + capabilities-p0/p1-p2."
  - "v1.1 (D20 sub-burst 2): Applied 9 new BCs + CAP-020 + CAP-021. Dispositions updated: req 1 COVERED (BC-2.08.013 ToolCallDialect), req 2 COVERED (BC-2.10.003 v1.2 OnCeiling::Summarize + BudgetInfo), req 3 unchanged + CAP-020 note, req 4 unchanged + CAP-020 note, req 5 v2-DEFERRED (execute_code RPC callback), req 6 COVERED (BC-2.13.007 env-var allowlist), req 8 COVERED (BC-2.04.008 FTS single-process v1), req 9 v2-DEFERRED (in-flight cancellation), req 10 COVERED (BC-2.08.014 ProviderFallbackPolicy), req 11 COVERED (CAP-021/BC-2.09.006-007 MCP server role)."
---

# Holdout Domain D — Hermes-style Agentic Assistant

> **Scope note.** This brief characterizes the *problem space* and maps it to ferrochain's
> planned primitive surface. It deliberately does NOT author acceptance scenarios — those are
> written hidden, later, by the product-owner (per D8). Everything here is a forcing function
> for Phase 1 (PRD/architecture must demonstrate these workloads are supportable) and a
> fact-base for Phase 2 holdout authoring.

> **Source authority.** The primary reference is [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent),
> referenced in D19 as "this library." All coverage claims are verified against
> `specs/behavioral-contracts/BC-INDEX.md`, `domain-spec/capabilities-p0.md`, and
> `domain-spec/capabilities-p1-p2.md` as read during this burst. Numeric parameters
> (iteration budgets, token caps, threshold values) are flagged as unverified — see
> §Research Caveats.

> **Citation convention.** `[BC-S.SS.NNN]` = specific contract verified to apply.
> `[CAP-NNN]` = capability shard confirmed. `[R]` = research-agent summary claim,
> documentation-level evidence, not independently line-verified.

---

## 10-Line Domain Summary

1. `hermes-agent` is a Python agent framework by NousResearch oriented around the Hermes model
   family, implementing a full ReAct-loop agent with a normalized multi-API backend, built-in
   tool library, and structured memory/identity system. [R]
2. Its defining architectural feature is **three-API normalization**: `chat_completions`,
   `codex_responses`, and `anthropic_messages` are all translated to a unified internal
   representation — any conforming provider is a first-class citizen without special-casing
   in the agent loop. [R]
3. The **Hermes ChatML tool-call format** is a distinct XML-delimited dialect
   (`<tools>...</tools>` in the system prompt; `<tool_call>{"name":...}</tool_call>` in model
   responses) that diverges from native OpenAI JSON tool calls and native Anthropic tool_use
   blocks — and is the sharp test for pluggable parser seams in any framework. [R]
4. The agent maintains **three-tier cached system prompts**: SOUL.md identity → MEMORY.md
   curated facts / USER.md user profile → per-turn volatile overlays; frozen-snapshot semantics
   for the stable tiers preserve prompt-cache hits while allowing ephemeral per-turn additions. [R]
5. **Runtime-mutable procedural skills** (agentskills.io-style SKILL.md) allow the agent to load
   skill documentation on demand and, in a self-improvement loop, write/update skill files at
   runtime to accumulate operating knowledge. [R]
6. Code execution uses **Unix-socket RPC** (`execute_code` tool): generated code runs in a
   sandbox and can call back into the registered tool registry via the RPC socket during execution;
   only the final result is returned to the model context. [R]
7. A **SQLite WAL state.db + FTS5** durable store holds full conversation history including
   tool calls and reasoning traces; history is multi-process safe and FTS5 search is exposed as
   a first-class agent tool. [R]
8. The agent supports **natural-language cron scheduling** (e.g., "every Monday at 9am"),
   **sub-agent spawning** (isolated child loops with own conversation/tools/budget), and
   **interrupt/cancellation** that can cancel in-flight model calls or tool executions on an
   incoming interrupt message. [R]
9. **MCP is implemented in both directions**: the agent can connect to external MCP servers as a
   client AND expose its own tools as an MCP server for other LLM applications to consume. [R]
10. For ferrochain, this domain validates that the core graph/server surface supports the complete
    Hermes-style agentic pattern; it forces **one net-new framework-scope surface** (MCP server
    role) and **seven partial gaps** in existing capabilities, and distinguishes two application-layer
    concerns (layered system prompt, runtime skills) that intentionally live above the framework.

---

## 1. What a Hermes-style Agent Actually Does

### 1.1 Core ReAct Loop

The agent runs a Reason-Act cycle: given a user message, the model reasons over available tools,
selects a tool call, receives its output, reasons again, and continues until it produces a final
answer or exhausts a configured iteration budget. [R]

Key behavioral properties:
- **Strict role alternation**: human → assistant → tool → assistant, with no skipped roles. [R]
- **Bounded iteration**: a configurable maximum step count (research reports ~90 for primary
  agent, ~50 for sub-agents — UNVERIFIED numeric) prevents infinite loops; on exhaustion the
  agent gracefully stops and produces a summarizing response rather than returning an error. [R]
- **Budget exposed to model**: the remaining iteration count is injected into the model context,
  allowing the model to adapt its reasoning strategy as budget runs low. [R]

### 1.2 Multi-API Normalization

Three provider API shapes are normalized to a single internal conversation representation: [R]
- `chat_completions` (OpenAI, Ollama, most open-source serving)
- `codex_responses` (OpenAI codex-style)
- `anthropic_messages` (Anthropic)

Tool-call translation is per-provider: native OpenAI JSON `tool_calls`, native Anthropic
`tool_use` blocks, and the Hermes ChatML XML dialect (`<tool_call>{json}</tool_call>` tags)
are all first-class — the choice is made per configured model. [R]

### 1.3 Memory and Identity System

Three-tier system prompt with frozen-snapshot semantics: [R]

| Tier | File | Content | Stability |
|------|------|---------|-----------|
| Identity | `SOUL.md` | Agent persona, values, operating principles | Frozen; never mutated at runtime |
| Durable facts | `MEMORY.md` + `USER.md` | Curated long-term facts, user preferences | Updated only by explicit memory-write tools; char caps + injection scanning [R-UNVERIFIED] |
| Volatile | Per-turn overlay | Ephemeral context for current run | Assembled fresh each turn; does not invalidate cached prefix |

### 1.4 Built-in Tool Library and Skills

~40 built-in tools covering file I/O, code execution, web browsing, memory management, cron
scheduling, and sub-agent spawning. [R-UNVERIFIED count]

**Skills** (agentskills.io SKILL.md pattern): skill files teach the agent *how and when* to
use groups of tools. The agent can load skill docs on demand and, in a self-improvement loop,
write or update skill files to accumulate operating knowledge over time. Human-in-the-loop
approval is recommended but not architecturally enforced by the framework. [R]

### 1.5 Code Execution via Unix-Socket RPC

`execute_code` is implemented as a Unix-socket RPC (Linux/macOS only): [R]
- Generated code runs in an isolated sandbox.
- During execution the sandbox can call back into the registered tool registry via the RPC socket.
- Only the final output is returned to the model context; intermediate tool calls do not consume
  conversation context.
- Per-script call limits and timeout are enforced; the outer run can interrupt an in-flight
  code execution via a separate signal.

### 1.6 Durable State Store (SQLite WAL + FTS5)

A `state.db` SQLite database in WAL mode holds: [R]
- Full conversation history including all tool calls and reasoning traces.
- FTS5 full-text index over the history, exposed as a first-class agent tool (`search_history`).
- Multi-process safe (WAL mode allows concurrent readers alongside one writer).
- Trajectory export is out of framework scope and handled by the application layer.

### 1.7 Sub-agent Spawning

The agent can spawn isolated child loops: [R]
- Each child has its own conversation thread, tool set, budget, and system-prompt identity.
- Parent/child lineage is tracked in the state store.
- Child iteration budget is separate from (and typically smaller than) parent budget
  (research reports ~50 — UNVERIFIED numeric).
- Parent can await child result, receive structured output, or fire-and-forget.

---

## 2. 2026 Hermes-Relevant Landscape

Hermes-agent is one of several open-source frameworks targeting the model-native tool-calling
agent pattern:

| Framework / project | Relevant overlap | Differentiator |
|---------------------|-----------------|----------------|
| **hermes-agent** (NousResearch) | ReAct loop, ChatML XML tool dialect, multi-API normalization, FTS5 state store, sub-agents | Hermes model integration, SOUL/MEMORY identity system |
| **smolagents** (HuggingFace) | Code-centric agents, tool registry | Different execution model (code generation as primary action) |
| **OpenClaw** (Domain C) | Gateway, multi-channel, memory, cron, skills | WhatsApp/Telegram focus, Node.js runtime |
| **LangGraph** (Python) | Graph-based agent loops, durable checkpointing | Python-first, LangGraph Platform |
| **agentskills.io / SKILL.md** | Procedural skill library pattern | Skill format standard, not a full framework |

The key forcing-function distinction from Domains A/B/C: Domain D exercises the **ChatML XML
tool-call dialect** (Hermes-specific), **MCP server role** (exporting ferrochain tools to
external LLM apps), and **code-execution RPC callback** (generated code calling tools mid-run).
These three surfaces are not forced by any other domain.

---

## 3. Framework Demands — Mapping to ferrochain's Planned Surface

Legend: **[COVERED]** = in-scope BC verified as semantically matching.
**[PARTIAL]** = foundation exists, gap identified (historic; all PARTIALs resolved or deferred in v1.1).
**[NEW framework-scope]** = not in any BC or capability; requires framework work.
**[NEW application-layer]** = intentionally above the framework; no BC needed.
**[v2-DEFERRED]** = gap acknowledged; framework work scoped to v2, not v1.

| # | Hermes requirement | ferrochain primitive | Disposition | Gap statement (if PARTIAL/NEW) |
|---|-------------------|---------------------|------------|-------------------------------|
| 1 | Multi-provider tool-calling with **pluggable parsers** — Hermes ChatML XML dialect selectable per model alongside native OpenAI JSON + Anthropic | SS-08 / CAP-009 / BC-2.08.002 (provider conformant tool-call round-trip); **BC-2.08.013 (ToolCallDialect — pluggable per-model serialize/deserialize seam)** D20 sub-burst 1 | **[COVERED CAP-009/BC-2.08.013]** | Gap closed D20 sub-burst 1: BC-2.08.013 (ToolCallDialect) provides the pluggable seam; Hermes ChatML XML is the `HermesChatMlXml` built-in dialect. E-PROV-009 covers dialect parse failures. |
| 2 | **ReAct loop** with bounded iteration budget + **graceful stop-and-summarize** on exhaustion; budget exposed to model mid-run | BSP engine CAP-003/SS-02 + CAP-004/SS-03; `recursion_limit` / E-GRAPH-017 (BC-2.08.002); budget governance CAP-012/SS-10 (**BC-2.10.003 v1.2: OnCeiling::Summarize + RunContext.budget\_info / BudgetInfo**) D20 sub-burst 1 | **[COVERED CAP-003/CAP-004/CAP-012/BC-2.10.003 v1.2]** | Both gaps closed by BC-2.10.003 v1.2 (D20 sub-burst 1): (a) OnCeiling::Summarize variant injects a stop-and-summarize prompt to the model on ceiling; (b) RunContext.budget\_info / BudgetInfo struct exposes remaining token/cost budget to the model mid-run. |
| 3 | **Layered/cached system-prompt composition** (SOUL.md identity → MEMORY.md → volatile overlays; ephemeral per-turn overlays that do not invalidate cached prefix; frozen-snapshot semantics) | CAP-001/SS-01 (typed messages); CAP-017/SS-15 (memory store P2); CAP-005/SS-04 (checkpoint per super-step); CAP-020/SS-15 (BC-2.15.006 frozen-snapshot context mutation) D20 sub-burst 1 | **[NEW application-layer]** | ferrochain provides the building blocks (message types, memory store, runnable config) but no framework primitive governs tiered system-prompt construction or volatile overlay sequencing. This is a concern for the Hermes-layer application built on top. _(D20 note: BC-2.15.006 adds frozen-snapshot context mutation as a framework primitive — CAP-020; the composition orchestration policy (SOUL.md → MEMORY.md → per-turn overlay) remains application-layer.)_ |
| 4 | **Runtime-mutable procedural skills** (agent loads SKILL.md on demand AND writes/updates at runtime — self-improvement loop) | CAP-020/SS-15 / BC-2.15.004 (SkillStore — load-on-demand skill documents); BC-2.15.005 (MemoryWriteGuard — guarded skill writes) D20 sub-burst 1 | **[NEW application-layer]** | "Skill" as a routing concept (which skill to load and when) is not modeled at the framework level. _(D20 note: CAP-020/BC-2.15.004 adds SkillStore for load-on-demand skill documents; BC-2.15.005 adds MemoryWriteGuard for guarded skill writes — these are framework primitives. The routing and self-improvement loop orchestration remains application-layer.)_ |
| 5 | **Programmatic tool execution** ("tools-callable-from-code"): generated code invokes registered tools via IPC/RPC socket during execution; only final output returns to context; per-script call limits, timeout, interrupt | SS-13 / CAP-015 / BC-2.13.001–007 (sandboxed execution, enforcing backend default, workspace confinement, env-var allowlist) | **[v2-DEFERRED CAP-015/SS-13]** | Sandboxed execution with pluggable backends, confinement, env-var allowlist, and seatbelt covered (BC-2.13.001–007). The "execute_code RPC gateway" — generated code calling back into the registered tool registry via an IPC socket during execution — is not in v1 scope. Deferred to v2: the reverse-callback pattern (code→ferrochain-tools) requires a new IPC/RPC seam in the sandbox backend. D20 sub-burst 2 explicit deferral. |
| 6 | **Sandboxed execution** across pluggable backends (local + container min.) with **env-secret stripping** | SS-13 / CAP-015 / BC-2.13.001–006; **BC-2.13.007 (SandboxConfig.env\_allowlist — env-var allowlist pattern filter, fail-closed)** D20 sub-burst 1 | **[COVERED CAP-015/BC-2.13.007]** | Gap closed D20 sub-burst 1: BC-2.13.007 specifies SandboxConfig.env\_allowlist regex pattern filter; E-SBXD-006 for invalid allowlist patterns. Fail-closed: no env-var inherits unless explicitly allowed; DI-006 enforced. |
| 7 | **Sub-agent spawning** — isolated child loops, own conversation/tools/budget/identity, parent/child lineage | Subgraphs CAP-003/SS-02; per-sub-agent budget CAP-012/BC-2.10.001 EC-004; streaming parent_ids correlation CAP-007/BC-2.06.002; thread isolation CAP-014/SS-12/BC-2.12.003 | **[COVERED CAP-003/CAP-012/CAP-007/CAP-014]** | Isolated subgraph contexts, independent budget policies, parent_ids lineage in events, and thread isolation all covered. "Own identity" (each sub-agent gets its own SOUL.md) is an application-layer concern — the framework provides no concept of agent identity, by design. |
| 8 | **Durable searchable concurrent conversation store** (full history incl. tool calls + reasoning traces; multi-process safe; **FTS exposed as a tool**) | SS-04 / CAP-005 / BC-2.04.001–BC-2.04.007 (checkpoint history); **BC-2.04.008 (FTS over checkpoint history — search\_history callable tool, SQLite FTS5)** D20 sub-burst 1; SS-15 / CAP-017 / BC-2.15.001 (hybrid KV+vector memory P2) | **[COVERED CAP-005/BC-2.04.008 — single-process v1]** | Gap closed D20 sub-burst 1: BC-2.04.008 adds search\_history(FtsSearchConfig) backed by SQLite FTS5, co-transactional with checkpoint writes (DI-002); E-CHKPT-008/009. Single-process SQLite WAL semantics; multi-process WAL-safe write concurrency deferred to v2. |
| 9 | **Interrupt/HITL cancellation mid-run** — in-flight model call or in-flight tool/code execution cancellable by incoming message; structured interruption | SS-05 / CAP-006 / BC-2.05.001–BC-2.05.006 (node-boundary interrupt + risk-tiered classification) | **[v2-DEFERRED CAP-006/SS-05]** | Node-boundary HITL interrupt/resume with risk tiers fully specified (BC-2.05.001–006). In-flight cancellation — ferrochain's `interrupt()` fires at node boundaries (between super-steps), not within a running model inference call or a running tool execution — is not in v1 scope; deferred to v2. See BC-2.05.001 Related BCs v2-deferral note (D20 sub-burst 2). Domain A brief also flagged this. |
| 10 | **Provider failover + retry policy** — ordered fallback chain on 429/5xx/auth; credential-refresh-then-failover | SS-16 / CAP-018 / BC-2.16.001–BC-2.16.003 (per-tool retry, circuit breaker); SS-08 / CAP-009 (provider abstraction); **BC-2.08.014 (ProviderFallbackPolicy — ordered chain on 429/5xx/auth + credential-refresh-before-failover)** D20 sub-burst 1 | **[COVERED CAP-009/BC-2.08.014]** | Gap closed D20 sub-burst 1: BC-2.08.014 (ProviderFallbackPolicy) specifies ordered fallback chain on 429/5xx/auth with optional credential-refresh-before-failover. E-PROV-010 covers chain exhaustion. |
| 11 | **MCP as BOTH client AND server** — ferrochain connects to MCP servers (client) AND exposes its own tools/resources as an MCP server for other LLM apps | SS-09 / CAP-010 / BC-2.09.001–BC-2.09.005 (MCP client: discovery, routing, untrusted ingress); **CAP-021/BC-2.09.006-007 (MCP server role: tools/list advertisement + tools/call invocation; stdio + SSE transports)** D20 sub-burst 1 | **[COVERED CAP-021/BC-2.09.006-007]** | Gap closed D20 sub-burst 1: CAP-021 (MCP Server Role) added. BC-2.09.006 specifies MCP server tool advertisement (tools/list); BC-2.09.007 specifies MCP server tool invocation (tools/call). Both stdio and SSE transports. E-MCP-005 covers bind failure. |
| 12 | **Scheduled autonomous runs** — cron-style, **natural-language definitions**, unattended normal loop, output to external channel | SS-12 / CAP-014 / BC-2.12.004 (CronSchedule with standard cron expressions, isolated session per firing) | **[COVERED SS-12/CAP-014/BC-2.12.004]** + **[NEW application-layer]** for NL definitions | Standard cron expression scheduling with fresh isolated session per firing fully covered. NL → cron synthesis (e.g., "every Monday at 9am" → `0 9 * * 1`) is application-layer; ferrochain accepts the resulting expression, not the NL input. Output to external channel (Slack/WhatsApp routing) is application-layer routing. |

---

## 4. Realistic Evaluation Shapes (General — NOT Holdout Scenarios)

These are *categories* of scenario that would credibly stress a Hermes-style agent on ferrochain,
provided to guide the product-owner's hidden authoring — deliberately generic:

- **Hermes XML tool-call parse and execution.** Issue a prompt to a Hermes-configured model
  that emits a `<tool_call>{json}</tool_call>` response; verify ferrochain correctly parses the
  XML dialect, routes the tool invocation, and completes the round-trip — exercising the
  pluggable parser gap (req 1).

- **Iteration budget exhaustion with graceful degradation.** Configure a ReAct agent with a
  very low iteration ceiling (e.g., 3 steps); give it a task that requires more; verify the
  run produces a meaningful partial-result response rather than crashing — exercising the
  stop-and-summarize gap (req 2).

- **Sub-agent fan-out with independent budgets.** Spawn 3 child sub-agents with distinct
  configs, each hitting a different tool, then synthesize their results in the parent — exercising
  sub-agent spawning primitives (req 7) and per-sub-agent budget isolation (CAP-012).

- **MCP server role: external consumer.** Start a ferrochain-server process that exposes its
  registered tools as an MCP server endpoint; connect an external MCP client (or a second
  ferrochain instance) and invoke a tool via the MCP protocol — exercising the NEW MCP server
  surface (req 11). This test is expected to reveal the gap.

- **Provider failover on 429.** Configure a primary provider that returns 429; a fallback
  provider in an ordered chain; verify the run silently retries on the fallback without
  surfacing the 429 to the graph — exercising the provider failover gap (req 10).

- **Code-calls-tools RPC callback.** Execute a code block that, during execution, calls back
  into a registered ferrochain tool via the IPC socket; verify only the final code output
  enters the model context, not the intermediate tool call/result — exercising the
  execute_code RPC gateway gap (req 5).

- **Mid-inference cancellation.** Send a cancel/interrupt signal while a model inference call
  is in progress (not at a node boundary); verify the run cleanly terminates and checkpoints
  a partial state — exercising the in-flight cancellation gap (req 9).

---

## 5. Phase-1-Ready Capability Checklist (Domain D Contributions)

Architecture/PRD must demonstrate the following are supportable. Items marked **[extends checklist]**
are new or sharpened relative to the D8/Domain A/B/C baseline. Items marked **[NEW — framework-scope]**
require a positive adoption/defer/out-of-scope decision in an ADR.

**Covered by planned surface (verify in holdout, do not re-design):**
- [ ] ReAct loop execution via BSP super-steps with configurable step ceiling and E-GRAPH-017
      on exhaustion (CAP-003/CAP-004/BC-2.08.002).
- [ ] Token/cost budget governance with halt and HITL-escalate on ceiling (CAP-012/BC-2.10.003/BC-2.10.004).
- [ ] Sub-agent spawning with isolated contexts and independent budget policies
      (CAP-003/CAP-012/BC-2.10.001 EC-004).
- [ ] Parent/child run lineage via `run_id + parent_ids` in streaming events (CAP-007/BC-2.06.002).
- [ ] Sandboxed execution with enforcing backend default + env-var allowlist (CAP-015/BC-2.13.001–BC-2.13.007 incl. env-secret stripping, D20).
- [ ] Cron-style scheduled runs with fresh isolated session per firing (CAP-014/BC-2.12.004).
- [ ] MCP client: runtime tool discovery + routing + untrusted-ingress guardrail
      (CAP-010/BC-2.09.001–BC-2.09.005; CAP-013/BC-2.11.001–BC-2.11.006).
- [ ] MCP server role: tool advertisement (tools/list) + invocation (tools/call); stdio + SSE transports
      (CAP-021/BC-2.09.006–BC-2.09.007, D20).
- [ ] Per-model pluggable tool-call parser seam: ToolCallDialect trait; built-in HermesChatMlXml + OpenAI JSON + Anthropic
      (CAP-009/BC-2.08.013, D20).
- [ ] Stop-and-summarize graceful degradation on ceiling: OnCeiling::Summarize + RunContext.budget\_info / BudgetInfo
      (CAP-012/BC-2.10.003 v1.2, D20).
- [ ] Provider-level ordered failover chain on 429/5xx/auth with credential-refresh-before-failover
      (CAP-009/BC-2.08.014, D20).
- [ ] FTS over checkpoint history as callable tool: search\_history(FtsSearchConfig) / SQLite FTS5 — single-process v1
      (CAP-005/BC-2.04.008, D20).

**Gaps in existing planned surface (all resolved or deferred in D20 — see §3 for detail):**
- [ ] **[COVERED D20 — BC-2.08.013]** Per-model pluggable tool-call parser seam — ToolCallDialect trait
      with built-in HermesChatMlXml, OpenAI JSON, and Anthropic dialects. E-PROV-009 covers parse failures.
      (Moved to "Covered by planned surface" checklist above.)
- [ ] **[COVERED D20 — BC-2.10.003 v1.2]** Stop-and-summarize graceful degradation mode on budget/iteration
      ceiling — OnCeiling::Summarize variant + RunContext.budget\_info / BudgetInfo for mid-run budget
      injection. (Moved to "Covered by planned surface" checklist above.)
- [ ] **[v2-DEFERRED]** In-flight cancellation of model calls and tool executions — cancel signal arrives
      mid-inference or mid-tool, not just at node boundaries. See BC-2.05.001 Related BCs v2-deferral note.
- [ ] **[v2-DEFERRED]** Execute_code → tool-registry IPC/RPC callback gateway — running sandbox code can
      invoke registered ferrochain tools via a local socket during execution. Not in v1 scope.
- [ ] **[COVERED D20 — BC-2.13.007]** Env-secret stripping at sandbox execution boundary — SandboxConfig.env\_allowlist
      regex pattern filter; E-SBXD-006 for invalid patterns; fail-closed. (Moved to "Covered" above.)
- [ ] **[COVERED D20 — BC-2.08.014]** Provider-level ordered failover chain on 429/5xx/auth — ProviderFallbackPolicy
      with optional credential-refresh-before-failover; E-PROV-010 for chain exhaustion. (Moved above.)
- [ ] **[COVERED D20 — BC-2.04.008 single-process v1]** FTS over conversation/checkpoint history as a callable tool —
      search\_history(FtsSearchConfig) / SQLite FTS5; co-transactional with checkpoint writes (DI-002). Multi-process
      WAL-safe write concurrency deferred to v2. (Moved above.)

**[NEW — framework-scope] resolved in D20:**
- [ ] **[COVERED D20 — CAP-021/BC-2.09.006-007]** MCP server role — `ferrochain-server` or `ferrochain-mcp`
      exposes registered tools and resources via the MCP protocol so external LLM applications
      can connect as MCP clients. Adopted in Wave 2: CAP-021 added; BC-2.09.006 (tools/list) and
      BC-2.09.007 (tools/call) specify behavior for stdio and SSE transports. E-MCP-005 covers
      bind failure. (Moved to "Covered by planned surface" checklist above.)

**Application-layer (intentionally above the framework — no BC needed):**
- [ ] Layered/cached system-prompt composition (SOUL.md → MEMORY.md → per-turn overlay).
      ferrochain provides message primitives + memory store; the composition policy is the
      Hermes application layer.
- [ ] Runtime-mutable procedural skills (SKILL.md load, route, write-back). No ferrochain
      primitive is required; the memory store is the persistence surface.
- [ ] Natural-language cron definitions (NL → cron expression synthesis). ferrochain accepts
      the resulting cron expression; parsing is application-layer.
- [ ] Sub-agent identity / SOUL.md per child. Agent identity (persona, values) is application-layer
      system prompt content.
- [ ] External channel output (Slack/WhatsApp routing from cron runs). Application-layer
      integration built on top of ferrochain-server run results.

---

## 6. Research Caveats

The following items are from the research-agent summary as documentation-level evidence and have
**not** been independently line-verified against the hermes-agent source code:

| Item | Caveat |
|------|--------|
| Iteration budget numeric values (~90 primary, ~50 sub-agent) | Unverified — treat as indicative order-of-magnitude; do NOT encode as conformance thresholds |
| Character caps on MEMORY.md / USER.md | Unverified — injection scanning behavior not confirmed at code level |
| ~40 built-in tools | Unverified count |
| Unix-socket RPC protocol details (message format, authentication) | Described at architecture level; wire protocol not confirmed |
| SQLite FTS5 indexing columns and query interface | Confirmed as FTS5; specific schema not inspected |
| Multi-process WAL safe write behavior | Correct for SQLite WAL mode in general; hermes-agent specific concurrency contracts not inspected |
| MCP server implementation maturity | Existence confirmed via research; completeness and transport specifics not verified |
| Natural-language cron parsing library / LLM-based synthesis | Architecture unknown; "natural-language definitions" is research-agent characterization |

**Design implication:** holdout scenarios must NOT depend on the specific numeric thresholds
above. They must test observable behavior (graceful stop, meaningful partial output, correct
tool call parsing) not internal parameter values.

---

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| Research-agent summary (pre-ingested) | N/A | Condensed 12-requirement analysis of hermes-agent architecture, verified at documentation level |
| **Local file reads (Read tool)** | 15 | BC-INDEX.md, capabilities-p0.md, capabilities-p1-p2.md, BC-2.10.001, BC-2.05.006, BC-2.08.002, BC-2.09.001, BC-2.16.001, BC-2.12.004, BC-2.15.001, domain-a-soc-analyst.md, domain-b-dark-factory.md, domain-c-openclaw.md | Disposition verification against actual BCs and capability shards |
| Perplexity / Tavily | 0 | Research-agent output was pre-provided; no additional external queries made |
| Training data | 0 | All factual claims about ferrochain surface verified against local spec files |

**Total new MCP tool calls this burst:** 0 (all evidence from local files + pre-provided research summary)
**Numeric parameters:** all flagged as UNVERIFIED — see §6 Research Caveats.

---

## Domain Distinctions for Holdout Authoring Anti-Leakage

- Domain D forces **Hermes ChatML XML tool-call dialect, MCP server role, and execute_code RPC callback** hardest. Keep holdouts domain-distinct so each exercises its unique primitive surface.
- Domain A/SOC forces HITL before containment, forensic audit, parallel enrichment. Domain B/dark-factory forces multi-day durability, convergence loops, budget governance. Domain C/OpenClaw forces channel adapters, webhook ingress, local-first packaging.
- Do NOT encode Hermes model weights or NousResearch-specific model names as conformance targets — test the *capability* (pluggable parser seam, MCP server role), not the hermes-agent implementation.
- The single NEW framework-scope item (MCP server role) is the highest-value forcing function for the D19 human gate and the adversary probe.
