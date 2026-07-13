---
artifact: semport/core/analysis-state
project: ferrochain
pass: 1
status: pass-1-broad-sweep-complete
deepening_run: false
date: 2026-07-12
producer: state-manager
note: persisted by state-manager on behalf of codebase-analyzer (direct write was hook-blocked)
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
---
