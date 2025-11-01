import InfoPlugin from './InfoPlugin.vue'
import type { Plugin } from '@/types/plugin'

export default {
  meta: {
    id: 'info',
    name: '信息',
    version: '2.0.0',
    author: 'sloan',
    description: '查询天气、股票等综合信息',
    icon: 'ℹ️'
  },

  config: {
    enabled: true,
    autoLoad: true,
    settings: {
      defaultCity: 'Beijing',
      apiKey: ''
    }
  },

  component: InfoPlugin

} as Plugin
