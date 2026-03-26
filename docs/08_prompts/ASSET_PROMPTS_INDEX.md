# Asset Prompts Index

Master index of all AI image generation prompt collections for the Hexbound project.

*Updated: 2026-03-19*

---

## Prompt Collections

| Collection | Purpose | File Location | Status | Prompts |
|---|---|---|---|---|
| Boss Sprites | Full-body boss character art, combat ready | `docs/08_prompts/BOSS_SPRITES_PROMPTS.md` | Active | Multiple bosses |
| Class Icons | Character class selection icons (Warrior, Mage, Rogue, etc.) | `docs/08_prompts/CLASS_ICONS_PROMPTS.md` | Active | 6+ classes |
| Race Icons | Race/origin selection icons | `docs/08_prompts/RACE_ICONS_PROMPTS.md` | Active | Multiple races |
| HUD Icons | In-game UI icons: stamina, health, mana, resources | `docs/08_prompts/HUD_ICONS_PROMPTS.md` | Active | 10+ icons |
| UI Icons | Generic UI elements: buttons, menus, settings | `docs/08_prompts/UI_ICONS_PROMPTS.md` | Active | 15+ icons |
| Combat Sprites | Combat action animations: attack, defend, cast, etc. | `docs/08_prompts/COMBAT_SPRITES_PROMPTS.md` | Active | Multiple actions |
| Combat Result Icons | End-of-combat state icons: victory, defeat, loot, XP | `docs/08_prompts/COMBAT_RESULT_ICONS_PROMPTS.md` | Active | 6+ states |
| Loading Screens | Full-screen loading screen artwork | `docs/08_prompts/LOADING_SCREENS_PROMPTS.md` | Active | Multiple variations |
| Preloader Icon | Spinning/animated preloader asset | `docs/08_prompts/PRELOADER_ICON_PROMPT.md` | Active | 1 asset |
| Hero Characters | Player character full-body art (various classes/races) | `Hexbound/HERO_PROMPTS.md` | Active | Multiple variations |
| Hub City | Hub/city background and location art | `docs/08_prompts/hexbound_hub_city_prompts.md` | Active | Location variations |
| Logo | Game logo design variations and concepts | `docs/08_prompts/hexbound_logo_prompts.md` | Active | Multiple logo styles |
| Loot & Asset Icons | Gold coins, XP crystals, gems, weapons, potions | `docs/08_prompts/asset-prompts.md` | Active | 20+ assets |
| Gold Mine Cards | Minigame card illustrations for the mine game | `docs/08_prompts/mine-card-prompts.md` | Active | Multiple card designs |
| Tavern Interior | Tavern screen background (9:16) + minigame icons (shell game, fortune wheel, dice) + patron busts | `docs/08_prompts/TAVERN_INTERIOR_PROMPTS.md` | Active | 1 bg + 3 icons + 3 patrons |

---

## Archive & Duplicates

| File | Status | Notes |
|---|---|---|
| `docs/11_archive/mine-card-prompts 2.md` | Archived | Duplicate of `mine-card-prompts.md` — do not use |

---

## How to Use This Index

1. **Find the asset type you need** in the table above
2. **Open the file location** listed in the "File Location" column
3. **Use the prompts as templates** for AI image generation (DALL-E, Midjourney, etc.)
4. **Follow the style guide** at `docs/08_prompts/ART_STYLE_GUIDE.md` for consistency
5. **Verify style rules** before generating: pen and ink, bold outlines, grimdark fantasy, no painting/concept art

---

## General Guidelines

- All prompts follow the **pen and ink RPG rulebook illustration** style
- All prompts should include the standard negative prompt to avoid painting/concept art
- Reference assets in the project (see ART_STYLE_GUIDE.md) when briefing illustrators
- Keep accent colors consistent with the Hexbound color palette (earth tones + 1-2 saturated accents)
- Asset sizes follow standard retina/2x specifications (see ART_STYLE_GUIDE.md for details)

---

## Adding New Prompt Collections

When creating a new prompt collection:
1. Create a new markdown file: `[NAME]_PROMPTS.md` or `[name]-prompts.md`
2. Follow the existing template structure in other files
3. Start each prompt with `Pen and ink illustration of...`
4. End with the standard negative prompt suffix
5. Add an entry to this index with the file path and status
6. Reference `ART_STYLE_GUIDE.md` for style consistency

---

## Questions or Updates

For questions about:
- **Style standards:** See `docs/08_prompts/ART_STYLE_GUIDE.md`
- **Development rules:** See `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md`
- **Design system tokens:** See `Hexbound/Theme/DarkFantasyTheme.swift`
