clear

dockerId=`docker ps -aqf "name=^${PWD##*/}-api-php"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash