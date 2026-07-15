---
document_type: adversarial-review
pass: 47
verdict: NOT_CLEAN
severity: CRITICAL
novelty: HIGH
phase: 1d
timestamp: 2026-07-15T00:00:00Z
findings_count: 2
observations_count: 2
---

# Adversarial Review — Pass 47

## Verdict: NOT CLEAN — 2 findings (1 CRITICAL, 1 MED). Novelty HIGH.

---

## Findings

### F-P47-01 (CRITICAL, security): Silent process-backend fallback asserted in interface-definitions.md §Flag Interaction Rules

**Location:** `interface-definitions.md` §Flag Interaction Rules line 395:
`| \`sandbox-wasm\` + \`sandbox-container\` both off | (none) | \`ferrochain-sandbox\` defaults to process backend; emits WARNING |`

**Finding:** The Flag Interaction Rules row mandates the EXACT silent process-backend fallback behavior (adk-rust P-61 behavior) that multiple authoritative specs explicitly invert:
- **BC-2.13.001 PC4:** If only `sandbox-process` feature is compiled (no `sandbox-wasm`, no `sandbox-container`), `SandboxBackend::default()` returns `Err(E-SBXD-003: SandboxInitFailed { reason: "no enforcing backend compiled in" })` — NOT a process backend.
- **BC-2.13.001 EC-002:** Both `sandbox-wasm` and `sandbox-container` features absent → Compile-time warning; `SandboxBackend::default()` returns `Err(E-SBXD-003: SandboxInitFailed { reason: "no enforcing backend compiled in" })`.
- **BC-2.13.001 PC3:** Process backend accessible ONLY via `Sandbox::unsafe_process_no_isolation()`.
- **DI-006 (Enforcing Sandbox Backend is Default):** No default or no-arg constructor may return a non-enforcing backend.
- **NE-01:** ferrochain explicitly inverts the adk-rust P-61 counter-example (adk-rust makes ProcessBackend the Cargo default; ferrochain must not).

An implementer following the supplement row would build the no-isolation security hole that BC-2.13.001 was designed to prevent. The supplement row is the DERIVED artifact; the BC/DI/NE are AUTHORITIES. The supplement row is wrong.

**Why it survived 46 passes:** No prior census explicitly cross-referenced supplement table rows against their cited BC postconditions. The Flag Interaction Rules table is a human-readable supplement used directly by implementers — divergence from the BC created an invisible security-critical implementation trap.

**Fix required (interface-definitions.md §Flag Interaction Rules):** Rewrite the row:
- Flag A: `sandbox-wasm` + `sandbox-container` both off
- Flag B: (none)
- Interaction: `SandboxBackend::default()` returns `Err(E-SBXD-003 SandboxInitFailed { reason: "no enforcing backend compiled in" })`; NO silent process fallback (BC-2.13.001 PC4/EC-002, DI-006, NE-01); process backend reachable ONLY via explicit `Sandbox::unsafe_process_no_isolation()` (BC-2.13.001 PC3)

**Fix owner:** product-owner (this burst) — interface-definitions.md §Flag Interaction Rules line 395.

---

### F-P47-02 (MED): Config-schema comment claims process-backend warning fires "on startup" — contradicts BC-2.13.002 PC2/EC-002

**Location:** `interface-definitions.md` line 364 (inside `[sandbox]` config schema block):
`# "process" emits loud WARNING on startup (BC-2.13.002)`

**Finding:** BC-2.13.002 PC2 states: "The warning is emitted once per `execute()` invocation, not only at construction time." BC-2.13.002 EC-002 states: "`ProcessBackend` is constructed but `execute()` is never called → No warning emitted." The config comment says "on startup," implying the warning fires when the backend is constructed or the process starts — which is exactly the behavior EC-002 says does NOT happen.

An operator reading the config comment would expect a startup warning to alert them before any tool runs. The actual behavior is per-execute. A backend constructed but never invoked emits no warning (EC-002). "On startup" overstates the security signal frequency and misleads operators about when to expect the warning.

**Fix required (interface-definitions.md line 364):** Change config comment to:
`# 'process' backend emits loud WARNING once per execute() invocation — NOT construction/startup (BC-2.13.002 PC2/EC-002)`

**Fix owner:** product-owner (this burst) — interface-definitions.md §Config Schema line 364.

---

## Observations

### OBS-P47-1 [process-gap]: No sandbox-process row in Cargo Feature Flags table; no supplement-vs-BC seam census gate

**Location:** `interface-definitions.md` §Cargo Feature Flags table (lines 376-386).

**Observation:** The Cargo Feature Flags table has rows for `sandbox-wasm` (BC-2.13.001) and `sandbox-container` (BC-2.13.001) but no `sandbox-process` row. BC-2.13.001 PC3 and PC4 explicitly reference a `sandbox-process` feature (the build scenario "only `sandbox-process` feature compiled" is the PC4 precondition). The Flag Interaction Rules row (F-P47-01) also references this feature behavior. An implementer reading the feature table has no entry documenting that `sandbox-process` exists but does NOT make the process backend a default.

**Why F-P47-01 hid for 46 passes:** No standing census explicitly cross-referenced supplement table rows (feature flags, flag interactions, config comments) against the cited BC's postconditions. Gate #29 closes this blind spot.

**Recommended fixes:**
1. Add `sandbox-process` row to Cargo Feature Flags table with NOT-enforcing / explicit-constructor-only semantics per BC-2.13.001 PC3/PC4.
2. Mint standing gate #29 in bc-authoring-plan.md: supplement-vs-BC seam census — every supplement table row citing a BC must diff against the cited BC's PCs/ECs. Census trigger: every supplement edit + adversary rotation. SS-13 sandbox rows are an explicit sub-check.

**Fix owner:** product-owner (this burst) — interface-definitions.md §Cargo Feature Flags + bc-authoring-plan.md gate #29.

---

### OBS-P47-2: BC-2.07.002 changelog date notional inconsistency

**Location:** BC-2.07.002 changelog entry dates.

**Observation:** Minor date notional inconsistency in BC-2.07.002 changelog. Non-load-bearing; does not affect behavioral semantics, implementer guidance, or test vectors. Not filed as a finding.

---

## Sibling Spot-Checks

1. **BC-2.06.001 EC-005 (F-P46-01 fix)** — PASS; stream-termination authority explicit, no `run_end` on interrupt or failure paths.
2. **BC-2.12.007 three fixes (F-P46-01: TV-005/EC-001/EC-003)** — PASS; zero live `run_end.status = interrupted` or hedged `(or a run_end with status: "failed")` text; interrupt-envelope-as-terminal-frame canon consistent with BC-2.06.001 TV-004.
3. **BC-2.09.005 Red Gate phrasing (OBS-P46-1 fix)** — PASS; phrasing aligned with sibling BC-2.09.004.
4. **interface-definitions.md /stream row (F-P46-01 downstream fix)** — PASS; run_end-on-completion-only with interrupt/failure path description per BC-2.06.001 PC2+EC-005.

---

## Census Results

### Census #21 — Override-count census (BC-2.14.002 PC3 overrides: exactly 9)
PASS — 9 overrides enumerated in BC-2.14.002 PC3; no phantom 10th override found.

### Census #26 — Retired-canon residue
PASS — zero live retired-identifier hits across `.factory/specs/`.

### Census #27 — Path roster validity
PASS — all BC Architecture Anchor crate paths valid per ADR-007 18-crate roster; F-P42-01 clean.

### Census #28 — Version-changelog integrity (all 86 BCs)
PASS — distribution EXACT 53×1.0 + 23×1.1 + 8×1.2 + 2×1.3 = 86; all 33 BCs at version > 1.0 have changelogs (30 frontmatter + 3 body-table).

### Census #16 — Endpoint-count invariant (26 total ferrochain-server endpoints)
PASS — 26 endpoints confirmed (Threads 7 + Assistants 7 + Runs 7 + Cron 4 + aggregate 1).

### Census #24 — Wire-object field-set coherence
PASS — Run/Thread/Assistant/CronSchedule/ResumeRequest field sets coherent across interface-definitions.md, entities-server.md, BC postconditions.

### Census #25 A/B/C — Module criticality sibling coherence + crate ownership diff
PASS — retry=core holds across all four criticality-bearing docs; distribution 9/12/10/2=33.

### RetryHint registry
PASS — exactly 5 known-intentional divergences documented in bc-authoring-plan.md §22 and error-taxonomy.md blockquote; no new divergences found.

### VP coherence (4 docs: VP-INDEX, verification-architecture, coverage-matrix, BC bodies)
PASS — VP citations consistent across all four documents.

---

## Seam Probes

- **sandbox × feature-flags** → F-P47-01 (CRITICAL) + F-P47-02 (MED): process-fallback claim in Flag Interaction Rules and "on startup" timing in config comment both contradict BC-2.13.001/002 authority.
- **provider × retry** → PASS: provider-layer error codes and retry-policy BCs operate at distinct layers; no conflict.
- **checkpoint × streaming** → PASS: event-ordering coherent; DI-011 satisfied; no run_end on interrupt path per BC-2.06.001 (F-P46-01 clean).
- **cron × runs** → PASS: shared lifecycle state machine and CronSchedule schema coherent across BCs.

---

## Proposed Decisions Log Entries

### D18-P47-A — Supplement rows are DERIVED from BCs; BC PCs/ECs are AUTHORITY

**Decision:** Any prd-supplement table row that describes behavior covered by a BC is a derived artifact. The BC postconditions and edge cases are the authority. On any conflict between a supplement row and a BC, the BC wins. The supplement row must be corrected to match the BC. An implementer following a supplement row that contradicts the BC would build incorrect (potentially insecure) behavior.

**Motivating instance:** F-P47-01 — interface-definitions.md Flag Interaction Rules stated silent process-backend fallback (adk-rust P-61 behavior); BC-2.13.001 PC4 specifies Err(E-SBXD-003 SandboxInitFailed).

**Gate:** Gate #29 (supplement-vs-BC seam census) enforces this decision structurally going forward.

### D18-P47-B — sandbox-process feature: off by default; explicit-constructor-only; NOT enforcing

**Decision:** The `sandbox-process` Cargo feature compiles the ProcessBackend but does NOT make it a default. It is never returned from `SandboxBackend::default()` or any default/no-arg constructor. It is accessible ONLY via `Sandbox::unsafe_process_no_isolation()`. This is true regardless of which other sandbox features are compiled. The feature flag table must document this explicitly.

**Authority:** BC-2.13.001 PC3/PC4, BC-2.13.002.

### D18-P47-C — Process-backend warning timing: per-execute(), NOT construction or startup

**Decision:** The WARN log for ProcessBackend fires once per `execute()` invocation. It does NOT fire at construction time, startup, or configuration load. A ProcessBackend constructed but never invoked emits no warning. The config schema comment must reflect per-execute timing, not "on startup."

**Authority:** BC-2.13.002 PC2, BC-2.13.002 EC-002.
