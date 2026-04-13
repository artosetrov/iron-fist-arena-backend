import { afterEach, describe, expect, it } from 'vitest'
import { BOT_TICKET_SECRET_MISSING, createBotBattleTicketId } from '@/lib/game/bot-ticket'

const originalSecret = process.env.BOT_TICKET_SECRET

afterEach(() => {
  if (originalSecret === undefined) {
    delete process.env.BOT_TICKET_SECRET
  } else {
    process.env.BOT_TICKET_SECRET = originalSecret
  }
})

describe('createBotBattleTicketId', () => {
  it('requires BOT_TICKET_SECRET', () => {
    delete process.env.BOT_TICKET_SECRET

    expect(() => createBotBattleTicketId('char-1', 'bot-1', 123)).toThrow(BOT_TICKET_SECRET_MISSING)
  })

  it('creates stable signed bot ticket ids', () => {
    process.env.BOT_TICKET_SECRET = 'test-secret'

    const ticketId = createBotBattleTicketId('char-1', 'bot-1', 123)

    expect(ticketId).toMatch(/^bot_[a-f0-9]{32}$/)
    expect(createBotBattleTicketId('char-1', 'bot-1', 123)).toBe(ticketId)
    expect(createBotBattleTicketId('char-1', 'bot-1', 124)).not.toBe(ticketId)
  })
})
