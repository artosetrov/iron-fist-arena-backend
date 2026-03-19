import { prisma } from '@/lib/prisma'

/**
 * Checks whether the given user ID belongs to a guest (anonymous) account.
 * Returns true if the user is a guest, false otherwise.
 */
export async function isGuestUser(userId: string): Promise<boolean> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { authProvider: true, email: true },
  })

  if (!user) return false

  // A user is a guest if authProvider is 'anonymous' or email matches guest pattern
  return user.authProvider === 'anonymous' ||
    (user.email?.endsWith('@guest.ironfist.local') ?? false)
}
