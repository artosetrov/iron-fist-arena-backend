const REWARD_TYPE_LABELS: Record<string, string> = {
  gold: 'Gold',
  gems: 'Gems',
  xp: 'XP',
  stamina: 'Stamina',
  chest: 'Chest',
  skin: 'Skin',
  item: 'Item',
  consumable: 'Consumable',
  cosmetic: 'Cosmetic',
  title: 'Title',
  frame: 'Frame',
  effect: 'Effect',
}

export function formatRewardTypeName(rewardType: string): string {
  return REWARD_TYPE_LABELS[rewardType] ?? rewardType
}
