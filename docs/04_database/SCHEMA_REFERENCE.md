# Database Schema Reference (Source of Truth)
*Derived from Prisma schema. Updated: 2026-03-29*

## Core User & Auth

### User
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| email | String | Unique |
| username | String | Unique |
| passwordHash | String? | Null for OAuth users |
| googleId | String? | Google OAuth |
| appleId | String? | Apple OAuth |
| gems | Int | Premium currency (default: 0) |
| gold | Int | Soft currency (default: 0) |
| role | UserRole | ADMIN, MODERATOR, PLAYER (default: PLAYER) |
| isBanned | Boolean | Default: false |
| banReason | String? | Ban details |
| createdAt | DateTime | Account creation |
| updatedAt | DateTime | Last modified |

**Unique constraints:** email, username, googleId, appleId

**Relations:** Character (1-N), Mail (1-N), Achievements (1-N), Training (1-N), GoldMine (1-N), Minigames (1-N)

---

## Characters

### Character
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| userId | String (UUID) | Foreign key to User |
| characterName | String | Unique per user |
| class | CharacterClass | WARRIOR, ROGUE, MAGE, TANK |
| origin | CharacterOrigin | HUMAN, ORC, SKELETON, DEMON, DOGFOLK |
| gender | CharacterGender | MALE, FEMALE |
| level | Int | Current level (1-100) |
| experience | BigInt | XP to next level |
| health | Int | Current HP |
| maxHealth | Int | Max HP from stats |
| strength | Int | STR stat |
| constitution | Int | CON stat |
| dexterity | Int | DEX stat |
| intelligence | Int | INT stat |
| wisdom | Int | WIS stat |
| charisma | Int | CHA stat |
| damage | Int | Calculated from STR |
| armor | Int | Calculated from CON/DEX |
| gold | BigInt | Soft currency |
| gems | Int | Premium currency override |
| pvpRating | Int | Elo rating (default: 1600) |
| stamina | Int | Current stamina |
| maxStamina | Int | Stamina cap |
| inventorySlots | Int | Usable slots (default: 20) |
| skillPoints | Int | Unallocated points |
| passivePoints | Int | Unallocated points |
| createdAt | DateTime | Creation date |
| updatedAt | DateTime | Last modified |
| deletedAt | DateTime? | Soft delete |

**Unique constraints:** (userId, characterName)

**Relations:** EquipmentInventory (1-N), ConsumableInventory (1-N), Skills (1-N), Passives (1-N), PvpMatches (1-N), Dungeons (1-N)

---

## Equipment & Inventory

### Item
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Unique item identifier |
| itemName | String | Display name |
| itemType | ItemType | WEAPON, HELMET, CHEST, etc. |
| rarity | ItemRarity | COMMON, UNCOMMON, RARE, EPIC, LEGENDARY |
| baseStats | JSON | {strength: 5, dexterity: 3, ...} |
| bonusType | BonusType | How stats apply |
| restrictions | JSON? | Class/level restrictions |
| shopPrice | Int | Gold cost |
| shopGemPrice | Int? | Gem cost (if premium) |
| sellValue | Int | Gold when sold |
| minLevel | Int | Level requirement (default: 1) |
| rollableStats | JSON | Which stats can roll |
| createdAt | DateTime |

**Relations:** EquipmentInventory (1-N)

### EquipmentInventory
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Foreign key to Character |
| itemId | String (UUID) | Foreign key to Item |
| upgradeLevel | Int | Enhancement level (0-10) |
| durability | Int | Current durability |
| maxDurability | Int | Max durability |
| isEquipped | Boolean | Currently worn |
| equippedSlot | EquipSlot? | WEAPON, HEAD, CHEST, etc. |
| rolledStats | JSON? | {strength: +8, dex: +2} |
| createdAt | DateTime |

**Unique constraints:** (characterId, itemId, equippedSlot) when isEquipped = true

**Relations:** Character, Item

### ConsumableInventory
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Foreign key to Character |
| consumableType | ConsumableType | HEALTH_POTION, STAMINA_RESTORE, BUFF_ATTACK, etc. |
| quantity | Int | Stack count |
| createdAt | DateTime |

**Unique constraints:** (characterId, consumableType)

**Relations:** Character

---

## PvP & Combat

### PvpMatch
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| challengerId | String (UUID) | Player who started fight |
| defenderId | String (UUID) | Opponent |
| isRevenge | Boolean | Revenge match |
| challengerBefore | Int | Challenger rating before |
| defenderBefore | Int | Defender rating before |
| challengerAfter | Int | Challenger rating after |
| defenderAfter | Int | Defender rating after |
| winner | String (UUID) | Winner ID |
| result | BattleResult | WIN, LOSS, DRAW |
| duration | Int | Battle duration (seconds) |
| battleData | JSON | Full fight log |
| createdAt | DateTime |

**Relations:** Character (2 relations), RevengeQueue

### RevengeQueue
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Who lost |
| opponentId | String (UUID) | Who won |
| matchId | String (UUID) | Original match |
| expiresAt | DateTime | Revenge window closes |
| createdAt | DateTime |

### PvpBattleTicket
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| opponentId | String (UUID) | Matchmade opponent |
| snapshot | JSON | Character state at creation |
| expiresAt | DateTime | Ticket validity window |
| createdAt | DateTime |

---

## Social

### Friendship
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| requesterId | String (UUID) | Who sent the request |
| receiverId | String (UUID) | Who received it |
| status | FriendshipStatus | PENDING, ACCEPTED, BLOCKED |
| createdAt | DateTime | Request date |
| updatedAt | DateTime | Last status change |

**Unique constraints:** (requesterId, receiverId)

### DirectMessage
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| senderId | String (UUID) | Sender character |
| receiverId | String (UUID) | Recipient character |
| content | String | Message text |
| isRead | Boolean | Read status |
| createdAt | DateTime | Sent at |

### Challenge
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| challengerId | String (UUID) | Who sent the challenge |
| defenderId | String (UUID) | Who received it |
| status | ChallengeStatus | PENDING, ACCEPTED, DECLINED, EXPIRED, COMPLETED |
| matchId | String (UUID)? | Resulting PvP match |
| createdAt | DateTime | Challenge date |
| expiresAt | DateTime | Expiry window |

### GuildChallenge
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| challengeType | String | Weekly challenge type |
| targetValue | Int | Community goal |
| currentValue | Int | Current progress |
| reward | JSON | Community reward |
| startsAt | DateTime | Challenge start |
| endsAt | DateTime | Challenge end |
| createdAt | DateTime |

---

## Dungeons

### Dungeon
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Unique identifier |
| dungeonName | String | Display name |
| minimumLevel | Int | Entry level |
| difficulty | DifficultyTier | EASY, NORMAL, HARD, NIGHTMARE |
| recommendedPower | Int | Target stats |
| floors | Int | Number of levels |
| bossHealth | Int | Boss HP per floor |
| lootTable | JSON | Drop pool |
| createdAt | DateTime |

### DungeonBoss
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| dungeonId | String (UUID) | Parent dungeon |
| bossName | String | Display name |
| baseHealth | Int | HP formula |
| baseStats | JSON | {strength: 20, ...} |
| abilities | JSON | Boss moves |
| createdAt | DateTime |

### DungeonWave
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| dungeonId | String (UUID) | Parent dungeon |
| waveNumber | Int | Order (1-N) |
| enemyCount | Int | Mobs per wave |
| enemyType | String | Mob catalog ID |
| createdAt | DateTime |

### DungeonWaveEnemy
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| waveId | String (UUID) | Parent wave |
| enemyName | String | Display name |
| baseHealth | Int | HP |
| baseStats | JSON | {strength: 10, ...} |
| createdAt | DateTime |

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
| status | DungeonStatus | IN_PROGRESS, COMPLETED, ABANDONED, FAILED |
| startedAt | DateTime |
| finishedAt | DateTime? |
| updatedAt | DateTime |

**Relations:** DungeonProgress (1-N), DungeonDrop (1-N)

### DungeonProgress
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| runId | String (UUID) | Parent run |
| floor | Int | Floor number |
| wavesSurvived | Int | Enemies defeated |
| bossDefeated | Boolean | Boss killed |

### DungeonDrop
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| runId | String (UUID) | Parent run |
| itemId | String (UUID) | Dropped item |
| amount | Int | Quantity (for gold/consumables) |
| claimedAt | DateTime? | Pickup time |

---

## Skills

### Skill
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Unique identifier |
| skillName | String | Display name |
| description | String | How it works |
| skillClass | CharacterClass | Learned by |
| cooldown | Int | Cooldown (seconds) |
| manaCost | Int | Resource cost |
| baseScaling | JSON | {strength: 1.2, dex: 0.8} |
| unlockLevel | Int | Level requirement |
| createdAt | DateTime |

### CharacterSkill
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| skillId | String (UUID) | Skill |
| skillRank | Int | 1-5 enhancement level |
| equipped | Boolean | In loadout |
| equippedSlot | Int | Hotbar position (1-6) |
| createdAt | DateTime |

**Unique constraints:** (characterId, skillId), (characterId, equippedSlot) when equipped = true

---

## Passives

### PassiveNode
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Unique identifier |
| nodeName | String | Display name |
| description | String | Passive effect |
| stats | JSON | Granted stats |
| pointCost | Int | Points to unlock |
| nodeClass | CharacterClass? | Class restriction |
| posX | Int | Tree position X |
| posY | Int | Tree position Y |
| createdAt | DateTime |

### PassiveConnection
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| fromNodeId | String (UUID) | Parent node |
| toNodeId | String (UUID) | Connected node |
| createdAt | DateTime |

### CharacterPassive
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| passiveNodeId | String (UUID) | Unlocked node |
| unlockedAt | DateTime | When acquired |

**Unique constraints:** (characterId, passiveNodeId)

---

## Shop & Economy

### ShopOffer
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Unique identifier |
| offerName | String | Bundle name |
| description | String | What's included |
| items | JSON | [{itemId: "...", quantity: 5}, ...] |
| goldPrice | BigInt | Gold cost |
| gemPrice | Int? | Gem cost |
| isBundle | Boolean | Cosmetic grouping |
| isFlashSale | Boolean | Limited-time flag |
| startsAt | DateTime? | Sale start |
| endsAt | DateTime? | Sale end |
| maxPurchases | Int? | Limit per player |
| createdAt | DateTime |

### ShopOfferPurchase
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Buyer |
| offerId | String (UUID) | What was bought |
| purchasedAt | DateTime |

---

## Seasons & Battle Pass

### Season
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Unique identifier (e.g., "s1_dawn") |
| seasonName | String | Display name |
| description | String | Theme/story |
| startsAt | DateTime | Start date |
| endsAt | DateTime | End date |
| seasonNumber | Int | 1, 2, 3, ... |
| createdAt | DateTime |

### BattlePass
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| seasonId | String (UUID) | Associated season |
| characterId | String (UUID) | Player |
| currentLevel | Int | Progress (0-100) |
| currentXp | Int | XP in level |
| isPremium | Boolean | Premium pass owned |
| premiumUnlockedAt | DateTime? | Upgrade date |

**Unique constraints:** (seasonId, characterId)

### BattlePassReward
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| seasonId | String (UUID) | Season |
| level | Int | Level (1-100) |
| freeReward | JSON | Free track reward |
| premiumReward | JSON | Premium track reward |
| createdAt | DateTime |

### BattlePassClaim
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| battlePassId | String (UUID) | Character's pass |
| rewardLevel | Int | Which level |
| track | BPTrack | FREE, PREMIUM |
| claimedAt | DateTime |

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

**Unique constraints:** (characterId, day) per reset cycle

### DailyQuest
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Quest template |
| questName | String | Display name |
| description | String | Objective |
| questType | QuestType | PVP_WINS, DUNGEON_CLEARS, etc. |
| targetValue | Int | How many to complete |
| goldReward | BigInt | Completion reward |
| gemReward | Int | Bonus reward |
| order | Int | Display order |
| createdAt | DateTime |

### QuestDefinition
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| questKey | String | Unique template key |
| questName | String | Display name |
| description | String | Objective text |
| questType | QuestType | PVP_WINS, DUNGEON_CLEARS, etc. |
| targetValue | Int | Required count |
| goldReward | BigInt | Gold payout |
| gemReward | Int | Gem payout |
| createdAt | DateTime |
| updatedAt | DateTime |

---

## Training & Stamina

### TrainingSession
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| sessionType | TrainingType | AI_BATTLE, SPARRING |
| startedAt | DateTime |
| finishedAt | DateTime? |
| stamina | Int | Cost |
| goldReward | Int | Earnings |

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

### MinigameSession
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| gameType | GameType | SHELL_GAME, DICE_ROLL |
| wager | Int | Bet amount |
| result | GameResult | WIN, LOSS |
| payout | BigInt | Earnings or loss |
| createdAt | DateTime |

---

## Cosmetics

### Cosmetic
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Unique identifier |
| cosmeticName | String | Display name |
| cosmeticType | CosmeticType | APPEARANCE, EFFECT, EMOTE, TITLE |
| description | String |
| rarity | ItemRarity | COMMON, RARE, LEGENDARY |
| purchasePrice | Int | Gem cost |
| createdAt | DateTime |

### AppearanceSkin
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Owner |
| cosmeticId | String (UUID) | Skin template |
| isPrimary | Boolean | Currently equipped |
| unlockedAt | DateTime | Purchase/earn date |

---

## Events & Milestones

### Event
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Unique identifier |
| eventName | String | Display name |
| eventType | EventType | BOSS_RUSH, GOLD_RUSH, XP_BOOST, etc. |
| description | String | Event details |
| multiplier | Float? | Bonus multiplier |
| startsAt | DateTime | Event start |
| endsAt | DateTime | Event end |
| isActive | Boolean | Currently running |
| createdAt | DateTime |

### MilestoneClaim
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Player |
| milestoneKey | String | Milestone identifier |
| claimedAt | DateTime | Claim time |

**Unique constraints:** (characterId, milestoneKey)

---

## Achievements

### Achievement
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| catalogId | String | Unique identifier |
| achievementName | String | Display name |
| description | String | How to earn |
| rewardType | String | Gold, gems, cosmetic |
| rewardAmount | Int | Value |
| createdAt | DateTime |

### AchievementDefinition
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| achievementId | String (UUID) | Template |
| characterId | String (UUID) | Player |
| progress | Int | Current (e.g., wins 23/50) |
| isUnlocked | Boolean | Earned |
| unlockedAt | DateTime? | Date earned |

**Unique constraints:** (achievementId, characterId)

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
| isRead | Boolean | Opened |
| itemsClaimed | Boolean | Attachments collected |
| readAt | DateTime? |
| claimedAt | DateTime? |
| deletedAt | DateTime? |

---

## Configuration & Admin

### GameConfig
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| configKey | String | e.g., "max_stamina", "daily_login_gold" |
| value | String / JSON | Config value |
| dataType | ConfigType | INT, FLOAT, STRING, JSON |
| description | String | What it controls |
| modifiedBy | String (UUID) | Admin who changed it |
| modifiedAt | DateTime |

### ConfigSnapshot
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| snapshotName | String | Label (e.g., "Balance Pass v2") |
| configSnapshot | JSON | Full config at moment |
| createdBy | String (UUID) | Admin |
| createdAt | DateTime |
| note | String? | Change notes |

### FeatureFlag
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| flagKey | String | e.g., "enable_new_dungeon" |
| flagType | FeatureFlagType | BOOLEAN, PERCENTAGE, SEGMENT, JSON |
| value | String / JSON | Current value |
| isEnabled | Boolean | Global on/off |
| createdAt | DateTime |
| updatedAt | DateTime |

### DesignToken
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| tokenKey | String | e.g., "color_gold_primary" |
| tokenType | TokenType | COLOR, SIZE, FONT, SPACING |
| value | String | Token value (hex, px, etc.) |
| iosValue | String? | Platform override |
| androidValue | String? | Platform override |
| createdAt | DateTime |

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
| profileName | String | Label for sim |
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
| verified | Boolean | Server-verified |
| createdAt | DateTime |

---

## Miscellaneous

### DailyGemCard
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Owner |
| cardIndex | Int | 0-4 (5 cards) |
| revealed | Boolean | Flipped |
| revealedAt | DateTime? |
| resetAt | DateTime | Daily reset |

### PushToken
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| userId | String (UUID) | Device owner |
| token | String | FCM / APNs token |
| platform | Platform | IOS, ANDROID, WEB |
| isActive | Boolean | Device still registered |
| registeredAt | DateTime |
| lastUsedAt | DateTime? |

### PushCampaign
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| campaignName | String | Label |
| targetSegment | String | ALL, NEW_PLAYERS, VIP |
| title | String | Notification title |
| body | String | Notification body |
| deepLink | String? | Action URL |
| sentAt | DateTime? | Delivery time |
| createdBy | String (UUID) | Admin |

### PushLog
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| campaignId | String (UUID) | Which campaign |
| tokenId | String (UUID) | Recipient device |
| status | PushStatus | SENT, FAILED, OPENED |
| sentAt | DateTime |

### LegendaryShard
| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Primary key |
| characterId | String (UUID) | Owner |
| shardType | String | LEGENDARY_WEAPON, LEGENDARY_ARMOR, etc. |
| quantity | Int | Count toward completion |
| completedAt | DateTime? | Full shard earned |

---

## Enums

**CharacterClass:** WARRIOR, ROGUE, MAGE, TANK

**CharacterOrigin:** HUMAN, ORC, SKELETON, DEMON, DOGFOLK

**CharacterGender:** MALE, FEMALE

**ItemType:** WEAPON, HELMET, CHEST, GLOVES, LEGS, BOOTS, ACCESSORY, AMULET, BELT, RELIC, NECKLACE, RING, CONSUMABLE

**ItemRarity:** COMMON, UNCOMMON, RARE, EPIC, LEGENDARY

**DamageType:** PHYSICAL, MAGICAL, TRUE_DAMAGE, POISON

**BonusType:** FLAT_STAT, PERCENT_STAT, CONDITIONAL, TRIGGER

**EquipSlot:** WEAPON, HEAD, CHEST, HANDS, LEGS, FEET, ACCESSORY, AMULET, BELT, RELIC, NECK, RING_1, RING_2

**ConsumableType:** HEALTH_POTION, STAMINA_RESTORE, BUFF_ATTACK, BUFF_DEFENSE, BUFF_XP, BUFF_GOLD

**BattleResult:** WIN, LOSS, DRAW

**DifficultyTier:** EASY, NORMAL, HARD, NIGHTMARE

**DungeonStatus:** IN_PROGRESS, COMPLETED, ABANDONED, FAILED

**QuestType:** PVP_WINS, DUNGEON_CLEARS, SKILL_USES, LEVEL_UP, EQUIP_ITEMS

**TrainingType:** AI_BATTLE, SPARRING

**GameType:** SHELL_GAME, DICE_ROLL

**GameResult:** WIN, LOSS

**CosmeticType:** APPEARANCE, EFFECT, EMOTE, TITLE

**UserRole:** ADMIN, MODERATOR, PLAYER

**BPTrack:** FREE, PREMIUM

**Platform:** IOS, ANDROID, WEB

**PushStatus:** SENT, FAILED, OPENED

**TokenType:** COLOR, SIZE, FONT, SPACING

**FeatureFlagType:** BOOLEAN, PERCENTAGE, SEGMENT, JSON

**ConfigType:** INT, FLOAT, STRING, JSON

**FriendshipStatus:** PENDING, ACCEPTED, BLOCKED

**ChallengeStatus:** PENDING, ACCEPTED, DECLINED, EXPIRED, COMPLETED

**EventType:** BOSS_RUSH, GOLD_RUSH, XP_BOOST, DROP_BOOST, PVP_TOURNAMENT

**MailTargetType:** USER, SEGMENT, BROADCAST
