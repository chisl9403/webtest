#!/bin/bash
# 📱 Android App 快速构建脚本
# 适用于 Sloan Toolkit Vue 项目

set -e  # 遇到错误时退出

echo "🚀 开始构建 Sloan Toolkit Android App"
echo "=================================="

# 检查环境
echo "🔍 检查开发环境..."

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装，请先安装 Node.js 16+"
    exit 1
fi

# 检查 npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm 未安装"
    exit 1
fi

# 检查 Java (Android 开发需要)
if ! command -v java &> /dev/null; then
    echo "⚠️  Java 未安装，请安装 JDK 11+"
    echo "   下载地址: https://adoptium.net/"
fi

# 检查 Android Studio
if [[ "$OSTYPE" == "darwin"* ]]; then
    ANDROID_STUDIO_PATH="/Applications/Android Studio.app"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    ANDROID_STUDIO_PATH="/opt/android-studio"
else
    ANDROID_STUDIO_PATH="C:\Program Files\Android\Android Studio"
fi

if [ ! -d "$ANDROID_STUDIO_PATH" ]; then
    echo "⚠️  Android Studio 未检测到"
    echo "   请从官网下载: https://developer.android.com/studio"
fi

echo "✅ 环境检查完成"
echo ""

# 进入项目目录
cd sloan-toolkit-vue

# 1. 安装 Capacitor
echo "📦 安装 Capacitor..."
npm install @capacitor/core @capacitor/cli @capacitor/android

# 2. 安装常用插件
echo "🔌 安装 Capacitor 插件..."
npm install @capacitor/status-bar @capacitor/splash-screen @capacitor/filesystem @capacitor/network @capacitor/device @capacitor/app

# 3. 初始化 Capacitor
echo "⚙️ 初始化 Capacitor 配置..."
if [ ! -f "capacitor.config.ts" ]; then
    npx cap init "Sloan Toolkit" "com.sloan.toolkit"
fi

# 4. 添加 Android 平台
echo "📱 添加 Android 平台..."
npx cap add android

# 5. 创建配置文件
echo "📝 创建 Capacitor 配置..."
cat > capacitor.config.ts << EOL
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.sloan.toolkit',
  appName: 'Sloan Toolkit',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
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
EOL

# 6. 修改 Vite 配置
echo "🔧 更新 Vite 配置..."
cp vite.config.ts vite.config.ts.backup

cat > vite.config.ts << 'EOL'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'

export default defineConfig({
  plugins: [
    vue(),
    AutoImport({
      imports: ['vue', 'vue-router', 'pinia'],
      resolvers: [ElementPlusResolver()],
      dts: 'src/auto-imports.d.ts'
    }),
    Components({
      resolvers: [ElementPlusResolver()],
      dts: 'src/components.d.ts'
    })
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src')
    }
  },
  base: './',  // 重要：Capacitor 需要相对路径
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      output: {
        manualChunks: {
          'element-plus': ['element-plus'],
          'echarts': ['echarts', 'vue-echarts'],
          'vue-vendor': ['vue', 'vue-router', 'pinia']
        }
      }
    }
  },
  server: {
    host: '::', 
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:5002',
        changeOrigin: true
      }
    }
  }
})
EOL

# 7. 构建 Web 应用
echo "🔨 构建 Web 应用..."
npm run build

# 8. 同步到 Android
echo "📲 同步到 Android 项目..."
npx cap sync android

# 9. 创建 Capacitor 工具类
echo "🛠️ 创建 Capacitor 工具类..."
mkdir -p src/utils

cat > src/utils/capacitor-native.ts << 'EOL'
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';
import { Network } from '@capacitor/network';
import { Device } from '@capacitor/device';
import { App } from '@capacitor/app';
import { StatusBar, Style } from '@capacitor/status-bar';

export class CapacitorNative {
  
  // 文件系统操作
  static async saveFile(filename: string, data: string): Promise<boolean> {
    try {
      await Filesystem.writeFile({
        path: filename,
        data: data,
        directory: Directory.Documents,
        encoding: Encoding.UTF8
      });
      return true;
    } catch (error) {
      console.error('保存文件失败:', error);
      return false;
    }
  }

  static async readFile(filename: string): Promise<string | null> {
    try {
      const result = await Filesystem.readFile({
        path: filename,
        directory: Directory.Documents,
        encoding: Encoding.UTF8
      });
      return result.data as string;
    } catch (error) {
      console.error('读取文件失败:', error);
      return null;
    }
  }

  static async listFiles(): Promise<string[]> {
    try {
      const result = await Filesystem.readdir({
        path: '',
        directory: Directory.Documents
      });
      return result.files.map(f => f.name);
    } catch (error) {
      console.error('列出文件失败:', error);
      return [];
    }
  }

  // 网络状态
  static async getNetworkStatus() {
    const status = await Network.getStatus();
    return {
      connected: status.connected,
      connectionType: status.connectionType
    };
  }

  static addNetworkListener(callback: (status: any) => void) {
    Network.addListener('networkStatusChange', callback);
  }

  // 设备信息
  static async getDeviceInfo() {
    const info = await Device.getInfo();
    return {
      platform: info.platform,
      model: info.model,
      operatingSystem: info.operatingSystem,
      osVersion: info.osVersion,
      manufacturer: info.manufacturer
    };
  }

  // 应用信息
  static async getAppInfo() {
    const info = await App.getInfo();
    return {
      name: info.name,
      id: info.id,
      build: info.build,
      version: info.version
    };
  }

  // 状态栏
  static async setStatusBar(style: 'light' | 'dark', backgroundColor?: string) {
    try {
      await StatusBar.setStyle({
        style: style === 'light' ? Style.Light : Style.Dark
      });
      
      if (backgroundColor) {
        await StatusBar.setBackgroundColor({
          color: backgroundColor
        });
      }
    } catch (error) {
      console.log('状态栏设置失败（可能在浏览器中）:', error);
    }
  }

  // 检查是否在原生环境中运行
  static isNative(): boolean {
    return window?.Capacitor?.isNativePlatform() || false;
  }

  // 检查是否在 Android 中运行
  static isAndroid(): boolean {
    return window?.Capacitor?.getPlatform() === 'android';
  }
}

// 声明全局类型（避免 TypeScript 错误）
declare global {
  interface Window {
    Capacitor: any;
  }
}
EOL

# 10. 创建示例用法
cat > src/utils/capacitor-example.ts << 'EOL'
import { CapacitorNative } from './capacitor-native';

// 在 Vue 组件中使用示例
export class CapacitorExamples {
  
  // 保存日志分析结果
  static async saveLogAnalysis(data: any) {
    const filename = `log-analysis-${Date.now()}.json`;
    const jsonData = JSON.stringify(data, null, 2);
    
    if (CapacitorNative.isNative()) {
      return await CapacitorNative.saveFile(filename, jsonData);
    } else {
      // Web 环境fallback
      const blob = new Blob([jsonData], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      a.click();
      return true;
    }
  }

  // 检查网络状态后进行API调用
  static async safeApiCall(apiFunction: Function) {
    const networkStatus = await CapacitorNative.getNetworkStatus();
    
    if (!networkStatus.connected) {
      throw new Error('网络未连接，请检查网络设置');
    }
    
    return await apiFunction();
  }

  // 初始化应用设置
  static async initializeApp() {
    if (!CapacitorNative.isNative()) return;
    
    // 设置状态栏
    await CapacitorNative.setStatusBar('light', '#667eea');
    
    // 获取设备信息
    const deviceInfo = await CapacitorNative.getDeviceInfo();
    console.log('设备信息:', deviceInfo);
    
    // 监听网络变化
    CapacitorNative.addNetworkListener((status) => {
      console.log('网络状态变化:', status);
      // 可以在这里处理离线/在线状态
    });
  }
}
EOL

# 11. 创建构建脚本
cat > build-android.sh << 'EOL'
#!/bin/bash
# Android App 构建脚本

echo "🔨 构建 Android App..."

# 1. 构建 Web 应用
echo "📦 构建前端..."
npm run build

# 2. 同步到 Android
echo "📱 同步到 Android..."
npx cap sync android

# 3. 选择构建方式
echo ""
echo "请选择构建方式:"
echo "1. 开发调试 (Debug APK)"
echo "2. 生产发布 (Release APK)"
echo "3. 打开 Android Studio"
read -p "请输入选项 (1-3): " choice

case $choice in
  1)
    echo "🔧 构建 Debug APK..."
    cd android
    ./gradlew assembleDebug
    echo "✅ Debug APK 已生成："
    echo "📁 android/app/build/outputs/apk/debug/app-debug.apk"
    ;;
  2)
    echo "🚀 构建 Release APK..."
    cd android
    ./gradlew assembleRelease
    echo "✅ Release APK 已生成："
    echo "📁 android/app/build/outputs/apk/release/app-release-unsigned.apk"
    echo "⚠️  注意：需要签名才能安装"
    ;;
  3)
    echo "🚀 打开 Android Studio..."
    npx cap open android
    ;;
  *)
    echo "❌ 无效选项"
    ;;
esac
EOL

chmod +x build-android.sh

echo ""
echo "🎉 Capacitor Android 项目配置完成！"
echo "=================================="
echo ""
echo "📁 项目结构:"
echo "   ├── android/                 (Android 原生项目)"
echo "   ├── capacitor.config.ts      (Capacitor 配置)"
echo "   ├── src/utils/capacitor-*    (原生功能封装)"
echo "   └── build-android.sh         (构建脚本)"
echo ""
echo "🚀 下一步操作:"
echo "   1. 安装 Android Studio: https://developer.android.com/studio"
echo "   2. 配置 Android SDK"
echo "   3. 运行构建脚本: ./build-android.sh"
echo ""
echo "🔧 开发命令:"
echo "   npm run build && npx cap sync   # 同步到 Android"
echo "   npx cap run android            # 运行到设备"
echo "   npx cap open android           # 打开 Android Studio"
echo ""
echo "📚 相关文档:"
echo "   - Capacitor 文档: https://capacitorjs.com/"
echo "   - Android 开发文档: https://developer.android.com/"
echo "   - 详细指南: ./ANDROID_CAPACITOR_GUIDE.md"