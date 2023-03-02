##split merged values tab files into individual files
##Python/3.9.6-GCCcore-11.2.0
import pandas as pd
import argparse

parser = argparse.ArgumentParser() 
parser.add_argument('--values_file', help='/path/to/values.tab', required=True) 
#parser.add_argument('--out_dir', help='/path/to/out_dir/', required=True)
args = parser.parse_args() 

file_path = args.values_file
#out_folder = args.out_dir

values_file = pd.read_csv(file_path,sep = '\t',skiprows = 3,header = None)#nrows
values_lines = pd.read_csv(file_path,sep = '\t',nrows = 1,header = None)#nrows
sample_name = file_path.split("/")[-1]
values_lines = values_lines.T
values_lines[['TF','len']] = values_lines[0].str.split(':',expand=True)
values_lines["TF"] = values_lines["TF"].replace("#", "", regex=True)
values_lines['len'] = values_lines['len'].astype(int)

central_str_plot_columns = [*range(57,77+1,1)]

##maybe parallize 
values_lines_list = values_lines[['TF','len']].values.tolist()
Start = 0
for each_bed in values_lines_list:
    print(each_bed[0],"done")
    To = Start + each_bed[1]
    current = values_file.iloc[Start:To,:]
    Start = Start + each_bed[1]
    #current.to_csv(out_folder + each_bed[0].replace(".sorted.bed","")+ "_with_" + sample_name,sep = '\t',header = False,index = False)
    current = current.describe()
    current["mean_val"] = current.sum(axis = 1) / (len(current.columns) - current.isna().sum(axis = 1))
    current["central_val"] = current[central_str_plot_columns].sum(axis = 1) / (len(central_str_plot_columns) - current[central_str_plot_columns].isna().sum(axis = 1))
    current["metric"] = current.index
    current["site_name"] = each_bed[0].replace(".sorted.bed","")
    current["sample"] = sample_name
    #current.to_csv(out_folder + each_bed[0].replace(".sorted.bed","")+ "_with_" + sample_name.replace(".values.tab","") + ".values.summary.txt", sep = '\t',header = False,index = False) 
    current.to_csv(each_bed[0].replace(".sorted.bed","")+ "_with_" + sample_name.replace(".values.tab","") + ".values.summary.txt", sep = '\t',header = False,index = False) 
print("Complete!")
