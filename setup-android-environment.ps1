# ============================================
# Android Environment Variables Setup Script
# 需要管理员权限运行
# ============================================

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Android Environment Setup" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "WARNING: 建议以管理员权限运行此脚本" -ForegroundColor Yellow
    Write-Host "部分设置可能需要管理员权限" -ForegroundColor Yellow
    Write-Host ""
}

# 查找 Java 安装
Write-Host "[1/4] Searching for Java JDK..." -ForegroundColor Yellow
$javaLocations = @(
    "C:\Program Files\Eclipse Adoptium\jdk-17*",
    "C:\Program Files\Java\jdk-17*",
    "C:\Program Files\OpenJDK\jdk-17*",
    "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\jdk-17*"
)

$javaHome = $null
foreach ($location in $javaLocations) {
    $found = Get-Item $location -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $javaHome = $found.FullName
        break
    }
}

if ($javaHome) {
    Write-Host "  Found Java at: $javaHome" -ForegroundColor Green
    
    # 设置 JAVA_HOME
    try {
        [System.Environment]::SetEnvironmentVariable('JAVA_HOME', $javaHome, 'User')
        Write-Host "  JAVA_HOME set successfully" -ForegroundColor Green
        $env:JAVA_HOME = $javaHome
    } catch {
        Write-Host "  ERROR: Failed to set JAVA_HOME" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Java JDK 17 not found in common locations" -ForegroundColor Yellow
    Write-Host "  Please install from: https://adoptium.net/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Or specify manual path:" -ForegroundColor Cyan
    $manualJavaPath = Read-Host "  Enter JAVA_HOME path (or press Enter to skip)"
    
    if ($manualJavaPath -and (Test-Path $manualJavaPath)) {
        try {
            [System.Environment]::SetEnvironmentVariable('JAVA_HOME', $manualJavaPath, 'User')
            Write-Host "  JAVA_HOME set to: $manualJavaPath" -ForegroundColor Green
            $env:JAVA_HOME = $manualJavaPath
            $javaHome = $manualJavaPath
        } catch {
            Write-Host "  ERROR: Failed to set JAVA_HOME" -ForegroundColor Red
        }
    }
}

# 查找 Android SDK
Write-Host ""
Write-Host "[2/4] Searching for Android SDK..." -ForegroundColor Yellow
$androidLocations = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "C:\Android\sdk",
    "$env:USERPROFILE\Android\Sdk"
)

$androidHome = $null
foreach ($location in $androidLocations) {
    if (Test-Path $location) {
        $androidHome = $location
        break
    }
}

if ($androidHome) {
    Write-Host "  Found Android SDK at: $androidHome" -ForegroundColor Green
    
    # 设置 ANDROID_HOME
    try {
        [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', $androidHome, 'User')
        Write-Host "  ANDROID_HOME set successfully" -ForegroundColor Green
        $env:ANDROID_HOME = $androidHome
    } catch {
        Write-Host "  ERROR: Failed to set ANDROID_HOME" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Red
    }
} else {
    Write-Host "  Android SDK not found in common locations" -ForegroundColor Yellow
    Write-Host "  Please install Android Studio from: https://developer.android.com/studio" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Or specify manual path:" -ForegroundColor Cyan
    $manualAndroidPath = Read-Host "  Enter ANDROID_HOME path (or press Enter to skip)"
    
    if ($manualAndroidPath -and (Test-Path $manualAndroidPath)) {
        try {
            [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', $manualAndroidPath, 'User')
            Write-Host "  ANDROID_HOME set to: $manualAndroidPath" -ForegroundColor Green
            $env:ANDROID_HOME = $manualAndroidPath
            $androidHome = $manualAndroidPath
        } catch {
            Write-Host "  ERROR: Failed to set ANDROID_HOME" -ForegroundColor Red
        }
    }
}

# 更新 PATH
Write-Host ""
Write-Host "[3/4] Updating PATH..." -ForegroundColor Yellow

try {
    $currentPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $pathsToAdd = @()
    
    if ($javaHome) {
        $javaBin = Join-Path $javaHome "bin"
        if ($currentPath -notlike "*$javaBin*") {
            $pathsToAdd += $javaBin
        }
    }
    
    if ($androidHome) {
        $androidPaths = @(
            (Join-Path $androidHome "platform-tools"),
            (Join-Path $androidHome "tools"),
            (Join-Path $androidHome "tools\bin")
        )
        
        foreach ($androidPath in $androidPaths) {
            if (Test-Path $androidPath) {
                if ($currentPath -notlike "*$androidPath*") {
                    $pathsToAdd += $androidPath
                }
            }
        }
    }
    
    if ($pathsToAdd.Count -gt 0) {
        $newPath = $currentPath
        foreach ($pathToAdd in $pathsToAdd) {
            $newPath = "$newPath;$pathToAdd"
            Write-Host "  Adding to PATH: $pathToAdd" -ForegroundColor Cyan
        }
        
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host "  PATH updated successfully" -ForegroundColor Green
    } else {
        Write-Host "  All paths already in PATH" -ForegroundColor Green
    }
} catch {
    Write-Host "  ERROR: Failed to update PATH" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Red
}

# 验证设置
Write-Host ""
Write-Host "[4/4] Verifying setup..." -ForegroundColor Yellow

$needsRestart = $false

# 检查 JAVA_HOME
if ($env:JAVA_HOME) {
    Write-Host "  JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Green
} else {
    Write-Host "  JAVA_HOME: Not set" -ForegroundColor Red
    $needsRestart = $true
}

# 检查 ANDROID_HOME
if ($env:ANDROID_HOME) {
    Write-Host "  ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Green
} else {
    Write-Host "  ANDROID_HOME: Not set" -ForegroundColor Red
    $needsRestart = $true
}

# 总结
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Setup Complete" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

if ($needsRestart) {
    Write-Host "IMPORTANT: Please restart your terminal (or computer) for changes to take effect" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "Environment variables are set in current session" -ForegroundColor Green
    Write-Host "They will be available in new terminal windows" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Restart your terminal" -ForegroundColor White
Write-Host "2. Run: cd d:\sw\sloan-toolkit-vue-andriod" -ForegroundColor White
Write-Host "3. Run: .\install-capacitor-environment.ps1" -ForegroundColor White
Write-Host ""

# 创建验证脚本
$verifyScript = @"
# Quick environment verification script
Write-Host "Environment Variables:" -ForegroundColor Cyan
Write-Host "JAVA_HOME: `$env:JAVA_HOME"
Write-Host "ANDROID_HOME: `$env:ANDROID_HOME"
Write-Host ""

Write-Host "Command Tests:" -ForegroundColor Cyan
try { 
    `$javaVer = java -version 2>&1
    Write-Host "Java: OK - `$(`$javaVer[0])" -ForegroundColor Green
} catch { 
    Write-Host "Java: NOT FOUND" -ForegroundColor Red 
}

try { 
    `$adbVer = adb version 2>&1 | Select-Object -First 1
    Write-Host "ADB: OK - `$adbVer" -ForegroundColor Green
} catch { 
    Write-Host "ADB: NOT FOUND" -ForegroundColor Red 
}
"@

$verifyScript | Out-File -FilePath "verify-environment.ps1" -Encoding UTF8
Write-Host "Created verify-environment.ps1 for quick verification" -ForegroundColor Cyan
Write-Host "Run: .\verify-environment.ps1" -ForegroundColor White
Write-Host ""
