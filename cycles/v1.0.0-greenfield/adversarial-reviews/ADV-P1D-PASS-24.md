---
document_type: adversarial-review-pass
phase: 1d
pass: 24
verdict: NOT CLEAN
findings_count: 2
high_count: 1
med_count: 1
observations_count: 3
consecutive_clean: 0
required_clean: 3
trajectory: "...→1→1→1→2"
timestamp: 2026-07-14T00:00:00Z
new_class: wire-object field-set coherence
---

# Adversarial Review Pass 24 — Phase 1d

**Verdict: NOT CLEAN** — 2 findings (1 HIGH, 1 MED) + 3 observations. Counter reset: 0/3 consecutive clean.

---

## F-P24-01 [HIGH] — Run Schema Three-Way Incoherence: updated_at Missing from Interface-Definitions; completed_at Missing from Entity and BC

**Finding class:** WIRE-OBJECT field-set coherence (new class this pass).

**Scope:** 3 files:
- `prd-supplements/interface-definitions.md` §Run Object Schema (lines 220–231) — `updated_at` absent from required array and properties; `completed_at` present with no semantics note
- `domain-spec/entities-server.md` §Run — `completed_at` absent from Fields list
- `behavioral-contracts/ss-12/BC-2.12.003.md` PC13 — `completed_at` absent from returned Run object

**Finding:**
The Run Object JSON schema in `interface-definitions.md` had `required: ["run_id", "thread_id", "assistant_id", "status", "created_at"]` — missing `updated_at` despite BC-2.12.003 PC13 explicitly listing it in the returned fields (`Run { ..., created_at, updated_at }`). The entity (`entities-server.md`) correctly included `updated_at`. The schema also included `completed_at` (nullable) without any semantics note and without propagating it to the entity or BC.

Three-way check:
- `updated_at`: BC ✓, entity ✓, schema ✗ (missing from required + properties) — FAIL
- `completed_at`: BC ✗, entity ✗, schema ✓ (no semantics) — FAIL

**Decision:** Keep `completed_at` as a distinct terminal-timestamp field (operationally useful — clients can filter/sort by terminal time without inferring from `updated_at`; matches LangGraph Platform norms). Decision: keep-with-semantics per F-P24-01. Semantics: "set only on terminal transition (status → completed | failed | cancelled); null in all non-terminal states (queued, in_progress, interrupted)."

**Fix (completed this pass):**

1. `interface-definitions.md` §Run Object Schema:
   - Added `updated_at` to `required` array.
   - Added `updated_at` property: `{ "type": "string", "format": "date-time", "description": "Set on every Run state mutation..." }`.
   - Updated `completed_at` description with explicit semantics: "Set only on terminal transition... Null in all non-terminal states... Authority: F-P24-01."
2. `entities-server.md` §Run:
   - Updated Fields: added `completed_at: Option<Timestamp>` with semantics note.
   - Typed `created_at` and `updated_at` as `Timestamp` (previously bare names).
3. `BC-2.12.003` PC13:
   - Added `completed_at?` to returned Run object.
   - Added inline semantics paragraph: `updated_at` set on every mutation; `completed_at` set only on terminal transition.

**Verification:**
```
grep -n "updated_at\|completed_at" \
  .factory/specs/prd-supplements/interface-definitions.md \
  .factory/specs/domain-spec/entities-server.md \
  .factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md
```
All three files must contain both fields.

---

## F-P24-02 [MED] — HTTP Status-Code Table Excludes E-SERVER Codes at 404 and 422

**Finding class:** Status-code ↔ E-code completeness (standing census, new probe).

**Scope:** `prd-supplements/interface-definitions.md` §HTTP Status Codes (lines 199–212).

**Finding:**
The 404 row listed only `E-SERVER-002, E-SERVER-003` — omitting `E-SERVER-006` (ScheduleNotFound — BC-2.12.004 EC-005), `E-SERVER-009` (AssistantNotFound — BC-2.12.002 PC8, TV-004), and `E-SERVER-010` (AssistantVersionNotFound — BC-2.12.002 EC-002). The 422 row listed only `E-GRAPH-*, E-CHKPT-*` — omitting `E-SERVER-009` in its run-body-reference context (BC-2.12.003 PC3: invalid `assistant_id` in run creation → 422) and `E-SERVER-011` (GraphNotFound in assistant body — BC-2.12.002 EC-005).

Additionally, the 409 row was a bare `E-SERVER-*` wildcard with no enumeration — replaced with explicit codes.

**Fix (completed this pass):**

- **404 row:** Added `E-SERVER-006 (ScheduleNotFound)`, `E-SERVER-009 (AssistantNotFound — direct resource lookup)`, `E-SERVER-010 (AssistantVersionNotFound)`.
- **422 row:** Changed to "VAL-category semantic failures on body content"; added `E-SERVER-009 (AssistantNotFound in run body — context-dependent)` and `E-SERVER-011 (GraphNotFound in assistant body)`.
- **409 row:** Enumerated explicit codes: `E-SERVER-007 (ThreadAlreadyExists)`, `E-SERVER-008 (ThreadStateConflict)`, `E-SERVER-012 (ConcurrentRun)`, `E-SERVER-015 (RunAlreadyExecuting)`.
- **500 row:** Added `E-SERVER-014 (RunStoreFailed)` which was confirmed at 500 in BC-2.12.006 EC-004.

**E-SERVER-009 context-dependency note:** This code appears at BOTH 404 and 422. At 404: direct `GET /assistants/{id}` not found. At 422: `POST /threads/{id}/runs` body references a non-existent `assistant_id` (semantic body validation). The same error code applied at two HTTP status codes depending on whether the client is requesting the resource directly vs. referencing it as a field value. This is documented explicitly in both rows.

**Cross-verification (E-code coverage check):**

| E-CODE | Category | HTTP Code | Citing BC | In table? |
|--------|----------|-----------|-----------|-----------|
| E-SERVER-002 | VAL | 404 | BC-2.12.003 PC14, TV-003 | PASS |
| E-SERVER-003 | VAL | 404 | BC-2.12.001 PC7, TV-004 | PASS |
| E-SERVER-004 | AUTH | 401 | BC-2.12.005 TV-002 | PASS |
| E-SERVER-005 | POLICY | 403 | BC-2.12.005 TV-003 | PASS |
| E-SERVER-006 | VAL | 404 | BC-2.12.004 EC-005 | PASS (added) |
| E-SERVER-007 | CONCURRENCY | 409 | BC-2.12.001 TV-002 | PASS (enumerated) |
| E-SERVER-008 | POLICY | 409 | BC-2.12.001 EC-005 | PASS (enumerated) |
| E-SERVER-009 | VAL | 404 (direct) / 422 (body ref) | BC-2.12.002 TV-004; BC-2.12.003 PC3 | PASS (both rows) |
| E-SERVER-010 | VAL | 404 | BC-2.12.002 EC-002 | PASS (added) |
| E-SERVER-011 | VAL | 422 | BC-2.12.002 EC-005 | PASS (added) |
| E-SERVER-012 | CONCURRENCY | 409 | BC-2.12.003 EC-002 | PASS (enumerated) |
| E-SERVER-013 | VAL | 400 | BC-2.12.005 | PASS (under E-CORE/400 umbrella) |
| E-SERVER-014 | DURABILITY | 500 | BC-2.12.006 EC-004 | PASS (added to 500 row) |
| E-SERVER-015 | CONCURRENCY | 409 | BC-2.12.007 TV-006 | PASS (enumerated) |
| E-SERVER-016 | TIMEOUT | 503 | BC-2.12.006 | NOTE: no 503 row in table; E-SERVER-016 is an internal store timeout — adds to 500 bucket or warrants a 503 row. Flagged for pass 25 probe. |

---

## Observations (non-blocking)

### OBS-1: Thread.status undefined in entities-server.md
BC-2.12.001 PC5 returns `Thread { ..., status }` but entities-server.md Thread Fields had no `status` field.

**Fix:** Added `status: ThreadStatus` with enum definition: `idle | busy | interrupted | error` (derived from active run state). Source: BC-2.12.001 PC5.

### OBS-2: Assistant entity missing wire-visible fields from BC-2.12.002 PC4
entities-server.md Assistant Fields listed only `assistant_id, graph_id, config, metadata` — missing `name, description, version, context, created_at` which are all present in BC-2.12.002 PC4 create response.

**Fix:** Added to Assistant entity: `context: Option<Value>`, `name: Option<String>`, `description: Option<String>`, `version: u32`, `created_at: Timestamp`. Added version semantics note (starts at 1; PATCH creates N+1 immutable snapshot). Source: BC-2.12.002 PC3/PC4/PC10.

### OBS-3: api-surface.md {schedule_id} → {cron_id} placeholder drift
api-surface.md schedule path rows used `{schedule_id}` while interface-definitions.md, BC-2.12.004, and entities-server.md all use `{cron_id}` as the path parameter name.

**Fix:** Replaced all three `{schedule_id}` instances with `{cron_id}` in api-surface.md schedule rows.

---

## NEW CLASS: Wire-Object Field-Set Coherence

**Class definition:** Any field on a wire-visible object (Run, Thread, Assistant, CronSchedule, Resume request) must be present coherently across three locations: (1) the `interface-definitions.md` JSON schema for that object, (2) the `entities-server.md` entity field list, (3) every BC postcondition and test vector that returns or consumes the object.

**Drain status:** All identified mismatches fixed this pass (Run updated_at, Run completed_at, Thread status, Assistant 5 fields, CronSchedule last_fired_at, api-surface {cron_id}).

**Standing gate added:** bc-authoring-plan.md guideline #18 — wire-object field-set coherence census gate. Trigger: any BC fix burst that adds, renames, or removes a field on a wire-visible object. Quick check command documented in guideline #18.

---

## Sibling Reverse-Anchor Check — PASS

BC partition: P0 48 + P1 30 + P2 8 = 86 total. No BC additions or retirements this pass.

---

## 7 Standing Census Rotations — PASS

| Census | Command | Result |
|--------|---------|--------|
| Lifecycle-arrow census (guideline #12) | `grep -rn "in_progress →\|→ interrupted\|⇄" .factory/specs/` | PASS — no new arrows introduced |
| DI-verbatim census (P11) | BC body DI description strings match canonical form | PASS — no new DI citations this pass |
| Cross-BC state-machine consistency (P11) | terminal set = {completed, failed, cancelled} | PASS |
| Shared-type census (P18/P19/P20) | `grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage\|\bCheckpointer\b" .factory/specs/` | PASS |
| E-code↔variant-name census (P20) | New pass uses verified codes: E-SERVER-009/011 additions match taxonomy | PASS |
| Capability-tier census (P21) | No CAP priority changes this pass | PASS |
| Reverse-anchor sweep (P22) | No CAP relocation this pass | PASS (not triggered) |

---

## Endpoint Census — PASS

URL-scheme consistency check (guideline #17A):
```
grep -rn "POST /runs\b\|GET /runs/\|DELETE /runs/\|PATCH /runs/" .factory/specs/ \
  | grep -v "schedule_id" | grep -v "threads/" | grep -v "bc-authoring-plan"
```
Output: EMPTY. Zero flat run paths.

api-surface.md {schedule_id}→{cron_id} fix verified: all 3 schedule path rows now use `{cron_id}`.

---

## Status-Code Census — PASS (post-fix)

| HTTP Code | E-code + Variant | Citing BCs | Verdict |
|-----------|-----------------|------------|---------|
| 404 | E-SERVER-002 RunNotFound | BC-2.12.003 PC14, TV-003 | PASS |
| 404 | E-SERVER-003 ThreadNotFound | BC-2.12.001 PC7, TV-004 | PASS |
| 404 | E-SERVER-006 ScheduleNotFound | BC-2.12.004 EC-005 | PASS (added) |
| 404 | E-SERVER-009 AssistantNotFound (direct) | BC-2.12.002 TV-004 | PASS (added) |
| 404 | E-SERVER-010 AssistantVersionNotFound | BC-2.12.002 EC-002 | PASS (added) |
| 409 | E-SERVER-007 ThreadAlreadyExists | BC-2.12.001 TV-002 | PASS (enumerated) |
| 409 | E-SERVER-008 ThreadStateConflict | BC-2.12.001 EC-005 | PASS (enumerated) |
| 409 | E-SERVER-012 ConcurrentRun | BC-2.12.003 EC-002 | PASS (enumerated) |
| 409 | E-SERVER-015 RunAlreadyExecuting | BC-2.12.007 TV-006 | PASS (enumerated) |
| 422 | E-GRAPH-002 NoActiveInterrupt | BC-2.05.005 TV-003 | PASS |
| 422 | E-SERVER-009 (in run body) | BC-2.12.003 PC3 | PASS (added; context-dependent) |
| 422 | E-SERVER-011 GraphNotFound | BC-2.12.002 EC-005 | PASS (added) |
| 500 | E-SERVER-014 RunStoreFailed | BC-2.12.006 EC-004 | PASS (added) |

**Open probe for pass 25:** E-SERVER-016 (IdempotencyLockTimeout) — currently no HTTP row covers TIMEOUT durability errors from the store. Likely 503 or 500. Probe pending.

---

## Wire-Object Field-Set Census — PASS (post-fix)

| Object | Field | schema (iface-def) | entity (entities-server) | BC | Verdict |
|--------|-------|-------------------|--------------------------|-----|---------|
| Run | run_id | required | YES | PC5, PC13 | PASS |
| Run | thread_id | required | YES | PC5, PC13 | PASS |
| Run | assistant_id | required | YES | PC5, PC13 | PASS |
| Run | status | required | YES | PC5, PC13 | PASS |
| Run | created_at | required | YES | PC5, PC13 | PASS |
| Run | updated_at | required (fixed) | YES | PC13 | PASS |
| Run | completed_at | nullable (fixed semantics) | YES (fixed) | PC13 (fixed) | PASS |
| Run | output | conditional | YES | PC15 | PASS |
| Run | error | conditional | implicit (FerrochainError) | PC16 | PASS |
| Run | interrupt | conditional | Interrupt entity (separate) | PC9 | PASS |
| Thread | thread_id | no JSON schema | YES | PC5 | PASS |
| Thread | metadata | — | YES | PC1 | PASS |
| Thread | created_at | — | YES | PC5 | PASS |
| Thread | updated_at | — | YES | PC5 | PASS |
| Thread | status | — | YES (fixed) | PC5 | PASS |
| Assistant | assistant_id | no JSON schema | YES | PC4 | PASS |
| Assistant | graph_id | — | YES | PC4 | PASS |
| Assistant | config | — | YES | PC4 | PASS |
| Assistant | context | — | YES (fixed) | PC4 | PASS |
| Assistant | metadata | — | YES | PC4 | PASS |
| Assistant | name | — | YES (fixed) | PC4 | PASS |
| Assistant | description | — | YES (fixed) | PC4 | PASS |
| Assistant | version | — | YES (fixed) | PC4 | PASS |
| Assistant | created_at | — | YES (fixed) | PC4 | PASS |
| CronSchedule | cron_id | path param | YES | PC1, PC3 | PASS |
| CronSchedule | assistant_id | — | YES | PC1 | PASS |
| CronSchedule | schedule | — | YES | PC1 | PASS |
| CronSchedule | config | — | YES | PC4 | PASS |
| CronSchedule | enabled | GET response | YES | PC4 | PASS |
| CronSchedule | last_fired_at | GET response | YES (fixed) | PC3 | PASS |
| ResumeRequest | resume_value | required | N/A | BC-2.05.004 | PASS |
| ResumeRequest | approver_id | optional | N/A | BC-2.05.004 | PASS |

---

## Novel Probes (4) — MIXED

| Probe | Target | Result |
|-------|--------|--------|
| Wire-object three-way field-set (NEW CLASS) | Run schema × entity × BC PC/TV for all wire objects | F-P24-01 (HIGH — Run schema missing updated_at) + OBS-1/2/3 — fixed |
| Status-code table exhaustiveness | interface-definitions.md §HTTP Status Codes vs all E-SERVER-NNN codes | F-P24-02 (MED — 404/422/409 rows incomplete) — fixed |
| api-surface path-param consistency | {schedule_id} vs {cron_id} across api-surface.md, interface-definitions.md, BCs, entity | OBS-3 — fixed |
| bc-authoring-plan.md guideline 17C E-GRAPH-002 row | 409 entry vs Pass 23 fix to 422 | Drift fixed in guideline 17C table |

---

## New Standing Gates

1. **Wire-object field-set coherence census (guideline #18):** Three-way field-set check:
   interface-definitions.md schema ↔ entities-server.md entity ↔ BC postconditions/TVs.
   BCs are authoritative. Trigger: any BC fix burst touching a wire-visible object field.
   Quick check command documented in bc-authoring-plan.md §guideline #18.
   Source of truth: ADV-P1D-PASS-24.md §WIRE-OBJECT class.
