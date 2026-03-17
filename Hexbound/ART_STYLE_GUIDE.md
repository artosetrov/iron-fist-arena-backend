# Hexbound — Art Style Guide for AI Image Generation

## Visual DNA (проанализировано по 12+ боссам и героям)

### Техника рисования
- **Pen and ink illustration** — это НЕ digital painting, НЕ concept art
- Каждый элемент обведён **жирной чёрной линией** (bold black ink outline)
- Внутри контуров — **цветная заливка с текстурой** (видны мазки, не плоский цвет)
- Тени делаются затемнением заливки, а не размытием или блюром
- Никакого glow, fog, mist, atmospheric lighting, volumetric effects
- Стиль ближе всего к: **D&D Monster Manual / Pathfinder rulebook / Darkest Dungeon**

### Палитра
- **База**: приглушённые землистые тона — серый камень, коричневый, бежевый/кость, тёмное железо
- **Акценты**: 1-2 насыщенных цвета на арт. Часто используемые:
  - Фиолетовый (магия, нежить, проклятия) — skeleton knight, lich king, bone colossus, necro priest
  - Зелёный (яд, болезнь, природа) — cave spider, plague bearer
  - Оранжевый (огонь, ржавчина, лава) — fire imp, rusty golem
  - Голубой/белый (лёд, призраки) — banshee
  - Красный/бурый (кровь, мясо) — ghoul brute, corpse weaver
  - Золотой (металл, богатство) — iron guardian

### Детализация
- Очень высокая — трещины, заклёпки, царапины, потёки, ржавчина
- Мелкие пропсы: черепа, кости, цепи, паутина, мечи, свитки
- Текстуры: шершавый камень, потрёпанная ткань, коррозия металла, гниение
- Каждая поверхность "пожила" — ничего нового/чистого

### Композиция
- Объект **изолирован на прозрачном/белом фоне** — как спрайт
- Нет фоновой сцены, нет окружения
- Персонажи обычно в 3/4 ракурсе, слегка динамичная поза
- Сцены/объекты (шахты, локации) — фронтальный или 3/4 вид

### Настроение
- **Grimdark / gothic dark fantasy**
- Черепа, кости, разложение — лейтмотив почти в каждом арте
- Мрачно, опасно, заброшено — ничего "красивого" или "волшебного" в позитивном смысле
- Даже "хорошие" вещи (золото, кристаллы) окружены гнилью и запустением

### Пропорции
- Слегка стилизованные, не фотореалистичные
- Не chibi, не аниме — western illustration
- Массивные, тяжёлые формы (доспехи, оружие, существа)

---

## Шаблон промта для DALL-E / ChatGPT

### Структура промта

```
Pen and ink illustration of [ОПИСАНИЕ ОБЪЕКТА], bold black ink outlines on every element, colored with [БАЗОВЫЕ ТОНА] and [АКЦЕНТНЫЙ ЦВЕТ] accents, [ДЕТАЛИ И ПРОПСЫ], isolated on white background, comic book lineart style, crisp sharp black outlines, fantasy RPG rulebook illustration, not a painting, not concept art, no blur, no glow, no fog, no text
```

### Негативный промт (если поддерживается)

```
painting, oil painting, watercolor, digital painting, concept art, realistic, photorealistic, 3D render, soft edges, blurry, atmospheric lighting, volumetric light, fog, mist, glow effects, gradient background, smooth shading, airbrushed, anime, pixel art
```

### Ключевые фразы которые РАБОТАЮТ для нашего стиля

| Нужный эффект | Фраза для промта |
|---|---|
| Жирные контуры | `bold black ink outlines on every element` |
| Не painting | `pen and ink illustration`, `not a painting` |
| Правильный жанр | `fantasy RPG rulebook illustration` |
| Изоляция | `isolated on white background` |
| Чёткость | `crisp sharp black outlines`, `comic book lineart` |
| Текстурная заливка | `colored with muted earth tones` |
| Гримдарк детали | `weathered, corroded, cracked, bone fragments, skulls, cobwebs` |

### Фразы которые НЕ РАБОТАЮТ (уводят стиль)

| Плохая фраза | Почему |
|---|---|
| `Darkest Dungeon inspired` | DALL-E интерпретирует как painted сцену |
| `dark fantasy` (без уточнений) | Слишком абстрактно, даёт concept art |
| `glowing`, `magical light` | Добавляет soft glow эффекты |
| `atmospheric` | Включает fog/mist/volumetric |
| `detailed`, `high quality` | Generic — не помогает стилю |
| `transparent background` | DALL-E часто игнорирует, лучше `white background` и удалить потом |

---

## Референсные арты из проекта

Если нужно показать стиль-референс генератору:

### Боссы (full body, самые характерные)
- `Assets.xcassets/Bosses/boss-skeleton-knight-full` — типичный стиль: доспехи, фиолетовый акцент, черепа
- `Assets.xcassets/Bosses/boss-rusty-golem-full` — металл, ржавчина, оранжевый акцент
- `Assets.xcassets/Bosses/boss-cave-spider-full` — существо, зелёный яд, чёткие контуры
- `Assets.xcassets/Bosses/boss-iron-guardian-full` — тяжёлый металл, золотой/бронзовый акцент
- `Assets.xcassets/Bosses/boss-banshee-full` — холодные тона, белый/голубой акцент

### Портреты (bust, хорошо видна техника контуров)
- `Assets.xcassets/Bosses/boss-necro-priest-portrait` — фиолетовый + золото, религиозная тематика
- `Assets.xcassets/Bosses/boss-skeleton-knight-portrait` — крупно видны ink outlines на черепе и шлеме
- `Assets.xcassets/Bosses/boss-plague-bearer-portrait` — текстура кожи, зелёный яд, мухи

### Иконки
- `Assets.xcassets/icon-gold-mine` — ⚠️ ДРУГОЙ стиль (casual/cartoon), НЕ использовать как референс

---

## Стандартные размеры ассетов

| Тип | Размер (1x) | Размер (2x для retina) | Aspect Ratio |
|---|---|---|---|
| Boss full body | ~512x512 | 1024x1024 | 1:1 |
| Boss portrait | ~256x256 | 512x512 | 1:1 |
| Mine card illustration | ~512x340 | 1024x680 | 3:2 |
| Icon (sidebar) | ~64x64 | 128x128 | 1:1 |
