---
document_type: adversarial-review-pass
phase: 1d
pass: 28
verdict: NOT CLEAN
findings_count: 1
high_count: 0
med_count: 1
low_count: 0
observations_count: 3
consecutive_clean: 0
required_clean: 3
trajectory: "...→7→5→6→1"
timestamp: 2026-07-14T00:00:00Z
new_class: "RetryHint category-default vs per-code coherence"
---

# Adversarial Review Pass 28 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (1 MED) + 3 observations. Counter reset: 0/3 consecutive clean.

---

## F-P28-01 [MED] — RetryHint Category-Default vs Per-Code Contradiction (5 codes)

**Finding class:** RetryHint category-default vs per-code coherence (new class this pass).

**Scope:**
- `prd-supplements/error-taxonomy.md` lines ~30-39: Error Category Codes table presents `RetryHint` as a category property (DURABILITY=Maybe, POLICY=Never)
- 5 per-code catalog rows diverge from their category default:
  - E-RETRY-003 (POLICY) carries `Later(<reset_timeout>)` — POLICY default is `Never`
  - E-CRON-003 (POLICY) carries `Later` — POLICY default is `Never`
  - E-MEMORY-002 (DURABILITY) carries `Never` — DURABILITY default is `Maybe`
  - E-MEMORY-005 (DURABILITY) carries `Never` — DURABILITY default is `Maybe`
  - E-BUDGET-002 (DURABILITY) carries `Never` — DURABILITY default is `Maybe`

**Finding:**
The category table presents `RetryHint` as a category-level property with no stated precedence rule. A reader consulting the category table for E-RETRY-003 (POLICY) would conclude `Never`, but the per-code row specifies `Later(<reset_timeout>)`. There is no statement in the table or the RetryHint Values section explaining which value is authoritative when they conflict. This ambiguity is systemic across the 5 listed codes.

All 5 divergences are **intentionally correct** at the per-code level:
- E-RETRY-003 / E-CRON-003: circuit-breaker and queue-full conditions are transient states with a known recovery horizon; `Later` is the correct semantics.
- E-MEMORY-002 / E-MEMORY-005 / E-BUDGET-002: storage-full, partial erasure, and journal-write failures are non-recoverable by retry without operator intervention; `Never` correctly overrides the DURABILITY `Maybe` default.

The defect is the missing precedence rule, not the per-code values.

**Fix (completed this burst):**

1. `error-taxonomy.md` (version 1.2 → 1.3):
   - Relabeled category-table `RetryHint` column → `Default RetryHint`.
   - Added precedence blockquote under the category table: "The Default RetryHint column applies only to codes whose per-code catalog row omits a RetryHint. Where a per-code catalog row specifies a RetryHint, the per-code value is authoritative — it overrides the category default. Intentional divergences must carry a BC-anchored rationale."
   - Cited E-RETRY-003 (BC-2.16.003 circuit-breaker cool-down) and E-MEMORY-002/005 / E-BUDGET-002 (non-recoverable storage failures) as examples.
2. `bc-authoring-plan.md` gate #22 (RETRYHINT COHERENCE — new standing gate):
   - Any new/edited per-code E-code row with explicit RetryHint OR any category-table Default RetryHint edit must verify coherence and document intentional divergences with BC-anchored rationale.
   - Known-intentional divergences table added (5 codes as of this pass).

---

## Observations

### OBS-P28-1 — BC-2.12.005 PC4 Inline Fix-Annotation Residue

**Finding:** PC4 of BC-2.12.005 contains the inline annotation `(F-P27-05: removed "(or the configured debug route path)" — the path is fixed at \`/_debug\`; \`debug_route_path\` is NOT a config option per the invariant below.)`. This is residue from the F-P27-05 fix. The fix annotation belongs in the changelog, not in the postcondition body text. Inline annotations in requirement text reduce readability and create noise for test-writers parsing the postcondition.

**Fix applied:** Removed the inline annotation from PC4. The changelog entry for version 1.2 already records it. Version bump 1.2 → 1.3.

### OBS-P28-2 — E-CHKPT-005 Raise-Condition Has No Behavioral Home

**Finding:** E-CHKPT-005 (SessionAddressCollision, TENANCY) is declared in error-taxonomy.md with BC-2.04.006 as its anchor. However, BC-2.04.006 specifies the session triple-address uniqueness invariant and its read/write isolation properties, but none of the existing edge cases (EC-001 through EC-004) describes the specific condition under which E-CHKPT-005 is **raised**. The error code exists in the taxonomy but the behavioral event that triggers it is unspecified in the anchor BC. This is an orphan raise-condition: the error can never be deterministically tested without a specified trigger.

**Fix applied:** Added EC-005 to BC-2.04.006 specifying the raise-condition: a `put` or `put_writes` call whose composite triple `(thread_id, checkpoint_ns, checkpoint_id)` collides with an existing session under a different tenant context, violating the Invariant 1 composite-PK uniqueness constraint at the tenancy boundary → `Err(FerrochainError { category: TENANCY, code: "E-CHKPT-005" })` with variant `SessionAddressCollision`. Version bump 1.1 → 1.2.

### OBS-P28-3 — BC-2.08.003 Refusal Path Constructs Codeless POLICY Error

**Finding:** BC-2.08.003 (Chat Model Structured Output Conformance) specifies the OpenAI `json_schema` refusal path at PC5, Invariant, EC-001, and TV-004 with `FerrochainError { category: POLICY }` — no `code` field. BC-2.14.001 establishes the posture that every `FerrochainError` carries a machine-readable code string. A codeless error:
1. Cannot be pattern-matched by error-code in the dispatch layer
2. Cannot be deterministically looked up in the taxonomy
3. Violates the BC-2.14.001 every-error-has-a-code invariant

**Decision (spec canon):** Mint E-PROV-007 (variant `StructuredOutputRefused`, category POLICY, RetryHint Never, anchor BC-2.08.003). Rationale: the refusal path is provider-internal (OpenAI safety filter); POLICY because the model policy rejected the request, not a deserialization failure; Never because the same prompt will produce the same refusal without prompt or config change.

**Fix applied:**
1. `error-taxonomy.md`: added E-PROV-007 to PROV section with message format `StructuredOutputRefused: model refused to generate structured output — refusal_message: '<message>'`. Correction note explaining: POLICY because model-policy rejection, not deserialization; RetryHint Never (POLICY default; refusal repeats); embedded in Run.error in v1.
2. `BC-2.08.003.md`: added `code: "E-PROV-007"` to all 4 construction sites (PC5, Invariant, EC-001, TV-004). EC-001 updated to note distinguishing by `code` vs by `category`. Version bump 1.0 → 1.1.
3. `interface-definitions.md`: added E-PROV-007 embedded omission note — POLICY→403 categorical fallback; no v1 endpoint emits HTTP 403 directly for this code; intentionally omitted from 403 row. Version bump 1.8 → 1.9.

---

## NEW CLASS: RetryHint Category-Default vs Per-Code Coherence

**Definition:** When a per-code catalog row specifies a RetryHint that diverges from the category-table Default RetryHint for that code's category, without a stated precedence rule, a reader cannot determine which value is authoritative. This produces ambiguity in the error-dispatch and retry-combinator implementations. The class is now caught by gate #22.

**Characteristics:**
- Only occurs in components that have explicit RetryHint columns in their per-code tables (RETRY, CRON, MEMORY, BUDGET — not CORE, GRAPH, CHKPT, SERVER, PROV, MCP, SPLIT, SBXD which use category defaults implicitly)
- Divergences are semantically intentional — the per-code value encodes domain knowledge about the specific failure mode that the category default cannot capture
- The defect is the missing precedence declaration, not the per-code value itself

**Drain status:** All 5 divergent codes documented in bc-authoring-plan.md gate #22 known-intentional-divergences table. Fixed.

**Standing gate added:** bc-authoring-plan.md guideline #22 (RETRYHINT COHERENCE).

---

## BC↔Taxonomy Category Census — PASS (72 Active Codes, Zero Mismatches)

> Census scope: all active (non-retired) error codes in error-taxonomy.md vs their BC anchor's category declaration. Retired codes (~~E-GRAPH-005~~, ~~E-SERVER-001~~) excluded. E-PROV-007 minted this burst — included as PASS (BC-2.08.003 uses POLICY throughout; taxonomy entry is POLICY).

| Error Code | Category | BC Anchor | Verdict |
|-----------|----------|-----------|---------|
| E-CORE-001 | VAL | BC-2.01.001 | PASS |
| E-CORE-002 | VAL | BC-2.01.002 | PASS |
| E-CORE-003 | VAL | BC-2.01.003 | PASS |
| E-CORE-004 | INTERNAL | BC-2.01.004 | PASS |
| E-CORE-005 | VAL | BC-2.14.006 | PASS |
| E-GRAPH-001 | CONCURRENCY | BC-2.03.002 | PASS |
| E-GRAPH-002 | POLICY | BC-2.05.005 | PASS |
| E-GRAPH-003 | VAL | BC-2.02.005 | PASS |
| E-GRAPH-004 | VAL | BC-2.02.003 | PASS |
| E-GRAPH-006 | INTERNAL | BC-2.03.001 | PASS |
| E-GRAPH-007 | VAL | BC-2.02.001 | PASS |
| E-GRAPH-008 | VAL | BC-2.02.001 | PASS |
| E-GRAPH-009 | VAL | BC-2.02.001 | PASS |
| E-GRAPH-010 | VAL | BC-2.02.003 | PASS |
| E-GRAPH-011 | INTERNAL | BC-2.02.005 | PASS |
| E-GRAPH-012 | VAL | BC-2.02.005 | PASS |
| E-GRAPH-013 | SECURITY | BC-2.05.006 | PASS |
| E-GRAPH-014 | POLICY | BC-2.05.006 | PASS |
| E-GRAPH-015 | VAL | BC-2.05.004 | PASS |
| E-GRAPH-016 | POLICY | BC-2.05.001 | PASS |
| E-CHKPT-001 | DURABILITY | BC-2.04.001 | PASS |
| E-CHKPT-002 | INTERNAL | BC-2.04.003 | PASS |
| E-CHKPT-003 | DURABILITY | BC-2.04.005 | PASS |
| E-CHKPT-004 | INTERNAL | BC-2.04.007 | PASS (corrected P27: was SECURITY→INTERNAL) |
| E-CHKPT-005 | TENANCY | BC-2.04.006 | PASS |
| E-CHKPT-006 | INTERNAL | BC-2.05.001 | PASS |
| E-SERVER-002 | VAL | BC-2.12.003 | PASS |
| E-SERVER-003 | VAL | BC-2.12.001 | PASS |
| E-SERVER-004 | POLICY | BC-2.12.005 | PASS (corrected P25: was AUTH→POLICY) |
| E-SERVER-005 | POLICY | BC-2.12.005 | PASS |
| E-SERVER-006 | VAL | BC-2.12.004 | PASS |
| E-SERVER-007 | CONCURRENCY | BC-2.12.001 | PASS |
| E-SERVER-008 | POLICY | BC-2.12.001 | PASS |
| E-SERVER-009 | VAL | BC-2.12.002 | PASS |
| E-SERVER-010 | VAL | BC-2.12.002 | PASS |
| E-SERVER-011 | VAL | BC-2.12.002 | PASS |
| E-SERVER-012 | CONCURRENCY | BC-2.12.003 | PASS |
| E-SERVER-013 | VAL | BC-2.12.005 | PASS |
| E-SERVER-014 | DURABILITY | BC-2.12.006 | PASS |
| E-SERVER-015 | CONCURRENCY | BC-2.12.007 | PASS |
| E-SERVER-016 | TIMEOUT | BC-2.12.006 | PASS |
| E-PROV-001 | RATE | BC-2.08.004 | PASS |
| E-PROV-002 | TIMEOUT | BC-2.08.007 | PASS |
| E-PROV-003 | TRANSPORT | BC-2.08.007 | PASS |
| E-PROV-004 | AUTH | BC-2.08.004 | PASS |
| E-PROV-005 | VAL | BC-2.08.003 | PASS |
| E-PROV-006 | VAL | BC-2.08.004 | PASS |
| E-PROV-007 | POLICY | BC-2.08.003 | PASS (minted this burst; all 4 BC construction sites use POLICY) |
| E-MCP-001 | TOOL | BC-2.09.004 | PASS |
| E-MCP-002 | TRANSPORT | BC-2.09.001 | PASS |
| E-MCP-003 | VAL | BC-2.09.005 | PASS |
| E-MCP-004 | VAL | BC-2.09.002 | PASS |
| E-SPLIT-001 | VAL | BC-2.07.001 | PASS |
| E-SPLIT-002 | VAL | BC-2.07.001 | PASS |
| E-SBXD-001 | SECURITY | BC-2.13.005 | PASS |
| E-SBXD-002 | POLICY | BC-2.13.003 | PASS |
| E-SBXD-003 | INTERNAL | BC-2.13.001 | PASS |
| E-SBXD-004 | POLICY | BC-2.13.006 | PASS |
| E-SBXD-005 | INTERNAL | BC-2.13.006 | PASS |
| E-RETRY-001 | POLICY | BC-2.16.001 | PASS |
| E-RETRY-002 | POLICY | BC-2.16.002 | PASS |
| E-RETRY-003 | POLICY | BC-2.16.003 | PASS (RetryHint Later diverges from POLICY Never default — intentional, gate #22 documented) |
| E-CRON-001 | VAL | BC-2.12.004 | PASS |
| E-CRON-002 | VAL | BC-2.12.004 | PASS |
| E-CRON-003 | POLICY | BC-2.12.004 | PASS (RetryHint Later diverges from POLICY Never default — intentional, gate #22 documented) |
| E-MEMORY-001 | VAL | BC-2.15.001 | PASS |
| E-MEMORY-002 | DURABILITY | BC-2.15.001 | PASS (RetryHint Never diverges from DURABILITY Maybe default — intentional, gate #22 documented) |
| E-MEMORY-003 | POLICY | BC-2.15.002 | PASS |
| E-MEMORY-004 | VAL | BC-2.15.002 | PASS |
| E-MEMORY-005 | DURABILITY | BC-2.15.003 | PASS (RetryHint Never diverges from DURABILITY Maybe default — intentional, gate #22 documented) |
| E-MEMORY-006 | POLICY | BC-2.15.003 | PASS |
| E-BUDGET-001 | POLICY | BC-2.10.003 | PASS |
| E-BUDGET-002 | DURABILITY | BC-2.10.002 | PASS (RetryHint Never diverges from DURABILITY Maybe default — intentional, gate #22 documented) |

**Census result: 73 active codes (72 pre-burst + E-PROV-007 minted this burst), ZERO category mismatches.** The F-P28-01 finding is RetryHint coherence only — no category authority conflicts.

---

## Sibling Reverse-Anchor Check

No BCs added or retired this burst. One EC added (EC-005 in BC-2.04.006), one E-code minted (E-PROV-007). BC count unchanged at P0 48 + P1 30 + P2 8 = 86 total.

**(a) BC version bumps consistent with changelog entries:**
- BC-2.12.005: 1.2 → 1.3 ✓ (OBS-P28-1 annotation residue removal)
- BC-2.04.006: 1.1 → 1.2 ✓ (OBS-P28-2 EC-005 added)
- BC-2.08.003: 1.0 → 1.1 ✓ (OBS-P28-3 E-PROV-007 code literals added)

**(b) E-PROV-007 anchor BC-2.08.003 citations consistent across all 4 construction sites:**
- PC5 line ~72: `code: "E-PROV-007"` present ✓
- Invariant line ~84: `code: "E-PROV-007"` present ✓
- EC-001 line ~92: `code: "E-PROV-007"` present ✓
- TV-004 line ~126: `code: "E-PROV-007"` present ✓

**(c) EC-005 in BC-2.04.006 cites E-CHKPT-005 with correct category TENANCY:**
`category: TENANCY, code: "E-CHKPT-005"` ✓

**(d) E-PROV-007 taxonomy category POLICY matches all BC construction sites (category: POLICY):** ✓

**(e) interface-definitions.md E-PROV-007 omission note present and 403 row NOT modified (embedded treatment):** ✓

**(f) bc-authoring-plan.md gate #22 added with known-intentional-divergences table (5 codes):** ✓

---

## Rotated Census Results (4 Selected)

| Census | Command | Result |
|--------|---------|--------|
| Retired-identifier residue (#19) | `grep -rn "to_problem_detail\|risk_tier\|X-Debug-Key" .factory/specs/ \| grep -v "~~\|changelog\|Census command\|retired.*list\|Retired Identifier\|action_risk.rs"` | PASS — no live occurrences; only changelog and registry rows |
| E-code↔variant-name census (#16) | `grep -hrn "E-[A-Z]*-[0-9]\{3\} [A-Z][A-Za-z]*" .factory/specs/behavioral-contracts/` — E-PROV-007 StructuredOutputRefused new pairing | PASS — taxonomy row and all 4 BC construction sites use StructuredOutputRefused variant name consistently |
| AUTH/POLICY category re-sweep (#20) | E-PROV-007 POLICY category — categorical POLICY→403; embedded in Run.error; no direct HTTP 403 surfacing | PASS — POLICY→403 categorical fallback; omission note added to interface-definitions.md; 403 row not modified (not a direct HTTP response) |
| HTTP status-code table edit → census re-run (#21) | interface-definitions.md version 1.8→1.9: only omission note added (no row changes to §HTTP Status Codes table) | PASS — no row add/remove/narrowing/widening; only blockquote omission note appended; §17-C census re-run not triggered (census trigger is row edits, not note additions) |

---

## Novelty Assessment

**Classification: LOW-TO-MEDIUM severity.**

**Trajectory context:** Pass counts: ...→7 (P25)→5 (P26)→6 (P27)→1 (P28). Finding count continues declining. Pass 28 has the lowest finding count in the history of this phase (1 MED, 0 HIGH, 0 LOW).

**New class assessment:** The RetryHint category-default vs per-code coherence class is genuinely new — not a subtype of any prior class. However, it is LOW-MEDIUM severity because:
- The divergences are all intentionally correct at the per-code level
- The defect is missing documentation, not incorrect behavior
- The fix is a clarity improvement (precedence rule + gate), not a semantic correction
- The class is unlikely to recur (gate #22 now enforces documentation)

**Deep convergence signal:** Three consecutive passes have produced no HIGH findings. The spec is reaching a stable state. Key outstanding risk: hidden divergences in newer BCs (ss-15, ss-16 especially) that haven't been deeply censused for error-code completeness. Recommend a targeted scan of BCs added in the last 5 bursts for codeless error constructions (pattern: `FerrochainError {` without `code:`).

---

## Fix Records (Post-Application)

| Finding | File | Change | Status |
|---------|------|--------|--------|
| F-P28-01 | error-taxonomy.md | Category-table `RetryHint` → `Default RetryHint`; precedence blockquote added; v1.2→1.3 | APPLIED |
| F-P28-01 | bc-authoring-plan.md | Gate #22 (RETRYHINT COHERENCE) added with 5-code known-intentional-divergences table | APPLIED |
| OBS-P28-1 | BC-2.12.005.md | PC4 inline F-P27-05 annotation removed; v1.2→1.3 | APPLIED |
| OBS-P28-2 | BC-2.04.006.md | EC-005 (SessionAddressCollision raise-condition) added to edge cases table; changelog field added; v1.1→1.2 | APPLIED |
| OBS-P28-3 | error-taxonomy.md | E-PROV-007 (StructuredOutputRefused, POLICY, Never) added to PROV section; inline rationale note | APPLIED |
| OBS-P28-3 | BC-2.08.003.md | `code: "E-PROV-007"` added to PC5, Invariant, EC-001, TV-004; changelog field added; v1.0→1.1 | APPLIED |
| OBS-P28-3 | interface-definitions.md | E-PROV-007 embedded omission note added (POLICY→403 categorical fallback, embedded in Run.error); v1.8→1.9 | APPLIED |

---

## Post-Fix Verification

| Check | Command | Result |
|-------|---------|--------|
| Default RetryHint column and precedence rule | `grep -n "Default RetryHint\|per-code value is authoritative" error-taxonomy.md` | PASS — column renamed (line 31); precedence rule present (line 46) |
| Configured debug route path drained from BC body | `grep -rn "configured debug route path" .factory/specs/ \| grep -v "~~\|changelog\|removed stale"` | PASS — zero live occurrences; only changelog reference |
| E-CHKPT-005 EC-005 in BC-2.04.006 | `grep -n "E-CHKPT-005" BC-2.04.006.md` | PASS — EC-005 row present (line 90) with raise-condition |
| E-PROV-007 in taxonomy | `grep -n "E-PROV-007" error-taxonomy.md` | PASS — taxonomy row line 154; changelog line 11 |
| E-PROV-007 in BC-2.08.003 (4 sites) | `grep -n "E-PROV-007" BC-2.08.003.md` | PASS — changelog (line 19), PC5 (line 72), Invariant (line 84), EC-001 (line 92), TV-004 (line 126) |
| E-PROV-007 omission note in interface-definitions.md | `grep -n "E-PROV-007" interface-definitions.md` | PASS — changelog (line 13) and omission note (line 230) |
| Gate #22 in bc-authoring-plan.md | `grep -n "gate #22\|RETRYHINT COHERENCE" bc-authoring-plan.md` | PASS — line 589 |
| Category census coherence: E-PROV-007 POLICY literal | `grep -n "category: POLICY" BC-2.08.003.md` (4 results) vs `grep -n "E-PROV-007.*POLICY" error-taxonomy.md` | PASS — all 4 BC construction sites use POLICY; taxonomy row is POLICY |
