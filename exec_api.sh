dockerId=`docker ps -aqf "name=^*api-php*"`
echo $dockerId
docker exec -it --user=root $dockerId bash