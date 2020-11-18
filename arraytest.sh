#!/bin/bash
#List
LIST="1 2 3 4 5 6 7 8 9 10"
for NUMBER in $LIST
do
echo "Number output is $NUMBER"
done
#Array
NAMESLIST=("Bob" "Peter" "$USER" "Big Bad John" "David" "$PATH")
for NAME in "${NAMESLIST[@]}"
do
echo "Number output is "$NAME
done
#Array Two Example
NUMBERLIST=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
for i in "${!NAMESLIST[@]}"
do
NAME1="${NAMESLIST[$i]}"
NUMBER1="${NUMBERLIST[$i]}"
echo $NAME1 "is name number" $NUMBER1 "on the list"
done
