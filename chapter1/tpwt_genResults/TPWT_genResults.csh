F#!/bin/csh
#This script generates proper gridded outputs from the two-plane-wave tomography summary and covar files.
#Run the script to see the USAGE!
#Coded by: omid.bagherpur@gmail.com
#=====Adjustable Parameters=====#
set gridder = gridder-src/gridder #compiled gridder.f code
set covargridder = gridder-src/covargridder #compiled covargridder.f code
set loninc  = 0.05 # gridder parameter: longitude increament
set latinc  = 0.05 # gridder parameter: latitude increament
set smoothing = 80
#===============================#
clear
printf "This script generates proper gridded outputs from the two-plane-wave tomography summary and covar files.\n\n"

#check the inputs
foreach code ($gridder $covargridder)
  if (! -e $code) then
    printf "\nError!\n Could not find the compiled code: '%s'\n Check the 'Adjustable Parameters' section at the top of the script.\n\n" $code
    exit
  endif
end

if ($#argv != 4) then
  printf "\nError USAGE! This script requires 4 inputs:\n ./TPWT_genResults.csh <summary datalist> <covar datalist> <TPWT gridnode> <output folder>\n\n"
  exit
else
	foreach inp ($1 $2 $3)
      if (! -e $inp) then
        printf "\nError!\n Could not find '%s'\n\n" $inp
        exit
      endif
	end
endif

foreach datalist ($1 $2)
  set ncol = `awk '{print NF}' $datalist|sort -n|head -n1`
  if ($ncol != 2) then
    printf "\nError in datalist format: '%s'\n Datalists should have two columns: 1)period 2)file location\n\n" $datalist
    exit
  endif
  foreach data (`awk '{print $2}' $datalist`)
    if (! -e $data) then
      printf "\nError!\n Could not find data: '%s'\n Check datalist: '%s'\n\n" $data $datalist
    endif
  end
end

set ndata1 = `cat $1|wc -l`
set ndata2 = `cat $2|wc -l`
set nnode = `cat $3|head -n2|tail -n1`

printf "\n Number of summary files: %d\n Number of covar files: %d\n Longitude spacing (deg): %s\n Latitude spacing (deg):  %s\n Smoothing length (km): %s\n\nDo you want to continue (y/n)? " $ndata1 $ndata2 $loninc $latinc $smoothing

set uans = $<
if ($uans != 'y') then
  printf "\nExit program!\n\n"
  exit
else
  set outFolder = $4
  if (! -d $outFolder) then
    mkdir $outFolder
  else
  	rm -rf $outFolder
  	mkdir $outFolder
  endif
  printf "\n\n"
endif

awk 'NR>2' $3|head -n$nnode|awk '{print $2,$1}' > $outFolder/nodes.tmp

#main code block!
printf "  Generate summary data\r"
@ i=0 #summary files
while ($i < $ndata1)
  @ i++
  printf "  Generate summary data ... $i of $ndata1\r"
  set period = `awk '{printf "%03d\n",$1}' $1|awk "NR==$i"` 
  set data = `awk '{print $2}' $1|awk "NR==$i"`
  set ncol = `tail -n$nnode $data|awk '{print NF}'|sort -n|head -n1`
  
  @ col=1
  cp $outFolder/nodes.tmp $outFolder/data1.tmp
  while ($col < $ncol)
    @ col++
    tail -n$nnode $data|awk -v c=$col '{printf "%13.10f\n",$c}'  > $outFolder/data2.tmp
    paste -d' ' $outFolder/data1.tmp $outFolder/data2.tmp > $outFolder/summary_p$period.dat
    cp $outFolder/summary_p$period.dat $outFolder/data1.tmp

    paste $outFolder/nodes.tmp $outFolder/data2.tmp> $outFolder/gridderInput.tmp
$gridder << EOF >> $outFolder/gridder.log
$nnode
$outFolder/gridderInput.tmp
$outFolder/gridderOutput.tmp
$loninc
$latinc
$smoothing
EOF
    awk '{printf "%.4f %.4f\n",$1,$2}' $outFolder/gridderOutput.tmp > $outFolder/gridderOutNod.tmp
    awk '{printf "%13.10f\n",$3}' $outFolder/gridderOutput.tmp > $outFolder/gVal$col.tmp
  end
  paste -d' ' $outFolder/gridderOutNod.tmp $outFolder/gVal*.tmp > $outFolder/summary_gridded_p$period.dat
  awk '{print $1,$2,$3,$4}' $outFolder/summary_gridded_p$period.dat > $outFolder/phvel_gridded_p$period.dat
  
  if ($ncol == 7) then
    awk '{printf "%.4f %.4f %7.2f %9.6f\n",$1,$2,0.5*atan2($7,$5)*(180/3.141592),200*(($5^2 + $7^2)^(0.5))/$3}' $outFolder/summary_p$period.dat > $outFolder/anis_p$period.dat
    
    awk '{printf "%.4f %.4f %7.2f %9.6f\n",$1,$2, 0.5*atan2($7,$5)*(180/3.141592),200*(($5^2 + $7^2)^(0.5))/$3}' $outFolder/summary_gridded_p$period.dat > $outFolder/anis_gridded_p$period.dat
  endif
  
  rm -f $outFolder/gVal*.tmp
end
printf "  Generate summary data ... Done.           \n"


printf "  Generate covar data\r"
@ i=0 #covar files
while ($i < $ndata2)
  @ i++
  printf "  Generate covar data ... $i of $ndata2\r"
  set period = `awk '{printf "%03d\n",$1}' $2|awk "NR==$i"` 
  set data = `awk '{print $2}' $2|awk "NR==$i"`
  set fn = covar_gridded_p$period.dat

$covargridder << EOF >> $outFolder/covargridder.log
$3
$data
$outFolder/covar.tmp
$loninc
$latinc
$smoothing
EOF

  awk '{printf "%.4f %.4f %13.10f\n",$1,$2,$3}' $outFolder/covar.tmp > $outFolder/$fn
  
  
end
#remove other files
rm -f $outFolder/*.{tmp,log}
printf "  Generate covar data ..... Done.           \n\nFinished!\n\n"

