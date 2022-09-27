#!/usr/bin/env bash

docker stop $(docker ps -aq)
docker ps

kill $(sudo lsof -t -i:8080)
kill $(sudo lsof -t -i:3306)
kill $(sudo lsof -t -i:9000)
kill $(sudo lsof -t -i:8082)
kill $(sudo lsof -t -i:8083)
kill $(sudo lsof -t -i:6379)


# docker system prune -a --volumes

docker-compose down --rmi all -v --remove-orphans

docker-compose up --build --force-recreate --no-deps -d mysql phpmyadmin redis nginx client-php api-php
# docker-compose up --build --force-recreate --no-deps -d mysql phpmyadmin redis nginx client-php