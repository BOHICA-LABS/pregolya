---
document_type: adr
level: L3
adr_id: "027"
slug: stable-bc-clause-anchors
title: "Stable BC Clause Anchors: Restructure-Proof AC→BC Traceability Convention"
status: accepted
producer: architect
timestamp: 2026-08-23T00:00:00Z
date: "2026-08-23"
subsystems_affected: []
supersedes: []
superseded_by: null
version: "1.1"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D-175]
changelog:
  - "1.1 (2026-08-24): Add §Scope Boundary section — documents which doc classes are IN vs OUT of the stable-anchor mandate. Prompted by adversary finding P2A-045 F-045-02. Decision: derived-prose doc classes (ADRs, domain-spec, interface-definitions, prd-supplements, VP prose, architecture section files) are OUT of scope with rationale. ~422 live-body positional citations exist across those classes; adversarial consistency sweeps are the appropriate governance mechanism, not CI-gate extension."
  - "1.0 (2026-08-23): Initial decision — human-directed stable-anchor migration (D-175). Root cause: corpus-wide audit found ~136 mis-anchored AC→BC citations across 22 of 39 stories from Phase-1 BC restructuring that shifted postcondition ordinals. Generalizes the existing EC-NNN model to all clause types."
---

# ADR-027: Stable BC Clause Anchors — Restructure-Proof AC→BC Traceability Convention

**Status:** Accepted — human-directed, 2026-08-23 (D-175).

---

## Context

A corpus-wide audit found approximately 136 mis-anchored AC→BC citations across 22 of 39
stories. Root cause: acceptance criteria cite positional ordinals such as
`(traces to BC-2.06.001 postcondition 4)`. During Phase-1 convergence, BCs were
restructured — new clauses inserted, existing clauses reordered — causing downstream ordinal
numbers to shift. The Phase-2 stories were never re-synced.

This is the exact anti-pattern banned by TD-VSDD-091 for line and record citations.
The current citation format is structurally identical to the volatile `file.rs:NNN` pattern:
both cite a positional index that changes on the next structural edit.

Edge Cases already have a correct solution: each is assigned a `### EC-NNN:` heading that
survives reordering. This ADR generalizes that model to postconditions, invariants, and
preconditions.

### Existing citation format (all four clause types)

```
### AC-NNN (traces to BC-S.SS.NNN postcondition 4)
### AC-NNN (traces to BC-S.SS.NNN invariant — code immutability)
### AC-NNN (traces to BC-S.SS.NNN precondition 2)
### AC-NNN (traces to BC-S.SS.NNN edge case EC-001)   ← already stable
```

The invariant form lacks even a number — it uses a freeform description. The validator
(`verify-ac-pc-trace.sh`, POL-48) resolves postconditions and preconditions by counting
numbered-list items and comparing ordinals; invariant citations are only weakly checked
(section existence, not clause existence). Edge case citations are resolved by `EC-NNN`
header scan — that mechanism is the model.

---

## Decision

### Decision 1 — Stable Clause Tag Format

Each postcondition, invariant, and precondition clause receives a **stable tag token**
embedded at the start of its text content. The tag syntax is:

```
{PC-NNN}    — postcondition clause (three-digit, zero-padded)
{INV-NNN}   — invariant clause
{PRE-NNN}   — precondition clause
```

IDs are **BC-local** (not globally unique): `{PC-001}` in BC-2.06.001 is distinct from
`{PC-001}` in BC-2.06.002. The BC ID in the citation resolves the scope.

IDs are **monotonically assigned at clause authoring time**, never renumbered. When a clause
is inserted between `{PC-002}` and `{PC-003}`, the new clause receives `{PC-004}` (next
available). Existing IDs never shift. Deleted clauses leave a gap in the sequence; gaps are
not backfilled.

Tags survive restructuring because they are bound to the clause text, not to a positional
index.

### Decision 2 — Placement in BC Clause

The tag is the **first token** of the clause text, immediately after the list marker:

**Postconditions** (numbered list, keep numbers for readability):
```markdown
1. {PC-001} For every phase transition that occurs during a run, exactly one typed
   `StreamEvent` variant is emitted in the ordering specified below.
2. {PC-002} The emitted event set covers all of the following variants when the
   corresponding phase occurs during a run: ...
```

**Preconditions** (numbered list):
```markdown
1. {PRE-001} A compiled `StateGraph` is executing (a `Run` is in `in_progress` status).
2. {PRE-002} A consumer has subscribed to the run's event stream.
```

**Invariants** (bullet list — may have existing bold labels; tag precedes them):
```markdown
- {INV-001} **DI-011 (Streaming / Unary Run Equivalence):** The streaming event emission
  path is driven by the same execution engine as the unary path.
- {INV-002} Start-before-end: every `*Start` event for a phase unit is emitted before
  the corresponding `*End` event for that same unit.
```

**Edge Cases** — no change. `### EC-NNN:` headers are already stable.

### Decision 3 — New AC Citation Format

```
### AC-NNN (traces to BC-S.SS.NNN PC-NNN)
### AC-NNN (traces to BC-S.SS.NNN INV-NNN)
### AC-NNN (traces to BC-S.SS.NNN PRE-NNN)
### AC-NNN (traces to BC-S.SS.NNN EC-NNN)
```

Examples:
```
### AC-001 (traces to BC-2.06.001 PC-001)
### AC-003 (traces to BC-2.06.001 PRE-001)
### AC-014 (traces to BC-2.14.002 INV-001)
### AC-008 (traces to BC-2.06.001 EC-001)
```

The old ordinal form `postcondition N`, `precondition N`, and freeform `invariant — ...`
are **retired** (see Decision 5 for the transition window).

### Decision 4 — Validator Resolution (`verify-ac-pc-trace.sh`, POL-48)

The citation regex is updated to:

```python
CITE_RE = re.compile(
    r'###\s+(AC-\d+)\s+\(traces\s+to\s+'
    r'(BC-\d+\.\d+\.\d+)\s+'
    r'(PC|INV|PRE|EC)-(\d+)'
    r'([^)]*)\)',
    re.IGNORECASE
)
```

Resolution by tag type:

| Citation form | Resolution method | CHECK-1 (blocking) |
|--------------|-------------------|--------------------|
| `PC-NNN` | Scan `## Postconditions` section for `\{PC-NNN\}` token | Tag not found → DRIFT |
| `INV-NNN` | Scan `## Invariants` section for `\{INV-NNN\}` token | Tag not found → DRIFT |
| `PRE-NNN` | Scan `## Preconditions` section for `\{PRE-NNN\}` token | Tag not found → DRIFT |
| `EC-NNN` | Scan `## Edge Cases` section for `### EC-NNN` header or table row | Unchanged |

The validator no longer counts numbered-list items by ordinal for CHECK-1. It greps for
the stable tag token. This is structurally identical to the existing EC-NNN scan.

CHECK-2 (error-code co-location, advisory) continues unchanged: given a cited clause,
extract its text by scanning from the tag token to the next list-item tag or section
boundary, then check for the error code.

### Decision 5 — Backward Compatibility During Migration

The validator operates in **dual-mode** until Phase M4 (cutover):

- If a cited BC file contains **no `{PC-NNN}` / `{INV-NNN}` / `{PRE-NNN}` tags**: the
  validator falls back to the old ordinal resolution for postconditions and preconditions,
  and accepts `invariant` with optional freeform note. This preserves green-field for
  stories whose BCs have not yet been labeled.
- If a cited BC file contains **any stable tags**: the validator enforces new-form citations
  only for that BC. Mixing old-form and new-form citations to the same BC is a CHECK-1
  DRIFT failure (`reason=mixed-form-anchor`).

This allows Phase M1 (BC labeling) and Phase M3 (AC re-citation) to proceed
independently per BC, verified incrementally.

---

## Migration Plan

### Phase M1 — BC Clause Labeling (prerequisite for M2 and M3)

**Scope:** All 133 BC files. Each BC receives `{PC-NNN}`, `{INV-NNN}`, `{PRE-NNN}` tags
on its clauses. Edge Cases are unchanged. Purely additive — no content changes.

**Batching:** 23 subsystems, batch by subsystem (5–8 BCs per subsystem). A subsystem is
complete when all its BCs are labeled and the validator reports zero DRIFT for citations
to that subsystem's BCs.

**Estimated scope:** ~133 BCs × average 8 clauses = ~1,060 tag insertions. Mechanical
work; a specialist (story-writer or product-owner) can process a subsystem in one burst.

**Estimated duration:** 3–4 burst cycles across subsystems.

### Phase M2 — Validator Rework

**Scope:** `verify-ac-pc-trace.sh` (one file). Update CITE_RE and resolution logic to
implement Decision 4 dual-mode. Blocked on M1 for at least one subsystem (smoke test).

**Estimated duration:** 1 burst cycle.

### Phase M3 — AC Re-citation

**Scope:** All 39 story files. Update every AC citation from the old ordinal form to the
new stable-anchor form. The ~136 known mis-anchored citations are **corrected** in the
same pass — since we must re-read each BC to confirm the stable tag, wrong ordinals are
caught and fixed at zero marginal cost.

**Coverage-gap items** (ACs that cited a clause that does not exist in the BC): these
are escalated to product-owner to either (a) add the missing BC clause, or (b) reroute
the AC to the correct clause. They are NOT silently discarded.

**Ordering:** M3 proceeds subsystem by subsystem, after that subsystem's BCs are labeled
(M1 complete for that subsystem). A story can be re-cited as soon as all BCs it traces to
are labeled.

**Estimated scope:** ~500 AC lines across 39 stories. Mechanical but requires reading
each BC to map old ordinals to new stable IDs.

**Estimated duration:** 3–4 burst cycles.

### Phase M4 — Backward-Compat Cutover

**Scope:** `verify-ac-pc-trace.sh` (one file). Remove dual-mode fallback. All citations
must use stable IDs. Run validator corpus-wide; zero DRIFT required before cutover.

**Gate:** M3 complete for all 39 stories.

**Estimated duration:** 1 burst cycle.

---

## Rationale

The EC-NNN model is already proven in this corpus — edge cases have never suffered
from ordinal drift because their IDs are structural headers, not positional counts.
The only question was how to apply the same principle to list-item clauses.

**Tag-token approach vs. sub-section approach**: Each clause could be promoted to a
`### PC-NNN:` sub-section heading (matching EC-NNN). This would be highly parseable but
massively disruptive to BC readability — postconditions that currently read as a compact
numbered list would become a cascade of sub-sections. The inline tag token `{PC-NNN}`
achieves the same machine-parseability with zero structural disruption.

**BC-local scope vs. global IDs**: Global IDs (e.g., `PC-2.06.001-001`) would be
unambiguous but verbose and redundant — the BC ID already scopes the citation. BC-local
IDs keep the tags short and authoring friction minimal.

**Keep ordinal numbers**: The numbered list format (`1. {PC-001} ...`) is retained for
human readability. The ordinal is decorative under the new regime; the `{PC-001}` tag is
the machine-canonical identifier. Removing the numbers would harm readability for no gain.

**Invariant precision gain**: The current `invariant — code immutability` freeform citation
is not validator-checkable. Moving to `INV-003` gives invariants the same verification
precision as postconditions, closing a long-standing CHECK-1 gap.

## Alternatives Considered

### A1: Rename each clause to a sub-section heading (EC-NNN model exactly)

Promoting every postcondition to `### PC-NNN: ...` matches EC-NNN structurally.

**Rejected** because: postconditions are compact list items often with sub-bullets and
code blocks. Wrapping each in a `###` heading would shatter BC readability. The EC model
works for edge cases because each EC is genuinely a mini-spec worthy of a heading; a
simple postcondition like "Returns HTTP 201 with the created Thread record" is not.

### A2: Hash-based content fingerprints

Cite by SHA-prefix of the clause text, e.g., `PC-SHA:a3f9b2`. Restructure-proof and
requires no authoring annotation.

**Rejected** because: (a) not human-readable in the citation or in the BC; (b) any typo
fix or wording update invalidates the citation silently; (c) validator must compute hashes
at check time, adding fragility. Behavioral meaning should be the anchor, not byte content.

### A3: Bold-label mandate (reuse existing `**Label:**` pattern)

Invariants already use bold labels (`**DI-011 (...):**`). Mandate that every clause have
a unique bold label and cite by label text.

**Rejected** because: (a) labels are freeform prose, not stable IDs — they can be
rephrased without breaking the citation only if the validator does fuzzy matching; (b)
postconditions and preconditions rarely have natural bold labels; (c) machine-parsing
prose labels is fragile. A structured `{TYPE-NNN}` token is unambiguous.

### A4: Accept the status quo, fix only the known 136 mis-anchors

Re-cite the 136 wrong ordinals to the correct ordinals without adding stable tags.

**Rejected** because: this fixes the symptom, not the cause. The next BC restructuring
(Phase 5 adversarial refinement is known to trigger BC clause insertions) would create
a new drift wave. The production-grade fix is a structural change that makes drift
impossible, not a one-time repair.

## Consequences

### Positive

- AC→BC citations are restructure-proof: inserting or reordering clauses cannot silently
  break any trace.
- Invariant citations gain machine-checkable precision: `INV-003` is verified to exist;
  freeform `invariant — code immutability` is not.
- The validator's CHECK-1 for postconditions/invariants/preconditions becomes
  structurally identical to the already-correct EC-NNN check.
- TD-VSDD-091 compliance: tags are behavioral anchors (symbol-like identifiers), not
  positional line or ordinal references.

### Negative / Trade-offs

- BC authoring burden: new clauses require a tag assignment (low friction; just
  increment the counter).
- Migration scope is substantial: ~133 BCs and 39 stories. Phased batching manages this.
- Deleted-clause gaps in the ID sequence may cause confusion; the rule "gaps are
  not backfilled" must be understood by authors.

### Invariant: no ID collisions within a BC

Within a single BC, no two clauses of the same type share the same NNN. The
product-owner is the enforcer; the validator provides the gate.

---

## Scope Boundary

This section documents which document classes are **IN** vs **OUT** of the stable-anchor
mandate. It was added in v1.1 in response to adversary finding P2A-045 F-045-02, which
observed that ~422 positional BC-clause citations exist in derived-prose document classes
not covered by M1–M4.

### IN scope (machine-validated CI gate)

| Doc class | Count | Mechanism |
|-----------|-------|-----------|
| BC files | ~133 files, ~1,060 clause tags | M1: tag insertion; validator CHECK-1 gate |
| Story files | ~39 files, ~500 AC lines | M3: re-citation; `verify-ac-pc-trace.sh` CI gate |

The CI gate (`verify-ac-pc-trace.sh`, POL-48) runs against these classes only. The gate
format is structured (`### AC-NNN (traces to BC-S.SS.NNN PC-NNN)`); extending it to
unstructured prose in other doc classes would require class-specific parsers and
ADR-immutability exceptions.

### OUT of scope (adversary-pass governance)

| Doc class | Approx live-body citations | Rationale for OUT |
|-----------|---------------------------|-------------------|
| ADR decision files | ~88 | ADRs are **immutable-when-ratified**. They capture historical grounding at the moment of ratification. When a BC evolves, the correct response is ADR supersession, not in-place re-citation. Migrating ADR prose to stable anchors would invert the supersession model. |
| interface-definitions.md | ~240 | Informational cross-references, not traceability anchors. Co-evolved with BCs in the same bursts. Stale citations are caught by adversary passes and consistency-validator sweeps. |
| domain-spec live body | ~30 | Informational authority footnotes (e.g., "Source: BC-2.12.001 PC5"). Drift is caught by adversary passes; the citation serves the human reader, not the CI gate. |
| Architecture section files (non-ADR) | ~24 | Informational rationale links. Same governance model as domain-spec. |
| PRD supplements (error-taxonomy, test-vectors, observability) | ~33 | These co-evolve with BCs in the same bursts and are covered by the adversary consistency-sweep standing discipline. |
| VP prose | ~7 | Small volume. See editorial note below. |

**Total OUT-of-scope citations: ~422** (comparable to the M1–M3 combined workload; a
formal M5 sweep without CI-gate extension would be aspirational editorial policy without
machine enforcement — weaker guarantees at higher maintenance cost than adversary governance).

### Governing rationale

The fundamental distinction is **citation role**:

- **Story AC citations** are formal machine-validated traceability links. Their correctness
  is a CI gate condition. Stale ordinals silently pass the current validator — the exact
  failure ADR-027 exists to prevent. Stable anchors + CI gate is the correct fix.

- **Derived-prose citations** are informational cross-references. A stale `PC9` reference
  in an ADR rationale or in interface-definitions prose does NOT silently pass a CI gate;
  it is flagged by adversary passes (the standing discipline already covers this).
  The appropriate mitigation is adversary-pass governance, not CI-gate extension.

### VP editorial note (soft guidance, no CI gate)

VP prose has ~7 positional citations. VP authors SHOULD use stable-anchor form
(`BC-2.NNN.NNN PC-NNN`) when citing specific postconditions in new VP files, as a good
practice that reduces adversary-pass churn. This is editorial guidance; no CI enforcement
is planned given the small volume and Phase 6 timeline.

### Drift-risk mitigation for OUT-of-scope classes

When a BC is restructured (clause insertion, deletion, reorder):

1. **Product-owner** updates the BC stable tags (M1 discipline).
2. **Adversary passes** on the same burst check `BC-S.SS.NNN PC<n>` citations in derived
   prose against the updated BC. A stale citation is a consistency finding.
3. **BC version event** (version bump in BC frontmatter) signals downstream doc owners to
   review cross-references. State-manager records the version bump; spec-steward governs
   traceability audit on request.

This is the standing governance model. No new process is required for OUT-of-scope classes.

---

## Source / Origin

- Human senior architect ruling, 2026-08-23 (D-175): migrate AC→BC citations to stable
  behavioral anchors; use the existing EC-NNN model as the template.
- Root-cause finding: ~136 mis-anchored citations across 22 stories from Phase-1 BC
  restructuring; ordinal citations violated TD-VSDD-091's anti-volatile-pin principle.
- ADR-022 (§Named-Section Citation Convention) is the sibling ADR governing
  `§Section-Name` citation stability.
- Scope boundary (v1.1): assessed ~422 derived-prose citations and decided (b)
  Document Boundary; adversary finding P2A-045 F-045-02 resolved as a documented
  defensible decision rather than a scope extension.

---

## Open Items (pre-migration)

| Item | Owner | When |
|------|-------|------|
| Assign D-175 decision number to this ADR | state-manager | Next burst |
| Update POL-48 wording in policies.yaml to reference stable-anchor form | spec-steward | After M2 |
| Update BC template to include tag guidance for new BCs | product-owner | After M1 |
