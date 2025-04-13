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

**In the case of a bulk item that is too big to fit on scratch, you will need to split the the bulk file into several bulk files to make sure the output will fit within 5Tb of scratch space. When this happens, you will have the opportunity to pass an extra parameter to the script with the beginning batch name. For example if you split your bulk file into two bulk files to be processed separately, when you start the second batch, you can pass the next batch_id, for example if the during the first half, batch_000 to batch_032 were created you would pass 33 to script when running the second half as follows:**

```
mkdir 20210;sbatch --array=0-1%2 ukb_download_split_per_1000.slurm /scratch/user/${USER}/UKB/20210.bulk 20210 33
```
Note that in this case you will need to manage a bit more carefully the copy onto rdm. Note that the **cp** command merges folders if files within the folder have different names. If they have the same name, the file from the source will overwrite the file in the target directory.

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

# Create master fail log from batch logs

To run this program you will need to be in the folder where you create the bulk folders (normally **/scratch/user/{USER}/UKB/**). You will need to copy the script **Check_output_logs.sh** there. The script takes as input the bulk ID as follows (example with bulk ID 20210):
```
bash Check_output_logs.sh 20210
```

This will create a log file in the bulk folder that concates all batch log files as follows:
```
= = = = = = = = = = = = = = = = batch_000 = = = = = = = = = = = = = = = 
     1	1079617 20210_3_0 1079617_20210_3_0.zip
     2	1133400 20210_3_0 1133400_20210_3_0.zip
     3	1141808 20210_3_0 1141808_20210_3_0.zip
     4	1301404 20210_3_0 1301404_20210_3_0.zip
     5	1328297 20210_3_0 1328297_20210_3_0.zip
     6	1348769 20210_3_0 1348769_20210_3_0.zip
     7	Expected fails (estimated): 6
No corrupted zip files found in batch_000
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 
= = = = = = = = = = = = = = = = batch_001 = = = = = = = = = = = = = = = 
     1	1649278 20210_3_0 1649278_20210_3_0.zip
     2	1680365 20210_3_0 1680365_20210_3_0.zip
     3	1710256 20210_3_0 1710256_20210_3_0.zip
     4	1735387 20210_3_0 1735387_20210_3_0.zip
     5	1814095 20210_3_0 1814095_20210_3_0.zip
     6	1953063 20210_3_0 1953063_20210_3_0.zip
     7	Expected fails (estimated): 6
No corrupted zip files found in batch_001
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 
= = = = = = = = = = = = = = = = batch_002 = = = = = = = = = = = = = = = 
...
...
```

# Retrying failed downloads on cluster vs locally

## On your local machine
If you have identified specific batches that have failed. You can use their respective fail log files to attempt to redownload the failed cases on your local machine. You need to copy the script Retry_fails.sh in your tools directory where ukbfetch and the key are located. 

It takes as argument the fail.log file that is found in the batch_XXX folder. It will download the files in the tools folder and you just need to copy the files back to your cluster folder.

```
bash Retry_fails.sh /<Path>/<to>/fail.log
```
## On the cluster
You can also just re-run a batch download on the cluster. For example if batch 22 failed. you can just run 

```
sbatch --array=22-22 ukb_download_split_per_1000.slurm /scratch/user/uqapapro/UKB/20209_1.bulk 20209

Note that if you had to split the bulk file into two or more files due to size, you will be need to specify the batch number relative to your batch start number. For example

sbatch --array=21-21 ukb_download_split_per_1000.slurm /scratch/user/uqapapro/UKB/20209_2.bulk 20209 32

Will retry the download for batch 32+21=53.
```


# Copy Bulk Folder Onto RDM

To copy a folder onto the rdm, you can use the directly mapped QCRISData folder and send the copy command as a job using ukb_copy_rdm.slurm. By default I request 6h, you can change this as you need (might need more for bulk items like diffusion). For reference it took me **01:43:39** to transfer about **450Gb**.
The script only takes the path to the bulk folder to copy as parameter. 

Note that you need access to <ins>/QRISdata/Q7990</ins> to be able to run the script. TO know if you have proper access, you can type **groups** and you should see something like this: Q7990RW (i.e.,   read-write permissions)

An example of command would be:

```
sbatch ukb_copy_rdm.slurm /scratch/user/${USER}/UKB/20210
```
This will just do a  **cp -r /scratch/user/${USER}/UKB/20210 /QRISdata/Q7990/bulk** command. 

I do recommend to have the master Fail log into the bulkID folder and possible the original bulk file for reference.

# Documentation for Create_bulk_file.sh

Write more documentation when I have more time. In the meantime you can look at the script itself it is pretty intuitive. 
Note that due to the size of the tab file, I am forced to use 'gawk' rather than 'awk' so you may need to install it.

# Documentation for ExtractDemographicsUKB.sh
Write more documentation when I have more time. In the meantime you can look at the script itself it is pretty intuitive. 
Note that due to the size of the tab file, I am forced to use 'gawk' rather than 'awk' so you may need to install it.
