dockerId=`docker ps -aqf "name=^*client-php*"`
echo $dockerId
docker exec -it --user=root $dockerId bash -c "./clear_cache.sh"