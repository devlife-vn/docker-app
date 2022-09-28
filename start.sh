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


# docker system prune -a --volumes

docker-compose down --rmi all -v --remove-orphans

docker-compose up --build --force-recreate --no-deps -d mysql

clear

docker ps

docker-compose up --build --force-recreate --no-deps -d phpmyadmin

clear

docker ps

docker-compose up --build --force-recreate --no-deps -d redis

clear

docker ps

docker-compose up --build --force-recreate --no-deps -d nginx

clear

docker ps

docker-compose up --build --force-recreate --no-deps -d client-php

clear

docker ps

docker-compose up --build --force-recreate --no-deps -d api-php

clear

docker ps

docker-compose up --build --force-recreate --no-deps -d job-server

clear

docker ps

# docker-compose up --build --force-recreate --no-deps -d mysql phpmyadmin redis nginx client-php