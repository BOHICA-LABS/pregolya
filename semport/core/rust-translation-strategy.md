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
