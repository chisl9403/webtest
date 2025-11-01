<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { Setting, Check, Close } from '@element-plus/icons-vue'

interface Plugin {
  id: string
  name: string
  icon: string
  description: string
  enabled: boolean
  version: string
}

const plugins = reactive<Plugin[]>([
  {
    id: 'info',
    name: '信息',
    icon: 'ℹ️',
    description: '查询天气、股票等综合信息，提供详细数据展示',
    enabled: true,
    version: '2.0.0'
  },
  {
    id: 'log-analyzer',
    name: 'PM:INFO 日志分析',
    icon: '📊',
    description: '分析 PM:INFO 日志文件，生成可视化图表和统计数据',
    enabled: true,
    version: '2.0.0'
  }
])

const hasChanges = ref(false)

// 切换插件状态
const togglePlugin = (plugin: Plugin) => {
  plugin.enabled = !plugin.enabled
  hasChanges.value = true
  ElMessage.info(`${plugin.name} 已${plugin.enabled ? '启用' : '禁用'}`)
}

// 保存配置
const saveConfig = () => {
  // 模拟保存配置
  setTimeout(() => {
    ElMessage.success('配置已保存')
    hasChanges.value = false
  }, 500)
}

// 重置配置
const resetConfig = () => {
  plugins.forEach(p => p.enabled = true)
  hasChanges.value = false
  ElMessage.success('已重置为默认配置')
}
</script>

<template>
  <div class="plugin-config">
    <el-container>
      <el-header>
        <div class="header-content">
          <div class="header-left">
            <el-icon class="header-icon"><Setting /></el-icon>
            <h1>插件配置</h1>
          </div>
          <div class="header-actions">
            <el-button @click="$router.push('/')">返回主页</el-button>
            <el-button
              type="primary"
              :disabled="!hasChanges"
              @click="saveConfig"
            >
              保存配置
            </el-button>
          </div>
        </div>
      </el-header>
      <el-main>
        <div class="config-container">
          <el-alert
            v-if="hasChanges"
            title="您有未保存的更改"
            type="warning"
            :closable="false"
            show-icon
            class="alert-changes"
          />

          <div class="plugins-grid">
            <el-card
              v-for="plugin in plugins"
              :key="plugin.id"
              class="plugin-card"
              :class="{ disabled: !plugin.enabled }"
              shadow="hover"
            >
              <div class="plugin-header">
                <div class="plugin-info">
                  <span class="plugin-icon">{{ plugin.icon }}</span>
                  <div class="plugin-details">
                    <h3 class="plugin-name">{{ plugin.name }}</h3>
                    <span class="plugin-version">v{{ plugin.version }}</span>
                  </div>
                </div>
                <el-switch
                  v-model="plugin.enabled"
                  size="large"
                  :active-icon="Check"
                  :inactive-icon="Close"
                  @change="togglePlugin(plugin)"
                />
              </div>
              <p class="plugin-description">{{ plugin.description }}</p>
              <div class="plugin-status">
                <el-tag
                  :type="plugin.enabled ? 'success' : 'info'"
                  size="small"
                  effect="plain"
                >
                  {{ plugin.enabled ? '已启用' : '已禁用' }}
                </el-tag>
              </div>
            </el-card>
          </div>

          <div class="actions-footer">
            <el-button @click="resetConfig">重置为默认</el-button>
          </div>
        </div>
      </el-main>
    </el-container>
  </div>
</template>

<style scoped lang="scss">
.plugin-config {
  min-height: 100vh;

  .el-header {
    display: flex;
    align-items: center;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
    padding: 0 30px;

    .header-content {
      width: 100%;
      display: flex;
      justify-content: space-between;
      align-items: center;

      .header-left {
        display: flex;
        align-items: center;
        gap: 15px;

        .header-icon {
          font-size: 28px;
        }

        h1 {
          margin: 0;
          font-size: 24px;
          font-weight: 600;
        }
      }

      .header-actions {
        display: flex;
        gap: 10px;
      }
    }
  }

  .el-main {
    padding: 30px;
    background: #f5f7fa;
    min-height: calc(100vh - 60px);
  }

  .config-container {
    max-width: 1200px;
    margin: 0 auto;

    .alert-changes {
      margin-bottom: 20px;
    }

    .plugins-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
      gap: 20px;
      margin-bottom: 30px;

      .plugin-card {
        border-radius: 12px;
        transition: all 0.3s;

        &:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
        }

        &.disabled {
          opacity: 0.6;

          .plugin-icon {
            filter: grayscale(1);
          }
        }

        .plugin-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 15px;

          .plugin-info {
            display: flex;
            align-items: center;
            gap: 15px;

            .plugin-icon {
              font-size: 48px;
              transition: all 0.3s;
            }

            .plugin-details {
              .plugin-name {
                margin: 0 0 5px 0;
                font-size: 18px;
                font-weight: 600;
                color: #303133;
              }

              .plugin-version {
                font-size: 12px;
                color: #909399;
                background: #f0f0f0;
                padding: 2px 8px;
                border-radius: 10px;
              }
            }
          }
        }

        .plugin-description {
          margin: 0 0 15px 0;
          font-size: 14px;
          color: #606266;
          line-height: 1.6;
        }

        .plugin-status {
          display: flex;
          justify-content: flex-end;
        }
      }
    }

    .actions-footer {
      display: flex;
      justify-content: center;
      padding-top: 20px;
      border-top: 1px solid #dcdfe6;
    }
  }
}

// 响应式设计
@media (max-width: 768px) {
  .plugin-config {
    .el-header .header-content {
      flex-direction: column;
      gap: 15px;
      padding: 15px 0;

      .header-actions {
        width: 100%;
        justify-content: space-between;
      }
    }

    .el-main {
      padding: 15px;
    }

    .config-container .plugins-grid {
      grid-template-columns: 1fr;
    }
  }
}
</style>
