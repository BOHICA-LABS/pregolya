---
document_type: story
level: ops
story_id: S-1.19
epic_id: E-11
version: "1.10"
status: draft
producer: story-writer
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.1 (ADR-027 M3/2026-08-24): AC traces re-cited to stable clause anchors."
  - "1.2 (ADR-027 M3 straggler/2026-08-24): straggler conversion to stable clause anchors."
  - "1.3 (round-25/F-P2A109-01/2026-08-28): Async panic mechanism corrected — synchronous `std::panic::catch_unwind` is inadequate for async `GuardrailHook::evaluate` (cannot catch panics fired during `.await` polling; CWE-248/703; mirrors ADR-029 §Decision 5 / BC-2.09.008 EC-010). Task §5, EC-001, and §Previous Story Intelligence S-1.04 Gotchas row updated to `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(...)))` at dispatch site. SEC-008-style `panic=unwind` build-profile note added. `futures` crate added to §Library & Framework Requirements."
  - "1.4 (round-26/F-P2A113-03/2026-08-28): AC-024 added: SEC-008 panic-profile build obligation mirroring S-2.11 AC-037 — `FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(...)))` in `pregolya-graph/src/provenance.rs` is voided if release profile sets `panic = \"abort\"`; implementer obligation is `// SEC-008` comment annotation at dispatch site; devops-engineer asserts workspace `Cargo.toml` profile at Phase-3 init. Traces to BC-2.11.002 PC-001 (unconditional hook dispatch). BC-2.11.002 Covered ACs updated to include AC-024. Task 11 added: SEC-008 annotation obligation. Token Budget updated (~5,000 → ~5,500 story spec; total ~25,500). Input-hash updated."
  - "1.5 (R28/F-P2A123-03/2026-08-28): AC-024 re-anchored from BC-2.11.002 {PC-001} to BC-2.11.002 {INV-005} — SEC-008 async panic-recovery obligation now lives in {INV-005} (added R27/v1.15); {PC-001} covers unconditional hook dispatch only, not panic recovery. Task 11 BC trace annotation updated from PC-001 to INV-005. Input-hash refreshed."
  - "1.6 (R29/F-P2A127-02+O-P2A125-02/2026-08-28): (1) AC-025 added: SEC-008 async-catch MECHANISM Red Gate — `GuardrailHook::evaluate` panic during `.await` polling caught via `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(content, tag))).await` in `provenance.rs`; content treated as Fail (fail-closed); `Err(PregolyaError { code: \"E-CORE-007\", .. })` propagated; Red Gate test `test_BC_2_11_002_hook_panic_caught_fail_closed_e_core_007()` MUST drive panic through `.await` (synchronous `std::panic::catch_unwind` substitute must NOT satisfy it); traces to BC-2.11.002 {INV-005}/EC-001 (F-P2A127-02). (2) §Library & Framework Requirements `futures` row: secondary anchor updated from `ADR-029 §Decision 5` to `BC-2.11.002 {INV-005}` (cross-subsystem anchor correction; EC-001 retained) (O-P2A125-02). (3) BC-2.11.002 covered-ACs updated to include AC-025. Token Budget updated (~5,500 → ~5,700 spec; total ~25,500 → ~25,700). input-hash unchanged — no BC input file changes in round-29."
  - "1.7 (R33/F-P2A143-01/2026-08-29): Exhaustive sibling-sweep for ADR-029 §Decision 5 cross-subsystem mis-anchor (F-P2A143-01). Re-anchored 3 remaining SS-11 mis-anchor sites from ADR-029 §Decision 5 to BC-2.11.002 {INV-005}/EC-001: (1) §Edge Cases EC-001 row; (2) §Tasks Task 5; (3) §Previous Story Intelligence S-1.04 row. CWE-248/703 citations and FutureExt::catch_unwind mechanism text preserved. SS-09 sibling see-also note added at each corrected site. Input-hash refreshed — drift caused by BC input updates since R29 (no story-input-file edits in this burst)."
  - "1.8 (R45/F-P2A189-01/2026-08-30): Workspace-root panic=unwind pin propagated to all four stale sites (F-P2A189-01 [HIGH, CWE-248/703]). Task 5: replaced 'devops must assert this for pregolya-graph at Phase-3 CI setup' with workspace-root form — library-member (pregolya-graph) [profile.release] override is silently ignored by Cargo and MUST NOT be relied upon; devops-engineer asserts workspace-root Cargo.toml at Phase-3 init. AC-024: heading updated to 'workspace-root release profile (pregolya-server binary)'; body extended with library-member-inert clause (Cargo honors [profile.release] panic ONLY at workspace root); devops obligation updated to 'assert on pregolya-server binary profile, NOT pregolya-graph library-member profile'; comment annotation updated to cite library-member-inert caveat. Task 11: comment annotation text updated to workspace-root form with library-member-inert caveat. EC-001: 'Recovery requires panic=unwind build profile' replaced with workspace-root form plus library-member-inert MUST NOT note. Mirrors S-2.11 AC-037 (v1.31). Input-hash refreshed by state-manager."
  - "1.9 (round-49/F-P2A207-02/2026-08-31): F-P2A207-02 [HIGH] — AC-026 added: create `pregolya-core/src/invocation_context.rs` with `InvocationContext` struct (guardrail_hook: Option<Arc<dyn GuardrailHook>> field), `new()`, `register_guardrail()`, `guardrail_hook()`, and `Default` impl per interface-definitions.md §InvocationContext. AC-026 traces to BC-2.11.001–006 {PRE-001}. BC table updated: AC-026 (PRE-001) added to all 6 BC rows. File Structure: `pregolya-core/src/invocation_context.rs` CREATE row added; lib.rs modify row updated. Task 12 added. Token Budget updated to include invocation_context.rs (~800 tokens; interface-definitions.md InvocationContext section ~1,200; total ~27,200). input-hash updated to 951a705."
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.001.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.002.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.003.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.004.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.005.md
  - .factory/specs/behavioral-contracts/ss-11/BC-2.11.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "2e7fed6"
traces_to: .factory/stories/STORY-INDEX.md
points: 13
depends_on: [S-1.14, S-1.04]
blocks: [S-2.02, S-2.10]
behavioral_contracts: [BC-2.11.001, BC-2.11.002, BC-2.11.003, BC-2.11.004, BC-2.11.005, BC-2.11.006]
verification_properties: []
priority: P0
cycle: v1.0.0-greenfield
wave: 1
target_module: pregolya-graph
subsystems: [SS-11]
estimated_days: 5
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

> **tdd_mode:** strict — full TDD Iron Law enforced. Security-critical path: fail-closed behavior must be the first tests written.

> **Execute:** `/vsdd-factory:deliver-story S-1.19`

# S-1.19: GuardrailHook, ProvenanceTag, and Ingress Boundary Enforcement

## Narrative

- **As a** graph runtime developer building the pregolya-graph ingress guardrail system
- **I want to** attach `ProvenanceTag` unconditionally to every content unit at tool-result, RAG, and memory ingress boundaries, fire `GuardrailHook::evaluate` before any tagged content enters the model context, enforce atomic rejection (rejected content reaches zero bytes in the model input buffer), and emit a structured `WARN` log when no hook is registered
- **So that** prompt-injection attacks via tool results, poisoned RAG chunks, and compromised memory items are blocked at the ingress boundary (DI-012 / NE-06), satisfying Domain A SOC analyst and Domain C OpenClaw security requirements

## Behavioral Contracts

| BC | Title | Covered ACs |
|----|-------|------------|
| BC-2.11.001 | ProvenanceTag Attached at Every Ingress Boundary (Tool-Result, RAG, Memory) | AC-001..AC-004, AC-026 (PRE-001) |
| BC-2.11.002 | GuardrailHook Fires Unconditionally at Tool-Result Ingress | AC-005..AC-009, AC-024, AC-025, AC-026 (PRE-001) |
| BC-2.11.003 | GuardrailHook Fires at RAG Ingress | AC-010..AC-013, AC-026 (PRE-001) |
| BC-2.11.004 | GuardrailHook Fires at Memory Ingress | AC-014..AC-016, AC-026 (PRE-001) |
| BC-2.11.005 | Rejected Content Does Not Enter Model Context Under Any Code Path | AC-017..AC-020, AC-026 (PRE-001) |
| BC-2.11.006 | No-Hook Default — Content Passes Through with WARNING LOG (Default-Permit) | AC-021..AC-023, AC-026 (PRE-001) |

## Acceptance Criteria

### AC-001 (traces to BC-2.11.001 PC-001 — tool-result content tagged with ProvenanceTag)
Every `ContentBlock` from a tool-result boundary carries `ProvenanceTag { boundary_type: BoundaryType::ToolResult, ingress_id: Uuid, sequence_position: usize }` before any consumer (hook or model context) is called. Verified by `test_BC_2_11_001_tool_result_content_tagged()`.

### AC-002 (traces to BC-2.11.001 PC-002 — RAG chunk tagged with ProvenanceTag)
Every document chunk from a RAG retrieval boundary carries `ProvenanceTag { boundary_type: BoundaryType::RAGRetrieval, ingress_id: Uuid, sequence_position: usize }`. Verified by `test_BC_2_11_001_rag_chunk_tagged()`.

### AC-003 (traces to BC-2.11.001 PC-003 — memory item tagged with ProvenanceTag)
Every item from a memory ingress boundary carries `ProvenanceTag { boundary_type: BoundaryType::MemoryIngress, ingress_id: Uuid, sequence_position: usize }`. Verified by `test_BC_2_11_001_memory_item_tagged()`.

### AC-004 (traces to BC-2.11.001 INV-001 — tagging is unconditional regardless of hook presence)
`ProvenanceTag` attachment occurs whether or not a `GuardrailHook` is registered. A run with no hook still produces tagged content. Verified by `test_BC_2_11_001_tagging_unconditional_no_hook()`.

### AC-005 (traces to BC-2.11.002 PC-001 — GuardrailHook::evaluate called for every tool-result ContentBlock)
When a `GuardrailHook` is registered, `evaluate(content: IngressContent::ToolResult(ContentBlock), provenance_tag)` is called for every `ContentBlock` before it enters the model input buffer. Verified by `test_BC_2_11_002_evaluate_called_for_every_tool_content_block()`.

### AC-006 (traces to BC-2.11.002 PC-002 — Pass forwards ContentBlock unchanged)
`GuardrailResult::Pass` → the `ContentBlock` is forwarded to the model input buffer unchanged. Verified by `test_BC_2_11_002_pass_forwards_content_unchanged()`.

### AC-007 (traces to BC-2.11.002 PC-003 — Fail injects error block and emits GuardrailDecision)
`GuardrailResult::Fail { reason, severity }` → original content NOT forwarded; error block injected at same position; `StreamEvent::GuardrailDecision { boundary: ToolResult, decision: Fail, reason: Some(reason), .. }` emitted BEFORE the enclosing `ToolEnd` event; zero bytes of rejected content in the event payload. Non-Critical severity allows run continuation. Verified by `test_BC_2_11_002_fail_injects_error_block()`.

### AC-008 (traces to BC-2.11.002 PC-004 — Transform forwards replacement and emits GuardrailDecision)
`GuardrailResult::Transform { new_content }` → `new_content` forwarded; original discarded; `StreamEvent::GuardrailDecision { decision: Transform, reason: None, severity: None, .. }` emitted BEFORE `ToolEnd`. Verified by `test_BC_2_11_002_transform_forwards_new_content()`.

### AC-009 (traces to BC-2.11.002 INV-002 — hook fires after ProvenanceTag attachment)
The execution order is: `ProvenanceTag` attached first, then `GuardrailHook::evaluate` called, then model context insertion. This order is non-negotiable. Verified by `test_BC_2_11_002_provenance_tag_attached_before_hook()`.

### AC-010 (traces to BC-2.11.003 PC-001 — evaluate called for every RAG chunk)
When a hook is registered and RAG retrieval returns N chunks, `evaluate(IngressContent::RagChunk(Value), provenance_tag)` is called exactly N times — once per chunk. Verified by `test_BC_2_11_003_evaluate_called_n_times_for_n_chunks()`.

### AC-011 (traces to BC-2.11.003 PC-005 — failed RAG chunk gets error block, passing chunks proceed)
A non-Critical `Fail` on chunk K does not block chunks 0..K-1 and K+1..N-1 that already passed. Each chunk's decision is independent. Verified by `test_BC_2_11_003_partial_chunk_fail_does_not_block_others()`.

### AC-012 (traces to BC-2.11.003 INV-004 — independent chunk evaluation)
One chunk's `Fail` result does not cause adjacent chunks in the same retrieval call to skip evaluation. All N chunks are evaluated regardless of any `Fail` results (except `Critical` which halts the run). Verified by `test_BC_2_11_003_all_chunks_independently_evaluated()`.

### AC-013 (traces to BC-2.11.003 PC-003 — GuardrailDecision emitted within NodeStart/NodeEnd window)
`StreamEvent::GuardrailDecision` for RAG/memory boundaries is emitted within the enclosing `NodeStart`/`NodeEnd` event window (not within `ToolStart`/`ToolEnd`). Verified by `test_BC_2_11_003_guardrail_decision_in_node_window()`.

### AC-014 (traces to BC-2.11.004 PC-001 — evaluate called for every memory item)
When a hook is registered and memory read returns M items, `evaluate(IngressContent::MemoryItem(Value), provenance_tag)` is called for every item before it enters model context. Verified by `test_BC_2_11_004_evaluate_called_for_memory_items()`.

### AC-015 (traces to BC-2.11.004 INV-001 — guardrail fires at retrieval time not storage time)
The guardrail fires when a memory item is retrieved and about to be injected into model context — not when it was originally stored. An item stored without a hook present is still evaluated when retrieved if a hook is now registered. Verified by `test_BC_2_11_004_guardrail_fires_at_retrieval_not_storage()`.

### AC-016 (traces to BC-2.11.004 INV-003 — memory items not destined for model context skip guardrail)
Memory items retrieved for internal routing decisions (not injected into model context) do not trigger `GuardrailHook::evaluate`. The ingress boundary is the model-context-injection boundary. Verified by `test_BC_2_11_004_non_context_memory_skips_guardrail()`.

### AC-017 (traces to BC-2.11.005 PC-001 — zero bytes of rejected content in model input buffer)
When `GuardrailResult::Fail` is returned, the model input buffer immediately before the next inference call contains zero bytes of the rejected content's original data — including in streaming surface events. Verified by `test_BC_2_11_005_zero_rejected_bytes_in_model_buffer()`.

### AC-018 (traces to BC-2.11.005 INV-001 — rejection is atomic)
There is no execution window between `GuardrailResult::Fail` return and the model input buffer being finalized in which rejected content could enter. The rejection and buffer finalization are a single synchronous operation. Verified by `test_BC_2_11_005_rejection_is_atomic()`.

### AC-019 (traces to BC-2.11.005 INV-004 — parallel hook composition fails-closed)
When two `GuardrailHook` instances are composed and run in parallel, if ANY hook returns `Fail`, the content is treated as rejected. `Fail` always wins over `Pass` in parallel composition. Verified by `test_BC_2_11_005_parallel_hook_fails_closed()`.

### AC-020 (traces to BC-2.11.005 PC-004 — Critical Fail halts run; non-Critical continues)
`GuardrailResult::Fail { severity: Critical }` → run transitions to `failed`; no further nodes execute; model inference not called. Non-Critical severity (`High`, `Medium`, `Low`) → error block substituted; run continues. Verified by `test_BC_2_11_005_critical_fail_halts_run()`.

### AC-021 (traces to BC-2.11.006 PC-001 — content forwarded unchanged when no hook registered)
When no `GuardrailHook` is registered, every content unit at every ingress boundary is forwarded to model context without modification. Verified by `test_BC_2_11_006_content_forwarded_no_hook()`.

### AC-022 (traces to BC-2.11.006 PC-002 — WARN log emitted once per boundary crossing)
When no hook is registered, exactly one `WARN`-level structured log entry with `event_type = "guardrail.unregistered_passthrough"` and required fields `{ boundary_type, ingress_id, item_count, timestamp }` is emitted per ingress boundary crossing event. For MCP `ToolResult` boundaries, optional fields `server_name` and `tool_name` are additionally included. Verified by `test_BC_2_11_006_warn_emitted_once_per_crossing()`.

### AC-023 (traces to BC-2.11.006 INV-002 — WARN log is machine-parseable)
The `WARN` log entry uses canonical `event_type = "guardrail.unregistered_passthrough"` with structured fields, enabling automated alerting. The log entry is emitted via `tracing::warn!` not `eprintln!`. Verified by `test_BC_2_11_006_warn_log_is_machine_parseable()`.

### AC-024 (traces to BC-2.11.002 INV-005 — SEC-008 panic-profile build obligation)
**Build-profile prerequisite (SEC-008) — `panic = "unwind"` required in the workspace-root release profile (pregolya-server binary):**
The workspace-root `Cargo.toml` release profile MUST pin `panic = "unwind"`. This is the
authoritative and ONLY effective setting — Cargo honors `[profile.release] panic` ONLY at the
workspace root, applying it to the final binary at link time. A library-member profile override
(e.g., a `[profile.release] panic = "unwind"` line inside `pregolya-graph/Cargo.toml` itself)
is silently ignored by the Cargo linker and MUST NOT be relied upon as the SEC-008 gate.
The `catch_unwind` boundary lives in `pregolya-graph/src/provenance.rs`, executed within the
`pregolya-server` binary — it is the `pregolya-server` binary's workspace-root profile setting
that determines the effective panic mode at runtime. If the workspace-root release profile sets
`panic = "abort"`, `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(content, tag)))` in
`pregolya-graph/src/provenance.rs` is voided — the process aborts on panic instead of unwinding,
bypassing the fail-closed catch and exposing a remote denial-of-service (CWE-248/703). This is a
Phase-3 devops-engineer obligation (workspace-root `Cargo.toml` authoring; assert on the
`pregolya-server` binary profile, NOT the `pregolya-graph` library-member profile). The
pregolya-graph story-level obligation: the implementing engineer MUST add a
`// SEC-008: panic = "unwind" required in workspace-root release profile (pregolya-server) — library-member (pregolya-graph) profile override is inert (silently ignored by Cargo); FutureExt::catch_unwind voids under abort`
comment at the `FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(content, tag)))` dispatch site
in `pregolya-graph/src/provenance.rs` to document the workspace-root `panic = "unwind"` dependency
of the ingress fail-closed catch. The devops-engineer asserts the workspace-root release profile at
Phase-3 workspace init. Verified by devops-engineer at Phase-3; implementer obligation is the
comment annotation. (See EC-001 for the `catch_unwind` mechanism; see S-2.11 AC-037 for the analogous SEC-008 obligation on the `GraphAgentTool` path.)

### AC-025 (traces to BC-2.11.002 INV-005 + EC-001 — Red Gate, SEC-008 async-catch mechanism)
**Red Gate / SEC-008 async-catch mechanism:** When `GuardrailHook::evaluate` panics DURING
`.await` polling, the panic MUST be caught via
`futures::future::FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(content, tag))).await`
at the dispatch site in `pregolya-graph/src/provenance.rs`. A caught panic causes content to
be treated as `Fail` (fail-closed) and `Err(PregolyaError { code: "E-CORE-007", .. })` is
propagated. The Red Gate test `test_BC_2_11_002_hook_panic_caught_fail_closed_e_core_007()` MUST
drive the panic through `.await` polling — a synchronous `std::panic::catch_unwind` substitute
MUST NOT satisfy this criterion (it cannot intercept panics that fire during `.await` execution;
CWE-248/703). Verified by `test_BC_2_11_002_hook_panic_caught_fail_closed_e_core_007()` (mock
`GuardrailHook` implementation whose `evaluate` future panics mid-poll via
`std::future::poll_fn`; assert `Err(PregolyaError { code: "E-CORE-007", .. })` is returned and
zero bytes of the original content appear in any downstream buffer). (Mirrors S-2.11 AC-033 for
the analogous `GraphAgentTool::invoke_dyn` path.)

### AC-026 (traces to BC-2.11.001–006 {PRE-001} — InvocationContext module creation, F-P2A207-02)
**Create `core::invocation_context`:** `pregolya-core/src/invocation_context.rs` MUST be created
with the `InvocationContext` struct and its full API surface as defined in
`interface-definitions.md §InvocationContext`. The canonical implementation:
```rust
pub struct InvocationContext {
    guardrail_hook: Option<Arc<dyn GuardrailHook>>,
}

impl InvocationContext {
    pub fn new() -> Self { Self { guardrail_hook: None } }
    pub fn register_guardrail(&mut self, hook: Arc<dyn GuardrailHook>) {
        self.guardrail_hook = Some(hook);
    }
    pub fn guardrail_hook(&self) -> Option<&Arc<dyn GuardrailHook>> {
        self.guardrail_hook.as_ref()
    }
}

impl Default for InvocationContext {
    fn default() -> Self { Self::new() }
}
```
`InvocationContext` is a **definitions-only** struct living in `pregolya-core` (SS-11 owner;
canonical home `core::invocation_context`). It carries the per-run hook registry. All BC-2.11.001–006
preconditions require `InvocationContext` ({PRE-001}: "caller-constructed `InvocationContext`
with the hook registered") before any guardrail boundary enforcement can proceed. Without this
struct, none of the behaviors in BC-2.11.001–006 are reachable. Cross-subsystem note: this type
also satisfies the `InvocationContext` precondition for `mcp::ingress` (see
interface-definitions.md §InvocationContext). Verified by
`test_invocation_context_register_and_query_guardrail_hook()` (register a mock `GuardrailHook`
via `register_guardrail`; assert `guardrail_hook()` returns `Some`; construct default and assert
`guardrail_hook()` returns `None`).

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|---------------|
| `GuardrailHook` trait, `GuardrailResult`, `IngressContent`, `GuardrailSeverity` | `pregolya-core/src/guardrail.rs` | Pure (definitions only) |
| `ProvenanceTag`, `BoundaryType` | `pregolya-core/src/guardrail.rs` | Pure (data types) |
| Ingress dispatch + tag attachment | `pregolya-graph/src/provenance.rs` | Effectful (calls hook, calls model context insert) |
| Atomic rejection enforcement | `pregolya-graph/src/provenance.rs` | Effectful (model buffer management) |
| WARN emission (no-hook path) | `pregolya-graph/src/provenance.rs` | Effectful (tracing::warn!) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-core/src/guardrail.rs` (trait + types) | pure-core | Definitions only; no execution logic per ADR-014 Decision 6 |
| `pregolya-graph/src/provenance.rs` (dispatch) | effectful-shell | Calls `GuardrailHook::evaluate` (async trait method), writes to model input buffer, emits `StreamEvent` |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | `GuardrailHook::evaluate` panics during async dispatch | Caught via `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(content, tag))).await` at dispatch site in `provenance.rs` — synchronous `std::panic::catch_unwind` is INADEQUATE (cannot catch panics fired during `.await` polling; BC-2.11.002 {INV-005}/EC-001 / CWE-248/703). Content treated as `Fail` (fail-closed); `Err(PregolyaError { code: "E-CORE-007", .. })` propagated. Recovery requires `panic = "unwind"` in the workspace-root release profile (pregolya-server binary) — a library-member (pregolya-graph) `[profile.release]` override is silently ignored by Cargo and MUST NOT be relied upon (AC-024 / SEC-008). (SS-09 sibling: ADR-029 §Decision 5) |
| EC-002 | Multiple `ContentBlock`s in one `ToolMessage` | Each evaluated independently; single `Fail` does not block others unless `Critical` |
| EC-003 | Zero-item RAG result | No `evaluate` calls; no `WARN` emitted; empty result forwarded |
| EC-004 | Two parallel hooks: one `Pass`, one `Fail` | `Fail` wins (fail-closed); content rejected |
| EC-005 | `GuardrailResult::Transform` changes `ContentBlock` variant within same `IngressContent` boundary | Accepted; same-boundary rule: `ToolResult(ContentBlock)` in → `ToolResult(ContentBlock)` out |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~6,000 |
| BC files (6 BCs) | ~9,000 |
| S-1.14 context (BSP engine, model context) | ~1,500 |
| S-1.17 context (StreamEvent for GuardrailDecision) | ~1,000 |
| `pregolya-core/src/guardrail.rs` | ~1,200 |
| `pregolya-core/src/invocation_context.rs` (new; AC-026) | ~800 |
| `pregolya-graph/src/provenance.rs` | ~2,000 |
| Test files | ~4,500 |
| Interface-definitions.md (GuardrailHook + InvocationContext sections) | ~1,200 |
| **Total** | **~27,200** |
| Agent context window | ~200K (Sonnet) |
| **Budget usage** | **~12.85%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-017..AC-020 (fail-closed, atomic rejection) FIRST — security-critical
2. [ ] Write remaining failing tests for AC-001..AC-016, AC-021..AC-023
3. [ ] Create `pregolya-core/src/guardrail.rs` — `GuardrailHook` trait, `GuardrailResult`, `IngressContent`, `GuardrailSeverity`, `ProvenanceTag`, `BoundaryType`
4. [ ] Create `pregolya-graph/src/provenance.rs` — `ProvenanceTag` attachment at all 3 boundaries; `GuardrailHook` dispatch; atomic rejection; parallel hook composition
5. [ ] Implement fail-closed panic catch in `provenance.rs` dispatch: `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(content, tag))).await` — synchronous `std::panic::catch_unwind` is INADEQUATE for async callees (cannot catch panics fired during `.await` polling; BC-2.11.002 {INV-005}/EC-001 / CWE-248/703). Map caught panic → `GuardrailResult::Fail { .. }` + `Err(PregolyaError { code: "E-CORE-007", .. })`. NOTE: recovery requires `panic = "unwind"` in the workspace-root release profile (pregolya-server binary) — a library-member (pregolya-graph) `[profile.release]` override is silently ignored by Cargo and MUST NOT be relied upon; devops-engineer asserts the workspace-root `Cargo.toml` profile at Phase-3 init (AC-024 / SEC-008). (SS-09 sibling: ADR-029 §Decision 5)
6. [ ] Implement no-hook WARN log: `tracing::warn!(event_type = "guardrail.unregistered_passthrough", ...)`
7. [ ] Wire `GuardrailDecision` stream event emission in `provenance.rs` (before `ToolEnd` / within `NodeStart-NodeEnd` window)
8. [ ] Register `guardrail.unregistered_passthrough` in Canonical Structured Event Catalog (SAP-1)
9. [ ] Export from `pregolya-core/src/lib.rs` and `pregolya-graph/src/lib.rs`
10. [ ] Run `cargo nextest run -p pregolya-graph -p pregolya-core --no-fail-fast` — all tests green
11. [ ] Add SEC-008 comment annotation at the `FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(content, tag))).await` dispatch site in `pregolya-graph/src/provenance.rs`: `// SEC-008: panic = "unwind" required in workspace-root release profile (pregolya-server) — library-member (pregolya-graph) profile override is inert (silently ignored by Cargo); FutureExt::catch_unwind voids under abort; devops-engineer asserts workspace-root Cargo.toml profile at Phase-3 init` (AC-024 / BC-2.11.002 INV-005)
12. [ ] Create `pregolya-core/src/invocation_context.rs` — `InvocationContext` struct with `guardrail_hook: Option<Arc<dyn GuardrailHook>>` field; `new()` constructor; `register_guardrail(&mut self, hook: Arc<dyn GuardrailHook>)` method (sets the slot); `guardrail_hook(&self) -> Option<&Arc<dyn GuardrailHook>>` accessor (queries the slot); `impl Default` returning `Self::new()`. Modify `pregolya-core/src/lib.rs` to re-export `InvocationContext`. Verified by `test_invocation_context_register_and_query_guardrail_hook()` (AC-026 / BC-2.11.001–006 {PRE-001})

## Previous Story Intelligence (MANDATORY)

| Story | Key Decisions | Patterns Established | Gotchas Discovered |
|-------|--------------|---------------------|-------------------|
| S-1.14 | BSP engine orchestrates node execution | Model input buffer is assembled in `bsp_engine.rs` | ProvenanceTag must be attached BEFORE any code passes content to `bsp_engine.rs` for model context assembly |
| S-1.17 | `StreamEvent::GuardrailDecision` variant defined | `GuardrailDecision` for `ToolResult` is emitted BEFORE `ToolEnd`; for RAG/Memory within `NodeStart/NodeEnd` | Streaming event window distinction: ToolResult uses ToolStart/ToolEnd window; RAG/Memory use NodeStart/NodeEnd |
| S-1.04 | `PregolyaError` with `E-CORE-007` (GuardrailHookPanic) | Fail-closed panic handling uses `futures::future::FutureExt::catch_unwind(AssertUnwindSafe(hook.evaluate(...)))` — NOT synchronous `std::panic::catch_unwind` (async callees require the async-capable form; BC-2.11.002 {INV-005}/EC-001 / CWE-248/703); `E-CORE-007` propagated on catch. (SS-09 sibling: ADR-029 §Decision 5) | `E-CORE-007` context-sourced fields: `boundary` from `provenance_tag.boundary_type`; `content_type` = bare variant name from `IngressContent` discriminant |

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `GuardrailHook` trait and all types defined in `pregolya-core` — no execution logic | BC-2.11.001 architecture anchors; ADR-014 Decision 6 | Import path check: `pregolya-graph` imports types from `pregolya-core::guardrail` |
| `ProvenanceTag` attached BEFORE `evaluate` — ordering is non-negotiable | BC-2.11.002 INV-002 | Integration test: hook receives non-None provenance_tag |
| No `ContentBlock` enters model buffer without `evaluate` call (when hook registered) | BC-2.11.002 INV-001 | Integration test VP-2.11.002-A pattern |
| Rejected content must be zero bytes in model input buffer — no partial insertion | BC-2.11.005 INV-001 | Unit test: assert buffer does not contain rejected content |
| Parallel hook fails-closed: any `Fail` wins | BC-2.11.005 INV-004 | Unit test: two hooks, one Fail → content rejected |
| `WARN` log uses `tracing::warn!` not `eprintln!` | CLAUDE.md §No println! in library crates | `cargo clippy`; no `eprintln!` in production code |
| `GuardrailSeverity` and `IngressContent` carry `#[non_exhaustive]` | CLAUDE.md §`#[non_exhaustive]` | Non-exhaustive gate crate; wildcard arm required |
| `guardrail.unregistered_passthrough` event_type in Canonical Structured Event Catalog | CLAUDE.md §Structured event catalog discipline (SAP-1) | Adversary SAP-1 probe |

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `uuid` | workspace-pinned | `ingress_id` generation in `ProvenanceTag` |
| `serde_json` | workspace-pinned | `IngressContent::RagChunk(Value)` and `MemoryItem(Value)` payloads |
| `tokio` | workspace-pinned | Async `GuardrailHook::evaluate` dispatch |
| `tracing` | workspace-pinned | `WARN` log + structured event emission |
| `futures` | workspace-pinned | `FutureExt::catch_unwind(AssertUnwindSafe(...))` for async-safe panic recovery in `provenance.rs` dispatch (EC-001; BC-2.11.002 {INV-005}) |

**Forbidden Dependencies:** `pregolya-core/src/guardrail.rs` must NOT import from `pregolya-graph`. Dependency direction: `pregolya-graph` → `pregolya-core`.

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-core/src/guardrail.rs` | create | `GuardrailHook` trait, `GuardrailResult`, `IngressContent`, `GuardrailSeverity`, `ProvenanceTag`, `BoundaryType` |
| `pregolya-core/src/invocation_context.rs` | create | `InvocationContext` struct — `guardrail_hook: Option<Arc<dyn GuardrailHook>>` field; `new()`, `register_guardrail()`, `guardrail_hook()` methods; `Default` impl; definitions-only, no execution logic (AC-026; BC-2.11.001–006 {PRE-001}) |
| `pregolya-core/src/lib.rs` | modify | Re-export guardrail types and `InvocationContext` |
| `pregolya-graph/src/provenance.rs` | create | ProvenanceTag attachment; hook dispatch; atomic rejection; no-hook WARN path |
| `pregolya-graph/src/lib.rs` | modify | Re-export provenance types |
| `pregolya-graph/tests/guardrail_ingress.rs` | create | AC-001..AC-023 tests |

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 1.10 | 2026-09-02 | round-79/F-P2A251-02: BC table title cells corrected to verbatim canonical H1 per POL-7/F-P2A251-02. | round-79 F-P2A251-02 |
