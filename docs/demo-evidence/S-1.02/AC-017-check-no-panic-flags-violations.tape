# VHS Demo — S-1.02 AC-017 (BC-2.14.003 EC-007)
# cargo xtask check-no-panic --fixture-mode flags bare assert! and _ => unreachable!()
# Usage: vhs docs/demo-evidence/S-1.02/AC-017-check-no-panic-flags-violations.tape

Output docs/demo-evidence/S-1.02/AC-017-check-no-panic-flags-violations.gif
Output docs/demo-evidence/S-1.02/AC-017-check-no-panic-flags-violations.webm

Require cargo

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font Mono"
Set FontSize 20
Set Width 1200
Set Height 700
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

# === Demo: AC-017 — check-no-panic FLAGS violations ===
# Error path: gate flags bare assert! and _ => unreachable!() in fixture files
Type "cargo xtask check-no-panic --fixture-mode xtask/tests/fixtures/violations"
Enter
Wait+Screen /violations found/
Sleep 2s
