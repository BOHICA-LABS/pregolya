---
document_type: bc-index
level: L3
version: "3.14"
status: active
producer: state-manager
timestamp: 2026-07-25T23:30:00Z
project: ferrochain
cycle: v1.0.0-greenfield
input-hash: "[live-index]"
traces_to: .factory/specs/prd.md
changelog:
  - "3.14 (burst-266/F-P164-01/2026-07-25): F-P164-01 HIGH: BC-2.14.001 v1.2→v1.3 — Component enum updated 16→17 (+TOOLS, ferrochain-tools SS-23); counter '16 components as of D21' → '17 components as of D23'; ADR-010 v1.6 D23 authority. TD-VSDD-060 sole-site confirmed: rg '16 components|sixteen components' .factory/specs/ — sole occurrence was BC-2.14.001 line 49; no other live-body references require amendment."
  - "3.13 (burst-264/2026-07-25): BC-2.12.004 v1.5→v1.6 — Architecture Anchors filesystem path corrected src/scheduler/ → src/cron/ per module-decomposition v1.26 adjudication (canonical module server::cron); pre-emptive micro-fix applied before adversary pass P1D-163."
  - "3.12 (burst-262/F-P161-03/2026-07-25): F-P161-03 LOW: Carry-Forward Notes #6 and #7 annotated '(later promoted to Wave 1 per D23)' per D23 promotion — Notes #6/#7 previously stated 'assigned wave 2' for ferrochain-memory SS-15 and SS-16 respectively, without acknowledging subsequent D23 Wave-1 promotion; now reads 'assigned wave 2, later promoted to Wave 1 per D23' following the parenthetical-annotation convention of Note #5."
  - "3.11 (burst-261/F-P160-01/F-P160-02/2026-07-25): F-P160-01 MED: BC-2.03.001 v1.6→v1.7 — Description corrected from 'exceeds config.recursion_limit' to the precise ceiling formula (stop = step_at_invoke_start + config.recursion_limit + 1; limit=5 → 6 steps execute, limit=25 → 26 steps execute); TD-VSDD-060 sibling sweep — BC-2.08.002 v1.4→v1.5 (VP-BC208002-01 description had implied ≤25 steps; corrected to 'within recursion_limit + 1 super-steps per invocation segment'; normative authority is BC-2.03.001 PC5); 7 sites audited (BC-2.01.003, BC-2.03.002/003, BC-2.04.006, interface-definitions/BC-2.03.001/error-taxonomy) all correct. F-P160-02 LOW: BC-2.04.006 v1.5→v1.6 — reciprocal NE-12 Related-BC link added (BC-2.15.002 cites this BC but no reciprocal existed; bidirectional advisory-link default convention)."
  - "3.10 (burst-260/F-P159-01/OBS-P159-A/2026-07-25): F-P159-01 HIGH: BC-2.15.001 v1.2→v1.3, BC-2.15.002 v1.2→v1.3, BC-2.15.003 v1.3→v1.4 — SS-15 trio body Traceability tables carried stale P2/Wave-2 post-D23 promotion; all 6 cells fixed to P1/Wave-1. OBS-P159-A adjudication: VP-MEM-01/02 (BC-2.15.001), VP-MEM-03/04 (BC-2.15.002), VP-MEM-05/06 (BC-2.15.003) all phases Post-v1→v1 — tenant isolation is v1 security-critical behavior; Wave-1 promotion applies; BC-2.15.004/005/006 reverse-contamination check clean."
  - "3.9 (burst-259/F-P158-01/02/2026-07-24): F-P158-01 MED: BC-2.16.003 v1.3→v1.4 — tool_name dropped from retry.circuit_breaker_disabled emission in EC-005; CircuitBreaker::always_closed() is a zero-argument constructor; tool-agnostic message template per sibling retry.unlimited_policy_constructed; observability v1.2→v1.3. F-P158-02 LOW: BC-2.12.004 v1.4→v1.5 — cron queue-full boundary adjudicated >= (ScheduleQueueFull fires when queue length meets or exceeds capacity; at-capacity semantics); error-taxonomy v1.39→v1.40; observability trigger-condition aligned."
  - "3.8 (burst-258/F-P157-02/2026-07-24): F-P157-02 MED: BC-INDEX frontmatter timestamp corrected 2026-07-25→2026-07-24 (future-dated). BC version sync from F-P157-01 observability catalog re-sweep (observability.md v1.1→v1.2; catalog 6→11 event_types): BC-2.08.008 v1.2 (eval.judge_infra_error), BC-2.12.004 v1.4 (server.cron_schedule_queue_full), BC-2.16.002 v1.4 (retry.unlimited_policy_constructed), BC-2.16.003 v1.3 (retry.circuit_breaker_disabled+retry.circuit_probe_failed)."
  - "3.7 (burst-257/F-P156-01/02/2026-07-24): F-P156-01 HIGH: 12 BC files (SS-11 ×6, SS-13 ×6) — nonexistent arch-file citations (ferrochain-core/graph/memory/sandbox.md, cargo-features.md, verification-properties.md) replaced with adjudicated real targets (interface-definitions §GuardrailHook, module-decomposition §rows, purity-boundary-map §rows, verification-architecture VP-003); corpus-complete audit zero other nonexistent citations; anchor-resolution validator minted (PASS=129 FAIL=0). BC versions: BC-2.11.001 v1.2, BC-2.11.002 v1.10, BC-2.11.003 v1.8, BC-2.11.004 v1.8, BC-2.11.005 v1.4, BC-2.11.006 v1.3, BC-2.13.001 v1.1, BC-2.13.002 v1.3, BC-2.13.003 v1.1, BC-2.13.004 v1.3, BC-2.13.005 v1.2, BC-2.13.006 v1.2. F-P156-02 MED: BC-INDEX body-table sync gap closed (3.6 row was absent; 3.6 + 3.7 rows added)."
  - "3.6 (burst-256/F-P155-01/02/2026-07-24): Form-A changelog direction sweep ×41 BC files: 25 pure-descending reversed (BC-2.05.001, BC-2.05.007, BC-2.05.008, BC-2.06.001, BC-2.06.005, BC-2.06.006, BC-2.08.007, BC-2.08.010, BC-2.09.002, BC-2.09.003, BC-2.10.005, BC-2.10.006, BC-2.13.002, BC-2.14.001, BC-2.14.004, BC-2.16.003, BC-2.18.001, BC-2.18.005, BC-2.19.001, BC-2.19.002, BC-2.23.001, BC-2.23.002, BC-2.23.003, BC-2.23.004, BC-2.23.005); 11 non-monotonic sorted ascending (BC-2.10.004, BC-2.15.006, BC-2.16.002, BC-2.18.002, BC-2.18.003, BC-2.18.004, BC-2.19.005, BC-2.20.003, BC-2.21.003, BC-2.22.001, BC-2.23.006); BC-2.16.001 sorted ascending + v1.4→v1.5 (frontmatter version aligned to newest changelog entry per gate #28 Rule 6); 4 duplicate-1.1-entry merged with '; also:' separator (BC-2.04.001, BC-2.11.002, BC-2.11.003, BC-2.11.004); BC-2.07.003 YAML parse fix (invalid backslash+backtick escape at col 364 removed). F-P155-03: verify-form-a-changelog-direction.sh validator minted (post-fix: PASS=121 WARN=8 FAIL=0). F-P155-04: all 13 VP files §BC Traceability Title cells synced verbatim to canonical BC H1s."
  - "3.5 (burst-255/F-P154-02/2026-07-24): BC-2.17.001 v1.3→v1.4 — VP-011 bullet realigned to actual proven scope per Option-A dispatch-design adjudication (F-P154-01 architect): route_pre_tool_decision covers 3 routable variants (Approve/Deny/Edit) + hook-error with #[non_exhaustive] wildcard arm → fail-closed Reject; PendingHumanApproval peeled off upstream in async pre_tool_dispatch wrapper per BC-2.05.007 PC-4; DispatchOutcome stays 2-variant; PendingHumanApproval non-invocation covered by BC-2.05.008 integration tests. In-scope compliance fix: BC-2.17.001 changelog reordered desc→asc per gate #28 Rule 6 (drifted since burst-241). gate #35 extended to include BC-2.17.001 VP-bullet edits + VP-NNN internal consistency check (bc-authoring-plan v2.48→v2.49)."
  - "3.4 (burst-254/F-P153-01/2026-07-24): BC-2.17.001 v1.2→v1.3 — VP-012 bullet: strict strict-< predicate closed (non-strict <= + f64 arithmetic + domain 0<=tokens_remaining<=ceiling; load-bearing note: EC-002 fraction=1.0 boundary must fire); VP-011 bullet modernized from Deny-only to full 4-variant PreToolDecision fail-closed coverage (Approve/Deny/Edit/PendingHumanApproval per VP-011.md v1.2). No f32 residue in remaining VP bullets; full BC staleness scan CLEAN."
  - "3.3 (burst-253/F-P152-03/2026-07-24): BC-2.07.002 v1.5→v1.6 — GTV-010 (NFD combining sequence discriminator: 'abcéxyz' 8 code pts/7 graphemes, chunk_size=4; correct ['abce','́xyz'] vs wrong grapheme ['abcé','xyz']) + GTV-011 (ZWJ family emoji discriminator: '👨‍👩‍👧‍👦 hi' 10 code pts/4 graphemes; correct 3 chunks splitting ZWJ sequence vs wrong 2 chunks) added; 9→11 GTVs Python-verified against pinned in-tree langchain-text-splitters==1.1.2; test-vectors v2.6→v2.7 (671→674 TVs = 663 canonical + 11 GTV)."
  - "3.2 (burst-252/F-P151-01..07/2026-07-24): BC version sync fix-burst-252 ADR-019 compaction type canon: BC-2.10.005 v1.2 (CompactionTrigger count/tokens fields, f64 fraction, non-strict <= predicate; ADR-019 Decision authority), BC-2.10.006 v1.6 (CompactionSummary flat compacted_start/end fields, mandatory parent_ids, put mechanism), BC-2.06.006 v1.4 (compaction_event flat wire payload per ADR-019 Decision 4), BC-2.06.001 v1.9 (compaction_event 15th event variant in StreamEvent taxonomy; OnWatermark f64 fraction/budget_tokens_used), BC-2.05.001 v1.4 (generalized suspend invariant covering all 3 suspend classes: interrupt/Budget Escalation/HITL), BC-2.10.004 v1.8 (Budget Escalation compaction write via get_next_version+put). Hash-currency cascade sweep: 3-pass TOTAL=234 MATCH=234 STALE=0 (specs/174 planning/3 cycles/18 + index exemptions)."
  - "3.1 (burst-250/F-P149-01..03+OBS-01/2026-07-24): CORPUS-WIDE TD-VSDD-091 de-pin sweep — 19 live-body 'ADR-NNN vN.N' version pins replaced with stable Decision/section anchors per D18-P84-A; zero live-body ADR version pins remain corpus-wide (changelogs exempt). BC scope: BC-2.20.002 v1.4 (F-P149-02 de-pin), BC-2.18.003 v1.2 (F-P149-02 de-pin), BC-2.23.006 v1.5 (F-P149-02 de-pin), BC-2.21.003 v1.4 (OBS-P149-01 PC5 attribution fix — [-1,1] range property is BC-local proptest sub-property VP-2.21.003-B, not VP-009 proptest harness). F-P149-01 HIGH: verification-architecture §VP-009 (1 site) + capabilities-p1-p2 §CAP-029 (2 sites) de-pinned 'ADR-014 v1.x Hardening' → 'ADR-014 Decision 2 §Hardening note'. F-P149-03 LOW: coverage-matrix v2.2 red_gate labels normalized on all 5 red_gate:true VP rows; verification-architecture v2.5 VP-006 heading labeled."
  - "3.0 (burst-249/F-P148-01..05/2026-07-24): (1) MUST Red Gate: BC-2.21.003 Risk Source de-pinned 'ADR-014 v1.1 Hardening Note' → 'ADR-014 Decision 2 §Hardening note' (F-P148-03); (2) MUST VP Seed: VP-009 Security Anchor de-pinned same; (3) Enhanced Red Gate canonical form: BC-2.18.004 → 'ADR-015 Decision 3 §Security Invariant 1', BC-2.18.005 → 'ADR-015 Decision 2 §Security Invariant 2', BC-2.19.005 → 'ADR-016 Decision 3 §Security Invariant' (F-P148-02 ADR labeled anchors); (4) Enhanced VP Seed: VP-006 → 'ADR-015 Decision 3 §Security Invariant 1', VP-010 → 'ADR-016 Decision 3 §Security Invariant'; (5) BC version sync (F-P148-01..05 closures): BC-2.18.004 v1.4, BC-2.18.005 v1.1, BC-2.19.005 v1.3, BC-2.21.003 v1.3, BC-2.07.002 v1.5. OBS-04: GTV-003/008 Python-verified against pinned corpus (corrected — both provisional values were wrong); all 9 GTVs now verified (test-vectors v2.6). OBS-05: BC-2.07.002 splitter pin reconciled to in-tree langchain-text-splitters==1.1.2."
  - "2.9 (burst-247/F-P146-02/2026-07-24): SS-23 title policy applied — 6 Full BC Catalog row titles synced to H1s per bc_h1_is_title_source_of_truth: BC-2.23.001 v1.3 E-TOOLS-001/E-TOOLS-002→E-TOOLS-001/002/008; BC-2.23.002 v1.2 E-TOOLS-001→E-TOOLS-001/008; BC-2.23.003 v1.3 +E-TOOLS-001/003/008 suffix appended; BC-2.23.004 v1.2 E-TOOLS-001;→E-TOOLS-001/008;; BC-2.23.005 v1.5 E-TOOLS-004/005/007→E-TOOLS-004/007 (E-TOOLS-005 Ok-path payload flag excluded from title); BC-2.23.006 v1.4 E-TOOLS-001/006→E-TOOLS-001/008/009 (E-TOOLS-006 Ok-path payload flag excluded from title)."
  - "2.8 (F-P142-03, burst-242, 2026-07-23): BC-2.05.008 and BC-2.06.005 titles updated to match new H1s (bc_h1_is_title_source_of_truth): Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form per BC-2.05.004 authority."
  - "2.7 (burst-241/Wave-2/F-P141-02/2026-07-23): BC-2.17.001 title updated to match new H1 (bc_h1_is_title_source_of_truth): 'Kani Harness Scope — BSP Determinism VP + Session Tenancy VP + Workspace Confinement VP' → 'Six P0 Kani VP Obligations + Three P1 Kani VP Obligations'. DI column +DI-014."
  - "2.6 (burst-239/F-P139/2026-07-22): BC-2.06.001 title updated to match current H1 (H1 is source of truth per bc_h1_is_title_source_of_truth policy — drift from D23 v1.5 update not swept to index). No BC count changes. BCs modified this burst: BC-2.04.001 v1.4 (+Inv-5 append-only), BC-2.10.006 v1.4 (citation fix), BC-2.06.001 v1.6 (PC2 type + Description), BC-2.07.003 v1.3 (PC5), BC-2.07.001 v1.3 (TV-005), BC-2.05.008 v1.1 (Related BCs + EC-006)."
  - "2.5 (burst-238/sweep/2026-07-23): Update VP-INDEX status note — 'VP-006–VP-010 pending architect authoring' was stale; VP-INDEX v1.2 (burst-223) registered VP-006–010 and VP-006.md–VP-010.md all exist. Note updated to reflect completed state."
---

# BC-INDEX: ferrochain Behavioral Contracts

> **129 BCs total — 51 P0 / 75 P1 / 3 P2 | 11 Red Gate | 11 VP Seed | 13 VPs registered**
>
> Subsystem IDs: SS-01 through SS-17 assigned by architect at Phase 1 Step D (2026-07-14).
> SS-18 through SS-22 added D21 ecosystem-parity expansion (2026-07-20).
> SS-23 (First-Party Tools) added D23 first-class approval hook + compaction expansion (2026-07-22).
> All BCs reside under `specs/behavioral-contracts/ss-NN/` per ARCH-INDEX Subsystem Registry.
> VP-INDEX: 13 VPs registered (VP-001–VP-003 Kani P0, VP-004–VP-005 integration P1,
> VP-006–VP-010 assigned VP-INDEX v1.2 (burst-223, 2026-07-21) and authored — VP-006.md–VP-010.md all complete;
> VP-011–VP-013 seeds assigned D23 burst-232 and authored — VP-011.md–VP-013.md all complete).

## Summary

| Metric | Count |
|--------|-------|
| Total BCs | 129 |
| Priority P0 | 51 |
| Priority P1 | 75 |
| Priority P2 | 3 |
| Red Gate BCs | 11 |
| VP Seed BCs | 11 |
| Subsection groups | 23 (SS-2.01 – SS-2.23) |

## Red Gate BCs

| BC ID | Title | Risk Source |
|-------|-------|-------------|
| BC-2.02.003 | NamedBarrierValue Missing-Writer Boundary Behavior | R10 (upstream coverage gap) |
| BC-2.02.004 | EphemeralValue Cleared-After-Super-Step Semantics | R10 (upstream coverage gap) |
| BC-2.07.002 | Non-ASCII Boundary Parity with Python Reference Implementation | R8 (splitter code-point parity) |
| BC-2.09.004 | MCP Bare ToolException Re-Raise Preserving Type Identity | R11 (MCP upstream test void) |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections | R11 (MCP upstream test void) |
| BC-2.18.004 | injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed at Render Time) | ADR-015 Decision 3 §Security Invariant 1 |
| BC-2.18.005 | SlotTrustPolicy::TrustAll on SystemMessage Slot Raises E-TMPL-002 at Construction Time (Fail-Closed) | ADR-015 Decision 2 §Security Invariant 2 |
| BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed, VP-010 Kani Candidate) | ADR-016 Decision 3 §Security Invariant |
| BC-2.20.002 | BoundaryType::RAGRetrieval Guardrail Covers All Retriever::get_relevant_documents Returns Entering Graph Context | ADR-014 Consequences §DI-012 |
| BC-2.21.003 | Zero-Norm Vector Guard — Vec\<f32\> Cosine Denominator Check Returns E-VS-001 Before Division (VP-009 Kani Candidate) | ADR-014 Decision 2 §Hardening note |
| BC-2.22.002 | EmbeddingsOpenAI — OpenAiApiKey Redacted-Debug Credential Opacity (DI-010); Batch Partial-Failure as Err | DI-010 Credential Opacity |

## VP Seed BCs

| VP ID | BC ID | Title | Proof Method | NE / Security Anchor |
|-------|-------|-------|-------------|----------------------|
| VP-001 | BC-2.03.001 | BSP Super-Step Execution Determinism | Kani | NE-17 |
| VP-002 | BC-2.04.006 | Session Triple-Address Uniqueness | Kani | NE-12 |
| VP-003 | BC-2.13.004 | All Workspace File Ops Call canonicalize_beneath_root | Kani | NE-02 |
| VP-006 | BC-2.18.004 | injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 | Kani (candidate) | ADR-015 Decision 3 §Security Invariant 1 |
| VP-007 | BC-2.19.001 | LcSerializable Round-Trip — Serialize to Serialized::Constructor, Deserialize to Semantically Equivalent Value | Proptest | CAP-024 round-trip invariant |
| VP-008 | BC-2.22.001 | Embeddings Trait — Dimensionality Contract → E-EMBED-001; Batch Partial-Failure as Err | Proptest | CAP-031 dimensionality invariant |
| VP-009 | BC-2.21.003 | Zero-Norm Vector Guard — Vec\<f32\> Cosine Denominator Check Returns E-VS-001 Before Division | Kani (candidate) | ADR-014 Decision 2 §Hardening note |
| VP-010 | BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed) | Kani (candidate) | ADR-016 Decision 3 §Security Invariant |
| VP-011 | BC-2.05.007 | PreToolCallHook Dispatch — pre_invoke Contract; Approve/Deny/Edit/PendingHumanApproval; Fail-Closed Deny | Kani (candidate) | ADR-018 Decision 1 |
| VP-012 | BC-2.10.005 | CompactionTrigger Configuration — Disabled/OnWatermark/OnMessageCount/OnTokenCount; Watermark Arithmetic | Kani (candidate) | ADR-019 Decision 3 |
| VP-013 | BC-2.23.005 | BashTool — Non-Lowerable Medium Risk Floor; Sandboxed Shell Execution | Kani (candidate) | ADR-020 Decision 3 |

_VP-004 and VP-005 are integration VPs (from BC-2.09.004/005); registered in VP-INDEX but not formal verification seeds. VP-006/007/008/009/010 seeds assigned burst-222 (2026-07-21); VP-011/012/013 seeds assigned burst-231 (2026-07-22); architect to author VP body files in Phase 6._

## Full BC Catalog

| BC ID | Title | Cap | NE Anchors | DI Anchors | Pri | RG | VP | File |
|-------|-------|-----|-----------|-----------|-----|----|----|------|
| BC-2.01.001 | Typed ContentBlock Sequence Construction (No Raw Content Where Typed Expected) | CAP-001 | | DI-008 | P0 | | | ss-01/BC-2.01.001.md |
| BC-2.01.002 | Message Type-Safety (AiMessage / HumanMessage / SystemMessage / ToolMessage) | CAP-001 | | DI-008 | P0 | | | ss-01/BC-2.01.002.md |
| BC-2.01.003 | Runnable Trait Invocation — invoke, stream, batch | CAP-002 | | | P0 | | | ss-01/BC-2.01.003.md |
| BC-2.01.004 | Runnable Pipe Composition (A.pipe(B) = AB Chain) | CAP-002 | | | P0 | | | ss-01/BC-2.01.004.md |
| BC-2.02.001 | StateGraph Node Definition with Typed Channel Assignment | CAP-003 | | | P0 | | | ss-02/BC-2.02.001.md |
| BC-2.02.002 | LastValue / Append / BarrierValue Channel Semantics and Reducer Wiring | CAP-003 | | DI-001 | P0 | | | ss-02/BC-2.02.002.md |
| BC-2.02.003 | NamedBarrierValue Missing-Writer Boundary Behavior (Red Gate — R10) | CAP-003 | | | P0 | **RG** | | ss-02/BC-2.02.003.md |
| BC-2.02.004 | EphemeralValue Cleared-After-Super-Step Semantics (Red Gate — R10) | CAP-003 | | | P0 | **RG** | | ss-02/BC-2.02.004.md |
| BC-2.02.005 | Conditional Edge Routing Function | CAP-003 | | | P0 | | | ss-02/BC-2.02.005.md |
| BC-2.02.006 | Send API Dynamic Fan-Out | CAP-003 | | | P0 | | | ss-02/BC-2.02.006.md |
| BC-2.03.001 | BSP Super-Step Execution Determinism — Kani VP Seed (NE-17) | CAP-004 | NE-17 | DI-001 | P0 | | **VP** | ss-03/BC-2.03.001.md |
| BC-2.03.002 | Concurrent LastValue Write Rejection Raises InvalidUpdateError | CAP-004 | | DI-001 | P0 | | | ss-03/BC-2.03.002.md |
| BC-2.03.003 | Deterministic Reducer Application Order (Task-Identity Sort) | CAP-004 | NE-17 | DI-001 | P0 | | | ss-03/BC-2.03.003.md |
| BC-2.04.001 | Per-Task put_writes Completes Before Next Super-Step Begins | CAP-005 | | DI-002 | P0 | | | ss-04/BC-2.04.001.md |
| BC-2.04.002 | Sync Durability Tier Is Default; Async and Exit Are Explicit Opt-In | CAP-005 | | DI-002 | P0 | | | ss-04/BC-2.04.002.md |
| BC-2.04.003 | Monotonic Logical-Clock Checkpoint IDs — Wall-Clock UUIDs Rejected | CAP-005 | | DI-004 | P0 | | | ss-04/BC-2.04.003.md |
| BC-2.04.004 | Fork Lineage via parent_checkpoint_id Pointers; No State Copy on Fork | CAP-005 | | DI-004 | P0 | | | ss-04/BC-2.04.004.md |
| BC-2.04.005 | Crash Recovery — Completed Tasks Not Re-Executed After Process Restart | CAP-005 | | DI-002 | P0 | | | ss-04/BC-2.04.005.md |
| BC-2.04.006 | Session Triple-Address Uniqueness (thread_id, checkpoint_ns, checkpoint_id) — Kani VP Seed | CAP-005 | NE-12 | DI-005 | P0 | | **VP** | ss-04/BC-2.04.006.md |
| BC-2.04.007 | Encryption at Rest Covers Both State AND Event Payloads; Rotation Errors Propagate | CAP-005 | NE-11 | | P0 | | | ss-04/BC-2.04.007.md |
| BC-2.04.008 | FTS Conversation Search Over Checkpoint History (Single-Process; SQLite FTS5) | CAP-005 | | DI-002,DI-008,DI-014 | P1 | | | ss-04/BC-2.04.008.md |
| BC-2.05.001 | Interrupt Suspension with Durable State Persistence | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.001.md |
| BC-2.05.002 | FIFO Resume-Value Delivery Order | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.002.md |
| BC-2.05.003 | Interrupted Node Re-Executes from Start of Super-Step on Resume | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.003.md |
| BC-2.05.004 | Command(resume=value) API Contract for Programmatic Resume | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.004.md |
| BC-2.05.005 | Resume on Empty Interrupt Queue Returns Err(NoActiveInterrupt) | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.005.md |
| BC-2.05.006 | Risk-Tiered Interrupt Classification (Typed Action-Risk Levels for Domain A SOC) | CAP-006 | | DI-003 | P0 | | | ss-05/BC-2.05.006.md |
| BC-2.05.007 | PreToolCallHook Dispatch — pre_invoke Contract; Approve/Deny/Edit/PendingHumanApproval; Fail-Closed Deny (VP-011 Kani Seed) | CAP-034 | | DI-014 | P1 | | **VP** | ss-05/BC-2.05.007.md |
| BC-2.05.008 | Skip-Hook-on-Resume Invariant — ToolApprovalRequest Checkpoint Persistence; Command(resume=PreToolDecision); No Re-Invocation of pre_invoke | CAP-034 | | DI-014 | P1 | | | ss-05/BC-2.05.008.md |
| BC-2.06.001 | Typed Per-Phase Event Taxonomy (run/step/node/tool start-stream-end; guardrail_decision; tool_approval_request/resolved; compaction_event) — 15 Variants | CAP-007 | | DI-011 | P0 | | | ss-06/BC-2.06.001.md |
| BC-2.06.002 | run_id + parent_ids Correlation Across All Streaming Events | CAP-007 | | | P0 | | | ss-06/BC-2.06.002.md |
| BC-2.06.003 | Streaming and Unary Run Produce Identical Final Answer (NE-13) | CAP-007 | NE-13 | DI-011 | P0 | | | ss-06/BC-2.06.003.md |
| BC-2.06.004 | `tool_approval_request` StreamEvent (Event 13) — Payload; Emission Timing; Causal Ordering Before Interrupt | CAP-034 | | DI-014 | P1 | | | ss-06/BC-2.06.004.md |
| BC-2.06.005 | `tool_approval_resolved` StreamEvent (Event 14) — Payload; Emission on Command(resume=…); Decision Outcome | CAP-034 | | DI-014 | P1 | | | ss-06/BC-2.06.005.md |
| BC-2.06.006 | `compaction_event` StreamEvent (Event 15) — Payload; Emission After Compaction Completes; Trigger Variant | CAP-035 | | DI-014 | P1 | | | ss-06/BC-2.06.006.md |
| BC-2.07.001 | Chunk Boundaries Are Unicode Code-Point Counts (Not Bytes) | CAP-008 | | | P0 | | | ss-07/BC-2.07.001.md |
| BC-2.07.002 | Non-ASCII Boundary Parity with Python Reference Implementation (Emoji, CJK) — R8 Red Gate | CAP-008 | | | P0 | **RG** | | ss-07/BC-2.07.002.md |
| BC-2.07.003 | Short Document (length < chunk_size) — Single Chunk, No Overlap, No Panic | CAP-008 | | | P0 | | | ss-07/BC-2.07.003.md |
| BC-2.08.001 | Chat Model Streaming Completions Conformance | CAP-009 | | DI-011 | P1 | | | ss-08/BC-2.08.001.md |
| BC-2.08.002 | Chat Model Tool-Call Round-Trip Conformance | CAP-009 | | | P1 | | | ss-08/BC-2.08.002.md |
| BC-2.08.003 | Chat Model Structured Output Conformance | CAP-009 | | | P1 | | | ss-08/BC-2.08.003.md |
| BC-2.08.004 | Chat Model Error-Type Fidelity Conformance | CAP-009 | | DI-014 | P1 | | | ss-08/BC-2.08.004.md |
| BC-2.08.005 | Chat Model Token-Usage Accounting Conformance | CAP-009 | | | P1 | | | ss-08/BC-2.08.005.md |
| BC-2.08.006 | Standalone SDK Crate Split Architecture (ferrochain-\<provider\>-sdk + Adapter) | CAP-009 | | DI-008 | P1 | | | ss-08/BC-2.08.006.md |
| BC-2.08.007 | Provider Streaming Interrupted by Transport Error Surfaces Err(Timeout) or Err(Transport), Not Truncated Success | CAP-009 | | DI-009,DI-014 | P1 | | | ss-08/BC-2.08.007.md |
| BC-2.08.008 | Eval Score Aggregation: Arithmetic Mean + JudgeResult::InfraError Third Outcome (NE-15) | CAP-011 | NE-15 | | P1 | | | ss-08/BC-2.08.008.md |
| BC-2.08.009 | Tool Schema Naming Stability (Snapshot Test Anchor) | CAP-009 | | | P1 | | | ss-08/BC-2.08.009.md |
| BC-2.08.010 | `#[tool]` Attribute Macro — async fn to Tool Implementor via schemars::JsonSchema | CAP-002 | | DI-008 | P1 | | | ss-08/BC-2.08.010.md |
| BC-2.08.011 | `#[entrypoint]` Attribute Macro — START Edge Auto-Wiring for StateGraph | CAP-003 | | | P1 | | | ss-08/BC-2.08.011.md |
| BC-2.08.012 | `#[task]` Attribute Macro — Task Registration Boilerplate Generation | CAP-003 | | | P1 | | | ss-08/BC-2.08.012.md |
| BC-2.08.013 | Pluggable Tool-Call Dialect Seam (ToolCallDialect; Hermes ChatML XML) | CAP-009 | | DI-008,DI-014 | P1 | | | ss-08/BC-2.08.013.md |
| BC-2.08.014 | Provider Failover Chain (ProviderFallbackPolicy; Ordered Fallback on 429/5xx/Auth) | CAP-009 | | DI-008,DI-009,DI-010,DI-014 | P1 | | | ss-08/BC-2.08.014.md |
| BC-2.09.001 | MCP Server Tool Discovery and Registration at Runtime | CAP-010 | | | P1 | | | ss-09/BC-2.09.001.md |
| BC-2.09.002 | ToolInvocation Routing to Correct MCP Server Transport | CAP-010 | | | P1 | | | ss-09/BC-2.09.002.md |
| BC-2.09.003 | Tool-Result Content Treated as Untrusted Ingress (DI-012 Applies) | CAP-010 | | DI-012 | P1 | | | ss-09/BC-2.09.003.md |
| BC-2.09.004 | MCP Bare ToolException Re-Raise Preserving Type Identity (Red Gate — R11) | CAP-010 | | DI-014 | P1 | **RG** | | ss-09/BC-2.09.004.md |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections (Red Gate — R11) | CAP-010 | | DI-014 | P1 | **RG** | | ss-09/BC-2.09.005.md |
| BC-2.09.006 | MCP Server Tool Advertisement (tools/list; mcp::server) | CAP-021 | | DI-008,DI-014 | P1 | | | ss-09/BC-2.09.006.md |
| BC-2.09.007 | MCP Server Tool Invocation (tools/call; External Client Executes Registered Tool) | CAP-021 | | DI-008,DI-010,DI-014 | P1 | | | ss-09/BC-2.09.007.md |
| BC-2.10.001 | BudgetPolicy allow/escalate/deny Evaluation per Run and per Sub-Agent | CAP-012 | | | P0 | | | ss-10/BC-2.10.001.md |
| BC-2.10.002 | Append-Only EvidenceJournal Records Every Budget Evaluation | CAP-012 | | | P0 | | | ss-10/BC-2.10.002.md |
| BC-2.10.003 | Graceful Halt When Budget Ceiling Reached (on_ceiling = halt \| summarize); Remaining-Budget Exposure | CAP-012 | | | P0 | | | ss-10/BC-2.10.003.md |
| BC-2.10.004 | Budget Escalation to HITL Interrupt (Soft-Limit Escalate Path and Hard-Ceiling on_ceiling=Escalate Path) | CAP-012 | | DI-003 | P0 | | | ss-10/BC-2.10.004.md |
| BC-2.10.005 | CompactionTrigger Configuration — Disabled/OnWatermark/OnMessageCount/OnTokenCount; BudgetConfig Extension; Watermark Arithmetic (VP-012 Kani Seed) | CAP-035 | | DI-014 | P1 | | **VP** | ss-10/BC-2.10.005.md |
| BC-2.10.006 | Compaction Execution — ConversationSnapshot from FTS; Mid-Run Window REPLACEMENT; CompactionEvent → EvidenceJournal; Checkpoint Immutability; DefaultSummarizationPolicy | CAP-035 | | DI-014 | P1 | | | ss-10/BC-2.10.006.md |
| BC-2.11.001 | ProvenanceTag Attached at Every Ingress Boundary (Tool-Result, RAG, Memory) | CAP-013 | | DI-012 | P0 | | | ss-11/BC-2.11.001.md |
| BC-2.11.002 | GuardrailHook Fires Unconditionally at Tool-Result Ingress | CAP-013 | NE-06 | DI-012 | P0 | | | ss-11/BC-2.11.002.md |
| BC-2.11.003 | GuardrailHook Fires at RAG Ingress | CAP-013 | NE-06 | DI-012 | P0 | | | ss-11/BC-2.11.003.md |
| BC-2.11.004 | GuardrailHook Fires at Memory Ingress | CAP-013 | NE-06 | DI-012 | P0 | | | ss-11/BC-2.11.004.md |
| BC-2.11.005 | Rejected Content Does Not Enter Model Context Under Any Code Path | CAP-013 | | DI-012 | P0 | | | ss-11/BC-2.11.005.md |
| BC-2.11.006 | No-Hook Default — Content Passes Through with WARNING LOG (Default-Permit) | CAP-013 | | DI-012 | P0 | | | ss-11/BC-2.11.006.md |
| BC-2.12.001 | Thread Resource CRUD (Create, Read, List, Delete Durable Conversation History) | CAP-014 | | | P1 | | | ss-12/BC-2.12.001.md |
| BC-2.12.002 | Assistant Resource CRUD (Named Agent Config with Graph Reference) | CAP-014 | | | P1 | | | ss-12/BC-2.12.002.md |
| BC-2.12.003 | Run Creation and Execution Lifecycle (queued → in_progress → completed/failed/cancelled/summary_halt; interrupted is pausable/resumable) | CAP-014 | | | P1 | | | ss-12/BC-2.12.003.md |
| BC-2.12.004 | CronSchedule Creation and Proactive Run Execution | CAP-014 | | | P1 | | | ss-12/BC-2.12.004.md |
| BC-2.12.005 | SecurityConfig::default() Denies CORS; Debug Route Gated on Explicit Opt-In Key (NE-14) | CAP-014 | NE-14 | DI-013 | P1 | | | ss-12/BC-2.12.005.md |
| BC-2.12.006 | IdempotencyStore / RateLimitStore / RunStore Trait Seams with Durable Backends (NE-08) | CAP-014 | NE-08 | | P1 | | | ss-12/BC-2.12.006.md |
| BC-2.12.007 | Streaming Endpoint and Unary Endpoint Drive Same Graph Engine, Same Final Answer | CAP-014 | NE-13 | DI-011 | P1 | | | ss-12/BC-2.12.007.md |
| BC-2.13.001 | Enforcing Sandbox Backend (WASM or Container) Is Default (NE-01) | CAP-015 | NE-01 | DI-006 | P1 | | | ss-13/BC-2.13.001.md |
| BC-2.13.002 | Process Backend Requires Explicit Opt-In and Emits Loud Runtime Warning | CAP-015 | | DI-006,DI-015 | P1 | | | ss-13/BC-2.13.002.md |
| BC-2.13.003 | Strict Policy + Non-Enforcing Backend Returns Err(PolicyNotEnforceable) | CAP-015 | | DI-006 | P1 | | | ss-13/BC-2.13.003.md |
| BC-2.13.004 | All Workspace File Ops Call canonicalize_beneath_root at Access Time (NE-02) — Kani VP Seed | CAP-015 | NE-02 | DI-007 | P1 | | **VP** | ss-13/BC-2.13.004.md |
| BC-2.13.005 | Symlink That Escapes Workspace Root Returns Err(WorkspaceEscape) | CAP-015 | NE-02 | DI-007 | P1 | | | ss-13/BC-2.13.005.md |
| BC-2.13.006 | macOS Seatbelt Profile: Deny-by-Default with Explicit Allow Rules (NE-16) | CAP-015 | NE-16 | DI-006 | P1 | | | ss-13/BC-2.13.006.md |
| BC-2.13.007 | Environment Variable Sanitization at Sandbox Execution Boundary | CAP-015 | | DI-006,DI-008,DI-010 | P1 | | | ss-13/BC-2.13.007.md |
| BC-2.14.001 | FerrochainError 2D Component × Category Struct with RetryHint and Machine Code | CAP-016 | | DI-008,DI-014 | P0 | | | ss-14/BC-2.14.001.md |
| BC-2.14.002 | RFC-7807 Compatible Problem Emission from FerrochainError | CAP-016 | | | P0 | | | ss-14/BC-2.14.002.md |
| BC-2.14.003 | All Library Constructors Return Result; No .unwrap()/.expect()/assert! in Non-Test Code | CAP-016 | NE-07 | DI-008 | P0 | | | ss-14/BC-2.14.003.md |
| BC-2.14.004 | Every Outbound HTTP ClientBuilder Must Set .timeout(30s); Zero Client::new() Outside Tests | CAP-016 | NE-04 | DI-009 | P0 | | | ss-14/BC-2.14.004.md |
| BC-2.14.005 | API Key Newtype with Redacted Debug; No Serialize; No Deref\<Target=str\> | CAP-016 | NE-10 | DI-010 | P0 | | | ss-14/BC-2.14.005.md |
| BC-2.14.006 | Validation Failures Propagate Err(FerrochainError); No Silent None | CAP-016 | NE-03 | DI-014 | P0 | | | ss-14/BC-2.14.006.md |
| BC-2.15.001 | KV and Vector Memory Persistence Across Threads (Not Per-Checkpoint) | CAP-017 | | | P1 | | | ss-15/BC-2.15.001.md |
| BC-2.15.002 | User/App/Session Tier Isolation — User-Private Does Not Bleed Across Scopes | CAP-017 | | | P1 | | | ss-15/BC-2.15.002.md |
| BC-2.15.003 | GDPR Erasure Removes All Traces from All Memory Tiers | CAP-017 | | | P1 | | | ss-15/BC-2.15.003.md |
| BC-2.15.004 | SkillStore Registry — Load-on-Demand Skill Documents | CAP-020 | | DI-008,DI-014 | P1 | | | ss-15/BC-2.15.004.md |
| BC-2.15.005 | Guarded Memory and Skill Writes (MemoryWriteGuard; E-MEMORY-007) | CAP-020 | | DI-008,DI-012,DI-014 | P1 | | | ss-15/BC-2.15.005.md |
| BC-2.15.006 | Frozen-Snapshot Context Mutation — Memory-Sourced System-Prompt Content | CAP-020 | | DI-002,DI-008,DI-014 | P1 | | | ss-15/BC-2.15.006.md |
| BC-2.16.001 | Per-Tool Retry Policy Keyed by tool_name (Not Args Hash) | CAP-018 | NE-09 | | P1 | | | ss-16/BC-2.16.001.md |
| BC-2.16.002 | Finite global_limit Non-None Default for All Retry Policies | CAP-018 | NE-09 | | P1 | | | ss-16/BC-2.16.002.md |
| BC-2.16.003 | Circuit Breaker Trips After Repeated Failure; Prevents Infinite Retry | CAP-018 | NE-09 | | P1 | | | ss-16/BC-2.16.003.md |
| BC-2.17.001 | Six P0 Kani VP Obligations + Three P1 Kani VP Obligations | CAP-019 | | DI-001,DI-005,DI-007,DI-014 | P2 | | | ss-17/BC-2.17.001.md |
| BC-2.17.002 | cargo-fuzz Targets — Serialization Round-Trip (Checkpoint) and Graph-Execution Paths | CAP-019 | | | P2 | | | ss-17/BC-2.17.002.md |
| BC-2.18.001 | PromptTemplate F-String Rendering, Partial Binding, Variable Detection, and Strict-Undefined Guard | CAP-022 | | DI-008,DI-014 | P1 | | | ss-18/BC-2.18.001.md |
| BC-2.18.002 | ChatPromptTemplate Multi-Message Rendering with PromptValue and Per-Message MessageProvenance | CAP-022 | | DI-008 | P1 | | | ss-18/BC-2.18.002.md |
| BC-2.18.003 | MessagesPlaceholder Vec\<Message\> In-Place Expansion and FewShotPromptTemplate Few-Shot Composition | CAP-023 | | DI-008 | P1 | | | ss-18/BC-2.18.003.md |
| BC-2.18.004 | injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed at Render Time) | CAP-022 | | DI-008,DI-014 | P1 | **RG** | **VP-006** | ss-18/BC-2.18.004.md |
| BC-2.18.005 | SlotTrustPolicy::TrustAll on SystemMessage Slot Raises E-TMPL-002 at Construction Time (Fail-Closed) | CAP-022 | | DI-008,DI-014 | P1 | **RG** | | ss-18/BC-2.18.005.md |
| BC-2.19.001 | LcSerializable Round-Trip — Serialize to Serialized::Constructor, Deserialize to Semantically Equivalent Value | CAP-024 | | DI-008 | P1 | | **VP-007** | ss-19/BC-2.19.001.md |
| BC-2.19.002 | lc_secrets() Credential Fields Stripped from kwargs Before Serialization and Constructor Dispatch | CAP-024 | | DI-008,DI-010 | P1 | | | ss-19/BC-2.19.002.md |
| BC-2.19.003 | Inventory-Based Type Registry — Link-Time Registration, Feature-Gated Partner Entries, OnceLock Allowlist | CAP-025 | | DI-008 | P1 | | | ss-19/BC-2.19.003.md |
| BC-2.19.004 | Legacy Namespace Remap — OLD_CORE_NAMESPACES_MAPPING Aliases Resolve to Canonical Constructors | CAP-025 | | DI-008 | P2 | | | ss-19/BC-2.19.004.md |
| BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed, VP-010 Kani Candidate) | CAP-025 | | DI-008,DI-014 | P0 | **RG** | **VP-010** | ss-19/BC-2.19.005.md |
| BC-2.19.006 | Langchain-Monolith Type Ids Return E-SRLZ-002 (Structured Error, Not Silent None or E-SRLZ-001) | CAP-025 | | DI-008,DI-014 | P1 | | | ss-19/BC-2.19.006.md |
| BC-2.20.001 | Retriever Trait — get_relevant_documents Async Dyn-Compatible; Document Carrier Type; Arc\<dyn Retriever\> Graph Seam | CAP-026 | | DI-008,DI-012,DI-014 | P1 | | | ss-20/BC-2.20.001.md |
| BC-2.20.002 | BoundaryType::RAGRetrieval Guardrail Covers All Retriever::get_relevant_documents Returns Entering Graph Context (DI-012 Coverage Obligation) | CAP-026 | | DI-012,DI-014 | P0 | **RG** | | ss-20/BC-2.20.002.md |
| BC-2.20.003 | VectorStoreRetriever — SearchType Enum (Similarity \| SimilarityScoreThreshold \| Mmr); k / fetch_k / lambda_mult Configuration; Constructed via as_retriever() | CAP-027 | | DI-008 | P1 | | | ss-20/BC-2.20.003.md |
| BC-2.21.001 | VectorStore Trait — Instance-Method Surface; VectorStoreFactory Sized-Bounded Separation; Arc\<dyn VectorStore\> Dyn-Safety | CAP-028 | | DI-008 | P1 | | | ss-21/BC-2.21.001.md |
| BC-2.21.002 | InMemoryVectorStore — Arc\<dyn Embeddings\> DI; RwLock Interior Mutability; Vec\<f32\> Cosine; VectorStoreFactory Constructor | CAP-029 | | DI-008 | P1 | | | ss-21/BC-2.21.002.md |
| BC-2.21.003 | Zero-Norm Vector Guard — Vec\<f32\> Cosine Denominator Check Returns E-VS-001 Before Division (VP-009 Kani Candidate) | CAP-029 | | DI-008,DI-014 | P0 | **RG** | **VP-009** | ss-21/BC-2.21.003.md |
| BC-2.21.004 | MetadataFilter — Eq / Ne / In FilterClause; Additive similarity_search_with_filter; Native Pre-Filter vs InMemoryVectorStore Post-Filter; #[non_exhaustive] | CAP-030 | | DI-008,DI-014 | P1 | | | ss-21/BC-2.21.004.md |
| BC-2.22.001 | Embeddings Trait — embed_documents Batch; embed_query; Dimensionality Contract → E-EMBED-001; Batch Partial-Failure as Err; Arc\<dyn Embeddings\> Dyn-Safe (VP-008 Proptest Seed) | CAP-031 | | DI-008,DI-014 | P1 | | **VP-008** | ss-22/BC-2.22.001.md |
| BC-2.22.002 | EmbeddingsOpenAI — text-embedding-3-small/large/ada-002-legacy; OpenAiApiKey Redacted-Debug Credential Opacity (DI-010); reqwest/rustls-tls/.timeout(30s); Batch Partial-Failure as Err | CAP-032 | | DI-008,DI-009,DI-010,DI-014 | P1 | **RG** | | ss-22/BC-2.22.002.md |
| BC-2.22.003 | EmbeddingsOllama — No API Key; POST /api/embed Preferred; use_legacy_endpoint Toggle for /api/embeddings; reqwest/rustls-tls/.timeout(30s) Unconditional | CAP-033 | | DI-008,DI-009,DI-014 | P1 | | | ss-22/BC-2.22.003.md |
| BC-2.23.001 | ReadFileTool — PathGuard-Confined File Read; max_bytes 1 MiB Limit; E-TOOLS-001/002/008 | CAP-036 | | DI-014 | P1 | | | ss-23/BC-2.23.001.md |
| BC-2.23.002 | WriteFileTool — PathGuard-Confined Atomic Write; High ActionRisk; No Auto-Retry; E-TOOLS-001/008 | CAP-036 | | DI-014 | P1 | | | ss-23/BC-2.23.002.md |
| BC-2.23.003 | EditFileTool — Exact-Match String Replace; E-TOOLS-003 on No-Match; Opt-In Fuzzy Fallback (EditConfig::fuzzy_threshold); Conditional Retry Safe; E-TOOLS-001/003/008 | CAP-036 | | DI-014 | P1 | | | ss-23/BC-2.23.003.md |
| BC-2.23.004 | ListDirTool — PathGuard-Confined Directory Listing; ReadOnly; E-TOOLS-001/008; DirEntry Struct | CAP-036 | | DI-014 | P1 | | | ss-23/BC-2.23.004.md |
| BC-2.23.005 | BashTool — Sandboxed Shell Execution; Non-Lowerable Medium Risk Floor; BashOutput; 256 KiB Output Cap; 30 s Timeout; E-TOOLS-004/007 (VP-013 Kani Seed) | CAP-037 | | DI-014,DI-015 | P1 | | **VP** | ss-23/BC-2.23.005.md |
| BC-2.23.006 | GrepTool — In-Process Regex Search; Linear-Time `regex` Crate; max_results 100 Cap; Hermetic; PathGuard Scope; E-TOOLS-001/008/009 | CAP-038 | | DI-014 | P1 | | | ss-23/BC-2.23.006.md |

## Carry-Forward Notes (RESOLVED at Phase 1 Step D, 2026-07-14)

1. **SS-TBD backfill** — RESOLVED. All 95 BCs now have `subsystem: SS-NN`. BC files moved to `ss-NN/` dirs per artifact-path-registry. ARCH-INDEX Subsystem Registry is authoritative.
2. **VP-INDEX registration** — RESOLVED. VP-001..VP-003 (Kani) + VP-004..VP-005 (integration, from BC-2.09.004/005) registered in VP-INDEX.md.
3. **vp_seed frontmatter inconsistency** — RESOLVED. BC-2.03.001: `vp_seed: true, vp_id: VP-001`. BC-2.04.006: normalized `kani_vp_seed` → `vp_seed: true, vp_id: VP-002`. BC-2.13.004: `vp_seed: true, vp_id: VP-003`.
4. **red_gate_required vs red_gate** — RESOLVED. BC-2.07.002: `red_gate_required: true` → `red_gate: true, red_gate_source: R8`.
5. **Proc-macro BCs (Phase-1b)** — ADDED. BC-2.08.010/011/012 authored from ADR-004 + ADR-008 acceptance (D5 gate resolved). Batch 13 in bc-authoring-plan.md. Total: 83 → 86 BCs; P1 count: 27 → 30 (later grown to 95 via D20).
6. **SS-15 wave drift (ADV-P1D-PASS-3 F-P3-06)** — RESOLVED. BC-2.15.001/002/003 frontmatter `wave: post-v1` → `wave: 2`; Traceability rows updated to `Wave 2`. Aligns with ARCH-INDEX §Canonical Crate Roster (ferrochain-memory assigned wave 2, later promoted to Wave 1 per D23).
7. **SS-16 wave drift (ADV-P1D-PASS-4 F-P4-03)** — RESOLVED. BC-2.16.001/002/003 frontmatter `wave: Post-v1` → `wave: 2`; Traceability rows updated to `Wave 2`. Stale Note rows (E-RETRY-001/002/003 "requires addition to error-taxonomy") removed — all three codes were already in RETRY component. Aligns with ARCH-INDEX §Canonical Crate Roster (SS-16 assigned wave 2, later promoted to Wave 1 per D23).

## Changelog

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 3.14 | 2026-07-25 | burst-266/F-P164-01: BC-2.14.001 v1.2→v1.3 — Component enum updated 16→17 (+TOOLS, ferrochain-tools SS-23; "16 components as of D21" → "17 components as of D23"). ADR-010 v1.6 D23 authority. TD-VSDD-060 sole-site confirmed. | burst-266 F-P164-01 |
| 3.13 | 2026-07-25 | burst-264: BC-2.12.004 v1.5→v1.6 — Architecture Anchors filesystem path corrected src/scheduler/ → src/cron/ per module-decomposition v1.26 adjudication (canonical module server::cron); pre-emptive micro-fix before adversary pass P1D-163. | burst-264 |
| 3.12 | 2026-07-25 | burst-262/F-P161-03: Carry-Forward Notes #6 and #7 annotated "(later promoted to Wave 1 per D23)" — Notes previously stated wave-2 assignment for SS-15/SS-16 without acknowledging D23 Wave-1 promotion; parenthetical clarifiers added following Note #5 convention. | burst-262 F-P161-03 |
| 3.11 | 2026-07-25 | burst-261/F-P160-01/02: F-P160-01 MED — BC-2.03.001 v1.6→v1.7 (Description corrected from 'exceeds config.recursion_limit' to precise ceiling formula: stop = step_at_invoke_start + config.recursion_limit + 1; limit=25 → 26 steps execute before halt); TD-VSDD-060 sibling sweep — BC-2.08.002 v1.4→v1.5 (VP-BC208002-01 description corrected from implied ≤25 to 'within recursion_limit + 1 super-steps per invocation segment'; normative authority BC-2.03.001 PC5); 7 recursion-arithmetic corpus sites audited CLEAN. F-P160-02 LOW — BC-2.04.006 v1.5→v1.6 (reciprocal NE-12 Related-BC link to BC-2.15.002 added; bidirectional advisory-link default convention). | burst-261 F-P160-01/02 |
| 3.10 | 2026-07-25 | burst-260/F-P159-01/OBS-P159-A: F-P159-01 HIGH — BC-2.15.001 v1.2→v1.3, BC-2.15.002 v1.2→v1.3, BC-2.15.003 v1.3→v1.4 (SS-15 trio body Traceability P2/Wave-2→P1/Wave-1; residue from incomplete D23 body sweep). OBS-P159-A: all 6 VP-MEM phases Post-v1→v1 (tenant isolation v1 security-critical; Wave-1 promotion); BC-2.15.004/005/006 reverse-contamination check clean. | burst-260 F-P159-01+OBS-P159-A |
| 3.9 | 2026-07-24 | burst-259/F-P158-01/02: F-P158-01 MED: BC-2.16.003 v1.3→v1.4 — tool_name dropped from retry.circuit_breaker_disabled emission in EC-005; zero-argument constructor; tool-agnostic message template per sibling retry.unlimited_policy_constructed; observability v1.2→v1.3. F-P158-02 LOW: BC-2.12.004 v1.4→v1.5 — cron queue-full boundary adjudicated >= (ScheduleQueueFull fires when queue meets or exceeds capacity; at-capacity semantics); error-taxonomy v1.39→v1.40; observability trigger-condition aligned. | burst-259 F-P158-01/02 |
| 3.8 | 2026-07-24 | burst-258/F-P157-02: BC-INDEX frontmatter timestamp corrected 2026-07-25→2026-07-24 (future-dated per F-P157-02 MED). BC version sync from F-P157-01 observability catalog re-sweep (observability.md v1.1→v1.2; catalog 6→11 event_types): BC-2.08.008 v1.2 (eval.judge_infra_error), BC-2.12.004 v1.4 (server.cron_schedule_queue_full), BC-2.16.002 v1.4 (retry.unlimited_policy_constructed), BC-2.16.003 v1.3 (retry.circuit_breaker_disabled + retry.circuit_probe_failed). | burst-258 F-P157-02 |
| 3.7 | 2026-07-24 | burst-257/F-P156-01/02: F-P156-01 HIGH — 12 BC files (SS-11 ×6, SS-13 ×6) anchor sweep: nonexistent arch-file citations replaced with adjudicated real targets; BC versions: BC-2.11.001 v1.2, BC-2.11.002 v1.10, BC-2.11.003 v1.8, BC-2.11.004 v1.8, BC-2.11.005 v1.4, BC-2.11.006 v1.3, BC-2.13.001 v1.1, BC-2.13.002 v1.3, BC-2.13.003 v1.1, BC-2.13.004 v1.3, BC-2.13.005 v1.2, BC-2.13.006 v1.2; anchor-resolution validator minted (PASS=129 FAIL=0). F-P156-02 MED: body-table sync gap closed (3.6 row was absent; 3.6 + 3.7 rows added). | burst-257 F-P156-01/02 |
| 3.6 | 2026-07-24 | burst-256/F-P155-01/02: Form-A changelog direction sweep ×41 BC files: 25 pure-descending reversed, 11 non-monotonic sorted ascending, BC-2.16.001 sorted ascending + v1.4→v1.5, 4 duplicate-1.1-entry merged; BC-2.07.003 YAML parse fix. F-P155-03: verify-form-a-changelog-direction.sh validator minted (post-fix: PASS=121 WARN=8 FAIL=0). F-P155-04: all 13 VP files §BC Traceability Title cells synced verbatim to canonical BC H1s. | burst-256 F-P155-01..04 |
| 3.5 | 2026-07-24 | burst-255/F-P154-02: BC-2.17.001 v1.3→v1.4 — VP-011 bullet realigned to actual proven scope per Option-A peel-off adjudication (route_pre_tool_decision covers 3 routable variants + hook-error fail-closed Reject per #[non_exhaustive] wildcard arm; PendingHumanApproval peeled off upstream in pre_tool_dispatch per BC-2.05.007 PC-4; DispatchOutcome stays 2-variant; BC-2.05.008 integration tests cover non-invocation). In-scope fix: BC-2.17.001 changelog reordered desc→asc per gate #28 Rule 6. gate #35 extended (bc-authoring-plan v2.49). | burst-255 F-P154-02 |
| 3.4 | 2026-07-24 | burst-254/F-P153-01: BC-2.17.001 v1.2→v1.3 — VP-012 bullet corrected: strict `<` → non-strict `<=` predicate; f64 arithmetic; domain 0<=tokens_remaining<=ceiling; load-bearing non-strict note (EC-002 fraction=1.0, tokens_remaining=0 boundary must fire). VP-011 bullet modernized: Deny-only → full 4-variant PreToolDecision fail-closed coverage (Approve/Deny/Edit/PendingHumanApproval per VP-011.md v1.2). Full BC staleness scan: no f32 residue in remaining VP bullets. | burst-254 F-P153-01 |
| 3.3 | 2026-07-24 | burst-253/F-P152-03: BC-2.07.002 v1.5→v1.6 — GTV-010 (NFD combining discriminator: 'abcéxyz' 8 code pts/7 graphemes, chunk_size=4) + GTV-011 (ZWJ family emoji discriminator: '👨‍👩‍👧‍👦 hi' 10 code pts/4 graphemes) added; 9→11 GTVs Python-verified against pinned in-tree langchain-text-splitters==1.1.2; test-vectors v2.6→v2.7 (671→674 TVs = 663 canonical + 11 GTV). | burst-253 F-P152-03 |
| 3.2 | 2026-07-24 | burst-252/F-P151-01..07: BC version sync — ADR-019 compaction type canon: BC-2.10.005 v1.2 (CompactionTrigger count/tokens fields, f64 fraction, non-strict <= predicate), BC-2.10.006 v1.6 (CompactionSummary flat compacted_start/end, mandatory parent_ids, put mechanism), BC-2.06.006 v1.4 (compaction_event flat wire payload per ADR-019), BC-2.06.001 v1.9 (compaction_event 15th variant; OnWatermark f64 fraction/budget_tokens_used), BC-2.05.001 v1.4 (generalized suspend invariant — all 3 suspend classes), BC-2.10.004 v1.8 (Budget Escalation write get_next_version+put). | burst-252 F-P151-01..07 |
| 3.1 | 2026-07-24 | burst-250/F-P149-01..03+OBS-01: CORPUS-WIDE TD-VSDD-091 de-pin sweep — 19 live-body 'ADR-NNN vN.N' version pins replaced with stable Decision/section anchors per D18-P84-A; zero live-body ADR version pins remain corpus-wide. BC scope: BC-2.20.002 v1.4 (de-pin), BC-2.18.003 v1.2 (de-pin), BC-2.23.006 v1.5 (de-pin), BC-2.21.003 v1.4 (OBS-P149-01 PC5 attribution — [-1,1] range is BC-local VP-2.21.003-B proptest sub-property, not VP-009 proptest harness). F-P149-01 HIGH: verification-architecture §VP-009 + capabilities-p1-p2 §CAP-029 (2 sites) de-pinned. F-P149-03 LOW: coverage-matrix v2.2 red_gate labels normalized; VP-006 heading labeled. | burst-250 F-P149-01..03+OBS-01 |
| 3.0 | 2026-07-24 | burst-249/F-P148-01..05: (1) MUST Red Gate de-pin: BC-2.21.003 'ADR-014 v1.1 Hardening Note'→'ADR-014 Decision 2 §Hardening note' (F-P148-03); (2) MUST VP Seed: VP-009 Security Anchor same de-pin; (3) Enhanced Red Gate canonical cite form per F-P148-02 ADR labeled anchors: BC-2.18.004→ADR-015 Decision 3 §Security Invariant 1, BC-2.18.005→ADR-015 Decision 2 §Security Invariant 2, BC-2.19.005→ADR-016 Decision 3 §Security Invariant; (4) Enhanced VP Seed: VP-006→ADR-015 Decision 3 §Security Invariant 1, VP-010→ADR-016 Decision 3 §Security Invariant; (5) BC versions noted: BC-2.18.004 v1.4, BC-2.18.005 v1.1, BC-2.19.005 v1.3, BC-2.21.003 v1.3, BC-2.07.002 v1.5; (6) F-P148-01 HIGH E-SRLZ-001 category VAL (BC-2.19.005 v1.3; VP-010 v1.3 PC1/Inv-3); (7) OBS-04 GTV-003/008 Python-verified against pinned corpus (test-vectors v2.6, 671 TVs, 9 GTVs verified); OBS-05 splitter pin reconciled to in-tree ==1.1.2 (BC-2.07.002 v1.5). | burst-249 F-P148-01..05 |
| 2.9 | 2026-07-24 | burst-247/F-P146-02: SS-23 title policy — 6 Full BC Catalog row titles synced to H1s per bc_h1_is_title_source_of_truth: BC-2.23.001 v1.3 E-TOOLS-001/002/008; BC-2.23.002 v1.2 E-TOOLS-001/008; BC-2.23.003 v1.3 +E-TOOLS-001/003/008; BC-2.23.004 v1.2 E-TOOLS-001/008;; BC-2.23.005 v1.5 E-TOOLS-004/007 (E-TOOLS-005 payload flag excluded); BC-2.23.006 v1.4 E-TOOLS-001/008/009 (E-TOOLS-006 payload flag excluded). | burst-247 F-P146-02 |
| 2.8 | 2026-07-23 | F-P142-03, burst-242: BC-2.05.008 and BC-2.06.005 titles updated to match new H1s (bc_h1_is_title_source_of_truth): Command::Resume(…) enum-variant form → Command(resume=…) struct kwarg form per BC-2.05.004 authority. | F-P142-03 burst-242 |
| 2.7 | 2026-07-23 | burst-241/Wave-2/F-P141-02: BC-2.17.001 title updated to match new H1 (bc_h1_is_title_source_of_truth): 'Kani Harness Scope — BSP Determinism VP + Session Tenancy VP + Workspace Confinement VP' → 'Six P0 Kani VP Obligations + Three P1 Kani VP Obligations'. DI column +DI-014. | burst-241/F-P141-02 |
| 2.6 | 2026-07-22 | burst-239/F-P139: BC-2.06.001 title corrected to match H1 (H1 authority — title was stale from pre-D23 era). BCs updated this burst: BC-2.04.001 v1.4 (+Inv-5 append-only invariant, F-P139-01a), BC-2.10.006 v1.4 (citation fix to BC-2.04.001 Inv-5, F-P139-01b), BC-2.06.001 v1.6 (PC2 tokens_remaining_after u64→Option<i64> F-P139-02; Description Step-no-Stream F-P139-04), BC-2.07.003 v1.3 (PC5 mandate [] F-P139-03), BC-2.07.001 v1.3 (TV-005 [] F-P139-03), BC-2.05.008 v1.1 (Related BCs PC-4 scope + EC-006 F-P139-07). | burst-239 F-P139 |
| 2.5 | 2026-07-23 | burst-238/sweep/2026-07-23: Update VP-INDEX status note — 'VP-006–VP-010 pending architect authoring' was stale; VP-INDEX v1.2 (burst-223) registered VP-006–010 and VP-006.md–VP-010.md all exist. Note updated to reflect completed state. | burst-238 |
| 2.4 | 2026-07-22 | burst-237/F-P137-01: BC-2.13.002 DI column DI-006 → DI-006,DI-015. Propagates burst-235 F-P135-05 di_anchors addition (co-enforcer of DI-015 Subprocess Execution Timeout; kill_on_drop PC-6+INV-6) to the index row — BC file frontmatter was correct since burst-235 but index was not swept. DI-anchor reconcile sweep: no other drift found (BC-2.20.003 and BC-2.18.004/005 apparent discrepancies confirmed as awk false-positives from \\| in title). | burst-237 F-P137-01 |
| 2.3 | 2026-07-22 | burst-235/F-P135-03: BC-2.23.005 DI column DI-009,DI-014 → DI-014,DI-015. Propagates burst-234 F-P134-06 re-anchor (DI-009→DI-015 adjudication) to the index row — BC file frontmatter was correct since burst-234 but index was not swept. | burst-235 F-P135-03 |
| 2.2 | 2026-07-22 | burst-233/F-P133-02: BC-2.16.001/002/003 Wave-1 promotion per D23 — priority P2→P1, wave 2→1; header 72 P1/6 P2 → 75 P1/3 P2; Full Catalog P2→P1 for all three rows. VP-013 Security Anchor corrected: ADR-018 Decision 6 → ADR-020 Decision 3 (BashTool non-lowerable Medium risk floor is ADR-020 Decision 3, not ADR-018). | burst-233 F-P133-02 |
| 2.1 | 2026-07-22 | D23 INTEGRATE burst-231: header 116→129 BCs; P1 56→72, P2 9→6 (BC-2.15.001/002/003 promoted P2→P1); VP Seed 8→11 (+VP-011→BC-2.05.007, VP-012→BC-2.10.005, VP-013→BC-2.23.005); VP-INDEX 10→13; subsection groups 22→23 (+SS-23 First-Party Tools); Full Catalog +13 rows (BC-2.05.007/008, BC-2.06.004/005/006, BC-2.10.005/006, BC-2.23.001–006). | D23 burst-231 |
| 2.0 | 2026-07-21 | Burst-226 (F-P131-01/02/03/05/06/07): (1) F-P131-05 TrustLevel migration: BC-2.18.004 v1.1→1.2 (title updated to canonical TrustLevel form; EC/TV/INV migrated from ProvenanceTag to TrustLevel). BC-2.18.002 v1.0→1.1 (INV-2/PC3 TrustLevel). BC-2.09.003 v1.1→1.2 (PC1 ProvenanceTag struct form; PC4 canonical guardrail.unregistered_passthrough). BC-2.11.006 v1.1→1.2 (PC2 canonical event_type). (2) F-P131-01: BC-2.20.002 v1.2→1.3 (PC2 severity-bifurcated Fail; E-CORE-008). (3) F-P131-07: BC-2.21.004 v1.1→1.2 (INV-3 fail-safe E-VS-005). (4) F-P131-02+03: BC-2.13.002 v1.0→1.1 (event_type sandbox.process_no_isolation_execute). BC-2.12.006 v1.2→1.3 (event_type server.rate_limit_store_in_memory). BC-2.15.003 v1.1→1.2 (event_type memory.gdpr_unattributed_session_entries). BC-2.12.005 v1.4→1.5 (event_type server.security_config_cors_wildcard). BC-2.18.004 H1 title already updated in v1.9→2.0 scope. | burst-226 F-P131 |
| 1.9 | 2026-07-21 | F-P130 fix burst 225: DI column updates — (1) BC-2.20.001: DI-008,DI-012 → DI-008,DI-012,DI-014 (F-P130-04). (2) BC-2.20.002: DI-012 → DI-012,DI-014 (F-P130-02/04). (3) BC-2.21.004: DI-008 → DI-008,DI-014 (F-P130-04). (4) BC-2.22.002: DI-008,DI-010,DI-014 → DI-008,DI-009,DI-010,DI-014 (F-P130-09). (5) BC-2.22.003: DI-008,DI-014 → DI-008,DI-009,DI-014 (F-P130-09). | F-P130 burst-225 |
| 1.8 | 2026-07-21 | D21 spec-body layer complete (burst 222): header 95→116 BCs; P0 48→51, P1 39→56, P2 8→9; Red Gate 5→11 (+BC-2.18.004/005, BC-2.19.005, BC-2.20.002, BC-2.21.003, BC-2.22.002); VP Seed 3→8 (+VP-006→BC-2.18.004, VP-007→BC-2.19.001, VP-008→BC-2.22.001, VP-009→BC-2.21.003, VP-010→BC-2.19.005); VP-INDEX 5→10; subsection groups 17→22; Full Catalog +21 rows (SS-18..22); VP Seed table restructured with VP ID column. BC-2.19.001 v1.0→v1.1 (VP-007 seed assigned). | D21 burst-222 |
| 1.7 | 2026-07-20 | D21 ecosystem-parity expansion: 21 BC files authored (SS-18..22); frontmatter/changelog updated in prd.md + BC-INDEX.md. Body incomplete (this entry). | D21 burst-216 |
| 1.6 | 2026-07-19 | F-P114-01 fix burst 117: Architecture Anchor fields corrected in BC-2.04.001–007 (7 files) — replaced nonexistent `architecture/ferrochain-checkpoint.md` citation with adjudicated real targets per architect guidance. Per-file versions: BC-2.04.001 v1.3, BC-2.04.002 v1.4, BC-2.04.003 v1.4, BC-2.04.004 v1.3, BC-2.04.005 v1.3, BC-2.04.006 v1.5, BC-2.04.007 v1.7. No BC body content changed. | F-P114-01 fix burst 117 |
| 1.5 | 2026-07-17 | F-P94-01: BC-2.10.003 index row trailing italic `_(v1.2: adds OnCeiling::Summarize + RunContext.budget_info / BudgetInfo)_` removed — title now byte-exact match to H1 in ss-10/BC-2.10.003.md. | F-P94-01 |
| 1.4 | 2026-07-15 | OBS-P74-B: Carry-Forward Note #5 appended "(later grown to 95 via D20)" for parallelism with prd OQR-4 clarifier convention. | OBS-P74-B |
| 1.3 | 2026-07-15 | F-P73-02: Carry-Forward Note #1 updated "All 86 BCs" → "All 95 BCs" (9 D20 BCs verified to carry `subsystem: SS-NN` frontmatter); version and timestamp bumped. | F-P73-02 |
| 1.2 | 2026-07-15 | D20 INTEGRATE sub-burst 2: 9 D20 BCs registered (86→95 total); header, Summary table, and section tables updated. | D20 sub-burst 2 |
| 1.1 | 2026-07-14 | Phase 1 Step D SS-NN backfill: all BCs moved to `ss-NN/` subdirectories; subsystem IDs assigned from ARCH-INDEX; carry-forward notes updated. | Phase 1 Step D |
| 1.0 | 2026-07-13 | Initial authoring. | Greenfield Phase 1a |
