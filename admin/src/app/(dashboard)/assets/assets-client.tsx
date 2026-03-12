'use client'

import { useState, useTransition, useCallback, useRef } from 'react'
import { listAssets, uploadAsset, deleteAsset, getAssetUrl } from '@/actions/assets'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent } from '@/components/ui/card'
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription,
} from '@/components/ui/dialog'
import {
  Upload, Trash2, Copy, Check, ImageIcon, FolderOpen, RefreshCw,
} from 'lucide-react'

type AssetFile = {
  name: string
  id: string | null
  metadata: Record<string, unknown> | null
  created_at: string | null
}

export function AssetsClient() {
  const [isPending, startTransition] = useTransition()
  const [bucket, setBucket] = useState('assets')
  const [path, setPath] = useState('')
  const [files, setFiles] = useState<AssetFile[]>([])
  const [loaded, setLoaded] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [urlDialogOpen, setUrlDialogOpen] = useState(false)
  const [selectedUrl, setSelectedUrl] = useState('')
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [deletingFile, setDeletingFile] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)
  const [refreshKey, setRefreshKey] = useState(Date.now())
  const fileInputRef = useRef<HTMLInputElement>(null)

  const loadFiles = useCallback(() => {
    setError('')
    startTransition(async () => {
      try {
        const data = await listAssets(bucket, path || undefined)
        setFiles(data.filter((f) => f.name !== '.emptyFolderPlaceholder') as AssetFile[])
        setLoaded(true)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load assets')
      }
    })
  }, [bucket, path, startTransition])

  function handleLoad() {
    loadFiles()
  }

  async function handleUpload(fileList: FileList | null) {
    if (!fileList || fileList.length === 0) return
    setError('')
    setMessage('')

    startTransition(async () => {
      try {
        for (const file of Array.from(fileList)) {
          const uploadPath = path ? `${path}/${file.name}` : file.name
          const formData = new FormData()
          formData.append('file', file)
          await uploadAsset(bucket, uploadPath, formData)
        }
        setMessage(`Uploaded ${fileList.length} file(s) successfully.`)
        setRefreshKey(Date.now())
        loadFiles()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Upload failed')
      }
    })
  }

  async function handleViewUrl(fileName: string) {
    const filePath = path ? `${path}/${fileName}` : fileName
    startTransition(async () => {
      try {
        const url = await getAssetUrl(bucket, filePath)
        setSelectedUrl(url)
        setUrlDialogOpen(true)
        setCopied(false)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to get URL')
      }
    })
  }

  async function handleCopy() {
    await navigator.clipboard.writeText(selectedUrl)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  function confirmDelete(fileName: string) {
    setDeletingFile(fileName)
    setDeleteDialogOpen(true)
  }

  async function handleDelete() {
    if (!deletingFile) return
    const filePath = path ? `${path}/${deletingFile}` : deletingFile
    startTransition(async () => {
      try {
        await deleteAsset(bucket, filePath)
        setMessage(`Deleted ${deletingFile}`)
        setDeleteDialogOpen(false)
        setDeletingFile(null)
        loadFiles()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to delete')
      }
    })
  }

  function getImagePreviewUrl(fileName: string) {
    const filePath = path ? `${path}/${fileName}` : fileName
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    if (!supabaseUrl) return null
    return `${supabaseUrl}/storage/v1/object/public/${bucket}/${filePath}?v=${refreshKey}`
  }

  function isImageFile(name: string) {
    return /\.(png|jpg|jpeg|gif|svg|webp|ico)$/i.test(name)
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault()
    handleUpload(e.dataTransfer.files)
  }

  return (
    <>
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}
      {message && (
        <div className="rounded-md bg-green-600/10 border border-green-600/30 px-4 py-3 text-sm text-green-400">
          {message}
        </div>
      )}

      {/* Bucket & Path Selector */}
      <div className="flex flex-wrap items-end gap-3">
        <div className="space-y-2">
          <Label>Bucket</Label>
          <Input
            value={bucket}
            onChange={(e) => setBucket(e.target.value)}
            placeholder="assets"
            className="w-48"
          />
        </div>
        <div className="space-y-2 flex-1 max-w-md">
          <Label>Path (optional)</Label>
          <Input
            value={path}
            onChange={(e) => setPath(e.target.value)}
            placeholder="e.g. items/weapons"
          />
        </div>
        <Button onClick={handleLoad} disabled={isPending}>
          <FolderOpen className="mr-2 h-4 w-4" />
          {isPending ? 'Loading...' : 'Browse'}
        </Button>
      </div>

      {/* Upload Area */}
      <div
        className="border-2 border-dashed border-border rounded-lg p-8 text-center cursor-pointer hover:border-primary/50 transition-colors"
        onDrop={handleDrop}
        onDragOver={(e) => e.preventDefault()}
        onClick={() => fileInputRef.current?.click()}
      >
        <Upload className="mx-auto h-8 w-8 text-muted-foreground mb-2" />
        <p className="text-sm text-muted-foreground">
          Drag & drop files here, or click to browse
        </p>
        <p className="text-xs text-muted-foreground mt-1">
          Uploads to: {bucket}/{path || '(root)'}
        </p>
        <input
          ref={fileInputRef}
          type="file"
          multiple
          className="hidden"
          onChange={(e) => handleUpload(e.target.files)}
        />
      </div>

      {/* Files Grid */}
      {loaded && (
        <>
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">
              {files.length} file(s) in {bucket}/{path || '(root)'}
            </p>
            <Button variant="outline" size="sm" onClick={loadFiles} disabled={isPending}>
              <RefreshCw className="mr-2 h-3 w-3" />
              Refresh
            </Button>
          </div>

          {files.length === 0 ? (
            <div className="rounded-lg border border-border p-8 text-center text-muted-foreground">
              <ImageIcon className="mx-auto h-12 w-12 mb-4 opacity-50" />
              <p>No files in this location.</p>
            </div>
          ) : (
            <div className="grid gap-4 grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
              {files.map((file) => (
                <Card
                  key={file.name}
                  className="overflow-hidden cursor-pointer hover:border-primary/50 transition-colors"
                  onClick={() => handleViewUrl(file.name)}
                >
                  <div className="aspect-square bg-muted flex items-center justify-center overflow-hidden">
                    {isImageFile(file.name) ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={getImagePreviewUrl(file.name) || ''}
                        alt={file.name}
                        className="w-full h-full object-cover"
                        loading="lazy"
                      />
                    ) : (
                      <ImageIcon className="h-12 w-12 text-muted-foreground opacity-50" />
                    )}
                  </div>
                  <CardContent className="p-2">
                    <p className="text-xs font-medium truncate">{file.name}</p>
                    <div className="flex justify-end mt-1">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={(e) => {
                          e.stopPropagation()
                          confirmDelete(file.name)
                        }}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </>
      )}

      {/* URL Dialog */}
      <Dialog open={urlDialogOpen} onOpenChange={setUrlDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Asset URL</DialogTitle>
            <DialogDescription>Public URL for this asset.</DialogDescription>
          </DialogHeader>
          <div className="flex items-center gap-2">
            <Input value={selectedUrl} readOnly className="font-mono text-xs" />
            <Button size="icon" variant="outline" onClick={handleCopy}>
              {copied ? <Check className="h-4 w-4 text-green-400" /> : <Copy className="h-4 w-4" />}
            </Button>
          </div>
          {isImageFile(selectedUrl) && selectedUrl && (
            <div className="mt-2 rounded-lg overflow-hidden border border-border">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={selectedUrl} alt="Preview" className="w-full max-h-64 object-contain" />
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Asset</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &quot;{deletingFile}&quot;? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
            <Button variant="destructive" onClick={handleDelete} disabled={isPending}>
              {isPending ? 'Deleting...' : 'Delete'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}
