---
document_type: behavioral-contract
level: L3
bc_id: BC-2.08.006
version: "1.8"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-08
capability: CAP-009
wave: 2
phase: 1a
producer: product-owner
timestamp: 2026-08-24T00:00:00Z
changelog:
  - "1.1 (ADV-P1D-PASS-56-COMPLETION): Gate #30 second-pass census — EC-002 had `Err(PregolyaError { category: Validation, ... })` (incorrect full-word capitalization; should be VAL per taxonomy code) and no code field; TV-002 had `Err(PregolyaError { category: VAL })` with no code. Fixed: (a) EC-002 'category: Validation' corrected to 'category: VAL'; (b) code: E-CORE-005 (ValidationFailed) added to EC-002 description and TV-002 — SDK builder constructed without calling .timeout() is a VAL construction-time validation failure."
  - "1.2 (2026-07-17, F-P89-04): Precondition 3 — removed stale live-prose clause '(or SS-TBD is used as a placeholder)'. SS-TBD is corpus-wide resolved as of Phase 1b (2026-07-14); all 95 BCs carry real SS-NN IDs. No behavioral change. Input-hash corrected from legacy 8095694 (computed against prior input state) to 412902d (current). BC changelog timestamp stays at v1.0 authoring date per Rule 5 BC branch."
  - "1.3 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-<provider>-sdk / pregolya-<provider> per module-decomposition.md v1.10."
  - "1.4 (F-P112-02, 2026-07-18): E-CORE-005 message canonicalization. EC-002 message reworded from 'timeout must be set; use .timeout(Duration::from_secs(30))' to 'Validation failed for 'timeout': must be set; use .timeout(Duration::from_secs(30))' to conform to canonical E-CORE-005 taxonomy format (Validation failed for '<field>': <reason>). TV-002 bare form unchanged — PASS-ABBREV via EC-002."
  - "1.5 (FIX-BURST-281-WAVE-B-SS08-B1/D-72/D-80/2026-07-29): (1) Error-construction notation sweep (ADR-010 §Error-Construction Notation Canon): §EC-002 and §Canonical Test Vectors TV-002 — PregolyaError value-observations missing required `..` rest pattern (partial fields: category, code, message at EC-002; category, code at TV-002); added `, ..` before closing `}` at both sites. All occurrences reconciled: 2 corrected (Class 3), 2 exempt (changelog, 1 line). (2) D-35/D-80 xtask rename: §Verification Properties VP-BC208006-02 table cell — `deny-expect-in-lib` → `check-no-panic`."
  - "1.6 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-2.06 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.7 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.8 (ADR-027 M4 / CLAUDE.md rustls-tls convention / 2026-08-24): INV-005 added — reqwest rustls-tls TLS-backend mandate for all SDK and adapter crates; native-tls and its aliases (default-tls/native-tls-alpn/native-tls-vendored) are forbidden and must be absent from the dependency tree at build and runtime. VP-BC208006-03 added for CI enforcement. Purely additive; no existing clause changed."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-009
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/entities-server.md
  - .factory/semport/partners/behavioral-intent.md
input-hash: "34b246c"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.08.006: Standalone SDK Crate Split Architecture (pregolya-\<provider\>-sdk + Adapter)

## Description

Each first-party provider integration is split into two crates: `pregolya-<provider>-sdk`
(the wire client — HTTP serialization, authentication, and raw response deserialization)
and `pregolya-<provider>` (the Runnable adapter — implements `ChatModel` and translates
between pregolya content-block types and the wire format). The SDK crate does NOT
depend on `pregolya-core`; the adapter crate depends on both. This split (HS-6/D17-Q5)
allows the SDK crate to be published and used independently of the pregolya graph runtime.

## Preconditions

1. {PRE-001} The Cargo workspace defines `pregolya-<provider>-sdk` and `pregolya-<provider>`
   as separate workspace members.
2. {PRE-002} The provider being implemented is one of the three first-party targets: OpenAI,
   Anthropic, or Ollama.
3. {PRE-003} The architect has produced the `architecture/ARCH-INDEX.md` with subsystem
   assignments for these crates.

## Postconditions

1. {PC-001} **Crate separation enforced by Cargo dependency graph:**
   - `pregolya-<provider>-sdk/Cargo.toml` does NOT list `pregolya-core` in
     `[dependencies]`. It may only depend on: `reqwest` (or equivalent HTTP client),
     `serde`, `serde_json`, and other pure-transport crates.
   - `pregolya-<provider>/Cargo.toml` lists BOTH `pregolya-<provider>-sdk` and
     `pregolya-core` in `[dependencies]`.
2. {PC-002} **SDK crate responsibilities:**
   - Provides a `<Provider>Client` struct with typed methods for the provider's
     chat completions endpoint (e.g., `create_chat_completion(req: ChatRequest) →
     Result<ChatResponse, SdkError>`).
   - Handles authentication: constructs the `Authorization: Bearer <key>` (or
     equivalent) header from the `ApiKey` newtype.
   - All SDK constructors return `Result<T, PregolyaError>` — no `.expect()` or
     `.unwrap()` in non-test code (DI-008).
   - The SDK client is constructed with a mandatory `.timeout(Duration)` (DI-009).
3. {PC-003} **Adapter crate responsibilities:**
   - Implements the `ChatModel` trait (which extends `Runnable`) from `pregolya-core`.
   - Contains all translation functions between `pregolya-core` content-block types
     and the provider's wire format (e.g., `Vec<Message> → ChatRequest`).
   - Exposes `bind_tools`, `with_structured_output` on the adapter type.
4. {PC-004} A `cargo check -p pregolya-<provider>-sdk` succeeds without `pregolya-core`
   present in the dependency graph of that package alone.

## Invariants

- {INV-001} **DI-008 (Library Constructor Result Contract):** All SDK and adapter constructors
  return `Result<T, PregolyaError>` — never panic.
- {INV-002} The SDK crate's `SdkError` type (if used internally) must convert `Into<PregolyaError>`
  so the adapter can propagate typed errors without re-wrapping.
- {INV-003} The SDK crate is published independently: its `Cargo.toml` must have a valid `[package]`
  section with `publish = true` (or no publish restriction).
- {INV-004} No translation logic lives in the SDK crate — translation is the adapter's sole
  responsibility. The SDK crate may define raw wire types (mirroring provider JSON), but
  not pregolya-core content blocks.
- {INV-005} **CLAUDE.md rustls-tls TLS Backend Mandate (ADR-027 M4):** Every `reqwest`
  dependency entry in `pregolya-<provider>-sdk/Cargo.toml` and `pregolya-<provider>/Cargo.toml`
  MUST declare `default-features = false, features = ["rustls-tls"]`. The `native-tls`
  feature and its aliases (`default-tls`, `native-tls-alpn`, `native-tls-vendored`) are
  forbidden — they MUST be absent from the dependency tree at both build time and runtime
  (verified by `cargo tree -p pregolya-<provider>-sdk | grep native-tls` returning empty).

## Edge Cases

### EC-001: SDK crate accidentally imports pregolya-core
**Scenario:** A developer adds a `pregolya-core` import to `pregolya-<provider>-sdk`
for convenience.
**Expected behavior:** CI `cargo check -p pregolya-<provider>-sdk` fails with a
dependency-graph violation (enforced via either a `cargo deny` rule or a CI check
that inspects `Cargo.lock` for the SDK package's transitive deps).

### EC-002: SDK client builder with no timeout call
**Scenario:** `<Provider>Client::new()` or `<Provider>ClientBuilder::build()` is called
without `.timeout(Duration)`.
**Expected behavior:** The build method returns `Err(PregolyaError { category: VAL, code: E-CORE-005,
message: "Validation failed for 'timeout': must be set; use .timeout(Duration::from_secs(30))", .. })`.
No default zero-timeout client is constructed. (Enforced via DI-009 / BC-2.14.004.)

### EC-003: Translation function in SDK crate (misplaced responsibility)
**Scenario:** A `fn format_messages_for_provider(msgs: Vec<Message>)` is defined in
`pregolya-<provider>-sdk` and imports `pregolya-core::messages::Message`.
**Expected behavior:** CI fails — `pregolya-<provider>-sdk` must not import
`pregolya-core`. Translation belongs in `pregolya-<provider>`.

### EC-004: Third-party SDK crate re-use
**Scenario:** A community provider crate wants to use only `pregolya-<provider>-sdk`
without pulling in the full pregolya runtime.
**Expected behavior:** `cargo add pregolya-openai-sdk` succeeds; `cargo check` with
only that dependency compiles. No graph-runtime types leak into the SDK public API.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | `cargo check -p pregolya-openai-sdk` | Exits 0; `pregolya-core` NOT in Cargo.lock for this package | Dependency separation |
| TV-002 | `pregolya-openai-sdk::OpenAiClient::builder().build()` (no timeout) | `Err(PregolyaError { category: VAL, code: E-CORE-005, .. })` | EC-002 timeout guard |
| TV-003 | `pregolya-openai-sdk::OpenAiClient::builder().timeout(30s).api_key(key).build()` | `Ok(OpenAiClient { … })` | Happy path SDK construction |
| TV-004 | `pregolya-openai::ChatOpenAI::new(config)` (adapter) | `Ok(ChatOpenAI { … })` — implements `ChatModel` trait | Adapter construction |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC208006-01 | pregolya-<provider>-sdk has no pregolya-core transitive dependency | CI check (cargo metadata + dep graph analysis) | Wave 2 |
| VP-BC208006-02 | All SDK + adapter constructors return Result, no .expect() in non-test code | CI lint (check-no-panic; DI-008) | Wave 2 |
| VP-BC208006-03 | Every reqwest dep in SDK + adapter crates declares `default-features = false, features = ["rustls-tls"]`; native-tls and aliases absent from cargo tree | CI check (`cargo tree -p pregolya-<provider>-sdk \| grep native-tls` exits empty; Cargo.toml lint) | Wave 2 |

## Related BCs

- BC-2.08.001 — streaming (streaming logic lives in adapter, transport in SDK)
- BC-2.14.004 — mandatory HTTP timeout (SDK builder must set timeout; co-enforced here)
- BC-2.14.003 — constructor Result contract (DI-008 applies to SDK constructors)

## Architecture Anchors

- `pregolya-openai-sdk/` — wire client crate (to be created)
- `pregolya-openai/` — Runnable adapter crate (to be created)
- `pregolya-anthropic-sdk/` — wire client crate (to be created)
- `pregolya-anthropic/` — Runnable adapter crate (to be created)
- `pregolya-ollama-sdk/` — wire client crate (to be created)
- `pregolya-ollama/` — Runnable adapter crate (to be created)

## Story Anchor

S-2.06

## VP Anchors

- VP-BC208006-01, VP-BC208006-02, VP-BC208006-03

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-009 |
| Capability Anchor Justification | CAP-009 ("Provider-Conformant Chat Model Interface") per capabilities-p1-p2.md §CAP-009 — this BC implements the HS-6/D17-Q5 standalone SDK crate split architecture mandate explicitly named in CAP-009's grounding ("standalone SDK crate split architecture (HS-6/D17-Q5)") |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract) |
| NE References | NE-04 (mandatory HTTP timeout on SDK client builder — shared with BC-2.14.004) |
| Priority | P1 |
| Wave | Wave 2 |
| Test Types | U (unit — constructor Result), CI (cargo dependency graph check) |
| Module | pregolya-<provider>-sdk / pregolya-<provider> |
