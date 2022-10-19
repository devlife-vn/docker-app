#!/usr/bin/env bash
echo "================================================================= [CONTAINER START] ============================================================================================="

docker-compose up -d php-fpm redis phpmyadmin mysql nginx

clear

docker ps
