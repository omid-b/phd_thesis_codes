#!/bin/csh
#This scripts makes plots for the output folder of the shearsaito1Dto3D.csh script (shearsaito_outputs)
# USAGE: csh shearsaito1Dto3D-step2.csh
#====Adjustable Parameters=====#
set maindir = $PWD
set noCT = 3 # number of crustal layers
#==============================#
clear;
cd $maindir
printf "This scripts makes plots for the output folder of the shearsaito1Dto3D.csh script (shearsaito_outputs)\n\n"

if ($#argv != 0) then
  printf "USAGE: csh shearsaito1Dto3D-step2.csh\n\n"
  exit
else if (! -d shearsaito_outputs) then
  printf "Could not find 'shearsaito_outputs' folder in main directory.\n\n"
  exit
else if (! -e stmodel.d) then
  printf "Could not find 'stmodel.d' in main directory.\n\n"
  exit
endif

cd shearsaito_outputs
touch layer.tmp; rm -f layer*
set nod = `ls |grep shvel|wc -l`

if (-d vs_profiles) then
  rm -rf vs_profiles
  mkdir vs_profiles
else
  mkdir vs_profiles
endif

set sample = `ls |grep shvel|awk 'NR==1'`
set ln1 = `grep -n 'main results' $sample| awk -F: '{print $1}'`
set ln2 = `grep -n 'data importance' $sample| awk -F: '{print $1}'`
set nlyr = `echo "($ln2-$ln1-1)/2"|bc`
printf " Number of nodes: $nod\n Number of layers: $nlyr\n\n"

printf "Do you want to continue (y/n)? "
set uans = $<
if ($uans != 'y') then
  printf "\n\nExit program!\n\n"
  exit
else
  printf "\n"
endif

#extract layers
touch crust.dat; rm -f crust.dat

foreach shvel (`ls|grep shvel`)
  set lon = `echo $shvel| awk -F"X" '{print $2}'|awk -F"Y" '{print $1}'`
  set lat = `echo $shvel| awk -F"Y" '{print $2}'|awk -F".d" '{print $1}'`
  
  set ln1 = `grep -n 'main results' $shvel| awk -F: '{print $1}'`
  set nlyr2 = `echo "$nlyr*2"|bc`
  cat $shvel|awk "NR>$ln1"| awk "NR<=$nlyr2" > main.tmp
  
  @ i=1;
  echo 0 > depth.tmp
  echo 0 > thck.tmp
  
  while ($i <= $nlyr)
    set fn  = `echo $i| awk '{printf "layer%02d.xyz",$1}'`
    set fn2 = all_xyzv
    set fn3 = `echo $lon $lat|awk '{printf "X%sY%s.vs",$1,$2}'`

    set lineNum = `echo "$i*2"|bc`
    set thck = `cat main.tmp|awk "NR==$lineNum"|awk '{print $1}'`
    set thck0 = `cat thck.tmp|awk "NR==$i"`
    set depth = `cat depth.tmp|awk "NR==$i"|awk -v thck=$thck -v thck0=$thck0 '{printf "%.2f",$1+(thck/2)+(thck0/2)}'`
    echo $depth >> depth.tmp
    echo $thck  >> thck.tmp
    set value = `cat main.tmp|awk "NR==$lineNum"|awk '{print $4}'`
    echo $lon $lat $value >> $fn
    echo $lon $lat $depth $value >> $fn2.tmp
    echo $depth $value >> vs_profiles/$fn3
    if ($i == $noCT) then
      echo $lon $lat $depth|awk -v thck=$thck '{print $1,$2,$3+(thck/2)}' >> crust.dat
    endif
    @ i++
  end
end

cat $fn2.tmp|sort -nk3|awk '{printf "%s %s %6.2f %s\n",$1,$2,$3,$4}' >> $fn2.dat

rm *.tmp


