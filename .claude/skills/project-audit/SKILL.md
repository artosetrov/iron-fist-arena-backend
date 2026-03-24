# Full Project Audit

> Trigger: "full audit", "аудит проекта", "project audit", "health check", or periodically.

## Purpose
Comprehensive health check of the entire Hexbound project across all dimensions.

## Audit Zones

### Zone 1 — Code Quality (iOS)
Run error-scanner skill checks:
- Hardcoded colors, missing theme prefix
- Force unwraps
- SFX enum misuse
- ButtonStyle ternary
- pbxproj integrity (ghost refs, junk files)
- Missing states on interactive elements

### Zone 2 — Code Quality (Backend)
- Try/catch on all routes
- PII in logs
- Missing `await` on async functions
- N+1 query patterns
- TOCTOU in purchase routes
- Atomic increments

### Zone 3 — Schema & Data
- Prisma schema sync (backend == admin)
- Migration status (all applied, not just resolved)
- Orphan tables/columns
- Missing indexes

### Zone 4 — API Contracts
- All routes documented
- Frontend models match backend responses
- CodingKeys correct (only when backend sends snake_case)
- Error handling consistent

### Zone 5 — Design System
- Run design-compliance skill
- Check all screens for token usage
- Verify ornamental patterns
- Check component reuse

### Zone 6 — Admin Coverage
- Run admin-coverage skill
- Check all game features have admin support
- Verify live config completeness

### Zone 7 — Documentation
- Run doc-freshness skill
- Check CLAUDE.md accuracy
- Verify all docs are current

### Zone 8 — Game Systems
- Economy balance (sources/sinks)
- Progression curve
- Combat fairness
- Reward coherence

### Zone 9 — Release Readiness
- Run release-checklist skill
- Build status
- Deploy pipeline health

### Zone 10 — Analytics & LiveOps
- Event tracking coverage
- Funnel completeness
- LiveOps tool readiness

## Output Format
Per zone:
```
ZONE: [name]
HEALTH: 🟢 Good / 🟡 Warnings / 🔴 Critical
FINDINGS: [list]
ACTIONS: [prioritized fixes]
```

Final summary:
```
OVERALL HEALTH: [assessment]
CRITICAL ISSUES: [count] — [list]
HIGH PRIORITY: [count] — [list]
MEDIUM: [count]
LOW: [count]
TOP 5 ACTIONS: [ordered list]
```
