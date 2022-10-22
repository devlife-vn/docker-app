#!/bin/bash

clear

TIMESTAMP=$(date '+%Y-%m-%d')

LOOP=1

DIR="authtanthanhdat/"

if [ -d "$DIR" ]; then

  cd $DIR

  for (( index=1; index<=LOOP; index++ ))
  do
    echo "*********************************************[ CLEAR CACHE SOURCE CLIENT --$TIMESTAMP-- --$index-- ]";
    php artisan cache:clear
    php artisan config:clear
    php artisan route:cache
    php artisan route:clear
    composer dump-autoload
    clear
  done
fi

DIR="../job/"

if [ -d "$DIR" ]; then

  cd $DIR

  for (( index=1; index<=LOOP; index++ ))
  do
    echo "*********************************************[ CLEAR CACHE SOURCE JOB --$TIMESTAMP-- --$index-- ]";
    php artisan cache:clear
    php artisan config:clear
    php artisan route:cache
    php artisan route:clear
    composer dump-autoload
    clear
  done
fi


DIR="../api/"

if [ -d "$DIR" ]; then

  cd $DIR
  
  for (( index=1; index<=LOOP; index++ ))
  do
    echo "*********************************************[ CLEAR CACHE SOURCE API --$TIMESTAMP-- --$index-- ]";
    php artisan cache:clear
    php artisan config:clear
    php artisan route:cache
    php artisan route:clear
    composer dump-autoload
    clear
  done
fi

DIR="../ademsios/"

if [ -d "$DIR" ]; then

  cd $DIR

  for (( index=1; index<=LOOP; index++ ))
  do
    echo "*********************************************[ CLEAR CACHE SOURCE ademsios --$TIMESTAMP-- --$index-- ]";
    php artisan cache:clear
    php artisan config:clear
    php artisan route:cache
    php artisan route:clear
    composer dump-autoload
    clear
  done
fi

echo "*********************************************[ clear cache successfuly..... ]*********************************************";
