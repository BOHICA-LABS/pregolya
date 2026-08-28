---
document_type: behavioral-contract
level: L3
bc_id: BC-2.13.006
version: "1.5"
status: active
producer: product-owner
timestamp: 2026-08-23T00:00:00Z
phase: 1a
inputs:
  - .factory/specs/domain-spec/capabilities-p1-p2.md
  - .factory/specs/domain-spec/invariants.md
  - .factory/specs/domain-spec/edge-cases.md
  - .factory/comparative/assessment-parts/part-2-dispositions-p51-p97.md
  - .factory/comparative/assessment-parts/part-3-conflicts-negative-evidence.md
  - .factory/planning/holdout-domains/domain-c-openclaw.md
input-hash: "27d5e02"
extracted_from: null
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
traces_to: domain-spec/L2-INDEX.md
origin: greenfield
subsystem: SS-13
capability: CAP-015
lifecycle_status: active
introduced: v1.0.0-greenfield
changelog:
  - "1.0 (initial): base BC authored (greenfield burst 72)."
  - "1.1 (ADV-P1D-PASS-11): F-P11-04 — E-SBXD-004 and E-SBXD-005 error codes added to PC6, EC-002, and EC-005 (error-taxonomy.md expansion; bc-authoring-plan.md E-code×variant gate)."
  - "1.2 (FIX-BURST-257/F-P156-01, 2026-07-24): anchor-class sweep — nonexistent architecture file citations replaced with adjudicated real targets (F-P114-01 pattern)."
  - "1.3 (burst-291/D-134/2026-08-16): §-anchor phantom sweep — Forcing Functions: §NE catalog NE-16 is a phantom anchor (no '## NE catalog' heading in product-brief.md; NE items are table rows within '### Security Defaults — PRD Carry-Forward'). Corrected to §Security Defaults — PRD Carry-Forward (NE-16)."
  - "1.4 (M1/ADR-027/2026-08-23): stable clause anchors {PC/INV/PRE-NNN} added; purely additive, no content change."
  - "1.5 (F-P2A123-01/2026-08-28): §Story Anchor backfilled to S-1.09; §Architecture Module confirmed as pregolya-sandbox / macOS Seatbelt backend — from STORY-INDEX forward map (SS-13 coverage map) and self §Architecture Anchors (module-decomposition.md §pregolya-sandbox, sandbox::seatbelt row). No behavioral change."
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
priority: P1
wave: 1
---

# BC-2.13.006: macOS Seatbelt Profile: Deny-by-Default with Explicit Allow Rules (NE-16)

## Description

When pregolya-sandbox generates a macOS Seatbelt (`sandbox_init`) profile for tool
execution, the profile must use `(deny default)` as its base policy and enumerate explicit
`(allow ...)` rules for each permitted operation. The adk-rust counter-example (P-60) uses
`(allow default)` then selectively denies `network*`, `file-write*`, and `process-fork` — but
never denies `file-read*`. Sandboxed code running under that profile can read any file the
process user can access: SSH keys, `~/.aws/credentials`, browser cookies, `/etc/hosts`. pregolya
inverts this: start from deny-everything and allow only what is explicitly needed. If a deny-by-default
allow-list is impractical for a given macOS environment, pregolya documents macOS as a
"no-isolation" platform for that tool and requires `--allow-no-sandbox` explicit opt-in rather
than silently running unsandboxed.

## Preconditions

1. {PRE-001} The target platform is macOS (Darwin)
2. {PRE-002} The `sandbox-macos-seatbelt` feature (or equivalent platform-detection) is active
3. {PRE-003} A Seatbelt profile is being generated for a tool-execution session
4. {PRE-004} The tool policy does not include `allow_network: true` (default is network-denied)

## Postconditions

1. {PC-001} The generated Seatbelt profile string contains `(deny default)` (or `(deny default
   (with no-report))` for production use) as the first policy rule
2. {PC-002} The profile does NOT contain the literal string `(allow default)` anywhere
3. {PC-003} Each allowed operation is enumerated explicitly: `(allow file-read* (subpath
   <workspace_path>))`, `(allow file-read* (subpath "/usr/lib"))` (system library reads), etc.
4. {PC-004} `file-read*` for paths outside the allowed set is denied by the base `(deny default)` rule
5. {PC-005} Network access is denied unless `allow_network: true` is set in the tool policy, in which
   case an explicit `(allow network*)` rule is added
6. {PC-006} If a deny-by-default allow-list is impractical (e.g., the tool requires too many system
   paths to enumerate), `SandboxBackend::new_macos_seatbelt()` returns
   `Err(SandboxError::PlatformNoEnforcement { reason: "macOS Seatbelt allow-list too broad to enumerate" })`
   (`E-SBXD-004`); execution proceeds only if the caller passes `SandboxPolicy::allow_no_sandbox()`

## Invariants

1. {INV-001} The literal string `(allow default)` must NOT appear in any pregolya-generated Seatbelt
   profile — not as a rule, not as a comment, not as a fallback
2. {INV-002} `(deny default)` must be present as the base policy before any `(allow ...)` rules
3. {INV-003} The allow-list is bounded and explicit: each allowed path or operation is named; wildcards
   are used only for subtree scoping (`(allow file-read* (subpath X))`) not for global scope
4. {INV-004} The asymmetry between Linux (deny-by-default reads via bubblewrap) and macOS (P-60 
   allow-all-reads) must not exist silently in any pregolya build; if macOS cannot enforce
   deny-by-default, the backend must report `PlatformNoEnforcement` and refuse to execute
   unless explicitly opted in
5. {INV-005} adk-rust reference sparsity: P-60 is the counter-example; no positive upstream reference
   for deny-by-default Seatbelt in this codebase — greenfield design derived from NE-16

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Tool policy sets `allow_network: true` | `(allow network*)` rule is added to the profile; `(deny default)` base remains; no `(allow default)` |
| EC-002 | macOS kernel version does not support the required Seatbelt operations | `Err(SandboxError::BackendUnavailable { reason: "Seatbelt unsupported on this macOS version" })` (`E-SBXD-005`); does NOT silently run unsandboxed |
| EC-003 | Running under `unsafe_process_no_isolation()` on macOS (explicitly opted in) | No Seatbelt profile is generated; standard process-backend WARN log (BC-2.13.002) is emitted |
| EC-004 | Profile generation produces a profile with `(deny default)` but the tool's required allow-list is feasible | Profile generated; returned to caller; execution proceeds with Seatbelt enforcement |
| EC-005 | Tool requires reading from a path outside the workspace and system libraries (e.g., user home dir beyond scope) | The specific path is evaluated: if it can be added to the allow-list without making the list impractical, it is added; otherwise `E-SBXD-004 PlatformNoEnforcement` is returned |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `SandboxBackend::new_macos_seatbelt(workspace_root, default_policy)` on macOS | Generated Seatbelt profile contains `(deny default)` and does NOT contain `(allow default)` | happy-path (NE-16 inversion) |
| Scan generated profile for the literal string `(allow default)` | Zero occurrences | NE-16 inversion structural test |
| `SandboxPolicy { allow_network: true }` → profile generation | Profile contains `(allow network*)`; still contains `(deny default)` as base | edge-case (network allow) |
| macOS with no Seatbelt support → `SandboxBackend::new_macos_seatbelt()` | `Err(SandboxError::BackendUnavailable)` — does not silently run unsandboxed | error (platform limitation) |
| Profile with `(deny default)` + explicit workspace read-allow + no file-read* for `/etc/passwd` + attempt to read `/etc/passwd` | Seatbelt denies the read at the OS level — file content never returned | sandboxing enforcement test |

## Verification Properties

| VP-ID | Property | Proof Method |
|-------|----------|--------------|
| VP-2.13.006-A | No pregolya-generated Seatbelt profile contains the literal string `(allow default)` | unit test — generate profile; assert string is absent |
| VP-2.13.006-B | Every pregolya-generated Seatbelt profile contains `(deny default)` as the first rule | unit test — profile string prefix assertion |
| VP-2.13.006-C | macOS Seatbelt profile denies file reads to paths outside the workspace (e.g., SSH keys, AWS credentials, `/etc/passwd`) | macOS integration test — run sandboxed code that attempts to read `~/.aws/credentials`; assert read is denied |

## Traceability

| Field | Value |
|-------|-------|
| L2 Capability | CAP-015 |
| Capability Anchor Justification | CAP-015 ("Sandboxed Tool Execution (Enforcing Backend Default)") per capabilities-p1-p2.md §CAP-015 |
| L2 Domain Invariants | DI-006 (Enforcing Sandbox Backend is Default) |
| Source Analysis | P-60 NOT-APPLICABLE (must-not-inherit: `(allow default)` then selective deny = allow-all-reads; credential exfiltration surface); NE-16 (pregolya requirement: deny-by-default with explicit allow rules); P-48 ADOPT (Linux bubblewrap deny-by-default is the positive reference model — macOS Seatbelt must match this posture); assessment-parts/part-3 §NE-16 |
| Reference Evidence | adk-rust P-60: macOS Seatbelt profile uses `(allow default)` as base — sandboxed code can read SSH keys, AWS credentials, browser cookies. pregolya INVERTS this. P-48 (Linux bubblewrap deny-by-default via `--unshare-*`) is the positive model that macOS must match. No upstream positive Seatbelt reference — greenfield. |
| Binding Decisions | NE-16, DI-006 |
| Forcing Functions | product-brief.md §Security Defaults — PRD Carry-Forward (NE-16) (implied by NE-01 enforcing-default posture applied to macOS platform); assessment-parts/part-3 §NE-16 ("asymmetry must not exist silently") |
| Architecture Module | pregolya-sandbox / macOS Seatbelt backend |
| Stories | S-1.09 |

## Related BCs

- BC-2.13.001 — composes with: the macOS Seatbelt deny-by-default profile is the enforcing backend for the macOS platform; BC-2.13.001's default-enforcing-backend mandate applies here
- BC-2.13.002 — composes with: if macOS Seatbelt is unavailable and caller uses `unsafe_process_no_isolation()`, BC-2.13.002's WARN log covers the fallback scenario

## Architecture Anchors

- `architecture/module-decomposition.md §pregolya-sandbox` — `sandbox::seatbelt` row: macOS Seatbelt deny-by-default profile (NE-16); profile generation for Darwin (MEDIUM, SS-13)
- `architecture/purity-boundary-map.md §Effectful Shell` — `sandbox::seatbelt` row: macOS Seatbelt syscall OS integration; integration test strategy

## Story Anchor

S-1.09 — macOS Seatbelt deny-by-default profile generation

## VP Anchors

- VP-2.13.006-A — No `(allow default)` in generated profiles (unit test)
- VP-2.13.006-B — `(deny default)` as first rule (unit test)
- VP-2.13.006-C — Credential read denied under Seatbelt (macOS integration test)
