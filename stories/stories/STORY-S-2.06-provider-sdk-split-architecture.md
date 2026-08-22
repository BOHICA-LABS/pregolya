---
document_type: story
level: ops
story_id: S-2.06
epic_id: E-19
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-19T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-08/BC-2.08.006.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/dependency-graph.md
input-hash: "3c2f849"
traces_to: .factory/stories/STORY-INDEX.md
points: 3
depends_on: [S-1.04]
blocks: [S-2.07, S-2.09]
behavioral_contracts: [BC-2.08.006, BC-2.14.005]
verification_properties: []
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: [pregolya-openai, pregolya-anthropic, pregolya-ollama, pregolya-openai-sdk, pregolya-anthropic-sdk, pregolya-ollama-sdk]
subsystems: [SS-08]
estimated_days: 1
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-2.06: Provider SDK Split Architecture — reqwest rustls-tls, Timeout Enforcement, No pregolya-core in SDK

## Narrative

- **As a** pregolya platform engineer defining the provider integration boundary
- **I want to** establish the two-crate split for each provider (`pregolya-<provider>-sdk` for the wire client and `pregolya-<provider>` for the adapter), ensuring that SDK crates carry no `pregolya-core` dependency, all reqwest clients use `rustls-tls` (never `native-tls`), and builders reject missing timeouts with `Err(E-CORE-005)`
- **So that** provider SDK crates remain reusable outside the pregolya library, the native-tls ~65s macOS Keychain overhead and MITM interception risk are eliminated at build time, and timeout-less clients are caught at construction time rather than at production incident time

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.08.006 | Provider SDK Two-Crate Split: pregolya-<provider>-sdk (wire client, no pregolya-core dep) + pregolya-<provider> (adapter); reqwest rustls-tls mandatory; SDK builder timeout enforcement (E-CORE-005) | P1 |
| BC-2.14.005 | API Key Newtype with Redacted Debug; No Serialize; No Deref<Target=str> | P0 |

## Acceptance Criteria

### AC-001 (traces to BC-2.08.006 postcondition 1)
Each provider has a two-crate structure:
- `pregolya-openai-sdk` — wire HTTP client for the OpenAI API; no `pregolya-core` dependency
- `pregolya-openai` — adapter crate; imports both `pregolya-core` and `pregolya-openai-sdk`
The same split applies to `pregolya-anthropic-sdk` / `pregolya-anthropic` and
`pregolya-ollama-sdk` / `pregolya-ollama`.
Verified by `test_BC_2_08_006_sdk_crate_no_pregolya_core_dep()` — inspects `Cargo.toml`
of each `-sdk` crate and asserts `pregolya-core` is not in `[dependencies]`.

### AC-002 (traces to BC-2.08.006 postcondition 2)
Every `reqwest` dependency entry in all provider crates (`pregolya-*-sdk`, `pregolya-openai`,
`pregolya-anthropic`, `pregolya-ollama`) declares `default-features = false, features = ["rustls-tls"]`.
The `native-tls`, `default-tls`, `native-tls-alpn`, and `native-tls-vendored` feature names are
absent from all Cargo.toml files in the workspace.
Verified by `test_BC_2_08_006_reqwest_rustls_tls_only()` — grep workspace for forbidden feature names.

### AC-003 (traces to BC-2.08.006 postcondition 3)
Each SDK builder (e.g., `OpenAiSdkBuilder`) requires `.timeout(Duration)` to be called before
`.build()`. If `.timeout()` is never called, `build()` returns:
`Err(PregolyaError::new(Component::Core, Category::Val, RetryHint::Never, "E-CORE-005",
"Validation failed for 'timeout': must be set; use .timeout(Duration) on the builder"))`.
`Category::Val` is correct for E-CORE-005 (VAL per error-taxonomy.md; a missing required builder
field is a construction-time validation failure; `Category::Config` is not a defined category).
The message must follow the canonical E-CORE-005 format: `"Validation failed for '<field>': <reason>"`.
Verified by `test_BC_2_08_006_sdk_builder_missing_timeout_returns_e_core_005()`.

### AC-004 (traces to BC-2.08.006 postcondition 4)
`OpenAiSdkBuilder::timeout(Duration)` with a valid duration (e.g., `Duration::from_secs(30)`)
followed by `.build()` returns `Ok(OpenAiSdk)` with the client configured to use the specified
timeout. The reqwest client is constructed with `ClientBuilder::new()` + `.timeout(duration)`
+ `.build()`.
Verified by `test_BC_2_08_006_sdk_builder_with_timeout_ok()`.

### AC-005 (traces to BC-2.08.006 postcondition 1 — crate-separation topology)
SDK crates (`pregolya-openai-sdk` etc.) have NO dependency on any `pregolya-*` adapter crate.
The dependency graph is:
```
pregolya-openai-sdk   ← no pregolya-core dep
pregolya-openai       → depends on pregolya-core + pregolya-openai-sdk
```
Any SDK crate that gains a `pregolya-core` dependency fails a CI cargo-deny check.
Verified by `test_BC_2_08_006_sdk_dep_graph_acyclic_no_core()`.

### AC-006 (traces to BC-2.14.005 postcondition 2 — credential newtype REDACTED Debug)
API key types in SDK crates (`OpenAiApiKey`, `AnthropicApiKey`, `OllamaBaseUrl`) are
newtypes with REDACTED `Debug` implementations:
```
impl fmt::Debug for OpenAiApiKey {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { f.write_str("<redacted>") }
}
```
No `Display` impl leaks key material. No `Serialize`/`Deserialize` impl on credential types.
Verified by `test_BC_2_08_006_api_key_debug_is_redacted()` and `test_BC_2_08_006_api_key_no_display()`.

### AC-007 (traces to BC-2.08.006 invariant 1)
`reqwest::Client` instances produced by SDK builders use `rustls-tls` as the TLS backend.
A unit test constructs a client and verifies no native-tls calls are made (mock TLS backend
or feature-flag check). At minimum, `cargo tree -e features -p pregolya-openai-sdk | grep native-tls`
returns empty in CI.
Verified by `test_BC_2_08_006_tls_backend_is_rustls()`.

### AC-008 (traces to BC-2.08.006 invariant 2)
The 30-second default timeout convention: SDK builders that do NOT receive an explicit
`.timeout()` call produce `Err(E-CORE-005)`. There is NO silent default of 30 seconds
in the builder — the caller must be explicit. The 30-second CLAUDE.md convention is a
RECOMMENDATION for callers, not a builder fallback.
Verified by `test_BC_2_08_006_no_silent_default_timeout()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `pregolya-openai-sdk` wire client | `pregolya-openai-sdk/src/lib.rs`, `pregolya-openai-sdk/src/client.rs` | effectful (reqwest HTTP) |
| `pregolya-openai` adapter | `pregolya-openai/src/lib.rs` | effectful (delegates to SDK) |
| `pregolya-anthropic-sdk` wire client | `pregolya-anthropic-sdk/src/lib.rs`, `pregolya-anthropic-sdk/src/client.rs` | effectful |
| `pregolya-anthropic` adapter | `pregolya-anthropic/src/lib.rs` | effectful |
| `pregolya-ollama-sdk` wire client | `pregolya-ollama-sdk/src/lib.rs`, `pregolya-ollama-sdk/src/client.rs` | effectful |
| `pregolya-ollama` adapter | `pregolya-ollama/src/lib.rs` | effectful |
| SDK builder (`OpenAiSdkBuilder` etc.) | per-SDK client.rs | pure-core (builder pattern, no I/O until `.build()`) |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| SDK builder (pre-build) | pure-core | Only accumulates configuration. No I/O until `.build()` is called. |
| SDK client (post-build) | effectful | Issues HTTP requests via reqwest. |
| Adapter crates | effectful | Delegates to effectful SDK clients; implements pregolya-core traits. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | Builder called with `timeout(Duration::ZERO)` | Accepted — a zero timeout is a valid (if aggressive) configuration; validation is the builder's contract |
| EC-002 | `pregolya-openai-sdk` added to a binary that already has `reqwest/native-tls` as a transitive dep | CI `cargo deny` check flags the native-tls feature; build fails |
| EC-003 | `OpenAiApiKey::new("")` (empty key) | SDK builder accepts; runtime call returns a 401 error from the API — key validation is not the builder's responsibility |
| EC-004 | `OpenAiApiKey` printed via `{:?}` | Output is `<redacted>` — no key material leaked |
| EC-005 | `OpenAiSdkBuilder::build()` called twice | Second call returns the same `Ok(OpenAiSdk)` or `Err` — builder is immutable; no double-free |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~3,200 |
| BC files (2 BCs) | ~6,000 |
| `module-decomposition.md` (SS-08 section) | ~400 |
| 6 × Cargo.toml stubs (~15 lines each) | ~500 |
| 6 × lib.rs stubs (~30 lines each) | ~1,000 |
| Test files (~80 lines) | ~1,200 |
| Tool outputs | ~500 |
| **Total** | **~12,800** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~6.4%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-008 (test-writer)
2. [ ] Verify Red Gate (no Red Gate BCs in this story — proceed to implementation after test stubs)
3. [ ] Create `pregolya-openai-sdk/Cargo.toml` — `reqwest = { default-features = false, features = ["rustls-tls"] }`, no pregolya-core dep
4. [ ] Create `pregolya-openai-sdk/src/lib.rs` — re-export-only root; `pub mod client;`
5. [ ] Create `pregolya-openai-sdk/src/client.rs` — `OpenAiSdkBuilder`, `OpenAiSdk`, `OpenAiApiKey` (redacted Debug, no Display); timeout enforcement
6. [ ] Create `pregolya-anthropic-sdk/Cargo.toml` + `src/lib.rs` + `src/client.rs` — same pattern
7. [ ] Create `pregolya-ollama-sdk/Cargo.toml` + `src/lib.rs` + `src/client.rs` — same pattern (base URL instead of API key)
8. [ ] Create `pregolya-openai/Cargo.toml` — depends on `pregolya-core` + `pregolya-openai-sdk`; create `src/lib.rs` stub
9. [ ] Create `pregolya-anthropic/Cargo.toml` + `src/lib.rs` stub — depends on pregolya-core + pregolya-anthropic-sdk
10. [ ] Create `pregolya-ollama/Cargo.toml` + `src/lib.rs` stub — depends on pregolya-core + pregolya-ollama-sdk
11. [ ] Confirm `E-CORE-005` in error taxonomy (already registered as `Component::Core, Category::Val, RetryHint::Never`; no new registration required — verify the row exists in error-taxonomy.md §Component: CORE)
12. [ ] Add all 6 crates to workspace root `Cargo.toml` members list
13. [ ] Run `cargo nextest run -p pregolya-openai-sdk -p pregolya-anthropic-sdk -p pregolya-ollama-sdk` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-1.04 established `Runnable` and `pregolya-core` foundational types. The adapter crates
(`pregolya-openai`, `pregolya-anthropic`, `pregolya-ollama`) will implement `Runnable` from
`pregolya-core` in later stories (S-2.07+). This story only establishes the structural
split and the SDK builders — no Runnable implementations yet.

S-1.02 established `PregolyaError` with `Component`, `Category`, `RetryHint`. `E-CORE-005`
uses `Component::Core, Category::Val, RetryHint::Never`. The code is already registered in
error-taxonomy.md §Component: CORE; verify the row exists before implementation — no new
registration required. `Category::Config` is not a defined category in the taxonomy; the
correct enum variant for VAL-category codes is `Category::Val`.

The CLAUDE.md code convention "reqwest TLS backend — rustls-tls mandatory" applies to
ALL reqwest deps workspace-wide. This story is the FIRST time reqwest is added to the
workspace — set the correct pattern from the start. Future crates inherit this pattern.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `pregolya-*-sdk` crates have NO `pregolya-core` dependency | BC-2.08.006 postcondition 1; ADR split architecture | `cargo deny` check; CI dependency graph assertion |
| `reqwest` with `default-features = false, features = ["rustls-tls"]` only | BC-2.08.006 postcondition 2; CLAUDE.md Code Conventions | `cargo deny` feature check; workspace-wide grep |
| `native-tls`, `default-tls`, `native-tls-alpn`, `native-tls-vendored` absent from all Cargo.toml files | CLAUDE.md Code Conventions | grep check in CI |
| SDK builder `.build()` without `.timeout()` returns `Err(E-CORE-005)` | BC-2.08.006 postcondition 3 | Unit test AC-003 |
| No silent 30s default timeout in builder | BC-2.08.006 invariant 2 | Unit test AC-008 |
| Credential newtypes have REDACTED `Debug` — no `Display` | CLAUDE.md Code Conventions; BC-2.14.005 postcondition 2 | Unit tests AC-006 |
| `lib.rs` and `mod.rs` are re-export-only | CLAUDE.md Code Conventions | Code review |

**Forbidden dependencies:** `pregolya-openai-sdk`, `pregolya-anthropic-sdk`, `pregolya-ollama-sdk` must NOT depend on `pregolya-core`, `pregolya-graph`, `pregolya-prompts`, `pregolya-vectorstores`, or any other `pregolya-*` crate. SDK crates must be independently publishable to crates.io with zero internal dependencies.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `reqwest` | workspace pin | HTTP client for provider API calls; MUST use `default-features = false, features = ["rustls-tls"]` |
| `tokio` | workspace pin | Async runtime for reqwest HTTP operations in SDK crates |
| `serde` + `serde_json` | workspace pin | Request/response serialization in SDK crates |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-openai-sdk/Cargo.toml` | CREATE | SDK crate; no pregolya-core dep; reqwest rustls-tls |
| `pregolya-openai-sdk/src/lib.rs` | CREATE | Re-export-only root |
| `pregolya-openai-sdk/src/client.rs` | CREATE | `OpenAiSdkBuilder`, `OpenAiSdk`, `OpenAiApiKey` |
| `pregolya-anthropic-sdk/Cargo.toml` | CREATE | Same pattern for Anthropic |
| `pregolya-anthropic-sdk/src/lib.rs` | CREATE | Re-export-only root |
| `pregolya-anthropic-sdk/src/client.rs` | CREATE | `AnthropicSdkBuilder`, `AnthropicSdk`, `AnthropicApiKey` |
| `pregolya-ollama-sdk/Cargo.toml` | CREATE | Same pattern for Ollama (no API key; base URL) |
| `pregolya-ollama-sdk/src/lib.rs` | CREATE | Re-export-only root |
| `pregolya-ollama-sdk/src/client.rs` | CREATE | `OllamaSdkBuilder`, `OllamaSdk`, `OllamaBaseUrl` |
| `pregolya-openai/Cargo.toml` | CREATE | Adapter; depends on pregolya-core + pregolya-openai-sdk |
| `pregolya-openai/src/lib.rs` | CREATE | Re-export-only stub (full impl in S-2.07+) |
| `pregolya-anthropic/Cargo.toml` | CREATE | Adapter; depends on pregolya-core + pregolya-anthropic-sdk |
| `pregolya-anthropic/src/lib.rs` | CREATE | Re-export-only stub |
| `pregolya-ollama/Cargo.toml` | CREATE | Adapter; depends on pregolya-core + pregolya-ollama-sdk |
| `pregolya-ollama/src/lib.rs` | CREATE | Re-export-only stub |
| `Cargo.toml` (workspace root) | MODIFY | Add all 6 crates to `members` list |
