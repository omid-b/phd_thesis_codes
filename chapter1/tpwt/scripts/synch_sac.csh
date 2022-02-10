#!/bin/csh
#This script is written to read and synchronize all the sac files of each event directory.

cd `dirname $0`
source ../param.csh

clear
echo "This script is written to synchronize all the SAC data files inside the event directories (yyjjjhhmmss).\n\n"

cd $homedir
if (-d synch_sac) then
 rm -rf synch_sac
 mkdir synch_sac
else
 mkdir synch_sac
endif

echo -n "  Acquiring some information ...       \r"

cd $homedir

ls|grep "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]" > synch_sac/evtList.txt
file */*|awk '{print $1,$2}'|cut -d" " -f 1-2|grep -w data|awk -F":" '{print $1}'|grep -v bbf|rev|awk -F"." '{print $1}'|rev|sort|uniq > synch_sac/channels.txt 

set numEvt = `cat synch_sac/evtList.txt|wc|awk '{print $1}'` #Number Of Event directories
set numChannels = `cat synch_sac/channels.txt|wc|awk '{print $1}'`
echo -n "  Acquiring some information ...Done!       \n\n"


echo "  Main directory: $homedir\n  Number of events: $numEvt\n  $numChannels Channel(s) Found: `cat synch_sac/channels.txt `"
echo -n "\n  WARNING! You can not undo the following procedure.\n Do you want to continue? "
set uans = $<
if ($uans == y || $uans == yes) then
   echo ''
else if ($uans == n || $uans == no) then
   echo '\nOK, You did not want to continue!\n'
   rm -rf synch_sac
   exit
else
   echo '\nYou entered a wrong input!\n'
   rm -rf synch_sac
   exit
endif


saclst o b t1 kztime f `ls $homedir/*/*Z` > synch_sac/checklist_before.txt


@ itr = 1
while ($itr <= $numEvt )
 set evt = `awk NR==$itr synch_sac/evtList.txt`
 cd $evt
 echo -n " Synchronizing event $itr of $numEvt      \r"

 foreach data (`ls $homedir/*/*Z`)
#--Runing sac macro--
setenv SAC_DISPLAY_COPYRIGHT 0
sac <<ENDSAC
echo ON ERRORS WARNINGS
setbb data $data
r %data
synchronize r on
setbb otime &1,o
evaluate to cotime %otime*(-1)
ch ALLT %cotime IZTYPE IO
wh
quit
ENDSAC
#-------------------
 end
 @ itr++
 cd ..
end

echo -n " Synchronizing event $numEvt of $numEvt......Done!\n\n"
saclst o b t1 kztime f `ls $homedir/*/*Z` > synch_sac/checklist_after.txt

