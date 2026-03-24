// DEPRECATED — This file is not imported anywhere. Safe to delete.
// Ownership checks are done inline in each API route.

import { prisma } from './prisma'

/** @deprecated Not used — ownership checks are done inline in API routes */
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
