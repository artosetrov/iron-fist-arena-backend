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

  it('returns scheduled variety rooms before any DB boss lookup', async () => {
    const randomSpy = vi.spyOn(Math, 'random').mockReturnValue(0)

    const floor = await generateDungeonFloorFromDB(3, 'normal', 'training_camp')

    expect(floor).toEqual({
      enemies: [],
      isBoss: false,
      room: {
        type: 'treasure',
        floor: 2,
        goldReward: 250,
        itemChance: 0.5,
      },
    })
    expect(prismaMock.dungeon.findFirst).not.toHaveBeenCalled()
    expect(prismaMock.dungeonBoss.findFirst).not.toHaveBeenCalled()

    randomSpy.mockRestore()
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
          maxHp: 700,
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
