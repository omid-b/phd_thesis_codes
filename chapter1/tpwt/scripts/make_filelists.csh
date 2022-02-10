#!/bin/csh
#This script is a modified version of 'mk_filelists.csh'. It automates making filelists for different kernels (e.g. smooth_40 etc) which are kept in a folder 
#Usage: First, please modify 'param.csh'
#UPDATE: Oct 18, 2018

cd `dirname $0`
source ../param.csh

clear
cd $homedir


cd $homedir
set numEvt = `ls|grep "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"|wc -l`
printf "This script automates making filelists for different inversion parameters.\n\nDataset directory:\n    $homedir\n\nNumber of events:  $numEvt\nGrid's file name: $grid\nMin number of stations: $minstns\nInversion Parameters:\n   iter = $iter, dampvel = $dampvel, dampanis = $dampanis\n   charactristic lengths/smoothing (km): "
printf "%s  " $smoothing

if (-e passbands.list) then
 echo " "
else
 echo "\nCould not find 'passbands.list' in $homedir! EXIT script.\n"
 exit
endif

#'echo "$nrun1D == 0"|bc` == 1

printf "\nDo you want to continue (Y/N)? "
set uans = $< 
if ($uans == 'yes' ||$uans == 'YES' ||$uans == 'Y' ||$uans == 'y') then
 echo ""
else
 echo "\n\n Wrong input! EXIT script.\n"
 exit
endif

if (! -d filelists) then
  mkdir filelists
endif

foreach smth ($smoothing)
 
 set setname = `echo $minstns-st$smth-km_itr$iter-dampV$dampvel-A$dampanis|sed 's/-//g'`


 foreach bp (`awk 'NR>1' passbands.list|awk '{printf "%s ",$1}'`)

 printf "  Making filelist: filelists_$setname\r"
  grep -w $bp $homedir/passbands.list > tmp
  set freq=`awk '{print $2}' tmp`
  set period=`awk '{print $3}' tmp`
  
  if (-d run1D_$setname) then
    set phasevel = `cat run1D_$setname/average*.disp|grep -w $period|awk '{print $2}'`
  else
    set phasevel=`awk '{print $4}' tmp`
  endif


#---'orderfilelist.csh'---#
   ls $homedir | grep "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"> evtlist

   set numevts=0
   set evtno=0
   if (-e temp1) rm -f temp1
   if (-e temp2) rm -f temp2

   foreach event (`cat evtlist`)

   if (`ls $event|rev|awk -F"." '{print $1}'|rev|sort|uniq|grep $bp` == $bp) then
     set nostns=`ls $event/*.$bp | wc -l`
   else
     set nostns = 0
   endif

   if ($nostns >= $minstns) then
     set evtno=`expr $evtno + 1`
     echo "$nostns $evtno" >> temp2
#     echo "$nostns" >> temp2
     #ls $PWD/$event/*.$bp >> temp2
     ls ./$event/*.$bp >> temp2
     set numevts=`expr $numevts + 1`
   endif
   
   end

    echo "$numevts" > temp1
    cat temp1 temp2 > filelist.bp
    rm evtlist temp1 temp2
#--------------------------#
  echo "1" >> filelist.bp
  echo $freq >> filelist.bp
  #echo "detail_p"$period >> filelist.bp
  #echo "summary_p"$period >> filelist.bp
  echo "detail_p"$period-$smth-$dampvel >> filelist.bp
  echo "summary_p"$period-$smth-$dampvel >> filelist.bp
  echo "$grid"|rev|awk -F/ '{print $1}'|rev >> filelist.bp
  echo "phamp_p"$period >> filelist.bp
  #echo "covar_p"$period >> filelist.bp
  echo "covar_p"$period-$smth-$dampvel >> filelist.bp
  #echo "mavamp_"$period >> filelist.bp
  #echo "resmax_"$period".dat" >> filelist.bp
  #echo "velarea_"$period >> filelist.bp
  #echo $iter $length $dampvel $dampanis $dum >> filelist.bp
  echo $iter $smth $dampvel $dampanis $phasevel >> filelist.bp
  #echo $phasevel >> filelist.bp
  #echo ./$senskern >> filelist.bp
  echo p$period.kern >> filelist.bp  
  mv filelist.bp filelist.p$period

 end
 
 if (! -d filelists/filelists_$setname) then
   mkdir filelists/filelists_$setname
 else
   rm -rf filelists/filelists_$setname
   mkdir filelists/filelists_$setname
 endif
 
 mv filelist.* filelists/filelists_$setname

@ i1++ 
end
printf "  Making filelists .......Done!                                \n"
echo "\n All filelists have been created!\n\n"
rm -f *tmp
