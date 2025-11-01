export interface LogStats {
  total_points: number
  avg_current: number
  max_current: number
  min_current: number
  avg_temp: number
  charging_time: number
}

export interface AnalysisResult {
  stats: LogStats
  graph: string
}
