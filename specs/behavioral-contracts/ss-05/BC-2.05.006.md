---
document_type: behavioral-contract
level: L3
bc_id: BC-2.05.006
version: "1.4"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.1 (ADV-P1D-PASS-27): F-P27-06 Architecture Anchor renamed risk_tier.rs → action_risk.rs for consistency with the action_risk wire-field canon (retired-identifier gate #19)."
  - "1.2 (pass-45): F-P45-02 — corrected BC-2.10.004 relationship in Related BCs: budget escalation reuses base interrupt mechanism (BC-2.05.001) with BudgetEscalation payload and BudgetResume::Extend|Halt resume; it is NOT a risk-tiered High interrupt and is NOT subject to RiskGatePolicy or High-tier approver gating."
  - "1.3 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-graph / ferrochain-server per module-decomposition.md v1.10."
  - "1.4 (F-P110-CENSUS, 2026-07-18): Fix EC-005 E-GRAPH-014 InterruptApprovalTimeout struct — 2-field form `{ tier, deadline_utc }` missing `run_id`. Taxonomy message format `interrupt for run '<run_id>' (tier '<tier>') expired at deadline '<deadline_utc>'` has 3 distinct placeholders; struct must be a SUPERSET of all taxonomy placeholders (gate #33 Step B check 2). Added `run_id: \"<run_id>\"` as first field. TD-VSDD-060 sweep: only one E-GRAPH-014 struct site in this file (EC-005 line ~148); TV-006 uses bare-variant form (no struct fields — not subject to parity check)."
origin: greenfield
priority: P0
subsystem: SS-05
capability: CAP-006
wave: 1
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
traces_to:
  - domain-spec/capabilities-p0.md#CAP-006
  - domain-spec/invariants.md#DI-003
  - domain-spec/assumptions.md#ASM-008
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/assumptions.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
input-hash: "77d7827"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.05.006: Risk-Tiered Interrupt Classification (Typed Action-Risk Levels for Domain A SOC)

## Description

`interrupt()` values may carry a typed `ActionRisk` level — `ReadOnly`, `Low`, `Medium`,
or `High` — that classifies the risk of the action awaiting human authorization. The
`interrupt` payload shape includes this tier, the specific `action` being requested, and
optional `context`. A `High`-tier interrupt must durably park the run until a senior
approver delivers `Command(resume=...)`. A `ReadOnly`-tier interrupt may be configured
to auto-approve (no human gate required). This BC is an extension of CAP-006 per OQR-1:
the interrupt mechanism is unchanged; risk tiers are a BC-level typing of interrupt
payload within the same HITL subsystem. The contract is motivated by ASM-008 (Domain A
SOC analyst forcing function: tiered autonomy with human approval before containment).

## Preconditions

1. A node constructs an `HitlInterruptPayload { action_risk: ActionRisk, action: String,
   context: Option<Value> }` and passes it to `interrupt(payload)`.
2. The graph run has a `CheckpointSaver` attached (BC-2.05.001 precondition).
3. The `ActionRisk` value is one of the four defined tiers: `ReadOnly`, `Low`, `Medium`,
   `High`. Any other value is a type error at compile time (the type is an exhaustive
   enum with no wildcard variant).
4. If a `RiskGatePolicy` is configured on the graph (optional), it specifies per-tier
   behavior: `AutoApprove`, `RequireApprover(role: ApproverRole)`, or
   `RequireApprover(role: ApproverRole) + timeout(Duration)`.

## Postconditions

1. **ReadOnly tier:** If `RiskGatePolicy` configures `AutoApprove` for `ReadOnly`,
   `interrupt()` returns an implicit `Command(resume=ReadOnlyAutoApproved)` without
   surfacing to a human; the node continues without waiting. If no policy is set, behavior
   defaults to `RequireApprover(Any)` — i.e., a human may approve.
2. **Low tier:** `RiskGatePolicy` defaults to `RequireApprover(Any)`. The interrupt halts
   the run and surfaces the payload to any registered approver. Any valid `Command(resume=...)`
   unblocks the run.
3. **Medium tier:** `RiskGatePolicy` defaults to `RequireApprover(Analyst)` (a named
   approver role). The interrupt payload carries `action_risk: Medium`. Only a `Command`
   submitted with a token that satisfies the `Analyst` role constraint is accepted; a
   `Command` from an unauthenticated or lower-privilege caller returns
   `Err(E-GRAPH-013 InsufficientApproverRole)`.
4. **High tier:** `RiskGatePolicy` defaults to `RequireApprover(SeniorAnalyst)`. Only a
   `Command` satisfying `SeniorAnalyst` role is accepted. The run durably parks until
   such approval is received; there is no timeout-based auto-expiry unless the policy
   explicitly configures one.
5. The interrupt payload is persisted to the checkpoint exactly as the `interrupt()` call
   in BC-2.05.001 specifies; the `action_risk` field is serialized in msgpack alongside
   the `action` and `context` fields.
6. The surfaced interrupt notification includes the full `HitlInterruptPayload` so the
   caller (or UI) can render the appropriate approval UI for the risk tier.

## Invariants

- **DI-003 (HITL FIFO Resume-Value Delivery):** Risk-tiered interrupts are FIFO with
  respect to other interrupts in the same task scratchpad. Tier classification does not
  change delivery order; it only governs who is authorized to deliver the resume value.
- `ActionRisk` is a closed, exhaustive enum; no runtime tier value outside the four
  defined variants is possible.
- A `High`-tier interrupt MUST NOT be auto-approved by any `RiskGatePolicy` unless a
  `SeniorAnalyst`-or-higher role supplies the `Command(resume=...)`. Automated approval
  of `High`-tier actions is a hard policy violation (returns
  `Err(E-GRAPH-013 InsufficientApproverRole)` even if the policy mistakenly attempts it).
- The risk tier classification does not affect the core HITL mechanics (scratchpad, FIFO,
  re-execute from start). It adds a role-authorization layer on top of the existing
  interrupt mechanism.
- **ASM-008 design invariant:** A single boolean interrupt is insufficient for Domain A.
  The four-tier typing exists precisely because SOC workflows require differentiated
  authorization levels — triage enrichment (ReadOnly), alert closure (Low), credential
  suspension (Medium), host isolation or account lockout (High).

## Edge Cases

### EC-001: High-tier interrupt without a SeniorAnalyst approver submitting Command
**Scenario:** Node interrupts with `action_risk: High, action: "isolate_host_prod_db"`.
An `Analyst`-role caller submits `Command(resume="approved")`.
**Expected behavior:** `Err(E-GRAPH-013 InsufficientApproverRole { required: SeniorAnalyst,
provided: Analyst })`. Run remains parked; the High-tier interrupt is not consumed. The
SOC manager must submit `Command(resume="approved")` with a `SeniorAnalyst` credential.

### EC-002: ReadOnly auto-approve policy
**Scenario:** `RiskGatePolicy { ReadOnly: AutoApprove }` is configured. Node calls
`interrupt(HitlInterruptPayload { action_risk: ReadOnly, action: "query_siem_logs", ... })`.
**Expected behavior:** The interrupt returns `ReadOnlyAutoApproved` immediately without
surfacing to a human. The node continues; no external `Command(resume=...)` is required.
This models "triage enrichment" operations in Domain A SOC workflows.

### EC-003: Stacked interrupts with mixed risk tiers
**Scenario:** Node calls `interrupt(ActionRisk::Medium, "suspend_credential")` then
`interrupt(ActionRisk::High, "isolate_host")`. Two separate `Command(resume=...)` calls
required.
**Expected behavior:** First `Command` must satisfy `Analyst` role (Medium tier); returns
resume value for slot 0. Node re-executes; first interrupt returns value; second interrupt
raises again, requiring `SeniorAnalyst` approval. FIFO order is preserved; role-checking
is per-slot.

### EC-004: Unknown or missing action_risk field in legacy payload
**Scenario:** A resume value arrives from an older client that does not set `action_risk`.
**Expected behavior:** Deserialization defaults to `ActionRisk::High` (fail-closed — if
the tier is unknown, assume the highest authorization requirement). Callers must explicitly
set the tier; absence is not equivalent to `ReadOnly` or `Low`.

### EC-005: RiskGatePolicy timeout on High-tier interrupt
**Scenario:** `RiskGatePolicy { High: RequireApprover(SeniorAnalyst), timeout: 4h }`.
No approval arrives within 4 hours.
**Expected behavior:** The graph transitions to `failed` with `E-GRAPH-014
InterruptApprovalTimeout { run_id: "<run_id>", tier: High, deadline_utc: "<ISO-8601 timestamp>" }`. The run is NOT
auto-approved; it fails closed. Operators must restart the run manually or apply a time-extension Command.

**Deadline persistence:** The deadline is computed at `interrupt()` time as
`created_at + policy.timeout` and stored as an absolute UTC timestamp in the parked interrupt
record (written to the checkpoint alongside the interrupt payload). Deadline evaluation is
**lazy**: it is checked on resume attempt (`POST /threads/{thread_id}/runs/{run_id}/resume`) and on status poll
(`GET /threads/{thread_id}/runs/{run_id}`), not via a background timer. This design ensures the timeout survives
process restarts without requiring external schedulers.

**Clock-skew posture:** The deadline is set by the process clock of the ferrochain-server
instance that created the interrupt. ferrochain makes no NTP/cluster-clock guarantees.
Operators requiring strict SLA enforcement (e.g., ±1s across nodes) must configure a
distributed clock source or accept ±process-clock-drift tolerances in the timeout window.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `interrupt({ action_risk: High, action: "isolate_host" })`; `Command(resume="approved")` from SeniorAnalyst | Node re-executes; `interrupt()` returns `"approved"`; isolation action proceeds | Happy path — High-tier SOC containment approval |
| TV-002 | Same interrupt; `Command(resume="approved")` from Analyst-role caller | `Err(E-GRAPH-013 InsufficientApproverRole { required: SeniorAnalyst, provided: Analyst })` | Role gate enforcement |
| TV-003 | `interrupt({ action_risk: ReadOnly, action: "query_logs" })` with AutoApprove policy | `interrupt()` returns `ReadOnlyAutoApproved` immediately; no human gate triggered | Auto-approve for read-only enrichment |
| TV-004 | `interrupt({ action_risk: Medium, action: "suspend_credential" })`; valid Analyst approval | `interrupt()` returns resume value; node proceeds to execute credential suspension | Medium-tier analyst approval |
| TV-005 | Payload with no `action_risk` field deserialized | Defaults to `ActionRisk::High`; requires SeniorAnalyst approval | Fail-closed default for unknown tier |
| TV-006 | High-tier interrupt with 4h timeout; no approval within window | `Err(E-GRAPH-014 InterruptApprovalTimeout)`; run fails; deadline_utc persisted in checkpoint | Timeout fail-closed behavior (lazy eval on poll/resume) |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-HITL-11 | High-tier interrupt is never auto-approved regardless of RiskGatePolicy config | Unit test (assert Err(InsufficientApproverRole) when policy attempts auto-approve for High) | Phase 1 |
| VP-HITL-12 | ReadOnly interrupt with AutoApprove policy does not surface to external caller | Integration test (assert no `__interrupt__` emitted in stream) | Phase 1 |
| VP-HITL-13 | ActionRisk enum is exhaustive; compile-time rejection of unknown variants | Cargo check (exhaustive match in policy evaluation code, no wildcard arm) | Wave 1 CI |

## Related BCs

- BC-2.05.001 — depends on: durable interrupt state is the storage contract; risk tiers are payload typing on top
- BC-2.05.002 — depends on: FIFO delivery applies per-slot; role-check is per-slot on top of FIFO
- BC-2.05.003 — depends on: node re-executes from start after approved High-tier interrupt
- BC-2.05.004 — depends on: Command(resume=value) with role credential is the programmatic approval API
- BC-2.10.004 — composes with: budget escalation reuses the BASE interrupt mechanism (BC-2.05.001) with a distinct `BudgetEscalation { current_usage, ceiling, policy_name, reason }` payload and `BudgetResume::Extend|Halt` resume variants; it is NOT risk-tiered and NOT subject to `RiskGatePolicy` or High-tier approver gating — orchestrator-initiated resume is explicitly permitted in BC-2.10.004
- BC-2.11.001 — related to: provenance tagging of tool results feeds Domain A context for risk tier determination

## Architecture Anchors

- `ferrochain-graph/src/hitl/action_risk.rs` — `ActionRisk` enum, `HitlInterruptPayload`, `RiskGatePolicy` (F-P27-06: renamed from `risk_tier.rs` for consistency with the `action_risk` wire-field canon; `risk_tier.rs` is a retired source path)
- `ferrochain-graph/src/hitl/policy.rs` — `ApproverRole`, role-check logic, auto-approve evaluation
- `ferrochain-server/src/routes/runs.rs` — `POST /threads/{thread_id}/runs/{run_id}/resume` with role-credential validation

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-HITL-11, VP-HITL-12, VP-HITL-13

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-006 |
| Capability Anchor Justification | CAP-006 ("HITL Interrupt / Resume with FIFO Resume-Value Delivery") per capabilities-p0.md §CAP-006 — this BC is an extension of CAP-006 per OQR-1 resolution: risk tiers are a typed payload classification within the HITL interrupt mechanism, not a new capability; the interrupt/resume mechanics are unchanged and CAP-006 is the correct anchor |
| L2 Domain Invariants | DI-003 (HITL FIFO Resume-Value Delivery) |
| L2 Assumptions | ASM-008 (A single boolean interrupt is insufficient for the SOC analyst domain; risk-tiered authorization gates require typed action-risk levels routing to different approver roles — Validated by domain-a-soc-analyst.md §4, §5) |
| OQR Resolution | OQR-1: HITL risk tiers are an extension of CAP-006 (not a new CAP); BC-2.05.006 is the BC-level implementation |
| Domain Holdout | Domain A (SOC analyst) — risk-tiered containment approval gates, tiered autonomy model |
| D17 Commitment | D17-Q2 — HITL contract as Phase-1 BC |
| CONFLICT Reference | CONFLICT-3 (adk-rust notification-only interrupt cannot carry typed risk tiers; full LangGraph-style payload injection is required) |
| Priority | P0 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-graph / ferrochain-server |
