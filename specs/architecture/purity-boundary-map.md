---
document_type: architecture-section
level: L3
section: purity-boundary-map
version: "1.0"
status: active
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd.md
input-hash: "04e632a218b2bbab"
traces_to: ARCH-INDEX.md
decisions: [D17]
---

# Purity Boundary Map: ferrochain

> **Iron Law:** Pure-core modules are formal verification targets (Kani). Effectful-shell
> modules are integration-tested and fuzz-tested but not Kani-provable. Every module
> must appear in exactly one column. Modules that cross the boundary must be redesigned
> to split their pure and effectful parts.

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
| `memory::store` (validation) | ferrochain-memory | `MemoryStore` key/query validation logic; no I/O | — |

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

## Purity Enforcement Rules

1. Pure modules MUST NOT import `tokio`, `reqwest`, `axum`, or any I/O crate at the module level.
2. Pure modules MUST NOT call any function that returns `impl Future` unless the future itself is pure (e.g., a test double).
3. The Kani harness for VP-001/VP-002/VP-003 operates ONLY on the pure-core modules listed above.
4. Any refactor that moves I/O into a currently-pure module requires an architectural review and ADR update.
