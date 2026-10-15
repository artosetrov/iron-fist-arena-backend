# Currency icons — gold / gems / XP / stamina (2026-10-15)

Замена мультяшных `icon-gold`, `icon-gems`, `icon-xp`, `icon-stamina` (искры, глянец, запечённые буквы «XP») на pen-and-ink из `ART_STYLE_GUIDE.md`. Модель `nano_banana_2_1`, 1:1, 2k, thinking medium, якорь `chest_godplate` = `1c5bda93-1f54-4c55-9261-c03d3d8fe087` (image_references).

## Где живут

| Ассет | Источник (job id) | Ключ | Где используется |
|---|---|---|---|
| `icon-gold` + `reward-gold` (был тот же файл) | `c4d94b97-54b3-4355-ba41-94e3d40ee643` | magenta | CurrencyDisplay, Daily Login, QuestRewardCell, ClaimRewardModalView, BattleResultSections, Fortune Wheel |
| `icon-gems` | `df72cd5a-dfb7-4dcb-b622-55d0c83ba083` | green | CurrencyDisplay, Daily Login, QuestRewardCell, MineClaimRewardView |
| `icon-xp` + `reward-xp` | `d50969da-d3b0-48b3-ab9e-46dfed47f665` | magenta | QuestRewardCell, DailyQuests fallback, BattlePass, Dungeon Rush, Hub banners, SessionSummary, ClaimRewardModalView |
| `icon-stamina` | `d0d575a5-05c2-434c-ba7f-c9bb111337e3` | magenta | UnifiedHeroWidget, HeroInventoryTab, DungeonRushStart, BattlePass, Daily Login (стамина-зелья) |

Отклонённые кандидаты: бледная куча монет `4f2d4897…` / `54e08d78…` (цвет кости, не золото), сырой осколок `e453400a…`, камень в когтях `93b06579…` (шум на 16pt), книга со звездой `33ec4aac…`, колба с молнией `21291d0c…` (читается как обычное зелье).

## Правила

- Без букв: XP передаётся медалью со звездой (гайд запрещает текст в арте).
- Читаемость проверена на 16pt (HUD), 44pt (сетка Daily Login), ~110pt (витрина).
- Палитра совпадает с `CURRENCY_BAG_PROMPTS.md` / `CURRENCY_GEMS_PROMPTS.md`: золото `#FFD700`/`#D4A537`, фиолет `#8B5CF6` с бликами `#E0E7FF`.
- Ingest: `ingest_generated_sprite.py --pt 160 --lossless`, затем паддинг до квадрата 160/320/480 и quantize (как у старых иконок — квадрат, чтобы `frame(w,h)` без `scaledToFit` не растягивал). `Contents.json` сохраняет `template-rendering-intent: original`.

## Промпты

Общий хвост (`{KEY}` = green `#00FF00` или magenta `#FF00FF`):

```
…, bold black ink outlines on every element, a single game currency icon, big clear shapes that read at a tiny 16 pixel icon size, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat bright {KEY} background, centred with margin, the subject filling about 80% of the frame, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters, numbers or logos, no particles, no sparkles. The ENTIRE background is one flat, uniform, solid bright {KEY} colour edge to edge, no pattern, no stripes, no frame, no border.
```

Тексты для `icon-xp` и `icon-stamina` восстановлены по результату (исходная формулировка не сохранилась), для золота и гемов — дословные.

Префикс: `Image 1 is the STYLE ANCHOR from the same item icon set: match its pen-and-ink linework, outline weight, lighting and colouring exactly; do not copy its subject.`

- **icon-gold** — `Pen and ink illustration of one large thick gold coin standing upright and facing the viewer at a slight 3/4 angle, leaning against a short stack of three more gold coins behind it, the front coin is stamped with a small crowned skull in the centre and a raised hexagonal border, the coins are bright polished yellow gold (#FFD700) with deeper amber gold (#D4A537) mid-tones and dark bronze crosshatched shading on the milled edges, a few dents and nicks on the rims` (magenta)
- **icon-gems** — `Pen and ink illustration of a single large cut gemstone, a classic brilliant-cut jewel with a flat hexagonal table on top and pointed pavilion below, seen at a slight 3/4 angle from above, deep violet (#8B5CF6) faces with lighter purple mid-tones and pale cyan-white (#E0E7FF) highlights on the upper facets, thin dark ink lines define every facet edge, a tiny chip on one edge and faint internal fracture lines` (green)
- **icon-xp** — `Pen and ink illustration of a round bronze medallion with a riveted rim framed by a laurel wreath of iron leaves, a large five-pointed star of pale cyan crystal set in its centre, the bronze is worn and scratched with crosshatched shading` (magenta)
- **icon-stamina** — `Pen and ink illustration of a jagged lightning bolt carved from a single piece of amber crystal, bound around its middle with a riveted black iron band, chipped facets and fracture lines in the crystal` (magenta)
