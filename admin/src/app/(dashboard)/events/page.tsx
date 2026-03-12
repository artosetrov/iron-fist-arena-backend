import { getEvents } from '@/actions/events'
import { EventsClient } from './events-client'

export default async function EventsPage() {
  const events = await getEvents()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">LiveOps Events</h1>
        <p className="text-muted-foreground">
          Manage in-game events and promotions. {events.length} events total.
        </p>
      </div>
      <EventsClient events={JSON.parse(JSON.stringify(events))} />
    </div>
  )
}
