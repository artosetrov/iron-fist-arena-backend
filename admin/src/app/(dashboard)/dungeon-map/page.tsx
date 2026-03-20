import { Metadata } from 'next'
import DungeonMapEditorClient from './dungeon-map-client'

export const metadata: Metadata = {
  title: 'Dungeon Map Editor | Hexbound Admin',
}

export default function DungeonMapPage() {
  return <DungeonMapEditorClient />
}
