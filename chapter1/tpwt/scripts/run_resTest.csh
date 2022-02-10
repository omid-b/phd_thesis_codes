#!/bin/csh

cd `dirname $0`
source ../param.csh
#===Adjustable Parameters====#
#compiled codes:
set kernsyndata = $softwaredir/bin/kern-syndata
set obgridgeno   = $softwaredir/bin/obgridgeno
set obgridgenvar = $softwaredir/bin/obgridgenvar
set simannerr1  = $softwaredir/bin/simannerr1
set simannerr13kern  = $softwaredir/bin/simannerr13.kern
#grid increament
set latinc = 0.1
set loninc = 0.1
set period = 25
#============================#
clear
printf "This script automates the resolution test procedure using 'checkerboard.vel' data in home directory.\n\n latinc = $latinc\n loninc = $loninc\n period: $period\n\n"
cd $homedir

if (! -e synmodel.vel) then
  printf "Error! Could not find 'synmodel.vel' in homedir. You can make a checkerboard model using 'checkerboard.csh'. Next, rename the output *.vel file as 'synmodel.vel' and put it in:\n  $homedir.\n\n"
  exit
endif

if (! -e $kernsyndata) then
  printf "Error! Could not find the compiled code ('kernsyndata').\n\n"
  exit
endif

if (! -e $obgridgeno) then
  printf "Error! Could not find the compiled code ('obgridgeno').\n\n"
  exit
endif

if (! -e $obgridgenvar) then
  printf "Error! Could not find the compiled code ('obgridgenvar').\n\n"
  exit
endif

if (`ls|grep ^run2Dkern_|wc -l` == 0) then
 printf "Could not find any run2Dkern* folders!\n\n"
 exit
endif

printf "Do you want to continue (y/n)? "
set uans = $< 
if ($uans == 'y') then
 printf "\n\n"
else
 printf "Exit!\n\n"
 exit
endif
 

#Code Block!
if (! -d resTest) mkdir resTest
set per = `echo $period|awk '{printf "%03.0f ", $1}'`
set nNod = `awk 'NR==2' $grid`

cp synmodel.vel gridnode.vel
cp $grid gridnode
cp $kernsyndata kernsyndata
cp $obgridgeno obgridgeno
cp $obgridgenvar obgridgenvar
cp $simannerr1 simannerr1
cp $simannerr13kern simannerr13kern
foreach runset (`ls|grep ^run2Dkern_|awk -F"run2Dkern_" '{print $2}'`)
 if (! -e run1D_$runset/average_$runset.disp) then
   printf "Error! Could not find run1D_$runset/average_$runset.disp\n\n"
   exit
 endif
 
 printf "  Make synthetic phase and amplitude data ... \r"
 if (! -d resTest/$runset) mkdir resTest/$runset
 if (! -d resTest/$runset/p$per) mkdir resTest/$runset/p$per
 cp phamps/phamps_$runset/phamp_p$per .
 cp kernels/kernels_$runset/p$per.kern .
 cp filelists/filelists_$runset/filelist.p$per filelistsyn.p$per
 ./kernsyndata < filelistsyn.p$per
 mv synamph synamph.p$per
 printf "  Make synthetic phase and amplitude data ... Done!\n"
 
 printf "  Running 1D TPW inversion using synthetic data ... \r"
 set filelistNR = `cat filelistsyn.p$per|wc -l`
 set filelisthead = `echo $filelistNR-4|bc`
 head -n$filelisthead filelistsyn.p$per > filelist1.p$per
 echo synamph.p$per >> filelist1.p$per
 tail -n3 filelistsyn.p$per >> filelist1.p$per
 ./simannerr1 < filelist1.p$per > simannerr1.log
 set avgVel = `tail -n1 summary_p$per.sa1|awk '{print $1}'`
 set filelisthead = `echo $filelistNR-2|bc`
 head -n$filelisthead filelist1.p$per > filelist13.p$per
 tail -n2 filelist1.p$per|awk 'NR==1'|awk -v vel=$avgVel '{print $1,$2,$3,$4,vel}' >> filelist13.p$per
 echo  p$per.kern >> filelist13.p$per
 printf "  Running 1D TPW inversion using synthetic data ... Done!\n"

 printf "  Running 2D TPW inversion using the obtained avgVel ... \r"
 ./simannerr13kern < filelist13.p$per > simannerr13kern.log
 printf "  Running 2D TPW inversion using the obtained avgVel ... Done!\n"
 
 printf "  Making gridded inversion outpus ... \r"
 
 set summary = summary_p$per.sa13kern
 set covar   = covar_p$per.sa13kern
 tail -n$nNod $summary > data.tmp
 awk 'NR>2' $grid|head -n$nNod > nodes.tmp
 
  set lat1 = `awk '{print $1}' nodes.tmp|sort -n |head -n1`
  set lat2 = `awk '{print $1}' nodes.tmp|sort -nr|head -n1`
  set lon1 = `awk '{print $2}' nodes.tmp|sort -n |head -n1`
  set lon2 = `awk '{print $2}' nodes.tmp|sort -nr|head -n1`
  
  set latLen = `echo $lat1 $lat2|awk '{printf "%.2f",$2-$1}'`
  set lonLen = `echo $lon1 $lon2|awk '{printf "%.2f",$2-$1}'`
  set nx = `echo $lonLen $loninc|awk '{printf "%d",$1/$2+1}'`
  set ny = `echo $latLen $latinc|awk '{printf "%d",$1/$2+1}'`

  set reflat = `echo $lat1 $lat2|awk '{printf "%.2f",($1+$2)/2}'`
  set reflon = `echo $lon1 $lon2|awk '{printf "%.2f",($1+$2)/2}'`
  set applat0 = `echo $reflat| awk '{printf "%.2f",$1-90}'`
  set applon0 = `echo $reflon| awk '{printf "%.2f",$1-90}'`
 
  if (`echo "$applat0 < (-90)"|bc` == 1) then
    set applat = `echo $applat0|awk '{printf "%.2f",$1+180}'`
  else
    set applat = $applat0
  endif

  if (`echo "$applon0 < (-90)"|bc` == 1) then
    set applon = `echo $applon0|awk '{printf "%.2f",$1+180}'`
  else
    set applon = $applon0
  endif

 printf "$grid\ndata.tmp\ngrid_p$per.tmp\n$applat\n$applon\n$reflat\n$reflon\n$lat1\n$lon1\n$nx\n$ny\n$latinc\n$loninc\n" > codeinp.tmp
 
    ./obgridgeno < codeinp.tmp > /dev/null
    awk '{printf "%9.4f %9.4f  %s\n",$1,$2,$3}' grid_p$per.tmp > resTest_p$per.xy
    rm -f grid_p$per.tmp codeinp.tmp data.tmp
 
 awk '{print $1,$4,0}' gridnode.vel > data.tmp
  printf "$grid\ndata.tmp\nsynmodel_p$per.tmp\n$applat\n$applon\n$reflat\n$reflon\n$lat1\n$lon1\n$nx\n$ny\n$latinc\n$loninc\n" > codeinp.tmp
  
 ./obgridgeno < codeinp.tmp > /dev/null
 awk '{printf "%9.4f %9.4f  %s\n",$1,$2,$3}' synmodel_p$per.tmp > resTestSyn_p$per.xy
 rm -f synmodel_p$per.tmp codeinp.tmp data.tmp
 
 printf "$grid\n$covar\ngridCovar_p$per.tmp\n$applat\n$applon\n$reflat\n$reflon\n$lat1\n$lon1\n$nx\n$ny\n$latinc\n$loninc\n" > codeinp.tmp
 ./obgridgenvar < codeinp.tmp > /dev/null
 awk '{printf "%9.4f %9.4f  %s\n",$1,$2,$3}' gridCovar_p$per.tmp > resTestCovar_p$per.xy
 rm -f codeinp.tmp gridCovar_p$per.tmp nodes.tmp kernsyndata obgridgeno obgridgenvar simannerr1 simannerr13kern
 printf "  Making gridded inversion outpus ... Done!\n\n"
 mv fort.11 covar_p$per.sa1 covar_p$per.sa13kern detail_p$per.sa1 detail_p$per.sa13kern filelistsyn.p$per filelist1.p$per filelist13.p$per followit12 gridnode gridnode.vel  resTest_p$per.xy resTestCovar_p$per.xy resTestSyn_p$per.xy p$per.kern phamp_p$per simannerr1.log simannerr13kern.log summary_p$per.sa1 summary_p$per.sa13kern synamph.p$per resTest/$runset/p$per
end

