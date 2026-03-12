import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { CharacterGender } from '@prisma/client'

const VALID_AVATARS: Record<CharacterGender, string[]> = {
  male: ['warlord', 'knight', 'barbarian', 'shadow'],
  female: ['valkyrie', 'sorceress', 'enchantress', 'huntress'],
}

export async function POST() {
  // Find all characters with empty or mismatched avatar
  const characters = await prisma.character.findMany({
    where: {
      OR: [
        { avatar: '' },
        { avatar: 'warlord', gender: 'female' }, // Fix mismatched gender/avatar
      ],
    },
    select: { id: true, gender: true, characterName: true, avatar: true },
  })

  let updated = 0

  for (const char of characters) {
    const gender = char.gender ?? 'male'
    const avatars = VALID_AVATARS[gender]

    // Pick a random avatar from the valid set for variety
    const avatar = avatars[Math.floor(Math.random() * avatars.length)]

    // Skip if already has a valid avatar for their gender
    if (char.avatar && avatars.includes(char.avatar)) continue

    await prisma.character.update({
      where: { id: char.id },
      data: { avatar },
    })
    updated++
  }

  return NextResponse.json({
    message: `Fixed ${updated} characters with missing/invalid avatars`,
    totalChecked: characters.length,
    updated,
  })
}
