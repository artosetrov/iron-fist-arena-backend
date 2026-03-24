# Admin Coverage Check

> Trigger: "admin check", "проверь админку", "admin coverage", or when any new backend feature is added.

## Purpose
Ensure every manageable game feature has proper admin panel support.

## Workflow

### Step 1 — Identify Feature Type
Classify the feature:
- **Content**: items, quests, achievements, dungeons, events → needs CRUD in admin
- **Config**: balance values, rates, limits → needs live config param
- **Economy**: prices, rewards, currencies → needs economy dashboard visibility
- **User management**: bans, resets, grants → needs moderation tools
- **Seasonal/LiveOps**: battle pass, events, offers → needs scheduling/management

### Step 2 — Check Existing Admin Pages
Read `docs/05_admin_panel/ADMIN_CAPABILITIES.md` and verify:
- Does a relevant admin page exist?
- Does it cover view/edit/create/delete as needed?
- Does it show related metrics/stats?

### Step 3 — Check Live Config
For any tunable value:
- Is it in `live-config.ts`?
- Is there an admin page to change it?
- Does changing it take effect without deploy?

### Step 4 — Gap Analysis
List what's missing:
- Missing admin pages
- Missing config params
- Missing moderation tools
- Missing visibility/monitoring

### Step 5 — Prisma Schema Sync
Verify `admin/prisma/schema.prisma` matches `backend/prisma/schema.prisma`.
```bash
diff backend/prisma/schema.prisma admin/prisma/schema.prisma
```

## Output
```
FEATURE: [name]
ADMIN STATUS: Covered / Partial / Missing
GAPS: [list]
PRIORITY: Critical / High / Medium / Low
ACTION: [what to build]
```
