clear

dockerId=`docker ps -aqf "name=^${PWD##*/}-client-php"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash