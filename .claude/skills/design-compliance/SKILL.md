# Design System Compliance Check

> Trigger: "design check", "проверь дизайн-систему", "design compliance", "token audit", or when reviewing any UI change.

## Purpose
Verify that UI code strictly follows the Hexbound design system: tokens, components, patterns, and rules from CLAUDE.md.

## Workflow

### Phase 1 — Token Verification
1. Open `DarkFantasyTheme.swift` — verify all color references exist
2. Open `ButtonStyles.swift` — verify all button styles exist
3. Open `LayoutConstants.swift` — verify all spacing/sizing tokens exist
4. Open `OrnamentalStyles.swift` — verify ornamental patterns used correctly

### Phase 2 — Grep Checks
Run these greps on changed/new Swift files:
```bash
# Hardcoded colors (FAIL if found)
grep -rn 'Color(hex:' --include="*.swift" | grep -v DarkFantasyTheme.swift | grep -v Theme/
grep -rn 'Color\.white\|Color\.black' --include="*.swift" | grep -v 'opacity(0.0[1-9])' | grep -v OrnamentalStyles

# Missing theme prefix (FAIL if found)
grep -rn '\.foregroundStyle(\.\|\.foregroundColor(\.' --include="*.swift" | grep -v DarkFantasyTheme

# Hardcoded cornerRadius (FAIL if found)
grep -rn 'cornerRadius: [0-9]' --include="*.swift" | grep -v LayoutConstants | grep -v 'width/2'

# SF Symbol currency icons (FAIL if found)
grep -rn 'dollarsign.circle\|diamond.fill' --include="*.swift" | grep -v '//'

# Wrong SFX names (FAIL if found)
grep -rn '\.tap\b\|\.confirm\b\|\.success\b\|\.error\b' --include="*.swift" | grep 'SFX\|sfx\|SoundManager'
```

### Phase 3 — Component Reuse
Check that these reusable components are used (not duplicated):
- `ItemCardView` for all item displays
- `UnifiedHeroWidget` for character summary
- `StanceDisplayView` for stance display
- `CurrencyDisplay` for gold/gems
- `TabSwitcher` for tab UI
- `GoldDivider` for dividers
- `RadialGlowBackground` for panel backgrounds

### Phase 4 — Ornamental Pattern
For every panel/card, verify:
- RadialGlowBackground (not flat bgSecondary)
- .surfaceLighting overlay
- .innerBorder overlay
- .cornerBrackets (on visible panels)
- Dual shadow (type + abyss)

### Phase 5 — States
Every interactive element must have: default, pressed, selected, disabled, loading, error.
Every list must have: empty state with CTA.
Loading: skeletons > spinners > blank.

## Output Format
```
✅ PASS: [description]
⚠️ WARN: [description] — [recommendation]
❌ FAIL: [description] — [exact fix needed]
```

## Severity
- ❌ FAIL = blocks merge
- ⚠️ WARN = should fix before release
- ✅ PASS = compliant
