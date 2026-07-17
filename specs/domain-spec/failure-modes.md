---
document_type: domain-spec-section
level: L2
section: failure-modes
version: "1.0"
status: active
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
phase: 1a
inputs:
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/specs/product-brief.md
input-hash: "42b6f60"
traces_to: L2-INDEX.md
decisions: [D17]
---

# Failure Modes

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.

FM-NNN are runtime failure modes grouped by subsystem. Each cites the adk-rust
counter-example or domain source where applicable.

> **Detection-field convention:** The `Detection:` field names the *verification vehicle* —
> the mechanism that catches the failure (Kani VP harness, integration test, domain holdout,
> CI lint, DEC unit test, etc.). Explicit `DI-NNN` citation in the Detection field is required
> only when the verification vehicle IS that DI's VP proof harness. FMs whose detection
> vehicle is an integration test, holdout scenario, or CI lint do not require a DI-NNN cite;
> this is correct by design (e.g., FM-006, FM-012 have no governing DI-NNN).

---

## Graph Execution Subsystem

### FM-001: Non-Deterministic Reducer Order
**What goes wrong:** Channel reducers apply in completion order (buffer_unordered) rather
than deterministic task-identity order. Identical inputs can produce different GraphState
on each execution. Downstream nodes see different values; holdout evaluation is
unreproducible.
**Trigger:** Concurrent node tasks complete in different arrival orders across runs.
**Counter-example source:** adk-rust NE-17, CONFLICT-1 — `buffer_unordered` folding.
**Detection:** Proptest / Kani VP harness (DI-001); sorted-order enforcement in reducer loop.

### FM-002: Checkpoint Write Loss on Crash
**What goes wrong:** Per-task outputs are batched and written only at step boundaries
(adk-rust style). A crash mid-super-step loses all completed task outputs. On resume,
completed tasks re-run, producing duplicate tool side-effects.
**Trigger:** Process crash after tasks complete but before step-boundary checkpoint flush.
**Counter-example source:** CONFLICT-2, adk-rust step-boundary-only durability.
**Detection:** Domain B dark-factory holdout — resume after crash must not re-run completed tasks.

### FM-003: HITL Resume Value Mis-Delivery
**What goes wrong:** Resume value intended for interrupted node N is delivered to a
different node, or delivered out of order when multiple stacked interrupts exist.
**Trigger:** FIFO queue not enforced; resume-value routing uses node name rather than
interrupt_id as the key.
**Counter-example source:** CONFLICT-3 — adk-rust notification-only HITL has no scratchpad.
**Detection:** DEC-007 test; Domain A and B holdout — HITL resume-value injection.

### FM-004: Checkpoint ID Collision on Fork
**What goes wrong:** Two fork branches starting from the same checkpoint receive the same
checkpoint_id on their first write, creating an ambiguous history.
**Trigger:** Wall-clock timestamp or sequential counter used without fork-awareness.
**Counter-example source:** CONFLICT-4 — adk-rust UUID v4 + wall-clock.
**Detection:** Concurrent-fork integration test; Kani VP candidate.

---

## Checkpoint / State Subsystem

### FM-005: Cross-Tenant State Read
**What goes wrong:** A bare thread_id lookup without checkpoint_ns collation returns state
from a different tenant's thread with the same thread_id prefix.
**Trigger:** Session identity collapses from (thread_id, checkpoint_ns, checkpoint_id)
to bare thread_id at the database boundary.
**Counter-example source:** NE-12 — adk-rust triple collapse.
**Detection:** DI-005 Kani VP — tenancy partition invariant; integration test with two tenants.

### FM-006: Encryption Gap Covers State but Not Events
**What goes wrong:** GraphState is encrypted at rest but streaming event payloads stored in
the event log are plaintext. Rotation failure swallowed with `let _ = rotation_result`.
**Trigger:** Encryption implementation applied to state blob only; event table not included.
**Counter-example source:** NE-11 — adk-rust encryption covers session STATE only.
**Detection:** Integration test: assert event payloads fail decryption without the key.

---

## Server Subsystem

### FM-007: Streaming Endpoint Does Not Invoke Engine
**What goes wrong:** The streaming run endpoint emits task-state stub events but never
dispatches the actual graph execution engine. The final answer is fabricated or absent.
**Trigger:** Streaming handler wired to a stub path independent of the unary execution path.
**Counter-example source:** NE-13 — adk-rust streaming sends stub events only.
**Detection:** DI-011; streaming/unary equivalence holdout (Domain B).

### FM-008: Debug Route Exposed Without Auth
**What goes wrong:** The introspection/debug HTTP route is reachable unauthenticated,
leaking graph config, state, or internal metrics.
**Trigger:** `SecurityConfig::default()` does not gate the debug route; default allows all.
**Counter-example source:** NE-14 — adk-rust `SecurityConfig::default()` unauthenticated debug.
**Detection:** DI-013 security test — assert 403 on debug route without explicit opt-in key.

### FM-009: CORS Wildcard Default
**What goes wrong:** `SecurityConfig::default()` emits CORS `Access-Control-Allow-Origin: *`,
making the ferrochain-server exploitable via CSRF from any origin.
**Trigger:** Default security config copied from OpenClaw-style permissive defaults.
**Counter-example source:** NE-14.
**Detection:** Integration test — assert CORS denied on default config.

---

## Providers and Tools Subsystem

### FM-010: API Key Leaked via Debug or Serialize
**What goes wrong:** A ProviderClient's ApiKey appears in a log line, panic message, or
serialized JSON because it derives `Debug` or `Serialize` without redaction.
**Trigger:** Bare String or newtype without redacted Debug impl; `#[derive(Serialize)]` applied.
**Counter-example source:** NE-10 — adk-rust workspace-wide bare-String API keys.
**Detection:** DI-010; CI lint: deny derive(Debug) on API key types without explicit impl.

### FM-011: Outbound HTTP Hangs Indefinitely
**What goes wrong:** A reqwest client built without `.timeout()` calls a provider endpoint
that stops responding. The thread blocks indefinitely; the Run never completes.
**Trigger:** `Client::new()` or builder without `.timeout()` in production code path.
**Counter-example source:** NE-04 — adk-rust 8+ sites without timeout.
**Detection:** DI-009 CI lint gate — zero `Client::new()` outside test files.

### FM-012: Tool-Retry Loops Forever
**What goes wrong:** A tool configured with per-args-hash retry keying + `global_limit: None`
retries a permanently failing tool call without bound. The run never terminates.
**Trigger:** Retry config inherits adk-rust P-63 pattern (args-hash key, None global limit).
**Counter-example source:** NE-09 — P-63 termination hole.
**Detection:** DEC unit test — tool that always fails must hit a finite retry bound; circuit
breaker trips.

---

## Core / Sandbox Subsystem

### FM-013: Sandbox Executes Without Enforcement
**What goes wrong:** A tool is dispatched through the sandbox with a strict policy, but the
configured backend is a non-enforcing process executor. The call does not return
`Err(PolicyNotEnforceable)` — it silently falls back to process execution. The policy's
intent (WASM or container isolation) is never enforced; the tool runs with the host
process's full filesystem, network, and environment access.
**Trigger:** Process backend used as default; `Sandbox::execute` does not check backend
enforcement capability against policy strictness before dispatch.
**Counter-example source:** NE-01 / P-61 — adk-rust process backend default with no
enforcement binding; capability honesty does not force enforcement.
**Detection:** DI-006 enforcement contract test — `Sandbox::execute` with strict policy
against a non-enforcing backend must return `Err(PolicyNotEnforceable)`, not `Ok`.
Process backend is only reachable via explicit opt-in with loud runtime warning.

### FM-014: Library Constructor Panics Instead of Returning Result
**What goes wrong:** A library constructor calls `.expect()` or `.unwrap()` on a fallible
internal operation (e.g., WASM engine initialization). When initialization fails, the host
process panics and terminates. The caller has no opportunity to observe, log, or recover
from the failure. Dependent services crash without a structured error.
**Trigger:** `.expect()` / `.unwrap()` in a public constructor body; or `Default::default()`
delegates to a fallible constructor path.
**Counter-example source:** NE-07 / P-66 — adk-rust WASM engine init calls `.expect()`;
the constructor signature returns the initialized type directly, not `Result<T, _>`.
**Detection:** DI-008 CI lint gate — deny `.expect()` / `.unwrap()` / `assert!` in non-test
library code; proptest boundary: constructor called with adversarial inputs must yield
`Err(FerrochainError)`, never panic.

---

## Subsystem Summary

| Subsystem | FM Count | Highest Severity |
|-----------|----------|-----------------|
| Graph Execution | FM-001 to FM-004 | High (FM-001 breaks VP, FM-002 breaks durability) |
| Checkpoint / State | FM-005, FM-006 | High (FM-005 is a security failure) |
| Server | FM-007, FM-008, FM-009 | High (FM-007 breaks behavioral contract; FM-008 is security) |
| Providers and Tools | FM-010, FM-011, FM-012 | High (FM-010 is security; FM-011 is DoS-class) |
| Core / Sandbox | FM-013, FM-014 | High (FM-013 is security/policy; FM-014 is reliability/availability) |
