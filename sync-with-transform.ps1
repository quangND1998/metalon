# Script để chạy đồng bộ MySQL sang PostgreSQL với transform datetime
# Usage: .\sync-with-transform.ps1 [--full-refresh]

param(
    [switch]$FullRefresh
)

Write-Host "Starting sync with datetime transform..." -ForegroundColor Green
Write-Host ""

$command = "meltano invoke tap-mysql | python3 /app/transform_datetime.py | meltano invoke target-postgres"

if ($FullRefresh) {
    Write-Host "Running full refresh sync..." -ForegroundColor Yellow
    Write-Host "Note: Full refresh requires manual state reset" -ForegroundColor Yellow
}

Write-Host "Running: docker-compose run --rm meltano bash -c `"$command`"" -ForegroundColor Cyan
Write-Host ""

docker-compose run --rm meltano bash -c $command

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSync completed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nSync failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

