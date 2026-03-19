// KPI types
export type KpiStatus = 'normal' | 'warning' | 'critical'
export type TrendDirection = 'up' | 'down' | 'flat'
export type AlertSeverity = 'info' | 'warning' | 'critical'
export type AlertStatus = 'active' | 'acknowledged' | 'resolved'

export interface KpiItem {
  key: string
  label: string
  value: number
  previousValue: number
  deltaPercent: number
  trend: TrendDirection
  status: KpiStatus
  format?: 'number' | 'percent' | 'currency' | 'duration'
}

export interface DashboardAlert {
  id: string
  alertType: string
  severity: AlertSeverity
  title: string
  description: string
  detectedAt: string
  status: AlertStatus
  entityType?: string
  entityId?: string
  suggestedAction?: string
  linkTarget?: string
}

export interface TimeSeriesPoint {
  date: string
  value: number
}

export interface EconomySnapshot {
  goldInflow: TimeSeriesPoint[]
  goldOutflow: TimeSeriesPoint[]
  goldSinkBreakdown: Array<{ source: string; amount: number }>
  gemSpendBreakdown: Array<{ source: string; amount: number }>
  inflationRisk: 'low' | 'medium' | 'high'
  totalGoldCirculation: number
  totalGemsCirculation: number
}

export interface PvpSnapshot {
  classWinRates: Array<{ class: string; winRate: number; totalMatches: number }>
  ratingDistribution: Array<{ bucket: string; count: number }>
  matchVolumeByDay: TimeSeriesPoint[]
  avgFightDuration: number
  totalMatchesToday: number
  matchmakingFairness: number // 0-1 score
}

export interface PlayerSnapshot {
  newUsersToday: number
  activeToday: number
  returningToday: number
  guestCount: number
  registeredCount: number
  guestConversionRate: number
  registrationsByDay: TimeSeriesPoint[]
  retentionD1: number
  retentionD7: number
  retentionD30: number
}

export interface SystemHealth {
  apiErrorRate: number
  slowEndpointsCount: number
  avgResponseTime: number
  recentErrors: Array<{ route: string; count: number; lastSeen: string }>
}

export interface DashboardData {
  kpis: KpiItem[]
  economy: EconomySnapshot
  pvp: PvpSnapshot
  players: PlayerSnapshot
  alerts: DashboardAlert[]
  system: SystemHealth
  generatedAt: string
}
