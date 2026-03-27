-- Guild Challenges table
CREATE TABLE IF NOT EXISTS guild_challenges (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  goal_type TEXT NOT NULL,
  goal_target INTEGER NOT NULL,
  current_progress INTEGER NOT NULL DEFAULT 0,
  gold_reward INTEGER NOT NULL,
  gem_reward INTEGER NOT NULL DEFAULT 0,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  completed BOOLEAN NOT NULL DEFAULT false,
  claimed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_guild_challenges_dates ON guild_challenges (start_at, end_at);

-- Milestone Claims table
CREATE TABLE IF NOT EXISTS milestone_claims (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  character_id TEXT NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  milestone_level INTEGER NOT NULL,
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(character_id, milestone_level)
);

CREATE INDEX IF NOT EXISTS idx_milestone_claims_character ON milestone_claims (character_id);
