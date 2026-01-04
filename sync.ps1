# Script để chạy đồng bộ MySQL sang PostgreSQL
# Usage: .\sync.ps1 [--full-refresh] [--discover] [--tap TAP_NAME] [--target TARGET_NAME] [--list]

param(
    [switch]$FullRefresh,
    [switch]$Discover,
    [string]$Tap = "tap-mysql",
    [string]$Target = "target-postgres",
    [switch]$List
)

# Load environment variables from .env file
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
} else {
    Write-Warning ".env file not found! Please create it from .env.example"
    exit 1
}

# Hiển thị danh sách các extractors và loaders có sẵn
if ($List) {
    Write-Host "`n=== Available Extractors ===" -ForegroundColor Cyan
    meltano list extractors
    Write-Host "`n=== Available Loaders ===" -ForegroundColor Cyan
    meltano list loaders
    Write-Host "`n=== Available Schedules ===" -ForegroundColor Cyan
    meltano schedule list
    exit 0
}

if ($Discover) {
    Write-Host "Discovering MySQL schemas using $Tap..." -ForegroundColor Green
    $schemaFile = "schema_$($Tap -replace 'tap-mysql', 'mysql').json"
    meltano invoke $Tap --discover | Out-File -FilePath $schemaFile -Encoding utf8
    Write-Host "Schema saved to $schemaFile" -ForegroundColor Green
    exit 0
}

Write-Host "Using extractor: $Tap" -ForegroundColor Cyan
Write-Host "Using loader: $Target" -ForegroundColor Cyan
Write-Host ""

if ($FullRefresh) {
    Write-Host "Running full refresh sync..." -ForegroundColor Yellow
    meltano run $Tap $Target --full-refresh
} else {
    Write-Host "Running incremental sync..." -ForegroundColor Green
    meltano run $Tap $Target
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Sync completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Sync failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
