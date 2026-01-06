# Danh Sách Lệnh Nhanh

File này chứa các lệnh thường dùng nhất để chạy dự án. Xem `QUICKSTART.md` để biết hướng dẫn chi tiết.

## 🚀 Setup Lần Đầu

```powershell
# 1. Tạo thư mục keys và đặt file PEM key
mkdir keys
# Copy file PEM key vào thư mục keys/
# Ví dụ: keys/thehuman-wealify-keypair.pem

# 2. Tạo file .env với nội dung:
# SSH Tunnel Configuration
# SSH_HOST=your_ssh_host
# SSH_PORT=22
# SSH_USERNAME=your_ssh_username
# MYSQL_RDS_HOST=your_mysql_rds_host
# MYSQL_RDS_PORT=3306
# SSH_KEY_FILE=your_key_file.pem
#
# MySQL Connection
# MYSQL_HOST=ssh-tunnel
# MYSQL_PORT=3306
# MYSQL_USER=your_mysql_user
# MYSQL_PASSWORD=your_mysql_password
# MYSQL_DATABASE=your_mysql_database
#
# PostgreSQL Connection
# POSTGRES_HOST=postgres
# POSTGRES_PORT=5432
# POSTGRES_USER=postgres
# POSTGRES_PASSWORD=postgres
# POSTGRES_DBNAME=testdb
# POSTGRES_DEFAULT_TARGET_SCHEMA=airbyte_raw

# 3. Build Docker image
docker-compose build

# 4. Khởi động SSH tunnel và PostgreSQL
docker-compose up -d ssh-tunnel postgres

# 5. Kiểm tra SSH tunnel đang chạy
docker-compose ps ssh-tunnel
docker-compose logs ssh-tunnel

# 6. Tạo schema PostgreSQL
.\create-schema.ps1

# 7. Chạy discovery
docker-compose run --rm meltano meltano invoke tap-mysql --discover

# 8. Chạy sync lần đầu
.\sync.ps1 --full-refresh
```

## 📊 Sync Dữ Liệu

```powershell
# Full refresh (sync tất cả dữ liệu)
.\sync.ps1 --full-refresh

# Incremental sync (chỉ sync dữ liệu mới/thay đổi)
.\sync.ps1

# Sync với transform datetime
.\sync-with-transform.ps1
```

## 🔍 Kiểm Tra và Debug

```powershell
# Kiểm tra containers đang chạy
docker-compose ps

# Kiểm tra SSH tunnel đang chạy
docker-compose ps ssh-tunnel
docker-compose logs ssh-tunnel

# Test kết nối MySQL qua SSH tunnel (dùng discovery của Meltano)
docker-compose run --rm meltano meltano invoke tap-mysql --discover

# Xem logs
docker-compose logs -f meltano
docker-compose logs -f ssh-tunnel
docker-compose logs -f postgres

# Debug cấu hình
.\debug-sync.ps1

# Kiểm tra cấu hình Meltano
docker-compose run --rm meltano config list target-postgres
docker-compose run --rm meltano config list tap-mysql
```

## 🗄️ Quản Lý Database

```powershell
# Kết nối MySQL
docker-compose exec mysql mysql -u root -p

# Kết nối PostgreSQL
docker-compose exec postgres psql -U postgres -d your_database

# Tạo schema mới
docker-compose exec postgres psql -U postgres -d your_database -c "CREATE SCHEMA IF NOT EXISTS schema_name;"

# Xem danh sách schemas
docker-compose exec postgres psql -U postgres -d your_database -c "\dn"

# Xem danh sách tables trong schema
docker-compose exec postgres psql -U postgres -d your_database -c "\dt airbyte_raw.*"
```

## 🔄 Reset và Cleanup

```powershell
# Reset catalog (giữ lại database data)
.\reset-catalog.ps1

# Xóa catalog thủ công
Remove-Item .\.meltano\catalog -Recurse -Force

# Xóa state thủ công
Remove-Item .\.meltano\state -Recurse -Force

# Dừng containers
docker-compose down

# Dừng và xóa volumes (XÓA DỮ LIỆU!)
docker-compose down -v

# Khởi động lại containers
docker-compose up -d
```

## 📋 Chọn Tables

```powershell
# Chọn table cụ thể
docker-compose run --rm meltano meltano select tap-mysql "database.table" "*"

# Xem danh sách đã chọn
docker-compose run --rm meltano meltano select tap-mysql --list

# Xem hướng dẫn chi tiết
# Mở file SELECT_TABLES.md
```

## 🛠️ Troubleshooting Nhanh

```powershell
# Containers không chạy
docker-compose up -d

# Schema không tồn tại
.\create-schema.ps1

# Lỗi datetime
.\sync-with-transform.ps1

# Reset hoàn toàn (XÓA TẤT CẢ!)
docker-compose down -v
Remove-Item .\.meltano -Recurse -Force
docker-compose build
docker-compose up -d
.\create-schema.ps1
.\sync.ps1 --full-refresh
```

## 📖 Xem Dữ Liệu

```powershell
# Kết nối PostgreSQL và xem dữ liệu
docker-compose exec postgres psql -U postgres -d your_database

# Trong psql shell:
# \dn                    # Liệt kê schemas
# \dt airbyte_raw.*      # Liệt kê tables
# SELECT * FROM airbyte_raw.table_name LIMIT 10;
# \q                     # Thoát
```

---

**Lưu ý:** Thay `your_database` bằng tên database thực tế từ file `.env`

**Xem `QUICKSTART.md` để biết hướng dẫn chi tiết từng bước**

