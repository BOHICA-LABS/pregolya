---
artifact: planning/naming-decision-pregolya
document_type: planning
stage: rename-stage-2-decision
version: "1.0"
created: 2026-07-30T00:00:00Z
author: business-analyst
status: ratified
decision_owner: human maintainer
supersedes: .factory/planning/naming-decision-study.md (D6)
superseded_by: N/A
preserve_classified: false
inputs:
  - .factory/planning/naming-decision-study.md
  - .factory/planning/rename-constraint-spec.md
  - .factory/planning/rename-sweep-manifest.md
  - .factory/specs/domain-spec/ubiquitous-language-core.md
  - .factory/semport/graph/behavioral-intent.md
  - .factory/semport/graph/module-inventory.md
input-hash: "262eaa9"
---

# Naming Decision Record — Pregolya

This record is the canonical source for the product rename to **Pregolya**. Every
downstream surface that references the project name (crate descriptions, README,
CLAUDE.md, Cargo.toml `[package] description` fields) must quote from this record
rather than reconstructing the rationale independently.

**Relationship to D6 (naming-decision-study.md):** The D6 record remains PRESERVE-
classified. It accurately documents why `ferrochain` was chosen and is the correct
historical record of that decision. This record supersedes D6 in the sense that it
ratifies a new name for the same project — it does not falsify D6. Forward reference:
D6 was the name-selection rationale; this record is the rename rationale. Both are
permanently retained in `.factory/planning/`.

---

## Changelog

### 2026-07-30 — v1.0 Initial ratified record

- Human confirmed selection: `Pregolya`
- Story, pronunciation, availability evidence, rejected alternatives, and process
  findings captured
- Availability independently re-verified via `curl` at time of authoring

---

## 1. Selected Name

| Attribute | Value |
|-----------|-------|
| Product name | **Pregolya** |
| Crate prefix | `pregolya` |
| Type prefix | `Pregolya` |
| Snake-case form | `pregolya_core`, `pregolya_standard_tests` |
| Example crate names | `pregolya-core`, `pregolya-graph`, `pregolya-checkpoint`, `pregolya-openai`, `pregolya-standard-tests` |
| Decision status | Ratified by human. Rename burst 284 executes the sweep. |

---

## 2. The Story — Four-Step Lineage

The name traces an unbroken intellectual lineage from an 18th-century river crossing to
this library.

**Step 1 — The river.**
The Pregolya (Russian: Преголя; German: Pregel) is a river in the Kaliningrad Oblast of
Russia, flowing westward through what was historically Königsberg. Both names — Pregolya
and Pregel — refer to the same river; Pregolya is the Russian form, Pregel the German.

**Step 2 — Euler's bridges.**
Königsberg's old town was built across seven bridges spanning the Pregolya and its
islands. In 1736, Leonhard Euler published *"Solutio problematis ad geometriam situs
pertinentis"* (Solution of a problem relating to the geometry of position). Euler proved
no walk through the city could cross each of the seven bridges exactly once. Ordinary
geometry could not express the problem — distance and angle are irrelevant; only which
landmasses are connected matters — so Euler named the new mathematics **geometria situs**
("the geometry of position"). This paper is generally regarded as the first theorem of
graph theory and a foundational precursor to topology.

**Step 3 — Google Pregel.**
In 2010, Grzegorz Malewicz et al. published "Pregel: A System for Large-Scale Graph
Processing" at SIGMOD 2010. The system was named after the river. Google Pregel
implements Leslie Valiant's **Bulk Synchronous Parallel (BSP)** computation model.
The fundamental unit of execution in BSP is the **super-step**: all active vertices
compute concurrently, then all messages are delivered, then the cycle repeats. Google
Pregel applies this model to large-scale graph computation across distributed workers.

Verification against project corpora: `.factory/semport/graph/behavioral-intent.md`
§1 explicitly identifies LangGraph as "a **Bulk Synchronous Parallel (Pregel/BSP)**
engine" and defines its execution as "a sequence of discrete **super-steps**."
The project's canonical ubiquitous language document (`ubiquitous-language-core.md`
§Super-step) defines: "One round of BSP (Bulk-Synchronous Parallel) execution."
Both references are independently consistent with the Google Pregel BSP super-step
terminology.

**Step 4 — LangGraph's engine and this library.**
LangGraph names its internal execution engine **Pregel** — specifically the class
`Pregel` in `langgraph/pregel/main.py`. `StateGraph.compile()` returns a
`CompiledStateGraph` that inherits from `Pregel`. The module directory is `pregel/`.
This is confirmed by `.factory/semport/graph/module-inventory.md` §1.1 ("pregel/ —
the execution engine") and the behavioral-intent document, which cites `_loop.py`,
`_algo.py`, and `_runner.py` as the core super-step driver, algorithm, and task
scheduler respectively.

This library is a Rust semantic port of LangGraph. It therefore sits at the terminus
of the lineage: Euler → the Pregolya river → Google Pregel (BSP) → LangGraph Pregel
engine → this library.

---

## 3. Why Pregolya and Not Pregel

Choosing the Russian form `pregolya` over the German `pregel` is the decisive fork in
the name selection. Three reasons support the choice; the third is practically decisive.

**Reason 1 — Common ancestor, not borrowed component name.**
`Pregel` is not LangChain intellectual property — it is a river. But within the LangGraph
ecosystem, `Pregel` reads as *LangGraph's internal engine class*. Choosing `Pregolya`
draws on the same common ancestor that upstream borrowed from, without adopting upstream's
own component name. The library sits in the lineage *alongside* LangGraph's Pregel engine;
it is not a renaming of it.

**Reason 2 — Grep disambiguation (token-overload).**
The token `pregel` appears in exactly 40 files under `.factory/specs/` (verified by
exhaustive grep at time of authoring). These occurrences are upstream Python references:
`pregel.py` parity citations, `PregelTask` behavioral contracts, `pregel/_loop.py`
source anchors in semport documents. Naming the library `Pregel`-anything would create
a two-meaning token in the project's own specification corpus — the library name and
the upstream reference — making grep-based disambiguation impossible.

**Reason 3 — Architecture layer ratification.**
Adversary finding F-P140-01 (pass 140, finding 01 of the convergence cascade) was a
HIGH-severity finding that swept 22 behavioral contract files to remove 35 path
references to `pregel/*.rs` and replace them with the canonical flat `graph::` module
layout per ADR-001. The resulting architecture names the execution engine modules
`graph::bsp_engine` and `graph::scheduler`. The rename sweep must not reintroduce
`pregel::` as a module namespace. Using `Pregolya` as the product name does not create
pressure to use `pregel::` internally; using `Pregel` as the product name would.

**Why `pregelia` was rejected.**
`pregelia` was the human's initial candidate in this lineage. It was superseded by
`pregolya` because `pregelia` can be parsed visually as `pregel-ia` — it contains
the five-character substring `pregel` followed by a vowel suffix. A reader scanning
spec files would be unable to distinguish a `pregelia` library reference from a
`PregelIA`-prefixed upstream construct at a glance. `Pregolya` (with the `o` in
position 4 rather than `e`) does not have this parsing ambiguity and is additionally
the correct standard transliteration of the Russian Преголя.

---

## 4. Pronunciation

**How to say it:** pruh-GOH-lyuh (stress on the second syllable, like "go" in "goal")

**IPA:** [prʲɪˈɡolʲə]

**Syllable-by-syllable guidance:**

| Syllable | Sound | Notes |
|----------|-------|-------|
| *pruh* | unstressed, reduced | "preh" is also acceptable; the vowel is schwa-like in Russian |
| *GOH* | stressed | like "goal" without the L; the `o` is a full open-mid back vowel |
| *lyuh* | soft, reduced | the `l` is palatalized (soft L as in the "lli" of "million"); final vowel is reduced to schwa |

**Canonical casual English approximation:** pre-GOAL-ya

This approximation is explicitly blessed as acceptable. The project has one sanctioned
casual form; "PRAY-goh-lyuh," "preh-GOL-ee-yah," and other invented forms are not
preferred.

**On the German form:** `Pregel` is pronounced *PRAY-gul* (two syllables, stress on
first). It is noted here only to explain why it is not the chosen form.

**One-liner for README and Cargo.toml description use:**
> Pronounced *pruh-GOH-lyuh* (casual: *pre-GOAL-ya*) — named for the Pregolya river
> in Kaliningrad, whose seven bridges inspired Euler's first theorem of graph theory.

---

## 5. Availability Evidence

Verification performed at time of authoring (2026-07-30) via `curl` with a
descriptive User-Agent header. Note: crates.io returns HTTP 403 when no User-Agent
is supplied (bot-protection behavior); the correct check requires a User-Agent and
interprets HTTP 404 with response body `"crate does not exist"` as available.

| Name | crates.io | PyPI | Status |
|------|-----------|------|--------|
| `pregolya` | HTTP 404 — "crate `pregolya` does not exist" | HTTP 404 | Available |
| `pregolya-core` | HTTP 404 — "crate `pregolya-core` does not exist" | — | Available |
| `pregolya-graph` | HTTP 404 — "crate `pregolya-graph` does not exist" | — | Available |
| `pregolya-checkpoint` | HTTP 404 — "crate `pregolya-checkpoint` does not exist" | — | Available |
| `pregolya-openai` | HTTP 404 — "crate `pregolya-openai` does not exist" | — | Available |
| `pregolya-standard-tests` | HTTP 404 — "crate `pregolya-standard-tests` does not exist" | — | Available |

**Important:** The name is verified free but NOT reserved. crates.io has no advance
reservation mechanism; claiming the name requires `cargo publish`. The `publish-all.sh`
script in `.factory/namespace-reservation/` must be updated for the new prefix as part
of burst 284, and devops-engineer must execute it immediately upon the rename going live
— before any public announcement — to prevent squatting. The human has authorized
deferring this to burst 284; that authorization is recorded in STATE.md.

---

## 6. Rejected Alternatives

### 6.1 Candidates from the rename generation passes

| Name | Disqualifying reason |
|------|---------------------|
| `anvilflow` | No derivable story — selected initially by reverse-engineered rationale (see §7 process finding). Additionally, `foundry-rs/foundry` (10,528 stars) publishes `anvil`, `forge`, `cast`, and `chisel`, colonizing the blacksmithing metaphor space in Rust. |
| `ferroweave` | Held as fallback through generation passes; rejected because the `ferro-` stem is a crowded namespace: `ferro`, `ferrocene`, `ferris`, `ferrous`, and `ferrix` all compete on crates.io prefix-search. |
| `shedline` | Highest architectural precision of the pure-invented set; "shed" reads as a storage building without weaving vocabulary, making the metaphor opaque to a new reader. |
| `syncstep` | Fully derivable from BSP super-step semantics; rejected as dry — reads as an internal architecture term, not a library name. |
| `warpweft` | Strongest weaving story of the metaphor group; `warp` has 45.1M downloads in the Rust ecosystem, making `warpweft` visually ambiguous in a Cargo.toml next to `warp`. |
| `situs` | Euler's own coinage for graph topology ("geometria situs"); shortest and cleanest of the historical candidates; rejected because it is Latin, carries no immediate signal in English, and collides with a medical term (anatomical situs inversus). |
| `kneiphof` | The central island of Königsberg that five of the seven bridges connect; the most historically precise reference; rejected for spelling friction — non-German speakers cannot spell it from hearing it. |
| `konigsberg` | Most legible historical story; rejected because it is the longest candidate (11 characters), the umlaut is lost in ASCII (`Königsberg → konigsberg`), and the German city name carries mid-20th-century historical freight unrelated to the project's domain. |
| `pregelia` | Human's initial pick in the river-name family; superseded by `pregolya` because it parses visually as `pregel-ia`, reintroducing the Pregel token-disambiguation problem in a different form. |

### 6.2 First-pass eliminations on crates.io

Eight names verified taken on crates.io in the first availability pass:

| Name | Reason eliminated |
|------|------------------|
| `ferrite` | Taken |
| `flowstate` | Taken |
| `trellis` | Taken |
| `corten` | Taken |
| `spindle` | Taken |
| `arbor` | Taken |
| `vantage` | Taken |
| `ferrix` | Taken |

---

## 7. Process Findings

Two findings from the naming process are recorded here as honest audit trail entries.
They affected the outcome and should inform future naming exercises.

**Process Finding 1 — Over-broad disqualification constraints.**
The orchestrator in the generation passes initially treated GitHub organization
availability and npm package availability as hard disqualifying constraints. Neither
binds for this project. The repository publishes under the existing `BOHICA-LABS`
organization, making GitHub org availability irrelevant. npm is irrelevant to a Rust
library absent JavaScript bindings. These over-constraints eliminated roughly a dozen
candidates — including `warpweft`, which had the strongest derivable story in the
metaphor group — and cost a generation cycle. The binding constraints are:
**crates.io (hard — all 21 crate names must be available)** and
**PyPI (soft — worth holding to prevent cross-ecosystem confusion, but not blocking if
clear evidence of low collision exists)**. GitHub org and npm are advisory checks only.

**Process Finding 2 — Reverse-engineered rationale detection.**
`anvilflow` was initially presented as the recommended candidate. The human's test —
"what is the story?" — caught that the recommendation preceded the rationale rather
than following from it. A name without a derivable story is a name selected by
elimination and dressed up post hoc. The correct ordering is: story first, name second.
`Pregolya` passes this test: the Euler lineage is the story; the name follows from it.

---

## 8. Decision Authority

The human has selected `Pregolya`. The selection is unconditional and not subject to
further availability research. Burst 284 executes the rename sweep per the manifest
at `.factory/planning/rename-sweep-manifest.md`. State-manager records the decision
in STATE.md. This record is the source of truth for all downstream naming surfaces.
