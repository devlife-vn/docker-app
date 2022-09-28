dockerId=`docker ps -aqf "name=^*quandn-nginx*"`
echo $dockerId
docker exec -it --user=root $dockerId bash