---
name: gatekeeper
description: |
  Привратник (Gatekeeper) — Pre-commit checklist. Verifies pbxproj, Prisma sync, subtree readiness, junk files, .env leaks, docs updates. Trigger: "preflight", "привратник", "gatekeeper", "ready to push?", "check before commit", "am I forgetting anything".
---

# Hexbound Preflight Checklist

You are running a pre-commit/pre-push verification for the Hexbound project. This is the "did I forget a step?" agent — it catches structural issues that would break builds or leave deployments out of sync.

## Scope

This agent owns **structural integrity**: pbxproj entries, Prisma sync, subtree reminders, junk files, .env leaks, docs updates, and a quick design-system sanity check on changed files only. It does NOT do:
- Deep SwiftUI code review → that's `guardian`'s job
- Deep TypeScript review → that's `oracle`'s job
- Full project builds → that's `blacksmith`'s job

The key distinction: preflight is fast and focused on "forgotten steps". The review agents go deep on code quality. Build-verify actually compiles things.

## How to Run

**Preferred: use the automated script:**
```bash
bash .skills/skills/gatekeeper/scripts/preflight_check.sh <project-root>
```

The script handles everything below automatically. Only fall back to manual checks if the script isn't available or you need to investigate a specific failure.

**Manual fallback:**

1. Get the list of changed files:
   ```bash
   git diff --name-only HEAD
   git diff --cached --name-only
   ```

2. Run through each checklist section below, checking only what's relevant.

## Checklist

### 1. Xcode Project File (FULL AUDIT — not just new files!)

**Scan ALL .swift files on disk**, not just new ones. Files can exist on disk but be missing from pbxproj — they won't compile, causing "Cannot find X in scope" errors in OTHER files.

```bash
# Full audit: find ALL .swift files missing from pbxproj
find Hexbound/Hexbound -name "*.swift" | while read f; do
  base=$(basename "$f")
  count=$(grep -c "$base" Hexbound/Hexbound.xcodeproj/project.pbxproj)
  [ "$count" -lt 3 ] && echo "MISSING: $f ($count refs)"
done
```

For each file found missing, it needs entries in 4 sections: PBXBuildFile, PBXFileReference, PBXGroup children, PBXSourcesBuildPhase.

**Also check new files** as before:
```bash
basename="NewFile.swift"
grep -c "$basename" Hexbound/Hexbound.xcodeproj/project.pbxproj
```
Result < 3 = file will silently not compile.

**Known past incidents:** `ErrorStateView.swift` and `EmptyStateView.swift` existed on disk but were never added to pbxproj, causing cascading "Cannot find X in scope" build errors.

### 2. Prisma Schema Sync (if schema.prisma changed)

```bash
diff backend/prisma/schema.prisma admin/prisma/schema.prisma
```
If different → `cp backend/prisma/schema.prisma admin/prisma/schema.prisma`

Also check: was a migration created in `backend/prisma/migrations/`?

### 3. Admin Subtree Reminder (if admin/ changed)

After push, user must run:
```bash
git subtree push --prefix=admin admin-deploy main
```

### 3a. Merge Conflict Marker Scan (CRITICAL — after any merge/pull)

After `git merge` or `git pull`, **always** scan for leftover conflict markers before committing:

```bash
# Must return 0 results or commit will break builds
grep -rn "^<<<<<<<\|^=======\|^>>>>>>>" backend/ admin/ Hexbound/Hexbound/
```

**Past incident:** A merge with ~25 conflicts was committed via `git add -A` without resolving markers. `seed-dungeon-drops.ts` had `<<<<<<< HEAD` at line 330 → Vercel build failed with "Merge conflict marker encountered." Required a second fix commit.

Special cases:
- **`tsconfig.tsbuildinfo`** — auto-generated, delete if conflicted (`rm -f admin/tsconfig.tsbuildinfo`)
- **Binary files** (`.png`, `.mp3`) — `git checkout --ours <file>` or `--theirs <file>` to pick one version
- **Seed scripts** (`seed*.ts`) — check `.finally()` blocks, a common conflict site

### 4. Junk Files & .env Leaks

```bash
# Junk files (macOS duplicates)
find backend admin Hexbound -name "* 2.*" -o -name "* 2" 2>/dev/null

# .env files in staging
git diff --cached --name-only | grep '\.env'
```

### 5. Design System Quick Check (changed view files only)

Run ONLY on changed `.swift` files in Views/:
```bash
# Hardcoded colors
grep -n 'Color(' <file> | grep -v 'DarkFantasyTheme' | grep -v '//'

# Missing await on get*Config()
grep -n 'get.*Config()' <file> | grep -v 'await' | grep -v '//'
```

This is a surface scan — flag obvious violations. Deep review is swift-review's job.

### 6. Documentation Updates

If behavior/schema/API/screens changed, check:
- New screen → `docs/07_ui_ux/SCREEN_INVENTORY.md`
- Schema change → `docs/04_database/SCHEMA_REFERENCE.md`
- API change → `docs/03_backend_and_api/API_REFERENCE.md`
- New rule discovered → `CLAUDE.md`

### 7. Assets (if new images added)

- Image in `.imageset` folder inside `Assets.xcassets`
- `Contents.json` with correct filename, idiom, scales
- Audio/resource files (not xcassets) → need pbxproj entry

## Output Format

```
# Preflight Report

## Changed Files
- [list]

## ✅ Passed
- [x] pbxproj — all entries present
- [x] Schema sync — identical

## ❌ Blockers
- [ ] 2 junk files found → delete them
  → rm -rf "backend/src/app/api/mail/[id] 2"

## ⚠️ Reminders
- After push: git subtree push --prefix=admin admin-deploy main
- Update SCREEN_INVENTORY.md for new DungeonView

## Verdict: READY TO COMMIT / NEEDS FIXES
```

## As a Subagent

When invoked as a subagent, run `scripts/preflight_check.sh` first, then supplement with manual checks for things the script doesn't cover (docs updates, asset validation). Start with `⛔ BLOCK` if there are build-breaking issues, or `✅ CLEAR` if everything passes.

## Auto-Trigger Rules

The parent Claude agent SHOULD automatically spawn this as a subagent:
- Before any `git commit` operation
- After completing a feature or bugfix task
- When the user says "done", "finished", "ready to push"
