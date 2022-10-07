echo "================================================================= [CONTAINER IP] =============================================================================================";

if [ "$1" = "--help" ]
	then
	echo "
	--Usage -> To Find the IP address of the Docker container
	--Parameters -> <Name of the container> or <All>
	--Sample -> sh find_ip_docker <Parameters>
	"
elif [ $# -ne 1 ]
	then
	echo "
	Error -> Parameter is missed
	Help -> sh find_ip_docker --help
	"
elif [ "$1" = "-a" ]
	then
	for container in $(docker ps --format '{{.Names}}')
	do
		for ipadd in $(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $container)
		do
		echo "** $container - [$ipadd] **"
		done
	done
else
	for container in $(docker ps --format '{{.Names}}')
	do
		if [ "$container" = "$1" ]
		then
			for ipadd in $(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}} {{end}}' $container)
			do
				echo "** $container - [$ipadd] **"
			done
		exit
		fi
	done
	echo "
	Error -> Unable to find a container with the name $1. Please check the Name and try again
	Help -> sh find_ip_docker --help
	"
fi