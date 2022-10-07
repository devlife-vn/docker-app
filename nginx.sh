clear

dockerId=`docker ps -aqf "name=^*nginx*"`
echo $dockerId
docker exec -it --user=root $dockerId bash