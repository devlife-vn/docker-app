#!/usr/bin/env bash
./stop.sh

clear

echo "========= [CONTAINER START] ========="

docker-compose up -d php-fpm redis phpmyadmin mysql nginx

# clear

docker ps

# notify-send "Đã bật hết tất cả container, bạn có thể chạy dự án rồi"

# byobu send-keys
# byobu split-window -v