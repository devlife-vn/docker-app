dockerId=`docker ps -aqf "name=^*quandn-mysql*"`
echo $dockerId
docker exec -it --user=root $dockerId bash -c "mysql -u root -psecret; source db.sql;"
