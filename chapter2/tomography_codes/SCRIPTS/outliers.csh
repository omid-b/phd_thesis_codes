#!/bin/csh
# This script automates using the code "excl_outl"; the most useful 
# output of this script is the new datalist, "datalist_outl", that will
# be created in the "reg_runset" directory.
# Usage: csh outliers.csh nonReg_runset reg_runset
#    -nonReg_runset: VERY weakly regularized runset 
#                    (very low damping and smoothing)
#    -reg_runset: moderately regularized runset

# CODED BY: omid.bagherpur@gmail.com
# UPDATE: 8 Sep 2020

clear

if ($#argv != 2) then
    printf "Error Usage\n\n Usage: csh outliers.csh   nonReg_runset  reg_runset\n\n"
    exit
endif

if (-e param.csh) then
    source param.csh
else
    printf "Error!\n Could not find 'param.csh' in current directory.\n\n"
    exit
endif

set runset0 = `realpath $argv[1]`
set runset1 = `realpath $argv[2]`

printf "nonReg_runset: $runset0\nreg_runset: $runset1\n\n Threshold type: $outliers_setting[1]\n Threshold factor: $outliers_setting[2]\n\n"

if (! -d $runset0) then
    printf "Error! Could not find the non-regularized runset!\n\n"
    exit
endif

if (! -d $runset1) then
    printf "Error! Could not find the regularized runset!\n\n"
    exit
endif

if (! -e $runset0/inv/iniac) then
    printf "Error! could not find 'iniac' in:\n$runset0/inv/\n\n"
    exit
else
    set runset0_dmp = (`awk 'NR==4' $runset0/inv/iniac`)
    set runset0_smth = (`awk 'NR==5' $runset0/inv/iniac`)
    set runset0_grad = (`awk 'NR==6' $runset0/inv/iniac`)
endif

if (! -e $runset1/inv/iniac) then
    printf "Error! could not find 'iniac' in:\n$runset1/inv/\n\n"
    exit
else
    set runset1_dmp = (`awk 'NR==4' $runset1/inv/iniac`)
    set runset1_smth = (`awk 'NR==5' $runset1/inv/iniac`)
    set runset1_grad = (`awk 'NR==6' $runset1/inv/iniac`)
endif

printf "Non-regularized runset parameters:\n  damping: $runset0_dmp\n  smoothing: $runset0_smth\n  gradient damping: $runset0_grad\n\nRegularized runset parameters:\n  damping: $runset1_dmp\n  smoothing: $runset1_smth\n  gradient damping: $runset1_grad\n\n"


@ err=0
foreach n (1 2 3)
    if (`echo "$runset0_dmp[$n] >= $runset1_dmp[$n]"|bc`) @ err++
    if (`echo "$runset0_smth[$n] >= $runset1_smth[$n]"|bc`) @ err++
    if (`echo "$runset0_grad[$n] >= $runset1_grad[$n]"|bc`) @ err++
end

if ($err > 0) then
    printf "Error! All regularization parameter values should be larger for the regularized runset!\n\n"
    exit
endif

set num_periods = `echo $periods|wc -w`
set periods0 = `ls $runset0/inv|grep ^"[0-9][0-9][0-9]"`
set periods1 = `ls $runset1/inv|grep ^"[0-9][0-9][0-9]"`
set periods_orig = ($periods)

@ i=1
while ($i <= $num_periods)
    set periods[$i] = `echo $periods[$i]|awk '{printf "%03d",$1}'`
    if ($periods[$i] != $periods0[$i] || $periods[$i] != $periods1[$i]) then
        printf "\nError! Periods in 'param.csh' and in the results' directories do not match!\n\n"
        exit
    endif
    @ i++
end

printf "  Do you want to continue (y/n)? "
set uin = $<
if ($uin == 'y' || $uin == 'Y') then
    printf "\n\n"
else
    printf "\n\nExit Program!\n\n"
    exit
endif

#start the main process
if (-d $runset1/outlier_info) then
    rm -rf $runset1/outlier_info
endif

if (-d $runset1/inv_outl) then
    rm -rf $runset1/inv_outl
endif

mkdir $runset1/outlier_info
mkdir $runset1/inv_outl

foreach prd ($periods)
 cp -r  $runset0/inv/$prd $runset1/outlier_info/$prd\_orig
end

echo 'Period  #Selected  #Paths  Included(%)'

set periods_flag = ()


@ i=1
set total_num_paths = 0
set total_num_paths_sel = 0
set total_num_paths_nsl = 0
foreach prd ($periods)
cd $runset1/outlier_info/$periods[$i]\_orig

$softwaredir/BIN/excl_outl << endinp >> excl_outl
$outliers_setting[1]
$outliers_setting[2]
endinp
    echo "outliers_setting: ($outliers_setting)" >> excl_outl
    set num_paths = `cat $runset1/outlier_info/$periods[$i]\_orig/path_list|wc -l`
    set num_paths_sel = `cat $runset1/outlier_info/$periods[$i]\_orig/path_sel|wc -l`
    set num_paths_nsl = `cat $runset1/outlier_info/$periods[$i]\_orig/path_nsl|wc -l`
    set inc_paths_per = `echo $num_paths_sel $num_paths|awk '{printf "%5.1f",($1/$2)*100}'`
    
    if (`echo "$num_paths_sel>0"|bc` == 1) then
        set periods_flag = ($periods_flag 1)
    else
        set periods_flag = ($periods_flag 0)
    endif

    set total_num_paths = `echo $total_num_paths+$num_paths|bc`
    set total_num_paths_nsl = `echo $total_num_paths_nsl+$num_paths_nsl|bc`
    set total_num_paths_sel = `echo $total_num_paths_sel+$num_paths_sel|bc`
    
    printf "%6s %10d %7d %11.1f%s\n" $periods[$i] $num_paths_sel $num_paths $inc_paths_per '%'
    @ i++
end

# write inbac_outl
set num_periods_ok = `echo $periods_flag|sed 's/ /\n/g'|grep 1|wc -l`
echo $runset1/outlier_info/ > $runset1/inbac_outl
echo $num_periods_ok >> $runset1/inbac_outl
@ i=1
foreach prd ($periods)
    if ($periods_flag[$i] == 1) then
        printf "%s 0 %s_orig/path_sel\n" $periods_orig[$i] $periods[$i] >> $runset1/inbac_outl
    endif   
    @ i++
end
tail -3 $runset1/inbac >> $runset1/inbac_outl

set total_inc_paths_per = `echo $total_num_paths_sel $total_num_paths|awk '{printf "%5.1f",($1/$2)*100}'`
printf "\n\n>> %s%s of datasets were included!\n\nRelated 'inbac_outl' created in the given runset directory!\n\nCheck the 'excl_outl' files in the 'outlier_info' directory.\n\n" $total_inc_paths_per '%'

