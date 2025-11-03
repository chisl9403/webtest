# Android Environment Variables Setup Script
# Auto-detect and configure Java and Android SDK

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Android Environment Configuration" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Find Java JDK
Write-Host "[1/3] Searching for Java JDK..." -ForegroundColor Yellow
$javaLocations = @(
    "C:\Program Files\Eclipse Adoptium\jdk-17*",
    "C:\Program Files\Java\jdk-17*",
    "C:\Program Files\OpenJDK\jdk-17*",
    "C:\Program Files\Eclipse Adoptium\jdk-*"
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
    Write-Host "  Found: $javaHome" -ForegroundColor Green
    [System.Environment]::SetEnvironmentVariable('JAVA_HOME', $javaHome, 'User')
    $env:JAVA_HOME = $javaHome
    Write-Host "  JAVA_HOME set successfully" -ForegroundColor Green
} else {
    Write-Host "  Not found in standard locations" -ForegroundColor Yellow
    $manualPath = Read-Host "  Enter JAVA_HOME path (or Enter to skip)"
    if ($manualPath -and (Test-Path $manualPath)) {
        [System.Environment]::SetEnvironmentVariable('JAVA_HOME', $manualPath, 'User')
        $env:JAVA_HOME = $manualPath
        $javaHome = $manualPath
        Write-Host "  JAVA_HOME set to: $manualPath" -ForegroundColor Green
    }
}

# Find Android SDK
Write-Host ""
Write-Host "[2/3] Searching for Android SDK..." -ForegroundColor Yellow
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
    Write-Host "  Found: $androidHome" -ForegroundColor Green
    [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', $androidHome, 'User')
    $env:ANDROID_HOME = $androidHome
    Write-Host "  ANDROID_HOME set successfully" -ForegroundColor Green
} else {
    Write-Host "  Not found in standard locations" -ForegroundColor Yellow
    $manualPath = Read-Host "  Enter ANDROID_HOME path (or Enter to skip)"
    if ($manualPath -and (Test-Path $manualPath)) {
        [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', $manualPath, 'User')
        $env:ANDROID_HOME = $manualPath
        $androidHome = $manualPath
        Write-Host "  ANDROID_HOME set to: $manualPath" -ForegroundColor Green
    }
}

# Update PATH
Write-Host ""
Write-Host "[3/3] Updating PATH..." -ForegroundColor Yellow
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
        if ((Test-Path $androidPath) -and ($currentPath -notlike "*$androidPath*")) {
            $pathsToAdd += $androidPath
        }
    }
}

if ($pathsToAdd.Count -gt 0) {
    $newPath = $currentPath
    foreach ($pathToAdd in $pathsToAdd) {
        Write-Host "  Adding: $pathToAdd" -ForegroundColor Cyan
        $newPath += ";$pathToAdd"
    }
    [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "  PATH updated" -ForegroundColor Green
} else {
    Write-Host "  All paths already in PATH" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Configuration Complete" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Current Settings:" -ForegroundColor Yellow
Write-Host "  JAVA_HOME: $env:JAVA_HOME"
Write-Host "  ANDROID_HOME: $env:ANDROID_HOME"
Write-Host ""
Write-Host "IMPORTANT: Restart your terminal for changes to take effect" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Close and reopen terminal" -ForegroundColor White
Write-Host "  2. Run: .\install-capacitor-environment.ps1" -ForegroundColor White
Write-Host ""
