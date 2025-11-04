<template>
  <div class="motion-demo">
    <el-card class="demo-card">
      <template #header>
        <div class="card-header">
          <span>📱 陀螺仪和运动传感器</span>
          <el-switch
            v-model="isTracking"
            @change="toggleTracking"
            active-text="监听中"
            inactive-text="已停止"
          />
        </div>
      </template>

      <div class="sensor-data">
        <!-- 屏幕方向 -->
        <div class="data-section">
          <h3>📐 屏幕方向</h3>
          <el-descriptions :column="2" border>
            <el-descriptions-item label="当前方向">
              {{ orientationText }}
            </el-descriptions-item>
            <el-descriptions-item label="角度">
              {{ orientation.angle }}°
            </el-descriptions-item>
          </el-descriptions>
        </div>

        <!-- 加速度计 -->
        <div class="data-section">
          <h3>🎯 加速度计</h3>
          <el-descriptions :column="3" border>
            <el-descriptions-item label="X 轴">
              {{ acceleration.x.toFixed(3) }} m/s²
            </el-descriptions-item>
            <el-descriptions-item label="Y 轴">
              {{ acceleration.y.toFixed(3) }} m/s²
            </el-descriptions-item>
            <el-descriptions-item label="Z 轴">
              {{ acceleration.z.toFixed(3) }} m/s²
            </el-descriptions-item>
          </el-descriptions>
          
          <!-- 加速度可视化 -->
          <div class="visual-indicator">
            <div class="ball" :style="ballStyle"></div>
          </div>
        </div>

        <!-- 陀螺仪 -->
        <div class="data-section">
          <h3>🔄 陀螺仪（旋转速率）</h3>
          <el-descriptions :column="3" border>
            <el-descriptions-item label="Alpha (Z)">
              {{ rotationRate.alpha.toFixed(3) }} °/s
            </el-descriptions-item>
            <el-descriptions-item label="Beta (X)">
              {{ rotationRate.beta.toFixed(3) }} °/s
            </el-descriptions-item>
            <el-descriptions-item label="Gamma (Y)">
              {{ rotationRate.gamma.toFixed(3) }} °/s
            </el-descriptions-item>
          </el-descriptions>
        </div>

        <!-- 设备朝向 -->
        <div class="data-section">
          <h3>🧭 设备朝向</h3>
          <el-descriptions :column="3" border>
            <el-descriptions-item label="Alpha">
              {{ deviceOrientation.alpha.toFixed(1) }}°
            </el-descriptions-item>
            <el-descriptions-item label="Beta">
              {{ deviceOrientation.beta.toFixed(1) }}°
            </el-descriptions-item>
            <el-descriptions-item label="Gamma">
              {{ deviceOrientation.gamma.toFixed(1) }}°
            </el-descriptions-item>
          </el-descriptions>
          
          <!-- 3D 可视化指示器 -->
          <div class="orientation-visual">
            <div 
              class="device-model" 
              :style="deviceModelStyle"
            >
              📱
            </div>
          </div>
        </div>

        <!-- 提示信息 -->
        <el-alert
          v-if="!isSupported"
          title="设备不支持运动传感器"
          type="warning"
          :closable="false"
          show-icon
        />
        
        <el-alert
          v-if="error"
          :title="error"
          type="error"
          :closable="false"
          show-icon
        />
      </div>
    </el-card>

    <!-- 使用说明 -->
    <el-card class="info-card">
      <template #header>
        <span>📖 使用说明</span>
      </template>
      <el-space direction="vertical" :size="10">
        <div>
          <el-tag type="success">屏幕旋转</el-tag>
          旋转设备查看屏幕自动适应不同方向
        </div>
        <div>
          <el-tag type="primary">加速度计</el-tag>
          移动设备查看 X、Y、Z 轴的加速度变化
        </div>
        <div>
          <el-tag type="warning">陀螺仪</el-tag>
          旋转设备查看角速度变化
        </div>
        <div>
          <el-tag type="info">设备朝向</el-tag>
          倾斜设备查看 Alpha、Beta、Gamma 角度
        </div>
      </el-space>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { Motion } from '@capacitor/motion'
import { ElMessage } from 'element-plus'

// 状态管理
const isTracking = ref(false)
const isSupported = ref(true)
const error = ref('')

// 传感器数据
const acceleration = ref({ x: 0, y: 0, z: 0 })
const rotationRate = ref({ alpha: 0, beta: 0, gamma: 0 })
const deviceOrientation = ref({ alpha: 0, beta: 0, gamma: 0 })
const orientation = ref({ angle: 0, type: 'portrait-primary' })

let accelListenerHandle: any = null
let orientationListenerHandle: any = null
let screenOrientationListener: ((event: any) => void) | null = null

// 屏幕方向文本
const orientationText = computed(() => {
  const typeMap: Record<string, string> = {
    'portrait-primary': '竖屏（正常）',
    'portrait-secondary': '竖屏（倒置）',
    'landscape-primary': '横屏（正常）',
    'landscape-secondary': '横屏（倒置）'
  }
  return typeMap[orientation.value.type] || orientation.value.type
})

// 小球样式（基于加速度）
const ballStyle = computed(() => {
  const maxMove = 100
  const x = Math.max(-maxMove, Math.min(maxMove, acceleration.value.x * 20))
  const y = Math.max(-maxMove, Math.min(maxMove, acceleration.value.y * 20))
  
  return {
    transform: `translate(${x}px, ${y}px)`
  }
})

// 设备模型样式（基于朝向）
const deviceModelStyle = computed(() => {
  const alpha = deviceOrientation.value.alpha
  const beta = deviceOrientation.value.beta
  const gamma = deviceOrientation.value.gamma
  
  return {
    transform: `
      rotateZ(${alpha}deg)
      rotateX(${beta}deg)
      rotateY(${gamma}deg)
    `
  }
})

// 开始监听传感器
const startTracking = async () => {
  try {
    // 开始监听运动事件（加速度和陀螺仪）
    accelListenerHandle = await Motion.addListener('accel', (event) => {
      // 加速度数据
      acceleration.value = {
        x: event.accelerationIncludingGravity?.x || 0,
        y: event.accelerationIncludingGravity?.y || 0,
        z: event.accelerationIncludingGravity?.z || 0
      }

      // 旋转速率（陀螺仪）
      if (event.rotationRate) {
        rotationRate.value = {
          alpha: event.rotationRate.alpha || 0,
          beta: event.rotationRate.beta || 0,
          gamma: event.rotationRate.gamma || 0
        }
      }
    })

    // 开始监听设备朝向
    orientationListenerHandle = await Motion.addListener('orientation', (event) => {
      deviceOrientation.value = {
        alpha: event.alpha || 0,
        beta: event.beta || 0,
        gamma: event.gamma || 0
      }
    })

    // 监听屏幕方向变化
    if (window.screen && window.screen.orientation) {
      screenOrientationListener = () => {
        orientation.value = {
          angle: window.screen.orientation.angle,
          type: window.screen.orientation.type
        }
      }
      window.screen.orientation.addEventListener('change', screenOrientationListener)
      
      // 初始化当前方向
      orientation.value = {
        angle: window.screen.orientation.angle,
        type: window.screen.orientation.type
      }
    }

    ElMessage.success('传感器监听已启动')
  } catch (err: any) {
    error.value = err.message || '无法启动传感器'
    isSupported.value = false
    isTracking.value = false
    ElMessage.error(error.value)
    console.error('Motion tracking error:', err)
  }
}

// 停止监听传感器
const stopTracking = async () => {
  try {
    if (accelListenerHandle) {
      await accelListenerHandle.remove()
      accelListenerHandle = null
    }

    if (orientationListenerHandle) {
      await orientationListenerHandle.remove()
      orientationListenerHandle = null
    }

    if (screenOrientationListener && window.screen?.orientation) {
      window.screen.orientation.removeEventListener('change', screenOrientationListener)
      screenOrientationListener = null
    }

    // 重置数据
    acceleration.value = { x: 0, y: 0, z: 0 }
    rotationRate.value = { alpha: 0, beta: 0, gamma: 0 }
    deviceOrientation.value = { alpha: 0, beta: 0, gamma: 0 }

    ElMessage.info('传感器监听已停止')
  } catch (err: any) {
    console.error('Stop tracking error:', err)
  }
}

// 切换监听状态
const toggleTracking = async (value: boolean | string | number) => {
  const boolValue = Boolean(value)
  if (boolValue) {
    await startTracking()
  } else {
    await stopTracking()
  }
}

onMounted(() => {
  // 自动检查支持情况
  if (!('DeviceMotionEvent' in window) && !('DeviceOrientationEvent' in window)) {
    isSupported.value = false
    error.value = '当前设备或浏览器不支持运动传感器'
  }
})

onUnmounted(() => {
  if (isTracking.value) {
    stopTracking()
  }
})
</script>

<style scoped lang="scss">
.motion-demo {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;

  .demo-card {
    margin-bottom: 20px;

    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-weight: bold;
      font-size: 16px;
    }
  }

  .sensor-data {
    .data-section {
      margin-bottom: 30px;

      h3 {
        margin: 0 0 15px 0;
        color: #409eff;
        font-size: 16px;
      }

      .el-descriptions {
        margin-bottom: 15px;
      }
    }

    // 加速度可视化
    .visual-indicator {
      position: relative;
      width: 100%;
      height: 200px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 8px;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;

      .ball {
        width: 40px;
        height: 40px;
        background: #fff;
        border-radius: 50%;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        transition: transform 0.1s ease-out;
      }
    }

    // 设备朝向可视化
    .orientation-visual {
      position: relative;
      width: 100%;
      height: 200px;
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      perspective: 1000px;

      .device-model {
        font-size: 60px;
        transition: transform 0.2s ease-out;
        transform-style: preserve-3d;
      }
    }
  }

  .info-card {
    .el-tag {
      margin-right: 8px;
    }
  }
}

// 响应式适配
@media (max-width: 768px) {
  .motion-demo {
    padding: 10px;

    .card-header {
      flex-direction: column;
      gap: 10px;
      align-items: flex-start !important;
    }
  }
}
</style>
