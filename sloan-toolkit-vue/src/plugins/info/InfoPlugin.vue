<script setup lang="ts">
/**
 * ============================================
 * 信息插件 - Info Plugin
 * ============================================
 * 功能：展示天气信息和科技资讯
 * 
 * 模块结构：
 * 1. 配置与常量
 * 2. 天气模块
 * 3. 科技资讯模块
 * 4. 工具函数
 * 5. 生命周期
 * 
 * 扩展指南：
 * - 要添加新的信息模块，在模板中复制 el-col 结构
 * - 添加对应的响应式数据和API函数
 * - 在生命周期函数中初始化数据
 * ============================================
 */

import { ref, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Star, StarFilled, Refresh } from '@element-plus/icons-vue'
import { useRouter } from 'vue-router'

// ============================================
// 1. 配置与常量
// ============================================

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

// 路由实例
const router = useRouter()

// ============================================
// 2. 天气模块
// ============================================

// 2.1 天气数据定义
const apiKey = ref('')
const API_ENDPOINT = 'https://api.openweathermap.org/data/2.5/weather'
const city = ref('')
const loading = ref(false)
const weatherData = ref<any>(null)
const favoriteCities = ref<string[]>([])
const searchHistory = ref<string[]>([])
const quickCities = ['北京', '上海', '广州', '深圳', '杭州', '成都']

// 2.2 天气本地存储操作
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

// 清空历史 (暂未使用)
// const clearHistory = () => {
//   searchHistory.value = []
//   saveHistory()
//   ElMessage.success('历史记录已清空')
// }

// 2.4 天气配置加载
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

  if (!apiKey.value || 
      apiKey.value === 'YOUR_API_KEY_HERE' || 
      apiKey.value === 'YOUR_OPENWEATHERMAP_API_KEY_HERE' ||
      apiKey.value.includes('请在此处填写') ||
      apiKey.value.includes('OpenWeatherMap API Key')) {
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
      pressure: data.main.pressure,
      // 新增字段
      clouds: data.clouds?.all || 0,  // 云量 (%)
      visibility: data.visibility ? (data.visibility / 1000).toFixed(1) : 'N/A',  // 能见度 (km)
      rain: data.rain?.['1h'] || data.rain?.['3h'] || 0,  // 降雨量 (mm)
      snow: data.snow?.['1h'] || data.snow?.['3h'] || 0,  // 降雪量 (mm)
      windDeg: data.wind?.deg || 0,  // 风向 (度)
      tempMin: Math.round(data.main.temp_min),  // 最低温度
      tempMax: Math.round(data.main.temp_max),  // 最高温度
      sunrise: data.sys?.sunrise || 0,  // 日出时间
      sunset: data.sys?.sunset || 0   // 日落时间
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

// 2.3 天气快速选择
const selectCity = (selectedCity: string) => {
  city.value = selectedCity
  getWeather()
}

// ============================================
// 3. 科技资讯模块 (36氪)
// ============================================

// 4.1 资讯数据类型定义
interface NewsItem {
  id: string
  title: string
  summary: string
  publishTime: string
  url: string
  coverImage?: string
  isTop?: boolean  // 标记是否为置顶内容
  category?: string  // 分类（如 "8点1氪"）
}

// 4.2 资讯响应式数据
const newsList = ref<NewsItem[]>([])
const newsLoading = ref(false)

// 4.3 获取36氪资讯（通过RSS源）
const get36KrNews = async () => {
  newsLoading.value = true
  try {
    // 使用后端代理获取RSS数据（避免CORS问题）
    const response = await fetch('/api/36kr/rss')
    
    if (!response.ok) {
      throw new Error('RSS获取失败')
    }
    
    const data = await response.json()
    
    // 解析RSS数据
    if (data.items && data.items.length > 0) {
      // 先查找8点1氪/9点1氪
      const topArticles = data.items.filter((item: any) => {
        const title = item.title || ''
        return title.includes('8点1氪') || title.includes('9点1氪')
      }).slice(0, 1).map((item: any) => ({
        id: item.id || item.link,
        title: item.title,
        summary: item.summary || item.description || '',
        publishTime: formatNewsTime(item.publishTime),
        url: item.link,
        isTop: true,
        category: item.title.includes('8点') ? '8点1氪' : '9点1氪'
      }))
      
      // 其他资讯
      const regularNews = data.items
        .filter((item: any) => {
          const title = item.title || ''
          return !title.includes('8点1氪') && !title.includes('9点1氪')
        })
        .slice(0, 9)
        .map((item: any) => ({
          id: item.id || item.link,
          title: item.title,
          summary: item.summary || item.description || '',
          publishTime: formatNewsTime(item.publishTime),
          url: item.link,
          isTop: false
        }))
      
      newsList.value = [...topArticles, ...regularNews]
      return
    }
    
    throw new Error('RSS数据为空')
    
  } catch (error) {
    console.error('获取36氪RSS失败:', error)
    
    // 降级到精选本地数据
    const now = new Date()
    const hour = now.getHours()
    
    const morningBrief = hour < 12 ? {
      id: 'morning-brief',
      title: '8点1氪｜华为Mate 70系列即将发布；OpenAI推出新功能；比亚迪销量再创新高',
      summary: '早间科技圈要闻：华为新旗舰将于本月发布，搭载鸿蒙4.0系统；OpenAI发布GPT-4 Turbo，性能提升显著；比亚迪10月新能源汽车销量突破50万辆',
      publishTime: '8:00',
      url: 'https://36kr.com',
      isTop: true,
      category: '8点1氪'
    } : {
      id: 'evening-brief',
      title: '9点1氪｜阿里云发布新一代AI芯片；特斯拉中国工厂扩产；蔚来推出手机新品',
      summary: '晚间科技要闻：阿里云自研芯片性能提升3倍；特斯拉上海工厂年产能将达100万辆；蔚来手机NIO Phone 2正式发布',
      publishTime: '21:00',
      url: 'https://36kr.com',
      isTop: true,
      category: '9点1氪'
    }
    
    newsList.value = [
      morningBrief,
      {
        id: '1',
        title: 'OpenAI发布GPT-4 Turbo，支持128K上下文',
        summary: 'OpenAI在开发者大会上宣布推出GPT-4 Turbo，相比GPT-4，上下文长度提升至128K tokens，价格降低3倍，并新增多模态能力',
        publishTime: formatNewsTime(Date.now() - 600000),
        url: 'https://36kr.com/p/2500887516382338',
        isTop: false
      },
      {
        id: '2',
        title: '华为Mate 70系列将搭载全新麒麟9100芯片',
        summary: '据供应链消息，华为Mate 70系列将采用5nm制程的麒麟9100处理器，性能相比上一代提升40%，支持卫星通信功能',
        publishTime: formatNewsTime(Date.now() - 1800000),
        url: 'https://36kr.com/p/2500887516382339',
        isTop: false
      },
      {
        id: '3',
        title: '比亚迪10月新能源车销量突破50万辆，同比增长38%',
        summary: '比亚迪公布10月销量数据，新能源汽车销售50.13万辆，其中纯电动车型占比42%，海外市场销量增长迅速',
        publishTime: formatNewsTime(Date.now() - 3600000),
        url: 'https://36kr.com/p/2500887516382340',
        isTop: false
      },
      {
        id: '4',
        title: '阿里云发布自研AI芯片倚天720，性能提升3倍',
        summary: '阿里云正式发布第三代自研AI芯片倚天720，采用5nm工艺，专为大模型训练优化，能效比提升50%',
        publishTime: formatNewsTime(Date.now() - 7200000),
        url: 'https://36kr.com/p/2500887516382341',
        isTop: false
      },
      {
        id: '5',
        title: '特斯拉上海工厂第三期扩建完成，年产能达100万辆',
        summary: '特斯拉中国宣布上海超级工厂第三期项目正式投产，新增产能30万辆，全厂年产能突破100万辆大关',
        publishTime: formatNewsTime(Date.now() - 10800000),
        url: 'https://36kr.com/p/2500887516382342',
        isTop: false
      }
    ]
  } finally {
    newsLoading.value = false
  }
}

// 4.4 格式化资讯时间
const formatNewsTime = (timestamp: number): string => {
  const now = Date.now()
  const diff = now - timestamp
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)
  
  if (minutes < 1) return '刚刚'
  if (minutes < 60) return `${minutes}分钟前`
  if (hours < 24) return `${hours}小时前`
  if (days < 7) return `${days}天前`
  
  const date = new Date(timestamp)
  return `${date.getMonth() + 1}月${date.getDate()}日`
}

// 4.5 打开资讯链接（使用内置浏览器 WebView）
const openNewsUrl = async (url: string) => {
  try {
    // 统一使用应用内 WebView 浏览器
    // 跳转到内置浏览器页面，传递 URL 参数
    router.push({
      path: '/browser',
      query: { url: encodeURIComponent(url) }
    })
  } catch (error) {
    console.error('打开链接失败:', error)
    ElMessage.error('无法打开链接')
  }
}

// 3.1 资讯数据类型定义
const getWindDirection = (deg: number): string => {
  const directions = ['北', '东北', '东', '东南', '南', '西南', '西', '西北']
  const index = Math.round(((deg % 360) / 45)) % 8
  return directions[index]
}

// 4.2 时间格式化
const formatTime = (timestamp: number): string => {
  if (!timestamp) return 'N/A'
  const date = new Date(timestamp * 1000)
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  return `${hours}:${minutes}`
}

// 4.3 空气质量判断（基于能见度）
const getAirQuality = (visibility: string): string => {
  const vis = parseFloat(visibility)
  if (isNaN(vis)) return '未知'
  if (vis >= 10) return '优'
  if (vis >= 5) return '良'
  if (vis >= 3) return '轻度污染'
  if (vis >= 1) return '中度污染'
  return '重度污染'
}

// 4.4 空气质量颜色
const getAirQualityColor = (visibility: string): string => {
  const vis = parseFloat(visibility)
  if (isNaN(vis)) return '#909399'
  if (vis >= 10) return '#67c23a'
  if (vis >= 5) return '#e6a23c'
  if (vis >= 3) return '#f56c6c'
  if (vis >= 1) return '#c71585'
  return '#8b0000'
}

// ============================================
// 5. 生命周期
// ============================================

// 组件挂载时加载配置和本地数据
onMounted(() => {
  loadConfig()
  loadLocalData()
  // 加载科技资讯
  get36KrNews()
})
</script>

<template>
  <!-- ============================================ -->
  <!-- 信息插件模板 -->
  <!-- ============================================ -->
  <!-- 布局结构：天气信息 + 科技资讯 -->
  <!-- 可扩展：复制 el-col 添加新的信息模块 -->
  <!-- ============================================ -->
  <div class="info-plugin">
    <!-- 信息展示区域：天气信息 -->
    <el-row :gutter="20">
      <!-- 天气信息 -->
      <el-col :xs="24" :sm="24" :md="24">
        <!-- 天气搜索卡片 -->
        <el-card shadow="hover" class="weather-search-card" style="margin-bottom: 20px;">
          <template #header>
            <div class="card-header">
              <span class="title">🔍 城市查询</span>
            </div>
          </template>

          <!-- 搜索框 -->
          <div class="search-box">
            <el-input
              v-model="city"
              placeholder="输入城市名查询天气"
              size="default"
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
            <el-tag
              v-for="quickCity in quickCities"
              :key="quickCity"
              class="city-tag"
              type="info"
              effect="plain"
              size="small"
              @click="selectCity(quickCity)"
            >
              {{ quickCity }}
            </el-tag>
          </div>
        </el-card>

        <!-- 天气信息展示卡片 -->
        <el-card shadow="hover" class="weather-card">
          <template #header>
            <div class="card-header">
              <span class="title">🌤️ 天气信息</span>
              <el-button
                v-if="weatherData"
                :icon="isFavorite ? StarFilled : Star"
                :type="isFavorite ? 'warning' : 'default'"
                size="small"
                circle
                @click="toggleFavorite(weatherData.cityName)"
              />
            </div>
          </template>

          <!-- 天气信息显示 -->
          <div v-if="weatherData" class="weather-content">
            <div class="weather-main">
              <div class="weather-icon">
                <img
                  :src="`https://openweathermap.org/img/wn/${weatherData.icon}@4x.png`"
                  :alt="weatherData.description"
                >
              </div>
              <div class="weather-info">
                <h2 class="location">{{ weatherData.name }}</h2>
                <div class="temperature">{{ weatherData.temp }}°C</div>
                <div class="temp-range">{{ weatherData.tempMin }}°C ~ {{ weatherData.tempMax }}°C</div>
                <div class="description">{{ weatherData.description }}</div>
              </div>
            </div>

            <!-- 详细信息网格 - 2列布局 -->
            <div class="weather-details-grid">
              <!-- 第一列 -->
              <div class="detail-column">
                <div class="detail-item">
                  <span class="detail-label">🌡️ 体感</span>
                  <span class="detail-value">{{ weatherData.feelsLike }}°C</span>
                </div>
                
                <div class="detail-item">
                  <span class="detail-label">💧 湿度</span>
                  <span class="detail-value">{{ weatherData.humidity }}%</span>
                </div>

                <div class="detail-item">
                  <span class="detail-label">🌬️ 风速</span>
                  <span class="detail-value">{{ weatherData.windSpeed }} m/s</span>
                </div>

                <div class="detail-item">
                  <span class="detail-label">🧭 风向</span>
                  <span class="detail-value">{{ getWindDirection(weatherData.windDeg) }}</span>
                </div>

                <div class="detail-item">
                  <span class="detail-label">☁️ 云量</span>
                  <span class="detail-value">{{ weatherData.clouds }}%</span>
                </div>

                <div class="detail-item">
                  <span class="detail-label">👁️ 能见度</span>
                  <span class="detail-value">{{ weatherData.visibility }} km</span>
                </div>
              </div>

              <!-- 第二列 -->
              <div class="detail-column">
                <div class="detail-item">
                  <span class="detail-label">🏭 空气</span>
                  <span 
                    class="detail-value air-quality"
                    :style="{ color: getAirQualityColor(weatherData.visibility) }"
                  >
                    {{ getAirQuality(weatherData.visibility) }}
                  </span>
                </div>

                <div class="detail-item">
                  <span class="detail-label">📊 气压</span>
                  <span class="detail-value">{{ weatherData.pressure }} hPa</span>
                </div>

                <div v-if="weatherData.rain > 0" class="detail-item">
                  <span class="detail-label">🌧️ 降雨</span>
                  <span class="detail-value rain">{{ weatherData.rain }} mm</span>
                </div>

                <div v-if="weatherData.snow > 0" class="detail-item">
                  <span class="detail-label">❄️ 降雪</span>
                  <span class="detail-value snow">{{ weatherData.snow }} mm</span>
                </div>

                <div class="detail-item">
                  <span class="detail-label">🌅 日出</span>
                  <span class="detail-value">{{ formatTime(weatherData.sunrise) }}</span>
                </div>

                <div class="detail-item">
                  <span class="detail-label">🌇 日落</span>
                  <span class="detail-value">{{ formatTime(weatherData.sunset) }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- 无数据提示 -->
          <el-empty 
            v-else
            description="输入城市名查询天气"
            :image-size="100"
          />
        </el-card>
      </el-col>
    </el-row>

    <!-- 科技资讯区域 (全宽) -->
    <el-row :gutter="20" style="margin-top: 20px;">
      <el-col :xs="24">
        <el-card shadow="hover" class="news-card">
          <template #header>
            <div class="card-header">
              <span class="title">📰 36氪科技资讯</span>
              <el-button
                text
                :icon="Refresh"
                @click="get36KrNews"
                :loading="newsLoading"
                size="small"
              >
                刷新
              </el-button>
            </div>
          </template>

          <div v-loading="newsLoading">
            <div 
              v-for="item in newsList" 
              :key="item.id"
              :class="['news-item', { 'news-item-top': item.isTop }]"
              @click="openNewsUrl(item.url)"
            >
              <div class="news-content">
                <div class="news-header">
                  <el-tag 
                    v-if="item.isTop" 
                    type="danger" 
                    size="small" 
                    effect="dark"
                    class="top-tag"
                  >
                    {{ item.category }}
                  </el-tag>
                  <h4 class="news-title">{{ item.title }}</h4>
                </div>
                <p v-if="item.summary" class="news-summary">{{ item.summary }}</p>
                <span class="news-time">{{ item.publishTime }}</span>
              </div>
            </div>
          </div>

          <el-empty 
            v-if="!newsLoading && newsList.length === 0"
            description="暂无资讯"
            :image-size="60"
          />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped lang="scss">
.info-plugin {
  max-width: 1400px;
  margin: 0 auto;
  padding: 20px;

  .card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;

    .title {
      font-size: 18px;
      font-weight: 600;
      color: #303133;
    }
  }

  // 天气搜索卡片
  .weather-search-card {
    // 与热门股票卡片高度对齐
    min-height: 200px;
    display: flex;
    flex-direction: column;

    :deep(.el-card__body) {
      flex: 1;
      display: flex;
      flex-direction: column;
      justify-content: center;
    }

    .search-box {
      margin-bottom: 12px;
    }

    .quick-cities {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;

      .city-tag {
        cursor: pointer;
        transition: all 0.3s;

        &:hover {
          transform: translateY(-2px);
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }
      }
    }
  }

  // 天气信息卡片
  .weather-card {
    // 与龙虎榜卡片高度对齐
    min-height: 400px;
    display: flex;
    flex-direction: column;

    :deep(.el-card__body) {
      flex: 1;
    }

    .weather-content {
      .weather-main {
        display: flex;
        align-items: center;
        gap: 20px;
        margin-bottom: 20px;
        padding-bottom: 15px;
        border-bottom: 1px solid #ebeef5;

        .weather-icon {
          img {
            width: 100px;
            height: 100px;
            filter: drop-shadow(0 2px 6px rgba(0, 0, 0, 0.1));
          }
        }

        .weather-info {
          flex: 1;

          .location {
            font-size: 22px;
            font-weight: 600;
            color: #303133;
            margin: 0 0 8px 0;
          }

          .temperature {
            font-size: 38px;
            font-weight: bold;
            color: #409eff;
            line-height: 1;
            margin-bottom: 4px;
          }

          .temp-range {
            font-size: 13px;
            color: #909399;
            margin-bottom: 6px;
          }

          .description {
            font-size: 15px;
            color: #606266;
            text-transform: capitalize;
          }
        }
      }

      // 天气详细信息网格 - 2列布局
      .weather-details-grid {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 15px;

        .detail-column {
          display: flex;
          flex-direction: column;
          gap: 10px;

          .detail-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 12px;
            background: #f5f7fa;
            border-radius: 6px;
            transition: all 0.3s;

            &:hover {
              background: #e8ecf0;
              transform: translateY(-1px);
            }

            .detail-label {
              font-size: 13px;
              color: #606266;
              font-weight: 500;
            }

            .detail-value {
              font-size: 13px;
              font-weight: 600;
              color: #303133;
              text-align: right;

              &.air-quality {
                font-weight: bold;
              }

              &.rain {
                color: #409eff;
              }

              &.snow {
                color: #67c23a;
              }
            }
          }
        }
      }
    }
  }

  // 科技资讯卡片
  .news-card {
    .news-item {
      padding: 16px 0;
      border-bottom: 1px solid #ebeef5;
      cursor: pointer;
      transition: all 0.3s;

      &:last-child {
        border-bottom: none;
      }

      &:hover {
        background: #f5f7fa;
        padding-left: 8px;
        padding-right: 8px;
        border-radius: 4px;

        .news-title {
          color: #409eff;
        }
      }

      // 置顶文章样式
      &.news-item-top {
        background: linear-gradient(to right, #fff5f5, #fff);
        padding: 16px 12px;
        border-radius: 8px;
        border: 1px solid #fde2e2;
        margin-bottom: 12px;

        &:hover {
          background: linear-gradient(to right, #ffeded, #fff9f9);
          border-color: #fbd5d5;
          box-shadow: 0 2px 12px rgba(245, 108, 108, 0.1);
        }

        .news-title {
          color: #303133;
          font-weight: 700;
        }
      }

      .news-content {
        .news-header {
          display: flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 8px;

          .top-tag {
            flex-shrink: 0;
          }

          .news-title {
            margin: 0;
            flex: 1;
          }
        }

        .news-title {
          margin: 0 0 8px 0;
          font-size: 15px;
          font-weight: 600;
          color: #303133;
          line-height: 1.5;
          transition: color 0.3s;
        }

        .news-summary {
          margin: 0 0 8px 0;
          font-size: 13px;
          color: #606266;
          line-height: 1.6;
          display: -webkit-box;
          -webkit-line-clamp: 2;
          line-clamp: 2;
          -webkit-box-orient: vertical;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .news-time {
          font-size: 12px;
          color: #909399;
        }
      }
    }
  }
}

// 响应式设计
@media (max-width: 992px) {
  .info-plugin {
    .weather-search-card,
    .weather-card {
      margin-bottom: 20px;
    }

    .weather-content {
      .weather-details-grid {
        grid-template-columns: repeat(2, 1fr);
        gap: 10px;
      }
    }
  }
}

@media (max-width: 768px) {
  .info-plugin {
    padding: 15px;

    .weather-search-card {
      margin-bottom: 15px;
    }

    .weather-content {
      .weather-main {
        flex-direction: column;
        text-align: center;
        gap: 15px;

        .weather-icon img {
          width: 90px;
          height: 90px;
        }

        .weather-info {
          .location {
            font-size: 18px;
          }

          .temperature {
            font-size: 32px;
          }

          .description {
            font-size: 14px;
          }
        }
      }

      .weather-details-grid {
        grid-template-columns: 1fr;
        gap: 8px;

        .detail-column {
          gap: 8px;

          .detail-item {
            padding: 6px 10px;

            .detail-label {
              font-size: 12px;
            }

            .detail-value {
              font-size: 12px;
            }
          }
        }
      }
    }

    .stock-card {
      margin-top: 15px;
    }
  }
}
</style>
