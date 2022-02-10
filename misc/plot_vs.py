#!python3
#This is a python3 script to plot multiple (or one) shear wave velocity profiles on a same plot.
#Data files should have two columns: Depth, Vsv
#UPDATE: 21 Feb 2019, Omid.bagherpur
#========Adjustable Parameters=======#
#Data parameters:

data  = [ # an array that contains the location of data files and legend titles
  ['./data/EstCA_avg/mean.vs'   , 'MC (old)'],
  ['./data/MC_EstCA1D_minErr0.0025.vs'   , 'MC (minErr=0.0025)'],
  ['./data/MC_EstCA1D_minErr0.0050.vs'   , 'MC (minErr=0.0050)'],
  ['./data/MC_EstCA1D_minErr0.0100.vs'   , 'MC (minErr=0.0100)'],
  ['./data/MC_EstCA1D_minErr0.0200.vs'   , 'MC (minErr=0.0200)'],
  ['./data/MC_EstCA1D_minErr0.0500.vs'   , 'MC (minErr=0.0500)'],
  ['./data/MC_EstCA1D_minErr0.1000.vs'   , 'MC (minErr=0.1000)'],
  #['./data/MC_EstCA1D_minErr0.1500.vs'   , 'MC (minErr=0.1500)'],
  ['./data/MC_EstCA1D_minErr0.2000.vs'   , 'MC (minErr=0.2000)'],
  #['./data/MC_EstCA1D_minErr0.2500.vs'   , 'MC (minErr=0.2500)'],
  ['./data/MC_EstCA1D_minErr0.3000.vs'   , 'MC (minErr=0.3000)'],
  #['./data/err1.disp'   , 'Err1'],
  #['./data/err2.disp'   , 'Err2'],
  #['./data/stmodel-ak135.vs'   , 'stmodel (AK135)'],
  ['./data/d0.2dc10.0.vs'   , 'saito (dmp=0.2,10.0)'],#(dmp= 0.2,10.0)

]

#Figure style:
title   = ''; #Figure title
xlabel  = 'Vsv (km/s)'; # Figure X axes label
ylabel  = 'Depth (km)'; # Figure Y axes label
legend  = 'lower left'; # Options: 'best' ,'upper left', 'upper right', 'lower left', 'lower right'
figSize = (4,8) # Size of the figure along (x, y) axis-> 100x pixel by 100y pixel
context = "notebook" ;# seaborn set_context: notebook, talk, poster, paper
style   = "whitegrid" ; # seaborn styles: darkgrid, whitegrid, white, ticks ...
#====================================#
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

sns.set(style=style)
sns.set_context(context)
plt.figure(1,figSize)

for i in range(len(data)):
  depth, shvel = np.loadtxt(data[i][0], dtype='float',unpack=True);
  plt.plot(shvel, depth,label=data[i][1]);

plt.gca().invert_yaxis();
plt.yticks(range(0,410,20))
plt.xlabel(xlabel)
plt.ylabel(ylabel)
plt.title(title)
plt.legend(loc=legend, prop={'size':10})
plt.tight_layout()
plt.savefig('plot.pdf')
