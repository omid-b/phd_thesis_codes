#!/bin/csh/
#run TPW inversion for availabe sets of filelists to make dispersion curves/data at all nodal points.
#Used parameters in 'param.csh': homedir, softwaredir, grid, passbands, stationid

cd `dirname $0`
source ../param.csh

set code = $softwaredir/bin/simannerr1
set plot1d = $softwaredir/scripts/plot_1dDisp.gmt
set period = `awk 'NR>1' $passbands|awk '{printf "%03.0f ", $3}'`

cd $homedir
set code_file = `echo $code|rev|awk -F"/" '{print $1}'|rev`
rm *sa1 *.log phamp_???
clear 
echo "This script runs 1D TPW inversion for availabe sets of filelists to make a 1D average dispersion curve (Kernels are not used)...\n"

echo "homedir: $homedir"
echo "softwaredir: $softwaredir"
echo "grid: $grid"
echo "passbands: $passbands"
echo "stationid: $stationid"

ls filelists|grep filelists_|grep -v tmp > filelists.tmp
set filelistsNum = `cat filelists.tmp|wc -l`
set phampNum = `ls phamps|grep "phamps_"|wc -l`

#check if the required codes are available
if (! -e $code) then
  echo "\nCould not find $code!\n"
  rm *.tmp
  exit
else if (`echo "$phampNum == 0"|bc` == 1) then
  echo "\nCould not find Phase&Amp folder(s)!\n"
  rm *.tmp
  exit
else if (`echo "$filelistsNum == 0"|bc` == 1) then 
  echo "\nCould not find filelist folder(s)!\n"
  rm *.tmp
  exit
endif
#------




echo "Number of filelists: $filelistsNum\n"


echo -n "\nDo you want to continue (y/n)? "
set uans = $<
if ($uans == 'y') then
  echo " "
else
  exit
endif


cp $code .
foreach filelist (`cat filelists.tmp`)
  set runset=`echo $filelist|cut -d"_" -f2-99`
  set smth = `echo $runset|awk -F"st" '{print $2}'|awk -F"km" '{print $1}'`
  echo "working on filelists_$runset"
  foreach per ($period)
    cp phamps/phamps_$runset/phamp_p$per .
#    cp $kernels/smooth_$smth/p$per.kern .
    printf "  Running 1D inversion on period $per\r"
    $code_file < filelists/filelists_$runset/filelist.p$per > p$per.log
    rm -f phamp_p$per
    if (-e followit12) mv followit12 followit12.p$per
  end
  if (! -d run1D_$runset) then
   mkdir run1D_$runset
  else
   rm -rf run1D_$runset
   mkdir run1D_$runset
  endif
  
  mv *sa1 *.log followit12* run1D_$runset
  cp filelists/$filelist/* $homedir/run1D_$runset
  
  foreach summary (`ls $homedir/run1D_$runset/|grep  summary|grep .sa1`)
    set per = `echo $summary|awk -F"_p" '{print $2}'|awk -F"." '{print $1}'`
    set vel = `tail -n1 $homedir/run1D_$runset/$summary|awk '{print $1}'`
    echo $per $vel >> $homedir/run1D_$runset/average_$runset.disp
  end
  

  
  

  csh $plot1d $homedir/run1D_$runset/average_$runset.disp $homedir/run1D_$runset/average_$runset.ps
  ps2pdf $homedir/run1D_$runset/average_$runset.ps $homedir/run1D_$runset/average_$runset.pdf
  printf "  Running 1D inversion ...Done!       \n\n"
end

echo "Complete!\n"
rm -f phamp_???  *.tmp $code_file
