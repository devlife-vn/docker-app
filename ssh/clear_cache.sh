#!/bin/bash

clear

TIMESTAMP=$(date '+%Y-%m-%d')

echo $TIMESTAMP

cd authtanthanhdat/

LOOP=1


for (( i=1; i<=LOOP; i++ ))
do
  echo "*********************************************[ CLEAR CACHE SOURCE CLIENT --$i-- ]";

  ##php artisan key:gen

  php artisan cache:clear

  php artisan config:clear

  php artisan route:cache

  php artisan route:clear

  composer dump-autoload
  ## ./clear_cache.sh
  clear
done

cd ../job/
for (( index=1; index<=LOOP; index++ ))
do
  echo "*********************************************[ CLEAR CACHE SOURCE JOB --$index-- ]";
  ##php artisan key:gen

  php artisan cache:clear

  php artisan config:clear

  php artisan route:cache

  php artisan route:clear

  composer dump-autoload

  ## ./clear_cache.sh
  clear
done

cd ../api/

for (( index=1; index<=LOOP; index++ ))
do
  echo "*********************************************[ CLEAR CACHE SOURCE API --$index-- ]";
  ##php artisan key:gen

  php artisan cache:clear

  php artisan config:clear

  php artisan route:cache

  php artisan route:clear

  composer dump-autoload

  ## ./clear_cache.sh
  clear
done

cd ../

./log_laravel.sh
