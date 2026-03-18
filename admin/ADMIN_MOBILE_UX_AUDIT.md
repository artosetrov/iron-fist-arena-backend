# Hexbound Admin Panel — Consolidated UX / Mobile / Forms / Accessibility Audit

> **Date:** 2026-03-18
> **Scope:** Admin panel (Next.js 15 + React 19 + Tailwind 4 + Radix UI)
> **Frameworks applied:** UX Heuristic Review, Mobile UX Review, Form Design Review, WCAG 2.1 AA Accessibility Audit

---

## Executive Summary

Админка функционально мощная (38 страниц, balance sim, CRUD, liveops), но **собиралась desktop-first без мобильной адаптации**. После первого прохода мобильной адаптации (sidebar → sheet, responsive grids, dialog scroll) осталось **23 issue** разной критичности.

| Severity | Count |
|----------|-------|
| Critical | 4 |
| Major | 9 |
| Minor | 10 |

---

## 1. UX Design Review (Nielsen Heuristics)

### H1 — Visibility of System Status ⚠️ MAJOR

- **Нет loading states** — при загрузке данных в DataTable, items, offers, passives не показывается skeleton/spinner. Пользователь видит пустой экран.
- **Нет индикатора активных фильтров** — после поиска в DataTable нет визуального badge "filtered" рядом с search.
- **Delete** — после удаления нет toast/notification об успехе. Пользователь не знает, сработало ли.

**Fix:** Добавить `<Skeleton />` компонент для таблиц. Добавить toast system (уже есть `@radix-ui/react-toast` в deps). Показывать badge "N results" при активном поиске.

### H3 — User Control and Freedom ⚠️ MAJOR

- **Delete без undo** — удаление записи мгновенное и необратимое. Нет soft-delete или undo toast.
- **Нет bulk undo** — если случайно удалил запись в generic table browser, данные потеряны.

**Fix:** Добавить confirmation dialog перед delete (уже есть AlertDialog в UI). Рассмотреть soft-delete + undo toast (30 сек window).

### H4 — Consistency and Standards ⚠️ MINOR

- **Смешанные паттерны навигации** — некоторые страницы используют tabs (item-balance), другие — cards (tables), третьи — plain lists (quests). Это ок для разных use-cases, но onboarding может быть confusing.

### H5 — Error Prevention 🔴 CRITICAL

- **Delete button в icon-only формате** рядом с Edit — промахнуться легко, особенно на мобилке. Touch targets кнопок `h-9 w-9` (36px) — **ниже 44px минимума**.
- **Нет confirmation для destructive actions** в DataTable — `onDelete` вызывается напрямую.

**Fix:** Добавить `AlertDialog` перед каждым delete. Увеличить touch target icon-only кнопок до 44px. Разнести Edit и Delete кнопки на мобилке.

### H6 — Recognition over Recall ⚠️ MINOR

- **Icon-only actions** (Edit/Delete в таблицах) — только `title` атрибут, который не работает на touch devices. Нет tooltip, нет label.

**Fix:** Добавить Tooltip component (есть `@radix-ui/react-tooltip` в deps) на все icon-only кнопки.

### H8 — Aesthetic and Minimalist Design ⚠️ MINOR

- **27 пунктов навигации** в sidebar — слишком много. Нужна группировка по категориям (Content, Balance, LiveOps, Analytics, System).

---

## 2. Mobile UX Review

### Overall Mobile Readiness: **Needs Work** (было Not Ready, стало лучше после первого прохода)

### ✅ Что уже работает после адаптации:
- Sidebar → Sheet drawer с hamburger
- Desktop sidebar hidden на `<md`
- Layout `md:pl-64` — контент не обрезается
- Grids responsive (grid-cols-1 → sm:grid-cols-2 → lg:grid-cols-4)
- Dialog scrollable с max-h-85vh
- DataTable pagination стэкается вертикально
- Login page — уже responsive из коробки

### 🔴 Critical — Touch Targets

- **Button `size="icon"`: h-9 w-9 = 36px** — ниже 44px минимума (WCAG 2.5.8, Apple HIG)
- **Button `size="sm"`: h-8 = 32px** — слишком маленькие для primary mobile interactions
- **Select trigger `h-8`** в settings — 32px, сложно тапнуть
- **Sort headers в DataTable** — весь `<th>` кликабелен, но tap target по вертикали только `py-2.5` = ~34px

**Fix:** Добавить mobile-specific размеры:
```tsx
// button.tsx — добавить
size: {
  // ...existing
  'icon-mobile': 'h-11 w-11',  // 44px
  'sm-mobile': 'h-11 px-4',    // 44px height
}
```
Или проще — на `<md` увеличить padding через responsive classes.

### ⚠️ Major — Input Font Size

- **Input `text-sm` (14px)** — на iOS при фокусе на input с font-size < 16px **браузер автоматически зумит страницу**. Это ломает layout.

**Fix:**
```tsx
// input.tsx
'text-sm md:text-sm text-base' // 16px на мобилке, 14px на десктопе
```

### ⚠️ Major — Table Readability

- DataTable на мобилке рендерит полную таблицу с горизонтальным скроллом. Для таблиц с 10+ колонками это **unusable**.
- Нет sticky first column — при скролле теряется контекст "какая это строка".

**Fix:** Рассмотреть card-based view для мобилки (каждая строка → card). Или sticky first column:
```css
th:first-child, td:first-child {
  position: sticky;
  left: 0;
  z-index: 10;
  background: var(--color-card);
}
```

### ⚠️ Major — Sidebar Navigation Scroll

- 27 nav items при высоте viewport ~667px (iPhone) — нижние пункты требуют значительного скролла.
- Нет группировки/accordions.

**Fix:** Добавить collapsible nav groups:
- 📦 Content (Items, Consumables, Passives, Skills, Appearances, Assets)
- ⚔️ Gameplay (Dungeons, Quests, Achievements, Events, Seasons)
- 💰 Economy (Offers, Loot, Battle Pass, Daily Login, Economy, Mail)
- 📊 Balance (Item Balance, Simulation, Validation, Profiles)
- 👥 Players (Players, Matches, Push)
- ⚙️ System (Settings, Config, Flags, Tables, Snapshots, Balance)

### ⚠️ Minor — Safe Area

- Нет padding для bottom safe area (iPhone home indicator = 34px). Sheet drawer и sticky elements могут перекрываться.

**Fix:** Добавить `pb-safe` или `env(safe-area-inset-bottom)` для Sheet footer и mobile pagination.

---

## 3. Form Design Review

### Login Form — Assessment: **Needs Work**

| Check | Status |
|-------|--------|
| Visible persistent labels | ✅ `<Label>` above each field |
| Required/optional indicated | ❌ Not marked |
| Password show/hide toggle | ❌ Missing |
| Inline validation | ❌ Only on submit |
| Correct input types | ✅ `type="email"`, `type="password"` |
| Autocomplete attributes | ✅ `autoComplete="email"`, `autoComplete="current-password"` |
| Error messages: problem + fix | ⚠️ Generic "Login failed" |
| Input height ≥ 48px on mobile | ❌ h-9 = 36px |
| Input font ≥ 16px on mobile | ❌ text-sm = 14px |

**Fixes needed:**
1. Add password visibility toggle
2. Increase input height to h-12 (48px) on mobile
3. Change font to text-base (16px) on mobile inputs
4. Better error messages: "Wrong password" vs "Account not found"

### DataTable Edit Dialog — Assessment: **Major Issues**

- Формы генерируются динамически из schema — нет control over field types
- **Нет validation** — можно отправить пустые required fields
- **Нет error recovery** — если сервер возвращает ошибку, форма закрывается (?)
- Нужно проверить: сохраняется ли input при ошибке

### Settings Page — Assessment: **Minor Issues**

- Role selector `w-[140px] h-8` — слишком маленький для мобилки
- Нет confirmation при смене роли пользователя (destructive action)

---

## 4. Accessibility Audit (WCAG 2.1 AA)

### Compliance Summary
- **WCAG 2.1 AA Status:** FAIL
- Critical violations: 4
- Major violations: 5
- Minor violations: 3

### 🔴 Critical Violations

**C1. Touch targets below 44px** (WCAG 2.5.8)
- Button `size="icon"`: 36px
- Button `size="sm"`: 32px
- Select triggers in settings: 32px
- **Impact:** Users with motor impairments cannot reliably tap controls.

**C2. Input font < 16px causes iOS zoom** (Usability / WCAG 1.4.4)
- All inputs use `text-sm` (14px) — iOS Safari auto-zooms, breaking layout.
- **Fix:** `text-base` on mobile.

**C3. Color-only status indicators** (WCAG 1.4.1)
- Boolean badges in DataTable: green "true" / red "false" — color + text is ok, BUT...
- DB connection status in settings: green dot = connected, red = error — **no text label for the dot**.
- FK/PK indicators: purple "PK", yellow "FK" — rely on color for distinction.

**C4. Sortable table headers lack ARIA** (WCAG 4.1.2)
- `<th>` elements are clickable but have no `role="button"`, no `aria-sort`, no keyboard support (Enter/Space).
- Screen readers cannot identify these as interactive or know the sort state.

**Fix:**
```tsx
<th
  role="columnheader"
  aria-sort={sortColumn === col ? (sortDir === 'asc' ? 'ascending' : 'descending') : 'none'}
  tabIndex={0}
  onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') handleSortClick(col) }}
>
```

### ⚠️ Major Violations

**M1. Icon-only buttons without aria-label** (WCAG 4.1.2)
- Edit/Delete buttons in DataTable use `title` but **no `aria-label`**. `title` is not reliably announced by screen readers.
- Hamburger menu button has `sr-only` text — ✅ this one is fine.

**M2. No focus visible ring on table rows** (WCAG 2.4.7)
- Table rows have `hover:bg-muted/30` but no `focus-visible` style for keyboard navigation.

**M3. CollapsibleJson button lacks aria-expanded** (WCAG 4.1.2)
- The expand/collapse JSON button doesn't communicate state to screen readers.

**M4. Missing skip-to-content link** (WCAG 2.4.1)
- No skip link to bypass sidebar navigation.

**M5. Dialog lacks aria-describedby** (Best practice)
- AlertDialog and Dialog don't always have `DialogDescription`, which means screen readers may not announce the purpose.

### ⚠️ Minor Violations

**m1. Heading hierarchy** — Dashboard h1 is fine, but sub-pages may skip levels.

**m2. No `prefers-reduced-motion`** — animations on Sheet/Dialog use CSS animations without respecting user preference.

**m3. Link/text contrast** — `text-muted-foreground: #a1a1aa` on `background: #09090b` = contrast ratio ~6.8:1 ✅ passes. But `text-muted-foreground` on `card: #0a0a0f` = similar ratio, fine. **Primary `#a78bfa` on `#09090b`** = ~6.2:1 ✅ passes.

---

## Priority Action Plan

### P0 — Fix before next deploy (Critical)

1. **Add `aria-label` to all icon-only buttons** (Edit, Delete, Sort, Collapse)
2. **Add `aria-sort` + keyboard support to sortable table headers**
3. **Add AlertDialog confirmation before every delete action**
4. **Fix input font to 16px on mobile** (`text-base md:text-sm`)

### P1 — Fix this sprint (Major)

5. **Increase touch targets to 44px minimum on mobile** (buttons, select triggers)
6. **Add loading/skeleton states** for DataTable and card grids
7. **Add toast notifications** for CRUD success/error feedback
8. **Group sidebar navigation** into collapsible categories
9. **Add sticky first column** to DataTable on mobile
10. **Add password visibility toggle** to login form
11. **Add skip-to-content link** in dashboard layout
12. **Add `prefers-reduced-motion` media query** to animations
13. **Fix settings role selector** — increase size on mobile

### P2 — Backlog (Minor)

14. Add tooltips to icon-only buttons (Radix Tooltip)
15. Add CollapsibleJson `aria-expanded` attribute
16. Add empty state illustrations (not just "No records found")
17. Add filter badge showing active search/sort state
18. Improve login error messages (distinguish wrong password vs. account not found)
19. Add card-based mobile view for DataTable (optional switch)
20. Add safe area padding for iOS home indicator
21. Consider dark mode contrast improvements for muted text
22. Add `DialogDescription` to all dialog instances
23. Add autosave indicator for multi-field edit forms

---

## Checklist Summary

### Mobile Readiness
- [x] Sidebar → hamburger drawer on mobile
- [x] Responsive grid layouts
- [x] Dialog scrollable on small screens
- [x] Pagination stacks vertically
- [ ] Touch targets ≥ 44px
- [ ] Input font ≥ 16px (no iOS zoom)
- [ ] Sticky first table column
- [ ] Nav grouped for scroll reduction
- [ ] Safe area padding
- [ ] Card view for tables on mobile

### Form Design
- [x] Visible persistent labels
- [x] Correct input types
- [x] Autocomplete attributes
- [ ] Password show/hide toggle
- [ ] Required/optional indicators
- [ ] Inline validation on blur
- [ ] Better error messages
- [ ] Mobile-sized inputs (48px)

### Accessibility (WCAG 2.1 AA)
- [x] Text contrast ≥ 4.5:1
- [x] Primary color contrast passes
- [ ] Touch targets ≥ 44px
- [ ] aria-label on icon-only buttons
- [ ] aria-sort on table headers
- [ ] Keyboard navigation for sort
- [ ] Skip-to-content link
- [ ] prefers-reduced-motion
- [ ] Color-independent status indicators
- [ ] Focus visible on all interactive elements
