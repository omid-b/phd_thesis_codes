#!/bin/csh
#This script is written to decimate any sac files within the event directories of a data folder (BH1, BH2, BHE, BHN, BHZ, ..., HHZ, SAC). 
#The sampling frequncy of the original files can be up to 49 times higher than the desired sampling frequency. (requirements: csh, bc, SAC)
#HINT! If you want to decimate a 100sample/sec sac file into a 1samp/sec (more than 49 times lower) run the script twice! e.g. First decimate it to 10samp/sec and the second time to 1samp/sec.
#Last edit: june 19, 2018.


cd `dirname $0`
source ../param.csh

#------Change this part if necessary!----#
ls 1*/*{BH,HH}{Z,E,N,1,2}* > datalist.tmp
#----------------------------------------#

clear
echo "This script will do the resampling process of your sac files\n"
echo "dataset directory:  $homedir\n"

echo -n "\nDo you want to continue (y/n)? "
set ansin = $<
if ($ansin == y || $ansin == yes) then
   echo ''
else if ($ansin == n || $ansin == no) then
   echo 'OK, You did not want to continue!\n'
   exit
else
   echo 'You entered a wrong input!\n'
   exit
endif

if (-e saclist.info) then
   echo "The 'saclist.info' is already existed! recreating the file..."   
   rm -f saclist.info
else
   echo "Creating sac file list..."
endif

saclst delta f `cat datalist.tmp` > saclist.info
if (-e datalist.tmp) rm -f datalist.tmp

if (-e saclist.info) then
   echo "'saclist.info' has been created successfully!\n This file contains the information of original sac files 'delta' header."
   set num_sac = `wc -l < saclist.info`
   set num_fs = `awk -F" " '{print $2}' < saclist.info |fmt -1|sort -n|uniq|wc -l`
   echo "\nTotal number of sac files: $num_sac \nNumber of sampling frequencies: $num_fs"
else 
   echo "Error! couldn\'t create the 'saclist.info file! check your defined homedir parameter."
   exit
endif

echo -n "Available sampling frequencies:  "
foreach uniqDelta (`awk -F" " '{print $2}' < saclist.info |fmt -1|sort -n|uniq`)
set tmp = `echo "scale=1; $uniqDelta ^ (-1)"|bc`
echo -n "$tmp  "
unset tmp
end

echo -n "\nChoose your desired sampling frequency (10,20, ...)? "
set desired_fs = $<
echo ''
#----------------------------
#(start) Doing the signal decimation
#----------------------------
@ itr = 0
if (-e error.log) rm -f error.log #removing  error log file if it is already exist!

#(start) working on each data file in a for loop:
foreach delta (`awk -F" " '{print $2}' < saclist.info`)
  
  @ itr++
  unset sacfile fs r1 d1
  set sacfile = `awk -F" " '{print $1}' < saclist.info|awk NR==$itr`
  set fs = `echo "scale=0; $delta^(-1)" | bc`
  set r1 = `echo "scale=0; $fs%$desired_fs"|bc`
  set d1 = `echo "scale=0; $fs/$desired_fs"|bc`
  echo -n "Working on file $itr of $num_sac... \r"
  
if ($r1 == 0 && $d1 > 1) then

setenv SAC_DISPLAY_COPYRIGHT 0

   if ($d1 >= 2 && $d1 <= 7) then
sac <<ENDSAC
   r $sacfile
   decimate $d1
   w over
   q
ENDSAC
   else if ($d1 == 8 || $d1 == 10 || $d1 == 12 || $d1 == 14) then
   set d2 = `echo "scale=0; $d1/2"|bc`
sac <<ENDSAC
   r $sacfile
   decimate 2
   decimate $d2
   w over
   q
ENDSAC
   else if ($d1 == 9 || $d1 == 15 || $d1 == 18 || $d1 == 21) then
      set d2 = `echo "scale=0; $d1/3"|bc`
sac <<ENDSAC
   r $sacfile
   decimate 3
   decimate $d2
   w over
   q
ENDSAC
   else if ($d1 == 16 || $d1 == 20 || $d1 == 24 || $d1 == 28) then
      set d2 = `echo "scale=0; $d1/4"|bc`
sac <<ENDSAC
   r $sacfile
   decimate 4
   decimate $d2
   w over
   q
ENDSAC
   else if ($d1 == 25 || $d1 == 30 || $d1 == 35) then
      set d2 = `echo "scale=0; $d1/5"|bc`
sac <<ENDSAC
   r $sacfile
   decimate 5
   decimate $d2
   w over
   q
ENDSAC
   else if ($d1 == 36 || $d1 == 42) then
      set d2 = `echo "scale=0; $d1/6"|bc`
sac <<ENDSAC
   r $sacfile
   decimate 6
   decimate $d2
   w over
   q
ENDSAC
   else if ($d1 == 49) then
sac <<ENDSAC
   r $sacfile
   decimate 7
   decimate 7
   w over
   q
ENDSAC
   else
      echo "Error! Couldn't decimate $sacfile !"
      echo $sacfile >> error.log 
   endif
   
else 
        echo "Error! Couldn't decimate $sacfile !"
        echo $sacfile >> error.log

endif

end
echo -n '\n'
#(end) working on each data file in a for loop
#---------------------
if (-e "checklist.info") rm -f "checklist.info"
echo "\nCreating a check list file (checklist.info)..."
saclst delta f `awk -F" " '{print $1}' < saclist.info` > "checklist.info"
if (-e "checklist.info") echo "'checklist.info' has been created successfully!\n This file contains the information of new sac files 'delta' header."
if (-e 'error.log') then
 echo "\n The job is done with several errors (error.log)! \n"
else
 echo "\n The job is done without any error! \n"
endif
