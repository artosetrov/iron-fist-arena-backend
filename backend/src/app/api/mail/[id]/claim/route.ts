import { getAuthUser } from '@/lib/auth';
import { invalidatePassiveCache, invalidateSkillCache } from '@/lib/game/combat-loader';
import { grantRewardEntries } from '@/lib/game/reward-grants';
import { prisma } from '@/lib/prisma';
import { rateLimit } from '@/lib/rate-limit';
import { NextRequest, NextResponse } from 'next/server';

type Attachment = {
  type: 'gold' | 'gems' | 'xp' | 'item' | 'consumable';
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
    const isAllowed = await rateLimit(rateLimitKey, 10, 60_000); // 10 requests per minute
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

    // All checks and claims inside a single transaction with row-level lock
    // to prevent double-claim race condition
    const claimedAttachments = await prisma.$transaction(async (tx) => {
      // Lock the mail recipient row to prevent concurrent double-claims
      const [mailRow] = await tx.$queryRawUnsafe<Array<{
        id: string;
        is_claimed: boolean;
        character_id: string;
        message_id: string;
      }>>(
        `SELECT mr.id, mr.is_claimed, mr.character_id, mr.message_id
         FROM mail_recipients mr
         WHERE mr.id = $1
         FOR UPDATE`,
        id
      );

      if (!mailRow) throw new Error('MAIL_NOT_FOUND');
      if (mailRow.character_id !== character_id) throw new Error('FORBIDDEN');
      if (mailRow.is_claimed) throw new Error('ALREADY_CLAIMED');

      // Fetch message attachments
      const message = await tx.mailMessage.findUnique({
        where: { id: mailRow.message_id },
        select: { attachments: true },
      });

      const attachments: Attachment[] = Array.isArray(message?.attachments)
        ? (message?.attachments as Attachment[])
        : [];
      if (!attachments || attachments.length === 0) throw new Error('NO_ATTACHMENTS');

      const rewardResult = await grantRewardEntries(tx, {
        userId: user.id,
        characterId: character_id,
        rewards: attachments.map((attachment) => ({
          type: attachment.type,
          id: attachment.itemId ?? null,
          quantity: attachment.amount ?? 0,
        })),
      });

      // Mark mail as claimed and read (atomically after lock)
      await tx.mailRecipient.update({
        where: { id },
        data: {
          isClaimed: true,
          claimedAt: new Date(),
          isRead: true,
          readAt: new Date(),
        },
      });

      return { attachments, rewardResult };
    });

    if (claimedAttachments.rewardResult.levelUpResult?.leveledUp) {
      await invalidateSkillCache(character_id);
      await invalidatePassiveCache(character_id);
    }

    return NextResponse.json({
      success: true,
      claimed: claimedAttachments.attachments,
      gold: claimedAttachments.rewardResult.gold,
      gems: claimedAttachments.rewardResult.gems,
      xp: claimedAttachments.rewardResult.xp,
      leveled_up: claimedAttachments.rewardResult.levelUpResult?.leveledUp ?? false,
      new_level: claimedAttachments.rewardResult.levelUpResult?.newLevel,
      stat_points_awarded: claimedAttachments.rewardResult.levelUpResult?.statPointsAwarded,
    });
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'MAIL_NOT_FOUND') return NextResponse.json({ error: 'Mail not found' }, { status: 404 });
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
      if (error.message === 'ALREADY_CLAIMED') return NextResponse.json({ error: 'Mail already claimed' }, { status: 400 });
      if (error.message === 'NO_ATTACHMENTS') return NextResponse.json({ error: 'No attachments to claim' }, { status: 400 });
      if (error.message === 'INVENTORY_FULL') return NextResponse.json({ error: 'Inventory is full' }, { status: 400 });
    }
    console.error('Mail claim error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
