# Hexbound — Archive Index

*Files moved here are superseded, duplicated, or outdated. Kept for historical reference.*
*Date archived: 2026-03-19*

## Superseded Documents

| File | Reason | Replaced By |
|------|--------|-------------|
| `PROJECT_KNOWLEDGE_v2_LEGACY.md` | References Godot (actual is Swift/iOS), outdated entity list | `docs/01_source_of_truth/PROJECT_OVERVIEW.md` |
| `CLAUDE_2_LEGACY.md` | Russian variant of rules, merged into canonical | `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` |
| `HEXBOUND_UI_UX_AUDIT_GUIDE_v1.md` | Superseded by v2 audit (B+ downgraded to B−) | `docs/07_ui_ux/UX_AUDIT.md` |
| `UI_DESIGN_DOCUMENT_LEGACY.md` | 3377-line spec, still useful as reference but superseded by design system + screen inventory | `docs/07_ui_ux/DESIGN_SYSTEM.md` + `docs/07_ui_ux/SCREEN_INVENTORY.md` |

## Audit Snapshots (point-in-time, not updated)

| File | Date | Purpose |
|------|------|---------|
| `BALANCE_AUDIT_REPORT_2026-03-09.md` | 2026-03-09 | Game balance audit (4C/8M/6L issues found) |
| `ADMIN_PANEL_AUDIT_REPORT_2026-03-16.md` | 2026-03-16 | Admin panel production readiness (6.5/10) |

## Duplicates (exact or near-exact copies)

| File | Original |
|------|----------|
| *(removed in audit block 135)* | Pure duplicates should be deleted once the canonical live source is stable |

## Feature-Specific Legacy Docs

| File | Purpose |
|------|---------|
| `PROMPT_HUB_CITY_IMPLEMENTATION.md` | Hub city feature implementation notes |
| `COMBAT_SPRITES_LIST.md` | Inventory list of combat sprite assets |

---

## Policy

- **Do not delete historical docs blindly** — preserve archive files when they still carry unique forensic or historical context
- **Do delete pure duplicates** once their canonical live source is stable and referenced elsewhere
- **Do not reference** archive files as current documentation
- **Do update** active docs in `/docs/01-10_*/` when implementation changes
