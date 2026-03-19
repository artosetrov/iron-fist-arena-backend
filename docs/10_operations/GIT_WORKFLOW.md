# Hexbound — Git Workflow

*Source of truth: this file + actual git config. Updated: 2026-03-19*

---

## Repository Structure

**1 local monorepo → 2 GitHub remotes**

| Remote | Repo | Contents | Deploy target |
|--------|------|----------|---------------|
| `origin` | `artosetrov/iron-fist-arena-backend` | Full monorepo | Backend → Vercel |
| `admin-deploy` | `artosetrov/iron-fist-arena-admin` | Admin subtree only | Admin → Vercel |

## Branch Strategy

```
main (production — always deployable)
  ↑ merge via PR (preferred) or direct push (solo dev ok)
feature/xxx (short-lived, 1-3 days)
```

- `main` = production. Every push triggers Vercel auto-deploy for backend.
- `feature/*` = development branches. Create for non-trivial changes.
- No develop/staging/release branches needed at current scale.

## Daily Workflow

### Quick fix (1-2 files, low risk)

```bash
# Work directly on main
git add <files>
git commit -m "fix: description"
git push origin main
```

### Feature work (multi-file, any risk)

```bash
# Create feature branch
git checkout -b feature/arena-redesign

# Work, commit as needed
git add .
git commit -m "feat: arena redesign"

# Push for CI check + Vercel preview
git push origin feature/arena-redesign

# Merge to main when ready
git checkout main
git merge feature/arena-redesign
git push origin main

# Clean up
git branch -d feature/arena-redesign
```

## Admin Deploy (IMPORTANT — Extra Step)

Admin panel lives in `admin/` subfolder but deploys from a **separate GitHub repo**.
After pushing to `origin main`, you must also push the admin subtree:

```bash
# After git push origin main:
git subtree push --prefix=admin admin-deploy main
```

**If you forget this step, admin panel will NOT update.**

### If subtree push fails (common after force push or rebase)

```bash
git subtree split --prefix=admin -b admin-subtree
git push admin-deploy admin-subtree:main --force
git branch -D admin-subtree
```

## Git Tags for Releases

```bash
# After iOS TestFlight upload
git tag ios-v1.0.1-build42
git push origin --tags

# After significant backend deploy
git tag backend-v2026.03.19
git push origin --tags
```

## Branch Protection (Recommended)

When ready, enable on GitHub → Settings → Branches → `main`:

- [x] Require pull request before merging
- [x] Require status checks (CI build)
- [ ] Require approvals (not needed for solo dev)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgot admin subtree push | Run `git subtree push --prefix=admin admin-deploy main` |
| Prisma schemas out of sync | Copy `backend/prisma/schema.prisma` → `admin/prisma/schema.prisma` |
| Pushed broken code to main | Revert commit: `git revert HEAD && git push origin main` |
| Large uncommitted diff | Commit in logical chunks, not one giant commit |
