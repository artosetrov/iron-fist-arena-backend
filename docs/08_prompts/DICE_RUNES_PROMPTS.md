# Hexbound — Промпты: кости и руны

> **Status**: `canonical` — Active prompt collection. Indexed at `docs/08_prompts/ASSET_PROMPTS_INDEX.md`
> Механика: `docs/06_game_systems/DICE_RUNES_DESIGN.md`. Стиль: `docs/08_prompts/ART_STYLE_GUIDE.md` (Visual DNA + Generation Rules) — семейство **pen-and-ink rulebook** (не гротеск боссов).
> Создано 2026-10-14. Файл собран скриптом, поэтому «библия стиля» в каждом промпте совпадает побайтно.

---

## 0. Как генерировать

**Модель:** Higgsfield → Nano Banana 2.1, **2K**, **1:1**, по одному ассету на вызов (§3 гайда: «one call = one image»).

**Пайплайн:**
1. Скопировать промпт целиком. Начало до `no particles` — библия стиля из гайда, **не править**. Всё после — специфика ассета.
2. Если у ассета указан якорь — приложить одобренный ассет якоря как reference image.
3. Negative prompt (если модель поддерживает) — один на весь пакет:
   ```
   painting, oil painting, watercolor, digital painting, concept art, realistic, photorealistic, 3D render, soft edges, blurry, atmospheric lighting, volumetric light, fog, mist, glow effects, gradient background, smooth shading, airbrushed, anime, pixel art, letters, alphabet, text, numbers, logo, frame, border
   ```
4. Ingest: `python3 scripts/ingest_generated_sprite.py raw.png <asset-name> --pt <pt>` → `@1x/@2x/@3x` + `Contents.json` в `Assets.xcassets`. Если скрипт печатает `WARNING … background was not flat` — перегенерировать, не дожимать ключ.
5. Одобрять только **в собранном экране на реальном размере** (прототип «Hexbound Dice Duel», дальше SwiftUI) — чеклист §7 гайда.

**Что рисует код, а не картинка** (§1 гайда): свечение руны при срабатывании, вспышка, подпись руны и урон, красная/синяя рамка кубика атаки/защиты, кольцо «можно тапнуть», трещина подсечки, замок с уровнем («Ур. 12» — текстом поверх `rune-socket-locked`).

**Порядок (якоря первыми):**

| # | Ассет | Почему первым |
|---|---|---|
| 1 | `dice-face-attack` | якорь граней |
| 2 | `dice-zone-head` | якорь эмблем |
| 3 | `rune-warrior-wrath` | якорь Малых рун |
| 4 | `rune-warrior-frenzy` | якорь рун Пути |
| 5 | `rune-warrior-beast` | якорь Великих рун |
| — | **стоп: собрать в экране и одобрить** | дальше всё генерируется от якорей |
| 6 | `dice-face-guard`, `dice-zone-body`, `dice-zone-legs`, `rune-socket-*` | edit/anchor-варианты |
| 7 | остальные 33 руны | по классам |
| 8 | `dice-showcase-*` | от одобренных граней и эмблем |

Всего **45 генераций** (+ перегенерации, бюджет 2 на ассет).

**Размеры:** грань кубика в бою до 112 pt → 2K с запасом; руна 64 pt (и 28 pt в углу кубика — проверить читаемость знака именно там).

## 1. Грани костей

Фон грани без символа. Символ зоны и руна накладываются кодом поверх — так 2 картинки граней × 3 эмблемы × 36 рун собираются в любые комбинации без перегенерации.

### `dice-face-attack` — грань кости Атаки (пустая)

- Показ: **104 pt** · генерация: **2K, 1:1** · ключ: `FF00FF`
- Якорь: первый ассет класса — после одобрения он якорь для `dice-face-guard`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png dice-face-attack --pt 104`

```
Pen and ink illustration of a single square face of a heavy game die seen straight-on, a thick square plate with softly rounded bevelled corners and a raised rim around a recessed inner field, the inner field left completely empty and smooth, bold black ink outlines on every element, colored with dark forged iron, charcoal and worn bone tones and oxblood red accents, an oxblood-red enamel band inlaid along the rim, four small round rivets in the corners, hammer marks, scratches, chipped enamel and rust in the recesses, the empty centre stays quiet with big calm shapes, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 86% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border.
```

### `dice-face-guard` — грань кости Защиты (пустая)

- Показ: **104 pt** · генерация: **2K, 1:1** · ключ: `FF00FF`
- Якорь: `dice-face-attack` (edit-вариант, не новый промпт с нуля)
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png dice-face-guard --pt 104`

```
Pen and ink illustration of a single square face of a heavy game die seen straight-on, a thick square plate with softly rounded bevelled corners and a raised rim around a recessed inner field, the inner field left completely empty and smooth, bold black ink outlines on every element, colored with cold grey steel, charcoal and worn bone tones and slate blue accents, a slate-blue enamel band inlaid along the rim, four small shield-shaped studs in the corners, hammer marks, scratches, chipped enamel and pitting in the recesses, the empty centre stays quiet with big calm shapes, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 86% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Edit of the attached approved attack face: change only the metal to cold grey steel, the enamel to slate blue and the corner rivets to small shield-shaped studs; keep shape, bevel, rim, proportions and light identical.
```


## 2. Эмблемы зон

Три эмблемы ложатся поверх обеих граней, поэтому они нейтральные (кость/слоновая кость + тёмное железо), без красного и синего. Должны читаться на 48 pt.

### `dice-zone-head` — эмблема зоны «голова»

- Показ: **48 pt** · генерация: **2K, 1:1** · ключ: `FF00FF`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png dice-zone-head --pt 48`

```
Pen and ink illustration of a carved emblem of a closed great helm seen from the front, as a flat relief badge with a simple bold silhouette that reads at small size, bold black ink outlines on every element, colored with pale bone and aged ivory tones and dark iron accents, a narrow visor slit and a single crest ridge, a few chisel marks, no plate or background behind the emblem, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 78% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border.
```

### `dice-zone-body` — эмблема зоны «тело»

- Показ: **48 pt** · генерация: **2K, 1:1** · ключ: `FF00FF`
- Якорь: `dice-zone-head`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png dice-zone-body --pt 48`

```
Pen and ink illustration of a carved emblem of a breastplate cuirass seen from the front, as a flat relief badge with a simple bold silhouette that reads at small size, bold black ink outlines on every element, colored with pale bone and aged ivory tones and dark iron accents, a central ridge down the chest and two shoulder plates, a few chisel marks, no plate or background behind the emblem, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 78% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

### `dice-zone-legs` — эмблема зоны «ноги»

- Показ: **48 pt** · генерация: **2K, 1:1** · ключ: `FF00FF`
- Якорь: `dice-zone-head`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png dice-zone-legs --pt 48`

```
Pen and ink illustration of a carved emblem of a single armoured boot in side view with the toe pointing right, as a flat relief badge with a simple bold silhouette that reads at small size, bold black ink outlines on every element, colored with pale bone and aged ivory tones and dark iron accents, a pointed sabaton toe and a short greave, a few chisel marks, no plate or background behind the emblem, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 78% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```


## 3. Кости целиком (профиль, вкладка «Кости»)

Витрина в шапке вкладки и в анимации «кость выкатывается» перед боем. Генерировать **после** одобрения граней и эмблем — прикладывать их как якоря.

### `dice-showcase-attack` — кость Атака в 3/4

- Показ: **200 pt** · генерация: **2K, 1:1** · ключ: `FF00FF`
- Якорь: `dice-face-attack` + `dice-zone-*`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png dice-showcase-attack --pt 200`

```
Pen and ink illustration of a heavy six-sided game die in three-quarter view showing its top, left and right faces, each face carved with a relief emblem: a closed great helm on the top face, a breastplate on the left face, an armoured boot on the right face, bold black ink outlines on every element, colored with dark forged iron, charcoal and worn bone tones and oxblood red accents, an oxblood-red enamel band inlaid along the rim of every face, four small round rivets on every corner, rounded bevelled edges, battle dents, a small skull embossed on one corner, big quiet shapes, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Three-quarter view of the cube, not frontal. The object fills about 78% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference images attached: the approved die face and zone emblems — match their materials and emblems.
```

### `dice-showcase-guard` — кость Защита в 3/4

- Показ: **200 pt** · генерация: **2K, 1:1** · ключ: `FF00FF`
- Якорь: `dice-face-guard` + `dice-zone-*`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png dice-showcase-guard --pt 200`

```
Pen and ink illustration of a heavy six-sided game die in three-quarter view showing its top, left and right faces, each face carved with a relief emblem: a closed great helm on the top face, a breastplate on the left face, an armoured boot on the right face, bold black ink outlines on every element, colored with cold grey steel, charcoal and worn bone tones and slate blue accents, a slate-blue enamel band inlaid along the rim of every face, four small shield-shaped studs on every corner, rounded bevelled edges, battle dents, a small skull embossed on one corner, big quiet shapes, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Three-quarter view of the cube, not frontal. The object fills about 78% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference images attached: the approved die face and zone emblems — match their materials and emblems.
```


## 4. Гнёзда рун

Пустое гнездо — на гранях без руны (в профиле). Закрытое — гнездо, которое ещё не открыто уровнем.

### `rune-socket-empty` — пустое гнездо

- Показ: **40 pt** · генерация: **2K, 1:1** · ключ: `FF00FF`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-socket-empty --pt 40`

```
Pen and ink illustration of an empty round rune socket: a ring of dark iron with four claw prongs pointing inward around an empty hollow centre, bold black ink outlines on every element, colored with dark iron and charcoal tones and tarnished bronze accents, small rivets on the ring, wear and scratches, the hollow centre is plain dark and empty, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 80% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border.
```

### `rune-socket-locked` — закрытое гнездо

- Показ: **40 pt** · генерация: **2K, 1:1** · ключ: `FF00FF`
- Якорь: `rune-socket-empty` (edit-вариант)
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-socket-locked --pt 40`

```
Pen and ink illustration of an empty round rune socket: a ring of dark iron with four claw prongs pointing inward around an empty hollow centre, closed by a small iron padlock hanging on a short chain across the hollow, bold black ink outlines on every element, colored with dark iron and charcoal tones and tarnished bronze accents, small rivets on the ring, wear and scratches, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 80% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Edit of the attached approved empty socket: change only — add the padlock and chain across the hollow; keep everything else identical.
```


## 5. Руны (36)

Форма камня = тип кости: **острая** (осколок, ромб, наконечник) — руна атаки, **круглая** (галька, щит, диск) — руна защиты. Материал = ранг: камень — Малая, железо в бронзе — Пути, обсидиан в золоте — Великая. Цвет пигмента в бороздах = класс.

Символ на руне — **придуманный знак** из нескольких штрихов. Описание каждого знака дано явно, чтобы модель не рисовала буквы. Проверять на 100%: знак совпадает с описанием, не похож на букву, штрихи толстые и читаются на 28 pt (размер руны в углу кубика). Брак по §6 гайда — 2 перегенерации, потом менять формулировку знака.

У Мага фиолетовый пигмент → фон **зелёный** `#00FF00` (§5 гайда: magenta съедает фиолетовый).


### Воин — акцент: oxblood red

#### `rune-warrior-wrath` — Гнев · Малая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: **это якорь класса** — генерировать первым, одобрить в экране
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-warrior-wrath --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a pointed flint shard, carrying a single invented sigil carved into the stone: an upward flame shape made of three strokes with a short horizontal bar beneath it, bold black ink outlines on every element, colored with grey stone and weathered bone tones and oxblood red accents, the sigil grooves filled with oxblood red pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border.
```

#### `rune-warrior-blade` — Клинок · Малая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-warrior-blade --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a pointed flint shard, carrying a single invented sigil carved into the stone: a single vertical blade stroke with a short crossguard and a notch near the tip, bold black ink outlines on every element, colored with grey stone and weathered bone tones and oxblood red accents, the sigil grooves filled with oxblood red pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-warrior-mail` — Кольчуга · Малая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-warrior-mail --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a smooth flat river pebble, carrying a single invented sigil carved into the stone: three small interlocking rings arranged in a triangle, bold black ink outlines on every element, colored with grey stone and weathered bone tones and oxblood red accents, the sigil grooves filled with oxblood red pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-warrior-endurance` — Стойкость · Малая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-warrior-endurance --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a smooth flat river pebble, carrying a single invented sigil carved into the stone: a small round shield outline with a two-leaf sprout growing upward from its top edge, bold black ink outlines on every element, colored with grey stone and weathered bone tones and oxblood red accents, the sigil grooves filled with oxblood red pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-warrior-frenzy` — Неистовство · Пути · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: **это якорь класса** — генерировать первым, одобрить в экране
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-warrior-frenzy --pt 64`

```
Pen and ink illustration of a rune tablet of forged iron shaped like a diamond kite, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: two parallel diagonal slashes crossed by a third shorter slash, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and oxblood red accents, the sigil grooves filled with oxblood red pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border.
```

#### `rune-warrior-bulwark` — Оплот · Пути · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-warrior-bulwark --pt 64`

```
Pen and ink illustration of a round rune tablet of forged iron shaped like a small buckler, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: a tall tower-shield outline with a small solid diamond set in its centre, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and oxblood red accents, the sigil grooves filled with oxblood red pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-warrior-headsman` — Палач · Пути · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-warrior-headsman --pt 64`

```
Pen and ink illustration of a rune tablet of forged iron shaped like a diamond kite, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: a crescent axe head above a short horizontal line, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and oxblood red accents, the sigil grooves filled with oxblood red pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-warrior-beast` — Зверь · Великая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: **это якорь класса** — генерировать первым, одобрить в экране
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-warrior-beast --pt 64`

```
Pen and ink illustration of a black obsidian rune shard shaped like a spear point, held in a gold claw mount with a tiny skull at its base, carrying a single invented sigil inlaid in the obsidian: three curved claw marks fanning downward, bold black ink outlines on every element, colored with black obsidian and aged gold tones and oxblood red accents, the sigil grooves filled with oxblood red pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border.
```

#### `rune-warrior-oath` — Клятва · Великая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-beast`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-warrior-oath --pt 64`

```
Pen and ink illustration of a round black obsidian rune disc held in a gold claw mount with a tiny skull at its base, carrying a single invented sigil inlaid in the obsidian: a circle with three short upward strokes rising from its top, like a raised palm, bold black ink outlines on every element, colored with black obsidian and aged gold tones and oxblood red accents, the sigil grooves filled with oxblood red pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```


### Разбойник — акцент: poison green

#### `rune-rogue-dagger` — Кинжал · Малая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-rogue-dagger --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a pointed flint shard, carrying a single invented sigil carved into the stone: a thin downward-pointing spike with a small diamond at its upper end, bold black ink outlines on every element, colored with grey stone and weathered bone tones and poison green accents, the sigil grooves filled with poison green pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-rogue-bloodletting` — Кровопускание · Малая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-rogue-bloodletting --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a pointed flint shard, carrying a single invented sigil carved into the stone: a short diagonal slash with three small drops hanging beneath it, bold black ink outlines on every element, colored with grey stone and weathered bone tones and poison green accents, the sigil grooves filled with poison green pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-rogue-evasion` — Уклон · Малая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-rogue-evasion --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a smooth flat river pebble, carrying a single invented sigil carved into the stone: one curved swerving stroke with a single dot on each side of it, bold black ink outlines on every element, colored with grey stone and weathered bone tones and poison green accents, the sigil grooves filled with poison green pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-rogue-smoke` — Дым · Малая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-rogue-smoke --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a smooth flat river pebble, carrying a single invented sigil carved into the stone: three stacked wavy horizontal strokes, bold black ink outlines on every element, colored with grey stone and weathered bone tones and poison green accents, the sigil grooves filled with poison green pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-rogue-shadowstrike` — Теневой удар · Пути · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-rogue-shadowstrike --pt 64`

```
Pen and ink illustration of a rune tablet of forged iron shaped like a diamond kite, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: a crescent moon pierced diagonally by one straight stroke, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and poison green accents, the sigil grooves filled with poison green pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-rogue-riposte` — Рипост · Пути · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-rogue-riposte --pt 64`

```
Pen and ink illustration of a round rune tablet of forged iron shaped like a small buckler, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: two short chevrons pointing at each other and almost touching, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and poison green accents, the sigil grooves filled with poison green pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-rogue-venom` — Яд · Пути · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-rogue-venom --pt 64`

```
Pen and ink illustration of a rune tablet of forged iron shaped like a diamond kite, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: a teardrop shape with a small cross scratched inside it, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and poison green accents, the sigil grooves filled with poison green pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-rogue-vanish` — Исчезновение · Великая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-beast`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-rogue-vanish --pt 64`

```
Pen and ink illustration of a round black obsidian rune disc held in a gold claw mount with a tiny skull at its base, carrying a single invented sigil inlaid in the obsidian: an almond eye shape with its lower half missing and three dots below it, bold black ink outlines on every element, colored with black obsidian and aged gold tones and poison green accents, the sigil grooves filled with poison green pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-rogue-reaper` — Жнец · Великая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-beast`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-rogue-reaper --pt 64`

```
Pen and ink illustration of a black obsidian rune shard shaped like a spear point, held in a gold claw mount with a tiny skull at its base, carrying a single invented sigil inlaid in the obsidian: a long curved scythe blade on a short straight shaft, bold black ink outlines on every element, colored with black obsidian and aged gold tones and poison green accents, the sigil grooves filled with poison green pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```


### Маг — акцент: arcane violet

#### `rune-mage-spark` — Искра · Малая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `00FF00`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-mage-spark --pt 64 --key 00FF00`

```
Pen and ink illustration of a small rune stone shaped like a pointed flint shard, carrying a single invented sigil carved into the stone: a small four-pointed star with uneven rays, bold black ink outlines on every element, colored with grey stone and weathered bone tones and arcane violet accents, the sigil grooves filled with arcane violet pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid green (#00FF00), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-mage-mana` — Мана · Малая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `00FF00`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-mage-mana --pt 64 --key 00FF00`

```
Pen and ink illustration of a small rune stone shaped like a pointed flint shard, carrying a single invented sigil carved into the stone: a crescent lying on its back like a cup, holding a small solid diamond just above its hollow, bold black ink outlines on every element, colored with grey stone and weathered bone tones and arcane violet accents, the sigil grooves filled with arcane violet pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid green (#00FF00), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-mage-barrier` — Барьер · Малая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `00FF00`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-mage-barrier --pt 64 --key 00FF00`

```
Pen and ink illustration of a small rune stone shaped like a smooth flat river pebble, carrying a single invented sigil carved into the stone: a half-circle dome standing on a horizontal line, bold black ink outlines on every element, colored with grey stone and weathered bone tones and arcane violet accents, the sigil grooves filled with arcane violet pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid green (#00FF00), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-mage-mirror` — Зеркало · Малая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `00FF00`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-mage-mirror --pt 64 --key 00FF00`

```
Pen and ink illustration of a small rune stone shaped like a smooth flat river pebble, carrying a single invented sigil carved into the stone: two mirrored brackets facing each other around a single dot, bold black ink outlines on every element, colored with grey stone and weathered bone tones and arcane violet accents, the sigil grooves filled with arcane violet pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid green (#00FF00), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-mage-flame` — Пламя · Пути · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `00FF00`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-mage-flame --pt 64 --key 00FF00`

```
Pen and ink illustration of a rune tablet of forged iron shaped like a diamond kite, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: a three-tongued flame contained inside a triangle, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and arcane violet accents, the sigil grooves filled with arcane violet pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid green (#00FF00), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-mage-flow` — Поток · Пути · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `00FF00`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-mage-flow --pt 64 --key 00FF00`

```
Pen and ink illustration of a round rune tablet of forged iron shaped like a small buckler, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: a spiral of one and a half turns, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and arcane violet accents, the sigil grooves filled with arcane violet pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid green (#00FF00), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-mage-frost` — Иней · Пути · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `00FF00`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-mage-frost --pt 64 --key 00FF00`

```
Pen and ink illustration of a round rune tablet of forged iron shaped like a small buckler, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: three crossing strokes forming a six-armed star with short ticks on each arm, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and arcane violet accents, the sigil grooves filled with arcane violet pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid green (#00FF00), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-mage-meteor` — Метеор · Великая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `00FF00`
- Якорь: `rune-warrior-beast`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-mage-meteor --pt 64 --key 00FF00`

```
Pen and ink illustration of a black obsidian rune shard shaped like a spear point, held in a gold claw mount with a tiny skull at its base, carrying a single invented sigil inlaid in the obsidian: a small circle with three trailing diagonal strokes behind it, bold black ink outlines on every element, colored with black obsidian and aged gold tones and arcane violet accents, the sigil grooves filled with arcane violet pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid green (#00FF00), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-mage-time` — Время · Великая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `00FF00`
- Якорь: `rune-warrior-beast`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-mage-time --pt 64 --key 00FF00`

```
Pen and ink illustration of a round black obsidian rune disc held in a gold claw mount with a tiny skull at its base, carrying a single invented sigil inlaid in the obsidian: an hourglass made of two triangles touching at their tips, bold black ink outlines on every element, colored with black obsidian and aged gold tones and arcane violet accents, the sigil grooves filled with arcane violet pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat green background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid green (#00FF00), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```


### Танк — акцент: steel blue

#### `rune-tank-ram` — Таран · Малая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-tank-ram --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a pointed flint shard, carrying a single invented sigil carved into the stone: a blunt arrow pointing up with a thick square head, bold black ink outlines on every element, colored with grey stone and weathered bone tones and steel blue accents, the sigil grooves filled with steel blue pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-tank-stone` — Камень · Малая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-tank-stone --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a smooth flat river pebble, carrying a single invented sigil carved into the stone: a solid square with one corner chipped off, bold black ink outlines on every element, colored with grey stone and weathered bone tones and steel blue accents, the sigil grooves filled with steel blue pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-tank-thorns` — Шипы · Малая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-tank-thorns --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a smooth flat river pebble, carrying a single invented sigil carved into the stone: a small circle with six short spikes around it, bold black ink outlines on every element, colored with grey stone and weathered bone tones and steel blue accents, the sigil grooves filled with steel blue pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-tank-fortify` — Укрепление · Малая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-wrath`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-tank-fortify --pt 64`

```
Pen and ink illustration of a small rune stone shaped like a smooth flat river pebble, carrying a single invented sigil carved into the stone: a small blacksmith's anvil silhouette made of a few blocky strokes, bold black ink outlines on every element, colored with grey stone and weathered bone tones and steel blue accents, the sigil grooves filled with steel blue pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-tank-challenge` — Вызов · Пути · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-tank-challenge --pt 64`

```
Pen and ink illustration of a rune tablet of forged iron shaped like a diamond kite, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: a curved war horn with a flared mouth and three short strokes bursting from the mouth, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and steel blue accents, the sigil grooves filled with steel blue pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-tank-wall` — Стена · Пути · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-tank-wall --pt 64`

```
Pen and ink illustration of a round rune tablet of forged iron shaped like a small buckler, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: a brick pattern of three rows of short bars, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and steel blue accents, the sigil grooves filled with steel blue pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-tank-unbreakable` — Несокрушимость · Пути · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-frenzy`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-tank-unbreakable --pt 64`

```
Pen and ink illustration of a round rune tablet of forged iron shaped like a small buckler, framed by a riveted bronze rim, carrying a single invented sigil inlaid in the iron: a hexagon outline with one short jagged crack entering from an edge and stopping before the centre, bold black ink outlines on every element, colored with dark iron and tarnished bronze tones and steel blue accents, the sigil grooves filled with steel blue pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-tank-bastion` — Бастион · Великая · защита

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-beast`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-tank-bastion --pt 64`

```
Pen and ink illustration of a round black obsidian rune disc held in a gold claw mount with a tiny skull at its base, carrying a single invented sigil inlaid in the obsidian: a tower outline with three crenellations on top, bold black ink outlines on every element, colored with black obsidian and aged gold tones and steel blue accents, the sigil grooves filled with steel blue pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

#### `rune-tank-earthshatter` — Землетрясение · Великая · атака

- Показ **64 pt** (дерево, шторка), мини-руна на кубике — тот же ассет на 28 pt · генерация **2K, 1:1** · ключ `FF00FF`
- Якорь: `rune-warrior-beast`
- Ingest: `python3 scripts/ingest_generated_sprite.py raw.png rune-tank-earthshatter --pt 64`

```
Pen and ink illustration of a black obsidian rune shard shaped like a spear point, held in a gold claw mount with a tiny skull at its base, carrying a single invented sigil inlaid in the obsidian: a blocky hammer head striking down onto a horizontal ground line, with three short cracks radiating beneath the line, bold black ink outlines on every element, colored with black obsidian and aged gold tones and steel blue accents, the sigil grooves filled with steel blue pigment, the sigil is made of a few thick chiselled strokes and is not a letter of any alphabet, chips, cracks and wear on the edges, big quiet shapes with detail only on the sigil, lit by one key light from the upper left, warm bone-coloured key, cool slate-grey shadows, no cast shadow on the ground, isolated on a flat magenta background, centred with margin, one subject only, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, not a 3D render, no blur, no glow, no fog, no text, letters or logos, no particles. Flat frontal view. The object fills about 74% of the frame. The ENTIRE background is one flat, uniform, solid magenta (#FF00FF), edge to edge, no pattern, no stripes, no frame, no border. Reference image attached: an approved asset of the same class. Match its line weight, light direction, ink texture and framing exactly; do not copy its emblem or sigil.
```

## Glyphs v2 (2026-10-14)

Семь знаков первой партии читались как буквы (Φ, I, ⊥, ∩, C, Z) и перегенерированы как пиктограммы: `rune-warrior-endurance`, `rune-warrior-bulwark`, `rune-mage-mana`, `rune-tank-fortify`, `rune-tank-challenge`, `rune-tank-unbreakable`, `rune-tank-earthshatter`. Старые описания заменены выше, job id обновлены в `DICE_RUNES_MANIFEST.json`.
