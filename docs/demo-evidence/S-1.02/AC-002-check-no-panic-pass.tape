# VHS Demo — S-1.02 AC-002 (BC-2.14.003 PC-004)
# cargo xtask check-no-panic exits 0 on the pregolya-core source tree.
# Usage: vhs docs/demo-evidence/S-1.02/AC-002-check-no-panic-pass.tape

Output docs/demo-evidence/S-1.02/AC-002-check-no-panic-pass.gif
Output docs/demo-evidence/S-1.02/AC-002-check-no-panic-pass.webm

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

Type "cargo build -p xtask -q 2>&1"
Enter
Sleep 15s

Type "clear"
Enter
Sleep 1s
Show

# === Demo: AC-002 — check-no-panic PASS ===
# Success path: gate exits 0 on pregolya-core source tree (no violations)
Type "cargo xtask check-no-panic"
Enter
Wait+Screen /PASSED/
Sleep 2s
