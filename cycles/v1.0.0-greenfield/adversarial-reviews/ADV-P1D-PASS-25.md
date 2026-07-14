---
document_type: adversarial-review-pass
phase: 1d
pass: 25
verdict: NOT CLEAN
findings_count: 7
high_count: 3
med_count: 4
observations_count: 3
consecutive_clean: 0
required_clean: 3
trajectory: "...→1→1→2→7"
timestamp: 2026-07-14T00:00:00Z
new_class: "HTTP-status dual-authority incoherence"
---

# Adversarial Review Pass 25 — Phase 1d

**Verdict: NOT CLEAN** — 7 findings (3 HIGH, 4 MED) + 3 observations. Counter reset: 0/3 consecutive clean.

---

## F-P25-01 [HIGH] — E-SERVER-016 Three-Way HTTP Status Contradiction

**Finding class:** HTTP-status dual-authority incoherence (new class this pass).

**Scope:** 3 files:
- `behavioral-contracts/ss-12/BC-2.12.006.md` EC-002 (lines ~116-117) — HTTP 503 for E-SERVER-016 IdempotencyLockTimeout
- `behavioral-contracts/ss-14/BC-2.14.002.md` PC3 — Category::Timeout → 504 (no per-code carve-out)
- `prd-supplements/interface-definitions.md` §HTTP Status Codes (lines ~199-210) — neither 503 nor 504 row present for IdempotencyLockTimeout

**Finding:**
BC-2.12.006 EC-002 specified HTTP 503 for IdempotencyLockTimeout. BC-2.14.002 PC3 mapped Category::Timeout → 504 with an invariant asserting "must not diverge." interface-definitions.md had no 503 or 504 row at all. Three-way incoherence: one BC said 503, another BC's categorical rule implied 504, and the interface table was silent.

**Decision:** canonical status = **503** (BC-2.12.006 EC-002 is authoritative; E-SERVER-016 is a server-side lock-serialization timeout, not an upstream gateway timeout — 503 Service Unavailable with Retry-After is semantically correct; 504 Gateway Timeout would mislead clients into thinking an upstream proxy is involved).

**Fix (completed this pass):**

1. `interface-definitions.md` §HTTP Status Codes:
   - Added `503 | Service temporarily unavailable (retryable store/lock timeout) | E-SERVER-016 (IdempotencyLockTimeout); Retry-After header present; per-endpoint override over categorical Timeout→504 (F-P25-01; BC-2.12.006 EC-002; BC-2.14.002 PC3 carve-out)`.
2. `BC-2.14.002.md` PC3:
   - Added "Per-endpoint status overrides" block documenting E-SERVER-016 → 503 as an explicit carve-out. Categorical Timeout→504 remains the fallback for other TIMEOUT codes.

---

## F-P25-02 [HIGH] — E-SERVER-004 Dual-Status 401+403 Contradicts BC-2.12.005

**Finding class:** HTTP-status dual-authority incoherence.

**Scope:** 3 files:
- `prd-supplements/interface-definitions.md` line ~204 — E-SERVER-004 under 401 row
- `prd-supplements/interface-definitions.md` line ~205 — E-SERVER-004 under 403 row
- `prd-supplements/error-taxonomy.md` line ~117 — E-SERVER-004 category AUTH (Category::Auth → 401)

**Finding:**
E-SERVER-004 (DebugRouteUnauthorized) appeared in both the 401 and 403 rows of the HTTP status table. The taxonomy categorized it as AUTH (which maps to 401 via BC-2.14.002 PC3). However BC-2.12.005 PC4 + EC-002 are unambiguous: `GET /_debug` returns `403 Forbidden` — not 401. The debug route is a capability gate (route inaccessible without explicit operator opt-in config), not a credential authentication failure. Returning 401 would suggest the caller should send credentials; 403 is the correct "you are not permitted" response regardless of credentials.

**Decision:** recategorize E-SERVER-004 AUTH → **POLICY** (Category::Policy → 403). BC-2.12.005 is authoritative. The 401 row is reserved for v1 with a note (no current E-code maps there).

**Fix (completed this pass):**

1. `error-taxonomy.md` §Component SERVER:
   - Changed E-SERVER-004 category from `AUTH` to `POLICY`.
   - Added inline correction note explaining the recategorization.
2. `interface-definitions.md` §HTTP Status Codes:
   - Removed E-SERVER-004 from the 401 row.
   - 401 row now reads: `reserved — no current E-code maps here; authentication middleware is out of v1 scope (F-P25-02: E-SERVER-004 recategorized AUTH→POLICY → 403)`.
   - 403 row now lists: `E-SERVER-004 (DebugRouteUnauthorized), E-SERVER-005 (CorsRejected)`.

---

## F-P25-03 [HIGH] — entities-server.md FerrochainError `code: u32` vs String Codes

**Finding class:** Type-representation drift (wire type vs domain entity).

**Scope:** `domain-spec/entities-server.md` line ~108 — `code: u32`.

**Finding:**
The FerrochainError entity in entities-server.md declared `code: u32`. All authoritative sources use string codes:
- BC-2.14.001 (authoritative): `code: &'static str`
- api-surface.md line ~119: `code: &'static str`
- error-taxonomy.md: all codes are strings ("E-CORE-001", "E-GRAPH-001", etc.)

`u32` is incoherent — it has no defined encoding for string codes like "E-SERVER-016".

**Decision:** change to `code: String` (wire representation; Rust: `&'static str` per api-surface.md). BCs are authoritative.

**Fix (completed this pass):**

1. `entities-server.md` §FerrochainError Fields:
   - Changed `code: u32` to `code: String (wire representation; Rust: \`&'static str\` per api-surface.md — e.g. \`"E-CORE-001"\`; fixed F-P25-03 from incorrect \`u32\`)`.

---

## F-P25-04 [MED] — api-surface.md Method Name Drift: `to_problem_detail()` vs `to_problem()`

**Finding class:** API method name drift.

**Scope:** `architecture/api-surface.md` line ~124.

**Finding:**
api-surface.md line ~124 referenced `FerrochainError::to_problem_detail()`. BC-2.14.002 PC1 (authoritative) uses `to_problem()` throughout. The method name drift would cause implementers following api-surface.md to implement the wrong method name.

**Fix (completed this pass):**

1. `api-surface.md` §Error Type:
   - Changed `FerrochainError::to_problem_detail()` to `FerrochainError::to_problem()` with correction note referencing F-P25-04 and BC-2.14.002 as authoritative.

---

## F-P25-05 [MED] — InterruptPayload Identifier Field: `interrupt_id` vs `id`

**Finding class:** Field name drift across BCs.

**Scope:** `behavioral-contracts/ss-05/BC-2.05.004.md` PC4 (lines ~48-49).

**Finding:**
BC-2.05.004 PC4 used both `interrupt_id` (in the command form `Command(resume={interrupt_id: value})`) and "the `id` field" (in the description of what it must match). BC-2.05.001 TV-001 and entities-server.md §Interrupt both use `interrupt_id` as the canonical field name. The "id field" wording would cause implementers to look for a field called `id` in the InterruptPayload struct.

**Fix (completed this pass):**

1. `BC-2.05.004.md` PC4:
   - Changed "the `id` field" to "the `interrupt_id` field".
   - Added authority citation: BC-2.05.001 TV-001 and entities-server.md §Interrupt.

---

## F-P25-06 [MED] — Run.interrupt Embedded Wire Object Sub-Fields Incoherent

**Finding class:** Wire-object sub-field coherence (extends P24 new class).

**Scope:** `prd-supplements/interface-definitions.md` lines ~244-256: Run.interrupt schema sub-fields.

**Finding:**
The interface-definitions.md Run.interrupt sub-object had:
- `node_id` — but entities-server.md §Interrupt uses `node_name`
- `risk_tier` — but BC-2.05.006 HitlInterruptPayload uses `action_risk`
- Missing `interrupt_id` (present in BC-2.05.001 TV-001 and entities-server.md §Interrupt)
- Missing `value` (the interrupt payload value, present in BC-2.05.001 PC4)
- Missing `action` and `context` (present in BC-2.05.006 HitlInterruptPayload)

Three authorities:
- BC-2.05.001 InterruptPayload: `{ value, interrupt_id }`
- BC-2.05.006 HitlInterruptPayload: `{ action_risk, action, context }`
- entities-server.md §Interrupt entity: `{ interrupt_id, run_id, node_name, scratchpad, created_at }`

All three were contradicted by the interface schema.

**Fix (completed this pass):**

1. `interface-definitions.md` §Run Object Schema, interrupt sub-object:
   - `node_id` → `node_name` (canonical per entities-server.md §Interrupt)
   - `risk_tier` → `action_risk` (canonical per BC-2.05.006 HitlInterruptPayload)
   - Added `interrupt_id` property (BC-2.05.001 TV-001, entities-server.md)
   - Added `value` property (BC-2.05.001 PC4)
   - Added `action` property (BC-2.05.006 HitlInterruptPayload; nullable for non-HITL interrupts)
   - Added `context` property (BC-2.05.006 HitlInterruptPayload; nullable for non-HITL interrupts)
   - Retained `super_step` and `scratchpad`
2. `bc-authoring-plan.md` guideline #18:
   - Extended the census trigger clause with a **Sub-field coherence extension** requiring that embedded sub-objects (Run.interrupt, Run.error) receive the same three-way field-set census as top-level objects.
   - Documented the canonical Run.interrupt and Run.error sub-field authorities.

---

## F-P25-07 [MED] — Status Table Missing 201/204 Rows + E-CRON-002; §17-C Census Falsely PASS [process-gap]

**Finding class:** Status table completeness + process-gap (inert census rule).

**Scope:**
- `prd-supplements/interface-definitions.md` §HTTP Status Codes — missing 201, 204 rows; 400 row lacked E-CRON-002
- `prd-supplements/bc-authoring-plan.md` §17-C census table — marked 201, 204, E-CRON-002 as PASS against a table where they didn't exist

**Finding:**
interface-definitions.md §HTTP Status Codes lacked rows for:
- 201 (used by BC-2.12.001 PC5, BC-2.12.002 PC4, BC-2.12.004 TV-001 — POST resource creation)
- 204 (used by BC-2.12.001:70, BC-2.12.002:71, BC-2.12.003:122, BC-2.12.004:65 — DELETE success)
- E-CRON-002 InvalidCronExpression→400 (BC-2.12.004 EC-002/TV-006)

bc-authoring-plan.md §17-C census marked all three as PASS. But 201 and 204 rows did not exist in the table, and E-CRON-002 was not listed under 400. The census was inert — it claimed PASS for values that could not have been verified by inspection of the table. **[process-gap]**

**Fix (completed this pass):**

1. `interface-definitions.md` §HTTP Status Codes:
   - Added `201 | Created (new resource; body contains created object) | —` row.
   - Added `204 | No Content (delete success; no response body) | —` row.
   - Added `E-CRON-002 (InvalidCronExpression)` to the 400 row.
2. `bc-authoring-plan.md` §17-C:
   - Added **Positive-coverage assertion** clause: every PASS row must be grep-verifiable in interface-definitions.md §HTTP Status Codes. Census command documented.
   - Added 503 row (E-SERVER-016) to the census table.
   - Annotated 201, 204, E-CRON-002 as "(added iface-def P25)".

---

## Observations (non-blocking)

### OBS-1: BC-2.14.002 "Must Not Diverge" Invariant Needs Precedence Carve-Out [process-gap]

BC-2.14.002 final invariant said "must not diverge from the table above." But legitimate per-endpoint divergences exist (E-SERVER-016 TIMEOUT→503 not 504; E-SERVER-009 VAL→404 for direct lookup; E-SERVER-004 POLICY→403 debug route). Without a carve-out, F-P25-01 and F-P25-02 fixes create apparent violations of BC-2.14.002's own invariant. **[process-gap]**

**Fix:** Amended BC-2.14.002 final invariant to: "A per-endpoint status specified in a resource BC overrides the categorical default; the categorical map is the fallback for errors with no per-endpoint specification. Legitimate per-endpoint divergences must be documented in PC3 and interface-definitions.md §HTTP Status Codes."

### OBS-2: Provider Timeout→504 / Transport→502 Have No Interface Table Rows

E-PROV-002 (ProviderTimeout → categorical 504) and E-PROV-003 (StreamInterrupted → categorical 502) were not in the HTTP status table. These codes surface embedded in Run.error (not as direct HTTP response codes) but the table had no coverage.

**Fix:** Added 502 and 504 rows to interface-definitions.md §HTTP Status Codes annotated "categorical fallback only; no v1 endpoint emits directly as terminal HTTP status; surfaced embedded in Run.error."

### OBS-3: VP-INDEX Arithmetic — PASS (no action required)

VP-INDEX arithmetic was verified as consistent with current BC count. No changes needed. Recorded as PASS observation.

---

## NEW CLASS: HTTP-Status Dual-Authority Incoherence

**Class definition:** Any error code that has an HTTP status assignment in a resource BC (e.g., BC-2.12.006 EC-002: E-SERVER-016 → 503) AND a categorical status assignment in BC-2.14.002 PC3 AND an entry (or absence) in interface-definitions.md §HTTP Status Codes must be coherent across all three. If a per-endpoint assignment differs from the categorical default, it must be: (a) documented as an explicit override in BC-2.14.002 PC3, (b) present as a row in interface-definitions.md, and (c) consistent with the resource BC.

**Drain status:** E-SERVER-016 (503 override), E-SERVER-004 (POLICY→403 override), all fixed this pass. E-PROV-002/003 (502/504 categorical rows added). BC-2.14.002 PC3 precedence carve-out documented.

**Standing gate added:** bc-authoring-plan.md guideline #17-C positive-coverage assertion. New census rows must be grep-verifiable before being marked PASS.

---

## Post-Fix Verification Census

| Check | Command | Result |
|-------|---------|--------|
| E-SERVER-016 coherence at 503 | `grep -rn "E-SERVER-016" .factory/specs/` | interface-def 503 row PASS; BC-2.14.002 PC3 override PASS; bc-authoring-plan census 503 row PASS; error-taxonomy TIMEOUT (categorical, override documented) PASS |
| E-SERVER-004 no 401, category POLICY | `grep -rn "E-SERVER-004" .factory/specs/` | 403 row only in interface-def PASS; POLICY in taxonomy PASS; 401 row is reserved-only PASS; all BC-2.12.005 references at 403 PASS |
| entities-server.md code: String | `grep -n "code:" .factory/specs/domain-spec/entities-server.md` | line 108: `code: String` PASS |
| api-surface.md to_problem() | `grep -rn "to_problem" .factory/specs/architecture/api-surface.md` | `to_problem()` PASS; old `to_problem_detail()` absent PASS |
| interrupt_id canonical in ss-05/ | `grep -rn "interrupt_id\|\"id\" field" .factory/specs/behavioral-contracts/ss-05/` | all occurrences use `interrupt_id`; "id field" wording absent PASS |
| 201/204/E-CRON-002 in interface-def | `grep -n "201\|204\|E-CRON-002" .factory/specs/prd-supplements/interface-definitions.md` | line 202: 201 row PASS; line 204: 204 row PASS; line 205: E-CRON-002 in 400 row PASS |

---

## 7 Standing Census Rotations

| Census | Command | Result |
|--------|---------|--------|
| Lifecycle-arrow census (guideline #12) | `grep -rn "in_progress →\|→ interrupted\|⇄" .factory/specs/` | PASS — no new arrows introduced this pass |
| DI-verbatim census (P11) | BC body DI description strings match canonical form | PASS — no new DI citations added |
| Cross-BC state-machine consistency (P11) | terminal set = {completed, failed, cancelled} | PASS — no state machine changes |
| Shared-type census (P18/P19/P20) | `grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage\|\bCheckpointer\b" .factory/specs/` | PASS — no new shared-type violations |
| E-code↔variant-name census (P20) | All new/changed codes: E-SERVER-004/016 variant names verified | PASS — DebugRouteUnauthorized and IdempotencyLockTimeout match taxonomy |
| HTTP endpoint census (P23) | `grep -rn "POST /runs\b\|GET /runs/\|DELETE /runs/\|PATCH /runs/" .factory/specs/ \| grep -v "schedule_id" \| grep -v "threads/"` | PASS — empty output; no flat run paths |
| Wire-object field-set coherence (P24) | Run.interrupt three-way census: iface-def ↔ entities-server ↔ BCs | PASS (post-fix; Run.interrupt sub-fields now coherent across all three authorities) |

---

## Sibling Reverse-Anchor Check — PASS

No BC additions or retirements this pass. BC count: P0 48 + P1 30 + P2 8 = 86 total unchanged.

---

## Status-Code Census — PASS (post-fix)

| HTTP Code | E-code + Variant | Citing BCs | Verdict |
|-----------|-----------------|------------|---------|
| 201 | POST resource creation | BC-2.12.001 PC5, BC-2.12.002 PC4, BC-2.12.004 TV-001 | PASS (added row P25) |
| 202 | Async run created | BC-2.12.003 PC5 | PASS |
| 204 | DELETE success | BC-2.12.001:70, BC-2.12.002:71, BC-2.12.003:122, BC-2.12.004:65 | PASS (added row P25) |
| 400 | E-CRON-002 InvalidCronExpression | BC-2.12.004 EC-002 | PASS (added to 400 row P25) |
| 401 | reserved — no current E-code | — | PASS (reserved note; F-P25-02) |
| 403 | E-SERVER-004 DebugRouteUnauthorized | BC-2.12.005 PC4, EC-002 | PASS (recategorized POLICY P25) |
| 403 | E-SERVER-005 CorsRejected | BC-2.12.005 PC1/PC2 | PASS |
| 404 | E-SERVER-002 RunNotFound | BC-2.12.003 PC14, TV-003 | PASS |
| 404 | E-SERVER-003 ThreadNotFound | BC-2.12.001 PC7, TV-004 | PASS |
| 503 | E-SERVER-016 IdempotencyLockTimeout | BC-2.12.006 EC-002 | PASS (added row P25; per-endpoint override) |
| 502 | E-PROV-003 StreamInterrupted (categorical) | BC-2.08.007 | PASS (added categorical row P25) |
| 504 | E-PROV-002 ProviderTimeout (categorical) | BC-2.08.007 | PASS (added categorical row P25) |

---

## Wire-Object Sub-Field Census — PASS (post-fix)

| Object.Sub-field | schema (iface-def) | BC authority | entity | Verdict |
|-----------------|-------------------|-------------|--------|---------|
| Run.interrupt.interrupt_id | ADDED P25 | BC-2.05.001 TV-001 | entities-server §Interrupt | PASS |
| Run.interrupt.node_name | RENAMED from node_id P25 | entities-server §Interrupt | entities-server §Interrupt | PASS |
| Run.interrupt.super_step | present | BC-2.05.001 (implicit) | — | PASS |
| Run.interrupt.value | ADDED P25 | BC-2.05.001 PC4 | — | PASS |
| Run.interrupt.action_risk | RENAMED from risk_tier P25 | BC-2.05.006 HitlInterruptPayload | — | PASS |
| Run.interrupt.action | ADDED P25 | BC-2.05.006 HitlInterruptPayload | — | PASS |
| Run.interrupt.context | ADDED P25 | BC-2.05.006 HitlInterruptPayload | — | PASS |
| Run.interrupt.scratchpad | present | entities-server §Interrupt | entities-server §Interrupt | PASS |

---

## New Standing Gates

1. **HTTP-status dual-authority census:** For any E-xxx-NNN code that has a categorical mapping in BC-2.14.002 PC3 AND a per-endpoint assignment in a resource BC, verify coherence across: (a) resource BC, (b) BC-2.14.002 PC3 override list, (c) interface-definitions.md §HTTP Status Codes row. Per-endpoint overrides must be explicit in all three locations. Source: ADV-P1D-PASS-25 §NEW CLASS.

2. **Wire-object sub-field coherence (guideline #18 extension):** Embedded sub-objects (Run.interrupt, Run.error) are subject to the same three-way field-set census as top-level objects. Sub-field drift between interface-definitions.md schema properties and the authoritative BC type is a wire-breaking defect. Source: ADV-P1D-PASS-25 §F-P25-06.

3. **§17-C positive-coverage assertion:** Every PASS row in the bc-authoring-plan.md §17-C census table must be grep-verifiable in interface-definitions.md §HTTP Status Codes before being marked PASS. A census row marked PASS against a non-existent status code or E-code is a false PASS [process-gap]. Source: ADV-P1D-PASS-25 §F-P25-07.
