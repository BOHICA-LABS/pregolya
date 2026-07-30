---
document_type: adr
level: L3
adr_id: "005"
slug: logical-clock-checkpoint-ordering
title: "Logical Clock and Checkpoint Ordering (CONFLICT-4: monotonic vs wall-clock)"
status: accepted
date: "2026-07-14"
subsystems_affected: ["SS-04"]
supersedes: null
superseded_by: null
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D11]
version: "1.12"
changelog:
  - "1.12 (FIX-BURST-278/Wave-C-S4-complete/2026-07-28): S4 body annotations applied and §Failure Mode struct literal corrected. (1) S4 body: four Wave C migration routing lines annotated with (non-object-safe, E0038) qualifier — all four are classification (b) hazard-naming prose (migration origin notation), not live normative signatures. The preceding changelog entry described these edits but the prior dispatch died before applying the body changes. (2) §Failure Mode: `Err(PregolyaError { category: DURABILITY, code: E-CHKPT-003, ... })` struct literal replaced with prose error-code reference per ADR-010 Direction B PascalCase canon."
  - "1.11 (FIX-BURST-278/Wave-C-S4/2026-07-28): S4 canon — five lines in changelog and body citing Arc<dyn pregolya_core::Tool> or Option<Arc<dyn Tool>> as migration origins annotated with non-object-safe (E0038) qualifier to satisfy verify-signature-canon.sh S4 gate exemption. All five sites are classification (b): hazard-describing prose and migration routing notes (Wave C PO-routing spec and v1.9 correction changelog). The actual DynTool body definitions already use DynTool; these annotations clarify the prohibited origin type in the migration routing context."
  - "1.10 (FIX-BURST-278/F-P175-D201+D202+D211+D212+D213+D216/2026-07-28): Six findings closed. (1) F-P175-D201 — delete fabricated 4-site `dyn Tool` list still in body; body now accurately shows 0 sites after corpus re-verification (errata that claimed correction 'above' has been completed directly). (2) F-P175-D202 — Wave C migration list count corrected from 2→3: add `BC-2.09.007 ToolRegistry` as the third migration site (`Option<Arc<dyn Tool>>` → `Option<Arc<dyn DynTool>>`). (3) F-P175-D211 — `invoke` → `invoke_dyn` in prose description of DynTool method. (4) F-P175-D212 — module path `core::tools` → `core::tool` (singular) in code sketch comment per BC-2.08.010 Architecture Anchors canonical form. (5) F-P175-D213 — object-safety sentence inverted: `dyn Tool` is NOT object-safe (dyn-incompatible under E0038); prior text incorrectly stated it IS object-safe. (6) F-P175-D216 — doc comment `Err(PregolyaError { category: INTERNAL, code: E-CHKPT-002, ... })` abbreviated struct literal replaced with `PregolyaError::new(...)` full-form named-argument call per D-49."
  - "1.9 (FIX-BURST-277-WAVE-B-errata/2026-07-28): Corpus re-verification of Wave C migration list (FIX-BURST-277-WAVE-B/2026-07-27 errata). Prior v1.8 cited 4 wrong BC IDs (BC-2.05.003 PC2, BC-2.05.004 PC1, BC-2.08.010 PC2, ToolCallPreview.tool) — grep of actual corpus found zero `dyn Tool` in those BCs; ToolCallPreview never had a `tool` field. Actual non-object-safe (E0038) `Arc<dyn pregolya_core::Tool>` sites: BC-2.09.001 Description+PC2 and BC-2.09.002 PC1 (MCP tool discovery/invocation). Wave C migration list corrected in §Adjacent Adjudications note. DynTool definition also propagated to interface-definitions.md §DynTool trait definition."
  - "1.8 (FIX-BURST-277-WAVE-B/F-P174-Tool-dyn/2026-07-27): Add `Tool` adjudication to §Adjacent Trait Object-Safety Adjudications. `Tool: Runnable<ToolInput, ToolOutput>` inherits `Runnable`'s `stream()` opaque `impl Stream` return and `pipe()` `impl Runnable` + `where Self: Sized` bound — making `dyn Tool` non-trivially object-safe. However the spec corpus has 4 live `dyn Tool` usage sites (interface-definitions.md §PreToolCallHook ToolCallPreview.tool field; BC-2.05.003 PC2; BC-2.05.004 PC1; BC-2.08.010 PC2). Resolution: option (b) — mint `DynTool` mirroring `DynRunnable<Value, Value>` as the type-erased object-safe seam for heterogeneous tool collections and PreToolCallHook dispatch; all `dyn Tool` sites must be migrated to `dyn DynTool` (Wave C PO routing). `DynTool` definition added to api-surface.md and interface-definitions.md. BC-side migration spec is in the §Adjacent Adjudications note below."
  - "1.7 (FIX-BURST-274/timestamp-convention/2026-07-26): Restore frozen original-acceptance timestamp and date per ADR decision-date convention (Gate #28 Rule 5): `timestamp` → `2026-07-14T12:00:00Z`; `date` → `2026-07-14`. Original decision date evidenced by v1.0 changelog (2026-07-14, initial). Fields were incorrectly set to 2026-07-19 in commit 2100b8e (pass-114 fix burst)."
  - "1.6 (FIX-BURST-270/P1D-168-casing/2026-07-25): PascalCase canon sweep — §MonotonicClock code sketch: Component::CHKPT → Component::Chkpt; Category::INTERNAL → Category::Internal per ADR-010 v1.9 Direction B adjudication."
  - "1.5 (FIX-BURST-267/F-P165-stale-prose/2026-07-25): Strip two stale version pins from §Object-Safety of the 5-Method CheckpointSaver Trait: (1) table receiver cell '`&self` (corrected v1.3)' → '`&self`' — the surrounding table context and changelog already record the v1.3 provenance; (2) condition 3 prose '`&self` added in this revision (v1.3)' → '`&self` added in this revision' — 'in this revision' is the behavioral anchor; the redundant version pin decays if the section is ever moved."
  - "1.4 (burst 119 coordinator sweep, 2026-07-19): Extend §Object-Safety section with Runnable and BaseChatModel adjudications: (1) verification-architecture.md:43 'pure get_next_version(current) successor function' description confirmed accurate — Kani target is MonotonicClock::get_next_version (ZST associated function), not the CheckpointSaver trait method; no edit to verification-architecture.md. (2) Runnable<Input, Output> dyn-compat axis settled: zero dyn Runnable<...> uses in specs/; the separate DynRunnable<Value, Value> type-erased trait (BC-2.01.003/004) is the heterogeneous composition seam; impl Stream return and generic type params in Runnable are non-issues; no interface-definitions.md change required. (3) BaseChatModel same conclusion: zero dyn BaseChatModel uses in specs/; always monomorphic impl BaseChatModel for ChatOpenAI/Anthropic/Ollama; no interface-definitions.md change required. No PO routing for items 2 or 3."
  - "1.3 (F-P116-01, 2026-07-19): dyn-compat fix — add &self receiver to get_next_version provided method on CheckpointSaver trait (was receiver-less, causing E0038 on Arc<dyn CheckpointSaver>). Three-reason rationale: (1) dyn-compatibility requires a receiver on every non-Sized-bounded method; (2) virtual dispatch of backend overrides through the vtable requires &self; (3) langgraph BaseCheckpointSaver.get_next_version is an instance method — the parity claim required correction from 'static method' to 'instance method'. Purity preserved: default body delegates entirely to MonotonicClock::get_next_version (ZST, no self use). Add §Object-Safety of the 5-Method CheckpointSaver Trait subsection with explicit dyn-compatibility conclusion. API Surface Reconciliation rev-2 Signature row updated to include &self."
  - "1.2 (F-P115-02, 2026-07-19): Placement adjudication — add §CheckpointSaver Trait Placement subsection. BC-2.04.003 PC1 says 'A CheckpointSaver implementation provides a get_next_version(current, channel) method'; to satisfy this literally, get_next_version is now also a provided method on the CheckpointSaver trait with a default impl delegating to MonotonicClock::get_next_version. MonotonicClock remains the canonical pure-core algorithm implementation; the trait default is a thin delegation wrapper. Aligns with langgraph BaseCheckpointSaver reference corpus placement."
  - "1.1 (F-P114-01, 2026-07-19): CRIT — replace argument-less MonotonicClock::next_id() AtomicU64 counter with stateless get_next_version(current, channel) per BC-2.04.003 PC1; correct 'Cross-instance ordering: not required' to cross-restart monotonicity guarantee via persisted-max seeding; define seeding scope as per-(thread_id, checkpoint_ns); document E-CHKPT-003 failure path at get_tuple() read; reconcile API surface with BC-2.04.003; add Rationale, Alternatives Considered, Source/Origin sections per adr-template.md."
  - "1.0 (2026-07-14, initial): base ADR accepted; CONFLICT-4 resolution; CheckpointId as u64 newtype; AtomicU64 per-instance counter design (superseded in 1.1)."
---

# ADR-005: Logical Clock and Checkpoint Ordering

**Status:** Accepted rev-4

## Context

CONFLICT-4: adk-rust uses UUID v4 + wall-clock `created_at` for checkpoint IDs.
This creates race conditions in concurrent fork/resume scenarios where two forks
created within the same millisecond have non-deterministic ordering. DI-004 mandates
monotonic logical-clock checkpoint IDs.

BC-2.04.003 Inv1 requires that for any two checkpoints C1 and C2 on the same
`(thread_id, checkpoint_ns)` pair, if C1 was created before C2 then
`C1.checkpoint_id < C2.checkpoint_id` — with no restart exception. BC-2.04.005
specifies crash recovery that resumes the same `thread_id` post-restart and writes
new checkpoints. BC-2.04.006 Inv1 makes `(thread_id, checkpoint_ns, checkpoint_id)`
the composite primary key across ALL storage, including across restarts.

The rev-1 design (AtomicU64 counter starting at 0 on restart) violated these three BCs:
a fresh-restart saver generates IDs starting at 0, colliding with or underrunning the
persisted maximum and producing PK collisions or ordering violations.

## Scope

This ADR covers: `checkpoint_id` generation and ordering in pregolya-checkpoint.
Not covered: `thread_id` (user-supplied string, not clock-derived), `checkpoint_ns` (user-supplied namespace).

## Decision: Stateless Monotonic Logical Clock per (thread_id, checkpoint_ns) Pair

### Design

```rust
/// Monotonic logical clock for checkpoint ordering.
///
/// Stateless: all sequencing state is persisted with the checkpoint.
/// Cross-restart monotonicity is implicit: callers pass the `checkpoint_id`
/// from the most recently loaded `CheckpointTuple` (returned by `get_tuple()`)
/// as `current`, ensuring the next ID is always strictly greater than any
/// previously written ID for the same `(thread_id, checkpoint_ns)` pair.
pub struct MonotonicClock;

impl MonotonicClock {
    /// Returns the next checkpoint ID, strictly greater than `current`.
    ///
    /// # Arguments
    /// - `current`:  `None` for a fresh thread/namespace (no prior checkpoints),
    ///               `Some(c)` for the `checkpoint_id` from the most recently
    ///               loaded `CheckpointTuple` for the `(thread_id, checkpoint_ns)` pair.
    /// - `_channel`: Accepted for API compatibility with BC-2.04.003 PC1; unused for
    ///               ordering. All channels within the same super-step receive the same
    ///               `next_version` value because `current` is identical for all
    ///               channel calls within a single super-step (BC-2.04.003 PC5).
    ///
    /// # Return
    /// - `current = None`    → `Ok(CheckpointId(1))` (first checkpoint for this pair)
    /// - `current = Some(c)` → `Ok(CheckpointId(c.0 + 1))`
    ///
    /// # Errors
    /// - `c.0 == u64::MAX`: `Err(PregolyaError::new(Component::Chkpt, Category::Internal,
    ///   RetryHint::Never, "E-CHKPT-002", "MonotonicClockRegression: checkpoint_id overflow — u64 exhausted"))`.
    ///   Unreachable in practice (requires 2^64 checkpoints per thread/namespace).
    pub fn get_next_version(
        current: Option<CheckpointId>,
        _channel: &ChannelName,
    ) -> Result<CheckpointId, PregolyaError> {
        match current {
            None => Ok(CheckpointId(1)),
            Some(c) => c.0.checked_add(1)
                .map(CheckpointId)
                .ok_or_else(|| PregolyaError::new(
                    Component::Chkpt,
                    Category::Internal,
                    RetryHint::Never,
                    "E-CHKPT-002",
                    "MonotonicClockRegression: checkpoint_id overflow — u64 exhausted",
                )),
        }
    }
}
```

- `CheckpointId` is a newtype over `u64`, not a UUID. Serialized as `u64` in msgpack.
- Wall-clock UUIDs are REJECTED: `CheckpointId::from_uuid()` does not exist.

### Seeding Scope

Seeding is per `(thread_id, checkpoint_ns)` pair:

- **Scope justification:** BC-2.04.003 Inv1 scopes the monotonicity invariant to `(thread_id, checkpoint_ns)` pairs. The `current` parameter is the `checkpoint_id` from the most recently loaded `CheckpointTuple` for that specific pair, not a store-global counter.
- **PK uniqueness:** BC-2.04.006 Inv1 defines the composite PK as `(thread_id, checkpoint_ns, checkpoint_id)`. Two different `(thread_id, checkpoint_ns)` pairs may independently start at `CheckpointId(1)` without violating global uniqueness.
- **Seeding mechanism:** Before calling `get_next_version`, the `CheckpointSaver` implementation loads the latest `CheckpointTuple` for the `(thread_id, checkpoint_ns)` pair via `get_tuple()` and passes its `checkpoint_id` as `current`. For fresh threads (no prior checkpoints), `get_tuple()` returns `Ok(None)` → `current = None` → `CheckpointId(1)`.
- **No constructor-time read required:** Seeding occurs at operation time (when a new super-step begins), not at `CheckpointSaver` construction time. The saver holds no mutable sequence counter.

### Cross-Restart Monotonicity Guarantee

`get_next_version` takes `current` as an explicit parameter derived from persisted storage. This guarantees that after a process restart, the next `CheckpointId` for any `(thread_id, checkpoint_ns)` pair is always strictly greater than all previously written IDs for that pair — without requiring any in-memory counter to survive the restart.

**Corrected guarantee (supersedes rev-1):** Cross-restart monotonicity is preserved for each `(thread_id, checkpoint_ns)` pair. The `current` parameter is the `checkpoint_id` sourced from the persisted `CheckpointTuple` returned by `get_tuple()`, so the generated ID is always strictly greater than the persisted maximum, regardless of how many times the process has restarted.

The rev-1 claim "Cross-instance ordering: not required; each process restart starts a new saver instance" is **retracted**. An in-memory counter that starts at 0 on each restart violates BC-2.04.003 Inv1 (cross-restart monotonicity not excepted) and BC-2.04.006 Inv1 (PK collision after restart). The stateless design with `current` sourced from storage is the correct replacement.

### API Surface Reconciliation

BC-2.04.003 PC1 specifies `get_next_version(current, channel)` as the required method signature. The rev-1 design exposed `next_id(&self)` with no parameters — an in-memory `AtomicU64` counter that started at 0 on each restart. These are incompatible:

| Dimension | rev-1 (retracted) | rev-2 (this ADR) |
|-----------|-------------------|-------------------|
| Signature | `next_id(&self) -> CheckpointId` | `get_next_version(&self, current: Option<CheckpointId>, _channel: &ChannelName) -> Result<CheckpointId, PregolyaError>` |
| State | AtomicU64 counter in instance | Stateless; all state in `current` parameter |
| Seeding | None (starts at 0) | Sourced from persisted `CheckpointTuple` by caller |
| Cross-restart | Resets to 0 (PK collision risk) | Monotonicity preserved via persisted-max seed |

The `channel` parameter matches BC-2.04.003 PC1's `get_next_version(current, channel)` signature. It is accepted but unused for ordering: per BC-2.04.003 PC5, all channels within the same super-step share a single `next_version` value because `current` is identical for all channel calls within a super-step (all derived from the same loaded checkpoint).

### Failure Mode: get_tuple() Read Failure

If `get_tuple()` returns an error carrying code `E-CHKPT-003` (`Category::Durability`) during crash recovery or run resumption:

- Recovery halts immediately per BC-2.04.005 EC-006.
- `get_next_version` is NOT called with an assumed-zero `current`.
- The error propagates to the caller unchanged.

This closes the "silent PK collision" failure mode: the saver never computes a new `CheckpointId` without first successfully loading the persisted state.

### Fork Lineage (BC-2.04.004, unchanged)

```rust
pub struct CheckpointMetadata {
    pub id: CheckpointId,
    pub parent_checkpoint_id: Option<CheckpointId>,
    pub thread_id: ThreadId,
    pub checkpoint_ns: CheckpointNamespace,
    // ... other fields
}
```

Fork creates a new `CheckpointId` (via `get_next_version`) with `parent_checkpoint_id = Some(source_id)`.
State is NOT copied; the parent checkpoint is referenced by pointer only.

### CheckpointSaver Trait Placement (F-P115-02; corrected F-P116-01)

BC-2.04.003 PC1 specifies that the `CheckpointSaver` trait provides `get_next_version` as a provided method with a default implementation delegating to `MonotonicClock::get_next_version`; implementations MAY override. To honor this — and to match the langgraph `BaseCheckpointSaver` reference corpus, which places `get_next_version` as an **instance method** on the saver class — `get_next_version` is exposed as a provided method on the `CheckpointSaver` trait with an `&self` receiver:

```rust
// Provided method on CheckpointSaver trait — callers can override, but the default is correct
fn get_next_version(
    &self,
    current: Option<CheckpointId>,
    channel: &ChannelName,
) -> Result<CheckpointId, PregolyaError> {
    MonotonicClock::get_next_version(current, channel)
}
```

**Receiver rationale (`&self` required, not optional):** Three independent reasons mandate an `&self` receiver:

1. **dyn-compatibility (E0038 avoidance):** A receiver-less associated function on a trait makes the trait NOT dyn-compatible under E0038 unless the method carries a `where Self: Sized` bound. `bounded-contexts.md:64` mandates `Arc<dyn CheckpointSaver>`; `semport/rust-translation-strategy.md:183-184` confirms dyn dispatch at the effectful-shell seam. Without `&self` (and without a `where Self: Sized` bound, which would exclude the method from the vtable entirely), the compiler rejects the trait object construction.

2. **Virtual dispatch of backend overrides:** Static methods are not virtually dispatched through trait objects — the override use case (e.g., a distributed backend using a server-side sequence counter) is only reachable through the vtable when the method carries a receiver. A receiver-less method's override is dead code when called through `Arc<dyn CheckpointSaver>`.

3. **langgraph instance-method parity:** langgraph's `BaseCheckpointSaver.get_next_version(self, current, channel)` is an instance method on the saver class. The prior "static method" parity claim was incorrect; the correct parity is instance-method parity.

**Purity preserved by delegation:** The `&self` receiver does NOT make `get_next_version` impure. The default body delegates entirely to `MonotonicClock::get_next_version(current, channel)`, which is a stateless pure-core function (ZST; ignores `&self` completely). Concrete overrides that DO use instance state (e.g., a distributed sequence counter accessed via `&self`) are effectful shell implementations — the pure-core algorithm lives in `MonotonicClock`.

**`MonotonicClock` status unchanged:** `MonotonicClock::get_next_version` remains the canonical pure-core algorithm implementation in `checkpoint::clock`. Its Pure Core classification in the Purity Boundary Map is unchanged. The trait default is a thin delegation wrapper; the algorithm lives in `MonotonicClock`.

**Why not `MonotonicClock` only?** An associated function on `MonotonicClock` satisfies the implementation contract but does not satisfy the BC-2.04.003 PC1 "provides a method" language, which names the saver as the provider. The reference corpus confirms the saver-level placement. The provided-method pattern achieves both: trait conformance and algorithm encapsulation.

**Override semantics:** Saver implementations MAY override the default if they require backend-specific ordering logic (e.g., a distributed backend that uses a server-side sequence). The default body delegates to `MonotonicClock`.

### Object-Safety of the 5-Method CheckpointSaver Trait

`bounded-contexts.md:64` mandates `Arc<dyn CheckpointSaver>`. The following table states the dyn-compatibility status of each method explicitly so this axis is settled.

| Method | Receiver | Async | Return type | dyn-compatible? |
|--------|----------|-------|-------------|-----------------|
| `put_writes` | `&self` | yes | `Result<(), PregolyaError>` | Yes — with async-trait boxed-future desugaring per pregolya effectful-shell seam strategy |
| `get_tuple` | `&self` | yes | `Result<Option<CheckpointTuple>, PregolyaError>` | Yes — with async-trait boxed-future desugaring |
| `list` | `&self` | yes | `Result<impl Stream<...>, PregolyaError>` | **Residual concern** — `impl Stream` opaque return is NOT dyn-compatible even after async-trait desugaring; must become `Pin<Box<dyn Stream<Item = Result<CheckpointTuple, PregolyaError>> + Send>>` in the trait definition; this change belongs in interface-definitions.md §CheckpointSaver (PO-owned; out of ADR-005 scope) |
| `put` | `&self` | yes | `Result<(), PregolyaError>` | Yes — with async-trait boxed-future desugaring |
| `get_next_version` | `&self` | no | `Result<CheckpointId, PregolyaError>` | Yes — synchronous; concrete return type; `&self` receiver added this revision |

**Conditions for complete dyn-compatibility:**

1. **Async methods** (put_writes, get_tuple, list, put): desugared via the `#[async_trait]` crate attribute or explicit `-> Pin<Box<dyn Future<Output = ...> + Send + '_>>` return types — eliminating the implicit `impl Future` from the vtable. This is the established pregolya effectful-shell seam strategy.
2. **`list` opaque stream:** `impl Stream<...>` replaced with `Pin<Box<dyn Stream<Item = Result<CheckpointTuple, PregolyaError>> + Send>>` in the trait definition. Flagged to interface-definitions.md §CheckpointSaver owner (PO-owned).
3. **`get_next_version` receiver:** `&self` added in this revision. Condition satisfied.

**Conclusion:** With conditions 1 and 2 applied (async-trait desugaring + `list` return type correction in interface-definitions.md) and condition 3 satisfied by this revision, the 5-method `CheckpointSaver` trait is dyn-compatible and `Arc<dyn CheckpointSaver>` compiles without E0038.

### Adjacent Trait Object-Safety Adjudications (burst 119 coordinator sweep)

**`Runnable<Input, Output>` — axis settled, dyn NOT required:**

`Runnable<Input, Output>` is a generic trait with `impl Stream` opaque returns (`stream()`) and an `impl Runnable` opaque return (`pipe()`, bounded by `where Self: Sized`). These characteristics make `dyn Runnable<Input, Output>` non-trivially dyn-compatible. However, the spec corpus contains **zero** instances of `dyn Runnable<...>`. The architecture resolves heterogeneous pipeline composition through a separate `DynRunnable<Value, Value>` type-erased object-safe trait (BC-2.01.003/BC-2.01.004; interface-definitions.md:824 E-CORE-004 note). `Runnable<Input, Output>` is always monomorphized — the `pipe()` combinator and concrete stage types are statically dispatched. The `impl Stream` return in `Runnable::stream()` and the `impl Runnable` return in `pipe()` are therefore **non-issues** for the production architecture. No changes to interface-definitions.md §Runnable are required.

**Authority:** semport/core/rust-translation-strategy.md:345–347 (recommends separate `DynRunnable` as candidate ADR); BC-2.01.003 EC-001 and BC-2.01.004 EC-001 and TV-004 (spec `DynRunnable<Value, Value>` as the type-erased composition path).

**`BaseChatModel` — axis settled, dyn NOT required:**

`BaseChatModel: Runnable<Vec<Message>, AiMessage>` inherits all of `Runnable`'s non-dyn characteristics and adds its own: `stream_chat()` returns `impl Stream`, `bind_tools()` returns `impl BaseChatModel`, and `with_structured_output<T>()` has a generic type parameter. The spec corpus contains **zero** instances of `dyn BaseChatModel` or `Arc<dyn BaseChatModel>`. Provider crates exclusively use static dispatch: `impl BaseChatModel for ChatOpenAI`, `impl BaseChatModel for ChatAnthropic`, `impl BaseChatModel for ChatOllama` (architecture/system-overview.md:72–76, module-decomposition.md:161–165). No changes to interface-definitions.md §BaseChatModel are required.

**`Tool` — axis settled, DynTool required (option b):**

`Tool: Runnable<ToolInput, ToolOutput>` inherits `Runnable`'s `stream()` method (returns `impl Stream`, non-dyn-compatible) and `pipe()` method (`impl Runnable` + `where Self: Sized` bound). These inherited characteristics make `dyn Tool` non-trivially NOT object-safe (dyn-incompatible under E0038); any caller that attempts direct vtable dispatch via `Arc<dyn Tool>` will fail to compile. Corpus re-verification (FIX-BURST-277-WAVE-B errata) found **2 live `Arc<dyn pregolya_core::Tool>` usage sites** in MCP BCs (BC-2.09.001 and BC-2.09.002).

Resolution: **option (b)** — mint `DynTool` as a type-erased object-safe seam mirroring the `DynRunnable<Value, Value>` pattern (BC-2.01.003/BC-2.01.004). `DynTool` exposes `async fn invoke_dyn(&self, input: serde_json::Value) -> Result<serde_json::Value, PregolyaError>` plus the `name()`, `description()`, `schema()`, and `action_risk()` methods from `Tool`. It is a separate, fully object-safe trait; `Arc<dyn DynTool>` compiles without E0038.

```rust
// pregolya-core: core::tool — alongside Tool
/// Object-safe façade for heterogeneous tool dispatch.
/// Mirrors DynRunnable: `Arc<dyn DynTool>` is the concrete composition seam.
#[async_trait]
pub trait DynTool: Send + Sync {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn schema(&self) -> schemars::Schema;
    fn action_risk(&self) -> Option<ActionRisk>;
    async fn invoke_dyn(&self, input: serde_json::Value) -> Result<serde_json::Value, PregolyaError>;
}

/// Blanket impl: any T: Tool + Send + Sync automatically implements DynTool.
impl<T: Tool + Send + Sync + 'static> DynTool for T { ... }
```

**Wave C BC-side migration spec (PO routing — do NOT edit BCs directly):**
The following 3 sites — all non-object-safe (E0038) — MUST change `Arc<dyn pregolya_core::Tool>` (or `Option<Arc<dyn Tool>>`) → `Arc<dyn DynTool>` (or `Option<Arc<dyn DynTool>>`) in a follow-on BC amendment:
1. `BC-2.09.001` — Description (MCP convert_mcp_tool return type) + PC2 (`convert_mcp_tool` return) — `Arc<dyn pregolya_core::Tool>` (non-object-safe, E0038) → `Arc<dyn DynTool>` (MCP discovery output is DynTool for object-safe dispatch)
2. `BC-2.09.002 PC1` — Precondition input type `Arc<dyn pregolya_core::Tool>` (non-object-safe, E0038) produced by `convert_mcp_tool` → `Arc<dyn DynTool>`
3. `BC-2.09.007` — ToolRegistry: `Option<Arc<dyn Tool>>` (non-object-safe, E0038) → `Option<Arc<dyn DynTool>>`

**`MonotonicClock::get_next_version` Kani target — description confirmed accurate:**

`verification-architecture.md:43` describes the Kani verification target as "pure `get_next_version(current)` successor function; stateless, no atomic counter." This refers to `MonotonicClock::get_next_version(current: Option<CheckpointId>, _channel: &ChannelName)` — a receiver-less associated function on the `MonotonicClock` ZST in `checkpoint::clock`. This function is correctly receiver-less (associated function on a zero-size type, not a trait method) and correctly described as pure and stateless. The v1.3 change adding `&self` to the `CheckpointSaver` trait method does not affect the `MonotonicClock` associated function — these are two different functions. No edit to verification-architecture.md is required.

## Rationale

The stateless `get_next_version(current, channel)` design is the only approach that satisfies all three governing BCs simultaneously:

1. **BC-2.04.003 PC1/Inv1:** The method signature `get_next_version(current, channel)` is directly specified by PC1. Inv1 requires monotonicity for each `(thread_id, checkpoint_ns)` pair with no restart exception — an in-memory counter that resets on restart cannot satisfy this invariant.

2. **BC-2.04.006 Inv1:** The composite PK `(thread_id, checkpoint_ns, checkpoint_id)` must be unique across ALL storage, including across restarts and across different saver instances. A counter that resets to 0 generates IDs that collide with pre-restart persisted IDs, violating this invariant.

3. **BC-2.04.005 (crash recovery):** Crash recovery uses the same `thread_id` post-restart. The saver must generate IDs that are strictly greater than the last ID written before the crash for that `(thread_id, checkpoint_ns)` pair. Only a design that reads the persisted max at operation time can guarantee this.

The `current` parameter design achieves all three properties by construction: because `current` is the persisted `checkpoint_id` from `get_tuple()`, the next ID is always `persisted_max + 1`. No operational discipline, initialization sequence, or in-memory state is needed — the invariant is enforced by the function signature itself.

The per-`(thread_id, checkpoint_ns)` seeding scope is chosen over a store-global counter because BC-2.04.003 Inv1 scopes monotonicity to the pair, not to the store. A store-global counter would be unnecessarily strict and would serialize checkpoint ID allocation across unrelated threads.

## Consequences

### Positive

- Cross-restart monotonicity is guaranteed by construction — no in-memory state to manage or lose across restarts.
- The function is pure (no side effects, no mutable state) and directly Kani-verifiable as part of the sync pure-core mandate.
- The API signature matches BC-2.04.003 PC1 exactly, eliminating the prior BC/ADR contract divergence.
- `get_tuple()` failure (E-CHKPT-003) is handled uniformly at the call site before `get_next_version` is invoked — no hidden "start from zero" fallback.

### Negative / Trade-offs

- Callers bear the responsibility of loading the latest `CheckpointTuple` before calling `get_next_version`. The saver implementation must not skip or cache-bypass this load at the start of each super-step.
- Return type is `Result<CheckpointId, PregolyaError>` rather than a plain `CheckpointId` — callers must propagate the overflow error even though it is unreachable in practice. This is the production-grade default (no silent panic for arithmetic).
- `CheckpointId` is `u64`, not `String` or `Uuid`. Downstream systems that expect UUID-format IDs must adapt.

### Status as of rev-4 (2026-07-19)

In-effect per this ADR revision. Implementation of `checkpoint::clock::get_next_version` is
pending Phase 3 (Wave 1, pregolya-checkpoint story). The retired `checkpoint::clock::next_id`
symbol MUST NOT appear in any Phase 3 implementation.

## Alternatives Considered

- **Option A — Constructor-time store-max seed (AtomicU64 initialized at `CheckpointSaver::new()`):** Read the global or per-pair maximum `checkpoint_id` from storage at construction time and initialize an `AtomicU64` at that value. Rejected: (a) requires a store read that can fail with E-CHKPT-003 at construction, complicating the constructor result; (b) in-memory counter diverges from storage if the saver is reused across multiple concurrent pairs; (c) a global max seed is more aggressive than the per-pair scope in BC-2.04.003 Inv1 and can starve ID space unnecessarily.

- **Option B — Per-(thread_id, checkpoint_ns) counter map in CheckpointSaver:** Maintain a `HashMap<(ThreadId, Namespace), AtomicU64>` seeded from the persisted max at first use per pair. Rejected: significantly more complex than the stateless design; the map is mutable shared state requiring synchronization; on restart the map starts empty and must re-seed from storage on first use anyway — equivalent to the stateless design but with extra indirection.

- **Option C — UUID v6 / ULID (time-sortable):** Use ULIDs or UUID v6 which embed a millisecond timestamp and are lexicographically sortable. Rejected: (a) same-millisecond writes within one saver still require a monotonic counter component, reintroducing the seeding problem; (b) adds UUID/ULID dependency; (c) CONFLICT-4 explicitly rejects wall-clock ordering; (d) ULIDs are `String`s — the BC requires `u64` semantics for simple numeric comparison.

- **Option D — Global sequence table in storage:** Add a `sequences` table to the backend (one row per `(thread_id, checkpoint_ns)`); atomically increment via `UPDATE ... RETURNING`. Rejected: backend-specific; SQLite supports this but it requires a separate write per super-step beyond the checkpoint write; adds migration complexity; the BC does not require a separate sequence object — `get_tuple()` already returns the current max as part of the loaded checkpoint.

## Source / Origin

- **BC-2.04.003 PC1** — mandates `get_next_version(current, channel)` API signature; Inv1 mandates monotonicity with no restart exception; PC5 mandates all channels share a single `next_version` per super-step.
- **BC-2.04.006 Inv1** — establishes `(thread_id, checkpoint_ns, checkpoint_id)` as the composite PK across all storage; drives the cross-restart uniqueness requirement.
- **BC-2.04.005 EC-006** — defines E-CHKPT-003 CheckpointReadFailed as the recovery-halt path; drives the failure-mode design.
- **DI-004** (domain invariant) — "Monotonic Checkpoint Clock" — foundational requirement; no wall-clock dependency.
- **CONFLICT-4** (comparative assessment) — adk-rust `Uuid::new_v4()` + `ORDER BY created_at DESC` is the explicit counter-example.
- **F-P114-01** (adversary pass 114, burst 117, 2026-07-19) — CRIT finding that identified the rev-1 AtomicU64 design as violating BC-2.04.003/006 cross-restart monotonicity + triple uniqueness.
