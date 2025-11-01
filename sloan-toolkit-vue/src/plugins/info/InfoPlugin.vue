<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Location, Star, StarFilled, Delete, Clock, TrendCharts, InfoFilled } from '@element-plus/icons-vue'

// 中文城市名映射表
const CITY_MAP: Record<string, string> = {
  '北京': 'Beijing',
  '上海': 'Shanghai',
  '广州': 'Guangzhou',
  '深圳': 'Shenzhen',
  '杭州': 'Hangzhou',
  '南京': 'Nanjing',
  '成都': 'Chengdu',
  '武汉': 'Wuhan',
  '西安': "Xi'an",
  '重庆': 'Chongqing',
  '天津': 'Tianjin',
  '苏州': 'Suzhou',
  '厦门': 'Xiamen',
  '青岛': 'Qingdao',
  '大连': 'Dalian'
}

// 响应式数据
const city = ref('')
const loading = ref(false)
const weatherData = ref<any>(null)
const apiKey = ref('')
const API_ENDPOINT = 'https://api.openweathermap.org/data/2.5/weather'

// 收藏的城市（使用 localStorage）
const favoriteCities = ref<string[]>([])

// 搜索历史
const searchHistory = ref<string[]>([])

// 加载收藏和历史
const loadLocalData = () => {
  const saved = localStorage.getItem('favoriteCities')
  if (saved) {
    favoriteCities.value = JSON.parse(saved)
  }

  const history = localStorage.getItem('searchHistory')
  if (history) {
    searchHistory.value = JSON.parse(history)
  }
}

// 保存收藏
const saveFavorites = () => {
  localStorage.setItem('favoriteCities', JSON.stringify(favoriteCities.value))
}

// 保存历史
const saveHistory = () => {
  localStorage.setItem('searchHistory', JSON.stringify(searchHistory.value))
}

// 添加到收藏
const toggleFavorite = (cityName: string) => {
  const index = favoriteCities.value.indexOf(cityName)
  if (index > -1) {
    favoriteCities.value.splice(index, 1)
    ElMessage.success('已取消收藏')
  } else {
    if (favoriteCities.value.length >= 10) {
      ElMessage.warning('最多收藏10个城市')
      return
    }
    favoriteCities.value.push(cityName)
    ElMessage.success('已添加到收藏')
  }
  saveFavorites()
}

// 检查是否收藏
const isFavorite = computed(() => {
  return weatherData.value && favoriteCities.value.includes(weatherData.value.cityName)
})

// 添加到历史
const addToHistory = (cityName: string) => {
  // 去重并添加到开头
  searchHistory.value = searchHistory.value.filter(c => c !== cityName)
  searchHistory.value.unshift(cityName)
  
  // 限制历史记录数量
  if (searchHistory.value.length > 20) {
    searchHistory.value = searchHistory.value.slice(0, 20)
  }
  
  saveHistory()
}

// 清空历史
const clearHistory = () => {
  searchHistory.value = []
  saveHistory()
  ElMessage.success('历史记录已清空')
}

// 加载配置
const loadConfig = async () => {
  try {
    // 优先尝试加载本地配置文件（包含真实的API key）
    let response
    try {
      response = await fetch('/config.local.json')
    } catch {
      // 如果本地配置不存在，回退到默认配置
      response = await fetch('/config.json')
    }
    
    const config = await response.json()
    apiKey.value = config.apiKey
    
    // 如果配置了自动加载默认城市
    if (config.plugins?.info?.autoLoad && config.plugins.info.defaultCity) {
      city.value = config.plugins.info.defaultCity
      await getWeather()
    }
  } catch (error) {
    console.error('加载配置失败:', error)
    ElMessage.error('请创建 config.local.json 文件并配置有效的 API key')
  }
}

// 获取天气
const getWeather = async () => {
  if (!city.value.trim()) {
    ElMessage.warning('请输入城市名')
    return
  }

  if (!apiKey.value || apiKey.value === 'YOUR_API_KEY_HERE' || apiKey.value === 'YOUR_OPENWEATHERMAP_API_KEY_HERE') {
    ElMessage.error('请在 config.local.json 中配置有效的 OpenWeatherMap API key')
    return
  }

  loading.value = true
  const cityName = CITY_MAP[city.value] || city.value
  const url = `${API_ENDPOINT}?q=${encodeURIComponent(cityName)}&units=metric&appid=${apiKey.value}&lang=zh_cn`

  try {
    const res = await fetch(url)
    
    if (!res.ok) {
      if (res.status === 401) {
        throw new Error('API key 无效或未授权')
      }
      if (res.status === 404) {
        throw new Error('找不到该城市，请检查拼写')
      }
      throw new Error(`请求出错：${res.status}`)
    }

    const data = await res.json()
    
    if (!data || !data.weather || !data.main) {
      throw new Error('API 返回数据格式异常')
    }

    weatherData.value = {
      cityName: data.name,
      name: `${data.name}${data.sys?.country ? ', ' + data.sys.country : ''}`,
      temp: Math.round(data.main.temp),
      description: data.weather[0].description,
      icon: data.weather[0].icon,
      humidity: data.main.humidity,
      windSpeed: data.wind.speed,
      feelsLike: Math.round(data.main.feels_like),
      pressure: data.main.pressure
    }

    // 添加到历史记录
    addToHistory(data.name)

    ElMessage.success('天气数据获取成功')
  } catch (error: any) {
    ElMessage.error(error.message || '请求天气数据失败')
    console.error('获取天气失败:', error)
  } finally {
    loading.value = false
  }
}

// 快速城市选择
const quickCities = ['北京', '上海', '广州', '深圳', '杭州', '成都']

const selectCity = (selectedCity: string) => {
  city.value = selectedCity
  getWeather()
}

// ========================= 股票功能 =========================

interface StockInfo {
  code: string          // 股票代码
  name: string          // 股票名称
  price: number         // 最新价
  change: number        // 涨跌额
  changePercent: number // 涨跌幅%
  volume: number        // 成交量(手)
  amount: number        // 成交额
  high: number          // 最高价
  low: number           // 最低价
  open: number          // 开盘价
  preClose: number      // 昨收价
  turnover: number      // 换手率%
}

// 股票数据
const hotStocks = ref<StockInfo[]>([])
const topStocks = ref<any[]>([])
const stockLoading = ref(false)
const lastTradeDate = ref<string>('') // 最新交易日期

// 获取最新交易日（排除周末）
const getLatestTradeDate = () => {
  const now = new Date()
  let date = new Date(now)
  
  // 如果是周六，往前推1天到周五
  if (date.getDay() === 6) {
    date.setDate(date.getDate() - 1)
  }
  // 如果是周日，往前推2天到周五
  else if (date.getDay() === 0) {
    date.setDate(date.getDate() - 2)
  }
  
  // 格式化为 YYYY-MM-DD
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  
  return `${year}-${month}-${day}`
}

// 获取热门股票（涨幅榜前5）
const getHotStocks = async () => {
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

    console.log('正在获取热门股票...')
    const res = await fetch(url)
    const data = await res.json()
    console.log('热门股票API返回:', data)

    if (data.data && data.data.diff) {
      hotStocks.value = data.data.diff.map((item: any) => ({
        code: item.f12,
        name: item.f14,
        price: (item.f2 / 1000).toFixed(2),
        change: (item.f4 / 1000).toFixed(2),
        changePercent: (item.f3 / 100).toFixed(2),
        volume: item.f5,
        amount: item.f6,
        high: (item.f15 / 1000).toFixed(2),
        low: (item.f16 / 1000).toFixed(2),
        open: (item.f17 / 1000).toFixed(2),
        preClose: (item.f18 / 1000).toFixed(2),
        turnover: (item.f8 / 100).toFixed(2)
      }))
      console.log('✅ 热门股票数据解析成功，共', hotStocks.value.length, '条')
    } else {
      console.warn('⚠️ 热门股票API返回数据为空')
    }
  } catch (error) {
    console.error('❌ 获取热门股票失败:', error)
  }
}

// 获取龙虎榜前5
const getTopStocks = async () => {
  try {
    // 使用HTTPS协议避免混合内容问题
    const params = {
      reportName: 'RPT_DAILYBILLBOARD_LIST',
      columns: 'SECURITY_CODE,SECURITY_NAME_ABBR,TRADE_DATE,CLOSE_PRICE,CHANGE_RATE,BILLBOARD_NET_AMT',
      pageNumber: '1',
      pageSize: '5',
      sortColumns: 'BILLBOARD_NET_AMT',
      sortTypes: '-1',
      source: 'WEB',
      client: 'WEB',
      filter: `(TRADE_DATE='${getLatestTradeDate()}')`
    }
    
    const url = 'https://datacenter-web.eastmoney.com/api/data/v1/get?' + new URLSearchParams(params)
    console.log('正在获取龙虎榜数据...', url)
    const res = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
      mode: 'cors'
    })
    
    console.log('龙虎榜API响应状态:', res.status)
    
    if (!res.ok) {
      throw new Error(`HTTP错误: ${res.status}`)
    }

    const data = await res.json()
    console.log('龙虎榜API返回:', data)
    console.log('data.result:', data.result)
    console.log('data.result.data:', data.result?.data)

    if (data.result && data.result.data && data.result.data.length > 0) {
      // 获取最新交易日期并格式化
      const latestDate = data.result.data[0].TRADE_DATE
      if (latestDate) {
        const date = new Date(latestDate)
        lastTradeDate.value = `${date.getMonth() + 1}月${date.getDate()}日`
        console.log('✅ 交易日期:', latestDate, '→', lastTradeDate.value)
      }
      
      topStocks.value = data.result.data.map((item: any) => ({
        code: item.SECURITY_CODE,
        name: item.SECURITY_NAME_ABBR,
        date: item.TRADE_DATE,
        price: item.CLOSE_PRICE?.toFixed(2) || '-',
        changePercent: item.CHANGE_RATE?.toFixed(2) || '-',
        netAmount: (item.BILLBOARD_NET_AMT / 100000000).toFixed(2), // 转换为亿元
        reason: '龙虎榜上榜'
      }))
      
      console.log('✅ 龙虎榜数据解析成功，共', topStocks.value.length, '条')
    } else {
      console.warn('⚠️ 龙虎榜API返回数据为空')
      // 使用模拟数据
      const mockDate = getLatestTradeDate()
      const date = new Date(mockDate)
      lastTradeDate.value = `${date.getMonth() + 1}月${date.getDate()}日`
      
      topStocks.value = [
        { code: '600519', name: '贵州茅台', price: '1680.50', changePercent: '2.35', netAmount: '5.68', date: mockDate, reason: '龙虎榜上榜' },
        { code: '000858', name: '五粮液', price: '156.80', changePercent: '3.21', netAmount: '3.45', date: mockDate, reason: '龙虎榜上榜' },
        { code: '601318', name: '中国平安', price: '42.50', changePercent: '-1.15', netAmount: '2.89', date: mockDate, reason: '龙虎榜上榜' },
        { code: '600036', name: '招商银行', price: '36.20', changePercent: '1.50', netAmount: '2.34', date: mockDate, reason: '龙虎榜上榜' },
        { code: '000001', name: '平安银行', price: '11.80', changePercent: '0.85', netAmount: '1.92', date: mockDate, reason: '龙虎榜上榜' }
      ]
      console.log('📊 使用模拟数据 (交易日:', mockDate, ')')
      ElMessage.info('龙虎榜数据加载失败，显示示例数据')
    }
  } catch (error: any) {
    console.error('❌ 获取龙虎榜失败:', error)
    console.error('错误详情:', error.message)
    
    // 提供模拟数据作为后备
    const mockDate = getLatestTradeDate()
    const date = new Date(mockDate)
    lastTradeDate.value = `${date.getMonth() + 1}月${date.getDate()}日`
    
    topStocks.value = [
      { code: '600519', name: '贵州茅台', price: '1680.50', changePercent: '2.35', netAmount: '5.68', date: mockDate, reason: '龙虎榜上榜' },
      { code: '000858', name: '五粮液', price: '156.80', changePercent: '3.21', netAmount: '3.45', date: mockDate, reason: '龙虎榜上榜' },
      { code: '601318', name: '中国平安', price: '42.50', changePercent: '-1.15', netAmount: '2.89', date: mockDate, reason: '龙虎榜上榜' },
      { code: '600036', name: '招商银行', price: '36.20', changePercent: '1.50', netAmount: '2.34', date: mockDate, reason: '龙虎榜上榜' },
      { code: '000001', name: '平安银行', price: '11.80', changePercent: '0.85', netAmount: '1.92', date: mockDate, reason: '龙虎榜上榜' }
    ]
    console.log('📊 API失败，使用模拟数据 (交易日:', mockDate, ')')
    ElMessage.info('龙虎榜数据加载失败，显示示例数据')
  }
}

// 刷新股票数据
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

// 组件挂载时加载配置和本地数据
onMounted(() => {
  loadConfig()
  loadLocalData()
  // 加载股票数据
  refreshStocks()
})
</script>

<template>
  <div class="info-plugin">
    <el-card shadow="hover">
      <template #header>
        <div class="card-header">
          <span class="title">🌤️ 天气查询</span>
        </div>
      </template>

      <!-- 搜索框 -->
      <div class="search-box">
        <el-input
          v-model="city"
          placeholder="输入城市名（如：北京、上海、广州等）"
          size="large"
          clearable
          @keyup.enter="getWeather"
        >
          <template #append>
            <el-button
              :icon="Search"
              :loading="loading"
              @click="getWeather"
            />
          </template>
        </el-input>
      </div>

      <!-- 快速选择城市 -->
      <div class="quick-cities">
        <div class="section-title">热门城市</div>
        <el-tag
          v-for="quickCity in quickCities"
          :key="quickCity"
          class="city-tag"
          type="info"
          effect="plain"
          @click="selectCity(quickCity)"
        >
          {{ quickCity }}
        </el-tag>
      </div>

      <!-- 收藏的城市 -->
      <div v-if="favoriteCities.length > 0" class="favorite-cities">
        <div class="section-title">
          <Star class="icon" />
          我的收藏
        </div>
        <el-tag
          v-for="favCity in favoriteCities"
          :key="favCity"
          class="city-tag favorite"
          type="warning"
          effect="light"
          closable
          @click="selectCity(favCity)"
          @close="toggleFavorite(favCity)"
        >
          {{ favCity }}
        </el-tag>
      </div>

      <!-- 搜索历史 -->
      <div v-if="searchHistory.length > 0" class="search-history">
        <div class="section-title">
          <el-icon><Clock /></el-icon>
          最近搜索
          <el-button
            text
            size="small"
            :icon="Delete"
            @click="clearHistory"
          >
            清空
          </el-button>
        </div>
        <div class="history-tags">
          <el-tag
            v-for="histCity in searchHistory.slice(0, 8)"
            :key="histCity"
            class="city-tag history"
            type="info"
            effect="plain"
            size="small"
            @click="selectCity(histCity)"
          >
            {{ histCity }}
          </el-tag>
        </div>
      </div>

      <!-- 天气信息 -->
      <el-divider v-if="weatherData" />
      
      <div v-if="weatherData" class="weather-content">
        <div class="weather-main">
          <div class="weather-icon">
            <img
              :src="`https://openweathermap.org/img/wn/${weatherData.icon}@4x.png`"
              :alt="weatherData.description"
            >
          </div>
          <div class="weather-info">
            <div class="location-row">
              <h2 class="location">{{ weatherData.name }}</h2>
              <el-button
                :icon="isFavorite ? StarFilled : Star"
                :type="isFavorite ? 'warning' : 'default'"
                circle
                @click="toggleFavorite(weatherData.cityName)"
              />
            </div>
            <div class="temperature">{{ weatherData.temp }}°C</div>
            <div class="description">{{ weatherData.description }}</div>
          </div>
        </div>

        <!-- 详细信息 -->
        <div class="weather-details">
          <el-row :gutter="20">
            <el-col :span="12">
              <div class="detail-item">
                <span class="detail-label">体感温度</span>
                <span class="detail-value">{{ weatherData.feelsLike }}°C</span>
              </div>
            </el-col>
            <el-col :span="12">
              <div class="detail-item">
                <span class="detail-label">湿度</span>
                <span class="detail-value">{{ weatherData.humidity }}%</span>
              </div>
            </el-col>
            <el-col :span="12">
              <div class="detail-item">
                <span class="detail-label">风速</span>
                <span class="detail-value">{{ weatherData.windSpeed }} m/s</span>
              </div>
            </el-col>
            <el-col :span="12">
              <div class="detail-item">
                <span class="detail-label">气压</span>
                <span class="detail-value">{{ weatherData.pressure }} hPa</span>
              </div>
            </el-col>
          </el-row>
        </div>
      </div>

      <!-- 空状态 -->
      <el-empty
        v-else-if="!loading"
        description="请输入城市名查询天气"
        :image-size="120"
      />
    </el-card>

    <!-- 股票信息区域 -->
    <el-divider>
      <el-icon><TrendCharts /></el-icon>
      股市行情
    </el-divider>

    <el-row :gutter="20">
      <!-- 热门股票榜 -->
      <el-col :xs="24" :sm="24" :md="12">
        <el-card shadow="hover" class="stock-card">
          <template #header>
            <div class="stock-card-header">
              <span class="stock-title">🔥 今日涨幅榜 TOP5</span>
              <el-button 
                size="small" 
                :loading="stockLoading"
                @click="refreshStocks"
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
                  :class="['stock-change', row.change >= 0 ? 'positive' : 'negative']"
                >
                  {{ row.change >= 0 ? '+' : '' }}{{ row.changePercent }}%
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
              <el-tooltip content="上一个交易日资金净流入" placement="top">
                <el-icon><InfoFilled /></el-icon>
              </el-tooltip>
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
            
            <el-table-column prop="price" label="收盘价" align="right" width="80">
              <template #default="{ row }">
                <span class="stock-price">{{ row.price }}</span>
              </template>
            </el-table-column>
            
            <el-table-column prop="changePercent" label="涨跌幅" align="right" width="90">
              <template #default="{ row }">
                <span 
                  :class="['stock-change', row.changePercent >= 0 ? 'positive' : 'negative']"
                >
                  {{ row.changePercent >= 0 ? '+' : '' }}{{ row.changePercent }}%
                </span>
              </template>
            </el-table-column>

            <el-table-column prop="netAmount" label="净流入(亿)" align="right" width="90">
              <template #default="{ row }">
                <span 
                  :class="['stock-amount', row.netAmount >= 0 ? 'positive' : 'negative']"
                >
                  {{ row.netAmount >= 0 ? '+' : '' }}{{ row.netAmount }}
                </span>
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
.info-plugin {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;

  .card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;

    .title {
      font-size: 20px;
      font-weight: 600;
      color: #303133;
    }
  }

  .search-box {
    margin-bottom: 15px;
  }

  .quick-cities,
  .favorite-cities,
  .search-history {
    margin-bottom: 15px;

    .section-title {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 14px;
      font-weight: 500;
      color: #606266;
      margin-bottom: 10px;

      .icon {
        color: #f7ba2a;
      }

      .el-button {
        margin-left: auto;
      }
    }

    .city-tag {
      margin-right: 8px;
      margin-bottom: 8px;
      cursor: pointer;
      transition: all 0.3s;

      &:hover {
        transform: translateY(-2px);
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      }

      &.favorite {
        border-color: #f7ba2a;
      }

      &.history {
        opacity: 0.85;
      }
    }

    .history-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
    }
  }

  .weather-content {
    .weather-main {
      display: flex;
      align-items: center;
      gap: 30px;
      margin-bottom: 30px;

      .weather-icon {
        img {
          width: 150px;
          height: 150px;
          filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.1));
        }
      }

      .weather-info {
        flex: 1;

        .location-row {
          display: flex;
          align-items: center;
          gap: 10px;
          margin-bottom: 10px;
        }

        .location {
          font-size: 28px;
          font-weight: 600;
          color: #303133;
          margin: 0;
        }

        .temperature {
          font-size: 48px;
          font-weight: bold;
          color: #409eff;
          line-height: 1;
          margin-bottom: 10px;
        }

        .description {
          font-size: 18px;
          color: #606266;
          text-transform: capitalize;
        }
      }
    }

    .weather-details {
      background: #f5f7fa;
      padding: 20px;
      border-radius: 8px;

      .detail-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 10px 0;

        .detail-label {
          font-size: 14px;
          color: #909399;
        }

        .detail-value {
          font-size: 16px;
          font-weight: 600;
          color: #303133;
        }
      }
    }
  }

  // 股票卡片样式
  .stock-card {
    margin-top: 20px;

    .stock-card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;

      .stock-title {
        font-size: 16px;
        font-weight: 600;
        color: #303133;

        .trade-date {
          font-size: 12px;
          font-weight: normal;
          color: #909399;
          margin-left: 6px;
        }
      }
    }

    .stock-name-cell {
      .stock-name {
        font-size: 13px;
        font-weight: 600;
        color: #303133;
        margin-bottom: 2px;
      }

      .stock-code {
        font-size: 11px;
        color: #909399;
      }
    }

    .stock-price {
      font-size: 13px;
      font-weight: 600;
      color: #303133;
    }

    .stock-change {
      font-size: 13px;
      font-weight: 600;

      &.positive {
        color: #f56c6c;
      }

      &.negative {
        color: #67c23a;
      }
    }

    .stock-turnover {
      font-size: 12px;
      color: #606266;
    }

    .stock-amount {
      font-size: 13px;
      font-weight: 600;

      &.positive {
        color: #f56c6c;
      }

      &.negative {
        color: #67c23a;
      }
    }
  }
}

// 响应式设计
@media (max-width: 768px) {
  .weather-plugin {
    .weather-content .weather-main {
      flex-direction: column;
      text-align: center;

      .weather-icon img {
        width: 120px;
        height: 120px;
      }

      .weather-info .temperature {
        font-size: 36px;
      }
    }

    .stock-card {
      margin-top: 15px;
    }
  }
}
</style>
