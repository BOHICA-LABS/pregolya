# VHS Demo — S-1.01 AC-002 / AC-003 / AC-004
# Component axis (17 named + Custom = 18), Category axis (14 incl. Sys), RetryHint (3 variants).
#
# ACs covered:
#   AC-002: Component — 17 named variants + Custom(String) = 18 total
#   AC-003: Category — 14 variants; Sys (14th) = INTERNAL-tier, HTTP 500
#   AC-004: RetryHint — Never / Maybe / Later(Duration); Duration::ZERO valid sentinel
#
# Run from worktree root:
#   vhs docs/demo-evidence/S-1.01/AC-002-003-004-enum-axes-retry-hint.tape

Output docs/demo-evidence/S-1.01/AC-002-003-004-enum-axes-retry-hint.gif
Output docs/demo-evidence/S-1.01/AC-002-003-004-enum-axes-retry-hint.webm

Require cargo

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font Mono"
Set FontSize 16
Set Width 1200
Set Height 600
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

# === Demo: AC-002 / AC-003 / AC-004 — Enum Axes & RetryHint ===
Type "cargo run -p pregolya-core --example error_taxonomy_demo -- enums 2>/dev/null"
Enter
Sleep 8s
