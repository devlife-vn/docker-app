#!/usr/bin/env bash

clear

userName=$1
if [ -z "$userName" ]; then
    read -p "Bạn có muốn thay đổi user (bỏ trống để đăng nhập bằng www-data): " userNameEnter;
    if [ -z "$userNameEnter" ]; then
      userName="www-data"
    else
      userName=$userNameEnter
    fi
fi

echo "name=^${PWD##*/}-php-fpm";

dockerId=`docker ps -aqf "name=^${PWD##*/}-php-fpm"`

echo $dockerId

cd ./ssh/

tar -cv * | docker exec -i $dockerId tar x -C /var/www

clear

cd ../

docker exec -it --user=$userName $dockerId bash