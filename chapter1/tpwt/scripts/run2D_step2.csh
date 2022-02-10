#!/bin/csh
# post processing the outputs in run2D and run2Dkern folders in $homedir. This script automates the followings: 
#   1) re-grid the output (using obgridgeno.f90)
#   2) gridding covariance data for further error analysis (required for masking error mask: 'errMask.nc')
#   3) extracting and plotting 1D disprsion data at grid nodes
# Used parameters in 'param.csh': homedir, passbands
cd `dirname $0`
source ../param.csh
#===Adjustable Parameters====#
#compiled codes:
set obgridgeno   = $softwaredir/bin/obgridgeno
set obgridgenvar = $softwaredir/bin/obgridgenvar
#plot 1D dispersion code:
set plot1dDisp   = $softwaredir/scripts/plot_1dDisp.gmt
#============================#
clear
printf "This script automates the post processing procedure of the 2D TPWT outputs, including the re-gridding of phase velocities.\n"
cd $homedir

if (! -e $obgridgeno) then
 printf "Error! Couldn't find the compiled code (obgridgeno)!\n"
 exit
endif

if (! -e $obgridgenvar) then
 printf "Error! Couldn't find the compiled code (obgridgenvar)!\n"
 exit
endif

printf "\nDo you want to continue (y/n)? "
set uans = $<
if ($uans == 'y') then
  echo " "
else
  exit
endif

foreach run2D (`ls|grep ^run2D`)
  printf "\n Working on $run2D\n"
  cd $homedir/$run2D
  touch f0.tmp && rm  -f *.tmp
  cp $obgridgeno obgridgeno
  cp $obgridgenvar obgridgenvar
  set nNod = `awk 'NR==2' $grid`
  awk 'NR>2' $grid|head -n$nNod > nodes.yx
  set nPer = `awk 'NR>1' $passbands|awk '{print $3}'|wc -l`
  awk 'NR>1' $passbands|awk '{print $3}'> per.dat

  set lat1 = `awk '{print $1}' nodes.yx|sort -n |head -n1`
  set lat2 = `awk '{print $1}' nodes.yx|sort -nr|head -n1`
  set lon1 = `awk '{print $2}' nodes.yx|sort -n |head -n1`
  set lon2 = `awk '{print $2}' nodes.yx|sort -nr|head -n1`
  
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
  
  foreach covar (`ls|grep covar`)
    set pxxx = `echo $covar|awk -F"_" '{print $2}'|awk -F"." '{print $1}'|awk '{printf "%s",$1}'`
    printf "  Making gridCovar_$pxxx.dat files ...\r"
    printf "$grid\n$covar\ngridCovar_$pxxx.tmp\n$applat\n$applon\n$reflat\n$reflon\n$lat1\n$lon1\n$nx\n$ny\n$latinc\n$loninc\n" > codeinp.tmp
    ./obgridgenvar < codeinp.tmp > /dev/null
    awk '{printf "%9.4f %9.4f  %s\n",$1,$2,$3}' gridCovar_$pxxx.tmp > gridCovar_$pxxx.dat
    rm -f codeinp.tmp
  end
  printf "  Making all gridCovar_p???.dat files ... Done \n"
   
  foreach summary (`ls summary_p*sa13*`)
    set pxxx = `echo $summary|awk -F"_" '{print $2}'|awk -F"." '{print $1}'|awk '{printf "%s",$1}'`
    printf "  Making grid_$pxxx.dat files ...\r"
    tail -n$nNod $summary > data.tmp
    printf "$grid\ndata.tmp\ngrid_$pxxx.tmp\n$applat\n$applon\n$reflat\n$reflon\n$lat1\n$lon1\n$nx\n$ny\n$latinc\n$loninc\n" > codeinp.tmp
    ./obgridgeno < codeinp.tmp > /dev/null
    paste grid_$pxxx.tmp  gridCovar_$pxxx.dat|awk '{printf "%9.4f %8.4f %10.8f %10.8f\n",$1,$2,$3,$6}'  > grid_$pxxx.dat
    rm -f grid_$pxxx.tmp codeinp.tmp data.tmp
    
   #make summary_p???.xy file: 
     set fn = `echo $summary|awk -F"." '{print $1}'`
     tail -n$nNod $summary > sf0.tmp
     paste nodes.yx sf0.tmp|awk '{printf "%.4f %.4f %10.8f %s\n",$2,$1,$4,$5}' > $fn.xy
    
  end
  rm -rf *.tmp
  printf "  Making all grid_p???.dat files ... Done \n"
  
  
  rm -f obgridgeno obgridgenvar
    if (-e gmt.conf) rm -f gmt.conf
  if (! -d dispCurves) then
    mkdir dispCurves
  else
    rm  -rf dispCurves
    mkdir dispCurves
  endif
  
  
  @ i=1
  while ($i <= $nNod)
    printf "  Making *.disp file ($i of $nNod)      \r"
    set lon = `awk "NR==$i" nodes.yx|awk '{printf "%.4f",$2}'`
    set lat = `awk "NR==$i" nodes.yx|awk '{printf "%.4f",$1}'`
    set np  = `cat grid_p*.dat|awk -v x=$lon '$1  ~ x'|awk -v y=$lat '$2 ~ y'|wc -l`
    if ($np == $nPer) then
      cat grid_p*|awk -v x=$lon '$1  ~ x'|awk -v y=$lat '$2 ~ y'|awk '{print $3}' > data.tmp
      cat summary_p*.xy|awk -v x=$lon '$1  ~ x'|awk -v y=$lat '$2 ~ y'|awk '{print $4}' > std.tmp
      paste per.dat data.tmp std.tmp> dispCurves/X$lon-Y$lat.disp
    endif
    @ i++
  end
  printf "  Making *.disp files ...Done!       \n"
  
  
  foreach disp (`ls $homedir/$run2D/dispCurves|awk -F".disp" '{print $1}'`)
    printf "  Plotting dispersion curve at  %s  \r" $disp
    csh $plot1dDisp $homedir/$run2D/dispCurves/$disp.disp $homedir/$run2D/dispCurves/$disp.ps
  end
  printf "  Plotting dispersion curves ...Done!              \n"
  rm -f *.tmp nodes.yx per.dat
end
