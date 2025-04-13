#!/bin/bash

#This file is here to try and redownload the failed cases that can be found in fail.log files
#after the ukb download script finished
#This can be useful in case where there was a DNS/server error during the download.
#You need to copy this script in your local tools directory where ukbfetch and the key
#are located

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