export interface AuditEntry {
  timestamp: string
  adminId: string
  adminEmail: string | null
  action: string
  target: string
  details?: Record<string, unknown>
}

/**
 * Logs an admin action as structured JSON to the server console.
 * In a production system this would write to a database table or
 * external logging service; for now structured console output is
 * sufficient and easy to pipe into log aggregators.
 */
export function auditLog(
  admin: { id: string; email?: string | null },
  action: string,
  target: string,
  details?: Record<string, unknown>
): void {
  const entry: AuditEntry = {
    timestamp: new Date().toISOString(),
    adminId: admin.id,
    adminEmail: admin.email ?? null,
    action,
    target,
    ...(details ? { details } : {}),
  }

  // Structured JSON line — easy to parse with jq / Datadog / etc.
  console.log(JSON.stringify({ level: 'audit', ...entry }))
}
