#!/bin/csh
#This script uses GMT to plot phase velocity maps resulted from TPWT.
# USAGE: ./TPWT_plotResuts.csh <datalist> <mask polygon> <map titles>
# NOTE: <datalist> could optionally have a second column for anisotropy plotting in (x,y,anisotropy (%),direction(deg)) format.
# Coded By: omid.bagherpur@gmail.com
# UPDATE: 1 June 2019
#=====Adjustable Parameters======#
set uniform_scale = 'yes' # 'yes' or 'no'; uniform colorscale for all maps
set min_cpt = 'auto' # 'auto' or a number
set max_cpt = 'auto' # 'auto' or a number

set plot_contours = 'no' #'yes' or 'no'
set plot_nodes    = 'no' #'yes' or 'no'
set scale_label = 'C (km/s)'
set scale_annot = 'auto' #choose a value or 'auto'
set titles_on_top = 'no' #If 'yes' and <map title> is provided, the title will be placed at the top of maps

#Anisotropy plot parameters:
set anis_factor = 0.65 # If anisotropy data available, it affects the magnitude at each node;scale factor
set anis_width = 3 # in pixel
set anis_color = magenta
set anis_legendSymbolSize = 2 #what anis percentage in the legend?
set anis_legendSymbolAngle = 91 #legend symbol angle
set anis_legendXY1 = '-61.7 42.2' #legend symbol location (lon, lat)
set anis_legendXY2 = '-59.5 42.2' #legend text location (lon, lat)

#grid and map parameters
set grdSpacing = 'auto' #choose the spacing (degrees) or 'auto' (uniform data spacing)
set tension_factor = 0 #tension factor in gridding (between 0 and 1); 0 is recommended for smooth results
set box_map  = 'no' # 'yes' or 'no'; rectangular map; If yes, set the following 4 variables:
set margin_right  = -0.5 #grid right margin  (in degrees) 
set margin_left   = 1.5 #grid left margin   (in degrees)
set margin_top    = 0.5 #grid top margin    (in degrees)
set margin_bottom = 0.5 #grid bottom margin (in degrees)

#plot style parameters/GMT flags
set font1 = '24p,Helvetica,black' #FONT_ANNOT_PRIMARY
set font2 = '24p,Helvetica,black' #FONT_ANNOT_SECONDARY
set font3 = '28p,Helvetica,black' #FONT_LABEL
set font4 = '42p,Helvetica-Bold,black' #FONT_TITLE
set frame = 'MAP_FRAME_TYPE fancy MAP_FRAME_PEN thick,black MAP_FRAME_WIDTH 0.25c'
set annot = '-Bx3 -By2 -BWSNe'    #pscoast -B flags x4 y3
set scale_flag = '-Dx0p/-50p+w780p/30p+jTL+h'
#===============================#
clear
printf " This script uses GMT to plot phase velocity maps resulted from TPWT.\n\n"
#check input
if ($#argv == 0 ) then
  printf "Error!\n USAGE: ./TPWT_plotResuts.csh <datalist> <mask polygon> <map titles>\n Note: <mask polygon> <map titles> are optional!\n\n"
  exit
else
  set datalist = $argv[1]
  set output_folder = `echo $datalist|rev|cut -d'.' -f2-99|rev|awk '{printf "%s_maps",$1}'`
endif

if (! -e $datalist) then
  printf "Error! could not find the <datalist>: '$datalist'\n\n"
  exit
else
  set nData = `cat $datalist|wc -l`
  set ncol_datalist = `awk '{ncol=NF}  END {print ncol}' $datalist`
endif

if ($#argv == 2 || $#argv == 3) then
  set maskpoly = $argv[2]
  if (! -e $maskpoly) then
    printf "Error! could not find the <mask polygon>: '$maskpoly'\n\n"
    exit
  endif
endif

if ($#argv == 3 ) then
    set titles = $argv[3]
    if (! -e $titles) then
      printf "Error! could not find the <map titles>: '$titles'\n\n"
      exit
    else
      set nTitles = `cat $titles|wc -l`
    endif
    
    if ($nTitles != $nData) then
      printf "Error! Number of data files does not match to the number of titles!'\n\n"
      exit
    endif
endif 

foreach data (`cat $datalist|awk '{print $1}'`)
  if (! -e $data) then
    printf "Datalist Error! Could not find '$data'.\n\n"
    exit
  endif
end
#check <mask polygon>
if ($#argv > 1) then
  if (! -e $maskpoly) then
    printf "Error! could not find the <mask polygon>: '$argv[2]'\n\n"
    exit
  else
    set ncol_maskpoly = `awk '{ncol=NF}  END {print ncol}' $maskpoly`
  endif
endif

printf "Parameters:\n  Input datalist: '$datalist'\n"
if ($#argv > 1) then
  printf "  Mask polygon:   '$maskpoly'\n"
endif
if ($#argv == 3) then
  printf "  Map titles:   '$titles'\n"
endif
printf "  Output folder: $output_folder\n  Number of Maps: $nData\n  Uniform color scales: $uniform_scale \n  Plot countours: $plot_contours\n  Plot nodes: $plot_nodes\n  Grid spacing: $grdSpacing\n\n"

printf "Do you want to continue (y/n)? "
set uans = $<
if ($uans == 'y') then
  printf "\n"
else
  printf "\nExit!\n\n"
  exit
endif

if (-d $output_folder) then
  rm -rf $output_folder
  mkdir $output_folder
else
  mkdir $output_folder
endif

cp $datalist $output_folder/datalist.tmp
if ($#argv > 1) then
  cp $maskpoly $output_folder/maskpoly.tmp
endif
cp `cat $datalist|awk '{print $1}'` $output_folder
cd $output_folder

#find region
set lon1 = 999; set  lon2 =  -999; set lat1 = 999; set lat2 = -999
foreach data (`cat datalist.tmp|awk '{print $1}'|rev|cut -d"/" -f1|rev`)
  set x_min = `awk '{print $1}' $data|sort -n |head -n1`
  set x_max = `awk '{print $1}' $data|sort -nr|head -n1`
  set y_min = `awk '{print $2}' $data|sort -n |head -n1`
  set y_max = `awk '{print $2}' $data|sort -nr|head -n1`
  if (`echo "$x_min < $lon1"|bc` == 1) set lon1 = $x_min
  if (`echo "$y_min < $lat1"|bc` == 1) set lat1 = $y_min
  if (`echo "$x_max > $lon2"|bc` == 1) set lon2 = $x_max
  if (`echo "$y_max > $lat2"|bc` == 1) set lat2 = $y_max
end

set lon_mid = `echo $lon1 $lon2|awk '{print ($1+$2)/2}'`
set lat_mid = `echo $lat1 $lat2|awk '{print ($1+$2)/2}'`

set lon1 = `echo $lon1|awk -v p=$margin_left '{print $1-p}'`
set lon2 = `echo $lon2|awk -v p=$margin_right '{print $1+p}'`
set lat1 = `echo $lat1|awk -v p=$margin_bottom '{print $1-p}'`
set lat2 = `echo $lat2|awk -v p=$margin_top '{print $1+p}'`


#GMT script

set mediaSize = '1200px1200p'

if ($box_map == 'yes') then
  set reg = `echo "$lon1 $lat1 $lon2 $lat2"|awk '{printf "%f/%f/%f/%fr",$1,$2,$3,$4}'`
else
  set reg = "$lon1/$lon2/$lat1/$lat2"
endif
set prj = "L$lon_mid/$lat_mid/$lat1/$lat2/900p"

gmt set FONT_ANNOT_PRIMARY $font1 FONT_ANNOT_SECONDARY $font2 \
        FONT_LABEL $font3 FONT_TITLE $font4 FORMAT_GEO_MAP \
        ddd:mm:ssF GMT_VERBOSE n $frame MAP_ANNOT_OBLIQUE 6 \
        MAP_ANNOT_OFFSET 15p MAP_GRID_CROSS_SIZE_PRIMARY 2 PS_MEDIA "$mediaSize" \
        MAP_TITLE_OFFSET 0.2i  COLOR_NAN white COLOR_FOREGROUND 0/0/200 \
        COLOR_BACKGROUND 170/0/0


# Gridding
set cpt_l1 = 99999; set cpt_l2 = -99999
@ i=0
while ($i < $nData)
  @ i++
  printf "  Gridding data  ... $i of $nData\r"
  set data = `cat datalist.tmp|awk "NR==$i"|awk '{print $1}'|rev|cut -d"/" -f1|rev`
  set fn = `echo $data|rev|cut -d"." -f2-999|rev`
  
  if ($grdSpacing == 'auto') then
    set px1 = `awk 'NR==1' $data|awk '{print $1}'`
    set py1 = `awk 'NR==1' $data|awk '{print $2}'`
    set px2 = `awk 'NR==2' $data|awk '{print $1}'`
    set py2 = `awk 'NR==2' $data|awk '{print $2}'`
    set grdSpacing = `echo $px1 $py1 | gmt mapproject -G$px2/$py2 | awk '{printf "%.2fd",($3/111000)/4}'`
  else
    set grdSpacing = `echo $grdSpacing| awk '{printf "%.2fd",$1}'`
  endif
  
  gmt blockmean $data -R$lon1/$lon2/$lat1/$lat2 -I$grdSpacing > bm.tmp
  gmt surface bm.tmp -I$grdSpacing -R$reg -T$tension_factor -G$fn.tmp
  
  
  if ($#argv > 1) then
    gmt grdmask maskpoly.tmp -R$reg -I$grdSpacing -NNaN/1/1 -Gmask.nc
    gmt grdmath mask.nc $fn.tmp MUL = $fn.nc
  else
    mv $fn.tmp $fn.nc
  endif
 
  
  

  set grdMin  = `gmt grdinfo $fn.nc -M|grep -w z_min|awk '{printf "%.2f\n",$3-0.01}'`
  set grdMax  = `gmt grdinfo $fn.nc -M|grep -w z_max|awk '{printf "%.2f\n",$12+0.01}'`
  if (`echo "$grdMin < $cpt_l1"|bc` == 1) set cpt_l1 = $grdMin
  if (`echo "$grdMax > $cpt_l2"|bc` == 1) set cpt_l2 = $grdMax

  rm -f $data
end
printf "  Gridding data  ..... Done.                  \n"

#make plots
@ i=0
foreach grd (`ls *.nc|grep -v mask.nc`)
  @ i++
  printf "  Generating plots ... $i of $nData\r"
  set fn = `echo $grd|rev|cut -d"." -f2-999|rev`
  
  if ($#argv == 3) then
    set title_str = `awk "NR==$i" ../$titles|sed 's/ /,,/g'` #trick to have space in titles!
    if ($titles_on_top == 'yes') then
      set annot2 = `echo "$annot"|awk -v tt="$title_str" '{printf "%s+t%s",$0,tt}'|sed 's/,,/\\n/g'`
    else
      set annot2 = `echo $annot`
    endif
  else
    set annot2 = `echo $annot`
  endif
  
  if ($uniform_scale != 'yes') then
    set cpt_l1 = `gmt grdinfo $grd -m|grep z_min|awk '{print $3}'`
    set cpt_l2 = `gmt grdinfo $grd -m|grep z_min|awk '{print $5}'`
  endif
  
  if ($min_cpt != 'auto') then
    set cpt_l1 = $min_cpt

  endif
  
  if ($max_cpt != 'auto') then
    set cpt_l2 = $max_cpt
  endif
  
  set scale_range = `echo $cpt_l1 $cpt_l2|awk '{printf "%f",$2-$1}'`
  #comment either of the two following lines lines (full linear vs semi-linear colorscale)
  #gmt grd2cpt $grd -Cseis -L$cpt_l1/$cpt_l2 -S`echo $cpt_l1 $cpt_l2|awk '{printf "%f/%f/%s",$1,$2,($2-$1)/20}'` -Z > c1.cpt
  gmt grd2cpt $grd -Cseis -L$cpt_l1/$cpt_l2 -S`echo $cpt_l1 $cpt_l2|awk '{printf "%f/%f/%s",$1+($2-$1)/5,$2-($2-$1)/5,($2-$1)/20}'`  -Z > c1.cpt
  
  if ($scale_annot == 'auto') then
    set scale_annot2 = `echo $scale_range|awk '{printf "%.2f",$1/6.5}'`
  
    if (`echo "$scale_range > 2"|bc`) then
      set scale_annot2 = `echo $scale_annot2|awk '{printf "%.0f",$1}'`
    endif
  else
    set scale_annot2 = $scale_annot
  endif
  
   
  
  gmt psbasemap -R$reg -J$prj -Y200p -X150p -BWSne -K -P > $fn.ps
  gmt psscale -Cc1.cpt $scale_flag -B$scale_annot2 -By+l"$scale_label" -O -K >> $fn.ps
    
  gmt grdimage $fn.nc -Cc1.cpt -R$reg -J$prj -E300 -O -K -P >> $fn.ps
  if ($plot_contours == 'yes') then
    gmt grdhisteq $fn.nc -G$fn-hist.nc -C64
    gmt makecpt -Cseis -I -T0/32/8 > hist.cpt
    gmt grdcontour $fn-hist.nc -Chist.cpt -R$reg -J$prj -A- -Wthinnest,gray50 -K -O >> $fn.ps
  endif
  
  if ($plot_nodes == 'yes') then
    awk '{print $1,$2}' bm.tmp|gmt psxy -R$reg -J$prj -K -O -P -Sc3p -Gblack -Wthin,black >> $fn.ps
  endif

  
  gmt pscoast -R$reg -J$prj -Wthin,black $annot2 -A500k -Di -N1 -P -O -K >> $fn.ps
  
  if ($#argv == 3 && $titles_on_top != 'yes') then
    echo  $title_str|sed 's/,,/\\n/g'| gmt pstext -R$reg -J$prj -F+cBR+f$font4 -D-1c/1c -P -O -K >> $fn.ps
  endif
  
  #plot anisotropy:
  if ($ncol_datalist == 2 ) then
    set anis_width = `echo $anis_width|awk '{printf "%sp",$1}'`
    set anisData = `awk '{print $2}' datalist.tmp|awk "NR==$i"`
    awk -v fac=$anis_factor '{ print $1,$2,$3,$4*fac}' ../$anisData | gmt psxy -R$reg -J$prj -SV1c+jc -W$anis_width,$anis_color -G$anis_color -O -K -Vq >> $fn.ps
    
    echo "$anis_legendXY1 $anis_legendSymbolAngle $anis_legendSymbolSize $anis_factor"|awk '{print $1,$2,$3,$4*$5}' | gmt psxy -R$reg -J$prj -SV1c+jc -W$anis_width,$anis_color -G$anis_color -O -K -Vq >> $fn.ps
    echo "$anis_legendXY2 $anis_legendSymbolSize% anisotropy" | gmt pstext -J -R -F+f$font2 -O -K -N >> $fn.ps
  endif

  #just to finalize the psfile:
  echo 0 0|gmt psxy -R -J -O -P -Sc0.001p -Gblack -Wthin,black >> $fn.ps
  ps2epsi $fn.ps $fn.epsi
  epstopdf --autorotate=None $fn.epsi
  
end

printf "  Generating plots ... Done.         \n\n"

#remove all the files but PDFs:
rm -f `ls|grep -v .pdf`


