#!/bin/csh/
#perform 2D TPW inversion (using sens kernels) for availabe sets of filelists to make dispersion curves/data at all nodal points.
#Used parameters in 'param.csh': homedir, softwaredir, grid, passbands, stationid

cd `dirname $0`
source ../param.csh

set code = $softwaredir/bin/simannerr13.kern
set period = `awk 'NR>1' $passbands|awk '{printf "%03.0f ", $3}'`

cd $homedir
set code_file = `echo $code|rev|awk -F"/" '{print $1}'|rev`
rm *sa*kern *.log phamp_p???
clear 
echo "This script performs 2D TPW inversion (using sens kernels) for availabe sets of filelists to make dispersion curves/data at all nodal points..\n"

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


printf "\nDo you want to continue (y/n)? "
set uans = $<
if ($uans == 'y') then
  echo " "
else
  exit
endif


cp $code .
foreach filelist (`cat filelists.tmp`)
  set setname=`echo $filelist|cut -d"_" -f2-99`
  set smth = `echo $setname|awk -F"st" '{print $2}'|awk -F"km" '{print $1}'`
  echo "working on filelists_$setname"
  foreach per ($period)
    cp phamps/phamps_$setname/phamp_p$per . ; cp kernels/kernels_$setname/p$per.kern .
    printf "  Running inversion on period $per      \r"
    $code_file < filelists/filelists_$setname/filelist.p$per > p$per.log
    rm -f phamp_p$per p$per.kern
    if (-e followit12) mv followit12 followit12.p$per
  end
  if (! -d run2Dkern_$setname) then
   mkdir run2Dkern_$setname
  else
   rm -rf run2Dkern_$setname
   mkdir run2Dkern_$setname
  endif
  mv *sa??kern *.log followit12* run2Dkern_$setname
  cp filelists/$filelist/* run2Dkern_$setname

  printf "  Running inversion ...Done!                   \n\n"
end

echo "Completed!\n"
rm -f phamp_p??? p???.kern *.tmp $code_file
