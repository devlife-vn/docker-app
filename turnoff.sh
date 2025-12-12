#!/bin/bash
# Script để đóng các ứng dụng đang chạy
# Tối ưu cho hiệu năng

# Hiển thị header
echo "\033[1;34m=== ĐANG ĐÓNG CÁC ỨNG DỤNG ===\033[0m"

# Danh sách các ứng dụng cần đóng
apps=(
    "Zalo"
    "Discord"
    "Telegram"
    "Termius"
    "Bitwarden"
    "Excel|Microsoft Excel"
    "Word|Microsoft Word"
    "Google Chrome"
    # "Visual Studio Code|code"
    "Cloudflare WARP"
)

# "Code|Visual Studio Code"

echo "\033[1;33m→ Bắt đầu đóng các ứng dụng\033[0m"

# Function để đóng một ứng dụng
close_app() {
    local app_name=$1
    local search_pattern=$2
    # Sử dụng cú pháp tương thích với nhiều shell hơn
    local IFS="|"
    local search_arr=($search_pattern)
    
    echo -n "• Đang đóng $app_name... "
    
    local found=0
    # Tìm kiếm theo các mẫu khác nhau
    for pattern in "${search_arr[@]}"; do
        if pgrep -i "$pattern" > /dev/null; then
            found=1
            pkill -9 -i "$pattern"
        fi
    done
    
    # Hiển thị kết quả
    if [[ $found -eq 1 ]]; then
        echo "\033[1;32m✓ Đã đóng thành công\033[0m"
    else
        echo "\033[1;33m! Ứng dụng không hoạt động\033[0m"
    fi
}

# Đóng tất cả các ứng dụng chỉ định
for app in "${apps[@]}"; do
    # Tách tên hiển thị và mẫu tìm kiếm
    if [[ "$app" == *"|"* ]]; then
        display_name=${app%%|*}
        search_pattern=$app
    else
        display_name=$app
        search_pattern=$app
    fi
    
    close_app "$display_name" "$search_pattern"
done

echo "\n\033[1;32m→ Tất cả các ứng dụng đã được xử lý xong\033[0m"