---
document_type: behavioral-contract
level: L3
bc_id: BC-2.13.003
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "760910c"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-13
capability: CAP-015
lifecycle_status: active
introduced: v1.0.0-greenfield
modified: []
extracted_from: null
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
priority: P1
wave: 1
---

# BC-2.13.003: Strict Policy + Non-Enforcing Backend Returns Err(PolicyNotEnforceable)

## Description

When `Sandbox::execute()` is called with a `SandboxPolicy` that requires enforcement
(e.g., `filesystem_isolated: true`) and the selected backend's `BackendCapabilities` reports
that requirement as `false`, the call returns `Err(E-SBXD-002: PolicyNotEnforceable)` without
executing the tool. This is the direct inversion of adk-rust P-62 (`RustSandboxExecutor`
declares a strict policy but silently proceeds without enforcement) and P-83 (Docker backend
ignores per-request policy). ferrochain hard-gates on the mismatch: policy requirements are
compared against backend capabilities at execute-time, before any tool code runs.

## Preconditions

1. A `SandboxPolicy` with at least one enforcement field set to `true`
   (e.g., `enforce_filesystem: true` or `enforce_network: true`) has been constructed
2. The selected `SandboxBackend`'s `BackendCapabilities` reports the corresponding
   capability field as `false`
3. `Sandbox::execute(tool, args, policy)` is called

## Postconditions

1. `Sandbox::execute()` returns
   `Err(E-SBXD-002: PolicyNotEnforceable { policy_requirements: [...], backend_capabilities: ... })`
2. The tool function is NOT called — zero lines of tool code execute
3. The error payload includes both the requested policy requirements and the actual
   `BackendCapabilities` of the selected backend, enabling the caller to log the precise mismatch
4. No silent fallback to a different backend occurs; `Sandbox::execute()` does not internally
   retry with a more capable backend
5. `E-SBXD-002` is classified as severity `broken` per the error taxonomy

## Invariants

1. `Sandbox::execute()` with a strict policy and a non-enforcing backend NEVER returns `Ok(_)` —
   there is no flag, config option, or `#[cfg(test)]` override that bypasses this gate
2. The error must carry the specific mismatch: which policy fields required `true` and which
   backend capability fields returned `false`
3. There is no `force_anyway()`, `override_policy_check()`, or equivalent method
4. The capability check occurs at execute-time (not at construction time) — even if the backend
   is upgraded between construction and execution, the check runs on the capabilities at the
   moment of the call
5. adk-rust reference sparsity: neither P-62 nor P-83 enforces this gate; it is greenfield
   behavior derived from NE-01 ferrochain requirement and DI-006

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Policy requests `enforce_filesystem: true` only; backend has `filesystem_isolated: false` but `network_isolated: true` | `Err(E-SBXD-002)` returned — filesystem mismatch is sufficient; no partial execution |
| EC-002 | `SandboxPolicy::permissive()` (all enforce fields `false`) combined with `ProcessBackend` | `Ok(result)` — no policy requirements; permissive policy allows any backend |
| EC-003 | `SandboxPolicy::strict()` combined with `WasmBackend` (all capabilities `true`) | `Ok(result)` — policy satisfied; tool executes normally |
| EC-004 | `SandboxPolicy::strict()` combined with `ProcessBackend` in a `#[cfg(test)]` context | Still returns `Err(E-SBXD-002)` — no test-only override permitted |
| EC-005 | Backend capabilities change between construction and execute (hypothetical mutable backend) | Capability check at execute-time catches the change; `Err(E-SBXD-002)` if mismatch at that moment |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `SandboxPolicy::strict()` + `ProcessBackend` → `execute(tool, args)` | `Err(E-SBXD-002: PolicyNotEnforceable)` — tool NOT called | happy-path (gate fires correctly) |
| `SandboxPolicy::permissive()` + `ProcessBackend` → `execute(tool, args)` | `Ok(result)` — tool executes | happy-path (no enforcement required) |
| `SandboxPolicy::strict()` + `WasmBackend` → `execute(tool, args)` | `Ok(result)` — all capabilities satisfied | happy-path (enforcing backend) |
| `SandboxPolicy { enforce_filesystem: true, enforce_network: false }` + `ProcessBackend` → `execute()` | `Err(E-SBXD-002)` with `policy_requirements: [filesystem_isolated]` in error payload | edge-case (partial policy mismatch) |
| Inspect `E-SBXD-002` error payload fields | Contains both `policy_requirements` listing `filesystem_isolated` and `backend_capabilities` showing `filesystem_isolated: false` | structural |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|--------------|
| VP-2.13.003-A | For all `(policy, backend)` pairs where any `policy.enforce_*` field is `true` and the corresponding `backend.capabilities.*` field is `false`, `execute()` returns `Err(E-SBXD-002)` | unit test truth table — 4 combinations (strict×enforcing, strict×non-enforcing, permissive×enforcing, permissive×non-enforcing) |
| VP-2.13.003-B | Tool function is never called when `Err(E-SBXD-002)` is returned | unit test — mock tool call counter asserts zero invocations |
| VP-2.13.003-C | `E-SBXD-002` error payload contains both policy requirements and backend capabilities | unit test — error field inspection |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-015 |
| Capability Anchor Justification | CAP-015 ("Sandboxed Tool Execution (Enforcing Backend Default)") per capabilities-p1-p2.md §CAP-015 |
| L2 Domain Invariants | DI-006 (Enforcing Sandbox Backend is Default) |
| Source Analysis | P-62 NOT-APPLICABLE (must-not-inherit: strict policy silently decoupled from enforcement); P-83 NOT-APPLICABLE (must-not-inherit: Docker backend ignores per-request policy); P-49 ADOPT (BackendCapabilities truthful flags drive this gate); P-57 NOT-APPLICABLE but correct reference posture; NE-01 ferrochain requirement; assessment-parts/part-3 §NE-01 |
| Reference Evidence | adk-rust P-62 `RustSandboxExecutor` declares strict policy but executes without enforcement — ferrochain explicitly inverts this. P-83 Docker backend ignores per-request SandboxPolicy — second counter-example. No upstream reference for this gate — greenfield. |
| Binding Decisions | NE-01, DI-006 |
| Forcing Functions | product-brief.md §NE catalog NE-01 ("Sandbox::execute on strict policy against non-enforcing backend returns Err(PolicyNotEnforceable)"); Domain C OpenClaw §4 |
| Architecture Module | ferrochain-sandbox (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.13.001 — depends on: the default enforcing backend satisfies strict policy, making this error rare on the happy path
- BC-2.13.002 — composes with: this gate fires BEFORE the ProcessBackend execute-time warning (BC-2.13.002); with a strict policy, the tool never runs and the warning is moot

## Architecture Anchors

- `architecture/ferrochain-sandbox.md` — `Sandbox::execute()` capability-check gate and `E-SBXD-002` error type (filled by architect)

## Story Anchor

S-N.MM — PolicyNotEnforceable gate in Sandbox::execute (filled by story-writer)

## VP Anchors

- VP-2.13.003-A — Truth table for (policy, backend) combinations (unit test)
- VP-2.13.003-B — Tool not called on Err(E-SBXD-002) (unit test)
- VP-2.13.003-C — Error payload fields (unit test)
