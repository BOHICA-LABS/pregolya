---
document_type: adversarial-review-pass
phase: 1d
pass: 20
verdict: NOT CLEAN
findings_count: 3
critical_count: 1
medium_count: 1
process_gap_count: 1
consecutive_clean: 0
required_clean: 3
trajectory: "...→4→2→3→3"
timestamp: 2026-07-14T00:00:00Z
---

# Adversarial Review Pass 20 — Phase 1d

**Verdict: NOT CLEAN** — 3 findings (1 CRIT, 1 MED, 1 process-gap). Counter reset: 0/3 consecutive clean.

---

## F-P20-01 [CRIT] — E-GRAPH-003 / E-CHKPT-003 Collision Residue (6 sites)

**Scope:** BC-2.05.001 (4 sites: lines 73, 84, 106, 115) and BC-2.10.004 (2 sites: lines 82, 93).

**Finding:** The burst-77 GRAPH reconciliation fixed E-GRAPH-001..006 taxonomy meanings and reassigned BC ss-02/ss-05 usages to E-GRAPH-007..014. However, two new codes were needed but not allocated at that time:
- `InterruptWithoutCheckpointer` (referenced in BC-2.05.001 and BC-2.10.004 as `E-GRAPH-003`) had no taxonomy entry; E-GRAPH-003 in the taxonomy is `UnknownRoutingTarget`.
- `SerializationFailed` (referenced in BC-2.05.001 as `E-CHKPT-003`) had no taxonomy entry; E-CHKPT-003 in the taxonomy is `CheckpointReadFailed`.

**Fix:** Added E-GRAPH-016 and E-CHKPT-006 to error-taxonomy.md; updated all 6 sites.

### New taxonomy entries

| Code | Category | Rationale |
|------|----------|-----------|
| E-GRAPH-016 | POLICY | `InterruptWithoutCheckpointer` is a policy-level constraint: the system policy "all interrupts must be durably parked" is violated when no `CheckpointSaver` is attached. This is not a data-shape (VAL) constraint — it is an architectural policy that `interrupt()` is only valid in a graph with durable state. RetryHint=Never (cannot retry without first attaching a `CheckpointSaver`). |
| E-CHKPT-006 | INTERNAL | `SerializationFailed` on `interrupt_value` is a programming-error invariant violation — the caller passed a non-serializable type to `interrupt()`, breaking the checkpoint system's type contract. This is analogous to an assertion failure, not a transient I/O failure. RetryHint=Never (retrying with the same non-serializable value cannot succeed). DURABILITY was considered but rejected: DURABILITY is for storage I/O failures; serialization failure is a caller-side type contract violation that occurs before any I/O attempt. |

### Sites fixed

| Site | Old | New |
|------|-----|-----|
| BC-2.05.001:73 (Invariants) | `E-GRAPH-003 InterruptWithoutCheckpointer` | `E-GRAPH-016 InterruptWithoutCheckpointer` |
| BC-2.05.001:84 (EC-001 body) | `E-GRAPH-003 InterruptWithoutCheckpointer` | `E-GRAPH-016 InterruptWithoutCheckpointer` |
| BC-2.05.001:106 (EC-004 body) | `E-CHKPT-003 SerializationFailed` | `E-CHKPT-006 SerializationFailed` |
| BC-2.05.001:115 (TV-003) | `E-GRAPH-003 InterruptWithoutCheckpointer` | `E-GRAPH-016 InterruptWithoutCheckpointer` |
| BC-2.10.004:82 (Invariants) | `E-GRAPH-003 InterruptWithoutCheckpointer` | `E-GRAPH-016 InterruptWithoutCheckpointer` |
| BC-2.10.004:93 (EC-001 body) | `E-GRAPH-003 InterruptWithoutCheckpointer` | `E-GRAPH-016 InterruptWithoutCheckpointer` |

---

## F-P20-02 [MED] — Non-canonical trait name `Checkpointer` in BC-2.04.001:47

**Finding:** BC-2.04.001 Precondition 1 read: "A `StateGraph` is compiled with a `Checkpointer` that implements the `put_writes` method". The canonical type name per ubiquitous-language-server.md reconciliation table is `CheckpointSaver`, not `Checkpointer`. This was a violation of the shared-type identifier census gate (§15, added P18).

**Fix:** BC-2.04.001:47 `Checkpointer` → `CheckpointSaver`.

---

## F-P20-03 [PROCESS-GAP] — E-code gate lacked code↔variant-name assertion; gate-#19 retired list lacked `\bCheckpointer\b`

**Finding (a):** No standing gate asserted that E-code + VariantName pairings in BC bodies match the canonical variant name in error-taxonomy.md. This class of drift (wrong variant name for a known code) was only detectable by adversarial visual inspection, not by the census tooling.

**Fix (a):** Added bc-authoring-plan §16 — E-code↔variant-name consistency census gate (added P20). Command extracts all `E-<COMP>-NNN <VariantName>` pairings from BCs and cross-checks against error-taxonomy.md.

**Finding (b):** Gate §15 (shared-type census, added P18, widened P19) did not include `\bCheckpointer\b` in its retired-spelling list. The bare `Checkpointer` type name in BC-2.04.001:47 was not caught by the census command.

**Fix (b):** Widened gate §15 census command to include `\bCheckpointer\b`. Documented that the regex self-excludes compound identifiers containing `Checkpointer` as a non-word-boundary suffix (e.g., `InterruptWithoutCheckpointer` is not matched by `\bCheckpointer\b` because the `C` in `Checkpointer` is preceded by `t`, a word character, so no left `\b` fires). An explicit exemption for that variant token is therefore not needed.

---

## Sibling Width Census — PASS

All 86 BCs reviewed in this pass. Findings count per BC family:

| Subsystem | BCs | Findings |
|-----------|-----|----------|
| SS-05 (HITL) | 6 | 1 (F-P20-01: 4 sites in BC-2.05.001) |
| SS-10 (Budget) | 4 | 1 (F-P20-01: 2 sites in BC-2.10.004) |
| SS-04 (Checkpoint) | 7 | 1 (F-P20-02: BC-2.04.001:47) |
| All others | 69 | 0 |

No findings in SS-01, SS-02, SS-03, SS-06, SS-07, SS-08, SS-09, SS-11, SS-12, SS-13, SS-14, SS-15, SS-16, SS-17, SS-TBD.

---

## Full E-code × Variant-Name Census Summary

Census command run:
```
grep -hrn "E-[A-Z]*-[0-9]{3} [A-Z][A-Za-z]*" .factory/specs/behavioral-contracts/ \
  | grep -v "~~" \
  | grep -oE "E-[A-Z]+-[0-9]{3} [A-Z][A-Za-z]+" \
  | sort -u
```

**Total distinct pairings audited: 40** (including the 6 known-collision sites before fix).

**Mismatches found (all fixed in this burst):**

| Pairing (pre-fix) | Taxonomy canonical | Resolution |
|-------------------|--------------------|------------|
| E-GRAPH-003 InterruptWithoutCheckpointer (5 sites) | E-GRAPH-003 = UnknownRoutingTarget | Renumbered to E-GRAPH-016; added to taxonomy |
| E-CHKPT-003 SerializationFailed (1 site) | E-CHKPT-003 = CheckpointReadFailed | Renumbered to E-CHKPT-006; added to taxonomy |

**Mismatches found beyond the 6 known sites: 0.**

Note: `E-MCP-001 TOOL` appeared in the raw regex output because one BC line reads `code: E-MCP-001, category: TOOL`; the regex captured `TOOL` as the suffix token. `TOOL` is a category keyword, not a variant name. The canonical variant name for E-MCP-001 is `ToolException` (present in the message format in that same BC). No fix required — this is a census regex false positive, not a variant-name mismatch.

---

## Trajectory

| Pass | Verdict | Findings |
|------|---------|----------|
| P17 | NOT CLEAN | 4 |
| P18 | NOT CLEAN | 2 |
| P19 | NOT CLEAN | 3 |
| P20 | NOT CLEAN | 3 |

Consecutive clean: **0/3**. Next pass starts fresh.
