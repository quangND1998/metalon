# Script tự động phát hiện lần đầu (full refresh) hay incremental sync
# Usage: .\sync-auto.ps1 [--force-full-refresh]

param(
    [switch]$ForceFullRefresh
)

Write-Host "Checking sync state..." -ForegroundColor Cyan

# Kiểm tra xem có state không (trong volume .meltano)
$statePath = ".\.meltano\state\tap-mysql-to-target-postgres.json"
$hasState = Test-Path $statePath

if ($ForceFullRefresh) {
    Write-Host "Force full refresh requested..." -ForegroundColor Yellow
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

# Chạy sync với transform
Write-Host ""
Write-Host "Running: docker-compose run --rm meltano bash -c `"meltano invoke tap-mysql | python3 /app/transform_datetime.py | meltano invoke target-postgres`"" -ForegroundColor Cyan
docker-compose run --rm meltano bash -c "meltano invoke tap-mysql | python3 /app/transform_datetime.py | meltano invoke target-postgres"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSync completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nSync failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

