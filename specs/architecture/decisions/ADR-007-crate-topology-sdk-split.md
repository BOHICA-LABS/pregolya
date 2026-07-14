---
document_type: adr
level: L3
adr_id: "007"
slug: crate-topology-sdk-split
title: "Crate Topology and SDK Split for Provider Crates (D17-Q5)"
status: proposed
producer: architect
timestamp: 2026-07-14T12:00:00Z
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D6, D17]
---

# ADR-007: Crate Topology and SDK Split

**Status:** Proposed (D17-Q5; finalizable)

## Context

D17-Q5 specifies standalone SDK crate split for partner crates: each provider ships as
`ferrochain-<provider>-sdk` (standalone typed client with no ferrochain-core dep) plus
an adapter crate that bridges to `BaseChatModel`. BC-2.08.006 is the behavioral contract.

## Scope

This ADR covers: how provider crates are structured, what the SDK vs adapter boundary is,
and Cargo workspace topology for the 12-crate family.

## Decision: Two-Layer Architecture for Provider Crates

Each provider crate contains two internal modules rather than two separate crates:

**Module structure (example: ferrochain-openai):**

```
ferrochain-openai/
  src/
    lib.rs
    sdk/           ← standalone SDK layer (no ferrochain-core dep)
      client.rs    ← typed reqwest client for OpenAI API
      types.rs     ← OpenAI request/response types
      streaming.rs ← SSE parsing
    adapter/       ← ferrochain-core integration
      chat_model.rs ← impl BaseChatModel for OpenAIChatModel
      error.rs      ← OpenAI error → FerrochainError mapping
```

**Why modules instead of separate crates:** BC-2.08.006 spec says "standalone SDK crate split"
but the practical test is whether the SDK layer is usable without ferrochain-core. Using
Cargo modules achieves this separation with zero additional crates.io namespace overhead,
no inter-crate local path dependency headaches, and simpler CI. The SDK module is
conditionally compiled without ferrochain-core if used as a standalone dependency (feature flag).

**Cargo feature flag:**

```toml
[features]
default = ["ferrochain-adapter"]
ferrochain-adapter = ["dep:ferrochain-core"]
standalone-sdk = []  # SDK-only mode; no ferrochain-core dep
```

## Full Crate Roster (12 crates, D6)

| Crate | crates.io name | Description |
|-------|----------------|-------------|
| ferrochain | ferrochain | Re-export facade (optional; convenience) |
| ferrochain-core | ferrochain-core | Core traits, types, error |
| ferrochain-graph | ferrochain-graph | StateGraph BSP engine |
| ferrochain-checkpoint | ferrochain-checkpoint | Durable checkpointing |
| ferrochain-server | ferrochain-server | HTTP server |
| ferrochain-splitters | ferrochain-splitters | Text splitting |
| ferrochain-sandbox | ferrochain-sandbox | Sandboxed tool execution |
| ferrochain-openai | ferrochain-openai | OpenAI chat model |
| ferrochain-anthropic | ferrochain-anthropic | Anthropic chat model |
| ferrochain-ollama | ferrochain-ollama | Ollama chat model |
| ferrochain-standard-tests | ferrochain-standard-tests | Conformance test suite |
| ferrochain-mcp | ferrochain-mcp | MCP tool adapter |

Note: `xtask` is a workspace binary, not published. `ferrochain-community` is post-v1.

## Name Reservation Status

crates.io names verified available (R6 in risk register). Human must run `cargo login` +
`publish-all.sh` to reserve names before any public announcement. This is time-sensitive.

## Consequences

- `ferrochain-standard-tests` depends on each provider crate as a dev-dependency.
- The re-export facade `ferrochain` is optional; users can depend on individual crates.
- Provider crate SDK modules can be used standalone (no LangGraph runtime required).
