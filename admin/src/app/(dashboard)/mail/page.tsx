import { listMailMessages, getMailStats } from '@/actions/mail'
import { MailClient } from './mail-client'

export default async function MailPage() {
  const [messagesData, stats] = await Promise.all([
    listMailMessages(),
    getMailStats(),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Mail &amp; Inbox</h1>
        <p className="text-muted-foreground">Send messages and rewards to players.</p>
      </div>
      <MailClient initialMessages={messagesData} stats={stats} />
    </div>
  )
}
