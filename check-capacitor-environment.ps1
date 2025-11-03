# Capacitor Android Development Environment Check Script
# Author: GitHub Copilot
# Date: 2025-11-03
# Description: Check and install required environment and dependencies for Capacitor Android development

Write-Host "Checking Capacitor Android development environment..." -ForegroundColor Cyan
Write-Host ("=" * 50)

# 检查结果存储
$checkResults = @{}
$installCommands = @()

# 1. 检查 Node.js
Write-Host "`n📦 检查 Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    if ($nodeVersion -match "v(\d+)\.") {
        $majorVersion = [int]$Matches[1]
        if ($majorVersion -ge 16) {
            Write-Host "✅ Node.js 版本: $nodeVersion (满足要求 >= 16.x)" -ForegroundColor Green
            $checkResults['Node.js'] = "✅ 已安装 ($nodeVersion)"
        } else {
            Write-Host "⚠️ Node.js 版本过低: $nodeVersion (需要 >= 16.x)" -ForegroundColor Red
            $checkResults['Node.js'] = "❌ 版本过低"
            $installCommands += "请从 https://nodejs.org 下载并安装最新的 Node.js LTS 版本"
        }
    }
} catch {
    Write-Host "❌ Node.js 未安装" -ForegroundColor Red
    $checkResults['Node.js'] = "❌ 未安装"
    $installCommands += "请从 https://nodejs.org 下载并安装 Node.js LTS 版本"
}

# 2. 检查 npm
Write-Host "`n📦 检查 npm..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version
    Write-Host "✅ npm 版本: $npmVersion" -ForegroundColor Green
    $checkResults['npm'] = "✅ 已安装 ($npmVersion)"
} catch {
    Write-Host "❌ npm 未安装" -ForegroundColor Red
    $checkResults['npm'] = "❌ 未安装"
}

# 3. 检查 Java JDK
Write-Host "`n☕ 检查 Java JDK..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1
    if ($javaVersion -match "version `"(\d+)") {
        $javaVersionNumber = [int]$Matches[1]
        if ($javaVersionNumber -ge 17) {
            Write-Host "✅ Java 版本符合要求 (>= 17)" -ForegroundColor Green
            $checkResults['Java JDK'] = "✅ 已安装"
        } else {
            Write-Host "⚠️ Java 版本过低，需要 JDK 17 或更高版本" -ForegroundColor Red
            $checkResults['Java JDK'] = "❌ 版本过低"
            $installCommands += "请安装 JDK 17 或更高版本"
        }
    }
} catch {
    Write-Host "❌ Java JDK 未安装或未配置环境变量" -ForegroundColor Red
    $checkResults['Java JDK'] = "❌ 未安装"
    $installCommands += "请安装 OpenJDK 17+ 或 Oracle JDK 17+ 并配置 JAVA_HOME 环境变量"
}

# 4. 检查 Android SDK
Write-Host "`n🤖 检查 Android SDK..." -ForegroundColor Yellow
$androidHome = $env:ANDROID_HOME
if ($androidHome -and (Test-Path $androidHome)) {
    Write-Host "✅ ANDROID_HOME: $androidHome" -ForegroundColor Green
    $checkResults['Android SDK'] = "✅ 已安装"
    
    # 检查 SDK 工具
    $sdkManagerPath = Join-Path $androidHome "cmdline-tools\latest\bin\sdkmanager.bat"
    if (Test-Path $sdkManagerPath) {
        Write-Host "✅ SDK Manager 可用" -ForegroundColor Green
    } else {
        Write-Host "⚠️ SDK Manager 未找到，可能需要重新安装 Command Line Tools" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Android SDK 未安装或 ANDROID_HOME 未配置" -ForegroundColor Red
    $checkResults['Android SDK'] = "❌ 未安装"
    $installCommands += "请安装 Android Studio 或 Android SDK，并配置 ANDROID_HOME 环境变量"
}

# 5. 检查 ADB
Write-Host "`n🔧 检查 ADB..." -ForegroundColor Yellow
try {
    $adbVersion = adb version
    Write-Host "✅ ADB 可用" -ForegroundColor Green
    $checkResults['ADB'] = "✅ 已安装"
} catch {
    Write-Host "❌ ADB 未找到或未配置到 PATH" -ForegroundColor Red
    $checkResults['ADB'] = "❌ 未安装"
    $installCommands += "请将 Android SDK platform-tools 目录添加到 PATH 环境变量"
}

# 6. 检查 Gradle
Write-Host "`n🏗️ 检查 Gradle..." -ForegroundColor Yellow
try {
    $gradleVersion = gradle --version
    Write-Host "✅ Gradle 可用" -ForegroundColor Green
    $checkResults['Gradle'] = "✅ 已安装"
} catch {
    Write-Host "⚠️ Gradle 未全局安装（将使用项目本地的 Gradle Wrapper）" -ForegroundColor Yellow
    $checkResults['Gradle'] = "⚠️ 使用 Wrapper"
}

# 7. 检查 Capacitor CLI
Write-Host "`n⚡ 检查 Capacitor CLI..." -ForegroundColor Yellow
try {
    $capVersion = npx @capacitor/cli --version
    Write-Host "✅ Capacitor CLI 可用: $capVersion" -ForegroundColor Green
    $checkResults['Capacitor CLI'] = "✅ 已安装 ($capVersion)"
} catch {
    Write-Host "❌ Capacitor CLI 未安装" -ForegroundColor Red
    $checkResults['Capacitor CLI'] = "❌ 未安装"
    $installCommands += "npm install -g @capacitor/cli"
}

# 输出检查结果摘要
Write-Host "`n" + "=" * 50
Write-Host "📊 环境检查结果摘要:" -ForegroundColor Cyan
Write-Host "=" * 50

foreach ($item in $checkResults.GetEnumerator()) {
    Write-Host "$($item.Key): $($item.Value)"
}

# 输出安装建议
if ($installCommands.Count -gt 0) {
    Write-Host "`n🔧 需要执行的安装/配置步骤:" -ForegroundColor Yellow
    Write-Host "=" * 50
    
    for ($i = 0; $i -lt $installCommands.Count; $i++) {
        Write-Host "$($i + 1). $($installCommands[$i])" -ForegroundColor White
    }
    
    Write-Host "`n💡 详细安装指南请参考: ANDROID_CAPACITOR_GUIDE.md" -ForegroundColor Cyan
} else {
    Write-Host "`n🎉 恭喜！所有环境依赖都已满足，可以开始 Capacitor Android 开发！" -ForegroundColor Green
}

Write-Host "`n" + "=" * 50
Write-Host "🚀 下一步操作建议:" -ForegroundColor Cyan
Write-Host "1. 如有缺失依赖，请先安装" -ForegroundColor White
Write-Host "2. 运行 ./setup-android-capacitor.ps1 初始化 Capacitor 项目" -ForegroundColor White
Write-Host "3. 使用 VS Code 开始开发（已配置完整开发环境）" -ForegroundColor White
Write-Host "=" * 50