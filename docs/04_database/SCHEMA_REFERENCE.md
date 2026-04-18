# Database Schema Reference (Source of Truth)
*Derived from Prisma schema. Updated: 2026-04-17 — 65 models, 19 enums, 830 fields.*

## Core User & Auth

### User
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| email | String? | Unique, optional |
| username | String? | Optional |
| passwordHash | String? | Null for OAuth users |
| authProvider | String? | Generic auth provider field |
| role | UserRole | ADMIN, MODERATOR, PLAYER (default: PLAYER) |
| isBanned | Boolean | Default: false |
| banReason | String? | Ban details |
| createdAt | DateTime | Account creation |
| updatedAt | DateTime | Last modified |

**Unique constraints:** email, username (if provided)

**Relations:** Character (1-N), Mail (1-N), Achievements (1-N), PushToken (1-N)

---

## Characters

### Character
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| userId | String (UUID) | Foreign key to User |
| characterName | String | Unique |
| class | CharacterClass | warrior, rogue, mage, tank |
| origin | CharacterOrigin | human, orc, skeleton, demon, dogfolk |
| gender | CharacterGender | male, female (default: male) |
| avatar | String | Avatar ID (default: "warlord") |
| level | Int | Current level (default: 1) |
| currentXp | Int | XP toward next level (default: 0) |
| prestigeLevel | Int | Prestige rank (default: 0) |
| statPointsAvailable | Int | Unallocated stat points (default: 0) |
| passivePointsAvailable | Int | Unallocated passive points (default: 0) |
| str | Int | Strength stat (default: 10) |
| agi | Int | Agility stat (default: 10) |
| vit | Int | Vitality stat (default: 10) |
| end | Int | Endurance stat (default: 10) |
| int | Int | Intelligence stat (default: 10) |
| wis | Int | Wisdom stat (default: 10) |
| luk | Int | Luck stat (default: 10) |
| cha | Int | Charisma stat (default: 10) |
| gold | Int | Soft currency (default: 500) |
| arenaTokens | Int | PvP currency (default: 0) |
| maxHp | Int | Max health points (default: 100) |
| currentHp | Int | Current HP (default: 100) |
| armor | Int | Armor defense (default: 0) |
| magicResist | Int | Magic resistance (default: 0) |
| combatStance | JSON? | Active combat stance |
| currentStamina | Int | Current stamina (default: 120) |
| maxStamina | Int | Max stamina (default: 120) |
| lastStaminaUpdate | DateTime? | Stamina regen timestamp |
| lastHpUpdate | DateTime? | HP regen timestamp |
| bonusTrainings | Int | Extra training sessions available (default: 0) |
| bonusTrainingsDate | DateTime? | When bonus trainings expire |
| bonusTrainingsBuys | Int | Number of bonus training purchases (default: 0) |
| createdAt | DateTime | Creation date |
| updatedAt | DateTime | Last modified |
| deletedAt | DateTime? | Soft delete |

**Unique constraints:** characterName

**Relations:** EquipmentInventory (1-N), ConsumableInventory (1-N), CharacterSkill (1-N), CharacterPassive (1-N), PvpMatch (2), DungeonRun (1-N), ShopOfferPurchase (1-N), Friendship (2), DirectMessage (2), Challenge (2), DailyLoginReward (1-N), BattlePass (1-N), DailyGemCard (1-N), AchievementDefinition (1-N), MailRecipient (1-N)

---

## Equipment & Inventory

### Item
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Unique item identifier |
| name | String | Display name |
| type | ItemType | weapon, helmet, chest, gloves, legs, boots, accessory, amulet, belt, relic, necklace, ring, consumable |
| rarity | Rarity | common, uncommon, rare, epic, legendary |
| baseStats | JSON | {str: 5, agi: 3, ...} |
| bonusType | String | How stats apply |
| sellValue | Int | Gold when sold |
| minLevel | Int | Level requirement (default: 1) |
| imageKey | String? | Asset catalog image reference |
| createdAt | DateTime |
| updatedAt | DateTime |

**Unique constraints:** key

**Relations:** EquipmentInventory (1-N), DungeonDrop (1-N)

### EquipmentInventory
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Foreign key to Character |
| itemId | String (UUID) | Foreign key to Item |
| upgradeLevel | Int | Enhancement level (0-10, default: 0) |
| durability | Int | Current durability |
| maxDurability | Int | Max durability |
| isEquipped | Boolean | Currently worn (default: false) |
| equippedSlot | EquippedSlot? | weapon, weapon_offhand, helmet, chest, gloves, legs, boots, accessory, amulet, belt, relic, necklace, ring, ring2 |
| rolledStats | JSON? | {str: +8, agi: +2} |
| createdAt | DateTime |
| updatedAt | DateTime |

**Relations:** Character, Item

### ConsumableInventory
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Foreign key to Character |
| consumableType | ConsumableType | stamina_potion_small, stamina_potion_medium, stamina_potion_large, health_potion_small, health_potion_medium, health_potion_large |
| quantity | Int | Stack count |
| createdAt | DateTime |

**Unique constraints:** (characterId, consumableType)

**Relations:** Character

### StashItem
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| userId | String (UUID) | Owner (gear stash is user-scoped, not character-scoped) |
| itemId | String (UUID) | Catalog reference |
| upgradeLevel | Int | +0..+10 upgrade tier (preserved in stash) |
| durability | Int | Current durability (default 100) |
| maxDurability | Int | Max durability (default 100) |
| rolledStats | JSON? | Rolled stat values at drop time |
| storedAt | DateTime | When moved to stash |
| createdAt / updatedAt | DateTime |

**Indexes:** userId, itemId

**Relations:** User, Item

---

## PvP & Combat

### PvpMatch
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| challengerId | String (UUID) | Player who started fight |
| defenderId | String (UUID) | Opponent |
| isRevenge | Boolean | Revenge match (default: false) |
| challengerRatingBefore | Int | Challenger rating before |
| defenderRatingBefore | Int | Defender rating before |
| challengerRatingAfter | Int | Challenger rating after |
| defenderRatingAfter | Int | Defender rating after |
| winnerId | String (UUID) | Winner ID |
| result | String | WIN, LOSS, DRAW |
| duration | Int | Battle duration (seconds) |
| battleData | JSON | Full fight log |
| createdAt | DateTime |

**Relations:** Character (2 relations)

### Challenge
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| challengerId | String (UUID) | Who sent the challenge |
| defenderId | String (UUID) | Who received it |
| status | ChallengeStatus | pending, accepted, declined, expired, completed |
| matchId | String (UUID)? | Resulting PvP match |
| createdAt | DateTime | Challenge date |
| expiresAt | DateTime | Expiry window |

**Relations:** Character (2)

### PvpBattleTicket
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| opponentId | String (UUID) | Matchmade opponent |
| snapshot | JSON | Character state at creation |
| expiresAt | DateTime | Ticket validity window |
| createdAt | DateTime |

### RevengeQueue
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| victimId | String (UUID) | Player who lost / was attacked |
| attackerId | String (UUID) | Player who initiated the attack |
| matchId | String (UUID) | Source PvpMatch |
| isSeen | Boolean | Victim has viewed the revenge opportunity |
| isUsed | Boolean | Revenge already claimed |
| createdAt | DateTime |
| expiresAt | DateTime | Revenge window (typically 24h) |

**Indexes:** (victimId, isUsed, expiresAt), attackerId, expiresAt

**Relations:** Character (as victim + attacker), PvpMatch, PvpBattleTicket[]

---

## Social

### Friendship
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| userId | String (UUID) | First character |
| friendId | String (UUID) | Second character |
| status | FriendshipStatus | pending, accepted, blocked (default: pending) |
| createdAt | DateTime | Request date |
| updatedAt | DateTime | Last status change |

**Unique constraints:** (userId, friendId)

**Relations:** Character (2)

### DirectMessage
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| senderId | String (UUID) | Sender character |
| receiverId | String (UUID) | Recipient character |
| content | String | Message text |
| isRead | Boolean | Read status (default: false) |
| createdAt | DateTime | Sent at |

**Relations:** Character (2)

---

## Dungeons

### Dungeon
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Unique identifier |
| name | String | Display name |
| type | DungeonType | story, side, event, endgame |
| difficulty | DungeonDifficulty | easy, normal, hard, nightmare, rush |
| minimumLevel | Int | Entry level |
| recommendedPower | Int | Target stat sum |
| floorCount | Int | Number of levels |
| lootTable | JSON | Drop pool configuration |
| createdAt | DateTime |
| updatedAt | DateTime |

**Unique constraints:** key

**Relations:** DungeonBoss (1-N), DungeonWave (1-N), DungeonRun (1-N), DungeonDrop (1-N)

### DungeonBoss
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| dungeonId | String (UUID) | Parent dungeon |
| name | String | Display name |
| health | Int | Boss HP |
| damage | Int | Boss damage |
| defense | Int | Boss defense (default: 0) |
| speed | Int | Boss speed (default: 0) |
| critChance | Float | Boss crit chance (default: 0) |
| description | String? | Boss lore |
| lore | String? | Extended lore |
| imageUrl | String? | Boss image URL |
| imagePrompt | String? | AI image generation prompt |
| floorNumber | Int | Which floor |
| sortOrder | Int | Display order (default: 0) |
| createdAt | DateTime |
| updatedAt | DateTime |

**Relations:** Dungeon, BossAbility (1-N)

### BossAbility
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| bossId | String (UUID) | Parent boss |
| name | String | Ability name |
| abilityType | String | Type identifier |
| damage | Int | Damage dealt (default: 0) |
| cooldown | Int | Cooldown in seconds (default: 0) |
| specialEffect | String? | Special effect description |
| description | String? | Full description |
| createdAt | DateTime |

**Relations:** DungeonBoss

### DungeonWave
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| dungeonId | String (UUID) | Parent dungeon |
| waveNumber | Int | Order (1-N) |
| createdAt | DateTime |

**Unique constraints:** (dungeonId, waveNumber)

**Relations:** Dungeon, DungeonWaveEnemy (1-N)

### DungeonWaveEnemy
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| waveId | String (UUID) | Parent wave |
| enemyType | String | Enemy catalog ID |
| level | Int | Enemy level |
| count | Int | Count per wave (default: 1) |
| createdAt | DateTime |

**Relations:** DungeonWave

### DungeonRun
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| dungeonId | String (UUID) | Which dungeon |
| currentFloor | Int | Progress (0-N) |
| health | Int | Current run HP |
| maxHealth | Int | Run HP cap |
| completedWaves | Int | Defeated enemies |
| goldEarned | BigInt | Current rewards |
| status | String | IN_PROGRESS, COMPLETED, ABANDONED, FAILED |
| startedAt | DateTime |
| finishedAt | DateTime? |
| updatedAt | DateTime |

**Relations:** Character, Dungeon, DungeonDrop (1-N)

### DungeonDrop
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| dungeonId | String (UUID) | Parent dungeon |
| itemId | String (UUID) | Dropped item |
| dropChance | Float | Drop probability (0-100) |
| minQuantity | Int | Min quantity (default: 1) |
| maxQuantity | Int | Max quantity (default: 1) |
| createdAt | DateTime |

**Relations:** Dungeon, Item

### DungeonProgress
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| dungeonId | String (UUID) | Dungeon identifier |
| bossIndex | Int | Current boss cursor inside the dungeon (default 0) |
| completed | Boolean | Whether the whole dungeon has been cleared |
| createdAt / updatedAt | DateTime |

**Unique constraints:** (characterId, dungeonId)
**Indexes:** characterId, (characterId, completed)

**Relations:** Character

---

## Skills

### Skill
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Unique identifier |
| name | String | Display name |
| description | String | How it works |
| skillClass | CharacterClass | Learned by |
| cooldown | Int | Cooldown (milliseconds) |
| manaCost | Int | Resource cost |
| damageType | SkillDamageType | physical, magical, true_damage, poison |
| targetType | SkillTargetType | single_enemy, self_buff, aoe |
| baseScaling | JSON | {str: 1.2, agi: 0.8} |
| unlockLevel | Int | Level requirement |
| createdAt | DateTime |

**Unique constraints:** key

**Relations:** CharacterSkill (1-N)

### CharacterSkill
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| skillId | String (UUID) | Skill |
| skillRank | Int | 1-5 enhancement level (default: 1) |
| equipped | Boolean | In loadout (default: false) |
| equippedSlot | Int? | Hotbar position (1-6) |
| createdAt | DateTime |

**Unique constraints:** (characterId, skillId)

**Relations:** Character, Skill

---

## Passives

### PassiveNode
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Unique identifier |
| name | String | Display name |
| description | String | Passive effect |
| stats | JSON | Granted stats |
| bonusType | PassiveBonusType | flat_stat, percent_stat, flat_damage, percent_damage, flat_crit_chance, flat_dodge_chance, flat_hp, percent_hp, flat_armor, flat_magic_resist, percent_armor, percent_magic_resist, lifesteal, cooldown_reduction, damage_reduction |
| pointCost | Int | Points to unlock |
| nodeClass | CharacterClass? | Class restriction |
| posX | Int | Tree position X |
| posY | Int | Tree position Y |
| createdAt | DateTime |

**Unique constraints:** key

**Relations:** PassiveConnection (2), CharacterPassive (1-N)

### PassiveConnection
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| fromNodeId | String (UUID) | Parent node |
| toNodeId | String (UUID) | Connected node |
| createdAt | DateTime |

**Relations:** PassiveNode (2)

### CharacterPassive
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| passiveNodeId | String (UUID) | Unlocked node |
| unlockedAt | DateTime | When acquired |

**Unique constraints:** (characterId, passiveNodeId)

**Relations:** Character, PassiveNode

### CharacterActiveSlot
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| nodeId | String (UUID)? | Talent node equipped in slot (null when slot holds a consumable) |
| consumableType | ConsumableType? | Consumable equipped in slot (null when slot holds a talent) |
| slotIndex | Int | 0, 1, 2 (3 active slots per character) |
| equippedAt | DateTime |

**Unique constraints:** (characterId, slotIndex)
**Indexes:** characterId

**Relations:** Character, PassiveNode

---

## Shop & Economy

### ShopOffer
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Unique identifier |
| title | String | Display name |
| description | String? | What's included |
| offerType | String | bundle, daily_deal, flash_sale, starter_pack, level_up (default: "bundle") |
| contents | JSON | [{type: "gold"/"gems"/"item"/"consumable", id?: string, quantity: number}] |
| originalPrice | Int | Display-only "was X" |
| salePrice | Int | Actual price |
| currency | String | gold, gems (default: "gold") |
| discountPct | Int | 0-100 (default: 0) |
| maxPurchases | Int | Per character, 0=unlimited (default: 1) |
| minLevel | Int | Min level (default: 1) |
| maxLevel | Int | Max level (default: 999) |
| sortOrder | Int | Display order (default: 0) |
| imageKey | String? | Asset reference |
| tags | String[] | Categorization |
| isActive | Boolean | Currently available (default: false) |
| startsAt | DateTime? | Sale start |
| endsAt | DateTime? | Sale end |
| createdBy | String? | Admin ID |
| createdAt | DateTime |
| updatedAt | DateTime |

**Unique constraints:** key

**Relations:** ShopOfferPurchase (1-N)

### ShopOfferPurchase
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| offerId | String (UUID) | What was bought |
| characterId | String (UUID) | Buyer |
| price | Int | Price paid |
| currency | String | gold, gems |
| createdAt | DateTime |

**Relations:** ShopOffer, Character

### ContrabandClaim
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Claimant |
| contents | JSON | `[{type, id?, quantity}]` — payload granted |
| price | Int | 0 = free, >0 = paid (gold/gems) |
| currency | String | gold \| gems (default: gold) |
| claimNumber | Int | Sequential per character (odd = free, even = paid) |
| claimedAt | DateTime |

**Indexes:** (characterId, claimedAt)

**Relations:** Character

Alternating free/paid contraband drops used by the "blackmarket" progression hook.

---

## Seasons & Battle Pass

### Season
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Unique identifier |
| name | String | Display name |
| description | String | Theme/story |
| seasonNumber | Int | 1, 2, 3, ... |
| startsAt | DateTime | Start date |
| endsAt | DateTime | End date |
| createdAt | DateTime |

**Unique constraints:** key

**Relations:** BattlePass (1-N), BattlePassReward (1-N)

### BattlePass
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| seasonId | String (UUID) | Associated season |
| characterId | String (UUID) | Player |
| currentLevel | Int | Progress (0-100, default: 0) |
| currentXp | Int | XP in level (default: 0) |
| isPremium | Boolean | Premium pass owned (default: false) |
| premiumUnlockedAt | DateTime? | Upgrade date |
| createdAt | DateTime |
| updatedAt | DateTime |

**Unique constraints:** (seasonId, characterId)

**Relations:** Season, Character

### BattlePassReward
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| seasonId | String (UUID) | Season |
| level | Int | Level (1-100) |
| freeReward | JSON | Free track reward |
| premiumReward | JSON | Premium track reward |
| createdAt | DateTime |

**Relations:** Season

### BattlePassClaim
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Claimant |
| battlePassId | String (UUID) | BattlePass row |
| rewardId | String (UUID) | BattlePassReward row |
| claimedAt | DateTime |

**Unique constraints:** (characterId, rewardId)

**Relations:** Character, BattlePass, BattlePassReward

### WeeklyChallengeProgress
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| isoWeek | String | e.g. "2026-W15" |
| slotIndex | Int | 0..4 (5 weekly slots per character) |
| goalType | QuestType | pvp_wins / dungeons_complete / etc. |
| goalTarget | Int | Target value |
| progress | Int | Current progress (default 0) |
| bpXpAward | Int | BP XP granted on completion |
| claimed | Boolean | Reward already claimed |
| completedAt | DateTime? |
| createdAt | DateTime |

**Unique constraints:** (characterId, isoWeek, slotIndex)
**Indexes:** (characterId, isoWeek)

**Relations:** Character

W3.D5 rotating weekly BP challenges — deterministic ISO-week seeded pool selection.

---

## Daily Systems

### DailyLoginReward
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| day | Int | Consecutive day (1-30) |
| reward | JSON | {gold: 1000, items: [...]} |
| claimedAt | DateTime? | Claim time |
| resetAt | DateTime | Reset timestamp |

**Unique constraints:** (characterId, day, resetAt period)

**Relations:** Character

### DailyQuest
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Quest template |
| name | String | Display name |
| description | String | Objective |
| questType | QuestType | pvp_wins, dungeons_complete, gold_spent, item_upgrade, consumable_use, shell_game_play, gold_mine_collect |
| targetValue | Int | How many to complete |
| goldReward | BigInt | Completion reward |
| gemReward | Int | Bonus reward |
| order | Int | Display order |
| createdAt | DateTime |

**Unique constraints:** key

### QuestProgress
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| questId | String (UUID) | Quest |
| progress | Int | Current count |
| completedAt | DateTime? | Completion timestamp |
| resetAt | DateTime | Daily reset timestamp |

**Unique constraints:** (characterId, questId, resetAt period)

**Relations:** Character, DailyQuest

### QuestDefinition
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| questType | String | Unique quest type key (e.g. "pvp_wins") |
| title | String |
| description | String |
| icon | String | Icon key (default "") |
| minTarget | Int | Min target value for randomized generation |
| maxTarget | Int | Max target value |
| rewardGold | Int | Gold reward (default 0) |
| rewardXp | Int | Character XP reward (default 0) |
| rewardGems | Int | Gem reward (default 0) |
| active | Boolean | Feature flag (default true) |
| createdAt / updatedAt | DateTime |

**Unique constraints:** questType

Catalog definitions that drive daily quest generation (one row per `questType`).

### TutorialQuest
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| questId | String | "equip_gear" \| "win_3_pvp" \| "first_dungeon" \| ... |
| progress | Int | Current count (default 0) |
| target | Int | Target count |
| isCompleted | Boolean |
| completedAt | DateTime? |
| rewardClaimed | Boolean |
| createdAt | DateTime |

**Unique constraints:** (characterId, questId)
**Indexes:** characterId

**Relations:** Character

Per-character tutorial onboarding progression rows.

---

## Training & Stamina

### TrainingSession
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| sessionType | String | AI_BATTLE, SPARRING |
| startedAt | DateTime |
| finishedAt | DateTime? |
| stamina | Int | Cost |
| goldReward | Int | Earnings |

**Relations:** Character

---

## Minigames

### GoldMineSession
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Owner |
| slotNumber | Int | Slot 1-5 |
| startedAt | DateTime | Mining start |
| completesAt | DateTime | Completion time |
| goldAmount | BigInt | Rewards |
| collectedAt | DateTime? | Claim time |
| boostedAt | DateTime? | Speed-up time |
| isBoosted | Boolean | Active boost |

**Unique constraints:** (characterId, slotNumber)

**Relations:** Character

### MinigameSession
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| gameType | String | SHELL_GAME, DICE_ROLL |
| wager | Int | Bet amount |
| result | String | WIN, LOSS |
| payout | BigInt | Earnings or loss |
| createdAt | DateTime |

**Relations:** Character

---

## Cosmetics

### Cosmetic
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Unique identifier |
| name | String | Display name |
| type | CosmeticType | frame, title, effect, skin |
| description | String |
| rarity | Rarity | common, uncommon, rare, epic, legendary |
| purchasePrice | Int | Gem cost |
| createdAt | DateTime |

**Unique constraints:** key

### AppearanceSkin
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Owner |
| cosmeticId | String (UUID) | Skin template |
| isPrimary | Boolean | Currently equipped (default: false) |
| unlockedAt | DateTime | Purchase/earn date |

**Relations:** Character, Cosmetic

---

## Events & Milestones

### Event
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Unique identifier |
| name | String | Display name |
| type | EventType | boss_rush, gold_rush, double_xp, drop_rate_boost, class_spotlight, tournament, weekend_warrior |
| description | String | Event details |
| multiplier | Float? | Bonus multiplier |
| startsAt | DateTime | Event start |
| endsAt | DateTime | Event end |
| isActive | Boolean | Currently running (default: false) |
| createdAt | DateTime |

**Unique constraints:** key

### MilestoneClaim
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| milestoneKey | String | Milestone identifier |
| claimedAt | DateTime | Claim time |

**Unique constraints:** (characterId, milestoneKey)

**Relations:** Character

### GuildChallenge
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| title | String |
| description | String |
| goalType | String | "pvp_wins" \| "gold_earned" \| "dungeons_cleared" |
| goalTarget | Int | Server-wide / guild target (e.g. 500 total wins) |
| currentProgress | Int | Aggregate progress (default 0) |
| goldReward | Int | Reward on completion |
| gemReward | Int | (default 0) |
| startAt / endAt | DateTime |
| completed | Boolean |
| claimed | Boolean |
| createdAt | DateTime |

**Indexes:** (startAt, endAt)

Global/guild-level LiveOps challenges with a shared pool goal.

### ReferralRewardClaim
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| referrerCharacterId | String (UUID) | Referrer |
| inviteeCharacterId | String (UUID) | Invitee whose qualification unlocked the reward |
| qualifiedAt | DateTime |

**Unique constraints:** (referrerCharacterId, inviteeCharacterId)
**Indexes:** referrerCharacterId, inviteeCharacterId

**Relations:** Character (as referrer + invitee)

---

## Achievements

### Achievement
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | Unique identifier |
| name | String | Display name |
| description | String | How to earn |
| category | String | pvp, progression, ranking |
| rewardType | String | gold, gems, cosmetic |
| rewardAmount | Int | Value |
| createdAt | DateTime |

**Unique constraints:** key

### AchievementDefinition
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| achievementId | String (UUID) | Template |
| characterId | String (UUID) | Player |
| progress | Int | Current (e.g., wins 23/50, default: 0) |
| isUnlocked | Boolean | Earned (default: false) |
| unlockedAt | DateTime? | Date earned |

**Unique constraints:** (achievementId, characterId)

**Relations:** Achievement, Character

---

## Mail

### MailMessage
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| subject | String | Subject line |
| content | String | Message body (markdown) |
| attachments | JSON | Items/gold/gems to attach |
| createdAt | DateTime |

### MailRecipient
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| mailId | String (UUID) | Message |
| recipientId | String (UUID) | Character |
| isRead | Boolean | Opened (default: false) |
| itemsClaimed | Boolean | Attachments collected (default: false) |
| readAt | DateTime? |
| claimedAt | DateTime? |
| deletedAt | DateTime? |

**Relations:** MailMessage, Character

---

## Configuration & Admin

### GameConfig
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | e.g., "max_stamina", "daily_login_gold" |
| value | String / JSON | Config value |
| dataType | String | INT, FLOAT, STRING, JSON |
| description | String | What it controls |
| modifiedBy | String? | Admin ID |
| modifiedAt | DateTime | Last change |

**Unique constraints:** key

### FeatureFlag
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | e.g., "enable_new_dungeon" |
| flagType | String | BOOLEAN, PERCENTAGE, SEGMENT, JSON |
| value | String / JSON | Current value |
| isEnabled | Boolean | Global on/off (default: false) |
| createdAt | DateTime |
| updatedAt | DateTime |

**Unique constraints:** key

### DesignToken
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| key | String | e.g., "color_gold_primary" |
| type | String | COLOR, SIZE, FONT, SPACING |
| value | String | Token value (hex, px, etc.) |
| iosValue | String? | Platform override |
| androidValue | String? | Platform override |
| createdAt | DateTime |

**Unique constraints:** key

### ConfigSnapshot
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| name | String | Snapshot label (e.g. "pre-v3-balance-2026-04-13") |
| description | String? |
| configs | JSON | Full serialized GameConfig / FeatureFlag state |
| createdBy | String | Admin user id |
| createdAt | DateTime |

Snapshots of live config state for rollback / audit.

---

## Analytics & Moderation

### AdminLog
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| adminId | String (UUID) | Who did it |
| action | String | CREATE_ITEM, BAN_USER, etc. |
| targetId | String? | Affected user/item |
| details | JSON | Action details |
| createdAt | DateTime |

### ItemBalanceProfile
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| name | String | Label for sim |
| itemStats | JSON | Item modifications |
| createdBy | String (UUID) | Admin |
| createdAt | DateTime |

### BalanceSimulationRun
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| profileId | String (UUID) | Profile used |
| matchups | JSON | Combat results |
| itemImpact | JSON | Performance changes |
| verdict | String | Balanced, OP, UP |
| createdAt | DateTime |

### PushLog
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| campaignId | String (UUID)? | PushCampaign reference (null for 1:1 sends) |
| userId | String (UUID) | Recipient |
| token | String | Device token used |
| title | String |
| body | String |
| status | String | sent \| delivered \| failed |
| error | String? | APNs/FCM error message |
| createdAt | DateTime |

**Indexes:** campaignId, (userId, createdAt DESC)

Per-send audit trail for push delivery.

---

## In-App Purchases

### IapTransaction
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| userId | String (UUID) | Buyer |
| productId | String | Apple product ID |
| transactionId | String | Apple receipt ID |
| gemsAwarded | Int | Gems purchased |
| goldAwarded | BigInt? | Gold bonus (if any) |
| price | String | Currency amount |
| currency | String | USD, GBP, JPY, etc. |
| receipt | String | Encrypted Apple receipt |
| verified | Boolean | Server-verified (default: false) |
| createdAt | DateTime |

### PremiumSubscription
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| userId | String (UUID) | Unique — one row per user |
| productId | String | e.g. `premium_pass_monthly` |
| originalTransactionId | String | Apple ORIGINAL tx id (stable across renewals) |
| latestTransactionId | String | Most recent Apple tx id |
| startedAt | DateTime |
| expiresAt | DateTime | Includes Apple's 16-day billing retry window |
| autoRenew | Boolean | default true |
| status | String | active \| grace_period \| expired \| refunded |
| latestReceipt | String? | Opaque receipt blob for re-verification |
| createdAt / updatedAt | DateTime |

**Unique constraints:** userId
**Indexes:** originalTransactionId, expiresAt

**Relations:** User (1:1)

Premium Pass (30-day auto-renewable). `hasPremium()` reads `max(user.premiumUntil, premiumSubscription.expiresAt)` so legacy `premium_forever` owners and Pass holders coexist. See `docs/06_game_systems/PREMIUM_PASS_MIGRATION.md`.

---

## Miscellaneous

### DailyGemCard
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Owner |
| cardIndex | Int | 0-4 (5 cards) |
| revealed | Boolean | Flipped (default: false) |
| revealedAt | DateTime? |
| resetAt | DateTime | Daily reset |

**Relations:** Character

### PushToken
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| userId | String (UUID) | Device owner |
| token | String | FCM / APNs token |
| platform | String | IOS, ANDROID, WEB |
| isActive | Boolean | Device still registered (default: true) |
| registeredAt | DateTime |
| lastUsedAt | DateTime? |

**Relations:** User

### PushCampaign
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| name | String | Label |
| targetSegment | String | ALL, NEW_PLAYERS, VIP |
| title | String | Notification title |
| body | String | Notification body |
| deepLink | String? | Action URL |
| sentAt | DateTime? | Delivery time |
| createdBy | String (UUID) | Admin ID |

### LegendaryShard
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Owner |
| shardType | String | LEGENDARY_WEAPON, LEGENDARY_ARMOR, etc. |
| quantity | Int | Count toward completion |
| completedAt | DateTime? | Full shard earned |

**Relations:** Character

---

## Enums

**CharacterClass:** warrior, rogue, mage, tank

**CharacterOrigin:** human, orc, skeleton, demon, dogfolk

**CharacterGender:** male, female

**ItemType:** weapon, helmet, chest, gloves, legs, boots, accessory, amulet, belt, relic, necklace, ring, consumable

**Rarity:** common, uncommon, rare, epic, legendary

**EquippedSlot:** weapon, weapon_offhand, helmet, chest, gloves, legs, boots, accessory, amulet, belt, relic, necklace, ring, ring2

**ConsumableType:** stamina_potion_small, stamina_potion_medium, stamina_potion_large, health_potion_small, health_potion_medium, health_potion_large

**QuestType:** pvp_wins, dungeons_complete, gold_spent, item_upgrade, consumable_use, shell_game_play, gold_mine_collect

**CosmeticType:** frame, title, effect, skin

**EventType:** boss_rush, gold_rush, double_xp, drop_rate_boost, class_spotlight, tournament, weekend_warrior

**DungeonDifficulty:** easy, normal, hard, nightmare, rush

**DungeonType:** story, side, event, endgame

**SkillDamageType:** physical, magical, true_damage, poison

**SkillTargetType:** single_enemy, self_buff, aoe

**PassiveBonusType:** flat_stat, percent_stat, flat_damage, percent_damage, flat_crit_chance, flat_dodge_chance, flat_hp, percent_hp, flat_armor, flat_magic_resist, percent_armor, percent_magic_resist, lifesteal, cooldown_reduction, damage_reduction

**ChallengeStatus:** pending, accepted, declined, expired, completed

**FriendshipStatus:** pending, accepted, blocked

**UserRole:** admin, moderator, player

**Notes:**
- Character stats are 8-dimensional: STR, AGI, VIT, END, INT, WIS, LUK, CHA (not 6)
- User authentication uses generic `authProvider` field, not separate googleId/appleId
- ConsumableType values include size variants (small/medium/large)
- QuestType has 7 values reflecting actual quest mechanics
- EventType has 7 event types for variety in live operations
- BossAbility is a separate model for granular boss ability management
- EquippedSlot includes ring2 for dual-ring support
- PassiveBonusType includes comprehensive damage/defense scaling and utility effects
