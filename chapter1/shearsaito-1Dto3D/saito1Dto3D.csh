#!/bin/csh
#This scripts generates the required inputs (i.e. filesc and phvel) for the compiled 'shearsaito-3cl-ct.f' (1D shearsaito code that considers crust to have variable thickness with 3 layers) for running the code at all individual dispersion curves to make a pseudo-3D shear wave velocity model.
# USAGE: csh shearsaito1Dto3D.csh <dispersion data list>
# <dispersion data list> should have 3 columns: longitude, latitude, dispCurve
#====Adjustable Parameters=====#
set maindir = $PWD
set iter = 10 #number of iteration
set nlyr = 40 #number of layers
set nper = 20 #number of periods
set dampVel = 0.20 #damping value for velocity
set dampCT  = 10   #damping value for crustal thickness
set CODE = shearsaito.3cl-ct
#==============================#
clear;
cd $maindir
printf "This script generates the required inputs (filesc and phvel) for the compiled 1D shearsaito code (shearsaito-3cl-ct.f) and then runs the inversion at a set of dispersion curves to make a pseudo-3D shear wave velocity model.\n\n"

if ($#argv != 1) then
  printf "USAGE: csh shearsaito1Dto3D.csh <dispersion data list>\n\n<dispersion data list> should have 3 columns:\n    1)longitude,   2)latitude,   3)dispCurve\n\n"
  printf "Each dispersion curve data should have 3 columns:\n    1)period,   2)phase Velocity,   3)variance\n\n"
  exit
else
  set datalist = $argv[1]
  set nod = `cat $datalist|wc -l`
  @ i=1
  foreach disp (`cat $datalist|awk '{print $3}'`) 
    if (! -e $disp ) then
      printf "Error!\n> Could not find data at line $i\n  $disp\n\n"
      exit
    endif
    @ i++
  end
endif

#make a folder to store input files ('shearsaito_inputs')
if (-d shearsaito_inputs) then
  rm -rf shearsaito_inputs
  mkdir shearsaito_inputs
else
  mkdir shearsaito_inputs
endif

#generate input files
printf "  Generating inputs ... \r"
@ i=1
while ($i <= $nod)
  set lon  = `awk "NR==$i" $datalist|awk '{printf "%.2f",$1}'`
  set lat  = `awk "NR==$i" $datalist|awk '{printf "%.2f",$2}'`
  set disp = `awk "NR==$i" $datalist|awk '{printf "%s",$3}'`
  set phvel = `echo $lon $lat|awk '{printf "phvel_X%sY%s.d",$1,$2}'`
  set shvel = `echo $lon $lat|awk '{printf "shvel_X%sY%s.d",$1,$2}'`
  set resol = `echo $lon $lat|awk '{printf "resol_X%sY%s.d",$1,$2}'`
  set filesc = `echo $lon $lat|awk '{printf "filesc_X%sY%s.d",$1,$2}'`
  cat $disp|awk '{printf "%10.8f%14.8f\n",$2,$3}'\
   > shearsaito_inputs/$phvel
  printf "$iter\n$nlyr\n$nper\n$dampVel $dampCT\n$phvel\n$shvel\n$resol\n"\
   > shearsaito_inputs/$filesc
  @ i++
end
printf "  Generating inputs ... Done!\n\n"

printf "Do you want to continue running the inversion (y/n)? "
set uans = $<
if ($uans != 'y') then
  printf "\n\nExit program!\n\n"
  exit
else
  printf "\n"
endif

#check if the code is available in main directory
foreach fn ($CODE stmodel.d stinput.d)
  if (! -e $fn) then
    printf "Error!\n> Could not find $fn in main directory\n\n"
    exit
  endif
end

#make a folder to store output files ('shearsaito_outputs')
if (-d shearsaito_outputs) then
  rm -rf shearsaito_outputs
  mkdir shearsaito_outputs
else
  mkdir shearsaito_outputs
endif

#run inversion
@ i=0
foreach filesc (`ls shearsaito_inputs|grep filesc`)
  @ i++
  set run = `echo $filesc| awk -F'_' '{print $2}'`
  cp shearsaito_inputs/$filesc filesc.tmp
  cp shearsaito_inputs/phvel_$run $maindir
  printf "  Running inversion ($i of $nod): $run \r"
  $CODE < filesc.tmp > log.tmp
  rm -f phvel_$run
  mv shvel_$run resol_$run shearsaito_outputs/
end
printf "  Running inversions ... Done!                              \n\n"

rm -f filesc.tmp log.tmp #DERIV.DATA 

