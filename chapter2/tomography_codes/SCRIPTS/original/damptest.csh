#!/bin/csh -f

foreach testval (`cat damptestvals`)

set resdir=$testval
echo $testval > tmp
set damp1=`awk -F_ '{print $1}' < tmp`
set damp2=`awk -F_ '{print $2}' < tmp`
set damp3=`awk -F_ '{print $3}' < tmp`

set smth1=0.1
set smth2=0.2
set smth3=0.2

foreach d (025)

cd $d
  
echo "500" > iniac
echo "25" >> iniac
echo "1 2 3 5 7 10 15 20 30 40 50 70 100 130 160 200 250 300 350 400 500 600 700 800 900" >> iniac
echo "0.05 0.05 0.05" >> iniac
echo $smth1 $smth2 $smth3 >> iniac
echo $damp1 $damp2 $damp3 >> iniac
echo "0 0 0" >> iniac
echo "0.6 0.6 0.6" >> iniac
  
iac < iniac > outiac
xsc < inxc > outxc
plcg-greenland.gmt

getstats.csh
  
mkdir $resdir
mv d* out* plcg.ps sol* stats-info $resdir

rm tmp tmp1
cd ..
end
end
