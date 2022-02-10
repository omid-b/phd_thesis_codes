#!/bin/csh
#This script automates the procedure of windowing, cutting, and bandpass filtering to all sacfiles inside event folders. Tested on Rayleigh wave two-plane-wave tomography
#Note: it requires compiled obwnd.f code (modified from wnd.f by omid.bagherpur@gmail.com)
#====Adjustable Parameters====#
set datasetdir = /data/home/omid_b/sacfiles #passbands.list should be in this dir
set stations_wildcard = 'D*.Z'
set events_wildcard = '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
set obwnd_code =  $PWD/obwnd #compiled 'obwnd.f' code 
#Note: 'obwnd.f' is modified from 'wnd.f' and reads phvel at shortest and longest periods from stinput)
#=============================#
clear
printf "This script automates the procedure of windowing, cutting, and bandpass filtering to all sacfiles inside event folders.\n\n"

#check availability
if (! -e $obwnd_code) then
  printf "Error! Could not find the compiled code!\nCheck 'Adjustable Parameters'\n\n"
  exit
endif

if (! -e $datasetdir/passbands.list) then
  printf "Error!\n Could not find 'passbands.list' in '$datasetdir'\n\n"
  exit
else
  set bp = `awk 'NR>1' $datasetdir/passbands.list|awk '{printf "%s ",$1}'`
  set nbp = `echo $bp|wc -w`
  set freq  = `awk 'NR>1' $datasetdir/passbands.list|awk '{printf "%s ",$2}'`
  set phvel = `awk 'NR>1' $datasetdir/passbands.list|awk '{printf "%s ",$4}'`
  set cf1 = `awk 'NR>1' $datasetdir/passbands.list|awk '{print $5}'|awk -F'-' '{printf "%s ",$1}'`
  set cf2 = `awk 'NR>1' $datasetdir/passbands.list|awk '{print $5}'|awk -F'-' '{printf "%s ",$2}'`
  
endif

set events = `ls $datasetdir|grep "$events_wildcard"|awk '{printf "%s ",$1}'`
set noEvt = `echo $events|wc -w`

printf " Dataset path: $datasetdir\n Number of frequency pass bands: $nbp\n Number of events: $noEvt\n\n"

printf " Do you want to continue (y/n)? "
set uans = $<
if ($uans != 'y') then
  printf "\n\nExit Program!\n\n"
  exit
else
  printf "\n"
endif


#Loop over all event folders
@ i=0
foreach evt ($events)
  @ i++
  printf "  Working on event $evt ($i of $noEvt)       \r"
  cd $datasetdir/$evt
  set stations = `ls $stations_wildcard|sort|awk '{printf "%s ",$1}'`
  cp $obwnd_code $datasetdir/$evt/wnd
  set nos = `echo $stations|wc -w`
  echo $nos $stations|sed 's/ /\n/g'> file.in
  echo $nbp $bp|sed 's/ /\n/g' > freq.in
  
#========================================================#
# Generate a modified version of sac macro 'fevlp.m' here:
set tmp = '$sta'
echo "#modified from original fevlp.m\
echo on\
setbb sta1 $stations[1]\
getbb sta1\
rh %sta1\
setbb dist &1,DIST\
setbb phvel1 $phvel[1]\
evaluate to cute %dist / %phvel1 + 800\
if %cute GT 3000\
 evaluate to cutb %cute - 3000\
else\
 evaluate to cutb 100\
endif\
\
do sta wild D*.Z\
 setbb fn1 $tmp\
 setbb fn2 %fn1%.w\
 cut %cutb %cute\
 r %fn1\
 w %fn2\
 cut off\
 xlim off\
 rmean\
 taper\
\
 do BANDP from 1 to $nbp by 1\
  r %fn2\
" > fevlp.m

printf '  if $BANDP EQ 1\n    setbb SUFIX %s%s%s\n    bp co %s %s n 4 p 2\n    w %s.p\n    envelope\n    w %s.evlp\n\n' \' $bp[1] \' $cf1[1] $cf2[1] %fn1%.%SUFIX% %fn1%.%SUFIX% >> fevlp.m

@ c=1
while ($c < $nbp)
  @ c++
  printf '  elseif $BANDP EQ %d\n    setbb SUFIX %s%s%s\n    bp co %s %s n 4 p 2\n    w %s.p\n    envelope\n    w %s.evlp\n\n' $c \' $bp[$c] \' $cf1[$c] $cf2[$c] %fn1%.%SUFIX% %fn1%.%SUFIX% >> fevlp.m
end

printf '  endif\n enddo\n   sc rm %s\nenddo\n' %fn2 >> fevlp.m
#====================================================#

#STEP1: run sac macro fevlp.m
setenv SAC_DISPLAY_COPYRIGHT 0
sac<<EOF> filtering-fevlp.log
macro fevlp.m
quit
EOF

#STEP2: run the fortran code
printf "$phvel[1]\n$phvel[$nbp]" > phvel.tmp
./wnd < phvel.tmp > filtering-wnd.log

#Generate a summary missing passbands
touch filtering-missing.log; rm -f filtering-missing.log
foreach sta ($stations)
  foreach bndp ($bp)
    if (! -e $sta.$bndp) then
      echo $sta.$bndp >> filtering-missing.log
    endif
  end
end

#remove unnecessary files:
  rm -f wnd phvel.tmp file.in freq.in fevlp.m #*.evlp *.p
end

printf "\n\n"

