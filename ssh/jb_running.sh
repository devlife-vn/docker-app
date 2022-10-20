#!/bin/bash
DIR=$PWD/api/

if [ -d "$DIR" ]; then
  cd $DIR

    clear

    echo "********************************************[ Horizon is running success ]";

    php artisan horizon:terminate

    php artisan horizon
fi