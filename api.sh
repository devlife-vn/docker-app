clear

dockerId=`docker ps -aqf "name=^*api-php*"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash