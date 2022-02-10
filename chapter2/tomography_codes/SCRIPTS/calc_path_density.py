#!/usr/bin/env python3
import os
import sys
about = "This script calculates path density for inversion nodes (Lebedev's tomography code) by counting the number of interception of inversion paths into a circle (with 'radius_size' km) around the nodes."

usage = """
USAGE:
python3 calc_path_density.py  <invset_dir>
"""
# Coded by: omid.bagherpur@gmail.com
# Update: April 14, 2021
#=========Adjustable Parameters=========#
radius_size = 50 # in km
gcpoint_interval = 5
#=======================================#
# Code Block!
os.system('clear')
print(f"{about}\n")

try:
    import re
    from math import pi
    import numpy as np
    import shutil
    from geographiclib.geodesic import Geodesic # pip install geographiclib
except ImportError as ie:
    print(f'{ie}')
    exit()


if len(sys.argv) != 2:
    print(f"{usage}\n\n")
    exit()

if os.path.isdir(sys.argv[1]):
    invset = os.path.abspath(sys.argv[1])
else:
    print(f"Error! Could not find 'invset_dir'!\n{usage}\n")
    exit()


periods = []
for x in os.listdir(invset):
    if re.search("^[0-9][0-9][0-9]$",x):
        periods.append(x)
if len(periods) == 0:
    print(f"Error! Did not find any period directory ([0-9][0-9][0-9]) in the given 'invset_dir'!\n{usage}\n\n")
    exit()

outdir = os.path.join(invset,f"nodes_path_density_{radius_size}km")
print(f"  Output directory: {outdir}\n  Radius size: {radius_size}\n")


#----FUNCTIONS----#


def read_paths(pathsFile):
    fopen = open(pathsFile, 'r')
    flines = fopen.readlines()
    fopen.close()
    p1 = []
    p2 = []
    i = 0
    while i <= len(flines):
        if i%3 == 1:
            p1.append(flines[i].split('\n')[0].split())
        if i%3 == 2:
            p2.append(flines[i].split('\n')[0].split())
        i += 1
    paths = [] # [[x1,y1,x2,y2],...]
    for k in range(len(p1)):
        paths.append([float(p1[k][0]),float(p1[k][1]),float(p2[k][0]),float(p2[k][1])])
    return paths


def read_nodes(shellFile):
    fopen = open(shellFile,'r')
    flines = fopen.readlines()
    fopen.close()
    lats = flines[1].split('\n')[0].split()
    lons = flines[2].split('\n')[0].split()
    nodes = []
    for i in range(len(lats)):
        lat = np.around(float(lats[i])*180/pi, 4)
        lon = np.around(float(lons[i])*180/pi, 4)
        if lon > 180:
            lon += -360
        nodes.append([lon,lat])
    return nodes


def calc_endPoint(startPoint, azimuth, dist):
    """
    This function calculates the end point given the starting point,
    azimuth, and distance to the end point.

    startPoint: starting point location [lon, lat]
    azimuth: in degrees (0-360)
    dist: distance along given azimuth (km)
    """
    endPoint = Geodesic.WGS84.Direct(startPoint[1],startPoint[0],azimuth,dist*1000)
    return [endPoint['lon2'], endPoint['lat2']]


def calc_dist(startPoint, endPoint):
    """
    This function calculates distance between two points in km

    startPoint: [lon, lat]
    endPoint: [lon, lat]
    """
    dist = Geodesic.WGS84.Inverse(startPoint[1],startPoint[0],endPoint[1],endPoint[0])['s12']/1000
    return dist


def calc_azim(startPoint, endPoint):
    """
    This function calculates forward azimuth between two points in degrees

    startPoint: [lon, lat]
    endPoint: [lon, lat]
    """
    azim = Geodesic.WGS84.Inverse(startPoint[1],startPoint[0],endPoint[1],endPoint[0])['azi1']
    return azim


def gen_gcpoints(startPoint, endPoint, gcpoint_interval):
    """
    This function calculates points, seperated by
    "gcpoint_interval" (km) along the given path.
    
    nop: number of points along the path
    """
    path_dist = calc_dist(startPoint, endPoint)
    path_azim = calc_azim(startPoint, endPoint)
    nop = int(path_dist/gcpoint_interval) +1
    points = [startPoint]
    for i in range(1, nop+1):
        points.append(calc_endPoint(startPoint, path_azim, gcpoint_interval*i))
    return points



def is_in_radius(gcpoints, node, radius_size):
    """
    This function checks if gcpath points ever get close to a given node location

    gcpoints: generated using 
    node: [lon, lat]
    """
    # trick to make the calculation faster
    d1 = calc_dist(gcpoints[0], node)
    d2 = calc_dist(gcpoints[-1], node)
    if d2 < d1:
        gcpoints = gcpoints[::-1]
    for gcp in gcpoints:
        dist = calc_dist(gcp, node)
        if dist <= radius_size:
            return True
    return False

#-----------------#

# generate output directory
if os.path.isdir(outdir):
    shutil.rmtree(outdir)
os.mkdir(outdir)


# main calculations
nodes = {}
node_path_density = {}
for period in periods:
    print(f"\n")
    paths = read_paths(os.path.join(invset,period,'paths'))
    nodes[period] = read_nodes(os.path.join(invset,period,'shell'))
    node_path_density[period] = []
    inod = 0
    nodes_azimuths = os.path.join(outdir,f"nodes_azim_P{period}")
    os.mkdir(nodes_azimuths)
    for node in nodes[period]:
        inod += 1
        print(f"  Period: {period} s; Node: {inod} of {len(nodes[period])}")
        count = 0
        azim = []
        ipath = 0
        fopen = open(os.path.join(nodes_azimuths,f"node_{inod}"),'w')
        fopen.write(f"%.4f %.4f\n" %(nodes[period][inod-1][0], nodes[period][inod-1][1]))
        for path in paths:
            ipath += 1
            #print(f"  Period: {period} s ({len(nodes[period])} nodes), node: {inod}, path density: {count}; Progress: %3.0f%s" %((ipath/len(paths))*100,'%'), end=f"       \r")
            gcpoints = gen_gcpoints([path[0],path[1]], [path[2],path[3]], gcpoint_interval)
 
            if is_in_radius(gcpoints, node, radius_size):
                count += 1
                fopen.write("%.1f\n" %(calc_azim([path[0],path[1]], [path[2],path[3]])) )
                # print(f"  Period: {period} s ({len(nodes[period])} nodes), node: {inod}, path density: {count}; Progress: %3.2f%s" %((ipath/len(paths))*100,'%'), end=f"       \r")
        node_path_density[period].append(count)
        fopen.close()
     
    # write path density to output
    fopen = open(os.path.join(outdir,f"{period}.dat"), 'w')
    for inod in range(len(nodes[period])):
        txt = "%.4f %.4f %d\n" %(nodes[period][inod][0], nodes[period][inod][1], node_path_density[period][inod])
        fopen.write(txt)
    fopen.close()


print("\nDone!\n\n")

