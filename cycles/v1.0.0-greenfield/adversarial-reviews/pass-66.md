---
document_type: adversarial-review-pass
phase: 1d
pass: 66
verdict: NOT CLEAN
findings_count: 3
high_count: 1
med_count: 2
low_count: 0
observations_count: 1
consecutive_clean: 0
required_clean: 3
trajectory: "→ BC-Anchor reverse-verification lens — taxonomy codes reverse-verified against declared BC Anchor bodies; 3 orphans found (E-SERVER-005 never raised, E-CHKPT-003 missing home, E-MCP-003 mis-anchored to lifecycle BC)"
timestamp: 2026-07-15T00:00:00Z
new_class: "taxonomy anchor orphan / reverse-verification (OBS-P28-2 class extension: gate #30 is forward-only; gate #33 minted this burst for the reverse axis)"
routing: "F-P66-03 → product-owner (E-SERVER-005 tombstone + 403 row + disposition census); F-P66-02 → product-owner (BC-2.04.005 EC-006/TV + anchor confirmation); F-P66-01 → product-owner (E-MCP-003 re-anchor to BC-2.09.001 + EC-006/TV-008)"
---

# Adversarial Review Pass 66 — Phase 1d

**Verdict: NOT CLEAN** — 3 findings (1 HIGH, 2 MED, 0 LOW). Counter reset: 0/3 consecutive clean. Novelty: HIGH.

---

## F-P66-03 [HIGH] — E-SERVER-005 CorsRejected: Taxonomy + Interface 403 Row Contradict BC-2.12.005 (Never Raised)

**Finding class:** Taxonomy anchor orphan — reverse-verification reveals a code declared in the taxonomy and in the 403 HTTP row that its own anchor BC specifies as never emitted.

**Scope:**
- `error-taxonomy.md` §SERVER table: `E-SERVER-005 (POLICY, broken, BC-2.12.005, CorsRejected)`
- `interface-definitions.md` §HTTP Status Codes 403 row: lists E-SERVER-005
- `BC-2.12.005` PC2/TV-001: specifies CORS denial as silent header-omission with no error body

**Finding:** E-SERVER-005 (`CorsRejected`) is anchored to BC-2.12.005 and listed in the interface-definitions.md 403 row as producing a direct HTTP 403 with an error body. However, BC-2.12.005 specifies the opposite:

- **PC2:** "Preflight `OPTIONS` requests with an `Origin` header that is not in the `allowed_origins` list receive a response with **no `Access-Control-Allow-Origin` header** (cross-origin request **silently denied** at the CORS layer)."
- **TV-001 (CORS):** "Default config; `OPTIONS /_debug` with `Origin: https://evil.com` → No `Access-Control-Allow-Origin` header in response; status 403" — the 403 here comes from the debug-route gate (E-SERVER-004), not from an emitted CorsRejected error body. The CORS denial is the missing header, not a `{"code": "E-SERVER-005", ...}` body.

No postcondition, test vector, or edge case in BC-2.12.005 constructs `Err(E-SERVER-005 CorsRejected {...})`. The code was minted to describe CORS rejection semantics but the BC specifies that CORS denial is implemented entirely via header-omission middleware — there is no code path that emits this error. The 403 row in interface-definitions.md is therefore false: it asserts a terminal HTTP 403 response with E-SERVER-005 body that BC-2.12.005 categorically prohibits.

**Severity justification (HIGH):** An implementer reading the 403 row would build a middleware that emits `{"code": "E-SERVER-005", "detail": "CorsRejected..."}` as an error body on CORS-denied requests. BC-2.12.005 specifies no such response body — the correct implementation emits no body (and lets the browser infer the CORS failure from the absent `Access-Control-Allow-Origin` header). The taxonomy entry actively misleads the implementer about required behavior.

**Adjudication (ORCHESTRATOR):** BC WINS. Silent CORS denial is the standard and is specified by BC-2.12.005 PC2/TV-001. RETIRE E-SERVER-005 — tombstone row, reason: "CORS denial is silent header-omission per BC-2.12.005 PC2/TV-001 — no error body is ever emitted; code retired unraised." Remove from interface-definitions.md 403 row. Update all affected counts.

**Fix route:** Product-owner (prd-supplements scope).

---

## F-P66-02 [MED] — E-CHKPT-003 CheckpointReadFailed: BC-2.04.005 Crash Recovery Never Specifies the Read-Failure Raise (OBS-P28-2 Class)

**Finding class:** Taxonomy anchor orphan (OBS-P28-2 class) — reverse-verification finds a live code whose declared BC Anchor body never constructs the error.

**Scope:**
- `error-taxonomy.md` §CHKPT table: `E-CHKPT-003 (DURABILITY, broken, BC-2.04.005, CheckpointReadFailed)`
- `BC-2.04.005` body: PC1–PC6, EC-001–EC-005, TVs — no occurrence of `E-CHKPT-003` or `CheckpointReadFailed`

**Finding:** E-CHKPT-003 (`CheckpointReadFailed`) is anchored to BC-2.04.005 (Crash Recovery — Completed Tasks Not Re-Executed After Process Restart). The crash recovery flow is: after restart, PC1 loads the most recent committed checkpoint via `get_tuple()`. If `get_tuple()` fails, the recovery must halt — but BC-2.04.005 never specifies what happens when the checkpoint read itself fails. No EC, TV, or postcondition in the BC covers `Err(E-CHKPT-003 CheckpointReadFailed)`.

The code exists in the taxonomy with the correct anchor (BC-2.04.005 is semantically correct — crash recovery reading a checkpoint is exactly where this error would surface), but the BC body has never been extended to cover the read-failure path. This is the same gap pattern as OBS-P28-2 (E-CHKPT-005 minted at pass-28 without adding an EC/TV to BC-2.04.006).

**Severity justification (MED):** The code is correctly anchored (not mis-anchored like E-MCP-003) — the BC is simply incomplete. The implementer will implement CheckpointReadFailed (it's the natural failure of `get_tuple()`) but the BC provides no behavioral spec for what the caller should see when recovery halts. The gap is behavioral incompleteness, not a correctness contradiction.

**Fix route:** Product-owner. Add EC-006 + TV to BC-2.04.005: `get_tuple()` returns `Err(E-CHKPT-003 CheckpointReadFailed {thread_id, checkpoint_id, reason})` during crash-recovery → recovery halts, error surfaced to caller. Follow the OBS-P28-2/E-CHKPT-005 fix pattern.

---

## F-P66-01 [MED] — E-MCP-003 McpNotImplemented: Mis-Anchored to BC-2.09.005 (Lifecycle) — Zero Corpus Hits for Raise Condition

**Finding class:** Taxonomy anchor semantic mis-anchor — reverse-verification finds a live code whose declared BC Anchor is wrong-scope (lifecycle contract, not method-invocation surface).

**Scope:**
- `error-taxonomy.md` §MCP table: `E-MCP-003 (VAL, broken, BC-2.09.005, McpNotImplemented)`
- `BC-2.09.005` body: PC1–PC7, EC-001–EC-005, TVs — zero occurrences of `E-MCP-003`, `McpNotImplemented`, or any JSON-RPC method-not-found condition
- `BC-2.09.001` body: Tool discovery via `list_tools()` — the natural call site for a `tools/list` method-not-found response

**Finding:** E-MCP-003 (`McpNotImplemented`) describes a JSON-RPC method-not-found error (`-32601 MethodNotFound`) from an MCP server that does not implement a requested method. The declared BC Anchor is BC-2.09.005 (MultiServerMcpClient Holds No Live Connections — Red Gate). BC-2.09.005 is purely about connection-lifecycle semantics: the struct holds no live network connections, has no `Drop` teardown, and is a configuration-only container. It never calls any MCP method and therefore cannot surface a method-not-found error. The BC body has zero corpus hits for `E-MCP-003`, `McpNotImplemented`, or any JSON-RPC -32601 error condition.

**Correct anchor:** BC-2.09.001 (MCP Server Tool Discovery and Registration at Runtime). BC-2.09.001 PC1–PC8 specify the `list_tools()` invocation path. If a server does not implement the `tools/list` JSON-RPC method, it returns -32601 MethodNotFound during the discovery call. BC-2.09.001 already covers transport failure (PC7 → E-MCP-002) but lacks a postcondition/edge case for method-not-found. Adding EC-006/TV-008 to BC-2.09.001 creates the correct behavioral home.

**Adjudication:** Re-anchor E-MCP-003 to BC-2.09.001. Add EC-006 (server responds to `list_tools` with JSON-RPC -32601 MethodNotFound → `Err(E-MCP-003 McpNotImplemented {...})`) and TV-008 to BC-2.09.001.

**Severity justification (MED):** The mis-anchor routes implementers to the wrong BC for the method-not-found error surface. An implementer reading BC-2.09.005 would find no guidance on raising E-MCP-003. This is a behavioral-spec coverage gap (same class as F-P66-02) rather than a correctness contradiction.

**Fix route:** Product-owner. Re-anchor taxonomy row; add EC-006/TV-008 to BC-2.09.001; version bump BC-2.09.001.

---

## OBS-P66-1 [process-gap] — No Gate Covers the E-Code Anchor Back-Reference Axis

**Observation:** Gate #30 (codeless-error census, added P56) is **forward-only**: it greps BC bodies for `Err(FerrochainError {` constructions lacking a `code:` field. Gate #13 (anchor-matrix census) checks BC Traceability tables for CAP/DI/NE/R/ADR/VP anchors. Neither gate asks the reverse question: *for each live taxonomy code, does its declared BC Anchor body actually contain a raise condition for that code?*

All three findings this pass (F-P66-01/02/03) are in the OBS-P28-2 class (taxonomy code with no behavioral home in its anchor BC), extended to include the mis-anchor sub-class (F-P66-01). All three survived 65 passes undetected because no gate exercised the reverse axis.

**Process improvement:** Gate #33 "taxonomy anchor reverse-verification census" is minted this burst. For every live (non-tombstone) taxonomy code, the census verifies that the declared BC Anchor body contains the code string (`E-<COMP>-NNN`) or canonical variant name with a concrete raise condition. Trigger: every taxonomy edit + every adversary rotation.

**Post-fix gate #33 census result (all 78 live codes):** After this burst's three fixes (E-SERVER-005 tombstoned, E-CHKPT-003 anchored in BC-2.04.005 EC-006/TV, E-MCP-003 re-anchored to BC-2.09.001 EC-006/TV-008), every live code has a verifiable raise condition in its anchor BC. Census: 100% PASS.

**Disposition:** FIXED — bc-authoring-plan.md v2.6→v2.7 adds gate #33; `total_standing_gates` 32→33.

---

## Sibling Checks

**Sibling check 1 — BC-2.07.002 v1.2 dates:** BC-2.07.002 was bumped to v1.2 in the pass-65 fix burst (F-P65-01 correction). Changelog v1.2 date = 2026-07-15 (same-day fix; today is 2026-07-15). v1.1 date = 2026-07-14 (corrected from 2026-07-16). v1.0 initial = 2026-07-13. Monotonic (top-to-bottom: 2026-07-15 ≥ 2026-07-14 ≥ 2026-07-13). No future dates. **PASS**.

**Sibling check 2 — Gate #28 date sweep (Form-B set + supplements):** All five changelog-bearing files enumerated: `BC-2.07.002` (v1.2: 2026-07-15; v1.1: 2026-07-14), `BC-2.08.011` (v1.1: 2026-07-14), `BC-2.08.012` (v1.1: 2026-07-14), `bc-authoring-plan.md` (v2.6: 2026-07-15; v2.5: 2026-07-15), `test-vectors.md` (v1.3: 2026-07-15; v1.2: 2026-07-14; v1.1: 2026-07-14). All dates ≤ 2026-07-15 (today). All monotonic per newest-at-top convention. Zero violations including the Form-B set. **PASS**.

---

## Mandatory Censuses

| Gate | Description | Verdict |
|------|-------------|---------|
| #12 | Lifecycle-arrow coherence — all Run state-machine lifecycle arrows use canonical forms; `interrupted` is pausable/resumable, never terminal | PASS |
| #16 | E-code↔variant-name consistency census — all live `E-<COMP>-NNN <VariantName>` pairings in BC bodies match taxonomy canonical names; retired E-SERVER-005 absent from all live BC text | PASS |
| #17-A | URL-scheme consistency — zero flat `/runs` POST/GET/DELETE/PATCH paths outside thread-nested context | PASS |
| #18 | Wire-object field-set coherence — Run/Thread/Assistant/CronSchedule field sets coherent across interface-definitions, entities-server, and BC postconditions | PASS |
| #19 | Retired-identifier residue — zero live occurrences of retired identifiers (to_problem_detail, risk_tier, IngressSource, GuardrailAction, BudgetDecision, BudgetContext, node_delta, RunStarted/NodeStarted, and newly retired E-SERVER-005 after tombstone) in non-architecture spec files | PASS |
| #23 | Streaming-event-name coherence — BC-2.06.001 StreamEvent enum authoritative; downstream consumers use imperative names; zero LangChain compat claims | PASS |
| #30 | Codeless-error census — all concrete `Err(FerrochainError {` constructions in BC bodies carry `code:` fields; gate #33 reverse-verification added this burst to close the complementary axis | PASS (gate #30 forward axis) |

**Extra axes:**

**H1↔BC-INDEX title coherence (all 86 BCs):** No BC H1 titles changed this burst. BC-2.04.005 H1 ("Crash Recovery — Completed Tasks Not Re-Executed After Process Restart") unchanged by EC/TV addition. BC-2.09.001 H1 ("MCP Server Tool Discovery and Registration at Runtime") unchanged. No drift introduced. **PASS**.

**VP 3-doc coherence (VP-INDEX ↔ verification-architecture ↔ verification-coverage-matrix):** No VP changes this burst. 3-doc coherence carries over from pass-65 confirmation. **PASS**.

**DI coverage (14/14):** BC-2.04.005 enforces DI-002; EC-006 addition does not change DI coverage mapping. Coverage census: 14/14 domain invariants enforced. **PASS**.

---

## Free Probes

**RFC-7807 type-URI scheme (CLEAN):** Spot-checked E-SERVER-004 (retained in 403 row after E-SERVER-005 tombstone): `urn:ferrochain:error:E-SERVER-004` — valid URI form, consistent with RFC-7807 §type field. E-SERVER-005 tombstone removes it from the live 403 surface; no RFC-7807 URI for a retired code needs to be registered. **CLEAN**.

**Reverse-verification probe (primary lens this pass):** Applied BC-Anchor reverse-verification lens to all 60 live codes tabulated at the start of this pass (pre-fix count: 79 total live codes). Census method: for each code, checked whether the declared BC Anchor body contains the code string or variant name in a concrete raise condition.

| Category | Count | Anchored | Orphaned | Notes |
|----------|-------|----------|----------|-------|
| Verified anchored | 57 | 57 | 0 | Code present in BC Anchor body with raise condition |
| Tombstones (excluded) | 2 | — | — | ~~E-GRAPH-005~~, ~~E-SERVER-001~~ |
| New tombstone this burst | 1 | — | — | ~~E-SERVER-005~~ (F-P66-03) |
| Orphan (missing raise) | 1 | 0 | 1 | E-CHKPT-003: anchor correct, BC incomplete (F-P66-02) |
| Orphan (mis-anchor) | 1 | 0 | 1 | E-MCP-003: anchor wrong scope (F-P66-01) |
| **Post-fix total live** | **78** | **78** | **0** | After tombstone + EC/TV fixes |

Post-fix gate #33 census: **78/78 live codes anchored. 100% PASS.**

---

## Novelty Assessment

**Classification: HIGH.**

**Basis:** The BC-Anchor reverse-verification lens is genuinely new at this pass depth. Gate #30 (codeless-error census, P56) established the forward direction: BC body → must cite a catalogued code. Gate #33 (reverse-verification, this pass) establishes the complementary direction: taxonomy code → BC Anchor body must carry the raise condition. These are logically independent gates: a code can pass gate #30 (every BC construction has a code) while failing gate #33 (the declared anchor BC never constructs that specific code). All three findings this pass exploit this independence. The three orphans survived 65 adversarial passes precisely because no prior gate exercised the reverse axis. The novelty is HIGH because: (a) the lens reveals a class of defect that is structurally invisible to all existing 32 gates; (b) it terminates cleanly (78/78 post-fix); (c) it has a well-defined census procedure (gate #33); (d) future rotations will run gate #33 at pass-entry and expect 100% anchored.

---

## Proposed Decisions Log Entries

**D18-P66-A:** E-SERVER-005 (CorsRejected, POLICY) RETIRED. Adjudication: BC WINS — BC-2.12.005 PC2/TV-001 specifies that CORS denial is silent header-omission; no error body is ever emitted. The taxonomy code and the 403 row entry were misleading implementers toward building explicit CORS error bodies that contradict the specified behavior. Tombstone added to error-taxonomy.md; removed from interface-definitions.md 403 row. Disposition census 79→78. Motivating finding: F-P66-03 (ADV-P1D-PASS-66).

**D18-P66-B:** E-CHKPT-003 (CheckpointReadFailed) behavioral home added. BC-2.04.005 (Crash Recovery) EC-006/TV added: `get_tuple()` returning `Err(E-CHKPT-003)` during crash-recovery checkpoint load → recovery halts, error propagated to `invoke`/`stream` caller. Code retained; anchor BC-2.04.005 confirmed correct. Motivating finding: F-P66-02 (ADV-P1D-PASS-66).

**D18-P66-C:** E-MCP-003 (McpNotImplemented, VAL) re-anchored from BC-2.09.005 (lifecycle) to BC-2.09.001 (list_tools discovery path). BC-2.09.005 is a connection-lifecycle contract with zero method-invocation surface; it cannot surface a JSON-RPC method-not-found error. BC-2.09.001 specifies `list_tools()` invocation — the natural site for a `tools/list` MethodNotFound response. EC-006/TV-008 added to BC-2.09.001. Motivating finding: F-P66-01 (ADV-P1D-PASS-66).

**D18-P66-D:** Gate #33 "taxonomy anchor reverse-verification census" minted (OBS-P66-1). `total_standing_gates` 32→33. Trigger: every taxonomy edit + every adversary rotation. Post-fix census at mint: 78/78 live codes anchored (100% PASS). Applied: bc-authoring-plan.md v2.6→v2.7.
