# 📱 陀螺仪和屏幕旋转功能指南

## ✨ 功能概述

应用现已支持完整的设备运动传感器和屏幕自动旋转功能：

- 🔄 **陀螺仪** - 检测设备旋转速率（Alpha, Beta, Gamma）
- 🎯 **加速度计** - 检测设备在 X、Y、Z 轴的加速度
- 🧭 **设备朝向** - 检测设备的空间方向
- 📐 **屏幕旋转** - 自动适应竖屏/横屏方向

---

## 🔧 技术实现

### 1. Capacitor Motion 插件

已安装 `@capacitor/motion` 插件用于访问设备传感器：

```json
{
  "dependencies": {
    "@capacitor/motion": "^7.x.x"
  }
}
```

### 2. Android 配置

#### AndroidManifest.xml

```xml
<activity
    android:screenOrientation="sensor"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|..."
    ...>
</activity>

<!-- 传感器权限声明 -->
<uses-feature android:name="android.hardware.sensor.accelerometer" android:required="false" />
<uses-feature android:name="android.hardware.sensor.gyroscope" android:required="false" />
```

**关键配置说明**：

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `android:screenOrientation` | `sensor` | 根据设备物理方向自动旋转屏幕 |
| `android:configChanges` | `orientation\|screenSize\|...` | 防止旋转时 Activity 重建，提升性能 |
| `android:required` | `false` | 传感器为可选功能，无传感器设备也能安装 |

#### 屏幕方向选项

```xml
<!-- 可用的 screenOrientation 值 -->
sensor          - 自动根据传感器旋转（推荐）✅
portrait        - 仅竖屏
landscape       - 仅横屏
sensorPortrait  - 竖屏，但可上下翻转
sensorLandscape - 横屏，但可左右翻转
fullSensor      - 支持所有4个方向
nosensor        - 忽略传感器
unspecified     - 系统默认
```

---

## 🎮 使用方法

### 1. 访问演示页面

在应用主页点击 **"📱 陀螺仪演示"** 按钮，或访问路由：

```
/motion
```

### 2. 启动传感器监听

- 点击页面顶部的 **"监听中/已停止"** 开关
- 授权传感器权限（首次使用）
- 移动设备查看实时数据

### 3. 查看传感器数据

#### 屏幕方向
- 当前方向（竖屏/横屏）
- 旋转角度（0°, 90°, 180°, 270°）

#### 加速度计
- X 轴：左右倾斜
- Y 轴：前后倾斜  
- Z 轴：上下移动
- 可视化：小球随重力方向移动

#### 陀螺仪（旋转速率）
- Alpha (Z轴)：围绕垂直轴旋转
- Beta (X轴)：左右旋转
- Gamma (Y轴)：前后旋转

#### 设备朝向
- Alpha：指南针方向 (0-360°)
- Beta：前后倾斜 (-180 - 180°)
- Gamma：左右倾斜 (-90 - 90°)
- 3D 可视化：📱 emoji 随设备旋转

---

## 📊 API 使用示例

### 监听加速度和陀螺仪

```typescript
import { Motion } from '@capacitor/motion'

// 开始监听
const accelHandler = await Motion.addListener('accel', (event) => {
  console.log('加速度:', event.accelerationIncludingGravity)
  // { x: 0.0, y: 0.0, z: 9.8 }
  
  console.log('旋转速率:', event.rotationRate)
  // { alpha: 0.0, beta: 0.0, gamma: 0.0 }
})

// 停止监听
await accelHandler.remove()
```

### 监听设备朝向

```typescript
const orientationHandler = await Motion.addListener('orientation', (event) => {
  console.log('朝向:', event)
  // { alpha: 45, beta: 10, gamma: -5 }
})

await orientationHandler.remove()
```

### 监听屏幕方向变化

```typescript
if (window.screen?.orientation) {
  window.screen.orientation.addEventListener('change', () => {
    const angle = window.screen.orientation.angle
    const type = window.screen.orientation.type
    console.log(`屏幕旋转到: ${type} (${angle}°)`)
  })
}
```

---

## 🎯 实际应用场景

### 1. 游戏控制

```typescript
// 使用设备倾斜控制游戏角色
Motion.addListener('accel', (event) => {
  const tiltX = event.accelerationIncludingGravity.x
  const tiltY = event.accelerationIncludingGravity.y
  
  if (tiltX > 2) {
    // 向右移动
  } else if (tiltX < -2) {
    // 向左移动
  }
})
```

### 2. 计步器

```typescript
let lastZ = 0
let steps = 0

Motion.addListener('accel', (event) => {
  const z = event.accelerationIncludingGravity.z || 0
  const diff = Math.abs(z - lastZ)
  
  if (diff > 5) { // 检测显著的 Z 轴变化
    steps++
  }
  lastZ = z
})
```

### 3. 水平仪

```typescript
Motion.addListener('orientation', (event) => {
  const beta = event.beta || 0  // 前后倾斜
  const gamma = event.gamma || 0 // 左右倾斜
  
  if (Math.abs(beta) < 2 && Math.abs(gamma) < 2) {
    console.log('设备处于水平状态')
  }
})
```

### 4. 指南针

```typescript
Motion.addListener('orientation', (event) => {
  const alpha = event.alpha || 0
  const direction = getDirection(alpha)
  console.log(`指向: ${direction}`)
})

function getDirection(alpha: number): string {
  if (alpha < 45 || alpha >= 315) return '北'
  if (alpha >= 45 && alpha < 135) return '东'
  if (alpha >= 135 && alpha < 225) return '南'
  return '西'
}
```

### 5. 摇一摇功能

```typescript
let lastAccel = { x: 0, y: 0, z: 0 }

Motion.addListener('accel', (event) => {
  const accel = event.accelerationIncludingGravity
  const deltaX = Math.abs(accel.x - lastAccel.x)
  const deltaY = Math.abs(accel.y - lastAccel.y)
  const deltaZ = Math.abs(accel.z - lastAccel.z)
  
  const shakeThreshold = 15
  if (deltaX > shakeThreshold || deltaY > shakeThreshold || deltaZ > shakeThreshold) {
    console.log('检测到摇晃！')
    // 触发摇一摇功能
  }
  
  lastAccel = { ...accel }
})
```

---

## 🔒 权限管理

### Android 权限

传感器访问无需运行时权限，但需在 Manifest 声明：

```xml
<uses-feature 
    android:name="android.hardware.sensor.accelerometer" 
    android:required="false" />
<uses-feature 
    android:name="android.hardware.sensor.gyroscope" 
    android:required="false" />
```

**`required="false"` 的作用**：
- ✅ 允许无传感器设备安装应用
- ✅ 需在代码中检查传感器可用性
- ❌ 如果设为 `true`，无传感器设备无法从商店安装

### 检查传感器可用性

```typescript
try {
  await Motion.addListener('accel', handler)
  // 传感器可用
} catch (error) {
  console.error('设备不支持运动传感器')
  // 提供降级方案
}
```

---

## 🐛 常见问题

### Q1: 屏幕不旋转？

**检查项**：
1. AndroidManifest.xml 中是否设置 `android:screenOrientation="sensor"`
2. 设备系统设置中是否启用了"自动旋转"
3. 应用是否在全屏模式（某些模式可能禁用旋转）

**解决方法**：
```xml
<!-- AndroidManifest.xml -->
<activity android:screenOrientation="sensor" ...>
```

### Q2: 传感器数据不更新？

**可能原因**：
- 设备不支持传感器
- 未正确启动监听
- 监听器被过早移除

**解决方法**：
```typescript
// 确保监听器在组件生命周期内保持
onMounted(async () => {
  handler = await Motion.addListener('accel', callback)
})

onUnmounted(async () => {
  if (handler) {
    await handler.remove()
  }
})
```

### Q3: 性能问题/耗电量大？

**原因**：传感器高频率更新（通常 60Hz）

**优化方法**：
```typescript
let lastUpdate = 0
const updateInterval = 100 // 限制为每 100ms 更新一次

Motion.addListener('accel', (event) => {
  const now = Date.now()
  if (now - lastUpdate < updateInterval) return
  
  lastUpdate = now
  // 处理数据
})
```

### Q4: Web 浏览器中无法使用？

**说明**：
- Web 浏览器需要 HTTPS 才能访问传感器
- 某些浏览器需要用户交互（点击）后才能启用
- iOS Safari 需要用户授权

**Web 降级方案**：
```typescript
if ('DeviceMotionEvent' in window) {
  // 使用原生 Web API
  window.addEventListener('devicemotion', handler)
} else {
  // 提示不支持
}
```

---

## 📐 坐标系说明

### 设备坐标系

```
         Y (设备顶部)
         ↑
         |
         |
         └────→ X (设备右侧)
        /
       /
      Z (垂直屏幕向外)
```

### 旋转角度

- **Alpha (α)**: 绕 Z 轴旋转，0-360°（指南针方向）
  - 0° = 北
  - 90° = 东
  - 180° = 南
  - 270° = 西

- **Beta (β)**: 绕 X 轴旋转，-180° 至 180°
  - 0° = 设备平放
  - 90° = 设备直立
  - -90° = 设备倒置

- **Gamma (γ)**: 绕 Y 轴旋转，-90° 至 90°
  - 0° = 设备平放
  - 90° = 设备向右倾斜
  - -90° = 设备向左倾斜

---

## 🔧 高级配置

### 锁定特定方向

如果某些页面不需要旋转，可以动态设置：

```typescript
// Capacitor 没有直接 API，需要使用原生代码或插件
// 临时方案：在 AndroidManifest 中为特定 Activity 设置方向
```

### 自定义旋转行为

```typescript
// 监听方向变化并执行自定义逻辑
window.screen.orientation.addEventListener('change', () => {
  const type = window.screen.orientation.type
  
  if (type.includes('landscape')) {
    // 横屏模式：调整布局
    applyLandscapeLayout()
  } else {
    // 竖屏模式：恢复默认布局
    applyPortraitLayout()
  }
})
```

### 防抖处理

```typescript
import { debounce } from 'lodash-es'

const debouncedHandler = debounce((event) => {
  // 处理传感器数据
}, 100) // 100ms 防抖

Motion.addListener('accel', debouncedHandler)
```

---

## 📊 性能优化建议

1. **按需启用**：只在需要时启动传感器监听
2. **及时清理**：组件卸载时移除监听器
3. **降低频率**：使用节流/防抖减少更新频率
4. **条件处理**：仅在数据变化显著时更新 UI
5. **后台暂停**：应用进入后台时暂停传感器

```typescript
// 应用生命周期管理
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    // 暂停传感器
    stopTracking()
  } else {
    // 恢复传感器
    startTracking()
  }
})
```

---

## 📚 相关资源

### 官方文档

- [Capacitor Motion Plugin](https://capacitorjs.com/docs/apis/motion)
- [Android Sensors API](https://developer.android.com/guide/topics/sensors/sensors_overview)
- [Screen Orientation API](https://developer.mozilla.org/en-US/docs/Web/API/Screen_Orientation_API)

### 示例代码

- 本项目: `src/components/MotionDemo.vue`
- 路由配置: `src/router/index.ts`

### 相关指南

- [Android 开发指南](./ANDROID_CAPACITOR_GUIDE.md)
- [Capacitor 环境配置](./CAPACITOR_ENVIRONMENT_SETUP.md)

---

## ✅ 功能清单

- [x] Capacitor Motion 插件集成
- [x] Android 屏幕旋转支持（sensor 模式）
- [x] 传感器权限声明
- [x] 演示组件（MotionDemo.vue）
- [x] 路由配置
- [x] 主页入口按钮
- [x] 实时数据显示
- [x] 可视化指示器
- [x] 权限处理
- [x] 错误提示
- [x] 完整文档

---

## 🎯 下一步

1. **测试功能**：在真实设备上测试所有传感器
2. **构建 APK**：`cd android && .\gradlew.bat assembleDebug`
3. **安装测试**：`adb install app-debug.apk`
4. **旋转设备**：查看屏幕自动适应
5. **查看演示**：点击"陀螺仪演示"测试传感器

---

<div align="center">

**📱 现在你的应用已支持完整的运动传感器和屏幕旋转功能！**

</div>
