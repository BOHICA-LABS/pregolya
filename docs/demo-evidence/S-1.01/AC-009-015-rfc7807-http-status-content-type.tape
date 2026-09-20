# VHS Demo — S-1.01 AC-009 / AC-010 / AC-011 / AC-012 / AC-013 / AC-014 / AC-015
# RFC-7807 to_problem(), http_status mapping, Content-Type, sync context, code immutability.
#
# ACs covered:
#   AC-009: to_problem() → type_uri="urn:pregolya:error:<code>", title, detail; top-level RFC-7807 §3.2 fields (retry_hint, component)
#   AC-010: serde_json::to_string_pretty → valid RFC-7807 JSON, no null required fields
#   AC-011: http_status() → all 14 categories mapped, no variant returns 200
#   AC-012: PROBLEM_JSON_CONTENT_TYPE = "application/problem+json" (not application/json)
#   AC-013: to_problem() synchronous — no tokio runtime required
#   AC-014: type_uri stable urn:pregolya:error:<code>; retry_hint canonical "never"/"maybe"/"later:<secs>"
#   AC-015: error.code preserved unchanged through to_problem().type_uri
#
# Run from worktree root:
#   vhs docs/demo-evidence/S-1.01/AC-009-015-rfc7807-http-status-content-type.tape

Output docs/demo-evidence/S-1.01/AC-009-015-rfc7807-http-status-content-type.gif
Output docs/demo-evidence/S-1.01/AC-009-015-rfc7807-http-status-content-type.webm

Require cargo

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font Mono"
Set FontSize 13
Set Width 1200
Set Height 1000
Set Theme "Catppuccin Mocha"
Set WindowBar Colorful
Set BorderRadius 8
Set Padding 20
Set Framerate 30
Set TypingSpeed 50ms

# === Hidden Setup ===
Hide
Sleep 2s
Type "clear"
Enter
Sleep 1s
Show

# === Demo: AC-009..015 — RFC-7807 emission, http_status, content-type, sync, immutability ===
# Taller terminal (Height 1000, FontSize 13) to show full output without scroll.
Type "cargo run -p pregolya-core --example error_taxonomy_demo -- rfc7807 2>/dev/null"
Enter
Sleep 10s
