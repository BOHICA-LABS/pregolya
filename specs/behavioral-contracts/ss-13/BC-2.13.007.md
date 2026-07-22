---
document_type: behavioral-contract
level: L3
bc_id: BC-2.13.007
version: "1.0"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-13
capability: CAP-015
wave: 1
phase: 1b
producer: product-owner
timestamp: 2026-07-15T00:00:00Z
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-015
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/planning/holdout-domains/domain-d-hermes-agent.md
input-hash: "5668669"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.13.007: Environment Variable Sanitization at Sandbox Execution Boundary

## Description

Before any sandboxed tool execution, `SandboxExecutor::prepare_environment()` filters the
current process environment: by default, the sandbox receives an **empty** environment (all
variables stripped). Operators may configure `SandboxConfig.env_allowlist: Vec<String>`
containing exact variable names to pass through. Only the variables named in the allowlist
are forwarded; all others — including provider API keys, tokens, and cloud credentials — are
discarded. Wildcard or glob patterns in `env_allowlist` are rejected at `SandboxConfig`
construction time with `E-SBXD-006 InvalidEnvAllowlistPattern`. This provides defense-in-depth
for DI-010 (Credential Opacity): even if code running inside the sandbox attempts to read
environment-based credentials, the values are absent unless the operator has explicitly
allowlisted them.

> **Error code minted here (E-SBXD-006).** `E-SBXD-006 InvalidEnvAllowlistPattern` is
> introduced by this BC. Category: VAL. Severity: broken. RetryHint: Never.
> Taxonomy row registration: sub-burst 2.

## Preconditions

1. A sandboxed tool execution is about to begin via any backend (WASM, container, or
   process-with-explicit-opt-in per BC-2.13.001/BC-2.13.002).
2. The current process has an active environment that may contain credential variables
   (e.g., `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `AWS_SECRET_ACCESS_KEY`, `GITHUB_TOKEN`).
3. `SandboxConfig.env_allowlist` is a `Vec<String>` of zero or more exact variable names
   (case-sensitive, no wildcards). The default is an empty vec (strip all).

## Postconditions

1. **Default (empty allowlist):** `SandboxExecutor::prepare_environment()` passes an empty
   environment map to the sandbox backend. The sandbox execution environment contains zero
   variables inherited from the parent process.
2. **Non-empty allowlist:** only variables whose exact name appears in `env_allowlist` AND
   are present in the current process environment are passed through. Variables in the
   allowlist that are absent from the current process environment are silently skipped (no
   error). All other variables are discarded.
3. The filtering happens inside `SandboxExecutor::prepare_environment()`, before the
   backend receives the execution config. No credential variable reaches the sandbox backend
   unless it is explicitly allowlisted.
4. A `DEBUG` log is emitted after filtering: `"Sandbox env sanitization: stripped <N>
   variables, forwarded <M> allowlisted variables"` where `N` is the count of variables
   discarded and `M` is the count forwarded. `N` and `M` are non-negative integers with
   `N + M` equal to the total number of variables present in the parent environment.
5. If any entry in `env_allowlist` contains the characters `*` or `?` (glob wildcards),
   `SandboxConfig::new(…)` returns:
   `Err(FerrochainError { component: SBXD, category: VAL, code: "E-SBXD-006",
   message: "InvalidEnvAllowlistPattern: entry '<pattern>' contains wildcard characters — only
   exact variable names are supported in v1", retry_hint: Never })`.
   Construction fails before any execution. (DI-008.)

## Invariants

- **Default is strip-all:** the safe default requires no action from the operator. Passing
  credentials to the sandbox requires explicit positive operator action (adding to allowlist).
- **v1 exact-names only:** glob patterns, prefix matches, and regex are not supported in v1.
  Supporting only exact names keeps the filtering code simple and auditable.
- **Defense-in-depth (DI-010):** env stripping is a layer below the sandbox backend isolation.
  Even if the sandbox backend itself leaks environment access, the credentials are not present
  because they were filtered before the backend received the execution config.
- **Apply to ALL sandbox backends:** filtering is done at the `SandboxExecutor` level, not
  per-backend. WASM, container, and process backends all receive the filtered environment.
- The allowlist entries are compared by exact string equality (case-sensitive). `"path"` and
  `"PATH"` are different entries.

## Edge Cases

### EC-001: Allowlisted variable absent from current process environment
**Scenario:** `env_allowlist = ["CUSTOM_TOOL_CONFIG"]` but `CUSTOM_TOOL_CONFIG` is not set
in the parent process.
**Expected behavior:** The sandbox receives an empty environment (nothing to forward). No error
raised. Debug log: `"Sandbox env sanitization: stripped N variables, forwarded 0 allowlisted
variables"`.

### EC-002: Allowlist explicitly includes a credential variable
**Scenario:** Operator sets `env_allowlist = ["OPENAI_API_KEY"]` intentionally (e.g., tool
needs API access from inside the sandbox).
**Expected behavior:** `OPENAI_API_KEY` is forwarded to the sandbox. This is a deliberate
operator opt-in; ferrochain does not block it. No warning emitted (warning would be noise
for valid operator-approved use cases).

### EC-003: env_allowlist contains a glob pattern
**Scenario:** `SandboxConfig::new(env_allowlist: vec!["OPENAI_*".to_string()])`.
**Expected behavior:** `Err(E-SBXD-006 InvalidEnvAllowlistPattern { pattern: "OPENAI_*" })`
at construction time. No execution proceeds.

### EC-004: Large parent environment (100+ variables); empty allowlist
**Scenario:** Parent process has 120 environment variables including 5 credential vars.
`env_allowlist = []`.
**Expected behavior:** All 120 variables stripped; sandbox receives empty environment.
Debug log: `"Sandbox env sanitization: stripped 120 variables, forwarded 0 allowlisted
variables"`.

### EC-005: env_allowlist contains both a valid name and a glob
**Scenario:** `env_allowlist = ["TOOL_TOKEN", "AWS_*"]`.
**Expected behavior:** `Err(E-SBXD-006 InvalidEnvAllowlistPattern { pattern: "AWS_*" })` at
construction. The valid entry `"TOOL_TOKEN"` does not save the config — the entire allowlist
is rejected if any entry contains a wildcard. (Fail-closed: refuse to execute with a
misconfigured allowlist.)

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `env_allowlist = []`; parent env has `OPENAI_API_KEY=sk-xxx`; execute tool; inspect sandbox env | Sandbox env is empty (no `OPENAI_API_KEY`) | Default strip-all |
| TV-002 | `env_allowlist = ["PATH", "HOME"]`; parent has both; execute tool | Sandbox env = `{PATH: <val>, HOME: <val>}` only | Allowlist filter |
| TV-003 | `env_allowlist = ["OPENAI_API_KEY"]`; parent has it; execute | Sandbox receives `OPENAI_API_KEY` | Explicit opt-in |
| TV-004 | `env_allowlist = ["MISSING_VAR"]`; `MISSING_VAR` not in parent env | Sandbox env is empty; `Ok(())` | Absent var not an error |
| TV-005 | `env_allowlist = ["OPENAI_*"]` | `Err(E-SBXD-006 InvalidEnvAllowlistPattern)` at construction | Glob pattern rejected |
| TV-006 | `env_allowlist = ["GOOD_VAR", "BAD_*"]` | `Err(E-SBXD-006 InvalidEnvAllowlistPattern { pattern: "BAD_*" })` | Any glob in list = reject all |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-ENV-01 | Default (empty allowlist): credential variables absent from sandbox environment | Integration test: set `OPENAI_API_KEY` in test env; execute sandboxed code that reads env; assert key not present | Wave 1 |
| VP-ENV-02 | Allowlisted variable present; non-allowlisted absent | Integration test: `env_allowlist = ["ALLOWED_VAR"]`; assert ALLOWED_VAR present, others absent | Wave 1 |

## Related BCs

- BC-2.13.001 — composes with: env sanitization applies to the default enforcing backend; stripping occurs regardless of which backend is active
- BC-2.13.002 — composes with: env sanitization applies even when process backend is explicitly opted in; the operator's allowlist governs both backends
- BC-2.13.006 — composes with: macOS Seatbelt deny-by-default provides file-system isolation; env stripping provides credential isolation; these are complementary defenses

## Architecture Anchors

- `ferrochain-sandbox/src/executor.rs` — `SandboxExecutor::prepare_environment(config: &SandboxConfig) -> HashMap<String, String>`; applies allowlist filter before passing environment to backend
- `ferrochain-sandbox/src/config.rs` — `SandboxConfig.env_allowlist: Vec<String>`; construction-time validation of allowlist entries (E-SBXD-006 on wildcard patterns)

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-ENV-01, VP-ENV-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-015 |
| Capability Anchor Justification | CAP-015 ("Sandboxed Tool Execution (Enforcing Backend Default)") per capabilities-p1-p2.md §CAP-015 — this BC specifies environment variable sanitization at the sandbox boundary, which is an orthogonal security layer within the sandboxed execution surface that CAP-015 defines; stripping credentials from the sandbox environment is a direct extension of the "enforcing isolation" posture CAP-015 mandates |
| L2 Domain Invariants | DI-006 (Enforcing Sandbox Backend is Default — env stripping is a defense-in-depth measure for the same threat model), DI-010 (Credential Opacity — API keys and tokens that appear as environment variables must not be accessible inside the sandbox unless explicitly allowlisted by the operator), DI-008 (Library Constructor Result Contract — invalid allowlist at construction returns Err not panic) |
| Error Code Minted | E-SBXD-006 InvalidEnvAllowlistPattern — VAL, broken, Never. SBXD namespace had 5 live codes (E-SBXD-001 through E-SBXD-005); E-SBXD-006 is next. Taxonomy row: sub-burst 2. |
| Domain D Forcing Function | domain-d-hermes-agent.md req 6 — "[PARTIAL SS-13/CAP-015] … env-secret stripping at the sandbox execution boundary — no BC specifies filtering environment variables (including provider API keys) before passing the execution environment to the sandbox backend" |
| Priority | P1 |
| Wave | Wave 1 |
| Test Types | U (unit), I (integration) |
| Module | ferrochain-sandbox |
