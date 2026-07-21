---
document_type: adr
level: L3
adr_id: "010"
slug: error-taxonomy-anyhow-confinement
title: "Error Taxonomy and anyhow Confinement (P-78 / NE-03 / DI-014)"
status: accepted
producer: architect
timestamp: 2026-07-20T00:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17, D21]
date: "2026-07-20"
subsystems_affected: [SS-14]
supersedes: null
superseded_by: null
version: "1.2"
changelog:
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
    pub component: Component,     // authoritative list lives in error-taxonomy.md §Components; enum reproduced here for the FerrochainError type definition (v1.1 — 16 components): CORE | GRAPH | CHKPT | SERVER | PROV | MCP | SPLIT | SBXD | RETRY | CRON | MEMORY | BUDGET | TMPL | SRLZ | VS | EMBED
    pub category: Category,       // canonical Category Codes (12 — unchanged): VAL | AUTH | RATE | TIMEOUT | TRANSPORT | INTERNAL | DURABILITY | POLICY | TOOL | CONCURRENCY | SECURITY | TENANCY
    pub retry_hint: RetryHint,    // canonical: Never | Maybe | Later(Duration)
    pub code: &'static str,       // "E-GRAPH-001", "E-CHKPT-002", "E-TMPL-001", "E-VS-001", etc.
    pub message: String,          // Human-readable; MUST NOT contain credentials
    pub source: Option<Box<dyn std::error::Error + Send + Sync>>,
}
```

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
bad input. The PO must apply `Category::Val` (not a new Serialization category) when
authoring BC-2.19.x and the error-taxonomy rows for SRLZ.

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
errors are therefore **E-VS-NNN** codes, not E-CFG-NNN. The PO assigns the next
available VS sequence number when authoring BC-2.21.x.

| Code | Category | Rationale |
|------|----------|-----------|
| E-VS-001 | VAL | ZeroNormVector: cosine similarity guard — zero-length embedding vector produces NaN; caller or embedding backend returned an invalid vector (ADR-014 hardening note). |
| E-VS-NNN (was E-CFG-001) | VAL | VectorStoreRetriever config validation (k, fetch_k, lambda_mult range checks). PO assigns next sequence number. No CFG component. |

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
   (16 named + `Custom`).
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

Category axis: **12 — unchanged** (VAL AUTH RATE TIMEOUT TRANSPORT INTERNAL DURABILITY POLICY TOOL CONCURRENCY SECURITY TENANCY). No new category is warranted.

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

The component axis expansion rationale (D21) is recorded inline in the §Component Axis Expansion
section above. The governing principle: new crate → new component; intra-crate logical subsystem
→ component following RETRY/CRON/BUDGET precedent; cross-crate concern → single component
(PROV/EMBED pattern). No new category was warranted — all D21 error conditions map to
existing VAL, SECURITY, or other established categories.

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
