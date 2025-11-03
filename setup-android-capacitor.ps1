# 📱 Sloan Toolkit Android App 快速构建脚本 (Windows)
# PowerShell 版本

param(
    [switch]$SkipEnvCheck,
    [switch]$Debug,
    [string]$Mode = "production"
)

Write-Host "🚀 开始构建 Sloan Toolkit Android App" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# 错误处理
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "🔸 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-Command {
    param([string]$CommandName)
    return Get-Command $CommandName -ErrorAction SilentlyContinue
}

# 环境检查
if (-not $SkipEnvCheck) {
    Write-Step "检查开发环境..."

    # 检查 Node.js
    if (-not (Test-Command "node")) {
        Write-Error "Node.js 未安装，请先安装 Node.js 16+"
        Write-Host "下载地址: https://nodejs.org/" -ForegroundColor Blue
        exit 1
    }
    
    $nodeVersion = node --version
    Write-Success "Node.js 版本: $nodeVersion"

    # 检查 npm
    if (-not (Test-Command "npm")) {
        Write-Error "npm 未安装"
        exit 1
    }
    
    $npmVersion = npm --version
    Write-Success "npm 版本: $npmVersion"

    # 检查 Java
    if (-not (Test-Command "java")) {
        Write-Warning "Java 未安装，Android 开发需要 JDK 11+"
        Write-Host "下载地址: https://adoptium.net/" -ForegroundColor Blue
    } else {
        $javaVersion = java -version 2>&1 | Select-String "version"
        Write-Success "Java: $javaVersion"
    }

    # 检查 Android Studio
    $androidStudioPaths = @(
        "$env:LOCALAPPDATA\Android\Sdk",
        "$env:ProgramFiles\Android\Android Studio",
        "$env:ProgramFiles(x86)\Android\Android Studio"
    )
    
    $androidStudioFound = $false
    foreach ($path in $androidStudioPaths) {
        if (Test-Path $path) {
            Write-Success "Android Studio 路径: $path"
            $androidStudioFound = $true
            break
        }
    }
    
    if (-not $androidStudioFound) {
        Write-Warning "Android Studio 未检测到"
        Write-Host "请从官网下载: https://developer.android.com/studio" -ForegroundColor Blue
    }

    Write-Success "环境检查完成"
    Write-Host ""
}

# 进入项目目录
if (Test-Path "sloan-toolkit-vue") {
    Set-Location "sloan-toolkit-vue"
} else {
    Write-Error "未找到 sloan-toolkit-vue 目录"
    exit 1
}

try {
    # 1. 安装 Capacitor
    Write-Step "安装 Capacitor..."
    npm install @capacitor/core @capacitor/cli @capacitor/android
    
    # 2. 安装常用插件
    Write-Step "安装 Capacitor 插件..."
    npm install @capacitor/status-bar @capacitor/splash-screen @capacitor/filesystem @capacitor/network @capacitor/device @capacitor/app
    
    # 3. 初始化 Capacitor（如果未初始化）
    if (-not (Test-Path "capacitor.config.ts")) {
        Write-Step "初始化 Capacitor 配置..."
        npx cap init "Sloan Toolkit" "com.sloan.toolkit"
    }
    
    # 4. 添加 Android 平台（如果未添加）
    if (-not (Test-Path "android")) {
        Write-Step "添加 Android 平台..."
        npx cap add android
    }
    
    # 5. 创建 Capacitor 配置
    Write-Step "创建 Capacitor 配置..."
    
    $capacitorConfig = @"
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
"@
    
    $capacitorConfig | Out-File -FilePath "capacitor.config.ts" -Encoding UTF8
    
    # 6. 备份并更新 Vite 配置
    if (Test-Path "vite.config.ts") {
        Write-Step "备份 Vite 配置..."
        Copy-Item "vite.config.ts" "vite.config.ts.backup" -Force
    }
    
    Write-Step "更新 Vite 配置..."
    
    $viteConfig = @"
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
"@
    
    $viteConfig | Out-File -FilePath "vite.config.ts" -Encoding UTF8
    
    # 7. 构建 Web 应用
    Write-Step "构建 Web 应用..."
    npm run build
    
    # 8. 同步到 Android
    Write-Step "同步到 Android 项目..."
    npx cap sync android
    
    # 9. 创建 Capacitor 工具类
    Write-Step "创建 Capacitor 工具类..."
    
    if (-not (Test-Path "src\utils")) {
        New-Item -ItemType Directory -Path "src\utils" -Force
    }
    
    $capacitorNative = @"
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
"@
    
    $capacitorNative | Out-File -FilePath "src\utils\capacitor-native.ts" -Encoding UTF8
    
    # 10. 创建 Windows 构建脚本
    Write-Step "创建构建脚本..."
    
    $buildScript = @"
# Android App 构建脚本 (Windows PowerShell)

Write-Host "🔨 构建 Android App..." -ForegroundColor Green

# 1. 构建 Web 应用
Write-Host "📦 构建前端..." -ForegroundColor Cyan
npm run build

# 2. 同步到 Android
Write-Host "📱 同步到 Android..." -ForegroundColor Cyan
npx cap sync android

# 3. 选择构建方式
Write-Host ""
Write-Host "请选择构建方式:" -ForegroundColor Yellow
Write-Host "1. 开发调试 (Debug APK)"
Write-Host "2. 生产发布 (Release APK)"
Write-Host "3. 打开 Android Studio"
`$choice = Read-Host "请输入选项 (1-3)"

switch (`$choice) {
  1 {
    Write-Host "🔧 构建 Debug APK..." -ForegroundColor Cyan
    Set-Location android
    & .\gradlew.bat assembleDebug
    Write-Host "✅ Debug APK 已生成：" -ForegroundColor Green
    Write-Host "📁 android\app\build\outputs\apk\debug\app-debug.apk" -ForegroundColor Blue
    break
  }
  2 {
    Write-Host "🚀 构建 Release APK..." -ForegroundColor Cyan
    Set-Location android
    & .\gradlew.bat assembleRelease
    Write-Host "✅ Release APK 已生成：" -ForegroundColor Green
    Write-Host "📁 android\app\build\outputs\apk\release\app-release-unsigned.apk" -ForegroundColor Blue
    Write-Host "⚠️  注意：需要签名才能安装" -ForegroundColor Yellow
    break
  }
  3 {
    Write-Host "🚀 打开 Android Studio..." -ForegroundColor Cyan
    npx cap open android
    break
  }
  default {
    Write-Host "❌ 无效选项" -ForegroundColor Red
  }
}
"@
    
    $buildScript | Out-File -FilePath "build-android.ps1" -Encoding UTF8
    
    Write-Host ""
    Write-Success "🎉 Capacitor Android 项目配置完成！"
    Write-Host "====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 项目结构:" -ForegroundColor Cyan
    Write-Host "   ├── android/                 (Android 原生项目)"
    Write-Host "   ├── capacitor.config.ts      (Capacitor 配置)"
    Write-Host "   ├── src/utils/capacitor-*    (原生功能封装)"
    Write-Host "   └── build-android.ps1        (Windows 构建脚本)"
    Write-Host ""
    Write-Host "🚀 下一步操作:" -ForegroundColor Yellow
    Write-Host "   1. 安装 Android Studio: https://developer.android.com/studio"
    Write-Host "   2. 配置 Android SDK 和环境变量"
    Write-Host "   3. 运行构建脚本: .\build-android.ps1"
    Write-Host ""
    Write-Host "🔧 开发命令:" -ForegroundColor Cyan
    Write-Host "   npm run build; npx cap sync   # 同步到 Android"
    Write-Host "   npx cap run android           # 运行到设备"
    Write-Host "   npx cap open android          # 打开 Android Studio"
    Write-Host ""
    Write-Host "📚 相关文档:" -ForegroundColor Blue
    Write-Host "   - Capacitor 文档: https://capacitorjs.com/"
    Write-Host "   - Android 开发文档: https://developer.android.com/"
    Write-Host "   - 详细指南: .\ANDROID_CAPACITOR_GUIDE.md"
    Write-Host "   - 方案对比: .\ANDROID_SOLUTIONS_COMPARISON.md"

} catch {
    Write-Error "构建过程中发生错误: $_"
    Write-Host "请检查错误信息并重新运行脚本" -ForegroundColor Red
    exit 1
}