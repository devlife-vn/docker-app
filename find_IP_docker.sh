if [ "$1" = "--help" ]
then
echo "
--Usage -> To Find the IP address of the Docker container
--Parameters -> <Name of the container> or <All>
--Sample -> sh find_IP_Address <Parameters>
"

elif [ $# -ne 1 ]
then
echo "
Error -> Parameter is missed
Help -> sh find_IP_Address --help
"

elif [ "$1" = "-a" ]
then
	for container in $(docker ps --format '{{.Names}}')
	do
		for ipadd in $(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $container)
		do
		echo "IP ADDRESS OF CONTAINER [$container]:  $ipadd"
		done
	done

else

	for con in $(docker ps --format '{{.Names}}')
	do
		if [ "$con" = "$1" ]
		then
			for ipadd in $(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $con)
			do
				echo "IP ADDRESS OF CONTAINER [$container]:  $ipadd"
			done
		exit
		fi
	done

echo "
Error -> Unable to find a container with the name $1. Please check the Name and try again
Help -> sh find_IP_Address --help
"

fi