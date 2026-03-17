import { getAuthUser } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { rateLimit } from '@/lib/rate-limit';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const user = await getAuthUser();
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Rate limit
    const rateLimitKey = `mail:read:${user.id}`;
    const isAllowed = await rateLimit(rateLimitKey, 30, 60); // 30 requests per minute
    if (!isAllowed) {
      return NextResponse.json(
        { error: 'Rate limit exceeded' },
        { status: 429 }
      );
    }

    const { id } = await params;
    const body = await request.json();
    const { character_id } = body;

    if (!character_id) {
      return NextResponse.json(
        { error: 'character_id is required' },
        { status: 400 }
      );
    }

    // Verify character belongs to user
    const character = await prisma.character.findUnique({
      where: { id: character_id },
    });

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    // Verify mail recipient exists and belongs to character
    const mailRecipient = await prisma.mailRecipient.findUnique({
      where: { id },
    });

    if (!mailRecipient) {
      return NextResponse.json({ error: 'Mail not found' }, { status: 404 });
    }

    if (mailRecipient.characterId !== character_id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    // Update to mark as read
    await prisma.mailRecipient.update({
      where: { id },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Mail read error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
