dockerId=`docker ps -aqf "name=^*quandn-api-php*"`
echo $dockerId
docker exec -it --user=root $dockerId bash