import { getAuthUser } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { rateLimit } from '@/lib/rate-limit';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    const user = await getAuthUser(request);
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Rate limit
    const rateLimitKey = `mail:unread:${user.id}`;
    const isAllowed = await rateLimit(rateLimitKey, 60, 60); // 60 requests per minute
    if (!isAllowed) {
      return NextResponse.json(
        { error: 'Rate limit exceeded' },
        { status: 429 }
      );
    }

    const searchParams = request.nextUrl.searchParams;
    const characterId = searchParams.get('character_id');

    if (!characterId) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      );
    }

    // Verify character belongs to user
    const character = await prisma.character.findUnique({
      where: { id: characterId },
    });

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const now = new Date();

    // Count unread, non-deleted, non-expired messages
    const unreadCount = await prisma.mailRecipient.count({
      where: {
        characterId,
        isDeleted: false,
        isRead: false,
        message: {
          OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
        },
      },
    });

    return NextResponse.json({ unread_count: unreadCount });
  } catch (error) {
    console.error('Unread count error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
