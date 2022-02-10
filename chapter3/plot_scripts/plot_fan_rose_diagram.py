#!/usr/env/bin

import os 
import sys
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

figsize = (4,4)
angle_bin_size = 10


os.system("clear")
if len(sys.argv) != 4:
    print(f"Usage: python3 plot.py <az_datalist> <baz_datalist> <out_dir>\n\n")
    exit()

# datalists
datalist_az = np.loadtxt(sys.argv[1], dtype=str)
datalist_baz = np.loadtxt(sys.argv[2], dtype=str)

if len(datalist_az) != len(datalist_baz):
	print("Error! len(datalist_az) != len(datalist_baz)")
	exit()

stations = []
for i in range(len(datalist_baz)):
    sta = os.path.basename(datalist_baz[i]).split('.')[0].split('_')[1]
    stations.append(sta)

out_dir = os.path.abspath(sys.argv[3])
if not os.path.isdir(out_dir):
    os.mkdir(out_dir)


# read baz data for each station and start plotting
angle_centres = range(0,360,angle_bin_size)
for i in range(len(stations)):
    print(f" Plotting {stations[i]}")
    az_data = datalist_az[i]
    baz_data = datalist_baz[i]
    az = np.loadtxt(az_data, dtype=float)
    baz = np.loadtxt(baz_data, dtype=float)
    pdf = os.path.join(out_dir,f"{stations[i]}.pdf")

    sns.set_context("notebook")
    f = plt.figure(figsize=figsize)
    ax=plt.subplot2grid((10, 10), (0, 0), rowspan=10, colspan=10, projection='polar')
    # # plot baz
    degrees=np.array(baz)
    radians=np.array(np.deg2rad(baz))
    a1, b1=np.histogram(degrees, bins=np.arange(0-angle_bin_size/2, 360+angle_bin_size/2, angle_bin_size))
    centres=np.deg2rad(np.ediff1d(b1)//2 + b1[:-1])
    ax.set_theta_zero_location("N")
    ax.set_theta_direction(-1)
    bars=ax.bar(centres, a1, bottom=0,width=np.deg2rad(angle_bin_size),edgecolor="#0072BB", color="#1183CC")
    for bar in bars:
            bar.set_alpha(0.8)
    # plot az
    degrees=np.array(az)
    radians=np.array(np.deg2rad(az))
    a2, b2=np.histogram(degrees, bins=np.arange(0-angle_bin_size/2, 360+angle_bin_size/2, angle_bin_size))
    centres=np.deg2rad(np.ediff1d(b2)//2 + b2[:-1])
    ax.set_theta_zero_location("N")
    ax.set_theta_direction(-1)
    bars=ax.bar(centres, a2, bottom=0,width=np.deg2rad(angle_bin_size),edgecolor="#EE4B4B", color="#FF5C5C")
    for bar in bars:
            bar.set_alpha(0.7)
    ax.set_yticks([int(np.max([np.max(a1)*0.33, np.max(a2)*0.33])),\
                   int(np.max([np.max(a1)*0.66, np.max(a2)*0.66])),\
                   int(np.max([np.max(a1)*0.90, np.max(a2)*0.90]))])
    plt.tight_layout()
    plt.savefig(pdf,dpi=300, format="PDF", transparent=True)
    plt.close()

print("\n\naz: red; baz: blue\nDone!\n\n")
