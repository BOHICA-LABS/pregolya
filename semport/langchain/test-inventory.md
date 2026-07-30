---
artifact: semport/langchain/test-inventory
project: pregolya
port_target: langchain (v1)
analyzer_pass: 3
date: 2026-07-12
---

# langchain (v1) — Test Inventory

Tests are **first-class specification** for this port. 63 `test_*.py` files, **31,653
LOC** — ~2.2× the 14,512 LOC of source. The suite is overwhelmingly **unit tests of the
agent loop and middleware**; there is almost no integration/network testing in-tree.

## 1. Distribution

| Group | LOC | Files | What it locks down |
|---|---:|---:|---|
| `unit_tests/agents/middleware/implementations/` | 14,550 | 17 <!-- [validation-corrected pass-3]: claimed 18; actual file count = 17 (find .../implementations/ -name "*.py" ! -name "__init__.py" | wc -l) --> | Per-middleware behavior (the biggest bucket) |
| `unit_tests/agents/middleware/core/` | 7,731 | 12 <!-- [validation-corrected pass-3]: claimed 11; actual file count = 12 (find .../core/ -name "test_*.py" | wc -l); the total implementations+core was correct at 29 but the two counts were individually swapped --> | Middleware framework: composition, decorators, wrap_model/tool_call, overrides, diagram |
| `unit_tests/agents/` (top level) | 6,537 | 17 | create_agent, react loop, response_format, streaming, state schema, injection, subagents |
| `unit_tests/agents/middleware_typing/` | 989 | 3 | Static typing / backwards-compat of middleware generics |
| `unit_tests/chat_models` + `embeddings` + `tools` | 487 | 4 | init_chat_model/init_embeddings/imports |
| `integration_tests/` | 343 | 5 <!-- [validation-exhaustive]: prior claimed 6; `find integration_tests -name "test_*.py" | wc -l` = 5 (test_human_in_the_loop_integration, test_shell_tool_integration, test_base×2, test_compile); 343 LOC is correct for test_*.py only; the 7 total .py files include conftest.py + fake_embeddings.py which are non-test support files --> | HITL + shell (require real infra), chat_models/embeddings base, compile smoke |
| `benchmarks/` | 44 | 1 | `test_create_agent` perf benchmark |

## 2. Highest-value contract sources (SCoT: assertions → postconditions)

| Test file | LOC | Contracts encoded |
|---|---:|---|
| `agents/test_react_agent.py` | 987 | **The core agent loop** — model↔tools iteration, stop conditions, tool fan-out, system prompt injection |
| `agents/test_response_format.py` | 1,018 | Structured output: Tool vs Provider vs Auto strategy selection, parsing, retry-on-error |
| `agents/test_system_message.py` | 1,052 | System prompt/message handling, dynamic prompt |
| `agents/test_injected_runtime_create_agent.py` | 859 | Runtime/state/store injection into tools |
| `agents/test_state_schema.py` | 351 | Middleware state-schema merging + Omit annotations |
| `agents/test_agent_streaming.py` | 285 | Stream modes, custom events |
| `agents/test_subagent_streaming.py` / `test_subagent_transformer.py` | 248+ | Nested named-agent surfacing on `run.subagents` |
| `agents/test_return_direct_graph.py` / `_spec.py` | — | `return_direct` tool exit behavior |
| `agents/test_responses.py` / `_spec.py` | 282 | Response construction / responses API spec |
| `agents/test_create_agent_tool_validation.py` | 411 | Unknown/dynamic tool validation errors |
| `agents/test_fetch_last_ai_and_tool_messages.py` | — | The loop's message-scan helper |

## 3. Middleware framework tests (`core/`) — composition semantics

| File | LOC | Locks down |
|---|---:|---|
| `test_wrap_model_call.py` | 1,600 | wrap_model_call: retry, short-circuit, response rewrite, AIMessage normalization, outer→inner order |
| `test_framework.py` | 1,086 | Hook registration, node creation, edge wiring |
| `test_wrap_model_call_state_update.py` | 919 | ExtendedModelResponse Command → reducer state updates |
| `test_wrap_tool_call.py` | 867 | wrap_tool_call retry/modify/short-circuit |
| `test_decorators.py` | 826 | before/after/wrap decorators synthesize correct middleware |
| `test_sync_async_wrappers.py` | 490 | sync-only/async-only NotImplementedError paths |
| `test_overrides.py` | 442 | ModelRequest.override immutability |
| `test_dynamic_tools.py` | 421 | Middleware adding tools at runtime |
| `test_tools.py` | 394 | Tool registration via middleware |
| `test_composition.py` | 349 | Multi-middleware ordering (first=outermost) |
| `test_transformers.py` / `test_diagram.py` | — | Stream transformer registration; graph diagram output |

## 4. Per-middleware implementation tests (17 files, 14,550 LOC) <!-- [validation-corrected pass-3]: heading said 18; actual = 17 -->

Each built-in middleware has a dedicated test file; the largest are behavioral goldmines:

| File | LOC | Middleware |
|---|---:|---|
| `test_pii.py` | 2,371 | PII detect/redact + stream redaction |
| `test_summarization.py` | 2,086 | Trigger clauses, summary replacement |
| `test_tool_retry.py` | 1,116 | Retry/backoff policy |
| `test_model_fallback.py` | 1,069 | Fallback model ordering |
| `test_human_in_the_loop.py` | 1,021 | interrupt/resume decisions (approve/edit/reject/respond) |
| `test_todo.py` | 846 | Planning tool + state |
| `test_tool_call_limit.py` | 819 | Limit + exceeded error |
| `test_model_retry.py` | 702 | Model retry |
| `test_shell_tool.py` (+`test_shell_execution_policies.py`) | 696+445 | Shell session + Host/Docker/Codex policies |
| `test_tool_selection.py` | 643 | LLM tool down-selection |
| `test_tool_emulator.py` | 627 | Tool emulation |
| `test_file_search.py` | 603 | File search tools |
| `test_context_editing.py` | 470 | Clear-tool-uses edit |
| `test_provider_tool_search.py` | 434 | Provider server-tool specs |
| `test_structured_output_retry.py` | 369 | SO retry via ToolStrategy handle_errors |
| `test_model_call_limit.py` | 233 | Model-call cap |

## 5. Fixtures & harness (reusable for pregolya conformance)
- `unit_tests/agents/model.py` — a fake/generic chat model driving deterministic loops.
- `unit_tests/agents/messages.py`, `any_str.py`, `utils.py` — message builders + matchers.
- `unit_tests/agents/conftest.py`, `conftest_checkpointer.py`, `conftest_store.py`,
  `memory_assert.py` — checkpointer/store fixtures + memory assertions.
- `integration_tests/cache/fake_embeddings.py`, `conftest.py`.

**Port recommendation:** the fake model + `messages.py`/`any_str.py` matcher pattern
should be ported to pregolya as the agent-loop conformance harness. Golden behavior of
`test_react_agent.py`, `test_response_format.py`, and `core/test_wrap_model_call.py`
defines "the agent works."

## 6. Coverage gaps (behaviors with weak/no in-tree tests)
- **Provider integration** — no real-provider tests in-tree (uses fakes); provider parity
  lives in `standard-tests` (separate package, out of this analysis).
- **Streaming token-level** — mostly delegated to langgraph; only agent-level stream modes
  tested here.
- **init_chat_model** — only 349 LOC (`test_chat_models.py`) + imports; provider inference
  edge cases lightly covered.
- **Networked middleware** (shell docker, HITL) — behind `integration_tests` requiring
  infra; unit tests use fakes.

## State Checkpoint
```yaml
pass: 3
artifact: test-inventory
status: complete
test_files: 63
test_loc: 31653
timestamp: 2026-07-12
```
</content>
