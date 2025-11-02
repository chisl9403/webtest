import type { Plugin } from '@/types/plugin'
import FinancePlugin from './FinancePlugin.vue'

export default {
  meta: {
    id: 'finance',
    name: '金融',
    version: '1.0.0',
    author: 'Sloan',
    description: '实时股票行情和龙虎榜数据',
    icon: '💰'
  },
  config: {
    enabled: true,
    autoLoad: true
  },
  component: FinancePlugin
} as Plugin
