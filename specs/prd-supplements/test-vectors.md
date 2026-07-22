---
document_type: prd-supplement-test-vectors
level: L3
version: "2.3"
status: active
producer: product-owner
timestamp: 2026-07-22T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.001.md
  - .factory/specs/behavioral-contracts/ss-07/BC-2.07.002.md
input-hash: "ef6bd52"
traces_to: prd.md
primary_consumers: [test-writer, holdout-evaluator]
changelog:
  - "2.3 (burst-234/F-P134-01/2026-07-22): BC-2.23.006 TV count 5→6 (+TV-006 traversal I/O error, E-TOOLS-008). Grand total 669→670 (661 canonical + 9 GTV). Notes column updated to add E-TOOLS-008 cite."
  - "2.2 (D23/2026-07-22): Add 13 new D23 BC rows (+60 TVs); grand total 609→669 (660 canonical + 9 GTV). New rows: BC-2.05.007 (6 TV, VP-011 Kani seed), BC-2.05.008 (4 TV), BC-2.06.004 (4 TV), BC-2.06.005 (3 TV), BC-2.06.006 (4 TV), BC-2.10.005 (5 TV, VP-012 Kani seed), BC-2.10.006 (4 TV), BC-2.23.001 (5 TV), BC-2.23.002 (5 TV), BC-2.23.003 (5 TV), BC-2.23.004 (4 TV), BC-2.23.005 (6 TV, VP-013 Kani seed), BC-2.23.006 (5 TV). BC count 116→129."
  - "2.1 (D21/2026-07-21): Initial supplement created from prd.md §7 RTM inventory. 116 BCs catalogued; 600 canonical TV + 9 GTV = 609 total. RG BCs: 11. GTV source: BC-2.07.002 §Golden Test Vectors."
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
| BC-2.04.001 | SS-04 | 4 | — | table (unlabelled) | | put_writes before next super-step |
| BC-2.04.002 | SS-04 | 4 | — | table (unlabelled) | | Sync tier is default |
| BC-2.04.003 | SS-04 | 4 | — | table (unlabelled) | | Monotonic clock rejects wall-clock |
| BC-2.04.004 | SS-04 | 4 | — | table (unlabelled) | | Fork via parent_checkpoint_id |
| BC-2.04.005 | SS-04 | 5 | — | table (unlabelled) | | Crash recovery; completed not re-run |
| BC-2.04.006 | SS-04 | 4 | — | table (unlabelled) | | Triple-address uniqueness; VP seed |
| BC-2.04.007 | SS-04 | 4 | — | table (unlabelled) | | Encryption covers state AND events |
| BC-2.04.008 | SS-04 | 6 | — | `TV-NNN` | | FTS conversation search (SQLite FTS5; single-process) |
| BC-2.05.001 | SS-05 | 5 | — | `TV-NNN` | | Interrupt + durable suspend |
| BC-2.05.002 | SS-05 | 5 | — | `TV-NNN` | | FIFO resume order |
| BC-2.05.003 | SS-05 | 5 | — | `TV-NNN` | | Node re-executes from start on resume |
| BC-2.05.004 | SS-05 | 6 | — | `TV-NNN` | | Command(resume=value) API |
| BC-2.05.005 | SS-05 | 8 | — | `TV-NNN` | | Empty queue → Err(NoActiveInterrupt) (v1.5 adds TV-006/007/008) |
| BC-2.05.006 | SS-05 | 6 | — | `TV-NNN` | | Risk-tiered classification for Domain A |
| BC-2.05.007 | SS-05 | 6 | — | `TV-NNN` | | PreToolCallHook dispatch — Approve/Deny/Edit/PendingHumanApproval; fail-closed Deny (VP-011 Kani seed) |
| BC-2.05.008 | SS-05 | 4 | — | `TV-NNN` | | Skip-hook-on-resume invariant; ToolApprovalRequest checkpoint persistence |
| BC-2.06.001 | SS-06 | 5 | — | `TV-NNN` | | Typed event taxonomy |
| BC-2.06.002 | SS-06 | 5 | — | `TV-NNN` | | run_id + parent_ids correlation |
| BC-2.06.003 | SS-06 | 5 | — | `TV-NNN` | | Streaming/unary identical final answer |
| BC-2.06.004 | SS-06 | 4 | — | `TV-NNN` | | `tool_approval_request` StreamEvent (event 13); payload; emission before interrupt |
| BC-2.06.005 | SS-06 | 3 | — | `TV-NNN` | | `tool_approval_resolved` StreamEvent (event 14); payload on Command::Resume |
| BC-2.06.006 | SS-06 | 4 | — | `TV-NNN` | | `compaction_event` StreamEvent (event 15); payload; emission after compaction completes |
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
| BC-2.10.004 | SS-10 | 6 | — | `TV-NNN` | | Budget escalation → HITL (v1.5 adds TV-006) |
| BC-2.10.005 | SS-10 | 5 | — | `TV-NNN` | | CompactionTrigger config — Disabled/OnWatermark/OnMessageCount/OnTokenCount (VP-012 Kani seed) |
| BC-2.10.006 | SS-10 | 4 | — | `TV-NNN` | | Compaction execution — ConversationSnapshot, mid-run REPLACEMENT, EvidenceJournal, checkpoint immutability |
| BC-2.11.001 | SS-11 | 4 | — | table (unlabelled) | | ProvenanceTag at all ingress boundaries |
| BC-2.11.002 | SS-11 | 5 | — | table (unlabelled) | | GuardrailHook at tool-result ingress |
| BC-2.11.003 | SS-11 | 4 | — | table (unlabelled) | | GuardrailHook at RAG ingress |
| BC-2.11.004 | SS-11 | 4 | — | table (unlabelled) | | GuardrailHook at memory ingress |
| BC-2.11.005 | SS-11 | 4 | — | table (unlabelled) | | Rejected content never in model context |
| BC-2.11.006 | SS-11 | 4 | — | table (unlabelled) | | No-hook default: WARNING LOG |
| BC-2.12.001 | SS-12 | 7 | — | `TV-NNN` | | Thread CRUD |
| BC-2.12.002 | SS-12 | 7 | — | `TV-NNN` | | Assistant CRUD |
| BC-2.12.003 | SS-12 | 7 | — | `TV-NNN` | | Run lifecycle |
| BC-2.12.004 | SS-12 | 7 | — | `TV-NNN` | | CronSchedule + proactive run |
| BC-2.12.005 | SS-12 | 7 | — | `TV-NNN` | | SecurityConfig::default() deny-CORS |
| BC-2.12.006 | SS-12 | 6 | — | `TV-NNN` | | Trait seams (IdempotencyStore etc.) |
| BC-2.12.007 | SS-12 | 6 | — | `TV-NNN` | | Streaming/unary same graph engine |
| BC-2.13.001 | SS-13 | 4 | — | table (unlabelled) | | Enforcing sandbox is default |
| BC-2.13.002 | SS-13 | 4 | — | table (unlabelled) | | Process backend requires explicit opt-in |
| BC-2.13.003 | SS-13 | 5 | — | table (unlabelled) | | Strict policy + non-enforcing → Err |
| BC-2.13.004 | SS-13 | 5 | — | table (unlabelled) | | canonicalize_beneath_root; VP seed |
| BC-2.13.005 | SS-13 | 5 | — | table (unlabelled) | | Symlink escape → Err(WorkspaceEscape) |
| BC-2.13.006 | SS-13 | 5 | — | table (unlabelled) | | macOS Seatbelt deny-by-default |
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
| BC-2.18.001 | SS-18 | 6 | — | `TV-NNN` | | PromptTemplate f-string render; partial binding; strict-undefined guard |
| BC-2.18.002 | SS-18 | 4 | — | `TV-NNN` | | ChatPromptTemplate multi-message render; PromptValue + MessageProvenance |
| BC-2.18.003 | SS-18 | 4 | — | `TV-NNN` | | MessagesPlaceholder expansion; FewShotPromptTemplate composition |
| BC-2.18.004 | SS-18 | 4 | — | `TV-NNN` | **RG** | injection_guard — TrustRequired slot + Untrusted tag → E-TMPL-001 |
| BC-2.18.005 | SS-18 | 4 | — | `TV-NNN` | **RG** | SlotTrustPolicy::TrustAll on SystemMessage → E-TMPL-002 at construction |
| BC-2.19.001 | SS-19 | 4 | — | `TV-NNN` | | LcSerializable round-trip; Serialized::Constructor form |
| BC-2.19.002 | SS-19 | 4 | — | `TV-NNN` | | lc_secrets() strips credential fields before serialization |
| BC-2.19.003 | SS-19 | 4 | — | `TV-NNN` | | Inventory-based type registry; OnceLock allowlist |
| BC-2.19.004 | SS-19 | 4 | — | `TV-NNN` | | Legacy namespace remap; OLD_CORE_NAMESPACES_MAPPING aliases |
| BC-2.19.005 | SS-19 | 4 | — | `TV-NNN` | **RG** | Reviver allowlist containment — unregistered id → E-SRLZ-001 (VP-010) |
| BC-2.19.006 | SS-19 | 4 | — | `TV-NNN` | | Langchain-monolith type ids → E-SRLZ-002 (not silent None) |
| BC-2.20.001 | SS-20 | 3 | — | `TV-NNN` | | Retriever trait; get_relevant_documents dyn-compatible; Arc<dyn Retriever> |
| BC-2.20.002 | SS-20 | 3 | — | `TV-NNN` | **RG** | BoundaryType::RAGRetrieval guardrail covers all Retriever returns (DI-012) |
| BC-2.20.003 | SS-20 | 5 | — | `TV-NNN` | | VectorStoreRetriever; SearchType; k/fetch_k/lambda_mult config; as_retriever() |
| BC-2.21.001 | SS-21 | 5 | — | `TV-NNN` | | VectorStore trait; VectorStoreFactory; Arc<dyn VectorStore> dyn-safety |
| BC-2.21.002 | SS-21 | 6 | — | `TV-NNN` | (v1.1 adds TV-006) | InMemoryVectorStore; Arc<dyn Embeddings> DI; cosine similarity; write-time zero-norm guard E-VS-004 |
| BC-2.21.003 | SS-21 | 5 | — | `TV-NNN` | **RG** | Zero-norm guard — cosine denominator → E-VS-001 before division (VP-009) |
| BC-2.21.004 | SS-21 | 5 | — | `TV-NNN` | | MetadataFilter Eq/Ne/In; similarity_search_with_filter; #[non_exhaustive] |
| BC-2.22.001 | SS-22 | 5 | — | `TV-NNN` | | Embeddings trait; embed_documents batch; dimensionality contract → E-EMBED-001 (VP-008) |
| BC-2.22.002 | SS-22 | 5 | — | `TV-NNN` | **RG** | EmbeddingsOpenAI; OpenAiApiKey redacted-Debug credential opacity (DI-010) |
| BC-2.22.003 | SS-22 | 5 | — | `TV-NNN` | | EmbeddingsOllama; no API key; POST /api/embed; use_legacy_endpoint toggle |
| BC-2.23.001 | SS-23 | 5 | — | `TV-NNN` | | ReadFileTool — PathGuard-confined file read; 1 MiB max_bytes; E-TOOLS-001/002 |
| BC-2.23.002 | SS-23 | 5 | — | `TV-NNN` | | WriteFileTool — PathGuard-confined atomic write; High ActionRisk; E-TOOLS-001 |
| BC-2.23.003 | SS-23 | 5 | — | `TV-NNN` | | EditFileTool — exact-match string replace; E-TOOLS-003 on no-match; opt-in fuzzy fallback |
| BC-2.23.004 | SS-23 | 4 | — | `TV-NNN` | | ListDirTool — PathGuard-confined directory listing; ReadOnly; DirEntry struct; E-TOOLS-001 |
| BC-2.23.005 | SS-23 | 6 | — | `TV-NNN` | | BashTool — sandboxed shell; non-lowerable Medium risk floor; 256 KiB cap; 30 s timeout (VP-013 Kani seed) |
| BC-2.23.006 | SS-23 | 6 | — | `TV-NNN` | | GrepTool — in-process regex; linear-time `regex`; max_results 100 cap; PathGuard scope; E-TOOLS-001/006/008/009 (TV-006 traversal I/O error) |

**Total vectors (129 authored BCs):** 661 canonical test vectors (TV Count column) + 9 golden test vectors (GTV Count column, BC-2.07.002 only) = **670 total vectors** across 129 BC files.

> **GTV convention:** The TV Count column counts standard canonical vectors; the GTV Count column counts golden test vectors (Red Gate acceptance data reproduced in §GTV). Grand totals are expressed as `<TV Count> + <GTV Count> = <total>` to prevent ambiguity.

**Red Gate BCs (11):** BC-2.02.003, BC-2.02.004, BC-2.07.002, BC-2.09.004, BC-2.09.005, BC-2.18.004, BC-2.18.005, BC-2.19.005, BC-2.20.002, BC-2.21.003, BC-2.22.002

---

## Per-Subsystem Test Vectors

> **Index model:** Canonical per-BC vectors reside in individual BC files under
> `behavioral-contracts/ss-NN/BC-S.SS.NNN.md`. The inventory table above is the
> authoritative index. Per-subsystem inline vector tables are not duplicated here —
> see each BC file's `## Test Vectors` section for the full `TV-NNN` rows.

Canonical per-BC vector tables reside in the individual BC files
(`behavioral-contracts/ss-NN/BC-S.SS.NNN.md §Test Vectors`). No inline per-subsystem
duplication exists in this supplement by design — the BC Test Vector Inventory table above
is the authoritative index. To inspect a specific BC's vectors, load the corresponding BC file.

---

## Cross-Subsystem Integration Vectors

> Integration scenarios that span multiple subsystems. These are not covered by
> individual BC files and require end-to-end test composition.

Cross-subsystem integration scenarios are authored by the test-writer at Phase 3 from the
wave schedule (`stories/STORY-INDEX.md`). This section is populated during Phase 3 story
delivery; no integration vectors exist at Phase 1a by design.

---

## Golden File References

> Pointers to golden test data files on disk. BC-2.07.002 GTVs are reproduced
> inline in §Golden Test Vectors below; this table references persistent fixture
> files when they exist.

| Vector Set | File | Format | BC Coverage |
|-----------|------|--------|------------|
| Non-ASCII splitter parity | `tests/fixtures/splitter_golden.toml` (created at Phase 3) | TOML | BC-2.07.002 |

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
| BC-2.18.004 | `tests/red_gate/test_BC_2_18_004_injection_guard.rs` | ADR-015 Security Invariant 1 | injection_guard impl in ferrochain-prompts |
| BC-2.18.005 | `tests/red_gate/test_BC_2_18_005_trustall_rejection.rs` | ADR-015 Security Invariant 2 | from_messages() SlotTrustPolicy guard in ferrochain-prompts |
| BC-2.19.005 | `tests/red_gate/test_BC_2_19_005_reviver_allowlist.rs` | ADR-016 Security Invariant | Reviver::revive() in ferrochain-core |
| BC-2.20.002 | `tests/red_gate/test_BC_2_20_002_rag_guardrail.rs` | ADR-014 §DI-012 | Retriever guardrail wiring in ferrochain-graph |
| BC-2.21.003 | `tests/red_gate/test_BC_2_21_003_zero_norm_guard.rs` | ADR-014 v1.1 Hardening | cosine similarity impl in ferrochain-vectorstores |
| BC-2.22.002 | `tests/red_gate/test_BC_2_22_002_credential_opacity.rs` | DI-010 Credential Opacity | EmbeddingsOpenAI::new() credential impl in ferrochain-openai |

---

## Usage Notes for test-writer

1. **Happy-path minimum:** Each BC has at least one happy-path vector. Start there.
2. **GTV discipline (BC-2.07.002):** Do not author the GTV-based tests until you have
   run the reference Python implementation to verify GTV-003 and GTV-008. Use
   `langchain_text_splitters==0.3.8` (or the version in L2-INDEX.md).
3. **Table (unlabelled) format (SS-04, SS-11, SS-13):** Test vectors in these BCs use
   markdown tables with `| Input | Expected Output | Category |` columns but without
   `TV-NNN` row identifiers (contrast with `TV-NNN` tables in SS-01–SS-03, SS-05–SS-10,
   SS-12, SS-14–SS-17). The header row is NOT a test vector — TV Count in the inventory
   above counts data rows only. Translate each data row into a test scenario following
   the naming convention: `test_BC_S_SS_NNN_<short_description>`.
4. **Integration tests:** BCs marked `I` in the PRD RTM Test Types column require a
   running ferrochain instance or mock. Structure these under `tests/integration/`.
5. **Soak tests:** BCs marked `S` (BC-2.04.001, BC-2.04.005, BC-2.06.003, BC-2.12.007)
   require sustained execution; put them under a `#[ignore]` soak feature flag.

---

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 2.3 | 2026-07-22 | burst-234/F-P134-01: BC-2.23.006 TV count 5→6 (+TV-006 traversal I/O error, E-TOOLS-008 FileIoError). Grand total 669→670 (661 canonical + 9 GTV). Notes column updated to cite E-TOOLS-008/009. | burst-234/F-P134-01 |
| 2.2 | 2026-07-22 | D23: Add 13 new D23 BC rows (+60 TVs); grand total 609→669 (660 canonical + 9 GTV). New rows: BC-2.05.007 (6 TV, VP-011 Kani seed), BC-2.05.008 (4 TV), BC-2.06.004 (4 TV), BC-2.06.005 (3 TV), BC-2.06.006 (4 TV), BC-2.10.005 (5 TV, VP-012 Kani seed), BC-2.10.006 (4 TV), BC-2.23.001 (5 TV), BC-2.23.002 (5 TV), BC-2.23.003 (5 TV), BC-2.23.004 (4 TV), BC-2.23.005 (6 TV, VP-013 Kani seed), BC-2.23.006 (5 TV). BC count 116→129. | D23 |
| 2.1 | 2026-07-21 | F-P224/H-2: BC-2.21.002 v1.1 adds TV-006 (write-time zero-norm guard — add_texts returns Err(E-VS-004) when any document embedding has L2 norm == 0.0; document_index context field). BC-2.21.002 row: TV Count 5→6. SS-21 subtotal: 20→21 TVs (BC-2.21.001=5, BC-2.21.002=6, BC-2.21.003=5, BC-2.21.004=5). Grand total: 599→600 canonical TVs; 600+9 GTVs = 609 total vectors. | F-P224, H-2 |
| 2.0 | 2026-07-20 | D21/Batch-3b-ii: Added 21 new BC inventory rows (SS-18 BCs 2.18.001–005, SS-19 BCs 2.19.001–006, SS-20 BCs 2.20.001–003, SS-21 BCs 2.21.001–004, SS-22 BCs 2.22.001–003). SS-18 subtotal=22 TVs, SS-19=24, SS-20=11, SS-21=20, SS-22=15; total new canonical TVs=92. Grand total updated: 507→599 canonical TVs; 599+9 GTVs = 608 total vectors. Red Gate BCs updated from 5→11: added BC-2.18.004, BC-2.18.005, BC-2.19.005, BC-2.20.002, BC-2.21.003, BC-2.22.002 to Red Gate Vector Summary. | D21/ADR-014/015/016/017 |
| 1.9 | 2026-07-19 | F-P119-01 + OBS-1 + OBS-2, fix burst 122: BC-2.05.005 v1.4→v1.5 adds 3 canonical TVs (TV-006 summary_halt guard, TV-007 queued guard, TV-008 cancelled guard per OBS-1 production-grade totality adjudication). BC-2.05.005 row: TV Count 5→8; Notes updated to '(v1.5 adds TV-006/007/008)'. SS-05 subtotal 32→35. Grand total: 504→507 canonical TVs; 507+9 GTVs = 516 total vectors. | F-P119-01 |
| 1.8 | 2026-07-17 | F-P94-02: Convention verdict — renumber (option ii): TV-001b in BC-2.10.004 renamed TV-006, eliminating the corpus's only lettered sub-vector. BC-2.10.004 row: TV Count 5→6, Notes updated to "(v1.5 adds TV-006)". Recount from ground truth: SS-10 subtotal 22→23 (BC-2.10.001=5, BC-2.10.002=5, BC-2.10.003=7, BC-2.10.004=6). Grand total: 503→504 canonical TVs; 504+9 GTVs = 513 total vectors. BC-2.10.004 v1.4→v1.5. | F-P94-02 |
| 1.7 | 2026-07-16 | F-P86-01: replaced TODO markers with authoritative forward-reference text in two sections. Per-Subsystem Test Vectors: removed conditional TODO, replaced with authoritative statement that canonical per-BC vectors reside in individual BC files (`behavioral-contracts/ss-NN/BC-S.SS.NNN.md §Test Vectors`); no inline duplication by design. Cross-Subsystem Integration Vectors: removed empty placeholder table row, replaced with forward-reference statement that integration scenarios are authored by test-writer at Phase 3 from the wave schedule (`stories/STORY-INDEX.md`). Retroactive changelog note: v1.6 added three template-conformance sections (Per-Subsystem Test Vectors, Cross-Subsystem Integration Vectors, Golden File References) as structural stubs per template compliance; this was not recorded in the v1.6 changelog entry. | F-P86-01 |
| 1.6 | 2026-07-16 | F-P85-04 (MED): Grand-total reconciliation. Independent recount of TV Count column (95 rows, header excluded) yields 503 canonical test vectors (per-SS: SS-01=20, SS-02=33, SS-03=15, SS-04=35, SS-05=32, SS-06=15, SS-07=17, SS-08=71, SS-09=41, SS-10=22, SS-11=25, SS-12=47, SS-13=34, SS-14=30, SS-15=41, SS-16=15, SS-17=10). BC-2.07.002 GTV Count column = 9 golden test vectors (separate classification from canonical TVs). Convention established: 503 canonical TVs + 9 GTVs = 512 total vectors. Old total "approximately 516" replaced with exact reconciled figures. "approximately" hedge removed. v1.5 figure of 516 was carried forward from the v1.5 "534→516 (−18)" arithmetic without a fresh row-sum. Sibling-sweep: no other .factory/specs/ or .factory/planning/ documents cite 516 as a test-vector total. Stale "516" appears only in this file's grand-total line (fixed here) and in v1.5 changelog history (preserved). | F-P85-04 |
| 1.5 | 2026-07-15 | F-P84-01 + OBS-P84-A + OBS-P84-B (D18-P84-A): SS-11 counts corrected (header-row over-count): BC-2.11.001 5→4, BC-2.11.002 6→5, BC-2.11.003 5→4, BC-2.11.004 5→4, BC-2.11.005 5→4, BC-2.11.006 5→4. SS-04 same defect audited and corrected: BC-2.04.001/002/003/004/006/007 5→4 each (BC-2.04.005 was already correct at 5). SS-13 same defect audited and corrected: BC-2.13.001/002 5→4, BC-2.13.003/004/005/006 6→5. Format label "narrative" → "table (unlabelled)" for all 19 affected rows (SS-04 001–007, SS-11 001–006, SS-13 001–006) — these BCs use `\| Input \| Expected Output \| Category \|` tables without TV-NNN IDs, not prose narrative. Usage note 3 rewritten accordingly. Total updated 534→516 (−18). | F-P84-01, OBS-P84-A, OBS-P84-B |
| 1.4 | 2026-07-15 | F-P73-01: added 9 D20 BC inventory rows (BC-2.04.008, BC-2.08.013, BC-2.08.014, BC-2.09.006, BC-2.09.007, BC-2.13.007, BC-2.15.004, BC-2.15.005, BC-2.15.006) with live-derived vector counts; BC-2.10.003 TV count corrected 5→7 (v1.2 added TV-006/007 for OnCeiling::Summarize + RunContext.budget_info); total updated 86→95 BCs, ~475→~534 vectors; frontmatter input-hash annotation updated 86→95. | F-P73-01 |
| 1.3 | 2026-07-15 | F-P64-02 sweep fix: corrected v1.1 changelog row date `2026-07-16` → `2026-07-14` (same root cause as bc-authoring-plan.md v1.1; PASS-36 = 2026-07-14). No content change; metadata-only. (F-P64-02, ADV-P1D-PASS-64) | F-P64-02 |
| 1.2 | 2026-07-14 | GTV annotation sync (OBS-P37-2): GTV-003 Expected-cell parenthetical corrected to match BC-2.07.002.md authoritative text ("after separator split on space"); GTV-008 Input-cell code-point note corrected ("3+5+3=11 code pts"); GTV-009 Input-cell annotation corrected ("4 code pts: ñ=U+00F1, o, ñ, o — 2 bytes each for ñ"). All 9 GTV rows now byte-identical to BC-2.07.002.md including non-normative annotations (ADV-P1D-PASS-37) | OBS-P37-2 |
| 1.1 | 2026-07-14 | GTV-008 row synced to concrete value `["abc🎉🎉", "🎉🎉🎉x", "yz"]` with PROVISIONAL marker (was: placeholder); GTV-003/GTV-008 note updated to clarify PROVISIONAL semantics; removed contradictory "Do not hard-code these without verification" language (F-P36-03 fix, ADV-P1D-PASS-36) | F-P36-03 |
| 1.0 | 2026-07-13 | Initial authoring | Greenfield Phase 1a |
