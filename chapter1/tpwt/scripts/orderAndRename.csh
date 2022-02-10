#!/bin/csh
# This script does ordering and renaming steps in Two Plane Wave tomography method automatically!

cd `dirname $0`
source ../param.csh

cd $homedir

clear
echo "This script does ordering and renaming process in TPW method using provided information. (three files are required; e.g. stations.loc, events.loc, stationid.dat)"

if (! -e $staloc) then
 echo "could not find station loction info in $homedir !\n"
 exit
endif
if (! -e $evtloc) then
 echo "could not find events loction info in $homedir !\n"
 exit
endif
if (! -e $stationid) then
 echo "could not find station id info in $homedir !\n"
 exit
endif
if (! -e $softwaredir/src/dummy.sac) then
 echo "could not find dummy.sac in $softwaredir/src/ !\n"
 exit
endif

cp $softwaredir/src/dummy.sac $homedir/

rm *.tmp */*.tmp
clear
echo "This script does ordering and renaming steps in Two Plane Wave tomography method automatically!\n"

echo "dataset directory: $PWD"
echo "station location : $staloc"
echo "events location  : $evtloc"
echo "station id info  : $stationid"

echo "\nDo you want to continue making stadis files (y/n)? "
set uans=$<
if ($uans == y) then
 echo "\nProcessing..."
else
 exit
endif

ls|grep "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]">evt.tmp
set staNum = `wc -l $stationid|awk '{print $1}'`

set itr=1
while ($itr <= $staNum)
 echo $itr|awk '{printf "%02.0f\n", $1}'>> order.tmp
 @ itr++
end

setenv SAC_DISPLAY_COPYRIGHT 0

foreach evt (`cat evt.tmp`) 
 set evtLat = `cat $evtloc|grep $evt|awk '{print $3}'`
 set evtLon = `cat $evtloc|grep $evt|awk '{print $2}'`
 
 foreach sta (`cat $stationid|awk '{print $1}'`)
  set id=`cat $stationid|grep $sta|awk '{printf "N%02.0f\n",  $2}'`
  set staLat=`cat $staloc|grep $sta|awk '{print $3}'`
  set staLon=`cat $staloc|grep $sta|awk '{print $2}'`
sac<<ENDSAC
 r dummy.sac
 ch stla $staLat
 ch stlo $staLon
 ch evla $evtLat
 ch evlo $evtLon
 wh
q
ENDSAC
 set dist = `saclst DIST f dummy.sac|awk '{printf "%.1f", $2}'`
 echo $sta $id $dist>> $evt/dist.tmp
 end
 cat $evt/dist.tmp|sort -nk3 > $evt/dist2.tmp
 rm -f $evt/dist.tmp; mv $evt/dist2.tmp $evt/dist.tmp
 paste $evt/dist.tmp order.tmp|awk '{printf "%4s%6s %.1f %4s\n", $1,$2, $3, $4}'|sort -k2 > $evt/stadis
end


echo "\nAll stadis files has been created!\n"
#Up to this point The script only has created the stadis file!

echo "\nDo you want to start renaming process (y/n)? "
set uans=$<
if ($uans == y) then
 echo "\nProcessing..."
else
 exit
endif

foreach evt (`cat evt.tmp`)
 cd $evt
 ls *HZ|sort|uniq> data.tmp

 foreach z (`cat data.tmp`)
   set sta=`echo $z|awk -F"_" '{print $2}'|awk -F"." '{print $1}'`
   set stid=`grep $sta stadis|awk '{print $2}'`
   set order=`grep $sta stadis|awk '{print $4}'`
   set new=`echo "D$order.$stid.$sta.Z"`
   mv $z $new
 end

 cd ..
end

rm -f *.tmp */*.tmp $homedir/dummy.sac
echo "\nAll files have been successfully renamed!\n"
