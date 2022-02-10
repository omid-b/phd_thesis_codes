#!/usr/env/bin

# Coded by: omid.bagherpur@gmail.com
# Update: July 20, 2021

# Code Block!

import os
import sys
import numpy as np

# os.system('clear')
if len(sys.argv) != 3:
    print("Usage: python3 mean_fan_data.py  <fan_datalist>  <out_dir>\n")
    exit()

###### FUNCTIONS ######

def read_fan_datalist(datalist):
    try:
        fopen = open(datalist, 'r')
        flines = fopen.readlines()
        fopen.close()
        fan_datalist = []
        for x in flines:
            fan_datalist.append(x.split('\n')[0])
    except Exception as e:
        print(f"Datalist read error!\n{e}\n")
        exit()
    return fan_datalist


def read_fan_data(fan_data):
    try:
        angle_bin, count, std, snr = np.loadtxt(fan_data, unpack=True, dtype=str)
    except Exception as e:
        print(f"Error! Could not read fan_data: {fan_data}\n{e}\n\n")
        exit()
    return angle_bin, count, std, snr


def mean_fan_data(fan_datalist):
    num_datalist = {}
    std_datalist = {}
    snr_datalist = {}
    for fan_data in fan_datalist:
        angle_bin, num, std, snr = read_fan_data(fan_data)
        for i in range(len(angle_bin)):
            # initialize lists
            if angle_bin[i] not in num_datalist.keys():
                num_datalist[f"{angle_bin[i]}"] = []
            if angle_bin[i] not in std_datalist.keys():
                std_datalist[f"{angle_bin[i]}"] = []
            if angle_bin[i] not in snr_datalist.keys():
                snr_datalist[f"{angle_bin[i]}"] = []
            # store data
            if num[i] != "N/A":
                num_datalist[f"{angle_bin[i]}"].append(int(num[i]))
            if std[i] != "N/A":
                std_datalist[f"{angle_bin[i]}"].append(float(std[i]))
            if snr[i] != "N/A":
                snr_datalist[f"{angle_bin[i]}"].append(float(snr[i]))
    num = []
    std = []
    snr = []
    for abin in angle_bin:
        # num
        if len(num_datalist[f"{abin}"]):
            num.append(np.sum(num_datalist[f"{abin}"]))
        else:
            num.append("N/A")
        # std
        if len(std_datalist[f"{abin}"]):
            std.append(np.mean(std_datalist[f"{abin}"]))
        else:
            std.append("N/A")
        # snr
        if len(snr_datalist[f"{abin}"]):
            snr.append(np.mean(snr_datalist[f"{abin}"]))
        else:
            snr.append("N/A")
        # check if all should be N/A
        if std[-1] == "N/A" and snr[-1] == "N/A":
            num[-1] = "N/A"
    return angle_bin, num, std, snr

#######################

# read data
fan_datalist = read_fan_datalist(sys.argv[1])
# calculate average data
angle_bin, num, std, snr = mean_fan_data(fan_datalist)

# create output directory if does not exist
if not os.path.isdir(sys.argv[2]):
    os.mkdir(sys.argv[2])

# save output file
basename = ".".join(os.path.basename(sys.argv[1]).split(".")[0:-1])
fout = os.path.join(sys.argv[2],f"mean_{basename}.dat")
fopen = open(fout, 'w')
for i in range(len(angle_bin)):
    if std[i] == "N/A":
        num[i] = "N/A"
        fopen.write("%s %3s %6s %6.2f\n" %(angle_bin[i], num[i], std[i], snr[i]) )
    else:
        fopen.write("%s %3.0f %6.2f %6.2f\n" %(angle_bin[i], num[i], std[i], snr[i]) )
fopen.close()
