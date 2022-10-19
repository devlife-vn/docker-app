#!/bin/bash

clear

TIMESTAMP=$(date '+%Y-%m-%d')

LOOP=1

DIR="authtanthanhdat/"

if [ -d "$DIR" ]; then

  cd $DIR

  for (( i=1; i<=LOOP; i++ ))
  do
    echo $TIMESTAMP
    echo "*********************************************[ CLEAR CACHE SOURCE CLIENT --$i-- ]";
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
    echo $TIMESTAMP
    echo "*********************************************[ CLEAR CACHE SOURCE JOB --$index-- ]";
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
    echo $TIMESTAMP
    echo "*********************************************[ CLEAR CACHE SOURCE API --$index-- ]";
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
    echo $TIMESTAMP
    echo "*********************************************[ CLEAR CACHE SOURCE ademsios --$index-- ]";
    php artisan cache:clear
    php artisan config:clear
    php artisan route:cache
    php artisan route:clear
    composer dump-autoload
    clear
  done
fi
