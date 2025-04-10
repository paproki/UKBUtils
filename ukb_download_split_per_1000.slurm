#!/bin/bash --login
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
##SBATCH --array=0-99                  If split /1000 entries, batch array needs to be passed using sbatch --array=0-$n script.slurm
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --job-name=ukb-down
#SBATCH --time=06:00:00               # Increased to 4 hours per batch
#SBATCH --partition=general           # Adjust to your cluster
#SBATCH --account=a_lena_neuro        # Adjust to your account
#SBATCH -o slurm_%A_%a_output         # %A is job ID, %a is array index
#SBATCH -e slurm_%A_%a_error 

############################### IMPORTANT WARNING ###############################
##
##
## Note that the maximum number of lines you can download per ukbfetch run is 1000 and not 50000 
## (this seems to be a new server-side verification). 
## Note that the maximum number of ukbfetch you can run simultaneous is 10 and this can also
## change depending on server-load (???)
##
##
#################################################################################


############################### BASIC COMMAND LINE ###############################
##
## Example of usage with bulk item 20210
## mkdir BULKD_ID;sbatch --array=0-$((`wc -l < BULKD_FILE.bulk`/1000))%3 ukb_download_split_per_1000.slurm /scratch/user/uqapapro/UKB/bulk.bulk BULKD_ID
##
## For 20210
## mkdir 20210;sbatch --array=0-$((`wc -l < 20210.csv`/1000))%3 ukb_download_split_per_1000.slurm /scratch/user/uqapapro/UKB/20210.csv 20210
##
## Note that I create a directory prior to running the script to not have mutiple jobs trying to create the same folder
##
## This will create a big job array, but only run 3 (%3) jobs simultanously 
##
#################################################################################

# Check if bulk file parameter is provided
if [ -z "$1" ]; then
    echo "Error: No bulk file provided. Usage: sbatch $0 /path/to/bulkfile"
    exit 1
fi

if [[ ! -f $1 ]];then 
    echo "Error: Bulk file $1 does not exist"
    exit 1;
fi

if [[ -z "$2" ]];then 
    echo "Error: No Bulk ID provided"
    exit 1;
fi

BULK_FILE="$1"              # Your bulk file with XX,XXX lines
BULK_ID="$2"                # Your bulk file with XX,XXX lines

# Environment setup
echo "Starting UK Biobank data download at $(date)"
echo "Job ID: $SLURM_ARRAY_JOB_ID, Array Task ID: $SLURM_ARRAY_TASK_ID"

# Set working directory
WORK_DIR="/scratch/user/${USER}/UKB"  # Replace with your directory
cd "$WORK_DIR" || exit 1

TOOLS_DIR="/scratch/user/${USER}/tools"

# Paths to files
UKBFETCH="$TOOLS_DIR/ukbfetch"              # Adjust path to ukbfetch
AUTH_KEY="$TOOLS_DIR/k100773x53188.key"     # Authentication key

# The file below is used to check for 'expected' errors for participants that cannot be downloaded
OUTPUT_SLURM=$WORK_DIR/slurm_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}_output #Output log file from script

# Check if required files exist
if [ ! -f "$UKBFETCH" ]; then
    echo "Error: ukbfetch not found at $UKBFETCH"
    exit 1
fi
if [ ! -f "$BULK_FILE" ]; then
    echo "Error: Bulk file not found at $BULK_FILE"
    exit 1
fi
if [ ! -f "$AUTH_KEY" ]; then
    echo "Warning: .ukbkey not found at $AUTH_KEY, assuming it’s in ~/"
fi

# Calculate start and max lines for this batch
TOTAL_LINES=$(wc -l < "$BULK_FILE") #w/ test file 75766
BATCH_SIZE=1000
N_BATCHES=$((TOTAL_LINES/BATCH_SIZE + 1))

   # Lines per batch for 0-98
LAST_BATCH_LINES=$((TOTAL_LINES-(BATCH_SIZE*(N_BATCHES - 1))))  # Lines for batch 99
LAST_BATCH_IDX=$((N_BATCHES-1))

START_LINE=$((SLURM_ARRAY_TASK_ID * BATCH_SIZE + 1))
if [ $SLURM_ARRAY_TASK_ID -eq $LAST_BATCH_IDX ]; then
    MAX_LINES=$LAST_BATCH_LINES
else
    MAX_LINES=$BATCH_SIZE
fi

echo "Batch $SLURM_ARRAY_TASK_ID: Start line = $START_LINE, Max lines = $MAX_LINES"

#
# SETUP DIRECTORY AND CHANGE DIRECTORY FOR DLD
#

# Create a directory for this batch
BATCH_NAME=$(printf '%03d' $SLURM_ARRAY_TASK_ID) # Formatting 00X
BATCH_DIR="batch_${BATCH_NAME}"
FETCHED="fetched_${BATCH_NAME}"
mkdir -p "$BULK_ID/$BATCH_DIR"
cd "$BULK_ID/$BATCH_DIR" || exit 1

# Run ukbfetch
echo "Running ukbfetch for batch $SLURM_ARRAY_TASK_ID..."
srun "$UKBFETCH" -b"$BULK_FILE" -s"$START_LINE" -m"$MAX_LINES" -a"$AUTH_KEY" -o$FETCHED


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check if ukbfetch command was successful and perform basic quality control
#       1. Check if zip files exist against expected list
#            -> Track failed download into fail.log
#            -> If fail_XXX.txt does not exist, all is good
#       2. Read from output log to see if there are 'expected' failures (Error with Code 2)
#       3. Check if zip files are corrupted and log into separate files
#            -> Track failed download into corrupted_zips.log
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#
#   CHECK DOWNLOADED ZIPS AGAINST EXPECTED ZIPS
#
if [ $? -eq 0 ]; then
    # Log successful completion with timestamp
    echo "Batch $SLURM_ARRAY_TASK_ID completed successfully at $(date)"
    
    # Count number of files downloaded by checking the .lis file
    FILE_COUNT=$(wc -w < "$FETCHED.lis")
    echo "Downloaded $FILE_COUNT files"

    # Create temporary files to track downloads
    TEMP_BULK="temp_bulk_${BATCH_NAME}.txt"   # Temporary file with bulk entries for this batch
    FAILED="fail.log"                         # File to track failed downloads

    if [[ -f $FAILED ]];then
	    rm $FAILED
    fi

    if [[ -f $TEMP_BULK ]];then
	    rm $TEMP_BULK
    fi
    
    # Calculate the range of lines from bulk file for this batch
    END_LINE=$((START_LINE + MAX_LINES - 1))
    
    # Extract relevant lines from bulk file into temporary file
    sed -n "${START_LINE},${END_LINE}p" "$BULK_FILE" > "$TEMP_BULK"
    
    # Check each expected download against actual files
    while read PID FID; do
        # If expected zip file doesn't exist, log it as failed
        if [[ ! -f ${PID}_${FID}.zip ]]; then
            echo "${PID} ${FID} ${PID}_${FID}.zip" >> $FAILED
        fi
    done < $TEMP_BULK
else
    # Log error and exit if ukbfetch failed
    echo "Error: ukbfetch failed for batch $SLURM_ARRAY_TASK_ID"
    exit 1
fi


#
#   CHECK FOR EXPECTED FAILURES IN THE SLURM OUTPUT LOG FILE AND LOG IT IN THE 
#   FAILED DOWNLOAD FILE
#

n_exp_fails_exp=$((`cat $OUTPUT_SLURM | grep Error | grep code\ 2 | wc -l`))
n_exp_fails_exp2=$((`cat $OUTPUT_SLURM | grep position\ 2 | wc -l`))
estimated_number=$(( (n_exp_fails_exp+n_exp_fails_exp2)/2 ))
echo "Expected fails (estimated): $estimated_number" >> $FAILED

#
#   CHECK FOR UKB SERVER ERRORS
#
SERVER_LOG="server_failure.log"
if [[ -f $SERVER_LOG ]];then
	rm $SERVER_LOG
fi
server_fails1=$((`cat $OUTPUT_SLURM | grep biota.ndph.ox.ac.uk | wc -l`))
server_fails2=$((`cat $OUTPUT_SLURM | grep chest.ndph.ox.ac.uk | wc -l`))
if [[ $server_fails1 -gt 0 ]] || [[ $server_fails2 -gt 0 ]];then
    echo "Some UKB servers failed" >> $SERVER_LOG
fi


#
#   CHECK FOR MALFORMED ZIP FILES THAT CANNOT BE UNZIPPED USING unzip -t (i.e., silent unzip for testing)
#

if [[ -f corrupted_zips.log ]];then
	rm corrupted_zips.log
fi

find . -name "*.zip" | xargs -n 1 -P 4 -I {} bash -c 'if ! unzip -t "{}" >/dev/null 2>&1; then echo "{}" >> corrupted_zips.log; fi'


echo "Batch $SLURM_ARRAY_TASK_ID finished at $(date)"
