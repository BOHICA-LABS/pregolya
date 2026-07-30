---
artifact: semport/langchain/behavioral-intent
project: pregolya
port_target: langchain (v1)
analyzer_pass: 3
date: 2026-07-12
---

# langchain (v1) — Behavioral Intent

Grounded in `agents/factory.py`, `agents/middleware/types.py`,
`agents/structured_output.py`, `chat_models/base.py`. Confidence: HIGH where quoted from
source + confirmed by named tests; MEDIUM where inferred from code flow.

---

## 1. `create_agent` — full behavioral contract

### 1.1 Signature and parameters (factory.py:808)

```python
def create_agent(
    model: str | BaseChatModel,
    tools: Sequence[BaseTool | Callable | dict] | None = None,
    *,
    system_prompt: str | SystemMessage | None = None,
    middleware: Sequence[AgentMiddleware] = (),
    response_format: ResponseFormat | type | dict | None = None,
    state_schema: type[AgentState] | None = None,
    context_schema: type[ContextT] | None = None,
    checkpointer: Checkpointer | None = None,
    store: BaseStore | None = None,
    interrupt_before: list[str] | None = None,
    interrupt_after: list[str] | None = None,
    debug: bool = False,
    name: str | None = None,
    cache: BaseCache | None = None,
    transformers: Sequence[TransformerFactory] | None = None,
) -> CompiledStateGraph[AgentState[ResponseT], ContextT, InputAgentState, OutputAgentState[ResponseT]]
```

Three `@overload`s vary the return's `ResponseT` by `response_format` shape (None → Any;
raw dict → `dict[str,Any]`; schema/`ResponseFormat` → inferred `ResponseT`).

**It returns a compiled langgraph graph, not an agent object.** Consumers call
`.invoke/.stream/.ainvoke/.astream` on the returned graph.

### 1.2 Build sequence (SCoT — sequential)

1. **Resolve model.** If `model` is a `str`, call `init_chat_model(model)` (§4).
2. **Normalize system prompt** to `SystemMessage | None`.
3. **Resolve response_format** → `initial_response_format`: raw schema wrapped in
   `AutoStrategy`; `AutoStrategy` eagerly converted to a `ToolStrategy` "for setup" so
   structured-output tools can be materialized up front (may be swapped to
   `ProviderStrategy` later at model-bind time based on model capability).
4. **Materialize structured-output tools** from `tool_strategy_for_setup.schema_specs`
   into `structured_output_tools: dict[name, OutputToolBinding]`.
5. **Collect middleware tools** (`m.tools`) and partition `tools` into `built_in_tools`
   (dicts = provider tools) and `regular_tools` (BaseTool/callables).
6. **Compose middleware handlers** for the 4 wrappable hooks:
   - `wrap_tool_call` / `awrap_tool_call` → `_chain_tool_call_wrappers` (first = outermost)
   - `wrap_model_call` / `awrap_model_call` → `_chain_model_call_handlers` (first = outermost)
   Each handler is wrapped in `langsmith.traceable(...)` with `_scrub_inputs` before composition.
7. **Build the `ToolNode`** (langgraph prebuilt) from `middleware_tools + regular_tools`,
   passing the composed `wrap_tool_call`/`awrap_tool_call`. Created iff there are
   client-side tools OR a wrap_tool_call wrapper exists.
8. **Validate middleware uniqueness** — duplicate `m.name` → `AssertionError`.
9. **Partition middleware by which hooks they override** (compares
   `m.__class__.hook is not AgentMiddleware.hook`) into 8 lists: before_agent,
   before_model, after_model, after_agent (built after uniqueness check), plus
   wrap_model_call sync, awrap_model_call async, wrap_tool_call sync, awrap_tool_call async
   (built before the ToolNode, as they feed into it). <!-- [validation-exhaustive]: prior said "6 lists"; actual factory.py creates 8 distinct partition lists — the 4 node-hook lists plus 4 for the 2 sync/async pairs of wrap_model_call and wrap_tool_call (middleware_w_wrap_tool_call at ~1010, middleware_w_awrap_tool_call at ~1031, middleware_w_wrap_model_call at ~1110, middleware_w_awrap_model_call at ~1119) -->
10. **Resolve state schema** — merge every `m.state_schema` (registration order) + the
    base (`state_schema` or `AgentState`, last so it wins conflicts) via `_resolve_schemas`,
    producing `(resolved_state_schema, input_schema, output_schema)` as dynamic `TypedDict`s.
    `OmitFromSchema` annotations drop fields from input/output schemas.
11. **Create `StateGraph`**, add nodes and edges (§1.3–1.4).
12. **Compile** with `checkpointer, store, interrupt_before, interrupt_after, debug,
    name, cache, transformers=[ToolCallTransformer, SubagentTransformer, *middleware_transformers, *transformers]`
    and `.with_config({recursion_limit: 9999, metadata:{ls_integration:"langchain_create_agent", lc_agent_name:name}})`.

### 1.3 Graph nodes

- `"model"` — a `RunnableCallable(model_node, amodel_node, trace=False)`. Core loop body.
- `"tools"` — the langgraph `ToolNode` (only if tools exist).
- `"{m.name}.before_agent"`, `"{m.name}.before_model"`, `"{m.name}.after_model"`,
  `"{m.name}.after_agent"` — one node per middleware **per overridden hook**, each a
  `RunnableCallable(sync_or_None, async_or_None, trace=False)` with
  `input_schema=resolved_state_schema`.

`wrap_model_call` / `wrap_tool_call` are **NOT nodes** — they are composed handler
closures invoked *inside* the `model` node and `ToolNode` respectively.

### 1.4 Graph edges — the agent loop (SCoT — branch/loop)

Node role classification:
- **entry_node** (runs once): first `before_agent` → else first `before_model` → else `model`.
- **loop_entry_node** (loop head): first `before_model` → else `model`.
- **loop_exit_node** (loop tail, runs each iter): first `after_model` → else `model`.
- **exit_node** (runs once at end): last `after_agent` → else `END`.

Edges:
- `START → entry_node`.
- **before_agent chain**: pairwise edges; last → `loop_entry_node`.
- **before_model chain**: pairwise edges; last → `"model"`.
- **after_model chain**: `"model" → last after_model`; then reverse-chained.
- **after_agent chain**: reverse-chained; first → `END`.
- **`tools` conditional edge** (`_make_tools_to_model_edge`): destinations
  `[loop_entry_node]` (+`exit_node` if any tool has `return_direct` or structured tools).
- **`loop_exit_node` conditional edge** (`_make_model_to_tools_edge`): destinations
  `["tools", exit_node]` (+`loop_entry_node` if response_format or after_model present).
- If **no tools but structured output**: `_make_model_to_model_edge` loops model↔model
  until a `structured_response` appears in state.
- Middleware nodes with `can_jump_to` (from `@hook_config` / decorator) get conditional
  `jump_edge`s that resolve `state["jump_to"]` ∈ {model, tools, end} → node.

**The classic agent loop** (`_make_model_to_tools_edge`, factory.py:1846):
1. If `state["jump_to"]` set → resolve jump (model/tools/end).
2. Find last `AIMessage` + subsequent `ToolMessage`s. If none → `end`.
3. If `len(tool_calls) == 0` → `end` (classic stop condition).
4. Compute pending tool calls (not yet answered, not structured-output tools). If any →
   emit `[Send("tools", [tool_call]) …]` (one Send per call — **parallel tool fan-out**).
5. If `"structured_response" in state` → `end`.
6. Else (artificial tool messages injected, e.g. HITL) → back to model.

`tools_to_model` (factory.py:1928): if all executed client-side tools have
`return_direct=True` → `end`; if any structured-output tool executed → `end`; else → model.

### 1.5 Model node behavior (`model_node` / `amodel_node`, factory.py:1433)

1. Build a `ModelRequest(model, tools=default_tools, system_message, response_format=
   initial_response_format, messages=state["messages"], tool_choice=None, state, runtime)`.
2. If no `wrap_model_call` handler → call `_execute_model_sync(request)` directly.
   Else → `wrap_model_call_handler(request, _execute_model_sync)`.
3. `_build_commands(model_response, commands)` → returns `list[Command]`: first Command
   is `{update:{messages:[...], structured_response?:...}}`; middleware commands appended.
   `Command.goto/resume/graph` are **rejected** in wrap_model_call (NotImplementedError).

`_execute_model_sync` (factory.py:1406):
1. `_get_bound_model(request)` → `(bound_runnable, effective_response_format)`.
2. Prepend `system_message` to messages if present.
3. `output = model_.invoke(messages)`; set `output.name = name` if agent named.
4. `_handle_model_output(output, effective_response_format)` → dict with `messages` and
   optional `structured_response`.
5. Wrap in `ModelResponse(result=messages_list, structured_response=...)`.

`_get_bound_model` (factory.py:1272) — **model binding + strategy auto-detection**:
- Validates request.tools are known client-side tools (skipped if wrap_tool_call present,
  since middleware may add dynamic tools) → else `ValueError` (DYNAMIC_TOOL_ERROR_TEMPLATE).
- Normalizes raw schema in `request.response_format` to `AutoStrategy`.
- If `AutoStrategy`: `_supports_provider_strategy(model, tools)` → `ProviderStrategy`
  (model profile says `structured_output`, with a Gemini-<3 tools-exclusion carve-out, or
  name matches `FALLBACK_MODELS_WITH_STRUCTURED_OUTPUT` regexes) else `ToolStrategy`.
- **ProviderStrategy bind**: `model.bind_tools(final_tools, **to_model_kwargs(),
  **model_settings)`, with `strict=True` forced for OpenAI-compatible models.
- **ToolStrategy bind**: appends structured tools, validates they were declared upfront
  (else ValueError), forces `tool_choice="any"` if structured tools exist.
- **No structured output**: `bind_tools(final_tools, tool_choice)` or `model.bind()`.

### 1.6 Structured-output integration in the main loop (`_handle_model_output`, factory.py:1168)

- **ProviderStrategy + no tool_calls**: `ProviderStrategyBinding.parse(output)` (extract
  text, `json.loads`, validate against schema) → set `structured_response`; on failure
  raise `StructuredOutputValidationError`.
- **ToolStrategy + tool_calls that match structured_output_tools**:
  - >1 structured tool call → `MultipleStructuredOutputsError`; if `handle_errors` allows,
    inject retry ToolMessages instead of raising.
  - exactly 1 → `OutputToolBinding.parse(tool_call["args"])` → set `structured_response`
    + append a synthetic ToolMessage (content from `tool_message_content` or default). On
    parse failure → `StructuredOutputValidationError`, or retry ToolMessage per
    `_handle_structured_output_error` policy.
- **Key intent:** structured output is produced **inside the same model turn**, either
  from provider-native JSON or from an injected tool call — **no separate extraction LLM
  call** (this is the v1 change vs. classic).

### 1.7 Streaming behavior
- The compiled graph inherits langgraph streaming (`stream_mode` ∈ updates/values/
  messages/custom/…). `create_agent` registers stream transformers:
  `ToolCallTransformer` (langgraph prebuilt), `SubagentTransformer` (own, surfaces nested
  named agents on `run.subagents`), then middleware-declared, then caller-supplied.
- Middleware may emit custom stream events via `runtime.stream_writer(...)` in any hook
  (documented in decorator docstrings; `stream_mode="custom"`).
- Token-level model streaming is delegated to langgraph's `messages` stream mode; the
  model node itself calls `model_.invoke` (not `.stream`) — token streaming is a graph
  concern, not a create_agent concern.

**BC-DRAFT-CA-001: Agent loops model→tools until no tool calls.**
Preconditions: model bound with tools; AIMessage may contain tool_calls.
Postconditions: loop repeats model↔tools while pending tool calls exist; exits to
after_agent/END when tool_calls empty, all return_direct, or structured_response set.
Evidence: `test_react_agent.py` (987 LOC), `_make_model_to_tools_edge`. Confidence: HIGH.

**BC-DRAFT-CA-002: `recursion_limit` defaults to 9,999.** Evidence: factory.py:1780.
Confidence: HIGH.

**BC-DRAFT-CA-003: Structured output requires no extra LLM call.**
Evidence: `_handle_model_output` runs inline in the model node; `test_response_format.py`
(1,018 LOC). Confidence: HIGH.

---

## 2. Middleware system — hook-point inventory & composition

### 2.1 The 10 hooks (`AgentMiddleware`, types.py:383)

| Hook (sync / async) | Signature | Return | Where it runs | Can jump? |
|---|---|---|---|---|
| `before_agent` / `abefore_agent` | `(state, runtime)` | `dict[str,Any]\|None` <!-- [validation-exhaustive]: original said `dict\|Command\|None`; actual type annotation in types.py:419,431 is `dict[str, Any] | None`; `Command` is NOT in the declared return type of any node hook; control flow is communicated via `{"jump_to": "model"|"tools"|"end"}` dict key, not by returning a Command object --> | node, once at start | yes (`can_jump_to`) |
| `before_model` / `abefore_model` | `(state, runtime)` | `dict[str,Any]\|None` <!-- [validation-exhaustive]: same fix; see types.py:443,454 --> | node, each loop head | yes |
| `wrap_model_call` / `awrap_model_call` | `(request, handler)` | `ModelResponse\|AIMessage\|ExtendedModelResponse` | **closure inside model node** | no (via Command rejected) |
| `after_model` / `aafter_model` | `(state, runtime)` | `dict[str,Any]\|None` <!-- [validation-exhaustive]: same fix; see types.py:467,478 --> | node, each loop tail | yes |
| `wrap_tool_call` / `awrap_tool_call` | `(request, handler)` | `ToolMessage\|Command` | **closure inside ToolNode** | n/a |
| `after_agent` / `aafter_agent` | `(state, runtime)` | `dict[str,Any]\|None` <!-- [validation-exhaustive]: same fix; see types.py:638,649 --> | node, once at end | yes |

Plus class attributes: `state_schema: type[StateT]` (default `_DefaultAgentState`),
`tools: Sequence[BaseTool]`, `transformers: Sequence[TransformerFactory]`,
`name: str` (property, defaults to class name).

**Execution order for one loop iteration:**
`before_agent* → [before_model* → (wrap_model_call outer→inner→ model → inner→outer) →
after_model*] (loop) → after_agent*`, with `wrap_tool_call` wrapping each tool execution
inside the tools node.

### 2.2 Composition semantics (HIGH confidence — directly from `_chain_*` fns)

- **Node hooks** (before_*/after_*): ordered as **distinct graph nodes**. before_* chains
  in registration order; after_* chains in **reverse** (outer-most middleware's after_model
  runs last). Each contributes conditional `jump_edge`s only if it declares `can_jump_to`.
- **`wrap_model_call`**: composed by `_chain_model_call_handlers` such that **first in list
  = outermost layer**. Each layer receives a `handler` callback; can call it 0..N times
  (short-circuit / retry). Commands accumulate **inner-first then outer** without merging
  (`_ComposedExtendedModelResponse.commands`). `inner_handler` **clears accumulated
  commands on each call** (retry safety). `AIMessage` return auto-normalizes to
  `ModelResponse`; `ExtendedModelResponse` carries an optional `Command`.
- **`wrap_tool_call`**: composed by `_chain_tool_call_wrappers`, first = outermost; each
  wraps a `call_inner` closure; outer may call inner multiple times (retry).
- **Sync/async duality**: a middleware may implement only sync or only async; calling the
  wrong context raises a descriptive `NotImplementedError` (types.py:574 etc.). The factory
  includes a middleware in *both* the sync and async wrapper lists if it overrides *either*
  variant, so the NotImplementedError surfaces at call time.

### 2.3 State extension by middleware (HIGH)
Each middleware declares `state_schema` (a TypedDict subclass of `AgentState`). The factory
**merges all middleware state schemas + base** into one `resolved_state_schema`
(`_resolve_schemas`). Fields use langgraph annotations: `add_messages` reducer for
`messages`, `EphemeralValue` for `jump_to`, `OmitFromSchema` to hide fields from
input/output. Examples: `ModelCallLimitState`, `ToolCallLimitState`, `PlanningState`
(todos), `ShellToolState`. This is how middleware adds durable custom state without the
caller writing a schema.

### 2.4 `ModelRequest` / `ModelResponse` (types.py:85, :270)
- `ModelRequest` (dataclass, immutable pattern): `model, messages, system_message,
  tool_choice, tools, response_format, state, runtime, model_settings`. `.override(**)`
  returns a *new* request via `dataclasses.replace`. Direct attribute assignment is
  deprecated (warns). `system_prompt` is a compat property over `system_message`.
- `ModelResponse[ResponseT]`: `result: list[BaseMessage]` + `structured_response:
  ResponseT|None`.
- `ExtendedModelResponse`: `model_response` + optional `command: Command` (applied via
  graph reducers as an additional state update; messages ADD not replace).

### 2.5 Decorators (types.py) — synthesize middleware from functions
`before_agent, after_agent, before_model, after_model` (state+runtime fns, support
`can_jump_to`, `state_schema`, `tools`, `name`), `wrap_model_call`, `wrap_tool_call`
(request+handler fns), `dynamic_prompt` (fn returning str/SystemMessage → sets
`request.system_message` then calls handler; implemented over wrap_model_call),
`hook_config` (attaches `__can_jump_to__` metadata). Each builds an `AgentMiddleware`
subclass at runtime with `type(name, (AgentMiddleware,), {...})()`. `iscoroutinefunction`
picks the sync vs async slot.

### 2.6 Built-in middleware behavioral summary (MEDIUM — from class/hook survey + docstrings)

- **SummarizationMiddleware** (`before_model`): when history exceeds a token/message
  threshold (`TriggerClause`), summarize older messages via a model call and replace them,
  using `REMOVE_ALL_MESSAGES` sentinel from langgraph.
- **HumanInTheLoopMiddleware** (`after_model` + langgraph `interrupt`/`get_config`):
  before executing configured tool calls, raise a langgraph `interrupt(HITLRequest)`;
  resume with human decisions (approve/edit/reject/respond) that rewrite tool calls.
- **PIIMiddleware** (`before_model`+`after_model`+stream transformer): detect/redact PII
  entities in messages and streamed tokens; can raise `PIIDetectionError`.
- **ContextEditingMiddleware** (`wrap_model_call`): edit context (e.g. clear old tool
  results — `ClearToolUsesEdit`) before the model call.
- **FilesystemFileSearchMiddleware** (registers tools): adds file-search tools.
- **ModelCallLimitMiddleware** (`before_model`+`after_model`, adds state): cap model calls
  per thread/run; raise `ModelCallLimitExceededError` or jump to end.
- **ModelFallbackMiddleware** (`wrap_model_call`): on model error, retry request against
  fallback models in order.
- **ModelRetryMiddleware** (`wrap_model_call`): retry model call with backoff (`_retry.py`).
- **ProviderToolSearchMiddleware** (`wrap_model_call`): inject provider server-side tool
  search specs.
- **ShellToolMiddleware** (`before_agent`+`after_agent`, adds state+tool): manage a shell
  session; execute commands under Host/Docker/Codex sandbox policies.
- **TodoListMiddleware** (`wrap_model_call`+`after_model`, adds state+tool): expose a
  write-todos planning tool + inject plan into prompt.
- **ToolCallLimitMiddleware** (`after_model`, adds state): cap tool calls; raise
  `ToolCallLimitExceededError`.
- **LLMToolEmulator** (`wrap_tool_call`): emulate a tool's output with an LLM instead of
  executing it (testing/sandbox).
- **ToolRetryMiddleware** (`wrap_tool_call`): retry failed tool calls with backoff.
- **LLMToolSelectorMiddleware** (`wrap_model_call`): use an LLM to down-select which tools
  to expose to the main model.

---

## 3. Structured output strategies (structured_output.py) — HIGH

- `_SchemaSpec` normalizes any of {pydantic BaseModel, dataclass, TypedDict, JSON-schema
  dict} → `{schema, name, description, schema_kind, json_schema, strict}`. Name from
  `__name__`/`title`/generated uuid; description from docstring/`description`.
- `ToolStrategy(schema, tool_message_content, handle_errors)`: `schema_specs` computed by
  flattening `Union`/`oneOf` variants. `handle_errors` ∈ {True | str | ExcType |
  tuple[ExcType] | Callable[[Exc],str] | False} controls retry-vs-raise.
- `ProviderStrategy(schema, strict)`: `.to_model_kwargs()` → OpenAI-style
  `{response_format:{type:json_schema, json_schema:{name, schema, strict?}}}`.
- `AutoStrategy(schema)`: placeholder resolved at bind time (§1.5).
- `OutputToolBinding.from_schema_spec` → builds a `StructuredTool(args_schema=json_schema,
  name, description)`; `.parse(args)` → `TypeAdapter(schema).validate_python`.
- `ProviderStrategyBinding.parse(AIMessage)` → extract text, `json.loads`, validate.
- Errors: `StructuredOutputError` (base, carries `ai_message`), `MultipleStructuredOutputsError`,
  `StructuredOutputValidationError`.

---

## 4. `init_chat_model` / `_ConfigurableModel` (chat_models/base.py) — HIGH

- **`_BUILTIN_PROVIDERS`**: 27 providers <!-- [validation-corrected pass-2]: original said 30; pass-1 corrected to 33; actual AST/regex parse of langchain_v1/langchain/chat_models/base.py lines 38-78 confirms 27 dict keys. Pass-1 overcounted because it matched continuation-line value strings (e.g. "langchain_google_vertexai.model_garden", "langchain_huggingface", "langchain_ibm") as if they were keys. --> → `(module_path, class_name, creator_func)`.
  `_get_chat_model_creator` lru-caches import + `functools.partial(creator, cls)`.
  Ollama has a `langchain_community` fallback.
- **Provider inference** (`_attempt_infer_model_provider`): prefix rules (`gpt-/o1/o3/
  chatgpt/text-davinci`→openai, `claude`→anthropic, `accounts/fireworks`→fireworks <!-- [validation-exhaustive]: prior passes omitted this rule; actual code base.py:556 has `if model_lower.startswith("accounts/fireworks"): return "fireworks"` as the 4th branch -->, `gemini`→google_vertexai w/ deprecation
  warning, `command`→cohere, `mistral/mixtral`→mistralai, `deepseek`, `grok`→xai,
  `sonar`→perplexity, `solar`→upstage, `amazon./anthropic./meta.`→bedrock). `provider:model`
  syntax parsed by `_parse_model`.
- **`_ConfigurableModel(Runnable[LanguageModelInput, Any])`**: when no fixed model, defers
  construction. `__getattr__` queues declarative ops (`bind_tools`,
  `with_structured_output`) and delegates other attrs to the built model. `_model(config)`
  builds `_init_chat_model_helper(**{default, **config-derived params})` then replays queued
  ops. Config keys namespaced by `config_prefix`. Implements the full Runnable surface
  (invoke/ainvoke/stream/astream/batch*/transform/astream_log/astream_events) by delegating.
- `init_embeddings` mirrors this with 10 providers <!-- [validation-corrected pass-2]: original said 11; pass-1 corrected to 14; actual parse of langchain_v1/langchain/embeddings/base.py lines 15-55 confirms 10 dict keys. Same over-count method as the chat provider error. --> (embeddings/base.py).

**Port note:** `_ConfigurableModel` is a Runnable façade doing lazy model construction +
declarative-op replay. In Rust this is a builder that captures a
`FnOnce(config)->ChatModel` + a queue of `bind_tools`/`with_structured_output` closures.

---

## 5. THE langgraph API surface consumed (KEY ARCHITECTURE INPUT)

This is the **minimum pregolya-graph public API** that the v1 `langchain` crate needs.
Extracted from all `from langgraph…` imports in `langchain/` (non-test).

### 5.1 Graph construction & compilation
| langgraph symbol | Import | Used by | Purpose |
|---|---|---|---|
| `StateGraph` | `langgraph.graph.state` | factory | Build the agent graph (nodes, edges, schemas) |
| `CompiledStateGraph` | `langgraph.graph.state` | factory (type) | Return type of `create_agent` |
| `START`, `END` | `langgraph.constants` | factory | Edge sentinels |
| `StateGraph.add_node/add_edge/add_conditional_edges/compile` | (methods) | factory | Wire the loop |
| `.compile(checkpointer, store, interrupt_before, interrupt_after, debug, name, cache, transformers)` | | factory | Compilation options |
| `.with_config(config)` | | factory | Attach recursion_limit + metadata |

### 5.2 State channels & reducers
| Symbol | Import | Used by | Purpose |
|---|---|---|---|
| `add_messages` | `langgraph.graph.message` | types, factory | messages reducer |
| `REMOVE_ALL_MESSAGES` | `langgraph.graph.message` | summarization | clear-history sentinel |
| `EphemeralValue` | `langgraph.channels.ephemeral_value` | types | `jump_to` channel (per-step) |
| `UntrackedValue` | `langgraph.channels.untracked_value` | (3 middleware) | non-checkpointed state channel |

### 5.3 Runtime, control flow, types
| Symbol | Import | Used by | Purpose |
|---|---|---|---|
| `Runtime[ContextT]` | `langgraph.runtime` | types + all middleware (11 imports) | Per-invocation context (`.context`, `.stream_writer`, `.store`) passed to every hook |
| `Command` | `langgraph.types` | factory, types, middleware | State-update / control-flow command from nodes |
| `Send` | `langgraph.types` | factory | Fan-out to parallel tool executions |
| `interrupt` | `langgraph.types` | human_in_the_loop | Pause for human input |
| `Checkpointer` | `langgraph.types` (type) | factory | Persistence handle |
| `get_config` | `langgraph.config` | human_in_the_loop | Read current RunnableConfig |
| `ContextT` | `langgraph.typing` | types | Context type var |
| `GraphBubbleUp` | `langgraph.errors` | (a middleware) | Control-flow exception to propagate |

### 5.4 Prebuilt tool execution
| Symbol | Import | Used by | Purpose |
|---|---|---|---|
| `ToolNode` | `langgraph.prebuilt.tool_node` | factory | Executes tool calls; `.tools_by_name`, `return_direct`, `wrap_tool_call`/`awrap_tool_call` params |
| `ToolCallRequest` | `langgraph.prebuilt.tool_node` | types, tool_node | wrap_tool_call request (`.tool_call`, `.state`, `.runtime`, `.override`) |
| `ToolCallWrapper` | `langgraph.prebuilt.tool_node` | types | wrap_tool_call type |
| `ToolCallWithContext` | `langgraph.prebuilt.tool_node` | tools/tool_node | (re-export) |
| `ToolCallTransformer` | `langgraph.prebuilt` | factory | Default stream transformer |
| `ToolRuntime` | `langgraph.prebuilt` / `.tool_node` | tools | Runtime injected into tools |
| `InjectedState`, `InjectedStore` | `langgraph.prebuilt` | tools | Tool-arg injection markers |

### 5.5 Streaming internals (the deepest coupling — subagent transformer)
| Symbol | Import | Used by | Purpose |
|---|---|---|---|
| `StreamTransformer` | `langgraph.stream` | pii, (base) | Base class for stream transformers |
| `TransformerFactory` | `langgraph.stream._mux` | types, factory (type) | `factory(scope)` producing a transformer |
| `StreamMux` | `langgraph.stream._mux` | subagent (type) | Stream multiplexer |
| `SubgraphRunStream`, `AsyncSubgraphRunStream` | `langgraph.stream.run_stream` | subagent | Base handles for nested runs |
| `StreamChannel` | `langgraph.stream.stream_channel` | subagent | Stream channel |
| `SubgraphStatus`, `_TasksLifecycleBase` | `langgraph.stream.transformers` | subagent | Lifecycle transformer base |
| `ProtocolEvent` | `langgraph.stream._types` | (2, type) | Stream event type |
| `RunnableCallable` | `langgraph._internal._runnable` | factory | Sync/async dual node wrapper |

### 5.6 Persistence & cache (types only)
| Symbol | Import | Purpose |
|---|---|---|
| `BaseStore` | `langgraph.store.base` | Cross-thread store param |
| `BaseCache` | `langgraph.cache.base` | Execution cache param |

**Architecture takeaway:** pregolya-graph MUST expose, at minimum: `StateGraph`
(add_node/add_edge/add_conditional_edges/compile/with_config), `CompiledStateGraph`,
START/END, `Command`+`Send`, `Runtime`, `add_messages` + channel types
(Ephemeral/Untracked), `interrupt`+`get_config`, `Checkpointer`/`BaseStore`/`BaseCache`
handles, `RunnableCallable`, and the `ToolNode` prebuilt with a wrap_tool_call seam. The
**stream-transformer internals (§5.5) are the riskiest surface** — they are private
(`_mux`, `_internal`, `_types`) langgraph APIs. Recommend the graph analyzer treat these
as the boundary; `_subagent_transformer.py` can be deferred (P3) so pregolya-graph need
not expose stream internals in v1.

## State Checkpoint
```yaml
pass: 3
artifact: behavioral-intent
status: complete
timestamp: 2026-07-12
```
</content>
