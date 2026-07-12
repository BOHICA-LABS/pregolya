# Preflight Report — langchain-rs

**Date:** 2026-07-12
**Project:** langchain-rs (greenfield Rust workspace, no src/ yet)
**Overall result:** WARN

---

## Summary

| Area | Status | Notes |
|------|--------|-------|
| Rust toolchain | PASS | rustc/cargo 1.95.0 stable + nightly present |
| Verification tools | PASS | All 7 tools present |
| Git + gh CLI | PASS | Authenticated as drbothen |
| Python / uv | PASS | Python 3.11.7, uv 0.7.8 |
| direnv | WARN | .envrc present but NOT yet allowed |
| .mcp.json | WARN | API key values hardcoded as plaintext |

**Missing tools:** none

---

## 1. Rust Toolchain

| Tool | Version | Status |
|------|---------|--------|
| rustc | 1.95.0 (59807616e 2026-04-14) | PASS |
| cargo | 1.95.0 (f2d3ce0bd 2026-03-21) | PASS |
| clippy | installed (stable-aarch64-apple-darwin) | PASS |
| rustfmt | installed (stable-aarch64-apple-darwin) | PASS |

**Installed toolchains via rustup:**

- `stable-aarch64-apple-darwin` (default)
- `nightly-aarch64-apple-darwin` (latest nightly)
- `nightly-2025-06-23-aarch64-apple-darwin`
- `nightly-2025-11-21-aarch64-apple-darwin`
- `1.83.0`, `1.86`, `1.88`, `1.95` pinned toolchains

**Installed targets:** aarch64-apple-darwin, aarch64-unknown-linux-musl, wasm32-wasip1,
x86_64-apple-darwin, x86_64-pc-windows-gnu, x86_64-pc-windows-msvc,
x86_64-unknown-linux-gnu, x86_64-unknown-linux-musl

---

## 2. Verification Tooling

| Tool | Version | Status |
|------|---------|--------|
| cargo-nextest | 0.9.129 | PASS |
| cargo-fuzz | 0.13.1 | PASS |
| cargo-mutants | 27.0.0 | PASS |
| cargo-kani | 0.67.0 | PASS |
| kani (binary) | present | PASS |
| cargo-audit | 0.22.1 | PASS |
| cargo-deny | 0.19.0 | PASS |
| semgrep | present (version string empty) | PASS |

Note: cargo-mutants exits with an error when no Cargo.toml is present — expected for
a greenfield project at this stage. It will function correctly once the workspace
is initialized.

---

## 3. Git + gh CLI Auth

| Tool | Version | Status |
|------|---------|--------|
| git | 2.50.1 (Apple Git-155) | PASS |
| gh | 2.83.2 (2025-12-10) | PASS |

**gh auth:** Logged in to github.com as `drbothen` (keyring). Active account: true.
Protocol: https. Token scopes: gist, project, read:org, repo, workflow.

---

## 4. Python / uv

| Tool | Version | Status |
|------|---------|--------|
| python3 | 3.11.7 | PASS |
| uv | 0.7.8 (Homebrew 2025-05-23) | PASS |

Both tools are available for semport analysis of the reference LangChain Python corpus.

---

## 5. direnv State

**File:** `/Users/jmagady/Dev/langchain-rs/.envrc` — present

**Allowed state:** NOT ALLOWED (allowed = 0)

**Action required:** Run `direnv allow .` from the project root before the pipeline
reads environment variables.

**Variable names declared in .envrc (names only — no values logged):**

- `CLAUDE_CODE_USE_ANTHROPIC_AWS`
- `AWS_REGION`
- `ANTHROPIC_AWS_WORKSPACE_ID`
- `ANTHROPIC_AWS_API_KEY`

No key validation was performed because direnv has not been allowed yet and no
`.env` file is expected at this stage of a greenfield project.

---

## 6. MCP Server Configuration

**File:** `/Users/jmagady/Dev/langchain-rs/.mcp.json` — present (untracked, not yet committed)

**Configured MCP servers:**

| Server | Transport | Status |
|--------|-----------|--------|
| perplexity | stdio (npx @perplexity-ai/mcp-server) | configured |
| tavily | http (mcp.tavily.com) | configured |
| playwright | stdio (npx @playwright/mcp@latest) | configured |
| context7 | http (mcp.context7.com) | configured |

**SECURITY WARNING:** `.mcp.json` contains API key values hardcoded as plaintext in the
`env` block (PERPLEXITY_API_KEY), in the Tavily URL query string, and in the context7
headers block. Key names flagged: PERPLEXITY_API_KEY, tavily API key (URL-embedded),
CONTEXT7_API_KEY. The file is currently untracked. Do NOT commit it in its current form.
Recommended remediation: move key values to `.env` and reference them via environment
variable expansion, or add `.mcp.json` to `.gitignore`.

---

## Warnings Summary

1. **direnv not allowed** — run `direnv allow .` before pipeline Phase 3. The .envrc
   declares 4 AWS/Anthropic key names that must be set in `.env` or the shell environment.

2. **Plaintext API keys in .mcp.json** — `.mcp.json` is untracked and must NOT be
   committed. Move secret values to `.env` or `.gitignore` the file before first commit.

---

## No Missing Tools

All required tools for the greenfield Rust pipeline are present:
Rust stable + nightly, clippy, rustfmt, cargo-nextest, cargo-fuzz, cargo-mutants,
cargo-kani, cargo-audit, cargo-deny, semgrep, git, gh, python3, uv, direnv.
