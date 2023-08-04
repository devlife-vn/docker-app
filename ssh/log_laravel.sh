#!/bin/bash
NAME=$1
if [ ! -z "$NAME" ]; then
    if [ -d "$NAME" ]; then
        cd $NAME/

        FILE="storage/logs/laravel-$(date '+%Y-%m-%d').log";

        if [ -f "$FILE" ]; then
            echo "*********************************************[ LOADING CONTENT FILE LOG CURRENT DATE IN FILE ---> ( $FILE ) ]";
            tail -f $FILE
        else
            FILE="storage/logs/laravel.log";
            if [ -f "$FILE" ]; then
                echo "*********************************************[ LOADING CONTENT FILE LOG CURRENT DATE IN FILE ---> ( $FILE ) ]";
                tail -f $FILE
            else
                echo "*********************************************[ $FILE ***** does not exist ]";
            fi
            echo "*********************************************[ $FILE ***** does not exist ]";
        fi
    fi
else
    echo "vui lòng nhập tên project";
fi


