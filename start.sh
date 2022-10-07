#!/usr/bin/env bash

./stop.sh

echo "================================================================= [CONTAINER START] ============================================================================================="

docker-compose up php-fpm redis phpmyadmin mysql nginx
