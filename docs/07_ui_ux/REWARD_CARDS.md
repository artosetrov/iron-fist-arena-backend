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
  does not fit, the illustration drops from 0.9 to 0.58, then to 0.4 of the window width; if it
  still does not fit, the card is pinned to the screen's height and only its content scrolls
  (indicator flashed, edges faded) — the title and the buttons never leave the screen.
- **The crest never covers the subject.** The frame metrics carry how far each crest hangs into
  the window (`crestBottom`); the illustration keeps its subject's top below it.
- **Text and buttons** stay inside the band the frame metrics are measured in (8 % of the
  width inside the rails), so no corner ornament ever covers them.
- **Losses** keep the family and tier, with `dimmed: true` (frame and illustration
  desaturate) and the title in `danger` red.

## Families — where the reward came from

| Family | Crest / corners | Scene | Windows |
|---|---|---|---|
| `arena` | crossed swords and shield | `bg-arena` | arena victory and defeat, rank up, the scripted first fight |
| `dungeon` | crowned horned skull, claws | `bg-dungeon` | boss victory, dungeon defeat, the end of a Dungeon Rush run |
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
  better item, then gems (few / heap) or gold (purse < 300 · heap < 2 000 · open chest),
  whichever is worth more (a gem weighs 20 gold), then potions, then the XP medallion.
  Achievements show their own medallion. A lost minigame shows the purse tipped over and empty.
- **Loot** is a row of 72 pt tiles, three to a row, each item's name under its tile in its
  rarity's colour. A fight's combat log is one line on the card that opens the rounds in a sheet.

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
| Shell game, fortune wheel, Fortune's Table | `MinigameResultModal` (+ the three game views) | fortune | win: the game's reading (wheel ×1.5 bronze, ×2 silver, ×3 gold, ×5 or jackpot mythic; the table's chest rarity) and the gold; loss: iron, dimmed | win: gold by amount; loss: `reward-art-fortune-loss`; the game's own picture on a line under the title |
| Dungeon Rush run end (The Descent) | `DescentResultCard` (over the run screen, 0.9 s after the last blow so its effects play) | dungeon | what came out (gold + XP, item rarities; shards do not count); victory at least gold; a fall or a retreat: dimmed | victory: the matching `rush2-chest-*-open` on `rush2-bg-treasure`; escaped: on `rush2-bg-entrance`; a fall: the hero in the depth's hall |
| Dungeon Rush v1 treasure | `TreasureRewardOverlay` | dungeon | the gold (a buff: at least silver) | the matching `rush2-chest-*-open` on `bg-rush-treasure` — v1 is not reachable since The Descent (no route opens `DungeonRushDetailView`) |
| Gold Mine payout | `MineClaimRewardView` | mine | the payout (the chest: at least gold) | gold / gems art; the chest scene inside the card |
| Purchase reveal | `PurchaseRewardRevealView` | merchant | the pack (`-tierN` of its art), else the amounts | the pack's own painting, or gold / gems art |

The Descent's in-run beats (spoils after a fight, an opened chest, an event's loot, the
guardian's relic) stay in its action panel: they are steps of one continuous run, not
windows. Only the end of the run is a card.
