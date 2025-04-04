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

if [[ ! -d $1 ]];then 
    echo "Error: $1 needs to be a folder"
    exit 1;
fi

RDMDEST=/QRISdata/Q7990/bulk

cp $1 $RDMDEST