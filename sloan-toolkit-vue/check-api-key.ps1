# API Key 配置验证脚本
# 快速检查配置文件状态和 API Key

Write-Host "================================" -ForegroundColor Cyan
Write-Host "   API Key Configuration Check" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 检查根目录配置文件
Write-Host "Checking root directory..." -ForegroundColor Yellow

$files = @("config.json", "config.local.json", "config.example.json")

foreach ($file in $files) {
    if (Test-Path $file) {
        $config = Get-Content $file -Raw | ConvertFrom-Json
        $apiKey = $config.apiKey
        
        $status = if ($apiKey -match '^[a-f0-9]{32}$') { "Real API Key" } else { "Placeholder" }
        $statusColor = if ($status -eq "Real API Key") { "Green" } else { "Yellow" }
        
        Write-Host "  $file" -NoNewline
        Write-Host " - " -NoNewline
        Write-Host $status -ForegroundColor $statusColor
        
        if ($status -eq "Real API Key") {
            Write-Host "    Key: $($apiKey.Substring(0, 8))...$($apiKey.Substring($apiKey.Length - 4))" -ForegroundColor Gray
        }
    } else {
        Write-Host "  $file - " -NoNewline
        Write-Host "Not Found" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Checking public directory..." -ForegroundColor Yellow

foreach ($file in $files) {
    $publicFile = "public\$file"
    if (Test-Path $publicFile) {
        $config = Get-Content $publicFile -Raw | ConvertFrom-Json
        $apiKey = $config.apiKey
        
        $status = if ($apiKey -match '^[a-f0-9]{32}$') { "Real API Key" } else { "Placeholder" }
        $statusColor = if ($status -eq "Real API Key") { "Green" } else { "Yellow" }
        
        Write-Host "  public\$file" -NoNewline
        Write-Host " - " -NoNewline
        Write-Host $status -ForegroundColor $statusColor
    } else {
        Write-Host "  public\$file - " -NoNewline
        Write-Host "Not Found" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Checking dist directory..." -ForegroundColor Yellow

if (Test-Path "dist") {
    foreach ($file in $files) {
        $distFile = "dist\$file"
        if (Test-Path $distFile) {
            $config = Get-Content $distFile -Raw | ConvertFrom-Json
            $apiKey = $config.apiKey
            
            $status = if ($apiKey -match '^[a-f0-9]{32}$') { "Real API Key" } else { "Placeholder" }
            $statusColor = if ($status -eq "Real API Key") { "Green" } else { "Yellow" }
            
            Write-Host "  dist\$file" -NoNewline
            Write-Host " - " -NoNewline
            Write-Host $status -ForegroundColor $statusColor
        }
    }
} else {
    Write-Host "  dist directory not found (run 'npm run build' first)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Checking Android assets..." -ForegroundColor Yellow

if (Test-Path "android\app\src\main\assets\public") {
    foreach ($file in $files) {
        $androidFile = "android\app\src\main\assets\public\$file"
        if (Test-Path $androidFile) {
            $config = Get-Content $androidFile -Raw | ConvertFrom-Json
            $apiKey = $config.apiKey
            
            $status = if ($apiKey -match '^[a-f0-9]{32}$') { "Real API Key" } else { "Placeholder" }
            $statusColor = if ($status -eq "Real API Key") { "Green" } else { "Yellow" }
            
            Write-Host "  android\assets\$file" -NoNewline
            Write-Host " - " -NoNewline
            Write-Host $status -ForegroundColor $statusColor
        }
    }
} else {
    Write-Host "  Android assets not found (run 'npx cap sync android' first)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  The app will try to load in this order:" -ForegroundColor White
Write-Host "  1. /config.local.json (priority)" -ForegroundColor Green
Write-Host "  2. /config.json (fallback)" -ForegroundColor Yellow
Write-Host ""
Write-Host "  To build with real API Key:" -ForegroundColor Cyan
Write-Host "  1. Ensure config.local.json contains real key" -ForegroundColor Gray
Write-Host "  2. Run: .\sync-config.ps1" -ForegroundColor Gray
Write-Host "  3. Run: npm run build" -ForegroundColor Gray
Write-Host "  4. Run: npx cap sync android" -ForegroundColor Gray
Write-Host "================================" -ForegroundColor Cyan
