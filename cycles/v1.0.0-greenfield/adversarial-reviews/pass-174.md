---
document_type: adversarial-review
level: ops
pass_id: P1D-174
pass_label: FULL-PERIMETER
frozen_head: cd0a2c7
date: 2026-07-27
version: "1.0"
status: closed
producer: adversary (13 slices) + state-manager
cycle: v1.0.0-greenfield
traces_to: STATE.md
---

# Adversarial Review — Pass P1D-174 FULL-PERIMETER

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P1D-174 FULL-PERIMETER |
| Frozen HEAD | `cd0a2c7` |
| Date | 2026-07-27 |
| Method | 13 bounded read-only slices (5 initial slices died on transient API `Connection closed mid-response`; re-dispatched as smaller segments — D-32 transient-failure class) |
| Scope | Full perimeter: architecture core, ADRs 001–020, domain-spec shards, VPs, interface-definitions, prd-supplements, all BC families ss-01 through ss-23 + BC-INDEX |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** |
| 3-CLEAN streak (BC-5.39.001) | **0/3 — unchanged** |

## Totals

**~256 findings total** (9 CRIT / 96 HIGH / 106 MED / 30 LOW / 11 OBS / 17 process-gap)

## Per-Segment Tallies

| Segment | Scope | CRIT | HIGH | MED | LOW | OBS | PG |
|---------|-------|------|------|-----|-----|-----|----|
| 1 | architecture core (9 files + ARCH-INDEX) + prd.md + module-criticality.md | 0 | 12 | 9 | 1 | 1 | 2 |
| 2 | ADRs 001–010 | 0 | 10 | 13 | 1 | 0 | 2 |
| 3 | ADRs 011–020 | 2 | 6 | 8 | 4 | 1 | 0 |
| 4 | domain-spec (15 shards) | 0 | 4 | 9 | 4 | 0 | 1 |
| 5 | VPs (14) + verification-architecture + coverage-matrix | 1 | 6 | 4 | 2 | 0 | 1 |
| 6a | interface-definitions.md + api-surface.md | 2 | 5 | 6 | 1 | 1 | 2 |
| 6b | prd-supplements (error-taxonomy, observability, test-vectors, nfr-catalog, bc-authoring-plan, module-criticality) | 0 | 3 | 6 | 1 | 1 | 2 |
| 7a | BCs ss-01..ss-04 (21 files) | 0 | 8 | 8 | 5 | 1 | 2 |
| 7b | BCs ss-05..ss-07 (17 files) | 0 | 8 | 6 | 3 | 0 | 2 |
| 8a | BCs ss-08..ss-09 (21 files) | 1 | 10 | 5 | 1 | 0 | 1 |
| 8b | BCs ss-10..ss-13 (26 files) | 0 | 8 | 10 | 2 | 0 | 0 |
| 9a | BCs ss-14..ss-18 (22 files) | 1 | 4 | 8 | 2 | 2 | 0 |
| 9b | BCs ss-19..ss-23 (22 files) + BC-INDEX | 2 | 12 | 14 | 3 | 4 | 2 |

---

## The 9 Critical Findings

### F-P174-303 — `FerrochainError` has no `context` field

**Severity:** CRIT
**Routing:** architect

Gate #33 "structured context field" convention has no carrier type. The struct has exactly 6 fields (`component`, `category`, `retry_hint`, `code`, `message`, `source`). Three error codes depend on a `context` field: E-VS-004 `document_index`, E-TOOLS-008, and E-TOOLS-009. There is nowhere to attach structured per-invocation context in any `FerrochainError` value.

---

### F-P174-305 / F-P174-952 — `lc_secrets` credential-stripping is unimplementable (triangulated by slices 3 and 9b)

**Severity:** CRIT
**Routing:** architect + product-owner

`LcEntry` has exactly 2 fields (`lc_id`, `constructor`). The method `lc_secrets` is declared as an instance method `fn lc_secrets(&self)`, so stripping secrets from `kwargs` BEFORE constructor dispatch is impossible — there is no slot to carry the static secret-name slice. This breaks the DI-010 credential-injection defence (ADR-016 Decision 3 Property 3, BC-2.19.002 PC-2/Inv-1/EC-002/TV-002/VP-2.19.002-B).

**Fix:** Add a third `LcEntry` field carrying the static secret-name slice, populated at `inventory::submit!` time.

---

### F-P174-502 — `verification-architecture.md` §VP-001 false closure

**Severity:** CRIT
**Routing:** architect

The `verification-architecture.md` v2.12 changelog claims formal-statement and harness fixes for §VP-001 that were NEVER applied. The §VP-001 body still contains `kani::any_permutation(n)` (a nonexistent Kani API), `TaskId(i as u64)` (the retired numeric model), and a 2-tuple `Vec<(TaskId, ChannelUpdate)>`. The VP-009 half of the same changelog entry WAS applied. VP-001.md v1.4 asserts "Sibling sweep (TD-VSDD-060): `verification-architecture.md` §VP-001 section updated in same burst" — it was not.

---

### F-P174-601 / F-P174-901 — `FerrochainError::new` is a phantom constructor (triangulated by slices 6a and 9a)

**Severity:** CRIT
**Routing:** architect + product-owner

Exactly ONE occurrence of `FerrochainError::new` exists corpus-wide (in `interface-definitions.md`, `VectorStore` default impl), with no `impl FerrochainError` block anywhere. The call passes 2 arguments to a 6-field `#[non_exhaustive]` type. Consequence: **20 of 21 workspace crates cannot construct any error** — `#[non_exhaustive]` bars the struct literal (E0639) and no constructor exists. The entire 109-code error taxonomy is unimplementable.

---

### F-P174-605 — First-party tool `action_risk` annotations missing (security-critical)

**Severity:** CRIT
**Routing:** product-owner

5 of 6 first-party tool stubs in `interface-definitions` §First-Party Tools lack `action_risk`: `read_file`, `write_file`, `edit_file`, `list_dir`, `grep` (only `bash` has it). Per the `§Tool` contract, unannotated tools return `action_risk() → None` → `ToolCallPreview.action_risk = None` → unclassifiable into any HITL interrupt tier → **destructive file writes dispatch with no approval gate**. BC-2.23.002 H1 mandates `High` for `WriteFileTool`.

---

### F-P174-801 / F-P174-615 — `dyn Tool` is E0038 (triangulated by slices 6a and 8a)

**Severity:** CRIT
**Routing:** architect

`Tool: Runnable<ToolInput, ToolOutput>`. `Runnable::stream` returns `impl Stream` with no `where Self: Sized` bound → dyn-incompatible. Live `dyn Tool` sites: BC-2.09.001 (×2), BC-2.09.002 PC1, BC-2.09.007 §Architecture Anchors. ADR-005 §Adjacent Trait Object-Safety Adjudications settles `Runnable` and `BaseChatModel` but NEVER adjudicates `Tool`. `api-surface.md` v1.10 quoted this exact line while fixing the trait row's subsystem anchor and did not notice. Blocks the entire MCP adapter + `ToolRegistry` design.

---

### F-P174-951 — BC-2.19.003 duplicate-detection false closure

**Severity:** CRIT
**Routing:** product-owner

BC-2.19.003 v1.2 changelog claims "Drop fabricated 'duplicate detection' clause (not attributed in ADR-016)"; the clause survives at 3 body sites (§Invariants 2, EC-003 `DuplicateRegistration`, §Traceability DI-008 row). BC-INDEX 3.19 repeats the closure claim. `inventory` has no duplicate-detection semantics, and the clause also violates the DI-008 no-panic posture asserted in the same table.

---

### F-P174-104 (elevated) — `prd.md` §3 Cargo feature list stale at 6 of 10 flags

**Severity:** CRIT (elevated)
**Routing:** product-owner

`prd.md` §3 omits `sandbox-process` (the NOT-enforcing backend, security-annotated), `mcp`, `budget` (default-ON), and `guardrail` (default-ON). `api-surface.md` was corrected to 10 flags in v1.14; `prd.md` was not swept. The list now misrepresents the public feature surface to every downstream reader.

---

### F-ORCH-174-04 — Validator reports PASS for files it cannot verify (process-gap — CRIT)

**Severity:** CRIT (process-gap)
**Routing:** devops-engineer

`verify-form-a-changelog-direction` emits `[PASS]` for all six BC files that have NO frontmatter `changelog:` key: BC-2.07.002, BC-2.08.011, BC-2.08.012, BC-2.09.007, BC-2.13.007, BC-2.15.005. It reports `UNVERIFIED=0`. Six of its 198 "passes" are vacuous. The `UNVERIFIED` counter was added in burst-276-content-3 specifically to close this class; STATE.md records that burst as "validator false-confidence family eliminated." **The family was not eliminated — it survives in the very validator that received the fix.**

---

## Seven-Control Security Cluster

### SEC-1 — Rate-limit bypass via LRU eviction (BC-2.12.006 EC-003)

**Finding ID:** F-P174-861

In-memory `RateLimitStore` LRU eviction resets a throttled caller's window. An attacker emits requests under 10,000 synthetic `caller_id` values to evict their own bucket, then resumes with fresh quota — repeatable indefinitely. Spec text blesses this: "This is documented as expected behavior of the in-memory default (not a bug)." The eviction also un-throttles every other tenant on the eviction wave.

**Fix:** Evict only fully-expired buckets; fail closed (429 + `Retry-After`) for new callers when no bucket exists; add an invariant that no eviction may increase any caller's remaining quota; add a VP.

---

### SEC-2 — Credential leak at MCP egress (BC-2.09.007)

**Finding ID:** F-P174-814

`tools/call` forwards `FerrochainError` message verbatim to an EXTERNAL untrusted MCP client (PC3/EC-002). Sanitization is described as "In v1 this is best-effort" with no predicate, no gate, no VP.

**Fix:** Serialize only `code` + `category` + the taxonomy-canonical message template, never `source` chains or provider-raw bodies; add a VP mirroring BC-2.08.014 VP-FAILOVER-02.

---

### SEC-3 — HITL gate bypass on destructive writes

See F-P174-605 above (CRIT 5). Destructive `write_file`/`edit_file` dispatch with no HITL approval gate due to missing `action_risk` annotation.

---

### SEC-4 — Credential-injection defence unimplementable

See F-P174-305/F-P174-952 above (CRIT 2). `lc_secrets` instance-method cannot strip secrets before constructor dispatch.

---

### SEC-5 — Silent MCP registry truncation (BC-2.09.001)

**Finding ID:** F-P174-816

`MAX_ITERATIONS=1000` pagination bound drops the final cursor and returns the partial list with `Ok`, while PC1 simultaneously claims "all pages are consumed." Silent partial failure; the agent then reports "tool not found" with no diagnostic.

---

### SEC-6 — VP-003 workspace confinement unprovable

**Finding ID:** F-P174-869

BC-2.13.004 makes `canonicalize_beneath_root` call `std::fs::canonicalize`, which Kani cannot model. VP-003 requires the pure `canonicalize_beneath_root_pure` seam that NO SS-13 BC defines.

---

### SEC-7 — Sandbox enforcing default unimplementable (BC-2.13.001)

**Finding ID:** F-P174-858

PC1 requires `SandboxBackend::default()` to return a backend value; PC4/EC-001/EC-002/EC-004/TV-3 require it to return `Err(E-SBXD-003)`. `Default::default() -> Self` cannot return `Result`, and EC-003 + DI-008 forbid panicking. No legal implementation exists.

**Fix:** Split to `try_default() -> Result<Self, FerrochainError>`.

---

### SEC-adjacent — Cosine denominator overflow (F-P174-972 / F-P174-955)

**F-P174-972:** Even after the v1.7 two-part guard, the denominator product `norm_a * norm_b` can overflow to `+Inf` when both per-vector norms are individually finite (finite norm bounded by `sqrt(f32::MAX)`), reopening the `Inf/Inf = NaN` path. VP-009 (Kani P0) will still not close. **Fix:** Guard `let denom = norm_a * norm_b; if !denom.is_finite() || denom == 0.0 { Err }`.

**F-P174-955:** The D-37 widening was NOT applied to the write-time sibling E-VS-004 (BC-2.21.002, 5 sites + taxonomy row). An overflow-norm vector passes the write gate, is persisted, and poisons every subsequent search permanently — defeats the ADR-014 Decision 5 containment promise.

---

## Six Confirmed False Closures

1. **`verification-architecture.md` v2.12 §VP-001** — CRIT (F-P174-502). Changelog claims `kani::any_permutation` replaced and `TaskId` model updated; body unchanged.
2. **BC-2.19.003 v1.2 duplicate-detection clause** — CRIT (F-P174-951). Changelog claims clause dropped; three body sites survive.
3. **VP-013 v1.13 "all 13 VP bodies checked"** — missed the §Lifecycle table in its own file (F-P174-506).
4. **`capabilities-p1-p2` v1.13 "zero additional hits" on stale-delegation sweep** — 5 surviving sites (F-P174-403).
5. **`test-vectors.md`** — STATE.md claims v2.8/675; file is v2.7/674, last bumped burst-253. **Orchestrator adjudication (D-39):** the registry is the stale artifact. BC-2.21.003 v1.8 genuinely carries EC-006 + TV-006 + the `!norm.is_finite()` guard; correct total is 675. Fix = bump `test-vectors.md` to v2.8/675; do NOT lower the baseline to 674.
6. **BC-2.07.002 v1.5** claims `input-hash` updated to `ea9cf4b`; frontmatter still shows `6a04860` (F-P174-758). Survived because this file has no frontmatter `changelog:` key → invisible to gate (see CRIT 9).

---

## The Structural Finding: Gates Scoped by Label Are Blind to Dialect Variants

**PRIMARY CONCLUSION of this pass.** Confirmed at six independent sites:

1. `verify-form-a-changelog-direction` PASSes 6 unverifiable files, reports `UNVERIFIED=0` (CRIT 9).
2. Gate #25 records "both difference sets empty" when the reverse set provably has 7 members (crate-level registry rows: `ferrochain-openai`, `ferrochain-anthropic`, `ferrochain-ollama`, `ferrochain-macros`, `ferrochain-standard-tests`, `xtask`, `ferrochain-community`). Cause: census keys on Qualifier label `ROLL-UP`, which appears 0× in `module-criticality.md` (actual vocabulary is `crate-level — …`), so `roll_up_row_count` is uncomputable and the gap is re-asserted empty each burst. Gate also says "sextuple" while specifying a ten-member vector, so blocking identities 0 and 1a have never been evaluated (F-P174-621/622/623).
3. `verify-module-canonicality` prints a promotion-path narrative demanding fixes for 36/13/13 non-canonical cells while the measured count is 0 and all 6 CHECK4 targets PASS — promotion trigger met, never promoted (F-ORCH-174-02 / F-P174-109).
4. `records-lint` L9/L10/L11 emit WARN on a clean tree (false-confidence equivalent).
5. The F-P96-01 Traceability sweep normalized to `Module` and was structurally blind to the `Architecture Module` dialect → 13 files retain "(filled by architect)" for already-filled values; 19 files carry the divergent label (F-P174-705).
6. The `observability.md` prose-emission census greps `WARN`/`WARNING`/`log.*emitted` — cannot match `"One DEBUG log:"` — so every DEBUG-level emission across all 129 BCs was invisible to a sweep recorded as complete corpus-wide (F-P174-804).

**Consequence for BC-5.39.001:** the 3-CLEAN streak has been computed against a ledger that overstates its own state. Content fixes are unverifiable while gates report PASS for what they do not examine. **Process-gap gates must be fixed FIRST in the remediation sequence.**

**Second structural finding:** The densest defects sit in BC files LEAST touched by prior passes — BC-2.21.001 (v1.0), BC-2.19.002 (v1.1), BC-2.20.001 (v1.1), BC-2.20.003 (v1.2). Prior passes concentrated on frequently-amended files. Combined with gate blindness, this explains how the corpus accumulated defects of this severity across 174 passes.

---

## Four Ratified-Decision Sweeps Found Incomplete

### D-37 (`DegenerateNormEmbedding`)
7+ files remain: ADR-010, ADR-014, `purity-boundary-map`, `module-decomposition`, `verification-coverage-matrix`, `prd.md` §5, VP-009 title/prose, plus the E-VS-004 write-time sibling (F-P174-955).

### D-35 (xtask `check-<subject>`)
~20 sites / 8+ files. `check-no-panic` appears NOWHERE in the corpus. Gate NE-04 has THREE live names (`deny-client-new`, `lint-no-timeout`, `check-client-timeout`). `module-decomposition.md` contains a blockquote that AUTHORIZES fragmentation ("resolved at implementation time against the governing BC or ADR") — a production-grade violation, and false on its own terms since BC-2.14.004 and BC-2.08.007 disagree with each other.

### D-27 (E-TOOLS-007 = `override_risk` CALL TIME)
Survived 3 closure bursts; still present in ADR-020 Decision 3, CAP-037 (×2), BC-2.23.005 (4 sites: §Description, §Preconditions 3, TV-005, TV-006).

### `#[non_exhaustive]`
Applied only to D21/D23-era artifacts. 8 public types unmarked across ADR-003/005/006/009; ~24 unmarked in `interface-definitions.md` vs ~12 marked; `Category` never declared either way while `Component` is.

---

## Seventeen Process-Gap Findings

### Recommended standing-gate additions

1. Diff changelog claims against body reality — catches false closures (6 found).
2. Require frontmatter `changelog:` on every BC; report UNVERIFIED (never PASS) for files without it (6 currently unverifiable).
3. Scope sweeps by VALUE pattern, not field label — prevents dialect-blindness.
4. Extend emission census to DEBUG/INFO/TRACE/`emitted` terms beyond WARN/WARNING.
5. Gate #25: rename "sextuple" → ten-member vector; re-key `roll_up_row_count` on literal `crate-level`; make the reverse difference set a load-bearing equation (`registry_distinct_modules − matched_rows == crate_level_row_count`).
6. Promote `verify-module-canonicality` to blocking (trigger already met); refresh its stale narrative.
7. BC frontmatter schema: require boolean `red_gate` + `vp_seed`; `red_gate_source` when `red_gate: true`; `vp_id` when `vp_seed: true` (F-P174-983 — a typo'd key currently reads as false with no failure: census-corruption vector on the most security-critical classification).
8. ADR frontmatter schema: two version schemes coexist (`rev-N` vs semver); `date`/`superseded_by`/`subsystems_affected` absent from ADR-002/003/004/008; three null spellings (`null`, `~`, `[]`).
9. Semantic (not existence-only) ADR-Decision citation check — 4 confirmed semantic mis-anchors: FM-015→Decision 4 (should be 3); BC-INDEX VP-011→Decision 1 (should be 3); `interface-definitions` §PreToolCallHook (2 wrong of 3 on one line); VP-012→ADR-009/ADR-019 Decision 1 vs 3.
10. Reject `*` in cited ADR paths — 4 glob citations survived the anchor validator.
11. Cross-document symbol registration: every `pub trait` in `interface-definitions` must have exactly one `api-surface` row; every error code must have exactly one of three dispositions with census recomputed, not hand-maintained.
12. Stale open-delegation residue grep (`PO BC obligation`, `must author`, `route to architect`) after a named BC reaches `active` — 5th recurrence this pass.
13. Enumerated `#[non_exhaustive]` expected-symbol list — ADR-010 already instructs maintaining one that does not exist.
14. Pre-commit validator gate — burst-276-content-1 and burst-276-signatures both shipped with a validator failing, unconsulted.
15. ADR-010's casing rendering rule is self-contradictory — offers `category: DURABILITY` (Rust struct-initializer syntax) as an example of permitted "prose" form; no linter can enforce it; restate syntactically.
16. Red Gate §Lifecycle rows must be conditional on `red_gate: true` — VP-011/012/013 carry `red_gate: false` + 2 Red Gate lifecycle rows each; VP-006 is `red_gate: true` with none.
17. Positive-coverage assertions must be runtime-computed and non-zero — empty registries currently pass silently.

---

## Coverage Debts (must be closed before any CLEAN claim under D-32)

- **Slice 5:** VP-002, VP-003, VP-004, VP-005, VP-007, VP-008 bodies verified only for frontmatter, harness-name resolution, and the `red_gate`/§Lifecycle axis — §Property Statement / §Formal Invariant / §BC Traceability NOT read line-by-line.
- **Slice 9a:** 8 of 22 files received targeted-pattern probe only — BC-2.15.004, BC-2.15.006, BC-2.16.002, BC-2.17.002, BC-2.18.001, BC-2.18.002, BC-2.18.003, BC-2.18.005. The `retry_hint` wrapper-form sweep proposed in F-P174-908 is unverified scope, not confirmed-clean.
- **Slice 8b:** ss-12 BC-2.12.001/002/005/007 received targeted grep only.
- **Slice 6b:** `product-brief.md` and `capabilities-p1-p2.md` NOT reviewed (they live at `specs/` and `specs/domain-spec/`, not `prd-supplements/` — orchestrator dispatch error).
- **Slice 6b:** 36 of 37 standing gates verified for count/numbering continuity only; only gate #25 audited body-deep.

---

## Verified-Genuine Prior Closures

The following are confirmed CLOSED and must not be re-derived as findings by future passes:

- F-P159-01 (SS-15 body Traceability P1/Wave-1)
- F-P169-01
- F-P158-01 (`circuit_breaker_disabled` correctly has no `tool_name`)
- F-P148-02
- F-P173-601 (`PathGuard::check` purge complete for that symbol)
- `observability.md` v1.7 (all 11 `Emitting-Module` cells resolve)
- BC-2.04.001 Inv-5 checkpoint-append-only
- ADR-020 macro-binding deletion (D-24)

---

## Validator Baselines at Frozen HEAD `cd0a2c7` (all 11 PASS, zero regressions)

| Validator | Result | Notes |
|-----------|--------|-------|
| records-lint | PASS=2 WARN=3 | clean tree, expected |
| verify-form-a-changelog-direction | PASS=198 WARN=4 FAIL=0 UNVERIFIED=0 | **6 vacuous PASSes — see CRIT 9** |
| verify-no-version-pins | PASS=198 | |
| verify-arch-anchor-resolution | PASS=129 | |
| verify-enum-variant-casing | PASS=198 | |
| verify-adr-decision-refs | PASS=308 (blocking) | |
| verify-module-canonicality | PASS=6 WARN=5, 0 non-canonical cells | promotion trigger met but not promoted |
| verify-changelog-date-monotonicity | PASS=131 WARN=75 | |
| verify-sha-currency | PASS=2 WARN=1 | |
| verify-red-gate-consistency | PASS=40 WARN=3 | Direction-3: VP-011/012/013 |
| verify-adr-self-version-refs | advisory | |

---

## Orchestrator Self-Attributed Defects (this session)

1. Imprecise `Category` casing rubric issued to slices — told them PascalCase; corpus canon is bare taxonomy codes in prose/table cells, PascalCase only inside Rust syntax. Slices 4 and 7a both correctly pushed back and deferred to corpus canon.
2. Misfiled `api-surface.md` under `prd-supplements/`; it lives at `specs/architecture/`.
3. Told slice 9a that SS-18 is memory; SS-18 is prompt templates (`ferrochain-prompts`), memory is SS-15. Agent located the correct subsystem and audited it correctly.
4. Slice 6b dispatch listed `product-brief.md` and `capabilities-p1-p2.md` as being in `prd-supplements/`; they are not — both went unreviewed.
5. Five slices dispatched at a size that ran ~13 minutes and died on transient API failure; work unrecoverable because the adversary cannot write files (D-40 adopted to prevent recurrence).

---

## Fix-Burst 277 Sequencing Mandate

Per the structural finding (gates scoped by label → validator suite certifies unmeasured state):

1. **FIRST:** Process-gap gates (validator false-confidence family, gate #25 re-keying on `crate-level` dialect, changelog-vs-body diff check). Content fixes are unverifiable until these are live.
2. **SECOND:** `FerrochainError` constructor (F-P174-601/901) + `Tool` object-safety adjudication (F-P174-801/615). Many downstream fixes depend on these structural resolutions.
3. **THIRD:** Content fixes in priority order (CRIT → HIGH → MED), routing per the Agent Routing Table in CLAUDE.md.
