#/bin/csh
#Coded by: omid.bagherpur@gmail.com
#UPDATE: 19 April 2019
#Run the sctipt to see the usage!
#====Adjustable Parameters=====#
set output_folder = ps1
set uniform_scale = 'yes' # 'yes' or 'no'; uniform colorscale for all maps
set min_depth = 50
set max_depth = 250
set profile_start = ' '
set profile_end   = ' '
set scale_label = "(%)"
#for the minimap (if $#argv==3)
set margin_right  = 3 #grid right margin  (in degrees) 1
set margin_left   = 3 #grid left margin   (in degrees)1
set margin_top    = 1.5 #grid top margin    (in degrees) 0.5
set margin_bottom = 2 #grid bottom margin (in degrees) 0.5
#==============================#
clear
printf "This script generates plots of cross sections with the same length over a tomography model using GMT.\n\n" 
printf "The inputs include:\n 1) A list of crosssection data (format: dist(km), depth(km), val ...)\n 2) (optional): A polygon track that defines the region of interest \n 3) (optional): Profiles xy track\n\n"


#---check input data---#
if ( $#argv < 1 ) then
  printf "Error!\n USAGE: csh crosssection-plot.csh <crosssection datalist> <area polygon> <profiles>\n\nInput data format (columns):\n\n <crosssection datalist>: 1)crosssection data location\n <area polygon>: 1)Lon,    2)Lat\n <profiles>: 1)profile xy tracks file location \n\n"
  exit
else
  set datalist = $1
  printf "  Checking inputs ... \r"
endif

if (! -e $datalist) then
  printf "\nError!\n Could not find <crosssection datalist>: '$datalist'\n\n"
  exit
else
  set nData = `cat $datalist|wc -l`
  set data_nCol = `awk 'NR==1' $datalist|awk '{print NF}'`
endif

if ( $#argv == 3 ) then
  set polygon  = $2
  set profiles = $3
  
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
  if ( $#argv == 3 ) then
    cp `awk "NR==$i" $profiles` $output_folder/profile_$num.dat
  endif
end
cp $datalist $output_folder/crosssection_list.dat

if ( $#argv == 3 ) then
  cp $polygon $output_folder/polygon.dat
endif

printf "  Copying data ............... Done.          \n"

#plotting script
cd $output_folder
set dep_len = `echo $min_depth $max_depth|awk '{print $2-$1}'`
set dis_len = `echo $dist_A $dist_Z|awk '{print $2-$1}'`
set mediaSize = `echo $dis_len $dep_len|awk '{printf "%.2fcx%.2fc",$1/50+6, $2/50+4}'`
set reg = $dist_A/$dist_Z/$min_depth/$max_depth
set prj = `echo $dis_len $dep_len|awk '{printf "X%.2fc/-%.2fc",$1/50,$2/50}' `

gmt set PS_MEDIA "$mediaSize" COLOR_NAN white COLOR_FOREGROUND darkblue \
        COLOR_BACKGROUND darkred FONT_LABEL 12p,black MAP_TICK_LENGTH 2p \
        MAP_FRAME_PEN 1p

set cpt_l1 =  9999
set cpt_l2 = -9999

printf "  Gridding data\r"
@ i=0
foreach cs (`ls|grep "crosssection_[0-9][0-9][0-9][0-9].dat"`)
  @ i++
  set xSpacing = `awk '{print $1}' crosssection_0001.dat|sort -n|uniq|head -n2|awk '{printf "%s %s",$1,$2}'|awk '{print $2-$1}'`
  set ySpacing = `awk '{print $2}' crosssection_0001.dat|sort -n|uniq|head -n2|awk '{printf "%s %s",$1,$2}'|awk '{print $2-$1}'`
  set grdSpacing = `echo $xSpacing $ySpacing| awk '{printf "%f/%f",$1/4,$2/4}'`
  printf "  Gridding data: $i of $nData \r"
  set grdName = `echo $i|awk '{printf "grid_%04d",$1}'`
  gmt blockmean $cs -R$reg -I"$grdSpacing" > bm.tmp
  gmt surface bm.tmp -R$reg -I"$grdSpacing" -G$grdName.tmp
  
  if (`echo "$xSpacing > $ySpacing"|bc`) then
    set maskDist = `echo $xSpacing|awk '{print $1+1}'`
  else
    set maskDist = `echo $ySpacing|awk '{print $1+1}'`
  endif
  
  gmt grdmask bm.tmp -R$reg -I"$grdSpacing" -NNaN/1/1 -S"$maskDist" -Gmask.nc
  gmt grdmath mask.nc $grdName.tmp MUL = $grdName.nc
  
  set grdMin  = `gmt grdinfo $grdName.nc -M|grep -w z_min|awk '{printf "%.2f\n",$3-0.01}'`
  set grdMax  = `gmt grdinfo $grdName.nc -M|grep -w z_max|awk '{printf "%.2f\n",$12+0.01}'`
  if (`echo "$grdMin < $cpt_l1"|bc`) set cpt_l1 = $grdMin
  if (`echo "$grdMax > $cpt_l2"|bc`) set cpt_l2 = $grdMax
  
end
printf "  Gridding data .............. Done.       \n"


printf "  Plotting\r"
@ i=0
foreach grd (`ls|grep "grid_[0-9][0-9][0-9][0-9].nc"`)
  @ i++
  set fn = `printf "crosssection_%04d" $i`

  if ( `echo "$data_nCol > 1"|bc` ) then
    set title = `awk "NR==$i" crosssection_list.dat|cut -d' ' -f 2-99|sed 's/ /\n/g'`
  else
    set title = ""
  endif
  
  gmt psbasemap  -R$reg -J$prj -Bx100+l'Distance(km)' -By50+l'Depth(km)' -BWnSe+t"$title" -P -K > $fn.ps

#make color scales  
  if ($uniform_scale != 'yes') then
    set cpt_l1 = `gmt grdinfo $grd -m|grep z_min|awk '{print $3}'`
    set cpt_l2 = `gmt grdinfo $grd -m|grep z_min|awk '{print $5}'`
  endif
  
  if (`echo "$cpt_l1 < 0"|bc`) then #make symmetric colorscale if perturbation data is used
    if (`echo "(-1)*$cpt_l1 > $cpt_l2"|bc`) then
      set val0 = `echo "(-1)*$cpt_l1"|bc`
    else
      set val0 = $cpt_l2
    endif
    set cpt_l1 = "-$val0"
    set cpt_l2 = $val0
    set scale_label = "(%)"
  endif

    set cpt_l1 = "-3"
    set cpt_l2 = 3
  
  set scale_range = `echo $cpt_l1 $cpt_l2|awk '{printf "%f",$2-$1}'`
  gmt grd2cpt $grd -Croma -L$cpt_l1/$cpt_l2 -S`echo $cpt_l1 $cpt_l2|awk '{printf "%f/%f/%s",$1+($2-$1)/5,$2-($2-$1)/5,($2-$1)/20}'`  -Z > c1.cpt
  set scale_annot = `echo $scale_range|awk '{printf "%.2f",$1/5.8}'`
  
  if (`echo "$scale_range > 2"|bc`) then
    set scale_annot = `echo $scale_annot|awk '{printf "%.0f",$1}'`
  endif 
  
  gmt grdimage $grd -Cc1.cpt -R$reg -J$prj -E300 -O -K -P >> $fn.ps
  set scaleWidth = `echo $prj|awk -F"/-" '{print $2}'`
  gmt psscale -Cc1.cpt -DJMR+w"$scaleWidth"/0.5c+o0.7c/0c -R$reg -J$prj -B"$scale_annot" -By+l"$scale_label" -O -K -P >> $fn.ps

#profile direction label
  echo $dist_A $min_depth $profile_start|awk '{printf "%f %f %s",$1+20,$2+15,$3}'|pstext -R$reg -J$prj -N -O -K -P >> $fn.ps
  echo $dist_Z $min_depth $profile_end  |awk '{printf "%f %f %s",$1-20,$2+15,$3}'|pstext -R$reg -J$prj -N -O -K -P >> $fn.ps
  
  if ( $#argv == 3 ) then
    set lon1 = `awk '{print $1}' polygon.dat|sort -n |awk 'NR==1'`
    set lon2 = `awk '{print $1}' polygon.dat|sort -nr|awk 'NR==1'`
    set lat1 = `awk '{print $2}' polygon.dat|sort -n |awk 'NR==1'`
    set lat2 = `awk '{print $2}' polygon.dat|sort -nr|awk 'NR==1'`
    
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
    cat polygon.dat|gmt psxy -R$reg2 -J$prj2 -K -O -P -W1p,darkblue >> $fn.ps
    cat `printf "profile_%04d.dat" $i`| gmt psxy -R$reg2 -J$prj2 -K -O -P -W1p,red >> $fn.ps
  endif
  
#  $dist_A/$dist_Z/$min_depth/$max_depth


  
  echo 0 0|gmt psxy -R$reg -J$prj -O -P -Sc0.001p -Gblack -Wthin,black >> $fn.ps
  ps2epsi $fn.ps $fn.epsi
  epstopdf $fn.epsi
end

printf "  Plotting ................... Done.\n\n"

#remove all the files but PDFs
rm -f `ls|grep -v ".pdf"`

