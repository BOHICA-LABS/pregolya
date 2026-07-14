---
document_type: behavioral-contract
level: L3
bc_id: BC-2.13.001
version: "1.1"
status: draft
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
input-hash: "01382649ae22c497f23c7d3371208c8694ad3996050b31954a83ad5108d55b0f"
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-13
capability: CAP-015
lifecycle_status: active
introduced: v1.0.0-greenfield
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
priority: P1
wave: 1
---

# BC-2.13.001: Enforcing Sandbox Backend (WASM or Container) Is Default (NE-01)

## Description

`SandboxBackend::default()` must return an enforcing isolation backend (WASM or container), not
the process backend. The adk-rust counter-example (P-61) makes `ProcessBackend` — which applies
only `env_clear()` and a wall-clock timeout, with no filesystem, network, or memory isolation —
the Cargo default feature. ferrochain inverts this: the `sandbox-wasm` feature is the default
Cargo feature, and any runtime path that cannot produce an enforcing backend must return
`Err(E-SBXD-003: SandboxInitFailed)` rather than silently falling back to the process backend.

## Preconditions

1. `ferrochain-sandbox` is compiled with default Cargo features (i.e., `sandbox-wasm` is active)
2. No `SandboxBackend` instance has been explicitly constructed by the caller
3. The caller invokes `SandboxBackend::default()` or `SandboxExecutor::new_default()`

## Postconditions

1. `SandboxBackend::default()` returns a `WasmBackend` (or `ContainerBackend` if WASM is
   unavailable and the `sandbox-container` feature is also enabled)
2. The returned backend's `BackendCapabilities` struct has `filesystem_isolated = true`,
   `network_isolated = true`, and `memory_bounded = true`
3. No `default()` or `new()` constructor on any `SandboxBackend` variant returns a
   `ProcessBackend` — the process backend is only accessible via
   `Sandbox::unsafe_process_no_isolation()`
4. If only the `sandbox-process` feature is compiled (no `sandbox-wasm`, no
   `sandbox-container`), `SandboxBackend::default()` returns
   `Err(E-SBXD-003: SandboxInitFailed)` with reason `"no enforcing backend compiled in"`
   and the Cargo build emits a compile-time warning: `"WARNING: ferrochain-sandbox compiled
   without an enforcing backend feature; all executions will fail at runtime unless an explicit
   process backend is constructed via unsafe_process_no_isolation()"`

## Invariants

1. No public `Default` implementation for any `SandboxBackend` variant may return a
   non-enforcing backend; the only legal default is WASM or container
2. `BackendCapabilities::enforcing()` for the default backend returns `true`; this helper
   is a conjunction of `filesystem_isolated && network_isolated && memory_bounded`
3. The name `unsafe_process_no_isolation` must appear verbatim in the process backend
   constructor — both "unsafe" and "no_isolation" tokens must be present to surface the
   security posture at call sites
4. adk-rust reference sparsity: upstream has no enforcing-default design; this invariant is
   purely ferrochain-greenfield, derived from NE-01 (P-61 counter-example) and DI-006

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Platform does not support unprivileged namespaces (Linux without `unshare` permission) | `SandboxBackend::default()` returns `Err(E-SBXD-003: SandboxInitFailed { reason: "unprivileged user namespaces unavailable" })`; does NOT silently fall back to `ProcessBackend` |
| EC-002 | Both `sandbox-wasm` and `sandbox-container` features are absent from the compiled binary | Compile-time warning; `SandboxBackend::default()` returns `Err(E-SBXD-003: SandboxInitFailed { reason: "no enforcing backend compiled in" })` |
| EC-003 | `sandbox-wasm` feature present but WASM engine init fails at runtime (e.g., OOM at engine construction) | Constructor returns `Err(E-SBXD-003: SandboxInitFailed { ... })`; must NOT panic (per DI-008; also must-not-inherit P-66: `WasmBackend::new()` uses `.expect()`) |
| EC-004 | `sandbox-wasm` unavailable on the target triple (e.g., WASM-on-WASM) and `sandbox-container` is also disabled | `SandboxBackend::default()` returns `Err(E-SBXD-003)` and logs the reason; caller must explicitly opt into `unsafe_process_no_isolation()` |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `SandboxBackend::default()` in a build with default features (`sandbox-wasm` active) | Returns `WasmBackend`; `BackendCapabilities { filesystem_isolated: true, network_isolated: true, memory_bounded: true }` | happy-path |
| `Sandbox::unsafe_process_no_isolation()` explicit call | Returns `ProcessBackend`; `BackendCapabilities { filesystem_isolated: false, network_isolated: false, memory_bounded: false }` | explicit opt-in (contrast) |
| Build compiled with only `sandbox-process` feature; call `SandboxBackend::default()` | `Err(E-SBXD-003: SandboxInitFailed { reason: "no enforcing backend compiled in" })` | error (no enforcing backend) |
| WASM engine init panics due to library bug (must-not-inherit P-66) | `Err(E-SBXD-003)` returned; no process panic | error (panic prevention) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|--------------|
| VP-2.13.001-A | `SandboxBackend::default()` never returns a `ProcessBackend` in any reachable code path when at least one enforcing backend feature is compiled | unit test — inspect returned variant |
| VP-2.13.001-B | `BackendCapabilities::enforcing()` is `true` for all backends returned from `default()` | unit test — `assert!(caps.enforcing())` |
| VP-2.13.001-C | No public API surface of `ferrochain-sandbox` has a method that returns `ProcessBackend` without the tokens "unsafe" and "no_isolation" in its name | structural test — API surface scan |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-015 |
| Capability Anchor Justification | CAP-015 ("Sandboxed Tool Execution (Enforcing Backend Default)") per capabilities-p1-p2.md §CAP-015 |
| L2 Domain Invariants | DI-006 (Enforcing Sandbox Backend is Default) |
| Source Analysis | P-61 NOT-APPLICABLE (adk-rust default ProcessBackend = must-not-inherit); P-62 NOT-APPLICABLE (policy strictness decoupled from enforcement = must-not-inherit); P-49 ADOPT (truthful BackendCapabilities); NE-01 (adk-rust default no-isolation is counter-example); assessment-parts/part-2 §6 Sandbox Cluster; assessment-parts/part-3 §NE-01 |
| Reference Evidence | Upstream adk-rust: ProcessBackend is default feature (P-61); ferrochain INVERTS this. No LangChain equivalent — greenfield design derived from NE-01 counter-example. P-48 ADOPT (bubblewrap deny-by-default) confirms enforcing-backend posture is correct for Linux; WASM analog for cross-platform. |
| Binding Decisions | NE-01, DI-006 |
| Forcing Functions | Domain C OpenClaw §4 (tool-execution sandboxing: "recommend default-on isolation"); product-brief.md §NE catalog NE-01 |
| Architecture Module | ferrochain-sandbox (filled by architect) |
| Stories | S-N.MM (filled by story-writer) |

## Related BCs

- BC-2.13.002 — composes with: ProcessBackend opt-in warning fires on the non-default path enabled by this BC's inversion
- BC-2.13.003 — depends on: policy enforcement gate requires knowing whether the backend is enforcing (via BackendCapabilities)
- BC-2.13.006 — composes with: macOS Seatbelt deny-by-default is an enforcing-backend requirement for the macOS target

## Architecture Anchors

- `architecture/ferrochain-sandbox.md` — `SandboxBackend` trait and default backend selection (filled by architect)
- `architecture/cargo-features.md` — `sandbox-wasm` as default Cargo feature (filled by architect)

## Story Anchor

S-N.MM — Enforcing sandbox backend default (filled by story-writer)

## VP Anchors

- VP-2.13.001-A — Default never returns ProcessBackend (unit test)
- VP-2.13.001-B — BackendCapabilities::enforcing() true for default (unit test)
- VP-2.13.001-C — API surface scan for "unsafe"/"no_isolation" tokens (structural test)
