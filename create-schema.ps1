# Script để tạo schema airbyte_raw trong PostgreSQL
# Usage: .\create-schema.ps1 [schema_name]

param(
    [string]$SchemaName = "airbyte_raw"
)

Write-Host "=== Creating PostgreSQL Schema ===" -ForegroundColor Cyan
Write-Host ""

# Load environment variables from .env file
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}

# Get PostgreSQL connection info
$postgresUser = [Environment]::GetEnvironmentVariable("POSTGRES_USER", "Process")
$postgresPassword = [Environment]::GetEnvironmentVariable("POSTGRES_PASSWORD", "Process")
$postgresDbname = [Environment]::GetEnvironmentVariable("POSTGRES_DBNAME", "Process")

if (-not $postgresUser) { $postgresUser = "postgres" }
if (-not $postgresDbname) { $postgresDbname = "testdb" }

Write-Host "Schema name: $SchemaName" -ForegroundColor Yellow
Write-Host "Database: $postgresDbname" -ForegroundColor Yellow
Write-Host "User: $postgresUser" -ForegroundColor Yellow
Write-Host ""

# Check if postgres container is running
$postgresRunning = docker ps --filter "name=meltano-postgres" --format "{{.Names}}" | Select-String "meltano-postgres"

if (-not $postgresRunning) {
    Write-Host "PostgreSQL container is not running. Starting it..." -ForegroundColor Yellow
    docker-compose up -d postgres
    Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
}

Write-Host "Creating schema '$SchemaName'..." -ForegroundColor Cyan

# Create schema using psql
$sqlCommand = "CREATE SCHEMA IF NOT EXISTS $SchemaName;"
$env:PGPASSWORD = $postgresPassword

docker-compose exec -T postgres psql -U $postgresUser -d $postgresDbname -c $sqlCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Schema '$SchemaName' created successfully!" -ForegroundColor Green
    
    # Verify schema exists
    Write-Host ""
    Write-Host "Verifying schema exists..." -ForegroundColor Cyan
    $verifyCommand = "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '$SchemaName';"
    docker-compose exec -T postgres psql -U $postgresUser -d $postgresDbname -c $verifyCommand
} else {
    Write-Host ""
    Write-Host "Failed to create schema. Exit code: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green

