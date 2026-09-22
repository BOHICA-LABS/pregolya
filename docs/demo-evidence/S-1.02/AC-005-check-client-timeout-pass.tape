# VHS Demo — S-1.02 AC-005 (BC-2.14.004 PC-003)
# cargo xtask check-client-timeout exits 0 (no missing-timeout violations).
# Usage: vhs docs/demo-evidence/S-1.02/AC-005-check-client-timeout-pass.tape

Output docs/demo-evidence/S-1.02/AC-005-check-client-timeout-pass.gif
Output docs/demo-evidence/S-1.02/AC-005-check-client-timeout-pass.webm

Require cargo

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font Mono"
Set FontSize 20
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
Type "cd $(git rev-parse --show-toplevel)"
Enter
Sleep 2s

Type "clear"
Enter
Sleep 1s
Show

# === Demo: AC-005 — check-client-timeout PASS ===
# Success path: no reqwest::Client::new() or missing .timeout() in pregolya-core
Type "cargo xtask check-client-timeout"
Enter
Wait+Screen /PASSED/
Sleep 2s
