---
document_type: story
level: ops
story_id: S-2.05
epic_id: E-18
version: "1.0"
status: draft
producer: story-writer
timestamp: 2026-08-19T00:00:00Z
phase: 2
inputs:
  - .factory/specs/behavioral-contracts/ss-18/BC-2.18.004.md
  - .factory/specs/behavioral-contracts/ss-18/BC-2.18.005.md
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/architecture/decisions/ADR-015-prompt-template-injection-safety.md
input-hash: "5a24e8f"
traces_to: .factory/stories/STORY-INDEX.md
points: 8
depends_on: [S-2.04]
blocks: [S-6.01]
behavioral_contracts: [BC-2.18.004, BC-2.18.005]
verification_properties: [VP-006]
priority: P1
cycle: v1.0.0-greenfield
wave: 2
target_module: pregolya-prompts
subsystems: [SS-18]
estimated_days: 2
assumption_validations: []
risk_mitigations: []
tdd_mode: strict
---

# S-2.05: Prompt Injection Safety Guard — TrustLevel Severity, injection_guard, and SystemMessage Policy Enforcement

## Narrative

- **As a** pregolya prompt author operating in an untrusted-input environment
- **I want** `ChatPromptTemplate::format_messages` to evaluate the provenance trust level of each bound variable against its slot's declared `SlotTrustPolicy`, and reject format attempts that would inject untrusted content into `TrustRequired` slots — with SystemMessage slots refusing `TrustAll` policy at construction time
- **So that** prompt injection paths are provably fail-closed: untrusted variables never reach LLM system context, and the type system + runtime guard together make injection a compile-time + runtime error rather than a silent security failure

## Behavioral Contracts

| BC | Title | Priority |
|----|-------|---------|
| BC-2.18.004 | injection_guard in format_messages — TrustLevel Severity Ordering; Fires BEFORE PromptValue Produced; E-TMPL-001 SECURITY/InjectionAttempt (Red Gate) | P1 |
| BC-2.18.005 | SlotTrustPolicy::TrustAll on SystemMessage Slot Raises E-TMPL-002 at Construction Time (Fail-Closed) (Red Gate) | P1 |

## Acceptance Criteria

### AC-001 (traces to BC-2.18.004 precondition 1 — Red Gate)
**RED GATE**: This test must COMPILE and FAIL before `injection_guard` is implemented.
A `ChatPromptTemplate` with a `TrustRequired` SystemMessage slot receives a
`TemplateInput::Scalar(TemplateVar)` tagged `TrustLevel::Untrusted`. The test asserts
`format_messages` returns `Err(E-TMPL-001)`. Fails as Red Gate because guard is absent.
Verified by `test_BC_2_18_004_untrusted_var_in_trust_required_slot_returns_e_tmpl_001_rg()`.

### AC-002 (traces to BC-2.18.004 postcondition 1)
`injection_guard` fires BEFORE the `PromptValue` is produced. If the guard fires for any
variable, no partial `PromptValue` is constructed — the function returns `Err` immediately.
Verified by a mock that tracks whether any message was assembled before the guard fires.
`test_BC_2_18_004_injection_guard_fires_before_prompt_value_produced()`.

### AC-003 (traces to BC-2.18.004 postcondition 2)
When injection is detected, the error is:
`Err(PregolyaError::new(Component::Tmpl, Category::Security, RetryHint::Never, "E-TMPL-001",
"InjectionAttempt: variable '<var_name>' carries untrusted provenance but slot '<slot_role>' requires TrustRequired policy"))`.
Both `var_name` and `slot_role` are dynamically interpolated into the message.
Verified by `test_BC_2_18_004_e_tmpl_001_dynamic_message_contains_var_and_role()`.

### AC-004 (traces to BC-2.18.004 postcondition 3)
`TrustLevel::severity()` returns a numeric severity score:
- `TrustLevel::Untrusted` → 2
- `TrustLevel::UserInput` → 1
- `TrustLevel::Trusted` → 0

The injection check uses `TrustLevel::severity()` — NEVER derived `Ord` comparison. The
derived `Ord` for an enum ordered `{Untrusted, UserInput, Trusted}` would have Untrusted < Trusted
(fail-open bug). The `severity()` method explicitly returns the correct ordering.
Verified by `test_BC_2_18_004_trust_level_severity_ordering()`.

### AC-005 (traces to BC-2.18.004 postcondition 4)
The injection guard fires when: `variable.trust_level.severity() > slot.policy.min_trust_severity()`.
A `TrustLevel::UserInput` variable in a slot with `SlotTrustPolicy::TrustRequired` fires the guard
only if `TrustRequired.min_trust_severity() == 0` (Trusted-only). A `TrustLevel::Trusted` variable
never fires the guard. Verified by `test_BC_2_18_004_severity_threshold_matrix()`.

### AC-006 (traces to BC-2.18.004 postcondition 5)
`injection_guard` evaluates slots in SOURCE ORDER (the order declared in `from_messages`).
It reports the FIRST violation found, not all violations simultaneously.
Verified by `test_BC_2_18_004_source_order_evaluation_first_violation()`.

### AC-007 (traces to BC-2.18.004 invariant 1)
`TrustLevel` is an enum: `Trusted`, `UserInput`, `Untrusted`. It is `#[non_exhaustive]`.
`TrustLevel` does NOT implement `PartialOrd` or `Ord` (to prevent accidental ordering bugs);
only `TrustLevel::severity() -> u8` is the ordering surface.
Verified by compile-fail test asserting `Ord` is not implemented: `test_BC_2_18_004_trust_level_no_ord_impl()`.

### AC-008 (traces to BC-2.18.004 invariant 2)
The injection guard operates on `TemplateVar` values that carry a `trust_level: TrustLevel`
field. A `TemplateVar` with no explicit trust annotation defaults to `TrustLevel::Trusted`
(conservative default — system-constructed values are trusted unless explicitly tagged).
Verified by `test_BC_2_18_004_templatevar_default_trust_is_trusted()`.

### AC-009 (traces to BC-2.18.004 invariant 3 — VP-006 Kani anchor)
`injection_guard` is FAIL-CLOSED: if the trust level evaluation encounters an unknown/new
`TrustLevel` variant, it defaults to treating the variable as untrusted (highest severity).
VP-006 (Kani P1) provides a formal proof of fail-closed behavior. Unit test:
`test_BC_2_18_004_fail_closed_unknown_trust_level_treated_as_untrusted()`.
This story is the ANCHOR story for VP-006.

### AC-010 (traces to BC-2.18.005 precondition 1 — Red Gate)
**RED GATE**: This test must COMPILE and FAIL before the `from_messages` SystemMessage policy
guard is implemented. `ChatPromptTemplate::from_messages(vec![(MessageRole::System, "You are {role}.", SlotTrustPolicy::TrustAll)])` — the test asserts this returns `Err(E-TMPL-002)`.
Fails as Red Gate because the construction-time guard is not yet in place.
Verified by `test_BC_2_18_005_system_slot_trust_all_returns_e_tmpl_002_rg()`.

### AC-011 (traces to BC-2.18.005 postcondition 1)
`ChatPromptTemplate::from_messages` with a `(MessageRole::System, _, SlotTrustPolicy::TrustAll)`
tuple returns:
`Err(PregolyaError::new(Component::Tmpl, Category::Val, RetryHint::Never, "E-TMPL-002",
"SystemMessage slots must use TrustRequired policy; TrustAll is disallowed for system-position message slots"))`.
The message is STATIC (no variable interpolation).
Verified by `test_BC_2_18_005_e_tmpl_002_exact_static_message()`.

### AC-012 (traces to BC-2.18.005 postcondition 2)
No `ChatPromptTemplate` is created when E-TMPL-002 fires — construction fails atomically.
No partial slot list is accessible. `from_messages` with two System slots where the first
is `TrustRequired` and the second is `TrustAll` also returns `Err(E-TMPL-002)` (not a partial template).
Verified by `test_BC_2_18_005_atomic_construction_failure()`.

### AC-013 (traces to BC-2.18.005 postcondition 4)
Non-SystemMessage slots with `TrustAll` (HumanMessage, AiMessage) do NOT trigger E-TMPL-002.
Only `MessageRole::System` with `TrustAll` is rejected.
Verified by `test_BC_2_18_005_human_ai_trust_all_allowed()`.

### AC-014 (traces to BC-2.18.005 invariant 1)
No SystemMessage slot can have `SlotTrustPolicy::TrustAll` after construction — there is no
mutation path to change a slot's policy post-construction. `ChatPromptTemplate` fields are
not exposed for mutation.
Verified by `test_BC_2_18_005_no_mutation_path_to_change_system_slot_policy()`.

### AC-015 (traces to BC-2.18.005 invariant 3)
E-TMPL-002 is `Category::Val` (not `Category::Security`). This is a programming error caught
at construction time. The runtime injection error is E-TMPL-001 (`Category::Security`).
The taxonomy distinction is intentional and must be preserved.
Verified by `test_BC_2_18_005_e_tmpl_002_category_val_not_security()`.

## Architecture Mapping

| Component | Module | Pure/Effectful |
|-----------|--------|----------------|
| `TrustLevel` enum + `severity()` method | `pregolya-prompts/src/trust.rs` | pure-core |
| `injection_guard` function | `pregolya-prompts/src/chat_template.rs` (inline, called from `format_messages`) | pure-core |
| `SystemMessage policy guard` in `from_messages` | `pregolya-prompts/src/chat_template.rs` | pure-core |
| VP-006 Kani harness | `pregolya-prompts/src/proofs/injection_guard.rs` | test/proof-only |
| Compile-fail test: TrustLevel no Ord | `pregolya-prompts/tests/external/trust-level-no-ord/` | test-only |

## Purity Classification

| Module | Classification | Justification |
|--------|---------------|---------------|
| `pregolya-prompts/src/trust.rs` | pure-core | TrustLevel is a data enum; severity() is a pure integer lookup. |
| `injection_guard` (inline in chat_template.rs) | pure-core | Pure iteration over slot/variable pairs; no I/O. |
| `from_messages` policy guard | pure-core | Pure construction-time check; no I/O. |

## Edge Cases

| ID | Scenario | Expected Behavior |
|----|----------|-------------------|
| EC-001 | All variables are `TrustLevel::Trusted`, all slots are `TrustRequired` | No guard fires; `format_messages` succeeds |
| EC-002 | `TrustLevel::UserInput` variable in `TrustAll` slot | Guard does NOT fire — UserInput is below TrustAll's minimum requirement |
| EC-003 | No variables bound (empty HashMap) but template has no required vars | Guard does not fire; succeeds |
| EC-004 | Two System slots: first TrustRequired (ok), second TrustAll (bad) | `Err(E-TMPL-002)` — second slot triggers the error; construction fails atomically |
| EC-005 | `injection_guard` encounters a variable with trust_level that would overflow severity() | Treated as Untrusted (fail-closed per AC-009) |
| EC-006 | `TrustLevel::Trusted` variable in `TrustRequired` System slot | Guard does NOT fire — Trusted is the correct trust level for TrustRequired |

## Token Budget Estimate (MANDATORY)

| Context Source | Estimated Tokens |
|---------------|-----------------|
| This story spec | ~4,200 |
| BC files (2 BCs) | ~7,500 |
| `module-decomposition.md` (SS-18 section) | ~400 |
| ADR-015 injection safety | ~3,000 |
| S-2.04 story spec (predecessor context) | ~2,500 |
| Module files (~80 lines each × 3 files) | ~2,700 |
| Test files (~120 lines) | ~1,800 |
| VP-006 Kani harness spec | ~500 |
| Tool outputs | ~500 |
| **Total** | **~23,100** |
| Agent context window | 200K (Sonnet) |
| **Budget usage** | **~12%** |

## Tasks (MANDATORY)

1. [ ] Write failing tests for AC-001 through AC-015 (test-writer); verify BOTH Red Gates (AC-001 and AC-010 must FAIL before guards are implemented)
2. [ ] Verify Red Gate density ≥ 0.5
3. [ ] Create `pregolya-prompts/src/trust.rs` — `TrustLevel` enum (`#[non_exhaustive]`, NO `Ord`/`PartialOrd` derives), `severity() -> u8` method
4. [ ] Update `pregolya-prompts/src/chat_template.rs` — add `injection_guard` (source-order evaluation, severity-based check, returns `Err(E-TMPL-001)` on violation); add SystemMessage `TrustAll` rejection in `from_messages`
5. [ ] Extend `TemplateVar` (from S-2.04) with `trust_level: TrustLevel` field; default to `TrustLevel::Trusted`
6. [ ] Register E-TMPL-001 (`Component::Tmpl, Category::Security, RetryHint::Never`) in error taxonomy
7. [ ] Verify E-TMPL-002 (`Component::Tmpl, Category::Val, RetryHint::Never`) is registered (from S-2.04)
8. [ ] Create `pregolya-prompts/src/proofs/injection_guard.rs` — VP-006 Kani harness stub for Phase 6 formal hardening
9. [ ] Create compile-fail test `tests/external/trust-level-no-ord/` asserting `TrustLevel` does NOT implement `Ord`
10. [ ] Run `cargo nextest run -p pregolya-prompts` — all tests pass

## Previous Story Intelligence (MANDATORY)

S-2.04 established `ChatPromptTemplate`, `SlotTrustPolicy`, `TemplateVar`, and `format_messages`.
This story EXTENDS `chat_template.rs` — it does NOT rewrite it. The `injection_guard` is
added inside `format_messages` as an internal step BEFORE the message list is assembled.
The `from_messages` SystemMessage check (AC-010) is added inside the existing `from_messages`
function.

**Critical: TrustLevel severity ordering.** `TrustLevel` must NOT derive `Ord` or `PartialOrd`
because the natural enum discriminant order (`Untrusted=0, UserInput=1, Trusted=2` in declaration
order) would give `Untrusted < Trusted`, which is the INVERSE of security severity — a derived
Ord comparison that "selects the higher trust level" via `a.max(b)` would actually select the
lower-severity value, creating a fail-open bug. The `severity()` method is the ONLY ordering
surface. Adversarial review found this class of bug in prior implementations. This story must
not repeat it.

**VP-006 anchor:** This story is the Phase 3 anchor for VP-006 (Kani P1 injection_guard
fail-closed proof). The Kani harness is created as a stub here; the full proof runs in Phase 6.

## Architecture Compliance Rules (MANDATORY)

| Rule | Source | Enforcement |
|------|--------|-------------|
| `TrustLevel` must NOT implement `Ord` or `PartialOrd` | BC-2.18.004 invariant 1; ADR-015 Decision 2 | Compile-fail test AC-007 |
| `injection_guard` fires BEFORE PromptValue is produced | BC-2.18.004 postcondition 2 | Unit test AC-002 |
| E-TMPL-001 message is DYNAMIC (contains var_name and slot_role) | BC-2.18.004 postcondition 3 | String contains check test |
| E-TMPL-002 message is STATIC (no interpolation) | BC-2.18.005 postcondition 1; invariant 3 | String equality test |
| E-TMPL-001 category is `Category::Security`; E-TMPL-002 category is `Category::Val` | BC-2.18.004 and BC-2.18.005 invariant 3 | Error code assertion tests |
| Fail-closed default: unknown TrustLevel treated as Untrusted | BC-2.18.004 invariant 3; VP-006 | Unit test AC-009 |
| `injection_guard` source-order evaluation | BC-2.18.004 postcondition 6 | Unit test AC-006 |

**Forbidden dependencies:** `pregolya-prompts/src/trust.rs` must NOT import from `pregolya-graph` or any crate that would create a cycle. `TrustLevel::severity()` must be a pure function with no external dependencies.

## Library & Framework Requirements (MANDATORY)

| Tool | Version | Purpose |
|------|---------|---------|
| `async-trait` | workspace pin | Inherited from S-2.04; `format_messages` is sync but `Runnable::invoke` is async |
| `kani` | workspace pin (Phase 6 only) | VP-006 Kani proof harness; harness stub created here, executed in Phase 6 |

## File Structure Requirements (MANDATORY)

| File | Action | Purpose |
|------|--------|---------|
| `pregolya-prompts/src/trust.rs` | CREATE | `TrustLevel` enum + `severity()` — no `Ord` derives |
| `pregolya-prompts/src/chat_template.rs` | MODIFY | Add `injection_guard` to `format_messages`; add SystemMessage TrustAll check to `from_messages` |
| `pregolya-prompts/src/template_input.rs` | MODIFY | Add `trust_level: TrustLevel` to `TemplateVar` with default `TrustLevel::Trusted` |
| `pregolya-prompts/src/lib.rs` | MODIFY | Add `pub mod trust;` |
| `pregolya-prompts/src/proofs/injection_guard.rs` | CREATE | VP-006 Kani harness stub |
| `pregolya-prompts/tests/external/trust-level-no-ord/main.rs` | CREATE | Compile-fail: TrustLevel no Ord |
