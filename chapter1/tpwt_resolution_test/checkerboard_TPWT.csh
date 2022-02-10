#!/bin/csh
# This script makes symmetric checkerboard velocity grid data. 
# USAGE: csh checkerboard.csh <lowVel> <highVel> <output>
# Coded by Omid Bagherpur
# Update: 22 Jan 2019
#=====Adjustable Parameters=====#
# set longitude (x) and latitude (y) limits (decimal degree):
# Note: upper coordinate limits might change a bit since the script tries to make a symmetric model
set x1 = -75
set x2 = -57
set y1 = 41
set y2 = 50
# set node spacing (deg):
set xSpacing = 0.75
set ySpacing = 0.5
# set the number of nodes for checkerboard square size (an integer larger than (or equal to) 2)
# square size in degrees: ($sqXNodes*$xSpacing) by ($sqYNodes*$ySpacing)
set sqXNodes = 2
set sqYNodes = 2
# set number of nodes (positive integer or zero) between anomalous squares and at margins having the average velocity:
set xGapNodes = 0
set yGapNodes = 0
# reverse the position of anomalies (yes/no):
set reverese = no
#=============================#
set avgVel  = $1
set pert = $2

#Code Block!
if (-e gridnodevel.tmp) rm -f gridnodevel.tmp
clear
printf "This script makes a grid of checkerboard velocity model.\n\nParameters:\n <Longitude>: $x1 $x2    <Latitude>: $y1 $y2\n  lonSpacing: $xSpacing      latSpacing: $ySpacing\n  sqXNodes:   $sqXNodes      sqYNodes:   $sqYNodes\n  xGapNodes:  $xGapNodes      yGapNodes:  $yGapNodes\n\n"

if ($#argv != 3) then
  printf "Error! USAGE: csh checkerboard.csh <avg Vel> <perturbation> <output>\n\n"
  exit
endif
#check if parameters are set correctly:
if (`echo "$x1 > $x2"|bc` == 1) then
  printf "Error! x1 should be less than x2!\n\n"
  exit
endif
if (`echo "$y1 > $y2"|bc` == 1) then
  printf "Error! y1 should be less than y2!\n\n"
  exit
endif

if (`echo "$sqXNodes < 2"|bc` == 1) then
  printf "Error! sqXNodes should be an integer greater than (or equal to) 2!\n\n"
  exit
endif
if (`echo "$sqYNodes < 2"|bc` == 1) then
  printf "Error! sqYNodes should be an integer greater than (or equal to) 2!\n\n"
  exit
endif
if (`echo "$xGapNodes < 0"|bc` == 1) then
  printf "Error! 'xGapNodes' should be a positive integer (or zero)!\n\n"
  exit
endif
if (`echo "$yGapNodes < 0"|bc` == 1) then
  printf "Error! 'yGapNodes' should be a positive integer (or zero)!\n\n"
  exit
endif
#------------------------------------
printf "Do you want to continue (y/n)? "
set uans = y
if ($uans != 'y') then
  echo "Exit!"
  exit
endif
printf "\n\n" 
#----------CALCULATIONS------------->
set anomaly = `echo "$avgVel $pert"|awk '{printf "%.4f",$1*($2/100)}'`

printf "  Making $3.vel and $3.xy ... \r"


set sign = 1
if ($reverese == 'yes') then
  set sign = `echo "$sign*(-1)"|bc`
endif

set nx = `echo $x1 $x2 $xSpacing|awk '{printf "%d",($2-$1)/$3 + 1}'`
set xPeriod = `echo $sqXNodes $xGapNodes|awk '{printf "%d",$1+$2}'`

set ny = `echo $y1 $y2 $ySpacing|awk '{printf "%d",($2-$1)/$3 + 1}'`
set yPeriod = `echo $sqYNodes $yGapNodes|awk '{printf "%d",$1+$2}'`

if (-e sqsign0.tmp) rm -f sqsign0.tmp

set nsqx = `echo $nx $xPeriod|awk '{printf "%.2f",$1/$2}'`
if (`echo $nsqx|awk -F"." '{printf "%d",$2}'` != 0) then
  set nsqx = `echo $nsqx|awk -F"." '{printf "%.2f",$1+1}'`
endif
set nsqx = `echo $nsqx|awk -F"." '{print $1}'`

set nsqy = `echo $ny $yPeriod|awk '{printf "%.2f",$1/$2}'`
if (`echo $nsqy|awk -F"." '{printf "%d",$2}'` != 0) then
  set nsqy = `echo $nsqy|awk -F"." '{printf "%.2f",$1+1}'`
endif
set nsqy = `echo $nsqy|awk -F"." '{print $1}'`

@ iy=1
while ($iy <= $nsqy)
  set sign = `echo "$sign*(-1)"|bc`
  echo 1 $iy $sign >> sqsign0.tmp
  @ iy++
end

@ ix=2
while ($ix <= $nsqx)
  @ iy=1
  while ($iy <= $nsqy)
    set temp = `echo "$ix-1"|bc`
    set sign = `cat sqsign0.tmp|awk -v x=$temp '$1  ~ x'|awk -v y=$iy '$2 ~ y'|awk '{print $3*(-1)}'`
    echo $ix $iy $sign >> sqsign0.tmp
    @ iy++
  end
  @ ix++
end
mv sqsign0.tmp sqsign.tmp

@ ix=1
while ($ix <= $nx)
  @ iy=1
  while ($iy <= $ny)
    set x = `echo $x1 $ix $xSpacing|awk '{printf "%.2f",$1+($2-1)*$3}'`
    set y = `echo $y1 $iy $ySpacing|awk '{printf "%.2f",$1+($2-1)*$3}'`
    set sqx = `echo $ix $xPeriod|awk '{printf "%.2f",($1-1)/$2}'|awk -F"." '{print $1+1}'`
    set sqy = `echo $iy $yPeriod|awk '{printf "%.2f",($1-1)/$2}'|awk -F"." '{print $1+1}'`
    
    if (`echo "$ix $xPeriod"|awk '{print ($1-1)%$2}'` < $xGapNodes || `echo "$iy $yPeriod"|awk '{print ($1-1)%$2}'` < $yGapNodes) then
      echo $x $y $avgVel| awk '{printf "%s %s %s\n",$1,$2,$3}' >> gridnodevel.tmp
    else
      set sign = `cat sqsign.tmp|awk -v sqx=$sqx '$1  ~ sqx'|awk -v sqy=$sqy '$2 ~ sqy'|awk '{print $3}'`
      echo $x $y $avgVel $anomaly $sign|awk '{printf "%s %s %.4f\n",$1,$2,$3+($4*$5)}' >> gridnodevel.tmp
    endif

    @ iy++
  end
  @ ix++
end


mv gridnodevel.tmp $3.xy
awk '{print NR,$2,$1,$3}' $3.xy > $3.vel
rm -f sqsign.tmp
printf "  Making $3.vel and $3.xy ... Done!\n\n"

