#!/bin/csh
# This script generates profile data along tracks using GMT.
# The profile xy tracks could be obtained using the 'make-profile.py' code
# I suggest gridding the geographical datasets using the 'gridder.f' code.
#=====Adjustable Parameters=====#
set output_folder = results
#===============================#
clear
printf "This script generates profile data along tracks using GMT.\n\n"

if ($#argv < 2) then
  printf "Error!\n USAGE: csh extract-profileData.csh <profiles> <dataset 1> ... <dataset n>\n\n"
  exit
endif

printf "  Checking inputs ...\r"
@ i=0
while ($i < $#argv)
  @ i++
  if (! -e $argv[$i]) then
    printf 'Error!\n Could not find the input file: "%s"\n\n' $argv[$i]
    exit
  else if ($i > 1) then
  	set ncol = `awk '{print NF}' $argv[$i]|sort -n|head -n1`
  	if ($ncol < 3) then
      printf "\n\nError reading '%s'\n The scattered datasets should have at least three columns!\n\n" $argv[$i]
      exit
  	endif
  endif
end 

foreach track (`cat $argv[1]`)
  if (! -e $track) then
    printf 'Error!\n Could not find the profile track: "%s"\n\n' $track
    exit
  endif
end
printf "  Checking inputs ... Done!\n"

#make output directory
if (-d $output_folder) then
  rm -rf $output_folder
  mkdir $output_folder
else
  mkdir $output_folder
endif

printf "  Copying data ...\r"
@ i=0
foreach track (`cat $argv[1]`)
  @ i++
  set id = `printf '%04d' $i`
  cp $track $output_folder/track_$id.dat
end

@ i=1
while ($i < $#argv)
  @ i++
  set id = `echo $i|awk '{printf "%04d",$1-1}' `
  cp $argv[$i] $output_folder/dataset_$id.dat
end
printf "  Copying data ...... Done!\n"

cd $output_folder
#Gridding
set noGrd = `echo $#argv|awk '{print $1-1}'`
printf "  Gridding ...\r"
@ i=0
foreach data (`ls |grep dataset`)
  @ i++
  printf "  Gridding ... $i of $noGrd\r"
  set id = `printf '%04d' $i`
  set lon1 = `awk '{print $1}' $data|sort -n |uniq|head -n1`
  set lon2 = `awk '{print $1}' $data|sort -nr|uniq|head -n1`  
  set lat1 = `awk '{print $2}' $data|sort -n |uniq|head -n1`  
  set lat2 = `awk '{print $2}' $data|sort -nr|uniq|head -n1`  
  set xSpacing = `awk '{print $1}' $data|sort -n|uniq|head -n2|awk '{printf "%s %s",$1,$2}'|awk '{print $2-$1}'`
  set ySpacing = `awk '{print $2}' $data|sort -n|uniq|head -n2|awk '{printf "%s %s",$1,$2}'|awk '{print $2-$1}'`
  set grdSpacing = `echo $xSpacing $ySpacing| awk '{printf "%f/%f",$1/4,$2/4}'`
  set reg = "$lon1/$lon2/$lat1/$lat2"
  
  gmt blockmean $data -R"$reg" -I"$grdSpacing" > bm.tmp
  gmt surface bm.tmp -R"$reg" -I"$grdSpacing" -Gdataset_$id.nc
end
printf "  Gridding .......... Done!       \n"

#extract profile data
printf "  Extracting data ...\r"
@ i=0
foreach track (`ls|grep "track_[0-9][0-9][0-9][0-9].dat"`)
  @ i++
  set pid = `printf '%04d' $i`
  awk '{print $1,$2}' $track > track.dat
  @ j=0
  foreach grd (`ls|grep "dataset_[0-9][0-9][0-9][0-9].nc"`)
    @ j++
    set gid = `printf '%04d' $j`
    gmt grdtrack track.dat -G$grd -N|awk '{print $3}' > val$gid.dat
  end
  paste track.dat val????.dat > profile_$pid.dat
  rm -f track.dat val????.dat
end

printf "  Extracting data ... Done!        \n"

#remove unnecessary files
rm -f `ls|grep -v "profile_[0-9][0-9][0-9][0-9].dat"`

