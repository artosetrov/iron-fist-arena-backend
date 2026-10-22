# Reward cards (2026-10-22)

Every window that pays the player or ends a fight is a painted card, in the language of
the gate-deck hero cards: a frame, a big illustration, then the numbers.

Code: `Views/Components/RewardCard.swift` (card, frame, illustration, title, rows, stage),
`RewardCardStyle.swift` (families, tiers, art, layout), `RewardCardFrameMetrics.swift`
(generated). Art: `docs/08_prompts/REWARD_CARD_FRAMES_PROMPTS.md`.

## Anatomy

```
        crest              ← frame top cap (where it came from)
  ┌───────┴───────┐
  │  illustration  │       ← family scene + tier light + big subject, fades into the body
  │     TITLE      │       ← on the fade
  │    subtitle    │
  │  ───── ◆ ───── │
  │  +24  Rating   │       ← content: one line per reward, loot three to a row, progress…
  │  +180 Gold     │
  │  [ CONTINUE ]  │       ← actions
  └───────┬───────┘       ← frame bottom cap
       ornament
```

- **Any height.** Each frame is cut into a top cap, a rail strip and a bottom cap. The strip
  repeats to fill the content's height; the caps cross-fade into it.
- **Fits the screen.** `RewardCardStage` centres the card at `min(screen − 32, 380)` pt. If it
  does not fit, the illustration drops from 0.9 to 0.58 of the window width; if it still does
  not fit, the card scrolls.
- **Text and buttons** stay inside the band the frame metrics are measured in (8 % of the
  width inside the rails), so no corner ornament ever covers them.
- **Losses** keep the family and tier, with `dimmed: true` (frame and illustration
  desaturate) and the title in `danger` red.

## Families — where the reward came from

| Family | Crest / corners | Scene | Windows |
|---|---|---|---|
| `arena` | crossed swords and shield | `bg-arena` | arena victory and defeat, rank up, the scripted first fight |
| `dungeon` | crowned horned skull, claws | `bg-dungeon` | boss victory, dungeon defeat, Dungeon Rush treasure |
| `fortune` | dice and a wheel, coins | `bg-fortune-wheel` | shell game, fortune wheel, Fortune's Table |
| `mine` | pickaxes and a lantern, timber | `bg-gold-mine` | Gold Mine payout and chest |
| `merchant` | scales and a purse, ribbons | `bg-shop` | purchases, contraband, special offers |
| `tribute` | scroll, quill and seal, an hourglass | `bg-tavern` | daily login, quests, mail, referrals |
| `glory` | laurels, a star, banners | `bg-title` | achievements, battle pass, season summary |
| `ascension` | wings around a sun | `bg-forge` | level up |

## Tiers — what it is worth

iron → bronze → silver → gold → mythic, the hero-card ladder. Each window passes its own
reading, and the most valuable thing in the card can lift it (`RewardCardTier.best`): an
epic drop turns any card gold.

| Reading | Rule |
|---|---|
| item rarity | common iron · uncommon bronze · rare silver · epic gold · legendary mythic |
| hero level | 1–9 iron · 10–19 bronze · 20–29 silver · 30–39 gold · 40+ mythic |
| PvP ladder tier | bronze · silver · gold/platinum gold · diamond and above mythic · unranked iron |
| daily login | days 1–2 iron · 3–4 bronze · 5–6 silver · 7 gold |
| battle pass level | 1–19 iron · 20–39 bronze · 40–59 silver · 60–79 gold · 80+ mythic |
| daily quests bonus | silver |
| currency only | gold + 20 × gems + xp / 2: < 150 iron · < 400 bronze · < 1 200 silver · < 5 000 gold · mythic |

The tier is cosmetic — it never changes what the server grants.

## Illustration — what is shown

- **Fights:** the opponent (hero portrait, mirrored) or the boss (full figure), sinking into the fade.
- **Heroes:** level up, rank up and the first fight show the player's own hero.
- **Rewards:** `RewardCardArt.headline` picks the most valuable thing in a bundle — a rare or
  better item, then gems (few / heap), then gold (purse < 300 · heap < 2 000 · open chest),
  then potions, then the XP medallion. Achievements show their own medallion.

## Windows

| Window | File | Family | Tier | Art |
|---|---|---|---|---|
| CLAIMED! — daily login | `DailyLoginPopupViewModel` | tribute | streak day | headline |
| CLAIMED! — quests, quest bonus, tutorial quests | `QuestService`, `DailyQuestsViewModel`, `HubView` | tribute | contents (bonus: silver) | headline |
| CLAIMED! — achievements | `AchievementsViewModel` | glory | contents | the achievement's medallion |
| CLAIMED! — battle pass | `BattlePassViewModel` | glory | BP level | headline |
| CLAIMED! — mail, referrals | `InboxViewModel`, `ReferralSectionView` | tribute | contents | headline |
| CLAIMED! — contraband, offers | `BlackMarketViewModel`, `ShopViewModel` | merchant | contents | headline |
| Level up | `LevelUpModalView` | ascension | new level | the hero |
| Rank up | `RankUpCeremonyView` | arena | new rank | the hero |
| Season summary | `SeasonSummaryModalView` | glory | final BP level (+1 with premium) | XP medallion |
| Tutorial victory | `VictoryOverlayView` | arena | iron | the hero |
