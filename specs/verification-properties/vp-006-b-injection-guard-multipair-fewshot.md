---
document_type: verification-property
level: L4
vp_id: VP-006-B
title: "injection_guard Multi-Pair FewShotExamples Fail-Closed — Untrusted Component at Any Pair Index in TrustRequired Slot Raises E-TMPL-001"
status: draft
producer: product-owner
timestamp: 2026-08-26T00:00:00Z
phase: 3
inputs:
  - .factory/specs/behavioral-contracts/ss-18/BC-2.18.004.md
input-hash: "a8c363d"
traces_to: ARCH-INDEX.md
source_bc: BC-2.18.004
bc_anchor: BC-2.18.004
bc_anchor_clause: "{PC-005}"
di_anchor: DI-014
module: prompts::injection_guard
crate: pregolya-prompts
tool: proptest
proof_method: proptest
proof_phase: 3
priority: P1
red_gate: true
red_gate_source: "BC-2.18.004 TV-007 annotated '(Red Gate)' — multi-pair check_fewshot_trust test must compile-and-fail before check_fewshot_trust is implemented"
feasibility: feasible
verification_lock: false
proof_completed_date: null
proof_file_hash: null
lifecycle_status: active
introduced: v1.0.0-greenfield
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
withdrawn: null
withdrawal_reason: null
removed: null
removal_reason: null
version: "1.0"
changelog:
  - "1.0 (B-SS18-sec-adjudication/ADR-029-SEC-003/2026-08-26): VP-006-B created — multi-pair FewShotExamples proptest complement to VP-006 Kani harness; covers any-pair-index-untrusted patterns including middle-pair-only scenarios (TV-007 Red Gate); anchors BC-2.18.004 {PC-005} 3rd arm; DI-014; harness_fn injection_guard_multipair_fewshot_fail_closed."
---

# VP-006-B: injection_guard Multi-Pair FewShotExamples Fail-Closed — Untrusted Component at Any Pair Index in TrustRequired Slot Raises E-TMPL-001

## Property Statement

For any `FewShotExamples` list of arbitrary length bound to a `TrustRequired` slot in
`format_messages`, if at least one `(iv, ov)` pair at any index has
`iv.trust_level.is_some_and(|t| t.is_untrusted())` or
`ov.trust_level.is_some_and(|t| t.is_untrusted())`, `check_fewshot_trust` returns
`Err(E-TMPL-001)` and no `PromptValue` is produced.

**Formal property (DI-014):**
```
∀ pairs: Vec<(TemplateVar, TemplateVar)>,
∀ slot_policy = TrustRequired,
(∃ (iv, ov) ∈ pairs:
    iv.trust_level.is_some_and(|t| t.is_untrusted()) ∨
    ov.trust_level.is_some_and(|t| t.is_untrusted()))
→ check_fewshot_trust(slot_policy, &pairs) == Err(PregolyaError { code: "E-TMPL-001", category: Category::Security, .. })
```

This property holds for arbitrary Vec lengths and for any pair index (first, middle, last).
The single-pair VP-006 Kani harness (`injection_guard_fewshot_fail_closed`) covers the
1-pair case exhaustively. VP-006-B covers the multi-pair dimension via proptest, including
the middle-pair-only-untrusted pattern (TV-007).

## Source Contract

- **BC:** BC-2.18.004 — injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed at Render Time)
- **Postcondition 5 ({PC-005}):** `injection_guard` checks each `FewShotExamples` pair
  component's `trust_level` against `TrustRequired` slots. The guard fires on the first
  untrusted component encountered: `iv` is evaluated before `ov` within each pair; pairs
  are evaluated in Vec index order. Same error code and category as Scalar and Messages arms.
- **TV-007 (Red Gate):** 4-pair FewShotExamples where pair index 1 iv is `Untrusted` and
  pairs 0/2/3 are `Trusted`. Must compile-and-fail before `check_fewshot_trust` is
  implemented.
- **Invariant 1 ({INV-001}):** injection_guard fires unconditionally for every TrustRequired
  slot — no bypass path exists.
- **Invariant 3 ({INV-003}):** Pure-core synchronous function — no I/O, no async, no
  external dependencies.

## BC Traceability

| BC | Title | Contribution |
|----|-------|-------------|
| BC-2.18.004 | injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed at Render Time) | Primary VP obligation; {PC-005} FewShotExamples 3rd arm; TV-007 (Red Gate multi-pair) |

Specific anchors: BC-2.18.004 {PC-005} (FewShotExamples arm — iv before ov, Vec index
order), TV-007 (Red Gate: 4-pair list; middle pair index 1 iv Untrusted; guard fires
fail-closed).

## Proof Method

| Method | Tool | Bounded? | Coverage |
|--------|------|----------|----------|
| Property-based test | proptest | Vec length 1..=8 pairs (proptest generates varied sizes) | For any generated pair list with at least one untrusted component, verify `check_fewshot_trust` returns `Err(E-TMPL-001)`; includes first-pair, middle-pair, last-pair, all-untrusted, and single-pair-middle-untrusted patterns |

**Why proptest (not Kani) for multi-pair coverage:** The VP-006 Kani harness
(`injection_guard_fewshot_fail_closed`) covers a 1-pair `FewShotExamples` list exhaustively.
For multi-pair lists (arbitrary Vec length), Kani's loop-unwinding bound makes exhaustive
coverage intractable without artificial Vec-length constraints. Proptest generates concrete
multi-pair lists with arbitrary trust level assignments and verifies the fail-closed property
empirically across large samples — the appropriate tool for the "any pair index" dimension.

**Complementary coverage (not duplication):** VP-006 (Kani) proves exhaustive correctness
for the 1-pair case and for Scalar/Messages arms. VP-006-B (proptest) adds empirical
confidence for multi-pair scenarios. Both pass = high overall assurance for {PC-005}.

## Proof Harness Skeleton

Target file: `pregolya-prompts/tests/injection_guard_multipair.rs`

Harness function: `injection_guard_multipair_fewshot_fail_closed`

```rust
// pregolya-prompts/tests/injection_guard_multipair.rs
// VP-006-B — multi-pair FewShotExamples fail-closed proptest

use pregolya_prompts::injection_guard::check_fewshot_trust;
use pregolya_prompts::trust::TrustLevel;
use pregolya_prompts::template::{SlotTrustPolicy, TemplateVar};
use proptest::prelude::*;

/// Strategy: generate an Option<TrustLevel> for a single component
fn arb_trust_level() -> impl Strategy<Value = Option<TrustLevel>> {
    prop_oneof![
        Just(None),
        Just(Some(TrustLevel::Trusted)),
        Just(Some(TrustLevel::UserInput)),
        Just(Some(TrustLevel::Untrusted)),
    ]
}

/// Strategy: generate a (iv, ov) pair
fn arb_pair() -> impl Strategy<Value = (TemplateVar, TemplateVar)> {
    (arb_trust_level(), arb_trust_level()).prop_map(|(it, ot)| {
        (
            TemplateVar { value: String::new(), trust_level: it },
            TemplateVar { value: String::new(), trust_level: ot },
        )
    })
}

proptest! {
    /// VP-006-B main harness: any-pair-index-untrusted → E-TMPL-001
    #[test]
    fn injection_guard_multipair_fewshot_fail_closed(
        pairs in proptest::collection::vec(arb_pair(), 1..=8)
    ) {
        // Only test cases where at least one pair has an untrusted component
        let has_untrusted = pairs.iter().any(|(iv, ov)| {
            iv.trust_level.is_some_and(|t| t.is_untrusted())
                || ov.trust_level.is_some_and(|t| t.is_untrusted())
        });
        prop_assume!(has_untrusted);

        let result = check_fewshot_trust(SlotTrustPolicy::TrustRequired, &pairs);
        prop_assert!(
            matches!(result, Err(ref e) if e.code == "E-TMPL-001"),
            "check_fewshot_trust must return E-TMPL-001 for any untrusted pair component \
             in TrustRequired slot"
        );
    }

    /// VP-006-B TV-007 concrete: 4-pair list, middle pair (index 1 iv) Untrusted
    #[test]
    fn injection_guard_multipair_middle_untrusted(_ignored in Just(())) {
        let pairs = vec![
            (TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Trusted) },
             TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Trusted) }),
            (TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Untrusted) },
             TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Trusted) }),
            (TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Trusted) },
             TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Trusted) }),
            (TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Trusted) },
             TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Trusted) }),
        ];
        let result = check_fewshot_trust(SlotTrustPolicy::TrustRequired, &pairs);
        prop_assert!(
            matches!(result, Err(ref e) if e.code == "E-TMPL-001"),
            "guard must fire for middle-pair Untrusted iv (TV-007 Red Gate concrete case)"
        );
    }

    /// VP-006-B negative: all-Trusted pairs → Ok(())
    #[test]
    fn injection_guard_multipair_all_trusted_passes(
        n in 1usize..=8usize
    ) {
        let pairs: Vec<(TemplateVar, TemplateVar)> = (0..n).map(|_| (
            TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Trusted) },
            TemplateVar { value: String::new(), trust_level: Some(TrustLevel::Trusted) },
        )).collect();
        let result = check_fewshot_trust(SlotTrustPolicy::TrustRequired, &pairs);
        prop_assert!(
            result.is_ok(),
            "all-Trusted multi-pair list must not trigger E-TMPL-001"
        );
    }
}
```

## Feasibility Assessment

**Feasibility: HIGH**

| Factor | Assessment | Notes |
|--------|-----------|-------|
| Input space | Bounded by proptest Vec strategy (1..=8 pairs) | Covers single-, middle-, and last-pair-untrusted patterns across varied list sizes |
| Proof complexity | Low | Structural fail-closed check on Vec of pairs; no async, no I/O |
| Tool support | Supported | `proptest` + `proptest-derive`; same toolchain already used in workspace |
| Async concern | None | `check_fewshot_trust` is pure-core sync (ADR-015 Decision 3) |
| Estimated proof time | < 1s per proptest case | 10k cases × negligible per case |

No blocking risks. `check_fewshot_trust` must be extractable as a standalone pure function
(same obligation as `check_slot_trust` for VP-006) — this is the shared pure-core extraction
pattern for all `injection_guard` VP harnesses.

## Proof Obligations

- [ ] `check_fewshot_trust(policy: SlotTrustPolicy, pairs: &[(TemplateVar, TemplateVar)]) -> Result<(), PregolyaError>` extracted as a named pure function in `injection_guard` module
- [ ] `injection_guard_multipair_fewshot_fail_closed` proptest runs without shrinking failures for 10k cases with `prop_assume!(has_untrusted)` filter
- [ ] `injection_guard_multipair_middle_untrusted` concrete test passes (TV-007 Red Gate: fails before implementation, passes after)
- [ ] `injection_guard_multipair_all_trusted_passes` negative test confirms no false positives for all-Trusted multi-pair lists
- [ ] VP-006 `injection_guard_fewshot_fail_closed` Kani harness and VP-006-B proptest harness run in the same `cargo nextest` invocation without interference
- [ ] BC-2.18.004 {PC-005} 3rd arm verified: `check_fewshot_trust` iterates pairs in Vec index order; first untrusted component (iv before ov within a pair) triggers E-TMPL-001

## Lifecycle

| Event | Date | Actor |
|-------|------|-------|
| Created | 2026-08-26 | product-owner |
| Proptest harness implemented | | test-writer |
| Harness passes | | implementer |
| Locked (VERIFIED) | | formal-verifier |
