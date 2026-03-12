import { prisma } from '@/lib/prisma'
import { SkillsClient } from './skills-client'

async function getSkills() {
  return prisma.skill.findMany({
    orderBy: [{ classRestriction: 'asc' }, { sortOrder: 'asc' }, { name: 'asc' }],
  })
}

export default async function SkillsPage() {
  const skills = await getSkills()
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Skills</h1>
        <p className="text-muted-foreground">
          Manage active combat skills. {skills.length} skills total.
        </p>
      </div>
      <SkillsClient skills={JSON.parse(JSON.stringify(skills))} />
    </div>
  )
}
