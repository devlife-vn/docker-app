#!/bin/bash
# Script để mở các ứng dụng trong danh sách
# Tối ưu cho hiệu năng

# Hiển thị header
echo "\033[1;34m=== Mở các ứng dụng ===\033[0m"

sh /Users/quandn/quandn/quit_app.sh

# Danh sách các ứng dụng cần mở
apps=(
    "Zalo"
    "Discord"
    "Telegram"
    "Bitwarden"
    "Google Chrome"
    # "Visual Studio Code"
    # "Cloudflare WARP"
)

# "Code|Visual Studio Code"

# # Liệt kê các ứng dụng đang chạy (cách hiệu quả hơn)
# echo "\033[1;33m→ Liệt kê các ứng dụng đang chạy\033[0m"
# ps -ax -o command | awk '{print $1}' | grep -E "^/" | grep -v -E "/System/Library/|/usr/libexec/|/usr/sbin/" | sort | uniq

echo "\033[1;33m→ Mở các ứng dụng chỉ định\033[0m"

# Function để mở một ứng dụng
open_app() {
    local app_name=$1
    local app_path=$2
    
    echo -n "• Đang mở $app_name... "
    
    # Kiểm tra nếu ứng dụng đã đang chạy
    if pgrep -i "$app_name" > /dev/null; then
        echo "\033[1;33m! Đã đang chạy\033[0m"
        return
    fi
    
    # Mở ứng dụng
    if [[ "$app_name" == "Excel" || "$app_name" == "Word" ]]; then
        # Xử lý đặc biệt cho ứng dụng Microsoft Office
        open -a "Microsoft $app_name"
    else
        open -a "$app_name"
    fi
    
    # Kiểm tra kết quả
    if [ $? -eq 0 ]; then
        echo "\033[1;32m✓ Đã mở\033[0m"
    else
        echo "\033[1;31m× Không thể mở\033[0m"
    fi
}

# Mở tất cả các ứng dụng chỉ định
for app in "${apps[@]}"; do
    # Tách tên hiển thị và mẫu tìm kiếm
    if [[ "$app" == *"|"* ]]; then
        display_name=${app%%|*}
        app_name=$display_name
    else
        display_name=$app
        app_name=$app
    fi
    
    open_app "$display_name" "$app_name"
done

