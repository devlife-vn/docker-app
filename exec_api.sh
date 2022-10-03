dockerId=`docker ps -aqf "name=^*quandn-api-php*"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash