### Interacting with UKB-RAP Tab data

This page explains how to access the UKB tab data from your terminal at no cost. You can then extract the fields you need for your study for local analysis. 

## Step one: On ukb-rap

After creating an account and linking it with your AMS account, you can create a project and link it with the application ID that you find in your AMS Projects. You will then need to dispense the data (you can dispense just the tabular data if you need). This will create a dataset and a database in your project folder. 

After that you need to create an API-Token, you can do so in:

```
settings>accountSecurity>API Tokens>+New Token
```

Make sure you save your token as you will only see it once. To avoid issue I'd suggest create an environment variable in your bashrc or whatever the MacOS equivalent is, for example:

```
export UKB_TOKEN="yyYXXXXXXAAAZZZZEEeeddAAA"
```

## Step two: install and use DNA-nexus toolkit

To install both the command line interface and the python package, you can simply use the command below (I'd recommend doing it in a conda environment).

Source https://github.com/dnanexus/dx-toolkit

```
pip install dxpy
```

Note that if you install it in a conda environment, you will need to activate the environment to be able to use the CLI tool dx. 

Once install you can link the CLI tool with your ukb-rap as follows (provided you setup the environment variable with your token).

```
dx login --token $UKB_TOKEN
```

After that you can find your project ID using 

```
dx find projects
Example output:
project-CccDDIOOnlkjnwnelf : <project name> (ADMINISTER)
```

And you can select your project using the project ID returned and list the records available:

```
dx select project-CccDDIOOnlkjnwnelf
dx ls -l
```

For me it returned something like this:

```
Bulk/
Showcase metadata/
State   Last modified       Size      Name (ID)
closed  2025-03-27 09:34:48           appXXXXXX_DATEANDTIMEXXX (database-kkLLjdiOIoIASDOIawdoiad)
closed  2025-03-27 09:35:04           appXXXXXX_DATEANDTIMEXXX.dataset (record-liAWLIDljawdjlawdLAWLJKND)
```

You now have all the information you need. We can use the **project-ID** and the **record-liAWLIDljawdjlawdLAWLJKND** associated with the **appXXXXXX_DATEANDTIMEXXX.dataset** file. Here are a bunch of useful commands to retrieve data:

To list the available fields you can run the following command:
```
dx extract_dataset record-liAWLIDljawdjlawdLAWLJKND --list-fields

if you have selected the project

or 

dx extract_dataset project-CccDDIOOnlkjnwnelf:record-liAWLIDljawdjlawdLAWLJKND --list-fields

if you have not selected the project
```

The commands takes a while (obv due to the size of ukbiobank) and will output the fields organised by alphabetical order:

```
...
participant.p31	Sex
participant.p31000_i2	MNI Native Transform | Instance 2
participant.p31000_i3	MNI Native Transform | Instance 3
participant.p31001_i2	Native aparc a2009s dMRI | Instance 2
participant.p31001_i3	Native aparc a2009s dMRI | Instance 3
participant.p31002_i2	Native aparc dMRI | Instance 2
participant.p31002_i3	Native aparc dMRI | Instance 3
participant.p31003_i2	Native Glasser dMRI | Instance 2
participant.p31003_i3	Native Glasser dMRI | Instance 3
participant.p31004_i2	Native Schaefer7n200p dMRI | Instance 2
participant.p31004_i3	Native Schaefer7n200p dMRI | Instance 3
participant.p31005_i2	Native Schaefer7n500p dMRI | Instance 2
participant.p31005_i3	Native Schaefer7n500p dMRI | Instance 3
participant.p31006_i2	Native Tian Subcortex S1 3T dMRI | Instance 2
participant.p31006_i3	Native Tian Subcortex S1 3T dMRI | Instance 3
participant.p31007_i2	Native Tian Subcortex S4 3T dMRI | Instance 2
...
```

I'd recommend saving the output to a text file for later use:

```
dx extract_dataset record-liAWLIDljawdjlawdLAWLJKND --list-fields > <path>/ukb-fields.txt
```

Now if you want to extract the fields you want and save them to a file (in this case i extract the data for bulk item 20218 and save them to participants_20218.json), you can use the following command:

```
dx extract_dataset record-liAWLIDljawdjlawdLAWLJKND --fields participant.eid,participant.p20218_i2,participant.p20218_i3 --output participants_20218b.json
```

The commands take a while and extracts the fields for ALL participants, so it will look something like this:

```
participant.eid,participant.p20218_i2,participant.p20218_i3
.....
6019148,,
6019177,,
6019414,6019414_20218_2_0.zip,
6019465,6019465_20218_2_0.zip,6019465_20218_3_0.zip
6019589,,
6019679,,
6019787,,
6019849,6019849_20218_2_0.zip,
6019905,,
6019919,,
6019978,,
.....
```

## Step three: post-process output file

If you want to used this to create a bulk file for download, you will need to filter out and reformat the output. The script Filter_dx_output.sh in this folder does just that (only works for 3 columns).

For example:

```
bash Filter_dx_output.sh --input participants_20218b.json --output 20218.bulk
```

Will create a file like this:
```
...
6015541 20218_2_0
6015828 20218_2_0
6015828 20218_3_0
6019414 20218_2_0
6019465 20218_2_0
6019465 20218_3_0
6019849 20218_2_0
6020070 20218_2_0
6020785 20218_2_0
6021386 20218_2_0
6021601 20218_2_0
...
```

