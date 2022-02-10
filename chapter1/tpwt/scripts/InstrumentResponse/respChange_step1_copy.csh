#!/bin/csh
#This script is written to search and copy all the required instrument response files from the archive to a temporary folder.
#Note: If you already have all the required instrument response files in a folder, skip running this script and go to step2!
#Update: 13 Oct 2017
#------Adjustable parameters---------
set dataDir = $PWD   #sac data files renamed to format yyjjjhhmmss_stationName.component
set SAC_file_format = '?H?'
set respDir = /data/CANADA-INST-RESPONSES #instrument response archive directory full path
#------------------------------------
clear
cd $dataDir
echo "This script is written to copy all the required instrument response files from the archive to a temporary folder.\n"
if (-d respChange_step1) rm -rf respChange_step1
mkdir respChange_step1

#--creating info files--
ls -d */ |awk -F"/" '{print $1}'| grep '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' > respChange_step1/evtFolders.txt
foreach event (`cat respChange_step1/evtFolders.txt`)
 cd $event
 ls $event*>> $dataDir/respChange_step1/allSACfiles.txt
 cd ..
end

cat $dataDir/respChange_step1/allSACfiles.txt|rev|awk -F"." '{print $1}'|rev|sort|uniq > respChange_step1/uniqComponents.txt
cat $dataDir/respChange_step1/allSACfiles.txt|awk -F"_" '{print $2}'|sort|uniq  > respChange_step1/stations.comp.txt

find $respDir -type f|sort|uniq>>respChange_step1/RespDirAllFiles.txt
foreach stnComp (`cat respChange_step1/stations.comp.txt`)
 set stn  = `echo $stnComp| awk -F"." '{print $1}'`
 set comp = `echo $stnComp| awk -F"." '{print $2}'`
 set nFound = `cat respChange_step1/RespDirAllFiles.txt |rev|awk -F"/" '{print $1}'|rev| grep $stn|grep $comp|wc| awk '{print $1}'`
 if ($nFound > 0) then
  cat respChange_step1/RespDirAllFiles.txt|grep \\.$stn\\.|grep $comp >> respChange_step1/availableRespFiles.txt
 else
  echo $stnComp >> respChange_step1/unavailableRespFiles.txt
 endif
 
 if ($nFound > 1) then
  echo $stn >> respChange_step1/conflictRespFiles_stations.txt
 endif 
end

#---------------------
set numUnavailableRespFiles = `cat respChange_step1/unavailableRespFiles.txt|wc|awk '{print $1}'`
set numConflictRespFiles_stations = `cat respChange_step1/conflictRespFiles_stations.txt|wc|awk '{print $1}'`
set numAvailableRespFiles = `cat respChange_step1/availableRespFiles.txt|wc|awk '{print $1}'` 

set numComponents = `cat respChange_step1/uniqComponents.txt|wc|awk '{print $1}'`
set numStations  = `cat respChange_step1/stations.comp.txt |awk -F"." '{print $1}'|wc|awk '{print $1}'`
set numEvtFolders = `cat respChange_step1/evtFolders.txt|wc|awk '{print $1}'`

echo " Main directory: $dataDir"; echo " Main directory: $dataDir" >>respChange_step1/log.txt
echo " Number of found stations: $numStations"; echo " Number of found stations: $numStations" >>respChange_step1/log.txt
echo " Number of found components: $numComponents"; echo " Number of found components: $numComponents" >>respChange_step1/log.txt
echo " Found components:" `cat respChange_step1/uniqComponents.txt`; echo " Found components:" `cat respChange_step1/uniqComponents.txt` >>respChange_step1/log.txt

echo "\n Response files archive directory: $respDir"; echo "\n Response files archive directory: $respDir">>respChange_step1/log.txt
echo " Number of found response files: $numAvailableRespFiles"; echo " Number of found response files: $numAvailableRespFiles">>respChange_step1/log.txt
echo " Number of response files which this script could not find: $numUnavailableRespFiles"; echo " Number of response files which this script could not find: $numUnavailableRespFiles" >>respChange_step1/log.txt
echo " Number of conflicted response files: $numConflictRespFiles_stations"; echo " Number of conflicted response files: $numConflictRespFiles_stations" >>respChange_step1/log.txt

if ($numUnavailableRespFiles == 1) then
   echo "\n Could not find response file for a station:\n   `cat respChange_step1/unavailableRespFiles.txt`"
   echo "\n Could not find response file for a station:\n   `cat respChange_step1/unavailableRespFiles.txt`" >>respChange_step1/log.txt
else if ($numUnavailableRespFiles > 1) then
   echo "\n Could not find response files for several stations:\n   `cat respChange_step1/unavailableRespFiles.txt`"
   echo "\n Could not find response files for several stations:\n   `cat respChange_step1/unavailableRespFiles.txt`" >>respChange_step1/log.txt
endif

if ($numConflictRespFiles_stations == 1) then
   echo " More than one response file found for a station:\n   `cat respChange_step1/conflictRespFiles_stations.txt`\n"
   echo " More than one response file found for a station:\n   `cat respChange_step1/conflictRespFiles_stations.txt`\n">>respChange_step1/log.txt
else if ($numConflictRespFiles_stations > 1) then
   echo " More than one response file found for several stations:\n   `cat respChange_step1/conflictRespFiles_stations.txt`\n"
   echo " More than one response file found for several stations:\n   `cat respChange_step1/conflictRespFiles_stations.txt`\n" >>respChange_step1/log.txt
endif

echo -n "\nDo you want to copy all the $numAvailableRespFiles available response files (y/n)? "
set ansin = $<
if ($ansin == y || $ansin == yes) then
   echo ''
   echo -n " Copying response files ...\r"
   mkdir respChange_step1/AvailableResponses
   cp `cat respChange_step1/availableRespFiles.txt` respChange_step1/AvailableResponses
   echo -n " Copying response files ...Done!\r\n"
   echo "    All the available response files copied to:\n    $dataDir/respChange_step1/AvailableResponses\n"
else if ($ansin == n || $ansin == no) then
   echo 'OK, You did not want to continue!\n'
   exit
else
   echo 'You entered a wrong input!\n'
   exit
endif

echo "Please, modify (add/remove) all instrument response files and move them all to a folder. Then you can run 'respChange_step2.csh' after adjusting the 'Adjustable Parameters' sectionfun to apply instrument response correction.\n"
echo "Please, modify (add/remove) all instrument response files and move them all to a folder. Then you can run 'respChange_step2.csh' after adjusting the 'Adjustable Parameters' sectionfun to apply instrument response correction.\n" >>respChange_step1/log.txt


