# Script để debug sync và xem lỗi chi tiết
# Usage: .\debug-sync.ps1

Write-Host "=== Debug Sync Configuration ===" -ForegroundColor Cyan
Write-Host ""

# Load environment variables
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}

# Check environment variables
Write-Host "Environment Variables:" -ForegroundColor Yellow
$postgresSchema = [Environment]::GetEnvironmentVariable("POSTGRES_DEFAULT_TARGET_SCHEMA", "Process")
if (-not $postgresSchema) { $postgresSchema = "airbyte_raw (default)" }
Write-Host "  POSTGRES_DEFAULT_TARGET_SCHEMA: $postgresSchema" -ForegroundColor White

$postgresHost = [Environment]::GetEnvironmentVariable("POSTGRES_HOST", "Process")
$postgresDbname = [Environment]::GetEnvironmentVariable("POSTGRES_DBNAME", "Process")
$postgresUser = [Environment]::GetEnvironmentVariable("POSTGRES_USER", "Process")
Write-Host "  POSTGRES_HOST: $postgresHost" -ForegroundColor White
Write-Host "  POSTGRES_DBNAME: $postgresDbname" -ForegroundColor White
Write-Host "  POSTGRES_USER: $postgresUser" -ForegroundColor White
Write-Host ""

# Check if schema exists
Write-Host "Checking if schema 'airbyte_raw' exists..." -ForegroundColor Yellow
$postgresPassword = [Environment]::GetEnvironmentVariable("POSTGRES_PASSWORD", "Process")
if (-not $postgresPassword) { $postgresPassword = "postgres" }
if (-not $postgresUser) { $postgresUser = "postgres" }
if (-not $postgresDbname) { $postgresDbname = "testdb" }

$env:PGPASSWORD = $postgresPassword
try {
    $schemaCheck = docker-compose exec -T postgres psql -U $postgresUser -d $postgresDbname -t -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'airbyte_raw';" 2>&1 | Out-String
    
    if ($schemaCheck -match "airbyte_raw") {
        Write-Host "  [OK] Schema 'airbyte_raw' exists" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Schema 'airbyte_raw' does NOT exist" -ForegroundColor Red
        Write-Host "  Run: .\create-schema.ps1" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [WARNING] Could not check schema: $_" -ForegroundColor Yellow
}
Write-Host ""

# Check Meltano configuration
Write-Host "Checking Meltano configuration..." -ForegroundColor Yellow
try {
    $meltanoConfig = docker-compose run --rm meltano config list target-postgres 2>&1 | Out-String
    Write-Host $meltanoConfig
} catch {
    Write-Host "  [WARNING] Could not get Meltano config: $_" -ForegroundColor Yellow
}
Write-Host ""

# Test connection
Write-Host "Testing PostgreSQL connection..." -ForegroundColor Yellow
try {
    $connectionTest = docker-compose exec -T postgres psql -U $postgresUser -d $postgresDbname -c "SELECT version();" 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] PostgreSQL connection OK" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] PostgreSQL connection FAILED" -ForegroundColor Red
        Write-Host $connectionTest
    }
} catch {
    Write-Host "  [ERROR] Could not test connection: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Ready to sync ===" -ForegroundColor Cyan
Write-Host "Run: .\sync.ps1 --full-refresh" -ForegroundColor Yellow

