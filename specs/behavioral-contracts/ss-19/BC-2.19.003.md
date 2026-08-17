---
document_type: behavioral-contract
level: L3
bc_id: BC-2.19.003
version: "1.4"
status: draft
lifecycle_status: active
introduced: v1.0.0-greenfield
origin: greenfield
priority: P1
subsystem: SS-19
capability: CAP-025
crate: pregolya-core
wave: 2
phase: 1b
producer: product-owner
timestamp: 2026-08-16T00:00:00Z
di_anchors: [DI-008]
changelog:
  - "1.0 (D21/2026-07-20): initial BC authored — D21 ecosystem-parity expansion SS-19 LC Serialization"
  - "1.1 (F-P130-08/2026-07-21): TV-001/TV-002 made falsifiable. Removed hedged magic-number assertion `registry_size() == 141 (or the current count…)`. TV-001 now asserts relational equality to `LANGCHAIN_CORE_REGISTRY.len()` named constant; TV-002 asserts feature-gated delta `registry_size() >= core_count + 1`. The literal 141 is retained as informative prose only."
  - "1.2 (F-P170-01/burst-272/2026-07-25): Re-anchor Architecture Anchors and Traceability Architecture Authority from ADR-016 Decision 4 to Decision 2 — the inventory crate, feature-gated partner registration, and OnceLock initialization are all defined in Decision 2 (Registry Mechanism); Decision 4 is Legacy Namespace Remapping and Version Tolerance (OLD_CORE_NAMESPACES_MAPPING). Drop fabricated 'duplicate detection' clause (not attributed in ADR-016). De-pin 'version 0.3.24' in PC1 per TD-VSDD-091 (version pins in normative body text decay on patch bumps)."
  - "1.3 (FIX-BURST-277-WAVE-C/FC-2-genuine-removal/2026-07-28): Genuine completion of v1.2 false-closure FC-2. v1.2 claimed 'Drop fabricated duplicate detection clause' but the term survived in Invariant 2 ('duplicate registration detection') and EC-003 ('DuplicateRegistration'). Decision on merits: ADR-016 Decision 2 specifies inventory::iter for registry construction with no duplicate-detection semantics; the inventory crate does not natively panic on duplicate submissions; the DuplicateRegistration panic behavior was fabricated without specification backing. Removal: (1) Invariant 2: panic-on-duplicate language replaced with last-write-wins HashMap semantics. (2) EC-003: DuplicateRegistration panic removed; replaced with last-write-wins HashMap behavior and a CI assertion recommendation. (3) DI-008 Traceability: 'except duplicate detection' exception removed. TD-VSDD-060 sibling sweep: no other SS-19 BCs contain duplicate-detection language."
  - "1.4 (F-P188-01/burst-297/2026-08-16): DI-008 Traceability cell corrected — 'Reviver::new() returns Result' was wrong. PC2 explicitly states Reviver::new() returns a plain Reviver instance (infallible); Reviver::new() calls inventory::iter at link-time and cannot fail. The fallible operation is revive(), not the constructor. Fixed cell to: 'revive returns Result; Reviver::new() is infallible; no panic on registry initialization' — matching the pattern of siblings BC-2.19.004/005/006. D-134 Sweep A: this was the only named-constructor mis-attribution among all 42 DI-008 Traceability cells corpus-wide (BC-2.19.001 was also fixed in the same burst). input-hash updated to current (e7b7c2e)."
traces_to:
  - domain-spec/capabilities-p1-p2.md#CAP-025
  - architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - domain-spec/invariants.md#DI-008
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/architecture/decisions/ADR-016-lc-json-deserialization-safety.md
  - .factory/specs/domain-spec/invariants.md
input-hash: "e7b7c2e"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# BC-2.19.003: Inventory-Based Type Registry — Link-Time Registration, Feature-Gated Partner Entries, OnceLock Allowlist

## Description

The serialization registry is populated at link time via `inventory::submit!` macros, not
by a hand-maintained list. Core pregolya types register unconditionally;
partner-crate types (e.g., OpenAI, Anthropic, Ollama adapters) register only when their
corresponding Cargo feature is enabled (e.g., `feature = "openai"`). At program startup,
`Reviver::new()` calls `inventory::iter::<LcEntry>()` to collect all registered entries into
a `HashMap<Vec<String>, ConstructorFn>`, which is wrapped in a `OnceLock` for thread-safe
single initialization. The allowlist used by BC-2.19.005's Reviver is derived from this
registry — it is never a hand-edited list.

## Preconditions

1. The `inventory` crate (dtolnay) is a dependency of `pregolya-core`.
2. Each type `T` that must participate in serialization declares its `LcEntry` via
   `inventory::submit! { LcEntry { lc_id: &["..."], constructor: |kwargs| { ... } } }`.
3. For partner crate entries: the `inventory::submit!` is inside a
   `#[cfg(feature = "openai")]` (or equivalent) guard so it is a no-op if the feature is not enabled.
4. `Reviver::new()` is called once at program startup; subsequent calls return the
   cached `OnceLock` value.

## Postconditions

1. After link step, `inventory::iter::<LcEntry>()` returns an iterator over all `LcEntry`
   items for every registered type whose feature is enabled in the current binary.
2. `Reviver::new()` returns a `Reviver` instance backed by a `HashMap` containing exactly
   the entries produced by `inventory::iter::<LcEntry>()`. No additional entries are added
   at runtime.
3. The `OnceLock` ensures the registry is initialized at most once per process — concurrent
   calls to `Reviver::new()` are safe and return the same registry.
4. Partner crate entries are NOT present in the registry when their feature is disabled (e.g.,
   `cargo build --no-default-features` produces a registry with only core types).
5. `Reviver::registry_size() → usize` returns the count of registered entries (used for
   smoke-test assertions in CI).

## Invariants

1. The registry is **append-only at link time** — no runtime API adds or removes entries.
   This property is what makes `OnceLock` initialization safe.
2. If two `inventory::submit!` calls register the same `lc_id` (a programming error), the
   `inventory` crate does not natively detect duplicates; both entries are collected by
   `inventory::iter::<LcEntry>()` and when the `HashMap` is constructed, the second entry
   overwrites the first for the same key (last-write-wins). This is not a production runtime
   error — it is a programming error that CI should catch via a registry size assertion.
3. The registry is the sole source of the allowlist — BC-2.19.005's Reviver checks against
   this `HashMap`, not against a separate hard-coded list.
4. Feature-gated entries follow the same `LcEntry` struct as unconditional entries — there
   is no separate "optional entry" type.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Binary compiled with `--no-default-features` (no partner features) | Registry contains only core pregolya types; partner type ids are absent; `Reviver::revive()` on a partner type id returns `Err(E-SRLZ-001)` |
| EC-002 | Binary compiled with `features = ["openai", "anthropic"]` | Registry contains core + OpenAI + Anthropic entries; Ollama entries absent if `"ollama"` feature not enabled |
| EC-003 | Duplicate `inventory::submit!` for the same `lc_id` | The `inventory` crate collects both entries; HashMap construction silently overwrites the first with the second (last-write-wins). The correct detection strategy is a CI assertion that `registry_size() == EXPECTED_COUNT`; a count mismatch indicates a duplicate or a missing entry |
| EC-004 | `inventory::iter::<LcEntry>()` called before `Reviver::new()` | Valid — iter is lazy; it does not require Reviver to be initialized |
| EC-005 | Multiple threads call `Reviver::new()` concurrently at program startup | `OnceLock` ensures initialization runs exactly once; all callers receive the same `Reviver` after initialization |

## Canonical Test Vectors

| # | Input | Expected Output | Category |
|---|-------|-----------------|----------|
| TV-001 | `Reviver::new()` in a binary with core features only | `reviver.registry_size() == LANGCHAIN_CORE_REGISTRY.len()` where `LANGCHAIN_CORE_REGISTRY` is the named compile-time constant listing all core `inventory::submit!` entries. Assertion is an equality against the constant, not against a hardcoded literal. (As of the reference corpus, `LANGCHAIN_CORE_REGISTRY.len() == 141`; the test is correct even when that count changes.) | happy-path (registry size — relational assertion) |
| TV-002 | `Reviver::new()` with `features = ["openai"]` enabled | `reviver.registry_size() >= core_count + 1` where `core_count = LANGCHAIN_CORE_REGISTRY.len()` and the delta of at least 1 asserts that at least one OpenAI entry was registered. The test is a feature-gated lower-bound check, not a magic absolute number. | happy-path (feature-gated partner — relational assertion) |
| TV-003 | Lookup `["langchain_core", "prompts", "prompt", "PromptTemplate"]` in registry | Entry found; constructor fn is callable | happy-path (lookup) |
| TV-004 | Lookup unknown id `["my_custom_type"]` in registry | `None` returned from HashMap; leads to E-SRLZ-001 in Reviver::revive | edge-case (missing id) |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|-------------|
| VP-2.19.003-A | `Reviver::new()` called N times returns identical `registry_size()` (idempotent startup) | unit test — call new() 3 times in sequence; assert same size |
| VP-2.19.003-B | Feature-gated entries are absent when the feature is not enabled | integration test — compile with `--no-default-features`; assert partner ids not in registry |

## Related BCs

- BC-2.19.001 — depends on: round-trip requires a registered type; this BC specifies how types become registered
- BC-2.19.004 — composes with: legacy namespace remapping adds alias entries to the same registry at startup
- BC-2.19.005 — depends on: Reviver allowlist containment (BC-2.19.005) is grounded in this registry

## Architecture Anchors

- `architecture/module-decomposition.md` — SS-19, `core::serializable::registry` sub-module
- `architecture/decisions/ADR-016-lc-json-deserialization-safety.md` — Decision 2 (inventory crate choice, feature-gated partner registration, OnceLock initialization)
- `architecture/purity-boundary-map.md` — `pregolya-core / core::serializable` Pure Core (initialization is pure; no I/O)

## Story Anchor

_[to be filled after story decomposition — Wave 2 SS-19 story]_

## VP Anchors

- VP-2.19.003-A, VP-2.19.003-B

## Traceability

| Field | Value |
|-------|-------|
| Source L2 Capability | CAP-025 |
| Capability Anchor Justification | CAP-025 ("Reviver and Type Registry (Inventory-Based; Allowlist Containment; Legacy-Namespace Remap)") per capabilities-p1-p2.md §CAP-025 — this BC specifies the inventory-based link-time registration mechanism, feature-gated partner entries, and OnceLock allowlist derivation, which CAP-025 identifies as the registry substrate for the Reviver's allowlist-containment model |
| L2 Domain Invariants | DI-008 (revive returns Result; Reviver::new() is infallible; no panic on registry initialization) |
| Architecture Authority | ADR-016 Decision 2 (inventory crate, feature-gated partner registration, OnceLock initialization) |
| Binding Decisions | D21 (ecosystem-parity scope expansion) |
| Module | pregolya-core / core::serializable::registry |
| Priority | P1 |
| Wave | 2 |
| Test Types | unit + integration (feature-flag compilation variants) |
