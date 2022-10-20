#!/bin/bash
DIR=$PWD/job/

if [ -d "$DIR" ]; then
  cd $DIR

    clear

    echo "********************************************[ Horizon job is running success ]";

    php artisan horizon:terminate

    php artisan horizon
fi