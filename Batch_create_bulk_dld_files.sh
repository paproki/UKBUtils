#!/bin/bash

all_field_config="${HOME}/Dev/UKBUtils/ukb_fields_new.txt"

while read BulkID;
do
    echo " > > > $BulkID < < <"
    fields="participant.eid"
    
    for bField in `cat $all_field_config | grep p$BulkID`;
    do
        fields="${fields},${bField}"
    done
    echo "dx extract_dataset record-GzfyQXjJ6yvFxGkYpqVK9G9G --fields $fields --output participants_${BulkID}.csv"
    echo "bash ukb-rap/Filter_dx_output.sh --input participants_${BulkID}.csv --output ${BulkID}.bulk"
done < All_bulk_ids.txt
