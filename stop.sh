clear

echo "================================================================= [CONTAINER STOP] ============================================================================================="


#!/usr/bin/env bash
docker stop $(docker ps -aq)

docker ps

sudo kill $(sudo lsof -t -i:8080)
sudo kill $(sudo lsof -t -i:3306)
sudo kill $(sudo lsof -t -i:9000)
sudo kill $(sudo lsof -t -i:8082)
sudo kill $(sudo lsof -t -i:8083)
sudo kill $(sudo lsof -t -i:8084)
sudo kill $(sudo lsof -t -i:6379)


# clear
