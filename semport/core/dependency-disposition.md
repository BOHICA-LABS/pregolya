---
artifact: semport/core/dependency-disposition
project: pregolya
port_target: langchain-core (P0)
analyzer_pass: 1
date: 2026-07-12
---

# langchain-core — Third-Party Dependency Disposition

Runtime dependencies from `libs/core/pyproject.toml` (`langchain-core==1.4.9`):

```
langsmith>=0.3.45,<1.0.0
tenacity!=8.4.0,>=8.1.0,<10.0.0
jsonpatch>=1.33.0,<2.0.0
PyYAML>=5.3.0,<7.0.0
typing-extensions>=4.7.0,<5.0.0
packaging>=23.2.0
pydantic>=2.7.4,<3.0.0
uuid-utils>=0.12.0,<1.0
langchain-protocol>=0.0.17
```
Plus two non-declared imports found in source: **jinja2** (optional, guarded import in
`prompts/string.py`) and **numpy** (test/in-memory-vectorstore only, declared under the
`test` dependency group).

Disposition legend: **MAP** = use a Rust crate; **PORT** = reimplement in Rust;
**ELIMINATE** = absorbed by the Rust type system / std / out of scope.

---

## pydantic `>=2.7.4,<3` — **PORT-equivalent via serde/derive + validator crate** (CRITICAL)

By far the most pervasive dependency. Every `Serializable`, `BaseMessage`,
prompt template, tool, and output parser is a `pydantic.BaseModel`. Pydantic runtime
behavior **leaks into the public contract** in several places that must be reproduced,
not just approximated:

- **`model_dump()` / `model_dump_json()`** — the exact serialized dict shape of
  messages, generations, and lc-JSON. Rust: `serde` `Serialize`. Semantic-diff risk:
  pydantic omits/None-handles fields via `exclude_none`/`exclude_defaults`; core's
  `Serializable.to_json` re-implements field pruning (`_is_field_useful`) on top —
  **port that pruning logic explicitly** (`load/serializable.py`), don't assume serde
  `skip_serializing_if` matches.
- **Field aliases** — `by_alias` serialization and alias-aware secret hiding
  (`_replace_secrets` walks aliases). Rust: `#[serde(rename/alias)]`. Risk: pydantic
  populate-by-name vs alias-only; must match on both read and write.
- **Validators** (`@field_validator`, `@model_validator`, `pre_init`) — e.g. AIMessage
  parses tool_calls out of content_blocks at construction; `id` coerces numbers to str
  (`coerce_numbers_to_str=True`). Rust: constructor functions / `TryFrom` / a validator
  crate (e.g. `validator`, or hand-rolled `new()` builders). Risk: pydantic runs
  validators on assignment and coercion implicitly; Rust must place these at explicit
  construction/deserialization boundaries.
- **`model_json_schema()` for tool schemas** — `utils/function_calling` emits OpenAI
  tool JSON schema derived from pydantic's schema generator. This is **model-facing
  wire output**, so the emitted JSON schema must match closely enough that providers
  accept it. Rust: `schemars` (JSON Schema derive) is the natural MAP, but its output
  differs from pydantic's (title casing, `$ref`/`$defs` layout, `anyOf` vs
  `nullable`). **High semantic-diff risk — needs an ADR and golden-schema tests**
  (port `utils/test_function_calling`-style fixtures).
- **`extra="allow"` (messages) / `extra="ignore"` (Serializable)** — messages capture
  unknown fields. Rust: `#[serde(flatten)] extra: Map<String,Value>` or
  `#[serde(deny_unknown_fields)]` opposite. Must preserve "allow" for messages.
- **pydantic v1/v2 dual-compat** (`utils/pydantic.py`, 630 LOC) — ELIMINATE. This is
  pure Python-migration cruft with no analog in a greenfield Rust port.

**Recommended Rust mapping:** `serde` + `serde_json` for (de)serialization; `schemars`
for tool JSON-schema generation (behind a compatibility shim + golden tests);
hand-rolled constructors/builders for validators; a small internal trait for the
`Serializable`/lc-JSON contract. Do **not** seek a single "pydantic crate" — the
behavior decomposes into serde + schemars + explicit validation.

---

## langchain-protocol `>=0.0.17` — **PORT (small, but new & churning)** 

New in the 1.4 line. Provides the wire protocol types for **content-block streaming
events** (`MessageStartData`, `ContentBlockDeltaData`, `ContentBlockFinishData`,
`MessageFinishData`, `MessagesData`, etc.), consumed by `chat_model_stream.py` (v3
stream), `chat_models.py`, and `callbacks/`. Scope: a set of TypedDict/dataclass event
schemas + finalization helpers. **PORT** as a set of serde-tagged enums in a small
`pregolya-protocol`-equivalent module (or fold into the messages crate). Risk: it is
`0.0.x`, actively evolving; ~~the v3 stream has only 2 tests~~ — CORRECTED: v3 streaming has 107 dedicated tests across `test_chat_model_v3_stream.py` (41), `test_chat_model_stream.py` (42), `test_chat_model_streamer.py` (24), + `test_runnable_events_v3.py` (2). `[validation-certification-9]` The protocol version string is still `0.0.x` and the schema is evolving, but the test coverage is substantial. **Gating v3 behind a feature remains a reasonable architecture decision**, but the rationale is version volatility, not lack of tests.

---

## langsmith `>=0.3.45` — **ELIMINATE from core / MAP as optional exporter**

Proprietary-SaaS tracing client. In core it is used only by the tracing seam:
`tracers/langchain.py` (posts runs), `tracers/context.py`, `tracers/evaluation.py`,
`runnables/config.py` (sets tracing context), `callbacks/manager.py`,
`document_loaders/langsmith.py`. Imports are deferred (~132ms cost). **Disposition:**
ELIMINATE from the core execution path — the Rust port exposes callback/tracer *traits*
and ships an in-memory/console tracer. A LangSmith exporter is an **optional downstream
crate** that implements the tracer trait and POSTs to the LangSmith ingestion API
(plain `reqwest`). No core logic should depend on it.

---

## tenacity `>=8.1,<10` — **MAP → `backon` or hand-rolled retry**

Retry/backoff library. Used by `runnables/retry.py` (`.with_retry` — stop-after-attempt,
exponential jitter, retry-on exception types), `language_models/llms.py`,
`callbacks/*`, `tracers/*` (retry posting runs). **MAP** to a Rust retry crate
(`backon`, `tokio-retry`, or `again`) or a small hand-rolled async retry combinator
(the surface used is narrow: max attempts, exponential backoff + jitter, predicate on
error type, `before_sleep` hook for `on_retry` callback). Semantic-diff risk: jitter
algorithm and the exact `wait_exponential_jitter` formula — match parameters, tests in
`runnables/test_runnable.py` cover retry counts. Async-first: use an async retry combinator
at the Runnable seam.

---

## jsonpatch `>=1.33,<2` — **MAP → `json-patch` crate (RFC 6902)**

Used in exactly 3 places, all streaming/diff:
`tracers/log_stream.py` (`astream_log` emits `RunLogPatch` = JSON Patch ops applied to
reconstruct run-tree state), `output_parsers/json.py` and
`output_parsers/openai_functions.py` (emit the *delta* between successive partial-JSON
parses so streamed structured output grows incrementally). **MAP** to the Rust
`json-patch` crate (implements RFC 6902 add/replace/remove + diff). Semantic-diff risk:
jsonpatch's `make_patch` diff algorithm ordering may differ from `json-patch`'s `diff`;
the *emitted patch stream* is observable behavior (tests assert patch sequences), so
**golden-test the patch output** or reimplement the diff to match. Moderate risk.

---

## PyYAML `>=5.3,<7` — **MAP → `serde_yaml` (or drop if YAML I/O deprioritized)**

Used in `prompts/loading.py` (load prompt templates from YAML files),
`prompts/base.py` (`save`), `language_models/llms.py` (`save`), and
`runnables/graph_mermaid.py`. All are file-based save/load convenience + a mermaid
config string. **MAP** to `serde_yaml` (or `serde_yml`). Low risk — YAML here is just
an alternate serialization surface over the same lc-JSON structures. Consider
deprioritizing YAML prompt loading to P1 (JSON path is primary).

---

## jinja2 (optional, undeclared) — **MAP → `minijinja` (feature-gated)**

Not a hard dependency; imported lazily in `prompts/string.py` with an ImportError guard
and a **sandboxed** environment (`SandboxedEnvironment`) plus explicit
"don't render untrusted templates" warnings. One of three template formats
(`f-string` default, `mustache`, `jinja2`). **MAP** to `minijinja` (closest Jinja2
semantics in Rust) behind a Cargo feature. Risk: variable-extraction (`jinja2.meta`)
and sandbox semantics differ; `minijinja` is not byte-identical. Low priority — most
LangChain templates use f-string/mustache.

---

## uuid-utils `>=0.12` — **ELIMINATE → `uuid` crate**

Fast Rust-backed UUID generation (the Python package is itself a Rust binding). Used in
`utils/uuid.py` for run/message id generation (`lc_`-prefixed UUID4). **ELIMINATE** the
dependency; use the Rust `uuid` crate directly (v4). Trivial. Preserve the `lc_` /
`lc_auto_` id-prefix convention (`utils/utils.py:LC_ID_PREFIX`, `LC_AUTO_PREFIX`,
`ensure_id`).

---

## typing-extensions — **ELIMINATE**

Backports of typing features (`TypedDict`, `NotRequired`, `Self`, `override`,
`ParamSpec`). Pure static-typing support. **ELIMINATE** — Rust's type system provides
all of this natively. `TypedDict` content blocks become structs/enums; `NotRequired`
becomes `Option<T>` / `#[serde(default)]`; `override` is `impl` semantics.

---

## packaging `>=23.2` — **ELIMINATE → `semver` crate if needed**

Version parsing/comparison, used in `_api` deprecation logic and `sys_info`.
**ELIMINATE**; if any runtime version comparison survives the port, use the `semver`
crate. Most of `_api` (deprecation/beta decorators) is itself ELIMINATE — Rust uses
`#[deprecated]` attributes and doc annotations.

---

## numpy (test/optional) — **MAP → `ndarray` only if in-memory vectorstore is in scope**

Used by `embeddings/fake.py`, `vectorstores/in_memory.py`, `vectorstores/utils.py`
(cosine similarity, MMR). Declared under `test` group. **MAP** to `ndarray` (or plain
`Vec<f32>` + manual dot/cosine — the math is small) *only if* `InMemoryVectorStore` is
ported into core. Otherwise ELIMINATE from core and leave vector math to downstream
vectorstore crates. Recommend: keep a minimal `Vec<f32>` cosine/MMR in core, no
`ndarray` dep.

---

## Disposition summary

| Dep | Disposition | Rust target | Risk |
|---|---|---|---|
| pydantic | PORT-equiv | serde + schemars + builders/validators | **HIGH** (schema gen, dump semantics) |
| langchain-protocol | PORT | tagged enums (own module) | MED (new/churning, v3 schema 0.0.x) <!-- [validation-certification-10]: "v3 immature" was stale — cert-9 established v3 streaming has 107 dedicated tests (NOT immature from test-coverage perspective). The valid risk is schema volatility at 0.0.x, not test immaturity. Risk label updated accordingly. --> |
| langsmith | ELIMINATE core / opt MAP | tracer trait + optional reqwest exporter | LOW |
| tenacity | MAP | `backon`/`tokio-retry` or hand-rolled | MED (jitter formula) |
| jsonpatch | MAP | `json-patch` (RFC 6902) | MED (diff output is observable) |
| PyYAML | MAP | `serde_yaml` | LOW |
| jinja2 (opt) | MAP (feature) | `minijinja` | LOW |
| uuid-utils | ELIMINATE | `uuid` crate | trivial |
| typing-extensions | ELIMINATE | native types | none |
| packaging | ELIMINATE | `semver` if needed | none |
| numpy (opt) | MAP if in scope | `ndarray` or manual | LOW |

**Net new Rust runtime deps for a faithful core:** `serde`, `serde_json`, `schemars`,
`serde_yaml`, a retry crate, `json-patch`, `uuid`, `futures`, `tokio`, `async-trait`
(at dyn seams), plus `minijinja` (feature). Everything pydantic/typing/packaging-shaped
collapses into the type system.

---

# Pass 7 deepening (2026-07-12) — langchain-protocol full inventory (R7)

**Not vendored in the langchain clone.** The pin is `langchain-protocol>=0.0.17` (a floor,
not `==0.0.17`; Pass 1 recorded it as if exact). No copy exists under `.reference/`. The only
local copy is **v0.0.15** in an OrbStack container site-packages
(`.../open-webui/.../site-packages/langchain_protocol/`), read as an approximation — **the
exact 0.0.17 schema must be fetched** from `github.com/langchain-ai/agent-protocol/tree/main/streaming`
(project URL in the dist-info METADATA) before finalizing the port. The package is a single
`protocol.py` (~578 LOC, machine-generated: header `# compiled with cddl2py` — it is compiled
from a **CDDL** wire-schema, so the canonical source is the `.cddl`, not the Python).

## CONTRADICTION C-1 (largest): scope was massively understated

Pass 1 (dependency-disposition + module-inventory) called it "the wire protocol types for
content-block streaming events … a set of TypedDict/dataclass event schemas + finalization
helpers." **It is far larger** — the full **LangChain Agent Streaming Protocol**, a JSON-RPC-
style *bidirectional* wire protocol for driving/observing a running agent (langgraph server):

- **Commands** (client→server): `run.start`, `subscription.subscribe`/`unsubscribe`/`reconnect`,
  `agent.getTree`, `input.respond`/`inject`, `state.get`/`listCheckpoints`/`fork`. Each is
  tagged by a `method` literal and carries an integer `id` (`_CommandVariant0..9`).
- **Responses**: `CommandResponse{type:"success", id, result}` / `ErrorResponse{type:"error",
  id, error: ErrorCode, message, stacktrace?}` with a 10-value `ErrorCode` enum
  (`invalid_argument`, `unknown_command`, `no_such_run`, `no_such_checkpoint`,
  `permission_denied`, `not_supported`, …).
- **Events** (server→client) across **9 channels**: `lifecycle`, `messages`, `tools`, `input`,
  `values`, `updates`, `checkpoints`, `custom`, `tasks`. Each event has SSE-style
  `event_id`/`seq` (monotonic) for **replay and reconnection** (`since`, `last_event_id`,
  `replayed_events`, `missed_events`).
- **State/time-travel**: `Checkpoint`, `CheckpointRef`, `CheckpointSource` (`input`/`loop`/
  `update`/`fork`), `state.fork` (branch a run from a checkpoint), `UpdatesData` (per-node state
  deltas), `AgentTreeNode`/`AgentStatus` (`started`/`running`/`completed`/`failed`/`interrupted`).
- **Messages channel (`MessagesData`)** — the ONLY part core uses: `MessageStartData`
  (`message-start`, role∈{ai,human,system}, id, metadata), `ContentBlockStartData`
  (`content-block-start`, index, content: ContentBlock), `ContentBlockDeltaData`
  (`content-block-delta`, index, delta: TextDelta|ReasoningDelta|DataDelta|BlockDelta),
  `ContentBlockFinishData` (`content-block-finish`, FinalizedContentBlock), `MessageFinishData`
  (`message-finish`, usage), `MessageErrorData` (`error`).
- **Tools channel (`ToolsData`)**: `tool-started`/`tool-output-delta`/`tool-finished`/`tool-error`.
- A **second, parallel `ContentBlock` union** (structurally near-isomorphic to
  `langchain_core.messages.content.ContentBlock` but nominally distinct) — the reason
  `_compat_bridge.py` exists.

## Revised disposition — SPLIT the port

| Scope | What | Disposition | Target crate |
|---|---|---|---|
| **Core needs** | `MessagesData` (6 event types) + `ContentBlock`/`FinalizedContentBlock` + `UsageInfo` + `MessageMetadata` + the `*Delta` types | **PORT** as serde-tagged enums | pregolya-core (messages module) |
| **Agent-server protocol** | Commands, subscriptions, state/fork/checkpoints, agent tree, 9-channel events, replay/reconnect | **DEFER / out of core** | a future pregolya-graph / agent-server crate |

Core's actual import surface is 7 import statements across 5 files (all `MessagesData`-subset):
`language_models/chat_models.py` (2 blocks: line 16 runtime + line 101 TYPE_CHECKING),
`language_models/_compat_bridge.py` (2 blocks: line 39 runtime + line 65 TYPE_CHECKING),
`language_models/chat_model_stream.py`, `callbacks/base.py`, `callbacks/manager.py`.
<!-- [validation-exhaustive]: original said "exactly 6 sites"; grep finds 7 `from langchain_protocol` import statements. The 5 files are correct; two of them contain 2 import groups each (one runtime, one TYPE_CHECKING-gated). -->
So Pass 1's "PORT the whole package as tagged enums (own module), MED risk" over-scopes core:
**core only needs the messages/content-block subset**; that subset should be **unified with the
core `ContentBlock` enum** (a single Rust type), which eliminates the `_compat_bridge` laundering
layer entirely. Revised R7 risk for core: **LOW-MED** (small, stable subset), with the
provisional/churning surface (the command/state protocol) pushed out of core scope. The full
protocol, if/when pregolya builds a langgraph-style server, should be generated from the
upstream CDDL schema rather than hand-transcribed.
