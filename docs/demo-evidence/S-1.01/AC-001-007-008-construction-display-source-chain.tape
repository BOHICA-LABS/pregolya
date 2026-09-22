# VHS Demo — S-1.01 AC-001 / AC-007 / AC-008
# PregolyaError construction, Display format, and Arc source chain + Clone.
#
# ACs covered:
#   AC-001: struct construction (5 named fields + source), Display = "[code] message"
#   AC-007: #[non_exhaustive] — external callers use PregolyaError::new public constructor
#   AC-008: source: Option<Arc<dyn Error+Send+Sync>> — clone preserves source via Arc refcount
#
# Run from worktree root:
#   vhs docs/demo-evidence/S-1.01/AC-001-007-008-construction-display-source-chain.tape

Output docs/demo-evidence/S-1.01/AC-001-007-008-construction-display-source-chain.gif
Output docs/demo-evidence/S-1.01/AC-001-007-008-construction-display-source-chain.webm

Require cargo

Set Shell "zsh"
Set FontFamily "FiraCode Nerd Font Mono"
Set FontSize 16
Set Width 1200
Set Height 650
Set Theme "Catppuccin Mocha"
Set WindowBar Colorful
Set BorderRadius 8
Set Padding 20
Set Framerate 30
Set TypingSpeed 50ms

# === Hidden Setup — let shell initialise, then clear screen ===
Hide
Sleep 2s
Type "clear"
Enter
Sleep 1s
Show

# === Demo: AC-001 / AC-007 / AC-008 ===
# Binary already built; cargo run completes in <1s (no recompile needed).
# 2>/dev/null suppresses cargo's "Finished" status line.
Type "cargo run -p pregolya-core --example error_taxonomy_demo -- construction 2>/dev/null"
Enter
Sleep 8s
