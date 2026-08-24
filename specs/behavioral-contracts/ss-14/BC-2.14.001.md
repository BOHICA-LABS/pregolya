---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.001
version: "1.11"
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
timestamp: 2026-08-24T01:00:00Z
changelog:
  - "1.1 (F-P96-01, 2026-07-17): Module field resolved from placeholder to pregolya-core per module-decomposition.md v1.10."
  - "1.2 (D21/Batch-3b-i/2026-07-20): Component enum expanded 12→16 per ADR-010 v1.1. Added TMPL (pregolya-prompts, SS-18), SRLZ (pregolya-core::serializable, SS-19), VS (pregolya-vectorstores, SS-21), EMBED (pregolya-core::embeddings, SS-22) to Description and Postcondition 2 component list. Category axis unchanged at 12."
  - "1.3 (F-P164-01/burst-266/2026-07-25): Component enum updated 16→17 per ADR-010 §Component Axis Expansion (D23). Added TOOLS (pregolya-tools, SS-23) to Description component list. Counter updated '16 components as of D21' → '17 components as of D23'. TD-VSDD-060 sole-site confirmed: rg -n '16 components|sixteen components' /Users/jmagady/Dev/pregolya/.factory/specs/ returns only BC-2.14.001 — no other live-body references require amendment. BC-INDEX sync required (v1.2→v1.3)."
  - "1.4 (F-P173-211+F-P173-619/FIX-BURST-276/2026-07-27): F-P173-211 — propagate ADR-010 §Decision (F-P173-211 Arc/Box adjudication): update EC-001 source field from `Option<Box<dyn Error + Send + Sync>>` to `Option<Arc<dyn std::error::Error + Send + Sync>>`; add source field to Description six-field enumeration (partial reproduction was the root cause of the 173-pass detection lag). F-P173-619 — add PC8 for `#[non_exhaustive]` attribute per CLAUDE.md Code Conventions (all public API surface error types carry it; PregolyaError was the sole missing instance). TD-VSDD-060 sweep: sole product-owner-owned Box site was EC-001 (fixed here); `entities-server.md §PregolyaError` entity definition `source: Option<Box<dyn StdError>>` is business-analyst scope — routed for separate fix; ADR-010 changelog text preserving old Box form is intentional historical record, no action."
  - "1.5 (FIX-BURST-276-TD091/2026-07-27): TD-VSDD-091 anti-volatile-pin repair — PC8 last sentence: replace live-body sibling-artifact version pin with stable section anchor. ADR-010 §Decision (the section containing the PregolyaError struct definition and canonical #[non_exhaustive] #[derive(Debug, Clone)] form) replaces a specific version number. Sibling-sweep of this file live body: no additional version pins found. BC-INDEX split unchanged (BC-2.14.001 remains P0)."
  - "1.6 (FIX-BURST-280-WAVE-C/F-P175-A25-T2/2026-07-28): Task 2 — explicit annotation added to PC1, TV-001 Notes, and TV-002 Notes. These three sites use struct-literal construction `PregolyaError { ... }` intentionally: (a) this BC defines the PregolyaError struct itself, not a usage BC; (b) the tests run within pregolya-core where #[non_exhaustive] does NOT bar struct-literal construction from the defining crate; (c) external callers use PregolyaError::new(...) per PC8/ADR-010 §Decision. No behavioral change. TD-VSDD-060 sibling-sweep confirmed: all other PregolyaError { ... } sites in BC-2.14.001 body are prose shorthand (ALL-CAPS) or the struct definition in PC8 — no additional in-crate construction forms present."
  - "1.7 (WAVE-B-B3/2026-07-29): Error-construction notation sweep (ADR-010 §Error-Construction Notation Canon). Three Class 3 violations corrected: EC-001 `PregolyaError { component: CHKPT, category: DURABILITY }` — added `, ..` (CLASS3 VIOLATION, 2/5 fields); Related BCs `PregolyaError { category: VAL }` — added `, ..` (CLASS3 VIOLATION, 1/5 fields); TV-002 Input `...` field-elision marker — replaced with `..` (CLASS3_ASCII_ELLIPSIS_VIOLATION). PC1, TV-001, and PC8 unchanged: PC1 and TV-001 are Class 3 VALID (all 5 non-source fields present; Class 4 defining-crate annotations from v1.6 remain accurate); PC8 `pub struct PregolyaError { … }` is EXCLUDED_DECL. No behavioral change."
  - "1.8 (BURST-308/D26-EXEC-propagation/2026-08-17): Category axis expanded 12→13 per ADR-010 §Category Axis Expansion (D26). Description: EXEC added as 13th category to the enumeration; counter updated from '12 categories, unchanged' to '13 categories (EXEC added by D26 per ADR-010 §Category Axis Expansion (D26))'. TD-VSDD-060 sibling sweep: EXEC not listed elsewhere in BC-2.14.001 live body (no other Category enumeration site). No behavioral change to PregolyaError struct."
  - "1.9 (story-anchor-backfill/2026-08-22): §Story Anchor backfilled to S-1.01 from STORY-INDEX forward map (CANONICAL PRINCIPLE Rule 6; no behavioral change)."
  - "1.10 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.11 (P2A-044 F-06/2026-08-24): compressed-ordinal citations normalized to stable tags."
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
input-hash: "9d456d5"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.14.001: PregolyaError 2D Component × Category Struct with RetryHint and Machine Code

## Description

Every error emitted by the pregolya library crate family is an instance of `PregolyaError`,
a struct with two orthogonal dimensions: `component` (which crate emitted the error: CORE, GRAPH,
CHKPT, SERVER, PROV, MCP, SPLIT, SBXD, RETRY, CRON, MEMORY, BUDGET, TMPL, SRLZ, VS, EMBED, TOOLS —
17 components as of D23) and `category` (the error class: VAL, AUTH, RATE, TIMEOUT, TRANSPORT,
INTERNAL, DURABILITY, POLICY, TOOL, CONCURRENCY, SECURITY, TENANCY, EXEC — 13 categories (EXEC added by D26 per ADR-010 §Category Axis Expansion (D26))). Each error also carries a `retry_hint` (Never / Maybe / Later(Duration)),
a machine-readable `code` string (e.g. `E-CORE-001`), a human-readable `message` (MUST NOT
contain credentials per DI-010), and a causal `source: Option<Arc<dyn std::error::Error + Send + Sync>>`
(MUST NOT be exposed in HTTP responses; `Arc` not `Box` — `Arc::clone` increments the refcount
without requiring `T: Clone`, which is what makes `#[derive(Clone)]` on the struct compile). This
contract adopts the adk-rust P-01/P-04 pattern (CONFLICT-6) and applies it uniformly across
all pregolya crates.

**Rendering convention (canonical):** In BC/spec prose and inline code slots, `component` and
`category` values are written as ALL-CAPS taxonomy codes (e.g. `category: DURABILITY`,
`component: CHKPT`). In formal Rust postconditions and code blocks that specify the exact API,
the full enum path is used (`Category::Durability`, `Component::Chkpt`). The mapping is
one-to-one; `DURABILITY` in prose ↔ `Category::Durability` in Rust, `CHKPT` ↔
`Component::Chkpt`, etc.

## Preconditions

1. {PRE-001} A pregolya library crate is constructing or propagating an error condition.
2. {PRE-002} The `pregolya-core` crate defines and exports `PregolyaError`, `Component`, `Category`,
   and `RetryHint` as public types.
3. {PRE-003} The error code string follows the convention `E-<COMPONENT>-<NNN>` using the component
   abbreviations defined in the error taxonomy.

## Postconditions

1. {PC-001} `PregolyaError { component: Component::Core, category: Category::Val, retry_hint: RetryHint::Never,
   code: "E-CORE-001".into(), message: "Invalid ContentBlock type...".into() }` constructs without error.
   _(Struct-literal form is **intentional** in this BC: this test runs within `pregolya-core` where
   `#[non_exhaustive]` does not bar struct-literal construction by the defining crate. External callers
   must use `PregolyaError::new(...)` per {PC-008} and ADR-010 §Decision. Do not convert this notation.)_
2. {PC-002} The `component` field identifies the originating crate (e.g. `Component::Graph` for graph
   errors, `Component::Chkpt` for checkpoint errors).
3. {PC-003} The `category` field identifies the error class independently of the component; a
   `(Component::Prov, Category::Rate)` error is a rate-limit from a provider, while
   `(Component::Server, Category::Policy)` is a policy violation from the server crate.
4. {PC-004} `retry_hint` carries semantic retry guidance:
   - `RetryHint::Never` — do not retry; the caller must fix their input or configuration.
   - `RetryHint::Maybe` — retry once; transient condition only.
   - `RetryHint::Later(duration)` — rate-limited; wait `duration` then retry.
5. {PC-005} Every component × category combination documented in error-taxonomy.md has a corresponding
   `E-<COMPONENT>-<NNN>` code; no two codes share the same string.
6. {PC-006} `PregolyaError` implements `std::error::Error + Send + Sync + 'static` (required for
   `anyhow` / `thiserror` compatibility in application code).
7. {PC-007} `PregolyaError` does NOT implement `Default` — errors must be constructed explicitly with
   all required fields.
8. {PC-008} `PregolyaError` is `#[non_exhaustive]` — external code cannot construct it via a struct
   literal or exhaustively pattern-match its fields without a `..` wildcard arm. This is
   required by CLAUDE.md Code Conventions for all public API surface types. The struct is
   defined as `#[non_exhaustive] #[derive(Debug, Clone)] pub struct PregolyaError { … }`
   in `pregolya-core/src/error.rs` (canonical form per ADR-010 §Decision).

## Invariants

- {INV-001} **DI-008 (Library Constructor Result Contract):** `PregolyaError` itself is always fully
  initialized (never partially constructed); its fields carry their semantic values without
  optional placeholders.
- {INV-002} **DI-014 (Error Propagation):** All validation and operational failures propagate as
  `Err(PregolyaError)` — no `None`, empty-vec, or silent-discard path is acceptable as a
  substitute for a real error.
- {INV-003} The `code` string is immutable once assigned; it serves as the machine-parseable stable
  identifier referenced in dashboards and alerting rules.
- {INV-004} `retry_hint` category assignments are fixed per error category as documented in
  error-taxonomy.md; implementors must not invent new hint-category pairings.

## Edge Cases

### EC-001: Error from crate A wraps error from crate B
**Scenario:** `pregolya-graph` catches a `PregolyaError { component: CHKPT, category: DURABILITY, .. }`
from `pregolya-checkpoint` and re-emits it. Should the outer error be Graph or Chkpt?
**Expected behavior:** The originating component (Chkpt) is preserved in the re-emitted error via
a `source: Option<Arc<dyn std::error::Error + Send + Sync>>` chain field. The outer error's
`component` field reflects the crate that added context; the source chain retains the root cause.
Alternatively, the Chkpt error is propagated unchanged if the graph crate adds no new context.
The `Arc` wrapper (not `Box`) is load-bearing: it is what allows `#[derive(Clone)]` to compile on
`PregolyaError` — `Arc::clone` increments a refcount without requiring the inner error to be
`Clone`. Dropping to `Box` would produce `error[E0277]` at the first build of `pregolya-core/src/error.rs`
(F-P173-211 root cause).

### EC-002: Constructing PregolyaError with an unknown component–category pair
**Scenario:** A new pregolya crate introduces a component abbreviation not in the current taxonomy.
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

### EC-005: PregolyaError used as anyhow source
**Scenario:** Application code wraps a `PregolyaError` with `anyhow::Context`.
**Expected behavior:** The wrap succeeds because `PregolyaError: Error + Send + Sync`. The anyhow
chain preserves the original `PregolyaError`'s fields when downcast with `anyhow.downcast_ref::<PregolyaError>()`.

## Canonical Test Vectors

| # | Input | Expected Output | Notes |
|---|-------|-----------------|-------|
| TV-001 | Construct `PregolyaError { component: Component::Core, category: Category::Val, retry_hint: RetryHint::Never, code: "E-CORE-001", message: "..." }` | Struct fields readable as specified; `err.to_string()` contains message | Happy path — in-crate construction (struct literal valid within `pregolya-core`; external API is `PregolyaError::new(...)`; notation intentional — do not convert) |
| TV-002 | `PregolyaError { component: Component::Prov, category: Category::Rate, retry_hint: RetryHint::Later(Duration::from_secs(30)), .. }` | `retry_hint == RetryHint::Later(30s)` | Rate-limit error with backoff — in-crate field verification (notation intentional; see {PC-001} note) |
| TV-003 | `std::error::Error::source(&err)` when `source` field is `Some(inner)` | Returns `Some(&inner)` | Error chaining works |
| TV-004 | `anyhow::Context::context(Err::<(), _>(pregolya_err), "ctx")` | `anyhow::Error` wraps `pregolya_err`; `downcast_ref::<PregolyaError>()` succeeds | anyhow compatibility |
| TV-005 | `PregolyaError::default()` | Compile error — `Default` not implemented | No default construction |

## Verification Properties

| VP ID | Description | Method | Phase |
|-------|-------------|--------|-------|
| VP-BC214001-01 | Every `E-<COMPONENT>-<NNN>` code in error-taxonomy.md is unique (no collision) | CI integration test enumerating all error variant codes | Wave 0 CI |
| VP-BC214001-02 | `PregolyaError` satisfies `Send + Sync + 'static` | `static_assertions::assert_impl_all!` | Wave 0 CI |

## Related BCs

- BC-2.14.002 — RFC-7807 emission (composes with: PregolyaError is the source for RFC-7807 problem+json output)
- BC-2.14.003 — Constructor Result contract (depends on: all crate constructors propagate errors as PregolyaError)
- BC-2.14.005 — API key newtype (composes with: credential errors must also use PregolyaError)
- BC-2.14.006 — Validation failure propagation (composes with: validation errors are PregolyaError { category: VAL, .. })
- BC-2.01.001 — Typed ContentBlock construction (depends on: content block errors propagate as PregolyaError)

## Architecture Anchors

- `pregolya-core/src/error.rs` — `PregolyaError`, `Component`, `Category`, `RetryHint` enum definitions (to be created)
- Error taxonomy source: `prd-supplements/error-taxonomy.md`

## Story Anchor

S-1.01

## VP Anchors

- VP-BC214001-01, VP-BC214001-02

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-016 |
| Capability Anchor Justification | CAP-016 ("Typed Error Taxonomy (PregolyaError 2D Struct)") per capabilities-p0.md §CAP-016 — this BC directly implements the 2D component × category struct with RetryHint and machine code that CAP-016 defines as its primary deliverable |
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract), DI-014 (Error Propagation (No Silent Swallowing)) |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), CI lint |
| Module | pregolya-core |
