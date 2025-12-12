# Development Environment Setup

Tài liệu hướng dẫn cài đặt và cấu hình môi trường phát triển sử dụng Docker, SSL cho domain local, và các lệnh thường dùng.

## Mục lục

- [Khởi tạo môi trường](#khởi-tạo-môi-trường)
- [Tạo SSL cho Domain Local](#tạo-ssl-cho-domain-local)
- [Tạo Client Certificates](#tạo-client-certificates)
- [Docker Commands](#docker-commands)
- [Troubleshooting](#troubleshooting)

---

## Khởi tạo môi trường

### 1. Copy file cấu hình môi trường

```bash
cp env-local .env
```

### 2. Cấu hình đường dẫn source code

Chỉnh sửa file `.env` và cập nhật:

```bash
APP_CODE_PATH_HOST=...
```

### 3. Khởi động Docker containers

```bash
./start.sh
```

---

## Tạo SSL cho Domain Local

### Bước 1: Chạy script tạo SSL

Script `ssl.sh` trong Docker sẽ tự động tạo chứng chỉ SSL cho domain local:

```bash
./ssl.sh domain-local-name.local
```

### Bước 2: Cơ chế hoạt động

Script thực hiện 2 công việc chính:

1. **Tạo Root CA** (lần đầu tiên):
   - Các file được tạo trong thư mục `/ca-certificates/`
   - Password phrase mặc định: `quandn`
   - ⚠️ **LƯU Ý**: Nhớ password này để tạo certificates cho các domain khác
   - Files được tạo: `rootCA.key`, `rootCA.pem`, `rootCA.srl`

2. **Tạo Certificate cho domain**:
   - Sử dụng Root CA đã tạo để ký certificate
   - Cần nhập password của Root CA (quandn)

### Bước 3: Cấu hình Nginx

Tạo/cập nhật file cấu hình Nginx cho domain:

```nginx
server {
    listen 80;
    server_name devlife.local;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    ssl_certificate /etc/nginx/ssl/devlife.local.crt;
    ssl_certificate_key /etc/nginx/ssl/devlife.local.key;

    server_name devlife.local;
    root /var/www/devlife/dist;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        try_files $uri /index.php =404;
        fastcgi_pass php-upstream;
        fastcgi_index index.php;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_read_timeout 600;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    location /.well-known/acme-challenge/ {
        root /var/www/letsencrypt/;
        log_not_found off;
    }

    error_log /var/log/nginx/devlife-error.log;
    access_log /var/log/nginx/devlife-access.log;
}
```

### Bước 4: Import Root CA vào trình duyệt

1. Mở trình duyệt và tìm mục **Certificates** (hoặc **Chứng chỉ**)
2. Import file `rootCA.pem` vào danh sách Trusted Root Certification Authorities
3. Khởi động lại trình duyệt

> **Lưu ý**: Cách import có thể khác nhau tùy theo hệ điều hành và trình duyệt

---

## Tạo Client Certificates

### 1. Tạo Root CA key và certificate

```bash
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -key rootCA.key -days 3650 -out rootCA.pem \
  -subj '/C=AA/ST=AA/L=AA/O=AA Ltd/OU=AA/CN=AA/emailAddress=aa@aa.com'
```

### 2. Tạo Client key và CSR

```bash
openssl genrsa -out client1.key 2048
openssl req -new -key client1.key -out client1.csr \
  -subj '/C=BB/ST=BB/L=BB/O=BB Ltd/OU=BB/CN=BB/emailAddress=bb@bb.com'
```

### 3. Ký Client certificate với Root CA

```bash
openssl x509 -req -days 365 -CA rootCA.pem -CAkey rootCA.key \
  -CAcreateserial -CAserial serial -in client1.csr -out client1.pem
```

### 4. Xác thực certificate

```bash
openssl verify -verbose -CAfile rootCA.pem client1.pem
```

> **Gợi ý**: Bạn có thể cấu hình file config và sử dụng `openssl ca` để quản lý certificates tốt hơn

---

## Docker Commands

### Copy file giữa Docker container và máy local

**Cú pháp**:

```bash
docker cp CONTAINER_NAME:/path/to/file/in/container /path/to/destination/on/host
```

**Lưu ý**:
- Copy từ container ra host: đường dẫn container trước, đường dẫn host sau
- Copy từ host vào container: đảo ngược thứ tự đường dẫn

**Ví dụ**:

```bash
# Copy từ container ra host
docker cp my_container:/var/www/html/config.php ./config.php

# Copy từ host vào container
docker cp ./config.php my_container:/var/www/html/config.php
```

### Đặt password cho user root trong Docker

```bash
cat /etc/shadow | grep root
passwd
```

### Chạy Laravel Scheduler trong Docker

```bash
while true; do php artisan schedule:run; sleep 5; done
```

---

## Troubleshooting

### 1. Lỗi khi tạo Vue project

**Triệu chứng**: Không thể tạo project Vue mới

**Giải pháp**:

```bash
vue config -s packageManager npm
```

### 2. Git Push Error: Insufficient permission

**Lỗi**: `insufficient permission for adding an object to repository database`

**Giải pháp**:

```bash
cd /path/to/project/.git/
sudo chown -R "${USER:-$(id -un)}" .
```

### 3. Apt Error: Target Packages configured multiple times

**Lỗi**: `W: Target Packages ... is configured multiple times`

**Giải pháp**:

1. Cài đặt prerequisites:

```bash
sudo apt install python3-apt
```

2. Tải và cấp quyền thực thi cho script cleanup:

```bash
chmod a+x other_files/aptsources-cleanup.pyz
```

3. Chạy script:

```bash
sudo ./other_files/aptsources-cleanup.pyz
```

---

## Liên hệ

Nếu có vấn đề hoặc câu hỏi, vui lòng tạo issue hoặc liên hệ team phát triển.
