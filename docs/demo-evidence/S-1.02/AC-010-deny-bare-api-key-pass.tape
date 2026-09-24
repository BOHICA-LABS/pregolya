# VHS Demo — S-1.02 AC-010 (BC-2.14.005 PC-006)
# cargo xtask deny-bare-api-key exits 0 (no structural credential violations).
# Usage: vhs docs/demo-evidence/S-1.02/AC-010-deny-bare-api-key-pass.tape

Output docs/demo-evidence/S-1.02/AC-010-deny-bare-api-key-pass.gif
Output docs/demo-evidence/S-1.02/AC-010-deny-bare-api-key-pass.webm

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

# === Demo: AC-010 — deny-bare-api-key PASS ===
# Success path: OpenAiApiKey and AnthropicApiKey use manual Debug (no derive(Debug))
# and no Serialize or Deref<Target=str> — structural gate passes clean
Type "cargo xtask deny-bare-api-key"
Enter
Wait+Screen /PASSED/
Sleep 2s
