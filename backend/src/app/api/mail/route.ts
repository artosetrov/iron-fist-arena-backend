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
    const rateLimitKey = `mail:list:${user.id}`;
    const isAllowed = await rateLimit(rateLimitKey, 30, 60); // 30 requests per minute
    if (!isAllowed) {
      return NextResponse.json(
        { error: 'Rate limit exceeded' },
        { status: 429 }
      );
    }

    const searchParams = request.nextUrl.searchParams;
    const characterId = searchParams.get('character_id');
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

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
    const skip = (page - 1) * limit;

    // Get total count
    const total = await prisma.mailRecipient.count({
      where: {
        characterId,
        isDeleted: false,
        message: {
          OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
        },
      },
    });

    // Get messages
    const mailRecipients = await prisma.mailRecipient.findMany({
      where: {
        characterId,
        isDeleted: false,
        message: {
          OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
        },
      },
      include: {
        message: {
          select: {
            id: true,
            subject: true,
            body: true,
            senderType: true,
            senderName: true,
            attachments: true,
            expiresAt: true,
            createdAt: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    });

    const messages = mailRecipients.map((recipient: any) => ({
      id: recipient.id,
      messageId: recipient.messageId,
      subject: recipient.message.subject,
      body: recipient.message.body,
      senderType: recipient.message.senderType,
      senderName: recipient.message.senderName,
      attachments: recipient.message.attachments,
      expiresAt: recipient.message.expiresAt,
      isRead: recipient.isRead,
      isClaimed: recipient.isClaimed,
      readAt: recipient.readAt,
      claimedAt: recipient.claimedAt,
      createdAt: recipient.createdAt,
    }));

    return NextResponse.json({
      messages,
      total,
      page,
      limit,
      unread_count: mailRecipients.filter((r: any) => !r.isRead).length,
    });
  } catch (error) {
    console.error('Mail list error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
