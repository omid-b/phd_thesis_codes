#!/bin/csh -f

set homedir='/data/home/darbyshire_f/SW_TOMOGRAPHY'

foreach testval (`cat smthtestvals`)
#foreach testval (`cat smthsuppl`)

set resdir=$testval
echo $testval > tmp
set smth1=`awk -F_ '{print $1}' < tmp`
set smth2=`awk -F_ '{print $2}' < tmp`
set smth3=`awk -F_ '{print $3}' < tmp`

set damp1=0.05
set damp2=0.05
set damp3=0.05

foreach d (070)

cd $d
  
echo "1000" > iniac
echo "25" >> iniac
echo "1 2 3 5 7 10 15 20 30 40 50 70 100 130 160 200 250 300 350 400 500 600 700 800 900" >> iniac
echo "0.05 0.05 0.05" >> iniac
echo $smth1 $smth2 $smth3 >> iniac
echo $damp1 $damp2 $damp3 >> iniac
echo "0 0 0" >> iniac
echo "0.6 0.6 0.6" >> iniac
  
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt

$homedir/SCRIPTS/getstats.csh
  
mkdir $resdir
mv d* out* tomo*.ps sol* stats-info $resdir

rm tmp tmp1
cd ..
end
end
