# container list
docker ps

./find_ip_docker.sh -a

# get ip
printf "ENTER CONTAINER ID:"

read ipContainerID

dockerInspect=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $ipContainerID`


echo "HERE IS YOUR IP: " $dockerInspect