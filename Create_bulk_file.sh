#!/bin/bash

INPUT_FILE=""
OUTPUT_FILE=""

# Function to display help message
show_help() {
  echo "Usage: $0 --input <input> --otuput <output>"
  echo ""
  echo "Options:"
  echo "  --input <input tab file>    The ukb tab file"
  echo "  --output <output bulk file>  The output bulk file"
  echo "  --bulkid <Bulk ID> The id of the bulk"
  echo "Example:"
  echo "  $0 --input ./ukb.tab  --output ./Blabla.bulk --bulkid 20210 "
  exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      INPUT_FILE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --bulkid)
      BULK_ID="$2"
      shift 2
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown parameter: $1"
      show_help
      exit 1
      ;;
  esac
done



FIELD_IDS=(
    $BULK_ID
)

# THESE FIELDS ARE RESTRICTED

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    show_help
    exit 1
fi

# # # # # # # # # # # # # # # # # # # # # # # #
#
#           STEP 1: Filter Tab file
#
# # # # # # # # # # # # # # # # # # # # # # # #



# Build the awk command dynamically to extract columns
AWK_FIELDS=""
HEADER_LINE=$(head -n 1 "$INPUT_FILE")  # Read the header
COLS_TO_KEEP=""

# Loop through each Field ID and find matching columns
#n_matching_fields=0
for field in "${FIELD_IDS[@]}"; do
    # Find all columns that start with f.<FieldID>.
    matching_cols=$(echo "$HEADER_LINE" | tr '\t' '\n' | grep -n "^f\.$field\." | cut -d':' -f1)
    if [ -n "$matching_cols" ]; then
        for col in $matching_cols; do
            # awk uses 1-based indexing, so no adjustment needed
            #n_matching_fields=$((n_matching_fields+1))
            if [ -z "$COLS_TO_KEEP" ]; then
                COLS_TO_KEEP="$col"
            else
                COLS_TO_KEEP="$COLS_TO_KEEP,$col"
            fi
        done
    else
        echo "Warning: No columns found for Field ID $field"
    fi
done

# If no columns were found, exit
if [ -z "$COLS_TO_KEEP" ]; then
    echo "Error: No matching columns found for the specified Field IDs."
    exit 1
fi

# Convert COLS_TO_KEEP into an awk-compatible print statement
AWK_PRINT="\$1"
for col in $(echo "$COLS_TO_KEEP" | tr ',' ' '); do
    if [ -z "$AWK_PRINT" ]; then
        AWK_PRINT="\$$col"
    else
        AWK_PRINT="$AWK_PRINT,\$$col"
    fi
done

# Extract the columns using awk and save as temp csv file
TEMP_BULK=${OUTPUT_FILE/.bulk/.csv}
echo "Extracting columns for Field IDs: ${FIELD_IDS[*]} (plus eid)"
gawk -F'\t' "BEGIN {OFS=\",\"} {print $AWK_PRINT}" "$INPUT_FILE" > "$TEMP_BULK"

# Check if output file was created successfully
if [ $? -eq 0 ]; then
    echo "Data extracted successfully to '$TEMP_BULK'."
    echo "Extracted columns correspond to indices: $COLS_TO_KEEP"
else
    echo "Error: Failed to extract data."
    exit 1
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#     STEP 2: Create bulk file from temp csv file
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ -f $OUTPUT_FILE ]];then
    rm $OUTPUT_FILE
fi

IFS=","
i=0
while read -r -a fields; do
    if [[ $i -eq 0 ]]; then
        i=$((i + 1))
        continue  # Skip the header row
    fi

    # First column is the ID
    ID="${fields[0]}"

    # Loop through columns 1 to n-1 (excluding ID, 0-based index)
    for ((j = 1; j < ${#fields[@]}; j++)); do
        value="${fields[$j]//\"/}"  # Remove quotes from the value
        if [[ "$value" != "NA" ]]; then
            echo "$ID $value" >> "$OUTPUT_FILE"
        fi
    done

done < "$TEMP_BULK"

rm $TEMP_BULK 

exit 0