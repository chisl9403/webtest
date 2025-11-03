# 📱 Capacitor Android App 封装指南

## 🎯 方案概述

使用 Ionic Capacitor 将 Vue 3 + Vite 项目封装为原生 Android App。

## 🚀 快速开始

### 1. 安装 Capacitor CLI

```bash
# 全局安装
npm install -g @capacitor/cli

# 项目内安装
cd sloan-toolkit-vue
npm install @capacitor/core @capacitor/cli
```

### 2. 初始化 Capacitor

```bash
# 初始化 Capacitor 配置
npx cap init "Sloan Toolkit" "com.sloan.toolkit"

# 添加 Android 平台
npm install @capacitor/android
npx cap add android
```

### 3. 配置 capacitor.config.ts

```typescript
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.sloan.toolkit',
  appName: 'Sloan Toolkit',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
    // 开发模式：连接本地服务器
    // url: 'http://192.168.1.100:3000',
    // cleartext: true
  },
  android: {
    allowMixedContent: true,
    captureInput: true,
    webContentsDebuggingEnabled: true
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: "#667eea",
      showSpinner: false
    },
    StatusBar: {
      style: "dark",
      backgroundColor: "#667eea"
    }
  }
};

export default config;
```

### 4. 安装必要插件

```bash
# 基础插件
npm install @capacitor/status-bar @capacitor/splash-screen

# 文件系统插件（用于日志文件）
npm install @capacitor/filesystem

# 网络插件（用于API调用）
npm install @capacitor/network

# 设备信息插件
npm install @capacitor/device

# 应用信息插件
npm install @capacitor/app
```

### 5. 修改 Vite 配置

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  base: './',  // 重要：使用相对路径
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      output: {
        manualChunks: undefined
      }
    }
  },
  server: {
    host: '0.0.0.0',  // 允许局域网访问
    port: 3000
  }
})
```

### 6. 创建 Android App

```bash
# 构建 Web 应用
npm run build

# 同步到 Android
npx cap sync android

# 打开 Android Studio
npx cap open android
```

## 🔧 原生功能集成

### 文件系统集成

```typescript
// src/utils/capacitor-file.ts
import { Filesystem, Directory } from '@capacitor/filesystem';

export class CapacitorFileManager {
  async saveLogFile(filename: string, data: string) {
    try {
      await Filesystem.writeFile({
        path: filename,
        data: data,
        directory: Directory.Documents,
        encoding: 'utf8'
      });
      return true;
    } catch (error) {
      console.error('保存文件失败:', error);
      return false;
    }
  }

  async readLogFile(filename: string) {
    try {
      const result = await Filesystem.readFile({
        path: filename,
        directory: Directory.Documents,
        encoding: 'utf8'
      });
      return result.data;
    } catch (error) {
      console.error('读取文件失败:', error);
      return null;
    }
  }
}
```

### 网络状态检测

```typescript
// src/utils/network.ts
import { Network } from '@capacitor/network';

export class NetworkManager {
  async checkNetworkStatus() {
    const status = await Network.getStatus();
    return {
      connected: status.connected,
      connectionType: status.connectionType
    };
  }

  addNetworkListener(callback: Function) {
    Network.addListener('networkStatusChange', (status) => {
      callback(status);
    });
  }
}
```

### 设备信息获取

```typescript
// src/utils/device.ts
import { Device } from '@capacitor/device';

export class DeviceManager {
  async getDeviceInfo() {
    const info = await Device.getInfo();
    return {
      platform: info.platform,
      model: info.model,
      operatingSystem: info.operatingSystem,
      osVersion: info.osVersion
    };
  }
}
```

## 🎨 App 图标和启动屏幕

### 1. 准备资源文件

```bash
# 创建资源目录
mkdir -p android/app/src/main/res/drawable
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi
```

### 2. 自动生成图标

```bash
# 安装图标生成工具
npm install -g cordova-res

# 准备 1024x1024 的 icon.png 和 2732x2732 的 splash.png
# 放在项目根目录

# 生成所有尺寸的图标
cordova-res android --skip-config --copy
```

### 3. 配置启动屏幕

```xml
<!-- android/app/src/main/res/values/styles.xml -->
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme.NoActionBarLaunch" parent="AppTheme.NoActionBar">
        <item name="android:background">@drawable/splash</item>
    </style>
</resources>
```

## 📦 构建和打包

### 开发调试

```bash
# 实时预览（连接本地服务器）
npx cap run android --livereload --external

# 或者使用 adb 调试
npx cap run android
```

### 生产构建

```bash
# 1. 构建 Web 应用
npm run build

# 2. 同步到 Android
npx cap sync android

# 3. 在 Android Studio 中：
# - 选择 Build > Generate Signed Bundle/APK
# - 选择 APK
# - 创建或选择密钥库
# - 选择 release 构建类型
# - 点击 Finish
```

### 自动化构建脚本

```bash
#!/bin/bash
# build-android.sh

echo "🔨 构建 Android App..."

# 1. 安装依赖
npm install

# 2. 构建 Web 应用
npm run build

# 3. 同步到 Android
npx cap sync android

# 4. 构建 APK
cd android
./gradlew assembleRelease

echo "✅ APK 构建完成："
echo "📱 文件位置: android/app/build/outputs/apk/release/app-release.apk"
```

## 🔧 配置优化

### Android 权限配置

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- 网络权限 -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- 文件系统权限 -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- 可选：相机权限（如果需要扫码功能） -->
    <!-- <uses-permission android:name="android.permission.CAMERA" /> -->
    
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:theme="@style/AppTheme.NoActionBarLaunch">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### ProGuard 代码混淆

```properties
# android/app/proguard-rules.pro
-keep class com.sloan.toolkit.** { *; }
-keep class com.getcapacitor.** { *; }
-keep class com.capacitorjs.** { *; }
-dontwarn com.getcapacitor.**
```

## 🚀 发布到 Google Play

### 1. 准备发布

```bash
# 生成签名密钥
keytool -genkey -v -keystore sloan-toolkit.keystore -alias sloan-toolkit -keyalg RSA -keysize 2048 -validity 10000

# 配置签名（android/app/build.gradle）
android {
    signingConfigs {
        release {
            keyAlias 'sloan-toolkit'
            keyPassword 'your-key-password'
            storeFile file('../sloan-toolkit.keystore')
            storePassword 'your-store-password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 2. 构建 AAB 包

```bash
# Android Studio 或命令行
cd android
./gradlew bundleRelease

# 输出文件：android/app/build/outputs/bundle/release/app-release.aab
```

### 3. Google Play Console

1. 创建应用条目
2. 上传 AAB 文件
3. 填写应用信息、截图、描述
4. 设置内容分级和目标受众
5. 提交审核

## 📊 性能优化

### Bundle 分割

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'element-plus': ['element-plus'],
          'echarts': ['echarts'],
          'vue-vendor': ['vue', 'vue-router', 'pinia']
        }
      }
    }
  }
})
```

### 资源优化

```bash
# 压缩图片
npm install -g imagemin-cli
imagemin src/assets/images/* --out-dir=dist/assets/images --plugin=imagemin-webp

# PWA 缓存策略
npm install @vite-pwa/vite-plugin-pwa
```

## 🔍 调试技巧

### Chrome DevTools

```bash
# 启用 USB 调试
# 在 Chrome 中访问：chrome://inspect/#devices
```

### Logcat 日志

```bash
# 查看应用日志
adb logcat | grep -i "sloan"

# 查看 WebView 日志
adb logcat | grep -i "chromium"
```

### 性能分析

```javascript
// 在 Web 代码中添加性能监控
if (window.performance) {
  console.log('页面加载时间：', window.performance.timing.loadEventEnd - window.performance.timing.navigationStart);
}
```

## 📋 项目清单

- [ ] 安装 Capacitor CLI
- [ ] 配置 capacitor.config.ts
- [ ] 安装必要插件
- [ ] 修改 Vite 配置
- [ ] 准备 App 图标和启动屏幕
- [ ] 配置 Android 权限
- [ ] 测试核心功能
- [ ] 性能优化
- [ ] 生成签名 APK
- [ ] Google Play 发布

## 🆘 常见问题

### Q: 网络请求失败？
A: 检查 `android:usesCleartextTraffic="true"` 和 CORS 配置

### Q: 文件上传不工作？
A: 使用 Capacitor Filesystem API 替代 Web File API

### Q: 图表显示异常？
A: 确保 ECharts 在 WebView 中正确初始化

### Q: 白屏问题？
A: 检查 `base: './'` 配置和资源路径

## 📚 参考资源

- [Capacitor 官方文档](https://capacitorjs.com/)
- [Android 开发指南](https://developer.android.com/)
- [Vue 3 + Capacitor 示例](https://github.com/ionic-team/capacitor-docs)