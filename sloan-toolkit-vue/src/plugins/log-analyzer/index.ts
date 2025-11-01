import LogAnalyzer from './LogAnalyzer.vue'
import type { Plugin } from '@/types/plugin'

export default {
  meta: {
    id: 'log-analyzer',
    name: 'PM:INFO 日志分析',
    version: '2.0.0',
    author: 'sloan',
    description: '分析 PM:INFO 日志文件，生成可视化图表和统计数据',
    icon: '📊'
  },

  config: {
    enabled: true
  },

  component: LogAnalyzer

} as Plugin
