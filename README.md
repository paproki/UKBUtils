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

All slurm outputs will be saved under /scratch/user/{USER}/UKB

## ukb_download_split_per_1000.slurm script usage

The ukb_download_split_per_1000.slurm will start a job array and distribute jobs accross available resources. The script takes as input the bulk file to download. Since we are splitting the files into multiple batches of 1000 (max allowed number of lines downloaded per ukbfetch script), the number of jobs is not the same per bulk file. You can identify the number of jobs using basic bash commands (e.g., wc -l < 20210.bulk ). An example of command line to start a bulk file download for bulk item 20210 would be:

```
mkdir 20210;sbatch --array=0-$((`wc -l < 20210.bulk`/1000))%10 ukb_download_split_per_1000.slurm /scratch/user/uqapapro/UKB/20210.bulk
```
Here we start by creating a folder for the bulk item. I prefer to do it before to avoid have several jobs trying to create it, which may cause trouble.

If the bulk file 20210.bulk contains 75766 lines, this command line will create a job array of size 0-75 (n=76). In this case, because I suffixed %10 to the --array=0-75%10 parameter, slurm with only run 10 jobs simultaneously. EZPZ.

The script itself will create several batch folders as follows:


```
/scratch/user/{USER}/UKB
--------------------/batch_000
--------------------/batch_000/SUBJECTID_20210_X_0.zip
--------------------/batch_000/...
--------------------/batch_000/SUBJECTID_20210_X_0.zip
--------------------/batch_000/fetched_000.lis
--------------------/batch_000/fail.log
--------------------/batch_000/corrupted_zips.log
--------------------/batch_001
--------------------/...
--------------------/batch_075
```

fail.log will contain information on the zip that were note downloaded at all (i.e., completely missing) and the last line will contain the number of 'expected fails'. For some reason some subjects are not available for download and the ukbfetch return and error with a 'code 2' which I used to count the number of expected failures which we can then compare to the number of missing zips.
An example of fail.log would be
```
1204125 20210_3_0 1204125_20210_3_0.zip
1207981 20210_3_0 1207981_20210_3_0.zip
1259527 20210_3_0 1259527_20210_3_0.zip
3
```

Finally the file corrupted_zips.log will only be create if the script detects that a zip file is malformed. For test this I go through all the zip files and try unzipping them using unzip -t XXXXXXXXXX.zip, which is a 'silent' unzipping that does not actually do the unzipping.

