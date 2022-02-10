#!/bin/csh
#===General Parameters===#
set homedir = /data/home/omid_b/2PWT_isotroic_final #Do not add "/" in the end
set softwaredir = /data/home/omid_b/Scripts/2PW #Do not add "/" in the end
set staloc = $homedir/stations.xy
set evtloc = $homedir/events.xy
set stationid = $homedir/stationid.dat
set passbands = $homedir/passbands.list
set grid = $homedir/nonuniform2_n2fac3.dat

#===Inversion Parameters===#
#filelists parameters:
#Aibing Li's recomended parameters: iter = 10, dampvel = 0.25, dampanis = 0.05
set smoothing = (80) #different smoothing(km) parameters
set minstns = 10    #min required number of stations in an event at each passband to be used in the inversion; more than 10 is recommended
set iter = 10       #number of iterations
set dampvel = 0.20
set dampanis = 0.05
set dum = 0.0004 #A dummy value; Not used in Li's codes!

#TPWT step2
set latinc = 0.025
set loninc = 0.025

#===Plotting Parameters===#
#used in plot_2dMaps.gmt and make_errMask.gmt
set grdSpacing = '0.5m' 
set mediaSize = '11.5ix14i'


