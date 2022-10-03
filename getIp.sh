# container list
docker ps

# get ip
printf "ENTER CONTAINER ID:"

read ipContainerID

dockerInspect=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $ipContainerID`


echo "HERE IS YOUR IP: " $dockerInspect