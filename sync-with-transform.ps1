# Script để chạy đồng bộ MySQL sang PostgreSQL với transform datetime
# Usage: .\sync-with-transform.ps1 [--full-refresh]

param(
    [switch]$FullRefresh
)

Write-Host "Starting sync with datetime transform..." -ForegroundColor Green
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
    $refreshFlag = "true"
} elseif (-not $hasState) {
    Write-Host "No state found - running FULL REFRESH..." -ForegroundColor Yellow
    $refreshFlag = "true"
} else {
    Write-Host "State found - running INCREMENTAL sync..." -ForegroundColor Green
    $refreshFlag = "false"
}

$command = "bash /app/sync-with-state.sh tap-mysql target-postgres $refreshFlag"

Write-Host ""
Write-Host "Running: docker-compose run --rm meltano bash -c `"$command`"" -ForegroundColor Cyan
Write-Host ""

docker-compose run --rm meltano bash -c $command

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSync completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nSync failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}


