'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import {
  Mail,
  Users,
  Eye,
  Gift,
  Plus,
  Trash2,
  Eye as EyeIcon,
  ChevronLeft,
  ChevronRight,
  Loader2,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { sendMail, deleteMailMessage } from '@/actions/mail'
import { useToast } from '@/hooks/use-toast'

interface MailMessage {
  id: string
  subject: string
  body: string
  senderName: string
  targetType: 'broadcast' | 'character' | 'segment'
  characterId?: string
  minLevel?: number
  maxLevel?: number
  class?: string
  attachments?: Array<{
    type: 'gold' | 'gems' | 'xp'
    amount: number
  }>
  expiresAt?: Date
  sentAt: Date
  totalRecipients: number
  readCount: number
  claimedCount: number
}

interface MailStats {
  totalMessages: number
  totalRecipients: number
  readRate: number
  claimedRate: number
}

interface MailClientProps {
  initialMessages: MailMessage[]
  stats: MailStats
}

type TargetType = 'broadcast' | 'character' | 'segment'
type AttachmentType = 'gold' | 'gems' | 'xp'

export function MailClient({ initialMessages, stats }: MailClientProps) {
  const router = useRouter()
  const { toast } = useToast()
  const [isPending, startTransition] = useTransition()

  const [messages, setMessages] = useState(initialMessages)
  const [isComposeOpen, setIsComposeOpen] = useState(false)
  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [currentPage, setCurrentPage] = useState(1)
  const itemsPerPage = 10

  // Compose form state
  const [subject, setSubject] = useState('')
  const [body, setBody] = useState('')
  const [senderName, setSenderName] = useState('Game Master')
  const [targetType, setTargetType] = useState<TargetType>('broadcast')
  const [characterId, setCharacterId] = useState('')
  const [minLevel, setMinLevel] = useState('')
  const [maxLevel, setMaxLevel] = useState('')
  const [characterClass, setCharacterClass] = useState('')
  const [attachments, setAttachments] = useState<
    Array<{ type: AttachmentType; amount: number }>
  >([])
  const [expiresAt, setExpiresAt] = useState('')
  const [isSending, setIsSending] = useState(false)

  const paginatedMessages = messages.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  )
  const totalPages = Math.ceil(messages.length / itemsPerPage)

  const handleAddAttachment = () => {
    setAttachments([...attachments, { type: 'gold', amount: 0 }])
  }

  const handleRemoveAttachment = (index: number) => {
    setAttachments(attachments.filter((_, i) => i !== index))
  }

  const handleUpdateAttachment = (
    index: number,
    field: 'type' | 'amount',
    value: AttachmentType | number
  ) => {
    const updated = [...attachments]
    if (field === 'type') {
      updated[index].type = value as AttachmentType
    } else {
      updated[index].amount = value as number
    }
    setAttachments(updated)
  }

  const resetForm = () => {
    setSubject('')
    setBody('')
    setSenderName('Game Master')
    setTargetType('broadcast')
    setCharacterId('')
    setMinLevel('')
    setMaxLevel('')
    setCharacterClass('')
    setAttachments([])
    setExpiresAt('')
  }

  const handleSendMail = async () => {
    if (!subject.trim() || !body.trim()) {
      toast({
        title: 'Error',
        description: 'Subject and body are required',
        variant: 'destructive',
      })
      return
    }

    if (targetType === 'character' && !characterId.trim()) {
      toast({
        title: 'Error',
        description: 'Character ID is required for single character mails',
        variant: 'destructive',
      })
      return
    }

    setIsSending(true)
    try {
      startTransition(async () => {
        await sendMail({
          subject,
          body,
          senderName,
          targetType,
          targetCharacterId: targetType === 'character' ? characterId : undefined,
          targetFilter: targetType === 'segment' ? {
            minLevel: minLevel ? Number(minLevel) : undefined,
            maxLevel: maxLevel ? Number(maxLevel) : undefined,
            class: characterClass || undefined,
          } : undefined,
          attachments: attachments.length > 0 ? attachments : undefined,
          expiresAt: expiresAt ? new Date(expiresAt) : undefined,
        })
        
        toast({
          title: 'Success',
          description: 'Mail sent successfully',
        })
        
        resetForm()
        setIsComposeOpen(false)
        router.refresh()
      })
    } catch (error) {
      toast({
        title: 'Error',
        description:
          error instanceof Error ? error.message : 'Failed to send mail',
        variant: 'destructive',
      })
    } finally {
      setIsSending(false)
    }
  }

  const handleDeleteMail = async () => {
    if (!deleteId) return

    startTransition(async () => {
      try {
        await deleteMailMessage(deleteId)
        setMessages(messages.filter((m) => m.id !== deleteId))
        setDeleteId(null)
        toast({
          title: 'Success',
          description: 'Mail deleted successfully',
        })
        router.refresh()
      } catch (error) {
        toast({
          title: 'Error',
          description:
            error instanceof Error ? error.message : 'Failed to delete mail',
          variant: 'destructive',
        })
      }
    })
  }

  const readRate = stats.totalRecipients > 0 ? Math.round((stats.readRate / stats.totalRecipients) * 100) : 0
  const claimedRate = stats.totalRecipients > 0 ? Math.round((stats.claimedRate / stats.totalRecipients) * 100) : 0

  return (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="border-border">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Messages</CardTitle>
            <Mail className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalMessages}</div>
            <p className="text-xs text-muted-foreground">All sent messages</p>
          </CardContent>
        </Card>

        <Card className="border-border">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Recipients</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalRecipients}</div>
            <p className="text-xs text-muted-foreground">Unique players</p>
          </CardContent>
        </Card>

        <Card className="border-border">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Read Rate</CardTitle>
            <EyeIcon className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{readRate}%</div>
            <p className="text-xs text-muted-foreground">{stats.readRate} of {stats.totalRecipients}</p>
          </CardContent>
        </Card>

        <Card className="border-border">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Claimed Rate</CardTitle>
            <Gift className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{claimedRate}%</div>
            <p className="text-xs text-muted-foreground">{stats.claimedRate} of {stats.totalRecipients}</p>
          </CardContent>
        </Card>
      </div>

      {/* Compose Mail Dialog */}
      <div className="flex justify-end">
        <Dialog open={isComposeOpen} onOpenChange={setIsComposeOpen}>
          <DialogTrigger asChild>
            <Button className="gap-2">
              <Plus className="h-4 w-4" />
              Compose Mail
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>Compose New Mail</DialogTitle>
              <DialogDescription>
                Send a message and rewards to players.
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-4 py-4">
              {/* Subject */}
              <div className="space-y-2">
                <label className="text-sm font-medium">Subject</label>
                <Input
                  placeholder="Mail subject"
                  value={subject}
                  onChange={(e) => setSubject(e.target.value)}
                  disabled={isSending}
                />
              </div>

              {/* Body */}
              <div className="space-y-2">
                <label className="text-sm font-medium">Body</label>
                <Textarea
                  placeholder="Mail message content"
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  rows={4}
                  disabled={isSending}
                />
              </div>

              {/* Sender Name */}
              <div className="space-y-2">
                <label className="text-sm font-medium">Sender Name</label>
                <Input
                  placeholder="Game Master"
                  value={senderName}
                  onChange={(e) => setSenderName(e.target.value)}
                  disabled={isSending}
                />
              </div>

              {/* Target Type */}
              <div className="space-y-2">
                <label className="text-sm font-medium">Target Type</label>
                <Select
                  value={targetType}
                  onValueChange={(value) => setTargetType(value as TargetType)}
                  disabled={isSending}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="broadcast">Broadcast (All Players)</SelectItem>
                    <SelectItem value="character">Single Character</SelectItem>
                    <SelectItem value="segment">Segment (Level/Class)</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Character ID */}
              {targetType === 'character' && (
                <div className="space-y-2">
                  <label className="text-sm font-medium">Character ID</label>
                  <Input
                    placeholder="Enter character ID"
                    value={characterId}
                    onChange={(e) => setCharacterId(e.target.value)}
                    disabled={isSending}
                  />
                </div>
              )}

              {/* Segment Filters */}
              {targetType === 'segment' && (
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Min Level</label>
                    <Input
                      type="number"
                      placeholder="1"
                      value={minLevel}
                      onChange={(e) => setMinLevel(e.target.value)}
                      disabled={isSending}
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Max Level</label>
                    <Input
                      type="number"
                      placeholder="100"
                      value={maxLevel}
                      onChange={(e) => setMaxLevel(e.target.value)}
                      disabled={isSending}
                    />
                  </div>
                  <div className="col-span-2 space-y-2">
                    <label className="text-sm font-medium">Class (optional)</label>
                    <Input
                      placeholder="e.g., Warrior, Mage, Rogue"
                      value={characterClass}
                      onChange={(e) => setCharacterClass(e.target.value)}
                      disabled={isSending}
                    />
                  </div>
                </div>
              )}

              {/* Attachments */}
              <div className="space-y-2">
                <label className="text-sm font-medium">Attachments</label>
                <div className="space-y-2">
                  {attachments.map((attachment, index) => (
                    <div key={index} className="flex gap-2">
                      <Select
                        value={attachment.type}
                        onValueChange={(value) =>
                          handleUpdateAttachment(index, 'type', value as AttachmentType)
                        }
                        disabled={isSending}
                      >
                        <SelectTrigger className="w-24">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="gold">Gold</SelectItem>
                          <SelectItem value="gems">Gems</SelectItem>
                          <SelectItem value="xp">XP</SelectItem>
                        </SelectContent>
                      </Select>
                      <Input
                        type="number"
                        placeholder="Amount"
                        value={attachment.amount}
                        onChange={(e) =>
                          handleUpdateAttachment(index, 'amount', parseInt(e.target.value) || 0)
                        }
                        disabled={isSending}
                        className="flex-1"
                      />
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleRemoveAttachment(index)}
                        disabled={isSending}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  ))}
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleAddAttachment}
                  className="gap-2"
                  disabled={isSending}
                >
                  <Plus className="h-4 w-4" />
                  Add Attachment
                </Button>
              </div>

              {/* Expires At */}
              <div className="space-y-2">
                <label className="text-sm font-medium">Expires At (optional)</label>
                <Input
                  type="datetime-local"
                  value={expiresAt}
                  onChange={(e) => setExpiresAt(e.target.value)}
                  disabled={isSending}
                />
              </div>
            </div>

            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => setIsComposeOpen(false)}
                disabled={isSending}
              >
                Cancel
              </Button>
              <Button
                onClick={handleSendMail}
                disabled={isSending || isPending}
                className="gap-2"
              >
                {isSending || isPending ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Sending...
                  </>
                ) : (
                  'Send Mail'
                )}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      {/* Mail History Table */}
      <Card className="border-border">
        <CardHeader>
          <CardTitle>Mail History</CardTitle>
        </CardHeader>
        <CardContent>
          {messages.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              No messages sent yet. Create your first mail!
            </div>
          ) : (
            <>
              <div className="border border-border rounded-lg overflow-hidden">
                <Table>
                  <TableHeader>
                    <TableRow className="border-border hover:bg-transparent">
                      <TableHead className="bg-muted/50">Subject</TableHead>
                      <TableHead className="bg-muted/50">Target</TableHead>
                      <TableHead className="bg-muted/50 text-right">Recipients</TableHead>
                      <TableHead className="bg-muted/50 text-center">Read / Claimed</TableHead>
                      <TableHead className="bg-muted/50">Sent At</TableHead>
                      <TableHead className="bg-muted/50 text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {paginatedMessages.map((message) => (
                      <TableRow key={message.id} className="border-border">
                        <TableCell className="font-medium">
                          {message.subject}
                        </TableCell>
                        <TableCell>
                          {message.targetType === 'broadcast' && (
                            <Badge variant="outline" className="bg-blue-500/10 text-blue-700 border-blue-500/50">
                              Broadcast
                            </Badge>
                          )}
                          {message.targetType === 'character' && (
                            <Badge variant="outline" className="bg-green-500/10 text-green-700 border-green-500/50">
                              {message.characterId}
                            </Badge>
                          )}
                          {message.targetType === 'segment' && (
                            <Badge variant="outline" className="bg-purple-500/10 text-purple-700 border-purple-500/50">
                              Segment
                            </Badge>
                          )}
                        </TableCell>
                        <TableCell className="text-right">
                          {message.totalRecipients}
                        </TableCell>
                        <TableCell className="text-center text-sm">
                          <div className="text-muted-foreground">
                            {message.readCount}/{message.totalRecipients} read · {message.claimedCount}/{message.totalRecipients} claimed
                          </div>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {new Date(message.sentAt).toLocaleDateString()} {new Date(message.sentAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </TableCell>
                        <TableCell className="text-right">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setDeleteId(message.id)}
                            disabled={isPending}
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>

              {/* Pagination */}
              {totalPages > 1 && (
                <div className="flex items-center justify-between mt-4">
                  <p className="text-sm text-muted-foreground">
                    Page {currentPage} of {totalPages} ({messages.length} total)
                  </p>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                      disabled={currentPage === 1}
                    >
                      <ChevronLeft className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                      disabled={currentPage === totalPages}
                    >
                      <ChevronRight className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* Delete Confirmation Dialog */}
      <Dialog open={!!deleteId} onOpenChange={(open) => !open && setDeleteId(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Delete Mail Message</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete this mail message? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteId(null)} disabled={isPending}>Cancel</Button>
            <Button
              variant="destructive"
              onClick={handleDeleteMail}
              disabled={isPending}
            >
              {isPending ? 'Deleting...' : 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
