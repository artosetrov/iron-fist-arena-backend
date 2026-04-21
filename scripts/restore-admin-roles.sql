-- =============================================================================
-- restore-admin-roles.sql — Post-restore admin-role re-apply
-- =============================================================================
--
-- Snapshot-based DB restores silently flip known admin accounts back to
-- role='player' if the snapshot predates the promotion. This is NOT a
-- static-catalog (those live in migrations/20260421_seed_*); admin role is
-- per-user state, so it needs its own runbook script rather than a seed.
--
-- Related incident: Degon account (2026-04-19) — admin panel silently
-- locked out after snapshot restore, because restore pulled a stale
-- role='player' row.
--
-- How to run (post-restore checklist — gatekeeper §6c):
--   psql "$DATABASE_URL" -f scripts/restore-admin-roles.sql
--
-- Verify afterward:
--   psql "$DATABASE_URL" -c "SELECT email, role FROM users WHERE role='admin' ORDER BY email;"
--
-- Maintenance: when you promote a new admin in prod, add their email below
-- in the same commit. git-history is the source of truth for "who is admin",
-- not Supabase row state.
--
-- Idempotent: UPDATE only touches rows that differ, and noop when the email
-- is not yet registered (row count = 0, no error).
-- =============================================================================

BEGIN;

UPDATE users
SET role = 'admin',
    updated_at = NOW()
WHERE email IN (
  'osetrov.artem@gmail.com'
  -- add newly-promoted admins here (alphabetical), one per line:
  -- 'someone@example.com',
)
AND role IS DISTINCT FROM 'admin';

-- Spot-check: fail loudly if nobody has role='admin' after this script runs.
-- This catches the "snapshot wiped all admins AND we forgot to add them here"
-- failure mode. RAISE EXCEPTION rolls back the transaction.
DO $$
DECLARE
  admin_count INT;
BEGIN
  SELECT COUNT(*) INTO admin_count FROM users WHERE role = 'admin';
  IF admin_count = 0 THEN
    RAISE EXCEPTION 'restore-admin-roles.sql: no admin users after apply — check email list above';
  END IF;
END $$;

COMMIT;

-- Report the result so the operator can visually confirm:
SELECT email, role, updated_at
FROM users
WHERE role = 'admin'
ORDER BY email;
