---
document_type: adr
level: L3
adr_id: "007"
slug: crate-topology-sdk-split
title: "Crate Topology and SDK Split for Provider Crates (D17-Q5)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D1, D6, D13, D17]
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
is, and the full Cargo workspace crate roster (18 crates, derived from D6 + D1 + D13 +
P2-05 + ADR-008 + D17-Q5). See also ARCH-INDEX.md §Canonical Crate Roster.

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
Rejected Alternatives below.

## Full Crate Roster (18 published crates + xtask)

> **Authoritative.** Derivation: D6 base (9) + D1 (mcp, standard-tests) + D13 (server)
> + P2-05 (sandbox, memory) + ADR-008 (macros) + D17-Q5 (3 × -sdk) = 18 published.
> See also ARCH-INDEX.md §Canonical Crate Roster (source of truth).

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
**Total in workspace:** 18 published + xtask.

## Consequences

- `ferrochain-standard-tests` dev-depends on each adapter crate (ferrochain-openai etc.).
- `ferrochain-macros` is re-exported from `ferrochain-core` via `pub use ferrochain_macros::*`.
- The re-export facade `ferrochain` is optional; users can depend on individual crates.
- Provider SDK crates (`*-sdk`) have no ferrochain-core dep and are standalone usable.
- R6 namespace reservation: publish-all.sh must cover all 18 crates. Time-sensitive.

## Rejected Alternatives

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

## Changelog

| Date | Change | Authority |
|------|--------|-----------|
| 2026-07-14 (burst 80) | Initial ADR — decision was modules-not-crates | architect |
| 2026-07-14 (burst 81) | Revised: decision changed to standalone crates per ADV-P1D-PASS-3 F-P3-02; modules-not-crates moved to Rejected Alternatives. Roster expanded to full 18. | architect, ADV-P1D-PASS-3 F-P3-02 |
