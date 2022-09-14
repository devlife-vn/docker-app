#!/usr/bin/env bash

docker-compose down

docker-compose up --build --force-recreate --no-deps -d mysql phpmyadmin redis nginx client-php api-php

docker ps
