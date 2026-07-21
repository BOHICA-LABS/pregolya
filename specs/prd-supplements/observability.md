---
document_type: prd-supplement-observability
level: L3
version: "1.0"
status: active
producer: product-owner
timestamp: 2026-07-21T00:00:00Z
phase: 1d
changelog:
  - "1.0 (F-P130-06/2026-07-21): Initial Canonical Structured Event Catalog created. Census: grep `event_type =` across all of .factory/specs/behavioral-contracts/ and .factory/specs/architecture/. Total: 2 distinct event_type values found. SAP-1 standing probe policy stated. New emission sites require a same-commit catalog row per SAP-1 (CLAUDE.md §Standing Adversary Probes)."
inputs:
  - .factory/specs/behavioral-contracts/ss-22/BC-2.22.002.md
  - .factory/specs/behavioral-contracts/ss-09/BC-2.09.003.md
input-hash: "6aea537"
---

# Canonical Structured Event Catalog

## SAP-1 Policy — New Emission Sites Require Same-Commit Catalog Row

Per CLAUDE.md §Standing Adversary Probes (SAP-1):

> For EVERY adversarial pass on stories or PRs touching `crates/**/*.rs`:
> 1. Grep `event_type =` across the entire `crates/` workspace: `rg 'event_type\s*=' crates/ --type rust`
> 2. For each `event_type` value found, verify a corresponding row exists in this catalog with full field schema, audit role, and recurrence policy.
> 3. Tracing emission WITHOUT a catalog row = **P1 finding**.
> 4. Same-commit catalog row required for emissions added in the branch.
> 5. Removal of an emission does NOT require a new catalog row.

**Every implementer adding a `tracing::*!(event_type = "...")` call to any `crates/` file MUST add a corresponding row to this catalog in the same commit.**

---

## Census Methodology

The catalog was seeded by grepping `event_type` across all BC files and architecture docs:

```bash
grep -r "event_type" .factory/specs/behavioral-contracts/ .factory/specs/architecture/
```

**Total distinct `event_type` values found: 2**

---

## Catalog

| event_type | Log Level | Emitting Crate / Module | Emitting BC | Trigger Condition | Field Schema | Audit Role | Recurrence Policy |
|------------|-----------|------------------------|-------------|-------------------|--------------|------------|-------------------|
| `embeddings.legacy_model_warning` | `WARN` | `ferrochain-openai` / `openai::embeddings` | BC-2.22.002 PC3, EC-002 | `EmbeddingsOpenAI` constructed with model name `"text-embedding-ada-002"` (superseded legacy model) | `event_type: &str`, `model: &str` (= `"text-embedding-ada-002"`) | Warn operator/user that a legacy embedding model was selected; the ada-002 model is still supported by OpenAI but superseded by the 3-series (`text-embedding-3-small`, `text-embedding-3-large`). Enables proactive migration planning. | Once per `EmbeddingsOpenAI` construction — NOT once per API call. Multiple calls on the same instance do not re-emit. |
| `ferrochain.mcp.guardrail.unregistered` | `WARN` | `ferrochain-core` / guardrail dispatch layer (called from `ferrochain-mcp`) | BC-2.09.003 PC4, EC-002 | MCP tool result from a server enters the model context pipeline and no `GuardrailHook` is registered in the `InvocationContext` (default-permit path per OQR-5) | `event_type: &str`, `server_name: &str`, `tool_name: &str` | Security observability: signals that a tool result entered model context without guardrail evaluation. Operators consuming audit logs can detect unguarded MCP ingress paths and apply guardrail hooks. This is the default-permit-with-WARNING behavior mandated by OQR-5. | Per MCP tool invocation that enters the no-guardrail code path. High-frequency if the application consistently lacks a GuardrailHook — this is intentional (the WARNING repetition motivates hook registration). |

---

## Catalog Table: Field Schema Details

### `embeddings.legacy_model_warning`

```rust
tracing::warn!(
    event_type = "embeddings.legacy_model_warning",
    model = %model_name,  // = "text-embedding-ada-002"
    "legacy embedding model selected; consider upgrading to text-embedding-3-small or text-embedding-3-large"
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"embeddings.legacy_model_warning"` |
| `model` | `&str` (Display) | The legacy model name; currently always `"text-embedding-ada-002"` |

### `ferrochain.mcp.guardrail.unregistered`

```rust
tracing::warn!(
    event_type = "ferrochain.mcp.guardrail.unregistered",
    server_name = %server_name,
    tool_name = %tool_name,
    "tool result from '{server}/{tool}' entered model context without guardrail check"
);
```

| Field | Type | Description |
|-------|------|-------------|
| `event_type` | `&'static str` | Always `"ferrochain.mcp.guardrail.unregistered"` |
| `server_name` | `&str` (Display) | The MCP server name from the InvocationContext |
| `tool_name` | `&str` (Display) | The MCP tool name from the CallToolResult |

---

## Adding a New Emission Site

When adding a new `tracing::*!(event_type = "...")` call in any `crates/` file:

1. Choose a `event_type` string following the reverse-DNS naming convention (e.g., `ferrochain.<subsystem>.<event>`).
2. Add a row to this catalog table in the SAME commit, with:
   - All field names and types
   - The emitting BC anchor (cite the BC ID and the precondition/postcondition that mandates the emission)
   - The audit role (why does an operator need this event?)
   - The recurrence policy (once per construction? per call? per invocation?)
3. A PR with a new `event_type` emission but no corresponding catalog row will be blocked by SAP-1 as a P1 finding in adversarial review.
