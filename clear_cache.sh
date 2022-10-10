clear

dockerId=`docker ps -aqf "name=^*quandn-php-fpm*"`
echo $dockerId
docker exec -it --user=root $dockerId bash -c "./clear_cache.sh;"
