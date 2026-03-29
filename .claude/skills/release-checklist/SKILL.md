# Release Stability Checklist

> Trigger: "release check", "ready to deploy?", "release checklist", "preflight", or before any deploy/push.

## Purpose
Verify the project is safe to deploy to production.

## Pre-Deploy Checklist

### 1. Code Quality
- [ ] No merge conflict markers: `grep -rn "^<<<<<<<\|^=======\$\|^>>>>>>>" . --include="*.swift" --include="*.ts" --include="*.tsx" --include="*.prisma" | grep -v node_modules | grep -v .git/`
- [ ] No force unwraps in Swift (except hardcoded URL literals with swiftlint comment)
- [ ] No PII in logs
- [ ] No `console.log` with email/password/token
- [ ] No `ignoreBuildErrors` in next.config

### 2. Backend Build
- [ ] `cd backend && npx prisma generate && npx next build` passes
- [ ] No TypeScript errors
- [ ] All `await` on async functions (especially `getGameConfig`, `runCombat`, `calculateCurrentStamina`)
- [ ] Try/catch on all API route handlers

### 3. Schema Sync
- [ ] `diff backend/prisma/schema.prisma admin/prisma/schema.prisma` — no differences
- [ ] Migrations applied (not just marked as applied)
- [ ] Verify tables exist: `SELECT table_name FROM information_schema.tables WHERE table_schema='public'`

### 4. Admin Build
- [ ] `cd admin && npx next build` passes
- [ ] Admin subtree ready: `git subtree push --prefix=admin admin-deploy main` (or via watcher)

### 5. iOS Build
- [ ] No junk files in `.xcodeproj`: `ls Hexbound/Hexbound.xcodeproj/ | grep -E '\.(bak|backup|tmp)$'`
- [ ] All new Swift files in pbxproj (4 sections)
- [ ] Xcode build succeeds

### 6. Environment
- [ ] All required env vars set on Vercel
- [ ] No secrets in committed code
- [ ] Database connection healthy

### 7. Rollback Plan
- [ ] Previous working commit identified
- [ ] Rollback procedure documented
- [ ] Database migration is reversible (or has manual rollback SQL)

## Output
```
✅ READY TO DEPLOY — all checks passed
⚠️ DEPLOY WITH CAUTION — [warnings]
❌ DO NOT DEPLOY — [blockers]
```

---

## Agent Bus (Team Communication)

> Ты часть Agent Team. После завершения работы — запиши результат в bus. Перед началом — проверь bus на сообщения от других агентов.

### При старте
1. `ls .claude/agent-bus/` — проверь есть ли файлы от других агентов
2. Прочитай `.md` файлы (кроме `PROTOCOL.md`, `AGENT_HEADER.md`) — это результаты других агентов
3. Проверь секцию `## Alerts` — если есть `@{твоё-имя}` или `@ALL`, обработай

### При завершении
Запиши результат: `Write tool → .claude/agent-bus/{твоё-имя}.md`

Формат:
```markdown
# {Name} — Result
timestamp: {now}
status: OK | WARNING | BLOCKED

## Findings
- ...

## Decisions
- ...

## Alerts
- @{agent}: описание (если нашёл проблему для другого агента)

## Files Changed
- path/to/file (action)
```
