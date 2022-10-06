#!/bin/bash

cd api 

composer install --ignore-platform-reqs

php artisan passport:install --force

php artisan key:gen


cd ../authtanthanhdat 

composer install --ignore-platform-reqs

php artisan key:gen

cd ../

./clear_cache.sh
