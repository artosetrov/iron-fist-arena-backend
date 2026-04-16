export type QuestDefinitionRecord = {
  id: string
  questType: string
  title: string
  description: string
  icon: string
  minTarget: number
  maxTarget: number
  rewardGold: number
  rewardXp: number
  rewardGems: number
  active: boolean
}

export type QuestDefinitionInput = {
  questType?: string
  title?: string
  description?: string
  icon?: string
  minTarget?: number
  maxTarget?: number
  rewardGold?: number
  rewardXp?: number
  rewardGems?: number
  active?: boolean
}

function parseNonNegativeInt(value: unknown, label: string): number {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new Error(`${label} must be a non-negative integer`)
  }

  return parsed
}

function parsePositiveInt(value: unknown, label: string): number {
  const parsed = typeof value === 'number' ? value : Number.parseInt(String(value), 10)
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error(`${label} must be a positive integer`)
  }

  return parsed
}

export function normalizeQuestType(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
}

export function sanitizeQuestDefinitionInput(
  input: QuestDefinitionInput,
  existing?: Omit<QuestDefinitionRecord, 'id'>
) {
  const questType = input.questType !== undefined
    ? normalizeQuestType(input.questType)
    : existing?.questType ?? ''
  const title = input.title !== undefined ? input.title.trim() : existing?.title ?? ''
  const description = input.description !== undefined ? input.description.trim() : existing?.description ?? ''

  if (!questType) throw new Error('Quest type is required')
  if (!title) throw new Error('Title is required')
  if (!description) throw new Error('Description is required')

  const minTarget = input.minTarget !== undefined
    ? parsePositiveInt(input.minTarget, 'Min target')
    : existing?.minTarget ?? 1
  const maxTarget = input.maxTarget !== undefined
    ? parsePositiveInt(input.maxTarget, 'Max target')
    : existing?.maxTarget ?? minTarget

  if (minTarget > maxTarget) {
    throw new Error('Min target cannot exceed max target')
  }

  return {
    questType,
    title,
    description,
    icon: input.icon !== undefined ? input.icon.trim() : existing?.icon ?? '',
    minTarget,
    maxTarget,
    rewardGold: input.rewardGold !== undefined ? parseNonNegativeInt(input.rewardGold, 'Gold reward') : existing?.rewardGold ?? 0,
    rewardXp: input.rewardXp !== undefined ? parseNonNegativeInt(input.rewardXp, 'XP reward') : existing?.rewardXp ?? 0,
    rewardGems: input.rewardGems !== undefined ? parseNonNegativeInt(input.rewardGems, 'Gems reward') : existing?.rewardGems ?? 0,
    active: input.active ?? existing?.active ?? true,
  }
}
