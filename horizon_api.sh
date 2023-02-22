#!/usr/bin/env bash
clear

dockerId=`docker ps -aqf "name=^${PWD##*/}-php-fpm"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash -c "ls -lsh; ./horizon_api.sh;"
