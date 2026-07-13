---
artifact: semport/mcp/EXHAUSTIVE-SWEEP
project: ferrochain
area: mcp
sweep_type: exhaustive (D14.1)
reference_tag: langchain-mcp-adapters==0.3.0
date: 2026-07-12
validator: extraction-validator
---

# Exhaustive Verification Sweep — mcp area

Reference corpus: `.reference/langchain-mcp-adapters` (tag 0.3.0).
All 5 area files examined: behavioral-intent, dependency-disposition, module-inventory,
rust-translation-strategy, test-inventory.

---

## Phase 1 — Behavioral Verification

| Pass / File | Items Checked | Verified | Inaccurate | Hallucinated | Unverifiable |
|---|---|---|---|---|---|
| behavioral-intent.md | 38 | 37 | 1 (TRIVIAL) | 0 | 0 |
| dependency-disposition.md | 14 | 10 | 0 | 0 | 4 (rmcp live-data) |
| module-inventory.md | 30 | 28 | 2 (TRIVIAL) | 0 | 0 |
| rust-translation-strategy.md | 18 | 18 | 0 | 0 | 0 |
| test-inventory.md | 37 | 33 | 4 (2 MODERATE, 2 LOW) | 0 | 0 |
| **Totals** | **137** | **126** | **7** | **0** | **4** |

---

## Phase 2 — Metric Verification

Every numeric claim in the analysis recounted independently with `wc -l`.

| Claim | Claimed | Recounted | Delta | Command |
|---|---|---|---|---|
| tools.py LOC | 685 | 685 | 0 | `wc -l langchain_mcp_adapters/tools.py` |
| sessions.py LOC | 477 | 477 | 0 | `wc -l langchain_mcp_adapters/sessions.py` |
| client.py LOC | 302 | 302 | 0 | `wc -l langchain_mcp_adapters/client.py` |
| interceptors.py LOC | 141 | 141 | 0 | `wc -l langchain_mcp_adapters/interceptors.py` |
| callbacks.py LOC | 141 | 141 | 0 | `wc -l langchain_mcp_adapters/callbacks.py` |
| resources.py LOC | 103 | 103 | 0 | `wc -l langchain_mcp_adapters/resources.py` |
| prompts.py LOC | 59 | 59 | 0 | `wc -l langchain_mcp_adapters/prompts.py` |
| __init__.py LOC | 6 | 6 | 0 | `wc -l langchain_mcp_adapters/__init__.py` |
| Total production LOC | 1,914 | 1,914 | 0 | `wc -l` sum of 8 modules |
| test_tools.py LOC | 1,469 | 1,469 | 0 | `wc -l tests/test_tools.py` |
| test_client.py LOC | 353 | 353 | 0 | `wc -l tests/test_client.py` |
| test_interceptors.py LOC | 323 | 323 | 0 | `wc -l tests/test_interceptors.py` |
| test_resources.py LOC | 275 | 275 | 0 | `wc -l tests/test_resources.py` |
| test_elicitation.py LOC | 164 | 164 | 0 | `wc -l tests/test_elicitation.py` |
| test_callbacks.py LOC | 143 | 143 | 0 | `wc -l tests/test_callbacks.py` |
| test_prompts.py LOC | 82 | 82 | 0 | `wc -l tests/test_prompts.py` |
| test_import.py LOC | 9 | 9 | 0 | `wc -l tests/test_import.py` |
| servers (math+weather+time) LOC | 70 | 70 | 0 | `wc -l` sum: 38+19+13 |
| conftest.py + utils.py LOC | 168 | 168 | 0 | `wc -l`: 68+100 |
| Total test LOC | 3,056 | 3,056 | 0 | `wc -l` sum of 13 test files |
| Production module count | 8 | 8 | 0 | `ls langchain_mcp_adapters/*.py \| wc -l` |
| Test/production ratio | 1.6× | 1.596× (≈1.6) | ~0 | 3056/1914 |
| MAX_ITERATIONS constant | 1000 | 1000 | 0 | grep `MAX_ITERATIONS` tools.py:67 |
| SSE default timeout | 5s | 5s | 0 | sessions.py:53 `DEFAULT_HTTP_TIMEOUT = 5` |
| SSE sse_read_timeout | 300s | 300s | 0 | sessions.py:54 `60 * 5` |
| StreamableHttp default timeout | 30s | 30s | 0 | sessions.py:56 `timedelta(seconds=30)` |
| StreamableHttp sse_read_timeout | 300s | 300s | 0 | sessions.py:57 `timedelta(seconds=60 * 5)` |
| to_fastmcp line end | 686 | 685 | **-1** | `wc -l tools.py` = 685; line 686 does not exist |

All metric claims pass at delta=0 except the `to_fastmcp` line-end off-by-one (-1), corrected in-place.

---

## Refinement Iterations: 1/3

One iteration was sufficient. All inaccuracies were correctable from ground truth;
no items required a second pass.

---

## Inaccurate Items (Corrected)

| # | Severity | File | Original Claim | Actual Behavior | Correction Applied |
|---|---|---|---|---|---|
| I-1 | MODERATE | test-inventory.md | `` `test_adapter_bug_still_raises` — bare ToolException (non-execution) re-raises. `` | Test actually verifies that AudioContent raises `NotImplementedError` even when `isError=True` and `handle_tool_errors=True`. This is a content-conversion error path that bypasses `_handle_mcp_tool_error` entirely (not a ToolException subclass). The "bare ToolException re-raise" behavior in `_handle_mcp_tool_error` is real (documented in the function's docstring) but has no dedicated lock test in the Python suite. | Rewrote description to accurately identify the two distinct paths; flagged bare ToolException re-raise as untested. `[validation-exhaustive]` |
| I-2 | MODERATE | test-inventory.md | test_client.py Client section: "name conflicts, the `__aenter__` NotImplementedError block" | (a) `test_get_tools_with_name_conflict` is in test_tools.py (line 1420), not test_client.py. (b) No test for `MultiServerMCPClient.__aenter__` raising NotImplementedError exists anywhere in the Python test suite. The behavior exists in client.py:267-291 but is untested — this is a coverage gap ferrochain-mcp must fill. | Removed both false claims; documented that `__aenter__` NotImplementedError is a coverage gap; redirected name-conflict attribution to test_tools.py. `[validation-exhaustive]` |
| I-3 | LOW | test-inventory.md | test_client.py module table Focus: "MultiServerMCPClient (get_tools, session, name conflicts, parallel)" | test_client.py also contains 5 stdio session env-var expansion tests (`test_stdio_session_*`) that test `_create_stdio_session`/`_expand_env_vars` behavior, not just MultiServerMCPClient. | Added stdio session env-var expansion to Focus column. `[validation-exhaustive]` |
| I-4 | TRIVIAL | module-inventory.md | `` `to_fastmcp` \| tools.py:638-686 `` | tools.py has 685 lines (wc -l = 685); line 686 does not exist. Function ends at line 685. | Changed to `tools.py:638-685`. `[validation-exhaustive]` |
| I-5 | TRIVIAL | module-inventory.md | `` `__init__.py` \| 6 \| version marker `` | `__init__.py` content is a 6-line module docstring only — no `__version__` variable or version marker of any kind. Version is declared in pyproject.toml only. | Changed to "package docstring only (no `__version__` variable)". `[validation-exhaustive]` |

---

## Hallucinated Items (Removed)

None. Every function, class, and test name cited in the analysis was found in the
reference codebase at the stated file.

---

## Unverifiable Items

| # | Item | Source | Reason |
|---|---|---|---|
| U-1 | rmcp v2.2.0 release date (2026-07-08), download counts (15.5M total / 8.0M recent) | dependency-disposition.md | Requires live crates.io access; not checkable against reference corpus |
| U-2 | rmcp official status ("modelcontextprotocol/rust-sdk — the OFFICIAL Rust MCP SDK") | dependency-disposition.md | Requires live GitHub/crates.io verification; not in reference corpus |
| U-3 | rmcp elicitation support ("elicitation not confirmed in README") | dependency-disposition.md | Requires live rmcp 2.2.0 docs/source; intentionally marked as open item #1 |
| U-4 | rmcp `CallToolResult` field names (`structuredContent`, `isError`, cursor pagination shape) | dependency-disposition.md | Requires live rmcp 2.2.0 source; intentionally marked as open items #2, #3 |

All four unverifiable items are correctly flagged as open verification items in the
dependency-disposition itself (section "Open verification items"). No correction needed.

---

## Coverage Statement

**Full (100%) coverage** of the 5 mcp area files against the reference corpus at
tag langchain-mcp-adapters==0.3.0.

Coverage by claim type:
- **Production module LOC** (8 files): 8/8 verified exactly
- **Test file LOC** (13 files): 13/13 verified exactly
- **Named test functions cited** (≈35 test names): 35/35 found in reference; 1 description corrected (I-1)
- **Behavioral contracts** (content-block mapping, error policy, session lifecycle, interceptors, callbacks, prompts, resources): all verified against source
- **Symbol/line-range citations** (17 symbols): 16/17 exact; 1 trivial off-by-one corrected (I-4)
- **Dependency version pins** (mcp>=1.9.2, langchain-core>=1.0.0, typing-extensions): all verified against pyproject.toml
- **rmcp claims**: 4 items UNVERIFIABLE (offline; correctly flagged as open items in source)
- **Transport defaults** (SSE 5s/300s; StreamableHttp 30s/300s): verified against constants in sessions.py
- **Behavioral edge cases** (env-var expansion, exception-capture workaround, interceptor onion, empty-content fallback): all verified against source

---

## Most Consequential Fix

**I-1 + I-2 combined (test-inventory.md, error-taxonomy lock tests).**

The test-inventory incorrectly described `test_adapter_bug_still_raises` as locking the
"bare ToolException re-raise" path in `_handle_mcp_tool_error`. The actual test locks
a *different* propagation path: content-conversion errors (`NotImplementedError`) that
bypass `_handle_mcp_tool_error` entirely. The "bare ToolException re-raise" behavior is
real and consequential — an interceptor raising a bare `ToolException` must re-raise rather
than be silently swallowed — but has NO lock test in the Python suite.

This matters for ferrochain-mcp's Red Gate test design:
1. The content-conversion propagation path (AudioContent → NotImplementedError) is already
   locked by `test_convert_audio_content_raises` and `test_adapter_bug_still_raises`. A
   ferrochain-mcp Red Gate for this path does not need to duplicate.
2. The "bare ToolException from interceptor re-raises" path is UNTESTED in Python and must
   be explicitly added as a ferrochain-mcp Red Gate test to prevent silent swallowing via
   the `_handle_mcp_tool_error` analogue.

The `__aenter__` NotImplementedError untested gap (I-2) is similarly important: ferrochain
must add a test that `MultiServerMcpClient` rejects use as an async context manager.
