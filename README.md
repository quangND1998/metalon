# Meltano MySQL to PostgreSQL Sync

Project này sử dụng Meltano để đồng bộ dữ liệu từ MySQL sang PostgreSQL.

## Yêu cầu

- Python 3.8+
- Meltano CLI
- MySQL server đang chạy
- PostgreSQL server đang chạy

## Cài đặt

### 1. Cài đặt Meltano

```bash
pip install meltano
```

Hoặc sử dụng pipx (khuyến nghị):

```bash
pipx install meltano
```

### 2. Cấu hình môi trường

Sao chép file `.env.example` thành `.env` và điền thông tin kết nối:

```bash
# Windows PowerShell
Copy-Item .env.example .env
```

Sau đó chỉnh sửa file `.env` với thông tin kết nối MySQL và PostgreSQL của bạn.

### 3. Cài đặt plugins

```bash
meltano install
```

## Sử dụng

### 1. Khám phá schema (Discover)

Khám phá các bảng và schema có sẵn trong MySQL:

```bash
meltano invoke tap-mysql --discover
```

Để xem kết quả dạng JSON:

```bash
meltano invoke tap-mysql --discover > schema.json
```

### 2. Chọn các stream để sync

Chọn các bảng bạn muốn đồng bộ:

```bash
meltano select tap-mysql "*.*"
```

Hoặc chọn bảng cụ thể:

```bash
meltano select tap-mysql "database_name.table_name" "*"
```

Để xem các stream đã chọn:

```bash
meltano select tap-mysql --list
```

### 3. Chạy đồng bộ (EL)

Đồng bộ dữ liệu từ MySQL sang PostgreSQL:

```bash
meltano run tap-mysql target-postgres
```

### 4. Chạy với state (Incremental Sync)

Để đồng bộ tăng dần, sử dụng state:

```bash
meltano run tap-mysql target-postgres --full-refresh=false
```

## Cấu hình nâng cao

### Lọc schema/tables cụ thể

Trong file `meltano.yml`, bạn có thể thêm cấu hình:

```yaml
settings:
  - name: filter_schemas
    value:
      - database1
      - database2
  - name: filter_tables
    value:
      - table1
      - table2
```

Hoặc sử dụng lệnh:

```bash
meltano config tap-mysql set filter_schemas '["database1","database2"]'
meltano config tap-mysql set filter_tables '["table1","table2"]'
```

### Đặt batch size cho target

```bash
meltano config target-postgres set batch_size_rows 50000
```

## Lập lịch chạy tự động

### Sử dụng Meltano Schedule

Tạo schedule trong `meltano.yml`:

**Chạy mỗi giờ (1 tiếng 1 lần):**

```yaml
schedules:
  - name: hourly-mysql-sync
    interval: '@hourly'
    job: tap-mysql target-postgres
```

**Hoặc sử dụng cron expression để chạy mỗi giờ:**

```yaml
schedules:
  - name: hourly-mysql-sync
    interval: '0 * * * *'  # Chạy vào phút 0 của mỗi giờ
    job: tap-mysql target-postgres
```

**Chạy mỗi ngày (ví dụ):**

```yaml
schedules:
  - name: daily-mysql-sync
    interval: '@daily'
    job: tap-mysql target-postgres
```

Sau đó chạy scheduler:

```bash
meltano schedule list
meltano schedule run hourly-mysql-sync
```

**Lưu ý:** Để scheduler chạy tự động, bạn cần chạy lệnh `meltano schedule run` trong một process chạy liên tục hoặc sử dụng system service.

### Hoặc sử dụng cron (Linux/Mac)

```bash
# Chạy mỗi ngày lúc 2 giờ sáng
0 2 * * * cd /path/to/project && meltano run tap-mysql target-postgres
```

### Hoặc sử dụng Task Scheduler (Windows)

Tạo task trong Windows Task Scheduler để chạy:

```powershell
meltano run tap-mysql target-postgres
```

## Mở rộng: Đồng bộ nhiều Database

Project này hỗ trợ nhiều kịch bản đồng bộ:

### Kịch bản 1: Nhiều MySQL DB → 1 PostgreSQL (cùng schema hoặc khác schema)

**Ví dụ:** DB A → PostgreSQL E, DB B → PostgreSQL E

**Bước 1:** Thêm extractors mới vào `meltano.yml`:

```yaml
extractors:
  - name: tap-mysql-db1
    namespace: tap_mysql
    pip_url: pipelinewise-tap-mysql
    executable: tap-mysql
    # ... (cấu hình tương tự tap-mysql)
  
  - name: tap-mysql-db2
    namespace: tap_mysql
    pip_url: pipelinewise-tap-mysql
    executable: tap-mysql
    # ... (cấu hình tương tự tap-mysql)
```

**Bước 2:** Thêm loader chung (hoặc dùng target-postgres có sẵn):

```yaml
loaders:
  - name: target-postgres-common
    namespace: target_postgres
    pip_url: pipelinewise-target-postgres
    executable: target-postgres
    # ... (cấu hình tương tự target-postgres)
```

**Bước 3:** Cấu hình biến môi trường trong `.env`:

```bash
# MySQL DB1
MYSQL_DB1_HOST=localhost
MYSQL_DB1_PORT=3306
MYSQL_DB1_USER=root
MYSQL_DB1_PASSWORD=password1
MYSQL_DB1_DATABASE=database_a

# MySQL DB2
MYSQL_DB2_HOST=localhost
MYSQL_DB2_PORT=3306
MYSQL_DB2_USER=root
MYSQL_DB2_PASSWORD=password2
MYSQL_DB2_DATABASE=database_b

# PostgreSQL Common
POSTGRES_COMMON_HOST=localhost
POSTGRES_COMMON_PORT=5432
POSTGRES_COMMON_USER=postgres
POSTGRES_COMMON_PASSWORD=password
POSTGRES_COMMON_DBNAME=database_e
POSTGRES_COMMON_DEFAULT_TARGET_SCHEMA=public
```

**Bước 4:** Cập nhật `meltano.yml` env section:

```yaml
env:
  TAP_MYSQL_DB1_HOST: ${MYSQL_DB1_HOST}
  TAP_MYSQL_DB1_PORT: ${MYSQL_DB1_PORT}
  TAP_MYSQL_DB1_USER: ${MYSQL_DB1_USER}
  TAP_MYSQL_DB1_PASSWORD: ${MYSQL_DB1_PASSWORD}
  TAP_MYSQL_DB1_DATABASE: ${MYSQL_DB1_DATABASE}
  # ... tương tự cho DB2
  TARGET_POSTGRES_COMMON_HOST: ${POSTGRES_COMMON_HOST}
  # ... các biến khác
```

**Bước 5:** Chạy đồng bộ:

```bash
# Đồng bộ DB1 → PostgreSQL E
meltano run tap-mysql-db1 target-postgres-common

# Đồng bộ DB2 → PostgreSQL E
meltano run tap-mysql-db2 target-postgres-common

# Hoặc sử dụng script PowerShell
.\sync.ps1 -Tap tap-mysql-db1 -Target target-postgres-common
.\sync.ps1 -Tap tap-mysql-db2 -Target target-postgres-common
```

**Bước 6:** Tạo schedules tự động:

```yaml
schedules:
  - name: hourly-db1-to-common
    interval: '@hourly'
    job: tap-mysql-db1 target-postgres-common
  
  - name: hourly-db2-to-common
    interval: '@hourly'
    job: tap-mysql-db2 target-postgres-common
```

### Kịch bản 2: Nhiều cặp đồng bộ riêng biệt

**Ví dụ:** DB A → DB B, DB C → DB D

**Bước 1:** Thêm extractors và loaders tương ứng:

```yaml
extractors:
  - name: tap-mysql-db1
    # ... cấu hình cho DB A
  - name: tap-mysql-db2
    # ... cấu hình cho DB C

loaders:
  - name: target-postgres-db1
    # ... cấu hình cho DB B
  - name: target-postgres-db2
    # ... cấu hình cho DB D
```

**Bước 2:** Chạy đồng bộ từng cặp:

```bash
# DB A → DB B
meltano run tap-mysql-db1 target-postgres-db1

# DB C → DB D
meltano run tap-mysql-db2 target-postgres-db2
```

**Bước 3:** Tạo schedules:

```yaml
schedules:
  - name: hourly-db1-to-db1
    interval: '@hourly'
    job: tap-mysql-db1 target-postgres-db1
  
  - name: hourly-db2-to-db2
    interval: '@hourly'
    job: tap-mysql-db2 target-postgres-db2
```

### Kịch bản 3: Sử dụng schema khác nhau trong cùng PostgreSQL

Khi nhiều MySQL DB đồng bộ vào cùng 1 PostgreSQL, bạn có thể dùng schema khác nhau:

```yaml
# Trong cấu hình loader, đặt default_target_schema khác nhau
loaders:
  - name: target-postgres-schema-a
    settings:
      - name: default_target_schema
        value: schema_a  # Schema cho DB A
  
  - name: target-postgres-schema-b
    settings:
      - name: default_target_schema
        value: schema_b  # Schema cho DB B
```

### Quản lý nhiều đồng bộ

**Xem danh sách extractors/loaders:**

```bash
meltano list extractors
meltano list loaders
```

**Xem danh sách schedules:**

```bash
meltano schedule list
```

**Sử dụng script PowerShell với nhiều cặp:**

```powershell
# Liệt kê các extractors và loaders
.\sync.ps1 -List

# Chạy đồng bộ với cặp cụ thể
.\sync.ps1 -Tap tap-mysql-db1 -Target target-postgres-common

# Discover schema cho extractor cụ thể
.\sync.ps1 -Discover -Tap tap-mysql-db1
```

### Lưu ý quan trọng

1. **State Management:** Mỗi cặp extractor-loader có state riêng, được lưu trong `.meltano/state/`
2. **Naming Convention:** Đặt tên extractors và loaders rõ ràng để dễ quản lý
3. **Environment Variables:** Mỗi extractor/loader cần có biến môi trường riêng trong `.env`
4. **Schema Conflicts:** Khi nhiều nguồn vào cùng 1 PostgreSQL, đảm bảo không có xung đột tên bảng hoặc dùng schema khác nhau

## Troubleshooting

### Kiểm tra kết nối MySQL

```bash
mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
```

### Kiểm tra kết nối PostgreSQL

```bash
psql -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -U ${POSTGRES_USER} -d ${POSTGRES_DBNAME}
```

### Xem logs

```bash
meltano run tap-mysql target-postgres --log-level=debug
```

## Tài liệu tham khảo

- [Meltano Documentation](https://docs.meltano.com/)
- [Singer SDK](https://sdk.meltano.com/)
- [tap-mysql](https://hub.meltano.com/extractors/tap-mysql)
- [target-postgres](https://hub.meltano.com/loaders/target-postgres)
