# 东方财富 API 开发资源说明

## 📚 API 概述

东方财富（East Money）提供了丰富的金融数据API接口，无需注册即可使用，适合个人项目和学习使用。

## 🔗 常用API接口

### 1. 大盘指数行情

#### 沪深指数实时数据
```
URL: https://push2.eastmoney.com/api/qt/stock/get
方法: GET
参数:
  - secid: 证券代码
    * 1.000001 (上证指数)
    * 0.399001 (深证成指)
    * 0.399006 (创业板指)
    * 1.000300 (沪深300)
  - fields: f43,f44,f45,f46,f47,f48,f49,f50,f51,f52,f57,f58,f60,f107,f152,f153,f169,f170,f168
  - ut: bd1d9ddb04089700cf9c27f6f7426281
  
返回字段说明:
  f43: 最新价
  f44: 最高价
  f45: 最低价
  f46: 今开
  f47: 成交量(手)
  f48: 成交额(元)
  f49: 外盘
  f50: 内盘
  f51: 最新价
  f52: 涨跌额
  f57: 代码
  f58: 名称
  f60: 昨收
  f107: 流通市值
  f152: 市盈率
  f153: 换手率
  f168: 涨跌幅
  f169: 成交量
  f170: 振幅

示例:
https://push2.eastmoney.com/api/qt/stock/get?secid=1.000001&fields=f43,f44,f45,f46,f60,f168,f169,f170
```

#### 多指数批量查询
```
URL: https://push2.eastmoney.com/api/qt/ulist.np/get
方法: GET
参数:
  - secids: 1.000001,0.399001,0.399006,1.000300 (逗号分隔)
  - fields: f2,f3,f4,f5,f6,f12,f13,f14
  
字段说明:
  f2: 最新价
  f3: 涨跌幅
  f4: 涨跌额
  f5: 成交量(手)
  f6: 成交额(元)
  f12: 代码
  f13: 市场编号
  f14: 名称
```

### 2. 期货行情

#### 期货实时数据
```
URL: https://push2.eastmoney.com/api/qt/stock/get
方法: GET
参数:
  - secid: 期货代码
    * 113.IF0 (沪深300期货主力)
    * 113.IH0 (上证50期货主力)
    * 113.IC0 (中证500期货主力)
    * 113.T0 (10年国债期货主力)
  - fields: f43,f44,f45,f46,f47,f48,f51,f52,f57,f58,f60,f169,f170,f168
  - ut: bd1d9ddb04089700cf9c27f6f7426281
  
返回字段说明:
  f43: 最新价
  f44: 最高价
  f45: 最低价
  f46: 今开
  f47: 成交量(手)
  f48: 成交额(元)
  f51: 最新价
  f52: 涨跌额
  f57: 代码
  f58: 名称
  f60: 昨收
  f168: 涨跌幅
  f169: 涨跌额
  f170: 涨跌幅

示例:
https://push2.eastmoney.com/api/qt/stock/get?secid=113.IF0&fields=f43,f44,f45,f46,f47,f48,f51,f52,f57,f58,f60,f169,f170,f168
```

### 3. 黄金行情

#### 黄金实时数据
```
URL: https://push2.eastmoney.com/api/qt/stock/get
方法: GET
参数:
  - secid: 黄金代码
    * 113.au9999 (上海黄金现货)
    * 113.aum (黄金期货主力合约)
  - fields: f43,f44,f45,f46,f47,f48,f51,f52,f57,f58,f60,f169,f170,f168
  - ut: bd1d9ddb04089700cf9c27f6f7426281
  
返回字段说明: (同期货)

示例:
https://push2.eastmoney.com/api/qt/stock/get?secid=113.au9999&fields=f43,f44,f45,f46,f47,f48,f51,f52,f57,f58,f60,f169,f170,f168
```

### 4. K线数据

#### 分时K线
```
URL: https://push2his.eastmoney.com/api/qt/stock/trends2/get
方法: GET
参数:
  - secid: 证券代码 (如 1.000001)
  - fields1: f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13
  - fields2: f51,f52,f53,f54,f55,f56,f57,f58
  - iscr: 0
  
返回: 当日分时数据
```

#### 日K线/周K线/月K线
```
URL: https://push2his.eastmoney.com/api/qt/stock/kline/get
方法: GET
参数:
  - secid: 证券代码 (如 1.000001)
  - klt: K线类型
    * 1: 1分钟
    * 5: 5分钟
    * 15: 15分钟
    * 30: 30分钟
    * 60: 60分钟
    * 101: 日K
    * 102: 周K
    * 103: 月K
  - fqt: 复权类型
    * 0: 不复权
    * 1: 前复权
    * 2: 后复权
  - lmt: 数据条数 (最多500)
  - end: 结束日期 (yyyyMMdd，如 20231201)
  - fields1: f1,f2,f3,f4,f5,f6
  - fields2: f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61
  - ut: bd1d9ddb04089700cf9c27f6f7426281
  
返回数据格式: "时间,开,收,高,低,成交量,成交额,振幅,涨跌幅,涨跌额,换手率"

示例:
https://push2his.eastmoney.com/api/qt/stock/kline/get?secid=1.000001&klt=101&fqt=0&lmt=120&fields1=f1,f2,f3,f4,f5,f6&fields2=f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61
```

### 5. 资金流向

#### 个股资金流向
```
URL: https://push2.eastmoney.com/api/qt/stock/fflow/kline/get
方法: GET
参数:
  - secid: 证券代码
  - klt: 0 (日线)
  - lmt: 数据条数
  - fields1: f1,f2,f3,f7
  - fields2: f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61,f62,f63,f64,f65
  
字段说明:
  f51: 日期
  f52: 主力净流入
  f53: 小单净流入
  f54: 中单净流入
  f55: 大单净流入
  f56: 超大单净流入
  f57: 主力净流入占比
  f58: 小单净流入占比
  f59: 中单净流入占比
  f60: 大单净流入占比
  f61: 超大单净流入占比
  f62: 收盘价
  f63: 涨跌幅

示例:
https://push2.eastmoney.com/api/qt/stock/fflow/kline/get?secid=1.000001&klt=0&lmt=30&fields1=f1,f2,f3,f7&fields2=f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61,f62,f63
```

#### 沪深两市资金流向
```
URL: https://push2.eastmoney.com/api/qt/kamt.rtmin/get
方法: GET
参数:
  - fields1: f1,f2,f3,f4
  - fields2: f51,f52,f53,f54,f55,f56
  
返回: 实时资金流向（主力、小单、中单、大单、超大单）
```

#### 板块资金流向
```
URL: https://push2.eastmoney.com/api/qt/clist/get
方法: GET
参数:
  - pn: 页码
  - pz: 每页数量
  - po: 1
  - np: 1
  - fltt: 2
  - invt: 2
  - fid: f62 (按主力净流入排序)
  - fs: b:BK0477 (板块代码)
  - fields: f12,f14,f2,f3,f62,f184,f66,f69,f72,f75,f78,f81,f84,f87,f204,f205,f124
  
字段说明:
  f62: 主力净流入
  f184: 主力净流入占比
  f66: 超大单净流入
  f69: 超大单净流入占比
  f72: 大单净流入
  f75: 大单净流入占比
  f78: 中单净流入
  f81: 中单净流入占比
  f84: 小单净流入
  f87: 小单净流入占比
```

### 6. 涨跌分布

```
URL: https://push2.eastmoney.com/api/qt/stock/zlszt/get
方法: GET
参数:
  - type: up (涨) / down (跌) / flat (平)
  
返回: 涨停/跌停/平盘股票列表
```

### 7. 龙虎榜 (已集成)

```
URL: https://datacenter-web.eastmoney.com/api/data/v1/get
方法: GET
参数:
  - reportName: RPT_DAILYBILLBOARD_LIST
  - columns: SECURITY_CODE,SECURITY_NAME_ABBR,TRADE_DATE,CLOSE_PRICE,CHANGE_RATE,BILLBOARD_NET_AMT
  - pageNumber: 1
  - pageSize: 10
  - sortColumns: BILLBOARD_NET_AMT
  - sortTypes: -1
  - filter: (TRADE_DATE='2023-12-01')
```

## 📊 数据可视化库推荐

### 1. ECharts (推荐)
- 官网: https://echarts.apache.org/
- 安装: `npm install echarts`
- 特点: 功能强大，支持K线图、资金流向图等
- Vue集成: `npm install vue-echarts`

### 2. Chart.js
- 官网: https://www.chartjs.org/
- 安装: `npm install chart.js`
- 特点: 轻量级，易用

### 3. Trading View Lightweight Charts
- GitHub: https://github.com/tradingview/lightweight-charts
- 安装: `npm install lightweight-charts`
- 特点: 专业金融图表，性能优秀

## 🎯 K线图实现方案

### 方案一：使用 ECharts（推荐）

```typescript
import * as echarts from 'echarts'

// K线图配置
const klineOption = {
  title: { text: '上证指数日K线' },
  tooltip: {
    trigger: 'axis',
    axisPointer: { type: 'cross' }
  },
  grid: {
    left: '10%',
    right: '10%',
    bottom: '15%'
  },
  xAxis: {
    type: 'category',
    data: dates, // 日期数组
    scale: true,
    boundaryGap: false,
    axisLine: { onZero: false },
    splitLine: { show: false },
    min: 'dataMin',
    max: 'dataMax'
  },
  yAxis: {
    scale: true,
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
      top: '90%',
      start: 50,
      end: 100
    }
  ],
  series: [
    {
      name: '日K',
      type: 'candlestick',
      data: klineData, // [开盘价, 收盘价, 最低价, 最高价]
      itemStyle: {
        color: '#ec0000', // 阳线颜色
        color0: '#00da3c', // 阴线颜色
        borderColor: '#ec0000',
        borderColor0: '#00da3c'
      }
    }
  ]
}
```

### 方案二：使用 Lightweight Charts

```typescript
import { createChart } from 'lightweight-charts'

const chart = createChart(container, {
  width: 800,
  height: 400,
  layout: {
    backgroundColor: '#ffffff',
    textColor: '#333'
  },
  grid: {
    vertLines: { color: '#e1e1e1' },
    horzLines: { color: '#e1e1e1' }
  }
})

const candlestickSeries = chart.addCandlestickSeries({
  upColor: '#ef5350',
  downColor: '#26a69a',
  borderVisible: false,
  wickUpColor: '#ef5350',
  wickDownColor: '#26a69a'
})

candlestickSeries.setData(klineData)
```

## 💰 资金流向图实现

### ECharts 柱状图 + 折线图组合

```typescript
const moneyFlowOption = {
  title: { text: '主力资金流向' },
  tooltip: {
    trigger: 'axis',
    axisPointer: { type: 'cross' }
  },
  legend: {
    data: ['主力净流入', '涨跌幅']
  },
  xAxis: {
    type: 'category',
    data: dates
  },
  yAxis: [
    {
      type: 'value',
      name: '资金(亿元)',
      position: 'left'
    },
    {
      type: 'value',
      name: '涨跌幅(%)',
      position: 'right'
    }
  ],
  series: [
    {
      name: '主力净流入',
      type: 'bar',
      data: moneyFlowData,
      itemStyle: {
        color: function(params) {
          return params.value >= 0 ? '#ec0000' : '#00da3c'
        }
      }
    },
    {
      name: '涨跌幅',
      type: 'line',
      yAxisIndex: 1,
      data: changePercentData
    }
  ]
}
```

## 🔐 注意事项

### 1. CORS问题
- 东方财富API支持跨域访问
- 如遇问题，可使用后端代理

### 2. 请求频率
- 建议添加防抖/节流
- 缓存数据减少请求
- 避免过于频繁刷新

### 3. 数据格式
- 注意价格单位（部分接口返回值需除以1000）
- 时间戳格式转换
- 成交量单位（手 vs 股）

### 4. 错误处理
- 网络超时处理
- API返回错误处理
- 降级方案（显示缓存数据）

## 📖 实用工具

### 1. API调试工具
- Postman: https://www.postman.com/
- 浏览器开发者工具 Network 面板

### 2. 数据格式化
```typescript
// 价格格式化（元）
const formatPrice = (price: number) => (price / 1000).toFixed(2)

// 成交额格式化（亿元）
const formatAmount = (amount: number) => (amount / 100000000).toFixed(2)

// 百分比格式化
const formatPercent = (percent: number) => (percent / 100).toFixed(2) + '%'
```

### 3. 日期处理
```typescript
// Unix时间戳转日期
const formatDate = (timestamp: number) => {
  const date = new Date(timestamp * 1000)
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

// 日期字符串转时间戳
const parseDate = (dateStr: string) => {
  return new Date(dateStr).getTime() / 1000
}
```

## 🎨 界面设计建议

### 布局方案
```
┌─────────────────────────────────────────────┐
│  大盘指数 (上证、深证、创业板)                │
│  ┌────┬────┬────┬────┐                     │
│  │上证│深证│创业│沪深│                     │
│  │指数│成指│板指│300 │                     │
│  └────┴────┴────┴────┘                     │
├─────────────────────────────────────────────┤
│  K线图 (可切换指数)                          │
│  ┌─────────────────────────────────────┐   │
│  │                                     │   │
│  │      📈 K线图表区域                 │   │
│  │                                     │   │
│  └─────────────────────────────────────┘   │
├─────────────────────────────────────────────┤
│  资金流向图                                  │
│  ┌─────────────────────────────────────┐   │
│  │   📊 柱状图 + 折线图                │   │
│  └─────────────────────────────────────┘   │
├─────────────────────────────────────────────┤
│  热门股票 TOP5  │  龙虎榜 TOP5             │
│  (现有功能)     │  (现有功能)              │
└─────────────────────────────────────────────┘
```

## 📚 参考资源

1. **ECharts K线图示例**
   - https://echarts.apache.org/examples/zh/editor.html?c=candlestick-sh

2. **Vue3 + ECharts**
   - https://github.com/ecomfe/vue-echarts

3. **金融数据处理**
   - https://github.com/topics/stock-data

4. **东方财富接口分析**
   - 开发者工具 Network 面板观察
   - 搜索关键词："东方财富API接口"

## 🚀 快速开始

1. 安装依赖
```bash
npm install echarts vue-echarts
```

2. 注册组件
```typescript
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { CandlestickChart, BarChart, LineChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, LegendComponent, DataZoomComponent } from 'echarts/components'

use([
  CanvasRenderer,
  CandlestickChart,
  BarChart,
  LineChart,
  GridComponent,
  TooltipComponent,
  LegendComponent,
  DataZoomComponent
])
```

3. 使用组件
```vue
<template>
  <v-chart :option="klineOption" style="height: 400px" />
</template>

<script setup>
import VChart from 'vue-echarts'
</script>
```

---

**提示**: 以上API接口均为公开接口，仅供学习研究使用。商业用途请联系东方财富获取正式授权。
