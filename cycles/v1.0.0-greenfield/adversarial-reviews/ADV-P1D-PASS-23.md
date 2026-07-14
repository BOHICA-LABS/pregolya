---
document_type: adversarial-review-pass
phase: 1d
pass: 23
verdict: NOT CLEAN
findings_count: 1
high_count: 1
consecutive_clean: 0
required_clean: 3
trajectory: "...→3→1→1→1"
timestamp: 2026-07-14T00:00:00Z
---

# Adversarial Review Pass 23 — Phase 1d

**Verdict: NOT CLEAN** — 1 finding (1 HIGH). Counter reset: 0/3 consecutive clean.

---

## F-P23-01 [HIGH] — HTTP Endpoint URL-Scheme Incoherence: BC-2.12.003 Thread-Nested vs BC-2.12.007 + BC-2.12.006 + BC-2.05.005/006 + api-surface + prd§3 Flat

**Finding class (NEW CLASS):** HTTP endpoint coherence — URL-scheme split between BC files
referencing the Run resource path.

**Scope:** 8 files:
- `ss-12/BC-2.12.007.md` (lines 34, 47–49, 97, 130) — flat run paths in Description + Precondition 3 + TV-006
- `ss-12/BC-2.12.006.md` (lines 74, 148–151) — flat `/runs/` paths in postcondition PC8 + test vectors TV-001–004
- `ss-05/BC-2.05.005.md` (lines 44, 79, 111, 133) — flat `/runs/{run_id}/resume` in preconditions, edge cases, TV-003, architecture anchor
- `ss-05/BC-2.05.006.md` (lines 142–143, 183) — flat `/runs/{id}/resume` and `/runs/{id}` in invariants + architecture anchor
- `domain-spec/edge-cases.md` (line 72) — flat `/runs/{run_id}/resume` in DEC-006 scenario
- `architecture/api-surface.md` (lines 79–85) — flat `/runs`, `/runs/{id}`, `/runs/{id}/stream`, `/runs/{id}/resume`; missing cancel, DELETE runs, PATCH schedules
- `prd-supplements/interface-definitions.md` §Cron Schedules — nested `/threads/{thread_id}/schedules` paths; missing PATCH row
- `prd.md` §3 (lines 341–342) — path strings referencing old flat `/runs`, `/schedules` shapes

**Finding:** BC-2.12.003 (the canonical Run CRUD BC) uses thread-nested paths throughout
(`POST /threads/{thread_id}/runs`, `GET /threads/{thread_id}/runs/{run_id}`, etc.).
BC-2.12.007 (streaming/unary equivalence) referenced the flat `POST /runs/{id}/stream`
and `POST /runs/{id}` surfaces, creating a two-tier incoherence: the Run is thread-nested
in BC-2.12.003 but flat in BC-2.12.007. The same flat-path residue existed in BC-2.12.006,
BC-2.05.005, BC-2.05.006, domain-spec/edge-cases.md, and was most severe in api-surface.md
which used flat `/runs` rows as the architecture-level summary (lines 79–82).

Additionally, interface-definitions.md §Cron Schedules used nested `/threads/{thread_id}/schedules`
paths (wrong: schedules are assistant-owned and flat per BC-2.12.004 PC3–PC5), and was
missing the `PATCH /schedules/{cron_id}` endpoint (enable/disable per PC4).

Secondary finding in status-code census: BC-2.05.005 stated `HTTP 409` for `E-GRAPH-002
NoActiveInterrupt`, while interface-definitions.md §HTTP Status Codes maps `E-GRAPH-*` → `422`.
The BC text itself noted the ambiguity ("409 or 422 — see interface-definitions.md").

**Adopted canon (semantically-pinned resolution):**
- **RUNS = thread-nested:** All run CRUD paths use `/threads/{thread_id}/runs/...`.
  Basis: BC-2.12.003 F-02 decision (DELETE = record deletion, separation from cancel follows
  langgraph-sdk semantics). Execution surfaces: `GET /threads/{thread_id}/runs/{run_id}/stream`
  (SSE) and `GET /threads/{thread_id}/runs/{run_id}` (unary polling after POST creates the run).
- **SCHEDULES = flat:** `/schedules/{cron_id}` (assistant-owned; fresh thread per firing).
  Basis: BC-2.12.004 PC3–PC5; architecture anchor `routes/schedules.rs`.
- **TV-002 (`GET /runs?schedule_id=`):** Kept as a flat read-only cross-thread aggregate
  query endpoint. Rationale: each cron-fired Run has a distinct `thread_id`; a thread-scoped
  query cannot enumerate all schedule Runs. Document as the only intentional flat `/runs` path.
- **E-GRAPH-002 HTTP status:** Resolved to 422 per interface-definitions.md `E-GRAPH-* → 422` mapping.

**Fix plan (completed this pass):**

1. **BC-2.12.007:** Lines 34–35 description; precondition 3 (lines 47–49); EC-002 (line 97);
   TV-006 (line 130) — all flat run paths → thread-nested.
2. **BC-2.12.006:** PC8 (line 74); TV-001/002/003/004 (lines 148–151) — flat → thread-nested.
3. **BC-2.05.005:** Precondition 1 (line 44); EC-001 (line 79); TV-003 (line 111);
   architecture anchor (line 133) — flat `/runs/{run_id}/resume` → thread-nested.
   TV-003 HTTP 409 → HTTP 422 (status-code census fix).
4. **BC-2.05.006:** Invariants prose (lines 142–143); architecture anchor (line 183)
   — flat → thread-nested.
5. **domain-spec/edge-cases.md:** DEC-006 (line 72) — flat → thread-nested.
6. **interface-definitions.md §Cron Schedules:** Nested paths → flat `/schedules/{cron_id}`;
   added `PATCH /schedules/{cron_id}` row; added explicit cross-thread aggregate query row
   (`GET /runs?schedule_id={cron_id}`) with explanatory note; added missing
   `GET /threads/{thread_id}/runs` (list) row to §Runs.
7. **api-surface.md:** Replaced flat run rows (lines 79–82) with thread-nested; added
   `GET /threads/{thread_id}/runs` (list), `POST .../runs/{run_id}/cancel`,
   `DELETE .../runs/{run_id}`, `PATCH /schedules/{schedule_id}`,
   `GET /runs?schedule_id={cron_id}`; added F-P23-01 URL-scheme note; added missing
   `GET /assistants` (list) row.
8. **prd.md §3:** Updated path summary to reflect thread-nested runs + flat schedules + F-P23-01 citation.
9. **BC-2.12.004 TV-002:** Added note that `GET /runs?schedule_id=` is the explicitly
   documented flat cross-thread aggregate endpoint.
10. **bc-authoring-plan.md:** Added guideline #17 — HTTP endpoint census gate (URL-scheme
    consistency check + canonical path table + status-code↔E-code table).

**Verification (post-fix):**
```
grep -rn "POST /runs\b\|GET /runs/\|DELETE /runs/\|PATCH /runs/" .factory/specs/ \
  | grep -v "schedule_id" | grep -v "threads/" | grep -v "bc-authoring-plan"
```
Output: EMPTY — zero flat run paths remaining.

---

## Sibling Reverse-Anchor Check — PASS

BC partition: P0 48 + P1 30 + P2 8 = 86 total. Count unchanged. No BC renumbering this pass.

All sibling checks from pass 22 (capabilities-p0.md anchor fix for ss-10/11/14) confirmed stable:
`grep -r "capabilities-p1-p2" .factory/specs/behavioral-contracts/ss-10 ss-11 ss-14` = empty.

---

## 7 Standing Census Rotations — PASS

| Census | Command | Result |
|--------|---------|--------|
| Lifecycle-arrow census (guideline #12) | `grep -rn "in_progress →\|→ interrupted\|⇄" .factory/specs/` | PASS — interrupted shows as pausable/resumable in all hits |
| DI-verbatim census (P11) | BC body DI description strings match canonical form | PASS — no stale descriptions found this pass |
| Cross-BC state-machine consistency (P11) | terminal set = {completed, failed, cancelled} | PASS |
| Shared-type census (P18/P19/P20) | `grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage\|\bCheckpointer\b" .factory/specs/` | PASS |
| E-code↔variant-name census (P20) | `grep -oE "E-[A-Z]+-[0-9]{3} [A-Z][A-Za-z]+"` → cross-check taxonomy | PASS |
| Capability-tier census (P21) | CAP priority vs BC P-levels for constituent BCs | PASS (no CAP priority changes this pass) |
| Reverse-anchor sweep (P22) | No CAP relocation this pass | PASS (not triggered) |

---

## Endpoint Census — PASS (post-fix)

| Path (canonical, post-fix) | Citing Docs | Scheme Verdict |
|---------------------------|-------------|---------------|
| `POST /threads/{thread_id}/runs` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
| `GET /threads/{thread_id}/runs` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
| `GET /threads/{thread_id}/runs/{run_id}` | interface-definitions.md, api-surface.md, BC-2.12.003, BC-2.12.007, BC-2.05.006 | PASS |
| `GET /threads/{thread_id}/runs/{run_id}/stream` | interface-definitions.md, api-surface.md, BC-2.12.007 | PASS |
| `POST /threads/{thread_id}/runs/{run_id}/resume` | interface-definitions.md, api-surface.md, BC-2.05.004, BC-2.05.005, BC-2.05.006, edge-cases.md | PASS |
| `POST /threads/{thread_id}/runs/{run_id}/cancel` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
| `DELETE /threads/{thread_id}/runs/{run_id}` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
| `POST /threads` | interface-definitions.md, api-surface.md, BC-2.12.001 | PASS |
| `GET /threads` | interface-definitions.md, api-surface.md, BC-2.12.001 | PASS |
| `GET /threads/{thread_id}` | interface-definitions.md, api-surface.md, BC-2.12.001 | PASS |
| `DELETE /threads/{thread_id}` | interface-definitions.md, api-surface.md, BC-2.12.001 | PASS |
| `GET /threads/{thread_id}/state` | BC-2.12.001 only | NOTE: not yet in api-surface.md or interface-definitions.md |
| `POST /threads/{thread_id}/state` | BC-2.12.001 only | NOTE: not yet in api-surface.md or interface-definitions.md |
| `GET /threads/{thread_id}/history?limit=N` | BC-2.12.001 only | NOTE: not yet in api-surface.md or interface-definitions.md |
| `POST /assistants` | interface-definitions.md, api-surface.md, BC-2.12.002 | PASS |
| `GET /assistants` | interface-definitions.md, api-surface.md, BC-2.12.002 | PASS |
| `GET /assistants/{assistant_id}` | interface-definitions.md, api-surface.md, BC-2.12.002 | PASS |
| `PUT /assistants/{assistant_id}` | interface-definitions.md, api-surface.md, BC-2.12.002 | PASS |
| `DELETE /assistants/{assistant_id}` | interface-definitions.md, api-surface.md, BC-2.12.002 | PASS |
| `GET /assistants/{assistant_id}/versions` | BC-2.12.002 only | NOTE: not yet in api-surface.md or interface-definitions.md |
| `POST /assistants/{assistant_id}/set_latest` | BC-2.12.002 only | NOTE: not yet in api-surface.md or interface-definitions.md |
| `POST /schedules` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
| `GET /schedules/{cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
| `PATCH /schedules/{cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
| `DELETE /schedules/{cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
| `GET /runs?schedule_id={cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS (intentional flat cross-thread aggregate) |
| `GET /_debug` | BC-2.12.005 only | PASS (internal debug route; no index entry needed) |

**NOTE paths** (BC only, not in api-surface.md/interface-definitions.md): Thread state
(`/threads/{thread_id}/state`, `/threads/{thread_id}/history`), assistant versioning
(`/assistants/{id}/versions`, `/assistants/{id}/set_latest`). These are correctly
specified in their BCs (BC-2.12.001 and BC-2.12.002) but not in the reference index docs.
Flagged for pass 24 endpoint completeness sweep if adversary probes these tables.

---

## Status-Code ↔ E-Code Census — PASS (post-fix)

| HTTP Code | E-code + Variant | Citing BCs | Verdict |
|-----------|-----------------|------------|---------|
| 201 | — (success) | BC-2.12.004 TV-001 (POST /schedules) | PASS |
| 202 | — (accepted async) | BC-2.12.003 PC5 (POST /threads/{id}/runs) | PASS |
| 204 | — (no content) | BC-2.12.004 PC5 (DELETE /schedules), BC-2.12.003 PC20 (DELETE /runs/{id}) | PASS |
| 400 | E-CRON-002 InvalidCronExpression | BC-2.12.004 EC-002 TV-006 | PASS (400 = validation error; E-CRON-NNN handled by 400 entry) |
| 404 | E-SERVER-002 RunNotFound | BC-2.12.003 PC14, TV-003, TV-004 | PASS |
| 404 | E-SERVER-003 ThreadNotFound | BC-2.12.003 PC2, EC-001 | PASS |
| 404 | E-SERVER-006 ScheduleNotFound | BC-2.12.004 EC-005 TV-007 | PASS |
| 409 | E-SERVER-007 ThreadAlreadyExists | BC-2.12.001 TV-002 | PASS |
| 409 | E-SERVER-012 ConcurrentRun | BC-2.12.003 EC-002 | PASS |
| 409 | E-SERVER-015 RunAlreadyExecuting | BC-2.12.007 TV-006 (two concurrent stream clients) | PASS |
| 409 | (terminal-state cancel) E-SERVER-* | BC-2.12.003 PC10 (cancel in terminal state) | PASS |
| 409 | (delete active run) | BC-2.12.003 PC19, EC-005 | PASS |
| 422 | E-GRAPH-002 NoActiveInterrupt | BC-2.05.005 TV-003 (fixed from 409) | PASS (E-GRAPH-* → 422 per interface-definitions.md) |
| 422 | (invalid assistant_id) | BC-2.12.003 PC3 | PASS |
| 429 | E-PROV-001 | interface-definitions.md §HTTP Status Codes | PASS |
| 500 | E-SERVER-014 RunStoreFailed | BC-2.12.006 EC-004 | PASS |
| 403 | E-SERVER-004 DebugRouteUnauthorized | BC-2.12.005 TV-002/003 | PASS |

**Status-code fix this pass:** BC-2.05.005 TV-003 changed from `HTTP 409` to `HTTP 422`
to resolve documented ambiguity; authoritative mapping `E-GRAPH-* → 422` per
interface-definitions.md §HTTP Status Codes.

---

## Novel Probes (3) — MIXED

| Probe | Target | Result |
|-------|--------|--------|
| HTTP endpoint URL-scheme sweep | All `/runs/...` and `/schedules/...` path strings in specs/ | F-P23-01 (see above) — FAIL (fixed) |
| Status-code↔E-code census (NEW CLASS) | interface-definitions §HTTP Status Codes vs every BC-stated HTTP code | HTTP 409 for E-GRAPH-002 NoActiveInterrupt in BC-2.05.005 → fixed to 422 |
| api-surface completeness (NEW CLASS) | All endpoint rows in api-surface.md vs all endpoints in BC bodies | NOTE paths flagged (BC-only; not a blocking failure) |

---

## New Standing Gates

1. **HTTP endpoint census (guideline #17):** URL-scheme consistency + canonical path table +
   status-code↔E-code table. Added to bc-authoring-plan.md §Authoring Guidelines.
   Trigger: any BC authoring or fix burst that adds, moves, or renames an HTTP endpoint path.
   Quick census command: `grep -rn "POST /runs\b\|GET /runs/\|DELETE /runs/\|PATCH /runs/" .factory/specs/ | grep -v "schedule_id" | grep -v "threads/" | grep -v "bc-authoring-plan"` — output must be EMPTY.
