#!/usr/bin/env bash

# SHOW CONTAINER

docker ps

# get ip
printf "ENTER CONTAINER ID TO EXEC:"

read dockerId

echo $dockerId

docker exec -it --user=www-data $dockerId bash


