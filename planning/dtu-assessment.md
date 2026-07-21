---
document_type: dtu-assessment
level: L3
version: "1.0"
status: active
producer: architect
timestamp: 2026-07-14T14:00:00Z
phase: 1b
inputs:
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/specs/architecture/api-surface.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.001.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.002.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.003.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.004.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.005.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.006.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.007.md
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.008.md
input-hash: "2e720ff"
traces_to: .factory/specs/architecture/ARCH-INDEX.md
decisions: [D3, D13]
dtu_required: true
---

# DTU Assessment: ferrochain

## Scope Decision (D13)

**D13 (human directive, 2026-07-13):** ferrochain-server is FIRST-PARTY — built
in-workspace, no wire-compatibility target against LangGraph Platform. The Pass-6
"stateful fake" pattern is retired. DTU scope is limited to **genuine third-party
HTTP surfaces only**: OpenAI API, Anthropic API, and Ollama (local inference, keyless CI).

STATE.md `dtu_required: false` reflects the retirement of the server DTU. This
assessment supersedes that field for the provider surfaces mandated by D3 and D13.

**Overall DTU verdict: DTU_REQUIRED: true** — three genuine provider surfaces require
cassette-based behavioral clones for keyless CI and Phase 4 holdout evaluation.

## Clone Mechanism

The BC-2.08 conformance suite design uses a **record/replay HTTP fixture layer**
(wiremock or equivalent cassette middleware) running in-process. This is the
ferrochain-specific DTU mechanism for providers: pre-recorded HTTP cassettes stored
as fixture files, not standalone Docker clone servers. This approach is mandated
directly in BC-2.08.001 Precondition 4:

> "A record/replay HTTP fixture layer (e.g., wiremock or cassette middleware) is
> available so the suite runs in CI without live provider keys."

BC-2.08.001 EC-004 further constrains the cassette: it must faithfully encode
SSE chunk-by-chunk framing, not a buffered single-response that bypasses streaming
logic. This is a Behavioral (L3) fidelity requirement on the cassette content.

## Summary

| Metric | Value |
|--------|-------|
| External dependencies identified | 3 |
| DTU clones recommended | 3 |
| Clone mechanism | wiremock cassette recordings (in-process) |
| Cassette storage | `.factory/dtu-clones/[provider]-cassettes/` |
| Fidelity level: OpenAI, Anthropic | L3 (Behavioral) |
| Fidelity level: Ollama | L2 (Stateful) |
| Pre-Phase-3 gate | cassette directories populated (see §Pre-Phase-3 Obligation) |

## Integration Surface Inventory

### Inbound Data Sources (External → Product)

None identified — ferrochain is a library/framework. It does not poll external
sources or receive webhooks. All data flows from user-supplied inputs through
Runnable pipelines.

### Outbound Operations (Product → External)

These are the DTU-in-scope surfaces. ferrochain makes outbound HTTP calls to provider
chat completion APIs on behalf of user code.

| # | Service | Protocol | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| 1 | OpenAI Chat Completions API | HTTPS / SSE | L3 (Behavioral) | YES | BCs 2.08.001-007 exercise streaming chunk framing, tool-call round-trip, error taxonomy (401/400-context/429/500), and per-chunk timeout. Cassette must capture SSE framing faithfully (EC-004 constraint). Phase 4 holdout runs without live keys. **API MIGRATION FLAG:** OpenAI is mid Responses-API migration (Assistants API sunset announced; Realtime beta removed from openai-openapi spec). Cassettes MUST target Chat Completions endpoint (`/v1/chat/completions`) — NOT the Responses or Assistants APIs. If OpenAI completes the migration and deprecates Chat Completions before Phase 3, cassettes require a full re-record; this migration is a re-record trigger. Monitor openai-openapi changelog before cassette capture. |
| 2 | Anthropic Messages API | HTTPS / SSE | L3 (Behavioral) | YES | Same conformance battery as OpenAI via ferrochain-standard-tests. Distinct SSE envelope format (content-block-start/delta/stop events). Error JSON schema differs from OpenAI. 429 rate-limit semantics differ. |
| 3 | Ollama REST API | HTTP (local) | L2 (Stateful) | YES (cassette) | D3 early integration; keyless by design (no auth errors). Ollama can run locally in CI with a small model, but cassette fallback required for environments without GPU/Ollama install. Simpler API surface — no content-block index protocol. |

### Identity & Access (Bidirectional)

None identified — API credentials are managed as `ApiKey` newtypes (BC-2.14.005:
Redacted Debug, no Serialize, no Deref<Target=str>). There is no external auth service
or OAuth flow. Keys are injected from environment variables; no external identity provider.

### Persistence & State (Product ↔ Storage)

None identified — ferrochain-checkpoint uses SQLite (bundled, first-party) as the
default durable backend. No external managed database, cache, or message queue is
required for v1.0.0. PostgreSQL is a stretch `[dev-feature]` flag that is
out-of-scope for Phase 4 holdout.

### Observability & Export (Product → Monitoring)

None identified — ferrochain emits no telemetry to external aggregators by default.
Streaming events (BC-2.06) are consumed by the caller. Log output is to stderr via the
`tracing` crate. No OpenTelemetry exporter or metrics push is mandated for v1.0.0.

### Enrichment & Lookup (External → Product)

None identified — ferrochain does not call external enrichment services. It is a
general-purpose agent framework; domain-specific enrichment (threat intel, geocoding,
etc.) is the responsibility of user-defined tools.

## Dependency Summary

| # | Service | Category | Fidelity | DTU? | Justification |
|---|---------|----------|----------|------|---------------|
| 1 | OpenAI Chat Completions API | Outbound/LLM | L3 (Behavioral) | YES | SSE streaming conformance, tool-call round-trip, error taxonomy, transport-error scenarios per BC-2.08.001-007 |
| 2 | Anthropic Messages API | Outbound/LLM | L3 (Behavioral) | YES | Same conformance battery as OpenAI via ferrochain-standard-tests; distinct SSE envelope + error shapes |
| 3 | Ollama REST API | Outbound/LLM | L2 (Stateful) | YES (cassette) | D3 early integration; keyless; simpler NDJSON format; GPU-free CI fallback required |

## Per-Surface Clone Specification

### Surface 1: OpenAI Chat Completions API

| Field | Value |
|-------|-------|
| **DTU?** | YES |
| **Fidelity** | L3 (Behavioral) |
| **Clone type** | wiremock cassette recordings |
| **Storage** | `.factory/dtu-clones/openai-cassettes/` |
| **API spec** | OpenAI OpenAPI spec: https://github.com/openai/openai-openapi |
| **BC coverage** | BC-2.08.001, BC-2.08.002, BC-2.08.003, BC-2.08.004, BC-2.08.005, BC-2.08.007 |

**Behavioral scope required for cassettes:**

1. **Happy-path streaming** (BC-2.08.001 TV-001..004): SSE stream with
   `message-start` / `content-block-start{type,index}` / `content-block-delta` /
   `content-block-finish` / `message-finish` events. Block indices are contiguous
   from 0. Cassette must encode chunk-by-chunk (not buffered).
2. **Tool-call streaming** (BC-2.08.002): SSE stream containing interleaved
   `text` (index 0) and `tool_call_chunk` (index 1) blocks. Complete round-trip:
   tool result supplied as ToolMessage; final non-tool-call response.
3. **Structured output** (BC-2.08.003): `response_format: {type: json_schema}`
   path; JSON response validates against schema.
4. **Error taxonomy** (BC-2.08.004 TV-001..005):
   - HTTP 401 → `FerrochainError { category: Auth }` (key not in message)
   - HTTP 400 "context length exceeded" → `FerrochainError { category: ContextOverflow }`
   - HTTP 429 with `Retry-After: 60` → `FerrochainError { category: RateLimit, retry_hint: RetryAfter(60s) }`
   - HTTP 500 → `FerrochainError { category: Provider }`
   - HTTP 400 unknown JSON → `FerrochainError { category: Provider }` (no panic)
5. **Transport interruption** (BC-2.08.007 TV-001..003):
   - Stream stalls after first chunk (wiremock: delay after chunk 1 exceeds per-chunk timeout)
   - TCP RST mid-stream (wiremock: connection drop)
   - Stall before first chunk
6. **Token usage** (BC-2.08.005): `usage: {prompt_tokens, completion_tokens, total_tokens}`
   present in response; ferrochain exposes as `TokenUsage` in the returned `AiMessage`.

**API migration note (2026-07):** OpenAI is mid Responses-API migration. Assistants API
sunset is announced; Realtime beta is removed from the openai-openapi spec. Cassettes
MUST target Chat Completions (`/v1/chat/completions`) as currently specified. This
migration is a **re-record trigger**: if Chat Completions is deprecated before Phase 3
cassette capture, the cassette spec requires revision. Clone spec author must verify
the openai-openapi changelog (https://github.com/openai/openai-openapi) before
recording cassettes.

**Build feasibility:** HIGH. OpenAI publishes a full OpenAPI spec. Error JSON envelopes
are well-documented (`{"error": {"type": ..., "message": ..., "code": ...}}`). SSE
framing is standard OpenAI streaming format. Cassette recordings can be captured from
a one-time live call using wiremock record mode, then committed as fixture files.

### Surface 2: Anthropic Messages API

| Field | Value |
|-------|-------|
| **DTU?** | YES |
| **Fidelity** | L3 (Behavioral) |
| **Clone type** | wiremock cassette recordings |
| **Storage** | `.factory/dtu-clones/anthropic-cassettes/` |
| **API spec** | Anthropic docs: https://docs.anthropic.com/en/api |
| **BC coverage** | BC-2.08.001, BC-2.08.002, BC-2.08.003, BC-2.08.004, BC-2.08.005, BC-2.08.007 |

**Behavioral scope required for cassettes:**

1. **Happy-path streaming**: Anthropic SSE uses distinct event types:
   `message_start` / `content_block_start` / `content_block_delta` /
   `content_block_stop` / `message_delta` / `message_stop`. Cassette must
   preserve this framing faithfully (distinct from OpenAI envelope).
2. **Tool-call streaming**: `tool_use` content blocks with `input_json_delta`
   events. Round-trip through `tool_result` message role.
3. **Structured output**: Anthropic tool_use forced JSON output path.
4. **Error taxonomy** (Anthropic error shapes differ from OpenAI):
   - HTTP 401 → Auth (Anthropic: `{"type": "error", "error": {"type": "authentication_error"}}`)
   - HTTP 400 context: `{"error": {"type": "invalid_request_error"}}` with max tokens msg
   - HTTP 429 → RateLimit; `Retry-After` header carries the delay
   - HTTP 529 (overloaded) → Provider category (Anthropic-specific)
   - HTTP 500 → Provider
5. **Transport interruption**: same pattern as OpenAI.
6. **Token usage**: `usage: {input_tokens, output_tokens}` (Anthropic naming differs
   from OpenAI `prompt_tokens`/`completion_tokens` — normalization is required).

**Build feasibility:** HIGH. Anthropic publishes API reference docs and error type
catalog. SSE event format is documented. The primary difference from OpenAI is the
event type naming and the Anthropic-specific HTTP 529 status. Cassette capture is
straightforward via wiremock record mode.

### Surface 3: Ollama REST API

| Field | Value |
|-------|-------|
| **DTU?** | YES (cassette fallback) |
| **Fidelity** | L2 (Stateful) |
| **Clone type** | wiremock cassette recordings (primary) + local Ollama process (optional CI path) |
| **Storage** | `.factory/dtu-clones/ollama-cassettes/` |
| **API spec** | Ollama API docs: https://github.com/ollama/ollama/blob/main/docs/api.md |
| **BC coverage** | BC-2.08.001, BC-2.08.002, BC-2.08.004 (no Auth errors — keyless) |

**Behavioral scope required for cassettes:**

1. **Happy-path streaming**: Ollama streaming uses NDJSON (newline-delimited JSON),
   not SSE. Each chunk is a `{"model":..., "message": {...}, "done": false}` line;
   final chunk has `"done": true`. Cassette captures NDJSON line-by-line.
2. **Tool-call round-trip**: Ollama tool calling via `/api/chat` with `tools` param
   (available in models supporting it). Cassette captures tool-use response.
3. **Error taxonomy** (L2 scope — no auth):
   - Model not found: HTTP 404
   - Invalid request: HTTP 400
   - No 401 (keyless) — Auth category not exercised for Ollama.
4. **Transport interruption**: same stall/drop patterns as other providers.

**Rationale for L2 (not L3):** Ollama is keyless; the auth-error subset of L3
does not apply. The streaming format is simpler (NDJSON vs SSE with block indices).
Error taxonomy is narrower. L2 cassette coverage is sufficient for all BC-2.08
conformance gates that apply to Ollama.

**Local Ollama in CI (optional path):** For integration environments with Docker,
Ollama can run as a container with `tinyllama` or `qwen2.5:0.5b` (sub-1B models
that fit in CI runners). This supplements cassettes and enables fully live
round-trip testing. The cassette remains the CI baseline for keyless environments.

## Services NOT Requiring DTU

| # | Service | Reason |
|---|---------|--------|
| 1 | ferrochain-server | First-party per D13. Full BCs + holdout scenarios assigned. No DTU. Pass-6 "stateful fake" retired. |
| 2 | SQLite (checkpoint) | Bundled first-party dependency; not an external service. |
| 3 | WASM runtime (sandbox) | First-party; ferrochain-sandbox implements the execution contract. |

## DTU Architecture

ferrochain uses a **cassette-based** clone mechanism rather than Docker Compose
clone servers. The "DTU" here is an in-process wiremock record/replay layer:
cassette files stored under `.factory/dtu-clones/` are loaded by test harnesses
at suite start, eliminating live provider keys in CI without running separate
containers.

| Clone | Mechanism | Fidelity | Port Required |
|-------|-----------|----------|---------------|
| openai-cassettes | wiremock in-process | L3 | none (in-process) |
| anthropic-cassettes | wiremock in-process | L3 | none (in-process) |
| ollama-cassettes | wiremock in-process (+ optional local container) | L2 | none (cassette path) |

### DTU Clone Storage Layout

```
.factory/dtu-clones/
├── openai-cassettes/
│   ├── README.md                    # Cassette format + capture instructions
│   ├── streaming-happy-path.json    # BC-2.08.001 TV-001..004
│   ├── tool-call-round-trip.json    # BC-2.08.002
│   ├── structured-output.json       # BC-2.08.003
│   ├── error-401.json               # BC-2.08.004 TV-001
│   ├── error-400-context.json       # BC-2.08.004 TV-002
│   ├── error-429-retry-after.json   # BC-2.08.004 TV-003
│   ├── error-500.json               # BC-2.08.004 TV-004
│   ├── transport-stall.json         # BC-2.08.007 TV-001
│   └── token-usage.json             # BC-2.08.005
├── anthropic-cassettes/
│   ├── README.md
│   ├── streaming-happy-path.json    # BC-2.08.001 (Anthropic SSE framing)
│   ├── tool-call-round-trip.json    # BC-2.08.002
│   ├── error-401.json               # BC-2.08.004 TV-001
│   ├── error-400-context.json       # BC-2.08.004 TV-002
│   ├── error-429-retry-after.json   # BC-2.08.004 TV-003
│   ├── error-529-overloaded.json    # Anthropic-specific Provider category
│   └── transport-stall.json         # BC-2.08.007 TV-001
└── ollama-cassettes/
    ├── README.md
    ├── streaming-happy-path.json    # BC-2.08.001 (NDJSON framing)
    ├── tool-call-round-trip.json    # BC-2.08.002
    └── error-404-model.json         # BC-2.08.004 (no auth errors)
```

## Environment Variable Overrides

No running-server ports required (cassette mechanism is in-process via wiremock).
Cassette path is configured via test fixture initialization, not environment variables.

For the optional local Ollama CI path:

| Variable | Production Value | DTU Value |
|----------|-----------------|-----------|
| `OLLAMA_BASE_URL` | `http://localhost:11434` | `http://localhost:11434` (local Ollama container) |

## Pre-Phase-3 Clone-Existence Check Obligation

Before any Wave 2 integration test story begins (Phase 3), the following gate must pass:

- [ ] `.factory/dtu-clones/openai-cassettes/` directory exists and contains ≥8 cassette files
- [ ] `.factory/dtu-clones/anthropic-cassettes/` directory exists and contains ≥7 cassette files
- [ ] `.factory/dtu-clones/ollama-cassettes/` directory exists and contains ≥3 cassette files
- [ ] Each cassette captures SSE framing chunk-by-chunk (not buffered single response)
- [ ] `ferrochain-openai/tests/` wires wiremock to load from `../../../.factory/dtu-clones/openai-cassettes/`
- [ ] `ferrochain-anthropic/tests/` wires wiremock from `anthropic-cassettes/`
- [ ] `ferrochain-ollama/tests/` wires wiremock from `ollama-cassettes/`

Cassette capture is a Wave 2 story (story decomposition Phase 2). Cassette wiring
stories are prerequisites to all BC-2.08 conformance stories.

## BC-2.08 Coverage Matrix (SS-08)

| BC | Title | Surfaces Covered | DTU Cassette Fidelity |
|----|-------|------------------|-----------------------|
| BC-2.08.001 | Streaming Completions Conformance | OpenAI, Anthropic, Ollama | L3 (SSE chunk framing) |
| BC-2.08.002 | Tool-Call Round-Trip Conformance | OpenAI, Anthropic, Ollama | L3 (tool streaming) |
| BC-2.08.003 | Structured Output Conformance | OpenAI, Anthropic | L3 (JSON schema response) |
| BC-2.08.004 | Error-Type Fidelity Conformance | OpenAI, Anthropic, Ollama | L3 (typed error taxonomy) |
| BC-2.08.005 | Token-Usage Accounting Conformance | OpenAI, Anthropic | L2 (response field) |
| BC-2.08.006 | Standalone SDK Crate Split | — (architectural, no cassette) | N/A |
| BC-2.08.007 | Streaming Transport Error | OpenAI, Anthropic, Ollama | L3 (stall + TCP RST) |
| BC-2.08.008 | Eval Score Aggregation | — (internal computation, no provider call) | N/A |

## Risk Annotation

**R3 (Low, resolved by D13):** DTU scope revised per D13. ferrochain-server
first-party treatment eliminates the Pass-6 stateful fake obligation. Residual
risk: cassette fidelity for streaming error scenarios (BC-2.08.007 stall/RST)
requires careful wiremock configuration — standard chunk-delivery cassettes
are insufficient; connection-drop and delay scenarios require behavioral cassette
extensions. Mitigation: cassette README documents capture procedure for each
error scenario.

## Clone Development Approach

Each DTU cassette set is developed as a VSDD story in Wave 2 with:
- Behavioral contracts derived from live provider API documentation and
  the BC-2.08 conformance matrix (see §BC-2.08 Coverage Matrix above)
- Cassette capture via wiremock record mode against a live provider (one-time,
  requires developer API keys; recorded cassettes are committed as fixture files)
- Contract tests verifying cassette content matches the BC-2.08 fidelity
  requirements (SSE chunk-by-chunk framing, error JSON envelopes, token-usage
  field presence)
- Cassette wiring stories are prerequisites to all BC-2.08 conformance stories;
  see §Pre-Phase-3 Clone-Existence Check Obligation for the gate criteria
- No Docker packaging required — cassettes are plain JSON files loaded
  in-process by wiremock; no container runtime needed in CI
