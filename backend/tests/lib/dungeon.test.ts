import { beforeEach, describe, expect, it, vi } from 'vitest'

const prismaMock = vi.hoisted(() => ({
  dungeon: {
    findFirst: vi.fn(),
  },
  dungeonBoss: {
    findFirst: vi.fn(),
  },
}))

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

import { generateDungeonFloorFromDB } from '../../src/lib/game/dungeon'

describe('dungeon.ts', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('floor 3 is a boss floor — variety rooms are off until the client has a room screen', async () => {
    prismaMock.dungeon.findFirst.mockResolvedValue({ id: 'dng-tc' })
    prismaMock.dungeonBoss.findFirst.mockResolvedValue({
      name: 'Cave Spider', level: 3, hp: 222, damage: 12, speed: 10, defense: 8,
    })

    const floor = await generateDungeonFloorFromDB(3, 'normal', 'training_camp')

    expect(floor.isBoss).toBe(true)
    expect(floor.room).toBeUndefined()
    expect(floor.enemies).toHaveLength(1)
    expect(floor.enemies[0].name).toBe('Cave Spider')
  })

  it('uses DB boss data on regular combat floors', async () => {
    prismaMock.dungeon.findFirst.mockResolvedValue({ id: 'dng-1' })
    prismaMock.dungeonBoss.findFirst.mockResolvedValue({
      name: 'Forge Warden',
      level: 12,
      hp: 500,
      damage: 20,
      speed: 8,
      defense: 10,
    })

    const floor = await generateDungeonFloorFromDB(2, 'hard', 'volcanic_forge')

    expect(prismaMock.dungeon.findFirst).toHaveBeenCalledWith({
      where: { slug: 'volcanic_forge', isActive: true },
      select: { id: true },
    })
    expect(prismaMock.dungeonBoss.findFirst).toHaveBeenCalledWith({
      where: { dungeonId: 'dng-1', floorNumber: 2 },
    })
    expect(floor).toMatchObject({
      isBoss: true,
      enemies: [
        {
          name: 'Forge Warden',
          level: 17,
          maxHp: 600, // hard: HP ×1.2, stats ×1.4 (2026-10-16 audit)
          str: 28,
          agi: 11,
          armor: 14,
          magicResist: 10,
          isBoss: true,
        },
      ],
    })
    expect(floor.room).toBeUndefined()
  })
})
