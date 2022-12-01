#!/usr/bin/env bash

# SHOW CONTAINER

docker ps

# get ip
printf "ENTER CONTAINER ID TO EXEC:"

read dockerId

echo $dockerId

docker exec -it --user=root $dockerId bash


# docker exec -i tanthanhdat-redis redis-cli FLUSHALL