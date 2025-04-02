#!/bin/bash

i=0
for file in `ls ${HOME}/debug-vrac/Splits/x*`; 
do 
    i=$((i+1));
    ID=$(printf '%03d' $i)

    if [[ $i == 1 ]];then
        echo "dx extract_dataset record-GzX8y9QJ6yv3VYPYq654fJGg --fields-file $file --output ${HOME}/debug-vrac/Splits/ukbdata_${ID}.csv"
        dx extract_dataset record-GzX8y9QJ6yv3VYPYq654fJGg --fields-file $file --output ${HOME}/debug-vrac/Splits/ukbdata_${ID}.csv
    else
        sed -i '1i participant.eid' $file
        echo "dx extract_dataset record-GzX8y9QJ6yv3VYPYq654fJGg --fields-file $file --output ${HOME}/debug-vrac/Splits/ukbdata_${ID}.csv"
        dx extract_dataset record-GzX8y9QJ6yv3VYPYq654fJGg --fields-file $file --output ${HOME}/debug-vrac/Splits/ukbdata_${ID}.csv
    fi
done