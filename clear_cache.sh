dockerId=`docker ps -aqf "name=^*php-fpm*"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash -c "./clear_cache.sh"
