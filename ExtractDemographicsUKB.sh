#!/bin/bash

INPUT_FILE=""
OUTPUT_FILE=""

# Function to display help message
show_help() {
  echo "Usage: $0 --input <input> --otuput <output>"
  echo ""
  echo "Options:"
  echo "  --input <input tab file>    The ukb tab file"
  echo "  --output <output csv file>  The output CSV file"
  echo "Example:"
  echo "  $0 --input ./ukb.tab  --output ./Filtered.csv"
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



#Expl fields
FIELD_IDS=(
    "21003"  # Age at recruitment
    "31"     # Sex
    "21000"  # Ethnic background
    "21001"  # Body mass index (BMI)
    "189"    # Townsend deprivation index
    "20116"  # Smoking status
    "20002"  # Self-reported medical conditions
    "41270"  # Diagnoses from hospital records (ICD-10)
    "6150"   # Vascular/heart problems diagnosed by doctor
    "40100"  # COVID-19 test results
    "22032"  # IPAQ-derived physical activity
    "1558"   # Alcohol intake frequency
    "20208"  # Cardiac MRI data availability
)

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    show_help
    exit 1
fi

# Build the awk command dynamically to extract columns
AWK_FIELDS=""
HEADER_LINE=$(head -n 1 "$INPUT_FILE")  # Read the header
COLS_TO_KEEP=""

# Loop through each Field ID and find matching columns
for field in "${FIELD_IDS[@]}"; do
    # Find all columns that start with f.<FieldID>.
    matching_cols=$(echo "$HEADER_LINE" | tr '\t' '\n' | grep -n "^f\.$field\." | cut -d':' -f1)
    if [ -n "$matching_cols" ]; then
        for col in $matching_cols; do
            # awk uses 1-based indexing, so no adjustment needed
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

# Extract the columns using awk and save as CSV
echo "Extracting columns for Field IDs: ${FIELD_IDS[*]} (plus eid)"
gawk -F'\t' "BEGIN {OFS=\",\"} {print $AWK_PRINT}" "$INPUT_FILE" > "$OUTPUT_FILE"

# Check if output file was created successfully
if [ $? -eq 0 ]; then
    echo "Data extracted successfully to '$OUTPUT_FILE'."
    echo "Extracted columns correspond to indices: $COLS_TO_KEEP"
else
    echo "Error: Failed to extract data."
    exit 1
fi

exit 0