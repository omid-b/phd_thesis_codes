#/bin/csh
#Coded by: omid.bagherpur@gmail.com
#UPDATE: 23 May 2019
#Run the sctipt to see the usage!
#====Adjustable Parameters=====#
set output_folder = plots/saito-sm30-AK135-PS2
set uniform_scale = 'yes' # 'yes' or 'no'; uniform colorscale for all maps
set moho_shift = 0  #4.5-4.70  4.39-4.65
set mantle_minValue = -4 #If auto, it will be chosen based on the max value of the Crust grid
set mantle_maxValue = 4 #If auto, it will be chosen based on the max value in the Mantle grid
set min_depth = 7
set max_depth = 250
set profile_start = 'SW'
set profile_end   = 'NE'
set scale_unit = "(%)"
#for the minimap:
set margin_right  = 3 #grid right margin  (in degrees) 1
set margin_left   = 3 #grid left margin   (in degrees)1
set margin_top    = 1.5 #grid top margin    (in degrees) 0.5
set margin_bottom = 2 #grid bottom margin (in degrees) 0.5
#==============================#
clear
printf "This script generates plots of cross sections with the same length over a tomography model using GMT.\n\n" 
printf "The inputs include:\n 1) A list of crosssection data (format: dist(km), depth(km), val ...)\n 2) A polygon track that defines the region of interest \n 3) Crustal thickness profile\n\n"


#---check input data---#
if ( $#argv != 3 ) then
  printf "Error!\n USAGE: csh crosssection-plot.csh <crosssection datalist> <area polygon> <profiles>\n\nInput data format (columns):\n\n <crosssection datalist>: 1)crosssection data location\n <area polygon>: 1)Lon,    2)Lat\n <profiles>: 1)Crustal thickness profile data\n\n"
  exit
else
  set datalist = $1
  set polygon  = $2
  set profiles = $3
  printf "  Checking inputs ... \r"
endif

if (! -e $datalist) then
  printf "\nError!\n Could not find <crosssection datalist>: '$datalist'\n\n"
  exit
else
  set nData = `cat $datalist|wc -l`
  set data_nCol = `awk 'NR==1' $datalist|awk '{print NF}'`
endif

  
  
if (! -e $polygon) then
  printf "\nError!\n Could not find <polygon>: '$polygon'\n\n"
  exit
endif

if (! -e $profiles) then
  printf "\nError!\n Could not find <profiles>: '$profiles'\n\n"
  exit
else
  set nProfiles = `cat $profiles|wc -l`
endif

if ($nProfiles  != $nData) then
  printf "\nError!\n Number of profiles and crosssections should match!\n\n"
  exit
endif

set dist_A = -9999
set dist_Z = 9999

foreach cs (`awk '{print $1}' $datalist`)
  if (! -e $cs) then
    printf "Error!\n Could not find '$cs' in <crosssection datalist>\n\n"
    exit
  else
    set dis1 = `awk '{print $1}' $cs|sort -n |awk 'NR==1'`
    set dis2 = `awk '{print $1}' $cs|sort -nr|awk 'NR==1'`
  endif
  
  if (`echo "$dis1 > $dist_A"|bc`) set dist_A = $dis1
  if (`echo "$dis2 < $dist_Z"|bc`) set dist_Z = $dis2
end

printf "  Checking inputs ... Done.\n\n"

printf " Number of cross-sctions: $nData\n Profile distance range (km): $dist_A-$dist_Z\n Plots depth range (km): $min_depth-$max_depth\n\n"

#---------
printf " Do you want to continue (y/n)? "
set uans = $<
if ($uans != 'y') then
  printf "\nExit program!\n\n"
  exit
else
  printf "\n\n"
endif


#copy data to $output_folder
if (-d $output_folder) then
  rm -rf $output_folder
  mkdir $output_folder
else
  mkdir $output_folder
endif

@ i=0
foreach cs (`awk '{print $1}' $datalist`)
  @ i++
  set num = `echo $i|awk '{printf "%04d",$1}'`
  printf "  Copying data: %d of %d\r" $i $nData
  cp $cs $output_folder/crosssection_$num.dat
  cp `awk "NR==$i" $profiles` $output_folder/profile_$num.dat
  if (`awk '{print NF}' $output_folder/profile_$num.dat|sort -n|awk 'NR==1'` != 3) then
    printf '\n\nError reading profile tracks!\n Profile tracks should provide information about crustal thickness values in the third column!\n\n'
    rm -rf $output_folder
    exit
  endif
end
cp $datalist $output_folder/crosssections.dat

cp $polygon $output_folder/polygons.dat


printf "  Copying data ............... Done.          \n"

#plotting script
cd $output_folder
set dep_len = `echo $min_depth $max_depth|awk '{print $2-$1}'`
set dis_len = `echo $dist_A $dist_Z|awk '{print $2-$1}'`
set mediaSize = `echo $dis_len $dep_len|awk '{printf "%.2fcx%.2fc",$1/50+9, $2/50+5}'`
set reg = $dist_A/$dist_Z/$min_depth/$max_depth
set prj = `echo $dis_len $dep_len|awk '{printf "X%.2fc/-%.2fc",$1/50,$2/50}' `

gmt set PS_MEDIA "$mediaSize" COLOR_NAN white COLOR_FOREGROUND 0/0/200 \
        COLOR_BACKGROUND 170/0/0 FONT_LABEL 12p,black MAP_TICK_LENGTH 2p \
        MAP_FRAME_PEN 1p

set mantle_cpt_l1 =  9999 ; set crust_cpt_l1 =  9999
set mantle_cpt_l2 = -9999 ; set crust_cpt_l2 = -9999

printf "  Gridding data\r"
@ i=0
foreach cs (`ls|grep "crosssection_[0-9][0-9][0-9][0-9].dat"`)
  @ i++
  set id = `echo $i|awk '{printf "%04d",$1}'`
  set prfName = "profile_$id.dat"
  set prfNOL = `cat $prfName|wc -l`
  #make crustMask.tmp and mantleMask.tmp
  touch ct.tmp; rm -f ct.tmp
  set px0 = `awk 'NR==1' $prfName|awk '{print $1}'`
  set py0 = `awk 'NR==1' $prfName|awk '{print $2}'`
  @ j=0
  while ($j < $prfNOL)
    @ j++
    set line = `awk "NR==$j" $prfName`
    set ct = `echo $line|awk '{printf "%s",$3}'`
    if ($ct != 'nan' && $ct != 'NaN') then
      set ct = `echo $ct $moho_shift|awk '{print $1+$2}'`
    endif
    set px = `echo $line|awk '{print $1}'`
    set py = `echo $line|awk '{print $2}'`
    set dist = `echo $px0 $py0|gmt mapproject -G$px/$py | awk '{printf "%.0f",$3/1000}'`
    echo $dist $ct >> ct.tmp
  end
  cat ct.tmp|grep -v 'nan'|grep -v 'NaN' > ct.tmp2
  
  set ct1 = `awk '{print $2}' ct.tmp2|sort -n |head -n1`
  set ct2 = `awk '{print $2}' ct.tmp2|sort -nr|head -n1`

  echo 0 $ct1 > ct.tmp
  cat ct.tmp2 >> ct.tmp
  echo $dist_Z $ct2 >> ct.tmp

  cat ct.tmp|sort -nk1|uniq > ct$id.dat

  #generate mantleMask.dat
  echo 0 $max_depth > mantleMask.tmp
  echo 0 $ct1 > mantleMask.tmp
  cat ct$id.dat >> mantleMask.tmp
  echo $dist $ct2 >> mantleMask.tmp
  echo $dist $max_depth >> mantleMask.tmp
  echo 0 $max_depth >> mantleMask.tmp
  cat mantleMask.tmp|grep -v 'nan'|grep -v 'NaN' > mantleMask.dat
  rm -f mantleMask.tmp
  
  
  #generate crustMask.dat
  echo 0 $min_depth > crustMask.tmp
  echo 0 $ct1 > crustMask.tmp
  cat ct$id.dat >> crustMask.tmp
  echo $dist $ct2 >> crustMask.tmp
  echo $dist $min_depth >> crustMask.tmp
  echo 0 $min_depth >> crustMask.tmp
  cat crustMask.tmp|grep -v 'nan'|grep -v 'NaN' > crustMask.dat
  rm -f crustMask.tmp

  set grdName = "grid_$id"
  set xSpacing = `awk '{print $1}' crosssection_$id.dat|sort -n|uniq|head -n2|awk '{printf "%s %s",$1,$2}'|awk '{print $2-$1}'`
  set ySpacing = `awk '{print $2}' crosssection_$id.dat|sort -n|uniq|head -n2|awk '{printf "%s %s",$1,$2}'|awk '{print $2-$1}'`
  set grdSpacing = `echo $xSpacing $ySpacing| awk '{printf "%f/%f",$1/4,$2/4}'`
  printf "  Gridding data: $i of $nData \r"
  
  gmt blockmean $cs -R$reg -I"$grdSpacing" > bm.tmp
  gmt surface bm.tmp -R$reg -I"$grdSpacing" -G$grdName.tmp
  
  if (`echo "$xSpacing > $ySpacing"|bc`) then
    set maskDist = `echo $xSpacing|awk '{print $1+1}'`
  else
    set maskDist = `echo $ySpacing|awk '{print $1+1}'`
  endif
  
  gmt grdmask bm.tmp -R$reg -I"$grdSpacing" -NNaN/1/1 -S"$maskDist" -Gmask.nc
  gmt grdmath mask.nc $grdName.tmp MUL = $grdName.nc
  
  gmt grdmask mantleMask.dat -R$reg -I$grdSpacing -NNaN/1/1 -Gmask.nc
  gmt grdmath mask.nc $grdName.nc MUL = mantle_$id.nc

  gmt grdmask crustMask.dat -R$reg -I$grdSpacing -NNaN/1/1 -Gmask.nc
  gmt grdmath mask.nc $grdName.nc MUL = crust_$id.nc

  set mantle_grdMin  = `gmt grdinfo mantle_$id.nc -M|grep -w z_min|awk '{printf "%.2f\n",$3-0.01}'`
  set mantle_grdMax  = `gmt grdinfo mantle_$id.nc -M|grep -w z_max|awk '{printf "%.2f\n",$12+0.01}'`
  if (`echo "$mantle_grdMin < $mantle_cpt_l1"|bc`) set mantle_cpt_l1 = $mantle_grdMin
  if (`echo "$mantle_grdMax > $mantle_cpt_l2"|bc`) set mantle_cpt_l2 = $mantle_grdMax


  set crust_grdMin  = `gmt grdinfo crust_$id.nc -M|grep -w z_min|awk '{printf "%.2f\n",$3-0.01}'`
  set crust_grdMax  = `gmt grdinfo crust_$id.nc -M|grep -w z_max|awk '{printf "%.2f\n",$12+0.01}'`
  if (`echo "$crust_grdMin < $crust_cpt_l1"|bc`) set crust_cpt_l1 = $crust_grdMin
  if (`echo "$crust_grdMax > $crust_cpt_l2"|bc`) set crust_cpt_l2 = $crust_grdMax
  
end
printf "  Gridding data .............. Done.       \n"


printf "  Plotting\r"
#plot mantle grids
@ i=0
foreach mantleGrd (`ls|grep "mantle_[0-9][0-9][0-9][0-9].nc"`)
  @ i++
  set id = `printf "%04d" $i`
  set crustGrd = `printf "crust_%04d.nc" $i`
  set fn = `printf "crosssection_%04d" $i`

  if ( `echo "$data_nCol > 1"|bc` ) then
    set title = `awk "NR==$i" crosssections.dat|cut -d' ' -f 2-99|sed 's/ /\n/g'`
  else
    set title = ""
  endif
  
  gmt psbasemap  -R$reg -J$prj -Bx100+l'Distance(km)' -By50+l'Depth(km)' -BWnSe+t"$title" -P -K > $fn.ps

#make color scales  
  if ($uniform_scale != 'yes') then
    set mantle_cpt_l1 = `gmt grdinfo $mantleGrd -m|grep z_min|awk '{print $3}'`
    set mantle_cpt_l2 = `gmt grdinfo $mantleGrd -m|grep z_min|awk '{print $5}'`
    set crust_cpt_l1 = `gmt grdinfo $crustGrd -m|grep z_min|awk '{print $3}'`
    set crust_cpt_l2 = `gmt grdinfo $crustGrd -m|grep z_min|awk '{print $5}'`
  endif
  
  if (`echo "$mantle_cpt_l1 < 0"|bc`) then #make symmetric colorscale if perturbation data is used
    if (`echo "(-1)*$mantle_cpt_l1 > $mantle_cpt_l2"|bc`) then
      set val0 = `echo "(-1)*$mantle_cpt_l1"|bc`
    else
      set val0 = $mantle_cpt_l2
    endif
    set mantle_cpt_l1 = "-$val0"
    set mantle_cpt_l2 = $val0
#    set scale_unit = "(%)"
  endif

  if (`echo "$crust_cpt_l1 < 0"|bc`) then #make symmetric colorscale if perturbation data is used
    if (`echo "(-1)*$crust_cpt_l1 > $crust_cpt_l2"|bc`) then
      set val0 = `echo "(-1)*$crust_cpt_l1"|bc`
    else
      set val0 = $crust_cpt_l2
    endif
    set crust_cpt_l1 = "-$val0"
    set crust_cpt_l2 = $val0
#    set scale_unit = "(%)"
  endif
  
  if ($mantle_minValue != 'auto') then
    set mantle_cpt_l1 = $mantle_minValue
  else
    set mantle_cpt_l1 = $crust_cpt_l2
  endif
  
  if ($mantle_maxValue != 'auto') then
    set mantle_cpt_l2 = $mantle_maxValue
  endif
  
  set mantle_scale_range = `echo $mantle_cpt_l1 $mantle_cpt_l2|awk '{printf "%f",$2-$1}'`
  gmt grd2cpt $mantleGrd -Cseis -L$mantle_cpt_l1/$mantle_cpt_l2 -S`echo $mantle_cpt_l1 $mantle_cpt_l2|awk '{printf "%f/%f/%s",$1+($2-$1)/5,$2-($2-$1)/5,($2-$1)/20}'`  -Z > mantle.cpt
  set mantle_scale_annot = `echo $mantle_scale_range|awk '{printf "%.2f",$1/5.8}'`

  set crust_scale_range = `echo $crust_cpt_l1 $crust_cpt_l2|awk '{printf "%f",$2-$1}'`
  gmt grd2cpt $crustGrd -Cwysiwyg -I -L$crust_cpt_l1/$crust_cpt_l2 -S`echo $crust_cpt_l1 $crust_cpt_l2|awk '{printf "%f/%f/%s",$1+($2-$1)/5,$2-($2-$1)/5,($2-$1)/20}'`  -Z -Vq > crust.cpt
  set crust_scale_annot = `echo $crust_scale_range|awk '{printf "%.2f",$1/5.6}'`
  
  if (`echo "$mantle_scale_range > 2"|bc`) then
    set mantle_scale_annot = `echo $mantle_scale_annot|awk '{printf "%.0f",$1}'`
  endif

  if (`echo "$crust_scale_range > 2"|bc`) then
    set crust_scale_annot = `echo $crust_scale_annot|awk '{printf "%.0f",$1}'`
  endif
  
  gmt grdimage $crustGrd -Ccrust.cpt -R$reg -J$prj -E300 -Q -O -K -P >> $fn.ps
  gmt grdimage $mantleGrd -Cmantle.cpt -R$reg -J$prj -E300 -Q -O -K -P >> $fn.ps
  

  cat ct$id.dat|gmt psxy -R$reg -J$prj -K -O -P -W2p,white >> $fn.ps

  set scaleWidth = `echo $prj|awk -F"/-" '{print $2}'`
  gmt psscale -Cmantle.cpt -DJMR+w"$scaleWidth"/0.5c+o0.4c/0c -R$reg -J$prj -B"$mantle_scale_annot" -By+l"$scale_unit" -O -K -P >> $fn.ps

  gmt psscale -Ccrust.cpt -DJMR+w"$scaleWidth"/0.5c+o2.2c/0c -R$reg -J$prj -Ba"$crust_scale_annot" -By+l"$scale_unit" -O -K -P >> $fn.ps

#profile direction and extra psscale labels
  echo $dist_A $min_depth $profile_start|awk '{printf "%f %f %s",$1+20,$2+15,$3}'|pstext -R$reg -J$prj -N -O -K -P >> $fn.ps
  echo $dist_Z $min_depth $profile_end  |awk '{printf "%f %f %s",$1-20,$2+15,$3}'|pstext -R$reg -J$prj -N -O -K -P >> $fn.ps
  echo $dist_Z $max_depth Mantle |awk '{printf "%f %f %s",$1+40,$2+15,$3}'|pstext -R$reg -J$prj -N -O -K -P >> $fn.ps
  echo $dist_Z $max_depth Crust |awk '{printf "%f %f %s",$1+120,$2+15,$3}'|pstext -R$reg -J$prj -N -O -K -P >> $fn.ps
  
  if ( $#argv == 3 ) then
    set lon1 = `awk '{print $1}' polygons.dat|sort -n |awk 'NR==1'`
    set lon2 = `awk '{print $1}' polygons.dat|sort -nr|awk 'NR==1'`
    set lat1 = `awk '{print $2}' polygons.dat|sort -n |awk 'NR==1'`
    set lat2 = `awk '{print $2}' polygons.dat|sort -nr|awk 'NR==1'`
    
    set lon1 = `echo $lon1|awk -v p=$margin_left '{print $1-p}'`
    set lon2 = `echo $lon2|awk -v p=$margin_right '{print $1+p}'`
    set lat1 = `echo $lat1|awk -v p=$margin_bottom '{print $1-p}'`
    set lat2 = `echo $lat2|awk -v p=$margin_top '{print $1+p}'`

    set lon_mid = `echo $lon1 $lon2|awk '{print ($1+$2)/2}'`
    set lat_mid = `echo $lat1 $lat2|awk '{print ($1+$2)/2}'`

    set reg2 = `echo "$lon1 $lat1 $lon2 $lat2"|awk '{printf "%f/%f/%f/%fr",$1,$2,$3,$4}'`
    set prj2 = `echo "$lon_mid $lat_mid $lat1 $lat2 $scaleWidth"|awk '{printf "L%f/%f/%f/%f/%f",$1,$2,$3,$4,$5/2}'`
    
    gmt psbasemap -R$reg2 -J$prj2 -Bx0 -By0 -P -O -K >> $fn.ps
    gmt pscoast -R$reg2 -J$prj2 -Gforestgreen -Slightskyblue1 -A1500k -Dl -P -O -K >> $fn.ps
    cat polygons.dat|gmt psxy -R$reg2 -J$prj2 -K -O -P -W1p,darkblue >> $fn.ps
    cat `printf "profile_%04d.dat" $i`| gmt psxy -R$reg2 -J$prj2 -K -O -P -W1p,red >> $fn.ps
  endif
  

  echo 0 0|gmt psxy -R$reg -J$prj -O -P -Sc0.001p -Gblack -Wthin,black >> $fn.ps
  ps2epsi $fn.ps $fn.epsi
  epstopdf $fn.epsi
end

printf "  Plotting ................... Done.\n\n"

#remove all the files but PDFs
rm -f `ls|grep -v ".pdf"`

