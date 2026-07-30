---
document_type: holdout-domain-brief
domain_id: A
domain_name: Virtual SOC analyst agent
status: complete
producer: research-agent
timestamp: 2026-07-13
traces_to: D8
project: pregolya
purpose: Phase-1 forcing function + Phase-2 holdout authoring input (product-owner authors hidden scenarios; only this domain is public)
verification: MCP-backed (4x perplexity_research deep + 3x tavily_search cross-validation)
---

# Holdout Domain A — Virtual SOC Analyst Agent

> **Scope note.** This brief characterizes the *problem space* and maps it to pregolya's planned
> primitive surface. It deliberately does NOT author acceptance scenarios — those are written hidden,
> later, by the product-owner (per D8). Everything here is a forcing function for Phase 1 (PRD/architecture
> must demonstrate these workloads are supportable) and a fact-base for Phase 2 holdout authoring.

> **Citation convention.** `[V]` = independently cross-verified via Tavily against a primary/vendor URL
> during this task. `[R]` = surfaced by MCP deep-research (Perplexity `sonar-deep-research`) with a named
> underlying source but not independently re-opened here — treat statistics as "as-reported." Conflicts and
> non-verifiable items are flagged inline.

---

## 10-Line Domain Summary

1. A SOC (Security Operations Center) continuously monitors, triages, investigates, and responds to security alerts across an enterprise; it is structured in tiers — Tier 1 (triage/enrichment/false-positive closure), Tier 2 (deep investigation, correlation, early containment), Tier 3 (major-incident command, threat hunting, detection engineering). [R]
2. The defining pain is **scale vs. accuracy**: enterprises commonly generate 10,000+ alerts/day, up to ~53% are false positives, ~62% of alerts go un-reviewed, and ~70% of junior analysts leave within three years — driving MTTD/MTTR/MTTC and breach cost (IBM 2024 avg. breach $4.88M). [R]
3. A "Virtual SOC analyst agent" is an autonomous/semi-autonomous LLM-driven system that investigates alerts 24/7 across the full tool stack, assembles evidence, reaches a verdict, and recommends or (within bounds) executes response. [R]
4. The 2026 product landscape is real and crowded: pure-plays (Dropzone AI, Prophet Security, Radiant Security, Simbian, Intezer, Exaforce), orchestration-first (Torq, Tines), and platform incumbents (Microsoft Security Copilot, CrowdStrike Charlotte AI, Google Gemini for SecOps, SentinelOne Purple AI, Palo Alto Cortex XSIAM). [R][V]
5. Architecturally these are **hybrid**: an LLM reasoning/planning loop orchestrating tool calls + RAG over telemetry, wrapped in deterministic guardrails and (increasingly) MCP tool integration; pure playbook automation and pure agentic reasoning are the two ends of a spectrum. [R]
6. Documented failure modes are the familiar LLM ones under high stakes: hallucinated verdicts, tool-use errors (one eval cited ~36% of conversations with tool-use failures; accuracy varying from single digits to ~80% across frontier models), and automation bias in humans. [R]
7. The tool surface an agent must integrate with: SIEM (Splunk, Sentinel, Elastic, Chronicle), EDR/XDR (CrowdStrike, SentinelOne, Defender), threat intel (MISP, VirusTotal, OTX, Recorded Future), SOAR/ticketing (ServiceNow, Jira, PagerDuty), identity (Okta, Entra/AD), and network/firewall. [R]
8. **MCP is being adopted in security tooling for real, right now** — verified official servers include Splunk (Splunkbase app 7931, now GA), Microsoft Sentinel (GA Nov 2025), Okta, ServiceNow; a notable community/vendor-maintained one is CrowdStrike `falcon-mcp` (explicitly *not* an official product); community servers exist for VirusTotal, MISP, OTX. [V]
9. Trust/safety is non-negotiable: tiered autonomy with **human approval gates before containment**, forensic-grade audit trails / chain-of-custody, verdict explainability with cited evidence, OCSF schema normalization, and compliance (GDPR Art. 33 72-hour breach documentation, NIST SP 800-61r3, SEC disclosure, MITRE ATT&CK mapping). [R][V]
10. For pregolya, this domain maps cleanly onto the planned graph-runtime primitives (durable checkpointed runs, HITL interrupts, structured output, parallel fan-out, MCP tools, tracing) but **forces four genuinely new surfaces**: forensic-grade immutable audit/provenance, risk-tiered authorization gating, evidence-cited structured verdicts, and prompt-injection isolation of untrusted tool content.

---

## 1. What a SOC Analyst Actually Does

### Tier model and core workflow loop
The traditional three-tier model persists in practice even as AI flattens it (Prophet Security and others argue Tier 1 is being absorbed by automation). [R]

- **Tier 1 (front-line triage).** Monitors the SIEM alert queue; performs the canonical triage stages: (1) ingestion/centralization, (2) categorization (by threat type, asset class, attack stage — often MITRE ATT&CK), (3) prioritization (severity + asset criticality + corroboration), (4) evidence gathering / **enrichment** (pull logs, endpoint telemetry, network flows, threat-intel reputation, asset owner, user context), (5) true-positive vs. false-positive determination, (6) escalation with attached context, (7) documentation. Closes FPs, escalates TPs, flags ambiguous cases. [R]
- **Tier 2 (deep investigation & early response).** Owns escalated cases; builds attack timelines, reconstructs process trees, analyzes memory/disk/packet artifacts; performs **event correlation / campaign detection** (linking disparate alerts by shared IP/account/hash/timeframe); executes early **containment** (host isolation, account disable, IP/domain block, process kill, session revoke), eradication, recovery; coordinates cross-team. [R]
- **Tier 3 / IR leads.** Major-incident command and crisis coordination; proactive **threat hunting** (hypothesis-driven queries across historical data); detection engineering (rule tuning — the sensitivity/specificity tradeoff that governs FP rate); post-incident review; strategic reporting to leadership/board. [R]

### The MTTR / alert-fatigue problem space (current numbers)
All figures below are **as-reported by deep research** [R]; treat as indicative, not independently benchmarked:

| Metric / statistic | Indicative value | Attributed source |
|---|---|---|
| Global avg. cost of a data breach | $4.88M (2024) | IBM Cost of a Data Breach 2024 |
| Daily alert volume (enterprise) | 10,000+ / day | SANS 2024 SOC Survey / Dropzone |
| SOCs unable to keep pace with alerts | 66% | SANS 2024 SOC Survey |
| SOCs overwhelmed by backlog | 90% | Osterman Research (via Dropzone) |
| Alerts ignored / un-reviewed | ~62% | Tines / MSSP Alert survey |
| False-positive rate (general) | up to 53% | Devo SOC Performance Report |
| Extreme FP example (IDS) | >99.7% (27,000 alerts, 76 real) | Devo |
| Analyst day spent on non-genuine alerts | ~1/3 | Morning Consult + IBM |
| Junior analyst turnover (<5 yrs exp) | ~70% leave within 3 yrs | SANS 2024 SOC Survey |
| Planning to use more AI tools | 89% | Vectra 2024 State of Threat Detection |
| AI-agent MTTC reduction (vendor case) | ~90% (30-40 min → 3-11 min) | Dropzone case study |

**Metric definitions.** MTTD = onset → detection; MTTR = detection → effective response (definitions vary; some include recovery); MTTC = detection → containment. **Explicit gap:** deep research found *no* independently verified cross-industry MTTD/MTTR benchmarks for 2025-2026 — organizations baseline internally. This is a real inconclusive area, not an omission. [R]

---

## 2. AI SOC Analyst Product Landscape (2026) — Verified

Capability claims below are largely **vendor marketing** unless flagged; independent empirical validation is sparse across the entire category. [R]

| Vendor / product | Positioning | Architecture (as disclosed) | Notable claims | Verification |
|---|---|---|---|---|
| **Dropzone AI** | Pure-play agentic SOC analyst | Fleet of collaborating agents, no playbooks/log-normalization required, pre-trained + NL-coachable, hypothesis-driven federated hunts | 90% ↓ investigation time, 10x alert capacity; pricing from ~$36k/yr / 4,000 investigations; humans authorize containment | [R] |
| **Prophet Security** | Autonomous AI SOC across T1/T2/T3 | Reasoning agents that dynamically build investigation plans, pivot across stack; agents "show their work" (plans, queries, evidence) | "Investigate every alert in minutes"; autonomous remediation for high-confidence + HITL for complex | [R] |
| **Radiant Security** | Agentic AI SOC | AI triage + research agents; "transparent reasoning for every decision" w/ full traceability | Investigates 100% of alerts | [R] |
| **Torq (HyperSOC / AI SOC Platform)** | Hyperautomation → agentic hybrid | **Deterministic + agentic reasoning, multi-agent, MCP integration**; 300+ integrations, 4,000+ steps; specialized case agents | >90% of cases remediated autonomously; sensitive actions gated | [R] |
| **Tines** | AI orchestration platform | Workflow "stories" + AI agents; orchestration layer, not an autonomous triage engine per se | Used w/ Elastic to automate SIEM investigations | [R] |
| **Microsoft Security Copilot** | Governed agent framework | 11 Security Copilot agents (Microsoft Secure 2025); **Security Alert Triage Agent** (renamed from Phishing Triage Agent) — autonomous, records verdict + NL rationale in Defender incidents, learns from feedback | Email/collab GA; identity/cloud in **preview**; ~15 min triage | **[V]** (Microsoft Learn + Tech Community) |
| **CrowdStrike Charlotte AI** | "Mission-ready" agentic; bounded autonomy | Generative + agentic; ingests cloud control-plane/workload/K8s/ASPM telemetry; prompt positions AI as "Tier 1 analyst"; cloud LLM | Autonomous triage + guiding-question RCA within expert-defined bounds | [R]; eval data below |
| **Google Gemini for SecOps (Chronicle)** | Assistant + Triage-and-Investigation (TIN) agent | On SecLM platform; NL search building, case summaries; TIN classifies TP/FP with findings + explanation; token/volume dashboards | Assistant-style, human retains response decisions | [R] |
| **SentinelOne Purple AI** | "Agentic AI security analyst" | Reasons over **OCSF-normalized** data; explainable "Verdict Justification"; automated actions only within pre-approved policies; every action logged; data not used to train | Virtual T1/T2 analyst | [R] |
| **Palo Alto Cortex XSIAM** | Autonomous playbooks | Automates workflows off Cortex Analytics alerts; **sensitive/impactful actions highlighted for analyst approval, never auto-executed** | Autonomous playbooks on by default for new tenants (dated ~May 2026 in source) | [R] |
| **Simbian** | Pure-play agentic | Federated reasoning across 100+ tools; "reasoning not rules," no playbooks; "Context Lake" RL feedback loop | 100% coverage, ~92% auto-resolution | [R] |
| **Intezer (Forensic AI SOC)** | Forensic-first hybrid | Proprietary + commercial models + deterministic forensics (endpoint forensics, reverse-engineering, sandboxing, static analysis); most alerts triaged without heavy LLM use | Sub-minute triage, <2% escalated, 98% verdict accuracy (vendor-reported) | [R] |
| **Exaforce** | Managed agentic SOC (MDR) | "Exabots" + human analysts, full transparency | Combined AI + human MDR | [R] |

### Documented limitations / failure modes (the important part for holdout design)
- **Accuracy variance & tool-use failure.** A frontier-model evaluation (surfaced via the CrowdStrike Charlotte AI ZenML profile) reported accuracy ranging from single digits to ~80% across models, with **tool-use failures in ~36% of conversations**, and hallucination of nonexistent domain facts in 15-45% of cases in a separate (non-security) context. [R]
- **Hallucinated verdicts.** Even domain-grounded RAG systems hallucinate: legal RAG tools (LexisNexis/Thomson Reuters) hallucinate 17-33% of responses; best (Lexis+ AI) ~65% accurate. By analogy, SIEM/EDR-grounded SOC agents will still occasionally misinterpret telemetry — so unreviewed hallucination-driven containment is treated as unacceptable industry-wide. [R]
- **Prompt injection.** Alert/log content is adversary-influenced; malicious text embedded in telemetry can attempt to steer an LLM agent. (Flagged by deep research as a recognized risk drawn from broader security literature — *not* explicitly documented in the vendor materials examined.) [R]
- **Automation bias.** Authoritative-looking explanations increase over-trust; role-aware, uncertainty-exposing explanations mitigate it ("Too Much to Trust?" arXiv, 2025). [R]
- **Transparency asymmetry.** Vendors disclose architecture selectively; almost none publish baselines, sample sizes, FP/FN rates, or independent benchmarks. The category is marketing-forward and evidence-light. [R]

---

## 3. Tool Surface & MCP Adoption in Security (Verified)

### Categories a SOC agent must integrate with [R]
- **SIEM / security data lake:** Splunk, Microsoft Sentinel, Elastic Security, Google Chronicle/SecOps — the global situational picture; agents query events, pivot into raw logs.
- **EDR/XDR:** CrowdStrike Falcon, SentinelOne, Microsoft Defender — endpoint telemetry + containment (isolate, remediate, forensic capture).
- **Threat intel:** MISP, VirusTotal, AlienVault OTX, Recorded Future — enrich IPs/domains/hashes/URLs with reputation + campaign context.
- **SOAR / ticketing / incident mgmt:** ServiceNow, Jira, PagerDuty — open/track tickets, page responders, run playbooks, request approvals.
- **Identity / IAM:** Okta, Microsoft Entra / Active Directory — authoritative identity, group membership, auth events; containment via disable/revoke.
- **Network / firewall / NDR:** flow logs, firewall logs, rule/segmentation changes — least MCP-mature category.

### Real, verifiable MCP servers for security tools (as of mid-2026)
Cross-validated during this task where marked [V]:

| Tool | MCP server | Official / community | Status | Evidence |
|---|---|---|---|---|
| **Splunk** | Splunk MCP Server (Splunkbase app 7931) | **Official (Splunk LLC)** | **GA** (v1.0.0 GA; latest 1.2.1, Jun 2026); RBAC + OAuth 2.1 | **[V]** splunkbase.splunk.com/app/7931; help.splunk.com |
| **Microsoft Sentinel** | Sentinel MCP server | **Official (Microsoft)** | Public preview Sep 30 2025 → **GA Nov 18 2025**; NL query over data lake + Defender | **[V]** Microsoft Security Blog / Tech Community |
| **CrowdStrike Falcon** | `falcon-mcp` | **Community-driven, maintained by CrowdStrike — explicitly NOT an official CrowdStrike product** (MIT) | Public preview; released Aug 5 2025; 15+ modules (detections, incidents, intel, RTR) | **[V]** github.com/crowdstrike/falcon-mcp — *corrects the deep-research claim of "official vendor-supported"* |
| **Okta** | Okta MCP Server | **Official (Okta)** | Bridges LLM→Okta APIs; OAuth scopes (okta.users.read etc.); device-auth / private-key JWT | [R] |
| **ServiceNow** | MCP Server Console | **Official (ServiceNow)** | Governed access to instance functionality for AI clients | [R] |
| **Atlassian (Jira/Confluence)** | Rovo MCP server | **Official (Atlassian)** | Acts with user's permissions; least-privilege + audit-log guidance | [R] |
| **VirusTotal** | `mcp-virustotal` | Community | URL/file/IP/domain + relationship APIs | [R] |
| **MISP** | `MISP-MCP-SERVER` | Community | Threat-intel query/correlate/share to LLMs | [R] |
| **AlienVault OTX** | `otx-mcp` | Community | Full OTX API interface (indicators, pulses) | [R] |
| **Wiz** | MCP Server for Wiz Defend | Official (Wiz) | CSPM / vuln-prioritization exposure | [R] |

**Could NOT verify** dedicated MCP servers for: Elastic Security, Google Chronicle, SentinelOne, standalone Microsoft Defender (accessed via Sentinel), Recorded Future, PagerDuty, or any network/firewall vendor. Deep research explicitly declined to assert these. [R]

### MCP architecture relevance to pregolya
MCP is a Host (runs model + MCP client) / Client (comms + capability discovery) / Server (exposes tools+data) model, standardizing tool calling so one agent can swap models and reuse integrations; supports **runtime capability discovery**. Security governance is layered on top (least privilege, scoped credentials, audit logging) — MCP is *not* itself a security control. This directly validates pregolya's `pregolya-mcp` crate (port of langchain-mcp-adapters) as the correct integration surface. [R]

### OCSF (Open Cybersecurity Schema Framework)
An open, vendor-neutral schema normalizing security telemetry across tools; maturing into wide adoption (AWS, Datadog, SentinelOne Purple AI reasons over OCSF-normalized data). For a cross-tool agent, OCSF matters because it lets the agent interpret and correlate events from disparate sources uniformly and map to MITRE ATT&CK — reducing per-tool schema-handling. **This is a normalization layer pregolya does not currently model.** [R]

---

## 4. Trust / Safety / Compliance Requirements

### Human approval gates before containment (tiered autonomy)
The industry consensus is **tiered autonomy**: "AI gets more freedom where risk is low; humans stay firmly in the loop where risk is high." Representative tiering (Underdefense model): [R]
- **Auto (read-only):** triage, enrichment, correlation — no side effects.
- **Auto within pre-approved policy (low-risk):** close benign alerts, create tickets, annotate.
- **Analyst approval required (medium-risk):** credential suspension, conditional-access restriction, session revocation.
- **Senior-analyst / SOC-manager authorization (high-risk):** endpoint isolation, account lockout, network-segment quarantine.

Why fully autonomous containment is risky: high-impact actions (isolating a production DB, disabling an exec account, blocking a critical IP) cause business disruption if misapplied; combined with non-zero hallucination rates, unreviewed containment is deemed unacceptable. Vendor implementations: CrowdStrike "bounded autonomy" / expert-defined limits; Palo Alto XSIAM highlights sensitive actions for approval and never auto-executes them; SentinelOne fires only within pre-approved policies + logs everything. [R]

### Audit trails, evidence chains, forensic soundness
- **Chain of custody:** chronological record of who handled evidence, when, why — broken chains render evidence inadmissible. Principles: never work on originals (bit-for-bit copies), hash verification, forensically clean media, full documentation. [R]
- **Auditability & reproducibility:** every AI decision must be **observable** and every action **auditable** — logs must capture which agent acted, which models/rules applied, which data was accessed, and the rationale. AI-generated notes/verdicts become part of the evidence record subject to the same logging + chain-of-custody standards as human entries. [R]
- **Phased deployment** (shadow mode → scoped pilot with approval on every response → broader autonomy) is the standard trust-building path. [R]

### Verdict explainability
SOC agents must show reasoning and **cite the specific evidence** (log entries, alerts, intel entries) behind a benign/malicious verdict. Explainability is both a cognitive aid (calibrated analyst trust, not blind trust or reflexive dismissal) and a control against hallucination (analyst can cross-check that cited evidence actually exists and supports the conclusion) and automation bias. Role-aware explanations (T1 vs T3 vs manager) with exposed uncertainty outperform generic confidence scores ("Too Much to Trust?", 2025). SentinelOne "Verdict Justification" and Prophet/Radiant "show their work" are concrete implementations. [R]

### Compliance / regulatory context
- **GDPR Article 33:** notify supervisory authority of a personal-data breach without undue delay, ≤72h; document facts, effects, remedial actions sufficient for the authority to verify compliance. AI involvement (what it surfaced, concluded, recommended/executed, how humans reviewed) must be in the record. **[V-adjacent / R]**
- **NIST SP 800-61 Rev.3** (finalized Apr 2025): incident-response guidance aligned to NIST CSF 2.0 (prepare; detect/analyze; contain/eradicate/recover; post-incident) with documentation across phases. [R]
- **SEC cyber incident disclosure** (2023 rules) and **SOC 2 trust-service-criteria** mappings: relevant but **NOT directly sourced** in this research — flagged as general domain knowledge, needs dedicated lookup if a holdout leans on them. [R — low confidence]
- **MITRE ATT&CK** mapping: the lingua franca for categorizing observed behavior into tactics/techniques; pervasive across triage, correlation, hunting, and explanations. [R]

### LLM-specific security risks (design constraints)
Hallucinated verdicts; **prompt injection via malicious log/alert content** (adversary-controlled text entering the reasoning loop through tool output); over-trust/automation bias. These are framework-level safety concerns because the *tool-output boundary* is an untrusted-input boundary. [R]

---

## 5. Framework Demands — Mapping to pregolya's Planned Surface

Legend: **COVERED** = in D8 checklist / D7 / D11 / D13 planned surface. **PARTIAL** = foundation exists, SOC-specific extension needed. **NEW** = not in current planned surface; this domain forces it.

| SOC requirement | pregolya primitive | Status | Notes |
|---|---|---|---|
| Long-running, multi-stage investigations that survive process restarts | Durable checkpointed graph runs; 3-tier durability, sync crash-safe default (D7, D11.3); pregolya-server durable runs (D13) | **COVERED** | P0 differentiator. Investigations may span hours→days; checkpoint/resume is exactly the lead feature. |
| Approval gate before containment | HITL interrupt mid-run (D8 checklist) | **PARTIAL → NEW** | A single interrupt exists conceptually, but SOC needs **risk-tiered authorization**: typed action-risk classification (read-only / low / medium / high) routed to different approver roles, with the run durably parked awaiting a specific role's sign-off. Richer than one boolean interrupt. |
| Structured triage verdict | Structured output (D8 checklist) | **PARTIAL → NEW** | Verdict *shape* is covered; SOC forces **evidence-cited verdicts** — verdict + severity + classification + justification + machine-checkable links to the specific evidence artifacts consulted (provenance). |
| Parallel enrichment fan-out (SIEM + EDR + intel + identity concurrently) | Parallel execution / fan-out (D8 checklist) | **COVERED** | Classic map-fan-out-join over independent tool calls. Must handle partial failure (one tool errors) gracefully. |
| Tool calling to security stack | pregolya-mcp (D1) + MCP tool integration (D8) | **COVERED** | Real MCP servers exist (Splunk, Sentinel, Okta, ServiceNow, falcon-mcp, VT/MISP/OTX). Validates the crate's priority. |
| Audit trail / evidence chain / reproducibility | Tracing + callbacks (ported); checkpoint history | **PARTIAL → NEW** | Ordinary tracing ≠ forensic audit. SOC forces **tamper-evident, immutable, attributable decision log** (which agent, which model, which data, which rationale, when) suitable for chain-of-custody and GDPR Art. 33 verification. Checkpoint history + msgpack wire format (D11.2) is a foundation but not a forensic audit guarantee. |
| Alert-storm / high-volume concurrency + fairness | Actor-style outer scheduler w/ quotas/fairness (D11.1) | **PARTIAL** | Multi-tenant fairness is designed; must be *proven* at alert-storm scale (thousands of concurrent short triage runs) with backpressure. |
| Conditional routing (escalate vs. close vs. hunt) | Quality-gate conditional routing (D8) | **COVERED** | Verdict-driven branch is standard graph conditional edges. |
| Sub-investigation delegation (spawn a focused hunt from a lead) | Hierarchical sub-agent delegation/spawning (D8) | **COVERED** | Maps to Tier-2 pivoting / Tier-3 hunt spin-off. |
| Cancellation / timeout of a stalled investigation mid-fan-out | Cancellation (D11 design considerations) | **PARTIAL** | Must cleanly cancel in-flight tool calls and checkpoint a partial state. |
| Prompt-injection isolation of untrusted tool output | — | **NEW** | Log/alert content is adversary-influenced. Framework should support treating tool output as untrusted (content/instruction separation, output constraints) at the tool boundary. No current primitive addresses this. |
| OCSF-style schema normalization at tool boundary | — | **NEW (likely out-of-core)** | Cross-tool correlation benefits from normalized telemetry. Probably an integration-layer concern, not core-graph — but worth an explicit "not our layer" decision. |

---

## 6. Realistic Evaluation Shapes (general only — NOT holdout scenarios)

These are *categories* of scenario that would credibly stress a SOC agent, provided to guide the product-owner's hidden authoring — deliberately generic:

- **Alert-storm triage under concurrency.** A burst of many alerts arrives near-simultaneously; agent must triage in parallel, prioritize by asset criticality, and not collapse under fan-out — exercises parallel execution + scheduler fairness + backpressure.
- **Multi-stage intrusion investigation (long-horizon, durable).** A single incident unfolds across many correlated signals and requires timeline reconstruction spanning a run long enough to cross a process restart — exercises durable checkpoint/resume + sub-investigation delegation + correlation.
- **False-positive discrimination.** A benign-but-suspicious pattern (e.g., legitimate admin automation resembling malicious scripting) must be correctly dismissed *with cited evidence* — exercises evidence-cited structured verdict + explainability + hallucination resistance.
- **Containment-with-approval.** Investigation concludes a host should be isolated / account disabled; the run must durably pause at a risk-tiered gate, route to the correct approver role, and only then execute — exercises HITL interrupt + risk-tiered authorization + audit trail.
- **Adversarial tool-content resistance.** Alert/log payload contains embedded text attempting to steer the agent — exercises prompt-injection isolation at the tool-output boundary.
- **Auditability / reproducibility replay.** After the fact, reconstruct exactly what the agent did, which evidence it consulted, and why — exercises forensic audit log + verdict provenance.

---

## Phase-1-Ready Capability Checklist (Domain A contributions)

Architecture/PRD must demonstrate the following are supportable. Items marked **[extends checklist]** are new or sharpened relative to the D8 baseline:

- [ ] Durable, checkpointed graph runs that resume across process restarts (multi-hour → multi-day investigations).
- [ ] Parallel tool fan-out with graceful partial-failure handling (one tool erroring does not fail the investigation).
- [ ] MCP tool integration against real security-tool MCP servers (Splunk/Sentinel/Okta/ServiceNow/falcon-mcp/VT/MISP/OTX).
- [ ] Conditional routing on verdict (close / escalate / hunt / contain).
- [ ] Hierarchical sub-agent delegation (spawn a focused sub-investigation/hunt from a lead).
- [ ] Mid-run cancellation/timeout with clean checkpoint of partial state.
- [ ] **[extends checklist]** Risk-tiered human authorization gates: typed action-risk levels (read-only / low / medium / high) with the run durably parked awaiting the correct approver role before any containment side-effect executes.
- [ ] **[extends checklist]** Evidence-cited structured verdicts: verdict + severity + classification + justification + machine-verifiable references to the specific evidence artifacts consulted (provenance).
- [ ] **[extends checklist]** Forensic-grade, tamper-evident, attributable audit trail of every agent decision and action (agent id, model, data accessed, rationale, timestamp) — reproducible and sufficient for chain-of-custody / GDPR Art. 33.
- [ ] **[extends checklist]** Untrusted-tool-output boundary: framework support for treating tool/observation content as untrusted input (content vs. instruction separation) to resist prompt injection via log/alert payloads.
- [ ] **[extends checklist]** Prove alert-storm concurrency: many concurrent short triage runs under the actor-style scheduler with fairness/quotas/backpressure (validates D11.1 at scale).
- [ ] **[decision needed]** Explicit stance on OCSF-style schema normalization: core, integration-layer, or out-of-scope.
- [ ] **[decision needed]** Explicit stance on whether SEC-disclosure / SOC 2 compliance semantics are in-scope for any holdout (currently low-confidence, unsourced).

---

## Research Methods

| Tool | Queries | Purpose |
|------|---------|---------|
| **Perplexity perplexity_research (PRIMARY)** | 4 (all `reasoning_effort: high`) | (1) SOC analyst tier workflows + MTTR/alert-fatigue numbers; (2) AI SOC product landscape 2026 w/ architectures + failure modes; (3) tool surface + MCP adoption in security + OCSF; (4) trust/safety/governance/compliance |
| Perplexity perplexity_reason | 0 | — |
| Perplexity perplexity_search | 0 | — |
| Perplexity perplexity_ask | 0 | — |
| Context7 | 0 | — (no single-library API question) |
| Tavily tavily_search | 3 (advanced) | Cross-validate vendor/product facts: falcon-mcp status, Microsoft Security Alert Triage Agent rename, Splunk MCP Server + Sentinel MCP GA status |
| Tavily tavily_research / extract / crawl / map | 0 | — |
| WebFetch | 0 | — |
| WebSearch | 0 | — |
| Training data | 2 areas (flagged) | SEC disclosure rules + SOC 2 mappings (deep research also lacked direct sources — flagged low-confidence); MITRE ATT&CK general framing |

**Total MCP tool calls:** 7 (4 perplexity_research + 3 tavily_search)
**Training data reliance:** low — nearly all claims are MCP-sourced; the two training-data areas are explicitly flagged as low-confidence and gated behind "decision needed" items.

**Verification corrections made vs. deep-research output:**
1. CrowdStrike `falcon-mcp` — deep research called it "official vendor-supported"; the repo explicitly states it is *community-driven, NOT an official CrowdStrike product* (though CrowdStrike-maintained, MIT). Corrected in §3. [V: github.com/crowdstrike/falcon-mcp]
2. Splunk MCP Server — deep research said "beta"; it reached **GA** (v1.0.0; latest 1.2.1, Jun 2026). Corrected in §3. [V: splunkbase.splunk.com/app/7931, help.splunk.com]
3. Microsoft Sentinel MCP — added verified timeline: preview Sep 30 2025 → GA Nov 18 2025. [V]
4. Microsoft Security Alert Triage Agent — confirmed rename from Phishing Triage Agent; email/collab GA, identity/cloud preview. [V: learn.microsoft.com]

**Flagged inconclusive:** no independently verified cross-industry MTTD/MTTR benchmarks 2025-2026; all alert/FP/turnover statistics are vendor/survey-reported (indicative, not audited); AI SOC vendor accuracy claims are almost entirely un-benchmarked marketing.
