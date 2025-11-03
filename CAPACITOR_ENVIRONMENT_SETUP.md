# Capacitor Android 环境配置报告

## ✅ 已完成的配置

### 1. Node.js 环境 ✓
- **Node.js 版本**: v22.18.0 ✓
- **npm 版本**: 10.9.3 ✓
- **状态**: 满足要求（需要 Node.js 18+）

### 2. 项目依赖 ✓
- **npm 包**: 已成功安装 249 个包
- **Capacitor 核心**: @capacitor/core ✓
- **Capacitor CLI**: @capacitor/cli ✓
- **Android 平台**: @capacitor/android ✓
- **Capacitor 初始化**: capacitor.config.ts 已创建 ✓

### 3. 项目文件
已创建 `capacitor.config.ts` 配置文件，应用信息：
- **应用名称**: Sloan Toolkit
- **包名**: com.sloan.toolkit
- **Web 目录**: dist

---

## ❌ 需要安装的组件

### 1. Java JDK 17 (必需)
**状态**: ❌ 未安装

**为什么需要**:
- Android 应用编译需要 Java Development Kit
- Gradle 构建工具依赖 JDK

**安装步骤**:

#### 方法一：使用 Adoptium (推荐)
1. 访问: https://adoptium.net/
2. 选择 **JDK 17 (LTS)**
3. 选择操作系统: **Windows**
4. 下载 `.msi` 安装包
5. 运行安装程序，**勾选"设置 JAVA_HOME 环境变量"**

#### 方法二：使用 Chocolatey (如果已安装)
```powershell
choco install openjdk17
```

#### 方法三：使用 Scoop (如果已安装)
```powershell
scoop install openjdk17
```

**验证安装**:
```powershell
java -version
# 应显示: openjdk version "17.x.x"
```

---

### 2. Android Studio 和 Android SDK (必需)
**状态**: ❌ 未安装（ANDROID_HOME 未设置）

**为什么需要**:
- Android SDK 提供编译和打包工具
- Android Studio 提供模拟器和调试工具
- 必需的 Android 构建工具和平台

**安装步骤**:

#### 1. 下载 Android Studio
- 访问: https://developer.android.com/studio
- 下载最新稳定版
- 运行安装程序

#### 2. 安装 Android SDK 组件
启动 Android Studio 后：
1. 打开 **Settings/Preferences** > **Appearance & Behavior** > **System Settings** > **Android SDK**
2. 在 **SDK Platforms** 标签页，安装：
   - ✓ Android 13.0 (Tiramisu) - API Level 33
   - ✓ Android 12.0 (S) - API Level 31
   - ✓ Android 11.0 (R) - API Level 30

3. 在 **SDK Tools** 标签页，确保安装：
   - ✓ Android SDK Build-Tools
   - ✓ Android SDK Command-line Tools
   - ✓ Android SDK Platform-Tools
   - ✓ Android Emulator
   - ✓ Google Play services

#### 3. 设置环境变量
**设置 ANDROID_HOME**:

##### PowerShell (需要管理员权限)
```powershell
# 通常 Android SDK 位置
$androidSdkPath = "$env:LOCALAPPDATA\Android\Sdk"

# 设置用户环境变量
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', $androidSdkPath, 'User')

# 添加到 PATH
$currentPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$newPath = "$currentPath;$androidSdkPath\platform-tools;$androidSdkPath\tools;$androidSdkPath\tools\bin"
[System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')

Write-Host "环境变量已设置，请重启终端生效"
```

##### 手动设置（Windows 11）
1. 右键"此电脑" > "属性"
2. 点击"高级系统设置"
3. 点击"环境变量"
4. 在"用户变量"中，点击"新建"：
   - 变量名: `ANDROID_HOME`
   - 变量值: `C:\Users\你的用户名\AppData\Local\Android\Sdk`
5. 编辑 `Path` 变量，添加：
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\tools`
   - `%ANDROID_HOME%\tools\bin`

**验证安装**:
```powershell
# 重启终端后运行
echo $env:ANDROID_HOME
adb --version
```

---

### 3. Gradle (可选)
**状态**: ⚠️ 未在 PATH 中（可使用 Gradle Wrapper）

**说明**: 
- Capacitor Android 项目会自动包含 Gradle Wrapper
- 不需要单独安装 Gradle
- 如果想全局使用，可以安装

**可选安装** (Chocolatey):
```powershell
choco install gradle
```

---

## 🔧 完成安装后的下一步操作

### 1. 重新运行环境检查
安装完 Java JDK 和 Android Studio 后，**重启终端**并运行：

```powershell
cd d:\sw\sloan-toolkit-vue-andriod
.\install-capacitor-environment.ps1
```

### 2. 添加 Android 平台
当环境检查通过后，脚本会自动执行：

```powershell
cd sloan-toolkit-vue
npx cap add android
```

这将创建 `android/` 目录，包含完整的 Android 项目。

### 3. 构建 Vue 项目
```powershell
cd sloan-toolkit-vue
npm run build
```

这会在 `dist/` 目录生成生产版本的 Web 应用。

### 4. 同步到 Android
```powershell
npx cap sync android
```

这会：
- 复制 Web 资源到 Android 项目
- 更新 Capacitor 插件
- 同步配置

### 5. 在 Android Studio 中打开
```powershell
npx cap open android
```

这会在 Android Studio 中打开项目，然后你可以：
- 运行模拟器
- 构建 APK
- 调试应用

---

## 📱 开发工作流

### 日常开发流程
```powershell
# 1. 修改 Vue 代码后构建
cd sloan-toolkit-vue
npm run build

# 2. 同步到 Android
npx cap sync android

# 3. 在 Android Studio 中运行
npx cap open android
```

### 使用 VS Code 开发（推荐）
你的 VS Code 已经配置好 Capacitor 开发环境：

**快捷键**:
- `Ctrl+Shift+B`: 构建项目
- `Ctrl+Shift+S`: 同步到 Android
- `Ctrl+Shift+O`: 在 Android Studio 中打开

**自动化任务**:
- 在 VS Code 中按 `Ctrl+Shift+P`
- 输入 "Tasks: Run Task"
- 选择对应任务（构建、同步、打开等）

---

## 🎯 快速安装命令汇总

如果你使用 **Chocolatey** 包管理器，可以快速安装所需工具：

```powershell
# 安装 Chocolatey (如果未安装)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 安装必需组件
choco install openjdk17 -y
# Android Studio 需要手动安装并配置 SDK
```

---

## ❓ 常见问题

### Q1: 如何检查当前环境状态？
```powershell
# 检查 Node.js
node --version

# 检查 Java
java -version

# 检查 Android SDK
echo $env:ANDROID_HOME
adb --version

# 检查 Capacitor
cd sloan-toolkit-vue
npx cap doctor
```

### Q2: Android Studio 安装后找不到 SDK？
默认位置：
- Windows: `C:\Users\你的用户名\AppData\Local\Android\Sdk`
- 也可能在: `C:\Android\sdk`

在 Android Studio 中检查：
Settings > Appearance & Behavior > System Settings > Android SDK

### Q3: 构建失败提示 "ANDROID_HOME not set"？
1. 确保已设置环境变量
2. **重启终端**（环境变量需要重启才能生效）
3. 运行 `echo $env:ANDROID_HOME` 验证

### Q4: Gradle 下载慢？
编辑 `android/gradle/wrapper/gradle-wrapper.properties`，使用国内镜像：
```properties
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-8.2.1-all.zip
```

---

## 📚 相关文档

- [Capacitor 官方文档](https://capacitorjs.com/docs)
- [Android Studio 下载](https://developer.android.com/studio)
- [Adoptium JDK 下载](https://adoptium.net/)
- [Vue 3 文档](https://vuejs.org/)
- [本项目的 Capacitor 开发指南](./CAPACITOR_VSCODE_DEVELOPMENT_GUIDE.md)

---

## ✨ 安装完成后的检查清单

- [ ] Node.js 18+ 已安装并可用
- [ ] npm 可以正常使用
- [ ] Java JDK 17 已安装
- [ ] JAVA_HOME 环境变量已设置
- [ ] Android Studio 已安装
- [ ] Android SDK 已安装（API 30+）
- [ ] ANDROID_HOME 环境变量已设置
- [ ] adb 命令可用
- [ ] 项目依赖已安装 (npm install)
- [ ] Capacitor 已初始化
- [ ] 环境检查脚本运行无错误

**完成以上检查后，你就可以开始 Capacitor Android 开发了！** 🚀
