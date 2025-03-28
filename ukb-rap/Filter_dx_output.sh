INPUT_FILE=""
OUTPUT_FILE=""

# Function to display help message
show_help() {
  echo "Usage: $0 --input <input> --otuput <output>"
  echo ""
  echo "Options:"
  echo "  --input <input dx output file>    The full file containing the data"
  echo "  --output <output json?? file>     The output CSV file"
  echo "Example:"
  echo "  $0 --input ./DX_output.json  --output ./Filtered_output.bulk"
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

if [[ -f $OUTPUT_FILE ]];then
    rm $OUTPUT_FILE
fi

IFS=","
i=0
n_have_2=0
while read EID FIELD1 FIELD2;
do
    if [[ $i == 0 ]];then
        i=$((i+1))
        continue;
    fi 
    if [[ "$FIELD1" != "" ]];then
        str_bulk=${FIELD1/${EID}_/}
        str_bulk=${str_bulk/.zip/}
        echo "$EID $str_bulk" >> $OUTPUT_FILE
    fi

    if [[ "$FIELD2" != "" ]];then
        str_bulk=${FIELD2/${EID}_/}
        str_bulk=${str_bulk/.zip/}
        echo "$EID $str_bulk" >> $OUTPUT_FILE
    fi
    
    if [[ "$FIELD1" != "" ]] && [[ "$FIELD2" != "" ]];then
        n_have_2=$((n_have_2+1))
    fi

done < $INPUT_FILE 

echo "This many participants have had 2 scans: $n_have_2"