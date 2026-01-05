# Hướng dẫn Chạy Dự Án Từ Đầu

Hướng dẫn chi tiết để setup và chạy dự án đồng bộ MySQL sang PostgreSQL với Meltano.

## 📋 Mục Lục

1. [Yêu Cầu Hệ Thống](#yêu-cầu-hệ-thống)
2. [Cài Đặt Docker](#cài-đặt-docker)
3. [Cấu Hình Dự Án](#cấu-hình-dự-án)
4. [Build và Chạy Containers](#build-và-chạy-containers)
5. [Tạo Schema PostgreSQL](#tạo-schema-postgresql)
6. [Chạy Sync Lần Đầu](#chạy-sync-lần-đầu)
7. [Các Lệnh Thường Dùng](#các-lệnh-thường-dùng)
8. [Troubleshooting](#troubleshooting)

---

## 🖥️ Yêu Cầu Hệ Thống

- **Windows 10/11** hoặc **Linux** hoặc **macOS**
- **Docker Desktop** (Windows/Mac) hoặc **Docker Engine + Docker Compose** (Linux)
- **PowerShell** (Windows) hoặc **Bash** (Linux/Mac)
- Kết nối internet để download Docker images

---

## 🐳 Cài Đặt Docker

### Windows

1. Tải và cài đặt [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
2. Khởi động Docker Desktop
3. Đảm bảo Docker đang chạy (icon Docker trong system tray)

### Linux

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io docker-compose-plugin

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

### macOS

1. Tải và cài đặt [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
2. Khởi động Docker Desktop

**Kiểm tra cài đặt:**
```powershell
# Windows PowerShell
docker --version
docker-compose --version
```

```bash
# Linux/Mac
docker --version
docker compose version
```

---

## ⚙️ Cấu Hình Dự Án

### Bước 1: Clone hoặc Download dự án

```powershell
# Nếu dùng Git
git clone <repository-url>
cd metalon
```

### Bước 2: Tạo file `.env`

Tạo file `.env` trong thư mục gốc của dự án với nội dung:

```bash
# MySQL Connection
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_mysql_password
MYSQL_DATABASE=your_mysql_database

# PostgreSQL Connection
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_DBNAME=your_postgres_database
POSTGRES_DEFAULT_TARGET_SCHEMA=airbyte_raw
```

**Lưu ý:**
- Nếu dùng database bên ngoài (không phải Docker containers), thay `mysql` và `postgres` bằng `localhost` hoặc IP thực tế
- Thay `your_mysql_password`, `your_postgres_password`, `your_mysql_database`, `your_postgres_database` bằng giá trị thực tế
- Schema mặc định là `airbyte_raw` (có thể đổi trong file `.env`)

### Bước 3: Kiểm tra file cấu hình

Đảm bảo các file sau tồn tại:
- ✅ `docker-compose.yml`
- ✅ `meltano.yml`
- ✅ `Dockerfile`
- ✅ `.env` (file bạn vừa tạo)

---

## 🏗️ Build và Chạy Containers

### Bước 1: Build Docker image

```powershell
# Windows PowerShell
docker-compose build
```

```bash
# Linux/Mac
docker compose build
```

**Lần đầu build có thể mất 5-10 phút** (download base images và cài đặt dependencies)

### Bước 2: Khởi động containers

```powershell
# Windows PowerShell
docker-compose up -d
```

```bash
# Linux/Mac
docker compose up -d
```

Lệnh này sẽ:
- Tạo và khởi động container MySQL
- Tạo và khởi động container PostgreSQL
- Tạo network để các containers giao tiếp với nhau

### Bước 3: Kiểm tra containers đang chạy

```powershell
# Windows PowerShell
docker-compose ps
```

```bash
# Linux/Mac
docker compose ps
```

Bạn sẽ thấy 3 containers:
- `meltano-mysql` - MySQL database
- `meltano-postgres` - PostgreSQL database
- `meltano-sync` - Meltano service (chỉ chạy khi cần)

### Bước 4: Xem logs (nếu cần)

```powershell
# Windows PowerShell
docker-compose logs -f mysql
docker-compose logs -f postgres
```

```bash
# Linux/Mac
docker compose logs -f mysql
docker compose logs -f postgres
```

---

## 🗄️ Tạo Schema PostgreSQL

Trước khi chạy sync, cần tạo schema `airbyte_raw` trong PostgreSQL:

### Cách 1: Dùng script tự động (Khuyến nghị)

```powershell
# Windows PowerShell
.\create-schema.ps1
```

Script sẽ tự động:
- Đọc cấu hình từ file `.env`
- Tạo schema `airbyte_raw` trong PostgreSQL
- Kiểm tra schema đã được tạo thành công

### Cách 2: Chạy thủ công

```powershell
# Windows PowerShell
docker-compose exec postgres psql -U postgres -d your_postgres_database -c "CREATE SCHEMA IF NOT EXISTS airbyte_raw;"
```

```bash
# Linux/Mac
docker compose exec postgres psql -U postgres -d your_postgres_database -c "CREATE SCHEMA IF NOT EXISTS airbyte_raw;"
```

**Thay `your_postgres_database` bằng tên database thực tế từ file `.env`**

### Kiểm tra schema đã tạo

```powershell
# Windows PowerShell
docker-compose exec postgres psql -U postgres -d your_postgres_database -c "\dn"
```

```bash
# Linux/Mac
docker compose exec postgres psql -U postgres -d your_postgres_database -c "\dn"
```

Bạn sẽ thấy schema `airbyte_raw` trong danh sách.

---

## 🚀 Chạy Sync Lần Đầu

### Bước 1: Chạy Discovery (Khám phá schema MySQL)

```powershell
# Windows PowerShell
docker-compose run --rm meltano meltano invoke tap-mysql --discover
```

```bash
# Linux/Mac
docker compose run --rm meltano meltano invoke tap-mysql --discover
```

Lệnh này sẽ:
- Kết nối đến MySQL
- Khám phá tất cả tables và columns
- Lưu catalog vào `.meltano/catalog/`

### Bước 2: Chọn tables cần sync (Optional)

Nếu bạn chỉ muốn sync một số tables cụ thể:

```powershell
# Windows PowerShell
# Ví dụ: chọn table users trong database mydb
docker-compose run --rm meltano meltano select tap-mysql "mydb.users" "*"

# Xem danh sách đã chọn
docker-compose run --rm meltano meltano select tap-mysql --list
```

Xem file `SELECT_TABLES.md` để biết chi tiết cách chọn tables.

### Bước 3: Chạy Sync với Script (Dễ nhất)

```powershell
# Windows PowerShell
.\sync.ps1 --full-refresh
```

Script này sẽ:
- Tự động dùng transform datetime để xử lý giá trị datetime không hợp lệ
- Chạy full refresh (sync tất cả dữ liệu)
- Hiển thị progress và kết quả

### Bước 4: Chạy Sync thủ công (Nếu cần)

```powershell
# Windows PowerShell
# Full refresh (sync tất cả dữ liệu)
docker-compose run --rm meltano bash -c "meltano invoke tap-mysql | python3 /app/transform_datetime.py | meltano invoke target-postgres"

# Hoặc incremental sync (chỉ sync dữ liệu mới/thay đổi)
docker-compose run --rm meltano meltano run tap-mysql target-postgres
```

---

## 📝 Các Lệnh Thường Dùng

### Sync dữ liệu

```powershell
# Windows PowerShell - Full refresh
.\sync.ps1 --full-refresh

# Windows PowerShell - Incremental sync (tự động)
.\sync.ps1

# Windows PowerShell - Sync với transform datetime
.\sync-with-transform.ps1
```

### Quản lý containers

```powershell
# Windows PowerShell
# Dừng tất cả containers
docker-compose down

# Dừng và xóa volumes (XÓA DỮ LIỆU!)
docker-compose down -v

# Khởi động lại containers
docker-compose up -d

# Xem logs
docker-compose logs -f meltano

# Xem logs của database
docker-compose logs -f mysql
docker-compose logs -f postgres
```

### Quản lý catalog và state

```powershell
# Windows PowerShell
# Reset catalog và state (giữ lại database data)
.\reset-catalog.ps1

# Xóa catalog thủ công
Remove-Item .\.meltano\catalog -Recurse -Force

# Xóa state thủ công
Remove-Item .\.meltano\state -Recurse -Force
```

### Debug và kiểm tra

```powershell
# Windows PowerShell
# Debug cấu hình
.\debug-sync.ps1

# Kiểm tra cấu hình Meltano
docker-compose run --rm meltano config list target-postgres

# Kiểm tra kết nối MySQL
docker-compose exec mysql mysql -u root -p -e "SHOW DATABASES;"

# Kiểm tra kết nối PostgreSQL
docker-compose exec postgres psql -U postgres -d your_database -c "SELECT version();"
```

### Xem dữ liệu đã sync

```powershell
# Windows PowerShell
# Kết nối vào PostgreSQL
docker-compose exec postgres psql -U postgres -d your_database

# Trong psql shell:
# \dn                    # Liệt kê schemas
# \dt airbyte_raw.*      # Liệt kê tables trong schema airbyte_raw
# SELECT * FROM airbyte_raw.your_table LIMIT 10;
# \q                     # Thoát
```

---

## 🔧 Troubleshooting

### Lỗi: "Container không chạy"

**Giải pháp:**
```powershell
# Kiểm tra containers
docker-compose ps

# Khởi động lại
docker-compose up -d

# Xem logs để tìm lỗi
docker-compose logs mysql
docker-compose logs postgres
```

### Lỗi: "Schema không tồn tại"

**Giải pháp:**
```powershell
# Tạo schema
.\create-schema.ps1

# Hoặc thủ công
docker-compose exec postgres psql -U postgres -d your_database -c "CREATE SCHEMA IF NOT EXISTS airbyte_raw;"
```

### Lỗi: "Datetime field value out of range"

**Giải pháp:**
Script `sync.ps1` đã tự động dùng transform datetime. Nếu vẫn lỗi:
```powershell
# Đảm bảo transform_datetime.py tồn tại
Test-Path transform_datetime.py

# Chạy sync với transform
.\sync-with-transform.ps1
```

### Lỗi: "Connection refused" hoặc "Cannot connect to database"

**Giải pháp:**
1. Kiểm tra containers đang chạy: `docker-compose ps`
2. Kiểm tra file `.env` có đúng cấu hình không
3. Kiểm tra network: `docker network ls`
4. Khởi động lại: `docker-compose restart`

### Lỗi: "Catalog not found"

**Giải pháp:**
```powershell
# Chạy discovery lại
docker-compose run --rm meltano meltano invoke tap-mysql --discover
```

### Reset hoàn toàn (XÓA TẤT CẢ DỮ LIỆU!)

```powershell
# Dừng và xóa containers + volumes
docker-compose down -v

# Xóa catalog và state
Remove-Item .\.meltano -Recurse -Force

# Build lại
docker-compose build

# Chạy lại từ đầu
docker-compose up -d
.\create-schema.ps1
.\sync.ps1 --full-refresh
```

### Xem logs chi tiết

```powershell
# Windows PowerShell
# Logs của Meltano
docker-compose logs meltano

# Logs của MySQL
docker-compose logs mysql

# Logs của PostgreSQL
docker-compose logs postgres

# Logs real-time
docker-compose logs -f
```

---

## 📚 Tài Liệu Tham Khảo

- **README.md** - Tài liệu tổng quan về dự án
- **SELECT_TABLES.md** - Hướng dẫn chi tiết về chọn tables
- [Meltano Documentation](https://docs.meltano.com/)
- [Docker Documentation](https://docs.docker.com/)

---

## ✅ Checklist Chạy Dự Án Lần Đầu

- [ ] Đã cài đặt Docker
- [ ] Đã tạo file `.env` với cấu hình đúng
- [ ] Đã build Docker image: `docker-compose build`
- [ ] Đã khởi động containers: `docker-compose up -d`
- [ ] Đã tạo schema: `.\create-schema.ps1`
- [ ] Đã chạy discovery: `docker-compose run --rm meltano meltano invoke tap-mysql --discover`
- [ ] Đã chạy sync: `.\sync.ps1 --full-refresh`
- [ ] Đã kiểm tra dữ liệu trong PostgreSQL

---

## 🆘 Cần Giúp Đỡ?

Nếu gặp vấn đề không giải quyết được:
1. Chạy `.\debug-sync.ps1` để kiểm tra cấu hình
2. Xem logs: `docker-compose logs`
3. Kiểm tra file `.env` có đúng không
4. Tham khảo phần Troubleshooting ở trên

---

**Chúc bạn sync dữ liệu thành công! 🎉**

