---
document_type: behavioral-contract
level: L3
bc_id: BC-2.14.001
version: "1.26"
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
timestamp: 2026-09-17T00:00:00Z
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
  - "1.12 (S-1.01 adv pass-1 F1/2026-09-17): Align to error-taxonomy v1.59 SYS 14th-category. Description category list updated: SYS added as 14th category after EXEC; counter updated from '13 categories (EXEC added by D26 per ADR-010 §Category Axis Expansion (D26))' to '14 categories (EXEC added by D26, SYS added by error-taxonomy v1.59 per burst-A2-error-coord/2026-08-26)'. This is propagation of an already-authorized taxonomy decision (SYS introduced in error-taxonomy v1.59 as the OS-level syscall failure category; Default RetryHint Maybe). Behavioral contract semantics of PregolyaError struct unchanged — only the enumerated category count in the description prose is updated. TD-VSDD-060 sibling sweep: no other site in BC-2.14.001 live body enumerates the category count or list outside the Description."
  - "1.13 (ADR-030-propagation/2026-09-19): Added Component::Traj (pregolya-checkpoint/trajectory, SS-04) per ADR-030 §Decision 2 — Durable Audit-Grade Trajectory Primitive. Component count: 17 → 18. Total (incl. Custom): 18 → 19. Description component enumeration updated from comma-separated to pipe-separated canonical form; TRAJ inserted after CHKPT, before SERVER. PC-002 example expanded to include Component::Traj. TD-VSDD-060 sibling sweep: sole component-list site in BC-2.14.001 live body is the Description paragraph — no other enumeration site. BC-INDEX title column sync required (v1.12→v1.13)."
  - "1.14 (S-1.01-adv-pass-7-corrigendum/2026-09-19): v1.13 changelog anchor corrected — ADR-030 §Decision 2 (not §Component Axis Expansion which belongs to ADR-010 §D23)."
  - "1.15 (S-1.01-adv-pass-8/2026-09-20): EC-002 — document Custom name lowercase normalization and named-component collision prohibition. Implementer action: add collision-detection test."
  - "1.16 (S-1.01-adv-pass-9/2026-09-20): EC-002 wire-path updated from extensions.component to top-level component per BC-2.14.002 §PC-001 RFC-7807 §3.2 flatten decision."
  - "1.17 (S-1.01-adv-pass-11): VP-BC214001-01 phase corrected to S-1.02 per story EC-004; DI-010 added to traces_to and traceability."
  - "1.18 (S-1.01-adv-pass-12): EC-002 guard description updated from debug_assert to always-on assert; emission-time guard (component_lowercase) documented."
  - "1.19 (S-1.01-adv-pass-2/F-005/2026-09-20): EC-006 and EC-007 added — code-format and code↔component binding construction/emission panics are now specified public API behavior."
  - "1.20 (S-1.01-adv-pass-3/F-001/2026-09-20): POL-12 repair — error-taxonomy v1.59 version pin in §Description replaced with stable anchor error-taxonomy.md §Error Categories."
  - "1.21 (S-1.01-adv-pass-3/F-005-followup/2026-09-20): §Description — remove chained double-§ form introduced by v1.20; error-taxonomy.md §Error Categories changed to error-taxonomy.md Error Categories section per ADR-022 §Decision 5 prohibition on chained §X §Y forms."
  - "1.22 (S-1.01-adv-pass-5/F-001/2026-09-20): EC-007 cross-ref to BC-2.14.002 EC-002 (emission-path panic enumeration) added for bidirectional traceability."
  - "1.23 (S-1.01-adv-pass-10/MED-001/2026-09-20): EC-007 scope clause added — binding covers code↔COMPONENT axis only; code↔category axis is normative but deferred to S-1.02 (VP-BC214001-01). OBS-001: citation form divergence adjudicated — BC-2.14.001 de-§ in Description is intentional per ADR-022 §Decision 5 (chained §-citation would result otherwise); BC-2.14.002 §-form in §Notes is correct (no chaining issue)."
  - "1.24 (S-1.01-adv-pass-13/MED-002/2026-09-20): EC-006 emission-time clause added — `to_problem()` re-validates the E- prefix at emission time (BC-2.14.002 EC-002 path 3); reachable via in-crate struct-literal construction ({PC-008} clause 1) where new() format check was bypassed. EC-007 Cross-refs updated from 'both sanctioned' to 'all three sanctioned' to_problem() panic paths."
  - "1.25 (S-1.02-adv-pass-2/CRITICAL-F-A/2026-09-22, product-owner): BC↔BC contradiction with BC-2.14.003 {PC-005}/{PC-006} resolved by Option-A adjudication (fail-fast governs). This BC's always-on assert! semantics (EC-002/EC-006/EC-007) are preserved unchanged. BC-2.14.003 §EC-006 (programmer-error-guard-assertion policy) explicitly encompasses the PregolyaError::new() precondition guards as the canonical example. No behavioral change to this BC; cross-reference added to Related BCs."
  - "1.26 (adversary-pass-3-H02/2026-09-22): VP-BC214001-01 closed — cargo xtask check-error-code-registry implemented and wired to CI lint-extra in S-1.02."
traces_to:
  - domain-spec/capabilities-p0.md#CAP-016
  - domain-spec/invariants.md#DI-008
  - domain-spec/invariants.md#DI-010
  - domain-spec/invariants.md#DI-014
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd-supplements/error-taxonomy.md
  - .factory/semport/core/rust-translation-strategy.md
input-hash: "79d6343"
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
a struct with two orthogonal dimensions: `component` (which crate emitted the error: CORE | GRAPH |
CHKPT | TRAJ | SERVER | PROV | MCP | SPLIT | SBXD | RETRY | CRON | MEMORY | BUDGET | TMPL | SRLZ | VS | EMBED | TOOLS —
18 components as of ADR-030) and `category` (the error class: VAL, AUTH, RATE, TIMEOUT, TRANSPORT,
INTERNAL, DURABILITY, POLICY, TOOL, CONCURRENCY, SECURITY, TENANCY, EXEC, SYS — 14 categories (EXEC added by D26 per ADR-010 §Category Axis Expansion (D26); SYS added by error-taxonomy.md Error Categories section per burst-A2-error-coord/2026-08-26)). Each error also carries a `retry_hint` (Never / Maybe / Later(Duration)),
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
3. {PRE-003} The error code string follows the convention `E-<COMPONENT>-NNN` using the component
   abbreviations defined in the error taxonomy. This convention is enforced as an always-on
   programmer-error invariant: `PregolyaError::new()` panics at construction time if `code` is
   malformed or the COMPONENT segment does not match the supplied `component` variant, and
   `PregolyaError::to_problem()` re-validates the code↔component binding at emission time
   (see EC-006, EC-007).

## Postconditions

1. {PC-001} `PregolyaError { component: Component::Core, category: Category::Val, retry_hint: RetryHint::Never,
   code: "E-CORE-001".into(), message: "Invalid ContentBlock type...".into() }` constructs without error.
   _(Struct-literal form is **intentional** in this BC: this test runs within `pregolya-core` where
   `#[non_exhaustive]` does not bar struct-literal construction by the defining crate. External callers
   must use `PregolyaError::new(...)` per {PC-008} and ADR-010 §Decision. Do not convert this notation.)_
2. {PC-002} The `component` field identifies the originating crate (e.g. `Component::Graph` for graph
   errors, `Component::Chkpt` for checkpoint errors, `Component::Traj` for checkpoint trajectory
   errors (pregolya-checkpoint/trajectory, SS-04, added per ADR-030)).
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
The custom component name is lowercased in the wire `component` field (top-level per RFC-7807 §3.2) (`Component::Custom("MyCrate")` → `"mycrate"`). Custom names that, when lowercased, collide with a named component's lowercase identifier (e.g. `Custom("Core")` → `"core"` collides with `Component::Core`) are forbidden — an always-on `assert!` in `PregolyaError::new()` detects this collision at construction time. A second always-on `assert!` guard in the wire-emission path (`component_lowercase`, reached from `to_problem()`) ensures the rule holds even if `component` is reassigned post-construction (ADR-010 §Decision keeps `component` as a `pub` field). Both panics are intentional: they surface a programmer error before a malformed URN reaches an RFC-7807 response. Callers should use only well-formed codes and `Component::Custom` names that are not collision-prone. The `code` field retains the casing supplied by the caller per the `impl Into<String>` conversion.

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

### EC-006: Code format invariant at construction
**Scenario:** A caller passes a `code` string to `PregolyaError::new()` that does not match the
`E-<COMPONENT>-NNN` format (e.g., `"CORE-001"`, `"E-CORE-1"`, `"E--001"`, `"E-CORE-0001"`).
**Expected behavior:** `PregolyaError::new()` panics at construction time via an always-on `assert!`.
The required format is: starts with `E-`, the middle COMPONENT segment satisfies `[A-Za-z0-9_-]`
with no leading, trailing, or consecutive separator characters, and the suffix is exactly three
ASCII digits. This is a programmer-error invariant; it fires for any caller regardless of whether
`component` is a named variant or `Component::Custom`. The `E-` prefix ensures temporal stability:
code strings serve as the machine-readable stable identifiers referenced in dashboards and alerting
rules ({INV-003}), and the format constraint prevents malformed codes from silently entering those
pipelines. Callers must supply a well-formed code string; a malformed code is a programming defect,
not a runtime error path.
Additionally, `to_problem()` re-validates the `E-` prefix at emission time: if `self.code` does not
begin with `"E-"`, it panics with a BC-2.14.001 EC-006-citing message (BC-2.14.002 EC-002 path 3).
This path is reachable only via the in-crate struct-literal construction form sanctioned by {PC-008}
clause 1, where `new()`'s construction-time validate step was bypassed.

### EC-007: Code↔component binding at construction and emission
**Scenario:** A caller constructs a `PregolyaError` where the COMPONENT segment of `code` does
not case-insensitively match `component_lowercase(&component)` — for example, `Component::Graph`
paired with `code: "E-CORE-001"`, or `Component::Custom("MyExt")` paired with `code: "E-GRAPH-001"`.
**Expected behavior:** `PregolyaError::new()` panics at construction time via an always-on `assert!`.
`PregolyaError::to_problem()` additionally enforces this binding at emission time, because `component`
is a `pub` field that may be reassigned post-construction (ADR-010 §Decision keeps `component` `pub`).
Purpose: prevents URN namespace aliasing — a `Component::Graph` error with `code: "E-CORE-001"` would
emit `type_uri: "urn:pregolya:error:E-CORE-001"` with `component: "graph"`, producing conflicting
attribution in RFC-7807 responses and monitoring dashboards. The binding applies to all component
variants: named variants (e.g., `Component::Graph` → COMPONENT segment must be `GRAPH`) and Custom
variants (e.g., `Component::Custom("MyExt")` → COMPONENT segment must be `MYEXT`). Both panics are
intentional: they surface a programmer error before a misattributed URN reaches an RFC-7807 response.
Cross-refs: EC-002 (Custom-name charset + collision guards, which also enforce the same binding at
emit-time via `component_lowercase`); BC-2.14.002 {INV-001} (monitoring keys on `type_uri`);
BC-2.14.002 EC-002 (emission-path panic enumeration — documents all three sanctioned to_problem() panic
paths including this EC-007 emit-time binding assert).

**Scope:** EC-007 binds `code`↔COMPONENT only. Consistency of `code` against the category column
of the error taxonomy (each `E-<COMPONENT>-NNN` code maps to a single category) is normative but
NOT enforced at construction or emission time in S-1.01; it is enforced by the code-registry CI
gate in story S-1.02 (VP-BC214001-01). The compensating control for RFC-7807 consumers is
BC-2.14.002 {INV-001}: clients MUST key monitoring and routing on `type_uri`, never `title` or
HTTP status.

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
| VP-BC214001-01 | Every `E-<COMPONENT>-<NNN>` code in error-taxonomy.md is unique (no collision) | `cargo xtask check-error-code-registry` — parses error-taxonomy.md, asserts uniqueness; wired in ci.yml lint-extra with factory-artifacts checkout; delivered in S-1.02 | S-1.02 (code-registry CI gate) |
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
| L2 Domain Invariants | DI-008 (Library Constructor Result Contract), DI-010 (Credential Opacity — `message` MUST NOT contain credentials), DI-014 (Error Propagation (No Silent Swallowing)) |
| NE References | — |
| Priority | P0 |
| Wave | Wave 0 |
| Test Types | U (unit), CI lint |
| Module | pregolya-core |
