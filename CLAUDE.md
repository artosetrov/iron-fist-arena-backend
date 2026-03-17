# Hexbound — Project Rules

## Xcode Project File (CRITICAL)

When creating ANY new `.swift` file in the `Hexbound/` iOS app, you MUST also add it to `Hexbound/Hexbound.xcodeproj/project.pbxproj`.

Each new file requires entries in **4 sections** of `project.pbxproj`:

1. **PBXBuildFile** — `{ID1} /* FileName.swift in Sources */ = {isa = PBXBuildFile; fileRef = {ID2} /* FileName.swift */; };`
2. **PBXFileReference** — `{ID2} /* FileName.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileName.swift; sourceTree = "<group>"; };`
3. **PBXGroup** — Add `{ID2} /* FileName.swift */,` to the correct group's `children` array (match the folder the file lives in, e.g. Auth, Components, Network)
4. **Sources build phase** — Add `{ID1} /* FileName.swift in Sources */,` to the `PBXSourcesBuildPhase` `files` array

Generate unique 24-character hex IDs for `{ID1}` and `{ID2}`. Keep entries alphabetically sorted within each section.

**If you skip this step, the file will NOT compile in Xcode.**

## Design System

- Always use `DarkFantasyTheme` color/font tokens — never hardcode `Color(hex:)` or raw color values
- Always use `ButtonStyles.swift` styles (`.primary`, `.secondary`, `.neutral`, etc.) — never inline button styling
- Always use `LayoutConstants` for spacing/sizing — minimum font size is `LayoutConstants.textBadge` (11px)
- The theme file is at `Hexbound/Hexbound/Theme/DarkFantasyTheme.swift`
- Button styles are at `Hexbound/Hexbound/Theme/ButtonStyles.swift`
- Layout constants are at `Hexbound/Hexbound/Theme/LayoutConstants.swift`

## Art Style (for AI image generation prompts)

- Full art style guide: `Hexbound/ART_STYLE_GUIDE.md`
- Style: pen and ink illustration, bold black ink outlines, muted earth tones + 1-2 saturated accent colors, grimdark dark fantasy, isolated on white/transparent background
- Reference: D&D Monster Manual / Pathfinder rulebook illustrations (NOT digital painting, NOT concept art, NOT anime)
- Always start prompts with `Pen and ink illustration of...`
- Always end with `isolated on white background, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text`
- The icon `icon-gold-mine` is in a DIFFERENT casual/cartoon style — do NOT use as art style reference

## Architecture

- State management: `@MainActor @Observable` classes
- Navigation: `NavigationStack` with `AppRouter`
- Cache: `GameDataCache` environment object, cache-first pattern
- Views pass `@Bindable var vm` to child components (not `@State`)
