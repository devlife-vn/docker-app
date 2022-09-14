dockerId=`docker ps -aqf "name=^*client-php*"`
echo $dockerId
docker exec -it --user=root $dockerId bash