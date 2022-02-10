#!/bin/csh
#This script is written to run instrument response correction of a data set. Before running this script one should run the script "respChange_step2_evaluate.csh" to have the "DataAndResponse.txt" file.
#mainDir :All the SAC files would be copied to this directory
#dataAndResponse: This file has been created by the script "respChange_step2_run.csh"
#PZfile: The pole-zero file that all the instrument responses of the sac files would change to this one.
#----Adjustable Parameters-----
set mainDir = $PWD #mainDir :All the SAC files will be copied to this directory
set dataAndResponse = DataAndResponse.txt #created by "respChange_step2_run.csh"
set PZfile = /data/CANADA-INST-RESPONSES/SAC_PZ_CMG3T
#------------------------------
#Code Block!
clear
cd $mainDir
echo "This script is written to do the Instrument Response correction of a data set and change all the final instrument responses to a specefic Pole-Zero file.\n"
set numData = `cat $dataAndResponse| wc| awk '{print $1}'`

echo " PoleZero file: $PZfile"
echo " Total number of data files: $numData\n"

@ itr = 1 
@ itrErrData = 0
@ itrErrResp = 0

echo -n " Checking all data and instResp files.....\r"
while ($itr <= $numData)
 set data = `awk NR==$itr $dataAndResponse| awk '{print $1}'`
 set resp = `awk NR==$itr $dataAndResponse| awk '{print $2}'`
 
 if (! -e $data) then
    echo " Could not find $data"
    @ itrErrData++
 endif

 if (! -e $resp) then
    echo " Could not find $resp"
    @ itrErrResp++
 endif
 @ itr++
end
echo -n " Checking all data and instResp files......Done!\n\n"

if ($itrErrResp > 0 ) then
   echo "Some instResp files are missing!\n"
   exit
else if ($itrErrData > 0) then
   echo "Some Sac files are missing!\n"
   exit
endif

echo -n " Main Directory: $mainDir\n\n WARNING! It is highly recommended to copy all the data files to the Main Directory before applying instrument response correction.\n\n Do you want to make a copy from your data set,  then apply the Instrument correction to them? (If yes, Copy this script and the DataAndResponse.txt file to a different directory and run the script again!) "
set copied = $<
if ($copied == y || $copied == yes) then
   echo -n "\n  Copying all the Sac files to the Main Directory ...\r"
   cp `cat $dataAndResponse|awk '{print $1}'` $mainDir
   echo -n "  Copying all the Sac files to the Main Directory ...Done!\n\n"
else if ($copied == n || $copied == no) then
   echo '\n WARNING! Your original SAC files will be overwritten!\n'
else
   echo '\n You entered a wrong input!\n'
   exit
endif

if ($copied == n || $copied == no) then
 echo -n " Are you sure you want to apply the instrument response correction to your original data? "
 set uans = $<
 if ($uans == y || $uans == yes) then
    echo ''
 else if ($uans == n || $uans == no) then
    echo '\n OK, You did not want to continue!\n'
    exit
 else
    echo '\n You entered a wrong input!\n'
    exit
 endif
endif 

if (-d respChange_step3) then
  rm -rf respChange_step3
  mkdir respChange_step3
else
  mkdir respChange_step3
endif


cat $dataAndResponse| awk '{print $1}'|rev|awk -F"/" '{print $1}'|rev > respChange_step3/fileName.tmp
paste respChange_step3/fileName.tmp $dataAndResponse| sed 's/\s/ /g' > respChange_step3/fnameDataResp.txt
rm -f respChange_step3/fileName.tmp

@ itr = 1
while ($itr <= $numData)
 rm -f respChange_step3/respChange.sm
 if ($copied == y || $copied == yes) then
   set data = `awk NR==$itr respChange_step3/fnameDataResp.txt| awk '{print $1}'`
 else 
   set data = `awk NR==$itr respChange_step3/fnameDataResp.txt| awk '{print $2}'`
 endif 

   set resp = `awk NR==$itr respChange_step3/fnameDataResp.txt| awk '{print $3}'`

#--Runnig sac commands---
setenv SAC_DISPLAY_COPYRIGHT 0
echo "Sac file: $itr of $numData " >>respChange_step3/respChange.log
sac>>respChange_step3/respChange.log <<ENDSAC
echo on errors warnings commands processed
SETBB data $data
SETBB resp $resp
SETBB pzfile $PZfile
r %data
transfer from evalresp fname %resp to polezero subtype %pzfile
w over
quit
ENDSAC
#------------------------
 echo "\n" >>respChange_step3/respChange.log
 echo -n "  Instrument Response Corrected: $itr of $numData          \r"
 @ itr++
end
 echo -n "  Instrument Response Corrected: $numData of $numData....Done!\n\n"



if ($copied == y || $copied == yes) then
  echo -n "  Moving all data to event folders...          \r"
  foreach data (`cat respChange_step3/fnameDataResp.txt| awk '{print $1}'`)
    set event = `echo $data|awk -F"_" '{print $1}'`
    if (-d $event) then
       mv $data $event/
    else
       mkdir $event
       mv $data $event/
    endif
  end
  echo -n "  Moving all data to event folders...Done!\n\n"
endif

echo -n "  Evaluating the number of errors...        \r"

cd respChange_step3
cat respChange.log|grep -n ERROR|awk -F":" '{print $1}' > errWord.tmp

if (! -e errWord.tmp || `cat errWord.tmp|wc|awk '{print $1}'` == 0) then
  echo -n "  Evaluating the number of errors...Done!\n\n"
  echo "The job is done without occuring any error!\n\n" 
  exit
endif

foreach errNum (`cat errWord.tmp`)
 set lin = `echo "$errNum-6"|bc`
 awk NR==$lin respChange.log|sed 's/\s/ /g'|awk '{print $3}' >> Error.tmp
end
sort -t"_" -k2 Error.tmp > Error.txt
cat Error.txt|awk -F"_" '{print $2}'|sort|uniq -c > Error_Station.tmp
@ itr = 1
@ totalErrSt = `cat Error_Station.tmp|wc|awk '{print $1}'`
while ($itr <= $totalErrSt)
  set errNum = `awk NR==$itr Error_Station.tmp|awk '{print $1}'`
  set stName = `awk NR==$itr Error_Station.tmp|awk '{print $2}'`
  set totalSt = `ls ../*/*$stName|wc|awk '{print $1}'`
  echo "$stName ($errNum of $totalSt)" >> Error_Station.txt
  @ itr++
end

echo -n "  Evaluating the number of errors...Done!\n\n  The problematic stations:\n\n"
cat Error_Station.txt
echo ''

rm -f *.tmp
