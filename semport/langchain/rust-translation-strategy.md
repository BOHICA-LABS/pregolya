---
artifact: semport/langchain/rust-translation-strategy
project: ferrochain
port_target: langchain (v1) → ferrochain (the crate)
analyzer_pass: 3
date: 2026-07-12
note: strategy only — NO Rust code committed; signatures are illustrative sketches
consistency: aligned with .factory/semport/core/rust-translation-strategy.md (async-first,
  dyn+boxed futures at plugin seams, generics on hot paths, serde-tagged enums,
  tower::Service-shaped Runnable). Depends on ferrochain-graph (separate analyzer).
---

# langchain (v1) → ferrochain — Translation Strategy

Difficulty scale: 🟢 easy · 🟡 moderate · 🟠 hard · 🔴 very hard / research-grade.

The v1 crate is **an orchestration layer over ferrochain-core + ferrochain-graph**. Its
own hard problems are: (1) the middleware trait + composition, (2) the create_agent graph
builder, (3) structured-output schema handling, (4) runtime-synthesized middleware
decorators. Everything else is thin registry/factory glue.

---

## 1. Middleware system — 🔴 very hard (the keystone of this crate)

Python has one base class with 10 overridable hooks; the factory partitions middleware by
"did you override this hook" using `method is not BaseClass.method` identity checks. Rust
has no method-override-detection at runtime, so the design must invert this.

Proposed shape (illustrative):
```
#[async_trait]
trait Middleware<Ctx, Resp>: Send + Sync {
    fn name(&self) -> &str;
    fn state_schema(&self) -> StateSchema { StateSchema::default() }
    fn tools(&self) -> &[ToolRef] { &[] }
    // node hooks — default None means "not registered"
    async fn before_agent(&self, s: &State, rt: &Runtime<Ctx>) -> Option<HookResult> { None }
    async fn before_model(&self, s: &State, rt: &Runtime<Ctx>) -> Option<HookResult> { None }
    async fn after_model (&self, s: &State, rt: &Runtime<Ctx>) -> Option<HookResult> { None }
    async fn after_agent (&self, s: &State, rt: &Runtime<Ctx>) -> Option<HookResult> { None }
    fn before_model_jumps(&self) -> &[JumpTo] { &[] }  // replaces @hook_config.can_jump_to
    // wrap hooks — Option return signals "not implemented" (replaces NotImplementedError)
    fn provides_wrap_model_call(&self) -> bool { false }
    async fn wrap_model_call(&self, req: ModelRequest<Ctx>, next: ModelHandler<'_,Ctx>)
        -> Result<ModelCallResult<Resp>, Error> { unreachable!() }
    fn provides_wrap_tool_call(&self) -> bool { false }
    async fn wrap_tool_call(&self, req: ToolCallRequest, next: ToolHandler<'_>)
        -> Result<ToolCallOutcome, Error> { unreachable!() }
}
```
- **Override detection → capability flags.** Python's `m.__class__.hook is not
  AgentMiddleware.hook` becomes `provides_*()`/non-empty hook-set. The factory's 6
  partition lists become filters on these flags. 🟠
- **Sync/async duality collapses to async-first** (per core strategy). Python's dual
  sync+async hooks and the `NotImplementedError`-on-wrong-context machinery are **deleted**
  — a Rust middleware implements the async method; blocking callers use a `block_on`
  wrapper at the graph boundary. This eliminates ~40% of `types.py`.
- **wrap_model_call composition** (`_chain_model_call_handlers`) → **`tower::Layer`-style
  onion** or a hand-rolled `Vec<Arc<dyn Middleware>>` folded so first=outermost. `next` is
  a boxed async closure (`ModelHandler = Box<dyn Fn(ModelRequest)->BoxFuture<ModelResponse>>`).
  Middleware may call `next` 0..N times (retry/short-circuit). **Command accumulation**
  (inner-first-then-outer, cleared per inner call for retry safety) must be ported exactly —
  it is test-locked in `core/test_wrap_model_call_state_update.py`. 🔴
- **ExtendedModelResponse.command** applied via graph reducers → depends on
  ferrochain-graph's `Command`/reducer model. The `goto/resume/graph` rejection is a simple
  guard.
- **dynamic_prompt** = a thin wrap_model_call that overrides `request.system_message` then
  calls next — trivial once wrap_model_call exists.

**Open design questions:** (a) capability flags vs a registration enum
(`HookSet` bitflags) to drive node/edge construction; (b) the boxed `next` closure's
lifetime/`Send` bounds under `async_trait`; (c) how ExtendedModelResponse Commands compose
with ferrochain-graph reducers.

## 2. create_agent graph builder — 🔴 very hard (but mostly delegation)

`create_agent` is a **graph-construction function**; its difficulty is 90% in the
ferrochain-graph API it targets, 10% in the wiring logic (which is deterministic and
test-locked in `core/test_framework.py` + `test_react_agent.py`).

- Return type: `CompiledGraph<...>` from ferrochain-graph. The **3 Python overloads** keyed
  on `response_format` collapse in Rust to **generics**: `create_agent::<Resp>(...)` with
  `Resp = ()` (no structured output), `serde_json::Value` (raw dict), or a typed `T:
  DeserializeOwned + JsonSchema`. Use a builder (`AgentBuilder`) rather than a 14-param fn
  with keyword args. 🟠
- **Node/edge wiring** (entry/loop_entry/loop_exit/exit node selection, before/after
  chains, conditional edges, jump edges) is pure logic → port faithfully. The edge closures
  (`_make_model_to_tools_edge` etc.) become Rust `Fn(&State)->EdgeTarget`. 🟡 — but MUST be
  byte-faithful (golden-tested).
- **`recursion_limit=9999`, metadata** → config passed to `.compile().with_config()`.
- **Model node** = a graph node holding the composed wrap_model_call onion + the
  `execute_model` core (bind model, prepend system message, invoke, handle output).
- **RunnableCallable(sync, async)** dual-wrapper → in async-first Rust just an async node fn.

**Open design question:** how much of `create_agent`'s wiring can be generic over the graph
crate vs. must know concrete ferrochain-graph node/edge types. Recommend create_agent
depends only on ferrochain-graph's *public* `StateGraph` builder API (behavioral-intent.md
§5.1–5.4); it must NOT touch stream internals (§5.5).

## 3. Structured output — 🟠 hard (schema generation is the crux)

- `ToolStrategy` / `ProviderStrategy` / `AutoStrategy` → an `enum ResponseFormat<T>`
  (serde-friendly). `AutoStrategy` resolution (`_supports_provider_strategy`: model profile
  + fallback regex list) is pure logic → port; the regex list
  (`FALLBACK_MODELS_WITH_STRUCTURED_OUTPUT`) is data → port as `&[&str]` + `regex`. 🟡
- `_SchemaSpec` normalizes {pydantic, dataclass, TypedDict, JSON-schema} → In Rust the four
  input kinds collapse to **two**: a Rust type `T: JsonSchema` (via `schemars`) or a raw
  `serde_json::Value` JSON-schema. `schema_kind` enum keeps {typed, json_schema}. **This is
  the pydantic→schemars boundary** flagged in core strategy §6 — the emitted JSON schema
  must be accepted by providers; golden-test against pydantic output. 🟠
- `OutputToolBinding.parse` (`TypeAdapter.validate_python`) → `serde_json::from_value::<T>`.
- `ProviderStrategyBinding.parse` (extract text → json.loads → validate) → port text
  extraction from content blocks + `serde_json`. 🟡
- `to_model_kwargs()` (OpenAI `response_format:{type:json_schema,...}`) → a typed struct
  serialized to the provider bind-kwargs. 🟢
- Error types (`StructuredOutputError`/`Multiple…`/`Validation…`) → `thiserror` enum
  carrying the offending message. 🟢
- `handle_errors` union (`bool|str|ExcType|tuple|Callable`) → a Rust enum
  `HandleErrors { All, Message(String), Types(Vec<ErrKind>), Custom(Box<dyn Fn>), None }`. 🟡

## 4. init_chat_model / init_embeddings — 🟡 moderate

- `_BUILTIN_PROVIDERS` → static registry: `HashMap<&str, ProviderCtor>` where
  `ProviderCtor` is a fn behind a cargo feature per provider. Lazy `importlib` →
  **compile-time feature gates** (no runtime import). PORT the registry structure;
  providers are separate crates. 🟡
- Prefix inference (`_attempt_infer_model_provider`, `_parse_model`) → pure string logic,
  straight PORT. 🟢
- **`_ConfigurableModel`** (defers construction, queues declarative ops `bind_tools`/
  `with_structured_output`, replays on `_model(config)`) → a builder capturing
  `default_config` + a `Vec<DeclarativeOp>` (enum) replayed when the concrete model is
  built. Implements the ferrochain-core `Runnable`/`ChatModel` trait by delegating to the
  built model. 🟠 — the "configurable at runtime via config keys" feature is niche; consider
  deferring the full Runnable delegation surface (batch/astream_log/astream_events) to a
  later round; v1 needs invoke/stream/bind_tools/with_structured_output.

## 5. Runtime-synthesized middleware decorators — 🟠 hard (redesign)

Python's 8 decorators use `type(name,(AgentMiddleware,),{...})()` to synthesize a class per
decorated function. Rust cannot create types at runtime. Replace with **generic wrapper
structs holding a closure**:
```
struct BeforeModelFn<F> { f: F, name: String, jumps: Vec<JumpTo>, state: StateSchema, tools: Vec<ToolRef> }
impl<F: Fn(&State,&Runtime)->Fut> Middleware for BeforeModelFn<F> { ... }
```
Provide constructor fns `before_model(f)`, `wrap_model_call(f)`, `dynamic_prompt(f)`, etc.
mirroring the decorator ergonomics. `iscoroutinefunction` branching disappears (async-only).
🟠 (mechanical but 8× repetition — a declarative macro can generate the wrappers).

## 6. Built-in middleware (15) <!-- [validation-corrected pass-2]: heading said 13; module-inventory.md was corrected to 15 in pass-1 but this file was not updated. Body list below already covers all 15. --> — 🟢–🟠 per-middleware, PORT on demand

Each is a self-contained `Middleware` impl. Port priority by value:
- **P1:** SummarizationMiddleware, ModelFallback, ModelRetry, ToolRetry (common, pure logic).
- **P2:** HumanInTheLoop (needs ferrochain-graph `interrupt`), ToolCallLimit/ModelCallLimit
  (need state extension), ContextEditing, TodoList, LLMToolSelector.
- **P3:** PII (878 LOC + stream transformer — needs redaction engine), ShellTool (sandboxes
  — heavy, `_execution.py`), ProviderToolSearch, LLMToolEmulator, FileSearch.
Shared helpers `_retry.py`/`_redaction.py`/`_execution.py` → ferrochain internal util
modules. State-adding middleware depend on ferrochain-graph's channel/reducer API.

## 7. Subagent transformer — 🔴 defer (P3)
`_subagent_transformer.py` couples to **private langgraph stream internals**
(`langgraph.stream.run_stream`, `.transformers._TasksLifecycleBase`, `._mux`). This is the
deepest, most fragile coupling. **Recommend excluding from ferrochain v1**; multi-agent
streaming (`run.subagents`) is an advanced feature. If required later, it forces
ferrochain-graph to expose stream-transformer internals — a large surface. Flag to the
graph analyzer as an explicit v1 non-goal.

## 8. Re-export modules — 🟢 trivial
`messages`, `rate_limiters`, `tools` (core parts), `chat_models.BaseChatModel`,
`embeddings.Embeddings` are pure re-exports of ferrochain-core → Rust `pub use`.

---

## Difficulty / risk summary

| Subsystem | Difficulty | Primary risk |
|---|---|---|
| Middleware trait + wrap_* composition | 🔴 | Override-detection→capability model; boxed `next` closure lifetimes; command accumulation exactness |
| create_agent graph wiring | 🔴 | Entirely gated on ferrochain-graph public API; edge logic must be byte-faithful |
| Structured output schema gen | 🟠 | schemars vs pydantic JSON-schema divergence (provider acceptance) |
| _ConfigurableModel | 🟠 | Deferred declarative-op replay + full Runnable delegation surface |
| Decorators (runtime class synth) | 🟠 | Redesign to closure-holding generics (macro-generate) |
| init_chat_model registry + inference | 🟡 | Feature-gated provider registry; inference is pure logic |
| Built-in middleware (15) <!-- [validation-corrected pass-3]: summary table still said (13); §6 heading corrected to 15 in pass-2 but this row was not updated --> | 🟢–🟠 | Per-feature; PII/Shell heaviest |
| Subagent transformer | 🔴 | Private langgraph stream internals — DEFER (v1 non-goal) |
| Re-exports | 🟢 | Mechanical |

## Cross-cutting open design questions (candidate ADRs)

1. **ADR: Middleware capability model** — how does ferrochain detect "this middleware
   registers before_model" without Python's method-identity trick? Bitflag `HookSet`,
   `provides_*()` methods, or a builder-declared registration? Drives all node/edge
   construction.
2. **ADR: wrap_model_call onion** — `tower::Layer` vs hand-rolled fold; the `Send`/lifetime
   bounds on the boxed `next` handler under `async_trait`; exact Command-accumulation +
   per-retry-clear semantics (test-locked).
3. **ADR: ferrochain-graph public API contract** — freeze the minimum surface from
   behavioral-intent.md §5.1–5.4 that create_agent targets; declare stream internals
   (§5.5) a v1 non-goal (excludes subagent transformer).
4. **ADR: state-schema composition** — Python merges TypedDicts via runtime type-hint
   reflection. Rust: static struct composition, a field-descriptor registry, or requiring
   middleware to declare state via a typed builder. Impacts every state-adding middleware.
5. **ADR: structured-output schema generation** — adopt `schemars` + a pydantic-compat
   golden-schema test suite, or hand-roll an emitter matching pydantic's output. (Shared
   with core strategy §6 ADR-2; must be decided once for both crates.)

## State Checkpoint
```yaml
pass: 3
artifact: rust-translation-strategy
status: complete
timestamp: 2026-07-12
```
</content>
