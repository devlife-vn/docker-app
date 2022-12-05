#!/usr/bin/env bash

clear

google-chrome "http://localhost:8081";

clear

./find_ip_docker.sh ${PWD##*/}-phpmyadmin

./find_ip_docker.sh ${PWD##*/}-mysql

echo "ACCOUNT [root][secret]";

notify-send "Đã mở trình duyệt, bạn có thể thao tác."
