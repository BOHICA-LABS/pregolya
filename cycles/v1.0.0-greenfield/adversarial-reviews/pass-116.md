---
document_type: adversarial-review
level: ops
version: "1.0"
status: complete
producer: adversary
timestamp: 2026-07-19T00:00:00Z
phase: 1d
inputs: []
input-hash: "[live-state]"
traces_to: STATE.md
pass: 116
previous_review: pass-115.md
---

# Adversarial Review: ferrochain (Pass 116)

## Finding ID Convention

Finding IDs use the format `F-P<PASS>-<SEQ>` per the ferrochain Phase 1d convention established at pass 1.

## Part A — Fix Verification and Frozen-Corpus Spot-Checks

Pass 115 produced two HIGH findings:
- F-P115-01: `verification-architecture.md` and `purity-boundary-map.md` still described the retracted AtomicU64 design after ADR-005 rev-2 redesign
- F-P115-02: `interface-definitions.md` §CheckpointSaver 3-method trait could not satisfy BC-2.04.006 PC2 / BC-2.04.007 PC1 / BC-2.04.002 PC4 / BC-2.04.001 EC-003; `get_next_version` placement unresolved

Fix burst 118 was dispatched. Verification follows.

### F-P115-01 Verification — CLOSED

**verification-architecture.md v1.4 (checkpoint::clock Kani sync-core mandate row):**

| Check | Result |
|-------|--------|
| Row changed from "monotonic AtomicU64 read — sync increment and compare" to stateless description | VERIFIED — v1.4 row reads "pure `get_next_version(current)` successor function; stateless, no atomic counter" |
| Description no longer implies a mutable counter | VERIFIED — "stateless, no atomic counter" explicitly rules out the retracted AtomicU64 design |
| Description consistent with ADR-005 rev-2 stateless ZST design | VERIFIED — "pure successor function" + "stateless" matches `MonotonicClock::get_next_version` signature (no instance fields) |

**purity-boundary-map.md v1.5 (checkpoint::clock row, Pure Guarantee column):**

| Check | Result |
|-------|--------|
| Pure Guarantee changed from "Monotonic counter increment; UUID wall-clock rejection is pure check" | VERIFIED — v1.5 reads "Pure successor function of caller-supplied `current`; UUID wall-clock rejection is pure check" |
| "counter increment" phrase removed | VERIFIED — "Pure successor function of caller-supplied `current`" carries no stateful-counter semantics |
| Wall-clock rejection clause preserved | VERIFIED — retained unchanged as second clause |

**Ripple sweep (entities-graph / ubiquitous-language / domain-spec):**

The 4-op persistence-operation lists for `CheckpointSaver` in `entities-graph.md` and `ubiquitous-language.md` enumerate `put_writes`, `get_tuple`, `list`, and `put`. `get_next_version` is correctly absent from these lists: it is a utility/clock method, not a persistence operation. This is consistent with the 5-method trait in `interface-definitions` v2.36 (4 persistence operations + 1 provided utility method). No spec file conflates `get_next_version` with the persistence-op enumeration.

**Rev-1 residue check (live spec corpus, excluding semport/ and retraction/changelog rows):**

| Pattern | Result |
|---------|--------|
| `AtomicU64` in live spec (non-changelog, non-semport) | CLEAN — occurrences in ADR-005 §Alternatives Considered / §API Surface Reconciliation comparison table / changelog are audit-trail exempt |
| `next_id` in live spec | CLEAN — only in ADR-005 comparison table §API Surface Reconciliation (retraction audit-trail) |
| `per saver instance` in live spec | CLEAN — only in VP-002 v1.1 changelog row (retraction note; correctly flagged as superseded) |

**F-P115-01 conclusion:** CLOSED. Stateless-clock descriptions in verification-architecture and purity-boundary-map are coherent with ADR-005 rev-2. Zero rev-1 residue in live spec content.

### F-P115-02 Verification — CLOSED on axis A; F-P116-01 raised on axis B

**interface-definitions v2.36 (5-method CheckpointSaver):**

| Check | Result |
|-------|--------|
| `put` method present (5th method) | VERIFIED — `async fn put(&self, config: CheckpointConfig, checkpoint: Checkpoint, metadata: CheckpointMetadata) -> Result<(), FerrochainError>` |
| `put` doc-comment cites BC-2.04.002 PC4/EC-002, BC-2.04.001 EC-003, BC-2.04.006 PC2, BC-2.04.007 PC1+INV-1 | VERIFIED |
| `get_next_version` provided method present (default body delegates to `MonotonicClock::get_next_version`) | VERIFIED — method present; default body correct |
| BC anchor line extended to 001–007 | VERIFIED |
| Gate #31 type note extended with `Checkpoint`, `CheckpointMetadata`, `CheckpointId` | VERIFIED |
| `get_next_version` has `&self` receiver | NOT MET — signature is receiver-less (no `&self` parameter) → F-P116-01 |

**ADR-005 v1.2 §CheckpointSaver Trait Placement:**

| Check | Result |
|-------|--------|
| §CheckpointSaver Trait Placement subsection present | VERIFIED — added in v1.2 |
| Rationale cites BC-2.04.003 PC1 "provides a method" language | VERIFIED |
| langgraph `BaseCheckpointSaver` reference corpus cited | VERIFIED |
| Provided-method pattern with default delegation described | VERIFIED |
| `get_next_version` code block has `&self` receiver | NOT MET — code block shows receiver-less form → F-P116-01 |
| "static because pure" assertion replaced with receiver rationale | NOT MET — rationale in v1.2 asserts receiver-less form is acceptable because purity is preserved → F-P116-01 |

**BC-2.04.003 v1.5 PC1:**

| Check | Result |
|-------|--------|
| PC1 updated to provided-method wording | VERIFIED — "A `CheckpointSaver` implementation provides `get_next_version(current, channel)` as a provided method (default impl delegates to `MonotonicClock::get_next_version`); implementations MAY override" |
| Full typed signature present in PC1 | VERIFIED — `get_next_version(current: Option<CheckpointId>, channel: &ChannelName) -> Result<CheckpointId, FerrochainError>` present |
| Signature includes `&self` receiver | NOT MET — PC1 quotes signature without `&self` → F-P116-01 |

**api-surface.md v1.5 CheckpointSaver row:**

| Check | Result |
|-------|--------|
| BC anchor range extended to 001–007 in both body table and changelog entry | VERIFIED — BC-2.04.001–BC-2.04.007 present in both locations (paper-fix correction from fix burst 118 confirmed) |

**F-P115-02 conclusion:** CLOSED on axis A (missing `put` method and BC-obligation satisfiability). F-P116-01 raised on axis B (receiver-less `get_next_version` breaks E0038 dyn-compatibility).

## Part B — New Findings

### F-P116-01 — HIGH: CheckpointSaver::get_next_version Declared Receiver-Less — E0038 dyn-Compatibility Failure on Arc<dyn CheckpointSaver>, Override Promise Undispatchable, langgraph Instance-Method Parity Misstated

**Severity:** HIGH
**Scope:** `specs/architecture/decisions/ADR-005-logical-clock-checkpoint-ordering.md` §CheckpointSaver Trait Placement (v1.2, at pass-116 time); `specs/prd-supplements/interface-definitions.md` §CheckpointSaver (v2.36, at pass-116 time); `specs/behavioral-contracts/ss-04/BC-2.04.003.md` PC1 (v1.5, at pass-116 time)

#### Evidence Chain (3 independent facts)

**Fact 1 — `bounded-contexts.md:64` mandates `Arc<dyn CheckpointSaver>`:**

`bounded-contexts.md:64` mandates `Arc<dyn CheckpointSaver>` as the injection seam for the `CheckpointSaver` effectful-shell component. `semport/rust-translation-strategy.md:183-184` confirms dyn dispatch at this seam. Any trait method that prevents `dyn CheckpointSaver` from being formed is a compile-time blocker at the bounded-context boundary.

**Fact 2 — ADR-005 v1.2 and interface-definitions v2.36 define `get_next_version` without `&self`:**

At pass-116 time, both ADR-005 v1.2 §CheckpointSaver Trait Placement and `interface-definitions` v2.36 §CheckpointSaver showed:

```rust
fn get_next_version(
    current: Option<CheckpointId>,
    channel: &ChannelName,
) -> Result<CheckpointId, FerrochainError> {
    MonotonicClock::get_next_version(current, channel)
}
```

This is a receiver-less **associated function**, not a method. Under Rust's dyn-compatibility rules (E0038), a trait with a receiver-less associated function that is not bounded by `where Self: Sized` is **not dyn-compatible** — `dyn CheckpointSaver` cannot be formed. The compiler would emit `error[E0038]: the trait CheckpointSaver cannot be made into an object` when attempting to construct `Arc<dyn CheckpointSaver>`.

ADR-005 v1.2 §CheckpointSaver Trait Placement also included a "static because pure" rationale justifying the receiver-less form (asserting that delegation to `MonotonicClock::get_next_version` preserves purity). This assertion is incorrect: the purity of the default body does not exempt the method from vtable requirements. The purity argument addresses implementation semantics, not trait object compatibility.

**Fact 3 — langgraph `BaseCheckpointSaver.get_next_version` is an instance method:**

In the Python langgraph reference corpus (langgraph 1.2.9), `BaseCheckpointSaver.get_next_version` is defined as:

```python
def get_next_version(self, current: Optional[V], channel: ChannelProtocol) -> V:
```

The explicit `self` parameter is the Python instance-method receiver. ADR-005 v1.2 §CheckpointSaver Trait Placement claimed "langgraph instance-method parity" as a rationale for the provided-method pattern, but then showed a receiver-less signature. This is an internal contradiction: the same paragraph claims parity with an instance method while specifying a signature incompatible with instance-method behavior in Rust.

#### Failure Mode Table

| Mode | Trigger | Impact |
|------|---------|--------|
| E0038 compilation failure | Phase 3 story implementer writes `Arc::new(saver)` where `saver: impl CheckpointSaver` or `Box::new(saver) as Box<dyn CheckpointSaver>` | `error[E0038]: the trait CheckpointSaver cannot be made into an object` — receiver-less associated function blocks trait object formation; ferrochain-checkpoint story fails to compile at the bounded-context injection point (bounded-contexts.md:64) |
| Override dead code | A distributed-backend saver overrides `get_next_version` via `impl CheckpointSaver for DistributedSaver { fn get_next_version(current, channel) → ... { server_seq_counter() } }` | Override is unreachable through `Arc<dyn CheckpointSaver>` vtable — associated functions are not virtually dispatched; `MonotonicClock::get_next_version` is always called regardless of the concrete type; BC-2.04.003 PC1 MAY-override semantics are silently violated |
| "Static because pure" misdirection | Implementation team reads ADR-005 v1.2 "static because pure" assertion in §CheckpointSaver Trait Placement | Team scaffolds only the `MonotonicClock` static call path; never sets up the `Arc<dyn CheckpointSaver>` vtable entry for `get_next_version`; override extensibility promised by PC1 is structurally unavailable at the effectful-shell seam |

#### Required Fix (fix burst 119 dispatched)

1. **ADR-005:** Replace §CheckpointSaver Trait Placement `get_next_version` code block with `&self` receiver form; replace "static because pure" assertion with 3-reason receiver rationale (E0038 dyn-compatibility avoidance; virtual dispatch of backend overrides; langgraph instance-method parity). Update §API Surface Reconciliation rev-2 Signature row to include `&self`. Add §Object-Safety of the 5-Method CheckpointSaver Trait with explicit per-method dyn-compatibility status table and conditions. Add §Adjacent Trait Object-Safety Adjudications settling `Runnable<Input, Output>`, `BaseChatModel`, and `MonotonicClock::get_next_version` (separate symbol) axes.
2. **interface-definitions.md §CheckpointSaver:** Add `&self` receiver to `get_next_version` provided method. Change `list` return type from `Result<impl Stream<Item = Result<CheckpointTuple, FerrochainError>>, FerrochainError>` to `Pin<Box<dyn Stream<Item = Result<CheckpointTuple, FerrochainError>> + Send>>` per ADR-005 §Object-Safety `list` residual condition.
3. **BC-2.04.003 PC1:** Update quoted signature from `get_next_version(current: Option<CheckpointId>, channel: &ChannelName)` to `get_next_version(&self, current: Option<CheckpointId>, channel: &ChannelName)`. Update Architecture Anchors cite to include `&self` in the signature reference.

---

## Cleared Candidates

| Axis | Disposition |
|------|-------------|
| F-P115-01 verification-architecture + purity-boundary-map stateless-clock descriptions | CLOSED — both files correctly describe the stateless pure function; no AtomicU64/counter language remaining in live content |
| F-P115-02 missing `put` method and BC-obligation satisfiability (axis A) | CLOSED — all four unsatisfiable BC predicates now satisfiable via `put` method in interface-definitions v2.36 |
| Rev-1 residue (AtomicU64 / next_id / per saver instance) in live spec | CLEAN — no live-spec residue; all occurrences in audit-trail rows (changelog/retraction tables; exempt) |
| `list` return type — `impl Stream` not dyn-compatible (pre-existing axis) | CLEARED-NOT-REPORTED — axis was flagged in ADR-005 v1.2 §CheckpointSaver Trait Placement as a residual PO-owned concern; it is the same dyn-compatibility class as F-P116-01 and is addressed in fix burst 119 PO scope as a paired fix to F-P116-01; reporting as an independent finding at this pass would be duplicative with F-P116-01 |
| VP-002 / BC-2.04.004 behavioral reference consistency | CLEAN — VP-002 "unique across the durable store" framing correct; BC-2.04.004 fork lineage unchanged |

## Summary

| Severity | Count |
|----------|-------|
| CRIT | 0 |
| HIGH | 1 (F-P116-01: `get_next_version` receiver-less → E0038 on `Arc<dyn CheckpointSaver>`; override dead code; langgraph parity contradiction in same section) |
| MED | 0 |
| LOW | 0 |
| OBS | 0 |
| **Total findings** | **1** |

**CLEAN (strict):** no (1 HIGH finding)
**CLEAN (PR-merge):** no (1 HIGH finding)

**Convergence counter:** 0/3 (counter unchanged — pass 116 NOT CLEAN strict; fix burst 119 dispatched; BC-5.39.001 frozen-HEAD streak rule applies)
**Novelty:** HIGH (F-P116-01 identifies that ADR-005 v1.2 §CheckpointSaver Trait Placement introduced a receiver-less associated function in the same fix that added the §placement section — the "static because pure" rationale was internally contradictory with the "instance-method parity" claim in the same paragraph and with the `bounded-contexts.md:64` `Arc<dyn CheckpointSaver>` seam requirement)

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 116 |
| **New findings** | 1 |
| **Cleared axes** | F-P115-01 ripple verification (stateless-clock descriptions CLOSED); F-P115-02 axis A (put-method satisfiability CLOSED); rev-1 residue CLEAN; list pre-existing axis CLEARED-NOT-REPORTED; VP-002/BC-2.04.004 consistency CLEAN |
| **Novelty score** | HIGH |
| **Median severity** | HIGH |
| **Trajectory** | →14→5→7→13→3→3→3→5→2→4→4→1→1→2→1→1→1→4→2→3→1→1→1→2→7→5→6→1→6→1→1→4→2→3→0→3→2→1→2→1→0→1→1→0→2→1→2→1→1→1→0→0→1→0→1→1→1→3→2→3→2→1→1→2→1→3→1→0→1→2→0→8→2→1→1→0→1→4→2→1→1→2→3→1→4→2→2→4→4→1→4→2→5→3→4→1→5→1→1→3→2→2→2→1→1→1→1→4→2→2→1→2→0→1→2→1 |
| **CLEAN (strict)** | no |
| **CLEAN (PR-merge)** | no |
| **Verdict** | FINDINGS_REMAIN (1 HIGH; counter 0/3 unchanged; fix burst 119 dispatched; NEXT: pass 117 on new HEAD after fix burst 119) |
