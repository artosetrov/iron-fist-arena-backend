# Documentation Freshness Sweep

> Trigger: "doc sweep", "проверь документацию", "docs fresh?", "doc freshness", or weekly.

## Purpose
Find outdated, missing, or contradictory documentation.

## Workflow

### Step 1 — Index Check
Read `docs/01_source_of_truth/DOCUMENTATION_INDEX.md` and verify:
- All listed files exist
- No unlisted docs in `docs/` folders
- Last-updated dates are reasonable

### Step 2 — CLAUDE.md Audit
- Read CLAUDE.md sections
- Check: do referenced files still exist?
- Check: are enum values still current?
- Check: are deleted/renamed files table up to date?
- Check: are rules still applicable?

### Step 3 — Schema vs Docs
- Compare `backend/prisma/schema.prisma` with `docs/04_database/SCHEMA_REFERENCE.md`
- Any new models/fields not documented?
- Any documented models that no longer exist?

### Step 4 — API vs Docs
- List all routes in `backend/src/app/api/`
- Compare with `docs/03_backend_and_api/API_REFERENCE.md`
- Any undocumented endpoints?
- Any documented endpoints that no longer exist?

### Step 5 — Screens vs Docs
- List all View folders in `Hexbound/Hexbound/Views/`
- Compare with `docs/07_ui_ux/SCREEN_INVENTORY.md`
- Any undocumented screens?

### Step 6 — Admin vs Docs
- List admin pages in `admin/src/app/`
- Compare with `docs/05_admin_panel/ADMIN_CAPABILITIES.md`

## Output
```
CATEGORY: [docs section]
STATUS: Current / Outdated / Missing
GAPS: [specific items]
ACTION: [update needed]
PRIORITY: [Critical/High/Medium/Low]
```
