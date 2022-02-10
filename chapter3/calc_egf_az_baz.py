#!/usr/env/bin
about = "This script calculates BAZ coverage of stations for EGF dataset."
usage = "Usage: python calc_egf_az_baz.py <egf_dir> <out_dir>"
# Coded by omid.bagherpur@gmail.com
# Update: July 19, 2021
#====Adjustable Parameters=====#
sacfile_regex = 'sac$'  # regular expression for sac files
#==============================#
# Code Block!
import os
import sys
os.system('clear')
print(f"{about}\n")

# import required modules
try:
    import re
    import obspy
    import numpy as np
except ImportError as ie:
    print(f"{ie}\n")
    exit()

# check usage
if len(sys.argv) != 3:
    print(f"Usage Error!\n{usage}\n")
    exit()
else:
    egf_dir = os.path.abspath(sys.argv[1])
    out_dir = os.path.abspath(sys.argv[2])

if not os.path.isdir(egf_dir):
    print(f"Error! Could not find the <egf_dir>!\n\n{usage}\n")
    exit()


###### CLASSES & FUNCTIONS ######

def get_egf_list(egf_dir):
    egf_list = []
    for x in os.listdir(egf_dir):
        if re.search(sacfile_regex,x):
            egf_list.append(os.path.join(egf_dir,x))
    return sorted(egf_list)


def get_sta_pairs(egf_list):
    sta_pairs = []
    for x in egf_list:
        try:
            sta1 = os.path.basename(x).split('_')[0]
            sta2 = os.path.basename(x).split('_')[1]
        except Exception as e:
            print(f"EGF filename format error!\n{e}\n")
            exit()
        sta_pairs.append([sta1, sta2])
    return sta_pairs


def get_sta_uniq(egf_list):
    sta_uniq = []
    for x in egf_list:
        try:
            sta1 = os.path.basename(x).split('_')[0]
            if sta1 not in sta_uniq:
                sta_uniq.append(sta1)
            sta2 = os.path.basename(x).split('_')[1]
            if sta2 not in sta_uniq:
                sta_uniq.append(sta2)
        except Exception as e:
            print(f"EGF filename format error!\n{e}\n")
            exit()
    return sorted(sta_uniq)


def get_sac_headers(egf):
    st = obspy.read(egf,format="SAC")
    sac_headers = st[0].stats.sac
    return sac_headers

#################################

egf_list = get_egf_list(egf_dir)
if not len(egf_list):
    print(f"Error! Could not find any EGF in the given directory!\n{usage}\n")
    exit()

sta_pairs = get_sta_pairs(egf_list)
sta_uniq = get_sta_uniq(egf_list)

sta_lon = {}
sta_lat = {}
sta_az = {}
sta_baz = {}
sta_net = {}
# initialize dictionaries for baz coverage
for i in range(len(sta_uniq)):
    sta_az[f"{sta_uniq[i]}"] = []
    sta_baz[f"{sta_uniq[i]}"] = []

print(" Reading EGF dataset ...")
for i in range(len(egf_list)):
    headers = get_sac_headers(egf_list[i])
    sta1 = sta_pairs[i][0]
    sta2 = sta_pairs[i][1]
    net1 = headers['knetwk'].split('-')[0]
    net2 = headers['knetwk'].split('-')[1]
    sta1_lon = float(headers['evlo'])
    sta1_lat = float(headers['evla'])
    sta2_lon = float(headers['stlo'])
    sta2_lat = float(headers['stla'])
    az = float(headers['az'])
    baz = float(headers['baz'])
    # store into dictionaries
    sta_net[f"{sta1}"] = net1
    sta_net[f"{sta2}"] = net2
    sta_lon[f"{sta1}"] = sta1_lon
    sta_lon[f"{sta2}"] = sta2_lon
    sta_lat[f"{sta1}"] = sta1_lat
    sta_lat[f"{sta2}"] = sta2_lat
    sta_az[f"{sta2}"].append(az)
    sta_az[f"{sta1}"].append(baz)
    sta_baz[f"{sta2}"].append(baz)
    sta_baz[f"{sta1}"].append(az)

# generate outputs
print(" Generating outputs ...")
if not os.path.isdir(out_dir):
    os.mkdir(out_dir)

fopen_xy = open(os.path.join(out_dir,"stations.xy"),'w')
for sta in sta_uniq:
    fopen_xy.write("%2s %4s %.4f %.4f\n" %(sta_net[sta], sta, sta_lon[sta], sta_lat[sta]))
    fopen_az = open(os.path.join(out_dir,f"az_{sta}.dat"),'w')
    fopen_baz = open(os.path.join(out_dir,f"baz_{sta}.dat"),'w')
    for az in sta_az[sta]:
        fopen_az.write("%f\n" %(az))
    for baz in sta_baz[sta]:
        fopen_baz.write("%f\n" %(baz))
    fopen_az.close()
    fopen_baz.close()
fopen_xy.close()

print(f"\nDone!\n")
