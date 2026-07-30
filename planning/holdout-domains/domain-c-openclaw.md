---
document_type: holdout-domain-brief
domain: C
domain_name: "OpenClaw-like personal AI assistant"
producer: research-agent
timestamp: 2026-07-13
traces_to: "D8 (amended 2026-07-13)"
project: pregolya
verification: primary-source (github.com/openclaw/openclaw README + docs, openclaw.ai, npm) cross-checked with web research
status: complete
confidence: high (identity/architecture verified from primary repo docs); medium (scale numbers — sources conflict, see §6)
---

# Holdout Domain C — OpenClaw-like Personal AI Assistant

> **Purpose (per D8-amended):** Domain C is both a **Phase-1 design forcing function** (the PRD/architecture
> must demonstrate pregolya can support this workload) and a **Phase-2 holdout scenario domain**
> (product-owner authors hidden acceptance scenarios; only the domain is public). This brief describes
> what OpenClaw **actually is**, verified from primary sources — not what a clone is assumed to be.

> **Verification note.** OpenClaw is a real, verifiable project. Do NOT confuse it with the unrelated
> `pjasicek/OpenClaw` — a C++ reimplementation of the 1997 platformer *Captain Claw*. The subject here is
> the viral personal-AI-assistant project at `github.com/openclaw/openclaw` / `openclaw.ai`. All non-obvious
> claims below carry a source URL. Unverifiable or conflicting items are flagged inline.

---

## 1. What OpenClaw Is, Precisely

**Identity.** OpenClaw is a self-hosted, open-source, local-first **personal AI assistant gateway**. You run
a single **Gateway** process on your own machine (or a VPS); it bridges the messaging apps you already use
(WhatsApp, Telegram, Discord, Signal, iMessage, Slack, and ~29 channels total) to an always-available AI agent
with tool use, persistent memory, skills, and scheduled/proactive autonomy. Tagline: *"Your own personal AI
assistant. Any OS. Any Platform. The lobster way."* [github.com/openclaw/openclaw](https://github.com/openclaw/openclaw),
[docs/index.md](https://github.com/openclaw/openclaw/blob/main/docs/index.md), [openclaw.ai](https://openclaw.ai)

**History / renames** (naming lineage matters for search — several predecessor names still circulate):
- Started as an experiment called **"WhatsApp Relay"** (late 2025). [openclaw.ai/blog/introducing-openclaw](https://openclaw.ai/blog/introducing-openclaw)
- Released publicly as **Clawdbot** on **2025-11-24**. [masterconcept.ai](https://masterconcept.ai/blog/what-is-openclaw-and-why-is-it-trending), [SamurAIGPT/awesome-openclaw](https://github.com/SamurAIGPT/awesome-openclaw)
- Renamed **Moltbot**, then to **OpenClaw** on **2026-01-30**. [masterconcept.ai](https://masterconcept.ai/blog/what-is-openclaw-and-why-is-it-trending)
- Nickname/mascot: **"Molty"** (a lobster). [digitalocean.com](https://www.digitalocean.com/resources/articles/what-is-openclaw)

**Maintainer.** Created by **Peter Steinberger** (Austrian developer, founder of PSPDFKit; reported to have
since joined OpenAI). Now community-driven with a large contributor base. [digitalocean.com](https://www.digitalocean.com/resources/articles/what-is-openclaw), [masterconcept.ai](https://masterconcept.ai/blog/what-is-openclaw-and-why-is-it-trending)

**License.** **MIT** — stated in `docs/index.md` ("Open source: MIT licensed, community-driven"). [docs/index.md](https://github.com/openclaw/openclaw/blob/main/docs/index.md) (root `LICENSE` file present in repo tree)

**Language / runtime.** **TypeScript (~91.8%)** with Swift (~3.4%, iOS/macOS apps), JavaScript, Kotlin
(~1.1%, Android), Shell, CSS. Organized as a **pnpm monorepo** (`packages/`, `src/`, `extensions/`, `apps/`,
`skills/`, `ui/`). Runs on **Node 24 (recommended) or Node 22.19+ LTS**. Distributed via npm
(`npm i -g openclaw`) with a Docker image and one-line installer. [github.com/openclaw/openclaw (languages panel)](https://github.com/openclaw/openclaw), [linkstartai.com](https://www.linkstartai.com/en/github-picks/openclaw), [docs/index.md](https://github.com/openclaw/openclaw/blob/main/docs/index.md)

**Current version.** npm `openclaw@2026.6.11` is the latest published release as of mid-2026; date-based
version scheme `YYYY.M.DD`; stable/beta/dev release channels. [npmjs.com/package/openclaw](https://www.npmjs.com/package/openclaw?activeTab=versions), [github.com/openclaw/openclaw/releases](https://github.com/openclaw/openclaw/releases)

**Activity level.** Extremely high. Early retrospective recorded ~6,933 commits in the first ~68 days
(~102 commits/day). Rapid, near-daily release cadence continues through 2026. See §6 for scale. [nathanowen.substack.com](https://nathanowen.substack.com/p/openclaws-clawdbot150k-github-stars)

---

## 2. Architecture

Verified primarily from `docs/agent-runtime-architecture.md`, `docs/concepts/*`, README, and `SECURITY.md`.

### 2.1 Gateway / agent model
- **The Gateway is the control plane** — "single source of truth for sessions, routing, and channel
  connections." It is local-first and owns all session state. The *product* is the assistant; the Gateway is
  just the bus. Runs as a daemon (launchd/systemd user service via `openclaw onboard --install-daemon`).
  [README](https://github.com/openclaw/openclaw/blob/main/README.md), [docs/index.md](https://github.com/openclaw/openclaw/blob/main/docs/index.md)
- **Topology:** `Chat apps + plugins → Gateway → { OpenClaw agent, CLI, Web Control UI, macOS app, iOS/Android nodes }`. [docs/index.md](https://github.com/openclaw/openclaw/blob/main/docs/index.md)
- **Multi-agent routing:** inbound channels/accounts/peers route to **isolated agents** (each with its own
  workspace + per-agent sessions). [README](https://github.com/openclaw/openclaw/blob/main/README.md)

### 2.2 Session model
- A **session** is a persistent conversation context owned by the Gateway; inbound messages route to sessions
  by source. Mapping: **DMs → shared "main" session by default**; **group chats → isolated per group**;
  **rooms/channels → isolated per room**; **cron jobs → fresh session per run**; **webhooks → isolated per hook**.
  [docs/concepts/session.md](https://github.com/openclaw/openclaw/blob/main/docs/concepts/session.md)
- **DM isolation** for multi-user: `session.dmScope` = `per-peer | per-channel-peer (recommended) | per-account-channel-peer`.
- **Reset modes:** daily reset (default, at a configured local hour), idle reset, manual (`/new`, `/reset`);
  per-chat-type/per-channel overrides.
- **Persistence & concurrency:** transcripts written to session files under a **process-aware, file-based
  session write lock** (catches writers bypassing the in-process queue or from another process). Runs are
  **serialized via per-session and global queues**. [docs/concepts/agent-loop.md](https://github.com/openclaw/openclaw/blob/main/docs/concepts/agent-loop.md)

### 2.3 Agent loop
Five serialized stages per turn: **intake → context assembly → model inference → tool execution → persistence.**
The `agent` RPC returns `{runId, acceptedAt}` immediately; `runEmbeddedAgent` resolves model + auth profile,
builds the session, subscribes to runtime events, streams assistant/tool deltas, enforces a run timeout
(aborts on expiry), and returns payloads + usage metadata. **Auto-compaction** emits `compaction` stream
events and can trigger a retry (in-memory buffers + tool summaries reset to avoid duplicate output). System
prompt assembled from base prompt + skills context + bootstrap files (`AGENTS.md`, `SOUL.md`, `TOOLS.md`) +
per-turn overrides, under model-specific token limits. Turn ends via timeout, AbortSignal, gateway disconnect,
or natural completion. [docs/concepts/agent-loop.md](https://github.com/openclaw/openclaw/blob/main/docs/concepts/agent-loop.md)

Code layout (from `docs/agent-runtime-architecture.md`):
- `packages/agent-core/` (`@openclaw/agent-core`) — reusable agent loop, harness types, messages, compaction
  helpers, prompt templates, skills, **session storage contracts**.
- `src/agents/sessions/` — session persistence (`session-manager.ts`), resource discovery, in-session
  extension loading, prompt templates, skills.
- `src/agents/runtime/` — facade wiring `agent-core` to the plugin-SDK LLM runtime.
- `src/agents/agent-tools.ts` — tool definitions, schemas, **tool policy**, before/after tool-call adapters,
  host/sandbox edit tools.
- `src/agents/harness/` — harness registry, selection policy, lifecycle (built-in + plugin-registered harnesses).
- `src/llm/` + `src/llm/providers/` — **model/provider registry**, transport helpers, per-provider streaming.
  [docs/agent-runtime-architecture.md](https://github.com/openclaw/openclaw/blob/main/docs/agent-runtime-architecture.md)

### 2.4 Messaging channels (concrete list)
One Gateway serves every configured channel plugin simultaneously. Full enumerated set:
**WhatsApp, Telegram, Slack, Discord, Google Chat, Signal, iMessage, IRC, Microsoft Teams, Matrix, Feishu,
LINE, Mattermost, Nextcloud Talk, Nostr, Synology Chat, Tlon, Twitch, Zalo, Zalo Personal, WeChat, QQ,
WebChat** — plus macOS / iOS / Android node surfaces (~29 channels). Core channels ship built-in; the long
tail installs on demand as channel plugins. Media (images, audio, documents) flows both directions.
[README](https://github.com/openclaw/openclaw/blob/main/README.md), [docs/index.md](https://github.com/openclaw/openclaw/blob/main/docs/index.md)

### 2.5 Model-provider abstraction
Model-agnostic "bring your own key." Providers include **Anthropic (Claude), OpenAI (GPT/Codex), DeepSeek,
and local models via Ollama**. Config is `agent.model: "<provider>/<model-id>"`; supports **auth-profile
rotation and model failover/fallbacks**. Registry lives in `src/llm/providers/`. [README](https://github.com/openclaw/openclaw/blob/main/README.md), [masterconcept.ai](https://masterconcept.ai/blog/what-is-openclaw-and-why-is-it-trending)

### 2.6 Memory / state persistence
- **No hidden state — only what's written to disk persists.** Workspace default `~/.openclaw/workspace`.
- **Two-tier Markdown memory:** `MEMORY.md` (compact, curated durable facts/preferences/decisions, injected
  into every session bootstrap) + `memory/YYYY-MM-DD.md` daily notes (working layer, indexed for search, not
  auto-injected); optional `DREAMS.md` summaries. Agents distill daily notes into long-term memory over time.
- **Retrieval:** `memory_search` (hybrid **vector similarity + keyword**) and `memory_get` (file/line ranges).
  Default backend **SQLite with optional vector embeddings** (OpenAI/Gemini/local).
- **Scope:** memory is per-agent (can be agent-agnostic); "commitments" (short-lived follow-ups) scope to the
  same agent+channel; scheduled tasks carry exact timing. [docs/concepts/memory.md](https://github.com/openclaw/openclaw/blob/main/docs/concepts/memory.md)
- Config lives at `~/.openclaw/openclaw.json`; per-conversation state in isolated SQLite + Markdown logs. [linkstartai.com](https://www.linkstartai.com/en/github-picks/openclaw)

### 2.7 Skills / plugins / extensions
- **Skill** = a directory with a `SKILL.md` (YAML frontmatter — min `name`+`description`; optional
  `user-invocable`, `command-dispatch`, gating on binary/env/config — plus a Markdown body of instructions
  "teaching the agent how and when to use tools"). Skills live at `~/.openclaw/workspace/skills/<skill>/SKILL.md`.
- **Loading:** precedence-based across **six sources** (workspace skills highest, bundled lowest); discovered
  by locating `SKILL.md` up to 6 levels deep; can be published from connected **nodes** (visible only while
  the node is connected).
- **ClawHub** = public skills registry: `openclaw skills install @owner/<slug>` (`--global` for system-wide);
  installs from Git repos / local dirs; **security-scanned before install** against trust envelopes in
  `.clawhub/origin.json`. Every ClawHub skill ships a **Skill Card** and is scanned by **SkillSpector** for
  hidden instructions. [openclaw.ai](https://openclaw.ai)
- **Agent-authored skills:** the agent does NOT write skills directly — it drafts proposals via the **Skill
  Workshop**; a human reviews/approves before they take effect.
- **Plugins vs extensions vs MCP:** plugins can ship their own skills (`openclaw.plugin.json`) and load
  **in-process** at low precedence; extensions load per-session; MCP tools are exposed as first-class tools.
  [docs/tools/skills.md](https://github.com/openclaw/openclaw/blob/main/docs/tools/skills.md), [docs/tools/creating-skills.md](https://github.com/openclaw/openclaw/blob/main/docs/tools/creating-skills.md)

### 2.8 Cron / scheduled tasks, webhooks, proactive agency
- **Cron jobs** run the agent proactively on a schedule — **each run gets a fresh isolated session**.
- **Webhooks** trigger agent runs — **each hook gets an isolated session**. Gmail Pub/Sub push is a
  documented integration.
- System **heartbeats** don't extend session-reset freshness (predictable boundaries for scheduled runs).
  This is the mechanism behind "works while you sleep" proactive automation. [docs/concepts/session.md](https://github.com/openclaw/openclaw/blob/main/docs/concepts/session.md), [README](https://github.com/openclaw/openclaw/blob/main/README.md), [digitalocean.com](https://www.digitalocean.com/resources/articles/what-is-openclaw)

### 2.9 First-class tools & surfaces
Built-in tools: **browser** (control/automation, form-fill, scrape), **canvas** (agent-driven visual
workspace via A2UI), **nodes** (device bridges), **cron**, **sessions** (list/history/send/spawn — the
multi-agent primitive), and channel actions (Discord/Slack). **Voice:** wake words on macOS/iOS + continuous
"Talk Mode" on Android (ElevenLabs + system TTS fallback). **Companion apps:** Windows Hub, macOS menu-bar
app, iOS/Android nodes (Canvas, camera, voice). Full system access: read/write files, run shell commands,
execute scripts — full or sandboxed. [README](https://github.com/openclaw/openclaw/blob/main/README.md), [openclaw.ai](https://openclaw.ai)

### 2.10 Local-first vs hosted posture
**Local-first by design.** Runs on Mac/Windows/Linux; state lives on the user's machine, not a vendor cloud;
BYO keys or fully local models. Can be deployed to a VPS for 24/7 availability; remote access via **Tailscale**
/ Web surfaces (explicitly *not* hardened for public exposure — loopback-only recommended). [openclaw.ai](https://openclaw.ai), [linkstartai.com](https://www.linkstartai.com/en/github-picks/openclaw), [README](https://github.com/openclaw/openclaw/blob/main/README.md)

---

## 3. Capability Inventory

### 3.1 User-facing capabilities (what a clone must do)
1. Chat with an AI agent from **any of ~29 messaging channels** (DMs + group chats), with media in/out.
2. **Persistent, resumable conversations** — pick up context days later; daily/idle/manual reset controls.
3. **Long-horizon personal memory** — remembers preferences, projects, people across sessions.
4. **Proactive autonomy** — scheduled cron tasks and webhook-triggered runs act without a prompt ("while you sleep").
5. **Tool-driven real-world actions** — send emails, manage calendar/inbox, control smart home (Hue/Home
   Assistant), manage notes/tasks (Obsidian/Notion/Things/Reminders), browser automation, GitHub/DevOps workflows.
6. **Skills ecosystem** — install community skills from ClawHub; agent proposes new skills via Skill Workshop.
7. **Voice** — wake-word + talk mode on device nodes.
8. **Live Canvas** — agent-rendered visual workspace the user controls.
9. **Multi-agent "army"** — route different channels/peers to isolated agents; spawn sub-sessions.
10. **Web Control UI + CLI** — dashboard for chat/config/sessions/nodes; `openclaw agent`, `message send`, etc.

### 3.2 Infrastructure capabilities beneath them
- **Session persistence & routing** (Gateway-owned, file-locked, queue-serialized).
- **Channel adapters** (per-protocol plugins: Baileys/WhatsApp, Telegram bot API, signal-cli, iMessage bridge, etc.).
- **Tool execution engine** with **tool policy** + host/sandbox edit tools + before/after adapters + exec approvals.
- **Model/provider registry** with auth-profile rotation + failover.
- **Memory store**: Markdown files + SQLite + optional vector embeddings + hybrid search.
- **Scheduler** for cron + heartbeats; **webhook ingress** server.
- **Skill/plugin loader** (6-source precedence, `SKILL.md` discovery, ClawHub install + security scan).
- **Device/node bridges** (macOS/iOS/Android nodes for canvas/camera/voice; Windows Hub).
- **Sandboxing backends** (Docker default; SSH, OpenShell).
- **Streaming runtime** (assistant/tool deltas, compaction events, usage metadata).

---

## 4. Security Posture & Known Criticisms

Verified from `SECURITY.md` (fetched) and README security section. **A pregolya-based clone must learn from these.**

- **Threat model = single trusted operator, NOT multi-tenant.** "OpenClaw does **not** model one gateway as
  a multi-tenant, adversarial user boundary." Authenticated callers (shared-secret bearer) get **full operator
  scope** regardless of declared narrower scopes; session IDs are **routing controls, not authorization boundaries**.
- **Prompt injection is explicitly out of scope as a "vulnerability."** The model is "not a trusted principal —
  assume prompt/content injection can manipulate behavior." Security derives from host/config trust, auth, tool
  policy, sandboxing, and exec approvals — **not** prompt isolation. **Indirect prompt injection (malicious
  instructions hidden in an email/webpage the agent reads) is not natively solved**; the recommended defense is
  strict isolation + non-privileged credentials. [SECURITY.md](https://github.com/openclaw/openclaw/blob/main/SECURITY.md)
- **Host-first execution by default.** `sandbox.mode` defaults `off`; `tools.exec.host` defaults `auto`. The
  `main` session runs tools on the host with **full access**. Sandboxing (`non-main`/`all`, Docker/SSH/OpenShell)
  is opt-in. Typical non-`main` sandbox allows `bash/process/read/write/edit/sessions_*`, denies
  `browser/canvas/nodes/cron/discord/gateway`.
- **DM pairing** is the front-line control: unknown senders on Telegram/WhatsApp/Signal/iMessage/Teams/Discord/
  Google Chat/Slack get a pairing code and their message is **not processed** until paired. [README](https://github.com/openclaw/openclaw/blob/main/README.md)
- **Plugins load in-process** with the same OS privileges as the process — not a sandbox boundary.
- **`MEMORY.md`/`memory/*.md` are trusted operator state** — memory search over them is expected, not a boundary
  (⇒ a memory-poisoning vector if an attacker can write memory).
- **Gateway is not hardened for public exposure** — loopback-only recommended; remote via Tailscale. Non-local
  setups are flagged dangerous by the project's own audits but permitted as operator-chosen tradeoffs.
- **Credential handling:** only OpenClaw-operated-infra secrets are in-scope for vuln reports; secret detection
  via pre-commit + CI (`detect-private-key`). User/third-party creds are the operator's responsibility.
- **Public criticism themes** (secondary sources, flag as opinion): "full system access = large blast radius,"
  "self-improving/AGI-like" hype, and enterprise-safety concerns driving hardened variants (DigitalOcean 1-Click
  hardened image; NVIDIA NemoClaw / NanoClaw / ZeroClaw enterprise forks; the `composio-community/secure-openclaw`
  reference). [digitalocean.com](https://www.digitalocean.com/resources/articles/what-is-openclaw), [masterconcept.ai](https://masterconcept.ai/blog/what-is-openclaw-and-why-is-it-trending), [github.com/composio-community/secure-openclaw](https://github.com/composiohq/secure-openclaw)

**Design lesson for pregolya:** treat all channel ingress as untrusted; make tool/exec policy and sandboxing
**default-on** for non-owner sessions; model session identity as auth, not just routing; and provide a
first-class isolation story (the opposite of OpenClaw's host-first default).

---

## 5. What an OpenClaw-like Clone Demands From an Agent Framework

Capability → framework-primitive mapping, then coverage against pregolya's **planned** surface
(langgraph runtime `pregolya-graph` + langchain agents `pregolya-core` + `pregolya-mcp` + `pregolya-server`,
per D7/D11/D13). Legend: **[COVERED]** planned surface plausibly satisfies it · **[PARTIAL]** foundation exists,
gap remains · **[NEW]** net-new surface not in current plan.

| # | OpenClaw capability | Framework primitive demanded | pregolya coverage |
|---|---------------------|------------------------------|---------------------|
| 1 | Persistent, resumable, multi-day sessions | Durable checkpointing + resume across process restarts | **[COVERED]** — `pregolya-graph` durable checkpointing (D7 P0), msgpack checkpoints + sync-default durability (D11.2/D11.3); `pregolya-server` threads/runs (D13) |
| 2 | Cross-session long-horizon personal memory | Long-horizon store (KV + vector) separate from checkpoints | **[PARTIAL]** — `pregolya-server` has a `store` (D13) analogous to LangGraph Store; but OpenClaw's **Markdown-file + SQLite + hybrid vector/keyword** memory model and MEMORY.md distillation loop are **[NEW]** application-layer surface |
| 3 | Multi-channel ingress (WhatsApp/TG/Discord/iMessage/…) | Pluggable **ingress/channel adapters** + normalized inbound event model | **[NEW]** — no channel-adapter layer in the langchain/langgraph corpus; entirely new surface a clone must build atop pregolya |
| 4 | Proactive cron + webhook agency | **Scheduler** (cron) firing fresh runs + webhook ingress → run trigger | **[PARTIAL]** — `pregolya-server` includes **crons** (D13) and streaming runs; "fresh session per cron run / per webhook" semantics + heartbeat model are design details to specify. Webhook→run ingress is largely **[NEW]** |
| 5 | Skills / plugins / MCP tool ecosystem | **Tool/plugin registry** + dynamic discovery + MCP client | **[PARTIAL]** — `pregolya-mcp` (D1) covers MCP tools; langchain tool abstractions cover tool calling; but `SKILL.md`-style markdown skills, 6-source precedence loading, and a **ClawHub-like registry + security scan** are **[NEW]** |
| 6 | Multi-agent routing / sub-agent spawning | Hierarchical/graph orchestration + sub-graph/session spawn | **[COVERED]** — langgraph subgraphs + `sessions_spawn`-equivalent map cleanly onto `pregolya-graph`; D8 already lists hierarchical delegation + parallel fan-out |
| 7 | Human-approval interrupts (exec approvals, pairing) | **Interrupt / human-in-the-loop** mid-run + resume | **[COVERED]** — langgraph `interrupt` + checkpoint/resume (D8 lists human-approval interrupts explicitly) |
| 8 | Model-agnostic provider abstraction + failover | Provider registry, auth-profile rotation, fallback | **[COVERED]** — `pregolya-openai`/`-anthropic`/`-ollama` (D3) + chat-model abstraction; failover/rotation is a thin layer to add |
| 9 | Tool-execution sandboxing (Docker/SSH/OpenShell) | Sandboxed tool-exec backends + tool policy engine | **[NEW]** — langchain has no exec-sandbox layer; pregolya must decide policy (recommend default-on isolation, §4 lesson) |
| 10 | Local-first single-binary deployment | Self-contained runtime, embedded persistence, daemon mode | **[PARTIAL→ADVANTAGE]** — Rust single-binary + embedded store is a **natural pregolya strength** vs OpenClaw's Node+pnpm footprint; but a "one binary that is the whole gateway" packaging target is **[NEW]** product surface |
| 11 | Streaming (assistant/tool deltas, compaction, usage) | Streaming runtime + token/usage accounting | **[COVERED]** — `pregolya-server` streaming (D13) + langgraph stream modes |
| 12 | Voice + Canvas + device nodes | Real-time audio I/O, A2UI surface, device bridge protocol | **[NEW]** — entirely outside the langchain/langgraph corpus; net-new if a clone targets parity |
| 13 | Structured triage/verdict outputs | Structured output / schema-constrained generation | **[COVERED]** — langchain structured output (also demanded by Domains A/B) |

**Net:** the **durable-run + graph + interrupt + streaming + MCP + structured-output** core is **covered** by
pregolya's planned surface (and is precisely the P0 differentiator per D7). The **new surface** Domain C
uniquely forces — not surfaced by Domains A (SOC analyst) or B (dark factory) — is: **(a)** channel/ingress
adapters, **(b)** webhook→run + proactive scheduling ergonomics, **(c)** a file+vector long-horizon personal
memory model with distillation, **(d)** a skill/plugin registry with markdown skills + security scanning,
**(e)** tool-exec sandboxing + policy, **(f)** local-first single-binary packaging, **(g)** voice/canvas/node
bridges (optional parity).

---

## 6. Scale Reference

OpenClaw is a **large, fast-moving TypeScript monorepo** and one of the most-starred software projects on GitHub.

| Metric | Value | Source / date | Confidence |
|--------|-------|---------------|------------|
| GitHub stars | **~250,000+** (milestones: 100k late-2025 → 145–150k Feb-2026 → 250k+ by Mar-2026; some sources cite 351k+) | [star-history.com](https://www.star-history.com/blog/openclaw-surpasses-react-most-starred-software), [petronellatech](https://petronellatech.com/blog/openclaw-ai-agent-guide-2026/), [masterconcept](https://masterconcept.ai/blog/what-is-openclaw-and-why-is-it-trending) | **medium — sources conflict** |
| Forks | ~20,000–34,000+ | [getopenclaw.ai](https://www.getopenclaw.ai/blog/openclaw-github), [testmuai](https://www.testmuai.com/blog/openclaw-github-repository/) | medium |
| Contributors | GitHub panel ~2,306; project-reported 300+ (definition-dependent) | [github.com/openclaw/openclaw](https://github.com/openclaw/openclaw) | medium |
| Commits | 6,933 at ~68 days (~Feb-2026); higher since, exact unknown | [nathanowen.substack.com](https://nathanowen.substack.com/p/openclaws-clawdbot150k-github-stars) | low (stale) |
| Languages | TypeScript 91.8%, Swift 3.4%, JS 2.3%, Kotlin 1.1%, Shell 0.8%, CSS 0.4% | [github.com/openclaw/openclaw](https://github.com/openclaw/openclaw) | high |
| Bundled skills | 40+ (repo) / 100+ (preconfigured) / 44,000+ community on ClawHub | [clawtrust.ai](https://clawtrust.ai/blog/openclaw-github-skills), [digitalocean](https://www.digitalocean.com/resources/articles/what-is-openclaw), [masterconcept](https://masterconcept.ai/blog/what-is-openclaw-and-why-is-it-trending) | medium |
| Docker image / disk | ~2–3 GB image; 5–8 GB running on a VPS | [clawtrust.ai](https://clawtrust.ai/blog/openclaw-github-skills) | low (secondary) |
| Reported MAU | ~3.2M monthly active users (secondary claim) | [masterconcept](https://masterconcept.ai/blog/what-is-openclaw-and-why-is-it-trending) | low (unverified) |

**Flag:** Star/fork/MAU figures vary widely across secondary sources and grew rapidly month-over-month;
treat as **order-of-magnitude** ("hundreds of thousands of stars, large TS monorepo, thousands of commits,
tens of thousands of community skills"). Repo-panel numbers (languages, contributor count) are highest-confidence;
promotional-blog numbers (351k stars, 38M visitors, 3.2M MAU) are lowest-confidence and unverified against a
primary counter.

---

## 7. Capability Checklist — Phase-1 Forcing-Function Input

> One-page, drop-in checklist. Each item is a workload the pregolya PRD/architecture must demonstrate is
> supportable. **[CORE]** = covered by planned surface; **[NEW]** = net-new surface Domain C forces;
> **[SEC]** = security requirement derived from OpenClaw's documented posture.

**Durable session & run core**
- [ ] **[CORE]** 24/7 persistent, resumable sessions that survive process restarts (checkpoint/resume).
- [ ] **[CORE]** Per-source session isolation (DM/main, per-group, per-room, per-cron-run, per-webhook).
- [ ] **[CORE]** Configurable session reset (daily/idle/manual) with per-channel/per-chat-type overrides.
- [ ] **[CORE]** Serialized run execution (per-session + global queues) with run timeout + abort.
- [ ] **[CORE]** Streaming of assistant/tool deltas + compaction events + usage/token accounting.
- [ ] **[CORE]** Auto-compaction / context management with safe retry.

**Multi-agent & control flow**
- [ ] **[CORE]** Route inbound peers/channels/accounts to isolated agents (workspaces + per-agent sessions).
- [ ] **[CORE]** Sub-agent / sub-session spawn + hierarchical delegation + parallel fan-out.
- [ ] **[CORE]** Human-approval interrupts mid-run (exec approval, pairing) with resume.
- [ ] **[CORE]** Quality-gate conditional routing; structured outputs.

**Ingress & proactivity**
- [ ] **[NEW]** Pluggable channel/ingress adapters with a normalized inbound event model (≥ WhatsApp, Telegram,
      Discord, Signal, iMessage, Slack, WebChat as reference set).
- [ ] **[NEW]** Webhook ingress that triggers an isolated agent run per hook.
- [ ] **[CORE/PARTIAL]** Cron/scheduled proactive runs (fresh session per run) + heartbeat model.

**Memory & knowledge**
- [ ] **[PARTIAL]** Long-horizon cross-session store (KV + vector) decoupled from checkpoints.
- [ ] **[NEW]** File-backed durable memory (curated long-term + dated working notes) with distillation loop.
- [ ] **[NEW]** Hybrid memory retrieval (vector similarity + keyword) with pluggable embedding backends.

**Tools, skills & extensibility**
- [ ] **[CORE]** MCP tool integration (client) + first-class tool registry with schemas + tool policy.
- [ ] **[NEW]** Skill packaging format (markdown instruction + metadata) with precedence-based discovery.
- [ ] **[NEW]** Skill/plugin registry install path with pre-install security scanning + provenance/trust envelope.
- [ ] **[CORE]** Model-provider abstraction with auth-profile rotation + failover across providers (incl. local/Ollama).

**Deployment & isolation**
- [ ] **[PARTIAL/NEW]** Local-first single-binary/daemon deployment; embedded persistence; runs on Mac/Win/Linux + VPS.
- [ ] **[NEW]** Tool-execution sandboxing backends (container/remote) with per-session sandbox policy.

**Security (derived from OpenClaw's documented gaps — pregolya should exceed, not copy, its defaults)**
- [ ] **[SEC]** Treat all channel ingress as untrusted input; unknown-sender gating/pairing before processing.
- [ ] **[SEC]** Session identity as an **authorization** boundary (not merely routing) for multi-user gateways.
- [ ] **[SEC]** Default-on isolation/tool-policy for non-owner sessions (opposite of OpenClaw's host-first default).
- [ ] **[SEC]** Credential newtypes / redacted debug for provider + channel secrets (aligns with CLAUDE.md D10).
- [ ] **[SEC]** Documented stance on indirect prompt injection + memory-poisoning (writable-memory attack surface).

---

## Sources (primary first)
- **Primary — repo/docs:** [github.com/openclaw/openclaw](https://github.com/openclaw/openclaw) · [README](https://github.com/openclaw/openclaw/blob/main/README.md) · [docs/index.md](https://github.com/openclaw/openclaw/blob/main/docs/index.md) · [docs/agent-runtime-architecture.md](https://github.com/openclaw/openclaw/blob/main/docs/agent-runtime-architecture.md) · [docs/concepts/agent-loop.md](https://github.com/openclaw/openclaw/blob/main/docs/concepts/agent-loop.md) · [docs/concepts/memory.md](https://github.com/openclaw/openclaw/blob/main/docs/concepts/memory.md) · [docs/concepts/session.md](https://github.com/openclaw/openclaw/blob/main/docs/concepts/session.md) · [docs/tools/skills.md](https://github.com/openclaw/openclaw/blob/main/docs/tools/skills.md) · [SECURITY.md](https://github.com/openclaw/openclaw/blob/main/SECURITY.md) · [openclaw.ai](https://openclaw.ai) · [npm openclaw](https://www.npmjs.com/package/openclaw?activeTab=versions)
- **Secondary — context/scale (lower confidence):** [digitalocean.com](https://www.digitalocean.com/resources/articles/what-is-openclaw) · [masterconcept.ai](https://masterconcept.ai/blog/what-is-openclaw-and-why-is-it-trending) · [linkstartai.com](https://www.linkstartai.com/en/github-picks/openclaw) · [star-history.com](https://www.star-history.com/blog/openclaw-surpasses-react-most-starred-software) · [nathanowen.substack.com](https://nathanowen.substack.com/p/openclaws-clawdbot150k-github-stars) · [clawtrust.ai](https://clawtrust.ai/blog/openclaw-github-skills) · [SamurAIGPT/awesome-openclaw](https://github.com/SamurAIGPT/awesome-openclaw) · [composio-community/secure-openclaw](https://github.com/composiohq/secure-openclaw)

---

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| **Perplexity perplexity_research (PRIMARY)** | 1 | Deep identity discovery — disambiguate OpenClaw (AI assistant) from Captain Claw game; establish project, maintainer, license, runtime (reasoning_effort=high; output exceeded token cap, mined via Grep) |
| Perplexity perplexity_ask | 1 | Verified scale/version lookup — npm latest version, stars/forks/contributors/commits, language breakdown, with conflict enumeration |
| Perplexity perplexity_search | 0 | — |
| Perplexity perplexity_reason | 0 | — |
| Context7 | 0 | Not applicable — OpenClaw is not a library with API docs to query; primary GitHub docs used directly |
| Tavily tavily_search | 1 | Initial identification of OpenClaw project + related repos |
| Tavily tavily_extract | 3 | Extract README, docs/index.md, agent-runtime-architecture.md (primary source verification) |
| Tavily tavily_map | 3 | Map docs/, docs/concepts/, docs/tools/ to find real doc filenames (initial guessed paths 404'd) |
| WebFetch | 4 | Fetch raw SECURITY.md, agent-loop.md, memory.md, skills.md (primary-source security + subsystem detail) |
| WebSearch | 1 | Corroborate identity + gather GitHub/related-repo URLs |
| Training data | 1 area | pregolya planned-surface mapping (§5) uses knowledge of langgraph/langchain primitives; grounded in project's own D7/D8/D11/D13 decisions read from .factory/STATE.md |

**Total MCP tool calls:** 13 (2 Perplexity + 7 Tavily + also 4 WebFetch/1 WebSearch native tools)
**Training data reliance:** low — every factual claim about OpenClaw is sourced to the primary repo/docs or a
cited secondary source. The only training-data input is general knowledge of langgraph/langchain primitives used
to map capabilities, and that mapping is anchored to pregolya's own decision log (D7/D8/D11/D13). Scale numbers
(§6) are flagged medium/low confidence due to conflicting secondary sources; the primary GitHub repo-panel figures
(languages, contributor count) and npm version are highest confidence.
