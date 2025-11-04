<template>
  <div class="in-app-browser">
    <el-card>
      <template #header>
        <div class="browser-header">
          <h3>🌐 内置浏览器</h3>
        </div>
      </template>

      <!-- URL 输入栏 -->
      <div class="url-bar">
        <el-input
          v-model="currentUrl"
          placeholder="输入网址，如: https://www.baidu.com"
          @keyup.enter="loadUrl"
          clearable
        >
          <template #prepend>
            <el-icon><Link /></el-icon>
          </template>
          <template #append>
            <el-button @click="loadUrl" :loading="loading">
              {{ loading ? '加载中' : '访问' }}
            </el-button>
          </template>
        </el-input>
      </div>

      <!-- 工具栏 -->
      <div class="toolbar">
        <el-button-group>
          <el-button @click="goBack" :disabled="!canGoBack" size="small">
            <el-icon><ArrowLeft /></el-icon>
            后退
          </el-button>
          <el-button @click="goForward" :disabled="!canGoForward" size="small">
            前进
            <el-icon><ArrowRight /></el-icon>
          </el-button>
          <el-button @click="reload" size="small">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
          <el-button @click="stopLoading" v-if="loading" size="small" type="danger">
            <el-icon><Close /></el-icon>
            停止
          </el-button>
        </el-button-group>

        <el-button-group style="margin-left: 10px">
          <el-button @click="openInSystemBrowser" size="small" type="primary">
            <el-icon><ChromeFilled /></el-icon>
            系统浏览器
          </el-button>
          <el-button @click="shareUrl" size="small">
            <el-icon><Share /></el-icon>
            分享
          </el-button>
        </el-button-group>
      </div>

      <!-- 快速链接 -->
      <div class="quick-links">
        <el-space wrap>
          <el-tag
            v-for="link in quickLinks"
            :key="link.url"
            @click="loadQuickLink(link.url)"
            style="cursor: pointer"
            effect="plain"
          >
            {{ link.name }}
          </el-tag>
        </el-space>
      </div>

      <!-- 浏览器视图容器 -->
      <div class="browser-view" ref="browserContainer">
        <el-empty v-if="!isLoaded" description="输入网址开始浏览">
          <el-button type="primary" @click="loadQuickLink('https://www.baidu.com')">
            访问百度
          </el-button>
        </el-empty>

        <!-- iframe WebView（所有环境） -->
        <iframe
          v-if="isLoaded"
          :src="loadedUrl"
          frameborder="0"
          class="browser-iframe"
          @load="onIframeLoad"
          allow="geolocation; microphone; camera"
          sandbox="allow-same-origin allow-scripts allow-popups allow-forms"
        ></iframe>

        <!-- 加载提示 -->
        <div v-if="loading" class="loading-overlay">
          <el-icon class="loading-icon"><Loading /></el-icon>
          <div>加载中...</div>
        </div>
      </div>

      <!-- 历史记录 -->
      <el-collapse v-if="history.length > 0" style="margin-top: 20px">
        <el-collapse-item title="📖 浏览历史" name="history">
          <el-timeline>
            <el-timeline-item
              v-for="(item, index) in history"
              :key="index"
              :timestamp="item.time"
              placement="top"
            >
              <el-link @click="loadQuickLink(item.url)" :underline="false">
                {{ item.title || item.url }}
              </el-link>
            </el-timeline-item>
          </el-timeline>
        </el-collapse-item>
      </el-collapse>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  Link,
  ArrowLeft,
  ArrowRight,
  Refresh,
  Close,
  ChromeFilled,
  Share,
  Loading
} from '@element-plus/icons-vue'

// 获取路由参数
const route = useRoute()

// 状态管理
const currentUrl = ref('')
const loadedUrl = ref('')
const isLoaded = ref(false)
const loading = ref(false)
const canGoBack = ref(false)
const canGoForward = ref(false)

// 历史记录
interface HistoryItem {
  url: string
  title?: string
  time: string
}

const history = ref<HistoryItem[]>([])

// 快速链接
const quickLinks = [
  { name: '百度', url: 'https://www.baidu.com' },
  { name: '必应', url: 'https://www.bing.com' },
  { name: '知乎', url: 'https://www.zhihu.com' },
  { name: '微博', url: 'https://weibo.com' },
  { name: 'GitHub', url: 'https://github.com' },
  { name: 'StackOverflow', url: 'https://stackoverflow.com' }
]

// 检测运行环境
onMounted(() => {
  // 从 localStorage 加载历史记录
  const savedHistory = localStorage.getItem('browser-history')
  if (savedHistory) {
    try {
      history.value = JSON.parse(savedHistory)
    } catch (e) {
      console.error('Failed to load history:', e)
    }
  }
  
  // 检查 URL 参数，自动加载
  if (route.query.url) {
    const urlFromQuery = decodeURIComponent(route.query.url as string)
    currentUrl.value = urlFromQuery
    loadUrl()
  }
})

// 保存历史记录
const saveHistory = () => {
  try {
    localStorage.setItem('browser-history', JSON.stringify(history.value))
  } catch (e) {
    console.error('Failed to save history:', e)
  }
}

// 添加到历史记录
const addToHistory = (url: string, title?: string) => {
  const now = new Date()
  const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
  
  history.value.unshift({
    url,
    title,
    time: timeStr
  })

  // 最多保留 20 条历史
  if (history.value.length > 20) {
    history.value = history.value.slice(0, 20)
  }

  saveHistory()
}

// 验证 URL
const validateUrl = (url: string): string => {
  let validUrl = url.trim()
  
  // 如果没有协议，添加 https://
  if (!validUrl.startsWith('http://') && !validUrl.startsWith('https://')) {
    validUrl = 'https://' + validUrl
  }
  
  // 验证 URL 格式
  try {
    new URL(validUrl)
    return validUrl
  } catch (e) {
    throw new Error('无效的网址格式')
  }
}

// 加载网址
const loadUrl = async () => {
  if (!currentUrl.value) {
    ElMessage.warning('请输入网址')
    return
  }

  try {
    const url = validateUrl(currentUrl.value)
    loading.value = true

    // 统一使用 iframe WebView（适用于所有平台）
    loadedUrl.value = url
    isLoaded.value = true
    addToHistory(url)
  } catch (error: any) {
    ElMessage.error(error.message || '加载失败')
    loading.value = false
  }
}

// iframe 加载完成
const onIframeLoad = () => {
  loading.value = false
  canGoBack.value = true
}

// 快速链接
const loadQuickLink = (url: string) => {
  currentUrl.value = url
  loadUrl()
}

// 后退
const goBack = () => {
  window.history.back()
}

// 前进
const goForward = () => {
  window.history.forward()
}

// 刷新
const reload = () => {
  if (isLoaded.value) {
    loadedUrl.value = loadedUrl.value + '?' + Date.now()
    loading.value = true
  }
}

// 停止加载
const stopLoading = () => {
  loading.value = false
}

// 在系统浏览器打开
const openInSystemBrowser = () => {
  if (!loadedUrl.value && !currentUrl.value) {
    ElMessage.warning('请先输入网址')
    return
  }

  const url = loadedUrl.value || currentUrl.value

  try {
    // 使用 window.open 在新窗口打开
    window.open(validateUrl(url), '_blank')
  } catch (error) {
    ElMessage.error('打开失败')
  }
}

// 分享链接
const shareUrl = async () => {
  const url = loadedUrl.value || currentUrl.value
  
  if (!url) {
    ElMessage.warning('没有可分享的链接')
    return
  }

  try {
    if (navigator.share) {
      await navigator.share({
        title: '分享链接',
        url: url
      })
    } else {
      // 复制到剪贴板
      await navigator.clipboard.writeText(url)
      ElMessage.success('链接已复制到剪贴板')
    }
  } catch (error) {
    console.error('Share failed:', error)
  }
}

onUnmounted(() => {
  // 清理
})
</script>

<style scoped lang="scss">
.in-app-browser {
  .browser-header {
    display: flex;
    align-items: center;
    justify-content: space-between;

    h3 {
      margin: 0;
      font-size: 18px;
    }
  }

  .url-bar {
    margin-bottom: 15px;
  }

  .toolbar {
    display: flex;
    margin-bottom: 15px;
    flex-wrap: wrap;
    gap: 10px;
  }

  .quick-links {
    margin-bottom: 20px;
    padding: 10px;
    background: #f5f7fa;
    border-radius: 4px;
  }

  .browser-view {
    position: relative;
    width: 100%;
    height: 600px;
    background: #fff;
    border: 1px solid #dcdfe6;
    border-radius: 4px;
    overflow: hidden;

    .browser-iframe {
      width: 100%;
      height: 100%;
    }

    .loading-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(255, 255, 255, 0.9);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      font-size: 16px;
      color: #409eff;

      .loading-icon {
        font-size: 40px;
        margin-bottom: 10px;
        animation: rotating 2s linear infinite;
      }
    }
  }
}

@keyframes rotating {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

// 响应式
@media (max-width: 768px) {
  .in-app-browser {
    .toolbar {
      .el-button-group {
        width: 100%;

        .el-button {
          flex: 1;
        }
      }
    }

    .browser-view {
      height: 500px;
    }
  }
}
</style>
