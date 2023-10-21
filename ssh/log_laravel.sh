#!/bin/bash
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
        cd $DIR/

        FILE="storage/logs/laravel-$(date '+%Y-%m-%d').log";

        if [ -f "$FILE" ]; then
            echo "*********************************************[ LOADING CONTENT FILE LOG CURRENT DATE IN FILE ---> ( $FILE ) ]";
            tail -f -n 1000 $FILE | sed \
                    -e 's/\(.*INFO.*\)/\x1B[32m\1\x1B[39m/' \
                    -e 's/\(.*ERROR.*\)/\x1B[31m\1\x1B[39m/' \
                    -e 's/\(.*exception.*\)/\x1B[31m\1\x1B[39m/' \
                    -e 's/\(.*stacktrace.*\)/\x1b[36m\1\x1B[39m/' \
                    -e 's/\(.*vendor.*\)/\x1b[35m\1\x1B[39m/'
        else
            FILE="storage/logs/laravel.log";
            if [ -f "$FILE" ]; then
                echo "*********************************************[ LOADING CONTENT FILE LOG CURRENT DATE IN FILE ---> ( $FILE ) ]";
                tail -f -n 1000 $FILE | sed \
                        -e 's/\(.*INFO.*\)/\x1B[32m\1\x1B[39m/' \
                        -e 's/\(.*ERROR.*\)/\x1B[31m\1\x1B[39m/' \
                        -e 's/\(.*exception.*\)/\x1B[31m\1\x1B[39m/' \
                        -e 's/\(.*stacktrace.*\)/\x1b[36m\1\x1B[39m/' \
                        -e 's/\(.*vendor.*\)/\x1b[35m\1\x1B[39m/'
            else
                echo "*********************************************[ $FILE ***** does not exist ]";
            fi
            echo "*********************************************[ $FILE ***** does not exist ]";
        fi
    else
        echo "Project [$name] không tồn tại";
    fi
fi


