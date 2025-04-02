#!/bin/bash

FAIL_DIR=${HOME}/debug-vrac/Splits/Fails
if [[ ! -d $FAIL_DIR ]];then
    mkdir $FAIL_DIR
fi

LOG=$FAIL_DIR/Fails.log

i=0
n_fails=0
for file in `ls ${HOME}/debug-vrac/Splits/x*`; 
do 
    i=$((i+1));
    ID=$(printf '%03d' $i)

    full_path=${HOME}/debug-vrac/Splits/ukbdata_${ID}.csv

    if [[ ! -f $full_path ]];then
        n_fails=$((n_fails+1))

        cp $file $FAIL_DIR

        echo "$file ukbdata_${ID}.csv"
        echo "$file ukbdata_${ID}.csv" >> $LOG
    fi
done
echo "Total fails = $n_fails"