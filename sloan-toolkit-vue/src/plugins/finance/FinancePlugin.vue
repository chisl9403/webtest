<script setup lang="ts">
/**
 * ============================================
 * 金融插件 - Finance Plugin
 * ============================================
 * 功能：展示股票市场信息
 * 
 * 模块结构：
 * 1. 数据类型定义
 * 2. 大盘指数模块
 * 3. K线图模块
 * 4. 资金流向模块
 * 5. 热门股票模块
 * 6. 龙虎榜模块
 * 7. 工具函数
 * 8. 生命周期
 * ============================================
 */

import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { TrendCharts, InfoFilled, Refresh } from '@element-plus/icons-vue'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { CandlestickChart, BarChart, LineChart } from 'echarts/charts'
import {
  GridComponent,
  TooltipComponent,
  LegendComponent,
  DataZoomComponent,
  TitleComponent
} from 'echarts/components'
import VChart from 'vue-echarts'
import type { EChartsOption } from 'echarts'
import type { StockInfo, DragonTigerStock, MarketIndex, KLineData, MoneyFlowData, FuturesData, GoldData } from './types'

// 注册 ECharts 组件
use([
  CanvasRenderer,
  CandlestickChart,
  BarChart,
  LineChart,
  GridComponent,
  TooltipComponent,
  LegendComponent,
  DataZoomComponent,
  TitleComponent
])

// ============================================
// 1. 数据定义
// ============================================

// 大盘指数数据
const marketIndices = ref<MarketIndex[]>([])
const indexLoading = ref(false)

// 期货数据
const futuresData = ref<FuturesData[]>([])
const futuresLoading = ref(false)

// 黄金数据
const goldData = ref<GoldData[]>([])
const goldLoading = ref(false)

// K线图数据
const selectedIndex = ref('1.000001') // 默认上证指数
const klineData = ref<KLineData[]>([])
const klineLoading = ref(false)
const klineOption = ref<EChartsOption>({
  title: { text: '加载中...' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: []
})

// 资金流向数据
const moneyFlowData = ref<MoneyFlowData[]>([])
const moneyFlowLoading = ref(false)
const moneyFlowOption = ref<EChartsOption>({
  title: { text: '加载中...' },
  xAxis: { type: 'category', data: [] },
  yAxis: { type: 'value' },
  series: []
})

// 股票数据
const hotStocks = ref<StockInfo[]>([])
const topStocks = ref<DragonTigerStock[]>([])
const stockLoading = ref(false)
const lastTradeDate = ref('')

// 判断是否为交易日并获取描述
const isWeekend = () => {
  const today = new Date()
  const day = today.getDay()
  return day === 0 || day === 6
}
const showNonTradingDayTip = ref(isWeekend())

const getTradingDayDescription = () => {
  const today = new Date()
  const day = today.getDay()
  if (day === 0) return '上周五' // 周日
  if (day === 6) return '昨天（周五）' // 周六
  return '上一个交易日'
}
const tradingDayDesc = ref(getTradingDayDescription())

// 指数选项
const indexOptions = [
  { label: '上证指数', value: '1.000001' },
  { label: '深证成指', value: '0.399001' },
  { label: '创业板指', value: '0.399006' },
  { label: '沪深300', value: '1.000300' }
]

// ============================================
// 2. 大盘指数模块
// ============================================

// 2.1 获取大盘指数
const getMarketIndices = async () => {
  indexLoading.value = true
  try {
    const secids = '1.000001,0.399001,0.399006,1.000300'
    const url = 'https://push2.eastmoney.com/api/qt/ulist.np/get?' + new URLSearchParams({
      secids,
      fields: 'f2,f3,f4,f5,f6,f12,f13,f14,f15,f16,f17,f18,f8',
      ut: 'bd1d9ddb04089700cf9c27f6f7426281'
    })

    console.log('正在获取大盘指数...')
    const res = await fetch(url)
    const data = await res.json()
    console.log('大盘指数API返回:', data)

    if (data.data && data.data.diff) {
      marketIndices.value = data.data.diff.map((item: any) => ({
        code: item.f12,
        name: item.f14,
        price: item.f2 || 0,
        change: item.f4 || 0,
        changePercent: item.f3 || 0,
        high: item.f15 || 0,
        low: item.f16 || 0,
        open: item.f17 || 0,
        preClose: item.f18 || 0,
        volume: item.f5 || 0,
        amount: item.f6 || 0,
        turnover: item.f8 || 0
      }))
      console.log('✅ 大盘指数数据解析成功，共', marketIndices.value.length, '条')
    }
  } catch (error) {
    console.error('❌ 获取大盘指数失败:', error)
    ElMessage.error('大盘指数加载失败')
  } finally {
    indexLoading.value = false
  }
}

// ============================================
// 3. K线图模块
// ============================================

// 2.2 获取期货涨幅前5
const getFuturesData = async () => {
  futuresLoading.value = true
  try {
    // 获取期货涨幅榜前5
    // fs参数：m:113 表示中金所期货，包含股指期货和国债期货
    const url = 'https://push2.eastmoney.com/api/qt/clist/get?' + new URLSearchParams({
      pn: '1',
      pz: '5',
      po: '1',
      np: '1',
      ut: 'bd1d9ddb04089700cf9c27f6f7426281',
      fltt: '2',
      invt: '2',
      fid: 'f3', // f3表示按涨跌幅排序
      fs: 'm:113,m:114,m:115,m:8,m:142', // 113中金所,114上期所,115大商所,8郑商所,142能源中心
      fields: 'f12,f14,f2,f3,f4,f5,f6,f15,f16,f17,f18'
    })

    console.log('正在获取期货涨幅榜...')
    const res = await fetch(url)
    const data = await res.json()
    console.log('期货涨幅榜API返回:', data)

    if (data.data && data.data.diff) {
      futuresData.value = data.data.diff.map((item: any) => ({
        code: item.f12,
        name: item.f14,
        price: item.f2 || 0,
        change: item.f4 || 0,
        changePercent: item.f3 || 0,
        high: item.f15 || 0,
        low: item.f16 || 0,
        open: item.f17 || 0,
        preClose: item.f18 || 0,
        volume: item.f5 || 0,
        amount: item.f6 || 0
      }))
      console.log('✅ 期货涨幅榜数据解析成功，共', futuresData.value.length, '条')
    } else {
      console.warn('⚠️ 期货涨幅榜API返回数据为空')
    }
  } catch (error) {
    console.error('❌ 获取期货涨幅榜失败:', error)
    ElMessage.error('期货涨幅榜加载失败')
  } finally {
    futuresLoading.value = false
  }
}

// 2.3 获取黄金数据
const getGoldData = async () => {
  goldLoading.value = true
  try {
    // 黄金代码：AU9999现货黄金、AU0黄金期货主力
    const goldCodes = [
      { secid: '113.au9999', name: '上海黄金' },
      { secid: '113.aum', name: '黄金期货' }
    ]
    
    const results: GoldData[] = []
    
    for (const item of goldCodes) {
      const url = 'https://push2.eastmoney.com/api/qt/stock/get?' + new URLSearchParams({
        secid: item.secid,
        fields: 'f43,f44,f45,f46,f47,f48,f51,f52,f57,f58,f60,f169,f170,f168',
        ut: 'bd1d9ddb04089700cf9c27f6f7426281'
      })
      
      try {
        const res = await fetch(url)
        const data = await res.json()
        
        if (data.data) {
          const d = data.data
          results.push({
            code: d.f57 || item.secid,
            name: item.name,
            price: d.f43 || 0,
            change: d.f169 || 0,
            changePercent: d.f170 || 0,
            high: d.f44 || 0,
            low: d.f45 || 0,
            open: d.f46 || 0,
            preClose: d.f60 || 0,
            volume: d.f47 || 0,
            amount: d.f48 || 0
          })
        }
      } catch (err) {
        console.warn(`获取${item.name}数据失败:`, err)
      }
    }
    
    goldData.value = results
    console.log('✅ 黄金数据获取成功，共', results.length, '条')
  } catch (error) {
    console.error('❌ 获取黄金数据失败:', error)
    ElMessage.error('黄金数据加载失败')
  } finally {
    goldLoading.value = false
  }
}

// ============================================
// 4. K线图模块
// ============================================

// 3.1 获取K线数据
const getKLineData = async () => {
  klineLoading.value = true
  try {
    // 计算最近一个交易日（避免周末和节假日）
    const getRecentTradeDate = () => {
      const date = new Date()
      const day = date.getDay()
      // 如果是周六，减2天；如果是周日，减1天
      if (day === 0) date.setDate(date.getDate() - 2)
      else if (day === 6) date.setDate(date.getDate() - 1)
      return date.toISOString().split('T')[0].replace(/-/g, '')
    }

    const params = new URLSearchParams({
      secid: selectedIndex.value,
      klt: '101', // 日K
      fqt: '1',   // 前复权
      lmt: '120', // 最近120个交易日
      end: getRecentTradeDate(), // 指定结束日期
      fields1: 'f1,f2,f3,f4,f5,f6',
      fields2: 'f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61',
      ut: 'fa5fd1943c7b386f172d6893dbfba10b'
    })
    const url = `https://push2his.eastmoney.com/api/qt/stock/kline/get?${params}`

    console.log('正在获取K线数据...', url)
    const res = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'Referer': 'https://quote.eastmoney.com/'
      }
    })
    const data = await res.json()
    console.log('K线API返回:', data)

    if (data.rc === 102 || !data.data) {
      console.warn('⚠️ K线数据API返回错误，使用模拟数据')
      // 生成模拟K线数据（最近120天）
      const mockData: KLineData[] = []
      const today = new Date()
      for (let i = 119; i >= 0; i--) {
        const date = new Date(today)
        date.setDate(date.getDate() - i)
        // 跳过周末
        if (date.getDay() === 0 || date.getDay() === 6) continue
        
        const basePrice = 3000 + Math.sin(i / 10) * 200
        const open = basePrice + (Math.random() - 0.5) * 50
        const close = open + (Math.random() - 0.5) * 80
        const high = Math.max(open, close) + Math.random() * 30
        const low = Math.min(open, close) - Math.random() * 30
        
        mockData.push({
          date: date.toISOString().split('T')[0],
          open: parseFloat(open.toFixed(2)),
          close: parseFloat(close.toFixed(2)),
          high: parseFloat(high.toFixed(2)),
          low: parseFloat(low.toFixed(2)),
          volume: Math.random() * 100000000,
          amount: Math.random() * 10000000000,
          changePercent: parseFloat(((close - open) / open * 100).toFixed(2))
        })
      }
      klineData.value = mockData
      updateKLineChart()
      ElMessage.info('K线数据暂不可用，显示模拟数据（非交易日）')
      return
    }

    if (data.data && data.data.klines) {
      klineData.value = data.data.klines.map((item: string) => {
        const parts = item.split(',')
        return {
          date: parts[0],
          open: parseFloat(parts[1]),
          close: parseFloat(parts[2]),
          high: parseFloat(parts[3]),
          low: parseFloat(parts[4]),
          volume: parseFloat(parts[5]),
          amount: parseFloat(parts[6]),
          changePercent: parseFloat(parts[8])
        }
      })
      console.log('✅ K线数据解析成功，共', klineData.value.length, '条')
      updateKLineChart()
    }
  } catch (error) {
    console.error('❌ 获取K线数据失败:', error)
    ElMessage.error('K线数据加载失败')
  } finally {
    klineLoading.value = false
  }
}

// 3.2 更新K线图表
const updateKLineChart = () => {
  console.log('🎨 开始更新K线图...', { hasData: !!klineData.value, dataLength: klineData.value?.length })
  
  if (!klineData.value || klineData.value.length === 0) {
    console.warn('⚠️ K线数据为空，无法绘制图表')
    klineOption.value = {
      title: { 
        text: '暂无数据',
        left: 'center',
        top: 'center',
        textStyle: { fontSize: 14, color: '#999' }
      },
      xAxis: { type: 'category', data: [] },
      yAxis: { type: 'value' },
      series: []
    }
    return
  }

  const dates = klineData.value.map(item => item.date)
  // ECharts K线数据格式: [开盘, 收盘, 最低, 最高]
  const values = klineData.value.map(item => [item.open, item.close, item.low, item.high])
  
  const indexName = indexOptions.find(opt => opt.value === selectedIndex.value)?.label || '指数'
  
  console.log('📊 K线图数据:', { 
    dates: dates.length, 
    values: values.length, 
    sampleDate: dates[0],
    sampleValue: values[0],
    indexName 
  })
  
  klineOption.value = {
    title: {
      text: `${indexName} 日K线`,
      left: 'center',
      textStyle: {
        fontSize: 14,
        fontWeight: 600
      }
    },
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross'
      },
      formatter: (params: any) => {
        if (!params || !params[0]) return ''
        const data = params[0]
        const value = data.value
        if (!value || value.length < 4) return data.name
        return `
          <strong>${data.name}</strong><br/>
          开盘: ${value[0]?.toFixed(2)}<br/>
          收盘: ${value[1]?.toFixed(2)}<br/>
          最低: ${value[2]?.toFixed(2)}<br/>
          最高: ${value[3]?.toFixed(2)}
        `
      }
    },
    grid: {
      left: '10%',
      right: '10%',
      bottom: '25%',
      top: '15%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: dates,
      boundaryGap: false,
      axisLine: { onZero: false },
      splitLine: { show: false },
      axisLabel: {
        formatter: (value: string) => {
          return value.split(' ')[0].substring(5) // 显示 MM-DD
        }
      }
    },
    yAxis: {
      type: 'value',
      splitArea: {
        show: true
      }
    },
    dataZoom: [
      {
        type: 'inside',
        start: 50,
        end: 100
      },
      {
        show: true,
        type: 'slider',
        bottom: '2%',
        start: 50,
        end: 100,
        height: 25
      }
    ],
    series: [
      {
        name: indexName,
        type: 'candlestick',
        data: values,
        itemStyle: {
          color: '#ec0000',
          color0: '#00da3c',
          borderColor: '#ec0000',
          borderColor0: '#00da3c'
        }
      }
    ]
  }
}

// 3.3 切换指数
const onIndexChange = () => {
  getKLineData()
  getMoneyFlowData()
}

// ============================================
// 4. 资金流向模块
// ============================================

// 4.1 获取资金流向数据
const getMoneyFlowData = async () => {
  console.log('🔍 [资金流向] 开始获取数据...')
  try {
    moneyFlowLoading.value = true
    
    const secid = selectedIndex.value === '000001.SH' 
      ? '1.000001' 
      : selectedIndex.value === '399001.SZ' 
        ? '0.399001' 
        : selectedIndex.value === '399006.SZ'
          ? '0.399006'
          : '1.000300'

    console.log('📍 [资金流向] 当前指数:', selectedIndex.value, '→ secid:', secid)

    const url = 'https://push2.eastmoney.com/api/qt/stock/fflow/kline/get?' + new URLSearchParams({
      lmt: '120',
      klt: '101',
      secid: secid,
      fields1: 'f1,f2,f3,f7',
      fields2: 'f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61,f62,f63,f64,f65',
      ut: 'b2884a393a59ad64002292a3e90d46a5',
      cb: 'jsonp'
    })
    
    console.log('🌐 [资金流向] 请求URL:', url)
    
    const response = await fetch(url)
    console.log('📡 [资金流向] 响应状态:', response.status, response.statusText)
    
    const text = await response.text()
    console.log('📄 [资金流向] 响应长度:', text.length, '字符')
    
    // 处理 JSONP 响应
    const jsonMatch = text.match(/\((.*)\)/)
    if (!jsonMatch) {
      console.error('❌ [资金流向] JSONP解析失败，响应内容:', text.substring(0, 200))
      throw new Error('解析响应失败')
    }

    const data = JSON.parse(jsonMatch[1])
    console.log('✅ [资金流向] JSON解析成功，data.data存在?', !!data.data, 'klines存在?', !!data.data?.klines)
    
    if (data.data && data.data.klines) {
      console.log('📊 [资金流向] klines数组长度:', data.data.klines.length)
      console.log('📋 [资金流向] 原始数据示例:', data.data.klines[0])
      
      moneyFlowData.value = data.data.klines.map((item: string) => {
        const parts = item.split(',')
        return {
          date: parts[0],
          mainNetInflow: parseFloat(parts[1]) / 100000000, // 转换为亿元
          mainNetInflowRate: parseFloat(parts[6]),
          largeNetInflow: parseFloat(parts[4]) / 100000000,
          mediumNetInflow: parseFloat(parts[3]) / 100000000,
          smallNetInflow: parseFloat(parts[2]) / 100000000,
          closePrice: parseFloat(parts[11]),
          changePercent: parseFloat(parts[12])
        }
      })
      console.log('✅ [资金流向] 数据解析成功，共', moneyFlowData.value.length, '条')
      console.log('📊 [资金流向] 转换后示例:', moneyFlowData.value[0])
      updateMoneyFlowChart()
    } else {
      console.warn('⚠️ [资金流向] API返回数据结构异常')
      console.log('📄 [资金流向] 完整响应:', JSON.stringify(data, null, 2))
    }
  } catch (error) {
    console.error('❌ [资金流向] 获取失败:', error)
    console.error('❌ [资金流向] 错误详情:', error instanceof Error ? error.message : error)
    ElMessage.error('资金流向数据加载失败')
  } finally {
    moneyFlowLoading.value = false
    console.log('🏁 [资金流向] 数据获取流程结束')
  }
}

// 4.2 更新资金流向图表
const updateMoneyFlowChart = () => {
  console.log('🎨 开始更新资金流向图...', { hasData: !!moneyFlowData.value, dataLength: moneyFlowData.value?.length })
  
  if (!moneyFlowData.value || moneyFlowData.value.length === 0) {
    console.warn('⚠️ 资金流向数据为空，无法绘制图表')
    moneyFlowOption.value = {
      title: { 
        text: '暂无数据',
        left: 'center',
        top: 'center',
        textStyle: { fontSize: 14, color: '#999' }
      },
      xAxis: { type: 'category', data: [] },
      yAxis: { type: 'value' },
      series: []
    }
    return
  }

  const dates = moneyFlowData.value.map(item => item.date)
  const mainFlow = moneyFlowData.value.map(item => item.mainNetInflow)
  const changePercent = moneyFlowData.value.map(item => item.changePercent)
  
  const indexName = indexOptions.find(opt => opt.value === selectedIndex.value)?.label || '指数'
  
  console.log('📊 资金流向图数据:', { 
    dates: dates.length, 
    mainFlow: mainFlow.length, 
    sampleDate: dates[0],
    sampleMainFlow: mainFlow[0],
    sampleChangePercent: changePercent[0],
    indexName
  })
  
  moneyFlowOption.value = {
    title: {
      text: `${indexName} 主力资金流向`,
      left: 'center',
      textStyle: {
        fontSize: 14,
        fontWeight: 600
      }
    },
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross'
      }
    },
    legend: {
      data: ['主力净流入', '涨跌幅'],
      top: 35
    },
    grid: {
      left: '10%',
      right: '12%',
      bottom: '15%',
      top: '22%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: dates,
      axisLabel: {
        formatter: (value: string) => {
          return value.split(' ')[0].substring(5)
        }
      }
    },
    yAxis: [
      {
        type: 'value',
        name: '资金(亿元)',
        position: 'left',
        axisLabel: {
          formatter: '{value}'
        }
      },
      {
        type: 'value',
        name: '涨跌幅(%)',
        position: 'right',
        axisLabel: {
          formatter: '{value}%'
        }
      }
    ],
    series: [
      {
        name: '主力净流入',
        type: 'bar',
        data: mainFlow,
        itemStyle: {
          color: (params: any) => {
            return params.value >= 0 ? '#ec0000' : '#00da3c'
          }
        }
      },
      {
        name: '涨跌幅',
        type: 'line',
        yAxisIndex: 1,
        data: changePercent,
        smooth: true,
        lineStyle: {
          width: 2
        },
        itemStyle: {
          color: '#409eff'
        }
      }
    ]
  }
}

// ============================================
// 5. 热门股票模块
// ============================================

// 5.2 获取热门股票（涨幅榜前5）
const getHotStocks = async () => {
  console.log('🔍 [热门股票] 开始获取数据...')
  try {
    const url = 'https://push2.eastmoney.com/api/qt/clist/get?' + new URLSearchParams({
      pn: '1',
      pz: '5',
      po: '1',
      np: '1',
      ut: 'bd1d9ddb04089700cf9c27f6f7426281',
      fltt: '2',
      invt: '2',
      fid: 'f3',
      fs: 'm:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23',
      fields: 'f12,f14,f2,f3,f4,f5,f6,f15,f16,f17,f18,f8'
    })

    console.log('🌐 [热门股票] 请求URL:', url)
    const res = await fetch(url)
    console.log('📡 [热门股票] 响应状态:', res.status, res.statusText)
    
    const data = await res.json()
    console.log('✅ [热门股票] JSON解析成功')
    console.log('📊 [热门股票] API返回结构:', { 
      hasData: !!data.data, 
      hasDiff: !!data.data?.diff,
      diffLength: data.data?.diff?.length || 0
    })

    if (data.data && data.data.diff && data.data.diff.length > 0) {
      console.log('📋 [热门股票] 原始数据示例:', data.data.diff[0])
      
      hotStocks.value = data.data.diff.map((item: any, index: number) => {
        const stock = {
          code: item.f12,
          name: item.f14,
          price: item.f2 ? (item.f2 / 1).toFixed(2) : '-',
          change: item.f4 ? (item.f4 / 1).toFixed(2) : '0',
          changePercent: item.f3 ? (item.f3 / 1).toFixed(2) : '0',
          volume: item.f5 || 0,
          amount: item.f6 || 0,
          high: item.f15 ? (item.f15 / 1).toFixed(2) : '-',
          low: item.f16 ? (item.f16 / 1).toFixed(2) : '-',
          open: item.f17 ? (item.f17 / 1).toFixed(2) : '-',
          preClose: item.f18 ? (item.f18 / 1).toFixed(2) : '-',
          turnover: item.f8 ? (item.f8 / 1).toFixed(2) : '0'
        }
        if (index === 0) {
          console.log('📊 [热门股票] 转换后示例:', stock)
        }
        return stock
      })
      console.log('✅ [热门股票] 数据解析成功，共', hotStocks.value.length, '条')
    } else {
      console.warn('⚠️ [热门股票] API返回数据为空或结构异常')
      console.log('📄 [热门股票] 完整响应:', JSON.stringify(data, null, 2))
      hotStocks.value = []
    }
  } catch (error) {
    console.error('❌ [热门股票] 获取失败:', error)
    console.error('❌ [热门股票] 错误详情:', error instanceof Error ? error.message : error)
  } finally {
    console.log('🏁 [热门股票] 数据获取流程结束')
  }
}

// ============================================
// 6. 龙虎榜模块（使用涨幅榜TOP5数据）
// ============================================

// 6.1 获取龙虎榜前5（实际为涨幅榜TOP5）
const getTopStocks = async () => {
  console.log('🔍 [龙虎榜] 开始获取数据...')
  try {
    // 使用涨幅榜TOP5数据（市场最活跃股票）
    const url = 'https://push2.eastmoney.com/api/qt/clist/get?' + new URLSearchParams({
      pn: '1',
      pz: '5',
      po: '1',
      np: '1',
      ut: 'bd1d9ddb04089700cf9c27f6f7426281',
      fltt: '2',
      invt: '2',
      fid: 'f3',  // 按涨跌幅排序
      fs: 'm:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23',  // 沪深A股
      fields: 'f12,f14,f2,f3,f62,f5,f6'
    })

    console.log('🌐 [龙虎榜] 请求URL:', url)
    
    const res = await fetch(url)
    console.log('📡 [龙虎榜] 响应状态:', res.status, res.statusText)
    
    if (!res.ok) {
      throw new Error(`HTTP错误: ${res.status}`)
    }

    const data = await res.json()
    console.log('✅ [龙虎榜] JSON解析成功')
    console.log('📊 [龙虎榜] API返回结构:', { 
      rc: data.rc,
      hasData: !!data.data, 
      hasDiff: !!data.data?.diff,
      diffLength: data.data?.diff?.length || 0,
      total: data.data?.total || 0
    })

    if (data.data && data.data.diff && data.data.diff.length > 0) {
      console.log('📋 [龙虎榜] 原始数据示例:', data.data.diff[0])
      
      // 获取当前日期作为交易日期
      const today = new Date()
      const day = today.getDay()
      if (day === 0) {
        today.setDate(today.getDate() - 2)  // 周日显示周五
      } else if (day === 6) {
        today.setDate(today.getDate() - 1)  // 周六显示周五
      }
      lastTradeDate.value = `${today.getMonth() + 1}月${today.getDate()}日`
      
      topStocks.value = data.data.diff.map((item: any, index: number) => {
        const stock = {
          code: item.f12,
          name: item.f14,
          date: today.toISOString().split('T')[0],
          price: item.f2 ? (item.f2 / 1).toFixed(2) : '-',
          changePercent: item.f3 ? (item.f3 / 1).toFixed(2) : '0',
          netAmount: item.f62 ? (item.f62 / 100000000).toFixed(2) : '0', // 主力净流入，转换为亿元
          reason: '涨幅居前'
        }
        if (index === 0) {
          console.log('📊 [龙虎榜] 转换后示例:', stock)
        }
        return stock
      })
      
      console.log('✅ [龙虎榜] 数据解析成功，共', topStocks.value.length, '条')
      console.log('📊 [龙虎榜] 交易日期:', lastTradeDate.value)
    } else {
      console.warn('⚠️ [龙虎榜] API返回数据为空或结构异常')
      console.log('📄 [龙虎榜] 完整响应:', JSON.stringify(data, null, 2))
      topStocks.value = []
      lastTradeDate.value = '无数据'
    }
  } catch (error: any) {
    console.error('❌ [龙虎榜] 获取失败:', error)
    console.error('❌ [龙虎榜] 错误详情:', error.message || error)
    console.error('❌ [龙虎榜] 堆栈:', error.stack)
    topStocks.value = []
    lastTradeDate.value = '获取失败'
  } finally {
    console.log('🏁 [龙虎榜] 数据获取流程结束，当前状态:', { 
      hasData: topStocks.value.length > 0,
      dataCount: topStocks.value.length,
      lastTradeDate: lastTradeDate.value
    })
  }
}

// ============================================
// 7. 工具函数
// ============================================

// 7.1 刷新所有数据
const refreshAllData = async () => {
  indexLoading.value = true
  stockLoading.value = true
  futuresLoading.value = true
  goldLoading.value = true
  
  try {
    await Promise.all([
      getMarketIndices(),
      getFuturesData(),
      getGoldData(),
      getKLineData(),
      getMoneyFlowData(),
      getHotStocks(),
      getTopStocks()
    ])
    ElMessage.success('数据刷新成功')
  } catch (error) {
    ElMessage.error('数据刷新失败')
  } finally {
    indexLoading.value = false
    stockLoading.value = false
  }
}

// 7.2 仅刷新股票数据
const refreshStocks = async () => {
  stockLoading.value = true
  try {
    await Promise.all([
      getHotStocks(),
      getTopStocks()
    ])
    ElMessage.success('股票数据刷新成功')
  } catch (error) {
    ElMessage.error('股票数据刷新失败')
  } finally {
    stockLoading.value = false
  }
}

// ============================================
// 8. 生命周期
// ============================================

// 组件挂载时加载所有数据
onMounted(() => {
  refreshAllData()
})
</script>

<template>
  <!-- ============================================ -->
  <!-- 金融插件模板 -->
  <!-- ============================================ -->
  <div class="finance-plugin">
    <!-- 顶部操作栏 -->
    <div class="toolbar">
      <el-button
        type="primary"
        :icon="Refresh"
        @click="refreshAllData"
        :loading="indexLoading || stockLoading"
        size="small"
      >
        刷新全部数据
      </el-button>
    </div>

    <!-- 非交易日提示 -->
    <el-alert
      v-if="showNonTradingDayTip"
      title="当前为非交易日"
      type="info"
      :closable="false"
      show-icon
      class="trading-day-tip"
    >
      <template #default>
        今天是周末，展示的是{{ tradingDayDesc }}（{{ lastTradeDate || '10月31日' }}）的数据
      </template>
    </el-alert>

    <!-- 大盘指数和黄金行情 -->
    <el-row :gutter="20" class="index-gold-row">
      <!-- 大盘指数 -->
      <el-col 
        v-for="index in marketIndices" 
        :key="index.code"
        :xs="12" 
        :sm="8" 
        :md="4"
      >
        <el-card shadow="hover" class="index-card" v-loading="indexLoading">
          <div class="index-content">
            <div class="index-name">{{ index.name }}</div>
            <div class="index-price">{{ index.price.toFixed(2) }}</div>
            <div 
              :class="['index-change', index.change >= 0 ? 'positive' : 'negative']"
            >
              <span>{{ index.change >= 0 ? '+' : '' }}{{ index.change.toFixed(2) }}</span>
              <span class="percent">{{ index.change >= 0 ? '+' : '' }}{{ index.changePercent.toFixed(2) }}%</span>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <!-- 黄金行情 -->
      <el-col 
        v-for="gold in goldData" 
        :key="gold.code"
        :xs="12" 
        :sm="8" 
        :md="4"
      >
        <el-card shadow="hover" class="gold-card" v-loading="goldLoading">
          <div class="gold-content">
            <div class="gold-name">{{ gold.name }}</div>
            <div class="gold-price">{{ gold.price.toFixed(2) }}</div>
            <div 
              :class="['gold-change', gold.change >= 0 ? 'positive' : 'negative']"
            >
              <span>{{ gold.change >= 0 ? '+' : '' }}{{ gold.change.toFixed(2) }}</span>
              <span class="percent">{{ gold.change >= 0 ? '+' : '' }}{{ gold.changePercent.toFixed(2) }}%</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- K线图和资金流向图 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :xs="24" :sm="24" :md="24" :lg="12">
        <el-card shadow="hover" class="chart-card">
          <template #header>
            <div class="chart-card-header">
              <span class="chart-title">📈 K线图</span>
              <el-select 
                v-model="selectedIndex" 
                @change="onIndexChange"
                size="small"
                style="width: 120px"
              >
                <el-option
                  v-for="option in indexOptions"
                  :key="option.value"
                  :label="option.label"
                  :value="option.value"
                />
              </el-select>
            </div>
          </template>
          <div class="chart-container" v-loading="klineLoading">
            <v-chart 
              :option="klineOption" 
              class="chart-instance"
              :autoresize="true"
            />
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="24" :md="24" :lg="12">
        <el-card shadow="hover" class="chart-card">
          <template #header>
            <div class="chart-card-header">
              <span class="chart-title">💰 资金流向</span>
            </div>
          </template>
          <div class="chart-container" v-loading="moneyFlowLoading">
            <v-chart 
              :option="moneyFlowOption" 
              class="chart-instance"
              :autoresize="true"
            />
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 期货涨幅榜 TOP5 -->
    <el-row :gutter="20" class="futures-top-row">
      <el-col :xs="24" :sm="24" :md="24">
        <el-card shadow="hover" class="stock-card">
          <template #header>
            <div class="stock-card-header">
              <span class="stock-title">📈 期货涨幅榜 TOP5</span>
              <el-button
                text
                :icon="TrendCharts"
                @click="getFuturesData"
                :loading="futuresLoading"
                size="small"
              >
                刷新
              </el-button>
            </div>
          </template>

          <el-table 
            :data="futuresData" 
            stripe
            :show-header="true"
            size="small"
            v-loading="futuresLoading"
          >
            <el-table-column prop="name" label="合约名称" min-width="150">
              <template #default="{ row }">
                <div class="stock-name-cell">
                  <div class="stock-name">{{ row.name }}</div>
                  <div class="stock-code">{{ row.code }}</div>
                </div>
              </template>
            </el-table-column>
            
            <el-table-column prop="price" label="最新价" align="right" width="100">
              <template #default="{ row }">
                <span class="stock-price">{{ row.price.toFixed(2) }}</span>
              </template>
            </el-table-column>
            
            <el-table-column prop="changePercent" label="涨跌幅" align="right" width="100">
              <template #default="{ row }">
                <span 
                  :class="['stock-change', row.changePercent >= 0 ? 'positive' : 'negative']"
                >
                  {{ row.changePercent >= 0 ? '+' : '' }}{{ row.changePercent.toFixed(2) }}%
                </span>
              </template>
            </el-table-column>

            <el-table-column prop="change" label="涨跌额" align="right" width="100">
              <template #default="{ row }">
                <span 
                  :class="['stock-change', row.change >= 0 ? 'positive' : 'negative']"
                >
                  {{ row.change >= 0 ? '+' : '' }}{{ row.change.toFixed(2) }}
                </span>
              </template>
            </el-table-column>

            <el-table-column prop="volume" label="成交量" align="right" width="100">
              <template #default="{ row }">
                <span class="stock-volume">{{ (row.volume / 10000).toFixed(2) }}万手</span>
              </template>
            </el-table-column>
          </el-table>

          <el-empty 
            v-if="!futuresLoading && futuresData.length === 0"
            description="暂无数据"
            :image-size="60"
          />
        </el-card>
      </el-col>
    </el-row>

    <!-- 热门股票和龙虎榜 -->
    <el-row :gutter="20" class="stock-row">
      <!-- 热门股票 -->
      <el-col :xs="24" :sm="24" :md="12">
        <el-card shadow="hover" class="stock-card">
          <template #header>
            <div class="stock-card-header">
              <span class="stock-title">🔥 热门股票 TOP5</span>
              <el-button
                text
                :icon="TrendCharts"
                @click="refreshStocks"
                :loading="stockLoading"
                size="small"
              >
                刷新
              </el-button>
            </div>
          </template>

          <el-table 
            :data="hotStocks" 
            stripe
            :show-header="true"
            size="small"
            v-loading="stockLoading"
          >
            <el-table-column prop="name" label="股票" width="100">
              <template #default="{ row }">
                <div class="stock-name-cell">
                  <div class="stock-name">{{ row.name }}</div>
                  <div class="stock-code">{{ row.code }}</div>
                </div>
              </template>
            </el-table-column>
            
            <el-table-column prop="price" label="最新价" align="right" width="80">
              <template #default="{ row }">
                <span class="stock-price">{{ row.price }}</span>
              </template>
            </el-table-column>
            
            <el-table-column prop="changePercent" label="涨跌幅" align="right" width="90">
              <template #default="{ row }">
                <span 
                  :class="['stock-change', parseFloat(row.changePercent) >= 0 ? 'positive' : 'negative']"
                >
                  {{ parseFloat(row.changePercent) >= 0 ? '+' : '' }}{{ row.changePercent }}%
                </span>
              </template>
            </el-table-column>

            <el-table-column prop="turnover" label="换手率" align="right" width="80">
              <template #default="{ row }">
                <span class="stock-turnover">{{ row.turnover }}%</span>
              </template>
            </el-table-column>
          </el-table>

          <el-empty 
            v-if="!stockLoading && hotStocks.length === 0"
            description="暂无数据"
            :image-size="60"
          />
        </el-card>
      </el-col>

      <!-- 龙虎榜 -->
      <el-col :xs="24" :sm="24" :md="12">
        <el-card shadow="hover" class="stock-card">
          <template #header>
            <div class="stock-card-header">
              <span class="stock-title">
                📊 龙虎榜 TOP5
                <span v-if="lastTradeDate" class="trade-date">({{ lastTradeDate }})</span>
              </span>
              <div class="header-actions">
                <el-tooltip content="刷新龙虎榜数据" placement="top">
                  <el-button 
                    :icon="Refresh" 
                    circle 
                    size="small"
                    :loading="stockLoading"
                    @click="getTopStocks"
                  />
                </el-tooltip>
                <el-tooltip content="当日涨幅最大的股票（市场热点）" placement="top">
                  <el-icon><InfoFilled /></el-icon>
                </el-tooltip>
              </div>
            </div>
          </template>

          <el-table 
            :data="topStocks" 
            stripe
            :show-header="true"
            size="small"
            v-loading="stockLoading"
          >
            <el-table-column prop="name" label="股票" width="100">
              <template #default="{ row }">
                <div class="stock-name-cell">
                  <div class="stock-name">{{ row.name }}</div>
                  <div class="stock-code">{{ row.code }}</div>
                </div>
              </template>
            </el-table-column>
            
            <el-table-column prop="price" label="最新价" align="right" width="80">
              <template #default="{ row }">
                <span class="stock-price">{{ row.price }}</span>
              </template>
            </el-table-column>
            
            <el-table-column prop="changePercent" label="涨跌幅" align="right" width="90">
              <template #default="{ row }">
                <span 
                  :class="['stock-change', parseFloat(row.changePercent) >= 0 ? 'positive' : 'negative']"
                >
                  {{ parseFloat(row.changePercent) >= 0 ? '+' : '' }}{{ row.changePercent }}%
                </span>
              </template>
            </el-table-column>

            <el-table-column prop="netAmount" label="净流入" align="right" width="80">
              <template #default="{ row }">
                <span class="stock-net-amount">{{ row.netAmount }}亿</span>
              </template>
            </el-table-column>
          </el-table>

          <el-empty 
            v-if="!stockLoading && topStocks.length === 0"
            description="暂无数据"
            :image-size="60"
          />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped lang="scss">
.finance-plugin {
  padding: 20px;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

// ============================================
// 工具栏
// ============================================
.toolbar {
  margin-bottom: 20px;
  display: flex;
  justify-content: flex-end;
}

// ============================================
// 非交易日提示
// ============================================
.trading-day-tip {
  margin-bottom: 20px;
  border-radius: 8px;
  
  :deep(.el-alert__title) {
    font-size: 14px;
    font-weight: 600;
  }
  
  :deep(.el-alert__description) {
    font-size: 13px;
    margin-top: 5px;
  }
}

// ============================================
// 大盘指数和黄金行情卡片
// ============================================
.index-gold-row {
  margin-bottom: 20px;
}

.index-card {
  border-radius: 12px;
  overflow: hidden;
  background: #fff;
  transition: all 0.3s;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }

  :deep(.el-card__body) {
    padding: 20px;
  }
}

.index-content {
  text-align: center;
}

.index-name {
  font-size: 14px;
  color: #909399;
  margin-bottom: 8px;
}

.index-price {
  font-size: 24px;
  font-weight: 700;
  color: #303133;
  margin-bottom: 6px;
}

.index-change {
  font-size: 14px;
  font-weight: 600;
  
  &.positive {
    color: #f56c6c;
  }
  
  &.negative {
    color: #67c23a;
  }

  .percent {
    margin-left: 8px;
  }
}

// ============================================
// 黄金卡片（与大盘指数样式一致）
// ============================================
.gold-card {
  border-radius: 12px;
  overflow: hidden;
  background: #fff;
  transition: all 0.3s;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }

  :deep(.el-card__body) {
    padding: 20px;
  }
}

.gold-content {
  text-align: center;
}

.gold-name {
  font-size: 14px;
  color: #909399;
  margin-bottom: 8px;
}

.gold-price {
  font-size: 24px;
  font-weight: 700;
  color: #303133;
  margin-bottom: 6px;
}

.gold-change {
  font-size: 14px;
  font-weight: 600;
  
  &.positive {
    color: #f56c6c;
  }
  
  &.negative {
    color: #67c23a;
  }

  .percent {
    margin-left: 8px;
  }
}

// ============================================
// 期货涨幅榜
// ============================================
.futures-top-row {
  margin-bottom: 20px;
}

// ============================================
// 图表卡片
// ============================================
.chart-row {
  margin-bottom: 20px;
}

.chart-card {
  border-radius: 12px;
  overflow: hidden;

  :deep(.el-card__header) {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border: none;
    padding: 16px 20px;
  }

  :deep(.el-card__body) {
    padding: 20px;
  }
}

.chart-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chart-title {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}

.chart-container {
  width: 100%;
  height: 450px;
  padding: 10px;
  box-sizing: border-box;
  
  .chart-instance {
    width: 100% !important;
    height: 100% !important;
  }
}

// ============================================
// 股票卡片样式
// ============================================
.stock-row {
  margin-bottom: 20px;
}

.stock-card {
  border-radius: 12px;
  overflow: hidden;

  :deep(.el-card__header) {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border: none;
    padding: 16px 20px;
  }

  :deep(.el-card__body) {
    padding: 0;
  }
}

.stock-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stock-title {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}

.trade-date {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.8);
  margin-left: 8px;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  
  .el-button {
    background-color: rgba(255, 255, 255, 0.2);
    border-color: transparent;
    color: #fff;
    
    &:hover {
      background-color: rgba(255, 255, 255, 0.3);
      border-color: transparent;
    }
  }
  
  .el-icon {
    cursor: pointer;
    color: rgba(255, 255, 255, 0.8);
    font-size: 16px;
    
    &:hover {
      color: #fff;
    }
  }
}

// 表格单元格样式
.stock-name-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stock-name {
  font-size: 14px;
  font-weight: 500;
  color: #303133;
}

.stock-code {
  font-size: 11px;
  color: #909399;
}

.stock-price {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.stock-change {
  font-size: 14px;
  font-weight: 600;
  
  &.positive {
    color: #f56c6c;
  }
  
  &.negative {
    color: #67c23a;
  }
}

.stock-turnover,
.stock-net-amount {
  font-size: 13px;
  color: #606266;
}

// ============================================
// 响应式布局
// ============================================
@media (max-width: 768px) {
  .finance-plugin {
    padding: 10px;
  }

  .index-row,
  .chart-row,
  .stock-row {
    margin-bottom: 15px;
  }

  .index-card,
  .chart-card,
  .stock-card {
    margin-bottom: 15px;
  }

  :deep(.el-card__header) {
    padding: 12px 15px;
  }

  .chart-container {
    height: 350px;
    padding: 5px;
  }

  .chart-title,
  .stock-title {
    font-size: 14px;
  }

  .index-price {
    font-size: 20px;
  }
}
</style>
