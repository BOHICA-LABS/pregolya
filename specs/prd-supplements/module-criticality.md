---
document_type: prd-supplement-module-criticality
level: L3
version: "1.8"
status: superseded
producer: product-owner
timestamp: 2026-07-26T00:00:00Z
phase: 1a
superseded_by: .factory/specs/module-criticality.md
changelog:
  - "1.8 (F-P172b-19+F-P172b-11/burst-275/2026-07-26): Two stale-metadata findings closed. (1) F-P172b-19 LOW: frontmatter `architect_note` field carried unsatisfiable obligation 'Architect must confirm crate-to-subsystem mapping and fill Architecture Module column after producing ARCH-INDEX.md' — ARCH-INDEX.md has existed since 2026-07-13 and this file was superseded at Phase 1b; replaced with discharged-obligation note. (2) F-P172b-11 MED (partial): SUPERSEDED banner hardcoded '(43 modules, Phase 1b)' count — registry has grown past 43 since the file was superseded; count pin removed and routed to §Classification Summary per de-pin discipline. Historical '43 modules' mentions in changelog rows 1.5 and 1.6 are not corrected (immutable audit trail per TD-VSDD-091)."
  - "1.7 (F-P170-11/burst-272/2026-07-25): Deleted wrong parenthetical tier count from SUPERSEDED banner per F-P170-11. Banner stated 'CRITICAL 9 / HIGH 18 / MEDIUM 14 / LOW 2 = 43 total' — carried pre-D21/D23 CRITICAL count (9 vs authoritative 11) and wrong MEDIUM (14 vs authoritative 12) while summing to the correct total of 43, making it invisible to self-sum arithmetic checks. Deletion preferred over correction per TD-VSDD-091 spirit — the authoritative file owns the count."
  - "1.6 (FIX-BURST-268/F-P166-01/2026-07-25): TD-VSDD-091 compliance — removed stale version pin from SUPERSEDED banner. Banner line previously read '.factory/specs/module-criticality.md (v1.6, 43 modules, Phase 1b)'; vN.N pin violates TD-VSDD-091 (narrative body must not cite version numbers that decay on subsequent diffs). Fixed to '(43 modules, Phase 1b)'. Full body scan confirmed no other <file>.md (vN.N instances."
  - "1.5 (FIX-BURST-267/F-P165-06/2026-07-25): Adjudication — option (a) applied per single-source-of-truth discipline. This PO-draft (22 modules, pre-D21/D23) is superseded by the arch-view at .factory/specs/module-criticality.md (43 modules, v1.6, authoritative post-Phase 1b). Added STALE/SUPERSEDED banner at top of body. No content rows added — option (b) sync to 43 would duplicate authority. Downstream consumers (architect, test-writer, formal-verifier) must read .factory/specs/module-criticality.md. Status changed active→superseded."
  - "1.4 (2026-07-17): Provenance-integrity fix — removed .factory/STATE.md from inputs: list. STATE.md is a live pipeline-state file; input-hash drifts on every state write with zero spec-content signal for this supplement. Added three ADR files as genuine derivation inputs: ADR-008 (proc-macro #[tool]/#[entrypoint] tier-HIGH justification), ADR-012 (memory::write_guard tier-HIGH decision), ADR-013 (mcp::server tier-MEDIUM decision). D20/D17 decision references cited inline are stable baked-in facts, not live dependencies. Input-hash recomputed."
  - "1.3 (pass-72 fix, 2026-07-15): F-P72-03 — add D20 modules per gate #32 PO-registry carrier obligation. (1) memory::write_guard (pregolya-memory, HIGH) — ADR-012 Decision 4: calls validate() on every write; injection scanning dispatch; security-sensitive execution path. ADR-012 Decision 4 explicitly excludes memory::skills ('no independent execution logic beyond storage delegation') — no new row for skills module. (2) mcp::server (pregolya-mcp, MEDIUM) — pending ADR-013: MCP server tool advertisement and invocation; external client interface. pregolya-memory crate added to Module Inventory. Classification Summary updated: HIGH 8→9, MEDIUM 4→5, Total 20→22. Gate #25 Part B/C: tier and crate must agree with arch-registry module-criticality.md when that view is updated by architect this burst."
  - "1.2 (ADV-P1D-PASS-32): F-P32-02 fix Classification Summary MEDIUM cell: was 5 (wrong), actual MEDIUM rows = 4; corrected to 4, percentage updated 25%→20%; self-sum now 6+8+4+2=20 reconciles with stated total."
  - "1.1 (ADV-P1D-PASS-31): OBS-P31-1 add exclusion-criteria note (facade/re-export crates #1/#16/#17/#18 excluded; xtask classified as dev-tooling for CI gate); pregolya-macros (#15) DECISION — receives HIGH-tier row (not excluded) because #[tool]/#[entrypoint] proc-macros affect P0 tool-calling and graph-composition paths per ADR-008; add pregolya-macros to Module Inventory + HIGH row to classification table; update Classification Summary counts (HIGH 7→8, Total 19→20)."
inputs:
  - .factory/specs/prd.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/architecture/decisions/ADR-008-proc-macro-attributes.md
  - .factory/specs/architecture/decisions/ADR-012-self-improvement-primitives.md
  - .factory/specs/architecture/decisions/ADR-013-mcp-server-module-placement.md
input-hash: "73c8a33"
traces_to: prd.md
primary_consumers: [architect, test-writer, formal-verifier]
architect_note: "Obligation discharged — ARCH-INDEX.md produced 2026-07-13 at Phase 1b; crate-to-subsystem mapping and Architecture Module column populated by architect in authoritative file .factory/specs/module-criticality.md. This PO-draft is superseded and frozen."
---

# Module Criticality Classification: pregolya

> **SUPERSEDED — DO NOT USE FOR IMPLEMENTATION DECISIONS**
>
> This is the PO-draft module criticality file (22 modules, pre-D21/D23 scope, Phase 1a).
> It was superseded at Phase 1b by the architecture-view file produced by the architect:
>
> **Authoritative file:** `.factory/specs/module-criticality.md` (Phase 1b — see §Classification Summary for current tier counts)
>
> The authoritative file incorporates all D21 (prompts, vectorstores, embeddings, serialization,
> retrieval) and D23 (first-party tools, budget compaction, per-tool-call HITL) module additions,
> as well as the full VP host assignments (VP-001 through VP-013), correct wave assignments,
> (see `.factory/specs/module-criticality.md` §Classification Summary for the authoritative tier counts).
>
> This file is preserved for audit trail purposes only. Do not route implementation,
> test-writer, or formal-verifier work to this file.

## Tier Definitions

| Tier | Mutation Kill Rate Target | Description | Examples |
|------|--------------------------|-------------|----------|
| **CRITICAL** | ≥ 95% | Security boundaries, formal verification targets, durability invariants | BSP engine, checkpoint store, credential newtypes |
| **HIGH** | ≥ 90% | Core business logic, conformance contracts, server resource management | Provider trait impls, HITL engine, server handlers |
| **MEDIUM** | ≥ 80% | Supporting functionality with correctness requirements | Splitters, MCP adapter, sandbox utilities |
| **LOW** | ≥ 70% | Infrastructure, configuration, boilerplate | Build scripts, allowlist tooling, doc generation |

## Module Inventory

- **pregolya-core** — typed message/content primitives (Runnable, Message, ContentBlock), PregolyaError 2D struct, credential newtypes, CI lint targets
- **pregolya-graph** — StateGraph BSP execution engine, HITL interrupt/resume, channel reducers, budget governance, content provenance/guardrail seams
- **pregolya-checkpoint** — three-tier durable checkpointing, per-task put_writes, monotonic clock, checkpoint fork lineage, encryption at rest
- **pregolya-server** — HTTP server for threads/assistants/runs/crons, SecurityConfig, IdempotencyStore/RateLimitStore/RunStore traits
- **pregolya-mcp** — MCP tool adapter, tool discovery, ToolException fidelity, untrusted-ingress routing; MCP server role (`mcp::server` — tool advertisement via `tools/list`, invocation via `tools/call`; ADR-013)
- **pregolya-memory** — skill document registry (`memory::skills`), guarded memory/skill writes (`memory::write_guard`; injection scanning dispatch per ADR-012 Decision 4)
- **pregolya-openai** — OpenAI chat model implementation, streaming, tool-call, structured output
- **pregolya-anthropic** — Anthropic chat model implementation, streaming, tool-call
- **pregolya-ollama** — Ollama chat model implementation
- **pregolya-macros** — proc-macro crate providing `#[tool]` and `#[entrypoint]` procedural macros for tool registration and graph entry-point declaration (ADR-008)
- **pregolya-standard-tests** — conformance test suite crate (consumers: all provider crates)
- **pregolya-splitters** — text splitting with code-point boundary correctness
- **pregolya-sandbox** — WASM/container tool execution backend, workspace path confinement, macOS Seatbelt
- **pregolya-community** — demand-ranked integration crates (post-v1; third-party)
- **xtask** — cargo xtask workspace tooling (file-size gate, client-timeout lint, namespace reservation)

> **Exclusion criteria (OBS-P31-1, ADV-P1D-PASS-31):** Facade/re-export and codegen-thin
> crates (`pregolya` #1, `pregolya-openai-sdk` #16, `pregolya-anthropic-sdk` #17,
> `pregolya-ollama-sdk` #18) carry no criticality-bearing modules of their own and are
> intentionally excluded from the Module Classification table — they re-export from the
> implementation crates listed above and contain no independent logic paths. `xtask` is
> dev-tooling (not a published library crate) but is classified because its file-size-check
> logic gates CI — a failing xtask gate blocks all merges.
>
> **pregolya-macros (#15) — row vs. exclusion DECISION (OBS-P31-1):** Although
> `pregolya-macros` is codegen infrastructure, it carries real proc-macro logic
> (`#[tool]`, `#[entrypoint]`) per ADR-008. Because `#[tool]` generates the ToolDefinition
> plumbing consumed by all P0 tool-calling paths (BC-2.09.001, BC-2.09.002) and
> `#[entrypoint]` gates graph composition entry points, incorrect macro expansion silently
> corrupts P0 execution without a clear runtime error. DECISION: `pregolya-macros`
> receives a **HIGH**-tier criticality row; it is NOT excluded as a facade crate.

## Module Classification

| Module | Crate | Tier | Rationale | Kill Rate Target | VP Count |
|--------|-------|------|-----------|-----------------|---------|
| BSP execution engine | pregolya-graph | CRITICAL | DI-001 formal verification target; nondeterminism is a silent defect; CONFLICT-1 critical finding | ≥ 95% | 1 (VP-001) |
| HITL interrupt/resume | pregolya-graph | CRITICAL | D17-Q2 Phase-1 BC; cannot be retrofitted; Domain A+B holdout depends on correctness | ≥ 95% | 0 |
| Per-task checkpoint store | pregolya-checkpoint | CRITICAL | DI-002 durability invariant; Domain B multi-day run depends on crash recovery | ≥ 95% | 0 |
| Session tenancy layer | pregolya-checkpoint | CRITICAL | DI-005 Kani VP target; NE-12 cross-tenant isolation | ≥ 95% | 1 (VP-002) |
| PregolyaError + credential newtypes | pregolya-core | CRITICAL | NE-10 security boundary; DI-008 API contract; DI-010 credential opacity | ≥ 95% | 0 |
| Workspace path confinement | pregolya-sandbox | CRITICAL | DI-007 Kani VP target; NE-02 symlink escape; Domain C forcing function | ≥ 95% | 1 (VP-003) |
| Budget governance | pregolya-graph | HIGH | D17-Q4 Phase-1 BC; Domain B holdout; append-only journal integrity | ≥ 90% | 0 |
| Content provenance/guardrail | pregolya-graph | HIGH | D17-Q8 Phase-1 BC; Domain A holdout; DI-012 ingress coverage | ≥ 90% | 0 |
| Runnable trait dispatch | pregolya-core | HIGH | Universal composition primitive; type boundary enforcement | ≥ 90% | 0 |
| pregolya-server HTTP handlers | pregolya-server | HIGH | CRUD lifecycle correctness; SecurityConfig defaults (DI-013); streaming/unary equivalence | ≥ 90% | 0 |
| pregolya-openai | pregolya-openai | HIGH | Conformance contract; error-type fidelity; token-usage accounting | ≥ 90% | 0 |
| pregolya-anthropic | pregolya-anthropic | HIGH | Conformance contract; streaming correctness | ≥ 90% | 0 |
| pregolya-ollama | pregolya-ollama | HIGH | Conformance contract; local-first deployment | ≥ 90% | 0 |
| Proc-macro suite (#[tool], #[entrypoint]) | pregolya-macros | HIGH | ADR-008; `#[tool]` generates ToolDefinition plumbing for P0 tool-calling paths (BC-2.09.001, BC-2.09.002); `#[entrypoint]` gates graph composition; incorrect macro expansion silently corrupts P0 execution (OBS-P31-1) | ≥ 90% | 0 |
| MCP tool adapter (`mcp::client`) | pregolya-mcp | MEDIUM | ToolException fidelity (R11); untrusted ingress; correctness but not formal target | ≥ 80% | 0 |
| MCP server (`mcp::server`) | pregolya-mcp | MEDIUM | ADR-013 — tool advertisement (tools/list) + invocation (tools/call); external client interface; correctness but not formal target (BC-2.09.006, BC-2.09.007) | ≥ 80% | 0 |
| Write guard (`memory::write_guard`) | pregolya-memory | HIGH | ADR-012 Decision 4 — calls `validate()` on every memory/skill write; prompt-injection and invisible-Unicode scanning dispatch; security-sensitive execution path (BC-2.15.005) | ≥ 90% | 0 |
| pregolya-splitters | pregolya-splitters | MEDIUM | Code-point parity correctness (R8); isolated from graph runtime | ≥ 80% | 0 |
| Sandbox WASM/container backend | pregolya-sandbox | MEDIUM | Execution isolation important but DI-006 behavioral test covers the main case | ≥ 80% | 0 |
| pregolya-standard-tests | pregolya-standard-tests | MEDIUM | Test infrastructure; quality signal not production runtime | ≥ 80% | 0 |
| xtask tooling | xtask | LOW | Build tooling; correctness checked by CI itself | ≥ 70% | 0 |
| pregolya-community | pregolya-community | LOW | Third-party contributed post-v1; not in-tree at v1 | ≥ 70% | 0 |

## Per-Module Risk Assessment

| Module | Tier | Blast Radius | Security Sensitivity | Implementation Complexity | Test Priority |
|--------|------|-------------|---------------------|--------------------------|--------------|
| BSP execution engine | CRITICAL | high — all graph runs | low (correctness not security) | high | P0 |
| HITL interrupt/resume | CRITICAL | high — all HITL scenarios | medium (authorization gates in Domain A) | high | P0 |
| Per-task checkpoint store | CRITICAL | high — all durable runs | medium (encryption at rest) | high | P0 |
| Session tenancy layer | CRITICAL | high — multi-tenant isolation | high (cross-tenant data leak) | medium | P0 |
| PregolyaError + credentials | CRITICAL | medium — error observability | high (credential leak) | low | P0 |
| Workspace path confinement | CRITICAL | medium — tool execution | high (path traversal) | medium | P0 |
| Budget governance | HIGH | medium — Domain B runs | low | medium | P0 |
| Content provenance/guardrail | HIGH | high — Domain A safety | high (prompt injection) | medium | P0 |
| Runnable trait dispatch | HIGH | high — all crates depend on it | low | medium | P0 |
| Server HTTP handlers | HIGH | high — all server consumers | high (CORS, auth, debug routes) | medium | P1 |
| Provider crates (3) | HIGH | medium — each crate isolated | medium (credential handling) | low | P1 |
| MCP adapter | MEDIUM | medium | medium (untrusted ingress) | medium | P1 |
| Splitters | MEDIUM | low (isolated) | none | low | P0 (R8 correctness) |
| Sandbox backends | MEDIUM | medium | high (execution isolation) | high | P1 |
| Standard tests | MEDIUM | low | none | low | P1 |

## Classification Summary

| Tier | Module Count | Percentage |
|------|-------------|------------|
| CRITICAL | 6 | 27% |
| HIGH | 9 | 41% |
| MEDIUM | 5 | 23% |
| LOW | 2 | 9% |
| **Total** | **22** | ~100% |

*Note: Community crate and xtask excluded from active-development count; counted here for completeness. pregolya-macros added as HIGH row (OBS-P31-1). Facade/re-export crates (#1/#16/#17/#18) excluded per exclusion-criteria note above. v1.3 addition: memory::write_guard (HIGH, pregolya-memory) + mcp::server (MEDIUM, pregolya-mcp) per ADR-012/ADR-013 gate #32 PO-registry obligation.*

## Dependency Graph — Build Order

```
pregolya-core (foundation — no internal deps)
  └── pregolya-graph (depends on core)
  │   └── pregolya-checkpoint (depends on core; graph checkpoints)
  │       └── pregolya-server (depends on graph, checkpoint)
  └── pregolya-splitters (depends on core; isolated)
  └── pregolya-sandbox (depends on core)
  │   └── (pregolya-graph uses sandbox for tool execution)
  └── pregolya-<provider> (depends on core; standalone)
  │   └── pregolya-standard-tests (tests providers; depends on core + each provider)
  └── pregolya-mcp (depends on core; optional dep on providers)
```

## Implementation Priority Order

1. **pregolya-core** — all primitives (Runnable, Message, ContentBlock, PregolyaError); prerequisite for everything
2. **pregolya-splitters** — isolated; provides early Red Gate test coverage for R8
3. **pregolya-checkpoint** — per-task durability; prerequisite for pregolya-graph HITL
4. **pregolya-graph** — BSP engine, HITL, budget governance, content provenance
5. **pregolya-server** — HTTP layer; depends on graph + checkpoint
6. **pregolya-sandbox** — WASM/container backends; pregolya-graph depends on this for tool execution
7. **pregolya-openai** — first provider crate (D3 early integration priority)
8. **pregolya-anthropic** — second provider crate
9. **pregolya-ollama** — third provider crate
10. **pregolya-standard-tests** — conformance suite; requires provider crates
11. **pregolya-mcp** — MCP adapter; Wave 2; depends on core + providers

## Cross-Cutting Concerns by Tier

| Concern | CRITICAL modules | HIGH modules | MEDIUM/LOW modules |
|---------|-----------------|-------------|-------------------|
| Error handling | `PregolyaError` only; no `.unwrap()`/`.expect()` in lib code; all paths return `Result` | `PregolyaError` propagation; no silent errors | `PregolyaError` propagation acceptable |
| Credential handling | Newtype wrapper mandatory; `Debug → "<redacted>"`; no `Serialize`; no `Deref<Target=str>` | Newtype wrapper mandatory | Newtype if API key present |
| HTTP timeouts | Mandatory `.timeout(30s)` on all `ClientBuilder` | Mandatory `.timeout(30s)` | Strongly recommended |
| Test coverage | Kani proofs where VP seed; proptest for invariants; ≥ 95% mutation kill rate | Property tests for invariants; ≥ 90% mutation kill rate | Unit tests sufficient |
| File size | ≤ 500 lines soft / ≤ 750 hard | ≤ 500 lines soft / ≤ 750 hard | ≤ 500 lines soft / ≤ 750 hard |

## Anti-Patterns Explicitly Not to Port

> Greenfield project. These patterns come from the adk-rust negative evidence catalog (NE-01–NE-17).

- `Default::default()` delegating to a fallible constructor — **NE-07 REJECT**
- Bare `String` API keys with `#[derive(Debug)]` — **NE-10 REJECT**
- `reqwest::Client::new()` without `.timeout()` — **NE-04 REJECT**
- Default sandbox backend = no isolation (process execution) — **NE-01 REJECT**
- String-only workspace path safety without symlink resolution — **NE-02 REJECT**
- Streaming endpoint that emits task-state stubs without invoking engine — **NE-13 REJECT**
- `SecurityConfig::default()` with CORS wildcard and open debug route — **NE-14 REJECT**
- Encryption covering only state payloads but not event payloads — **NE-11 REJECT**
- Identity triple collapsing to bare `session_id` — **NE-12 REJECT**
- Per-tool retry keyed on args hash (non-terminating) — **NE-09 REJECT**
- Non-deterministic reducer fold via `buffer_unordered` — **NE-17 REJECT**
