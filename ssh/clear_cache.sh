#!/bin/bash
TIMESTAMP=$(date '+%Y-%m-%d')
LOOP=1
name=$1
if [ -z "$name" ]; then
    read -p "Nhập tên project: " PROJECTNAME;
    if [ -z "$PROJECTNAME" ]; then
      echo "bye bye";
    else
      name=$PROJECTNAME
    fi
fi

if [ ! -z "$name" ]; then
  DIR="/var/www/$name/"

  if [ -d "$DIR" ]; then
      cd $DIR
      for (( index=1; index<=LOOP; index++ ))
      do
        echo "********************[$DIR]***[$TIMESTAMP]***[$index]********************";
        php artisan cache:clear
        php artisan config:clear
        php artisan route:clear
        php artisan route:cache
        php artisan optimize
        composer dump-autoload
      done
      echo "********************[ clear cache successfuly..... ]********************";
  else
      echo "Project [$name] không tồn tại";
  fi
fi
