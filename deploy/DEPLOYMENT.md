# Hướng Dẫn Deploy lên Digital Ocean Droplet với GitHub CI/CD

Tài liệu này hướng dẫn cách deploy project Meltano MySQL to PostgreSQL Sync lên Digital Ocean Droplet sử dụng GitHub Actions CI/CD.

> **Lưu ý:** File này nằm trong thư mục `deploy/`. Tất cả các file liên quan đến deployment đều được tổ chức trong thư mục này.

## 📋 Mục Lục

1. [Chuẩn Bị](#chuẩn-bị)
2. [Cấu Hình Digital Ocean Droplet](#cấu-hình-digital-ocean-droplet)
3. [Cấu Hình GitHub Secrets](#cấu-hình-github-secrets)
4. [Deploy](#deploy)
5. [Troubleshooting](#troubleshooting)

## 🚀 Chuẩn Bị

### Yêu Cầu

- Tài khoản Digital Ocean
- Tài khoản GitHub
- Tài khoản Docker Hub
- Repository đã được push lên GitHub
- Docker image đã được build và test local

## 🔧 Cấu Hình Digital Ocean Droplet

### Bước 1: Tạo Docker Hub Repository

1. Đăng nhập vào [Docker Hub](https://hub.docker.com/)
2. Vào **Repositories** → **Create Repository**
3. Đặt tên repository (ví dụ: `meltano-sync`)
4. Chọn **Public** hoặc **Private** (khuyến nghị Private)
5. Click **Create**
6. Lưu lại tên repository (format: `username/repository-name`)

### Bước 2: Tạo Droplet

1. Đăng nhập vào [Digital Ocean Control Panel](https://cloud.digitalocean.com/)
2. Vào **Droplets** → **Create Droplet**
3. Chọn cấu hình:
   - **Image**: Ubuntu 22.04 LTS (khuyến nghị)
   - **Plan**: Basic ($6/month đủ cho test, hoặc cao hơn cho production)
   - **Region**: Singapore (hoặc region gần nhất với bạn)
   - **Authentication**: SSH keys (khuyến nghị) hoặc Password
   - **Hostname**: `meltano-sync` (tùy chọn)
4. Click **Create Droplet**
5. Lưu lại **IP Address** của Droplet

### Bước 3: Setup Droplet

SSH vào Droplet và cài đặt các công cụ cần thiết:

```bash
# Kết nối SSH (thay YOUR_IP bằng IP của Droplet)
ssh root@YOUR_DROPLET_IP

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version

# Logout và login lại để áp dụng group changes
exit
```

### Bước 4: Setup Project trên Droplet

SSH lại vào Droplet và setup project:

```bash
# Tạo thư mục project
sudo mkdir -p /opt/meltano-sync
cd /opt/meltano-sync

# Clone repository (hoặc tạo thủ công)
# Option 1: Clone từ GitHub (khuyến nghị)
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git .

# Option 2: Hoặc tạo thủ công các file cần thiết
# mkdir -p /opt/meltano-sync
# nano docker-compose.yml
# nano .env
```

### Bước 5: Copy file docker-compose.yml lên Droplet

Copy file `docker-compose.droplet.yml` từ repository lên Droplet:

**Option 1: Clone repository (khuyến nghị)**
```bash
cd /opt/meltano-sync
# Nếu đã clone repository ở Bước 4, chỉ cần copy file
cp deploy/docker-compose.droplet.yml docker-compose.yml
# Hoặc nếu chưa clone, clone lại:
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git .
cp deploy/docker-compose.droplet.yml docker-compose.yml
```

**Option 2: Copy file thủ công**
```bash
# Từ máy local, copy file lên Droplet
scp deploy/docker-compose.droplet.yml root@YOUR_DROPLET_IP:/opt/meltano-sync/docker-compose.yml

# Hoặc tạo file trực tiếp trên Droplet
cd /opt/meltano-sync
nano docker-compose.yml
# Copy nội dung từ file deploy/docker-compose.droplet.yml trong repository
```

**Quan trọng:** Sau khi copy file, cần chỉnh sửa để thay `YOUR_DOCKERHUB_USERNAME` bằng Docker Hub username của bạn:

```bash
cd /opt/meltano-sync
nano docker-compose.yml
# Tìm và thay YOUR_DOCKERHUB_USERNAME bằng username thực tế
# Ví dụ: image: your-username/meltano-sync:latest
```

**Lưu ý:** 
- File `docker-compose.droplet.yml` đã được cấu hình sẵn với SSH tunnel và các environment variables cần thiết.
- SSH tunnel sẽ tự động tạo tunnel từ container đến MySQL RDS qua SSH server.
- File này bao gồm cả SSH tunnel service và Meltano service.

### Bước 6: Tạo thư mục keys và đặt SSH key

Tạo thư mục `keys` và đặt file PEM key vào:

```bash
cd /opt/meltano-sync
mkdir -p keys
chmod 700 keys

# Copy file PEM key vào thư mục keys/
# Cách 1: Sử dụng scp từ máy local
# scp /path/to/your-key.pem root@YOUR_DROPLET_IP:/opt/meltano-sync/keys/

# Cách 2: Tạo file trực tiếp trên Droplet
nano keys/your-key.pem
# Paste nội dung PEM key vào, sau đó Ctrl+X, Y, Enter để save
chmod 600 keys/your-key.pem
```

**Lưu ý:** 
- File PEM key phải có quyền 600 (chỉ owner đọc/ghi)
- Tên file phải khớp với `SSH_KEY_FILE` trong file `.env`

### Bước 7: Tạo file .env trên Droplet

Tạo file `.env` với thông tin kết nối:

```bash
cd /opt/meltano-sync
nano .env
```

Paste nội dung sau và điền thông tin:

```bash
# SSH Tunnel Configuration (cần thiết nếu MySQL RDS không accessible trực tiếp)
SSH_HOST=your_ssh_host
SSH_PORT=22
SSH_USERNAME=your_ssh_username
MYSQL_RDS_HOST=your_mysql_rds_host
MYSQL_RDS_PORT=3306
SSH_KEY_FILE=your_key_file.pem

# MySQL Connection (qua SSH tunnel - sử dụng tên service ssh-tunnel)
MYSQL_HOST=ssh-tunnel
MYSQL_PORT=3306
MYSQL_USER=your_mysql_user
MYSQL_PASSWORD=your_mysql_password
MYSQL_DATABASE=your_mysql_database

# PostgreSQL Connection
POSTGRES_HOST=your_postgres_host
POSTGRES_PORT=5432
POSTGRES_USER=your_postgres_user
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_DBNAME=your_postgres_database
POSTGRES_DEFAULT_TARGET_SCHEMA=airbyte_raw
```

**Lưu ý về SSH Tunnel:**
- Nếu MySQL RDS có thể truy cập trực tiếp từ Droplet (không cần SSH tunnel), bạn có thể:
  - Bỏ qua các biến SSH Tunnel
  - Đặt `MYSQL_HOST` trực tiếp là hostname/IP của MySQL RDS
  - Có thể comment hoặc xóa service `ssh-tunnel` trong `docker-compose.yml` và bỏ `depends_on: ssh-tunnel` trong service `meltano`

**Lưu ý quan trọng:**
- **KHÔNG** hardcode thông tin nhạy cảm vào code, tất cả phải dùng biến môi trường
- Không commit file `.env` lên GitHub (đã có trong .gitignore)
- Không commit file PEM key lên GitHub (đã có trong .gitignore)
- Đảm bảo SSH server cho phép kết nối từ IP của Droplet

### Bước 8: Tạo thư mục state

```bash
cd /opt/meltano-sync
mkdir -p .meltano
chmod 755 .meltano
```

### Bước 9: Test chạy lần đầu (tùy chọn)

```bash
cd /opt/meltano-sync

# Pull image từ Docker Hub
docker pull YOUR_DOCKERHUB_USERNAME/meltano-sync:latest

# Khởi động SSH tunnel trước
docker-compose up -d ssh-tunnel

# Kiểm tra SSH tunnel đang chạy
docker-compose ps ssh-tunnel
docker-compose logs ssh-tunnel

# Chạy Meltano container
docker-compose up -d meltano

# Xem logs
docker-compose logs -f meltano

# Kiểm tra tất cả containers đang chạy
docker-compose ps
```

## 🔐 Cấu Hình GitHub Secrets

Vào GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Thêm các secrets sau:

### 1. **DOCKERHUB_USERNAME**
   - Docker Hub username của bạn
   - Ví dụ: `your-username`

### 2. **DOCKERHUB_TOKEN**
   - Tạo tại: [Docker Hub Account Settings](https://hub.docker.com/settings/security) → **New Access Token**
   - Đặt tên token (ví dụ: `github-actions`)
   - Chọn quyền: **Read & Write** (để push images)
   - Copy token và paste vào secret
   - **Lưu ý**: Sử dụng Access Token thay vì password (khuyến nghị)

### 3. **DO_DROPLET_HOST**
   - IP address của Droplet
   - Ví dụ: `123.456.789.0`
   - Tìm tại: Digital Ocean → Droplets → Your Droplet → IP Address

### 4. **DO_DROPLET_USER**
   - Username SSH để kết nối Droplet
   - Thường là `root` (nếu dùng root) hoặc `ubuntu` (nếu dùng Ubuntu user)

### 5. **DO_DROPLET_SSH_KEY**
   - Private SSH key để kết nối Droplet
   - **Cách tạo SSH key (nếu chưa có):**
     ```bash
     # Trên máy local
     ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
     # Nhấn Enter để chọn default location
     # Nhấn Enter để không đặt passphrase (hoặc đặt nếu muốn)
     
     # Copy public key lên Droplet
     ssh-copy-id root@YOUR_DROPLET_IP
     
     # Copy private key để paste vào GitHub Secret
     cat ~/.ssh/id_rsa
     ```
   - Copy toàn bộ nội dung file `~/.ssh/id_rsa` (bao gồm `-----BEGIN OPENSSH PRIVATE KEY-----` và `-----END OPENSSH PRIVATE KEY-----`)
   - Paste vào secret `DO_DROPLET_SSH_KEY`

## 🚀 Deploy

### Tự Động Deploy

Sau khi cấu hình xong, mỗi khi push code lên branch `main` hoặc `master`, GitHub Actions sẽ tự động:

1. Build Docker image từ Dockerfile
2. Push image lên Docker Hub với tag `latest`
3. SSH vào Droplet
4. Pull image mới từ Docker Hub
5. Restart container với image mới

### Manual Deploy

Bạn cũng có thể trigger manual:

1. Vào **Actions** tab trên GitHub
2. Chọn workflow **Build and Deploy to Digital Ocean**
3. Click **Run workflow**
4. Chọn branch và click **Run workflow**

### Kiểm Tra Deployment

**Xem logs trên Droplet:**
```bash
ssh root@YOUR_DROPLET_IP
cd /opt/meltano-sync
docker-compose logs -f meltano
```

**Kiểm tra container đang chạy:**
```bash
docker-compose ps
```

**Xem logs real-time:**
```bash
docker-compose logs -f --tail=100 meltano
```

**Kiểm tra image đã được pull:**
```bash
docker images | grep meltano-sync
```

## ⚙️ Cấu Hình Nâng Cao

### Scheduled Sync

Để chạy sync theo lịch, bạn có thể sử dụng cron trên Droplet:

```bash
# SSH vào Droplet
ssh root@YOUR_DROPLET_IP

# Mở crontab editor
crontab -e

# Thêm dòng sau để chạy sync mỗi giờ
0 * * * * cd /opt/meltano-sync && docker-compose run --rm meltano meltano run tap-mysql target-postgres

# Hoặc chạy mỗi ngày lúc 2 giờ sáng
0 2 * * * cd /opt/meltano-sync && docker-compose run --rm meltano meltano run tap-mysql target-postgres
```

**Lưu ý:** Khi dùng cron, nên dùng `docker-compose run --rm` để chạy job một lần thay vì restart container.

### Environment Variables

Để cập nhật environment variables:

1. SSH vào Droplet
2. Chỉnh sửa file `.env`:
   ```bash
   cd /opt/meltano-sync
   nano .env
   ```
3. Restart container:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Backup State

State của Meltano được lưu trong `.meltano/state/`. Để backup:

```bash
# SSH vào Droplet
ssh root@YOUR_DROPLET_IP
cd /opt/meltano-sync

# Backup state
tar -czf meltano-state-backup-$(date +%Y%m%d).tar.gz .meltano/state/

# Copy về máy local (từ máy local)
scp root@YOUR_DROPLET_IP:/opt/meltano-sync/meltano-state-backup-*.tar.gz ./
```

### Update Project Files

Nếu bạn cần cập nhật `meltano.yml` hoặc các file khác:

**Option 1: Pull từ GitHub**
```bash
ssh root@YOUR_DROPLET_IP
cd /opt/meltano-sync
git pull origin main
docker-compose restart
```

**Option 2: Copy file thủ công**
```bash
# Từ máy local
scp meltano.yml root@YOUR_DROPLET_IP:/opt/meltano-sync/
ssh root@YOUR_DROPLET_IP "cd /opt/meltano-sync && docker-compose restart"
```

## 🔍 Troubleshooting

### Lỗi: "Failed to build Docker image"

**Nguyên nhân:** Dockerfile có lỗi hoặc dependencies không đúng

**Giải pháp:**
- Test build local trước: `docker build -t test .`
- Kiểm tra logs trong GitHub Actions
- Đảm bảo Dockerfile đúng format

### Lỗi: "Cannot connect to MySQL/PostgreSQL"

**Nguyên nhân:** Environment variables chưa được set, SSH tunnel chưa chạy, hoặc database không accessible

**Giải pháp:**
- Kiểm tra file `.env` trên Droplet: `cat /opt/meltano-sync/.env`
- Kiểm tra SSH tunnel đang chạy: `docker-compose ps ssh-tunnel`
- Xem logs SSH tunnel: `docker-compose logs ssh-tunnel`
- Kiểm tra SSH key đã được đặt đúng: `ls -la /opt/meltano-sync/keys/`
- Kiểm tra quyền SSH key: `chmod 600 /opt/meltano-sync/keys/your-key.pem`
- Test kết nối SSH tunnel từ trong container:
  ```bash
  docker-compose exec meltano bash
  # Trong container, test kết nối MySQL qua tunnel
  mysql -h ssh-tunnel -u YOUR_USER -p
  ```
- Đảm bảo SSH server cho phép kết nối từ IP của Droplet
- Kiểm tra firewall rules trên database server

### Lỗi: "Registry authentication failed" hoặc "unauthorized: authentication required"

**Nguyên nhân:** DOCKERHUB_TOKEN hoặc DOCKERHUB_USERNAME sai

**Giải pháp:**
- Tạo lại Docker Hub Access Token tại [Docker Hub Security Settings](https://hub.docker.com/settings/security)
- Đảm bảo token có quyền **Read & Write**
- Kiểm tra username (phải là Docker Hub username, không phải email)
- Test login local: `docker login -u YOUR_USERNAME -p YOUR_TOKEN`

### Lỗi: "Permission denied (publickey)" khi SSH

**Nguyên nhân:** SSH key không đúng hoặc chưa được thêm vào Droplet

**Giải pháp:**
- Kiểm tra SSH key trong GitHub Secret có đúng format không
- Đảm bảo public key đã được thêm vào Droplet:
  ```bash
  # Trên máy local
  ssh-copy-id root@YOUR_DROPLET_IP
  ```
- Test SSH connection: `ssh -i ~/.ssh/id_rsa root@YOUR_DROPLET_IP`

### Lỗi: "Cannot pull image" trên Droplet

**Nguyên nhân:** Image chưa được push lên Docker Hub hoặc tên image sai

**Giải pháp:**
- Kiểm tra image đã được push: Vào Docker Hub và kiểm tra repository
- Kiểm tra tên image trong `docker-compose.yml` trên Droplet
- Pull thủ công để test: `docker pull YOUR_USERNAME/meltano-sync:latest`

### Lỗi: "Container keeps restarting"

**Nguyên nhân:** Container crash do lỗi trong code hoặc thiếu environment variables

**Giải pháp:**
- Xem logs: `docker-compose logs meltano`
- Kiểm tra environment variables: `docker-compose config`
- Test chạy container interactively:
  ```bash
  docker-compose run --rm meltano /bin/bash
  ```

### Kiểm Tra Logs

**Trên Droplet:**
```bash
# Logs của container
docker-compose logs -f meltano

# Logs của Docker daemon
sudo journalctl -u docker.service -f

# Logs của system
sudo journalctl -f
```

**Từ GitHub Actions:**
- Vào tab **Actions** trên GitHub
- Chọn workflow run
- Xem logs của từng step

### Kiểm Tra Container Status

```bash
# Xem containers đang chạy
docker-compose ps

# Xem tất cả containers (bao gồm stopped)
docker-compose ps -a

# Xem resource usage
docker stats meltano-sync
```

## 📚 Tài Liệu Tham Khảo

- [Digital Ocean Droplets Docs](https://docs.digitalocean.com/products/droplets/)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Meltano Documentation](https://docs.meltano.com/)
- [Docker Compose Docs](https://docs.docker.com/compose/)

## 💡 Tips

1. **Test local trước:** Luôn test build và chạy local trước khi deploy
2. **Sử dụng secrets:** Không commit passwords vào code, luôn dùng GitHub Secrets
3. **Monitor logs:** Theo dõi logs thường xuyên để phát hiện lỗi sớm
4. **Backup state:** Backup `.meltano/state/` định kỳ để có thể restore
5. **Security:** 
   - Sử dụng SSH keys thay vì password
   - **KHÔNG** hardcode thông tin nhạy cảm (RDS host, passwords, SSH keys) vào code
   - Tất cả thông tin nhạy cảm phải dùng biến môi trường
   - Giới hạn firewall rules chỉ cho phép IP cần thiết
   - Sử dụng private Docker Hub repository cho production
   - File `.env` và `keys/*.pem` đã được ignore trong `.gitignore`
6. **Cost optimization:** 
   - Sử dụng Basic plan cho development/test
   - Monitor resource usage: `docker stats`
   - Scale up chỉ khi cần thiết
7. **Maintenance:**
   - Update system định kỳ: `sudo apt update && sudo apt upgrade`
   - Clean up unused Docker images: `docker system prune -a`
   - Monitor disk space: `df -h`
