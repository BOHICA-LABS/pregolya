# VHS Demo — S-1.02 AC-008 + AC-011 + AC-016 (BC-2.14.005 PC-002, BC-2.14.006 PC-001/EC-006)
# Unit tests demonstrate:
#   AC-008: Debug emits exactly "<redacted>" (no key material in output)
#   AC-011: new("") → Err(E-CORE-005 / VAL / Never)
#   AC-016: new("   ") → Err(E-CORE-005 / VAL / Never) — whitespace-only rejection
# Usage: vhs docs/demo-evidence/S-1.02/AC-008-AC-011-AC-016-credential-validation-redaction.tape

Output docs/demo-evidence/S-1.02/AC-008-AC-011-AC-016-credential-validation-redaction.gif
Output docs/demo-evidence/S-1.02/AC-008-AC-011-AC-016-credential-validation-redaction.webm

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

# === Demo: AC-008 / AC-011 / AC-016 — credential validation + redacted Debug ===
# Runs tests covering:
#   - Debug emits "<redacted>" (AC-008)
#   - empty key → Err(E-CORE-005) (AC-011)
#   - whitespace-only key → Err(E-CORE-005) (AC-016)
Type "cargo nextest run -p pregolya-core -E 'test(BC_2_14_005) or test(BC_2_14_006)' --no-fail-fast"
Enter
Sleep 20s
