import { getAuthUser } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { rateLimit } from '@/lib/rate-limit';
import { NextRequest, NextResponse } from 'next/server';

type Attachment = {
  type: 'gold' | 'gems' | 'xp' | 'item';
  amount?: number;
  itemId?: string;
};

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const user = await getAuthUser(request);
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Rate limit
    const rateLimitKey = `mail:claim:${user.id}`;
    const isAllowed = await rateLimit(rateLimitKey, 10, 60); // 10 requests per minute
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
      include: { user: { select: { id: true, gems: true } } },
    });

    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    // Verify mail recipient exists and belongs to character
    const mailRecipient = await prisma.mailRecipient.findUnique({
      where: { id },
      include: { message: true },
    });

    if (!mailRecipient) {
      return NextResponse.json({ error: 'Mail not found' }, { status: 404 });
    }

    if (mailRecipient.characterId !== character_id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    if (mailRecipient.isClaimed) {
      return NextResponse.json(
        { error: 'Mail already claimed' },
        { status: 400 }
      );
    }

    const attachments: Attachment[] = (mailRecipient.message.attachments as Attachment[]) || [];

    if (!attachments || attachments.length === 0) {
      return NextResponse.json(
        { error: 'No attachments to claim' },
        { status: 400 }
      );
    }

    // Use transaction to atomically process claim
    const result = await prisma.$transaction(async (tx) => {
      // Calculate totals for each attachment type
      let goldToAdd = 0;
      let gemsToAdd = 0;
      let xpToAdd = 0;

      for (const attachment of attachments) {
        if (attachment.type === 'gold') {
          goldToAdd += attachment.amount || 0;
        } else if (attachment.type === 'gems') {
          gemsToAdd += attachment.amount || 0;
        } else if (attachment.type === 'xp') {
          xpToAdd += attachment.amount || 0;
        }
      }

      // Update character gold and xp
      if (goldToAdd > 0 || xpToAdd > 0) {
        await tx.character.update({
          where: { id: character_id },
          data: {
            gold: { increment: goldToAdd },
            currentXp: { increment: xpToAdd },
          },
        });
      }

      // Update user gems
      if (gemsToAdd > 0) {
        await tx.user.update({
          where: { id: user.id },
          data: { gems: { increment: gemsToAdd } },
        });
      }

      // Mark mail as claimed and read
      const updated = await tx.mailRecipient.update({
        where: { id },
        data: {
          isClaimed: true,
          claimedAt: new Date(),
          isRead: true,
          readAt: new Date(),
        },
      });

      return updated;
    });

    return NextResponse.json({ success: true, claimed: attachments });
  } catch (error) {
    console.error('Mail claim error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
