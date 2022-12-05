#!/usr/bin/env bash

clear

dockerId=`docker ps -aqf "name=^${PWD##*/}-php-fpm"`
echo $dockerId
docker exec -it --user=root $dockerId bash -c "./clear_cache.sh;"
