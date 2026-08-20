---
document_type: blocking-issues-resolved
level: ops
version: "1.0"
status: archive
producer: state-manager
timestamp: 2026-07-14T01:00:00Z
cycle: v1.0.0-greenfield
inputs: [STATE.md]
input-hash: "f45eac4"
traces_to: STATE.md
---

# Resolved Blocking Issues — v1.0.0-greenfield

<!-- Blocking issues that were resolved and archived from STATE.md.
     Open blocking issues remain in STATE.md. -->

## Resolved Risk Entries — Archived from STATE.md Risk Register (Burst 221 compaction, 2026-07-21)

These risk entries were resolved, downgraded to Low/effectively-closed, or had their root cause
addressed during Phase pre-1 / Phase 1. Open risks R6, R8, R10, R11, R12 remain in STATE.md.

| ID | Risk | Severity | Affects | Resolution |
|----|------|----------|---------|------------|
| R1 | langgraph `scheduler-kafka` confirmed removed from langgraph 1.2.9. With D1 amended, treat as out-of-scope unless architecture finds a dependency | Low | Phase 1/3 | Effectively resolved by D1 amendment |
| R2 | langchain-community stable is 0.4.x; v1.0.0a1 tagged — API churn risk for community wave | Medium | Phase 1/3 | Phase community work last per D1 roadmap — deferred by design |
| R3 | DTU scope revised per D13 — ferrochain-server is first-party. DTU = OpenAI, Anthropic, provider APIs, Ollama keyless CI. Pass-6 "stateful fake" RETIRED. | Low | Phase 1 | Direction resolved by D13 |
| R4 | langgraph crate 0.2.5 (2026-07-01, pre-1.0) ships Postgres/Sqlite checkpointing. Competitor velocity HIGH confirmed. ferrochain differentiator = GA maturity + conformance suite + formal verification. Watch for their 1.0 release. | Medium | Phase 1/3 | REFRAMED per burst-74 research. Monitor langgraph 1.0 release date. Not a blocking risk. |
| R5 | Three incompatible tag conventions across reference repos — tag-sort bug already triggered (langgraph mis-pinned at 0.3.34, corrected) | Low | Tooling | Semport tooling handles all three conventions; risk closed |
| R7 | langchain-protocol v0.0.17 — no stable release; schema evolving. Port rationale is version-volatility, not immaturity (v3 streaming has 107 dedicated tests — corrected cert pass 9). | Low | Phase 1/3 | DOWNGRADED from Medium; full schema in .factory/semport/core/ANALYSIS-STATE.md |
| R9 | Platform API churn re-classified per D13 — SDK-1.2.9 endpoint catalog is design reference only; no conformance target. | Low | Phase 1 | Severity downgraded per D13; non-blocking |

## Resolved Blocking Issues — Archived at burst-285 (2026-07-31)

| ID | Issue | Severity | Resolution |
|----|-------|----------|------------|
| E011 | `publish-all.sh` §publish-loop `cd` command navigated to `/Users/jmagady/Dev/pregolya/namespace-reservation/` (non-existent at the time D-115 was authored; working dir was `/Users/jmagady/Dev/ferrochain`). Script entirely non-functional at old path. | High | CLOSED — working directory renamed to `/Users/jmagady/Dev/pregolya` (D-116). The `cd` path in `publish-all.sh` now resolves. No file edit required; the directory rename made it correct. Closure basis: worktree linkage verified clean; `git -C /Users/jmagady/Dev/pregolya/.factory status --porcelain` = empty. |
| E012 | All 21 stub Cargo.toml files carried `repository = "https://github.com/BOHICA-LABS/pregolya"` which would have been a live URL only after the GitHub repository rename. D-115 registered this as a pre-publish hard gate. | High (irreversible if skipped) | CLOSED — GitHub repository renamed BOHICA-LABS/ferrochain → BOHICA-LABS/pregolya (D-116). Old URL 301-redirects. All 21 stubs now declare a resolving `repository` URL. Branch protection on `main` and `develop` verified identical to pre-state (five CI contexts, strict: true, enforce_admins: false). Publishing will embed a live URL rather than a 404 into 21 immutable crate versions. |
