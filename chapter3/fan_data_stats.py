#!/usr/bin/env python3

import os
import sys
import numpy as np

os.system('clear')

if len(sys.argv) != 2:
	print(f"Usage: python3 fan_data_stats.py <fan_data>\n\n")
	exit()

#---FUNCTIONS---#

def read_fan_data(fan_data):
    try:
        angle_bin, count, std, snr = np.loadtxt(fan_data, unpack=True, dtype=str)
    except Exception as e:
        print(f"Error! Could not read fan_data: {fan_data}\n{e}\n\n")
        exit()
    return angle_bin, count, std, np.array(snr,dtype=float)

#---------------#

angle_bin, count, std, snr = read_fan_data(sys.argv[1])

print(f" Fan data: {os.path.abspath(sys.argv[1])}\n")

print(f" Mean: {np.nanmean(snr)}")
print(f" STD: {np.nanstd(snr)}")

