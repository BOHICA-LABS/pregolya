---
document_type: architecture-section
level: L3
section: purity-boundary-map
version: "1.15"
status: active
producer: architect
timestamp: 2026-07-23T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd.md
input-hash: "7d3c5e9"
traces_to: ARCH-INDEX.md
decisions: [D17, D21, D23]
changelog:
  - "1.15 (burst-241/2026-07-23): F-P141-02 — expand Purity Enforcement Rule 3 from VP-001/002/003 to all 9 Kani VPs (6 P0 + 3 P1). VP-009/010/011 confirmed P0; all 9 Kani harness targets must operate exclusively on pure-core sync functions."
  - "1.14 (burst-238/2026-07-23): Stale-handoff sweep — remove stale 'VP-006 candidate' label on prompts::injection_guard Pure Core row; VP-006 was seeded in burst-223 (D21, VP-INDEX v1.2, Kani P1). Replace with 'VP-006 (Kani P1, seeded burst-223)'."
  - "1.13 (burst-236/F-P136-02/2026-07-23): Fix missing `run_ctx: &RunContext` parameter in `PreToolCallHook::pre_invoke` signature on graph::hitl Boundary row. Canonical signature per ADR-018 Decision 1 + BC-2.05.007 PC2 is `pre_invoke(&self, preview: &ToolCallPreview, run_ctx: &RunContext) -> PreToolDecision`; rendered form was truncated to `pre_invoke(preview: &ToolCallPreview) -> PreToolDecision`. Sibling sweep (TD-VSDD-060): module-decomposition.md graph::hitl row does not render pre_invoke signature (no fix needed); ADR-018 canonical signature correct (no fix needed); ADR-020 prose reference only, no parameter list (no fix needed); zero `graph::approval` occurrences in architecture layer (clean). Architecture-layer sweep: CLEAN."
  - "1.12 (burst-235/F-P135-05/2026-07-22): Add missing `sandbox::process` Effectful Shell row (ProcessBackend — BC-2.13.002, SS-13) — spawns OS subprocesses via `tokio::process::Command` with `.kill_on_drop(true)`; DI-015 co-enforcer (defense-in-depth); Effectful Shell because it directly interacts with the OS process tree. Iron Law gap: BC-2.13.002 is a full behavioral contract but the module had no purity classification row. Effectful Shell 35→36; total 78→79."
  - "1.11 (burst-233/2026-07-22): F-P133-07 sibling sweep (TD-VSDD-060) — remove stale 'VP-011 Kani P0 candidate' label in graph::hitl Boundary row (VP-011 seeded burst-232, Kani P0)."
  - "1.10 (D23/2026-07-22): Add 3 new Effectful Shell rows: tools::fs, tools::shell, tools::search (ferrochain-tools crate #21, SS-23, ADR-020). Add 1 new Boundary row: graph::hitl (pre-tool dispatch) — pure PreToolDecision routing + effectful PreToolCallHook::pre_invoke dispatch (ADR-018). Fix stale intro count: 49→53 criticality-universe modules (50 pre-D23 + 3 new tools, correcting 1-off from burst-224 that added vectorstores::similarity without updating prose). Pure Core 31 (unchanged) + Effectful Shell 35 (+3) + Boundary 12 (+1) = 78 total."
  - "1.9 (burst-226/2026-07-21): F-P131-05 sibling sweep — prompts::injection_guard Pure Core row: replace 'checks substituted variable's ProvenanceTag' with 'checks substituted variable's TrustLevel' per ADR-015 v1.3 adjudication; TrustLevel is SS-18-local type in prompts::template, distinct from core::guardrail::ProvenanceTag (SS-11). F-P131-01 sibling sweep — core::retriever Boundary row: replace monolithic 'Fail → propagate Err' with severity-bifurcated description: Critical → Err(E-CORE-008) batch aborts (BC-2.11.005 PC4); non-Critical → error-entry Document substituted, batch continues (BC-2.11.005 PC5)."
  - "1.8 (burst-225/2026-07-21): F-P130-01 sibling sweep — correct core::guardrail Pure Core row: GuardrailHook method updated from wrong sync `fn check(&self, boundary: BoundaryType, docs: &[Document]) → Result<(), FerrochainError>` to canonical `async fn evaluate(&self, content: IngressContent, provenance_tag: ProvenanceTag) -> GuardrailResult` per interface-definitions.md §GuardrailHook (BC-2.11.002..006 authority); full type set listed (GuardrailResult, IngressContent, GuardrailSeverity, BoundaryType). Correct core::retriever Boundary row: rag_ingress description updated from sync `guardrail.check(BoundaryType::RAGRetrieval, &docs)` batch call to async per-document `guardrail.evaluate(IngressContent::RagChunk(...), provenance_tag).await` calls per BC-2.11.003 PC1/PC5; all three GuardrailResult arms noted. Classification unchanged (both remain Pure Core / Boundary Module respectively)."
  - "1.7 (burst-224/2026-07-21): F-P129-11 — split vectorstores::mmr into vectorstores::similarity (new Pure Core; VP-009 Kani P0 target; cosine_similarity shared primitive) + vectorstores::mmr (Pure Core; MMR-only algorithm; calls vectorstores::similarity; VP cleared). F-P129-09 — add core::guardrail Pure Core row (definitions-only: GuardrailHook trait + BoundaryType enum; ADR-014 Decision 6); relocate core::retriever from Pure Core → Boundary (GuardedDocuments::rag_ingress dispatches to injected &dyn GuardrailHook — pure routing gate delegating to effectful impl; ADR-014 Decision 6 / DI-012). Pure Core 30→31 (add similarity +1, add guardrail +1, remove retriever -1); Boundary 10→11 (add retriever). Total 72→74."
  - "1.6 (D21/2026-07-20): ecosystem-parity scope expansion — add 14 new module rows across Pure Core, Effectful Shell, and Boundary columns; pure-core additions (+8): core::documents, core::retriever, core::embeddings (definitions-only), prompts::template, prompts::chat_template, prompts::few_shot, prompts::injection_guard, vectorstores::mmr; effectful shell additions (+4): openai::embeddings, ollama::embeddings, vectorstores::memory, vectorstores::retriever; boundary additions (+2): core::serializable (Reviver dispatch), vectorstores::store (VectorStore trait + factory seam). Pure Core 22→30, Effectful 28→32, Boundary 8→10, total 58→72. ADRs: ADR-014/015/016/017."
  - "1.5 (F-P115-01, 2026-07-19): checkpoint::clock Pure Core row — Pure Guarantee column corrected from 'Monotonic counter increment; UUID wall-clock rejection is pure check' to 'Pure successor function of caller-supplied `current`; UUID wall-clock rejection is pure check'. Reflects ADR-005 rev-2 stateless get_next_version design; retired AtomicU64 counter language excised."
  - "1.4 (F-P91-02 sibling sweep, 2026-07-17): update core::budget Pure Core row to include OnCeiling enum and BudgetConfig struct (both newly defined in interface-definitions.md v2.29); row now lists all six core::budget types."
  - "1.3 (provenance-fix-169/2026-07-17): hash-currency refresh — prd.md updated to v1.2 in same burst. No spec content changes."
  - "1.2 (F-P85-01/F-P85-02/F-P85-03 / 2026-07-16): F-P85-01 (HIGH): correct splitters::parity citation R8/BC-2.07.003 → R8/BC-2.07.002 (BC-2.07.003 is Short-Document single-chunk, not the R8 Red Gate; the non-ASCII parity Red Gate BC is BC-2.07.002). F-P85-02 (HIGH): correct memory::write_guard Boundary citation ADR-012/BC-2.15.006 → ADR-012/BC-2.15.005 (BC-2.15.006 is Frozen-Snapshot Context Mutation governing graph::scheduler + core::context_mutation; the MemoryWriteGuard enforcement BC is BC-2.15.005 per its Architecture Anchors). F-P85-03 (MED): add missing Pure Core row for core::budget (BudgetPolicy trait, PolicyDecision, TokenUsage, RunContext — definitions-only, no execution logic per ADR-009 Option 3 / BC-2.10.001); closes Iron Law completeness gap. Pure Core 21→22, total 57→58 (28 effectful / 8 boundary unchanged). Re-verification of all 16 v1.1 rows: remaining 14 rows PASS citation correctness audit."
  - "1.1 (OBS-P84-C / 2026-07-16): classify 16 previously-unclassified modules — adds server::security, macros::tool/entrypoint/task, splitters::parity, core::context_mutation, core::write_guard to Pure Core; mcp::discovery, mcp::server, memory::skills, ferrochain-standard-tests, xtask, ferrochain-community to Effectful Shell; server::stores, sandbox::policy, memory::write_guard to Boundary Modules. Closes Iron Law gap (adversarial pass 84 finding OBS-P84-C). Also reclassify memory::store from Pure Core → Boundary (defect: '(validation)' qualifier left async dispatch surface unclassified, violating Iron Law; parallel to checkpoint::saver storage-trait Boundary pattern; BC-2.15.001 / SS-15). Module count: 41 rows before (15 pure / 22 effectful / 4 boundary) → 57 rows after (21 pure / 28 effectful / 8 boundary)."
  - "1.0 (2026-07-14): initial purity boundary map authored."
---

# Purity Boundary Map: ferrochain

> **Iron Law:** Pure-core modules are formal verification targets (Kani). Effectful-shell
> modules are integration-tested and fuzz-tested but not Kani-provable. Every module
> must appear in exactly one column. Modules that cross the boundary must be redesigned
> to split their pure and effectful parts.

## [Section Content]

Every ferrochain module appears in exactly one of three columns: **Pure Core** (deterministic,
no I/O, Kani-provable), **Effectful Shell** (I/O, network, or async runtime, not Kani-provable),
or **Boundary Modules** (pure validation/routing layer that delegates I/O to an injected
effectful dependency). All 53 criticality-universe modules plus structural and definitions-only
modules are enumerated in `## Purity Classification` below (79 total rows after burst-235 expansion:
31 Pure Core + 36 Effectful Shell + 12 Boundary). Enforcement invariants follow
in `## Purity Enforcement Rules`.

## Purity Classification

### Pure Core (Deterministic, Side-Effect-Free)

These modules take data in, return data out. No I/O, no network, no global state, no
side effects. Kani proofs operate here.

| Module | Crate | Pure Guarantee | VP Target |
|--------|-------|----------------|-----------|
| `core::message` | ferrochain-core | ContentBlock/Message construction is pure type-system enforcement | — |
| `core::error` | ferrochain-core | Error struct construction; no I/O in constructor | — |
| `core::credentials` | ferrochain-core | Newtype construction; Debug redaction is compile-time | — |
| `core::runnable` | ferrochain-core | `pipe()` combinator is pure function composition | — |
| `core::events` | ferrochain-core | Event type construction; no emission (emitter is effectful) | — |
| `graph::channels` | ferrochain-graph | Reducer logic: deterministic fold over (task_id, value) pairs | — |
| `graph::bsp_engine` (reducer stage) | ferrochain-graph | Task-identity sort + reducer application is pure given channel state | VP-001 |
| `graph::hitl` (queue logic) | ferrochain-graph | FIFO queue dequeue / interrupt-state transitions are pure data transforms | — |
| `graph::definition` | ferrochain-graph | Graph topology construction; no execution | — |
| `checkpoint::session_index` | ferrochain-checkpoint | Triple-address uniqueness validation is pure math | VP-002 |
| `checkpoint::clock` | ferrochain-checkpoint | Pure successor function of caller-supplied `current`; UUID wall-clock rejection is pure check | — |
| `checkpoint::lineage` | ferrochain-checkpoint | Fork-pointer construction is pure (no I/O to the DB) | — |
| `sandbox::path_guard` | ferrochain-sandbox | `canonicalize_beneath_root` is pure path arithmetic after OS resolution | VP-003 |
| `splitters::recursive` | ferrochain-splitters | Chunk boundary computation is pure string iteration | — |
| `server::security` | ferrochain-server | `SecurityConfig::default()` is pure static config construction; router hardening applies `tower::Layer` composition — no I/O (NE-14 / DI-013) | — |
| `macros::tool` | ferrochain-macros | compile-time `TokenStream → TokenStream`; expands `#[tool]` to `ToolDefinition` plumbing; no runtime I/O (ADR-008 / BC-2.08.010) | — |
| `macros::entrypoint` | ferrochain-macros | compile-time `TokenStream → TokenStream`; expands `#[entrypoint]` to START-edge wiring; no runtime I/O (ADR-008 / BC-2.08.011) | — |
| `macros::task` | ferrochain-macros | compile-time `TokenStream → TokenStream`; expands `#[task]` to task-registration boilerplate; no runtime I/O (ADR-008 / BC-2.08.012) | — |
| `splitters::parity` | ferrochain-splitters | deterministic equality check against golden reference vectors; no I/O (R8 / BC-2.07.002) | — |
| `core::context_mutation` | ferrochain-core | definitions-only: `ContextSourceSpec`, `ContextMutationConfig` pure structs; no execution logic (ADR-012 Decision 1) | — |
| `core::write_guard` | ferrochain-core | definitions-only: `MemoryWriteRequest`, `MemoryWriteGuard` trait (`validate()` synchronous, no I/O per ADR-012 Decision 1), `WriteGuardDecision` | — |
| `core::budget` | ferrochain-core | definitions-only: `BudgetPolicy` trait (`evaluate()` pure, no async, no I/O per ADR-009 Option 3), `PolicyDecision` enum (Allow/Escalate/Deny), `OnCeiling` enum (Halt/Escalate/Summarize — BC-2.10.003 v1.2 + BC-2.10.004), `BudgetConfig` struct (soft_limit, hard_limit, on_ceiling — BC-2.10.001 + ADR-009), `TokenUsage` struct, `RunContext` struct; no execution logic (dispatch engine lives in `graph::budget`) (ADR-009 Option 3 / BC-2.10.001) | — |
| `core::guardrail` | ferrochain-core | definitions-only: `GuardrailHook` trait (`async fn evaluate(&self, content: IngressContent, provenance_tag: ProvenanceTag) -> GuardrailResult` — `#[async_trait]` desugared; no execution logic in trait body per canonical definition in interface-definitions.md §GuardrailHook); `GuardrailResult` enum (Pass \| Fail{reason,severity} \| Transform{new_content}); `IngressContent` enum (ToolResult(ContentBlock) \| RagChunk(Value) \| MemoryItem(Value)); `GuardrailSeverity` enum (Critical/High/Medium/Low); `BoundaryType` enum (ToolResult \| RAGRetrieval \| MemoryIngress — 3 variants, PASS-58 canon; not `#[non_exhaustive]`; used in ProvenanceTag per BC-2.11.001); all definitions-only, no execution logic; promoted from graph::provenance/mcp::ingress per trait-in-core precedent matching ADR-009/ADR-012 pattern (ADR-014 Decision 6 / DI-012 / BC-2.20.002) | — |
| `core::documents` | ferrochain-core | `Document { page_content, metadata, id }` pure data carrier; construction is pure type-system enforcement; no I/O (ADR-014 / SS-20) | — |
| `core::embeddings` | ferrochain-core | `Embeddings` trait definition; definitions-only: trait body + dimensionality contract types; no execution logic (ADR-017 / SS-22) | — |
| `prompts::template` | ferrochain-prompts | f-string engine: variable substitution is pure string iteration + format; `{var}` extraction at construction; `.partial()` builder returns new pure value (ADR-015 / SS-18) | — |
| `prompts::chat_template` | ferrochain-prompts | `ChatPromptTemplate` message construction: given substituted variables, produces `PromptValue` with per-message `MessageProvenance`; pure data transform with no I/O (ADR-015 / SS-18) | — |
| `prompts::few_shot` | ferrochain-prompts | `FewShotPromptTemplate`: pure assembly of example messages + template rendering; no I/O; snapshot-fixture parity tests (ADR-015 / SS-18) | — |
| `prompts::injection_guard` | ferrochain-prompts | `SlotTrustPolicy` enforcement: pure synchronous check — for each TrustRequired slot, checks substituted variable's `TrustLevel` (`var.trust_level.is_some_and(\|t\| t.is_untrusted())`); returns `Err(E-TMPL-001)` or `Ok(())`; no async, no I/O (ADR-015 v1.3 / SS-18); `TrustLevel` is SS-18-local type in `prompts::template`, distinct from `core::guardrail::ProvenanceTag` (SS-11) | VP-006 (Kani P1, seeded burst-223) |
| `vectorstores::mmr` | ferrochain-vectorstores | Maximal Marginal Relevance selection: calls `vectorstores::similarity::cosine_similarity` for pairwise distances; pure diversity-penalty scoring pass; no network, no I/O; inputs: query embedding + candidate embeddings + params; output: ranked document indices (ADR-014 / SS-21; F-P129-11 burst-224) | — |
| `vectorstores::similarity` | ferrochain-vectorstores | Shared cosine similarity primitive: `cosine_similarity(a: &[f32], b: &[f32]) → Result<f32, FerrochainError>`; IEEE-754 zero-norm L2-guard (checks `a.iter().map(\|x\| x*x).sum::<f32>().sqrt() == 0.0 \|\| b…`); returns `Err(E-VS-001)` on zero-norm; pure `Vec<f32>` inner product; no `ndarray`, no I/O; called by vectorstores::memory, vectorstores::mmr, and any future VectorStore backend (ADR-014 / SS-21; F-P129-11 burst-224) | VP-009 |

**Kani constraint:** Kani model checking operates on finite, bounded loops. `graph::channels`
reducer loop must be bounded by the number of tasks per super-step. `sandbox::path_guard`
path resolution must not call OS syscalls in the harness — canonicalization is modeled
symbolically.

### Effectful Shell (I/O, Network, Async Runtime)

These modules interact with the outside world. Integration-tested and fuzz-tested.
Kani is not applicable here.

| Module | Crate | Side Effects | Test Strategy |
|--------|-------|-------------|--------------|
| `core::config` | ferrochain-core | env var reads for API keys | Unit |
| `graph::scheduler` | ferrochain-graph | tokio task spawn, semaphore, timer | Integration |
| `graph::event_emitter` | ferrochain-graph | channel send (tokio MPSC) | Integration |
| `graph::budget` (EvidenceJournal write) | ferrochain-graph | append-only journal write | Integration |
| `checkpoint::sqlite` | ferrochain-checkpoint | SQLite file I/O | Integration + Soak |
| `checkpoint::postgres` | ferrochain-checkpoint | TCP database connection | Integration |
| `checkpoint::memory` | ferrochain-checkpoint | in-memory HashMap (deterministic for tests) | Unit |
| `checkpoint::encryption` | ferrochain-checkpoint | random IV generation (CSPRNG) | Integration |
| `server::handlers` | ferrochain-server | HTTP request/response, async task spawn | Integration |
| `server::streaming` | ferrochain-server | SSE event stream, async channel | Integration + Soak |
| `server::cron` | ferrochain-server | Wall-clock timer, background task | Integration |
| `sandbox::wasm` | ferrochain-sandbox | wasmtime engine (executes arbitrary WASM) | Integration |
| `sandbox::container` | ferrochain-sandbox | Docker/OCI container launch | Integration |
| `sandbox::seatbelt` | ferrochain-sandbox | macOS Seatbelt syscall (OS integration) | Integration |
| `sandbox::process` | ferrochain-sandbox | OS subprocess spawning via `tokio::process::Command` with `.kill_on_drop(true)`; `env_clear()` + wall-clock timeout enforcement; DI-015 co-enforcer at sandbox layer — subprocess killed on Future drop when BashTool's `tokio::time::timeout` cancels; only accessible via `unsafe_process_no_isolation()` (BC-2.13.002 / SS-13) | Integration |
| `ferrochain-openai` (invoke) | ferrochain-openai | reqwest HTTP call to api.openai.com | Integration (DTU) |
| `ferrochain-anthropic` (invoke) | ferrochain-anthropic | reqwest HTTP call to api.anthropic.com | Integration (DTU) |
| `ferrochain-ollama` (invoke) | ferrochain-ollama | reqwest HTTP call to localhost:11434 | Integration |
| `mcp::client` | ferrochain-mcp | MCP transport (stdio / HTTP SSE) | Integration |
| `mcp::adapter` (invoke) | ferrochain-mcp | Tool call over transport | Integration |
| `memory::sqlite` | ferrochain-memory | SQLite I/O for long-horizon memory | Integration |
| `memory::in_memory` | ferrochain-memory | In-memory HashMap store (deterministic for tests) | Unit |
| `memory::search` | ferrochain-memory | Search execution (may invoke embedding/vector backend) | Integration |
| `mcp::discovery` | ferrochain-mcp | MCP transport I/O: enumerates tool set from external MCP server at runtime (BC-2.09.001) | Integration |
| `mcp::server` | ferrochain-mcp | binds stdio/SSE transport; accepts inbound MCP connections; dispatches tool calls and serializes responses (ADR-013 / BC-2.09.006/007) | Integration |
| `memory::skills` | ferrochain-memory | async `SkillStore` I/O: reads skill KV entries via `MemoryStore` backend; `load_skill`, `list_skills`, `skill_exists` I/O-bound (ADR-012 / BC-2.15.004) | Integration |
| `ferrochain-standard-tests` | ferrochain-standard-tests | shared conformance suite; invokes provider HTTP stacks via DTU doubles (BC-2.08.013–014) | Integration (DTU) |
| `xtask` | xtask | filesystem reads (file-size gate) + subprocess spawning (lint CI gates); CI enforcement binary (SS-17) | CI/Unit |
| `ferrochain-community` | ferrochain-community | post-v1 placeholder; expected effectful shell when populated (LOW-tier, community contributions) | advisory (post-v1) |
| `openai::embeddings` | ferrochain-openai | reqwest HTTP call to `api.openai.com/v1/embeddings`; `OpenAiApiKey` credential; 30s timeout; SSE not used (blocking JSON response) (ADR-017 / DI-009) | Integration (DTU) |
| `ollama::embeddings` | ferrochain-ollama | reqwest HTTP call to `localhost:<port>/api/embeddings`; no API key; 30s timeout (ADR-017 / DI-009) | Integration |
| `vectorstores::memory` | ferrochain-vectorstores | In-memory VectorStore backend; `RwLock<Vec<(Document, Vec<f32>)>>` interior mutability; `Arc<dyn Embeddings>` injection for embed calls (which are async I/O); async `add_texts` + `similarity_search` (ADR-014 / SS-21) | Unit + Integration |
| `vectorstores::retriever` | ferrochain-vectorstores | `VectorStoreRetriever` dispatches to `&dyn VectorStore` (async I/O); impl `Retriever`; bridge from Retriever trait to VectorStore methods (ADR-014 / SS-20) | Integration |
| `tools::fs` | ferrochain-tools | OS filesystem I/O: `ReadFileTool` (file read syscall), `WriteFileTool` (file write/create syscall), `EditFileTool` (read + string-replace + write), `ListDirTool` (readdir syscall); `PathGuard` validation is pure path arithmetic but OS `canonicalize()` is effectful; all operations produce observable filesystem state changes (ADR-020 / SS-23) | Integration |
| `tools::shell` | ferrochain-tools | subprocess execution via ferrochain-sandbox WASM or container backend; stdout/stderr/exit-code capture; wall-clock timeout (tokio timer); observable process-tree state (ADR-020 / SS-23) | Integration |
| `tools::search` | ferrochain-tools | in-process `regex` crate pattern matching over OS filesystem; directory traversal is I/O (readdir syscall chain); CPU-bound regex matching sits atop effectful directory walk; `PathGuard` validation before traversal (ADR-020 / SS-23) | Integration |

### Boundary Modules (Pure Logic + Effectful Dispatch)

These modules contain pure validation / routing logic that delegates I/O to an injected
effectful dependency. The pure part is testable with unit/property tests; the effectful
dispatch is integration-tested.

| Module | Crate | Pure Part | Effectful Part |
|--------|-------|-----------|---------------|
| `graph::provenance` | ferrochain-graph | ProvenanceTag construction; route decision | GuardrailHook dispatch (user-injected) |
| `core::retry` | ferrochain-core | Policy evaluation: `ToolRetryPolicy`, `CircuitBreaker` state transitions (allow/deny/open/half-open), `global_limit` counter | Retry execution (actual re-invoke) is effectful; the pure policy layer returns `BreakerDecision` to the caller |
| `checkpoint::saver` (trait impl) | ferrochain-checkpoint | put_writes validation | Backend I/O (sqlite/postgres/memory) |
| `mcp::ingress` | ferrochain-mcp | Untrusted-ingress routing decision | GuardrailHook dispatch |
| `server::stores` | ferrochain-server | `IdempotencyStore`/`RateLimitStore`/`RunStore` trait interface definitions (pure seams per NE-08) | Backend I/O when trait impl is dispatched (store reads/writes) |
| `sandbox::policy` | ferrochain-sandbox | `SandboxPolicy` evaluation: pure compatibility check of policy requirements against backend capabilities; `Err(PolicyNotEnforceable)` on mismatch (NE-01 / SS-13) | Effectful backend enforcement when policy is applied (calls sandbox backend) |
| `memory::write_guard` | ferrochain-memory | pure `MemoryWriteGuard::validate()` call (synchronous, no I/O per ADR-012 Decision 1); returns `WriteGuardDecision` (Allow/Deny/Transform) | effectful `MemoryStore` write commit/abort; injection-scanner guard enforcement (ADR-012 / BC-2.15.005) |
| `memory::store` | ferrochain-memory | `MemoryStore` key/query validation logic; no I/O | async KV/vector/erasure ops dispatched to backend implementations (sqlite/in_memory/search/skills); parallel structure to `checkpoint::saver` storage-trait Boundary pattern (BC-2.15.001 / SS-15) |
| `core::serializable` | ferrochain-core | Pure part: `LcSerializable` trait definitions; `Reviver` allowlist lookup (pure HashMap check); secret-key stripping from kwargs (pure map operation); E-SRLZ-001/002 error construction | Effectful part: registered constructor functions (`fn(Map) -> Box<dyn Any>`) are called at deserialization time — these constructors may allocate, decode, or otherwise have side effects; `inventory::iter` traversal at startup populates `OnceLock` (ADR-016 / SS-19) |
| `vectorstores::store` | ferrochain-vectorstores | Pure part: `VectorStore` trait definition + `MetadataFilter` validation logic; `as_retriever()` returns concrete `VectorStoreRetriever` (pure construction) | Effectful part: `add_texts`, `similarity_search`, `delete` and all other async instance methods dispatch to the concrete backend impl (e.g., `vectorstores::memory`, or a community adapter) (ADR-014 / SS-21) |
| `core::retriever` | ferrochain-core | Pure part: `Retriever` trait definition (zero-LOC pure interface); `GuardedDocuments` newtype (pure data wrapper — `Vec<Document>` private field, no public constructor, `#[non_exhaustive]` on inner); `GuardedDocuments::rag_ingress(docs: Vec<Document>, guardrail: &dyn GuardrailHook) -> Result<GuardedDocuments, FerrochainError>` **`async fn`** — per-document routing gate: for each Document calls `guardrail.evaluate(IngressContent::RagChunk(serde_json::to_value(&doc)?), ProvenanceTag { boundary_type: BoundaryType::RAGRetrieval, ingress_id, sequence_position: i }).await`; N documents → N evaluate calls (BC-2.11.003 PC5); dispatches on GuardrailResult: Pass → include; Fail Critical severity → propagate Err(E-CORE-008) batch aborts (BC-2.11.005 PC4); Fail non-Critical severity → substitute error-entry Document at position i, batch continues (BC-2.11.005 PC5); Transform → include deserialized replacement Document (BC-2.11.003 PC4) | Effectful part: `guardrail.evaluate()` dispatches to an injected `&dyn GuardrailHook` implementation — impls may log, call external policy services, or scan content; DI-012 enforcement by type: graph nodes that inject retrieved docs into context accept `&GuardedDocuments`, making bypass a compile-time type error (ADR-014 Decision 6 / BC-2.20.002 / DI-012) |
| `graph::hitl (pre-tool dispatch)` | ferrochain-graph | Pure part: `pre_tool_dispatch` routing function — pure pattern-match on `PreToolDecision` variant; fail-closed: Deny variant never allows tool invocation (VP-011, Kani P0, seeded burst-232); `Edit` variant substitutes caller-supplied `modified_args` (pure struct replacement); `Approve` variant passes call through unchanged; all routing decisions are deterministic given the `PreToolDecision` value (ADR-018 Decision 3) | Effectful part: `PreToolCallHook::pre_invoke(&self, preview: &ToolCallPreview, run_ctx: &RunContext) -> PreToolDecision` — user-injected async hook impl may present UI, call external approval service, read policy store, or emit `tool_approval_request` streaming event; `PendingHumanApproval` variant dispatches `interrupt(ToolApprovalRequest{..})` reusing BC-2.05.001 machinery (ADR-018 Decisions 1+4) |

> **Storage-trait Boundary pattern:** `checkpoint::saver` (SS-04) and `memory::store` (SS-15)
> both follow the same canonical pattern: the trait module defines pure validation logic + an
> async dispatch contract, while effectful I/O is implemented by separate Effectful Shell modules
> (checkpoint::sqlite/postgres/memory and memory::sqlite/in_memory/search/skills respectively).
> Both are correctly classified Boundary. The parallel is intentional.

## Purity Enforcement Rules

1. Pure modules MUST NOT import `tokio`, `reqwest`, `axum`, or any I/O crate at the module level.
2. Pure modules MUST NOT call any function that returns `impl Future` unless the future itself is pure (e.g., a test double).
3. The Kani harness for all 9 Kani VPs (P0: VP-001/002/003/009/010/011; P1: VP-006/012/013) operates ONLY on pure-core sync functions listed above; each harness target must be extractable as a side-effect-free sync function before the Phase 6 harness can be written.
4. Any refactor that moves I/O into a currently-pure module requires an architectural review and ADR update.
