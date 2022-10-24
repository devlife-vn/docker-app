#!/usr/bin/env bash
./stop.sh

clear

echo "================================================================= [CONTAINER START] ============================================================================================="

docker-compose up -d php-fpm redis phpmyadmin mysql nginx

clear

docker ps

# byobu send-keys
# byobu split-window -v