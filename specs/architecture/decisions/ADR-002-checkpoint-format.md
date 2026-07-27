---
document_type: adr
level: L3
adr_id: "002"
slug: checkpoint-format
title: "Checkpoint Wire Format: msgpack (Rust-native, non-Python-compatible)"
status: accepted
producer: architect
timestamp: 2026-07-14T12:00:00Z
version: "1.0"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D11]
supersedes: []
changelog:
  - "1.0 (D11/2026-07-14): Initial ADR — checkpoint wire format: msgpack via rmp-serde for ferrochain-checkpoint."
---

# ADR-002: Checkpoint Wire Format

**Status:** Accepted — D11.2 confirmed; msgpack decision finalized

## Context

The checkpoint store must serialize GraphState to a durable backend (SQLite, PostgreSQL).
LangGraph Python uses pickle (non-portable, Python-only). D11.2 decided RUST-NATIVE format.
Three candidates: JSON, msgpack, or bincode.

## Decision: msgpack via `rmp-serde`

**Chosen format:** msgpack (via `rmp-serde` crate, verified 1.3.1, 2026-01)

**Rationale:**
- Compact binary format (2-4x smaller than JSON for typical GraphState); important for soak-test durability and large checkpoints (Domain B multi-day runs).
- `rmp-serde` provides serde integration without custom derive; works with ferrochain's existing serde model.
- Self-describing format: field tags survive schema evolution (adding/removing optional fields) without a separate version header.
- Stable, widely-used format with implementations in all languages (relevant for the one-way Python-checkpoint import tool in scope).
- Faster serialization/deserialization than JSON for large payloads (benchmarks: ~3× on struct-heavy payloads).
- NOT Python pickle — no Python compatibility required per D11.2; one-way import tool handles legacy Python checkpoints separately.

**Rejected alternatives:**
- **JSON:** Human-readable but 2-4× larger; slower for large state payloads. Acceptable for HTTP responses but not checkpoint store.
- **bincode (2.0.1, 2025):** Faster than msgpack but not self-describing; schema evolution (adding fields)
  requires explicit version tagging because bincode does not encode field names. Both bincode 1.x (legacy)
  and bincode 2.0.1 (current stable, breaking rewrite of 1.x) share this limitation. REJECT.
- **postcard (1.1.3, 2026):** Designed for embedded/`no_std` use cases; compact but also
  not self-describing (encodes as positional fields). The same schema-evolution concern applies
  as with bincode. REJECT.

## Consequences

- `ferrochain-checkpoint` adds `rmp-serde = "1.3"` as a dependency (pin to 1.3.x for API stability).
- `GraphState` and `CheckpointMetadata` structs must implement `serde::Serialize + serde::Deserialize`.
- cargo-fuzz target `checkpoint_roundtrip` tests `serialize(x) |> deserialize == x` (BC-2.17.002).
- One-way Python-checkpoint import tool (separate crate, post-v1 stretch) reads pickle format and writes msgpack.
- HTTP responses use JSON (separate serialization path); msgpack is only for the checkpoint store.

## Scope

ADR-002 covers: checkpoint store wire format only.
Not covered: HTTP response format (always JSON), event streaming format (JSON for SSE).
