# Thư Mục Deploy

Thư mục này chứa tất cả các file và tài liệu liên quan đến việc deploy project lên Digital Ocean Droplet.

## 📁 Cấu Trúc Thư Mục

```
deploy/
├── README.md                    # File này - mô tả về thư mục deploy
├── DEPLOYMENT.md                # Hướng dẫn chi tiết về cách deploy
└── docker-compose.droplet.yml   # Docker Compose file cho Droplet (có SSH tunnel)
```

## 📄 Mô Tả Các File

### `DEPLOYMENT.md`
Hướng dẫn chi tiết từng bước để:
- Setup Digital Ocean Droplet
- Cấu hình GitHub Secrets
- Deploy tự động qua GitHub Actions
- Troubleshooting các lỗi thường gặp

### `docker-compose.droplet.yml`
Docker Compose file được sử dụng trên Digital Ocean Droplet. File này bao gồm:
- **SSH Tunnel service**: Tạo tunnel đến MySQL RDS qua SSH
- **Meltano service**: Container chạy Meltano sync

**Lưu ý:** 
- File này cần được copy lên Droplet tại `/opt/meltano-sync/docker-compose.yml`
- Cần thay `YOUR_DOCKERHUB_USERNAME` bằng Docker Hub username thực tế
- GitHub Actions workflow sẽ tự động thay thế username khi deploy

## 🚀 Sử Dụng

### Deploy Tự Động (Khuyến Nghị)
Sử dụng GitHub Actions workflow (`.github/workflows/deploy.yml`) để tự động:
1. Build Docker image
2. Push lên Docker Hub
3. Deploy lên Droplet

Xem chi tiết trong [DEPLOYMENT.md](./DEPLOYMENT.md).

### Deploy Thủ Công
1. Copy `docker-compose.droplet.yml` lên Droplet:
   ```bash
   scp deploy/docker-compose.droplet.yml root@YOUR_DROPLET_IP:/opt/meltano-sync/docker-compose.yml
   ```

2. Chỉnh sửa file trên Droplet để thay `YOUR_DOCKERHUB_USERNAME`

3. Tạo file `.env` với các biến môi trường cần thiết

4. Chạy `docker-compose up -d`

## 📝 Lưu Ý

- Tất cả thông tin nhạy cảm (passwords, SSH keys) phải được lưu trong file `.env` trên Droplet
- File `.env` và `keys/*.pem` không được commit lên GitHub (đã có trong `.gitignore`)
- SSH tunnel chỉ cần thiết nếu MySQL RDS không accessible trực tiếp từ Droplet


