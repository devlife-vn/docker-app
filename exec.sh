#!/usr/bin/env bash

clear

userName=$1
if [ -z "$userName" ]; then
    userName="www-data"
else
    userName=$userName
fi

echo "name=^${PWD##*/}-php-fpm";

dockerId=`docker ps -aqf "name=^${PWD##*/}-php-fpm"`

echo $dockerId

cd ./ssh/

tar -cv * | docker exec -i $dockerId tar x -C /var/www

clear

cd ../

docker exec -it --user=$userName $dockerId bash