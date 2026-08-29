---
document_type: adr
level: L3
adr_id: "026"
slug: lcel-composition-primitives-parallel-passthrough
title: "LCEL Composition Primitives: RunnableParallel and RunnablePassthrough (burst-302 scope expansion)"
status: accepted
producer: architect
timestamp: 2026-08-17T00:00:00Z
date: "2026-08-17"
subsystems_affected: ["SS-01"]
supersedes: []
superseded_by: null
version: "1.7"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D_BURST302_TBD]
changelog:
  - "1.7 (round-40/F-P2A168-02/2026-08-29): Fix nested impl Trait in associated-type binding (E0562-class, non-realizable on stable Rust) at all 4 ADR-026 sites. The form `impl IntoIterator<Item = (impl Into<String>, Arc<dyn DynRunnable>)>` uses impl Trait inside an associated-type projection, which is only permitted at the outermost argument position on stable Rust. Replaced with named generic K: Into<String> at all 4 sites: §Decision 1 constructor (RunnableParallel::new), §Decision 4 assign method body, §Interface-Definitions Additions RunnableParallel::new signature, §Interface-Definitions Additions RunnablePassthrough::assign signature. Canonical form: `pub fn new<K: Into<String>>(steps: impl IntoIterator<Item = (K, Arc<dyn DynRunnable>)>) -> Self`. Source: F-P2A168-02 [MED] round-40 full-re-derivation; sibling fix at interface-definitions.md §RunnableParallel and §RunnablePassthrough."
  - "1.6 (P1D-208/F-P208-01/2026-08-18): §Decision 2 Key behavioral properties item 4 — E-CORE-011 INTERNAL category rendered as bare `Internal` corrected to ALL-CAPS taxonomy code `INTERNAL` per ADR-010 §Category casing canon (matches sibling item 3 `EXEC` form)."
  - "1.5 (burst-315/F-B1/2026-08-17): Decision 2 collect-loop sketch: replace `.unwrap()` with `.ok_or_else(|| PregolyaError::new(Component::Core, Category::Internal, RetryHint::Never, \"E-CORE-011\", format!(\"RunnableParallelTaskPanic: task panicked: missing branch key '{key}'\")))?` — eliminates no-unwrap convention violation (CLAUDE.md §Code Conventions). The key-presence invariant holds when the JoinSet loop completes without early-return error, but `.unwrap()` on an `Option` is forbidden in non-test code regardless of logical guarantee. E-CORE-011 (INTERNAL, minted burst-309) is the canonical expression for this programming-error invariant violation on the task-panic path. Disclaimer note retained."
  - "1.4 (burst-309/F-P201-01/2026-08-17): Mint E-CORE-011 (INTERNAL, broken, BC-2.01.006 PC-4, RetryHint Never) for the RunnableParallel JoinError/task-panic path. Highest existing CORE code was E-CORE-010; no existing INTERNAL code covers a JoinSet task panic (E-CORE-007 is GuardrailHookPanic; E-CORE-004 is pipe-composition failure; E-CORE-006 is recursion-limit). (1) §Decision 2 collect-loop sketch JoinError branch: `'E-CORE-NNN'` → `'E-CORE-011'`; comment updated. (2) Behavioral property 4: code field added (`code: E-CORE-011`). (3) §Error codes minted: E-CORE-011 row added. Near-name check: RunnableParallelTaskPanic vs RunnableParallelBranchFailure (E-CORE-009) — distinct paths (task panic at JoinSet level vs branch Err return) — no collision. Branch key is NOT available at the JoinError catch site (JoinSet::join_next yields JoinError only; key lives inside the task closure); message template omits `<key>`."
  - "1.3 (burst-308/F-P200-03+04/2026-08-17): Two Decision 2 sketch corrections. F-P200-03 (MED): behavioral property 3 message template corrected from `\"RunnableParallel branch '<key>' failed: <cause>\"` to canonical form `\"RunnableParallelBranchFailure: branch '<key>' failed: <cause>\"` (matching §Error codes minted form and error-taxonomy E-CORE-009 message template). F-P200-04 (OBS): illustrative sketch aligned to canonical types — (1) `ErrorCategory::Internal` → `Category::Internal` (PascalCase canon per ADR-010); (2) `RetryHint::NoRetry` → `RetryHint::Never` (canonical variant name); (3) `\"E-CORE-009\"` removed from JoinError→Internal path (E-CORE-009 is the EXEC branch-failure code per BC-2.01.006 PC-4; JoinError maps to Category::Internal WITHOUT E-CORE-009); (4) E-CORE-009 wrapping added inside spawned task where branch key is in scope; (5) `\"parallel\"` string-literal → `Component::Core` (canonical Component enum path)."
  - "1.2 (burst-304/F-P195-02/F-P195-03/2026-08-17): Module-path canon + error-code placeholder resolution. F-P195-02 (HIGH): §Consequences item 2: `core::runnable::parallel` + `core::runnable::passthrough` → `core::runnable` (files parallel.rs / passthrough.rs; canonical 2-level registry form per module-decomp and ADR-026 §Decision 5). §Consequences item 4: `targeting `core::runnable::parallel`` → `targeting `core::runnable``. §VP Recommendation: `module `core::runnable::parallel`` → `module `core::runnable``. §New Domain Invariant Enforcer: `core::runnable::parallel` via JoinSet → `core::runnable` (via parallel.rs JoinSet). F-P195-03 (MED): §Decision 2 code sketch: `E-CORE-NNN` → `E-CORE-009`. §Decision 2 behavioral property 3: E-CORE-NNN → E-CORE-009 (two sites). §Error new-code placeholder section: reframed as resolved record (codes minted: E-CORE-009 EXEC / E-CORE-010 VAL). §Decision 4 doc comment + behavioral property 1a: E-CORE-MMM → E-CORE-010. §Consequences item 5: reframed as resolved (codes minted). §Interface-Definitions Additions: E-CORE-NNN → E-CORE-009; E-CORE-MMM → E-CORE-010."
  - "1.1 (burst-303/F-P194-01/2026-08-17): Fix method surface mismatch — change invoke_dyn→invoke and stream_dyn→stream everywhere in ADR body to match canonical DynRunnable trait declared in interface-definitions.md §DynRunnable and RunnableSequence. Affects: §Context (DynRunnable::invoke_dyn reference), §Decision 2 (async fn invoke_dyn code block → async fn invoke; branch.invoke_dyn → branch.invoke; stream_dyn → stream in Streaming section), §Decision 3 (behavioral properties 1 and 2), §Decision 4 (behavioral properties 1 and 2; mapper.invoke_dyn → mapper.invoke), §VP Recommendation (invoke_dyn reference). The DynTool pattern (invoke_dyn/stream_dyn) is distinct from DynRunnable (invoke/stream); confusing them is a method-surface mismatch."
  - "1.0 (burst-302/scope-expansion/2026-08-17): Initial decision — human-directed Phase-1 approval-gate scope expansion. Adds RunnableParallel, RunnablePassthrough, and RunnableAssign to pregolya v1. Five decisions: (1) RunnableParallel type representation and key ordering; (2) concurrent execution and error handling; (3) RunnablePassthrough identity semantics; (4) RunnableAssign dict augmentation; (5) pipe composition and module placement."
---

# ADR-026: LCEL Composition Primitives — RunnableParallel and RunnablePassthrough

**Status:** Accepted — burst-302 human-directed Phase-1 approval-gate scope expansion.

---

## Context

The human senior architect ruled at the Phase-1 approval gate that `RunnableParallel` and
`RunnablePassthrough` are IN SCOPE for pregolya v1. This is a sanctioned scope expansion
analogous to D21 (ecosystem-parity: prompt templates, vectorstores, embeddings) and D23
(first-party tools, HITL per-tool-call hook). Phase-1 approval is conditional on completing
the corresponding CAP, BC, and architecture additions.

### LangChain v1.3.13 reference semantics

Reference files (read-only):
- `RunnableParallel`: `.reference/langchain/libs/core/langchain_core/runnables/base.py` §class RunnableParallel
- `RunnablePassthrough` and `RunnableAssign`: `.reference/langchain/libs/core/langchain_core/runnables/passthrough.py`

**RunnableParallel** (`base.py` §RunnableParallel):
- One of the two main LCEL composition primitives (alongside `RunnableSequence`).
- Holds a `Mapping[str, Runnable[Input, Any]]` — a named dict of branches.
- `invoke(input)`: runs all branches concurrently against the **same input**; returns
  `dict[str, Any]` keyed by branch name with each branch's output.
- Sync concurrency: `ThreadPoolExecutor` (via `get_executor_for_config`). Each branch
  runs as a `Future`; `future.result()` for each branch in iteration order.
- Async concurrency: `asyncio.gather(...)` over branch `ainvoke` coroutines.
- Error semantics: **fail-fast** — the first branch error is re-raised; remaining branches
  are not waited on (`asyncio.gather` without `return_exceptions=True`). No partial result
  dictionary is emitted.
- Streaming (`transform`/`atransform`): fans out to each branch's `transform` generator;
  yields `AddableDict({branch_name: chunk})` chunks as they arrive (interleaved).
- Branch output types may be heterogeneous (Python's `Any`).
- Alias: `RunnableMap = RunnableParallel`.

**RunnablePassthrough** (`passthrough.py` §RunnablePassthrough):
- Identity runnable: `invoke(input)` returns `input` unchanged.
- Optional `func`/`afunc`: side-effect callback called with the input value; does NOT
  alter the return value. Used for logging, tracing, inspection.
- Streaming: passes each chunk through unchanged.
- `InputType == OutputType` for all invocation paths.

**RunnableAssign** (from `RunnablePassthrough.assign(**kwargs)`, `passthrough.py` §RunnableAssign):
- Created via the classmethod `RunnablePassthrough.assign(**kwargs)` where each kwarg
  value is a `Runnable` or `Callable` operating on the input dict.
- Internally: wraps a `RunnableParallel(kwargs)` as its `mapper`.
- `invoke(input)` requires `input` to be a `dict`; raises `ValueError` otherwise.
- Output: `{**input, **mapper.invoke(input)}` — input dict spread first, mapper output
  second; **mapper keys overwrite input keys on collision**.
- Streaming: splits input stream with `safetee`; runs mapper stream and passthrough stream
  in parallel; yields passthrough chunks (filtered) then mapper chunks.

### Pregolya architecture integration constraints

- Pregolya uses `DynRunnable` for type-erased composition (interface-definitions.md
  §DynRunnable and RunnableSequence). `DynRunnable::invoke` takes and returns
  `serde_json::Value`. Both new types MUST implement `DynRunnable` to compose via
  `pipe()` (BC-2.01.004).
- Error propagation: CLAUDE.md §Code Conventions mandates "No silent empty returns
  where partial-failure should propagate." This amplifies langchain's fail-fast semantics
  to require structured `PregolyaError` with the failing branch key identified — not a
  bare `raise`.
- Tokio multi-threaded runtime (ADR-001 Alt-B HYBRID). No blocking I/O on the Tokio
  thread pool. Async-first; sync facade via `Handle::block_on` where needed.
- `#[non_exhaustive]` on all public API structs (ADR-023 §Required Inventory).

---

## Decision 1 — RunnableParallel: Type Representation and Key Ordering

`RunnableParallel` is a newtype struct holding an `IndexMap<String, Arc<dyn DynRunnable>>`:

```rust
#[non_exhaustive]
pub struct RunnableParallel {
    steps: IndexMap<String, Arc<dyn DynRunnable>>,
}
```

Rationale for `IndexMap` over `HashMap`:
- Preserves insertion order → **deterministic output key order** in the returned
  `serde_json::Map<String, Value>`. This enables round-trip and property-based tests
  to assert output structure without sort-dependent comparisons.
- Matches the `Mapping` (insertion-ordered in Python 3.7+) behavior of the reference.
- `IndexMap` is already a transitive dependency (indexmap crate) in pregolya via
  serde_json's preserve-order feature.

Constructor:
```rust
impl RunnableParallel {
    pub fn new<K: Into<String>>(
        steps: impl IntoIterator<Item = (K, Arc<dyn DynRunnable>)>
    ) -> Self { .. }
}
```

No Python-style dict-literal coercion in Rust — callers construct `RunnableParallel::new(...)`
explicitly. This is a deliberate Rust-idiom simplification: no magic coercion from
`HashMap<_, _>` to `RunnableParallel`.

Output type: `serde_json::Value::Object(Map<String, Value>)` where each key is the
branch name and each value is the JSON-serialized branch output. The output `Map` follows
IndexMap's insertion order (= `steps` key order).

---

## Decision 2 — RunnableParallel: Concurrent Execution and Error Handling

### Async invocation (canonical path)

Use `tokio::task::JoinSet` for fan-out:

```rust
async fn invoke(
    &self,
    input: serde_json::Value,
    config: Option<RunnableConfig>,
) -> Result<serde_json::Value, PregolyaError> {
    let mut set = tokio::task::JoinSet::new();
    for (key, branch) in &self.steps {
        let branch = Arc::clone(branch);
        let input = input.clone();
        let config = config.clone();
        let key = key.clone();
        set.spawn(async move {
            // Branch failure path: wrap with E-CORE-009 (Category::Exec), identifying the branch
            let out = branch.invoke(input, config).await.map_err(|cause| PregolyaError::new(
                Component::Core,
                Category::Exec,
                RetryHint::Never,
                "E-CORE-009",
                format!("RunnableParallelBranchFailure: branch '{}' failed: {}", key, cause.message),
            ))?;
            Ok::<(String, serde_json::Value), PregolyaError>((key, out))
        });
    }
    // Collect results in steps order
    let mut results: IndexMap<String, serde_json::Value> =
        IndexMap::with_capacity(self.steps.len());
    // join_next() returns tasks in completion order; re-insert in steps order below
    let mut raw: Vec<(String, serde_json::Value)> = Vec::with_capacity(self.steps.len());
    while let Some(join_result) = set.join_next().await {
        // JoinError (task panic): Category::Internal; NOT E-CORE-009 (per BC-2.01.006 PC-4)
        let branch_result = join_result.map_err(|je| PregolyaError::new(
            Component::Core,
            Category::Internal,
            RetryHint::Never,
            "E-CORE-011", // E-CORE-011 INTERNAL: RunnableParallel task panic (JoinError); minted burst-309
            format!("RunnableParallel task panic: {je}"),
        ))??;
        raw.push(branch_result);
    }
    // Re-order to match steps insertion order
    for key in self.steps.keys() {
        let val = raw.iter().find(|(k, _)| k == key)
            .map(|(_, v)| v.clone())
            .ok_or_else(|| PregolyaError::new(
                Component::Core,
                Category::Internal,
                RetryHint::Never,
                "E-CORE-011",
                format!("RunnableParallelTaskPanic: task panicked: missing branch key '{key}'"),
            ))?; // all tasks complete above; missing key is programming-error invariant violation
        results.insert(key.clone(), val);
    }
    Ok(serde_json::Value::Object(
        serde_json::Map::from_iter(results)
    ))
}
```

The illustrative sketch above shows the intent; the implementer will write the canonical
form. Key behavioral properties:

1. All branches launch concurrently before any result is awaited.
2. **Fail-fast with abort**: if `JoinSet::join_next()` yields an error, call
   `set.abort_all()` to cancel remaining in-flight branches; return the error
   immediately. No partial result dictionary is produced.
3. Error wraps the failing branch's key in the message:
   `PregolyaError { category: EXEC, code: E-CORE-009, message: "RunnableParallelBranchFailure: branch '<key>' failed: <cause>", .. }`.
   Minted as `E-CORE-009` in `error-taxonomy.md` (burst-302b/BC-2.01.006 authoring).
4. JoinError (tokio task panic) maps to `PregolyaError { category: INTERNAL, code: E-CORE-011, .. }` per
   ADR-010 §Class 1.

### Streaming

For `stream(input: Value)`:
- Spawn one task per branch that calls `branch.stream(input.clone())`.
- Merge streams via `tokio::sync::mpsc` channel or `futures::stream::select_all`;
  each chunk is a `serde_json::Value::Object` with one key (the branch name) and the
  chunk value — equivalent to Python's `AddableDict({key: chunk})`.
- First stream error aborts all branch streams and propagates.

### Error codes (minted)

Codes minted in `error-taxonomy.md` (burst-302b/BC-2.01.005/006 authoring; E-CORE-011 minted burst-309):
- `E-CORE-009` (category EXEC): RunnableParallel branch failure; message template
  `"RunnableParallelBranchFailure: branch '<key>' failed: <cause>"`.
- `E-CORE-010` (category VAL): RunnableAssign non-dict input; message template
  `"RunnableAssignNonDictInput: input to RunnablePassthrough.assign() must be a JSON object"`.
- `E-CORE-011` (category INTERNAL): RunnableParallel task panic (JoinError); message template
  `"RunnableParallelTaskPanic: task panicked: <detail>"`. One placeholder: `<detail>` = JoinError
  display string (`je.to_string()`). The branch key is NOT available at the JoinError catch site
  (JoinSet::join_next yields JoinError only; key lives inside the task closure). RetryHint: Never
  (INTERNAL default — a task panic is a programming-error invariant violation; same code path
  always panics on retry). BC anchor: BC-2.01.006 PC-4.

---

## Decision 3 — RunnablePassthrough: Zero-Cost Identity

```rust
/// Identity runnable — passes input through unchanged.
/// Optionally calls an inspect function for side effects (logging, tracing).
/// Implements `DynRunnable`; compose with `pipe()`.
#[non_exhaustive]
pub struct RunnablePassthrough {
    inspect_fn: Option<Arc<dyn Fn(&serde_json::Value) + Send + Sync>>,
}
```

Behavioral properties:
1. `invoke(input, config)` → calls `inspect_fn(input)` if present (side effect only,
   no mutation), then returns `Ok(input)` — exact same value passed through.
2. `stream(input, config)` → passes each chunk through unchanged; calls `inspect_fn`
   on the reassembled input after stream exhaustion (mirroring Python's `transform` behavior
   which accumulates then calls `func`).
3. The `inspect_fn` MUST NOT alter the return value; it is a read-only callback.
4. Constructor: `RunnablePassthrough::new()` (no inspect) and
   `RunnablePassthrough::with_inspect(f: impl Fn(&serde_json::Value) + Send + Sync + 'static)`.

`#[non_exhaustive]` is applied to the struct. Callers cannot construct via struct literal
(E0639); they use `RunnablePassthrough::new()` or `::with_inspect(...)`.

---

## Decision 4 — RunnableAssign: Dict Augmentation

```rust
/// Augments a dict input with additional computed keys.
/// Created via `RunnablePassthrough::assign(...)`.
#[non_exhaustive]
pub struct RunnableAssign {
    mapper: RunnableParallel,
}

impl RunnablePassthrough {
    /// Create a `RunnableAssign` that augments a dict input.
    ///
    /// Each entry in `pairs` is `(key, runnable)` where `runnable` receives the full
    /// input dict and its output is inserted at `key` in the result.
    ///
    /// # Errors
    /// Returns `Err(PregolyaError { category: VAL, code: E-CORE-010, .. })` at invoke time
    /// if the input is not a JSON object.
    pub fn assign<K: Into<String>>(
        pairs: impl IntoIterator<Item = (K, Arc<dyn DynRunnable>)>
    ) -> RunnableAssign {
        RunnableAssign {
            mapper: RunnableParallel::new(pairs),
        }
    }
}
```

Behavioral properties:
1. `invoke(input, config)`:
   a. Validate: if `input` is not `Value::Object(...)`, return
      `Err(PregolyaError { category: VAL, code: E-CORE-010, .. })`.
   b. Run `self.mapper.invoke(input.clone(), config.clone()).await?` to get the
      augmentation map.
   c. Merge: start with `input`'s object fields; overwrite/insert with mapper output
      fields. **Mapper output keys take precedence** (matching Python's `{**value, **mapper.invoke(value)}`).
   d. Return `Ok(Value::Object(merged_map))`.
2. `stream(input, config)`: split input stream into two copies; run
   passthrough stream and mapper stream in parallel; yield passthrough chunks first
   (filtered to exclude mapper-output keys), then mapper chunks — matching Python's
   `_transform` safetee pattern.
3. Key-overwrite semantics: documented in BC edge cases; callers should not rely on
   specific ordering if their input keys collide with mapper keys.

`RunnableAssign` implements `DynRunnable` and therefore composes via `pipe()`.

---

## Decision 5 — Pipe Composition and Module Placement

### Pipe composition

All three types implement `DynRunnable`:
- `RunnableParallel: DynRunnable` (heterogeneous branches via type erasure)
- `RunnablePassthrough: DynRunnable` (identity)
- `RunnableAssign: DynRunnable` (dict augmentation wrapper)

Since `RunnableSequence` holds `Box<dyn DynRunnable>` stages (interface-definitions.md
§DynRunnable and RunnableSequence), all three types compose freely via `pipe()` with any
other pregolya `Runnable`. No changes to `pipe()` semantics or `RunnableSequence` structure
are required.

Coercion note: Python's implicit dict-literal-to-`RunnableParallel` coercion in the `|`
pipe operator is **not** implemented in Rust. Callers must construct `RunnableParallel::new(...)`
explicitly. This is the correct Rust idiom (no magic coercion; explicitness over convenience).

### Module placement

```
pregolya-core
└── core::runnable                      (existing, BC-2.01.003/004)
    ├── parallel.rs                     NEW — RunnableParallel + RunnableAssign
    └── passthrough.rs                  NEW — RunnablePassthrough
```

Public re-exports from:
- `pregolya_core::runnables::{RunnableParallel, RunnablePassthrough, RunnableAssign}`
- `pregolya_core::prelude::{RunnableParallel, RunnablePassthrough, RunnableAssign}`

Module placement justification: SS-01 (Core Primitives, pregolya-core) owns all base
LCEL composition primitives. `RunnableSequence` already lives in `core::runnable`; the
parallel/passthrough primitives belong in the same subsystem. The CAP assigned to
these types is CAP-039 (SS-01 scope; product-owner and business-analyst author next).

---

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| `HashMap<String, ...>` instead of `IndexMap<String, ...>` for `RunnableParallel.steps` | Non-deterministic output key order; breaks round-trip property tests and streaming determinism guarantees. `IndexMap` costs one extra dependency but is already transitive via serde_json. REJECT. |
| `Box<dyn DynRunnable>` instead of `Arc<dyn DynRunnable>` for branches | `Arc` enables sharing a branch across multiple `RunnableParallel` instances and across Tokio tasks (which require `Send + 'static`). `Box` requires move semantics; cloning for multi-task fan-out would require `Clone` bound on `DynRunnable`, which is not in the current ADR-005 design. REJECT. |
| Partial-result aggregation (collect all branch results including errors) | Langchain's reference behavior is fail-fast. Partial results create ambiguous state: caller cannot distinguish "branch 'b' returned None" from "branch 'b' was not reached." Production-grade rule requires explicit error propagation, not implicit empty result. Return full error with branch key; caller retries or handles. REJECT. |
| Separate `RunnableInspect` struct instead of `inspect_fn` on `RunnablePassthrough` | Python's `RunnablePassthrough(func=f)` embeds the inspect on the passthrough itself. Separate type adds unnecessary API surface for a minor feature. Keep co-located as optional field. REJECT. |
| `RunnablePassthrough` as a generic `Runnable<I, I>` without `DynRunnable` | Would require `RunnablePassthrough<I>` to be typed; cannot compose in heterogeneous pipelines without explicit type annotation. `DynRunnable` + `Value` round-trip is the canonical composition path (BC-2.01.003 EC-001, ADR-005). Accept type-erasure overhead at composition boundaries. ACCEPT DYNDRUNNABLE PATH. |
| Delay `RunnableAssign` to Wave 2 | `RunnablePassthrough.assign()` is the primary consumer pattern in LCEL pipelines (RAG chains, message augmentation). Without `assign()`, `RunnablePassthrough` has limited real-world utility. Must be co-delivered. REJECT DELAY. |

---

## Consequences

1. **SS-01 BC range expands** from 001–004 to 001–008. State-manager updates ARCH-INDEX
   Subsystem Registry SS-01 row (`BCs: BC-2.01.001–008`) after BC authoring.

2. **`module-criticality.md` new rows**: `core::runnable` (the `core::runnable` module gains
   files parallel.rs: RunnableParallel + RunnableAssign; and passthrough.rs: RunnablePassthrough)
   must be classified. Recommendation: HIGH criticality (concurrent fan-out correctness, error
   propagation, dict-augmentation merge semantics — HIGH kill rate ≥ 90%).

3. **`purity-boundary-map.md` new rows**: Both new modules are Pure Core (no I/O,
   no global state, no network). Branches may perform I/O but that is encapsulated in
   `Arc<dyn DynRunnable>`; the fan-out orchestration itself is deterministic. Architect
   to add rows during burst-302 cleanup or next consistency pass.

4. **`verification-coverage-matrix.md` and VP-INDEX**: One new VP recommended
   (VP-014 — proptest, P1) targeting `core::runnable`. Product-owner authors
   VP-014 during BC authoring; state-manager propagates to VP-INDEX and
   verification-architecture.md per VP-INDEX propagation obligation.

5. **`error-taxonomy.md`**: Codes minted (burst-302b/BC authoring): `E-CORE-009` (EXEC,
   RunnableParallelBranchFailure) per Decision 2; `E-CORE-010` (VAL, RunnableAssignNonDictInput)
   per Decision 4.

6. **`interface-definitions.md`**: Architect (or product-owner per routing) adds
   `RunnableParallel`, `RunnablePassthrough`, and `RunnableAssign` struct + method
   signatures to §Core Primitives (pregolya-core: core::runnable) section. See
   §Interface-Definitions Additions below.

7. **ADR count**: 25 → 26. ARCH-INDEX §ADR Registry gains one row; state-manager
   updates at burst close.

8. **No new crates**: All types live in existing `pregolya-core` (Wave 1). No crate
   topology change; Canonical Crate Roster unchanged.

---

## BC Anchors

_(To be filled by product-owner during BC authoring.)_

| BC ID | Scope |
|-------|-------|
| BC-2.01.005 | RunnableParallel construction, concurrent invocation, keyed dict output |
| BC-2.01.006 | RunnableParallel branch failure: fail-fast with structured error; abort remaining; no partial results |
| BC-2.01.007 | RunnablePassthrough identity: invoke returns input unchanged; streaming passes chunks through; inspect side-effect contract |
| BC-2.01.008 | RunnableAssign dict augmentation: input must be JSON object; output = merge(input, mapper_output) with mapper-wins-on-collision; propagates mapper errors |

---

## VP Recommendation

**VP-014 recommended** (proptest, P1, module `core::runnable`):

Property: For any `RunnableParallel` with `N` configured branches and any input:
- If `invoke` returns `Ok(output)`: `output.as_object().unwrap().len() == N` (no key
  silently dropped from a successful result).
- Each key in the output corresponds exactly to a configured branch key (no phantom keys,
  no missing keys).

This enforces DI-016 (see §Interface-Definitions Additions) at the property level.
Kani is less suitable here (IndexMap + dynamic branch count exceeds Kani's tractable
bound with current harness style); proptest is the right tool.

Product-owner authors VP-014 file during BC authoring with this BC anchor
(BC-2.01.005 or BC-2.01.006 depending on which BC covers the key-completeness invariant).

---

## Interface-Definitions Additions

Product-owner/architect must add the following to `interface-definitions.md`
§Core Primitives (pregolya-core: core::runnable) alongside the existing `DynRunnable`
and `RunnableSequence` section:

```rust
/// Fan-out composition primitive — runs all branches concurrently on the same input.
///
/// Returns a JSON object with one key per branch; key order follows insertion order.
/// Branch errors are fail-fast: first error aborts remaining branches and returns
/// `Err(E-CORE-009)` identifying the failing branch key.
///
/// Authority: BC-2.01.005 (construction + invocation), BC-2.01.006 (error propagation),
///            ADR-026 §Decision 1 and §Decision 2.
#[non_exhaustive]
pub struct RunnableParallel {
    steps: IndexMap<String, Arc<dyn DynRunnable>>,
}

impl RunnableParallel {
    /// Construct from an ordered iterator of (key, branch) pairs.
    pub fn new<K: Into<String>>(
        steps: impl IntoIterator<Item = (K, Arc<dyn DynRunnable>)>
    ) -> Self;
}

/// Identity runnable — passes input through unchanged.
///
/// Optional inspect function is called for side effects only and does not alter output.
///
/// Authority: BC-2.01.007, ADR-026 §Decision 3.
#[non_exhaustive]
pub struct RunnablePassthrough {
    inspect_fn: Option<Arc<dyn Fn(&serde_json::Value) + Send + Sync>>,
}

impl RunnablePassthrough {
    pub fn new() -> Self;
    pub fn with_inspect(f: impl Fn(&serde_json::Value) + Send + Sync + 'static) -> Self;

    /// Create a `RunnableAssign` that augments a dict input with computed keys.
    ///
    /// Input at invoke time must be a JSON object; returns
    /// `Err(E-CORE-010)` otherwise.
    ///
    /// Authority: BC-2.01.008, ADR-026 §Decision 4.
    pub fn assign<K: Into<String>>(
        pairs: impl IntoIterator<Item = (K, Arc<dyn DynRunnable>)>
    ) -> RunnableAssign;
}

/// Dict-augmentation runnable created by `RunnablePassthrough::assign`.
///
/// Merges input dict with mapper outputs; mapper keys overwrite on collision.
///
/// Authority: BC-2.01.008, ADR-026 §Decision 4.
#[non_exhaustive]
pub struct RunnableAssign {
    mapper: RunnableParallel,
}
```

All three types implement `DynRunnable` (erasure path) and compose via `pipe()` per
BC-2.01.004.

---

## New Domain Invariant Recommendation (DI-016)

The product-owner / business-analyst team should consider adding `DI-016` to
`domain-spec/invariants.md`:

**DI-016: RunnableParallel Key-Completeness and Branch-Failure Propagation**

> For any `RunnableParallel` invocation: if the result is `Ok(output)`, then `output`
> contains exactly one key for every configured branch (no key silently absent). If any
> branch fails, the result is `Err(...)` containing the failing branch's key; no partial
> output dictionary is returned. This invariant prohibits silent degradation (empty
> output) where branch failure data should propagate — consistent with DI-014
> (Error Propagation: No Silent Swallowing).

Enforcer: `core::runnable` (via parallel.rs `JoinSet`) abort-on-first-error + structured
error. VP-014 proptest property verifies the completeness half (`Ok → N keys`).
BC-2.01.006 verifies the fail-fast error half.

Business-analyst authors DI-016 in `invariants.md`; state-manager indexes it.

---

## Rationale

1. **RunnableParallel is fundamental to LCEL ergonomics.** In real-world langchain usage,
   `RunnableParallel` is the primary mechanism for: RAG context fetch + question pass-through,
   multi-model fan-out (joke chain || poem chain), and structured data extraction from multiple
   fields simultaneously. Without it, pregolya users cannot implement canonical LangChain
   patterns.

2. **DynRunnable as the composition substrate is correct.** Type-erasing branches to
   `Arc<dyn DynRunnable>` avoids the heterogeneous-type explosion that would result from
   a generic `RunnableParallel<B1: Runnable, B2: Runnable, ...>` approach. This matches
   how `RunnableSequence` handles heterogeneous stages. The JSON boundary cost (serialization
   per branch) is acceptable for a composition primitive.

3. **Fail-fast with structured error exceeds langchain parity.** Python's
   `asyncio.gather()` cancels on first exception but loses the branch key. Pregolya's
   structured error (including branch key) provides better observability at no
   correctness cost. This satisfies the production-grade default without breaking
   langchain behavioral parity (the user-visible semantics — fail-fast — are identical).

4. **Scope belongs in SS-01 / pregolya-core.** These are foundational LCEL building
   blocks, not partner integrations or optional extensions. Co-locating them with
   `RunnableSequence` and `DynRunnable` in `core::runnable` minimizes import surface
   and aligns with langchain's own package placement (both in `langchain_core.runnables`).

5. **No new crate is warranted.** Adding a crate for two composition types would
   impose namespace reservation and release overhead disproportionate to the surface.

---

## Source / Origin

- **Human directive (burst-302)**: Phase-1 approval-gate scope expansion ruling — "add
  CAP + BCs" for RunnableParallel and RunnablePassthrough; D-NNN assigned by state-manager
  (frontmatter placeholder: `D_BURST302_TBD`).
- **Reference corpus** (read-only, pinned langchain 1.3.13):
  - `RunnableParallel` — `.reference/langchain/libs/core/langchain_core/runnables/base.py`
    §class RunnableParallel (`invoke`, `ainvoke`, `_transform` stream, `RunnableMap` alias)
  - `RunnablePassthrough` / `RunnableAssign` — `.reference/langchain/libs/core/langchain_core/runnables/passthrough.py`
    §class RunnablePassthrough, the `assign` classmethod, the `RunnableAssign` class
- **ADR-005**: Object-safety patterns (adjacent trait object-safety adjudications; DynRunnable pattern)
- **ADR-010**: Error taxonomy (error-code structure; EXEC/VAL category assignment)
- **ADR-023**: `#[non_exhaustive]` governance (Required Inventory — all three new types
  are public API surface structs requiring `#[non_exhaustive]`)
- **BC-2.01.003**: Runnable trait invocation (DynRunnable composition path)
- **BC-2.01.004**: RunnableSequence / pipe composition (EC-001 DynRunnable path; PC5 E-CORE-004)
- **interface-definitions.md** §DynRunnable and RunnableSequence — DynRunnable signature
- **D21 precedent**: ecosystem-parity scope expansion at Phase-1; same process followed here
