'use client'

import { useEffect, useState, type FormEvent } from 'react'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  { auth: { flowType: 'pkce', detectSessionInUrl: true, persistSession: false } }
)

type Phase = 'verifying' | 'invalid' | 'ready' | 'done'

export default function ResetPasswordPage() {
  const [phase, setPhase] = useState<Phase>('verifying')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const url = new URL(window.location.href)
        const code = url.searchParams.get('code')
        if (code) {
          const { error: exchangeError } = await supabase.auth.exchangeCodeForSession(code)
          if (exchangeError) {
            if (!cancelled) setPhase('invalid')
            return
          }
        }
        const { data } = await supabase.auth.getSession()
        if (cancelled) return
        setPhase(data.session ? 'ready' : 'invalid')
      } catch {
        if (!cancelled) setPhase('invalid')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [])

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    if (password.length < 8) {
      setError('Password must be at least 8 characters.')
      return
    }
    if (password !== confirm) {
      setError('Passwords do not match.')
      return
    }
    setSubmitting(true)
    const { error: updateError } = await supabase.auth.updateUser({ password })
    setSubmitting(false)
    if (updateError) {
      setError(updateError.message)
      return
    }
    await supabase.auth.signOut()
    setPhase('done')
  }

  return (
    <main style={styles.page}>
      <div style={styles.card}>
        <h1 style={styles.brand}>HEXBOUND</h1>
        <div style={styles.ornament}>◆ • • • ◆</div>
        <h2 style={styles.title}>Reclaim your access</h2>

        {phase === 'verifying' && <p style={styles.body}>Verifying your reset link…</p>}

        {phase === 'invalid' && (
          <p style={styles.error}>
            This reset link is invalid or has expired. Please request a new one from the app.
          </p>
        )}

        {phase === 'ready' && (
          <form onSubmit={handleSubmit} style={styles.form}>
            <label style={styles.label}>
              New password
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                minLength={8}
                autoComplete="new-password"
                required
                style={styles.input}
              />
            </label>
            <label style={styles.label}>
              Confirm password
              <input
                type="password"
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                minLength={8}
                autoComplete="new-password"
                required
                style={styles.input}
              />
            </label>
            {error && <p style={styles.error}>{error}</p>}
            <button type="submit" disabled={submitting} style={styles.button}>
              {submitting ? 'UPDATING…' : 'RESET PASSWORD'}
            </button>
          </form>
        )}

        {phase === 'done' && (
          <p style={styles.success}>
            Password updated. You can now sign in to Hexbound with your new password.
          </p>
        )}

        <div style={styles.footer}>© 2026 Hexbound. All rights reserved.</div>
      </div>
    </main>
  )
}

const styles: Record<string, React.CSSProperties> = {
  page: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: '#0b0d14',
    padding: '24px',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
  },
  card: {
    width: '100%',
    maxWidth: 480,
    background: '#141826',
    border: '1px solid #d4a24a',
    borderRadius: 12,
    padding: '40px 32px',
    color: '#e6e6ea',
    boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
  },
  brand: {
    textAlign: 'center',
    fontSize: 28,
    letterSpacing: 6,
    color: '#d4a24a',
    margin: 0,
    fontWeight: 800,
  },
  ornament: {
    textAlign: 'center',
    color: '#d4a24a',
    letterSpacing: 8,
    margin: '12px 0 24px',
    fontSize: 14,
  },
  title: {
    fontSize: 18,
    fontWeight: 700,
    margin: '0 0 16px',
  },
  body: { color: '#a6a9b5', lineHeight: 1.5 },
  form: { display: 'flex', flexDirection: 'column', gap: 16 },
  label: { display: 'flex', flexDirection: 'column', gap: 6, fontSize: 13, color: '#a6a9b5' },
  input: {
    padding: '12px 14px',
    borderRadius: 8,
    border: '1px solid #2a2f42',
    background: '#0b0d14',
    color: '#e6e6ea',
    fontSize: 15,
    outline: 'none',
  },
  button: {
    marginTop: 8,
    padding: '14px 16px',
    borderRadius: 8,
    border: 'none',
    background: '#d4a24a',
    color: '#0b0d14',
    fontWeight: 800,
    letterSpacing: 2,
    fontSize: 15,
    cursor: 'pointer',
  },
  error: { color: '#ff7a7a', lineHeight: 1.5, margin: 0 },
  success: { color: '#9cd18c', lineHeight: 1.5 },
  footer: {
    marginTop: 32,
    paddingTop: 16,
    borderTop: '1px solid #2a2f42',
    textAlign: 'center',
    fontSize: 12,
    color: '#6a6d7a',
  },
}
