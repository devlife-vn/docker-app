#!/usr/bin/env bash

docker-compose down

docker-compose up --build --force-recreate --no-deps -d mysql phpmyadmin redis nginx client-php api-php

# LOOP=15
# for (( i=1; i<=LOOP; i++ )) 
# do
    clear
    echo "RELOAD CHECK CONTAINER STATUS: [$i]";
    docker ps
# done