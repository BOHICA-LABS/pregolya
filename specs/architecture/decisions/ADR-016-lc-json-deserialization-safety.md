---
document_type: adr
level: L3
adr_id: "016"
slug: lc-json-deserialization-safety
title: "lc-JSON Round-Trip and Deserialization Safety: Type Registry, Reviver Design, Untrusted-Input Containment"
status: accepted
date: "2026-07-20"
producer: architect
timestamp: 2026-07-20T00:00:00Z
version: "1.2"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D21]
supersedes: null
superseded_by: null
subsystems_affected: [SS-19]
changelog:
  - "1.2 (burst-224/2026-07-21): F-P129-06 — fix Decision 3 Property 1 and Property 4 code sketches: replace non-canonical `category: Serialization` with `component: Component::SRLZ, category: Category::VAL` per ADR-010 adjudication (Serialization is not a canonical Category variant)."
  - "1.1 (crates.io/2026-07-20): Record validated pin `inventory = \"0.3\"` (0.3.24, dtolnay, MSRV 1.62, WASM-safe); add keep-pin-fresh note re: compiler-internal tracking."
  - "1.0 (D21/2026-07-20): Initial ADR — core::serializable in ferrochain-core, inventory-crate static registry, 141 core-internal entries, feature-gated partner registration, untrusted-deserialization safety (allowlist = registered set, no path loading, secret stripping), 12 langchain-monolith entries unregistered, one-way Python checkpoint import compatibility."
---

# ADR-016: lc-JSON Round-Trip and Deserialization Safety

**Status:** Accepted — D21 ecosystem-parity scope expansion (SECURITY-CRITICAL)

## Context

D21 promotes LC serialization/load (lc-JSON) to full v1 scope. The Python reference corpus
(`langchain_core/load/`) defines a round-trip serialization protocol:
- `LcSerializable`: opt-in trait that types implement to be serializable via lc-JSON
- `Reviver`: deserializes lc-JSON back to typed objects using a type registry
- `SERIALIZABLE_MAPPING`: 178 raw registry entries (176 unique after collision resolution);
  141 resolve to `langchain_core` types; 23 to partner packages; 12 to the `langchain`
  aggregation package (no ferrochain owner)

Two security problems in the Python implementation must be solved by construction in Rust:
1. **Arbitrary-type instantiation**: the Python Reviver can instantiate any registered type
   from an untrusted JSON blob. In Python, the type registry is a mutable global dict; a
   sufficiently crafted blob could invoke constructors with adversarial kwargs.
2. **Namespace allowlist drift**: `DEFAULT_NAMESPACES` in Python is a hand-maintained list
   that has drifted from the actual registered set (three entries registered but not
   allowlisted; two namespaces allowlisted but with no registered entries).

Semport analysis (Pass 8 ADR-3 / rust-translation-strategy.md §9) has fully characterized
the registry contents and confirmed the design implication: ferrochain must derive the valid
allowlist FROM the registered set, not maintain a parallel hand-written list.

## Decision 1 — Crate Placement: `core::serializable` in ferrochain-core

The 141 core-internal registrations are all core types (`PromptTemplate`, `ChatPromptTemplate`,
`SystemMessage`, `HumanMessage`, `AiMessage`, etc.). The `LcSerializable` trait and the
`Reviver` are foundational primitives analogous to `Runnable` — they belong in ferrochain-core.

Module path: `ferrochain_core::serializable` (file: `ferrochain-core/src/serializable.rs`,
split into `ferrochain-core/src/serializable/` if it exceeds the 500-line soft target).

Partner crates register their entries via the same `inventory`-based plugin seam (Decision 2).
No new crate is created for lc-JSON — it is a ferrochain-core module.

## Decision 2 — Registry Mechanism: `inventory` Crate (Static Link-Time Registration)

**Chosen: `inventory` crate (`inventory::submit!` macro).**

The `inventory` crate uses linker constructor sections (`.init_array` / `__attribute__((constructor))`)
to collect `submit!`-registered values into a static iterable at program startup. This gives:

- **Allowlist determined at compile time** by Cargo feature selection — the registered set
  is structurally identical to what is compiled in.
- **No runtime mutation**: no `HashMap::insert` at runtime; no way for untrusted code to
  add new registry entries post-load.
- **No reflection, no dynamic plugin loading**: registered types are statically known
  at link time.
- **Feature-gated partner registration**: `ferrochain-openai` calls `inventory::submit!`
  for its 4 lc-ids only when `features = ["lc-serializable"]` is enabled. Enabling that
  feature in `Cargo.toml` is the only way to make those types loadable.

**Validated pin (crates.io/2026-07-20):** `inventory = "0.3"` (current: 0.3.24, dtolnay,
actively released Q1-2026, edition-agnostic, MSRV 1.62, WASM-safe via constructor model).
Note: keep this pin reasonably current when updating the Rust toolchain — constructor-section
crates (`inventory`, `linkme`) track compiler internals and occasionally require a patch
bump alongside a Rust stable release. The caret `"0.3"` bound covers patch updates within
the 0.3 series automatically.

The valid-namespace allowlist is **derived from the registered set** at program startup
(one `OnceLock<HashSet<String>>` populated by iterating over `inventory::iter::<LcEntry>()`
and collecting the namespace component of each `lc_id`). This is the design implication
identified in Pass 8: deriving the allowlist from the registry eliminates the drift class.

### `LcSerializable` trait

```rust
// ferrochain-core: core::serializable
pub trait LcSerializable: Send + Sync {
    /// Fully-qualified type ID as a namespace path.
    /// Example: ["langchain_core", "prompts", "prompt", "PromptTemplate"]
    fn lc_id() -> &'static [&'static str] where Self: Sized;

    /// Fields to exclude from serialization (credential fields by name).
    /// Aligned with DI-010: credential values never appear in serialized output.
    fn lc_secrets(&self) -> &'static [&'static str] { &[] }

    /// Additional attributes beyond serde fields. Defaults to empty.
    fn lc_attributes(&self) -> serde_json::Map<String, serde_json::Value> {
        serde_json::Map::new()
    }

    /// Opt-in: types that do not implement this return false.
    fn is_lc_serializable() -> bool where Self: Sized { false }
}
```

### `Serialized` enum (the wire format)

```rust
#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Serialized {
    Constructor {
        lc: u8,
        id: Vec<String>,
        kwargs: serde_json::Map<String, serde_json::Value>,
    },
    Secret {
        lc: u8,
        id: Vec<String>,
    },
    NotImplemented {
        lc: u8,
        id: Vec<String>,
        repr: Option<String>,
    },
}
```

### Registry entry type

```rust
pub struct LcEntry {
    pub lc_id: &'static [&'static str],
    /// Constructor: takes kwargs (pre-validated Map) → Result<Box<dyn Any + Send + Sync>>
    pub constructor: fn(
        serde_json::Map<String, serde_json::Value>,
    ) -> Result<Box<dyn Any + Send + Sync>, FerrochainError>,
}
inventory::collect!(LcEntry);
```

Core types call `inventory::submit! { LcEntry { lc_id: &[...], constructor: |kwargs| ... } }`.
Partner crates do the same, feature-gated.

## Decision 3 — Untrusted-Input Deserialization Safety

Five safety properties, each enforced by construction:

### Property 1: Only registered types are instantiated

The `Reviver` checks `inventory::iter::<LcEntry>()` at startup and builds a `HashMap<Vec<String>, &LcEntry>`.
Any `id` NOT in this map returns:
```
Err(FerrochainError { component: Component::SRLZ, category: Category::VAL, code: "E-SRLZ-001",
    message: "unknown-serializable: type id not in registry" })
```
No fallback, no silent `None`. Consistent with DI-014 (no silent empty returns on validation failure).

### Property 2: No path-based loading (eliminates a whole attack class)

Python's `load_from_path` allows loading a type by Python module path string if
`DISALLOW_LOAD_FROM_PATH` does not contain it. This mechanism allows loading arbitrary
classes from installed packages given a valid dotted path.

**ferrochain has no path-based loading.** There is no `load_from_path` API. The registry
is the ONLY deserialization path. This eliminates the path-traversal attack class entirely.

### Property 3: Secret fields stripped from kwargs before constructor dispatch

`LcSerializable::lc_secrets()` returns the field names that carry credentials. Before
calling the registered constructor, the Reviver strips these keys from `kwargs`:

```rust
for secret_key in entry.lc_secrets() {
    kwargs.remove(secret_key);
}
// Then call: (entry.constructor)(kwargs)
```

This prevents a crafted lc-JSON blob from injecting a credential value (e.g., an API key)
via the `kwargs` map. Constructors that need credentials receive them via normal
`Arc<dyn Credentials>` DI — not from the deserialized payload. Consistent with DI-010.

### Property 4: 12 `langchain`-monolith entries are deliberately unregistered

`LLMChain`, `ToolAgentAction`, `OutputFixingParser`, and the other 9 entries that resolve
to the `langchain` aggregation package (which ferrochain does not port) return:
```
Err(FerrochainError { component: Component::SRLZ, category: Category::VAL, code: "E-SRLZ-002",
    message: "unsupported-serializable: langchain-monolith type not ported to ferrochain" })
```
This is a structured error with a clear message — not a panic, not a silent `None`.

### Property 5: The allowlist is derived, not hand-maintained

The valid-namespace `HashSet<String>` is computed once at startup from the registered set.
It is used only to provide a fast pre-check before the full registry lookup. The registry
is still the authoritative gate. This design eliminates the allowlist drift class found in
the Python implementation (namespaces in the allowlist but not in the registry, and vice versa).

## Decision 4 — Legacy Namespace Remapping and Version Tolerance

The Python reference corpus has 178 raw entries across 4 source dictionaries, collapsing
to 176 unique keys after JS↔SERIALIZABLE collisions. Legacy aliases (e.g., `ChatBedrock`
has 3 lc-ids pointing to the same class) are handled by registering MULTIPLE `LcEntry`
instances with the same constructor but different `lc_id` values. The ferrochain core
crate ships a legacy remap for `OLD_CORE_NAMESPACES_MAPPING` (58 entries) and the JS /
OG remaps — all pointing to the same constructors as the canonical IDs.

Version tolerance: lc-JSON blobs from older langchain versions may carry older namespace
prefixes. The legacy remap handles this transparently — callers do not need to know which
version serialized the blob.

## Decision 5 — One-Way Python Checkpoint Import Tool Compatibility

The existing one-way Python-checkpoint import tool (noted in the D21 task context) reads
Python-serialized checkpoints and converts them to ferrochain format. It uses the `Reviver`
to deserialize checkpoint payloads. This is read-only: the Reviver is called with the same
allowlist and the same safety properties. The import tool does NOT bypass the registry.

If a Python checkpoint contains a `langchain`-monolith type (E-SRLZ-002) or an unregistered
type (E-SRLZ-001), the import returns a structured error identifying the unloadable entry
so the user can handle it (skip, partial import, etc.). No silent data loss.

## Rationale

**`inventory` vs `OnceLock<HashMap>` (explicit runtime registration):** The `OnceLock`
approach requires each partner crate to call a registration function at startup
(e.g., `ferrochain_openai::register_lc_types()`). This is error-prone: a crate that
is compiled in but whose registration function is never called leaves its types
unloadable with no compile-time warning. `inventory` uses linker constructors —
types are registered the moment the binary links them in, with no caller ceremony.
The allowlist is therefore structurally determined by Cargo features, which is
the correct security model.

**Why `inventory` and not `linkme`?** Both use the same linker-section mechanism.
`inventory` is the dominant choice in the Rust ecosystem for this pattern, has a
larger maintenance footprint, and the API (`submit!` / `iter`) is more stable.
`linkme` would also work; `inventory` is preferred.

**Why not a `serde::Deserializer`-based approach?** serde's tagged enum deserialization
could handle the dispatch, but the `#[serde(tag="type")]` mechanism does not support
the open-ended registry that lc-JSON requires (new types added by partner crates at
link time). The `Serialized` enum captures the wire format; the Reviver adds the
registry-based open dispatch on top.

## Alternatives Considered

### Alt A: OnceLock<HashMap> explicit runtime registration

Arguments for: no linker magic; fully standard Rust.
Rejected: silent non-registration when a crate is compiled but its init function is not
called is a production-grade defect. `inventory`'s linker-section mechanism guarantees
registration on link.

### Alt B: Hand-maintained match statement (no registry)

Arguments for: zero runtime overhead; fully static.
Rejected: 141+ entries with legacy aliases is unmaintainable as a match statement.
Partner crates cannot contribute to a match in ferrochain-core without forking the crate.
Not extensible.

### Alt C: serde untagged enum with Box<dyn Any>

Arguments for: familiar serde pattern.
Rejected: `Box<dyn Any>` erases the type; callers must downcast. The registry approach
with concrete constructors returning typed results is safer and provides better error
messages.

### Alt D: Port DISALLOW_LOAD_FROM_PATH to control path loading

Arguments for: parity with Python implementation.
Rejected: ferrochain eliminates path-based loading entirely. There is no scenario where
arbitrary `module.path.ClassName` loading from deserialized data is safe. The parity
objective is behavioral fidelity in round-trip results, not API surface parity — the
security posture is strictly better than the reference.

## Source / Origin

- **D21 (burst 216)**: ecosystem-parity scope expansion for lc-JSON.
- **semport/core/rust-translation-strategy.md §9 (Pass 7 + Pass 8 ADR-3)**: complete
  characterization of registry contents (141 core / 23 partner / 12 monolith), alias
  multiplicity, allowlist drift, one-way Python import compatibility, inventory vs explicit
  registration design question.
- **ADR-004**: serde + schemars foundation; `LcSerializable` builds on serde.
- **DI-010**: credential opacity — `lc_secrets()` field exclusion from serialized output.
- **DI-014**: no silent empty returns — E-SRLZ-001 and E-SRLZ-002 are structured errors.
- **R12** (deserialization-of-untrusted-input risk from D21 scope): the security surface
  introduced by loading lc-JSON from external sources.

## Consequences

- `core::serializable` is a new module in ferrochain-core. `LcSerializable`, `Serialized`,
  `LcEntry`, and `Reviver` are new public types in ferrochain-core.
- `inventory` crate becomes a dependency of ferrochain-core (also used by
  ferrochain-vectorstores for the adapter extension seam per ADR-014).
- Partner crates (ferrochain-openai, ferrochain-anthropic, ferrochain-ollama) gain an
  optional `lc-serializable` Cargo feature that activates their `inventory::submit!` calls.
- The valid-namespace `HashSet<String>` is computed once at startup in a `OnceLock`
  populated from `inventory::iter::<LcEntry>()`. This adds ~1ms to binary startup.
- The one-way Python checkpoint import tool uses the Reviver with full safety properties.
  E-SRLZ-001 / E-SRLZ-002 propagate as structured errors to the import caller.
- VP-010 candidate: prove that a type NOT in the registry NEVER successfully deserializes.
