---
artifact: semport/langchain/module-inventory
project: ferrochain
port_target: langchain (v1 package, PyPI `langchain` 1.3.13)
source: .reference/langchain/libs/langchain_v1  (v1 ONLY — NOT libs/langchain / classic, per D1)
analyzer_pass: 3
date: 2026-07-12
note: analysis only — NO Rust code; signatures quoted are Python from source
---

# langchain (v1) — Module Inventory

## 0. Scale summary

Measured with `find … -exec wc -l` on the checkout (2026-07-12).

| Area | Files | LOC | Notes |
|---|---:|---:|---|
| **Source (`langchain/`)** | 33 `.py` | **14,512** | The entire shippable package |
| Tests (`tests/`) | 63 `test_*.py` (+fixtures) | **31,653** | ~2.2× source; unit-test-heavy |
| **Total** | ~96 | ~46,165 | |

Source LOC concentrates almost entirely in **agents/** (13,026 LOC, ~90%). The rest <!-- [validation-corrected pass-8]: "≈12,600 LOC, 87%" was inaccurate; recount: `find .../langchain_v1/langchain/agents -name "*.py" | xargs wc -l` = 13,026; 13,026/14,512 = 89.8% ≈ 90% -->
(`chat_models`, `embeddings`, `messages`, `tools`, `rate_limiters`) is thin factory /
re-export glue over `langchain-core` and `langgraph`.

Top source files:

| File | LOC | Role |
|---|---:|---|
| `agents/middleware/types.py` | 2,161 | Middleware base class, hook contracts, state schemas, decorators |
| `agents/factory.py` | 2,007 | `create_agent` — the graph builder + model node + edges |
| `chat_models/base.py` | 1,055 | `init_chat_model` + `_ConfigurableModel` |
| `agents/middleware/shell_tool.py` | 949 | Shell exec middleware (host/docker/codex sandboxes) |
| `agents/middleware/pii.py` | 878 | PII detection/redaction middleware + stream transformer |
| `agents/middleware/summarization.py` | 868 | History summarization middleware |
| `agents/structured_output.py` | 463 | Response-format strategies (Tool/Provider/Auto) |

**Scoping verdict:** This is a *medium* package but a *heavy* one — its behavioral
weight is the agent loop + middleware composition, not breadth. The hard part is not
LOC; it is that ~11 langgraph subsystems and the entire graph-execution model are
consumed as a dependency. Everything else re-exports `langchain-core`.

## 1. Package layout

```
langchain/
├── __init__.py            # just __version__ = "1.3.13"
├── agents/                # THE package (~90% of LOC) <!-- [validation-corrected pass-8]: was "87%"; actual 13,026/14,512 = 89.8% -->
│   ├── __init__.py        # exports create_agent, AgentState
│   ├── factory.py         # create_agent (graph builder)
│   ├── structured_output.py  # ToolStrategy / ProviderStrategy / AutoStrategy + bindings
│   ├── _subagent_transformer.py  # stream transformer: surface nested named agents
│   └── middleware/
│       ├── __init__.py    # re-exports all built-in middleware + decorators
│       ├── types.py       # AgentMiddleware, hooks, AgentState, ModelRequest/Response, decorators
│       ├── _execution.py  # shared shell/tool execution helpers (used by shell_tool)
│       ├── _redaction.py  # shared redaction primitives (used by pii)
│       ├── _retry.py      # shared retry primitives (used by *_retry)
│       └── <15 built-in middleware impls>  <!-- [validation-corrected: 15 not 13; counted from source] -->
├── chat_models/           # init_chat_model + _ConfigurableModel
│   ├── __init__.py        # re-exports BaseChatModel (core), init_chat_model
│   └── base.py
├── embeddings/            # init_embeddings
│   ├── __init__.py        # re-exports Embeddings (core), init_embeddings
│   └── base.py
├── messages/__init__.py   # PURE re-export of langchain_core.messages (34 symbols)
├── tools/                 # re-exports core tools + langgraph tool_node symbols
│   ├── __init__.py        # BaseTool, tool, InjectedToolArg… + InjectedState/Store/ToolRuntime
│   └── tool_node.py       # backwards-compat re-export of langgraph.prebuilt.tool_node
└── rate_limiters/__init__.py  # PURE re-export of langchain_core.rate_limiters
```

## 2. Public API surface (what a consumer imports from `langchain`)

| Import path | Symbols | Origin |
|---|---|---|
| `langchain.agents` | `create_agent`, `AgentState` | **own** |
| `langchain.agents.middleware` | `AgentMiddleware`, `AgentState`, `ModelRequest`, `ModelResponse`, `ModelCallResult`, `ExtendedModelResponse`, `InputAgentState`, `OutputAgentState`, `ToolCallRequest`; decorators `before_agent/after_agent/before_model/after_model/dynamic_prompt/wrap_model_call/wrap_tool_call/hook_config`; 15 built-in middleware classes + their config types <!-- [validation-corrected pass-3]: §2 still said 13; §4 corrected to 15 in pass-1; propagation missed in passes 1 and 2 --> | **own** |
| `langchain.chat_models` | `init_chat_model`, `BaseChatModel` (re-export) | **own** + core |
| `langchain.embeddings` | `init_embeddings`, `Embeddings` (re-export) | **own** + core |
| `langchain.messages` | 31 symbols (message types, content-block types, tool-call types, and `trim_messages`) <!-- [validation-exhaustive]: prior passes claimed 34; AST parse of messages/__init__.py `__all__` list = 31 entries (30 types + trim_messages); `python3 -c "..."` confirms count = 31 --> | **pure re-export of `langchain_core.messages`** |
| `langchain.tools` | `BaseTool`, `tool`, `InjectedToolArg`, `InjectedToolCallId`, `ToolException` (core) + `InjectedState`, `InjectedStore`, `ToolRuntime` (langgraph) | re-export core + langgraph |
| `langchain.rate_limiters` | `BaseRateLimiter`, `InMemoryRateLimiter` | **pure re-export of `langchain_core.rate_limiters`** |

**Implication for ferrochain:** `messages`, `rate_limiters`, most of `tools`, and the
`BaseChatModel`/`Embeddings` re-exports are satisfied entirely by **ferrochain-core**.
The v1 `langchain` crate's *net-new* surface is: `create_agent`, the middleware system,
`init_chat_model`/`init_embeddings`, and `structured_output`.

## 3. Component catalog (own code)

### 3.1 `create_agent` (factory.py) — the entry point
Builds and compiles a **langgraph `StateGraph`** into a `CompiledStateGraph`. Not a
class; a function with 3 typed overloads keyed on `response_format`. Produces nodes
(`model`, optional `tools`, one node per middleware hook instance), wires conditional
edges implementing the agent loop, and compiles with checkpointer/store/cache/interrupts/
stream-transformers. See behavioral-intent.md §1 for the full contract.

### 3.2 Middleware system (middleware/types.py)
`AgentMiddleware[StateT, ContextT, ResponseT]` base class with **10 overridable hooks**
(5 sync + 5 async pairs), a `state_schema`, `tools`, and `transformers`. Plus 8 function
decorators that synthesize middleware subclasses at runtime via `type(...)`. See
behavioral-intent.md §2 for the hook-point inventory and composition semantics.

### 3.3 Structured output (structured_output.py)
`ToolStrategy` (force a tool call whose args = the schema), `ProviderStrategy` (native
provider `response_format=json_schema`), `AutoStrategy` (pick based on model profile).
Supporting: `_SchemaSpec` (normalizes pydantic/dataclass/TypedDict/JSON-schema →
name+description+json_schema), `OutputToolBinding`, `ProviderStrategyBinding`, three error
types. Integrated **into the model node's main loop** (no extra LLM call).

### 3.4 `init_chat_model` (chat_models/base.py)
Provider registry (`_BUILTIN_PROVIDERS`: 27 providers <!-- [validation-corrected pass-2]: original said 30; pass-1 corrected to 33 but that was also wrong. Definitive count: regex on dict keys only (lines 38-78 of chat_models/base.py with pattern `^\s+"[a-z_A-Z]+":`) = 27. Pass-1 overcounted 3 multi-line tuple value strings as keys. --> → import path + class + creator
lambda), provider inference from model-name prefix, and `_ConfigurableModel` — a
`Runnable` wrapper that defers model construction and queues declarative ops
(`bind_tools`, `with_structured_output`) until a config selects the concrete model.

### 3.5 `init_embeddings` (embeddings/base.py)
Same pattern as `init_chat_model`, 10 providers <!-- [validation-corrected pass-2]: original said 11; pass-1 corrected to 14 but that was also wrong. Definitive count: regex on dict keys (lines 15-55 of embeddings/base.py) = 10. Same over-count error as §3.4. -->, returns `Embeddings` or a configurable
wrapper. Much smaller (275 LOC).

### 3.6 `_subagent_transformer.py` / `SubagentTransformer`
A langgraph `StreamTransformer` subclass (`_TasksLifecycleBase`) that detects nested
named agents (`create_agent(name=...)`) during streaming and surfaces them as typed
`run.subagents` handles. Multi-agent streaming plumbing. Depends heavily on langgraph
stream internals (`langgraph.stream.*`).

## 4. Built-in middleware inventory (15) <!-- [validation-corrected: 15 not 13] -->

| Middleware | File | LOC | Primary hook(s) | Adds state? | Adds tools? |
|---|---|---:|---|---|---|
| `SummarizationMiddleware` | summarization.py | 868 | `before_model` | no | no |
| `HumanInTheLoopMiddleware` | human_in_the_loop.py | 485 | `after_model` (+ langgraph `interrupt`) | no | no |
| `PIIMiddleware` | pii.py | 878 | `before_model` + `after_model` (+ stream transformer) | no | no |
| `ContextEditingMiddleware` | context_editing.py | 298 | `wrap_model_call` | no | no |
| `FilesystemFileSearchMiddleware` | file_search.py | 433 | (registers tools) | no | **yes** |
| `ModelCallLimitMiddleware` | model_call_limit.py | 267 | `before_model` + `after_model` | **yes** (`ModelCallLimitState`) | no |
| `ModelFallbackMiddleware` | model_fallback.py | 408 | `wrap_model_call` | no | no |
| `ModelRetryMiddleware` | model_retry.py | 312 | `wrap_model_call` | no | no |
| `ProviderToolSearchMiddleware` | provider_tool_search.py | 307 | `wrap_model_call` | no | no |
| `ShellToolMiddleware` | shell_tool.py | 949 | `before_agent` + `after_agent` (registers shell tool) | **yes** (`ShellToolState`) | **yes** |
| `TodoListMiddleware` | todo.py | 357 | `wrap_model_call` + `after_model` (registers write-todos tool) | **yes** (`PlanningState`) | **yes** |
| `ToolCallLimitMiddleware` | tool_call_limit.py | 487 | `after_model` | **yes** (`ToolCallLimitState`) | no |
| `LLMToolEmulator` | tool_emulator.py | 209 | `wrap_tool_call` | no | no |
| `ToolRetryMiddleware` | tool_retry.py | 411 | `wrap_tool_call` | no | no |
| `LLMToolSelectorMiddleware` | tool_selection.py | 355 | `wrap_model_call` | no | no |

Shared internal helpers: `_execution.py` (385, shell/exec policies), `_redaction.py`
(454, regex/entity redaction used by pii + shell), `_retry.py` (125, backoff/retry policy
used by model_retry + tool_retry).

Config/value types exported alongside: `TriggerClause`, `InterruptOnConfig`,
`ClearToolUsesEdit`, `RedactionRule`, `HostExecutionPolicy`, `DockerExecutionPolicy`,
`CodexSandboxExecutionPolicy`, `PIIDetectionError`.

## 5. Dependency graph (own modules)

```mermaid
graph TD
    factory[agents/factory.py<br/>create_agent] --> mwtypes[middleware/types.py]
    factory --> structured[structured_output.py]
    factory --> subxf[_subagent_transformer.py]
    factory --> initcm[chat_models/base.py<br/>init_chat_model]
    mwinit[middleware/__init__.py] --> mwtypes
    mwinit --> mw15[15 built-in middleware] <!-- [validation-corrected pass-3]: node was mw13[13 built-in middleware]; corrected to 15 -->
    mw15 --> mwtypes
    mw15 --> shared[_execution / _redaction / _retry]
    factory --> LG[[langgraph]]
    mwtypes --> LG
    subxf --> LG
    mw15 --> LG
    factory --> LS[[langsmith.traceable]]
    factory --> CORE[[langchain-core]]
    mwtypes --> CORE
    structured --> CORE
    initcm --> CORE
```

**Every own module depends on `langchain-core`; every agent module depends on
`langgraph`.** `factory.py` additionally imports `langsmith.traceable` directly (see
dependency-disposition.md — this is the only non-declared runtime import).

## 6. Entry points (priority order for the port)

1. `langchain/agents/factory.py::create_agent` — **P0**, the whole point of the package.
2. `langchain/agents/middleware/types.py` — **P0**, the contracts create_agent composes.
3. `langchain/agents/structured_output.py` — **P1**, integrated in the model node.
4. `langchain/chat_models/base.py::init_chat_model` — **P1**, model-string resolution.
5. Built-in middleware — **P2**, each is a self-contained feature; port on demand.
6. `_subagent_transformer.py` — **P3**, multi-agent streaming; defer.

## State Checkpoint
```yaml
pass: 3
artifact: module-inventory
status: complete
files_scanned: 33 source (full reads of factory, types, structured_output, chat_models/base, all __init__; surveyed 15 middleware <!-- [validation-corrected pass-4]: "13 middleware" was stale metadata from original analysis pass; actual count is 15 as corrected in passes 1-3 -->)
timestamp: 2026-07-12
```
</content>
</invoke>
