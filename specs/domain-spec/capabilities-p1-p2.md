---
document_type: domain-spec-section
level: L2
section: capabilities-p1-p2
version: "1.5"
status: active
producer: business-analyst
timestamp: 2026-07-20T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "cf67214"
traces_to: L2-INDEX.md
decisions: [D1, D3, D7, D8, D13, D17, D19, D20, D21]
changelog:
  - "1.5 (2026-07-20): D21 second-half CAP authoring — CAP-028..033 added (SS-21 VectorStore Abstraction, SS-22 Embeddings). P1 count 13→19; total section CAP count 16→22. New section 'P1 — VectorStore Abstraction and Embeddings (Wave 2 / SS-21..22)' added. Grounded in ADR-014 (SS-21), ADR-017 (SS-22), burst-217 handoff table. Domain C forcing-function linkage for SS-22 documented in CAP-031."
  - "1.4 (2026-07-20): D21 first-half CAP authoring — CAP-022..027 added (SS-18 Prompt Templates, SS-19 LC Serialization, SS-20 Document Retrieval). P1 count 7→13; total section CAP count 10→16. Section header updated. Grounded in ADR-014 (SS-20), ADR-015 (SS-18), ADR-016 (SS-19), burst-217 handoff table. D21 added to decisions list. input-hash unchanged (no new planning-level inputs; ADR grounding is inline per convention)."
  - "1.3 (2026-07-17): Provenance-integrity fix — STATE.md removed from inputs (D-NNN decisions baked at authoring time); COMPARATIVE-ASSESSMENT.md added (HS-6/D17-Q5 grounding for CAP-009, CONFLICT-7 for CAP-017, NE-09 for CAP-018, D17-Q7 for CAP-019); domain-c-openclaw.md added (CAP-017 long-horizon memory forcing function); domain-d-hermes-agent.md added (CAP-020/CAP-021 D19/D20 forcing functions); input-hash recomputed."
  - "1.2 (OBS-P77-C, 2026-07-15): ADR-012 DI-001 renamed to ADR-012 INV-1 per architect adjudication D18-P77-A (propagation from BC-2.15.006 v1.1 and ADR-012 v1.2 local-invariant rename)."
  - "1.1 (D20 sub-burst 1, 2026-07-15): CAP-020 (Self-Improvement Primitives, P1) and CAP-021 (MCP Server Role, P1) added per D20 human authority + D19 forcing function (domain-d-hermes-agent.md). P1 count 5→7. ADR-012 is the architecture authority for both new CAPs."
---

# Domain Capabilities — P1 and P2

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.
> P0 capabilities are in `capabilities-p0.md`.
> **Pass-21 update:** CAP-012, CAP-013, CAP-016 relocated to `capabilities-p0.md` (elevated
> to P0 per ADV-P1D-PASS-21 F-P21-01). This file now holds P1/P2 only.
> **D20 update (2026-07-15):** CAP-020 and CAP-021 added (P1). See changelog.
> **D21 update (2026-07-20):** CAP-022..033 added (P1, full D21 expansion SS-18..22). First
> half (CAP-022..027): SS-18 Prompt Templates, SS-19 LC Serialization, SS-20 Document
> Retrieval. Second half (CAP-028..033): SS-21 VectorStore Abstraction, SS-22 Embeddings.
> P1 count 7→19; total P1/P2 count 10→22. See changelog and the two D21 sections below.

---

## P1 — Partners, Conformance, MCP, and Server (Wave 2 + Wave 0/1)

### CAP-009: Provider-Conformant Chat Model Interface

Expose a chat model trait that passes ferrochain-standard-tests for streaming, tool calling,
structured output, error propagation, and token accounting. First-party implementations for
OpenAI, Anthropic, Ollama. Architecture uses standalone SDK crate split (HS-6/D17-Q5):
`ferrochain-<provider>-sdk` (wire client) + `ferrochain-<provider>` (Runnable adapter).

**Grounding:** product-brief.md §Scope Wave 2 — `ferrochain-openai`, `ferrochain-anthropic`,
`ferrochain-ollama` first-party provider crates (D3 early-integration priority); standalone
SDK crate split architecture (HS-6/D17-Q5).
**Anchor justification:** CAP-009 covers provider conformance because the brief names the three
provider crates explicitly in Wave 2 scope and market differentiator #5 requires a
LangChain-semantic migration story.

### CAP-010: MCP Tool Adapter

Discover tools from MCP servers at runtime, present them to a graph as standard ferrochain
Tools, and route ToolInvocation requests to the correct MCP server transport. Treat all
tool-result content as untrusted ingress (DI-012). Target semantic surface:
langchain-mcp-adapters==0.3.0 (D1/D2).

**Grounding:** product-brief.md §Scope Wave 2 — `ferrochain-mcp` port of
langchain-mcp-adapters==0.3.0 (D2); MCP client adapter for security, productivity, and
custom server integration.
**Anchor justification:** CAP-010 covers MCP adapter because D1 mandates ferrochain-mcp as
the primary integration surface after langchain-community was archived. Overflow §MCP-Surface
lists verified active MCP servers that must be supported.

### CAP-011: Provider Conformance Suite (Standard Tests)

Provide a test crate (`ferrochain-standard-tests`) that every ferrochain provider crate must
pass before v1 release. Tests exercise: streaming completions, tool-call round-trips,
structured output, error-type fidelity, and token-usage accounting. Port of LangChain's
`langchain-tests` conformance suite.

**Grounding:** product-brief.md §Scope Wave 2 — `ferrochain-standard-tests` port of
LangChain's langchain-tests conformance suite; "all Wave 2 provider crates must pass before
v1 release."
**Anchor justification:** CAP-011 covers the conformance suite because it is an explicit Wave 2
deliverable named in the brief and market differentiator #2.

### CAP-014: Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)

Provide a first-party HTTP server that manages: Thread (durable conversation history),
Assistant (named agent config), Run (single execution), and CronSchedule (recurring
proactive runs). Streaming and unary run endpoints drive the same graph execution engine.
No wire-compatibility with LangGraph Platform (D13).

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-server`: threads, assistants,
cron scheduler, streaming and unary run equivalence (NE-13/D17); first-party per D13.
**Anchor justification:** CAP-014 covers ferrochain-server because D13 names it as first-party
and the brief lists its required resource types (threads, assistants, cron, streaming/unary
equivalence) explicitly.

### CAP-015: Sandboxed Tool Execution (Enforcing Backend Default)

Execute tools in an enforcing isolation backend (WASM or container) by default. The process
backend requires explicit opt-in and emits a loud warning. On a strict policy with a
non-enforcing backend, return `Err(PolicyNotEnforceable)` — do not silently fall back. All
workspace file operations call `canonicalize_beneath_root(base, path)` at access time.

**Grounding:** product-brief.md §Scope Wave 0 NE catalog — NE-01/NE-02/D17: "Enforcing
sandbox backend (WASM/container) must be the default; process backend is loud opt-in."
**Anchor justification:** CAP-015 covers sandbox enforcement because NE-01 and NE-02 are both
named as first-class BC candidates in the brief's Overflow §Security-PRD-Carry-Forward.

### CAP-020: Self-Improvement Primitives (Skill Registry, Guarded Memory Writes, Frozen-Snapshot Context Mutation)

Provide three framework-scope primitives that enable a self-improving agent loop:
(a) **Skill registry** (`memory::skills`): load skill documents (agentskills.io SKILL.md pattern)
into agent context on demand; list skills by tag; check existence without loading. Skill
documents stored as ordinary KV entries in `MemoryStore` with routing semantics added by
`SkillStore`. (b) **Guarded memory/skill writes** (`core::write_guard` + `memory::write_guard`):
every write to a guarded memory namespace goes through `MemoryWriteGuard::validate(req)`
before commit; validator returns Allow / Deny(reason) / Transform(sanitized); built-in scanner
checks for prompt-injection patterns and invisible-Unicode; Deny raises `E-MEMORY-007
MemoryWriteGuardDenied`. (c) **Frozen-snapshot context mutation** (`core::context_mutation` +
`graph::scheduler`): `RunnableConfig.context_mutations` declares which memory keys are loaded
into the system-prompt context; loaded once at run start before the first super-step; writes
during the run take effect on the NEXT run (cache-coherence invariant, per ADR-012 INV-1).

**Grounding:** D20 human authority — self-improvement loop promoted from application-layer to
framework-scope. domain-d-hermes-agent.md req 4 (runtime-mutable procedural skills) and req 3
(frozen-snapshot system-prompt semantics) are the forcing functions.
**Anchor justification:** CAP-020 is a net-new capability with no prior CAP ID. It covers the
three primitives ADR-012 Decision 1 adopts: skill registry in `ferrochain-memory`, write guard
split between `ferrochain-core` (types/trait) and `ferrochain-memory` (enforcement), and
context mutation config in `ferrochain-core` loaded by `ferrochain-graph`.
**Architecture authority:** ADR-012 (`decisions/ADR-012-self-improvement-primitives.md`).

### CAP-021: MCP Server Role (Expose Registered Tools as MCP Server Endpoint)

Expose ferrochain's registered tools and resources as an MCP server so that external LLM
applications can connect as MCP clients and invoke ferrochain tools via the MCP protocol.
`mcp::server` module in `ferrochain-mcp` provides: server startup with a configured transport
(stdio or SSE), `tools/list` advertisement of all tools registered in the tool registry,
`tools/call` dispatch to the underlying ferrochain `Tool` implementation and return of the
result via MCP response format. This is the **server** role complementing the existing MCP
**client** role (CAP-010 / SS-09 / BC-2.09.001–005).

**Grounding:** D19 forcing function — domain-d-hermes-agent.md req 11 ([NEW framework-scope]):
"ferrochain exposes its own tools and resources via the MCP protocol so that other LLM
applications can connect as clients — entirely absent from all BCs and capabilities." D20
adoption decision includes MCP server role in Phase-1 scope.
**Anchor justification:** CAP-021 is a net-new capability. MCP client role (CAP-010) covers the
client direction; CAP-021 covers the server direction. These are architecturally independent
surfaces in `ferrochain-mcp`: client code (`mcp::client`) and server code (`mcp::server`) are
separate modules. CAP-010 cannot cover server-role behavior without creating a
client-vs-server semantic collision.

---

## P1 — Prompt Templates, LC Serialization, and Document Retrieval (Wave 2 / SS-18..20)

> D21 ecosystem-parity scope expansion (burst 216) promoted SS-18 (Prompt Templates),
> SS-19 (LC Serialization), and SS-20 (Document Retrieval) to full v1 scope.
> CAP-022..027 author the first-half D21 expansion. SS-21 (VectorStore Abstraction) and
> SS-22 (Embeddings) CAPs will follow in the second-half D21 authoring pass.

### CAP-022: PromptTemplate and ChatPromptTemplate as Runnable (f-string Default, Jinja2 Optional)

Construct single-message PromptTemplates and multi-message ChatPromptTemplates as Runnables.
Render via f-string engine (always-on, in-house ~100 LOC, Python `str.format` semantics:
`{variable}` substitution, `{{` / `}}` literal-brace escapes, no nested attribute access in v1).
Optionally render via jinja2 engine (Cargo feature `"jinja2"`, minijinja 2.x, sandboxed mode
mandatory, strict-undefined raises E-TMPL-003). Support partial variable binding: pre-bound
variables are merged with call-time variables; call-time wins on key collision. Detect required
variable names at template-construction time (static introspection, not deferred to render).

**Grounding:** D21 human authority (burst 216) — SS-18 (ferrochain-prompts) promoted from
post-v1/community to full v1 scope, superseding the product-brief §Out-of-Scope entry for
PromptTemplate. ADR-015 Decision 1 establishes ferrochain-prompts as crate #19. Burst-217
handoff table names "template construction, rendering, injection guard, FewShot" as SS-18 CAP
targets.
**Anchor justification:** CAP-022 covers PromptTemplate and ChatPromptTemplate as Runnable
because D21 explicitly names SS-18 as a v1 deliverable, ADR-015 Decision 4 locks f-string as
the default engine (mustache DROPPED as production-grade violation — crates.io stale since
2018; jinja2 optional via minijinja 2.x), and partial variable binding is required per semport
rust-translation-strategy §4 `.partial()` requirement. Rendering and composition cannot share
a CAP with FewShot/MessagesPlaceholder because the acceptance shapes differ (scalar vs
message-list substitution).
**Security invariant:** SystemMessage slots are hard-coded `TrustRequired`; untrusted-tagged
variables substituted into a TrustRequired slot → E-TMPL-001 (SECURITY/InjectionAttempt) at
render time via `injection_guard` pure-core blocker (ADR-015 Decision 3). This block is
unconditional — not dependent on a configured GuardrailHook. VP-006 Kani candidate.
**Architecture authority:** ADR-015.

### CAP-023: MessagesPlaceholder and FewShotPromptTemplate — Message-List and Few-Shot Composition

Insert a named `Vec<Message>` variable into a chat template position via `MessagesPlaceholder`,
enabling dynamic message-list injection (conversation history windows, streamed tool-result
sequences). Compose few-shot examples into a ChatPromptTemplate via `FewShotPromptTemplate`:
accepts a `Vec` of `(input, output)` example pairs, formats each as a Human/AI message pair,
and injects the sequence before the user-turn slot. All composition produces a `PromptValue`
output carrying per-message `MessageProvenance` (highest-severity ProvenanceTag across
substituted variables + SlotTrustPolicy), enabling downstream guardrail and observability use
(ADR-015 Decision 3).

**Grounding:** D21/SS-18. MessagesPlaceholder and FewShot* are first-class LangChain v1
composition types (semport Corpus 1, langchain==1.3.13). Burst-217 handoff table lists
"FewShot" alongside template construction and rendering as explicit SS-18 CAP targets.
**Anchor justification:** CAP-023 is separated from CAP-022 because MessagesPlaceholder and
FewShot operate at message-list granularity, not scalar-string substitution. MessagesPlaceholder
expands a `Vec<Message>` variable in-place; FewShotPromptTemplate drives a template-per-example
composition loop producing multiple message pairs. Each has an independent BC acceptance shape
(message-list expansion vs. example-sequence formatting) that cannot be collapsed into
CAP-022's f-string/jinja2 scalar rendering shape.
**Architecture authority:** ADR-015.

### CAP-024: LcSerializable Round-Trip (Serialize → Serialized → Deserialize → Equivalent Value)

Serialize any type implementing `LcSerializable` to a `Serialized::Constructor` JSON envelope
(fields: `lc`, `id: Vec<String>`, `kwargs: Map<String, Value>`) and deserialize back to a
type-equivalent value via Reviver. Round-trip invariant: `deserialize(serialize(x))` produces
a value semantically equivalent to `x` for all 141 core-registered types. Credential fields
listed in `lc_secrets()` are stripped from `kwargs` before serialization and before Reviver
dispatch — they are never present in the wire representation (DI-010 credential opacity).
`LcSerializable::is_lc_serializable()` returns false for types that opt out; no serialization
is attempted for opt-out types.

**Grounding:** D21/SS-19. The lc-JSON round-trip protocol is a first-class LangChain v1
serialization contract characterized in semport Pass 7 + Pass 8 ADR-3
(rust-translation-strategy §9). ADR-016 Decision 1 places `core::serializable` in
ferrochain-core with 141 core registrations. Decision 3 Property 3 defines the lc_secrets
stripping invariant grounded in DI-010.
**Anchor justification:** CAP-024 covers the serialize→deserialize lifecycle including secret
stripping because ADR-016 Decisions 2 and 3 together specify these behaviors as the core
safety-critical lc-JSON contract. The 141-entry count grounds the v1 scope in the semport
analysis; any new registration requires an `inventory::submit!` call, not a spec amendment.
CAP-024 covers behavioral equivalence; CAP-025 covers containment and error handling — the two
are distinct BC axes.
**Architecture authority:** ADR-016.

### CAP-025: Reviver and Type Registry (Inventory-Based; Allowlist Containment; Legacy-Namespace Remap)

Deserialize a `Serialized::Constructor` to a typed value by looking up `id` in the
`inventory`-based static registry of `LcEntry` records, populated at link time via
`inventory::submit!` (no runtime mutation possible — allowlist is structurally determined by
Cargo feature selection). The valid-namespace allowlist is derived from the registered set at
startup (OnceLock<HashSet<String>>) not hand-maintained, so allowlist-vs-registry drift cannot
occur. Unknown `id` → E-SRLZ-001 (structured error; no silent None, no fallback).
`langchain`-monolith types (12 entries: LLMChain, ToolAgentAction, OutputFixingParser, etc.)
→ E-SRLZ-002 (structured error with clear message). Legacy namespace aliases
(OLD_CORE_NAMESPACES_MAPPING, 58 entries) remap transparently to canonical constructors.
Path-based loading does not exist — the registry is the only deserialization path, eliminating
the path-traversal attack class entirely.

**Grounding:** D21/SS-19. ADR-016 Decisions 2 and 3 define the five untrusted-input safety
properties, allowlist derivation (derived-not-hand-maintained), the 12 langchain-monolith
entries (E-SRLZ-002), and 58 legacy aliases — all explicitly characterized in semport Pass 8
ADR-3. No path-based loading per ADR-016 Decision 3 Property 2.
**Anchor justification:** CAP-025 is separated from CAP-024 because the Reviver and registry
are the containment and error-handling surface for unknown or untrusted input; CAP-024
describes the round-trip behavioral contract for known registered types. Distinct BC axes:
CAP-024 = behavioral equivalence; CAP-025 = allowlist containment, E-SRLZ-001/002, legacy
remap, no-path-loading. VP-010 Kani candidate (type not in registry never successfully
deserializes) is anchored to this CAP.
**Architecture authority:** ADR-016.

### CAP-026: Retriever Trait — get_relevant_documents; Arc<dyn Retriever> Seam; DI-012 RAGRetrieval Guardrail Coverage

Provide the `Retriever` dyn-compatible async trait (`ferrochain-core: core::retriever`):
`async fn get_relevant_documents(&self, query: &str) → Result<Vec<Document>, FerrochainError>`.
Object-safe via `#[async_trait]` desugaring and `&self` receiver, consistent with ADR-005
precedent. Graph nodes hold `Arc<dyn Retriever>` for RAG operations without depending on
ferrochain-vectorstores. All `Document` values returned by any `Retriever` implementation and
entering graph context pass the `BoundaryType::RAGRetrieval` guardrail (DI-012 / BC-2.11.001)
— the existing `BoundaryType::RAGRetrieval` variant already covers this seam; no BoundaryType
extension is required (ADR-014 §Consequences confirms this explicitly).

**Grounding:** D21/SS-20. ADR-014 Decision 1 places `Retriever` in ferrochain-core for the
same gravity reason as `Runnable` and `BaseChatModel` — graph nodes performing RAG need
`Arc<dyn Retriever>` without pulling in ferrochain-vectorstores. DI-012 / BC-2.11.001's
`BoundaryType::RAGRetrieval` variant was authored before D21 and already covers RAG retrieval
ingress; ADR-014 §Consequences confirms no extension is needed.
**Anchor justification:** CAP-026 covers the Retriever trait seam because it is the dyn-dispatch
boundary all RAG-using graph nodes depend on. The DI-012 linkage is mandatory: documents
entering graph context via any Retriever are untrusted RAG ingress by definition (DI-012
source: NE-06, HS-8, D17-Q8). CAP-026 confirms DI-012 coverage — it does not redefine or
extend BC-2.11.001, which remains the BC authority for the guardrail invariant.
**Architecture authority:** ADR-014.

### CAP-027: VectorStoreRetriever — SearchType Enum; k / fetch_k / lambda_mult Configuration

Provide a concrete `Retriever` implementation (`VectorStoreRetriever<'a>` in
`ferrochain-vectorstores: vectorstores::retriever`) backed by a `&dyn VectorStore`,
configurable via:
- **SearchType enum:** `Similarity` (default) | `SimilarityScoreThreshold { score_threshold: f32 }` | `Mmr`
- **k:** number of final documents to return
- **fetch_k:** candidate pool size fetched before MMR re-ranking (applicable to SearchType::Mmr only)
- **lambda_mult ∈ [0.0, 1.0]:** MMR diversity parameter (0.0 = maximum diversity, 1.0 = pure relevance)

Constructed via `VectorStore::as_retriever()` — a concrete (non-opaque) return type that
preserves VectorStore dyn-compatibility (ADR-014 Decision 2 §Object-safety). Implements
`Retriever` and can be type-erased to `Arc<dyn Retriever>` for use in graph nodes via the
CAP-026 seam. DI-012 RAGRetrieval guardrail applies to all returned Documents via CAP-026.

**Grounding:** D21/SS-20/SS-21. ADR-014 Decision 2 defines the `VectorStoreRetriever` struct
and fields, the `SearchType` enum variants and behavioral semantics, and the `as_retriever()`
concrete-return-type pattern required for E0038-safe VectorStore dyn-compatibility.
**Anchor justification:** CAP-027 is separated from CAP-026 because VectorStoreRetriever is a
specific, configurable VectorStore-backed implementation with its own BC surface (SearchType,
k, fetch_k, lambda_mult). CAP-026 is the abstract `Arc<dyn Retriever>` seam in ferrochain-core;
CAP-027 is the concrete VectorStore-backed implementation in ferrochain-vectorstores. The two
have independent acceptance shapes. The `as_retriever()` concrete-return-type design is a load-
bearing object-safety choice documented in ADR-014 (dyn-compatible via non-opaque return).
**Architecture authority:** ADR-014.

---

## P1 — VectorStore Abstraction and Embeddings (Wave 2 / SS-21..22)

> D21 second-half expansion. SS-21 (VectorStore Abstraction) lives in ferrochain-vectorstores
> (crate #20). SS-22 (Embeddings) lives in ferrochain-core (core::embeddings) plus provider
> modules in ferrochain-openai and ferrochain-ollama. ferrochain-anthropic has NO embedding
> impl (Anthropic has no public embedding API — ADR-017 Decision 3).

### CAP-028: VectorStore Trait — add_texts; Similarity Search; MMR; delete; as_retriever (Concrete Return for Dyn-Compat)

Provide the `VectorStore` async trait (`ferrochain-vectorstores: vectorstores::store`) with
instance methods only — all `&self` receivers, dyn-compatible via `#[async_trait]` desugaring:
`add_texts(texts, metadatas)` (returns Vec<String> of assigned document IDs),
`similarity_search(query, k)` (k-nearest documents),
`similarity_search_with_score(query, k)` (returns Vec<(Document, f32)> with scores ∈ [0.0, 1.0]),
`max_marginal_relevance_search(query, k, fetch_k, lambda_mult)` (diversity-aware MMR retrieval),
`delete(ids)`, and `as_retriever(&self) → VectorStoreRetriever<'_>` (concrete, non-opaque return
type — required to preserve VectorStore dyn-compatibility, ADR-014 Decision 2 §Object-safety).
Static constructors (`from_texts`) live on the separate `VectorStoreFactory` trait (Sized-bounded,
NOT on the VectorStore vtable) — this split is required for E0038-safe `Arc<dyn VectorStore>`.
`add_texts` uses `&self` (not `&mut self`) because external backends are stateless from the
client perspective; the in-memory backend uses `RwLock` interior mutability (CAP-029).

**Grounding:** D21/SS-21. ADR-014 Decision 2 specifies the VectorStore trait instance method
surface, the `&self`-not-`&mut self` rationale, the `as_retriever` concrete-return-type
requirement, and the `VectorStoreFactory` separation for E0038-safe dyn dispatch.
**Anchor justification:** CAP-028 covers the VectorStore trait (abstract seam) because it is the
foundational document-index contract that the in-memory backend (CAP-029), MetadataFilter
(CAP-030), and all future community adapters implement. The `VectorStoreFactory` split is a
load-bearing architectural constraint (not a style preference) — a `fn from_texts()` on the
main VectorStore trait would make `Arc<dyn VectorStore>` impossible in Rust (E0038). BC authors
must express the `as_retriever()` concrete-return-type invariant in the BC acceptance shape.
**Architecture authority:** ADR-014.

### CAP-029: InMemoryVectorStore — Arc<dyn Embeddings> DI; RwLock Interior Mutability; Vec<f32> Cosine; E-VS-001 Zero-Norm Guard

Provide the reference `VectorStore` implementation (`ferrochain-vectorstores: vectorstores::memory`,
struct `InMemoryVectorStore`) backed by `RwLock<Vec<(Document, Vec<f32>)>>` (document +
pre-computed embedding vector). Constructed with `Arc<dyn Embeddings>` injected at creation
time via `VectorStoreFactory::from_texts_sync` — Arc-DI wiring per workspace convention; no
placeholder construction is permitted. Text queries are converted to query vectors via the injected
`Embeddings` impl at search time. Document vectors are generated at `add_texts` time.
Cosine similarity is computed from `Vec<f32>` inner products (no ndarray — semport §8 avoidance).
**Zero-norm guard (ADR-014 v1.1 hardening):** before any cosine division, the implementation
checks `norm = vec.iter().map(|x| x*x).sum::<f32>().sqrt()`. If `norm == 0.0`:
`return Err(FerrochainError { code: "E-VS-001" })` (ADR-authored code; PO to formalize in
error taxonomy). A zero-length embedding produces NaN that silently corrupts ranking — this guard
is two lines and is unconditional. Implements `VectorStoreFactory` for `from_texts_sync`.

**Grounding:** D21/SS-21. ADR-014 Decision 4 specifies the InMemoryVectorStore struct
(`Arc<dyn Embeddings>` + `RwLock<Vec<(Document, Vec<f32>)>>`), the Arc-DI wiring contract,
and the `Vec<f32>` cosine approach (semport §8 avoidance of ndarray in core). ADR-014 v1.1
§Hardening note specifies the zero-norm guard and its VP-009 connection (MMR cosine values ∈
[-1.0, 1.0] + no NaN in output scores for any valid non-zero query embedding).
**Anchor justification:** CAP-029 is separated from CAP-028 because the in-memory implementation
has its own BC surface — Arc-DI wiring, RwLock semantics, Vec<f32> cosine math, NaN prevention
via E-VS-001, and VP-009 (Kani MMR bounded proof). These are not part of the abstract VectorStore
contract and must not be forced on external backends.
**Architecture authority:** ADR-014.

### CAP-030: MetadataFilter — Eq / Ne / In Clause Filtering on Document Metadata During Search

Provide optional metadata-based pre/post-filtering for VectorStore similarity searches via
`MetadataFilter { filters: Vec<FilterClause> }` with clause types `Eq { key: String, value: Value }`,
`Ne { key, value }`, `In { key, values: Vec<Value> }`. MetadataFilter is an optional parameter
on an additive `similarity_search_with_filter` method — it does NOT change the base VectorStore
trait contract and does NOT break existing implementations that omit it. Community adapters
supporting native server-side metadata filtering dispatch the filter to the backend; the
InMemoryVectorStore (CAP-029) applies MetadataFilter as a post-filter over the similarity result
set. Both `MetadataFilter` and `FilterClause` are `#[non_exhaustive]`; new clause variants
(e.g., `Gte`, `Lt`, `Contains`) can be added in future minor versions without breaking existing
match arms in community adapter implementations.

**Grounding:** D21/SS-21. ADR-014 Decision 2 §Metadata filter surface defines the MetadataFilter
and FilterClause types (Eq/Ne/In), the additive `similarity_search_with_filter` method pattern,
and the pre-filter (native adapters) vs post-filter (in-memory) behavioral split.
**Anchor justification:** CAP-030 is separated from CAP-028 because MetadataFilter is an optional
capability addon — community adapters may or may not support it natively — and it must not be
a required method on the base VectorStore contract. Its own BC axis covers clause semantics,
evaluation order, and the native-vs-post-filter distinction.
**Architecture authority:** ADR-014.

### CAP-031: Embeddings Trait — embed_documents (Batch); embed_query; Dimensionality Contract; Arc<dyn Embeddings> Seam

Provide the `Embeddings` dyn-compatible async trait (`ferrochain-core: core::embeddings`):
`async fn embed_documents(&self, texts: Vec<String>) → Result<Vec<Vec<f32>>, FerrochainError>`
and `async fn embed_query(&self, text: String) → Result<Vec<f32>, FerrochainError>`.
Object-safe via `&self` receivers and `#[async_trait]` desugaring (ADR-005 precedent). `Arc<dyn
Embeddings>` compiles without E0038. **Dimensionality contract** (MUST hold for every impl):
(1) `embed_documents(texts).len() == texts.len()` — one vector per input; (2) all returned
vectors have identical length (the model's embedding dimension); (3) `embed_query` returns a
vector of the same length as any `embed_documents` vector for the same model. Contract violation
→ `Err(FerrochainError { code: "E-EMBED-001" })` (ADR-authored code; PO to formalize in error
taxonomy). Batch failure (e.g., provider rate limit mid-batch) → entire call returns `Err` —
no silent partial-batch degradation to a truncated or empty Vec (DI-014). VP-008 proptest
candidate (any valid Embeddings impl returns vectors with consistent length across embed_documents
and embed_query).

**Grounding:** D21/SS-22. ADR-017 Decisions 1 and 2 place `Embeddings` in ferrochain-core
(same gravity as Retriever, BudgetPolicy, GuardrailHook — avoiding dependency inversion with
ferrochain-memory), define the `&self`/`#[async_trait]` dyn-compatible shape, the three
dimensionality invariants, and the DI-014-aligned batch error semantics.
**Anchor justification:** CAP-031 covers the Embeddings trait seam because it is the dyn-dispatch
boundary used by InMemoryVectorStore (CAP-029 via Arc<dyn Embeddings>), ferrochain-memory
(semantic search), and all first-party and community embedding providers. Placement in
ferrochain-core is required — if the trait lived in ferrochain-vectorstores, ferrochain-memory
would depend on ferrochain-vectorstores (inverted dependency direction).
**Forcing-function linkage (Domain C — OpenClaw):** Domain C requires pluggable embedding
backends as a [NEW] forcing-function requirement. CAP-017's vector retrieval path (long-horizon
memory with vector similarity) is only executable with a concrete `Embeddings` impl at runtime.
CAP-031 is the abstract seam; CAP-032 (OpenAI) and CAP-033 (Ollama) are the first-party v1
impls that make Domain C's vector path holdout-executable. This is the one strictly
holdout-necessary piece of D21: without CAP-031/032/033, the Domain C evaluation cannot
complete the vector retrieval branch.
**Architecture authority:** ADR-017.

### CAP-032: EmbeddingsOpenAI — text-embedding-3-small/large; OpenAiApiKey Newtype; Batch Semantics; reqwest/rustls-tls

Provide a first-party `Embeddings` impl (`ferrochain-openai: openai::embeddings`, struct
`EmbeddingsOpenAI`) targeting the OpenAI `/v1/embeddings` endpoint. **Model currency
(crates.io/2026-07-20):** `text-embedding-3-small` (default — cost/performance balance),
`text-embedding-3-large` (higher quality), `text-embedding-ada-002` (legacy — still supported
by OpenAI but superseded by the 3-series). Model name is a configurable `String` field (not an
enum) so future models are supported without a breaking change. **Credential handling:** API key
is accepted as `OpenAiApiKey` newtype with redacted `Debug` implementation — credential values
never appear in AI context, logs, or lc-JSON serialized output (DI-010). **Batch failure:**
if the provider returns a partial batch error (e.g., rate limit), the entire call returns `Err`
— no silent partial-batch degradation (DI-014). **HTTP client:** reqwest MUST use
`default-features = false, features = ["rustls-tls"]` and `.timeout(Duration::from_secs(30))`
(DI-009); workspace CI gate `deny-client-new` enforces the timeout constraint.

**Grounding:** D21/SS-22. ADR-017 Decision 3 specifies ferrochain-openai gaining
`openai::embeddings`, model currency (verified crates.io/2026-07-20), OpenAiApiKey
newtype credential handling (DI-010), batch-failure Err semantics (DI-014), and the
reqwest/rustls-tls/timeout constraints (DI-009).
**Anchor justification:** CAP-032 is separated from CAP-031 (the abstract trait) because it is
a provider-specific implementation with its own BC surface: OpenAI endpoint configuration,
model name selection, OpenAiApiKey DI, HTTP client constraints, and batch error behavior at
the provider boundary.
**Architecture authority:** ADR-017.

### CAP-033: EmbeddingsOllama — Model-Configurable; /api/embed (Default); use_legacy_endpoint Toggle; No API Key

Provide a first-party `Embeddings` impl (`ferrochain-ollama: ollama::embeddings`, struct
`EmbeddingsOllama`) for local Ollama deployments. No model default — callers configure a
locally-pulled model name (e.g., `nomic-embed-text`, `mxbai-embed-large`). No API key
required (Ollama is a local service; uses the existing Ollama base URL config). **Endpoint
behavior (ADR-017 v1.1):** default sends `POST /api/embed` with `{ model, input: [text] }`
(preferred — newer Ollama releases). When `use_legacy_endpoint: bool` is set to `true`, sends
`POST /api/embeddings` with `{ model, prompt: text }` (legacy fallback for Ollama deployments
that predate `/api/embed`). The legacy toggle is an explicit opt-in, not silent auto-detection
or feature sniffing. **HTTP client:** reqwest MUST use `default-features = false, features =
["rustls-tls"]` and `.timeout(Duration::from_secs(30))` (DI-009) — the 30-second timeout
applies even for localhost targets; the workspace CI gate enforces this unconditionally.

**Grounding:** D21/SS-22. ADR-017 Decision 3 and v1.1 specify ferrochain-ollama gaining
`ollama::embeddings`, the `/api/embed` preferred endpoint with `use_legacy_endpoint` toggle
for `/api/embeddings`, the no-API-key characteristic, and the reqwest/rustls-tls/timeout
constraints.
**Anchor justification:** CAP-033 is separated from CAP-032 because Ollama embeddings have a
distinct operational profile: no API key, local deployment, fully configurable model, and a
dual-endpoint legacy compatibility requirement with its own BC axis (endpoint selection, toggle
semantics, failure behavior when the local Ollama process is unreachable on the configured
base URL).
**Architecture authority:** ADR-017.

---

## P2 — Extended Capabilities (Post-v1 Candidates)

### CAP-017: Long-Horizon Cross-Session Memory Store (KV + Vector)

Persist key-value and vector-embedding memory across threads, decoupled from checkpoints.
Support hybrid retrieval (vector similarity + keyword). Provide user-private, app-scoped,
and session-scoped tiers. GDPR erasure must remove all traces from all tiers (CONFLICT-7
memory scope model). Default backend: SQLite with optional vector embeddings.

**Grounding:** product-brief.md §Constraints (implied by Domain C OpenClaw forcing function
and LangGraph Store analog); CONFLICT-7 memory scope — user/app/session partitioning + GDPR
erasure; domain-c-openclaw.md §2.6.
**Anchor justification:** CAP-017 covers long-horizon memory because Domain C identifies
file-backed memory with vector retrieval as a gap (domain-c §5, item #2), and CONFLICT-7
shapes the tier model.

### CAP-018: Tool Retry with Circuit Breaker

Retry tool invocations with a per-tool retry policy keyed by `(tool_name)` — not args hash.
Enforce a finite `global_limit` (not None). Trip a circuit breaker after repeated failures
to prevent infinite retry on permanently failing tools.

**Grounding:** product-brief.md §Constraints NE catalog — NE-09 (adk-rust P-63 termination
hole REJECT): "Retry bound keyed on (tool_name) not args; finite global_limit non-None
default; circuit-breaker on by default."
**Anchor justification:** CAP-018 covers tool retry because NE-09 is listed in the NE catalog
as a ferrochain requirement derived from the adk-rust counter-example. The brief says all 17
NE items must be anchored before Phase-2 story decomp.

### CAP-019: Formal Verification Pipeline (Kani + cargo-fuzz)

Run Kani harness proofs for the three committed VP obligations (D17-Q7): BSP determinism VP
(VP-001, DI-001/NE-17), session triple-address uniqueness VP (VP-002, DI-005/NE-12), and
workspace path confinement VP (VP-003, DI-007/NE-02). Run cargo-fuzz on the core
serialization and graph-execution paths. Both tools locked by D17-Q7.

**Grounding:** product-brief.md §Success Criteria — "All 3 committed VP obligations pass Kani
harness before v1 convergence (D17-Q7)"; §Scope cross-cutting — "Formal verification
pipeline: Kani proofs + cargo-fuzz [both locked: D17-Q7]."
**Anchor justification:** CAP-019 covers formal verification because D17-Q7 commits the top-3
VP obligations by name and the brief's success criteria include VP coverage as a gate metric.
**Note on phase placement:** VP deliverables belong to Phase 6 (formal hardening). The
behavioral invariants they prove (DI-001, DI-005, DI-007) are Phase-1 BC scope.
