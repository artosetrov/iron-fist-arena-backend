import { prisma } from './prisma'

/**
 * Verify that a character belongs to the given user.
 * Uses select to fetch only the userId field — minimal data transfer.
 */
export async function verifyCharacterOwnership(
  characterId: string,
  userId: string
): Promise<boolean> {
  const char = await prisma.character.findUnique({
    where: { id: characterId },
    select: { userId: true },
  })
  return char?.userId === userId
}
