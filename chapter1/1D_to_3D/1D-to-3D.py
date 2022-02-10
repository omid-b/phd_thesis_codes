#!/usr/bin/env python3
#
#====Adjustable Parameters====#
spline_order = 1 ; # 1 for linear interpolation, and 3 for cubic spline
rounding = 4   ; #value decimal rounding
depth_step = 1 ; #depth step in interpolation; 1 is recommended

#plot parameters:
plot_filetype = 'pdf'
depthTick = 20 # yaxis thick step
valTick   = 0.2 # xaxis thick step
figSize   = (3.5,6) # Size of the figure along (x, y) axis
context  = "notebook" ;# seaborn set_context: notebook, talk, poster, paper
style    = "whitegrid" ; # seaborn styles: darkgrid, whitegrid, white, ticks ...
#=============================#
about='''
  USAGE: ./1D-to-3D.py <datalist> <output folder name>

  <datalist>: Should have three columns: Lon, Lat, <profile data>
  <profile data>:  Should have at least two columns: depth, value ...

  Coded by: omid.bagherpur@gmail.com

  UPDATE: 8 April 2019
'''
#Code Block!
import os, sys
os.system('clear')
print('This script generates the XYZ data at all depths from 1D profile data using the B-Spline method.')

#check the inputs
if (len(sys.argv) != 3):
  print(about)
  exit()
#import the required libraries
try:
  import sys, csv
  import numpy as np
  import matplotlib.pyplot as plt
  import seaborn as sns
  from scipy import interpolate
  import shutil
except ImportError:
  print("Error importing required modules!\nMake sure the following modules are accessable by entering help('module name') in python shell:\n")
  print("  sys, numpy, matplotlib.pyplot, seaborn, scipy, shutil\n" )
  exit()



if (os.path.isfile(sys.argv[1]) == False):
  print(f'\nError! could not find "{sys.argv[1]}"\n')
  exit()

lon=[]
lat=[]
data=[]
with open(sys.argv[1],'r') as fn:
  for line in fn:
    lon.append(float(line.split()[0]))
    lat.append(float(line.split()[1]))
    data.append(str(line.split()[2]))


for fn in data:
  if (os.path.isfile(fn) == False):
    print(f'\nError!\n Could not find "{fn}" (check {sys.argv[1]})\n')
    exit()

nop = len(data) #number of profiles

print(f'\n  Spline order = {spline_order}\n  Number of profiles= {nop}\n  Study region:')
print(f'  Longitude: [{np.min(lon)}, {np.max(lon)}],    Latitude: [{np.min(lat)}, {np.max(lat)}]')
print(f"  Output folder: '{sys.argv[2]}'")

uans = input('\nDo you want to continue (y/n)? ')

if (uans != 'y'):
  print('\nExit program!\n')
  exit()
else:
  print(' ')
  if os.path.isdir(sys.argv[2]):
    shutil.rmtree(sys.argv[2])


os.mkdir(sys.argv[2])
minDepth = []
maxDepth = []
interpolated = []

i=0
for profile in data:
  x = '%.2f' % lon[i]
  y = '%.2f' % lat[i]
  i+=1
  fname = f'X{x}Y{y}'
  depth, value = np.loadtxt(profile, unpack=True, dtype='float')
  depth_interp = np.arange(int(depth[0]),int(depth[-1])+depth_step, depth_step)
  tck = interpolate.splrep(depth, value, s=0, k=spline_order)
  value_interp = interpolate.splev(depth_interp, tck, der=0)
  minDepth.append(int(depth[0]))
  maxDepth.append(int(depth[-1]))
  interpolated.append(os.path.join(sys.argv[2], fname+'.dat'))
  out1= open(os.path.join(sys.argv[2], fname+'.dat'), 'w')
  figout= f'{sys.argv[2]}/{fname}.{plot_filetype}'
  for item in range(len(depth_interp)):
    out1.write(f'%4s %.4f\n' % (depth_interp[item], round(value_interp[item], rounding)) )
  
  sns.set(style=style)
  sns.set_context(context)
  plt.figure(i,figSize)
  plt.plot(value, depth,'o', label='Input model')
  plt.plot(value_interp, depth_interp, 'r:', label=f'Interpolated model\n  (Spline order={spline_order})')
  plt.xticks(np.arange(-100, 100, valTick))
  plt.yticks(range(0, 6000, depthTick))
  plt.ylim((0, np.max(depth)+10))
  plt.xlim((np.min(value)-0.1,np.max(value)+0.1))
  plt.ylabel('Depth')
  plt.xlabel('Value')
  plt.gca().invert_yaxis()
  plt.legend(loc='best')
  plt.tight_layout()
  plt.savefig(figout,dpi=300,transparent=True)
  out1.close()
  plt.close()
  print("  Interpolation progress    {:2.0%}".format(i / nop), end="\r")

minDepth = np.max(minDepth)
maxDepth = np.min(maxDepth)

print(f" ")

nDepth = len(range(minDepth, maxDepth+depth_step, depth_step))

i=0
for map_depth in range(minDepth, maxDepth+depth_step, depth_step):
  i+=1
  map_depth0 = '%03d' % map_depth
  out2= open(os.path.join(sys.argv[2],f'Depth_{map_depth0}km.dat'), 'a')
  for fn in interpolated:
    x = fn.split('/')[-1].split('X')[1].split('Y')[0]
    y = fn.split('/')[-1].split('Y')[1].split('.dat')[0]
    with open(fn) as file:
      for line in file.readlines():
        if int(line.split()[0]) == int(map_depth):
          out2.write(f'{x} {y} {line.split()[1]}\n')
    print("  Making map data progress  {:2.0%}".format(i / nDepth), end="\r")

print(f"\n\nFinished.\n")

