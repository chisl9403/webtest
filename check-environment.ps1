# Capacitor Android Development Environment Check Script
# Author: GitHub Copilot
# Date: 2025-11-03

Write-Host "Checking Capacitor Android development environment..." -ForegroundColor Cyan
Write-Host ("=" * 50)

# Store check results
$checkResults = @{}
$installCommands = @()

# 1. Check Node.js
Write-Host "`nChecking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    if ($nodeVersion -match "v(\d+)\.") {
        $majorVersion = [int]$Matches[1]
        if ($majorVersion -ge 16) {
            Write-Host "Node.js version: $nodeVersion (OK >= 16.x)" -ForegroundColor Green
            $checkResults['Node.js'] = "Installed ($nodeVersion)"
        } else {
            Write-Host "Node.js version too old: $nodeVersion (need >= 16.x)" -ForegroundColor Red
            $checkResults['Node.js'] = "Version too old"
            $installCommands += "Download and install latest Node.js LTS from https://nodejs.org"
        }
    }
} catch {
    Write-Host "Node.js not installed" -ForegroundColor Red
    $checkResults['Node.js'] = "Not installed"
    $installCommands += "Download and install Node.js LTS from https://nodejs.org"
}

# 2. Check npm
Write-Host "`nChecking npm..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version
    Write-Host "npm version: $npmVersion" -ForegroundColor Green
    $checkResults['npm'] = "Installed ($npmVersion)"
} catch {
    Write-Host "npm not installed" -ForegroundColor Red
    $checkResults['npm'] = "Not installed"
}

# 3. Check Java JDK
Write-Host "`nChecking Java JDK..." -ForegroundColor Yellow
try {
    $javaOutput = java -version 2>&1 | Out-String
    if ($javaOutput -match 'version "(\d+)') {
        $javaVersionNumber = [int]$Matches[1]
        if ($javaVersionNumber -ge 17) {
            Write-Host "Java version meets requirements (>= 17)" -ForegroundColor Green
            $checkResults['Java JDK'] = "Installed"
        } else {
            Write-Host "Java version too old, need JDK 17 or higher" -ForegroundColor Red
            $checkResults['Java JDK'] = "Version too old"
            $installCommands += "Install JDK 17 or higher"
        }
    }
} catch {
    Write-Host "Java JDK not installed or not configured" -ForegroundColor Red
    $checkResults['Java JDK'] = "Not installed"
    $installCommands += "Install OpenJDK 17+ and configure JAVA_HOME environment variable"
}

# 4. Check Android SDK
Write-Host "`nChecking Android SDK..." -ForegroundColor Yellow
$androidHome = $env:ANDROID_HOME
if ($androidHome -and (Test-Path $androidHome)) {
    Write-Host "ANDROID_HOME: $androidHome" -ForegroundColor Green
    $checkResults['Android SDK'] = "Installed"
} else {
    Write-Host "Android SDK not installed or ANDROID_HOME not configured" -ForegroundColor Red
    $checkResults['Android SDK'] = "Not installed"
    $installCommands += "Install Android Studio or Android SDK and configure ANDROID_HOME environment variable"
}

# 5. Check ADB
Write-Host "`nChecking ADB..." -ForegroundColor Yellow
try {
    adb version | Out-Null
    Write-Host "ADB available" -ForegroundColor Green
    $checkResults['ADB'] = "Installed"
} catch {
    Write-Host "ADB not found or not in PATH" -ForegroundColor Red
    $checkResults['ADB'] = "Not installed"
    $installCommands += "Add Android SDK platform-tools directory to PATH environment variable"
}

# 6. Check Gradle
Write-Host "`nChecking Gradle..." -ForegroundColor Yellow
try {
    gradle --version | Out-Null
    Write-Host "Gradle available" -ForegroundColor Green
    $checkResults['Gradle'] = "Installed"
} catch {
    Write-Host "Gradle not globally installed (will use project Gradle Wrapper)" -ForegroundColor Yellow
    $checkResults['Gradle'] = "Using Wrapper"
}

# 7. Check Capacitor CLI
Write-Host "`nChecking Capacitor CLI..." -ForegroundColor Yellow
try {
    $capVersion = npx @capacitor/cli --version 2>&1
    Write-Host "Capacitor CLI available: $capVersion" -ForegroundColor Green
    $checkResults['Capacitor CLI'] = "Installed ($capVersion)"
} catch {
    Write-Host "Capacitor CLI not installed" -ForegroundColor Red
    $checkResults['Capacitor CLI'] = "Not installed"
    $installCommands += "npm install -g @capacitor/cli"
}

# Output check results summary
Write-Host "`n" + ("=" * 50)
Write-Host "Environment Check Results Summary:" -ForegroundColor Cyan
Write-Host ("=" * 50)

foreach ($item in $checkResults.GetEnumerator()) {
    $status = if ($item.Value -like "*Installed*" -or $item.Value -like "*Using*") { "OK" } else { "MISSING" }
    $color = if ($status -eq "OK") { "Green" } else { "Red" }
    Write-Host "$($item.Key): $($item.Value)" -ForegroundColor $color
}

# Output installation suggestions
if ($installCommands.Count -gt 0) {
    Write-Host "`nRequired Installation/Configuration Steps:" -ForegroundColor Yellow
    Write-Host ("=" * 50)
    
    for ($i = 0; $i -lt $installCommands.Count; $i++) {
        Write-Host "$($i + 1). $($installCommands[$i])" -ForegroundColor White
    }
    
    Write-Host "`nFor detailed installation guide, see: ANDROID_CAPACITOR_GUIDE.md" -ForegroundColor Cyan
} else {
    Write-Host "`nCongratulations! All environment dependencies are satisfied!" -ForegroundColor Green
    Write-Host "You can start Capacitor Android development now!" -ForegroundColor Green
}

Write-Host "`n" + ("=" * 50)
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Install any missing dependencies listed above" -ForegroundColor White
Write-Host "2. Run ./setup-android-capacitor.ps1 to initialize Capacitor project" -ForegroundColor White
Write-Host "3. Use VS Code to start development (complete dev environment configured)" -ForegroundColor White
Write-Host ("=" * 50)