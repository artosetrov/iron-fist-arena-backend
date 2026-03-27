# Screen: {SCREEN_NAME}

> **View file:** `Hexbound/Hexbound/Views/{path}/{ScreenName}View.swift`
> **ViewModel:** `{ScreenName}ViewModel.swift`
> **Route:** `AppRoute.{routeName}`
> **Last updated:** {YYYY-MM-DD}

---

## Purpose

{Что делает экран, какая главная задача пользователя}

## Primary CTA

{Одна главная кнопка/действие}

## Layout

```
┌─────────────────────────┐
│ {header / navigation}   │
├─────────────────────────┤
│                         │
│ {main content area}     │
│                         │
├─────────────────────────┤
│ {bottom action area}    │
└─────────────────────────┘
```

## Components Used

- `{ComponentName}` — {role}
- `{ComponentName}` — {role}

## States

| State | Visual | User Action |
|-------|--------|-------------|
| Loading | {skeleton / spinner} | Wait |
| Empty | {empty CTA} | {action} |
| Error | {error toast} | Retry |
| Success | {normal content} | Interact |
| Disabled | {dimmed} | — |

## Data Sources

- ViewModel: `{ClassName}`
- Cache: `GameDataCache.{method}()`
- API: `{endpoint}`

## Navigation

- Entered from: {parent screen / route}
- Navigates to: {child screens}
- Modals/Sheets: {presented sheets}

## Design Tokens

- Corner radius: `LayoutConstants.{token}`
- Colors: `DarkFantasyTheme.{tokens}`
- Button style: `.{styleName}`

## Known Issues

- {issues}
