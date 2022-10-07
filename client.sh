clear

dockerId=`docker ps -aqf "name=^*client-php*"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash