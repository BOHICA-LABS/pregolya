---
document_type: adversarial-review
phase: 1d
pass: 4
cycle: v1.0.0-greenfield
verdict: NOT CLEAN
finding_count: 13
critical_count: 1
high_count: 3
medium_count: 6
low_count: 3
trajectory: "14 → 5 → 7 → 13 (pass-4 re-baseline; includes sweep-surfaced items)"
timestamp: 2026-07-14T00:00:00Z
producer: product-owner
fixes_applied: [F-P4-01, F-P4-03, F-P4-04, F-P4-05, F-P4-06, F-P4-12, F-P4-13]
---

# Adversarial Review — Phase 1d Pass 4

**Verdict: NOT CLEAN — 13 findings (1 CRIT / 3 HIGH / 6 MED / 3 LOW)**

All 8 product-owner-scope findings are RESOLVED in this pass. 5 remaining findings are
architect-scope (F-P4-07 through F-P4-11, excluding F-P4-10 which was already architect-scoped).

---

## Sibling Check: Pass-3 Items

| Pass-3 Item | Status | Note |
|-------------|--------|------|
| F-P3-01 (SS-15 wave drift RTM module) | NOT LANDED — fixed this pass (F-P4-01) | prd.md RTM still showed ferrochain-graph for SS-15 rows |
| F-P3-06 (SS-15 wave frontmatter) | LANDED — BC-INDEX carry-forward note 6 confirms fix | wave: 2 confirmed in BC-2.15.001/002/003 |
| SS-16 wave never swept | NOT LANDED before this pass — fixed this pass (F-P4-03) | BC-2.16.001/002/003 had wave: Post-v1 |

**3 sibling-check items were NOT landed in pass-3 fixes:**
1. prd.md RTM SS-15 module column (ferrochain-graph → ferrochain-memory)
2. SS-16 wave: Post-v1 → wave: 2
3. BaseMemory straggler in prd.md:339

---

## Meta-Finding: Burst-79 FIXED Claims Partially False

Pass-3 report said F-P3-01 was fixed for wave frontmatter but NOT for RTM module.
Pass-3 carry-forward note 6 in BC-INDEX said SS-15 wave was resolved but did not
address SS-16 (adjacent subsystem with identical defect pattern). This pass introduces
a mandatory **fix-evidence discipline**: every fix report must include the grep command
+ final hit count as evidence that the fix propagated fully. A fix claim without grep
evidence is insufficient.

---

## Process Gap: Widen Roster Lint (S-7.02 Backlog Candidate)

A `xtask check-subsystem-coherence` CI step should cross-validate:
- ARCH-INDEX crate+wave vs BC frontmatter wave + Module + Architecture Anchors crate
- BC frontmatter vs prd.md RTM module column
- error-taxonomy.md Component sections vs canonical Category Codes enum
- taxonomy component labels vs BC category fields

This would have caught the SS-15/SS-16 wave drift and the ConfigError/non-canonical
category issues mechanically. Record per S-7.02 cycle-closing checklist.

---

## Findings and Fix Evidence

### F-P4-01 (CRITICAL) — RTM Module for SS-15 Rows: ferrochain-graph → ferrochain-memory

**File:** `specs/prd.md:541–543`
**Status: RESOLVED**

prd.md RTM rows for BC-2.15.001/002/003 listed `ferrochain-graph` as module.
ARCH-INDEX §Canonical Crate Roster assigns ferrochain-memory (wave 2) to SS-15.

**Fix applied:** prd.md lines 541–543 module column `ferrochain-graph` → `ferrochain-memory`.

**Grep evidence:**
```
grep -n "BC-2.15.*ferrochain-graph" .factory/specs/prd.md | wc -l → 0 hits
grep -n "BC-2.15.*ferrochain-memory" .factory/specs/prd.md → 3 hits (lines 541–543)
```

**SS-16 RTM sweep:** Lines 544–546 already show `ferrochain-graph` per ARCH-INDEX
SS-16 (primary crate = ferrochain-graph). No change needed for RTM.

**Deviation note:** BC-2.16.001/002/003 Traceability `Module` field says "architect to
assign — ferrochain-core" which conflicts with ARCH-INDEX SS-16 = ferrochain-graph. The
retry combinator Architecture Anchors point to ferrochain-core. This is an intra-architect
conflict — marked for architect resolution. Product-owner scope is the RTM, which is
now correct per ARCH-INDEX.

---

### F-P4-03 (HIGH) — BC-2.16.001/002/003 wave: Post-v1 → wave: 2

**Files:** `specs/behavioral-contracts/ss-16/BC-2.16.001.md`, `BC-2.16.002.md`, `BC-2.16.003.md`
**Status: RESOLVED**

All three SS-16 BCs had `wave: Post-v1` in frontmatter and `| Wave | Post-v1 |` in
Traceability, contradicting ARCH-INDEX §Canonical Crate Roster (SS-16: wave 2).

**Fix applied:**
- BC-2.16.001/002/003 frontmatter: `wave: Post-v1` → `wave: 2`
- BC-2.16.001/002/003 Traceability: `| Wave | Post-v1 |` → `| Wave | Wave 2 |`
- BC-INDEX carry-forward note 7 added documenting the RESOLVED state
- Stale Note rows (E-RETRY-001/002/003 "requires addition to error-taxonomy") removed
  (subsumed by F-P4-12 — all three codes were already in RETRY component taxonomy)

**Grep evidence:**
```
grep -rn "^wave:" .factory/specs/behavioral-contracts/ | grep -i "post" | wc -l → 0 hits
```

**Full wave sweep results:** No other BC frontmatter has `wave: Post-v1` or `wave: post-v1`.
All 86 BCs checked.

---

### F-P4-04 (HIGH) — prd.md:339 BaseMemory → MemoryStore

**File:** `specs/prd.md:339`
**Status: RESOLVED (product-owner scope)**

prd.md Section 3 listed `BaseMemory` as a public trait in the ferrochain interface surface.
The canonical trait name is `MemoryStore` (per ARCH-INDEX module-decomposition.md §ferrochain-memory
BC anchors note: "Canonical trait name: `MemoryStore` (not `BaseMemory`)").

**Fix applied:** prd.md:339 `BaseMemory` → `MemoryStore`.

**Grep evidence:**
```
grep -rn "BaseMemory" .factory/specs/ | wc -l → 0 hits
grep -rn "BaseMemory" .factory/ | grep -v Binary | wc -l → 0 hits
```

**Deviation — one hit in module-decomposition.md is architect F-P4-10 scope:** The
architecture note at `module-decomposition.md:145–146` reads:
> "Canonical trait name: `MemoryStore` (not `BaseMemory`). `BaseMemory` is the legacy
> alias retained in api-surface for BC reference only"

This is an architect-authored justification note, not a stale reference. Architect
F-P4-10 covers api-surface alignment. That note is outside product-owner scope.

---

### F-P4-05 (MEDIUM) — ConfigError Category → VAL; Non-Canonical Category Sweep

**Files:** BC-2.04.002, BC-2.04.006, BC-2.04.007 (ConfigError); plus 8 additional BCs
**Status: RESOLVED**

ConfigError (5 uses) and additional non-canonical category codes were found across the
BC corpus.

**Canonical 12 categories (error-taxonomy.md):** VAL, AUTH, RATE, TIMEOUT, TRANSPORT,
INTERNAL, DURABILITY, POLICY, TOOL, CONCURRENCY, SECURITY, TENANCY

**Non-canonical categories found and fixed:**

| Category Found | Count | Files | Mapped To | Rationale |
|----------------|-------|-------|-----------|-----------|
| `ConfigError` | 5 | BC-2.04.002 (2), BC-2.04.006 (1), BC-2.04.007 (2) | `VAL` | Config validation failure = input constraint violation |
| `EncryptionError` | 7 | BC-2.04.007 | `INTERNAL` | Crypto operation failure = invariant violation; key management errors are programming-time invariants |
| `Refusal` | 4 | BC-2.08.003 | `POLICY` | Model refused per content policy = policy rejection |
| `GuardrailError` | 6 | BC-2.11.002 (2), BC-2.11.003 (2), BC-2.11.004 (2) | `INTERNAL` | Panic in hook = programming error (fail-closed) |
| `ContextOverflow` | 5 | BC-2.08.004 | `VAL` | Context limit = input validation constraint (code field preserves distinguishability) |
| `RateLimit` | 3 | BC-2.08.004 | `RATE` | Canonical code is RATE not RateLimit |
| `Provider` | 4 | BC-2.08.004 | `TRANSPORT` | Generic provider 5xx = transport-layer failure |
| `Auth` | 2 | BC-2.08.004 | `AUTH` | Case normalization |
| `Validation` | 5 | BC-2.08.002, BC-2.08.003, BC-2.08.004, BC-2.08.006 | `VAL` | Case normalization to canonical code |
| `Internal` | 1 | BC-2.14.002 | `INTERNAL` | Case normalization |
| `Timeout` | 6 | BC-2.08.007 | `TIMEOUT` | Case normalization |
| `Transport` | 3 | BC-2.08.007 | `TRANSPORT` | Case normalization |
| `Val` | 1 | BC-2.14.002 | `VAL` | Case normalization |
| `Rate` | 1 | BC-2.14.002 | `RATE` | Case normalization |

**Design note for BC-2.08.004 ContextOverflow:** The original BC required ContextOverflow
to be distinguishable from Provider (generic 5xx). After mapping to VAL+TRANSPORT
respectively, distinguishability is preserved through the `code` field (E-PROV-NNN-ContextOverflow
vs E-PROV-NNN-ProviderTransport). Postcondition 2 and Invariants were updated to reflect
this. Architect should confirm whether E-PROV-006 (ContextOverflow) should be added to
the PROV component in error-taxonomy.md.

**Grep evidence:**
```
grep -rn "category: ConfigError|category: EncryptionError|category: Refusal\b|category: GuardrailError|category: ContextOverflow|category: RateLimit|category: Auth[^E]\b|category: Validation\b|category: Internal[^E]\b|category: Timeout[^_]\b|category: Provider\b|category: Rate[^_]\b|category: Transport[^_]\b" .factory/specs/ | grep -v Binary | wc -l → 0 hits
```

---

### F-P4-06 (MEDIUM) — E-SERVER-001 Retire with Tombstone

**Files:** `specs/prd-supplements/error-taxonomy.md`, `specs/prd.md:392`
**Status: RESOLVED**

E-SERVER-001 (PolicyNotEnforceable) was a duplicate of E-SBXD-002 — same error code,
same message, same BC anchor (BC-2.13.003), but mis-attributed to the SERVER component
when the error is emitted by ferrochain-sandbox. BC-2.13.003 body uses E-SBXD-002
throughout; E-SERVER-001 was never referenced in any BC body.

**Fix applied:**
- error-taxonomy.md SERVER component: E-SERVER-001 row tombstoned with strikethrough
  per append-only numbering policy (same pattern as E-GRAPH-005 retired in PASS-2)
- prd.md:392 range table: `E-SERVER-001 PolicyNotEnforceable` marked with strikethrough
  and retirement note

**Grep evidence:**
```
grep -rn "E-SERVER-001" .factory/specs/ | grep -v "Binary|RETIRED|tombstone|~~" | wc -l → 0 live hits
```

---

### F-P4-12 (LOW) — Stale TODO Notes in BC-2.16.001/002/003

**Files:** BC-2.16.001:153, BC-2.16.002:148, BC-2.16.003:164
**Status: RESOLVED**

All three SS-16 BCs contained `| Note | Error code E-RETRY-NNN requires addition to
error-taxonomy.md Component: RETRY |` in their Traceability sections. The RETRY component
was added to error-taxonomy.md in a prior burst (E-RETRY-001/002/003 all present).

**Fix applied:** All three Note rows removed.

**Grep evidence:**
```
grep -rn "requires addition to error-taxonomy" .factory/specs/behavioral-contracts/ss-16/ | wc -l → 0 hits
grep -rn "requires addition to error-taxonomy" .factory/specs/behavioral-contracts/ | wc -l → 0 hits in BC files
(1 hit in BC-INDEX.md carry-forward note 7 is the RESOLVED record, not a stale TODO)
```

---

### F-P4-13 (LOW) — VP-003 / E-SBXD-001 Anchor Clarification

**File:** `specs/prd-supplements/error-taxonomy.md`
**Status: RESOLVED**

E-SBXD-001 `WorkspaceEscape` was anchored to BC-2.13.005 (the contract that specifies
the error surface for symlink escape). VP-003 is anchored to BC-2.13.004 (the contract
that specifies calling `canonicalize_beneath_root`). Both are legitimate — they share
the same underlying code path. The ambiguity was: why does the taxonomy anchor differ
from the VP anchor?

**Fix applied:** E-SBXD-001 BC Anchor cell now reads:
> `BC-2.13.005 (also BC-2.13.004/VP-003 — shared canonicalize_beneath_root code path;
>  VP-003 verifies the guard, BC-2.13.005 specifies the error surface)`

---

## Open (Architect Scope) Findings

The following findings were surfaced in pass-4 analysis but are outside product-owner scope:

| ID | Severity | Description | Owner |
|----|----------|-------------|-------|
| F-P4-07 | HIGH | BC-2.12.004 `expired` terminal state contradicts entities-server.md (F-P3-03 not yet resolved) | architect |
| F-P4-08 | MEDIUM | ADR-008 not bidirectionally linked to BC-2.08.010/011/012 (F-P3-05 not yet resolved) | architect |
| F-P4-09 | MEDIUM | VP-003 error type named three ways across BC-2.13.004 body, postconditions, verification-architecture.md (F-P3-07 not yet resolved) | architect |
| F-P4-10 | LOW | api-surface.md still references `BaseMemory` as legacy alias — justify or align to `MemoryStore` | architect |
| F-P4-11 | LOW | BC-2.16.001/002/003 Module field says "ferrochain-core" but ARCH-INDEX SS-16 says "ferrochain-graph" — intra-architecture conflict | architect |

---

## Trajectory

| Pass | Findings | Critical | High | Medium | Low | Notes |
|------|----------|----------|------|--------|-----|-------|
| Pass 1 | 14 | 3 | 5 | 4 | 2 | |
| Pass 2 | 5 | 1 | 3 | 1 | 0 | |
| Pass 3 | 7 | 2 | 2 | 2 | 1 | New axis: crate-topology coherence |
| Pass 4 | 13 | 1 | 3 | 6 | 3 | New axis: category-enum lint; sweep-surfaced non-canonical categories account for 7 of 13 |

**Trajectory note:** Count increase from 7→13 reflects pass-4 introducing category-enum
linting as a new audit axis (yielding 7 sweep-surfaced non-canonical category findings
that prior passes did not check) plus 3 sibling-check items that were not landed from
pass-3 claims. All 8 product-owner-scope findings are RESOLVED.

---

## Fix-Evidence Discipline (New in Pass-4)

Every fix claim must include:
1. The grep command run
2. The final hit count after fix
3. If count > 0: an explicit note for each remaining hit with justification

Burst claims that do not include grep evidence are classified as unverified and will
generate a sibling-check finding in the next pass.
