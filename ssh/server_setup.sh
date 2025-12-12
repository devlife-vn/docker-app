#!/usr/bin/env bash
set -e

echo "🚀 Bắt đầu cài đặt môi trường Laravel..."

cd ~

# --- Hàm hỗ trợ ---
is_installed() {
    dpkg -l | grep -qw "$1"
}

php_ext_installed() {
    php -m | grep -i -q "$1"
}

# --- Cập nhật hệ thống ---
apt update -y && apt upgrade -y && apt autoremove -y

# --- Cài gói cơ bản ---
for pkg in curl gnupg unzip software-properties-common git build-essential; do
    if is_installed "$pkg"; then
        echo "✅ $pkg đã được cài."
    else
        echo "📦 Cài đặt $pkg..."
        sudo apt install -y "$pkg"
    fi
done

# --- PHP 8.3 ---
if ! php -v | grep -q "8.3"; then
    echo "🔧 Cài đặt PHP 8.3..."
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    sudo apt install -y php8.3 php8.3-cli php8.3-fpm
else
    echo "✅ PHP 8.3 đã được cài."
fi

# --- Cài PHP extensions cần thiết ---
declare -A php_extensions=(
    [mysql]="php8.3-mysql"
    [xml]="php8.3-xml"
    [mbstring]="php8.3-mbstring"
    [curl]="php8.3-curl"
    [zip]="php8.3-zip"
    [bcmath]="php8.3-bcmath"
    [gd]="php8.3-gd"
    [readline]="php8.3-readline"
    [soap]="php8.3-soap"
    [intl]="php8.3-intl"
    [imagick]="php8.3-imagick"
    [ext-dom]="php8.3-dom"
)

echo "🧩 Kiểm tra PHP extensions..."
for ext in "${!php_extensions[@]}"; do
    if php_ext_installed "$ext"; then
        echo "✅ Extension $ext đã có."
    else
        echo "➕ Cài extension $ext..."
        sudo apt install -y "${php_extensions[$ext]}"
    fi
done

# --- Composer ---
if ! command -v composer &> /dev/null; then
    echo "📦 Cài đặt Composer..."
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
else
    echo "✅ Composer đã được cài."
fi

# --- MySQL ---
if ! is_installed "mysql-server"; then
    echo "🗄️  Cài đặt MySQL..."
    sudo apt install -y mysql-server
else
    echo "✅ MySQL đã được cài."
fi

# --- Redis ---
if ! is_installed "redis-server"; then
    echo "⚡ Cài Redis..."
    sudo apt install -y redis-server
    sudo systemctl enable redis-server
    sudo systemctl start redis-server
else
    echo "✅ Redis đã được cài."
fi

# --- Node.js ---
if ! command -v node &> /dev/null; then
    echo "🛠️  Cài Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "✅ Node.js đã được cài."
fi

# --- Yarn ---
if ! command -v yarn &> /dev/null; then
    echo "🧶 Cài Yarn..."
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt update && sudo apt install -y yarn
else
    echo "✅ Yarn đã được cài."
fi

# --- Nginx ---
if ! is_installed "nginx"; then
    echo "🌐 Cài đặt Nginx..."
    sudo apt install -y nginx
else
    echo "✅ Nginx đã được cài."
fi

# --- Cấu hình GZIP trong nginx.conf ---
NGINX_CONF="/etc/nginx/nginx.conf"
if ! grep -q "gzip on;" "$NGINX_CONF"; then
    echo "🌀 Bật Gzip trong nginx.conf..."
    sudo sed -i '/http {/a \    gzip on;\
    gzip_disable "msie6";\
    gzip_vary on;\
    gzip_proxied any;\
    gzip_comp_level 6;\
    gzip_buffers 16 8k;\
    gzip_http_version 1.1;\
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;' "$NGINX_CONF"
else
    echo "✅ Gzip đã được cấu hình."
fi

# --- Thêm Cache-Control header trong default site ---
NGINX_DEFAULT="/etc/nginx/sites-available/default"
if ! grep -q "Cache-Control" "$NGINX_DEFAULT"; then
    echo "📦 Thêm Cache-Control header hỗ trợ bfcache..."
    sudo sed -i '/server_name _;/a \
    add_header Cache-Control "public, max-age=3600, stale-while-revalidate=30";\
    add_header X-Cache-Status "HIT";' "$NGINX_DEFAULT"
else
    echo "✅ Cache-Control header đã được cấu hình."
fi

# --- Cài đặt và cấu hình Git ---
if ! is_installed "git"; then
    echo "📦 Cài đặt Git và cấu hình cơ bản..."
    sudo apt install -y git
    
    # Cấu hình Git
    echo "⚙️ Thiết lập cấu hình Git cơ bản..."
    echo -e "\033[33mĐể cấu hình Git, hãy chạy các lệnh sau với thông tin của bạn:\033[0m"
    echo -e "\033[36m   git config --global user.name \"Tên Của Bạn\"\033[0m"
    echo -e "\033[36m   git config --global user.email \"email@example.com\"\033[0m"
    echo -e "\033[36m   git config --global core.editor \"nano\"\033[0m"
    echo -e "\033[36m   git config --global init.defaultBranch main\033[0m"
    echo -e "\033[36m   git config --global pull.rebase false\033[0m"
    echo -e "\033[36m   git config --global color.ui auto\033[0m"
    
    # Cấu hình alias hữu ích
    echo -e "\033[33mCác alias Git hữu ích:\033[0m"
    echo -e "\033[36m   git config --global alias.st status\033[0m"
    echo -e "\033[36m   git config --global alias.ci commit\033[0m"
    echo -e "\033[36m   git config --global alias.co checkout\033[0m"
    echo -e "\033[36m   git config --global alias.br branch\033[0m"
    echo -e "\033[36m   git config --global alias.lg \"log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit\"\033[0m"
    
    echo "✅ Git đã được cài đặt thành công."
else
    echo "✅ Git đã được cài đặt trước đó."
fi

# --- Cài đặt SSL với Certbot ---
if ! command -v certbot &> /dev/null; then
    echo "🔒 Cài đặt Certbot cho SSL/HTTPS..."
    sudo apt install -y certbot python3-certbot-nginx
    echo "✅ Certbot đã được cài đặt."
else
    echo "✅ Certbot đã được cài."
fi

# --- Bật và khởi động lại dịch vụ ---
echo "🔁 Restart các dịch vụ..."
for svc in php8.3-fpm mysql nginx redis-server; do
    sudo systemctl enable "$svc"
    sudo systemctl restart "$svc"
done

# --- Hiển thị hướng dẫn cấu hình SSL ---
echo ""
echo "🔐 HƯỚNG DẪN CẤU HÌNH SSL CHO DOMAIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "\033[1;33mĐể cài đặt SSL cho domain của bạn:\033[0m"
echo -e "\033[36m1. Đảm bảo domain đã trỏ về IP máy chủ này\033[0m"
echo -e "\033[36m2. Tạo file cấu hình Nginx cho domain:\033[0m"
echo -e "   \033[33msudo nano /etc/nginx/sites-available/your-domain.conf\033[0m"
echo -e "\033[36m3. Thêm cấu hình server block cơ bản:\033[0m"
echo -e "\033[33m   server {
       listen 80;
       server_name your-domain.com www.your-domain.com;
       root /var/www/your-project/public;
       
       index index.php index.html;
       
       location / {
           try_files \$uri \$uri/ /index.php?\$query_string;
       }
       
       location ~ \.php$ {
           include snippets/fastcgi-php.conf;
           fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
       }
   }\033[0m"
echo -e "\033[36m4. Kích hoạt cấu hình và kiểm tra:\033[0m"
echo -e "   \033[33msudo ln -s /etc/nginx/sites-available/your-domain.conf /etc/nginx/sites-enabled/\033[0m"
echo -e "   \033[33msudo nginx -t\033[0m"
echo -e "   \033[33msudo systemctl reload nginx\033[0m"
echo -e "\033[36m5. Cài đặt SSL với Certbot:\033[0m"
echo -e "   \033[33msudo certbot --nginx -d your-domain.com -d www.your-domain.com\033[0m"
echo -e "\033[36m6. Kiểm tra tự động gia hạn SSL:\033[0m"
echo -e "   \033[33msudo certbot renew --dry-run\033[0m"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- Kiểm tra phiên bản ---
echo "✅ Môi trường Laravel đã sẵn sàng!"
echo "📊 Các lệnh kiểm tra phiên bản thành phần:"
echo -e "\033[36mKiểm tra phiên bản: \033[33mphp -v | head -n 1\033[0m"
echo -e "\033[36mComposer: \033[33mcomposer --version\033[0m"
echo -e "\033[36mMySQL: \033[33mmysql --version | head -n 1\033[0m"
echo -e "\033[36mRedis: \033[33mredis-cli ping\033[0m" 
echo -e "\033[36mNode: \033[33mnode -v\033[0m"
echo -e "\033[36mYarn: \033[33myarn -v\033[0m"
echo -e "\033[36mNginx: \033[33mnginx -v\033[0m"
echo -e "\033[36mCertbot: \033[33mcertbot --version\033[0m"
