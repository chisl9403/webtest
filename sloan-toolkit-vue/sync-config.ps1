# 配置文件同步脚本
# 用途：将根目录的 config.json 同步到 public 目录，确保 Android 编译时使用最新配置

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Config File Sync Tool" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 检查源文件是否存在
if (-not (Test-Path "config.json")) {
    Write-Host "Error: config.json not found" -ForegroundColor Red
    Write-Host "Please run this script in project root directory" -ForegroundColor Yellow
    exit 1
}

# 读取并验证 API Key
$config = Get-Content "config.json" -Raw | ConvertFrom-Json
$apiKey = $config.apiKey

Write-Host "Checking configuration..." -ForegroundColor Yellow

# 验证 API Key
$invalidKeys = @(
    "YOUR_OPENWEATHERMAP_API_KEY_HERE",
    "YOUR_API_KEY_HERE"
)

$isValid = $true
if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Host "Warning: API Key is empty" -ForegroundColor Yellow
    $isValid = $false
} elseif ($invalidKeys -contains $apiKey) {
    Write-Host "Warning: API Key not configured (using placeholder)" -ForegroundColor Yellow
    $isValid = $false
} elseif ($apiKey.Length -ne 32) {
    Write-Host "Warning: API Key length incorrect (should be 32 chars)" -ForegroundColor Yellow
    Write-Host "Current length: $($apiKey.Length)" -ForegroundColor Gray
    $isValid = $false
}

if ($isValid) {
    Write-Host "API Key validated" -ForegroundColor Green
    Write-Host "Key: $($apiKey.Substring(0, 8))...$($apiKey.Substring($apiKey.Length - 4))" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "Tips: To use weather features, configure a valid OpenWeatherMap API Key" -ForegroundColor Cyan
    Write-Host "1. Visit: https://openweathermap.org/api" -ForegroundColor Gray
    Write-Host "2. Register and get API Key" -ForegroundColor Gray
    Write-Host "3. Edit config.json and fill apiKey field" -ForegroundColor Gray
    Write-Host "4. Run this script again to sync" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Starting sync..." -ForegroundColor Yellow

# 确保 public 目录存在
if (-not (Test-Path "public")) {
    Write-Host "Error: public directory not found" -ForegroundColor Red
    exit 1
}

try {
    # 同步到 public 目录
    Copy-Item "config.json" "public\config.json" -Force
    Write-Host "Synced: config.json -> public\config.json" -ForegroundColor Green
    
    # 同步 config.local.json（如果存在）
    if (Test-Path "config.local.json") {
        Copy-Item "config.local.json" "public\config.local.json" -Force
        Write-Host "Synced: config.local.json -> public\config.local.json" -ForegroundColor Green
        
        # 验证 local 配置中的 API Key
        $localConfig = Get-Content "config.local.json" -Raw | ConvertFrom-Json
        $localApiKey = $localConfig.apiKey
        
        if ($localApiKey -and $localApiKey -ne "YOUR_OPENWEATHERMAP_API_KEY_HERE") {
            Write-Host "Found real API Key in config.local.json" -ForegroundColor Cyan
            Write-Host "Key: $($localApiKey.Substring(0, 8))...$($localApiKey.Substring($localApiKey.Length - 4))" -ForegroundColor Gray
        }
    }
    
    # 同步示例文件（如果存在）
    if (Test-Path "config.example.json") {
        Copy-Item "config.example.json" "public\config.example.json" -Force
        Write-Host "Synced: config.example.json -> public\config.example.json" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host "Sync completed!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    
    # 提示后续操作
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "   npm run dev" -ForegroundColor Gray
    Write-Host "   npm run build" -ForegroundColor Gray
    Write-Host "   npx cap sync android" -ForegroundColor Gray
    Write-Host "   cd android; .\gradlew.bat assembleDebug" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host "Sync failed: $_" -ForegroundColor Red
    exit 1
}
