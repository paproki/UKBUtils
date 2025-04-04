# UKB Download utility scripts

This repository covers script to do basic manipulation of the tab files from the UKB and perform parallel downloads using ukbfetch on HPC systems running slurm.

## Basic directory structure on scratch

For the download script, the assumed directory structure is as follows:

```
/scratch/user/{USER}/
--------------------/tools
--------------------/tools/ukbfetch
--------------------/tools/***.key
/scratch/user/{USER}/
--------------------/UKB
--------------------/UKB/ukb_download_split_per_1000.slurm
--------------------/UKB/XXXXX.bulk
--------------------/UKB/YYYYY.bulk
--------------------/...
```

All slurm output logs will be saved under /scratch/user/{USER}/UKB

## ukb_download_split_per_1000.slurm script usage

The ukb_download_split_per_1000.slurm will start a job array and distribute jobs accross available resources. The script takes as input the bulk file to download and the bulk ID itself. Since we are splitting the files into multiple batches of 1000 (max allowed number of lines downloaded per ukbfetch script), the number of jobs will be different for each bulk file. You can identify the number of jobs using basic bash commands (e.g., wc -l < 20210.bulk ). Assuming that you have currently seating in the folder **/scratch/user/${USER}/UKB** and that you have copied the download script inside of it, an example of command line to start a bulk file download for bulk item 20210 would be:

```
mkdir 20210;sbatch --array=0-$((`wc -l < 20210.bulk`/1000))%10 ukb_download_split_per_1000.slurm /scratch/user/${USER}/UKB/20210.bulk 20210
```
We start by creating a folder for the bulk item. I prefer to do it before to avoid having several jobs trying to create it, which may cause trouble.

If the bulk file 20210.bulk contains 75766 lines, this command line will create a job array of size 0-75 (n=76). In this case, because I suffixed **%10** to the --array=0-75%10 parameter, slurm with only run 10 jobs simultaneously. Since we have only 10 instances that we can run simultaneously between all of us we'll need to change this to predefined number, for example %3. 

Note that if you wanted to do a little try with a couple batches you can simply run the following command with a small 0-1 array. It will create a job array with 2 jobs running simultaneously (replace the folder name and bulk file with your own):
```
mkdir 20210;sbatch --array=0-1%2 ukb_download_split_per_1000.slurm /scratch/user/${USER}/UKB/20210.bulk 20210
```

The script itself will create several batch folders as follows:


```
/scratch/user/{USER}/UKB/20210
------------------------/20210/batch_000
------------------------/20210/batch_000/SUBJECTID_20210_X_0.zip
------------------------/20210/batch_000/...
------------------------/20210/batch_000/SUBJECTID_20210_X_0.zip
------------------------/20210/batch_000/fetched_000.lis
------------------------/20210/batch_000/fail.log
------------------------/20210/batch_000/corrupted_zips.log
------------------------/20210/batch_001
------------------------/20210/...
------------------------/20210/batch_075
```

<ins>**fail.log**</ins> will contain information on the zip that were not downloaded at all (i.e., completely missing) and the last line will contain the number of **expected fails**. For some reason some subjects are not available for download and the ukbfetch returns an error with a 'code 2', which I used to count the number of 'expected' failures which we can then compare to the number of missing zips.
An example of fail.log would be
```
1204125 20210_3_0 1204125_20210_3_0.zip
1207981 20210_3_0 1207981_20210_3_0.zip
1259527 20210_3_0 1259527_20210_3_0.zip
3
```

This information can be used to detect abnormal errors. If the number at the bottom differs from the number of missing zips then something else happened ( ¯\\\_(ツ)\_/¯ ). 

Finally the file **<ins>corrupted_zips.log</ins>** will only be created if the script detects that a zip file is malformed. To test this I go through all the zip files and try unzipping them using 'unzip -t XXXXXXXXXX.zip', which runs a 'silent' unzipping that does not actually do the unzipping but tests if it would work.

At the moment the maximum time dedicated for each individual job is 6 hours. You may need to change this based on your needs (e.g., diffusion MRI will be huge). For each bulk file I would recommend downloading a couple of examples individually on your own machine to check the size of the zip file. The command to download an individual zip for a given Subject EID and bulk ID  is as follows:
```
  ukbfetch -e<EID> -d<BULK-ID> -a/path/to/key.key
```
You can find example EID and BULKD-ID in the bulkfiles.bulk. (PS: do not add a space between the -e and <EDI>, it needs to be something like -e987987464 all struck together)

It takes roughly 4 hours to download 1000 zip files averaging 6Mb and do the unzip test. Based on this you can decide how much time you need for your jobs.


The last step, which is no included in this script, will be to copy the data onto RDM. However I think we'll maybe, possibly, probably need to manually check the fail logs prior to doing the copying ¯\\\_(ツ)\_/¯ ?!

Note that I have no failsafe for cases where Bunya itself fails and screws up jobs. You can figure out if this happened using a command like sacct -X -j \<job id\> -o "JobID,JobName,State,Start,End,Elapsed,NodeList,ReqMem,MaxRSS,ExitCode,User"

# Copy Bulk Folder Onto RDM

To copy a folder onto the rdm, you can use the directly mapped QCRISData folder and send the copy command as a job using ukb_copy_rdm.slurm. By default I request 6h, you can change this as you need (might need more for bulk items like diffusion). For reference it took me **01:43:39** to transfer about **450Gb**.
The script only takes the path to the bulk folder to copy as parameter. 

Note that you need access to <ins>/QRISdata/Q7990</ins> to be able to run the script. TO know if you have proper access, you can type **groups** and you should see something like this: Q7990RW (i.e.,   read-write permissions)

An example of command would be:

```
sbatch ukb_copy_rdm.slurm /scratch/user/${USER}/UKB/20210
```
This will just do a  **cp -r /scratch/user/${USER}/UKB/20210 /QRISdata/Q7990/bulk** command. 

# Documentation for Create_bulk_file.sh

Write more documentation when I have more time. In the meantime you can look at the script itself it is pretty intuitive. 
Note that due to the size of the tab file, I am forced to use 'gawk' rather than 'awk' so you may need to install it.

# Documentation for ExtractDemographicsUKB.sh
Write more documentation when I have more time. In the meantime you can look at the script itself it is pretty intuitive. 
Note that due to the size of the tab file, I am forced to use 'gawk' rather than 'awk' so you may need to install it.
