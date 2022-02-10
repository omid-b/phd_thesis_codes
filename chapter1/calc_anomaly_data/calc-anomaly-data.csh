#!/bin/csh
# This script generates anomaly data using the input scattered datasets (e.g. Vsv map data at different depths) and a reference depth profile model.
# Run the script to the the usage!
# Coded by: omid.bagherpur@gmail.com
# UPDATE: 25 April 2019

clear
printf "This script generates anomaly data using the input scattered datasets (e.g. Vsv map data at different depths) and a reference depth profile model.\n\n"
if ($#argv != 3) then
  printf "Error!\n\nUSAGE: ./make-anomaly-data.csh <datalist> <reference model> <output folder>\n\n"
  exit
else
	set datalist  = $argv[1]
	set refModel  = $argv[2]
	set outFolder = $argv[3]
endif

#check if the inputs are available
if (! -e $datalist) then
  printf "Error!\nCould not find the <datalist>: '$datalist'\n\n"
  exit
else if (! -e $refModel) then
  printf "Error!\nCould not find the <reference model>: '$refModel'\n\n"
  exit
endif

set nod = `cat $datalist|wc -l` #number of data

#make the outputfolder
if (-d $outFolder) then
  rm -rf $outFolder
endif
mkdir $outFolder

@ i=0
while ($i < $nod)
  @ i++
  echo "$i $nod %"|awk '{printf "  Generating data progress: %d%s   \r",($1/$2)*100,$3}'
  set depth = `awk "NR==$i" $datalist|awk '{printf "%.4f",$1}'`
  set data  = `awk "NR==$i" $datalist|awk '{print $2}'`
  set refDepth = `awk -v dep=$depth '$1==dep {printf "%.4f",$1}' $refModel`
  set refValue = `awk -v dep=$depth '$1==dep {print $2}' $refModel`
  if ( $refDepth != $depth ) then
    printf "\n\nError! Could not find the reference model value at depth=$depth\n\n"
    exit
  endif

  set fn = `echo $data|rev|awk -F"/" '{print $1}'|rev`
  awk -v val=$refValue '{print $1,$2,(($3-val)/val)*100}' $data > $outFolder/$fn
end
printf "  Generating data .... Done.            \n\n"


