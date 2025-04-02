#!/usr/bin/env python

import pandas as pd

# List of input files
files = ["ukbdata1.csv", "ukbdata2.csv"]
output_file = "combined.csv"

# Read each file into a DataFrame
dfs = [pd.read_csv(file) for file in files]

# Merge horizontally on 'participant.eid'
combined_df = dfs[0]  # Start with the first file
for df in dfs[1:]:
    combined_df = combined_df.merge(df, on="participant.eid", how="outer")
    #combined_df = combined_df.merge(df, how="outer")

# Write to output file
combined_df.to_csv(output_file, index=False)