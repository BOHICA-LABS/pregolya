---
document_type: domain-spec-section
level: L2
section: capabilities-p1-p2
version: "1.0"
status: active
producer: business-analyst
timestamp: 2026-07-14T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/STATE.md
input-hash: "f6a9de5f38547412b42b12dbd19c3733ab48c3741c91c3cacad08519057dee21"
traces_to: L2-INDEX.md
decisions: [D1, D3, D7, D8, D13, D17]
---

# Domain Capabilities — P1 and P2

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.
> P0 capabilities are in `capabilities-p0.md`.

---

## P1 — Partners, Conformance, MCP, and Governance (Wave 2)

### CAP-009: Provider-Conformant Chat Model Interface

Expose a chat model trait that passes ferrochain-standard-tests for streaming, tool calling,
structured output, error propagation, and token accounting. First-party implementations for
OpenAI, Anthropic, Ollama. Architecture uses standalone SDK crate split (HS-6/D17-Q5):
`ferrochain-<provider>-sdk` (wire client) + `ferrochain-<provider>` (Runnable adapter).

**Grounding:** product-brief.md §Scope Wave 2 — `ferrochain-openai`, `ferrochain-anthropic`,
`ferrochain-ollama` first-party provider crates (D3 early-integration priority); standalone
SDK crate split architecture (HS-6/D17-Q5).
**Anchor justification:** CAP-009 covers provider conformance because the brief names the three
provider crates explicitly in Wave 2 scope and market differentiator #5 requires a
LangChain-semantic migration story.

### CAP-010: MCP Tool Adapter

Discover tools from MCP servers at runtime, present them to a graph as standard ferrochain
Tools, and route ToolInvocation requests to the correct MCP server transport. Treat all
tool-result content as untrusted ingress (DI-012). Target semantic surface:
langchain-mcp-adapters==0.3.0 (D1/D2).

**Grounding:** product-brief.md §Scope Wave 2 — `ferrochain-mcp` port of
langchain-mcp-adapters==0.3.0 (D2); MCP client adapter for security, productivity, and
custom server integration.
**Anchor justification:** CAP-010 covers MCP adapter because D1 mandates ferrochain-mcp as
the primary integration surface after langchain-community was archived. Overflow §MCP-Surface
lists verified active MCP servers that must be supported.

### CAP-011: Provider Conformance Suite (Standard Tests)

Provide a test crate (`ferrochain-standard-tests`) that every ferrochain provider crate must
pass before v1 release. Tests exercise: streaming completions, tool-call round-trips,
structured output, error-type fidelity, and token-usage accounting. Port of LangChain's
`langchain-tests` conformance suite.

**Grounding:** product-brief.md §Scope Wave 2 — `ferrochain-standard-tests` port of
LangChain's langchain-tests conformance suite; "all Wave 2 provider crates must pass before
v1 release."
**Anchor justification:** CAP-011 covers the conformance suite because it is an explicit Wave 2
deliverable named in the brief and market differentiator #2.

### CAP-012: Budget Governance (Allow / Escalate / Deny; Cost Metering)

Evaluate token and cost consumption per run and per sub-agent against a composable
BudgetPolicy (allow / escalate / deny). Record every evaluation in an append-only
EvidenceJournal. When the ceiling is reached, degrade gracefully: halt the run, or escalate
to a HITL interrupt, according to the policy's `on_ceiling` setting.

**Grounding:** product-brief.md §Scope cross-cutting — Phase-1 BC backlog D17-Q4: "budget
governance allow/escalate/deny policy trait, composable, append-only evidence journal —
Domain B dark-factory holdout requires it."
**Anchor justification:** CAP-012 covers budget governance because D17-Q4 explicitly mandates
it as a Phase-1 BC, and the domain-b-dark-factory holdout cannot evaluate without it.

### CAP-013: Content Provenance Tagging and Guardrail-on-Ingress

Attach a ProvenanceTag to content at every ingress boundary (tool-result, RAG, memory).
Fire a registered GuardrailHook before content enters the model context. The hook can accept,
reject (replace with an error block), or redact. The guardrail seam is in the
InvocationContext; it fires unconditionally — there is no opt-out code path for tool-result
ingress.

**Grounding:** product-brief.md §Scope cross-cutting — Phase-1 BC backlog D17-Q8:
"content provenance-tag seam + guardrail hook at tool-result, RAG, and memory ingress —
Domain A SOC analyst holdout."
**Anchor justification:** CAP-013 covers guardrail-on-ingress because D17-Q8 makes it a
Phase-1 BC and domain-a-soc-analyst.md §5 marks prompt-injection isolation as NEW forcing
function.

### CAP-014: Durable-Run HTTP Server (Threads, Assistants, Runs, Crons)

Provide a first-party HTTP server that manages: Thread (durable conversation history),
Assistant (named agent config), Run (single execution), and CronSchedule (recurring
proactive runs). Streaming and unary run endpoints drive the same graph execution engine.
No wire-compatibility with LangGraph Platform (D13).

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-server`: threads, assistants,
cron scheduler, streaming and unary run equivalence (NE-13/D17); first-party per D13.
**Anchor justification:** CAP-014 covers ferrochain-server because D13 names it as first-party
and the brief lists its required resource types (threads, assistants, cron, streaming/unary
equivalence) explicitly.

### CAP-015: Sandboxed Tool Execution (Enforcing Backend Default)

Execute tools in an enforcing isolation backend (WASM or container) by default. The process
backend requires explicit opt-in and emits a loud warning. On a strict policy with a
non-enforcing backend, return `Err(PolicyNotEnforceable)` — do not silently fall back. All
workspace file operations call `canonicalize_beneath_root(base, path)` at access time.

**Grounding:** product-brief.md §Scope Wave 0 NE catalog — NE-01/NE-02/D17: "Enforcing
sandbox backend (WASM/container) must be the default; process backend is loud opt-in."
**Anchor justification:** CAP-015 covers sandbox enforcement because NE-01 and NE-02 are both
named as first-class BC candidates in the brief's Overflow §Security-PRD-Carry-Forward.

### CAP-016: Typed Error Taxonomy (FerrochainError 2D Struct)

Surface errors as a 2D struct with Component dimension (which ferrochain crate) and Category
dimension (auth, validation, timeout, provider, internal, etc.), carrying a RetryHint,
machine code, and RFC-7807-compatible emission. No `.unwrap()` or `.expect()` in non-test
code; CI lint gate enforces this. All library constructors return `Result`.

**Grounding:** product-brief.md §Scope Wave 0 — FerrochainError 2D component×category error
taxonomy (CONFLICT-6/D17); Overflow §Security-PRD-Carry-Forward NE-07.
**Anchor justification:** CAP-016 covers the error taxonomy because CONFLICT-6 (adopted from
adk-rust P-01/P-04) is named in the brief's Wave 0 scope and NE-07 is in the security
carry-forward table.

---

## P2 — Extended Capabilities (Post-v1 Candidates)

### CAP-017: Long-Horizon Cross-Session Memory Store (KV + Vector)

Persist key-value and vector-embedding memory across threads, decoupled from checkpoints.
Support hybrid retrieval (vector similarity + keyword). Provide user-private, app-scoped,
and session-scoped tiers. GDPR erasure must remove all traces from all tiers (CONFLICT-7
memory scope model). Default backend: SQLite with optional vector embeddings.

**Grounding:** product-brief.md §Constraints (implied by Domain C OpenClaw forcing function
and LangGraph Store analog); CONFLICT-7 memory scope — user/app/session partitioning + GDPR
erasure; domain-c-openclaw.md §2.6.
**Anchor justification:** CAP-017 covers long-horizon memory because Domain C identifies
file-backed memory with vector retrieval as a gap (domain-c §5, item #2), and CONFLICT-7
shapes the tier model.

### CAP-018: Tool Retry with Circuit Breaker

Retry tool invocations with a per-tool retry policy keyed by `(tool_name)` — not args hash.
Enforce a finite `global_limit` (not None). Trip a circuit breaker after repeated failures
to prevent infinite retry on permanently failing tools.

**Grounding:** product-brief.md §Constraints NE catalog — NE-09 (adk-rust P-63 termination
hole REJECT): "Retry bound keyed on (tool_name) not args; finite global_limit non-None
default; circuit-breaker on by default."
**Anchor justification:** CAP-018 covers tool retry because NE-09 is listed in the NE catalog
as a ferrochain requirement derived from the adk-rust counter-example. The brief says all 17
NE items must be anchored before Phase-2 story decomp.

### CAP-019: Formal Verification Pipeline (Kani + cargo-fuzz)

Run Kani harness proofs for the three committed VP obligations (D17-Q7): BSP determinism VP
(VP-001, DI-001/NE-17), session triple-address uniqueness VP (VP-002, DI-005/NE-12), and
workspace path confinement VP (VP-003, DI-007/NE-02). Run cargo-fuzz on the core
serialization and graph-execution paths. Both tools locked by D17-Q7.

**Grounding:** product-brief.md §Success Criteria — "All 3 committed VP obligations pass Kani
harness before v1 convergence (D17-Q7)"; §Scope cross-cutting — "Formal verification
pipeline: Kani proofs + cargo-fuzz [both locked: D17-Q7]."
**Anchor justification:** CAP-019 covers formal verification because D17-Q7 commits the top-3
VP obligations by name and the brief's success criteria include VP coverage as a gate metric.
**Note on phase placement:** VP deliverables belong to Phase 6 (formal hardening). The
behavioral invariants they prove (DI-001, DI-005, DI-007) are Phase-1 BC scope.
