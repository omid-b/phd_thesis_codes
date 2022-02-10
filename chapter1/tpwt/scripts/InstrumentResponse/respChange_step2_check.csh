#!/bin/csh
#
#----Adjustable Parameters-----
set dataDir = $PWD
set respDir = /data/home/bagherpur_o/Instrument-Responses
#------------------------------
#Code Block!
clear
cd $dataDir
#-----Creating allResp.info file---
echo "This script is written to check the availability of instrument response data from the provided Instrument Response data folder. This script evaluates all the dates and times (Start and End instrument operation time, Event time) to create a list of data and it's suitable instrument response file (dataAndResponse.txt) which will make applying the instrument response correction much easier.\n"

echo " Data directory: $dataDir\n Instrument responses: $respDir\n"
echo -n " Acquiring instrument response information ...\r"
if (-d respChange_step2_temp1) rm -rf respChange_step2_temp1
if (-d respChange_step2) rm -rf respChange_step2
mkdir respChange_step2_temp1
grep -rnw $respDir -e "Station:"|grep -v respDir| awk '{print $3}'|sed 's/\s//g' >respChange_step2_temp1/Station.tmp
grep -rnw $respDir -e "Station:"|grep -v respDir| awk -F":" '{print $1}' >respChange_step2_temp1/files.tmp
grep -rnw $respDir -e "Network:"|grep -v respDir| awk '{print $3}' >respChange_step2_temp1/Network.tmp
grep -rnw $respDir -e "Channel:"|grep -v respDir| awk '{print $3}' |sed 's/\s//g' >respChange_step2_temp1/Channel.tmp
grep -rnw $respDir -e "Start date:"|grep -v respDir| awk '{print $4}' >respChange_step2_temp1/Start.tmp0
grep -rnw $respDir -e "End date:"|grep -v respDir| awk '{print $4}' >respChange_step2_temp1/End.tmp


paste respChange_step2_temp1/Station.tmp respChange_step2_temp1/Channel.tmp|sed 's/\s/\./g'> respChange_step2_temp1/StationChannel.txt

set numFound = `cat respChange_step2_temp1/Station.tmp|wc|awk '{print $1}'`
@ itr = 1
while ($itr <= $numFound)
 echo '0000000000000' >>respChange_step2_temp1/zeros.tmp
 
 #Changing all the start times before year 2000 to the begining of 2000
 set startTimeYear = `awk NR==$itr respChange_step2_temp1/Start.tmp0| awk -F"," '{print $1}'`
 if ($startTimeYear < 2000) then
   echo '2000,001,00:00:00' >> respChange_step2_temp1/Start.tmp
 else
   awk NR==$itr respChange_step2_temp1/Start.tmp0 >> respChange_step2_temp1/Start.tmp
 endif

 @ itr++
end

#----------------------------------------------------
paste respChange_step2_temp1/Start.tmp respChange_step2_temp1/zeros.tmp|sed 's/\s//g'|sed 's/\,//g'|sed 's/\://g'|sed 's/\.//g'|cut -c 3-13 > respChange_step2_temp1/START.txt
paste respChange_step2_temp1/End.tmp respChange_step2_temp1/zeros.tmp|sed 's/No/2599365235959/g'|sed 's/\s//g'|sed 's/\,//g'|sed 's/\://g'|sed 's/\.//g'|cut -c 3-13 > respChange_step2_temp1/END.txt

mkdir respChange_step2
paste respChange_step2_temp1/StationChannel.txt respChange_step2_temp1/Network.tmp respChange_step2_temp1/START.txt respChange_step2_temp1/END.txt respChange_step2_temp1/files.tmp|sed 's/\r//g'|sed 's/\s/ /g'|sort|uniq> respChange_step2/allResp.info
#---------------------------------
#---Making available response list in temp2 folder----

if (-d respChange_step2_temp2) rm -rf respChange_step2_temp2
mkdir respChange_step2_temp2
ls */* |grep -v respChange_step2|awk -F"/" '{print $2}'|awk -F"_" '{print $2}'|sort|uniq|grep '\S' > respChange_step2_temp1/StationChannel_dataUniq.txt
set numStationChannel = `cat respChange_step2_temp1/StationChannel_dataUniq.txt|wc|awk '{print $1}'`

@ itr = 1
@ errItr = 0
while ($itr <= $numStationChannel)
 
 set StCh = `awk NR==$itr respChange_step2_temp1/StationChannel_dataUniq.txt`
 cat respChange_step2/allResp.info| grep $StCh >  respChange_step2_temp2/$StCh

 @ itr++
end
#--------------------------------------------
echo -n " Acquiring instrument response information ...Done!\n"
echo -n " Converting all the reformatted times to seconds ...\r"
#---Time conversion (to  seconds)---

ls -d */ |awk -F"/" '{print $1}'|grep -v  respChange_step2 > respChange_step2/Events.txt
cat respChange_step2/Events.txt respChange_step2_temp1/END.txt respChange_step2_temp1/START.txt| sort| uniq > respChange_step2_temp1/TimeConversion.tmp1
set numTime = `cat respChange_step2_temp1/TimeConversion.tmp1|wc|awk '{print $1}'`

@ itr = 1
while ($itr <= $numTime)
 set yy  = `awk NR==$itr respChange_step2_temp1/TimeConversion.tmp1| cut -c 1-2`
 set jjj = `awk NR==$itr respChange_step2_temp1/TimeConversion.tmp1| cut -c 3-5`
 set hh  = `awk NR==$itr respChange_step2_temp1/TimeConversion.tmp1| cut -c 6-7`
 set mm  = `awk NR==$itr respChange_step2_temp1/TimeConversion.tmp1| cut -c 8-9`
 set ss  = `awk NR==$itr respChange_step2_temp1/TimeConversion.tmp1| cut -c 10-11`

 set SECONDS = `echo "$yy*31557600 + ($jjj-1)*86400 + $hh*3600 + $mm*60 + $ss"|bc`
 echo $SECONDS >> respChange_step2_temp1/TimeConversion.tmp2
 @ itr++
end

paste respChange_step2_temp1/TimeConversion.tmp1 respChange_step2_temp1/TimeConversion.tmp2| sed 's/\s/ /g' >respChange_step2_temp1/TimeConversion.txt
rm -f respChange_step2_temp1/TimeConversion.tmp1 respChange_step2_temp1/TimeConversion.tmp2
#----------------------------------
echo -n " Converting all the reformatted times to seconds ...Done!\n"
#--Checking the availablity of response data for the data set--
set numEvt = `cat respChange_step2/Events.txt|wc|awk '{print $1}'`
@ itrEvt =0
foreach evt (`cat respChange_step2/Events.txt`)
 @ itrEvt++
 cd $evt
 echo -n " Checking the availablity of response data (Event: $itrEvt of $numEvt)   \r"
 set evtTime = `cat $dataDir/respChange_step2_temp1/TimeConversion.txt|grep $evt|awk '{print $2}'`
 
 foreach data (`ls $evt*`)
  echo $dataDir/$evt/$data >> $dataDir/respChange_step2/allData.txt
  set StCh = `echo $data| awk -F"_" '{print $2}'`
  set numResp = `cat $dataDir/respChange_step2_temp2/$StCh |wc| awk '{print $1}'`
  @ itr = 1
  while ($itr <= $numResp)
    set startRespTemp = `awk NR==$itr $dataDir/respChange_step2_temp2/$StCh|awk '{print $3}'`
    set endRespTemp   = `awk NR==$itr $dataDir/respChange_step2_temp2/$StCh|awk '{print $4}'`
    
    set startRespTime = `cat $dataDir/respChange_step2_temp1/TimeConversion.txt|grep $startRespTemp|awk '{print $2}'`
    set endRespTime   = `cat $dataDir/respChange_step2_temp1/TimeConversion.txt|grep $endRespTemp|awk '{print $2}'`
    
    if ($evtTime >= $startRespTime && $evtTime <= $endRespTime) then 
       set OKRespFile = `awk NR==$itr $dataDir/respChange_step2_temp2/$StCh|awk '{print $5}'`
       echo "$dataDir/$evt/$data $OKRespFile">> $dataDir/respChange_step2/DataAndResponse.tmp
    endif

  @ itr++
  end

 if (`cat $dataDir/respChange_step2/DataAndResponse.tmp|grep $data|wc|awk '{print $1}'` == 0) then
     echo "Could not find Response data for $data !          "
     echo "Could not find Response data for $data !          " >> $dataDir/respChange_step2/Error.txt
 endif

 end 


 
 cd $dataDir
end
echo -n " Checking the availablity of response data (Event: $numEvt of $numEvt) ...Done !\n\n"

cat $dataDir/respChange_step2/DataAndResponse.tmp|sort|uniq > $dataDir/respChange_step2/DataAndResponse.txt
rm -f $dataDir/respChange_step2/DataAndResponse.tmp

if (-e $dataDir/respChange_step2/Error.txt) then
   echo " Some instrument response data are missing!\n (see Error.txt)\n"
   rm -rf $dataDir/respChange_step2_temp1 $dataDir/respChange_step2_temp2
   exit
else
   echo " All the required instrument response data are available!\n (see DataAndResponse.txt)\n"
endif

echo " allResp.info gives useful information about instrument response data:\n <Station.Channel Network StartDate EndDate ResponseData>\n"
#-----------------------------------------------------------
rm -rf $dataDir/respChange_step2_temp1 $dataDir/respChange_step2_temp2
echo "Use DataAndResponse.txt file for the next step (respChange_step3_run.csh)\n"
