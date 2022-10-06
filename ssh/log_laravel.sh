#!/bin/bash
cd api/


FILE="storage/logs/laravel-$(date '+%Y-%m-%d').log";

if [ -f "$FILE" ]; then
    echo "*********************************************[ LOADING CONTENT FILE LOG CURRENT DATE IN FILE ---> ( $FILE ) ]";
    tail -f storage/logs/laravel-$(date '+%Y-%m-%d').log
else
    echo "*********************************************[ $FILE ***** does not exist ]";
fi

