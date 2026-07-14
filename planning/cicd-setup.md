---
artifact: cicd-setup
phase: phase-1-workspace-init
created: 2026-07-14
author: devops-engineer
decisions-traced: D4, D10, D12
---

# ferrochain CI/CD Setup

## Repository

- **Repo:** BOHICA-LABS/ferrochain (public)
- **Default branch:** main (set manually after initial push)
- **Factory artifacts:** `.factory/` worktree on `factory-artifacts` orphan branch (pre-existing)

## Branch Strategy

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Stable releases; tagged versions | CI required, no force-push, no delete |
| `develop` | Integration target for story PRs | CI required, no force-push, no delete |
| `feature/STORY-NNN` | Per-story worktrees (`.worktrees/STORY-NNN/`) | None (ephemeral) |
| `factory-artifacts` | `.factory/` worktree (state-manager only) | None (orphan) |

## CI Pipeline: `.github/workflows/ci.yml`

### Trigger

- `push` to any branch (excludes `factory-artifacts`)
- `pull_request` targeting `main` or `develop`

### Concurrency

Cancel-in-progress for same workflow + ref — prevents queue pile-up on rapid pushes.

### Permissions

`contents: read` at workflow level (least-privilege). No elevated permissions needed for the current job set.

### Jobs

| Job name | Runner | Timeout | Guard condition |
|----------|--------|---------|----------------|
| `CI / fmt` | ubuntu-24.04 | 10 min | `hashFiles('Cargo.toml') != ''` |
| `CI / clippy` | ubuntu-24.04 | 20 min | `hashFiles('Cargo.toml') != ''` |
| `CI / test` | ubuntu-24.04 | 30 min | `hashFiles('Cargo.toml') != ''` |
| `CI / build` | ubuntu-24.04 | 30 min | `hashFiles('Cargo.toml') != ''` |
| `CI / file-size-gate` | ubuntu-24.04 | 15 min | `hashFiles('Cargo.toml') != '' && hashFiles('xtask/Cargo.toml') != ''` |

**Pre-workspace behaviour:** All Rust jobs emit a skip message and exit 0 when
`Cargo.toml` does not exist. The file-size gate additionally requires
`xtask/Cargo.toml`. The workflow therefore goes green on the bootstrap commit and
auto-enforces once Phase 3 workspace initialisation lands.

### Action pins (supply-chain security)

All actions are pinned to full commit SHAs, never tags or `latest`:

| Action | Version | SHA |
|--------|---------|-----|
| `actions/checkout` | v4.2.2 | `11bd71901bbe5b1630ceea73d27597364c9af683` |
| `dtolnay/rust-toolchain` | master | `fa04a1451ff1842e2626ccb99004d0195b455a88` |
| `Swatinem/rust-cache` | v2.7.5 | `82a92a6e8fbeee089604da2575dc567ae9ddeaab` |

### Rust cache

`Swatinem/rust-cache` caches `~/.cargo/registry`, `~/.cargo/git`, and per-workspace
`target/` keyed by `Cargo.lock` hash + OS + Rust channel. Shared between `clippy`,
`test`, and `build` jobs for fast incremental CI.

### File-size gate (D12)

`cargo xtask check-file-size` reads `tokei --output json` and enforces:
- Production files: 500 code-lines soft / 750 hard (CI fail)
- Test files: 1,000 soft / 1,500 hard

Exceptions are tracked in `xtask/file-size-allowlist.toml`. See
`.factory/planning/file-size-standard-study.md` for the full rationale.

The `tokei` binary is installed via `cargo install tokei --locked` within the job
so the version is pinned by the xtask's `Cargo.lock`.

## Branch Protection Configuration

Applied to both `main` and `develop` via `gh api`:

```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "CI / fmt",
      "CI / clippy",
      "CI / test",
      "CI / build",
      "CI / file-size-gate"
    ]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": true
  },
  "enforce_admins": false,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
```

`required_approving_review_count: 0` allows the VSDD PR flow (squash-merge via
pr-manager) to operate without a human review gate at the branch-protection layer.
Human review happens at the orchestrator approval gate, not the GitHub layer.

## .envrc Decision

`.envrc` was NOT committed to any branch. It contains a real value for
`ANTHROPIC_AWS_API_KEY` (base64-encoded AWS Marketplace workspace key). It has
been added to `.gitignore` alongside `.env` and `*.env.*` patterns. The direnv
scaffolding documents the `security add-generic-password` pattern for local setup
via macOS Keychain.

## Secrets Required in GitHub Actions

For Phase 3+ workflows that call LLM APIs or publish crates, add the following
GitHub repository secrets (none required for the current bootstrap CI):

| Secret name | Purpose |
|-------------|---------|
| `CRATES_IO_TOKEN` | Phase 7 release — `cargo publish` |
| `ANTHROPIC_AWS_API_KEY` | Integration tests requiring live Anthropic API (if any) |

## Planned Additions (not yet created)

These workflows are deferred to Phase 3 / Phase 7 respectively:

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/security.yml` | Weekly + PR | cargo audit, cargo deny, semgrep |
| `.github/workflows/release.yml` | Tag `v*` | Build binaries, publish crates.io, create GitHub Release |

Security and release workflows are authored by devops-engineer when the workspace
is initialised (Phase 3 entry) and when the release pipeline is triggered (Phase 7).
