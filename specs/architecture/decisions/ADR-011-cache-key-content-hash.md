---
document_type: adr
level: L3
adr_id: "011"
slug: cache-key-content-hash
title: "Cache-Key Content-Hash Contract (NE-05)"
status: accepted
producer: architect
timestamp: 2026-07-13T00:00:00Z
version: "1.0"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17]
ne_anchors: [NE-05]
supersedes: []
changelog:
  - "1.0 (D17/2026-07-13): Initial ADR — content-hash cache-key contract anchoring NE-05; prohibits description-proxy and partial-content cache keys."
---

# ADR-011: Cache-Key Content-Hash Contract

**Status:** Accepted — constrained by D17 NE adoption (NE-05)

## Context

NE-05 (from comparative analysis, P-17 evidence): the adk-rust runner keys its
context-cache on `agent.description()` as a self-described "reasonable proxy" for
system-instruction content. Concurrently, it passes an empty `HashMap::new()` as
the tools map at cache-key computation time (confirmed in `adk-runner::runner`
`build_context_cache_key` function body, CERTIFICATION-REPORT B-02).

This proxy approach creates two classes of correctness risk:

1. **Description-instruction divergence:** Two agents with identical descriptions but
   different resolved instructions produce the same cache key. Changed instruction bytes
   under a stable description can serve a stale cached response.

2. **Tool-definition invisibility:** Because tools are not part of the cache key, an
   agent whose tool list changes (new tool added, tool removed, schema updated) will
   receive cache hits scoped to the old tool set. An LLM may reference a tool that no
   longer exists or omit a newly registered tool.

The counter-example principle stated in NE-05: ferrochain prompt-caching MUST key on
a content hash of the fully resolved (instruction bytes, sorted tool declarations) —
never on a description proxy or on a partial subset of the content.

## Caching Surfaces in ferrochain

The following surfaces in the architecture involve cache-key computation and are
governed by this ADR:

| Surface | Crate | Cache-Key Input |
|---------|-------|-----------------|
| LLM provider response caching (prompt cache) | ferrochain-core / ferrochain-openai / ferrochain-anthropic / ferrochain-ollama | Content hash of: resolved system instruction bytes + sorted tool declaration bytes |
| Tool schema lookup / memoization | ferrochain-core / ferrochain-mcp | Content hash of: full serialized tool schema (name + description + input_schema) |
| Skill / compiled graph lookup (future) | ferrochain-graph | Content hash of: graph definition bytes |

If a new caching surface is introduced in any ferrochain crate, the implementer MUST
apply the hash-input contract defined in the Decision section and add a corresponding
CI lint exemption acknowledgment comment.

## Decision: Content-hash cache keys — full serialized content, not proxies

### Hash-Input Contract

A cache key MUST be derived as follows:

```
cache_key = hex(SHA-256(canonical_content_bytes))
```

Where `canonical_content_bytes` is the deterministic concatenation of:

1. **Resolved instruction bytes** — the fully-rendered system instruction after all
   template substitution, not the template string, not the agent description, not the
   agent name.
2. **Sorted tool declaration bytes** — each tool's serialized schema (name + description
   + input_schema JSON, canonicalized with keys in lexicographic order), sorted
   lexicographically by tool name, then concatenated. An empty tool list produces a
   zero-length contribution (not an error).

### What is PROHIBITED as a cache key

- `agent.description()` or any human-readable label as a standalone key
- Agent struct identity (pointer, ID, name) without content resolution
- Partial content (instruction without tools, or tools without instruction)
- Non-deterministic representations (HashMap iteration order, raw pointer bytes)

### Implementation Note

The `sha2` crate (already in the ferrochain dependency graph via adk-rust's
`content-addressed skill IDs` pattern, see `dependency-disposition.md` `sha2` row)
provides `Sha256`. Use `sha2::Sha256::digest(bytes)` and encode the result as a
lowercase hex string.

## Alternatives Considered

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| Description proxy (P-17 pattern) | REJECT | See NE-05 context: divergence and tool-invisibility risks. |
| Agent identity hash (struct ID / UUID) | REJECT | Identity does not change when instruction or tools change; stale cache risk survives object recreation in the same memory space. |
| Instruction-only hash (no tools) | REJECT | Tool set changes are invisible; cache hits can reference non-existent or stale tools. |
| Full message history hash | REJECT | Conversation history grows unboundedly; this would defeat caching entirely for multi-turn agents. Cache keys are computed over the STATIC configuration (instruction + tools), not over dynamic conversation state. |

## CI Lint Obligation

PRD §9 NE Disposition Table anchors NE-05 to this ADR with a CI lint gate obligation.
The lint gate implementation requirement:

- **Gate:** `cargo xtask deny-description-cache-key` (Semgrep rule or AST scan)
- **What it scans:** All `cache_key` / `CacheKey` / `cache_key_for` call sites in
  `ferrochain-*` library crates
- **Failure condition:** Any call site passes a description string, agent name, or
  other non-hash proxy as a cache key without a `#[allow(description_cache_key)]`
  suppression comment approved by an architect ADR review
- **Phase obligation:** Story implementing provider caching or skill-lookup caching
  MUST include the CI lint gate as an acceptance criterion, traceable to this ADR

The lint gate is the sole enforcement mechanism for NE-05 (no BC). Its existence is
declared here to give story-writer a concrete acceptance criterion anchor.

## BC and CI Anchors

| Anchor | Type | Reference |
|--------|------|-----------|
| NE-05 | Negative Evidence (comparative analysis) | PRD §9 NE Disposition Table; COMPARATIVE-ASSESSMENT.md NE-05 row |
| P-17 | Pattern (adk-rust, REJECT) | comparative/adk-rust/patterns-observed.md P-17; comparative/assessment-parts/part-1-dispositions-p01-p50.md |
| D17 NE adoption | Decision obligation | STATE.md D17 NE adoption commitment; all 17 NEs anchored in PRD §9 |
| CI lint gate | Enforcement | `cargo xtask deny-description-cache-key`; story acceptance criterion anchor |

No BC owns NE-05 (CI lint gate only, per PRD §9). This ADR is the authoritative
specification for the lint gate's semantic contract.

## Consequences

- All LLM provider caching implementations in ferrochain MUST compute cache keys per
  the hash-input contract above before any response is stored or retrieved.
- Tool schema memoization MUST include the full serialized schema in the hash input.
- The `sha2` crate becomes a direct (non-dev) dependency of `ferrochain-core`.
- Story-writer will anchor the cache-key lint gate story to this ADR (ADR-011) and to
  PRD §9 NE-05 row.
- Two agents with identical descriptions but different resolved instructions MUST produce
  different cache keys. This is a testable correctness invariant and SHOULD be an
  integration test in the story that implements provider caching.
