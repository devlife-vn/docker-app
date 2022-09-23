#!/usr/bin/env bash

docker stop $(docker ps -aq)

docker ps

# docker system prune -a --volumes

docker-compose down --rmi all -v --remove-orphans

docker-compose up --build --force-recreate --no-deps -d mysql phpmyadmin redis nginx client-php api-php
# docker-compose up --build --force-recreate --no-deps -d mysql phpmyadmin redis nginx client-php
