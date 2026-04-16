export const BATTLE_PASS_REWARD_TYPES = [
  'gold',
  'gems',
  'xp',
  'stamina',
  'item',
  'chest',
  'consumable',
  'cosmetic',
  'skin',
  'title',
  'frame',
  'effect',
] as const

export type BattlePassRewardType = typeof BATTLE_PASS_REWARD_TYPES[number]

export type SeasonRecord = {
  id: string
  number: number
  theme: string | null
}

export type BattlePassRewardRecord = {
  id: string
  seasonId: string
  bpLevel: number
  isPremium: boolean
  rewardType: string
  rewardId: string | null
  rewardAmount: number
  season: SeasonRecord
}

type RewardInput = {
  seasonId?: string
  bpLevel?: number
  isPremium?: boolean
  rewardType?: string
  rewardId?: string | null
  rewardAmount?: number
}

function parsePositiveInt(value: unknown, label: string): number {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error(`${label} must be a positive integer`)
  }

  return parsed
}

export function parseBattlePassRewardType(value: unknown): BattlePassRewardType {
  if (typeof value !== 'string') {
    throw new Error('Reward type is required')
  }

  const normalized = value.trim().toLowerCase()
  if (!BATTLE_PASS_REWARD_TYPES.includes(normalized as BattlePassRewardType)) {
    throw new Error('Invalid reward type')
  }

  return normalized as BattlePassRewardType
}

function normalizeRewardId(value: string | null | undefined): string | null {
  if (value === undefined || value === null) return null
  const normalized = value.trim()
  return normalized.length > 0 ? normalized : null
}

export function battlePassRewardTypeRequiresId(
  rewardType: BattlePassRewardType
): boolean {
  return ['item', 'consumable', 'cosmetic', 'skin', 'title', 'frame', 'effect'].includes(rewardType)
}

export function sanitizeBattlePassRewardInput(input: RewardInput, existing?: {
  seasonId?: string
  bpLevel?: number
  isPremium?: boolean
  rewardType?: string
  rewardId?: string | null
  rewardAmount?: number
}) {
  const seasonId = input.seasonId ?? existing?.seasonId ?? ''
  if (!seasonId.trim()) throw new Error('Season is required')

  const rewardType = input.rewardType !== undefined
    ? parseBattlePassRewardType(input.rewardType)
    : parseBattlePassRewardType(existing?.rewardType ?? '')

  const rewardId = normalizeRewardId(input.rewardId !== undefined ? input.rewardId : existing?.rewardId ?? null)
  if (battlePassRewardTypeRequiresId(rewardType) && !rewardId) {
    throw new Error(`Reward ID is required for ${rewardType}`)
  }

  return {
    seasonId,
    bpLevel: input.bpLevel !== undefined ? parsePositiveInt(input.bpLevel, 'Battle Pass level') : parsePositiveInt(existing?.bpLevel, 'Battle Pass level'),
    isPremium: input.isPremium ?? existing?.isPremium ?? false,
    rewardType,
    rewardId,
    rewardAmount: input.rewardAmount !== undefined ? parsePositiveInt(input.rewardAmount, 'Reward amount') : parsePositiveInt(existing?.rewardAmount, 'Reward amount'),
  }
}
