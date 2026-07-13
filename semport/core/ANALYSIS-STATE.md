---
artifact: semport/core/analysis-state
project: ferrochain
pass: 7
status: pass-7-deepening-complete
deepening_run: true
date: 2026-07-12
producer: codebase-analyzer
note: Pass 7 convergence deepening; direct writes to the 5 deliverables + this file succeeded (not hook-blocked this pass)
scale:
  source_loc: 60101
  source_files: 180
  test_count: 1766
  test_loc: 59935
top_risks:
  - id: RED-1
    area: "Runnables/LCEL (runnables/base.py 6,713 LOC)"
    severity: RED
  - id: ORA-1
    area: "lc-JSON serialization fidelity"
    severity: ORANGE
  - id: ORA-2
    area: "pydantic→JSON-schema tool generation"
    severity: ORANGE
  - id: ORA-3
    area: "astream_events v2 ordering"
    severity: ORANGE
  - id: ORA-4
    area: "streaming-parser jsonpatch contracts"
    severity: ORANGE
new_deps:
  - name: langchain-protocol
    version: "0.0.17"
    status: immature
    strategy: port-as-provisional
    risk_id: R7
adr_candidates: 5
adr_candidates_ref: ".factory/semport/core/rust-translation-strategy.md"
deliverables_produced:
  - .factory/semport/core/module-inventory.md
  - .factory/semport/core/behavioral-intent.md
  - .factory/semport/core/test-inventory.md
  - .factory/semport/core/dependency-disposition.md
  - .factory/semport/core/rust-translation-strategy.md
deepening_items_remaining:
  - id: 1
    priority: P0
    item: "runnables/base.py internals full read (binding/each/generator/lambda/configurable/fallbacks/graph)"
  - id: 2
    priority: P0
    item: "line-level astream_events v2 ordering from test_runnable_events_v2.py"
  - id: 3
    priority: P1
    item: "enumerate load/mapping.py remap table"
  - id: 4
    priority: P1
    item: "verify trim_messages against its 145 tests"
  - id: 5
    priority: P2
    item: "per-provider block_translators extraction (deferrable to partner scoping)"
  - id: 6
    priority: P1
    item: "audit _compat_bridge.py coverage"
  - id: 7
    priority: P0
    item: "inspect external langchain_protocol schema (R7 dep)"
  - id: 8
    priority: P1
    item: "confirm indexing/ P0-vs-P1 scope (1,772 LOC / 61 tests)"
pass_7_deepening:
  date: 2026-07-12
  items_completed:
    - id: 1
      item: "runnables/base.py full internals"
      novelty: MED
      note: "4-vector RunnableBinding + config_factories, __getattr__ delegation (no Rust analog), with_retry/with_fallbacks defaults, Generator-vs-Lambda stream semantics. Refines RED-1; no new subsystem."
    - id: 2
      item: "astream_events v2 ordering (line-level)"
      novelty: MED
      note: "7-field event shape, on_<type>_<phase> taxonomy (partial combos), start-before-end streaming interleave, ls_* metadata derivation, cancellation+cleanup contract, on_tool_error tool_call_id."
    - id: 3
      item: "load/mapping.py remap table"
      novelty: LOW
      note: "4 dicts / 178 entries (SERIALIZABLE 94, OLD_CORE 58, JS 19, OG 7) merged into ALL_SERIALIZABLE_MAPPINGS; some values point to partner pkgs (langchain_aws/langchain) -> feature-gated registration. Confirms ADR-3."
    - id: 4
      item: "trim_messages vs tests"
      novelty: LOW
      note: "21 dedicated tests (not 145=file total). New surface: token_counter='approximate', start_on/end_on, text_splitter."
    - id: 5
      item: "_compat_bridge.py coverage audit"
      novelty: MED
      note: "CONTRADICTION C-2: dedicated test_compat_bridge.py exists (43 tests/1403 LOC). 3 fns bridge core chunks <-> protocol MessagesData. Collapses under a unified ContentBlock enum."
    - id: 6
      item: "langchain_protocol schema inventory"
      novelty: HIGH
      note: "CONTRADICTION C-1: full agent streaming protocol (JSON-RPC commands + 9-channel events + state/checkpoint/fork + reconnect), NOT just content blocks. Core uses ONLY MessagesData subset @ 6 sites. Not vendored (pin >=0.0.17; only 0.0.15 in docker). SPLIT the port; fetch exact 0.0.17 CDDL."
    - id: 7
      item: "indexing/ P0-vs-P1 scope"
      novelty: LOW
      note: "P1 confirmed: no external deps, RAG-ingestion utility off the LLM/agent hot path. index() cleanup modes + 4 hash algos. Mechanical port."
    - id: 8
      item: "block_translators pipeline architecture (verify only)"
      novelty: MED
      note: "CONTRADICTION C-3: registry+pipeline HYBRID (PROVIDER_TRANSLATORS registry + register_translator plugin seam + fixed 5-stage BaseMessage fallback). 8 provider modules (+google_vertexai, new) not 7; no registration.py module. 29 translator tests."
  contradictions_with_pass_1:
    - id: C-1
      severity: HIGH
      claim: "langchain_protocol = content-block streaming event schemas"
      reality: "full LangChain Agent Streaming Protocol; core uses only MessagesData subset"
    - id: C-2
      severity: MED
      claim: "_compat_bridge has no dedicated test file; coverage scattered"
      reality: "dedicated test_compat_bridge.py, 43 tests / 1403 LOC"
    - id: C-3
      severity: MED
      claim: "block_translators = provider registry (recommended) / 7 files"
      reality: "registry+fixed-pipeline hybrid already exists; 8 provider modules incl new google_vertexai; no registration.py"
    - id: C-4
      severity: LOW
      claim: "test_utils.py 145 = trim_messages tests"
      reality: "145 is file total; trim_messages has 21 dedicated tests"
    - id: C-5
      severity: LOW
      claim: "langchain-protocol pinned 0.0.17"
      reality: ">=0.0.17 (floor); not vendored; only 0.0.15 locally inspectable"
    - id: C-6
      severity: LOW
      claim: "RunnableBinding = partial kwargs"
      reality: "4 vectors incl config_factories (with_listeners) and custom_input/output_type; __getattr__ delegation has no Rust analog"
  new_adr_candidates:
    - "ADR-6 protocol scope split: core=MessagesData subset unified with core ContentBlock; full protocol deferred to graph/server crate, gen from CDDL (eliminates _compat_bridge laundering)"
    - "ADR-7 block-translator plugin registry (register_translator seam) + fixed fallback pipeline"
    - "ADR-8 astream_events cancellation & cleanup-ordering guarantee on stream drop"
  novelty_assessment:
    high: 1   # protocol scope (item 6)
    med: 4    # items 1,2,5,8
    low: 3    # items 3,4,7
    overall: MED-trending-LOW
  converged: false
  convergence_rationale: >
    Broad-sweep model is now accurate for spec crystallization; the one HIGH-novelty finding
    (protocol scope, C-1) is resolved by a scope SPLIT that keeps core small, so it does not
    expand core's port surface. Remaining open work is a targeted fetch (exact 0.0.17 CDDL
    schema) + 3 new ADR write-ups, not further reverse-engineering. One more narrow pass is
    warranted ONLY to: (a) confirm the fetched 0.0.17 schema matches the 0.0.15 approximation,
    (b) line-verify the RunnableSequence.transform/stream unification (streaming primitive ADR-5),
    and (c) enumerate the SERIALIZABLE_MAPPING entries that resolve to partner packages. All
    other items are LOW/nitpick. Recommend: NARROW pass-8, not a full re-sweep.
---
