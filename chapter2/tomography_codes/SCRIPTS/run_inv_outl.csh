#!/bin/csh
# This script automates running "bac/iac/xsc" codes (after outlier exclusion process)
# Usage: csh run_inv_outl.csh runsetdir
# * runsetdir: path to runset directory

clear

if (-e param.csh) then
    source param.csh
else
    printf "Error!\n Could not find 'param.csh' in current directory.\n\n"
    exit
endif

# check software directory
if (-d $softwaredir) then
    if (! -e $softwaredir/BIN/bac || ! -e $softwaredir/BIN/iac || ! -e $softwaredir/BIN/xsc) then
        printf "\nError!\n Could not find the compiled codes (bac/iac/xsc) in BIN directory!\n Check BIN directory content:\n $softwaredir/BIN\n\n"
        exit
    endif
else
    printf "\nError!\n Could not find softwaredir:\n $softwaredir\n\n"
    exit
endif


# check inputs
if ($#argv == 1) then
    set runsetdir = `realpath $argv[1]`
else
    printf "\nError!\n\nUsage: csh run_inv_outl.csh runsetdir\n\n"
    exit
endif

printf "runset: $runsetdir\n\n"

if (! -d $runsetdir) then
    printf "\nError!\n 'runset' directory does not exist!\n\n"
    exit
endif

if (! -e $runsetdir/datalist) then
    printf "\nError!\n Could not find 'datalist' in the given runset!\n\n"
    exit
else if (! -e $runsetdir/inbac_outl) then
    printf "\nError!\n Could not find 'inbac_outl' in the given runset;\n use script 'outliers.csh' first!\n\n"
    exit
endif

printf "  Do you want to continue (y/n)? "
set uin = $<
if ($uin == 'y' || $uin == 'Y') then
    printf "\n\n"
else
    printf "\n\nExit Program!\n\n"
    exit
endif

if (-d $runsetdir/inv_outl) then
    rm -rf $runsetdir/inv_outl 
endif

mkdir $runsetdir/inv_outl
cd $runsetdir/inv_outl

#run bac
printf "  Inversion in progress (code: 'bac') \n"

$softwaredir/BIN/bac < $runsetdir/inbac_outl > outbac_outl
#cp $runsetdir/inv/outbac $runsetdir

# sortdirs
set prds = `ls | grep ^"shell_key" | cut -c 10-12`
foreach prd ($prds)
    mkdir $prd
    set files = `ls | grep {$prd}$ | grep ^"[a-z]"`
    foreach f ($files)
        set f1 = `echo $f | sed s/$prd/""/g`
        cp $f $prd/$f1
    end
    cp $runsetdir/iniac $runsetdir/inv_outl/$prd/iniac
    cp $runsetdir/inxc $runsetdir/inv_outl/$prd/inxc

end

rm colsums* ers* matrix* path* rhs* shell* stations* tri*
cp $runsetdir/datalist $runsetdir/inv_outl/
cp $runsetdir/inbac_outl $runsetdir/inv_outl/
cp $runsetdir/iniac $runsetdir/inv_outl/
cp $runsetdir/inxc $runsetdir/inv_outl/


#run iac and xsc
foreach prd ($periods)
    set prd = `printf "%03d" $prd`
    cd $prd
    
    printf "  Inversion in progress (codes: 'iac' & 'xsc'; period: $prd)  \n"
    $softwaredir/BIN/iac < iniac > outiac
    $softwaredir/BIN/xsc < inxc > outxc
    
    #get stats
    grep ^"[nlig ][oatr 0-9][rtea 0-9][merd0-9]" outiac > tmp
    grep iso tmp | head -1 > stats-info
    grep iso tmp | head -2 | tail -1 >> stats-info
    grep iso tmp | tail -1 >> stats-info

    set numiter = `tail -1 tmp | awk '{print $1}' `
    set remvar =  `tail -1 tmp | awk '{print $7}' `
    printf "Number of iterations, remaining variance: $numiter $remvar\n\n"  >> stats-info

    grep ^"[m ][ai]" outxc > tmp1
    head -1 tmp1 >> stats-info
    head -2 tmp1 | tail -1 >> stats-info
    set slim = `head -3 inxc | tail -1 | awk '{print $1}' `
    echo "(saturated-scale limits are "$slim" of the max)" >> stats-info
    head -3 tmp1 | tail -1 >> stats-info
    head -4 tmp1 | tail -1 >> stats-info
    head -5 tmp1 | tail -1 >> stats-info
    head -6 tmp1 | tail -1 >> stats-info
  
    grep "roughness" outiac >> stats-info
    grep "average phase velocity" outiac >> stats-info

    echo "period: "$prd" s" >> stats-info
    set np = `grep ^">" paths | wc -l`
    echo "number of paths: "$np >> stats-info
    set ks = `head -1 shell`
    set ks = `echo $ks[3] | awk -F. '{print $1}'`
    echo "knot spacing: "$ks" km" >> stats-info
    rm -f tmp*
    cd ..
end



