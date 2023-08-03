#!/usr/bin/env bash
clear

./stop.sh

docker system prune -a --volumes

echo "=============== [CONTAINER REBUILD] ==============="


docker-compose up --build --force-recreate --remove-orphans --no-deps -d mysql
docker ps

docker-compose up --build --force-recreate --remove-orphans --no-deps -d phpmyadmin
docker ps

docker-compose up --build --force-recreate --remove-orphans --no-deps -d redis
docker ps

docker-compose up --build --force-recreate --remove-orphans --no-deps -d nginx
docker ps

# docker-compose up --build --force-recreate --remove-orphans --no-deps -d client-php
# docker ps

# build api-php

# docker-compose up --build --force-recreate --remove-orphans --no-deps -d job-server
# clear

docker-compose up --build --force-recreate --remove-orphans --no-deps -d php-fpm
docker ps
# clear