##generate table summary
#path = "/fh/scratch/delete90/haffner_m/user/madil/Methylation_profiles/Cell_lines/tmp/tmp/"
#file_name = "ZMYND8.Prostate_hg19LO_10k_with_LNCaP.values.tab"
#out_name = "test.values.metrics.txt"

import pandas as pd
import numpy as np
import argparse

parser = argparse.ArgumentParser() 
parser.add_argument('--input', help='/path/', required=True) 
parser.add_argument('--out', help='Output matrix name', required=True) 
args = parser.parse_args() 

file_name = args.input
out_name = args.out

current_Matrix = pd.read_csv(file_name,skiprows=3,sep = '\t',header = None)
current_Matrix = current_Matrix.describe()

central_str_plot_columns = [*range(57,77+1,1)]
current_Matrix["mean_val"] = current_Matrix.sum(axis = 1) / (len(current_Matrix.columns) - current_Matrix.isna().sum(axis = 1))
current_Matrix["central_val"] = current_Matrix[central_str_plot_columns].sum(axis = 1) / (len(central_str_plot_columns) - current_Matrix[central_str_plot_columns].isna().sum(axis = 1))
current_Matrix["metric"] = current_Matrix.index
#current_Matrix["sample"] = file_name.split("/")[-1].split("_with_")[0]
#current_Matrix["site_name"] = file_name.split("/")[-1].split("_with_")[1].split(".sorted.values.tab")[0]
current_Matrix["sample"] = file_name.split("_with_")[0]
current_Matrix["site_name"] = file_name.split("_with_")[1].split(".sorted.values.tab")[0]

current_Matrix.to_csv(out_name, sep = '\t',header = False,index = False)
print("Done!",file_name)
