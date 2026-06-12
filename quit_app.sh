#!/bin/bash
# Script để thoát các ứng dụng trong danh sách
# Tối ưu cho hiệu năng

# Hiển thị header
echo "\033[1;34m=== Thoát các ứng dụng ===\033[0m"

# Danh sách các ứng dụng cần thoát
apps=(
    "Zalo"
    "Discord"
    "Telegram"
    "Visual Studio Code"
)

echo "\033[1;33m→ Thoát các ứng dụng chỉ định\033[0m"

# Function để thoát một ứng dụng
quit_app() {
    local app_name=$1

    echo -n "• Đang thoát $app_name... "

    # Kiểm tra nếu ứng dụng đang chạy
    if ! pgrep -i "$app_name" > /dev/null; then
        echo "\033[1;33m! Không đang chạy\033[0m"
        return
    fi

    # Thoát ứng dụng một cách graceful
    osascript -e "quit app \"$app_name\"" 2>/dev/null

    # Đợi một chút để app có thời gian thoát
    sleep 0.5

    # Kiểm tra kết quả
    if ! pgrep -i "$app_name" > /dev/null; then
        echo "\033[1;32m✓ Đã thoát\033[0m"
    else
        # Nếu vẫn chạy, force quit
        echo -n "\033[1;33m! Đang force quit... \033[0m"
        pkill -i "$app_name"
        sleep 0.3

        if ! pgrep -i "$app_name" > /dev/null; then
            echo "\033[1;32m✓ Đã thoát (force)\033[0m"
        else
            echo "\033[1;31m× Không thể thoát\033[0m"
        fi
    fi
}

# Thoát tất cả các ứng dụng chỉ định
for app in "${apps[@]}"; do
    # Tách tên hiển thị và mẫu tìm kiếm
    if [[ "$app" == *"|"* ]]; then
        display_name=${app%%|*}
        app_name=$display_name
    else
        display_name=$app
        app_name=$app
    fi

    quit_app "$app_name"
done

