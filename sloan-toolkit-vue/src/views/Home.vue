<script setup lang="ts">
import { ref } from 'vue'
import InfoPlugin from '@/plugins/info/InfoPlugin.vue'
import LogAnalyzer from '@/plugins/log-analyzer/LogAnalyzer.vue'

const title = ref('sloan的工具集')
const activeTab = ref('info')
</script>

<template>
  <div class="home">
    <el-container>
      <el-header>
        <div class="header-content">
          <h1>{{ title }}</h1>
          <el-button type="primary" @click="$router.push('/config')">
            ⚙️ 插件配置
          </el-button>
        </div>
      </el-header>
      <el-main>
        <!-- 插件选项卡 -->
        <el-tabs v-model="activeTab" type="border-card" class="plugin-tabs">
          <el-tab-pane label="ℹ️ 信息" name="info">
            <InfoPlugin />
          </el-tab-pane>
          <el-tab-pane label="📊 日志分析" name="log-analyzer">
            <LogAnalyzer />
          </el-tab-pane>
        </el-tabs>
      </el-main>
    </el-container>
  </div>
</template>

<style scoped lang="scss">
.home {
  .el-header {
    display: flex;
    align-items: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);

    .header-content {
      width: 100%;
      display: flex;
      justify-content: space-between;
      align-items: center;

      h1 {
        margin: 0;
        font-size: 24px;
        font-weight: 600;
      }
    }
  }
  
  .el-main {
    padding: 20px;
    background: #f5f7fa;
    min-height: calc(100vh - 60px);
  }

  :deep(.el-tabs) {
    background: white;
    box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
    border-radius: 8px;
  }

  .plugin-tabs {
    :deep(.el-tabs__header) {
      margin: 0;
      border-radius: 8px 8px 0 0;
    }

    :deep(.el-tabs__item) {
      font-size: 16px;
      font-weight: 500;
      padding: 0 30px;
      transition: all 0.3s;

      &:hover {
        color: #409eff;
      }

      &.is-active {
        color: #409eff;
      }
    }

    :deep(.el-tabs__content) {
      padding: 0;
    }
  }
}
</style>
