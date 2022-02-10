#!/bin/csh

cd `dirname $0`
source ../param.csh
cd $homedir


set getdata = $softwaredir/bin/getdatafromsac
set createsac = $softwaredir/bin/createsac
set sensitivity = $softwaredir/bin/sensitivity_Rayleigh
set period = `awk 'NR>1' $passbands|awk '{printf "%3.0f ", $3}'`
#set vel = `awk 'NR>1' $passbands|awk '{printf "%10.8f ", $4}'`
clear

printf "This script automates making kernels for various smoothing lengths\n\n"

set nrun1d = `ls|grep run1D_|wc -l`

if (`echo "$nrun1d == 0"|bc` == 1) then
  printf 'Could not find any run1D* directory! Please run the 1D inversion code first!\n\n'
  exit
endif

printf "Do you want to continue (Y/N)? "
set uans = $< 
if ($uans == 'yes' ||$uans == 'YES' ||$uans == 'Y' ||$uans == 'y') then
 echo ""
else
 printf "\n EXIT script!\n\n"
 exit
endif

#---------------------------#
#           STEP1
#    Make spectral files 
# (Input to the kernel code)
#---------------------------#

if (-d kernels) rm -rf kernels
mkdir kernels

printf "STEP1: Making spectral files to input to the kernel code.\nPeriods:"
printf " %s" $period; printf "\n\n Making the spectral file\n"

foreach per1 ($period)
cd $homedir/kernels

set per = `echo $per1| awk '{printf "%03.0f\n",$1}'`

set freq = `awk 'NR>1' $passbands|awk '{print $3,$2}'|grep -w $per|awk '{printf "%s ", $2}'`
printf "  Frequency: $freq, Period: $per   \r"
$createsac <<END >log.tmp
$freq
$homedir/kernels/p$per.sac
END

$getdata <<END >log.tmp
$homedir/kernels/p$per.sac
$homedir/kernels/p$per.dat
END

set f = $homedir/kernels/p$per.dat
@ c = 0

#line number smaller and equal to 1000
@ l = 1000

while ($c <= 1)
 set amp1 = `awk "NR==$l" $f|awk '{print $2}'`
 set l = `echo "$l-1"|bc`
 set amp2 = `awk "NR==$l" $f|awk '{print $2}'`
 if (`echo "($amp1*$amp2) < 0"|bc` == 1) then
   @ c++
   set w1 = `echo "$l-1"|bc`
 endif
end
#line number larger than 1000
@ l = 1001

while ($c <= 2)
 set amp1 = `awk "NR==$l" $f|awk '{print $2}'`
 set l = `echo "$l+1"|bc`
 set amp2 = `awk "NR==$l" $f|awk '{print $2}'`

 if (`echo "($amp1*$amp2) < 0"|bc` == 1) then
   @ c++
   set w2  = `echo "$l+1"|bc`
 endif
end


setenv SAC_DISPLAY_COPYRIGHT 0
sac <<END >log.tmp
echo off

 setbb cut1 $w1
 setbb cut2 $w2
 evaluate to cut1 %cut1 - 50
 evaluate to cut2 %cut2 + 50
    cut %cut1 %cut2
    evaluate to totlen %cut2 - %cut1
    evaluate to tprfrac 50 / %totlen

     r p$per.sac
     taper w %tprfrac
     w temp2
    cuterr fillz
    cut 0 2000
    r temp2
    cuterr u
     w p$per.cut
     r p$per.cut
     fft
     wsp
quit
END

rm  temp? p$per.dat

$getdata <<END >log.tmp
p$per.cut.am
p$per.cut.am.dat.tmp
END

awk 'NR>1' p$per.cut.am.dat.tmp > p$per.cut.am.dat
rm -f p$per.cut.am.dat.tmp

set max = `cat p$per.cut.am.dat|sort -nrk2|awk "NR==1"|awk '{print $2}'`
set maxPos = `grep -nr $max p$per.cut.am.dat|awk -F: '{print $1}'`

set l2pos = $maxPos
set l1pos = `echo "$l2pos-1"|bc`
set l1 = `awk "NR==$l1pos" p$per.cut.am.dat|awk '{print $2}'`
set l2 = $max

while ( `echo "$l2 > $l1"|bc` == 1 )
  set l1pos = `echo "$l1pos-1"|bc`
  set l2pos = `echo "$l1pos+1"|bc`
  set l1 = `awk "NR==$l1pos" p$per.cut.am.dat|awk '{print $2}'`
  set l2 = `awk "NR==$l2pos" p$per.cut.am.dat|awk '{print $2}'`
  if ($l1pos < 1) set l1 = $l2
end
set start = `echo "$l1pos-1"|bc`

set l1pos = $maxPos
set l2pos = `echo "$l1pos+1"|bc`
set l2 = `awk "NR==$l2pos" p$per.cut.am.dat|awk '{print $2}'`
set l1 = $max

while ( `echo "$l1 > $l2"|bc` == 1 )
  set l1 = $l2
  set l1pos = $l2pos
  set l2pos = `echo "$l2pos+1"|bc`
  set l2 = `awk "NR==$l2pos" p$per.cut.am.dat|awk '{print $2}'`
end

set end = `echo "$l1pos+1"|bc`

awk "NR>$start && NR<$end" p$per.cut.am.dat > p$per.spectral.tmp
cat p$per.spectral.tmp|wc -l > p$per.spectral
cat p$per.spectral.tmp >>p$per.spectral
rm -f p$per.spectral.tmp
end

rm -f *.tmp; printf "\n\n"

if (-d kernel_spectral) rm -rf kernel_spectral
mkdir kernel_spectral
mv p*.sp* kernel_spectral
rm p*cut* *.sac


#---------------------#
#       STEP2
#    Make Kernels
#---------------------#
printf "STEP 2: Making final kernels using the spectral files."

cd $homedir
if (! -d $homedir/kernels/kernel_spectral) then
  echo "Could not find kernel_spectral folder! \n"
  exit
endif

foreach run1d (`ls|grep run1D_`)
  set setname = `echo $run1d|cut -d"_" -f2-99`
  set phvels = `cat $homedir/$run1d/average*disp|awk '{printf "%10.8f ",$2}'`
  set smth = `echo $setname|awk -F"st" '{print $2}'|awk -F"km" '{print $1}'`
  
  printf "\n\n Runset: $setname\n"
  set c1 = 0
  foreach per1 ($period)
    cd $homedir/kernels
    @ c1++
    set per = `echo $per1| awk '{printf "%03.0f\n",$1}'`
    printf "  Smoothing(km): $smth, Spectral: p$per.spectral, Velocity: $phvels[$c1]\r"
    
$sensitivity <<END >log.tmp
$phvels[$c1]
kernel_spectral/p$per.spectral
p$per.kern
$smth
END

  end
  if (-d $homedir/kernels/kernels_$setname) rm -rf $homedir/kernels/kernels_$setname
  mkdir $homedir/kernels/kernels_$setname
  mv $homedir/kernels/p*.kern kernels_$setname
end

printf "\n\n"

