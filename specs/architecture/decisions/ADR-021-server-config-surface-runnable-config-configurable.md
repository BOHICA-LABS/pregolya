---
document_type: adr
level: L3
adr_id: "021"
slug: server-config-surface-runnable-config-configurable
title: "SecurityConfig TOML Representation and RunnableConfig.configurable Field (fix-burst-283 / F-P175-C101 + F-P175-C113)"
status: accepted
producer: architect
timestamp: 2026-07-30T00:00:00Z
version: "1.0"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D13]
changelog:
  - "1.0 (fix-burst-283/F-P175-C101+F-P175-C113/2026-07-30): Initial decision — two adjudications from P1D-175 Slice C1. Decision 1: SecurityConfig TOML representation — resolve mutual unbootability between BC-2.12.005 EC-005 and the interface-definitions.md sample config. Decision 2: RunnableConfig.configurable field addition — resolve BC-2.12.002 fabricated-capability finding (mislabeled as BC-2.12.005 by adversary; actual defect in BC-2.12.002)."
---

# ADR-021: SecurityConfig TOML Representation and RunnableConfig.configurable Field

**Status:** Accepted — fix-burst-283 architect adjudication of F-P175-C101 (CRIT) and F-P175-C113 (HIGH) from P1D-175 Slice C1.

---

## Context

Two open findings from adversarial pass P1D-175 Slice C1 were never routed or closed. Both turn on the correct shape of the server configuration surface and the `RunnableConfig` type boundary. They share a root cause: the architecture documents describing these two surfaces are internally inconsistent. Per CLAUDE.md §Companion Principle, the adjudication of both findings is architect scope; the BC body edits that follow are product-owner scope.

### Finding F-P175-C101 (CRIT) — debug_route_key mutual unbootability

BC-2.12.005 EC-005 makes `Some("")` (an empty-string `debug_route_key`) a fatal startup error (`E-SERVER-013 InvalidDebugRouteKey`). The `interface-definitions.md` sample TOML config declares `debug_route_key = ""` with the comment "empty string = debug routes disabled (SECURE DEFAULT)". These are mutually exclusive: under serde's standard `Option<String>` deserialization, a present TOML key with value `""` deserializes to `Some("")`, which BC-2.12.005 EC-005 defines as an unconditional startup failure. If BC-2.12.005 governs, the shipped sample config makes the server unbootable. If the TOML comment governs, EC-005/TV-007/E-SERVER-013 are unreachable dead code and the empty-key guard can never fire.

### Finding F-P175-C113 (HIGH) — RunnableConfig fabricated capabilities

The adversary attributed this finding to `BC-2.12.005 §Description` but the text it quotes — "model, tools, system prompt overrides, checkpointer config" — does not appear in BC-2.12.005. It appears in `BC-2.12.002 §Description`:

> "An Assistant is a named, versioned configuration record that binds a `graph_id` to a specific runtime config (model, tools, system prompt overrides, checkpointer config) and optional context."

BC-2.12.002 PC1 types the `config` field as `RunnableConfig`. The canonical `RunnableConfig` struct (defined in `interface-definitions.md`) has exactly four fields: `recursion_limit`, `thread_id`, `budget_config`, `context_mutations`. None can express model selection, tool bindings, or system-prompt overrides. The "reusable agent persona" purpose stated in BC-2.12.002 §Description is architecturally incoherent under the current `RunnableConfig` definition.

**Adversary mislabeling note:** F-P175-C113's stated file `BC-2.12.005` is incorrect. The actual defect site is `BC-2.12.002`. No change to BC-2.12.005 is warranted for finding C113.

---

## Decision 1 — SecurityConfig TOML representation: absent field, not empty string

**Chosen:** The shipped sample TOML config must represent "debug routes disabled" as the **absence** of the `debug_route_key` key — not as `debug_route_key = ""`.

The Rust field type `Option<String>` maps to TOML as follows under serde's default deserialization:
- Key absent from config file → serde produces `None` → debug routes disabled (SECURE DEFAULT)
- Key present as non-empty string → serde produces `Some(key)` → debug routes enabled with key gate
- Key present as empty string (`debug_route_key = ""`) → serde produces `Some("")` → E-SERVER-013 startup failure (BC-2.12.005 EC-005 / TV-007)

The sample TOML in `interface-definitions.md` must therefore show the `debug_route_key` key as **commented out**, not as an empty-string value. BC-2.12.005 EC-005 and TV-007 remain load-bearing: they guard against an operator who accidentally includes `debug_route_key = ""` in a live config file (which would otherwise silently strip the gate without the operator realising the route was accessible).

### Rationale

1. **BC-2.12.005 is the authoritative contract.** The BC's EC-005 design — reject `Some("")` at startup — is a valid security invariant: an empty string cannot gate anything, so it must never be treated as a "disabled" sentinel at the type level. The TOML *representation* must be consistent with the Rust type, not override it.
2. **TOML absent key is the correct serde idiom for `Option<T>` defaults.** `#[serde(default)]` or the `Option<T>` type's inherent default (`None`) means absence and `None` are semantically equivalent. This is standard Rust practice.
3. **E-SERVER-013 remains reachable.** A user who explicitly writes `debug_route_key = ""` in their config file receives a clear startup error. This is a useful guard against misconfiguration — the route effectively gets disabled by operator mistake, but the mistake is caught loudly rather than silently. "Disabled by empty key" is operationally indistinguishable from "never configured" to a caller, but leaves no visible evidence that someone intended to configure the route. The startup error makes the intent explicit.

### Effect on existing artifacts

- `interface-definitions.md` §Sample TOML Config: change `debug_route_key = ""` to commented form `# debug_route_key = "your-secret-here"` with updated comment.
- BC-2.12.005: no change to body content required. EC-005, TV-007, E-SERVER-013, and all invariants are already correct under this decision.
- E-SERVER-013 startup-only omission note in `interface-definitions.md` §HTTP Status Table: phrasing "debug_route_key must be non-empty when debug routes are enabled" remains accurate.

---

## Decision 2 — Add `configurable: Option<HashMap<String, Value>>` to `RunnableConfig`

**Chosen:** Add a `configurable: Option<HashMap<String, Value>>` field to `RunnableConfig`.

This is the LangGraph-parity field identified in the semport analysis (semport §RunnableConfig mapping §11). LangGraph's Python `RunnableConfig` carries a `configurable: dict` that graphs inspect at runtime to read model, tool-set, system-prompt, and other graph-specific overrides. Without this field, the ferrochain `RunnableConfig` cannot carry the per-graph runtime configuration that makes the Assistant's "reusable agent persona" concept realizable.

### Rationale

1. **Semport mandate.** The semport `rust-translation-strategy.md §RunnableConfig mapping §11` explicitly includes `configurable: Map<String,Value>` in the proposed `RunnableConfig` struct. This field was omitted from the initial architecture phase without a recorded decision.
2. **LangGraph parity is the design requirement.** BC-2.12.002 §Description states the Assistant concept is LangGraph-parity (D13). LangGraph `Assistants` store a `configurable` dict keyed to graph-specific parameter names (e.g., `"model"`, `"system_prompt"`, `"tools"`). The graph reads its parameters from `config.configurable` at execution time. Without `configurable`, ferrochain graphs have no standard channel for receiving per-run model or system-prompt overrides that differ from graph to graph.
3. **Preserves typed-field precedent.** The strongly-typed fields `budget_config` and `context_mutations` cover ferrochain-specific behaviors that require precise type-level enforcement. The `configurable` map covers the "pass-through to graph logic" use case where each graph defines its own parameters — a generic map is correct here because no single graph schema applies across all graphs.
4. **No `#[non_exhaustive]` conflict.** `RunnableConfig` is not currently declared `#[non_exhaustive]` (the struct's internal use makes that impractical; callers construct it). Adding a new `Option<…>` field is a backward-compatible extension — existing construction sites using struct-literal form add the field as `configurable: None`.

### Type details

```rust
pub configurable: Option<HashMap<String, serde_json::Value>>,
```

- `None` (default): no graph-specific overrides; graph uses its built-in defaults.
- `Some(map)`: graph inspects specific keys. Key names are graph-defined and unvalidated by the framework at `RunnableConfig` construction time — validation is graph-internal.
- Merge semantics (BC-2.12.003 §Run-Config Merge Precedence Invariant): when a Run request supplies a `config.configurable` map, it is deep-merged over the Assistant's stored `configurable` map at the key level, with run-level keys winning on collision. Merge is applied at run-creation time.

### Effect on existing artifacts

- `interface-definitions.md` §RunnableConfig: add `configurable` field with doc comment.
- `api-surface.md` §ferrochain-core Public Types `RunnableConfig` row: add `configurable` to the field summary.
- BC-2.12.002 §Description: product-owner must replace the fabricated list with language reflecting what `RunnableConfig.configurable` actually carries (see §Product-Owner Handoff below).
- BC-2.12.004 §Invariants: product-owner must remove the fabricated field reference `RunnableConfig.missed_fire_policy` (discovered in TD-VSDD-060 sibling sweep; this field does not exist in `RunnableConfig`).

---

## Alternatives Considered

| Alternative | Disposition | Rationale |
|-------------|-------------|-----------|
| Decision 1: Keep `debug_route_key = ""` in TOML; change Rust type to `String` (treat empty = disabled) | **REJECT** | Removes E-SERVER-013 / EC-005 / TV-007 as meaningful; the empty-string-means-disabled sentinel is operationally ambiguous. BC-2.12.005 is the security contract; the TOML representation must conform to the Rust type, not override it. |
| Decision 1: Keep empty-string default; treat it as `None` in a custom deserializer | **REJECT** | Non-standard serde behavior; the standard `Option<String>` deserialization is unambiguous. Custom deserializers add complexity and maintenance surface for no behavioral gain over the absent-key pattern. |
| Decision 2: Separate `AssistantConfig` struct (typed fields: `model`, `tools`, `system_prompt`) | **REJECT** | Breaks LangGraph parity: LangGraph's `configurable` map is deliberately untyped because different graphs use different keys. A typed `AssistantConfig` would require every graph to know the ferrochain-server schema, inverting the dependency. The generic map is correct; graph logic owns key validation. |
| Decision 2: Keep `RunnableConfig` as-is; fix BC-2.12.002 §Description to say "execution parameters only, no model/tools" | **REJECT** | The Assistant's "reusable agent persona" concept has no mechanism without `configurable`. The semport mandate was clear. Accepting the fabrication as a spec correction without adding the missing field leaves ferrochain unable to implement LangGraph-parity Assistants. |

---

## Consequences

### interface-definitions.md changes

1. §RunnableConfig struct: add `configurable: Option<HashMap<String, Value>>` field with doc comment.
2. §Sample TOML Config: change `debug_route_key = ""` to the commented form `# debug_route_key = "your-secret-here"`.

### api-surface.md changes

- §ferrochain-core Public Types: `RunnableConfig` row description updated to include `configurable`.

### BC handoff to product-owner (do not edit BC files)

See §Product-Owner Handoff section in the fix-burst-283 adjudication record. The two sites requiring product-owner action are:

1. **BC-2.12.002 §Description** — replace "model, tools, system prompt overrides, checkpointer config" with accurate description per Decision 2.
2. **BC-2.12.004 §Invariants** — remove or replace the fabricated `RunnableConfig.missed_fire_policy` reference.

### VP changes

No VP changes required. VP-SEC-01 and VP-SEC-02 (anchored in BC-2.12.005) are unaffected by either decision.

---

## BC Anchors

| BC | Relevance |
|----|-----------|
| BC-2.12.005 | Authoritative source for `debug_route_key` gate behavior; EC-005/TV-007/E-SERVER-013 validated and unchanged by Decision 1 |
| BC-2.12.002 | "Reusable agent persona" concept; config field typed as `RunnableConfig`; product-owner must update §Description per Decision 2 |

---
