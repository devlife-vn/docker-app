#!/usr/bin/env bash
clear

dockerId=`docker ps -aqf "name=^${PWD##*/}-php-fpm"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash -c "cd authtanthanhdat; ls -lsh; npm run watch; exit; google-chrome 'http://auth.tanthanhdat.local/';"
