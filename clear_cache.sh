#!/usr/bin/env bash

clear

dockerId=`docker ps -aqf "name=^${PWD##*/}-php-fpm"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash -c "./clear_cache.sh;"

# DIR="api-devlife/"
# cd ~;
# if [ -d "$DIR" ]; then

#   cd $DIR

#   for (( index=1; index<=LOOP; index++ ))
#   do
#     echo "*********************************************[ CLEAR CACHE SOURCE api-devlife --$TIMESTAMP-- --$index-- ]";
#     php artisan optimize
#     php artisan cache:clear
#     php artisan config:clear
#     php artisan route:clear
#     php artisan route:cache
#     php artisan view:clear
#     php artisan view:cache
#     composer dump-autoload
#     clear
#   done
# fi

# echo "*********************************************[ clear cache successfuly..... ]*********************************************";
