---
document_type: prd-supplement-test-vectors
level: L3
version: "1.4"
status: active
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md
  - .factory/specs/behavioral-contracts/ss-07/BC-2.07.002.md
input-hash: "[live-index — aggregated from 95 BC files]"
traces_to: prd.md
primary_consumers: [test-writer, holdout-evaluator]
---

# Test Vector Catalog: ferrochain

> **Index model:** This supplement is an index — it does NOT duplicate the canonical
> test vectors that live inside individual BC files. Each row below points to the
> authoritative source in `behavioral-contracts/ss-NN/BC-S.SS.NNN.md`.
>
> **Golden Test Vectors (GTVs):** BC-2.07.002 contains the normative golden vector
> set for non-ASCII splitter parity. These GTVs are reproduced in §GTV below because
> they constitute the Red Gate acceptance data — the test-writer needs them inline
> without loading the full BC file.
>
> **Red Gate vectors** are marked **RG** — they must exist as failing tests BEFORE
> implementation begins (D17-Q9 mandate).

---

## BC Test Vector Inventory

| BC ID | Subsystem | TV Count | GTV Count | Format | RG | Notes |
|-------|-----------|----------|-----------|--------|-----|-------|
| BC-2.01.001 | SS-01 | 5 | — | `TV-NNN` | | Typed ContentBlock happy/error/edge |
| BC-2.01.002 | SS-01 | 5 | — | `TV-NNN` | | Message type-safety: wrong type rejects |
| BC-2.01.003 | SS-01 | 5 | — | `TV-NNN` | | Runnable invoke/stream/batch dispatch |
| BC-2.01.004 | SS-01 | 5 | — | `TV-NNN` | | Pipe A\|B produces AB chain |
| BC-2.02.001 | SS-02 | 5 | — | `TV-NNN` | | StateGraph node + channel happy path |
| BC-2.02.002 | SS-02 | 6 | — | `TV-NNN` | | Reducer semantics: LastValue/Append/Barrier |
| BC-2.02.003 | SS-02 | 5 | — | `TV-NNN` | **RG** | NamedBarrierValue missing-writer → default |
| BC-2.02.004 | SS-02 | 5 | — | `TV-NNN` | **RG** | EphemeralValue cleared after super-step |
| BC-2.02.005 | SS-02 | 6 | — | `TV-NNN` | | Conditional edge routing |
| BC-2.02.006 | SS-02 | 6 | — | `TV-NNN` | | Send API fan-out |
| BC-2.03.001 | SS-03 | 5 | — | `TV-NNN` | | BSP determinism; VP seed |
| BC-2.03.002 | SS-03 | 5 | — | `TV-NNN` | | Concurrent LastValue → InvalidUpdateError |
| BC-2.03.003 | SS-03 | 5 | — | `TV-NNN` | | Task-identity sort order |
| BC-2.04.001 | SS-04 | 5 | — | narrative | | put_writes before next super-step |
| BC-2.04.002 | SS-04 | 5 | — | narrative | | Sync tier is default |
| BC-2.04.003 | SS-04 | 5 | — | narrative | | Monotonic clock rejects wall-clock |
| BC-2.04.004 | SS-04 | 5 | — | narrative | | Fork via parent_checkpoint_id |
| BC-2.04.005 | SS-04 | 5 | — | narrative | | Crash recovery; completed not re-run |
| BC-2.04.006 | SS-04 | 5 | — | narrative | | Triple-address uniqueness; VP seed |
| BC-2.04.007 | SS-04 | 5 | — | narrative | | Encryption covers state AND events |
| BC-2.04.008 | SS-04 | 6 | — | `TV-NNN` | | FTS conversation search (SQLite FTS5; single-process) |
| BC-2.05.001 | SS-05 | 5 | — | `TV-NNN` | | Interrupt + durable suspend |
| BC-2.05.002 | SS-05 | 5 | — | `TV-NNN` | | FIFO resume order |
| BC-2.05.003 | SS-05 | 5 | — | `TV-NNN` | | Node re-executes from start on resume |
| BC-2.05.004 | SS-05 | 6 | — | `TV-NNN` | | Command(resume=value) API |
| BC-2.05.005 | SS-05 | 5 | — | `TV-NNN` | | Empty queue → Err(NoActiveInterrupt) |
| BC-2.05.006 | SS-05 | 6 | — | `TV-NNN` | | Risk-tiered classification for Domain A |
| BC-2.06.001 | SS-06 | 5 | — | `TV-NNN` | | Typed event taxonomy |
| BC-2.06.002 | SS-06 | 5 | — | `TV-NNN` | | run_id + parent_ids correlation |
| BC-2.06.003 | SS-06 | 5 | — | `TV-NNN` | | Streaming/unary identical final answer |
| BC-2.07.001 | SS-07 | 7 | — | `TV-NNN` | | Code-point chunk size (not bytes) |
| BC-2.07.002 | SS-07 | 3 | 9 | `TV-NNN` + GTV | **RG** | Non-ASCII parity (see §GTV below) |
| BC-2.07.003 | SS-07 | 7 | — | `TV-NNN` | | Short doc < chunk_size → single chunk |
| BC-2.08.001 | SS-08 | 4 | — | `TV-NNN` | | Streaming conformance |
| BC-2.08.002 | SS-08 | 5 | — | `TV-NNN` | | Tool-call round-trip conformance |
| BC-2.08.003 | SS-08 | 5 | — | `TV-NNN` | | Structured output conformance |
| BC-2.08.004 | SS-08 | 5 | — | `TV-NNN` | | Error-type fidelity conformance |
| BC-2.08.005 | SS-08 | 5 | — | `TV-NNN` | | Token-usage accounting conformance |
| BC-2.08.006 | SS-08 | 4 | — | `TV-NNN` | | SDK crate split (sdk + adapter) |
| BC-2.08.007 | SS-08 | 5 | — | `TV-NNN` | | Transport error → Err(Timeout) |
| BC-2.08.008 | SS-08 | 5 | — | `TV-NNN` | | Eval arithmetic mean + InfraError |
| BC-2.08.009 | SS-08 | 5 | — | `TV-NNN` | | Schema naming stability snapshot |
| BC-2.08.010 | SS-08 | 5 | — | `TV-NNN` | | `#[tool]` proc-macro |
| BC-2.08.011 | SS-08 | 5 | — | `TV-NNN` | | `#[entrypoint]` proc-macro |
| BC-2.08.012 | SS-08 | 5 | — | `TV-NNN` | | `#[task]` proc-macro |
| BC-2.08.013 | SS-08 | 6 | — | `TV-NNN` | | Pluggable tool-call dialect (ToolCallDialect; Hermes ChatML XML) |
| BC-2.08.014 | SS-08 | 7 | — | `TV-NNN` | | Provider failover chain (ProviderFallbackPolicy; 429/5xx/auth) |
| BC-2.09.001 | SS-09 | 7 | — | `TV-NNN` | | MCP tool discovery |
| BC-2.09.002 | SS-09 | 7 | — | `TV-NNN` | | ToolInvocation routing |
| BC-2.09.003 | SS-09 | 5 | — | `TV-NNN` | | Tool-result as untrusted ingress |
| BC-2.09.004 | SS-09 | 5 | — | `TV-NNN` | **RG** | Bare ToolException re-raise |
| BC-2.09.005 | SS-09 | 5 | — | `TV-NNN` | **RG** | MultiServerMcpClient no live connections |
| BC-2.09.006 | SS-09 | 6 | — | `TV-NNN` | | MCP server tool advertisement (tools/list; mcp::server) |
| BC-2.09.007 | SS-09 | 6 | — | `TV-NNN` | | MCP server tool invocation (tools/call; external client) |
| BC-2.10.001 | SS-10 | 5 | — | `TV-NNN` | | Budget allow/escalate/deny evaluation |
| BC-2.10.002 | SS-10 | 5 | — | `TV-NNN` | | EvidenceJournal append-only |
| BC-2.10.003 | SS-10 | 7 | — | `TV-NNN` | | Graceful halt \| summarize on ceiling (v1.2 adds TV-006/007) |
| BC-2.10.004 | SS-10 | 5 | — | `TV-NNN` | | Budget escalation → HITL |
| BC-2.11.001 | SS-11 | 5 | — | narrative | | ProvenanceTag at all ingress boundaries |
| BC-2.11.002 | SS-11 | 6 | — | narrative | | GuardrailHook at tool-result ingress |
| BC-2.11.003 | SS-11 | 5 | — | narrative | | GuardrailHook at RAG ingress |
| BC-2.11.004 | SS-11 | 5 | — | narrative | | GuardrailHook at memory ingress |
| BC-2.11.005 | SS-11 | 5 | — | narrative | | Rejected content never in model context |
| BC-2.11.006 | SS-11 | 5 | — | narrative | | No-hook default: WARNING LOG |
| BC-2.12.001 | SS-12 | 7 | — | `TV-NNN` | | Thread CRUD |
| BC-2.12.002 | SS-12 | 7 | — | `TV-NNN` | | Assistant CRUD |
| BC-2.12.003 | SS-12 | 7 | — | `TV-NNN` | | Run lifecycle |
| BC-2.12.004 | SS-12 | 7 | — | `TV-NNN` | | CronSchedule + proactive run |
| BC-2.12.005 | SS-12 | 7 | — | `TV-NNN` | | SecurityConfig::default() deny-CORS |
| BC-2.12.006 | SS-12 | 6 | — | `TV-NNN` | | Trait seams (IdempotencyStore etc.) |
| BC-2.12.007 | SS-12 | 6 | — | `TV-NNN` | | Streaming/unary same graph engine |
| BC-2.13.001 | SS-13 | 5 | — | narrative | | Enforcing sandbox is default |
| BC-2.13.002 | SS-13 | 5 | — | narrative | | Process backend requires explicit opt-in |
| BC-2.13.003 | SS-13 | 6 | — | narrative | | Strict policy + non-enforcing → Err |
| BC-2.13.004 | SS-13 | 6 | — | narrative | | canonicalize_beneath_root; VP seed |
| BC-2.13.005 | SS-13 | 6 | — | narrative | | Symlink escape → Err(WorkspaceEscape) |
| BC-2.13.006 | SS-13 | 6 | — | narrative | | macOS Seatbelt deny-by-default |
| BC-2.13.007 | SS-13 | 6 | — | `TV-NNN` | | Env var sanitization at sandbox execution boundary |
| BC-2.14.001 | SS-14 | 5 | — | `TV-NNN` | | FerrochainError 2D struct |
| BC-2.14.002 | SS-14 | 5 | — | `TV-NNN` | | RFC-7807 emission |
| BC-2.14.003 | SS-14 | 5 | — | `TV-NNN` | | Constructor Result; no unwrap |
| BC-2.14.004 | SS-14 | 5 | — | `TV-NNN` | | HTTP timeout 30s enforced |
| BC-2.14.005 | SS-14 | 5 | — | `TV-NNN` | | API key newtype redacted Debug |
| BC-2.14.006 | SS-14 | 5 | — | `TV-NNN` | | No silent None for validation failure |
| BC-2.15.001 | SS-15 | 7 | — | `TV-NNN` | | KV/vector memory across threads |
| BC-2.15.002 | SS-15 | 7 | — | `TV-NNN` | | User/app/session tier isolation |
| BC-2.15.003 | SS-15 | 7 | — | `TV-NNN` | | GDPR erasure all tiers |
| BC-2.15.004 | SS-15 | 7 | — | `TV-NNN` | | SkillStore registry — load-on-demand skill documents |
| BC-2.15.005 | SS-15 | 7 | — | `TV-NNN` | | Guarded memory and skill writes (MemoryWriteGuard) |
| BC-2.15.006 | SS-15 | 6 | — | `TV-NNN` | | Frozen-snapshot context mutation (memory-sourced sys prompt) |
| BC-2.16.001 | SS-16 | 5 | — | `TV-NNN` | | Retry keyed by tool_name not args |
| BC-2.16.002 | SS-16 | 5 | — | `TV-NNN` | | Finite global_limit non-None |
| BC-2.16.003 | SS-16 | 5 | — | `TV-NNN` | | Circuit breaker after repeated failure |
| BC-2.17.001 | SS-17 | 5 | — | `TV-NNN` | | Kani harness scope (all 3 VPs) |
| BC-2.17.002 | SS-17 | 5 | — | `TV-NNN` | | cargo-fuzz targets |

**Total vectors (95 authored BCs):** approximately 534 canonical test vectors across 95 BC files.

**Red Gate BCs (5):** BC-2.02.003, BC-2.02.004, BC-2.07.002, BC-2.09.004, BC-2.09.005

---

## Golden Test Vectors — BC-2.07.002 (Non-ASCII Boundary Parity)

> **Source of truth:** `behavioral-contracts/ss-07/BC-2.07.002.md §Golden Test Vectors`
> These GTVs are reproduced here as a convenience for the test-writer.
> The BC file is authoritative; this section is a read-only copy.
>
> **Red Gate requirement:** `tests/red_gate/test_BC_2_07_002_python_parity.rs` must be
> committed and FAILING before any splitter implementation code is written (D17-Q9).
>
> **Reference implementation:** `langchain_text_splitters.RecursiveCharacterTextSplitter`
> with `separators=["\n\n", "\n", " ", ""]` and `length_function=len` (code-point counts).

### Group 1: Emoji (U+1F600 family, 4 bytes each in UTF-8)

| GTV ID | Input | chunk_size | overlap | Expected Chunks |
|--------|-------|------------|---------|-----------------|
| GTV-001 | `"😀😃😄😁😆"` (5 emoji = 5 code pts, 20 bytes) | 3 | 0 | `["😀😃😄", "😁😆"]` |
| GTV-002 | `"😀😃😄😁😆"` (5 emoji) | 3 | 1 | `["😀😃😄", "😄😁😆"]` |
| GTV-003 | `"hello 😀 world"` (13 code pts) | 7 | 0 | `["hello", "😀 world"]` (after separator split on space) |
| GTV-004 | `"😀" * 100` (100 emoji, 400 bytes) | 10 | 0 | 10 chunks of 10 emoji each |

### Group 2: CJK Unified Ideographs (U+4E00–U+9FFF, 3 bytes each in UTF-8)

| GTV ID | Input | chunk_size | overlap | Expected Chunks |
|--------|-------|------------|---------|-----------------|
| GTV-005 | `"中文测试内容"` (6 CJK = 6 code pts, 18 bytes) | 3 | 0 | `["中文测", "试内容"]` |
| GTV-006 | `"中文测试内容"` (6 CJK) | 3 | 1 | `["中文测", "测试内", "内容"]` |
| GTV-007 | `"a中b文c"` (5 code pts: 1+1+1+1+1) | 3 | 0 | `["a中b", "文c"]` |

### Group 3: Mixed ASCII and Multi-Byte

| GTV ID | Input | chunk_size | overlap | Expected Chunks |
|--------|-------|------------|---------|-----------------|
| GTV-008 | `"abc" + "🎉" * 5 + "xyz"` (3+5+3=11 code pts) | 5 | 0 | `["abc🎉🎉", "🎉🎉🎉x", "yz"]` **(PROVISIONAL — must be Python-verified before Red Gate test is written)** |
| GTV-009 | `"ñoño"` (4 code pts: ñ=U+00F1, o, ñ, o — 2 bytes each for ñ) | 2 | 0 | `["ño", "ño"]` |

> **Note on GTV-003 and GTV-008:** Exact expected chunks depend on separator logic.
> GTV-008 carries a concrete value copied from BC-2.07.002 (the authoritative source); it is
> marked **PROVISIONAL** pending verification against the Python reference implementation.
> Values marked PROVISIONAL must be Python-verified before the Red Gate test is written —
> do not commit a Red Gate test that hard-codes a PROVISIONAL expected value.
> GTV-003 has no concrete value and must be computed from the reference before any test is authored.
> The test-writer MUST run `langchain_text_splitters.RecursiveCharacterTextSplitter` with the
> specified parameters and replace the PROVISIONAL marker with a VERIFIED confirmation once validated.

---

## Red Gate Vector Summary

| BC ID | Red Gate Test File | D17 Source | Test Must FAIL Before |
|-------|-------------------|-----------|----------------------|
| BC-2.02.003 | `tests/red_gate/test_BC_2_02_003_named_barrier.rs` | R10 | NamedBarrierValue implementation |
| BC-2.02.004 | `tests/red_gate/test_BC_2_02_004_ephemeral_value.rs` | R10 | EphemeralValue implementation |
| BC-2.07.002 | `tests/red_gate/test_BC_2_07_002_python_parity.rs` | R8 | ferrochain-splitters implementation |
| BC-2.09.004 | `tests/red_gate/test_BC_2_09_004_tool_exception.rs` | R11 | ferrochain-mcp ToolException impl |
| BC-2.09.005 | `tests/red_gate/test_BC_2_09_005_no_live_connections.rs` | R11 | MultiServerMcpClient impl |

---

## Usage Notes for test-writer

1. **Happy-path minimum:** Each BC has at least one happy-path vector. Start there.
2. **GTV discipline (BC-2.07.002):** Do not author the GTV-based tests until you have
   run the reference Python implementation to verify GTV-003 and GTV-008. Use
   `langchain_text_splitters==0.3.8` (or the version in L2-INDEX.md).
3. **Narrative format (SS-04, SS-11, SS-13):** Test vectors in these BCs use prose
   descriptions rather than `TV-NNN` tables. Translate each row into a test scenario
   following the same naming convention: `test_BC_S_SS_NNN_<short_description>`.
4. **Integration tests:** BCs marked `I` in the PRD RTM Test Types column require a
   running ferrochain instance or mock. Structure these under `tests/integration/`.
5. **Soak tests:** BCs marked `S` (BC-2.04.001, BC-2.04.005, BC-2.06.003, BC-2.12.007)
   require sustained execution; put them under a `#[ignore]` soak feature flag.

---

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.4 | 2026-07-15 | F-P73-01: added 9 D20 BC inventory rows (BC-2.04.008, BC-2.08.013, BC-2.08.014, BC-2.09.006, BC-2.09.007, BC-2.13.007, BC-2.15.004, BC-2.15.005, BC-2.15.006) with live-derived vector counts; BC-2.10.003 TV count corrected 5→7 (v1.2 added TV-006/007 for OnCeiling::Summarize + RunContext.budget_info); total updated 86→95 BCs, ~475→~534 vectors; frontmatter input-hash annotation updated 86→95. | F-P73-01 |
| 1.3 | 2026-07-15 | F-P64-02 sweep fix: corrected v1.1 changelog row date `2026-07-16` → `2026-07-14` (same root cause as bc-authoring-plan.md v1.1; PASS-36 = 2026-07-14). No content change; metadata-only. (F-P64-02, ADV-P1D-PASS-64) | F-P64-02 |
| 1.2 | 2026-07-14 | GTV annotation sync (OBS-P37-2): GTV-003 Expected-cell parenthetical corrected to match BC-2.07.002.md authoritative text ("after separator split on space"); GTV-008 Input-cell code-point note corrected ("3+5+3=11 code pts"); GTV-009 Input-cell annotation corrected ("4 code pts: ñ=U+00F1, o, ñ, o — 2 bytes each for ñ"). All 9 GTV rows now byte-identical to BC-2.07.002.md including non-normative annotations (ADV-P1D-PASS-37) | OBS-P37-2 |
| 1.1 | 2026-07-14 | GTV-008 row synced to concrete value `["abc🎉🎉", "🎉🎉🎉x", "yz"]` with PROVISIONAL marker (was: placeholder); GTV-003/GTV-008 note updated to clarify PROVISIONAL semantics; removed contradictory "Do not hard-code these without verification" language (F-P36-03 fix, ADV-P1D-PASS-36) | F-P36-03 |
| 1.0 | 2026-07-13 | Initial authoring | Greenfield Phase 1a |
