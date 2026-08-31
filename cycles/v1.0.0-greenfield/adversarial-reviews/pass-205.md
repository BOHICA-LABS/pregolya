---
document_type: adversarial-review
level: ops
pass_id: P2A-205
pass_label: ROUND-49 SECURITY
frozen_head: 2c7ab45
review_head: 2c7ab45
date: 2026-08-31
version: "1.0"
status: closed
producer: adversary
timestamp: "2026-08-31T00:00:00Z"
phase: 2
pass: 205
previous_review: pass-204.md
cycle: v1.0.0-greenfield
traces_to: STATE.md
inputs: []
input-hash: "[pending-recompute]"
---

# Adversarial Review — Pass P2A-205 ROUND-49 SECURITY (CLOSED)

> **RECORD STATUS: CLOSED.** 3 findings (2 HIGH + 1 MED process-gap). CLEAN(strict): NO. CLEAN(PR-merge): NO (2 HIGH). Streak: 0/3 (reset on fix-burst push). Frozen spec HEAD: `2c7ab45` (post-D-325 push). Phase-2 re-convergence pass (round-49, lens 2: security).

## Finding ID Convention

Finding IDs use the format `F-P2A205-NN` for substantive findings and `O-P2A205-NN` for observations/process-gaps. Canonical format per template: `ADV-P2CONV-P205-<SEV>-<SEQ>`. Phase-2 shorthand applied throughout.

## Pass Metadata

| Field | Value |
|-------|-------|
| Pass ID | P2A-205 ROUND-49 SECURITY |
| Frozen spec HEAD | `2c7ab45` |
| Date | 2026-08-31 |
| Pass total | Phase-2 pass 205 (round-49, lens 2) |
| Method | Security lens (CWE-209/532/522) — credential-sanitization coverage audit on generic tools/call boundary; redact_credentials pattern completeness audit; R06 gate partial-pipeline robustness. |
| Scope | BC-2.09.007 {INV-003}(b) pattern completeness; ADR-029 §SEC-BOUND-001 BC attribution; BC-2.09.007 {INV-003} steps 2+3 parity at the generic tools/call boundary; verify-security-literal-propagation.sh R06-PP partial-pipeline clause. |

## Verdict

| Criterion | Result |
|-----------|--------|
| CLEAN (strict) — ZERO findings of any severity | **NO** |
| CLEAN (PR-merge) — ZERO findings of CRIT/HIGH/MED | **NO** (2 HIGH) |
| 3-CLEAN streak (BC-5.39.001) | **0/3** |

## Part A — Fix Verification

Round-48 security fixes verified: R06 gate corpus-wide SEC-BOUND-001 (13 self-probes) confirmed in verify-security-literal-propagation.sh; BC-2.12.007 {INV-004} SSE boundary pipeline confirmed in place (round-48 closure); BC-2.09.007 Bearer-token pattern 4 (TV-010) confirmed. No regression.

## Part B — New Findings

### HIGH

#### F-P2A205-01 [HIGH, CWE-209/532] — Generic tools/call boundary missing SEC-BOUND-001 step-3 (sanitize_internal_ids); ADR-029 mis-attribution

**Description:** The generic MCP tools/call boundary (BC-2.09.007 {INV-003}) applied `redact_credentials` (step 2) but lacked `sanitize_internal_ids` (step 3). The SEC-BOUND-001 pipeline mandates both steps. Additionally, ADR-029 §SEC-BOUND-001 incorrectly attributed the generic tools/call pipeline obligation to BC-2.09.008 (GraphAgentTool) instead of BC-2.09.007 (generic tools/call). This mis-attribution would cause maintainers to look in the wrong BC for the step-3 mandate, creating a spec-navigation gap that persists under code review. CWE-209: UUID-shaped internal identifiers (run_id) could leak into MCP error responses at the plain-tool boundary because step 3 was absent.

**Disposition:** CLOSED. BC-2.09.007 (v2.4→v2.5) {INV-003} restructured as SEC-BOUND-001 2-step pipeline: step 1 N/A (DI-008 no-panic plain tools cannot emit E-GRAPH-011/019); step 2 `redact_credentials`; step 3 `sanitize_internal_ids` (UUID-shaped pass with u64-CheckpointId carve-out). {PC-003} updated to cite steps 2+3. TV-011 minted (UUID in plain-tool error message → `<redacted-id>` via step 3). ADR-029 (v2.18→v2.19) §SEC-BOUND-001 corrected: BC-2.09.007 generic tools/call boundary — step-1 N/A clause added; BC-2.09.008 GraphAgentTool — all-3-steps mandatory (step-1 applicable since GraphAgentTool CAN raise E-GRAPH-011/019). test-vectors.md §TV-011 BC-2.09.007 TV count 10→11. SS-09 subtotal +1.

#### F-P2A205-02 [HIGH, CWE-522/532] — redact_credentials missing URL-userinfo and HTTP Basic-auth patterns

**Description:** The canonical `redact_credentials` sanitizer (BC-2.09.007 {INV-003}(b)) covered 4 patterns: OpenAI `sk-`, Anthropic `sk-ant-`, 64+ alphanumeric, and Bearer token. Two credential forms were absent: (a) URL-embedded userinfo (`scheme://user:password@host`), which is the live production credential vector for `OllamaBaseUrl` (auth-bearing URL per CLAUDE.md); (b) HTTP Basic auth header (`Basic <base64-of-user:pass>`). A base64-encoded `user:pass` credential in an Authorization header would not match patterns 1-4 because base64 padding chars `+` and `=` prevent pattern 3 (64+ pure-alphanumeric) from matching, and the `Basic` prefix is not covered by any prior pattern.

**Disposition:** CLOSED. BC-2.09.007 (v2.4→v2.5) {INV-003}(b) extended from 4 to 6 patterns: pattern 5 URL-embedded userinfo `[a-zA-Z][a-zA-Z0-9+.\-]*://[^/\s:@]+:[^/\s:@]+@` → `"<redacted>"`; pattern 6 HTTP Basic auth `Basic\s+[A-Za-z0-9+/=]+` → `"<redacted>"`. 'four patterns' → 'six patterns' in pluggable-registry note. TV-012 minted (URL-userinfo; TV count 11→12). TV-013 minted (Basic-auth; TV count 12→13). Propagated to BC-2.09.008 {INV-003}, BC-2.12.003 {INV-008} step 2, BC-2.12.007 {INV-004} step 2. VP-015 (v1.1→v1.2) §Property Statement formal property expanded to 6-pattern canonical set; harness skeleton extended 4→7 test cases. test-vectors.md §TV-011-TV-013 BC-2.09.007 TV count 10→13. SS-09 subtotal 69→72. Grand total 767→770 canonical + 11 GTV = 778→781.

### MEDIUM / PROCESS-GAP

#### O-P2A205-03 [MED, process-gap] — R06 gate false-green on partial pipelines (missing R06-PP clause)

**Description:** The R06 gate in `verify-security-literal-propagation.sh` checked for the presence of SEC-BOUND-001 anchor citations but did not verify that the cited pipeline was COMPLETE (all 3 steps present). A spec could satisfy R06 by citing SEC-BOUND-001 in a single-step form, avoiding the gate while remaining incomplete. This is a partial-pipeline false-green class — R06 passes green even when the spec only documents step 2 but omits step 3. The R06 gate was added in round-48 to mechanically catch boundary-sanitization gaps; this OBS identifies a precision gap in the gate itself.

**Disposition:** CLOSED / IMPLEMENTED in-scope. `verify-security-literal-propagation.sh` extended with R06-PP (partial-pipeline) rule: checks for explicit step-2+step-3 citation or the absence of a step-3 carve-out note in each SEC-BOUND-001-anchored boundary. 3 self-probes added (coverage-gap, correct-full-pipeline, explicit-N/A-carve-out). Exit 0 advisory gate. L-240 codified (partial-pipeline SEC-BOUND-001 gate discipline).

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 0 |
| LOW | 0 |
| OBS | 0 |
| PROCESS-GAP (MED) | 1 |
| **Total** | **3** |

**Overall Assessment:** NOT CLEAN (strict). NOT CLEAN (PR-merge).
**CLEAN(strict): NO | CLEAN(PR-merge): NO (2 HIGH) | streak: 0/3**

## Novelty Assessment

| Field | Value |
|-------|-------|
| **Pass** | 205 |
| **New findings** | 3 |
| **Duplicate/variant findings** | 0 |
| **Novelty score** | 3 / (3 + 0) = 1.0 |
| **Median severity** | HIGH |
| **Trajectory** | →2→2→1→1→2→3 |
| **Verdict** | FINDINGS_REMAIN (3 findings closed; NOT CLEAN(strict); NOT CLEAN(PR-merge); streak 0/3; NEXT P2A-206 consistency/census/records) |
