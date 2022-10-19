clear

dockerId=`docker ps -aqf "name=^${PWD##*/}-nginx"`
echo $dockerId
docker exec -it --user=root $dockerId bash