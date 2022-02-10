#!/bin/csh -f

set about = "This script automates the resolution tests analysis for the Sergei's tomography code.\n"
set usage = " usage: csh run_resotests.csh [inversion_results_dir] [period 1] ... [period n]\n\n Note: period inputs are optional (if not given, all periods will be considered)\n"

# Note: use the script "plot_invdir.csh" to plot the results after running this script

# CODED BY: omid.bagherpur@gmail.com
# UPDATE: 26 Jan 2021
#======Adjustable Parameters======#
set resotest_dirname = "spiketests_20211116_2"

# run/don't run different resolution test types; true or false
set run_iso = false
set run_2psi = false
set run_4psi = false
set run_const = false
set run_anisrev = false
set run_grad = false
set run_grad_values = (-45 45 90 180)
set run_spk = true
set run_spkanis = false


# compiled codes paths
set softwaredir = /data/home/omid_b/Ambient-Noise-Tomography/tomography
set iac_compiled = $softwaredir/BIN/iac
set xsc_compiled = $softwaredir/BIN/xsc
set make_reso_inC_compiled = $softwaredir/BIN/make_reso_inC
set make_rhsC_err_compiled = $softwaredir/BIN/make_rhsC_err
#=================================#

clear
printf "$about\n"

if ($#argv == 0) then
  printf "Error USAGE!\n\n$usage\n\n"
  exit
endif

if (! -d $argv[1]) then
  printf "Error! Could not find the inversion results directory:\n$argv[1]\n\n"
  exit()
else
  set homedir = `realpath $argv[1]`
endif


# check if all compiled codes do exist!
if (! -e $iac_compiled) then
  printf "Error! Could not find the 'iac' compiled code:\n$iac_compiled\n\n"
  exit()
endif

if (! -e $xsc_compiled) then
  printf "Error! Could not find the 'xsc' compiled code:\n$xsc_compiled\n\n"
  exit()
endif

if (! -e $make_reso_inC_compiled) then
  printf "Error! Could not find the 'make_reso_inC' compiled code:\n$make_reso_inC_compiled\n\n"
  exit()
endif

if (! -e $make_rhsC_err_compiled) then
  printf "Error! Could not find the 'make_rhsC_err' compiled code:\n$make_rhsC_err_compiled\n\n"
  exit()
endif

# list of periods
set periods = `ls $homedir|grep -e "^[0-9][0-9][0-9]"`
if ($#periods == 0) then
  printf "Error! Could not find any period directory in homedir!\nhomedir = $homedir\n\n"
  exit
endif

if ($#argv > 1) then
  @ i=2
  set periods = ""
  while ($i <= $#argv)
    set prd = `echo $argv[$i]|awk '{printf "%03d",$1}'`
    if (! -d $homedir/$prd) then
      printf "Error! Could not find period directory: $prd\n\n"
      exit
    else
      set periods = "$periods $prd"
    endif
    @ i++
  end
endif
set periods = ($periods)


# check the first period directory for the 'spk?' files
if (-e $homedir/$periods[1]/spk1) then
  set spks = `ls $homedir/$periods[1]/spk?|awk -F"/" '{print $NF}'`
  set spks = ($spks)
else
  set spks = ()
endif

set report = "  homedir: $homedir\n  #periods: $#periods\n  periods: $periods\n\n  run_iso = $run_iso\n  run_2psi = $run_2psi\n  run_4psi = $run_4psi\n  run_const = $run_const\n  run_anisrev = $run_anisrev\n  run_grad = $run_grad       run_grad_values = $run_grad_values\n\n  run_spk = $run_spk\n  run_spkanis =  $run_spkanis\n  #spike models: $#spks"

if (-e $homedir/$periods[1]/spk1) then
  set report = "$report        spike models: $spks\n"
else
  set report = "$report\n"
endif

set report = "$report  resotest directory: $resotest_dirname\n"

printf "$report\n Do you want to run the analysis (y/n)? "
set uinp = $<
if ($uinp == 'y' || $uinp == 'Y') then
  printf "\n"
else
  printf "\n Quit program!\n\n"
  exit
endif

# remove existing resolution test directory
set resotest_homedir = "$homedir/$resotest_dirname"
if (-d $resotest_homedir) then
  rm -rf $resotest_homedir
endif
mkdir $resotest_homedir

# copy all required files
foreach prd ($periods)
  printf "  Copying files into initial directories ... period: $prd \r"
  if (! -d "$resotest_homedir/$prd") then
    cp -r $homedir/$prd $resotest_homedir
    cp $homedir/nbrs $resotest_homedir
    cd $resotest_homedir/$prd
    mkdir initial
    mv d* rhs solution* initial
    cp iniac inxc matrix* path* shell* initial
  endif
end

if (-d $homedir/spiketest_models) then
  if ($run_spk == true || $run_spkanis == true) then
    cp -r $homedir/spiketest_models $resotest_homedir
  endif
endif

set datetime = `date +"%Y-%m-%d %T"`
printf "$datetime\n\n$report\n" > $resotest_homedir/readme.txt
printf "  Copying files into initial directories ... Done.         \n\n"

##########################
# RUN THE RESOLUTION TESTS
##########################

set tests = "" # initialize the tests list

# Isotropic-only tests
if ($run_iso == true) then
  set testdir = "isotropic"
  set tests = " $tests $testdir"
  foreach prd ($periods)
    printf "  Running resolution analysis: $testdir (period $prd)\r"
    set prdDir = $resotest_homedir/$prd
    cd $prdDir
    mkdir $testdir
    cp initial/solution $testdir
    cd $testdir
    
$make_reso_inC_compiled << end1 >& /dev/null
orig
0
end1

$make_rhsC_err_compiled << end2 >& /dev/null
0.02
end2

    cp srhs ../rhs
    cd $prdDir
    $iac_compiled < iniac > outiac
    $xsc_compiled < inxc > outxc
    cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
    mv d* rhs solution* $testdir
  end
  printf "  Running resolution analysis: $testdir               \n"
endif


# 2psi-only tests
if ($run_2psi == true) then
  set testdir = "2psi_only"
  set tests = " $tests $testdir"
  foreach prd ($periods)
    printf "  Running resolution analysis: $testdir (period $prd)\r"
    set prdDir = $resotest_homedir/$prd
    cd $prdDir
    mkdir $testdir
    cp initial/solution $testdir
    cd $testdir
    
$make_reso_inC_compiled << end1 >& /dev/null
orig
1
end1

$make_rhsC_err_compiled << end2 >& /dev/null
0.02
end2

    cp srhs ../rhs
    cd $prdDir
    $iac_compiled < iniac > outiac
    $xsc_compiled < inxc > outxc
    cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
    mv d* rhs solution* $testdir
  end
  printf "  Running resolution analysis: $testdir             \n"
endif


# 4psi-only tests
if ($run_4psi == true) then
  set testdir = "4psi_only"
  set tests = " $tests $testdir"
  foreach prd ($periods)
    printf "  Running resolution analysis: $testdir (period $prd)\r"
    set prdDir = $resotest_homedir/$prd
    cd $prdDir
    mkdir $testdir
    cp initial/solution $testdir
    cd $testdir
    
$make_reso_inC_compiled << end1 >& /dev/null
orig
2
end1

$make_rhsC_err_compiled << end2 >& /dev/null
0.02
end2

    cp srhs ../rhs
    cd $prdDir
    $iac_compiled < iniac > outiac
    $xsc_compiled < inxc > outxc
    cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
    mv d* rhs solution* $testdir
  end
  printf "  Running resolution analysis: $testdir                 \n"
endif


# constant tests
if ($run_const == true) then
  set testdir = "constant"
  set tests = " $tests $testdir"
  foreach prd ($periods)
    printf "  Running resolution analysis: $testdir (period $prd)\r"
    set prdDir = $resotest_homedir/$prd
    cd $prdDir
    mkdir $testdir
    cd $testdir

$make_reso_inC_compiled << end1 >& /dev/null
const
end1
    
    cp ssol ../solution
    cd $prdDir
    $xsc_compiled < inxc > $testdir/outxc_syn
    if (-e dcp) cp dcp $testdir/dcp_syn
    if (-e dcg) cp dcg $testdir/dcg_syn
    if (-e dap) cp dap $testdir/dap_syn
    if (-e d4p) cp d4p $testdir/d4p_syn
    rm solution d*
    cd $testdir

$make_rhsC_err_compiled << end2 >& /dev/null
0.02
end2

    cp srhs ../rhs
    cd $prdDir
    $iac_compiled < iniac > outiac
    $xsc_compiled < inxc > outxc
    cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
    mv d* rhs solution* $testdir
  end
  printf "  Running resolution analysis: $testdir              \n"
endif


# anisrev tests
if ($run_anisrev == true) then
  set testdir = "anisrev"
  set tests = " $tests $testdir"
  foreach prd ($periods)
    printf "  Running resolution analysis: $testdir (period $prd)\r"
    set prdDir = $resotest_homedir/$prd
    cd $prdDir
    mkdir $testdir
    cp $prdDir/initial/solution $testdir
    cd $testdir

$make_reso_inC_compiled << end1 >& /dev/null
anisrev
end1

    cp ssol ../solution
    cd $prdDir
    $xsc_compiled < inxc > $testdir/outxc_syn
    if (-e dcp) cp dcp $testdir/dcp_syn
    if (-e dcg) cp dcg $testdir/dcg_syn
    if (-e dap) cp dap $testdir/dap_syn
    if (-e d4p) cp d4p $testdir/d4p_syn
    rm solution d*
    cd $testdir

$make_rhsC_err_compiled << end2 >& /dev/null
0.02
end2

    cp srhs ../rhs
    cd $prdDir
    $iac_compiled < iniac > outiac
    $xsc_compiled < inxc > outxc
    cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
    mv d* rhs solution* $testdir
  end
  printf "  Running resolution analysis: $testdir               \n"
endif


# grad tests
if ($run_grad == true) then
  foreach gv ($run_grad_values)
    set testdir = "grad_$gv"
    set tests = " $tests $testdir"
    foreach prd ($periods)
      printf "  Running resolution analysis: $testdir (period $prd)\r"
      set prdDir = $resotest_homedir/$prd
      cd $prdDir
      mkdir $testdir
      cd $testdir

$make_reso_inC_compiled << end1 >& /dev/null
grad
$gv
end1

      cp ssol $prdDir/solution
      cd $prdDir
      $xsc_compiled < inxc > $testdir/outxc_syn
      if (-e dcp) cp dcp $testdir/dcp_syn
      if (-e dcg) cp dcg $testdir/dcg_syn
      if (-e dap) cp dap $testdir/dap_syn
      if (-e d4p) cp d4p $testdir/d4p_syn
      rm solution d*
      cd $testdir
      
$make_rhsC_err_compiled << end2 >& /dev/null
0.02
end2
      
      cp srhs $prdDir/rhs
      cd $prdDir
      $iac_compiled < iniac > outiac
      $xsc_compiled < inxc > outxc
      cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
      mv d* rhs solution* $testdir
    end
    printf "  Running resolution analysis: $testdir              \n"
  end
endif


# spike tests
if ($run_spk == true) then
  foreach spk ($spks)
    set spk_indx = `echo "$spk"|cut -c4-999`
    set testdir = "spike$spk_indx"
    set tests = " $tests $testdir"
    foreach prd ($periods)
      printf "  Running resolution analysis: $testdir (period $prd)\r"
      set prdDir = $resotest_homedir/$prd
      cd $prdDir
      mkdir $testdir
      cd $testdir
      cp $prdDir/$spk $prdDir/$testdir

$make_reso_inC_compiled << end1 >& /dev/null
spk
$spk_indx
end1

      cp ssol $prdDir/solution
      cd $prdDir
      $xsc_compiled < inxc > $testdir/outxc_syn
      if (-e dcp) cp dcp $testdir/dcp_syn
      if (-e dcg) cp dcg $testdir/dcg_syn
      if (-e dap) cp dap $testdir/dap_syn
      if (-e d4p) cp d4p $testdir/d4p_syn
      rm solution d*
      cd $testdir
      
$make_rhsC_err_compiled << end2 >& /dev/null
0.02
end2
      
      cp srhs $prdDir/rhs
      cd $prdDir
      $iac_compiled < iniac > outiac
      $xsc_compiled < inxc > outxc
      cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
      mv d* rhs solution* $testdir
    end
    printf "  Running resolution analysis: $testdir             \n"
  end
endif


# spike anis tests
if ($run_spkanis == true) then
  foreach spk ($spks)
    set spk_indx = `echo "$spk"|cut -c4-999`
    set testdir = `printf "spike%s%s" $spk_indx 'anis'`
    set tests = " $tests $testdir"
    foreach prd ($periods)
      printf "  Running resolution analysis: $testdir (period $prd)\r"
      set prdDir = $resotest_homedir/$prd
      cd $prdDir
      mkdir $testdir
      cd $testdir
      cp $prdDir/$spk $prdDir/$testdir

$make_reso_inC_compiled << end1 >& /dev/null
spkanis
$spk_indx
end1

      cp ssol $prdDir/solution
      cd $prdDir
      $xsc_compiled < inxc > $testdir/outxc_syn
      if (-e dcp) cp dcp $testdir/dcp_syn
      if (-e dcg) cp dcg $testdir/dcg_syn
      if (-e dap) cp dap $testdir/dap_syn
      if (-e d4p) cp d4p $testdir/d4p_syn
      rm solution d*
      cd $testdir
      
$make_rhsC_err_compiled << end2 >& /dev/null
0.02
end2
      
      cp srhs $prdDir/rhs
      cd $prdDir
      $iac_compiled < iniac > outiac
      $xsc_compiled < inxc > outxc
      cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
      mv d* rhs solution* $testdir
    end
    printf "  Running resolution analysis: $testdir             \n"
  end
endif

##################
# INVERSIONS DONE!
##################

# generate stats-info
set tests = ($tests)
foreach testdir ($tests)
  foreach prd ($periods)
    cd $resotest_homedir/$prd/$testdir
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
  end
end


printf "\n Done!\n\n"

