#!/bin/bash

if [[ ! -f $1 ]];then
    echo "Please pass the fail log as argument"
    exit
fi

IFS=" "

while read pID fID zip;
do

    echo "Redownloading for id = ${pID}; fid = ${fID}"

    echo "./ukbfetch -e${pID} -d${fID} -a./k100773x53188.key"
    ./ukbfetch -e${pID} -d${fID} -a./k100773x53188.key
done < $1