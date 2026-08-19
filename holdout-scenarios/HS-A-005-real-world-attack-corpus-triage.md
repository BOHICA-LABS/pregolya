---
document_type: holdout-scenario
level: ops
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-08-19T00:00:00Z
phase: 2
domain: A
domain_name: Virtual SOC Analyst Agent
id: HS-A-005
title: "Real-World Attack Corpus Triage — False-Positive and True-Positive Discrimination"
category: real-world-corpus
must_pass: false
priority: should-pass
epic_id: N/A
behavioral_contracts:
  - BC-2.08.001
  - BC-2.04.001
  - BC-2.08.003
inputs:
  - .factory/specs/prd.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
input-hash: "7442088"
traces_to: .factory/planning/holdout-domains/domain-a-soc-analyst.md
lifecycle_status: active
introduced: v1.0.0-phase-2
last_evaluated: null
staleness_check: null
stale_reason: null
retired: null
assumption_source: null
risk_source: null
coverage_areas:
  - composition
  - providers
  - structured_output
  - graph_execution
---

# Holdout Scenario HS-A-005: Real-World Attack Corpus Triage — False-Positive and True-Positive Discrimination

> **SEALED — Phase 4 use only.**
> Do NOT share with implementer, test-writer, or architect agents.

---

## Scenario

A triage agent is exercised against two known real-world corpora: one set of benign administrative activity logs that historically generate false-positive alerts, and one set of documented attack-sequence logs from a publicly available intrusion dataset. The agent must correctly discriminate between the two with evidence-cited verdicts.

**Known-good corpus (benign — tests false-positive rate):** Administrative scripting activity from the MITRE ATT&CK Enterprise evaluation dataset's "clean" baseline period. These are logs from legitimate IT operations (PowerShell remoting, group policy application, scheduled task execution) that naive rules flag as suspicious. A well-functioning triage agent should classify the majority as `false_positive` or `needs_escalation` (not `true_positive`) because the context (known admin, business hours, asset managed by IT) clearly indicates benign activity.

Source: MITRE ATT&CK Evaluations program — Enterprise evaluation baseline logs (publicly available at attack.mitre.org/evaluations; the "clean baseline" period preceding adversary simulation).

**Known-problematic corpus (attack — tests false-negative rate):** Alert records derived from a documented APT intrusion simulation published by MITRE ATT&CK (e.g., APT29 round of the ATT&CK evaluation). These include credential dumping, lateral movement via pass-the-hash, and data staging — all well-characterized in ATT&CK TTP taxonomy. A well-functioning triage agent should classify the majority as `true_positive` or `needs_escalation`.

**Given** a triage agent configured with a DTU mock chat model provider. Both corpora are presented as a batch of structured alert records, each containing at minimum: alert type, source host classification (admin vs. standard), time of day, log snippet, and a user context note.

**When** the agent triages all alerts in both corpora.

**Then:**
1. For the benign corpus: false-positive rate ≤ 30% (no more than 30% of benign alerts classified as `true_positive`).
2. For the attack corpus: true-positive detection rate ≥ 60% (at least 60% of attack alerts classified as `true_positive` or `needs_escalation`).
3. Every verdict includes a non-empty `summary` field explaining the triage decision in natural language — not just a bare label.
4. No alert triage crashes or panics.
5. Batch triage completes without indefinite blocking.

---

## Behavioral Contract Linkage

| BC ID | Clause Tested | Scenario Aspect |
|-------|--------------|-----------------|
| BC-2.08.001 | Chat model invocation returns typed structured output | Triage verdicts deserialized from provider responses |
| BC-2.04.001 | Graph execution completes batch without crash | Batch of 10+ alerts processed without failure |
| BC-2.08.003 | Structured output schema enforced | `disposition`, `confidence`, `summary` fields present on every verdict |

---

## Verification Approach

1. Prepare two batches of alerts drawn from the MITRE ATT&CK Evaluations materials:
   - Batch A (benign): 5–10 alerts from the clean baseline period (documented admin activity).
   - Batch B (attack): 5–10 alerts from the APT simulation period (documented attack activity with known TTPs).
2. Build a batch triage agent using pregolya's public API. Feed each alert record through the triage graph individually.
3. Collect structured verdicts for all alerts.
4. Compute false-positive rate for Batch A: `(count of 'true_positive' verdicts) / (total batch A alerts)`.
5. Compute true-positive detection rate for Batch B: `(count of 'true_positive' or 'needs_escalation' verdicts) / (total batch B alerts)`.
6. Assert FP rate ≤ 0.30 and TP rate ≥ 0.60.
7. Assert every verdict has a non-empty `summary`.
8. All test assertions pass (no crashes).

---

## Evaluation Rubric

| Dimension | Weight | Passing Signal |
|-----------|--------|----------------|
| False-positive rate (benign corpus) | 0.35 | ≤ 30% of benign alerts misclassified as true_positive |
| True-positive detection rate (attack corpus) | 0.35 | ≥ 60% of attack alerts detected as true_positive or needs_escalation |
| Verdict explanation quality | 0.20 | Every verdict has a non-empty, contextually relevant summary |
| Stability | 0.10 | All alerts processed without crash or panic |

**Threshold for should-pass:** weighted average ≥ 0.55.

---

## Edge Conditions

- Alert records with missing optional fields (no user context note): agent must still produce a verdict.
- Alert records where the DTU mock returns a low-confidence response: agent must preserve the low confidence in the output, not inflate it.

---

## Failure Guidance

"HOLDOUT LOW: HS-A-005 (satisfaction: X.XX) — triage agent either over-flagged benign administrative activity as true positive, or failed to detect documented attack patterns."

---

## Category: real-world-corpus

### Corpus Details

| Field | Known-Good (Benign) | Known-Problematic (Attack) |
|-------|--------------------|-----------------------------|
| corpus_source | MITRE ATT&CK Evaluations Enterprise — clean baseline period (attack.mitre.org/evaluations) | MITRE ATT&CK Evaluations Enterprise — APT simulation period (same source) |
| corpus_size | 5–10 alert records (manually curated from evaluation logs) | 5–10 alert records (manually curated from APT simulation round) |
| known_edge_cases | Legitimate PowerShell admin commands flagged by naive rule; scheduled tasks from known hosts | Pass-the-hash lateral movement; LSASS credential dump; data staging |
| false_positive_threshold | ≤ 30% of benign alerts classified as true_positive | N/A |
| false_negative_threshold | N/A | ≤ 40% of attack alerts missed (detection rate ≥ 60%) |
