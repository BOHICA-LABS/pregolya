---
document_type: burst-log
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-07-12T23:14:56Z
cycle: v0.0.0-pre-pipeline
inputs: [STATE.md]
input-hash: "[live-state]"
traces_to: STATE.md
---

# Burst Log — v0.0.0-pre-pipeline

## Burst: pre-pipeline burst 1 — toolchain preflight, reference corpus, arch research (2026-07-12)

**Parent-commit:** 6dca920f9895e11d849ed4f57d67ccc56f608b1b

**Adversary verdict:** n/a — pre-pipeline burst; no spec or implementation artifacts subject to adversarial review yet.

**Files touched (Dim-1): 3 unique files**

- .factory/preflight-report.md
- .factory/semport/reference-manifest.md
- .factory/semport/langchain-research.md

**Codifications:** D1-D6 human decisions locked. Pipeline advanced from INITIALIZED to IN_PROGRESS. .mcp.json gitignored (plaintext API keys resolved). Risks R1-R5 registered.

**Dim-2 Attestation:** n/a — pre-pipeline burst; no Rust code delivered; no behavioral-contract shell gates to run. Reference corpus cloned at pinned SHAs (verified via git -C .reference/langchain rev-parse HEAD).

**Dim-5 Attestation:** n/a — pre-pipeline burst; no WASM hook artifacts produced or modified in this burst.

**Dim-6 Attestation:** n/a — pre-pipeline burst; Cargo workspace not yet initialized; cargo fmt / clippy gates not applicable.

**Dim-7 Attestation:** n/a — pre-pipeline burst; no test suite yet; cargo nextest / bats gates not applicable.

**Closes:** pre-pipeline steps: toolchain-preflight (WARN), reference-corpus-clone (DONE), external-research-langchain-v1-arch (DONE).

---

### Burst 1 Detail

| Agent | Task | Outcome |
|-------|------|---------|
| dx-engineer | Toolchain preflight — validate rustc 1.95.0, 7 verification tools, gh auth, direnv, .mcp.json | WARN: direnv unenabled (B1 open); .mcp.json had plaintext API keys → resolved via .gitignore |
| devops-engineer | Reference corpus shallow-clone — pin langchain, langgraph, langchain-community at latest stable v1 tags | DONE: 3 repos pinned; note: langgraph initially mis-pinned at 0.3.34 due to tag-sort bug (R5), corrected to 1.2.9 |
| research-agent | External research — LangChain v1 architecture, ecosystem structure, langgraph internals | DONE: .factory/semport/langchain-research.md |

### Human Decisions Recorded

| ID | Decision |
|----|----------|
| D1 | Full ecosystem port scope (langchain-core + langchain v1 + text-splitters + 15 partner packages + FULL langgraph incl. Platform SDK/CLI + FULL langchain-community ~1,051 modules roadmap-phased) |
| D2 | Reference version pins: langchain==1.3.13 / langgraph==1.2.9 / langchain-community==v0.4.2 |
| D3 | Early integrations: OpenAI, Anthropic, Ollama first; then full partner set |
| D4 | Single Cargo workspace; crates publish individually |
| D5 | Dependency disposition mandate: per-package disposition file; pydantic→serde/schemars ADR required before BCs |
| D6 | Naming under research; `langchain` and `langgraph` crate names TAKEN on crates.io |

### Risks Flagged

| ID | Risk |
|----|------|
| R1 | langgraph `scheduler-kafka` removed 0.3.x→1.2.9 — confirm new home before porting |
| R2 | langchain-community API churn (0.4.x stable vs 1.0.0a1 tagged) |
| R3 | LangGraph Platform SDK/CLI → DTU_REQUIRED likely TRUE at P1-06 (proprietary SaaS backend) |
| R4 | Competing active `langgraph` crate on crates.io (updated 2026-07-01) |
| R5 | Three incompatible tag conventions across reference repos — tag-sort bug already triggered |
