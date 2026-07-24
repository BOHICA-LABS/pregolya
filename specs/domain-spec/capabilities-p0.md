---
document_type: domain-spec-section
level: L2
section: capabilities-p0
version: "1.8"
status: active
producer: business-analyst
timestamp: 2026-07-23T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/product-brief.md
  - .factory/comparative/COMPARATIVE-ASSESSMENT.md
  - .factory/planning/holdout-domains/domain-a-soc-analyst.md
  - .factory/planning/holdout-domains/domain-b-dark-factory.md
input-hash: "1896407"
traces_to: L2-INDEX.md
decisions: [D1, D7, D8, D11, D13, D17, D21]
changelog:
  - "v1.8 (burst-241 OBS-P141-B, 2026-07-23): CAP-007: replace stale '12 variants total' absolute claim with forward-reference note '12-variant base; extended to 15 by D23 (CAP-034 events 13-14 tool-approval, CAP-035 event 15 compaction)'. CAP-007 legitimately defines the 12-variant BASE; a cross-referencing reader consulting the base spec was misled into believing 12 was the final count. TD-VSDD-060 sweep: sole stale absolute '12' streaming count in domain-spec/; all other '12' occurrences are historical changelog entries or already describe the 12-variant base correctly."
  - "v1.7 (2026-07-20): CAP-002 D21 reversal — PromptTemplate/ChatPromptTemplate flipped from 'post-v1/community' to v1 deliverables (SS-18/ferrochain-prompts, CAP-022/CAP-023); standalone OutputParser remains post-v1; with_structured_output covered by provider conformance (CAP-009), not a separate OutputParser. Prior v1.6 clarification partially superseded by D21 scope expansion (burst 216). D21 added to decisions list."
  - "v1.6 (2026-07-20): CAP-002 scope clarification added — listed Runnable examples (model call, prompt template, output parser, tool, graph) are user-implementable instances; ferrochain ships the trait and composition machinery in v1 only; PromptTemplate / OutputParser first-party impls are post-v1/community deliverables. Grounded in product-brief v1.3 out-of-scope dispositions and audit Q1 GAP. input-hash updated (drift: 8fe3546→2b2bd5a)."
  - "v1.3 (2026-07-17): F-P95-04 fix — CAP-012 on_ceiling enumeration was stale (two-mode: Halt | Escalate only). Expanded to all three canonical variants: Halt | Escalate | Summarize per interface-definitions §OnCeiling, BC-2.10.003 PC8, and D20 addition."
  - "v1.4 (OBS-P121 audit, fix burst 124, 2026-07-19): CAP-007 §StreamEvent variant list: add 12th variant guardrail_decision (F-P99-01, interface-definitions v2.34 §StreamEvent). Prior list of 11 variants was authored before the guardrail observability axis was added. Canon: interface-definitions §StreamEvent 12 variants."
  - "v1.5 (F-P122-01, fix burst 125, 2026-07-19): CAP-001 illustrative ContentBlock list: replaced 5-token drifted list (text, image_url, tool_use, tool_result, document) with canonical 14-variant enumeration per BC-2.01.001 PC2; added tool results → ToolMessage per BC-2.09.002."
  - "v1.2 (2026-07-17): F-P91-01 attribution fix — CAP-012 `on_ceiling` was mis-attributed to the `BudgetPolicy` trait; corrected to the budget configuration (`BudgetConfig::on_ceiling`) per api-surface.md ~line 70 and ADR-009. No other capabilities affected."
  - "v1.1 (2026-07-17): Provenance-integrity fix — STATE.md removed from inputs (D-NNN decisions baked at authoring time); COMPARATIVE-ASSESSMENT.md added (D17/CONFLICT-*/NE-* grounding for CAP-004, CAP-005, CAP-007, CAP-008, CAP-012, CAP-013, CAP-016); domain-a-soc-analyst.md added (CAP-013 guardrail-on-ingress forcing function); domain-b-dark-factory.md added (CAP-005 multi-day durability, CAP-012 budget governance forcing function); input-hash recomputed."
---

# Domain Capabilities — P0 (Must-Have for Release)

> **Sharded L2 section (DF-021).** Navigate via `L2-INDEX.md`.
> Continued in `capabilities-p1-p2.md` (P1 and P2 capabilities).
> **Pass-21 update:** CAP-012, CAP-013, CAP-016 relocated here from capabilities-p1-p2.md
> after ADV-P1D-PASS-21 found their L2 tier was inconsistent with PRD P0 section headers
> and constituent BC priorities. See §P0 — Cross-Cutting section below.

Each capability is grounded in the product brief. IDs are stable from this spec forward.

---

## P0 — Core Primitives and Graph Runtime (Wave 0 / Wave 1)

### CAP-001: Type-Safe Message and Content Primitive Construction

Construct typed messages (AiMessage, HumanMessage, SystemMessage, ToolMessage) whose content
is a sequence of typed ContentBlocks — Text, Reasoning, ToolCall, ToolCallChunk,
InvalidToolCall, Image, Video, Audio, PlainText, File, ServerToolCall, ServerToolCallChunk,
ServerToolResult, NonStandard — per BC-2.01.001 PC2; tool results are ToolMessage per
BC-2.09.002. Guarantee that no caller can observe raw untyped content where a typed variant
is expected.

**Grounding:** product-brief.md §Scope Wave 0 — `ferrochain-core` typed message/content
primitives (Runnable, Message, ContentBlock).
**Anchor justification:** CAP-001 covers typed content construction because the brief mandates
`ferrochain-core` typed ContentBlock as the API-surface root primitive and market
differentiator #4 (product-brief §Overflow Competitive Differentiator Traceability).

### CAP-002: Runnable Trait Abstraction (Compose, Pipe, Chain)

Express any computation — model call, prompt template, output parser, tool, graph — as a
Runnable that can be invoked, streamed, batched, and composed via `|` pipe into chains.
The listed examples are all user-implementable instances of the `Runnable` trait — ferrochain
ships the trait and composition machinery in v1.

**D21 scope update (v1.7):** `PromptTemplate` and `ChatPromptTemplate` ARE now v1 deliverables
(SS-18 / ferrochain-prompts, CAP-022 / CAP-023). The prior v1.6 clarification that
"PromptTemplate first-party impls are post-v1/community deliverables" is superseded by D21
(burst 216). Standalone `OutputParser` remains a post-v1/community deliverable — it is not
part of the D21 expansion. The `with_structured_output` use case is covered in v1 via provider
conformance (CAP-009), not a separate first-party OutputParser implementation. Summary of what
flipped and what did not:
- **Flipped to v1:** PromptTemplate, ChatPromptTemplate (CAP-022/023, SS-18)
- **Unchanged (post-v1):** standalone OutputParser; `with_structured_output` is provider-
  conformance scope (CAP-009), not a separate OutputParser implementation

Provides the universal composition protocol across all ferrochain crates.

**Grounding:** product-brief.md §Scope Wave 0 — "Runnable" is the core LangChain v1 semantic
primitive (reference-manifest.md, semport Corpus 1 langchain==1.3.13). The brief lists
`(Runnable, Message, ContentBlock)` as Wave 0 foundation. D21 (burst 216) supersedes the
product-brief §Out-of-Scope entry for PromptTemplate for the purposes of v1 scope.
**Anchor justification:** CAP-002 covers Runnable composition because the product-brief names
it explicitly in Wave 0 and it is the composition primitive that all higher capabilities
(chains, graphs, providers, and now prompt templates) depend on.

### CAP-003: StateGraph Definition (Nodes, Edges, Channels, Reducers)

Define directed agent graphs: add typed nodes (Runnables), channel-typed state slots with
reducer functions (LastValue, Append, BarrierValue, NamedBarrierValue, EphemeralValue,
BinaryOperatorAggregate), typed edges including conditional edges, and Send API for
dynamic fan-out.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-graph` LangGraph StateGraph engine,
BSP scheduling, Send API fan-out, conditional edges.
**Anchor justification:** CAP-003 covers graph definition because the brief names StateGraph and
the LangGraph port as the P0 lead differentiator (D7).

### CAP-004: BSP Graph Execution with Deterministic Reducer Order

Execute a StateGraph via the Bulk-Synchronous Parallel scheduling model: in each super-step,
all scheduled PregelTasks execute; then all channel reducers apply in deterministic
task-identity-sorted order. Concurrent writes to the same LastValue channel raise
InvalidUpdateError rather than silently racing.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-graph` BSP scheduling with
deterministic reducer order (CONFLICT-1/NE-17/D17); brief §Scope "BSP scheduling with
deterministic reducer order (CONFLICT-1/NE-17)."
**Anchor justification:** CAP-004 covers BSP execution because it is the execution model the
brief mandates by name, tracing to CONFLICT-1 and D17 HYBRID outcome.

### CAP-005: Durable Three-Tier Checkpointing (Sync Default; Per-Task put_writes)

Persist graph state at three durability tiers — sync (crash-safe default, writes before
returning), async (background), exit-only — using per-task `put_writes` so each PregelTask's
output is stored before the next super-step begins. Checkpoint IDs use a monotonic logical
clock, not wall-clock. Backends: SQLite (default), in-memory; msgpack wire format [D11.2].
Postgres stretch target.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-checkpoint` three-tier durable
checkpointing, per-task put_writes (CONFLICT-2/D11.3/D17-Q3), monotonic logical-clock
checkpoint IDs (CONFLICT-4), msgpack wire format [locked: D11.2], SQLite + in-memory
backends [locked: D11.3].
**Anchor justification:** CAP-005 covers three-tier checkpointing because the brief names
it explicitly and D11.3 locks the three-tier model with sync default. Domain B
dark-factory multi-day runs cannot function without this.

### CAP-006: HITL Interrupt / Resume with FIFO Resume-Value Delivery

Pause graph execution at any node boundary via `interrupt()`. Persist the interrupted
state durably. Accept one or more resume values externally (human decision, approval
command, or correction). Deliver resume values in strict FIFO order to the interrupted
node, which re-executes from the start of its super-step with the resume value available.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-graph` full HITL interrupt/resume
contract per CONFLICT-3/D17-Q2: "per-task scratchpad, FIFO resume-value delivery,
node-re-executes-from-start, Command(resume=value) API."
**Anchor justification:** CAP-006 covers HITL because it is explicitly named as a Phase-1 BC
in D17-Q2 and the brief states "cannot be retrofitted post-graph-design." Both Domain A
(risk-tiered approval gates) and Domain B (pipeline approval gates) force this.

### CAP-007: Structured Streaming Event Taxonomy

Emit typed per-phase streaming events: run_start / run_stream / run_end, step_start /
step_end, node_start / node_stream / node_end, tool_start / tool_stream / tool_end,
guardrail_decision (Fail/Transform outcomes only; Pass is not streamed — F-P99-01,
interface-definitions §StreamEvent v2.34) — 12-variant base; extended to 15 by D23
(CAP-034 events 13-14 tool-approval, CAP-035 event 15 compaction) — each carrying a
run_id, parent_ids chain, and phase-specific payload. Streaming and unary runs drive
the same engine and produce identical final answers.

**Grounding:** product-brief.md §Scope Wave 1 — `ferrochain-server` streaming and unary run
equivalence (NE-13/D17), CONFLICT-5 typed per-phase event taxonomy. Brief §Scope "streaming
and unary run equivalence (NE-13/D17)."
**Anchor justification:** CAP-007 covers structured streaming because NE-13 (streaming stub
must not exist) and CONFLICT-5 (typed taxonomy) are both named in the brief's scope section.

### CAP-008: Text Splitting with Code-Point Boundary Correctness

Split documents into chunks that respect the configured chunk size as a count of Unicode
code points (not bytes), with configurable overlap. On non-ASCII text, chunk boundaries
must be identical to the reference LangChain Python implementation (which also uses
code-point counts, not byte counts). Provide explicit test vectors for emoji and CJK inputs.

**Grounding:** product-brief.md §Scope Wave 0 — `ferrochain-splitters` with "explicit BC for
code-point vs byte-length boundary parity on non-ASCII input (R8/D17-Q9)."
**Anchor justification:** CAP-008 covers splitters because the brief names R8 as a High risk
and D17-Q9 mandates it as a Phase-1 BC backlog item. The code-point/byte-length distinction
is explicitly called out by name.

---

## P0 — Cross-Cutting: Budget, Security, and Error Taxonomy (D17-Elevated; Wave 0/1)

> D17-Q4, D17-Q8, and D17 CONFLICT-6 mandated these capabilities as Phase-1 BCs with all
> constituent BCs at P0 in the PRD (§2.10, §2.11, §2.14). They were previously grouped under
> `capabilities-p1-p2.md` as P1 in the "Wave 2" section. ADV-P1D-PASS-21 (F-P21-01) found
> this was a capability-tier ↔ BC-priority cross-doc mismatch. Relocated here and elevated to P0.

### CAP-012: Budget Governance (Allow / Escalate / Deny; Cost Metering)

Evaluate token and cost consumption per run and per sub-agent against a composable
BudgetPolicy (allow / escalate / deny). Record every evaluation in an append-only
EvidenceJournal. When the ceiling is reached, degrade gracefully: halt the run, escalate
to a HITL interrupt, or issue a final summarize call (summary_halt), according to the budget
configuration's `on_ceiling` setting (`BudgetConfig::on_ceiling` — `OnCeiling::Halt | Escalate | Summarize`).

**Grounding:** product-brief.md §Scope cross-cutting — Phase-1 BC backlog D17-Q4: "budget
governance allow/escalate/deny policy trait, composable, append-only evidence journal —
Domain B dark-factory holdout requires it."
**Anchor justification:** CAP-012 covers budget governance because D17-Q4 explicitly mandates
it as a Phase-1 BC, and the domain-b-dark-factory holdout cannot evaluate without it.
**D17-elevation note:** Elevated to P0 by D17-Q4 — constituent BCs P0, wave 1 (SS-10,
ferrochain-graph). Domain B dark-factory holdout requires this capability for Phase-1
evaluation; it cannot be deferred to Wave 2.

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
**D17-elevation note:** Elevated to P0 by D17-Q8 — constituent BCs P0, wave 1 (SS-11,
ferrochain-graph). Domain A SOC analyst holdout requires this capability for Phase-1
evaluation; it cannot be deferred to Wave 2.

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
**D17-elevation note:** Elevated to P0 by D17 CONFLICT-6/NE-07 — constituent BCs P0, wave 0
(SS-14, ferrochain-core). All security BCs across every subsystem depend on this error model;
it is a Wave-0 foundational primitive, not a Wave-2 optional capability.
