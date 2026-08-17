---
document_type: adr
level: L3
adr_id: "010"
slug: error-taxonomy-anyhow-confinement
title: "Error Taxonomy and anyhow Confinement (P-78 / NE-03 / DI-014)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17, D21, D23]
date: "2026-07-14"
subsystems_affected: [SS-14]
supersedes: null
superseded_by: null
version: "1.21"
changelog:
  - "1.21 (burst-308/F-P200-01/2026-08-17): Category Axis Expansion D26 — adjudicate ADR-010 vs ADR-026 conflict on EXEC as 13th category. Decision: Option A — EXEC is a legitimate 13th category (none of CONCURRENCY/INTERNAL/TOOL/VAL fit 'an orchestrated branch returned an error and is being wrapped to identify which branch failed'). (1) Add §Category Axis Expansion (D26) section recording the adjudication, EXEC definition, HTTP mapping (library-layer-only, no new BC-2.14.002 row), and #[non_exhaustive] gate update requirement. (2) PregolyaError struct `category` comment: supersede '12 — unchanged' with '13 — expanded by D26 (EXEC added)'. (3) Component count summary table footer: mark 'Category axis: 12 — unchanged / No new category is warranted' as superseded-through-D23; add D26 expansion row. (4) §Rationale 'No new category was warranted for D21 or D23' — append supersession note referencing D26. POL-1 append-only applied to all three supersession sites."
  - "1.20 (burst-295/F-P186-F3/2026-08-16): Replace `(Wave TBD)` with `(Wave 1)` in §Component Axis Expansion (D23) non-exhaustive gate update requirement. pregolya-tools = SS-23; all SS-23 BCs carry wave: 1; wave is mechanically determinable in scope (CLAUDE.md Rule 6)."
  - "1.19 (burst-290/F-180-06/2026-08-16): Rewrite stale present-tense obligations in §Class 3 adjudication note (~line 178) to past-tense facts. The note formerly claimed `verify-error-notation-canon.sh` gates `FerrochainError` (not `PregolyaError`) and has no Class 3 `::new()` detection — this was the opposite of the current HEAD state. Corrected to: the hook gates `PregolyaError`; `NEW_FORM_VIOLATION` detection for `PregolyaError::new()` in prose contexts was added in burst-287. POL-17 scoping obligation was a separate spec-steward task; corrected note references the obligation as already routed rather than pending."
  - "1.18 (burst-288/F-P177-E01/2026-08-15): Add §Class 1 Scanner Contract to unambiguously specify CLASS1_VIOLATION for devops scanner. (1) Define value-expression-position indicators vs pattern-position indicators in rust fences. (2) State explicitly: adding `..` to a value-expression position occurrence does NOT resolve a Class 1 violation — `#[non_exhaustive]` bars struct-literal construction (E0639) from external crates regardless of `..`; the `..` rest-pattern applies to patterns (Class 2), not to construction literals. (3) CLASS1_VIOLATION remedy is ALWAYS `::new()` replacement. (4) Update §Mechanical Discriminator Step 2 rust-fence branch to check position type BEFORE checking `..`; value-expression position → Class 1 (regardless of `..` presence); pattern position + `..` → Class 2 VALID; pattern position + no `..` → CLASS2_MISSING_REST: add `..`."
  - "1.17 (fix-burst-287/F-P176-C008/2026-08-01): Adjudicate ADR-010 vs POL-17 contradiction (Mechanism 5). Strengthen §Class-3 prohibition: `PregolyaError::new()` is now explicitly FORBIDDEN (not merely 'not used') in Class 3 prose/observation contexts. Add canonical-form summary to §Class-3 header. State rationale for why construction syntax is wrong in description contexts. POL-17 must be corrected by spec-steward to scope its 'allowed construction form' claim to Class 1 contexts only — that correction is outside this ADR's scope."
  - "1.16 (NOTATION-GAP-FIX/D-76-CORR/2026-07-29): Close two Mechanical Discriminator gaps identified in the Wave B pilot batch and correct the authoritative BC violation count. (1) Gap 1 — Unicode ellipsis U+2026 not named as a forbidden elision marker: Class 3 rule and Step 2 discriminator named only `...` (three ASCII dots) as a forbidden field-elision marker; `…` fell into an unnamed branch; pilot Wave B correctly replaced 3 instances in BC-2.08.004 by re-derivation but required per-agent reasoning on each occurrence. Fix: `…` (U+2026) is now a named class, CLASS3_UNICODE_ELLIPSIS_VIOLATION, distinct from CLASS3_ASCII_ELLIPSIS_VIOLATION (`...`); applies when `…` appears in field-elision position (unquoted, not inside a double-quoted string value such as `message: \"…\"`); canonical replacement is `..`; added to both Class 3 normative rule text and Step 2 discriminator. 1 live corpus violation in B2 scope: BC-2.09.007 §Scenario. (2) Gap 2 — Split-line opener form undetectable: discriminator required `PregolyaError {` on a single line; 2 corpus sites open with `PregolyaError` at end-of-line and `{` on the following line (BC-2.08.003 §EC-002 and BC-2.08.007 §PC2); these were invisible to the v1.15 detector. Fix: `spec_region_utils.py` gains `find_pregolya_error_openers(raw_lines)` — returns both single-line openers (form=single) and split-line openers (form=split); a split-line `pub struct PregolyaError` / `{` still classifies EXCLUDED_DECL because the EXCLUDED_DECL check operates on the opener_line content. Step 0, Step 1b, and Step 2 updated. (3) Count correction: the authoritative count recorded as 170 (D-76, v1.15) was complete with respect to the then-current single-line-only detector. With the 2 split-line sites included, the true figure is 172. Reconciliation chain: 144 (discriminator with 4 defects) → 158 (unbounded literal pattern) → 170 (multiline-aware, single-line-only opener) → 172 (split-line opener support included). See §Classification Procedure."
  - "1.15 (FIX-BURST-281-WAVE-A-CORR/D-72/2026-07-29): Correct §Mechanical Discriminator — fix four verified defects in the v1.14 discriminator algorithm. (1) Defect 1 — Multiline span blindspot: the v1.14 grep checked for `..` on the SAME LINE as `PregolyaError {`, failing to detect spans where `..` is on a continuation line. Fix: discriminator now brace-counts the ENTIRE `{ ... }` span (up to 15-line lookahead) using spec_region_utils.py for region context; all classification checks (including the `..` test) operate on the full span, not just the opening line. Confirmed: 43 normative multiline spans in BC corpus, all correctly classified; raw rg count 48 includes 5 `PregolyaError {` pattern-mentions in changelog text that lack a matching `}` in scope (EXCLUDED_NO_CLOSE). (2) Defect 2 — Canon flags its own illustration regions: the discriminator previously flagged 10 lines inside ADR-010's FORBIDDEN-examples block and worked-examples table, making the canon self-flag and forcing a standing WARN on every CI run. Fix: (a) bash/sh fenced blocks that QUOTE the pattern are EXCLUDED_BASH; (b) pattern-name references (bare `PregolyaError {` immediately followed by `` ` ``) are EXCLUDED_PATTERN_REF; (c) doc-comment lines (`///`) inside rust fences are EXCLUDED_DOC_COMMENT; (d) intentional illustration regions marked with `<!-- discriminator:illustration-start -->` / `<!-- discriminator:illustration-end -->` HTML comment pairs are EXCLUDED_ILLUSTRATION per spec_region_utils.py `illustration_exempt_lines()`. Self-test B post-fix: ADR-010 reports ZERO violations. (3) Defect 3 — Declaration/impl forms not excluded: `pub struct PregolyaError {` and `impl PregolyaError {` are now EXCLUDED_DECL in Step 0. (4) Defect 4 (named) — grep-v false-negative class: old `grep -v '\\.\\.'` matched `..` ANYWHERE on the opening line, not just in the PregolyaError span, causing false exclusions when `..` appeared in adjacent fix-instruction text. New discriminator checks `..` in the EXTRACTED SPAN only. Delta decomposition (current corpus): old-style grep gives 169; new discriminator gives 170; delta +1 is entirely Defect 4 (1 BC site where `..` appeared on the opening line outside the span). Effect A (multiline span has `..`, old grep would over-count): 0 — no normative multiline span contains `..` in this corpus. Authoritative BC corpus count: 170 violations (133 Class 3 missing-`..`, 37 Class 3 three-dot ASCII) across 51 files; 14 CLASS3_VALID_COMPLETE; 33 EXEMPT/excluded. Wave B sweep (product-owner) proceeds from the authoritative count of 170."
  - "1.14 (FIX-BURST-281/D-72/2026-07-28): Extend error-construction notation canon — adjudicate all four notation classes and add §Error-Construction Notation Canon section. (1) Class 1 Construction Form: in ```rust fenced blocks, value-expression position, MUST use PregolyaError::new(...); struct literal without `..` is FORBIDDEN (already implicit in v1.13; now a named class with mechanical discriminator). (2) Class 2 Pattern Form: in ```rust blocks, match-arm / matches!() / let-destructuring position, MUST include `..` rest pattern (required by #[non_exhaustive] for external-crate patterns). (3) Class 3 Value-Observation Form: prose, table cells, non-rust fenced formal-statement blocks, doc-comment annotation text — MUST include `..` when any field is elided; `...` (three-dot English prose ellipsis) is FORBIDDEN as field-elision marker in these contexts; PregolyaError::new(...) is NOT used here (it implies construction, not observation). (4) Class 4 Defining-Crate Exception: BC-2.14.001 and BC-2.14.002 ONLY — struct-literal construction permitted inside pregolya-core tests; annotation required per §Canon rule. Defining-crate exception (fix-burst-280-wave-C annotation) RATIFIED: #[non_exhaustive] does not restrict the defining crate; exception is strictly bounded to BC-2.14.001/002. Mechanical discriminator specified for devops-engineer validator. Architecture corpus swept: 19 Class 3 violations corrected (added `..` or replaced `...` with `..`) across ADR-015, ADR-017, verification-architecture, module-decomposition, interface-definitions, VP-003, VP-004, VP-006, VP-009, VP-010, VP-013. Residue: 5 out-of-scope domain-spec/prd sites (business-analyst/product-owner remediation in Wave B); BC corpus 158-site sweep handed to product-owner per §Classification Procedure."
  - "1.13 (FIX-BURST-277-WAVE-B/F-P174-303+F-P174-constructor/2026-07-27): F-P174-303 — adjudicate `context` field (referenced in ADR-014 Decision 5 write-time zero-norm sketch): REJECTED. No `context` field is added to `PregolyaError`. Structured diagnostics such as `document_index` MUST be interpolated into the `message` field using key=value format (e.g., `format!(\"embedding vector has zero L2 norm at write time; document_index={}\", i)`). Rationale: adding `context: Option<serde_json::Map<String, serde_json::Value>>` would pull `serde_json` into the hot path of every `PregolyaError` construction site and bloat the struct; the `message: String` field already carries structured diagnostics in the VSDD corpus via key=value interpolation. ADR-014 Decision 5 pseudocode must be corrected in ADR-014 §Decision-5-pseudocode to use `message` interpolation instead of a phantom `context:` field. F-P174-constructor — add `impl PregolyaError` with `pub fn new(component, category, retry_hint, code, message: impl Into<String>) -> Self` primary constructor (all six fields; `source: None` by default) and `pub fn with_source(self, source: Arc<dyn std::error::Error + Send + Sync>) -> Self` builder (consumes self, returns updated instance). These are the sole sanctioned construction paths; direct struct-literal construction from external crates is barred by `#[non_exhaustive]` (ADR-010 §non-exhaustive-gate/F-P173-619). All spec pseudocode blocks in ADR-010/014/005 that showed struct literals must use `PregolyaError::new(...)` + optional `.with_source(...)` going forward."
  - "1.12 (FIX-BURST-276/F-P173-211+F-P173-619/2026-07-27): F-P173-211 — fix PregolyaError compilability: change `source` field from `Option<Box<dyn std::error::Error + Send + Sync>>` to `Option<Arc<dyn std::error::Error + Send + Sync>>`. Adjudication: option (a) selected over (b) drop-Clone and (c) clone-drops-source. `Arc<dyn Trait>` implements `Clone` (reference-count increment, independent of whether T: Clone), preserving both the derive and the error chain. Option (b) propagates `Arc<PregolyaError>` wrappers to every sharing site, invasively changing call-site API. Option (c) silently drops `source` on clone, violating the production-grade no-silent-failure rule (CLAUDE.md: no silent empty returns where partial-failure should propagate); `retry_hint` and `to_problem()` (BC-2.14.002 RFC-7807 emission) both depend on Clone without losing the causal chain; option (c) breaks both. Propagated to api-surface.md §Error Type (F-P173-202). BC-2.14.001 propagation form (product-owner-owned): `source: Option<Arc<dyn std::error::Error + Send + Sync>>,` with comment `// Causal error chain; MUST NOT be exposed in HTTP responses`. F-P173-619 — add `#[non_exhaustive]` to PregolyaError struct. CLAUDE.md Code Conventions requires `#[non_exhaustive]` on all public API surface types; sibling D21/D23 types all carry it; `PregolyaError` was the sole public error type without it."
  - "1.11 (FIX-BURST-274/timestamp-convention/2026-07-26): Restore frozen original-acceptance timestamp and date per ADR decision-date convention (Gate #28 Rule 5): `timestamp` → `2026-07-14T12:00:00Z`; `date` → `2026-07-14`. Original D17 decision date evidenced by v1.0 changelog. Fields were incorrectly bumped across multiple fix bursts (62672f9, 317b144, f4819b2, 75b0c8a)."
  - "1.10 (FIX-BURST-272/F-P170-07+09+10/2026-07-25): Three targeted fixes. (1) F-P170-07 — E-TMPL-003 description de-minijinjaed: replace 'UndefinedVariable: minijinja strict-undefined mode raises this when a template variable is not in the input map.' with engine-neutral form matching error-taxonomy.md §E-TMPL-003 and ADR-015 Decision 4 universal strict-undefined contract (F-P131-04, burst-226). (2) F-P170-09 — Axis-alignment rationale: replace phantom 'Python REPL' tool with actual ADR-020 Decision 2 inventory (ReadFileTool/WriteFileTool/EditFileTool/ListDirTool — tools::fs; BashTool — tools::shell; GrepTool — tools::search). (3) F-P170-10 — Informational payload fields: off-by-two BC mis-anchor corrected; 'BC-2.23.003/004' → 'BC-2.23.005 PC-2 / BC-2.23.006 PC-2' per error-taxonomy.md §TOOLS E-TOOLS-005/006 anchors."
  - "1.9 (FIX-BURST-270/P1D-168-adjudication/2026-07-25): Retract v1.8 casing canon (F-P167-05) and replace with Direction B (PascalCase). Category enum variants use PascalCase — Category::Val, Category::Auth, Category::Security, etc. The v1.8 note incorrectly mandated SCREAMING_CASE Rust identifiers by conflating the taxonomy code-string column (legitimately ALL-CAPS: VAL, AUTH, etc.) with the Rust variant identifier. Evidence for Direction B: (1) BC-2.14.001 §Rendering Convention explicitly mandates PascalCase for Rust paths; (2) clippy::upper_case_acronyms with -D warnings makes Category::VAL a compile error without a lint exemption; (3) Component variants are uniformly PascalCase (Component::Tmpl, Component::Chkpt) — Category must follow the same convention; (4) wire form uses humanized titles ('Validation', not 'VAL') so no serde rename is needed. Rewrite casing canon note in live body. Downstream architect-owned sites updated in same burst."
  - "1.8 (FIX-BURST-269/F-P167-05/2026-07-25): Add Category casing canon note after PregolyaError struct definition. Category enum variants use SCREAMING_CASE (Category::VAL, Category::AUTH, etc.) — not PascalCase (Category::Val). The canonical codes list at the category comment already used uppercase (VAL | AUTH | …); this note makes the Rust variant casing explicit to prevent future Category::Val drift. Closing adjudication from F-P167-05."
  - "1.7 (FIX-BURST-267/F-P165-01+02/2026-07-25): F-P165-01 — de-label two version-pinned D23 cites to decay-resistant 'as of D23' form: (1) PregolyaError struct component comment '(v1.2 — 17 components)' → '(as of D23 — 17 components)'; (2) Component count summary table row 'v1.2 (D23)' → 'as of D23'. F-P165-02 — restore D21 #[non_exhaustive] gate-count block to historically-correct 13→17 (16 named + Custom) with a forward note 'As of D23, the current value is 18 (17 named + Custom) — see §Component Axis Expansion (D23)'; previous text incorrectly stated 13→18 (skipping the D21-era intermediate), contradicting the D23 §gate update block which correctly shows 17→18."
  - "1.6 (burst-238/2026-07-23): Stale-handoff sweep — rewrite three future-tense PO obligations added in v1.1 (D21) to past-tense facts: (1) SRLZ 'PO must apply Category::Val when authoring BC-2.19.x' → 'PO applied Category::Val (error-taxonomy v1.27/D21)'; (2) VS E-CFG-001 resolution 'PO assigns next available VS sequence number when authoring BC-2.21.x' → 'PO assigned E-VS-003 (error-taxonomy v1.27/D21; anchor BC-2.20.003)'; (3) VS table row 'E-VS-NNN (was E-CFG-001)' → 'E-VS-003 (was E-CFG-001)'; remove 'PO assigns next sequence number' from table cell."
  - "1.5 (burst-234/2026-07-22): PO minted E-TOOLS-009 InvalidRegexPattern (VAL/Never; fields pattern: String + compile_error: String; anchor BC-2.23.006 PC-4/EC-002/TV-003 — invalid-regex path in GrepTool). Add E-TOOLS-009 row to TOOLS component table. Update Source/Origin cite range 001..007 → 001..009 (TD-VSDD-060 sibling sweep). TOOLS namespace is now 9 codes (001..009); component count and #[non_exhaustive] gate count unchanged."
  - "1.4 (burst-233/2026-07-22): F-P133-03 sibling sweep — add E-TOOLS-008 FileIoError to TOOLS component table (category TOOL, RetryHint Maybe); covers OS-level I/O errors during file tool execution; wraps std::io::ErrorKind; anchor BCs: BC-2.23.001–004, BC-2.23.006. Component count and #[non_exhaustive] gate count unchanged (TOOLS already registered as component 17 in v1.3; new code is within existing component)."
  - "1.3 (burst-232/2026-07-22): D23 — register TOOLS as component 17 (pregolya-tools, SS-23). Component axis 16→17. E-TOOLS-001..007 adjudicated (codes coined by error-taxonomy v1.31 during D23 BC authoring). E-TOOLS-004 (BashTimeout) carries RetryHint::Never diverging from the TIMEOUT category default (Later); rationale in §Component Axis Expansion (D23). E-TOOLS-005 (BashOutput.truncated) and E-TOOLS-006 (GrepResult.capped) are informational payload fields, not PregolyaError Err returns — they are outside the component×category axis. #[non_exhaustive] gate count 17→18."
  - "1.2 (burst-225/2026-07-21): F-P130-07 sibling sweep — correct stale E-EMBED-001 rationale prefix in EMBED component table: `DimensionMismatch:` → `EmbeddingDimensionMismatch:` per error-taxonomy v1.29 (PO renamed to distinguish from E-VS-002 which retains bare `DimensionMismatch:`)."
  - "1.1 (D21/2026-07-20): Component axis expanded from 12 → 16 by adjudicating error codes introduced in ADR-014 (VectorStore), ADR-015 (Prompt Templates), ADR-016 (lc-JSON), and ADR-017 (Embeddings). Four new components added: TMPL (pregolya-prompts), SRLZ (pregolya-core::serializable), VS (pregolya-vectorstores), EMBED (pregolya-core::embeddings + providers). Category axis unchanged at 12. E-CFG-001 (VectorStoreRetriever config) reassigned to E-VS-NNN — no CFG component created. ADR-016 category error corrected: 'Serialization' → VAL. #[non_exhaustive] gate count 13 → 17. All four new components are library-layer only; no RFC-7807 status rows needed in BC-2.14.002."
  - "1.0 (D17/2026-07-14): Initial ADR — anyhow confinement rules, PregolyaError at all library boundaries, thiserror for internal errors, CI enforcement via cargo xtask deny-anyhow-in-lib."
---

# ADR-010: Error Taxonomy and anyhow Confinement

**Status:** Accepted

## Context

adk-rust uses `anyhow::Error` at the library boundary in several places, losing structured
error information for callers (P-78 pattern to avoid). DI-014 mandates structured error
propagation with no silent None returns. BC-2.14.001–006 specify the PregolyaError model.

This ADR specifies: when is `anyhow` permitted, where is it banned, and how are crate
boundaries enforced.

## Decision: PregolyaError at all library boundaries; anyhow permitted only in binaries

**Rule:** `anyhow::Error` MUST NOT appear in any `pub` function signature in any library
crate. All public functions return `Result<T, PregolyaError>`.

**PregolyaError structure (BC-2.14.001):**

```rust
#[non_exhaustive]
#[derive(Debug, Clone)]
pub struct PregolyaError {
    pub component: Component,     // authoritative list lives in error-taxonomy.md §Components; enum reproduced here for the PregolyaError type definition (as of D23 — 17 components): CORE | GRAPH | CHKPT | SERVER | PROV | MCP | SPLIT | SBXD | RETRY | CRON | MEMORY | BUDGET | TMPL | SRLZ | VS | EMBED | TOOLS
    pub category: Category,       // canonical Category Codes (13 — expanded by D26: EXEC added; see §Category Axis Expansion (D26)): VAL | AUTH | RATE | TIMEOUT | TRANSPORT | INTERNAL | DURABILITY | POLICY | TOOL | CONCURRENCY | SECURITY | TENANCY | EXEC
    pub retry_hint: RetryHint,    // canonical: Never | Maybe | Later(Duration)
    pub code: &'static str,       // "E-GRAPH-001", "E-CHKPT-002", "E-TMPL-001", "E-VS-001", etc.
    pub message: String,          // Human-readable; MUST NOT contain credentials
    pub source: Option<Arc<dyn std::error::Error + Send + Sync>>,  // Causal error chain; MUST NOT be exposed in HTTP responses; Arc (not Box) preserves Clone
}

impl PregolyaError {
    /// Primary constructor. All fields required; `source` defaults to `None`.
    /// Use `.with_source(arc)` to chain a causal error.
    ///
    /// This is the ONLY sanctioned construction path from external crates.
    /// `#[non_exhaustive]` bars struct-literal construction (E0639) outside pregolya-core.
    pub fn new(
        component: Component,
        category: Category,
        retry_hint: RetryHint,
        code: &'static str,
        message: impl Into<String>,
    ) -> Self {
        Self { component, category, retry_hint, code, message: message.into(), source: None }
    }

    /// Builder: attach a causal error chain. Consumes `self`; returns updated instance.
    /// The causal chain is available via `std::error::Error::source()` for logging.
    /// MUST NOT be exposed in HTTP responses (DI-010 credential-leak risk).
    pub fn with_source(self, source: Arc<dyn std::error::Error + Send + Sync>) -> Self {
        Self { source: Some(source), ..self }
    }
}
```

**F-P174-303 adjudication — no `context` field:** A phantom `context: { "document_index": N }` field appeared in ADR-014 Decision 5 pseudocode but does not exist on `PregolyaError`. The resolution is REJECTION of a new `context` field. Structured diagnostics such as `document_index` MUST be interpolated into the `message` field using key=value notation: `format!("embedding vector has zero L2 norm at write time; document_index={}", i)`. No `serde_json::Map` dependency is incurred; the 6-field struct is final. ADR-014 Decision 5 is corrected per the ADR-014 F-P174-303 adjudication.

**Category casing canon (FIX-BURST-270 adjudication, retracted v1.8/F-P167-05):** `Category` enum variants use **PascalCase** — `Category::Val`, `Category::Auth`, `Category::Security`, `Category::Internal`, etc. The taxonomy code-string column (`VAL | AUTH | RATE | …`) is ALL-CAPS documentation shorthand and is **distinct** from the Rust variant identifier. Rendering rule: in BC/spec prose and table cells use the taxonomy codes (`VAL`, `AUTH`, `category: DURABILITY`); in Rust code blocks and formal postconditions use the PascalCase enum path (`Category::Val`, `Category::Auth`, `Category::Durability`). The v1.8 note incorrectly conflated these two representations; it is hereby retracted. The `Component` variants follow the same PascalCase rule (`Component::Chkpt`, `Component::Tmpl`, `Component::Core`). No serde rename is needed because the RFC-7807 wire form uses humanized titles (`"Validation"`, `"Authentication"`) not taxonomy codes.

## Error-Construction Notation Canon (D-72 extension, v1.14)

This section governs how `PregolyaError` values are expressed across all VSDD artifacts. The canon covers four notation classes. A fifth special case (Type Schema Form) is exempt.

### Class 0 — Type Schema Form (exempt)

A field-and-type listing showing the struct's shape: `PregolyaError { component: Component, category: Category, … }`. Not a value expression, pattern, or observation. No restriction applies. Mechanical exclusion: matches `PregolyaError { component: Component,` (field types, not field values).

### Class 1 — Construction Form (MUST use `::new()`)

**Where:** Inside a ` ```rust ` fenced code block, in a VALUE EXPRESSION position — after `return Err(`, used as a function return, after `let x =`, or any position where the code is meant to PRODUCE a PregolyaError value.

**Rule:** MUST use `PregolyaError::new(component, category, retry_hint, code, message)` + optional `.with_source(arc)`.
<!-- discriminator:illustration-start -->
Struct literal `PregolyaError { field: val, … }` without `..` in a value-expression position is FORBIDDEN.
<!-- discriminator:illustration-end -->

**Rationale:** This is compilable code targeting external crates. `#[non_exhaustive]` bars struct-literal construction (E0639) outside `pregolya-core`. Spec must match production requirements.

**Class 1 Scanner Contract (burst-288, F-P177-E01):**

CLASS1_VIOLATION triggers when: (a) the occurrence is inside a rust-fenced code block (language = "rust"), AND (b) the occurrence is in value-expression position, AND (c) the occurrence is not already a PregolyaError::new constructor call.

<!-- discriminator:illustration-start -->
**Value-expression position indicators** (code PRODUCES a value):
- After `return Err(` — e.g., `return Err(PregolyaError { code: "E-XXX", .. })`
- After `let <name> =` (not a destructuring pattern) — e.g., `let err = PregolyaError { code: "E-XXX", .. };`
- After `=` in an assignment expression
- As a function's direct return expression (implicit return at end of block)
- Inside `Err(...)` or `Ok(...)` as a wrapping constructor argument

**Pattern position indicators** (code MATCHES a value, not PRODUCES one):
- Inside a `match` arm (after `=>` or before `=>` on the LHS)
- Inside `matches!(expr, Err(PregolyaError { code: "E-XXX", .. }))` — the second argument is always a pattern
- After `let ... =` in a destructuring binding (the LHS `PregolyaError { field, .. }` is a pattern)
<!-- discriminator:illustration-end -->

**Critical distinction — adding `..` does NOT resolve a Class 1 violation:**
`PregolyaError { code: "E-X", .. }` in value-expression position is still a CLASS1_VIOLATION. `#[non_exhaustive]` bars struct-literal construction from external crates via E0639 (struct expression); this error fires regardless of `..` presence. The `..` rest-pattern applies only to struct patterns (pattern position, Class 2) — not to struct literal construction. A devops scanner that checks only for `..` presence will produce false negatives (CLASS1_VIOLATION occurrences with `..` classified as valid).

**CLASS1_VIOLATION remedy is ALWAYS `::new()` replacement.** Adding `..` converts the syntactic form but does NOT make the construction valid from external crates — it merely converts a Class 2 missing-`..` concern into a Class 1 violation with `..` present. The only correct remediation is:
<!-- discriminator:illustration-start -->
```
PregolyaError { .. }  →  PregolyaError::new(component, category, retry_hint, code, message)
```
<!-- discriminator:illustration-end -->
Adding `..` to satisfy a different lint (e.g., a Class 3 missing-`..` check) when the occurrence is in value-expression position is the WRONG fix. The position determines the class; the class determines the remedy.

### Class 2 — Pattern Form (MUST include `..`)

**Where:** Inside a ` ```rust ` fenced code block, in a PATTERN EXPRESSION position — in `match` arms (after `=>`), inside `matches!()`, in `let … =` destructuring, or equivalent.

**Rule:** MUST include `..` rest pattern. Minimum form: `PregolyaError { code: "E-XXX", .. }`. Additional fields (category, component) before `..` are permitted for documentation clarity. The `..` is REQUIRED because `#[non_exhaustive]` bars exhaustive patterns from external crates (E0008 without `..`).

**Compliant examples:**
```rust
Err(PregolyaError { code: "E-SBXD-001", .. }) => {}                          // match arm
matches!(result, Err(PregolyaError { code: "E-VS-001", .. }))                 // matches! arg
matches!(result, Err(PregolyaError { code: "E-TMPL-001", category: Category::Security, .. }))  // with extra field
```

### Class 3 — Value-Observation Form (MUST include `..` when eliding fields)

**Where:** Prose, Markdown table cells, non-rust fenced blocks (formal statements, mathematical notation), doc-comment annotation text, inline backtick-quoted expressions in prose that are NOT inside a ` ```rust ` fence.

**Canonical form:** `PregolyaError { code: "E-XXX-001", .. }` — or with additional discriminating fields before `..` for clarity.

**Rule:**
- MUST include `..` when any of the 5 non-source fields (component, category, retry_hint, code, message) is omitted.
- Full-field observations (all 5 fields present) need not add `..` but may.
- Field names use taxonomy codes (ALL-CAPS: `TOOL`, `INTERNAL`, `MCP`) per rendering convention; PascalCase Rust identifiers (`Category::Val`) are also permitted.
- `...` (three ASCII dots — English prose ellipsis) is FORBIDDEN as a field-elision marker in value-observation contexts. Use `..` (two dots, Rust rest-pattern notation) instead. Discriminator sub-class: CLASS3_ASCII_ELLIPSIS_VIOLATION.
- `…` (U+2026 Unicode ellipsis) is FORBIDDEN as a field-elision marker in value-observation contexts. Use `..` instead. **Field-elision position** means `…` appears after `, ` (comma-whitespace) or `{ ` (brace-whitespace) in the span text — i.e., in the position where `..` would appear in a Rust rest pattern. A `…` appearing after `: ` (as a value placeholder, e.g., `component: …`) is NOT in field-elision position and does NOT constitute a violation. A `…` inside a quoted string value (e.g., `message: "…"`) is also NOT a violation. Discriminator sub-class: CLASS3_UNICODE_ELLIPSIS_VIOLATION — a distinct sub-class from CLASS3_ASCII_ELLIPSIS_VIOLATION.
- **`PregolyaError::new(...)` is FORBIDDEN in Class 3 contexts.** (adjudicated fix-burst-287 / F-P176-C008)

**Rationale for the `::new()` prohibition in Class 3:** `PregolyaError::new()` is a five-argument constructor call expression — it is syntax for PRODUCING a value, not for DESCRIBING one. In prose, table cells, and formal statement blocks, the intent is to describe what error a function returns, not to write callable code. Using `::new()` in these contexts is misleading in three ways: (1) it implies the reader should call the constructor at runtime, when the author's intent is only to identify the error code; (2) the five positional arguments obscure the discriminating field (`code:`) behind `component`, `category`, and `retry_hint` — making prose harder to scan; (3) it bypasses the `..` rest-pattern discipline that makes Class 3 observations consistent with the `#[non_exhaustive]` contract across all contexts. The `{ code: "E-XXX-001", .. }` form is correct for Class 3 because it is observational in structure: it describes a field-value binding, not a function call.

**Adjudication note (F-P176-C008 / fix-burst-287):** Prior fix-bursts optimised for `grep 'PregolyaError {' returns zero` and may have replaced Class 3 struct-literal observations with `::new()` calls to satisfy that lint. Those replacements were incorrect substitutions: they transformed a Class 3 violation (missing `..`) into a different Class 3 violation (`::new()` in prose context). The correct fix for a Class 3 violation is always to add `..`, not to replace the observation form with a constructor. POL-17 asserts `PregolyaError::new()` is "an allowed construction form" — that claim is correct for Class 1 (rust fence, value-expression position) but incorrect as a general statement applicable to Class 3. POL-17 was corrected by spec-steward (policies.yaml v1.1) to scope the `::new()` allowed-construction claim to Class 1 contexts only. `verify-error-notation-canon.sh` gates `PregolyaError` (not `FerrochainError`) and includes `NEW_FORM_VIOLATION` detection for `PregolyaError::new()` in prose contexts — added in burst-287 as the devops half of the F-P176-C008 fix.

**Compliant examples (prose / table cell / formal-statement):**

| Form | Example | Notes |
|------|---------|-------|
| Single-field code | `Err(PregolyaError { code: "E-MCP-001", .. })` | `..` required |
| Two-field code+category | `Err(PregolyaError { code: "E-TOOLS-007", category: VAL, .. })` | `..` required |
| Full-field (no `..` needed) | `Err(PregolyaError { component: MCP, category: TOOL, retry_hint: Never, code: "E-MCP-001", message: "…" })` | all 5 fields |
| Formal statement block | `cosine(a, b) == Err(PregolyaError { code: "E-VS-001", .. })` | inside non-rust fence |

<!-- discriminator:illustration-start -->
**FORBIDDEN examples:**
- `Err(PregolyaError { code: "E-X" })` — missing `..` (partial fields)
- `Err(PregolyaError { code: "E-X", ... })` — `...` three-dot form
- `Err(PregolyaError { category: INTERNAL, code: E-CORE-006, message: "…" })` — no `..`, partial fields
<!-- discriminator:illustration-end -->

### Class 4 — Defining-Crate Exception (RATIFIED, D-72)

**Where:** Rust code blocks in artifacts that DEFINE `PregolyaError` itself. **Scope: BC-2.14.001 and BC-2.14.002 ONLY.**

**Rule:** Struct-literal construction with all 5 non-source fields is PERMITTED because `#[non_exhaustive]` does not restrict the defining crate's own code. The Rust Reference: "Outside of the crate in which a non-exhaustive type is defined, construction of that type is not possible."

**RATIFICATION of fix-burst-280-wave-C annotation:** The annotation applied to BC-2.14.001 PC1, TV-001 Notes, TV-002 Notes, and BC-2.14.002 TV table in fix-burst-280-wave-C is hereby ADR-backed. The exception is strictly bounded — no other BC or ADR defines `PregolyaError`, so no other "defining-crate exception" exists.

**Required annotation at each site:** `// defining-crate: struct-literal permitted (tests run inside pregolya-core; #[non_exhaustive] does not bar same-crate construction)`

### Mechanical Discriminator

The discriminator classifies every `PregolyaError {` occurrence in a VSDD artifact file.
Uses `spec_region_utils.py` `changelog_exempt_lines()` and `illustration_exempt_lines()` for region-exempt logic.

**Step 0 — Pre-filter: excluded forms (skip all further classification)**

| Excluded Form | Tag | Reason |
|---------------|-----|--------|
| Lines in YAML frontmatter or `## Changelog` body sections | `EXEMPT` | Historical record per `spec_region_utils.py` `changelog_exempt_lines()` |
| Lines inside `<!-- discriminator:illustration-start -->` … `<!-- discriminator:illustration-end -->` regions | `EXCLUDED_ILLUSTRATION` | Intentional FORBIDDEN-form examples in canon documents; documentation illustrations, not normative assertions. Detected via `spec_region_utils.py` `illustration_exempt_lines()` (Defect 2 complete fix) |
| `pub struct PregolyaError {` | `EXCLUDED_DECL` | Struct declaration — defining form, not a value expression (Defect 3 fix) |
| `impl PregolyaError {` | `EXCLUDED_DECL` | Impl block opening — not a value expression (Defect 3 fix) |
| `pub struct PregolyaError` (line N) / `{` at start of line N+1 | `EXCLUDED_DECL` | Split-line struct declaration (Gap 2 fix). Detected via `find_pregolya_error_openers()` form="split"; EXCLUDED_DECL classification uses opener_line content, not brace_line |
| `impl PregolyaError` (line N) / `{` at start of line N+1 | `EXCLUDED_DECL` | Split-line impl block opening (Gap 2 fix). Same opener_line content rule |
| `PregolyaError { component: Component,` | `CLASS0_EXEMPT` | Type Schema Form — field-type listing, not a value expression |
| Lines inside a ` ```bash ` or ` ```sh ` fence | `EXCLUDED_BASH` | Bash/sh fences quote the pattern (grep command examples); they do not assert it (Defect 2 fix) |
| `PregolyaError {` immediately followed by `` ` `` (no closing `}` in scope) | `EXCLUDED_PATTERN_REF` | Pattern-name reference — names the occurrence pattern with no value (Defect 2 fix) |
| Lines starting with `///` inside a ` ```rust ` fence | `EXCLUDED_DOC_COMMENT` | Doc comment lines are documentation text, not normative Rust code |

**Step 1 — Identify fence context**

At the line of the `PregolyaError {` occurrence (after Step 0 filtering):
- Inside a ` ```rust ` fence? → `rust_fence = true`
- Inside a non-rust, non-bash fence? → `formal_stmt = true`
- Otherwise (prose, table cell, inline backtick, doc comment outside fence): `prose = true`

**Step 1b — Determine the occurrence span (Defect 1 fix: multiline-aware; Gap 2 fix: split-line opener)**

The occurrence span begins at the `PregolyaError` identifier and ends at the matching `}`,
found by brace-counting. An opener may have arbitrary whitespace — including a newline —
between the identifier and the `{`. Use `spec_region_utils.py`
`find_pregolya_error_openers(raw_lines)` which returns both forms:

- **Single-line opener** (form="single"): `PregolyaError {` on one line — `opener_line == brace_line`
- **Split-line opener** (form="split"): `PregolyaError` at end of line N, `{` at start of line N+1 — `brace_line == opener_line + 1`

For both forms, the span begins at `opener_line` and the brace-count starts from `brace_line`.
For EXCLUDED_DECL classification, the check examines the **opener_line** content (the line
containing `PregolyaError`): if it contains `pub struct PregolyaError` or
`impl PregolyaError`, classify EXCLUDED_DECL regardless of single vs split form.

Apply `changelog_exempt_lines()` and `illustration_exempt_lines()` for region context before
classifying. Count `{` and `}` characters (up to 15-line lookahead) to determine the span end.

**Step 2 — Classify and gate**

```
IF rust_fence:
  # Determine position type BEFORE checking `..`.
  # `..` presence alone is NOT sufficient to classify as Class 2 VALID —
  # value-expression position is CLASS1_VIOLATION regardless of `..`.
  Determine position_type:
    VALUE_EXPRESSION: span is preceded (within 3 lines before opener) by `return Err(`,
      `let <ident> =` (non-destructuring), plain `=` assignment, or the span is the
      trailing expression in a block. Also: span is directly inside `Err(...)` or `Ok(...)`.
    PATTERN_POSITION: span appears on the LHS of a match arm (before `=>`), inside
      `matches!(`, or after `let ... =` in a destructuring binding (LHS pattern).
    UNKNOWN: cannot determine from context (treat as VALUE_EXPRESSION; safe over-flagging)

  IF position_type == VALUE_EXPRESSION:
    IF file is BC-2.14.001 or BC-2.14.002:
      → Class 4 VALID (defining-crate exception; verify // defining-crate annotation present)
    ELSE:
      → Class 1 VIOLATION: must use PregolyaError::new constructor (see §Class-1)
      NOTE: presence of `..` in value-expression position does NOT change this classification.
      `PregolyaError { .., field: val }` in value-expression is still E0639 from external crates.
      Remedy: replace entire `PregolyaError { .. }` literal with PregolyaError::new call.

  IF position_type == PATTERN_POSITION:
    IF occurrence span contains `..` (two-dot rest pattern, not part of `...`):
      → Class 2 VALID
    ELSE:
      → CLASS2_MISSING_REST: missing `..` rest pattern in pattern context.
      Remedy: add `..` before closing `}` of the pattern.

IF formal_stmt OR prose:
  IF span contains `..` (two-dot rest pattern, not part of `...`):
    → Class 3 VALID
  IF span contains `...` (three ASCII dots, no `..` present):
    → CLASS3_ASCII_ELLIPSIS_VIOLATION: replace `...` with `..`
  IF span matches `,\s*…` or `{\s*…` (U+2026 in field-elision position: after comma-whitespace
    or brace-whitespace) AND span does NOT contain `..`:
    → CLASS3_UNICODE_ELLIPSIS_VIOLATION: replace `…` with `..`
    NOTE: `…` after `: ` (value placeholder, e.g., `component: …`) and `…` inside a quoted
    string (e.g., `message: "…"`) do NOT trigger this sub-class. Field-elision position is
    defined by the `, …` / `{ …` pattern only. CLASS3_UNICODE_ELLIPSIS_VIOLATION is a distinct
    tag from CLASS3_ASCII_ELLIPSIS_VIOLATION; validators MUST report them separately.
  IF span contains neither `..` nor `...` AND span does NOT match the `…`-in-elision-position
    pattern AND partial fields (not all 5: component, category, retry_hint, code, message):
    → Class 3 VIOLATION: add `..`
  IF span contains neither `..` nor `...` AND span does NOT match the `…`-in-elision-position
    pattern AND all 5 non-source fields present:
    → Class 3 VALID (complete observation)
```

**Quick sweep commands (reference only — full discriminator requires span-based check):**

For a fast scan of Class 3 missing-`..` violations (excludes declaration/impl/bash forms):
```bash
rg -n 'PregolyaError \{' <file> \
  | grep -v 'pub struct PregolyaError' \
  | grep -v 'impl PregolyaError' \
  | grep -v 'component: Component'
# Then apply Step 1b span check: inspect each result's full span for `..`
# (single-line results without `..` are violations; multiline spans require manual inspection)
```

For three-dot violations (full-file scan):
```bash
rg -U --multiline -n 'PregolyaError \{[^}]*\.\.\.[^}]*\}' <file>
```

For the authoritative corpus-wide count use the Python discriminator that imports
`spec_region_utils.py` and performs proper span extraction (see FIX-BURST-281-WAVE-A-CORR
discriminator script). The quick-sweep grep is not authoritative because `..` may appear
elsewhere on a violation's line (in fix-instruction text like "add `..`"), causing false
exclusions.

### Classification Procedure for Product-Owner BC Sweep (Wave B)

**Authoritative count (NOTATION-GAP-FIX, split-line-aware discriminator):** 172 violations
across 51 of 60 BC files.

**Count reconciliation chain (each step encodes a named detector defect):**

| Count | Detector version | Delta from prior | Defect closed |
|-------|-----------------|------------------|---------------|
| 144 | v1.13 (same-line grep, 4 defects active) | — | baseline |
| 158 | v1.14 (unbounded field-bearing literal pattern) | +14 | four-defect discriminator → multiline-aware |
| 170 | v1.15 (multiline-aware, single-line-only opener) | +12 | Defect 4 grep-v false-negative (BC-2.11.003) |
| **172** | **v1.16 (split-line opener support)** | **+2** | **Gap 2 — 2 split-line sites (BC-2.08.003 §EC-002, BC-2.08.007 §PC2)** |

The count of 170 (D-76 / v1.15) was complete with respect to the then-current single-line-only
detector. The delta +2 is exactly the 2 split-line sites that were invisible to that detector.

For each of the 172 `PregolyaError` violation sites across 51 BC files:

1. **Determine context** (prose / formal-statement block / rust fence / defining-crate).
2. **Apply Step 2 rules above.**
3. **For Class 3 violations** (the expected majority): add `..` before the closing `}`, or replace `...`/`…` with `..` when an ellipsis form is the violation.
<!-- discriminator:illustration-start -->
   - `PregolyaError { code: "E-X" }` → `PregolyaError { code: "E-X", .. }`
   - `PregolyaError { component: MCP, category: TOOL, code: "E-X", message: "…" }` → add `, ..` before `}`
   - `PregolyaError { code: "E-X", ... }` → `PregolyaError { code: "E-X", .. }`  (CLASS3_ASCII_ELLIPSIS_VIOLATION)
   - `PregolyaError { category: TRANSPORT, … }` → `PregolyaError { category: TRANSPORT, .. }`  (CLASS3_UNICODE_ELLIPSIS_VIOLATION)
<!-- discriminator:illustration-end -->
4. **For Class 1 violations** in rust fences (construction without `..`): convert to `PregolyaError::new(...)`.
5. **For Class 4 sites** (BC-2.14.001/002, already annotated by fix-burst-280): no change required.

**Worked examples from the corpus:**

<!-- discriminator:illustration-start -->
| BC Site Pattern | Context | Classification | Fix |
|----------------|---------|---------------|-----|
| `Err(PregolyaError { component: MCP, category: TOOL, code: E-MCP-001, message: "..." })` | Prose bullet | Class 3 VIOLATION | Add `..`; fix `...` → `..` in message; quote code string |
| `PregolyaError { code: "E-SBXD-001" }` | Table cell | Class 3 VIOLATION | Add `..` |
| `Err(PregolyaError { code: "E-VS-001" })` | Source Contract bullet | Class 3 VIOLATION | Add `..` |
<!-- discriminator:illustration-end -->
| `matches!(result, Err(PregolyaError { code: "E-X", .. }))` | ```rust fence, matches! | Class 2 VALID | No change |
| `Err(PregolyaError { code: "E-X", .. }) => {}` | ```rust fence, match arm | Class 2 VALID | No change |
| `PregolyaError { component: …, category: …, retry_hint: …, code: "E-X", message: "…" }` | ```rust fence, construction | Class 1 VIOLATION | Use `::new(...)` |
| (BC-2.14.001 TV-001) `PregolyaError { component: Component::Core, category: Category::Val, retry_hint: RetryHint::Never, code: "E-X", message: "…", source: None }` | ```rust fence, construction, with annotation | Class 4 VALID | No change |

**anyhow confinement rules:**
1. Library crates (`pregolya-*`): `anyhow` is NOT a dependency. ZERO uses.
2. `xtask` (binary): `anyhow` is permitted (CLI tooling; errors are human-facing).
3. Integration test binaries: `anyhow` is permitted for test harness convenience.
4. Example binaries: `anyhow` is permitted.

**CI enforcement:** `cargo xtask deny-anyhow-in-lib` (custom Semgrep rule) scans
`src/` in all library crates for `anyhow` imports. Fails CI on any finding.

**Internal error conversion:** Library crates use `thiserror` for internal error types
that convert to `PregolyaError` at the crate boundary. `thiserror` is permitted in
library crates; `anyhow` is not.

**Scope note:** NE-16 in the PRD refers to macOS Seatbelt (BC-2.13.006); it does NOT
govern anyhow confinement. This ADR's authority derives from P-78 (adk-rust
`MistralRsError::Other(#[from] anyhow::Error)` must-not-inherit pattern — the sole
genuine anyhow public-signature leak per CERTIFICATION-REPORT W-04), DI-014 (no silent
error swallowing), and the BC-2.14.003 CI lint gate.

## Component Axis Expansion (D21) — 12 → 16

D21 (burst 216, 2026-07-20) introduced four new pregolya subsystems via ADR-014/015/016/017,
each coining new error code prefixes. This section records the adjudicated mapping for each
new prefix. The authoritative component list grows from 12 to 16; the category axis is
**unchanged at 12**.

### Axis-alignment precedent

The existing 12 components follow a mixed-alignment model:
- **Crate-aligned (one component per crate):** CORE, GRAPH, CHKPT, SERVER, MCP, SPLIT, SBXD, MEMORY.
- **Cross-crate concern (one component spanning multiple crates):** PROV spans
  pregolya-openai, pregolya-anthropic, pregolya-ollama.
- **Intra-crate logical subsystem (own component prefix within a host crate):** RETRY
  (pregolya-core retry combinator), CRON (pregolya-server scheduler), BUDGET
  (pregolya-graph budget governance). This pattern — explicitly labeled in error-taxonomy.md —
  is the governing precedent for SRLZ below.

### New components (D21 adjudication)

#### TMPL — pregolya-prompts (SS-18, new crate)

`pregolya-prompts` is the 19th published crate (ADR-015 Decision 1). New crate → new
component. Canonical abbreviation: **TMPL** (as coined by ADR-015).

| Code | Category | Rationale |
|------|----------|-----------|
| E-TMPL-001 | SECURITY | InjectionAttempt: untrusted variable substituted into TrustRequired (SystemMessage) slot — prompt injection attack vector, not a policy violation. SECURITY per authorization-failure categorization rule: bypass enables concrete attack. |
| E-TMPL-002 | VAL | SystemSlotPolicy: construction-time rejection of TrustAll policy on a SystemMessage slot. Input constraint violation at template-build time. |
| E-TMPL-003 | VAL | UndefinedVariable: engine-neutral — raised by both the f-string (default) and jinja2 engines when a template variable is referenced in the template string but absent from the input variable map. Input constraint violation at render time. Anchor: BC-2.18.001 (ADR-015 Decision 4 universal strict-undefined contract). |

`Component::Tmpl` ↔ `TMPL` in prose/code.

#### SRLZ — pregolya-core::serializable (SS-19, intra-core module)

ADR-016 Decision 1 explicitly places `core::serializable` **as a module within pregolya-core**
(no new crate). The RETRY / CRON / BUDGET precedent governs: an intra-crate logical subsystem
with a distinct behavioral domain gets its own component prefix. Serialization registry
errors are categorically distinct from core type-construction errors (E-CORE-*).
Canonical abbreviation: **SRLZ** (as coined by ADR-016).

**Category correction:** ADR-016 used `category: Serialization` — this is not one of the
12 canonical categories. Both E-SRLZ codes are correctly **VAL**: the Reviver is rejecting
input JSON whose `id` field references an unknown or unsupported type. Callers provided
bad input. The PO applied `Category::Val` (not a new Serialization category) when
authoring BC-2.19.x and the error-taxonomy rows for SRLZ (error-taxonomy v1.27/D21; E-SRLZ-001/002 minted as VAL).

| Code | Category | Rationale |
|------|----------|-----------|
| E-SRLZ-001 | VAL | UnknownSerializable: type id not in registry — caller provided lc-JSON with an unrecognized type path. Input validation failure. |
| E-SRLZ-002 | VAL | UnsupportedSerializable: langchain-monolith type not ported to pregolya — known-but-unsupported type referenced. Input validation failure. |

`Component::Srlz` ↔ `SRLZ` in prose/code.

#### VS — pregolya-vectorstores (SS-21, new crate)

`pregolya-vectorstores` is the 20th published crate (ADR-014 Consequences). New crate →
new component. Canonical abbreviation: **VS** (as coined by ADR-014).

**E-CFG-001 resolution:** The PO flagged `E-CFG-001` (VectorStoreRetriever config
validation) as a possible collision. There is no existing CFG namespace (no collision).
However, no CFG component is created. Configuration-validation errors for a given
component belong to that component's namespace — this is the universal pattern:
E-RETRY-004 (RetryPolicy config, RETRY), E-SBXD-006 (SandboxConfig allowlist, SBXD),
E-SPLIT-001/002 (TextSplitter config, SPLIT). VectorStoreRetriever config validation
errors are therefore **E-VS-NNN** codes, not E-CFG-NNN. The PO assigned E-VS-003 as the next
available VS sequence number (error-taxonomy v1.27/D21; anchor BC-2.20.003).

| Code | Category | Rationale |
|------|----------|-----------|
| E-VS-001 | VAL | ZeroNormVector: cosine similarity guard — zero-length embedding vector produces NaN; caller or embedding backend returned an invalid vector (ADR-014 hardening note). |
| E-VS-003 (was E-CFG-001) | VAL | VectorStoreRetriever config validation (k, fetch_k, lambda_mult range checks). Assigned E-VS-003 (error-taxonomy v1.27/D21; anchor BC-2.20.003). No CFG component. |

`Component::Vs` ↔ `VS` in prose/code.

#### EMBED — pregolya-core::embeddings (SS-22, core trait + provider impls)

The `Embeddings` trait lives in pregolya-core (`core::embeddings`, ADR-017 Decision 1).
Provider implementations live in pregolya-openai and pregolya-ollama — the same
cross-crate-concern pattern as PROV. However EMBED is distinct from PROV: PROV covers
LLM generation errors; EMBED covers embedding dimensionality and batch contract errors.
The trait is core-resident; errors originate from the contract check layer.
Canonical abbreviation: **EMBED** (as coined by ADR-017).

| Code | Category | Rationale |
|------|----------|-----------|
| E-EMBED-001 | VAL | EmbeddingDimensionMismatch: embed_documents or embed_query returned vectors of inconsistent length — violates the dimensionality contract (DI-014 / ADR-017 Decision 2). Input or provider error. |

`Component::Embed` ↔ `EMBED` in prose/code.

### #[non_exhaustive] gate update requirement

The `Component` enum is a public API surface type and carries `#[non_exhaustive]`.
Adding 4 variants triggers the gate update rule from CLAUDE.md: **update ALL three locations**
when the non-exhaustive gate grows:

1. **Gate crate** — `tests/external/<gate-name>/`: add `Component::Tmpl`, `Component::Srlz`,
   `Component::Vs`, `Component::Embed` to the expected symbol list.
2. **Expected count constant** — update from 13 (12 named + `Custom`) to **17**
   (16 named + `Custom`). As of D23, the current value is 18 (17 named + `Custom`) — see §Component Axis Expansion (D23).
3. **Expected symbol list** — add the four new variant symbols.

The implementer who creates `pregolya-core/src/error.rs` (Wave 0) owns this gate update.

### RFC-7807 status mapping (BC-2.14.002)

All four new components are **library-layer only**. None surfaces directly as an HTTP
terminal response from pregolya-server in v1. Categorical fallbacks apply if ever
surfaced directly (SECURITY→403, VAL→400) but no per-endpoint overrides are needed.

**The PO does NOT need to add new rows to BC-2.14.002's Known-overrides enumeration.**

### Component count summary

| Version | Count | Components |
|---------|-------|-----------|
| v1.0 (D17) | 12 | CORE GRAPH CHKPT SERVER PROV MCP SPLIT SBXD RETRY CRON MEMORY BUDGET |
| v1.1 (D21) | **16** | + TMPL SRLZ VS EMBED |
| as of D23 | **17** | + TOOLS |

Category axis through D23: **12** (VAL AUTH RATE TIMEOUT TRANSPORT INTERNAL DURABILITY POLICY TOOL CONCURRENCY SECURITY TENANCY). _[Superseded by D26: "No new category is warranted" was the D21/D23 position; EXEC was introduced as the 13th category by D26 (burst-308); see §Category Axis Expansion (D26).]_

## Component Axis Expansion (D23) — 16 → 17

D23 (burst 232, 2026-07-22) introduced `pregolya-tools` (SS-23) via ADR-020, coining the
TOOLS error code prefix. The component axis grows from 16 to 17. The category axis remains
**unchanged at 12**.

### Axis-alignment rationale

`pregolya-tools` is a new crate (ADR-020 Decision 1: `pregolya-tools` is the published
crate housing first-party file I/O tools (`ReadFileTool`, `WriteFileTool`, `EditFileTool`,
`ListDirTool` — `tools::fs`), bash execution (`BashTool` — `tools::shell`), and text search
(`GrepTool` — `tools::search`), per ADR-020 Decision 2 exhaustive module inventory). New crate → new
component, following the same rule as GRAPH, CHKPT, MCP, SPLIT, SBXD, MEMORY.

#### TOOLS — pregolya-tools (SS-23, new crate)

`pregolya-tools` is the 21st published crate. Canonical abbreviation: **TOOLS** (as coined
by ADR-020 and error-taxonomy v1.31).

| Code | Category | RetryHint | Rationale |
|------|----------|-----------|-----------|
| E-TOOLS-001 | SECURITY | Never | PathConfinementViolation: file-write path escapes workspace; matches SBXD pattern — blocking security violation; caller must not retry. |
| E-TOOLS-002 | VAL | Never | FileReadExceedsLimit: read byte count exceeds configured limit; caller provided an oversized path or limit is misconfigured. Input constraint violation. |
| E-TOOLS-003 | VAL | Never | EditOldStringNotFound: `old_string` literal not found in the target file; caller supplied a stale or incorrect patch string. Input constraint violation. |
| E-TOOLS-004 | TIMEOUT | **Never** | BashTimeout: Bash process exceeded the execution time limit. **RetryHint divergence:** TIMEOUT category default is `Later(Duration)`, but BashTimeout carries `RetryHint::Never` — the same command will timeout again unless the caller changes the command or limit. Callers must not auto-retry without user intervention. |
| E-TOOLS-007 | VAL | Never | BashRiskTierViolation: ActionRisk below the minimum allowed floor (ReadOnly or Low rejected); caller attempted to invoke a command below the enforced risk floor. Input constraint violation. |
| E-TOOLS-008 | TOOL | Maybe | FileIoError: OS-level I/O error during file tool execution; wraps `std::io::ErrorKind` in structured fields (`path: String`, `io_kind: String` — ErrorKind debug name, e.g. "NotFound", "PermissionDenied", "StorageFull", "NotADirectory"); covers file-not-found/permission-denied/not-a-directory/disk-full/missing-parent-dir conditions in tools::fs and tools::search. RetryHint::Maybe because some IO errors are transient (e.g. StorageFull); caller inspects `io_kind` field to determine retry eligibility. Anchor BCs: BC-2.23.001–004, BC-2.23.006. |
| E-TOOLS-009 | VAL | Never | InvalidRegexPattern: `GrepTool` `pattern` argument failed to compile as a valid regex; structured fields: `pattern: String`, `compile_error: String` (the `regex` crate compile error message). Caller supplied an invalid pattern — input constraint violation; retrying the same pattern is futile. Anchor: BC-2.23.006 PC-4/EC-002/TV-003. |

**Informational payload fields (NOT PregolyaError Err returns):**

E-TOOLS-005 and E-TOOLS-006 are **outside the component × category axis**. They are
boolean/numeric fields on success payload structs, not `Err(PregolyaError)` returns:
- `BashOutput.truncated: bool` (E-TOOLS-005): output exceeded the truncation limit; the
  BashTool invocation succeeded but the output was truncated. This is an informational
  field on `BashOutput`, not a `Result::Err`.
- `GrepResult.capped: bool` (E-TOOLS-006): match count exceeded the cap; the grep
  succeeded but results were capped. This is an informational field on `GrepResult`,
  not a `Result::Err`.

These identifiers appear in error-taxonomy v1.31 for completeness; they are NOT
PregolyaError codes and do NOT add to the component count or the #[non_exhaustive]
gate. The PO confirmed their non-Err nature in the D23 BC layer (BC-2.23.005 PC-2 /
BC-2.23.006 PC-2).

#### #[non_exhaustive] gate update requirement (D23)

Adding `Component::Tools` (one variant) to the D21 gate update requirement:

1. **Gate crate** — `tests/external/<gate-name>/`: add `Component::Tools` to the expected
   symbol list (joins the D21 additions: Tmpl, Srlz, Vs, Embed).
2. **Expected count constant** — update from **17** (D21 value: 16 named + `Custom`) to
   **18** (17 named + `Custom`).
3. **Expected symbol list** — add `Component::Tools`.

The implementer who creates `pregolya-tools/src/error.rs` (Wave 1) owns this gate update.
The gate file must be updated in the SAME commit that adds `Component::Tools` to `error.rs`.

`Component::Tools` ↔ `TOOLS` in prose/code.

## Category Axis Expansion (D26) — 12 → 13

D26 (burst-308, 2026-08-17) introduced `EXEC` as the 13th error category, minted by
ADR-026 for E-CORE-009 (RunnableParallel branch failure). The component axis is unchanged at 17.

### Adjudication: why EXEC is a legitimate 13th category

ADR-026 Decision 2 defines E-CORE-009 with category `EXEC` for `RunnableParallel` branch
failures — when a concurrently-dispatched branch returns a `PregolyaError`, the parent wraps
that error to identify WHICH branch failed. This is a new semantic: "an orchestrated child step
returned an error." The fitness of each existing category was evaluated:

| Category | Fitness for E-CORE-009 | Ruling |
|----------|------------------------|--------|
| CONCURRENCY | Covers concurrency-safety violations (race conditions, ordering invariants, deadlocks) | Rejected: CONCURRENCY implies the error IS a concurrency-safety problem, not that it occurred during concurrent execution. A branch may fail with a VAL error; labelling the wrapper CONCURRENCY misrepresents the cause. |
| INTERNAL | For unexpected internal state errors / task panics (JoinError path — behavioral property 4) | Rejected: merging JoinError and branch-failure erases the semantic distinction between "task panicked" (unexpected, no client action useful) and "branch's own logic returned an error" (expected propagation with observable cause chain). |
| TOOL | For tool-execution errors (E-TOOLS-* codes, SS-23, pregolya-tools) | Rejected: `RunnableParallel` branches are `DynRunnable` instances, not `Tool` instances in the pregolya taxonomy. |
| VAL | Input validation failures | Rejected: branch failure is not an input constraint violation at the `RunnableParallel` level. |

**Decision:** None of the 12 existing categories fits cleanly. EXEC is semantically orthogonal:
a parent orchestration operation completed its concurrency management but a dispatched child
returned an error. The parent wraps the child error to preserve child identity (branch key)
in the error message. This admission follows the same appendable-ADR principle established
by the Component Axis Expansion precedent (D21/D23).

### EXEC — Execution orchestration failure

**Definition:** A parent orchestration operation (fan-out, pipeline stage, subtask dispatch)
completed its own concurrency management, but a child/branch that was dispatched returned an
error. The parent wraps the child `PregolyaError` to identify which child failed, enabling
callers to locate the failing branch.

**Canonical code:** `E-CORE-009` — `RunnableParallelBranchFailure: branch '<key>' failed: <cause>`.
The child's `PregolyaError` is chained via `.with_source()` for observability and retry-hint
propagation.

**RetryHint:** `RetryHint::Never` — the retry decision belongs to the child error's own
`retry_hint` (accessible via the `source` chain). The wrapper itself does not retry.

**HTTP mapping disposition:** EXEC is a **library-layer-only category**. No RFC-7807 status
row is needed in BC-2.14.002. Like TOOL, CONCURRENCY, and DURABILITY, EXEC failures surface
via the `to_problem()` categorical fallback (INTERNAL → 500) at the pregolya-server layer —
the HTTP client cannot meaningfully distinguish or retry a branch-execution failure without
inspecting the source chain, which MUST NOT be exposed in HTTP responses (DI-010 credential
leak risk). **The PO does NOT need to add a new row to BC-2.14.002's Known-overrides
enumeration.**

### Category count summary

| Version | Count | Categories |
|---------|-------|-----------|
| v1.0–D23 (D17 through D23) | 12 | VAL AUTH RATE TIMEOUT TRANSPORT INTERNAL DURABILITY POLICY TOOL CONCURRENCY SECURITY TENANCY |
| D26 (burst-308) | **13** | + EXEC |

### #[non_exhaustive] gate update requirement (D26)

The `Category` enum is a public API surface type and carries `#[non_exhaustive]`.
Adding `Category::Exec` (one variant) triggers the gate update rule from CLAUDE.md: **update
ALL three locations** when the non-exhaustive gate grows:

1. **Gate crate** — `tests/external/<gate-name>/`: add `Category::Exec` to the expected
   symbol list.
2. **Expected count constant** — update from 12 to 13.
3. **Expected symbol list** — add `Category::Exec`.

The implementer who creates `pregolya-core/src/error.rs` (Wave 1) owns this gate update.
This change is coordinate with the Component gate update (D23: 17 → 18); both updates
occur in the same `pregolya-core/src/error.rs` commit.

## Rationale

The 2D `component × category` model provides structured, machine-readable error information
that `anyhow::Error` loses. Callers need to distinguish rate-limit errors from auth errors
from internal errors — `category` provides that; they also need to know which crate originated
the error for observability routing — `component` provides that. Both dimensions are necessary;
neither is sufficient alone.

`thiserror` was chosen over hand-written `std::error::Error` impls because it generates the
correct `source()` chaining via `#[from]` and `#[source]` attributes with no boilerplate, while
remaining compatible with the `PregolyaError` conversion boundary pattern. `thiserror` is
a library crate; `anyhow` is not permitted in library crates because it erases type information
at the public boundary.

The CI lint gate (`cargo xtask deny-anyhow-in-lib`) is the enforcement mechanism — policy
without tooling enforcement is not production-grade.

The component axis expansion rationale (D21 and D23) is recorded inline in the §Component Axis
Expansion sections above. The governing principle: new crate → new component; intra-crate logical
subsystem → component following RETRY/CRON/BUDGET precedent; cross-crate concern → single component
(PROV/EMBED pattern). No new category was warranted for either D21 or D23 — all error conditions
map to existing VAL, SECURITY, TIMEOUT, or other established categories. _[Superseded in part by
D26 (burst-308): D26 introduced EXEC as the first category expansion (RunnableParallel branch-failure
propagation); the D21/D23 "no new category warranted" was correct for those points; D26 is the first
case where no existing category fits cleanly; see §Category Axis Expansion (D26).]_ The D23 TOOLS
component also establishes the RetryHint::Never divergence precedent for TIMEOUT-category codes where
retry would be futile without caller action (E-TOOLS-004 BashTimeout).

## Consequences

- All library crates add `thiserror` as a dependency.
- Internal module errors use `thiserror`-derived enums.
- The `From<SomeInternalError> for PregolyaError` impl provides the conversion boundary.
- `anyhow` appears ONLY in `xtask/Cargo.toml` and integration test harness crates.
- RFC-7807 emission (BC-2.14.002): `PregolyaError::to_problem()` serializes to
  `application/problem+json` for pregolya-server error responses.
  **Correction (F-P26-02, ADV-P1D-PASS-26, propagating F-P25-04 canon):** `to_problem_detail()`
  was the retired method name; `to_problem()` is authoritative per BC-2.14.002 PC1 and
  api-surface.md §Error Type.
- `PregolyaError::source()` returns the original cause (for logging); MUST NOT be
  exposed in HTTP responses (credential leak risk per DI-010).

## Alternatives Considered

- **Option `anyhow` at library boundaries:** Rejected because it erases component, category,
  and retry_hint — callers cannot programmatically distinguish error kinds. P-78 documents
  this as a known failure pattern in the adk-rust reference corpus (W-04).
- **Option hand-written error enums per crate (no `thiserror`):** Rejected because the
  boilerplate is large and the `source()` chaining is error-prone without macro support.
  `thiserror` provides the same result with less surface area for mistakes.
- **Option `anyhow` internally, convert at boundary:** Rejected because internal `anyhow`
  chains lose the structured context before it can be captured in `PregolyaError.source`.
  `thiserror`-derived internal types preserve full structured context through the conversion.

## Source / Origin

- **P-78 (adk-rust certification report W-04):** `MistralRsError::Other(#[from] anyhow::Error)`
  public-signature leak — the sole genuine anyhow boundary violation identified; this ADR
  prevents pregolya from inheriting that pattern.
- **DI-014** (`domain-spec/invariants.md`): no silent error swallowing; structured error
  propagation required at all library boundaries.
- **BC-2.14.001–006** (`.factory/specs/behavioral-contracts/ss-14/`): PregolyaError 2D
  model, RFC-7807 emission, constructor result contract, API key safety, validation propagation.
- **BC-2.14.003**: CI lint gate (`cargo xtask deny-anyhow-in-lib`) enforcing anyhow
  confinement at build time.
- **ADR-014** (VectorStore + Retriever): coins `E-VS-001`; VS component adjudicated here.
- **ADR-015** (Prompt Template Injection Safety): coins `E-TMPL-001/002/003`; TMPL component adjudicated here.
- **ADR-016** (lc-JSON Deserialization Safety): coins `E-SRLZ-001/002`; SRLZ component adjudicated here; `category: Serialization` corrected to `VAL`.
- **ADR-017** (Embeddings Trait): coins `E-EMBED-001`; EMBED component adjudicated here.
- **D21** (burst 216, 2026-07-20): ecosystem-parity scope expansion triggering component axis review.
- **ADR-020** (BashTool / pregolya-tools): TOOLS namespace; original D23 codes E-TOOLS-001..007; E-TOOLS-008 FileIoError added burst-233; E-TOOLS-009 InvalidRegexPattern added burst-234; full range E-TOOLS-001..009 (excluding informational payload fields 005/006). TOOLS component adjudicated here. E-TOOLS-004 RetryHint::Never divergence rationale documented in §Component Axis Expansion (D23).
- **error-taxonomy v1.31** (D23 BC layer): E-TOOLS-001..007 minted; error census 105.
- **D23** (burst 232, 2026-07-22): pregolya-tools / SS-23 scope expansion triggering component axis review.
