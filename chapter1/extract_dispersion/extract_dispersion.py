#!/usr/bin/env python3
# Coded by: omid.bagherpur@gmail.com
# Run the script to see the usage!
import sys, os
os.system('clear')
print('This script extracts the dispersion curve data at all nodes\n')
about = f'''
 USAGE: {sys.argv[0]} <datalist> <output folder>
 <datalist> columns: 1)period, 2)phase velocity data file (xyz format)
'''
if len(sys.argv) !=3:
  print(' Error!\n',about)
  exit()

try:
  import shutil
except ImportError:
  print('Error in importing required modules!\n\nCheck the followings modules:')
  print('  shutil\n')
  exit()


if os.path.isdir(sys.argv[2]):
    shutil.rmtree(sys.argv[2])
    os.mkdir(sys.argv[2])
else:
    os.mkdir(sys.argv[2])


periods=[]
datalist=[]
for line in open(sys.argv[1],mode='r'):
  periods.append(line.split()[0])
  datalist.append(line.split()[1])
  if os.path.isfile(datalist[-1]) == False:
    print(f'Error!\n Could not find {data[-1]}\n')
    exit()


i=-1
for data in datalist:
  i+=1
  period= periods[i]
  for line in open(data,mode='r'):
    ncol = len(line)
    x = line.split()[0]
    y = line.split()[1]
    val = line.split()[2]
    fname = '%s/X%.4fY%.4f.disp' %(sys.argv[2],float(x),float(y))
    fopen = open(fname,mode='a')
    if ncol == 3:
      outputLine = '%s %s\n' % (period,val)
    else:
      val2 = line.split()[3]
      outputLine = '%s %s %s\n' % (period,val,val2)
    fopen.write(outputLine)
    fopen.close()
    print("  Program progress:    {:2.0%}".format(i / len(periods)), end="\r")
  
print("  Program progress:    100%  \n")