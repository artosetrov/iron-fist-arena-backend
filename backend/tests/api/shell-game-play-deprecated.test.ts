import { describe, expect, it } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

import { POST } from '@/app/api/minigames/shell-game/play/route'

describe('POST /api/minigames/shell-game/play', () => {
  it('returns 410 so callers cannot bypass the two-step locked session flow', async () => {
    const response = await POST(
      makeNextRequest('http://localhost/api/minigames/shell-game/play', {
        method: 'POST',
        body: JSON.stringify({
          character_id: 'char-1',
          bet_amount: 100,
          chosen_cup: 1,
        }),
      }),
    )

    expect(response.status).toBe(410)
    await expect(response.json()).resolves.toMatchObject({
      deprecated: true,
      redirect: '/api/minigames/shell-game/start',
    })
  })
})
