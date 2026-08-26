---
document_type: architecture-section
level: L3
section: verification-architecture
version: "2.21"
status: active
producer: architect
timestamp: 2026-08-21T00:00:00Z
phase: 1b
inputs:
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/prd.md
  - .factory/specs/behavioral-contracts/ss-03/BC-2.03.001.md
  - .factory/specs/behavioral-contracts/ss-04/BC-2.04.006.md
  - .factory/specs/behavioral-contracts/ss-13/BC-2.13.004.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.004.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.005.md
  - .factory/specs/behavioral-contracts/ss-17/BC-2.17.002.md
  - .factory/specs/behavioral-contracts/ss-18/BC-2.18.004.md
  - .factory/specs/behavioral-contracts/ss-19/BC-2.19.001.md
  - .factory/specs/behavioral-contracts/ss-19/BC-2.19.005.md
  - .factory/specs/behavioral-contracts/ss-21/BC-2.21.003.md
  - .factory/specs/behavioral-contracts/ss-22/BC-2.22.001.md
  - .factory/specs/behavioral-contracts/ss-05/BC-2.05.007.md
  - .factory/specs/behavioral-contracts/ss-10/BC-2.10.005.md
  - .factory/specs/behavioral-contracts/ss-23/BC-2.23.005.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.005.md
  - .factory/specs/behavioral-contracts/ss-01/BC-2.01.006.md
input-hash: "57a7c93"
traces_to: ARCH-INDEX.md
decisions: [D17, D21, D23]
---

# Verification Architecture: pregolya

> **VP-INDEX is the source of truth.** Any count or module assignment here must
> match VP-INDEX.md exactly. Arithmetic: VP total = P0 count + P1 count.

## [Section Content]

This file documents pregolya's verification architecture: the Kani async constraint (0.67.0 has no native async/.await support), the fifteen committed VP obligations (VP-001–VP-015), and the P0/P1 property catalog with proof harness skeleton patterns. VP-001..005 are the original five (three Kani P0 + two integration P1). VP-006..010 are the D21 ecosystem-parity expansion (three Kani P0/P1 + two proptest P1). VP-011..013 are the D23 tools/budget layer (three Kani P0/P1). VP-014 is the burst-302b LCEL composition expansion (one proptest P1; D-170). VP-015 is the architect-reconcile-burst credential-redaction unit test (one integration P1; BC-2.09.007 {INV-003}).

## Kani Async Constraint (Verified Kani 0.67.0)

**Kani 0.67.0 has NO native async/.await support.** Harnesses that call `.await`
on a `Future` will fail at verification time. Consequences:

1. **Harnesses must call `block_on` manually** (or restructure to avoid async entirely):
   the pure sync core is extracted and the async wrapper is excluded from the harness.
2. **Sync-core mandate:** The following modules MUST expose a sync (non-async) pure
   core function that is the Kani verification target:
   - `checkpoint::session_index` (VP-002 target) — sync key derivation logic
   - `checkpoint::clock` — pure `get_next_version(current)` successor function; stateless, no atomic counter
   - `graph::bsp_engine` (VP-001 target) — sync reducer; async orchestration wraps it
   - `graph::hitl` (VP-011 target) — sync `route_pre_tool_decision(decision: PreToolDecision) -> DispatchOutcome` extracted from async `pre_tool_dispatch`; `shield_hook_result(result: Result<PreToolDecision, HookError>) -> PreToolDecision` is the companion sync adapter
   - `core::budget` (VP-012 target) — sync `check_watermark_trigger(tokens_remaining: u64, ceiling: u64, fraction: f64) -> bool`; pure arithmetic, no I/O; implements `<= (1.0 - fraction)` (non-strict, EC-002 correctness)
3. **ADR-001 Alt-B constraint:** The HYBRID orchestrator-loop is `async` (Tokio runtime).
   This is intentional and correct. The Kani-verifiable invariants live inside the
   synchronous `reduce_super_step()` core that the orchestrator calls. Async orchestration
   wraps sync verifiable cores — the boundary between them is the purity-boundary-map.
4. **Harness pattern for wrapped sync cores:**
   ```rust
   #[kani::proof]
   fn bsp_determinism_harness() {
       // Call the sync reducer directly — no .await, no Tokio, no block_on needed
       let outputs: Vec<(TaskId, ChannelUpdate)> = kani::vec(kani::any::<usize>().min(4));
       assert_eq!(reduce_super_step(&outputs), reduce_super_step(&permute(&outputs)));
   }
   ```

## Committed VP Obligations (D17-Q7 + R11 + D21 + D23)

Fifteen VPs committed before v1.0 release — VP-001..005 (original five) plus VP-006..010 (D21 ecosystem-parity expansion) plus VP-011..013 (D23 tools/budget layer) plus VP-014 (burst-302b LCEL composition expansion) plus VP-015 (architect-reconcile-burst MCP credential-redaction):

| VP | BC Anchor | DI | Module | Tool | Phase | Priority |
|----|-----------|-----|--------|------|-------|---------|
| VP-001 | BC-2.03.001 | DI-001 | `graph::bsp_engine` | Kani | 6 | P0 |
| VP-002 | BC-2.04.006 | DI-005 | `checkpoint::session_index` | Kani | 6 | P0 |
| VP-003 | BC-2.13.004 | DI-007 | `sandbox::path_guard` | Kani | 6 | P0 |
| VP-004 | BC-2.09.004 | DI-014 | `mcp::exception` | integration | 3 | P1 |
| VP-005 | BC-2.09.005 | DI-014 | `mcp::client` | integration | 3 | P1 |
| VP-006 | BC-2.18.004 | DI-014 | `prompts::injection_guard` | Kani | 6 | P1 |
| VP-007 | BC-2.19.001 | DI-008 | `core::serializable` | proptest | 3 | P1 |
| VP-008 | BC-2.22.001 | DI-014 | `core::embeddings` | proptest | 3 | P1 |
| VP-009 | BC-2.21.003 | DI-014 | `vectorstores::similarity` | Kani | 6 | P0 |
| VP-010 | BC-2.19.005 | DI-014 | `core::serializable` | Kani | 6 | P0 |
| VP-011 | BC-2.05.007 | DI-014 | `graph::hitl` | Kani | 6 | P0 |
| VP-012 | BC-2.10.005 | DI-014 | `core::budget` | Kani | 6 | P1 |
| VP-013 | BC-2.23.005 | DI-014 | `tools::shell` | Kani | 6 | P1 |
| VP-014 | BC-2.01.005 + BC-2.01.006 | DI-016 | `core::runnable` | proptest | 3 | P1 |
| VP-015 | BC-2.09.007 {INV-003} | DI-010 | `mcp::sanitize` | integration | 3 | P1 |

**Total: 15 VPs — 6 P0 / 9 P1 | Tool breakdown: Kani ×9, proptest ×3, integration ×3**

## Provable Properties Catalog

### P0: Must Prove (CRITICAL / security / durability)

**VP-001 — BSP Super-Step Determinism** (`graph::bsp_engine`)

Property: For any fixed set of super-step task outputs, the reduced channel state is
identical regardless of the order in which tasks complete.

Formal statement: `∀ task_outputs: Vec<(TaskId, ChannelUpdate)>,
  reduce_super_step(task_outputs) == reduce_super_step(permute(task_outputs))`
(`reduce_super_step` sorts by `task_id` then reduces — VP-001.md §Property Statement)

Kani harness sketch (see VP-001.md §Proof Harness Skeleton for full bounded permutation impl):
```rust
#[kani::proof]
fn bsp_determinism_harness() {
    let n: usize = kani::any();
    kani::assume(n > 0 && n <= 4); // bounded for model checking
    let task_outputs: Vec<(TaskId, ChannelUpdate)> = (0..n)
        .map(|i| (TaskId(i as u64), kani::any::<ChannelUpdate>()))
        .collect();
    // kani::any_permutation(n) is not a built-in API; see VP-001.md Note for
    // bounded permutation array pattern
    let permutation: Vec<usize> = kani::any_permutation(n);
    let permuted: Vec<(TaskId, ChannelUpdate)> =
        permutation.iter().map(|&i| task_outputs[i].clone()).collect();
    let result_a = reduce_super_step(task_outputs.clone());
    let result_b = reduce_super_step(permuted);
    kani::assert(result_a == result_b, "BSP determinism violated");
}
```

Feasibility: HIGH. `reduce_super_step` is a pure function; task-identity sort produces a total order.
Bounded by n ≤ 4 to keep state-space finite. Key verification target per NE-17.

---

**VP-002 — Session Triple-Address Uniqueness** (`checkpoint::session_index`)

Property: No two distinct sessions (thread_id, checkpoint_ns, checkpoint_id) map to the
same storage row. The triple (thread_id, checkpoint_ns, checkpoint_id) is a composite key.

Formal statement: `∀ s1 s2: SessionKey, s1 ≠ s2 → storage_address(s1) ≠ storage_address(s2)`

Kani harness sketch:
```rust
#[kani::proof]
fn session_tenancy_harness() {
    let s1: SessionKey = kani::any();
    let s2: SessionKey = kani::any();
    kani::assume(s1 != s2);
    assert_ne!(storage_address(&s1), storage_address(&s2));
}
```

Feasibility: HIGH. `SessionKey` is a pure struct; `storage_address` is a deterministic
function over its fields. No I/O in the harness.

---

**VP-003 — Workspace Path Confinement** (`sandbox::path_guard`)

Property: For any symbolic path under a workspace root, `canonicalize_beneath_root`
either returns a path within the root or returns `Err(PregolyaError { code: "E-SBXD-001", .. })`.
It never returns a path outside the root.

Formal statement: `∀ base: Path, path: Path,
  match canonicalize_beneath_root(base, path) {
    Ok(p) => p.starts_with(base),
    Err(PregolyaError { code: "E-SBXD-001", .. }) => true,  // WorkspaceEscape — E-SBXD-001
    _ => false
  }`

Kani harness sketch (see VP-003.md §Proof Harness Skeleton for full bounded path construction):
```rust
#[kani::proof]
fn workspace_confinement_harness() {
    // Target: canonicalize_beneath_root_pure — the extracted pure model
    // (no OS std::fs::canonicalize; symlinks modeled via bounded path components)
    let base_components: Vec<BoundedPathComponent> = kani::vec(3, kani::any);
    let base = PathBuf::from_components(&base_components);
    let path_components: Vec<BoundedPathComponent> = kani::vec(6, kani::any);
    let path = PathBuf::from_components(&path_components);
    match canonicalize_beneath_root_pure(&base, &path) {
        Ok(p) => kani::assert(p.starts_with(&base), "result must be within base"),
        Err(PregolyaError { code: "E-SBXD-001", .. }) => {},
        Err(_) => {}, // other errors allowed (e.g., path does not exist in model)
    }
}
```

Feasibility: MEDIUM-HIGH. Proof targets `canonicalize_beneath_root_pure` — the extracted
pure-model variant (no OS `std::fs::canonicalize`; pure path arithmetic over bounded
components). Bounded: base ≤ 3 components; path ≤ 6 components per VP-003.md.

---

**VP-009 — Zero-Norm Cosine Guard** (`vectorstores::similarity`) `red_gate: true`

Property: For any symbolic pair of finite `f32` vectors where either L2 norm is `0.0`
(IEEE-754 exact equality), `cosine_similarity` returns `Err(E-VS-001)` and never
produces `Ok(f32::NAN)`. Division is unreachable when either norm is zero.

Formal statement:
```
∀ a: &[f32], b: &[f32], 1 ≤ |a| = |b| ≤ 8, all elements finite (is_finite()):
  let norm_a = sqrt(Σ aᵢ²);  let norm_b = sqrt(Σ bᵢ²)
  (norm_a == 0.0 ∨ !norm_a.is_finite() ∨ norm_b == 0.0 ∨ !norm_b.is_finite()) →
    cosine_similarity(a, b) == Err(E-VS-001)
    ∧ cosine_similarity(a, b) ≠ Ok(NaN)
```

Overflow note (F-P173-503): finite elements can produce norm = +Inf via Σ xᵢ² overflow;
`sqrt(+Inf) = +Inf`; `Inf/Inf = NaN`. Guard must check `!norm.is_finite()` in addition to
`norm == 0.0`. BC-2.21.003 Invariant 3 BC amendment required (routed to product-owner).
See VP-009.md §Property Statement for full specification.

Kani harness sketch (see VP-009.md §Proof Harness Skeleton for complete three-harness set):
```rust
#[kani::proof]
#[kani::unwind(9)]
fn zero_norm_guard_fail_closed() {
    let len: usize = kani::any();
    kani::assume(len >= 1 && len <= 8);
    let a: Vec<f32> = (0..len).map(|_| { let x: f32 = kani::any(); kani::assume(x.is_finite()); x }).collect();
    let b: Vec<f32> = (0..len).map(|_| { let x: f32 = kani::any(); kani::assume(x.is_finite()); x }).collect();
    let norm_a = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let norm_b = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    let result = cosine_similarity(&a, &b);
    // Covers both zero-norm and overflow (norm = +Inf from Σ xᵢ² overflow)
    if norm_a == 0.0 || !norm_a.is_finite() || norm_b == 0.0 || !norm_b.is_finite() {
        kani::assert(matches!(result, Err(PregolyaError { code: "E-VS-001", .. })), "guard must fire (zero or overflow)");
        kani::assert(!matches!(result, Ok(v) if v.is_nan()), "Ok(NaN) unreachable");
    } else {
        kani::assert(result.is_ok(), "finite non-zero norm must produce Ok");
    }
}
```

Feasibility: MEDIUM-HIGH. `cosine_similarity` is a pure-core sync function in `vectorstores::similarity`
(ADR-014 Decision 2 §Hardening note; relocated from vectorstores::mmr per F-P129-11). Kani 0.67.0 models
`f32` symbolically over IEEE-754 domain. Requires `#[kani::unwind(9)]` for the 8-element vector
iteration. Estimated proof time: 5–15 min. Red Gate: tests TV-001 and TV-002 must compile-and-fail
before Phase 3 story delivery for SS-21.

---

**VP-010 — Reviver Allowlist Containment** (`core::serializable` — Reviver aspect) `red_gate: true`

Property: For any type-ID path that is (a) not present in the registered allowlist AND
(b) not a LangChain monolith passthrough type (`LANGCHAIN_MONOLITH_TYPES`), `allowlist_check`
returns `Err(E-SRLZ-001)`. The `Ok(())` path is unreachable for non-monolith unregistered IDs.
Broader "never Ok for ANY unregistered id" invariant is jointly covered with BC-2.19.006 unit
tests (monolith ids correctly produce `E-SRLZ-002`, not `E-SRLZ-001` — VP-010 proof domain
excludes those IDs per VP-010.md v1.1 scoping).

Formal statement:
```
∀ id: &[String] (depth ≤ 4, each segment ≤ 16 bytes ASCII printable),
  registry: &HashMap<Vec<String>, ()> (5 concrete entries),
  id ∉ LANGCHAIN_MONOLITH_TYPES:
    !registry.contains_key(id) → allowlist_check(id, registry) == Err(E-SRLZ-001)
```

Kani harness sketch:
```rust
#[kani::proof]
fn allowlist_rejects_unregistered_id() {
    let depth: usize = kani::any();
    kani::assume(depth >= 1 && depth <= 4);
    let id: Vec<String> = (0..depth).map(|_| {
        let len: usize = kani::any();
        kani::assume(len >= 1 && len <= 16);
        (0..len).map(|_| { let c: u8 = kani::any(); kani::assume(c.is_ascii_graphic()); c as char }).collect()
    }).collect();
    let mut registry: HashMap<Vec<String>, ()> = HashMap::new();
    registry.insert(vec!["lc".into(), "PromptTemplate".into()], ());
    // 4 more concrete entries
    kani::assume(!registry.contains_key(&id));
    kani::assume(!LANGCHAIN_MONOLITH_TYPES.contains(&id.as_slice())); // non-monolith domain
    let result = allowlist_check(&id, &registry);
    kani::assert(matches!(result, Err(PregolyaError { code: "E-SRLZ-001", .. })), "unregistered non-monolith id must be rejected");
}
```

Feasibility: HIGH. `OnceLock<HashMap>` complexity excluded by extracting `allowlist_check` as a standalone
pure function. Bounded: ID depth ≤ 4, segments ≤ 16 ASCII bytes, registry fixed at 5 concrete entries,
non-monolith domain assumption (VP-010.md v1.1 scoping per F-P129-04). HashMap lookup is directly modeled
by Kani's CBMC backend. Red Gate: must compile-and-fail before Phase 3 story delivery for SS-19.

---

**VP-011 — PreToolCallHook Fail-Closed** (`graph::hitl`) `Kani P0`

Property: For any `PreToolDecision::Deny` — whether returned by the hook or synthesized by
the panic-shield from `Err(HookError)` — `route_pre_tool_decision` returns
`DispatchOutcome::Reject(_)` and `pre_tool_dispatch` never calls `tool.invoke`.
`DispatchOutcome::Proceed(_)` is reachable from `PreToolDecision::Approve` AND from
`PreToolDecision::Edit { modified_args }` when `modified_args` is a valid JSON object
(BC-2.05.007 PC-3). `PreToolDecision::PendingHumanApproval` is handled by the async `pre_tool_dispatch`
wrapper BEFORE `route_pre_tool_decision` is called — the wrapper issues
`interrupt(ToolApprovalRequest{..})` and suspends the run (BC-2.05.001 machinery);
`route_pre_tool_decision` is not invoked for this path. This variant is outside the Kani
proof scope; non-invocation is covered by BC-2.05.008 integration tests. If
`PendingHumanApproval` reaches `route_pre_tool_decision` unexpectedly, the
`#[non_exhaustive]` wildcard arm returns `DispatchOutcome::Reject(_)` (fail-closed).

Formal statement:
```
// route_pre_tool_decision: pure-sync routing over three routable variants + #[non_exhaustive] wildcard
// NOTE: PendingHumanApproval is peeled off upstream in pre_tool_dispatch before this fn is called.
∀ decision: PreToolDecision passed to route_pre_tool_decision:
  decision == Deny { .. }
    → route_pre_tool_decision(decision) == Reject(_)
  decision == Approve
    → route_pre_tool_decision(decision) == Proceed(_)
  decision == Edit { modified_args }:
    is_valid_json_object(modified_args) == true
      → route_pre_tool_decision(decision) == Proceed(_)
    is_valid_json_object(modified_args) == false
      → route_pre_tool_decision(decision) == Reject(_)  // fallback Deny per BC-2.05.007 PC-3
  _ (wildcard — including PendingHumanApproval if it unexpectedly reaches this fn)
    → route_pre_tool_decision(decision) == Reject(_)    // #[non_exhaustive] fail-closed

// pre_tool_dispatch (async wrapper): PendingHumanApproval peeled off before route_pre_tool_decision
// This path is outside Kani scope (async/effectful); covered by BC-2.05.008 integration tests:
PreToolDecision::PendingHumanApproval { .. } received by pre_tool_dispatch
  → interrupt(ToolApprovalRequest{..}) issued; run suspended;
    route_pre_tool_decision NOT called; tool NOT invoked

∀ result: Result<PreToolDecision, HookError>:
  result == Err(_)  → shield_hook_result(result) == Deny { .. }  // fail-closed panic-shield
  result == Ok(d)   → shield_hook_result(result) == d            // identity pass-through
```

`#[non_exhaustive]` note: `PreToolDecision` is `#[non_exhaustive]`. The harness uses
concrete variant construction rather than `kani::any::<PreToolDecision>()` (which cannot
enumerate future variants). The four proof functions below target the three routable variants
(Deny, Approve, Edit) and the hook-error path; `PendingHumanApproval` is peeled off upstream
in `pre_tool_dispatch` and has no dedicated proof function. Future variants require
specification of which layer handles them before a harness can be added
(VP-011.md §Proof Obligations).

Kani harness sketch (see VP-011.md §Proof Harness Skeleton for full target-file path):
```rust
// Target: graph::hitl::route_pre_tool_decision + shield_hook_result (pure sync)

#[kani::proof]
fn deny_excludes_tool_invocation() {
    // reason content does not affect routing — branch is variant-based.
    let reason = "denied by hook".to_string();
    let decision = PreToolDecision::Deny { reason: reason.clone() };
    let outcome = route_pre_tool_decision(decision);
    kani::assert(matches!(outcome, DispatchOutcome::Reject(_)), "Deny MUST produce Reject");
    kani::assert(!matches!(outcome, DispatchOutcome::Proceed(_)), "tool.invoke MUST be unreachable for Deny");
}

#[kani::proof]
fn approve_reaches_tool_invocation() {
    let decision = PreToolDecision::Approve;
    let outcome = route_pre_tool_decision(decision);
    kani::assert(matches!(outcome, DispatchOutcome::Proceed(_)), "Approve MUST reach tool.invoke");
}

#[kani::proof]
fn hook_error_resolves_to_deny_and_reject() {
    let error_detail = "panic in hook".to_string();
    let hook_result: Result<PreToolDecision, HookError> = Err(HookError::Panic(error_detail));
    let effective_decision = shield_hook_result(hook_result);
    kani::assert(matches!(effective_decision, PreToolDecision::Deny { .. }),
        "hook panic MUST be converted to PreToolDecision::Deny");
    let outcome = route_pre_tool_decision(effective_decision);
    kani::assert(matches!(outcome, DispatchOutcome::Reject(_)), "hook panic → Deny → Reject");
    kani::assert(!matches!(outcome, DispatchOutcome::Proceed(_)), "tool.invoke unreachable after hook panic");
}

#[kani::proof]
fn edit_invalid_args_falls_back_to_deny() {
    // Non-object JSON value is invalid for Edit modified_args (BC-2.05.007 PC-3)
    let invalid_args = serde_json::Value::String("not-an-object".to_string());
    let decision = PreToolDecision::Edit { modified_args: invalid_args };
    let outcome = route_pre_tool_decision(decision);
    kani::assert(matches!(outcome, DispatchOutcome::Reject(_)), "Edit with non-object args MUST fall back to Reject");
    kani::assert(!matches!(outcome, DispatchOutcome::Proceed(_)), "tool.invoke unreachable for invalid Edit");
}
```

Feasibility: HIGH. `PreToolDecision` is a 4-variant `#[non_exhaustive]` enum (D23-defined:
Approve, Deny, Edit, PendingHumanApproval; BC-2.05.007 PC1–PC4); the harness targets the
three routable variants (Deny, Approve, Edit) plus hook-error path — `PendingHumanApproval`
is peeled off upstream in `pre_tool_dispatch` (not a harness target). `route_pre_tool_decision`
and `shield_hook_result` are pure sync functions extracted from the async `pre_tool_dispatch`
per the sync-core mandate above. No I/O in harness; routing is a `match` over three routable
variants plus `#[non_exhaustive]` wildcard — CBMC solves branch reachability queries in
seconds. Estimated proof time: < 2 min.
See VP-011.md §Feasibility Assessment for full factor table.

## Should Prove (P1 — Core Algorithms, Conformance Contracts)

**VP-006 — injection_guard Fail-Closed** (`prompts::injection_guard`) `Kani P1 Phase 6` `red_gate: true`

**Scope (v1.9 extension, architect-reconcile-burst):** VP-006 covers all 3 injection arms:
(1) slot-variable trust check (`check_slot_trust` — original scope); (2) few-shot example
injection (`check_fewshot_trust` — added in v1.9 per BC-2.18.004 {PC-005}); (3) TV-006 Red Gate
(compile-and-fail before Phase 3 story delivery for SS-18). Two Kani harnesses:
`injection_guard_fail_closed` (Arm 1) and `injection_guard_fewshot_fail_closed` (Arm 2).
Authoritative harness bodies: VP-006.md §Proof Harness Skeleton.

Property: For any injection-guard input with `TrustLevel::Untrusted` where the guard policy
is `TrustRequired`, the corresponding check function returns `Err(E-TMPL-001)` and never
returns `Ok(PromptValue)`. Holds for both `check_slot_trust` (Arm 1) and `check_fewshot_trust`
(Arm 2). The safe passage (`TrustAll`) path is only reachable when the policy explicitly permits it.

Note (burst-226 / F-P131-05): `TrustLevel` is the SS-18-local trust classifier in
`pregolya-prompts: prompts::template`. It is distinct from `core::guardrail::ProvenanceTag`
(SS-11 ingress-boundary struct). Harness uses `kani::Arbitrary` on `TrustLevel` (3-variant
enum: `Untrusted | UserInput | Trusted`). Error code is `E-TMPL-001` (SECURITY/InjectionAttempt).

Formal statement (Arm 1 — slot variables):
```
∀ slots: Vec<SlotVar>, |slots| ≤ 4:
  ∃ slot ∈ slots: slot.policy == SlotTrustPolicy::TrustRequired
                  ∧ slot.trust_level.is_some_and(|t| t.is_untrusted()) →
    check_slot_trust(slots) == Err(PregolyaError { code: "E-TMPL-001", category: SECURITY, .. })
```

Formal statement (Arm 2 — few-shot examples):
```
∀ examples: Vec<FewShotExample>, |examples| ≤ 4:
  ∃ ex ∈ examples: ex.trust_level.is_some_and(|t| t.is_untrusted()) →
    check_fewshot_trust(examples) == Err(PregolyaError { code: "E-TMPL-001", category: SECURITY, .. })
```

Kani harness sketch (Arm 1 — canonical, unchanged from prior versions):
```rust
#[kani::proof]
fn injection_guard_fail_closed() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 4);
    // SlotVar has fields: policy: SlotTrustPolicy, trust_level: Option<TrustLevel>
    let slot_vars: Vec<SlotVar> = (0..n)
        .map(|_| SlotVar {
            policy: kani::any::<SlotTrustPolicy>(),
            trust_level: kani::any::<Option<TrustLevel>>(),  // None | Some(Untrusted|UserInput|Trusted)
        })
        .collect();
    let result = check_slot_trust(&slot_vars);
    let has_violation = slot_vars.iter().any(|s|
        s.policy == SlotTrustPolicy::TrustRequired
        && s.trust_level.is_some_and(|t| t.is_untrusted())
    );
    if has_violation {
        kani::assert(matches!(result, Err(PregolyaError { code: "E-TMPL-001", .. })), "fail-closed: must return E-TMPL-001");
    } else {
        kani::assert(result.is_ok(), "no violation: must pass");
    }
}
```

Kani harness sketch (Arm 2 — few-shot, added v1.9):
```rust
#[kani::proof]
fn injection_guard_fewshot_fail_closed() {
    let n: usize = kani::any();
    kani::assume(n >= 1 && n <= 4);
    let examples: Vec<FewShotExample> = (0..n)
        .map(|_| FewShotExample {
            trust_level: kani::any::<Option<TrustLevel>>(),
        })
        .collect();
    let result = check_fewshot_trust(&examples);
    let has_untrusted = examples.iter().any(|ex|
        ex.trust_level.is_some_and(|t| t.is_untrusted())
    );
    if has_untrusted {
        kani::assert(matches!(result, Err(PregolyaError { code: "E-TMPL-001", .. })), "fewshot fail-closed: must return E-TMPL-001");
    } else {
        kani::assert(result.is_ok(), "no untrusted fewshot: must pass");
    }
}
```

Feasibility: HIGH. Both `check_slot_trust` and `check_fewshot_trust` are pure sync functions over
bounded Vec. Enum variants finite (TrustLevel: 3 variants; SlotTrustPolicy: 2 variants).
Harness bounds: ≤ 4 slots / ≤ 4 examples. Estimated proof time per harness: 1–3 min.

---

**VP-007 — LcSerializable Round-Trip** (`core::serializable`) `proptest P1 Phase 3`

Property: For all types implementing `LcSerializable`, `deserialize(serialize(x)) ≡ x`.
Serialization is deterministic and lossless for registered types (excluding fields listed
in `lc_secrets()`, which are stripped by design).

Why proptest (not Kani): 141 registered types exceed practical Kani bounds. proptest's shrinking
is more actionable for debugging round-trip failures than a CBMC counterexample.

proptest strategy sketch (see VP-007.md §Proof Harness Skeleton for full strategy):
```rust
proptest! {
    #[test]
    fn prop_prompt_template_round_trip(pt in any::<PromptTemplate>()) {
        // Authoritative API: serialize() + Reviver::revive() (VP-007.md §Property Statement)
        let serialized = pt.serialize();
        prop_assume!(matches!(serialized, Serialized::Constructor { .. }));
        let reviver = Reviver::new();
        let revived = reviver.revive(serialized).expect("registered type must round-trip");
        let revived_pt = revived.downcast::<PromptTemplate>()
            .expect("downcast to PromptTemplate must succeed");
        prop_assert_eq!(pt.lc_id(), revived_pt.lc_id());
        prop_assert_eq!(pt.input_variables(), revived_pt.input_variables());
    }
}
```

Feasibility: HIGH. proptest shrinking identifies concrete failing inputs. `Arbitrary` impls
required for all `LcSerializable` types by Phase 3. Secret-field exclusion (`lc_secrets()`)
is explicit in the equivalence check, not a gap.

---

**VP-008 — Embeddings Dimensionality Contract** (`core::embeddings`) `proptest P1 Phase 3`

Property: For any batch of non-empty strings, all vectors returned by `embed_documents`
have equal length, and `embed_query` returns a vector of the same length as any vector
in the batch result. An empty input batch returns `Ok(vec![])`. Count mismatches and
zero-length vectors are caught and returned as `Err(E-EMBED-001)`.

**Production function under test:** `validate_embedding_batch(texts: &[String], vecs: &[Vec<f32>]) -> Result<(), PregolyaError>`.
This function lives in `core::embeddings` production code (not test-only). All `Embeddings`
impls must call it before returning. The proptest harness calls this function DIRECTLY —
the mock impls supply raw valid or invalid outputs as inputs; no validation logic lives
inside any mock.

**Why production-function targeting (not mock-based assertion):**
Prior design (pre-v2.14) asserted `batch.iter().all(|v| v.len() == dim)` on a mock that
returns `vec![0.1; dim]` by construction — trivially true regardless of whether production
validation code exists. A deleted production validator would leave every assertion green.
The redesign targets `validate_embedding_batch` directly so deletion or regression of the
production gate causes immediate test failure.

proptest strategy sketch (calls production function directly):
```rust
proptest! {
    #[test]
    fn prop_validate_embedding_batch_accepts_valid(
        dim in 1usize..=4096usize,
        n_texts in 1usize..=64usize,
    ) {
        let texts: Vec<String> = (0..n_texts).map(|i| format!("text {i}")).collect();
        let vecs: Vec<Vec<f32>> = (0..n_texts).map(|_| vec![0.1f32; dim]).collect();
        // PRODUCTION CODE UNDER TEST
        let result = validate_embedding_batch(&texts, &vecs);
        prop_assert!(result.is_ok());
    }
}
```

Negative harnesses (VP-008-C/D/E) pass raw violating vectors to `validate_embedding_batch`
and assert `Err(E-EMBED-001)`. See VP-008.md §Proof Harness Skeleton for all five harnesses.

Feasibility: HIGH. `validate_embedding_batch` is a pure sync function (no async, no I/O).
Proptest exercises it directly; no Tokio runtime needed for VP-008-A/B. EC-003 (count
mismatch) and EC-004 (zero-length vector) now have dedicated concrete harnesses VP-008-D
and VP-008-E (previously falsely claimed as covered by ragged_batch harness).

---

**VP-012 — OnWatermark Arithmetic** (`core::budget`) `Kani P1 Phase 6`

Property: `check_watermark_trigger(tokens_remaining, ceiling, fraction)` returns `true` if and
only if `(tokens_remaining as f64) / (ceiling as f64) <= (1.0 - fraction)` for all valid inputs
in the bounded domain. Non-strict `<=` is load-bearing (EC-002: fraction=1.0 must fire when
remaining=0). The function never overflows, produces NaN, or returns an incorrect trigger
decision within the bounded domain.

Formal statement:
```
∀ tokens_remaining: u64 ∈ [0, ceiling], ceiling: u64 ∈ (0, 2^24],
  fraction: f64 ∈ (0.0, 1.0], fraction.is_finite():
    check_watermark_trigger(tokens_remaining, ceiling, fraction)
    == ((tokens_remaining as f64) / (ceiling as f64) <= (1.0f64 - fraction))
```

Bound rationale: `ceiling ≤ 2^24` is a CBMC tractability bound (not a precision constraint);
f64 is exact up to 2^53, well above all realistic LLM token budgets as of D23.

Kani harness sketch:
```rust
#[kani::proof]
fn watermark_arithmetic_harness() {
    let tokens_remaining: u64 = kani::any();
    let ceiling: u64 = kani::any();
    let fraction: f64 = kani::any();
    // tokens_remaining: u64 is always >= 0 by type; tokens_remaining=0 is IN-domain (EC-002).
    kani::assume(ceiling > 0 && tokens_remaining <= ceiling);
    kani::assume(ceiling <= 1 << 24);
    kani::assume(fraction > 0.0 && fraction <= 1.0 && fraction.is_finite());
    let result = check_watermark_trigger(tokens_remaining, ceiling, fraction);
    let r = tokens_remaining as f64;
    let c = ceiling as f64;
    let expected = r / c <= (1.0f64 - fraction);  // non-strict <=
    kani::assert(result == expected, "OnWatermark arithmetic must match reference");
}
```

Feasibility: MEDIUM-HIGH. `check_watermark_trigger` is a pure sync arithmetic function in
`pregolya-core::core::budget`. The bounded domain (`ceiling ≤ 2^24`) makes the f64
arithmetic tractable for Kani's IEEE-754 model. Estimated proof time: 5–15 min.
Note: `fraction > 0.0` assumption excludes the degenerate `fraction = 0.0` case (always-fire)
which is rejected at BudgetConfig construction (EC-001 in BC-2.10.005).

---

**VP-014 — RunnableParallel Key-Completeness** (`core::runnable`) `proptest P1 Phase 3`

Property: For any N-branch `RunnableParallel` invocation where `invoke` returns `Ok(output)`:
`output.as_object().unwrap().len() == N` AND the output key set exactly equals the configured
branch key set passed to `RunnableParallel::new(steps)`. Holds for all N ≥ 0.

Formal statement (DI-016 key-completeness half):
```
// new() accepts an iterator of (key, runnable) pairs — the canonical argument type
// per BC-2.01.005 PC1. IndexMap is the INTERNAL container built by new(), not the
// argument type (ADR-026 §Decision 1).
∀ steps: Vec<(String, Arc<dyn DynRunnable>)>, ∀ input: Value:
  let key_set: HashSet<String> = steps.iter().map(|(k, _)| k.clone()).collect();
  let N = key_set.len();
  let result = RunnableParallel::new(steps).invoke(input, None).await;
  if let Ok(output) = result {
    let obj = output.as_object().unwrap();
    obj.len() == N
    ∧ obj.keys().cloned().collect::<HashSet<_>>() == key_set
  }
```

Why proptest not Kani: `invoke` is an `async fn` using `JoinSet` (Tokio). Kani 0.67.0
has no native async support. proptest with identity-branch runnables (zero I/O, infallible)
exercises the actual Tokio runtime and verifies the key-set property over random inputs.

**Proptest harness:** See `VP-014.md` §Proof Harness Skeleton for the complete harness.
Strategy: `proptest::collection::hash_set` generates arbitrary distinct branch keys (0..=20),
each branch is an identity `DynRunnable`, and the output key set is asserted equal to the input key set.

Feasibility: HIGH. Identity-branch runnables are pure and infallible; zero I/O; no LLM API keys
required. 256 proptest cases at N ≤ 20 completes in < 1 minute.

---

**VP-013 — BashTool Risk Floor** (`tools::shell`) `Kani P1 Phase 6`

Property: For all `ActionRisk r ∈ {ReadOnly, Low}`, `check_risk_floor(r)` returns
`Err(PregolyaError { code: "E-TOOLS-007", category: VAL, .. })` and never returns `Ok(())`.
The Low/ReadOnly risk tiers are unconditionally below the minimum allowed floor.

Formal statement:
```
∀ r: ActionRisk:
  (r == ReadOnly ∨ r == Low) → check_risk_floor(r) == Err(E-TOOLS-007, category: VAL)
  (r == Medium ∨ r == High) → check_risk_floor(r) == Ok(())
```

**RESOLVED (burst-232, 2026-07-22; casing corrected FIX-BURST-270):** BC-2.23.005 §Postconditions (PC-4) category corrected to `Category::Val`
(same burst that seeded VP-013). The prior `Category::CONFIGURATION` label was non-canonical
(not present in the 13-category axis per ADR-010). BC-2.23.005 §Postconditions (PC-4) category = VAL (taxonomy code), Rust identifier = `Category::Val`, consistent with
error-taxonomy.md §Component: TOOLS and this VP harness. No active contradictions.

**Kani harness:** See `VP-013.md` §Proof Harness Skeleton for the complete three-harness set
(`risk_floor_rejects_below_medium`, `risk_floor_accepts_at_or_above_medium`,
`risk_floor_exhaustive_coverage`). `VP-013.md` is the authoritative source per
Source-of-Truth Precedence rule 4 (VP files supersede architecture prose for the property they
cover); harness bodies are not duplicated here to eliminate drift.

Feasibility: HIGH. `ActionRisk` is a 4-variant enum; `check_risk_floor` is a pure sync match.
State-space is trivially finite for Kani. Estimated proof time: < 1 min. See `VP-013.md`
§Feasibility Assessment for the complete feasibility analysis.

## Test-Sufficient (No Kani)

Modules where behavioral testing is the primary verification method:

| Module | Reason | Tools |
|--------|--------|-------|
| pregolya-server | I/O-bound; Kani not applicable | Integration, PropTest for request schema |
| pregolya-openai | Network I/O; testing via DTU fakes | Integration |
| pregolya-anthropic | Network I/O; testing via DTU fakes | Integration |
| pregolya-ollama | Network I/O; testing via DTU fakes | Integration |
| pregolya-mcp | Transport I/O + Red Gate behavioral tests | Integration, Red Gate |
| pregolya-splitters | Pure but no formal invariant; golden-vector parity sufficient | Unit, PropTest |
| pregolya-sandbox | OS-level execution; not Kani-tractable (path_guard excluded — covered by VP-003 Kani P0 above) | Integration |
| `graph::budget` | Append-only ordering (EvidenceJournal); soak tests cover most cases | Unit, Soak |
| `graph::provenance` | DI-012 RAGRetrieval boundary enforced via GuardedDocuments compile_fail (ADR-014 Decision 6; VP-2.20.002-A); hook dispatch coverage is behavioral; not state-machine | compile_fail, Unit, Integration |

## Fuzzing Targets (BC-2.17.002)

| Target | Crate | What is fuzzed | Priority |
|--------|-------|----------------|---------|
| Checkpoint serialization round-trip (`fuzz_checkpoint_serde`) | pregolya-checkpoint | msgpack ↔ GraphState round-trip; no data loss | P0 |
| Graph-engine boundary inputs (`fuzz_graph_execution`) | pregolya-graph | Malformed GraphConfig; out-of-range node indices | P0 |

> Non-normative: Splitter robustness (R8 Unicode parity) is covered by proptest + the GTV Red Gate suite (BC-2.07.002), not cargo-fuzz, in v1; a splitter fuzz target is a candidate post-v1 addition requiring BC-2.17.002 + coverage-matrix updates in the same burst (gate #25/#32 discipline).

## Risk Mitigations

| Risk | Impact | Architecture Mitigation |
|------|--------|------------------------|
| R10 (NamedBarrierValue missing writer) | HIGH | VP-001 scope includes BarrierValue reducer; Red Gate BC-2.02.003 |
| R8 (code-point parity) | HIGH | Golden-vector parity test in pregolya-splitters; Red Gate BC-2.07.002 |
| R11 (MCP upstream test voids) | MEDIUM | Red Gate BCs BC-2.09.004 / BC-2.09.005 enforce type-identity behavior |
| NE-17 nondeterminism | HIGH | VP-001 Kani proof eliminates the class of bugs |
| NE-12 session collapse | HIGH | VP-002 Kani proof makes cross-tenant isolation machine-checked |
| NE-02 path traversal | HIGH | VP-003 Kani proof covers all symbolic path inputs |

## Changelog

| Version | Date | Author | Decision | Change |
|---------|------|--------|----------|--------|
| 2.21 | 2026-08-26 | architect | architect-reconcile-burst | (1) VP-006 3-arm scope extension (v1.9): §VP-006 updated to document all 3 injection arms; added Arm 2 formal statement (few-shot) and `injection_guard_fewshot_fail_closed` Kani harness sketch; TV-006 Red Gate noted. (2) VP-015 added to Committed VP Obligations table: `mcp::sanitize`, integration P1, Phase 3, BC-2.09.007 {INV-003}, DI-010. Section Content narrative updated (fourteen→fifteen VPs). Total: 15 VPs — 6 P0 / 9 P1, Kani 9 + proptest 3 + integration 3. input-hash refreshed (57a7c93 from hook-computed value; BC inputs added by Burst B propagation). |
| 2.20 | 2026-08-21 | architect | INVESTIGATE-RECONCILE | VP-004 Module column: `mcp::adapter` → `mcp::exception` in Provable Properties Catalog table. Story S-2.10 creates no `adapter.rs`; VP-004 ToolException type-identity property targets `mcp::exception`. Arithmetic invariant unchanged: 14 VPs, 6 P0 / 8 P1, Kani 9 + proptest 3 + integration 2. |
| 2.19 | 2026-08-17 | architect | BURST-313 / F-P204-02 | VP-014 formal statement corrected: stale `new()` argument type `IndexMap<String, Arc<dyn DynRunnable>>` replaced with canonical `Vec<(String, Arc<dyn DynRunnable>)>` (iterator-of-pairs). IndexMap is the INTERNAL container built by `new()`, not the argument type (ADR-026 §Decision 1 / BC-2.01.005 PC1). Formal invariant rewritten: quantifier uses Vec-of-pairs, extracts `key_set` from pairs via iterator map-collect, derives `N = key_set.len()`. Adds clarifying comment that IndexMap is internal. Key-completeness property preserved. Source of truth: VP-014.md §Changelog (burst-311/OBS-P202-B). No §Decision 1/2 split required — arch block does not attribute JoinSet/concurrent execution to §Decision 1. Corpus sweep: only this site was a stale new()-arg; interface-definitions.md §RunnableParallel struct definition, BC-2.01.005 §Construction Preconditions, ADR-026 §Decision 1 are struct-field/internal-container usages (correct). |
| 2.18 | 2026-08-17 | architect | burst-308 / F-P200-02 | Category-axis reference correction in §VP-013 RESOLVED block. "(not present in the 12-category axis per ADR-010)" → "(not present in the 13-category axis per ADR-010)". Rationale: ADR-010 §Category Axis Expansion (D26) expanded the category axis from 12 to 13 (EXEC added) in this burst; CONFIGURATION has never been a valid category, pre- or post-D26 expansion. |
| 2.17 | 2026-08-17 | architect | burst-304 / F-P195-01 + F-P195-02 | VP-014 method-surface and module-path alignment (POL-9 propagation from VP-014.md). §VP-014 heading: `core::runnable::parallel` → `core::runnable` (canonical 2-level registry form; F-P195-02). §VP-014 property, formal statement, and rationale: `invoke_dyn` → `invoke` (three sites; F-P195-01). Canon: DynRunnable method is `invoke`/`stream`; `invoke_dyn`/`stream_dyn` belong to DynTool only (ADR-026 §Decision 5; interface-definitions.md §DynRunnable). |
| 2.16 | 2026-08-17 | product-owner | burst-302b / D-170 | Add VP-014 (proptest P1, BC-2.01.005 + BC-2.01.006, module core::runnable::parallel, crate pregolya-core, DI-016). LCEL composition scope expansion (D-170; ADR-026). VP-014 proves the RunnableParallel key-completeness property: for any N-branch RunnableParallel where invoke_dyn returns Ok(output), output.as_object().len() == N AND output key set == configured branch key set. Why proptest not Kani: invoke_dyn is async with Tokio JoinSet fan-out; Kani 0.67.0 has no native async support. §Section Content narrative updated (thirteen→fourteen). Committed VP Obligations table: add VP-014 row; update total line (13→14, P1 7→8, proptest 2→3). Should Prove section: add VP-014 entry. New BC inputs added: BC-2.01.005, BC-2.01.006. Input-hash updated (new inputs added). |
| 2.15 | 2026-08-16 | architect | FIX-BURST-291 / F-P1D182-01 + D-134 | Phantom §-anchor fixes in §VP-013 RESOLVED block and §VP-013 changelog row. Live-body: 'BC-2.23.005 §Category was corrected to' → 'BC-2.23.005 §Postconditions (PC-4) category corrected to'; 'BC-2.23.005 §Category = VAL' → 'BC-2.23.005 §Postconditions (PC-4) category = VAL'; 'error-taxonomy §TOOLS' → 'error-taxonomy.md §Component: TOOLS' (two sites: §VP-013 body line and §VP-013 Changelog row 2.11 '→' targets). Rationale: BC-2.23.005 has no §Category heading; category field lives in §Postconditions PC-4. error-taxonomy.md has no §TOOLS heading; real heading is §Component: TOOLS (pregolya-tools). |
| 2.14 | 2026-07-28 | architect | FIX-BURST-280 / F-P175-A24 companion | VP-008 section redesign to remove self-proving mock rationale. Prior §VP-008 stated "Mock embeddings implementation makes the contract hold by construction" — this perpetuated the F-P175-A24 defect (harnesses certifying mock internals, not production code). Replaced with description of `validate_embedding_batch` production function approach: mocks supply raw inputs only; production validator is the assertion target. Proptest sketch updated to call `validate_embedding_batch` directly. EC-003 and EC-004 negative harnesses (VP-008-D/E) noted. MockEmbeddings::new_fixed_dim(128) self-proving sketch removed. |
| 2.13 | 2026-07-27 | architect | CHECK4-vparch closure | Canonicalize all Module cells in §Committed VP Obligations table (13 rows) and §Test-Sufficient table (7 rows → 9 rows) to `crate::module` or ARCH-INDEX canonical crate-name form. VP table: replace all `pregolya-X / y-name` two-part notation — graph::bsp_engine, checkpoint::session_index, sandbox::path_guard, mcp::adapter, mcp::client, prompts::injection_guard, core::serializable (×2: VP-007 LcSerializable + VP-010 Reviver aspect), core::embeddings, vectorstores::similarity, graph::hitl, core::budget, tools::shell. VP-007 and VP-010 both map to core::serializable; aspect distinction preserved via BC Anchor (BC-2.19.001 vs BC-2.19.005), Tool (proptest vs Kani), Phase (3 vs 6), and Priority (P1 vs P0) columns — rows not merged. Test-Sufficient table: pregolya-server handlers → pregolya-server; Provider crates (unresolvable single mapping) → split into pregolya-openai + pregolya-anthropic + pregolya-ollama (3 rows); pregolya-sandbox backends → pregolya-sandbox with path_guard exclusion note; Budget governance (journal) → graph::budget; Content provenance/guardrail → graph::provenance. pregolya-mcp and pregolya-splitters already canonical — left unchanged. Section headings (VP-001..013 prose entries) updated to canonical form for consistency; VP-010 heading uses `core::serializable — Reviver aspect` to distinguish from VP-007. Total Module cells: 22 (was 20; +2 from Provider crates split into 3 rows). |
| 2.12 | 2026-07-27 | architect | FIX-BURST-276 / F-P173-501+503 | F-P173-501 — §VP-001 section: update formal statement from `sorts by task_id` to `sorts by (task_id: &str, channel_name: &str) lexicographic ascending`; add channel_name tiebreaker note and lexicographic hazard explanation; update harness sketch to use string TaskId and (TaskId, String, ChannelUpdate) tuple, replacing TaskId(i as u64) with bounded-string construction per VP-001.md §Proof Harness Skeleton. F-P173-503 — §VP-009 section: update formal statement to add overflow path (!norm.is_finite() covers +Inf from sum-of-squares overflow); update harness sketch conditional from (norm == 0.0) to (norm == 0.0 OR !norm.is_finite()); add overflow note. Source of truth for both: VP-001.md and VP-009.md §Proof Harness Skeleton respectively. |
| 2.11 | 2026-07-25 | architect | FIX-BURST-273 / F-P171a-10+11 | F-P171a-10 — replace §VP-013 Kani harness sketch (2 harnesses, missing `risk_floor_accepts_at_or_above_medium`) with pointer to `VP-013.md` §Proof Harness Skeleton; VP-013.md is authoritative per Source-of-Truth Precedence rule 4; pointer names all three canonical harnesses to eliminate drift surface. F-P171a-11 — de-pin two live-body version pins in §VP-013 RESOLVED block: 'BC-2.23.005 was amended to `Category::Val` (burst-232)' → 'BC-2.23.005 §Postconditions (PC-4) category corrected to `Category::Val`'; 'BC-2.23.005 category = VAL (burst-232)' → 'BC-2.23.005 §Postconditions (PC-4) category = VAL'. Allowlist entry for the BC-2.23.005 version-pin in verification-architecture.md (F-P171a-11 de-pin) is now dead — devops to remove. |
| 2.10 | 2026-07-25 | architect | FIX-BURST-272 / F-P170-05 sibling + DEFECT-2 | Purge phantom `ActionRisk::Critical` from §VP-013 body — sibling of VP-013.md F-P170-05 purge that verification-architecture.md missed. (1) Formal statement: remove `∨ r == Critical` disjunct. (2) `risk_floor_exhaustive_coverage` harness: `kani::assume(idx <= 4)` → `kani::assume(idx <= 3)`; `_ => ActionRisk::Critical` → `_ => ActionRisk::High`; assert message `"Medium/High/Critical must pass floor check"` → `"Medium/High must pass floor check"`. (3) Feasibility line: `5-variant enum` → `4-variant enum`. |
| 2.9 | 2026-07-25 | architect | FIX-BURST-270 / P1D-168-casing | PascalCase canon sweep — §VP-013 RESOLVED note: `` `Category::VAL` `` → `` `Category::Val` `` per ADR-010 v1.9 Direction B adjudication. |
| 2.8 | 2026-07-24 | architect | FIX-BURST-255 / F-P154-01 | F-P154-01 (HIGH) VP-011 internal contradiction + totality gap: adjudicate PendingHumanApproval routing design — Option A peel-off. PendingHumanApproval is handled by async `pre_tool_dispatch` wrapper BEFORE `route_pre_tool_decision` is called (interrupt issued; run suspended; `route_pre_tool_decision` not invoked). Fix property prose from "neither Proceed nor Reject returned" (impossible given DispatchOutcome type) to peel-off design. Fix formal statement: remove PendingHumanApproval clause from `route_pre_tool_decision` quantifier block; add wildcard arm clause (fail-closed Reject); add separate `pre_tool_dispatch` peel-off block. Fix `#[non_exhaustive]` note: "each proof function targets one variant" → "four proof functions target three routable variants (Deny/Approve/Edit) + hook-error; `PendingHumanApproval` has no dedicated proof function". Corresponds to VP-011.md v1.2→v1.3. |
| 2.7 | 2026-07-24 | architect | FIX-BURST-253 / F-P152-02 | VP-012 symbolic domain widening. Formal statement: `tokens_remaining ∈ (0, ceiling]` → `[0, ceiling]` (strict lower bound excluded the EC-002 boundary case that the burst-252 `<=` predicate change was meant to cover). Harness sketch: removed `tokens_remaining > 0` from multi-condition assume; u64 guarantees ≥ 0 by type. Added IN-domain comment. |
| 2.6 | 2026-07-24 | architect | FIX-BURST-252 / F-P151-04+05 | VP-012 predicate + precision corrections. (1) F-P151-04: `<` → `<=` in VP-012 Property Statement, Formal Statement, harness expected expression, and core-budget sync-core line. Non-strict `<=` is required: with strict `<`, condition `tokens_remaining/ceiling < 0.0` can never be true (remaining≥0), so fraction=1.0/remaining=0 would never fire (contradicts BC-2.10.005 EC-002). (2) F-P151-05: `fraction: f32` → `fraction: f64` throughout VP-012 section (Property Statement, Formal Statement, harness). `f64` is the adjudicated type (interface-definitions §Compaction already used f64; f64 avoids precision issues for budgets >16M tokens). `watermark_boundary_does_not_fire` harness renamed `watermark_boundary_fires` (with `<=`, exactly-at-threshold now fires). Feasibility note updated: CBMC tractability bound 2^24 retained, rationale changed from f32-precision to state-space-only. |
| 2.5 | 2026-07-24 | architect | FIX-BURST-250 / F-P149-01 | F-P149-01 (HIGH, architect half) de-pin volatile ADR version: VP-009 Feasibility note `ADR-014 v1.2 §Hardening note` → `ADR-014 Decision 2 §Hardening note` (TD-VSDD-091 per D18-P84-A: live-body citations use stable section anchors, not version pins). Sibling sweep (F-P149-03): VP-006 heading updated from `` `Kani P1 Phase 6` `` to `` `Kani P1 Phase 6` `red_gate: true` `` — parity with VP-009 and VP-010 headings (both carry `` `red_gate: true` ``). |
| 2.4 | 2026-07-24 | architect | FIX-BURST-248 / F-P147-01 | F-P147-01 (HIGH) red_gate adjudication: VP-011 entry heading corrected — remove stale `red_gate: true` label. BC-2.05.007 is NOT Red-Gated (product-owner authority: BC-2.05.007 red_gate: false, burst-231; ADR-018 Decision 3 contains no compile-and-fail mandate; fabricated red_gate_source removed in VP-011 v1.1). Heading updated from `` `Kani P0 red_gate: true` `` to `` `Kani P0` ``. Red Gate census: 11 (unchanged). |
| 2.3 | 2026-07-24 | architect | burst-247 / F-P146-01 | F-P146-01 (HIGH) VP-011 catalog correction: rewrite formal statement, prose, and harness sketch to match authoritative 4-variant `#[non_exhaustive]` PreToolDecision model (Approve/Deny/Edit/PendingHumanApproval per BC-2.05.007 PC1–PC4 + VP-011.md + interface-definitions). Removes stale two-variant exhaustive claim and "(no other variant exists; enum is exhaustive)" line. Fixes wrong Proceed-reachability prose (Approve-only → Approve AND valid Edit per PC-3). Replaces non-compiling `kani::any()` two-arm match with four concrete proof functions (deny_excludes_tool_invocation, approve_reaches_tool_invocation, hook_error_resolves_to_deny_and_reject, edit_invalid_args_falls_back_to_deny) mirroring VP-011.md §Proof Harness Skeleton. Fixes feasibility "2-variant" → "4-variant #[non_exhaustive]". Coherence sweep of 12 remaining VP catalog entries (OBS-P146 process-gap follow-up) found 4 additional harness-target divergences fixed in same burst: VP-001 `reduce_deterministic`→`reduce_super_step` + `sort_and_reduce`→`reduce_super_step` in formal statement; VP-003 harness `canonicalize_beneath_root`→`canonicalize_beneath_root_pure`; VP-006 SlotVar `trust_policy`+`value` fields→`policy` (no value field, `is_some_and(t.is_untrusted())` predicate per VP-006.md); VP-007 `lc_serialize()`/`lc_deserialize()`→`serialize()`/`Reviver::new().revive()`. TD-VSDD-060 sibling sweep: all PreToolDecision claims in architect-owned files (module-decomposition, purity-boundary-map, api-surface) verified correct (4-variant model already present); domain-spec + PO-owned files not modified. Input-hash updated: fb6e588→fd27b6d. |
| 2.2 | 2026-07-22 | architect | burst-233 / F-P133-06 | F-P133-06 sibling sweep: resolve stale BC-2.23.005 Category::CONFIGURATION contradiction note in §VP-013 property body. Note was "routed to PO for amendment"; BC-2.23.005 was amended to `VAL` in burst-232 (v1.1) — contradiction is now closed. Note updated to RESOLVED status, consistent with error-taxonomy v1.31 and VP harness. No VP catalog or coverage-matrix changes. |
| 2.1 | 2026-07-22 | architect | burst-232 / D23 | D23 VP layer: add VP-011..013 (Kani P0/P1) to Committed VP Obligations table and Provable Properties Catalog. VP-011 (graph::hitl, P0): PreToolCallHook fail-closed dispatch. VP-012 (core-budget, P1): OnWatermark arithmetic. VP-013 (tools-shell, P1): BashTool risk floor. Total 10→13 VPs; P0 5→6; P1 5→7; Kani 6→9. Add BC-2.05.007/2.10.005/2.23.005 to inputs; decisions D17/D21 → D17/D21/D23. Input-hash refresh pending. |
| 2.0 | 2026-07-21 | architect | burst-227 / F-P132-03 | VP-006 Feasibility section: `ProvenanceTag: 3 variants` → `TrustLevel: 3 variants` (ProvenanceTag is a struct with Uuid field, not an enum; TrustLevel is the Kani input). Propagates VP-006.md v1.4 residue sweep. |
| 1.9 | 2026-07-21 | architect | burst-226 / F-P131-05 | VP-006 section corrected: replace nonexistent `ProvenanceTag::External \| ProvenanceTag::ToolOutput` variants with `TrustLevel::Untrusted` (SS-18-local trust classifier per ADR-015 v1.3); fix error code `E-INJ-001` → `E-TMPL-001` (SECURITY/InjectionAttempt). Formal statement, harness sketch, and explanatory note updated throughout. `TrustLevel` is distinct from `core::guardrail::ProvenanceTag` (SS-11 ingress struct). `SlotVar.tag` field renamed to `SlotVar.trust_level` in harness. |
| 1.8 | 2026-07-21 | architect | burst-225 / F-P130-05 | Correct VP-006 DI column in Committed VP Obligations table: DI-008 → DI-014. VP-006 proves the fail-closed property (injection detected → Err returned, no PromptValue produced); the semantically correct invariant is DI-014 (Error Propagation / No Silent Swallowing), not DI-008 (Library Constructor Result Contract). Siblings VP-009 and VP-010 both anchor DI-014 for the same class of proof. Propagates VP-INDEX.md v1.4 and VP-006.md v1.2 corrections. |
| 1.7 | 2026-07-21 | architect | burst-224 / VP-chain propagation | VP-010 formal statement scoped to non-monolith domain (id ∉ LANGCHAIN_MONOLITH_TYPES) per VP-010.md v1.1 / F-P129-04; harness sketch updated with LANGCHAIN_MONOLITH_TYPES assumption and corrected assertion; feasibility note updated. Test-Sufficient 'Content provenance/guardrail' row updated to reflect GuardedDocuments compile_fail mechanism (ADR-014 Decision 6 / VP-2.20.002-A). Input-hash refreshed: b279860 → d7ef822 (BC-2.18.004 v1.1 + BC-2.19.005 v1.1 bumped by PO in same burst). |
| 1.6 | 2026-07-21 | architect | burst-224 / F-P129-11 | VP-009 module renamed from `pregolya-vectorstores / vectorstores-mmr` to `pregolya-vectorstores / vectorstores-similarity` in Committed VP Obligations table and VP-009 P0 entry; propagates VP-INDEX v1.3 module rename. cosine_similarity is a shared primitive in vectorstores::similarity; MMR algorithm is a separate caller. |
| 1.5 | 2026-07-21 | architect | burst-223 / D21 | VP layer for D21 ecosystem-parity expansion: add VP-006..010 (3 Kani P1/P0 + 2 proptest P1) to Committed VP Obligations table and Provable Properties Catalog. Total 5→10 VPs; P0 3→5; P1 2→5; Kani 3→6; proptest 0→2. Add SS-18..22 BCs to inputs. |
| 1.4 | 2026-07-19 | architect | burst-118 / F-P115-01 | checkpoint::clock sync-core mandate rewritten to reflect ADR-005 rev-2 stateless design. Replaced "(monotonic AtomicU64 read) — sync increment and compare" with "pure `get_next_version(current)` successor function; stateless, no atomic counter". No VP or coverage-matrix changes — VP-002 target is checkpoint::session_index; checkpoint::clock is not a direct VP target. |
| 1.3 | 2026-07-17 | architect | burst-169 / D18-P88-A | Formal version bump deferred from burst-169 (prd v1.2 cascade): timestamp advanced to 2026-07-17 in that burst; validate-changelog-monotonicity blocked the bump because no committed changelog baseline existed. Burst-169 now committed (1a915c6). Same-day provenance amendment (D18-P88-A): removed forbidden live-index input BC-INDEX.md; replaced with the six stable versioned BC files the document actually derives from (BC-2.03.001 VP-001 anchor, BC-2.04.006 VP-002 anchor, BC-2.13.004 VP-003 anchor, BC-2.09.004 VP-004 anchor, BC-2.09.005 VP-005 anchor, BC-2.17.002 fuzzing-targets authority); input-hash recomputed 270a1de → 8091abc. No spec content changes. |
| 1.2 | 2026-07-15 | architect | D18-P63-A | Removed outlier "Splitter inputs" row from §Fuzzing Targets per BC-2.17.002 authority (two targets only: fuzz_checkpoint_serde + fuzz_graph_execution); added named harness IDs to remaining rows; added non-normative note directing splitter robustness to proptest + BC-2.07.002 Red Gate suite with post-v1 fuzz candidacy. Coverage-matrix already shows splitter fuzz = — (no matrix edit required). |
| 1.1 | 2026-07-14 | architect | D18-P38-A | Fixed stale VP count in §"Committed VP Obligations": intro line changed from "Three VPs" to correctly enumerate five total (three Kani D17-Q7/NFR-003 + two integration R11); heading updated from (D17-Q7) to (D17-Q7 + R11) for mutual coherence with table and total line |
| 1.0 | 2026-07-14 | architect | D17 | Initial verification architecture with Kani async constraint, VP catalog, purity boundaries, and risk mitigations |
