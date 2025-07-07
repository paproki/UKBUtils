#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --job-name=ukb-copy
#SBATCH --time=30:00:00               # Increased to 4 hours per batch
#SBATCH --partition=general           # Adjust to your cluster
#SBATCH --account=a_lena_neuro        # Adjust to your account
#SBATCH -o ukbcopy_%A_%a_output         # %A is job ID, %a is array index
#SBATCH -e ukbcopy_%A_%a_error 

############################### IMPORTANT WARNING ###############################
##
##
## Update time based on your needs
## You need to have access to the QRIS RDM folder /QRISdata/Q7990/bulk
##
##
#################################################################################


############################### BASIC COMMAND LINE ###############################
##
## Example of usage with bulk item 20210
## sbatch ukb_copy_rdm.slurm <path/to/bulk-folder>
## sbatch ukb_copy_rdm.slurm /scratch/user/${USER}/UKB/20210
##
#################################################################################

# Check if bulk file parameter is provided
if [ -z "$1" ]; then
    echo "Error: No bulk folder provided. Usage: sbatch $0 /path/to/bulkfile"
    exit 1
fi

if [[ ! -d $1 ]];then
    echo "Error: $1 needs to be a folder"
    exit 1;
fi

RDMDEST=/QRISdata/Q7990/bulk/
echo "rsync --info=progress2 -azvvh $1 $RDMDEST"
rsync --info=progress2 -azvvh $1 $RDMDEST