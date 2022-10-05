#!/usr/bin/env bash

docker stop $(docker ps -aq)
docker ps

sudo kill $(sudo lsof -t -i:8080)
sudo kill $(sudo lsof -t -i:3306)
sudo kill $(sudo lsof -t -i:9000)
sudo kill $(sudo lsof -t -i:8082)
sudo kill $(sudo lsof -t -i:8083)
sudo kill $(sudo lsof -t -i:8084)
sudo kill $(sudo lsof -t -i:6379)

# docker-compose up
# docker ps
# ./find_IP_docker.sh -a

docker system prune -a --volumes

# docker-compose down --rmi all -v --remove-orphans

# build mysql
docker-compose up --build --force-recreate --no-deps -d mysql
docker ps

# build phpmyadmin
docker-compose up --build --force-recreate --no-deps -d phpmyadmin
docker ps

# build redis
docker-compose up --build --force-recreate --no-deps -d redis
docker ps

# build nginx
docker-compose up --build --force-recreate --no-deps -d nginx
docker ps

# # build client-php
# docker-compose up --build --force-recreate --no-deps -d client-php
# docker ps

# build api-php
docker-compose up --build --force-recreate --no-deps -d workspaces
docker ps
clear
# # build job-server
# docker-compose up --build --force-recreate --no-deps -d job-server
# clear

echo "================================================================= [CONTAINERS] ========================================================================================================";
docker ps

./find_ip_docker.sh -a

echo "================================================================= [CONTAINER ACCOUNTS] ==================================================================================================";
echo "ACCOUNT MYSQL [root][secret]";