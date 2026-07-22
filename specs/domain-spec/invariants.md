---
document_type: domain-spec-section
level: L2
section: invariants
version: "1.3"
status: active
producer: business-analyst
timestamp: 2026-07-22T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
input-hash: "8dce7df"
traces_to: L2-INDEX.md
decisions: [D11, D17]
changelog:
  - "v1.3 (2026-07-22): Fix burst 235 — DI-015 Enforcer bullet corrected per F-P135-05 architect adjudication (SPLIT enforcement): added co-enforcer BC-2.13.002 (sandbox::process ProcessBackend, .kill_on_drop(true)); clarified that tokio::time::timeout wraps sandbox execute() call in BashTool, not tokio::process::Command directly (which is spawned internally by sandbox::process). input-hash refreshed."
  - "v1.2 (2026-07-22): Fix burst 234 — DI-015 (Subprocess Execution Timeout, Mandatory) added per F-P134-06 architect adjudication; no subprocess-execution-timeout invariant existed in DI-001..014. Census: 14→15 invariants. New section: Tool Execution Invariants. input-hash refreshed (0dac18e)."
  - "v1.1 (2026-07-17): Provenance-integrity fix — STATE.md removed from inputs (D11/D17 decisions and CONFLICT-*/NE-* invariant sources were baked at authoring time from COMPARATIVE-ASSESSMENT.md, not live state); input-hash recomputed."
---

# Domain Invariants

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

DI-NNN invariants are business rules that must always hold — not implementation choices.
Each invariant that originates from a CONFLICT or NE decision cites its source.

---

## Graph Execution Invariants

### DI-001: BSP Reducer Determinism
Channel reducers apply in deterministic task-identity-sorted order within a super-step.
Identical inputs always produce identical GraphState regardless of node completion order.
Concurrent writes to a LastValue channel from the same super-step raise InvalidUpdateError.

- **Source:** CONFLICT-1, NE-17 (adk-rust nondeterministic buffer_unordered is counter-example)
- **VP obligation:** Kani harness — concurrent node outputs → identical reduced state (D17-Q7)
- **Invariant class:** process correctness

### DI-002: Per-Task Durability (Sync Default)
Every PregelTask's output is stored via `put_writes` before the next super-step begins.
The sync durability tier is the default; async and exit-only tiers are explicit opt-in.
A process crash during a super-step must not lose task outputs from completed tasks.

- **Source:** CONFLICT-2, D11.3, D17-Q3 (adk-rust step-boundary-only is counter-example)
- **Invariant class:** durability, data integrity

### DI-003: HITL FIFO Resume-Value Delivery
Resume values are consumed in strict FIFO order. An interrupted node re-executes from the
start of its super-step, with the dequeued resume value available in its scratchpad.
There is no mechanism to deliver a resume value out of order or to skip an interrupt.

- **Source:** CONFLICT-3, D17-Q2 (adk-rust notification-only HITL is counter-example)
- **Invariant class:** process correctness, human safety

### DI-004: Monotonic Checkpoint Clock
Checkpoint IDs are monotonically increasing values from a logical clock (not wall-clock
timestamps). Fork lineage is tracked via parent\_checkpoint\_id pointers, not by copying
parent state. UUID v4 plus wall-clock ordering is disallowed.

- **Source:** CONFLICT-4 (adk-rust UUID v4 + wall-clock is counter-example)
- **Invariant class:** ordering, durability

---

## Tenancy and Security Invariants

### DI-005: Session Triple-Address Uniqueness
Every state operation is addressed by the triple (thread\_id, checkpoint\_ns, checkpoint\_id).
No code path may address state by bare thread\_id alone. The triple flows from the trait
method signature to the SQL WHERE clause without collapsing.

- **Source:** NE-12 (adk-rust identity-triple collapse is counter-example)
- **VP obligation:** Kani harness — session tenancy partition (D17-Q7)
- **Invariant class:** multi-tenancy, security

### DI-006: Enforcing Sandbox Backend is Default
The default tool-execution backend isolates the tool in an enforcing context (WASM or
container). The process backend requires explicit opt-in and emits a loud runtime warning.
Calling `Sandbox::execute` on a strict policy with a non-enforcing backend returns
`Err(PolicyNotEnforceable)` — it does not silently fall back to process execution.

- **Source:** NE-01 (adk-rust default no-isolation is counter-example)
- **Invariant class:** security, least-privilege

### DI-007: Workspace Path Confinement
Every workspace file operation calls `canonicalize_beneath_root(base, path)` at access time.
No file operation may observe content outside the declared workspace root. Symlink traversal
that escapes the root returns `Err(WorkspaceEscape)`.

- **Source:** NE-02 (adk-rust string-only path safety without symlink resolution is counter-example)
- **VP obligation:** no file op observes outside workspace root (D17-Q7 confirmed by architect)
- **Invariant class:** security, integrity

### DI-008: Library Constructor Result Contract
All public library constructors return `Result<T, FerrochainError>`. `Default` must not
delegate to a fallible constructor. `.expect()`, `.unwrap()`, and `assert!` are disallowed
in non-test library code. CI lint gate enforces this.

- **Source:** NE-07 (adk-rust `.expect()` panic in WASM engine init is counter-example)
- **Invariant class:** reliability, API contract

### DI-009: Outbound Connection Timeout (Mandatory)
Every outbound HTTP client builder must set a connection timeout (recommended 30 seconds).
Zero-argument `Client::new()` calls are disallowed outside test files. CI lint gate enforces
this. No outbound call may hang indefinitely.

- **Source:** NE-04 (adk-rust 8+ sites with no `.timeout()` are the counter-example)
- **Invariant class:** reliability, operational safety

### DI-010: Credential Opacity
Every API key type is a newtype struct. Its `Debug` impl emits `"<redacted>"`. It does not
`#[derive(Serialize)]`. It does not `impl Deref<Target = str>`. Credentials never appear
in logs, error messages, or serialized artifacts.

- **Source:** NE-10 (adk-rust bare-String API keys with derive(Debug) are counter-example)
- **Invariant class:** security, credential hygiene

---

## Server and Streaming Invariants

### DI-011: Streaming / Unary Run Equivalence
The streaming run endpoint and the unary run endpoint invoke the same execution engine and
produce the same final answer for the same inputs. There is no stub path that emits
task-state events without running the actual graph.

- **Source:** NE-13, CONFLICT-10 (adk-rust streaming stub that never invokes engine is counter-example)
- **Invariant class:** behavioral consistency, correctness

### DI-012: Guardrail Coverage at Ingress Boundaries
Guardrail hooks fire on tool-result ingress, RAG ingress, and memory ingress — not only on
user-input and model-output boundaries. Content that fails a guardrail does not enter the
model context under any code path.

- **Source:** NE-06, HS-8, D17-Q8 (adk-rust guardrails cover only user-input + model-output)
- **Invariant class:** security, Domain A forcing function

### DI-013: Secure Server Defaults
`SecurityConfig::default()` must deny CORS (no wildcard). The debug/introspection route
requires an explicit opt-in key in the config. Unauthenticated access to debug routes
returns 403, not 200 or 404.

- **Source:** NE-14 (adk-rust `SecurityConfig::default()` CORS wildcard + debug route is counter-example)
- **Invariant class:** security, deployment safety

---

## Error and Validation Invariants

### DI-014: Error Propagation (No Silent Swallowing)
Validation failures propagate as `Err(FerrochainError)`. No public API returns `None` or
an empty result to represent a validation failure. Skill-coordinator and plugin-coordinator
validation errors are not silently discarded.

- **Source:** NE-03 (adk-rust strict-mode skill coordinator returns None on validation failure)
- **Invariant class:** observability, reliability

---

## Tool Execution Invariants

### DI-015: Subprocess Execution Timeout (Mandatory)
Every spawned subprocess must complete within its configured `max_duration` wall-clock limit.
The executor must terminate the subprocess and return a structured timeout error
(E-TOOLS-004 BashTimeout) if the limit is exceeded; no subprocess execution may hang
indefinitely. Distinct from DI-009 (which governs outbound HTTP-client connection timeouts).

- **Source:** F-P134-06 (architect adjudication — subprocess-execution-timeout invariant absent from DI-001..014; counter-example: adk-rust spawns subprocesses without configurable timeout)
- **Enforcer:** BC-2.23.005 (BashTool, `tools::shell`); co-enforcer: BC-2.13.002 (`sandbox::process` ProcessBackend — defense-in-depth via `.kill_on_drop(true)`); implementation: `tokio::time::timeout` wrapping the sandbox backend `execute()` call in BashTool; `tokio::process::Command` is spawned by `sandbox::process` internally — NOT called directly by BashTool
- **Invariant class:** reliability, operational safety
