# UI/UX Design Principles

Canonical design and UX standards for Hexbound. Use this guide when designing new screens, auditing existing screens, or reviewing SwiftUI code for UX quality.

*Updated: 2026-03-19*

---

## Product Principles (Hard Requirements)

These are non-negotiable. Every screen must satisfy all of them.

### 3-Second Rule

Player understands the primary goal and action of the screen in under 3 seconds.

- What is this screen for?
- What should the player do?
- What will happen if they do it?

If the player can't answer these three questions in 3 seconds, the design has failed.

### One Goal Per Screen

One primary call-to-action (CTA). Everything else is secondary.

- Not "pick a class AND read lore AND customize appearance" — pick class (then move to next screen)
- Not "view inventory AND shop AND equip" — pick one per screen
- Secondary actions (info, back, close) exist but are not emphasized
- This respects player time and reduces cognitive load

### No Dead Ends

Every state has a clear next action.

- Empty state? Show a CTA: "Create your first character" or "Claim your daily reward"
- Error state? Show "Retry" or "Go back" — never just an error message
- Loading state? Show a skeleton or spinner; never a blank screen
- Every player interaction leads somewhere; nothing strands the player

### Short Sessions

2-5 minutes per session is the target. Respect the player's time.

- Single combat should resolve in 1-2 minutes
- Character progression should feel significant in under 5 minutes
- Don't require long grinding sessions to feel progress
- Build a habit of short, repeatable sessions (daily quests, quick challenges)

### Monetization = Acceleration

Monetization should NEVER hard-block fair play.

- Battle pass? Cosmetic or battle pass-exclusive rewards, not power
- Energy/stamina system? Regenerates naturally, paid option speeds it up
- Gacha/rewards? Free players progress, paying players progress faster
- No "pay or wait 30 days" scenarios — always a free path

---

## Mobile UX Standards

Constraints specific to iOS mobile play. Hard limits, not suggestions.

### Touch Targets & Zones

- **Minimum touch target:** 48×48 points (Apple HIG standard)
- **Primary buttons:** 56pt+ (more forgiving, higher confidence)
- **Key actions:** Located in bottom 60% of screen (thumb zone on single-handed grip)
- **Top of screen:** Status, info, secondary actions only
- **Avoid:** Small buttons (<48pt), dense touch targets, horizontal scrolling in main content

### Visible Actions

- **Max 4-6 interactive elements** visible at once
- Reduces decision fatigue and visual clutter
- If you need more actions, use tabs, filters, or drill-down screens

### Typography

- **Minimum font size:** 11px (`LayoutConstants.textBadge` — for badges, small labels only)
- **Body text:** 14px or larger (`LayoutConstants.textBody`)
- **Headers:** 18px or larger (`LayoutConstants.textHeader`)
- Never go smaller than 11px for any visible text

### Interactive Element States

Every button, toggle, link, and interactive element MUST define these states:

- **Default:** Ready to interact
- **Pressed/Highlighted:** User is touching it
- **Selected/Active:** Currently chosen (for tabs, toggles)
- **Disabled:** Can't interact (grayed out, reduced opacity)
- **Loading:** Action in progress (spinner, animated state)
- **Error:** Something went wrong (red tint, error icon)
- **Success:** Action completed (checkmark, green tint)

Use `ButtonStyles.swift` to enforce consistent state styling.

### List & Collection States

Every list and collection view MUST define:

- **Loading state:** Skeleton cards or shimmer, not a spinner alone
- **Empty state:** Message + CTA, e.g., "No quests yet. Check back tomorrow!" or "Create your first character"
- **Error state:** Error message + "Retry" button
- **Data state:** Normal list with clear item structure
- **Pull-to-refresh:** If data can change, support refresh

### Loading Patterns

Order of preference:

1. **Skeletons** — Show layout with placeholder content, feels like content is there
2. **Spinners** — Animated loading indicator, acceptable for short waits
3. **Blank screens** — Avoid; only use if truly unavoidable

Load in the background when possible; don't block interaction longer than 2 seconds.

---

## Design System Enforcement

All UI must use design tokens. Do NOT hardcode styles.

### Required Files & Tokens

**Theme tokens:** `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- Colors: `.gold`, `.bgPrimary`, `.textPrimary`, `.borderGold`, etc.
- Fonts: `.headline`, `.body`, `.caption`, etc.
- **Verify tokens exist before using** — do not guess names

**Button styles:** `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- Styles: `.primary`, `.secondary`, `.neutral`, `.ghost`, `.socialAuth`, `.danger`, etc.
- **Check signature** — some take parameters (`.primary(enabled:)`), some don't
- **Verify style exists** before using — never inline button styling

**Layout constants:** `Hexbound/Hexbound/Theme/LayoutConstants.swift`
- Spacing: padding, margins, gaps between elements
- Font sizes: for body, headers, badges, etc.
- Touch target sizes: button heights, icon sizes
- **Use these for all spacing** — never hardcode `.padding(16)` or `.frame(height: 44)`

### Common Mistakes (NEVER DO)

- `.accent`, `.primary` (as color), `.background`, `.text` — these DO NOT EXIST
- `Color(hex: "...")` — use theme tokens instead
- `Font.system(...)` — use theme tokens instead
- `.frame(height: 44)` — use `LayoutConstants.buttonHeight` instead
- `.padding(20)` — use `LayoutConstants.spacing` constants instead
- Inline opacity, blur, shadow — define these in ButtonStyles or extend theme

---

## Canonical Components

Check this list before creating new components. We already have:

- `panelCard()` — Styled card/panel container
- `GoldDivider()` — Gold accent line divider
- `TabSwitcher` — Tab/segmented control component
- `HubLogoButton` — Game logo button (navigation)
- `ActiveQuestBanner` — Quest status banner component
- Skeleton cards — Loading placeholders
- Empty state components — Encourage next action
- Error state components — Show problem + retry option

Location: `Hexbound/Hexbound/Views/Components/`

Before proposing a new component:
1. Check if it already exists in Components/
2. Check if it can be built from existing components
3. If truly new, create it and add it to this list

---

## Screen Design Output Format

When designing a new screen, document:

1. **Goal** — What is the player trying to do? (one sentence)
2. **Primary Action** — The main CTA (button text, gesture)
3. **Secondary Actions** — Back, info, menu, etc. (in order of importance)
4. **Data Display** — What info is shown? How is it laid out?
5. **Layout Structure** — Zones: top (info), middle (content), bottom (action)
6. **States** — Loading, empty, error, success, disabled (mockups or description)
7. **Design System Tokens** — Which colors, fonts, spacing from the theme?

Example:

```
QUEST DETAIL SCREEN
Goal: Understand quest objective and claim reward
Primary Action: "Claim Reward" button (56pt, primary style, bottom center)
Secondary: "Abandon" link (secondary style), back button (top left)
Data: Quest title, description, reward preview, completion status
Layout:
  - Top: Quest title, quest icon
  - Middle: Objective text, reward details (in panelCard)
  - Bottom: "Claim Reward" button (full width, 56pt)
States:
  - Loading: Skeleton of quest details
  - Incomplete: "Claim Reward" disabled, countdown timer visible
  - Claimable: "Claim Reward" enabled, primary style (gold highlight)
  - Claimed: Screen transitions to reward screen
Tokens: .gold border on panelCard, .textPrimary for body, .buttonHeight for CTA
```

---

## UX Audit Format

When reviewing existing screens or auditing UX quality:

### Start with Strengths (3-5 items)

What's working well? Be specific.

✅ Clear primary action in thumb zone
✅ Gold dividers create visual hierarchy
✅ Loading skeleton matches final layout perfectly
✅ Empty state has clear next step ("Check back tomorrow!")

### Then Issues (What → Problem → Impact → Fix → Priority)

For each issue:

❌ **What:** Quest progress bar not visible on listing screen
**Problem:** User can't see quest completion status at a glance
**Impact:** Player may abandon quest thinking it didn't progress
**Fix:** Add small progress indicator badge to quest card (secondary color, top-right)
**Priority:** High

### Reference Real Tokens

Cite actual tokens from the design system:

- ✅ "Use `.gold` border instead of `Color(red: ...)`"
- ❌ "Make the border more blue" (too vague, doesn't reference token)

### Check Existing Components

- ✅ "Use existing `panelCard()` wrapper for consistency"
- ❌ "Create a new card style" (when `panelCard` exists)

---

## Game Systems Checklist

Every UX decision must account for these factors:

### Retention Hooks

- **Why return?** Daily rewards, limited-time events, progression markers
- **Consequence of not playing:** Missing daily bonuses, falling behind (perceived, not actual)
- **Short-term wins:** XP gain, level-up notifications, loot drop feedback

### Fairness (Anti-Exploit)

- **Server authority:** Client never calculates combat, rewards, economy values
- **Anti-cheat:** No offline progression, no client-side cheating vectors
- **Balance:** No pay-to-win hard blocks; monetization is acceleration only

### Progression Clarity

- **Visible path:** Player always knows what level they are, what's next, how far until next milestone
- **Unlocks & gates:** Clear explanation of why content is locked and how to unlock
- **Numbers & feedback:** XP gain, health damage, cooldown timers — always visible

### Reward Anticipation

- **Loot tables & odds:** If randomized, show the odds (battle pass, gacha rewards)
- **Milestone visibility:** "2 more quests until next level" creates anticipation
- **Streak breaking:** Losing or failing feels bad — anti-frustration design (retry, no penalty, daily reset)

### Economy Health

- **Inflation/deflation:** Track gold spending vs. earning. If earning > spending, economy breaks
- **Sink systems:** Gold sinks keep economy stable (cosmetics, rerolls, upgrades)
- **Pacing:** Early game rewards feel generous (retention), late game paces slower (prevent burnout)

### Anti-Frustration After Losses

- **Quick reset:** Can't retry immediately? Show cooldown and next attempt time
- **Consolation:** Losing a battle gives some XP or minor rewards (not nothing)
- **Not punishing:** Losses never result in net negative progress (no item loss, no rank resets)
- **Narrative framing:** "You were defeated" vs. "Your party needs rest" (tone matters)

### First-Session Friendliness

- **Onboarding:** Tutorial teaches core loop in <2 minutes
- **Clear tooltips:** New mechanics explained inline, not in a help screen
- **Early wins:** First quest felt easy and rewarding; confidence building
- **No walls:** No paywalls, level locks, or long waits in first session

### Live Ops Extensibility

- **Event slots:** Is there room to plug in new events, seasonal content, limited-time bosses?
- **Battle pass ready:** Screen design supports pass tiers, rewards, cosmetics
- **Shop extensibility:** Can new items be added without redesign?
- **Analytics hooks:** Can you track which screens players visit, which actions they take?

---

## Checklist: New Screen Design

Before submitting a new screen design:

- [ ] Goal is clear (one sentence)
- [ ] Primary CTA is 56pt+ and in thumb zone (bottom 60%)
- [ ] Max 4-6 visible actions
- [ ] Uses DarkFantasyTheme tokens (no hardcoded colors)
- [ ] Uses ButtonStyles (no inline styling)
- [ ] Uses LayoutConstants (no hardcoded spacing)
- [ ] Loading, empty, error, success states defined
- [ ] 3-second rule test: Can I understand this in 3 seconds?
- [ ] No dead ends: Every state has a next action
- [ ] Existing components checked: Not reinventing panelCard(), GoldDivider, etc.
- [ ] Game systems considered: retention, fairness, progression, rewards, economy, anti-frustration, first-session, live ops

---

## Checklist: UX Audit

When auditing a screen:

- [ ] Start with strengths (3-5 items)
- [ ] List issues: What → Problem → Impact → Fix → Priority
- [ ] Reference real design tokens from DarkFantasyTheme.swift, ButtonStyles.swift, LayoutConstants.swift
- [ ] Suggest existing components before proposing new ones
- [ ] Test 3-second rule on the screen
- [ ] Check for dead ends (empty, error states have CTAs)
- [ ] Verify touch targets are 48pt+ (56pt+ for primary buttons)
- [ ] Check for consistent state coverage (default, pressed, disabled, loading, error, success)

---

## Additional Resources

- **Design system tokens:** `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- **Button styles:** `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- **Layout constants:** `Hexbound/Hexbound/Theme/LayoutConstants.swift`
- **Components:** `Hexbound/Hexbound/Views/Components/`
- **Art style:** `docs/08_prompts/ART_STYLE_GUIDE.md`
- **Development rules:** `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md`
