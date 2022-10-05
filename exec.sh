dockerId=`docker ps -aqf "name=^*workspaces*"`
echo $dockerId
docker exec -it --user=www-data $dockerId bash