#!/usr/bin/env bash

WORKING_DIR=$PWD/laradock
ENV_FILE=$PWD/.env
LARADOCK_URL=https://github.com/Laradock/laradock.git

# install any required dependencies
function install_deps(){
    COMPOSER_COMMAND=`composer install`
    NPM_COMMAND=`npm install`
    exit 0
}

# execute other things
function execute(){
    # check stuff
    if [[ ! -d ${WORKING_DIR} ]]; then
       echo "cloning laradock from ${LARADOCK_URL}"
       git clone ${LARADOCK_URL}
    fi

    # check if .env exists. we should copy the file only if it doesn't exist
    if [ ! -f $PWD/.env ]; then
        echo "copying .env.example to .env..."
        cp $PWD/.env.example $PWD/.env
    fi

    # basically we don't need the git repo in laradock at this point
    if [[ -d ${WORKING_DIR}/.git ]]; then
        echo "cleaning up...."
        rm -rf ${WORKING_DIR}/.git
    fi

    # copy the docker config stub
    cp -r $PWD/docker_compose_sample.yml ${WORKING_DIR}/docker-compose.yml

    # run nginx, mysql, phpmyadmin redis and beanstalkld
    cd ${WORKING_DIR} && docker-compose up -d nginx mysql phpmyadmin redis beanstalkd

    # get the IP address of the redis server
    IP_REDIS=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' laradock_redis_1`

    # get the IP address of the mysql server
    IP_MYSQL=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' laradock_mysql_1`

    echo "use $IP_REDIS as the IP address for connecting to the redis caching server."
    echo "use $IP_MYSQL as the IP address for connecting to the mysql db."

    # do some replacements
    sed -i "s/^\(DB_HOST*=\s*\).*$/\1$IP_MYSQL/" ${ENV_FILE}
    sed -i "s/^\(REDIS_HOST*=\s*\).*$/\1$IP_REDIS/" ${ENV_FILE}

    echo "These settings have been placed in the .env file"
    exit 0
}

function check_windows(){
    os=`uname`
    if [[ "$os" == 'Linux' ]]; then
       echo 1;
    elif [[ "$os" == 'MINGW64_NT-10.0' ]]; then
       echo 2;
    fi
}

function login_to_workspace(){
    echo "logging you into the docker workspace..."
    if [[ $(check_windows) -eq 2 ]]; then
        cd ${WORKING_DIR} && winpty docker-compose exec --user=laradock workspace bash
        exit 0
    else
        cd ${WORKING_DIR} && docker-compose exec --user=laradock workspace bash
        exit 0
    fi
}

function login_root(){
    # note that this logs you in as root
    echo "logging you into the docker workspace..."
    if [[ $(check_windows) -eq 2 ]]; then
        cd ${WORKING_DIR} && winpty docker-compose exec workspace bash
        exit 0
    else
        cd ${WORKING_DIR} && docker-compose exec workspace bash
        exit 0
    fi
}

function login_to_mysql(){
    # mysql
    if [[ $(check_windows) -eq 2 ]]; then
        cd ${WORKING_DIR} && winpty docker-compose exec mysql bash
        exit 0
    else
        cd ${WORKING_DIR} && docker-compose exec mysql bash
        exit 0
    fi
}

function beanstalkd(){
    # queue. Beanstalkd
    cd ${WORKING_DIR} && docker-compose up -d beanstalkd-console
    echo "All done. Visit localhost:2080 to get started"
    exit 0
}

function stop(){
    # nothing much. for now just stops all containers
    cd ${WORKING_DIR} && docker stop $(docker ps -a -q)
    echo "All containers have been stopped."
    exit 0
}

while [ $# -ne 0 ]
do
    arg="$1"
    case "$arg" in
        --deps)
            install_deps
            ;;
        --setupdocker)
            execute
            ;;
        --boot)
            execute
            ;;
        --login)
            login_to_workspace
            ;;
        --login-root)
            login_root
            ;;
        --mysql)
            login_to_mysql
            ;;
        --q)
            beanstalkd
            ;;
        --halt)
            stop
            ;;

    esac
    shift
done

echo "====Usage===="
echo "1. --deps => Install project dependencies (npm, composer)"
echo "2. --setupdocker => Setup required docker containers (pulls the docker containers - currently hardcoded to nginx, mysql, phpmyadmin, redis, beanstalkd)"
echo "3. --boot => Start all required docker containers"
echo "4. --login => Login to the docker workspace container"
echo "5. --login-root => Login to the docker workspace container as root user"
echo "6. --mysql => Logs in to the docker container, to allow you to run mysql on the command line"
echo "7. --q => Runs the beanstalkld queue manager"
echo "8. --halt => Stops all docker containers"