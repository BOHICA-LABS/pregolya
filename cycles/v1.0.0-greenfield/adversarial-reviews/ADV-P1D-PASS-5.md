---
document_type: adversarial-review
pass: 5
reviewer: adversary
timestamp: 2026-07-14T00:00:00Z
verdict: NOT_CLEAN
finding_count: 3
high_count: 1
med_count: 2
trajectory: [14, 5, 7, 13, 3]
novelty: MEDIUM-HIGH
structural_axes: stable
---

# ADV-P1D-PASS-5: Phase 1d Adversarial Review — Pass 5

**Verdict:** NOT CLEAN
**Finding count:** 3 (1 HIGH, 2 MED)
**Trajectory:** 14 → 5 → 7 → 13 → 3
**Novelty:** MEDIUM-HIGH — new finding axis (canonical category/component representation
drift); structural axes (BC completeness, traceability, edge-case coverage, invariant
lifting, capability anchoring) are stable and passing.

## Sibling Dimension Table

| Dimension | Status |
|-----------|--------|
| BC Completeness | PASS |
| Traceability | PASS |
| Edge Case Coverage | PASS |
| Test Vectors | PASS |
| Invariant Lifting | PASS |
| Capability Anchoring | PASS |
| Category / Component Canonical Representation | FAIL |

---

## Findings

### F-P5-01 [HIGH] — Fictitious Error Categories in BC Bodies and Domain Spec

**Scope:**
- BC-2.04.001 EC-002 + TV row-3
- BC-2.04.003 EC-003 + TV row-3
- BC-2.04.004 EC-003 + TV row-3
- `domain-spec/edge-cases.md` DEC-012 line 124
- `domain-spec/entities-server.md` §MCPTool line 111

**Observation:** Three category tokens appear in BC prose and domain-spec that are not
members of the canonical error taxonomy defined in `prd-supplements/error-taxonomy.md`
(§ Error Category Codes):

| Fictitious token | Count | Correct canonical code | Error code anchor |
|----------------|-------|----------------------|------------------|
| `CheckpointError` | 4 | DURABILITY (BC-2.04.001) / INTERNAL (BC-2.04.003) | E-CHKPT-001 / E-CHKPT-002 |
| `StateUpdateError` | 2 | VAL | E-GRAPH-007 |
| `ToolError` | 2 | TOOL | E-MCP-001 |

**Failure scenario:** A test-writer follows BC-2.04.001 EC-002 and attempts to write a
Rust assertion `assert_eq!(err.category(), Category::CheckpointError)`. The Rust compiler
rejects the code because `Category::CheckpointError` is not a variant of the `Category`
enum. The test cannot compile; the Red Gate discipline for the error path is broken before
implementation even begins.

**Fix applied (this pass):**
- BC-2.04.001 EC-002 + TV: `CheckpointError` → `DURABILITY, code: E-CHKPT-001`
- BC-2.04.003 EC-003 + TV: `CheckpointError` → `INTERNAL, code: E-CHKPT-002`
- BC-2.04.004 EC-003 + TV: `StateUpdateError` → `VAL, code: E-GRAPH-007`
  (note: no E-CHKPT code exists for update_state unknown-channel validation; the operation
  is at the GRAPH layer; E-GRAPH-007 UnknownChannelKey is the semantically correct code)
- edge-cases.md DEC-012: `ToolError` → `TOOL`
- entities-server.md §MCPTool: `ToolError` → `TOOL`

---

### F-P5-02 [MED] — PascalCase Drift in `category:`/`component:` Inline Code Slots

**Scope:**
- BC-2.08.001 EC-003 (line 103): `category: Transport`
- BC-2.09.004 TV-001 (line 120): `category: Tool`
- BC-2.10.003 Description (line 34) + Postconditions (line 58): `component: Budget, category: Policy`
- BC-2.14.001 EC-001 (line 86): `component: Chkpt, category: Durability`
- edge-cases.md DEC-013 (lines 131, 134): `category: Transport`, `category: Timeout`
- VP-003.md (lines 75, 114): `category: Security`
- BC-2.14.002 TV-001 (line 123): `component: Core`
- BC-2.14.002 TV-002 (line 124): `component: Prov`

**Observation:** Multiple `category:` and `component:` slots in BC prose, domain-spec,
and verification property inline code snippets used PascalCase tokens (`Transport`, `Tool`,
`Budget`, `Policy`, `Chkpt`, `Durability`, `Timeout`, `Security`, `Core`, `Prov`) instead
of the canonical ALL-CAPS taxonomy codes. The canonical codes are:

- **Categories:** VAL, AUTH, RATE, TIMEOUT, TRANSPORT, INTERNAL, DURABILITY, POLICY,
  TOOL, CONCURRENCY, SECURITY, TENANCY
- **Components:** CORE, GRAPH, CHKPT, SERVER, PROV, MCP, SPLIT, SBXD, RETRY, CRON,
  MEMORY, BUDGET

Additionally, BC-2.14.001 was internally inconsistent: its Description section established
the ALL-CAPS convention but omitted four later-added components (RETRY, CRON, MEMORY,
BUDGET), and EC-001 used bare PascalCase `Chkpt`/`Durability` — violating the convention
defined in the same BC.

**Failure scenario:** A reader of BC-2.10.003 sees ``component: Budget, category: Policy``
in a code slot and writes that into a Rust test. This does not compile; Rust enum paths are
`Component::Budget` and `Category::Policy`. BC-2.14.001 does not resolve the ambiguity
because EC-001 mixed the rendering — leaving implementers and test-writers guessing.

**Fix applied (this pass):**
- BC-2.08.001 EC-003: `Transport` → `TRANSPORT`
- BC-2.09.004 TV-001: `Tool` → `TOOL` (Red Gate TV — only the category token changed;
  all other TV content is verbatim-correct and unchanged)
- BC-2.10.003 Description + Postconditions: `Budget` → `BUDGET`, `Policy` → `POLICY`
- BC-2.14.001 Description: added RETRY, CRON, MEMORY, BUDGET to component list; added
  explicit dual-rendering rule paragraph
- BC-2.14.001 EC-001: `Chkpt` → `CHKPT`, `Durability` → `DURABILITY`
- edge-cases.md DEC-013: `Transport` → `TRANSPORT`, `Timeout` → `TIMEOUT`
- VP-003.md (lines 75, 114): `Security` → `SECURITY`
- BC-2.14.002 TV-001: `Core` → `CORE`
- BC-2.14.002 TV-002: `Prov` → `PROV`

---

### F-P5-03 [MED] — Process Gap: Pass-4 Grep Evidence Admitted False Negatives

**Scope:** Review methodology meta-finding. No BC file change required.

**Observation:** Pass-4 used a `[^_]\b`-anchored regex pattern to exclude known-canonical
ALL-CAPS values. This is an enumerate-known-bad methodology: it builds a blocklist and
assumes everything else is acceptable. It produced false negatives for `Chkpt`, `Budget`,
`Durability`, `Transport`, `Timeout`, `Tool`, `Security`, `Core`, `Prov` — all of which
should have been caught in pass-4.

Root causes:
1. The `[^_]\b` pattern cannot distinguish `TRANSPORT` from `Transport` when
   both words follow `category: ` — it depends on which words were put on the blocklist.
2. Adding new values to the PascalCase set requires updating the blocklist, which can
   itself miss values.
3. Enumerate-known-bad methodology has unbounded false-negative rate: any PascalCase
   value not on the list is silently accepted.

**Mandated fix — complement-assertion methodology:**

Evidence for category/component coverage MUST be produced by extracting EVERY distinct
value and asserting each is a member of the canonical set:

```
grep -rhoE "category: [A-Za-z_]+" .factory/specs/ | sort | uniq -c
grep -rhoE "component: [A-Za-z_]+" .factory/specs/ | sort | uniq -c
```

Any value outside the canonical sets is a finding. Justified exceptions must be listed
individually with rationale (see §Post-Fix Tables below).

**Phase-2 xtask lint backlog:** Widen the existing Phase-2 xtask lint backlog item to
include a complement-assertion check over all `.factory/specs/` `category:` and
`component:` occurrences. The lint should:
1. Extract all distinct values via the grep patterns above.
2. Diff against the canonical sets hard-coded in the lint script.
3. Fail CI on any non-member value not present in an explicit exception list.

---

## Post-Fix Complement Evidence Tables

Both tables were produced after all fixes were applied.

### `category:` distinct values (post-fix)

```
  33 category: VAL
  22 category: INTERNAL
  12 category: TIMEOUT
  11 category: TRANSPORT
   9 category: POLICY
   8 category: TOOL
   7 category: Category
   4 category: RATE
   4 category: DURABILITY
   3 category: AUTH
   2 category: SECURITY
   2 category: CONCURRENCY
   1 category: ErrorCategory
```

| Value | Status | Justification |
|-------|--------|---------------|
| VAL | CANONICAL | — |
| INTERNAL | CANONICAL | — |
| TIMEOUT | CANONICAL | — |
| TRANSPORT | CANONICAL | — |
| POLICY | CANONICAL | — |
| TOOL | CANONICAL | — |
| RATE | CANONICAL | — |
| DURABILITY | CANONICAL | — |
| AUTH | CANONICAL | — |
| SECURITY | CANONICAL | — |
| CONCURRENCY | CANONICAL | — |
| `Category` | EXCEPTION | Rust enum type name captured from full paths like `category: Category::Val` in Postconditions code blocks. Not a value slot; the `::Val` suffix is stripped by the `[A-Za-z_]+` regex. |
| `ErrorCategory` | EXCEPTION | Field type annotation in `domain-spec/entities-server.md` entity schema definition: `category: ErrorCategory (Authentication | Validation | …)`. This is a type name in a schema, not a code slot value. |

### `component:` distinct values (post-fix)

```
   7 component: Component
   4 component: MCP
   3 component: RETRY
   2 component: SBXD
   2 component: CHKPT
   2 component: BUDGET
   1 component: PROV
   1 component: no
   1 component: GRAPH
   1 component: FerrochainComponent
   1 component: CORE
```

| Value | Status | Justification |
|-------|--------|---------------|
| MCP | CANONICAL | — |
| RETRY | CANONICAL | — |
| SBXD | CANONICAL | — |
| CHKPT | CANONICAL | — |
| BUDGET | CANONICAL | — |
| PROV | CANONICAL | — |
| GRAPH | CANONICAL | — |
| CORE | CANONICAL | — |
| `Component` | EXCEPTION | Rust enum type name captured from full paths like `component: Component::Core` in Postconditions code blocks. Same pattern as `Category` exception above. |
| `no` | EXCEPTION | English prose in BC-2.03.003 §Invariants: "The sort key contains no runtime-non-deterministic component: no `Instant::now()`, …" — the word `no` is part of an English sentence, not a code slot. |
| `FerrochainComponent` | EXCEPTION | Field type annotation in `domain-spec/entities-server.md` entity schema definition: `component: FerrochainComponent (enum covering all ferrochain crate names)`. Same pattern as `ErrorCategory` exception above. |

**TENANCY** (canonical category) and **SERVER, SPLIT, PROV, CRON, MEMORY** (canonical
components) have zero occurrences in the specs tree — they are canonical but unused in
current BCs. Zero occurrences is not a finding; those codes are valid for future BCs.

---

## Summary of Files Modified (This Pass)

| File | Finding | Change |
|------|---------|--------|
| `.factory/specs/behavioral-contracts/ss-04/BC-2.04.001.md` | F-P5-01 | EC-002 + TV: `CheckpointError` → `DURABILITY, code: E-CHKPT-001` |
| `.factory/specs/behavioral-contracts/ss-04/BC-2.04.003.md` | F-P5-01 | EC-003 + TV: `CheckpointError` → `INTERNAL, code: E-CHKPT-002` |
| `.factory/specs/behavioral-contracts/ss-04/BC-2.04.004.md` | F-P5-01 | EC-003 + TV: `StateUpdateError` → `VAL, code: E-GRAPH-007` |
| `.factory/specs/behavioral-contracts/ss-08/BC-2.08.001.md` | F-P5-02 | EC-003: `Transport` → `TRANSPORT` |
| `.factory/specs/behavioral-contracts/ss-09/BC-2.09.004.md` | F-P5-02 | TV-001: `Tool` → `TOOL` |
| `.factory/specs/behavioral-contracts/ss-10/BC-2.10.003.md` | F-P5-02 | Description + Postconditions: `Budget` → `BUDGET`, `Policy` → `POLICY` |
| `.factory/specs/behavioral-contracts/ss-14/BC-2.14.001.md` | F-P5-02 | Description: add RETRY/CRON/MEMORY/BUDGET + dual-rendering note; EC-001: `Chkpt`/`Durability` → `CHKPT`/`DURABILITY` |
| `.factory/specs/behavioral-contracts/ss-14/BC-2.14.002.md` | F-P5-02 | TV-001: `Core` → `CORE`; TV-002: `Prov` → `PROV` |
| `.factory/specs/domain-spec/edge-cases.md` | F-P5-01 + F-P5-02 | DEC-012: `ToolError` → `TOOL`; DEC-013: `Transport`/`Timeout` → `TRANSPORT`/`TIMEOUT` |
| `.factory/specs/domain-spec/entities-server.md` | F-P5-01 | §MCPTool: `ToolError` → `TOOL` |
| `.factory/specs/verification-properties/VP-003.md` | F-P5-02 | Lines 75/114: `Security` → `SECURITY` |
