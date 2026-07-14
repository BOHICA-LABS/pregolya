---
document_type: adversarial-review-pass
phase: 1d
pass: 26
verdict: NOT CLEAN
findings_count: 5
high_count: 0
med_count: 5
low_count: 0
observations_count: 3
consecutive_clean: 0
required_clean: 3
trajectory: "...→1→2→7→5"
timestamp: 2026-07-14T00:00:00Z
new_class: "HTTP-status AUTH-category orphan + debug-route auth-mechanism dual-authority"
---

# Adversarial Review Pass 26 — Phase 1d

**Verdict: NOT CLEAN** — 5 findings (0 HIGH, 5 MED) + 3 observations. Counter reset: 0/3 consecutive clean.

---

## F-P26-01 [MED] — BC-2.14.002 PC3 "Known Overrides" List Contradicts Its Own Invariant

**Finding class:** HTTP-status dual-authority incoherence (extends P25 class).

**Scope:** `behavioral-contracts/ss-14/BC-2.14.002.md` PC3 lines ~74-79 + Invariant lines ~94-100.

**Finding:**
The invariant at the end of BC-2.14.002 asserted that "Legitimate per-endpoint divergences must
be documented in PC3 and interface-definitions.md §HTTP Status Codes." However, PC3's
"Known overrides as of v1.0.0" block listed ONLY E-SERVER-016. The invariant's example list
included E-SERVER-009 VAL→404 (a true per-endpoint override, since categorical VAL→400) and
E-SERVER-004 POLICY→403 (falsely claimed as a divergence — POLICY→403 IS the categorical
default, so no override exists). The invariant was simultaneously incomplete (missing 7 real
overrides) and incorrect (including one non-override).

**Fix (completed this pass):**

1. `BC-2.14.002.md` PC3 Known-overrides block:
   - Expanded from E-SERVER-016 only to all 8 per-endpoint override classes:
     E-SERVER-002 (VAL→404), E-SERVER-003 (VAL→404), E-SERVER-006 (VAL→404),
     E-SERVER-008 (POLICY→409), E-SERVER-009 (VAL→404 direct / VAL→422 body),
     E-SERVER-010 (VAL→404), E-SERVER-011 (VAL→422), E-SERVER-016 (TIMEOUT→503).
   - Each entry includes rationale and source BC citation.
2. `BC-2.14.002.md` Invariant:
   - Removed E-SERVER-004 POLICY→403 from the divergence example list.
   - Added explicit note: "E-SERVER-004 POLICY→403 is NOT a divergence — POLICY→403 is the
     categorical default and requires no carve-out."
   - Replaced divergence example with E-SERVER-008 POLICY→409 (a genuine override).
3. Version bump 1.1 → 1.2; changelog entry.

---

## F-P26-02 [MED] — to_problem_detail() Residue in ADR-010

**Finding class:** API method name drift (extends F-P25-04 canon — residue miss).

**Scope:** `architecture/decisions/ADR-010-error-taxonomy-anyhow-confinement.md` line ~72.

**Finding:**
F-P25-04 set the canon: `FerrochainError::to_problem()` is the authoritative method name
(per BC-2.14.002 PC1 and api-surface.md). The fix in P25 correctly updated api-surface.md,
but the RETIRED-IDENTIFIER RESIDUE GREP gate (new this pass — gate #19) revealed that
ADR-010 line ~72 still used the retired name `FerrochainError::to_problem_detail()`.

**Fix (completed this pass):**

1. `ADR-010-error-taxonomy-anyhow-confinement.md` §Consequences:
   - Changed `FerrochainError::to_problem_detail()` → `FerrochainError::to_problem()`.
   - Added inline correction note: "Correction (F-P26-02, propagating F-P25-04 canon):
     `to_problem_detail()` was the retired method name; `to_problem()` is authoritative
     per BC-2.14.002 PC1 and api-surface.md §Error Type."

---

## F-P26-03 [MED] — BC-2.05.001 TV-005 Uses Retired Field Name `risk_tier`

**Finding class:** Wire-object sub-field residue (extends F-P25-06 canon — residue miss).

**Scope:** `behavioral-contracts/ss-05/BC-2.05.001.md` TV-005 line ~117.

**Finding:**
F-P25-06 established the canon: `action_risk` is the authoritative field name (renamed from
`risk_tier`) in `HitlInterruptPayload` and the Run.interrupt wire object. interface-definitions.md
Run.interrupt sub-object was correctly updated in P25. However BC-2.05.001 TV-005's test
vector still used `{ "risk_tier": "High", "action": "isolate_host" }` with the retired field name.
An implementer following TV-005 would code the wrong field name.

**Fix (completed this pass):**

1. `BC-2.05.001.md` TV-005:
   - Changed `{ "risk_tier": "High", "action": "isolate_host" }` → `{ "action_risk": "High", "action": "isolate_host" }`.
   - Added correction note in TV-005 Notes column.
2. Version bump 1.0 → 1.1; changelog entry added.

**Residual acknowledged — not a violation:** BC-2.05.006 Architecture Anchors (line 181)
references `ferrochain-graph/src/hitl/risk_tier.rs`. This is a Rust **source file path**
(implementer-named module), not a wire field name. The canonical type it contains is `ActionRisk`.
Source file naming is implementer scope. This is acknowledged and not treated as a live residue hit.

---

## F-P26-04 [MED] — Debug-Route Auth Mechanism Three-Axis Contradiction

**Finding class:** HTTP-status AUTH-category orphan + debug-route auth-mechanism dual-authority (new class this pass).

**Scope:** 2 files:
- `prd-supplements/interface-definitions.md` §ferrochain-server Config File Schema line ~314: `X-Debug-Key` header, `/debug/*` path.
- `behavioral-contracts/ss-12/BC-2.12.005.md` (authoritative): `Authorization: Bearer <key>` header, `/_debug` path, plus invariant reference to `debug_route_path` config option that does NOT exist in the config schema.

**Finding:**
The config comment in interface-definitions.md described the wrong auth header (`X-Debug-Key`)
and path glob (`/debug/*`). BC-2.12.005 is authoritative and specifies `Authorization: Bearer <key>`
for path `/_debug`. Additionally, BC-2.12.005's invariant referenced `debug_route_path` as a
configurable option, but no such key appears in the config schema — creating a phantom config key.

**Decision:** BC-2.12.005 is authoritative for header+path. For `debug_route_path`: REMOVE from
BC-2.12.005 invariant. Rationale: (a) the config schema has no such key, (b) BC test vectors
TV-001 through TV-007 all hardcode `/_debug`, (c) a configurable debug path would increase
attack surface. Minimal config surface / secure-default simplicity wins.

**Fix (completed this pass):**

1. `interface-definitions.md` §ferrochain-server Config File Schema:
   - Changed `# non-empty = enables /debug/* routes if X-Debug-Key matches`
     → `# non-empty = enables /_debug route; gate requires Authorization: Bearer <key>`.
2. `BC-2.12.005.md` Invariant:
   - Changed "The debug route path is fixed at `/_debug` (or configured via `debug_route_path`)"
     → "The debug route path is fixed at `/_debug` [...] `debug_route_path` is NOT a config option."
   - Added F-P26-04 decision note.
3. Version bump 1.0 → 1.1; changelog entry added.

---

## F-P26-05 [MED] — 401 Row Falsely Claims "No Current E-Code Maps Here" — E-PROV-004 Is AUTH

**Finding class:** HTTP-status AUTH-category orphan (new class this pass).

**Scope:** `prd-supplements/interface-definitions.md` §HTTP Status Codes line ~208.

**Finding:**
After F-P25-02 recategorized E-SERVER-004 AUTH→POLICY, the 401 row was rewritten as
"reserved — no current E-code maps here." However, error-taxonomy.md §PROV has
E-PROV-004 (ProviderAuthFailed) with category AUTH (Category::Auth → 401 per BC-2.14.002 PC3).
The 401 row's claim was false — an AUTH code existed in a different namespace that the
F-P25-02 fix failed to survey (insufficient cross-namespace scope).

**Fix (completed this pass):**

1. `interface-definitions.md` §HTTP Status Codes, 401 row:
   - Rewrote in the categorical-fallback form used by the 502/504 rows:
     `E-PROV-004 (ProviderAuthFailed, AUTH) — categorical fallback only; no v1 server endpoint
     emits 401 as a direct terminal HTTP status; surfaced embedded in Run.error. Server-side
     authentication middleware is out of v1 scope.`
   - Preserved the F-P25-02 note about E-SERVER-004 recategorization.

---

## Observations (non-blocking)

### OBS-1 (applied): Narrow the 422 Wildcard

`interface-definitions.md` 422 row used `E-GRAPH-*, E-CHKPT-*` wildcards. The 500 row
separately listed E-GRAPH-006 — creating overlap (E-GRAPH-* includes E-GRAPH-006). Further,
no E-CHKPT-* code has VAL category (they are DURABILITY/INTERNAL/SECURITY/TENANCY), so
E-CHKPT-* had no business in the 422 row at all.

**Fix applied:** Narrowed 422 row to enumerate only the 8 VAL-category E-GRAPH codes explicitly:
E-GRAPH-003, E-GRAPH-004, E-GRAPH-007, E-GRAPH-008, E-GRAPH-009, E-GRAPH-010, E-GRAPH-012, E-GRAPH-015.
Removed E-CHKPT-* from 422 row. Expanded 500 row to explicitly enumerate INTERNAL E-CHKPT and
GRAPH codes (E-GRAPH-006, E-GRAPH-011, E-CHKPT-001/002/003/006). No code now appears in both rows.

### OBS-2 (applied): E-CRON-001/003 Intentional-Omission Note

E-CRON-001 (AssistantNotFoundAtFiring) and E-CRON-003 (ScheduleQueueFull) are async firing-time
errors that never appear as direct HTTP responses. The status table had no note explaining their
absence, which could lead reviewers to flag them as missing.

**Fix applied:** Added a blockquote note after the status table and BC anchor:
"E-CRON-001 (AssistantNotFoundAtFiring) and E-CRON-003 (ScheduleQueueFull) are async
firing-time errors surfaced in schedule/run state, never as a direct HTTP response —
intentionally omitted from this table."

### OBS-3 (applied): Extend Categorical-Fallback Treatment to E-PROV-005/E-PROV-006

E-PROV-005 (StructuredOutputParseError, VAL) and E-PROV-006 (ContextLengthExceeded, VAL) were
not in the HTTP status table. Both have VAL category (categorical VAL→400) but surface embedded
in Run.error, not as direct HTTP responses.

**Fix applied:** Added E-PROV-005 and E-PROV-006 to the 400 row with annotation:
"categorical VAL→400; surfaced embedded in Run.error, not as direct HTTP response codes
(OBS-3; BC-2.08.003, BC-2.08.004)."
Source BCs verified: BC-2.08.003 (E-PROV-005) and BC-2.08.004 (E-PROV-006) both confirm VAL category.

---

## NEW CLASS: HTTP-Status AUTH-Category Orphan + Debug-Route Auth-Mechanism Dual-Authority

**AUTH-Category Orphan definition:** When the 401 row is edited (especially when codes are
removed), the fix must survey ALL error code namespaces (not just the namespace being edited)
for AUTH-category codes that now have no 401 coverage. The standing AUTH/POLICY CATEGORY
RE-SWEEP gate (#20) was added to enforce this going forward.

**Debug-Route Auth-Mechanism Dual-Authority definition:** The config schema, BC preconditions,
and BC test vectors must agree on: (a) the HTTP header used for debug route authentication,
(b) the debug route path. Any divergence between these three locations is a dual-authority
defect. BC is always authoritative; config schema and test vectors follow.

**Drain status:** E-PROV-004 AUTH→401 categorical-fallback documented; debug-route header+path
canon established as `Authorization: Bearer <key>` + `/_debug`; `debug_route_path` config option
eliminated. All fixed this pass.

**Standing gates added:** bc-authoring-plan.md guidelines #19 (Retired-Identifier Residue Grep)
and #20 (AUTH/POLICY Category Re-Sweep).

---

## Fix Records (Post-Application)

| Finding | File | Change | Status |
|---------|------|--------|--------|
| F-P26-01 | BC-2.14.002.md | PC3 Known-overrides expanded to 8 entries; E-SERVER-004 removed from invariant example | APPLIED |
| F-P26-02 | ADR-010-error-taxonomy-anyhow-confinement.md | `to_problem_detail()` → `to_problem()`; correction note added | APPLIED |
| F-P26-03 | BC-2.05.001.md | TV-005 `risk_tier` → `action_risk`; version bump + changelog | APPLIED |
| F-P26-04 | interface-definitions.md + BC-2.12.005.md | Config comment fixed (Bearer+/_debug); debug_route_path removed from BC invariant | APPLIED |
| F-P26-05 | interface-definitions.md | 401 row rewritten with E-PROV-004 categorical-fallback | APPLIED |
| OBS-1 | interface-definitions.md | 422 row narrowed to VAL E-GRAPH codes; E-CHKPT-* removed; 500 row explicitly lists INTERNAL codes | APPLIED |
| OBS-2 | interface-definitions.md | E-CRON-001/003 intentional-omission note added | APPLIED |
| OBS-3 | interface-definitions.md | E-PROV-005/006 added to 400 row with embedded-in-Run.error annotation | APPLIED |
| Gates | bc-authoring-plan.md | Standing gates #19 (Retired-Identifier Residue Grep) and #20 (AUTH/POLICY Category Re-Sweep) added | APPLIED |

---

## Post-Fix Verification Census

| Check | Command | Result |
|-------|---------|--------|
| `to_problem_detail` drained | `grep -rn "to_problem_detail" .factory/specs/` (excl. changelog/census-rule) | PASS — zero live occurrences |
| `risk_tier` field drained | `grep -rn "risk_tier" .factory/specs/` (excl. changelog/architecture-anchors/census-rule) | PASS — BC-2.05.001 TV-005 fixed; BC-2.05.006 Architecture Anchor `risk_tier.rs` is a source file path, not a wire field — acknowledged |
| `X-Debug-Key`/`/debug/*` drained | `grep -rn "X-Debug-Key\|/debug/\*" .factory/specs/` (excl. changelog/retired-id-table) | PASS — zero live occurrences |
| E-PROV-004/005/006 in table | `grep -n "E-PROV-004\|E-PROV-005\|E-PROV-006" interface-definitions.md` | PASS — E-PROV-004 in 401 row; E-PROV-005/006 in 400 row |
| BC-2.14.002 PC3 overrides | Count Known-override entries | PASS — 8 override entries (E-SERVER-002/003/006/008/009/010/011/016) |
| 422/500 no overlap | Visual check of both rows | PASS — no code in both rows |
| debug_route_path eliminated | `grep -n "debug_route_path" BC-2.12.005.md` | PASS — only appears in changelog note (explaining the removal) and the "NOT a config option" clarification |

---

## Sibling Reverse-Anchor Check — PASS

No BC additions or retirements this pass. BC count: P0 48 + P1 30 + P2 8 = 86 total unchanged.

---

## Dual-Authority Census (Post-Fix)

| Interface Point | BC Authority | Config/Interface | Match |
|----------------|-------------|-----------------|-------|
| Debug route path | BC-2.12.005: `/_debug` fixed | interface-def config: `/_debug` (fixed F-P26-04) | PASS |
| Debug route header | BC-2.12.005: `Authorization: Bearer <key>` | interface-def config: `Authorization: Bearer <key>` (fixed F-P26-04) | PASS |
| debug_route_path configurable? | BC-2.12.005: NO (fixed F-P26-04) | interface-def config schema: absent (consistent) | PASS |
| E-PROV-004 HTTP status | error-taxonomy.md: AUTH→401 categorical | interface-def 401 row: E-PROV-004 categorical-fallback (fixed F-P26-05) | PASS |

---

## HTTP Status Code Census — PASS (Post-Fix)

| HTTP Code | E-code + Variant | Category | Notes | Verdict |
|-----------|-----------------|----------|-------|---------|
| 400 | E-CORE-001 through E-CORE-005 | VAL | Direct HTTP 400 | PASS |
| 400 | E-CRON-002 InvalidCronExpression | VAL | Direct HTTP 400 | PASS |
| 400 | E-PROV-005 StructuredOutputParseError | VAL | Categorical; embedded in Run.error (OBS-3) | PASS (added P26) |
| 400 | E-PROV-006 ContextLengthExceeded | VAL | Categorical; embedded in Run.error (OBS-3) | PASS (added P26) |
| 401 | E-PROV-004 ProviderAuthFailed | AUTH | Categorical fallback; embedded in Run.error (F-P26-05) | PASS (fixed P26) |
| 403 | E-SERVER-004 DebugRouteUnauthorized | POLICY | Direct HTTP 403 | PASS |
| 403 | E-SERVER-005 CorsRejected | POLICY | Direct HTTP 403 | PASS |
| 404 | E-SERVER-002 RunNotFound | VAL | Per-endpoint override (VAL→404 not 400) | PASS |
| 404 | E-SERVER-003 ThreadNotFound | VAL | Per-endpoint override | PASS |
| 404 | E-SERVER-006 ScheduleNotFound | VAL | Per-endpoint override | PASS |
| 404 | E-SERVER-009 AssistantNotFound (direct) | VAL | Per-endpoint override (direct lookup) | PASS |
| 404 | E-SERVER-010 AssistantVersionNotFound | VAL | Per-endpoint override | PASS |
| 409 | E-SERVER-007 ThreadAlreadyExists | CONCURRENCY | Categorical CONCURRENCY→409 | PASS |
| 409 | E-SERVER-008 ThreadStateConflict | POLICY | Per-endpoint override (POLICY→409 not 403) | PASS (documented in BC-2.14.002 PC3 F-P26-01) |
| 409 | E-SERVER-012 ConcurrentRun | CONCURRENCY | Categorical | PASS |
| 409 | E-SERVER-015 RunAlreadyExecuting | CONCURRENCY | Categorical | PASS |
| 422 | E-GRAPH-003/004/007/008/009/010/012/015 | VAL | Per-endpoint override (VAL→422 not 400); body content semantics | PASS (narrowed P26 OBS-1) |
| 422 | E-SERVER-009 AssistantNotFound (body) | VAL | Per-endpoint override (run creation body context) | PASS |
| 422 | E-SERVER-011 GraphNotFound | VAL | Per-endpoint override | PASS |
| 429 | E-PROV-001 RateLimited | RATE | Categorical RATE→429 | PASS |
| 500 | E-GRAPH-006 BspDeterminismViolation | INTERNAL | Categorical | PASS (explicit P26 OBS-1) |
| 500 | E-GRAPH-011 ConditionalEdgePanic | INTERNAL | Categorical; was implicit under E-GRAPH-* wildcard | PASS (explicit P26 OBS-1) |
| 500 | E-CHKPT-001/002/003/006 | DURABILITY/INTERNAL | Categorical | PASS (explicit P26 OBS-1) |
| 500 | E-SERVER-014 RunStoreFailed | DURABILITY | Categorical | PASS |
| 502 | E-PROV-003 StreamInterrupted | TRANSPORT | Categorical fallback; embedded in Run.error | PASS |
| 503 | E-SERVER-016 IdempotencyLockTimeout | TIMEOUT | Per-endpoint override (TIMEOUT→503 not 504) | PASS |
| 504 | E-PROV-002 ProviderTimeout | TIMEOUT | Categorical fallback; embedded in Run.error | PASS |

*Intentionally omitted (async only, never direct HTTP): E-CRON-001 (AssistantNotFoundAtFiring), E-CRON-003 (ScheduleQueueFull). See OBS-2 note.*

---

## Rotated Census Results

| Census | Command | Result |
|--------|---------|--------|
| Lifecycle-arrow census (guideline #12) | `grep -rn "in_progress →\|→ interrupted\|⇄" .factory/specs/` | PASS — no new arrows introduced this pass |
| DI-verbatim census (P11) | BC body DI description strings | PASS — no new DI citations added |
| Cross-BC state-machine consistency (P11) | terminal set = {completed, failed, cancelled} | PASS — no state machine changes |
| Shared-type census (P18/P19/P20) | `grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage\|\bCheckpointer\b" .factory/specs/` | PASS — no new violations |
| E-code↔variant-name census (P20) | All new/changed codes: E-SERVER-008/009/011 variant names verified | PASS — ThreadStateConflict, AssistantNotFound, GraphNotFound match taxonomy |
| HTTP endpoint census (P23) | `grep -rn "POST /runs\b\|GET /runs/\|DELETE /runs/\|PATCH /runs/" .factory/specs/ \| grep -v "schedule_id" \| grep -v "threads/"` | PASS — empty output |
| Wire-object field-set coherence (P24/P25) | Run.interrupt three-way census | PASS — no sub-field changes this pass |
| Retired-identifier residue grep (P26 — NEW gate #19) | `grep -rn "to_problem_detail\|risk_tier" .factory/specs/` (excl. allowed) | PASS — to_problem_detail zero; risk_tier field zero; risk_tier.rs file-path acknowledged |
| AUTH/POLICY category re-sweep (P26 — NEW gate #20) | All AUTH/POLICY/CONCURRENCY codes × status mapping | PASS — full census in §HTTP Status Code Census above |

---

## New Standing Gates (added to bc-authoring-plan.md)

**Gate #19 — Retired-Identifier Residue Grep:** Whenever a rename canon is set (method,
field, type, path), the fix burst MUST grep the ENTIRE `.factory/specs/` tree (including
ADRs and all BC TVs) for the retired identifier and drain every hit. Current retired-identifier
list: to_problem_detail, risk_tier (field), node_id (interrupt context), {schedule_id},
CheckpointStore, RunConfig, BaseCheckpointSaver, AIMessage, bare Checkpointer,
X-Debug-Key, /debug/*. Source: ADV-P1D-PASS-26 §F-P26-02, §F-P26-03, §F-P26-04.

**Gate #20 — AUTH/POLICY Category Re-Sweep:** Any edit to a 401/403/409 table row OR to
an E-code's category MUST re-run the full category→status census for ALL codes in the
affected categories across ALL namespaces (including E-PROV). This gate prevents the
AUTH-category orphan class (E-PROV-004 was orphaned when only E-SERVER-004 was surveyed
for the 401 row). Source: ADV-P1D-PASS-26 §F-P26-05.
