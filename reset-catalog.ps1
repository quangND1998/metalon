# Script để xóa catalog và rebuild Docker mà không xóa database data
# Usage: .\reset-catalog.ps1

Write-Host "=== Reset Meltano Catalog and Rebuild Docker ===" -ForegroundColor Cyan
Write-Host ""

# 1. Dừng containers (nếu đang chạy)
Write-Host "1. Stopping containers..." -ForegroundColor Yellow
docker-compose down

# 2. Xóa catalog và state (KHÔNG xóa database data)
Write-Host ""
Write-Host "2. Removing Meltano catalog and state..." -ForegroundColor Yellow
if (Test-Path ".\.meltano") {
    # Xóa catalog và state, giữ lại plugins nếu muốn
    if (Test-Path ".\.meltano\catalog") {
        Remove-Item ".\.meltano\catalog" -Recurse -Force
        Write-Host "   - Removed .meltano\catalog" -ForegroundColor Green
    }
    if (Test-Path ".\.meltano\state") {
        Remove-Item ".\.meltano\state" -Recurse -Force
        Write-Host "   - Removed .meltano\state" -ForegroundColor Green
    }
    if (Test-Path ".\.meltano\run") {
        Remove-Item ".\.meltano\run" -Recurse -Force
        Write-Host "   - Removed .meltano\run" -ForegroundColor Green
    }
    # Giữ lại plugins để không phải cài lại
    Write-Host "   - Keeping .meltano\plugins (to avoid reinstalling)" -ForegroundColor Cyan
} else {
    Write-Host "   - .meltano directory not found, skipping..." -ForegroundColor Gray
}

# 3. Rebuild Docker image (chỉ rebuild meltano service)
Write-Host ""
Write-Host "3. Rebuilding Docker image..." -ForegroundColor Yellow
docker-compose build --no-cache meltano

# 4. Start containers lại
Write-Host ""
Write-Host "4. Starting containers..." -ForegroundColor Yellow
docker-compose up -d mysql postgres

# Đợi databases sẵn sàng
Write-Host "   Waiting for databases to be ready..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# 5. Hiển thị thông tin
Write-Host ""
Write-Host "=== Reset Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run discovery to regenerate catalog:" -ForegroundColor White
Write-Host "     docker-compose run --rm meltano meltano invoke tap-mysql --discover" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Or run sync (will auto-discover if needed):" -ForegroundColor White
Write-Host "     .\sync.ps1 --full-refresh" -ForegroundColor Gray
Write-Host ""
Write-Host "Note: Database data is preserved in Docker volumes" -ForegroundColor Green
Write-Host "      (mysql_data and postgres_data volumes)" -ForegroundColor Green

