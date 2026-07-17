---
document_type: architecture-section
level: L3
section: purity-boundary-map
version: "1.3"
status: active
producer: architect
timestamp: 2026-07-17T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd.md
input-hash: "c0b5473"
traces_to: ARCH-INDEX.md
decisions: [D17]
changelog:
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
effectful dependency). All 35 criticality-universe modules plus structural and definitions-only
modules are enumerated in `## Purity Classification` below. Enforcement invariants follow
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
| `checkpoint::clock` | ferrochain-checkpoint | Monotonic counter increment; UUID wall-clock rejection is pure check | — |
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
| `core::budget` | ferrochain-core | definitions-only: `BudgetPolicy` trait (`evaluate()` pure, no async, no I/O per ADR-009 Option 3), `PolicyDecision` enum (Allow/Escalate/Deny), `TokenUsage` struct, `RunContext` struct; no execution logic (dispatch engine lives in `graph::budget`) (ADR-009 Option 3 / BC-2.10.001) | — |

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

> **Storage-trait Boundary pattern:** `checkpoint::saver` (SS-04) and `memory::store` (SS-15)
> both follow the same canonical pattern: the trait module defines pure validation logic + an
> async dispatch contract, while effectful I/O is implemented by separate Effectful Shell modules
> (checkpoint::sqlite/postgres/memory and memory::sqlite/in_memory/search/skills respectively).
> Both are correctly classified Boundary. The parallel is intentional.

## Purity Enforcement Rules

1. Pure modules MUST NOT import `tokio`, `reqwest`, `axum`, or any I/O crate at the module level.
2. Pure modules MUST NOT call any function that returns `impl Future` unless the future itself is pure (e.g., a test double).
3. The Kani harness for VP-001/VP-002/VP-003 operates ONLY on the pure-core modules listed above.
4. Any refactor that moves I/O into a currently-pure module requires an architectural review and ADR update.
