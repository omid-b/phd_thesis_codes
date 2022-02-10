#!/bin/csh -f

# Assumes script "dcpgridcount" has been used to make coordinate files.

set maindir=/data/home/darbyshire_f/SW_TOMOGRAPHY/GREENLAND2

set ds = (0??)

foreach period ($ds)
 set refvel=`awk '{print $7}' < $maindir/$period/matrix_key`
 echo $period $refvel >> reference_vels
end

foreach point (`cat coordinates`)
echo $point > temp
set lon=`awk -F- '{print $1}' < temp`
set lat=`awk -F- '{print $2}' < temp`
 foreach period ($ds)
  grep "$lon  $lat" $maindir/$period/dcp > tmp
  set deviso=`awk '{print $3}' < tmp `
  set refvel=`awk '{print $7}' < $maindir/$period/matrix_key`
  echo $refvel $deviso > tmp1
  set isovel=`awk '{print $1+$2/1000}' < tmp1 `
  
  set filenm='curve_'$lon'_'$lat
  echo $period $isovel >> $filenm
  rm temp tmp*
 end
end

mkdir 1D-curves
mv curve_* 1D-curves
