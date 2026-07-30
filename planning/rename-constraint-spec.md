---
artifact: planning/rename-constraint-spec
document_type: planning
stage: rename-stage-1
version: "1.0"
created: 2026-07-30T00:00:00Z
author: business-analyst
purpose: >
  Stage 1 of a two-stage naming exercise. Recovers D6 criteria, enumerates hard
  constraints that the original study left unexamined, and generates a candidate
  shortlist grouped by positioning strategy. Stage 2 (research-agent) performs
  live availability checks before any name is presented to the human.
inputs:
  - .factory/planning/naming-decision-study.md
  - .factory/specs/architecture/ARCH-INDEX.md
  - .factory/namespace-reservation/
input-hash: "pending"
---

# Rename Constraint Specification — Stage 1

**Context:** The human has decided to rename the library. The rename executes as
burst 284. The motivation has not been stated; candidates are grouped by
positioning strategy so the shortlist stays useful for any motivation the human
confirms. This document reads the D6 evidence and extends it; it does not repeat
what the original study covered in depth. Stage 2 availability checks are
delegated to research-agent.

---

## Part A — D6 Criteria Recovery

### Scoring Criteria Applied

The naming-decision-study.md scored candidates on five criteria (1–5 scale, 5 = best):

| Criterion | What it measured |
|-----------|-----------------|
| Legal / trademark risk | Probability of enforcement action by LangChain Inc.; lower risk = higher score |
| Namespace completeness | Ability to claim all required crate names on crates.io without blocking gaps |
| Discoverability / adoption | Capture of brand-literal search queries (e.g., "langchain rust") |
| Identity / differentiation | Distinctness from competing Rust LLM projects |
| Long-term flexibility | Independence from LangChain Inc.'s roadmap; ability to coexist with a future official SDK |

### Candidates Evaluated

The study evaluated Option 1 (langchain-*-rs prefix family) versus Option 2 (distinct
brand). Within Option 2, four candidates received full namespace verification:

| Candidate | Disposition |
|-----------|-------------|
| `ferrochain` | Selected — verified clean: base crate, core crate, GitHub org |
| `cogflow` | Viable alternate — ML-space "CogFlow" prior art noted but not deep-researched |
| `graphweave` | Viable with caveat — GitHub org handle registered-but-empty at check time |
| `agentflow` | Rejected — `agentflow-core` already taken on crates.io |

Additional candidates (`rustchain`, `linkforge`, `chainforge`, `weaver`, `synapse`,
`relay`, `lattice`, `cascade`) were eliminated at first-pass collision check.

### Why ferrochain Won

`ferrochain` is the only candidate with a verified-clean full namespace: base crate,
`ferrochain-core`, and `github.com/ferrochain` org were all available at check time.
Three compounding advantages:

- **Semantics**: `ferro` (Latin: iron) directly signals Rust (the language is named for iron oxidation). No borrowed trademark morpheme.
- **Zero software collision**: a targeted web search for "ferrochain LLM Rust" surfaced no existing project.
- **Score**: 23/25 vs. Option 1's 14/25. The only below-maximum criterion was discoverability (3/5), mitigated by keyword tagging and functional-query positioning.

### Criteria Left Unexamined in D6

The original study did not assess:

1. **Prefix-ability under a 21-crate roster.** At D6 time the roster was 9 crates. The study noted partner crates would carry the prefix but did not stress-test awkward members. The roster has since grown to 21 published crates with suffix lengths up to 16 characters.
2. **The `-chain` morpheme specifically.** The study analyzed the "LANGCHAIN" compound mark but did not separately assess whether `-chain` as a suffix creates brand association or semantic mismatch with the library's actual architecture (graph-based, not chain-based).
3. **Rust-idiom fit** — `use` statement clarity, Cargo.toml key ergonomics, feature flag verbosity.
4. **Cross-ecosystem collisions** beyond crates.io and GitHub: specifically PyPI and npm.
5. **Pronounceability.** The study tested web-search collision but not phonetic distinctiveness.

### Candidates That Would Score Differently Now

- **`cogflow`**: the ML "CogFlow" prior art was noted as "possible minor." If that project has grown, it scores lower on collision. Stage 2 must deep-check.
- **`graphweave`**: the empty GitHub org handle may now be claimed. Stage 2 must re-verify.
- Neither change alters the relative standing from D6; they are relevant only if the human wants to revisit those specific alternates.

---

## Part B — Hard Constraints for the New Name

### B-1: Prefix-Ability Across 21 Crates

**The roster.** The canonical 21-crate roster ratified in ARCH-INDEX.md §Canonical Crate
Roster (origin: D6 base + D1 + D13 + D21 + D23) produces the following suffix family. Every
suffix must read naturally when appended to the new prefix:

| Suffix | Example full name | Chars |
|--------|------------------|-------|
| (facade) | ferrochain | 10 |
| -core | ferrochain-core | 15 |
| -graph | ferrochain-graph | 16 |
| -checkpoint | ferrochain-checkpoint | 21 |
| -openai | ferrochain-openai | 17 |
| -anthropic | ferrochain-anthropic | 20 |
| -ollama | ferrochain-ollama | 17 |
| -community | ferrochain-community | 20 |
| -splitters | ferrochain-splitters | 20 |
| -mcp | ferrochain-mcp | 14 |
| **-standard-tests** | **ferrochain-standard-tests** | **26** |
| -server | ferrochain-server | 17 |
| -sandbox | ferrochain-sandbox | 18 |
| -memory | ferrochain-memory | 17 |
| -macros | ferrochain-macros | 17 |
| -openai-sdk | ferrochain-openai-sdk | 21 |
| **-anthropic-sdk** | **ferrochain-anthropic-sdk** | **24** |
| -ollama-sdk | ferrochain-ollama-sdk | 21 |
| -prompts | ferrochain-prompts | 18 |
| **-vectorstores** | **ferrochain-vectorstores** | **23** |
| -tools | ferrochain-tools | 16 |

**Hard limits derived from this table:**

**Length ceiling.** crates.io enforces a 64-character maximum. The longest suffix
is `-standard-tests` (15 chars). Maximum permissible prefix: 64 − 1 (hyphen) − 15 = 48
characters. No practical brand name approaches this limit; it is not a real constraint.

**Awkwardness test on the three longest full names.** A new prefix P must produce
legible readings for `P-standard-tests`, `P-anthropic-sdk`, and `P-vectorstores`. Any
name that creates semantic redundancy or an awkward consonant cluster in these three
forms fails the test.

**Semantic redundancy rule.** If the prefix contains a word that also appears as a
roster suffix, the compound becomes awkward. The affected suffixes are `-graph`,
`-core`, `-server`, `-memory`, `-tools`, `-macros`. Concretely: any name containing
"graph" produces `<name>-graph` where the word "graph" appears twice. Names
eliminated by this rule: `ferrograph`, `nexusgraph`, `graphweft`, `stategraph`.

**Snake-case readability.** Rust imports use underscores. The critical readings are:

```
use <name>_core::...;
use <name>_standard_tests::ProviderConformance;
use <name>_anthropic_sdk::AnthropicClient;
```

With a 7-character prefix (e.g., `trellis`): `trellis_standard_tests` — 22 characters,
readable. With a 10-character prefix: `ferrochain_standard_tests` — 25 characters,
still readable. The practical readability soft limit is a prefix under 14 characters.

**Summary: any name under 14 characters that does not contain a roster-suffix word
is prefix-able. The 21-crate roster imposes no blocking hard constraint but eliminates
candidate names whose stems repeat the words graph, core, server, memory, tools,
or macros.**

### B-2: Trademark Posture Toward LangChain

> **Risk assessment only — not legal advice.**

**The LANGCHAIN mark.** LangChain Inc. has a USPTO word-mark application on file for
"LANGCHAIN" (class: downloadable software, filing date 2023-06-08; serial number
documented in naming-decision-study.md §LangChain Inc. trademark posture). Registration
status was unconfirmable from public sources at D6 time; treat as at minimum an
applied-for plus common-law mark. No enforcement actions against community ports
(`langchain4j`, `langchaingo`, `langchain-rust`) were documented in the D6 study.

**The `-chain` morpheme analysis.**

The word mark "LANGCHAIN" covers the compound, not the morpheme `-chain` in isolation.
Using `-chain` in a different compound does not constitute use of the mark. However
two distinct costs apply:

1. **Brand association without benefit.** Both "LangChain" and "ferrochain" share
   the `-chain` suffix and operate in the same domain. Users mentally associate the
   names. This is brand-confusion distinct from trademark infringement, but it
   anchors ferrochain's identity to LangChain's brand equity — equity the project
   cannot control and may not benefit from as LangChain evolves.

2. **Semantic mismatch.** LangChain deprecated "chains" as its central abstraction
   in v1, moving to graph-based execution (LangGraph). This library is a behavioral
   port of that graph architecture: BSP super-steps, channel-based state, durable
   checkpointing, HITL interrupt/resume. None of these concepts are "chains." The
   `-chain` morpheme accurately describes LangChain v0.1's architecture, not this
   library's architecture.

**Assessment.** The `-chain` morpheme carries real cost — brand entanglement plus
semantic inaccuracy — while providing no offsetting benefit. A rename that drops
`-chain` eliminates both the association risk and the mismatch. This constraint is
additive to D6's analysis.

### B-3: Ecosystem Collision Surface

A new name must be clear across four namespaces. Stage 2 (research-agent) performs
live availability checks; this section defines the required scope:

| Namespace | Check required | Notes |
|-----------|---------------|-------|
| crates.io | Primary — all 21 crate names must be available | crates.io normalizes `-` and `_` to the same name; checking `<name>` also covers `<name>_` |
| GitHub org `github.com/<name>` | Required — org needed for the project home | An existing org with no repos/members may be reclaimable; an active org is blocking |
| PyPI `pypi.org/project/<name>` | Required — AI library names cross language ecosystems; a prominent PyPI package creates confusion for engineers who use both | |
| npm `npmjs.com/package/<name>` | Required — same cross-ecosystem concern | |
| Rust LLM / agent crate space | Advisory — check for similar names in the llm, agent, rag, nlp keyword space | Prominent incumbents: `rig`, `swiftide`, `kalosm`, `langchain-rust`, `langgraph` (Onelevenvy) |

**Known collision risk patterns to avoid:**
- Any name already taken on crates.io in the Rust ecosystem
- Any name used by a prominent non-Rust AI tool (examples: Vellum AI, ChainForge, Conduit CDC, WeaveWorks, Loom)
- Names overloaded in unrelated high-traffic domains (Relay, Nexus, Lattice, Prism, Beacon) — search results are swamped

### B-4: Rust-Idiom Fit

A name reads correctly in Rust if it satisfies five conditions:

1. **`use` statement clarity.** `use <snake_name>_core::message::HumanMessage;` is unambiguous.
   Names that create identical or near-identical import paths to well-known crates fail.

2. **Cargo.toml dependency keys.** `<name>-core = { version = "...", path = "..." }`.
   Compound names produce verbose but valid keys; no hard limit is imposed by Cargo.

3. **Feature flag notation.** Cross-crate feature flags use `<crate-name>/<feature>`.
   The longest roster feature flag: `<name>-anthropic-sdk/rustls-tls`. With a 10-char
   prefix this is 25 characters — readable. With a 14-char prefix: 29 characters — valid.

4. **No Rust keyword collision.** Names must not be Rust keywords (`type`, `fn`, `use`,
   `let`, `mod`, `pub`, `match`, `where`, etc.). None of the Part C candidates are
   Rust keywords.

5. **Proc-macro crate convention.** The `ferrochain-macros` crate follows the `-macros`
   suffix convention. The new name must work as `<name>-macros` without collision.

**No candidate in Part C fails a Rust-idiom test as long as it is under 14 characters
and uses only `[a-z0-9-]` characters.**

### B-5: Pronounceability and Search-Distinctiveness

Criteria:
- Pronounceable on first attempt by an English speaker reading it cold
- Spellable from hearing the pronunciation
- Memorable after one encounter
- Produces focused web search results: `<name> rust` or `<name> crate` surfaces the
  project, not unrelated results

**Trade-off.** Invented compound words (high search focus, lower immediate recall)
versus real English words (higher immediate recall, higher collision risk). The D6
candidate set leaned toward invented compounds — this shortlist continues that pattern.

---

## Part C — Candidates by Positioning Strategy

> Stage 2 must verify crates.io, GitHub org, PyPI, and npm availability for all 24
> candidates before any name is presented to the human. Collision flags in the tables
> below are based on general knowledge, not authoritative checks.
>
> **Reading guide for crate prefix columns.** Three roster members are shown for each
> candidate: `-core` (universal), `-graph` (fundamental graph crate), and the longest
> or most structurally awkward member. A clean reading in all three is the pass criterion.

### Strategy 1 — Rust-Signalling (keeps metal/Rust cue, drops `-chain`)

| Candidate | `-core` `-graph` `-standard-tests` | Collision flags |
|-----------|-------------------------------------|-----------------|
| `ironmill` | `ironmill-core` `ironmill-graph` `ironmill-standard-tests` | No known Rust/AI collision; "Iron Mill" is a common business name but that is a different domain; verify crates.io |
| `ferrex` | `ferrex-core` `ferrex-graph` `ferrex-standard-tests` | Neologism from ferro + -ex suffix; 6 chars; short names carry higher squatting risk on crates.io; no known AI/Rust collision |
| `oxideweave` | `oxideweave-core` `oxideweave-graph` `oxideweave-standard-tests` | "oxide" is used by Oxide Computer Co. (hardware, different domain); `oxideweave` as compound is likely clear |
| `anvilflow` | `anvilflow-core` `anvilflow-graph` `anvilflow-standard-tests` | Anvil is used by a PDF/forms SaaS product; `anvilflow` as compound should be distinct; verify crates.io |
| `steelflow` | `steelflow-core` `steelflow-graph` `steelflow-standard-tests` | No known collision; "steel" is a weaker Rust-signal than "ferro/iron" but clear; verify |
| `ferrite` | `ferrite-core` `ferrite-graph` `ferrite-standard-tests` | Higher collision risk: "Ferrite" appears as an icon set and an audio app; `ferrite-core` sounds like a hardware component (ferrite bead); verify carefully |

### Strategy 2 — Graph/Dataflow-Signalling (aligns to LangGraph architecture)

Names containing "graph" are excluded per the B-1 semantic redundancy rule.

| Candidate | `-core` `-graph` `-standard-tests` | Collision flags |
|-----------|-------------------------------------|-----------------|
| `channelflow` | `channelflow-core` `channelflow-graph` `channelflow-standard-tests` (29 chars) | HPC fluid-dynamics research code "ChannelFlow" at Princeton; verify Rust/AI crates.io space specifically |
| `superstep` | `superstep-core` `superstep-graph` `superstep-standard-tests` | Precise BSP term; highly distinctive in the LLM/agent space; likely clean; verify |
| `stateweave` | `stateweave-core` `stateweave-graph` `stateweave-standard-tests` | No known collision; semantically accurate (stateful graph) and distinctive |
| `weftworks` | `weftworks-core` `weftworks-graph` `weftworks-standard-tests` | Very distinctive (weft = cross-thread in weaving; works = framework); lower discoverability offset by search focus |
| `nodeflow` | `nodeflow-core` `nodeflow-graph` `nodeflow-standard-tests` | `nodeflow-graph` has mild node/graph semantic overlap; "NodeFlow" exists as a visual-programming tool name; verify |
| `flowstate` | `flowstate-core` `flowstate-graph` `flowstate-standard-tests` | "FlowState" broadly used in productivity and wellness apps; verify Rust/AI space specifically |

### Strategy 3 — Neutral/Abstract (maximum trademark distance)

| Candidate | `-core` `-graph` `-standard-tests` | Collision flags |
|-----------|-------------------------------------|-----------------|
| `trellis` | `trellis-core` `trellis-graph` `trellis-standard-tests` | Trellis.earth (climate tech) and a Trellis WordPress framework exist; moderate adjacent-domain collision; verify crates.io |
| `corten` | `corten-core` `corten-graph` `corten-standard-tests` | COR-TEN is a branded weathering-steel alloy (United States Steel trademark); no known software collision; the steel reference carries a latent Rust pun; verify crates.io |
| `heddle` | `heddle-core` `heddle-graph` `heddle-standard-tests` | Loom component that separates warp threads; very distinctive; likely clean across all namespaces; verify |
| `spindle` | `spindle-core` `spindle-graph` `spindle-standard-tests` | Spindle is an Elixir property-testing framework; verify Rust space specifically |
| `arbor` | `arbor-core` `arbor-graph` `arbor-standard-tests` | `arbor-graph` has mild tree/graph semantic overlap (arbor = tree, trees are a graph subtype); "Arbor" appears in multiple software projects; collision risk |
| `vantage` | `vantage-core` `vantage-graph` `vantage-standard-tests` | Vantage AI (LLM cost optimization) is an active product in the AI tools space; moderate same-domain collision risk |

### Strategy 4 — Continuity (ferro-derived, retains brand lineage)

All Strategy 4 candidates derive from the current `ferro-` stem. Availability is likely
because `ferrochain` itself was verified clean and these compounds extend a clean stem.
Stage 2 must confirm each individually.

| Candidate | `-core` `-graph` `-standard-tests` | Collision flags |
|-----------|-------------------------------------|-----------------|
| `ferroflow` | `ferroflow-core` `ferroflow-graph` `ferroflow-standard-tests` | Likely clean; drops `-chain`, adds dataflow signal; strongest continuity-plus-accuracy option |
| `ferroweave` | `ferroweave-core` `ferroweave-graph` `ferroweave-standard-tests` | Likely clean; weave connotes graph connectivity; 10 chars |
| `ferronode` | `ferronode-core` `ferronode-graph` `ferronode-standard-tests` | `ferronode-graph` has mild node/graph overlap; 9 chars; likely clean |
| `ferrix` | `ferrix-core` `ferrix-graph` `ferrix-standard-tests` | Compressed ferro + -ix (Latin ending); 6 chars; punchy; short names carry higher squatting risk; likely clean |
| `ferroloom` | `ferroloom-core` `ferroloom-graph` `ferroloom-standard-tests` | Loom = weaving/orchestration machine; `loom` crate exists in Rust for thread-safety testing but `ferroloom` as compound is distinct; verify |
| `ferrolink` | `ferrolink-core` `ferrolink-graph` `ferrolink-standard-tests` | Link connotes graph edges; likely clean; 9 chars |

---

## Part D — Rename Sweep Scope

### What Must Change

| Location | What changes |
|----------|-------------|
| `.factory/specs/` (all spec files) | All crate names in spec prose, tables, interface definitions, error taxonomy, NFR catalog, and behavioral contracts |
| `.factory/specs/architecture/` (ARCH-INDEX.md, all section files, all ADRs) | Canonical crate roster, subsystem registry crate columns, ADR crate references, module decomposition, dependency graph |
| `.factory/hooks/` validator scripts | Any canonical pattern or allowlist entry matching `ferrochain` as a crate or project identifier |
| `.factory/namespace-reservation/` | All 21 stub Cargo.toml files: rename `name = "ferrochain-*"` to `name = "<new-name>-*"` |
| `.factory/namespace-reservation/publish-all.sh` | Update the crate name list to the new prefix |
| `.factory/semport/` | Reference manifest and per-package analysis files that identify output crate names |
| `CLAUDE.md` (project root) | Crate names in the toolchain section, pipeline references, code conventions, and the ARCH-INDEX §Canonical Crate Roster note |
| `.github/workflows/ci.yml` | Any workspace crate references or coverage targets |
| Root `Cargo.toml` | `members` list workspace entries (once crate directories exist) |
| Per-crate `Cargo.toml` under `crates/` | `[package] name` field and cross-crate `[dependencies]` keys |
| Per-crate `src/lib.rs` under `crates/` | `pub use` re-exports referencing sibling crate names |

### What Must NOT Change — Hard Exclusions

| Location | Reason and authority |
|----------|---------------------|
| `.factory/cycles/` — entire directory, all contents | **Hard exclusion.** Historical adversary pass reports, burst logs, convergence trajectories, and lessons files must state what was true when written. A rename sweep that edits these documents would retroactively falsify the audit trail. A past adversary pass that cites `ferrochain-core` was accurate at the time it was written; that accuracy is the foundation of the audit trail's evidentiary value. This exclusion is non-negotiable regardless of any other sweep-scope decision. (Grounded in D-79 and D-84.) |
| Historical STATE.md decision rows D1 through D-NNN at the time of the rename | STATE.md decision rows are append-only historical records. D6, which ratified "ferrochain", correctly records what was decided at that time. Do not alter historical decision rows; add a new decision row for the rename. |
| `naming-decision-study.md` | Historical record of the D6 rationale. It accurately records why ferrochain was chosen. It remains valid as history even after the name changes. |
| Sealed holdout scenario files that reference the old name | Holdout scenarios sealed before Phase 4 cannot be altered mid-stream without breaking the information-asymmetry guarantee. If currently sealed, they must remain unchanged. If not yet sealed, they are in scope. |

### Special Cases

**`ferrochain-prebuilt`.** The stub at `.factory/namespace-reservation/ferrochain-prebuilt/`
is NOT in the 21-crate canonical roster in ARCH-INDEX.md §Canonical Crate Roster. It is an
inert orphan with no production counterpart, already flagged as pending removal. The correct
action is to **delete** this stub directory entirely — not rename it. It should not appear
in the new namespace.

**`factory-artifacts` branch name.** The git branch name is infrastructure, not a project
identity marker. It does not require renaming.

**GitHub org and repo.** If `BOHICA-LABS/ferrochain` is renamed, all git remote URLs in
worktrees, CI pipelines, and local clones must be updated. This is a devops-engineer task
that follows the rename decision; it is not in scope for burst 284's spec-corpus sweep.

**crates.io reservation timing.** crates.io is first-come-first-served with no reservation
mechanism. The moment the new name is confirmed by the human, devops-engineer must claim all
21 crate names immediately — before any public announcement — to prevent squatting. The
`publish-all.sh` script in `.factory/namespace-reservation/` exists for exactly this purpose
and must be updated as part of the rename burst.

---

*Stage 2: research-agent runs live availability checks against crates.io, GitHub, PyPI,
and npm for all 24 candidates above. No candidate should be presented to the human until
Stage 2 verification is complete.*
