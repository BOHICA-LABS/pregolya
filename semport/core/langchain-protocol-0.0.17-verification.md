# langchain-protocol 0.0.17 — Schema Verification (Pass-7 follow-up)

**Date:** 2026-07-12
**Task:** Obtain and verify the canonical `langchain-protocol` 0.0.17 wire schema; diff the
`MessagesData` content-block subset against the 0.0.15-based subset documented in Pass 7.
**Verdict (headline):** **CHANGED — but the change is a single additive, backward-compatible
expansion of `UsageInfo` (nested inside `MessageFinishData`). All six MessagesData event
envelopes and all content-block union types are IDENTICAL to 0.0.15.**

---

## 1. Canonical source — VERIFIED

| Item | Finding | Source |
|------|---------|--------|
| Repo | `github.com/langchain-ai/agent-protocol` — **CONFIRMED correct** | [repo](https://github.com/langchain-ai/agent-protocol) |
| Schema location | `streaming/protocol.cddl` (CDDL wire-schema; the tree-map found exactly `streaming/README.md` + `streaming/protocol.cddl`) | [streaming tree](https://github.com/langchain-ai/agent-protocol/tree/main/streaming) |
| Python package | `langchain-protocol` on PyPI — "Python bindings for the LangChain agent streaming protocol", dep `typing-extensions`, License MIT. Confirmed `protocol.py` is `cddl2py`-generated, so the `.cddl` is canonical (per Pass 7 dependency-disposition:223). | [PyPI stats](https://pypistats.org/packages/langchain-protocol), [piwheels](https://www.piwheels.org/project/langchain-protocol/) |
| 0.0.17 release | **FOUND.** PyPI/piwheels: 0.0.17 published **2026-06-12** (wheel 7 KB). Git tag `langchain-protocol==0.0.17` exists = **Merge PR #87**, release note *"added token-detail breakdowns to UsageInfo"*. | [piwheels](https://www.piwheels.org/project/langchain-protocol/), [tags](https://github.com/langchain-ai/agent-protocol/tags), [PR #87](https://github.com/langchain-ai/agent-protocol/pull/87/files) |
| 0.0.15 baseline | Git tag `langchain-protocol==0.0.15` (2026-05-01). This is the version Pass 7 physically inspected (OrbStack site-packages copy). | [tags](https://github.com/langchain-ai/agent-protocol/tags) |
| License | **MIT** — "Copyright (c) 2024 LangChain, Inc." | [LICENSE@0.0.17](https://raw.githubusercontent.com/langchain-ai/agent-protocol/langchain-protocol==0.0.17/LICENSE) |

**Tag naming note:** tags are literally named `langchain-protocol==0.0.17` (with the `==`). The
raw-content URLs resolve at
`https://raw.githubusercontent.com/langchain-ai/agent-protocol/langchain-protocol==0.0.17/streaming/protocol.cddl`
(and the `==0.0.15` equivalent). Both resolved successfully, so the exact 0.0.17 tag is **findable**
— no gap/fallback was needed. Latest release is 0.0.18 (2026-06-18, PR #89); the pin in the
langchain clone is `langchain-protocol>=0.0.17` (a floor, not `==`).

---

## 2. Fetched schema — MessagesData subset @ 0.0.17

Verbatim from `streaming/protocol.cddl` at tag `langchain-protocol==0.0.17`:

```cddl
MessagesData = MessageStartData
             / ContentBlockStartData
             / ContentBlockDeltaData
             / ContentBlockFinishData
             / MessageFinishData
             / MessageErrorData

MessageStartData = {
  event: "message-start",
  role: MessageRole,          ; MessageRole = "ai" / "human" / "system"
  id: text,
  ? metadata: MessageMetadata,
  Extensible,
}

ContentBlockStartData = {
  event: "content-block-start",
  index: uint,
  content: ContentBlock,
  Extensible,
}

ContentBlockDeltaData = {
  event: "content-block-delta",
  index: uint,
  delta: ContentBlockDelta,
  Extensible,
}

ContentBlockFinishData = {
  event: "content-block-finish",
  index: uint,
  content: FinalizedContentBlock,
  Extensible,
}

MessageFinishData = {
  event: "message-finish",
  ? usage: UsageInfo,
  Extensible,
}

MessageErrorData = {
  event: "error",
  message: text,
  ? code: text,
  Extensible,
}

ContentBlock = TextContentBlock / InvalidToolCall / ReasoningContentBlock
             / NonStandardContentBlock / DataContentBlock / ToolContentBlock

FinalizedContentBlock = TextContentBlock / ReasoningContentBlock / ToolCall
                      / InvalidToolCall / ServerToolCall / ServerToolResult
                      / DataContentBlock / NonStandardContentBlock

ContentBlockDelta = TextDelta / ReasoningDelta / DataDelta / BlockDelta

MessageMetadata = {
  ? provider: text, ? model: text, ? modelType: text, ? runId: text,
  ? threadId: text, ? systemFingerprint: text, ? serviceTier: text,
  * text => MetadataScalar,
}

; ---- CHANGED in 0.0.17 (see §3) ----
UsageInfo = {
  ? inputTokens: uint,
  ? outputTokens: uint,
  ? totalTokens: uint,
  ? inputTokenDetails: InputTokenDetails,     ; NEW in 0.0.17
  ? outputTokenDetails: OutputTokenDetails,   ; NEW in 0.0.17
  Extensible,
}

InputTokenDetails = {                          ; NEW TYPE in 0.0.17
  ? audio: uint, ? cacheCreation: uint, ? cacheRead: uint, Extensible,
}

OutputTokenDetails = {                         ; NEW TYPE in 0.0.17
  ? audio: uint, ? reasoning: uint, Extensible,
}
```

---

## 3. DIFF — 0.0.17 vs documented 0.0.15 subset

**Method:** fetched both `==0.0.17` and `==0.0.15` tagged `protocol.cddl`, and independently
cross-checked against the PR #87 file diff and the release note. Four corroborating sources
(see Confidence).

| Type in MessagesData subset | 0.0.15 | 0.0.17 | Verdict |
|-----------------------------|--------|--------|---------|
| `MessagesData` union (6 variants) | same | same | **IDENTICAL** |
| `MessageStartData` (event/role/id/?metadata/Extensible) | same | same | **IDENTICAL** |
| `ContentBlockStartData` (event/index/content/Extensible) | same | same | **IDENTICAL** |
| `ContentBlockDeltaData` (event/index/delta/Extensible) | same | same | **IDENTICAL** |
| `ContentBlockFinishData` (event/index/content/Extensible) | same | same | **IDENTICAL** |
| `MessageFinishData` (event/?usage/Extensible) | same | same **structurally** | **IDENTICAL** (envelope unchanged; nested `UsageInfo` gained fields — see below) |
| `MessageErrorData` (event="error"/message/?code/Extensible) | same | same | **IDENTICAL** |
| `MessageRole` (`"ai"/"human"/"system"`) | same | same | **IDENTICAL** |
| `MessageMetadata` (7 opt fields + open map) | same | same | **IDENTICAL** |
| `ContentBlock` union (6 variants) | same | same | **IDENTICAL** |
| `FinalizedContentBlock` union (8 variants) | same | same | **IDENTICAL** |
| `ContentBlockDelta` union (4 variants) | same | same | **IDENTICAL** |
| **`UsageInfo`** | `inputTokens?`, `outputTokens?`, `totalTokens?`, `Extensible` | **+ `inputTokenDetails?: InputTokenDetails`**, **+ `outputTokenDetails?: OutputTokenDetails`** | **CHANGED (additive)** |
| **`InputTokenDetails`** | *did not exist* | `{ audio? , cacheCreation? , cacheRead? , Extensible }` | **CHANGED (new type)** |
| **`OutputTokenDetails`** | *did not exist* | `{ audio? , reasoning? , Extensible }` | **CHANGED (new type)** |

### Exact deltas (the only changes)

1. `UsageInfo` gained **two optional fields**: `inputTokenDetails: InputTokenDetails` and
   `outputTokenDetails: OutputTokenDetails`. The three pre-existing fields
   (`inputTokens`, `outputTokens`, `totalTokens`) are unchanged.
2. **Two new supporting types** introduced:
   - `InputTokenDetails = { ? audio: uint, ? cacheCreation: uint, ? cacheRead: uint, Extensible }`
   - `OutputTokenDetails = { ? audio: uint, ? reasoning: uint, Extensible }`

### Backward-compatibility assessment (important for the Rust port)

- The change is reachable from the MessagesData subset **only** via `MessageFinishData.usage`
  (which is itself optional).
- Both new fields are **optional**, and 0.0.15's `UsageInfo` was already `Extensible` (open map) —
  so a consumer built to the 0.0.15 shape **already tolerates** these keys as unknown extras.
  The change is **strictly additive / non-breaking** for a 0.0.15-modeled reader.
- **Content blocks proper (start/delta/finish, all three unions): ZERO changes.** The Pass-7
  concern area — the `ContentBlock` / `FinalizedContentBlock` / `ContentBlockDelta` unions — is
  **byte-for-byte IDENTICAL** between 0.0.15 and 0.0.17.

**Net verdict:** **CHANGED**, confined to token-usage accounting (`UsageInfo` + 2 new detail
types); **the message/content-block event envelopes and all content-block unions are IDENTICAL.**
For the Rust port, the only additional work vs the Pass-7 (0.0.15) model is adding two optional
`*TokenDetails` structs to the `UsageInfo` type.

---

## 4. Full-protocol top-level structure (for ADR-6, graph/server-layer decision)

Command/event channel inventory only (one line each), from `protocol.cddl@0.0.17`. **Note: none of
this beyond the `messages` channel is used by langchain-core today** (core imports only the
MessagesData subset at 6 sites — Pass 7). This inventory is forward-looking for ADR-6.

**Wire envelope (JSON-RPC-style framing):**
- `Command` — client→server request (numeric id + method).
- `CommandResponse` — server success reply (result payload).
- `ErrorResponse` — server error reply (code + message).
- `Event` — server→client push (optional event id + sequence for replay/reconnect).

**Command channel (client→server methods):**
- `run.start` — initiate or resume a graph execution with input.
- `subscription.subscribe` — register for the WebSocket event stream (WS only).
- `subscription.unsubscribe` — deregister from the event stream (WS only).
- `subscription.reconnect` — restore subscription state after a disconnect.
- `agent.getTree` — retrieve hierarchical agent/subgraph structure.
- `input.respond` — resume execution after an interrupt with a user response.
- `input.inject` — inject an unsolicited user message mid-execution.
- `state.get` — retrieve graph state for specified keys.
- `state.listCheckpoints` — list checkpoints for time-travel.
- `state.fork` — branch execution from a historical checkpoint.

**Event channels (server→client):**
- `lifecycle` (`LifecycleEvent`) — agent/subgraph status transitions and causation.
- `messages` (`MessagesEvent` → wraps `MessagesData`) — transcript + content-block lifecycle. **[ONLY channel core uses]**
- `tools` (`ToolsEvent`) — tool invocation start/output/finish/error.
- `input` (`InputEvent`) — human-in-the-loop interrupt requests.
- `values` (`ValuesEvent`) — complete graph-state snapshots per step.
- `updates` (`UpdatesEvent`) — per-node state deltas.
- `checkpoints` (`CheckpointsEvent`) — lightweight checkpoint metadata for time-travel UI.
- `custom` (`CustomEvent`) — user-defined application payloads (`custom:*` namespaces).
- `tasks` (`TasksEvent`) — Pregel task creation/result metadata.

---

## 5. Confidence & sourcing

**Confidence: HIGH** on the UsageInfo delta — four independent corroborating sources:
1. `protocol.cddl` @ tag `==0.0.17` shows `UsageInfo` **with** the two detail fields + both new types.
2. `protocol.cddl` @ tag `==0.0.15` shows `UsageInfo` **without** them (and no `*TokenDetails` types).
3. PR #87 file-diff independently shows exactly these additions and no other CDDL changes.
4. The 0.0.17 release note text: *"added token-detail breakdowns to UsageInfo."*

**Confidence: HIGH** on IDENTICAL for all other subset types — both tagged fetches returned the
same definitions verbatim.

**Caveat (LOW risk):** the `.cddl` bodies were retrieved via `WebFetch` (small-model extraction over
`raw.githubusercontent.com`), not a byte-diff. The four-way agreement above makes hallucination of
the delta implausible, but if a byte-exact record is later required, pull the two raw files directly
in CI and `diff` them. The 0.0.16→0.0.17 bump (PR #87) is the only release between 0.0.15 and 0.0.17
that touched the CDDL per the PR record; 0.0.16 introduced no MessagesData-subset changes found.

### Source URLs
- Repo / streaming tree: https://github.com/langchain-ai/agent-protocol/tree/main/streaming
- 0.0.17 CDDL: https://raw.githubusercontent.com/langchain-ai/agent-protocol/langchain-protocol==0.0.17/streaming/protocol.cddl
- 0.0.15 CDDL: https://raw.githubusercontent.com/langchain-ai/agent-protocol/langchain-protocol==0.0.15/streaming/protocol.cddl
- PR #87 (the 0.0.17 change): https://github.com/langchain-ai/agent-protocol/pull/87/files
- Tags: https://github.com/langchain-ai/agent-protocol/tags
- LICENSE @0.0.17: https://raw.githubusercontent.com/langchain-ai/agent-protocol/langchain-protocol==0.0.17/LICENSE
- PyPI: https://pypistats.org/packages/langchain-protocol ; https://www.piwheels.org/project/langchain-protocol/

---

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| **Perplexity perplexity_research (PRIMARY)** | 0 | Not used — task was a targeted schema fetch/diff against known repo, better served by direct raw-file retrieval than multi-source synthesis (deviation justified: exact CDDL byte content needed, not a synthesized overview). |
| Perplexity perplexity_search | 2 | Locate PyPI package, release dates, repo path, streaming channel names. |
| Tavily tavily_map | 1 | Map `streaming/` subdirectory to confirm `protocol.cddl` location. |
| WebFetch | 6 | Fetch `protocol.cddl` @ main / @0.0.17 / @0.0.15, PR #87 diff, tags page, LICENSE. |
| Read / Grep | 3 | Read Pass-7 documented 0.0.15 subset in behavioral-intent.md + dependency-disposition.md. |
| Training data | 0 areas | None relied upon — all findings web-verified against tagged sources. |

**Total MCP tool calls:** 3 (2 perplexity_search + 1 tavily_map). Plus 6 WebFetch (native).
**Training data reliance:** low — version numbers, schema bodies, license, and the delta were all
verified against the actual tagged repo files and PR diff; nothing taken from model memory.
