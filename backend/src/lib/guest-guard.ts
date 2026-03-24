// DEPRECATED — This file is not imported anywhere. Safe to delete.
// Kept for reference in case guest account feature is re-implemented.

import { prisma } from '@/lib/prisma'

/** @deprecated Not used — ownership checks are done inline in API routes */
export async function isGuestUser(userId: string): Promise<boolean> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { authProvider: true, email: true },
  })

  if (!user) return false

  return user.authProvider === 'anonymous' ||
    (user.email?.endsWith('@guest.ironfist.local') ?? false)
}
