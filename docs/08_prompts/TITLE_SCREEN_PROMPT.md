# Hexbound — Промпт для Nano Banana Pro: Title Screen Background

> **Status**: `canonical` — Active prompt. Indexed at `docs/08_prompts/ASSET_PROMPTS_INDEX.md`
> **Asset name**: `bg-title`
> **Usage**: Full-screen background для `WelcomeView.swift` (первое касание игры — должен давать вау с первой секунды)

---

## Общие правила

**Формат:** 9:19.5 (вертикальный, iPhone full-screen) — можно генерировать 9:16 и обрезать
**Фон:** Очень тёмный (#0D0D12 → #1A1A2E), чтобы лого Hexbound и кнопки поверх были идеально читаемы
**Стиль:** Hand-drawn ink and watercolor illustration, crosshatching shading, grotesque dark fantasy medieval manuscript art style. Thick bold outlines.
**UI overlay zones (КРИТИЧНО — оставить тёмным / почти пустым):**
- **Верхняя треть, центр:** зона логотипа Hexbound (не полностью пустая — допустимо лёгкое свечение/дымка для обрамления, но никакого яркого объекта в центре)
- **Средняя треть, центр:** зона subtitle — максимально тёмная
- **Нижняя треть, центр:** зона кнопок — максимально тёмная, почти чёрная

Основная детализация — по **верхнему краю, боковым колоннам и нижнему краю** (обрамление композиции).

**БЕЗ текста, БЕЗ надписей, БЕЗ UI элементов, БЕЗ персонажей лицом к зрителю.**

---

## `bg-title` — Hexbound Title Screen

A dark vertical illustration for the title screen of a grimdark fantasy mobile RPG. The scene depicts the player's first view of the world of Hexbound — a lone hooded figure seen from behind, standing on a broken stone path at the foot of a colossal ancient hexagonal stone gateway set into a towering mountainside, under a storm-torn night sky. The gate is sealed, bound with massive iron chains and covered in faintly glowing golden hex-runes. This is the threshold to the game — ominous, epic, ancient.

COMPOSITION: Vertical 9:19.5. The hexagonal stone gate looms in the upper portion of the frame but is deliberately half-hidden by rolling mist and darkness so its silhouette reads without competing with the logo. The dead-center of the image, from roughly 25% height to 80% height, is kept very dark — almost black with only hints of fog and shape — this is where the Hexbound logo, subtitle, and buttons will sit. Detail and art weight are concentrated along the TOP EDGE (sky, gate apex), LEFT EDGE (stone pillar and torch), RIGHT EDGE (cliff face and chains), and BOTTOM EDGE (broken stone path and debris). The hooded figure is small, a dark silhouette at the lower-center, back turned to the viewer, looking up toward the gate — tiny enough not to interfere with button placement, more like a shadow cue than a focal character.

TOP AREA (behind and above the logo zone): A torn storm-night sky. Ragged black clouds drift across a pale bone-white moon that is partially obscured, casting cold dim light. Distant lightning flickers crosshatched in the clouds — no actual lightning bolts, just hints. The apex of the hexagonal gateway is visible near the top — massive carved stone in the shape of a hexagon's upper three sides, with an ancient weathered keystone bearing a faintly glowing golden hex-sigil (#D4A537). Cracks run through the stone. Tattered banners hang from iron hooks along the upper frame — grimy, wind-torn fabric, barely any color left. A few crows silhouetted perching on the stone frame. No stars — only storm.

LEFT EDGE (framing the logo column): A crumbling stone pillar rises from bottom to top, weathered and cracked, part of an ancient wall. Moss and dead ivy cling to it. An iron torch sconce is bolted halfway up — its flame is dying, a small warm golden ember glow (#D4A537) barely lighting the stone around it with crosshatched shadow. A battered tower shield hangs from the pillar — dented, blood-stained dark rust-brown, with a faded hexagonal emblem barely visible. A human skull embedded in the stone at the base, half-overgrown with moss — a long-dead traveler. Cobwebs in the upper corner. Heavy iron chains drape from somewhere above the pillar, disappearing into the darkness of the gateway.

RIGHT EDGE (framing the logo column): A rougher, more broken section of the cliff face — the mountain the gate is carved into. Jagged rock with deep fissures, dense crosshatching for stone texture. Massive rusted iron chains bolted into the rock, some taut, some sagging, binding the gate shut. A wanted poster board fragment nailed to the rock — torn, illegible, just shapes. Old scratch marks from claws or blades gouged into the stone. A dead twisted root pushes out of a crack near the top. Near the bottom, a broken iron lantern lies on its side, glass shattered, fire long dead.

BOTTOM AREA (below the buttons zone, framing the screen bottom): A cracked stone path of hexagonal flagstones leading from the foreground toward the gate. Many stones are broken, missing, or tilted — no one has walked this path in a long time. Scattered debris: a rusted sword half-buried in the dirt, a cracked helmet turned on its side, scattered gold hexagonal coins (a few, not many), small animal bones, dead leaves, a dropped torn-open letter with a broken wax seal. Fog pools low along the ground, rolling in from the edges. The small silhouette of the hooded figure stands facing away from the viewer, cloak hem frayed, boots worn — rendered as a simple dark ink shape, not detailed, almost part of the shadows.

COLOR PALETTE: Very dark — near-black (#0D0D12) dominant everywhere, with #1A1A2E for mid-shadows. Cold pale moonlight providing a thin gray-blue tone to the sky and upper stone highlights. Warm golden-orange accent (#D4A537) ONLY from: the dying torch flame on the left pillar, the faint hex-runes on the gate keystone and along the hexagonal frame, and the few scattered gold coins on the path. The gold is the single saturated accent — everything else is muted grays, deep blacks, cold bone-white moonlight, rust-brown bloodstains, dark moss-green on stone. Storm-lit and grim.

MOOD: The player is standing at the edge of something ancient and dangerous. The world is old, cursed, bound. The gate is sealed but calling. First impression should be: grimdark, epic, mysterious, heavy with history. No hope, no warmth except the single dying torch — the only sign of life in a dead place.

Hand-drawn ink and watercolor illustration, crosshatching shading, grotesque dark fantasy medieval manuscript art style. Thick bold outlines. Very high detail on the edges and borders, deliberate darkness and emptiness in the center vertical column. NO text, NO UI elements, NO characters facing the viewer, NO glowing magical particles, NO volumetric fog beams, NO lens flares. Vertical composition 9:19.5 (or 9:16, will be cropped).

### Negative prompt

painting, oil painting, digital painting, concept art, realistic, photorealistic, 3D render, soft edges, blurry, atmospheric lighting, volumetric light beams, lens flare, glow effects, neon, bloom, gradient background, smooth shading, airbrushed, anime, pixel art, characters facing camera, any visible text, UI elements, watermark, chromatic aberration

---

## Post-generation checklist

Перед тем как закидывать в `Assets.xcassets/bg-title.imageset/`:

1. Crop/resize до 1179×2556 (iPhone 15 Pro full-screen 3x) или 1290×2796 (iPhone 15 Pro Max)
2. Проверь, что центральная вертикальная колонна (roughly X: 20%-80%, Y: 25%-85%) максимально тёмная — логотип и кнопки должны читаться поверх без доп. vignette
3. Проверь, что нет случайного текста/надписей от генератора
4. Сохранить как PNG, максимум 1024px по меньшей стороне для xcassets (правило из `CLAUDE.md`: sync-assets.sh max 1024)
5. Зарегистрировать: `bg-title.imageset` + `Contents.json` + обновить `ASSET_PROMPTS_INDEX.md`

---

## Integration notes

В `WelcomeView.swift` фон будет добавлен как самый нижний слой в `ZStack`:

```swift
ZStack {
    Image("bg-title")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .ignoresSafeArea()
        .interpolation(.medium)  // per Asset Pipeline Rules
    
    // + subtle radial vignette overlay for extra focus (SwiftUI layer, not baked into PNG)
    // + остальной контент
}
```

Vignette и любое затемнение под кнопки — **в SwiftUI слоях поверх арта**, НЕ запекать в сам PNG, чтобы при необходимости можно было усилить/ослабить без перегенерации.
