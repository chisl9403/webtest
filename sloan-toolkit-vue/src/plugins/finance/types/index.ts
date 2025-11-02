/**
 * 金融插件类型定义
 */

export interface StockInfo {
  code: string
  name: string
  price: string
  change: string
  changePercent: string
  volume?: number
  amount?: number
  high?: string
  low?: string
  open?: string
  preClose?: string
  turnover?: string
}

export interface DragonTigerStock {
  code: string
  name: string
  date: string
  price: string
  changePercent: string
  netAmount: string
  reason: string
}

// 大盘指数
export interface MarketIndex {
  code: string
  name: string
  price: number
  change: number
  changePercent: number
  high: number
  low: number
  open: number
  preClose: number
  volume: number
  amount: number
  turnover: number
}

// K线数据
export interface KLineData {
  date: string
  open: number
  close: number
  high: number
  low: number
  volume: number
  amount: number
  changePercent: number
}

// 资金流向数据
export interface MoneyFlowData {
  date: string
  mainNetInflow: number
  mainNetInflowRate: number
  largeNetInflow: number
  mediumNetInflow: number
  smallNetInflow: number
  closePrice: number
  changePercent: number
}

// 期货数据
export interface FuturesData {
  code: string
  name: string
  price: number
  change: number
  changePercent: number
  high: number
  low: number
  open: number
  preClose: number
  volume: number
  amount: number
}

// 黄金数据
export interface GoldData {
  code: string
  name: string
  price: number
  change: number
  changePercent: number
  high: number
  low: number
  open: number
  preClose: number
  volume: number
  amount: number
}
