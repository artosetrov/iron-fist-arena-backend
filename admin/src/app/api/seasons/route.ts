import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { getAdminUser, canModifyConfig } from '@/lib/auth'

function forbidden() {
  return NextResponse.json({ error: 'Insufficient permissions — admin or developer role required' }, { status: 403 })
}

export async function POST(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!canModifyConfig(admin.role)) return forbidden()

  try {
    const body = await req.json()
    const season = await prisma.season.create({
      data: {
        number: body.number,
        theme: body.theme || null,
        startAt: new Date(body.startAt),
        endAt: new Date(body.endAt),
      },
    })
    return NextResponse.json(season)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to create season'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}

export async function PUT(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!canModifyConfig(admin.role)) return forbidden()

  try {
    const body = await req.json()
    const { id, ...data } = body
    const season = await prisma.season.update({
      where: { id },
      data: {
        number: data.number,
        theme: data.theme || null,
        startAt: new Date(data.startAt),
        endAt: new Date(data.endAt),
      },
    })
    return NextResponse.json(season)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to update season'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}

export async function DELETE(req: NextRequest) {
  const admin = await getAdminUser()
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!canModifyConfig(admin.role)) return forbidden()

  try {
    const { searchParams } = new URL(req.url)
    const id = searchParams.get('id')
    if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 })

    await prisma.season.delete({ where: { id } })
    return NextResponse.json({ success: true })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Failed to delete season'
    return NextResponse.json({ error: message }, { status: 400 })
  }
}
