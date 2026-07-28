---
document_type: adversarial-review
level: ops
pass_id: P1D-175
pass_label: FULL-PERIMETER
frozen_head: 2d36282
date: 2026-07-27
version: "1.0"
status: closed
producer: adversary (7 slices: A/B1/B2/C1/C2/D1/D2; B-original/C-original/D-original died per D-40)
cycle: v1.0.0-greenfield
traces_to: STATE.md
---

# Adversarial Review — Pass P1D-175 FULL-PERIMETER (CLOSED)

> **RECORD STATUS: CLOSED.** All 7 slices complete: A (32) + B1 (29) + B2 (34) + C1 (26) + C2 (26) + D1 (17) + D2 (25) = 189 findings. Three original slices (B, C, D) lost to transient `Connection closed mid-response` failures; re-run split as B1/B2, C1/C2, D1/D2 per D-40 protocol. CLEAN(strict): NO. CLEAN(PR-merge): NO. Streak: 0/3 unchanged.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-175 FULL-PERIMETER |
| Frozen HEAD | `2d36282` |
| Date | 2026-07-27 |
| Method | Batch decomposition — 7 slices completed. B/C/D originals died (transient `Connection closed mid-response`); re-dispatched split per D-40 as B1/B2, C1/C2, D1/D2. 5 orchestrator adjudications (1–3 in D1 session; Adjudication 4 in D2 session). |
| Scope | Full perimeter: A (VP-002/003/004/005/007/008), B1 (BC-2.15.004/006, BC-2.16.002, BC-2.17.002), B2 (BC-2.18.001/002/003/005 + ADR-015), C1 (BC-2.12.001/002/005/007), C2 (`product-brief.md`), D1 (corpus-wide sweeps + census), D2 (changed-content verification of frozen HEAD `2d36282`) |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — UNCHANGED, do NOT advance** |

## Batch 1 Slice Status

| Slice | Perimeter | Status |
|-------|-----------|--------|
| A | VP-002, VP-003, VP-004, VP-005, VP-007, VP-008 | COMPLETE — 32 findings recorded below |
| B (original) | TBD | DIED — transient `Connection closed mid-response`; work unrecoverable per D-40 |
| B1 | BC-2.15.004, BC-2.15.006, BC-2.16.002, BC-2.17.002 | COMPLETE — 29 findings recorded below |
| B2 | BC-2.18.001, BC-2.18.002, BC-2.18.003, BC-2.18.005 + ADR-015 | COMPLETE — 34 findings recorded below |
| C (original) | TBD | DIED — had read its perimeter; partial work unrecoverable per D-40 |
| C1 | BC-2.12.001, BC-2.12.002, BC-2.12.005, BC-2.12.007 (SS-12 server) | COMPLETE — 26 findings recorded below |
| C2 | `product-brief.md` (v1.7, approved, never reviewed in 175 passes) | COMPLETE — 26 findings recorded below |
| D (original) | TBD | DIED — had surfaced leads; partial work unrecoverable per D-40 |
| D1 | Corpus-wide sweeps; census integrity | COMPLETE — 17 findings recorded below |
| D2 | Changed-content verification of frozen HEAD `2d36282` | COMPLETE — 25 findings recorded below |

---

## Slice A Perimeter

All six files were read line-by-line in full at frozen HEAD `2d36282`. Prior passes had read only frontmatter, harness names, and the `red_gate:` axis — this constituted the declared coverage debt in pass-174 §Coverage Debts. That debt is now closed for these six files.

Files covered: `VP-002.md`, `VP-003.md`, `VP-004.md`, `VP-005.md`, `VP-007.md`, `VP-008.md`

## Slice A Verified-Clean Axes

The following axes were verified clean in slice A. Future passes MUST NOT re-derive findings in these areas without new evidence against a changed HEAD.

- **BC §Traceability Title cells:** byte-exact match against all 13 anchor-BC H1s. The burst-256 sweep holds.
- **Gate #36 three-way corroboration for VP-004/VP-005 `red_gate: true`:** PASSES — anchor BC frontmatter confirms `red_gate: true`; BC-INDEX Red Gate rows are present; the R11 property is quote-verifiable in `product-brief.md` §Risks and `domain-spec/risks.md` §R-006.
- **VP-INDEX arithmetic:** 13 = 6+7 = 9+2+2. Holds.
- **Fabricated ADR citations:** none of the VP-011 fabrication pattern found in any of the six files.
- **`file:NNN` line-cite violations (TD-VSDD-091):** none found in any of the six files.
- **`CheckpointId` as `u64` newtype:** confirmed in ADR-005 §CheckpointId Adjudication.

## Slice A Totals

**32 findings: 0 CRIT / 14 HIGH / 13 MED / 4 LOW / 1 OBS-cluster**

---

## Slice A HIGH Findings (14)

### F-P175-A01 — VP-002: uniqueness scope contradiction between changelog and property statement

**Severity:** HIGH
**File:** `VP-002.md`
**Owner:** architect

**Defect:** VP-002 §Property Statement asserts that `checkpoint_id` must be "unique across the durable store." ADR-005 §CheckpointId Adjudication, revision 2, explicitly scopes uniqueness to the `(thread_id, checkpoint_ns)` pair, deliberately removing the store-global counter model present in revision 1. VP-002 v1.1's changelog records this broadening decision — and then the property statement overshot the broadening and re-asserted store-global uniqueness, the exact scope the revision 2 adjudication removed. The cell self-contradicts: the changelog records the narrowing intent while the property statement asserts the broader scope.

**Why it matters:** Invites rebuilding the store-global counter mechanism that ADR-005 revision 2 deliberately removed. Leaves implementers with contradictory uniqueness invariants for the checkpoint persistence layer.

---

### F-P175-A02 — VP-002: harness unrealizable — `kani::any` on heap-allocated types

**Severity:** HIGH
**File:** `VP-002.md`
**Owner:** architect

**Defect:** The harness calls `kani::any::<SessionKey>()` on a struct containing heap `String` fields, then applies a length bound via `assume(len() <= 64)` AFTER generation. Kani's `Arbitrary` trait does not support `String` or `Vec<T>` — these are heap-allocated types requiring special bounded generation via the `BoundedAny` pattern. VP-003 handles this correctly via `BoundedPathComponent`, so this is a sibling inconsistency within the same VP corpus, not an inherent Kani tooling limit.

**Why it matters:** The harness cannot be compiled under Kani as written. The `SessionKey` uniqueness property is unverifiable until rewritten using the bounded-generation pattern VP-003 already demonstrates.

---

### F-P175-A04 — VP-002: §Property Statement asserts a dataflow property neither harness proves

**Severity:** HIGH
**File:** `VP-002.md`
**Owner:** architect

**Defect:** §Property Statement claims a dataflow property — that the `(thread_id, session_index, checkpoint_ns)` triple flows from the trait method signature to the SQL WHERE clause without collapsing. Neither harness in VP-002 proves this; both only call `storage_address`. The real obligation is BC-2.04.006 Invariant 6 and VP-2.04.006-A, whose declared proof method is a Kani harness over async `CheckpointSaver` methods. VP-008 §Async Support states that Kani 0.67.0 has no async support. BC-2.04.006's primary VP obligation is therefore declared against a method family that cannot run under Kani.

**Why it matters:** BC-2.04.006's verification obligation exists in an unexecutable state — declared as Kani proof over async code Kani cannot model. §Property Statement in VP-002 makes a stronger claim than the harnesses can support.

---

### F-P175-A05 — VP-003: three-way drift between §Property Statement, §Formal Invariant, and harness

**Severity:** HIGH
**File:** `VP-003.md`
**Owner:** architect

**Defect:** §Property Statement is an exclusive two-way disjunction: the function returns `Ok(p)` with the path prefix invariant satisfied, or returns `Err(E-SBXD-001)`. The formal invariant forbids only bad-`Ok` outcomes; it does not address the error variant set. The harness explicitly permits other `Err` variants with `Err(other) => { let _ = other; }`. Three artifacts within one file specify different contracts for the same function.

**Why it matters:** A conformant implementation could return `Err(E-SBXD-002)` (or any other error variant) and the harness would PASS, but §Property Statement would be violated. The verification does not enforce the declared contract.

---

### F-P175-A10 — VP-004: `err.source().is_some()` assertion does not verify type identity

**Severity:** HIGH
**File:** `VP-004.md`
**Owner:** architect

**Defect:** VP-004 exists to verify TYPE IDENTITY preservation — that the original `McpError` remains accessible via `Error::source()`. The harness asserts only `err.source().is_some()`. This assertion passes with any attached cause, including a bare string. BC-2.09.004 TV-005 requires that `err.source()` specifically returns `McpError::ToolExecution`. The R11 defect this Red Gate was minted to lock would pass this assertion even when the bug is present. This is a TD-VSDD-059 false-green generator.

**Why it matters:** The Red Gate passes without verifying the invariant it was created to enforce. An implementation wrapping `McpError` into a generic error without preserving downcastability would produce a green gate.

---

### F-P175-A11 — VP-004: §Property Statement contradicts DI-014 and BC-2.09.004 PC1

**Severity:** HIGH
**File:** `VP-004.md`
**Owner:** architect

**Defect:** §Property Statement forbids "wrapped in a generic error" and "not downcast." This negates VP-004's own §Invariant (DI-014) and BC-2.09.004 PC1, both of which MANDATE wrapping into `FerrochainError` as a required step. The §Property Statement also forbids the only mechanism by which type identity can be recovered from `Error::source()` — wrapping plus `source()` chain access. The over-broadening originated from BC-2.09.004 PC2's narrow prohibition (do not LOSE the original error via opaque wrapping) but was expanded to forbid the wrapping mechanism that PC1 requires.

**Why it matters:** §Property Statement and the BC preconditions are logically contradictory. No implementation can satisfy both simultaneously.

---

### F-P175-A12 — VP-004 and VP-005: Red Gate test path names carry an extra `mcp_` segment vs registry

**Severity:** HIGH
**Files:** `VP-004.md`, `VP-005.md`
**Owner:** architect

**Defect:** VP-004 declares the Red Gate test path as `test_BC_2_09_004_mcp_tool_exception.rs`; VP-005 declares `test_BC_2_09_005_mcp_connection_failure.rs`. The canonical test-vectors registry declares the paths without the `mcp_` segment: `test_BC_2_09_004_tool_exception.rs` and `test_BC_2_09_005_connection_failure.rs`. PRD supplements supersede VP prose per the project source-of-truth precedence rule. A test-writer using these VPs as the authoritative source creates files that no Red Gate CI gate knows to look for, while the gate continues to report "test absent."

**Why it matters:** Red Gate tests authored against the VP-declared paths ship invisibly — the gate never finds them, never goes green, and never blocks on their absence.

---

### F-P175-A17 — VP-007: `prop_assume!` used where `prop_assert!` is required for component 1

**Severity:** HIGH
**File:** `VP-007.md`
**Owner:** architect

**Defect:** The harness uses `prop_assume!(matches!(serialized, Serialized::Constructor { .. }))` on component 1 of the three-part invariant it exists to prove. A regression to `Serialized::NotImplemented` — the BC-2.19.001 PC4 error variant — would cause the harness to silently DISCARD every failing case via `TestCaseError::Assume`, rather than reporting a test failure. The correct form is `prop_assert!`. Partial failures are exactly the inputs the harness was designed to detect, and the assumption silently discards them.

**Why it matters:** The harness cannot detect the regression it was written to prevent. TD-VSDD-059 false-green generator.

---

### F-P175-A18 — VP-007: `PromptTemplate` constructed via struct literal, contradicting BC-2.18.001

**Severity:** HIGH
**File:** `VP-007.md`
**Owner:** architect

**Defect:** The harness constructs `PromptTemplate` via a struct literal with an `input_variables` field. BC-2.18.001 PC1 specifies fallible named constructors returning `Result`; PC3 specifies `input_variables(&self) -> &[String]` as an ACCESSOR with extraction performed at construction time by the f-string engine. `verification-architecture.md` §Serializable uses the accessor form consistently. VP-007 encodes the wrong construction idiom as its harness entry point — a form that will not exist once BC-2.18.001 is implemented.

**Why it matters:** The harness tests a construction API surface that will not exist. The BC-mandated API surface is untested.

---

### F-P175-A19 — VP-007: `SystemMessage` built from raw `String`, encoding the BC-2.01.001 anti-pattern

**Severity:** HIGH
**Files:** `VP-007.md`, `BC-2.19.001 TV-004` (cross-perimeter)
**Owner:** architect (VP-007); product-owner (BC-2.19.001 TV-004)

**Defect:** The harness builds `SystemMessage { content }` from a raw `String` generated as `content in ".*{0,512}"`. Message content is typed as `MessageContent` / `Vec<ContentBlock>` per BC-2.01.002 and `entities-graph.md` §Message Entities. This encodes the exact raw-string construction anti-pattern BC-2.01.001 exists to forbid. BC-2.19.001 TV-004 carries the identical raw-string construction form, meaning test writers using the test vector as a template will produce non-compilable tests once BC-2.01.001 is implemented.

**Why it matters:** The harness verifies a construction path that cannot compile once the typed `MessageContent` API is in place. BC-2.19.001 TV-004 propagates the same defect to the test-vector layer.

---

### F-P175-A20 — VP-007: all 141 proptest harnesses placed in `ferrochain-core`, inverting crate layering

**Severity:** HIGH
**File:** `VP-007.md`
**Owner:** architect

**Defect:** VP-007 places all 141 round-trip proptest harnesses in `ferrochain-core/src/serializable.rs`, but the types under test (such as `PromptTemplate`) live in downstream crates including `ferrochain-prompts`. This would require `ferrochain-core` to dev-depend on the full workspace, inverting the dependency graph. The file self-contradicts on test placement — both the `#[cfg(test)] mod tests` inline form and the `tests/proptest_strategies/` directory form are described. VP-007 §Feasibility rates feasibility as HIGH without acknowledging the layering inversion that makes the central harness file unrealizable.

**Why it matters:** The verification plan as written cannot be executed without restructuring the crate graph. The harness home has no valid location.

---

### F-P175-A24 — VP-008: both harnesses verify their own test doubles, exercising zero production code

**Severity:** HIGH
**File:** `VP-008.md`
**Owner:** architect

**Defect:** `MockEmbeddings` returns `vec![0.1f32; self.dim]` (output dimension fixed by construction), then the harness asserts all vector lengths equal `dim` — a property true by construction, not by exercising any `ferrochain` production code path. The ragged mock contains the validation gate under test INSIDE the mock itself. Zero production code is exercised by either harness. VP-008 is the sole registered verification vehicle for BC-2.22.001's dimensionality invariant. `verification-architecture.md` documents this shape as intentional design, meaning it passed all prior reviews as a feature rather than a defect.

**Why it matters:** BC-2.22.001's dimensionality invariant ships unverified. The VP certifies its own test double. TD-VSDD-059 self-certification class.

---

### F-P175-A25 — VP-008: stale `FerrochainError` struct literal — three independent compile errors

**Severity:** HIGH
**Files:** `VP-008.md`, `BC-2.22.001 PC2` (cross-perimeter)
**Owner:** architect (VP-008); product-owner (BC-2.22.001 PC2); orchestrator (corpus-wide sweep)

**Defect:** VP-008's harness constructs `FerrochainError` as a struct literal with 4 of 6 required fields — `retry_hint` and `source` are omitted (error E0063 missing struct fields). The `message` field is `&'static str` where the struct requires `String` (type mismatch). The `#[non_exhaustive]` attribute on `FerrochainError` bars direct struct-literal construction entirely (error E0639). VP-008 was edited at v1.4 and v1.5 without catching any of these errors. BC-2.22.001 PC2 carries the identical 4-field literal.

**`[process-gap]`:** The `FerrochainError::new` adjudication performed in fix-burst 277 was never swept across inline struct construction sites in VP bodies and BC bodies. This is a TD-VSDD-060 sibling-site sweep failure within fix-burst 277 itself.

**Why it matters:** The harness cannot compile. BC-2.22.001's contract is unverifiable. The same defect in BC-2.22.001 PC2 will propagate to any test writer using it as a template.

---

### F-P175-A26 — VP-008: EC-003 falsely claimed as covered; EC-004 structurally excluded

**Severity:** HIGH
**File:** `VP-008.md`
**Owner:** architect

**Defect:** The Coverage cell claims EC-003 is covered by `ragged_batch_returns_embed_error`. That test case produces alternating 768/512-length vectors, which exercises Invariant 2 / TV-003 (dimension mismatch within a batch). EC-003 is a COUNT mismatch — the count of returned vectors does not equal the count of input texts — and no harness case produces `vecs.len() != texts.len()`. EC-004 (zero-length embedding vector) has no case and is structurally excluded because the harness bounds `dim in 1usize..=4096usize`, preventing generation of zero-dimension inputs. Two of three declared negative edge cases are uncovered; EC-003 carries a false coverage claim.

**Why it matters:** False coverage claims are the most dangerous form of spec drift. EC-003 and EC-004 are the failure modes most likely to produce silent data corruption at scale. The VP certifies them as covered when they are not.

---

## Slice A MED Findings (13)

### F-P175-A03 — VP-002: second harness doc-comment asserts a subsumed, mis-attributed property

**Severity:** MED
**File:** `VP-002.md`
**Owner:** architect

**Defect:** The second harness doc-comment claims to prove BC-2.04.006 Invariant 3, which is an API-structural property. An injectivity proof over storage addresses does not establish API structure — the obligations are orthogonal. The property is also subsumed by the first harness's scope. The doc-comment misrepresents the proof obligation for this harness.

---

### F-P175-A06 — VP-003: §Feasibility presents a settled interface split as an open design decision

**Severity:** MED
**File:** `VP-003.md`
**Owner:** architect

**Defect:** VP-003 §Feasibility presents the pure/effectful split for `canonicalize_beneath_root` as a "Key design decision required." `interface-definitions.md` already declares both `canonicalize_beneath_root_pure` and `canonicalize_beneath_root` as distinct method entries with separate signatures. The split is settled; §Feasibility has not been updated to reflect the decision already recorded in `interface-definitions.md`.

---

### F-P175-A07 — VP-003: harness uses non-existent `kani::vec` and `PathBuf::from_components`

**Severity:** MED
**File:** `VP-003.md`
**Owner:** architect

**Defect:** The harness calls `kani::vec(3, kani::any)` — Kani has no `kani::vec` function; bounded vector generation uses a different mechanism — and `PathBuf::from_components`, which is not a Rust standard library method. The bounded-generation mechanism is load-bearing for the workspace confinement Kani proof to be realizable.

**Why it matters:** The harness cannot compile as written. The proof mechanism is structurally wrong, not merely a naming variant.

---

### F-P175-A08 — VP-003: three-way error type and variant name drift

**Severity:** MED
**Files:** `VP-003.md`, `BC-2.13.004`, `interface-definitions.md`
**Owner:** architect

**Defect:** BC-2.13.004 §Description declares return type `SandboxError`; VP-003 and `interface-definitions.md` declare return type `FerrochainError`. The escape error variant is named `PathEscapeViolation` in `interface-definitions.md` and named `WorkspaceEscape` in the error taxonomy, BC files, and VP-003. `SandboxError` is declared nowhere in the corpus as a Rust type.

---

### F-P175-A13 — VP-004 and VP-005: `proof_method: manual` contradicts integration-test body

**Severity:** MED
**Files:** `VP-004.md`, `VP-005.md`
**Owner:** architect

**Defect:** Both VPs declare `proof_method: manual` in frontmatter. Their §Proof Method sections describe integration tests executed by nextest — structured test execution, not manual inspection. The frontmatter value and the body content describe different verification mechanisms for the same obligation.

---

### F-P175-A14 — VP-004 and VP-005: Phase-1 Red-Gate authoring obligation dropped from §Lifecycle

**Severity:** MED
**Files:** `VP-004.md`, `VP-005.md`
**Owner:** architect

**Defect:** Both VPs record only the Phase-3 pass condition for the Red Gate — what the test looks like once implementation is complete and the test passes. Both drop the Phase-1 authoring obligation: the Red Gate test must be authored in FAILING state during Phase 1, before any implementation exists, and committed to `factory-artifacts`. Dropping this obligation defeats the Red Gate mechanism — a test can be authored after implementation and trivially made to pass without ever serving as a genuine pre-implementation gate.

---

### F-P175-A15 — VP-005: "if not pooled" hedge contradicts §Property Statement and BC-2.09.005

**Severity:** MED
**File:** `VP-005.md`
**Owner:** architect

**Defect:** VP-005 §Feasibility includes the hedge "if not pooled." VP-005 §Property Statement and BC-2.09.005 EC-004 and TV-003 forbid connection pooling UNCONDITIONALLY as part of the fresh-connection-per-invocation contract. The hedge introduces a conditional that the §Property Statement forecloses. These are contradictory specifications within the same document.

---

### F-P175-A16 — VP-005: BC-2.09.005 compile-fail obligations have no verification vehicle

**Severity:** MED
**File:** `VP-005.md`
**Owner:** architect

**Defect:** BC-2.09.005 PC2, PC3, PC7, and TV-005 are compile-fail obligations — type system enforcement of connection lifecycle invariants. None of these have a verification vehicle in VP-005. `interface-definitions.md` already establishes the `tests/external/<gate-name>/` compile-fail test pattern. VP-005 declares the properties but provides no harness or compile-fail test stub for them.

---

### F-P175-A21 — VP-007: regex strategy `".*{0,512}"` is unbounded; `.` excludes newlines

**Severity:** MED
**File:** `VP-007.md`
**Owner:** architect

**Defect:** `content in ".*{0,512}"` applies the quantifier `{0,512}` to `.*`, which is already an unbounded wildcard — the quantifier is semantically redundant and does not bound the generated string length to 512. The `.` character in regex also excludes `\n` by default, so the strategy cannot generate multi-line content. The unicode coverage claim in §Coverage fails on both counts.

---

### F-P175-A22 — VP-007: §Coverage claims input shapes the harness strategy cannot produce

**Severity:** MED
**File:** `VP-007.md`
**Owner:** architect

**Defect:** §Coverage claims coverage of `None`/`Some` optional fields, empty strings, and unicode. The actual proptest strategy is `[a-zA-Z ]{1,128}`, which excludes unicode entirely and imposes a minimum length of 1 (cannot generate empty strings). §Coverage also names a fabricated `#[proptest]` attribute macro as the harness invocation form; the correct and actual invocation is the `proptest! { #[test] ... }` block form shown in the harness body. No `#[proptest]` attribute macro exists in the proptest crate.

---

### F-P175-A28 — VP-008: `input-hash: "[live-state]"` disables functional drift-detection field

**Severity:** MED
**File:** `VP-008.md`
**Owner:** architect

**Defect:** VP-008 carries `input-hash: "[live-state]"` while five sibling VP files carry real computed hashes. The `input-hash:` frontmatter field is a functional field consumed by the input-drift detection gate — it is not a citation in the TD-VSDD-091 sense. De-pinning it to `[live-state]` does not improve records hygiene; it converts a working staleness gate into a no-op for VP-008. Applying `[live-state]` corpus-wide would disable drift detection across the entire VP layer.

**Orchestrator adjudication (in-session, recorded here):** `[live-state]` sweeping is REJECTED. VP-008's de-pin was the error and must be corrected. TD-VSDD-091 governs citation text (symbol names and behavioral anchors instead of line numbers and volatile version pins); it does not govern functional frontmatter fields consumed by tooling. VP-008 must be re-pinned to a real computed hash. Historical SHA references in changelog rows and decisions-log rows remain valid — those reference immutable past burst SHAs.

---

### F-P175-A29 — VP-008 and BC-2.22.001: changelog entries carry volatile version pins

**Severity:** MED
**Files:** `VP-008.md`, `BC-2.22.001`
**Owner:** architect (VP-008); product-owner (BC-2.22.001); devops-engineer (records-lint gap)

**Defect:** VP-008's changelog carries post-ratification entries citing sibling spec artifact versions by version number (the `SpecName vN.N` pin form). VP-008 v1.6 ran TD-VSDD-091 hygiene over this same block and left the version pins intact — a partial fix that missed this sub-class. BC-2.22.001 v1.4 contains the identical version pin pattern.

**`[process-gap]`:** `records-lint.sh` L9 gates `file:NNN` line-number citations but does NOT gate volatile version pins of the `SpecDocName vN.N` form in changelog prose. This class of TD-VSDD-091 violation is currently undetected by the linter. See PG-175-A-03 below.

---

### F-P175-A30 — VP-008 vs `verification-architecture.md`: mock construction form and bounds diverge

**Severity:** MED
**Files:** `VP-008.md`, `verification-architecture.md`
**Owner:** architect

**Defect:** The two documents specify the same mock construction in incompatible ways. VP-008 uses `MockEmbeddings { dim }` struct-literal construction with bounds `1..=64`. `verification-architecture.md` §VP-008 uses `MockEmbeddings::new_fixed_dim(128)` named-constructor form with bounds `1..=32`. If `#[non_exhaustive]` is applied to `MockEmbeddings`, the struct-literal form in VP-008 is also invalid (error E0639). Neither form is reconciled; the two documents cannot both be correct.

---

## Slice A LOW Findings (4)

### F-P175-A09 — VP-003: §Source Contract appends a derived clause inside a quoted postcondition

**Severity:** LOW
**File:** `VP-003.md`
**Owner:** architect

**Defect:** §Source Contract appends a derived consequence clause ("therefore no escape possible") inside a field that should contain a verbatim quoted postcondition from the BC. Derived consequences belong in §Invariants or §Proof Method, not embedded within the quoted source postcondition.

---

### F-P175-A23 — VP-002, VP-007, VP-008: §BC Traceability names BCs absent from frontmatter `inputs:`

**Severity:** LOW
**Files:** `VP-002.md`, `VP-007.md`, `VP-008.md`
**Owner:** architect

**Defect:** §BC Traceability in all three VPs names BCs that do not appear in the frontmatter `inputs:` list. VP-007 additionally cites BC-2.19.002 in §Traceability prose without including it in `inputs:`. VP-003 follows the complete convention correctly — both its §BC Traceability table and its frontmatter `inputs:` list are in agreement.

---

### F-P175-A31 — VP-003, VP-008: free variables in formal statements

**Severity:** LOW
**Files:** `VP-003.md`, `VP-008.md`
**Owner:** architect

**Defect:** Formal statements contain unbound free variables: VP-003 §Formal Invariant uses `p` without binding it to a quantifier or function argument; VP-008 §Formal Invariant uses `d` similarly. The statements are not machine-translatable to proof obligations as written.

---

### F-P175-A32 — VP-007: §Feasibility proof-time bounds self-inconsistent; §Source Contract merges two PCs

**Severity:** LOW
**File:** `VP-007.md`
**Owner:** architect

**Defect:** §Feasibility states `<30s per type` across 141 types alongside `<10 min total`. These are mathematically inconsistent: 141 types at 30 seconds each is approximately 70 minutes, not 10. §Source Contract merges BC-2.19.001 PC3 (f-string engine extracts variables at construction time) and PC4 (error return for undefined variables) into a single table entry, obscuring their distinct roles and obligation boundaries.

---

## Slice A OBS-cluster (1)

### F-P175-A27 — All six VP source files: burst-276 `crate::module` canonicalization applied only to index documents

**Severity:** OBS-cluster (high-priority observation spanning 6 authoritative source files)
**Files:** `VP-002.md`, `VP-003.md`, `VP-004.md`, `VP-005.md`, `VP-007.md`, `VP-008.md`
**Owner:** architect

**Defect:** The burst-276 `crate::module` canonicalization was propagated to VP-INDEX, `verification-architecture.md`, and `verification-coverage-matrix.md` — the index and cross-reference documents — but was NOT applied to the 13 authoritative VP source files. All six VP source files reviewed in slice A carry pre-canonicalization module path identifiers:

| VP | Stale form | Canonical form |
|----|-----------|----------------|
| VP-002 | `session-index` | `checkpoint::session_index` |
| VP-003 | `path-guard` | `sandbox::path_guard` |
| VP-004 | `mcp-adapter` | `mcp::adapter` |
| VP-005 | `mcp-client` | `mcp::client` |
| VP-007 | `serializable` | `core::serializable` |
| VP-008 | `embeddings` | `core::embeddings` |

**Root-cause pattern:** The sweep ran index-document-first and stopped at the index boundary. The authoritative source files were not swept. This codifies process-gap PG-175-A-01 below (source-file-first sweep direction).

**Why it matters:** The index documents cite canonical paths while the authoritative source documents retain stale paths. Divergence between index and source is the class of drift the adversary exists to catch. Future passes reading source files will encounter stale module paths; passes reading index documents will see canonical forms. The divergence is undetectable by tooling until PG-175-A-04 is implemented.

---

## Orchestrator Adjudication — F-P175-A28 (`input-hash` de-pin)

Slice A escalated the `[live-state]` de-pin in VP-008 as a question requiring orchestrator adjudication before the finding could be assigned final severity and ownership.

**Decision (recorded here for durability):** `[live-state]` sweeping is REJECTED. VP-008's `input-hash: "[live-state]"` was an error; it must be re-pinned to a real computed hash. The `input-hash:` frontmatter field is a FUNCTIONAL field consumed by the input-drift detection gate — not a citation in the TD-VSDD-091 sense. De-pinning it does not improve records hygiene; it silently disables staleness detection for VP-008, converting a working gate into a no-op. Applying `[live-state]` corpus-wide would disable drift detection across the entire VP artifact layer. TD-VSDD-091 governs citation text (symbol names and behavioral anchors instead of line numbers and volatile version pins) — it does not govern functional frontmatter fields consumed by tooling.

Historical SHA references in changelog rows, decisions-log rows, and cycle manifests remain valid — those reference immutable past burst SHAs and constitute an audit trail.

**Owner for VP-008 re-pin:** architect.
**Recorded finding severity:** MED (F-P175-A28).

---

## Process-Gap Codifications (Slice A — Pending Formal Entry)

These candidate process rules are derived from slice A findings. They are recorded here for durability pending formal codification by the appropriate owner after the pass is closed.

### PG-175-A-01 — Source-file-first sweep direction

**Evidence:** F-P175-A27 (burst-276 canonicalization skipped 13 VP source files; VP-INDEX, `verification-architecture.md`, and `verification-coverage-matrix.md` received the update while their source files did not). F-P175-A25 (fix-burst 277 `FerrochainError::new` adjudication swept inline struct construction sites in VP bodies and BC bodies but did not sweep the VP harness bodies themselves). Two independent canonicalization fixes landed on documents that CITE a value while skipping the documents that DECLARE it.

**Proposed rule:** When any value changes (module path, constructor form, field count, error variant name), the sweep MUST begin with the authoritative source documents — VP body files, BC body files, the error taxonomy — before propagating to index documents and cross-reference docs. Source-file-first is the default sweep direction.

**Owner:** orchestrator (codification as a standing rule), devops-engineer (mechanical gate).

---

### PG-175-A-02 — VP harness positive-coverage requirement

**Evidence:** F-P175-A24 (VP-008 both mock harnesses verify their own test doubles; zero production code exercised). F-P175-A17 (VP-007 `prop_assume!` silently discards failure cases that should trigger assertion failures). F-P175-A10 (VP-004 assertion passes with any attached cause, not the type-specific cause the BC requires). Three independent instances from a single pass of harnesses certifying their own test doubles or silently discarding the very failures they were written to detect.

**Proposed rule:** A VP harness MUST assert against production code paths. Mock-only assertions — assertions trivially true given the mock's own construction, with no production code on any code path — are a finding. Harnesses that use `prop_assume!` on the primary invariant predicate, rather than `prop_assert!`, are a finding.

**Owner:** architect (VP authoring template), devops-engineer (review gate).

---

### PG-175-A-03 — `records-lint.sh` gap: `SpecName vN.N` version pins not gated by L9

**Evidence:** F-P175-A29 (VP-008 and BC-2.22.001 changelogs carry sibling spec version pins of the `SpecDocName vN.N` form; `records-lint.sh` L9 gates `file:NNN` line-number citations but not this class of volatile version reference).

**Proposed rule:** Extend `records-lint.sh` to detect and gate volatile version pins of the `SpecDocName vN.N` pattern in changelog and spec prose entries. These are the TD-VSDD-091 volatile-pin family at the version-reference level — they go stale whenever the cited document's version number advances, with nothing left to detect the stale reference.

**Owner:** devops-engineer.

---

### PG-175-A-04 — VP frontmatter drift check: source VP fields vs VP-INDEX rows

**Evidence:** F-P175-A27 (VP source files carry stale `module:` identifiers while VP-INDEX carries canonical forms). F-P175-A30 (VP-008 body and `verification-architecture.md` specify incompatible construction forms for the same mock).

**Proposed rule:** Mechanically diff VP frontmatter fields (`module:`, `crate:`, `tool:`, `priority:`, `proof_phase:`) against their corresponding VP-INDEX rows on every factory commit. Divergence between authoritative VP frontmatter and VP-INDEX is a blocking gate failure.

**Owner:** devops-engineer.

---

## Cross-Perimeter Observations from Slice A

These observations were identified during slice A's review but fall outside slice A's declared perimeter. They are flagged here for the owning slices and are NOT counted among slice A's 32 findings. Do not include these in slice A's tally.

1. **BC-INDEX.md header vs §VP Seed table:** BC-INDEX header claims 11 VP Seed entries; the sampled §VP Seed table shows 8 rows. Owner: whichever slice covers BC-INDEX census.

2. **BC-2.04.006 PC2 vs `interface-definitions.md` §CheckpointSaver:** PC2 names `RunnableConfig` as the config parameter type; `interface-definitions.md` §CheckpointSaver declares `CheckpointConfig` on every method. Owner: whichever slice covers BC-2.04.006.

3. **`error-taxonomy.md` §SBXD vs BC-2.13.004 and BC-2.13.005:** The taxonomy gives E-SBXD-001 a two-placeholder message template (`<resolved>`, `<root>`). BC-2.13.004 and BC-2.13.005 Invariant 2 mandate a three-field form specifying `requested`, `resolved`, and `root`. Owner: whichever slice covers the error taxonomy.

4. **`verification-architecture.md` §VP-008 shape rationale:** `verification-architecture.md` documents the VP-008 self-proving harness shape as intentional design — this rationale document must be corrected alongside VP-008 (F-P175-A24); aligning `verification-architecture.md` to the corrected VP-008 without correcting the rationale would leave the rationale perpetuating the defect. Owner: whichever slice covers `verification-architecture.md`.

---

## Novelty Assessment (Slice A)

**HIGH novelty.** The coverage debt on VP-002 through VP-008 bodies was genuine — prior passes had read only frontmatter, harness names, and the `red_gate:` axis. Reading the bodies line-by-line in full exposed three root-cause categories invisible to all prior passes:

1. **Harnesses verifying their own test doubles** (F-P175-A24, F-P175-A17, F-P175-A10): three independent instances in a single perimeter scan. This axis was structurally invisible to any pass that did not read harness bodies.

2. **§Property Statement over-claiming relative to formal invariant and harness** (F-P175-A05, F-P175-A11, F-P175-A01): multiple VPs assert stronger properties in prose than their formal sections demonstrate or their harnesses can verify.

3. **Canonicalization sweeps skipping authoritative source files** (F-P175-A27, F-P175-A25): two independent fixes applied to index and cross-reference documents while leaving source files with the pre-fix values. Both are direct consequences of fix operations at the frozen HEAD captured in this pass.

Finding F-P175-A25 and F-P175-A27 could not have been found in any pass predating the burst-276 and burst-277 operations — they are consequences of those bursts operating at the HEAD this pass examines.

---

---

## Slice B2 Perimeter and Verified-Clean Axes

Files covered (all read line-by-line in full): `BC-2.18.001`, `BC-2.18.002`, `BC-2.18.003`, `BC-2.18.005`, `ADR-015`. Closes part of the pattern-probe coverage debt declared in pass-174 §Coverage Debts for SS-18.

**Verified clean:** `subsystem: SS-18` and `capability: CAP-022|CAP-023` correct in all four BCs. BC-INDEX H1 titles match all four exactly. No frontmatter/index title drift. `BC-2.18.004` was NOT read (outside perimeter — targeted grep only). Record as residual debt.

## Slice B2 Totals

**34 findings: 2 CRIT / 17 HIGH / 11 MED / 2 LOW / 2 OBS**

---

## Slice B2 CRIT Findings (2)

### F-P175-B201 — BC-2.18.001: unguarded injection path falsely asserted as guarded

**Severity:** CRIT
**File:** `BC-2.18.001`
**Owner:** product-owner

**Defect:** `PromptTemplate::format` is an unguarded injection path while §Related BCs claims *"BC-2.18.004 — depends on: injection_guard fires during the render path that BC-2.18.001 exercises."* BC-2.18.004 scopes the guard to exactly one function: *"The `injection_guard` module fires inside `ChatPromptTemplate::format_messages` at render."* ADR-015 §Decision 3 concurs: *"The injection check fires at render time (inside `format_messages`)."* BC-2.18.001 PC1 declares no slots and no `SlotTrustPolicy`. PC2 accepts `HashMap<String, TemplateVar>` where `TemplateVar` carries `trust_level: Option<TrustLevel>`, yet no postcondition inspects `trust_level`. PC1 returns `Ok(rendered_string)` — a bare `String` with no `MessageProvenance`, discarding provenance at the boundary. A caller rendering a system prompt with `trust_level: Some(TrustLevel::Untrusted)` receives `Ok(String)` with no `E-TMPL-001`. Fail-open, papered over by a false coverage claim.

**Why it matters:** SS-18 is the security-tier subsystem; R12 is the ADR-015 threat model. The injection guard does not fire on single-message `PromptTemplate::format`; the false §Related BCs claim has made this invisible to all prior passes.

**Fix:** Either specify the guard obligation on `PromptTemplate::format`, or state prominently that single-message rendering is unguarded and forbid it for system-position content. Silent fail-open is a production-grade violation.

---

### F-P175-B202 — BC-2.18.003 and BC-2.18.002: MessagesPlaceholder and FewShotPromptTemplate expansion unguarded

**Severity:** CRIT
**Files:** `BC-2.18.003`, `BC-2.18.002`
**Owner:** product-owner (BC) + architect (ADR-015 §Decision 3 injection-check extension)

**Defect:** BC-2.18.003 §Related BCs claims the injection guard covers `MessagesPlaceholder` expansion and `FewShotPromptTemplate` example rendering. The ADR-015 §Decision 3 check iterates `slot.variable_names()` and inspects scalar `TemplateVar` entries only — `MessageListVar` is never inspected by any guard postcondition in BC-2.18.004 or ADR-015. Few-shot inner-template variables are not slot variables of the outer `ChatPromptTemplate`, so `slot.variable_names()` never sees them. Conversation history and streamed tool-result sequences — the explicitly named high-risk use cases in ADR-015 §Threat Model R12 — are the canonical untrusted sources routed through these paths. Compounded by F-P175-B208: the aggregate `highest_trust_level` the guard relies on is itself unreliable. Two independent bypasses of the primary threat model.

**Why it matters:** The security claim in §Related BCs creates false assurance. Both bypass vectors affect the paths most exposed to untrusted content in production agent workflows.

---

## Slice B2 HIGH Findings (17)

### F-P175-B203 — BC-2.18.001 and BC-2.18.005: illegal `FerrochainError` struct literals (multiple sites)

**Severity:** HIGH
**Files:** `BC-2.18.001` (PC4, §Description, TV-004), `BC-2.18.005` (PC1, §Description, TV-001)
**Owner:** product-owner

**Defect:** Multiple sites carry 4-field and 2-field `FerrochainError` struct literals. `ferrochain-prompts` is an external crate per ADR-015 ("`ferrochain-prompts` depends on `ferrochain-core`"), so `#[non_exhaustive]` makes every struct literal E0639. Correct form is `FerrochainError::new(Component::Tmpl, Category::Val, RetryHint::Never, "E-TMPL-003", …)` — `RetryHint::Never` per error-taxonomy for both E-TMPL-002 and E-TMPL-003. FIX-BURST-269 and FIX-BURST-270 edited these exact blocks for casing and left the constructor form stale. TD-VSDD-060 failure at the touched site. **Third independent confirmation** that the `FerrochainError` sweep was incomplete (after slice A F-P175-A25 and slice B1 F-P175-B106).

---

### F-P175-B208 — BC-2.18.002 INV-2 and VP-2.18.002-A: severity-ordering inversion, silent fail-open

**Severity:** HIGH
**Files:** `BC-2.18.002`, VP-2.18.002-A
**Owner:** architect

**Defect:** INV-2 declares *"TrustLevel severity ordering: `Untrusted > UserInput > Trusted`. The highest-severity TrustLevel wins."* VP-2.18.002-A requires *"exactly the maximum-severity TrustLevel."* But every declaration (ADR-015 and `interface-definitions.md`) is `pub enum TrustLevel { Untrusted, UserInput, Trusted }` with no `Ord`, no `PartialOrd`, and no `severity()` method — only `is_untrusted()`. Rust derives `Ord` in declaration order, so `Untrusted < UserInput < Trusted` is the derived ordering: an implementer adding `#[derive(Ord)]` and calling `.max()` — the literal reading of "maximum-severity" — gets `Trusted` as the aggregate for a slot containing an `Untrusted` variable. `interface-definitions.md` §ChatPromptTemplate makes this load-bearing: BC-2.18.004 PC1's `TrustLevel::Untrusted` in `highest_trust_level` drives the injection_guard fail-closed decision.

**Why it matters:** Silent fail-open on the injection guard for any slot whose aggregate is computed via standard Rust ordering.

---

### F-P175-B213 — `interface-definitions.md` §ChatPromptTemplate surface absent

**Severity:** HIGH
**File:** `interface-definitions.md` §ChatPromptTemplate and PromptValue Surface
**Owner:** product-owner

**Defect:** `PromptTemplate`, `MessagesPlaceholder`, `FewShotPromptTemplate`, and `MessageListVar` are entirely absent from the signature source of truth. Greps for `from_template`, `input_variables`, `MessagesPlaceholder`, `FewShotPromptTemplate`, `MessageListVar` return zero type or signature declarations in `interface-definitions.md`. The vacuum was filled by invention: BC-2.19.001 TV entries and VP-007's harness both make `input_variables` a public caller-supplied field, contradicting BC-2.18.001 PC3's accessor form `input_variables(&self) -> &[String]` and PC1's fallible constructors. This is the root cause of slice A's F-P175-A18.

**Extension:** Because VP-007 supplies `input_variables` independently of `template`, it can construct a `PromptTemplate` whose variable list is inconsistent with its template body — a state unreachable through PC1, violating BC-2.18.001 INV-2's purity/idempotence — so VP-007's round-trip property passes vacuously on an unconstructible value.

---

### F-P175-B218 — `MessageRole` is a phantom type

**Severity:** HIGH
**File:** `BC-2.18.005`
**Owner:** product-owner

**Defect:** `MessageRole` has 13 corpus hits, none a definition. `interface-definitions.md` uses it in the canonical `from_messages` signature but never declares `pub enum MessageRole`. `MessageRole::Ai` is never written anywhere, yet BC-2.18.005 PC4 and EC-005 require it (as does BC-2.18.003 TV-002). BC-2.18.005 is `red_gate: true`; its Red Gate test must compile against `MessageRole::System` — an undefined type.

---

### F-P175-B214 — BC-2.18.001 and BC-2.18.002: CAP-022's `Runnable` mandate uncovered

**Severity:** HIGH
**Files:** `BC-2.18.001`, `BC-2.18.002`
**Owner:** product-owner

**Defect:** CAP-022's H1 is *"PromptTemplate and ChatPromptTemplate **as Runnable**."* A grep for `Runnable` across all of the SS-18 subsystem returns 4 hits — all inside the quoted CAP-022 title string. Zero postconditions, invariants, edge cases, or test vectors specify the `Runnable` implementation: no `invoke`, `batch`, `stream`, associated types, or `.pipe()` semantics. LCEL composability is why SS-18 is in v1 scope (D21 ecosystem parity); without this, an implementer builds two structs that cannot be piped into a chat model.

---

### F-P175-B205 — BC-2.18.003 vs BC-2.18.001: strict-undefined contradiction

**Severity:** HIGH
**Files:** `BC-2.18.003` (PC3), `BC-2.18.001` (§Description)
**Owner:** product-owner

**Defect:** BC-2.18.001 §Description: *"There is no lenient mode; E-TMPL-003 is engine-neutral and not gated on any configuration flag (ADR-015 §Decision 4)."* BC-2.18.003 PC3: *"if required (default), returns `Err(E-TMPL-003)`; if optional, expands to zero messages"* — a configuration flag gating E-TMPL-003 plus an explicit lenient mode. BC-2.18.003 PC3 also violates DI-014 and the no-silent-empty rule. One of the three contracts must move.

---

### F-P175-B206 — BC-2.18.003 PC1/PC2: type-impossible variable channel and paper-fix

**Severity:** HIGH
**File:** `BC-2.18.003` (PC1, PC2)
**Owner:** product-owner

**Defect:** PC1/PC2 say the `vars` map supplies a `Vec<Message>` and derive trust from *"the `Vec<Message>` variable's declared `trust_level`"* — but `Vec<Message>` has no `trust_level`, and the render entry point takes `HashMap<String, TemplateVar>` whose `value` is a `String`, so a `Vec<Message>` cannot transit it. ADR-015 v1.4 introduced `MessageListVar { messages, trust_level }` precisely for this. BC-2.18.003 never mentions `MessageListVar`, while its v1.1 changelog claims *"explicit ADR-015-conformant trust derivation."* TD-VSDD-059 paper-fix.

---

### F-P175-B207 — BC-2.18.003: phantom field `required: bool` and phantom constructor

**Severity:** HIGH
**Files:** `BC-2.18.003` (PC3, PC1, TV-003, EC-005)
**Owner:** product-owner + architect

**Defect:** `required: bool` is described as "the slot's setting" but `from_messages` takes 3-tuples `Vec<(MessageRole, &str, SlotTrustPolicy)>` with no `required` element and no placeholder-variable-name element. No `MessagesPlaceholder` or `FewShotPromptTemplate` constructor signature is declared anywhere in the corpus.

---

### F-P175-B212 — BC-2.18.003 and BC-2.18.005: changelog-asserted `input-hash` contradicts frontmatter

**Severity:** HIGH
**Files:** `BC-2.18.003`, `BC-2.18.005`, `BC-2.18.001`, `BC-2.18.002`
**Owner:** product-owner + devops-engineer (process-gap)

**Defect:** BC-2.18.003 v1.2 claims *"input-hash updated to `d2cc4f4`"* while frontmatter holds `352f3dd`. BC-2.18.005 v1.1 claims *"input-hash updated to `fa92953`"* while frontmatter holds `352f3dd`. All four BCs carry the same v1.0-era hash while their declared input ADR-015 has advanced v1.0 through v1.8 — including the v1.3 `TrustLevel` adjudication and v1.4 `MessageListVar` addition these BCs must consume. The only mechanical BC-vs-input drift detector reports "no drift" on a corpus that has drifted extensively.

**`[process-gap]`:** No hook validates that a changelog-asserted `input-hash` equals the frontmatter value. This manufactured the very coverage debt this slice repaid.

---

### F-P175-B211 — BC-2.18.002: retired `ProvenanceTag` residue after claimed migration

**Severity:** HIGH
**Files:** `BC-2.18.002` (§Architecture Anchors, §Traceability)
**Owner:** product-owner + architect

**Defect:** Retired `ProvenanceTag` references survive at two sites in the document whose v1.2 changelog claims *"Complete TrustLevel migration residue from v1.1 partial propagation."* ADR-015 §Decision 3 retired `ProvenanceTag` explicitly: *"`ProvenanceTag` … and template-composition trust serve two distinct axes and MUST NOT be conflated."* Contradicts INV-2 in the same document. ADR-015 §PO Handoffs falsely lists this as RESOLVED.

---

### F-P175-B210 — BC-2.18.003 and BC-2.18.002: phantom module anchors

**Severity:** HIGH
**Files:** `BC-2.18.003`, `BC-2.18.002`
**Owner:** architect (module-decomposition resolution) then product-owner

**Defect:** The SS-18 registry has exactly four modules (`prompts::template`, `prompts::chat_template`, `prompts::few_shot`, `prompts::injection_guard`) in both `module-decomposition.md` and `purity-boundary-map.md`. BC-2.18.003 cites `prompts::messages_placeholder` at two sites, attributing it to `module-decomposition.md` which does not contain it — a corpus grep returns only those two lines. BC-2.18.002 cites `prompts::prompt_value` similarly (appears only there plus `entities-graph.md`). `module-decomposition.md` explicitly assigns `MessagesPlaceholder` and `PromptValue` to `prompts::chat_template`.

---

### F-P175-B217 — BC-2.18.001 PC5/EC-003/TV-003: engine-conditional semantics unresolved

**Severity:** HIGH
**File:** `BC-2.18.001` (PC5, EC-003, TV-003)
**Owner:** architect then product-owner

**Defect:** PC5 states unqualified that `{{`/`}}` render as literal braces and TV-003 asserts `"Curly: {{not_a_var}}"` → `Ok("Curly: {not_a_var}")`. Under jinja2, `{{not_a_var}}` is substitution syntax, and ADR-015 §Decision 4 mandates `strict_undefined = true` engine-neutrally — so TV-003 asserts `Ok` where the universal contract mandates `Err(E-TMPL-003)`. PC6 carries the *"in f-string mode"* qualifier while PC5 does not. Engine selection is a Cargo feature with no per-template selector; feature unification means any dependency enabling `jinja2` silently flips escape semantics workspace-wide — security-relevant given ADR-015 §Threat Model R12.

---

### F-P175-B204 — BC-2.18.001 INV-1: self-contradictory; missing error code for malformed template

**Severity:** HIGH
**File:** `BC-2.18.001` (INV-1)
**Owner:** product-owner

**Defect:** INV-1 is self-contradictory ("infallible only if" vs PC1's unconditional `Result`). It mandates a construction-time `Err` for unparseable templates with no error code in existence — TMPL has only E-TMPL-001/002/003; a corpus grep for `E-TMPL-004`, `malformed template`, and `unbalanced` returns this line as the sole SS-18 hit. No EC and no TV for unbalanced braces (`"Hello, {name"`, `"a } b"`, `"{}"`). Likely outcome without explicit error handling: `unwrap()`/`panic!` (DI-008/NO-UNWRAP violation) or silent acceptance. Must mint `E-TMPL-004 MalformedTemplate` with ECs and TVs.

---

### F-P175-B215 — BC-2.18.001 INV-4/PC1: `.partial()` builder unspecified; INV-4 self-contradicts

**Severity:** HIGH
**File:** `BC-2.18.001` (INV-4, PC1)
**Owner:** product-owner

**Defect:** `.partial()` builder is mandated by `module-decomposition.md`, `purity-boundary-map.md`, and CAP-022, specified by no postcondition. INV-4 self-contradicts: *"immutable once set at construction"* vs *"builder returns a new `PromptTemplate` value."* Return type (`Self` vs `Result<Self, _>`) and interaction with PC3 are undefined.

---

### F-P175-B216 — BC-2.18.001 §Related BCs: false dependency claim

**Severity:** HIGH
**File:** `BC-2.18.001` (§Related BCs)
**Owner:** product-owner

**Defect:** §Related BCs claims E-TMPL-002 is *"a precondition for BC-2.18.001's construction postconditions."* E-TMPL-002 is a `ChatPromptTemplate::from_messages` slot-policy error. `PromptTemplate` is single-message with no slots, no `MessageRole`, and no `SlotTrustPolicy`. The claimed dependency is a category error.

---

### F-P175-B209 — BC-2.18.002 and BC-2.18.003: phantom constructors and raw-string message content

**Severity:** HIGH
**Files:** `BC-2.18.002` (TV-001, TV-004), `BC-2.18.003` (TV-001, TV-002)
**Owner:** product-owner

**Defect:** Test vectors use phantom constructors `System(...)`, `Human(...)`, `Ai(...)` — no such symbols in the corpus; canonical is the 3-tuple form used correctly in BC-2.18.005 TV-002. Raw-string message content where BC-2.01.001 mandates typed `MessageContent`/`Vec<ContentBlock>`. BC-2.18.002 TV-001 also omits the mandatory `SlotTrustPolicy` element while asserting `policy: TrustRequired`/`TrustAll` in its output — asserting a value the input never supplied.

---

### F-P175-B219 — BC-2.18.005 §Description and VP-2.18.005-B: paper-proof for system-role guard

**Severity:** HIGH
**Files:** `BC-2.18.005` (§Description), VP-2.18.005-B
**Owner:** product-owner + architect

**Defect:** Claims a *"compile-time architectural invariant"* and a *"type-level invariant"*, but `from_messages(Vec<(MessageRole, &str, SlotTrustPolicy)>)` makes `(MessageRole::System, _, TrustAll)` a well-typed value rejected at **runtime** via `Err`. Nothing makes the illegal pair unrepresentable at the type level. The "type-level argument" leg discharges to nothing, leaving a non-exhaustive unit test presenting as a structural guarantee. VP-2.18.005-A compounds this: *"for all … always `Err`"* with method *"unit test — exhaustive"* — exhaustive testing of a finite set is not a type-level invariant.

---

## Slice B2 MED Findings (11)

`F-P175-B220` (phantom default: BC-2.18.002 asserts `AiMessage` defaults to `TrustAll`, but every `from_messages` tuple requires an explicit `SlotTrustPolicy` element — no code path where a default applies; owner: product-owner). `F-P175-B221` (BC-2.18.002 PC3 restricts `None` trust to "template-literal slots," contradicted by its own TV-001 and by ADR-015's correct disjunction "or all substituted variables carried `None` trust_level"; owner: product-owner). `F-P175-B222` (BC-2.18.003 missing DI-014 anchor though PC8/PC3/EC-004/EC-005 restate it verbatim; siblings BC-2.18.001 and BC-2.18.005 both carry the anchor; BC-INDEX mirrors the gap; owner: product-owner). `F-P175-B223` (`error-taxonomy.md` §TMPL documents only one E-TMPL-003 raise site — `PromptTemplate::format` — but BC-2.18.003 PC3/EC-005 and `interface-definitions.md` raise it from `format_messages` too; owner: product-owner). `F-P175-B224` (TD-VSDD-091 volatile version pins authored 2026-07-25 — after ratification, not grandfathered — BC-2.18.001 and BC-2.18.005 each carry `FIX-BURST-270/ADR-010 v1.9` plus `ADR-010 v1.9 Direction B`; BC-2.18.005 also carries `ADR-015 v1.5`; BC-2.18.003 shows the correct de-pinned form; **`[process-gap]`:** records-lint L9 did not gate these; owner: product-owner for BCs, devops-engineer for linter gap). `F-P175-B225` (ADR-015 §Traceability mis-anchors DI-008 as an "untrusted-content invariant"; DI-008 is the Library Constructor Result Contract — all four BCs anchor it correctly, ADR-015 is the outlier and adds a false traceability claim; owner: architect). `F-P175-B226` (ADR-015 §Template Engines says "Three template engines" above a two-engine table; mustache residue dropped in v1.1 without updating the count; owner: architect). `F-P175-B227` (retired spelling `AIMessage` at two ADR-015 sites in the exact passage BC-2.18.005 PC4/EC-005 depends on; canonical is `AiMessage`; owner: architect). `F-P175-B228` (root cause of F-P175-B203 upstream: both ADR-015 §Decision 3 code sketches construct `FerrochainError` by 4-field literal; v1.7 edited those exact lines for casing without fixing the constructor form, then it propagated into BC-2.18.001 PC4 and BC-2.18.005 PC1 — TD-VSDD-060; owner: architect). `F-P175-B229` (`TrustLevel` derive divergence: ADR-015 has `Copy` + `#[cfg_attr(kani, derive(kani::Arbitrary))]`, `interface-definitions.md` has neither; the `kani::Arbitrary` omission is load-bearing for VP-006 Kani Phase 1; neither carries `#[non_exhaustive]` on a public enum, unlike sibling `PromptValue`/`MessageProvenance`; owner: architect + product-owner). `F-P175-B230` (retired `ProvenanceTag` language surviving in `test-vectors.md` SS-18 row: *"TrustRequired slot + Untrusted tag"*; ADR-015 §PO Handoffs lists the migration RESOLVED without covering test-vectors; owner: product-owner).

## Slice B2 LOW and OBS Findings (4)

`F-P175-B231` (LOW — BC-2.18.001 PC4 message uses `'{var_name}'` while error-taxonomy convention is `'<var_name>'` — ambiguous in a BC whose subject is `{...}` substitution syntax; owner: product-owner). `F-P175-B232` (LOW — TV-006 calls `input_variables()` directly on `from_template`'s `Result` without `?` or match — a type error; owner: product-owner). `F-P175-B233` (OBS — verification asymmetry: BC-2.18.005 is `red_gate: true` and *"the first layer"* of the security model, but only the second layer has a Kani VP (VP-006 → BC-2.18.004); the construction-time guard is trivially Kani-provable as a finite `MessageRole × SlotTrustPolicy` product over pure-core code; architect should seed a VP-INDEX entry; owner: architect). `F-P175-B234` (OBS / **`[process-gap]`** — these four BC files were carried as "covered" across multiple converged passes on grep-for-known-defect-shapes; 19 HIGH-or-above findings were invisible to shape-matching; the adversarial-review convergence-state schema must distinguish `probe` from `full-read` per artifact and refuse to advance the 3-CLEAN streak on probe-only coverage; owner: devops-engineer for schema enforcement).

## Slice B2 Synthesis

Three patterns recur across B2's HIGH findings and match patterns in other slices:

1. **TD-VSDD-060 failures at the touched line** (B203, B211, B228): a burst edited a line for one attribute and left a second stale attribute on the same line.
2. **TD-VSDD-059 paper-fixes** (B206, B211, B212): a changelog asserts a closure whose referent is absent from the body.
3. **§Related BCs asserting coverage the cited BC does not provide** (B201, B202, B216): this section is validated by no hook and is a systematic source of false assurance in SS-18.

---

## Slice B1 Perimeter and Verified-Clean Axes

Files covered (all read line-by-line in full): `BC-2.15.004`, `BC-2.15.006`, `BC-2.16.002`, `BC-2.17.002`. Closes the remainder of the pattern-probe coverage debt.

**Verified clean:** No subsystem mis-anchor — SS-15 = Long-Horizon Memory, SS-16 = Tool Retry + Circuit Breaker, SS-17 = Formal Verification Pipeline, all correct per ARCH-INDEX §Subsystem Registry. Note correction: my B1 dispatch instructed corroboration against `L2-INDEX.md` for the subsystem registry, but that file contains no `SS-NN` tokens — the registry lives in `ARCH-INDEX.md`. The slice self-corrected. Recorded below in orchestrator self-attributed defects.

## Slice B1 Totals

**29 findings: 2 CRIT / 11 HIGH / 10 MED / 6 LOW-OBS**

---

## Slice B1 CRIT Findings (2)

### F-P175-B101 — BC-2.15.006 PC1: caller-controlled cross-tenant read path

**Severity:** CRIT
**File:** `BC-2.15.006` (PC1, EC-001, TV-001)
**Owner:** architect (namespace↔MemoryScope bridge adjudication) + product-owner (PC1 rewrite + authorization precondition)

**Security class:** consider security-reviewer triage alongside adjudication.

**Defect:** PC1 calls `MemoryStore::memory_get(MemoryScope::App(spec.namespace), &spec.key)`, placing a caller-supplied content namespace into the `app_id` tenancy partition key. `MemoryScope::App(app_id)` means *"entries visible to all callers within the same `app_id`"* per BC-2.15.002 §Scope Definitions, and BC-2.15.002 §Invariants NE-12 requires scope fields to *"flow from the `MemoryScope` enum through to the SQL WHERE clause without collapsing or merging."* The values PC1 actually passes are content namespaces (`namespace: "agent"`, `key: "MEMORY.md"`, `ns: "agent"`, `key: "SOUL.md"`). PC1 has no authorization precondition — contrast BC-2.15.004 Precondition 3 which states scope checks apply. BC-2.15.002 confirms *"the store itself trusts the caller-provided scope."* `E-MEMORY-003 ScopeAccessDenied` is anchored to `memory_set` only, so reads rely on isolation-by-invisibility. A caller setting `namespace: "<other-tenant-app-id>"` reads that tenant's app-scoped memory straight into their own system prompt.

**Either way PC1 is wrong:** if `App(app_id)` is the intended scope, the call is malformed — TV-001/TV-004/EC-005 all return `Ok(None)`, making the happy paths unachievable. If content namespaces map directly to `app_id`, the tenancy model is broken. The write side has no scope tier at all (BC-2.15.005 Precondition 2 takes bare `namespace: String`), and nothing establishes the write-namespace → read-`MemoryScope` correspondence PC1 assumes.

---

### F-P175-B102 — BC-2.15.004 PC1–PC5: `SkillStore` has no scope parameter

**Severity:** CRIT
**File:** `BC-2.15.004` (PC1–PC5, Precondition 3, EC-004)
**Owner:** architect (SkillStore→MemoryScope binding adjudication) + product-owner

**Security class:** consider security-reviewer triage.

**Defect:** `SkillStore` has no scope parameter on any method — `load_skill`, `list_skills`, `skill_exists` are identical in both `interface-definitions.md` and ADR-012. `interface-definitions.md` states MemoryStore has a *"scope parameter on every method."* The BC never states which scope tier skill reads use and conflates namespace with scope in Precondition 3. Three blocking consequences: (1) `load_skill` is unimplementable — no scope input and no specified derivation; (2) under BC-2.15.002 EC-001 the default scope is `Session(current_session_id)`, so every skill written outside the current session returns `Ok(None)`, causing TV-001, TV-005, TV-007, and EC-005 to fail; (3) `E-MEMORY-004 NoScopeContext` — which `interface-definitions.md` raises when *"no session context is derivable and the caller omitted an explicit scope"* — appears nowhere in BC-2.15.004; PC5's only error class is storage-layer failure and EC-004's only code is `E-MEMORY-008`. A P1 Wave-1 read path with an unenumerated raise condition.

---

## Slice B1 HIGH Findings (11)

### F-P175-B105 — All four BCs and VP-INDEX: all nine cited VP IDs are phantoms; cargo-fuzz VPs absent

**Severity:** HIGH
**Files:** `BC-2.15.004`, `BC-2.15.006`, `BC-2.16.002`, `BC-2.17.002`, VP-INDEX
**Owner:** architect then product-owner

**Defect:** All nine VP IDs cited across the four BCs are absent from VP-INDEX, which declares itself *"Source of truth for VP IDs, modules, tools, phases, and counts."* Phantom IDs: `VP-SKILL-01/02` (BC-2.15.004), `VP-CTX-01/02` (BC-2.15.006), `VP-BC216002-01/02`, `VP-BC217002-01/02/03`. Each appears only inside its citing BC. VP-INDEX records `| fuzz | 0 |` while BC-2.17.002 mandates two fuzz targets as a v1-convergence gate per CAP-019 *"Formal Verification Pipeline (Kani + cargo-fuzz)."* `verification-architecture.md` has a `## Fuzzing Targets (BC-2.17.002)` table with no VP ID column, so neither target has a VP identity and the entire cargo-fuzz half of CAP-019 is invisible to the VP arithmetic invariant.

---

### F-P175-B106 — Five sites across four BCs: `FerrochainError` struct-literal sweep incomplete

**Severity:** HIGH
**Files:** `BC-2.15.004` (EC-004), `BC-2.15.006` (EC-003, TV-006), `BC-2.16.002` (PC5), `BC-2.17.002` (EC-002)
**Owner:** product-owner

**Defect:** Five literal sites across four BCs: BC-2.15.004 EC-004 (3 of 6 fields), BC-2.15.006 EC-003 (1 of 6) and TV-006 (1 of 6), BC-2.16.002 PC5 (5 of 6), BC-2.17.002 EC-002 (2 of 6). None compile — E0639 outside `ferrochain-core`, E0063 inside (missing `source` field). All five also use ALL-CAPS enum tokens in formal postconditions, contradicting ADR-010 §Casing Rules PascalCase canon. Changelogs for BC-2.15.004 v1.2, BC-2.16.002 v1.2, and BC-2.17.002 v1.3 all claim closure of a *"Gate #33 Form 3 wrapper-form sweep"* — that sweep added `message:` fields to invalid literals without converting them to `FerrochainError::new(...)`. TD-VSDD-059 paper-fix. BC-2.15.004 drops `retry_hint`, which error-taxonomy pins to `Maybe` for E-MEMORY-008.

---

### F-P175-B107 — BC-2.15.004 and BC-2.15.006: D23 SS-15 Wave-1 promotion residue

**Severity:** HIGH
**Files:** `BC-2.15.004`, `BC-2.15.006`
**Owner:** product-owner + business-analyst + state-manager

**Defect:** Both BCs still declare `wave: 2` in frontmatter, §Traceability, and VP-table phase cells, while ARCH-INDEX §Subsystem Registry registers SS-15 as Wave 1 spanning BC-2.15.001–006 with no carve-out. BC-INDEX explicitly certifies *"BC-2.15.004/005/006 reverse-contamination check clean"* — the F-P159-01 burst checked only for reverse contamination and never for the forward gap. Result: `ferrochain-memory` ships Wave 1 while `SkillStore` trait and `ContextMutationConfig` loading inside it are scheduled Wave 2. Correctly swept sibling BC-2.16.002 shows the intended form. Also CAP-020 lacks the wave marker its sibling CAP-018 carries. **This is the sharpest instance of the label-not-value verification pattern** (see pass-174 §Structural Finding).

---

### F-P175-B103 — BC-2.17.002 PC1/EC-001/TV-003: phantom error type `DeserializationError`

**Severity:** HIGH
**File:** `BC-2.17.002` (PC1, EC-001, TV-003)
**Owner:** product-owner

**Defect:** `DeserializationError` has exactly 3 corpus sites, all inside this BC. Contradicts ADR-010 §Universal Return Type: *"All public functions return `Result<T, FerrochainError>`."* No error-taxonomy code covers malformed-msgpack deserialization (E-CHKPT-003 is DURABILITY/restore; E-CHKPT-006 is INTERNAL/interrupt_value; E-SRLZ-001/002 are allowlist codes). The fuzz oracle for Target 1 asserts against a nonexistent type. Sibling EC-002 carries a real code, confirming this is drift not style.

---

### F-P175-B104 — BC-2.17.002 PC2/EC-002: phantom type `GraphDefinition`

**Severity:** HIGH
**File:** `BC-2.17.002` (PC2, EC-002)
**Owner:** product-owner

**Defect:** `GraphDefinition` has 3 corpus sites, all in this BC. The canonical type is `GraphConfig`, used throughout `interface-definitions.md` and in `verification-architecture.md`'s own fuzz-target row for this exact BC. Because BC supersedes architecture docs for contract semantics, the phantom is currently authoritative for the Phase-6 fuzz harness.

---

### F-P175-B108 — BC-2.16.002: `global_limit` counting unit specified three incompatible ways

**Severity:** HIGH
**File:** `BC-2.16.002` (§Description, PC5, PC6, EC-001, TV-003)
**Owner:** product-owner

**Defect:** Three incompatible counting units: "retry budget" (§Description, PC5 message, error-taxonomy); "8 total failures" (PC6, EC-001, TV-003); and sibling BC-2.16.001 counts attempts. For 3 tools each failing once: retries = 0, attempts = 3, failures = 3 — the three readings halt at materially different points under `global_limit = Some(8)`. This is exactly the termination bound FM-012 (Tool-Retry Loops Forever), named in this BC's own §Traceability, exists to close. Two implementers produce two different combinators, both passing tests.

---

### F-P175-B109 — BC-2.16.002 PC1/EC-002/TV-001: forbidden deferral and three-strength contradiction

**Severity:** HIGH
**File:** `BC-2.16.002` (PC1, EC-002, TV-001, VP anchor)
**Owner:** product-owner

**Defect:** PC1 contains *"(or another specific finite value set by the architect…)"* — a forbidden deferral (CLAUDE.md Canonical Principle Rule 6 names this pattern verbatim). The value 10 is already chosen in the same sentence. PC1/EC-002/TV-001 also specify the property at three incompatible strengths: `Some(10)` (PC1/EC-002), any `n >= 3` (TV-001), merely `Some(_)` (the VP). No single test satisfies all three; EC-002's *"(or the documented default)"* hedge makes it non-assertable.

---

### F-P175-B110 — BC-2.16.002 PC1: `NonZeroU32::new(10).unwrap()` mandated in library code

**Severity:** HIGH
**File:** `BC-2.16.002` (PC1, EC-004)
**Owner:** product-owner

**Defect:** PC1 mandates `NonZeroU32::new(10).unwrap()` inside `impl Default for RetryPolicy` — non-test library code in `ferrochain-core`. Direct NO-UNWRAP violation written into a postcondition. The same document's §Invariants declares *"No `assert!` or `if limit == 0 { panic!(...) }` is needed or permitted in library code (per DI-008)."* Needs a non-panicking const form such as `const DEFAULT_LIMIT: NonZeroU32 = unsafe { NonZeroU32::new_unchecked(10) }` with a safety comment.

---

### F-P175-B111 — BC-2.15.004 §Invariants: registration invariant with no registration operation

**Severity:** HIGH
**File:** `BC-2.15.004` (§Invariants)
**Owner:** product-owner

**Defect:** An invariant requires surfacing an error at *"registration time"* for skill name collisions, but no registration operation exists — `SkillStore` has exactly 3 read methods; BC-2.15.005 governs namespace writes only. No error code exists for the condition. PC2's *"all registered `SkillDescriptor` entries"* presupposes a registry that PC4 contradicts (*"no in-process cache"*; skills are *"ordinary KV entries"*). Same shape as the previously-shipped fabricated `DuplicateRegistration` panic.

---

### F-P175-B112 — BC-2.15.006 PC1/PC2/TV-001: `memory_get` returns `Option<Value>` but postcondition prepends text

**Severity:** HIGH
**File:** `BC-2.15.006` (PC1, PC2, TV-001)
**Owner:** product-owner

**Defect:** `memory_get` returns `Option<Value>` (`serde_json::Value`) but PC2 prepends text. The `Value`→`String` projection is unspecified. `to_string()` yields `"You are a helpful agent."` with quote characters (TV-001 fails); `as_str()` returns `None` for non-string JSON with no specified behavior — not an error per EC-003. A corrupted or wrong-typed entry silently vanishes from the system prompt with no error and no log. Also leaves VP-CTX-02's cache-key bytes underspecified, so two implementations compute different keys.

---

### F-P175-B113 — BC-2.17.002: false closure on Module field and missing fuzz module registry entry

**Severity:** HIGH
**File:** `BC-2.17.002` (§Changelog v1.2, §Traceability Module)
**Owner:** architect + product-owner

**Defect:** v1.2 claims the Module field was *"resolved from placeholder to `fuzz/` per module-decomposition.md."* `module-decomposition.md` contains no `fuzz` module row — only two unrelated "fuzzy" substring hits. ARCH-INDEX §Subsystem Registry SS-17 crate list has no fuzz crate. Also `fuzz/` is a directory path, not the `crate::module` canonical form — siblings in the same perimeter use the correct form. The SS-17 fuzz harnesses have no registered module home, which is why F-P175-B105's missing fuzz VP rows went unnoticed: no module row for the coverage matrix to hang them on. Three passes accepted this closure claim.

---

## Slice B1 MED Findings (10)

`F-P175-B114` (BC-2.15.004 PC1 forbids returning an empty string for not-found, but natural `Value`→`String` implementations are all either banned by NO-UNWRAP, forbidden by PC1, or wrong in type — no valid third path is specified; owner: product-owner). `F-P175-B115` (test-vectors counts 7 TVs for BC-2.15.004; actual is 8 — the v1.1 fix that added TV-008 never swept the test-vectors inventory; verified not systemic: the other three perimeter BCs match exactly; owner: product-owner + state-manager). `F-P175-B116` (BC-2.16.002 Module field holds a crate name `ferrochain-core` instead of `core::retry`; the F-P96-01 closure picked the crate column rather than the module identifier — same false-resolution class as B113; owner: architect). `F-P175-B117` (the entire SS-16 public type surface is absent from `interface-definitions.md` — no `RetryPolicy`, `ToolRetryPolicy`, `CircuitBreaker`, `global_limit`, `unlimited()`; SS-16 is Wave 1 / P1 and `core::retry` is the shared combinator provider crates and graph both route through; its absence is why F-P175-B106/B109/B110 and F-P175-B124 exist — the BC's inline sketches are the only signature authority; owner: architect). `F-P175-B118` (`#[non_exhaustive]` not asserted on 5 public API types — `SkillDescriptor`, `ContextSourceSpec`, `ContextMutationConfig`, `RetryPolicy`, `ToolRetryPolicy`; upstream declarations are bare `pub struct`; `ContextMutationConfig` hangs off `RunnableConfig` and `RetryPolicy` is a provider-routed config struct — exactly the named class; post-1.0 field addition becomes breaking under `cargo semver-checks`; owner: architect then product-owner). `F-P175-B119` (BC-2.15.006 PC2/EC-001/TV-002 silently skip absent context sources with no observability — SOUL.md and MEMORY.md are the sources, so a typo'd key, wrong namespace, or the B101 scope mismatch all manifest as the agent silently running with no persona, indistinguishable from correct operation; needs a structured tracing emission + SAP-1 `observability.md` catalog row; owner: product-owner + devops-engineer). `F-P175-B120` (BC-2.17.002 §Invariants requires pinning the nightly fuzz toolchain in `rust-toolchain.toml`, contradicting CLAUDE.md's single-stable-channel MSRV pin; one `channel` key cannot be both; correct mechanism — separate `fuzz/rust-toolchain.toml` or a nightly CI pin — is unspecified; owner: architect then product-owner). `F-P175-B121` (BC-2.17.002 PC2 mandates the fuzzer *"must reach all three BSP super-step paths"* but PC4 and the VP gate only on *"10,000 corpus inputs without new crash findings"* — a harness whose `Arbitrary` never generates an interrupt or empty super-step passes while covering 1 of 3 paths; PC5 makes the gate blocking; needs a runtime-computed per-path coverage assertion; owner: product-owner + devops-engineer). `F-P175-B122` (BC-2.16.002 Precondition 1 and H1 "All Retry Policies" extend the contract to `ToolRetryPolicy`, which has no `global_limit` field, so no postcondition governs it; the overreach propagates into BC-INDEX; owner: product-owner). `F-P175-B123` (§Invariants NE-09 enforcement is an unnamed "CI contract test" — no job, xtask, or just recipe named; the only candidate assertion is a phantom VP that asserts only `Some(_)`; contrast ADR-010 which names `cargo xtask deny-anyhow-in-lib` concretely; owner: product-owner + devops-engineer).

## Slice B1 LOW-OBS Findings (6)

`F-P175-B124` (LOW — BC-2.16.002 TV-005 uses `3_NonZeroU32` — not valid Rust syntax; `NonZeroU32` is not a primitive type suffix; uncompilable; owner: product-owner). `F-P175-B125` (LOW — BC-2.15.006 PC1 moves `spec.namespace` out of a borrow while `&spec.key` in the same call proves the borrow is live — E0507; needs `.clone()`; same defect in §Architecture Anchors; owner: product-owner). `F-P175-B126` (LOW — BC-2.17.002 frontmatter `wave: Phase-6` — a phase string in an integer field; ARCH-INDEX expresses it as `6`; siblings use integers; breaks numeric wave sorting; owner: state-manager). `F-P175-B127` (LOW — BC-2.15.004 and BC-2.15.006 VP-table Phase column holds `Wave 2` in 4 cells; BC-INDEX records the corresponding correction for the SS-15 trio — 004 and 006 are the un-swept remainder; distinct column from B107; owner: state-manager). `F-P175-B128` (LOW — TD-VSDD-091 volatile version pins in all four changelogs — `error-taxonomy.md v1.18`, `interface-definitions.md v2.39`, `module-decomposition.md v1.21`, `module-decomposition.md v1.10` ×2; all predate or coincide with the 2026-07-24 ratification and records-lint L9 grandfathers them; flagged so the grandfathering is a recorded decision rather than an oversight; fix at next touch; owner: respective spec owners). `F-P175-B129` (OBS **`[process-gap]`** — ADR-012's §Changelog carries a literal TD-VSDD-091 violation: *"`PO to propagate rename to BC-2.15.006 (lines ~69, ~150) and capabilities-p1-p2.md (~line 111)`"*; the cited references have already decayed from their original locations, demonstrating exactly what TD-VSDD-091 exists to prevent; L9 grandfathering leaves this class alive in highest-authority documents; owner: architect for ADR-012 changelog; devops-engineer to consider an L9 audit sweep over ADR changelogs).

## Slice B1 Synthesis

Three findings trace to closures that verified the **label** of a change rather than its **value** — consistent with pass-174 §Structural Finding: (1) F-P175-B107: a certification of "BC-2.15.004/005/006 clean" produced by running the check in the wrong direction; (2) F-P175-B113: a Module closure verified the claimed derivation source rather than the module value itself; (3) F-P175-B116: the F-P96-01 closure picked the wrong column (crate name vs module path). This pattern spans slices B1, B2, and A, confirming it is structural and not incident-specific.

---

## Slice D1 Perimeter and Verified-Clean Axes

Corpus-wide sweeps and census integrity. Not bounded to specific files; D1 operated globally.

**Sweep totals (verified results — the zeros matter as much as the hits):**

| Target | Matches | Files |
|--------|---------|-------|
| `FerrochainError {` | 310 | 89 |
| `FerrochainError::new(` | 11 | 5 |
| `dyn Tool` | 24 | 6 |
| `VectorStoreRetriever<` | 9 | 9 |
| `as_retriever` | 41 | 17 |
| Hyphenated module forms | 105 | 37 |
| `ADR-NNN vN.N` version pins | 131 | ~60 |

**Confirmed-extinct phantoms:** `PathGuard::check` — 6 matches, all in changelog records, ZERO live-body; `Category::VALIDATION` — 11 hits, all changelog, ZERO live-body; `ActionRisk::Critical` — 2 hits, both changelog; `DuplicateRegistration` — ZERO corpus-wide; `ZeroNormEmbedding` — ZERO corpus-wide.

**One live-body phantom survivor:** `ToolCallPreview.tool` — 2 hits, 1 live-body (ADR-005 §Repudiated Entries errata list, see F-P175-D107).

**Census confirmed exact:** BC count 129 = 51/75/3 (verified three ways: H1 headings, `priority:` frontmatter counts, BC-INDEX catalog rows). Crate roster 21 (ARCH-INDEX rows self-sum 9+2+1+2+1+3+2+1). Error codes 109. VP count 13 with correct tool arithmetic (Kani 9 + proptest 2 + integration 2). SAP-1 `event_type` coverage CLEAN — 11 distinct values, all 11 cataloged, ZERO orphans; `crates/` does not exist yet. Module count 83 total / 77 tiered / 6 exempt — `module-decomposition.md`'s 71/69/2 is the outlier (see F-P175-D110/D111).

**Dual-copy `module-criticality.md` — CLEAN, not drift.** The `prd-supplements/` copy carries `status: superseded`, `superseded_by:`, and a banner *"SUPERSEDED — DO NOT USE FOR IMPLEMENTATION DECISIONS."* The authoritative copy is `specs/module-criticality.md` v2.6. No finding — do not dispatch on it.

## Slice D1 Totals

**17 findings: 2 CRIT / 7 HIGH (includes D116 reclassified per Adjudication 3) / 6 MED / 1 LOW / 1 OBS**

---

## Slice D1 Orchestrator Adjudications (in-session, recorded for durability)

### D1 Adjudication 1 — `FerrochainError` literal sweep boundary

Of 310 `FerrochainError {` occurrences across 89 files, the overwhelming majority are the documented abbreviated-designator convention (Gate #33 Form 3, e.g. `Err(FerrochainError { ... })` with ellipsis), and exactly one site is a hard compile failure.

**Ruling:** The fix scope is FULL-FORM NAMED-FIELD literals only — NOT all 310. A blanket sweep would churn 89 files to no benefit and is rejected. Severity gradient: explicit named-field literals missing required fields = HIGH/CRIT (they read as authoritative and get transcribed); 1–2-field abbreviated designators = MED at most, and acceptable where the corpus convention is established. This supersedes any implication in slices A, B1, or B2 that all literal sites are defects.

### D1 Adjudication 2 — TD-VSDD-091 changelog-vs-live-body scope

**Ruling:** Both changelog and live-body are in scope for TD-VSDD-091, but they are separated by ratification date, not by register. Text authored on or after 2026-07-24 must be de-pinned wherever it appears — changelog included; that is what "not grandfathered" means, and the `ADR-010 v1.9` cluster of 23 post-ratification sites falls squarely inside it. Text predating ratification stays grandfathered in changelogs (rewriting a historical entry destroys the audit trail), but must be de-pinned in live body on next touch. Owner: devops-engineer to encode the date boundary in records-lint L9 so this is mechanically enforced rather than adjudicated per-burst. Note the self-demonstrating case D1 found: a changelog entry recording a TD-VSDD-091 de-pin while itself citing a version pin.

### D1 Adjudication 3 — Test-vector census: D-39 confirmed, the "675" closure was FALSE

D1 reported that my dispatch brief's `675 = 664 + 11` has no corpus provenance and that four independent sites agree on `674 = 663 + 11`. I verified ground truth directly:

- `BC-2.21.003` is at v1.8 and genuinely carries both EC-006 and TV-006 (verified present in its §Edge Cases and §Canonical Test Vectors tables — the `f32::MAX` overflow vector with the `!norm.is_finite()` guard).
- BC-2.21.003's own v1.7 changelog states verbatim: *"TV census: 6 canonical (was 5) + 0 GTV = 6 BC-local TVs; project total 675 (664 canonical + 11 GTV)."*
- `test-vectors.md`'s last changelog entry is v2.7 (*"Grand total 671→674 (663 canonical + 11 GTV)"*) and its total line still reads *"663 canonical … + 11 golden … = 674 total vectors."* The +1 for TV-006 was never applied.

**Ruling:** Promote F-P175-D116 to HIGH. D-39 stands: per CLAUDE.md §Source-of-Truth Precedence the BC governs its own contract content and the registry derives from it, so the correct total is 675 = 664 + 11. `test-vectors.md` must be corrected upward. STATE.md's record that test-vectors was bumped to v2.8/675 is a **FALSE CLOSURE** — record it as such, noting that this false closure is in our own records on a decision I made as orchestrator. Also: check for a frontmatter `version:` vs last-changelog-entry mismatch in `test-vectors.md` (frontmatter may say 2.8 while the changelog tops out at 2.7 — a gate #28 violation). Fix direction is **upward to 675**, not downward. Owner: product-owner (registry correction + changelog), state-manager (STATE.md census + false-closure record).

---

## Slice D1 CRIT Findings (2)

### F-P175-D101 — `capabilities-p1-p2.md` §CAP-027/§CAP-028: stale `as_retriever` anchors

**Severity:** CRIT
**File:** `capabilities-p1-p2.md` (§CAP-027, §CAP-028)
**Owner:** business-analyst

**Defect:** The L2 capability anchors are stale on both `as_retriever` adjudications. Burst-277 propagated to the BCs, ADR-014, `api-surface.md`, and `interface-definitions.md` and skipped the domain spec entirely. Four independent contradictions: (1) `VectorStoreRetriever<'a>` lifetime parameter; (2) `&dyn VectorStore` borrowed vs `Arc<dyn VectorStore>` owned; (3) receiver `&self` vs `self: &Arc<Self>`; (4) infallible return vs `Result<…>`. Verbatim surviving text: *"Provide a concrete `Retriever` implementation (`VectorStoreRetriever<'a>` …) backed by a `&dyn VectorStore`"* and *"`as_retriever(&self) → VectorStoreRetriever<'_>` (concrete, non-opaque return)."* Also states `lambda_mult ∈ [0.0, 1.0]` as a domain constraint with no rejection semantics — silent on `Err(E-VS-003)`.

**Load-bearing mis-anchor:** BC-2.20.003 §Traceability names *"CAP-027 per capabilities-p1-p2.md §CAP-027"* and BC-2.21.001 names CAP-028. An implementer following the BC's own anchor pointer upstream lands on a signature that contradicts the BC in four dimensions and will not compile.

---

### F-P175-D104 — VP-008 §Proof Harness: `FerrochainError` literal has three compile errors

**Severity:** CRIT
**File:** `VP-008.md` (§Proof Harness)
**Owner:** architect

**Defect:** The proptest harness constructs `FerrochainError` with 4 of 6 fields — `retry_hint` and `source` omitted (E0063). `message: "…"` is `&'static str` where the field requires `String` (E0308). VP-INDEX assigns VP-008 to `ferrochain-core`, so `#[non_exhaustive]`/E0639 does not shield it — but E0063 fires unconditionally. This is the harness a test-writer transcribes verbatim in Phase 6; it cannot build. Confirms and extends slice A's F-P175-A25 with the precise compile-error analysis.

---

## Slice D1 HIGH Findings (7)

### F-P175-D107 — ADR-005 §Repudiated Entries: errata says "corrected above" but repudiated entries survive

**Severity:** HIGH
**File:** `ADR-005` (§Repudiated Entries)
**Owner:** architect

**Defect:** The §Repudiated Entries section states *"Corrected above"* while the repudiated list above it was never edited. All four repudiated entries survive verbatim, including the sole surviving `ToolCallPreview.tool` phantom in the corpus. D1 independently verified: `dyn Tool` appears in zero of BC-2.05.003, BC-2.05.004, BC-2.08.010 — the errata's content is correct but the correction was never applied to the body. Net effect: ADR-005 now simultaneously asserts *"4 live `dyn Tool` usage sites [list]"* and *"that list is wrong."* An implementer looking up which sites need `DynTool` is directed to a self-refuting document. TD-VSDD-059 paper-fix.

---

### F-P175-D102 — `module-decomposition.md`: `VectorStoreRetriever` ownership contradicts ADR-014

**Severity:** HIGH
**File:** `module-decomposition.md`
**Owner:** architect

**Defect:** The canonical module registry says `VectorStoreRetriever<'_>` wrapping `&dyn VectorStore`. ADR-014 §Decision 5 states: *"Holds `Arc<dyn VectorStore>` (not a borrowed reference) — making `VectorStoreRetriever` a `'static` type."* Two architect-owned files, same type, opposite ownership models. All module anchors resolve against this registry, so every downstream consumer of `module-decomposition.md` gets the wrong model.

---

### F-P175-D103 — ADR-014: stale open obligation asserting a false claim about current BC content

**Severity:** HIGH
**File:** `ADR-014`
**Owner:** architect

**Defect:** ADR-014 carries an open obligation: *"BC-2.20.003 PC-2 currently states infallible `-> VectorStoreRetriever<'_>`; that is incorrect — Wave C PO correction required."* The correction has landed — BC-2.20.003 now reads `as_retriever(self: &Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>` and EC-006 explicitly says *"(no lifetime parameter)."* Any agent trusting the ADR will re-open a closed finding.

---

### F-P175-D110 — `module-decomposition.md`: module census stale with false attribution

**Severity:** HIGH
**File:** `module-decomposition.md`
**Owner:** architect

**Defect:** States *"Current module universe: 71 total (69 tiered / 2 exempt …) per module-criticality.md canonical registry."* Actual per that registry: 83 total / 77 tiered / 6 exempt (12 CRIT + 28 HIGH + 35 MED + 2 LOW + 6 exempt), independently corroborated by `verification-coverage-matrix.md`. Burst-277 added 6 exempt modules and propagated to two files but not this one.

---

### F-P175-D112 — All 13 VP source files: `module:` frontmatter 100% divergent from canonical form

**Severity:** HIGH
**Files:** All 13 VP source files
**Owner:** architect

**Defect:** Every VP source file carries a pre-canonicalization `module:` value. Full mapping:

| VP | Stale | Canonical |
|----|-------|-----------|
| VP-001 | `bsp-engine` | `graph::bsp_engine` |
| VP-002 | `session-index` | `checkpoint::session_index` |
| VP-003 | `path-guard` | `sandbox::path_guard` |
| VP-004 | `mcp-adapter` | `mcp::adapter` |
| VP-005 | `mcp-client` | `mcp::client` |
| VP-006 | `injection_guard` | `prompts::injection_guard` |
| VP-007 | `serializable` | `core::serializable` |
| VP-008 | `embeddings` | `core::embeddings` |
| VP-009 | `vectorstores-similarity` | `vectorstores::similarity` |
| VP-010 | `serializable-reviver` | `core::serializable` |
| VP-011 | `hitl` | `graph::hitl` |
| VP-012 | `core-budget` | `core::budget` |
| VP-013 | `tools-shell` | `tools::shell` |

Two escalations beyond slice A's F-P175-A27: (a) VP-010's `serializable-reviver` is not a de-hyphenation but a distinct name with no registry entry — a semantic mis-anchor to a nonexistent workspace artifact; (b) the sweep ran backwards: derived consumers (VP-INDEX, `verification-architecture.md`) were made canonical while the authoritative source files stayed stale. Without a source-file-first discipline, the next consistency-validator pass will "correct" the consumers back to hyphenated form.

---

### F-P175-D105 — BC-2.22.001 PC2: 4-field literal is upstream root of VP-008 compile failure

**Severity:** HIGH
**File:** `BC-2.22.001` (PC2)
**Owner:** product-owner

**Defect:** BC-2.22.001 PC2 presents a 4-of-6-field `FerrochainError` literal as the authoritative construction form using explicit named fields (contrast the correctly abbreviated `Err(FerrochainError { ... })` elsewhere in the file). This is the direct upstream source of VP-008's compile-failure literal (F-P175-D104 / F-P175-A25). BC supersedes VP for contract discipline, so fixing VP-008 alone leaves the authoritative source broken and the regression re-emerges. Must be fixed as a pair.

---

### F-P175-D116 — `test-vectors.md`: TV-006 not recorded; total 674 contradicts BC-2.21.003 v1.8

**Severity:** HIGH (reclassified from OBS per Adjudication 3)
**Files:** `test-vectors.md`, STATE.md (false-closure record)
**Owner:** product-owner (registry correction + changelog), state-manager (STATE.md false-closure record)

**Defect:** `test-vectors.md` total reads 674 (663 canonical + 11 GTV). BC-2.21.003 v1.8 carries EC-006 and TV-006 and its own v1.7 changelog records the project total as 675 (664 canonical + 11 GTV). The +1 was never applied to the registry. Per CLAUDE.md §Source-of-Truth Precedence, BC-2.21.003 governs; the registry must be corrected upward to 675. STATE.md's record that test-vectors was bumped to v2.8/675 is a false closure — the changelog tops out at v2.7. D-39 stands.

---

## Slice D1 MED Findings (6)

`F-P175-D106` (BC-2.20.003 three `E-VS-003` sites use 2-of-6-field literals — the BC that owns adjudication 3 never states the full error shape for its own signature error; TV-004/TV-005 are what a test-writer transcribes into Red Gate tests, so the generated assertion can only check the code discriminant, silently dropping the `Component::Vs + Category::Val + RetryHint::Never` obligations ADR-014 mandates; owner: product-owner). `F-P175-D108` (ADR-005 contradicts itself 13 lines apart on the `DynTool` method name — prose says `invoke`, the code block says `invoke_dyn`; `invoke` would collide with `Tool::invoke` under the blanket impl, which is why the method is named `invoke_dyn`; the prose names a design that cannot compile; owner: architect). `F-P175-D109` (ADR-005 carries a prospective *"The following 2 sites MUST change … in a follow-on BC amendment"* for work completed in the same burst — BC-2.09.001 v1.4 and BC-2.09.002 v1.4 both landed it; same discharged-obligation class as D103; owner: architect). `F-P175-D111` (`module-criticality.md` contradicts its own summary one line later — `| Total | 83 |` then *"= 77 rows total"*; both arithmetics self-sum correctly (12+28+35+2+6=83; 12+24+4+34+1+2=77); the defect is the word "total" used for two different sets; `verification-coverage-matrix.md` uses the correct *"= 77 tiered"* form; this ambiguity is the direct proximate cause of F-P175-D110 and of `bc-authoring-plan`'s `registry_rows=77`; owner: architect). `F-P175-D113` (105 hyphenated module-path occurrences across 37 files beyond the 13 VP frontmatters; D1 did not triage each into live-body vs changelog — the finding is that no sweep boundary was ever defined, so burst-276 stopped at three files with no record of the residue; `module-decomposition.md`'s own 5 occurrences are the highest-value subset; owner: architect). `F-P175-D114` (131 version pins across ~60 files; largest cluster is 23 post-ratification sites citing ADR-010 by version number — minted by FIX-BURST-269/270 on 2026-07-25, after the 2026-07-24 ratification date, explicitly not grandfathered; `api-surface.md` v1.15 established the project's own enforcement precedent and swept exactly one file; records-lint L9 catches `file:NNN` but not `SpecDoc vN.N` — devops-engineer to extend L9; architect for ADR/VP/architecture sites; product-owner for BC/BC-INDEX sites).

## Slice D1 LOW and OBS Findings (2)

`F-P175-D115` (LOW — contingent on ADR-010 §Canon Note: if the v1.8 SCREAMING_CASE-reversal note survives verbatim, severity is HIGH, not LOW — 23 downstream artifacts are pinned to the version that overturned it; D1 did not open ADR-010's canon-note site to confirm; escalate to HIGH if confirmed surviving; owner: architect). `F-P175-D117` (OBS — BC-INDEX §VP Seed table cross-slice refutation: slice A observed the header claims 11 VP Seed BCs while the table showed 8 rows; D1 census confirms exactly 11 data rows (VP-001/002/003/006/007/008/009/010/011/012/013), matching the header and Summary row; VP-004 and VP-005 are correctly excluded and footnoted as integration VPs; the "8" was the pre-D23 count recorded in BC-INDEX's own changelog; **no fix required** — do not dispatch on this; recorded to prevent a wasted fix burst).

## Slice D1 Coverage Disclosure

Did not hand-sum the 129 TV Count cells (663 rests on four-way cross-artifact agreement). Did not individually triage all 105 hyphenated occurrences or all 131 version pins into live-body vs changelog — counts and file lists are exact, per-site classification is not. Did not open ADR-010's canon-note site to confirm the v1.8 SCREAMING_CASE note was reversed (see D115 contingency). Three of 11 `FerrochainError::new(` sites not individually opened, though no 2-arg phantom form was found in any. Per-VP frontmatter checked `module:` only — not `tool`, `priority`, `bc_anchor`, `crate`. Carry all of these forward as residual coverage debt.

## Slice D1 Synthesis

The dominant mechanism across F-P175-D103, F-P175-D107, F-P175-D109, F-P175-D110, and F-P175-D112 is a single one: burst-276 and burst-277 propagated to derived and consumer artifacts and stopped short of the authoritative sources and the obligation-tracking notes. A fix-burst that closes these file-by-file without adopting a **sweep-boundary manifest** — enumerate every match, triage live-body vs changelog, record the residue — will regenerate this finding class on pass 176.

---

## Orchestrator Self-Attributed Defects (Pass P1D-175)

1. **Three initial slices (B original, C original, D original) dispatched at a size that exceeded API response limits**, resulting in transient `Connection closed mid-response` failures; work unrecoverable per D-40. Required re-dispatch as B1/B2, C1/C2, D1/D2. Adopted from pass-174's lesson (5 slices lost); recurred here with 3 slices.

2. **B1 dispatch instructed corroboration of the subsystem registry against `L2-INDEX.md`**, but `L2-INDEX.md` contains no `SS-NN` tokens — the registry lives in `ARCH-INDEX.md`. The B1 slice self-corrected. Recorded as D1's verified-clean note.

3. **D1 dispatch brief cited `675 = 664 + 11` as the established test-vector count**, but this count had not actually been applied to `test-vectors.md` — it was only recorded in STATE.md and in BC-2.21.003's own changelog. The brief propagated a false closure (D-39) into the dispatch brief without verification. D1 correctly detected the discrepancy and escalated; Adjudication 3 confirms the false closure.

---

## Running Pass Totals (Slices A + B2 + B1 + D1)

**112 findings: 6 CRIT / 48 HIGH / 43 MED / 11 LOW / 4 OBS** (approximately — MED/LOW/OBS counts are aggregated; individual severity counts from each slice above are authoritative)

Slices C1, C2, D2 remain in progress.

---

---

## Slice C2 Perimeter and Verified-Clean Axes

File covered (read line-by-line in full): `product-brief.md` (v1.7, `status: approved`). This file has never been reviewed in any of the 175 preceding passes. It was listed in STATE.md §COVERAGE DEBTS. See Orchestrator Self-Attributed Defects item 4 for why it was skipped for two further passes after being recorded as a debt.

**Verified clean (7 candidate findings dropped with reasoning):** DI-014 triple-anchor on VP-009/010/011 matches VP-INDEX exactly; cargo-fuzz footprint is in scope with two named targets; Postgres deferral is a ratified full-feature deferral with a real delivery vehicle; frontmatter changelog pins are exempt by design; `langchain-rs` residue — zero corpus-wide; four burst-277 stale-content probes all clean (no `FerrochainError::new` arity claim, no `Arc<dyn Tool>`, no `as_retriever` infallibility claim, `VectorStoreRetriever` carries no lifetime parameter); count verification — crate roster 21 ✓, StreamEvent 15 variants ✓, 17 NE requirements ✓, 43 ADOPT/ADAPT ✓, 1,051 community modules ✓, 6 P0 Kani ✓, all four corpus pins ✓.

## Slice C2 Totals

**26 findings: 2 CRIT / 7 HIGH / 10 MED / 3 LOW / 4 OBS**

---

## Slice C2 CRIT Findings (2)

### F-P175-C201 — §Scope §In Scope: entire D-23 scope expansion absent

**Severity:** CRIT
**File:** `product-brief.md` (§Scope §In Scope, §Success Criteria, `decisions:` frontmatter)
**Owner:** product-owner

**Defect:** The D-23 scope expansion — `ferrochain-tools`, `ferrochain-macros`, `PreToolCallHook`, rolling compaction — is entirely absent from §In Scope. Wave 1 lists four crates with no mention of SS-23, CAP-034–038, or the two Wave-1 promotions. ARCH-INDEX registers `SS-23 | First-Party Tool Library | ferrochain-tools | BC-2.23.001–006 | wave: 1`. L2-INDEX records CAP-034–038 as net-new P1 Wave-1 capabilities. L2-INDEX's own `decisions:` field includes D-23. **A Phase-2 story-writer decomposing exclusively from §In Scope produces zero stories for SS-23, CAP-034–038, ADR-018/019/020, or the two Wave-1 promotions — six BCs, five capabilities, three accepted ADRs and a Kani P0 obligation (VP-011) silently dropped.** Requires a TD-VSDD-060 sweep into `prd.md` §Scope as a sibling.

---

### F-P175-C202 — Frontmatter `inputs:`, §Who Is It For, §Success Criteria: three holdout domains when there are five

**Severity:** CRIT
**File:** `product-brief.md` (frontmatter `inputs:`, §Who Is It For persona table, §Success Criteria gate criterion)
**Owner:** product-owner

**Defect:** The brief states *"Three holdout-domain archetypes anchor the design (D8),"* its persona table stops at A/B/C, and `inputs:` lists only domain-a/b/c. L2-INDEX §Design-Forcing-Function Summary states *"Five holdout domains"* including **Domain D — Hermes Agent** and **Domain E — Agentic Coding CLI**, and five files exist on disk. This corrupts a Phase-4 gate criterion: §Success Criteria reads *"all three domains pass Phase 4 gate."* **ferrochain can pass its holdout gate without evaluating Domain D or E** — including Domain E, whose five DEGRADED gaps were the entire justification for the D-23 expansion. A gate criterion under-counting its inputs by 40% is a false-green at the highest level in the pipeline. `prd.md` §Scope carries the same stale claim — sweep both in one burst.

---

## Slice C2 HIGH Findings (7)

### F-P175-C203 — Frontmatter `decisions:` and §In Scope: D19/D20/D22 absent; MCP server role absent

**Severity:** HIGH
**File:** `product-brief.md` (frontmatter `decisions:`, §In Scope)
**Owner:** product-owner

**Defect:** `decisions:` lists D1–D13, D17, D21, D23; D19/D20/D22 are absent. The capabilities they added (CAP-021 inbound MCP server role from ADR-013; CAP-020 self-improvement primitives from ADR-012) are v1 P1 and appear nowhere in §In Scope. The `ferrochain-mcp` bullet describes a client-only adapter. L2-INDEX's own `decisions:` includes D19/D20 — **the derivative tracks decisions its source does not.** Two accepted ADRs and four BCs across SS-09/SS-15 invisible from the root scope document.

---

### F-P175-C204 — §Overflow R6 row: live human instruction targets a stale script

**Severity:** HIGH
**Files:** `product-brief.md` (§Overflow R6 row), `namespace-reservation/publish-all.sh`
**Owner:** product-owner + devops-engineer

**Defect:** R6 says *"Human must run `cargo login` + publish-all.sh immediately"* and asserts coverage of all 21 crates. The script's `CRATES` array has ten entries and includes `ferrochain-prebuilt`, which is not on the 21-row canonical roster (pre-D21 residue). Executing it as written consumes an irreversible `cargo publish` on a crate that will never exist, leaves 12 roster names exposed, and — because the script prints "Published: 10" — produces a false completion signal. The brief's v1.7 changelog rates this site safety-critical yet corrected only the count, never the executable it points at. TD-VSDD-059 paper-fix. Note: a background devops-engineer agent has been dispatched to regenerate the script in-scope per Canonical Principle Rule 4; this is not a human-only deferral.

---

### F-P175-C205 — §Overflow Risk Register: stale risks, missing open risks

**Severity:** HIGH
**File:** `product-brief.md` (§Overflow Risk Register)
**Owner:** product-owner

**Defect:** The table declares `Source: STATE.md Risk Register (binding)` then disagrees bidirectionally: it carries R4 and R7, both archived as resolved, and omits R12/R13/R14 — all open HIGH. R14 is the direct sharpening of the brief's own R6 row; R12/R13 describe the scope deltas §In Scope failed to absorb (C201/C203). Also, the R-N alias scheme is declared *"binding"* here while `risks.md` §F-10 states aliases *"do not use them in new spec or BC authoring"* — this inversion is the mechanism behind the sync failure (see C216 below).

---

### F-P175-C206 — §In Scope cross-cutting and §Overflow Differentiator Traceability: VP count stale at 3 vs 6

**Severity:** HIGH
**File:** `product-brief.md` (§In Scope cross-cutting, §Overflow Differentiator Traceability)
**Owner:** product-owner

**Defect:** VP obligation count stated as 3 at two sites while §Success Criteria in the same document commits to 6 P0 Kani proofs (VP-001/002/003/009/010/011, matching VP-INDEX exactly). The v1.5 changelog claims the 3→6 expansion was applied — it was applied to one site only. A reader of §In Scope plans a 3-proof Phase 6 while §Success Criteria gates v1 on 6.

---

### F-P175-C207 — §Out of Scope: one-way import tool claimed in-scope by brief, out-of-scope by ADR-002

**Severity:** HIGH
**File:** `product-brief.md` (§Out of Scope), `ADR-002`, `assumptions.md` (ASM-007)
**Owner:** architect then product-owner + business-analyst

**Defect:** The brief declares the one-way Python-checkpoint import tool in v1 scope. ADR-002 (accepted) declares it *"separate crate, post-v1 stretch."* No delivery vehicle exists — no roster slot in the closed 21-row table, no SS, no capability. `assumptions.md` ASM-007 rests its `Impact if Wrong | Low` rating on this brief-citation, discounting risk on a locked msgpack wire format. ADR-016 §Decision 5 compounds it: *"The existing one-way Python-checkpoint import tool"* — the tool does not exist.

---

### F-P175-C208 — §Out of Scope and §Open Questions: out-of-scope and pending simultaneously; architecture phase has closed

**Severity:** HIGH
**File:** `product-brief.md` (§Out of Scope, §Open Questions)
**Owner:** architect then product-owner

**Defect:** Three items are simultaneously declared out-of-scope and awaiting an in/out decision (voice/canvas bridges, OCSF telemetry normalization, SEC/SOC 2 semantics). §Open Questions defers all three to an architecture phase that has closed (ARCH-INDEX records `phase: 1b` with 20 ADRs all accepted, none addressing these three) while asserting *"None outstanding at brief level."* All three are answerable now under the ratified production-grade default; the forbidden residue is verbatim.

---

### F-P175-C209 — §Out of Scope CAP-002 blockquote: live open imperative for work already done

**Severity:** HIGH
**File:** `product-brief.md` (§Out of Scope CAP-002 blockquote)
**Owner:** product-owner

**Defect:** A live open imperative directing the business-analyst to propagate a CAP-002 clarification to `capabilities-p0.md` — work completed long ago. `capabilities-p0.md` §CAP-002 already carries the content and states *"D21 (burst 216) supersedes the product-brief §Out-of-Scope entry for PromptTemplate."* Two prior fix-bursts hunted this stale-delegation class across `domain-spec/` (L-026 sweep and FC-4 in burst-277) and both missed the root document. The prescribed text no longer matches what landed.

---

## Slice C2 MED, LOW, and OBS Findings (17)

`C210` (MED — `ferrochain-memory` under Wave 2 in §In Scope while the brief's own R6 row and ARCH-INDEX say Wave 1; v1.7 changelog claims this fix but swept only the R6 site; `ferrochain-macros` appears in no wave bullet at all; owner: product-owner). `C211` (MED — SS-06 BC range cited `BC-2.06.001–003`; canonical is `001–006`; the three missing BCs are the D23 events the same v1.6 changelog sentence claims to have accounted for; owner: product-owner). `C212` (MED — VP-009/VP-010 labelled bare "VP-NNN candidate", which ratified D-29 reserves for IDs not yet in VP-INDEX; both are assigned Kani P0 rows; owner: product-owner). `C213` (MED — `adk-rust` mis-classified inside the Python reference corpus, erasing its D16 Corpus-5 status and the Rust-blindness rule; `langchain-community` omitted so Constraints says 4 where the Overflow table says 5; owner: business-analyst). `C214` (MED — ASM-004 mis-cited at two sites as evidence for a competitive white-space claim; ASM-004 is a Rust-vs-Python performance assumption at Medium confidence, methodology unaudited; the load-bearing anchor is ASM-003 alone with `Impact if Wrong: HIGH`; owner: product-owner). `C215` (MED — R4 mitigation instructs leading with checkpointing *"before"* a competitor matches it; the archived reframe records the competitor already ships SQLite/Postgres checkpointing and relocated the differentiator to GA maturity + conformance + formal verification; owner: product-owner). `C216` (MED — the brief declares STATE.md `R-N` aliases *"binding"*; ratified F-10 in `risks.md` says the domain-spec `R-NNN` scheme is canonical and aliases *"do not use them in new spec or BC authoring"*; this inversion is the mechanism behind C205; owner: product-owner + business-analyst). `C217` (MED — two live-body version pins whose sole allowlist exemption invokes a *"source-of-data citation"* rationale — a retired justification category; the entry is dated FIX-BURST-262 / 2026-07-25, after the 2026-07-24 retirement, and the allowlist header states *"grandfathering is the sole remaining basis for any entry"*; these pins have been passing a validator reporting PASS=198 on an entry no longer permitted to exist; owner: product-owner for spec content, devops-engineer to close the allowlist loophole). `C218` (MED — §Constraints leaves MSRV as *"set in Phase-1 architecture ADR"*; ADR-020 §Decision 7 sets it: MSRV ≥ 1.85, dominated by the `similar` pin; owner: product-owner). `C219` (MED — verification pipeline footprint stated as two crates; actual is eight per VP-INDEX; the two flagship P0 security proofs VP-002/VP-003 live in `ferrochain-checkpoint` and `ferrochain-sandbox`, crates the sentence excludes; owner: product-owner). `C220` (LOW — brief assigns crates to Wave 0; architecture's Wave-0 row is crate-free; owner: product-owner + architect). `C221` (LOW — the competitor anchoring a measurable success criterion is named three ways with two versions; owner: product-owner). `C222` (LOW — a Medium-confidence, methodology-unaudited benchmark presented as established fact under a "Pain validated" heading; ASM-004 instructs *"treat as indicative"*; owner: product-owner). `C223` (OBS — `risks.md` canonical register carries no equivalents for STATE.md's three open HIGH risks R12/R13/R14; Dual-Risk-ID reconciliation coverage claim is imprecise; owner: business-analyst). `C224` (OBS / **`[process-gap]`** — `verify-no-version-pins.sh` grants a blanket changelog exemption citing TD-VSDD-091's "pass-report changelogs" carve-out, which CLAUDE.md marks RETIRED; this is the D-46 gate-provenance failure mode in the exemption direction; owner: devops-engineer + orchestrator). `C225` (OBS — `entities-graph.md` §Relationships Summary still carries the retracted borrow form *"backed by `&dyn VectorStore`,"* contradicting D-45; owner: business-analyst). `C226` (OBS — §Success Criteria conformance row names no measurement vehicle; DTU cassette replay is established downstream; owner: product-owner, optional).

## Slice C2 Process-Gap Finding — record as decision-grade item

**Codify the following:** Three separate ratified sweeps each hunted a pattern that also existed in `product-brief.md` and stopped at document boundary: the L-026/FC-4 stale-delegation sweeps (scoped `domain-spec/`), the ARCH-INDEX v1.12 per-row wave audit (scoped the roster table), and the L2-INDEX holdout-domain sweep (scoped L2-INDEX). STATE.md §COVERAGE DEBTS already carried `specs/product-brief.md: NOT reviewed` — the debt was correctly recorded and not discharged for two passes because the dispatch mis-filed the path under `prd-supplements/`. **Perimeter construction must be derived from a glob of `.factory/specs/**/*.md` differenced against the pass's slice manifest, so a document's absence from every slice is a hard dispatch error rather than a silent skip. Any file listed under §COVERAGE DEBTS must be assigned to a named slice before the pass is dispatched.** This is an orchestrator process fix.

---

## Slice C1 Perimeter and Verified-Clean Axes

Files covered (all four read line-by-line in full): `BC-2.12.001`, `BC-2.12.002`, `BC-2.12.005`, `BC-2.12.007` (SS-12 server). Closed the SS-12 server coverage debt.

**Verified clean:** `bc_id`↔filename all four; `subsystem`/`capability` resolve; BC-INDEX titles byte-identical; `traces_to` anchors resolve; Form-A changelogs ascending; TV counts match test-vectors exactly (7/7/7/6); `red_gate:` absence is not a defect (schema hook declares it optional); `server.security_config_cors_wildcard` has an observability catalog row (SAP-1 satisfied); E-SERVER-011→422 and E-SERVER-008→409 correct. Self-validation dropped 4 findings and merged 3 — no `red_gate:` finding, no struct-variant notation finding, no missing `1.0 (initial)` changelog finding, no BC-2.12.007 PC2 short-list finding (PC2 says "including"; TV-002 says "contains" — both satisfiable).

## Slice C1 Totals

**26 findings: 1 CRIT / 11 HIGH / 9 MED / 1 LOW / 1 OBS**

---

## Slice C1 CRIT Finding (1)

### F-P175-C101 — BC-2.12.005 PC7 vs `interface-definitions.md` config schema: mutual unbootability on `debug_route_key`

**Severity:** CRIT
**Files:** `BC-2.12.005` (PC7, EC-005, TV-007), `interface-definitions.md` (config schema §debug_route_key)
**Owner:** product-owner + architect

**Defect:** BC-2.12.005 makes an empty `debug_route_key` a fatal startup error (`E-SERVER-013`, *"An empty string would effectively disable the gate — this must not be permitted"*). `interface-definitions.md` config schema makes it the shipped secure default (`debug_route_key = ""  # empty string = debug routes disabled (SECURE DEFAULT)`). Both readings are broken: if BC wins, the documented default `toml` deserializes to `Some("")` and the shipped default config makes the server unbootable; if interface-definitions wins, EC-005/TV-007/E-SERVER-013 are dead code and the security gate is unreachable. Compounding: TOML has no `None`, so `Option<String>` default is inexpressible in the declared schema, and since the key *is* the enable switch, the guard *"must be non-empty when debug routes are enabled"* is circular and can never fire. This is the NE-14 counter-example — the one contract whose purpose is preventing an unauthenticated debug route.

---

## Slice C1 HIGH Findings (11)

### F-P175-C102 — BC-2.12.001 TV-001 vs PC2: CORS preflight returns 403 vs silent-omission; E-SERVER-005 retired on wrong evidence

**Severity:** HIGH
**Files:** `BC-2.12.001` (TV-001, PC2), `error-taxonomy.md` (E-SERVER-005)
**Owner:** product-owner

**Defect:** TV-001 asserts 403 for a CORS-denied preflight while PC2 says silent header-omission with no status. `error-taxonomy.md` and `interface-definitions.md` both cite TV-001 as evidence that no 403 is produced — the exact opposite of what TV-001 says. E-SERVER-005 was retired on the strength of that citation. `tower_http` answers a non-allowed preflight with 200 + no ACAO header, matching PC2 and contradicting TV-001. The code is correct; TV-001 is wrong; but the retirement of E-SERVER-005 rests on the wrong TV reading.

---

### F-P175-C103 — BC-2.12.001: `AllowOrigin::Any` is a phantom type; `allowed_origins` field type mismatch

**Severity:** HIGH
**Files:** `BC-2.12.001` (§Invariants, EC-001, EC-003)
**Owner:** architect then product-owner

**Defect:** `AllowOrigin::Any` appears in 3 BC lines and 1 observability row — zero other corpus hits. `tower_http::cors::AllowOrigin` is an opaque struct whose wildcard is the constructor `AllowOrigin::any()`, not a variant; it cannot compile against the real dependency. Additionally, `allowed_origins` is typed as list-of-strings in EC-001 and list-of-`AllowOrigin` in Invariants/EC-003 — same field, two element types, one document.

---

### F-P175-C106 — BC-2.12.002 PC1: `if_exists` absent from Create-Thread body schema

**Severity:** HIGH
**Files:** `BC-2.12.002` (PC1), `BC-2.12.001` (correctly carries `if_exists`)
**Owner:** product-owner

**Defect:** Create-Thread body schema omits `if_exists` while PC3/PC4/EC-001/TV-002 branch on it. Sibling BC-2.12.001 PC1 declares it correctly, confirming targeted drift not pattern absence.

---

### F-P175-C107 — BC-2.12.001/002 TV-004/EC-003: non-UUID IDs make not-found paths unreachable

**Severity:** HIGH
**Files:** `BC-2.12.001` (TV-004, EC-003), `BC-2.12.002` (TV-004)
**Owner:** product-owner

**Defect:** IDs declared `Uuid` but every EC/TV uses non-UUID literals. `DELETE /threads/does-not-exist` fails path deserialization at 400/422, so EC-003's mandated `404 E-SERVER-003` is unreachable. The not-found vectors for two P1 contracts fail against a conforming implementation.

---

### F-P175-C108 — BC-2.12.002 PC15 vs EC-004/TV-007: `checkpoint: CheckpointId` non-optional vs `checkpoint: null` required

**Severity:** HIGH
**Files:** `BC-2.12.002` (PC15, EC-004, TV-007), `interface-definitions.md`
**Owner:** product-owner + architect

**Defect:** PC15 declares non-optional `checkpoint: CheckpointId` while EC-004/TV-007 require `checkpoint: null`. `interface-definitions.md` carries the same wrong type, so the defect sits in the type-authority position.

---

### F-P175-C111 — BC-2.12.001 and BC-2.12.002: two mandated error responses with no taxonomy code

**Severity:** HIGH
**Files:** `BC-2.12.001`, `BC-2.12.002`
**Owner:** product-owner

**Defect:** Two mandated error responses have no code anywhere in the taxonomy: PC5's assistant-conflict 409 and Invariant 4's empty-`graph_id` validation error. Every other SS-12 conflict names its code; these were not minted.

---

### F-P175-C112 — BC-2.12.002 PC10 vs EC-001: unconditional version creation contradicts no-op prohibition

**Severity:** HIGH
**Files:** `BC-2.12.002` (PC10, EC-001), `entities-server.md`
**Owner:** product-owner

**Defect:** PC10 makes version creation unconditional on every PATCH. EC-001 forbids it for a no-op and introduces a value-comparison rule PC10 lacks. `entities-server.md` propagates the unconditional reading.

---

### F-P175-C113 — BC-2.12.005 §Description: fabricated behavior — `RunnableConfig` cannot hold model/tools/system-prompt

**Severity:** HIGH
**File:** `BC-2.12.005` (§Description, §In Scope of Contract)
**Owner:** product-owner + architect

**Defect:** §Description claims the Assistant config binds *"model, tools, system prompt overrides, checkpointer config."* The declared type `RunnableConfig` has exactly four fields — `recursion_limit`, `thread_id`, `budget_config`, `context_mutations` — and can express none of them. The "reusable agent persona" premise of the entire Assistant resource collapses.

---

### F-P175-C114 — BC-2.12.007 §Cascade: unbounded cross-assistant data destruction

**Severity:** HIGH
**File:** `BC-2.12.007` (§Cascade invariant), `entities-server.md`
**Owner:** product-owner + architect

**Defect:** `delete_threads=true` cascades to "all Threads associated with this Assistant's Runs." `entities-server.md` cardinality: Thread 1→N Run, each Run belonging to a different Assistant. Deleting Assistant A destroys Threads holding B's Runs and, per BC-2.12.001's cascade invariant, B's checkpoint lineage. No authorization postcondition governs the cross-assistant reach.

---

### F-P175-C116 — BC-2.12.007 VP-DI011-02: phantom method makes security VP vacuously pass

**Severity:** HIGH
**File:** `BC-2.12.007` (VP-DI011-02 assertion target)
**Owner:** architect

**Defect:** VP-DI011-02's static-analysis assertion targets `CompiledGraph.invoke`; canonical is `CompiledGraph::run()`. A grep for `CompiledGraph.invoke` matches zero symbols — the VP passes vacuously. It is the only mechanized defense against CONFLICT-10/NE-13 streaming-stub counter-example. Dot notation also violates Rust path canon.

---

### F-P175-C117 — All four BCs: four phantom VP anchors absent from VP-INDEX; two at impossible phase

**Severity:** HIGH
**Files:** `BC-2.12.001`, `BC-2.12.002`, `BC-2.12.005`, `BC-2.12.007`
**Owner:** architect

**Defect:** All four phantom VP IDs (`VP-SEC-01/02`, `VP-DI011-01/02`) are absent from VP-INDEX, which declares itself source of truth with a closed arithmetic invariant. Neither matches the ratified VP-ID regex. Both DI011 VPs declare `Phase 1`, in which an integration test cannot run. VP-DI011-02's method "Static analysis" is not among VP-INDEX's registered tools. These are the verification anchors for DI-011 and DI-013 — the two invariants these BCs exist to enforce — and neither will ever be scheduled or gated under the current VP-INDEX.

---

### F-P175-C118 — BC-2.12.007: `S` test-type re-defined as "static analysis"; `prd.md` legend says "soak"

**Severity:** HIGH
**File:** `BC-2.12.007`, `prd.md` (test-type legend), `test-vectors.md` §Usage Notes
**Owner:** product-owner

**Defect:** BC-2.12.007 redefines the canonical `S` test-type abbreviation as "static analysis." `prd.md` legend says soak. `test-vectors.md` §Usage Notes instructs the test-writer to put `S`-marked BCs behind `#[ignore]` — so the DI-011/NE-13 streaming-unary equivalence tests never execute in CI. False-green on a P1 correctness contract. Conversely if soak is intended, BC-2.12.007 has no soak vector at all.

---

## Slice C1 MED, LOW, and OBS Findings (11)

`C104` (MED — CORS field has two names: `SecurityConfig.allowed_origins` vs TOML `cors_allow_origins`, with no declared serde rename; fails safe, hence MED; owner: architect then product-owner). `C105` (MED — partial-fix propagation: changelogs 1.1/1.2/1.3 claim configurable-path and inline-annotation residue removed; both survive — §Description says *"`/_debug` or equivalent"* contradicting the invariant's *"fixed constant,"* and the Invariants bullet still carries a parenthetical naming an identifier the same sentence declares nonexistent; owner: product-owner). `C109` (MED — `values: GraphState` is unserializable per ubiquitous-language, and PC16 types the same logical field `Map<String, Value>`; `NodeId` is not the canonical `NodeName`; owner: product-owner + architect). `C110` (MED — BC-2.12.001 enforces DI-002 in its body but records no invariant in `traces_to`, Traceability, or BC-INDEX, unlike correctly-anchored siblings; invisible to any invariant-coverage audit; owner: product-owner). `C115` (MED — `graph_id` is `String` in the BC and `GraphId` in `entities-server.md`; `GraphId` is defined nowhere — corpus grep returns exactly that one line; owner: architect then product-owner). `C119` (MED — TV-004 expected output `4xx/5xx` is not a falsifiable assertion — any error status passes; a node error on the unary polling endpoint most likely surfaces as `200 OK` with `status: "failed"`, so TV-004 and EC-001 may be wrong about the error shape, not just the digits; owner: product-owner). `C120` (MED — three mutually-inconsistent `ferrochain-server` file-layout conventions across the four BCs, none matching the canonical module set; no `server::api`, `server::routes`, `server::middleware`, or `server::sse` exists; `server::stores` is plural while BCs write `src/store/`; the SSE adapter is `src/sse.rs` per BC-2.12.007 but `src/streaming.rs` per BC-2.06.001; owner: architect). `C121` (MED — three preconditions/ECs assume a server-side auth layer that `interface-definitions.md` declares out of v1 scope, plus an *"unauthenticated dev mode"* toggle absent from the config schema; owner: product-owner). `C122` (MED — fabricated verbatim quotation in a traceability justification: BC-2.12.002 quotes CAP-014 as *"Assistant (named agent config with graph reference)"*; actual text is *"Assistant (named agent config)"*; BC-2.12.001 and BC-2.12.007 quote it correctly; owner: product-owner). `C124` (MED — coverage-matrix `graph::scheduler` row still says *"Pending ADR-001"*; burst-238 sweep removed that note from `module-decomposition.md` and missed the sibling; D9 gate passed 2026-07-14; owner: architect). `C125` (MED — a surviving 4-of-6-field `FerrochainError` struct literal inside `interface-definitions.md` §BaseChatModel's `bind_tools` doc comment — in the same document that declares such literals barred; an implementer copies this verbatim and it will not compile from partner crates; owner: architect/product-owner). `C123` (LOW — message-template placeholder names drift from taxonomy: `'<id>'` vs `'<thread_id>'`/`'<assistant_id>'`; counts and prefixes match but the taxonomy row itself uses `'<id>'`, so the taxonomy is internally inconsistent; owner: product-owner). `C126` (OBS — four changelog version pins, all pre-ratification and therefore grandfathered; recorded so the grandfathering is explicit; no `file.rs:NNN` citations in any of the four files — that check passes cleanly).

## Slice C1 Process-Gap Findings

1. **TV assertion-strength gap:** C119, C102, and C108 all sit in TV cells whose expected-output values are unfalsifiable or self-contradictory. They passed every prior pass because TV counts reconcile with `test-vectors.md`. A count-only gate cannot detect an unfalsifiable or self-contradictory expected value. Every TV Expected Output must pin a single status code and a schema-valid body, checked against the BC's postconditions and the taxonomy message template.
2. **BC-local VP-anchor declarations not validated against VP-INDEX:** C117 shows four invented IDs in non-canonical format, naming a tool the registry lacks, at a phase in which the stated method cannot execute. Proposed: reverse check — every ID under a BC's `## VP Anchors` must exist as a VP-INDEX row.

---

## Orchestrator Adjudication 4 — D-45 is OVERTURNED; `as_retriever` receiver correction

**This is the pass's most severe finding, and the defect is mine.**

Slice D2 (F-P175-D206) reported that `as_retriever(self: &Arc<Self>)` is an illegal receiver producing E0307. **D2's stated error code is wrong — and the true consequence is worse.**

Verified results on the pinned toolchain:
1. `trait T { fn f(self: &Arc<Self>) -> R; }` on a concrete impl compiles cleanly. No E0307.
2. Adding `fn dynok(x: &Arc<dyn T>) -> R { x.f() }` fails with **E0038: the trait `T` is not dyn compatible**, annotated *"method `f`'s `self` parameter cannot be dispatched on"* with the suggestion *"consider changing method `f`'s `self` parameter to be `&self`."*
3. `trait T { fn f(self: Arc<Self>) -> R; }` with `fn dynok(x: Arc<dyn T>) -> R { x.f() }` compiles, and `Arc::clone(&self)` works inside the body.

**Therefore:** `&Arc<Self>` makes `VectorStore` not object-safe, so `Arc<dyn VectorStore>` cannot exist. That destroys the entire premise of D-45, whose purpose was to have `VectorStoreRetriever` own `Arc<dyn VectorStore>` so it is `'static` and survives `tokio::spawn`. BC-2.20.003 PC2 states `as_retriever` is *"called on an `Arc<dyn VectorStore>`"* — which the adjudicated receiver makes impossible. The SS-20 RAG seam and BC-2.20.002 (a P0 Red Gate) are blocked. `VP-2.20.003-A` now specifies a compile-time test asserting this compiles, which cannot pass.

**Corrected ruling — supersedes D-45 on this point:** the receiver is `fn as_retriever(self: Arc<Self>) -> Result<VectorStoreRetriever, FerrochainError>`. It is dyn-compatible, permits `Arc::clone(&self)` for the owned-store field, and preserves every other part of D-45 (no lifetime parameter; retriever owns `Arc<dyn VectorStore>`; fallible return per D-44). **Rationale: the receiver must be object-safe because the design's own ownership model requires `Arc<dyn VectorStore>`.**

**Record as orchestrator self-attributed defect, stated plainly:** the architect proposed `&Arc<Self>` and I endorsed it as "the better call" without checking dyn-compatibility, then propagated it to 4 documents and 11+ sites plus a Red Gate compile test. This is the second E0038 object-safety failure in this project — the first was `Tool`, which D-43 solved with `DynTool`. I approved a fix for one problem that reintroduced the same failure class elsewhere. **D2's severity was right while its error code was wrong**, which is why independent verification of adversary claims is load-bearing: had I dispatched the fix on D2's reasoning alone, the burst would have "fixed" a nonexistent E0307 and left the real E0038 in place.

**Routing:** architect re-adjudicates ADR-014 Decision 2 to `self: Arc<Self>`, then a corpus-wide sweep of all 11+ sites across ADR-014, `interface-definitions.md` §VectorStore, `api-surface.md`, BC-2.20.003 (×5) and BC-2.21.001 (×3), plus `VP-2.20.003-A`'s compile-test specification. Sweep-boundary manifest required per D1 recommendation.

---

## Slice D2 Perimeter and Verified-Clean Axes

Changed-content verification of frozen HEAD `2d36282` (burst-277). Reviewed eight closure claims against the diff.

**Per-item closure verdicts:**

| Item | Verdict |
|------|---------|
| `as_retriever` fallibility | PARTIAL/FAILED — 5 sites correct, rejection-not-clamping correct, no lifetime form; but receiver wrong (Adjudication 4) and 2 unswept `&dyn VectorStore` sites in BC-2.20.003 |
| DynTool migration | FAILED — fabricated site list still live under false "Corrected above" attestation; migration list omits a real third site; `invoke` vs `invoke_dyn`; module path 3-way split; semantic inversion |
| `FerrochainError` constructor | PARTIAL/FAILED — 5-arg signature, `Option<Arc<…>>`, Clone rationale all VERIFIED; 2-arg phantom gone; survivors: BC-2.22.001 PC2, BC-2.21.002 phantom field ×4, ADR-005 |
| BC-2.19.003 fabricated-panic removal | PARTIAL — ADR-016 justification VERIFIED REAL; no `DuplicateRegistration` survives anywhere; but edited DI-008 row now asserts a `Result` return contradicting PC2 and interface-definitions |
| BC-2.07.002 input-hash | VERIFIED — Form-A rows 1.0–1.7 faithfully mirror Form-B; no fabricated entry; correction note present and consistent |
| BC-2.08.011/012 metadata-only | VERIFIED — Form-A is verbatim-equivalent transcription; zero substantive content changed; withholding the bump was correct |
| Version/changelog discipline | FAILED — BC-INDEX count/enumeration mismatch + unrecorded bump; 4 perimeter BCs with no bump; ARCH-INDEX placeholder hash and stale timestamp; new TD-091 pins |
| Domain-spec Wave D (capabilities-p1-p2) | VERIFIED with defect — all 5 sites resolved, zero residue in 3 shards, all 7 cited BCs exist; but grep term used cannot falsify singular residue, and sweep was never corpus-wide |

**Note on BC-2.20.001, BC-2.20.002, BC-2.21.002, BC-2.22.001 (D221 adjudication):** `git show --stat 2d36282` confirms all four appear in the diff at `2 +-` (1 line added, 1 removed — consistent with a mechanical field update). The commit message explicitly names only 6 BCs (BC-2.20.003/2.09.001/2.09.002/2.21.001/2.19.003/2.07.002). All four were edited without acknowledgment in the commit message and without BC-INDEX recording.

## Slice D2 Totals

**25 findings: 1 CRIT (D206 reclassified per Adjudication 4) / 9 HIGH / 12 MED / 3 LOW-OBS**

---

## Slice D2 CRIT Finding (1)

### F-P175-D206 — BC-2.20.003 and ADR-014: `as_retriever(self: &Arc<Self>)` makes `VectorStore` not object-safe

**Severity:** CRIT (reclassified from HIGH per Adjudication 4)
**Files:** `BC-2.20.003` (PC2), `ADR-014` (§Decision 2), `interface-definitions.md` (§VectorStore), `api-surface.md`, `VP-2.20.003-A`
**Owner:** architect

**Defect:** See Adjudication 4 above. The receiver `self: &Arc<Self>` causes E0038 when `VectorStore` is used as a dyn trait object, not E0307 as originally reported. The corrected receiver is `self: Arc<Self>`.

---

## Slice D2 HIGH Findings (9)

### F-P175-D201 — ADR-005: retracted fabricated list still lives in body; false "Corrected above" attestation

**Severity:** HIGH
**File:** `ADR-005`
**Owner:** architect

**Defect:** The retracted fabricated list (*"4 live `dyn Tool` usage sites"* enumerating BC-2.05.003/004, BC-2.08.010, `ToolCallPreview.tool`) still lives directly above an errata claiming *"Corrected above."* Only the 2-site migration list was corrected. The code sketch also retains the retracted claim about covering *"heterogeneous tool dispatch and HITL approval"* and *"wherever `Arc<dyn Tool>` was specified."* Zero `dyn Tool` in those three BCs — independently confirmed. TD-VSDD-059 paper-fix layered on the exact defect the burst claimed to close.

---

### F-P175-D202 — ADR-005 and `api-surface.md`: corrected migration list still incomplete — third real site missed

**Severity:** HIGH
**Files:** `ADR-005`, `api-surface.md`
**Owner:** architect

**Defect:** Both assert the corrected list is exactly 2 sites, but BC-2.09.007's own changelog records a third real site migrated in the same commit (`ToolRegistry`: `Option<Arc<dyn Tool>>` → `Option<Arc<dyn DynTool>>`). The re-verification that produced the corrected list missed it — **the errata fixing a fabricated list produced a second incomplete one.**

---

### F-P175-D203 — BC-2.21.002 (4 sites): `document_index` carried as a field on `FerrochainError`

**Severity:** HIGH
**File:** `BC-2.21.002` (×4 sites)
**Owner:** product-owner

**Defect:** `document_index` carried as a field on `FerrochainError`. ADR-010 §Decision F-P174-303, authored in this burst, explicitly forbids it: *"No `context` field is added to `FerrochainError` … MUST be interpolated into the `message` field … the 6-field struct is final."* ADR-014 was rewritten to `format!("… document_index={}", i)`; the consumer BC was not swept. TD-VSDD-060.

---

### F-P175-D204 — BC-2.22.001 PC2: 4-of-6-field literal survives (third independent confirmation)

**Severity:** HIGH
**File:** `BC-2.22.001` (PC2)
**Owner:** product-owner

**Defect:** 4-of-6-field `FerrochainError` literal — `retry_hint` absent (a required defaultless field). Third independent confirmation (after F-P175-A25/D104 and slice B2 F-P175-B203). This is the upstream source of VP-008's compile failure; fixing VP-008 alone leaves the authoritative BC stale.

---

### F-P175-D205 — BC-2.20.003 Precondition 1 and Related BCs: two `&dyn VectorStore` sites survive in primary fix target

**Severity:** HIGH
**File:** `BC-2.20.003` (Precondition 1, §Related BCs)
**Owner:** product-owner

**Defect:** Two `&dyn VectorStore` sites survive in the primary fix target, two lines above a PC2 that correctly says `Arc<dyn VectorStore>`. BC-2.21.001's mirrored line was fixed, so this is an in-file miss. TD-VSDD-060.

---

### F-P175-D207 — BC-INDEX v3.23 header vs enumeration: 7 bumps claimed, 6 enumerated; BC-2.09.007 absent

**Severity:** HIGH
**File:** `BC-INDEX.md` (v3.23 changelog)
**Owner:** state-manager

**Defect:** Header claims *"7 BC version bumps"*; the entry enumerates six. BC-2.09.007 v1.0→v1.1 is absent entirely. BC-2.20.003 v1.2→v1.3 also unrecorded (v3.23 opens at "v1.3→v1.4"). BC-INDEX is the version-currency source of truth for every later pass.

---

### F-P175-D208 — `interface-definitions.md` §Tool/§DynTool: `ToolOutput` missing `Serialize`; error-variant mapping unspecified

**Severity:** HIGH
**Files:** `interface-definitions.md` (§Tool, §DynTool), `BC-2.09.001`, `BC-2.09.002`
**Owner:** architect + product-owner

**Defect:** `ToolOutput` declared `#[non_exhaustive]` with no derives — no `Serialize`, so no `ToolOutput → serde_json::Value` conversion exists for the blanket impl. The mapping for `ToolOutput::Error(String)` is also unspecified: if it maps to `Ok(json)`, it is a silent-error-swallow vector — a tool failure surfacing as `Ok` through the object-safe seam violates DI-014 and the no-silent-empty rule.

---

### F-P175-D209 — BC-2.19.003 Traceability row edited this burst: asserts `Reviver::new()` returns `Result`; PC2 and interface-definitions say it returns `Self`

**Severity:** HIGH
**Files:** `BC-2.19.003` (Traceability row, PC2), `interface-definitions.md`
**Owner:** product-owner + architect

**Defect:** The Traceability row now asserts *"DI-008 (`Reviver::new()` returns Result…)"* while PC2 says it *"returns a `Reviver` instance"* and `interface-definitions.md` declares `pub fn new() -> Self`. The burst edited this exact row to remove an exception and thereby created a three-document contradiction.

---

### F-P175-D210 — BC-2.09.002 §Description, PC4, TV-003: `McpError::ToolExecution` at a public boundary with no E-MCP code

**Severity:** HIGH
**File:** `BC-2.09.002` (§Description, PC4, TV-003)
**Owner:** product-owner

**Defect:** Raw `Err(McpError::ToolExecution)` at a public boundary with no E-MCP code assigned, contradicting the taxonomy preamble. The file's own v1.3 changelog fixed PC5/PC6 for exactly this reason and left these three unswept. TD-VSDD-060.

---

## Slice D2 MED Findings (12)

`D211` (ADR-005 prose says `invoke`; its own code block and two other documents say `invoke_dyn`; owner: architect). `D212` (3-way module-path split for `DynTool`/`Tool`: `core::tools` vs `core::tool`; neither has a row in `module-decomposition.md`, the registry VP-INDEX names canonical; owner: architect). `D213` (ADR-005 asserts `dyn Tool` IS *"object-safe under E0038"* — the sentence justifying the entire DynTool decision states the opposite of `api-surface.md`, `interface-definitions.md`, BC-2.09.001, and BC-2.09.002; owner: architect). `D214` (stale *"Wave C PO correction required/pending"* notes in ADR-014 and `interface-definitions.md` for work that landed in the same commit; also the sole surviving `VectorStoreRetriever<'_>` in the corpus; owner: architect). `D215` (the burst that removed 11 TD-091 pins wrote 12+ new ones, including one in a live body — ARCH-INDEX §Verification Properties citing VP-INDEX by version number — in a file whose own v1.14 entry ratified that newly-authored live-body pins are violations and *"not grandfathered"*; owner: architect + devops-engineer). `D216` (ADR-005 §MonotonicClock: a 3-field SCREAMING-cased literal eleven lines above the same error rendered correctly via `FerrochainError::new(...)` in the same fence — falsifying both ADR-005 v1.6's and ADR-010 v1.13's scoped sweep claims; ADR-005 was bumped this burst and not swept; TD-VSDD-060; owner: architect). `D217` (ADR-014's `pub enum SearchType` declared without `#[non_exhaustive]`, contradicting BC-2.20.003 INV-1 and `interface-definitions.md` — six lines below the struct this burst rewrote; owner: architect). `D218` (capabilities-p1-p2 v1.18 attests a machine-verifiable sweep quoting the PLURAL term, but the fixed site used the SINGULAR form — the quoted grep cannot falsify singular residue; same false-green mechanism that produced FC-4; owner: business-analyst). `D219` (ADR-019 carries two live future-tense PO BC obligation delegations for BCs that all exist — BC-2.06.006, BC-2.10.005, BC-2.10.006 — because all three burst-277 sweep attestations were scoped "in this file"; owner: architect). `D220` (ARCH-INDEX frontmatter `input-hash: "pending-FIX-BURST-275"` — a placeholder surviving two touches including this burst; owner: state-manager). `D221` (BC-2.20.001, BC-2.20.002, BC-2.21.002, BC-2.22.001 each appear in the diff at `2 +-` per `git show --stat 2d36282` but carry no version bump and no BC-INDEX recording; the commit message names only 6 BCs; four BCs were edited without acknowledgment; owner: product-owner for version bumps, state-manager for BC-INDEX). `D222` (`interface-definitions.md` carries an open *"BC-2.14.001 must be amended"* routing note; Wave C discharged every sibling but not BC-2.14.001, the canonical `FerrochainError` contract; owner: product-owner).

## Slice D2 LOW and OBS Findings (3)

`D223` (LOW — ARCH-INDEX timestamp 2026-07-26 vs changelog v1.16 dated 2026-07-28; not an ADR so the frozen-timestamp exemption does not apply; owner: state-manager). `D224` (LOW — BC-2.07.002, BC-2.08.011, BC-2.08.012 now carry both Form-A and Form-B with byte-divergent wording for the same versions; BC-2.07.002 v1.7 says *"migrated from Form-B"* but Form-B was neither removed nor annotated as superseded; adjudicate: replicate the D-28 banner into each dual-form body, or drop Form B; owner: state-manager). `D225` (OBS — the D-42 burst-log record says `Arc` preserves Clone *"for broadcast channels"* — that rationale appears nowhere in the corpus; the recorded rationale in ADR-010, `api-surface.md`, and BC-2.14.001 EC-001 is `#[derive(Clone)]` compilability and `to_problem()`/`retry_hint` dependence; a records-tier claim introduced with no artifact anchor; owner: state-manager).

## Slice D2 Synthesis

The burst's own attestations are the least reliable artifacts in the diff. Three false-closure attestations were minted in this commit (D201: "Corrected above" when it was not; D202: a re-verification that missed a site the same commit fixed; D207: a bump count contradicting its own enumeration), and two more (D216, D218) falsify claims a prior burst attested and this burst had the chance to re-verify. Second structural pattern: the adjudication landed in the authority document but not in the consumer BC (D203, D204, D205, D210) because every TD-VSDD-060 sweep in this burst was scoped "in this file."

---

## Orchestrator Self-Attributed Defects (Pass P1D-175 — complete record)

1. **Three initial slices (B, C, D original) dispatched at a size exceeding API response limits**, resulting in transient `Connection closed mid-response` failures; work unrecoverable per D-40. Required re-dispatch as B1/B2, C1/C2, D1/D2. Recurrence of pass-174's 5-slice loss despite that lesson.

2. **B1 dispatch instructed corroboration against `L2-INDEX.md`** for the subsystem registry, but that file contains no `SS-NN` tokens — the registry lives in `ARCH-INDEX.md`. B1 self-corrected.

3. **D1 dispatch brief cited 675 as the established test-vector count**, but this count had not been applied to `test-vectors.md` — it was only in STATE.md and BC-2.21.003's own changelog. D1 correctly detected the discrepancy; Adjudication 3 confirms D-39 stands and STATE.md's v2.8/675 record is a false closure.

4. **`product-brief.md` was carried in STATE.md §COVERAGE DEBTS and still skipped for two passes** because my dispatch mis-filed its path under `prd-supplements/`. The debt was correctly recorded; the assignment logic failed. C2 found 26 findings including 2 CRIT.

5. **D-45 `as_retriever` receiver adjudication: `&Arc<Self>` propagated to 4 documents and 11+ sites plus a Red Gate compile test without checking dyn-compatibility.** The receiver makes `VectorStore` not object-safe (E0038), destroying the `Arc<dyn VectorStore>` ownership premise of D-45. D2 reported the correct severity while misidentifying the error code (E0307 vs E0038). Corrected receiver: `self: Arc<Self>`. This is the second E0038 object-safety failure in this project.

---

## Final Pass Totals

All 7 slices complete: A (32) + B1 (29) + B2 (34) + C1 (26) + C2 (26) + D1 (17) + D2 (25) = **189 findings**

**10 CRIT / ~69 HIGH / ~76 MED / remainder LOW-OBS**

Three slices lost to transient API failures (B original, C original, D original) — re-run split.

**Perimeter note:** P1D-175's perimeter was deliberately debt-first (six coverage debts closed: 6 VP bodies, 8 pattern-probe BCs, 4 SS-12 BCs, `product-brief.md`, corpus sweeps, delta regression verification), not the same perimeter as P1D-174. The 256→189 movement is NOT convergence evidence.

Convergence trajectory tail: →130 (P1D-173) →256 (P1D-174) →189 (P1D-175)

---

## Validator Baselines at Frozen HEAD `2d36282`

Baselines from the burst-277 commit message (authoritative):

| Validator | Result |
|-----------|--------|
| `records-lint` | PASS=4 WARN=1 (L10 advisory) FAIL=0 |
| `verify-no-version-pins` | PASS=198 |
| `verify-form-a-changelog-direction` | PASS=198 WARN=7 BC_UNVERIFIED=0 |
| `verify-bc-frontmatter-schema` | PASS=129 |
| `verify-adr-decision-refs` | PASS=322 |
| `verify-arch-anchor-resolution` | PASS=129 |
| `verify-module-canonicality` | FAIL=0 |
| `verify-enum-variant-casing` | PASS=198 |

---

## Fix-Burst Sequencing Mandate

**Do not dispatch fix-bursts until the final pass record is committed to factory-artifacts.** The following priority ordering is recommended.

**P0 — Correctness gate blockers (address before any other work):**
1. Adjudication 4 / F-P175-D206: `as_retriever(self: Arc<Self>)` corpus-wide sweep (architect → product-owner) — 11+ sites across ADR-014, `interface-definitions.md`, `api-surface.md`, BC-2.20.003 ×5, BC-2.21.001 ×3, `VP-2.20.003-A`
2. F-P175-C101: `debug_route_key` mutual-unbootability (architect adjudicates, product-owner rewrites BC-2.12.005 + `interface-definitions.md`)
3. F-P175-B201/B202: SS-18 injection guard false-coverage (product-owner + architect)
4. F-P175-C202: holdout gate under-counts domains (product-owner — `product-brief.md` + `prd.md` sweep)

**P1 — Security and convergence-blocking:**
5. F-P175-B101/B102: cross-tenant read path and SkillStore scope gap (architect + product-owner + security-reviewer triage)
6. F-P175-D104/D204: VP-008 and BC-2.22.001 compile failures (pair fix — BC-2.22.001 PC2 first, VP-008 second)
7. F-P175-D101: `capabilities-p1-p2.md` §CAP-027/028 stale `as_retriever` anchors (business-analyst — but wait for Adjudication 4 fix to land first)
8. F-P175-C117: phantom VP anchors in SS-12 (architect — 4 VP registrations + method correction in VP-DI011-02)

**P2 — Correctness, sweep completion:**
9. D221: BC-2.20.001/002/2.21.002/2.22.001 unbumped; BC-INDEX missing entries (product-owner + state-manager)
10. D207/D203/D205: BC-INDEX enumeration gap; BC-2.21.002 phantom field; BC-2.20.003 survivors (product-owner + state-manager)
11. C201/C203: `product-brief.md` D-23 scope and decisions gap (product-owner) — include `prd.md` sweep per C201
12. D116/D-39 false closure: `test-vectors.md` → 675 (product-owner + state-manager)

**Sweep-boundary discipline (mandatory for all fix-bursts):** Per D1 synthesis, every fix-burst must include a sweep-boundary manifest enumerating every match found, triaging live-body vs changelog, and recording residue explicitly. A burst scoped "in this file" without corpus-wide verification will be flagged as a process-gap finding on the next pass.

---

## Verified-Genuine Prior Closures

The following finding-IDs from prior passes were independently confirmed CLOSED against frozen HEAD `2d36282` by D2 slice verification:

- F-P174-xxx BC-2.07.002 input-hash correction — VERIFIED
- F-P174-xxx BC-2.08.011/012 Form-A metadata-only — VERIFIED
- F-P174-xxx domain-spec Wave D stale content (capabilities-p1-p2 shards) — VERIFIED with note (grep term limitation recorded above)
- F-P174-xxx `DuplicateRegistration` fabricated-panic removal — VERIFIED (zero corpus-wide)
- F-P174-xxx 2-arg `FerrochainError::new` phantom — VERIFIED (zero corpus-wide)

---

## Pass Record Completeness

All 7 slices complete. Pass record CLOSED.

**CLEAN (strict): NO — 189 findings of varying severity. Streak stays 0/3 — do NOT advance.**
**CLEAN (PR-merge): NO — multiple CRIT findings present.**

Status: `closed` — update frontmatter before committing.
