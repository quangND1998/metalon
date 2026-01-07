# PowerShell script để chạy Meltano commands trong Docker
# Usage: .\docker-run.ps1 [command] [args...]
# Examples:
#   .\docker-run.ps1 meltano run tap-mysql target-postgres
#   .\docker-run.ps1 meltano invoke tap-mysql --discover
#   .\docker-run.ps1 meltano select tap-mysql "*.*"

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Command
)

if ($Command.Count -eq 0) {
    Write-Host "Usage: .\docker-run.ps1 [meltano command] [args...]" -ForegroundColor Yellow
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\docker-run.ps1 meltano run tap-mysql target-postgres" -ForegroundColor Gray
    Write-Host "  .\docker-run.ps1 meltano invoke tap-mysql --discover" -ForegroundColor Gray
    Write-Host "  .\docker-run.ps1 meltano select tap-mysql `"*.*`"" -ForegroundColor Gray
    exit 1
}

$fullCommand = $Command -join " "
Write-Host "Running: docker-compose run --rm meltano $fullCommand" -ForegroundColor Green
docker-compose run --rm meltano $fullCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "Command failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}





