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

# Check if transform_datetime.py exists and use it if available
$useTransform = Test-Path "transform_datetime.py"

# Kiểm tra state để tự động quyết định full refresh hay incremental
$statePath = ".\.meltano\state\tap-mysql-to-target-postgres.json"
$hasState = Test-Path $statePath

if ($FullRefresh) {
    Write-Host "Full refresh requested..." -ForegroundColor Yellow
    if ($hasState) {
        Write-Host "Removing existing state file for full refresh..." -ForegroundColor Yellow
        Remove-Item $statePath -Force -ErrorAction SilentlyContinue
    }
} elseif (-not $hasState) {
    Write-Host "No state found - this appears to be the first sync" -ForegroundColor Yellow
    Write-Host "Running FULL REFRESH (sync all data)..." -ForegroundColor Yellow
} else {
    Write-Host "State found - running INCREMENTAL sync (only new/changed data)..." -ForegroundColor Green
}

if ($useTransform) {
    Write-Host "Using datetime transform to handle invalid MySQL datetime values..." -ForegroundColor Yellow
    # Use wrapper script to ensure state is managed properly with transform
    $refreshFlag = if ($FullRefresh -or -not $hasState) { "true" } else { "false" }
    $command = "bash /app/sync-with-state.sh $Tap $Target $refreshFlag"
    
    if ($FullRefresh -or -not $hasState) {
        Write-Host "Running full refresh sync with transform..." -ForegroundColor Yellow
        if ($hasState) {
            Remove-Item $statePath -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "Running incremental sync with transform..." -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Running: docker-compose run --rm meltano bash -c `"$command`"" -ForegroundColor Cyan
    docker-compose run --rm meltano bash -c $command
} else {
    if (-not $hasState -or $FullRefresh) {
        Write-Host "Running full refresh sync..." -ForegroundColor Yellow
        docker-compose run --rm meltano meltano run $Tap $Target --full-refresh
    } else {
        Write-Host "Running incremental sync..." -ForegroundColor Green
        docker-compose run --rm meltano meltano run $Tap $Target
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Sync completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Sync failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
