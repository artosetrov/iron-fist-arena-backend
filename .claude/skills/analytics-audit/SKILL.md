# Analytics Instrumentation Audit

> Trigger: "analytics check", "проверь аналитику", "tracking audit", or when new feature affects user behavior.

## Purpose
Verify that key user actions and funnels have proper event tracking.

## Workflow

### Step 1 — Feature Events
For the feature, identify events that MUST be tracked:
- **Action events**: button taps, purchases, battles started, items used
- **Funnel events**: screen viewed, step started, step completed, step abandoned
- **Error events**: API failures, validation errors, timeout
- **Economy events**: gold earned, gold spent, gems earned, gems spent (with source/sink label)
- **Session events**: session start, session end, duration

### Step 2 — Check Backend Tracking
Verify backend logs/tracks:
- Purchase transactions
- Combat results
- Reward grants
- Level ups
- Economy transactions

### Step 3 — Check Client Tracking
Verify iOS tracks (if analytics SDK integrated):
- Screen views
- Button taps on key CTAs
- Funnel step completion
- Error encounters

### Step 4 — Funnel Coverage
For each user flow, verify the complete funnel is trackable:
- Onboarding: register → character create → tutorial → first battle
- PvP: arena enter → opponent select → fight → result → reward claim
- Shop: shop open → item view → purchase → use
- Dungeon: select → enter → room clear → boss → loot

### Step 5 — Gap Analysis
List:
- Events that should exist but don't
- Funnels that can't be analyzed
- Economy transactions without audit trail

## Output
```
FEATURE: [name]
EVENTS NEEDED: [list]
EVENTS PRESENT: [list]
GAPS: [list]
PRIORITY: [Critical/High/Medium/Low]
```
