# Hướng dẫn chọn bảng để đồng bộ

Có 2 cách để chỉ định các bảng bạn muốn đồng bộ:

## Cách 1: Sử dụng `meltano select` (Khuyến nghị)

### Bước 1: Khám phá các bảng có sẵn

```bash
# Với Docker
docker-compose run --rm meltano meltano invoke tap-mysql --discover

# Hoặc lưu vào file để xem
docker-compose run --rm meltano meltano invoke tap-mysql --discover > schema.json
```

### Bước 2: Chọn các bảng cụ thể

**Chọn tất cả bảng trong một database:**
```bash
docker-compose run --rm meltano meltano select tap-mysql "database_name.*" "*"
```

**Chọn một bảng cụ thể:**
```bash
docker-compose run --rm meltano meltano select tap-mysql "database_name.table_name" "*"
```

**Chọn nhiều bảng:**
```bash
# Chọn bảng 1
docker-compose run --rm meltano meltano select tap-mysql "database_name.table1" "*"

# Chọn bảng 2
docker-compose run --rm meltano meltano select tap-mysql "database_name.table2" "*"

# Chọn bảng 3
docker-compose run --rm meltano meltano select tap-mysql "database_name.table3" "*"
```

**Chọn tất cả bảng (không khuyến nghị nếu có nhiều bảng):**
```bash
docker-compose run --rm meltano meltano select tap-mysql "*.*" "*"
```

### Bước 3: Xem danh sách các bảng đã chọn

```bash
docker-compose run --rm meltano meltano select tap-mysql --list
```

### Bước 4: Bỏ chọn một bảng

```bash
docker-compose run --rm meltano meltano select tap-mysql "database_name.table_name" --rm
```

### Bước 5: Chạy đồng bộ

```bash
docker-compose run --rm meltano meltano run tap-mysql target-postgres
```

## Cách 2: Sử dụng `filter_tables` trong cấu hình

### Cách 2a: Cấu hình trong `meltano.yml`

Thêm vào phần `settings` của extractor `tap-mysql`:

```yaml
plugins:
  extractors:
    - name: tap-mysql
      # ... các cấu hình khác ...
      config:
        filter_tables:
          - table1
          - table2
          - table3
```

### Cách 2b: Sử dụng lệnh `meltano config`

```bash
docker-compose run --rm meltano meltano config tap-mysql set filter_tables '["table1","table2","table3"]'
```

**Lưu ý:** Cách này sẽ lọc ở cấp độ discovery, chỉ các bảng được liệt kê mới được khám phá.

## Ví dụ thực tế

### Ví dụ 1: Chỉ đồng bộ bảng `users` và `orders` từ database `mydb`

```bash
# 1. Khám phá schema
docker-compose run --rm meltano meltano invoke tap-mysql --discover > schema.json

# 2. Chọn bảng users
docker-compose run --rm meltano meltano select tap-mysql "mydb.users" "*"

# 3. Chọn bảng orders
docker-compose run --rm meltano meltano select tap-mysql "mydb.orders" "*"

# 4. Xác nhận các bảng đã chọn
docker-compose run --rm meltano meltano select tap-mysql --list

# 5. Chạy đồng bộ
docker-compose run --rm meltano meltano run tap-mysql target-postgres
```

### Ví dụ 2: Chọn tất cả bảng trong database `mydb` nhưng loại trừ bảng `logs`

```bash
# 1. Chọn tất cả bảng trong database
docker-compose run --rm meltano meltano select tap-mysql "mydb.*" "*"

# 2. Bỏ chọn bảng logs
docker-compose run --rm meltano meltano select tap-mysql "mydb.logs" --rm

# 3. Chạy đồng bộ
docker-compose run --rm meltano meltano run tap-mysql target-postgres
```

### Ví dụ 3: Chọn các cột cụ thể trong một bảng

```bash
# Chọn bảng users nhưng chỉ các cột id, name, email
docker-compose run --rm meltano meltano select tap-mysql "mydb.users" "id,name,email"
```

## Lưu ý quan trọng

1. **Cấu hình được lưu trong `.meltano/`**: Khi bạn chạy `meltano select`, cấu hình được lưu trong `.meltano/` directory và sẽ được sử dụng cho các lần chạy sau.

2. **Format của pattern**: 
   - `database_name.table_name` - chọn một bảng cụ thể
   - `database_name.*` - chọn tất cả bảng trong database
   - `*.*` - chọn tất cả bảng trong tất cả database

3. **Chọn cột**: 
   - `"*"` - chọn tất cả cột
   - `"col1,col2,col3"` - chọn các cột cụ thể

4. **Kiểm tra trước khi chạy**: Luôn chạy `meltano select --list` để xác nhận các bảng đã chọn trước khi chạy sync.

## Troubleshooting

**Nếu không thấy bảng trong danh sách:**
- Đảm bảo bạn đã chạy `meltano invoke tap-mysql --discover` trước
- Kiểm tra tên database và table có đúng không (case-sensitive)
- Kiểm tra quyền truy cập của MySQL user

**Nếu muốn reset và chọn lại:**
```bash
# Xóa tất cả selections
docker-compose run --rm meltano meltano select tap-mysql --rm "*.*"

# Sau đó chọn lại các bảng bạn muốn
```




