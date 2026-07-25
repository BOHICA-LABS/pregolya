---
document_type: domain-spec-section
level: L2
section: failure-modes
version: "1.1"
status: active
producer: business-analyst
timestamp: 2026-07-23T00:00:00Z
phase: 1a
inputs:
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/specs/product-brief.md
input-hash: "7634e89"
traces_to: L2-INDEX.md
decisions: [D17, D20, D21, D23]
changelog:
  - "v1.1 (burst-241 OBS-P141-A, 2026-07-23): Add FM-015 through FM-019 — five SECURITY-CRITICAL failure modes introduced by D21/D23 that each carry a dedicated Kani VP or error-code gate. FM-015 (PreToolCallHook Deny bypass, VP-011/D23) added to Graph Execution. FM-016 (Injection-guard bypass, VP-006/D21) and FM-018 (Reviver allowlist bypass, VP-010/D21) added to Core/Sandbox. FM-017 (Zero-norm NaN corruption, VP-009/D21) and FM-019 (First-party tool path escape, E-TOOLS-001/D23) added to Providers and Tools. Subsystem Summary table updated with new FM ranges and severities. decisions list updated to D17/D20/D21/D23."
  - "v1.0 (2026-07-14): Initial FM register authored (D17 adk-rust NE-*/CONFLICT-* counter-examples)."
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

### FM-015: PreToolCallHook Deny Bypass (SECURITY-CRITICAL)
**What goes wrong:** `PreToolCallHook::pre_invoke` returns `PreToolDecision::Deny { reason }` but
the tool is invoked anyway — the fail-closed contract (VP-011) is violated. The denied tool
executes with full side-effect authority despite an explicit deny decision, undermining
human-in-the-loop governance of high-risk tools (BashTool, WriteFileTool, EditFileTool).
**Trigger:** A code path in the graph dispatch loop that checks the hook return but enters
the tool invocation branch regardless; or a race condition where the Deny check and the
dispatch branch are not atomically coupled.
**Counter-example source:** D23 security requirement (ADR-018 Decision 4, BC-2.05.007 fail-closed
invariant). No adk-rust counter-example — this is a ferrochain-first HITL capability.
**Detection:** VP-011 Kani proof (BC-2.05.007 fail-closed VP candidate — exhaustive property:
`Deny` return NEVER leads to tool invocation, regardless of execution path). Integration test:
mock hook returning Deny for all inputs; assert tool fn body is never called.

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

### FM-017: Zero-Norm NaN Corruption in Embedding Similarity (SECURITY-CRITICAL)
**What goes wrong:** An embedding provider returns a zero-magnitude vector (all components 0.0)
for a degenerate input (empty string, whitespace-only, adversarially crafted token sequence).
Cosine similarity computes 0/0 = NaN for comparisons involving the zero vector. NaN propagates
through the similarity ranking and infects the top-k result set with non-deterministic ordering
(NaN comparisons are undefined). RAG retrieval delivers wrong or arbitrary documents to the
model context.
**Trigger:** No zero-norm guard in the embedding normalization path; provider returns all-zero
vector without error; downstream similarity comparison proceeds without checking for NaN.
**Counter-example source:** D21 embeddings addition (ADR-017). No adk-rust counter-example —
ferrochain-first capability.
**Detection:** VP-009 Kani proof (pure arithmetic property: zero-norm input must return
`Err(E-VS-001)` before similarity computation proceeds; NaN must never enter the result
set). Unit test: embed_documents with zero-magnitude vector; assert E-VS-001 returned,
not a NaN-contaminated result.

### FM-019: First-Party File Tool Path Escape (SECURITY-CRITICAL)
**What goes wrong:** `ReadFileTool`, `WriteFileTool`, or `EditFileTool` resolves a user-supplied
(or model-supplied) relative path that escapes the allowed working directory via traversal
sequences (`../../../etc/passwd`, symlink chains, absolute path injection). The tool
accesses or overwrites files outside the intended scope with the host process's credentials.
**Trigger:** Path not canonicalized against an allowed-root anchor before filesystem access;
or allowed-root check applied before symlink resolution (TOCTOU).
**Counter-example source:** D23 first-party tools (ADR-020/SS-23). No adk-rust counter-example —
ferrochain-first capability.
**Detection:** E-TOOLS-001 path validation error (must be returned for any path resolving outside
allowed root); security integration test: supply `../` traversal paths and assert
`Err(E-TOOLS-001)` returned before any I/O occurs. High action_risk annotation on
WriteFileTool/EditFileTool enforces PreToolCallHook gate as an additional defense-in-depth layer.

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

### FM-016: Injection-Guard Bypass at Template Render (SECURITY-CRITICAL)
**What goes wrong:** A `TrustLevel::Untrusted` variable is substituted into a `TrustRequired`
template slot but `E-TMPL-001` (SECURITY/InjectionAttempt) is NOT raised by
`format_messages()`. Adversarial content from an external source (RAG retrieval, MCP tool
output) enters the model context without the injection guard firing, enabling prompt-injection
attacks (ADR-015 §Decision 3, CAP-022/023).
**Trigger:** Trust-level/slot-policy check omitted from a code path in `format_messages()`; or
conditional branching that skips the check for a subset of message variants.
**Counter-example source:** D21 injection-guard requirement (ADR-015, CAP-022/CAP-023). No
adk-rust counter-example — ferrochain-first template security capability.
**Detection:** VP-006 Kani proof (exhaustive property: Untrusted variable in TrustRequired slot
ALWAYS raises E-TMPL-001 before PromptValue is produced — no PromptValue with
TrustRequired/Untrusted combination ever exists). Unit test: render template with Untrusted
variable in TrustRequired slot; assert Err(E-TMPL-001), never Ok(PromptValue).

### FM-018: Reviver Allowlist Bypass During Deserialization (SECURITY-CRITICAL)
**What goes wrong:** `Reviver::revive()` processes a `Serialized::Constructor` payload whose
`id` path (namespace vector) is NOT registered in the `LcEntry` allowlist. The Reviver
instantiates the type anyway — either due to a missing registry check or a catch-all fallback
branch — producing an object of an unauthorized type from untrusted wire data. This opens
deserialization gadget chains and arbitrary type instantiation risks.
**Trigger:** Allowlist lookup returns `None` but deserialization proceeds instead of returning
`Err(E-SRLZ-001 UnknownType)`.
**Counter-example source:** D21 serialization addition (ADR-016). No adk-rust counter-example —
ferrochain-first capability.
**Detection:** VP-010 Kani proof (property: `Constructor` with any `id` not in the registered
`LcEntry` inventory ALWAYS returns `Err(E-SRLZ-001)` — no type instantiation occurs for
unknown ids). Integration test: present crafted Constructor payloads with unknown id vectors;
assert Err(E-SRLZ-001) for every unknown id.

---

## Subsystem Summary

| Subsystem | FM Count | Highest Severity |
|-----------|----------|-----------------|
| Graph Execution | FM-001 to FM-004, FM-015 | SECURITY-CRITICAL (FM-015 PreToolCallHook Deny bypass, VP-011/D23); High (FM-001 VP, FM-002 durability) |
| Checkpoint / State | FM-005, FM-006 | High (FM-005 is a security failure) |
| Server | FM-007, FM-008, FM-009 | High (FM-007 breaks behavioral contract; FM-008 is security) |
| Providers and Tools | FM-010, FM-011, FM-012, FM-017, FM-019 | SECURITY-CRITICAL (FM-017 NaN corruption VP-009/D21; FM-019 path escape E-TOOLS-001/D23); High (FM-010 credential leak; FM-011 DoS) |
| Core / Sandbox | FM-013, FM-014, FM-016, FM-018 | SECURITY-CRITICAL (FM-016 injection-guard bypass VP-006/D21; FM-018 reviver allowlist bypass VP-010/D21); High (FM-013 policy; FM-014 reliability) |
