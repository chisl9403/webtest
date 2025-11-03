# ============================================
# Capacitor Android Environment Setup Script
# ============================================

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Capacitor Android Environment Check" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$errorCount = 0
$warningCount = 0

# Check Node.js
Write-Host "[1/8] Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "  Node.js version: $nodeVersion" -ForegroundColor Green
    if ($nodeVersion -match "v(\d+)\.") {
        $majorVersion = [int]$matches[1]
        if ($majorVersion -lt 18) {
            Write-Host "  WARNING: Node.js 18+ is recommended" -ForegroundColor Yellow
            $warningCount++
        }
    }
} catch {
    Write-Host "  ERROR: Node.js not found!" -ForegroundColor Red
    Write-Host "  Please install from: https://nodejs.org/" -ForegroundColor Red
    $errorCount++
}

# Check npm
Write-Host "[2/8] Checking npm..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version
    Write-Host "  npm version: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: npm not found!" -ForegroundColor Red
    $errorCount++
}

# Check Java JDK
Write-Host "[3/8] Checking Java JDK..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1
    if ($javaVersion -match "version") {
        Write-Host "  Java installed:" -ForegroundColor Green
        Write-Host "  $($javaVersion[0])" -ForegroundColor Green
    }
} catch {
    Write-Host "  ERROR: Java JDK not found!" -ForegroundColor Red
    Write-Host "  Please install JDK 17 from: https://adoptium.net/" -ForegroundColor Red
    $errorCount++
}

# Check JAVA_HOME
Write-Host "[4/8] Checking JAVA_HOME..." -ForegroundColor Yellow
if ($env:JAVA_HOME) {
    Write-Host "  JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Green
} else {
    Write-Host "  WARNING: JAVA_HOME not set!" -ForegroundColor Yellow
    Write-Host "  Android build may fail without JAVA_HOME" -ForegroundColor Yellow
    $warningCount++
}

# Check Android SDK
Write-Host "[5/8] Checking Android SDK..." -ForegroundColor Yellow
if ($env:ANDROID_HOME) {
    Write-Host "  ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Green
    if (Test-Path "$env:ANDROID_HOME\platform-tools\adb.exe") {
        Write-Host "  ADB found" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: ADB not found in platform-tools" -ForegroundColor Yellow
        $warningCount++
    }
} else {
    Write-Host "  ERROR: ANDROID_HOME not set!" -ForegroundColor Red
    Write-Host "  Please install Android Studio and set ANDROID_HOME" -ForegroundColor Red
    Write-Host "  Download from: https://developer.android.com/studio" -ForegroundColor Red
    $errorCount++
}

# Check Gradle
Write-Host "[6/8] Checking Gradle..." -ForegroundColor Yellow
try {
    $gradleVersion = gradle --version 2>&1 | Select-String "Gradle"
    if ($gradleVersion) {
        Write-Host "  $gradleVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "  INFO: Gradle not in PATH (will use Gradle Wrapper)" -ForegroundColor Cyan
}

# Check project dependencies
Write-Host "[7/8] Checking project dependencies..." -ForegroundColor Yellow
$projectDir = "sloan-toolkit-vue"
if (Test-Path "$projectDir\package.json") {
    if (Test-Path "$projectDir\node_modules") {
        Write-Host "  Node modules installed" -ForegroundColor Green
    } else {
        Write-Host "  Node modules not installed" -ForegroundColor Yellow
        Write-Host "  Will install dependencies..." -ForegroundColor Cyan
        
        Push-Location $projectDir
        Write-Host "  Running: npm install" -ForegroundColor Cyan
        npm install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Dependencies installed successfully" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: Failed to install dependencies" -ForegroundColor Red
            $errorCount++
        }
        Pop-Location
    }
} else {
    Write-Host "  ERROR: package.json not found in $projectDir" -ForegroundColor Red
    $errorCount++
}

# Check/Install Capacitor
Write-Host "[8/8] Checking Capacitor..." -ForegroundColor Yellow
Push-Location $projectDir

# Check if Capacitor is in package.json
$packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
$hasCapacitor = $packageJson.dependencies.PSObject.Properties.Name -contains "@capacitor/core"

if ($hasCapacitor) {
    Write-Host "  Capacitor already in package.json" -ForegroundColor Green
} else {
    Write-Host "  Installing Capacitor packages..." -ForegroundColor Cyan
    
    # Install Capacitor core and CLI
    Write-Host "  Installing @capacitor/core @capacitor/cli..." -ForegroundColor Cyan
    npm install @capacitor/core @capacitor/cli
    
    # Install Android platform
    Write-Host "  Installing @capacitor/android..." -ForegroundColor Cyan
    npm install @capacitor/android
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Capacitor packages installed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Failed to install Capacitor packages" -ForegroundColor Red
        $errorCount++
        Pop-Location
        exit 1
    }
}

# Initialize Capacitor if not already initialized
if (Test-Path "capacitor.config.ts") {
    Write-Host "  Capacitor already initialized" -ForegroundColor Green
} else {
    Write-Host "  Initializing Capacitor..." -ForegroundColor Cyan
    npx cap init "Sloan Toolkit" "com.sloan.toolkit" --web-dir=dist
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Capacitor initialized successfully" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Failed to initialize Capacitor" -ForegroundColor Red
        $errorCount++
    }
}

# Add Android platform if not exists
if (Test-Path "android") {
    Write-Host "  Android platform already added" -ForegroundColor Green
} else {
    if ($errorCount -eq 0) {
        Write-Host "  Adding Android platform..." -ForegroundColor Cyan
        npx cap add android
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Android platform added successfully" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: Failed to add Android platform" -ForegroundColor Red
            $errorCount++
        }
    } else {
        Write-Host "  SKIPPED: Fix errors above before adding Android platform" -ForegroundColor Yellow
    }
}

Pop-Location

# Summary
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Environment Check Summary" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
Write-Host "Warnings: $warningCount" -ForegroundColor $(if ($warningCount -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($errorCount -eq 0) {
    Write-Host "SUCCESS: Environment is ready for Capacitor Android development!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Build your Vue project: cd sloan-toolkit-vue && npm run build" -ForegroundColor White
    Write-Host "2. Sync to Android: npx cap sync android" -ForegroundColor White
    Write-Host "3. Open in Android Studio: npx cap open android" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "FAILED: Please fix the errors above before proceeding" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Yellow
    Write-Host "- Install Node.js 18+: https://nodejs.org/" -ForegroundColor White
    Write-Host "- Install Java JDK 17: https://adoptium.net/" -ForegroundColor White
    Write-Host "- Install Android Studio: https://developer.android.com/studio" -ForegroundColor White
    Write-Host "- Set ANDROID_HOME to your Android SDK location" -ForegroundColor White
    Write-Host ""
    exit 1
}
