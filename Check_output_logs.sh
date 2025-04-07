#!/bin/bash

if [[ -z "$1" ]];then
	echo "Need bulk ID as parameter to find folder"
	exit
fi

bulk_id=$1

for batch in `ls $bulk_id`;
do	
	batch_path=$bulk_id/$batch

	echo "= = = = = = = = = = = = = = = = $batch = = = = = = = = = = = = = = = " >> ./Fail_log_${bulk_id}.log
	if [[ -f $batch_path/fail.log ]];then
		cat -n $batch_path/fail.log >> ./Fail_log_${bulk_id}.log
	else
		echo "No fail log found in $batch" >> ./Fail_log_${bulk_id}.log
	fi

	if [[ -f $batch_path/corrupted_zips.log ]];then
		cat -n $batch_path/corrupted_zips.log >> ./Fail_log_${bulk_id}.log
	else
		echo "No corrupted zip files found in $batch" >> Fail_log_${bulk_id}.log
	fi
	
	echo "= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = " >> ./Fail_log_${bulk_id}.log
done
