'use client'

/**
 * Web previews of Hexbound DS components — Part 2.
 * Covers game-specific widgets: hero, arena, battle, achievements, dungeon, inbox, etc.
 * NOT production components — only for preview/verification.
 */

import tokens from '@/lib/design-tokens.json'

// Compatibility alias: old code used c.accent.* — map to real token groups
const accent = {
  gold: tokens.colors.gold.gold,
  goldBright: tokens.colors.gold.goldBright,
  goldDim: tokens.colors.gold.goldDim,
  goldGlow: tokens.colors.gold.goldGlow,
  danger: tokens.colors.feedback.danger,
  success: tokens.colors.feedback.success,
  info: tokens.colors.feedback.info,
  purple: tokens.colors.feedback.purple,
  cyan: tokens.colors.feedback.cyan,
  stamina: tokens.colors.stamina.stamina,
}
const c = { ...tokens.colors, accent }
const t = tokens.typography
const s = tokens.spacing
const r = tokens.radius

// ─── Helper: Section Label ──────────────────────────────────────

function Label({ text }: { text: string }) {
  return (
    <span style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 10, marginBottom: 2 }}>
      {text}
    </span>
  )
}

// ─── 1. Hero Widget Previews ────────────────────────────────────

export function HeroWidgetPreviews() {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: s.spaceMD,
      background: c.background.bgSecondary, border: `1px solid ${c.border.borderSubtle}`,
      borderRadius: r.radiusLG, padding: s.spaceMD,
    }}>
      {/* Avatar */}
      <div style={{
        width: 72, height: 72, borderRadius: 36,
        background: c.background.bgTertiary, border: `2px solid ${c.accent.gold}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <span style={{ fontSize: 28 }}>🗡️</span>
      </div>
      {/* Info */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
        <span style={{ color: c.accent.goldBright, fontFamily: '"Oswald", sans-serif', fontSize: 14, letterSpacing: 0.5 }}>
          ShadowBlade
        </span>
        {/* HP bar */}
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
            <span style={{ color: c.accent.success, fontFamily: '"Inter", sans-serif', fontSize: 9, fontWeight: 600 }}>HP</span>
            <span style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 9 }}>340/420</span>
          </div>
          <div style={{ height: 10, borderRadius: 5, background: c.background.bgAbyss, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: '81%', borderRadius: 5, background: 'linear-gradient(90deg, #2ECC71, #55EFC4)' }} />
          </div>
        </div>
        {/* Stamina bar */}
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
            <span style={{ color: c.accent.stamina, fontFamily: '"Inter", sans-serif', fontSize: 9, fontWeight: 600 }}>STA</span>
            <span style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 9 }}>85/120</span>
          </div>
          <div style={{ height: 10, borderRadius: 5, background: c.background.bgAbyss, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: '71%', borderRadius: 5, background: 'linear-gradient(90deg, #E67E22, #F39C12)' }} />
          </div>
        </div>
      </div>
    </div>
  )
}

// ─── 2. Stance Display Previews ─────────────────────────────────

export function StanceDisplayPreviews() {
  return (
    <div style={{
      display: 'flex', alignItems: 'stretch',
      background: c.background.bgSecondary, border: `1px solid ${c.border.borderSubtle}`,
      borderRadius: r.radiusLG, overflow: 'hidden',
    }}>
      {/* Attack zone */}
      <div style={{
        flex: 1, padding: s.spaceMS, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
        background: `${c.stance.zoneHead}10`,
      }}>
        <span style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 9, textTransform: 'uppercase', letterSpacing: 1 }}>Attack</span>
        <div style={{
          width: 40, height: 40, borderRadius: 20,
          background: `${c.stance.zoneHead}20`, border: `2px solid ${c.stance.zoneHead}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <span style={{ fontSize: 16 }}>🎯</span>
        </div>
        <span style={{ color: c.stance.zoneHead, fontFamily: '"Oswald", sans-serif', fontSize: 14 }}>Head</span>
      </div>
      {/* Gold divider */}
      <div style={{ width: 2, background: `linear-gradient(180deg, transparent, ${c.accent.gold}, transparent)` }} />
      {/* Defense zone */}
      <div style={{
        flex: 1, padding: s.spaceMS, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
        background: `${c.stance.zoneChest}10`,
      }}>
        <span style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 9, textTransform: 'uppercase', letterSpacing: 1 }}>Defense</span>
        <div style={{
          width: 40, height: 40, borderRadius: 20,
          background: `${c.stance.zoneChest}20`, border: `2px solid ${c.stance.zoneChest}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <span style={{ fontSize: 16 }}>🛡️</span>
        </div>
        <span style={{ color: c.stance.zoneChest, fontFamily: '"Oswald", sans-serif', fontSize: 14 }}>Chest</span>
      </div>
    </div>
  )
}

// ─── 3. Arena Opponent Card Previews ────────────────────────────

export function ArenaOpponentCardPreviews() {
  return (
    <div style={{
      background: c.background.bgSecondary, border: `1px solid ${c.border.borderSubtle}`,
      borderRadius: r.radiusLG, padding: s.spaceMD,
      display: 'flex', alignItems: 'center', gap: s.spaceMD,
    }}>
      {/* Avatar */}
      <div style={{
        width: 56, height: 56, borderRadius: 28,
        background: c.background.bgTertiary, border: `2px solid ${c.accent.danger}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
      }}>
        <span style={{ fontSize: 22 }}>💀</span>
      </div>
      {/* Info */}
      <div style={{ flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ color: c.text.textPrimary, fontFamily: '"Oswald", sans-serif', fontSize: 16 }}>DarkKnight</span>
          <span style={{
            color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 10,
            background: c.background.bgTertiary, padding: '2px 6px', borderRadius: r.radiusXS,
          }}>Lv.30</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
          <span style={{ color: c.text.textSecondary, fontFamily: '"Inter", sans-serif', fontSize: 12 }}>Warrior</span>
          <span style={{ color: c.accent.gold, fontFamily: '"Oswald", sans-serif', fontSize: 12 }}>⚔ 1250</span>
        </div>
      </div>
      {/* Fight button */}
      <div style={{
        background: 'linear-gradient(180deg, #FF6600, #D35400)',
        color: c.text.textPrimary, border: '2px solid #4A1500',
        borderRadius: r.radiusMD, padding: '8px 16px',
        fontFamily: '"Oswald", sans-serif', fontSize: 14, letterSpacing: 1,
        textTransform: 'uppercase', cursor: 'pointer', position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          position: 'absolute', inset: -2, borderRadius: r.radiusMD,
          background: 'linear-gradient(180deg, rgba(255,255,255,0.12) 0%, transparent 50%, rgba(0,0,0,0.18) 100%)',
          pointerEvents: 'none',
        }} />
        Fight
      </div>
    </div>
  )
}

// ─── 4. Battle Result Card Previews ─────────────────────────────

export function BattleResultCardPreviews() {
  const results = [
    {
      title: 'VICTORY', accent: c.accent.gold, icon: '🏆',
      rewards: [{ label: '+150 Gold', color: c.accent.goldBright }, { label: '+25 XP', color: c.accent.purple }],
    },
    {
      title: 'DEFEAT', accent: c.accent.danger, icon: '💀',
      rewards: [{ label: '-15 Rating', color: c.accent.danger }],
    },
  ]

  return (
    <div style={{ display: 'flex', gap: s.spaceSM }}>
      {results.map(res => (
        <div key={res.title} style={{
          flex: 1, background: c.background.bgSecondary,
          border: `1px solid ${res.accent}40`, borderRadius: r.radiusLG,
          padding: s.spaceMD, textAlign: 'center',
          boxShadow: `0 0 16px ${res.accent}20`,
        }}>
          <span style={{ fontSize: 24 }}>{res.icon}</span>
          <p style={{
            color: res.accent, fontFamily: '"Oswald", sans-serif', fontSize: t.section.fontSize,
            letterSpacing: 2, marginTop: 4,
          }}>{res.title}</p>
          <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 4 }}>
            {res.rewards.map(r => (
              <span key={r.label} style={{ color: r.color, fontFamily: '"Inter", sans-serif', fontSize: 12, fontWeight: 600 }}>
                {r.label}
              </span>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}

// ─── 5. Leaderboard Row Previews ────────────────────────────────

export function LeaderboardRowPreviews() {
  const rows = [
    { rank: 3, name: 'StormBreaker', rating: 1450, isSelf: false },
    { rank: 7, name: 'You', rating: 1320, isSelf: true },
  ]

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {rows.map(row => (
        <div key={row.rank} style={{
          display: 'flex', alignItems: 'center', gap: s.spaceSM,
          background: c.background.bgSecondary,
          border: `1px solid ${row.isSelf ? c.accent.gold : c.border.borderSubtle}`,
          borderRadius: r.radiusMD, padding: `${s.spaceSM}px ${s.spaceMS}px`,
          boxShadow: row.isSelf ? `0 0 8px ${c.accent.gold}20` : 'none',
        }}>
          <span style={{
            color: row.isSelf ? c.accent.goldBright : c.text.textTertiary,
            fontFamily: '"Oswald", sans-serif', fontSize: 16, width: 28, textAlign: 'center',
          }}>#{row.rank}</span>
          <div style={{
            width: 32, height: 32, borderRadius: 16,
            background: c.background.bgTertiary, border: `1.5px solid ${c.border.borderMedium}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <span style={{ fontSize: 14 }}>⚔️</span>
          </div>
          <span style={{
            flex: 1, color: row.isSelf ? c.accent.goldBright : c.text.textPrimary,
            fontFamily: '"Inter", sans-serif', fontSize: 13, fontWeight: row.isSelf ? 700 : 400,
          }}>{row.name}</span>
          <span style={{ color: c.accent.gold, fontFamily: '"Oswald", sans-serif', fontSize: 14 }}>{row.rating}</span>
          {row.isSelf && <Label text="(You)" />}
        </div>
      ))}
    </div>
  )
}

// ─── 6. PvP Stats Widget Previews ───────────────────────────────

export function PvPStatsWidgetPreviews() {
  const stats = [
    { label: 'Win Rate', value: '65%' },
    { label: 'Total Fights', value: '142' },
    { label: 'Win Streak', value: '5' },
    { label: 'Rating', value: '1250' },
  ]

  return (
    <div style={{
      background: c.background.bgSecondary, border: `1px solid ${c.border.borderSubtle}`,
      borderRadius: r.radiusLG, padding: s.spaceMD,
    }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: s.spaceSM, textAlign: 'center' }}>
        {stats.map(stat => (
          <div key={stat.label}>
            <p style={{ color: c.accent.goldBright, fontFamily: '"Oswald", sans-serif', fontSize: 20 }}>{stat.value}</p>
            <p style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 10, marginTop: 2 }}>{stat.label}</p>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── 7. Dungeon Boss Card Previews ──────────────────────────────

export function DungeonBossCardPreviews() {
  const bosses = [
    { state: 'Locked', icon: '🔒', name: '???', difficulty: '', color: c.text.textTertiary, opacity: 0.5, border: c.border.borderSubtle },
    { state: 'Available', icon: '💀', name: 'Bone Colossus', difficulty: 'Hard', color: c.text.textPrimary, opacity: 1, border: c.accent.danger },
    { state: 'Defeated', icon: '✅', name: 'Shadow Wyrm', difficulty: 'Medium', color: c.text.textTertiary, opacity: 0.6, border: c.accent.success },
  ]

  return (
    <div style={{ display: 'flex', gap: s.spaceSM }}>
      {bosses.map(boss => (
        <div key={boss.state} style={{
          flex: 1, background: c.background.bgSecondary,
          border: `1px solid ${boss.border}`, borderRadius: r.radiusLG,
          padding: s.spaceMS, textAlign: 'center', opacity: boss.opacity,
        }}>
          <span style={{ fontSize: 24 }}>{boss.icon}</span>
          <p style={{ color: boss.color, fontFamily: '"Oswald", sans-serif', fontSize: 14, marginTop: 4 }}>{boss.name}</p>
          {boss.difficulty && (
            <span style={{
              display: 'inline-block', marginTop: 4,
              color: boss.state === 'Available' ? c.accent.danger : c.accent.success,
              fontFamily: '"Inter", sans-serif', fontSize: 10, fontWeight: 600,
              background: `${boss.state === 'Available' ? c.accent.danger : c.accent.success}15`,
              padding: '2px 8px', borderRadius: r.radiusXS,
            }}>{boss.difficulty}</span>
          )}
          <p style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 9, marginTop: 4 }}>{boss.state}</p>
        </div>
      ))}
    </div>
  )
}

// ─── 8. Achievement Card Previews ───────────────────────────────

export function AchievementCardPreviews() {
  const achievements = [
    { state: 'Locked', icon: '🔒', title: '???', desc: 'Hidden achievement', progress: 0, max: 10, claimable: false, claimed: false },
    { state: 'In Progress', icon: '⚔️', title: 'Arena Veteran', desc: 'Win 10 PvP battles', progress: 6, max: 10, claimable: false, claimed: false },
    { state: 'Claimable', icon: '🏆', title: 'First Blood', desc: 'Win your first PvP', progress: 1, max: 1, claimable: true, claimed: false },
    { state: 'Claimed', icon: '✅', title: 'Dungeon Delver', desc: 'Complete 5 dungeons', progress: 5, max: 5, claimable: false, claimed: true },
  ]

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {achievements.map(ach => (
        <div key={ach.state} style={{
          display: 'flex', alignItems: 'center', gap: s.spaceMS,
          background: c.background.bgSecondary,
          border: `1px solid ${ach.claimable ? c.accent.gold : ach.claimed ? c.accent.success + '40' : c.border.borderSubtle}`,
          borderRadius: r.radiusMD, padding: s.spaceMS,
          opacity: ach.state === 'Locked' ? 0.5 : ach.claimed ? 0.7 : 1,
          boxShadow: ach.claimable ? `0 0 12px ${c.accent.gold}25` : 'none',
        }}>
          <span style={{ fontSize: 20 }}>{ach.icon}</span>
          <div style={{ flex: 1 }}>
            <p style={{
              color: ach.claimable ? c.accent.goldBright : c.text.textPrimary,
              fontFamily: '"Oswald", sans-serif', fontSize: 13,
              ...(ach.state === 'Locked' ? { filter: 'blur(3px)' } : {}),
            }}>{ach.title}</p>
            <p style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 10, marginTop: 2 }}>{ach.desc}</p>
            {/* Progress bar for In Progress */}
            {ach.state === 'In Progress' && (
              <div style={{ height: 6, borderRadius: 3, background: c.background.bgAbyss, marginTop: 4, overflow: 'hidden' }}>
                <div style={{
                  height: '100%', width: `${(ach.progress / ach.max) * 100}%`,
                  borderRadius: 3, background: `linear-gradient(90deg, ${c.accent.gold}, ${c.accent.goldBright})`,
                }} />
              </div>
            )}
          </div>
          {ach.claimable && (
            <div style={{
              background: `linear-gradient(180deg, ${c.accent.gold}, ${c.accent.goldDim})`,
              color: c.text.textOnGold, fontFamily: '"Oswald", sans-serif', fontSize: 11,
              padding: '4px 10px', borderRadius: r.radiusSM, letterSpacing: 0.5,
              textTransform: 'uppercase', cursor: 'pointer',
            }}>Claim</div>
          )}
          {ach.claimed && (
            <span style={{ color: c.accent.success, fontSize: 16 }}>✓</span>
          )}
        </div>
      ))}
    </div>
  )
}

// ─── 9. Active Quest Banner Previews ────────────────────────────

export function ActiveQuestBannerPreviews() {
  const quests = [
    { state: 'Active', title: 'Win 3 PvP Battles', progress: '2/3', accent: c.accent.info, icon: '⚔️', done: false },
    { state: 'Complete', title: 'Collect 500 Gold', progress: '500/500', accent: c.accent.success, icon: '✅', done: true },
  ]

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {quests.map(q => (
        <div key={q.state} style={{
          display: 'flex', alignItems: 'center', gap: s.spaceMS,
          background: c.background.bgSecondary,
          border: `1px solid ${q.accent}30`, borderLeft: `3px solid ${q.accent}`,
          borderRadius: r.radiusMD, padding: `${s.spaceSM}px ${s.spaceMS}px`,
        }}>
          <span style={{ fontSize: 16 }}>{q.icon}</span>
          <div style={{ flex: 1 }}>
            <p style={{ color: c.text.textPrimary, fontFamily: '"Inter", sans-serif', fontSize: 12, fontWeight: 600 }}>{q.title}</p>
            {!q.done && (
              <div style={{ height: 4, borderRadius: 2, background: c.background.bgAbyss, marginTop: 4, overflow: 'hidden', width: '80%' }}>
                <div style={{ height: '100%', width: '66%', borderRadius: 2, background: q.accent }} />
              </div>
            )}
          </div>
          <span style={{
            color: q.done ? c.accent.success : q.accent,
            fontFamily: '"Oswald", sans-serif', fontSize: 13,
            ...(q.done ? { textTransform: 'uppercase' as const } : {}),
          }}>{q.done ? 'COMPLETE' : q.progress}</span>
        </div>
      ))}
    </div>
  )
}

// ─── 10. BP Reward Node Previews ────────────────────────────────

export function BPRewardNodePreviews() {
  const nodes = [
    { state: 'Locked', icon: '🔒', border: c.border.borderSubtle, bg: c.background.bgAbyss, fill: false },
    { state: 'Available', icon: '🎁', border: c.accent.gold, bg: c.background.bgSecondary, fill: false },
    { state: 'Claimed', icon: '✓', border: c.accent.gold, bg: c.accent.gold, fill: true },
    { state: 'Premium', icon: '⭐', border: c.accent.purple, bg: `${c.accent.purple}20`, fill: false },
  ]

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: s.spaceMD }}>
      {nodes.map((node, i) => (
        <div key={node.state} style={{ display: 'flex', alignItems: 'center', gap: 0 }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{
              width: 48, height: 48, borderRadius: 24,
              background: node.bg, border: `2px solid ${node.border}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: node.state === 'Available' ? `0 0 8px ${c.accent.gold}30` : 'none',
            }}>
              <span style={{
                fontSize: node.fill ? 18 : 16,
                color: node.fill ? c.text.textOnGold : undefined,
                ...(node.state === 'Locked' ? { opacity: 0.4 } : {}),
              }}>{node.icon}</span>
            </div>
            <p style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 9, marginTop: 4 }}>{node.state}</p>
          </div>
          {i < nodes.length - 1 && (
            <div style={{
              width: 20, height: 2, background: i < 2 ? c.accent.gold : c.border.borderSubtle,
              marginLeft: 2, marginRight: 2, marginBottom: 14,
            }} />
          )}
        </div>
      ))}
    </div>
  )
}

// ─── 11. Inbox Row Previews ─────────────────────────────────────

export function InboxRowPreviews() {
  const messages = [
    { state: 'Unread', title: 'Battle Reward', subtitle: 'You received 150 gold from arena victory', time: '2m ago', unread: true },
    { state: 'Read', title: 'Daily Login', subtitle: 'Your daily reward is ready to claim', time: '1h ago', unread: false },
  ]

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      {messages.map(msg => (
        <div key={msg.state} style={{
          display: 'flex', alignItems: 'center', gap: s.spaceMS,
          background: c.background.bgSecondary,
          border: `1px solid ${c.border.borderSubtle}`,
          borderRadius: r.radiusMD, padding: s.spaceMS,
        }}>
          {msg.unread && (
            <div style={{ width: 8, height: 8, borderRadius: 4, background: c.accent.gold, flexShrink: 0 }} />
          )}
          <div style={{ flex: 1 }}>
            <p style={{
              color: c.text.textPrimary, fontFamily: '"Inter", sans-serif', fontSize: 13,
              fontWeight: msg.unread ? 700 : 400,
            }}>{msg.title}</p>
            <p style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 11, marginTop: 2 }}>{msg.subtitle}</p>
          </div>
          <span style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 10, flexShrink: 0 }}>{msg.time}</span>
        </div>
      ))}
    </div>
  )
}

// ─── 12. NPC Guide Widget Previews ──────────────────────────────

export function NPCGuideWidgetPreviews() {
  return (
    <div style={{
      background: c.background.bgSecondary,
      border: `1px solid ${c.border.borderOrnament}`,
      borderRadius: r.radiusLG, padding: s.spaceMD,
      position: 'relative',
    }}>
      {/* Corner ornament hint */}
      <div style={{
        position: 'absolute', top: -1, left: -1, width: 12, height: 12,
        borderTop: `2px solid ${c.accent.gold}`, borderLeft: `2px solid ${c.accent.gold}`,
        borderRadius: '4px 0 0 0',
      }} />
      <div style={{
        position: 'absolute', top: -1, right: -1, width: 12, height: 12,
        borderTop: `2px solid ${c.accent.gold}`, borderRight: `2px solid ${c.accent.gold}`,
        borderRadius: '0 4px 0 0',
      }} />
      <p style={{
        color: c.accent.goldBright, fontFamily: '"Oswald", sans-serif', fontSize: 13,
        letterSpacing: 1, textTransform: 'uppercase',
      }}>Lady Fortuna</p>
      <p style={{
        color: c.text.textSecondary, fontFamily: '"Inter", sans-serif', fontSize: 12,
        marginTop: 6, lineHeight: 1.5, fontStyle: 'italic',
      }}>
        &ldquo;The arena awaits, champion. Your enemies grow restless...&rdquo;
      </p>
    </div>
  )
}

// ─── 13. Event Banner Previews ──────────────────────────────────

export function EventBannerPreviews() {
  const events = [
    { type: 'Normal', title: 'Weekend Bonus', desc: '2x Gold from PvP', accent: c.accent.info, timer: '23:45:12' },
    { type: 'Urgent', title: 'Flash Event', desc: 'Boss Rush ending soon!', accent: c.accent.danger, timer: '01:30:00' },
  ]

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {events.map(ev => (
        <div key={ev.type} style={{
          display: 'flex', alignItems: 'center', gap: s.spaceMS,
          background: `${ev.accent}08`, border: `1px solid ${ev.accent}40`,
          borderRadius: r.radiusMD, padding: `${s.spaceSM}px ${s.spaceMS}px`,
        }}>
          <span style={{ fontSize: 16 }}>{ev.type === 'Urgent' ? '🔥' : '🎉'}</span>
          <div style={{ flex: 1 }}>
            <p style={{ color: ev.accent, fontFamily: '"Oswald", sans-serif', fontSize: 13 }}>{ev.title}</p>
            <p style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 10 }}>{ev.desc}</p>
          </div>
          <span style={{
            color: ev.accent, fontFamily: '"Oswald", sans-serif', fontSize: 13,
            fontVariantNumeric: 'tabular-nums',
          }}>{ev.timer}</span>
        </div>
      ))}
    </div>
  )
}

// ─── 14. Celebration Banner Previews ────────────────────────────

export function CelebrationBannerPreviews() {
  const celebrations = [
    { type: 'LevelUp', color: c.toast.levelUp, icon: '⬆️', title: 'LEVEL UP!', sub: 'You reached level 25' },
    { type: 'Achievement', color: c.toast.achievement, icon: '🏆', title: 'ACHIEVEMENT UNLOCKED', sub: 'Arena Veteran' },
    { type: 'RankUp', color: c.toast.rankUp, icon: '👑', title: 'RANK UP!', sub: 'Gold III → Platinum I' },
    { type: 'Quest', color: c.accent.cyan, icon: '📜', title: 'QUEST COMPLETE', sub: 'Daily Warrior' },
    { type: 'RareDrop', color: c.rarity.legendary, icon: '✨', title: 'LEGENDARY DROP!', sub: 'Excalibur obtained' },
  ]

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {celebrations.map(cel => (
        <div key={cel.type} style={{
          background: `linear-gradient(90deg, ${cel.color}15, transparent)`,
          border: `1px solid ${cel.color}30`,
          borderLeft: `3px solid ${cel.color}`,
          borderRadius: r.radiusMD, padding: `${s.spaceSM}px ${s.spaceMS}px`,
          display: 'flex', alignItems: 'center', gap: s.spaceMS,
        }}>
          <span style={{ fontSize: 18 }}>{cel.icon}</span>
          <div>
            <p style={{ color: cel.color, fontFamily: '"Oswald", sans-serif', fontSize: 13, letterSpacing: 1 }}>{cel.title}</p>
            <p style={{ color: c.text.textSecondary, fontFamily: '"Inter", sans-serif', fontSize: 10 }}>{cel.sub}</p>
          </div>
        </div>
      ))}
    </div>
  )
}

// ─── 15. Guest Gate Previews ────────────────────────────────────

export function GuestGatePreviews() {
  return (
    <div style={{
      background: c.background.bgSecondary,
      border: `1px solid ${c.border.borderMedium}`,
      borderRadius: r.radiusLG, padding: s.spaceLG,
      textAlign: 'center', maxWidth: 260,
    }}>
      <span style={{ fontSize: 32 }}>🏰</span>
      <p style={{
        color: c.accent.goldBright, fontFamily: '"Oswald", sans-serif', fontSize: t.cardTitle.fontSize,
        marginTop: s.spaceSM, letterSpacing: 0.5,
      }}>Create Account</p>
      <p style={{
        color: c.text.textSecondary, fontFamily: '"Inter", sans-serif', fontSize: 12,
        marginTop: s.spaceSM, lineHeight: 1.5,
      }}>
        Sign up to save your progress and unlock all features.
      </p>
      {/* Sign Up button */}
      <div style={{
        background: `linear-gradient(180deg, ${c.accent.gold}, ${c.accent.goldDim})`,
        color: c.text.textOnGold, fontFamily: '"Oswald", sans-serif', fontSize: 14,
        padding: '10px 0', borderRadius: r.radiusMD, marginTop: s.spaceMD,
        letterSpacing: 1, textTransform: 'uppercase', cursor: 'pointer',
      }}>Sign Up</div>
      {/* Ghost button */}
      <div style={{
        color: c.accent.gold, fontFamily: '"Oswald", sans-serif', fontSize: 13,
        padding: '8px 0', marginTop: s.spaceSM, cursor: 'pointer',
        letterSpacing: 0.5,
      }}>Continue as Guest</div>
    </div>
  )
}

// ─── 16. Session Expired Previews ───────────────────────────────

export function SessionExpiredPreviews() {
  return (
    <div style={{
      background: c.background.bgSecondary,
      border: `1px solid ${c.border.borderMedium}`,
      borderRadius: r.radiusLG, padding: s.spaceLG,
      textAlign: 'center', maxWidth: 260,
    }}>
      <span style={{ fontSize: 28 }}>⚠️</span>
      <p style={{
        color: c.text.textPrimary, fontFamily: '"Oswald", sans-serif', fontSize: t.cardTitle.fontSize,
        marginTop: s.spaceSM,
      }}>Session Expired</p>
      <p style={{
        color: c.text.textSecondary, fontFamily: '"Inter", sans-serif', fontSize: 12,
        marginTop: s.spaceSM, lineHeight: 1.5,
      }}>
        Your session has ended. Please log in again to continue.
      </p>
      <div style={{
        background: `linear-gradient(180deg, ${c.accent.gold}, ${c.accent.goldDim})`,
        color: c.text.textOnGold, fontFamily: '"Oswald", sans-serif', fontSize: 14,
        padding: '10px 0', borderRadius: r.radiusMD, marginTop: s.spaceMD,
        letterSpacing: 1, textTransform: 'uppercase', cursor: 'pointer',
      }}>Log In Again</div>
    </div>
  )
}

// ─── 17. Item Detail Sheet Previews ─────────────────────────────

export function ItemDetailSheetPreviews() {
  const stats = [
    { label: 'Attack', value: '+45' },
    { label: 'Critical', value: '+12%' },
    { label: 'Bonus', value: 'Holy Dmg' },
  ]

  return (
    <div style={{
      background: c.background.bgSecondary,
      border: `1px solid ${c.rarity.legendary}40`,
      borderRadius: r.radiusLG, padding: s.spaceMD,
      maxWidth: 220, boxShadow: `0 0 20px ${c.rarity.legendary}15`,
    }}>
      {/* Item image placeholder */}
      <div style={{
        height: 80, borderRadius: r.radiusMD,
        background: c.background.bgTertiary,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `inset 0 0 30px ${c.rarity.legendary}15`,
        marginBottom: s.spaceMS,
      }}>
        <div style={{ width: 40, height: 40, borderRadius: 6, background: `${c.rarity.legendary}30` }} />
      </div>
      {/* Name + rarity */}
      <p style={{ color: c.rarity.legendary, fontFamily: '"Oswald", sans-serif', fontSize: 16 }}>Excalibur</p>
      <span style={{
        display: 'inline-block', marginTop: 4,
        color: c.rarity.legendary, fontFamily: '"Inter", sans-serif', fontSize: 10, fontWeight: 700,
        background: `${c.rarity.legendary}15`, padding: '2px 8px', borderRadius: r.radiusXS,
        textTransform: 'uppercase', letterSpacing: 0.5,
      }}>Legendary</span>
      {/* Stats */}
      <div style={{
        marginTop: s.spaceMS, borderTop: `1px solid ${c.border.borderSubtle}`,
        paddingTop: s.spaceSM, display: 'flex', flexDirection: 'column', gap: 4,
      }}>
        {stats.map(stat => (
          <div key={stat.label} style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ color: c.text.textTertiary, fontFamily: '"Inter", sans-serif', fontSize: 11 }}>{stat.label}</span>
            <span style={{ color: c.accent.goldBright, fontFamily: '"Oswald", sans-serif', fontSize: 12 }}>{stat.value}</span>
          </div>
        ))}
      </div>
      {/* Equip button */}
      <div style={{
        background: `linear-gradient(180deg, ${c.accent.gold}, ${c.accent.goldDim})`,
        color: c.text.textOnGold, fontFamily: '"Oswald", sans-serif', fontSize: 14,
        padding: '8px 0', borderRadius: r.radiusMD, marginTop: s.spaceMS,
        textAlign: 'center', letterSpacing: 1, textTransform: 'uppercase', cursor: 'pointer',
      }}>Equip</div>
    </div>
  )
}

// ─── 18. Level Up Modal Previews ────────────────────────────────

export function LevelUpModalPreviews() {
  return (
    <div style={{
      background: c.background.bgSecondary,
      border: `1px solid ${c.accent.gold}40`,
      borderRadius: r.radiusLG, padding: s.spaceLG,
      textAlign: 'center', maxWidth: 260,
      boxShadow: `0 0 30px ${c.accent.gold}20`,
    }}>
      <span style={{ fontSize: 36 }}>⬆️</span>
      <p style={{
        color: c.accent.goldBright, fontFamily: '"Oswald", sans-serif', fontSize: t.title.fontSize,
        letterSpacing: 2, marginTop: s.spaceSM,
      }}>LEVEL UP!</p>
      {/* Level transition */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginTop: s.spaceMS }}>
        <span style={{ color: c.text.textSecondary, fontFamily: '"Oswald", sans-serif', fontSize: 20 }}>24</span>
        <span style={{ color: c.accent.gold, fontFamily: '"Oswald", sans-serif', fontSize: 16 }}>→</span>
        <span style={{ color: c.accent.goldBright, fontFamily: '"Oswald", sans-serif', fontSize: 24, fontWeight: 700 }}>25</span>
      </div>
      {/* Stat points */}
      <div style={{
        background: `${c.accent.success}10`, border: `1px solid ${c.accent.success}30`,
        borderRadius: r.radiusMD, padding: `${s.spaceSM}px ${s.spaceMS}px`,
        marginTop: s.spaceMS,
      }}>
        <span style={{ color: c.accent.success, fontFamily: '"Inter", sans-serif', fontSize: 13, fontWeight: 600 }}>
          +3 Stat Points
        </span>
      </div>
      {/* Continue button */}
      <div style={{
        background: `linear-gradient(180deg, ${c.accent.gold}, ${c.accent.goldDim})`,
        color: c.text.textOnGold, fontFamily: '"Oswald", sans-serif', fontSize: 14,
        padding: '10px 0', borderRadius: r.radiusMD, marginTop: s.spaceMD,
        letterSpacing: 1, textTransform: 'uppercase', cursor: 'pointer',
      }}>Continue</div>
    </div>
  )
}
