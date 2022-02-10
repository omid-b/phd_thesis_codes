#!/bin/csh -f

#set ds = `ls -F | grep "[0-9][0-9][0-9]/"`
#foreach d ($ds)

set refdir='/data/home/darbyshire_f/SW_TOMOGRAPHY'

foreach d (01? 02? 03? 04? 05? 06? 07? 08?)
#foreach d (03?)
#foreach d (025)

cd $d

# For low-smoothness run before excluding outliers
#  set smth1=0.001
#  set smth2=0.001
#  set smth3=0.001

# For constant smoothness all the way through
  set smth1=0.4
  set smth2=0.8
  set smth3=0.8

# For low-damping run before excluding outliers
#  set damp1=0.001
#  set damp2=0.001
#  set damp3=0.001

# Gradient damping, standard values
  set damp1=0.05
  set damp2=0.07
  set damp3=0.07

  echo "1000" > iniac
  echo "25" >> iniac
  echo "1 2 3 5 7 10 15 20 30 40 50 70 100 130 160 200 250 300 350 400 500 600 700 800 900 1000" >> iniac
  echo "0.05 0.05 0.05" >> iniac
  echo $smth1 $smth2 $smth3 >> iniac
  echo $damp1 $damp2 $damp3 >> iniac
  echo "0 0 0" >> iniac
  echo "0.6 0.6 0.6" >> iniac

  echo "0" > inxc
  echo "0" >> inxc
  echo "0.5 0.5 0.5" >> inxc
  echo "1  0.2" >> inxc
  echo "1  0.7" >> inxc
 
  $refdir/BIN/iac < iniac > outiac
  $refdir/BIN/xsc < inxc > outxc
  $refdir/SCRIPTS/plcg-greenland-new.gmt
  $refdir/SCRIPTS/getstats.csh

 echo "Finished period $d"

  cd ..
end
