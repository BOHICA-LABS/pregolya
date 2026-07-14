---
document_type: architecture-section
level: L3
section: verification-architecture
version: "1.0"
status: active
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/BC-INDEX.md
input-hash: "2d2537ae23f62153"
traces_to: ARCH-INDEX.md
decisions: [D17]
---

# Verification Architecture: ferrochain

> **VP-INDEX is the source of truth.** Any count or module assignment here must
> match VP-INDEX.md exactly. Arithmetic: VP total = P0 count + P1 count.

## Kani Async Constraint (Verified Kani 0.67.0)

**Kani 0.67.0 has NO native async/.await support.** Harnesses that call `.await`
on a `Future` will fail at verification time. Consequences:

1. **Harnesses must call `block_on` manually** (or restructure to avoid async entirely):
   the pure sync core is extracted and the async wrapper is excluded from the harness.
2. **Sync-core mandate:** The following modules MUST expose a sync (non-async) pure
   core function that is the Kani verification target:
   - `checkpoint::session_index` (VP-002 target) — sync key derivation logic
   - `checkpoint::clock` (monotonic AtomicU64 read) — sync increment and compare
   - `graph::bsp_engine` (VP-001 target) — sync reducer; async orchestration wraps it
3. **ADR-001 Alt-B constraint:** The HYBRID orchestrator-loop is `async` (Tokio runtime).
   This is intentional and correct. The Kani-verifiable invariants live inside the
   synchronous `reduce_super_step()` core that the orchestrator calls. Async orchestration
   wraps sync verifiable cores — the boundary between them is the purity-boundary-map.
4. **Harness pattern for wrapped sync cores:**
   ```rust
   #[kani::proof]
   fn bsp_determinism() {
       // Call the sync reducer directly — no .await, no Tokio, no block_on needed
       let outputs: Vec<(TaskId, ChannelUpdate)> = kani::vec(kani::any::<usize>().min(4));
       assert_eq!(reduce_super_step(&outputs), reduce_super_step(&permute(&outputs)));
   }
   ```

## Committed VP Obligations (D17-Q7)

Three VPs committed before v1.0 release (NFR-003):

| VP | BC Anchor | DI | Module | Tool | Phase | Priority |
|----|-----------|-----|--------|------|-------|---------|
| VP-001 | BC-2.03.001 | DI-001 | ferrochain-graph / bsp-engine | Kani | 6 | P0 |
| VP-002 | BC-2.04.006 | DI-005 | ferrochain-checkpoint / session-index | Kani | 6 | P0 |
| VP-003 | BC-2.13.004 | DI-007 | ferrochain-sandbox / path-guard | Kani | 6 | P0 |
| VP-004 | BC-2.09.004 | DI-014 | ferrochain-mcp / mcp-adapter | integration | 3 | P1 |
| VP-005 | BC-2.09.005 | DI-014 | ferrochain-mcp / mcp-client | integration | 3 | P1 |

**Total: 5 VPs — 3 P0 / 2 P1 | Tool breakdown: Kani ×3, integration ×2**

## Provable Properties Catalog

### P0: Must Prove (CRITICAL / security / durability)

**VP-001 — BSP Super-Step Determinism** (ferrochain-graph / bsp-engine)

Property: For any fixed set of super-step task outputs, the reduced channel state is
identical regardless of the order in which tasks complete.

Formal statement: `∀ task_outputs: Vec<(TaskId, ChannelUpdate)>,
  sort_and_reduce(task_outputs) == sort_and_reduce(permute(task_outputs))`

Kani harness sketch:
```rust
#[kani::proof]
fn bsp_determinism() {
    let n: usize = kani::any();
    kani::assume(n <= 4); // bounded for model checking
    let outputs: Vec<(TaskId, ChannelUpdate)> = kani::vec(n);
    let perm = kani::any_permutation(&outputs);
    assert_eq!(reduce_deterministic(&outputs), reduce_deterministic(&perm));
}
```

Feasibility: HIGH. The reducer is pure; task-identity sort produces a total order.
Bounded by n ≤ 4 to keep state-space finite. Key verification target per NE-17.

---

**VP-002 — Session Triple-Address Uniqueness** (ferrochain-checkpoint / session-index)

Property: No two distinct sessions (thread_id, checkpoint_ns, checkpoint_id) map to the
same storage row. The triple (thread_id, checkpoint_ns, checkpoint_id) is a composite key.

Formal statement: `∀ s1 s2: SessionKey, s1 ≠ s2 → storage_address(s1) ≠ storage_address(s2)`

Kani harness sketch:
```rust
#[kani::proof]
fn session_tenancy_partition() {
    let s1: SessionKey = kani::any();
    let s2: SessionKey = kani::any();
    kani::assume(s1 != s2);
    assert_ne!(storage_address(&s1), storage_address(&s2));
}
```

Feasibility: HIGH. `SessionKey` is a pure struct; `storage_address` is a deterministic
function over its fields. No I/O in the harness.

---

**VP-003 — Workspace Path Confinement** (ferrochain-sandbox / path-guard)

Property: For any symbolic path under a workspace root, `canonicalize_beneath_root`
either returns a path within the root or returns `Err(FerrochainError { code: "E-SBXD-001", .. })`.
It never returns a path outside the root.

Formal statement: `∀ base: Path, path: Path,
  match canonicalize_beneath_root(base, path) {
    Ok(p) => p.starts_with(base),
    Err(FerrochainError { code: "E-SBXD-001", .. }) => true,  // WorkspaceEscape — E-SBXD-001
    _ => false
  }`

Kani harness sketch:
```rust
#[kani::proof]
fn workspace_confinement() {
    let base: PathBuf = kani::any_symbolic_path();
    let path: PathBuf = kani::any_symbolic_path();
    match canonicalize_beneath_root(&base, &path) {
        Ok(p) => assert!(p.starts_with(&base)),
        Err(FerrochainError { code: "E-SBXD-001", .. }) => {},
        _ => assert!(false, "unexpected result"),
    }
}
```

Feasibility: MEDIUM-HIGH. Requires modeling path canonicalization without OS syscalls.
Pure path arithmetic (prefix checks, symlink detection) is tractable for Kani; OS-level
`std::fs::canonicalize` must be replaced with a pure model in the harness.

## Should Prove (P1 — Core Algorithms, Conformance Contracts)

No P1 Kani VPs committed at Phase 1 (the 2 committed P1 VPs — VP-004/VP-005 — are integration-tier, Phase 3). Additional Kani candidates for Phase 6 consideration:
- Monotonic clock: `∀ t1 < t2: Clock, clock_id(t1) < clock_id(t2)` (DI-004)
- Fork lineage: no state copy on fork; pointer only (DI-004)
- BarrierValue: all expected writers present before barrier releases (DI-001)

These are candidates for post-v1 or v1 stretch if Phase 6 capacity allows.

## Test-Sufficient (No Kani)

Modules where behavioral testing is the primary verification method:

| Module | Reason | Tools |
|--------|--------|-------|
| ferrochain-server handlers | I/O-bound; Kani not applicable | Integration, PropTest for request schema |
| Provider crates | Network I/O; testing via DTU fakes | Integration |
| ferrochain-mcp | Transport I/O + Red Gate behavioral tests | Integration, Red Gate |
| ferrochain-splitters | Pure but no formal invariant; golden-vector parity sufficient | Unit, PropTest |
| ferrochain-sandbox backends | OS-level execution; not Kani-tractable | Integration |
| Budget governance (journal) | Append-only ordering; soak tests cover most cases | Unit, Soak |
| Content provenance/guardrail | Hook dispatch coverage is behavioral; not state-machine | Unit, Integration |

## Fuzzing Targets (BC-2.17.002)

| Target | Crate | What is fuzzed | Priority |
|--------|-------|----------------|---------|
| Checkpoint serialization round-trip | ferrochain-checkpoint | msgpack ↔ GraphState round-trip; no data loss | P0 |
| Graph-engine boundary inputs | ferrochain-graph | Malformed GraphConfig; out-of-range node indices | P0 |
| Splitter inputs | ferrochain-splitters | Unicode edge cases; very long strings; null bytes | P1 |

## Risk Mitigations

| Risk | Impact | Architecture Mitigation |
|------|--------|------------------------|
| R10 (NamedBarrierValue missing writer) | HIGH | VP-001 scope includes BarrierValue reducer; Red Gate BC-2.02.003 |
| R8 (code-point parity) | HIGH | Golden-vector parity test in ferrochain-splitters; Red Gate BC-2.07.002 |
| R11 (MCP upstream test voids) | MEDIUM | Red Gate BCs BC-2.09.004 / BC-2.09.005 enforce type-identity behavior |
| NE-17 nondeterminism | HIGH | VP-001 Kani proof eliminates the class of bugs |
| NE-12 session collapse | HIGH | VP-002 Kani proof makes cross-tenant isolation machine-checked |
| NE-02 path traversal | HIGH | VP-003 Kani proof covers all symbolic path inputs |
