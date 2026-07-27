---
document_type: adr
level: L3
adr_id: "007"
slug: crate-topology-sdk-split
title: "Crate Topology and SDK Split for Provider Crates (D17-Q5)"
status: accepted
producer: architect
date: "2026-07-14"
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D1, D6, D13, D17, D21, D23]
subsystems_affected: [SS-01, SS-02, SS-03, SS-04, SS-05, SS-06, SS-07, SS-08, SS-09, SS-10, SS-11, SS-12, SS-13, SS-14, SS-15, SS-16, SS-17, SS-18, SS-19, SS-20, SS-21, SS-22, SS-23]
supersedes: ~
superseded_by: ~
version: "1.3"
changelog:
  - "1.3 (FIX-BURST-276/2026-07-27): F-B276-01: Fix live-body roster trap — section heading, derivation blockquote, and total line now state 21 published as current count at every reading position. Authoritative label relocated to point at ARCH-INDEX.md §Canonical Crate Roster as source of truth; D7 original 18-crate derivation preserved as historical record under D7 original derivation label. No table rows changed; Forward Amendment blockquote unchanged."
  - "1.2 (FIX-BURST-265/2026-07-25): F-P163-05: Add forward-amendment note (18-crate table reflects original D7; expanded to 21 by D21+D23; ARCH-INDEX is SoT). Fix Consequences R6: 18→21 crates. Add template compliance sections (Rationale, Alternatives Considered, Source / Origin). Add D21/D23 to decisions list."
  - "1.1 (burst-81/2026-07-14): Revised: decision changed to standalone crates per ADV-P1D-PASS-3 F-P3-02; modules-not-crates moved to Alternatives Considered. Roster expanded to full 18."
  - "1.0 (burst-80/2026-07-14): Initial ADR — decision was modules-not-crates."
---

# ADR-007: Crate Topology and SDK Split

**Status:** Accepted — revised per ADV-P1D-PASS-3 F-P3-02 to align with D17-Q5 and BC-2.08.006.

## Context

D17-Q5 specifies standalone SDK crate split for partner crates: each provider ships as two
**separate Cargo crates** — `ferrochain-<provider>-sdk` (standalone typed client, no
ferrochain-core dep) and `ferrochain-<provider>` (adapter — implements `BaseChatModel`).
BC-2.08.006 is the behavioral contract; it mandates separate Cargo workspace members with
enforced separation via `cargo check -p ferrochain-<provider>-sdk` (no ferrochain-core in
the dependency graph).

## Scope

This ADR covers: how provider crates are structured, what the SDK vs adapter crate boundary
is, and the full Cargo workspace crate roster (18 crates at original decision, derived from
D6 + D1 + D13 + P2-05 + ADR-008 + D17-Q5; since expanded to 21 by D21+D23 — see
ARCH-INDEX.md §Canonical Crate Roster as source of truth).

## Rationale

Three forces drive the two-crate SDK split:

1. **BC-2.08.006 enforcement requirement.** The behavioral contract mandates `cargo check -p ferrochain-<provider>-sdk` succeeds without ferrochain-core appearing in the dependency graph. This postcondition cannot be satisfied by module-level feature-flag isolation: `cargo check` on a single crate resolves all features in its Cargo.toml workspace context, so a feature-gated `dep:ferrochain-core` would still appear in the lock file under default workspace resolution. Only a crate boundary creates the hard dependency exclusion that TV-001 requires.

2. **Independent publishability and usability.** SDK crates (`ferrochain-openai-sdk`, etc.) are standalone wire clients publishable and usable without any ferrochain runtime. Users who only need a typed OpenAI API client should not pull the ferrochain-core + graph + checkpoint dependency tree.

3. **Clean dependency direction.** The adapter crate (outer layer) depends on the core (inner layer), never the reverse. Embedding SDK code inside a core-dependent crate would invert this relationship and contaminate the standalone client with LangChain semantics.

## Decision: Two-Crate Architecture for Provider Providers (D17-Q5)

Each provider is split into two **independent Cargo crates**:

**Crate pair (example: OpenAI):**

```
ferrochain-openai-sdk/        ← standalone wire client (no ferrochain-core dep)
  Cargo.toml                  ← deps: reqwest, serde, serde_json only
  src/
    lib.rs
    client.rs                 ← typed reqwest client for OpenAI API
    types.rs                  ← OpenAI request/response types
    streaming.rs              ← SSE parsing

ferrochain-openai/            ← Runnable adapter (depends on core + sdk)
  Cargo.toml                  ← deps: ferrochain-core, ferrochain-openai-sdk
  src/
    lib.rs
    chat_model.rs             ← impl BaseChatModel for ChatOpenAI
    translate.rs              ← ferrochain-core types ↔ provider wire format
    error.rs                  ← SdkError → FerrochainError mapping
```

**Enforced separation:**

- `ferrochain-<provider>-sdk/Cargo.toml` MUST NOT list `ferrochain-core` in `[dependencies]`
  or `[dev-dependencies]`. CI check: `cargo check -p ferrochain-<provider>-sdk` must
  succeed without ferrochain-core in Cargo.lock for that package.
- No feature flag can cause ferrochain-core to appear as a transitive dep of the SDK crate.
- Translation logic (ferrochain-core types ↔ wire format) lives exclusively in the adapter
  crate (BC-2.08.006 EC-003).

**Why two crates, not modules:** BC-2.08.006 mandates `cargo check -p ferrochain-<provider>-sdk`
succeeds without ferrochain-core. This separation cannot be enforced by Cargo at the module
level — only the crate boundary creates the required dependency isolation. Module-level
separation via feature flags cannot satisfy BC-2.08.006 TV-001 (Cargo.lock check). See
Alternatives Considered below.

## Full Crate Roster (D7 original: 18 published; current: 21 published — ARCH-INDEX.md §Canonical Crate Roster is source of truth)

> **D7 original derivation (18 published at initial decision):** D6 base (9) + D1 (mcp, standard-tests) + D13 (server)
> + P2-05 (sandbox, memory) + ADR-008 (macros) + D17-Q5 (3 × -sdk) = 18 published at original decision.
> **Authoritative current count: 21 published + xtask (D21 +2, D23 +1). Source of truth: ARCH-INDEX.md §Canonical Crate Roster.**
> (See Forward Amendment below for expanded roster derivation.)

| # | Crate | Origin | Description |
|---|-------|--------|-------------|
| 1 | ferrochain | D6 | Re-export facade (optional; convenience) |
| 2 | ferrochain-core | D6 | Core traits, types, error taxonomy |
| 3 | ferrochain-graph | D6 | StateGraph BSP engine, HITL, budget, provenance |
| 4 | ferrochain-checkpoint | D6 | Durable checkpointing, monotonic clock |
| 5 | ferrochain-openai | D6+D17-Q5 | OpenAI adapter crate (`impl BaseChatModel`) |
| 6 | ferrochain-anthropic | D6+D17-Q5 | Anthropic adapter crate |
| 7 | ferrochain-ollama | D6+D17-Q5 | Ollama adapter crate |
| 8 | ferrochain-community | D6 | [post-v1; community integrations; not in-tree at v1] |
| 9 | ferrochain-splitters | D6 | Unicode text splitting |
| 10 | ferrochain-mcp | D1 | MCP tool adapter |
| 11 | ferrochain-standard-tests | D1 | Conformance test suite |
| 12 | ferrochain-server | D13 | Axum HTTP server (threads/runs/schedules) |
| 13 | ferrochain-sandbox | P2-05 | WASM/container sandboxed tool execution |
| 14 | ferrochain-memory | P2-05 | Long-horizon memory (`MemoryStore` trait) |
| 15 | ferrochain-macros | ADR-008 | Proc-macro crate (#[tool], #[entrypoint], #[task]) |
| 16 | ferrochain-openai-sdk | D17-Q5 | OpenAI standalone wire client (no ferrochain-core dep) |
| 17 | ferrochain-anthropic-sdk | D17-Q5 | Anthropic standalone wire client |
| 18 | ferrochain-ollama-sdk | D17-Q5 | Ollama standalone wire client |

**Not published:** `xtask` (workspace binary), `ferrochain-community` (post-v1, placeholder only).
**Total at D7 decision:** 18 published + xtask. **Current total: 21 published + xtask** — see Forward Amendment below and ARCH-INDEX.md §Canonical Crate Roster (source of truth).

> **Forward Amendment (FIX-BURST-265, 2026-07-25):** The 18-crate table above reflects the
> original D7 decision. The roster has since expanded to **21 published crates** by D21
> (+ferrochain-prompts [#19], +ferrochain-vectorstores [#20]) and D23 (+ferrochain-tools
> [#21]). The derivation formula is now: D6 (9) + D1 + D13 + P2-05 + ADR-008 + D17-Q5
> (3×-sdk) + D21 (+prompts, +vectorstores) + D23 (+tools) = 21 published.
> **See ARCH-INDEX.md §Canonical Crate Roster as the authoritative source of truth.**

## Consequences

- `ferrochain-standard-tests` dev-depends on each adapter crate (ferrochain-openai etc.).
- `ferrochain-macros` is re-exported from `ferrochain-core` via `pub use ferrochain_macros::*`.
- The re-export facade `ferrochain` is optional; users can depend on individual crates.
- Provider SDK crates (`*-sdk`) have no ferrochain-core dep and are standalone usable.
- R6 namespace reservation: publish-all.sh must cover all 21 crates. Time-sensitive.

## Alternatives Considered

### Alternative A: Modules-Not-Crates (feature-flag isolation)

Each provider would contain two internal Rust modules (`sdk/` and `adapter/`) within a
single crate, with a Cargo feature flag `ferrochain-adapter = ["dep:ferrochain-core"]`
to conditionally compile the ferrochain-core dependency.

**Arguments for:** Zero additional crates.io namespace overhead, no inter-crate local path
dependency headaches during workspace development, simpler CI matrix (fewer crates to test).

**Rejected because:** BC-2.08.006 requires `cargo check -p ferrochain-<provider>-sdk`
to succeed without ferrochain-core in the dependency graph (TV-001). Feature-flag
conditional compilation does not satisfy this: `cargo check` on a single crate resolves
all features declared in that crate's Cargo.toml workspace context. The crate boundary
is the only Cargo mechanism that enforces hard dependency exclusion. This alternative
violates BC-2.08.006 postcondition 1 and EC-003 (translation logic must not live in the
SDK crate, but module colocation makes this harder to enforce).

## Source / Origin

| Source | Role |
|--------|------|
| D17-Q5 | Stakeholder decision mandating standalone SDK crate split for all provider pairs |
| BC-2.08.006 | Behavioral contract defining the postcondition (`cargo check -p *-sdk` must succeed without ferrochain-core) and enforcement mechanism (TV-001 Cargo.lock check) |
| ADV-P1D-PASS-3 F-P3-02 | Adversarial finding that identified the original modules-not-crates approach as insufficient to satisfy BC-2.08.006 TV-001; triggered revision to two-crate architecture |
| D21 | Ecosystem-parity scope expansion (2026-07-20): added ferrochain-prompts (#19) and ferrochain-vectorstores (#20) to the workspace roster |
| D23 | Scope expansion (2026-07-22): added ferrochain-tools (#21), promoted ferrochain-memory to Wave 1 |

