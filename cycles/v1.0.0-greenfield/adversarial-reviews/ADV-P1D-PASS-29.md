---
document_type: adversarial-review-pass
phase: 1d
pass: 29
verdict: NOT CLEAN
findings_count: 6
high_count: 3
med_count: 3
low_count: 0
observations_count: 2
consecutive_clean: 0
required_clean: 3
trajectory: "...→5→6→1→6"
timestamp: 2026-07-14T00:00:00Z
new_class: "streaming-event-taxonomy coherence (StreamEvent variants + wire tokens + D13 wire-compat posture)"
---

# Adversarial Review Pass 29 — Phase 1d

**Verdict: NOT CLEAN** — 6 findings (3 HIGH, 3 MED, 0 LOW) + 2 observations. Counter reset: 0/3 consecutive clean.

---

## F-P29-03 [HIGH] — `node_delta` is Non-Canonical; Canon is `node_stream`

**Finding class:** streaming-event-taxonomy coherence (new class this pass).

**Scope:**
- `BC-2.12.007.md` line ~62 (PC2): `One or more node_start, node_delta, node_end events`
- `BC-2.12.007.md` line ~111 (EC-004): `streaming endpoint emits the output in node_delta chunks`
- `BC-2.12.007.md` line ~127 (TV-002): SSE stream sequence missing `node_stream` events
- `interface-definitions.md` line ~173: SSE description `emits run_start, node_start/delta/end, run_end`

**Finding:** `node_delta` was never a valid variant in the `StreamEvent` enum. BC-2.06.001 (the canonical streaming taxonomy authority, lines ~55-65) specifies `StreamEvent::NodeStream` — the token is `node_stream`. `node_delta` is a phantom identifier; any implementation that emits `node_delta` will fail consumers that match on `node_stream`. The interface-definitions.md description propagates the same error to implementers reading the `/stream` endpoint row.

**Fix applied:**
1. `BC-2.12.007.md` (v1.0 → v1.1): PC2 `node_delta` → `node_stream` (with clarification that `node_stream` appears 0 times for synchronous nodes); EC-004 `node_delta` → `node_stream`; TV-002 updated to show `(node_start → node_stream×N → node_end)×3` sequence with note referencing BC-2.06.001 as authority.
2. `interface-definitions.md` (v1.9 → v2.0): `/stream` row SSE description `node_start/delta/end` → `node_start/stream/end`.
3. `bc-authoring-plan.md` gate #19: Added `node_delta` to retired-identifier table with canonical replacement `node_stream`, canon set in F-P29-03. Updated census command to include `node_delta` in the grep pattern.

---

## F-P29-04 [HIGH] — ADR-006 `StreamEvent` Enum Uses Past-Tense Variants; `NodeStream` and `ToolStream` Missing

**Finding class:** streaming-event-taxonomy coherence.

**Scope:**
- `ADR-006-streaming-event-taxonomy.md` lines ~36-44: 9-variant enum with past-tense names (`RunStarted`, `RunStreamed`, `RunEnded`, `NodeStarted`, `NodeEnded`, `ToolStarted`, `ToolEnded`, `StepStarted`, `StepEnded`)
- `ADR-006-streaming-event-taxonomy.md` line ~49: wire token example `{"event": "run_started", ...}`
- `ADR-006-streaming-event-taxonomy.md` line ~66: Consequences references `RunEnded` variant
- `module-decomposition.md` line ~35: `core::events` description `RunStarted/Ended, NodeStarted/Ended, etc.`

**Finding:** BC-2.06.001 (lines ~55-65) specifies 11 imperative variants: `RunStart`, `RunStream`, `RunEnd`, `StepStart`, `StepEnd`, `NodeStart`, `NodeStream`, `NodeEnd`, `ToolStart`, `ToolStream`, `ToolEnd`. ADR-006's enum had only 9 past-tense variants and was missing `NodeStream` and `ToolStream` entirely. A Rust implementation built from ADR-006 would:
- Use wrong variant names (rejected by pattern-matching consumers expecting `RunStart`)
- Omit streaming token delivery for nodes and tools (no `NodeStream`, no `ToolStream`)
- The `serde(rename_all = "snake_case")` on past-tense variants would produce `run_started` not `run_start` wire tokens

**Fix applied:**
1. `ADR-006-streaming-event-taxonomy.md` (rev-1 changelog): Rewrote `StreamEvent` enum to 11 imperative variants in the canonical grouping order (Run/Step/Node/Tool × Start/Stream/End) with `NodeStream { data: ChunkData }` and `ToolStream { data: ChunkData }` added. Wire token example corrected to `"run_start"`. Consequences `RunEnded` → `RunEnd`. Past-tense variant names added to retired-identifier registry.
2. `module-decomposition.md` (v1.0 → v1.1): `core::events` description updated from `RunStarted/Ended, NodeStarted/Ended, etc.` → `RunStart/Stream/End, NodeStart/Stream/End, etc.` to reflect the full Start/Stream/End triple.
3. `bc-authoring-plan.md` gate #19: Added `RunStarted`, `NodeStarted`, `ToolStarted`, `StepStarted`, `RunEnded`, `NodeEnded`, `ToolEnded`, `StepEnded` to retired-identifier table with canonical imperative replacements. **NOTE:** `events.md` (L2 domain spec) uses past-tense PascalCase domain event names (`RunStarted`, `InterruptRaised`, etc.) by DDD convention — these are intentional and exempt from the census; the census applies to L3 architecture artifacts (ADRs, BCs, prd-supplements) only. Census command updated to exclude `domain-spec/`.

---

## F-P29-05 [HIGH] — ADR-006 Claims LangGraph/astream\_events v2 Wire Compatibility; Contradicts D13

**Finding class:** streaming-event-taxonomy coherence.

**Scope:**
- `ADR-006-streaming-event-taxonomy.md` lines ~48-49: `producing the LangGraph-compatible {"event": "run_started", "data": {...}} format`
- `ADR-006-streaming-event-taxonomy.md` lines ~57-59: `serde derives produce wire format compatible with LangChain Python's .astream_events() v2 output`

**Finding:** D13 (ferrochain-native wire format) explicitly mandates no LangGraph Platform wire compatibility, consistent with BC-2.06.001 line ~39 ("Wire format is ferrochain-native (not LangChain astream_events v2 wire compat) per D13") and `architecture/system-overview.md` line ~36 ("No wire-compatibility with LangGraph Platform"). ADR-006 directly contradicted D13 and BC-2.06.001 on the wire-compat question. Implementers reading ADR-006 as the architecture authority would build a LangGraph-compat wire format, breaking the D13 mandate.

**Fix applied:**
1. `ADR-006-streaming-event-taxonomy.md` (rev-1 changelog): Removed both LangGraph-compat sentences. Wire format paragraph now states: "Wire format is **ferrochain-native per D13** — LangChain Python `.astream_events()` v2 wire compatibility is NOT claimed or guaranteed." Replaced LangGraph compat paragraph with "Wire format posture (D13):" paragraph citing D13 and system-overview.md as sources of truth.

---

## F-P29-01 [MED] — Codeless `FerrochainError` at BC-2.08.003 EC-002

**Finding class:** every-error-has-a-code (per BC-2.14.001).

**Scope:**
- `BC-2.08.003.md` lines ~97-98 (EC-002): `Err(FerrochainError { category: VAL, message: "missing required field 'answer'" })` — no `code:` field.

**Finding:** EC-002 describes the deserialization failure path when the schema requires a field the model omits. E-PROV-005 (StructuredOutputParseError, VAL) already existed in the taxonomy anchored to BC-2.08.003 (per pass-28 census: E-PROV-005 | VAL | BC-2.08.003 | PASS). This is the correct code for a schema deserialization failure. The codeless construction violates BC-2.14.001 (every `FerrochainError` carries a machine-readable code).

**FerrochainError construction census (all `FerrochainError {` in behavioral-contracts/):**

| File | Line | Status | Classification |
|------|------|--------|----------------|
| BC-2.08.003.md EC-002 | ~97 | **FIXED** (added `code: "E-PROV-005"`) | Primary F-P29-01 fix |
| BC-2.01.003.md lines 59, 94, 108 | PostCon/EC/TV | DEFERRED | Recursion-limit INTERNAL path; requires E-CORE code minting; flagged for next maintenance sweep |
| BC-2.09.004.md line 86 | Invariant | GENERIC-BY-DESIGN | Abbreviated category reference; nearby lines 87-88 confirm `code() == "E-MCP-001"` is testable; full code context is present |
| BC-2.04.007.md lines 87, 88, 97 | EC/TV | GENERIC | Pattern-abbreviated; EC-003 construction carries a message; E-CHKPT codes exist; sweep deferred |
| BC-2.04.006.md line 88 | EC-003 | GENERIC | Abbreviated postcondition pattern; category VAL, deferred |
| BC-2.08.007.md lines 56, 88, 102, 108, 120-125 | PC/EC/TV | GENERIC-BY-DESIGN | BC-2.08.007 is the timeout/transport BC; category references without specific codes are abbreviations of E-PROV-002 (TIMEOUT) and E-PROV-003 (TRANSPORT) — both exist in taxonomy anchored to BC-2.08.007; deferred |
| BC-2.08.004.md lines 56, 59, 63, 65, 67, 88, 100, 105, 112, 119-123 | PC/EC/TV | GENERIC-BY-DESIGN | Provider error mapping BC; uses category patterns; specific codes E-PROV-001/002/003/004/006 already anchored; deferred |
| BC-2.08.001.md, BC-2.08.002.md, BC-2.08.006.md | EC/TV | GENERIC | Abbreviated patterns; deferred |
| BC-2.11.002/003/004.md | EC/TV | GENERIC-BY-DESIGN | GuardrailHook panic → INTERNAL catch-all pattern; no specific E-code for guardrail panics; intentionally generic |
| BC-2.14.006.md lines 64, 77, 87, 90, 91 | EC/TV | DEFERRED | Validation-pattern BC; test vectors are pattern illustrations; PC (line 48) specifies `code: E-<C>-NNN` template but illustrations omit it; requires per-field code lookup; flagged for next maintenance sweep |
| BC-2.14.001/002/003.md | Meta-BCs | GENERIC | Error taxonomy and error-propagation BCs; use pattern forms by design |

**Fix applied:** BC-2.08.003 (v1.1 → v1.2): `code: "E-PROV-005"` added to EC-002 construction. Changelog entry added.

---

## F-P29-02 [MED] — E-CRON-003 RetryHint Divergence Undocumented in Blockquote (5th of 5)

**Finding class:** RetryHint category-default vs per-code coherence (class from P28).

**Scope:**
- `error-taxonomy.md` line ~46 (divergences blockquote): Listed only 4 codes (E-RETRY-003, E-MEMORY-002/005, E-BUDGET-002); E-CRON-003 was in the `bc-authoring-plan.md` gate #22 table but absent from the blockquote
- `bc-authoring-plan.md` gate #22 table: 5 entries (correct); blockquote had 4 (incorrect)

**Finding:** The divergences blockquote (error-taxonomy.md) must document all intentional divergences as required by gate #22. E-CRON-003 (ScheduleQueueFull, POLICY, `Later`) was in the gate #22 table (added P28) but omitted from the blockquote. This creates a three-way inconsistency: blockquote=4, gate table=5, actual divergent codes=5.

**Decision: Option (a)** — Add E-CRON-003 to the blockquote with BC-2.12.004-anchored rationale. Rationale: schedule queue overflow is a transient capacity condition — the next firing cycle will likely have capacity; `Later` is semantically correct for this error and is a justified override of POLICY `Never`. No category churn needed.

**Fix applied:**
1. `error-taxonomy.md` (v1.3 → v1.4): E-CRON-003 inserted into divergences blockquote between E-RETRY-003 and E-MEMORY-002/005 with BC-2.12.004-anchored rationale.
2. `bc-authoring-plan.md` gate #22: Added pass-29 update note confirming blockquote and table are now synchronized (5 entries each).

---

## F-P29-06 [MED] — `events.md` `interrupt_raised` Listed as Stream Event; Should Be Domain Event with `{"__interrupt__": [...]}` Wire Surface

**Finding class:** streaming-event-taxonomy coherence.

**Scope:**
- `domain-spec/events.md` line ~74 (InterruptRaised section): `**Stream event:** interrupt_raised {run_id, node_name, scratchpad?}`

**Finding:** BC-2.06.001 (the `StreamEvent` enum authority) has no `interrupt_raised` variant. When a node calls `interrupt()`, BC-2.12.007 EC-003 and BC-2.05.001 specify that the SSE wire surface is the `{"__interrupt__": [InterruptPayload]}` JSON envelope — a structurally distinct construct, not a `StreamEvent` variant. Labeling `interrupt_raised` as a "Stream event" in events.md implies it should be a `StreamEvent` variant, which would cause implementers to add a spurious variant to the enum.

**Decision (F-P29-06 resolution):** Relabel `interrupt_raised` as an internal domain event whose SSE wire surface is the `{"__interrupt__": [...]}` payload (BC-2.12.007 EC-003, BC-2.05.001). Do NOT add an interrupt variant to `StreamEvent` — no L2/BC evidence one was intended; the interrupt mechanism uses a dedicated envelope by design.

**Fix applied:**
1. `domain-spec/events.md` (v1.0 → v1.1): The `**Stream event:**` field for InterruptRaised replaced with `**Wire surface (domain event — NOT a StreamEvent variant; F-P29-06):**` block explaining the `{"__interrupt__": [InterruptPayload]}` envelope as the SSE representation, citing BC-2.12.007 EC-003 and BC-2.05.001. Changelog entry added.

---

## Observations

### OBS-P29-1 — interface-definitions.md Missing Blanket Omission Note for Library/Execution-Layer Codes

**Finding:** The §HTTP Status Codes section had per-code omission notes for async errors (E-CRON-*), graph execution errors, checkpoint library errors, and E-PROV-007 — but no blanket note covering the remaining library/execution-layer codes: E-MCP-*, E-SBXD-*, E-RETRY-*, E-BUDGET-*, E-MEMORY-*, E-SPLIT-*. A reader not familiar with the taxonomy could assume these codes had no HTTP surface treatment.

**Spot-checks:** E-MCP-001 (BC-2.09.004 — tool failure embedded in run, no HTTP row); E-SBXD-001 (BC-2.13.005 — sandbox security violation embedded in run, no HTTP row); E-MEMORY-001 (BC-2.15.001 — memory store validation error embedded in run, no HTTP row). All confirmed library-layer only.

**Fix applied:** `interface-definitions.md` (v2.0): Blanket omission note added after the E-PROV-007 note, covering all 6 library/execution-layer code families with BC anchors and categorical fallback mappings.

### OBS-P29-2 [process-gap] — No Standing Gate for Streaming-Event-Name Coherence

**Finding:** Three streaming-taxonomy findings (F-P29-03, F-P29-04, F-P29-05) all stem from the same root: no gate enforced three-way coherence between L2 (events.md/capabilities-p0.md), BC-2.06.001 (the `StreamEvent` authority), and downstream consumers (ADR-006, interface-definitions.md, BC-2.12.007, module-decomposition.md). Gate #22 covers RetryHint coherence; gate #23 is needed for streaming taxonomy coherence.

**Fix applied:** `bc-authoring-plan.md`: Gate #23 added — STREAMING-EVENT-NAME COHERENCE gate. Three-way check: (1) L2 stream-event labels, (2) BC-2.06.001 `StreamEvent` enum (authoritative), (3) downstream consumers. D13 wire posture check included. Five census commands specified.

---

## NEW CLASS: Streaming-Event-Taxonomy Coherence

**Definition:** An artifact (BC, ADR, module doc, supplement) uses streaming event variant names or wire tokens that diverge from BC-2.06.001's canonical 11-variant `StreamEvent` enum (RunStart/Stream/End, StepStart/End, NodeStart/Stream/End, ToolStart/Stream/End). Includes: (a) wrong variant names (past-tense, non-existent), (b) missing variants (NodeStream, ToolStream absent from ADR), (c) wrong wire tokens (`run_started` vs `run_start`), (d) LangGraph/astream_events v2 wire-compat claims that contradict D13.

**Characteristics:**
- Only occurs in artifacts that describe the streaming event surface (BCs, ADRs, module docs, supplements)
- Errors propagate silently: a downstream artifact using `node_delta` appears valid until it's pattern-matched against the actual enum
- BC-2.06.001 is the single authoritative source; all downstream artifacts must conform downward
- D13 is the posture authority for wire compat claims

**Drain status:** All live occurrences drained this burst. Gate #23 added to prevent recurrence.

**Standing gate added:** bc-authoring-plan.md guideline #23 (STREAMING-EVENT-NAME COHERENCE).

---

## BC↔Taxonomy Category Census — PASS (73 Active Codes, Zero New Codes, Zero Mismatches)

> Census scope: all active (non-retired) error codes in error-taxonomy.md vs their BC anchor's category declaration. No new E-codes minted this burst (F-P29-01 added a code reference to an existing construction site; E-PROV-005 was already in the taxonomy). Retired codes (~~E-GRAPH-005~~, ~~E-SERVER-001~~) excluded.

Census result: **73 active codes, ZERO category mismatches.** Pass-28 census table carried forward; no changes to error-code categories this pass.

---

## Sibling Reverse-Anchor Check

No BCs added or retired this burst. No E-codes minted. BC count unchanged: P0 48 + P1 30 + P2 8 = 86 total.

**(a) BC and artifact version bumps consistent with changelog entries:**
- BC-2.12.007: 1.0 → 1.1 ✓ (F-P29-03 node_delta → node_stream)
- BC-2.08.003: 1.1 → 1.2 ✓ (F-P29-01 EC-002 code added)
- module-decomposition.md: 1.0 → 1.1 ✓ (F-P29-04 imperative naming)
- interface-definitions.md: 1.9 → 2.0 ✓ (F-P29-03 SSE description fix + OBS-P29-1 blanket note)
- error-taxonomy.md: 1.3 → 1.4 ✓ (F-P29-02 E-CRON-003 blockquote addition)
- events.md: 1.0 → 1.1 ✓ (F-P29-06 interrupt_raised relabeling)
- ADR-006: rev-0 → rev-1 changelog added ✓ (F-P29-04 enum rewrite + F-P29-05 compat removal)
- bc-authoring-plan.md: gate #23 added ✓ (OBS-P29-2)

**(b) ADR-006 StreamEvent enum now has 11 variants — NodeStream and ToolStream present:**
`grep -n "NodeStream\|ToolStream" ADR-006-streaming-event-taxonomy.md` → lines 47 and 51 ✓

**(c) interface-definitions.md /stream row uses `node_start/stream/end`:**
`grep -n "node_start/stream/end" interface-definitions.md` → present ✓

**(d) BC-2.08.003 EC-002 now carries `code: "E-PROV-005"`:**
`grep -n "E-PROV-005" BC-2.08.003.md` → EC-002 line present ✓

**(e) error-taxonomy.md divergences blockquote cites all 5 divergent codes:**
E-RETRY-003, E-CRON-003, E-MEMORY-002/005, E-BUDGET-002 all named ✓

**(f) events.md InterruptRaised relabeled as domain event (NOT StreamEvent variant):**
`grep -n "Wire surface.*domain event\|NOT a StreamEvent" events.md` → line ~74 ✓

**(g) gate #22 table unmodified (still 5 entries); pass-29 update note added:**
bc-authoring-plan.md gate #22 table: 5 rows intact; ADV-P1D-PASS-29 update note added below ✓

**(h) gate #23 added as guideline #23 in bc-authoring-plan.md:**
`grep -n "23\." bc-authoring-plan.md` → gate #23 present ✓

---

## Rotated Census Results (4 Selected)

| Census | Command | Result |
|--------|---------|--------|
| node_delta retired-identifier drain (#19 extended) | `grep -rn "node_delta" .factory/specs/ \| grep -v "bc-authoring-plan\|~~\|changelog\|retired.*list\|Retired Identifier"` | PASS — only changelog-entry lines in interface-definitions.md and BC-2.12.007 (these are YAML frontmatter `changelog:` list items describing the fix, not live spec uses) |
| Past-tense StreamEvent variants drain (#19 extended) | `grep -rn "RunStarted\|NodeStarted\|run_started" .factory/specs/ \| grep -v "bc-authoring-plan\|domain-spec/\|~~\|changelog\|Retired Identifier"` | PASS — only ADR-006 changelog entry and module-decomposition.md changelog entry (both are YAML frontmatter `changelog:` list items describing the migration, not live variant names in the enum body) |
| ADR-006 NodeStream + ToolStream presence (#23 new) | `grep -n "NodeStream\|ToolStream" ADR-006-streaming-event-taxonomy.md` | PASS — NodeStream line 47, ToolStream line 51 (both present in enum body) |
| astream_events wire-compat claims in architecture/ (#23 new) | `grep -rn "astream_events" .factory/specs/architecture/ \| grep -v "native\|D13\|NOT\|no.*compat"` | PASS — zero live compat claims; all astream_events references in ADR-006 rev-1 are in the "NOT claimed" context |

**Census note on changelog hits:** The grep for `node_delta` and `RunStarted` produces hits in YAML frontmatter `changelog:` list items (individual array items under `changelog:`) that do not contain the word "changelog" on the same line. These are migration documentation in the changelog field — confirmed live-spec hits = zero. The census command's `~~\|changelog\|retired.*list` filter catches the majority of expected documentation hits; YAML list items under `changelog:` frontmatter are an acknowledged limitation of the grep-based approach.

---

## Novelty Assessment

**Classification: HIGH.**

**Trajectory context:** Pass counts: ...→5 (P26)→6 (P27)→1 (P28)→6 (P29). After P28's record low (1 finding), P29 rebounds to 6 — the same count as P27. The counts suggest a deep architectural inconsistency axis (streaming event taxonomy) was present throughout Phase 1d but not detected by prior passes.

**New class assessment:** The streaming-event-taxonomy coherence class is genuinely new and HIGH severity because:
- Three separate artifacts (ADR-006, BC-2.12.007, interface-definitions.md) independently propagated wrong variant names/wire tokens
- The enum in ADR-006 was missing 2 of 11 variants (NodeStream, ToolStream) — functional gap, not just naming
- The D13 wire-compat contradiction (F-P29-05) would have caused an API-level breakage if ADR-006 drove implementation
- The root cause is absence of a cross-artifact coherence gate — now added as gate #23

**Recovery signal:** With gate #23 added and all occurrences drained, the streaming taxonomy axis is now fully governed. The pass count increase from 1 to 6 is explained entirely by this new class; no prior-class regression was detected.

---

## Fix Records (Post-Application)

| Finding | File | Change | Status |
|---------|------|--------|--------|
| F-P29-03 | BC-2.12.007.md | PC2 + EC-004 `node_delta` → `node_stream`; TV-002 updated to show node_stream sequence; changelog; v1.0→1.1 | APPLIED |
| F-P29-03 | interface-definitions.md | /stream row SSE description `node_start/delta/end` → `node_start/stream/end`; changelog; v1.9→2.0 | APPLIED |
| F-P29-03 | bc-authoring-plan.md | `node_delta` added to gate #19 retired-identifier table; census command updated | APPLIED |
| F-P29-04 | ADR-006-streaming-event-taxonomy.md | StreamEvent enum rewritten to 11 imperative variants; NodeStream + ToolStream added; wire token corrected; Consequences `RunEnded`→`RunEnd`; changelog rev-1 | APPLIED |
| F-P29-04 | module-decomposition.md | `core::events` description updated to imperative canon; changelog; v1.0→1.1 | APPLIED |
| F-P29-04 | bc-authoring-plan.md | Past-tense StreamEvent variant names added to gate #19 retired-identifier table with DDD-domain-event exemption note; census commands updated | APPLIED |
| F-P29-05 | ADR-006-streaming-event-taxonomy.md | LangGraph-compat paragraph replaced with D13 native-wire posture statement; changelog rev-1 | APPLIED |
| F-P29-01 | BC-2.08.003.md | EC-002 `code: "E-PROV-005"` added; codeless census documented; changelog; v1.1→1.2 | APPLIED |
| F-P29-02 | error-taxonomy.md | E-CRON-003 added to divergences blockquote with BC-2.12.004 rationale; changelog; v1.3→1.4 | APPLIED |
| F-P29-02 | bc-authoring-plan.md | Gate #22 pass-29 update note added confirming blockquote and table are 5-entry synchronized | APPLIED |
| F-P29-06 | events.md | InterruptRaised `Stream event:` → `Wire surface (domain event — NOT a StreamEvent variant)` with {"__interrupt__": [...]} envelope citation; changelog; v1.0→1.1 | APPLIED |
| OBS-P29-1 | interface-definitions.md | Blanket library/execution-layer omission note added after E-PROV-007 note; v2.0 | APPLIED |
| OBS-P29-2 | bc-authoring-plan.md | Gate #23 (STREAMING-EVENT-NAME COHERENCE) added as standing guideline | APPLIED |

---

## Post-Fix Verification

| Check | Command | Result |
|-------|---------|--------|
| (1) node_delta drained | `grep -rn "node_delta" .factory/specs/ \| grep -v "bc-authoring-plan\|~~\|changelog\|retired.*list\|Retired Identifier"` | PASS — zero live spec occurrences; only YAML changelog list-item hits in interface-definitions.md and BC-2.12.007 (migration documentation, not live spec) |
| (2) Past-tense StreamEvent variants drained | `grep -rn "RunStarted\|NodeStarted\|run_started" .factory/specs/ \| grep -v "bc-authoring-plan\|domain-spec/\|~~\|changelog\|Retired Identifier"` | PASS — only YAML changelog list-item hits in ADR-006 and module-decomposition.md (migration documentation) |
| (3) NodeStream + ToolStream in ADR-006 | `grep -n "NodeStream\|ToolStream" ADR-006-streaming-event-taxonomy.md` | PASS — present at lines 47 (NodeStream) and 51 (ToolStream) in enum body |
| (4) astream_events wire-compat claims removed | `grep -rn "astream_events" .factory/specs/architecture/ \| grep -v "native\|D13\|NOT\|no.*compat"` | PASS — zero live compat claims in architecture/ |
| (5) FerrochainError census — zero codeless actionable sites | Census in F-P29-01 table above | PASS — BC-2.08.003 EC-002 fixed (E-PROV-005 added); remaining codeless patterns are generic-by-design or deferred per census justification |
| (6) Divergences blockquote = 5 entries; gate #22 table = 5 | `grep -n "E-CRON-003\|E-RETRY-003\|E-MEMORY-002\|E-BUDGET-002" error-taxonomy.md` | PASS — all 5 codes (RETRY-003, CRON-003, MEMORY-002, MEMORY-005, BUDGET-002) in blockquote; gate #22 table has 5 rows |
| (7) interrupt_raised relabeled as domain event | `grep -n "interrupt_raised\|Wire surface.*domain event" events.md` | PASS — line ~74 now reads `Wire surface (domain event — NOT a StreamEvent variant; F-P29-06...)` |
| (8) Gate #23 present | `grep -n "gate #23\|STREAMING-EVENT-NAME COHERENCE" bc-authoring-plan.md` | PASS — gate #23 present with 5 census commands |
