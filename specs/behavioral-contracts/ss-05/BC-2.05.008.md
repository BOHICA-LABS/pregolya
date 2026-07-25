---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.008
version: "1.2"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-05
capability: CAP-034
crate: ferrochain-graph
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-22T00:00:00Z
di_anchors: [DI-014]
vp_seed: false
red_gate: false
changelog:
  - "1.0 (D23/2026-07-22): Initial BC — D23 per-tool-call approval hook, SS-05 skip-hook-on-resume invariant."
  - "1.1 (2026-07-22, F-P139-07, burst-239): (a) Related BCs: 'BC-2.05.007 PC-1 through PC-4 applied on resume' corrected to 'PC-1 through PC-3' — PC-4 is PendingHumanApproval, the trigger path that issued the interrupt, and is never a valid resume decision delivered by the caller. (b) EC-006 added: explicit behavior when Command::Resume(PendingHumanApproval { .. }) is delivered — invalid payload, returns Err per BC-2.05.004 contract."
  - "1.2 (F-P142-03, burst-242, 2026-07-23): Sweep Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form per BC-2.05.004 authority and F-P120-01 adjudication. H1 title, Description, PC-1/2/3, Invariants, EC-001/004/006, TV-001/002/003, Related BCs, Traceability updated. Zero Command:: enum-variant residue remains in live body text."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-034
  - architecture/decisions/ADR-018-per-tool-call-approval-hook.md
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-018-per-tool-call-approval-hook.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "60290b6"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.008: Skip-Hook-on-Resume Invariant — ToolApprovalRequest Checkpoint Persistence; Command(resume=PreToolDecision); No Re-Invocation of pre_invoke

## Description

When `BC-2.05.007`'s `PendingHumanApproval` path is triggered, the engine serializes a
`ToolApprovalRequest { preview: ToolCallPreview, prompt: Option<String> }` into the
checkpoint (BC-2.05.001 interrupt machinery) and suspends the run. On resume, the caller
delivers `Command(resume=PreToolDecision)`. The engine applies the delivered `PreToolDecision`
directly via the `BC-2.05.007` PC-1/PC-2/PC-3 routing rules — without re-calling
`hook.pre_invoke`. This "skip-hook-on-resume" invariant is the key behavioral difference
between `PendingHumanApproval` resumes and normal node re-execution (BC-2.05.003): the hook
is not re-queried on the resumed dispatch because the human has already delivered the
decision out-of-band.

## Preconditions

1. A `PreToolCallHook` returned `PendingHumanApproval { prompt }` for tool dispatch of
   tool `T` with args `A`.
2. The engine has issued `interrupt(ToolApprovalRequest { preview: ToolCallPreview { tool_name:
   T.name(), tool_args: A, action_risk: T.action_risk() }, prompt })` via BC-2.05.001 machinery.
3. A `ToolApprovalRequest` record is durably persisted in the checkpoint (same durability
   guarantees as any interrupt payload — BC-2.04.002 msgpack wire format).
4. The run is in `interrupted` state with the `ToolApprovalRequest` as the pending interrupt
   payload.

## Postconditions

1. **Resume with Approve:** `Command(resume=PreToolDecision::Approve)` delivered. The engine
   proceeds to `tool.invoke(A)` with the original args from the checkpoint. `hook.pre_invoke`
   is NOT called again.
2. **Resume with Deny:** `Command(resume=PreToolDecision::Deny { reason })`. The engine
   applies Deny routing (BC-2.05.007 PC-2): `ToolOutput::Error(reason)` constructed without
   invoking the tool. `hook.pre_invoke` is NOT called again.
3. **Resume with Edit:** `Command(resume=PreToolDecision::Edit { modified_args })`. The engine
   validates `modified_args` (JSON object check) then proceeds to `tool.invoke(modified_args)`.
   `hook.pre_invoke` is NOT called again.
4. **Process restart before resume:** The `ToolApprovalRequest` is persisted in the checkpoint
   via msgpack (BC-2.04.002). After process restart, loading the checkpoint restores the
   pending interrupt; the resume path is available as in PC-1/PC-2/PC-3.
5. **FIFO ordering:** The `ToolApprovalRequest` interrupt follows BC-2.05.002 FIFO semantics
   — if multiple interrupts are pending, this approval interrupt is delivered in the order
   it was created.

## Invariants

- **Skip-hook-on-resume:** `hook.pre_invoke` is called exactly ONCE per tool dispatch attempt.
  When `PendingHumanApproval` is raised, the hook is NOT re-called on the resumed dispatch.
  The human's decision (delivered via `Command(resume=…)`) IS the hook decision for that
  dispatch attempt.
- **ToolApprovalRequest durability:** The payload must be serializable to msgpack and
  survive process restart. `ToolCallPreview` is msgpack-compatible (no closures, no
  non-serializable types). This is a consequence of reusing BC-2.05.001 interrupt machinery.
- This invariant is DISTINCT from BC-2.05.003 (node re-execute from start): node re-execution
  re-runs node logic including any calls to `interrupt()`; it does NOT re-call `pre_invoke`
  for a tool dispatch that was already at the `PendingHumanApproval` stage. The resume
  delivers the decision directly.
- **DI-014 (No Silent Swallowing):** The resume decision is always applied; it is never
  silently ignored. An invalid `Command(resume=…)` payload returns `Err` to the caller
  (BC-2.05.004 semantics).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Resume with Approve after process restart | Engine loads checkpoint; ToolApprovalRequest present; `Command(resume=Approve)` applies Approve; tool invoked with original args from checkpoint |
| EC-002 | Resume with Deny after process restart | ToolOutput::Error(reason) returned; tool NOT invoked; original args discarded |
| EC-003 | Resume with Edit after process restart | modified_args validated; if valid, tool invoked with modified_args; if invalid, Deny fallback |
| EC-004 | Multiple PendingHumanApproval interrupts queued (N sequential tool calls each needing approval) | FIFO: first ToolApprovalRequest resumed first; N separate Command(resume=…) deliveries required; hook not re-called for any |
| EC-005 | A second tool invocation during the node's re-execution after the first approval is resumed | The second tool invocation goes through pre_tool_dispatch (BC-2.05.007) normally — pre_invoke is called for the SECOND dispatch (only skipped for the specific dispatch that was in PendingHumanApproval) |
| EC-006 | `Command(resume=PreToolDecision::PendingHumanApproval { .. })` delivered as the resume payload | `PendingHumanApproval` is a hook RETURN value that triggers interrupt issuance (BC-2.05.007 PC-4); it is not a valid decision payload for `Command(resume=…)`. The engine returns `Err(FerrochainError)` per BC-2.05.004 invalid-payload contract. No tool invocation, no state mutation, run remains in `interrupted` state. |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | Tool T at PendingHumanApproval; `Command(resume=Approve)` delivered | T.invoke(original_args) called; pre_invoke NOT re-called | happy-path (approve resume) |
| TV-002 | Tool T at PendingHumanApproval; process restart; checkpoint reload; `Command(resume=Approve)` | Same as TV-001 — checkpoint restores ToolApprovalRequest; tool invoked with original args | process-restart durability |
| TV-003 | Tool T at PendingHumanApproval; `Command(resume=Deny { reason: "user rejected" })` | `ToolOutput::Error("user rejected")` — tool NOT invoked | deny-on-resume |
| TV-004 | Tool T1 at PendingHumanApproval; Tool T2 also queued | T1 resume processed first (FIFO); T2 approve-or-deny processed second | FIFO ordering |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.05.008-A | hook.pre_invoke called exactly once per tool dispatch (not again on resume) | Unit test: hook that counts pre_invoke calls; assert count == 1 after full cycle through PendingHumanApproval + resume |
| VP-2.05.008-B | ToolApprovalRequest survives process restart (msgpack round-trip) | Unit test: serialize ToolApprovalRequest → msgpack → deserialize; assert fields equal |
| VP-2.05.008-C | FIFO: two PendingHumanApproval interrupts resolved in creation order | Integration test: assert first resume applies to first queued approval |

## Related BCs

- BC-2.05.001 — depends on: interrupt() machinery (suspension + checkpoint persistence) reused for ToolApprovalRequest
- BC-2.05.002 — depends on: FIFO delivery of ToolApprovalRequest interrupts
- BC-2.05.003 — related to: node re-execute is a DIFFERENT mechanism; this BC specifies skip-hook-on-resume which differs from node re-execute semantics
- BC-2.05.004 — depends on: Command(resume=PreToolDecision) is the programmatic resume API
- BC-2.05.007 — depends on: pre_tool_dispatch dispatch rules PC-1 through PC-3 applied on resume; PC-4 (PendingHumanApproval) is the hook RETURN value that triggered the interrupt and is NOT a valid resume decision payload
- BC-2.06.004 — related to: tool_approval_request streaming event emitted when PendingHumanApproval issued
- BC-2.06.005 — related to: tool_approval_resolved streaming event emitted when Command(resume=…) arrives

## Architecture Anchors

- `architecture/decisions/ADR-018-per-tool-call-approval-hook.md` — Decision 3 step 6 ("On resume semantics: hook is skipped for the resumed dispatch"), Decision 4 (PendingHumanApproval reuses interrupt() machinery; ToolApprovalRequest serialized to msgpack via ADR-002)
- `architecture/module-decomposition.md` — SS-05, `ferrochain-graph / hitl` and `graph::scheduler` modules

## Story Anchor

_[to be filled after story decomposition — Wave 1 SS-05 extension story]_

## VP Anchors

- VP-2.05.008-A
- VP-2.05.008-B
- VP-2.05.008-C

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-034 |
| Capability Anchor Justification | CAP-034 ("Per-Tool-Call Interactive Approval Hook (PreToolCallHook / PreToolDecision)") per capabilities-p1-p2.md §CAP-034 — this BC specifies the "skip-hook-on-resume" invariant explicitly called out in ADR-018 Decision 3 as a PO BC obligation; it governs the PendingHumanApproval suspend-and-resume path that is a core part of the pre-tool-call approval hook surface defined in CAP-034 |
| L2 Domain Invariants | DI-014 (Error Propagation — resume decision always applied; invalid Command(resume=…) payload returns Err per BC-2.05.004) |
| Architecture Authority | ADR-018 Decisions 3 (skip-hook-on-resume) and 4 (ToolApprovalRequest checkpoint durability, msgpack serialization) |
| Binding Decisions | D23 (per-tool-call approval hook mandate, SS-05 extension) |
| VP Registration | VP-2.05.008-A/B/C (unit/integration tests) |
| Module | ferrochain-graph / hitl + scheduler |
| Priority | P1 |
| Wave | 1 |
| Test Types | unit + integration |
