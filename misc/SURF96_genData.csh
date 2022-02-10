#!/bin/csh
#====Adjustable Parameters====#
set minErrs = (0.02) 
#=============================#
clear
printf "This script makes the input dispersion curve data for the SURF96 program.\n\n"

if ($#argv == 0) then
  printf "USAGE: csh surf96_gendata.csh <dispersion data>\nNOTE: The input data should have three columns:\n      (1)Period (2)PhaseVel (3)Error\n\n"
  exit
endif

@ i=1
while ( $i <= $#argv ) 
  set nper = `cat $argv[$i]|wc -l`
  set periods = `awk '{printf "%s ", $1}' $argv[$i]`
  set phvels  = `awk '{printf "%s ", $2}' $argv[$i]`
  set errors  = `awk '{printf "%s ", $3}' $argv[$i]`
  set minErrVal = `awk '{print $3}' $argv[$i]|sort -n|awk 'NR==1'`
  set errFactors = `awk -v errval=$minErrVal '{printf "%.4f ",$3/errval}' $argv[$i]`
  printf "Dispersion curve: '%s'\nNumber of periods: %s\nMinimum error values: " $argv[$i] $nper
  foreach err ($minErrs)
    printf "%s, " $err
  end
  printf "\n"
  
  #making outputs
  set nout = `echo $minErrs|wc -w`
  @ i2=1
  while ($i2 <= $nout)
    set fn = `echo $argv[$i]|rev|cut -d. -f 2-99|rev|awk -v err=$minErrs[$i2] '{printf "surf96_%s_err%.4f.disp",$1,err}'`
    touch $fn && rm -f $fn
    @ i3=1
    while ($i3 <= $nper)
      set errorValue = `echo $errFactors[$i3] $minErrs[$i2]|awk '{print $1*$2}'`
      printf "SURF96 R C X   0 %8.3f %7.4f %7.4f\n" $periods[$i3] $phvels[$i3] $errorValue >> $fn
      @ i3++
    end
    @ i2++
  end
  @ i++
  printf 'Done!\n\n'
end

