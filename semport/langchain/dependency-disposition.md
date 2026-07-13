---
artifact: semport/langchain/dependency-disposition
project: ferrochain
port_target: langchain (v1)
analyzer_pass: 3
date: 2026-07-12
mandate: D5 — every third-party dep → MAP | PORT | ELIMINATE
---

# langchain (v1) — Dependency Disposition

**Legend:**
- **MAP** — satisfied by an existing/planned Rust crate or another ferrochain crate.
- **PORT** — must be reimplemented in Rust (no faithful equivalent; behavior is intrinsic).
- **ELIMINATE** — Python-runtime-specific; no Rust counterpart needed.

## 1. Declared runtime dependencies (`pyproject.toml`)

`test_dependencies.py` asserts the required set is **exactly** `{langchain-core,
langgraph, pydantic}`.

| Dep | Version | Disposition | Rationale / target |
|---|---|---|---|
| **langchain-core** | `>=1.4.9,<2` | **MAP → ferrochain-core** | Messages, content blocks, `BaseChatModel`, tools, `Runnable`, `RunnableConfig`, `Embeddings`, rate limiters, prompt values, tracers. This is Pass-1's port target. All of `langchain.messages`, `langchain.rate_limiters`, most of `langchain.tools`, and the `BaseChatModel`/`Embeddings` re-exports resolve here. |
| **langgraph** | `>=1.2.5,<1.3` | **MAP → ferrochain-graph** (separate analyzer/crate) | The agent runtime. `create_agent` builds & compiles a langgraph `StateGraph`. The exact consumed surface is enumerated in behavioral-intent.md §5 — that list defines ferrochain-graph's minimum public API. **Do not port here; it is a sibling crate.** |
| **pydantic** | `>=2.7.4,<3` | **MAP → serde + schemars** | Used in `structured_output.py` (`BaseModel`, `TypeAdapter`, `model_json_schema`) and by middleware config models. Rust: `serde` for (de)serialize, `schemars` for JSON-schema emission, `TypeAdapter.validate_python` → `serde_json::from_value` into a typed struct. See rust-translation-strategy.md §3. |

## 2. Undeclared but imported at runtime

| Dep | Where | Disposition | Rationale |
|---|---|---|---|
| **langsmith** (`traceable`) | `factory.py:30` — wraps every composed wrap_model_call/wrap_tool_call handler | **ELIMINATE (v1) / MAP (later)** | Proprietary tracing SaaS client, pulled in transitively via langchain-core. `traceable` is a decorator adding tracing spans; functionally a no-op wrapper if tracing is off. ferrochain: replace with a **callback/tracing trait seam** (a no-op by default, optionally emitting to an exporter). Not required for behavioral parity. Confirmed out-of-scope by langchain-research.md §7. |
| **langchain_protocol** (`LifecycleCause`) | `_subagent_transformer.py:37` — **TYPE_CHECKING only** | **ELIMINATE / PORT-if-needed** | Type-only import for the subagent stream cause. Only needed if `_subagent_transformer.py` (P3, deferred) is ported. If ported, `LifecycleCause` becomes a small ferrochain-graph enum (`Cause::ToolCall{tool_call_id}`). |

## 3. Optional dependencies (`[project.optional-dependencies]`) — provider packages

All 19 optional extras are **provider integration packages** (`langchain-anthropic`,
`-openai`, `-google-vertexai`, `-google-genai`, `-fireworks`, `-ollama`, `-together`,
`-mistralai`, `-huggingface`, `-groq`, `-aws`, `-baseten`, `-deepseek`, `-xai`,
`-perplexity`, `-meta`, `-azure-ai`, `-community`, `-cohere`). They are imported lazily by
`init_chat_model`/`init_embeddings` via `importlib.import_module` from the
`_BUILTIN_PROVIDERS` registry (30 chat providers, 11 embeddings providers).

| Group | Disposition | Rationale |
|---|---|---|
| All provider extras | **MAP → ferrochain partner crates** (per-provider, out of this analysis) | These implement `BaseChatModel`/`Embeddings` from core. In Rust, back them with `genai`/`async-openai`/`anthropic-sdk-rust`/`ollama-rs` behind the ferrochain-core `ChatModel` trait. The **registry pattern itself** (name→creator) is ported; the concrete providers are separate crates. |

**Registry disposition:** `_BUILTIN_PROVIDERS` (lazy `importlib` + `functools.partial`)
→ **PORT** as a static Rust registry (`HashMap<&str, fn(ModelConfig)->Box<dyn ChatModel>>`
gated behind cargo features per provider) plus the **prefix-inference function**
(`_attempt_infer_model_provider`) which is pure string logic — straight PORT.

## 4. Standard-library / Python-runtime usage → ELIMINATE or MAP

| Python facility | Where | Disposition | Rust equivalent |
|---|---|---|---|
| `functools.lru_cache` | provider creators, schema hints | MAP | `once_cell`/`OnceLock` or a memo map |
| `importlib.import_module` | dynamic provider loading | ELIMINATE | Static registry + cargo features (no runtime import) |
| `dataclasses` (`dataclass`, `field`, `replace`, `fields`) | ModelRequest/Response, strategies | MAP | plain structs + a `.override()` builder (replaces `replace`) |
| `typing` reflection (`get_type_hints`, `get_args`, `get_origin`, `Annotated`, `TypedDict`, `Required/NotRequired`) | `_resolve_schemas`, `_extract_metadata` | **PORT (design-heavy)** | State-schema merging must become **static struct composition** or a registry of field descriptors; Python runtime type-hint reflection has no direct Rust analog. See open questions. |
| `type(name, bases, dict)` dynamic class creation | all 8 middleware decorators | **PORT (redesign)** | Rust can't synthesize types at runtime. Decorators become **generic wrapper structs** holding a closure (e.g. `FnMiddleware { hook: BeforeModelFn }`) implementing the middleware trait. |
| `warnings.warn` / `DeprecationWarning` | ModelRequest setattr, gemini inference | ELIMINATE | Drop deprecated setattr path; use `tracing::warn!` if a message is desired |
| `inspect.iscoroutinefunction` | decorators (sync vs async slot) | ELIMINATE | Rust async is static; a middleware impls the async trait method directly |
| `re` (regex) | structured-output model matching, PII, redaction | MAP | `regex` crate |
| `json` | ProviderStrategyBinding.parse | MAP | `serde_json` |
| `uuid` | schema-spec name fallback | MAP | `uuid` crate |
| `itertools.pairwise` | edge wiring | MAP | `slice::windows(2)` |

## 5. Summary counts
- **MAP:** langchain-core, langgraph, pydantic (→serde+schemars), langsmith(later),
  provider extras, + stdlib (lru_cache, dataclasses, re, json, uuid, itertools).
- **PORT:** `_BUILTIN_PROVIDERS` registry + prefix inference, state-schema merging logic,
  runtime-class-creation decorators (as generic wrappers), reducers referenced from
  langgraph are ferrochain-graph's job.
- **ELIMINATE:** langsmith (behavioral no-op), langchain_protocol (type-only),
  importlib dynamic loading, warnings/deprecations, iscoroutinefunction, deprecated
  setattr.

## 6. Critical dependency note for orchestrator
The single most important disposition is **langgraph = MAP → ferrochain-graph**, and the
consumed API is fully enumerated in behavioral-intent.md §5. **ferrochain (the v1 crate)
cannot be specced without ferrochain-graph's public API being fixed first.** The v1 crate
is otherwise a thin orchestration layer: it contributes `create_agent`'s graph-wiring
logic, the middleware trait/composition, structured-output strategies, and the model/
embeddings registries — everything else is core + graph.

## State Checkpoint
```yaml
pass: 3
artifact: dependency-disposition
status: complete
timestamp: 2026-07-12
```
</content>
