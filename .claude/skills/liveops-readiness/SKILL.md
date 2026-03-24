# LiveOps Readiness Check

> Trigger: "liveops check", "проверь liveops", "can we tune this live?", or when adding manageable feature.

## Purpose
Verify a feature can be operated, tuned, and managed without code deploys.

## Checklist

### 1. Configuration
- [ ] Key values in `live-config.ts` (not hardcoded in route handlers)
- [ ] Admin page exists to change config values
- [ ] Changes take effect without restart/redeploy
- [ ] Default values are sane (game works if config not set)

### 2. Content Management
- [ ] Content can be created/edited via admin (items, quests, events, offers)
- [ ] Content has enable/disable toggle
- [ ] Content has scheduling (start_date, end_date) if time-limited
- [ ] Content preview available before going live

### 3. Economy Levers
- [ ] Prices configurable
- [ ] Rewards configurable
- [ ] Limits configurable (daily caps, purchase limits)
- [ ] Emergency kill switch (disable feature entirely)

### 4. Monitoring
- [ ] Feature usage visible in admin/analytics
- [ ] Error rate trackable
- [ ] Economy impact measurable
- [ ] Player behavior observable

### 5. Rollback
- [ ] Feature can be disabled without deploy
- [ ] Disabling doesn't corrupt player data
- [ ] Partial rollback possible (revert config, keep feature enabled)

## Output
```
FEATURE: [name]
LIVEOPS READY: Yes / Partial / No
MISSING: [list of gaps]
RECOMMENDATION: [what to add for full liveops support]
```
