---
document_type: adr
level: L3
adr_id: "010"
slug: error-taxonomy-anyhow-confinement
title: "Error Taxonomy and anyhow Confinement (P-78 / NE-03 / DI-014)"
status: accepted
producer: architect
timestamp: 2026-07-25T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17, D21, D23]
date: "2026-07-25"
subsystems_affected: [SS-14]
supersedes: null
superseded_by: null
version: "1.8"
changelog:
  - "1.8 (FIX-BURST-269/F-P167-05/2026-07-25): Add Category casing canon note after FerrochainError struct definition. Category enum variants use SCREAMING_CASE (Category::VAL, Category::AUTH, etc.) — not PascalCase (Category::Val). The canonical codes list at the category comment already used uppercase (VAL | AUTH | …); this note makes the Rust variant casing explicit to prevent future Category::Val drift. Closing adjudication from F-P167-05."
  - "1.7 (FIX-BURST-267/F-P165-01+02/2026-07-25): F-P165-01 — de-label two version-pinned D23 cites to decay-resistant 'as of D23' form: (1) FerrochainError struct component comment '(v1.2 — 17 components)' → '(as of D23 — 17 components)'; (2) Component count summary table row 'v1.2 (D23)' → 'as of D23'. F-P165-02 — restore D21 #[non_exhaustive] gate-count block to historically-correct 13→17 (16 named + Custom) with a forward note 'As of D23, the current value is 18 (17 named + Custom) — see §Component Axis Expansion (D23)'; previous text incorrectly stated 13→18 (skipping the D21-era intermediate), contradicting the D23 §gate update block which correctly shows 17→18."
  - "1.6 (burst-238/2026-07-23): Stale-handoff sweep — rewrite three future-tense PO obligations added in v1.1 (D21) to past-tense facts: (1) SRLZ 'PO must apply Category::Val when authoring BC-2.19.x' → 'PO applied Category::Val (error-taxonomy v1.27/D21)'; (2) VS E-CFG-001 resolution 'PO assigns next available VS sequence number when authoring BC-2.21.x' → 'PO assigned E-VS-003 (error-taxonomy v1.27/D21; anchor BC-2.20.003)'; (3) VS table row 'E-VS-NNN (was E-CFG-001)' → 'E-VS-003 (was E-CFG-001)'; remove 'PO assigns next sequence number' from table cell."
  - "1.5 (burst-234/2026-07-22): PO minted E-TOOLS-009 InvalidRegexPattern (VAL/Never; fields pattern: String + compile_error: String; anchor BC-2.23.006 PC-4/EC-002/TV-003 — invalid-regex path in GrepTool). Add E-TOOLS-009 row to TOOLS component table. Update Source/Origin cite range 001..007 → 001..009 (TD-VSDD-060 sibling sweep). TOOLS namespace is now 9 codes (001..009); component count and #[non_exhaustive] gate count unchanged."
  - "1.4 (burst-233/2026-07-22): F-P133-03 sibling sweep — add E-TOOLS-008 FileIoError to TOOLS component table (category TOOL, RetryHint Maybe); covers OS-level I/O errors during file tool execution; wraps std::io::ErrorKind; anchor BCs: BC-2.23.001–004, BC-2.23.006. Component count and #[non_exhaustive] gate count unchanged (TOOLS already registered as component 17 in v1.3; new code is within existing component)."
  - "1.3 (burst-232/2026-07-22): D23 — register TOOLS as component 17 (ferrochain-tools, SS-23). Component axis 16→17. E-TOOLS-001..007 adjudicated (codes coined by error-taxonomy v1.31 during D23 BC authoring). E-TOOLS-004 (BashTimeout) carries RetryHint::Never diverging from the TIMEOUT category default (Later); rationale in §Component Axis Expansion (D23). E-TOOLS-005 (BashOutput.truncated) and E-TOOLS-006 (GrepResult.capped) are informational payload fields, not FerrochainError Err returns — they are outside the component×category axis. #[non_exhaustive] gate count 17→18."
  - "1.2 (burst-225/2026-07-21): F-P130-07 sibling sweep — correct stale E-EMBED-001 rationale prefix in EMBED component table: `DimensionMismatch:` → `EmbeddingDimensionMismatch:` per error-taxonomy v1.29 (PO renamed to distinguish from E-VS-002 which retains bare `DimensionMismatch:`)."
  - "1.1 (D21/2026-07-20): Component axis expanded from 12 → 16 by adjudicating error codes introduced in ADR-014 (VectorStore), ADR-015 (Prompt Templates), ADR-016 (lc-JSON), and ADR-017 (Embeddings). Four new components added: TMPL (ferrochain-prompts), SRLZ (ferrochain-core::serializable), VS (ferrochain-vectorstores), EMBED (ferrochain-core::embeddings + providers). Category axis unchanged at 12. E-CFG-001 (VectorStoreRetriever config) reassigned to E-VS-NNN — no CFG component created. ADR-016 category error corrected: 'Serialization' → VAL. #[non_exhaustive] gate count 13 → 17. All four new components are library-layer only; no RFC-7807 status rows needed in BC-2.14.002."
  - "1.0 (D17/2026-07-14): Initial ADR — anyhow confinement rules, FerrochainError at all library boundaries, thiserror for internal errors, CI enforcement via cargo xtask deny-anyhow-in-lib."
---

# ADR-010: Error Taxonomy and anyhow Confinement

**Status:** Accepted

## Context

adk-rust uses `anyhow::Error` at the library boundary in several places, losing structured
error information for callers (P-78 pattern to avoid). DI-014 mandates structured error
propagation with no silent None returns. BC-2.14.001–006 specify the FerrochainError model.

This ADR specifies: when is `anyhow` permitted, where is it banned, and how are crate
boundaries enforced.

## Decision: FerrochainError at all library boundaries; anyhow permitted only in binaries

**Rule:** `anyhow::Error` MUST NOT appear in any `pub` function signature in any library
crate. All public functions return `Result<T, FerrochainError>`.

**FerrochainError structure (BC-2.14.001):**

```rust
#[derive(Debug, Clone)]
pub struct FerrochainError {
    pub component: Component,     // authoritative list lives in error-taxonomy.md §Components; enum reproduced here for the FerrochainError type definition (as of D23 — 17 components): CORE | GRAPH | CHKPT | SERVER | PROV | MCP | SPLIT | SBXD | RETRY | CRON | MEMORY | BUDGET | TMPL | SRLZ | VS | EMBED | TOOLS
    pub category: Category,       // canonical Category Codes (12 — unchanged): VAL | AUTH | RATE | TIMEOUT | TRANSPORT | INTERNAL | DURABILITY | POLICY | TOOL | CONCURRENCY | SECURITY | TENANCY
    pub retry_hint: RetryHint,    // canonical: Never | Maybe | Later(Duration)
    pub code: &'static str,       // "E-GRAPH-001", "E-CHKPT-002", "E-TMPL-001", "E-VS-001", etc.
    pub message: String,          // Human-readable; MUST NOT contain credentials
    pub source: Option<Box<dyn std::error::Error + Send + Sync>>,
}
```

**Category casing canon (F-P167-05, FIX-BURST-269):** `Category` enum variants use SCREAMING_CASE — `Category::VAL`, `Category::AUTH`, `Category::SECURITY`, etc. PascalCase forms such as `Category::Val` are NON-CANONICAL and must not appear in any spec, harness, or code artifact. The codes list above (`VAL | AUTH | RATE | …`) is intentionally uppercase; the Rust variant identifiers match exactly.

**anyhow confinement rules:**
1. Library crates (`ferrochain-*`): `anyhow` is NOT a dependency. ZERO uses.
2. `xtask` (binary): `anyhow` is permitted (CLI tooling; errors are human-facing).
3. Integration test binaries: `anyhow` is permitted for test harness convenience.
4. Example binaries: `anyhow` is permitted.

**CI enforcement:** `cargo xtask deny-anyhow-in-lib` (custom Semgrep rule) scans
`src/` in all library crates for `anyhow` imports. Fails CI on any finding.

**Internal error conversion:** Library crates use `thiserror` for internal error types
that convert to `FerrochainError` at the crate boundary. `thiserror` is permitted in
library crates; `anyhow` is not.

**Scope note:** NE-16 in the PRD refers to macOS Seatbelt (BC-2.13.006); it does NOT
govern anyhow confinement. This ADR's authority derives from P-78 (adk-rust
`MistralRsError::Other(#[from] anyhow::Error)` must-not-inherit pattern — the sole
genuine anyhow public-signature leak per CERTIFICATION-REPORT W-04), DI-014 (no silent
error swallowing), and the BC-2.14.003 CI lint gate.

## Component Axis Expansion (D21) — 12 → 16

D21 (burst 216, 2026-07-20) introduced four new ferrochain subsystems via ADR-014/015/016/017,
each coining new error code prefixes. This section records the adjudicated mapping for each
new prefix. The authoritative component list grows from 12 to 16; the category axis is
**unchanged at 12**.

### Axis-alignment precedent

The existing 12 components follow a mixed-alignment model:
- **Crate-aligned (one component per crate):** CORE, GRAPH, CHKPT, SERVER, MCP, SPLIT, SBXD, MEMORY.
- **Cross-crate concern (one component spanning multiple crates):** PROV spans
  ferrochain-openai, ferrochain-anthropic, ferrochain-ollama.
- **Intra-crate logical subsystem (own component prefix within a host crate):** RETRY
  (ferrochain-core retry combinator), CRON (ferrochain-server scheduler), BUDGET
  (ferrochain-graph budget governance). This pattern — explicitly labeled in error-taxonomy.md —
  is the governing precedent for SRLZ below.

### New components (D21 adjudication)

#### TMPL — ferrochain-prompts (SS-18, new crate)

`ferrochain-prompts` is the 19th published crate (ADR-015 Decision 1). New crate → new
component. Canonical abbreviation: **TMPL** (as coined by ADR-015).

| Code | Category | Rationale |
|------|----------|-----------|
| E-TMPL-001 | SECURITY | InjectionAttempt: untrusted variable substituted into TrustRequired (SystemMessage) slot — prompt injection attack vector, not a policy violation. SECURITY per authorization-failure categorization rule: bypass enables concrete attack. |
| E-TMPL-002 | VAL | SystemSlotPolicy: construction-time rejection of TrustAll policy on a SystemMessage slot. Input constraint violation at template-build time. |
| E-TMPL-003 | VAL | UndefinedVariable: minijinja strict-undefined mode raises this when a template variable is not in the input map. Input constraint violation at render time. |

`Component::Tmpl` ↔ `TMPL` in prose/code.

#### SRLZ — ferrochain-core::serializable (SS-19, intra-core module)

ADR-016 Decision 1 explicitly places `core::serializable` **as a module within ferrochain-core**
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
| E-SRLZ-002 | VAL | UnsupportedSerializable: langchain-monolith type not ported to ferrochain — known-but-unsupported type referenced. Input validation failure. |

`Component::Srlz` ↔ `SRLZ` in prose/code.

#### VS — ferrochain-vectorstores (SS-21, new crate)

`ferrochain-vectorstores` is the 20th published crate (ADR-014 Consequences). New crate →
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

#### EMBED — ferrochain-core::embeddings (SS-22, core trait + provider impls)

The `Embeddings` trait lives in ferrochain-core (`core::embeddings`, ADR-017 Decision 1).
Provider implementations live in ferrochain-openai and ferrochain-ollama — the same
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

The implementer who creates `ferrochain-core/src/error.rs` (Wave 0) owns this gate update.

### RFC-7807 status mapping (BC-2.14.002)

All four new components are **library-layer only**. None surfaces directly as an HTTP
terminal response from ferrochain-server in v1. Categorical fallbacks apply if ever
surfaced directly (SECURITY→403, VAL→400) but no per-endpoint overrides are needed.

**The PO does NOT need to add new rows to BC-2.14.002's Known-overrides enumeration.**

### Component count summary

| Version | Count | Components |
|---------|-------|-----------|
| v1.0 (D17) | 12 | CORE GRAPH CHKPT SERVER PROV MCP SPLIT SBXD RETRY CRON MEMORY BUDGET |
| v1.1 (D21) | **16** | + TMPL SRLZ VS EMBED |
| as of D23 | **17** | + TOOLS |

Category axis: **12 — unchanged** (VAL AUTH RATE TIMEOUT TRANSPORT INTERNAL DURABILITY POLICY TOOL CONCURRENCY SECURITY TENANCY). No new category is warranted.

## Component Axis Expansion (D23) — 16 → 17

D23 (burst 232, 2026-07-22) introduced `ferrochain-tools` (SS-23) via ADR-020, coining the
TOOLS error code prefix. The component axis grows from 16 to 17. The category axis remains
**unchanged at 12**.

### Axis-alignment rationale

`ferrochain-tools` is a new crate (ADR-020 Decision 1: `ferrochain-tools` is the published
crate housing BashTool, Python REPL, file-edit tools, and grep utilities). New crate → new
component, following the same rule as GRAPH, CHKPT, MCP, SPLIT, SBXD, MEMORY.

#### TOOLS — ferrochain-tools (SS-23, new crate)

`ferrochain-tools` is the 21st published crate. Canonical abbreviation: **TOOLS** (as coined
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

**Informational payload fields (NOT FerrochainError Err returns):**

E-TOOLS-005 and E-TOOLS-006 are **outside the component × category axis**. They are
boolean/numeric fields on success payload structs, not `Err(FerrochainError)` returns:
- `BashOutput.truncated: bool` (E-TOOLS-005): output exceeded the truncation limit; the
  BashTool invocation succeeded but the output was truncated. This is an informational
  field on `BashOutput`, not a `Result::Err`.
- `GrepResult.capped: bool` (E-TOOLS-006): match count exceeded the cap; the grep
  succeeded but results were capped. This is an informational field on `GrepResult`,
  not a `Result::Err`.

These identifiers appear in error-taxonomy v1.31 for completeness; they are NOT
FerrochainError codes and do NOT add to the component count or the #[non_exhaustive]
gate. The PO confirmed their non-Err nature in the D23 BC layer (BC-2.23.003/004).

#### #[non_exhaustive] gate update requirement (D23)

Adding `Component::Tools` (one variant) to the D21 gate update requirement:

1. **Gate crate** — `tests/external/<gate-name>/`: add `Component::Tools` to the expected
   symbol list (joins the D21 additions: Tmpl, Srlz, Vs, Embed).
2. **Expected count constant** — update from **17** (D21 value: 16 named + `Custom`) to
   **18** (17 named + `Custom`).
3. **Expected symbol list** — add `Component::Tools`.

The implementer who creates `ferrochain-tools/src/error.rs` (Wave TBD) owns this gate update.
The gate file must be updated in the SAME commit that adds `Component::Tools` to `error.rs`.

`Component::Tools` ↔ `TOOLS` in prose/code.

## Rationale

The 2D `component × category` model provides structured, machine-readable error information
that `anyhow::Error` loses. Callers need to distinguish rate-limit errors from auth errors
from internal errors — `category` provides that; they also need to know which crate originated
the error for observability routing — `component` provides that. Both dimensions are necessary;
neither is sufficient alone.

`thiserror` was chosen over hand-written `std::error::Error` impls because it generates the
correct `source()` chaining via `#[from]` and `#[source]` attributes with no boilerplate, while
remaining compatible with the `FerrochainError` conversion boundary pattern. `thiserror` is
a library crate; `anyhow` is not permitted in library crates because it erases type information
at the public boundary.

The CI lint gate (`cargo xtask deny-anyhow-in-lib`) is the enforcement mechanism — policy
without tooling enforcement is not production-grade.

The component axis expansion rationale (D21 and D23) is recorded inline in the §Component Axis
Expansion sections above. The governing principle: new crate → new component; intra-crate logical
subsystem → component following RETRY/CRON/BUDGET precedent; cross-crate concern → single component
(PROV/EMBED pattern). No new category was warranted for either D21 or D23 — all error conditions
map to existing VAL, SECURITY, TIMEOUT, or other established categories. The D23 TOOLS component
also establishes the RetryHint::Never divergence precedent for TIMEOUT-category codes where retry
would be futile without caller action (E-TOOLS-004 BashTimeout).

## Consequences

- All library crates add `thiserror` as a dependency.
- Internal module errors use `thiserror`-derived enums.
- The `From<SomeInternalError> for FerrochainError` impl provides the conversion boundary.
- `anyhow` appears ONLY in `xtask/Cargo.toml` and integration test harness crates.
- RFC-7807 emission (BC-2.14.002): `FerrochainError::to_problem()` serializes to
  `application/problem+json` for ferrochain-server error responses.
  **Correction (F-P26-02, ADV-P1D-PASS-26, propagating F-P25-04 canon):** `to_problem_detail()`
  was the retired method name; `to_problem()` is authoritative per BC-2.14.002 PC1 and
  api-surface.md §Error Type.
- `FerrochainError::source()` returns the original cause (for logging); MUST NOT be
  exposed in HTTP responses (credential leak risk per DI-010).

## Alternatives Considered

- **Option `anyhow` at library boundaries:** Rejected because it erases component, category,
  and retry_hint — callers cannot programmatically distinguish error kinds. P-78 documents
  this as a known failure pattern in the adk-rust reference corpus (W-04).
- **Option hand-written error enums per crate (no `thiserror`):** Rejected because the
  boilerplate is large and the `source()` chaining is error-prone without macro support.
  `thiserror` provides the same result with less surface area for mistakes.
- **Option `anyhow` internally, convert at boundary:** Rejected because internal `anyhow`
  chains lose the structured context before it can be captured in `FerrochainError.source`.
  `thiserror`-derived internal types preserve full structured context through the conversion.

## Source / Origin

- **P-78 (adk-rust certification report W-04):** `MistralRsError::Other(#[from] anyhow::Error)`
  public-signature leak — the sole genuine anyhow boundary violation identified; this ADR
  prevents ferrochain from inheriting that pattern.
- **DI-014** (`domain-spec/invariants.md`): no silent error swallowing; structured error
  propagation required at all library boundaries.
- **BC-2.14.001–006** (`.factory/specs/behavioral-contracts/ss-14/`): FerrochainError 2D
  model, RFC-7807 emission, constructor result contract, API key safety, validation propagation.
- **BC-2.14.003**: CI lint gate (`cargo xtask deny-anyhow-in-lib`) enforcing anyhow
  confinement at build time.
- **ADR-014** (VectorStore + Retriever): coins `E-VS-001`; VS component adjudicated here.
- **ADR-015** (Prompt Template Injection Safety): coins `E-TMPL-001/002/003`; TMPL component adjudicated here.
- **ADR-016** (lc-JSON Deserialization Safety): coins `E-SRLZ-001/002`; SRLZ component adjudicated here; `category: Serialization` corrected to `VAL`.
- **ADR-017** (Embeddings Trait): coins `E-EMBED-001`; EMBED component adjudicated here.
- **D21** (burst 216, 2026-07-20): ecosystem-parity scope expansion triggering component axis review.
- **ADR-020** (BashTool / ferrochain-tools): TOOLS namespace; original D23 codes E-TOOLS-001..007; E-TOOLS-008 FileIoError added burst-233; E-TOOLS-009 InvalidRegexPattern added burst-234; full range E-TOOLS-001..009 (excluding informational payload fields 005/006). TOOLS component adjudicated here. E-TOOLS-004 RetryHint::Never divergence rationale documented in §Component Axis Expansion (D23).
- **error-taxonomy v1.31** (D23 BC layer): E-TOOLS-001..007 minted; error census 105.
- **D23** (burst 232, 2026-07-22): ferrochain-tools / SS-23 scope expansion triggering component axis review.
