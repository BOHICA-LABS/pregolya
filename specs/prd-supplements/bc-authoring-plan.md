---
document_type: prd-supplement-bc-authoring-plan
level: L3
version: "2.70"
status: active
producer: product-owner
total_standing_gates: 37
timestamp: 2026-08-27T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/L2-INDEX.md
input-hash: "117c7a3"
traces_to: prd.md
total_bcs: 134
total_batches: 20
p0_count: 51
p1_count: 80
p2_count: 3
changelog:
  - "2.70 (round-20/F-P2A092-01/2026-08-27): GAP-01/D-275 sync miss corrected. Frontmatter: total_bcs 133→134, p1_count 79→80. Summary table: Total BCs 133→134, P1 (should-have) 79→80. Batch 14 header count 8→9 BCs; BC-2.09.008 row added after BC-2.09.007 (Title: StateGraph-as-MCP-Tool Wrapping (GraphAgentTool; mcp::graph_tool); P1; CAP-021; DI-008, DI-010, DI-014; Wave 2). DI coverage table: BC-2.09.008 appended to DI-008, DI-010, and DI-014 enforcer lists per BC-2.09.008 Traceability §L2 Domain Invariants. Canonical census is 134 = 51 P0 / 80 P1 / 3 P2 (matches BC-INDEX/STORY-INDEX/prd.md/STATE.md)."
  - "2.69 (P2A-052 F-052-01/2026-08-25): Convention note added to §Authoring Guidelines for Sub-Burst Agents — §VP Anchors section must contain VP identifiers only (VP-NNN or BC-local VP-<suffix>) or the literal 'None'; must never contain a story ID (story coverage belongs in §Story Anchor). Six BCs corrected: BC-2.09.001, BC-2.09.002, BC-2.09.003 (S-2.10 → None) and BC-2.12.001, BC-2.12.002, BC-2.12.003 (S-1.26 → None). Each BC bumped to next version."
  - "2.68 (P2A-049/F-049-01-sibling-sweep/2026-08-25): BC-2.18.002 and BC-2.18.004 title cells in Batch 16 table synced to canonical H1s (POL-7 downstream drift; FIX-BURST-256 H1 form superseded). BC-2.18.002: 'ChatPromptTemplate Multi-Message Rendering with PromptValue and Per-Message MessageProvenance' → 'ChatPromptTemplate Multi-Message Rendering, PromptValue Enum (String/Messages Variants, Send+Sync), and Runnable<HashMap<String,TemplateInput>,PromptValue>'. BC-2.18.004: 'injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed)' → 'injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed at Render Time)' (missing 'at Render Time' suffix). BC-2.18.005 title cell verified correct — no change."
  - "2.67 (burst-307/P1D-199/F-P199-01/2026-08-17): DI-016 enforcer mis-anchoring corrected — 006↔007 swap introduced by v2.66. DI coverage table DI-016 row: BC-2.01.005, BC-2.01.007, BC-2.01.008 → BC-2.01.005, BC-2.01.006, BC-2.01.008. Batch-1 table BC-2.01.006 row: DI-014 → DI-014, DI-016. Batch-1 table BC-2.01.007 row: DI-014, DI-016 → DI-014. v2.66 changelog DI-016 enforcer text corrected in-place (same-cycle factual correction). DI-014 enforcer list verified: all four (BC-2.01.005/006/007/008) retained — DI-014 anchored by all four per di_anchors frontmatter. DI-016 enforcer set now {BC-2.01.005, BC-2.01.006, BC-2.01.008} consistent with invariants.md and BC frontmatter source of truth (POL-46). input-hash updated to 87d8d75."
  - "2.66 (burst-306/F-P198-02/2026-08-17): LCEL composition scope expansion propagated — burst-302b index-layer sync miss. Frontmatter: total_bcs 129→133, p1_count 75→79. Summary table: Total BCs 129→133, P1 75→79, Subsystems covered CAP-001–CAP-038 → CAP-001–CAP-039. SS.01 subsystem map: CAP-001, CAP-002 → CAP-001, CAP-002, CAP-039; priority P0 → P0/P1. Batch 1 count 8→12; four rows added: BC-2.01.005 (RunnableParallel Construction and Concurrent Invocation, CAP-039, DI-014/DI-016, Wave 1), BC-2.01.006 (RunnableParallel Branch Failure — Fail-Fast, CAP-039, DI-014/DI-016, Wave 1), BC-2.01.007 (RunnablePassthrough Identity Pass-Through, CAP-039, DI-014, Wave 1), BC-2.01.008 (RunnableAssign Dict Augmentation, CAP-039, DI-014/DI-016, Wave 1). DI coverage: DI-014 enforcer list extended with BC-2.01.005/006/007/008; DI-016 row added (enforcers: BC-2.01.005, BC-2.01.006, BC-2.01.008); coverage 15/15→16/16. Note: DI-008 enforcer list correctly omits BC-2.01.005–008 (they anchor DI-016/DI-014, not DI-008, per di_anchors frontmatter). input-hash updated to e4da046. [v2.66 DI text corrected in-place by v2.67]"
  - "2.65 (burst-291/D-134-cont/2026-08-16): Two phantom §-anchor citations corrected in live body text. (1) Line ~758 gate #31 text: 'ADV-P1D-PASS-24.md §WIRE-OBJECT class' → 'ADV-P1D-PASS-24.md §NEW CLASS: Wire-Object Field-Set Coherence' (real heading at line 126 of ADV-P1D-PASS-24.md; §WIRE-OBJECT matches no heading). Gate regex parses §NEW CLASS (stops at colon) → prefix-matches '## NEW CLASS: Wire-Object Field-Set Coherence' uniquely — PASS. (2) Line ~2591 batch-20 text: 'interface-definitions.md §IngressContent' → 'interface-definitions.md §GuardrailHook' (IngressContent enum is defined inline within §GuardrailHook; §IngressContent matches no heading in interface-definitions.md). TD-VSDD-060 sweep: sole §WIRE-OBJECT and sole §IngressContent occurrences in live body text."
  - "2.64 (burst-291/D-134/2026-08-16): §-anchor phantom sweep. (1) §Authoring Guidelines for Sub-Burst Agents (guideline #17-C) (4 sites): no heading §17-C exists in this file; guideline #17-C is a numbered list item within §Authoring Guidelines for Sub-Burst Agents. Corrected to §Authoring Guidelines for Sub-Burst Agents (guideline #17-C). (2) §Coverage by Criticality Tier bare self-reference (2 sites at lines 1114/1122 context): no such heading in this file; target heading lives in verification-coverage-matrix.md (architecture/); added explicit file prefix verification-coverage-matrix.md §Coverage by Criticality Tier. (3) §CRITICAL Module Security Profile (1 site): no such heading in module-criticality.md; CRITICAL security profiles are in §Per-Module Risk Assessment. Corrected to module-criticality.md §Per-Module Risk Assessment. Cross-owner: verification-coverage-matrix.md §Coverage by Criticality Tier heading validity left to architect agent."
  - "2.63 (burst-288/F-P177-D01/2026-08-15): Full §Subsystem → CAP Mapping sweep (D-134 structural remedy). All 23 rows cross-checked against ARCH-INDEX §Subsystem Registry (authoritative source). Five divergent rows corrected: SS.06 pregolya-graph → pregolya-graph, pregolya-core (ARCH-INDEX SS-06 primary crates include both); SS.11 pregolya-core/graph → pregolya-graph (ARCH-INDEX SS-11 primary crate is pregolya-graph); SS.13 pregolya-graph/sandbox → pregolya-sandbox (ARCH-INDEX SS-13 primary crate is pregolya-sandbox; pregolya-graph owns zero SS-13 modules); SS.17 all (formal verification) → xtask, pregolya-graph, pregolya-checkpoint, pregolya-sandbox (ARCH-INDEX SS-17 primary crates enumerated); SS.20 pregolya-vectorstores → pregolya-core, pregolya-vectorstores (ARCH-INDEX SS-20 primary crates include both). D-135 note: these are crate-assignment routing errors; pregolya-community IS a valid roster crate (post-v1 row 8); no phantom-crate errors. Eighteen rows verified matching ARCH-INDEX: SS.01, SS.02, SS.03, SS.04, SS.05, SS.07, SS.08, SS.09, SS.10, SS.12, SS.14, SS.15, SS.16, SS.18, SS.19, SS.21, SS.22, SS.23."
  - "2.62 (fix-burst-287/F-P176-D002+D004/2026-08-01): TWO FINDINGS VERIFIED. (1) F-P176-D002 CONFIRMED: §Subsystem → CAP Mapping SS-22 crate corrected from `pregolya-community` (post-v1, absent from 21-crate v1 roster per ARCH-INDEX §Canonical Crate Roster row 8 status=post-v1) to `pregolya-core, pregolya-openai, pregolya-ollama`. Four concurring artifacts: ARCH-INDEX §Subsystem Registry SS-22 row (`pregolya-core, pregolya-openai, pregolya-ollama`); module-decomposition §Provider Embeddings Modules (SS-22) (`core::embeddings` in pregolya-core; `openai::embeddings` in pregolya-openai; `ollama::embeddings` in pregolya-ollama); BC-2.22.001 frontmatter `crate: pregolya-core`; BC-2.22.002 frontmatter `crate: pregolya-openai`; BC-2.22.003 frontmatter `crate: pregolya-ollama`. bc-authoring-plan.md was the lone outlier. (2) F-P176-D004 note-half FALSE: adversary finding claimed a §Note in bc-authoring-plan.md asserts gate #37 was wired to pre-commit-validators.sh. String-presence check (`grep 'wired to pre-commit' bc-authoring-plan.md`) returned empty — no such note exists. Gate #37 (LAYER-SCOPED SWEEP BAN) is a process gate with no machine hook; its text at §37 accurately describes a manual standing gate and makes no wired-validator claim. No text change to gate #37."
  - "2.61 (ERROR-NOTATION-CANON/WAVE-B/2026-07-29): FIVE ADR-010 §Error-Construction Notation Canon violations fixed. (1) Three CLASS3_ASCII_ELLIPSIS_VIOLATION sites in gate text — `...` (three-dot) elision markers replaced with canonical `..`: gate #30 trigger-text sentence (×2) and gate #33 Step B wrapper-form example sentence. (2) Two CLASS3_MISSING_DOTS_VIOLATION sites — `, ..` added before closing `}` to mark elided fields: gate #30 motivating-instance struct observation (`{ category: INTERNAL, message: \"...\", .. }`) and gate #33 wrapper-form discipline bare-struct example (`{ category: X, code: E-YYY-NNN, .. }`). verify-error-notation-canon.sh: FAIL=5 → FAIL=0."
  - "2.60 (FIX-BURST-276-WAVE-C/F-P173-304+F-P173-407/2026-07-27): TWO FINDINGS CLOSED. (1) F-P173-304 HIGH [process-gap]: Gate #25 Part C blocking identity 3 (composite-key uniqueness) lacked a census command and recorded evaluation — burst-275 recorded a quintuple census but identity 3 was never evaluated with inline derivation. Fix: census command added to identity 3 block (awk header-derived extraction of all (Module, Qualifier) composite key pairs piped through sort|uniq -d; any duplicate pair prints inline — self-revealing failure, not an assertion). Evaluation recorded for burst-276-Wave-C: sextuple (decomposition_total_rows=71, decomposition_tiered_rows=69, exempt_count=2, registry_rows=77, registry_distinct_modules=76, matched_rows=69); both difference sets empty; command output empty (zero duplicate (Module, Qualifier) pairs). The 1-row gap (registry_rows=77 vs registry_distinct_modules=76) is the single multi-aspect row: core::serializable appears twice with Qualifiers 'reviver-allowlist CRITICAL' vs 'round-trip HIGH' — DISTINCT Qualifiers, identity 3 PASSES. Four-failure-mode falsifiability argument (F-P173-304 requirement, THE TRAP AVOIDED — no fifth-generation tautology): (a) same (Module, Qualifier) duplicate on two rows — DETECTED: sort|uniq -d prints the duplicate key inline; identity 3 FAILS LOUDLY. (b) module present in decomposition but absent from registry — NOT DETECTED by identity 3: command output is empty regardless; this is identity 2's domain (difference set in matched_rows). (c) module with wrong tier in registry — NOT DETECTED by identity 3: unique composite key, no duplicate output; tier-diff check (Registry→Decomposition direction) covers this. (d) extra module in one list but not the other — NOT DETECTED by identity 3: same reasoning as (b); identity 2 in both directions covers this. Assessment: identity 3 covers failure mode (a) only; modes (b)–(d) require identity 2 and the tier-diff check. Together identities 0–3 plus tier-diff form a complete sensor over the four failure modes; no single identity need cover all four. (2) F-P173-407 MED: DEC-013 orphan corrected. Pass-42 adversarial probe recorded '13/13 CLEAN' (all 13 domain edge cases anchored to a BC with explicit DEC citation) but DEC-013 (Provider Streaming Interrupted by Transport Error) was a one-directional reference: edge-cases.md cited BC-2.08.007 as anchor but BC-2.08.007 carried no reciprocal DEC-013 citation. Fix: BC-2.08.007 updated to cite DEC-013 in traces_to frontmatter and Traceability DEC References row; edge-cases.md anchor text strengthened to a labelled BC-anchor line. Canonical DEC count derivation: 13 = count of ###-DEC-NNN headings in domain-spec/edge-cases.md (DEC-001 through DEC-013, sequential, no gaps). The pass-42 '13/13 CLEAN' probe claim is now accurate."
  - "2.59 (FIX-BURST-276-WAVE-A/F-P173-303+F-P173-306+F-P173-308+F-P173-309+F-P173-310+F-P173-319+L-065/2026-07-27): SIX PROCESS-GAP FINDINGS CLOSED + GATE #37 MINTED (gate-semantics wave — fourth-generation unfalsifiable-suppression remediation). (1) F-P173-303 HIGH [process-gap] — Blocking identity 1 tautology (fourth generation; orchestrator self-attributed; lineage: F-P172b-05 inverted-census-direction → Class A/B flattening ambiguous exempt_count → crate-level annotation asserting an untruth → this tautological parenthetical): false parenthetical claiming identity 1 detects Class A row gains, Class B Criticality drift, or row-count drift deleted; identity 1 annotated to state exactly what it detects (arithmetic slips and malformed Criticality cells ONLY); per-section row vector added as required census member with sum-identity; class_a_row_count added as explicit census member with blocking identity class_a_row_count == 0; Class B membership assertion added (set equality: set of — Criticality rows must equal {core::documents, memory::skills} exactly, not just equal in count). (2) F-P173-306 HIGH [process-gap] — crate-level annotation verification grep unsound: name-prefix heuristic (^| <crate_stem>::) replaced with section-scoped procedure (locate crate's H2/H3 section in module-decomposition.md, enumerate that section's table rows; for Provider Embeddings Modules and Standard Test Modules, additionally match the Crate column); live false PASS route documented (pregolya-standard-tests / eval::judge); enumerated row names recorded per crate; blocking identity verified_count == crate_level_row_count added. (3) F-P173-308 MED — gate #25 Part B Tier-summary row check named a Criticality column that does not exist in verification-coverage-matrix.md (columns are Module|Crate|Kani|proptest|fuzz|Integration|Notes); per-row recount instruction BLOCKED with explicit precondition until architect adds Tier column per F-P173-812 (Wave B); gate now honest about its dependency: until that column exists, tier cross-check uses arch-registry §Classification Summary only (mirroring from sibling document is prohibited by Part B gate rule). (4) F-P173-309 MED — registry_rows self-contradiction (77 in definition, 76 in adjacent roll-up coexistence rule sentence): registry_rows is now unconditionally the total row count (all rows including roll-ups, always 77); registry_census_rows = registry_rows − roll_up_row_count introduced as explicit census member and the intersection denominator; roll_up_row_count added as census member; 'excluded from registry_rows for matched_rows purposes' phrasing deleted from roll-up coexistence rule. (5) F-P173-310 MED [process-gap] — Class A inverse assertion stated with no census command, no recorded value, no covering identity; census command added (grep all four Class A names against decomposition table rows); class_a_row_count member and class_a_row_count == 0 blocking identity added (shared with F-P173-303 item 3 — same identity, single definition). (6) F-P173-319 MED [process-gap] — gate #25 Part C awk field index second break (F-P170-15 fixed $4→$3 one burst earlier; Qualifier column insertion in burst-275 moved Crate from $3 to $4, silently emitting (Module, Qualifier) pairs instead of (Module, Crate) on every row); hardcoded index replaced with header-derived column extraction (awk NR==1 locates Module and Crate columns by name from live header; no future column insertion can break the command without first changing the column name); inline header comment updated to show current Module|Qualifier|Crate|… form; TD-VSDD-060 gate-corpus awk/cut audit: gate #33 census (awk $2/$5 with documented column map) verified against error-taxonomy.md header Error-Code|Category|Severity|BC-Anchor|Message-Format — PASS (column map is accurate); no other hardcoded awk column indices found. (7) Gate #37 LAYER-SCOPED SWEEP BAN minted (standing gate — L-065): three independent P1D-173 slices converged on same root cause (every sweep in this corpus that declared a layer scope left survivors in excluded layers — 'in this file', 'in architecture-layer docs', 'Zero live-body ADR version pins remain in domain-spec/ corpus' each left real survivors in behavioral-contracts/, verification-properties/, prd-supplements/); a sweep or de-pin closure statement may not be layer-scoped; either the sweep is corpus-wide or the closure statement MUST enumerate the excluded layers as named follow-up obligations with a target burst ID; the sweep predicate (what pattern was searched, corpus-wide) must be recorded in the closure statement, not the layer that happened to be searched. total_standing_gates 36→37."
  - "2.58 (burst-275C/2026-07-26): TWO DEFINITIONAL GAPS — exposed by first real census run on v2.57 gate. Gap 1 (same structural class as F-P172b-05): Gate #25 Part C directed that crate-level registry rows be annotated 'no 1:1 decomposition module' so the census skips them — but no clause required the annotation to be TRUE. An annotation that suppresses a check must itself be falsified; this is exactly the F-P172b-05 defect (unfalsifiable clause that silently suppresses a check) one layer down. Motivating instance: the pregolya-macros registry row was annotated crate-level while its Qualifier text enumerated #[tool] #[entrypoint] #[task] — and module-decomposition.md carried macros::tool, macros::entrypoint, macros::task as three separate HIGH tiered rows. The annotation asserted 'no 1:1 decomposition module' about a row with three of them; the census skipped three real gaps. Fix: Part C now requires per-row verification of every crate-level annotation against module-decomposition.md (grep for module rows belonging to the crate; if any exist, annotation is INVALID → HIGH-severity finding); verification must be recorded per-row, not as a summary; a crate-level row may coexist with module rows only as an explicitly-labeled roll-up (which must be excluded from registry_rows for matched_rows computation). Gap 2: registry_rows was undefined as table-ROWS vs distinct-module-names, and the core::serializable duplicate (two rows, same Module cell, distinct Qualifiers for reviver-allowlist CRITICAL and round-trip HIGH) made the distinction load-bearing. Fix: quintuple expanded to sextuple by introducing registry_distinct_modules (count of distinct Module cell values); registry_rows redefined explicitly as total table ROWS; blocking identity 3 added: for any two rows where row_i.Module == row_j.Module, (row_i.Module, row_i.Qualifier) != (row_j.Module, row_j.Qualifier) must hold (duplicate (Module, Qualifier) pair = HIGH-severity finding); matched_rows redefined as explicit SET INTERSECTION {decomposition_tiered_module_names} ∩ {registry_Module_cell_values} with the difference set required to be reported inline and empty — prose-asserting the value is PROHIBITED. Motivating instance: coordinator independently computed matched_rows = 66 against decomposition_tiered_rows = 69 (3 macros module gaps); the prose-asserted value had been accepted without the difference set. Gate #32 step 4b updated to same sextuple + three-identity form."
  - "2.57 (burst-275B/2026-07-26): LOAD-BEARING ARITHMETIC FIX — gate #25 Part B exempt list flattening (v2.56) caused blocking identity misfire. Root cause: v2.56 combined two structurally distinct exempt classes into a flat list of 6, making exempt_count = 6 and decomposition_tiered_rows (68) − exempt_count (6) = 62 ≠ matched_rows (68) — gate would block on a correct census. Separately, the — reciprocal assertion was unevaluable for the four no-row modules (no Criticality cell to check). Fix: split into Class A and Class B with distinct arithmetic roles. Class A — non-row definitions-only (core::context_mutation, core::write_guard, core::guardrail, core::action_risk): NO table row in module-decomposition.md; appear only as prose definitions notes; NOT in row universe; NOT in any count; — reciprocal assertion does NOT apply; INVERSE assertion added (Class A MUST NOT gain a table row — HIGH-severity finding if one appears, requiring architect re-classification). Class B — exempt table rows (core::documents, memory::skills): ARE table rows with Criticality —; ARE in row universe; exempt_count := |Class B| = 2; — reciprocal assertion applies; exempt_count MUST be derived by counting — Criticality rows (not list length); cross-check required (count ≠ list length = HIGH-severity finding). Arithmetic corrected: universe-total identity added: decomposition_total_rows == decomposition_tiered_rows + exempt_count (currently 70 == 68 + 2). Census output changed from triple (decomposition_tiered_rows, registry_rows, matched_rows) to quintuple (decomposition_total_rows, decomposition_tiered_rows, exempt_count, registry_rows, matched_rows). Two blocking identities: identity 1 (universe): decomposition_total_rows == decomposition_tiered_rows + exempt_count; identity 2 (matching completeness): matched_rows == decomposition_tiered_rows. Gate #32 carrier 4 step 4b updated to same quintuple + dual-identity form. Class A / Class B split recorded here to prevent re-flattening."
  - "2.56 (F-P172b-05+OBS-P172b-B/burst-275/2026-07-26): Two process-gap findings closed. (1) F-P172b-05 HIGH [process-gap]: Gate #25 Part B census direction was INVERTED by burst-274 exemption clause ending 'Only check modules that are present as rows in the arch-registry (module-criticality.md) table' — this silently skipped any tiered decomposition module absent from the registry, exactly the gap class to detect. Rewritten BIDIRECTIONAL: Decomposition→Registry direction (absence class): for each module in module-decomposition.md with non-`—` Criticality value, a registry row MUST exist unless the module appears verbatim in the gate #32 carrier-4 exempt list; exempt module carrying a tier value is a reciprocal consistency violation (HIGH); Registry→Decomposition direction (tier-divergence class) retained. Exempt list converted from implicit skip clause to positive allowlist with verbatim-match required; definitions-only and routing-overlay rationale preserved. (2) OBS-P172b-B [process-gap]: No census gate required a positive-coverage assertion — prose completeness claims were unfalsifiable, enabling phantom baselines (F-P172b-02 motivating instance: '56' mirrored registry total across ~170 passes while naming decomposition table, concealing 7 baseline gaps). Gate #25 Part B now REQUIRES a coverage triple (decomposition_tiered_rows, registry_rows, matched_rows) recorded in the burst changelog; blocking assertion: decomposition_tiered_rows − exempt_count == matched_rows; all three numbers independently recomputed from named artifacts in this burst; anti-phantom clause: census figure naming an artifact must be derived by counting that artifact's rows in the burst. Same positive-coverage triple added to gate #32 carrier 4 step 4b."
  - "2.55 (F-P172a-02+F-P172a-03+F-P172a-04+F-P172a-05+F-P172a-06+F-P172a-07+F-P172a-08+F-P172a-12+F-P172a-14+F-P172a-16+F-P172a-17+F-P172a-19/burst-274-B/2026-07-26): Twelve structural/propagation findings closed. (1) F-P172a-02 HIGH: Gate #32 preamble 'three BC-layer carriers' → 'four BC-layer carriers'; carrier 5 'THREE live documents (items 1–3)' → 'FOUR live documents (items 1–4)'; census procedure gained step 4a: check arch-registry (module-criticality.md) for new or re-placed modules, applying definitions-only or routing-overlay exception as appropriate. (2) F-P172a-03 HIGH: Gate #25 Part B/C — 5 live 'four docs / all four' sites → 'three docs / all three'; Part B Census commands: PO-registry row deleted ('Count rows per tier in Module Classification table (PO)' — file is superseded/frozen); historical source citation '(widening — all four criticality-bearing docs added)' preserved as-is (historical record). (3) F-P172a-04 HIGH: Gate #32 carrier 4 definitions-only exception rewritten: (a) memory::skills removed from exempt list — it is Effectful Shell with async I/O (load_skill / list_skills / skill_exists bound to MemoryStore backend per purity-boundary-map.md; not Pure Core); (b) invalid ADR-009 Option 3 precedent citation removed — core::budget HAS a criticality row (SS-10/HIGH/VP-012) and is not a precedent for no-row; direct rationale substituted (modules hosting ONLY type/trait definitions have no algorithmic failure modes to tier-classify); (c) routing-overlay exception class added for memory::skills: structural decomp row exists in module-decomposition.md but no criticality row required — routing/discovery overlay over MemoryStore KV backend with no execution-business-logic; (d) core::documents definitions-only exemption resolved — architect adjudication confirmed (FIX-BURST-274): ADR-014 Decision 2 states 'No I/O. Pure data carrier. Pure Core classification.'; struct has only page_content/metadata/id fields with derived impls; no execution methods; no VP target; Criticality column changed from MEDIUM to — in module-decomposition.md; no criticality row required; core::documents added to definitions-only exempt case lists (gate #25 Part B exemption clause + gate #32 carrier 4 established-cases list). (4) F-P172a-12 MED: Gate #25 Part B derived-doc check — exemption clause added for definitions-only modules (core::context_mutation, core::write_guard, core::guardrail, core::action_risk) and routing-overlay modules (memory::skills); their absence from module-criticality.md is intentional, not a mismatch; census checks only modules present in the arch registry. (5) F-P172a-05 MED: Gate #28 DEFER-002 narrowed — verify-changelog-date-monotonicity.sh (Rules 2+3) and verify-form-a-changelog-direction.sh (Rule 6 Form A direction) are now LIVE blocking pre-commit hooks; remaining deferred to Phase 3: Rule 1 (date ≤ timestamp supplement branch), Rule 4 (temporal-neighbor sweep), Rule 5 (frontmatter-currency machine check), Rule 6 Form B (body-table direction machine check); both-forms co-existence WARNs emitted by verify-changelog-date-monotonicity.sh noted as non-blocking. (6) F-P172a-06 MED: Gate #28 date-validity census upgraded — verify-changelog-date-monotonicity.sh is now the authoritative corpus-wide date sweep (replaces manual file enumeration as primary); manual fallback widened from 5 to 11 files by adding ADR-007, ADR-009, ADR-012, ADR-013, BC-INDEX.md, verification-architecture.md; verification-architecture.md classified as architecture/ (not supplement). (7) F-P172a-07 MED: Gate #28 Rule 5 supplement enumeration extended 6→7: observability.md added (status: active, version 1.5). (8) F-P172a-08 MED: Six 'all 95 BCs' / '95-BC plan total' staleness sites de-pinned — subsystem_note, Batch 13 scope note, guideline #1, guideline #8, guideline #13 census prose, gate #28 Rule 6 census header — all now read 'all BCs in BC-INDEX' or 'BC-INDEX plan total'. TD-VSDD-060 sibling sweep: six sites confirmed, no others (changelog rows exempt per TD-VSDD-091). (9) F-P172a-14 MED: FORM CHOICE — Form A (frontmatter changelog: YAML list) is the single authoritative form for bc-authoring-plan.md; Form B (## Changelog body table) retained as historical audit trail with explicit 'historical record — superseded by frontmatter changelog' banner; bc-authoring-plan.md reclassified from 'Form-B-only' to 'BOTH forms (Form A authoritative)' in gate #28 known-file list. (10) F-P172a-16 LOW: Gate #25 Part B after-editing bullet — heading example '## pregolya-macros — MEDIUM' marked explicitly hypothetical to prevent backward correction against a module that has a different tier in the registry. (11) F-P172a-17 LOW: Authoring Guidelines source order corrected — item 16 (E-code↔variant-name census gate) now precedes item 17 (HTTP endpoint census gate) in source; rendered positions now match numbering; gate #21 reference 'guideline #17 above' (HTTP endpoint census) is now correct by rendered position. (12) F-P172a-19 LOW: VP-NNN candidate policy disambiguation added — bare 'VP-NNN candidate' label means proposed VP ID not yet assigned in VP-INDEX (rule (3) drop-the-qualifier applies when assigned); 'VP-NNN (Kani P1 candidate)' or 'VP-NNN (<tier> qualifier)' label means VP IS assigned in VP-INDEX and the parenthetical is a tier/priority descriptor — rule (3) does NOT apply to tier-descriptor qualifiers; BC-2.23.005 row 'VP-013 (Kani P1 candidate)' is COMPLIANT (VP-013 is assigned in VP-INDEX per gate #13 census). (13) FIX-BURST-274 amendments: core::documents added to definitions-only exempt case lists (gate #25 Part B exemption clause + gate #32 carrier 4 established-cases list); gate #25 Part C census comment de-pinned (hardcoded 'exactly 44' count replaced with instruction to recompute from arch-registry §Classification Summary — registry is actively growing per architect's corpus-wide sweep; de-pinned per F-P170-14 precedent)."
  - "2.54 (F-P172a-01+F-P172a-09+F-P172a-10+F-P172a-11+F-P172a-13+F-P172a-15+F-P172a-18/burst-274/2026-07-25): Seven broken-census-command findings closed. (1) F-P172a-01 HIGH: Gate #33 census anchor field index corrected from column 4 (Severity) to column 5 (BC-Anchor); inline column-map note added; follow-on grep patched to use find or ss-*/ glob instead of globstar; dry-run: 107/108 live codes resolve, E-TOOLS-008 multi-anchor cell verified across all 5 listed BCs. (2) F-P172a-09 MED: Gate #13 VP-uniqueness regex widened to cover all three VP-ID forms (numeric VP-001..013, dotted VP-2.04.001-A, alpha-domain VP-BSP-DET-01); BC-INDEX.md excluded; census now extracts only primary first-column VP ID to distinguish DEFINITION from CITATION; DEFINITION vs CITATION disambiguated in rule text; dry-run: no collisions. (3) F-P172a-10 MED: Gate #25 Part C census replaced bare grep-n pipeline (broken: -n prefix defeats header filter; unsectioned sweep produces junk rows from security-profile section) with section-scoped awk+grep pipeline; dry-run: exactly 44 module-crate pairs, no junk rows. (4) F-P172a-11 MED: Gate #25 Part B changed 'Module Inventory table (arch)' to 'Module Classification table (arch)' — the arch registry section is named Module Classification, not Module Inventory (that name belongs to the superseded PO file). (5) F-P172a-13 MED: Gate #36 steps 1 and 2 glob narrowed from VP-star.md to VP-[0-9][0-9][0-9].md to exclude VP-INDEX.md; explicit note added that VP-INDEX.md lacks red_gate: by design; dry-run step 2: empty output confirmed. (6) F-P172a-15 LOW: Gate #25 Part B heading-check command bare filename 'module-decomposition.md' given full path '.factory/specs/architecture/module-decomposition.md'. (7) F-P172a-18 LOW: Gate #28 Step 1 converted from count-only (wc -l, includes BC-INDEX.md) to filename-emitting list (cut -d: -f1, BC-INDEX.md excluded via --exclude); Step 2 prose clarified that Form A and Form B union is computed independently of Step 1 output. TD-VSDD-060 class sweep: gate #25 Part C was the sole broken-command site of the grep-n header-filter class; no other awk anchor-column sites found."
  - "2.53 (F-P171a-08+F-P171a-16+F-P171a-17/burst-273/2026-07-25): Three process-gap findings closed. (1) F-P171a-08 MED: Gate #32 step 4 — add definitions-only carve-out: modules hosting ONLY type/trait definitions with no execution logic are exempt from the arch-registry criticality table requirement (ADR-009 Option 3 precedent); five established exempt cases listed (core::context_mutation, core::write_guard, core::guardrail, memory::skills, core::action_risk); tools::config is NOT exempt (has validation logic). Exempt modules must appear in purity-boundary-map.md §Pure Core and module-decomposition.md definitions note. (2) F-P171a-16 LOW: §Authoring Guidelines VP-NNN candidate label adjudication documented — 'VP-NNN candidate' is acceptable PO/BA shorthand for a seeded VP that has not yet received a permanent VP-INDEX entry; it signals intent to the architect without implying the VP is assigned or active. (3) F-P171a-17 LOW: Gate #28 Rule 5 FRONTMATTER-CURRENCY — add ADR branch: ADR document timestamp:/date: fields = original decision date (frozen at first acceptance); currency tracked via version: + changelog; amendment does not update the original decision date."
  - "2.52 (F-P170-08/F-P170-13/F-P170-14/F-P170-15/burst-272/2026-07-25): Four process-gap findings closed. (1) F-P170-08 HIGH: Gate #25 Part B 'ALL FOUR' → 'ALL THREE' — prd-supplements/module-criticality.md (PO registry) is superseded/frozen; removed from live sibling set; added explicit frozen/do-not-sync note for item 5; corresponding Gate #32 step 5 restated as frozen. Gate #32 step 5 now reads: 'status: superseded — DO NOT SYNC; any new ADR module addition need only appear in the three live documents.' Never-update-all-four clause updated to never-update-all-three. (2) F-P170-13 MED: Gate #32 step 4 wrong path '.factory/specs/architecture/module-criticality.md' → '.factory/specs/module-criticality.md' (only one instance in whole document — confirmed by grep). (3) F-P170-14 MED: Gate #25 Part B census tier-summary row check de-pinned — removed hardcoded 'Example correct value: 9/12/10/2=33' (pre-D21/D23 stale value); replaced with instruction to recompute from arch-registry §Classification Summary. Historical motivating-instance text (OBS-P37-1) preserved untouched. (4) F-P170-15 MED: Gate #25 Part C awk census command corrected from '{print $2, $4}' to '{print $2, $3}' — table header 'Module | Crate | SS | Tier | VP | Kill Rate | Phase Gate' puts Crate at $3 not $4; previous command printed (Module, SS) not (Module, Crate), causing guaranteed false mismatches on every module row."
  - "2.51 (F-P163-01/FIX-BURST-265/2026-07-25): Gate #27 ARCH-ANCHOR CRATE-RESOLUTION CENSUS updated for 21-crate roster (closes F-P163-01 [process-gap, HIGH]). (1) Rule 1 label: 'ADR-007 18-crate roster (+xtask)' → 'ARCH-INDEX §Canonical Crate Roster (21 published crates + xtask)' — ARCH-INDEX is the authoritative living source of truth, not ADR-007 (which documents the original 18-crate topology). (2) Embedded roster block relabeled 'ARCH-INDEX §Canonical Crate Roster (source of truth — 21 published crates)'; three new crates appended: pregolya-prompts (D21/ADR-015), pregolya-vectorstores (D21/ADR-014), pregolya-tools (D23/ADR-020); disambiguation note added (ADR-007 is original 18; ARCH-INDEX is SoT). (3) Three ownership rules added: prompts::template/chat_template/few_shot/injection_guard → pregolya-prompts (SS-18); vectorstores::store/retriever/memory/similarity/mmr → pregolya-vectorstores (SS-20/SS-21); tools::fs/shell/search → pregolya-tools (SS-23). (4) Census command prose: '18-crate roster' → '21-crate roster'. Sanity-check results: BC-2.21.003 (vectorstores::similarity) PASS rule 1 (pregolya-vectorstores ∈ 21-crate roster) + PASS rule 2 (similarity owned by pregolya-vectorstores per module-decomp SS-21); SS-18 BC (BC-2.18.004, pregolya-prompts/injection_guard) PASS rule 1 + PASS rule 2 (injection_guard owned by pregolya-prompts SS-18); SS-23 BC (BC-2.23.005, pregolya-tools/tools-shell) PASS rule 1 + PASS rule 2 (tools::shell owned by pregolya-tools SS-23). Sweep for other live '18-crate' or '18 crates' in bc-authoring-plan.md (changelog rows exempt): zero remaining hits."
  - "2.50 (F-P161-01/FIX-BURST-262/2026-07-25): Three NORMATIVE version pins de-pinned + five HISTORICAL pins allowlisted (TD-VSDD-091 stable-anchor enforcement, F-P161-01). De-pinned: (1) Gate #12 lifecycle-arrow census authority 'BC-2.12.003 v1.4 PC7-PC9' → 'BC-2.12.003 PC7-PC9'. (2) Gate #12 source citation 'F-P117-01 adjudication (fix burst 120, BC-2.12.003 v1.4)' → '(fix burst 120, BC-2.12.003)'. (3) Type-census table BudgetInfo authority 'BC-2.10.003 v1.2 PC5/INV/TV-007' → 'BC-2.10.003 PC5/INV/TV-007'. Allowlisted (HISTORICAL-RECORD prose, version-pin-allowlist.txt entries at post-edit line numbers): 1677 (BC-2.08.004 v1.2 in ADV-P1D-PASS-56-COMPLETION RESOLVED note), 1707 (BC-2.04.002 v1.3 / BC-2.04.007 v1.6 / BC-2.08.002 v1.4 / BC-2.08.006 v1.4 / BC-2.08.014 v1.3 in F-P112-02 fix-burst record), 2115 (BC-2.08.014 v1.2), 2119 (BC-2.04.007 v1.5), 2125 (BC-2.08.013 v1.2) in F-P108-04 motivating-instance records."
  - "2.49 (burst-255/OBS-P154-A/2026-07-24): Gate #35 VP PROPERTY-BODY COHERENCE extended — TRIGGER now also fires on edits to VP-scope bullets in BC-2.17.001.md (SS-17 Kani-harness-scope authority); ACTION extended with step 7: VP-NNN.md INTERNAL consistency check: §Proof Method table coverage claims, §Proof Harness Skeleton proof-fn inventory, §BC Traceability scope statements, and §Proof Obligations outcome-type claims must all agree internally AND with the citing BC-2.17.001 bullet; a coverage claim ('covers all N variants') must be backed by an actual harness fn per claimed variant or an explicit peel-off/out-of-scope statement. Root cause of F-P154-01/02: burst-254 VP-011 bullet modernization propagated to BC/index rows but not cross-checked against VP-011.md §Proof Method table and §Proof Harness Skeleton which contradicted each other internally."
  - "2.48 (F-P149-02/burst-250/2026-07-24): Three live-body version pins de-pinned (TD-VSDD-091 stable-anchor enforcement, F-P149-02). (1) Retired-identifiers table: 'ADR-009 v1.1 confirms same rename' → 'ADR-009 §Decision confirms same rename' (PolicyDecision type is listed in ADR-009 §Decision / §Consequences). (2) Gate #20 census rule: 'per ADR-010 v1.1)' → 'per ADR-010 §Component Axis Expansion (D21))' (D21 component-axis expansion is the named section in ADR-010). (3) Gate #27 ownership rule: 'ADR-009 v1.2 Option 3 places budget TRAIT/types' → 'ADR-009 §Decision (Option 3 split) places budget TRAIT/types' (Option 3 is the chosen option in ADR-009 §Decision)."
  - "2.47 (burst-248/F-P147-02+F-P147-03/2026-07-24): Gate #36 VP↔BC RED-GATE PARITY minted (standing gate [process-gap, F-P147-03]) — every VP-NNN.md must carry explicit red_gate: frontmatter field (true or false, never absent); red_gate: true requires three-way corroboration: anchor BC frontmatter red_gate: true + BC-INDEX Red Gate membership + verifiable red_gate_source citation (anti-fabrication clause: citation must be quote-verifiable in the cited document); on divergence BC frontmatter + BC-INDEX census win over VP (BC supersedes VP for contract-discipline designations per CLAUDE.md Source-of-Truth Precedence); VP-side corrections route to architect; BC-side corrections route to product-owner. Motivating instance: VP-011 carried red_gate: true with fabricated ADR-018 citation (ADR-018 contains no Red Gate mandate); anchor BC-2.05.007 adjudicated false by architect; six VP files lacked the field entirely. F-P147-02: error-taxonomy.md v1.37→v1.38 E-TOOLS-002 placeholder count Two→Three corrected; taxonomy-wide placeholder-count parity scan: 10 other count-stating rows all verified correct (E-MCP-006 Two ✓, E-TMPL-001 Two ✓, E-TMPL-003 One ✓, E-VS-003 Two ✓, E-TOOLS-003 One ✓, E-TOOLS-004 One ✓, E-TOOLS-007 One ✓, E-TOOLS-008 Three ✓, E-TOOLS-009 Two ✓). total_standing_gates 35→36."
  - "2.46 (burst-247/F-P146-02+OBS/2026-07-24): (1) Gate #35 VP PROPERTY-BODY COHERENCE minted — on any edit to a VP-NNN.md or verification-architecture.md VP catalog entry, diff property statement + variant/branch coverage + harness sketch between the two docs; VP-NNN.md wins on divergence (CLAUDE.md source-of-truth precedence rule 4). Routing: architect scope for verification-architecture.md fixes. (2) SS-23 BC title error-code enumeration policy added as a non-numbered policy note in Authoring Guidelines (between items 11 and 12): titles enumerate ALL and ONLY raised error codes; Ok-path payload flags (E-TOOLS-005 BashOutput.truncated, E-TOOLS-006 GrepResult.capped) excluded. (3) Batch 20 BC title rows synchronized to exact H1 titles per bc_h1_is_title_source_of_truth: all 6 SS-23 BC rows updated (001 separator normalized; 001/002/004 E-TOOLS-008 added; 003 E-TOOLS-001/003/008 added + EditConfig::fuzzy_threshold restored; 005 BashOutput added, E-TOOLS-005 removed, E-TOOLS-004/007; 006 Hermetic added, E-TOOLS-001/008/009). total_standing_gates 34→35."
  - "2.45 (F-P142-03, burst-242, 2026-07-23): BC-2.06.005 title in Batch 20 table updated — 'Emission on Command::Resume' → 'Emission on Command(resume=…)' per BC-2.05.004 struct kwarg authority and BC-2.06.005 H1 (bc_h1_is_title_source_of_truth)."
  - "2.44 (burst-237/F-P137-02+F-P137-03/2026-07-23): F-P137-02 DI table: add DI-015 row (Subprocess Execution Timeout) — enforcers BC-2.23.005 (primary) + BC-2.13.002 (co-enforcer, .kill_on_drop(true)); remove BC-2.23.005 from DI-009 row (re-anchored burst-234 F-P134-06); DI-009 row corrected to {BC-2.08.007, BC-2.08.014, BC-2.14.004, BC-2.22.002, BC-2.22.003}; coverage 14/14→15/15. F-P137-03 CAP-017 wave-1 promotion: SS.15 subsystem map CAP-017 (P2)→(P1), priority P1/P2→P1; Batch 11 header (P1/P2)→(P1); BC-2.15.001/002/003 Wave 2→Wave 1. TD-VSDD-060 sweep: Batch 20 BC-2.23.005 DI column DI-009,DI-014→DI-014,DI-015 (same burst-234 re-anchor not propagated to batch table)."
  - "2.43 (burst-233/F-P133-02/2026-07-22): BC-2.16.001/002/003 Wave-1 promotion per D23 — SS.16 priority P2→P1; frontmatter p1_count 72→75, p2_count 6→3; Summary table P1 72→75, P2 6→3; Full BC table rows P2→Post-v1→P1/Wave 1."
  - "2.42 (D23/2026-07-22): D21 retroactive registration (Batches 16-18, +21 BCs); D23 Integration (Batches 19-20, +13 BCs); BC-2.15.001/002/003 promoted P2→P1; SS.18..23 added to subsystem map; counts 95→129."
  - "2.41 (D21/2026-07-20): D21 ADR-010 v1.1 error-model integration."
subsystem_note: "BCs were authored with subsystem: SS-TBD; ARCH-INDEX SS-NN IDs assigned at Phase 1b — RESOLVED 2026-07-14, see BC-INDEX. All BCs in BC-INDEX carry real SS-NN subsystem IDs."
---

# BC Authoring Plan: pregolya

> This plan enumerates every BC-S.SS.NNN to be authored, organized into
> batches of ≤8 BCs each at initial planning (Batch 9 carries a documented 9th BC — BC-2.08.009, Step-E addition per ADR-004 acceptance) for sequential sub-bursts. Each batch is one sub-burst.
> BC files go to `.factory/specs/behavioral-contracts/ss-NN/BC-S.SS.NNN.md`
> using the SS-NN ID from ARCH-INDEX Subsystem Registry (assigned Phase 1 Step D, 2026-07-14).

## Summary

| Metric | Value |
|--------|-------|
| Total BCs | 134 |
| P0 (must-have) | 51 |
| P1 (should-have) | 80 |
| P2 (nice-to-have) | 3 |
| Batches | 20 |
| BCs per batch (max) | 9 (Batch 9 only — Step-E exception; planning cap remains 8) |
| Subsystems covered | 23 (SS.01–SS.23, mapping CAP-001–CAP-039) |

## Subsystem → CAP Mapping

| Subsection | CAP(s) | Crate | Priority |
|-----------|--------|-------|----------|
| SS.01 | CAP-001, CAP-002, CAP-039 | pregolya-core | P0/P1 |
| SS.02 | CAP-003 | pregolya-graph | P0 |
| SS.03 | CAP-004 | pregolya-graph | P0 |
| SS.04 | CAP-005 | pregolya-checkpoint | P0 |
| SS.05 | CAP-006 | pregolya-graph | P0 |
| SS.06 | CAP-007 | pregolya-graph, pregolya-core | P0 |
| SS.07 | CAP-008 | pregolya-splitters | P0 |
| SS.08 | CAP-009, CAP-011 | pregolya-\<provider\>, pregolya-standard-tests | P1 |
| SS.09 | CAP-010, CAP-021 | pregolya-mcp | P1 |
| SS.10 | CAP-012 | pregolya-graph | P0 |
| SS.11 | CAP-013 | pregolya-graph | P0 |
| SS.12 | CAP-014 | pregolya-server | P1 |
| SS.13 | CAP-015 | pregolya-sandbox | P1 |
| SS.14 | CAP-016 | pregolya-core | P0 |
| SS.15 | CAP-017 (P1), CAP-020 (P1) | pregolya-memory | P1 |
| SS.16 | CAP-018 | pregolya-core | P1 |
| SS.17 | CAP-019 | xtask, pregolya-graph, pregolya-checkpoint, pregolya-sandbox | P2 |
| SS.18 | CAP-022, CAP-023 | pregolya-prompts | P1 |
| SS.19 | CAP-024, CAP-025 | pregolya-core | P1 |
| SS.20 | CAP-026, CAP-027 | pregolya-core, pregolya-vectorstores | P1 |
| SS.21 | CAP-028, CAP-029, CAP-030 | pregolya-vectorstores | P1 |
| SS.22 | CAP-031, CAP-032, CAP-033 | pregolya-core, pregolya-openai, pregolya-ollama | P1 |
| SS.23 | CAP-034, CAP-035, CAP-036, CAP-037, CAP-038 | pregolya-tools | P1 |

## D17 Phase-1 BC Commitments Coverage

| D17 Commitment | BCs |
|----------------|-----|
| Q2: HITL contract | BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.05.004, BC-2.05.005, BC-2.05.006 |
| Q3: Per-task durability | BC-2.04.001, BC-2.04.002, BC-2.04.005 |
| Q4: Budget governance | BC-2.10.001, BC-2.10.002, BC-2.10.003, BC-2.10.004 |
| Q8: Content provenance/guardrail-on-ingress | BC-2.11.001–006 |
| Q9: R8 (splitters parity) | BC-2.07.001, BC-2.07.002 |
| Q9: R10 (NamedBarrierValue/EphemeralValue) | BC-2.02.003, BC-2.02.004 |
| Q9: R11 (MCP test voids) | BC-2.09.004, BC-2.09.005 |

> **Risk ID reconciliation:** `R11` used throughout this plan matches `R-006` in
> `domain-spec/risks.md` (both describe "MCP test voids: bare ToolException re-raise path
> untested upstream; `__aenter__` NotImplementedError contract untested"). STATE.md uses `R11`
> as a shorthand inherited from the D17 gate decisions; risks.md uses the canonical `R-006`
> identifier. They are the same risk. BCs continue to reference `R11` for consistency with
> STATE.md; the canonical ID for future artifacts is `R-006`.

## NE Requirement Coverage Summary

| NE | BC Anchors |
|----|-----------|
| NE-01 | BC-2.13.001 |
| NE-02 | BC-2.13.004, BC-2.13.005 |
| NE-03 | BC-2.14.006 |
| NE-04 | BC-2.14.004 |
| NE-05 | CI lint gate (ADR, no BC) |
| NE-06 | BC-2.11.002, BC-2.11.003, BC-2.11.004 |
| NE-07 | BC-2.14.003 |
| NE-08 | BC-2.12.006 |
| NE-09 | BC-2.16.001, BC-2.16.002, BC-2.16.003 |
| NE-10 | BC-2.14.005 |
| NE-11 | BC-2.04.007 |
| NE-12 | BC-2.04.006 |
| NE-13 | BC-2.06.003, BC-2.12.007 |
| NE-14 | BC-2.12.005 |
| NE-15 | BC-2.08.008 |
| NE-16 | BC-2.13.006 |
| NE-17 | BC-2.03.001, BC-2.03.003 |

## DI Invariant Enforcement Coverage

| DI | Enforcing BCs |
|----|--------------|
| DI-001 | BC-2.02.002, BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.17.001 |
| DI-002 | BC-2.04.001, BC-2.04.002, BC-2.04.005, BC-2.04.008, BC-2.15.006 |
| DI-003 | BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.05.004, BC-2.05.005, BC-2.05.006, BC-2.10.004 |
| DI-004 | BC-2.04.003, BC-2.04.004 |
| DI-005 | BC-2.04.006, BC-2.17.001 |
| DI-006 | BC-2.13.001, BC-2.13.002, BC-2.13.003, BC-2.13.006, BC-2.13.007 |
| DI-007 | BC-2.13.004, BC-2.13.005, BC-2.17.001 |
| DI-008 | BC-2.01.001, BC-2.01.002, BC-2.04.008, BC-2.08.006, BC-2.08.010, BC-2.08.013, BC-2.08.014, BC-2.09.006, BC-2.09.007, BC-2.09.008, BC-2.13.007, BC-2.14.001, BC-2.14.003, BC-2.15.004, BC-2.15.005, BC-2.15.006, BC-2.18.001, BC-2.18.002, BC-2.18.003, BC-2.18.004, BC-2.18.005, BC-2.19.001, BC-2.19.002, BC-2.19.003, BC-2.19.004, BC-2.19.005, BC-2.19.006, BC-2.20.001, BC-2.20.003, BC-2.21.001, BC-2.21.002, BC-2.21.003, BC-2.21.004, BC-2.22.001, BC-2.22.002, BC-2.22.003 |
| DI-009 | BC-2.08.007, BC-2.08.014, BC-2.14.004, BC-2.22.002, BC-2.22.003 |
| DI-010 | BC-2.08.014, BC-2.09.007, BC-2.09.008, BC-2.13.007, BC-2.14.005, BC-2.19.002, BC-2.22.002 |
| DI-011 | BC-2.06.001, BC-2.06.003, BC-2.08.001, BC-2.12.007 |
| DI-012 | BC-2.09.003, BC-2.11.001, BC-2.11.002, BC-2.11.003, BC-2.11.004, BC-2.11.005, BC-2.11.006, BC-2.15.005, BC-2.20.001, BC-2.20.002 |
| DI-013 | BC-2.12.005 |
| DI-014 | BC-2.01.005, BC-2.01.006, BC-2.01.007, BC-2.01.008, BC-2.04.008, BC-2.08.004, BC-2.08.007, BC-2.08.013, BC-2.08.014, BC-2.09.004, BC-2.09.005, BC-2.09.006, BC-2.09.007, BC-2.09.008, BC-2.14.001, BC-2.14.006, BC-2.15.004, BC-2.15.005, BC-2.15.006, BC-2.18.001, BC-2.18.004, BC-2.18.005, BC-2.19.005, BC-2.19.006, BC-2.20.001, BC-2.20.002, BC-2.21.003, BC-2.21.004, BC-2.22.001, BC-2.22.002, BC-2.22.003, BC-2.05.007, BC-2.05.008, BC-2.06.004, BC-2.06.005, BC-2.06.006, BC-2.10.005, BC-2.10.006, BC-2.23.001, BC-2.23.002, BC-2.23.003, BC-2.23.004, BC-2.23.005, BC-2.23.006 |
| DI-015 | BC-2.23.005, BC-2.13.002 |
| DI-016 | BC-2.01.005, BC-2.01.006, BC-2.01.008 |

**Coverage: 16/16 DIs enforced. Zero orphan invariants.**

---

## Batch Assignments

> **Wave-0 convention (OBS-P45-1 reconciliation):** Thirteen BCs across SS-01, SS-07, and SS-14
> carry `wave: Wave 0` in their frontmatter and in the batch tables below. ARCH-INDEX Subsystem
> Registry and `dependency-graph.md` use a coarser two-wave crate-build scheme (Wave 1 / Wave 2)
> with no "Wave 0." Both conventions are canonical at their own granularity:
> **Wave 0 ⊂ Wave 1** — Wave 0 is a foundational sub-wave of Wave 1 covering BCs with no
> intra-workspace crate dependencies (pregolya-core message primitives, pregolya-splitters
> text utilities, and pregolya-core error taxonomy). All Wave 0 BCs participate in Wave 1 of
> the ARCH-INDEX two-wave build scheme. Wave 2 BCs (SS-02, SS-03, SS-04, SS-05, etc.) depend on
> one or more Wave 0/1 crates. This sub-wave distinction is a BC-planning granularity choice only;
> it does not create a third build wave. Source: OBS-P45-1 (ADV-P1D-PASS-45).

### Batch 1 — Core Primitives + Error Taxonomy Foundation (P0 first principles)
*12 BCs — SS.01 + SS.14 partial (8 original P0; +4 CAP-039 LCEL P1 added burst-302b)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.01.001 | Typed ContentBlock sequence construction (no raw content where typed expected) | P0 | CAP-001 | DI-008 | Wave 0 |
| BC-2.01.002 | Message type-safety (AiMessage/HumanMessage/SystemMessage/ToolMessage) | P0 | CAP-001 | DI-008 | Wave 0 |
| BC-2.01.003 | Runnable trait invocation — invoke, stream, batch | P0 | CAP-002 | — | Wave 0 |
| BC-2.01.004 | Runnable pipe composition (A \| B = AB chain) | P0 | CAP-002 | — | Wave 0 |
| BC-2.01.005 | RunnableParallel Construction and Concurrent Invocation | P1 | CAP-039 | DI-014, DI-016 | Wave 1 |
| BC-2.01.006 | RunnableParallel Branch Failure — Fail-Fast, Structured Error, No Partial Results | P1 | CAP-039 | DI-014, DI-016 | Wave 1 |
| BC-2.01.007 | RunnablePassthrough Identity Pass-Through and Inspect Side-Effect Contract | P1 | CAP-039 | DI-014 | Wave 1 |
| BC-2.01.008 | RunnableAssign Dict Augmentation — Merge Semantics and Dict-Input Validation | P1 | CAP-039 | DI-014, DI-016 | Wave 1 |
| BC-2.14.001 | PregolyaError 2D component × category struct with RetryHint and machine code | P0 | CAP-016 | DI-008, DI-014 | Wave 0 |
| BC-2.14.002 | RFC-7807 compatible problem emission from PregolyaError | P0 | CAP-016 | — | Wave 0 |
| BC-2.14.003 | All library constructors return Result; no .unwrap()/.expect()/assert! in non-test (NE-07) | P0 | CAP-016 | DI-008 | Wave 0 |
| BC-2.14.004 | Every outbound HTTP ClientBuilder must set .timeout(30s); zero Client::new() outside tests (NE-04) | P0 | CAP-016 | DI-009 | Wave 0 |

### Batch 2 — Error Taxonomy Cont. + BSP Execution + Text Splitting (P0 correctness contracts)
*8 BCs — SS.14 cont. + SS.03 + SS.07*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.14.005 | API key newtype + Debug→"<redacted>"; no Serialize; no Deref<Target=str> (NE-10) | P0 | CAP-016 | DI-010 | Wave 0 |
| BC-2.14.006 | Validation failures propagate Err(PregolyaError); no silent None (NE-03) | P0 | CAP-016 | DI-014 | Wave 0 |
| BC-2.03.001 | BSP super-step execution determinism — Kani VP seed (NE-17) | P0 | CAP-004 | DI-001 | Wave 1 |
| BC-2.03.002 | Concurrent LastValue write rejection raises InvalidUpdateError | P0 | CAP-004 | DI-001 | Wave 1 |
| BC-2.03.003 | Deterministic reducer application order (task-identity sort) | P0 | CAP-004 | DI-001 | Wave 1 |
| BC-2.07.001 | Chunk boundaries are Unicode code-point counts (not bytes) | P0 | CAP-008 | — | Wave 0 |
| BC-2.07.002 | Non-ASCII boundary parity with Python reference implementation (emoji, CJK) — R8 Red Gate | P0 | CAP-008 | — | Wave 0 |
| BC-2.07.003 | Short document (length < chunk_size) — single chunk, no overlap, no panic | P0 | CAP-008 | — | Wave 0 |

### Batch 3 — Checkpointing Full Subsystem (P0 durability)
*7 BCs — SS.04 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.04.001 | Per-task put_writes completes before next super-step begins | P0 | CAP-005 | DI-002 | Wave 1 |
| BC-2.04.002 | Sync durability tier is default; async and exit-only are explicit opt-in | P0 | CAP-005 | DI-002 | Wave 1 |
| BC-2.04.003 | Monotonic logical-clock checkpoint IDs — wall-clock UUIDs are rejected | P0 | CAP-005 | DI-004 | Wave 1 |
| BC-2.04.004 | Fork lineage via parent_checkpoint_id pointers; no state copy on fork | P0 | CAP-005 | DI-004 | Wave 1 |
| BC-2.04.005 | Crash recovery: completed tasks not re-executed after process restart | P0 | CAP-005 | DI-002 | Wave 1 |
| BC-2.04.006 | Session triple-address uniqueness (thread_id, checkpoint_ns, checkpoint_id) — Kani VP seed (NE-12) | P0 | CAP-005 | DI-005 | Wave 1 |
| BC-2.04.007 | Encryption at rest covers both state AND event payloads; rotation errors propagate (NE-11) | P0 | CAP-005 | — | Wave 1 |

### Batch 4 — HITL Interrupt/Resume Full Subsystem (P0 D17-Q2 mandate)
*6 BCs — SS.05 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.05.001 | Interrupt suspension with durable state persistence | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.002 | Resume values delivered in strict FIFO order | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.003 | Interrupted node re-executes from start of its super-step on resume | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.004 | Command(resume=value) API contract for programmatic resume | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.005 | Resume on empty interrupt queue returns Err(NoActiveInterrupt) | P0 | CAP-006 | DI-003 | Wave 1 |
| BC-2.05.006 | Risk-tiered interrupt classification (typed action-risk levels for Domain A SOC) | P0 | CAP-006 | DI-003 | Wave 1 |

### Batch 5 — StateGraph Definition Full Subsystem (P0)
*6 BCs — SS.02 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.02.001 | StateGraph node definition with typed channel assignment | P0 | CAP-003 | — | Wave 1 |
| BC-2.02.002 | LastValue / Append / BarrierValue channel semantics and reducer wiring | P0 | CAP-003 | DI-001 | Wave 1 |
| BC-2.02.003 | NamedBarrierValue missing-writer boundary behavior — Red Gate test (R10) | P0 | CAP-003 | — | Wave 1 |
| BC-2.02.004 | EphemeralValue cleared-after-super-step semantics — Red Gate test (R10) | P0 | CAP-003 | — | Wave 1 |
| BC-2.02.005 | Conditional edge routing function | P0 | CAP-003 | — | Wave 1 |
| BC-2.02.006 | Send API dynamic fan-out | P0 | CAP-003 | — | Wave 1 |

### Batch 6 — Streaming Events + Budget Governance (P0 D17-Q4 mandate)
*7 BCs — SS.06 + SS.10*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.06.001 | Typed per-phase event taxonomy (run/step/node/tool start-stream-end) | P0 | CAP-007 | DI-011 | Wave 1 |
| BC-2.06.002 | run_id + parent_ids correlation across all streaming events | P0 | CAP-007 | — | Wave 1 |
| BC-2.06.003 | Streaming and unary run produce identical final answer (NE-13) | P0 | CAP-007 | DI-011 | Wave 1 |
| BC-2.10.001 | BudgetPolicy allow/escalate/deny evaluation per run and per sub-agent | P0 | CAP-012 | — | Wave 1 |
| BC-2.10.002 | Append-only EvidenceJournal records every budget evaluation | P0 | CAP-012 | — | Wave 1 |
| BC-2.10.003 | Graceful halt when budget ceiling reached (on_ceiling = halt | summarize) | P0 | CAP-012 | — | Wave 1 |
| BC-2.10.004 | Budget escalation to HITL interrupt when on_ceiling = escalate | P0 | CAP-012 | DI-003 | Wave 1 |

### Batch 7 — Content Provenance + Guardrail-on-Ingress Full Subsystem (P0 D17-Q8 mandate)
*6 BCs — SS.11 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.11.001 | ProvenanceTag attached at every ingress boundary (tool-result, RAG, memory) | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.002 | GuardrailHook fires unconditionally at tool-result ingress | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.003 | GuardrailHook fires at RAG ingress | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.004 | GuardrailHook fires at memory ingress | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.005 | Rejected content does not enter model context under any code path | P0 | CAP-013 | DI-012 | Wave 1 |
| BC-2.11.006 | No-hook default: content passes through with WARNING LOG (default-permit) | P0 | CAP-013 | DI-012 | Wave 1 |

### Batch 8 — Sandboxed Tool Execution Full Subsystem (P1)
*6 BCs — SS.13 complete*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.13.001 | Enforcing sandbox backend (WASM or container) is default (NE-01) | P1 | CAP-015 | DI-006 | Wave 1 |
| BC-2.13.002 | Process backend requires explicit opt-in and emits loud runtime warning | P1 | CAP-015 | DI-006 | Wave 1 |
| BC-2.13.003 | Strict policy + non-enforcing backend returns Err(PolicyNotEnforceable) | P1 | CAP-015 | DI-006 | Wave 1 |
| BC-2.13.004 | All workspace file ops call canonicalize_beneath_root at access time — VP seed (NE-02) | P1 | CAP-015 | DI-007 | Wave 1 |
| BC-2.13.005 | Symlink that escapes workspace root returns Err(WorkspaceEscape) | P1 | CAP-015 | DI-007 | Wave 1 |
| BC-2.13.006 | macOS Seatbelt profile: deny-by-default with explicit allow rules (NE-16) | P1 | CAP-015 | DI-006 | Wave 1 |

### Batch 9 — Provider Conformance + Standard Tests (P1)
*9 BCs — SS.08 complete (Step-E addition: BC-2.08.009 authored from ADR-004 acceptance, architect feedback)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.08.001 | Chat model streaming completions conformance | P1 | CAP-009 | DI-011 | Wave 2 |
| BC-2.08.002 | Chat model tool-call round-trip conformance | P1 | CAP-009 | — | Wave 2 |
| BC-2.08.003 | Chat model structured output conformance | P1 | CAP-009 | — | Wave 2 |
| BC-2.08.004 | Chat model error-type fidelity conformance | P1 | CAP-009 | DI-014 | Wave 2 |
| BC-2.08.005 | Chat model token-usage accounting conformance | P1 | CAP-009 | — | Wave 2 |
| BC-2.08.006 | Standalone SDK crate split architecture (pregolya-\<provider\>-sdk + adapter) | P1 | CAP-009 | DI-008 | Wave 2 |
| BC-2.08.007 | Provider streaming interrupted by transport error surfaces Err(Timeout) or Err(Transport), not truncated success | P1 | CAP-009 | DI-009, DI-014 | Wave 2 |
| BC-2.08.008 | Eval score: arithmetic mean aggregation + JudgeResult::InfraError third outcome (NE-15) | P1 | CAP-011 | — | Wave 2 |
| BC-2.08.009 | Tool schema naming stability (snapshot test anchor) — **Step E** (ADR-004 snapshot obligation) | P1 | CAP-009 | — | Wave 2 |

### Batch 10 — MCP Adapter + Server Partial (P1)
*8 BCs — SS.09 + SS.12 partial*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.09.001 | MCP server tool discovery and registration at runtime | P1 | CAP-010 | — | Wave 2 |
| BC-2.09.002 | ToolInvocation routing to correct MCP server transport | P1 | CAP-010 | — | Wave 2 |
| BC-2.09.003 | Tool-result content treated as untrusted ingress (DI-012 applies) | P1 | CAP-010 | DI-012 | Wave 2 |
| BC-2.09.004 | MCP bare ToolException re-raise preserving type identity — R11 Red Gate | P1 | CAP-010 | DI-014 | Wave 2 |
| BC-2.09.005 | MultiServerMcpClient Holds No Live Connections (Red Gate — R11) | P1 | CAP-010 | DI-014 | Wave 2 |
| BC-2.12.001 | Thread resource CRUD (create, read, list, delete durable conversation history) | P1 | CAP-014 | — | Wave 1 |
| BC-2.12.002 | Assistant resource CRUD (named agent config with graph reference) | P1 | CAP-014 | — | Wave 1 |
| BC-2.12.003 | Run Creation and Execution Lifecycle (queued → in_progress → completed/failed/cancelled/summary_halt; interrupted is pausable/resumable) | P1 | CAP-014 | — | Wave 1 |

### Batch 11 — Server Cont. + Long-Horizon Memory (P1)
*7 BCs — SS.12 cont. + SS.15*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.12.004 | CronSchedule creation and proactive run execution | P1 | CAP-014 | — | Wave 1 |
| BC-2.12.005 | SecurityConfig::default() denies CORS; debug route gated on explicit opt-in key (NE-14) | P1 | CAP-014 | DI-013 | Wave 1 |
| BC-2.12.006 | IdempotencyStore / RateLimitStore / RunStore trait seams with durable backends (NE-08) | P1 | CAP-014 | — | Wave 1 |
| BC-2.12.007 | Streaming endpoint and unary endpoint drive same graph engine, same final answer | P1 | CAP-014 | DI-011 | Wave 1 |
| BC-2.15.001 | KV and vector memory persistence across threads (not per-checkpoint) | P1 | CAP-017 | — | Wave 1 |
| BC-2.15.002 | User/app/session tier isolation — user-private does not bleed across scopes | P1 | CAP-017 | — | Wave 1 |
| BC-2.15.003 | GDPR erasure removes all traces from all memory tiers | P1 | CAP-017 | — | Wave 1 |

### Batch 12 — Tool Retry + Formal Verification (P2)
*5 BCs — SS.16 + SS.17*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.16.001 | Per-tool retry policy keyed by tool_name (not args hash) (NE-09) | P1 | CAP-018 | — | Wave 1 |
| BC-2.16.002 | Finite global_limit non-None default for all retry policies (NE-09) | P1 | CAP-018 | — | Wave 1 |
| BC-2.16.003 | Circuit breaker trips after repeated failure; prevents infinite retry (NE-09) | P1 | CAP-018 | — | Wave 1 |
| BC-2.17.001 | Kani harness scope: BSP determinism VP + session tenancy VP + workspace confinement VP | P2 | CAP-019 | DI-001, DI-005, DI-007 | Phase 6 |
| BC-2.17.002 | cargo-fuzz targets: serialization round-trip (checkpoint) and graph-execution paths | P2 | CAP-019 | — | Phase 6 |

---

## Proc-Macro BCs (UNBLOCKED — ADR-004 + ADR-008 accepted)

ADR-004 (D5 gate) and ADR-008 are both accepted. The following BCs have been authored
as Phase-1b additions (Batch 13). They are included in the BC-INDEX plan total.

### Batch 13 — Proc-Macro Developer Ergonomics (P1, Phase-1b, ADR-004/ADR-008)
*3 BCs — SS.08 extension (pregolya-macros re-exported from pregolya-core)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.08.010 | `#[tool]` Attribute Macro: async fn → Tool implementor via schemars::JsonSchema | P1 | CAP-002 | DI-008 | Wave 1 |
| BC-2.08.011 | `#[entrypoint]` Attribute Macro: START edge auto-wiring for StateGraph | P1 | CAP-003 | — | Wave 1 |
| BC-2.08.012 | `#[task]` Attribute Macro: task registration boilerplate generation | P1 | CAP-003 | — | Wave 1 |

---

## D20 Integration BCs (UNBLOCKED — ADR-012 + domain-d-hermes-agent.md analysis)

D20 gap analysis on domain-d-hermes-agent.md produced 9 new BCs across SS.04, SS.08, SS.09,
SS.13, and SS.15. Split into two batches: Batch 14 (8 BCs, Wave 2) and Batch 15 (1 BC, Wave 1)
to respect the planning cap of 8 BCs per batch (cap exception would require Step-E doc, not done;
split by wave avoids exception).

### Batch 14 — D20 Integration: Provider Dialect + Failover + MCP Server + Self-Improvement Primitives (P1, Phase-1b, D20)
*9 BCs — SS.04/SS.08/SS.09/SS.15 extensions (Wave 2); +1 GAP-01/D-275 addition (BC-2.09.008)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.04.008 | FTS conversation search over checkpoint history (single-process; SQLite FTS5) | P1 | CAP-005 | DI-002, DI-008, DI-014 | Wave 2 |
| BC-2.08.013 | Pluggable tool-call dialect seam (ToolCallDialect; Hermes ChatML XML) | P1 | CAP-009 | DI-008, DI-014 | Wave 2 |
| BC-2.08.014 | Provider failover chain (ProviderFallbackPolicy; ordered fallback on 429/5xx/Auth) | P1 | CAP-009 | DI-008, DI-009, DI-010, DI-014 | Wave 2 |
| BC-2.09.006 | MCP server tool advertisement (tools/list; mcp::server) | P1 | CAP-021 | DI-008, DI-014 | Wave 2 |
| BC-2.09.007 | MCP server tool invocation (tools/call; external client executes registered tool) | P1 | CAP-021 | DI-008, DI-010, DI-014 | Wave 2 |
| BC-2.09.008 | StateGraph-as-MCP-Tool Wrapping (GraphAgentTool; mcp::graph_tool) | P1 | CAP-021 | DI-008, DI-010, DI-014 | Wave 2 |
| BC-2.15.004 | SkillStore registry — load-on-demand skill documents | P1 | CAP-020 | DI-008, DI-014 | Wave 2 |
| BC-2.15.005 | Guarded memory and skill writes (MemoryWriteGuard; E-MEMORY-007) | P1 | CAP-020 | DI-008, DI-012, DI-014 | Wave 2 |
| BC-2.15.006 | Frozen-snapshot context mutation — memory-sourced system-prompt content | P1 | CAP-020 | DI-002, DI-008, DI-014 | Wave 2 |

### Batch 15 — D20 Integration: Env-Sanitization Sandbox Boundary (P1, Phase-1b, D20; Wave 1)
*1 BC — SS.13 addendum (Wave 1 — unblocked by existing BC-2.13.001–006 Wave-1 foundation)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.13.007 | Environment variable sanitization at sandbox execution boundary | P1 | CAP-015 | DI-006, DI-008, DI-010 | Wave 1 |

---

## D21 Integration BCs (RETROACTIVE REGISTRATION — authored burst-222, 2026-07-21)

D21 ecosystem-parity expansion produced 21 new BCs across SS-18..22 (CAP-022..033).
These BCs were authored in burst-222 but not registered here at that time.
Split into three batches to respect the planning cap of 8 BCs per batch.

### Batch 16 — D21 Integration: Prompt Templates (P1, Phase-1b, D21)
*8 BCs — SS.18 + SS.19 partial (Wave 2)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.18.001 | PromptTemplate F-String Rendering, Partial Binding, Variable Detection, Strict-Undefined Guard | P1 | CAP-022 | DI-008, DI-014 | Wave 2 |
| BC-2.18.002 | ChatPromptTemplate Multi-Message Rendering, PromptValue Enum (String/Messages Variants, Send+Sync), and Runnable<HashMap<String,TemplateInput>,PromptValue> | P1 | CAP-022 | DI-008 | Wave 2 |
| BC-2.18.003 | MessagesPlaceholder Vec\<Message\> In-Place Expansion and FewShotPromptTemplate Composition | P1 | CAP-023 | DI-008 | Wave 2 |
| BC-2.18.004 | injection_guard — SystemMessage Slot with TrustLevel::Untrusted Raises E-TMPL-001 (Fail-Closed at Render Time) | P1 | CAP-022 | DI-008, DI-014 | Wave 2 |
| BC-2.18.005 | SlotTrustPolicy::TrustAll on SystemMessage Slot Raises E-TMPL-002 at Construction Time (Fail-Closed) | P1 | CAP-022 | DI-008, DI-014 | Wave 2 |
| BC-2.19.001 | LcSerializable Round-Trip — Serialize to Serialized::Constructor, Deserialize to Semantically Equivalent Value | P1 | CAP-024 | DI-008 | Wave 2 |
| BC-2.19.002 | lc_secrets() Credential Fields Stripped from kwargs Before Serialization and Constructor Dispatch | P1 | CAP-024 | DI-008, DI-010 | Wave 2 |
| BC-2.19.003 | Inventory-Based Type Registry — Link-Time Registration, Feature-Gated Partner Entries, OnceLock Allowlist | P1 | CAP-025 | DI-008 | Wave 2 |

### Batch 17 — D21 Integration: Serialization + Retrieval + Vector Store (P0/P1/P2, Phase-1b, D21)
*8 BCs — SS.19 cont. + SS.20 + SS.21 partial (Wave 2)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.19.004 | Legacy Namespace Remap — OLD_CORE_NAMESPACES_MAPPING Aliases Resolve to Canonical Constructors | P2 | CAP-025 | DI-008 | Wave 2 |
| BC-2.19.005 | Reviver Allowlist Containment — Unregistered Type Id Raises E-SRLZ-001 (Fail-Closed, VP-010 Kani Candidate) | P0 | CAP-025 | DI-008, DI-014 | Wave 2 |
| BC-2.19.006 | Langchain-Monolith Type Ids Return E-SRLZ-002 (Structured Error, Not Silent None or E-SRLZ-001) | P1 | CAP-025 | DI-008, DI-014 | Wave 2 |
| BC-2.20.001 | Retriever Trait — get_relevant_documents Async Dyn-Compatible; Document Carrier; Arc\<dyn Retriever\> Graph Seam | P1 | CAP-026 | DI-008, DI-012, DI-014 | Wave 2 |
| BC-2.20.002 | BoundaryType::RAGRetrieval Guardrail Covers All Retriever::get_relevant_documents Returns (DI-012 Coverage) | P0 | CAP-026 | DI-012, DI-014 | Wave 2 |
| BC-2.20.003 | VectorStoreRetriever — SearchType Enum; k / fetch_k / lambda_mult Configuration; as_retriever() | P1 | CAP-027 | DI-008 | Wave 2 |
| BC-2.21.001 | VectorStore Trait — Instance-Method Surface; VectorStoreFactory Sized-Bounded Separation; Dyn-Safety | P1 | CAP-028 | DI-008 | Wave 2 |
| BC-2.21.002 | InMemoryVectorStore — Arc\<dyn Embeddings\> DI; RwLock Interior Mutability; Vec\<f32\> Cosine | P1 | CAP-029 | DI-008 | Wave 2 |

### Batch 18 — D21 Integration: Vector Store Cont. + Embeddings (P0/P1, Phase-1b, D21)
*5 BCs — SS.21 cont. + SS.22 (Wave 2)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.21.003 | Zero-Norm Vector Guard — Vec\<f32\> Cosine Denominator Check Returns E-VS-001 Before Division (VP-009) | P0 | CAP-029 | DI-008, DI-014 | Wave 2 |
| BC-2.21.004 | MetadataFilter — Eq / Ne / In FilterClause; similarity_search_with_filter; #[non_exhaustive] | P1 | CAP-030 | DI-008, DI-014 | Wave 2 |
| BC-2.22.001 | Embeddings Trait — embed_documents Batch; embed_query; Dimensionality Contract → E-EMBED-001; VP-008 Proptest Seed | P1 | CAP-031 | DI-008, DI-014 | Wave 2 |
| BC-2.22.002 | EmbeddingsOpenAI — text-embedding models; OpenAiApiKey Redacted-Debug; reqwest/rustls-tls; Batch Partial-Failure | P1 | CAP-032 | DI-008, DI-009, DI-010, DI-014 | Wave 2 |
| BC-2.22.003 | EmbeddingsOllama — No API Key; POST /api/embed Preferred; use_legacy_endpoint Toggle; reqwest/rustls-tls | P1 | CAP-033 | DI-008, DI-009, DI-014 | Wave 2 |

---

## D23 Integration BCs (UNBLOCKED — ADR-018 approval hook + ADR-019 compaction + ADR-020 first-party tools)

D23 decisions produced 13 new BCs across SS-05/06/10 (extensions) and SS-23 (new subsystem).
BC-2.15.001/002/003 promoted P2→P1 in same decision band.
Split into two batches: Batch 19 (7 BCs, SS.05/06/10 extensions) and Batch 20 (6 BCs, SS.23 new).

### Batch 19 — D23 Integration: PreToolCallHook + Compaction Events + Budget Extension (P1, Phase-1b, D23; Wave 1)
*7 BCs — SS.05/SS.06/SS.10 extensions (Wave 1)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.05.007 | PreToolCallHook Dispatch — pre_invoke Contract; Approve/Deny/Edit/PendingHumanApproval; Fail-Closed Deny (VP-011 Kani Seed) | P1 | CAP-034 | DI-014 | Wave 1 |
| BC-2.05.008 | Skip-Hook-on-Resume Invariant — ToolApprovalRequest Checkpoint Persistence; No Re-Invocation of pre_invoke | P1 | CAP-034 | DI-014 | Wave 1 |
| BC-2.06.004 | `tool_approval_request` StreamEvent (Event 13) — Payload; Emission Timing; Causal Ordering Before Interrupt | P1 | CAP-034 | DI-014 | Wave 1 |
| BC-2.06.005 | `tool_approval_resolved` StreamEvent (Event 14) — Payload; Emission on Command(resume=…); Decision Outcome | P1 | CAP-034 | DI-014 | Wave 1 |
| BC-2.06.006 | `compaction_event` StreamEvent (Event 15) — Payload; Emission After Compaction Completes; Trigger Variant | P1 | CAP-035 | DI-014 | Wave 1 |
| BC-2.10.005 | CompactionTrigger Configuration — Disabled/OnWatermark/OnMessageCount/OnTokenCount; Watermark Arithmetic (VP-012 Kani Seed) | P1 | CAP-035 | DI-014 | Wave 1 |
| BC-2.10.006 | Compaction Execution — ConversationSnapshot from FTS; Mid-Run Window REPLACEMENT; CompactionEvent → EvidenceJournal | P1 | CAP-035 | DI-014 | Wave 1 |

### Batch 20 — D23 Integration: First-Party Tool Library (P1, Phase-1b, D23; Wave 1)
*6 BCs — SS.23 new subsystem (pregolya-tools, Wave 1)*

| BC ID | Title | Priority | CAP | DI | Wave |
|-------|-------|----------|-----|----|------|
| BC-2.23.001 | ReadFileTool — PathGuard-Confined File Read; max_bytes 1 MiB Limit; E-TOOLS-001/002/008 | P1 | CAP-036 | DI-014 | Wave 1 |
| BC-2.23.002 | WriteFileTool — PathGuard-Confined Atomic Write; High ActionRisk; No Auto-Retry; E-TOOLS-001/008 | P1 | CAP-036 | DI-014 | Wave 1 |
| BC-2.23.003 | EditFileTool — Exact-Match String Replace; E-TOOLS-003 on No-Match; Opt-In Fuzzy Fallback (EditConfig::fuzzy_threshold); Conditional Retry Safe; E-TOOLS-001/003/008 | P1 | CAP-036 | DI-014 | Wave 1 |
| BC-2.23.004 | ListDirTool — PathGuard-Confined Directory Listing; ReadOnly; E-TOOLS-001/008; DirEntry Struct | P1 | CAP-036 | DI-014 | Wave 1 |
| BC-2.23.005 | BashTool — Sandboxed Shell Execution; Non-Lowerable Medium Risk Floor; BashOutput; 256 KiB Output Cap; 30 s Timeout; E-TOOLS-004/007 (VP-013 Kani Seed) | P1 | CAP-037 | DI-014, DI-015 | Wave 1 |
| BC-2.23.006 | GrepTool — In-Process Regex Search; Linear-Time `regex` Crate; max_results 100 Cap; Hermetic; PathGuard Scope; E-TOOLS-001/008/009 | P1 | CAP-038 | DI-014 | Wave 1 |

---

## Authoring Guidelines for Sub-Burst Agents

1. **Subsystem ID (RESOLVED):** BCs were authored with `subsystem: SS-TBD`; ARCH-INDEX SS-NN IDs were assigned by architect at Phase 1b (2026-07-14) and backfilled into all BC files — see BC-INDEX. New BCs must use a real SS-NN ID from ARCH-INDEX Subsystem Registry, not SS-TBD.
2. **Capability Anchor Justification:** Each BC Traceability section must include:
   `| Capability Anchor Justification | CAP-NNN ("<exact title>") per capabilities.md §CAP-NNN |`
3. **DI citations:** Every BC that enforces a domain invariant must list it in the Traceability
   section under "L2 Domain Invariants".
4. **Test vectors:** Minimum 3 per BC (one happy-path, one edge-case, one error-case).
5. **Edge cases:** Minimum 1 per BC (EC-001); use domain-spec edge-cases.md for DEC-NNN anchors.
6. **VP seeds:** BCs that are Kani VP seeds (BC-2.03.001, BC-2.04.006, BC-2.13.004) must include
   a Verification Properties table with the VP description and method (Kani).
7. **Red Gate tests:** BCs for R8/R10/R11 (BC-2.07.002, BC-2.02.003-004, BC-2.09.004-005)
   must note "Red Gate test required — must compile and FAIL before implementation begins."
8. **Origin:** `origin: greenfield` for all BCs in BC-INDEX (no brownfield extraction).
9. **Lifecycle:** `lifecycle_status: active`, `introduced: v1.0.0-greenfield`. **Status:** `status: active` — a BC is `active` once integrated into BC-INDEX; version bumps do NOT reset this field to `draft`.
10. **File path:** `.factory/specs/behavioral-contracts/ss-NN/BC-S.SS.NNN.md` (SS-NN from ARCH-INDEX Subsystem Registry)
11. **Governance: integrated-into-index ⇒ `status: active` (all spec artifacts).**
    - A spec artifact is integrated once its authoritative index accepts it: BC files → BC-INDEX, domain-spec shards → L2-INDEX, architecture sections → ARCH-INDEX, prd.md and prd-supplements → prd.md supplements list, ADRs → ARCH-INDEX ADR log (stay `accepted`), product-brief → product review (stays `approved`).
    - VP files are the **only** exception: they may remain `status: draft` while Kani/integration harnesses are pre-implementation, provided VP-INDEX.md is `status: active` and lists the VP.
    - This rule is generalized from F-P6-03 (ADV-P1D-PASS-6 fix). Source of truth: ADV-P1D-PASS-8.md §F-P8-04.

> **SS-23 BC Title Error-Code Enumeration Policy (F-P146-02, burst-247, 2026-07-24):**
> For BC titles in subsystem SS-23 (pregolya-tools), error codes in the title enumerate ALL and ONLY *raised* error codes — codes that appear as `Err(PregolyaError{code: "E-TOOLS-NNN"})` returns. Ok-path payload flags (E-TOOLS-005 `BashOutput.truncated`, E-TOOLS-006 `GrepResult.capped`) are NOT raised errors and MUST NOT appear in title enumerations. The trailing error-code section uses slash-separated format without spaces: `E-TOOLS-NNN/NNN/NNN`. Inline contextual error-code references (e.g., "E-TOOLS-003 on No-Match") are permitted where they describe the trigger condition; a complete trailing enumeration of all raised codes must also be present for machine extractability. Policy adjudication rationale: (1) listing a payload flag while omitting a real raised error is semantically inverted; (2) exhaustive enumeration of raised codes enables grepping BC titles to find all BCs that raise a given code; (3) consistent with BC-2.23.005 pre-existing exhaustive-enumeration pattern extended to all 6 SS-23 BCs. Applied burst-247: BC-2.23.001→`E-TOOLS-001/002/008`, BC-2.23.002→`E-TOOLS-001/008`, BC-2.23.003→`E-TOOLS-001/003/008`, BC-2.23.004→`E-TOOLS-001/008`, BC-2.23.005→`E-TOOLS-004/007` (E-TOOLS-005 payload flag removed from title), BC-2.23.006→`E-TOOLS-001/008/009` (E-TOOLS-006 payload flag removed, E-TOOLS-008/009 added).

> **"VP-NNN candidate" Label Policy (F-P171a-16, burst-273, 2026-07-25; F-P172a-19 disambiguation, burst-274-B, 2026-07-26):**
> `"VP-NNN candidate"` is acceptable PO/BA shorthand for a seeded Verification Property that has not yet received a permanent VP-INDEX entry. It signals authoring intent to the architect without implying the VP is formally assigned or active. Usage rules: (1) In the BC §Verification Properties table, `"VP-NNN candidate"` (e.g., `"VP-013 candidate"`, `"VP-HITL-13 candidate"`) indicates that this BC is the intended source for a VP to be minted at architect phase. (2) In the BC frontmatter `vp_seed: true` field, the companion `vp_id` field MAY be set to the candidate ID. (3) Once the architect assigns the VP in VP-INDEX, the "candidate" qualifier is dropped — the BC §Verification Properties table and `vp_id` frontmatter field are updated to the confirmed VP-NNN ID. (4) A "VP-NNN candidate" label does NOT grant gate #36 VP↔BC RED-GATE PARITY exemption — the candidate label is a precursor, not a substitute for a VP-INDEX entry.
>
> **Disambiguation — tier-descriptor qualifiers (F-P172a-19):** Rule (3) above applies ONLY when the full label form is `"VP-NNN candidate"` (bare) — i.e., the entire parenthetical conveys "ID not yet in VP-INDEX." When the parenthetical instead describes a **verification tier or priority** — e.g., `"VP-013 (Kani P1 candidate)"` or `"VP-NNN (<tier> qualifier)"` — the VP-NNN ID IS already assigned in VP-INDEX and the qualifier is informative tier metadata, NOT an ID-candidate signal. In that case: (a) rule (3) does NOT apply — the qualifier is retained as useful tier context, not dropped; (b) the gate #36 VP↔BC RED-GATE PARITY check applies normally (VP-NNN is an assigned VP with a VP-INDEX entry). Example: BC-2.23.005 row `"VP-013 (Kani P1 candidate)"` is COMPLIANT — VP-013 is assigned in VP-INDEX (gate #13 census) and the parenthetical conveys Kani P1 priority tier, not ID-candidate status. If unsure whether a parenthetical is a tier descriptor or ID-candidate signal, check VP-INDEX: if the ID exists, it is tier metadata; if it does not exist, it is ID-candidate shorthand and rule (3) applies on assignment.
>
> Source: F-P171a-16 adjudication (process-gap — option (a) "acceptable shorthand"); 40-site cosmetic removal would be disproportionate to the lack of any correctness issue. F-P172a-19 disambiguation (burst-274-B).

> **`## VP Anchors` Section Content Convention (P2A-052 F-052-01, 2026-08-25):**
> The `## VP Anchors` section in any BC file contains VP identifiers ONLY — either a canonical `VP-NNN` (assigned in VP-INDEX) or a BC-local `VP-<suffix>` identifier — or the literal `None` when the BC has no Kani VP seed (i.e., the BC is integration/unit-tested and §Verification Properties states no VP is required). It MUST NEVER contain a story ID such as `S-N.NN`. Story coverage lives exclusively in `## Story Anchor`. Placing a story ID in `## VP Anchors` is a template-fill artifact: the two sections are adjacent in the BC template, and authoring agents occasionally copy the story ID into both. Finding root cause (P2A-052): six BCs (BC-2.09.001/002/003 and BC-2.12.001/002/003) contained their story ID in `## VP Anchors` instead of a VP identifier or `None`.

12. **Lifecycle-arrow census gate (added P12):** Any BC or supplement that contains a Run
    state-machine lifecycle arrow MUST use one of the two canonical forms:
    - *Title/prose* form: `queued → in_progress → completed/failed/cancelled/summary_halt; interrupted is pausable/resumable`
    - *Diagram/arrow* form: `queued → in_progress → completed | failed | cancelled | summary_halt; in_progress ⇄ interrupted (resume via POST .../resume)`
    Terminal set = {completed, failed, cancelled, summary_halt}. `summary_halt` is the
    budget-summarize terminal state reached via `in_progress → summary_halt` on
    `OnCeiling::Summarize` (BC-2.10.003 PC8(c)(d)); it carries the summarize model response
    as output; `completed_at` is set; it is not cancellable (already terminal — HTTP 409 per
    BC-2.12.003 PC12); it is directly deletable without a prior cancel step; it emits `RunEnd`.
    `interrupted` MUST NOT appear as a terminal state in any lifecycle arrow. The single
    authority for the state machine is BC-2.12.003 PC7-PC9. Run
    `grep -rn "in_progress →\|in_progress→\|→ interrupted\|⇄" .factory/specs/`
    and verify every hit: (a) shows `interrupted` as pausable/resumable, and (b) lists all
    four terminal states `completed | failed | cancelled | summary_halt`. Additionally verify
    no hit enumerates only `completed | failed | cancelled` (three-member set) as the full
    terminal set — every such hit must gain `summary_halt`. Source of truth:
    ADV-P1D-PASS-12.md §F-P12-01; F-P117-01 adjudication (fix burst 120, BC-2.12.003);
    F-P118-01 four-member canonicalization (fix burst 121).
13. **Anchor-matrix census gate (added P16 — standing gate, subsumes all prior per-axis checks; widened P40 — five-way):**
    After any BC authoring burst, run the full anchor-matrix census across all BCs in BC-INDEX × 6 axes
    {CAP, DI, NE, R (R-NNN/R8-10-11 aliases), ADR, registered-VP}. For each axis, perform a
    **five-way consistency check**: BC body Traceability tables ↔ BC-INDEX columns (NE Anchors,
    DI Anchors, Cap, VP, RG) ↔ PRD §2 tables + §7 RTM Source column + §9 NE Disposition Table ↔
    authoritative registry (capabilities shards / invariants.md / PRD §9 / risks.md /
    ARCH-INDEX ADR registry / VP-INDEX) ↔ **bc-authoring-plan batch-table anchor columns
    (CAP, DI)**. Body wins unless provably wrong; fix index/RTM/batch-table to match body.
    The ne_anchor and ne_coverage frontmatter fields are OPTIONAL-LEGACY — BC body
    Traceability (NE anchor row) + BC-INDEX NE Anchors column are the canonical carriers; do
    NOT add ne_anchor/ne_coverage frontmatter to new BCs.
    **Widening rationale (OBS-P40-1, ADV-P1D-PASS-40):** The bc-authoring-plan batch-table
    CAP/DI columns were absent from the carrier set through Pass 39. This allowed the batch-table
    DI cell for BC-2.08.007 to show `DI-014` while all other four carriers showed `DI-009, DI-014`
    (motivating instance: F-P40-01). The batch-table is consumed by sub-burst authoring agents and
    must match BC-INDEX on every anchor-affecting burst to prevent forward propagation of drift.
    Source of truth: ADV-P1D-PASS-16.md §F-P16-01 + anchor-matrix reconciliation;
    ADV-P1D-PASS-40 §OBS-P40-1 (widening).
    **VP uniqueness sub-check (added P93 — OBS-P93-01; regex widened P172a — F-P172a-09):** The registered-VP axis above checks
    BC VP Anchors ↔ VP-INDEX, but does NOT detect the same per-BC VP ID being defined
    in two different BC bodies with different semantics (a cross-BC collision). After any BC
    authoring or VP assignment burst, run the following census across all BC bodies:
    ```
    grep -rh "^| VP-" .factory/specs/behavioral-contracts/ --include="*.md" \
      --exclude="BC-INDEX.md" \
      | sed 's/^| //' \
      | grep -oE "^VP-([0-9]{3}\b|[A-Z0-9.]+(-[A-Z0-9]+)*-[0-9A-Z]+)" \
      | sort | uniq -d
    ```
    **Semantics (DEFINITION vs CITATION — critical disambiguation):**
    - This census extracts only the **primary (first-column) VP ID** from each `^| VP-` row.
      That first-column ID is the VP being DEFINED in that BC.
    - Registered VPs (VP-001..VP-013) are legitimately CO-CITED by multiple BCs — they
      appear in secondary positions of rows like `| VP-2.23.001-A (VP-003 reuse) | ...` and
      in BC-INDEX.md (excluded by `--exclude`). These are NOT collisions.
    - A TRUE collision is when the SAME per-BC VP ID appears as the primary (first-column)
      ID in two different BC bodies with different Property text.
    Expected output: **empty** (zero primary per-BC VP ID is the primary definition in two
    different BC bodies). Any non-empty output is a collision — resolution: keep the older
    (lower phase) definition as canonical; renumber the newer definition to the next free
    sequential ID in the same domain (e.g., VP-BUDGET-07 if VP-BUDGET-06 is already used).
    Update both the VP table row and the VP Anchors section in the affected BC, then re-run
    the census.
    **Regex coverage (three forms):**
    - `[0-9]{3}\b` → `VP-001` through `VP-013` (numeric registered form)
    - `[A-Z0-9.]+(-[A-Z0-9]+)*-[0-9A-Z]+` → `VP-2.04.001-A` (per-BC dotted form) AND
      `VP-BSP-DET-01`, `VP-BUDGET-05`, `VP-BC201001-01` (alpha-domain and BC-keyed forms)
    **Prior regex** `VP-[A-Z0-9]+(-[A-Z0-9]+)*-[0-9]+` missed `VP-001..VP-013` (numeric)
    and `VP-S.SS.NNN-X` (dots in segment), making the census blind to those two forms.
    Motivating instance: F-P93-04 — BC-2.10.003 and BC-2.10.004 both defined VP-BUDGET-05
    with different semantics (Summarize path vs HITL interrupt path). Resolved 2026-07-17:
    BC-2.10.004's VP-BUDGET-05 (Phase 1) kept canonical; BC-2.10.003's VP-BUDGET-05
    renumbered → VP-BUDGET-07 (next free after VP-BUDGET-06).
14. **Harness-fn registry + executable-string census gate (added P17 — standing gate):**
    VP-INDEX.md `harness_fn` column is the authoritative registry for Phase-6 `cargo kani --harness`
    invocation identifiers. Any change to a VP harness function name MUST update VP-INDEX.md
    `harness_fn` first, then propagate to: VP-NNN.md harness skeleton fn name, nfr-catalog.md
    any `cargo kani --harness` command string, BC body Kani VP Seed notes, and
    verification-architecture.md harness sketches. After any such change, run the full
    executable-string census: `grep -rn "cargo kani --harness" .factory/specs/` and verify
    every cited harness name matches a `harness_fn` value in VP-INDEX.md (or is a placeholder
    `<harness_name>`). Source of truth: ADV-P1D-PASS-17.md §F-P17-01 + executable-string census.
15. **Shared-type identifier census gate (added P18 — standing gate):**
    After any BC authoring or fix burst, run the shared-type identifier census across all BC code
    snippets and prd-supplements (excluding interface-definitions.md, which is architect scope).
    For every pregolya type in the ubiquitous-language reconciliation table plus the core
    shared types (Message, ContentBlock, AiMessage, AiMessageChunk, PregolyaError, Component,
    Category, RetryHint, CheckpointSaver, RunnableConfig, CheckpointTuple, RunStatus, MemoryStore,
    BudgetPolicy, GuardrailHook, ProvenanceTag): assert single spelling per type across all BC
    code snippets and prd-supplements. Canonical spellings are the pregolya names per
    ubiquitous-language-server.md reconciliation table (D17 fidelity: CheckpointSaver not
    CheckpointStore; RunnableConfig not RunConfig; AiMessage not AIMessage). Retired spellings
    (CheckpointStore, RunConfig, BaseCheckpointSaver, AIMessage in Rust contexts) must have 0
    occurrences. Census command (updated P20):
    `grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage\|\bCheckpointer\b" .factory/specs/`
    Added retired spelling: bare `\bCheckpointer\b` (canonical name is `CheckpointSaver`).
    Note: compound identifiers where `Checkpointer` has no left `\b` (e.g.,
    `InterruptWithoutCheckpointer`) are self-excluded by the regex — no explicit exemption needed.
    Exemptions (do NOT count as violations): (a) Python semport cross-references (cite semport
    source file); (b) census-rule text itself in bc-authoring-plan.md; (c) reconciliation table
    LEFT column in ubiquitous-language-server.md (intentionally documents LangChain Python names).
    Source of truth: ADV-P1D-PASS-19.md §F-P19-02 (scope widened from BC+prd-supplements to full
    .factory/specs/); ADV-P1D-PASS-18.md §F-P18-01 + shared-type identifier census.
    `\bCheckpointer\b` widened: ADV-P1D-PASS-20.md §F-P20-03.

16. **E-code↔variant-name consistency census gate (added P20 — standing gate; widened P34 — F-P34-03):**
    After any BC authoring or fix burst that introduces, renames, or retires an error code,
    run the variant-name consistency census. For every `E-<COMP>-NNN <VariantName>` or
    `E-<COMP>-NNN: <VariantName>` pairing found in any BC body, assert that `<VariantName>`
    is the canonical variant name for `E-<COMP>-NNN` in error-taxonomy.md. A code referenced
    with the wrong variant name is a high-severity drift that misleads implementers.

    **Census commands (BOTH forms required — F-P34-03):**

    Form 1 (space-delimited: `E-XXX-NNN VariantName`):
    `grep -hrn "E-[A-Z]*-[0-9]\{3\} [A-Z][A-Za-z]*" .factory/specs/behavioral-contracts/ | grep -v "~~" | grep -oE "E-[A-Z]+-[0-9]{3} [A-Z][A-Za-z]+" | sort -u`

    Form 2 (colon-delimited: `E-XXX-NNN: VariantName`):
    `grep -hrn "E-[A-Z]*-[0-9]\{3\}: [A-Z][A-Za-z]*" .factory/specs/behavioral-contracts/ | grep -v "~~" | grep -oE "E-[A-Z]+-[0-9]{3}: [A-Z][A-Za-z]+" | sort -u`

    **Cross-check requirement (collision detection):** For each extracted pairing (either form),
    look up the code in error-taxonomy.md and verify (a) the variant name matches the taxonomy
    row exactly, AND (b) the code is not already assigned a DIFFERENT variant name elsewhere in
    the taxonomy (collision detection, not just name drift). A code appearing in a BC with a
    variant name that differs from the taxonomy's canonical variant is a HIGH-severity finding.
    Category names (POLICY, VAL, TIMEOUT, DURABILITY, TOOL, etc.) appearing after a code in a
    markdown table row are false positives — filter these out by confirming the word is not a
    known category code from the Error Categories table.

    Codes used without a variant name (e.g., bare `E-CHKPT-001`) are permitted — only named
    pairings are checked. Retired codes (~~strikethrough~~ in taxonomy) must not appear in
    non-~~strikethrough~~ BC text.

    Source of truth: ADV-P1D-PASS-20.md §F-P20-03. Widening rationale: ADV-P1D-PASS-34
    §F-P34-03 — the original space-only regex missed `E-RETRY-003: InvalidRetryLimit` in
    BC-2.16.001.md for 33 passes, allowing a live collision to persist undetected.

17. **HTTP endpoint census gate (added P23 — standing gate):**
    After any BC authoring or fix burst that adds, moves, or renames an HTTP endpoint path,
    run the full endpoint census. Two sub-checks:

    **A. URL-scheme consistency (RUNS = thread-nested; SCHEDULES = flat):**
    Canon: ALL run CRUD paths are `/threads/{thread_id}/runs/...`. The ONLY flat run path
    is the cross-thread aggregate `GET /runs?schedule_id={cron_id}` (BC-2.12.004). All
    schedule CRUD paths are `/schedules/{cron_id}` (flat). Source of truth: F-P23-01;
    interface-definitions.md §Runs and §Cron Schedules; api-surface.md §pregolya-server HTTP Endpoints.

    Census command:
    `grep -rn "POST /runs\b\|GET /runs/\|DELETE /runs/\|PATCH /runs/" .factory/specs/ | grep -v "schedule_id" | grep -v "threads/"` — output must be EMPTY (zero hits).
    Any non-empty output means a flat run path escaped the fix.

    **B. Path × citing-docs × scheme-verdict table:** After any endpoint change, verify
    the following canonical table still holds (all rows PASS):

    | Path (canonical) | Citing Docs | Scheme Verdict |
    |-----------------|-------------|---------------|
    | `POST /threads/{thread_id}/runs` | interface-definitions.md, api-surface.md, prd.md §3, BC-2.12.003 | PASS (thread-nested) |
    | `GET /threads/{thread_id}/runs` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
    | `GET /threads/{thread_id}/runs/{run_id}` | interface-definitions.md, api-surface.md, BC-2.12.003, BC-2.12.007, BC-2.05.006 | PASS |
    | `GET /threads/{thread_id}/runs/{run_id}/stream` | interface-definitions.md, api-surface.md, BC-2.12.007 | PASS |
    | `POST /threads/{thread_id}/runs/{run_id}/resume` | interface-definitions.md, api-surface.md, BC-2.05.004, BC-2.05.005, BC-2.05.006, edge-cases.md | PASS |
    | `POST /threads/{thread_id}/runs/{run_id}/cancel` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
    | `DELETE /threads/{thread_id}/runs/{run_id}` | interface-definitions.md, api-surface.md, BC-2.12.003 | PASS |
    | `POST /schedules` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS (flat) |
    | `GET /schedules/{cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
    | `PATCH /schedules/{cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
    | `DELETE /schedules/{cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS |
    | `GET /runs?schedule_id={cron_id}` | interface-definitions.md, api-surface.md, BC-2.12.004 | PASS (flat; cross-thread aggregate only) |

    **Endpoint-count invariant (OBS-P33-2, ADV-P1D-PASS-33 [process-gap]):** Total
    pregolya-server HTTP endpoints = **26** (Threads 7 + Assistants 7 + Runs 7 +
    Cron 4 + aggregate 1). Recount confirmed from interface-definitions.md §Threads /
    §Assistants / §Runs / §Cron Schedules tables. Any burst that adds or removes an
    endpoint MUST update this count in the same burst.

    **C. HTTP status-code↔E-code census (schema discipline):** For each BC that states
    an HTTP status code for a specific E-xxx-NNN error, assert the code maps correctly
    to the interface-definitions.md §HTTP Status Codes table.

    **Positive-coverage assertion (added P25 — [process-gap] fix):** Every PASS row in
    this census table MUST be grep-verifiable in interface-definitions.md §HTTP Status Codes.
    A census row marked PASS against a status code or E-code not present in the interface
    table is a false PASS — the census is inert. Census command:
    `grep -n "^| 201\|^| 202\|^| 204\|^| 400\|^| 401\|^| 403\|^| 404\|^| 409\|^| 422\|^| 429\|^| 500\|^| 502\|^| 503\|^| 504" .factory/specs/prd-supplements/interface-definitions.md`
    Every status code appearing in the census table below must appear as a row in that grep output.
    Source: ADV-P1D-PASS-25 F-P25-07 [process-gap].

    | HTTP Code | E-code + Variant | Citing BCs (sample) | Verdict |
    |-----------|-----------------|---------------------|---------|
    | 400 | E-CRON-002 InvalidCronExpression | BC-2.12.004 EC-002 | PASS (added 400 row in iface-def P25) |
    | 404 | E-SERVER-002 RunNotFound | BC-2.12.003 EC-001, TV-003, TV-004 | PASS |
    | 404 | E-SERVER-003 ThreadNotFound | BC-2.12.003 PC2, EC-001 | PASS |
    | 404 | E-SERVER-006 ScheduleNotFound | BC-2.12.004 EC-005 | PASS |
    | 409 | E-SERVER-012 ConcurrentRun | BC-2.12.003 EC-002 | PASS |
    | 409 | E-SERVER-015 RunAlreadyExecuting | BC-2.12.007 TV-006 | PASS |
    | 422 | E-GRAPH-002 NoActiveInterrupt | BC-2.05.005 TV-003 | PASS (F-P27-01: E-GRAPH-002 now enumerated in 422 row explicitly as POLICY→422 per-endpoint override; BC-2.14.002 PC3 9th override; wildcard citation in EC-001 and TV-003 replaced with concrete override citation; prior wildcard "E-GRAPH-* → 422" retired by P26 OBS-1 narrowing) |
    | 422 | E-SERVER-009 (AssistantNotFound in run body) | BC-2.12.003 PC3 | PASS (context-dependent: 422 in run creation body; 404 at direct assistant lookup) |
    | 422 | E-SERVER-011 (GraphNotFound in assistant body) | BC-2.12.002 EC-005 | PASS |
    | 429 | E-PROV-001 | interface-definitions.md | PASS |
    | 500 | E-SERVER-014 RunStoreFailed | BC-2.12.006 EC-004 | PASS |
    | 204 | DELETE success (no body) | BC-2.12.004 PC5, EC-005 | PASS (204 row added to iface-def P25) |
    | 201 | POST /schedules | BC-2.12.004 TV-001 | PASS (201 row added to iface-def P25) |
    | 202 | POST /threads/{id}/runs | BC-2.12.003 PC5 | PASS |
    | 503 | E-SERVER-016 IdempotencyLockTimeout | BC-2.12.006 EC-002 | PASS (503 row added to iface-def P25; per-endpoint override over Timeout→504) |

    Source of truth: ADV-P1D-PASS-23.md §F-P23-01; ADV-P1D-PASS-25 §F-P25-07; interface-definitions.md §HTTP Status Codes.

18. **Wire-object field-set coherence census gate (added P24 — standing gate):**
    After any BC authoring or fix burst that introduces, modifies, or removes a field on a
    wire-visible object (Run, Thread, Assistant, CronSchedule, Resume request, or any new
    server resource), run the three-way field-set census: `interface-definitions.md` JSON schema
    ↔ `entities-server.md` entity fields ↔ every BC postcondition / test vector that returns or
    consumes the object. All three must agree; the BCs are authoritative.

    **Canonical field-set table (as of F-P24-01):**

    | Object | Field | schema (iface-def) | entity (entities-server) | BC PC/TV | Verdict |
    |--------|-------|-------------------|--------------------------|----------|---------|
    | Run | run_id | required | YES | PC5, PC13 | PASS |
    | Run | thread_id | required | YES | PC5, PC13 | PASS |
    | Run | assistant_id | required | YES | PC5, PC13 | PASS |
    | Run | status | required | YES (RunStatus) | PC5, PC13 | PASS |
    | Run | created_at | required | YES | PC5, PC13 | PASS |
    | Run | updated_at | required (added F-P24-01) | YES | PC13 | PASS |
    | Run | completed_at | nullable (added F-P24-01) | YES (Option<Timestamp>) | PC13 | PASS |
    | Run | output | conditional (status=completed) | YES (Option<Value>) | PC15 | PASS |
    | Run | error | conditional (status=failed) | implicit via PregolyaError | PC16 | PASS |
    | Run | interrupt | conditional (status=interrupted) | Interrupt entity (separate) | PC9 | PASS (flattened) |
    | Thread | thread_id | no JSON schema | YES | PC5 | NOTE: no explicit JSON schema; entity + BC suffice |
    | Thread | metadata | — | YES | PC1 | PASS |
    | Thread | created_at | — | YES | PC5 | PASS |
    | Thread | updated_at | — | YES | PC5 | PASS |
    | Thread | status | — | YES (ThreadStatus; added F-P24-01) | PC5 | PASS |
    | Assistant | assistant_id | no JSON schema | YES | PC4 | PASS |
    | Assistant | graph_id | — | YES | PC4 | PASS |
    | Assistant | config | — | YES | PC4 | PASS |
    | Assistant | context | — | YES (Option<Value>; added F-P24-01) | PC4 | PASS |
    | Assistant | metadata | — | YES | PC4 | PASS |
    | Assistant | name | — | YES (Option<String>; added F-P24-01) | PC4 | PASS |
    | Assistant | description | — | YES (Option<String>; added F-P24-01) | PC4 | PASS |
    | Assistant | version | — | YES (u32; added F-P24-01) | PC4 | PASS |
    | Assistant | created_at | — | YES (added F-P24-01) | PC4 | PASS |
    | CronSchedule | cron_id | path param `{cron_id}` | YES | PC1, PC3 | PASS |
    | CronSchedule | assistant_id | — | YES | PC1 | PASS |
    | CronSchedule | schedule | — | YES (CronExpression) | PC1 | PASS |
    | CronSchedule | config | — | YES | PC4 (input) | PASS |
    | CronSchedule | enabled | GET response | YES | PC4 | PASS |
    | CronSchedule | last_fired_at | GET response | YES (Option<Timestamp>; added F-P24-01) | PC3 | PASS |
    | ResumeRequest | resume_value | required | N/A (request body) | BC-2.05.004 | PASS |
    | ResumeRequest | approver_id | optional | N/A | BC-2.05.004 | PASS |

    **Census trigger:** any change to a BC postcondition or test vector that adds, renames, or
    removes a field on a wire-visible object MUST propagate to (a) the `interface-definitions.md`
    JSON schema for that object (if one exists), (b) the `entities-server.md` entity field list,
    and (c) all other BCs that return or consume that same object. Three-way consistency is
    required before the fix burst closes.

    **Sub-field coherence extension (added P25 — F-P25-06):** The three-way census applies to
    EMBEDDED sub-objects (e.g., Run.interrupt, Run.error) with the same discipline as top-level
    objects. For each embedded object with a `properties` block in the interface-definitions.md
    JSON schema, every named sub-field must be coherent across (a) the schema `properties`, (b)
    the entity or BC type that defines the sub-object shape, and (c) all BCs that emit or consume
    the parent object in the interrupted/error state. Known embedded sub-objects subject to this rule:
    Run.interrupt (fields: interrupt_id, node_name, super_step, value, action_risk, action, context,
    scratchpad — authority: BC-2.05.001, BC-2.05.006, entities-server.md §Interrupt);
    Run.error (fields: type, title, detail, extensions — authority: BC-2.14.002, RFC-7807).
    Sub-field drift between the schema and the authoritative BC is a wire-breaking defect.
    Source: ADV-P1D-PASS-25 §F-P25-06.

    **Quick check command (Run object schema):**
    `grep -n "updated_at\|completed_at" .factory/specs/prd-supplements/interface-definitions.md .factory/specs/domain-spec/entities-server.md .factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md`
    Both `updated_at` and `completed_at` must appear in all three files.

    Source of truth: ADV-P1D-PASS-24.md §NEW CLASS: Wire-Object Field-Set Coherence.

19. **Retired-identifier residue grep (added P26 — standing gate):**
    Whenever a rename canon is set (method name, field name, type identifier, route path),
    the fix burst MUST grep the ENTIRE `.factory/specs/` tree — including
    `architecture/decisions/` ADRs AND all BC test vectors — for the retired identifier
    and drain every hit before the burst closes. A changelog or census-rule mention is
    not a hit; only live (non-~~strikethrough~~, non-changelog, non-census-rule) occurrences
    are violations.

    **Current retired-identifier list** (add to this list whenever a new rename is canonized):
    | Retired Identifier | Canonical Replacement | Canon Set In |
    |--------------------|----------------------|-------------|
    | `to_problem_detail` | `to_problem` | F-P25-04 (api-surface.md); F-P26-02 (ADR-010) |
    | `risk_tier` | `action_risk` | F-P25-06 (Run.interrupt sub-field); F-P26-03 (BC-2.05.001 TV-005) |
    | `node_id` (in interrupt context) | `node_name` | F-P25-06 (Run.interrupt sub-field) |
    | `{schedule_id}` (flat run path param) | thread-nested `runs/` paths | F-P23-01 |
    | `CheckpointStore` | `CheckpointSaver` | P18 shared-type census |
    | `RunConfig` | `RunnableConfig` | P18 shared-type census |
    | `BaseCheckpointSaver` | `CheckpointSaver` | P18 shared-type census |
    | `AIMessage` (Rust context) | `AiMessage` | P18 shared-type census |
    | bare `\bCheckpointer\b` | `CheckpointSaver` | P20 shared-type census |
    | `X-Debug-Key` header | `Authorization: Bearer <key>` | F-P26-04 |
    | `/debug/*` path | `/_debug` | F-P26-04 |
    | `risk_tier.rs` (source file path) | `action_risk.rs` | F-P27-06 (BC-2.05.006 Architecture Anchor) |
    | `node_delta` (SSE event token / description) | `node_stream` | F-P29-03 (BC-2.12.007, interface-definitions.md); BC-2.06.001 is the streaming taxonomy authority |
    | `RunStarted`, `NodeStarted`, `ToolStarted`, `StepStarted`, `RunEnded`, `NodeEnded`, `ToolEnded`, `StepEnded` (Rust enum variant names in L3 architecture artifacts) | `RunStart`, `NodeStart`, `ToolStart`, `StepStart`, `RunEnd`, `NodeEnd`, `ToolEnd`, `StepEnd` (imperative) | F-P29-04 (ADR-006, module-decomposition.md); BC-2.06.001 is the authority; **NOTE: events.md (L2 domain spec) uses past-tense PascalCase (RunStarted, InterruptRaised, etc.) as DDD domain event names — this is correct and NOT retired; the census below excludes domain-spec/** |
    | `run_started`, `node_started` (snake_case SSE wire tokens) | `run_start`, `node_start` (imperative) | F-P29-04 (ADR-006); wire tokens follow variant names |
    | `IngressSource` (ProvenanceTag field type) | `BoundaryType` (ToolResult \| RAGRetrieval \| MemoryIngress) | F-P58-03 (entities-server.md + ubiquitous-language-server.md ss-11 fix) |
    | `source_type` field on ProvenanceTag | `boundary_type` | F-P58-03 |
    | `tool_name`, `invocation_id`, `timestamp` fields on ProvenanceTag | removed — ProvenanceTag fields are now `boundary_type`, `ingress_id`, `sequence_position` | F-P58-03 |
    | `GuardrailAction` (enum type name) | `GuardrailResult` | F-P57-01 (iface-def) + F-P58-03 (entities fully retired) |
    | `Accept`, `Reject(reason)`, `Redact(sanitized)` (GuardrailAction variants as guardrail API) | `Pass`, `Fail{reason,severity}`, `Transform{new_content}` (GuardrailResult variants) | F-P57-01 + F-P58-03 |
    | `BudgetDecision` (enum type name) | `PolicyDecision` | F-P60-01 (interface-definitions.md §BudgetPolicy + bc-authoring-plan gate #31 registry; ADR-009 §Decision confirms same rename) |
    | `BudgetContext` (context param type name) | `RunContext` | F-P61-02 (interface-definitions.md §BudgetPolicy context param; gate #31 census table — near-name blindspot: corpus already named RunContext in BC-2.10.001 precondition 3 with identical contents) |

    Census command: `grep -rn "to_problem_detail\|risk_tier\|X-Debug-Key\|node_delta\|IngressSource\|GuardrailAction\b\|BudgetDecision\|BudgetContext\|CheckpointStore\b\|RunConfig\b\|BaseCheckpointSaver\b\|AIMessage\b\|\bCheckpointer\b" .factory/specs/ | grep -v "bc-authoring-plan\|~~\|changelog\|Census command\|retired.*list\|Retired Identifier\|action_risk.rs\|architecture/\|domain-spec/\|ADV-P1D-PASS"` — output must be ZERO live occurrences. Exclusions: bc-authoring-plan.md (registry document); architecture/ (architect scope — ADR-009 manages BudgetDecision rename in that domain); domain-spec/ (Python→Rust name-mapping tables in ubiquitous-language-server.md and related files use the retired names as translation labels, not live Rust type usages); `ADV-P1D-PASS` (YAML frontmatter changelog list items — always reference ADV-P1D-PASS-NN; these are audit trail, not live uses; exempted per gate #19 "A changelog or census-rule mention is not a hit" rule). **AIMessage operator note:** `AIMessage` hits in `**Reference:**` annotations that cite Python/semport source files are Python-context names, not Rust type usages, and are not violations; operator must verify context on any remaining AIMessage hit.
    Census command (past-tense StreamEvent variants — L3 architecture and BC artifacts only): `grep -rn "RunStarted\|NodeStarted\|ToolStarted\|StepStarted\|run_started\|node_started" .factory/specs/ | grep -v "bc-authoring-plan\|domain-spec/\|~~\|changelog\|Census command\|retired.*list\|Retired Identifier"` — output must be ZERO live occurrences.
    **Coverage-closure note (F-P74-01/OBS-P74-A, adjudication D18-P74-A):** The five shared-type names (`CheckpointStore`, `RunConfig`, `BaseCheckpointSaver`, `AIMessage`-Rust-context, `Checkpointer`) were absent from the prior census pattern. Gate #15 explicitly excludes interface-definitions.md from retired-identifier checks; the shared-type names were not covered by any other census. This gap allowed a `CheckpointStore` residue to survive in interface-definitions.md (architect-scope twin of F-P74-01) and in BC-2.04.008.md Description (F-P74-01, fixed in pass-74 PO burst). Gate #19's whole-tree traversal now covers interface-definitions.md on the retired-spelling axis, closing the gap that gate #15's exclusion left open.
    Source: ADV-P1D-PASS-26 §F-P26-02, §F-P26-03, §F-P26-04; ADV-P1D-PASS-27 §F-P27-06; ADV-P1D-PASS-29 §F-P29-03, §F-P29-04; ADV-P1D-PASS-74 §F-P74-01/OBS-P74-A (shared-type names extension, D18-P74-A).

20. **AUTH/POLICY/INTERNAL category re-sweep (added P26 — standing gate; widened P69 — F-P69-01/OBS-P69-1):**
    Any edit to a 401/403/409/500 table row in interface-definitions.md §HTTP Status Codes,
    OR any change to an E-code's `category` field in error-taxonomy.md,
    OR any table edit involving a range expression or INTERNAL-category code placement,
    MUST trigger a full category→status census for ALL error codes in the affected categories
    across ALL namespaces (E-CORE, E-GRAPH, E-CHKPT, E-SERVER, E-PROV, E-MCP, E-SPLIT,
    E-SBXD, E-RETRY, E-CRON, E-MEMORY, E-BUDGET, E-TMPL, E-SRLZ, E-VS, E-EMBED — not just
    the namespace being edited; D21 added E-TMPL/E-SRLZ/E-VS/E-EMBED per ADR-010 §Component Axis Expansion (D21)).

    The census must verify:
    1. Every AUTH-category code: maps to 401 (categorical) or has a documented per-endpoint override in BC-2.14.002 PC3.
    2. Every POLICY-category code: maps to 403 (categorical) or has a documented per-endpoint override.
    3. Every CONCURRENCY-category code: maps to 409 (categorical) or has a documented per-endpoint override.
    4. No code appears in two conflicting rows of the HTTP status table without an explicit disambiguation note.
    5. **(Added P69 — INTERNAL axis)** Every INTERNAL-category code: maps to the 500 row OR
       carries a documented individual omission note OR is covered by a named blanket omission
       group (e.g., E-SBXD-*, E-RETRY-*, etc.). No INTERNAL-category code may appear in a
       VAL-labeled row or in any row whose description asserts "categorical VAL→400" without
       an explicit INTERNAL override/omission note. INTERNAL→500 is the categorical fallback;
       library-layer INTERNAL codes that never surface as direct HTTP responses use individual
       omission notes following the pattern of E-CORE-004, E-CORE-006, and E-CORE-007.

    **Range-expansion rule (added P69 — F-P69-01):** Any range expression in the HTTP Status
    Codes table rows — written as "X through Y", "X..Y", or similar contiguous shorthand
    (e.g., "E-CORE-001 through E-CORE-005") — MUST be mentally expanded to its full member
    set and each member's category verified against error-taxonomy.md on every table edit.
    A range that sweeps in a code whose category does not match the row's label (e.g., an
    INTERNAL code swept into a VAL→400 row) is a silent category mismatch undetectable by
    membership-only census checks. Prefer explicit code enumerations over ranges in all status
    table rows. Where shorthand notation is used (e.g., "E-CHKPT-001, -002, -003"), the
    expansion must be verified but need not be rewritten if all members share the row's
    category label; any skip in the sequence (e.g., -001, -002, -004 skipping -003) must be
    verified to confirm the skipped code is intentionally absent (retired, different category,
    or omission-noted).

    **Motivating instance (F-P69-01, ADV-P1D-PASS-69):** The 400 row's "E-CORE-001 through
    E-CORE-005" range silently included E-CORE-004 (INTERNAL, not VAL). E-CORE-004 is a
    library-layer pipe-composition failure (BC-2.01.004 PC5) that never surfaces as a direct
    HTTP 400 response. The range was corrected to explicit enumeration "E-CORE-001, E-CORE-002,
    E-CORE-003, E-CORE-005" and E-CORE-004 was given an individual omission note mirroring
    E-CORE-007. This class of bug is undetectable by a categorical census that checks only
    "is code X in the table?" without checking "does code X's category match the row label?".

    Source: ADV-P1D-PASS-26 §F-P26-05 (original gate trigger — E-PROV-004 orphan discovery);
    ADV-P1D-PASS-69 §OBS-P69-1 (INTERNAL axis + range-expansion rule widening).

21. **HTTP status-code table edit → census re-run trigger (added P27 — standing gate):** [process-gap]
    Any burst that edits the interface-definitions.md §HTTP Status Codes table (row add,
    row remove, row narrowing, or row widening) MUST re-run the full §Authoring Guidelines for Sub-Burst Agents (guideline #17-C)
    (guideline #17 above) IN THE SAME BURST and update every affected census row before
    the burst closes.

    **Trigger conditions:**
    - Adding a new E-code to any row → add a census row for that code
    - Removing an E-code from a row → retire the census row (mark RETIRED with reason)
    - Narrowing a wildcard to an enumerated list → update every census row that cited the wildcard
    - Widening an enumerated list → add census rows for newly included codes
    - Changing a row's description without changing codes → no census update needed (description-only)

    **Rationale:** ADV-P1D-PASS-27 §OBS-P27-2 found that the P26 OBS-1 narrowing of the 422
    wildcard (E-GRAPH-* → enumerated list) left the §Authoring Guidelines for Sub-Burst Agents (guideline #17-C) row for E-GRAPH-002 citing
    the retired wildcard as its PASS evidence — making the census row a false PASS. The census
    must be re-run whenever the table it verifies against changes.

    **Deferred process improvement (machine-enforcement recommendation, OBS-P27-2):** The
    orchestrator should consider a CI/hook implementation: a grep script that re-runs the
    §Authoring Guidelines for Sub-Burst Agents (guideline #17-C) after any commit touching interface-definitions.md §HTTP Status Codes and
    fails if any census row cites a wildcard pattern that no longer exists in the table row.
    This would make the census machine-enforceable rather than relying on burst discipline.
    Log at cycle close for v1.1 planning.

    **Sub-check: Cross-row routing-enumeration completeness (added P67 — OBS-P67-1):**
    The §HTTP Status Codes table contains rows whose descriptions explicitly enumerate codes
    that "go to the X row" or "see the Y row." These inter-row routing enumerations must
    be kept in sync with the target row's actual contents. Whenever any code is added to
    or removed from a row, every OTHER row's explanatory enumeration that references that
    row must be updated to reflect the change.

    **Trigger:** Any code added to or removed from a status row → scan all other rows for
    "go to the X row" / "see the Y row" language that names the modified row; diff the
    inline enumeration against the target row's current code list; fix any discrepancy in
    the same burst.

    **Census procedure:**
    1. Extract all inter-row routing enumerations: text of the form "(E-XXX-NNN, ...)" that
       appears in one row's description with an explicit "go to the Y row" or "see the Y row"
       annotation.
    2. For each such enumeration, extract the target row's live code list.
    3. Diff: codes in target row but absent from the enumeration → add. Codes in the
       enumeration but absent from the target row → remove.
    4. If the enumeration uses "..." or a wildcard, ensure the wildcard is still accurate
       (a wildcard that was narrowed to an enumerated list per OBS-1 must remain enumerated).

    **Motivating instance (F-P67-01, ADV-P1D-PASS-67):** The 422 row enumeration
    "(E-CHKPT-001, -002, -003, -004, -006) go to the 500 row" omitted E-CHKPT-007, which
    IS in the 500 row. E-CHKPT-007 was added to the 500 row at v2.11 (pass-56-completion)
    without updating the 422 row's sibling enumeration. The gap survived 10 passes because
    gate #21 checked code→row membership (§Authoring Guidelines for Sub-Burst Agents (guideline #17-C)) but not inter-row routing
    enumeration completeness.

    Source: ADV-P1D-PASS-27 §OBS-P27-2 [process-gap]; ADV-P1D-PASS-67 §OBS-P67-1 [process-gap].

22. **RetryHint coherence gate — RETRYHINT COHERENCE (added P28 — standing gate):**
    Any burst that creates or edits a per-code catalog row in error-taxonomy.md OR edits
    the Error Categories table (adding/removing a category or changing a Default RetryHint)
    MUST verify RetryHint coherence before the burst closes:

    1. **Per-code row check:** For every new or edited E-code row that has an explicit
       `RetryHint` column value, confirm whether that value matches or diverges from the
       category's "Default RetryHint" in the category table.
    2. **Divergence requires BC-anchored rationale:** If the per-code RetryHint diverges
       from the category default, the per-code row (or an inline correction note) MUST
       include a rationale citing the specific BC (e.g., "BC-2.16.003 circuit-breaker
       cool-down semantics override POLICY Never default"). A bare divergence with no
       rationale is a gate failure.
    3. **Category-table edit propagation:** If the Default RetryHint for a category is
       changed, re-audit ALL per-code rows in that category to confirm that:
       (a) any previously-compliant rows are still compliant under the new default, and
       (b) any new divergences are documented with rationale.
    4. **No silent convergence:** Do NOT silently change a per-code RetryHint to match
       the default without confirming the semantics. The per-code value may be intentionally
       different (e.g., a DURABILITY code that is non-recoverable by retry should keep
       `Never` even if the category default is `Maybe`).

    **Known intentional divergences (as of ADV-P1D-PASS-28):**

    | Error Code | Category | Default RetryHint | Per-Code RetryHint | Rationale |
    |-----------|----------|-------------------|--------------------|-----------|
    | E-RETRY-003 | POLICY | Never | `Later(<reset_timeout>)` | BC-2.16.003: circuit breaker has a defined reset horizon; the cool-down period makes Later semantics correct (retrying after reset_timeout will likely succeed) |
    | E-CRON-003 | POLICY | Never | `Later` | BC-2.12.004: schedule queue transiently full; next firing cycle will likely have capacity |
    | E-MEMORY-002 | DURABILITY | Maybe | `Never` | BC-2.15.001: storage-full is non-recoverable by retry without operator intervention (capacity must be freed or expanded) |
    | E-MEMORY-005 | DURABILITY | Maybe | `Never` | BC-2.15.003: GDPR erasure partial failure rolled back; retry without fixing the underlying cause will produce the same partial failure |
    | E-BUDGET-002 | DURABILITY | Maybe | `Never` | BC-2.10.002: budget journal write failure is non-recoverable by retry if the storage backend has failed; journaling must be restored by operator |
    | E-MCP-005 | TRANSPORT | Later | `Never` | BC-2.09.006: socket bind failure (EADDRINUSE, EACCES) requires operator configuration change — the same bind address/port will fail immediately on retry; `Later` would be misleading (D20 sub-burst 2) |

    **Rationale:** ADV-P1D-PASS-28 §F-P28-01 found that 5 codes have per-code RetryHints
    diverging from their category defaults with no precedence rule documenting which value
    is authoritative. E-MCP-005 added as 6th divergence in D20 sub-burst 2. The fix (F-P28-01) relabeled the column to "Default RetryHint" and
    added a precedence rule; this gate ensures future divergences are explicitly justified.
    Source: ADV-P1D-PASS-28 §F-P28-01 [process-gap].

    **ADV-P1D-PASS-29 update (F-P29-02):** E-CRON-003 (ScheduleQueueFull) was present in
    the known-intentional-divergences table above but was NOT cited in the blockquote at
    error-taxonomy.md §RetryHint precedence rule. Fixed: blockquote now explicitly cites all
    5 divergent codes. The blockquote divergence list and this table must remain in sync.

23. **Streaming-event-name coherence gate — STREAMING-EVENT-NAME COHERENCE (added P29 — standing gate):**
    [process-gap] Any burst that creates or edits streaming event names in ANY of the following
    artifacts: `domain-spec/events.md`, `domain-spec/capabilities-p0.md`, `BC-2.06.001.md` (the
    StreamEvent enum authority), `architecture/decisions/ADR-006-streaming-event-taxonomy.md`,
    `prd-supplements/interface-definitions.md`, `BC-2.12.007.md`, `architecture/module-decomposition.md`
    MUST perform a three-way coherence check before the burst closes:

    1. **L2 source (events.md, capabilities-p0.md):** Note the domain event names and any
       stream-event labels. Domain event section headers (RunStarted, InterruptRaised, etc.)
       use DDD past-tense PascalCase — this is intentional and NOT a violation.
    2. **BC-2.06.001 StreamEvent enum (authoritative):** Variant names must be imperative
       (RunStart, NodeStream, ToolEnd, etc.); wire tokens must be snake_case imperative
       (run_start, node_stream, tool_end, etc.).
    3. **Downstream consumers** (ADR-006, interface-definitions.md, BC-2.12.007,
       module-decomposition.md): Must use the exact variant names and wire tokens from
       BC-2.06.001. Any description field listing event tokens must use node_stream not
       node_delta; RunStart not RunStarted.
    4. **D13 wire posture:** ADR-006 and any wire-format description must state
       pregolya-native wire format. LangChain Python `.astream_events()` v2 compat
       claims are a gate failure (they contradict D13).
    5. **Census commands:**
       - `grep -rn "node_delta" .factory/specs/ | grep -v "bc-authoring-plan\|~~\|changelog\|retired.*list\|Census"` → zero live hits
       - `grep -rn "RunStarted\|NodeStarted\|run_started" .factory/specs/ | grep -v "bc-authoring-plan\|domain-spec/\|~~\|changelog\|retired.*list\|Census"` → zero live hits
       - `grep -n "NodeStream\|ToolStream" .factory/specs/architecture/decisions/ADR-006-streaming-event-taxonomy.md` → present
       - `grep -rn "astream_events" .factory/specs/architecture/ | grep -v "native\|D13\|NOT\|no.*compat"` → zero live compat claims

    **Anti-fix note (OBS-P30-2, ADV-P1D-PASS-30 — DURABLE):** `domain-spec/events.md` legitimately omits `run_stream`, `step_start`, `step_end`, and similar wire-taxonomy labels. `events.md` documents domain processing-stages by DDD convention, not the exhaustive wire-event taxonomy; gate #23 step 1 explicitly permits representative subsets in L2. Future passes MUST NOT "fix" `events.md` into duplicating BC-2.06.001's `StreamEvent` authority — BC-2.06.001 is the single wire-taxonomy source of truth. Any attempt to add `run_stream`, `step_start`, or `step_end` labels to `events.md` on the grounds that they are "missing from L2" is incorrect; the omission is intentional.

    Source: ADV-P1D-PASS-29 §F-P29-03, §F-P29-04, §F-P29-05, §OBS-P29-2 [process-gap]; ADV-P1D-PASS-30 §OBS-P30-2.

24. **Pagination coherence census gate — PAGINATION COHERENCE (added P31 — standing gate):**

    Any burst that adds or edits a list/aggregate GET endpoint in `interface-definitions.md`
    MUST perform this census before closing:

    1. **Canonical convention check:** The endpoint row cites F-P31-01 or carries an explicit
       documented exemption with rationale. The canonical convention is: `limit` (default 10,
       max 100; values > 100 silently clamped to 100), `offset` (default 0), results ordered
       `created_at` descending (or endpoint-specific ordering explicitly declared).

    2. **Anchor BC match:** The anchor BC named in the endpoint row's "BC Anchor" column must
       have a matching postcondition that declares the same limit/offset/ordering semantics as
       the interface row. Drift between the interface row and the anchor BC is a gate failure.

    3. **Out-of-range uniformity:** All list endpoints must use the same out-of-range canon:
       **clamp** (not reject). If any BC uses reject-with-E-CORE instead of clamp, that BC
       and this gate note must be updated together. The current canon is clamp (decided
       ADV-P1D-PASS-31 §F-P31-01 — no prior BC stated reject, so clamp was adopted).

    4. **Census commands:**
       - `grep -n "limit" .factory/specs/prd-supplements/interface-definitions.md | grep "GET"` →
         all list endpoint rows carry pagination or explicit exemption.
       - `grep -n "limit\|offset" .factory/specs/behavioral-contracts/ss-12/BC-2.12.004.md` →
         PC7 present with default 10 / max 100 / offset / created_at DESC.
       - `grep -n "limit\|offset" .factory/specs/behavioral-contracts/ss-12/BC-2.12.003.md` →
         PC18 includes limit/offset/clamped/created_at DESC.
       - `grep -n "limit\|offset" .factory/specs/behavioral-contracts/ss-12/BC-2.12.001.md` →
         PC8 includes default 10 / max 100 / values > 100 clamped / offset default 0
         (F-P34-01, ADV-P1D-PASS-34); PC17 includes default 10 / max 100 / clamped / offset.
       - `grep -n "limit\|offset" .factory/specs/behavioral-contracts/ss-12/BC-2.12.002.md` →
         PC21 includes limit (default 10 / max 100 / clamped); PC22 returns
         { assistants: [Assistant], total_count: u64 }; PC23 declares created_at DESC
         (list-assistants anchor, F-P33-01); PC20 present with /versions pagination
         (limit 10/100/clamped/offset 0/version ASC exemption, F-P32-03).

    **Exemption pattern:** If an endpoint legitimately cannot support pagination (e.g., it
    returns a single resource, not a list), document the exemption in the row's description
    with rationale. Endpoints that *do* return arrays but omit pagination are a gate failure.

    Source: ADV-P1D-PASS-31 §F-P31-01 (pagination/query-param coherence — new class).

25. **Summary-arithmetic + criticality-sibling coherence census gate — SUMMARY-ARITHMETIC
    + CRITICALITY-SIBLING COHERENCE (added P32 — standing gate [process-gap]):**

    Any burst that edits a table containing a summary/count section OR edits any
    module-criticality document MUST perform this two-part census before closing:

    **Part A — Summary arithmetic:**
    Any edit to a table that has an associated Summary or Classification Summary section
    (containing module counts, row counts, percentages, or self-summing totals) MUST:
    1. Recount the table rows in the SAME burst — do not trust existing Summary cells.
    2. Reconcile EVERY summary cell (each tier count AND the total) against the row recount.
    3. Update ALL mismatched cells in the same burst. Deferring reconciliation is a gate
       failure.

    Trigger: any row add, row remove, row re-tier, count edit, or percentage edit in a
    table that has a downstream Summary section.

    **Part B — Criticality-sibling coherence (widened P37 — OBS-P37-1 [process-gap]):**
    Any burst that adds, removes, or re-tiers a module in ANY criticality-bearing document MUST
    propagate the change to ALL THREE sibling documents in the same burst:
    1. `.factory/specs/module-criticality.md` (arch registry — authoritative source of truth post-1b)
    2. `.factory/specs/architecture/module-decomposition.md` (derived — per-module Criticality column
       AND structurally-privileged module-tier headings, e.g., `## <module-name> — <TIER>`)
    3. `.factory/specs/architecture/verification-coverage-matrix.md` (derived — per-tier summary row
       AND per-module table Criticality column)

    Note: `.factory/specs/prd-supplements/module-criticality.md` (PO registry) is **superseded**
    (status: superseded; 22-module pre-D21/D23 view; frozen — do not sync). Routing implementation
    decisions to it is prohibited per its SUPERSEDED banner. It is excluded from this gate.

    Never update any one of these three without verifying all three in the same burst.

    After editing:
    - Apply **Part A** (table/summary reconciliation) to every document you touch.
    - Apply **Gate #26** (Structurally-Privileged-Line Canon Check) to catch stale tier claims
      in H1/H2/H3 headings (e.g., `## pregolya-macros — MEDIUM` heading in
      module-decomposition.md is a **hypothetical example** — the heading is structurally
      privileged and must match the actual tier in the arch registry for that module).
    - Run the **Tier agreement census** below across all three documents.

    **Census commands:**
    - Registry rows: count rows per tier in Module Classification table (arch) → must equal arch
      Summary cells.
    - **Derived-doc module check — BIDIRECTIONAL (F-P172b-05/burst-275; Class A/B
      split/burst-275B):** The census iterates the DECOMPOSITION domain, not the registry domain.
      The exempt set is split into two named classes with distinct arithmetic roles.

      **Exempt Class A — non-row definitions-only (NOT in universe; not in any count):**
      `core::context_mutation`, `core::write_guard`, `core::guardrail`, `core::action_risk`

      These four modules have NO table row in `module-decomposition.md` — they appear only as
      prose definitions notes inside the pregolya-core crate sections. They are NOT members of
      the row universe and NEVER enter any row count or the exempt_count arithmetic. The `—`
      reciprocal assertion does NOT apply (no Criticality cell exists to check). The INVERSE
      assertion applies instead: a Class A module MUST NOT appear as a table row in
      `module-decomposition.md`; if one gains a row, that is a HIGH-severity finding requiring
      architect re-classification into Class B or into the tiered set.

      **Class A census command — BLOCKING (F-P173-310/burst-276):** Enumerate all four Class A
      names against decomposition table rows in every burst that runs the Part B census:
      ```bash
      grep -E "^\| (core::context_mutation|core::write_guard|core::guardrail|core::action_risk) " \
        .factory/specs/architecture/module-decomposition.md \
        | grep -v "^|---"
      ```
      Expected: zero rows. A non-empty result means a Class A module has gained a table row —
      HIGH-severity finding. Record the count as `class_a_row_count` in the census sextuple
      (see Positive-Coverage Assertion below); the blocking identity is
      **`class_a_row_count == 0`**.

      **Exempt Class B — exempt table rows (`exempt_count` source; counted in universe):**
      `core::documents`, `memory::skills`

      These two modules ARE table rows in `module-decomposition.md` with Criticality `—`. They
      ARE members of the row universe and counted in `decomposition_total_rows`. The `—`
      reciprocal assertion applies to exactly these: each MUST carry Criticality `—`; a Class B
      module carrying any tier value is a HIGH-severity finding. `exempt_count` is defined as
      `|Class B|` and MUST be obtained by COUNTING rows with Criticality `—` in
      `module-decomposition.md`, NOT by taking the length of the Class B name list. The count and
      the list must be independently derived and then cross-checked; if they disagree (count ≠
      list length, or a counted `—` row is not in the list), that disagreement is itself a
      HIGH-severity finding.

      (Class A / Class B split rationale: definitions-only modules have no algorithmic failure
      modes AND no table row — the `—` reciprocal assertion cannot apply. Routing-overlay modules
      also lack execution-business-logic but DO have a structural decomposition row. Flattening
      these two classes into one exempt list made exempt_count = 6, causing the blocking identity
      to give 68 − 6 = 62 ≠ 68 on a correct census — the motivating defect for burst-275B. See
      gate #32 carrier 4 for full rationale and adjudication records.)

      **Decomposition→Registry (absence class):** For each module in `module-decomposition.md`
      with a non-`—` Criticality value (these are `decomposition_tiered_rows`), a row MUST exist
      in `module-criticality.md` (arch registry). If absent, that is a HIGH-severity finding.
      Class A modules never appear in this domain (no table row); Class B modules carry `—`
      Criticality and are also not in this domain.

      **Registry→Decomposition (tier-divergence class):** For each module row in
      `module-criticality.md`, verify the assigned tier matches the Criticality column in
      `module-decomposition.md`. Any mismatch is a HIGH-severity finding regardless of class.
    - Tier-summary row check: cross-check the verification-coverage-matrix.md §Coverage by Criticality Tier summary row
      (CRITICAL/HIGH/MEDIUM/LOW counts and total) against the arch-registry
      (`.factory/specs/module-criticality.md`) §Classification Summary — recompute from the
      arch-registry; do not trust a hardcoded example.
      **PRECONDITION — BLOCKED until F-P173-812 (architect Wave B):** The per-row tier recount
      from the `verification-coverage-matrix.md` per-module table is blocked. That table's
      columns are `Module | Crate | Kani | proptest | fuzz | Integration | Notes` — there is
      NO Criticality or Tier column. Until the architect adds the `Tier` column per F-P173-812,
      tier counts are cross-checked solely by comparing the verification-coverage-matrix.md §Coverage by Criticality Tier summary
      row against the arch-registry §Classification Summary. Attempting to derive tier counts
      from the per-module table requires either a non-existent column lookup (impossible) or
      mirroring from a sibling document — both prohibited by this gate.
    - **Positive-Coverage Assertion (OBS-P172b-B/burst-275; Class A/B fix/burst-275B;
      registry-rows-vs-distinct-modules/burst-275C) — BLOCKING:** Every burst that runs this
      census MUST record the following sextuple in the burst's Form A frontmatter changelog entry
      for this file:

      `(decomposition_per_section_vector, decomposition_total_rows, decomposition_tiered_rows, exempt_count, class_a_row_count, registry_rows, roll_up_row_count, registry_census_rows, registry_distinct_modules, matched_rows)`

      Where (all members independently recomputed from named artifacts in THIS burst):
      - `decomposition_per_section_vector`: per-section breakdown of ALL tiered rows, e.g.,
        `core:8 graph:8 checkpoint:8 server:5 sandbox:6 splitters:2 eval:1 mcp:5 memory:6
        macros:3 core-D21:4 prompts:4 vectorstores:5 provider-embeddings:2 tools:4`. Must be
        stated inline; the sum MUST equal `decomposition_tiered_rows`. A dropped or added section
        causes the sum to misfire — this is the per-section sum identity (see blocking identity 0
        below).
      - `decomposition_total_rows`: ALL table rows in `module-decomposition.md` (Class B `—` rows
        included; Class A rows NOT included — they have no table rows)
      - `decomposition_tiered_rows`: rows with non-`—` Criticality (Class B `—` rows excluded)
      - `exempt_count`: rows with `—` Criticality = |Class B|; MUST be obtained by COUNTING rows
        whose Criticality cell is `—`, not by taking the Class B name list length; cross-check
        count against Class B list — if they disagree, that is a HIGH-severity finding
      - `class_a_row_count`: count of Class A module names (`core::context_mutation`,
        `core::write_guard`, `core::guardrail`, `core::action_risk`) appearing as table rows in
        `module-decomposition.md`; derived by the Class A census command above; MUST equal 0
      - `registry_rows`: total table ROWS in `module-criticality.md` §Module Classification,
        counting ALL rows unconditionally — including crate-level roll-up rows and multi-aspect
        rows for the same module name (one module may appear on multiple rows with distinct
        Qualifiers). This is the unconditional row total; never reduced by any exclusion.
      - `roll_up_row_count`: count of rows explicitly labeled ROLL-UP in the Qualifier column;
        MUST be derived by counting those rows, not by list length
      - `registry_census_rows`: `registry_rows − roll_up_row_count`; this is the intersection
        denominator (non-roll-up rows that are candidates for module-name matching)
      - `registry_distinct_modules`: count of DISTINCT Module cell values in §Module
        Classification; a module appearing on multiple rows (multi-aspect pattern) is counted once
      - `matched_rows`: cardinality of the SET INTERSECTION
        `{decomposition_tiered_module_names} ∩ {registry_Module_cell_values}`.
        MUST be computed by enumerating each tiered decomposition module name and testing whether
        it appears in the set of registry Module cell values. The DIFFERENCE SET
        `{decomposition_tiered_module_names} \ {registry_Module_cell_values}` MUST be reported
        inline and MUST be empty. Prose-asserting the count without the difference set is
        PROHIBITED — see rule 5 below.

      **Blocking identity 0 (per-section sum):**
      `sum(decomposition_per_section_vector) == decomposition_tiered_rows`
      A dropped or added section causes this sum to diverge even when `decomposition_total_rows`
      is computed correctly. State the per-section vector inline so the sum is reproducible by
      any reader. Recompute fresh each burst.

      **Blocking identity 1 (universe total):**
      `decomposition_total_rows == decomposition_tiered_rows + exempt_count`
      Detects: arithmetic slips and malformed Criticality cells (a `—` row miscounted as tiered,
      or vice versa). Does NOT detect Class A gaining a table row (use `class_a_row_count == 0`
      identity), Class B Criticality drift (use Class B membership assertion), or section-level
      row additions/drops (use per-section sum identity 0). Recompute fresh each burst — never
      copy forward prior values.

      **Blocking identity 1a (Class A absence — F-P173-310):**
      `class_a_row_count == 0`
      Derived by the Class A census command above; a non-zero value means a Class A module has
      gained a table row and must be re-classified by the architect.

      **Blocking identity 1b (Class B membership — set equality, not count equality):**
      The set `{rows in module-decomposition.md with Criticality —}` MUST equal exactly
      `{core::documents, memory::skills}`. A `—` row outside this named set is a HIGH-severity
      finding requiring architect adjudication.

      **Blocking identity 2 (matching completeness):**
      `matched_rows == decomposition_tiered_rows`
      (Every tiered decomposition module must appear as a registry Module cell — zero gaps
      tolerated. The difference set must be explicitly reported and empty.)

      **Blocking identity 3 (registry uniqueness over composite key):**
      For every pair of rows `(row_i, row_j)` where `row_i.Module == row_j.Module`, the composite
      key MUST differ: `(row_i.Module, row_i.Qualifier) != (row_j.Module, row_j.Qualifier)`.
      A duplicate `(Module, Qualifier)` pair is a HIGH-severity finding. `matched_rows` is
      computed against the Module cell (not the composite key), so one decomposition module
      correctly covers multiple registry rows when they carry the same Module name with distinct
      Qualifiers (multi-aspect pattern, e.g., `core::serializable` with a CRITICAL reviver-
      allowlist row and a HIGH round-trip row).

      **Identity 3 census command — genuinely falsifiable (F-P173-304; required derivation,
      not assertion):**
      Extract all `(Module, Qualifier)` composite key pairs from `§Module Classification`,
      then pipe through `sort | uniq -d`. Any duplicate pair is printed inline — the output
      is self-revealing. Empty output = PASSES; non-empty output = duplicate printed = FAILS LOUDLY.
      ```bash
      awk '/^## Module Classification/{f=1;next} /^## /{f=0} f' .factory/specs/module-criticality.md \
        | grep '^| ' | grep -v '^|---' \
        | awk -F'|' '
          NR==1 {
            for (i=2; i<=NF; i++) {
              h=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", h)
              if (h == "Module")    mc=i
              if (h == "Qualifier") qc=i
            }
            next
          }
          { m=$mc; q=$qc
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", m)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", q)
            print m "|" q
          }' | sort | uniq -d
      # Expected: empty output (zero duplicate (Module, Qualifier) pairs).
      # Non-empty output prints the offending pair inline — identity 3 FAILS.
      ```

      **Identity 3 evaluation (burst-276-Wave-C):** census sextuple
      `(decomposition_total_rows=71, decomposition_tiered_rows=69, exempt_count=2,
      registry_rows=77, registry_distinct_modules=76, matched_rows=69)`;
      both difference sets empty. Command output: empty — zero duplicate (Module, Qualifier)
      pairs found. The 1-row gap (registry_rows=77 vs registry_distinct_modules=76) is the
      single multi-aspect row: `core::serializable` appears twice — once with Qualifier
      `reviver-allowlist CRITICAL` and once with Qualifier `round-trip HIGH`. These are
      DISTINCT Qualifier strings; identity 3 PASSES.

      **Four-failure-mode falsifiability argument (F-P173-304):**

      (a) **A module counted in both tiers — same (Module, Qualifier) pair on two rows:**
      Identity 3 DETECTS this. `sort | uniq -d` prints the duplicate composite key inline.
      Trigger example: two rows each with `core::serializable | reviver-allowlist CRITICAL`
      — command outputs `core::serializable|reviver-allowlist CRITICAL`; identity 3 FAILS LOUDLY.

      (b) **A module counted in neither — present in decomposition, absent from registry:**
      Identity 3 CANNOT detect this. A missing module has no composite key to duplicate; the
      command output stays empty regardless. This failure mode belongs to identity 2: the
      required difference set `{decomposition_tiered_module_names} \ {registry_Module_cell_values}`
      exposes absent modules. Additional check needed: identity 2.

      (c) **A misclassified module — wrong tier in registry vs decomposition:**
      Identity 3 CANNOT detect this. A wrong-tier module still has a unique (Module, Qualifier)
      pair — no duplicate output. Tier drift is the Registry→Decomposition direction's job
      (Part B census tier-diff check). Additional check needed: tier-diff check.

      (d) **An extra module in one list but not the other:**
      Identity 3 CANNOT detect this. An extra registry module has a unique composite key; an
      extra decomposition module has no registry entry to duplicate. Both cases leave the
      `sort | uniq -d` output empty. Additional check needed: identity 2 in both directions.

      **Assessment:** Identity 3 detects ONLY duplicate (Module, Qualifier) composite-key
      entries — failure mode (a) only. Modes (b)–(d) are covered by identity 2 (matching
      completeness, both directions) and the tier-diff check. Together, identities 0–3 plus
      the tier-diff check form a complete sensor over the full four-mode failure space; no
      single identity covers all four modes. This is an honest partial, not a tautology.

      If any identity does not hold, the burst is BLOCKED and the gate fails. Rules:
      1. All members MUST be independently recomputed from the named artifacts in THIS burst
         — never copied forward from a prior burst or mirrored from a sibling document.
      2. `exempt_count` MUST be derived by counting `—` Criticality rows, not by list length.
         Cross-check against Class B list; disagreement = HIGH-severity finding.
      3. Per-section derivation: state `decomposition_per_section_vector` inline so the total
         is reproducible by a reader (identity 0 requires this to be load-bearing).
      4. Anti-phantom clause (F-P172b-02 motivating instance): a census figure that names an
         artifact MUST be derived by counting that artifact's rows in this burst. The "56" figure
         mirrored the registry total across ~170 passes while naming the decomposition table,
         concealing 7 module-universe baseline gaps.
      5. Set-intersection motivating instance (burst-275C): The coordinator independently computed
         `matched_rows = 66` against `decomposition_tiered_rows = 69`. Three tiered HIGH modules
         (`macros::tool`, `macros::entrypoint`, `macros::task`) had no registry Module cell. A
         prose claim that each module "has a corresponding row" had been accepted without computing
         the difference set. Identity 2 would have blocked at 66 ≠ 69 if `matched_rows` had been
         computed as a set intersection and the difference set reported; instead, the identity was
         evaluated against a prose-asserted value. Reporting the difference set inline makes the
         gap self-revealing: the difference set `{macros::tool, macros::entrypoint, macros::task}`
         would have been the finding.
    - Structurally-privileged heading check: grep `^##` in module-decomposition.md for
      tier-bearing headings; verify each named module's tier matches module-criticality.md.
      Command: `grep -n "^## " .factory/specs/architecture/module-decomposition.md | grep -E "CRITICAL|HIGH|MEDIUM|LOW"`

    **Motivating instance (OBS-P37-1):** F-P37-01 and F-P37-02 survived passes 31–36 because
    the original Part B named only the two registry docs — leaving module-decomposition.md and
    verification-coverage-matrix.md unchecked. Specific drift: graph::channels showed CRITICAL in
    module-decomposition.md vs HIGH in module-criticality.md; verification-coverage-matrix.md
    §Coverage by Criticality Tier showed 6/7/5/2=20 while the authoritative count is 9/12/10/2=33
    and the doc's own per-module table enumerated 9 CRITICAL / 11 HIGH rows.

    Source: ADV-P1D-PASS-32 §OBS-P32-3 [process-gap] (original gate — two-registry sibling set);
    ADV-P1D-PASS-37 §OBS-P37-1 [process-gap] (widening — all four criticality-bearing docs added).

    **Part C — Per-row crate ownership diff (added pass-45 — F-P45-01):**
    In addition to comparing tier values across the three docs, each burst that runs the Part B
    census MUST also diff each module's **owning crate** per-row across the three docs, using
    `module-criticality.md` (arch registry) as the authoritative crate-ownership source.

    **Rule:** A module row that is tier-identical across all three docs but crate-divergent is a
    HIGH-severity finding — it will pass every tier-diff check while silently routing
    implementation and verification work to the wrong crate.

    **Census command (run after every Part B census):**
    ```bash
    # For each module in module-criticality.md §Module Classification, extract (module, owning_crate).
    # Section-scoped to avoid sweeping §Tier Definitions, module-criticality.md §Per-Module Risk Assessment,
    # and §Anti-Patterns rows (which have different headers and produce junk pairs).
    # Note: do NOT use 'grep -n' here — the NN: prefix breaks the header filter.
    # Header-derived column extraction (F-P173-319): the header row is passed to awk NR==1,
    # which locates the "Module" and "Crate" columns by name. Hardcoded field indices are
    # PROHIBITED here — the table header is "Module | Qualifier | Crate | SS | Tier | …"
    # (Qualifier was added in burst-275; any future column change will shift indices again).
    awk '/^## Module Classification/{f=1;next} /^## /{f=0} f' .factory/specs/module-criticality.md \
      | grep '^| ' | grep -v '^|---' \
      | awk -F'|' '
        NR==1 {
          for (i=2; i<=NF; i++) {
            h=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", h)
            if (h == "Module") mc=i
            if (h == "Crate")  cc=i
          }
          next
        }
        { m=$mc; c=$cc
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", m)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", c)
          print m, c
        }' | sort
    # Expected count: recompute from arch-registry §Classification Summary (module-criticality.md).
    # Do NOT hardcode a fixed number here — the registry grows as ADRs add modules.
    # Compare each module's crate column against module-decomposition.md Crate column and
    # verification-coverage-matrix.md Crate/Owner column. Any mismatch is a HIGH-severity finding.
    ```
    All three docs must agree on crate ownership for every module row. Tier agreement alone is
    insufficient — crate-divergent rows survive all tier-only diff checks.

    **Motivating instance (F-P45-01):** The `retry` module row in verification-coverage-matrix.md
    (line 51) listed `pregolya-graph` as owning crate while six independent authorities
    (module-criticality.md, ARCH-INDEX.md, purity-boundary-map, prd.md, error-taxonomy.md,
    bc-authoring-plan.md) all assign retry to `pregolya-core`. The tier was HIGH in both docs
    (tier-identical), so Part B passed. No crate-ownership diff existed to catch the divergence.
    Source: ADV-P1D-PASS-45 §F-P45-01.

    **Crate-level annotation verification — BLOCKING (burst-275C; same structural class as
    F-P172b-05):**
    Some registry rows carry a "crate-level row, no 1:1 decomposition module" annotation (or
    equivalent) in their Qualifier column, signaling that the row covers the crate as a whole and
    the census should not expect a decomposition module match. An annotation that suppresses a
    check MUST itself be verified — this is the same structural defect as F-P172b-05 (an
    unfalsifiable clause that silently suppresses a check), one layer down in the gate hierarchy.

    For every registry row carrying a crate-level or "no 1:1 decomposition module" annotation:

    1. **Verify the annotation is TRUE in this burst using a section-scoped procedure.**
       The crate-stem-prefix grep (`grep "^| <crate_stem>::"`) is **UNSOUND and PROHIBITED**
       (F-P173-306): the module namespace does not always match the crate stem. The live false
       PASS: `pregolya-standard-tests` owns `eval::judge`; the stem-prefix grep searches
       `standard_tests::`, matches zero rows, and stamps VERIFIED — while `eval::judge` exists
       in the Standard Test Modules subsection.

       **Section-scoped procedure (required):**

       a. Locate the crate's H2 section (or H3 subsection for special cases) in
          `module-decomposition.md`. Section headings follow the form
          `## pregolya-<name> (SS-NN) — <TIER>` or similar.
          ```bash
          # General pattern — H2 section scope:
          awk '/^## <section-keyword>/{f=1;next} /^## /{f=0} f' \
            .factory/specs/architecture/module-decomposition.md \
            | grep '^| ' | grep -v '^| Module\|^|---'
          ```
          Where `<section-keyword>` is the distinctive word in the crate's H2 heading
          (e.g., `xtask`, `macros`, `pregolya-memory`). If the output is empty, the
          crate has no module rows in its own H2 section.

       b. **For the two sections that carry an explicit Crate column**, additionally filter
          by crate name in that column:
          - **Provider Embeddings Modules** (`^## Provider Embeddings`): the table header is
            `| Module | Crate | Responsibility | Criticality | SS |`; extract rows where the
            `Crate` column matches the annotated crate.
          - **Standard Test Modules** (`^### Standard Test Modules`): this H3 subsection under
            `## Provider Crates and Standard Tests` contains modules owned by
            `pregolya-standard-tests` (e.g., `eval::judge`); any row in this subsection means
            a `pregolya-standard-tests` crate-level annotation is INVALID.

       c. Combine both results. If ANY module row for that crate is found by either path, the
          annotation is INVALID and is a HIGH-severity finding.

    2. **Record per-row, not as a summary assertion.** State the result for each crate-level
       row individually — e.g., "`pregolya-macros` crate-level row: INVALID — section-scoped
       lookup returned `macros::tool`, `macros::entrypoint`, `macros::task`" or "`pregolya-xtask`
       crate-level row: VERIFIED — section-scoped lookup returned 0 module rows."
       A single "all crate-level rows verified" sentence is NOT sufficient.
       Record the pair `(crate_level_row_count, verified_count)` in the burst's changelog
       commentary. The blocking identity is **`verified_count == crate_level_row_count`**
       (every crate-level row must be individually verified by the section-scoped procedure).

    3. **Roll-up coexistence rule.** A registry row MAY coexist with module rows for the same
       crate ONLY if it is explicitly labeled as a roll-up (e.g., Qualifier contains "ROLL-UP —
       module rows exist; this row aggregates crate-wide properties"). In that case:
       - The row MUST NOT carry "no 1:1 decomposition module" language.
       - The row IS counted in `registry_rows` (unconditional total) and in `roll_up_row_count`.
         It is NOT counted in `registry_census_rows` (= `registry_rows − roll_up_row_count`).
         A roll-up row cannot absorb a module gap; each module must have its own row in the
         `matched_rows` set intersection (roll-up row Module cells use crate-name form, not
         `crate::module` form, so they do not naturally appear in the intersection).

    **Motivating instance (burst-275C):** The `pregolya-macros` registry row was annotated
    "crate-level, no 1:1 decomposition module" while its Qualifier text enumerated
    `#[tool] #[entrypoint] #[task]`. `module-decomposition.md` carried `macros::tool`,
    `macros::entrypoint`, and `macros::task` as three separate HIGH tiered rows. The "no 1:1
    decomposition module" annotation asserted a falsehood; the census skipped three real gaps on
    the strength of the un-verified annotation. Had the annotation been verified in-burst, the
    grep would have returned three rows and the annotation would have been flagged as INVALID
    immediately, surfacing the gap before the census was accepted.

26. **Structurally-Privileged-Line Canon Check — STRUCTURALLY-PRIVILEGED-LINE CANON CHECK
    (added P36 — standing gate [process-gap]):**

    Whenever a fix retires or amends a canon claim, the fixer MUST grep structurally-privileged
    lines — markdown H1/H2/H3 headings (especially `## Decision:` in ADRs), Summary cells/blocks,
    and index/registry rows — across the affected document AND its citing documents for the retired
    claim, not just body prose. A fix that updates body paragraphs but leaves the same stale claim
    in a structurally-privileged heading creates first-class misleading artifacts: headings appear
    in file diffs, navigation, and summaries first and are typically the only content reviewers
    absorb when skimming.

    **Trigger:** Every canon-retirement or canon-amendment fix burst.

    **Scope — what counts as a structurally-privileged line:**
    1. H1/H2/H3 headings in the affected document (especially `## Decision:` and `## Summary:` in ADRs)
    2. Summary / Abstract / Synopsis paragraph blocks (first prose paragraph after the title)
    3. Index rows and registry rows that reference the affected artifact:
       BC-INDEX Title column, ARCH-INDEX ADR log Decision-summary column,
       BC-authoring-plan batch-table Title column, VP-INDEX Description column

    **Census commands (run after every canon-retirement fix):**

    Check H1/H2/H3 headings in the affected document for the retired claim:
    ```
    grep -n "^#" <affected-file> | grep "<retired-claim-keywords>"
    ```

    Check ALL spec documents for structurally-privileged lines containing the retired claim:
    ```
    grep -rn "^#.*<retired-claim-keywords>" .factory/specs/
    grep -rn "^| .*<retired-claim-keywords>" .factory/specs/   # index/registry rows
    ```

    **Motivating instances (two occurrences before this gate was added):**
    - **F-P27-02 (ADV-P1D-PASS-27):** A fix updated body prose but left a stale canon claim in a
      structurally-privileged summary or heading line. First observed instance.
    - **F-P36-01 (ADV-P1D-PASS-36):** `ADR-006-streaming-event-taxonomy.md` `## Decision:` heading
      retained "JSON-serialized to LangGraph format over HTTP" after F-P29-05 corrected the body
      to pregolya-native wire format (D13). The heading was not re-read by any prior fix pass
      across 7 subsequent adversarial reviews.

    **Anti-pattern to prevent:** Fix the body paragraphs, close the burst, leave the heading unchanged.
    The heading is the privileged summary of the decision — it propagates through git diffs, PR
    descriptions, and table-of-contents navigation. Stale headings outlive stale prose.

    Source: ADV-P1D-PASS-27 §OBS-P27-2 (motivating predecessor); ADV-P1D-PASS-36 §OBS-P36-2 [process-gap].

27. **Architecture-anchor crate-resolution census gate — ARCH-ANCHOR CRATE-RESOLUTION CENSUS
    (added P42 — standing gate [process-gap]):**

    Every `pregolya-<crate>/src/...` path (and `xtask/` path) appearing in any BC's
    `## Architecture Anchors` section must satisfy two conditions:

    1. **Roster membership:** The crate name must exist in the ARCH-INDEX §Canonical Crate Roster
       (21 published crates + xtask). Crate names not in the roster are invalid regardless of
       whether the file exists.
    2. **Ownership correctness:** The module cited must be owned by the named crate per
       `module-decomposition.md` responsibilities and ADR-007 crate responsibility descriptions.
       A path that uses a VALID crate name but assigns a module owned by a DIFFERENT crate is a
       wrong-crate assignment and is a HIGH-severity error.

    **ARCH-INDEX §Canonical Crate Roster (source of truth — 21 published crates):** pregolya,
    pregolya-core, pregolya-graph, pregolya-checkpoint, pregolya-openai,
    pregolya-anthropic, pregolya-ollama, pregolya-community, pregolya-splitters,
    pregolya-mcp, pregolya-standard-tests, pregolya-server, pregolya-sandbox,
    pregolya-memory, pregolya-macros, pregolya-openai-sdk, pregolya-anthropic-sdk,
    pregolya-ollama-sdk, pregolya-prompts, pregolya-vectorstores, pregolya-tools.
    Plus: xtask. (Note: ADR-007 documents the original 18-crate topology; D21 added
    pregolya-prompts and pregolya-vectorstores; D23 added pregolya-tools. ARCH-INDEX
    §Canonical Crate Roster is the authoritative living source of truth, not ADR-007.)

    **Key ownership rules (from module-decomposition.md):**
    - StateGraph builder (`add_node`, `add_edge`, `compile`, `graph::definition`) → **pregolya-graph**
    - BSP engine, HITL, channels, scheduler, provenance → **pregolya-graph**
    - budget ENGINE (`BudgetEngine`, `EvidenceJournal`) → **pregolya-graph**; budget TRAIT/types (`BudgetPolicy`, `PolicyDecision`, `TokenUsage`, `RunContext`) → **pregolya-core/src/budget.rs** per ADR-009 Option 3
    - guardrail hook trait (`GuardrailHook`) → **pregolya-core**; guardrail invocation pipeline (ingress call site, `InvocationContext` registration) → **pregolya-graph**
    - Runnable trait, Message types, error taxonomy, credentials, events, config, retry → **pregolya-core**
    - Proc-macro implementations (`#[tool]`, `#[entrypoint]`, `#[task]`) → **pregolya-macros**
    - Re-exported macro trait hooks (e.g., `Tool` re-export) → **pregolya-core** (defensible re-export)
    - CheckpointSaver, session index, logical clock, lineage, encryption → **pregolya-checkpoint**
    - `prompts::template`, `prompts::chat_template`, `prompts::few_shot`, `prompts::injection_guard` → **pregolya-prompts** (SS-18; D21/ADR-015)
    - `vectorstores::store`, `vectorstores::retriever`, `vectorstores::memory`, `vectorstores::similarity`, `vectorstores::mmr` → **pregolya-vectorstores** (SS-20/SS-21; D21/ADR-014)
    - `tools::fs` (ReadFileTool, WriteFileTool, EditFileTool, ListDirTool), `tools::shell` (BashTool), `tools::search` (GrepTool) → **pregolya-tools** (SS-23; D23/ADR-020)

    **Census command:**
    ```
    grep -rh "## Architecture Anchors" --include="*.md" -A 10 .factory/specs/behavioral-contracts/ \
      | grep "pregolya-" | grep -oE "pregolya-[a-z-]+" | sort -u
    ```
    Verify each extracted crate name against the 21-crate roster. Then for any path containing
    `/src/`, verify module ownership against module-decomposition.md.

    **Quick wrong-crate check (run after any BC anchor edit):**
    ```
    grep -rn "pregolya-core/src/graph\|pregolya-core/src/channels\|pregolya-core/src/pregel\
    \|pregolya-core/src/hitl\|pregolya-core/src/bsp\
    \|pregolya-core/src/provenance\|pregolya-core/src/scheduler" \
    .factory/specs/behavioral-contracts/
    ```
    Output must be EMPTY (zero hits). These are graph-owned modules incorrectly placed in core.
    Note: `pregolya-core/src/budget` is EXCLUDED from this forbidden set — `BudgetPolicy` and
    related types (`PolicyDecision`, `TokenUsage`, `RunContext`) correctly reside in
    `pregolya-core/src/budget.rs` per ADR-009 Option 3. BC-2.10.001:141 and BC-2.10.003:139
    are canonical anchors, not wrong-crate hits.

    **Positive assertion — budget ENGINE must not anchor to pregolya-core (run after any BC anchor edit):**
    ```
    grep -rn "pregolya-core.*BudgetEngine\|pregolya-core.*EvidenceJournal" \
    .factory/specs/behavioral-contracts/
    ```
    Output must be EMPTY (zero hits). `BudgetEngine` and `EvidenceJournal` are graph-owned;
    any `pregolya-core` anchor for these types is a wrong-crate assignment.

    **Trigger:** Every burst that adds or edits BC Architecture Anchors + every adversary rotation.
    Running the full census on every adversary rotation prevents wrong-crate anchors from surviving
    multiple passes.

    **Exemptions:** Paths marked `(to be created)` with a plausible crate ownership (i.e., the
    module name is consistent with the crate's scope) are accepted. Paths marked `(to be created)`
    with wrong-crate assignment are NOT exempt — the wrong-crate error is independent of whether
    the file exists. The deferral-actor placeholder class is no longer an accepted exemption —
    all Module fields must carry resolved crate assignments from the time of authoring
    (F-P96-01 + F-P97-01, 2026-07-17; all 60 legacy placeholders resolved — 59 literal + 1 semantic variant).

    **Banned placeholder class (widened F-P97-04, 2026-07-17):** Any phrase matching
    `architect to (assign|confirm|determine|resolve)` — bracketed or unbracketed — in live spec
    content (BC body, traceability table, PRD/supplement section body). Changelog rows,
    gate-rule definitions, and historical audit-trail entries are EXEMPT.
    Prior narrow literal: `[architect to assign]` only. Now covers all semantic variants of the
    same pattern (e.g., "architect to confirm crate→subsystem", "architect to determine placement").

    **Corpus-wide sweep command — run after every burst touching Module fields AND every adversary rotation:**
    ```
    grep -rn --include="*.md" -iE "architect to (assign|confirm|determine|resolve)" \
      .factory/specs/
    ```
    Scope: ALL of `.factory/specs/` (not just `behavioral-contracts/`). Expected live-content hits:
    zero. Exempt hits (changelog rows, gate-rule text, historical audit-trail entries) do not
    constitute gate failures. A hit in live spec content outside those exempt categories is a
    HIGH-severity gate failure.

    **Motivating instances:**
    - F-P42-01 (ADV-P1D-PASS-42) — BC-2.08.011 line 112 and BC-2.08.012 line 119 cited
      `pregolya-core/src/graph/builder.rs` for the StateGraph builder (`add_edge`, `add_node`).
      The StateGraph builder is owned by `pregolya-graph` per ADR-007, module-decomp
      `graph::definition`, and BC-2.02.001 Architecture Anchors. This wrong-crate anchor survived
      41 passes because gate #13 (anchor-matrix census) covers Traceability column cells, not the
      free-text `## Architecture Anchors` bullet section. Gate #27 closes this blind spot.
    - F-P70-01 (ADV-P1D-PASS-70) — Gate #27 ownership rule listed "budget" in the
      pregolya-graph group, and the quick-check pattern included `pregolya-core/src/budget`
      in the forbidden set. ADR-009 §Decision (Option 3 split) places budget TRAIT/types (`BudgetPolicy`,
      `PolicyDecision`, `TokenUsage`, `RunContext`) in `pregolya-core/src/budget.rs` —
      BC-2.10.001:141 and BC-2.10.003:139 are correct anchors to that path. Running the gate as
      written yields 2 false HIGH hits, risking backward "correction." Fixed: ownership rule
      split ENGINE (graph) / TRAIT/types (core); `pregolya-core/src/budget` removed from the
      forbidden set; positive assertion added for BudgetEngine/EvidenceJournal.

    Source: ADV-P1D-PASS-42 §F-P42-01 [process-gap]; ADV-P1D-PASS-70 §F-P70-01 [process-gap].

28. **Version-changelog integrity gate — VERSION-CHANGELOG INTEGRITY
    (added P43 — standing gate [process-gap]):**

    Any BC file with `version` > `"1.0"` MUST carry a `changelog:` frontmatter key (or a
    `## Changelog` body table) with at least one entry per version bump. A file that asserts
    `version: "1.1"` (or higher) while carrying no changelog entry is a **self-contradiction**:
    the version field asserts a revision history that no record corroborates.

    **Rule:**
    - `version: "1.0"`: no changelog required (initial authoring; no prior version exists).
    - `version: "1.1"` or higher: MUST have at least one changelog entry for EACH version
      level above 1.0, recording: what changed, which adversary pass or burst authorised it,
      and a one-line description of the change. An entry may combine multiple co-committed
      changes (e.g., `"1.1 (ADV-P1D-PASS-4): category canon + input re-anchor."`).

    **Format (preferred — frontmatter YAML list):**
    ```yaml
    changelog:
      - "1.0 (initial): base BC authored."
      - "1.1 (ADV-P1D-PASS-N): <one-line description of the 1.0→1.1 change>."
    ```
    The `## Changelog` body-table format (as in BC-2.08.011/012, BC-2.07.002) is also
    acceptable when the BC template already contains a body changelog section. Do not mix
    both formats in the same file.

    **`modified: []` note:** The `modified:` frontmatter field is vestigial and is always
    left as `[]` regardless of changelog presence. It does NOT substitute for the
    `changelog:` key.

    **MANDATORY PRE-EMISSION CHECK — Form-B false-positive trap (OBS-P105-B; prior: F-P49-01):**
    Before emitting ANY "absent changelog," "missing changelog," or "no changelog for version > 1.0"
    finding against any BC or supplement file, run BOTH form checks and union the results:
    1. **Form A check:** `grep -l "^changelog:" <file>` — non-empty output means changelog exists → finding is **INVALID** (false positive).
    2. **Form B check:** `grep -l "^## Changelog" <file>` — non-empty output means changelog exists → finding is **INVALID** (false positive).
    A "missing changelog" finding is ONLY valid when BOTH Form A AND Form B return empty output for the target file.

    Known Form-B-only files (FAIL Form A but are COMPLIANT — always check Form B before filing a finding):
    - BCs: `BC-2.07.002`, `BC-2.08.011`, `BC-2.08.012`
    - Indexes: `BC-INDEX.md`
    - Supplements: `test-vectors.md`, `verification-architecture.md`
    - Any index, ADR, or supplement that uses a `## Changelog` body section rather than a frontmatter `changelog:` YAML list

    **BOTH forms (special classification — F-P172a-14, burst-274-B):**
    - `bc-authoring-plan.md` carries BOTH Form A (frontmatter `changelog:` list) AND Form B (`## Changelog` body table). **Form A is the authoritative form.** The Form B body table is preserved as a historical audit trail only, with an explicit "historical record — superseded by frontmatter changelog" banner at the head of the body table. Agents: do NOT add new entries to the Form B table; add to the Form A frontmatter list only. When checking bc-authoring-plan.md for changelog presence, Form A check passes — finding is INVALID regardless of Form B state.

    Rationale: the existing CRITICAL note and Union coverage rule text (below) were insufficient to
    prevent this pattern — F-P49-01 (pass-49) and OBS-P105-B (pass-105) both reproduced because the
    adversary ran Form A alone and stopped. This standalone step makes the pre-emission check
    explicit and non-optional.

    **Census command (two-form check required — F-P49-01 false-positive fix):**

    Step 1 — Identify all BC files with version > "1.0" (BC-INDEX.md excluded — it is a
    state-manager rolling index whose `version:` tracks index schema, not BC revision):
    ```
    grep -rn "^version:" .factory/specs/behavioral-contracts/ \
      --exclude="BC-INDEX.md" \
      | grep -v '"1\.0"' \
      | cut -d: -f1 | sort -u
    ```
    This emits the filenames of BCs that require a changelog entry.
    (Step 1 is a LIST; Step 2 operates on the Form A / Form B union independently of Step 1's
    output — the union check does not require iterating the Step 1 list file-by-file.)

    Step 2 — For each BC identified in Step 1, check BOTH forms of changelog:

    Form A (frontmatter `changelog:` key):
    ```
    grep -rl "^changelog:" .factory/specs/behavioral-contracts/
    ```

    Form B (`## Changelog` body table):
    ```
    grep -rl "^## Changelog" .factory/specs/behavioral-contracts/
    ```

    **Union coverage rule:** A BC with `version` > `"1.0"` satisfies this gate if it appears
    in Form A's grep output (frontmatter `changelog:` key present) OR Form B's grep output
    (`## Changelog` body section present). A BC NOT appearing in either output while carrying
    `version` > `"1.0"` is a gate failure.

    **CRITICAL:** The adversary MUST run BOTH Step 2 form checks and union the results.
    Checking only Form A (frontmatter) is INSUFFICIENT — it misses BCs that carry their
    changelog exclusively as a body `## Changelog` table. Checking only Form B is also
    insufficient for BCs using frontmatter-only changelogs.

    **Motivating instance (F-P49-01 false positive, ADV-P1D-PASS-49):** The adversary claimed
    BC-2.08.011, BC-2.08.012, and BC-2.07.002 at v1.1 lacked changelogs. The adversary ran
    only Form A (frontmatter `changelog:` grep). All three BCs carry `## Changelog` BODY
    TABLES — the alternate permitted form. The Form-A-only check produced a false positive.
    Root cause: the prior census command text listed "verify a `changelog:` frontmatter key
    or `## Changelog` body section" in PROSE but provided only a Form-A grep COMMAND, giving
    no machine guidance to run Form B. This two-step explicit census closes that gap.

    Any version > 1.0 without a changelog in either form is a gate failure.

    **Date-validity sub-check (added P65 — OBS-P65-1 widening; scoped P87 — D18-P87-A):**
    For every changelog entry in any changelog-bearing file (BC file or supplement) (Form A
    frontmatter list entries AND Form B body table rows), the date value MUST satisfy the
    following five rules, scoped by document type:
    1. **`date ≤ frontmatter timestamp` (SUPPLEMENT documents only — `introduced:` field absent):**
       A changelog entry date must not exceed the document's `timestamp:` field. Since supplement
       `timestamp:` always equals the newest changelog entry date (Rule 5 supplement branch), all
       individual entry dates satisfy this constraint when Rule 5 holds.
       **BC files (`introduced:` field present): Rule 1 does NOT apply.** `timestamp:` is frozen
       at the v1.0 authoring date; subsequent changelog entries carry dates AFTER `timestamp:` by
       design — COMPLIANT per Rule 5 BC branch (D18-P87-A). The date ceiling for BC changelog
       entries is Rule 2 only.
    2. `date ≤ current burst date` — no future-dated changelog entries; the date must not
       exceed the date on which the burst is executed. (Applies to ALL document types.)
    3. Monotonic per file ordering convention — Form B tables (newest-at-top) must have
       dates non-increasing reading top-to-bottom; Form A lists must have dates non-decreasing
       reading bottom-to-top. A v1.1 row dated AFTER the superseding v1.2 row is a violation.
       (Applies to ALL document types.)

    **Form-B date-validity sweep — authoritative tool (F-P172a-06):**
    `verify-changelog-date-monotonicity.sh` is the **authoritative corpus-wide** date sweep.
    It covers ALL `.factory/specs/` changelog-bearing files — both Form A (frontmatter list)
    and Form B (body table) — without requiring manual file enumeration. Run it as the
    primary date-validity check on every adversary rotation:
    ```
    bash .factory/hooks/verify-changelog-date-monotonicity.sh
    ```
    Expected: PASS (no date-order violations). Non-blocking WARNs for both-forms co-existence
    are informational only (see DEFER-002 note above).

    **Manual fallback (when hook is unavailable — run on every adversary rotation):**
    All files carrying Form-B (`## Changelog`) body tables — BCs, supplements, indexes, and
    architecture docs — must be included in every body-table date sweep. Known Form-B files:

    *BC files (body-table form):*
    `BC-2.07.002`, `BC-2.08.011`, `BC-2.08.012`

    *Supplement files (body-table form):*
    `bc-authoring-plan.md` (BOTH forms — Form A authoritative; Form B historical audit trail),
    `test-vectors.md`

    *Indexes:*
    `BC-INDEX.md`

    *Architecture files (body-table form — classified as `architecture/`, not supplement):*
    `verification-architecture.md`, `ADR-007`, `ADR-009`, `ADR-012`, `ADR-013`

    ```
    grep -n "| [0-9]\+\.[0-9]\+ | 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]" \
      .factory/specs/behavioral-contracts/ss-07/BC-2.07.002.md \
      .factory/specs/behavioral-contracts/ss-08/BC-2.08.011.md \
      .factory/specs/behavioral-contracts/ss-08/BC-2.08.012.md \
      .factory/specs/prd-supplements/bc-authoring-plan.md \
      .factory/specs/prd-supplements/test-vectors.md \
      .factory/specs/behavioral-contracts/BC-INDEX.md \
      .factory/specs/architecture/verification-architecture.md \
      .factory/specs/architecture/decisions/ADR-007-*.md \
      .factory/specs/architecture/decisions/ADR-009-*.md \
      .factory/specs/architecture/decisions/ADR-012-*.md \
      .factory/specs/architecture/decisions/ADR-013-*.md
    ```
    For each extracted date, assert: (a) `date ≤` current burst date, and (b) dates within each
    file decrease monotonically reading top-to-bottom (newest-at-top convention). For
    **SUPPLEMENT files only** (bc-authoring-plan, test-vectors), additionally assert:
    (c) `date ≤ frontmatter timestamp:` field (Rule 1 supplement branch — D18-P87-A).
    Any date later than the burst date, violating monotonicity, or exceeding the supplement
    `timestamp:` is a gate failure.

    **Motivating instances:**
    - F-P64-02 (ADV-P1D-PASS-64): bc-authoring-plan.md v1.1 and test-vectors.md v1.1 rows
      dated 2026-07-16 — two days future relative to their superseding v1.2 rows dated
      2026-07-14 (same F-P36-03 root cause). Gate #28 scope at that time was changelog-presence
      only; date-validity was outside all standing gates.
    - F-P65-01 (pass-65): BC-2.07.002 body `## Changelog` v1.1 row dated 2026-07-16 —
      same PASS-36 root cause as F-P64-02. The P64 fix burst covered the two prd-supplements
      but never enumerated the Form-B BC set. OBS-P65-1 identifies the Form-B enumeration gap
      as a process deficiency at the same layer.
    Source: OBS-P65-1 [process-gap].

    **Extended rules (added P75 — F-P75-01/OBS-P75-A, 3rd recurrence of future-dated-changelog class; prior: F-P64-02, F-P65-01):**

    4. **TEMPORAL-NEIGHBOR SWEEP:** When any file is edited in a fix burst, ALL neighboring changelog rows in that file — not only the newly added row — must be date-audited in the same burst. Pass N's changelog dates may not exceed pass N+1's artifact dates, nor precede pass N-1's beyond same-day. A row whose date exceeds an adjacent pass's canonical date is a gate failure even if the row was authored in an earlier burst.

    5. **FRONTMATTER-CURRENCY (scoped by document type — adjudication D18-P86-A, 2026-07-16):**
       - **Supplement documents** (`introduced:` frontmatter field absent — bc-authoring-plan, test-vectors, error-taxonomy, interface-definitions, nfr-catalog, module-criticality, observability [7 total]): `timestamp:` must equal the date of the file's newest changelog entry. A supplement `timestamp:` that exceeds the current burst date, or that does not match the newest changelog entry's date, is a self-contradiction.
       - **BC files** (`introduced:` frontmatter field present): `timestamp:` is the authoring date (stable, never updated after initial v1.0 authoring). BC currency is tracked via `version:` + `## Changelog` + `introduced:`. A BC `timestamp:` that does not match the v1.0 changelog row's date is a self-contradiction.

       **ADR documents** (`.factory/specs/architecture/decisions/ADR-NNN-*.md`):
       `timestamp:` or `date:` field = the original ADR acceptance date (frozen at first
       acceptance; never updated when the ADR is amended). ADR currency is tracked via
       `version:` + changelog (newest-at-top per architecture/ descending direction rule).
       An ADR `timestamp:` that does not match the original first-accepted date is a
       self-contradiction. Amendments to an ADR do NOT change its `timestamp:` or `date:` —
       they add a changelog entry and bump `version:`. Source: F-P171a-17 adjudication
       (process-gap — Gate #28 Rule 5 scoped only Supplement + BC; ADR branch was absent).

       **Convention note:** BC-2.07.002 (ts 2026-07-13, newest changelog 2026-07-15), BC-2.08.011 (ts 2026-07-13, newest changelog 2026-07-14), and BC-2.08.012 (ts 2026-07-13, newest changelog 2026-07-14) are COMPLIANT under the scoped rule — each timestamp equals its v1.0 initial authoring date. DEFER-002 machine enforcement at Phase 3 must branch on `introduced:` field presence: `if has_introduced: assert timestamp == v1.0_changelog_date; else: assert timestamp == max_changelog_date`.

    6. **VERSION-MONOTONICITY (CHANGELOG-MONOTONICITY — added 2026-07-17; codified at 3rd
       recurrence per lessons-codification.md policy; prior: F-P97-03/BC-2.08.006,
       F-P101-02/BC-2.11.002, F-P102-01/BC-2.11.005):**
       Every changelog-bearing file's version entries MUST be ordered monotonically in ONE
       direction consistent with that file's own established convention. The direction is
       determined from the file's first two distinct-version rows — once established, no
       subsequent version transition may reverse it.

       - **BC files** (`.factory/specs/behavioral-contracts/`), Form A (frontmatter YAML list):
         direction = **ascending** (oldest version at top, newest at bottom) per gate
         convention. Form B (`## Changelog` body table, non-INDEX files only): direction =
         **descending** (newest version at top) — machine-enforced by the
         `validate-changelog-monotonicity` hook. `*INDEX.md` files are **exempt** from this
         direction rule: the `validate-changelog-monotonicity` hook skips them, and the
         `validate-count-propagation` hook blocks all BC-INDEX.md edits until STATE.md count
         drift is resolved by state-manager. BC-INDEX.md direction is maintained descending
         as a by-product of hook enforcement on its last edit; no census direction assertion
         is emitted for INDEX files.
       - **Architecture files** (`.factory/specs/architecture/`), Form A or B: direction =
         **descending** (newest version at top) — machine-enforced by the
         `validate-changelog-monotonicity` hook for Form B; Form A follows the same descending
         convention by project policy (confirmed during pass-103 fix burst via hook-source
         audit: hook fires on all `.factory/**/*.md` `## Changelog` body tables except
         `*STATE.md|*INDEX.md|*burst-log*|*convergence-trajectory*|*session-checkpoint*|*lessons*`).
       - **Supplement files** (`.factory/specs/prd-supplements/`), Form A or B: direction =
         **descending** (newest version at top) per D18-P64-B. `error-taxonomy.md` and
         `interface-definitions.md` use Form A YAML frontmatter but follow this descending
         convention — the form (A vs B) does NOT determine direction; the file-class path
         determines convention.
       - **Equal-version adjacent rows** (same-version multi-event entries) are permitted and
         do not affect direction determination.

       **Why this is independent of Rule 3 (date ordering):** Rule 3 detects date VALUES that
       are out of temporal order relative to surrounding rows. Rule 6 detects version NUMBERS
       that are positionally transposed — even when both transposed entries share the same date,
       making the transposition invisible to a date-ordering check.

       **Motivating instances (3-recurrence threshold met 2026-07-17):**
       - F-P97-03 (ADV-P1D-PASS-97): BC-2.08.006 changelog transposition
       - F-P101-02 (ADV-P1D-PASS-101): BC-2.11.002 changelog transposition
       - F-P102-01 (ADV-P1D-PASS-102): BC-2.11.005 — version 1.3 appeared before 1.2 in the
         ascending YAML list; corrected by swapping the two rows (pure reorder, no version bump)

       **Motivating instance (OBS-P103-A — direction-blindness, 2026-07-17):**
       - OBS-P103-A (ADV-P1D-PASS-103): nfr-catalog.md changelog ran 1.1→1.2 (ascending) but
         prd-supplements/ class requires DESCENDING (newest-at-top per D18-P64-B). The prior
         direction-agnostic census was structurally unable to flag a consistently-wrong-direction
         file — nfr-catalog.md passed burst-184 census because the 1.1→1.2 sequence is
         internally monotonic even though the direction is wrong. Extended to direction-aware in
         this burst (v2.32). Direction rules discovered via hook-source audit during fix burst:
         prd-supplements/ → desc; architecture/ → desc (hook-enforced for Form B, project policy
         for Form A); behavioral-contracts/ Form A → asc; behavioral-contracts/ Form B non-INDEX
         → desc (hook-enforced); behavioral-contracts/ *INDEX.md → exempt (hook skips;
         count-propagation blocks edits). Single-entry and single-distinct-version files exempt
         from the direction assertion (monotonicity trivially satisfied).
         Corpus-wide pass-103 census results: 27 BC Form A files corrected desc→asc;
         nfr-catalog.md corrected asc→desc (F-P103-01); 7 architecture Form A files corrected
         asc→desc (ARCH-INDEX, api-surface, dependency-graph, module-decomposition,
         system-overview, tooling-selection, verification-coverage-matrix);
         purity-boundary-map.md retained desc (architecture Form A — reverted after erroneous
         asc correction); 3 ADRs (Form B) retained desc per hook enforcement; BC-INDEX.md
         retained desc (count-propagation blocker prevents any edit);
         verification-coverage-matrix.md input-hash refreshed (pre-existing drift
         `cabbed8`→`6b6537d` surfaced by changelog reorder edit). Post-fix census: PASS.

       **Census command (copy-paste runnable; direction-aware (v2.32+); section-scoped to avoid
       false positives from example YAML in gate prose; covers all changelog-bearing files
       corpus-wide — all BCs + prd-supplements + architecture changelogs):**
       ```bash
       python3 << 'CENSUS'
       import re, glob
       def expected_dir(path, form):
           # Rule: prd-supplements and architecture are always descending.
           # BC Form A (frontmatter YAML): ascending per gate convention.
           # BC Form B (## Changelog table):
           #   - *INDEX.md files: exempt (validate-changelog-monotonicity skips them;
           #     validate-count-propagation blocks edits until STATE.md count is resolved).
           #   - All other BC Form B: descending (machine-enforced by hook).
           if '/prd-supplements/' in path: return 'desc'
           if '/architecture/' in path: return 'desc'
           if '/behavioral-contracts/' in path:
               basename = path.split('/')[-1]
               if form == 'B':
                   if 'INDEX' in basename: return None  # exempt — hook skips, count-propagation blocks
                   return 'desc'  # validate-changelog-monotonicity hook-enforced
               return 'asc'  # Form A: ascending per gate convention
           return None
       def chk(path):
           text = open(path).read()
           parts = text.split('---', 2)
           fm = parts[1] if len(parts) >= 3 else ''
           body = parts[2] if len(parts) >= 3 else text
           # Form A: changelog: YAML list in frontmatter only
           fm_m = re.search(r'^changelog:\s*\n((?:[ \t]+-[ \t]+.*\n)+)', fm, re.MULTILINE)
           if fm_m:
               vers = re.findall(r'^[ \t]+-[ \t]+"(\d+\.\d+)', fm_m.group(0), re.MULTILINE)
               if len(vers) >= 2:
                   nums = [tuple(int(x) for x in v.split('.')) for v in vers]
                   i = next((j for j in range(len(nums)-1) if nums[j] != nums[j+1]), None)
                   if i is None: return None
                   asc = nums[i+1] > nums[i]
                   for j in range(len(nums)-1):
                       if nums[j] == nums[j+1]: continue
                       if (nums[j+1] > nums[j]) != asc:
                           return '  %s (Form-A): %s->%s breaks monotonicity (%s)' % (
                               path, vers[j], vers[j+1], 'asc' if asc else 'desc')
                   exp = expected_dir(path, 'A')
                   if exp is not None and ('asc' if asc else 'desc') != exp:
                       return '  %s (Form-A): direction=%s but file-class requires %s' % (
                           path, 'asc' if asc else 'desc', exp)
                   return None
           # Form B: ## Changelog body section only
           bm = re.search(r'(?:^|\n)## Changelog\n(.*?)(?=\n## |\Z)', body, re.DOTALL)
           if bm:
               vers = re.findall(r'^\|\s*(\d+\.\d+)\s*\|', bm.group(1), re.MULTILINE)
               if len(vers) >= 2:
                   nums = [tuple(int(x) for x in v.split('.')) for v in vers]
                   i = next((j for j in range(len(nums)-1) if nums[j] != nums[j+1]), None)
                   if i is None: return None
                   asc = nums[i+1] > nums[i]
                   for j in range(len(nums)-1):
                       if nums[j] == nums[j+1]: continue
                       if (nums[j+1] > nums[j]) != asc:
                           return '  %s (Form-B): %s->%s breaks monotonicity (%s)' % (
                               path, vers[j], vers[j+1], 'asc' if asc else 'desc')
                   exp = expected_dir(path, 'B')
                   if exp is not None and ('asc' if asc else 'desc') != exp:
                       return '  %s (Form-B): direction=%s but file-class requires %s' % (
                           path, 'asc' if asc else 'desc', exp)
           return None
       files = sorted(
           glob.glob('.factory/specs/behavioral-contracts/**/*.md', recursive=True) +
           glob.glob('.factory/specs/prd-supplements/*.md') +
           glob.glob('.factory/specs/architecture/**/*.md', recursive=True)
       )
       errs = [r for r in (chk(f) for f in files) if r]
       print('\n'.join(errs) if errs else 'PASS -- all changelog version sequences are monotonic and direction-correct')
       CENSUS
       ```
       Expected output after corpus fix: **PASS — all changelog version sequences are monotonic and direction-correct**

       **Scope:** ALL changelog-bearing files in `.factory/specs/`. This is a corpus-wide
       check — not limited to the file being edited in the current burst.

       **Trigger:** Every burst that creates new BCs, bumps any version, or edits any
       changelog entry + every adversary rotation.

    **Machine enforcement status (OBS-P75-A / DEFER-002; revised F-P172a-05, burst-274-B):**
    - **LIVE (blocking pre-commit hooks):**
      - `verify-changelog-date-monotonicity.sh` — enforces **Rules 2+3** (date ≤ burst date; monotonic ordering within file). This hook also emits non-blocking WARNs for both-forms co-existence (`both-changelog-forms:frontmatter=X.X,body-table=Y.Y`) and version-parity divergence between forms.
      - `verify-form-a-changelog-direction.sh` — enforces **Rule 6 Form A** (prd-supplements/architecture Form A descending direction; behavioral-contracts Form A ascending direction).
    - **DEFERRED to Phase 3 CI hardening (DEFER-002 residual):**
      - Rule 1 (`date ≤ frontmatter timestamp:` — supplement branch only): requires CI branch on `introduced:` field presence.
      - Rule 4 (temporal-neighbor sweep): requires multi-file context; not yet mechanized.
      - Rule 5 (frontmatter-currency machine check: `timestamp:` == newest changelog date for supplements; `timestamp:` == v1.0 date for BCs): requires CI branch on `introduced:` field presence per D18-P86-A / D18-P87-A.
      - Rule 6 Form B (body-table direction machine check for architecture/ and behavioral-contracts/ Form B): `validate-changelog-monotonicity` hook covers body tables but not Form A direction on those paths.
    Deferral logged by state-manager as a STATE.md drift/deferral entry. Until full machine enforcement, burst discipline governs — every PO burst that touches a changelog file must manually run the date-validity and version-monotonicity sub-checks for the still-deferred rules.

    The Phase 3 linter MUST implement the following decision tree, branching on `introduced:`
    field presence (D18-P86-A for Rule 5 scoping; D18-P87-A for Rule 1 scoping):

    ```
    if document has `introduced:` field (BC files):
        assert date ≤ current_burst_date               [Rule 2 — universal]
        assert monotonic_ordering_within_file          [Rule 3 — universal]
        assert temporal_neighbor_sweep                 [Rule 4 — universal]
        assert timestamp == v1.0_changelog_row_date    [Rule 5 BC branch]
        assert version_monotonicity_within_file        [Rule 6 — universal]
        # Rule 1 does NOT apply — timestamp frozen at v1.0 authoring date
    else (supplement documents, `introduced:` field absent):
        assert date ≤ frontmatter_timestamp            [Rule 1 — supplement branch only]
        assert date ≤ current_burst_date               [Rule 2 — universal]
        assert monotonic_ordering_within_file          [Rule 3 — universal]
        assert temporal_neighbor_sweep                 [Rule 4 — universal]
        assert timestamp == max_changelog_date         [Rule 5 supplement branch]
        assert version_monotonicity_within_file        [Rule 6 — universal]
    ```

    **Revert rule:** If git history shows a BC was never substantively modified (only metadata
    touches such as `bc_id` addition and `status: draft → active`), the version MUST be
    reverted to `"1.0"` — a spurious batch-wide bump does not create a changelog obligation.

    **Trigger:** Every burst that creates new BCs or bumps a BC version field + every
    adversary rotation.

    **Motivating instance:** F-P43-01 (ADV-P1D-PASS-43) — 17 BCs in ss-04, ss-11, ss-13
    carried `version: "1.1"` with `modified: []` and no changelog key. Git-history
    adjudication found 4 files were genuinely unmodified (reverted to 1.0) and 13 were
    substantively modified (changelog entries added recording the specific pass and change).

    Source: ADV-P1D-PASS-43 §F-P43-01 [process-gap].

29. **Supplement-vs-BC seam census gate — SUPPLEMENT-VS-BC SEAM CENSUS
    (added P47 — standing gate [process-gap]):**

    Any edit to a prd-supplement table row that describes behavior governed by a BC (feature
    flags table, flag interaction rules table, config schema comments, endpoint row descriptions)
    MUST verify the row's claim matches the cited BC's postconditions and edge cases before the
    burst closes. The supplement row is the DERIVED artifact; the BC postconditions and edge
    cases are the AUTHORITY. On any conflict between a supplement row and a BC, the BC wins.

    **Trigger:** Every supplement edit (interface-definitions.md or any prd-supplement table
    containing BC citations) + every adversary rotation.

    **Scope — what rows are subject to this census:**
    1. Cargo Feature Flags table rows with a non-empty BC Anchor column
    2. Flag Interactions table rows (any row describing behavior controlled by a BC)
    3. Config schema inline comments citing a BC (e.g., `# ...  (BC-S.SS.NNN)`)
    4. HTTP endpoint rows with behavioral BC citations where the row makes a semantic claim
       beyond "endpoint exists" (e.g., describing state transitions, error return values,
       timing of side effects such as warnings)

    **Census procedure:**
    For each row in scope, extract the cited BC(s), open the cited BC file, and diff the
    row's claim against the BC's Postconditions and Edge Cases tables:
    - Feature flag "Default" column must match whether the feature is active in
      `SandboxBackend::default()` / `SandboxExecutor::new_default()` semantics per BC PCs.
    - Feature flag description must not claim a fallback or default behavior the BC prohibits
      (e.g., "defaults to process backend" contradicts BC-2.13.001 PC4).
    - Flag interaction description for an "off+off" combination must match the BC's
      postcondition for that state (no enforcing backend → Err, not silent process fallback).
    - Config comment describing timing of warnings must match BC PC2/EC-002 (per-execute,
      not construction or startup).

    **SS-13 sandbox rows (full census — run at every adversary rotation):**

    | Row | Cited BC | PC/EC Check | Verdict |
    |-----|----------|-------------|---------|
    | `sandbox-wasm` feature (Default: on) | BC-2.13.001 | Default=on (enforcing); no fallback claim | PASS |
    | `sandbox-container` feature (Default: off) | BC-2.13.001 | Default=off; supplementary enforcing backend | PASS |
    | `sandbox-process` feature (Default: off) | BC-2.13.001, BC-2.13.002 | Default=off; NOT enforcing; explicit-constructor-only via `unsafe_process_no_isolation()` | PASS (added OBS-P47-1) |
    | `[sandbox] backend = "process"` config comment | BC-2.13.002 PC2/EC-002 | Warning timing = per-execute() invocation, NOT startup or construction | PASS (fixed F-P47-02) |
    | Flag interaction: `sandbox-wasm + sandbox-container` both off | BC-2.13.001 PC4/EC-002 | Returns `Err(E-SBXD-003 SandboxInitFailed)`; NO silent process fallback | PASS (fixed F-P47-01) |
    | Flag interaction: `sandbox-wasm + sandbox-container` both on | BC-2.13.001 PC1 | WASM takes precedence; ContainerBackend is fallback when WASM unavailable | PASS |

    **Census command (after any supplement edit):**
    ```
    grep -n "BC-2\.13\." .factory/specs/prd-supplements/interface-definitions.md
    ```
    For each hit, open the cited BC file and diff the supplement text against the BC's
    Postconditions and Edge Cases. Any supplement claim that contradicts a BC PC or EC
    is a gate failure requiring immediate correction.

    **Broader census command (all BC-cited supplement rows):**
    ```
    grep -n "BC-[0-9]\." .factory/specs/prd-supplements/interface-definitions.md \
      | grep -v "changelog\|BC anchor\|authority\|Authority\|F-P\|OBS-P\|Fix\|ADV-P1D"
    ```
    For each extracted BC citation in a feature-flag, flag-interaction, or config-comment
    context, diff the surrounding text against the cited BC's PCs/ECs.

    **Motivating instance (F-P47-01, CRITICAL, survived 46 adversarial passes):**
    Flag Interaction Rules row for `sandbox-wasm + sandbox-container both off` stated
    "`pregolya-sandbox` defaults to process backend; emits WARNING" — directly inverting
    BC-2.13.001 PC4 and EC-002 (the correct behavior is `Err(E-SBXD-003 SandboxInitFailed)`,
    no silent fallback). This is the adk-rust P-61 security hole that BC-2.13.001 was
    explicitly designed to prevent. An implementer following the supplement row would have
    built the no-isolation security hole. The row survived 46 passes because no prior census
    explicitly cross-referenced supplement rows against their cited BC's postconditions.

    F-P47-02 (MED): `[sandbox]` config comment said "on startup" — contradicting BC-2.13.002
    PC2 ("once per execute() invocation, not only at construction time") and EC-002 (no
    warning if execute() never called).

    Source: ADV-P1D-PASS-47 §F-P47-01 (CRITICAL); §F-P47-02 (MED); §OBS-P47-1 [process-gap].

30. **Codeless-error census gate — CODELESS-ERROR CENSUS (added P56 — standing gate [process-gap]):**

    Any burst that creates or edits a BC file, OR adds an error code to error-taxonomy.md, MUST
    verify that every concrete `Err(PregolyaError { .. })` construction in the affected BC
    bodies carries a `code:` field referencing a catalogued taxonomy code before the burst closes.

    **Definition — what counts as a concrete (non-exempt) construction:**

    A construction is concrete (subject to this gate) if it:
    1. Appears in a BC table (test vectors, edge cases) or named postcondition;
    2. Does NOT use `...` or `…` ellipsis notation as a field placeholder (ellipsis forms are
       "pattern description" abstractions and are exempt); AND
    3. Identifies a specific error instance (not a category family).

    **Rule:** Every concrete construction must carry `code: E-<COMP>-NNN` where `E-<COMP>-NNN`
    is a live (non-retired) code in error-taxonomy.md. A construction that matches the message
    format or category of a known taxonomy code must use that code. If no existing code fits,
    mint a new one in the same burst.

    **RetryHint coherence:** When a `code:` field is added, verify per gate #22 that the
    code's RetryHint matches the category default or is documented as a divergence.

    **Census command (first-pass scan for codeless constructions):**
    ```
    grep -rn "Err(PregolyaError {" .factory/specs/behavioral-contracts/ \
      | grep -v "code:" | grep -v "\.\.\." | grep -v "~~"
    ```
    Output should be empty or consist solely of pattern-description / ellipsis exemptions.
    For each hit, determine whether the construction is concrete (subject to gate) or exempt.

    **Trigger:** Every burst that authors new BCs or edits existing BC tables/postconditions
    containing `Err(PregolyaError { .. })` constructions + every adversary rotation.

    **Motivating instance (F-P56-01, ADV-P1D-PASS-56 [process-gap]):** BC-2.01.003 PC5,
    invariant §layer-disambiguation, EC-004, and TV-004 all returned `Err(PregolyaError
    { category: INTERNAL, message: "recursion limit exceeded...", .. })` with no `code:` field,
    while the graph-engine counterpart (E-GRAPH-017) had been coded since pass 49. The
    codeless construction was invisible to the 75-code disposition census (census counts
    catalogued codes only). E-CORE-006 minted this burst; all four sites updated.

    **First-pass census results (ADV-P1D-PASS-56):**

    | BC | Construction | Verdict | Action |
    |----|-------------|---------|--------|
    | BC-2.01.003 PC5/inv/EC-004/TV-004 | `{ category: INTERNAL, message: "recursion limit exceeded..." }` | Concrete — missing code | Fixed: E-CORE-006 |
    | BC-2.14.006 EC-001/EC-004/TV-001/TV-004/TV-005 | `{ category: VAL, message: "Validation failed for..." }` | Concrete — missing code | Fixed: E-CORE-005 |
    | BC-2.08.007 EC-001/EC-003/EC-004/TV-001/TV-003/TV-005 | `{ category: TIMEOUT/TRANSPORT }` (no message, no ellipsis) | Concrete — missing code | Fixed: E-PROV-002/E-PROV-003 |
    | BC-2.08.004 EC-001/EC-003/TV-001/TV-003 | `{ category: AUTH/RATE }` | Concrete — missing code | Fixed: E-PROV-004/E-PROV-001 |
    | BC-2.08.004 EC-004/EC-005/TV-004/TV-005 | `{ category: TRANSPORT, message: "provider HTTP 500 / unknown format" }` | Concrete but no exact PROV TRANSPORT code for non-stream HTTP errors | Deferred: mint E-PROV-008 (ProviderHttpError) or broaden E-PROV-003 scope in next burst |
    | BC-2.14.006 line 34, BC-2.14.002, BC-2.14.003 etc. | `{ category: X, ... }` with explicit `...` | Exempt: ellipsis pattern description | No action needed |
    | BC-2.08.007 PC1/PC2 | `{ category: TIMEOUT/TRANSPORT, … }` with `…` | Exempt: ellipsis pattern description | No action needed |

    **Deferred (now RESOLVED, ADV-P1D-PASS-56-COMPLETION):** BC-2.08.004 EC-004/EC-005/TV-004/TV-005 — TBD-E-PROV-HTTP replaced with E-PROV-008 (ProviderHttpError, TRANSPORT, minted error-taxonomy.md v1.8). Both sites share TRANSPORT category; one code is correct. BC-2.08.004 v1.2.

    **Second-pass census results (ADV-P1D-PASS-56-COMPLETION):**

    | BC | Construction | Verdict | Action |
    |----|-------------|---------|--------|
    | BC-2.08.004 EC-004/EC-005/TV-004/TV-005 | `{ category: TRANSPORT, code: TBD-E-PROV-HTTP }` | Concrete — placeholder code | Fixed: E-PROV-008 (minted) |
    | BC-2.09.004 line 70 | `{ component: MCP, category: TOOL, code: E-MCP-001, ... }` | Multi-line — code on next line | Already coded — PASS |
    | BC-2.09.004 line 86 | `{ category: TOOL }` | Pattern contrast in invariants; code specified in PC1/EC-001 as E-MCP-001 | Exempt: pattern description with code elsewhere in same BC |
    | BC-2.01.003 line 106 | `{ category: INTERNAL, code: E-CORE-006, ... }` | Multi-line — code present | Already coded (pass 56 fix) — PASS |
    | BC-2.01.004 line 79 | `{ category: INTERNAL, code: E-CORE-004, ... }` | Multi-line — code on following lines | Already coded — PASS |
    | BC-2.08.006 EC-002 | `{ category: Validation, message: "timeout must be set..." }` | Concrete — wrong category name + no code | Fixed: category corrected to VAL; code: E-CORE-005 added |
    | BC-2.08.006 TV-002 | `{ category: VAL }` | Concrete — no code | Fixed: code: E-CORE-005 added |
    | BC-2.08.002 EC-005 | `{ category: VAL, message: "model <name> does not support tool calling" }` | Concrete — no code | Fixed: code: E-CORE-005 added |
    | BC-2.08.002 TV-005 | `{ category: VAL }` | Concrete — no code | Fixed: code: E-CORE-005 added |
    | BC-2.08.007 line 38 | `{ category: TIMEOUT | TRANSPORT }` | Pattern description in Description section | Exempt: class-level description |
    | BC-2.08.007 line 58 | `{ category: TIMEOUT, message: "...", … }` | PC1 with Unicode `…`; E-PROV-002 specified in EC/TV | Exempt: ellipsis form; code specified elsewhere in same BC |
    | BC-2.08.001 EC-003 | `{ category: TRANSPORT, … }` | Unicode `…` but code not in this BC (cross-ref to BC-2.08.007) | Fixed: code: E-PROV-003 added explicitly to satisfy gate rule |
    | BC-2.08.004 PC1-PC5 | `{ category: AUTH/VAL/RATE/TRANSPORT/VAL, … }` | Postcondition descriptions with Unicode `…`; codes in EC/TV | Exempt: ellipsis forms; codes specified in EC/TV |
    | BC-2.11.002 EC-001/TV | `{ category: INTERNAL }` | Concrete — no code | Fixed: code: E-CORE-007 (minted) |
    | BC-2.11.003 EC-004/TV | `{ category: INTERNAL }` | Concrete — no code | Fixed: code: E-CORE-007 |
    | BC-2.11.004 EC-004/TV | `{ category: INTERNAL }` | Concrete — no code | Fixed: code: E-CORE-007 |
    | BC-2.16.002 line 57 | `{ component: RETRY, category: POLICY, code: E-RETRY-002, ... }` | Code present | Already coded — PASS |
    | BC-2.04.002 EC-003/TV | `{ category: VAL, message: "unknown durability tier..." }` | Concrete — no code | Fixed: code: E-CORE-005 added |
    | BC-2.04.006 EC-003 | `{ category: VAL }` | Concrete — no code | Fixed: code: E-CORE-005 added |
    | BC-2.04.007 EC-003/TV | `{ category: VAL, message: "EncryptedSerializer: key..." }` | Concrete — no code | Fixed: code: E-CORE-005 added |
    | BC-2.04.007 EC-004 | `{ category: INTERNAL, message: "missing cipher header..." }` | Concrete — no code | Fixed: code: E-CHKPT-007 (minted) |

    **Census summary (ADV-P1D-PASS-56-COMPLETION):** 24 constructions examined; 13 fixed (codes added); 3 already-coded multi-line constructions (PASS); 8 exempt (pattern descriptions or ellipsis forms with code specified elsewhere in same BC). Zero genuine codeless constructions remaining. Gate #30 census command `grep -rn "Err(PregolyaError {" .factory/specs/behavioral-contracts/ | grep -v "code:" | grep -v "\.\.\." | grep -v "~~"` now returns zero genuine hits (residual grep hits are ellipsis `…` forms or already-coded multi-line constructions where `code:` is on the following line).

    **(F-P112-02, 2026-07-18 addendum):** Four E-CORE-005 sites in the above census had non-canonical message text (did not match `Validation failed for '<field>': <reason>` taxonomy format): BC-2.04.002 EC-003 (`"unknown durability tier: \"<value>\""` → `"Validation failed for 'durability': unknown tier \"<value>\""`); BC-2.04.007 EC-003 (`"EncryptedSerializer: key material must be non-empty"` → `"Validation failed for 'key_material': must be non-empty"`); BC-2.08.002 EC-005 (`"model <name> does not support tool calling"` → `"Validation failed for 'model': model '<name>' does not support tool calling"`); BC-2.08.006 EC-002 (`"timeout must be set; use .timeout(Duration::from_secs(30))"` → `"Validation failed for 'timeout': must be set; use .timeout(Duration::from_secs(30))"`). Additionally, BC-2.08.014 EC-006 was not in this census (EC-006 was authored in a later burst) but was discovered by the F-P112-02 corpus-wide sweep: `"ProviderFallbackPolicy.chain must not be empty"` → `"Validation failed for 'ProviderFallbackPolicy.chain': must not be empty"`. All five sites now conform. BC versions bumped: BC-2.04.002 v1.3, BC-2.04.007 v1.6, BC-2.08.002 v1.4, BC-2.08.006 v1.4, BC-2.08.014 v1.3. See bc-authoring-plan v2.39 and error-taxonomy.md v1.26 for adjudication record.

    New codes minted this burst: E-PROV-008, E-CORE-007, E-CHKPT-007 (see error-taxonomy.md v1.8).

    Source: ADV-P1D-PASS-56 §F-P56-01 (motivating instance); §OBS-P56-2 [process-gap]; ADV-P1D-PASS-56-COMPLETION (drain burst).

31. **Trait-signature type-resolution census gate — TRAIT-SIGNATURE TYPE-RESOLUTION CENSUS
    (added P58 — standing gate [process-gap]):**

    Any burst that edits the `§Public Rust Trait Signatures` block of `interface-definitions.md`
    (adding or removing a method, changing a param/return type, adding an inline enum definition)
    MUST run the trait-signature type-resolution census before the burst closes.

    **Definition:** Every concrete type identifier named in any Public Rust Trait Signatures block
    (params, returns, enum variants and their inner types) that is NOT:
    (a) a Rust-standard/external crate type (`Stream`, `DeserializeOwned`, `serde_json::Value`, etc.), OR
    (b) a trait-level generic parameter (`Input`, `Output`, `T`, `NextOutput`, etc.)
    MUST have a definition site in the spec corpus: inline in the §GuardrailHook (or relevant) section,
    an entities shard (`entities-graph.md`, `entities-server.md`), or a BC body.

    **Census procedure:**
    1. Extract every type name from the 5 trait blocks and their inline enum definitions.
    2. Classify each as: (a) generic param → exempt; (b) external Rust type → external; (c) corpus type → check.
    3. For each corpus type, locate its definition site. If none found: flag as UNRESOLVED and either
       (a) add a minimal inline definition or type note in the same burst, or
       (b) document as implementer-scope with a gate #31 note and flag for architect.
    4. **Name-equality check (added P60 — OBS-P60-1 widening; extended P61 — D18-P61-B):** For each
       corpus type that is RESOLVED via a BC citation, assert that the identifier name used in the
       interface block exactly equals the identifier name in the cited authority BC. A definition that
       exists in the corpus under a different name (i.e., interface block uses `BudgetDecision`, BC
       uses `PolicyDecision`) is NOT a valid resolution — it is a HIGH-severity name-drift finding.
       Definition-existence alone is insufficient; name equality is required.
       Motivating instance: F-P60-01 — `BudgetDecision` was marked RESOLVED because an inline
       definition existed in the interface block, while all four ss-10 BCs used `PolicyDecision`.
       The drift survived pass-58 and pass-59 undetected because step 3 checked only existence.

       **Extended step 4 (near-name corpus check — added P61 — D18-P61-B):** For each type
       classified as UNRESOLVED after step 3, the census MUST also check whether the corpus
       contains a near-name concept that plays the same structural role before finalizing the
       UNRESOLVED classification. A near-name concept is: an identifier in a BC body or entity
       definition that has semantically equivalent contents and the same functional role, even if
       the name differs (e.g., `BudgetContext` vs `RunContext` — same fields, same role, different
       name minted without corpus search). If a near-name concept exists: (a) the interface block
       identifier is a name-drift finding (HIGH severity), (b) the near-name identifier is the
       RESOLVED canonical, and (c) the interface block identifier is retired via gate #19.
       Motivating instance: F-P61-02 — `BudgetContext` was classified UNRESOLVED because that
       exact string was not in the corpus; step 3 did not ask "Is there a corpus type with these
       same contents under a different name?" BC-2.10.001 precondition 3 named `RunContext` with
       identical fields (thread_id, run_id, sub-agent identity) — the near-name check would have
       caught this immediately.

    **Current pass-60 census results (`interface-definitions.md` v2.15):**

    | Type | Trait | Definition Site | Status |
    |------|-------|----------------|--------|
    | `RunnableConfig` | Runnable | entities-graph.md §CheckpointTuple (`config: RunnableConfig`) | RESOLVED |
    | `PregolyaError` | Runnable, CheckpointSaver | entities-server.md §PregolyaError | RESOLVED |
    | `Message` | BaseChatModel | entities-graph.md §Message | RESOLVED |
    | `AiMessage` | BaseChatModel | BC-2.01.002 (full field spec: content, tool_calls, usage_metadata, id, name) | RESOLVED |
    | `ChatConfig` | BaseChatModel | NOT IN CORPUS — implementer-scope (provider-specific overrides: temperature, max_tokens, …); flagged for architect | UNRESOLVED |
    | `AiMessageChunk` | BaseChatModel | BC-2.08.001 PC1 + BC-2.08.005 TV (streaming completions) | RESOLVED |
    | `ToolDefinition` | BaseChatModel | BC-2.08.009 (tool schema naming stability BC; entire BC governs ToolDefinition) | RESOLVED |
    | `CheckpointConfig` | CheckpointSaver | NOT IN CORPUS — logically derived: `{ thread_id, checkpoint_ns, checkpoint_id }` per BC-2.04.006 triple-address; flagged for architect | UNRESOLVED |
    | `ChannelName` | CheckpointSaver | entities-graph.md §GraphState (`Map<ChannelName, ChannelValue>`) | RESOLVED |
    | `ChannelValue` | CheckpointSaver | entities-graph.md §GraphState | RESOLVED |
    | `TaskId` | CheckpointSaver | VP-001.md Kani harness sketch (`TaskId(i as u64)` — newtype around u64) | RESOLVED |
    | `CheckpointTuple` | CheckpointSaver | entities-graph.md §CheckpointTuple | RESOLVED |
    | `IngressContent` | GuardrailHook | inline §GuardrailHook (interface-definitions.md v2.13 — DEFINED P58) | RESOLVED |
    | `ContentBlock` | GuardrailHook (IngressContent::ToolResult inner) | entities-graph.md §ContentBlock | RESOLVED |
    | `Value` | GuardrailHook (IngressContent::RagChunk / ::MemoryItem inner) | serde_json::Value — external | EXTERNAL |
    | `ProvenanceTag` | GuardrailHook | entities-server.md §ProvenanceTag (v1.3) | RESOLVED |
    | `GuardrailResult` | GuardrailHook | inline §GuardrailHook (interface-definitions.md — defined P57) | RESOLVED |
    | `GuardrailSeverity` | GuardrailHook | inline §GuardrailHook (interface-definitions.md v2.13 — DEFINED P58) | RESOLVED |
    | `TokenUsage` | BudgetPolicy | BC-2.10.001 PC2/PC3 (struct shape: prompt_tokens, completion_tokens, total_tokens, estimated_cost) | RESOLVED |
    | `PolicyDecision` | BudgetPolicy | BC-2.10.001 PC3 (three-variant contract: Allow / Escalate{reason,current_usage} / Deny{reason,current_usage}); inline §BudgetPolicy (interface-definitions.md v2.15 — DEFINED P60) — name-equality verified: BC uses PolicyDecision, interface uses PolicyDecision | RESOLVED |
    | `RunContext` | BudgetPolicy | BC-2.10.001 precondition 3 ("The execution engine has access to the `RunContext` (thread_id, run_id, sub-agent identity if applicable)"); inline §BudgetPolicy (interface-definitions.md v2.16 — DEFINED P61); name-equality verified: BC uses RunContext, interface uses RunContext; fields fully enumerated in pre-3 (thread_id, run_id, sub_agent_id: Option) | RESOLVED |
    | `ToolCall` | ToolCallDialect | BC-2.08.002 (tool-call round-trip conformance — entire BC governs the ToolCall structure: name, arguments, id); name-equality verified: BC-2.08.002 governs ToolCall throughout; interface block uses ToolCall | RESOLVED |
    | `SkillDescriptor` | SkillStore | inline §SkillStore (interface-definitions.md v2.20 — DEFINED D20 sub-burst 2); fields: name: String, namespace: String, key: String, tags: Vec\<String\> | RESOLVED |
    | `MemoryWriteRequest` | MemoryWriteGuard | inline §MemoryWriteGuard (interface-definitions.md v2.20 — DEFINED D20 sub-burst 2); variants: Add\{namespace, key, value\}, Replace\{namespace, key, old\_value, new\_value\}, Remove\{namespace, key\} | RESOLVED |
    | `WriteGuardDecision` | MemoryWriteGuard | inline §MemoryWriteGuard (interface-definitions.md v2.20 — DEFINED D20 sub-burst 2); variants: Allow, Deny\{reason: String\}, Transform\{sanitized: Value\} | RESOLVED |
    | `BudgetInfo` | BudgetPolicy (via RunContext.budget\_info) | inline §BudgetPolicy (interface-definitions.md v2.21 — DEFINED D20 TOUCH-UP); fields: tokens\_remaining: Option\<i64\>, steps\_remaining: Option\<u32\>; authority BC-2.10.003 PC5/INV/TV-007; name-equality verified | RESOLVED |
    | `ProviderCredential` | ProviderFallbackPolicy | NOT IN CORPUS — implementer-scope (provider-specific credential shape differs per provider: API key, OAuth token, etc.); flagged for architect | UNRESOLVED |
    | `CredentialRefreshConfig` | ProviderFallbackPolicy | NOT IN CORPUS — implementer-scope (callback/config for automatic credential refresh on auth failure); flagged for architect | UNRESOLVED |

    > **Retired from BudgetPolicy rows (P60):** `RunId` (no longer in trait — removed from 3-param to 2-param sig), `EvidenceJournal` (no longer in trait — journal writes are caller responsibility per BC-2.10.001 INV + ADR-009), `BudgetDecision` (renamed to PolicyDecision — see gate #19 retired-identifier table).
    > **Retired from BudgetPolicy rows (P61):** `BudgetContext` (renamed to RunContext per BC-2.10.001 pre-3 canon — see gate #19 retired-identifier table; near-name blindspot F-P61-02).

    **Census verdict:** 24/28 types resolved; 4 unresolved (ChatConfig, CheckpointConfig, ProviderCredential, CredentialRefreshConfig) — flagged
    implementer-scope for architect; do NOT block spec publication. (28 rows: 23 RESOLVED + 1 EXTERNAL [Value, exempt] + 4 UNRESOLVED = 28 ✓; prior verdict "25/28" was wrong on both counts — table had 27 rows before BudgetInfo addition, and numerator 25 was incorrect arithmetic; corrected in D20 TOUCH-UP burst.)

    **Census trigger:** Any burst that edits `interface-definitions.md` §Public Rust Trait Signatures
    (new method, type rename, inline enum addition or removal) + every adversary rotation.

    **Motivating instances:**

    - **(OBS-P58-1, ADV-P1D-PASS-58):** F-P57-01 (pass-57) removed `GuardrailError`
      (correct — not in corpus) but introduced `IngressContent` and retained `GuardrailSeverity` as
      referenced-but-undefined types. Both survived one full pass (pass-57 → pass-58) because no census
      extracted and resolved every type in the trait block. Gates #15 (harness-fn) and #30 (codeless-error)
      cover named identifiers in BC bodies; this gate closes the parallel gap for trait-signature identifiers
      in prd-supplements.

    - **(OBS-P60-1, ADV-P1D-PASS-60):** `BudgetDecision` was marked RESOLVED in the census table because
      an inline definition existed in the interface block. However, the cited authority (BC-2.10.001–004) used
      `PolicyDecision` throughout. The old step 3 (definition-existence) passed; the new step 4 (name-equality)
      would have caught this. This is the motivating instance for the original step 4 addition.

    - **(F-P61-02, ADV-P1D-PASS-61):** `BudgetContext` was classified UNRESOLVED because that exact
      string was not in the corpus. However, BC-2.10.001 precondition 3 named `RunContext` with
      identical contents (thread_id, run_id, sub-agent identity) — the near-name concept was already
      present. The pass-60 fix burst minted `BudgetContext` without running a near-name corpus search.
      The old step 4 covered name-equality for RESOLVED types; it did not cover near-name checks for
      UNRESOLVED types. This is the motivating instance for the step 4 near-name extension (D18-P61-B).

    Source: ADV-P1D-PASS-58 §OBS-P58-1 [process-gap]; ADV-P1D-PASS-60 §OBS-P60-1 [process-gap]; ADV-P1D-PASS-61 §F-P61-02.

32. **ADR-propagation census gate — ADR-PROPAGATION CENSUS
    (added P61 — standing gate [process-gap, OBS-P61-1]):**

    Any burst that accepts or amends an ADR that makes a **crate-placement or type-home decision**
    (i.e., declares which workspace crate owns a trait, type, module, or file) MUST reconcile
    that placement decision against the four BC-layer carriers IN THE SAME BURST:

    **Five required carriers:**

    1. **module-decomposition.md** — scope lines for the affected subsystem(s); module rows/notes;
       crate ownership columns. A crate assignment in the ADR must appear in the corresponding
       module-decomposition row.

    2. **Every affected BC's Architecture Anchors section** — each BC that names a type or file
       owned by the decided crate must have its Architecture Anchors updated to cite the correct
       crate path per the ADR. "Affected BC" = any BC whose Architecture Anchors currently cite
       the old crate OR any BC whose domain directly concerns the decided type/trait.

    3. **interface-definitions.md §Public Rust Trait Signatures section headers** — any section
       that names a trait or type whose home crate was decided by the ADR must have its
       implementation note, crate reference, or doc-comment updated to reflect the ADR placement.

    4. **`.factory/specs/module-criticality.md` (arch registry)** — if the ADR
       introduces a new module or changes crate placement for a module, the arch-registry
       criticality table must reflect the module with its correct crate and tier. A module added
       by an ADR that does not appear in the arch registry is a gate #32 + gate #25 violation.

       **Definitions-only exception (F-P171a-08, burst-273; revised F-P172a-04, burst-274-B):**
       A module that hosts ONLY type/trait definitions with no execution logic — no algorithmic
       computation, no I/O, no method bodies beyond trivial derives — does NOT require a
       criticality row in the arch registry. **Rationale:** modules hosting ONLY type/trait
       definitions have no algorithmic failure modes to tier-classify; a criticality tier is
       meaningful only when there are runtime code paths whose failure would propagate to users.
       (Note: `core::budget` holds the `BudgetPolicy` trait and associated types AND has a
       criticality row — `core::budget` is NOT a precedent for no-row; it is a properly-tiered
       module with algorithmic execution paths in the budget engine.)
       Established definitions-only exempt cases: `core::context_mutation`, `core::write_guard`,
       `core::guardrail`, `core::action_risk`, `core::documents`. For each exempt module, the
       authoritative placement record is `purity-boundary-map.md` §Pure Core AND a definitions
       note in the corresponding `module-decomposition.md` subsystem row.

       **Routing-overlay exception (F-P172a-04, burst-274-B):** A module whose architectural
       role is routing/discovery overlay over another module's storage or execution backend —
       with no execution-business-logic of its own — also does NOT require a criticality row.
       Established routing-overlay exempt case: `memory::skills`. This module provides
       routing/discovery over the MemoryStore KV backend (load_skill, list_skills, skill_exists
       I/O bound to MemoryStore) but owns no algorithmic business logic; it is classified as
       Effectful Shell in `purity-boundary-map.md` (async SkillStore I/O), NOT Pure Core — so
       it fails the definitions-only criterion. The routing-overlay exception applies instead.
       For a routing-overlay exempt module: a structural decomposition row in
       `module-decomposition.md` is required; a criticality row in `module-criticality.md` is
       NOT required.

       **Architect adjudication confirmed (F-P172a-04 — resolved FIX-BURST-274):** `core::documents`
       is definitions-only exempt. Classification evidence: ADR-014 Decision 2 explicitly states
       "No I/O. Pure data carrier. Pure Core classification." — the struct has only `page_content`,
       `metadata`, and `id` fields with derived impls; no execution methods; no VP target. Pattern
       matches `core::guardrail`, `core::action_risk`, and `core::write_guard` (definitions-only
       precedent). Definitions note added to the `core::documents` row in `module-decomposition.md`;
       Criticality column changed from MEDIUM to `—`. No criticality row required.

       **Narrow scope — neither exception applies to:** `tools::config` (contains
       `ToolConfig::override_risk` validation logic — MEDIUM criticality tier), and any other
       module with non-trivial method bodies, side effects, or algorithmic logic. When in doubt,
       create the criticality row; the exceptions are for obvious pure-definitions or pure-routing
       modules only.

    5. **`.factory/specs/prd-supplements/module-criticality.md` (PO registry — SUPERSEDED, FROZEN)**
       — this file is `status: superseded` (22-module pre-D21/D23 view, audit trail only).
       Do NOT sync it. Routing ADR placement changes to this file is prohibited — it is permanently
       frozen. Any new ADR module addition need only appear in the FOUR live documents listed above
       (items 1–4). (OBS-P72 historical context: D20 ADR-012/ADR-013 modules were the motivating
       instance; the PO registry was superseded at Phase 1b under F-P165-06 adjudication.)

    **Census procedure:**
    1. Read the ADR's placement statement(s) (e.g., "X lives in pregolya-core/src/budget.rs").
    2. Run: `grep -rn "<type_name>\|<trait_name>" .factory/specs/behavioral-contracts/` to find
       every BC Architecture Anchor that references the type.
    3. For each hit: verify the crate path matches the ADR placement. A mismatch is a HIGH-severity
       anchor-drift finding.
    4. Check module-decomposition.md rows for the affected subsystem — verify crate assignment
       matches the ADR decision.
    4a. Check `.factory/specs/module-criticality.md` (arch registry, carrier 4) — if the ADR
       introduces a NEW module or re-places an EXISTING module, verify or add the module row
       with the correct crate and tier. Apply the definitions-only exception (modules hosting
       ONLY type/trait definitions with no execution logic) or the routing-overlay exception
       (modules whose role is routing/discovery overlay over another module's backend with no
       execution-business-logic) if appropriate — see carrier 4 exceptions above. If the module
       qualifies for an exception, no criticality row is required; document the exception in
       module-decomposition.md instead. If no exception applies, a missing row is a HIGH-severity
       gate #32 + gate #25 violation.
    4b. **Positive-Coverage Assertion (OBS-P172b-B/burst-275; Class A/B fix/burst-275B;
       registry-rows-vs-distinct-modules/burst-275C; gate-semantics-fix/burst-276-wave-A) —
       BLOCKING:** After completing step 4a for this ADR's modules, record the following census
       tuple in the burst's Form A frontmatter changelog entry. All definitions, exempt classes,
       crate-level annotation verification, and blocking identities follow gate #25 Part B/C
       exactly — this step is the gate #32 mirror of that gate.

       `(decomposition_per_section_vector, decomposition_total_rows, decomposition_tiered_rows, exempt_count, class_a_row_count, registry_rows, roll_up_row_count, registry_census_rows, registry_distinct_modules, matched_rows)`

       **Blocking identity 0 (per-section sum):**
       `sum(decomposition_per_section_vector) == decomposition_tiered_rows`

       **Blocking identity 1 (universe total):**
       `decomposition_total_rows == decomposition_tiered_rows + exempt_count`
       Detects arithmetic slips and malformed Criticality cells only — see gate #25 identity 1
       annotation for what this does NOT detect.

       **Blocking identity 1a (Class A absence):**
       `class_a_row_count == 0`

       **Blocking identity 1b (Class B membership — set equality):**
       `{rows with Criticality —} == {core::documents, memory::skills}` exactly.

       **Blocking identity 2 (matching completeness — SET INTERSECTION required):**
       `matched_rows == decomposition_tiered_rows`
       The difference set `{decomposition_tiered_module_names} \ {registry_Module_cell_values}`
       MUST be reported inline and MUST be empty. Prose-asserting the count without the
       difference set is PROHIBITED.

       **Blocking identity 3 (registry uniqueness over composite key):**
       For every pair of rows where `row_i.Module == row_j.Module`, the pair
       `(row_i.Module, row_i.Qualifier) != (row_j.Module, row_j.Qualifier)` MUST hold.

       All members MUST be independently derived from the named artifacts in THIS burst —
       never copied from a prior burst or mirrored from a sibling document. `exempt_count` MUST
       be obtained by counting `—` Criticality rows, not by list length; cross-check against
       Class B name list — disagreement is a HIGH-severity finding. `registry_rows` is the
       unconditional total; `registry_census_rows = registry_rows − roll_up_row_count`.
       Per-section vector (identity 0) required inline.
    5. Check interface-definitions.md §Public Rust Trait Signatures for any section header or
       doc-comment citing the old crate — update to the new placement.

    **Trigger:** ADR acceptance or amendment that contains a crate-placement statement.
    **Scope:** All BCs under the affected subsystem (SS-NN) plus any BCs that explicitly anchor
    to the affected crate path.

    **Motivating instance:** ADR-009 Option-3 placed `BudgetPolicy` trait + `PolicyDecision` +
    `TokenUsage` + `RunContext` in `pregolya-core/src/budget.rs`. This decision was not
    reconciled against BC-2.10.001/003 Architecture Anchors, which continued to cite
    `pregolya-graph/src/budget/policy.rs`. The mismatch survived pass-60 undetected because
    no census compared ADR placement statements against BC Architecture Anchors. Caught by
    pass-61 adversary F-P61-01.

    Source: ADV-P1D-PASS-61 §OBS-P61-1 [process-gap].

33. **Taxonomy anchor reverse-verification census gate — TAXONOMY ANCHOR REVERSE-VERIFICATION CENSUS
    (added P66 — standing gate [process-gap, OBS-P66-1]):**

    Every live (non-tombstone) error code row in `error-taxonomy.md` carries a **BC Anchor** column
    that declares which behavioral contract is the home for that code's raise condition.
    Gate #30 (codeless-error census) is the *forward* axis — BC bodies must cite catalogued codes.
    Gate #33 is the **reverse** axis — for every live taxonomy code, the declared BC Anchor body
    must contain the error code string (e.g., `E-CHKPT-003`) or variant name
    (e.g., `CheckpointReadFailed`) with a **specified raise condition** (an EC-NNN, TV row, or
    postcondition that describes when the code is raised).

    A code that passes gate #30 (every BC construction has a code) can still fail gate #33 if the
    declared anchor BC never constructs that specific code. These two gates are logically independent.

    **Census procedure:**

    1. Open `error-taxonomy.md` and enumerate every live (non-tombstone) row with a BC Anchor cell.
    2. For each row, extract the BC Anchor ID (e.g., `BC-2.09.005`).
    3. Run: `grep -l "E-<COMP>-NNN\|<VariantName>" .factory/specs/behavioral-contracts/<anchor-path>/` to
       confirm the code string or variant name appears in the BC body.
    4. Verify the hit is not merely a changelog/retired-identifier mention — it must appear in an
       EC-NNN, TV table row, postcondition, or invariant body as a raise condition.
    5. If no raise condition is found: the code is an **OBS-P28-2 class orphan** (anchor declared but
       BC body never constructs the error) — HIGH-severity finding.
    6. If the declared BC Anchor is wrong scope for the code's raise path (e.g., wrong subsystem
       lifecycle phase): **re-anchor** the taxonomy row to the correct BC and add EC/TV to that BC.

    **Census command (automated pre-check):**
    ```
    # For each live taxonomy row, check that the BC Anchor body contains the code or variant name.
    # Run from repo root. Outputs: code, anchor BC, grep result (non-empty = PASS).
    # Column map (awk -F'|'): $1=leading-empty $2=Error-Code $3=Category $4=Severity $5=BC-Anchor $6=Message-Format
    grep -h "^| E-" .factory/specs/prd-supplements/error-taxonomy.md | grep -v "~~" | \
      awk -F'|' '{code=$2; anchor=$5; gsub(/ /,"",code); gsub(/ /,"",anchor); print code, anchor}'
    # Then for each (code, anchor) pair, resolve the primary anchor (strip secondary annotations)
    # and use find or ss-*/ glob to locate the BC file:
    #   find .factory/specs/behavioral-contracts -name "${primary_anchor}.md" | xargs grep -l "$code"
    # OR: ls .factory/specs/behavioral-contracts/ss-*/${primary_anchor}.md 2>/dev/null | xargs grep -l "$code"
    # shopt -s globstar is NOT required when using the ss-*/ single-directory wildcard.
    # Multi-anchor cells (comma-separated BCs) require checking each primary anchor independently.
    ```

    **Scope:** All live taxonomy codes (non-tombstone rows). Tombstone rows (~~strikethrough~~) are
    excluded — a retired code has no behavioral home obligation.

    **Trigger:** Every taxonomy edit (add, modify, re-anchor, or tombstone any row) AND every
    adversary rotation where the new adversary uses the BC-Anchor reverse-verification lens.

    **Pass threshold:** 100% of live codes must have at least one raise condition in their declared
    BC Anchor body. Zero orphans permitted.

    **Motivating instances:**
    - **F-P66-03 (HIGH):** E-SERVER-005 `CorsRejected` — taxonomy declared `BC-2.12.005` as anchor
      and listed it in the interface-definitions 403 row, but BC-2.12.005 PC2/TV-001 specifies CORS
      denial as silent header-omission (no error body ever emitted). The code was never raised
      anywhere. Resolution: RETIRE E-SERVER-005; tombstone row; 403 row updated; census 79→78.
    - **F-P66-02 (MED):** E-CHKPT-003 `CheckpointReadFailed` — taxonomy declared `BC-2.04.005`
      as anchor, but BC-2.04.005 PC1 only reads checkpoints without specifying the read-failure raise.
      Resolution: Added EC-006 + TV to BC-2.04.005 (this burst).
    - **F-P66-01 (MED):** E-MCP-003 `McpNotImplemented` — taxonomy declared `BC-2.09.005`
      (lifecycle / no-live-connections scope), which has no tools/list invocation surface. Zero
      corpus hits. Resolution: Re-anchored to BC-2.09.001 (tool discovery path — first MCP method
      invoked); added EC-006 + TV-008 to BC-2.09.001 (this burst).

    **Post-fix gate #33 census (ADV-P1D-PASS-66):** 78/78 live codes anchored. 100% PASS.

    **SEMANTIC-AGREEMENT sub-check (D18-P77-B, F-P77-01):**
    Presence-verification (steps 1–6 above) is necessary but not sufficient. A code whose string
    appears in its anchor BC can still contradict that BC if the taxonomy row's Message Format
    template or raise-condition annotation diverges semantically from the BC's authoritative
    `message:` string and EC/TV trigger conditions.

    Extended procedure (performed on every taxonomy edit, in addition to steps 1–6):

    7. For each live row, open the declared BC Anchor and locate: (a) the authoritative `message:`
       string for the code (in a postcondition, EC-NNN, or TV table row that first defines the
       message text), and (b) the EC/TV trigger conditions (the scenario under which the code is
       raised).
    8. Compare the taxonomy row's **Message Format** column against the BC's authoritative message
       text. The taxonomy row must reproduce the exact template (or a faithful parameterized form
       using `<placeholder>` syntax); it must not substitute a different description.
    9. Compare the taxonomy row's raise-condition annotation (inline text after the message
       template) against the BC's EC-NNN and TV trigger conditions. The annotation must name the
       same triggering predicate (e.g., "contains `*` or `?`") as the BC's EC/TV body.
    10. On any semantic divergence: **the BC wins** — the taxonomy row is corrected to match the BC.
        The BC body is never modified to match a stale taxonomy row.
    11. **Omission-note citation verification (D18-P78-B, F-P78-02/03):** For every named
        individual omission note in `interface-definitions.md` that cites a BC with a specific
        PC-N or EC-N pointer (e.g., "BC-2.08.013 PC4/EC-002"), verify that each cited PC/EC is
        a **raising path** for the code — i.e., the postcondition or edge case actually
        constructs `Err(E-xxx-NNN)`. Citing a success-path PC (one that returns `Ok(...)` or
        proceeds without error) is a violation. Census command: for each omission-note anchor
        "BC-S.SS.NNN PCn/ECn", open the BC and confirm that every cited PC and EC explicitly
        raises the code in its Expected Behavior. Success-path citations must be replaced with
        the correct raising PC/EC. Motivating instances: F-P78-02 (E-PROV-010 cited PC4 = ordered
        chain semantics / EC-002 = credential-refresh success; correct = PC5 / EC-004) and
        F-P78-03 (E-PROV-009 cited PC4 = NativeAnthropic success-parse; correct = PC8/PC9/EC-002).

    **STRUCT-PLACEHOLDER PARITY CENSUS (D18-P108-04, F-P108-04 [process-gap]):**

    Presence-verification (steps 1–6) and semantic-agreement (steps 7–11) are necessary but
    not sufficient. A code whose taxonomy message format uses N distinct dynamic placeholders
    must be renderable from N independently-accessible fields in the variant struct. A single
    "catch-all" field that embeds multiple placeholder values (e.g., `last_error:
    "E-PROV-008/provider-b"` combining `<last_error_code>` and `<last_provider>`) or an
    intra-BC field-name inconsistency (e.g., `{ source: <reason> }` in PC4 but `{ message:
    "EncryptionKeyRotationFailed: ..." }` in PC5) silently prevents the canonical message from
    being constructed from struct fields alone.

    Extended procedure (performed AFTER steps 7–11, on every BC error-struct-site edit and
    once per adversarial pass touching error semantics):

    **Step A — Enumerate all struct-shorthand sites:**
    ```
    # Form 1: Err( with brace-open struct shorthand
    grep -rn 'Err(E-' .factory/specs/behavioral-contracts/ --include="*.md" \
      | grep '{' | grep -v "~~\|changelog"
    # Form 2: variant-name followed by brace (catches non-Err( forms)
    grep -rn 'E-[A-Z]*-[0-9]\{3\}[[:space:]][A-Z][A-Za-z]*[[:space:]]*{' \
      .factory/specs/behavioral-contracts/ --include="*.md" | grep -v "~~\|changelog"
    # Form 3: PregolyaError wrapper construction (code appears as `code:` field inside struct)
    # Step 3a — single-pass for wrapper sites missing `message:` on the same line:
    grep -rn 'PregolyaError {' .factory/specs/behavioral-contracts/ --include="*.md" \
      | grep 'code:' | grep -v '~~\|changelog' | grep -v 'message:'
    # Step 3b — false-positive check: a line flagged by Step 3a but with `message:` on the
    # continuation (next) line is NOT a violation — it is a multi-line struct with a valid
    # message field. Manually inspect the line immediately following each Step 3a hit before
    # recording it as a violation.
    ```
    Collect the complete list of `(code, file, line)` tuples where a struct shorthand
    (`VariantName { field: value, ... }`) or wrapper form (`PregolyaError { .., code: E-xxx-NNN, .. }`)
    appears.

    **Wrapper-form discipline (applies to all Form 3 sites):** A bare wrapper
    `PregolyaError { category: X, code: E-YYY-NNN, .. }` with NO `message:` field is ONLY
    valid for codes whose taxonomy Message Format contains NO `<placeholder>` tokens (fixed
    message strings). For codes with one or more taxonomy placeholders, the struct MUST include
    one of:
    - **(a) Inline `message:` template** — e.g., `message: "Foo: bar '<placeholder>'"` with
      the placeholder token(s) shown verbatim so the reader can trace each to its source at
      the raise site.
    - **(b) Explicit individual struct fields** — e.g., `{ code, field_a, field_b }` where
      `field_a` and `field_b` satisfy Step B check 2 (field set is a SUPERSET of all distinct
      taxonomy placeholders, with registered semantic aliases permitted).
    - **(c) Registered context-sourced exception** — see the context-sourced exception
      registry in Step B check 2; the BC must name the context object and the placeholder
      mapping.
    A bare `{ category, code }` wrapper that has taxonomy placeholders and satisfies none of
    (a), (b), or (c) is a Step B check 2 FAIL regardless of Form 1/2 verdict for the same code.

    **Step B — Per-code assessment (three checks):**

    1. **Intra-BC/intra-corpus field-name consistency:** all sites for the same variant across
       ALL anchor BCs listed in the taxonomy BC-Anchor cell for the code must use identical
       field names. **"Intra-corpus" means EVERY struct site in every BC the taxonomy anchors
       this code to (primary AND secondary anchors) — not just within a single BC file.**
       If `{ source: ... }` appears in PC4 of BC-A but `{ message: "..." }` in PC5/EC/TV of
       BC-A, or if the primary anchor BC uses 3-field form `{ requested, resolved, root }` but
       a secondary anchor BC uses 2-field form `{ resolved, root }`, one site is wrong. BC-wins
       rule: the PRIMARY anchor's most authoritative construct (TV/EC over PC description prose)
       determines the canonical field name and field count; update ALL diverging sites in ALL
       anchor BCs. The root cause of pass-110's F-P110-02 was that the TD-VSDD-060 sweep was
       anchored "in file" rather than "across ALL anchor BCs" — E-SBXD-001 BC-2.13.004 (secondary
       anchor) diverged from BC-2.13.005 (primary anchor, canonical 3-field form) because the
       sweep never checked the secondary anchor. This cross-anchor scope is mandatory.

    2. **Placeholder coverage:** collect the DISTINCT dynamic placeholders from the taxonomy
       Message Format (`<placeholder>` tokens). The struct field set must be a SUPERSET of
       those placeholders. Known semantic aliases are acceptable and must be noted:
       - `step` ↔ `<n>` (super-step counter)
       - `node` ↔ `<node_id>` (graph node identifier)
       - `thread_id` ↔ `<run_id>` (in interrupt context — a run is identified by its thread)
       - `transport_error` ↔ `<transport_error>` (transport failure detail)
       - `offset` ↔ `<n>` (E-PROV-009 — byte offset in dialect parse error)
       - `providers_attempted` ↔ `<N>` (E-PROV-010 — abbreviation; tried-count)
       - `backend_error` ↔ `<reason>` (E-MEMORY-005 — storage backend failure detail)
       - `message` ↔ `<reason>` (E-CHKPT-004 CODE-SPECIFIC — the entire constructed error
         message string is the reason; taxonomy corrected to bare `<reason>` per v1.16 BC-wins
         rule; field renamed from `source` to `message` in v1.22; do NOT apply this alias to
         other codes where `message` maps to a `<message>` taxonomy placeholder)
       A single catch-all field that embeds MULTIPLE placeholder values mid-string is NOT
       acceptable when the taxonomy has more than one distinct placeholder (the message cannot
       be reconstructed from fields with independent variable positions). A trailing catch-all
       `reason` is ONLY acceptable when: (a) the taxonomy has exactly ONE remaining placeholder
       at the TRAILING position of the message, and (b) all preceding placeholders already have
       dedicated struct fields. The accepted trailing catch-all instances are:
       E-CHKPT-003 `{ thread_id, checkpoint_id, reason }`, E-MCP-005 `{ transport, reason }`,
       E-SBXD-003 `{ reason }` (static prefix + single trailing placeholder).

       **Context-sourced placeholder exception:** For errors where taxonomy placeholders
       are sourced from a named context object at the raise site, the struct may omit those
       fields without failing check 2 if and only if: (a) the BC explicitly names the
       context object as the placeholder source, (b) the placeholder is deterministically
       available at the raise site via that context (no runtime computation or I/O required),
       and (c) this exception is registered by error code below. Currently registered
       context-sourced exceptions:
       - **E-MEMORY-007** — `<ns>` and `<key>` sourced from `MemoryWriteRequest.namespace`
         / `.key`.
       - **E-CORE-007** — `<boundary>` sourced from `ProvenanceTag.boundary_type` (available
         as the `provenance_tag` argument to `GuardrailHook::evaluate()`); `<content_type>`
         sourced from the `IngressContent` variant discriminant (available as the `content`
         argument) and renders as the **BARE variant name** per interface-definitions.md §GuardrailHook
         (authoritative definition; F-P112-01 adjudication; IngressContent enum defined inline under §GuardrailHook). Both are deterministically available
         at the panic catch site — no runtime computation or I/O required. BC-2.11.002 names
         `BoundaryType::ToolResult` / `"ToolResult"`; BC-2.11.003 names `BoundaryType::RAGRetrieval` /
         `"RagChunk"`; BC-2.11.004 names `BoundaryType::MemoryIngress` / `"MemoryItem"`.

       **Abbreviation acceptance (PASS-ABBREV):** A TV row using `{ field_a, field_b, ... }`
       where `...` replaces one or more trailing fields PASSES check 2 only if a non-TV
       (PC or EC) full-struct site exists in the same BC that explicitly names all fields.
       When TV-row abbreviation is the SOLE struct-bearing site for a code in the BC, the
       `...` form is a FAIL — the TV row must list all fields explicitly.

    3. **No-hardcoded-value check in general-case EC/PC:** where the BC parameterizes a field
       (e.g., `<key_id>`), the struct field must not use a hardcoded value in a general-case
       EC or PC; only concrete test-vector examples may use concrete literals.

    **Step C — Output the per-code TABLE (MANDATORY; prose completeness claims are INVALID):**

    | Code | Variant Name | BC Sites (file:line) | Struct Fields | Taxonomy Placeholders | Semantic Aliases Noted | Step-B Verdict |
    |------|-------------|---------------------|---------------|----------------------|-----------------------|----------------|

    A **PASS** verdict means all three Step B checks pass for every site of that code.
    A **FAIL** verdict means at least one check fails; the failing site(s) must be fixed in
    the same burst.

    **Trigger:** Any edit to a BC error-struct site (add, rename, or remove a field), any
    taxonomy Message Format edit, and once per adversarial pass touching error semantics.

    **Completeness gate:** The census result is only valid if Step A was run with both grep
    commands and ALL codes with at least one struct-shorthand site are included in Step C.
    A census table missing any code from Step A output is INCOMPLETE and the completeness
    claim is invalid.

    **Motivating instances (F-P108-04, ADV-P1D-PASS-108):**
    - **E-PROV-010 ProviderChainExhausted:** v1.20 sweep ("21 PASS") and v1.21 corrigendum
      ("17 PASS") both missed: BC-2.08.014 EC-004 used `{ providers_attempted, last_error }`
      with `last_error: "E-PROV-008/provider-b"` combining two taxonomy placeholders
      `<last_error_code>/<last_provider>` into one field. Step B check 2 detects this:
      taxonomy has 3 distinct placeholders (`<N>`, `<last_error_code>`, `<last_provider>`);
      struct has only 2 fields with one combining two values. Fixed in BC-2.08.014 v1.2.
    - **E-CHKPT-004 EncryptionKeyRotationFailed:** v1.4 prefix-sweep fixed 4 sites but missed
      PC4, which still used `{ source: <reason> }` while PC5/EC-002/TV used `{ message:
      "EncryptionKeyRotationFailed: ..." }`. Step B check 1 (intra-BC consistency) would have
      caught this immediately. Fixed in BC-2.04.007 v1.5.
    - **E-PROV-009 ToolCallDialectParseError:** EC-002 used `{ dialect, reason }` with
      `reason: "JSON parse error at offset N: key must be a string"` — the `N` offset is
      MID-message in the 4-placeholder taxonomy format, so `reason` cannot independently
      render `<element>` and `<n>`. Step B check 2 catches: 4 distinct placeholders in
      taxonomy (`<dialect>`, `<element>`, `<n>`, `<parse_error>`); struct has only 2 fields.
      Expanded to `{ dialect, element, offset, parse_error }` in BC-2.08.013 v1.2.
    - **Root cause of repeated false PASS across 3 bursts:** prior sweeps enumerated struct
      SITES but assessed only "does some struct field exist?" — they did not systematically
      map each taxonomy placeholder to a named struct field. Step B makes this mapping
      explicit and mandatory per site.

    Source: ADV-P1D-PASS-108 §F-P108-04 [process-gap].

    **Motivating instance (F-P77-01, ADV-P1D-PASS-77):** E-SBXD-006 taxonomy row described a
    REGEX model ("is not a valid regex pattern — <reason>"; "fails regex compilation") while
    BC-2.13.007 PC5/EC-003/EC-005/TV-005/TV-006 mandates the EXACT-NAME/WILDCARD model
    ("contains wildcard characters — only exact variable names are supported in v1"; triggered on
    `*` or `?` characters). The divergence violated the DI-010 credential-security boundary
    semantics. Gate #20 (variant name presence) PASSed because the variant name `InvalidEnvAllowlistPattern` is present. Gate #33 steps 1–6 (raise-condition presence) PASSed because
    a raise condition mentioning the code exists. Neither gate verified that the raise-condition
    annotation's predicate agreed with the BC's EC/TV trigger predicate — that semantic gap is
    what steps 7–10 close.

    Source: ADV-P1D-PASS-66 §OBS-P66-1 [process-gap]; extended D18-P77-B (ADV-P1D-PASS-77).

34. **Frontmatter input-hash format-consistency gate — INPUT-HASH FORMAT CONSISTENCY
    (added P87 — standing gate [process-gap, F-P87-02]; D18-P87-B RESOLVED pass-87 fix burst):**

    **Canonical format (D18-P87-B RESOLVED):**
    `compute-input-hash <file>` returns a **7-char truncated MD5** for ALL spec artifacts —
    prd-supplements and BC files alike. The two-format convention documented at minting was
    incorrect: BC files do NOT use 64-char SHA-256. The canonical format is 7-char truncated
    MD5 for all files. The 64-char SHA-256 hashes in older BC files were produced by the manual
    ADV-P1D-PASS-9 §F-P9-02 procedure (a different algorithm); those values are legacy drift,
    not an alternate canonical format.

    | File type | Canonical format | Enforcement |
    |-----------|-----------------|-------------|
    | prd-supplements | 7-char truncated MD5 | `validate-input-hash` hook — blocks non-conforming writes |
    | BC files (`.factory/specs/behavioral-contracts/`) | 7-char truncated MD5 | `validate-input-hash` hook |
    | Architecture files (`.factory/specs/architecture/`) | Under architect authority | Not PO scope |
    | `BC-INDEX.md` | `"[live-index]"` (sanctioned — see below) | State-manager authority; exempt from hash tracking |

    **Sanctioned exception class — `[live-index]` (BC-INDEX.md only):**
    BC-INDEX.md is a state-manager-maintained rolling aggregate of all BC titles, statuses, and
    metadata. It has no stable `inputs:` field (it depends on every BC file by definition) and
    receives targeted row-level edits as BCs are created, modified, or retired. Requiring a
    recomputed hash after every BC change would make every BC authoring burst a two-step cascade.
    The `[live-index]` placeholder is the permanent sanctioned sentinel for this file class.
    Only BC-INDEX.md carries this placeholder; it is not a general escape hatch for other files.

    **Computation tool (all file types):**
    ```
    compute-input-hash <file>
    ```
    The tool reads the `inputs:` frontmatter, computes 7-char truncated MD5 of the content
    manifest, and returns the canonical value.

    **Census commands (drift detection):**
    ```
    # prd-supplements: stored must match compute-input-hash
    for f in .factory/specs/prd-supplements/*.md; do
      computed=$(compute-input-hash "$f" 2>&1)
      stored=$(grep "^input-hash:" "$f" | sed 's/input-hash: "\(.*\)"/\1/')
      [ "$computed" = "$stored" ] || echo "DRIFT: $f stored=$stored computed=$computed"
    done
    # Expected: empty (0 DRIFT)

    # BC files: ALL entries must match compute-input-hash (zero-exception)
    # Sanctioned exceptions: only BC-INDEX.md with "[live-index]" is exempt
    compute-input-hash --scan .factory/specs/behavioral-contracts/
    # Expected: STALE=0 (MATCH equals TOTAL minus 1 for BC-INDEX.md which is excluded by scan)
    ```

    **Trigger:** Every burst that creates or modifies a spec artifact with `inputs:` frontmatter
    + every adversary rotation.

    **Rule (F-P89-01):** Per-file hash values are NEVER recorded in gate text.
    The frontmatter `input-hash:` field is the single source of truth for each file's
    hash value. Gate snapshots record date and PASS/FAIL counts only — never per-file
    hash values. Embedding hash values in gate text produces the same churn class as
    STATE.md-in-inputs: stale on every recompute.

    **Last-run snapshot (non-authoritative — run census commands above for current state):**
    2026-07-17 (pass-89 fix burst): prd-supplements 2/6 MATCH (bc-authoring-plan, nfr-catalog);
    4/6 DRIFT (error-taxonomy, interface-definitions, module-criticality, test-vectors —
    pre-existing from bursts 168-170, requires dedicated hash-sweep burst).
    BC files: 1/95 MATCH (BC-2.08.006 fixed this burst); 94/95 STALE pre-existing.
    BC-INDEX.md: `"[live-index]"` — sanctioned exception, state-manager authority.
    No `[pending state-manager]` placeholders remain.

    **Motivating instance (F-P87-02, ADV-P1D-PASS-87):** Adversary claimed 64-char SHA-256
    was canonical for ALL files. `validate-input-hash` hook blocked the attempted 64-char write
    on test-vectors.md and provided the computed 7-char hash. The two-format hypothesis followed
    from that observation. Pass-87 fix burst resolved: `compute-input-hash` returns 7-char for BC
    files too — a single canonical format applies across all spec artifact types.

    Source: F-P87-02 [process-gap]. Decision: D18-P87-B RESOLVED (single format, 7-char MD5,
    no human adjudication required). `total_standing_gates` 33 → 34.

35. **VP property-body coherence gate — VP PROPERTY-BODY COHERENCE
    (added burst-247/OBS-P146-C — standing gate [process-gap]):**

    Any burst that edits a `VP-NNN.md` file or edits a `verification-architecture.md`
    catalog entry (any VP catalog row or the property description block for a listed VP)
    MUST diff the following three elements between `VP-NNN.md` and the
    `verification-architecture.md` entry for the same VP:

    1. **Property statement** — the formal invariant or safety property being verified.
    2. **Variant/branch coverage** — the set of cases, enum branches, or input classes the
       proof or test covers (e.g., "all `ActionRisk` variants below Medium", "UUID vs
       monotonic checkpoint ID forms").
    3. **Harness sketch** — the Kani harness function signature, fuzz target entry point,
       or proptest strategy outline described in the body.

    **Source-of-truth rule (CLAUDE.md Source-of-Truth Precedence rule 4):** `VP-NNN.md` is
    the authoritative source for all three elements. On divergence,
    `verification-architecture.md` is corrected to match `VP-NNN.md` — never the reverse.
    VP files supersede the prose verification narrative in PRD/architecture for the
    property they cover.

    **Census procedure:**

    1. For every VP that has both a `VP-NNN.md` file and a catalog entry in
       `verification-architecture.md`, open both files.
    2. Extract the property statement from `VP-NNN.md` (typically the H2
       `## Formal Property` or `## Property Statement` section) and from the
       `verification-architecture.md` catalog row or property block.
    3. Extract variant/branch coverage from `VP-NNN.md` (the `## Coverage` or
       `## Variant Coverage` section) and from `verification-architecture.md`.
    4. Extract the harness sketch from `VP-NNN.md` (the `## Kani Harness Sketch` or
       `## Harness` section) and from `verification-architecture.md`.
    5. Compare each pair. Any difference that changes the semantic content (not just
       formatting) is a coherence failure.
    6. On coherence failure: correct `verification-architecture.md` to match `VP-NNN.md`.
       Do NOT modify `VP-NNN.md` to match `verification-architecture.md`.

    **VP-NNN.md internal consistency check (added burst-255/OBS-P154-A):**

    7. When the gate is triggered by a BC-2.17.001 VP-scope bullet edit, the diff MUST
       additionally include a VP-NNN.md INTERNAL consistency check for the cited VP. The
       following four elements must agree with each other AND with the citing BC-2.17.001
       bullet:

       a. **§Proof Method table coverage claims** — the "variants/cases covered" column must
          enumerate the same variant set as the BC-2.17.001 postcondition bullet.
       b. **§Proof Harness Skeleton actual proof-fn inventory** — the harness function names
          and their argument types must cover exactly the variants and paths claimed in the
          coverage column. A proof-fn claiming "covers all N variants" must have N distinct
          callable branches or a parameterized loop over N cases.
       c. **§BC Traceability scope statements** — the VP's cited BC scope (which BCs it
          verifies) must not claim variants that are peeled off upstream (e.g.,
          `PendingHumanApproval` handled by an async wrapper before the sync harness function
          executes).
       d. **§Proof Obligations outcome-type claims** — the expected outcome column for each
          obligation row must match the actual routing postconditions in the citing
          BC-2.17.001 bullet.

       A coverage claim ("covers all N variants") must be backed by an actual harness fn per
       claimed variant OR an explicit peel-off/out-of-scope statement explaining why the
       variant is handled upstream and not by the harness. A coverage claim with no harness fn
       and no peel-off statement is a HIGH-severity gap.

    **Trigger:** Any edit to a `VP-NNN.md` file (property statement, coverage, or harness
    sketch) OR any edit to a VP catalog entry in `verification-architecture.md` OR any edit
    to a VP-scope bullet in `BC-2.17.001.md` (the SS-17 Kani-harness-scope authority for
    VP-001/002/003/009/010/011 — the BC enumerates all VP postcondition bullets and is the
    citing context for VP-NNN.md scope claims).

    **Scope:** All VP files under `.factory/specs/verification-properties/` and all VP
    catalog entries in `.factory/specs/architecture/verification-architecture.md`.

    **Pass threshold:** 100% of VP files with `verification-architecture.md` catalog entries
    must have identical property statement, variant/branch coverage, and harness sketch
    across both documents.

    **Routing note:** Product-owner does NOT edit `verification-architecture.md` (architect
    scope). On finding a coherence failure, route to architect via orchestrator with the
    `VP-NNN.md` text as the authoritative version to propagate. The fix must be dispatched
    and completed in scope — tech-debt deferral is prohibited under the production-grade
    default.

    Source: OBS-P146-C [process-gap]. `total_standing_gates` 34 → 35.

36. **VP↔BC red-gate parity gate — VP↔BC RED-GATE PARITY
    (added burst-248/F-P147-03 — standing gate [process-gap]):**

    **Rule 1 — Mandatory `red_gate:` field on all VP files:**
    Every `VP-NNN.md` file MUST carry an explicit `red_gate:` frontmatter field. The field
    MUST be either `true` or `false` — the field may not be absent, `null`, or any other
    value. A VP file without a `red_gate:` field is a process-gap finding.

    **Rule 2 — `red_gate: true` requires three-way corroboration:**
    A VP file with `red_gate: true` is valid ONLY when ALL THREE of the following hold:

    1. **Anchor BC frontmatter:** The VP's anchor BC (identified by the VP's `anchor_bc:`
       frontmatter field or equivalent) carries `red_gate: true` in its own frontmatter.
    2. **BC-INDEX membership:** The anchor BC appears in the Red Gate table or Red Gate
       column of `BC-INDEX.md`.
    3. **Verifiable `red_gate_source:` citation (anti-fabrication clause):** The VP's
       `red_gate_source:` frontmatter field cites a specific document and section (e.g.,
       `"ADR-018 §Decision 3"`). The citation MUST be quote-verifiable — open the cited
       document and section and confirm the Red Gate mandate is stated there in substance.
       A citation to a document or section that does not contain a Red Gate mandate is a
       fabricated citation and is a HIGH-severity finding.

    **Rule 3 — BC supersedes VP for contract-discipline designations (divergence rule):**
    On any divergence between a VP's `red_gate:` value and its anchor BC's `red_gate:`
    value or BC-INDEX census:

    - **BC frontmatter + BC-INDEX census WIN.** The VP-side value is corrected.
    - **Routing:** VP-side corrections route to architect (architect owns VP files and
      `verification-architecture.md`). BC-side corrections route to product-owner.
    - The divergence is always resolved in favor of the BC contract — VP files record
      the verification obligation; BCs define whether a contract carries Red Gate status.

    **Census procedure:**

    1. List all VP files (individual VP files only; excludes VP-INDEX.md which is an index,
       not a VP, and carries no `red_gate:` obligation):
       `ls .factory/specs/verification-properties/VP-[0-9][0-9][0-9].md`
    2. Check for missing `red_gate:` field across all VP files (index excluded):
       ```
       grep -rL "^red_gate:" .factory/specs/verification-properties/VP-[0-9][0-9][0-9].md
       ```
       Expected: empty output (zero individual VP files missing the field).
       Note: `VP-*.md` glob MUST NOT be used here — it matches `VP-INDEX.md`, which lacks
       `red_gate:` by design (it is a catalog, not a VP). Using `VP-*.md` produces a permanent
       false failure that trains operators to ignore the gate result.
    3. For each VP with `red_gate: true`, verify all three corroboration requirements:
       a. Anchor BC frontmatter: `grep "red_gate:" .factory/specs/behavioral-contracts/ss-NN/BC-S.SS.NNN.md`
          — must return `red_gate: true`.
       b. BC-INDEX membership: `grep "BC-S.SS.NNN" .factory/specs/behavioral-contracts/BC-INDEX.md`
          — confirm the row is in the Red Gate table or carries a Red Gate marker.
       c. `red_gate_source:` citation: open the cited document + section and confirm
          the Red Gate mandate is stated there in substance.

    **Trigger:** Any edit to a `VP-NNN.md` frontmatter `red_gate:` field, any edit to a
    BC frontmatter `red_gate:` field, any edit to the BC-INDEX Red Gate table or
    Red Gate column.

    **Pass threshold:** 100% of VP files carry `red_gate: true` or `red_gate: false`.
    Zero VP files with `red_gate: true` whose anchor BC has `red_gate: false` or whose
    anchor BC is absent from BC-INDEX Red Gate census. Zero `red_gate_source:` citations
    that cannot be verified in the cited document.

    **Motivating instance (F-P147-03, ADV-P1D-PASS-147):** VP-011 carried
    `red_gate: true` with `red_gate_source: "ADR-018 §Mandate B"`. The anchor BC-2.05.007
    carries `red_gate: false`. Architect adjudicated: BC-2.05.007 `false` is correct;
    ADR-018 contains no such mandate — the citation was fabricated. Root cause: no gate
    asserted that (a) VP `red_gate:` must agree with the anchor BC value, (b)
    `red_gate_source:` must be quote-verifiable in the cited document, or (c) every VP
    must carry the `red_gate:` field at all (six VP files lacked it entirely before
    burst-248 architect side). Architect resolved VP-011 and the six missing fields;
    this gate prevents recurrence.

    Source: F-P147-03 [process-gap]. `total_standing_gates` 35 → 36.

37. **Layer-scoped sweep ban — LAYER-SCOPED SWEEP BAN
    (added FIX-BURST-276-WAVE-A — standing gate [process-gap, L-065]):**

    A sweep or de-pin closure statement **may not be layer-scoped**. Three independent P1D-173
    slices converged on this root cause: every sweep in this corpus that declared a layer scope
    left survivors in the layers it excluded. Examples that produced findings:

    - "in this file" → left version pins in sibling documents
    - "in architecture-layer docs" → left version pins in `behavioral-contracts/` and
      `verification-properties/`
    - "Zero live-body ADR version pins remain in `domain-spec/` corpus" → left real survivors
      in `behavioral-contracts/`, `verification-properties/`, and `prd-supplements/`

    In each case the closure statement named a layer, not a predicate, so no reader could
    independently verify whether the excluded layers were truly clean.

    **Rule:** Either the sweep is corpus-wide (and the closure statement records the
    corpus-wide predicate and result), or — if a corpus-wide sweep is genuinely out of scope
    for the burst — the closure statement MUST enumerate every excluded layer as a named
    follow-up obligation with a specific target burst ID. A statement that excludes layers
    without naming them as follow-up obligations is a HIGH-severity process-gap finding.

    **What to record in the closure statement:**
    1. **The sweep predicate** — the pattern, string, or structural property that was searched
       (e.g., `grep -rn "version:" .factory/specs/ --include="*.md" | grep '"[0-9]\+\.[0-9]\+"'`)
    2. **The corpus searched** — either "corpus-wide (all of `.factory/specs/`)" or a named
       subset WITH an explicit enumeration of excluded layers and follow-up burst IDs
    3. **The result** — hit count, file list, or "zero hits"

    **Anti-pattern (PROHIBITED):**
    - "Swept behavioral-contracts/ — zero remaining hits." ← layer-scoped, no follow-up
    - "ADR version pins in domain-spec/ resolved." ← layer-scoped, no follow-up
    - "Corpus-wide de-pin complete." ← claims corpus-wide but lacks predicate or result

    **Required form (one of):**
    - "Pattern `<predicate>` swept corpus-wide across `.factory/specs/`: `<N>` hits found,
      all resolved in this burst." (corpus-wide)
    - "Pattern `<predicate>` swept in `behavioral-contracts/`: `<N>` hits found, all resolved.
      Excluded layers: `prd-supplements/` (follow-up obligation: burst NNN),
      `architecture/` (follow-up obligation: burst NNN)." (layer-scoped with follow-ups)

    **Trigger:** Any burst that includes a sweep, de-pin, or corpus-wide cleanup closure
    statement in its changelog entry or in spec body text.

    **Source:** L-065 [process-gap]; three independent P1D-173 slice convergences.
    `total_standing_gates` 36 → 37.

---

## Changelog

> **Historical record — superseded by frontmatter `changelog:` (Form A).**
> The frontmatter `changelog:` YAML list above is the **authoritative** changelog for this file.
> This body table is preserved as an audit trail only and is intentionally incomplete
> (rows for v2.48, v2.49, v2.52, v2.53, v2.54, v2.55 are absent from this table).
> Do NOT add new entries here. For new changelog entries, use the frontmatter `changelog:` list.
> Form choice adjudicated by F-P172a-14 (burst-274-B, 2026-07-26): Form A preferred because
> it is hook-enforced (`verify-form-a-changelog-direction.sh`) and avoids reconstructing missing rows.

| Version | Date | Change | Source |
|---------|------|--------|--------|
| 2.51 | 2026-07-25 | FIX-BURST 265 (PO share): Gate #27 ARCH-ANCHOR CRATE-RESOLUTION CENSUS updated — stale 18-crate roster replaced with 21-crate ARCH-INDEX §Canonical Crate Roster as source of truth (closes F-P163-01 [process-gap, HIGH]). Rule 1 label updated to cite ARCH-INDEX §Canonical Crate Roster (21 published crates + xtask). Embedded roster relabeled and extended with pregolya-prompts (D21), pregolya-vectorstores (D21), pregolya-tools (D23); disambiguation note added (ADR-007 = original 18-crate topology; ARCH-INDEX = living SoT). Three ownership rules added: prompts::*/injection_guard → pregolya-prompts (SS-18); vectorstores::store/retriever/memory/similarity/mmr → pregolya-vectorstores (SS-20/21); tools::fs/shell/search → pregolya-tools (SS-23). Census command prose updated: '18-crate' → '21-crate'. | FIX-BURST-265, F-P163-01 |
| 2.50 | 2026-07-25 | FIX-BURST 262 (PO share): Three NORMATIVE version pins de-pinned + five HISTORICAL pins allowlisted (TD-VSDD-091 stable-anchor enforcement, F-P161-01). De-pinned: (1) Gate #12 lifecycle-arrow census authority 'BC-2.12.003 v1.4 PC7-PC9' → 'BC-2.12.003 PC7-PC9'; (2) Gate #12 source citation 'BC-2.12.003 v1.4' → 'BC-2.12.003'; (3) type-census BudgetInfo authority 'BC-2.10.003 v1.2 PC5/INV/TV-007' → 'BC-2.10.003 PC5/INV/TV-007'. Allowlisted HISTORICAL-RECORD prose (post-edit line numbers): 1677 (BC-2.08.004 v1.2 RESOLVED note), 1707 (five BC version pins in F-P112-02 fix-burst record), 2115/2119/2125 (BC-2.08.014 v1.2, BC-2.04.007 v1.5, BC-2.08.013 v1.2 in F-P108-04 motivating instances). | FIX-BURST-262, F-P161-01 |
| 2.47 | 2026-07-24 | FIX-BURST 248 (PO side): Gate #36 VP↔BC RED-GATE PARITY minted (standing gate — every VP-NNN.md must carry explicit red_gate: frontmatter (true or false, never absent); red_gate: true requires anchor BC frontmatter red_gate: true + BC-INDEX Red Gate membership + verifiable red_gate_source citation (anti-fabrication, quote-verifiable); on divergence BC frontmatter + BC-INDEX census win; VP-side corrections to architect, BC-side to product-owner). Motivating instance: VP-011 red_gate: true with fabricated ADR-018 citation; anchor BC-2.05.007 adjudicated false. F-P147-02: error-taxonomy.md v1.37→v1.38 E-TOOLS-002 placeholder count Two→Three corrected; taxonomy-wide scan PASS (10 other count-stating rows all correct). total_standing_gates 35→36. | burst-248, F-P147-02, F-P147-03 |
| 2.46 | 2026-07-24 | FIX-BURST 247: Gate #35 VP PROPERTY-BODY COHERENCE minted (standing gate — on any edit to VP-NNN.md or verification-architecture.md catalog entry, diff property statement + variant/branch coverage + harness sketch between the two; VP-NNN.md wins on divergence per CLAUDE.md rule 4; routing: architect scope for verification-architecture.md fixes); SS-23 BC title error-code enumeration policy added as non-numbered policy note in Authoring Guidelines (titles enumerate ALL and ONLY raised codes; Ok-path payload flags excluded); Batch 20 6 BC title rows synced to exact H1 titles per bc_h1_is_title_source_of_truth (001: E-TOOLS-001/002/008; 002: E-TOOLS-001/008; 003: fuzzy_threshold token restored + E-TOOLS-001/003/008; 004: E-TOOLS-001/008; 005: BashOutput segment added + payload flag E-TOOLS-005 removed + E-TOOLS-004/007; 006: Hermetic segment added + E-TOOLS-001/008/009). input-hash updated bacf294→b2c6f44. total_standing_gates 34→35. | burst-247, F-P146-02, OBS-P146-C |
| 2.45 | 2026-07-23 | BC-2.06.005 Batch 20 title updated: 'Emission on Command::Resume' → 'Emission on Command(resume=…)' per BC-2.05.004 struct kwarg authority and BC-2.06.005 H1 (bc_h1_is_title_source_of_truth). | burst-242, F-P142-03 |
| 2.44 | 2026-07-23 | DI coverage table: DI-015 row added (BC-2.23.005 primary + BC-2.13.002 co-enforcer, .kill_on_drop(true)); BC-2.23.005 removed from DI-009 row (re-anchored F-P134-06); DI-009 corrected to {BC-2.08.007, BC-2.08.014, BC-2.14.004, BC-2.22.002, BC-2.22.003}; coverage 14/14→15/15. CAP-017 wave-1 promotion: SS.15 subsystem map CAP-017 P2→P1; Batch 11 header (P1/P2)→(P1); BC-2.15.001/002/003 Wave 2→Wave 1. Batch 20 BC-2.23.005 DI column DI-009,DI-014→DI-014,DI-015. | burst-237, F-P137-02, F-P137-03 |
| 2.43 | 2026-07-22 | BC-2.16.001/002/003 Wave-1 promotion per D23: SS.16 priority P2→P1; frontmatter p1_count 72→75, p2_count 6→3; Summary table P1 72→75, P2 6→3; Full BC table rows P2→Post-v1→P1/Wave 1. | burst-233, F-P133-02 |
| 2.42 | 2026-07-22 | D21 retroactive registration (Batches 16–18, +21 BCs: SS-18..22, CAP-022..033, 3 P0 + 17 P1 + 1 P2) and D23 integration (Batches 19–20, +13 BCs: SS-23 new subsystem + SS-05/06/10 extensions, all P1); BC-2.15.001/002/003 promoted P2→P1 per D23; SS.18..23 added to Subsystem→CAP table; DI-008/009/010/012/014 coverage rows updated with all 34 new BCs; counts: 95→129 total, P0 48→51, P1 39→72, P2 8→6, batches 15→20, subsystems 17→23. | D21 burst-222, D23 burst-231 |
| 2.41 | 2026-07-20 | D21/Batch-3b-i ADR-010 v1.1 error-model integration: Error namespace list in §Error namespace discipline expanded 12→16 by adding E-TMPL, E-SRLZ, E-VS, E-EMBED. New namespaces correspond to ADR-015 (pregolya-prompts TMPL), ADR-016 (pregolya-core::serializable SRLZ), ADR-014 (pregolya-vectorstores VS), ADR-017 (pregolya-core::embeddings EMBED). Namespace list is now: E-CORE, E-GRAPH, E-CHKPT, E-SERVER, E-PROV, E-MCP, E-SPLIT, E-SBXD, E-RETRY, E-CRON, E-MEMORY, E-BUDGET, E-TMPL, E-SRLZ, E-VS, E-EMBED. Cross-cutting integrations for this expansion (error-taxonomy.md v1.27 9 new codes, BC-2.14.001 v1.2 component enum, interface-definitions.md v2.41 blanket annotation census 86→95, api-surface.md v1.6 Component enum, BC-2.20.003 v1.1 E-CFG-001→E-VS-003 reassignment) handled in companion files this burst. BC-2.14.002 verified: no change needed (all 4 new components library-layer only). TD-VSDD-060 E-CFG corpus sweep: zero active residue. | D21, ADR-010 v1.1 |
| 2.40 | 2026-07-19 | F-P118-01 (HIGH, process-gap): Gate #12 Lifecycle-Arrow Census Gate updated to reflect four-member terminal set. (1) Both canonical forms updated: title/prose form gains `/summary_halt`; diagram/arrow form gains `\| summary_halt`. (2) "Terminal set = {completed, failed, cancelled} only" → "{completed, failed, cancelled, summary_halt}" with inline rationale: `summary_halt` is the budget-summarize terminal state reached via `in_progress → summary_halt` on `OnCeiling::Summarize` (BC-2.10.003 PC8(c)(d)); carries summarize output; `completed_at` set; not cancellable; directly deletable; emits `RunEnd`. (3) grep-verify instruction updated: verify hits list all FOUR terminal states; explicitly disallow three-member-only enumerations. (4) Authority citations updated: BC-2.12.003 v1.4 + F-P117-01 adjudication (fix burst 120) + F-P118-01 (fix burst 121). (5) Batch-10 table entry for BC-2.12.003 synced to BC-INDEX:122 / BC H1 four-member verbatim form. F-P118-02: sibling BC propagation — BC-2.12.004 v1.2→v1.3 (PC2b + Related BCs: add `\| summary_halt`); BC-2.05.004 v1.2→v1.3 (Invariant non-interrupted status list: add `summary_halt`); BC-2.05.005 v1.3→v1.4 (Related BCs + VP-HITL-10: add `summary_halt`). Corpus-wide closure grep: 5 three-member terminal-set hits enumerated — all in bc-authoring-plan.md and BC-2.12.004/BC-2.05.004/BC-2.05.005; all fixed this burst. BC-2.12.003 v1.4 (canonical) and BC-2.12.006 already correct. `total_standing_gates` unchanged at 34. | F-P118-01, F-P118-02 |
| 2.39 | 2026-07-18 | F-P112-01 (MED): E-CORE-007 `<content_type>` rendered-value adjudication. ADJUDICATED: BARE variant name. interface-definitions.md §IngressContent (lines 270-272) is the pre-existing authoritative definition specifying bare names ('ToolResult', 'RagChunk', 'MemoryItem'). The qualified 'IngressContent::ToolResult/RagChunk/MemoryItem' form introduced incidentally by burst-115 (F-P111-01) contradicted the interface-definitions source of truth. BC fixes: BC-2.11.002 EC-001/TV (v1.7→v1.8), BC-2.11.003 EC-004/TV (v1.6→v1.7), BC-2.11.004 EC-004/TV (v1.6→v1.7) — all 6 annotation sites now render bare variant names. Gate #33 context-sourced exception registry updated: E-CORE-007 `<content_type>` now explicitly noted as rendering BARE variant name per interface-definitions.md §IngressContent; per-BC named values updated to bare-quoted form '"ToolResult"/"RagChunk"/"MemoryItem"'. F-P112-02 (MED, process-gap): E-CORE-005 polymorphic message adjudication. ADJUDICATED: E-CORE-005 taxonomy format 'Validation failed for '<field>': <reason>' is the SINGLE required message shape corpus-wide. 5 divergent BC sites rewound to canonical form: BC-2.04.002 EC-003 (v1.2→v1.3), BC-2.04.007 EC-003 (v1.5→v1.6), BC-2.08.002 EC-005 (v1.3→v1.4), BC-2.08.006 EC-002 (v1.3→v1.4), BC-2.08.014 EC-006 (v1.2→v1.3; site discovered by F-P112-02 corpus-wide sweep, not in pass-56 census). Addendum note added to pass-56 second-pass census block. error-taxonomy.md v1.25→v1.26 adjudication row. `total_standing_gates` unchanged at 34. | F-P112-01, F-P112-02 |
| 2.38 | 2026-07-18 | F-P111-01 (MED, process-gap): gate #33 Step A extended with **Form 3** — `PregolyaError { ..., code: E-xxx-NNN, ... }` wrapper constructions where the error code appears as a `code:` field rather than as the leading variant identifier (Form 1/2). Prior Step A greps (`Err(E-` and variant-name-brace) silently missed all wrapper-form sites. Form 3 procedure: `grep -rn 'PregolyaError {' .factory/specs/behavioral-contracts/ | grep 'code:' | grep -v '~~\|changelog' | grep -v 'message:'` (Step 3a); Step 3b: verify false positives for multi-line structs where `message:` appears on the continuation line. **Wrapper-form discipline** added inline: bare `{ category, code }` wrapper is ONLY valid for placeholder-free taxonomy messages; codes with `<placeholder>` tokens require (a) inline `message:` template, (b) explicit struct fields, or (c) registered context-sourced exception. **Context-sourced registry** extended from E-MEMORY-007 to also include **E-CORE-007** (`<boundary>` from `ProvenanceTag.boundary_type`; `<content_type>` from `IngressContent` variant discriminant; both deterministically available as `GuardrailHook::evaluate()` arguments). **Full wrapper-form sweep (Form 3, F-P111-01):** 21 violation records across 15 BC files fixed in fix-burst 115 (E-CORE-007 × 6 sites, E-RETRY-002 × 1, E-RETRY-001 × 1, E-CORE-001 × 1, E-PROV-002 × 3, E-PROV-003 × 3, E-MEMORY-008 × 1, E-GRAPH-006 × 1, E-GRAPH-017 × 3, E-CHKPT-001 × 2, E-GRAPH-007 × 2, E-CORE-005 × 2, E-CHKPT-005 × 1, E-MCP-004 × 1, E-GRAPH-008 × 1, E-PROV-001 × 3, E-PROV-006 × 2). Complete census table published in error-taxonomy.md v1.25 changelog. `total_standing_gates` unchanged at 34 (Form 3 is a Step A extension of gate #33, not a new gate). | F-P111-01 |
| 2.37 | 2026-07-18 | F-P110-02 (HIGH, process-gap): gate #33 Step B check-1 cross-anchor scope clarification. The prior text required field-name consistency "within the same BC" — the v2.37 clarification redefines "intra-corpus" as EVERY struct site in every BC the taxonomy BC-Anchor cell lists for the code (primary AND secondary anchors). Root cause of F-P110-02: TD-VSDD-060 sweep anchored "in-file" missed E-SBXD-001 secondary anchor BC-2.13.004 TV-002 (2-field `{ resolved, root }`) diverging from primary anchor BC-2.13.005 canonical 3-field form `{ requested, resolved, root }`. The Step B check-1 prose now names this cross-anchor obligation explicitly: "The PRIMARY anchor's most authoritative construct determines the canonical field name and field count; update ALL diverging sites in ALL anchor BCs." Additionally: full re-census under v2.37 cross-anchor scope found 34 struct-bearing codes total (prior: 30); 4 newly-scoped: E-GRAPH-009 (PASS), E-GRAPH-014 (FAIL — fixed in BC-2.05.006 v1.4), E-CRON-002 (PASS), E-SERVER-006 (PASS). `total_standing_gates` unchanged at 34 (sub-check clarification of gate #33, not a new gate). | F-P110-02 |
| 2.36 | 2026-07-18 | F-P109-02 (MED, process-gap): gate #33 check-2 registry extended with four semantic aliases (`offset ↔ <n>` for E-PROV-009 — byte offset in dialect parse error; `providers_attempted ↔ <N>` for E-PROV-010 — abbreviation, tried-count; `backend_error ↔ <reason>` for E-MEMORY-005 — storage backend failure detail; `message ↔ <reason>` for E-CHKPT-004 CODE-SPECIFIC — full constructed message string is the reason, do not apply to codes where `message` maps to `<message>` placeholder) and two new exception classes: (1) context-sourced placeholder exception — for errors where taxonomy placeholders `<ns>` and `<key>` are sourced from a named request context object at the raise site (currently registered: E-MEMORY-007, `<ns>` and `<key>` from `MemoryWriteRequest.namespace`/`.key`); struct may omit those fields without failing check 2 if and only if BC names context object, placeholder is deterministically available at raise site, and exception is registered by code; (2) PASS-ABBREV rule — TV-row `...` abbreviation PASSES check 2 only if a non-TV (PC or EC) full-struct site in the same BC explicitly names all fields; when the abbreviated TV row is the sole struct-bearing site for a code in the BC, the `...` form is a FAIL — all fields must be listed explicitly. Motivating instance for PASS-ABBREV: BC-2.09.001 TV-004 `{ server: "math", ... }` was the sole E-MCP-002 struct site — expanded to `{ server: "math", transport_error: "connection refused" }` in BC-2.09.001 v1.3. `total_standing_gates` unchanged at 34. | F-P109-02 |
| 2.35 | 2026-07-18 | F-P108-04 (HIGH, process-gap): gate #33 extended with STRUCT-PLACEHOLDER PARITY CENSUS sub-check (Steps A–C). Two consecutive sweeps (v1.20 "21 PASS," v1.21 "17 PASS") produced false completeness claims because they checked that struct fields EXISTED but did not verify CONSTRUCTIBILITY: (1) intra-BC field-name consistency across sites, and (2) struct field set is a SUPERSET of all distinct taxonomy placeholders with no combined multi-placeholder field. Root cause confirmed by three burst-112 failures: E-PROV-010 (`last_error` combined `<last_error_code>/<last_provider>` into one field), E-CHKPT-004 (`source` in PC4 vs `message` in PC5/EC-002/TV), E-PROV-009 (`reason` catch-all embedded mid-message `<n>` offset, can't independently render `<element>` and `<n>`). New sub-check: Step A (enumerate all struct-shorthand Err(E-...) sites via grep), Step B (per-code: assert intra-BC field-name consistency + assert field set is SUPERSET of all distinct taxonomy placeholders + catch-all `reason` only valid for TRAILING-only variable content), Step C (full per-code TABLE as mandatory output; prose-only completeness claims are INVALID). Motivating instances, catch-all rule, and known semantic aliases (step↔\<n\>, node↔\<node_id\>, thread_id↔\<run_id\>) documented inline. `total_standing_gates` unchanged at 34 (sub-check extension of gate #33, not a new gate). | F-P108-04 |
| 2.34 | 2026-07-18 | F-P106-01 (process-gap): gate #28 Form-B-only known-file list was missing `BC-INDEX.md` and the catch-all did not cover indexes. Fix: (1) added `BC-INDEX.md` to explicit "Indexes" bullet in the Known Form-B-only files list; (2) catch-all broadened from "Any ADR or supplement" to "Any index, ADR, or supplement that uses a `## Changelog` body section." SIBLING-SWEEP (TD-VSDD-060): corpus-wide diff of `grep -rl "^## Changelog"` vs `grep -rl "^changelog:"` across `.factory/specs/` — Form-B-only set confirmed as {ADR-007, ADR-009, ADR-012, ADR-013, BC-INDEX.md, BC-2.07.002.md, BC-2.08.011.md, BC-2.08.012.md, bc-authoring-plan.md, test-vectors.md, verification-architecture.md}; domain-spec/ubiquitous-language-server.md has BOTH forms (not Form-B-only, excluded). After fix, all 11 Form-B-only files are covered (explicit list covers 7; broadened catch-all covers ADR-007/009/012/013; BC-INDEX.md covered by both). Zero omissions. L2-INDEX/ARCH-INDEX/VP-INDEX confirmed Form-A only (adversary assertion verified). `total_standing_gates` unchanged at 34 (sub-list correction of gate #28, not a new gate). | F-P106-01 |
| 2.33 | 2026-07-18 | OBS-P105-B (process-gap): gate #28 mandatory pre-emission check added. F-P49-01 false-positive was reproduced at pass-105 — adversary ran only Form A (frontmatter `changelog:`) and missed Form-B files (body `## Changelog` table) despite the existing "CRITICAL" and "Union coverage rule" text. Fix: inserted a standalone MANDATORY PRE-EMISSION CHECK block with per-step explicit Form A + Form B checks and "finding is INVALID" gate for each; enumerated known Form-B files (BCs: BC-2.07.002/011/012; supplements: bc-authoring-plan.md, test-vectors.md, verification-architecture.md). F-P105-01/OBS-P105-A: error-taxonomy.md SECURITY category description corrected (new description spans all 3 SECURITY members: E-SBXD-001/E-GRAPH-013/E-MEMORY-007; removed "sandbox policy enforcement" phrase that contradicted E-SBXD-002 POLICY category); SECURITY vs POLICY authorization-failure categorization rule documented as new blockquote note; error-taxonomy.md bumped 1.18→1.19. `total_standing_gates` unchanged at 34 (sub-check widening of gate #28, not a new gate). | OBS-P105-B, F-P105-01, OBS-P105-A |
| 2.32 | 2026-07-17 | OBS-P103-A (process-gap): gate #28 Rule 6 census was direction-agnostic — structurally unable to flag a consistently-wrong-direction file (a file whose changelog runs in the wrong direction for its class but is internally monotonic). Motivating instance: nfr-catalog.md ran 1.1→1.2 (ascending) but prd-supplements/ class requires DESCENDING; the burst-184 census passed it because the sequence has no inversions. Extended census command to direction-aware: replaced single-param `expected_dir(path)` with `expected_dir(path, form)` that correctly handles all five file classes (prd-supplements/ → desc; architecture/ → desc; behavioral-contracts/ Form A → asc; behavioral-contracts/ Form B non-INDEX → desc per hook; behavioral-contracts/ *INDEX.md → exempt). Direction rules confirmed via hook-source audit: `validate-changelog-monotonicity` hook fires on all `.factory/**/*.md` `## Changelog` body tables except `*STATE.md|*INDEX.md|*burst-log*|*convergence-trajectory*|*session-checkpoint*|*lessons*` — enforcing descending for architecture Form B and BC Form B non-INDEX. Gate prose Rule 6 bullet updated to match: BC Form A = asc; architecture all forms = desc; BC Form B non-INDEX = desc (hook-enforced); BC-INDEX = exempt. Motivating instance block for OBS-P103-A updated to document hook discovery, per-class rules, and BC-INDEX exemption rationale. Corpus-wide census results: 27 BC Form A files corrected desc→asc; nfr-catalog.md corrected asc→desc (F-P103-01); 7 architecture Form A files corrected asc→desc (ARCH-INDEX, api-surface, dependency-graph, module-decomposition, system-overview, tooling-selection, verification-coverage-matrix); purity-boundary-map.md retained desc (architecture Form A); 3 ADRs (Form B) retained desc per hook; BC-INDEX.md retained desc (count-propagation blocker); verification-coverage-matrix.md input-hash refreshed (pre-existing drift cabbed8→6b6537d). Post-fix census: PASS. `total_standing_gates` unchanged at 34 (sub-check extension of gate #28 Rule 6). | OBS-P103-A, F-P103-01 |
| 2.31 | 2026-07-17 | Gate #28 extended: Rule 6 VERSION-MONOTONICITY (CHANGELOG-MONOTONICITY) sub-check added. Codified at 3rd recurrence (F-P97-03/BC-2.08.006, F-P101-02/BC-2.11.002, F-P102-01/BC-2.11.005). Direction-agnostic Python census command included (covers all changelog-bearing files corpus-wide). Machine enforcement deferral updated from "rules 1–5" to "rules 1–6"; Phase 3 decision tree extended with `assert version_monotonicity_within_file [Rule 6 — universal]` in both branches. bc-authoring-plan self-compliance verified (v2.31 changelog table descending — PASS). `total_standing_gates` unchanged at 34 (sub-check extension of gate #28). | F-P102-01 codification |
| 2.30 | 2026-07-17 | F-P98-01 (count reconciliation): Gate #27 exemption note placeholder-total corrected 59 → 60 (59 literal `[architect to assign]` + 1 semantic variant `[architect to confirm]` in BC-2.08.009, caught at pass 97 per F-P97-01). Source reference updated from F-P96-01 alone to F-P96-01 + F-P97-01. Grep sweep for other live "59" placeholder-total references (changelog rows exempt): zero additional hits found. `total_standing_gates` unchanged at 34. | F-P98-01 |
| 2.29 | 2026-07-17 | F-P97-04 (process-gap): Gate #27 residue class widened from literal `[architect to assign]` to semantic class `architect to (assign\|confirm\|determine\|resolve)` (bracketed or unbracketed); scope extended from `behavioral-contracts/` only to ALL of `.factory/specs/`; corpus-wide sweep command added. Sweep run: 2 live hits found and fixed in same burst (BC-2.08.009:199 per F-P97-01; prd.md:635 per F-P97-02); 2 exempt (bc-authoring-plan gate-rule text + changelog row). Additional sweeps — "PO to (confirm\|assign)": 0 hits; "to be confirmed": 0 hits; "TBD by": 0 hits. `total_standing_gates` unchanged at 34 (census widening of gate #27, not a new gate). | F-P97-04 |
| 2.28 | 2026-07-17 | F-P96-01: Gate #27 exemption updated — `[architect to assign]` placeholder class removed from accepted exemptions. All 59 vestigial Module-field placeholders across `.factory/specs/behavioral-contracts/` resolved to authoritative crate assignments per module-decomposition.md v1.10. New BCs must carry resolved Module fields from authoring. | F-P96-01 |
| 2.27 | 2026-07-17 | F-P95-02 (process-gap) — gate #13 VP-census regex widened: old `VP-[A-Z]+-[0-9]+` silently missed multi-segment domain IDs (VP-BSP-DET-01, VP-DI001-01) and digit-bearing domains — SS-03's entire VP set was invisible. New regex: `VP-[A-Z0-9]+(-[A-Z0-9]+)*-[0-9]+`. Verified: VP-BSP-DET-01, VP-DI001-01, VP-BUDGET-05, VP-SPLIT-001 all extracted correctly; old regex missed VP-BSP-DET-01 and VP-DI001-01 (confirmed by running both patterns). Post-fix corpus census (new regex): 141 unique VP IDs extracted — zero duplicates. Old regex captured only 71 IDs (50 invisible). `total_standing_gates` unchanged at 34 (sub-check widening, not a new gate). | F-P95-02 |
| 2.26 | 2026-07-17 | OBS-P93-01 (process-gap) — gate #13 VP uniqueness sub-check added. Prior anchor-matrix census detected BC VP Anchors ↔ VP-INDEX drift but did NOT detect same VP-<DOMAIN>-NNN ID defined in two BC bodies with different semantics (cross-BC collision). New sub-check: `grep -rh "^| VP-" .factory/specs/behavioral-contracts/ --include="*.md" | grep -oE "VP-[A-Z]+-[0-9]+" \| sort \| uniq -d` — expected empty output. Motivating instance: F-P93-04 — BC-2.10.003 VP-BUDGET-05 (Summarize path) collided with BC-2.10.004 VP-BUDGET-05 (HITL interrupt path). Resolved by renumbering BC-2.10.003's to VP-BUDGET-07. Census run immediately after fix: zero duplicate VP IDs found (PASS). `total_standing_gates` unchanged at 34 (sub-check extension of gate #13, not a new gate). | OBS-P93-01, F-P93-04 |
| 2.25 | 2026-07-17 | F-P89-01/02 + class-sweep (pass-89 fix burst). (1) F-P89-01 — Gate #34 structural fix: removed stale per-file hash values from census block (class: hash-values-in-gate-text, same churn as STATE.md-in-inputs). Replaced with: (a) existing census commands [already authoritative], (b) explicitly-NON-AUTHORITATIVE last-run snapshot (2026-07-17: supplements 2/6 MATCH, 4/6 DRIFT; BCs 1/95 MATCH [BC-2.08.006], 94/95 STALE pre-existing), (c) rule sentence: "per-file hash values are NEVER recorded in gate text; frontmatter input-hash is the single source of truth." (2) F-P89-02 — Frontmatter input-hash reconciled: v2.24 wrote e238778 (burst-168); bursts 169-170 bumped inputs (prd.md→v1.2, L2-INDEX→v1.3), producing e786fea without a changelog entry; current recompute yields 41c29d9. Full chain: 90d28fa → e238778 (burst-168) → e786fea (bursts 169-170, previously undocumented) → 41c29d9 (this burst). (3) Class sweep — no other gate-text 7-char hash literals found in .factory/specs/; no other "pending recomput" live-prose instances; no other SS-TBD live BC body residue beyond BC-2.08.006 precondition (fixed separately this burst). | F-P89-01, F-P89-02, pass-89 |
| 2.24 | 2026-07-17 | Provenance-integrity fix — removed .factory/STATE.md from inputs: list. STATE.md is a live pipeline-state file; input-hash drifts on every state write with zero spec-content signal for this supplement. All genuine derivation sources (prd.md, domain-spec/L2-INDEX.md) were already listed and are unchanged. Input-hash recomputed (90d28fa → e238778). | burst-168-provenance-fix |
| 2.23 | 2026-07-17 | F-P88-02/03/04 — (1) Gate #16/gate #22 live gate prose: "Error Category Codes table" → "Error Categories table" (2 sites; section was renamed in pass-87 burst); gate #29 live scope item: "Flag Interaction Rules table rows" → "Flag Interactions table rows" (1 site; section renamed in pass-87 burst). Line-1297 "Flag Interaction Rules row for sandbox-wasm" in Motivating Instance block verified historical audit-trail — left as-is. Full .factory/specs/ grep for both old names: all remaining occurrences are changelog/audit-trail rows, all exempt. (2) Changelog gap adjudication: versions 2.8 and 2.9 EXISTED in committed git history (4ed9ed1 and 96f6317 respectively) but their changelog TABLE ROWS were omitted when version numbers were incremented. Reconstructed entries added to close the gap (git dates and commit descriptions used as evidence; see rows below). (3) Frontmatter `subsystem_note` and guideline #1 rewritten to past-tense/historical form: SS-TBD status was RESOLVED at Phase 1b (2026-07-14); all 95 BCs carry real SS-NN IDs. (4) error-taxonomy.md bumped v1.16→v1.17 and interface-definitions.md bumped v2.27→v2.28 with timestamps → 2026-07-17, recording the pass-87 body changes that lacked version propagation (F-P88-01). input-hash updated after all edits. | F-P88-01, F-P88-02, F-P88-03, F-P88-04 |
| 2.22 | 2026-07-17 | Pass-87 burst completion — all 61 remaining stale BC hashes normalized (53 legacy 64-char SHA-256 + 8 `[pending state-manager]` placeholders → correct 7-char MD5 via compute-input-hash for each). Full lifecycle frontmatter (extracted_from, modified, deprecated, deprecated_by, replacement, retired, removed, removal_reason) added to all files that lacked it. test-vectors.md cascade: hash updated "334c597" → "5c68c70" (BC-2.01.001 and BC-2.07.002 in its inputs both changed). Gate #34 updated: Placeholder row rewritten to document only the `[live-index]` sanctioned exception class with explicit rationale; `[pending state-manager]` class removed (all resolved). Census line updated to 95/95 MATCH, STALE=0. Final gate #34 state: zero-exception compliance. | F-P87-02, D18-P87-B |
| 2.21 | 2026-07-17 | Pass-87 fix burst — D18-P87-B RESOLVED: single-format canonical (7-char truncated MD5 for all spec artifacts). `compute-input-hash` returns 7-char for BC files too; the two-format convention documented in v2.20 was incorrect. Gate #34 rewritten to remove two-format language and document the corrected single-format convention with zero-exception census commands. Input-hash cleanup completed: (1) 3 prd-supplements normalized from legacy 64-char SHA-256 to correct 7-char (error-taxonomy "f766c52", nfr-catalog "465a82f", interface-definitions "cdce094"); (2) 19 BC files in ss-08/ss-10/ss-11/ss-14 updated from stale abbreviated hashes to correct 7-char; (3) 15 additional BC files (ss-01/03/04/05/07/08/12/13/16) updated after cascade drift triggered by error-taxonomy.md section rename (prerequisite for template compliance); (4) module-criticality.md stale hash corrected ("fed74e2" → "b8ac573", STATE.md drift). Supplement template compliance: error-taxonomy "Error Category Codes" renamed → "Error Categories"; interface-definitions: added §CLI Interface, §Exit Code Semantics, §JSON Output Schema stubs and renamed §Flag Interaction Rules → §Flag Interactions. BC template compliance: lifecycle frontmatter keys added to 37 BC files missing extracted_from/modified/deprecated/etc. Pre-existing residual: 53 BC files with legacy 64-char SHA-256 hashes (not caused by this burst; route to dedicated cleanup burst). prd-supplements census: 6/6 PASS. BC 7-char census: 34/34 CLEAN. | F-P87-01, F-P87-02, D18-P87-B |
| 2.20 | 2026-07-16 | F-P87-01 (HIGH, process-gap): gate #28 date-validity sub-check Rule 1 (`date ≤ frontmatter timestamp`) scoped to supplement documents only per D18-P87-A. BC files (`introduced:` field present) are exempt — `timestamp:` is frozen at v1.0 authoring date, so post-v1.0 changelog rows carry dates AFTER `timestamp:` by design (COMPLIANT per Rule 5 BC branch). Changes: (1) header updated: "any BC file" → "any changelog-bearing file (BC file or supplement)"; "three conditions" → "five rules, scoped by document type"; (2) Rule 1 rewritten with supplement-only scope and explicit BC exemption; (3) Rule 2/3 annotated "(Applies to ALL document types.)"; (4) census command assertion extended with Rule 1 supplement-only assertion (c); (5) DEFER-002 note updated from "rules 4 and 5" to "rules 1–5" with full five-rule decision tree keyed on `introduced:` presence. Contradiction-free verification: BC-2.07.002 (ts 07-13, changelog 07-15) PASS; BC-2.08.011 (ts 07-13, changelog 07-14) PASS; BC-2.08.012 (ts 07-13, changelog 07-14) PASS; bc-authoring-plan (ts 07-16, changelog 07-16) PASS; test-vectors (ts 07-16, changelog 07-16) PASS; module-criticality (ts 07-15, changelog 07-15) PASS. F-P87-02 (MED, process-gap): input-hash format conflict surfaced and documented. `validate-input-hash` hook (PostToolUse enforcer) blocked attempted 64-char SHA-256 write on test-vectors.md, revealing two-format convention: prd-supplements use 7-char truncated MD5 (hook-enforced), BC files use 64-char SHA-256 (ADV-P1D-PASS-9 convention). Adversary premise (64-char canonical for all files) is incorrect; burst 166 normalization to 7-char was CORRECT for supplements. Gate #34 INPUT-HASH FORMAT CONSISTENCY minted documenting the per-type convention and flagging D18-P87-B for human adjudication on whether to unify formats. `total_standing_gates` 33 → 34. input-hash updated: stored "80954d3" → "ddae3ae" (recomputed by validate-input-hash hook; inputs unchanged, STATE.md drift). | F-P87-01, F-P87-02, D18-P87-A, D18-P87-B |
| 2.19 | 2026-07-16 | F-P86-02 (process-gap adjudication): gate #28 Rule 5 (FRONTMATTER-CURRENCY) scoped by document type. Supplements (`introduced:` field absent) retain the existing rule: `timestamp:` must equal the newest changelog entry date. BC files (`introduced:` field present) are excluded: `timestamp:` is the authoring date (stable, never updated after v1.0). This resolves the contradiction between Rule 5 as written and the BC corpus — BC-2.07.002 (ts 2026-07-13, newest changelog 2026-07-15), BC-2.08.011 (ts 2026-07-13, newest changelog 2026-07-14), and BC-2.08.012 (ts 2026-07-13, newest changelog 2026-07-14) are all COMPLIANT under the scoped rule (each timestamp equals its v1.0 initial authoring date). Corpus sweep: module-criticality.md timestamp corrected 2026-07-14 → 2026-07-15 (metadata-only; matches v1.3 changelog entry date). Zero Rule-5 violations remain under the scoped rule. DEFER-002 machine enforcement note updated: branch on `introduced:` field presence (`if has_introduced: assert timestamp == v1.0_changelog_date; else: assert timestamp == max_changelog_date`). | F-P86-02, D18-P86-A |
| 2.18 | 2026-07-15 | D18-P78-B (F-P78-02/03 process-gap): gate #33 step 11 added — every omission-note BC-anchor citation in interface-definitions.md must resolve to a raising PC/EC (success-path citations = violation). Motivating instances: F-P78-02 (E-PROV-010 cited PC4/EC-002 which are success paths; correct = PC5/EC-004) and F-P78-03 (E-PROV-009 cited PC4 which is a success parse; correct = PC8/PC9/EC-002). `total_standing_gates` unchanged at 33 (step-11 extension of gate #33, not a new gate). | D18-P78-B, F-P78-02, F-P78-03 |
| 2.17 | 2026-07-15 | D18-P77-B (F-P77-01 process-gap): gate #33 extended with SEMANTIC-AGREEMENT sub-check (steps 7–10). For every live taxonomy code, the row's Message Format template and raise-condition annotation must semantically agree with the anchor BC's authoritative `message:` text and EC/TV trigger conditions; on divergence the BC wins (taxonomy is corrected). Motivating instance: E-SBXD-006 regex-vs-wildcard divergence on DI-010 credential boundary survived both gates #20 and #33 (both are name/presence-only; neither verified predicate agreement). `total_standing_gates` unchanged at 33 (sub-check extension of gate #33, not a new gate). | D18-P77-B, F-P77-01 |
| 2.16 | 2026-07-15 | F-P75-01/D18-P75-A: gate #28 date-validity sub-check extended with two new rules — (4) TEMPORAL-NEIGHBOR SWEEP: all neighboring changelog rows in any edited file must be date-audited in the same burst, not just the new row; pass N dates may not exceed pass N+1 artifact dates; (5) FRONTMATTER-CURRENCY: frontmatter `timestamp:` must equal the date of the file's newest changelog entry. Trigger: 3rd recurrence of future-dated-changelog class (F-P75-01/OBS-P75-A; prior: F-P64-02, F-P65-01). Machine enforcement (pre-commit hook / CI lint) DEFERRED to Phase 3 CI hardening — deferral logged by state-manager. `total_standing_gates` unchanged at 33 (widening of gate #28, not a new gate). Plan version 2.15 → 2.16. | F-P75-01, D18-P75-A |
| 2.15 | 2026-07-15 | OBS-P74-A: gate #19 census command extended with five shared-type retired names (`CheckpointStore`, `RunConfig`, `BaseCheckpointSaver`, `AIMessage`-Rust-context, `Checkpointer`); `domain-spec/` added to exclusion list (Python→Rust mapping tables); AIMessage operator note added; coverage-closure note added recording that gate #15 previously left interface-definitions.md uncovered on this axis. Adjudication D18-P74-A. | OBS-P74-A |
| 2.14 | 2026-07-15 | OBS-P73-B: gate #32 carrier #5 module count corrected "(20-module subset;" → "(22-module subset;" (D20 added ToolCallDialect + ProviderFallbackPolicy modules to the PO criticality registry, bringing the total from 20 to 22; the prose was not updated in the D20 burst). | OBS-P73-B |
| 2.13 | 2026-07-15 | pass-72 fix burst — OBS fixes: (1) stale "86" swept → 95 in three locations (guideline #8, Batch-13 scope note, gate #13 census prose); (2) BC-2.10.003 Batch-6 table title aligned with H1/BC-INDEX: "(on_ceiling = halt)" → "(on_ceiling = halt \| summarize)"; (3) gate #32 expanded from three to five required carriers (+module-criticality arch registry +module-criticality PO registry; OBS-P72 process-gap addition — D20 ADR-012/ADR-013 modules not reconciled against PO registry in same burst). | OBS-P72, F-P72-08 |
| 2.12 | 2026-07-15 | D20 TOUCH-UP burst — Residue 1: BudgetInfo row added to gate #31 census table (RESOLVED — defined inline in interface-definitions.md v2.21 §BudgetPolicy, BC-2.10.003 v1.2). Census verdict corrected: prior "25/28" had two errors — (a) table had 27 rows (BudgetInfo was the missing 28th row) and (b) numerator 25 was wrong arithmetic. True N/M after recount = 24/28 (23 RESOLVED + 1 EXTERNAL [Value, exempt] = 24 effectively resolved; 4 UNRESOLVED unchanged; total = 28). | D20 TOUCH-UP |
| 2.11 | 2026-07-15 | D20 INTEGRATE sub-burst 2: 9 new BCs registered (86→95; P1 30→39; batches 13→15). Batch 14 (8 BCs, Wave 2): BC-2.04.008 (CAP-005), BC-2.08.013/014 (CAP-009), BC-2.09.006/007 (CAP-021), BC-2.15.004/005/006 (CAP-020). Batch 15 (1 BC, Wave 1): BC-2.13.007 (CAP-015). Subsystem→CAP mapping: SS.09 gains CAP-021; SS.15 gains CAP-020. DI coverage table: DI-002/006/008/009/010/012/014 all gain new enforcing BCs; zero orphan invariants (14/14 DIs covered). Gate #22: E-MCP-005 added as 6th intentional RetryHint divergence (TRANSPORT/Later→Never; BC-2.09.006 anchored). Gate #31 census: +7 types (ToolCall, SkillDescriptor, MemoryWriteRequest, WriteGuardDecision, ProviderCredential, CredentialRefreshConfig); census 19/21 → 25/28 resolved (4 UNRESOLVED: ChatConfig, CheckpointConfig, ProviderCredential, CredentialRefreshConfig). | D20 sub-burst 2 |
| 2.10 | 2026-07-15 | F-P70-01: Gate #27 budget ownership corrected per ADR-009 v1.2 Option 3 split — "budget" removed from pregolya-graph group; new rules added: budget ENGINE (BudgetEngine, EvidenceJournal → pregolya-graph) and budget TRAIT/types (BudgetPolicy, PolicyDecision, TokenUsage, RunContext → pregolya-core/src/budget.rs). Quick-check forbidden set: `pregolya-core/src/budget` removed (BC-2.10.001:141 + BC-2.10.003:139 are correct anchors, not wrong-crate hits); positive assertion added (BudgetEngine/EvidenceJournal must never anchor to pregolya-core). Guardrail canon rule added (GuardrailHook trait → pregolya-core; invocation pipeline → pregolya-graph) — adjudicated placement missing from ownership rules since pass-61. Motivating instance block expanded with F-P70-01. | F-P70-01 |
| 2.9 | 2026-07-15 | Gate #20 widened to AUTH/POLICY/INTERNAL category re-sweep (F-P69-01/OBS-P69-1 [process-gap], ADV-P1D-PASS-69): (1) trigger expanded to cover 500 table row edits and any table edit involving a range expression or INTERNAL-category code placement; (2) Rule 5 INTERNAL axis added — every INTERNAL-category code must map to the 500 row OR carry a documented individual omission note OR be covered by a named blanket omission group; no INTERNAL code may appear in a VAL-labeled row without an explicit override note; (3) Range-expansion rule added — any range expression in the HTTP Status Codes table (e.g., "E-CORE-001 through E-CORE-005") must be mentally expanded and each member's category verified on every table edit; (4) Motivating instance added (F-P69-01): "E-CORE-001 through E-CORE-005" range silently included E-CORE-004 (INTERNAL, not VAL), which was found and fixed in interface-definitions.md. `total_standing_gates` unchanged at 33 (widening of gate #20, not a new gate). **NOTE (F-P88-03, 2026-07-17): This changelog entry was reconstructed from git commit 96f6317 (burst 145, 2026-07-15). The version number was incremented to 2.9 in that commit but the changelog table row was omitted.** | F-P69-01, OBS-P69-1 |
| 2.8 | 2026-07-15 | Gate #21 extended with cross-row routing-enumeration completeness sub-check (OBS-P67-1 [process-gap], ADV-P1D-PASS-67): whenever a code is added to or removed from a status row, every other row's explanatory enumeration that references that row must be updated to reflect the change; census procedure defined (extract inter-row routing enumerations, diff against target row's live code list, fix discrepancies in same burst). Motivating instance: F-P67-01 — the 422 row enumeration "(E-CHKPT-001, -002, -003, -004, -006) go to the 500 row" omitted E-CHKPT-007 (added to 500 row at v2.11 without updating the 422 row sibling enumeration; gap survived 10 passes). `total_standing_gates` unchanged at 33 (sub-check extension of gate #21, not a new gate). **NOTE (F-P88-03, 2026-07-17): This changelog entry was reconstructed from git commit 4ed9ed1 (burst 143, 2026-07-15). The version number was incremented to 2.8 in that commit but the changelog table row was omitted.** | OBS-P67-1, F-P67-01 |
| 2.7 | 2026-07-15 | Gate #33 "taxonomy anchor reverse-verification census" added; `total_standing_gates` 32→33. Reverse axis of gate #30: every live (non-tombstone) taxonomy code's declared BC Anchor body must contain the code string or variant name with a specified raise condition; census = per-code grep; orphans/mis-anchors = findings. Trigger: every taxonomy edit + adversary rotation. Pass threshold: 100%. Post-fix census (ADV-P1D-PASS-66): 78/78 live codes anchored (100% PASS). Motivating instances: F-P66-03 (E-SERVER-005 retired — CORS denial is silent header-omission; code was unraised), F-P66-02 (E-CHKPT-003 — BC-2.04.005 lacked EC/TV for read-failure raise; added this burst), F-P66-01 (E-MCP-003 — re-anchored from BC-2.09.005 to BC-2.09.001; EC-006 + TV-008 added this burst). (ADV-P1D-PASS-66 §OBS-P66-1 [process-gap]) | OBS-P66-1 |
| 2.6 | 2026-07-15 | Gate #28 widened with date-validity sub-check (OBS-P65-1 [process-gap]): all changelog entries in any BC file (Form A and Form B) must satisfy (a) date ≤ frontmatter timestamp, (b) date ≤ current burst date, and (c) monotonic per file ordering convention. Form-B set (BC-2.07.002/BC-2.08.011/BC-2.08.012) explicitly listed as required enumeration targets alongside prd-supplements in every date sweep. Census command added. `total_standing_gates` unchanged at 32 (widening, not new gate). Motivating instances: F-P64-02 (supplement body changelog dates, pass-64) + F-P65-01 (BC-2.07.002 Form-B changelog v1.1 row dated 2026-07-16, pass-65). (pass-65, OBS-P65-1) | F-P65-01, OBS-P65-1 |
| 2.5 | 2026-07-15 | F-P64-02 fix: corrected v1.1 changelog row date `2026-07-16` → `2026-07-14` (PASS-36 = 2026-07-14, consistent with v1.2 same-day PASS-37 authoring; prior date was a future-date typo). Supplement date sweep: test-vectors.md v1.1 same defect corrected (v1.2→v1.3); error-taxonomy, interface-definitions, module-criticality carry frontmatter-only changelogs (no explicit date fields in entries — temporal-order check not applicable); nfr-catalog v1.0 no changelog (correct). (F-P64-02, ADV-P1D-PASS-64) | F-P64-02 |
| 2.4 | 2026-07-15 | Gate #32 "ADR-propagation census" added; `total_standing_gates` 31→32. Gate #31 step 4 extended with near-name corpus check (D18-P61-B): UNRESOLVED types must also be checked against near-name corpus concepts before classification. Census updated P60→P61: 21→21 types, BudgetContext UNRESOLVED retired → RunContext RESOLVED (BC-2.10.001 pre-3); 18/21 → 19/21 resolved; 3 unresolved → 2 unresolved (ChatConfig, CheckpointConfig). Gate #19 retired-identifier list extended: BudgetContext → RunContext (F-P61-02). Gate #19 census command updated: BudgetContext added to grep pattern. Motivating instances: F-P61-01 (ADR-009 trait anchors in wrong crate), F-P61-02 (BudgetContext minted without near-name corpus search — RunContext already in BC-2.10.001 pre-3), OBS-P61-1 [process-gap]. (ADV-P1D-PASS-61) | F-P61-01, F-P61-02, OBS-P61-1 |
| 2.3 | 2026-07-15 | Gate #31 widened: step 4 "name-equality check" added (OBS-P60-1 [process-gap] — BudgetDecision/PolicyDecision drift survived 2 passes because definition-existence alone was checked). Census updated P58→P60: 22→21 types (removed RunId, EvidenceJournal, BudgetDecision from BudgetPolicy rows; added PolicyDecision, BudgetContext); 20 resolved → 18 resolved, 2 unresolved → 3 unresolved (ChatConfig, CheckpointConfig, BudgetContext). Gate #19 retired-identifier list extended: BudgetDecision → PolicyDecision (F-P60-01). Gate #19 census command updated: BudgetDecision added to grep pattern; architecture/ added to exclusion (architect scope). `total_standing_gates` unchanged at 31 (widening, not new gate). (ADV-P1D-PASS-60 §OBS-P60-1 [process-gap]) | OBS-P60-1 |
| 2.2 | 2026-07-15 | Gate #31 "trait-signature type-resolution census" added; `total_standing_gates` 30→31. Census run P58: 22 types across 5 traits; 20 resolved, 2 unresolved (ChatConfig, CheckpointConfig — flagged implementer-scope for architect). Retired-identifier list extended: IngressSource, source_type, tool_name/invocation_id/timestamp (ProvenanceTag old fields), GuardrailAction, Accept/Reject/Redact. Census command updated. Motivating instance: OBS-P58-1 — F-P57-01 introduced IngressContent+GuardrailSeverity as undefined types surviving one full pass. (ADV-P1D-PASS-58 §OBS-P58-1 [process-gap]) | OBS-P58-1 |
| 2.1 | 2026-07-15 | Gate #30 second-pass drain (ADV-P1D-PASS-56-COMPLETION): resolved deferred TBD-E-PROV-HTTP and all second-pass codeless candidates. Minted 3 new codes (E-PROV-008, E-CORE-007, E-CHKPT-007). Fixed 13 constructions across BC-2.08.004 (×4), BC-2.08.001 (×1), BC-2.08.002 (×2), BC-2.08.006 (×2), BC-2.11.002/003/004 (×6), BC-2.04.002 (×2), BC-2.04.006 (×1), BC-2.04.007 (×3). Census: 24 constructions examined; 13 fixed; 3 already-coded; 8 exempt. Zero genuine codeless constructions remain. Gate #30 census command returns zero genuine hits. Disposition census 76→79: 45 HTTP table rows, 11 individual omission notes, 23 blanket library-layer coverage. | OBS-P56-2 drain |
| 2.0 | 2026-07-15 | Gate #30 "codeless-error census" added; `total_standing_gates` 29→30. First-pass census run: identified 19 concrete codeless PregolyaError constructions across BC-2.01.003 (×4), BC-2.14.006 (×5), BC-2.08.007 (×6), BC-2.08.004 (×4). Fixed 15 with clear taxonomy mappings (E-CORE-006, E-CORE-005, E-PROV-002, E-PROV-003, E-PROV-004, E-PROV-001). Deferred 4 (BC-2.08.004 EC-004/EC-005/TV-004/TV-005: TRANSPORT non-stream HTTP responses) pending E-PROV-008 mint decision. Motivating instance: F-P56-01 — BC-2.01.003 recursion limit error codeless while graph-engine counterpart (E-GRAPH-017) had a code since pass 49. (ADV-P1D-PASS-56 §F-P56-01, §OBS-P56-2 [process-gap]) | F-P56-01, OBS-P56-2 |
| 1.9 | 2026-07-15 | Gate #28 census command updated to explicit two-form (Form A: frontmatter `changelog:` key; Form B: body `^## Changelog` table; union required). `total_standing_gates` unchanged at 29 (no new gate — clarification only). Motivating instance: F-P49-01 false positive (ADV-P1D-PASS-49) — adversary ran only Form A, missed three BCs (BC-2.08.011/012, BC-2.07.002) carrying Form B changelogs. (ADV-P1D-PASS-49 §F-P49-01 [false positive rejected by orchestrator]) | F-P49-01 |
| 1.8 | 2026-07-15 | Gate #29 "supplement-vs-BC seam census" added; `total_standing_gates` 28→29. Gate census run at addition: 6 SS-13 sandbox rows checked across interface-definitions.md feature-flags + flag-interactions + config-comment — zero additional mismatches beyond F-P47-01 and F-P47-02 (both fixed in interface-definitions.md v2.6 in same burst). Motivating instance F-P47-01 (CRITICAL, survived 46 passes): Flag Interaction Rules row for `sandbox-wasm+container-both-off` stated silent process-backend fallback, inverting BC-2.13.001 PC4/EC-002/DI-006/NE-01. F-P47-02 (MED): config comment "on startup" contradicts BC-2.13.002 PC2/EC-002. OBS-P47-1 [process-gap]: `sandbox-process` feature row added to Cargo Feature Flags table. (ADV-P1D-PASS-47 §F-P47-01 CRITICAL, §F-P47-02 MED, §OBS-P47-1 [process-gap]) | F-P47-01, F-P47-02, OBS-P47-1 |
| 1.7 | 2026-07-14 | (1) Gate #25 Part C added: per-row crate ownership diff across all four criticality-bearing docs required in addition to tier diff; motivating instance F-P45-01 (retry module crate-divergent row survived all tier-only checks). (2) Wave-0 convention note added to Batch Assignments section: Wave 0 ⊂ Wave 1 in the ARCH-INDEX two-wave scheme; 13 BCs across SS-01/07/14 are the foundational sub-wave; reconciles OBS-P45-1 (ADV-P1D-PASS-45). `total_standing_gates` unchanged at 28 (Part C extends gate #25; no new gate). | F-P45-01, OBS-P45-1 |
| 1.6 | 2026-07-14 | Gate #28 "version-changelog integrity" added; `total_standing_gates` 27→28. Git-history adjudication of F-P43-01: 17 BCs (ss-04 ×5, ss-11 ×6, ss-13 ×6) carried version "1.1" with no changelog. Outcome: 4 genuinely unmodified BCs reverted to version "1.0" (BC-2.13.001/002/003/005); 13 substantively modified BCs kept at version "1.1" with `changelog:` frontmatter entries added recording specific pass and change per file. (F-P43-01 [process-gap], ADV-P1D-PASS-43) | F-P43-01 |
| 1.5 | 2026-07-14 | Gate #27 "architecture-anchor crate-resolution census" added; `total_standing_gates` 26→27. Full gate-#27 census run across all 86 BCs × 187 Architecture Anchor crate paths: 16 distinct crate names found (all valid per ADR-007 roster); exactly 2 wrong-crate anchors found and fixed (BC-2.08.011 line 112 and BC-2.08.012 line 119: `pregolya-core/src/graph/builder.rs` → `pregolya-graph/src/graph/state.rs`). Zero remaining wrong-crate anchors after fixes. (F-P42-01 [process-gap], ADV-P1D-PASS-42) | F-P42-01 |
| 1.4 | 2026-07-14 | (1) F-P40-01: Batch 9 BC-2.08.007 DI cell corrected `DI-014` → `DI-009, DI-014` (body + BC-INDEX + DI-coverage table all show DI-009; batch-table was the sole outlier). (2) Full batch-table anchor sweep (86 rows vs BC-INDEX): 8 corrections — BC-2.08.001–005 CAP `CAP-009, CAP-011` → `CAP-009` (body capability: CAP-009; CAP-011 spurious); BC-2.10.004 CAP `CAP-012, CAP-006` → `CAP-012` (body primary capability: CAP-012); BC-2.05.006 DI `DI-003, ASM-008` → `DI-003` (ASM-008 is an assumption reference, not a domain invariant). Zero remaining anchor drifts vs BC-INDEX after fixes. (3) Gate #13 widened from four-way to five-way consistency check: bc-authoring-plan batch-table CAP/DI columns added as fifth verified carrier; motivating instance F-P40-01 cited (OBS-P40-1, ADV-P1D-PASS-40) | F-P40-01, OBS-P40-1 |
| 1.3 | 2026-07-14 | Reconciled batch-size constraint with Batch 9 Step-E exception: amended line-27 prose to document BC-2.08.009 exception per ADR-004 acceptance; updated Summary metric "BCs per batch (max)" from `8` to `9 (Batch 9 only — Step-E exception; planning cap remains 8)`; three statements (prose, metric, Batch 9 header) now mutually coherent (F-P39-02, ADV-P1D-PASS-39) | F-P39-02 |
| 1.2 | 2026-07-14 | Gate #25 Part B widened from 2-registry to 4-document sibling set: added module-decomposition.md (derived Criticality column + tier headings) and verification-coverage-matrix.md (derived tier summary + per-module table) as required census targets; extended census commands accordingly (OBS-P37-1 [process-gap], ADV-P1D-PASS-37) | OBS-P37-1 |
| 1.1 | 2026-07-14 | Added standing gate #26 "Structurally-Privileged-Line Canon Check"; added `total_standing_gates: 26` to frontmatter (F-P36-03/OBS-P36-2 codification, ADV-P1D-PASS-36) | OBS-P36-2 |
| 1.0 | 2026-07-13 | Initial authoring | Greenfield Phase 1a |
