import { createHash } from 'crypto'

export const BOT_TICKET_SECRET_MISSING = 'BOT_TICKET_SECRET_MISSING'

function getBotTicketSecret(): string {
  const secret = process.env.BOT_TICKET_SECRET
  if (!secret) throw new Error(BOT_TICKET_SECRET_MISSING)
  return secret
}

export function createBotBattleTicketId(
  characterId: string,
  opponentId: string,
  battleSeed: number,
): string {
  const secret = getBotTicketSecret()

  return `bot_${createHash('sha256')
    .update(`${characterId}:${opponentId}:${battleSeed}:${secret}`)
    .digest('hex')
    .slice(0, 32)}`
}
