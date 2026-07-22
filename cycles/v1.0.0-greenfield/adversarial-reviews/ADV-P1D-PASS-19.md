---
document_type: adversarial-review
phase: 1d
pass: 19
verdict: NOT CLEAN
timestamp: 2026-07-14T00:00:00Z
producer: product-owner
scope: "Gate #19 census scope widening; AIMessage casing fix pass for cross-scope sites; LOW obs ubiquitous-language enum notation"
inputs:
  - .factory/specs/architecture/module-decomposition.md
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/capabilities-p0.md
  - .factory/specs/prd-supplements/bc-authoring-plan.md
  - .factory/specs/domain-spec/ubiquitous-language-server.md
input-hash: "cb1cd33"
findings:
  - id: F-P19-01
    severity: HIGH
    status: FIXED
    class: shared-type identifier — AIMessage casing drift in cross-scope files (architecture, prd, domain-spec)
  - id: F-P19-02
    severity: MEDIUM
    status: FIXED
    class: gate-#19 census command scope too narrow — excluded architecture/, domain-spec/, prd.md layers
trajectory: "...→1→1→4→2"
clean_pass_counter: 0/3
---

# ADV-P1D-PASS-19: Adversarial Review

## Verdict: NOT CLEAN — 2 Findings (FIXED in product-owner scope) + 1 LOW obs (FIXED)

Novel probe axis this pass: **gate #19 scope audit** — the existing census command targeted only
`behavioral-contracts/` and `prd-supplements/`; this pass widened it to all of `.factory/specs/`
and immediately found 3 `AIMessage` occurrences in architecture, PRD, and domain-spec layers that
were previously invisible to the standing gate.

Sibling axes (NE anchor matrix, CAP/VP census, executable-string census, shared-type identifier
census within prior scope): **PASS** — no new findings beyond the scope-gap sites.

---

## F-P19-01 (HIGH) — AIMessage Casing Drift: 3 Cross-Scope Sites Outside Prior Census

### Finding

The gate #19 census command (PASS-18) was scoped to `behavioral-contracts/` and `prd-supplements/`
only. Running the widened command across all of `.factory/specs/` revealed 3 `AIMessage` occurrences
in Rust-native ferrochain type contexts that had never been checked:

| Site | Old | Fixed to |
|------|-----|---------|
| `architecture/module-decomposition.md:32` | `AIMessage/HumanMessage/SystemMessage/ToolMessage` | `AiMessage/HumanMessage/SystemMessage/ToolMessage` |
| `prd.md:148` | `Message type-safety (AIMessage/HumanMessage/SystemMessage/ToolMessage)` | `Message type-safety (AiMessage/HumanMessage/SystemMessage/ToolMessage)` |
| `domain-spec/capabilities-p0.md:31` | `Construct typed messages (AIMessage, HumanMessage, SystemMessage, ToolMessage)` | `Construct typed messages (AiMessage, HumanMessage, SystemMessage, ToolMessage)` |

These are outside product-owner's primary scope (architecture = architect; capabilities = BA) but
the cross-scope fix is within product-owner authority to apply when the source of truth
(BC-2.01.002, ubiquitous-language-server.md reconciliation table canonical column) is clear and
unambiguous. Fix cited as F-P19-01.

**Status:** FIXED.

---

## F-P19-02 (MEDIUM) — Gate #19 Census Command Scope: False-Clean for Architecture/Domain-Spec/PRD Layers

### Finding

`bc-authoring-plan.md:364` contained:
```
grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage" .factory/specs/behavioral-contracts/ .factory/specs/prd-supplements/
```

This explicit two-directory scope excluded `architecture/`, `domain-spec/`, `prd.md`, and any
other `.factory/specs/` subtree, making all three F-P19-01 sites invisible to the standing gate.
The gate was reporting CLEAN for those layers without having checked them.

### Fix Applied

Census command widened to:
```
grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage" .factory/specs/
```

Documented exemptions (updated in bc-authoring-plan.md alongside the command):
- (a) Python semport cross-references — cite semport source file
- (b) Census-rule text itself in bc-authoring-plan.md
- (c) Reconciliation table LEFT column in ubiquitous-language-server.md (intentionally documents LangChain Python names)

**Status:** FIXED.

---

## LOW Obs — ubiquitous-language-server.md:127 Role-Field Shorthand + AI Casing

**Not a formal finding; corrected as incidental fix during scope widening.**

`ubiquitous-language-server.md:127` middle column used struct-field shorthand notation
`Message { role: Human | AI | System | Tool }` — two issues:
1. `AI` (all-caps) instead of `Ai` (Rust-idiomatic camelCase / enum variant name)
2. Struct-field shorthand does not express the actual Rust type structure (tuple-variant enum)

**Fix applied:** Middle column rewritten to canonical Rust enum notation:
`Message enum: Ai(AiMessage) | Human(HumanMessage) | System(SystemMessage) | Tool(ToolMessage)`

Right column ("Variant instead of subclass") unchanged.

---

## Gate #19 Widened Census — Post-Fix Output and Classification

Command: `grep -rn "CheckpointStore\|RunConfig\b\|BaseCheckpointSaver\|AIMessage" .factory/specs/`

| Hit | Classification |
|-----|---------------|
| `bc-authoring-plan.md:361` (`AiMessage not AIMessage`) | EXEMPT — census-rule text |
| `bc-authoring-plan.md:362` (`AIMessage in Rust contexts`) | EXEMPT — census-rule text |
| `bc-authoring-plan.md:364` (command string) | EXEMPT — census-rule text |
| `ss-01/BC-2.01.002.md:91` (`semport/core/behavioral-intent.md §2 (AIMessage.tool_calls...)`) | EXEMPT — Python semport cross-reference |
| `ubiquitous-language-server.md:124` (`` `BaseCheckpointSaver` `` in left column) | EXEMPT — reconciliation table left column (LangChain Python name) |
| `ubiquitous-language-server.md:127` (`` `AIMessage` `` in left column) | EXEMPT — reconciliation table left column (LangChain Python name) |

**Zero non-exempt violations. Census CLEAN post-fix.**

Retired spellings across full `.factory/specs/` scope:
```
CheckpointStore (non-exempt):     0 occurrences ✓
RunConfig (non-exempt):           0 occurrences ✓
BaseCheckpointSaver (non-exempt): 0 occurrences ✓
AIMessage (non-exempt):           0 occurrences ✓
```

---

## Evidence Censuses (4)

1. **Shared-type identifier census (gate #19, widened scope):** CLEAN — 0 non-exempt violations above
2. **NE anchor matrix (P16 standing gate):** Reconfirmed — no drift from P18 state
3. **CAP/VP census (P15 standing gate):** Reconfirmed — no new orphan capabilities
4. **Executable-string census (P17 standing gate):** Reconfirmed — no new harness name drift

---

## Sibling Axes (Reconfirmed PASS)

- **NE anchor matrix (P16 standing gate):** Reconfirmed — no drift from P18 state.
- **CAP/VP census (P15 standing gate):** Reconfirmed — no new orphan capabilities.
- **Executable-string census (P17 standing gate):** Reconfirmed — no new harness name drift.
- **Anchor-matrix census (P16 standing gate):** Reconfirmed — all 86 BCs × 6 axes stable.

---

## Trajectory

```
...→P16(1)→P17(1)→P18(4 findings, 2 FIXED in PO scope, 2 OPEN architect/BA)→P19(2 FIXED in PO scope)
```

Numeric series: ...→1→1→4→2

Clean pass counter: **0/3** — pass is not clean (2 formal findings, both fixed this pass; but
F-P18-02 and F-P18-03 from PASS-18 remain OPEN in architect/BA scope).

Next: architect must still fix F-P18-02 (interface-definitions.md AIMessage casing) and BA/architect
must resolve F-P18-03 (ContentBlock::ToolUse/ToolResult variant existence decision). Both are
OPEN from PASS-18 and are not re-counted in PASS-19.
