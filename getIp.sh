#!/usr/bin/env bash

# container list
clear

docker ps

./find_ip_docker.sh -a

# get ip
printf "ENTER CONTAINER ID:"

read ipContainerID

for ipadd in $(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $ipContainerID)
do
echo "** HERE IS YOUR IP: - [$ipadd] **"
done