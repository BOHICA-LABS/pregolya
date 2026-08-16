---
document_type: adr
level: L3
adr_id: "023"
slug: non-exhaustive-governance
title: "#[non_exhaustive] Governance for Public API Types (fix-burst-287 / F-P176-A028 + A029 + D009 + B026 + C028)"
status: accepted
producer: architect
timestamp: 2026-08-16T00:00:00Z
date: "2026-08-16"
version: "1.4"
phase: 1b
traces_to: ARCH-INDEX.md
decisions: [D17, D21, D23]
subsystems_affected: ["all"]
supersedes: null
superseded_by: null
changelog:
  - "1.4 (burst-289/F-178-03+F-178-05/2026-08-16): Two findings closed. (F-178-03) Fix two phantom anchor citations: §Exempt Enums StreamEvent rationale and §Consequences both cited 'SS-06 §StreamEvent-Variants' — that heading does not exist in any SS-06 BC (variants live in BC-2.06.001 §Postconditions PC2, verified by heading grep). Both sites now cite 'BC-2.06.001 §Postconditions'. Both stale action-required directives updated to past tense: StreamEvent::Error was added to BC-2.06.001 §Postconditions (PC2) in burst-288 (v1.10). (F-178-05) Required Inventory enum header label corrected: '17 original + corpus-scan additions as of burst-288' was arithmetically misleading — '17 original' does not match the actual pre-burst-288 count of 12 (11 D17/D21/D23 table rows + TemplateInput). New label: '12 pre-burst-288 + 6 burst-288 D-03 additions = 18 total; 17 table rows below + TemplateInput'. Arithmetic totals unchanged (confirmed correct by adversary)."
  - "1.3 (burst-288/F-P177-A02+D-02+D-03+B01/2026-08-15): Four HIGH findings from P1D-177 closed. (A02) Fix Decision 4 heading and §Rationale: heading renamed from 'Required inventory and BC-2.22.001 compile-fail gate scope' to 'Required Inventory and compile-fail gate scope' — the old heading incorrectly implied BC-2.22.001 IS the gate scope document; §Rationale paragraph that read 'The compile-fail gate (BC-2.22.001) is the enforcement mechanism' was false (no gate exists yet) and replaced with accurate statement. (D-02) ToolCallPreview verified in Required Inventory; product-owner cross-owner routing note added to confirm #[non_exhaustive] attribute presence in interface-definitions.md. (D-03) Expand type inventory by 22 missing public types discovered in corpus-wide scan: 6 new Required enums, 3 new Exempt enums, 11 new Required structs, 2 new Exempt structs. Gate scope count updated from 20 to 37 Required Inventory types (18 enums + 19 structs). Exempt count updated from 6 to 11 (9 enums + 2 structs). (B01) StreamEvent governance resolved: EC-005 mandates terminal error SSE event requiring StreamEvent::Error as 16th variant; variant count updated 15 → 16; Exempt Inventory rationale updated noting Error variant must be added before Phase 3 implementation. Product-owner cross-owner routing note: add StreamEvent::Error variant to SS-06 §StreamEvent-Variants."
  - "1.2 (fix-burst-287/ADR-022-self-compliance/2026-08-01): Fix three phantom §citations that violated ADR-022 (restriction to real markdown headings). (1) Decision 4 struct note: removed 'BC-2.22.001 §compile-fail-gate text refers only to enums' — §compile-fail-gate is not a real heading anywhere in the BC corpus; restated as plain prose. (2) Gate update protocol step 3: removed 'Update BC-2.22.001 §compile-fail-gate' instruction — phantom heading citation; replaced with conditional prose. (3) Source/Origin D009: removed 'interface-definitions.md §public-API-enums' — no such heading exists in interface-definitions.md; public API enum declarations appear across the body of that document. (4) Rationale: correct 'five exempt enums' → 'six exempt enums' (BoundaryType added in v1.1)."
  - "1.1 (fix-burst-287/2026-08-01): Post-verification corrections. (1) A029 confirmed FALSE: BoundaryType does NOT carry #[non_exhaustive] per ADR-014 §Decision 6 body ('canonical 3-variant closed set, PASS-58 canon, not #[non_exhaustive]'); ADR-016 citation in the finding was wrong ADR. Add BoundaryType to Exempt Inventory (Criterion A). (2) C028 confirmed FALSE: BC-2.22.001 §compile-fail-gate does not exist anywhere in BC corpus (grep: zero hits). Removed false claim from Context and Consequences; replaced with accurate statement that no compile-fail gate exists and one must be created in Phase 3. (3) Correct ADR-016 → ADR-014 in A029 Affected-findings line."
  - "1.0 (fix-burst-287/F-P176-A028+A029+D009+B026+C028/2026-08-01): Initial decision — close Mechanism 4 (#[non_exhaustive] applied ad hoc). Establishes governing rule, exception criteria, and Exempt Inventory."
---

# ADR-023: #[non_exhaustive] Governance for Public API Types

**Status:** Accepted — fix-burst-287 architect adjudication of F-P176-A028, F-P176-D009, and F-P176-B026 from P1D-176 Mechanism 4. F-P176-A029 and F-P176-C028 were confirmed FALSE POSITIVE after post-initial verification (see v1.1 changelog); the governing-rule gap they cited was real, but their specific factual claims were not.

---

## Context

The `#[non_exhaustive]` attribute has been applied across pregolya's public API surface on an ad hoc basis: each type application was made independently with no governing ADR stating the rule, the exception criteria, or the exempt inventory. This produces three problems:

1. **Re-litigation at every type.** Every new public enum or struct requires the author to independently decide whether `#[non_exhaustive]` applies. Authors either apply it reflexively (possibly incorrectly) or skip it (possibly incorrectly).

2. **No authoritative exempt list.** Without a governing rule, there is no canonical answer to "which public types are intentionally exhaustive?" The adversary cannot distinguish a type that is correctly exhaustive from one that is incorrectly missing the annotation.

3. **No compile-fail gate exists for the Required Inventory.** There is currently no `tests/external/non_exhaustive_gate/` directory and no BC with a compile-fail gate verifying the full type inventory. Without a governing rule, Phase 3 implementers have no authoritative scope for the gate and no way to know which types to include. (F-P176-C028 claimed BC-2.22.001 §compile-fail-gate exists and is stale — post-verification: that section does not exist anywhere in the BC corpus. The root cause — no governing rule and no gate — is real, but the specific claim was false.)

Affected findings: F-P176-A028 (StreamEvent, ADR-006 — CONFIRMED), F-P176-A029 (BoundaryType, ADR-014 — FALSE: BoundaryType does not carry #[non_exhaustive]; see Exempt Inventory), F-P176-D009 (14-type roster in interface-definitions.md — CONFIRMED), F-P176-B026 (ContentBlock, BC-2.01.002 — CONFIRMED), F-P176-C028 (§compile-fail-gate section — FALSE: section does not exist; governing-rule gap was real).

---

## Decision 1 — Governing rule: all public API surface types MUST carry #[non_exhaustive]

Every `pub enum` and `pub struct` that is part of pregolya's published crate API surface MUST carry the `#[non_exhaustive]` attribute, **unless the type is listed in the Exempt Inventory (Decision 3)**.

**Rationale:** Pregolya is a library crate hierarchy. Adding a variant to a public enum or a field to a public struct is a breaking change for downstream crates under stable Rust without `#[non_exhaustive]` (enum matching requires `..`, struct construction requires all fields). Marking public types as non-exhaustive allows the library to evolve without forcing a major-version bump for every additive extension. This is Rust's designed escape hatch for library-side evolution.

**Scope:** "Published crate API surface" means any `pub` type in a crate that appears in the Canonical Crate Roster (ARCH-INDEX §Canonical Crate Roster) with Published = YES, excluding workspace binaries (xtask) and `pregolya-standard-tests`.

**Applies to both enums and structs.** `#[non_exhaustive]` on a struct prevents external crates from constructing it with a struct literal (E0639 compiler error). `#[non_exhaustive]` on an enum prevents external crates from exhaustively matching it without a wildcard arm (E0004 compiler error). Both capabilities must be reserved for the library.

---

## Decision 2 — Exception criteria: types eligible for exemption

A type MAY be exempted from the `#[non_exhaustive]` requirement if and only if it meets one of the following criteria. Both the criterion AND the explicit Exempt Inventory entry (Decision 3) are required for a type to be exempt — meeting a criterion alone is not sufficient.

**Criterion A — Closed protocol enum:** The type is an enum whose variant set is semantically closed by an external contract, standard, or fundamental algorithm — i.e., new variants are genuinely impossible or would constitute a protocol revision, not an additive extension. The exhaustive match at callsites is a feature (missing a new variant causes a compile error, which is correct behavior for a closed protocol).

**Criterion B — Internal or sealed type:** The type is not exposed as part of the public API surface — it is used only within the library internally, passed only between types in the same crate. Such types cannot be constructed or matched by downstream users regardless of `#[non_exhaustive]`.

**What does NOT qualify:**
- "We happen not to have more variants right now" does not qualify as Criterion A.
- "It's probably stable" does not qualify.
- "Adding variants would be rare" does not qualify.
- If there is any plausible reason the type could grow, it MUST carry `#[non_exhaustive]`.

---

## Decision 3 — Exempt Inventory

The following types are explicitly exempt from the `#[non_exhaustive]` requirement. Each entry states the governing criterion from Decision 2 and the rationale.

### Exempt Enums

| Type | Crate | Criterion | Rationale |
|------|-------|-----------|-----------|
| `StreamEvent` | pregolya-graph (via pregolya-core) | A | ADR-006 §Status explicitly states "Exhaustive match enforcement: any new variant added to `StreamEvent` causes compile errors at all match sites, making omissions impossible to ship undetected." Exhaustive matching is a design goal — consumer code that handles all events is structurally correct code. New events constitute a streaming protocol revision and require a version bump, not an additive extension. **Authoritative variant set: 16 variants including `StreamEvent::Error`.** EC-005 mandates a terminal error SSE event; `StreamEvent::Error` is the 16th variant. The exhaustive-match design goal is preserved — adding `Error` forces all consumers to handle the error path at compile time, which is the correct behavior. Completed: `StreamEvent::Error` was added to BC-2.06.001 §Postconditions (PC2) as the 16th variant in burst-288. |
| `MemoryScope` | pregolya-core | A | Three-tier storage partition (User/App/Session) is semantically closed. The storage-layer SQL WHERE predicate maps each variant to a distinct partition key. Adding a fourth scope tier would require a storage schema migration, not just a Rust additive extension. Callers that exhaustively match `MemoryScope` enforce correct partition routing — the compile error on variant addition is the desired behavior. |
| `WriteGuardDecision` | pregolya-core | A | Three-way protocol contract (Allow/Deny/Transform) for the MemoryWriteGuard hook. All three outcomes must be handled by the guard dispatch layer. Adding a fourth outcome would change the dispatch contract, not extend it. Missing a variant in the dispatch match is a logic error the compiler should catch. |
| `MemoryWriteRequest` | pregolya-core | A | Three-way write operation enum (Add/Replace/Remove). The write guard and memory store implementations must handle all three. The complete set of fundamental write operations is closed: Add, Replace, Remove covers the full CRUD-without-read surface. |
| `SlotTrustPolicy` | pregolya-prompts | A | Binary predicate (TrustAll/TrustRequired) representing whether a template slot accepts untrusted variables. The two variants map to a security binary: either the slot requires trusted input, or it does not. Adding a third variant would constitute a new security policy level — a protocol revision requiring new injection_guard logic. Construction-time exhaustive checking against slot assignments is correct behavior. |
| `BoundaryType` | pregolya-core (core::guardrail) | A | Canonical 3-variant closed set (ToolResult \| RAGRetrieval \| MemoryIngress) per PASS-58 canon and ADR-014 Decision 6. Explicitly documented as "not #[non_exhaustive]" in ADR-014 body. Every guardrail entry point must be classified; a missing match arm is a guardrail bypass (security regression). New ingress paths constitute protocol additions requiring explicit guardrail design, not additive extension. Authority: BC-2.11.001 through BC-2.11.004. Note: F-P176-A029 incorrectly claimed BoundaryType "carries #[non_exhaustive] without governing rule" — it does not carry the attribute; the exemption was ungoverned, which this entry corrects. |
| `IngressBoundary` | pregolya-core (core::guardrail) | A | Three-way ingress boundary classification (ToolResult \| RagChunk \| MemoryItem) defined by the guardrail protocol topology. Adding a fourth boundary requires a guardrail protocol change (a new ingress path), not an additive library extension. Exhaustive matching at dispatch sites enforces complete protocol coverage; a missing arm is a guardrail bypass. (burst-288, D-03) |
| `GuardrailDecisionKind` | pregolya-core (core::guardrail) | A | Binary Fail/Transform guardrail decision outcome. The guardrail result-dispatch protocol has exactly two non-Pass outcomes; adding a third kind would change the protocol semantics. Missing a branch is a security regression. The binary model maps directly to the SSE wire protocol for guardrail events. (burst-288, D-03) |
| `GuardrailSeverityWire` | pregolya-core (core::guardrail) | A | Four-tier wire severity (Critical \| High \| Medium \| Low) mapping to the SSE event protocol. New severity levels require SSE protocol revision; exhaustive matching at consumer sites enforces complete coverage. The four-tier model is an established security classification standard (CVSS-aligned). (burst-288, D-03) |

### Exempt Structs

| Type | Crate | Criterion | Rationale |
|------|-------|-----------|-----------|
| `GuardedDocuments` | pregolya-core (core::rag_ingress) | B | Tuple struct with private inner field (`Vec<Document>` declared without `pub`). External crates cannot construct it regardless of `#[non_exhaustive]`; callers receive `GuardedDocuments` only via `rag_ingress()` return value. Adding `#[non_exhaustive]` provides no additional protection beyond the private-field seal. (burst-288, D-03) |
| `RunnableSequence<I, O>` | pregolya-core | B | Generic pipeline composition type returned from `.pipe()`. External callers receive it as a result of calling API methods but cannot construct it (struct fields are private composition internals; the generic parameters are inferred by the compiler). Adding `#[non_exhaustive]` on this return-only type provides no protection beyond the private-field seal. (burst-288, D-03) |

---

## Decision 4 — Required Inventory and compile-fail gate scope

The types listed below constitute the **Required Inventory** — types that MUST carry `#[non_exhaustive]`. This is the authoritative scope for the compile-fail gate.

**Architect note to product-owner:** No compile-fail gate for the Required Inventory exists at this time. The gate directory `tests/external/non_exhaustive_gate/` does not exist; no BC specifies a §compile-fail-gate for this inventory. In Phase 2 (story decomposition), a BC should be authored for this gate. The Phase 3 implementer who creates the gate MUST cover the full Required Inventory at time of gate implementation. (F-P176-C028 claimed BC-2.22.001 §compile-fail-gate exists and is stale — this section was not found in BC-2.22.001 or any other BC.)

### Required Inventory (post-D23)

**Public enums with `#[non_exhaustive]` (12 pre-burst-288 + 6 burst-288 D-03 additions = 18 total; 17 table rows below + TemplateInput):**

| Type | Crate / Module | First introduced | BC anchor |
|------|---------------|-----------------|-----------|
| `Component` | pregolya-core | D17 (ADR-010) | BC-2.14.001 |
| `Category` | pregolya-core | D17 (ADR-010) | BC-2.14.001 |
| `RetryHint` | pregolya-core | D17 (ADR-010) | BC-2.14.001 |
| `ContentBlock` | pregolya-core | D17 | BC-2.01.002 |
| `ActionRisk` | pregolya-core::core::action_risk | D23 (ADR-020) | BC-2.05.006, BC-2.23.005 |
| `PreToolDecision` | pregolya-graph::graph::hitl | D23 (ADR-018) | BC-2.05.007 |
| `ToolOutput` | pregolya-core::core::tool | D23 (ADR-020) | BC-2.23.001–006 |
| `CompactionTrigger` | pregolya-core::core::budget | D23 (ADR-019) | BC-2.10.005 |
| `TrustLevel` | pregolya-prompts::injection_guard | D21 (ADR-015) | BC-2.18.004 |
| `SearchType` | pregolya-vectorstores | D21 (ADR-014) | BC-2.20.003 |
| `FilterClause` | pregolya-vectorstores | D21 (ADR-014) | BC-2.21.004 |
| `GuardrailResult` | pregolya-core (core::guardrail) | burst-288 (D-03) | — (Phase 2 BC) |
| `IngressContent` | pregolya-core (core::guardrail) | burst-288 (D-03) | — (Phase 2 BC) |
| `GuardrailSeverity` | pregolya-core (core::guardrail) | burst-288 (D-03) | — (Phase 2 BC) |
| `PolicyDecision` | pregolya-core (core::budget) | burst-288 (D-03) | — (Phase 2 BC) |
| `OnCeiling` | pregolya-core (core::budget) | burst-288 (D-03) | — (Phase 2 BC) |
| `Serialized` | pregolya-core (core::serializable) | burst-288 (D-03) | — (Phase 2 BC) |

**Note on TemplateInput:** `TemplateInput` (pregolya-prompts, ADR-015 §Decision 3 Amendment, fix-burst-279) carries `#[non_exhaustive]` and was added post-D21. It is part of the Required Inventory. Its late addition reflects the amendment history; it should be included in the compile-fail gate. Total confirmed non-exhaustive enums: **18** (including TemplateInput; 17 from this table + TemplateInput).

**Public structs with `#[non_exhaustive]` (19 as of burst-288):**

| Type | Crate / Module | First introduced |
|------|---------------|-----------------|
| `PregolyaError` | pregolya-core | D17 (ADR-010, F-P173-619) |
| `ProviderFallbackPolicy` | pregolya-core | D20 (ADR-012 / BC-2.08.014) |
| `Document` | pregolya-core::core::documents | D21 (ADR-014) |
| `MetadataFilter` | pregolya-vectorstores | D21 (ADR-014) |
| `PromptValue` | pregolya-prompts | D21 (ADR-015) |
| `MessageProvenance` | pregolya-prompts | D21 (ADR-015) |
| `ToolConfig` | pregolya-tools | D23 (ADR-020) |
| `ToolCallPreview` | pregolya-graph::graph::hitl | D23 (ADR-018) |
| `RunnableConfig` | pregolya-core | burst-288 (D-03) |
| `BudgetConfig` | pregolya-core (core::budget) | burst-288 (D-03) |
| `SkillDescriptor` | pregolya-memory | burst-288 (D-03) |
| `MemoryEntry` | pregolya-memory | burst-288 (D-03) |
| `ConversationSnapshot` | pregolya-core (core::budget) | burst-288 (D-03) |
| `CompactionSummary` | pregolya-core (core::budget) | burst-288 (D-03) |
| `ToolInput` | pregolya-core (core::tool) | burst-288 (D-03) |
| `VectorStoreRetriever` | pregolya-vectorstores | burst-288 (D-03) |
| `TemplateVar` | pregolya-prompts | burst-288 (D-03) |
| `LcEntry` | pregolya-core (core::serializable) | burst-288 (D-03) |
| `Reviver` | pregolya-core (core::serializable) | burst-288 (D-03) |

**Cross-owner routing (D-02):** `ToolCallPreview` is listed in this Required Inventory but the attribute MUST be verified present in interface-definitions.md. A corpus-wide scan (burst-288) confirms `ToolCallPreview` at the interface-definitions declaration site does NOT carry `#[non_exhaustive]`. Product-owner action required: add `#[non_exhaustive]` to `ToolCallPreview` in interface-definitions.md. This is a product-owner owned file; the architect records the gap here.

**Note:** Compile-fail gate for structs verifies that struct-literal construction fails (E0639) from external crates. When the product-owner authors the gate BC in Phase 2, the gate scope MUST cover both enums and structs — all 37 Required Inventory types (18 enums + 19 structs). Enums-only coverage would leave the struct prohibition unverified.

### Gate update protocol

When adding a new public type that meets the governing rule (Decision 1):
1. Add `#[non_exhaustive]` to the type at authoring time.
2. Add the type to this Exempt Inventory (if it meets an exemption criterion) OR to the Required Inventory above.
3. If a compile-fail gate BC exists for the Required Inventory, update it to include the new type. If the gate BC has not yet been authored, the new type will be included when the gate is created in Phase 2.
4. The Phase 3 implementer updates `tests/external/non_exhaustive_gate/` in the SAME commit that adds the type to the implementation.

The gate update protocol applies equally to new enums and new structs.

---

## Alternatives Considered

**Alternative 1 — Apply `#[non_exhaustive]` only to enums, not structs.**
Rejected. The production-grade default requires protecting all additive evolution surfaces. Adding a field to a public struct is a semver-breaking change for downstream code that constructs the struct with a literal (E0639). Pregolya library crates expose configuration structs (`RunnableConfig`, `BudgetConfig`, `ToolConfig`, etc.) that downstream callers construct; these structs will gain fields as the library evolves. Leaving struct construction unrestricted forces a major-version bump for every field addition.

**Alternative 2 — Use builder patterns instead of `#[non_exhaustive]` for structs.**
Rejected for Phase 1. Builder patterns are a valid design pattern for large configuration structs and are not mutually exclusive with `#[non_exhaustive]`. However, mandating builders for every struct at this stage would require architectural refactoring across all public configuration types before any implementation. The correct approach: apply `#[non_exhaustive]` now (low-effort, correct by default) and migrate specific structs to builders where the ergonomic benefit justifies it (future architecture decision per struct).

**Alternative 3 — Enumerate exempt types without a governing ADR; rely on case-by-case adversarial review.**
Rejected. This was the status quo before this ADR (ad hoc application) and produced the P1D-176 findings that drove ADR-023's creation. Case-by-case review has no authoritative scope, produces re-litigation at every new type, and cannot distinguish a correctly exhaustive type from a type that simply wasn't annotated. A governing rule with an explicit Exempt Inventory is the only mechanism that makes the distinction machine-verifiable.

---

## Rationale

The `#[non_exhaustive]` attribute is the Rust standard mechanism for library-side additive evolution. Its default application to all public API types is consistent with the following precedents in this codebase:
- CLAUDE.md Code Conventions: "`#[non_exhaustive]` on all public API surface types."
- ADR-010: applied to `PregolyaError` at F-P173-619 for exactly this reason.
- ADR-015 Decision 3 Amendment: applied to `TrustLevel` at F-P175-B208.

The Exempt Inventory (Decision 3) is small and principled: all nine exempt enums are closed by an external protocol contract or represent a fundamental operation set, where exhaustive matching is the correct behavior for downstream correctness. The two exempt structs (GuardedDocuments, RunnableSequence) are sealed by private fields regardless of `#[non_exhaustive]`, making the attribute redundant.

The Required Inventory is the authoritative scope definition for the compile-fail gate once authored. No compile-fail gate for the Required Inventory exists yet (no `tests/external/non_exhaustive_gate/` directory exists; no BC defines this gate — F-P176-C028's claim to the contrary was a false positive). This ADR supplies the scope that Phase 2 BC authorship requires. The assertion "BC-2.22.001 is the enforcement mechanism" was incorrect and has been removed (burst-288, A02).

---

## Consequences

- All new public API surface enums and structs in pregolya MUST carry `#[non_exhaustive]` at authoring time unless they appear in Decision 3.
- The nine exempt enums (StreamEvent, MemoryScope, WriteGuardDecision, MemoryWriteRequest, SlotTrustPolicy, BoundaryType, IngressBoundary, GuardrailDecisionKind, GuardrailSeverityWire) and two exempt structs (GuardedDocuments, RunnableSequence) correctly do NOT carry `#[non_exhaustive]`. Their absence is documented and justified in the Exempt Inventory.
- No compile-fail gate for the Required Inventory exists yet. A BC for `tests/external/non_exhaustive_gate/` must be authored in Phase 2. The gate MUST cover all 37 Required Inventory types (18 enums + 19 structs). The previous count of 20 types reflected only the initial D17/D21/D23 corpus sweep; burst-288 D-03 added 17 additional types identified via a full interface-definitions.md scan.
- Product-owner action required: add `#[non_exhaustive]` to `ToolCallPreview` in interface-definitions.md (D-02 routing note in Required Inventory struct table).
- Product-owner action completed: `StreamEvent::Error` added as the 16th variant to BC-2.06.001 §Postconditions (PC2) in burst-288 (EC-005 mandate fulfilled).
- Future capability additions (D24+) that introduce new public types MUST reference this ADR and follow the gate update protocol.

---

## Source / Origin

- **F-P176-A028** (MED) CONFIRMED: StreamEvent `#[non_exhaustive]` applied without governing ADR rule (ADR-006). Closed by Decision 3 Exempt Inventory entry.
- **F-P176-A029** (MED) FALSE POSITIVE: Claimed "BoundaryType carries `#[non_exhaustive]` without governing rule (ADR-016)." Verification: ADR-014 Decision 6 body explicitly states "BoundaryType — canonical 3-variant closed set (PASS-58 canon, not #[non_exhaustive])"; ADR-016 is LC JSON deserialization (wrong ADR cited). BoundaryType does NOT carry the attribute. The ungoverned exemption was real; closed by Decision 3 Exempt Inventory entry for BoundaryType.
- **F-P176-D009** (HIGH) CONFIRMED: public API enum declarations in interface-definitions.md (spread across the document body; no dedicated §public-API-enums heading exists) had no ADR governing rule, exceptions, or exempt inventory. Closed by this ADR.
- **F-P176-B026** (OBS) CONFIRMED: ContentBlock `#[non_exhaustive]` without governing rule (BC-2.01.002). Closed by Decision 4 Required Inventory (ContentBlock listed).
- **F-P176-C028** (MED) FALSE POSITIVE: Claimed "BC-2.22.001 §compile-fail-gate states 'verifies all 14 public enums.'" Verification: §compile-fail-gate section does not exist in BC-2.22.001 or anywhere in the BC corpus (grep: zero hits). The underlying gap (no gate, no governing scope) was real; addressed by Decision 4 gate note directing Phase 2 BC authorship.
- **CLAUDE.md Code Conventions:** "#[non_exhaustive] on all public API surface types."
- **ADR-006 §Status:** Exhaustive match enforcement for StreamEvent is a design goal.
- **ADR-010 F-P173-619:** `#[non_exhaustive]` added to PregolyaError — motivating precedent.
- **ADR-015 §Decision 3 Amendment:** `#[non_exhaustive]` added to TrustLevel at F-P175-B208.
