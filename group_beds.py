##group_beds.py
##Python/3.9.6-GCCcore-11.2.0
import argparse
import json
import numpy as np

parser = argparse.ArgumentParser() 
parser.add_argument('--Sites', help='/path/to/Sites.json', required=True) 
parser.add_argument('--Group_n', help='Num of beds to group together', required=True)
args = parser.parse_args() 

Sites_file = args.Sites
Group_n = args.Group_n

f = open(Sites_file)
data = json.load(f)

##split list of input beds into groups
if Group_n > 0 and len(data['reach.bedFiles']) > 0:
    Site_list = data['reach.bedFiles']
    Site_list = np.array_split(Site_list,Group_n)
else:
    Site_list = data['reach.bedFiles']
    
##make dict with group ID
def convert(lst):
    return ' '.join(lst)

Group_dict = {}
for each_group in range(1,Group_n+1,1):
    n = each_group - 1
    a1 = convert(Site_list[n])
    Paths = a1.lstrip('\"')
    Group_dict["Group_" + str(each_group)] = Paths

##nest dict
Group_dict_nest = {}
Group_dict_nest["reach.Group_beds"] = Group_dict

##save dict as json
with open("Group.json", "w") as outfile:
    json.dump(Group_dict_nest, outfile)
    
print("Done!")