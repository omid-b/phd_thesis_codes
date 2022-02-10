#!/usr/bin/env python3
''' 
This script is to plot the results of the SURF96 modelling. 

The input files include 4 files: 2 dispersion data (e.g. input.disp and output.disp) and 2 model data (e.g. start-model.modl and output-model.modl)

'''
#=======Adjustable Parameters=======#
output_filetype = 'pdf'
profile= 'vs' ; #options: 'vs', 'vp', 'rho', 'qp', 'qs'
depRange= (0, 410) #vertical axis limits (profile)
velRange=(3.4, 5.1) #horizontal axis limits (profile)
depTick= 20
velTick   = 0.25
legSize  = 11 #legend font size
figSize  = (12,8) # Size of the figure along (x, y) axis
context  = "notebook" ; # seaborn set_context: notebook, talk, poster, paper
style    = "whitegrid" ; # seaborn styles: darkgrid, whitegrid, white, ticks ... 
#===================================#
about='''
USAGE: ./plot-surf96.py  <input.disp> <output.disp> <startMod.mod> <outputMod.mod>

  Coded by omid.bagherpur@gmail.com

  Update: 12 March 2019
'''

import os
os.system('clear')
print('This script is to plot the results of the SURF96 modelling.')

#import required modules
try:
  import sys
  import itertools
  import numpy as np
  import matplotlib.pyplot as plt
  from matplotlib import gridspec
  import seaborn as sns
except ImportError:
  print("Error importing required modules!\nMake sure the following modules are accessable by entering help('module name') in python shell:\n")
  print("  sys, numpy, matplotlib, seaborn, itertools\n" )
  exit()


#check the inputs
if (len(sys.argv) != 5):
	print(about)
	exit()

if (os.path.isfile(sys.argv[1]) == False):
  print(f'\nError! could not find "{sys.argv[1]}"\n')
  exit()
elif (os.path.isfile(sys.argv[2]) == False):
  print(f'\nError! could not find "{sys.argv[2]}"\n')
  exit()
elif (os.path.isfile(sys.argv[3]) == False):
  print(f'\nError! could not find "{sys.argv[3]}"\n')
  exit()
elif (os.path.isfile(sys.argv[4]) == False):
  print(f'\nError! could not find "{sys.argv[4]}"\n')
  exit()

nol=[0]
for i in range(1,len(sys.argv) ):
	c=0
	for line in open(sys.argv[i]):
	  c+=1
	nol.append(c)

if (nol[1] != nol[2]):
	print(f'\nError! Number of lines in "{sys.argv[1]}" and "{sys.argv[2]}" do not match ({nol[1]}!={nol[2]}).\n')
	exit()
elif (nol[3] != nol[4]):
	print(f'\nError! Number of lines in "{sys.argv[3]}" and "{sys.argv[4]}" do not match ({nol[3]}!={nol[4]}).\n')
	exit()

#reading data:
#1) read dispersion data:
period=[]
inp_phvel=[]
inp_phvel_err=[]
out_phvel=[]
for line in open(sys.argv[1],'r'):
	period.append( float(line.split()[5]) )
	inp_phvel.append( float(line.split()[6]))
	inp_phvel_err.append( float(line.split()[7])/2)

for line in open(sys.argv[2],'r'):
	out_phvel.append( float(line.split()[6]))

#1) read model data:
beginLine=12 #zero based
h_col=0; vp_col=1; vs_col=2; rho_col=3; qp_col=4; qs_col=5;

startMod_h=[]; startMod_vp=[]; startMod_vs=[];
startMod_rho=[]; startMod_qp=[]; startMod_qs=[];
outMod_h=[]; outMod_vp=[]; outMod_vs=[];
outMod_rho=[]; outMod_qp=[]; outMod_qs=[];
depth=[0]

with open(sys.argv[3],'r') as startMod:
	i=0;
	for line in itertools.islice(startMod, beginLine, nol[3]):
		depth.append( depth[i]+float(line.split()[h_col]) )
		startMod_h.append( float(line.split()[h_col]) )
		startMod_vp.append( float(line.split()[vp_col]) )
		startMod_vs.append( float(line.split()[vs_col]) )
		startMod_rho.append( float(line.split()[rho_col]) )
		startMod_qp.append( float(line.split()[qp_col]) )
		startMod_qs.append( float(line.split()[qs_col]) )
		i+=1

with open(sys.argv[4],'r') as outMod:
	for line in itertools.islice(outMod, beginLine, nol[4]):
		outMod_h.append( float(line.split()[h_col]) )
		outMod_vp.append( float(line.split()[vp_col]) )
		outMod_vs.append( float(line.split()[vs_col]) )
		outMod_rho.append( float(line.split()[rho_col]) )
		outMod_qp.append( float(line.split()[qp_col]) )
		outMod_qs.append( float(line.split()[qs_col]) )


#make layered models:
nlayer=nol[3]-beginLine

for i in range(1,nlayer):
	depth.insert(2*i-1, depth[2*i-2])
	startMod_vp.insert(2*i-1, startMod_vp[2*i-2])
	startMod_vs.insert(2*i-1, startMod_vs[2*i-2])
	startMod_rho.insert(2*i-1, startMod_rho[2*i-2])
	startMod_qp.insert(2*i-1, startMod_qp[2*i-2])
	startMod_qs.insert(2*i-1, startMod_qs[2*i-2])
	outMod_vp.insert(2*i-1, outMod_vp[2*i-2])
	outMod_vs.insert(2*i-1, outMod_vs[2*i-2])
	outMod_rho.insert(2*i-1, outMod_rho[2*i-2])
	outMod_qp.insert(2*i-1, outMod_qp[2*i-2])
	outMod_qs.insert(2*i-1, outMod_qs[2*i-2])

del depth[0]

#plotting
sns.set(style=style)
sns.set_context(context)
plt.figure(1,figSize)
gs = gridspec.GridSpec(1, 2, width_ratios=[0.45, 1]) 

ax1 = plt.subplot(gs[0])

if (profile.lower() == 'vp'):
  plt.plot(startMod_vp, depth,label='Starting model');
  plt.plot(outMod_vp, depth,label='Inversion results');
  plt.xlabel('$V_{pv}$ (km/s)')
elif (profile.lower() == 'rho'):
  plt.plot(startMod_rho, depth,label='Starting model');
  plt.plot(outMod_rho, depth,label='Inversion results');
  plt.xlabel('Rho ($grams/cm^3$)')
elif (profile.lower() == 'qp'):
  plt.plot(startMod_qp, depth,label='Starting model');
  plt.plot(outMod_qp, depth,label='Inversion results');
  plt.xlabel('$Q_p$')
elif (profile.lower() == 'qs'):
  plt.plot(startMod_qs, depth,label='Starting model');
  plt.plot(outMod_qs, depth,label='Inversion results');
  plt.xlabel('$Q_s$')
else:
  plt.plot(startMod_vs, depth,label='Starting model');
  plt.plot(outMod_vs, depth,label='Inversion results');
  plt.xlabel('$V_{sv}$  (km/s)')

plt.yticks(range(0, 6000, depTick))
plt.xticks(np.arange(0, 15, velTick))
plt.ylim(depRange)
plt.xlim((velRange))
plt.gca().invert_yaxis();

plt.ylabel('Depth (km)')
plt.legend(loc='lower left', prop={'size':legSize})

ax2 = plt.subplot(gs[1])
plt.errorbar(period, inp_phvel, yerr=inp_phvel_err, fmt='--o', label='Observed');
plt.plot(period, out_phvel,label='Synthetic');
plt.xlabel('Period (s)')
plt.ylabel('Phase velocity (km/s)')
plt.yticks(np.arange(2,10,0.1))
plt.legend(loc='upper left', prop={'size':legSize})

plt.ylim((np.min(inp_phvel)-0.1,np.max(inp_phvel)+0.15))
#plt.ylim((3.5, 5))

plt.tight_layout()
figout = f'surf96_{sys.argv[1]}.{output_filetype}'
plt.savefig(figout,dpi=300,transparent=True)
print(f"\n{figout} is created!\n")
#plt.show()


