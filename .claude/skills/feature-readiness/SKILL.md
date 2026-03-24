# Feature Readiness Audit

> Trigger: "feature ready?", "готова ли фича", "readiness check", "feature audit", or before marking any feature as done.

## Purpose
Verify that a feature is truly complete across ALL dimensions — not just "code works".

## Checklist

### 1. Frontend Completeness
- [ ] All screens/components implemented
- [ ] All states: loading, empty, error, success, disabled, retry
- [ ] Navigation works correctly (push, pop, deep link if applicable)
- [ ] Design system compliance (run `design-compliance` skill)
- [ ] Accessibility: min 48pt touch targets, 4.5:1 contrast, VoiceOver labels
- [ ] Optimistic UI for mutating actions
- [ ] Skeleton loading (not spinners)

### 2. Backend Completeness
- [ ] All endpoints implemented and tested
- [ ] Input validation on all routes
- [ ] Error handling (try/catch, proper status codes)
- [ ] Rate limiting where needed
- [ ] Anti-cheat: server-authoritative for economy/combat/rewards
- [ ] No PII in logs
- [ ] TOCTOU prevention for purchase/economy routes (transaction + row lock)
- [ ] Atomic increments for counters

### 3. Data & Schema
- [ ] Prisma migration created and applied
- [ ] Schema synced: `backend/prisma/schema.prisma` == `admin/prisma/schema.prisma`
- [ ] No N+1 queries
- [ ] Indexes on frequently queried fields

### 4. Admin Coverage
- [ ] If feature needs management → admin page exists
- [ ] If feature has config → live config in admin
- [ ] If feature has economy impact → visible in admin economy dashboard

### 5. Game Design
- [ ] Feature fits core/meta loop
- [ ] Balance reviewed (sources/sinks, progression impact)
- [ ] Anti-abuse considered
- [ ] Retention hook identified

### 6. Analytics
- [ ] Key events tracked
- [ ] Funnel covered
- [ ] Anomaly detection possible

### 7. Documentation
- [ ] API docs updated (`API_REFERENCE.md`)
- [ ] Screen inventory updated (`SCREEN_INVENTORY.md`)
- [ ] Game systems docs updated if applicable
- [ ] CLAUDE.md updated if new rules/patterns discovered

### 8. QA
- [ ] Happy path verified
- [ ] Edge cases listed and checked
- [ ] Error recovery tested
- [ ] No regression in adjacent features

## Output
For each section: PASS / PARTIAL (list gaps) / FAIL (list blockers).
Overall verdict: READY / NOT READY (with specific blockers).
