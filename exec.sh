dockerId=`docker ps -aqf "name=^*php-fpm*"`

echo $dockerId

cd ./ssh/

tar -cv * | docker exec -i $dockerId tar x -C /var/www

clear

cd ../

docker exec -it --user=www-data $dockerId bash