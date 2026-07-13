---
artifact: semport/core/rust-translation-strategy
project: ferrochain
port_target: langchain-core (P0)
analyzer_pass: 1
date: 2026-07-12
note: strategy only — NO Rust code committed; signatures are illustrative sketches
---

# langchain-core → Rust (ferrochain-core) Translation Strategy

Guiding decisions (from `langchain-research.md` §6 and confirmed by this analysis):
**async-first**, `dyn` + boxed futures at plugin seams, generics on hot paths,
serde-tagged enums for closed variant sets (messages/content blocks), and a
`tower::Service`-shaped `Runnable`.

Difficulty scale: 🟢 easy · 🟡 moderate · 🟠 hard · 🔴 very hard / research-grade.

---

## 1. Runnables (LCEL) — 🔴 very hard

The keystone. `runnables/base.py` is 6,713 LOC; `Runnable` has one abstract method
(`invoke`) and ~30 derived methods. In Rust the sync/async duality collapses to
**async-first**: there is one async core; blocking wrappers are a thin `block_on`
module, not a mirrored surface.

Proposed shape (illustrative):
```
#[async_trait]
trait Runnable: Send + Sync {
    type Input;  type Output;
    async fn invoke(&self, input: Self::Input, config: &RunnableConfig)
        -> Result<Self::Output, Error>;
    // default methods:
    async fn batch(&self, inputs: Vec<Self::Input>, cfg: &RunnableConfig)
        -> Vec<Result<Self::Output, Error>>;          // ordered, bounded concurrency
    fn stream(&self, input: Self::Input, cfg: &RunnableConfig)
        -> BoxStream<'_, Result<Chunk<Self::Output>, Error>>;
    fn transform(&self, input: BoxStream<Self::Input>, cfg: &RunnableConfig)
        -> BoxStream<Result<Chunk<Self::Output>, Error>>;
}
```
- **`tower::Service` shape**: `invoke` ≈ `Service::call`; `.with_retry`/`.with_config`
  /`.with_fallbacks` ≈ `Layer`s. Prototype the trait as Service-compatible so middleware
  (LangChain v1's customization primitive) composes for free. Open question: Service's
  `poll_ready`/backpressure vs LangChain's fire-and-forget invoke.
- **Composition**: `RunnableSequence`/`RunnableParallel` as concrete generic types;
  the `|` operator has no Rust equivalent — use a `.pipe()` builder or a `seq!`/`chain!`
  macro. Heterogeneous pipelines need `Box<dyn Runnable<Input=I, Output=O>>` — but I/O
  types must line up, so type-erased composition needs an internal `Value`
  (serde_json::Value) boundary or GATs. **This is the hardest design problem.**
- **Streaming through sequences**: `transform` returning `BoxStream` composes; token
  streaming requires every stage transform-capable. Use `async-stream` for ergonomics.
- **`RunnableConfig` threading**: see §11 — a `tokio::task_local!` replaces the Python
  ContextVar for implicit propagation across `.await` points.
- **`configurable_fields`/`configurable_alternatives`**: Python mutates attributes at
  call time via a stringly `configurable` dict. Rust: a `Configurable` trait +
  typed override map, or builder-produced closures. 🟠
- **input_schema/output_schema**: Python infers pydantic models via runtime
  reflection. Rust: `schemars::JsonSchema` derive on concrete I/O types — but generic
  `dyn` Runnables can't reflect. Likely require `JsonSchema` bounds or store schema at
  construction. 🟠

**Open design questions:** (a) type-erased heterogeneous composition — `Value` boundary
vs GAT-based typed pipelines; (b) `tower::Service` adoption depth; (c) how `stream` and
`transform` unify (LangChain has both — is `transform` the primitive and `stream` a
special case?); (d) object-safety of the trait given associated types (likely need a
separate `DynRunnable` object-safe trait with erased `Value` I/O).

---

## 2. Messages + Content Blocks — 🟡 moderate (highest-value early win)

Nearly dependency-free; maps cleanly to serde.

```
#[serde(tag = "type", rename_all = "snake_case")]
enum ContentBlock {
    Text(TextContentBlock),
    Reasoning(ReasoningContentBlock),
    ToolCall(ToolCall),
    #[serde(rename="tool_call_chunk")] ToolCallChunk(ToolCallChunk),
    InvalidToolCall(InvalidToolCall),
    Image(ImageContentBlock), Video(..), Audio(..),
    #[serde(rename="text-plain")] PlainText(..), File(..),
    ServerToolCall(..), ServerToolCallChunk(..), ServerToolResult(..),
    #[serde(rename="non_standard")] NonStandard { value: serde_json::Value },
}

#[serde(tag = "type", rename_all = "snake_case")]
enum Message {
    Human(HumanMessage), Ai(AiMessage), System(SystemMessage),
    Tool(ToolMessage), Function(FunctionMessage), Chat(ChatMessage),
    Remove(RemoveMessage),
}
```
- Content field: `enum MessageContent { Text(String), Blocks(Vec<ContentBlock>) }`
  (matches `str | list[str|dict]`). Provider `extras` → `#[serde(flatten)] extras:
  Map<String, Value>` per block (matches `extra_items=Any` direction).
- `.content_blocks` (the lazy normalization view) → a method returning
  `Vec<ContentBlock>` that runs the translator pipeline. The block_translators become a
  `trait BlockTranslator` with a provider registry (`dyn` seam).
- **Chunk concatenation** → implement `Add`/an `extend`/`reduce`: port `merge_content`,
  `merge_dicts`, `merge_lists`, `add_ai_message_chunks` *exactly* (they are
  test-locked; type-mismatch → error). This reducer is 🟡 but must be byte-faithful.
- `extra="allow"` on messages → capture unknown fields (flatten map), unlike the
  default `deny`.

**Open question:** how much of the best-effort `.content_blocks` translator pipeline is
in-scope for core vs pushed to provider crates (the v0/provider translators are ~2,300
LOC and provider-coupled). Recommend: core ships the enum + the generic parse; provider
translators live with partner crates.

---

## 3. Language models — 🟠 hard

```
#[async_trait]
trait ChatModel: Runnable<Input=LanguageModelInput, Output=AiMessage> {
    async fn generate(&self, msgs: Vec<Message>, cfg: &RunnableConfig)
        -> Result<ChatResult, Error>;               // provider implements this
    fn stream(&self, ...) -> BoxStream<Result<AiMessageChunk, Error>>;
    fn bind_tools(&self, tools: Vec<ToolSpec>) -> BoundChatModel;   // returns wrapper
    fn with_structured_output<T: DeserializeOwned + JsonSchema>(&self)
        -> impl Runnable<Input=LanguageModelInput, Output=T>;
}
enum LanguageModelInput { Text(String), Messages(Vec<Message>), Prompt(PromptValue) }
```
- Sync `_generate`/`_agenerate` collapse to one async `generate`; `SimpleChatModel`
  convenience stays.
- **Caching** (`BaseCache` keyed by `(prompt, llm_string)`) → a `Cache` trait +
  in-memory impl; wrap `generate`. 🟡
- **with_structured_output**: generic over `T: DeserializeOwned + JsonSchema`; internally
  `bind_tools` with the schemars-generated schema + a tools parser. `include_raw` →
  return an enum/struct `{ raw, parsed: Option<T>, parsing_error: Option<Error> }`. 🟠
  (depends on §schema-gen ADR).
- **v3 protocol streaming** (`ChatModelStream`, replay-buffer, typed projections) → a
  `Stream` + a projection API; **defer** (immature, 2 tests). Model v2 events first.
- `_compat_bridge` (v0↔v1 output_version) → mostly ELIMINATE if the Rust port is
  v1-content-block-native; keep only what partner outputs require.

**Open question:** does core define the transport (HTTP) or purely the trait? Per
research: trait only; partner crates use `genai`/`async-openai` behind it.

---

## 4. Prompts — 🟡 moderate

- `PromptTemplate`/`ChatPromptTemplate`/`MessagesPlaceholder`/`FewShot*`/`Structured`
  as concrete Runnables (`invoke(HashMap<String,Value>) -> PromptValue`).
- Template formats: `f-string` → port the small `utils/formatting` formatter (or a
  format crate); `mustache` → MAP a Rust mustache crate or port `utils/mustache.py`
  (706 LOC); `jinja2` → `minijinja` (feature). An enum `TemplateFormat { FString,
  Mustache, Jinja2 }`.
- Input-variable auto-detection per format → parse at construction; store variable set.
- `.partial()` → builder holding bound vars. `+` concat → a `.concat()`/builder method.
- Snapshot-frozen serialization: port the `.ambr` outputs as golden fixtures.

**Open question:** f-string semantics — Python `str.format` with `{var}` and `{{`
escaping; need a faithful mini-formatter (nested attribute access `{x.y}` is used).

---

## 5. Output parsers — 🟠 hard (streaming diffs)

```
#[async_trait]
trait OutputParser: Runnable {
    type Output;
    fn parse(&self, text: &str) -> Result<Self::Output, OutputParserError>;
    fn parse_result(&self, gens: &[Generation], partial: bool)
        -> Result<Self::Output, OutputParserError>;
}
```
- `Str`, `Json` (+partial via a tolerant parser porting `parse_partial_json`),
  `Pydantic`→`Typed<T: DeserializeOwned>`, `Xml`, list parsers, tool parsers.
- **Streaming diff**: `BaseCumulativeTransformOutputParser` re-parses accumulated text
  and emits `json-patch` diffs. Port on the `json-patch` crate; the emitted patch
  sequence is observable → golden-test it. 🟠
- `OutputParserException` carries `llm_output`/`observation`/`send_to_llm` → an error
  struct with those fields (used by fixing/retry loops).

---

## 6. Tools — 🟠 hard (schema generation)

```
#[async_trait]
trait Tool: Runnable<Input=ToolInput, Output=ToolOutput> {
    fn name(&self) -> &str;  fn description(&self) -> &str;
    fn args_schema(&self) -> &JsonSchema;
    async fn run(&self, args: ToolCall, cfg: &RunnableConfig) -> Result<ToolMessage, Error>;
}
enum ToolInput { Str(String), Args(Map<String,Value>), Call(ToolCall) }
```
- `#[tool]` proc-macro replaces the `@tool` decorator: derive name/description from
  doc-comments, `args_schema` from the argument struct via `schemars`. 🟠 (macro work).
- `args_schema` validation → `serde` deserialize into the typed args struct; validation
  errors → `ToolException`/handled per `handle_tool_error` policy
  (`enum ToolErrorHandling { Raise, Message(String), Handler(Fn) }`).
- Input parsing (`str`/`dict`/`ToolCall`) → the `ToolInput` enum + `_parse_input` logic;
  ToolCall input yields a `ToolMessage` with `tool_call_id`.
- `InjectedToolArg`/`InjectedToolCallId` → params supplied by runtime, excluded from the
  model-facing schema → a `#[injected]` field attribute.
- **`convert_to_openai_tool`** (the JSON-schema emitter) is the crux — see §schema ADR.

---

## 7. Callbacks — 🟠 hard (async fan-out + run tree)

```
#[async_trait]
trait CallbackHandler: Send + Sync {
    async fn on_llm_start(&self, run: &RunContext, ...) {}
    async fn on_llm_new_token(&self, token: &str, ...) {}
    async fn on_chain_start/_end/_error(...);  // + tool/retriever/agent/custom
}
```
- All ~20 lifecycle hooks (default no-op). One async trait (sync+async merge).
- `CallbackManager` → a struct holding `Vec<Arc<dyn CallbackHandler>>`, config-merged
  (inheritable vs local). `configure()` merges from `RunnableConfig`. Handler panics
  caught (don't crash the run) unless strict.
- Run tree: each run gets a `Uuid` + `parent_run_id`; managers are scoped
  (`*ForRun`). Propagation via the task-local config (§11).
- **`dyn` seam** — this is where `async-trait` boxed futures are appropriate.

---

## 8. Documents / Retrievers / VectorStores / Embeddings — 🟢–🟡

- `Document { page_content: String, metadata: Map<String,Value>, id: Option<String> }`
  — 🟢.
- `trait Embeddings { async fn embed_documents(&self, Vec<String>) ->
  Result<Vec<Vec<f32>>>; async fn embed_query(&self, String) -> Result<Vec<f32>>; }` — 🟢.
- `trait Retriever: Runnable<Input=String, Output=Vec<Document>>` with
  `get_relevant_documents` — 🟢.
- `trait VectorStore` — `add_texts`/`similarity_search`/`from_texts` core; MMR + relevance
  normalization; `as_retriever` → `VectorStoreRetriever` with search-type enum. 🟡.
  In-memory impl: plain `Vec<f32>` cosine (avoid `ndarray` in core).

---

## 9. Load / Serialization (lc-JSON) — 🟠 hard (serde contract)

```
#[serde(tag="type")]
enum Serialized {
    #[serde(rename="constructor")] Constructor { lc: u8, id: Vec<String>, kwargs: Map<..> },
    #[serde(rename="secret")]      Secret { lc: u8, id: Vec<String> },
    #[serde(rename="not_implemented")] NotImplemented { lc: u8, id: Vec<String>, repr: Option<String> },
}
trait LcSerializable {
    fn lc_id() -> Vec<String>;            // namespace + name
    fn lc_secrets(&self) -> Map<String,String>;
    fn lc_attributes(&self) -> Map<String,Value>;
    fn is_lc_serializable() -> bool { false }   // opt-in
}
```
- Port the **field-pruning** (`_is_field_useful`) and **secret redaction/injection**
  (`_replace_secrets`, alias-aware) logic explicitly — serde attrs alone won't match.
- The `Reviver` + `SERIALIZABLE_MAPPING` (namespace→type, 1,085 LOC) → a registry
  `HashMap<Vec<String>, fn(kwargs) -> Box<dyn Any>>` with legacy-namespace remapping and
  a `valid_namespaces` allowlist (security). 🟠
- Golden round-trip tests from `load/test_serializable.py`.

**Open question:** how to reconstruct concrete types from `id` in a statically-typed
language — a registration macro/inventory (`inventory`/`linkme` crate) vs a hand-written
match. Impacts every Serializable type.

---

## 10. Tracers — 🟠 hard

- Tracers are `CallbackHandler` impls building `Run` trees.
- `astream_events` (v2) → a tracer that pushes `StreamEvent` into an mpsc channel merged
  with the token stream; port the **event ordering** (test-locked). Use `atee`/`safetee`
  analog (stream duplication) via `futures` + a broadcast/replay buffer. 🟠
- `astream_log` → `json-patch` `RunLogPatch` stream. 🟠
- LangChain/LangSmith tracer → optional downstream exporter crate (see deps).

---

## 11. RunnableConfig mapping — 🟡 (pervasive)

```
#[derive(Default, Clone)]
struct RunnableConfig {
    tags: Vec<String>, metadata: Map<String,Value>,
    callbacks: Callbacks, run_name: Option<String>,
    max_concurrency: Option<usize>, recursion_limit: usize /*=25*/,
    configurable: Map<String,Value>, run_id: Option<Uuid>,
}
tokio::task_local! { static CURRENT_CONFIG: RunnableConfig; }
```
- Python's `ContextVar` implicit propagation → `tokio::task_local!` (survives `.await`,
  per-task). `ensure_config()`/`merge_configs()` → explicit `merge` + a scope guard that
  sets the task-local for the duration of a child run.
- Merge rules: `tags`/`metadata` accumulate; `callbacks` inherit; `run_name`/`run_id`
  consumed once (not inherited). Port `merge_configs` exactly.
- **Risk:** task-local vs Python contextvar semantics differ across spawned tasks —
  `tokio::spawn` does *not* inherit task-locals, so config must be explicitly captured
  and re-scoped when spawning concurrent batch/parallel branches. **ADR needed.**

---

## Error taxonomy — 🟡

```
enum Error {
    OutputParser(OutputParserError),   // llm_output, observation, send_to_llm
    Tool(ToolError),                   // ToolException analog
    Validation(String),                // schema/args validation
    Model(ModelError),                 // provider failure
    RecursionLimit,
    Serialization(SerdeError),
    Config(String),
    Other(Box<dyn std::error::Error + Send + Sync>),
}
```
Use `thiserror` for the library error enum; avoid `anyhow` in the public API. Fallbacks
and retries match on error variants (LangChain matches on exception *types*).

---

## Difficulty / risk summary

| Subsystem | Difficulty | Primary risk |
|---|---|---|
| Runnables/LCEL | 🔴 | Type-erased heterogeneous composition; stream/transform unification; object-safety |
| Load / lc-JSON serde | 🟠 | Field-pruning + secret + namespace-registry reconstruction must be byte-faithful |
| Tools + schema gen | 🟠 | schemars vs pydantic JSON-schema divergence (model-facing wire output) |
| Language models | 🟠 | with_structured_output generics; v3 protocol stream immaturity; compat bridge |
| Output parsers | 🟠 | streaming json-patch diff sequences are observable |
| Tracers / astream_events | 🟠 | event ordering + stream duplication/replay + task-local propagation |
| Callbacks | 🟠 | async fan-out, run-tree, panic isolation |
| Messages + content blocks | 🟡 | chunk-merge reducers must be exact; translator scope boundary |
| Prompts | 🟡 | 3 template engines; f-string fidelity |
| RunnableConfig | 🟡 | task-local vs contextvar across spawned tasks |
| VectorStore/Retriever/Embeddings/Documents | 🟢–🟡 | mostly mechanical |

## Cross-cutting open design questions (candidate ADRs)

1. **ADR: Runnable object-safety** — typed associated-type trait + a separate
   object-safe `DynRunnable` (erased `serde_json::Value` I/O) for heterogeneous
   pipelines? How does `|`-style composition survive type erasure?
2. **ADR: tool/structured-output JSON-schema generation** — adopt `schemars` and add a
   pydantic-compatibility shim + golden schema tests, or hand-roll an emitter matching
   pydantic's output? (Determines provider acceptance.)
3. **ADR: lc-JSON deserialization registry** — `inventory`/`linkme` auto-registration
   vs explicit match; how to map legacy namespaces; security allowlist.
4. **ADR: RunnableConfig propagation** — `tokio::task_local!` semantics across
   `tokio::spawn` in batch/parallel; explicit re-scoping contract.
5. **ADR: streaming model** — is `transform(Stream)->Stream` the primitive with
   `stream` derived? How to duplicate/replay streams for `astream_events`/`astream_log`
   (broadcast buffer)? Depth of `tower::Service`/`Layer` adoption for middleware.

---

# Pass 7 deepening (2026-07-12) — refined strategy from full reads

## D-1. Runnables (RED-1) — concrete design constraints now confirmed

- **`RunnableBinding` needs 4 fields, not 1**: `kwargs`, `config`, `config_factories`
  (`Vec<Box<dyn Fn(&RunnableConfig)->RunnableConfig>>` — the `with_listeners` seam), and
  `custom_input_type`/`custom_output_type`. Merge order in `_merge_configs`: bound `config`
  first, then fold each `config_factory(config)`.
- **`RunnableBinding.__getattr__` transparent delegation is NOT portable.** Python delegates any
  attribute to `self.bound` and auto-injects the bound config into any callable taking a `config`
  param. Rust has no `__getattr__`. **Redesign**: expose an explicit `.inner()`/`Deref`-to-bound
  is wrong (would bypass config merge); instead the wrapper only forwards the known Runnable
  surface and injects config there. Document that arbitrary provider-method passthrough
  (`binding.some_provider_method()`) is dropped — provider-specific methods must be reached
  before binding, or via a typed extension trait.
- **`with_retry` defaults are load-bearing**: `stop_after_attempt=3`, `wait_exponential_jitter=true`,
  retry-on `(Exception,)` i.e. all errors by default. The Rust retry combinator must default to
  3 attempts + exponential jitter and match tenacity's `wait_exponential_jitter` formula
  (`initial`, `max`, `exp_base`, `jitter`) — golden-test the delays or accept documented drift.
- **`with_fallbacks` `exception_key`**: when set, inject the caught error into the fallback's
  input map under that key → Rust needs a fallback runner generic over an input that can carry
  an injected `Error` (only valid when `Input: Map`-shaped). Model as
  `Option<String> exception_key` + a `merge_exception_into_input` step.
- **`RunnableGenerator` vs `RunnableLambda` split is semantic, not cosmetic**: Generator = stream-
  native (`Stream<In> -> Stream<Out>`, emits as input arrives); Lambda = buffered (needs whole
  input). `coerce_to_runnable` picks Generator for generator-fns, Lambda otherwise. In Rust:
  `RunnableGenerator` wraps `FnMut(BoxStream<In>) -> BoxStream<Out>`; `RunnableLambda` wraps
  `FnMut(In) -> Out` (with buffered stream fallback). The `.pipe()`/`seq!` builder's coercion
  must mirror this fork. Constructor validation (Python raises `TypeError` for non-generators)
  becomes a compile-time type distinction in Rust (free).
- **`configurable_fields` eager validation**: raises if a key ∉ model fields. Rust: validate the
  override-key set against the type's known configurable fields at builder time → `Result`.

## D-2. astream_events v2 (ORA-3) — porting contract sharpened

- Emit a fixed 7-field event struct `StreamEvent { event: EventKind, name, run_id: Uuid,
  parent_ids: Vec<Uuid>, tags: Vec<String>, metadata: Map, data: EventData }`.
- `EventKind` is `on_<runtype>_<phase>`: runtype ∈ {chain, chat_model, llm, tool, prompt,
  retriever, custom}; phase ∈ {start, stream, end, error}. **Not all combos exist**: tool has no
  `stream` (only start/end/error); prompt has no `stream` (start/end); retriever has start/end.
- **Ordering invariant (the hard one)**: in a streaming sequence a downstream `*_start` fires
  before the upstream `*_end`. Implementation: the streaming tracer must emit `start` when a node
  begins consuming its input stream, not when its input fully arrives. Preserve start-before-end
  interleave.
- **Tag/metadata propagation**: tags accumulate down the tree; `seq:step:N` added per sequence
  position; metadata inherited+merged; LangSmith scalars derived (`ls_model_type`, `ls_stop`
  from bound `stop` kwarg). Port the `ls_*` derivation.
- **Cancellation**: dropping the event stream must cancel the running node and skip downstream
  nodes; the outer chain must observe cancellation for cleanup. Rust cancellation-on-drop covers
  (a)+(c); use a scope-guard / `select!` with a cancellation token to guarantee the outer
  generator's cleanup path runs (b). Golden-test with the break/cancel scenarios.
- **`on_tool_error` includes `tool_call_id`** (from the invoking ToolCall id, else `None`).

## D-3. Block translators — port BOTH mechanisms (ORA-1)

Not just "a trait + registry". Port:
1. A `PROVIDER_TRANSLATORS` registry: `HashMap<Provider, TranslatorPair>` where
   `TranslatorPair { translate_content, translate_content_chunk }`. Populated by partner crates
   via a `register_translator(provider, pair)` entry point — use `inventory`/`linkme`
   auto-registration or an explicit `OnceLock` registry seeded by feature-gated partner crates.
2. A fixed **ordered fallback pipeline** in `Message::content_blocks`: langchain_v0 → openai →
   anthropic → google_genai → bedrock_converse, each unpacking remaining `NonStandard` blocks.
3. Dispatch order in `AiMessage::content_blocks`: (a) short-circuit if `output_version=="v1"`
   AND content is a `Blocks(Vec)` variant (string content must NOT short-circuit — rebuild from
   tool_calls); (b) provider translator if `model_provider` registered; (c) fallback pipeline.
`langchain_v0` stays out of the registry (input-parsing only, pipeline-only). Core ships the
enum + fallback pipeline + registry mechanism; provider translators for anthropic/openai/etc.
live with (or register from) partner crates.

## D-5. `_compat_bridge` — mostly collapses under a unified ContentBlock

The bridge (3 fns: `finalize_tool_call_chunk`, `chunks_to_events`, `message_to_events`; 43-test
spec) exists **only** because Python has two distinct `ContentBlock` unions
(`messages.content` vs `langchain_protocol.protocol`). **Rust decision: define ONE
`ContentBlock` enum** shared by messages and the (ported) MessagesData protocol subset. Then the
laundering casts (`_to_protocol_block`/`_to_finalized_block`) vanish, and only the genuine
transform remains: `AiMessageChunk` stream → `MessagesData` event stream (`message-start` /
`content-block-start/delta/finish` / `message-finish`). Port that transform (it is the v3-stream
foundation) and keep the 43 tests as golden fixtures; ELIMINATE the dual-union laundering.

## D-6. langchain_protocol — port only the MessagesData subset into core

Confirmed core uses only: `MessageStartData`, `ContentBlockStartData/DeltaData/FinishData`,
`MessageFinishData`, `MessageErrorData`, `ContentBlock`, `FinalizedContentBlock`, `UsageInfo`,
`MessageMetadata`, and the `*Delta` types. Model these as serde-tagged enums UNIFIED with the
core content-block types (D-5). The full agent-server protocol (commands, subscriptions,
state/checkpoint/fork, 9-channel events, reconnection) is **out of core scope** → future
ferrochain-graph/server crate, ideally generated from the upstream CDDL schema (the Python is
itself `cddl2py`-generated). **Fetch the exact 0.0.17 schema** before finalizing (only 0.0.15
was locally inspectable).

## D-7. indexing/ — P1 ruling (self-contained, deferrable)

`indexing/` (1,772 src LOC / 3,373 test LOC / 61 tests) has **no external deps** beyond core +
stdlib hashing. Public API: `index()`/`aindex()` (dedup via content hash + `RecordManager`
bookkeeping; `cleanup` ∈ {incremental, full, scoped_full}; `key_encoder` ∈
{sha1, sha256, sha512, blake2b}; `cleanup_batch_size=1000`), `RecordManager`/
`InMemoryRecordManager`, `DocumentIndex`, `UpsertResponse`/`DeleteResponse`, `IndexingResult`.
It is a **RAG document-ingestion utility, not on the LLM/agent hot path** → **P1** (defer to a
later wave, after core→graph→partners). Difficulty 🟢–🟡 (dedup bookkeeping + hashing; the SQL/
persistent RecordManager backends are partner concerns; core ships the in-memory one). Port maps
cleanly to `sha2`/`blake2` crates + a `RecordManager` trait.

## Difficulty/risk table — additions

| Subsystem | Difficulty | Primary risk (Pass 7) |
|---|---|---|
| langchain_protocol (core subset) | 🟡 | Small/stable; unify with core ContentBlock; fetch exact 0.0.17 |
| _compat_bridge chunk→event transform | 🟡 | Collapses under unified enum; keep the stream transform + 43 golden tests |
| block-translator registry+pipeline | 🟠 | Two mechanisms (registry plugin seam + ordered fallback); dispatch order + string-content guard |
| indexing | 🟢–🟡 | P1; mechanical; hash-algo parity (4 algos) |

## New candidate ADRs surfaced (Pass 7)

6. **ADR: protocol scope split** — core defines only the MessagesData content-block subset,
   unified with the core `ContentBlock` enum; the full agent-streaming protocol is deferred to a
   graph/server crate and generated from CDDL. (Eliminates `_compat_bridge` laundering.)
7. **ADR: block-translator plugin registry** — `register_translator` extension seam
   (`inventory`/`linkme` vs explicit `OnceLock`) + the fixed core fallback pipeline; how partner
   crates contribute provider translators.
8. **ADR: astream_events cancellation & cleanup ordering** — guarantee the outer generator's
   cleanup runs on stream-drop/cancel while skipping downstream nodes (cancellation token +
   scope guard); golden-test against break/cancel scenarios.

---

# Pass 8 (2026-07-12, NARROW) — final convergence pass

Two residual items line-verified against the pinned corpus (langchain 1.3.13,
`libs/core/langchain_core/`). Reference line numbers below are into the **pinned, read-only**
corpus (stable; TD-VSDD-091 exception — pass-report test-anchor table), paired with function
names for durability. Item 1 → ADR-5; item 2 → ADR-3. The third residual (langchain-protocol
0.0.17 CDDL fetch, ADR-6/C-1) is handled by research-agent in parallel and is intentionally NOT
covered here.

## ADR-5 (Pass 8) — `stream`/`transform` unification: line-verified mechanics

**The relationship is two-tier, and it INVERTS between the base default and streaming nodes.**
This directly answers the standing open question §1(c) / ADR-5 candidate ("is `transform` the
primitive with `stream` derived?").

### Tier A — base `Runnable` default (non-streaming leaf): stream/transform derive from invoke
- `Runnable.stream` (`base.py:1182`) default body is literally `yield self.invoke(input, config)`
  — a one-shot generator. `astream` (`base.py:1203`) = `yield await self.ainvoke(...)`.
- `Runnable.transform` (`base.py:1748`) / `atransform` (`base.py:1793`) default **buffers the
  entire input stream** by folding it with `+` (`final = final + ichunk`; on `TypeError` →
  `final = ichunk`, i.e. keep-last), then `yield from self.stream(final, config)`. Docstring
  contract: *"Subclasses must override this method if they can start producing output while input
  is still being generated."*
- So for a plain leaf: `invoke` is the primitive; `stream` wraps it; `transform` buffers→streams.

### Tier B — streaming-native nodes INVERT it: `transform` is the primitive, `stream = transform(once(input))`
Verified in all four streaming Runnable subclasses; every one overrides `transform` and defines
`stream` in terms of it:
- **`RunnableSequence`**: `transform` (`base.py:3801`) → `_transform_stream_with_config(input,
  self._transform, ...)`; `stream` (`base.py:3815`) = `yield from self.transform(iter([input]),
  ...)`. (`astream`/`atransform` symmetric at 3839/3824.)
- **`RunnableParallel`**: `transform` (`base.py:4288`); `stream` (`base.py:4299`) =
  `transform(iter([input]))`.
- **`RunnableGenerator`**: `transform` (`base.py:4619`) is the primitive (wraps the generator fn
  `Iterator[In]->Iterator[Out]`, `defers_inputs=True`); `stream` (`base.py:4637`) =
  `transform(iter([input]))`; and even `invoke` (`base.py:4646`) folds `stream` via `+`. **Purest
  inversion — everything derives from `transform`.**
- **`RunnableLambda`**: `transform` (`base.py:5408`); `stream` (`base.py:5435`) =
  `transform(iter([input]))`. Its `_transform` (`base.py:5345`) buffers all input via `+`
  ("RunnableLambdas consume all input before emitting output"), then: generator-fn → yield
  incrementally; output-is-Runnable → recursive `output.stream(final, recursion_limit-1)`
  (`RecursionError` at ≤0); else yield the single value.

**Answer to ADR-5(c): YES — `transform(Stream)->Stream` is the primitive for streaming nodes;
`stream` is the trivial single-element special case `transform(once(input))`. The base class
provides the reverse fallback (`transform` = buffer-then-`stream`, `stream` = `once(invoke)`) so
that a node implementing ONLY `invoke` still satisfies the full surface.** Rust design: two
defaults on the trait — implement EITHER `invoke` (→ buffered `transform` + one-shot `stream`
provided) OR `transform` (→ `stream(input) = transform(stream::once(input))` provided, and
`invoke = fold(stream)`).

### Step-wise transform chaining (`RunnableSequence._transform`, `base.py:3752`)
```
steps = [self.first, *self.middle, self.last]
final_pipeline = inputs                       # the input Iterator
for idx, step in enumerate(steps):
    config = patch_config(config, callbacks=run_manager.get_child(f"seq:step:{idx+1}"))
    final_pipeline = step.transform(final_pipeline, config[, **kwargs if idx==0])
yield from final_pipeline
```
Composition is **lazy iterator chaining**: each step's `transform` consumes the previous step's
output iterator; only step 0 receives `**kwargs`; each step gets a child callback manager tagged
`seq:step:{N}` (the same `seq:step:N` tags Pass 7 D-2 flagged for astream_events).

### Buffering behavior per step type (the load-bearing distinction)
- **Streaming-native step** (Sequence / Parallel / Generator / `RunnablePassthrough` /
  transform-capable output parsers) → passes chunks through **incrementally as they arrive**; no
  full-input buffering. E.g. `StrOutputParser` in a sequence emits char-by-char.
- **Buffering step** (`RunnableLambda` with a non-generator fn, and the Tier-A base default) →
  folds the **entire** input via `+` (non-addable → keep-last) before emitting. This is a natural
  stream barrier inside an otherwise-streaming pipeline.
- The `+` fold reducer is the SAME operator used for message/AddableDict merge (§2). Rust needs
  ONE `Add`/`merge`-with-keep-last-fallback contract on chunk types.

### Shared wrapper `_transform_stream_with_config` (`base.py:2490`) — mechanics that MUST port
Both `stream` and `transform` of streaming nodes route through this. Non-obvious, test-observable
behavior:
1. **`tee(inputs, 2)`** (`base.py:2515`) — the input iterator is **duplicated**: one copy drives
   the transformer, the other is folded via `+` into `final_input` for the `on_chain_end` /
   `on_chain_error(inputs=...)` callback payload. → **Stream duplication is required even for
   plain `transform`, not only for `astream_events`/`astream_log`.** This raises the priority of
   the broadcast/replay-buffer design (previously scoped only to §10) — it is a base primitive.
2. **Eager first pull** — `next(input_for_tracing, None)` (`base.py:2517`) pulls the first input
   **before** running the transformer, guaranteeing the upstream Runnable starts before this one.
   **This is the same mechanism behind astream_events v2's start-before-end ordering (ADR-8 /
   ORA-3) — unify them.**
3. **ContextVar scoping** — `set_config_context(child_config)` + `context.run(next, iterator)`
   (`base.py:2538-2555`): every output pull runs inside the captured config context (ties ADR-4
   task-local propagation; each `next()` re-enters the scope).
4. **Output aggregation** — `final_output` folded via `+` (TypeError → stop folding, keep-last;
   `base.py:2557-2567`) for the `on_chain_end` aggregate.
5. **`defers_inputs`** flag (RunnableGenerator passes `True`) → forwarded into `on_chain_start`.
6. **`tap_output_iter`** — a `_StreamingCallbackHandler`, if present, taps the output iterator to
   populate `astream_log` `streamed_output` (`base.py:2540-2552`).

### What Pass 8 FIXES / CONSTRAINS for ADR-5
- **Resolves the open primitive question** (was OPEN in §1(c) and Pass 7 D-1): `transform` is the
  streaming primitive; `stream` = `transform(once)`; base fallback reverses it. The Rust trait is
  a two-default design (see Tier B above), NOT a single `stream`-primitive.
- **Elevates stream-duplication to a base requirement**: the input-`tee` for tracing means the
  Rust `_transform_stream_with_config` analog needs a broadcast/tee combinator on EVERY streaming
  node, feeding both the transformer and the on_chain_end `inputs=` aggregate. Not just §10.
- **Unifies the eager-first-pull ordering** with ADR-8 (start-before-end). One mechanism.
- **Single reducer contract**: the `+` fold appears at 4 sites (input tracing, output
  aggregation, lambda buffering, base transform buffering) — all share "addable → concat,
  non-addable → keep last".

### Tests that lock the semantics (HIGH confidence — direct assertions, pinned corpus)
| Test (file `tests/unit_tests/runnables/test_runnable.py`) | Locks |
|---|---|
| `test_runnable_sequence_transform` / `_atransform` (`:3846` / `:3859`) | `(llm \| StrOutputParser).transform(llm.stream(...))` yields **one chunk per character** (`len(chunks)==len("foo-lish")`) → token-by-token streaming preserved through a sequence when steps are transform-capable |
| `test_default_transform_with_dicts` (`:5580`) | CustomRunnable implementing only `invoke`; `transform([{a},{n}]) == [{n}]` (plain dict non-addable → keep-last) and `stream({n})==[{n}]` → Tier-A base buffering + keep-last |
| `test_default_atransform_with_dicts` (`:5602`) | `AddableDict` inputs fold via `+` → `[{"foo":"an"}]` → the addable branch of the reducer |
| `test_transform_of_runnable_lambda_with_dicts` (`:5539`) | RunnableLambda buffers to last chunk; `seq.stream(x) == seq.transform(iter([x]))` → the `stream = transform(once)` identity |
| `test_passthrough_transform_with_dicts` (`:5634`) | `RunnablePassthrough.transform([{a},{n}]) == [{a},{n}]` (NO buffering) → the contrast proving streaming-native vs buffering step distinction |
| `test_runnable_gen_transform` (`:5379`) | `RunnableGenerator(gen) \| plus_one`; `chain.stream(3)==[1,2,3]` → generator-native streaming + coercion of a bare generator fn into a transform step |
| `test_map_stream_iterator_input` (`:3262`), `test_deep_stream` (`:3561`) | Parallel/sequence streaming end-to-end |

### Contradictions with prior passes (item 1)
- **No contradiction; a RESOLUTION.** §1(c) and Pass 7 D-1 left "is transform the primitive?" OPEN
  and described Generator-vs-Lambda semantics without the universal `stream = transform(once)`
  identity or the tee-based input tracing. Pass 8 resolves the question and adds one NEW constraint
  (input-`tee` ⇒ stream duplication is a base primitive, not astream_events-only).

---

## ADR-3 (Pass 8) — partner-resolving `SERIALIZABLE_MAPPING` entries: feature-gated registration list

Line-verified against `load/mapping.py` (4 dicts) and `load/load.py` (`ALL_SERIALIZABLE_MAPPINGS`
merge at `:157`; `DEFAULT_NAMESPACES` allowlist at `:134`; `DISALLOW_LOAD_FROM_PATH` at `:152`;
core-mode filter `value[0] != "langchain_core"` at `:206`).

### Counts (corrects Pass 7's "178")
- Raw dicts: `SERIALIZABLE_MAPPING` 94 + `OLD_CORE_NAMESPACES_MAPPING` 58 +
  `_JS_SERIALIZABLE_MAPPING` 19 + `_OG_SERIALIZABLE_MAPPING` 7 = **178 raw pairs**.
- Merged `ALL_SERIALIZABLE_MAPPINGS` (dict-splat, later-wins) = **176 unique keys** — 2 collisions:
  the JS keys `("langchain","chat_models","bedrock","ChatBedrock")` and `(...,"BedrockChat")`
  override the `SERIALIZABLE_MAPPING` values (JS 3-tuple `langchain_aws.chat_models.ChatBedrock`
  wins over the 4-tuple `...bedrock.ChatBedrock`). **178 = sum of dicts; 176 = the registry.**
- Resolution buckets (by target `value[0]`): **langchain_core = 141** (own via ferrochain-core),
  **`langchain` monolith = 12**, **partner packages = 23 unique keys / 12 packages**.

### The 12 `langchain`-monolith entries — NO ferrochain owner
`LLMChain`, `ToolAgentAction`, `OutputFixingParser`, `RegexParser`, `ChatGooglePalm`, `BaseOpenAI`,
`GooglePalm`, `Replicate`, `CombiningOutputParser`, `HubRunnable`, `OpenAIFunctionsRouter`,
`OpenAIToolAgentAction`. These resolve to the `langchain` aggregation package, which ferrochain
does **not** port (ferrochain ports core/graph/mcp-adapters + provider partners). `langchain` is in
`DISALLOW_LOAD_FROM_PATH` (`load.py:152`) → loadable only via the mapping, never by path. **In
ferrochain these are UNREGISTERED**: a load of one of these lc-ids must return a structured
"unsupported serializable (upstream-monolith)" error — NOT a silent `None`/`Vec::new()` (Code
Conventions: no silent empty returns).

### The 23 partner entries → ferrochain crate owner (feature-gated registration)
Key = the **serialized lc-id** (the tuple KEY, i.e. what is on the wire); registration is keyed on
this, so partner crates must register the canonical id **plus all legacy aliases** for their class.
`ferrochain-core` initial crate family (per CLAUDE.md) has dedicated crates only for `openai` and
`anthropic`; the rest land in `ferrochain-community` initially, or in a per-provider crate when one
is added (final crate names are set at the Phase-1 architecture ADR).

| lc-namespace key (on-the-wire id) | target class | upstream partner pkg | ferrochain crate owner (feature) |
|---|---|---|---|
| `langchain.llms.openai.OpenAI` | OpenAI | langchain_openai | **ferrochain-openai** |
| `langchain.chat_models.openai.ChatOpenAI` | ChatOpenAI | langchain_openai | **ferrochain-openai** |
| `langchain.chat_models.azure_openai.AzureChatOpenAI` | AzureChatOpenAI | langchain_openai | **ferrochain-openai** |
| `langchain.llms.openai.AzureOpenAI` | AzureOpenAI | langchain_openai | **ferrochain-openai** |
| `langchain.chat_models.anthropic.ChatAnthropic` | ChatAnthropic | langchain_anthropic | **ferrochain-anthropic** |
| `langchain.chat_models.bedrock.ChatBedrock` | ChatBedrock | langchain_aws | ferrochain-community / future ferrochain-aws |
| `langchain.chat_models.bedrock.BedrockChat` | ChatBedrock (alias) | langchain_aws | ferrochain-community / future ferrochain-aws |
| `langchain.chat_models.anthropic_bedrock.ChatAnthropicBedrock` | ChatAnthropicBedrock | langchain_aws | ferrochain-community / future ferrochain-aws |
| `langchain_aws.chat_models.ChatBedrockConverse` | ChatBedrockConverse | langchain_aws | ferrochain-community / future ferrochain-aws |
| `langchain.llms.bedrock.Bedrock` | BedrockLLM (alias) | langchain_aws | ferrochain-community / future ferrochain-aws |
| `langchain.llms.bedrock.BedrockLLM` | BedrockLLM | langchain_aws | ferrochain-community / future ferrochain-aws |
| `langchain_groq.chat_models.ChatGroq` | ChatGroq | langchain_groq | ferrochain-community / future ferrochain-groq |
| `langchain.chat_models.groq.ChatGroq` | ChatGroq (alias) | langchain_groq | ferrochain-community / future ferrochain-groq |
| `langchain_google_genai.chat_models.ChatGoogleGenerativeAI` | ChatGoogleGenerativeAI | langchain_google_genai | ferrochain-community / future ferrochain-google |
| `langchain.chat_models.google_genai.ChatGoogleGenerativeAI` | ChatGoogleGenerativeAI (alias) | langchain_google_genai | ferrochain-community / future ferrochain-google |
| `langchain.chat_models.vertexai.ChatVertexAI` | ChatVertexAI | langchain_google_vertexai | ferrochain-community / future ferrochain-google |
| `langchain.chat_models.mistralai.ChatMistralAI` | ChatMistralAI | langchain_mistralai | ferrochain-community / future ferrochain-mistral |
| `langchain.chat_models.fireworks.ChatFireworks` | ChatFireworks | langchain_fireworks | ferrochain-community / future ferrochain-fireworks |
| `langchain.llms.fireworks.Fireworks` | Fireworks | langchain_fireworks | ferrochain-community / future ferrochain-fireworks |
| `langchain_xai.chat_models.ChatXAI` | ChatXAI | langchain_xai | ferrochain-community / future ferrochain-xai |
| `langchain_openrouter.chat_models.ChatOpenRouter` | ChatOpenRouter | langchain_openrouter | ferrochain-community / future (⚠ namespace not in allowlist) |
| `langchain_baseten.chat_models.ChatBaseten` | ChatBaseten | langchain_baseten | ferrochain-community / future (⚠ namespace not in allowlist) |
| `langchain.llms.vertexai.VertexAI` | VertexAI | langchain_vertexai | ⚠ DEAD upstream — see below |

Alias multiplicity to preserve on registration: **ChatBedrock** (3 keys), **BedrockLLM** (2),
**ChatGroq** (2), **ChatGoogleGenerativeAI** (2) — partner registration must map every legacy key
to the one class.

### Upstream security-allowlist drift (constrains the ferrochain reviver design)
`DEFAULT_NAMESPACES` (`load.py:134`) = {langchain, langchain_core, langchain_community,
langchain_anthropic, langchain_groq, langchain_google_genai, langchain_aws, langchain_openai,
langchain_google_vertexai, langchain_mistralai, langchain_fireworks, langchain_xai,
langchain_sambanova, langchain_perplexity}. Drift found:
- `langchain_openrouter`, `langchain_baseten`, `langchain_vertexai` appear as mapping **values** but
  are **NOT** in the allowlist → the reviver rejects `value[0] ∉ valid_namespaces` (`load.py:544`),
  so these 3 entries are **effectively unloadable upstream** today. `VertexAI`-LLM in particular is
  a dead entry (its sibling `ChatVertexAI` correctly targets the allowlisted
  `langchain_google_vertexai`; the LLM targets the non-allowlisted `langchain_vertexai`).
- `langchain_sambanova`, `langchain_perplexity` are allowlisted but have **NO mapping entries**.
- **Design implication for ADR-3**: ferrochain must NOT port a hand-maintained parallel allowlist
  (it drifts, as shown). Derive the valid-namespace allowlist **from the registered set** — the
  registry (core-internal registrations + feature-gated partner registrations) is the single source
  of truth; a type is loadable iff it is registered. This eliminates the drift class entirely and
  makes the security allowlist a consequence of Cargo feature selection.

### Registration architecture (ADR-3 concrete shape confirmed)
- **ferrochain-core** ships: the `Reviver` + the registry mechanism (`inventory`/`linkme`
  auto-registration or explicit `OnceLock` seeded at init), the **141 core-internal registrations**,
  and the **legacy-alias remap** (OLD_CORE / JS / OG keys all fold onto the same core targets).
- **Partner crates** register their own serializable types via the plugin seam, **feature-gated**.
  Today only `ferrochain-openai` (4 ids) and `ferrochain-anthropic` (1 id) exist → they own 5 of 23;
  the other 18 belong to crates not yet in the workspace and initially land in `ferrochain-community`.
- Registration is keyed on the **serialized id**, alias-aware (see multiplicity above).
- `langchain`-monolith ids (12) and non-allowlisted/dead ids → deliberately unregistered; loads
  return a structured `Serialization`/`unsupported-serializable` error variant.

### Contradictions with prior passes (item 2)
- **C-7 (LOW)** — Pass 7 item 3 / D-9 recorded "**178** entries … some values point to partner pkgs
  (langchain_aws/langchain)". Pass 8 sharpens: 178 is the sum of the 4 source dicts; the **merged
  registry is 176** (2 JS↔SERIALIZABLE collisions). Partner-resolving = **23 unique keys / 12
  packages**; the 12 `langchain`-monolith entries are **not** partner crates and have **no**
  ferrochain owner (Pass 7 conflated "langchain" with partner packages). Refinement + one small
  count correction, not a semantic reversal.
