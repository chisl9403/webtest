# Capacitor Android 环境配置总结

## 📊 当前状态

### ✅ 已完成
1. **Node.js 环境**: v22.18.0 ✓
2. **npm 包管理**: v10.9.3 ✓
3. **项目依赖**: 已安装 249 个包 ✓
4. **Capacitor 核心**: @capacitor/core 已安装 ✓
5. **Capacitor CLI**: @capacitor/cli 已安装 ✓
6. **Android 平台包**: @capacitor/android 已安装 ✓
7. **Capacitor 初始化**: capacitor.config.ts 已创建 ✓

### ❌ 待安装
1. **Java JDK 17**: 未安装
2. **Android Studio**: 未安装
3. **Android SDK**: 未配置
4. **环境变量**: JAVA_HOME 和 ANDROID_HOME 未设置

---

## 🚀 快速开始指南

### 步骤 1: 安装 Java JDK 17

#### 选项 A: 自动下载安装 (推荐)
1. 访问 https://adoptium.net/
2. 选择 **Temurin 17 (LTS)**
3. 下载 Windows x64 MSI 安装包
4. 运行安装，**勾选设置 JAVA_HOME**

#### 选项 B: 使用包管理器
```powershell
# Chocolatey
choco install openjdk17 -y

# Scoop
scoop install openjdk17
```

---

### 步骤 2: 安装 Android Studio

1. **下载**: https://developer.android.com/studio
2. **安装**: 运行安装程序，使用默认设置
3. **首次启动**: 按照向导完成初始设置

#### 在 Android Studio 中配置 SDK:

1. 打开 **File** > **Settings** (或 **Configure** > **Settings**)
2. 导航到 **Appearance & Behavior** > **System Settings** > **Android SDK**

3. **SDK Platforms** 标签页，勾选安装:
   - ✓ Android 13.0 (T) - API 33
   - ✓ Android 12.0 (S) - API 31
   - ✓ Android 11.0 (R) - API 30

4. **SDK Tools** 标签页，确保安装:
   - ✓ Android SDK Build-Tools
   - ✓ Android SDK Command-line Tools
   - ✓ Android SDK Platform-Tools
   - ✓ Android Emulator
   - ✓ Intel x86 Emulator Accelerator (HAXM installer)

5. 点击 **Apply** 开始下载安装

---

### 步骤 3: 配置环境变量

#### 自动配置 (推荐)
```powershell
cd d:\sw\sloan-toolkit-vue-andriod
.\setup-android-environment.ps1
```

这个脚本会：
- 自动查找 Java JDK 安装位置
- 自动查找 Android SDK 位置
- 设置 JAVA_HOME 和 ANDROID_HOME
- 更新 PATH 环境变量

#### 手动配置
如果自动脚本无法找到安装路径，手动设置：

1. 打开 **系统属性** > **高级** > **环境变量**
2. 添加用户变量：
   - `JAVA_HOME` = `C:\Program Files\Eclipse Adoptium\jdk-17.x.x`
   - `ANDROID_HOME` = `C:\Users\你的用户名\AppData\Local\Android\Sdk`

3. 编辑 `Path` 变量，添加：
   - `%JAVA_HOME%\bin`
   - `%ANDROID_HOME%\platform-tools`
   - `%ANDROID_HOME%\tools`
   - `%ANDROID_HOME%\tools\bin`

---

### 步骤 4: 验证环境配置

**重启终端后**运行验证脚本：

```powershell
cd d:\sw\sloan-toolkit-vue-andriod
.\verify-environment.ps1
```

或手动验证：

```powershell
# 检查 Java
java -version
# 应显示: openjdk version "17.x.x"

# 检查环境变量
echo $env:JAVA_HOME
echo $env:ANDROID_HOME

# 检查 Android 工具
adb --version
```

---

### 步骤 5: 完成 Capacitor 配置

环境验证通过后，运行完整的环境检查和配置：

```powershell
cd d:\sw\sloan-toolkit-vue-andriod
.\install-capacitor-environment.ps1
```

这个脚本会：
- 重新检查所有环境
- 自动添加 Android 平台到项目
- 创建 `android/` 目录

---

### 步骤 6: 构建和运行

```powershell
# 进入项目目录
cd sloan-toolkit-vue

# 构建 Vue 项目
npm run build

# 同步到 Android
npx cap sync android

# 在 Android Studio 中打开
npx cap open android
```

在 Android Studio 中：
1. 等待 Gradle 同步完成
2. 选择模拟器或连接真机
3. 点击 ▶️ Run 按钮

---

## 📝 配置文件说明

### capacitor.config.ts
已创建在 `sloan-toolkit-vue/capacitor.config.ts`:

```typescript
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.sloan.toolkit',      // Android 包名
  appName: 'Sloan Toolkit',        // 应用显示名称
  webDir: 'dist'                   // Vue 构建输出目录
};

export default config;
```

### package.json
Capacitor 相关依赖已添加：
- `@capacitor/core`: Capacitor 核心库
- `@capacitor/cli`: Capacitor 命令行工具
- `@capacitor/android`: Android 平台支持

---

## 🛠️ 可用脚本

### 1. `install-capacitor-environment.ps1`
**功能**: 全面的环境检查和 Capacitor 安装
- 检查 Node.js、npm、Java、Android SDK
- 安装项目依赖
- 安装 Capacitor 包
- 初始化 Capacitor 配置
- 添加 Android 平台

**使用**:
```powershell
.\install-capacitor-environment.ps1
```

### 2. `setup-android-environment.ps1`
**功能**: 自动配置 Android 开发环境变量
- 查找 Java JDK 安装位置
- 查找 Android SDK 位置
- 设置 JAVA_HOME 和 ANDROID_HOME
- 更新 PATH 环境变量

**使用**:
```powershell
.\setup-android-environment.ps1
```

### 3. `verify-environment.ps1`
**功能**: 快速验证环境配置
- 显示环境变量
- 测试 Java 命令
- 测试 ADB 命令

**使用**:
```powershell
.\verify-environment.ps1
```

---

## 📱 开发工作流

### 方式 1: 命令行开发

```powershell
# 1. 修改代码
# 编辑 Vue 组件...

# 2. 构建
npm run build

# 3. 同步
npx cap sync android

# 4. 运行
npx cap open android
```

### 方式 2: VS Code 开发 (推荐)

你的项目已配置好 VS Code 任务和快捷键：

**快捷键**:
- `Ctrl+Shift+B`: 构建项目
- `Ctrl+Shift+S`: 同步到 Android  
- `Ctrl+Shift+O`: 在 Android Studio 中打开

**或使用命令面板**:
1. 按 `Ctrl+Shift+P`
2. 输入 "Tasks: Run Task"
3. 选择任务：
   - `Capacitor: Build`
   - `Capacitor: Sync Android`
   - `Capacitor: Open Android`

---

## ❓ 常见问题

### Q1: Java 安装后还是提示未找到？
**解决**:
1. 确认安装时勾选了"设置 JAVA_HOME"
2. **重启终端**（环境变量需要重启生效）
3. 运行 `java -version` 验证
4. 如果还不行，手动设置环境变量

### Q2: Android Studio 安装但 ANDROID_HOME 未找到？
**解决**:
1. 在 Android Studio 中检查 SDK 位置：
   Settings > Android SDK > SDK Location
2. 复制路径并手动设置环境变量
3. 常见位置：
   - `C:\Users\你的用户名\AppData\Local\Android\Sdk`
   - `C:\Android\sdk`

### Q3: Gradle 下载慢或失败？
**解决**: 使用国内镜像

编辑 `android/build.gradle`:
```gradle
repositories {
    maven { url 'https://maven.aliyun.com/repository/public/' }
    maven { url 'https://maven.aliyun.com/repository/google/' }
    google()
    mavenCentral()
}
```

编辑 `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-8.2.1-all.zip
```

### Q4: 模拟器无法启动？
**解决**:
1. 确保已安装 Android Emulator 和 HAXM
2. 在 BIOS 中启用虚拟化 (VT-x/AMD-V)
3. 或使用真机调试（USB 调试模式）

### Q5: 构建时提示 SDK 版本不匹配？
**解决**:
在 Android Studio 中：
1. Tools > SDK Manager
2. 安装提示的 SDK 版本
3. 或修改 `android/app/build.gradle` 中的版本号

---

## 🔍 环境检查清单

完成以下检查，确保环境完全就绪：

- [ ] Node.js 18+ 已安装 (`node --version`)
- [ ] npm 可以正常使用 (`npm --version`)
- [ ] Java JDK 17 已安装 (`java -version`)
- [ ] JAVA_HOME 已设置 (`echo $env:JAVA_HOME`)
- [ ] Android Studio 已安装
- [ ] Android SDK API 30+ 已安装
- [ ] ANDROID_HOME 已设置 (`echo $env:ANDROID_HOME`)
- [ ] ADB 命令可用 (`adb --version`)
- [ ] 终端已重启（环境变量生效）
- [ ] 项目依赖已安装 (`node_modules` 目录存在)
- [ ] Capacitor 已初始化 (`capacitor.config.ts` 存在)
- [ ] Android 平台已添加 (`android/` 目录存在)

**全部完成后，运行**:
```powershell
cd sloan-toolkit-vue
npx cap doctor
```

这会显示完整的环境状态和任何需要修复的问题。

---

## 📚 下一步学习

- [Capacitor 官方文档](https://capacitorjs.com/docs)
- [Android 开发指南](https://developer.android.com/guide)
- [Vue 3 文档](https://vuejs.org/)
- [本项目的详细开发指南](./CAPACITOR_VSCODE_DEVELOPMENT_GUIDE.md)
- [Capacitor vs Kotlin 对比](./KOTLIN_VS_CAPACITOR_COMPARISON.md)

---

## 💡 提示

1. **首次构建会比较慢**: Gradle 需要下载依赖，耐心等待
2. **使用 VS Code 开发**: 已配置好的任务和快捷键会提高效率
3. **开启热重载**: 在开发模式下，可以使用 `npm run dev` + Capacitor Live Reload
4. **真机测试**: 记得在真机上测试，某些功能模拟器不支持

---

**🎉 祝开发顺利！遇到问题请参考文档或运行相应的验证脚本。**
