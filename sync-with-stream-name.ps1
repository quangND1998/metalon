# Script để chạy đồng bộ MySQL sang PostgreSQL với transform stream name
# Usage: .\sync-with-stream-name.ps1 [--full-refresh]

param(
    [switch]$FullRefresh
)

Write-Host "Starting sync with stream name transform..." -ForegroundColor Green
Write-Host "Stream mappings:" -ForegroundColor Cyan
Write-Host "  - wealify_db-virtual-accounts -> virtual_accounts" -ForegroundColor Cyan
Write-Host "  - wealify_db-virtual-cards -> virtual_cards" -ForegroundColor Cyan
Write-Host "  - wealify_db-kyc-level2-data-vc -> kyc_level2_data_vc" -ForegroundColor Cyan
Write-Host "  - wealify_db-system-payment-changes -> system-payment-changes" -ForegroundColor Cyan
Write-Host "  - wealify_db-system-payment-limits -> system-payment-limits" -ForegroundColor Cyan
Write-Host "  - wealify_db-system-payment-priority -> system-payment-priority" -ForegroundColor Cyan
Write-Host "  - wealify_db-system-payments -> system-payments" -ForegroundColor Cyan
Write-Host "  - wealify_db-transaction-histories -> transaction-histories" -ForegroundColor Cyan
Write-Host ""

# Check state
$statePath = ".\.meltano\state\tap-mysql-to-target-postgres.json"
$hasState = Test-Path $statePath

if ($FullRefresh) {
    Write-Host "Running full refresh sync..." -ForegroundColor Yellow
    if ($hasState) {
        Write-Host "Removing existing state file for full refresh..." -ForegroundColor Yellow
        Remove-Item $statePath -Force -ErrorAction SilentlyContinue
    }
} elseif (-not $hasState) {
    Write-Host "No state found - running FULL REFRESH..." -ForegroundColor Yellow
} else {
    Write-Host "State found - running INCREMENTAL sync..." -ForegroundColor Green
}

Write-Host ""
Write-Host "Running: meltano invoke tap-mysql | python3 transform_stream_name.py | meltano invoke target-postgres" -ForegroundColor Cyan
Write-Host ""

# Run with stream name transform
# Meltano will automatically load catalog from .meltano/catalog/ and apply selections from meltano.yml
docker-compose run --rm meltano bash -c "meltano invoke tap-mysql | python3 /app/transform_stream_name.py | meltano invoke target-postgres"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSync completed successfully!" -ForegroundColor Green
    Write-Host "Tables created in PostgreSQL with renamed streams" -ForegroundColor Green
} else {
    Write-Host "`nSync failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

