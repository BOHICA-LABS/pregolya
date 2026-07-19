---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.001
version: "1.1"
status: active
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P0
subsystem: SS-14
capability: CAP-016
wave: 0
phase: 1a
producer: product-owner
timestamp: 2026-07-13T00:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to ferrochain-core per module-decomposition.md v1.10."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "0b13d84"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.001: FerrochainError 2D Component × Category Struct with RetryHint and Machine Code

## Description

Every error emitted by the ferrochain library crate family is an instance of `FerrochainError`,
a struct with two orthogonal dimensions: `component` (which crate emitted the error: CORE, GRAPH,
CHKPT, SERVER, PROV, MCP, SPLIT, SBXD, RETRY, CRON, MEMORY, BUDGET) and `category` (the error
class: VAL, AUTH, RATE, TIMEOUT, TRANSPORT, INTERNAL, DURABILITY, POLICY, TOOL, CONCURRENCY,
SECURITY, TENANCY). Each error also carries a `retry_hint` (Never / Maybe / Later(Duration)),
a machine-readable `code` string (e.g. `E-CORE-001`), and a human-readable `message`. This
contract adopts the adk-rust P-01/P-04 pattern (CONFLICT-6) and applies it uniformly across
all ferrochain crates.

**Rendering convention (canonical):** In BC/spec prose and inline code slots, `component` and
`category` values are written as ALL-CAPS taxonomy codes (e.g. `category: DURABILITY`,
`component: CHKPT`). In formal Rust postconditions and code blocks that specify the exact API,
the full enum path is used (`Category::Durability`, `Component::Chkpt`). The mapping is
one-to-one; `DURABILITY` in prose ↔ `Category::Durability` in Rust, `CHKPT` ↔
`Component::Chkpt`, etc.

## Preconditions

1. A ferrochain library crate is constructing or propagating an error condition.
2. The `ferrochain-core` crate defines and exports `FerrochainError`, `Component`, `Category`,
   and `RetryHint` as public types.
3. The error code string follows the convention `E-<COMPONENT>-<NNN>` using the component
   abbreviations defined in the error taxonomy.

## Postconditions

1. `FerrochainError { component: Component::Core, category: Category::Val, retry_hint: RetryHint::Never,
   code: "E-CORE-001".into(), message: "Invalid ContentBlock type...".into() }` constructs without error.
2. The `component` field identifies the originating crate (e.g. `Component::Graph` for graph
   errors, `Component::Chkpt` for checkpoint errors).
3. The `category` field identifies the error class independently of the component; a
   `(Component::Prov, Category::Rate)` error is a rate-limit from a provider, while
   `(Component::Server, Category::Policy)` is a policy violation from the server crate.
4. `retry_hint` carries semantic retry guidance:
   - `RetryHint::Never` — do not retry; the caller must fix their input or configuration.
   - `RetryHint::Maybe` — retry once; transient condition only.
   - `RetryHint::Later(duration)` — rate-limited; wait `duration` then retry.
5. Every component × category combination documented in error-taxonomy.md has a corresponding
   `E-<COMPONENT>-<NNN>` code; no two codes share the same string.
6. `FerrochainError` implements `std::error::Error + Send + Sync + 'static` (required for
   `anyhow` / `thiserror` compatibility in application code).
7. `FerrochainError` does NOT implement `Default` — errors must be constructed explicitly with
   all required fields.

## Invariants

- **DI-008 (Library Constructor Result Contract):** `FerrochainError` itself is always fully
  initialized (never partially constructed); its fields carry their semantic values without
  optional placeholders.
- **DI-014 (Error Propagation):** All validation and operational failures propagate as
  `Err(FerrochainError)` — no `None`, empty-vec, or silent-discard path is acceptable as a
  substitute for a real error.
- The `code` string is immutable once assigned; it serves as the machine-parseable stable
  identifier referenced in dashboards and alerting rules.
- `retry_hint` category assignments are fixed per error category as documented in
  error-taxonomy.md; implementors must not invent new hint-category pairings.

## Edge Cases

### EC-001: Error from crate A wraps error from crate B
**Scenario:** `ferrochain-graph` catches a `FerrochainError { component: CHKPT, category: DURABILITY }`
from `ferrochain-checkpoint` and re-emits it. Should the outer error be Graph or Chkpt?
**Expected behavior:** The originating component (Chkpt) is preserved in the re-emitted error via
a `source: Option<Box<dyn Error + Send + Sync>>` chain field. The outer error's `component` field
reflects the crate that added context; the source chain retains the root cause. Alternatively,
the Chkpt error is propagated unchanged if the graph crate adds no new context.

### EC-002: Constructing FerrochainError with an unknown component–category pair
**Scenario:** A new ferrochain crate introduces a component abbreviation not in the current taxonomy.
**Expected behavior:** The `Component` enum has a catch-all variant (`Component::Custom(String)`)
for forward compatibility. The `code` field must still follow `E-<CUSTOM_NAME>-<NNN>` format.
The retry_hint must be one of the three defined variants — no new variants allowed without a
taxonomy amendment.

### EC-003: RetryHint::Later with zero duration
**Scenario:** A provider returns a rate-limit response but includes no `Retry-After` header.
**Expected behavior:** The error uses `RetryHint::Later(Duration::from_secs(0))` as a sentinel
rather than omitting the hint. The client interprets zero-duration as "retry immediately after
yielding" rather than as an invalid state.

### EC-004: Error code collision detection
**Scenario:** Two crate teams both claim `E-CORE-001` for different error conditions.
**Expected behavior:** CI integration test validates that `E-<COMPONENT>-<NNN>` codes are unique
across all registered error taxonomy entries. The build fails on a collision.

### EC-005: FerrochainError used as anyhow source
**Scenario:** Application code wraps a `FerrochainError` with `anyhow::Context`.
**Expected behavior:** The wrap succeeds because `FerrochainError: Error + Send + Sync`. The anyhow
chain preserves the original `FerrochainError`'s fields when downcast with `anyhow.downcast_ref::<FerrochainError>()`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Construct `FerrochainError { component: Component::Core, category: Category::Val, retry_hint: RetryHint::Never, code: "E-CORE-001", message: "..." }` | Struct fields readable as specified; `err.to_string()` contains message | Happy path — basic construction |
| TV-002 | `FerrochainError { component: Component::Prov, category: Category::Rate, retry_hint: RetryHint::Later(Duration::from_secs(30)), ... }` | `retry_hint == RetryHint::Later(30s)` | Rate-limit error with backoff |
| TV-003 | `std::error::Error::source(&err)` when `source` field is `Some(inner)` | Returns `Some(&inner)` | Error chaining works |
| TV-004 | `anyhow::Context::context(Err::<(), _>(ferrochain_err), "ctx")` | `anyhow::Error` wraps `ferrochain_err`; `downcast_ref::<FerrochainError>()` succeeds | anyhow compatibility |
| TV-005 | `FerrochainError::default()` | Compile error — `Default` not implemented | No default construction |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC214001-01 | Every `E-<COMPONENT>-<NNN>` code in error-taxonomy.md is unique (no collision) | CI integration test enumerating all error variant codes | Wave 0 CI |
| VP-BC214001-02 | `FerrochainError` satisfies `Send + Sync + 'static` | `static_assertions::assert_impl_all!` | Wave 0 CI |

## Related BCs

- BC-2.14.002 — RFC-7807 emission (composes with: FerrochainError is the source for RFC-7807 problem+json output)
- BC-2.14.003 — Constructor Result contract (depends on: all crate constructors propagate errors as FerrochainError)
- BC-2.14.005 — API key newtype (composes with: credential errors must also use FerrochainError)
- BC-2.14.006 — Validation failure propagation (composes with: validation errors are FerrochainError { category: VAL })
- BC-2.01.001 — Typed ContentBlock construction (depends on: content block errors propagate as FerrochainError)

## Architecture Anchors

- `ferrochain-core/src/error.rs` — `FerrochainError`, `Component`, `Category`, `RetryHint` enum definitions (to be created)
- Error taxonomy source: `prd-supplements/error-taxonomy.md`

## Story Anchor

_[to be filled after story decomposition]_

## VP Anchors

- VP-BC214001-01, VP-BC214001-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (FerrochainError 2D Struct)") per capabilities-p0.md §CAP-016 — this BC directly implements the 2D component × category struct with RetryHint and machine code that CAP-016 defines as its primary deliverable |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract), DI-014 (Error Propagation (No Silent Swallowing)) |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), CI lint |
| Module | ferrochain-core |
