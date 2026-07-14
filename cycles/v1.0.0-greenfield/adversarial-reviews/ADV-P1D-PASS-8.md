---
document_type: adversarial-review
pass: 8
phase: 1d
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
finding_count: 5
sibling_checks: run-status PASS (CONVERGED — full-vocabulary complement confirmed); status-governance axis PASS (prior pass verified); 2 prior axes re-verified CLEAN
trajectory: "14→5→7→13→3→3→3→5"
convergence_counter: "0/3"
produced_by: product-owner
timestamp: 2026-07-14T06:00:00Z
process_gap: "BC-INDEX title axis previously SAMPLED (not full-census) — generalized to whitelist-complement / full 86-row census method this pass"
---

# ADV-P1D-PASS-8 — Adversarial Review

**Verdict:** NOT CLEAN — 5 findings (1 HIGH, 2 MED, 2 LOW)

---

## Sibling Checks

| Check | Result |
|-------|--------|
| run-status vocabulary (full-census complement) | **PASS — CONVERGED** |
| BC-INDEX title axis (full 86-row census vs H1s) | DONE — 5 exceptions found, 4 task-specified + 1 additional (BC-2.13.004 H1 lacked "— Kani VP Seed" present in INDEX) |
| status-field governance (integrated-into-index ⇒ active) | DONE — 29 files normalized |
| Error message fidelity (per-BC semantic anchor) | DONE — 2 messages fixed |
| PC self-contradiction audit (SS-08 eval contract) | DONE — 1 self-contradiction fixed |

**run-status CONVERGED evidence:**
```
grep -rn "→ running\|running →\|\"running\"\|status.*\`running\`|\`running\`.*status|run_status.*running|/running/" .factory/specs/
```
Result: 0 hits (full-vocabulary complement, all backtick/slash/quote forms).

---

## Full 86-Row BC Title Census (F-P8-01 Evidence)

**Method:** `find .factory/specs/behavioral-contracts/ -name 'BC-*.md' ! -name 'BC-INDEX.md' | xargs grep -h "^# BC-"` produced 86 H1 lines. Diffed against BC-INDEX title column.

**Census result:** 82/86 exact-match. 5 exceptions:

| BC ID | H1 Title (authoritative) | BC-INDEX Title (pre-fix) | Type |
|-------|--------------------------|--------------------------|------|
| BC-2.08.007 | `...Surfaces Err(Timeout) or Err(Transport), Not Truncated Success` | `...Surfaces Err(Timeout), Not Truncated Success` | Missing "or Err(Transport)" |
| BC-2.15.002 | `...Does Not Bleed Across Scopes` | `...Does Not Bleed Across Sessions` | "Sessions" → "Scopes" |
| BC-2.17.001 | `...Workspace Confinement VP` | `...Workspace-Escape VP` | Wrong VP name |
| BC-2.17.002 | `...Graph-Execution Paths` | `...Graph-Engine Boundary` | Wrong cargo-fuzz target name |
| BC-2.13.004 | H1 lacked "— Kani VP Seed" | INDEX had "— Kani VP Seed" | INDEX enrichment not lifted to H1 (per bc_h1_is_title_source_of_truth policy — consistent with BC-2.03.001/BC-2.04.006 pattern) |

**Cascade scope:** BC-2.08.007 drift also present in prd.md §2.08 table (line 224) and bc-authoring-plan.md Batch 9 table (line 243). BC-2.15.002 and BC-2.17.001/002 were already correct in prd.md and bc-authoring-plan.md (only BC-INDEX was wrong for those three).

**Post-fix census: 86/86 exact-match.**

---

## Findings

### F-P8-01 [HIGH] — 4 BC-INDEX title drifts (full-census method, process-gap: prior passes sampled)

**Root cause:** Prior adversarial passes spot-checked BC-INDEX titles against H1s using sampled rows, not a full census. This allowed 4 drift cases to persist undetected. One additional drift (BC-2.13.004 INDEX enrichment not in H1) was also caught by the census.

**Pre-fix locations:**
- `BC-INDEX.md` row BC-2.08.007: "Surfaces Err(Timeout), Not Truncated Success" (missing "or Err(Transport)")
- `BC-INDEX.md` row BC-2.15.002: "Does Not Bleed Across Sessions" (should be "Scopes")
- `BC-INDEX.md` row BC-2.17.001: "Workspace-Escape VP" (should be "Workspace Confinement VP")
- `BC-INDEX.md` row BC-2.17.002: "Graph-Engine Boundary" (should be "Graph-Execution Paths")
- `prd.md:224`: BC-2.08.007 title missing "or Err(Transport)"
- `bc-authoring-plan.md:243`: BC-2.08.007 title missing "or Err(Transport)"
- `BC-2.13.004.md` H1: missing "— Kani VP Seed" (INDEX had it; H1 is source of truth per policy)

**Fixes applied:**
- BC-INDEX.md: corrected all 4 primary drifts to match H1 verbatim
- prd.md §2.08 table: added "or Err(Transport)" to BC-2.08.007 title
- bc-authoring-plan.md Batch 9: added "or Err(Transport)" to BC-2.08.007 title
- BC-2.13.004.md H1: added "— Kani VP Seed" (lifts INDEX enrichment into H1 per bc_h1_is_title_source_of_truth)

**Post-fix verification:**
```
grep -h "^# BC-" .factory/specs/behavioral-contracts/**/*.md > /tmp/h1s.txt
# Compare against BC-INDEX title column: 86/86 exact-match
```
Result: 86/86.

---

### F-P8-02 [MED] — BC-2.08.008 PC5 self-contradiction: "NaN or" path alongside Err(EvalError::AllCasesInfraError)

**Location:** `BC-2.08.008.md:67`

**Pre-fix text:**
> If all return `InfraError`, the aggregate score is `NaN` or the runner returns `Err(EvalError::AllCasesInfraError)` — it does not return `1.0` or `0.0`.

**Problem:** The phrase "NaN or" introduces an alternate outcome (`f64::NAN`) that contradicts EC-001, EC-003, TV-004, and the Invariants section (which requires a `Result` type). The definitive path is `Err(EvalError::AllCasesInfraError)`. "NaN or" implies an implementation might return `Ok(NaN)` as an acceptable alternative, which is false — an `Ok` return with score data is excluded by EC-001/EC-003.

**Fix applied (`BC-2.08.008.md:67`):**
> If all return `InfraError`, the runner returns `Err(EvalError::AllCasesInfraError)` —
> it does not return `1.0` or `0.0`.

"NaN or" dropped. Err-only outcome now consistent with EC-001/EC-003 and TV-004.

---

### F-P8-03 [MED] — E-CORE-001 message lists provider wire types, not ferrochain KNOWN_BLOCK_TYPES; misrepresents actual trigger

**Location:** `error-taxonomy.md:56`

**Pre-fix:**
```
Invalid ContentBlock type '<type>' in position <n> of message; expected one of: text, image_url, tool_use, tool_result, document
```

**Problems:**
1. Lists `image_url`, `tool_use`, `tool_result`, `document` — OpenAI/Anthropic provider wire tags, not ferrochain's `ContentBlock` enum serde tags.
2. Implies E-CORE-001 fires on any unknown type; BC-2.01.001 Invariants say unknown types map to `ContentBlock::NonStandard` in lenient deserialization — E-CORE-001 is the strict-validation mode path only.
3. "expected one of: ..." style implies a fixed closed set shown to callers, but the KNOWN_BLOCK_TYPES set governs dispatch, not rejection.

**Fix applied:**
```
StrictContentBlockValidation: block at position <n> has unrecognized type tag '<type>'; not in KNOWN_BLOCK_TYPES — use lenient deserialization for NonStandard passthrough
```

Aligns with BC-2.01.001 PC5 (NonStandard mapping), PC6 (strict-validation error path), and Invariants (KNOWN_BLOCK_TYPES set). Drops incorrect provider-specific type list.

---

### F-P8-04 [LOW] — Status-field governance gap: 29 integrated spec artifacts carried `status: draft`

**Scope:** All `status: draft` occurrences in `.factory/specs/` outside `behavioral-contracts/` and `verification-properties/`.

**Pre-fix count:** 29 files

**The rule (F-P6-03 extended):** An artifact integrated into its authoritative index is `status: active`. Draft status after integration is a governance gap — it signals the artifact might not be finalized when it actually is the current spec state.

**Affected artifact classes:**
- `prd.md` (L3 root document, integrated by definition): `draft → active`
- `prd-supplements/` × 4 (error-taxonomy, interface-definitions, nfr-catalog, module-criticality): `draft → active`
- `domain-spec/` × 15 shards (integrated via L2-INDEX): `draft → active`
- `architecture/` × 9 sections (integrated via ARCH-INDEX): `draft → active`

**VP exception:** VP-001 through VP-005 remain `status: draft` — VP-INDEX.md is `status: active` and tracks all 5 VPs. VPs stay draft until their Kani/integration harnesses are implemented (wave 1 or post-v1 deliverables).

**ADR and brief exception:** ADRs remain `status: accepted`; product-brief remains `status: approved`. These are correct per their document-type governance.

**Fix applied:** Python bulk replacement of `status: draft\n` → `status: active\n` across 29 files.

**Governance rule written to:** `bc-authoring-plan.md` Authoring Guidelines item 11 (generalized rule, cites ADV-P1D-PASS-8.md §F-P8-04).

**Post-fix distinct-value table (all of `.factory/specs/`):**

| Value | Count | Justification |
|-------|-------|---------------|
| `status: active` | 120 | All integrated spec artifacts: BCs (86), prd.md + supplements, domain-spec shards, architecture sections, VP-INDEX, BC-INDEX |
| `status: accepted` | 11 | ADRs — accepted ADR is the terminal state per ADR governance |
| `status: draft` | 5 | VP-001 through VP-005 — pre-implementation Kani/integration harnesses; VP-INDEX tracks these |
| `status: approved` | 1 | product-brief.md — approved product brief |

---

### F-P8-05 [LOW] — E-MEMORY-003 field name and semantics mismatch with BC-2.15.002

**Location:** `error-taxonomy.md:186` (MEMORY component section)

**Pre-fix:**
```
ScopeAccessDenied: requested scope <requested_scope> requires higher privilege than caller scope <caller_scope>
```

**Problems:**
1. Field name `caller_scope` should be `caller_identity` per BC-2.15.002 Invariants: "returns `Err(E-MEMORY-003 ScopeAccessDenied { requested_scope: User("bob"), caller_identity: "alice" })`"
2. "requires higher privilege than caller scope" describes privilege elevation (vertical denial), but BC-2.15.002's invariant is about **cross-owner lateral denial** (alice trying to write to bob's scope). The two users could be at the same privilege level — the denial is identity-based, not privilege-based.
3. TV-001 tests this exact scenario: `memory_get(User("bob"), "key1")` as alice → `None`. The enforcement is about scope ownership, not privilege levels.

**Fix applied:**
```
ScopeAccessDenied: caller identity '<caller_identity>' cannot write to <requested_scope> — cross-owner lateral access denied
```

Field `caller_identity` matches BC-2.15.002 Invariants exactly. "cross-owner lateral access denied" describes the actual semantics (alice cannot write to bob's scope because it's bob's scope, not because alice lacks privilege level). Consistent with TV-001/TV-004 test vectors.

---

## Prior Axes Re-Verified CLEAN This Pass

| Axis | Method | Result |
|------|--------|--------|
| run-status vocabulary (passes 7, 6, 5) | Full grep of all forms `→ running`, `"running"`, `` `running` ``, `/running/`, `run_status.*running` | CLEAN — 0 hits (CONVERGED) |
| DI orphan coverage (pass 6) | bc-authoring-plan.md §DI Invariant Enforcement Coverage: 14/14 DIs, zero orphans | CLEAN |

---

## Cumulative BC-Body Coverage

~90% of BC body content has been reviewed across passes 1–8 (sampled from all 17 subsystems, full coverage of SS-01 through SS-14, partial coverage SS-15/SS-17).

---

## Convergence Trajectory

```
Pass 1: 14 findings
Pass 2:  5 findings
Pass 3:  7 findings
Pass 4: 13 findings
Pass 5:  3 findings
Pass 6:  3 findings
Pass 7:  3 findings
Pass 8:  5 findings  ← this pass (process-gap axis exposed by full-census method)
```

Counter: 0/3 (3 consecutive passes with ≤3 findings required for CLEAN declaration).

Finding count regressed from 3 to 5 due to the new full-census method exposing the BC-INDEX title axis. The process-gap has been closed (whitelist-complement / full-census now mandatory for this axis). Expected trajectory improvement next pass.
